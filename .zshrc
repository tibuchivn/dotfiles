# zmodload zsh/zprof
# Homebrew prefix — change this when moving to a new machine (e.g. /usr/local on Intel Mac)
BREW_PREFIX="/opt/homebrew"

# If you come from bash you might have to change your $PATH.F
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell" or "amuse"
# ZSH_THEME="honukai"

# ZSH_THEME="spaceship"

# # SPACESHIP_CHAR_SYMBOL="➜  "
# SPACESHIP_EXEC_TIME_SHOW="false"
# SPACESHIP_TIME_SHOW="true"
# SPACESHIP_TIME_PREFIX=""
# SPACESHIP_PROMPT_ADD_NEWLINE="true"
# SPACESHIP_PROMPT_DEFAULT_PREFIX="$USER"
# SPACESHIP_PROMPT_FIRST_PREFIX_SHOW="true"
# SPACESHIP_USER_SHOW="false"
# SPACESHIP_DIR_PREFIX=""
# # SPACESHIP_RUBY_SYMBOL="♦️"
# # GIT
# # Disable git symbol
# SPACESHIP_GIT_SYMBOL="" # disable git prefix
# # SPACESHIP_GIT_BRANCH_PREFIX="" # disable branch prefix too
# # Wrap git in `git:(...)`
# SPACESHIP_GIT_PREFIX='git:('
# SPACESHIP_GIT_SUFFIX=") "
# # SPACESHIP_GIT_BRANCH_SUFFIX="" # remove space after branch name
# # Unwrap git status from `[...]`
# # SPACESHIP_GIT_STATUS_PREFIX=""
# # SPACESHIP_GIT_STATUS_SUFFIX=""
# SPACESHIP_GIT_BRANCH_COLOR="blue"

# # NODE
# SPACESHIP_NODE_PREFIX="node:("
# SPACESHIP_NODE_SUFFIX=") "
# SPACESHIP_NODE_SYMBOL=""

# # RUBY
# SPACESHIP_RUBY_PREFIX="ruby:("
# SPACESHIP_RUBY_SUFFIX=") "
# SPACESHIP_RUBY_SYMBOL=""

# SPACESHIP_DOCKER_SHOW="false"
# SPACESHIP_PACKAGE_SHOW="false"

# SPACESHIP_PROMPT_ORDER=(
  # user          # Username section
  # dir           # Current directory section
  # host          # Hostname section
  # git           # Git section (git_branch + git_status)
  # hg            # Mercurial section (hg_branch  + hg_status)
  # package       # Package version
  # node          # Node.js section
  # ruby          # Ruby section
  # elixir        # Elixir section
  # xcode         # Xcode section
  # swift         # Swift section
  # golang        # Go section
  # php           # PHP section
  # rust          # Rust section
  # haskell       # Haskell Stack section
  # julia         # Julia section
  # docker        # Docker section
  # aws           # Amazon Web Services section
  # venv          # virtualenv section
  # conda         # conda virtualenv section
  # pyenv         # Pyenv section
  # dotnet        # .NET section
  # ember         # Ember.js section
  # terraform     # Terraform workspace section
  # exec_time     # Execution time
  # time          # Time stamps section
  # line_sep      # Line break
  # battery       # Battery level and status
  # vi_mode       # Vi-mode indicator
  # jobs          # Background jobs indicator
  # exit_code     # Exit code section
  # char          # Prompt character
# )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git tmux chucknorris zsh-autosuggestions)
plugins=(git tmux zsh-autosuggestions)

DISABLE_MAGIC_FUNCTIONS=true
ZSH_TMUX_AUTOSTART=false

# Skip compaudit security scan (saves ~70ms) — OMZ handles compinit once
ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh
source $BREW_PREFIX/opt/chruby/share/chruby/chruby.sh
source $BREW_PREFIX/opt/chruby/share/chruby/auto.sh
# chruby ruby-2.6.10

# fortune -s | cowsay -f ${$(cowsay -l | cut -f2 -d:)[($(gshuf -i 0-${#$(cowsay -l | cut -f2 -d:)[@]} -n 1))]}

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

ANTIGEN_MUTEX=false
# antigen removed — not loading any bundles, was causing startup warnings
# eval "$(thefuck --alias)"
# antigen bundle thewtex/tmux-mem-cpu-load
# antigen theme denysdovhan/spaceship-prompt

# eval "$(pyenv init --path)"

# export PATH=${PATH}:/usr/local/mysql/bin
export PATH=$PATH:/opt/local/bin
export PATH=$PATH:/usr/local/lib/node_modules
export PATH=/usr/local/sbin:$PATH
export PATH="$BREW_PREFIX/opt/git/bin:$PATH"

# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=false
# export PATH="/usr/local/bin:$PATH"
# export PATH="/Users/tungtram/Library/Python/3.7/bin:$PATH"

# export PATH="/usr/local/opt/python@3.7/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/Users/ttram/gocode
export PATH="$PATH:$GOPATH/bin"
# export PATH="/Users/ttram/elasticsearch/elasticsearch-5.6.16/bin:$PATH"
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

alias vi="vim"
alias n="nvim"
alias ci="circleci-cli"
alias rsp="bundle exec rails s -b 0.0.0.0"
alias rc="bundle exec rails console"
alias b="bundle install"
alias c="bundle exec cucumber"
alias migrate="unset DATABASE_URL && bundle exec rake db:migrate && RAILS_ENV=test bundle exec rake db:migrate"
alias testprepare="bundle exec rake db:test:prepare"
alias testmigrate="RAILS_ENV=test bundle exec rake db:migrate"
alias testdb="RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load db:migrate"
alias cow="fortune | cowsay"
alias 'today=calendar -A 0 -f /usr/share/calendar/calendar.mark | sort'
alias 'smart=diskutil info disk0 | grep SMART' # display SMART status of hard drive
alias apps='mdfind "kMDItemAppStoreHasReceipt=1"'
alias refreshbrew='brew outdated | while read cask; do brew upgrade $cask; done'
alias transvi='trans :vi'
alias tv='trans :vi'
# alias pyenv="source ~/gl-env/bin/activate"
alias pss="ps aux | grep"
alias rs="rspec -f d -c"
alias tiny="la | grep tiny"
alias unzipall='unzip "*.zip"'
alias aria='aria2c --enable-rpc=true --rpc-listen-all=true --rpc-allow-origin-all=true --rpc-secret=token --disable-ipv6=true'
alias ss='spotify status'
alias st='spotify stop'
alias sn='spotify next'
alias sp='spotify play'
alias sps='spotify share'
alias start_sa='eval "$(ssh-agent -s)"'
alias reswag='RAILS_ENV=test rake rswag:specs:swaggerize'
alias rmorig="find . -type f -name '*.orig' -delete"
alias gfco="git fco"
alias gfm="git fmerge"
alias gfrs="git freset"
alias tx="tmuxinator"
alias ls="eza"

alias k9sp='KUBECONFIG=~/tinypulse-production.yaml k9s -n production'
alias k9ss='KUBECONFIG=~/tinypulse-staging.yaml k9s -n tiny-staging'

export PATH="/usr/local/opt/qt@5.5/bin:$PATH"
# ~/.github_token không có trong backup 2026-10-20 → chỉ export khi file tồn tại
if [ -r "$HOME/.github_token" ]; then
  export BUNDLE_GITHUB__COM=$(<"$HOME/.github_token")
  export BUNDLE_RUBYGEMS__PKG__GITHUB__COM="x-access-token:$(<"$HOME/.github_token")"
fi

mkcdir()
{
  mkdir -p -- "$1" &&
  cd -P -- "$1"
}

# export PATH="/Users/tungtram/bin/Sencha/Cmd:$PATH"

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/Users/tungtram/Downloads/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/tungtram/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
# if [ -f '/Users/tungtram/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/tungtram/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# export CXXFLAGS="-mmacosx-version-min=10.9"
# export LDFLAGS="-mmacosx-version-min=10.9"
# export VIRTUALENVWRAPPER_PYTHON="/usr/local/opt/python@3.7/bin/python3"
# export VIRTUALENVWRAPPER_VIRTUALENV="/Users/ttram/Library/Python/3.7/bin/virtualenv"

export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
#source /usr/local/bin/virtualenvwrapper.sh
# export VIRTUALENVWRAPPER_SCRIPT=/Users/tungtram/Library/Python/3.7/bin/virtualenvwrapper.sh
# source /Users/tungtram/Library/Python/3.7/bin/virtualenvwrapper_lazy.sh

# alias pg_start="launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
# alias pg_stop="launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pg_start="launchctl load ~/Library/LaunchAgents"
alias pg_stop="launchctl unload ~/Library/LaunchAgents"

alias tngl="bundle exec tiny_golem"

alias kitty_update="curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin"
alias ip2loc='curl -s https://ipinfo.io/$(curl -s https://ipinfo.io/ip) | jq'
# alias brew_reinstall="brew list | xargs brew reinstall"

alias coin="coin_price"
export COIN_PRICE="bitcoin,matic-network,chiliz,enjincoin,tlm,tko,ftt"

alias nrd="npm run dev"

