// functions/index.js
const functions = require("firebase-functions");
const { generateExerciseRecommendation } = require("./gemini");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "senior-fitness-app" });
  console.log("🔥 Firebase Admin inicializado correctamente (index.js)");
}

const db = admin.firestore();

// ======================================================
// 🧠 Función principal de Sofi
// ======================================================
exports.generateExerciseRecommendation = generateExerciseRecommendation;

// ======================================================
// 🧩 Función: checkUser (ID o Email, con retorno del ID real)
// ======================================================
exports.checkUser = functions.https.onRequest(async (req, res) => {
  try {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") return res.status(204).send("");

    const { userId, email } = req.query;
    if (!userId && !email)
      return res.status(400).json({ error: "Falta userId o email en la query" });

    const cleanUserId = userId?.trim();
    const cleanEmail = email?.trim().toLowerCase();

    let docSnap = null;
    let foundBy = null;

    // 1️⃣ Intentar buscar por ID
    if (cleanUserId) {
      const doc = await db.collection("users").doc(cleanUserId).get();
      if (doc.exists) {
        docSnap = doc;
        foundBy = "id";
      }
    }

    // 2️⃣ Buscar por correo si no se encontró
    if (!docSnap && cleanEmail) {
      const q = await db.collection("users").where("email", "==", cleanEmail).limit(1).get();
      if (!q.empty) {
        docSnap = q.docs[0];
        foundBy = "email";
      }
    }

    // 3️⃣ No encontrado
    if (!docSnap) {
      return res.status(404).json({
        found: false,
        message: "❌ Usuario no encontrado en Firestore",
        searched: { by: userId ? "userId" : "email", value: userId || email },
      });
    }

    // 4️⃣ Usuario encontrado
    const user = docSnap.data();
    return res.status(200).json({
      found: true,
      message: "✅ Usuario encontrado correctamente",
      foundBy,
      realUserId: docSnap.id, // 👈 aquí te devuelve el ID verdadero del documento
      name: user.name || "Sin nombre",
      email: user.email,
      age: user.age ?? null,
      gender: user.gender || "No especificado",
      level: user.level || user.fitness_level || "principiante",
    });
  } catch (err) {
    console.error("❌ Error en checkUser:", err);
    return res.status(500).json({ error: err.message });
  }
});
