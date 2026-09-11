import os
import sys
from pathlib import Path
from typing import Optional, List

# Ensure src directory is in sys.path and .env is loaded
SRC_DIR = Path(__file__).resolve().parent
BASE_DIR = SRC_DIR.parent
ENV_PATH = BASE_DIR / ".env"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dotenv import load_dotenv
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    load_dotenv()

from fastapi import FastAPI, HTTPException, BackgroundTasks, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from chatbot import (
    generate_answer,
    detect_language,
    update_conversation_summary
)
from database import (
    create_conversation,
    save_message,
    get_conversation
)
from vision import (
    load_vision_model,
    predict_wheat_disease,
    is_model_loaded
)
from rl_decision import (
    load_ppo_model,
    is_ppo_loaded,
    build_ppo_observation,
    predict_decision,
    ACTION_MAP
)

# ============================================================
# 1. Initialize FastAPI app
# ============================================================

app = FastAPI(
    title="NabhKrishi AI - Wheat Disease & RAG API",
    description="FastAPI interface for Swin-T Wheat Disease Detection, PPO V3 Decision Support, and RAG Chatbot",
    version="1.1.0"
)

# Pre-load Swin-T and PPO V3 models once on startup
@app.on_event("startup")
def startup_event():
    try:
        load_vision_model()
    except Exception as e:
        print(f"Warning: Failed to preload Swin-T model on startup: {e}")
    try:
        load_ppo_model()
    except Exception as e:
        print(f"Warning: Failed to preload PPO V3 model on startup: {e}")

# ============================================================
# 2. CORS Middleware
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# 3. Schemas
# ============================================================

class ChatRequest(BaseModel):
    conversation_id: Optional[str] = None
    message: str
    user_id: Optional[str] = None


class ChatResponse(BaseModel):
    conversation_id: str
    answer: str
    language: str


class PredictionItem(BaseModel):
    class_id: int
    class_name: str
    confidence: float


class DecisionItem(BaseModel):
    action_id: int
    action_name: str
    description_en: Optional[str] = None
    description_hi: Optional[str] = None


class DecisionRequest(BaseModel):
    disease_class_id: Optional[int] = None
    disease_name: Optional[str] = None
    confidence: float = 0.90
    stage: int = 2
    previous_action: int = -1
    baseline_yield: Optional[float] = None
    irrigation_number: int = 3
    field_context: Optional[dict] = None


class PredictResponse(BaseModel):
    success: bool
    prediction: PredictionItem
    top_predictions: List[PredictionItem]
    decision: Optional[DecisionItem] = None


# ============================================================
# 4. Endpoints
# ============================================================

@app.get("/")
def root():
    return {
        "service": "NabhKrishi AI API",
        "status": "running",
        "version": "1.1.0"
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "NabhKrishi AI",
        "vision_model_loaded": is_model_loaded(),
        "ppo_loaded": is_ppo_loaded(),
        "observation_size": 60,
        "action_count": 6
    }


@app.get("/rl/health")
def rl_health_check():
    return {
        "status": "ok",
        "ppo_loaded": is_ppo_loaded(),
        "observation_size": 60,
        "action_count": 6,
        "model": "PPO V3"
    }


@app.post("/decision", response_model=DecisionItem)
def decision_endpoint(request: DecisionRequest):
    disease = request.disease_class_id if request.disease_class_id is not None else (request.disease_name or "healthy")
    try:
        obs = build_ppo_observation(
            disease=disease,
            confidence=request.confidence,
            stage=request.stage,
            previous_action=request.previous_action,
            baseline_yield=request.baseline_yield,
            irrigation_number=request.irrigation_number,
            field_context=request.field_context
        )
        res = predict_decision(obs, deterministic=True)
        return DecisionItem(
            action_id=res["action_id"],
            action_name=res["action_name"],
            description_en=res.get("description_en"),
            description_hi=res.get("description_hi")
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to generate decision: {str(e)}")


@app.post("/predict", response_model=PredictResponse)
async def predict_endpoint(image: UploadFile = File(...)):
    if not image or not image.filename:
        raise HTTPException(status_code=400, detail="No image file provided.")

    try:
        contents = await image.read()
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read uploaded image.")

    if not contents or len(contents) == 0:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    # 15 MB max file limit
    if len(contents) > 15 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image size exceeds 15MB limit.")

    try:
        result = predict_wheat_disease(contents)
        
        # PPO V3 decision-support inference
        ppo_decision = None
        try:
            obs = build_ppo_observation(
                disease=result["class_id"],
                confidence=result["confidence"]
            )
            decision_res = predict_decision(obs, deterministic=True)
            ppo_decision = DecisionItem(
                action_id=decision_res["action_id"],
                action_name=decision_res["action_name"],
                description_en=decision_res.get("description_en"),
                description_hi=decision_res.get("description_hi")
            )
        except Exception as pe:
            print(f"Warning: PPO decision inference failed: {pe}")

        return PredictResponse(
            success=True,
            prediction=PredictionItem(
                class_id=result["class_id"],
                class_name=result["class_name"],
                confidence=result["confidence"]
            ),
            top_predictions=[
                PredictionItem(
                    class_id=item["class_id"],
                    class_name=item["class_name"],
                    confidence=item["confidence"]
                ) for item in result.get("top_predictions", [])
            ],
            decision=ppo_decision
        )
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"Prediction inference error: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to analyze wheat leaf image. Please try again with a clear photo."
        )


@app.post("/chat", response_model=ChatResponse)
def chat_endpoint(request: ChatRequest, background_tasks: BackgroundTasks):
    question = request.message.strip() if request.message else ""
    if not question:
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    conversation_id = request.conversation_id

    # 1. Create a new conversation if not provided
    if not conversation_id or conversation_id.strip() == "":
        try:
            conv = create_conversation(
                user_id=request.user_id or "nabhkrishi_farmer",
                title=question[:50]
            )
            conversation_id = conv.get("id") if isinstance(conv, dict) else str(conv)
        except Exception as e:
            print(f"Warning: Failed to create conversation: {e}")
            import uuid
            conversation_id = str(uuid.uuid4())

    # 2. Save farmer message to Supabase
    try:
        save_message(
            conversation_id=conversation_id,
            role="user",
            content=question
        )
    except Exception as e:
        print(f"Warning: Failed to save user message: {e}")

    # 3. Detect language
    try:
        language = detect_language(question)
    except Exception as e:
        print(f"Language detection error: {e}")
        language = "English"

    # 4. Generate RAG answer (passing pre-detected language)
    try:
        answer = generate_answer(
            question=question,
            conversation_id=conversation_id,
            language=language
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating AI answer: {str(e)}"
        )

    # 5. Save AI response to Supabase
    try:
        save_message(
            conversation_id=conversation_id,
            role="assistant",
            content=answer
        )
    except Exception as e:
        print(f"Warning: Failed to save AI message: {e}")

    # 6. Update conversation summary asynchronously via FastAPI BackgroundTasks
    try:
        background_tasks.add_task(update_conversation_summary, conversation_id)
    except Exception as e:
        print(f"Warning: Failed to schedule summary update: {e}")

    return ChatResponse(
        conversation_id=conversation_id,
        answer=answer,
        language=language
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
