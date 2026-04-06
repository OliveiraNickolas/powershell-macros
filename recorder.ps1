# ============================================================
#  MacroRecorder - Gravador de macros para macros.ps1
#  Captura cliques, teclas e delays automaticamente.
#  F9 = iniciar/parar gravacao
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ([System.Management.Automation.PSTypeName]'MacroRecorder').Type) { Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public class MacroRecorder {
    // ------------------------------------------------------------------ Hooks
    private const int WH_KEYBOARD_LL = 13;
    private const int WH_MOUSE_LL    = 14;
    private const int WM_LBUTTONDOWN = 0x0201;
    private const int WM_RBUTTONDOWN = 0x0204;
    private const int WM_KEYDOWN     = 0x0100;
    private const int WM_SYSKEYDOWN  = 0x0104;

    [DllImport("user32.dll")] private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] private static extern bool   UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll")] private static extern short  GetKeyState(int nVirtKey);

    public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)] private struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] private struct MSLLHOOKSTRUCT {
        public POINT pt; public uint mouseData, flags, time; public IntPtr dwExtraInfo;
    }
    [StructLayout(LayoutKind.Sequential)] private struct KBDLLHOOKSTRUCT {
        public uint vkCode, scanCode, flags, time; public IntPtr dwExtraInfo;
    }

    // VK - Modifiers
    private const int VK_CONTROL = 0x11, VK_SHIFT = 0x10, VK_MENU = 0x12;
    private const int VK_LWIN    = 0x5B, VK_RWIN  = 0x5C;

    private static IntPtr _mouseHook = IntPtr.Zero;
    private static IntPtr _keyHook   = IntPtr.Zero;
    private static LowLevelProc _mouseProc;
    private static LowLevelProc _keyProc;

    public static bool         IsRecording = false;
    public static List<string> Actions     = new List<string>();
    public static Action<string> OnAction;       // callback -> atualiza UI
    public static Action         OnStop;         // callback -> gravacao parou (F9)
    public static int            MinDelayMs = 200;

    private static DateTime _lastTime   = DateTime.Now;
    private static StringBuilder _textBuf = new StringBuilder();

    // ------------------------------------------------------------------ Helpers internos
    private static bool Ctrl()  { return (GetKeyState(VK_CONTROL) & 0x8000) != 0; }
    private static bool Alt()   { return (GetKeyState(VK_MENU)    & 0x8000) != 0; }
    private static bool Shift() { return (GetKeyState(VK_SHIFT)   & 0x8000) != 0; }
    private static bool Win()   { return (GetKeyState(VK_LWIN)    & 0x8000) != 0 ||
                                         (GetKeyState(VK_RWIN)    & 0x8000) != 0; }

    private static void FlushText() {
        if (_textBuf.Length == 0) return;
        string text = _textBuf.ToString();
        _textBuf.Clear();
        // Escapar aspas e backticks para PS1
        string escaped = text.Replace("`", "``").Replace("\"", "`\"");
        string line = string.Format("        @{{ Type = \"TypeText\"; Text = \"{0}\" }},", escaped);
        Actions.Add(line);
        if (OnAction != null) OnAction(line);
    }

    private static void AddDelay() {
        DateTime now = DateTime.Now;
        int ms = (int)(now - _lastTime).TotalMilliseconds;
        _lastTime = now;
        if (ms >= MinDelayMs) {
            string line = string.Format("        @{{ Type = \"Delay\"; Milliseconds = {0} }},", ms);
            Actions.Add(line);
            if (OnAction != null) OnAction(line);
        }
    }

    private static void Emit(string actionType, string extra = "") {
        FlushText();
        AddDelay();
        string line = string.IsNullOrEmpty(extra)
            ? string.Format("        @{{ Type = \"{0}\" }},", actionType)
            : string.Format("        @{{ Type = \"{0}\"; {1} }},", actionType, extra);
        Actions.Add(line);
        if (OnAction != null) OnAction(line);
    }

    // ------------------------------------------------------------------ Mouse
    private static IntPtr MouseProc(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && IsRecording) {
            var s = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
            int msg = wParam.ToInt32();
            if (msg == WM_LBUTTONDOWN)
                Emit("Click",      string.Format("X = {0}; Y = {1}", s.pt.x, s.pt.y));
            else if (msg == WM_RBUTTONDOWN)
                Emit("RightClick", string.Format("X = {0}; Y = {1}", s.pt.x, s.pt.y));
        }
        return CallNextHookEx(_mouseHook, nCode, wParam, lParam);
    }

    // ------------------------------------------------------------------ Keyboard
    private static IntPtr KeyProc(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && IsRecording) {
            int msg = wParam.ToInt32();
            if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
                var s = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
                int vk = (int)s.vkCode;

                // F9 = parar gravacao
                if (vk == 0x78) {
                    IsRecording = false;
                    FlushText();
                    if (OnStop != null) OnStop();
                    return CallNextHookEx(_keyHook, nCode, wParam, lParam);
                }

                // Ignorar pressionamento de modificadores sozinhos
                if (vk == 0x10 || vk == 0x11 || vk == 0x12 ||
                    vk == 0xA0 || vk == 0xA1 || vk == 0xA2 || vk == 0xA3 ||
                    vk == 0xA4 || vk == 0xA5 || vk == 0x5B || vk == 0x5C)
                    return CallNextHookEx(_keyHook, nCode, wParam, lParam);

                bool ctrl = Ctrl(), alt = Alt(), shift = Shift(), win = Win();
                string mapped = MapKey(vk, ctrl, alt, shift, win);

                if (mapped != null) {
                    Emit(mapped);
                } else {
                    // Caractere imprimivel -> buffer TypeText
                    char? ch = VkToChar(vk, shift);
                    if (ch.HasValue) {
                        // Atualizar timestamp sem adicionar delay entre letras
                        _lastTime = DateTime.Now;
                        _textBuf.Append(ch.Value);
                        if (OnAction != null) OnAction("[digitando: " + _textBuf.ToString() + "]");
                    }
                }
            }
        }
        return CallNextHookEx(_keyHook, nCode, wParam, lParam);
    }

    // ------------------------------------------------------------------ Mapeamento de teclas
    private static string MapKey(int vk, bool ctrl, bool alt, bool shift, bool win) {
        // Win combos
        if (win && !ctrl && !alt) {
            switch (vk) {
                case 0x25: return "WinArrowLeft";
                case 0x26: return "WinArrowUp";
                case 0x27: return "WinArrowRight";
                case 0x28: return "WinArrowDown";
                case 0x52: return "WinR";
            }
        }
        // Alt combos
        if (alt && !ctrl && !win) {
            if (vk == 0x73) return "AltF4";   // F4
            if (vk == 0x09) return "AltTab";  // Tab
        }
        // Ctrl+Shift
        if (ctrl && shift && !alt && !win) {
            if (vk == 0x53) return "CtrlShiftS";
        }
        // Ctrl combos
        if (ctrl && !alt && !shift && !win) {
            if (vk >= 0x41 && vk <= 0x5A) return "Ctrl" + (char)vk;  // A-Z
            if (vk >= 0x60 && vk <= 0x69) return "CtrlNum" + (vk - 0x60);  // Numpad
            if (vk == 0x21) return "CtrlPageUp";
            if (vk == 0x22) return "CtrlPageDown";
        }
        // Sem modificadores (ou so Shift para teclas especiais)
        if (!ctrl && !alt && !win) {
            switch (vk) {
                case 0x0D: return "Enter";
                case 0x08: return "Backspace";
                case 0x2E: return "Delete";
                case 0x24: return "Home";
                case 0x23: return "End";
                case 0x21: return "PageUp";
                case 0x22: return "PageDown";
                case 0x20: return "Space";
                case 0x25: return "ArrowLeft";
                case 0x26: return "ArrowUp";
                case 0x27: return "ArrowRight";
                case 0x28: return "ArrowDown";
                case 0x70: return "F1";  case 0x71: return "F2";
                case 0x72: return "F3";  case 0x73: return "F4";
                case 0x74: return "F5";  case 0x75: return "F6";
                case 0x76: return "F7";  case 0x77: return "F8";
                // 0x78 = F9 (usado como stop)
                case 0x79: return "F10"; case 0x7A: return "F11";
                case 0x7B: return "F12";
                case 0x12: return "Alt"; // Alt sozinho (SYSKEYDOWN)
                // Numpad 0-9 sem Ctrl -> acoes "0"-"9" do macros.ps1
                case 0x60: return "0"; case 0x61: return "1";
                case 0x62: return "2"; case 0x63: return "3";
                case 0x64: return "4"; case 0x65: return "5";
                case 0x66: return "6"; case 0x67: return "7";
                case 0x68: return "8"; case 0x69: return "9";
            }
        }
        return null; // imprimivel ou desconhecido
    }

    private static char? VkToChar(int vk, bool shift) {
        if (vk >= 0x41 && vk <= 0x5A) return shift ? (char)vk : char.ToLower((char)vk);
        if (vk >= 0x30 && vk <= 0x39) {
            if (!shift) return (char)vk;
            string s = ")!@#$%^&*(";
            return s[vk - 0x30];
        }
        switch (vk) {
            case 0xBD: return shift ? '_' : '-';
            case 0xBB: return shift ? '+' : '=';
            case 0xDB: return shift ? '{' : '[';
            case 0xDD: return shift ? '}' : ']';
            case 0xBA: return shift ? ':' : ';';
            case 0xDE: return shift ? '"' : '\'';
            case 0xBC: return shift ? '<' : ',';
            case 0xBE: return shift ? '>' : '.';
            case 0xBF: return shift ? '?' : '/';
            case 0xC0: return shift ? '~' : '`';
            case 0xDC: return shift ? '|' : '\\';
        }
        return null;
    }

    // ------------------------------------------------------------------ API publica
    public static void Start(int minDelayMs) {
        Actions.Clear();
        _textBuf.Clear();
        _lastTime   = DateTime.Now;
        IsRecording = true;
        MinDelayMs  = minDelayMs;
        IntPtr hMod = GetModuleHandle(null);
        _mouseProc  = MouseProc;
        _keyProc    = KeyProc;
        _mouseHook  = SetWindowsHookEx(WH_MOUSE_LL,    _mouseProc, hMod, 0);
        _keyHook    = SetWindowsHookEx(WH_KEYBOARD_LL, _keyProc,   hMod, 0);
    }

    public static void Stop() {
        if (!IsRecording) return;
        IsRecording = false;
        FlushText();
        if (_mouseHook != IntPtr.Zero) { UnhookWindowsHookEx(_mouseHook); _mouseHook = IntPtr.Zero; }
        if (_keyHook   != IntPtr.Zero) { UnhookWindowsHookEx(_keyHook);   _keyHook   = IntPtr.Zero; }
    }

    public static string GetCode(string macroName) {
        var sb = new StringBuilder();
        sb.AppendLine("    \"" + macroName + "\" = @(");
        foreach (var a in Actions)
            sb.AppendLine(a);
        sb.AppendLine("    )");
        return sb.ToString();
    }
}
"@ }


