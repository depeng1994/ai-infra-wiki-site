#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTENT_ROOT="${1:-${SITE_ROOT}/content-repo}"

if [[ ! -d "${CONTENT_ROOT}" ]]; then
  echo "Content repository not found: ${CONTENT_ROOT}" >&2
  exit 1
fi

if [[ ! -d "${CONTENT_ROOT}/docs" ]]; then
  echo "Content repository must contain a docs/ directory: ${CONTENT_ROOT}" >&2
  exit 1
fi

rm -rf "${SITE_ROOT}/docs"
mkdir -p "${SITE_ROOT}/docs"
cp -R "${CONTENT_ROOT}/docs/." "${SITE_ROOT}/docs/"

# Keep shared binary/static assets available under the published site.
if [[ -d "${CONTENT_ROOT}/assets" ]]; then
  rm -rf "${SITE_ROOT}/docs/assets"
  cp -R "${CONTENT_ROOT}/assets" "${SITE_ROOT}/docs/assets"
fi

# Make example scripts browsable/downloadable from the generated site.
if [[ -d "${CONTENT_ROOT}/examples" ]]; then
  rm -rf "${SITE_ROOT}/docs/examples"
  mkdir -p "${SITE_ROOT}/docs/examples"
  cp -R "${CONTENT_ROOT}/examples/." "${SITE_ROOT}/docs/examples/"
fi


mkdir -p "${SITE_ROOT}/docs/stylesheets"
cat > "${SITE_ROOT}/docs/stylesheets/extra.css" <<'CSS_EOF'
/* Mobile-first reading improvements for long technical notes. */
:root {
  --md-text-font-size: 0.95rem;
}

.md-typeset {
  line-height: 1.8;
}

.md-typeset h1,
.md-typeset h2,
.md-typeset h3 {
  font-weight: 700;
}

.md-typeset code {
  word-break: break-word;
}

.md-typeset pre > code {
  white-space: pre;
}

