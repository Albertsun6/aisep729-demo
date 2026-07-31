# SPEC：win-loss-log（行为契约）

> 阶段 2 产物 · 门禁②评审材料 · 2026-07-31（v2：architect 预审 10 项阻断全部修复后重写）
> 上游：prd.md（门禁① 批准 @2026-07-31）｜ 状态：待批 → 批准后进阶段 3

## 范围与读者

覆盖 PRD 的 US-1~3 与 SR-1~3。读者：实现者、评审者、门禁②决策人。

## 分层形态（预审 #1/#2/#3 的根本修法）

单文件内联，但**用固定标记把三层切开**，标记字面量即契约：

```
/* ==== LAYER:LOGIC:BEGIN ==== */   纯函数区：零 DOM、零 localStorage 引用
/* ==== LAYER:LOGIC:END ==== */
/* ==== LAYER:STORE:BEGIN ==== */   存储区：函数接受注入的 store（便于用内存 Map 测试）
/* ==== LAYER:STORE:END ==== */
/* ==== LAYER:UI:BEGIN ==== */      UI 区（含控制器职责）：调 LOGIC 做计算校验、调 STORE 做读写；
/* ==== LAYER:UI:END ==== */        **不直接碰 localStorage**（必须经 STORE 的函数）
```

**为什么这么切**：预审实测——整块 `<script>` 交给 node 求值必炸（`ReferenceError: document is not defined`）。抽出 LOGIC 块后求值可跑通，逻辑契约才真的可验证。

**测试 ABI（异构评审 #1：原设计只说"new Function 求值"，没定义怎么导出）**：
- LOGIC/STORE 块必须**自包含**：不引用块外常量、无未声明自由变量
- 每块**末尾必须有** `return { ...导出的函数名 };`（否则 `new Function(code)()` 只返回 undefined）
- 测试 harness 抽块后拼 `"use strict";` 前缀再求值（块外的 strict 指令抽块后会丢失）
- **负样本**：构造一个引用块外常量的 LOGIC 块，断言测试**必须失败**（证明自包含约束真的在管用）

## 行为契约

### 数据层

- **SPEC-1**：记录结构 `{schemaVersion:1, id:string, date:"YYYY-MM-DD", venue:string, amount:number}`，`amount` 为整数（正=赢、负=输），单位元。验证：`tests/logic.test.sh` 抽 LOGIC 块后断言 `makeRecord()` 产出结构与字段类型
- **SPEC-2**：存储层函数**接受注入的 store**（接口 `{get(k), set(k,v)}`），生产用 localStorage、测试用内存 Map；存储键固定 **`e2e.winLossLog.v1`**（ADR-003：file:// 全局共享 origin，须带命名空间前缀防撞名；本机实测已存在他人键 `gambleTrackerV1`）。**STORE 块内对 localStorage 的引用必须在函数体内**（顶层求值会使抽块测试炸 `localStorage is not defined`，预审 B1 实测）。验证：抽 STORE 块 + 内存 Map 断言写入读回一致（**不需要浏览器**）
- **SPEC-3**：读取容错分三级——① JSON 解析失败或根值非数组 → 返回空列表 + `console.warn` 且**保留原始数据不覆写**（不能因读不懂就清空用户数据）② 单条不满足 `isRecordV1`（`schemaVersion===1` 且 `date` 匹配 `^\d{4}-\d{2}-\d{2}$` 且 `amount` 为安全整数 且 `venue` 为字符串）→ 跳过并计数 ③ localStorage 抛异常（隐私模式/配额）→ 降级内存态 + `console.warn` + UI 提示"本次数据不会保存"。验证：三类各构造负样本断言行为；断言 `load()` 返回 `{records, skipped}` 且脏数据不进排序累加（异构评审 #6：原设计只查 schemaVersion，字段类型错的仍会进计算）
- **SPEC-3b**：只读写 `e2e.` 前缀的键，**绝不触碰同 origin 下他人的键**（ADR-003：本机实测存在 `gambleTrackerV1`）。验证：注入他人键后断言 `load()`/`save()` 前后该键值不变

### 输入校验（SR-2 只收整数）

- **SPEC-4**：金额校验算法定死（异构评审 #4）——① `typeof raw === "string"` ② 词法 `^-?\d+$`（不用 `Number.isInteger`：预审实测 `1e3`/`0x10` 会误过）③ `Number.isSafeInteger(Number(raw))`。三条全过才接受。验证：断言 `12`/`0`/`-500` 接受；`12.5`/`abc`/``/`1e3`/`0x10`/`" 12 "`/`+12`/`12.` 全拒
- **SPEC-5**：单笔与**累计**都必须安全——`Number.isSafeInteger` 每笔成立**不代表总和成立**（`[MAX_SAFE, 2, -MAX_SAFE]` 用 Number 累加得 `1` 而非 `2`）。故：**单笔绝对值上限 1e9**（赌场场景绰绰有余），累计仍用 Number 但有上限保证安全。验证：断言 `"9007199254740993"` 与 `"-9007199254740993"` 均被拒；断言 `1000000001` 被拒；断言累计 1000 笔上限值不失精度
- **SPEC-6**：`date` 用 `<input type="date" required>` 原生约束（缺失即浏览器拦截）；`venue` 允许空串。验证：markup grep 断言 `type="date"` 与 `required` 存在

