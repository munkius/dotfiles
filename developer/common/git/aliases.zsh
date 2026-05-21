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
# into master, delete the now-safe branch, then prune stale worktree entries.
# Dirty worktrees and the main worktree are skipped (git refuses to remove them).
gwd() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "gwd: not a git repository" >&2; return 1; }
  git worktree list --porcelain | awk '/^worktree /{w=$2} /^branch /{print w"\t"$2}' | \
    while IFS=$'\t' read -r wt ref; do
      br=${ref#refs/heads/}
      [[ "$br" == "master" || "$br" == "main" ]] && continue
      git merge-base --is-ancestor "$ref" master 2>/dev/null && \
        git worktree remove "$wt" && git branch -d "$br"
    done
  git worktree prune
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
