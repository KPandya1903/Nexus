import { Project } from "@/types";

export const projects: Project[] = [
  {
    id: "dummy-trading",
    title: "Dummy Trading — Paper Trading Platform",
    category: "Full-Stack & Machine Learning",
    description: "Comprehensive paper trading platform with $100K virtual funds, real-time Alpaca pricing, ML-powered predictions, and competitive group trading.",
    problem: "Provide a risk-free environment for learning stock trading with real market data, technical analysis, and AI-driven research capabilities.",
    solution: "Built a full-stack trading platform using React 18, TypeScript, and Node.js with PostgreSQL via Prisma ORM. Integrated TensorFlow.js for ML predictions using a stacked ensemble of Holt-Winters, LSTM, and GRU models. Added deep research pipeline with Gemini and DeepSeek-R1 for multi-dimensional stock analysis.",
    impact: "Full S&P 500 market browsing with real-time pricing. ML prediction system with 23-feature engineering pipeline from OHLCV data. Supports limit/stop orders with automated 60-second validation cycles.",
    tech: ["React", "TypeScript", "Node.js", "PostgreSQL", "Prisma", "TensorFlow.js", "Gemini", "Ollama"],
    githubRepo: "KPandya1903/Dummy-Trading",
    highlights: [
      "$100K virtual portfolio with real-time Alpaca pricing",
      "ML ensemble: Holt-Winters + LSTM + GRU predictions",
      "RSI, MACD, Bollinger Bands technical analysis",
      "Group trading with invite codes and leaderboards",
      "Deep research pipeline with LLM analysis"
    ],
    date: "Feb 2026"
  },
  {
    id: "wizard-duel",
    title: "Wizard Duel — 3D Battle Game",
    category: "Game Development & AI",
    description: "First-person 3D wizard battle game built with Unity 6 and URP, featuring a 10-level Harry Potter-themed campaign with voice-controlled spell casting.",
    problem: "Create an immersive wizard combat game with progressive difficulty, real-time spell physics, and innovative voice-controlled input.",
    solution: "Developed a Unity 6 game with Universal Render Pipeline, featuring 8 progressively unlocked spells with projectile physics, shields, and status effects. Integrated Featherless Whisper API for voice-to-spell casting and optional LLM-powered opponent AI decisions.",
    impact: "10-level campaign from Professor Quirrell to Lord Voldemort across themed arenas. State machine AI with weighted decision-making and dynamic arena theming per level.",
    tech: ["Unity 6", "C#", "URP", "Cinemachine", "Whisper API", "LLM", "ProBuilder"],
    githubRepo: "KPandya1903/Unity---Harry-Potter-",
    highlights: [
      "10-level Harry Potter-themed campaign",
      "Voice-controlled spell casting via Whisper API",
      "8 spells with projectile physics and status effects",
      "State machine AI with weighted decisions",
      "Dynamic arena theming with ArenaThemeApplier"
    ],
    date: "Feb 2026"
  },
  {
    id: "vehicle-matching",
    title: "Vehicle Matching System (AIRGarage Track)",
    category: "Computer Vision & Deep Learning",
    description: "Multi-stage computer vision pipeline for associating vehicle entry-exit events across 100K+ images with 94% matching accuracy.",
    problem: "Need to accurately match vehicle entry and exit events across a massive dataset of parking lot images for automated parking management.",
    solution: "Assembled a multi-stage CV pipeline using YOLO for vehicle detection, FastALPR + OCR for license plate reading, and ResNet for vehicle feature matching. Accelerated processing with CUDA-optimized GPU inference.",
    impact: "Achieved 94% matching accuracy across 100K+ images. Reduced end-to-end processing latency under batch workloads using GPU acceleration.",
    tech: ["Python", "YOLO", "FastALPR", "OCR", "ResNet", "CUDA", "Computer Vision", "Deep Learning"],
    githubRepo: "KPandya1903/Vehicle-Matching-System",
    highlights: [
      "94% matching accuracy across 100K+ images",
      "Multi-stage pipeline: YOLO → FastALPR + OCR → ResNet",
      "GPU-accelerated inference with CUDA",
      "Real-time batch processing"
    ],
    date: "Dec 2025"
  },
  {
    id: "cf-doc-explorer",
    title: "Cloudflare AI Doc Explorer",
    category: "AI & Edge Computing",
    description: "Production-ready semantic documentation search and AI chat system built on Cloudflare's edge infrastructure with vector embeddings and Gemini.",
    problem: "Enable natural language querying of Cloudflare documentation with context-aware AI responses and sub-second search latency.",
    solution: "Built a semantic search system using Cloudflare Workers, Vectorize for 768-dimensional BGE embeddings, and Durable Objects for persistent chat with SQLite. Integrated Google Gemini 2.0 Flash for AI-powered responses with real-time streaming.",
    impact: "70ms cold start, 200-400ms search latency. Bundle optimized from 1.5MB to 285KB gzipped. 25+ indexed documentation chunks with persistent chat history.",
    tech: ["TypeScript", "Cloudflare Workers", "Vectorize", "Gemini", "React 19", "Durable Objects", "Tailwind CSS"],
    githubRepo: "KPandya1903/cf_ai_doc-explorer-for-CloudFlare",
    highlights: [
      "Semantic search with BGE vector embeddings",
      "70ms cold start, 200-400ms search latency",
      "Real-time AI response streaming via Gemini",
      "Persistent chat history with Durable Objects",
      "Bundle optimized: 1.5MB → 285KB gzipped"
    ],
    date: "Jan 2026"
  },
  {
    id: "credit-risk",
    title: "Credit Risk Inference System",
    category: "Machine Learning & Backend",
    description: "Production-grade credit risk model using XGBoost analyzing 50,000+ borrower records with 91% AUC-ROC and real-time Flask inference API.",
    problem: "Build a reliable credit risk assessment system capable of real-time loan predictions with high accuracy and low latency.",
    solution: "Developed an XGBoost classifier with scikit-learn pipeline incorporating StandardScaler and categorical encoding. Built Flask REST API for real-time inference with health checks, single predictions, and batch processing endpoints.",
    impact: "Achieved 91% AUC-ROC and 81% accuracy. API responses under 200ms median latency, handling 1,000+ daily predictions with concurrent request support.",
    tech: ["Python", "XGBoost", "scikit-learn", "Flask", "PostgreSQL", "pandas", "NumPy"],
    githubRepo: "KPandya1903/Credit-Risk-Inference-System",
    highlights: [
      "91% AUC-ROC with XGBoost classifier",
      "Real-time API with <200ms median latency",
      "1,000+ daily predictions capacity",
      "Batch processing endpoint",
      "Docker-ready production deployment"
    ],
    date: "Jan 2026"
  },
  {
    id: "passmanager",
    title: "PassManager Server",
    category: "Security & Backend",
    description: "Lightweight password manager server with trust-free architecture, end-to-end encryption, and secure session management.",
    problem: "Deploy a secure password management solution on modest infrastructure without sacrificing cryptographic security standards.",
    solution: "Built a Python-based server implementing trust-free architecture with end-to-end encryption, secure key management, and session-based access control. Designed RESTful API with comprehensive endpoint documentation and standardized response formats.",
    impact: "Lightweight deployment suitable for small-scale infrastructure. Complete cryptographic implementation with secure authentication and encrypted data storage.",
    tech: ["Python", "Cryptography", "REST API", "Session Management", "Database"],
    githubRepo: "KPandya1903/PassManager-Server",
    highlights: [
      "Trust-free architecture design",
      "End-to-end encryption for stored credentials",
      "Secure session management and access control",
      "Comprehensive API documentation",
      "Lightweight deployable server"
    ],
    date: "Jan 2026"
  },
  {
    id: "ventureview-hr",
    title: "VentureViewHR — AI HR Assistant",
    category: "AI & Full-Stack",
    description: "AI-powered HR analytics application built with Gemini AI for intelligent recruitment insights and workforce management.",
    problem: "Streamline HR decision-making with AI-driven analysis of recruitment data and workforce metrics.",
    solution: "Built an AI Studio application powered by Google Gemini API, providing intelligent HR analytics and recruitment insights through a modern TypeScript interface.",
    impact: "AI-driven HR analytics with real-time Gemini-powered insights for recruitment and workforce management decisions.",
    tech: ["TypeScript", "Gemini AI", "React", "Node.js"],
    githubRepo: "KPandya1903/VentureViewHR",
    highlights: [
      "Gemini AI-powered HR analytics",
      "Real-time recruitment insights",
      "Modern TypeScript interface",
      "AI Studio integration"
    ],
    date: "Nov 2025"
  },
  {
    id: "pulse",
    title: "Pulse — Distributed Task Orchestrator",
    category: "Distributed Systems",
    description: "Horizontally scalable distributed task orchestration service with REST APIs, Redis priority queues, and fault-tolerant task processing.",
    problem: "Need for a reliable, fault-tolerant task orchestration system capable of handling burst workloads without task starvation or retry storms.",
    solution: "Built a distributed orchestrator exposing REST APIs for task submission, scheduling, and status tracking. Implemented horizontally scalable workers consuming from Redis priority queues with priority-aware batching, idempotent execution, and bounded retries.",
    impact: "Handles 10K+ tasks/day with 99.9% reliability. Resolved task starvation and retry storms under burst workloads, stabilizing end-to-end task processing.",
    tech: ["Python", "FastAPI", "PostgreSQL", "Redis", "Docker", "Distributed Systems"],
    githubRepo: "KPandya1903/Pulse-Orchestrator",
    highlights: [
      "10K+ tasks/day processing capacity",
      "99.9% reliability with fault tolerance",
      "Priority-aware batching for fair scheduling",
      "Idempotent task execution with bounded retries",
      "Horizontally scalable worker architecture"
    ],
    date: "Oct 2025"
  },
  {
    id: "p2p-event-mesh",
    title: "Decentralized P2P Event Mesh",
    category: "Distributed Systems & Networking",
    description: "Decentralized peer-to-peer event mesh using Java, gRPC, and Chord-based DHT for real-time push-based message propagation.",
    problem: "Design a decentralized system for real-time event propagation across dynamic nodes without central coordination.",
    solution: "Formed a P2P event mesh using Java and gRPC with a Chord-based Distributed Hash Table (DHT) enabling real-time, push-based message propagation. Implemented fault tolerance for node joins, failures, and migrations.",
    impact: "Evaluated on Amazon EC2, maintaining consistent message delivery during node joins, failures, and migrations. Zero central point of failure with automatic DHT rebalancing.",
    tech: ["Java", "gRPC", "EC2", "Protobuf", "Chord DHT", "Distributed Systems", "Networking"],
    githubRepo: "KPandya1903/High-Performance-Decentralized-P2P-Event-Mesh",
    highlights: [
      "Chord-based DHT for decentralized routing",
      "Real-time push-based message propagation",
      "Fault-tolerant during node churn",
      "Deployed and tested on Amazon EC2",
      "Zero single point of failure"
    ],
    date: "Aug 2025"
  },
  {
    id: "smartkitchen-ai",
    title: "SmartKitchen AI",
    category: "AI/ML & Backend Systems",
    description: "Scalable backend with MobileNetV2-based ingredient recognition, recipe catalog of 8,000+ entries, and hybrid recommendation engine.",
    problem: "Build an intelligent kitchen assistant that recognizes ingredients and provides personalized meal recommendations with nutritional tracking.",
    solution: "Delivered a scalable backend integrating MobileNetV2-based ingredient recognition service with a 8,000+ recipe catalog. Implemented hybrid recommendation engine combining TF-IDF content-based filtering with user-preference signals.",
    impact: "Real-time ingredient recognition and personalized recommendations. Automated inventory tracking and nutritional data retrieval in end-to-end production workflow.",
    tech: ["Python", "MobileNetV2", "TensorFlow", "TF-IDF", "Backend Systems", "Recommendation Engines"],
    githubRepo: "KPandya1903/Smart-Kitchen",
    highlights: [
      "MobileNetV2-based ingredient recognition",
      "8,000+ recipe catalog integration",
      "Hybrid TF-IDF + preference-based recommendations",
      "Automated inventory and nutrition tracking",
      "Production-ready backend architecture"
    ],
    date: "Oct 2024"
  }
];
