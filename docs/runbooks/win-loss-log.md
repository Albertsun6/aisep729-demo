# Runbook：win-loss-log（赌场输赢记录）

> 阶段5 产物 · SPEC-22 三节非空硬契约 · 2026-07-31
> 形态：**单文件 HTML，双击用浏览器打开（file:// 协议）**，无服务器、无构建、无部署管线。
> 因此本 runbook 的"启动/回滚/故障"含义与服务端系统**不同**，每节开头都写明了实际含义。

**先记住三个事实**（下面所有命令都基于它们，均已实测）：

| 事实 | 值 | 怎么自己确认 |
|---|---|---|
| 存储键 | `e2e.winLossLog.v1` | `grep -n "var KEY" index.html` |
| 全局对象 | `window.__E2E_LOGIC` / `window.__E2E_STORE` | `grep -n "__E2E_" index.html` |
| 产品文件 | `index.html`（单文件，182 行） | `bash scripts/check-single-file.sh` |

---

## 启动

「启动」= 用户拿到文件并打开它。**没有服务进程要拉起。**

### 方式一：克隆整个仓库（想跟着更新时用）

```bash
git clone https://github.com/Albertsun6/aisep729-demo.git
cd aisep729-demo
open index.html                      # macOS 默认浏览器
open -a "Google Chrome" index.html   # 指定 Chrome
open -a Safari index.html            # 指定 Safari（已实测可用）
```

### 方式二：只拿单文件（最常见，双击即用）

```bash
curl -fsSL -o ~/Desktop/赌场输赢记录.html \
  https://raw.githubusercontent.com/Albertsun6/aisep729-demo/main/index.html
open ~/Desktop/赌场输赢记录.html
```

> ⚠️ 方式二拿到的是**快照副本**。仓库后续更新不会同步到它，
> 而且**仓库侧的任何回滚也影响不了它**（见 §回滚 的不可逆点）。

### 健康检查判据（三条，全绿才算启动成功）

1. **肉眼**：页面标题「赌场输赢记录」，下方三个按钮「记一笔 / 流水 / 汇总」，
   「记一笔」按钮为高亮态（`aria-current="true"`）。

2. **DevTools Console 应当无 error / warn**。
   Chrome：`⌥⌘I` → Console；Safari：先开「开发」菜单，再 `⌥⌘I`。

3. **在 Console 里粘这一段**，三项全 `true` 才算三层都加载了：

```js
JSON.stringify({
  逻辑层: typeof window.__E2E_LOGIC?.validateAmount === 'function',
  存储层: typeof window.__E2E_STORE?.load === 'function',
  UI层:   !!document.getElementById('rows')
})
```

预期输出：`{"逻辑层":true,"存储层":true,"UI层":true}`

### 首次使用最小路径

1. 「记一笔」页：日期已自动填今天 → 场次填「测试」→ 金额填 `100` → 点「记下」
2. 「流水」页应出现一行：`<今天日期>　测试` 与绿色 `+100`
3. 「汇总」页应显示 `+100` 与「共 1 笔」
4. **刷新页面**，上面两项仍在 → 持久化成立

---

## 回滚

### ⚠️ 先读这段：本产品**没有可回滚的上一版本**

这不是疏漏，是实测事实。`index.html` 从头到尾**只被提交过一次**：

```bash
git log --oneline -- index.html
# 6ac4119 feat(win-loss-log): 三步骨架实现 + 逻辑测试 + 单文件契约探针
```

因此三条"看起来像回滚"的路，实测结果是：

| 演练 | 命令 | 实测结果 | 结论 |
|---|---|---|---|
| A | `git revert <门禁③ merge>` | EXIT=0 | ✅ 能跑，但**回滚的是流程文档，不是产品** —— `index.html` 不在那个 commit 里 |
| C | `git revert 6ac4119` | **EXIT=1** | ❌ **14 个文件冲突**（它是初始提交、空树父，后续提交改过这些文件）。此路不通 |
| D | 前滚修复（改 → 提交 → 过门禁） | EXIT=0，三道探针全绿 | ✅ **唯一可行路径** |

### 唯一可行的回滚 = 前滚修复（roll-forward）

```bash
# 1. 从 main 切修复分支（main 受保护，不能直推——已实测拦得住）
git switch -c hotfix-amount-validation origin/main   # 分支名换成你这次修的东西

# 2. 改 index.html（保持在 LAYER:LOGIC / STORE / UI 三块的正确位置内）

# 3. 本地先过门禁，别浪费一轮 CI
bash scripts/check-single-file.sh     # 无外链 / ≤400 行 / 分层三断言
bash tests/logic.test.sh              # 33 条逻辑断言
bash tests/probe-negative/run.sh      # 探针自身可证伪

# 4. 提交并开 PR（四个 required check 必须绿）
git add index.html && git commit -m "fix: 金额校验漏掉全角数字"   # 换成你的描述
git push -u origin hotfix-amount-validation
gh pr create --fill

# 5. 校验命令：确认 PR 可合
gh pr checks --watch
gh pr view --json mergeStateStatus --jq '.mergeStateStatus'   # 必须 CLEAN
gh pr merge --squash --delete-branch
```

