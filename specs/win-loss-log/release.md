# RELEASE：win-loss-log（门禁④ 生产放行评审材料）

> 阶段 5 产物 · 门禁④（生产放行）· 2026-07-31 · 模板见 docs/process/stages/stage-5-release.md
> 上游：门禁③（**账本在服务端**，SPEC-2 对其豁免文本块）｜ 状态：**待放行**
> 本文件的门禁④记录=**流程留痕，非防伪审批证据**（ADR-009 试点模式；企业模式以服务端事件为准）

## 本次评审怎么做的（先说方法，再说结论）

PRR 五类核对项由 5 个独立 agent 并行取证，每条「已就绪」与「不适用」的断言
再交给独立 agent **尝试证伪**（默认怀疑，要求跑命令而非推理）。
**21 条断言里 16 条被证伪**——绝大多数不是"结论错"，而是**"证据不实"或"射程过宽"**：
把 partial 说成 ok、把"做起来麻烦"说成 N/A、引用了没跑过的命令输出。

这个比例本身是最值得记的一条：**单轮取证的自证倾向很强**，
没有对抗验证的话，这份 PRR 会带着 16 处美化过门禁。

## 门禁③ 入口证据（探针实测结果照抄，不许追认）

| 路径 | 怎么验的 | 实际证据 |
|---|---|---|
| 远程（权威） | `bash .claude/skills/e2e-release/scripts/check-release.sh specs/win-loss-log/ --gate-only` | `GATE3-IN: 远程路径 ✓（PR=MERGED｜checks=SUCCESS,SUCCESS,SUCCESS,SUCCESS）`｜PR #1｜mergeSha=`dd8d245252dd`｜mergedAt=2026-07-31T04:24:52Z |
| 本地（降级，gh 不可用时） | 目标分支 merge commit + 全量测试绿 | **未走**（远程路径可用） |

## PRR 核对表（生产就绪评审）

> 核对人**必须是可归因的人类**（宪法 C14）。下方 `<待人签>` 需人类逐项确认后填写。
> **本产品形态特殊**：单文件 HTML、file:// 打开、无服务端、无部署管线，
> 因此多项传统 PRR 条目**真的不适用**——但每条 N/A 都经过独立证伪，不是图省事。

### 容量与依赖

- [ ] PRR-1 依赖清单与配额已确认 ｜ 证据：**产品运行时零第三方依赖**——`git ls-files | wc -l` → 72 项，无 package.json/requirements.txt/go.mod/任何 lockfile/node_modules/.gitmodules；`grep -Eic "fetch\(|XMLHttpRequest|sendBeacon|WebSocket|EventSource|https?://" index.html` → **0**；`grep -oE '(src\|href\|action)="[^"]*"' index.html` → 零匹配。**但 CI 供应链非零**：`actions/checkout` 已由可变 tag `@v5` 改为 SHA-pin `@fbc6f39…`，并新增 `.github/dependabot.yml`（`package-ecosystem: github-actions`，该生态**不需要 manifest**——原判"无对象可扫 → N/A"被证伪，属 C15 违规，已修） ｜ 核对人：`<待人签>`
- [ ] PRR-2 容量估算与撞限行为 ｜ 证据：Chrome 二分探针实测 localStorage 配额 = **5 MiB（5,242,880 UTF-16 code unit）**，可证伪（写 10 字符成功 / 写 50 MB 抛 `QuotaExceededError`）。单条记录 ~86 字符，**独占前提下**约 56,000 条撞限。**关键限定（原断言遗漏，经证伪补入）**：该配额是 **origin 级**，而 ADR-003 已双浏览器实测确证 `file://` 下所有本地页共享同一 origin ——**这 5 MiB 不是本产品独占的**，同机其它本地页可能已占用大半。故"约 56,000 条"是**上界不是保证**。撞限行为：`save()` 的 `try/catch`（index.html:96）返回 `false`，UI 显示「⚠️ 本次数据未能保存（存储不可用）」（index.html:152）——**不静默丢数据** ｜ 核对人：`<待人签>`
- [ ] PRR-3 单文件行数预算 ｜ 证据：`bash scripts/check-single-file.sh` → `PASS`，`✅ SPEC-11：182/400 行`，`✅ SPEC-12①/②/③`（分层三断言）；CI `product-contract` job 每次 PR 必跑 ｜ 核对人：`<待人签>`

