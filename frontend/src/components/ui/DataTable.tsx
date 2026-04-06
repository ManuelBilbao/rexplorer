import React from "react";
import Skeleton from "./Skeleton";
import Button from "./Button";

interface Column<T> {
  header: string;
  accessor: string | ((row: T) => React.ReactNode);
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  loading?: boolean;
  emptyMessage?: string;
  onLoadMore?: () => void;
  hasMore?: boolean;
}

function getCell<T>(row: T, accessor: Column<T>["accessor"]): React.ReactNode {
  if (typeof accessor === "function") return accessor(row);
  return (row as Record<string, unknown>)[accessor] as React.ReactNode;
}

export default function DataTable<T>({
  columns,
  data,
  loading = false,
  emptyMessage = "No data available.",
  onLoadMore,
  hasMore = false,
}: DataTableProps<T>) {
  return (
    <div className="w-full overflow-x-auto">
      <table className="min-w-full divide-y divide-rex-border">
        <thead className="bg-rex-bg-tertiary">
          <tr>
            {columns.map((col, i) => (
              <th
                key={i}
                className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-rex-text-secondary"
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-rex-border bg-rex-bg-secondary">
          {loading
            ? Array.from({ length: 5 }).map((_, rowIdx) => (
                <tr key={rowIdx}>
                  {columns.map((_, colIdx) => (
                    <td key={colIdx} className="px-4 py-3">
                      <Skeleton width="100%" height="1rem" />
                    </td>
                  ))}
                </tr>
              ))
            : data.length === 0
              ? (
                <tr>
                  <td
                    colSpan={columns.length}
                    className="px-4 py-8 text-center text-sm text-rex-text-secondary"
                  >
                    {emptyMessage}
                  </td>
                </tr>
              )
              : data.map((row, rowIdx) => (
                <tr
                  key={rowIdx}
                  className="hover:bg-rex-bg-tertiary transition-colors"
                >
                  {columns.map((col, colIdx) => (
                    <td
                      key={colIdx}
                      className="px-4 py-3 text-sm text-rex-text whitespace-nowrap"
                    >
                      {getCell(row, col.accessor)}
                    </td>
                  ))}
                </tr>
              ))}
        </tbody>
      </table>
      {hasMore && !loading && onLoadMore && (
        <div className="flex justify-center py-4">
          <Button variant="secondary" size="sm" onClick={onLoadMore}>
            Load more
          </Button>
        </div>
      )}
    </div>
  );
}
