import React from "react";

type BadgeVariant = "green" | "red" | "yellow" | "blue" | "gray";

interface BadgeProps {
  variant?: BadgeVariant;
  children: React.ReactNode;
}

const variantClasses: Record<BadgeVariant, string> = {
  green:
    "bg-rex-success/10 text-rex-success",
  red:
    "bg-rex-danger/10 text-rex-danger",
  yellow:
    "bg-rex-warning/10 text-rex-warning",
  blue:
    "bg-rex-primary/10 text-rex-primary",
  gray:
    "bg-rex-bg-tertiary text-rex-text-secondary",
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
