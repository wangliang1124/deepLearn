#!/bin/bash
# 编译并运行本目录所有验证代码。
#   ./run-all.sh           跑全部
#   ./run-all.sh objc-kvo  只跑名字匹配的
cd "$(dirname "$0")" || exit 1

filter="${1:-}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0; failed=()

run() {
    local name="$1"; shift
    [ -n "$filter" ] && [[ "$name" != *"$filter"* ]] && return
    printf '\n\033[1m═══ %s ═══\033[0m\n' "$name"
    if ! "$@"; then
        printf '\033[31m!!! %s 失败\033[0m\n' "$name"
        fail=$((fail+1)); failed+=("$name"); return
    fi
    pass=$((pass+1))
}

run_objc() {
    local f="$1" out="$tmp/${1%.m}"
    if ! clang -fobjc-arc -framework Foundation "$f" -o "$out" 2>"$tmp/err"; then
        grep 'error:' "$tmp/err" | head -5; return 1
    fi
    "$out"
}

for f in *.m; do
    [ -e "$f" ] || continue
    run "$f" run_objc "$f"
done

for f in *.swift; do
    [ -e "$f" ] || continue
    run "$f" swift "$f"
done

printf '\n\033[1m───────────────────────────\033[0m\n'
printf '通过 %d，失败 %d\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
    printf '失败的：%s\n' "${failed[*]}"
    exit 1
fi

cat <<'EOF'

提示：swift xxx.swift 走的是 -Onone。性能相关的结论请用 -O 重测，例如：
    swiftc -O swift-existential-generic.swift -o /tmp/eg && /tmp/eg
EOF
