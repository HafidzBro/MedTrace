DROP POLICY IF EXISTS "chatbot_conversations_update_self" ON public.chatbot_conversations;

CREATE POLICY "chatbot_conversations_update_self"
ON public.chatbot_conversations FOR UPDATE
USING (patient_id = public.current_patient_id())
WITH CHECK (patient_id = public.current_patient_id());
