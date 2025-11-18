from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
import openai
import os
from typing import List, Optional
import json

app = FastAPI(title="Senior Fitness API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)
openai.api_key = os.getenv("OPENAI_API_KEY")

# Modelos
class UserProfile(BaseModel):
    email: str
    name: str
    age: int
    gender: str
    chronic_conditions: List[str]

class ExerciseRequest(BaseModel):
    user_email: str
    conditions: List[str]
    activity_level: str = "principiante"

# Corpus de ejercicios (tu JSON)
EXERCISE_CORPUS = [
    {
        "id": 1,
        "condicion": "Hipertensión",
        "ejercicio": "Caminata ligera",
        "descripcion": "Caminar a paso tranquilo durante 20-30 minutos en superficie plana.",
        "nivel": "Bajo",
        "beneficios": "Mejora la circulación y ayuda a controlar la presión arterial.",
        "banderas_rojas": "Evitar subidas muy pronunciadas o caminar bajo altas temperaturas."
    },
    {
        "id": 2,
        "condicion": "Diabetes tipo 2",
        "ejercicio": "Ejercicios de resistencia con bandas elásticas",
        "descripcion": "Realizar 2-3 series de 10 repeticiones con bandas suaves.",
        "nivel": "Moderado",
        "beneficios": "Mejora la sensibilidad a la insulina y mantiene la masa muscular.",
        "banderas_rojas": "Evitar ejercicios intensos sin control de glicemia."
    },
    {
        "id": 3,
        "condicion": "Artrosis",
        "ejercicio": "Movilidad articular en silla",
        "descripcion": "Rotación suave de hombros, tobillos y rodillas sentado en una silla.",
        "nivel": "Bajo",
        "beneficios": "Reduce la rigidez y mejora la movilidad de las articulaciones.",
        "banderas_rojas": "Evitar movimientos bruscos o de alto impacto."
    },
    {
        "id": 4,
        "condicion": "Osteoporosis",
        "ejercicio": "Ejercicios de equilibrio",
        "descripcion": "Caminar en línea recta levantando ligeramente las rodillas.",
        "nivel": "Bajo",
        "beneficios": "Reduce el riesgo de caídas y fortalece el equilibrio.",
        "banderas_rojas": "Evitar ejercicios que impliquen saltos o riesgo de caídas fuertes."
    }
]

@app.post("/api/recommend-exercises")
async def recommend_exercises(request: ExerciseRequest):
    try:
        # Obtener perfil del usuario
        user_data = supabase.table("users").select("*").eq("email", request.user_email).execute()
        
        if not user_data.data:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
        user = user_data.data[0]
        
        # Filtrar ejercicios del corpus según condiciones
        recommended_exercises = []
        for condition in request.conditions:
            for exercise in EXERCISE_CORPUS:
                if exercise["condicion"].lower() == condition.lower():
                    recommended_exercises.append(exercise)
        
        # Generar recomendación con OpenAI
        prompt = f"""
        Usuario: {user['name']}, {user['age']} años, {user['gender']}
        Condiciones: {', '.join(request.conditions)}
        Nivel de actividad: {request.activity_level}
        
        Ejercicios recomendados del corpus: {json.dumps(recommended_exercises, ensure_ascii=False)}
        
        Genera un plan de ejercicios personalizado que incluya:
        1. Calentamiento (5 minutos)
        2. Ejercicios principales (20-30 minutos)
        3. Enfriamiento (5 minutos)
        
        Incluye precauciones específicas basadas en las banderas rojas.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Eres un fisioterapeuta especializado en adultos mayores."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=500,
            temperature=0.7
        )
        
        recommendation = response.choices[0].message.content
        
        # Registrar la recomendación
        supabase.table("exercise_recommendations").insert({
            "user_email": request.user_email,
            "recommendation": recommendation,
            "conditions": request.conditions
        }).execute()
        
        return {
            "recommended_exercises": recommended_exercises,
            "ai_recommendation": recommendation
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/update-streak")
async def update_streak(user_email: str):
    try:
        # Obtener racha actual
        streak_data = supabase.table("streaks").select("*").eq("user_email", user_email).execute()
        
        current_streak = 0
        if streak_data.data:
            current_streak = streak_data.data[0]["current_streak"] + 1
            supabase.table("streaks").update({
                "current_streak": current_streak,
                "last_activity": "now()"
            }).eq("user_email", user_email).execute()
        else:
            current_streak = 1
            supabase.table("streaks").insert({
                "user_email": user_email,
                "current_streak": current_streak,
                "last_activity": "now()"
            }).execute()
        
        return {"current_streak": current_streak}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)