# ============================================================
#  INTERFACE
# ============================================================

$cAccent  = [System.Drawing.Color]::FromArgb(98, 224, 239)
$cBg      = [System.Drawing.Color]::FromArgb(24, 5, 37)
$cText    = [System.Drawing.Color]::FromArgb(220, 220, 255)
$cBorder  = [System.Drawing.Color]::FromArgb(70, 170, 185)
$cGreen   = [System.Drawing.Color]::FromArgb(0, 255, 180)
$cOrange  = [System.Drawing.Color]::FromArgb(255, 140, 0)
$cRed     = [System.Drawing.Color]::FromArgb(255, 0, 120)
$cPink    = [System.Drawing.Color]::FromArgb(255, 0, 220)
$cSurface = [System.Drawing.Color]::FromArgb(10, 10, 28)
$font     = New-Object System.Drawing.Font("Consolas", 8,  [System.Drawing.FontStyle]::Bold)
$fontLg   = New-Object System.Drawing.Font("Consolas", 15, [System.Drawing.FontStyle]::Bold)
$fontSm   = New-Object System.Drawing.Font("Consolas", 7,  [System.Drawing.FontStyle]::Bold)

$script:wasRecording = $false

# --- Formulario ---
$form = New-Object System.Windows.Forms.Form
$form.Text            = "MacroRecorder"
$form.Size            = New-Object System.Drawing.Size(520, 540)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = $font

