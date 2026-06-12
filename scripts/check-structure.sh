#!/usr/bin/env bash
# Structural validation for the ultimatepowers plugin.
# Checks: SKILL.md frontmatter, namespace-ref resolution, stale superpowers refs,
# manifest parse + path fields, hook executability, formal-verification surface.
set -uo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
err() { printf 'FAIL: %s\n' "$*"; FAIL=1; }
ok()  { printf 'ok: %s\n' "$*"; }

# 1. Frontmatter: exactly name + description on every SKILL.md; name == dir name
for f in skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  fm=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$f")
  keys=$(printf '%s\n' "$fm" | grep -E '^[A-Za-z_-]+:' | cut -d: -f1 | sort | tr '\n' ' ')
  [ "$keys" = "description name " ] || err "$f frontmatter keys '$keys' (want exactly: description name)"
  name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p')
  [ "$name" = "$dir" ] || err "$f frontmatter name '$name' != directory '$dir'"
done
ok "frontmatter (name+description, name==dir) on $(ls skills | wc -l) skills"

# 2. Every ultimatepowers:<x> reference resolves to skills/<x>/
for r in $(grep -rhoE 'ultimatepowers:[a-z0-9-]+' skills/ hooks/ tests/ 2>/dev/null | sort -u); do
  s=${r#ultimatepowers:}
  [ -d "skills/$s" ] || err "reference '$r' does not resolve to skills/$s/"
done
ok "all ultimatepowers:<skill> references resolve"

# 3. Zero superpowers: (colon-form) refs outside the allowlist
hits=$(grep -rn 'superpowers:' . \
  --exclude-dir=.git --exclude-dir=reference --exclude-dir=docs \
  --exclude-dir=node_modules --exclude-dir=.worktrees \
  --exclude=LICENSE --exclude=README.md --exclude=CLAUDE.md \
  --exclude=check-structure.sh 2>/dev/null)
[ -z "$hits" ] || err "stale superpowers: references: $hits"
ok "no stale superpowers: references"

# 4. Manifests parse and their path fields resolve
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json \
         .codex-plugin/plugin.json .cursor-plugin/plugin.json \
         gemini-extension.json package.json .version-bump.json \
         hooks/hooks.json hooks/hooks-cursor.json; do
  jq empty "$j" 2>/dev/null || err "$j does not parse as JSON"
done
[ "$(jq -r .name .claude-plugin/plugin.json)" = "ultimatepowers" ] || err "plugin.json name != ultimatepowers"
[ "$(jq -r .name .claude-plugin/marketplace.json)" = "ultimatepowers-dev" ] || err "marketplace name != ultimatepowers-dev"
[ "$(jq -r '.plugins[0].source' .claude-plugin/marketplace.json)" = "./" ] || err "marketplace plugin source != ./"
[ -d "$(jq -r .skills .cursor-plugin/plugin.json)" ] || err "cursor skills path missing"
[ -f "$(jq -r .hooks .cursor-plugin/plugin.json)" ] || err "cursor hooks path missing"
[ "$(jq -r '.agents // empty' .cursor-plugin/plugin.json)" = "" ] || err "cursor manifest has stale agents pointer"
[ "$(jq -r '.commands // empty' .cursor-plugin/plugin.json)" = "" ] || err "cursor manifest has stale commands pointer"
[ -d "$(jq -r .skills .codex-plugin/plugin.json)" ] || err "codex skills path missing"
[ -f "$(jq -r .interface.composerIcon .codex-plugin/plugin.json)" ] || err "codex composerIcon missing"
[ -f "$(jq -r .interface.logo .codex-plugin/plugin.json)" ] || err "codex logo missing"
[ -f "$(jq -r .main package.json)" ] || err "package.json main missing"
[ -f "$(jq -r .contextFileName gemini-extension.json)" ] || err "gemini contextFileName missing"
ok "manifests parse; path fields resolve; stale cursor pointers absent"

# 5. Hook files executable
[ -x hooks/session-start ] || err "hooks/session-start not executable"
[ -x hooks/run-hook.cmd ] || err "hooks/run-hook.cmd not executable"
bash -n hooks/session-start || err "hooks/session-start has bash syntax errors"
ok "hook files executable and parse"

# 6. Formal-verification surface present and wired
for p in skills/formal-reasoning-foundations/SKILL.md \
         skills/formal-reasoning-foundations/references/claim-shapes.md \
         skills/formalizing-code/SKILL.md \
         skills/verifying-specs/SKILL.md \
         skills/formal-code-review/SKILL.md \
         skills/requesting-code-review/formal-reviewer.md \
         skills/subagent-driven-development/formal-verification-reviewer-prompt.md; do
  [ -f "$p" ] || err "missing $p"
done
grep -q 'formal-reviewer.md' skills/requesting-code-review/SKILL.md \
  || err "requesting-code-review/SKILL.md not wired to formal-reviewer.md"
grep -q 'formal-verification-reviewer-prompt.md' skills/subagent-driven-development/SKILL.md \
  || err "subagent-driven-development/SKILL.md not wired to formal-verification-reviewer-prompt.md"
grep -q 'ultimatepowers:formal-code-review' skills/using-superpowers/SKILL.md \
  || err "using-superpowers/SKILL.md missing formal-review mention"
grep -q 'docs/ultimatepowers/verification/' skills/requesting-code-review/formal-reviewer.md \
  || err "formal-reviewer.md missing artifact persistence path"
grep -q 'constructed, not machine-checked' skills/requesting-code-review/formal-reviewer.md \
  || err "formal-reviewer.md missing honesty status label"
ok "formal-verification surface present and wired"

if [ "$FAIL" -ne 0 ]; then echo "STRUCTURE CHECK FAILED"; exit 1; fi
echo "STRUCTURE CHECK PASSED"
