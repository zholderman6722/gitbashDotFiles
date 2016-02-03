#Bash profile to change the default terminal prompt and add some git information.
#David Barnes

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

export TERM=xterm-color
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# Color shortcuts
# Based on https://gist.github.com/joemaller/4503986
function RED        { echo "\e[0;31m$1\e[0m"; }
function GREEN      { echo "\e[0;32m$1\e[0m"; }
function YELLOW     { echo "\e[0;33m$1\e[0m"; }
function BLUE       { echo "\e[0;34m$1\e[0m"; }
function MAGENTA    { echo "\e[0;35m$1\e[0m"; }
function CYAN       { echo "\e[0;36m$1\e[0m"; }
function WHITE      { echo "\e[0;37m$1\e[0m"; }

function B_RED      { echo "\e[1;31m$1\e[0m"; }
function B_GREEN    { echo "\e[1;32m$1\e[0m"; }
function B_YELLOW   { echo "\e[1;33m$1\e[0m"; }
function B_BLUE     { echo "\e[1;34m$1\e[0m"; }
function B_MAGENTA  { echo "\e[1;35m$1\e[0m"; }
function B_CYAN     { echo "\e[1;36m$1\e[0m"; }
function B_WHITE    { echo "\e[1;37m$1\e[0m"; }

# Format for git_prompt_status()
BASH_THEME_GIT_PROMPT_UNMERGED=" $(RED unmerged)"
BASH_THEME_GIT_PROMPT_DELETED=" $(RED deleted)"
BASH_THEME_GIT_PROMPT_RENAMED=" $(YELLOW renamed)"
BASH_THEME_GIT_PROMPT_MODIFIED=" $(YELLOW modified)"
BASH_THEME_GIT_PROMPT_ADDED=" $(GREEN added)"
BASH_THEME_GIT_PROMPT_UNTRACKED=" $(WHITE untracked)"

function BASH_THEME_GIT_PROMPT_BRANCH { echo "$(CYAN $1)"; }
BASH_THEME_GIT_PROMPT_DIRTY=" $(B_RED \(*\))"
BASH_THEME_GIT_PROMPT_CLEAN=""

# Colors vary depending on time lapsed.
function BASH_THEME_GIT_TIME_SINCE_COMMIT_SHORT     { echo "$(GREEN $1)"; }
function BASH_THEME_GIT_TIME_SINCE_COMMIT_MEDIUM    { echo "$(B_YELLOW $1)"; }
function BASH_THEME_GIT_TIME_SINCE_COMMIT_LONG      { echo "$(B_RED $1)"; }
function BASH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL   { echo "$(CYAN $1)"; }

# Format for git_prompt_ahead()
BASH_THEME_GIT_PROMPT_AHEAD=" $(WHITE \()$(YELLOW ↑)$(WHITE \))"

# Format for git_prompt_long_sha() and git_prompt_short_sha()
BASH_THEME_GIT_PROMPT_SHA_BEFORE="$(YELLOW ::)"

current_branch () {
  local ref
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret="$?"
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return
    ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

# Outputs if current branch is ahead of remote
git_prompt_ahead () {
  if [[ -n "$(git rev-list origin/$(current_branch)..HEAD 2> /dev/null)" ]]; then
    echo "$BASH_THEME_GIT_PROMPT_AHEAD"
  fi
}

# Checks if working tree is dirty
parse_git_dirty () {
  local STATUS=''
  local FLAGS
  FLAGS=('--porcelain')
  if [[ "$(git config --get oh-my-zsh.hide-dirty)" != "1" ]]; then
    if [[ $POST_1_7_2_GIT -gt 0 ]]; then
      FLAGS+='--ignore-submodules=dirty'
    fi
    if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]; then
      FLAGS+='--untracked-files=no'
    fi
    STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
  fi
  if [[ -n $STATUS ]]; then
    echo "$BASH_THEME_GIT_PROMPT_DIRTY"
  else
    echo "$BASH_THEME_GIT_PROMPT_CLEAN"
  fi
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
git_time_since_commit () {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Only proceed if there is actually a commit.
    if [[ $(git log 2>&1 > /dev/null | grep -c "^fatal: bad default revision") == 0 ]]; then
      # Get the last commit.
      last_commit=`git log --pretty=format:'%at' -1 2> /dev/null`
      now=`date +%s`
      seconds_since_last_commit=$((now-last_commit))

      # Totals
      MINUTES=$((seconds_since_last_commit / 60))
      HOURS=$((seconds_since_last_commit/3600))

      # Sub-hours and sub-minutes
      DAYS=$((seconds_since_last_commit / 86400))
      SUB_HOURS=$((HOURS % 24))
      SUB_MINUTES=$((MINUTES % 60))
      function COLOR {
        if [[ -n $(git status -s 2> /dev/null) ]]; then
          if [ "$MINUTES" -gt 30 ]; then
            echo "$(BASH_THEME_GIT_TIME_SINCE_COMMIT_LONG $1)"
          elif [ "$MINUTES" -gt 10 ]; then
            echo "$(BASH_THEME_GIT_TIME_SINCE_COMMIT_MEDIUM $1)"
          else
            echo "$(BASH_THEME_GIT_TIME_SINCE_COMMIT_SHORT $1)"
          fi
        else
          echo "$(BASH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL $1)"
        fi
      }

      if [ "$HOURS" -gt 24 ]; then
        echo "$(COLOR ${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m)"
      elif [ "${MINUTES}" -gt 60 ]; then
        echo "$(COLOR ${HOURS}h${SUB_MINUTES}m)"
      else
        echo "$(COLOR ${MINUTES}m)"
      fi
    else
      echo ""
    fi
  fi
}

my_git_time () {
  echo " ($(git_time_since_commit))"
}

color_prompt=yes;
force_color_prompt=yes;

# old pos was after current_branch for... $(git_prompt_short_sha)
# old pos was before dirty status for...$(git_prompt_status)
git_custom_status () {
    local cb=$(current_branch)
    if [ -n "$cb" ]; then
        echo " on $(BASH_THEME_GIT_PROMPT_BRANCH $(current_branch))$(my_git_time)$(parse_git_dirty)$(git_prompt_ahead)"
    fi
}

git_prompt_command() {
    PS1="$(MAGENTA \\u) at $(YELLOW \\h) in $(B_BLUE \\w)$(git_custom_status)\n$(CYAN \>) "
}

PROMPT_COMMAND="git_prompt_command; $PROMPT_COMMAND"