$form.add_Paint({
    param($s,$e)
    $pen = New-Object System.Drawing.Pen($cAccent, 3)
    $e.Graphics.DrawRectangle($pen, 1, 1, ($form.Width - 3), ($form.Height - 3))
    $pen.Dispose()
})

$dragHandler = {
    param($s,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Application]::DoEvents()
        $pt = $form.PointToScreen($e.Location)
        $form.Location = New-Object System.Drawing.Point(($pt.X - 200), ($pt.Y - 19))
    }
}

# --- Barra de titulo ---
$pnlTitle = New-Object System.Windows.Forms.Panel
$pnlTitle.Location  = New-Object System.Drawing.Point(3, 3)
$pnlTitle.Size      = New-Object System.Drawing.Size(514, 38)
$pnlTitle.BackColor = $cAccent
$pnlTitle.add_MouseDown({
    param($s,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:dragStart = $e.Location
    }
})
$pnlTitle.add_MouseMove({
    param($s,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $script:dragStart) {
        $pt = $form.PointToScreen($e.Location)
        $form.Location = New-Object System.Drawing.Point(
            ($pt.X - $script:dragStart.X),
            ($pt.Y - $script:dragStart.Y)
        )
    }
})
$form.Controls.Add($pnlTitle)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "MacroRecorder"
$lblTitle.Location  = New-Object System.Drawing.Point(10, 7)
$lblTitle.Size      = New-Object System.Drawing.Size(380, 25)
$lblTitle.Font      = $fontLg
$lblTitle.ForeColor = $cBg
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$pnlTitle.Controls.Add($lblTitle)