### 回滚后的校验

```bash
git fetch origin && git switch main && git pull
bash scripts/check-single-file.sh && bash tests/logic.test.sh && echo "✅ 回滚后契约与逻辑均通过"
git log --oneline -1 -- index.html    # 确认产品文件确实变了
```

### 不可逆点（三个，都实测过）

1. **已分发到用户手上的副本改不了。**
   实测：把 `index.html` 复制到别处后，仓库侧切回原版，那份副本**内容不变**。
   用 `curl` 单文件方式拿走的用户，除非他们自己重新下载，否则永远停在旧版本。
   **这是本产品最硬的不可逆点，没有任何技术手段能补救。**

2. **用户 localStorage 里已写入的数据不随版本回退。**
   数据在浏览器里，与仓库无关。若某个坏版本写入了不合规记录，
   回退代码**不会**清掉它们 —— 但也不会崩：`isRecordV1` 会跳过它们，
   并在 Console 打印 `[win-loss-log] 跳过 N 条不合规记录`（index.html:127）。
   用户需自行清理，见 §故障处理 第 7 条。

3. **公开仓的历史不可撤回。** 仓库已 PUBLIC，历史 commit 可能已被 clone / fork / 缓存 / 索引。

### 预期 RTO（条件性数字，不是保证上界）

| 环节 | 实测 |
|---|---|
| 本地三道探针 | ~3 秒 |
| CI 四 job | **11–20 秒**（`gh run list` 实测 6 次：13/20/15/11/16/13） |
| 人工改码 + 开 PR + 合并 | 数分钟（取决于修复本身） |

→ **仓库侧 RTO ≈ 2–5 分钟**，前提是：① 修复本身简单 ② GitHub Actions 正常。
**用户侧 RTO 不可控**——取决于他们何时重新下载，可能永远不发生。

### 触发回滚的判据（诚实版）

本产品**没有任何遥测**（这是 ADR-001 的显式选型：数据不出本机）。
因此**不存在"指标超阈值自动触发回滚"这回事**。真实的触发源只有两个：

1. 用户主动报告
2. 开发者自己在 Chrome/Safari 里跑 §启动 的健康检查发现异常

**不得**在任何文档里声称本产品有监控告警。

---

## 故障处理

格式：**症状 → 首诊命令（Console 里可直接粘贴）→ 处置 → 升级路径**

### 1. 打开页面一片空白 / 三屏都不显示

- **首诊**：
  ```js
  JSON.stringify({逻辑:!!window.__E2E_LOGIC, 存储:!!window.__E2E_STORE, rows:!!document.getElementById('rows')})
  ```
- **处置**：任一为 `false` → bootstrap 求值失败。看 Console 第一条红色报错。
  最可能是文件被截断或被编辑器改坏。重新下载单文件（见 §启动 方式二）。
- **升级**：本地 `bash scripts/check-single-file.sh`；若探针也红，是仓库侧问题 → 走前滚修复。

### 2. 记了一笔但刷新后不见了

- **首诊**：
  ```js
  JSON.stringify({原始存储: localStorage.getItem('e2e.winLossLog.v1'), 协议: location.protocol})
  ```
- **处置**：
  - 返回 `null` → 从未写入成功。检查是否为**隐私/无痕窗口**（localStorage 被禁），换普通窗口。
  - 有内容但页面不显示 → 记录格式不合规被 `isRecordV1` 跳过，见第 7 条。
- **升级**：若 `协议` 不是 `"file:"`，说明打开方式不同（例如通过某本地服务器），
  那是**另一个 origin**、另一份存储 —— 数据不会互通，这是浏览器行为，非缺陷。

### 3. 汇总数字不对

- **首诊**：
  ```js
  (function(){var raw=localStorage.getItem('e2e.winLossLog.v1');var a=raw?JSON.parse(raw):[];
   return JSON.stringify({条数:a.length, 各笔:a.map(function(x){return x.amount}),
     手算净额:a.reduce(function(s,x){return s+x.amount},0),
     页面显示:document.getElementById('net').textContent});})()
  ```
- **处置**：`手算净额` 与 `页面显示` 应一致（页面带 `+` 号）。
  不一致 → 是真缺陷，走前滚修复并**先补一条逻辑测试**（`tests/logic.test.sh`）。
- **升级**：`bash tests/logic.test.sh` 若在本地就红，直接定位到 `netTotal`。

### 4. 提示「⚠️ 本次数据未能保存（存储不可用）」