### 可观测

- [x] PRR-4 服务端指标 / 健康检查 / APM / 日志聚合 ｜ **N/A（不适用）** ｜ 证据：无服务端进程、无托管端点、无网络出口。`gh api repos/Albertsun6/aisep729-demo/pages` → **404**（Pages 未启用）；`.github/workflows/` 无任何 deploy step。不存在可抓取的指标、可探活的 endpoint、可聚合的日志流。（注：仓库**有** CI 质量门禁管线，但它守的是合并、不是运行时，**不构成产品可观测性**） ｜ 核对人：`<待人签>`
- [x] PRR-5 可用性 SLO / SLI ｜ **N/A —— 并显式豁免 stage-5 R5 的「SLO 表」硬要求** ｜ 证据：无请求、无错误率、无延迟分布、无 uptime；运营方对用户设备与浏览器**无任何控制力与观测通道**。强行定义 SLO 会让人误以为存在持续测量与告警接线，**危害大于收益**。本条 N/A 覆盖 R5 的「运行时 SLO」部分，**不覆盖** R5 的「可观测」全部（见 PRR-6） ｜ 核对人：`<待人签>`
- [ ] PRR-6 用户可见的故障信号 ｜ **partial（部分就绪，非 ok）** ｜ 证据：**成立部分**——Chrome 实测（patch `Storage.prototype.setItem` 抛 `QuotaExceededError`）：`#err` 显示「⚠️ 本次数据未能保存（存储不可用）」且元素确实可见；`store.set` 的 try/catch 覆盖全部**抛出型**失败（含 localStorage 属性访问即抛 `SecurityError`）。这是全产品**唯一到达用户眼前**的故障信号。**不成立部分（据此不能判 ok）**：① 仅 2 处 `console.warn`（index.html:127/128）在 **load 路径**，save 路径无；② 普通用户不会开 DevTools，`console.warn` 对他们等于不存在；③ 无 `addEventListener('storage')`，多标签页并发写会互相覆盖且无提示；④ 写入失败**不重试**。四项已写入 §未决风险 ｜ 核对人：`<待人签>`

### 失败与回滚

- [ ] PRR-7 故障模式与爆炸半径 ｜ 证据：爆炸半径 = **单个用户的单个浏览器**（无服务端、无共享状态、无多租户）。已识别 7 类故障并逐条写入 `docs/runbooks/win-loss-log.md` §故障处理，每条含可粘贴的首诊命令。最坏情况：用户本机数据不可读——**不影响任何他人** ｜ 核对人：`<待人签>`
- [ ] PRR-8 回滚命令可执行且**已演练** ｜ **gap（有已知缺口，非 ok）** ｜ 证据：**五次实跑演练**（clone 到 scratchpad 独立目录，非纸面推演）：<br/>**演练 A** `git revert <门禁③ merge dd8d245>` → **EXIT=0**，但**回滚的是流程文档不是产品**（`git log --oneline -- index.html` 显示 index.html 不在该 commit 内）<br/>**演练 C** `git revert 6ac4119`（唯一含 index.html 的提交）→ **EXIT=1，14 个文件冲突**（初始提交、空树父，后续提交改过这些文件）<br/>**关键事实**：`index.html` 全历史**只被提交过一次** → **本产品不存在"可回滚的上一版本"**<br/>**演练 D** 前滚修复 → EXIT=0，`check-single-file.sh` / `logic.test.sh` / `probe-negative/run.sh` **三道全绿** → **唯一可行路径**<br/>**演练 E** 已分发副本：仓库侧切回原版后，副本内容**不变** → 不可逆 ｜ 核对人：`<待人签>`
- [ ] PRR-9 不可逆点已标注 ｜ 证据：三个不可逆点已写入 runbook §回滚，均实测：① **已分发到用户手上的 index.html 副本**——仓库侧任何操作都改不了（最硬）；② **用户 localStorage 已写入的数据**不随版本回退，但不会崩（`isRecordV1` 跳过 + `console.warn`，index.html:127）；③ **公开仓历史**已可被 clone/fork/缓存/索引 ｜ 核对人：`<待人签>`

