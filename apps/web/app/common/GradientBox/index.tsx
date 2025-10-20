export function GradientBox({ children }: { children: React.ReactNode }) {
  return (
    <div className="bg-gradient-to-br from-primary-50 via-secondary-50 to-accent-50 dark:from-primary-950/30 dark:via-secondary-950/30 dark:to-accent-950/30 p-6 rounded-xl border-2 border-primary-200 dark:border-primary-800 shadow-md">
      {children}
    </div>
  );
}
