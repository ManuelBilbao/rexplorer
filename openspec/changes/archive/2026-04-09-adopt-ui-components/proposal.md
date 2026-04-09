## Why

The frontend has a well-defined component library (`components/ui/`) and explorer components (`components/explorer/`), but pages have drifted away from using them. Pages hand-roll raw `<button>`, `<table>`, status badges, and loading skeletons instead of using Button, DataTable, Badge, and Skeleton. Six explorer components (AddressDisplay, BlockNumber, ChainBadge, StatusBadge, TimeAgo, TokenAmount) exist but are imported nowhere — pages re-implement their functionality inline. This defeats the purpose of having a component system and creates visual inconsistency, duplicated logic, and higher maintenance cost.

## What Changes

- **Audit each page's inline implementations against the corresponding component** and determine which version is better (richer, more correct, better UX). Upgrade the component if the page version wins, then swap it in.
- **TxDetailPage**: Replace 4 inline status badges with StatusBadge, replace local ChainBadge function with the component, replace raw toggle buttons with Button, replace inline skeletons with Skeleton.
- **AddressPage**: Replace inline status badges with StatusBadge, replace "Load more" raw buttons with Button, replace inline skeletons with Skeleton, adopt AddressDisplay for address rendering, adopt Badge for "Contract" label.
- **BlockListPage**: Replace raw `<table>` with DataTable, replace raw "Load more" button with Button, replace inline skeletons with Skeleton.
- **BlockDetailPage**: Replace raw `<table>` with DataTable, replace inline skeletons with Skeleton.
- **HomePage**: Replace inline skeletons with Skeleton.
- **Adopt BlockNumber, TokenAmount, TimeAgo, TxHash, AddressDisplay** in pages wherever addresses, hashes, amounts, timestamps, or block numbers are rendered inline.
- **Remove DesignPreview.tsx** and its `/design` route from App.tsx (scaffolding artifact, served its purpose).

## Non-goals

- Not adding new UI components (Modal, Dropdown, Toast, Tooltip are defined but have no current use case in pages — that's fine).
- Not redesigning page layouts or changing functionality.
- Not touching backend code.

## Capabilities

### New Capabilities

_(none — this is a consistency/adoption change, not a new feature)_

### Modified Capabilities

- `component-library`: Some components may need updates (new variants, props) to cover what pages currently do inline. For example, Button may need to handle "Load more" patterns, StatusBadge may need additional status variants, DataTable may need to support the specific column patterns used in block/tx tables.
- `explorer-components`: Components like StatusBadge and ChainBadge may need refinement if the inline page versions handle edge cases the component doesn't.
- `frontend-pages`: All page files will be modified to import and use components instead of inline implementations.

## Impact

- **Frontend pages**: TxDetailPage, AddressPage, BlockListPage, BlockDetailPage, HomePage — all modified.
- **UI components**: Button, DataTable, Skeleton, Badge — potentially updated with new props/variants.
- **Explorer components**: StatusBadge, ChainBadge, AddressDisplay, BlockNumber, TimeAgo, TokenAmount, TxHash — adopted in pages, possibly updated.
- **Deleted**: DesignPreview.tsx, `/design` route.
- **Risk**: Low. Pure frontend refactor, no API or data model changes. Visual output should remain identical (or improve in consistency).
