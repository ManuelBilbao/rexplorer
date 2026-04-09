## MODIFIED Requirements

### Requirement: Button component
The system SHALL provide a `Button` component with variants: `primary`, `secondary`, `ghost`, `danger`. It MUST support `size` prop (`sm`, `md`, `lg`), `disabled` state, and `loading` state (with spinner). All variants MUST work in both light and dark modes. The `secondary` variant MUST support the "Load more" pattern used across pagination footers (border style, full-width option).

#### Scenario: Primary button renders
- **WHEN** `<Button variant="primary">Submit</Button>` is rendered
- **THEN** a styled button with the primary color scheme is displayed

#### Scenario: Loading state shows spinner
- **WHEN** `<Button loading>Saving</Button>` is rendered
- **THEN** the button shows a spinner icon and is non-interactive

#### Scenario: Load more button in pagination
- **WHEN** `<Button variant="secondary" onClick={loadMore} disabled={isFetching}>Load more</Button>` is rendered
- **THEN** a border-styled button matching the current pagination pattern is displayed
- **AND** the button is disabled and shows loading feedback when `isFetching` is true

### Requirement: DataTable component
The system SHALL provide a `DataTable` component that renders tabular data with support for: column definitions, row rendering, empty state, loading skeleton rows, and a "load more" / pagination footer. It MUST NOT implement client-side sorting (server handles pagination). It MUST accept a `columns` prop defining headers and cell renderers, and a `data` prop with the rows. The `onLoadMore` callback and `hasMore` boolean MUST control the pagination footer. The pagination footer MUST use the `Button` component.

#### Scenario: Table with data
- **WHEN** `<DataTable columns={cols} data={rows} />` is rendered with 10 rows
- **THEN** a table with headers and 10 rows is displayed

#### Scenario: Loading state
- **WHEN** `<DataTable columns={cols} loading />` is rendered
- **THEN** skeleton rows are displayed using the `Skeleton` component

#### Scenario: Empty state
- **WHEN** `<DataTable columns={cols} data={[]} emptyMessage="No blocks found" />` is rendered
- **THEN** the empty message is displayed instead of rows

#### Scenario: Pagination with load more
- **WHEN** `<DataTable columns={cols} data={rows} hasMore onLoadMore={fn} />` is rendered
- **THEN** a "Load more" Button is displayed below the table