.md-typeset table:not([class]) {
  display: block;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

.md-typeset .mermaid {
  text-align: center;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

@media screen and (max-width: 76.2344em) {
  .md-content__inner {
    margin-left: 0;
    margin-right: 0;
    padding-left: calc(1rem + env(safe-area-inset-left));
    padding-right: calc(1rem + env(safe-area-inset-right));
  }

  .md-typeset h1 {
    font-size: 1.65rem;
  }

  .md-typeset h2 {
    font-size: 1.25rem;
  }
}

@media screen and (max-width: 44.9844em) {
  .md-content__inner {
    padding-left: calc(1.15rem + env(safe-area-inset-left));
    padding-right: calc(1.15rem + env(safe-area-inset-right));
  }
}


/* Keep the wide desktop reading area, but use Material's mobile drawer model. */
@media screen and (min-width: 76.25em) {
  .md-grid {
    max-width: none;
  }

  .md-main__inner {
    width: 100%;
  }

  .md-content {
    min-width: 0;
  }

  .md-content__inner {
    max-width: none;
    margin-right: 1.25rem;
    margin-left: 1.25rem;
  }

  .md-header__button[for="__drawer"] {
    display: inline-block;
  }

  .md-header__button.md-logo,
  .md-header__source {
    display: none;
  }

  .md-header,
  .md-main,
  .md-footer {
    transition: margin-left 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      margin-right 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  }

  [data-md-toggle="drawer"]:checked ~ .md-header {
    margin-left: 12.1rem;
    width: calc(100% - 12.1rem);
  }

  [data-md-toggle="drawer"]:checked ~ .md-container .md-main {
    margin-left: 12.1rem;
    width: calc(100% - 12.1rem);
  }

  [data-md-toggle="drawer"]:checked ~ .md-container .md-footer {
    margin-left: 12.1rem;
    width: calc(100% - 12.1rem);
  }

  [dir="rtl"] [data-md-toggle="drawer"]:checked ~ .md-header,
  [dir="rtl"] [data-md-toggle="drawer"]:checked ~ .md-container .md-main,
  [dir="rtl"] [data-md-toggle="drawer"]:checked ~ .md-container .md-footer {
    margin-right: 12.1rem;
    margin-left: 0;
  }

  html.md-drawer-navigation-lock .md-header {
    margin-left: 12.1rem !important;
    width: calc(100% - 12.1rem) !important;
  }

  html.md-drawer-navigation-lock .md-container .md-main,
  html.md-drawer-navigation-lock .md-container .md-footer {
    margin-left: 12.1rem !important;
    width: calc(100% - 12.1rem) !important;
  }

  html[dir="rtl"].md-drawer-navigation-lock .md-header,
  html[dir="rtl"].md-drawer-navigation-lock .md-container .md-main,
  html[dir="rtl"].md-drawer-navigation-lock .md-container .md-footer {
    margin-right: 12.1rem !important;
    margin-left: 0 !important;
  }

  html.md-drawer-navigation-lock .md-sidebar--primary {
    box-shadow: var(--md-shadow-z3);
    transform: translateX(12.1rem) !important;
  }

  .md-drawer-pin {
    position: absolute;
    top: 0.55rem;
    right: 0.55rem;
    z-index: 3;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-height: 1.8rem;
    padding: 0.15rem 0.45rem;
    border: 0.05rem solid transparent;
    border-radius: 0.2rem;
    color: var(--md-default-fg-color--light);
    font: inherit;
    font-size: 0.7rem;
    line-height: 1.2;
    background: transparent;
    cursor: pointer;
  }

  .md-drawer-pin:hover,
  .md-drawer-pin:focus-visible {
    border-color: currentcolor;
    color: var(--md-accent-fg-color);
    outline: none;
  }

  [dir="rtl"] .md-drawer-pin {
    right: auto;
    left: 0.55rem;
  }

  .md-sidebar--secondary:not([hidden]) {
    display: none;
  }

  [dir="ltr"] .md-sidebar--primary {
    left: -12.1rem;
  }

  [dir="rtl"] .md-sidebar--primary {
    right: -12.1rem;
  }

  .md-sidebar--primary {
    position: fixed;
    z-index: 5;
    /* Material's sticky-sidebar script writes inline top/bottom offsets on desktop. */
    top: 0 !important;
    display: block;
    width: 12.1rem;
    height: 100%;
    bottom: 0 !important;
    background-color: var(--md-default-bg-color);
    transform: translateX(0);
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.25s;
  }

  [data-md-toggle="drawer"]:checked ~ .md-container .md-sidebar--primary {
    box-shadow: var(--md-shadow-z3);
    transform: translateX(12.1rem);
  }

  [dir="rtl"] [data-md-toggle="drawer"]:checked ~ .md-container .md-sidebar--primary {
    transform: translateX(-12.1rem);
  }

  .md-sidebar--primary .md-sidebar__scrollwrap {
    position: absolute;
    top: 0;
    right: 0;
    bottom: 0;
    left: 0;
    margin: 0;
    height: 100% !important;
    overflow: hidden;
    scroll-snap-type: none;
  }

  .md-nav--primary,
  .md-nav--primary .md-nav {
    position: absolute;
    z-index: 1;
    top: 0;
    right: 0;
    left: 0;
    display: flex;
    flex-direction: column;
    height: 100%;
    background-color: var(--md-default-bg-color);
  }

  .md-nav--primary .md-nav__item,
  .md-nav--primary .md-nav__title {
    font-size: 0.8rem;
    line-height: 1.5;
  }

  .md-nav--primary .md-nav__title {
    position: relative;
    height: 5.6rem;
    padding: 3rem 0.8rem 0.2rem;
    color: var(--md-default-fg-color--light);
    line-height: 2.4rem;
    white-space: nowrap;
    background-color: var(--md-default-fg-color--lightest);
    cursor: pointer;
  }

  /* Neutralize desktop-only sticky-nav cosmetics so the drawer matches mobile. */
  .md-nav--primary,
  .md-nav--primary .md-nav {
    margin-bottom: 0;
  }

  .md-nav--primary .md-nav__title {
    top: auto;
    z-index: auto;
    box-shadow: none;
  }

  .md-nav--primary .md-nav__list {
    padding-bottom: 0;
    padding-left: 0;
  }

  [dir="ltr"] .md-nav--primary .md-nav__item > .md-nav__link {
    margin-right: 0;
  }

  [dir="rtl"] .md-nav--primary .md-nav__item > .md-nav__link {
    margin-left: 0;
  }

  .md-nav__item--nested > .md-nav > .md-nav__title {
    display: block;
  }

  .md-nav--primary .md-nav__icon {
    border-radius: 0;
    transition: none;
  }

  .md-nav--primary .md-nav__icon:hover {
    background-color: transparent;
  }

  [dir="ltr"] .md-nav--primary .md-nav__title .md-nav__icon {
    left: 0.4rem;
  }

  [dir="rtl"] .md-nav--primary .md-nav__title .md-nav__icon {
    right: 0.4rem;
  }

  .md-nav--primary .md-nav__title .md-nav__icon {
    position: absolute;
    top: 0.4rem;
    display: block;
    width: 1.2rem;
    height: 1.2rem;
    margin: 0.2rem;
  }

  .md-nav--primary .md-nav__title .md-nav__icon::after {
    display: block;
    width: 100%;
    height: 100%;
    background-color: currentcolor;
    content: "";
    mask-image: var(--md-nav-icon--prev);
    mask-position: center;
    mask-repeat: no-repeat;
    mask-size: contain;
  }

  .md-nav--primary .md-nav__title ~ .md-nav__list {
    overflow-y: auto;
    touch-action: pan-y;
    background-color: var(--md-default-bg-color);
    box-shadow: 0 0.05rem 0 var(--md-default-fg-color--lightest) inset;
    scroll-snap-type: y mandatory;
  }

  .md-nav--primary .md-nav__title ~ .md-nav__list > :first-child {
    border-top: 0;
  }

  .md-nav--primary .md-nav__title[for="__drawer"] {
    color: var(--md-primary-bg-color);
    font-weight: 700;
    background-color: var(--md-primary-fg-color);
  }

  .md-nav--primary .md-nav__title .md-logo {
    position: absolute;
    top: 0.2rem;
    right: 0.2rem;
    left: 0.2rem;
    display: block;
    margin: 0.2rem;
    padding: 0.4rem;
  }

  .md-nav__source {
    display: block;
    padding: 0 0.2rem;
    color: var(--md-primary-bg-color);
    background-color: var(--md-primary-fg-color--dark);
  }

  .md-nav--primary .md-nav__list {
    flex: 1;
  }

  .md-nav--primary .md-nav__item {
    border-top: 0.05rem solid var(--md-default-fg-color--lightest);
  }

  .md-nav--primary .md-nav__item--active > .md-nav__link {
    color: var(--md-typeset-a-color);
  }

  .md-nav--primary .md-nav__item--active > .md-nav__link:is(:focus, :hover) {
    color: var(--md-accent-fg-color);
  }

  .md-nav--primary .md-nav__link {
    margin-top: 0;
    padding: 0.6rem 0.8rem;
  }

  .md-nav--primary .md-nav__link svg {
    margin-top: 0.1em;
  }

  .md-nav--primary .md-nav__link > .md-nav__link {
    padding: 0;
  }

  [dir="ltr"] .md-nav--primary .md-nav__link .md-nav__icon {
    margin-right: -0.2rem;
  }

  [dir="rtl"] .md-nav--primary .md-nav__link .md-nav__icon {
    margin-left: -0.2rem;
  }

  .md-nav--primary .md-nav__link .md-nav__icon {
    width: 1.2rem;
    height: 1.2rem;
    font-size: 1.2rem;
  }

  .md-nav--primary .md-nav__link .md-nav__icon::after {
    display: block;
    width: 100%;
    height: 100%;
    background-color: currentcolor;
    content: "";
    mask-image: var(--md-nav-icon--next);
    mask-position: center;
    mask-repeat: no-repeat;
    mask-size: contain;
  }

  [dir="rtl"] .md-nav--primary .md-nav__icon::after {
    transform: scale(-1);
  }

  .md-nav--primary .md-nav--secondary .md-nav,
  .md-nav--secondary {
    position: static;
    background-color: initial;
  }

  .md-nav--primary .md-nav__link[for="__toc"] {
    display: flex;
  }

  .md-nav--primary .md-nav__link[for="__toc"] .md-icon::after {
    content: "";
  }

  .md-nav--primary .md-nav__link[for="__toc"] + .md-nav__link {
    display: none;
  }

  .md-nav--primary .md-nav__link[for="__toc"] ~ .md-nav {
    display: flex;
  }

  [dir="ltr"] .md-nav--primary .md-nav--secondary .md-nav .md-nav__link {
    padding-left: 1.4rem;
  }

  [dir="rtl"] .md-nav--primary .md-nav--secondary .md-nav .md-nav__link {
    padding-right: 1.4rem;
  }

  [dir="ltr"] .md-nav--primary .md-nav--secondary .md-nav .md-nav .md-nav__link {
    padding-left: 2rem;
  }

  [dir="rtl"] .md-nav--primary .md-nav--secondary .md-nav .md-nav .md-nav__link {
    padding-right: 2rem;
  }

  .md-nav__toggle ~ .md-nav {
    display: flex;
    grid-template-rows: none;
    visibility: visible;
    opacity: 0;
    transform: translateX(100%);
    transition: transform 0.25s cubic-bezier(0.8, 0, 0.6, 1), opacity 125ms 50ms;
  }

  [dir="rtl"] .md-nav__toggle ~ .md-nav {
    transform: translateX(-100%);
  }

  .md-nav__toggle:checked ~ .md-nav {
    opacity: 1;
    transform: translateX(0);
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), opacity 125ms 125ms;
  }

  .md-nav__toggle:checked ~ .md-nav > .md-nav__list {
    backface-visibility: hidden;
  }

  .md-overlay {
    position: fixed;
    z-index: 5;
    top: 0;
    width: 0;
    height: 0;
    background-color: rgba(0, 0, 0, 0.54);
    opacity: 0;
    transition: width 0ms 0.25s, height 0ms 0.25s, opacity 0.25s;
  }

  [data-md-toggle="drawer"]:checked ~ .md-overlay {
    width: 0;
    height: 0;
    opacity: 0;
    pointer-events: none;
    transition: width 0ms 0.25s, height 0ms 0.25s, opacity 0.25s;
  }
}

/* Keep long MathJax display equations readable on mobile. */
.md-typeset .arithmatex {
  overflow-x: auto;
  overflow-y: hidden;
  -webkit-overflow-scrolling: touch;
}

.md-typeset mjx-container[jax="CHTML"][display="true"] {
  overflow-x: auto;
  overflow-y: hidden;
  max-width: 100%;
  padding: 0.25rem 0;
}
CSS_EOF


# Keep site-owned JavaScript vendors available after docs/ is regenerated.
if [[ -d "${SITE_ROOT}/assets/javascripts" ]]; then
  mkdir -p "${SITE_ROOT}/docs/assets/javascripts"
  cp -R "${SITE_ROOT}/assets/javascripts/." "${SITE_ROOT}/docs/assets/javascripts/"
fi

mkdir -p "${SITE_ROOT}/docs/javascripts"

cat > "${SITE_ROOT}/docs/javascripts/mermaid.js" <<'JS_EOF'
const getMermaidTheme = () => {
  const scheme = document.body.getAttribute("data-md-color-scheme");
  return scheme === "slate" ? "dark" : "default";
};

const renderMermaid = async () => {
  if (!window.mermaid) {
    return;
  }

  mermaid.initialize({
    startOnLoad: false,
    theme: getMermaidTheme(),
    securityLevel: "loose"
  });

  const nodes = [];
  document.querySelectorAll("pre.mermaid, .mermaid").forEach((node) => {
    if (node.querySelector("svg") || node.getAttribute("data-processed") === "true") {
      return;
    }

    if (node.tagName.toLowerCase() === "pre") {
      const code = node.querySelector("code");
      const replacement = document.createElement("pre");
      replacement.className = node.className;
      replacement.textContent = code ? code.textContent.trim() : node.textContent.trim();
      node.replaceWith(replacement);
      nodes.push(replacement);
    } else {
      nodes.push(node);
    }
  });

  if (!nodes.length) {
    return;
  }

  try {
    await mermaid.run({ nodes });
  } catch (error) {
    console.error("Mermaid render failed", error);
  }
};

document$.subscribe(() => {
  renderMermaid();
});

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", renderMermaid, { once: true });
} else {
  renderMermaid();
}

