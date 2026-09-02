import os

from dotenv import load_dotenv
from supabase import create_client


# ============================================================
# 1. Load environment variables
# ============================================================

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")


if not SUPABASE_URL:
    raise ValueError("SUPABASE_URL is missing from .env")

if not SUPABASE_KEY:
    raise ValueError("SUPABASE_KEY is missing from .env")


# ============================================================
# 2. Supabase client
# ============================================================

supabase = create_client(
    SUPABASE_URL,
    SUPABASE_KEY
)


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

    response = (
        supabase
        .table("conversations")
        .insert(data)
        .execute()
    )

    return response.data[0]


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

    response = (
        supabase
        .table("messages")
        .insert(data)
        .execute()
    )

    return response.data[0]


# ============================================================
# 5. Get recent messages
# ============================================================

def get_recent_messages(
    conversation_id,
    limit=10
):

    response = (
        supabase
        .table("messages")
        .select(
            "role, content, created_at"
        )
        .eq(
            "conversation_id",
            conversation_id
        )
        .order(
            "created_at",
            desc=True
        )
        .limit(limit)
        .execute()
    )

    messages = response.data

    # Newest → oldest from Supabase.
    # We want oldest → newest.

    messages.reverse()

    return messages


# ============================================================
# 6. Get conversation
# ============================================================

def get_conversation(
    conversation_id
):

    response = (
        supabase
        .table("conversations")
        .select("*")
        .eq(
            "id",
            conversation_id
        )
        .single()
        .execute()
    )

    return response.data


# ============================================================
# 7. Get conversation summary
# ============================================================

def get_summary(
    conversation_id
):

    conversation = get_conversation(
        conversation_id
    )

    if not conversation:
        return ""

    return conversation.get(
        "summary",
        ""
    )


# ============================================================
# 8. Update conversation summary
# ============================================================

def update_summary(
    conversation_id,
    summary
):

    response = (
        supabase
        .table("conversations")
        .update({
            "summary": summary
        })
        .eq(
            "id",
            conversation_id
        )
        .execute()
    )

    return response.data