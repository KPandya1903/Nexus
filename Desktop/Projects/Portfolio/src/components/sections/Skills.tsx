import { ScrollReveal } from "../animations/ScrollReveal";
import { SkillBadge } from "../ui/SkillBadge";
import { skills } from "@/data/skills";

export const Skills = () => {
  return (
    <section id="skills" className="py-20 bg-surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <h2 className="text-4xl sm:text-5xl font-bold text-center mb-4 text-text-primary">
            Technical <span className="text-accent-primary">Skills</span>
          </h2>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-16" />
        </ScrollReveal>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {skills.map((skillCategory, index) => (
            <ScrollReveal key={skillCategory.category} delay={0.1 * (index + 1)}>
              <div className="bg-surface-light rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300">
                {/* Category Header */}
                <h3 className="text-xl font-bold text-text-primary mb-4 flex items-center">
                  <span className="w-2 h-2 rounded-full bg-accent-primary mr-3" />
                  {skillCategory.category}
                </h3>

                {/* Skills */}
                <div className="flex flex-wrap gap-2">
                  {skillCategory.skills.map((skill) => (
                    <SkillBadge key={skill} skill={skill} />
                  ))}
                </div>
              </div>
            </ScrollReveal>
          ))}
        </div>

        {/* Additional Note */}
        <ScrollReveal delay={0.8}>
          <div className="mt-12 text-center">
            <p className="text-text-secondary">
              Always learning and exploring new technologies to build better systems
            </p>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
};
