# 风险分级路由表（risk-tiers）

> SPEC-20 的规则来源 · 宪法 C12 的执行表 · v1 2026-07-31
> **本文件自身列为高风险路径**——改门禁规则须人审（防"改规则绕规则"）。
> 用法：`e2e-review` 按改动文件路径匹配下表 glob，取**命中的最高档**决定评审强度。

## 分档规则

| 档 | 匹配路径（glob） | 为什么高/低 | 评审强度 | 人审 |
|---|---|---|---|---|
| **高** | `docs/constitution.md`<br/>`docs/process/risk-tiers.md`<br/>`docs/process/skills-manifest.md`<br/>`docs/architecture/adr/**`<br/>`quality-baseline.txt`<br/>`.github/workflows/**`<br/>`.github/CODEOWNERS`<br/>`.claude/settings.json`<br/>`.claude/hooks/**`<br/>`scripts/lib/**` | 改的是**规则本身或门禁本身**——错了会让后续所有检查失效（"改规则绕规则"是最危险的路径）；CI/CODEOWNERS/settings/hooks 是权限与执行边界 | reviewer + security 双 agent + **异构评审**（跨模型，宪法 C12）+ 辩论矩阵留痕 | **强制**，且 approver≠author（C14） |
| **中** | `.claude/skills/**`<br/>`scripts/**`<br/>`bin/**`<br/>`tests/**`<br/>`src/**` `lib/**` `app/**`（业务代码默认档） | 可执行代码，错了有真实后果，但有测试与探针兜底 | reviewer 单 agent + 可执行验证必过 | 建议（CI 绿可自动合并，除非 finding 有 block） |
| **低** | `docs/**`（除上列高风险项）<br/>`specs/**`<br/>`*.md` 文档类<br/>`.gitignore` `README*` | 文字与制品记录，错了改起来便宜，且探针已覆盖结构 | 仅 CI 探针（结构/链接/拼写） | 否 |

**匹配优先级**：命中多档时取**最高档**（如同一 PR 既改 `docs/architecture/adr/` 又改 `README.md` → 按高风险处理）。

## 升档触发（动态，覆盖静态路径规则）

以下情况**自动升一档**，与路径无关：

1. **门禁打回 ≥2 次**的制品（宪法 C12）——反复打回=风险信号
2. finding 中出现 `severity=block` 且分类为 `security`
3. **规模触发**（调研 v2 修订，标为**默认启发值非实证安全线**）：
   - 净改动 **>400 行** → 升档；**>1000 行** → 默认要求拆分（[Google 官方口径](https://google.github.io/eng-practices/review/developer/small-cls.html)：100 行合理、1000 行过大，比 2006 年的 SmartBear 200-400 更严且更新）
   - **文件分散度独立计**：>15 个文件即升档，即便总行数不大（Google："200 行散在 50 个文件通常就太大"）
   - **计数算法**（v1 缺失，必须明确）：只计 additions + deletions 的**非生成、非 lockfile、非 vendored** 文件；排除清单维护于本文件 §计数排除
4. 改动涉及**新增外部依赖**或第三方 Action（宪法 C15 供应链）
5. **删除测试** / 跨公共 API 变更 / 标记为 AI 生成且无人类逐行确认

## 计数排除（规模触发的分母定义）

以下路径不计入规模统计：`*.lock` `*-lock.json` `*.sum` `vendor/**` `dist/**` `*.min.*` `**/generated/**` `*.svg` `*.png`

## 阈值的演进方式（调研 v2 新增）

本表用**显式路径 glob + 事件规则**，这是**没有风险模型与事故标签时的正确做法**。
[Meta RADAR](https://arxiv.org/html/2605.30208v1) 的百分位阈值（P25→P50 渐进标定）属**成熟级能力**——需要已校准的风险模型、大量事故标签、单调性验证与漂移监控；且其 revert 率 1/3、事故率 1/50 是**观察性比较，论文明确非因果估计**。本平台在积累足够事故标签前**不采用百分位**。

## 降档禁止

- 任何情况下**不得**把高风险路径降档处理；确需例外须记 ADR 并由人批准
- `--force`/`--no-verify` 类绕过操作在高风险路径上一律视为违规（宪法 C3）

---

## 执行层：分档如何在 GitHub 上真生效（S6 spike 实测，ADR-014）

上表是**判据**，本节是**执行机制**。判据写在文档里没有强制力——分档必须落到服务端才算数（宪法 C3）。

### 三条通路（各自的强制力不同）

| 分档 | 服务端机制 | 强制力 | 谁能绕过 |
|---|---|---|---|
| **高** | `CODEOWNERS` + `require_code_owner_reviews: true` | 服务端硬拦，PR 不合规无法合并 | 无人（前提：`enforce_admins: true`） |
| **中** | required status checks（CI 四检查） | 服务端硬拦 | 无人（同上） |
| **低** | 同上 CI 检查，但无人审要求 | 服务端硬拦（仅结构类） | 无人 |
| 升档触发 | `e2e-review` 计算后打 label + 在 PR 正文写明档位 | **无强制力**（label 可人工改） | 任何有写权限的人 |

**必须诚实的一点**：升档触发（§升档触发 1-5 条）**目前只有建议力**。GitHub 没有"按 diff 规模自动提高必审人数"的原生能力，label 也不能作为 required check 的输入。要让它有强制力，需要一个 CI job 自行计算档位并在不达标时 exit 非零——这条列入 backlog，**在实现前手册不得声称"规模超限会被自动拦下"**。

### CODEOWNERS 的前置条件（否则形同虚设）

1. `enforce_admins: true` —— 否则 admin 直推绕过一切（ADR-014 陷阱②，实测证伪过）
2. `require_code_owner_reviews: true` —— 光有 CODEOWNERS 文件**不产生任何强制力**，它只决定"自动请谁来审"
3. **仓库人数 ≥2** —— 单人仓里 owner 就是作者，GitHub 不允许自批，PR 会永久阻塞（ADR-014 陷阱③）

故单人仓（试点/demo）的正确配置是：**放 CODEOWNERS 文件**（作为路径→责任人的声明，供未来扩员即时生效），但 `require_code_owner_reviews` 保持 `false`，并在 PR 记录中写明"单人仓，高风险人审由异构评审留痕代行"。

### 验证方式

`bash scripts/check-branch-protection.sh` —— **行为证明探针**：实际尝试直推受保护分支，必须收到 `protected branch hook declined`。不接受"配置回读一致"作为通过依据（理由见 ADR-014）。
