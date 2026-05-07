-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES TABLE POLICIES
-- ============================================================

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() = id);

-- Doctors can read only profiles of patients linked to them.
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

-- Patients can read only their assigned doctor's public profile.
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

-- New auth users can create their own patient profile only.
CREATE POLICY "Patients can insert own profile during registration"
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id AND role = 'patient');

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ============================================================
-- PATIENTS TABLE POLICIES
-- ============================================================

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

-- ============================================================
-- DOCTOR_CODES TABLE POLICIES
-- ============================================================

-- Doctors can see their own codes
CREATE POLICY "Doctors can create and view their codes"
ON public.doctor_codes
FOR SELECT
USING (
  doctor_id = auth.uid()
);

-- Doctors can insert codes
CREATE POLICY "Doctors can create codes"
ON public.doctor_codes
FOR INSERT
WITH CHECK (
  doctor_id = auth.uid() AND
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'doctor'
);

-- Anyone can validate a code (for patient registration)
CREATE POLICY "Anyone can validate doctor codes"
ON public.doctor_codes
FOR SELECT
USING (is_active = true AND expires_at > NOW());

-- ============================================================
-- DOCTOR_PATIENTS TABLE POLICIES
-- ============================================================

-- Doctors can see their patients
CREATE POLICY "Doctors can see their patients"
ON public.doctor_patients
FOR SELECT
USING (doctor_id = auth.uid());

-- Patients can see their doctor assignment
CREATE POLICY "Patients can see their doctor"
ON public.doctor_patients
FOR SELECT
USING (patient_id = auth.uid());

-- System can create doctor-patient relationships
CREATE POLICY "Doctor patients insert by doctor"
ON public.doctor_patients
FOR INSERT
WITH CHECK (doctor_id = auth.uid());

-- Patients can complete their own link only through a still-valid registration code.
CREATE POLICY "Patients can insert own doctor link with valid code"
ON public.doctor_patients
FOR INSERT
WITH CHECK (
  patient_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.doctor_codes dc
    WHERE dc.id = registration_code_id
      AND dc.doctor_id = doctor_patients.doctor_id
      AND dc.is_active = true
      AND dc.expires_at > NOW()
      AND dc.current_uses < dc.max_uses
  )
);

-- ============================================================
-- TREATMENTS TABLE POLICIES
-- ============================================================

-- Patients can read their own treatments
CREATE POLICY "Patients can read own treatments"
ON public.treatments
FOR SELECT
USING (patient_id = auth.uid());

-- Doctors can read treatments of their patients
CREATE POLICY "Doctors can read patient treatments"
ON public.treatments
FOR SELECT
USING (
  doctor_id = auth.uid() OR
  patient_id IN (
    SELECT patient_id FROM public.doctor_patients WHERE doctor_id = auth.uid()
  )
);

-- Doctors can update treatments of their patients
CREATE POLICY "Doctors can update patient treatments"
ON public.treatments
FOR UPDATE
USING (
  doctor_id = auth.uid()
)
WITH CHECK (
  doctor_id = auth.uid()
);

-- Doctors can create treatments for their patients
CREATE POLICY "Doctors can create treatments"
ON public.treatments
FOR INSERT
WITH CHECK (
  doctor_id = auth.uid()
);

-- ============================================================
-- MEDICATIONS TABLE POLICIES
-- ============================================================

-- Patients can read their medications
CREATE POLICY "Patients can read own medications"
ON public.medications
FOR SELECT
USING (
  treatment_id IN (
    SELECT id FROM public.treatments WHERE patient_id = auth.uid()
  )
);

-- Doctors can read medications for their patients
CREATE POLICY "Doctors can read patient medications"
ON public.medications
FOR SELECT
USING (
  treatment_id IN (
    SELECT id FROM public.treatments WHERE doctor_id = auth.uid()
  )
);

-- Doctors can create medications
CREATE POLICY "Doctors can create medications"
ON public.medications
FOR INSERT
WITH CHECK (
  treatment_id IN (
    SELECT id FROM public.treatments WHERE doctor_id = auth.uid()
  )
);

-- Doctors can update medications
CREATE POLICY "Doctors can update medications"
ON public.medications
FOR UPDATE
USING (
  treatment_id IN (
    SELECT id FROM public.treatments WHERE doctor_id = auth.uid()
  )
)
WITH CHECK (
  treatment_id IN (
    SELECT id FROM public.treatments WHERE doctor_id = auth.uid()
  )
);

-- ============================================================
-- MEDICATION_LOGS TABLE POLICIES
-- ============================================================

-- Patients can read their medication logs
CREATE POLICY "Patients can read own medication logs"
ON public.medication_logs
FOR SELECT
USING (patient_id = auth.uid());

