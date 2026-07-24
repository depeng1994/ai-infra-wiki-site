#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTENT_ROOT="${1:-${SITE_ROOT}/../ai-infra-wiki}"
PYTHON="${SITE_ROOT}/.venv/bin/python"

if [[ ! -x "${PYTHON}" ]]; then
  echo "Repository virtualenv not found: ${PYTHON}" >&2
  exit 1
fi

"${SCRIPT_DIR}/prepare_content.sh" "${CONTENT_ROOT}"
"${PYTHON}" "${SCRIPT_DIR}/check_nav_consistency.py" \
  --site-root "${SITE_ROOT}" --docs-root "${SITE_ROOT}/docs"
"${PYTHON}" -m mkdocs build --clean --config-file "${SITE_ROOT}/mkdocs.yml"
