#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
grep -Fq 'stylesheets/extra.css?v=20260724-drawer-parity' "${ROOT}/mkdocs.yml"
grep -Fq 'javascripts/desktop-drawer.js?v=20260724-drawer-pin' "${ROOT}/mkdocs.yml"
grep -Fq 'javascripts/instant-navigation.js?v=20260724-content-only-2' "${ROOT}/mkdocs.yml"
TMP_ROOT="$(mktemp -d /mnt/workspace/ai-infra-wiki-layout-test.XXXXXX)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

mkdir -p "${TMP_ROOT}/assets/javascripts" "${TMP_ROOT}/content/docs" "${TMP_ROOT}/scripts"
cp "${ROOT}/scripts/prepare_content.sh" "${TMP_ROOT}/scripts/prepare_content.sh"
cp -R "${ROOT}/assets/javascripts/." "${TMP_ROOT}/assets/javascripts/"
printf '# Fixture\n' > "${TMP_ROOT}/content/docs/index.md"

(cd "${TMP_ROOT}" && bash scripts/prepare_content.sh content)
CSS="${TMP_ROOT}/docs/stylesheets/extra.css"

grep -Fq '@media screen and (min-width: 76.25em)' "${CSS}"
grep -Fq '.md-grid {' "${CSS}"
grep -Fq 'max-width: none;' "${CSS}"
grep -Fq '.md-header__button[for="__drawer"] {' "${CSS}"
grep -Fq 'display: inline-block;' "${CSS}"
grep -Fq '[dir="ltr"] .md-sidebar--primary {' "${CSS}"
grep -Fq 'left: -12.1rem;' "${CSS}"
grep -Fq 'width: 12.1rem;' "${CSS}"
grep -Fq 'height: 100%;' "${CSS}"
grep -Fq 'top: 0 !important;' "${CSS}"
grep -Fq 'bottom: 0 !important;' "${CSS}"
grep -Fq 'height: 100% !important;' "${CSS}"
grep -Fq 'box-shadow: none;' "${CSS}"
grep -Fq 'margin-bottom: 0;' "${CSS}"
grep -Fq '.md-sidebar--secondary:not([hidden]) {' "${CSS}"
grep -Fq 'grid-template-rows: none;' "${CSS}"
grep -Fq 'visibility: visible;' "${CSS}"
grep -Fq 'position: fixed;' "${CSS}"
grep -Fq 'transform: translateX(12.1rem);' "${CSS}"
grep -Fq '[data-md-toggle="drawer"]:checked ~ .md-header {' "${CSS}"
grep -Fq '[data-md-toggle="drawer"]:checked ~ .md-container .md-main {' "${CSS}"
grep -Fq '[data-md-toggle="drawer"]:checked ~ .md-container .md-footer {' "${CSS}"
grep -Fq '[data-md-toggle="drawer"]:checked ~ .md-overlay {' "${CSS}"
grep -Fq 'pointer-events: none;' "${CSS}"
grep -Fq '.md-drawer-pin {' "${CSS}"
grep -Fq 'html.md-drawer-navigation-lock .md-header {' "${CSS}"
grep -Fq 'transform: translateX(12.1rem);' "${CSS}"
grep -Fq '.md-nav__toggle ~ .md-nav {' "${CSS}"
grep -Fq 'transform: translateX(100%);' "${CSS}"
if grep -Fq 'width: max-content;' "${CSS}" || grep -Fq '.md-nav--primary:hover' "${CSS}"; then
  echo "desktop-only hover drawer rules must be removed" >&2
  exit 1
fi
grep -Fq '@media screen and (max-width: 76.2344em)' "${CSS}"
grep -Fq 'padding-left: calc(1rem + env(safe-area-inset-left));' "${CSS}"

JS="${TMP_ROOT}/docs/javascripts/desktop-drawer.js"
test -f "${JS}"
grep -Fq 'llm-infra-wiki:desktop-drawer-pinned' "${JS}"
grep -Fq 'document$.subscribe' "${JS}"
grep -Fq 'aria-pressed' "${JS}"

NAV_JS="${TMP_ROOT}/docs/javascripts/instant-navigation.js"
test -f "${NAV_JS}"
grep -Fq 'DOMParser' "${NAV_JS}"
grep -Fq 'md-sidebar--primary' "${NAV_JS}"
grep -Fq 'currentContent.replaceWith(nextContent)' "${NAV_JS}"

echo "desktop layout CSS contract: PASS"
