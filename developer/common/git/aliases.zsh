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

alias gbd='git branch --merged | grep -v "\*" | grep -v "master" | xargs -n 1 git branch -d; git remote prune origin'
# gwd — gbd's worktree sibling: remove worktrees whose branch is already merged
# into master, delete the now-safe branch, then prune. The worktree dir is
# renamed aside (O(1) same-filesystem rename) and the actual `rm -rf` runs in the
# background, so a multi-GB node_modules doesn't block the shell for minutes.
# Worktrees with uncommitted/untracked changes are skipped (mirrors `git worktree
# remove`), as are the master/main worktrees.
gwd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gwd: not a git repository" >&2; return 1; }
  git worktree list --porcelain | awk '/^worktree /{w=$2} /^branch /{print w"\t"$2}' | \
    while IFS=$'\t' read -r wt ref; do
      br=${ref#refs/heads/}
      [[ "$br" == "master" || "$br" == "main" ]] && continue
      git merge-base --is-ancestor "$ref" master 2>/dev/null || continue
      if [[ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]]; then
        echo "gwd: skipping $wt (uncommitted changes)" >&2
        continue
      fi
      trash="${wt}.gwd-del.$$"
      if mv "$wt" "$trash" 2>/dev/null; then
        git worktree prune && git branch -d "$br"
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
