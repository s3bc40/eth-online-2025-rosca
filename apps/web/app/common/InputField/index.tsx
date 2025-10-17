import React from "react";

type InputProps = {
  label: string;

  id: string;
  name: string;

  value: string;

  placeholder?: string;

  required?: boolean;

  className?: string;

  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
};

export const InputField: React.FC<InputProps> = ({
  label,
  id,
  name,
  value,
  placeholder = "",
  required = false,
  className = "",
  onChange,
}) => {
  return (
    <div className="">
      <div>
        <label
          htmlFor={id}
          className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
        >
          {label} {required && "*"}
        </label>

        <input
          type="text"
          id={id}
          name={name}
          value={value}
          onChange={onChange}
          required={required}
          placeholder={placeholder}
          className={`w-full px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent ${className}`}
        />
      </div>
    </div>
  );
};
