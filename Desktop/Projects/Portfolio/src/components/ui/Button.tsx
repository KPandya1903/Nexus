import React from "react";
import { cn } from "@/lib/utils";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "outline";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = "primary",
  size = "md",
  className,
  children,
  ...props
}) => {
  const baseStyles = "font-medium rounded-lg transition-all duration-200 inline-flex items-center justify-center";

  const variantStyles = {
    primary: "bg-accent-orange hover:bg-accent-orange/90 text-white shadow-lg hover:shadow-xl hover:scale-105",
    secondary: "bg-accent-blue hover:bg-accent-blue/90 text-white shadow-lg hover:shadow-xl hover:scale-105",
    outline: "border-2 border-accent-blue text-accent-blue hover:bg-accent-blue hover:text-white",
  };

  const sizeStyles = {
    sm: "px-4 py-2 text-sm",
    md: "px-6 py-3 text-base",
    lg: "px-8 py-4 text-lg",
  };

  return (
    <button
      className={cn(baseStyles, variantStyles[variant], sizeStyles[size], className)}
      {...props}
    >
      {children}
    </button>
  );
};
