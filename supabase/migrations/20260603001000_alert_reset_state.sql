-- Let therapy reset archive existing alerts without deleting clinical records.

ALTER TABLE public.alerts
ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.alerts
ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

DROP POLICY IF EXISTS "alerts_update_doctor" ON public.alerts;

CREATE POLICY "alerts_update_doctor"
ON public.alerts FOR UPDATE
USING (public.is_assigned_patient(patient_id))
WITH CHECK (public.is_assigned_patient(patient_id));
