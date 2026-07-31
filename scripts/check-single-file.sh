#!/usr/bin/env bash
# check-single-file.sh — 单文件交付物契约探针（SPEC-10/11/12）
#
# 能力边界（异构评审 #2，必须如实说）：SPEC-12 是**词法引用守卫**，不是架构依赖证明。
#   `window.document` / `document["x"]` / `globalThis["local"+"Storage"]` / 别名 / 动态求值
#   均可绕过。它挡"手滑写错层"，不挡"蓄意绕过"。
#
# 用法: bash scripts/check-single-file.sh [文件，默认 index.html]
# 退出码: 0=PASS / 65=文件缺失 / 66=契约违反
set -u
cd "$(dirname "$0")/.." || exit 1
f="${1:-index.html}"
[ -f "$f" ] || { echo "FAIL(65): 缺 ${f}"; exit 65; }
miss=0

# ---- SPEC-10：无静态外部引用 ----
ext=$(LC_ALL=C grep -nE '<script[^>]+src=|<link[^>]+rel="stylesheet"[^>]+href=|https?://|["'"'"']//[a-zA-Z0-9]|@import|fetch\(|sendBeacon|XMLHttpRequest|EventSource|new WebSocket' "$f" || true)
if [ -n "$ext" ]; then
  echo "❌ SPEC-10：存在外部引用/网络调用"; printf '%s\n' "$ext" | sed 's/^/   /'
  miss=$((miss + $(printf '%s\n' "$ext" | grep -c .)))
fi

# ---- SPEC-11：总行数 ≤400（wc -l 口径，与 PRD NFR-3 一致）----
lines=$(wc -l < "$f" | tr -d ' ')
if [ "$lines" -gt 400 ]; then
  echo "❌ SPEC-11：${lines} 行 > 400（按 prfaq 熔断砍序砍功能，不抬限不压行）"; miss=$((miss+1))
else
  echo "✅ SPEC-11：${lines}/400 行"
fi

# ---- SPEC-12①：六个标记各一次、独占一行、严格顺序 ----
order=$(LC_ALL=C grep -nE '^[[:space:]]*/\* ==== LAYER:(LOGIC|STORE|UI):(BEGIN|END) ==== \*/[[:space:]]*$' "$f" \
        | sed -E 's/.*LAYER:([A-Z]+):([A-Z]+).*/\1:\2/' | tr '\n' ' ')
want="LOGIC:BEGIN LOGIC:END STORE:BEGIN STORE:END UI:BEGIN UI:END "
if [ "$order" != "$want" ]; then
  echo "❌ SPEC-12①：分层标记不合规（fail-closed）"
  echo "   期望：${want}"
  echo "   实际：${order:-（无）}"
  miss=$((miss+1))
else
  echo "✅ SPEC-12①：六标记齐全、独占行、顺序正确"
fi

# ---- SPEC-12②③：区块内引用约束（awk 区间判定；plain grep 无区块作用域）----
blk() {  # blk <层名> → 输出该层区块内容（**剥行注释**：注释里提到 ≠ 代码引用）
  awk -v L="$1" '
    $0 ~ "LAYER:" L ":BEGIN" {inside=1; next}
    $0 ~ "LAYER:" L ":END"   {inside=0}
    inside {print}
  ' "$f" | sed -E 's://.*$::'
}
logic_bad=$(blk LOGIC | LC_ALL=C grep -cE 'document|localStorage|window' || true)
if [ "${logic_bad:-0}" -gt 0 ]; then
  echo "❌ SPEC-12②：LOGIC 块内有 ${logic_bad} 处 DOM/存储引用（应为纯函数）"; miss=$((miss+1))
else
  echo "✅ SPEC-12②：LOGIC 块纯净（零 DOM/存储引用）"
fi
ui_bad=$(blk UI | LC_ALL=C grep -cE 'localStorage' || true)
if [ "${ui_bad:-0}" -gt 0 ]; then
  echo "❌ SPEC-12③：UI 块直接访问 localStorage ${ui_bad} 处（必须经 STORE）"; miss=$((miss+1))
else
  echo "✅ SPEC-12③：UI 块不直连 localStorage"
fi
# STORE 块：localStorage 引用必须在函数体内（预审 B1：顶层求值会让抽块测试炸）
store_top=$(blk STORE | LC_ALL=C grep -nE '^[[:space:]]*(const|let|var)[^=]*=[^=]*localStorage' || true)
[ -n "$store_top" ] && { echo "❌ SPEC-2：STORE 块顶层求值 localStorage（抽块测试会炸）"; printf '%s\n' "$store_top" | sed 's/^/   /'; miss=$((miss+1)); }

[ "$miss" -gt 0 ] && { echo "FAIL(66): ${miss} 项契约违反"; exit 66; }
echo "PASS: 单文件契约全部满足"
exit 0
