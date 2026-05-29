CREATE OR REPLACE FUNCTION public.create_default_patient_therapy(
  p_patient_id UUID,
  p_tb_case_id UUID,
  p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_doctor_id UUID;
  v_therapy_id UUID;
  v_intensive_phase_id UUID;
  v_continuation_phase_id UUID;
  v_start_date DATE := CURRENT_DATE;
  v_rif_id UUID;
  v_inh_id UUID;
  v_pza_id UUID;
  v_emb_id UUID;
BEGIN
  SELECT doctor_id INTO v_doctor_id
  FROM public.patients
  WHERE patient_id = p_patient_id;

  IF v_doctor_id IS NULL THEN
    RAISE EXCEPTION 'Patient is not assigned to a doctor';
  END IF;

  SELECT therapy_id INTO v_therapy_id
  FROM public.therapies
  WHERE patient_id = p_patient_id
    AND status IN ('ongoing', 'on_treatment')
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_therapy_id IS NULL THEN
    INSERT INTO public.therapies (
      tb_case_id,
      patient_id,
      doctor_id,
      start_date,
      status,
      adherence_percentage,
      description
    )
    VALUES (
      p_tb_case_id,
      p_patient_id,
      v_doctor_id,
      v_start_date,
      'on_treatment',
      0,
      p_description
    )
    RETURNING therapy_id INTO v_therapy_id;
  END IF;

  INSERT INTO public.therapy_phases (
    therapy_id,
    phase_name,
    phase_order,
    start_month,
    end_month,
    start_date,
    end_date,
    frequency,
    intake_time,
    instructions,
    status
  )
  VALUES (
    v_therapy_id,
    'Intensive Phase',
    1,
    1,
    2,
    v_start_date,
    v_start_date + INTERVAL '2 months',
    'daily',
    '08:00',
    'Take medication after breakfast. Submit VDOT when possible.',
    'active'
  )
  ON CONFLICT (therapy_id, phase_order) DO UPDATE
  SET phase_name = EXCLUDED.phase_name,
      start_month = EXCLUDED.start_month,
      end_month = EXCLUDED.end_month,
      frequency = EXCLUDED.frequency,
      intake_time = EXCLUDED.intake_time,
      instructions = EXCLUDED.instructions,
      status = EXCLUDED.status
  RETURNING therapy_phase_id INTO v_intensive_phase_id;

  INSERT INTO public.therapy_phases (
    therapy_id,
    phase_name,
    phase_order,
    start_month,
    end_month,
    start_date,
    end_date,
    frequency,
    intake_time,
    instructions,
    status
  )
  VALUES (
    v_therapy_id,
    'Continuation Phase',
    2,
    3,
    6,
    v_start_date + INTERVAL '2 months',
    v_start_date + INTERVAL '6 months',
    'daily',
    '08:00',
    'Take medication after breakfast. Do not skip doses.',
    'pending'
  )
  ON CONFLICT (therapy_id, phase_order) DO UPDATE
  SET phase_name = EXCLUDED.phase_name,
      start_month = EXCLUDED.start_month,
      end_month = EXCLUDED.end_month,
      frequency = EXCLUDED.frequency,
      intake_time = EXCLUDED.intake_time,
      instructions = EXCLUDED.instructions,
      status = EXCLUDED.status
  RETURNING therapy_phase_id INTO v_continuation_phase_id;

  INSERT INTO public.medication (code, name, abbreviation, description)
  VALUES
    ('RIF', 'Rifampicin', 'RIF', 'First-line TB medication'),
    ('INH', 'Isoniazid', 'INH', 'First-line TB medication'),
    ('PZA', 'Pyrazinamide', 'PZA', 'First-line TB medication'),
    ('EMB', 'Ethambutol', 'EMB', 'First-line TB medication')
  ON CONFLICT (code) DO UPDATE
  SET name = EXCLUDED.name,
      abbreviation = EXCLUDED.abbreviation,
      description = EXCLUDED.description;

  SELECT medication_id INTO v_rif_id FROM public.medication WHERE code = 'RIF';
  SELECT medication_id INTO v_inh_id FROM public.medication WHERE code = 'INH';
  SELECT medication_id INTO v_pza_id FROM public.medication WHERE code = 'PZA';
  SELECT medication_id INTO v_emb_id FROM public.medication WHERE code = 'EMB';

  INSERT INTO public.phase_medication (phase_id, medication_id, dosage, unit)
  VALUES
    (v_intensive_phase_id, v_rif_id, 600, 'mg'),
    (v_intensive_phase_id, v_inh_id, 300, 'mg'),
    (v_intensive_phase_id, v_pza_id, 1500, 'mg'),
    (v_intensive_phase_id, v_emb_id, 1200, 'mg'),
    (v_continuation_phase_id, v_rif_id, 600, 'mg'),
    (v_continuation_phase_id, v_inh_id, 300, 'mg')
  ON CONFLICT (phase_id, medication_id) DO UPDATE
  SET dosage = EXCLUDED.dosage,
      unit = EXCLUDED.unit;

  INSERT INTO public.therapy_progress (
    therapy_id,
    days_on_therapy,
    last_calculated
  )
  VALUES (v_therapy_id, 1, NOW())
  ON CONFLICT (therapy_id) DO UPDATE
  SET days_on_therapy = EXCLUDED.days_on_therapy,
      last_calculated = EXCLUDED.last_calculated;

  RETURN v_therapy_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_default_patient_therapy(UUID, UUID, TEXT) TO authenticated;
