import { ScrollReveal } from "../animations/ScrollReveal";
import { siteMetadata } from "@/data/metadata";
import { education } from "@/data/education";
import { HiAcademicCap, HiLocationMarker } from "react-icons/hi";

export const About = () => {
  return (
    <section id="about" className="py-20 bg-surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <h2 className="text-4xl sm:text-5xl font-bold text-center mb-4 text-text-primary">
            About Me
          </h2>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-12" />
        </ScrollReveal>

        {/* Bio */}
        <ScrollReveal delay={0.2}>
          <div className="max-w-3xl mx-auto mb-16">
            {siteMetadata.bio.map((paragraph, index) => (
              <p
                key={index}
                className="text-lg text-text-secondary mb-4 leading-relaxed"
              >
                {paragraph}
              </p>
            ))}
          </div>
        </ScrollReveal>

        {/* Education */}
        <ScrollReveal delay={0.4}>
          <h3 className="text-3xl font-bold text-center mb-8 text-text-primary">
            Education
          </h3>
        </ScrollReveal>

        <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto">
          {education.map((edu, index) => (
            <ScrollReveal key={edu.id} delay={0.2 * (index + 3)}>
              <div className="bg-surface-light rounded-xl p-6 shadow-card hover:shadow-card-hover transition-all duration-300 border border-accent-cream">
                {/* Icon */}
                <div className="w-12 h-12 rounded-lg bg-surface flex items-center justify-center mb-4">
                  <HiAcademicCap className="w-7 h-7 text-accent-primary" />
                </div>

                {/* Degree */}
                <h4 className="text-xl font-bold text-text-primary mb-1">
                  {edu.degree}
                </h4>
                <p className="text-accent-secondary font-medium mb-2">{edu.field}</p>

                {/* Institution */}
                <p className="text-text-primary font-medium mb-2">
                  {edu.institution}
                </p>

                {/* Location & Period */}
                <div className="flex flex-col gap-1 text-sm text-text-secondary mb-3">
                  <div className="flex items-center gap-2">
                    <HiLocationMarker className="w-4 h-4 text-accent-secondary" />
                    <span>{edu.location}</span>
                  </div>
                  <p>{edu.period}</p>
                </div>

                {/* Coursework */}
                {edu.coursework && edu.coursework.length > 0 && (
                  <div className="mt-4 pt-4 border-t border-accent-cream">
                    <p className="text-sm font-medium text-text-secondary mb-2">
                      Key Coursework:
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {edu.coursework.slice(0, 3).map((course) => (
                        <span
                          key={course}
                          className="text-xs px-2 py-1 bg-surface text-text-secondary rounded-full border border-accent-cream"
                        >
                          {course}
                        </span>
                      ))}
                      {edu.coursework.length > 3 && (
                        <span className="text-xs text-text-secondary self-center">
                          +{edu.coursework.length - 3} more
                        </span>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
};
