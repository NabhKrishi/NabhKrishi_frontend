# 🌱 NabhKrishi

### AI-Powered Smart Farming & Agricultural Decision Support Platform

> **Smarter Farming • Better Decisions • Sustainable Future**

NabhKrishi is an AI-powered agricultural decision-support platform that brings together **Computer Vision, Reinforcement Learning, RAG, LLMs, satellite data, weather information, and farm-level data** to help farmers make more informed decisions.

The platform is designed to be **multi-crop, multilingual, scalable, and farmer-centric**, with the ability to expand across different crops, regions, and agricultural use cases.

---

## 📸 About NabhKrishi

NabhKrishi follows a simple workflow:

**Farmer → Crop & Farm Data → AI Analysis → Decision Support → Agricultural Knowledge → Personalized Guidance**

The goal is to make advanced agricultural technology accessible through a simple mobile application while keeping the farmer at the center of the decision-making process.

---

## 🚜 Key Features

### 🔬 AI Crop Disease Detection

NabhKrishi uses a **Swin Transformer (Swin-T)** based computer vision model for image-based crop health and disease analysis.

**Capabilities:**

- 📷 Crop image analysis
- 🦠 Disease classification
- 📊 Prediction confidence
- 🌱 Crop-health insights
- 🔄 Extensible architecture for additional crops and disease classes

> The current vision model provides a foundation that can be expanded with additional validated agricultural datasets.

---

### 🤖 AI Decision Support

NabhKrishi integrates a **PPO (Proximal Policy Optimization)** based decision-support system.

The system can consider contextual information such as:

- 🌱 Crop growth stage
- 🦠 Disease information
- 📊 Prediction confidence
- 🌦️ Environmental conditions
- 💧 Irrigation requirements
- 📈 Agricultural and historical information

The system provides **decision support** rather than replacing agricultural experts.

---

### 🧠 AI Agricultural Assistant

NabhKrishi includes a knowledge-grounded agricultural chatbot powered by:

- **NVIDIA Nemotron**
- **Retrieval-Augmented Generation (RAG)**
- **ChromaDB**
- **BGE Embeddings**

Instead of relying only on the LLM's internal knowledge, the system retrieves relevant agricultural information before generating a response.

#### RAG Pipeline

