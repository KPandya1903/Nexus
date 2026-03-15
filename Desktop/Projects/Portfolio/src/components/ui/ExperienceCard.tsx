import React from "react";
import { Experience } from "@/types";
import { SkillBadge } from "./SkillBadge";
import { HiBriefcase, HiLocationMarker } from "react-icons/hi";
import { cn } from "@/lib/utils";

interface ExperienceCardProps {
  experience: Experience;
  className?: string;
}

export const ExperienceCard: React.FC<ExperienceCardProps> = ({ experience, className }) => {
  return (
    <div className={cn("relative pl-8 pb-12 last:pb-0", className)}>
      {/* Timeline Line */}
      <div className="absolute left-0 top-0 bottom-0 w-px bg-gradient-to-b from-accent-primary via-accent-secondary to-transparent" />

      {/* Timeline Dot */}
      <div className="absolute left-[-4px] top-2 w-2 h-2 rounded-full bg-accent-primary ring-4 ring-background" />

      {/* Content Card */}
      <div className="bg-surface rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300">
        {/* Header */}
        <div className="mb-4">
          <div className="flex items-start justify-between flex-wrap gap-2 mb-2">
            <h3 className="text-xl font-bold text-text-primary">
              {experience.title}
            </h3>
            {experience.current && (
              <span className="px-2 py-1 text-xs font-mono bg-accent-cream text-accent-primary rounded border border-accent-cream">
                Current
              </span>
            )}
          </div>

          <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 text-text-secondary text-sm">
            <div className="flex items-center gap-2">
              <HiBriefcase className="w-4 h-4 text-accent-primary" />
              <span className="font-medium">{experience.company}</span>
            </div>
            <div className="flex items-center gap-2">
              <HiLocationMarker className="w-4 h-4 text-accent-secondary" />
              <span>{experience.location}</span>
            </div>
          </div>

          <p className="text-sm text-text-secondary mt-2">{experience.period}</p>
        </div>

        {/* Description */}
        <ul className="space-y-2 mb-4">
          {experience.description.map((item, index) => (
            <li key={index} className="text-text-secondary text-sm flex items-start">
              <span className="text-accent-primary mr-2 mt-1">▸</span>
              <span>{item}</span>
            </li>
          ))}
        </ul>

        {/* Tech Stack */}
        <div className="flex flex-wrap gap-2">
          {experience.tech.map((tech) => (
            <SkillBadge key={tech} skill={tech} />
          ))}
        </div>
      </div>
    </div>
  );
};