### 安全与合规

- [ ] PRR-10 密钥不入仓（宪法 C15） ｜ 证据：`gitleaks git --no-banner --redact` @ gitleaks 8.30.1 → **6 commits scanned / no leaks found / EXIT=0**（本仓）；平台仓 `AISEP729` → 16 commits / no leaks。另跑自建全 blob 扫描覆盖**已删除文件**：172 个历史对象，高置信密钥模式（sk-/ghp_/AKIA/PRIVATE KEY/xox/AIza）**0 命中**。<br/>**口径诚实说明**：这是**扫描结果干净**，不等于**前向控制**——仓库当前**没有** push protection 或 pre-commit secret hook，未来提交仍可能引入。已记入 §未决风险 ｜ 核对人：`<待人签>`
- [ ] PRR-11 许可与数据合规 ｜ 证据：**LICENSE = MIT**（用户裁决 2026-07-31，commit `4ebb397`）——此前公开仓无许可证，默认版权下他人**不得使用/修改/分发**，属真实阻断项，现已解除。数据合规：产品**不发送任何数据**（PRR-1 的 grep 证据），localStorage 数据不出本机。**但隐私边界须如实声明**：`file://` 下同机任意本地 HTML 页面**都能读到**本应用数据——Chrome 与 Safari **双浏览器实测确证**（ADR-003 + 其追加记录），不是某浏览器特例。产品内隐私声明（index.html:53）已无条件写明此点 ｜ 核对人：`<待人签>`
- [ ] PRR-12 XSS / 注入面 ｜ 证据：UI 层**全部用 `textContent`**，`grep -n "innerHTML" index.html` → **零匹配**。`textContent` 按文本赋值、不解析标记，故用户输入的 `<script>` 等只会被当字面文本显示。这消除了本产品的 DOM XSS 主面 ｜ 核对人：`<待人签>`
- [ ] PRR-13 零网络出口的**证据强度** ｜ **partial（现状干净，但门禁能力有边界）** ｜ 证据：**现状可断言**——独立宽口径复扫（含 `window.open` / `location.href|assign|replace` / `document.write` / `<iframe>` / `<link>` / `<form>` / `srcset` / `poster` / `url()`）**零命中**。**能力边界必须写明（勿夸大）**：`scripts/check-single-file.sh:17` 是**字面量黑名单式词法守卫**，防的是"误引入 CDN/外链"这类**无意事故**；它**不构成**对抗性的"零出口"证明——拼接构造（如 `window['fe'+'tch']`）可绕过。故对外只能说"无静态外部引用"，**不得**说"已证明不可能外发" ｜ 核对人：`<待人签>`

### 运维交接

