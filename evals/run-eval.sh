#!/bin/bash
# Eval runner for senior-developer skill
# Usage: ./evals/run-eval.sh [eval-name] [model]
#
# Runs Claude in --print mode with the skill loaded, sends the eval query,
# and checks if the output mentions expected behaviors.
#
# Examples:
#   ./evals/run-eval.sh analysis-flow-basic
#   ./evals/run-eval.sh analysis-flow-basic haiku
#   ./evals/run-eval.sh all                    # run all evals

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MODEL="${2:-sonnet}"
EVAL_NAME="${1:-all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_single_eval() {
  local eval_file="$1"
  local name
  name=$(jq -r '.name' "$eval_file")
  local query
  query=$(jq -r '.query' "$eval_file")
  local description
  description=$(jq -r '.description' "$eval_file")

  echo ""
  echo -e "${YELLOW}━━━ Eval: ${name} ━━━${NC}"
  echo "  Description: ${description}"
  echo "  Query: ${query}"
  echo "  Model: ${MODEL}"
  echo ""

  # Run Claude with the skill loaded, in print mode
  local output
  output=$(cd "$REPO_DIR" && claude \
    --print \
    --model "$MODEL" \
    --plugin-dir "$REPO_DIR" \
    --dangerously-skip-permissions \
    "$query" 2>&1) || true

  # Check expected behaviors
  local expected
  expected=$(jq -r '.expected_behavior[]' "$eval_file")
  local pass_count=0
  local fail_count=0
  local total=0

  while IFS= read -r behavior; do
    total=$((total + 1))
    # Simple keyword check — not exact match, just presence of key concepts
    # Extract key words from the behavior (3+ char words)
    local keywords
    keywords=$(echo "$behavior" | tr ' ' '\n' | grep -E '.{4,}' | head -5 | tr '\n' '|' | sed 's/|$//')

    if echo "$output" | grep -iqE "$keywords" 2>/dev/null; then
      echo -e "  ${GREEN}PASS${NC} $behavior"
      pass_count=$((pass_count + 1))
    else
      echo -e "  ${RED}MISS${NC} $behavior"
      fail_count=$((fail_count + 1))
    fi
  done <<< "$expected"

  echo ""
  echo -e "  Result: ${pass_count}/${total} behaviors detected"

  if [ "$fail_count" -gt 0 ]; then
    echo -e "  ${RED}Some expected behaviors not detected in output${NC}"
    echo ""
    echo "  --- Raw output (first 50 lines) ---"
    echo "$output" | head -50 | sed 's/^/  | /'
    echo "  ---"
  fi

  return "$fail_count"
}

# Main
echo "Senior Developer Skill — Eval Runner"
echo "Model: ${MODEL}"

if [ "$EVAL_NAME" = "all" ]; then
  total_pass=0
  total_fail=0
  for f in "$SCRIPT_DIR"/*.json; do
    if run_single_eval "$f"; then
      total_pass=$((total_pass + 1))
    else
      total_fail=$((total_fail + 1))
    fi
  done
  echo ""
  echo "━━━ Summary ━━━"
  echo -e "  ${GREEN}Passed:${NC} ${total_pass}"
  echo -e "  ${RED}Failed:${NC} ${total_fail}"
else
  eval_file="$SCRIPT_DIR/${EVAL_NAME}.json"
  if [ ! -f "$eval_file" ]; then
    echo "Eval not found: ${eval_file}"
    exit 1
  fi
  run_single_eval "$eval_file"
fi
