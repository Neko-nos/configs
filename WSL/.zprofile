# Path
# ref: https://qiita.com/magicant/items/d3bb7ea1192e63fba850
## pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
## Poetry
export PATH="$HOME/.local/bin:$PATH"
## CUDA
export PATH=/usr/local/cuda:/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
## TensorFlow
### デフォルトだとlogが全て出てくる
### ref: https://70vps.net/wsl-19.html
export TF_CPP_MIN_LOG_LEVEL=1