- [ ] PRR-14 runbook 三节非空且可照做 ｜ 证据：`docs/runbooks/win-loss-log.md` 三节（启动/回滚/故障处理）全部非占位符；所有 Console 命令引用的标识符已核实真实存在（`window.__E2E_LOGIC` / `window.__E2E_STORE` / 键 `e2e.winLossLog.v1` / DOM id `rows`,`net`,`cnt`,`err`,`d`,`v`,`a`,`save`）；探针 `check-release.sh --final` 校验三节非空 ｜ 核对人：`<待人签>`
- [ ] PRR-15 运维事项与归属 ｜ 证据：本产品**无传统运维对象**（无进程、无端点、无 deploy step、Pages 未启用）。运维收敛为**四**件（原断言写三件，经证伪补入第四件）：① 新版本分发 ② 用户数据自助备份/恢复 ③ 仓库门禁与 CI 维护 ④ **依赖更新（Action SHA-pin + Dependabot）**。归属：`.github/CODEOWNERS` → `@Albertsun6`。<br/>⚠️ **该 owner 声明当前无服务端强制力**：`require_code_owner_reviews=false`、`required_approving_review_count=0`（见 `docs/process/risk-tiers.md` §执行层「当前状态」列）。写"角色"而非"找某人"的要求，在单人仓无法满足——如实记录 ｜ 核对人：`<待人签>`
- [ ] PRR-16 用户自助能力 ｜ **partial（备份可用，恢复有风险）** ｜ 证据：产品**无内置导出功能**（本次范围外）。runbook §故障处理第 5 条给出 Console 备份片段，Chrome 实测可落盘（400 字节 JSON，`json.load` 验证 VALID）。**恢复半程有已知风险**（经证伪发现）：直接 `setItem` 会**静默永久覆盖**现有数据，故 runbook 已改为**三步式**（先 `getItem` 看清楚 → 确认后再覆盖 → 刷新验证），并标注第②步为破坏性操作 ｜ 核对人：`<待人签>`

## 发布策略（部署 ≠ 发布）

**本产品无 feature flag、无金丝雀、无灰度**——这不是遗漏，是形态决定的：
用户拿到的是一个静态文件，运营方**无法**按比例控制谁拿到哪个版本。

| 项 | 值 |
|---|---|
| 发布动作 | 合并到 `main`（受保护，须过四个 required check） |
| 用户获取 | 主动 `git clone` 或 `curl` 单文件；**运营方不推送** |
| 放量控制 | **无**——无法按比例灰度 |
| 观察窗 | 无遥测，只能靠用户主动反馈（见「触发判据」） |

## 回滚预案

| 触发判据 | 回滚动作（可执行） | 预期 RTO | 不可逆点 |
|---|---|---|---|
| 用户报告功能异常 / 开发者跑 runbook §启动 健康检查发现异常（**无自动告警，见 PRR-5**） | **前滚修复**（唯一可行路径，演练 D 已实跑）：<br/>`git switch -c hotfix-x origin/main`<br/>改 `index.html`<br/>`bash scripts/check-single-file.sh && bash tests/logic.test.sh && bash tests/probe-negative/run.sh`<br/>`git commit -am "fix: x" && git push -u origin hotfix-x`<br/>`gh pr create --fill && gh pr checks --watch`<br/>`gh pr merge --squash --delete-branch` | **2–5 分钟**（条件性，非保证上界）<br/>实测分解：本地三道探针 ~3s；CI 四 job **11–20s**（`gh run list` 六次实测 13/20/15/11/16/13）；人工改码开 PR 数分钟 | ① **已分发副本**（演练 E 实测：仓库侧切回原版，副本内容不变）<br/>② 用户 localStorage 已写数据（不随版本回退，但不崩）<br/>③ 公开仓历史 |
| 需要撤下产品 | **无干净的 revert 路径**（演练 C：`git revert 6ac4119` → EXIT=1，14 冲突）。只能新提交删除 `index.html` 并在 README 标注退役 → 走阶段6（e2e-retire） | 同上 | 同上 + 已分发副本仍可用 |

### 回滚演练证据

- **回滚演练证据**：2026-07-31 实跑五次（A/C/D/E + RTO 计时），**非纸面推演**。
  环境：`git clone` 到独立 scratchpad 目录，三份互不干扰的 clone。
  结论：演练 C 证明「回滚到上一版」此路不通（EXIT=1，14 冲突）；
  演练 D 证明前滚修复是**唯一可行路径**且三道探针全绿；
  演练 E 证明已分发副本不可逆。完整输出见下方代码块。

演练环境：`git clone` 到独立 scratchpad 目录，三份独立 clone。

