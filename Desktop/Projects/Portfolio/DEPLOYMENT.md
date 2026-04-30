# Deployment Guide

## Prerequisites

Before deploying your portfolio, ensure you have:

1. A GitHub account
2. Your actual resume PDF (replace `/public/resume.pdf`)
3. Your LinkedIn URL (update in `/src/data/metadata.ts`)
4. (Optional) A custom domain name

## Pre-Deployment Checklist

### 1. Update Personal Information

- [ ] Replace `/public/resume.pdf` with your actual resume
- [ ] Update LinkedIn URL in `/src/data/metadata.ts`
- [ ] Verify all email links work (`kunjspandya@gmail.com`)
- [ ] Verify GitHub username is correct (`kpandya1903`)

### 2. Update Site URLs

Replace `https://kunjpandya.com` with your actual domain in:
- [ ] `/src/data/metadata.ts` - Update `metadataBase`
- [ ] `/src/app/layout.tsx` - Update OpenGraph URLs
- [ ] `/src/app/robots.ts` - Update sitemap URL
- [ ] `/src/app/sitemap.ts` - Update site URL

If using Vercel subdomain (e.g., `portfolio.vercel.app`), use that instead.

### 3. Add OG Image (Optional)

Create an Open Graph image (1200x630px) and save it as `/public/og-image.png`:
- Include your name and title
- Use your brand colors (blue: #3b82f6, cyan: #06b6d4)
- Keep text large and readable

## Deploying to Vercel

### Step 1: Create GitHub Repository

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial portfolio implementation"

# Create GitHub repository at https://github.com/new
# Then connect it:
git remote add origin https://github.com/YOUR_USERNAME/portfolio.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy to Vercel

1. Go to [vercel.com](https://vercel.com) and sign up/login with GitHub
2. Click "Add New Project"
3. Import your portfolio repository
4. Vercel will auto-detect Next.js and configure settings
5. Click "Deploy"

Your site will be live at `https://YOUR_PROJECT.vercel.app` in ~2 minutes!

### Step 3: Configure Custom Domain (Optional)

1. Purchase a domain (e.g., `kunjpandya.com` from Namecheap, Google Domains)
2. In Vercel dashboard, go to your project → Settings → Domains
3. Add your custom domain
4. Follow Vercel's DNS configuration instructions
5. SSL certificate will be automatically provisioned

## Post-Deployment

### Verify Everything Works

- [ ] Visit your deployed site
- [ ] Test all navigation links
- [ ] Test theme toggle (dark/light mode)
- [ ] Click all project links (GitHub repos)
- [ ] Test resume download
- [ ] Test all contact links (email, GitHub, LinkedIn)
- [ ] Check mobile responsiveness
- [ ] Run Lighthouse audit (aim for 90+ scores)

### Lighthouse Audit

1. Open your site in Chrome
2. Right-click → Inspect → Lighthouse tab
3. Run audit for Desktop and Mobile
4. Target scores:
   - Performance: 90+
   - Accessibility: 90+
   - Best Practices: 90+
   - SEO: 90+

### Analytics (Optional)

Enable Vercel Analytics for visitor insights:
1. Go to your project in Vercel dashboard
2. Navigate to Analytics tab
3. Enable Vercel Analytics (free tier available)

## Updating Your Portfolio

Whenever you want to update your portfolio:

```bash
# Make your changes
git add .
git commit -m "Update project descriptions"
git push

# Vercel will automatically deploy the changes!
```

## Environment Variables

If you want to add GitHub API authentication for higher rate limits:

1. Create a GitHub Personal Access Token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Select `public_repo` scope
   - Copy the token

2. Add to Vercel:
   - Project Settings → Environment Variables
   - Name: `GITHUB_TOKEN`
   - Value: Your token
   - Redeploy the project

Then update `/src/lib/github.ts` to use the token:

```typescript
headers: {
  Accept: "application/vnd.github.v3+json",
  Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
},
```

## Troubleshooting

### Build Fails

- Check Vercel deployment logs for errors
- Ensure all dependencies are in `package.json`
- Run `npm run build` locally to test

### Images Not Loading

- Ensure images are in `/public` folder
- Use relative paths (e.g., `/image.png`, not `./image.png`)

### Fonts Not Loading

- Next.js font optimization handles this automatically
- Ensure you have internet connection (fonts load from Google)

## Performance Tips

1. **Image Optimization**: Use Next.js `<Image>` component (already implemented)
2. **Caching**: GitHub API data is cached for 1 hour (already implemented)
3. **Code Splitting**: Next.js handles this automatically
4. **Lazy Loading**: Scroll animations trigger on viewport entry (already implemented)

## Support

If you encounter issues:
1. Check [Next.js documentation](https://nextjs.org/docs)
2. Check [Vercel documentation](https://vercel.com/docs)
3. Review Vercel deployment logs for errors
4. Ensure all TODO items in this checklist are completed

---

Good luck with your portfolio! 🚀
