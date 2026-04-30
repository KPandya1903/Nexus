import { ScrollReveal } from "../animations/ScrollReveal";
import { ExperienceCard } from "../ui/ExperienceCard";
import { experiences } from "@/data/experience";

export const Experience = () => {
  return (
    <section id="experience" className="py-20 bg-background">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <h2 className="text-4xl sm:text-5xl font-bold text-center mb-4 text-text-primary">
            <span className="text-accent-primary">Experience</span>
          </h2>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-16" />
        </ScrollReveal>

        <div className="relative">
          {experiences.map((experience, index) => (
            <ScrollReveal key={experience.id} delay={0.2 * (index + 1)}>
              <ExperienceCard experience={experience} />
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
};
