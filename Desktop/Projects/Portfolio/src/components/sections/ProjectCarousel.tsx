"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { HiChevronLeft, HiChevronRight } from "react-icons/hi";
import { projects } from "@/data/projects";
import { ProjectCard } from "../ui/ProjectCard";
import { cn } from "@/lib/utils";

const TOTAL = projects.length;

const SLOT_OFFSETS = [-2, -1, 0, 1, 2] as const;

const slotStyles: Record<number, { scale: number; opacity: number; zIndex: number }> = {
  0: { scale: 1, opacity: 1, zIndex: 10 },
  1: { scale: 0.82, opacity: 0.5, zIndex: 5 },
  [-1]: { scale: 0.82, opacity: 0.5, zIndex: 5 },
  2: { scale: 0.70, opacity: 0.25, zIndex: 1 },
  [-2]: { scale: 0.70, opacity: 0.25, zIndex: 1 },
};

const slideVariants = {
  enter: (dir: number) => ({ x: dir > 0 ? 50 : -50, opacity: 0 }),
  center: { x: 0, opacity: 1 },
  exit: (dir: number) => ({ x: dir > 0 ? -50 : 50, opacity: 0 }),
};

export const ProjectCarousel = () => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState(1);
  const isHovering = useRef(false);

  const navigate = useCallback((dir: 1 | -1) => {
    setDirection(dir);
    setCurrentIndex((prev) => (prev + dir + TOTAL) % TOTAL);
  }, []);

  const goToIndex = useCallback((i: number) => {
    setDirection(i > currentIndex || (currentIndex === TOTAL - 1 && i === 0) ? 1 : -1);
    setCurrentIndex(i);
  }, [currentIndex]);

  useEffect(() => {
    const id = setInterval(() => {
      if (!isHovering.current) navigate(1);
    }, 4500);
    return () => clearInterval(id);
  }, [navigate]);

  const getProject = (offset: number) =>
    projects[(currentIndex + offset + TOTAL) % TOTAL];

  return (
    <div
      className="relative"
      onMouseEnter={() => { isHovering.current = true; }}
      onMouseLeave={() => { isHovering.current = false; }}
    >
      {/* Carousel Track */}
      <div className="overflow-hidden py-8">
        <div className="flex items-center justify-center gap-4">
          {SLOT_OFFSETS.map((offset) => {
            const project = getProject(offset);
            const isFeatured = offset === 0;
            const style = slotStyles[offset];

            return (
              <motion.div
                key={offset}
                animate={{ scale: style.scale, opacity: style.opacity }}
                transition={{ type: "spring", stiffness: 300, damping: 30 }}
                style={{ zIndex: style.zIndex }}
                className={cn(
                  "flex-shrink-0 self-stretch",
                  isFeatured
                    ? "w-[520px] max-w-[85vw]"
                    : Math.abs(offset) === 1
                    ? "w-[280px] hidden sm:block"
                    : "w-[220px] hidden lg:block"
                )}
              >
                {isFeatured ? (
                  <AnimatePresence mode="wait" custom={direction}>
                    <motion.div
                      key={project.id}
                      custom={direction}
                      variants={slideVariants}
                      initial="enter"
                      animate="center"
                      exit="exit"
                      transition={{ duration: 0.3, ease: "easeInOut" }}
                      className="h-full"
                    >
                      <ProjectCard project={project} isFeatured={true} />
                    </motion.div>
                  </AnimatePresence>
                ) : (
                  <ProjectCard
                    project={project}
                    isFeatured={false}
                    onSelect={() =>
                      goToIndex((currentIndex + offset + TOTAL) % TOTAL)
                    }
                  />
                )}
              </motion.div>
            );
          })}
        </div>
      </div>

      {/* Arrow Buttons */}
      <button
        onClick={() => navigate(-1)}
        className="absolute left-2 top-1/2 -translate-y-1/2 z-20 w-10 h-10 rounded-full bg-surface border border-accent-cream text-accent-primary hover:bg-accent-cream transition-colors flex items-center justify-center shadow-card"
        aria-label="Previous project"
      >
        <HiChevronLeft className="w-5 h-5" />
      </button>
      <button
        onClick={() => navigate(1)}
        className="absolute right-2 top-1/2 -translate-y-1/2 z-20 w-10 h-10 rounded-full bg-surface border border-accent-cream text-accent-primary hover:bg-accent-cream transition-colors flex items-center justify-center shadow-card"
        aria-label="Next project"
      >
        <HiChevronRight className="w-5 h-5" />
      </button>

      {/* Progress Dots */}
      <div className="flex justify-center gap-2 mt-2">
        {projects.map((_, i) => (
          <button
            key={i}
            onClick={() => goToIndex(i)}
            aria-label={`Go to project ${i + 1}`}
            className={cn(
              "h-2 rounded-full transition-all duration-300",
              i === currentIndex
                ? "w-6 bg-accent-primary"
                : "w-2 bg-accent-cream hover:bg-accent-secondary"
            )}
          />
        ))}
      </div>
    </div>
  );
};
