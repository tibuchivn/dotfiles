#!/bin/bash
# Two-line Claude Code status line.
# Line 1: folder (blue) | git branch (normal color, omitted outside a repo)
# Line 2: [Model]: context-usage% progress bar | estimated cost | caveman stats

input=$(cat)

result=$(STATUSLINE_JSON="$input" python3 <<'PYEOF'
import json, os

try:
    data = json.loads(os.environ.get("STATUSLINE_JSON") or "{}")
except Exception:
    data = {}

def price_for(mid):
    m = (mid or "").lower()
    if "opus" in m:
        return 15, 75
    if "haiku" in m:
        return 1, 5
    return 3, 15  # sonnet / default

workspace = data.get("workspace") or {}
cwd = workspace.get("current_dir") or data.get("cwd") or os.getcwd()

model = data.get("model") or {}
model_name = model.get("display_name") or model.get("id") or "Claude"
model_id = model.get("id") or ""

transcript_path = data.get("transcript_path") or ""

total_input = total_output = total_cache_create = total_cache_read = context_used = 0
if transcript_path and os.path.isfile(transcript_path):
    try:
        last_usage = None
        with open(transcript_path, "r", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                usage = (obj.get("message") or {}).get("usage")
                if not usage:
                    continue
                total_input += usage.get("input_tokens", 0) or 0
                total_output += usage.get("output_tokens", 0) or 0
                total_cache_create += usage.get("cache_creation_input_tokens", 0) or 0
                total_cache_read += usage.get("cache_read_input_tokens", 0) or 0
                last_usage = usage
        if last_usage:
            context_used = ((last_usage.get("input_tokens", 0) or 0)
                + (last_usage.get("cache_creation_input_tokens", 0) or 0)
                + (last_usage.get("cache_read_input_tokens", 0) or 0))
    except Exception:
        pass

context_limit = 200000
pct = int(context_used * 100 / context_limit) if context_limit else 0
pct = max(0, min(100, pct))

# Prefer Claude Code's own session cost (same basis as /cost & /usage);
# fall back to token estimate only if it's absent.
cc_cost = ((data.get("cost") or {}).get("total_cost_usd"))
if cc_cost is not None:
    cost = float(cc_cost)
else:
    pin, pout = price_for(model_id)
    cost = (total_input * pin + total_cache_create * pin * 1.25
            + total_cache_read * pin * 0.1 + total_output * pout) / 1_000_000

# ---- Real monthly spend + limit from /usage cache ----
spend_used = spend_limit = -1.0
spend_pct = -1
try:
    with open(os.path.expanduser("~/.claude.json"), "r", errors="ignore") as f:
        cj = json.load(f)
    spend = (((cj.get("cachedUsageUtilization") or {}).get("utilization") or {}).get("spend") or {})
    used = spend.get("used") or {}
    lim = spend.get("limit") or {}
    if used.get("amount_minor") is not None:
        spend_used = used["amount_minor"] / (10 ** (used.get("exponent", 2)))
    if lim.get("amount_minor") is not None:
        spend_limit = lim["amount_minor"] / (10 ** (lim.get("exponent", 2)))
    if spend.get("percent") is not None:
        spend_pct = int(spend["percent"])
except Exception:
    pass

print("\x1f".join([cwd, model_name, str(pct), f"{cost:.4f}",
                   f"{spend_used:.2f}", f"{spend_limit:.2f}", str(spend_pct)]))
PYEOF
)

IFS=$'\x1f' read -r dir model_name pct cost spend_used spend_limit spend_pct <<< "$result"
[ -z "$dir" ] && dir=$(pwd)

# ---------- Line 1: folder + branch ----------
# display_dir="${dir/#$HOME/~}"
# line1=$(printf '\033[34m📁 %s\033[0m' "$display_dir")

# branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
# [ -n "$branch" ] && line1="${line1} | 🌿 ${branch}"

# ---------- Line 2: model + usage bar + cost + caveman stats ----------
bar_len=10
filled=$(( pct * bar_len / 100 ))
empty=$(( bar_len - filled ))
bar=""
[ "$filled" -gt 0 ] && bar=$(printf '%0.s█' $(seq 1 "$filled"))
bar_empty=""
[ "$empty" -gt 0 ] && bar_empty=$(printf '%0.s░' $(seq 1 "$empty"))

CYAN_BLUE='\033[38;5;51m'
NEON_YELLOW='\033[38;5;226m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

if [ "$pct" -ge 80 ]; then
  USAGE_COLOR="$RED"
elif [ "$pct" -ge 50 ]; then
  USAGE_COLOR="$YELLOW"
else
  USAGE_COLOR="$GREEN"
fi

line2=$(printf "${CYAN_BLUE}[%s]${RESET}: ${USAGE_COLOR}%s%% [%s%s]${RESET} | ${NEON_YELLOW}💰 \$%s${RESET}" "$model_name" "$pct" "$bar" "$bar_empty" "$cost")

# Monthly spend segment (real /usage data), only if cache present
if [ -n "$spend_pct" ] && [ "$spend_pct" -ge 0 ] 2>/dev/null; then
  if [ "$spend_pct" -ge 90 ]; then
    SPEND_COLOR="$RED"
  elif [ "$spend_pct" -ge 70 ]; then
    SPEND_COLOR="$YELLOW"
  else
    SPEND_COLOR="$GREEN"
  fi
  line2="${line2}$(printf " | ${SPEND_COLOR}📅 \$%s/\$%s (%s%%)${RESET}" "$spend_used" "$spend_limit" "$spend_pct")"
fi

printf '%s\n%s\n' "$line1" "$line2"