(() => {
  const palette = document.querySelector("[data-md-component=palette]");
  if (palette) {
    palette.addEventListener("change", () => {
      location.reload();
    });
  }
})();
JS_EOF

cat > "${SITE_ROOT}/docs/javascripts/mathjax.js" <<'JS_EOF'
window.MathJax = {
  tex: {
    inlineMath: [["\\(", "\\)"], ["$", "$"]],
    displayMath: [["\\[", "\\]"], ["$$", "$$"]],
    processEscapes: true,
    processEnvironments: true
  },
  options: {
    ignoreHtmlClass: ".*|",
    processHtmlClass: "arithmatex"
  }
};

document$.subscribe(() => {
  if (!window.MathJax || !MathJax.typesetPromise) {
    return;
  }

  MathJax.startup.output.clearCache();
  MathJax.typesetClear();
  MathJax.texReset();
  MathJax.typesetPromise();
});
JS_EOF

cat > "${SITE_ROOT}/docs/javascripts/desktop-drawer.js" <<'JS_EOF'
(() => {
  const STORAGE_KEY = "llm-infra-wiki:desktop-drawer-pinned";
  const DESKTOP_QUERY = "(min-width: 76.25em)";

  const isDesktop = () => window.matchMedia(DESKTOP_QUERY).matches;

  const readPinned = () => {
    try {
      return window.localStorage.getItem(STORAGE_KEY) === "true";
    } catch (error) {
      return false;
    }
  };

  const writePinned = (pinned) => {
    try {
      if (pinned) {
        window.localStorage.setItem(STORAGE_KEY, "true");
      } else {
        window.localStorage.removeItem(STORAGE_KEY);
      }
    } catch (error) {
      // A blocked storage area must not disable the drawer itself.
    }
  };

  const getDrawer = () => document.querySelector("#__drawer");

  const updateButton = (button, pinned) => {
    button.setAttribute("aria-pressed", String(pinned));
    button.setAttribute("aria-label", pinned ? "取消固定侧边导航" : "固定侧边导航");
    button.textContent = pinned ? "已固定" : "固定";
  };

  const syncDrawer = () => {
    const drawer = getDrawer();
    if (!drawer) {
      return;
    }

    const pinned = readPinned();
    if (pinned && !drawer.checked) {
      drawer.checked = pinned;
      drawer.dispatchEvent(new Event("change", { bubbles: true }));
    }

    document.querySelectorAll("button.md-drawer-pin").forEach((button) => {
      updateButton(button, pinned);
    });
  };

  const installDrawerGuard = () => {
    const drawer = getDrawer();
    if (!drawer || drawer.dataset.desktopDrawerGuard === "true") {
      return;
    }

    drawer.dataset.desktopDrawerGuard = "true";
    drawer.addEventListener("change", () => {
      if (isDesktop() && readPinned() && !drawer.checked) {
        drawer.checked = true;
      }

      document.querySelectorAll("button.md-drawer-pin").forEach((button) => {
        updateButton(button, readPinned());
      });
    });
  };

  const installPinButton = () => {
    if (!isDesktop()) {
      const drawer = getDrawer();
      if (drawer && drawer.checked) {
        drawer.checked = false;
        drawer.dispatchEvent(new Event("change", { bubbles: true }));
      }
      document.querySelectorAll("button.md-drawer-pin").forEach((button) => button.remove());
      return;
    }

    const nav = document.querySelector(".md-nav--primary");
    if (!nav) {
      return;
    }

    let button = nav.querySelector("button.md-drawer-pin");
    if (!button) {
      button = document.createElement("button");
      button.className = "md-drawer-pin";
      button.type = "button";
      button.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        const pinned = !readPinned();
        writePinned(pinned);
        if (!pinned) {
          const drawer = getDrawer();
          if (drawer && drawer.checked) {
            drawer.checked = false;
            drawer.dispatchEvent(new Event("change", { bubbles: true }));
          }
        }
        syncDrawer();
      });
      nav.prepend(button);
    }

    updateButton(button, readPinned());
    installDrawerGuard();
    syncDrawer();
  };

  const render = () => {
    installPinButton();
  };

  const mediaQuery = window.matchMedia(DESKTOP_QUERY);
  if (mediaQuery.addEventListener) {
    mediaQuery.addEventListener("change", render);
  } else {
    mediaQuery.addListener(render);
  }

  if (window.document$ && typeof document$.subscribe === "function") {
    document$.subscribe(render);
  } else {
    document.addEventListener("DOMContentLoaded", render, { once: true });
  }

  render();
})();
JS_EOF

