# Path
# ref: https://qiita.com/magicant/items/d3bb7ea1192e63fba850
## pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
## Poetry
export PATH="~/.local/bin:$PATH"
## TensorFlow
### デフォルトだとlogが全て出てくる
### ref: https://70vps.net/wsl-19.html
export TF_CPP_MIN_LOG_LEVEL=1

# ここからはMac専用
# 一部コマンドをLinuxを同じ形式(GNU)にするためのcoreutilsのパスを通す
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
# brew
eval "$(/opt/homebrew/bin/brew shellenv)"