export METAPLEX_PATH="~/tung/solana/metaplex/js/packages/cli/src"
alias metaplex="ts-node $METAPLEX_PATH/candy-machine-v2-cli.ts"

alias glances="/Users/ttram/.local/bin/glances"
alias kill_md="launchctl unload /Library/LaunchAgents/com.microsoft.wdav.tray.plist"
alias hebi="hebikani"
alias create_release_mr='/Users/ttram/create-release-mr.sh -d "$(pwd)"'

export SKIM_DEFAULT_COMMAND='rg --files --hidden --follow -g "!.git/*" -g "!node_modules" -g "!tmp/*" -g "!**/*.min.js" -g "!**/*.min.css"'

export FZF_BASE="/Users/ttram/.fzf/bin/fzf"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!.git/*" -g "!node_modules" -g "!tmp/*" -g "!**/*.min.js" -g "!**/*.min.css"'
_gen_fzf_default_opts() {
  local base03="234"
  local base02="235"
  local base01="240"
  local base00="241"
  local base0="244"
  local base1="245"
  local base2="254"
  local base3="230"
  local yellow="136"
  local orange="166"
  local red="160"
  local magenta="125"
  local violet="61"
  local blue="33"
  local cyan="37"
  local green="64"

  # Comment and uncomment below for the light theme.

  # Solarized Dark color scheme for fzf
  export FZF_DEFAULT_OPTS="
  --reverse --bind up:preview-up,down:preview-down
  --color fg:-1,bg:-1,hl:$blue,fg+:$base2,bg+:$base02,hl+:$blue
  --color info:$yellow,prompt:$yellow,pointer:$base3,marker:$base3,spinner:$yellow
  "
  #
  # Solarized Light color scheme for fzf
  # export FZF_DEFAULT_OPTS="
   # --reverse --bind up:preview-up,down:preview-down
   # --color fg:-1,bg:-1,hl:$blue,fg+:$base02,bg+:$base2,hl+:$blue
   # --color info:$yellow,prompt:$yellow,pointer:$base03,marker:$base03,spinner:$yellow
  # "
}
_gen_fzf_default_opts
export EDITOR='nvim'

export FZF_COMPLETION_TRIGGER='~~'
export FZF_COMPLETION_OPTS='+c -x'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export PATH="/usr/local/opt/qt/bin:$PATH"
export PIP_NO_CACHE_DIR=off

export THOR_MERGE='nvim -d $1 $2'
# export THOR_MERGE='$BREW_PREFIX/bin/nvim -d $1 $2 -c "wincmd w" -c "wincmd J"'

# for solarized dark
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=23"
# for solarized light
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=180"

# fzf stuff
# Will return non-zero status if the current directory is not managed by git
# GIT heart FZF
# -------------

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% "$@" --border
}

fzf_gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

fzf_gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fzf_gt() {
  is_in_git_repo || return
  git recent |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

fzf_gg() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

fzf_gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local c
  for c in $@; do
    eval "fzf-g$c-widget() { local result=\$(fzf_g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^g^$c' fzf-g$c-widget"
  done
}

bind-git-helper f b t r g
unset -f bind-git-helper

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# workaround to disable bold promt for spaceship theme
# () {
  # local z=$'\0'
  # PROMPT='${${${$(spaceship_prompt)//\%\%/'$z'}//\%B}//'$z'/%%}'
# }

aws_force_deploy() {
  aws ecs update-service --cluster $1 --service $2 --force-new-deployment
}

railsc() {
  cluster=$1
  if [ -z "$1" ]
  then
    cluster=staging-engage
  fi

  service_name=$2
  if [ -z "$2" ]
  then
    service_name=console
  fi

  console_service=$(aws ecs list-services --cluster $cluster | jq -r "[.serviceArns[]|select(match(\"${service_name}\"))][0]")
  echo $console_service

  task=$(aws ecs list-tasks --cluster $cluster --service $console_service | jq -r '.taskArns[0]')
  echo $task
  # chamber_cluster=$(echo $cluster | tr - /)
  chamber_cluster=$(echo $cluster | sed 's/-/\//')

  container=$3
  if [ -z "$3" ]
  then
    container=engage
  fi
  aws ecs execute-command --cluster $cluster --region us-east-1 --task $task --container $container --command "chamber exec ${chamber_cluster} -- bundle exec rails console" --interactive
}

merge_test() {
  current_branch=$(git symbolic-ref HEAD --short)
  upper_branch=$1
  if [ -z "$1" ]
  then
    upper_branch=staging
  fi

  git checkout $upper_branch
  if [[ $? != 0 ]]; then
    echo "Failed to checkout $upper_branch"
    return
  fi
  git fetch origin
  git reset --hard FETCH_HEAD
  git merge --no-ff $current_branch
  git checkout $current_branch

  # read -p "Push $upper_branch to origin? (y/N) " push_upper
  read "push_upper?Push $upper_branch to origin? (y/N) "
  if [ "$push_upper" = "y" ]; then
    git push origin $upper_branch

    echo
    echo All done.
  fi

  return
}
touch2() { mkdir -p "$(dirname "$1")" && touch "$1" ; }

check_ruby_syntax() {
  local check_type="${1:-unstaged}"  # Default to unstaged if no argument provided
  local ruby_files
  local description

  case "$check_type" in
    "unstaged")
      ruby_files=$(git diff --name-only | grep '\.rb$')
      description="unstaged"
      ;;
    "staged")
      ruby_files=$(git diff --cached --name-only | grep '\.rb$')
      description="staged"
      ;;
    "both")
      # Combine both unstaged and staged files, removing duplicates
      ruby_files=$(git diff --name-only && git diff --cached --name-only | sort -u | grep '\.rb$')
      description="unstaged and staged"
      ;;
    *)
      echo "Usage: check_ruby_syntax [unstaged|staged|both]"
      echo "  unstaged: Check only unstaged files (default)"
      echo "  staged:   Check only staged files"
      echo "  both:     Check both unstaged and staged files"
      return 1
      ;;
  esac

  # Check if there are any Ruby files to process
  if [ -z "$ruby_files" ]; then
    echo "No $description Ruby files to check."
    return 0
  fi

  echo "Checking syntax for $description Ruby files..."
  echo ""

  local has_errors=false

  # Loop through each file using a while read loop
  while IFS= read -r file; do
    # Skip empty lines that might result from the command substitution
    if [ -z "$file" ]; then
        continue
    fi

    echo "Checking syntax for: $file"

    if [ -f "$file" ]; then
      local output
      output=$(ruby -c "$file" 2>&1)
      local exit_code=$?

      if [ $exit_code -ne 0 ]; then
        echo "----------------------------------------"
        printf "Syntax ERROR in: %s\n" "$file"
        printf "%s\n" "$output"
        echo "----------------------------------------"
        has_errors=true
      fi
    else
        printf "Warning: File '%s' listed by git but not found on disk.\n" "$file"
    fi
  done <<< "$ruby_files"

  # Final notification
  if [ "$has_errors" = true ]; then
    echo ""
    echo "Errors were found in one or more files."
    return 1
  else
    echo ""
    echo "All checked Ruby files have valid syntax."
    return 0
  fi
}

# Convenience wrapper functions
check_unstaged_ruby_syntax() {
  check_ruby_syntax "unstaged"
}

check_staged_ruby_syntax() {
  check_ruby_syntax "staged"
}

check_all_ruby_syntax() {
  check_ruby_syntax "both"
}

export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="$BREW_PREFIX/opt/python@3.9/libexec/bin:$PATH"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$BREW_PREFIX/opt/openssl@1.1"
export CARGO_NET_GIT_FETCH_WITH_CLI=true

export PATH="$BREW_PREFIX/opt/mysql@8.0/bin:$PATH"
export PATH="/Users/ttram/.pyenv/shims:${PATH}"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export ASDF_GOLANG_MOD_VERSION_ENABLED=true
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export KITTY_LISTEN_ON=unix:/tmp/mykitty
export MYSQL_PS1="(\u@\h) [\d]> "

export KUBECONFIG="$HOME/tinypulse-staging.yaml"

export DISABLE_AUTO_UPDATE="true"
export OPENCODE_DISABLE_CLAUDE_CODE_HOOKS=1

# . $BREW_PREFIX/opt/asdf/libexec/asdf.sh

unset GITHUB_TOKEN

# Add the following to the end of ~/.zshrc
# eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
# eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"

# ~/.local/bin/env do installer sinh ra (pipx/uv); máy mới chưa có → chỉ source khi tồn tại
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
# zprof

# bun completions
[ -s "/Users/ttram/.bun/_bun" ] && source "/Users/ttram/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/ttram/.antigravity-ide/antigravity-ide/bin:$PATH"

# Added by asterix-gittrace installer on Thu Oct  1 14:51:09 +07 2026
export PATH="/Users/ttram/.asterix-gittrace/bin:$PATH"

# ── Secrets (không track trong git) ──────────────────────────────────
# Copy .zsh_secrets.example -> ~/.zsh_secrets rồi điền giá trị.
[ -f "$HOME/.zsh_secrets" ] && source "$HOME/.zsh_secrets"