cat > "${SITE_ROOT}/docs/javascripts/instant-navigation.js" <<'JS_EOF'
(() => {
  let navigating = false;
  let pendingNavigation = null;
  let preserveDrawerOpenUntil = 0;

  const pathOf = (url) => `${url.pathname}${url.search}`.replace(/\/$/, "") || "/";

  const isInternalPageLink = (event, link) => {
    if (!link || link.target || link.hasAttribute("download")) {
      return false;
    }
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return false;
    }

    const url = new URL(link.href, window.location.href);
    return url.origin === window.location.origin && pathOf(url) !== pathOf(new URL(window.location.href));
  };

  const updatePrimaryNavigation = (url) => {
    const primary = document.querySelector(".md-sidebar--primary");
    if (!primary) {
      return;
    }

    const targetPath = pathOf(url);
    const primaryNav = primary.querySelector(".md-nav--primary");
    primary.querySelectorAll(".md-nav__item--active").forEach((item) => {
      item.classList.remove("md-nav__item--active");
    });
    primary.querySelectorAll("input.md-nav__toggle").forEach((toggle) => {
      toggle.checked = false;
      const childNav = toggle.parentElement.querySelector(":scope > nav.md-nav");
      if (childNav) {
        childNav.setAttribute("aria-expanded", "false");
      }
    });
    primary.querySelectorAll("a.md-nav__link").forEach((link) => {
      const linkUrl = new URL(link.href, window.location.href);
      const active = !linkUrl.hash && pathOf(linkUrl) === targetPath;
      link.classList.toggle("md-nav__link--active", active);
      const item = link.closest(".md-nav__item");
      if (item) {
        item.classList.toggle("md-nav__item--active", active);
      }
      if (active) {
        link.setAttribute("aria-current", "page");
        let branchNav = link.closest("nav.md-nav");
        while (branchNav && branchNav !== primaryNav) {
          const branch = branchNav.closest(".md-nav__item--nested");
          if (!branch) {
            break;
          }
          branch.classList.add("md-nav__item--active");
          const toggle = branch.querySelector(":scope > input.md-nav__toggle");
          const childNav = branch.querySelector(":scope > nav.md-nav");
          if (toggle) {
            toggle.checked = true;
          }
          if (childNav) {
            childNav.setAttribute("aria-expanded", "true");
          }
          branchNav = branch.parentElement.closest("nav.md-nav");
        }
      } else {
        link.removeAttribute("aria-current");
      }
    });
  };

  const replaceRightPane = (nextDocument) => {
    const currentContent = document.querySelector(".md-content");
    const nextContent = nextDocument.querySelector(".md-content");
    if (!currentContent || !nextContent) {
      throw new Error("instant navigation content target is missing");
    }
    currentContent.replaceWith(nextContent);

    const currentSecondary = document.querySelector(".md-sidebar--secondary");
    const nextSecondary = nextDocument.querySelector(".md-sidebar--secondary");
    if (currentSecondary && nextSecondary) {
      currentSecondary.replaceWith(nextSecondary);
    }

    const currentFooter = document.querySelector(".md-footer");
    const nextFooter = nextDocument.querySelector(".md-footer");
    if (currentFooter && nextFooter) {
      currentFooter.replaceWith(nextFooter);
    }
  };

  const navigate = async (url, pushState) => {
    if (navigating) {
      pendingNavigation = { url, pushState };
      return;
    }
    navigating = true;
    const drawer = document.querySelector("#__drawer");
    const preservedPrimary = document.querySelector(".md-sidebar--primary");
    const drawerWasOpen = window.matchMedia("(min-width: 76.25em)").matches
      && Boolean(drawer && drawer.checked);
    const primaryObserver = preservedPrimary ? new MutationObserver(() => {
      const currentPrimary = document.querySelector(".md-sidebar--primary");
      if (currentPrimary && currentPrimary !== preservedPrimary) {
        currentPrimary.replaceWith(preservedPrimary);
      }
    }) : null;
    if (primaryObserver) {
      primaryObserver.observe(document.body, { childList: true, subtree: true });
      window.setTimeout(() => primaryObserver.disconnect(), 2000);
    }
    preserveDrawerOpenUntil = drawerWasOpen ? Date.now() + 2000 : 0;
    if (drawerWasOpen) {
      document.documentElement.classList.add("md-drawer-navigation-lock");
    }
    try {
      const response = await fetch(url.href, { headers: { Accept: "text/html" } });
      if (!response.ok) {
        throw new Error(`instant navigation request failed: ${response.status}`);
      }
      const nextDocument = new DOMParser().parseFromString(await response.text(), "text/html");
      replaceRightPane(nextDocument);
      document.title = nextDocument.title;
      updatePrimaryNavigation(url);
      window.scrollTo(0, 0);
      if (window.document$ && typeof document$.next === "function") {
        document$.next(document);
      }
      const currentPrimary = document.querySelector(".md-sidebar--primary");
      if (preservedPrimary && currentPrimary && currentPrimary !== preservedPrimary) {
        currentPrimary.replaceWith(preservedPrimary);
      }
      if (pushState) {
        window.history.pushState({}, "", url.href);
      }
      if (drawerWasOpen) {
        const restoreDrawer = window.setInterval(() => {
          const currentDrawer = document.querySelector("#__drawer");
          if (currentDrawer && !currentDrawer.checked) {
            currentDrawer.checked = true;
          }
        }, 25);
        window.setTimeout(() => {
          const currentDrawer = document.querySelector("#__drawer");
          if (currentDrawer && !currentDrawer.checked) {
            currentDrawer.checked = true;
          }
          window.clearInterval(restoreDrawer);
          document.documentElement.classList.remove("md-drawer-navigation-lock");
        }, 1500);
      }
      window.setTimeout(() => {
        preserveDrawerOpenUntil = 0;
      }, 2000);
    } catch (error) {
      window.location.href = url.href;
    } finally {
      navigating = false;
      if (pendingNavigation) {
        const pending = pendingNavigation;
        pendingNavigation = null;
        navigate(pending.url, pending.pushState);
      }
    }
  };

  document.addEventListener("click", (event) => {
    if (Date.now() < preserveDrawerOpenUntil && event.target === document.querySelector("#__drawer")) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }
    if (!(event.target instanceof Element)) {
      return;
    }
    const link = event.target.closest("a");
    if (!isInternalPageLink(event, link)) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    navigate(new URL(link.href, window.location.href), true);
  }, true);

  document.addEventListener("change", (event) => {
    const drawer = document.querySelector("#__drawer");
    if (Date.now() < preserveDrawerOpenUntil && event.target === drawer && !drawer.checked) {
      drawer.checked = true;
      event.stopImmediatePropagation();
    }
  }, true);

  window.addEventListener("popstate", (event) => {
    event.stopImmediatePropagation();
    navigate(new URL(window.location.href), false);
  }, true);
})();
JS_EOF