$btnMin = New-Object System.Windows.Forms.Button
$btnMin.Text      = "0"
$btnMin.Location  = New-Object System.Drawing.Point(462, 6)
$btnMin.Size      = New-Object System.Drawing.Size(22, 22)
$btnMin.FlatStyle = "Flat"
$btnMin.BackColor = $cAccent
$btnMin.ForeColor = $cBg
$btnMin.FlatAppearance.BorderSize = 0
$btnMin.Font      = New-Object System.Drawing.Font("Webdings", 11, [System.Drawing.FontStyle]::Bold)
$btnMin.add_Click({ $form.WindowState = "Minimized" })
$pnlTitle.Controls.Add($btnMin)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text      = "r"
$btnClose.Location  = New-Object System.Drawing.Point(487, 7)
$btnClose.Size      = New-Object System.Drawing.Size(22, 22)
$btnClose.FlatStyle = "Flat"
$btnClose.BackColor = $cAccent
$btnClose.ForeColor = $cRed
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.Font      = New-Object System.Drawing.Font("Marlett", 9, [System.Drawing.FontStyle]::Bold)
$btnClose.add_Click({
    [MacroRecorder]::Stop()
    $form.Close()
})
$pnlTitle.Controls.Add($btnClose)

# --- Separador ---
$sep0 = New-Object System.Windows.Forms.Panel
$sep0.Location  = New-Object System.Drawing.Point(3, 41)
$sep0.Size      = New-Object System.Drawing.Size(514, 2)
$sep0.BackColor = $cBorder
$form.Controls.Add($sep0)

# --- Nome do macro ---
$lblNome = New-Object System.Windows.Forms.Label
$lblNome.Text      = "Nome do macro:"
$lblNome.Location  = New-Object System.Drawing.Point(12, 52)
$lblNome.Size      = New-Object System.Drawing.Size(115, 18)
$lblNome.ForeColor = $cAccent
$form.Controls.Add($lblNome)

$txtNome = New-Object System.Windows.Forms.TextBox
$txtNome.Location  = New-Object System.Drawing.Point(130, 50)
$txtNome.Size      = New-Object System.Drawing.Size(374, 20)
$txtNome.BackColor = $cSurface
$txtNome.ForeColor = $cText
$txtNome.BorderStyle = "FixedSingle"
$txtNome.Text      = "Novo Macro"
$form.Controls.Add($txtNome)

