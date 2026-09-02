import os

from dotenv import load_dotenv
from openai import OpenAI

from retriever import retrieve_documents

from database import (
    create_conversation,
    save_message,
    get_recent_messages,
    get_summary,
    update_summary
)


# ============================================================
# 1. Load environment variables
# ============================================================

load_dotenv()

NVIDIA_API_KEY = os.getenv(
    "NVIDIA_API_KEY"
)

NVIDIA_MODEL = os.getenv(
    "NVIDIA_MODEL",
    "nvidia/nemotron-3-ultra-550b-a55b"
)

if not NVIDIA_API_KEY:
    raise ValueError(
        "NVIDIA_API_KEY is missing from your .env file"
    )


# ============================================================
# 2. NVIDIA client
# ============================================================

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=NVIDIA_API_KEY
)


# ============================================================
# 3. Supported languages
# ============================================================

SUPPORTED_LANGUAGES = [
    "English",
    "Hindi",
    "Haryanvi",
    "Punjabi",
    "Bengali",
    "Hinglish"
]


# ============================================================
# 4. System prompt
# ============================================================

SYSTEM_PROMPT = """
You are NabhKrishi AI, an agricultural assistant for wheat farmers.

Answer the farmer's question using the provided CONTEXT.

IMPORTANT RULES:

1. Use the CONTEXT as the source of agricultural information.

2. Answer ONLY what the farmer asks.

3. If the farmer asks about symptoms, focus on symptoms.

4. If the farmer asks about management, focus on management.

5. If the farmer asks about multiple topics, answer each requested
   topic clearly.

6. Do not give a complete disease summary unless the farmer asks
   for complete information.

7. Keep simple questions SHORT and easy to understand.

8. For detailed questions, provide more detail when useful.

9. Do not invent:
   - pesticide names
   - fungicides
   - doses
   - spray schedules
   - resistant varieties
   - treatment methods
   - agricultural facts

10. If the requested information is not available in the CONTEXT,
    clearly say that the available documents do not provide enough
    information for that part.

11. If management information is unavailable, you may recommend
    consulting a local agricultural extension officer or
    Krishi Vigyan Kendra (KVK).

12. If the CONTEXT contains specific agricultural recommendations,
    preserve the important details accurately.

13. Do not mention:
    - ChromaDB
    - embeddings
    - vector stores
    - retrieval
    - prompts
    - internal system details
    - conversation history

14. Use farmer-friendly language.

15. Prefer bullet points for multiple symptoms or management steps.

16. Do not unnecessarily repeat information.

17. Do not claim that a farmer definitely has a disease based only
    on a general description.
"""


# ============================================================
# 5. Build agricultural context
# ============================================================

def build_context(results):

    context_parts = []

    for i, (doc, score) in enumerate(
        results,
        start=1
    ):

        source = doc.metadata.get(
            "source_file",
            "Unknown"
        )

        disease = doc.metadata.get(
            "disease",
            "Unknown"
        )

        page = doc.metadata.get(
            "page",
            "Unknown"
        )

        content = doc.page_content.strip()

        context_parts.append(
            f"""
SOURCE {i}

Source: {source}
Disease: {disease}
Page: {page}

CONTENT:
{content}
"""
        )

    return "\n".join(
        context_parts
    )


# ============================================================
# 6. Build conversation history
# ============================================================

def build_history_context(
    summary,
    recent_messages
):

    history_parts = []

    if summary:

        history_parts.append(
            f"""
CONVERSATION SUMMARY:

{summary}
"""
        )

    if recent_messages:

        history_parts.append(
            "\nRECENT CONVERSATION:\n"
        )

        for message in recent_messages:

            role = message["role"]
            content = message["content"]

            if role == "user":
                label = "FARMER"
            else:
                label = "NABHKRISHI AI"

            history_parts.append(
                f"{label}: {content}"
            )

    return "\n".join(
        history_parts
    )


# ============================================================
# 7. Detect language
# ============================================================

