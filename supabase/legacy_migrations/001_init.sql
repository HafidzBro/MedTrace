-- 001_init.sql
-- Supabase migration: schema, indexes, triggers, adherence calculation, RLS policies

BEGIN;

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS postgis;

-- profiles: maps to auth.users.id
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text,
  email text,
  phone text,
  role text NOT NULL CHECK (role IN ('doctor','patient','admin')),
  doctor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- doctor_codes: one-time codes doctors provide for patient registration
CREATE TABLE IF NOT EXISTS public.doctor_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE,
  description text,
  max_uses integer DEFAULT 1,
  current_uses integer DEFAULT 0,
  expires_at timestamptz,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- patients: domain patient record (linked to profile)
CREATE TABLE IF NOT EXISTS public.patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid UNIQUE REFERENCES public.profiles (id) ON DELETE CASCADE,
  doctor_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  national_id text,
  date_of_birth date,
  gender text,
  address text,
  latitude double precision,
  longitude double precision,
  location geography(Point,4326),
  phone text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- note: doctor_patients relationship table/view is managed by the initial schema migration; avoid duplicating here.


-- treatments: per-patient treatment plan
CREATE TABLE IF NOT EXISTS public.treatments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  doctor_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  diagnosis_date date,
  start_date date NOT NULL,
  end_date date,
  phase text NOT NULL CHECK (phase IN ('intensive','continuation')),
  status text NOT NULL CHECK (status IN ('ongoing','completed','defaulted')),
  adherence_percentage numeric(5,2) DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- medication_logs: each scheduled dose and whether taken
CREATE TABLE IF NOT EXISTS public.medication_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_id uuid NOT NULL REFERENCES public.treatments (id) ON DELETE CASCADE,
  patient_id uuid NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  scheduled_at timestamptz NOT NULL,
  taken boolean NOT NULL DEFAULT false,
  taken_at timestamptz,
  note text,
  created_at timestamptz DEFAULT now()
);

-- reminders: patient reminder schedules
CREATE TABLE IF NOT EXISTS public.reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  treatment_id uuid REFERENCES public.treatments (id) ON DELETE SET NULL,
  time time NOT NULL,
  weekdays text[] DEFAULT ARRAY['mon','tue','wed','thu','fri','sat','sun'],
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- chatbot_logs: save chat history and context for AI assistant
CREATE TABLE IF NOT EXISTS public.chatbot_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  role text,
  message text NOT NULL,
  response text,
  context jsonb,
  created_at timestamptz DEFAULT now()
);

-- notifications: alerts to users (local or push)
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles (id) ON DELETE CASCADE,
  patient_id uuid REFERENCES public.patients (id) ON DELETE CASCADE,
  title text,
  body text,
  data jsonb,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_patients_location ON public.patients USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_treatments_patient_id ON public.treatments (patient_id);
CREATE INDEX IF NOT EXISTS idx_medication_logs_treatment_id ON public.medication_logs (treatment_id);
CREATE INDEX IF NOT EXISTS idx_medication_logs_scheduled_at ON public.medication_logs (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications (user_id);

-- Trigger: populate geometry location from lat/lon
CREATE OR REPLACE FUNCTION public.patients_set_location()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude),4326)::geography;
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patients_set_location
BEFORE INSERT OR UPDATE ON public.patients
FOR EACH ROW
EXECUTE FUNCTION public.patients_set_location();

