#!/usr/bin/env bash
# logic.test.sh — 逻辑与存储契约测试（SPEC-1~5/7/9 + SPEC-2/3/3b）
#
# 测试 ABI（异构评审 #1 定死）：
#   - 抽 LAYER:LOGIC / LAYER:STORE 区块
#   - 拼 "use strict"; 前缀（块外 strict 指令抽块后会丢失）
#   - 块末必须有 return {...}，否则 new Function(code)() 返回 undefined
#   - 块必须自包含：引用块外常量的负样本必须失败
set -u
cd "$(dirname "$0")/.." || exit 1
SRC="${1:-index.html}"
[ -f "$SRC" ] || { echo "FAIL(65): 缺 ${SRC}"; exit 65; }
command -v node >/dev/null 2>&1 || { echo "FAIL(65): 需要 node（ADR-002 选项 A）"; exit 65; }

extract() { awk -v L="$1" '$0 ~ "LAYER:" L ":BEGIN"{i=1;next} $0 ~ "LAYER:" L ":END"{i=0} i' "$SRC"; }
extract LOGIC > /tmp/e2e-logic.$$.js
extract STORE > /tmp/e2e-store.$$.js
trap 'rm -f /tmp/e2e-logic.$$.js /tmp/e2e-store.$$.js /tmp/e2e-test.$$.js' EXIT

cat > /tmp/e2e-test.$$.js <<'NODEEOF'
const fs = require('fs');
const [,, logicPath, storePath] = process.argv;
let pass = 0, fail = 0;
const ok = (name, cond) => cond ? (pass++, console.log('  ✅ ' + name))
                                : (fail++, console.log('  ❌ ' + name));

// 测试 ABI：补 "use strict"，要求块末 return {...}
const load = p => new Function('"use strict";' + fs.readFileSync(p, 'utf8'))();
const L = load(logicPath);
const S = load(storePath);

console.log('-- 测试 ABI（异构评审 #1）--');
ok('LOGIC 块有导出（return {...}）', L && typeof L === 'object');
ok('STORE 块有导出', S && typeof S === 'object');
// 负样本：引用块外常量必须失败（证明自包含约束真在管用）
let selfContained = false;
try { new Function('"use strict"; return OUTSIDE_CONST;')(); }
catch (e) { selfContained = e instanceof ReferenceError; }
ok('负样本：引用块外常量确实抛 ReferenceError', selfContained);

console.log('-- SPEC-4/5 金额校验 --');
[['12',true],['0',true],['-500',true],['1000000000',true],
 ['12.5',false],['abc',false],['',false],['1e3',false],['0x10',false],
 [' 12 ',false],['+12',false],['12.',false],
 ['9007199254740993',false],['-9007199254740993',false],['1000000001',false]
].forEach(([raw, want]) =>
  ok(`validateAmount(${JSON.stringify(raw)}) === ${want}`, L.validateAmount(raw) === want));

console.log('-- SPEC-9 累计（安全整数范围内）--');
ok('netTotal([300,-500,200]) === 0', L.netTotal([{amount:300},{amount:-500},{amount:200}]) === 0);
const big = Array.from({length:1000}, () => ({amount: 1000000000}));
ok('1000 笔 1e9 累计精确', L.netTotal(big) === 1000000000000);

console.log('-- SPEC-7 排序（日期倒序）--');
const recs = [{date:'2026-01-01',amount:1},{date:'2026-03-01',amount:2},{date:'2026-02-01',amount:3}];
ok('sortRecords 日期倒序', L.sortRecords(recs).map(r=>r.date).join(',') === '2026-03-01,2026-02-01,2026-01-01');

console.log('-- SPEC-1/3 记录校验 --');
ok('isRecordV1 接受合法记录', L.isRecordV1({schemaVersion:1,id:'a',date:'2026-01-01',venue:'x',amount:5}));
ok('isRecordV1 拒 schemaVersion 错', !L.isRecordV1({schemaVersion:2,id:'a',date:'2026-01-01',venue:'x',amount:5}));
ok('isRecordV1 拒 amount 非整数', !L.isRecordV1({schemaVersion:1,id:'a',date:'2026-01-01',venue:'x',amount:1.5}));
ok('isRecordV1 拒 date 格式错', !L.isRecordV1({schemaVersion:1,id:'a',date:'2026/01/01',venue:'x',amount:5}));

console.log('-- SPEC-2/3/3b 存储（注入式 store）--');
const mk = (init={}) => { const m = new Map(Object.entries(init));
  return { get:k=>m.has(k)?m.get(k):null, set:(k,v)=>m.set(k,v), _m:m }; };
const KEY = 'e2e.winLossLog.v1';
let st = mk();
S.save(st, [{schemaVersion:1,id:'a',date:'2026-01-01',venue:'v',amount:5}]);
ok('save 写入后可读回', S.load(st, L.isRecordV1).records.length === 1);
ok('SPEC-2 键名为 e2e.winLossLog.v1', st._m.has(KEY));

st = mk({[KEY]: '这不是 JSON'});
let r = S.load(st, L.isRecordV1);
ok('SPEC-3① 解析失败返回空列表', r.records.length === 0);
ok('SPEC-3① 解析失败不覆写原数据', st._m.get(KEY) === '这不是 JSON');

st = mk({[KEY]: JSON.stringify({not:'array'})});
ok('SPEC-3① 根值非数组返回空', S.load(st, L.isRecordV1).records.length === 0);

st = mk({[KEY]: JSON.stringify([
  {schemaVersion:1,id:'ok',date:'2026-01-01',venue:'v',amount:5},
  {schemaVersion:2,id:'bad1',date:'2026-01-01',venue:'v',amount:5},
  {schemaVersion:1,id:'bad2',date:'bad',venue:'v',amount:5}])});
r = S.load(st, L.isRecordV1);
ok('SPEC-3② 脏记录被跳过', r.records.length === 1);
ok('SPEC-3② 跳过计数正确', r.skipped === 2);

st = mk({'gambleTrackerV1':'别人的数据', [KEY]: JSON.stringify([])});
S.save(st, [{schemaVersion:1,id:'x',date:'2026-01-01',venue:'v',amount:1}]);
ok('SPEC-3b 不碰他人键（ADR-003）', st._m.get('gambleTrackerV1') === '别人的数据');

console.log(`\n== 结果：${pass} 通过 / ${fail} 失败 ==`);
process.exit(fail === 0 ? 0 : 1);
NODEEOF
node /tmp/e2e-test.$$.js /tmp/e2e-logic.$$.js /tmp/e2e-store.$$.js
