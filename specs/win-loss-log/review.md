# REVIEW：win-loss-log（门禁③ 评审材料）

> 阶段 4 产物 · 门禁③（合并批准）· 2026-07-31 · 模板见 docs/process/stages/stage-4-review.md
> 上游：tasks.md（阶段3 出口 19/19 复杂度点，`check-tasks.sh` 绿 @2026-07-31）
> 状态：**待批** → 批准后进阶段 5（发布）
> 对应 PR：[Albertsun6/aisep729-demo#1](https://github.com/Albertsun6/aisep729-demo/pull/1)

## 定档结论

- **风险档**：**高**
- **依据**：命中 `risk-tiers.md` §分档规则 两条高档 glob
  - `.github/CODEOWNERS` —— 决定"谁必须审"，改它即改门禁规则
  - `docs/process/risk-tiers.md` —— 分档表自身（防"改规则绕规则"）
- **动态升档**：⚠️ **已触发两条**（净改动 847 > 400；文件数 19 > 15）。本 PR 原已是高档，无更高档可升；触发事实见 §规模统计
- **评审强度**：reviewer + security 双 agent + **异构评审**（跨模型，宪法 C12）

## 规模统计

| 项 | 值 | 阈值 | 判定 |
|---|---|---|---|
| 净改动行数（排除 png/lock/vendored/generated） | 847（+661/−186） | >400 升档 / >1000 拆分 | ⚠️ **触发升档**（>400） |
| 文件数（同上排除） | 19（含图片 20） | >15 升档 | ⚠️ **触发升档**（>15） |

> 修复三方 findings 后，改动集从 5 文件 / 290 行扩大到 **19 文件 / 847 行**，
> **同时触发 §升档触发 #3 的两条规模阈值**。本 PR 已是最高档（高），无更高档可升——
> 但按 fail-closed 纪律**必须如实记录触发事实**，不得因"反正已是最高档"而略过。
> 若本 PR 原为中档，此处应强制升为高档。
>
> 同时须记：`>1000 行默认要求拆分` 尚未触及，但已接近。若后续再有修复轮次，
> 应拆成「探针修复」与「分档表修订」两个 PR，而不是继续堆在同一个里。

## 覆盖声明（fail-closed，不得省略）

- **已审**：`.github/CODEOWNERS`、`docs/process/risk-tiers.md`、`ops/check-branch-protection.sh`、`scripts/check-skill-deps.sh`、`scripts/check-clause-refs.sh`、`docs/constitution.md`、`.github/workflows/quality-gates.yml`、`.gitignore`、7 个 `SKILL.md`、`tests/probe-negative/run.sh`、`specs/win-loss-log/tasks.md`
- **未审及原因**：
  - `docs/demo-dark-mobile.png` —— 二进制截图，无逻辑；已人工目视确认为深色+窄屏渲染结果
  - **Safari 行为（ADR-003 未验项）** —— 见下 §T-7，**当前不得声称跨浏览器可用**
  - **完整历史 secret scan** —— 仓已公开但只做了当前内容扫描，未扫历史。转门禁④
  - **LICENSE** —— 公开仓无许可证，使用权不清。转门禁④

## 通道① 确定性检查（唯一 blocker 来源，先于任何 LLM 评审执行）

| 探针 | 结果 |
|---|---|
| `scripts/check-single-file.sh` | ✅ 0（SPEC-10/11/12，182/400 行） |
| `tests/logic.test.sh` | ✅ 0（33 断言全通过） |
| `scripts/check-structure.sh` | ✅ 0 |
| `scripts/check-selfcontained.sh` | ✅ 0 |
| `scripts/check-shell-traps.sh` | ✅ 0 |
| `tests/probe-negative/run.sh` | ✅ 0 |
| `tests/probe-negative/ratchet-negative.sh` | ✅ 0 |
| `check-tasks.sh specs/win-loss-log/` | ✅ 0 |
| `scripts/check-skill-deps.sh` | ✅ 0（**本次新增**） |
| `scripts/check-branch-protection.sh` | ✅ 0（**本次新增**，行为证明） |

**通道① blocker 数：0**

CI 外环（PR #1，run 30602400358）四 job 全 `pass`：`process-gates` / `probe-negatives` / `product-contract` / `logic-contract`。

## T-7 浏览器人工 checklist

### Chrome（file:// 实测，2026-07-31）

| # | 检查项 | 结果 |
|---|---|---|
| C1 | 双击即用：三层（LOGIC/STORE/UI）全部加载 | ✅ |
| C2 | 三屏切换正常，且任一时刻只有一屏可见 | ✅ |
| C3 | 非法金额全拒（`12.5`/`1e3`/`0x10`/`+12`/`" 12 "`/`abc`/空） | ✅ |
| C3b | 上限拦截（`1000000001` 拒）、合法通过（`500`/`-300`） | ✅ |
| C4 | 缺日期拦截并提示"请选日期" | ✅ |
| C5 | 存储读写正确（`[500,-300]`），**他人键 `gambleTrackerV1` 未被触碰**（SPEC-3b） | ✅ |
| C6 | 汇总数字正确（净额 `+200`，共 2 笔） | ✅ |
| C7 | 隐私声明可见（含"不上传"） | ✅ |
| C8 | 深色模式生效（bg `rgb(28,25,23)` / fg `rgb(245,245,244)`） | ✅ |
| C9 | 窄屏 390px 无横向溢出（scrollWidth == clientWidth == 390） | ✅ |
| C10 | 触控目标高度 41.7px（≥ 40px 可点区） | ✅ |
| C11 | Console 无 error / warn | ✅ 零条 |

截图留痕：`docs/demo-screenshot.png`（浅色桌面）、`docs/demo-dark-mobile.png`（深色 390×844）

### Safari —— **未验证**（诚实记录，不得含混）

- **状态**：**未跑**。尝试用 `osascript` 自动化被系统授权对话框阻断（Safari 的"允许 Apple 事件中的 JavaScript"默认关闭），非交互会话无法通过。
- **处置**：按 ADR-003 原定路径转入**门禁④ 人工 checklist**，由人在 Safari 里逐条跑 C1–C11。
- **约束**：在该项完成前，**任何文档、手册、演示材料均不得声称"跨浏览器可用"**。ADR-003 已记载 Safari 对 `file://` 存储更严格，存在 localStorage 被拒的真实可能。
- **若不成立时的处置**（预先写死，防事后找补）：Safari 若拒绝 `file://` 的 localStorage，则 `save()` 返回 `false`，UI 走已实现的"⚠️ 本次数据未能保存"分支——**功能降级但不静默丢数据**；届时在 prfaq FAQ 与手册"已知限制"补记 Safari 不可用。

## Findings

> source：`deterministic`（通道①，**唯一 blocker 来源**）/ `llm-advisory`（通道③，建议）/ `llm-triage`（通道②，对①的分诊建议）
> 状态机：`open → fixed | false-positive | accepted-risk → reopened`

| ID | severity | source | 类型 | 定位 | 问题 | 状态 | 闭环证据 |
|---|---|---|---|---|---|---|---|
| F-1 | block | deterministic | contract | `bin/e2e`（平台仓）拷贝清单 | `e2e-review` 第1步定档依赖 `docs/process/risk-tiers.md`，但 init/adopt 都不发它 → 业务仓定档无数据源 → **静默按低风险处理，不跑 LLM/异构评审（fail-open）** | fixed | 加入 init/adopt 清单；新建 `check-skill-deps.sh` 守整类；干净目录 `e2e init` 实测已发出该文件且探针 PASS |
| F-2 | block | deterministic | correctness | `scripts/ratchet.sh:41`（旧版） | `fp=$(… \| md5 -q \| cut)` 的退出码取自 `cut`，`md5` 缺失时 `cut` 仍退 0 输出空串 → `\|\| md5sum` 兜底**永不触发** → 指纹静默变空 → 同 rule+file 的违规全部塌缩成一条，ratchet 漏报 | fixed | 改为 `command -v` 显式探测 + 空指纹即 exit 66（fail-closed）；`ratchet-negative.sh` 全绿，demo 仓五场景实测通过 |
| F-3 | block | deterministic | correctness | `.github`（分支保护配置） | `enforce_admins` 默认 `false` → 分支保护对 admin 不生效。配置回读四项 checks 全在、GitHub 打印 `4 of 4 required status checks are expected`，**直推 main 仍成功** | fixed | 置 `enforce_admins=true`；`check-branch-protection.sh` 行为证明 → `protected branch hook declined` |
| F-4 | block | deterministic | correctness | ADR-014 初稿「决定」第 3 条 | 该 ADR 自己开的方子（单人仓 `approvals=0` + `require_last_push_approval=true`）**会让 PR 永久 BLOCKED**——该开关不看 approvals 数值，独立要求"非推送者批准" | fixed | A/B 对照锁定单一变量（false→`CLEAN` / true→`BLOCKED`）；ADR-014 加陷阱④ 并修正分级表；PR #1 现为 `CLEAN` |
| F-5 | minor | deterministic | maintainability | `scripts/check-shell-traps.sh` | macOS 无 `timeout`/`realpath`/`md5sum` 等 GNU 命令，缺失时若外层吞退出码即"静默通过"——本会话已因 `timeout` 缺失导致一次异构评审静默失败 | fixed | 新增陷阱3 检测 + `# shell-traps:ok` 显式豁免机制；正负样本双向验证 |

### 通道②③ findings（三方评审：reviewer agent · security agent · cursor-agent 异构）

> 三方**独立**运行，互不可见彼此输出。F-6/F-9/F-13 被三方各自独立指出，F-7/F-11 被两方指出。
>
> **通道归属的判据（本仓被自己的探针纠正过一次）**：
> `source` 记的是**阻断权从哪来**，不是"谁最先看见"。
> LLM 指出一个问题 ≠ LLM 有权阻断合并——这正是三通道契约要防的（调研 v2 的核心设计缺陷）。
> 初版把 8 条 LLM finding 标成 `block`，被 `check-review.sh` 当场拒绝：
> `MISSING: 8 条 block 级 finding 来自 llm-advisory 通道——违反三通道契约(LLM 无阻断权)`。
>
> 正确处置**不是改标签，而是补测试**（宪法 C2 + 原则⑤"把评审者给的反例加进测试"）：
> 凡能写成**对旧实现会失败**的可执行断言的，authority 就来自那条测试 → `deterministic`；
> 写不出可执行断言的，诚实记为 `llm-advisory`，**不得**占用阻断权。
> `提出方` 列保留 LLM 的贡献归属——advisory 不等于不重要，只等于不能强制阻断。

#### 通道① 补录：由 LLM 线索转化而来的确定性阻断

> 每条都有一个**对旧实现失败、对新实现通过**的可执行断言。空回归（新旧都通过）不算数。

| ID | severity | source | 提出方 | 类型 | 定位 | 问题 | 状态 | 可证伪断言（对旧实现的结果） |
|---|---|---|---|---|---|---|---|---|
| F-6 | block | deterministic | llm-advisory ×3 | security | `check-branch-protection.sh`（旧版 :79） | `git commit --allow-empty` **不是空提交**——它提交当前 index。① 门禁失效时把开发者暂存的机密**推进公开仓的 main**；② 即便推送被拒，cleanup 的删分支操作在**成功路径上也会静默销毁**那份暂存工作 | fixed | 负样本 `BP 不碰索引/分支/工作区`。**对旧实现实测：索引 `[secret.txt]→[]`、`secret.txt` 被销毁 → 断言失败**。另证：`git show <probe>:secret.txt` 输出 `STAGED-SECRET`，机密确实进了"空"提交 |
| F-9 | block | deterministic | llm-advisory ×3 | correctness | `check-skill-deps.sh`（旧版） | 这个"防 fail-open"的探针自己有 4 条真空 PASS 路径：无 skills 目录 / 目录为空 / 无 SKILL.md / 零引用，全部 exit 0；`ROOT` 默认 `.` 使仓内子目录被判成"非 e2e 仓" | fixed | 4 条负样本 `SD/66 ×4`。**对旧实现全部 exit 0（期望 66）→ 断言失败** |
| F-10 | block | deterministic | llm-advisory ×2 | correctness | 同上（旧版 :70） | 抽取正则要求**整个反引号内容就是一条路径**，漏掉最主流的"反引号包整条命令"写法 | fixed | 负样本 `SD/1 命令内引用的缺失依赖必须被抓到`。**对旧实现输出"已检查 0 条引用 / PASS"，exit 0 → 断言失败** |
| F-11 | block | deterministic | llm-advisory ×2 | correctness | 同上（旧版 :25-31 vs :70） | 金丝雀用的正则**与生产抽取器不是同一条**，只验证了"一条没人用的正则能工作"；生产正则退化时它照样绿 | fixed | 负样本 `SD/66 生产正则被改坏时金丝雀必须报警`：把 `PATH_RE` 替换成永不匹配的串后必须 exit 66。**旧版金丝雀用独立正则，改坏生产正则后不会报警 → 断言失败** |
| F-16 | block | deterministic | llm-advisory ×2 | contract | demo 仓 `docs/constitution.md` | **条款层 fail-open**：本仓宪法只定义 C1-C5，全仓却引用 C6-C15——其中 C12/C13/C14 正是整套门禁的规范依据。agent 被指示"按 C14 检查"，读到没有 C14 的文件后**不报错，按无约束继续** | fixed | 新增 `check-clause-refs.sh` + 3 条负样本。**对本仓修复前实测 exit 1，列出悬空的 C6-C15 → 断言失败** |

#### 通道③ llm-advisory（**无阻断权**；已修，但阻断权不来自它们）

> 这些**写不出对旧实现会失败的可执行断言**——它们是设计判断、措辞与权限边界问题。
> 按契约只能是 advisory。我作为执行者选择修，人类门禁裁决时已知悉。
> **advisory ≠ 不重要**：F-13/F-17 的严重度不低于上表任何一条，只是无法机器证伪。

| ID | severity | source | 类型 | 定位 | 问题 | 状态 | 处置证据 |
|---|---|---|---|---|---|---|---|
| F-7 | major | llm-advisory ×2 | correctness | `check-branch-protection.sh`（旧版 :94） | 输出"服务端拒绝了直推**（含 admin）**"，但"含 admin"从未被证明——非 admin 用户/`GITHUB_TOKEN` 直推受保护分支本来就会被拒。而这正是 ADR-014 的全部要害 | fixed | 推送前查 `.permissions.admin`；非 true 时文案降级为"仅覆盖普通写权限路径" |
| F-8 | major | llm-advisory | correctness | 同上（旧版 :17,36 vs :82） | confused deputy：被审计的仓与被推送的仓解耦，可能"读 A 仓配置、往 B 仓推"。fork 工作流下必然踩中 | fixed | 删掉 `owner/repo` 参数（无跨仓用例），仓库固定取当前 origin |
| F-12 | major | llm-advisory ×2 | test-gap | `tests/probe-negative/run.sh`、CI | 新增两个探针零可执行验证：不在任何 CI job 里，也无负样本。"一条没人跑、无人证伪的探针，等于文档里的一句话" | fixed | 负样本 34 → **48**；两个新探针接进两仓 CI。`check-branch-protection` 因会写远端**不进 PR 触发的 CI**，其非触网部分已有 4 条负样本 |
| F-13 | major | llm-advisory ×3 | security | `risk-tiers.md` 分档表 | **"改门禁绕门禁"路径没堵死**：① `.claude/agents/reviewer.md` 只命中"`*.md` 文档"→ 低档 = 无人审，改成"永远无 finding"即可关掉整套内环；② `scripts/check-*.sh` 是四个 required check 的执行体却只算中档，改 `exit 0` 后 required check 变成真空绿；③ `docs/process/stages/**`（SOP 权威定义）→ 低档；④ `bin/e2e` 一次改动污染所有新客户仓 | fixed | 高档 glob 重写并前置**判据**（"凡定义门禁或被 required check 执行的 = 高档"），使清单可推导而非死记；补入 `ops/**`、`.claude/agents/**`、`tests/probe-negative/**`、`bin/**`、`.claude/settings*.json`。**遗留**：分档表覆盖度本身无探针，见 §backlog |
| F-14 | major | llm-advisory ×2 | contract | 同上 | **无 catch-all 默认档**，零命中行为未定义 → 实现者会默认低档。实测落空的真实路径：`index.html`（**整个产品**）、`.claude/settings.local.json`（且本仓无 `.gitignore`）、`.github/dependabot.yml` | fixed | 加默认档（`*` → 中档）+ 零命中 fail-closed 语义（必须单独列清单）；两仓补 `.gitignore` |
| F-15 | major | llm-advisory | contract | 同上 §执行层 | 用**现在时**声称高档"服务端硬拦、无人能绕过"，而线上实测 `approvals=0` → 作者可自合。正文别处纠正了，但被引用的是表 | fixed | 表加「**当前试点仓状态（实测）**」列，高档行标 🔴 未启用 |
| F-17 | major | llm-advisory | security | `.claude/settings.json` allow 规则 | 白名单有 `Bash(bash scripts/*)`。本 PR 把一个**向远端受保护分支写**的脚本放进了这条已授权的通配前缀 → agent 可无提示、带任意参数调用。叠加 F-6：无人值守会话可把暂存内容发到远端 main | fixed | 探针移出通配区 → `ops/`（不在 allow 列表，需逐次确认）；`ops/**` 同时列入高风险档 |
| F-20 | warn | llm-advisory | maintainability | `check-branch-protection.sh` | 退出码契约冲突：抬头声明 `1=REFUTED`，但 `die` 一律 exit 1 → 网络抖动被播报成"门禁失效"，会让人去改一个没坏的东西 | fixed | 基础设施类失败改 exit 2，**1 只留给"真的推上去了"** |

### 未采纳/部分采纳（fail-closed：不采纳必须写明理由）

| 意见 | 立场 | 理由 |
|---|---|---|
| 异构 #1：行为证明不能作为唯一通过依据，应与配置不变量取**交集** | **accept** | 完全成立。旧版只证明了"一个无 check 的新 SHA 推不上去"，并不证明"必须走 PR、必须有人审"。已改为两层合取：配置不变量 ∩ 行为证明，任一不过即 exit 2 |
| 异构 #5：不得声称"结构性守住整类 fail-open" | **accept** | 改为"**显式路径引用**的静态存在性检查"，并在脚本抬头列出**抓不到的 12 种形态**（markdown 链接/花括号展开/变量拼接/传递依赖/外部工具依赖/条款号…）。对外表述同步收窄 |
| 异构 #7：CODEOWNERS 的 `* @Albertsun6` 兜底使分档失效；企业客户复制后 owner 无效 | **partial** | 「当前零强制力」已在 CODEOWNERS 正文与 risk-tiers「当前状态」列双处标注。但"企业客户复制后 owner 名无效"确实未解决——**列入 M4 手册的接入检查项**，本轮不改（单人试点仓改了也无法验证） |
| 异构 #8：为免费分支保护把仓改公开，代价被低估（无 LICENSE、无完整历史 secret scan） | **partial** | 公开前已做内容扫描（无密钥/无绝对路径/无个人数据），并已向用户明示 commit 邮箱会公开。**未做**完整历史 secret scan、**未加 LICENSE**——两项列入门禁④ 发布前检查，本记录明确标为**未完成** |
| reviewer #10 / security #16：双基准解析（skill 目录 OR 仓根）残留 fail-open | **accept** | 已消除 OR：7 个 SKILL.md 全部规范化为显式仓根路径（原先 4 个写裸 `scripts/check-*.sh`，**从仓根跑必然失败**），探针改为单一基准，`templates/` 是唯一保留的 skill 私有前缀 |
| security #17：第三方 Action 未 SHA-pin | **open** | 成立但不在本 PR 范围（workflow 未改）。当前只用 `actions/checkout`（GitHub 一方）。列入 backlog，**在实现前手册不得声称"供应链已钉版"** |

### 非终态说明（false-positive / accepted-risk 必填）

| ID | 状态 | 签署人（**必须是人类，非 agent**） | 理由 | 到期日 | 跟踪票据 |
|---|---|---|---|---|---|
| — | — | — | 本轮无 false-positive / accepted-risk 条目；未采纳项见上表，均标注为 partial/open 而非"误报" | — | — |

> 安全 critical **禁止** accepted-risk。

## 异构评审（高风险档强制，宪法 C12）

外部 lens：cursor-agent（gpt 族），独立运行，输出 236 行。

| 意见 | 立场 | 论据 |
|---|---|---|
| 行为探针可在"评审门禁完全没开"时返回成功 | accept | 见 F-7；改为配置不变量 ∩ 行为证明 |
| 探针会推走暂存内容并破坏本地状态 | accept | 见 F-6；我方实测复现后改用 `commit-tree` |
| 依赖探针可"一个 skill 都没扫"仍返回成功 | accept | 见 F-9；四条真空路径全改 66 |
| 反引号正则覆盖太窄，"守住整类"名不副实 | accept | 见 F-10 + 能力边界声明 |
| risk tier 是说明文字，不是可执行路由 | **partial** | 三个"危险但落不进高风险 glob"的例子全部成立 → F-13 已补。但"`check-review.sh` 只信 review.md 自填档位"这条**未修**：把高风险改动手填成低档，探针发现不了。**列入 backlog**，且手册不得声称"分档会被自动强制" |
| 承认 CODEOWNERS 无强制力 ≠ 消除误导 | partial | 见上表 |
| 公开仓的信息风险被低估 | partial | 见上表 |

**三方收敛度**：F-6 / F-9 / F-13 被 reviewer + security + 异构**三方各自独立**指出；
F-7 / F-10 / F-11 / F-12 / F-14 被两方指出。单一 lens 会漏掉其中任意一条。

## 环境留痕（防非确定性绕过）

- 评审时 diff hash：`c5ffd5645e6cf343`｜HEAD：`e08ba89`（修复后已变，见 PR 最新 commit）
- 三方评审各运行 1 次，**均未重跑**（禁止重跑到过）
- 通道① 先于通道②③ 执行：是（9/9 探针绿后才启动 LLM 评审）
- 修复后通道① 复跑：demo 10/10 绿、平台 6/6 绿、负样本 **45/45**（原 34）

## C14 归因声明（单人仓的诚实交代）

本仓为**单人仓**（owner = author）。按 ADR-014 分级：`approvals=0`、`require_last_push_approval=false`
（开则永久死锁）、`require_code_owner_reviews=false`（单人仓 owner 即作者，GitHub 不允许自批）。

因此：**本 PR 没有第二个人类批准，C14「执行者不得自批」在服务端层面不成立**。
把关实际由 ① CI 四检查 + ② 10 项本地探针 + ③ 跨模型异构评审留痕 承担。
`.github/CODEOWNERS` 已就位但**当前零强制力**，仅在扩员至 ≥2 人并开启
`require_code_owner_reviews` 后生效。手册与演示材料**不得**因存在该文件而声称"有人审"。

---
门禁③ 记录（批后"决定"填 批准/打回 之一；批准人须为人类且 ≠ 作者/最后 push 者）：
- 批准人：yongqian（**人类**，仓库 owner）
- 决定：批准
- 日期：2026-07-31
- 备注：**归因如实记录，不得美化**——本仓为单人仓，批准人与 commit 作者身份
  （`yongqian <albertsun6@gmail.com>`）为**同一 GitHub 账号**，故 C14 要求的
  "approver ≠ author"在**服务端层面不成立**，服务端也无第二人类的 review 事件。
  本次批准是**会话内的人类裁决**（过程留痕，ADR-009 试点模式），
  把关由 ① CI 四检查 ② 10 项本地探针 ③ 三方独立评审（reviewer / security / 跨模型异构）承担。
  裁决时已明确告知三项未完成项：Safari 未验证、无 LICENSE、未做完整历史 secret scan，
  以及 1 条 open finding（分档可手填绕过）。三项转门禁④。
