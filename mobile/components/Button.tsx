import {
  ActivityIndicator,
  Pressable,
  Text,
  type PressableProps,
} from "react-native";

interface ButtonProps extends PressableProps {
  title: string;
  variant?: "primary" | "secondary" | "ghost";
  loading?: boolean;
  className?: string;
}

const variantStyles = {
  primary: "bg-primary-600 active:bg-primary-700",
  secondary: "bg-white border border-slate-200 active:bg-slate-50",
  ghost: "bg-transparent",
};

const textStyles = {
  primary: "text-white font-semibold",
  secondary: "text-slate-800 font-semibold",
  ghost: "text-primary-700 font-semibold",
};

export function Button({
  title,
  variant = "primary",
  loading = false,
  disabled,
  className = "",
  ...props
}: ButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <Pressable
      className={`rounded-xl px-4 py-3.5 items-center justify-center ${variantStyles[variant]} ${isDisabled ? "opacity-60" : ""} ${className}`}
      disabled={isDisabled}
      {...props}
    >
      {loading ? (
        <ActivityIndicator color={variant === "primary" ? "#fff" : "#2563EB"} />
      ) : (
        <Text className={textStyles[variant]}>{title}</Text>
      )}
    </Pressable>
  );
}
