import React from "react";

type ButtonProps = {
  /** Additional custom class names */
  className?: string;

  /** Optional icon to display inside the button */
  icon?: React.ReactNode;

  /** Label text for the button */
  label?: string;

  /** Function to handle button click */
  onClick?: () => void;

  /** Button variant: determines the style */
  variant?: "primary" | "dashed";

  /** Optionally disable the button */
  disabled?: boolean;
};

export default function ButtonContainer({
  className = "",
  icon,
  label,
  onClick,
  variant = "primary",
  disabled = false,
}: ButtonProps) {
  // Base styles for the button
  const baseStyles =
    "w-full flex items-center justify-center py-3 px-4 rounded-lg font-medium transition-colors";

  // Styles for different button variants
  const variantStyles = {
    primary:
      "btn-primary bg-primary-600 text-white hover:bg-primary-700 dark:bg-primary-500 dark:hover:bg-primary-400",
    dashed:
      "w-full py-3 px-4 border-2 border-dashed border-gray-300 dark:border-slate-600 rounded-lg text-primary-600 dark:text-primary-400 hover:border-primary-400 dark:hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/10 font-medium transition-colors flex items-center justify-center",
  };

  return (
    <button
      onClick={onClick}
      type="button"
      disabled={disabled}
      className={`${baseStyles} ${variantStyles[variant]} ${className} ${
        disabled
          ? "opacity-50 cursor-not-allowed"
          : "hover:opacity-100 focus:ring-2 focus:ring-primary-500"
      }`}
    >
      {icon && <span className="mr-2">{icon}</span>}
      {label}
    </button>
  );
}
