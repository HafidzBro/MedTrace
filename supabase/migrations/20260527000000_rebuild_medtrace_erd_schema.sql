-- Rebuild MedTrace public schema to match the current ERD.
-- Destructive for application tables. Supabase Auth tables are not touched.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

DROP VIEW IF EXISTS public.treatment_adherence CASCADE;

DROP TRIGGER IF EXISTS mirror_chatbot_messages_to_logs ON public.chatbot_messages;
DROP FUNCTION IF EXISTS public.log_chatbot_message() CASCADE;
DROP FUNCTION IF EXISTS public.complete_patient_registration(UUID, TEXT, TEXT, TEXT) CASCADE;

DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.alerts CASCADE;
DROP TABLE IF EXISTS public.chatbot_messages CASCADE;
DROP TABLE IF EXISTS public.chatbot_logs CASCADE;
DROP TABLE IF EXISTS public.chatbot_conversations CASCADE;
DROP TABLE IF EXISTS public.reminders CASCADE;
DROP TABLE IF EXISTS public.therapy_status_histories CASCADE;
DROP TABLE IF EXISTS public.therapy_progress CASCADE;
DROP TABLE IF EXISTS public.medication_logs CASCADE;
DROP TABLE IF EXISTS public.phase_medication CASCADE;
DROP TABLE IF EXISTS public.medications CASCADE;
DROP TABLE IF EXISTS public.medication CASCADE;
DROP TABLE IF EXISTS public.therapy_phases CASCADE;
DROP TABLE IF EXISTS public.treatments CASCADE;
DROP TABLE IF EXISTS public.therapies CASCADE;
DROP TABLE IF EXISTS public.patient_locations CASCADE;
DROP TABLE IF EXISTS public.tb_cases CASCADE;
DROP TABLE IF EXISTS public.doctor_patients CASCADE;
DROP TABLE IF EXISTS public.doctor_code_usages CASCADE;
DROP TABLE IF EXISTS public.doctor_codes CASCADE;
DROP TABLE IF EXISTS public.patients CASCADE;
DROP TABLE IF EXISTS public.doctors CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('doctor', 'patient', 'admin')),
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE public.doctors (
  doctor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(profile_id) ON DELETE CASCADE,
  facility_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.doctor_codes (
  code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(doctor_id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  max_uses INTEGER NOT NULL DEFAULT 1 CHECK (max_uses > 0),
  current_uses INTEGER NOT NULL DEFAULT 0 CHECK (current_uses >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CHECK (current_uses <= max_uses)
);

CREATE TABLE public.patients (
  patient_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(profile_id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT,
  patient_code TEXT UNIQUE,
  nik TEXT UNIQUE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  birth_date DATE,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.doctor_code_usages (
  usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES public.doctor_codes(code_id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(code_id, patient_id)
);

CREATE TABLE public.tb_cases (
  tb_case_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  diagnosis_date DATE NOT NULL,
  tb_category TEXT,
  tb_type TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.patient_locations (
  patient_location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  latitude NUMERIC(10, 8) NOT NULL,
  longitude NUMERIC(11, 8) NOT NULL,
  address TEXT,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.therapies (
  therapy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tb_case_id UUID REFERENCES public.tb_cases(tb_case_id) ON DELETE SET NULL,
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT,
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT NOT NULL DEFAULT 'ongoing' CHECK (status IN ('registered', 'ongoing', 'on_treatment', 'completed', 'defaulted', 'paused')),
  adherence_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0 CHECK (adherence_percentage >= 0 AND adherence_percentage <= 100),
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.therapy_phases (
  therapy_phase_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  therapy_id UUID NOT NULL REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  phase_name TEXT NOT NULL,
  phase_order INTEGER NOT NULL,
  start_month INTEGER,
  end_month INTEGER,
  start_date DATE,
  end_date DATE,
  frequency TEXT,
  intake_time TIME,
  instructions TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'skipped')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(therapy_id, phase_order)
);

CREATE TABLE public.medication (
  medication_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  abbreviation TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.phase_medication (
  phase_medication_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_id UUID NOT NULL REFERENCES public.therapy_phases(therapy_phase_id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES public.medication(medication_id) ON DELETE RESTRICT,
  dosage NUMERIC,
  unit TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(phase_id, medication_id)
);

CREATE TABLE public.medication_logs (
  medication_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  therapy_id UUID NOT NULL REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  therapy_phase_id UUID REFERENCES public.therapy_phases(therapy_phase_id) ON DELETE SET NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  taken_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('taken', 'missed', 'skipped', 'pending')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.therapy_progress (
  therapy_progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  therapy_id UUID NOT NULL UNIQUE REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  days_on_therapy INTEGER NOT NULL DEFAULT 0 CHECK (days_on_therapy >= 0),
  last_calculated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.therapy_status_histories (
  therapy_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  therapy_id UUID NOT NULL REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  notes TEXT,
  changed_by UUID REFERENCES public.profiles(profile_id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.reminders (
  reminder_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  therapy_id UUID REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  therapy_phase_id UUID REFERENCES public.therapy_phases(therapy_phase_id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL DEFAULT 'custom' CHECK (reminder_type IN ('medication', 'appointment', 'checkup', 'custom')),
  reminder_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'cancelled')),
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  therapy_id UUID REFERENCES public.therapies(therapy_id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('missed_medication', 'high_risk', 'treatment_completion', 'custom')),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.notifications (
  notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(profile_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chatbot_conversations (
  conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  title TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chatbot_logs (
  chatbot_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(patient_id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES public.chatbot_conversations(conversation_id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chatbot_messages (
  messages_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.chatbot_conversations(conversation_id) ON DELETE CASCADE,
  response TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_doctors_profile_id ON public.doctors(profile_id);
CREATE INDEX idx_doctor_codes_doctor_id ON public.doctor_codes(doctor_id);
CREATE INDEX idx_doctor_codes_code ON public.doctor_codes(code);
CREATE INDEX idx_patients_profile_id ON public.patients(profile_id);
CREATE INDEX idx_patients_doctor_id ON public.patients(doctor_id);
CREATE INDEX idx_doctor_code_usages_code_id ON public.doctor_code_usages(code_id);
CREATE INDEX idx_tb_cases_patient_id ON public.tb_cases(patient_id);
CREATE INDEX idx_patient_locations_patient_id ON public.patient_locations(patient_id);
CREATE INDEX idx_patient_locations_geo ON public.patient_locations USING GIST (ll_to_earth(latitude, longitude));
CREATE INDEX idx_therapies_patient_id ON public.therapies(patient_id);
CREATE INDEX idx_therapies_doctor_id ON public.therapies(doctor_id);
CREATE INDEX idx_therapy_phases_therapy_id ON public.therapy_phases(therapy_id);
CREATE INDEX idx_phase_medication_phase_id ON public.phase_medication(phase_id);
CREATE INDEX idx_medication_logs_patient_id ON public.medication_logs(patient_id);
CREATE INDEX idx_medication_logs_therapy_id ON public.medication_logs(therapy_id);
CREATE INDEX idx_medication_logs_scheduled_at ON public.medication_logs(scheduled_at);
CREATE INDEX idx_reminders_patient_id ON public.reminders(patient_id);
CREATE INDEX idx_alerts_patient_id ON public.alerts(patient_id);
CREATE INDEX idx_alerts_severity ON public.alerts(severity);
CREATE INDEX idx_notifications_profile_id ON public.notifications(profile_id);
CREATE INDEX idx_chatbot_conversations_patient_id ON public.chatbot_conversations(patient_id);
CREATE INDEX idx_chatbot_logs_conversation_id ON public.chatbot_logs(conversation_id);
CREATE INDEX idx_chatbot_messages_conversation_id ON public.chatbot_messages(conversation_id);

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_doctors_updated_at
BEFORE UPDATE ON public.doctors
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_patients_updated_at
BEFORE UPDATE ON public.patients
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_therapies_updated_at
BEFORE UPDATE ON public.therapies
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chatbot_conversations_updated_at
BEFORE UPDATE ON public.chatbot_conversations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.current_profile_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT profile_id FROM public.profiles WHERE user_id = auth.uid() AND is_active = true
$$;

CREATE OR REPLACE FUNCTION public.current_doctor_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT d.doctor_id
  FROM public.doctors d
  JOIN public.profiles p ON p.profile_id = d.profile_id
  WHERE p.user_id = auth.uid() AND p.role = 'doctor' AND p.is_active = true
$$;

CREATE OR REPLACE FUNCTION public.current_patient_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT pa.patient_id
  FROM public.patients pa
  JOIN public.profiles p ON p.profile_id = pa.profile_id
  WHERE p.user_id = auth.uid() AND p.role = 'patient' AND p.is_active = true
$$;

CREATE OR REPLACE FUNCTION public.is_assigned_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.patients pa
    WHERE pa.patient_id = p_patient_id
      AND pa.doctor_id = public.current_doctor_id()
  )
$$;

CREATE OR REPLACE FUNCTION public.complete_patient_registration(
  p_user_id UUID,
  p_email TEXT,
  p_full_name TEXT,
  p_doctor_code TEXT
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code public.doctor_codes%ROWTYPE;
  v_profile public.profiles%ROWTYPE;
  v_patient_id UUID;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized registration request';
  END IF;

  SELECT *
  INTO v_code
  FROM public.doctor_codes
  WHERE code = upper(trim(p_doctor_code))
    AND is_active = true
    AND expires_at > NOW()
  FOR UPDATE;

  IF NOT FOUND OR v_code.current_uses >= v_code.max_uses THEN
    RAISE EXCEPTION 'Invalid or expired doctor code';
  END IF;

  INSERT INTO public.profiles (profile_id, user_id, email, role, full_name)
  VALUES (p_user_id, p_user_id, lower(trim(p_email)), 'patient', nullif(trim(p_full_name), ''))
  ON CONFLICT (user_id) DO UPDATE
  SET email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = 'patient',
      updated_at = NOW()
  RETURNING * INTO v_profile;

  INSERT INTO public.patients (patient_id, profile_id, doctor_id)
  VALUES (p_user_id, v_profile.profile_id, v_code.doctor_id)
  ON CONFLICT (profile_id) DO UPDATE
  SET doctor_id = EXCLUDED.doctor_id,
      updated_at = NOW()
  RETURNING patient_id INTO v_patient_id;

  INSERT INTO public.doctor_code_usages (code_id, patient_id)
  VALUES (v_code.code_id, v_patient_id)
  ON CONFLICT (code_id, patient_id) DO NOTHING;

  UPDATE public.doctor_codes
  SET current_uses = current_uses + 1,
      is_active = CASE WHEN current_uses + 1 >= max_uses THEN false ELSE is_active END
  WHERE code_id = v_code.code_id;

  RETURN v_profile;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_patient_registration(UUID, TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_therapy_adherence()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_therapy_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_therapy_id := OLD.therapy_id;
  ELSE
    v_therapy_id := NEW.therapy_id;
  END IF;

  UPDATE public.therapies t
  SET adherence_percentage = COALESCE((
    SELECT ROUND(
      COUNT(*) FILTER (WHERE status = 'taken')::NUMERIC
      / NULLIF(COUNT(*) FILTER (WHERE status IN ('taken', 'missed', 'skipped'))::NUMERIC, 0)
      * 100,
      2
    )
    FROM public.medication_logs ml
    WHERE ml.therapy_id = v_therapy_id
  ), 0),
  updated_at = NOW()
  WHERE t.therapy_id = v_therapy_id;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER medication_logs_sync_therapy_adherence
AFTER INSERT OR UPDATE OR DELETE ON public.medication_logs
FOR EACH ROW EXECUTE FUNCTION public.sync_therapy_adherence();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_code_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapy_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phase_medication ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapy_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapy_status_histories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_related"
ON public.profiles FOR SELECT
USING (
  profile_id = public.current_profile_id()
  OR profile_id IN (SELECT profile_id FROM public.patients WHERE doctor_id = public.current_doctor_id())
  OR profile_id IN (
    SELECT d.profile_id
    FROM public.doctors d
    JOIN public.patients p ON p.doctor_id = d.doctor_id
    WHERE p.patient_id = public.current_patient_id()
  )
);

CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
USING (profile_id = public.current_profile_id())
WITH CHECK (profile_id = public.current_profile_id());

CREATE POLICY "doctors_select_related"
ON public.doctors FOR SELECT
USING (
  doctor_id = public.current_doctor_id()
  OR doctor_id IN (SELECT doctor_id FROM public.patients WHERE patient_id = public.current_patient_id())
);

CREATE POLICY "doctor_codes_select_own_or_valid"
ON public.doctor_codes FOR SELECT
USING (
  doctor_id = public.current_doctor_id()
  OR (is_active = true AND expires_at > NOW())
);

CREATE POLICY "doctor_codes_insert_own"
ON public.doctor_codes FOR INSERT
WITH CHECK (doctor_id = public.current_doctor_id());

CREATE POLICY "doctor_codes_update_own"
ON public.doctor_codes FOR UPDATE
USING (doctor_id = public.current_doctor_id())
WITH CHECK (doctor_id = public.current_doctor_id());

CREATE POLICY "doctor_code_usages_select_related"
ON public.doctor_code_usages FOR SELECT
USING (
  patient_id = public.current_patient_id()
  OR patient_id IN (SELECT patient_id FROM public.patients WHERE doctor_id = public.current_doctor_id())
);

CREATE POLICY "patients_select_self_or_doctor"
ON public.patients FOR SELECT
USING (patient_id = public.current_patient_id() OR doctor_id = public.current_doctor_id());

CREATE POLICY "patients_update_self_or_doctor"
ON public.patients FOR UPDATE
USING (patient_id = public.current_patient_id() OR doctor_id = public.current_doctor_id())
WITH CHECK (patient_id = public.current_patient_id() OR doctor_id = public.current_doctor_id());

CREATE POLICY "tb_cases_select_self_or_doctor"
ON public.tb_cases FOR SELECT
USING (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "tb_cases_insert_doctor"
ON public.tb_cases FOR INSERT
WITH CHECK (public.is_assigned_patient(patient_id));

CREATE POLICY "patient_locations_select_self_or_doctor"
ON public.patient_locations FOR SELECT
USING (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "patient_locations_insert_self"
ON public.patient_locations FOR INSERT
WITH CHECK (patient_id = public.current_patient_id());

CREATE POLICY "therapies_select_self_or_doctor"
ON public.therapies FOR SELECT
USING (patient_id = public.current_patient_id() OR doctor_id = public.current_doctor_id());

CREATE POLICY "therapies_insert_doctor"
ON public.therapies FOR INSERT
WITH CHECK (doctor_id = public.current_doctor_id() AND public.is_assigned_patient(patient_id));

CREATE POLICY "therapies_update_doctor"
ON public.therapies FOR UPDATE
USING (doctor_id = public.current_doctor_id())
WITH CHECK (doctor_id = public.current_doctor_id());

CREATE POLICY "therapy_phases_select_related"
ON public.therapy_phases FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_phases.therapy_id
      AND (t.patient_id = public.current_patient_id() OR t.doctor_id = public.current_doctor_id())
  )
);

CREATE POLICY "therapy_phases_write_doctor"
ON public.therapy_phases FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_phases.therapy_id
      AND t.doctor_id = public.current_doctor_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_phases.therapy_id
      AND t.doctor_id = public.current_doctor_id()
  )
);

CREATE POLICY "medication_read_authenticated"
ON public.medication FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "phase_medication_select_related"
ON public.phase_medication FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.therapy_phases tp
    JOIN public.therapies t ON t.therapy_id = tp.therapy_id
    WHERE tp.therapy_phase_id = phase_medication.phase_id
      AND (t.patient_id = public.current_patient_id() OR t.doctor_id = public.current_doctor_id())
  )
);

CREATE POLICY "medication_logs_select_related"
ON public.medication_logs FOR SELECT
USING (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "medication_logs_insert_self_or_doctor"
ON public.medication_logs FOR INSERT
WITH CHECK (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "medication_logs_update_self_or_doctor"
ON public.medication_logs FOR UPDATE
USING (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id))
WITH CHECK (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "therapy_progress_select_related"
ON public.therapy_progress FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_progress.therapy_id
      AND (t.patient_id = public.current_patient_id() OR t.doctor_id = public.current_doctor_id())
  )
);

CREATE POLICY "therapy_status_histories_select_related"
ON public.therapy_status_histories FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_status_histories.therapy_id
      AND (t.patient_id = public.current_patient_id() OR t.doctor_id = public.current_doctor_id())
  )
);

CREATE POLICY "therapy_status_histories_insert_doctor"
ON public.therapy_status_histories FOR INSERT
WITH CHECK (
  changed_by = public.current_profile_id()
  AND EXISTS (
    SELECT 1 FROM public.therapies t
    WHERE t.therapy_id = therapy_status_histories.therapy_id
      AND t.doctor_id = public.current_doctor_id()
  )
);

CREATE POLICY "reminders_select_self_or_doctor"
ON public.reminders FOR SELECT
USING (patient_id = public.current_patient_id() OR public.is_assigned_patient(patient_id));

CREATE POLICY "reminders_write_self"
ON public.reminders FOR ALL
USING (patient_id = public.current_patient_id())
WITH CHECK (patient_id = public.current_patient_id());

CREATE POLICY "alerts_select_doctor"
ON public.alerts FOR SELECT
USING (public.is_assigned_patient(patient_id));

CREATE POLICY "alerts_insert_doctor"
ON public.alerts FOR INSERT
WITH CHECK (public.is_assigned_patient(patient_id));

CREATE POLICY "notifications_select_own"
ON public.notifications FOR SELECT
USING (profile_id = public.current_profile_id());

CREATE POLICY "notifications_update_own"
ON public.notifications FOR UPDATE
USING (profile_id = public.current_profile_id())
WITH CHECK (profile_id = public.current_profile_id());

CREATE POLICY "chatbot_conversations_select_self"
ON public.chatbot_conversations FOR SELECT
USING (patient_id = public.current_patient_id());

CREATE POLICY "chatbot_conversations_insert_self"
ON public.chatbot_conversations FOR INSERT
WITH CHECK (patient_id = public.current_patient_id());

CREATE POLICY "chatbot_logs_select_self"
ON public.chatbot_logs FOR SELECT
USING (patient_id = public.current_patient_id());

CREATE POLICY "chatbot_logs_insert_self"
ON public.chatbot_logs FOR INSERT
WITH CHECK (patient_id = public.current_patient_id());

CREATE POLICY "chatbot_messages_select_self"
ON public.chatbot_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.chatbot_conversations c
    WHERE c.conversation_id = chatbot_messages.conversation_id
      AND c.patient_id = public.current_patient_id()
  )
);

CREATE POLICY "chatbot_messages_insert_self"
ON public.chatbot_messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.chatbot_conversations c
    WHERE c.conversation_id = chatbot_messages.conversation_id
      AND c.patient_id = public.current_patient_id()
  )
);

COMMIT;
