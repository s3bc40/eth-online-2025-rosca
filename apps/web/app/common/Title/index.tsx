import React from "react";

type TextProps = {
  text: string;

  type: "h1" | "h2" | "h3" | "label" | "pxs" | "psm";

  className?: string;
  icon?: React.ReactNode;
};

export function Text({ text, type, className, icon }: TextProps) {
  const baseStyles = {
    h1: "text-3xl font-bold text-gray-900 dark:text-slate-100",
    h2: "text-xl font-semibold text-gray-900 dark:text-slate-100 mb-4 flex items-center",
    label: "block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1",
    h3: "font-bold text-primary-900 dark:text-primary-200 text-sm mb-1",
    pxs: "text-xs text-primary-800 dark:text-primary-300",
    psm: "text-sm text-gray-600 dark:text-slate-400 mb-4",
  };

  return (
    <div className={`${baseStyles[type]} ${className || ""}`}>
      {icon} {text}
    </div>
  );
}
