import { ScrollReveal } from "../animations/ScrollReveal";
import { FaGithub, FaLinkedin, FaEnvelope, FaMapMarkerAlt } from "react-icons/fa";
import { siteMetadata } from "@/data/metadata";

export const Contact = () => {
  return (
    <section id="contact" className="py-20 bg-background">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <h2 className="text-4xl sm:text-5xl font-bold text-center mb-4 text-text-primary">
            Get in <span className="text-accent-primary">Touch</span>
          </h2>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-8" />
          <p className="text-center text-text-secondary max-w-2xl mx-auto mb-16">
            I&apos;m always open to discussing new opportunities, collaborations, or just
            having a chat about distributed systems and AI/ML.
          </p>
        </ScrollReveal>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Email */}
          <ScrollReveal delay={0.2}>
            <a
              href={`mailto:${siteMetadata.email}`}
              className="group bg-surface rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300 flex flex-col items-center text-center"
            >
              <div className="w-14 h-14 rounded-full bg-accent-cream flex items-center justify-center mb-4 group-hover:bg-accent-cream/60 transition-colors">
                <FaEnvelope className="w-6 h-6 text-accent-primary" />
              </div>
              <h3 className="font-semibold text-text-primary mb-2">Email</h3>
              <p className="text-sm text-text-secondary break-all">
                {siteMetadata.email}
              </p>
            </a>
          </ScrollReveal>

          {/* GitHub */}
          <ScrollReveal delay={0.3}>
            <a
              href={siteMetadata.github}
              target="_blank"
              rel="noopener noreferrer"
              className="group bg-surface rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300 flex flex-col items-center text-center"
            >
              <div className="w-14 h-14 rounded-full bg-accent-cream flex items-center justify-center mb-4 group-hover:bg-accent-cream/60 transition-colors">
                <FaGithub className="w-6 h-6 text-accent-primary" />
              </div>
              <h3 className="font-semibold text-text-primary mb-2">GitHub</h3>
              <p className="text-sm text-text-secondary">@kpandya1903</p>
            </a>
          </ScrollReveal>

          {/* LinkedIn */}
          <ScrollReveal delay={0.4}>
            <a
              href={siteMetadata.linkedin}
              target="_blank"
              rel="noopener noreferrer"
              className="group bg-surface rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300 flex flex-col items-center text-center"
            >
              <div className="w-14 h-14 rounded-full bg-accent-cream flex items-center justify-center mb-4 group-hover:bg-accent-cream/60 transition-colors">
                <FaLinkedin className="w-6 h-6 text-accent-primary" />
              </div>
              <h3 className="font-semibold text-text-primary mb-2">LinkedIn</h3>
              <p className="text-sm text-text-secondary">Connect with me</p>
            </a>
          </ScrollReveal>

          {/* Location */}
          <ScrollReveal delay={0.5}>
            <div className="bg-surface rounded-xl p-6 border border-accent-cream flex flex-col items-center text-center">
              <div className="w-14 h-14 rounded-full bg-accent-cream flex items-center justify-center mb-4">
                <FaMapMarkerAlt className="w-6 h-6 text-accent-primary" />
              </div>
              <h3 className="font-semibold text-text-primary mb-2">Location</h3>
              <p className="text-sm text-text-secondary">{siteMetadata.location}</p>
            </div>
          </ScrollReveal>
        </div>

        {/* Footer */}
        <ScrollReveal delay={0.6}>
          <div className="mt-16 pt-8 border-t border-accent-cream text-center">
            <p className="text-text-secondary text-sm">
              © {new Date().getFullYear()} {siteMetadata.name}. Built with Next.js,
              TypeScript, and Tailwind CSS.
            </p>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
};
