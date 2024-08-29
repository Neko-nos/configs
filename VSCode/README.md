# VScode

## launch.json
こちらは各ワークスペースに置くもので、現在はPythonのdebug用の記述のみ。

## linebreak.py
VSCodeでの`settings.json`の中には`"markdown.preview.breaks": true,`という設定ができるが、これをした場合、プレビューでは問題なく改行されるがGitHubにそのまま載せるとコード側には変更がされないので改行できなくなる<br>
しかし、毎回`<br>`等を打つのは面倒なので、保存の度に自動で`<br>`等を入れて適切に改行してくれるコードを作った。<br>
(但し、HTMLを使っているMarkdownは対象外)<br>
なお、標準ライブラリのみで動く様にしている。

## settings.json
WSL(Ubuntu)側のsettings.json<br>
フォントとして指定しているのはMoralerspace Neon

## settings_mac.json
Mac側のsettings.json<br>
MacはLaTeXといった他の言語を書く際にも用いているのでWSL側のsettings.jsonよりも設定項目が多い