# --- Delay minimo ---
$lblDelay = New-Object System.Windows.Forms.Label
$lblDelay.Text      = "Delay min (ms):"
$lblDelay.Location  = New-Object System.Drawing.Point(12, 80)
$lblDelay.Size      = New-Object System.Drawing.Size(115, 18)
$lblDelay.ForeColor = $cAccent
$form.Controls.Add($lblDelay)

$numDelay = New-Object System.Windows.Forms.NumericUpDown
$numDelay.Location  = New-Object System.Drawing.Point(130, 78)
$numDelay.Size      = New-Object System.Drawing.Size(80, 20)
$numDelay.BackColor = $cSurface
$numDelay.ForeColor = $cText
$numDelay.Minimum   = 50
$numDelay.Maximum   = 5000
$numDelay.Increment = 50
$numDelay.Value     = 200
$form.Controls.Add($numDelay)

# --- Status ---
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Pronto. Clique em GRAVAR ou pressione F9."
$lblStatus.Location  = New-Object System.Drawing.Point(220, 81)
$lblStatus.Size      = New-Object System.Drawing.Size(284, 18)
$lblStatus.ForeColor = $cAccent
$lblStatus.Font      = $fontSm
$form.Controls.Add($lblStatus)

# --- Separador ---
$sep1 = New-Object System.Windows.Forms.Panel
$sep1.Location  = New-Object System.Drawing.Point(3, 106)
$sep1.Size      = New-Object System.Drawing.Size(514, 2)
$sep1.BackColor = $cBorder
$form.Controls.Add($sep1)

# --- Botoes de acao ---
function New-RecBtn($txt, $x, $clr) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $txt
    $b.Location  = New-Object System.Drawing.Point($x, 115)
    $b.Size      = New-Object System.Drawing.Size(116, 28)
    $b.FlatStyle = "Flat"
    $b.BackColor = $cBg
    $b.ForeColor = $clr
    $b.FlatAppearance.BorderColor = $clr
    $b.FlatAppearance.BorderSize  = 1
    $b.Font      = $font
    return $b
}

$btnGravar = New-RecBtn "GRAVAR [F9]" 10  $cGreen
$btnParar  = New-RecBtn "PARAR"       132 $cRed
$btnLimpar = New-RecBtn "LIMPAR"      254 $cOrange
$btnCopiar = New-RecBtn "COPIAR CODIGO" 376 $cAccent

$form.Controls.AddRange(@($btnGravar, $btnParar, $btnLimpar, $btnCopiar))

# --- Separador ---
$sep2 = New-Object System.Windows.Forms.Panel
$sep2.Location  = New-Object System.Drawing.Point(3, 151)
$sep2.Size      = New-Object System.Drawing.Size(514, 2)
$sep2.BackColor = $cBorder
$form.Controls.Add($sep2)

# --- Log de acoes ---
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text      = "Acoes capturadas:"
$lblLog.Location  = New-Object System.Drawing.Point(12, 158)
$lblLog.Size      = New-Object System.Drawing.Size(200, 16)
$lblLog.ForeColor = $cAccent
$form.Controls.Add($lblLog)

$lstLog = New-Object System.Windows.Forms.ListBox
$lstLog.Location      = New-Object System.Drawing.Point(3, 176)
$lstLog.Size          = New-Object System.Drawing.Size(514, 300)
$lstLog.BackColor     = $cSurface
$lstLog.ForeColor     = $cText
$lstLog.BorderStyle   = "None"
$lstLog.HorizontalScrollbar = $true
$lstLog.Font          = $fontSm
$form.Controls.Add($lstLog)

# --- Botao guardar ficheiro ---
$btnGuardar = New-Object System.Windows.Forms.Button
$btnGuardar.Text      = "GUARDAR FICHEIRO"
$btnGuardar.Location  = New-Object System.Drawing.Point(3, 480)
$btnGuardar.Size      = New-Object System.Drawing.Size(514, 28)
$btnGuardar.FlatStyle = "Flat"
$btnGuardar.BackColor = $cBg
$btnGuardar.ForeColor = $cPink
$btnGuardar.FlatAppearance.BorderColor = $cPink
$btnGuardar.FlatAppearance.BorderSize  = 1
$btnGuardar.Font      = $font
$form.Controls.Add($btnGuardar)


