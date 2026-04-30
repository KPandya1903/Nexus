export interface LinkedInPost {
  id: string;
  date: string;
  content: string;
  url: string;
  likes?: number;
  comments?: number;
  tags?: string[];
}

// Add your LinkedIn posts here manually.
// url: the full URL to the specific post (linkedin.com/posts/...)
export const linkedinPosts: LinkedInPost[] = [
  {
    id: "1",
    date: "March 2026",
    content:
      "Just shipped a distributed task orchestrator that processes 10K+ tasks/day using Go + Redis Streams. The hardest part wasn't the throughput — it was designing the failure recovery logic so no task is ever lost, even mid-crash.",
    url: "https://www.linkedin.com/in/kpandya7/",
    likes: 42,
    comments: 8,
    tags: ["Distributed Systems", "Go", "Backend"],
  },
  {
    id: "2",
    date: "February 2026",
    content:
      "Built a computer vision pipeline for real-time hand gesture recognition using MediaPipe + a custom LSTM model. Achieving 94% accuracy at 30fps on edge hardware. The secret: data augmentation + temporal smoothing.",
    url: "https://www.linkedin.com/in/kpandya7/",
    likes: 67,
    comments: 12,
    tags: ["Computer Vision", "ML", "Edge AI"],
  },
  {
    id: "3",
    date: "January 2026",
    content:
      "Reflected on building my first SaaS — the technical decisions that scaled and the ones that didn't. Microservices felt like overkill at user #10 but saved us at user #500. Context matters more than best practices.",
    url: "https://www.linkedin.com/in/kpandya7/",
    likes: 89,
    comments: 23,
    tags: ["Entrepreneurship", "SaaS", "Architecture"],
  },
];
