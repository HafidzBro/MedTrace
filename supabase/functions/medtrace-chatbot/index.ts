import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ChatLog = {
  role: "user" | "assistant" | "system";
  message: string;
};

type GeminiContent = {
  role: "user" | "model";
  parts: { text: string }[];
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    const geminiModel = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

    if (!supabaseUrl || !supabaseAnonKey || !geminiApiKey) {
      return jsonResponse(
        {
          error:
            "Supabase URL, anon key, atau GEMINI_API_KEY belum tersedia di Edge Function secrets.",
        },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse(
        { error: "Authorization header tidak ditemukan." },
        401,
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return jsonResponse(
        { error: "User belum login atau token tidak valid." },
        401,
      );
    }

    const body = await req.json();
    const message = String(body.message ?? "").trim();
    const patientId = String(body.patient_id ?? "").trim();
    let conversationId = body.conversation_id
      ? String(body.conversation_id)
      : null;

    if (!message || !patientId) {
      return jsonResponse(
        { error: "message dan patient_id wajib dikirim." },
        400,
      );
    }

    const { data: patient, error: patientError } = await supabase
      .from("patients")
      .select("patient_id")
      .eq("patient_id", patientId)
      .maybeSingle();

    if (patientError || !patient) {
      return jsonResponse(
        { error: "Patient tidak ditemukan atau bukan milik user login." },
        403,
      );
    }

    if (!conversationId) {
      const { data: sessionData, error: sessionError } = await supabase
        .from("chatbot_conversations")
        .insert({
          patient_id: patientId,
          title: message.substring(0, 48),
        })
        .select("conversation_id")
        .single();

      if (sessionError) {
        return jsonResponse({ error: sessionError.message }, 500);
      }

      conversationId = sessionData.conversation_id;
    }

    const { error: userLogError } = await supabase.from("chatbot_logs").insert({
      patient_id: patientId,
      conversation_id: conversationId,
      role: "user",
      message,
    });

    if (userLogError) {
      return jsonResponse({ error: userLogError.message }, 500);
    }

    const { data: historyData } = await supabase
      .from("chatbot_logs")
      .select("role, message")
      .eq("conversation_id", conversationId)
      .order("created_at", { ascending: false })
      .limit(10);

    const history = ((historyData ?? []) as ChatLog[])
      .reverse()
      .map((item): GeminiContent => ({
        role: item.role === "assistant" ? "model" : "user",
        parts: [{ text: item.message }],
      }));

    const appContext = await patientAppContext(supabase, patientId);
    const systemPrompt = buildSystemPrompt(appContext);

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": geminiApiKey,
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }],
          },
          contents: history,
          generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 450,
          },
        }),
      },
    );

    const geminiData = await geminiResponse.json();
    if (!geminiResponse.ok) {
      return jsonResponse(
        {
          error: "Gagal memanggil Gemini API.",
          detail: geminiData,
        },
        500,
      );
    }

    const reply = extractGeminiText(geminiData) ??
      "Maaf, saya belum bisa menjawab saat ini.";

    const { error: assistantLogError } = await supabase
      .from("chatbot_logs")
      .insert({
        patient_id: patientId,
        conversation_id: conversationId,
        role: "assistant",
        message: reply,
      });

    if (assistantLogError) {
      return jsonResponse({ error: assistantLogError.message }, 500);
    }

    await supabase.from("chatbot_messages").insert({
      conversation_id: conversationId,
      response: reply,
    });

    await supabase
      .from("chatbot_conversations")
      .update({
        title: message.substring(0, 48),
        updated_at: new Date().toISOString(),
      })
      .eq("conversation_id", conversationId);

    return jsonResponse({
      reply,
      conversation_id: conversationId,
    });
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});

async function patientAppContext(supabase: any, patientId: string) {
  const { data: therapy } = await supabase
    .from("therapies")
    .select(
      "therapy_id, start_date, end_date, status, adherence_percentage, description, created_at",
    )
    .eq("patient_id", patientId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const therapyId = therapy?.therapy_id ?? null;

  const { data: phases } = therapyId
    ? await supabase
      .from("therapy_phases")
      .select(
        "therapy_phase_id, phase_name, phase_order, start_date, end_date, status, intake_time",
      )
      .eq("therapy_id", therapyId)
      .order("phase_order", { ascending: true })
    : { data: [] };

  const phaseIds = (phases ?? []).map((phase: any) => phase.therapy_phase_id);
  const { data: medications } = phaseIds.length > 0
    ? await supabase
      .from("phase_medication")
      .select(
        "phase_id, dosage, frequency, medication:medication_id(name, abbreviation, unit)",
      )
      .in("phase_id", phaseIds)
    : { data: [] };

  const { data: reminder } = await supabase
    .from("reminders")
    .select("reminder_time, status")
    .eq("patient_id", patientId)
    .eq("reminder_type", "medication")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const { data: recentLogs } = therapyId
    ? await supabase
      .from("medication_logs")
      .select("scheduled_at, taken_at, status")
      .eq("therapy_id", therapyId)
      .order("scheduled_at", { ascending: false })
      .limit(7)
    : { data: [] };

  return {
    therapy,
    phases,
    medications,
    medication_reminder: reminder,
    recent_medication_logs: recentLogs,
  };
}

function buildSystemPrompt(appContext: unknown) {
  return `
Kamu adalah MedTrace Assistant, chatbot pendamping pasien TBC di aplikasi MedTrace.

Peran:
- Membantu pasien memahami jadwal terapi, pengingat obat, progres terapi, dan edukasi umum TBC.
- Jawab dalam bahasa Indonesia yang sederhana, empatik, singkat, dan mudah diikuti.
- Tanyakan maksimal 2 pertanyaan lanjutan jika informasi pasien belum cukup.
- Jangan memberikan diagnosis pasti.
- Jangan mengubah dosis, frekuensi, atau durasi obat.
- Jangan menyuruh pasien menghentikan obat.
- Jangan menggantikan keputusan dokter atau fasilitas kesehatan.
- Jika pasien menyebut sesak berat, pingsan, batuk darah banyak, nyeri dada berat, reaksi alergi berat, demam tinggi berkepanjangan, atau kondisi memburuk, arahkan segera ke dokter/fasilitas kesehatan.

Data aplikasi pasien yang boleh digunakan:
${JSON.stringify(appContext, null, 2)}
`;
}

function extractGeminiText(data: any): string | null {
  const parts = data?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return null;

  const text = parts
    .map((part) => part?.text)
    .filter((text: unknown) => typeof text === "string")
    .join("")
    .trim();

  if (!text) {
    return null;
  }

  return text;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
