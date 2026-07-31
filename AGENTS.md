# AGENTS.md — 工具无关的 agent 入口

本仓库采用六段端到端生命周期 + 产物状态机，制品在 `specs/<feature>/`。

## 快速上手
- 前置检查：`e2e doctor`
- 结构自审：`bash scripts/check-structure.sh`（若存在）
- 阶段定义：`docs/process/stages/`
- 工程宪法：`docs/constitution.md`（不可妥协原则）

## 约定
- 产物是真相（`docs/` `specs/`），`.claude/` 只是 Claude 适配层
- 门禁记录在各制品尾部；试点模式下为流程留痕，非防伪审批证据
