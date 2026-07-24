# Desktop Drawer Pin Implementation Plan

**Goal:** Add a persistent, desktop-only drawer pin and reserve layout space whenever the drawer is open.

**Architecture:** Keep Material's `#__drawer` checkbox as the open-state source of truth. Generate one site-owned JavaScript file from `prepare_content.sh` for pin persistence and instant-navigation lifecycle handling, and add desktop-only CSS selectors for layout movement.

**Tech stack:** Bash-generated assets, CSS, browser JavaScript, MkDocs Material, Playwright async Python.

## Task 1: Lock the desired behavior in tests

**Files:**

- Modify: `scripts/test_desktop_layout.sh`
- Modify: `scripts/test_desktop_layout_browser.py`

1. Add static assertions for the new JavaScript asset, MkDocs reference, storage key, desktop shift rules, and desktop pin styles.
2. Add browser assertions for header/content movement and lack of overlay interception after a temporary open.
3. Add browser assertions for pin persistence across reload and instant navigation, plus immediate close on unpin.
4. Assert the mobile layout does not shift and has no pin control.
5. Run both focused tests and confirm they fail because the new behavior is absent.

## Task 2: Generate and load the pin controller

**Files:**

- Modify: `scripts/prepare_content.sh`
- Modify: `mkdocs.yml`

1. Generate `docs/javascripts/desktop-drawer.js`.
2. Guard the logic with the desktop media query.
3. Inject the accessible button into the primary navigation.
4. Persist pinned state in guarded `localStorage` access.
5. Reapply state on initial load, media-query changes, and MkDocs `document$` emissions.
6. Add the generated script to `extra_javascript` with a cache-busting query.

## Task 2a: Preserve the primary sidebar during page navigation

**Files:**

- Modify: `scripts/prepare_content.sh`
- Modify: `mkdocs.yml`
- Modify: `scripts/test_desktop_layout.sh`
- Modify: `scripts/test_desktop_layout_browser.py`

1. Add a same-origin navigation fallback that is independent of the canonical sitemap host.
2. Fetch the target HTML and replace only `.md-content`, `.md-sidebar--secondary`, and `.md-footer`.
3. Keep `.md-sidebar--primary` and `#__drawer` in place, update active navigation state, and emit `document$` for content renderers.
4. Preserve drawer layout during Material's route-close side effect and cover browser back navigation.
5. Verify the primary sidebar identity, open state, desktop geometry, and mobile behavior across next-page and back navigation.

## Task 3: Reserve desktop layout space

**Files:**

- Modify: `scripts/prepare_content.sh`

1. Add transitions for header, main, and footer.
2. Shift LTR and RTL layouts by `12.1rem` when `#__drawer` is checked.
3. Shrink the affected regions by the same amount.
4. Disable the desktop overlay while keeping the mobile overlay unchanged.
5. Style the injected pin control only at the desktop breakpoint.

## Task 4: Verify and review

**Files:**

- Regenerate ignored `docs/` assets from the content repository.
- Optionally update test documentation only if the invocation changes.

1. Run the static layout contract test.
2. Run shell syntax checks and `scripts/validate_site.sh` with the repository `.venv` on `PATH`.
3. Run the Playwright desktop/mobile regression against a freshly built local preview.
4. Run `git diff --check` and inspect the final diff.
5. Request an independent code review, address substantive findings, then rerun the complete verification set.
