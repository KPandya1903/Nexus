import { ScrollReveal } from "../animations/ScrollReveal";
import { linkedinPosts } from "@/data/linkedinPosts";
import { FaLinkedin, FaThumbsUp, FaComment } from "react-icons/fa";
import { HiExternalLink } from "react-icons/hi";

export const LinkedIn = () => {
  if (linkedinPosts.length === 0) return null;

  return (
    <section id="linkedin" className="py-20 bg-surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <ScrollReveal>
          <div className="flex items-center justify-center gap-3 mb-4">
            <FaLinkedin className="w-7 h-7 text-accent-primary" />
            <h2 className="text-4xl sm:text-5xl font-bold text-text-primary">
              Recent <span className="text-accent-primary">Posts</span>
            </h2>
          </div>
          <div className="w-20 h-1 bg-accent-primary mx-auto mb-4" />
          <p className="text-center text-text-secondary max-w-xl mx-auto mb-12">
            Thoughts on distributed systems, AI/ML, and building things that scale
          </p>
        </ScrollReveal>

        {/* Horizontal scroll row */}
        <ScrollReveal delay={0.2}>
          <div className="flex gap-6 overflow-x-auto pb-4 snap-x snap-mandatory scrollbar-hide">
            {linkedinPosts.map((post) => (
              <a
                key={post.id}
                href={post.url}
                target="_blank"
                rel="noopener noreferrer"
                className="group snap-start flex-shrink-0 w-[340px] bg-surface-light rounded-xl p-6 border border-accent-cream hover:border-accent-secondary hover:shadow-card-hover transition-all duration-300 flex flex-col"
              >
                {/* Header */}
                <div className="flex items-center justify-between mb-4">
                  <span className="text-xs text-text-secondary font-medium">
                    {post.date}
                  </span>
                  <HiExternalLink className="w-4 h-4 text-text-secondary group-hover:text-accent-primary transition-colors" />
                </div>

                {/* Content */}
                <p className="text-sm text-text-secondary leading-relaxed flex-1 mb-4 line-clamp-5">
                  {post.content}
                </p>

                {/* Tags */}
                {post.tags && post.tags.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-4">
                    {post.tags.map((tag) => (
                      <span
                        key={tag}
                        className="text-xs px-2 py-1 bg-surface text-text-secondary rounded-full border border-accent-cream"
                      >
                        #{tag}
                      </span>
                    ))}
                  </div>
                )}

                {/* Stats */}
                {(post.likes !== undefined || post.comments !== undefined) && (
                  <div className="flex items-center gap-4 pt-4 border-t border-accent-cream text-xs text-text-secondary">
                    {post.likes !== undefined && (
                      <span className="flex items-center gap-1">
                        <FaThumbsUp className="w-3 h-3 text-accent-secondary" />
                        {post.likes}
                      </span>
                    )}
                    {post.comments !== undefined && (
                      <span className="flex items-center gap-1">
                        <FaComment className="w-3 h-3 text-accent-secondary" />
                        {post.comments}
                      </span>
                    )}
                  </div>
                )}
              </a>
            ))}
          </div>
        </ScrollReveal>

        {/* LinkedIn profile link */}
        <ScrollReveal delay={0.4}>
          <div className="text-center mt-8">
            <a
              href="https://www.linkedin.com/in/kpandya7/"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-accent-primary hover:text-accent-hover transition-colors font-medium"
            >
              <FaLinkedin className="w-4 h-4" />
              View full profile on LinkedIn →
            </a>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
};
