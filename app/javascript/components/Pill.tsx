import React from "react";
import { classNames } from "$app/utils/classNames";

interface PillProps {
  children: React.ReactNode;
  variant?: "filled" | "primary" | "success" | "warning" | "danger" | "info" | "black" | "accent";
  size?: "default" | "small";
  dismissable?: boolean;
  expandable?: boolean;
  isSelect?: boolean;
  onDismiss?: () => void;
  onExpand?: () => void;
  className?: string;
}

export default function Pill({
  children,
  variant = "filled",
  size = "default",
  dismissable = false,
  expandable = false,
  isSelect = false,
  onDismiss,
  onExpand,
  className,
}: PillProps) {
  const baseClasses = "inline-block align-middle border-solid border-[0.0625rem] overflow-hidden whitespace-nowrap text-ellipsis text-[rgb(var(--color))]";

  const sizeClasses = {
    default: "py-3 px-4 rounded-full",
    small: "p-2 rounded text-sm leading-[1.3]",
  };

  const variantClasses = {
    filled: "bg-[rgb(var(--filled))] border-[rgb(var(--parent-color)/var(--border-alpha))]",
    primary: "bg-[rgb(var(--primary))] border-[rgb(var(--primary))]",
    success: "bg-[rgb(var(--success))] border-[rgb(var(--success))]",
    danger: "bg-[rgb(var(--danger))] border-[rgb(var(--danger))]",
    warning: "bg-[rgb(var(--warning))] border-[rgb(var(--warning))]",
    info: "bg-[rgb(var(--info))] border-[rgb(var(--info))]",
    black: "bg-[rgb(var(--black))] border-[rgb(var(--black))]",
    accent: "bg-[rgb(var(--accent))] border-[rgb(var(--accent))]",
  };

  const variantCSSVars: Record<typeof variant, React.CSSProperties> = {
    filled: { "--color": "var(--contrast-filled)", "--parent-color": "inherit" } as React.CSSProperties,
    primary: { "--color": "var(--contrast-primary)", "--parent-color": "inherit" } as React.CSSProperties,
    success: { "--color": "var(--contrast-success)", "--parent-color": "inherit" } as React.CSSProperties,
    danger: { "--color": "var(--contrast-danger)", "--parent-color": "inherit" } as React.CSSProperties,
    warning: { "--color": "var(--contrast-warning)", "--parent-color": "inherit" } as React.CSSProperties,
    info: { "--color": "var(--contrast-info)", "--parent-color": "inherit" } as React.CSSProperties,
    black: { "--color": "var(--contrast-black)", "--parent-color": "inherit" } as React.CSSProperties,
    accent: { "--color": "var(--contrast-accent)", "--parent-color": "inherit" } as React.CSSProperties,
  };

  const handleClick = () => {
    if (dismissable && onDismiss) {
      onDismiss();
    }
    if (expandable && onExpand) {
      onExpand();
    }
  };

  return (
    <span
      className={classNames(
        baseClasses,
        sizeClasses[size],
        variantClasses[variant],
        {
          "cursor-pointer": dismissable || expandable || isSelect,
          "relative": isSelect,
        },
        className
      )}
      style={variantCSSVars[variant]}
      onClick={handleClick}
    >
      {children}
      {dismissable && (
        <span className="float-right ml-3">
          <i className="icon-x" />
        </span>
      )}
      {expandable && (
        <span className="float-right ml-3">
          <i className="icon-outline-cheveron-down" />
        </span>
      )}
      {isSelect && (
        <select
          className="absolute top-0 left-0 h-full w-full opacity-0 cursor-pointer"
          style={{
            color: "rgb(var(--color))",
            backgroundColor: "rgb(var(--filled))",
          }}
        />
      )}
    </span>
  );
}
