# Mac
## WSL(Ubuntu)との違い
主要な違いは以下

1. brew vs apt
2. BSD vs GNU
3. Command vs Control

これらの違い以外はWSL側の`.zshrc`等とは基本的には変わっていない

## Homebrew
Macではaptではなくbrewを使うことになる<br>
(デフォルトでは入っていないのでinstall必須)

## BSD vs GNU
`ls`, `sed`といった一部のコマンド達はMacではBSD系なので、Linuxの時の様に使いたい際にはGNU系のものに替える必要がある。<br>
基本的には`brew install coreutils`で大丈夫だが、`sed`に関しては別に`brew install gsed`とする必要がある。<br>
その為、prefixとしてgがついているため、alias等をして対応する必要がある。

## Command vs Control
実はMacでは`.zshrc`の中での`bindkey`ではcommand keyを用いることができない<br>
https://superuser.com/questions/349439/how-to-bind-command-key-in-zsh<br>
その為、Windows/WSLでのキーボードと同じ動作で`peco`関連のfunctionを動かすには、`karabina-elements`で変更する必要がある。

### Karabina-Elements
karabina_elementsというフォルダの中にjsonファイルがあるが、これをKarabina-Elementsの設定画面のComplex Modificationsの中で貼り付ければ,

- Control R -> Comannd R (the bindkey for `peco-select-hisotry`)
- Control P -> Command P (the bindkey for `peco-cdr`)

という様にでき、これによってWindows側のキーボード設定と同じになる