### 展示层

- **SPEC-7**：流水按 `date` 倒序；同日期按插入顺序倒序。**新记录按日期定位，不保证置顶**（补记历史日期时会排在中间——PRD US-1 已同步修订）。验证：抽 LOGIC 块断言 `sortRecords()` 顺序
- **SPEC-8**：零记录时显示空态文案。验证：**人工 checklist**（浏览器打开确认，非机器可验——不伪装成断言）
- **SPEC-9**：汇总显示累计净额与笔数。**表述更正**：JS 的 Number 本身就是浮点（异构评审 #4），此处成立不是因为"没有浮点"，而是因为**所有值都在安全整数范围内且有 1e9 单笔上限**。验证：断言 `netTotal([300,-500,200]) === 0`、`count === 3`；断言 1000 笔各 1e9 累计精确

### 形态约束（SR-3 单文件零依赖）

- **SPEC-10**：无 `<script src=`、无 `<link rel="stylesheet" href=`、无 `http(s)://`、无 `//host` 协议相对 URL、无 `fetch(`、无 `sendBeacon`、无 `@import`。验证：`scripts/check-single-file.sh` grep 断言零命中（**证据强度限于"无静态外部引用"**，见预审 A3）
- **SPEC-11**：`index.html` 总行数（`wc -l`，含空行，与 PRD NFR-3 同口径）≤400。验证：同上脚本内 `wc -l` 断言
- **SPEC-12**：分层断言——① 六个标记**各出现一次、独占一行、严格按 LOGIC→STORE→UI 顺序**（重复/同行/缺失/错序一律 FAIL，**fail-closed**）② LOGIC 块内 `document`/`localStorage`/`window` 命中数=0 ③ `localStorage` 只出现在 STORE 块内。验证：`check-single-file.sh` 内 **awk 区间判定**（plain grep 无区块作用域，预审实测）
  - **能力边界（异构评审 #2，必须如实标注）**：这是**词法引用守卫**，不是架构依赖证明。`window.document`、`document["querySelector"]`、`globalThis["local"+"Storage"]`、别名与动态求值**均可绕过**。它挡的是"手滑写错层"，不是"蓄意绕过"；真正的依赖约束需要 JS parser，超出本 demo 的零依赖约束（记入 ADR-002 后果）

## 数据与接口

- 存储键：`e2e.winLossLog.v1`（ADR-003）。**存储命名空间版本与数据结构 schemaVersion 是两个独立决策**，各自变更各走 ADR（异构评审 #6）
- 无网络接口（离线应用）

## 与 PRD 的追溯

| SPEC | ↔ US/SR/NFR | 备注 |
|---|---|---|
| SPEC-1~3 | SR-1 | 数据结构、注入式 store、脏数据容错 |
| SPEC-4~6 | US-1 · SR-2 | 只收整数（词法判定）+ 字段约束 |
| SPEC-7~9 | US-2 · US-3 | 流水排序、空态、汇总 |
| SPEC-10 | SR-3 · NFR-2/4 | 单文件零外链 |
| SPEC-11 | NFR-3 | 规模 ≤400 行（wc -l 口径） |
| SPEC-12 | plan 依赖方向 | 分层 fitness function |
| （人工 checklist） | NFR-1 | 浏览器兼容：Safari/Chrome 各跑一遍，结果在门禁④留痕 |

## 评审记录

### architect 预审
2026-07-31 五查完成（只读，含 node v24.12.0 实测与 awk 原型验证）：**10 项阻断**——①②验证方式在单文件形态下不可执行（实测 node eval 必炸）③fitness 的 grep 做不到区块作用域 ④SPEC-10 口径与 PRD 不一致且静默改写已批 NFR ⑤ratchet 对 index.html 零覆盖=假绿 ⑥CI workflow 指向不存在的 specs/platform-pilot/（实测 FAIL 65）⑦PRD 追溯下游列未填 ⑧引用了本仓不存在的 US-13/ADR-010 ⑨ADR-001 选项 B 是稻草人（IndexedDB 不需构建）⑩SPEC-7 静默重解了 US-1 的"流水顶部"验收。**全部修复**（分层标记+注入式 store+awk 区间+口径统一+ratchet 声明+CI 模板修复+追溯回填+ADR-002 新增+ADR-001 选项 B 改写+US-1 同步修订）。建议项 A1/A3/A4/A5/A7 一并采纳（词法校验、证据强度限定、去掉计数 UI、字段约束、spike 重定）。

### 异构评审辩论矩阵

2026-07-31 · reviewer=gpt-5.6-sol-xhigh（跨模型独立 lens）· Verdict=**Refine（11 阻断 + 2 建议）**
> 注：此前本栏曾被填为"按 risk-tiers 豁免"——**那是错的**（复核 R2 指出：demo 仓无 risk-tiers.md，且它是阶段4 的代码评审路由，挪用来豁免阶段2 架构评审；同模型预审也不能替代异构 lens）。已真跑。

