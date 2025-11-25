
// functions/gemini.js
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const { VertexAI } = require("@google-cloud/vertexai");

// Inicializa Firebase Admin una sola vez
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "senior-fitness-app", // fuerza a usar el proyecto correcto
  });
  console.log(" Firebase Admin inicializado correctamente");
  console.log(" Proyecto detectado:", process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT);
}

exports.generateExerciseRecommendation = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      // --- Healthcheck ---
      if (req.method === "GET") {
        console.log(" Healthcheck recibido");
        return res.status(200).json({
          ok: true,
          message: " Endpoint activo. Usa POST con { userId } para obtener una recomendación."
        });
      }

      if (req.method === "OPTIONS") return res.status(204).send("");

      if (req.method !== "POST") {
        console.warn(" Método no permitido:", req.method);
        return res.status(405).json({
          error: "Método no permitido",
          recommendation: "Usa POST con { userId } para obtener tu recomendación 🌿"
        });
      }

      // --- Entrada ---
      let { userId } = req.body || {};
      console.log(" Solicitud recibida para userId:", userId);

      //  Limpieza del userId (para evitar caracteres ocultos o saltos de línea)
      if (typeof userId === "string") {
        userId = userId.trim();
      }

      if (!userId) {
        return res.status(400).json({
          error: "Falta userId",
          recommendation: "Necesito tu perfil para personalizar la recomendación 🌟"
        });
      }

      // --- Datos de Firestore ---
      const db = admin.firestore();
      console.log(" Intentando leer usuario de Firestore (colección 'users')...");
      let docSnap = await db.collection("users").doc(userId).get();

      if (!docSnap.exists) {
        console.log(" No existe documento con ese ID. Intentando buscar por email...");
        const q = await db.collection("users").where("email", "==", userId).limit(1).get();

        if (q.empty) {
          console.error(" Usuario no encontrado en Firestore.");
          return res.status(404).json({
            found: false,
            message: " Usuario no encontrado en Firestore",
            project: "senior-fitness-app"
          });
        }

        docSnap = q.docs[0];
      }

      console.log(" Usuario encontrado correctamente en Firestore.");
      const user = docSnap.data() || {};
      console.log(" Datos del usuario:", JSON.stringify(user, null, 2));

      const name = user.name || "Usuario";
      const age = user.age ?? 65;
      const gender = user.gender || "No especificado";
      const level = user.fitness_level || "principiante";
      const mood = user.mood || "neutral";
      const conditions = Array.isArray(user.chronic_conditions)
        ? user.chronic_conditions
        : ["Ninguna"];
      const lastActivity = user.last_exercise_completed || "nunca";

      // --- Prompt dinámico ---
      const prompt = `
Eres **Sofi**, la entrenadora virtual de *Senior Fitness*.
Tu objetivo es motivar, cuidar y acompañar al usuario con empatía.

Datos del usuario:
- Nombre: ${name}
- Edad: ${age} años
- Género: ${gender}
- Nivel físico: ${level}
- Estado de ánimo actual: ${mood}
- Condiciones médicas: ${conditions.join(", ")}
- Último ejercicio: ${lastActivity}

Instrucciones:
1. Usa un tono cálido, natural y cercano. No suenes robótica.
2. Ofrece una recomendación de ejercicio segura y adaptada al nivel y estado de ánimo.
3. Incluye una breve justificación y un consejo de bienestar general.
4. Si el usuario está "cansado", prioriza ejercicios suaves o de respiración.
5. Si está "motivado", sugiere algo un poco más activo (dentro de su nivel).
6. Devuelve el resultado en formato JSON con esta estructura:

{
  "mensaje": "...",
  "ejercicio": {
    "nombre": "...",
    "duracion": "...",
    "tipo": "...",
    "nivel": "...",
    "consejo": "..."
  }
}

Usa máximo 2 emojis.
`.trim();

      // --- Configuración Vertex AI ---
      const project = process.env.GCLOUD_PROJECT || "senior-fitness-app";
      const location = "us-east1";
      console.log(" VertexAI conectado a proyecto:", project, "| región:", location);

      const vertexAI = new VertexAI({ project, location });
      const model = vertexAI.getGenerativeModel({ model: "gemini-2.5-flash" });

      console.log(" Solicitando respuesta a Gemini 2.5 Flash...");
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.8, topP: 0.9, maxOutputTokens: 512 }
      });

      let rawText = "";
      try {
        rawText = result.response.text();
      } catch {
        const candidates = result?.response?.candidates || [];
        for (const c of candidates) {
          const parts = c?.content?.parts || [];
          for (const p of parts) if (typeof p?.text === "string") rawText += p.text;
        }
      }

      // 🧹 Limpieza avanzada del texto antes de parsear
      rawText = rawText
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .replace(/^.*?{/, "{")
        .replace(/}[^}]*$/, "}")
        .trim();

      let recommendation;
      try {
        recommendation = JSON.parse(rawText);
      } catch (err) {
        console.warn(" No se pudo parsear JSON. Texto recibido:", rawText);
        recommendation = {
          mensaje: "¡Hola! 🌞 Hoy te recomiendo hacer algunos estiramientos suaves y mantenerte hidratado.",
          ejercicio: {
            nombre: "Estiramiento de cuello y hombros",
            duracion: "5 minutos",
            tipo: "flexibilidad",
            nivel: level,
            consejo: "Haz movimientos lentos y suaves, sin forzar."
          }
        };
      }

      // --- Respuesta final ---
      console.log(" Recomendación generada correctamente para", name);
      return res.status(200).json({
        recommendation,
        userId,
        source: rawText ? "gemini" : "fallback",
        model: "gemini-2.5-flash",
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      console.error(" Error general:", err);
      return res.status(500).json({
        error: "Error interno del servidor",
        recommendation: {
          mensaje: "Hoy te recomiendo moverte un poquito y sonreír 🌿",
          ejercicio: {
            nombre: "Caminata corta",
            duracion: "5 minutos",
            tipo: "movilidad",
            nivel: "principiante",
            consejo: "Da pasos suaves y respira profundo."
          }
        },
        source: "fallback",
        model: null,
        timestamp: new Date().toISOString()
      });
    }
  });
});
