#Requires AutoHotkey v2.0
#SingleInstance Force

; ================= EXECUÇÃO ELEVADA (ADMINISTRADOR) =================
if (!A_IsAdmin) {
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        ExitApp()
    }
}

; Caminho do utilitário de persistência de desktops virtuais
global vdExe := A_ScriptDir "\VirtualDesktop11.exe"

; ================= INCLUSÃO DE CONFIGURAÇÃO =================
#Include "config.ahk"

; ================= INCLUSÃO DE MÓDULOS =================
#Include "utils.ahk"
#Include "focus.ahk"
#Include "window-grid.ahk"
#Include "virtual-desktop.ahk"
#Include "window-swap.ahk"
#Include "window-resize.ahk"
#Include "window-grouping.ahk"
#Include "hotkeys.ahk"

; ================= ATALHOS PRINCIPAIS =================

; Win + T: Abre o modal de seleção de zona em grade
#t::GridWindowTiling()

; Win + P: Fixa a janela ativa em todos os desktops virtuais
#p::PinCurrentWindow()

; Win + Ctrl + Left: Navega para desktop virtual à esquerda
^#Left::NavigateDesktopLeft()

; Win + Ctrl + Right: Navega para desktop virtual à direita
^#Right::NavigateDesktopRight()

; Win + Alt + Left / Right: Troca posição de janelas
#!Left::SwapWindows()
#!Right::SwapWindows()

; Win + = / Win + -: Redimensiona janelas adjacentes
#=::AdjustWindowSplit(200)          ; Win + =
#+=::AdjustWindowSplit(200)         ; Win + Shift + = (Win + + físico)
#NumpadAdd::AdjustWindowSplit(200)  ; Win + Numpad +

#-::AdjustWindowSplit(-200)         ; Win + -
#NumpadSub::AdjustWindowSplit(-200) ; Win + Numpad -
