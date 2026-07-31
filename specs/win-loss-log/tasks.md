# TASKS：win-loss-log / 三步骨架

> 阶段 3 产物 · 2026-07-31
> 上游：spec.md（门禁② 批准 @2026-07-31）
> 度量：复杂度点（1/3/8）｜熔断信号：验证连续失败 3 次 / spike 超时间盒
> 格式：`- [ ] T-N 描述 ｜ SPEC-x ｜ 复杂度 N ｜ 依赖 T-y ｜ 验证：<命令/判据>`

## A 组：spike（时间盒，先行）

- [x] T-1 D1 抽块可测性：写出可跑的「抽 LAYER:LOGIC → 补 use strict → 求值 → 断言」最小样例，含"引用块外常量必须失败"负样本 ｜ SPEC-1/测试ABI ｜ 复杂度 3 ｜ 依赖 - ｜ 验证：`bash tests/logic.test.sh` 在样例上退出 0，且负样本用例确实红

## B 组：纵向骨架（端到端最小可用链路）

- [x] T-2 探针先行 `scripts/check-single-file.sh`：无外链 + `wc -l`≤400 + 分层三断言（标记各一次/独占一行/严格序，LOGIC 零 DOM，localStorage 仅 STORE） ｜ SPEC-10/11/12 ｜ 复杂度 3 ｜ 依赖 - ｜ 验证：对构造的坏样本（缺标记/UI 直连 localStorage/含外链）三类各退出非 0，对好样本退出 0
- [x] T-3 逻辑层实现（LAYER:LOGIC）：`validateAmount` 三条校验、`isRecordV1`、`sortRecords`、`netTotal`、`makeRecord`，块末 `return {...}` ｜ SPEC-1/4/5/7/9 ｜ 复杂度 3 ｜ 依赖 T-1 ｜ 验证：`bash tests/logic.test.sh` 全绿（含 `12.5`/`1e3`/`0x10`/`+12`/`" 12 "` 全拒、`-9007199254740993` 拒、`1000000001` 拒、`netTotal([300,-500,200])===0`）
- [x] T-4 存储层实现（LAYER:STORE）：`load/save` 接受注入 store、三级容错、只碰 `e2e.` 前缀键、localStorage 引用只在函数体内 ｜ SPEC-2/3/3b ｜ 复杂度 3 ｜ 依赖 T-3 ｜ 验证：`bash tests/logic.test.sh` 存储用例全绿（含解析失败不覆写、脏记录跳过计数、他人键 `gambleTrackerV1` 前后不变）
- [x] T-5 UI 层实现（LAYER:UI）：三屏 markup + 事件；date 用 `<input type="date" required>`；不直接碰 localStorage ｜ US-1/2/3 · SPEC-6/8 ｜ 复杂度 3 ｜ 依赖 T-4 ｜ 验证：`bash scripts/check-single-file.sh` 退出 0（分层守卫通过）

## C 组：增量（骨架之上）

- [ ] T-6 CI 四 job 真跑通 ｜ SPEC-10/11/12 · plan CI 契约 ｜ 复杂度 3 ｜ 依赖 T-5 ｜ 验证：`gh run list` 显示四个 job 全绿
- [ ] T-7 浏览器人工 checklist（Chrome + **Safari**，后者是 ADR-003 的未验项） ｜ NFR-1 · ADR-003 ｜ 复杂度 1 ｜ 依赖 T-5 ｜ 验证：逐条勾选记录写入 review.md，Safari 结果明确（成立/不成立各有处置）

## 进度与容量（复杂度点）

| 组 | 点数 | 已完成 | 状态 |
|---|---|---|---|
| A（spike） | 3 | 3 | ✅ 完成 |
| B（骨架） | 12 | 12 | ✅ 完成 |
| C（增量） | 4 | 0 | T-6/T-7 进行中 |
| **合计** | **19** | **15（79%）** | - |

> 熔断信号（非点数上限）：任务验证连续失败 3 次 / spike 超时间盒 → 按 prfaq 砍序（先砍汇总页只留数字）

## spike 结论

| spike | 结论 | 落点 |
|---|---|---|
| D1（T-1） | ✅ 抽块可测**成立**，但实测暴露两处：① 块末 `return` 在 `<script>` 顶层是语法错误 → 改用 `type="text/x-e2e-layer"` 承载源码 + bootstrap `new Function` 求值，**浏览器与 node 走完全相同加载路径**；② STORE 块曾引用 `window.__E2E_LOGIC` 违反自包含 → 改为 `load(store, isValid)` 注入校验函数（**这正是负样本要防的，它真抓到了**） | plan 风险表 · SPEC 测试 ABI |

## 砍线记录（熔断触发时填）

| 时间 | 触发原因 | 砍掉什么 | 依据 |
|---|---|---|---|
