#!/bin/bash
# Eval runner for work-on-issue skill
# Usage: ./evals/run-eval.sh [eval-name] [model] [judge-model]
#
# Runs Claude in --print mode with the skill loaded, sends the eval query,
# and uses an LLM judge to evaluate expected behaviors.
#
# Examples:
#   ./evals/run-eval.sh analysis-flow-basic
#   ./evals/run-eval.sh analysis-flow-basic sonnet
#   ./evals/run-eval.sh analysis-flow-basic sonnet haiku
#   ./evals/run-eval.sh all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MODEL="${2:-sonnet}"
EVAL_NAME="${1:-all}"
JUDGE_MODEL="${3:-haiku}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup_eval_env() {
  local eval_file="$1"
  local hide_tools
  hide_tools=$(jq -r '.setup_env.hide_tools // [] | .[]' "$eval_file" 2>/dev/null)

  EVAL_ENV_DIR=""
  if [ -n "$hide_tools" ]; then
    EVAL_ENV_DIR=$(mktemp -d)
    for tool in $hide_tools; do
      cat > "$EVAL_ENV_DIR/$tool" <<SHADOW
#!/bin/bash
echo "${tool}: command not found" >&2
exit 127
SHADOW
      chmod +x "$EVAL_ENV_DIR/$tool"
    done
  fi
}

cleanup_eval_env() {
  if [ -n "$EVAL_ENV_DIR" ] && [ -d "$EVAL_ENV_DIR" ]; then
    rm -rf "$EVAL_ENV_DIR"
  fi
}

judge_behaviors() {
  local output="$1"
  local eval_file="$2"

  local behaviors
  behaviors=$(jq -r '.expected_behavior[]' "$eval_file")

  # Build numbered list
  local behavior_list=""
  local i=1
  while IFS= read -r b; do
    behavior_list="${behavior_list}${i}. ${b}
"
    i=$((i + 1))
  done <<< "$behaviors"

  local judge_prompt="You are an eval judge. Given the output of a Claude skill invocation, determine whether each expected behavior was demonstrated.

<skill_output>
${output}
</skill_output>

<expected_behaviors>
${behavior_list}
</expected_behaviors>

For each numbered behavior, respond with exactly one line in this format:
PASS <number>
or
FAIL <number>

Only output PASS/FAIL lines, nothing else. A behavior PASSES if the output demonstrates or is consistent with that behavior. A behavior FAILS only if the output clearly contradicts it or shows no evidence of it."

  claude --print --model "$JUDGE_MODEL" "$judge_prompt" 2>/dev/null
}

run_single_eval() {
  local eval_file="$1"
  local name
  name=$(jq -r '.name' "$eval_file")
  local query
  query=$(jq -r '.query' "$eval_file")
  local description
  description=$(jq -r '.description' "$eval_file")

  setup_eval_env "$eval_file"

  echo ""
  echo -e "${YELLOW}━━━ Eval: ${name} ━━━${NC}"
  echo "  Description: ${description}"
  echo "  Query: ${query}"
  echo "  Model: ${MODEL}"
  echo "  Judge: ${JUDGE_MODEL}"
  echo ""

  # Run Claude with the skill loaded, in print mode
  local eval_path="$PATH"
  if [ -n "$EVAL_ENV_DIR" ]; then
    eval_path="$EVAL_ENV_DIR:$PATH"
  fi

  local output
  output=$(cd "$REPO_DIR" && PATH="$eval_path" claude \
    --print \
    --model "$MODEL" \
    --plugin-dir "$REPO_DIR" \
    --dangerously-skip-permissions \
    "$query" 2>&1) || true

  cleanup_eval_env

  # Judge expected behaviors using LLM
  local judge_output
  judge_output=$(judge_behaviors "$output" "$eval_file")

  local pass_count=0
  local fail_count=0
  local total=0
  local i=1

  while IFS= read -r behavior; do
    total=$((total + 1))
    if echo "$judge_output" | grep -qE "^PASS ${i}$|^PASS ${i} "; then
      echo -e "  ${GREEN}PASS${NC} $behavior"
      pass_count=$((pass_count + 1))
    else
      echo -e "  ${RED}FAIL${NC} $behavior"
      fail_count=$((fail_count + 1))
    fi
    i=$((i + 1))
  done <<< "$(jq -r '.expected_behavior[]' "$eval_file")"

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
echo "Judge: ${JUDGE_MODEL}"

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
