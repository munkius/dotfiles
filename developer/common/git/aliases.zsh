# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
hub_path=$(which hub)
if (( $+commands[hub] ))
then
  alias git=$hub_path
fi

# The rest of my fun git aliases
alias gl='git pull --prune'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push origin HEAD'

# Remove `+` and `-` from start of diff lines; just rely upon color.
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'

# gbd / gwd: clean up local branches and worktrees whose work has LANDED.
#
# "Landed" is decided per branch, and never by "upstream gone" alone: a PR that is
# CLOSED without merging also loses its remote branch, and the old `-D` on [gone]
# deleted that unmerged work. A branch has landed when ONE of these holds:
#   1. its tip is an ancestor of origin's default branch (classic merge, ff);
#   2. GitHub has a MERGED PR with the SAME head name (into ANY base, so epic/stacked
#      merges count) and the local tip is that PR's head, or every local commit is on
#      origin, or the local tip is older than the merge (pre-squash / pre-rebase
#      originals);
#   3. backup branches (backup/*, backup-*, *-backup*, *-bak*, *-pre-*): every commit
#      is on origin, or the branch they back up has landed. The original is derived
#      from the name both as-is and with the first `-` after a known prefix (feature,
#      fix, ...) turned back into `/`, because `mynia squash` writes
#      backup/<branch with every / replaced by ->-pre-squash-<stamp>. A name such as
#      backup-2376 has no original to find: only "every commit on origin" releases it;
#   4. `git cherry` lists no `+` line: every commit is in the default branch by
#      content (rebases, cherry-picks). Squashed branches are NOT landed by any other
#      heuristic.
# Unpushed work that matches none of these is KEPT and listed, never deleted.
# Needs `gh` for rule 2; without it rules 1, 3 (via origin or a local original) and 4
# still apply. gwd treats a worktree whose only uncommitted change is package-lock.json
# as clean (an `npm install` at session start rewrites it).
# Both take -n for a dry run.

# merged PRs of this repo: headRefName \t headRefOid \t mergedAt (epoch)
_git_merged_prs() {
  command -v gh >/dev/null 2>&1 || return 0
  gh pr list --state merged --limit 10000 \
    --json headRefName,headRefOid,mergedAt \
    --jq '.[] | "\(.headRefName)\t\(.headRefOid)\t\(.mergedAt | fromdateiso8601)"' 2>/dev/null
}

# _git_content_landed <branch> <default-ref>: ancestor of base, or no `+` in git cherry
_git_content_landed() {
  local tip
  tip=$(git rev-parse -q --verify "refs/heads/$1") || return 1
  git merge-base --is-ancestor "$tip" "$2" 2>/dev/null && { _GIT_WHY="in ${2#origin/}"; return 0; }
  git cherry "$2" "$tip" 2>/dev/null | grep -q '^+' && return 1
  _GIT_WHY="every commit is in ${2#origin/} by content"
  return 0
}

