import { View, type ViewProps } from "react-native";

interface SkeletonProps extends ViewProps {
  className?: string;
}

export function Skeleton({ className = "", ...props }: SkeletonProps) {
  return (
    <View
      className={`animate-pulse rounded-lg bg-slate-200 ${className}`}
      {...props}
    />
  );
}

export function StatsSkeleton() {
  return (
    <View className="flex-row gap-3 px-4">
      {[1, 2, 3, 4].map((i) => (
        <Skeleton key={i} className="h-28 w-36 rounded-2xl" />
      ))}
    </View>
  );
}

export function ListSkeleton({ rows = 3 }: { rows?: number }) {
  return (
    <View className="gap-3 px-4">
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} className="h-16 w-full rounded-xl" />
      ))}
    </View>
  );
}

export function CardSkeleton() {
  return <Skeleton className="mx-4 h-32 rounded-2xl" />;
}
