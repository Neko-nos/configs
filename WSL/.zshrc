# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zplug
source ~/.zplug/init.zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug romkatv/powerlevel10k, as:theme, depth:1
## 補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
## Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
## Then, source plugins and add commands to $PATH
zplug load --verbose

# 補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*:default' menu select=1
setopt autoremoveslash # ディレクトリの補完時に最後に/を残さない
setopt no_beep         # 補完候補がない場合等でビープ音を鳴らさない

# typoの指摘
setopt correct
setopt correct_all

# history関連
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups # 重複するコマンドは古いほうを削除する
setopt hist_ignore_dups     # 直前と同じなら追加しない
setopt share_history        # share command history data
setopt append_history       # zsh_hisotryをreplaceせずに追加する
setopt inc_append_history   # add new history lines incrementally
setopt hist_no_store        # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks   # 余分な空白は詰めて記録

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# peco
## 通常のhistory検索
function peco-select-history() {
  BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history
## cdr対応
function peco-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N peco-cdr
bindkey '^E' peco-cdr

# lsや補完に色を付ける
eval $(dircolors ~/.dircolors-solarized/dircolors.ansi-light)
if [ -n "$LS_COLORS" ]; then
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

# key設定
# 参考: https://unix.stackexchange.com/questions/58870/ctrl-left-right-arrow-keys-issue
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# alias設定
## ls
## ref: https://atmarkit.itmedia.co.jp/ait/articles/1606/28/news021.html
alias ls='ls -AX --color=auto'
## cd系
alias ...='cd ../..'
alias ....='cd ../../..'
## tree系
## ref: https://atmarkit.itmedia.co.jp/ait/articles/1802/01/news025.html
alias tree='tree -aCq -I ".git|.ruff_cache|.venv|env|venv|__pycache__"'
## 名前をtreeと被せると再帰関数になってしまう
alias ctree='_custom_tree'
# ref: https://qiita.com/osw_nuco/items/a5d7173c1e443030875f
function _custom_tree() {
    # ホームディレクトリでalias済みのtreeを打つと大量のファイルが表示されるので制限する
    if [[ "$PWD" == "$HOME" ]]; then
        tree -L 2 "$@"
    else
        tree "$@"
    fi
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Path
## pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
## Poetry
export PATH="/home/neko/.local/bin:$PATH"
## CUDA
export PATH=/usr/local/cuda:/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
## TensorFlow
### デフォルトだとlogが全て出てくる
### ref: https://70vps.net/wsl-19.html
export TF_CPP_MIN_LOG_LEVEL=1
