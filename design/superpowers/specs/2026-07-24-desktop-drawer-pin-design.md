# Desktop Drawer Pin Design

## Goal

Improve the desktop navigation drawer without changing the existing mobile interaction:

- the top-left menu button opens and closes the desktop drawer;
- while the drawer is open, the header and page content move right by the drawer width instead of being covered;
- the drawer contains a pin control;
- pinning persists across MkDocs instant navigation and full-page reloads;
- unpinning closes the drawer immediately and restores the full-width layout.

## Interaction model

Material for MkDocs already owns the `#__drawer` checkbox and the header menu button. The desktop behavior will continue to use that checkbox as the single open/closed state.

The pin control is desktop-only. Activating it stores a boolean value in `localStorage`, checks `#__drawer`, and updates its accessible pressed state. Deactivating it removes the stored value and immediately unchecks `#__drawer`.

On every MkDocs `document$` emission, the script recreates the control if the instant-navigation DOM replacement removed it and reapplies the persisted state. A normal reload follows the same initialization path.

The generated instant-navigation controller also handles same-origin page links when the preview host differs from the canonical `site_url`. Material's built-in sitemap matcher otherwise falls back to a full document navigation in that situation. The controller fetches the target document, replaces only the content, secondary TOC, and footer regions, and keeps the primary sidebar DOM (including its open and pinned state) intact. Browser back/forward uses the same content-only path.

## Layout

At the desktop breakpoint (`min-width: 76.25em`), the open checkbox shifts the header, main page area, and footer by the existing `12.1rem` drawer width. Their usable width shrinks by the same amount. The fixed drawer remains anchored to the viewport, so it occupies the newly reserved column rather than moving twice.

The desktop overlay is disabled while open so it cannot cover or intercept the shifted content. Existing drawer and nested-navigation transitions remain unchanged.

Below the desktop breakpoint, no pin control is inserted and none of the new shift rules apply.

## Persistence and accessibility

- Storage key: `llm-infra-wiki:desktop-drawer-pinned`.
- Stored value: `true`; absence means unpinned.
- The pin control is a real `button` with `aria-pressed`, an explicit Chinese accessible label, and visible `固定` / `已固定` text.
- Storage access is guarded so blocked storage does not break drawer use.

## Verification

The shell contract test checks generated CSS, generated JavaScript, and MkDocs inclusion. The Playwright regression checks temporary shifting, pin/unpin behavior, reload persistence, instant-navigation persistence, overlay removal, and unchanged mobile layout.
