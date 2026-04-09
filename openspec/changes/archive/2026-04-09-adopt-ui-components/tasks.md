## 1. Upgrade UI Components

- [x] 1.1 Update StatusBadge to use Badge internally (map status boolean → Badge variant)
- [x] 1.2 Update ChainBadge to use Badge internally, merge chain color maps (union of component's 10 + TxDetailPage's 5, including `bnb` alias)
- [x] 1.3 Verify Button `secondary` variant covers the "Load more" pattern used in AddressPage/BlockListPage (border style, disabled state feedback)
- [x] 1.4 Verify DataTable supports BlockListPage column patterns (custom cell renderers for BlockNumber, TimeAgo, gas bar) and BlockDetailPage patterns (AddressDisplay cells)
- [x] 1.5 Ensure DataTable's loading skeleton uses the Skeleton component (not raw animate-pulse divs)
- [x] 1.6 Ensure DataTable's "Load more" footer uses the Button component

## 2. Migrate BlockListPage

- [x] 2.1 Replace raw `<table>` with DataTable, define columns using BlockNumber, TimeAgo, and gas formatting
- [x] 2.2 Replace raw `<button>` "Load more" with DataTable's `onLoadMore`/`hasMore` props
- [x] 2.3 Replace inline skeleton divs with DataTable's built-in loading state
- [x] 2.4 Replace `timeAgo()` calls with TimeAgo component
- [x] 2.5 Replace manual block number Links with BlockNumber component

## 3. Migrate BlockDetailPage

- [x] 3.1 Replace raw `<table>` with DataTable for the transaction list
- [x] 3.2 Replace inline skeleton divs with Skeleton components
- [x] 3.3 Replace manual address Links with AddressDisplay component
- [x] 3.4 Replace manual block number Links with BlockNumber component
- [x] 3.5 Replace `timeAgo()` calls with TimeAgo component

## 4. Migrate HomePage

- [x] 4.1 Replace inline LoadingSkeleton function with Skeleton components
- [x] 4.2 Replace manual block number Links with BlockNumber component
- [x] 4.3 Replace `timeAgo()` calls with TimeAgo component
- [x] 4.4 Keep TxTypeIcon dots as-is (different visual purpose than StatusBadge per design decision)

## 5. Migrate AddressPage

- [x] 5.1 Replace all inline status badge spans (3 instances) with StatusBadge component
- [x] 5.2 Replace all raw "Load more" `<button>` elements (3 instances) with Button component
- [x] 5.3 Replace inline skeleton divs with Skeleton components
- [x] 5.4 Replace manual address Links with AddressDisplay component
- [x] 5.5 Replace `timeAgo()` calls with TimeAgo component
- [x] 5.6 Replace inline "Contract" badge with Badge component
- [x] 5.7 Evaluate AddressPage custom formatters (`formatBalance`, `formatTransferAmount`, `formatInternalValue`) — adopt TokenAmount where applicable

## 6. Migrate TxDetailPage

- [x] 6.1 Replace all inline status badge spans (4 instances) with StatusBadge component
- [x] 6.2 Remove local ChainBadge function, use imported ChainBadge component
- [x] 6.3 Replace raw toggle buttons (Simple/Advanced) with Button component
- [x] 6.4 Replace inline skeleton divs with Skeleton components
- [x] 6.5 Replace manual address Links with AddressDisplay component
- [x] 6.6 Replace manual block number Link with BlockNumber component
- [x] 6.7 Replace `timeAgo()` calls with TimeAgo component
- [x] 6.8 Replace inline frame status/mode badges with Badge or StatusBadge as appropriate

## 7. Delete Scaffolding

- [x] 7.1 Delete `frontend/src/pages/DesignPreview.tsx`
- [x] 7.2 Remove DesignPreview import and `/design` route from `App.tsx`

## 8. Documentation

- [x] 8.1 Document the component adoption workflow with a Mermaid diagram showing data flow from API → page → shared components
- [x] 8.2 Update frontend docs to reflect component usage guidelines (which component to use where)
