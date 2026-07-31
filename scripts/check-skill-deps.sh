#!/usr/bin/env bash
# check-skill-deps.sh — skill 声明的依赖文件必须真实存在（防 fail-open 脚手架缺口）
#
# 根因（本探针存在的理由）：
#   skill 的 SOP 会引用仓内文件（分档表 / 阶段定义 / 模板 / 探针）。若脚手架没把
#   这些文件发到业务仓，skill 跑到那一步会"找不到就跳过"——**静默降级为不检查**。
#   实测案例：`e2e init/adopt` 漏发 docs/process/risk-tiers.md → e2e-review 第 1 步
#   定档无数据源 → 一切按低风险处理 → 不跑 LLM 与异构评审。这是 fail-open。
#   同类事故已发生多次（glossary 缺阶段4-6 / 缺 spine.md / CI 硬编码 specs 路径），
#   故不再逐个补，改为**结构性守住整类**。
#
# 用法：bash scripts/check-skill-deps.sh [<repo-root>]
# 退出码：0=全部存在  1=有缺失  66=自检失败（扫描引擎不可用）

set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "${ROOT}" && pwd)"
cd "${ROOT}"

SKILL_DIR=".claude/skills"
[ -d "${SKILL_DIR}" ] || { echo "跳过：无 ${SKILL_DIR}（非 e2e 仓）"; exit 0; }

# ---- 自检金丝雀：扫描引擎必须真能从样本里抽出路径，否则响亮失败 ----
CANARY='参见 `docs/process/risk-tiers.md` 与 `scripts/check-structure.sh`'
canary_hits=$(printf '%s\n' "${CANARY}" \
  | grep -oE '`[A-Za-z0-9_][A-Za-z0-9_./-]*\.(md|sh|json|ya?ml|txt)`' | wc -l | tr -d ' ')
if [ "${canary_hits}" -ne 2 ]; then
  echo "自检失败：路径抽取引擎异常（金丝雀应命中 2 条，实得 ${canary_hits}）" >&2
  exit 66
fi

echo "== skill 依赖文件存在性检查 ｜ ${ROOT} =="

missing=0
checked=0

for skill in "${SKILL_DIR}"/*/SKILL.md; do
  [ -f "${skill}" ] || continue
  name=$(basename "$(dirname "${skill}")")
  skill_home=$(dirname "${skill}")

  # 抽取反引号包住的仓内相对路径：必须以已知顶层目录开头，且不含占位符/通配
  # `<skill目录>/scripts/x.sh` 这类相对 skill 自身的引用单独解析
  while IFS= read -r ref; do
    path="${ref//\`/}"
    case "${path}" in
      *'<'*|*'>'*|*'*'*) continue ;;                  # 占位符/通配，非确定路径
    esac

    # 写目标豁免：这些是 skill 运行时**按需创建**的产出，不是读依赖，
    # 不存在属正常态。豁免必须逐条写明理由，不许当垃圾桶。
    case "${path}" in
      docs/process/opportunity-backlog.md) continue ;;  # 阶段0 kill 想法时才创建
    esac

    # 解析基准：skill 私有资产（templates/、自带探针）相对 skill 目录，
    # 其余相对仓根。两个基准都试——SKILL.md 里 `scripts/check-x.sh` 既可能指
    # skill 自带探针，也可能指仓级探针，任一存在即算满足。
    checked=$((checked + 1))
    if [ -e "${skill_home}/${path}" ] || [ -e "${ROOT}/${path}" ]; then
      continue
    fi
    case "${path}" in
      docs/*|scripts/*|tests/*|bin/*|.claude/*|.github/*|specs/*|templates/*)
        printf '  ❌ %-18s 引用了不存在的 %s\n' "${name}" "${path}"
        missing=$((missing + 1)) ;;
      *) checked=$((checked - 1)) ;;                    # 不认识的前缀不臆断
    esac
  done < <(grep -oE '`[A-Za-z0-9_.][A-Za-z0-9_./<>-]*\.(md|sh|json|ya?ml|txt)`' "${skill}" | sort -u)
done

echo "  已检查 ${checked} 条引用"
if [ "${missing}" -gt 0 ]; then
  cat >&2 <<EOF

❌ FAIL：${missing} 条 skill 依赖缺失。
   后果不是"报错"，而是 skill 跑到那步**静默跳过检查**（fail-open）。
   修复：把缺失文件加入 bin/e2e 的 init/adopt 拷贝清单，或修正 SKILL.md 的引用路径。
EOF
  exit 1
fi

echo "PASS: skill 依赖文件齐全"
