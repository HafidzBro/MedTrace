-- 002_registration.sql
-- Adds doctor_codes usage tracking, profiles insert policy and a helper RPC to complete patient registration atomically

BEGIN;

-- doctor_codes columns are created in the initial migration (001_init.sql) — no ALTER required here

-- Allow users to insert their own profile row (id must equal auth.uid())
CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
USING (auth.role() = 'service_role' OR id = auth.uid())
WITH CHECK (id = auth.uid());

-- Helper RPC: complete_patient_registration
-- Validates doctor code, inserts profile and patient records, increments usage counter
CREATE OR REPLACE FUNCTION public.complete_patient_registration(
  p_user_id uuid,
  p_email text,
  p_full_name text,
  p_doctor_code text
)
RETURNS TABLE(
  id uuid,
  full_name text,
  email text,
  role text,
  doctor_id uuid,
  created_at timestamptz
) LANGUAGE plpgsql AS $$
DECLARE
  c record;
  new_profile_id uuid;
BEGIN
  -- Validate code
  SELECT * INTO c FROM public.doctor_codes WHERE code = p_doctor_code AND is_active = true LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired doctor code';
  END IF;

  -- Insert or update profile (patient)
  INSERT INTO public.profiles (id, full_name, email, role, doctor_id, created_at)
  VALUES (p_user_id, p_full_name, p_email, 'patient', c.doctor_id, now())
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, email = EXCLUDED.email, updated_at = now();

  -- Create patient row if not exists
  INSERT INTO public.patients (profile_id, doctor_id, created_at)
  VALUES (p_user_id, c.doctor_id, now())
  ON CONFLICT (profile_id) DO NOTHING;

  -- Increment current_uses and deactivate if exceeding max_uses
  UPDATE public.doctor_codes
  SET current_uses = current_uses + 1,
      is_active = CASE WHEN (current_uses + 1) >= max_uses THEN false ELSE is_active END
  WHERE id = c.id;

  -- Return the created profile
  RETURN QUERY
  SELECT id, full_name, email, role, doctor_id, created_at FROM public.profiles WHERE id = p_user_id;
END;
$$;

COMMIT;
