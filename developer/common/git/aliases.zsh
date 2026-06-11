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

# gbd — delete local branches that have already landed on master. Catches both
# classic merges (branch tip is an ancestor of master) AND squash-merges (the PR
# landed as one new commit, so the tip is NOT an ancestor — detected via the
# upstream tracking ref being gone after a prune). Protected branches and the
# current branch are never touched. `--format` is used so the `*`/`+` prefixes
# git puts on the current/worktree branches don't leak into `git branch -d` (the
# old pipe-through-grep version tripped on `+` and errored `branch '+' not found`).
gbd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gbd: not a git repository" >&2; return 1; }
  git fetch --prune --quiet
  local cur protected
  cur=$(git symbolic-ref --short -q HEAD)
  protected="master|main|develop|${cur:-master}"
  # 1. classic merge / fast-forward: safe `-d` (git refuses if not truly merged)
  git branch --merged master --format='%(refname:short)' | grep -vxE "$protected" | \
    while read -r br; do git branch -d "$br" && echo "deleted (merged)   $br"; done
  # 2. squash-merged: upstream gone after prune → force `-D`. Skip ancestors
  # (already handled by step 1), so `-D` only ever fires on genuine squash-merges.
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | \
    awk '$2=="[gone]"{print $1}' | grep -vxE "$protected" | \
    while read -r br; do
      git merge-base --is-ancestor "refs/heads/$br" master 2>/dev/null && continue
      git branch -D "$br" && echo "deleted (squashed) $br"
    done
}
# gwd — gbd's worktree sibling: remove worktrees whose branch has already landed
# on master (classic merge OR squash-merge, same detection as gbd), delete the
# now-safe branch, then prune. The worktree dir is renamed aside (O(1)
# same-filesystem rename) and the actual `rm -rf` runs in the background, so a
# multi-GB node_modules doesn't block the shell for minutes. Worktrees with
# uncommitted *tracked* changes are skipped; untracked files (e.g. node_modules)
# do NOT block removal. The master/main/develop worktrees are always kept.
gwd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gwd: not a git repository" >&2; return 1; }
  git fetch --prune --quiet
  git worktree list --porcelain | awk '/^worktree /{w=$2} /^branch /{print w"\t"$2}' | \
    while IFS=$'\t' read -r wt ref; do
      br=${ref#refs/heads/}
      [[ "$br" == "master" || "$br" == "main" || "$br" == "develop" ]] && continue
      # merged the classic way, OR squash-merged (upstream gone after prune)?
      if ! git merge-base --is-ancestor "$ref" master 2>/dev/null; then
        [[ "$(git for-each-ref --format='%(upstream:track)' "$ref")" == "[gone]" ]] || continue
      fi
      if [[ -n "$(git -C "$wt" status --porcelain -uno 2>/dev/null)" ]]; then
        echo "gwd: skipping $wt (uncommitted changes)" >&2
        continue
      fi
      trash="${wt}.gwd-del.$$"
      if mv "$wt" "$trash" 2>/dev/null; then
        git worktree prune && git branch -D "$br"
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
