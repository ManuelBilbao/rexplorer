interface SkeletonProps {
  width?: string;
  height?: string;
  rounded?: boolean;
}

export default function Skeleton({
  width = "100%",
  height = "1rem",
  rounded = false,
}: SkeletonProps) {
  return (
    <div
      className={`animate-pulse bg-rex-bg-tertiary ${rounded ? "rounded-full" : "rounded"}`}
      style={{ width, height }}
    />
  );
}
