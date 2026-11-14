#!/usr/bin/env bash
# Live demo of the ternary operator in this fork, one compiler stage at a time.
#
# Usage: ternary-demo/demo.sh [--no-pause]
#
# Press enter to move between steps. Step 1 compares against an unmodified
# Go: the first `go` on PATH, or set STOCK_GO=/path/to/go.
set -euo pipefail

demo_dir=$(cd "$(dirname "$0")" && pwd)
goroot=$(dirname "$demo_dir")
pause=1
[[ ${1:-} == --no-pause ]] && pause=0

stock_go=${STOCK_GO:-$(command -v go || true)}
[[ $stock_go == "$goroot/bin/go" ]] && stock_go=

if [[ ! -x $goroot/bin/go ]]; then
	echo "No toolchain at $goroot/bin/go. Build one first: cd $goroot/src && ./make.bash" >&2
	exit 1
fi

if [[ -t 1 ]]; then
	bold=$(tput bold) dim=$(tput dim) reset=$(tput sgr0)
else
	bold= dim= reset=
fi

step() { printf '\n%s== %s ==%s\n\n' "$bold" "$1" "$reset"; }
say() { printf '%s\n' "$@"; }
show() { printf '%s--- %s ---%s\n' "$dim" "$1" "$reset"; cat "$1"; echo; }
next() { if ((pause)); then read -rp "${dim}[enter]${reset}" _ </dev/tty; fi; }

# cmd DISPLAY [ACTUAL]: print DISPLAY as the command, then run ACTUAL (or DISPLAY).
# Failures don't stop the demo; some steps fail on purpose.
cmd() { printf '%s$ %s%s\n' "$bold" "$1" "$reset"; eval "${2:-$1}" || true; echo; }

open_file() {
	case $(uname) in
	Darwin) open "$1" ;;
	*) xdg-open "$1" >/dev/null 2>&1 || say "Open $PWD/$1 in a browser." ;;
	esac
}

# ir_for FUNC: keep FUNC's IR from "before order" up to "after walk", minus noise.
ir_for() {
	awk -v fn="$1" '$0 == "before order " fn {p = 1} $0 == "after walk " fn {exit} p' |
		sed -E -e 's/ (esc|tc)\([^)]*\)//g' -e 's/ (Class|Offset):[A-Z0-9]+//g' \
			-e 's/ (OnStack|Used|AutoTemp)//g' -e 's/ *# .*$//' -e 's/main\.\.?//g'
}

# asm_for FUNC [START]: FUNC's instructions from -S output, from the first one
# whose source position contains START up to its RET, with file paths shortened.
asm_for() {
	awk -v fn="$1" -v start="${2:-}" '
		$1 == fn && $2 == "STEXT" {p = 1; next}
		!p {next}
		/^[^\t]/ {exit}
		!/\.go:[0-9]+\)/ || /PCDATA|FUNCDATA/ {next}
		!on && (start == "" || index($0, start)) {on = 1}
		on {print}
		on && /\tRET/ {exit}' |
		sed -E 's#\([^)]*/([^/)]+)\)#(\1)#'
}

say "Rebuilding the compiler from this checkout..."
export GOROOT=$goroot PATH=$goroot/bin:$PATH
go install cmd/compile
export GO111MODULE=off GOFLAGS=

work=${TMPDIR:-/tmp}/ternary-demo
rm -rf "$work"
mkdir -p "$work"
cp "$demo_dir"/*.go "$work"
cd "$work"

step "1. Same file, two compilers"
show pick.go
next
if [[ -n $stock_go ]]; then
	cmd "$stock_go version" "env -u GOROOT $stock_go version"
	cmd "$stock_go run pick.go" "env -u GOROOT $stock_go run pick.go"
	next
fi
cmd "go version"
cmd "go run pick.go"
next

step "2. Type checking"
show errors.go
next
cmd "go run errors.go"
next

step "3. The order pass rewrites it as an if/else"
say "The compiler's IR for pick, before and after the order pass" \
	"(\"before walk\" is the same point as \"after order\")." ""
cmd "go build -gcflags=-W=2 -o /dev/null pick.go" \
	"go build -gcflags=-W=2 -o /dev/null pick.go 2>&1 | ir_for pick"
say "The TERNARY node is gone: order replaced it with an IF that assigns a" \
	"temporary in each branch, and returns the temporary."
next

step "4. Only the branch that's taken runs"
show sideeffects.go
next
cmd "go run sideeffects.go"
next

step "5. SSA, pass by pass"
cmd "GOSSAFUNC=pick go build -o /dev/null pick.go"
say "Each column in ssa.html is one optimization pass. The two branches merge" \
	"in a Phi; watch the branchelim pass replace it with a CondSelect."
open_file ssa.html
next

step "6. Machine code"
cmd "go build -gcflags=-S -o /dev/null pick.go" \
	"go build -gcflags=-S -o /dev/null pick.go 2>&1 | asm_for main.pick"
say "No branch at all: a single conditional select (CSEL on arm64, CMOV on amd64)," \
	"from an optimization pass nobody touched."
next
say "" "Now a ternary whose branches call functions:" ""
cmd "go build -gcflags=-S -o /dev/null sideeffects.go" \
	"go build -gcflags=-S -o /dev/null sideeffects.go 2>&1 | asm_for main.choose 'sideeffects.go:9)'"
say "branchelim leaves this one alone: it can't run both calls, so there's a real" \
	"branch. TBZ tests the condition and jumps to the else code; the then code" \
	"jumps over it; both meet at the RET. (loud was inlined, hence the printstrings.)"
next

step "Done"
say "That's one expression, from the scanner to machine code."
