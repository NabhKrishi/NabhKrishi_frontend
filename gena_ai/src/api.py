import os
import sys
from pathlib import Path
from typing import Optional

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

from fastapi import FastAPI, HTTPException, BackgroundTasks
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

# ============================================================
# 1. Initialize FastAPI app
# ============================================================

app = FastAPI(
    title="NabhKrishi AI - Wheat RAG Chatbot API",
    description="FastAPI interface for Wheat Agriculture RAG Chatbot with NVIDIA Nemotron & Supabase",
    version="1.0.0"
)

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


# ============================================================
# 4. Endpoints
# ============================================================

@app.get("/")
def root():
    return {
        "service": "NabhKrishi AI Chatbot API",
        "status": "running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "NabhKrishi AI"
    }


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
            conversation_id = conv["id"]
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create conversation: {str(e)}"
            )

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
