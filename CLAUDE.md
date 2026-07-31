# 项目上下文（Claude Code 常驻规则）

> 本文件 ≤200 行（SPEC-11）。深知识放 skills 按需加载，工程原则见宪法。

@docs/constitution.md

## 本项目

- 生命周期：六段治理底图 × 产物状态机（见 docs/process/stages/）
- 制品位置：`specs/<feature>/`（prfaq→prd→spec/plan→tasks）
- 门禁：⓪立项 ①需求 ②架构 ③合并 ④发布 ⑤退役
- 能力：`.claude/skills/e2e-*`（拓扑见 docs/process/skills-manifest.md）

## 纪律

- 未过门禁不进下一段（skill 第 0 步自校验）
- 每条任务带可执行验证方式；能验证的绝不用"我觉得对了"
- 探针在 `scripts/` 与各 skill 的 `scripts/`，交付前必须跑
