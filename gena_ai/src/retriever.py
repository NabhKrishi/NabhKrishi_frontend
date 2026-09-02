from pathlib import Path

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma


# ============================================================
# Paths
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

CHROMA_DIR = BASE_DIR / "chroma_db"

COLLECTION_NAME = "nabhkrishi_wheat_ipm"


# ============================================================
# 1. Load embedding model
# ============================================================

embeddings = HuggingFaceEmbeddings(
    model_name="BAAI/bge-small-en-v1.5",
    model_kwargs={
        "device": "cpu"
    },
    encode_kwargs={
        "normalize_embeddings": True
    }
)


# ============================================================
# 2. Load ChromaDB
# ============================================================

vectorstore = Chroma(
    persist_directory=str(CHROMA_DIR),
    collection_name=COLLECTION_NAME,
    embedding_function=embeddings
)


# ============================================================
# 3. Disease aliases
# ============================================================

DISEASE_ALIASES = {

    "yellow_rust": [
        "yellow rust",
        "stripe rust",
        "yellow stripe rust"
    ],

    "black_rust": [
        "black rust",
        "stem rust"
    ],

    "brown_rust": [
        "brown rust",
        "leaf rust"
    ],

    "powdery_mildew": [
        "powdery mildew"
    ],

    "fusarium": [
        "fusarium",
        "fusarium head blight",
        "head scab",
        "fusarium head scab"
    ]
}


# ============================================================
# 4. Topic keywords
# ============================================================

TOPIC_KEYWORDS = {

    "symptoms": [
        "symptom",
        "symptoms",
        "sign",
        "signs",
        "look like",
        "identify",
        "identification",
        "appearance"
    ],

    "management": [
        "manage",
        "management",
        "control",
        "treatment",
        "treat",
        "what should i do",
        "what can i do"
    ],

    "spread": [
        "spread",
        "spreads",
        "transmit",
        "transmission",
        "dissemination",
        "how does it spread"
    ],

    "favourable_conditions": [
        "favourable conditions",
        "favorable conditions",
        "weather",
        "temperature",
        "humidity",
        "conditions",
        "climate"
    ],

    "survival": [
        "survive",
        "survival",
        "survives",
        "source of infection",
        "where does it survive"
    ],

    "prevention": [
        "prevent",
        "prevention",
        "avoid",
        "protect",
        "protection"
    ]
}


# ============================================================
# 5. Detect disease
# ============================================================

def detect_disease(question):

    question_lower = question.lower()

    for disease, aliases in DISEASE_ALIASES.items():

        for alias in aliases:

            if alias in question_lower:
                return disease

    return None


# ============================================================
# 6. Detect topics
# ============================================================

def detect_topics(question):

    question_lower = question.lower()

    detected_topics = []

    for topic, keywords in TOPIC_KEYWORDS.items():

        for keyword in keywords:

            if keyword in question_lower:

                detected_topics.append(topic)

                break

    # If no specific topic was detected
    if not detected_topics:
        detected_topics.append("general")

    return detected_topics


# ============================================================
# 7. Topic search terms
# ============================================================

TOPIC_SEARCH_TERMS = {

    "symptoms":
        "symptoms signs disease appearance lesions pustules",

    "management":
        "management control treatment prevention IPM practices",

    "spread":
        "spread transmission spores infection",

    "favourable_conditions":
        "favourable conditions temperature humidity weather infection",

    "survival":
        "survival source inoculum crop debris seed soil",

    "prevention":
        "prevention management IPM resistant varieties sanitation",

    "general":
        ""
}


# ============================================================
# 8. Check useful chunk
# ============================================================

def is_useful_chunk(doc):

    text = doc.page_content.lower().strip()

    if len(text) < 150:
        return False

    if "table of contents" in text:
        return False

    if text.startswith("http://"):
        return False

    if text.startswith("https://"):
        return False

    if "google.co.in/search?q=" in text:
        return False

    return True


# ============================================================
# 9. Build focused query
# ============================================================

def build_topic_query(question, disease, topic):

    topic_terms = TOPIC_SEARCH_TERMS.get(
        topic,
        ""
    )

    if disease:

        disease_name = disease.replace(
            "_",
            " "
        )

        return (
            f"{question} "
            f"{disease_name} "
            f"wheat "
            f"{topic_terms}"
        )

    return (
        f"{question} "
        f"wheat "
        f"{topic_terms}"
    )


# ============================================================
# 10. Retrieve documents
# ============================================================

def retrieve_documents(question, k=5):

    disease = detect_disease(question)

    topics = detect_topics(question)

    all_results = {}

    # --------------------------------------------------------
    # Search separately for every requested topic
    # --------------------------------------------------------

    for topic in topics:

        search_query = build_topic_query(
            question,
            disease,
            topic
        )

        # Disease-aware search
        if disease:

            results = vectorstore.similarity_search_with_score(
                search_query,
                k=k * 2,
                filter={
                    "disease": disease
                }
            )

        # General search
        else:

            results = vectorstore.similarity_search_with_score(
                search_query,
                k=k * 2
            )

        # ----------------------------------------------------
        # Store useful results
        # ----------------------------------------------------

        for doc, score in results:

            if not is_useful_chunk(doc):
                continue

            key = (
                doc.metadata.get(
                    "source_file",
                    ""
                ),
                doc.metadata.get(
                    "page",
                    ""
                ),
                doc.page_content[:100]
            )

            # Keep the best score for duplicate chunks
            if key not in all_results:

                all_results[key] = (
                    doc,
                    score
                )

            else:

                old_doc, old_score = all_results[key]

                if score < old_score:

                    all_results[key] = (
                        doc,
                        score
                    )

    # --------------------------------------------------------
    # Sort by similarity
    # Lower distance = better
    # --------------------------------------------------------

    final_results = sorted(
        all_results.values(),
        key=lambda x: x[1]
    )

    # --------------------------------------------------------
    # Return top K
    # --------------------------------------------------------

    return final_results[:k]