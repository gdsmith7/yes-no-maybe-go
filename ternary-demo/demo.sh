#!/usr/bin/env bash
# Live demo of the ternary operator in this fork.
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

say "Rebuilding the compiler from this checkout..."
export GOROOT=$goroot PATH=$goroot/bin:$PATH
go install cmd/compile
export GO111MODULE=off GOFLAGS=

# Run from a scratch directory so the demo leaves nothing in the repo.
rm -rf "${TMPDIR:-/tmp}"/ternary-demo.*
work=$(mktemp -d "${TMPDIR:-/tmp}/ternary-demo.XXXXXX")
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

step "3. Only the branch that's taken runs"
show sideeffects.go
next
cmd "go run sideeffects.go"

step "Done"