-- Patients can insert medication logs
CREATE POLICY "Patients can create medication logs"
ON public.medication_logs
FOR INSERT
WITH CHECK (patient_id = auth.uid());

-- Patients can update their medication logs
CREATE POLICY "Patients can update medication logs"
ON public.medication_logs
FOR UPDATE
USING (patient_id = auth.uid())
WITH CHECK (patient_id = auth.uid());

-- Doctors can read medication logs of their patients
CREATE POLICY "Doctors can read patient medication logs"
ON public.medication_logs
FOR SELECT
USING (
  patient_id IN (
    SELECT patient_id FROM public.doctor_patients WHERE doctor_id = auth.uid()
  )
);

-- ============================================================
-- REMINDERS TABLE POLICIES
-- ============================================================

-- Patients can read their reminders
CREATE POLICY "Patients can read own reminders"
ON public.reminders
FOR SELECT
USING (patient_id = auth.uid());

-- Patients can create reminders
CREATE POLICY "Patients can create reminders"
ON public.reminders
FOR INSERT
WITH CHECK (patient_id = auth.uid());

-- Patients can update their reminders
CREATE POLICY "Patients can update reminders"
ON public.reminders
FOR UPDATE
USING (patient_id = auth.uid())
WITH CHECK (patient_id = auth.uid());

-- ============================================================
-- PATIENT_LOCATIONS TABLE POLICIES
-- ============================================================

-- Patients can create their location records
CREATE POLICY "Patients can create location records"
ON public.patient_locations
FOR INSERT
WITH CHECK (patient_id = auth.uid());

-- Patients can read their own locations
CREATE POLICY "Patients can read own locations"
ON public.patient_locations
FOR SELECT
USING (patient_id = auth.uid());

-- Doctors can read locations of their patients
CREATE POLICY "Doctors can read patient locations"
ON public.patient_locations
FOR SELECT
USING (
  patient_id IN (
    SELECT patient_id FROM public.doctor_patients WHERE doctor_id = auth.uid()
  )
);

-- ============================================================
-- CHATBOT_CONVERSATIONS TABLE POLICIES
-- ============================================================

-- Patients can read their conversations
CREATE POLICY "Patients can read own conversations"
ON public.chatbot_conversations
FOR SELECT
USING (patient_id = auth.uid());

-- Patients can create conversations
CREATE POLICY "Patients can create conversations"
ON public.chatbot_conversations
FOR INSERT
WITH CHECK (patient_id = auth.uid());

-- ============================================================
-- CHATBOT_MESSAGES TABLE POLICIES
-- ============================================================

-- Patients can read messages from their conversations
CREATE POLICY "Patients can read own messages"
ON public.chatbot_messages
FOR SELECT
USING (
  conversation_id IN (
    SELECT id FROM public.chatbot_conversations WHERE patient_id = auth.uid()
  )
);

-- Patients can create messages
CREATE POLICY "Patients can create messages"
ON public.chatbot_messages
FOR INSERT
WITH CHECK (
  conversation_id IN (
    SELECT id FROM public.chatbot_conversations WHERE patient_id = auth.uid()
  )
);

-- ============================================================
-- CHATBOT_LOGS TABLE POLICIES
-- ============================================================

CREATE POLICY "Patients can read own chatbot logs"
ON public.chatbot_logs
FOR SELECT
USING (patient_id = auth.uid());

CREATE POLICY "Patients can create own chatbot logs"
ON public.chatbot_logs
FOR INSERT
WITH CHECK (patient_id = auth.uid());

-- ============================================================
-- ALERTS TABLE POLICIES
-- ============================================================

-- Doctors can read their alerts
CREATE POLICY "Doctors can read own alerts"
ON public.alerts
FOR SELECT
USING (doctor_id = auth.uid());

-- Doctors can update their alerts
CREATE POLICY "Doctors can update own alerts"
ON public.alerts
FOR UPDATE
USING (doctor_id = auth.uid())
WITH CHECK (doctor_id = auth.uid());

-- Doctors can create alerts for their patients
CREATE POLICY "Doctors can create alerts"
ON public.alerts
FOR INSERT
WITH CHECK (
  doctor_id = auth.uid() AND patient_id IN (
    SELECT patient_id FROM public.doctor_patients WHERE doctor_id = auth.uid()
  )
);

-- ============================================================
-- NOTIFICATIONS TABLE POLICIES
-- ============================================================

-- Users can read their notifications
CREATE POLICY "Users can read own notifications"
ON public.notifications
FOR SELECT
USING (user_id = auth.uid());

-- Users can update their notifications
CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
