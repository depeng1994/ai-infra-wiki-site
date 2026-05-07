# AI Infra Wiki Site

This repository contains only the publishing/build system for the AI Infra Wiki.

- Content repository: `OWNER/ai-infra-wiki`
- Site repository: `OWNER/ai-infra-wiki-site`
- Static site generator: Material for MkDocs
- Deployment target: GitHub Pages

The content repository remains the source of truth for Markdown docs, assets, and examples.
This repository checks out the content repository in GitHub Actions, copies the publishable
content into `docs/`, builds the static site, and deploys it to GitHub Pages.

## Local preview

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
./scripts/prepare_content.sh ../ai-infra-wiki
mkdocs serve
```

If your local content checkout is still named `wiki-zdp`, run:

```bash
./scripts/prepare_content.sh ../wiki-zdp
mkdocs serve
```

## GitHub setup placeholders

Replace `OWNER` in these files after the GitHub account or organization name is known:

- `mkdocs.yml`
- `.github/workflows/deploy.yml`
- content repo `.github/workflows/trigger-site-deploy.yml`
