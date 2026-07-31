#!/usr/bin/env bash
# check-branch-protection.sh — 服务端门禁的【行为证明】探针（ADR-014）
#
# 核心原则：不把「配置回读一致」当作通过依据。
#   S6 spike 实测：required checks 四项全在、GitHub 打印 "4 of 4 required status
#   checks are expected"，push 依然成功（enforce_admins 默认 false）。
#   所有"看起来像验证"的信号都是绿的 —— 静默失效。
#   故本探针只认一件事：**实际尝试直推受保护分支，必须被服务端拒绝。**
#
# 用法：bash scripts/check-branch-protection.sh [<owner/repo>] [<branch>]
#   不传参时从当前仓的 origin 推断，分支默认 main。
#
# 退出码：0=CONFIRMED  1=REFUTED(拦不住)  2=不可用/降级(fail-closed，非静默)  66=自检失败

set -euo pipefail

REPO="${1:-}"
BRANCH="${2:-main}"

die()  { echo "❌ $*" >&2; exit 1; }
warn() { echo "⚠️  $*" >&2; }

# ---- 自检金丝雀：工具可用性必须响亮失败，不许静默跳过 ----
command -v git >/dev/null 2>&1 || { echo "自检失败：git 不可用" >&2; exit 66; }
command -v gh  >/dev/null 2>&1 || { echo "自检失败：gh CLI 不可用，无法验证服务端门禁" >&2; exit 66; }
gh auth status >/dev/null 2>&1 || { echo "自检失败：gh 未登录，无法验证服务端门禁" >&2; exit 66; }

if [ -z "${REPO}" ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) \
    || die "无法推断仓库（不在 git 仓内，或无 origin 远端）"
fi

echo "== 服务端门禁行为探针 ｜ ${REPO} @ ${BRANCH} =="

# ---- 第 0 层：分支保护是否可用（ADR-014 陷阱①）----
PROT_JSON=$(gh api "repos/${REPO}/branches/${BRANCH}/protection" 2>&1) || {
  if printf '%s' "${PROT_JSON}" | grep -qi 'Upgrade to GitHub Pro'; then
    cat >&2 <<EOF
⚠️  服务端门禁【不可用】：免费账号的私有仓不支持分支保护。
    当前仓只能按【试点模式】运行（ADR-009）：门禁记录是过程留痕，无服务端强制力。
    升级路径：① 仓库改公开，或 ② GitHub Team/Enterprise 计划。
    —— 此状态下禁止声称"门禁已启用"。
EOF
    exit 2
  fi
  if printf '%s' "${PROT_JSON}" | grep -qi 'Branch not protected'; then
    die "分支 ${BRANCH} 未配置任何保护规则"
  fi
  die "查询分支保护失败：$(printf '%s' "${PROT_JSON}" | head -2)"
}

# ---- 诊断信息（仅供人看，不作为通过依据）----
# 用 gh 内置 jq 按结构取值：早期版本靠 tr/grep 切字符串，把 required_signatures.enabled
# 误读成 enforce_admins.enabled，实际 true 报成 false —— 误导性诊断本身就是 ADR-014 反对的东西。
echo "-- 配置回读（诊断用，不构成通过依据）--"
CHECKS=$(gh api "repos/${REPO}/branches/${BRANCH}/protection" \
  --jq '(.required_status_checks.contexts // []) | join(",")' 2>/dev/null || echo '?')
ADMINS=$(gh api "repos/${REPO}/branches/${BRANCH}/protection" \
  --jq '.enforce_admins.enabled' 2>/dev/null || echo 'unknown')
echo "   required checks : ${CHECKS:-(无)}"
echo "   enforce_admins  : ${ADMINS}"

# ---- 第 1 层：行为证明（唯一的通过依据）----
echo "-- 行为证明：尝试直推 ${BRANCH}，必须被拒 --"

git rev-parse --git-dir >/dev/null 2>&1 || die "不在 git 工作区内，无法做行为证明"
git fetch -q origin "${BRANCH}" || die "fetch origin/${BRANCH} 失败"

PROBE_BRANCH="__e2e-protection-probe"
ORIG_REF=$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)

cleanup() {
  git checkout -q "${ORIG_REF}" 2>/dev/null || true
  git branch -D "${PROBE_BRANCH}" -q 2>/dev/null || true
}
trap cleanup EXIT

git checkout -q -B "${PROBE_BRANCH}" "origin/${BRANCH}"
git commit --allow-empty -q -m "probe: 直推受保护分支应被拒绝（check-branch-protection.sh）"

PUSH_LOG=$(mktemp)
if git push origin "${PROBE_BRANCH}:${BRANCH}" >"${PUSH_LOG}" 2>&1; then
  cat >&2 <<EOF
❌ REFUTED：直推 ${BRANCH} 竟然成功了 —— 服务端门禁未真正生效。
   最常见原因：enforce_admins = false（当前值：${ADMINS:-unknown}）。
   分支保护默认对仓库 admin 不生效，而小团队里人人都是 admin。
   修复：gh api -X POST repos/${REPO}/branches/${BRANCH}/protection/enforce_admins
   注意：本次探针的空 commit 已推入 ${BRANCH}，需人工清理。
EOF
  rm -f "${PUSH_LOG}"
  exit 1
fi

if grep -qiE 'protected branch|GH006|must be made through a pull request' "${PUSH_LOG}"; then
  echo "✅ CONFIRMED：服务端以分支保护拒绝了直推（含 admin）"
  rm -f "${PUSH_LOG}"
  exit 0
fi

warn "推送被拒，但拒绝原因不是分支保护 —— 证据不成立（fail-closed 判为不通过）"
sed -n '1,6p' "${PUSH_LOG}" >&2
rm -f "${PUSH_LOG}"
exit 2