```text
User Question
      ↓
Language Detection
      ↓
Translation / Normalization
      ↓
Vector Retrieval
      ↓
ChromaDB
      ↓
Relevant Agricultural Knowledge
      ↓
NVIDIA Nemotron
      ↓
Grounded Response
      ↓
User's Preferred Language

This approach helps reduce unsupported or hallucinated agricultural recommendations.

🌐 Multilingual Support
NabhKrishi is designed to make agricultural information accessible in the farmer's preferred language.
Supported Languages
- 🇬🇧 English
- 🇮🇳 Hindi
- 🗣️ Hinglish
- Punjabi
- Haryanvi
- Bengali
The architecture is designed to support additional regional languages in the future.
🗺️ Smart Farm Mapping
Farmers can digitally define and manage their farm boundaries using GPS and interactive maps.
Features
- 📍 GPS-based location
- 🗺️ Interactive 2D map
- ✏️ Farm boundary drawing
- 📐 Farm area calculation
- 🌍 GeoJSON representation
- 💾 Local farm-boundary persistence
This creates a digital representation of the farm that can support future satellite, weather, and farm-level analytics.
🛰️ Satellite & Environmental Intelligence
NabhKrishi is designed to combine multiple agricultural data sources.
Data Source	Possible Use
🛰️ Satellite Data	Crop and land monitoring
🌦️ Weather Data	Weather-aware decisions
🌧️ Rainfall	Water and crop analysis
🌡️ Temperature	Environmental context
🌱 Soil Data	Soil and nutrient insights
🚜 Farm Data	Personalized farm decisions
📊 Crop Data	Crop-specific analysis


Combining these sources allows NabhKrishi to move from generic agricultural information toward context-aware decision support.
🌱 Sustainable Agriculture
NabhKrishi focuses not only on productivity but also on sustainable resource management.
The platform supports concepts related to:
- 💧 Water management
- 🌱 Soil management
- 🧪 Input management
- 🌾 Crop management
- ♻️ Sustainable farming practices
The long-term objective is to help farmers improve resource efficiency, resilience, and sustainable agricultural outcomes.
🌍 Carbon Credits & MRV
NabhKrishi also explores the potential of using digital agricultural data for Measurement, Reporting and Verification (MRV) of sustainable farming outcomes.
Satellite Data
      +
Soil Data
      +
Weather Data
      +
Farm Data
      ↓
NabhKrishi MRV
      ↓
Measure → Report → Verify
      ↓
Verified Agricultural Outcomes
      ↓
Potential Carbon Credit Eligibility
      ↓
Potential Additional Farmer Revenue
MRV Framework
Measure
Collect information from:
- Satellite
- Soil
- Weather
- Farm data
Report
Maintain digital evidence of:
- Farm practices
- Inputs
- Management activities
- Agricultural outcomes
Verify
Enable verification of reported outcomes under an applicable methodology.
Carbon-credit generation depends on applicable standards, methodologies, verification requirements, and market conditions. NabhKrishi provides a potential digital foundation for such workflows.

🏗️ System Architecture
                    ┌─────────────────────┐
                    │       FARMER        │
                    │   Flutter Mobile    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │       FastAPI       │
                    │       Backend       │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
             ▼                 ▼                 ▼
       ┌───────────┐     ┌───────────┐     ┌───────────┐
       │  Swin-T   │     │    PPO    │     │    RAG    │
       │ Vision AI │     │ Decision  │     │ Knowledge │
       └───────────┘     └───────────┘     └─────┬─────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │  Nemotron    │
                                          │     LLM      │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                      Multilingual Guidance
🛠️ Technology Stack
Category	Technology
📱 Mobile	Flutter + Dart
⚙️ Backend	Python + FastAPI
👁️ Computer Vision	Swin Transformer + PyTorch
🤖 Decision AI	PPO + Stable-Baselines3
🧠 LLM	NVIDIA Nemotron
🔎 RAG	ChromaDB
🔢 Embeddings	BGE Embeddings
🔐 Authentication	Firebase
🗄️ Database	Supabase + Firestore
🗺️ Maps	OpenStreetMap
📍 Location	GPS + Geolocator
🌍 Farm Boundaries	GeoJSON
🐍 Data Processing	Python


📊 AI Model Performance
The current validated crop-disease vision model achieved:
Metric	Result
Test Accuracy	91.60%
Macro F1	89.87%
Macro Precision	94.47%
Macro Recall	91.60%
Test Images	750


These metrics represent evaluation of the current vision model on its test dataset.
Prediction confidence should not be interpreted as disease severity.

🔄 End-to-End Workflow
1. Farmer opens NabhKrishi
             ↓
2. Farm / crop information
             ↓
3. Crop image captured
             ↓
4. Swin-T analyzes the image
             ↓
5. Crop-health / disease prediction
             ↓
6. PPO provides contextual decision support
             ↓
7. RAG retrieves relevant knowledge
             ↓
8. Nemotron generates a grounded response
             ↓
9. Response delivered in preferred language
👨‍🌾 Farmer-Centric Development
NabhKrishi was developed with direct interaction with farmers and agricultural experts.
Our team interacted with farmers to understand practical challenges related to:
- Crop diseases
- Irrigation
- Soil and fertilizer management
- Access to agricultural information
- Language barriers
- Farm-level decision making
These interactions helped us focus on building a solution that is practical, accessible, and farmer-centric.
We also discussed the concept with agricultural experts to understand real-world farming requirements and the importance of field validation.
🔬 Data & Validation
NabhKrishi combines multiple categories of agricultural information:
- 🌾 Crop information
- 🚜 Farm data
- 🌦️ Weather information
- 🛰️ Satellite observations
- 🌱 Soil information
- 📷 Crop images
- 📊 Agricultural datasets
The platform uses standard machine-learning evaluation metrics where applicable.
Real-world agricultural deployment requires continued:
- Field validation
- Agricultural expert review
- Region-specific testing
- Dataset expansion
- Model validation
🚀 Future Scope
NabhKrishi is designed as a scalable agricultural intelligence platform.
Planned Expansion
- 🌾 Support for additional crops
- 🦠 Expanded disease and pest detection
- 🛰️ Advanced satellite analytics
- 🌦️ Weather forecasting integration
- 💧 Improved irrigation decision support
- 🌱 Soil-health intelligence
- 🗣️ Additional regional languages
- 📱 Offline / low-connectivity support
- 📊 Farmer analytics dashboard
- 🤝 Agricultural expert integration
- 🌍 Sustainable farming and MRV workflows
- 💰 Carbon-market integration where applicable
- 🔄 Continuous learning from validated field data
🔐 Responsible AI
NabhKrishi is designed as a decision-support platform, not as a replacement for agricultural professionals.
The platform aims to:
- Ground chatbot responses in retrieved knowledge
- Reduce unsupported agricultural recommendations
- Provide prediction confidence where applicable
- Encourage expert consultation when information is insufficient
- Support continued field validation
- Avoid presenting experimental outputs as guaranteed agricultural outcomes
📁 Project Structure
NabhKrishi/
│
├── frontend/
│   └── Flutter Application
│
├── backend/
│   ├── FastAPI APIs
│   ├── AI Models
│   ├── RAG Pipeline
│   └── Decision Support
│
├── models/
│   ├── Swin-T
│   ├── PPO
│   └── Supporting Models
│
├── rag/
│   ├── ChromaDB
│   └── Embeddings
│
├── data/
│   └── Agricultural Data
│
└── README.md
🎯 Vision
To build an intelligent, accessible, and sustainable digital farming ecosystem where farmers can use AI and data to make better agricultural decisions.

NabhKrishi connects:
AI + Agriculture + Data + Sustainability
to create a scalable platform for the future of farming.
🌱 NabhKrishi
Smarter Farming. Better Decisions. Sustainable Future.
