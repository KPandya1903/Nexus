import React from "react";

interface SkillBadgeProps {
  skill: string;
  className?: string;
}

export const SkillBadge: React.FC<SkillBadgeProps> = ({ skill, className }) => {
  return (
    <span
      className={`px-3 py-1 text-xs font-medium rounded-full bg-surface text-text-secondary hover:bg-accent-cream transition-colors border border-accent-cream ${className}`}
    >
      {skill}
    </span>
  );
};
