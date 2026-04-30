import { ScrollReveal } from "../animations/ScrollReveal";
import { ProjectCarousel } from "./ProjectCarousel";

export const Projects = () => {
  return (
    <section id="projects" className="py-20 bg-background">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <h2 className="text-4xl sm:text-5xl font-bold text-center mb-4 text-text-primary">
            Featured <span className="text-accent-primary">Projects</span>
          </h2>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-4" />
          <p className="text-center text-text-secondary max-w-2xl mx-auto mb-8">
            A selection of projects demonstrating expertise in distributed systems,
            AI/ML, and scalable backend architecture
          </p>
        </ScrollReveal>

        <ProjectCarousel />

        {/* GitHub Link */}
        <div className="text-center mt-8">
          <a
            href="https://github.com/kpandya1903"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-accent-primary hover:text-accent-hover transition-colors font-medium"
          >
            View More Projects on GitHub →
          </a>
        </div>
      </div>
    </section>
  );
};
