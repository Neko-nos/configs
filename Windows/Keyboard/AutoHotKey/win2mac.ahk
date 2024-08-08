#Requires AutoHotkey v2.0
#SingleInstance Force

; Macの様な矢印入力を可能にする
:*:zh::←
:*:zj::↓
:*:zk::↑
:*:zl::→

;文字の削除
F13 & H::Send "{Blind}{Backspace}"

;カーソルの移動(上下左右)
F13 & F::Send "{Blind}{Right}"
F13 & B::Send "{Blind}{Left}"
F13 & P::Send "{Blind}{Up}"
F13 & N::Send "{Blind}{Down}"

;カーソルの移動(行頭・行末)
F13 & A::Send "{Blind}{Home}"
F13 & E::Send "{Blind}{End}"
