; ================= ATALHOS GERAIS DO SISTEMA =================
; Módulo responsável por atalhos gerais que não se encaixam em outras categorias

; Win + W: Fecha a janela em foco
#w:: {
    hwnd := WinExist("A")
    if (!hwnd)
        return
    class := WinGetClass("ahk_id " hwnd)
    if (class == "Progman" || class == "WorkerW" || class == "Shell_TrayWnd")
        return
    Send("!{F4}")
}

; Win + Espaço: PowerToys Run
#Space::Send("#!{Space}")

; Win + Enter: Terminal
#Enter::Run("wt")

; Win + Alt + Enter: Terminal com privilégios de administrador
#!Enter::Run("*RunAs wt")

; Win + Alt + R: Recarregar script
#!r::Reload()

; Win + G: Desativa Game Bar (Win + G)
#g::return

; ================= DESATIVAR MENU INICIAR NA TECLA WIN AVULSA =================
; Impede a abertura do Menu Iniciar ao teclar Win sozinho,
; mas mantém 100% funcionais todos os atalhos (Win + T, Win + Espaço, etc.):
~LWin::Send("{Blind}{vkE8}")
~RWin::Send("{Blind}{vkE8}")

; Ao pressionar e soltar a tecla Win sozinha, abre o PowerToys Run:
~LWin up:: {
    if (A_PriorKey == "LWin")
        Send("#!{Space}")
}