# Ensure MkDocs has a homepage even if the content repo has not added one yet.
if [[ ! -f "${SITE_ROOT}/docs/index.md" ]]; then
  cat > "${SITE_ROOT}/docs/index.md" <<'INDEX_EOF'
# LLM Infra Wiki

一个从 first principles 出发的大模型系统与框架知识库。

## 推荐学习路径

1. [Running Examples](./00-running-example/index.md)
2. [Compute & Memory](./01-compute-memory/index.md)
3. [Distributed Training](./02-distributed-training/index.md)
4. [PyTorch Native](./03-pytorch-native/index.md)
5. [Long Context](./04-long-context/index.md)
6. [RLHF Systems](./05-rlhf-systems/index.md)
7. [Inference Serving](./06-inference-serving/index.md)
8. [Profiling & Debugging](./07-profiling-debugging/index.md)
9. [Case Studies](./08-case-studies/index.md)
10. [Data & Training Engineering](./09-data-training-engineering/index.md)
11. [Kernels & Operators](./10-kernels-operators/index.md)
12. [MoE Systems](./11-moe-systems/index.md)
13. [Attention Architectures](./13-attention-architectures/index.md)

## 快速入口

- [Roadmap](./00-roadmap.md)
- [Glossary](./glossary.md)
- [References](./references.md)
INDEX_EOF
fi
