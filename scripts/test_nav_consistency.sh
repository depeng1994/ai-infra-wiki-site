#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d /mnt/workspace/ai-infra-wiki-nav-test.XXXXXX)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

mkdir -p "${TMP_ROOT}/docs/section"
cat > "${TMP_ROOT}/mkdocs.yml" <<'YAML'
site_name: Fixture
nav:
  - Section:
      - 总览: section/index.md
YAML
printf '# Section\n\n- [Topic](./topic.md)\n' > "${TMP_ROOT}/docs/section/index.md"
printf '# Topic\n' > "${TMP_ROOT}/docs/section/topic.md"

if "${ROOT}/.venv/bin/python" "${ROOT}/scripts/check_nav_consistency.py" \
  --site-root "${TMP_ROOT}" --docs-root "${TMP_ROOT}/docs" >"${TMP_ROOT}/output" 2>&1; then
  echo "nav consistency checker must reject an unlisted page" >&2
  exit 1
fi
grep -Fq 'section/topic.md' "${TMP_ROOT}/output"

cat > "${TMP_ROOT}/mkdocs.yml" <<'YAML'
site_name: Fixture
nav:
  - Section:
      - 总览: section/index.md
      - Topic: section/topic.md
YAML
"${ROOT}/.venv/bin/python" "${ROOT}/scripts/check_nav_consistency.py" \
  --site-root "${TMP_ROOT}" --docs-root "${TMP_ROOT}/docs"

cat > "${TMP_ROOT}/mkdocs.yml" <<'YAML'
site_name: Fixture
nav:
  - Section:
      - 总览: section/index.md
      - Second: section/second.md
      - First: section/first.md
YAML
printf '# First\n' > "${TMP_ROOT}/docs/section/first.md"
printf '# Second\n' > "${TMP_ROOT}/docs/section/second.md"
printf '# Section\n\n- [First](./first.md)\n- [Second](./second.md)\n' > "${TMP_ROOT}/docs/section/index.md"

if "${ROOT}/.venv/bin/python" "${ROOT}/scripts/check_nav_consistency.py" \
  --site-root "${TMP_ROOT}" --docs-root "${TMP_ROOT}/docs" >"${TMP_ROOT}/order-output" 2>&1; then
  echo "nav consistency checker must reject an order mismatch" >&2
  exit 1
fi
grep -Fq '顺序不一致' "${TMP_ROOT}/order-output"

echo "nav consistency checker: PASS"
