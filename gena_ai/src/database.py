import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv

# Ensure .env is loaded from gena_ai parent folder if present
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        from supabase import create_client
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print(f"[Database] Warning: Failed to initialize Supabase client: {e}")

# In-memory storage fallback when Supabase is unreachable or paused
_local_conversations = {}
_local_messages = {}


# ============================================================
# 3. Create conversation
# ============================================================

def create_conversation(
    user_id=None,
    title="New Conversation"
):
    data = {
        "title": title,
        "summary": ""
    }
    if user_id:
        data["user_id"] = user_id

    if supabase is not None:
        try:
            response = (
                supabase
                .table("conversations")
                .insert(data)
                .execute()
            )
            if response.data and len(response.data) > 0:
                return response.data[0]
        except Exception as e:
            print(f"[Database] Supabase create_conversation failed ({e}), using local session")

    # Local fallback
    conv_id = str(uuid.uuid4())
    data["id"] = conv_id
    data["created_at"] = datetime.now(timezone.utc).isoformat()
    _local_conversations[conv_id] = data
    return data


# ============================================================
# 4. Save message
# ============================================================

def save_message(
    conversation_id,
    role,
    content
):
    data = {
        "conversation_id": conversation_id,
        "role": role,
        "content": content
    }

    if supabase is not None:
        try:
            response = (
                supabase
                .table("messages")
                .insert(data)
                .execute()
            )
            if response.data and len(response.data) > 0:
                return response.data[0]
        except Exception as e:
            print(f"[Database] Supabase save_message failed ({e}), using local store")

    # Local fallback
    if conversation_id not in _local_messages:
        _local_messages[conversation_id] = []
    data["created_at"] = datetime.now(timezone.utc).isoformat()
    _local_messages[conversation_id].append(data)
    return data


# ============================================================
# 5. Get recent messages
# ============================================================

def get_recent_messages(
    conversation_id,
    limit=10
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("messages")
                .select("role, content, created_at")
                .eq("conversation_id", conversation_id)
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            messages = response.data or []
            messages.reverse()
            return messages
        except Exception as e:
            print(f"[Database] Supabase get_recent_messages failed ({e}), using local store")

    # Local fallback
    msgs = _local_messages.get(conversation_id, [])
    return msgs[-limit:]


# ============================================================
# 6. Get conversation
# ============================================================

def get_conversation(
    conversation_id
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("conversations")
                .select("*")
                .eq("id", conversation_id)
                .single()
                .execute()
            )
            return response.data
        except Exception as e:
            pass

    return _local_conversations.get(conversation_id)


# ============================================================
# 7. Get conversation summary
# ============================================================

def get_summary(
    conversation_id
):
    conversation = get_conversation(conversation_id)
    if not conversation:
        return ""
    return conversation.get("summary", "")


# ============================================================
# 8. Update conversation summary
# ============================================================

def update_summary(
    conversation_id,
    summary
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("conversations")
                .update({"summary": summary})
                .eq("id", conversation_id)
                .execute()
            )
            return response.data
        except Exception as e:
            pass

    if conversation_id in _local_conversations:
        _local_conversations[conversation_id]["summary"] = summary
    return None