- **首诊**：
  ```js
  (function(){try{localStorage.setItem('__probe','1');localStorage.removeItem('__probe');
   return '可写';}catch(e){return e.name+': '+e.message;}})()
  ```
- **处置**：
  - `QuotaExceededError` → 存储满了。**注意：配额是 origin 级共享的**，
    `file://` 下所有本地页面共用同一份（ADR-003 实测确证），
    所以可能是**别的本地页面**占满的。先备份自己的数据（第 5 条），再清理。
  - `SecurityError` / 隐私模式 → 换普通窗口。
- **升级**：这条提示本身是**唯一到达用户眼前的故障信号**（index.html:152）；
  写入失败**不会**静默丢数据，但也不会重试。

### 5. 换了浏览器 / 清了缓存，数据不见了

- **首诊**：无需命令 —— 这是**已知设计限制**，不是故障。
  localStorage 按浏览器隔离，Chrome 与 Safari 各存各的（已实测）。
- **处置（备份）**：在**有数据的那个浏览器**里跑：
  ```js
  (function(){var raw=localStorage.getItem('e2e.winLossLog.v1');
   if(raw===null){console.warn('存储为空，无可备份数据');return;}
   try{JSON.parse(raw);}catch(e){console.error('存储内容不是合法 JSON，仍原样导出以免丢失');}
   var a=document.createElement('a');
   a.href=URL.createObjectURL(new Blob([raw],{type:'application/json'}));
   a.download='winlosslog-backup.json'; a.click(); return '已触发下载';})()
  ```
- **处置（恢复）**：在目标浏览器里，**先看清楚会覆盖什么再执行**：
  ```js
  // ① 先看当前有什么，别盲目覆盖
  localStorage.getItem('e2e.winLossLog.v1')
  // ② 确认可以覆盖后，把备份文件内容粘进下面的字符串
  localStorage.setItem('e2e.winLossLog.v1', '把备份 json 文件的全部内容粘在这对引号里')
  // ③ 刷新页面确认
  ```
  ⚠️ 第 ② 步是**破坏性覆盖**，执行前务必先跑 ①。
- **升级**：产品**没有内置导出功能**（本次范围外，已记入 backlog）。

### 6. Safari 上有问题

- **首诊**：
  ```js
  JSON.stringify({UA:navigator.userAgent.slice(0,40), 协议:location.protocol,
    可写:(function(){try{localStorage.setItem('__p','1');localStorage.removeItem('__p');return true}catch(e){return e.name}})()})
  ```
- **处置**：Safari 已于 2026-07-31 **实测通过 C1-C11**（ADR-003 追加记录）：
  `file://` 下 localStorage 可写、刷新后持久化、功能全部正常。
  所以 Safari 上的问题**不能默认归因于"Safari 不支持"**，按第 1–4 条正常排查。
- **升级**：若确认是 Safari 专有行为，补进 ADR-003 追加记录并前滚修复。

### 7. Console 出现「跳过 N 条不合规记录」或「存储内容无法解析」

- **首诊**：
  ```js
  (function(){var raw=localStorage.getItem('e2e.winLossLog.v1');
   if(raw===null) return '存储为空';
   var p; try{p=JSON.parse(raw);}catch(e){return '整体 JSON 损坏: '+e.message;}
   if(!Array.isArray(p)) return '不是数组: '+typeof p;
   return JSON.stringify({总数:p.length,
     合规:p.filter(function(x){return window.__E2E_LOGIC.isRecordV1(x)}).length,
     不合规样本:p.filter(function(x){return !window.__E2E_LOGIC.isRecordV1(x)}).slice(0,3)});})()
  ```
- **处置**：
  - 「跳过 N 条」→ 这些记录**仍在存储里**，只是不显示、不计入汇总。
    先按第 5 条备份，再决定是否清理。**产品不会自动删它们**（这是有意的：不静默丢数据）。
  - 「存储内容无法解析」→ 整体 JSON 损坏。**产品不会覆写原数据**（index.html:105），
    原始内容仍可通过上面的 `localStorage.getItem` 取出抢救。
- **升级**：若不合规记录是**本产品自己写出来的**，那是真缺陷 —— 先补逻辑测试再前滚修复。

### 通用升级路径

1. 本地全量门禁：`bash scripts/check-single-file.sh && bash tests/logic.test.sh && bash tests/probe-negative/run.sh`
2. 仍无法定位 → 开 issue，附：浏览器与版本、`location.protocol`、上面对应条目的首诊输出、Console 完整报错
3. 需要改码 → 走 §回滚 的前滚修复流程（**不存在"回退上一版"这条路**）
4. Owner：见 `.github/CODEOWNERS`。⚠️ 该文件当前**无服务端强制力**
   （单人仓，`require_code_owner_reviews=false`，见 `docs/process/risk-tiers.md` §执行层「当前状态」列）
