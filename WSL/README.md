# WSL
## Ubuntuのinstallまで
以下の記事等を参照にした<br>
https://zenn.dev/yumizz/articles/627d4e4821c636<br>
https://youtu.be/2l_nSudnKs4?si=7d5_qHXjmAKDWp0E

## VSCodeとの連携
以下の記事を参考にした<br>
https://qiita.com/_masa_u/items/d3c1fa7898b0783bc3ed

# Ubuntu側の設定
1. sudoをpassward無しで実行できるようにした
2. shellをbashからzshに変えた
(この記事には書いてなかったが`chsh -s /bin/zsh`の後にはWSLの再起動が必要)<br>
https://qiita.com/yoshi_yast/items/5eaa917e567b3add55ac

# zsh
## zplug
zplugで管理することにした<br>
(入れた拡張機能)<br>
https://qiita.com/kamykn/items/203583935ed1cced5174<br>
https://qiita.com/obake_fe/items/c2edf65de684f026c59c<br>
(peco)<br>
https://zenn.dev/mato/scraps/2b0c423ad9da2c<br>
https://qiita.com/reireias/items/fd96d67ccf1fdffb24ed<br>
(zshrcでの書き方/公式Document)<br>
https://github.com/zplug/zplug/blob/master/doc/guide/ja/README.md

## zshrc
1. plugin<br>
https://qiita.com/kamykn/items/203583935ed1cced5174

2. history関連<br>
https://qiita.com/Kakuni/items/a8025e075926272f491d

# Python環境
pyenvを使用していて、以下の記事を参考にした<br>
https://qiita.com/neruoneru/items/1107bcdca7fa43de673d<br>
ただし、Pathについて、windows側にもpyenvを導入した際にはWSLの場合公式のパス設定では衝突するので以下の記事に従った<br>
https://qiita.com/gomi1994/items/0d98c10628221b557b68

## 仮想環境
1. 自分のプロジェクトはpoetryを使っている。(ruffを合わせると便利)
2. WSLではリモートSSH接続していて、WSLではUser側のsettings.jsonでは`python.venvPath`等を弄れないので毎回pythonファイルを用意して手動で設定する必要がある

# CUDA関連の設定
1. WSLにおいては通常のUbuntu環境と異なり、Windows側にNvidia-driverを置く必要があり、他にも追加手順がある<br>
https://docs.nvidia.com/cuda/wsl-user-guide/index.html#getting-started-with-cuda-on-wsl-2<br>
https://docs.nvidia.com/cuda/wsl-user-guide/index.html#cuda-support-for-wsl-2

2. CUDA等のversionはPyTorchの要求(12.1) <= (CUDA) <= nvidia-smiの対応できるversionにした(今回は12.4)<br>
(完全な記事)<br>
https://zenn.dev/yumizz/articles/627d4e4821c636<br>
https://pytorch.org/get-started/locally/<br>
https://developer.nvidia.com/cuda-12-4-0-download-archive

3. WSL2でUbuntu 24.04 LTSを使っているが、以下のErrorが出る
   ```shell
   The following packages have unmet dependencies:
    nsight-systems-2023.4.4 : Depends: libtinfo5 but it is not installable
   E: Unable to correct problems, you have held broken packages.
   ```
   以下の記事を参考にすればよい<br>
   https://askubuntu.com/questions/1491254/installing-cuda-on-ubuntu-23-10-libt5info-not-installable<br>
   https://touch-sp.hatenablog.com/entry/2024/04/26/124533

4. cuDNNは9.2.0で、cuda-keyring_1.1-1_all2.debを使ってinstallした<br>
https://developer.nvidia.com/cudnn-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network
