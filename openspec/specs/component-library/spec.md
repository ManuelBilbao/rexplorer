## ADDED Requirements

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

### Requirement: Badge component
The system SHALL provide a `Badge` component with color variants: `green`, `red`, `yellow`, `blue`, `gray`. It MUST support both light and dark modes.

#### Scenario: Status badge
- **WHEN** `<Badge variant="green">Success</Badge>` is rendered
- **THEN** a green-tinted badge label is displayed

### Requirement: Tabs component
The system SHALL provide a `Tabs` component with `TabList` and `TabPanel` sub-components. The active tab MUST be visually highlighted. Tab switching MUST be controlled via props or internal state.

#### Scenario: Tab navigation
- **WHEN** the user clicks on a tab
- **THEN** the corresponding panel content is displayed and the tab is highlighted

### Requirement: Skeleton component
The system SHALL provide a `Skeleton` component for loading placeholders. It MUST support `width`, `height`, and `rounded` props. It MUST animate with a pulse or shimmer effect.

#### Scenario: Loading placeholder
- **WHEN** `<Skeleton width="200px" height="20px" />` is rendered
- **THEN** a pulsing placeholder of the specified dimensions is displayed

### Requirement: Modal component
The system SHALL provide a `Modal` component with overlay backdrop, close button, and body content. It MUST trap focus inside the modal and close on Escape key or backdrop click.

#### Scenario: Modal opens and closes
- **WHEN** a modal is opened
- **THEN** it displays with an overlay, and pressing Escape closes it

### Requirement: Toast notification component
The system SHALL provide a `Toast` component and a `useToast` hook for triggering notifications. Toasts MUST support `success`, `error`, `info` variants and auto-dismiss after a configurable duration.

#### Scenario: Toast notification appears
- **WHEN** `toast.success("Block indexed!")` is called
- **THEN** a success toast appears and auto-dismisses after the configured duration

### Requirement: Tooltip component
The system SHALL provide a `Tooltip` component that displays on hover/focus. It MUST position itself relative to the trigger element.

#### Scenario: Tooltip on hover
- **WHEN** the user hovers over a `<Tooltip content="Full hash: 0xabc...">` trigger
- **THEN** the tooltip text appears near the element

### Requirement: Dropdown component
The system SHALL provide a `Dropdown` component with trigger button and menu items. It MUST close when clicking outside or pressing Escape.

#### Scenario: Dropdown opens on click
- **WHEN** the user clicks the dropdown trigger
- **THEN** the menu items are displayed below the trigger

### Requirement: Dark mode support
All components MUST support dark mode via Tailwind's `dark:` class strategy. The dark mode toggle MUST persist the user's preference in localStorage and default to system preference.

#### Scenario: Toggle dark mode
- **WHEN** the user clicks the dark mode toggle
- **THEN** all components switch to dark color scheme and the preference is persisted
