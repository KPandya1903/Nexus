import { Experience } from "@/types";

export const experiences: Experience[] = [
  {
    id: "backend-engineer-stevens",
    title: "Backend Engineer – Distributed ML Platform",
    company: "Stevens Institute of Technology",
    location: "Hoboken, NJ",
    period: "Nov 2025 – Present",
    current: true,
    description: [
      "Architecting and building a distributed profiling platform for federated machine learning, handling energy metrics collection from 100+ edge devices in real-time.",
      "Developed scalable backend infrastructure using TensorFlow.js, Socket.IO, and Redis to process per-layer power consumption data across heterogeneous device networks, optimizing for low-latency data aggregation and fault tolerance."
    ],
    tech: ["TensorFlow.js", "Socket.IO", "Redis", "Distributed Systems", "Real-time Processing", "Edge Computing", "System Architecture"]
  },
  {
    id: "founding-engineer-placement",
    title: "Founding Engineer – Placement Intelligence Platform",
    company: "D. J. Sanghvi College of Engineering",
    location: "Mumbai, India",
    period: "May 2024 – June 2025",
    current: false,
    description: [
      "Built and scaled backend infrastructure from scratch for a placement platform serving 500+ students. Designed RESTful APIs handling 10K+ requests/day with <200ms p95 latency, optimizing database queries and implementing efficient caching strategies.",
      "Architected and deployed ML inference microservices including an spaCy-based resume parser (95% accuracy) and real-time computer vision pipeline processing at 30 FPS. Managed end-to-end product development from initial prototype to production deployment."
    ],
    tech: ["Node.js", "SQLite", "RESTful APIs", "Microservices", "spaCy", "TensorFlow", "System Design", "Product Development"]
  }
];
