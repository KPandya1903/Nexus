import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import Script from "next/script";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains-mono",
});

export const metadata: Metadata = {
  title: "Kunj Pandya | Full-Stack Engineer & Entrepreneur",
  description: "Portfolio of Kunj Pandya - Building scalable backend systems and intelligent applications. MS CS student at Stevens Institute with expertise in distributed systems, microservices, and cloud infrastructure.",
  keywords: ["Kunj Pandya", "Full Stack Developer", "Backend Engineer", "Entrepreneur", "Distributed Systems", "Microservices", "Cloud Architecture", "System Design"],
  authors: [{ name: "Kunj Pandya" }],
  creator: "Kunj Pandya",
  publisher: "Kunj Pandya",
  metadataBase: new URL("https://kunjpandya.com"),
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Kunj Pandya | Full-Stack Engineer & Entrepreneur",
    description: "Building scalable backend systems and intelligent applications. Expertise in distributed systems, microservices, and cloud infrastructure.",
    url: "https://kunjpandya.com",
    siteName: "Kunj Pandya Portfolio",
    locale: "en_US",
    type: "website",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Kunj Pandya - Full-Stack Engineer & Entrepreneur",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Kunj Pandya | Full-Stack Engineer & Entrepreneur",
    description: "Building scalable backend systems and intelligent applications",
    images: ["/og-image.png"],
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=G-L4J7CCTJVB"
          strategy="afterInteractive"
        />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-L4J7CCTJVB');
          `}
        </Script>
      </head>
      <body
        className={`${inter.variable} ${jetbrainsMono.variable} font-sans antialiased bg-background text-text-primary`}
      >
        {children}
      </body>
    </html>
  );
}
