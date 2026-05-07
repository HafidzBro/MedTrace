-- Production hardening for MedTrace registration and strict role isolation.
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  phone_number TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  address TEXT,
  latitude NUMERIC(10, 8),
  longitude NUMERIC(11, 8),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT doctor_must_be_different CHECK (doctor_id <> id)
);

CREATE INDEX IF NOT EXISTS idx_patients_doctor_id ON public.patients(doctor_id);

DROP TRIGGER IF EXISTS update_patients_updated_at ON public.patients;
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read other profiles" ON public.profiles;
DROP POLICY IF EXISTS "Doctors can read assigned patient profiles" ON public.profiles;
DROP POLICY IF EXISTS "Patients can read assigned doctor profile" ON public.profiles;
DROP POLICY IF EXISTS "Patients can insert own profile during registration" ON public.profiles;

CREATE POLICY "Doctors can read assigned patient profiles"
ON public.profiles
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.doctor_patients dp
    WHERE dp.doctor_id = auth.uid()
      AND dp.patient_id = profiles.id
  )
);

CREATE POLICY "Patients can read assigned doctor profile"
ON public.profiles
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.doctor_patients dp
    WHERE dp.patient_id = auth.uid()
      AND dp.doctor_id = profiles.id
  )
);

CREATE POLICY "Patients can insert own profile during registration"
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id AND role = 'patient');

DROP POLICY IF EXISTS "Patients can read own patient record" ON public.patients;
DROP POLICY IF EXISTS "Doctors can read assigned patient records" ON public.patients;
DROP POLICY IF EXISTS "Patients can update own contact and location" ON public.patients;

CREATE POLICY "Patients can read own patient record"
ON public.patients
FOR SELECT
USING (id = auth.uid());

CREATE POLICY "Doctors can read assigned patient records"
ON public.patients
FOR SELECT
USING (doctor_id = auth.uid());

CREATE POLICY "Patients can update own contact and location"
ON public.patients
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Doctors can update patient treatments" ON public.treatments;
CREATE POLICY "Doctors can update patient treatments"
ON public.treatments
FOR UPDATE
USING (doctor_id = auth.uid())
WITH CHECK (doctor_id = auth.uid());

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

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_code.doctor_id AND role = 'doctor' AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Doctor code is not linked to an active doctor';
  END IF;

  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (p_user_id, lower(trim(p_email)), 'patient', nullif(trim(p_full_name), ''))
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = 'patient',
      updated_at = NOW()
  RETURNING * INTO v_profile;

  INSERT INTO public.doctor_patients (doctor_id, patient_id, registration_code_id)
  VALUES (v_code.doctor_id, p_user_id, v_code.id)
  ON CONFLICT (doctor_id, patient_id) DO NOTHING;

  INSERT INTO public.patients (id, doctor_id)
  VALUES (p_user_id, v_code.doctor_id)
  ON CONFLICT (id) DO UPDATE
  SET doctor_id = EXCLUDED.doctor_id,
      updated_at = NOW();

  UPDATE public.doctor_codes
  SET current_uses = current_uses + 1
  WHERE id = v_code.id;

  RETURN v_profile;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_patient_registration(UUID, TEXT, TEXT, TEXT) TO authenticated;

CREATE TABLE IF NOT EXISTS public.chatbot_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES public.chatbot_conversations(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chatbot_logs_patient_id ON public.chatbot_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_logs_conversation_id ON public.chatbot_logs(conversation_id);
ALTER TABLE public.chatbot_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients can read own chatbot logs" ON public.chatbot_logs;
DROP POLICY IF EXISTS "Patients can create own chatbot logs" ON public.chatbot_logs;

CREATE POLICY "Patients can read own chatbot logs"
ON public.chatbot_logs
FOR SELECT
USING (patient_id = auth.uid());

CREATE POLICY "Patients can create own chatbot logs"
ON public.chatbot_logs
FOR INSERT
WITH CHECK (patient_id = auth.uid());

CREATE OR REPLACE FUNCTION public.log_chatbot_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id UUID;
BEGIN
  SELECT patient_id INTO v_patient_id
  FROM public.chatbot_conversations
  WHERE id = NEW.conversation_id;

  IF v_patient_id IS NOT NULL THEN
    INSERT INTO public.chatbot_logs (conversation_id, patient_id, role, message, created_at)
    VALUES (NEW.conversation_id, v_patient_id, NEW.role, NEW.message, NEW.created_at);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS mirror_chatbot_messages_to_logs ON public.chatbot_messages;
CREATE TRIGGER mirror_chatbot_messages_to_logs
AFTER INSERT ON public.chatbot_messages
FOR EACH ROW EXECUTE FUNCTION public.log_chatbot_message();

CREATE OR REPLACE VIEW public.treatment_adherence AS
SELECT
  t.id AS treatment_id,
  t.patient_id,
  t.doctor_id,
  CASE
    WHEN COUNT(ml.id) FILTER (WHERE ml.status IN ('taken', 'missed', 'skipped')) = 0 THEN 0::NUMERIC
    ELSE ROUND(
      (
        COUNT(ml.id) FILTER (WHERE ml.status = 'taken')::NUMERIC
        / COUNT(ml.id) FILTER (WHERE ml.status IN ('taken', 'missed', 'skipped'))::NUMERIC
      ) * 100,
      2
    )
  END AS adherence_percentage
FROM public.treatments t
LEFT JOIN public.medications m ON m.treatment_id = t.id
LEFT JOIN public.medication_logs ml ON ml.medication_id = m.id
GROUP BY t.id, t.patient_id, t.doctor_id;
