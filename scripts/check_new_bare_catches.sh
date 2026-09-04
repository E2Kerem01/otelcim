#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-${GITHUB_BASE_REF:-}}"
if [[ -z "$base_ref" ]]; then
  echo "error: pass the PR base branch (for example: $0 main)" >&2
  exit 2
fi

merge_base="$(git merge-base "origin/$base_ref" HEAD)"

git diff --unified=20 --no-ext-diff --diff-filter=ACMR \
  "$merge_base" HEAD -- ':(glob)lib/**/*.dart' |
awk '
function finish() {
  if (!pending) return
  if (body !~ /(logError|mapToFailure)[[:space:]]*\(/ && body !~ /(^|[^[:alnum:]_])rethrow([^[:alnum:]_]|$)/) {
    printf "  %s:%d: %s\n", catch_file, catch_line, catch_text > "/dev/stderr"
    violations++
  }
  pending = 0; body = ""; depth = 0; opened = 0
}
function consume(text, braces, opens, closes) {
  body = body "\n" text
  braces = text
  opens = gsub(/\{/, "{", braces)
  braces = text
  closes = gsub(/\}/, "}", braces)
  if (opens) opened = 1
  depth += opens - closes
  if (opened && depth <= 0) finish()
}
/^diff --git / { finish(); next }
/^\+\+\+ b\// { file = substr($0, 7); next }
/^@@ / {
  finish()
  header = $0
  sub(/^.*\+/, "", header); sub(/[, ].*$/, "", header)
  new_line = header + 0
  next
}
/^-/ { next }
/^[+ ]/ {
  marker = substr($0, 1, 1)
  text = substr($0, 2)
  line = new_line++

  if (pending) consume(text)
  if (!pending && marker == "+" && text ~ /(^|[^[:alnum:]_])catch[[:space:]]*\(/) {
    pending = 1
    catch_file = file; catch_line = line; catch_text = text
    catch_part = text
    sub(/^.*catch[[:space:]]*\(/, "catch(", catch_part)
    consume(catch_part)
  }
}
END {
  finish()
  if (violations) {
    print "New catch blocks must call logError(...), mapToFailure(...), or rethrow." > "/dev/stderr"
    exit 1
  }
}
'
