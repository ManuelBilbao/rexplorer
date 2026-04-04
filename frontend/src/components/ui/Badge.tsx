import React from "react";

type BadgeVariant = "green" | "red" | "yellow" | "blue" | "gray";

interface BadgeProps {
  variant?: BadgeVariant;
  children: React.ReactNode;
}

const variantClasses: Record<BadgeVariant, string> = {
  green:
    "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
  red:
    "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300",
  yellow:
    "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
  blue:
    "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300",
  gray:
    "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300",
};

export default function Badge({ variant = "gray", children }: BadgeProps) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variantClasses[variant]}`}
    >
      {children}
    </span>
  );
}
