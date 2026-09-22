# 🌱 NabhKrishi

### AI-Powered Smart Farming & Agricultural Decision Support Platform

NabhKrishi is an AI-powered agricultural decision-support platform designed to help farmers make smarter, faster, and more informed decisions about their crops.

The platform combines **Artificial Intelligence, Computer Vision, Weather Data, Satellite Data, Farm Information, Reinforcement Learning, and Retrieval-Augmented Generation (RAG)** to provide personalized agricultural insights through a simple and multilingual mobile application.

---

## 🚜 Problem

Farmers often face challenges such as:

- 🌾 Early identification of crop diseases and pests
- 💧 Efficient water and irrigation management
- 🌱 Soil and nutrient management
- 🌦️ Changing weather conditions
- 📊 Lack of personalized farm-level information
- 🗣️ Limited access to agricultural information in regional languages
- 💰 Improving productivity while maintaining sustainable farming practices

Existing agricultural information is often fragmented across different sources.

**NabhKrishi brings these capabilities together into one integrated platform.**

---

## 💡 Our Solution

NabhKrishi provides an intelligent workflow:

```text
Farmer
   ↓
Farm & Crop Information
   ↓
AI-Based Crop Analysis
   ↓
Decision Support
   ↓
Verified Agricultural Knowledge
   ↓
Personalized Guidance
   ↓
Better & Sustainable Farming
The platform is designed to be extensible across multiple crops, regions, and agricultural use cases.
✨ Key Features
🔬 AI-Based Crop Disease Detection
NabhKrishi uses a Swin Transformer (Swin-T) based computer vision model to analyze crop images and identify potential diseases or crop-health conditions.
The system provides:
- Disease classification
- Prediction confidence
- Crop-health insights
- Image-based analysis
The vision pipeline is designed to be extended with additional crops and disease classes as more validated datasets become available.
🤖 AI Decision Support
NabhKrishi integrates a PPO-based Reinforcement Learning decision-support model.
The decision-support system considers contextual information such as:
- Crop growth stage
- Disease information
- Prediction confidence
- Environmental conditions
- Irrigation requirements
- Historical agricultural information
The system produces a decision-support action rather than directly replacing agricultural experts.
🧠 Agricultural AI Chatbot
NabhKrishi includes an AI-powered agricultural assistant using:
- NVIDIA Nemotron
- Retrieval-Augmented Generation (RAG)
- ChromaDB
- BGE Embeddings
The chatbot retrieves relevant agricultural knowledge before generating a response.
RAG Pipeline
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
Nemotron
      ↓
Grounded Response
      ↓
User's Preferred Language
The RAG layer is used to reduce unsupported or hallucinated agricultural recommendations.
🌐 Multilingual Support
NabhKrishi is designed to make agricultural information accessible in multiple languages.
Current supported interaction includes:
- 🇬🇧 English
- 🇮🇳 Hindi
- 🗣️ Hinglish
- Punjabi
- Haryanvi
- Bengali
The architecture is extensible so that additional regional languages can be added in the future.
🗺️ Smart Farm Mapping
NabhKrishi allows farmers to digitally define their farm boundaries using GPS and interactive maps.
Features
- 📍 GPS-based location
- 🗺️ Interactive 2D map
- ✏️ Farm boundary drawing
- 📐 Farm area calculation
- 🌍 GeoJSON representation
- 💾 Local farm-boundary persistence
This creates a digital representation of the farmer's field that can support future satellite and farm-level analytics.
🛰️ Satellite & Environmental Data
NabhKrishi is designed to integrate environmental information such as:
- Satellite observations
- Weather data
- Rainfall
- Temperature
- Soil information
- Farm-level data
These data sources can be combined to provide more contextual agricultural decision support.
🌱 Sustainable Agriculture
NabhKrishi is not only focused on productivity.
The platform also promotes better:
- 💧 Water management
- 🌱 Soil management
- 🧪 Input management
- 🌾 Crop management
- ♻️ Sustainable agricultural practices
The long-term objective is to help farmers improve resource efficiency while maintaining productive and resilient farming systems.
🌍 Carbon Credits & MRV
NabhKrishi also explores how digital agricultural data can support Measurement, Reporting and Verification (MRV) for sustainable farming outcomes.
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
Carbon-credit generation depends on applicable methodologies, measurement requirements, verification, and market conditions.
NabhKrishi provides the digital data and decision-support foundation that can potentially contribute to such workflows.
🏗️ System Architecture
                    ┌─────────────────────┐
                    │      FARMER         │
                    │   Flutter Mobile    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     FastAPI         │
                    │      Backend        │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┼─────────────────┐
             ▼                 ▼                 ▼
      ┌────────────┐    ┌────────────┐    ┌────────────┐
      │  Swin-T    │    │    PPO     │    │    RAG     │
      │ Vision AI  │    │ Decision AI│    │ Knowledge  │
      └────────────┘    └────────────┘    └─────┬──────┘
                                                │
                                                ▼
                                         ┌─────────────┐
                                         │  Nemotron   │
                                         │     LLM     │
                                         └──────┬──────┘
                                                │
                                                ▼
                                     Multilingual Guidance
🛠️ Technology Stack
Layer	Technology
Mobile App	Flutter + Dart
Backend	Python + FastAPI
Computer Vision	Swin Transformer + PyTorch
Decision Support	PPO + Stable-Baselines3
LLM	NVIDIA Nemotron
RAG	ChromaDB
Embeddings	BGE Embeddings
Authentication	Firebase
Database	Supabase / Firestore
Maps	OpenStreetMap
Location	GPS + Geolocator
Farm Boundaries	GeoJSON
ML/Data Processing	Python
Deployment	API-based architecture


📊 Model Performance
The current crop-disease vision model achieved:
Metric	Result
Test Accuracy	91.60%
Macro F1	89.87%
Macro Precision	94.47%
Macro Recall	91.60%
Test Images	750


The model currently contains multiple crop-disease classes and is designed as a foundation for expanding the vision system to additional crops and agricultural conditions.
🔄 End-to-End Workflow
1. Farmer opens NabhKrishi
              ↓
2. Selects / records farm information
              ↓
3. Captures crop image
              ↓
4. Swin-T analyzes the image
              ↓
5. Disease / crop-health prediction
              ↓
6. PPO provides contextual decision support
              ↓
7. RAG retrieves relevant agricultural knowledge
              ↓
8. Nemotron generates a grounded response
              ↓
9. Response is provided in the farmer's preferred language
👨‍🌾 Farmer-Centric Development
NabhKrishi has been designed with direct farmer interaction in mind.
Our team interacted with farmers to understand real-world challenges related to:
- Crop diseases
- Irrigation
- Soil and fertilizer management
- Access to agricultural information
- Language barriers
- Farm-level decision making
These interactions helped us focus on building a solution that is practical, accessible, and farmer-centric.
We also discussed the concept with agricultural experts to understand practical farming requirements and the importance of field validation.
🔬 Data & Validation
NabhKrishi combines multiple types of agricultural information, including:
- Agricultural field data
- Crop information
- Weather information
- Farm management information
- Satellite observations
- Crop images
Model performance is evaluated using standard machine-learning metrics where applicable.
Real-world agricultural deployment requires continued field validation, expert review, and region-specific testing.
🚀 Future Scope
NabhKrishi is designed as a scalable agricultural intelligence platform.
Future development areas include:
- 🌾 Expansion to more crops
- 🛰️ More advanced satellite analytics
- 🌦️ Weather forecasting integration
- 💧 Improved irrigation decision support
- 🌱 Soil-health intelligence
- 🐛 Pest and disease monitoring
- 🗣️ Additional regional languages
- 📱 Offline / low-connectivity support
- 📊 Farmer analytics dashboard
- 🤝 Agricultural expert integration
- 🌍 Sustainable farming and MRV workflows
- 💰 Carbon-market integration where applicable
- 🔄 Continuous learning from validated field data
🔐 Responsible AI
NabhKrishi is designed as a decision-support system, not a replacement for agricultural experts.
The platform aims to:
- Ground chatbot responses in retrieved knowledge
- Avoid unsupported treatment recommendations
- Provide confidence information where applicable
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

NabhKrishi brings together AI + Agriculture + Data + Sustainability to create a scalable platform for the future of farming.
