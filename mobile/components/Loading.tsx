import { ScreenLoader } from "@/components/animations/ScreenLoader";

interface LoadingProps {
  message?: string;
}

export function Loading({ message = "Loading..." }: LoadingProps) {
  return <ScreenLoader message={message} />;
}