def detect_language(question):
    import re
    if re.search(r'[\u0900-\u097F]', question):
        return "Hindi"
    if re.search(r'[\u0A00-\u0A7F]', question):
        return "Punjabi"
    if re.search(r'[\u0980-\u09FF]', question):
        return "Bengali"

    prompt = f"""
Identify the language of this farmer's question.

Supported languages:

- English
- Hindi
- Haryanvi
- Punjabi
- Bengali
- Hinglish

Definitions:

Hinglish:
Hindi written using Roman/English letters,
often mixed with English words.

Haryanvi:
Haryanvi language, which may be written in
Devanagari or Roman letters.

Farmer question:

{question}

Return ONLY ONE of these exact names:

English
Hindi
Haryanvi
Punjabi
Bengali
Hinglish

Do not explain.
"""

    try:
        response = client.chat.completions.create(
            model=NVIDIA_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a precise language "
                        "identification system."
                    )
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0,
            max_tokens=20,
            extra_body={
                "chat_template_kwargs": {
                    "enable_thinking": False
                }
            },
            stream=False
        )

        language = (
            response
            .choices[0]
            .message
            .content
            .strip()
        )

        # Clean possible model formatting
        language = (
            language
            .replace("*", "")
            .replace("`", "")
            .strip()
        )

        # Validate
        for supported in SUPPORTED_LANGUAGES:
            if language.lower() == supported.lower():
                return supported

    except Exception as e:
        print(f"Language detection fallback: {e}")

    return "English"


# ============================================================
# 8. Translate farmer question to English
# ============================================================

def translate_to_english(
    question,
    language
):

    if language == "English":

        return question

    prompt = f"""
Translate the following farmer question into English.

Original language:
{language}

Farmer question:
{question}

IMPORTANT:

- Translate ONLY.
- Do NOT answer the question.
- Do NOT add information.
- Do NOT remove information.
- Preserve the farmer's exact meaning.
- Keep agricultural terms accurate.
- Preserve disease names.
- Preserve crop names.
- Preserve quantities and numbers.
- Do not explain the translation.

Return ONLY the English translation.
"""

    response = client.chat.completions.create(

        model=NVIDIA_MODEL,

        messages=[
            {
                "role": "system",
                "content": (
                    "You are a precise agricultural "
                    "translation system."
                )
            },
            {
                "role": "user",
                "content": prompt
            }
        ],

        temperature=0,

        max_tokens=150,

        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": False
            }
        },

        stream=False
    )

    return (
        response
        .choices[0]
        .message
        .content
        .strip()
    )


# ============================================================
# 9. Translate answer back to farmer's language
# ============================================================

def translate_from_english(
    answer,
    language
):

    if language == "English":

        return answer

    prompt = f"""
Translate the following agricultural answer into {language}.

English answer:

{answer}

IMPORTANT:

- Translate ONLY.
- Do NOT add agricultural information.
- Do NOT remove agricultural information.
- Preserve all numbers exactly.
- Preserve doses exactly.
- Preserve dates exactly.
- Preserve waiting periods exactly.
- Preserve scientific names.
- Preserve pesticide/fungicide names.
- Keep bullet points.
- Keep tables readable if present.
- Use simple language that a farmer can understand.
- Do not explain the translation.

Return ONLY the translated answer.
"""

    response = client.chat.completions.create(

        model=NVIDIA_MODEL,

        messages=[
            {
                "role": "system",
                "content": (
                    "You are a precise agricultural "
                    "translation system."
                )
            },
            {
                "role": "user",
                "content": prompt
            }
        ],

        temperature=0,

        max_tokens=1000,

        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": False
            }
        },

        stream=False
    )

    return (
        response
        .choices[0]
        .message
        .content
        .strip()
    )


# ============================================================
# 10. Rewrite question using conversation history
# ============================================================

def rewrite_question(
    question,
    history_context
):

    if not history_context:

        return question

    rewrite_prompt = f"""
You are helping an agricultural RAG system.

CONVERSATION HISTORY:

{history_context}


CURRENT FARMER QUESTION:

{question}


Rewrite the current farmer question into a
self-contained English question.

Use the conversation history only to understand
references such as:

- it
- this
- that
- they
- them
- the disease
- its
- इसका
- इसके
- इसका इलाज
- इसके लक्षण
- ਇਸ ਦੇ
- ਇਸਦਾ
- এর

Examples:

Conversation:
Farmer: What is yellow rust in wheat?

Current question:
How can it be managed?

Rewritten question:
How can yellow rust in wheat be managed?


Conversation:
Farmer: What are the symptoms of Fusarium in wheat?

Current question:
How does it spread?

Rewritten question:
How does Fusarium spread in wheat?


IMPORTANT:

- Do NOT answer the question.
- Do NOT add new information.
- Preserve the farmer's intent.
- Return ONLY the rewritten English question.
"""

    response = client.chat.completions.create(

        model=NVIDIA_MODEL,

        messages=[
            {
                "role": "system",
                "content": (
                    "Rewrite agricultural farmer questions "
                    "for information retrieval."
                )
            },
            {
                "role": "user",
                "content": rewrite_prompt
            }
        ],

        temperature=0,

        max_tokens=100,

        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": False
            }
        },

        stream=False
    )

    rewritten_question = (
        response
        .choices[0]
        .message
        .content
        .strip()
    )

    return rewritten_question