```
演练 A: git revert dd8d245           → EXIT=0   ✅ 能跑，但回滚的不是产品
演练 C: git revert 6ac4119           → EXIT=1   ❌ 14 个文件冲突，此路不通
        git log --oneline -- index.html → 仅 6ac4119 一条 → 无上一版本
演练 D: 前滚修复 → 提交 454964f
        check-single-file.sh  ✅
        tests/logic.test.sh   ✅
        probe-negative/run.sh ✅       → 唯一可行路径
演练 E: 副本 diff → 仓库回滚后副本内容不变 → 不可逆点确证
```

## SLO 与监控

| SLI | 目标 SLO | 错误预算 | 告警规则 | 指向 runbook 小节 |
|---|---|---|---|---|
| 服务端可用性 | **N/A —— 无服务端**（显式豁免 stage-5 R5，理由见 PRR-5） | N/A | **无**（不存在告警接线） | — |
| 本地契约不变量 | **100%**（`check-single-file.sh` + `logic.test.sh` 在每个 PR 上必须全绿，0 容忍） | 0 | CI `product-contract` / `logic-contract` job 失败即阻断合并 | §启动 → 健康检查判据 |
| CI 门禁时延 | **≤ 60 秒**（实测 11–20s，留 3× 余量） | — | 超时人工察觉（无自动告警） | §回滚 → 预期 RTO |

> ⚠️ **本表只有第 2、3 行是真的可测量指标，且测的是"合并门禁"不是"运行时"**。
> 任何文档、手册、演示材料**不得**声称本产品有运行时监控或告警。

## 未决风险与例外（人类签署到期日）

| # | 风险 | 为什么不在本次解决 | 到期日 | 签署人 |
|---|---|---|---|---|
| E-1 | **无用户可见的错误上报**：`console.warn` 仅在 load 路径且普通用户看不到 | 需要 UI 改动（在页面上显示"跳过 N 条"），超出本次单文件 400 行预算与范围 | 2026-09-30 | `<待人签>` |
| E-2 | **多标签页并发写会互相覆盖**：无 `addEventListener('storage')` | 单用户本地工具，并发概率低；修复需引入跨标签同步逻辑 | 2026-09-30 | `<待人签>` |
| E-3 | **写入失败不重试** | 重试对 QuotaExceeded 无意义；用户已收到明确提示 | 不修（接受） | `<待人签>` |
| E-4 | **无内置导出功能**，备份需手粘 Console 片段 | 已在 prfaq 明确列为 backlog 非本次范围 | 2026-09-30 | `<待人签>` |
| E-5 | **secret scan 无前向控制**：无 push protection / pre-commit hook | 需仓库设置变更；扫描结果当前干净 | 2026-08-31 | `<待人签>` |
| E-6 | **零出口只有词法证据**：`check-single-file.sh` 是字面量黑名单，拼接构造可绕过 | 对抗性证明需运行时网络捕获，成本远超本产品价值 | 不修（接受，但**不得夸大表述**） | `<待人签>` |
| E-7 | **分档可手填绕过**（门禁③ 遗留 open finding）：`check-review.sh` 只信 review.md 自填档位 | 需实现 diff→glob 匹配的 CI job | 2026-09-30 | `<待人签>` |
| E-8 | **配额与他人共享**：5 MiB 是 origin 级，同机其它本地页可占用 | `file://` 固有属性，无技术手段隔离（ADR-003 已论证 IndexedDB 也不行） | 不修（接受，已在 runbook 说明） | `<待人签>` |

## 观察窗与运营

- **观察窗**：无遥测，无法定义指标化观察窗。替代做法：放行后由 owner 在 Chrome 与 Safari 各跑一次 runbook §启动 的三条健康检查判据，结果回写本文件。
- **事故处理**：任何事故引出的改动走门禁⓪ 立项（宪法 C8 紧急通道：可先动手，48h 内补票）。

---
门禁④ 记录（批准人须为**人类**且 ≠ 发布执行者；本仓为单人仓，归因限制同门禁③）：
- 批准人：`<待人签>`
- 决定：`<待填>`
- 日期：`<待填>`
- 备注：`<待填>`
