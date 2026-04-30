"use client";

import React, { useRef, useState } from "react";
import { Project } from "@/types";
import { SkillBadge } from "./SkillBadge";
import { FaGithub } from "react-icons/fa";
import { cn } from "@/lib/utils";

interface ProjectCardProps {
  project: Project;
  className?: string;
  isFeatured?: boolean;
  onSelect?: () => void;
}

export const ProjectCard: React.FC<ProjectCardProps> = ({
  project,
  className,
  isFeatured = true,
  onSelect,
}) => {
  const cardRef = useRef<HTMLDivElement>(null);
  const [rotateX, setRotateX] = useState(0);
  const [rotateY, setRotateY] = useState(0);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!cardRef.current) return;
    const card = cardRef.current;
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    setRotateX(((y - centerY) / centerY) * -10);
    setRotateY(((x - centerX) / centerX) * 10);
  };

  const handleMouseLeave = () => {
    setRotateX(0);
    setRotateY(0);
  };

  // Compact view for side carousel cards
  if (!isFeatured) {
    return (
      <div
        onClick={onSelect}
        className={cn(
          "cursor-pointer select-none bg-surface-light rounded-xl p-5 border border-accent-cream flex flex-col h-full transition-colors hover:border-accent-secondary",
          className
        )}
      >
        <span className="text-xs font-medium text-text-secondary bg-surface px-3 py-1 rounded-full self-start mb-3">
          {project.category}
        </span>
        <h3 className="text-base font-bold text-text-primary mb-1 line-clamp-2">
          {project.title}
        </h3>
        <p className="text-xs text-text-secondary mb-3">{project.date}</p>
        <div className="flex flex-wrap gap-1 mt-auto">
          {project.tech.slice(0, 3).map((tech) => (
            <SkillBadge key={tech} skill={tech} />
          ))}
        </div>
      </div>
    );
  }

  // Full featured view
  return (
    <div
      ref={cardRef}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={{
        transform: `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`,
        transition: "transform 0.1s ease-out",
      }}
      className={cn(
        "group relative bg-surface-light rounded-xl p-8 shadow-card hover:shadow-card-hover transition-shadow duration-300 flex flex-col h-full border border-accent-cream",
        className
      )}
    >
      {/* Category Badge */}
      <div className="mb-4">
        <span className="text-xs font-medium text-text-secondary bg-surface px-3 py-1 rounded-full">
          {project.category}
        </span>
      </div>

      {/* Title */}
      <h3 className="text-2xl font-bold text-text-primary mb-3">
        {project.title}
      </h3>

      {/* Date */}
      <p className="text-sm text-text-secondary mb-4">{project.date}</p>

      {/* Description */}
      <p className="text-text-secondary mb-4 leading-relaxed">
        {project.description}
      </p>

      {/* Impact Highlight */}
      <div className="mb-6 p-4 bg-surface rounded-lg border border-accent-cream">
        <p className="text-sm text-text-secondary">
          <span className="font-semibold text-accent-primary">Impact:</span>{" "}
          {project.impact}
        </p>
      </div>

      {/* Tech Stack */}
      <div className="flex flex-wrap gap-2 mb-6">
        {project.tech.slice(0, 5).map((tech) => (
          <SkillBadge key={tech} skill={tech} />
        ))}
        {project.tech.length > 5 && (
          <span className="text-xs text-text-secondary self-center">
            +{project.tech.length - 5} more
          </span>
        )}
      </div>

      {/* GitHub Link */}
      <div className="mt-auto pt-4 border-t border-accent-cream">
        {project.githubRepo && (
          <a
            href={`https://github.com/${project.githubRepo}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-sm font-medium text-accent-primary hover:text-accent-hover transition-colors"
          >
            <FaGithub className="w-4 h-4" />
            View on GitHub
          </a>
        )}
      </div>
    </div>
  );
};