-- Adherence calculation function: computes adherence % for a treatment
CREATE OR REPLACE FUNCTION public.compute_and_update_treatment_adherence(p_treatment_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  total int;
  taken int;
  pct numeric;
BEGIN
  SELECT COUNT(*) INTO total FROM public.medication_logs WHERE treatment_id = p_treatment_id;
  IF total = 0 THEN
    pct := 0;
  ELSE
    SELECT COUNT(*) INTO taken FROM public.medication_logs WHERE treatment_id = p_treatment_id AND taken = true;
    pct := (taken::numeric / total::numeric) * 100;
  END IF;

  UPDATE public.treatments SET adherence_percentage = round(pct::numeric,2), updated_at = now() WHERE id = p_treatment_id;
END;
$$;

-- Trigger: call adherence update after medication_logs change
CREATE OR REPLACE FUNCTION public.medication_logs_after_change()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  t_id uuid;
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    t_id := NEW.treatment_id;
  ELSIF TG_OP = 'DELETE' THEN
    t_id := OLD.treatment_id;
  ELSE
    RETURN NULL;
  END IF;

  PERFORM public.compute_and_update_treatment_adherence(t_id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_medication_logs_after_change
AFTER INSERT OR UPDATE OR DELETE ON public.medication_logs
FOR EACH ROW
EXECUTE FUNCTION public.medication_logs_after_change();

-- Enable Row Level Security for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- POLICIES

-- profiles policies: users can read own profile; doctors can read their patients
CREATE POLICY "profiles_select_own_or_doctor"
ON public.profiles FOR SELECT
USING (
  auth.role() = 'service_role' OR
  id = auth.uid() OR
  (role = 'patient' AND doctor_id = auth.uid())
);

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- doctor_codes: public read for active codes to validate registration; modifications by service_role only
CREATE POLICY "doctor_codes_select_active"
ON public.doctor_codes FOR SELECT
USING (is_active = true);

CREATE POLICY "doctor_codes_insert_service"
ON public.doctor_codes FOR INSERT
USING (auth.role() = 'service_role');

CREATE POLICY "doctor_codes_update_service"
ON public.doctor_codes FOR UPDATE
USING (auth.role() = 'service_role');

-- patients policies: patient owner or their doctor
CREATE POLICY "patients_select_owner_or_doctor"
ON public.patients FOR SELECT
USING (
  auth.role() = 'service_role' OR
  profile_id = auth.uid() OR
  doctor_id = auth.uid()
);

CREATE POLICY "patients_insert_owner_or_doctor"
ON public.patients FOR INSERT
USING (
  auth.role() = 'service_role' OR
  profile_id = auth.uid() OR
  doctor_id = auth.uid()
)
WITH CHECK (
  auth.role() = 'service_role' OR
  profile_id = auth.uid() OR
  doctor_id = auth.uid()
);

CREATE POLICY "patients_update_owner_or_doctor"
ON public.patients FOR UPDATE
USING (
  auth.role() = 'service_role' OR
  profile_id = auth.uid() OR
  doctor_id = auth.uid()
)
WITH CHECK (
  auth.role() = 'service_role' OR
  profile_id = auth.uid() OR
  doctor_id = auth.uid()
);

-- treatments policies (allow access to patient owner and assigned doctor)
CREATE POLICY "treatments_select_allowed"
ON public.treatments FOR SELECT
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.treatments.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

CREATE POLICY "treatments_update_allowed"
ON public.treatments FOR UPDATE
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.treatments.patient_id AND p.doctor_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.treatments.patient_id AND p.profile_id = auth.uid())
)
WITH CHECK (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.treatments.patient_id AND p.doctor_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.treatments.patient_id AND p.profile_id = auth.uid())
);

CREATE POLICY "treatments_insert_allowed"
ON public.treatments FOR INSERT
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
)
WITH CHECK (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

-- medication_logs policies
CREATE POLICY "medication_logs_select_allowed"
ON public.medication_logs FOR SELECT
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.medication_logs.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

CREATE POLICY "medication_logs_insert_allowed"
ON public.medication_logs FOR INSERT
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
)
WITH CHECK (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

CREATE POLICY "medication_logs_update_allowed"
ON public.medication_logs FOR UPDATE
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.medication_logs.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
)
WITH CHECK (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

-- reminders policies
CREATE POLICY "reminders_select_owner_or_doctor"
ON public.reminders FOR SELECT
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = public.reminders.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

CREATE POLICY "reminders_modify_owner_or_doctor"
ON public.reminders FOR INSERT, UPDATE, DELETE
USING (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
)
WITH CHECK (
  auth.role() = 'service_role' OR
  EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND (p.profile_id = auth.uid() OR p.doctor_id = auth.uid()))
);

-- chatbot_logs policies
CREATE POLICY "chatbot_logs_select_or_insert_own"
ON public.chatbot_logs FOR SELECT, INSERT
USING (
  auth.role() = 'service_role' OR
  user_id = auth.uid()
)
WITH CHECK (
  auth.role() = 'service_role' OR
  user_id = auth.uid()
);

-- notifications policies
CREATE POLICY "notifications_select_own"
ON public.notifications FOR SELECT
USING (
  auth.role() = 'service_role' OR
  user_id = auth.uid()
);

CREATE POLICY "notifications_insert_by_doctor_or_service"
ON public.notifications FOR INSERT
USING (
  auth.role() = 'service_role' OR
  (user_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND p.doctor_id = auth.uid()))
)
WITH CHECK (
  auth.role() = 'service_role' OR
  (user_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.patients p WHERE p.id = NEW.patient_id AND p.doctor_id = auth.uid()))
);

COMMIT;