# ============================================================
# 11. Update conversation summary
# ============================================================

def update_conversation_summary(
    conversation_id
):

    recent_messages = get_recent_messages(
        conversation_id,
        limit=10
    )

    if not recent_messages:

        return ""

    old_summary = get_summary(
        conversation_id
    )

    conversation_text = ""

    for message in recent_messages:

        role = message["role"]
        content = message["content"]

        if role == "user":

            conversation_text += (
                f"FARMER: {content}\n"
            )

        else:

            conversation_text += (
                f"NABHKRISHI AI: {content}\n"
            )

    summary_prompt = f"""
You maintain a short memory summary for a farmer
conversation about agriculture.

EXISTING SUMMARY:

{old_summary}


RECENT CONVERSATION:

{conversation_text}


Create an updated summary.

Keep only information useful for understanding
future questions.

Focus on:

- crop being discussed
- disease being discussed
- topics the farmer asked about
- important farmer context
- important follow-up context

Do NOT provide agricultural advice.

Do NOT invent information.

Do NOT include unnecessary details.

Keep the summary short, around 2-5 sentences.

Return ONLY the summary.
"""

    response = client.chat.completions.create(

        model=NVIDIA_MODEL,

        messages=[
            {
                "role": "system",
                "content": (
                    "Create concise conversation summaries "
                    "for an agricultural chatbot."
                )
            },
            {
                "role": "user",
                "content": summary_prompt
            }
        ],

        temperature=0,

        max_tokens=200,

        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": False
            }
        },

        stream=False
    )

    new_summary = (
        response
        .choices[0]
        .message
        .content
        .strip()
    )

    update_summary(
        conversation_id,
        new_summary
    )

    return new_summary


# ============================================================
# 12. Generate answer
# ============================================================