| # | 意见 | 立场 | 论据/落改 |
|---|---|---|---|
| 1 | 抽块 `new Function` 未定义导出契约、丢 strict、捕获不到块外常量 | accept | spec 新增「测试 ABI」：块自包含 + 末尾 `return {...}` + harness 补 `"use strict"` + **反向负样本**（引用块外常量必须失败） |
| 2 | awk 只证行区间，别名/动态属性可绕过，不能宣称证明架构 | accept | SPEC-12 降格为**词法引用守卫**并写明可绕过方式；标记规则收严（各一次/独占一行/严格顺序） |
| 3 | spec 说 UI 调 LOGIC+STORE，plan 说禁 UI→STORE，**两份设计矛盾** | accept | 统一：UI 区含控制器职责，可调 LOGIC 与 STORE，**但不直接碰 localStorage**；spec/plan/spine 同步 |
| 4 | 每笔安全 ≠ 总和安全（`[MAX_SAFE,2,-MAX_SAFE]` 得 1）；"不引入浮点"表述错误 | accept | SPEC-4 校验算法定死三条；SPEC-5 加**单笔上限 1e9** 保证累计安全；SPEC-9 更正表述（JS Number 本就是浮点，成立靠的是安全整数范围） |
| 5 | 验证只证纯函数，不证用户契约（提交→写入→刷新→仍在） | partial | **接受覆盖缺口而非假装解决**：ADR-002 后果段显式记录"用户契约端到端链路只有人工 checklist"，并注明企业落地应选方案 D（Node 单测+浏览器冒烟+实机） |
| 6 | 读取只查 schemaVersion，字段类型错的仍进计算；解析失败/非数组无契约 | accept | SPEC-3 改三级容错（解析失败保留原数据不覆写 / `isRecordV1` 逐字段 / localStorage 异常降级内存态）+ 新增 SPEC-3b（只碰 `e2e.` 前缀键） |
| 7 | **file:// localStorage 持久化是未验证的地基假设**（单点风险） | accept | **实测并出 ADR-003**：Chrome 下刷新与改名均持久（评审担心的丢数据不成立），但发现**所有 file:// 页面共享同一 localStorage**——本机实测已存在他人键 `gambleTrackerV1`。存储键改 `e2e.winLossLog.v1`；NFR-4 表述降级为"不出本机但同机本地页可读"；**Safari 未验证**列入门禁④ |
| 8 | ADR-001 选项 B/C 代价表述仍不诚实（异步不必侵蚀纯逻辑；后端不必然要账号） | accept | 二次修正为真实代价：B=样板/错误面吃预算 + <100KB 零收益 + **ADR-003 证明连隔离都换不到**；C=部署/网络/安全/运维成本 |
| 9 | 把 Playwright 等**开发期依赖**等同产品运行时依赖，错误解释 SR-3 | accept | ADR-002 选项 B 代价改写并明说"SR-3 约束运行时，开发依赖不违反"；**新增选项 D（混合方案）**并显式记录"不选 D 是 Appetite 不是技术判断" |
| 10 | 静态黑名单证明不了零网络请求（XHR/WS/EventSource/动态拼接） | partial | SPEC-10 已限定证据强度为"无静态外部引用"；浏览器网络捕获列为**门禁④人工 checklist**（不加自动化，超 Appetite） |
| 11 | **required check 对应 job 不是 step**；且缺文件时静默跳过成功 | accept | CI 拆四个独立 job（process-gates/probe-negatives/product-contract/logic-contract）；**tasks.md 一旦存在即进入阶段3，缺交付物 FAIL 不再跳过** |
| 12 | `wc -l` 可被压行规避，超限不应先牺牲校验 | accept（建议级） | plan NFR-3 行补：超限按 prfaq 熔断砍序砍功能，**先删装饰与重复 markup，保留三项 Must 行为**，不抬限不压行 |
| 13 | 单文件权衡可能被培训对象误读为通用最佳实践 | accept（建议级） | ADR-002 决定段已写明"企业项目应默认选 D"；手册须设「适用边界」章（M4 交付项） |

**单点风险裁定**：成立且已实测出清（见 #7 与 ADR-003）——但**出清方式与评审预期不同**：不是"确认能持久化"，而是"发现共享 origin 这个更重要的事实"，并据此改了存储键、隐私表述与读写边界。

---
门禁② 记录（spec/plan/ADR 三制品共用；批后"决定"填 批准/打回 之一）：
- 批准人：yongqian（架构决策人，人类）
- 决定：批准
- 日期：2026-07-31
- 备注：双审通过后批准——architect 预审 10 阻断 + 复核 2 残留清零；异构评审（gpt-5.6-sol-xhigh）Refine 13 条全部处置（11 accept / 2 partial 明确记为接受的覆盖缺口）。地基假设经 Chrome 实测出 ADR-003（file:// 共享 origin，存储键改 e2e. 前缀）。已知缺口：用户端到端链路仅人工 checklist、Safari 未验证（门禁④前必验）。