# _git_backup_originals <backup-branch>: candidate names of the branch it backs up
_git_backup_originals() {
  local orig=$1 p
  orig=${orig#backup/}; orig=${orig#backup-}
  orig=${orig%%-backup*}; orig=${orig%%-bak*}; orig=${orig%%-pre-*}
  [[ -n "$orig" && "$orig" != <-> ]] || return 0
  print -r -- "$orig"
  for p in feature fix feat chore docs refactor test claude munkius worktree nia; do
    [[ "$orig" == $p-* ]] && { print -r -- "$p/${orig#$p-}"; break; }
  done
}

# _git_landed <branch> <default-ref> ; reads the PR table from $_GIT_PRS
_git_landed() {
  local br=$1 base=$2 tip tdate line oid merged off orig
  tip=$(git rev-parse -q --verify "refs/heads/$br") || return 1
  git merge-base --is-ancestor "$tip" "$base" 2>/dev/null && { _GIT_WHY="in ${base#origin/}"; return 0; }
  off=$(git rev-list --count "$tip" --not --remotes=origin 2>/dev/null)
  tdate=$(git log -1 --format=%ct "$tip")
  _git_pr_landed() {
    line=$(print -r -- "$_GIT_PRS" | awk -F'\t' -v b="$1" '$1==b' | sort -t$'\t' -k3 -n | tail -1)
    [[ -z "$line" ]] && return 1
    oid=${${line#*$'\t'}%%$'\t'*}; merged=${line##*$'\t'}
    [[ "$tip" == "$oid" || "$off" == "0" || "$tdate" -le "$merged" ]]
  }
  if _git_pr_landed "$br"; then _GIT_WHY="PR merged"; return 0; fi
  if [[ "$br" == backup/* || "$br" == backup-* || "$br" == *-backup* || "$br" == *-bak* || "$br" == *-pre-* ]]; then
    [[ "$off" == "0" ]] && { _GIT_WHY="backup, all on origin"; return 0; }
    for orig in ${(f)"$(_git_backup_originals "$br")"}; do
      _git_pr_landed "$orig" && { _GIT_WHY="backup of landed $orig"; return 0; }
      if _git_content_landed "$orig" "$base"; then _GIT_WHY="backup of landed $orig"; return 0; fi
    done
  fi
  if _git_content_landed "$br" "$base"; then return 0; fi
  return 1
}

_git_default_ref() {
  local d
  d=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  print -r -- "${d:-origin/master}"
}

gbd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gbd: not a git repository" >&2; return 1; }
  local dry=0; [[ "$1" == "-n" ]] && dry=1
  git fetch --prune --quiet
  local base cur br kept=0 _GIT_WHY
  base=$(_git_default_ref); cur=$(git symbolic-ref --short -q HEAD)
  _GIT_PRS=$(_git_merged_prs)
  # branches checked out in ANY worktree are gwd's business, not gbd's
  local -a inwt
  inwt=(${(f)"$(git worktree list --porcelain | awk '/^branch /{sub("refs/heads/","",$2); print $2}')"})
  for br in ${(f)"$(git for-each-ref --format='%(refname:short)' refs/heads)"}; do
    [[ "$br" == (master|main|develop) || "$br" == "$cur" ]] && continue
    (( ${inwt[(Ie)$br]} )) && continue
    if _git_landed "$br" "$base"; then
      if (( dry )); then echo "would delete  $br ($_GIT_WHY)"
      else git branch -D "$br" >/dev/null && echo "deleted  $br ($_GIT_WHY)"; fi
    else
      kept=$((kept+1))
    fi
  done
  echo "gbd: kept $kept branch(es) that have not landed (see: git branch -vv)"
}

gwd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gwd: not a git repository" >&2; return 1; }
  local dry=0; [[ "$1" == "-n" ]] && dry=1
  git fetch --prune --quiet
  local base main wt ref lock br off trash _GIT_WHY
  base=$(_git_default_ref)
  _GIT_PRS=$(_git_merged_prs)
  main=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
  # one line per worktree: path \t branch-or-(detached) \t locked?
  git worktree list --porcelain | awk '
    /^worktree /{w=$2; b="(detached)"; l="-"} /^branch /{b=$2} /^locked/{l="locked"}
    /^$/{print w "\t" b "\t" l} END{if (w) print w "\t" b "\t" l}' | sort -u | \
  while IFS=$'\t' read -r wt ref lock; do
    [[ "$wt" == "$main" ]] && continue
    # a locked worktree belongs to a live session (claude -w / nwt): never touch it
    [[ "$lock" == locked ]] && { echo "gwd: keep  $wt (locked by a session)" >&2; continue; }
    [[ -d "$wt" ]] || continue
    # package-lock.json alone does not count: an `npm install` rewrites it
    if [[ -n "$(git -C "$wt" status --porcelain -uno 2>/dev/null | grep -Ev '^.. (.*/)?package-lock\.json$')" ]]; then
      echo "gwd: keep  $wt (uncommitted changes)" >&2; continue
    fi
    br=${ref#refs/heads/}
    if [[ "$br" == "(detached)" ]]; then
      off=$(git -C "$wt" rev-list --count HEAD --not --remotes=origin 2>/dev/null)
      [[ "$off" == "0" ]] || { echo "gwd: keep  $wt (detached, $off commit(s) on no remote)" >&2; continue; }
      _GIT_WHY="detached, all on origin"
    else
      [[ "$br" == (master|main|develop) ]] && continue
      _git_landed "$br" "$base" || continue
    fi
    if (( dry )); then echo "would remove  $wt ($_GIT_WHY)"; continue; fi
    trash="${wt}.gwd-del.$$"
    if mv "$wt" "$trash" 2>/dev/null; then
      git worktree prune
      [[ "$br" != "(detached)" ]] && git branch -D "$br" >/dev/null
      echo "removed  $wt ($_GIT_WHY)"
      rm -rf "$trash" &!   # background delete; shell returns immediately
    fi
  done
}
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git checkout master'
alias gco='git checkout'
alias gcb='git copy-branch-name'
alias gb='git branch'
alias gs='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gac='git add -A && git commit -m'
alias ge='git-edit-new'
