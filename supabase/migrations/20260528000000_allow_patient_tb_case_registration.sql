DROP POLICY IF EXISTS "tb_cases_insert_self" ON public.tb_cases;

CREATE POLICY "tb_cases_insert_self"
ON public.tb_cases FOR INSERT
WITH CHECK (patient_id = public.current_patient_id());