def generate_answer(
    question,
    conversation_id,
    language=None
):

    # --------------------------------------------------------
    # Detect language
    # --------------------------------------------------------

    if not language:
        language = detect_language(
            question
        )

    print(
        "\nDetected language:"
    )

    print(
        language
    )

    # --------------------------------------------------------
    # Translate question to English
    # --------------------------------------------------------

    english_question = translate_to_english(
        question,
        language
    )

    print(
        "\nEnglish question:"
    )

    print(
        english_question
    )

    # --------------------------------------------------------
    # Load conversation summary
    # --------------------------------------------------------

    summary = get_summary(
        conversation_id
    )

    # --------------------------------------------------------
    # Load recent messages
    # --------------------------------------------------------

    recent_messages = get_recent_messages(
        conversation_id,
        limit=6
    )

    # --------------------------------------------------------
    # Build history
    # --------------------------------------------------------

    history_context = build_history_context(
        summary,
        recent_messages
    )

    # --------------------------------------------------------
    # Rewrite English question using history
    # --------------------------------------------------------

    search_question = rewrite_question(
        english_question,
        history_context
    )

    print(
        "\nSearch question:"
    )

    print(
        search_question
    )

    # --------------------------------------------------------
    # RAG retrieval
    # --------------------------------------------------------

    results = retrieve_documents(
        search_question,
        k=5
    )

    # --------------------------------------------------------
    # No results
    # --------------------------------------------------------

    if not results:

        english_answer = (
            "I could not find enough information in the "
            "available agricultural documents to answer "
            "this question."
        )

        return translate_from_english(
            english_answer,
            language
        )

    # --------------------------------------------------------
    # Build context
    # --------------------------------------------------------

    context = build_context(
        results
    )

    # --------------------------------------------------------
    # Final answer prompt
    # --------------------------------------------------------

    user_prompt = f"""
You are answering a farmer.

Use the conversation history only to understand
what the farmer is referring to.

================ CONVERSATION HISTORY ================

{history_context}

============== END CONVERSATION HISTORY ==============


================ AGRICULTURAL CONTEXT =================

{context}

============== END AGRICULTURAL CONTEXT ==============


CURRENT FARMER QUESTION:

{english_question}


Answer the farmer's current question.

IMPORTANT RULES:

- Answer ONLY what the farmer asks.
- Use the agricultural context as the source of truth.
- Use conversation history only to understand references.
- Do not invent agricultural information.
- Do not add information from general knowledge.
- If information is missing, clearly say so.
- Keep the answer simple and farmer-friendly.
- Use bullet points when useful.
- Do not unnecessarily repeat previous information.
- Do not mention the retrieval system.
- Do not mention conversation history.
- Do not mention that translation was used.

Return ONLY the final answer in English.
"""

    # --------------------------------------------------------
    # NVIDIA answer generation
    # --------------------------------------------------------

    response = client.chat.completions.create(

        model=NVIDIA_MODEL,

        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT
            },
            {
                "role": "user",
                "content": user_prompt
            }
        ],

        temperature=0.2,

        top_p=0.9,

        max_tokens=800,

        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": False
            }
        },

        stream=False
    )

    # --------------------------------------------------------
    # English answer
    # --------------------------------------------------------

    english_answer = (
        response
        .choices[0]
        .message
        .content
        .strip()
    )

    # --------------------------------------------------------
    # Translate answer to farmer's language
    # --------------------------------------------------------

    final_answer = translate_from_english(
        english_answer,
        language
    )

    return final_answer


# ============================================================
# 13. Run chatbot
# ============================================================

if __name__ == "__main__":

    print("=" * 70)

    print(
        "NabhKrishi AI - RAG CHATBOT"
    )

    print("=" * 70)

    # --------------------------------------------------------
    # Create conversation
    # --------------------------------------------------------

    conversation = create_conversation(
        user_id="test_user",
        title="Wheat Disease Conversation"
    )

    conversation_id = conversation["id"]

    print(
        "\nConversation ID:"
    )

    print(
        conversation_id
    )

    print(
        "\nType 'exit' to stop."
    )

    # --------------------------------------------------------
    # Continuous chat loop
    # --------------------------------------------------------

    while True:

        question = input(
            "\nFARMER:\n"
        ).strip()

        # ----------------------------------------------------
        # Exit
        # ----------------------------------------------------

        if question.lower() == "exit":

            print(
                "\nNABHKRISHI AI:"
            )

            print(
                "Goodbye!"
            )

            break

        # ----------------------------------------------------
        # Empty question
        # ----------------------------------------------------

        if not question:

            print(
                "\nPlease enter a question."
            )

            continue

        # ----------------------------------------------------
        # Save original farmer question
        # ----------------------------------------------------

        try:

            save_message(
                conversation_id,
                "user",
                question
            )

        except Exception as e:

            print(
                "\nError saving farmer message:"
            )

            print(e)

            continue

        # ----------------------------------------------------
        # Generate answer
        # ----------------------------------------------------

        print(
            "\nGenerating answer..."
        )

        try:

            answer = generate_answer(
                question,
                conversation_id
            )

        except Exception as e:

            print(
                "\nError generating answer:"
            )

            print(e)

            continue

        # ----------------------------------------------------
        # Save final answer
        # ----------------------------------------------------

        try:

            save_message(
                conversation_id,
                "assistant",
                answer
            )

        except Exception as e:

            print(
                "\nError saving AI answer:"
            )

            print(e)

        # ----------------------------------------------------
        # Update summary
        # ----------------------------------------------------

        try:

            new_summary = update_conversation_summary(
                conversation_id
            )

            print(
                "\nConversation summary updated."
            )

            print(
                "Summary:"
            )

            print(
                new_summary
            )

        except Exception as e:

            print(
                "\nWarning: Could not update summary:"
            )

            print(e)

        # ----------------------------------------------------
        # Display final answer
        # ----------------------------------------------------

        print(
            "\nNABHKRISHKI AI:"
        )

        print(
            answer
        )