# ============================================================
#  LOGICA
# ============================================================

function Update-LogFromCallback([string]$line) {
    if ($lstLog.IsHandleCreated) {
        $lstLog.Invoke([Action] {
            # Substituir preview de digitacao se for o ultimo item
            if ($lstLog.Items.Count -gt 0 -and ($lstLog.Items[$lstLog.Items.Count - 1] -like "*[digitando:*")) {
                $lstLog.Items[$lstLog.Items.Count - 1] = $line
            } else {
                $lstLog.Items.Add($line) | Out-Null
            }
            $lstLog.SelectedIndex = $lstLog.Items.Count - 1
        })
    }
}

function Start-Recording {
    if ([MacroRecorder]::IsRecording) { return }
    $lstLog.Items.Clear()
    [MacroRecorder]::OnAction = [Action[string]] { param($l) Update-LogFromCallback $l }
    [MacroRecorder]::OnStop   = [Action] {
        $form.Invoke([Action] { Stop-Recording })
    }
    [MacroRecorder]::Start([int]$numDelay.Value)
    $script:wasRecording = $true
    $lblStatus.Text      = "A gravar... [F9 para parar]"
    $lblStatus.ForeColor = $cGreen
    $btnGravar.ForeColor = $cRed
    $btnGravar.FlatAppearance.BorderColor = $cRed
    $btnGravar.Text = "A GRAVAR..."
}

function Stop-Recording {
    [MacroRecorder]::Stop()
    $count = [MacroRecorder]::Actions.Count
    $lblStatus.Text      = "Parado. $count acoes capturadas."
    $lblStatus.ForeColor = $cOrange
    $btnGravar.ForeColor = $cGreen
    $btnGravar.FlatAppearance.BorderColor = $cGreen
    $btnGravar.Text = "GRAVAR [F9]"
}

$btnGravar.add_Click({ Start-Recording })
$btnParar.add_Click({ Stop-Recording })

$btnLimpar.add_Click({
    Stop-Recording
    [MacroRecorder]::Actions.Clear()
    $lstLog.Items.Clear()
    $lblStatus.Text      = "Limpo. Pronto para nova gravacao."
    $lblStatus.ForeColor = $cAccent
})

$btnCopiar.add_Click({
    if ([MacroRecorder]::Actions.Count -eq 0) {
        $lblStatus.Text = "Nenhuma acao gravada."
        return
    }
    $nome = if ($txtNome.Text.Trim()) { $txtNome.Text.Trim() } else { "Novo Macro" }
    $code = [MacroRecorder]::GetCode($nome)
    [System.Windows.Forms.Clipboard]::SetText($code)
    $lblStatus.Text      = "Copiado! Cole em macros.ps1 dentro de `$macros = @{...}"
    $lblStatus.ForeColor = $cGreen
})

$btnGuardar.add_Click({
    if ([MacroRecorder]::Actions.Count -eq 0) {
        $lblStatus.Text = "Nenhuma acao gravada."
        return
    }
    $nome = if ($txtNome.Text.Trim()) { $txtNome.Text.Trim() } else { "Novo Macro" }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title      = "Guardar snippet do macro"
    $dlg.Filter     = "PowerShell (*.ps1)|*.ps1|Todos (*.*)|*.*"
    $dlg.FileName   = ($nome -replace '[\\/:*?"<>|]', '_') + ".ps1"
    $dlg.InitialDirectory = $PSScriptRoot
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $code = [MacroRecorder]::GetCode($nome)
        $code | Out-File -FilePath $dlg.FileName -Encoding UTF8
        $lblStatus.Text      = "Guardado: $($dlg.FileName)"
        $lblStatus.ForeColor = $cGreen
    }
})

# Timer para poll do estado (caso F9 pare gravacao fora do UI thread)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 150
$timer.add_Tick({
    if ($script:wasRecording -and -not [MacroRecorder]::IsRecording) {
        $script:wasRecording = $false
        # Stop-Recording ja foi chamado pelo OnStop callback
    }
})
$timer.Start()

$form.add_FormClosing({ [MacroRecorder]::Stop(); $timer.Stop() })
$form.ShowDialog()
