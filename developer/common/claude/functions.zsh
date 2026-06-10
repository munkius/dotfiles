# nwt — launch a Claude Code worktree for a Linear issue, seeding
# `/start-development <KEY>` as the session's first prompt. The launcher lives
# in the nia-playbook and is distributed to every consumer repo as
# `scripts/playbook/nwt.mjs`, so this function just resolves the repo root and
# runs it. Run from a consumer repo's MAIN checkout (not from inside a worktree).
#
#   nwt nia-123                    # worktree name derived from the Linear title
#   nwt nia-123 short custom slug  # explicit description override
#   nwt nia-123 fix timeout --perm bypass   # set the launch permission mode
#
# --perm <mode>: auto (default, no flag → repo settings) | bypass | plan | accept | default
nwt() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "nwt: run this from inside a git repo (a nia-playbook consumer)" >&2
    return 1
  }
  local launcher="$root/scripts/playbook/nwt.mjs"
  if [[ ! -f "$launcher" ]]; then
    echo "nwt: $launcher not found — run 'npm run playbook:upgrade' (needs nia-playbook >= 0.93.0)" >&2
    return 1
  fi
  node "$launcher" "$@"
}
