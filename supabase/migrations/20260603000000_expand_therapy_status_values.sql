-- Allow doctor-facing therapy statuses to be stored directly in therapies.status.
-- This keeps Patient Directory, Patient Detail, and Map aligned on one source.

ALTER TABLE public.therapies
DROP CONSTRAINT IF EXISTS therapies_status_check;

ALTER TABLE public.therapies
ADD CONSTRAINT therapies_status_check
CHECK (
  status IN (
    'registered',
    'ongoing',
    'on_treatment',
    'at_risk',
    'completed',
    'defaulted',
    'paused',
    'failed'
  )
);
