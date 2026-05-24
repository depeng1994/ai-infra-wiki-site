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

  const nodes = document.querySelectorAll(".mermaid");
  if (!nodes.length) {
    return;
  }

  await mermaid.run({ nodes });
};

document$.subscribe(() => {
  renderMermaid();
});

const palette = document.querySelector("[data-md-component=palette]");
if (palette) {
  palette.addEventListener("change", () => {
    location.reload();
  });
}
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
