#Requires AutoHotkey v2.0
#SingleInstance Force

;-----------------------------------------------------------
; ref: https://qiita.com/kenichiro_ayaki/items/d55005df2787da725c6f
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle:="A")  {
    hwnd := WinExist(WinTitle)
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        cbSize := 4+4+(PtrSize*6)+16
        stGTI := Buffer(cbSize,0)
        NumPut("DWORD", cbSize, stGTI.Ptr,0)   ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", "Uint",0, "Uint", stGTI.Ptr)
                 ? NumGet(stGTI.Ptr,8+PtrSize,"Uint") : hwnd
    }
    return DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hwnd)
          , "UInt", 0x0283  ;Message : WM_IME_CONTROL
          ,  "Int", 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  "Int", 0)      ;lParam  : 0
}


; Macの様な矢印入力を可能にする
; ref: https://www.autohotkey.com/docs/v2/lib/_HotIf.htm
#HOTIF (IME_GET() = 1)
:*:zh::←
:*:zj::↓
:*:zk::↑
:*:zl::→
#HOTIF

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
