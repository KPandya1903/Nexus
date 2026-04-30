export interface Project {
  id: string;
  title: string;
  category: string;
  description: string;
  problem: string;
  solution: string;
  impact: string;
  tech: string[];
  githubRepo?: string;
  highlights: string[];
  date: string;
}

export interface Experience {
  id: string;
  title: string;
  company: string;
  location: string;
  period: string;
  description: string[];
  tech: string[];
  current: boolean;
}

export interface Education {
  id: string;
  degree: string;
  field: string;
  institution: string;
  location: string;
  period: string;
  coursework?: string[];
}

export interface SkillCategory {
  category: string;
  skills: string[];
}

export interface GitHubRepo {
  name: string;
  stars: number;
  forks: number;
  language: string;
  languageColor?: string;
}

export interface ContactLink {
  label: string;
  url: string;
  icon: string;
}
