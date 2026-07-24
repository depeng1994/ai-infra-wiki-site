# AI Infra Wiki Site 贡献者 / Agent 总纲

## 项目边界

- 本仓库（`ai-infra-wiki-site`）只负责 MkDocs 发布配置、构建脚本和 GitHub Pages 产物。
- 原始 Markdown、图片和示例的唯一来源是 sibling 仓库 `../wiki-zdp`（部署时为 checkout 的 content repository）。
- `docs/` 和 `site/` 是构建过程中的复制/生成目录，均不应作为内容真相源提交。

## 导航一致性硬约束

新增、删除或重命名原始知识库页面时，必须同步检查 `mkdocs.yml` 的 `nav`：

1. 章节 `index.md` 中的相对 Markdown 链接必须指向存在的页面。
2. 所有可发布 Markdown 页面必须恰好有一个导航入口；计划/规格等内部文件要用 `exclude_docs` 排除。
3. 章节首页目录与导航的入口集合不能漂移；跨章节链接可以保留在其归属章节，同时在相关章节提供入口。

内容同步后，在本仓库 `.venv` 中运行：

```bash
./.venv/bin/python scripts/check_nav_consistency.py --site-root . --docs-root docs
./scripts/validate_site.sh ../wiki-zdp
```

发布前还应使用 `mkdocs build --strict --clean` 验证无孤立页面、无失效导航目标，并确认生成目录不包含 `superpowers/` 等内部资料。
