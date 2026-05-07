#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTENT_ROOT="${1:-${SITE_ROOT}/../ai-infra-wiki}"

"${SCRIPT_DIR}/prepare_content.sh" "${CONTENT_ROOT}"
cd "${SITE_ROOT}"
mkdocs serve
