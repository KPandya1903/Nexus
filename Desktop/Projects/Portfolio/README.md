# Kunj Pandya - Portfolio Website

Modern, sleek portfolio website showcasing expertise in distributed systems, AI/ML, and backend engineering.

## 🚀 Tech Stack

- **Framework**: Next.js 15 (React 19)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Animations**: Framer Motion
- **Icons**: React Icons
- **Theme**: next-themes (dark/light mode)
- **Deployment**: Vercel

## ✨ Features

- 🎨 Modern, minimalist design with glassmorphism effects
- 🌓 Dark/light mode toggle with smooth transitions
- 📱 Fully responsive (mobile, tablet, desktop)
- ⚡ Fast performance (90+ Lighthouse score)
- 🎭 Smooth scroll animations with Framer Motion
- 🔗 Live GitHub project stats via GitHub API
- 🎯 SEO optimized with meta tags and structured data
- ♿ Accessible (WCAG AA compliant)
- 🎨 Custom color scheme with accent colors

## 📦 Getting Started

### Prerequisites

- Node.js 18+ and npm

### Installation

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint code
npm run lint
```

Open [http://localhost:3000](http://localhost:3000) to view the portfolio.

## 📂 Project Structure

```
portfolio/
├── public/              # Static assets
│   ├── images/         # Project images
│   ├── resume.pdf      # Resume PDF
│   └── favicon.svg     # Site favicon
├── src/
│   ├── app/            # Next.js app directory
│   │   ├── layout.tsx  # Root layout with SEO
│   │   ├── page.tsx    # Main homepage
│   │   ├── globals.css # Global styles
│   │   └── api/        # API routes (GitHub)
│   ├── components/     # React components
│   │   ├── sections/   # Page sections
│   │   ├── ui/         # Reusable UI components
│   │   └── animations/ # Animation wrappers
│   ├── data/           # Static data files
│   ├── lib/            # Utility functions
│   └── types/          # TypeScript types
└── ...config files
```

## 🎨 Sections

1. **Hero** - Full-screen landing with name, title, and CTAs
2. **About** - Bio and education (Stevens MS CS, DJSCE B.Tech AI/ML)
3. **Experience** - Timeline of research and work positions
4. **Projects** - Grid showcasing 4 major projects:
   - Vehicle Matching System (Computer Vision)
   - Pulse (Distributed Task Orchestrator)
   - Decentralized P2P Event Mesh
   - SmartKitchen AI
5. **Skills** - Categorized technical skills
6. **Contact** - Email, GitHub, LinkedIn links

## 🎯 Customization

### Update Personal Information

1. **Resume**: Replace `/public/resume.pdf` with your actual resume
2. **Metadata**: Update `/src/data/metadata.ts` with your info
3. **Projects**: Modify `/src/data/projects.ts` with your projects
4. **Experience**: Update `/src/data/experience.ts`
5. **Skills**: Edit `/src/data/skills.ts`
6. **Education**: Modify `/src/data/education.ts`

### Update Colors

Edit `/tailwind.config.ts` to change the color scheme:

```typescript
colors: {
  accent: {
    blue: "#3b82f6",    // Primary accent
    cyan: "#06b6d4",    // Secondary accent
    orange: "#f97316",  // CTA color
  },
}
```

### Update Site URL

Replace `https://kunjpandya.com` in:
- `/src/data/metadata.ts`
- `/src/app/layout.tsx`
- `/src/app/robots.ts`
- `/src/app/sitemap.ts`

## 🚀 Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions.

### Quick Deploy to Vercel

1. Push code to GitHub
2. Import repository in Vercel
3. Deploy (auto-configured for Next.js)

## 📊 Performance

Target Lighthouse Scores (all 90+):
- ⚡ Performance: 95+
- ♿ Accessibility: 95+
- ✅ Best Practices: 95+
- 🔍 SEO: 100

## 🛠️ Technologies Used

- **Next.js 15** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Animation library
- **next-themes** - Theme management
- **React Icons** - Icon library
- **GitHub API** - Live project stats

## 📝 License

This project is open source and available under the MIT License.

## 📧 Contact

- **Email**: kunjspandya@gmail.com
- **GitHub**: [@kpandya1903](https://github.com/kpandya1903)
- **LinkedIn**: [Kunj Pandya](https://linkedin.com/in/kunjpandya)
- **Location**: Hoboken, NJ

---

Built with ❤️ using Next.js, TypeScript, and Tailwind CSS
