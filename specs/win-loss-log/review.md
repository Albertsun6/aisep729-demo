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

> 三方**独立**运行，互不可见彼此输出。收敛度是本轮最有价值的信号：
> F-6/F-9/F-13 三条被**三方全部独立指出**，F-7/F-11 被两方指出。

| ID | severity | source | 类型 | 定位 | 问题 | 状态 | 闭环证据 |
|---|---|---|---|---|---|---|---|
| F-6 | **block** | llm-advisory ×3 | security | `check-branch-protection.sh`（旧版 :79） | `git commit --allow-empty` **不是空提交**——它提交当前 index。① 门禁失效时把开发者暂存的机密**推进公开仓的 main**；② 即便推送被拒，cleanup 的 `branch -D` 在**成功路径上也会静默销毁**那份暂存工作（只剩 reflog）。②今天就在发生 | fixed | 我自己实测复现：`git add confidential.txt` → `--allow-empty` 提交里 `git show HEAD:confidential.txt` 输出 `SECRET-DO-NOT-LEAK`。改用 `git commit-tree` 直接造对象再推 SHA：不 checkout、不建分支、不设 trap。复验：跑完后暂存文件仍在、索引不变、无残留分支 |
| F-7 | **block** | llm-advisory ×2 | correctness | 同上（旧版 :94） | 输出"✅ 服务端拒绝了直推**（含 admin）**"，但"含 admin"从未被证明——非 admin 的写权限用户/`GITHUB_TOKEN` 直推受保护分支**本来就会**被拒，与 `enforce_admins` 无关。而这正是 ADR-014 的全部要害 | fixed | 推送前先查 `.permissions.admin`；非 true 时文案降级为"仅覆盖普通写权限路径，未覆盖 admin 绕过" |
| F-8 | **block** | llm-advisory | correctness | 同上（旧版 :17,36 vs :82） | confused deputy：`$1`（被审计的仓）与 `origin`（被推送的仓）完全解耦——可能"读 A 仓配置、往 B 仓推 commit"，报告标题还写着 A 仓。fork 工作流下必然踩中 | fixed | 删掉 `owner/repo` 参数（无跨仓用例，② Simplicity），仓库固定取当前 origin |
| F-9 | **block** | llm-advisory ×3 | correctness | `check-skill-deps.sh`（旧版） | 这个"防 fail-open"的探针自己有 **4 条真空 PASS 路径**：无 skills 目录 / 目录为空 / 无 SKILL.md / 零引用，全部 exit 0。且 `ROOT` 默认 `.`，在仓内子目录跑会把一个有 7 个 skill 的仓判成"非 e2e 仓"并 exit 0 | fixed | 四条路径全改 exit 66；`ROOT` 改取 `git rev-parse --show-toplevel`。四条各配一个负样本（见 §负样本） |
| F-10 | **block** | llm-advisory ×2 | correctness | 同上（旧版 :70） | 抽取正则要求**整个反引号内容就是一条路径**，于是漏掉最主流的写法——反引号包整条命令。实测：构造 5 条全不存在的依赖 → "已检查 0 条引用 / PASS"。**这正是它声称要堵的 fail-open 本身** | fixed | 改为行内任意位置抽取；负样本 `SD/1 命令内引用的缺失依赖必须被抓到` 钉住 |
| F-11 | **block** | llm-advisory ×2 | correctness | 同上（旧版 :25-31 vs :70） | 金丝雀用的正则**与生产抽取器不是同一条**，只验证了"一条没人用的正则能工作"；生产正则退化时它照样绿——**金丝雀无法发现引擎失效**（F-10 就是它没抓住的活证据） | fixed | 抽成单一变量 `PATH_RE`，金丝雀用生产 `extract()` 扫覆盖三种写法的样本，命中 <3 即 exit 66 |
| F-12 | **block** | llm-advisory ×2 | test-gap | `tests/probe-negative/run.sh`、CI | 本次新增两个探针**零可执行验证**：既不在任何 CI job 里，也没有一条负样本。"一条没人跑、无人证伪的探针，等于文档里的一句话"——违反 C13 | fixed | 补 8 条负样本（skill-deps 6 + branch-protection 2）+ 3 条条款探针负样本；`check-skill-deps` / `check-clause-refs` 接进两仓 CI。`check-branch-protection` 因会写远端**不进 PR 触发的 CI**，改由本地跑并在本记录留证 |
| F-13 | **block** | llm-advisory ×3 | security | `risk-tiers.md` 分档表 | **"改门禁绕门禁"路径没堵死**：① `.claude/agents/reviewer.md` 只命中"`*.md` 文档"→ **低档 = 无人审**，改成"永远无 finding"即可关掉整套内环；② `scripts/check-*.sh` 是四个 required check 的**执行体**，只算中档，改成 `exit 0` 后 required check 变成真空绿；③ `docs/process/stages/**`（各 skill 声明的 SOP 权威定义）→ 低档；④ `bin/e2e` 一次改动污染所有新客户仓 → 中档 | fixed | 高档 glob 重写，并前置一条**判据**（"凡定义门禁或被 required check 执行的 = 高档"）使清单可推导而非死记；新增 `ops/**`、`.claude/agents/**`、`tests/probe-negative/**`、`bin/**`、`.claude/settings*.json` 等 |
| F-14 | major | llm-advisory ×2 | contract | `risk-tiers.md` 分档表 | **无 catch-all 默认档**，零命中行为未定义 → 实现者会默认低档（fail-open）。实测落空的真实路径：`index.html`（**整个产品**）、`.claude/settings.local.json`（权限覆盖文件，且**本仓无 `.gitignore`** 可入库）、`.github/dependabot.yml` | fixed | 加默认档（`*` → 按中档），并写明 fail-closed 语义：零命中必须在定档结论里**单独列出清单**；两仓补 `.gitignore` 忽略 `settings.local.json` |
| F-15 | major | llm-advisory | contract | `risk-tiers.md` §执行层 | 该表用**现在时**声称高档"服务端硬拦、无人能绕过"，而线上实测 `approvals=0`、`require_code_owner_reviews=false` → 改宪法/风险表/workflow 的 PR **作者可自合，零人审**。正文别处纠正了，但被引用的是表 | fixed | 表加「**当前试点仓状态（实测）**」列，高档行标 🔴 未启用，并写明 C14 服务端强制力为 0 |
| F-16 | major | llm-advisory ×2 | contract | demo 仓 `docs/constitution.md` | **条款层 fail-open**：本仓宪法只定义 C1-C5，全仓却引用 C6-C15——其中 C12（异构评审）/C13（探针可证伪）/C14（不得自批）正是整套门禁的规范依据。`.claude/agents/security.md` 被指示"按 C14 检查"，读到一个没有 C14 的文件后**不报错，按无约束继续** | fixed | 根因在 `bin/e2e` 的 `tpl_constitution` 只生成 C1-C5 残桩 → 改为发**完整 C1-C15**；新增 `check-clause-refs.sh` 守住整类，接进两仓 CI + 3 条负样本 |
| F-17 | major | llm-advisory | security | `.claude/settings.json` allow 规则 | 白名单有 `Bash(bash scripts/*)`。本 PR 把一个**向远端受保护分支 push** 的脚本放进了这条已授权的通配前缀 → agent 可无提示、带任意参数调用它。叠加 F-6：无人值守会话可把暂存内容发到远端 main | fixed | 探针移出通配区 → `ops/check-branch-protection.sh`（`ops/` 不在 allow 列表，需逐次确认）；`ops/**` 同时列入高风险档 |
| F-18 | minor | deterministic | correctness | `check-shell-traps.sh` | 注释排除的正则只匹配目录模式的 `file:line:` 格式，**单文件模式是 `line:`——而 post-edit hook 走的正是单文件模式**，所以注释里提到 `md5sum` 会被误报为违规。负样本"hook 误伤干净文件"当场抓到 | fixed | 正则改 `(^\|:)[0-9]+:` 兼容两种格式；四个方向的正负样本各验一次 |
| F-19 | minor | deterministic | correctness | `check-clause-refs.sh` | `set -euo pipefail` 下 `grep` 无匹配退出 1，命令替换直接终止脚本，使"抽取失效 → exit 66"的分支**永远到不了**（负样本期望 66 实得 1） | fixed | 加 `\|\| true`；负样本 `CR/66 抽出 0 条定义` 转绿 |
| F-20 | minor | llm-advisory | maintainability | `check-branch-protection.sh` | 退出码契约冲突：抬头声明 `1=REFUTED(拦不住)`，但 `die` 一律 exit 1 → 网络抖动/查询失败被播报成"门禁失效"，会让人去改一个没坏的东西 | fixed | 基础设施类失败改 exit 2，**1 只留给"真的推上去了"**这一条路径 |

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
- 批准人：<待填>
- 决定：<待填>
- 日期：<待填>
- 备注：<待填>
