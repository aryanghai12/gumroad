import { Icon } from "$app/components/Icons";
import * as React from "react";

type AlertVariant = "success" | "danger" | "warning" | "info";

type AlertProps = {
  variant: AlertVariant;
  children: React.ReactNode;
  onClose?: () => void;
  className?: string;
  role?: "alert" | "status";
};

const ALERT_CONFIG: Record<
  AlertVariant,
  {
    icon: IconName;
    cssVar: string;
  }
> = {
  success: {
    icon: "solid-check-circle",
    cssVar: "success",
  },
  danger: {
    icon: "x-circle-fill",
    cssVar: "danger",
  },
  warning: {
    icon: "solid-shield-exclamation",
    cssVar: "warning",
  },
  info: {
    icon: "info-circle-fill",
    cssVar: "info",
  },
};

export const Alert = ({ variant, children, onClose, className, role = "alert" }: AlertProps) => {
  const config = ALERT_CONFIG[variant];
  const colorVar = `var(--${config.cssVar})`;

  return (
    <div
      role={role}
      className={className}
      style={{
        display: "grid",
        gridTemplateColumns: onClose ? "auto 1fr auto" : "auto 1fr",
        alignItems: "start",
        gap: "var(--spacer-2)",
        padding: "var(--spacer-3)",
        borderWidth: "var(--border-width)",
        borderStyle: "solid",
        borderColor: `rgb(${colorVar})`,
        borderRadius: "var(--border-radius-1)",
        backgroundColor: `rgb(${colorVar} / 0.2)`,
      }}
    >
      <Icon
        name={config.icon}
        style={{
          width: "1lh",
          minHeight: "max(1lh, 1em)",
          color: `rgb(${colorVar})`,
        }}
      />
      <div>{children}</div>
      {onClose && <button className="close" style={{ alignSelf: "center" }} onClick={onClose} aria-label="Close" />}
    </div>
  );
};
