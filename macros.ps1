# ============================================================
#  MacroExecutor - Automatizacao de tarefas com mouse e teclado
#  Macros ficam em ficheiros JSON na pasta  .\macros\
#  Para criar novos macros: clica em GRAVAR na interface.
#  Execucao: powershell -ExecutionPolicy Bypass -File macros.ps1
# ============================================================

# Se estiver dentro do VS Code / PSES, relancar numa janela PowerShell separada
if ($host.Name -like "*Visual Studio Code*" -or $host.Name -like "*EditorServices*") {
    $script = $MyInvocation.MyCommand.Path
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`"$script`""
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ([System.Management.Automation.PSTypeName]'User32').Type) { Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);

    private const int MOUSEEVENTF_LEFTDOWN  = 0x0002;
    private const int MOUSEEVENTF_LEFTUP    = 0x0004;
    private const int MOUSEEVENTF_RIGHTDOWN = 0x0008;
    private const int MOUSEEVENTF_RIGHTUP   = 0x0010;
    public  const uint KEYEVENTF_KEYUP      = 0x0002;

    public static void MoveMouse(int x, int y)   { SetCursorPos(x, y); }
    public static void ClickMouse()              { mouse_event(MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP, 0, 0, 0, 0); }
    public static void RightClickMouse()         { mouse_event(MOUSEEVENTF_RIGHTDOWN | MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0); }

    // VK codes
    public const byte VK_NUMPAD0=0x60; public const byte VK_NUMPAD1=0x61; public const byte VK_NUMPAD2=0x62;
    public const byte VK_NUMPAD3=0x63; public const byte VK_NUMPAD4=0x64; public const byte VK_NUMPAD5=0x65;
    public const byte VK_NUMPAD6=0x66; public const byte VK_NUMPAD7=0x67; public const byte VK_NUMPAD8=0x68;
    public const byte VK_NUMPAD9=0x69;
    public const byte VK_F1=0x70; public const byte VK_F2=0x71; public const byte VK_F3=0x72;
    public const byte VK_F4=0x73; public const byte VK_F5=0x74; public const byte VK_F6=0x75;
    public const byte VK_F7=0x76; public const byte VK_F8=0x77; public const byte VK_F9=0x78;
    public const byte VK_F10=0x79; public const byte VK_F11=0x7A; public const byte VK_F12=0x7B;
    public const byte VK_A=0x41; public const byte VK_B=0x42; public const byte VK_C=0x43;
    public const byte VK_D=0x44; public const byte VK_E=0x45; public const byte VK_F=0x46;
    public const byte VK_G=0x47; public const byte VK_H=0x48; public const byte VK_I=0x49;
    public const byte VK_J=0x4A; public const byte VK_K=0x4B; public const byte VK_L=0x4C;
    public const byte VK_M=0x4D; public const byte VK_N=0x4E; public const byte VK_O=0x4F;
    public const byte VK_P=0x50; public const byte VK_Q=0x51; public const byte VK_R=0x52;
    public const byte VK_S=0x53; public const byte VK_T=0x54; public const byte VK_U=0x55;
    public const byte VK_V=0x56; public const byte VK_W=0x57; public const byte VK_X=0x58;
    public const byte VK_Y=0x59; public const byte VK_Z=0x5A;
    public const byte VK_CONTROL=0x11; public const byte VK_SHIFT=0x10; public const byte VK_MENU=0x12;
    public const byte VK_LWIN=0x5B;    public const byte VK_RWIN=0x5C;  public const byte VK_BACK=0x08;
    public const byte VK_DELETE=0x2E;  public const byte VK_HOME=0x24;  public const byte VK_END=0x23;
    public const byte VK_SPACE=0x20;   public const byte VK_PRIOR=0x21; public const byte VK_NEXT=0x22;
    public const byte VK_LEFT=0x25;    public const byte VK_UP=0x26;    public const byte VK_RIGHT=0x27;
    public const byte VK_DOWN=0x28;    public const byte VK_DASH=0x6D;
    public const byte VK_TAB=0x09;     public const byte VK_ESCAPE=0x1B;

    public static void SendKey(byte vk)              { keybd_event(vk,0,0,0); keybd_event(vk,0,KEYEVENTF_KEYUP,0); }
    public static void SendCtrl(byte vk)             { keybd_event(VK_CONTROL,0,0,0); keybd_event(vk,0,0,0); keybd_event(vk,0,KEYEVENTF_KEYUP,0); keybd_event(VK_CONTROL,0,KEYEVENTF_KEYUP,0); }
    public static void SendCtrlShift(byte vk)        { keybd_event(VK_CONTROL,0,0,0); keybd_event(VK_SHIFT,0,0,0); keybd_event(vk,0,0,0); keybd_event(vk,0,KEYEVENTF_KEYUP,0); keybd_event(VK_SHIFT,0,KEYEVENTF_KEYUP,0); keybd_event(VK_CONTROL,0,KEYEVENTF_KEYUP,0); }
    public static void SendCtrlNumpad(byte numpadKey) { keybd_event(VK_CONTROL,0,0,0); keybd_event(numpadKey,0,0,0); keybd_event(numpadKey,0,KEYEVENTF_KEYUP,0); keybd_event(VK_CONTROL,0,KEYEVENTF_KEYUP,0); }
    public static void SendWinKey(byte key)           { keybd_event(VK_LWIN,0,0,0); keybd_event(key,0,0,0); keybd_event(key,0,KEYEVENTF_KEYUP,0); keybd_event(VK_LWIN,0,KEYEVENTF_KEYUP,0); }
    public static void SendAltTab()  { keybd_event(VK_MENU,0,0,0); keybd_event(0x09,0,0,0); keybd_event(0x09,0,KEYEVENTF_KEYUP,0); keybd_event(VK_MENU,0,KEYEVENTF_KEYUP,0); }
    public static void SendAltF4()   { keybd_event(VK_MENU,0,0,0); keybd_event(VK_F4,0,0,0); keybd_event(VK_F4,0,KEYEVENTF_KEYUP,0); keybd_event(VK_MENU,0,KEYEVENTF_KEYUP,0); }
    public static void SendShift(byte vk) { keybd_event(VK_SHIFT,0,0,0); keybd_event(vk,0,0,0); keybd_event(vk,0,KEYEVENTF_KEYUP,0); keybd_event(VK_SHIFT,0,KEYEVENTF_KEYUP,0); }
}
"@ }

if (-not ([System.Management.Automation.PSTypeName]'MacroRecorder').Type) { Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public class MacroRecorder {
    private const int WH_KEYBOARD_LL = 13;
    private const int WH_MOUSE_LL    = 14;
    private const int WM_LBUTTONDOWN = 0x0201;
    private const int WM_RBUTTONDOWN = 0x0204;
    private const int WM_KEYDOWN     = 0x0100;
    private const int WM_SYSKEYDOWN  = 0x0104;

    [DllImport("user32.dll")] private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelProc fn, IntPtr hMod, uint tid);
    [DllImport("user32.dll")] private static extern bool   UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string name);
    [DllImport("user32.dll")] private static extern short  GetKeyState(int nVirtKey);

    public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)] private struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] private struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData, flags, time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] private struct KBDLLHOOKSTRUCT { public uint vkCode, scanCode, flags, time; public IntPtr dwExtraInfo; }

    private const int VK_CONTROL=0x11, VK_SHIFT=0x10, VK_MENU=0x12, VK_LWIN=0x5B, VK_RWIN=0x5C;

    private static IntPtr _mouseHook = IntPtr.Zero;
    private static IntPtr _keyHook   = IntPtr.Zero;
    private static LowLevelProc _mouseProc;
    private static LowLevelProc _keyProc;

    // Dados publicos para leitura pelo PowerShell
    public static bool        IsRecording = false;
    public static int         MinDelayMs  = 200;
    public static string      TextPreview = "";    // preview do texto que esta a ser digitado
    // ActionLog: descricoes legíveis; ActionJsonLines: JSON por linha (para guardar)
    public static List<string> ActionLog      = new List<string>();
    public static List<string> ActionJsonLines = new List<string>();

    private static DateTime     _lastTime  = DateTime.Now;
    private static StringBuilder _textBuf  = new StringBuilder();
    // callback disparado quando uma acao é adicionada (PS usa timer em vez disto)
    public static Action OnStop;

    private static bool Ctrl()  { return (GetKeyState(VK_CONTROL) & 0x8000) != 0; }
    private static bool Shift() { return (GetKeyState(VK_SHIFT)   & 0x8000) != 0; }
    private static bool Alt()   { return (GetKeyState(VK_MENU)    & 0x8000) != 0; }
    private static bool Win()   { return (GetKeyState(VK_LWIN)    & 0x8000) != 0 || (GetKeyState(VK_RWIN) & 0x8000) != 0; }

    private static void FlushText() {
        if (_textBuf.Length == 0) return;
        string text = _textBuf.ToString();
        _textBuf.Clear();
        TextPreview = "";
        AddDelay();
        // Escapar para JSON: barra invertida e aspas
        string escaped = text.Replace("\\", "\\\\").Replace("\"", "\\\"");
        string json = "{\"Type\":\"TypeText\",\"Text\":\"" + escaped + "\"}";
        ActionJsonLines.Add(json);
        ActionLog.Add("TypeText: \"" + text + "\"");
    }

    private static void AddDelay() {
        DateTime now = DateTime.Now;
        int ms = (int)(now - _lastTime).TotalMilliseconds;
        _lastTime = now;
        if (ms >= MinDelayMs) {
            string json = "{\"Type\":\"Delay\",\"Milliseconds\":" + ms + ",\"Message\":\"\",\"Load\":0}";
            ActionJsonLines.Add(json);
            ActionLog.Add("Delay  " + ms + "ms");
        }
    }

    private static void Emit(string type, string extraJson = "") {
        FlushText();
        AddDelay();
        string json = string.IsNullOrEmpty(extraJson)
            ? "{\"Type\":\"" + type + "\"}"
            : "{\"Type\":\"" + type + "\"," + extraJson + "}";
        ActionJsonLines.Add(json);
        ActionLog.Add(type);
    }

    private static IntPtr MouseProc(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && IsRecording) {
            var s = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
            int msg = wParam.ToInt32();
            if (msg == WM_LBUTTONDOWN)
                Emit("Click",      "\"X\":" + s.pt.x + ",\"Y\":" + s.pt.y);
            else if (msg == WM_RBUTTONDOWN)
                Emit("RightClick", "\"X\":" + s.pt.x + ",\"Y\":" + s.pt.y);
        }
        return CallNextHookEx(_mouseHook, nCode, wParam, lParam);
    }

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
                // Ignorar modificadores sozinhos
                if (vk==0x10||vk==0x11||vk==0x12||vk==0xA0||vk==0xA1||vk==0xA2||vk==0xA3||vk==0xA4||vk==0xA5||vk==0x5B||vk==0x5C)
                    return CallNextHookEx(_keyHook, nCode, wParam, lParam);

                bool ctrl=Ctrl(), alt=Alt(), shift=Shift(), win=Win();
                string mapped = MapKey(vk, ctrl, alt, shift, win);
                if (mapped != null) {
                    Emit(mapped);
                } else {
                    char? ch = VkToChar(vk, shift);
                    if (ch.HasValue) {
                        _lastTime = DateTime.Now;
                        _textBuf.Append(ch.Value);
                        TextPreview = "> " + _textBuf.ToString();
                    }
                }
            }
        }
        return CallNextHookEx(_keyHook, nCode, wParam, lParam);
    }

    private static string MapKey(int vk, bool ctrl, bool alt, bool shift, bool win) {
        if (win && !ctrl && !alt) {
            switch(vk) { case 0x25:return "WinArrowLeft"; case 0x26:return "WinArrowUp"; case 0x27:return "WinArrowRight"; case 0x28:return "WinArrowDown"; case 0x52:return "WinR"; }
        }
        if (alt && !ctrl && !win) {
            if (vk==0x73) return "AltF4";
            if (vk==0x09) return "AltTab";
        }
        if (ctrl && shift && !alt && !win) {
            if (vk>=0x41&&vk<=0x5A) return "CtrlShift"+(char)vk;
            switch(vk) { case 0x24:return "CtrlShiftHome"; case 0x23:return "CtrlShiftEnd"; }
        }
        if (ctrl && !alt && !shift && !win) {
            if (vk>=0x41&&vk<=0x5A) return "Ctrl"+(char)vk;
            if (vk>=0x60&&vk<=0x69) return "CtrlNum"+(vk-0x60);
            switch(vk) { case 0x21:return "CtrlPageUp"; case 0x22:return "CtrlPageDown"; case 0x24:return "CtrlHome"; case 0x23:return "CtrlEnd"; }
        }
        if (shift && !ctrl && !alt && !win) {
            switch(vk) {
                case 0x24:return "ShiftHome";      case 0x23:return "ShiftEnd";
                case 0x21:return "ShiftPageUp";    case 0x22:return "ShiftPageDown";
                case 0x25:return "ShiftArrowLeft"; case 0x26:return "ShiftArrowUp";
                case 0x27:return "ShiftArrowRight";case 0x28:return "ShiftArrowDown";
                case 0x09:return "ShiftTab";       case 0x2E:return "ShiftDelete";
            }
            return null; // shift+letra → VkToChar trata como maiuscula
        }
        if (!ctrl&&!alt&&!win&&!shift) {
            switch(vk) {
                case 0x0D:return "Enter";    case 0x08:return "Backspace"; case 0x2E:return "Delete";
                case 0x24:return "Home";     case 0x23:return "End";       case 0x21:return "PageUp";
                case 0x22:return "PageDown"; case 0x20:return "Space";     case 0x09:return "Tab";
                case 0x25:return "ArrowLeft";case 0x26:return "ArrowUp";   case 0x27:return "ArrowRight"; case 0x28:return "ArrowDown";
                case 0x70:return "F1";  case 0x71:return "F2";  case 0x72:return "F3";  case 0x73:return "F4";
                case 0x74:return "F5";  case 0x75:return "F6";  case 0x76:return "F7";  case 0x77:return "F8";
                case 0x79:return "F10"; case 0x7A:return "F11"; case 0x7B:return "F12";
                case 0x60:return "0"; case 0x61:return "1"; case 0x62:return "2"; case 0x63:return "3";
                case 0x64:return "4"; case 0x65:return "5"; case 0x66:return "6"; case 0x67:return "7";
                case 0x68:return "8"; case 0x69:return "9"; case 0x6D:return "Dash";
            }
        }
        return null;
    }

    private static char? VkToChar(int vk, bool shift) {
        if (vk>=0x41&&vk<=0x5A) return shift?(char)vk:char.ToLower((char)vk);
        if (vk>=0x30&&vk<=0x39) { if(!shift)return(char)vk; string s=")!@#$%^&*("; return s[vk-0x30]; }
        switch(vk) {
            case 0xBD:return shift?'_':'-'; case 0xBB:return shift?'+':'=';
            case 0xDB:return shift?'{':'['; case 0xDD:return shift?'}':']';
            case 0xBA:return shift?':':';'; case 0xDE:return shift?'"':'\'';
            case 0xBC:return shift?'<':','; case 0xBE:return shift?'>':'.';
            case 0xBF:return shift?'?':'/'; case 0xC0:return shift?'~':'``';
            case 0xDC:return shift?'|':'\\';
        }
        return null;
    }

    public static void Start(int minDelayMs) {
        ActionLog.Clear();
        ActionJsonLines.Clear();
        TextPreview = "";
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
        if (_mouseHook!=IntPtr.Zero){UnhookWindowsHookEx(_mouseHook);_mouseHook=IntPtr.Zero;}
        if (_keyHook!=IntPtr.Zero)  {UnhookWindowsHookEx(_keyHook);  _keyHook=IntPtr.Zero;}
    }
}
"@ }


# ============================================================
#  MACROS FOLDER - LOAD / SAVE
# ============================================================

$script:macrosFolder = Join-Path $PSScriptRoot "macros"
if (-not (Test-Path $script:macrosFolder)) {
    New-Item -ItemType Directory -Path $script:macrosFolder | Out-Null
}

function Load-Macros {
    $result = [ordered]@{}
    $files = Get-ChildItem $script:macrosFolder -Filter "*.json" -ErrorAction SilentlyContinue
    if (-not $files) { return $result }
    $files | ForEach-Object {
        try {
            $d = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $result[$d.name] = $d
        } catch { }
    } | Sort-Object { try { [int]$_.order } catch { 999 } }
    # Reordenar pelo campo order
    $sorted = [ordered]@{}
    $result.GetEnumerator() | Sort-Object { try { [int]$_.Value.order } catch { 999 } } | ForEach-Object {
        $sorted[$_.Key] = $_.Value.actions
    }
    return $sorted
}

function Get-NextOrder {
    $orders = Get-ChildItem $script:macrosFolder -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        try { [int](Get-Content $_.FullName -Raw | ConvertFrom-Json).order } catch { 0 }
    }
    if (-not $orders) { return 10 }
    return ([int]($orders | Measure-Object -Maximum).Maximum) + 10
}

function Save-RecordedMacro {
    param([string]$name)
    if ([MacroRecorder]::ActionJsonLines.Count -eq 0) { return $false }
    $order    = Get-NextOrder
    $jsonBody = "[" + ([MacroRecorder]::ActionJsonLines -join ",") + "]"
    $actions  = $jsonBody | ConvertFrom-Json
    $data     = [ordered]@{ name = $name; order = $order; actions = $actions }
    $safe     = $name -replace '[\\/:*?"<>|]', '_'
    $filename = "{0:D3}_{1}.json" -f $order, $safe
    $filepath = Join-Path $script:macrosFolder $filename
    $data | ConvertTo-Json -Depth 10 | Out-File $filepath -Encoding UTF8 -Force
    return $true
}

$script:macros = Load-Macros


# ============================================================
#  WRAPPERS POWERSHELL
# ============================================================

function Invoke-Click      { param([int]$x,[int]$y) [User32]::MoveMouse($x,$y); Start-Sleep -Milliseconds 100; [User32]::ClickMouse() }
function Invoke-RightClick { param([int]$x,[int]$y) [User32]::MoveMouse($x,$y); Start-Sleep -Milliseconds 100; [User32]::RightClickMouse() }
function Invoke-MoveMouse  { param([int]$x,[int]$y) [User32]::MoveMouse($x,$y) }

function Invoke-Delay {
    param([int]$Milliseconds, [string]$Message = "", [int]$Load = 0)
    if ($Message) {
        $txt = ($Message -split ";")[0]
        $script:outputBox.AppendText("$txt`n")
    }
    $end = [DateTime]::Now.AddMilliseconds($Milliseconds)
    while ([DateTime]::Now -lt $end) {
        if ($script:stopMacro) { return }
        if ($Load -ne 0) {
            $script:outputBox.AppendText(".`r")
            $script:outputBox.ScrollToCaret()
        }
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.Application]::DoEvents()
    }
    if ($Load -ne 0) {
        $script:outputBox.AppendText(" `n")
        $script:outputBox.ScrollToCaret()
    }
}

function Invoke-TypeText {
    param([string]$text)
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait($text)
}

function Write-Output2 { param([string]$msg) $script:outputBox.AppendText("$msg`n") }

function Play-Sound {
    param([string]$path)
    if ($path -and (Test-Path $path)) {
        $p = New-Object System.Media.SoundPlayer; $p.SoundLocation = $path; $p.PlaySync()
    }
}


# ============================================================
#  EXECUTOR
# ============================================================

function Execute-Script {
    param([array]$actions)
    foreach ($action in $actions) {
        if ($script:stopMacro) { return }
        while ($script:pauseMacro) { Start-Sleep -Milliseconds 100; [System.Windows.Forms.Application]::DoEvents() }
        switch ($action.Type) {
            "0"{[User32]::SendKey([User32]::VK_NUMPAD0)} "1"{[User32]::SendKey([User32]::VK_NUMPAD1)}
            "2"{[User32]::SendKey([User32]::VK_NUMPAD2)} "3"{[User32]::SendKey([User32]::VK_NUMPAD3)}
            "4"{[User32]::SendKey([User32]::VK_NUMPAD4)} "5"{[User32]::SendKey([User32]::VK_NUMPAD5)}
            "6"{[User32]::SendKey([User32]::VK_NUMPAD6)} "7"{[User32]::SendKey([User32]::VK_NUMPAD7)}
            "8"{[User32]::SendKey([User32]::VK_NUMPAD8)} "9"{[User32]::SendKey([User32]::VK_NUMPAD9)}
            "A"{[User32]::SendKey([User32]::VK_A)} "B"{[User32]::SendKey([User32]::VK_B)}
            "C"{[User32]::SendKey([User32]::VK_C)} "D"{[User32]::SendKey([User32]::VK_D)}
            "E"{[User32]::SendKey([User32]::VK_E)} "F"{[User32]::SendKey([User32]::VK_F)}
            "G"{[User32]::SendKey([User32]::VK_G)} "H"{[User32]::SendKey([User32]::VK_H)}
            "I"{[User32]::SendKey([User32]::VK_I)} "J"{[User32]::SendKey([User32]::VK_J)}
            "K"{[User32]::SendKey([User32]::VK_K)} "L"{[User32]::SendKey([User32]::VK_L)}
            "M"{[User32]::SendKey([User32]::VK_M)} "N"{[User32]::SendKey([User32]::VK_N)}
            "O"{[User32]::SendKey([User32]::VK_O)} "P"{[User32]::SendKey([User32]::VK_P)}
            "Q"{[User32]::SendKey([User32]::VK_Q)} "R"{[User32]::SendKey([User32]::VK_R)}
            "S"{[User32]::SendKey([User32]::VK_S)} "T"{[User32]::SendKey([User32]::VK_T)}
            "U"{[User32]::SendKey([User32]::VK_U)} "V"{[User32]::SendKey([User32]::VK_V)}
            "W"{[User32]::SendKey([User32]::VK_W)} "X"{[User32]::SendKey([User32]::VK_X)}
            "Y"{[User32]::SendKey([User32]::VK_Y)} "Z"{[User32]::SendKey([User32]::VK_Z)}
            "Dash"        { [User32]::SendKey([User32]::VK_DASH) }
            "Alt"         { [User32]::SendKey([User32]::VK_MENU) }
            "AltTab"      { [User32]::SendAltTab() }
            "AltF4"       { [User32]::SendAltF4() }
            "Backspace"   { [User32]::SendKey([User32]::VK_BACK) }
            "Delete"      { [User32]::SendKey([User32]::VK_DELETE) }
            "Enter"       { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") }
            "Home"        { [User32]::SendKey([User32]::VK_HOME) }
            "End"         { [User32]::SendKey([User32]::VK_END) }
            "PageUp"      { [User32]::SendKey([User32]::VK_PRIOR) }
            "PageDown"    { [User32]::SendKey([User32]::VK_NEXT) }
            "Space"       { [User32]::SendKey([User32]::VK_SPACE) }
            "ArrowUp"     { [User32]::SendKey([User32]::VK_UP) }
            "ArrowDown"   { [User32]::SendKey([User32]::VK_DOWN) }
            "ArrowLeft"   { [User32]::SendKey([User32]::VK_LEFT) }
            "ArrowRight"  { [User32]::SendKey([User32]::VK_RIGHT) }
            "CtrlA"       { [User32]::SendCtrl([User32]::VK_A) }
            "CtrlB"       { [User32]::SendCtrl([User32]::VK_B) }
            "CtrlC"       { [User32]::SendCtrl([User32]::VK_C) }
            "CtrlD"       { [User32]::SendCtrl([User32]::VK_D) }
            "CtrlE"       { [User32]::SendCtrl([User32]::VK_E) }
            "CtrlF"       { [User32]::SendCtrl([User32]::VK_F) }
            "CtrlG"       { [User32]::SendCtrl([User32]::VK_G) }
            "CtrlH"       { [User32]::SendCtrl([User32]::VK_H) }
            "CtrlI"       { [User32]::SendCtrl([User32]::VK_I) }
            "CtrlJ"       { [User32]::SendCtrl([User32]::VK_J) }
            "CtrlK"       { [User32]::SendCtrl([User32]::VK_K) }
            "CtrlL"       { [User32]::SendCtrl([User32]::VK_L) }
            "CtrlM"       { [User32]::SendCtrl([User32]::VK_M) }
            "CtrlN"       { [User32]::SendCtrl([User32]::VK_N) }
            "CtrlO"       { [User32]::SendCtrl([User32]::VK_O) }
            "CtrlP"       { [User32]::SendCtrl([User32]::VK_P) }
            "CtrlQ"       { [User32]::SendCtrl([User32]::VK_Q) }
            "CtrlR"       { [User32]::SendCtrl([User32]::VK_R) }
            "CtrlS"       { [User32]::SendCtrl([User32]::VK_S) }
            "CtrlT"       { [User32]::SendCtrl([User32]::VK_T) }
            "CtrlU"       { [User32]::SendCtrl([User32]::VK_U) }
            "CtrlV"       { [User32]::SendCtrl([User32]::VK_V) }
            "CtrlW"       { [User32]::SendCtrl([User32]::VK_W) }
            "CtrlX"       { [User32]::SendCtrl([User32]::VK_X) }
            "CtrlY"       { [User32]::SendCtrl([User32]::VK_Y) }
            "CtrlZ"       { [User32]::SendCtrl([User32]::VK_Z) }
            "CtrlNum0"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD0) }
            "CtrlNum1"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD1) }
            "CtrlNum2"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD2) }
            "CtrlNum3"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD3) }
            "CtrlNum4"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD4) }
            "CtrlNum5"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD5) }
            "CtrlNum6"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD6) }
            "CtrlNum7"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD7) }
            "CtrlNum8"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD8) }
            "CtrlNum9"    { [User32]::SendCtrlNumpad([User32]::VK_NUMPAD9) }
            "CtrlPageUp"  { [User32]::SendCtrl([User32]::VK_PRIOR) }
            "CtrlPageDown"{ [User32]::SendCtrl([User32]::VK_NEXT) }
            "CtrlShiftS"  { [User32]::SendCtrlShift([User32]::VK_S) }
            "WinArrowUp"  { [User32]::SendWinKey([User32]::VK_UP) }
            "WinArrowDown"{ [User32]::SendWinKey([User32]::VK_DOWN) }
            "WinArrowLeft"{ [User32]::SendWinKey([User32]::VK_LEFT) }
            "WinArrowRight"{[User32]::SendWinKey([User32]::VK_RIGHT) }
            "WinR"        { [User32]::SendWinKey([User32]::VK_R) }
            "F1" {[User32]::SendKey([User32]::VK_F1)} "F2" {[User32]::SendKey([User32]::VK_F2)}
            "F3" {[User32]::SendKey([User32]::VK_F3)} "F4" {[User32]::SendKey([User32]::VK_F4)}
            "F5" {[User32]::SendKey([User32]::VK_F5)} "F6" {[User32]::SendKey([User32]::VK_F6)}
            "F7" {[User32]::SendKey([User32]::VK_F7)} "F8" {[User32]::SendKey([User32]::VK_F8)}
            "F10"{[User32]::SendKey([User32]::VK_F10)}"F11"{[User32]::SendKey([User32]::VK_F11)}
            "F12"{[User32]::SendKey([User32]::VK_F12)}
            "Click"       { Invoke-Click      -x $action.X -y $action.Y }
            "RightClick"  { Invoke-RightClick -x $action.X -y $action.Y }
            "MoveMouse"   { Invoke-MoveMouse  -x $action.X -y $action.Y }
            "Delay"       { Invoke-Delay -Milliseconds ([int]$action.Milliseconds) -Message ([string]$action.Message) -Load ([int]$action.Load) }
            "Message"     { Write-Output2 -msg ($action.Text -split ";")[0] }
            "TypeText"    { Invoke-TypeText -text $action.Text }
            "Tab"             { [User32]::SendKey([User32]::VK_TAB) }
            "ShiftTab"        { [User32]::SendShift([User32]::VK_TAB) }
            "ShiftHome"       { [User32]::SendShift([User32]::VK_HOME) }
            "ShiftEnd"        { [User32]::SendShift([User32]::VK_END) }
            "ShiftPageUp"     { [User32]::SendShift([User32]::VK_PRIOR) }
            "ShiftPageDown"   { [User32]::SendShift([User32]::VK_NEXT) }
            "ShiftArrowLeft"  { [User32]::SendShift([User32]::VK_LEFT) }
            "ShiftArrowRight" { [User32]::SendShift([User32]::VK_RIGHT) }
            "ShiftArrowUp"    { [User32]::SendShift([User32]::VK_UP) }
            "ShiftArrowDown"  { [User32]::SendShift([User32]::VK_DOWN) }
            "ShiftDelete"     { [User32]::SendShift([User32]::VK_DELETE) }
            "CtrlHome"        { [User32]::SendCtrl([User32]::VK_HOME) }
            "CtrlEnd"         { [User32]::SendCtrl([User32]::VK_END) }
            "CtrlShiftHome"   { [User32]::SendCtrlShift([User32]::VK_HOME) }
            "CtrlShiftEnd"    { [User32]::SendCtrlShift([User32]::VK_END) }
            default {
                if ($action.Type -match '^CtrlShift([A-Z])$') {
                    [User32]::SendCtrlShift([byte][int][char]$Matches[1])
                } elseif ($action.Type -match '^Shift([A-Z])$') {
                    [User32]::SendShift([byte][int][char]$Matches[1])
                }
            }
        }
    }
}


# ============================================================
#  CONTROLO
# ============================================================

$script:stopMacro      = $false
$script:pauseMacro     = $false
$script:outputBox      = $null
$script:selectedMacro  = $null

function Start-Macro {
    param([string]$macroName)
    $script:stopMacro  = $false
    $script:pauseMacro = $false
    $loop        = $script:loopCheckBox.Checked
    $repeat      = $script:repeatCheckBox.Checked
    $repeatCount = [int]($script:repeatCountTextBox.Text -replace '\D','0')
    $actions = $script:macros[$macroName]
    if (-not $actions) { Write-Output2 "Macro nao encontrado: $macroName"; return }

    if ($repeat -and $repeatCount -gt 0) {
        for ($i = 0; $i -lt $repeatCount; $i++) {
            if ($script:stopMacro) { break }
            Write-Output2 "Executando $macroName"
            Execute-Script -actions $actions
            Write-Output2 "Completo ($($i+1)/$repeatCount)"
        }
    } else {
        while (-not $script:stopMacro) {
            if (-not $script:pauseMacro) {
                Write-Output2 "Executando $macroName"
                Execute-Script -actions $actions
            }
            if (-not $loop) { break }
        }
    }
}

function Stop-Macro {
    $script:stopMacro = $true; $script:pauseMacro = $false
    $script:outputBox.AppendText("`nFinalizado.`n")
}

function Toggle-Pause {
    $script:pauseMacro = -not $script:pauseMacro
    Write-Output2 (if ($script:pauseMacro) { "PAUSADO" } else { "Retomado" })
}


# ============================================================
#  PALETA DE CORES (partilhada pelos dois formularios)
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

function New-FlatButton($txt, $x, $y, $w, $h, $fg, $form) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object System.Drawing.Point($x,$y)
    $b.Size = New-Object System.Drawing.Size($w,$h); $b.FlatStyle = "Flat"
    $b.BackColor = $cBg; $b.ForeColor = $fg; $b.Font = $font
    $b.FlatAppearance.BorderColor = $fg; $b.FlatAppearance.BorderSize = 1
    if ($form) { $form.Controls.Add($b) }
    return $b
}

function New-TitleBar($form, $title, $w) {
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location  = New-Object System.Drawing.Point(3,3)
    $pnl.Size      = New-Object System.Drawing.Size(($w-6), 38)
    $pnl.BackColor = $cAccent

    $targetForm = $form                          # local copy — closures capture this, not outer $form
    $drag = @{ Pt = $null; Origin = $null }      # per-instance drag state (not shared via $script:)

    $onDown = {
        param($s,$e)
        if ($e.Button -eq "Left") {
            $drag.Pt     = $s.PointToScreen($e.Location)
            $drag.Origin = $targetForm.Location
        }
    }.GetNewClosure()
    $onMove = {
        param($s,$e)
        if ($e.Button -eq "Left" -and $drag.Pt) {
            $cur = $s.PointToScreen($e.Location)
            $targetForm.Location = New-Object System.Drawing.Point(
                ($drag.Origin.X + $cur.X - $drag.Pt.X),
                ($drag.Origin.Y + $cur.Y - $drag.Pt.Y))
        }
    }.GetNewClosure()
    $onUp = { $drag.Pt = $null }.GetNewClosure()

    $pnl.add_MouseDown($onDown); $pnl.add_MouseMove($onMove); $pnl.add_MouseUp($onUp)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $title; $lbl.Location = New-Object System.Drawing.Point(10,7)
    $lbl.Size = New-Object System.Drawing.Size(($w-80), 25); $lbl.Font = $fontLg
    $lbl.ForeColor = $cBg; $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.add_MouseDown($onDown); $lbl.add_MouseMove($onMove); $lbl.add_MouseUp($onUp)
    $pnl.Controls.Add($lbl)

    $btnMin = New-Object System.Windows.Forms.Button
    $btnMin.Text="0"; $btnMin.Location=New-Object System.Drawing.Point(($w-74),6); $btnMin.Size=New-Object System.Drawing.Size(22,22)
    $btnMin.FlatStyle="Flat"; $btnMin.BackColor=$cAccent; $btnMin.ForeColor=$cBg; $btnMin.FlatAppearance.BorderSize=0
    $btnMin.Font=New-Object System.Drawing.Font("Webdings",11,[System.Drawing.FontStyle]::Bold)
    $btnMin.add_Click({ $targetForm.WindowState="Minimized" }.GetNewClosure())
    $pnl.Controls.Add($btnMin)

    $btnX = New-Object System.Windows.Forms.Button
    $btnX.Text="r"; $btnX.Location=New-Object System.Drawing.Point(($w-48),7); $btnX.Size=New-Object System.Drawing.Size(22,22)
    $btnX.FlatStyle="Flat"; $btnX.BackColor=$cAccent; $btnX.ForeColor=$cRed; $btnX.FlatAppearance.BorderSize=0
    $btnX.Font=New-Object System.Drawing.Font("Marlett",9,[System.Drawing.FontStyle]::Bold)
    $btnX.add_Click({ $targetForm.Close() }.GetNewClosure())
    $pnl.Controls.Add($btnX)

    $form.Controls.Add($pnl)
    return $pnl
}


# ============================================================
#  FORMULARIO GRAVADOR (abre em janela separada)
# ============================================================

function Open-RecorderForm {
    param($parentComboBox)
    # ── Form ──────────────────────────────────────────────────────
    $rec = New-Object System.Windows.Forms.Form
    $rec.Text = "MacroRecorder"; $rec.Size = New-Object System.Drawing.Size(540, 560)
    $rec.StartPosition = "CenterScreen"; $rec.FormBorderStyle = "None"; $rec.KeyPreview = $true
    $rec.BackColor = $cBg; $rec.ForeColor = $cText; $rec.Font = $font
    $rec.add_Paint({ param($s,$e) $pen=New-Object System.Drawing.Pen($cAccent,3); $e.Graphics.DrawRectangle($pen,1,1,($rec.Width-3),($rec.Height-3)); $pen.Dispose() })
    New-TitleBar $rec "MacroRecorder" 540 | Out-Null

    # ── Linha 1: Nome + Delay min + Status ────────────────────────
    $lblNome = New-Object System.Windows.Forms.Label
    $lblNome.Text="Nome:"; $lblNome.Location=New-Object System.Drawing.Point(10,50); $lblNome.Size=New-Object System.Drawing.Size(48,18); $lblNome.ForeColor=$cAccent
    $rec.Controls.Add($lblNome)
    $txtNome = New-Object System.Windows.Forms.TextBox
    $txtNome.Location=New-Object System.Drawing.Point(60,48); $txtNome.Size=New-Object System.Drawing.Size(240,20)
    $txtNome.BackColor=$cSurface; $txtNome.ForeColor=$cText; $txtNome.BorderStyle="FixedSingle"; $txtNome.Text="Novo Macro"
    $rec.Controls.Add($txtNome)
    $lblDly = New-Object System.Windows.Forms.Label
    $lblDly.Text="Delay min:"; $lblDly.Location=New-Object System.Drawing.Point(308,50); $lblDly.Size=New-Object System.Drawing.Size(68,18); $lblDly.ForeColor=$cAccent
    $rec.Controls.Add($lblDly)
    $numDly = New-Object System.Windows.Forms.NumericUpDown
    $numDly.Location=New-Object System.Drawing.Point(378,48); $numDly.Size=New-Object System.Drawing.Size(70,20)
    $numDly.BackColor=$cSurface; $numDly.ForeColor=$cText; $numDly.Minimum=50; $numDly.Maximum=5000; $numDly.Increment=50; $numDly.Value=200
    $rec.Controls.Add($numDly)
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text="Pronto. [F9] grava."; $lblStatus.Location=New-Object System.Drawing.Point(454,51); $lblStatus.Size=New-Object System.Drawing.Size(82,16)
    $lblStatus.ForeColor=$cAccent; $lblStatus.Font=$fontSm
    $rec.Controls.Add($lblStatus)

    $sep1 = New-Object System.Windows.Forms.Panel
    $sep1.Location=New-Object System.Drawing.Point(3,74); $sep1.Size=New-Object System.Drawing.Size(534,2); $sep1.BackColor=$cBorder
    $rec.Controls.Add($sep1)

    # ── Linha 2: Botões ───────────────────────────────────────────
    $recBtnGravar  = New-FlatButton "GRAVAR [F9]"  5   81 108 26 $cGreen  $rec
    $recBtnParar   = New-FlatButton "PARAR"        118  81 82  26 $cRed    $rec
    $recBtnLimpar  = New-FlatButton "LIMPAR"       205  81 82  26 $cOrange $rec
    $recBtnGuardar = New-FlatButton "GUARDAR"      292  81 100 26 $cPink   $rec
    $recBtnAddDly  = New-FlatButton "+DELAY"       397  81 73  26 $cBorder $rec
    $recBtnAddMsg  = New-FlatButton "+MSG"         475  81 61  26 $cBorder $rec

    $sep2 = New-Object System.Windows.Forms.Panel
    $sep2.Location=New-Object System.Drawing.Point(3,113); $sep2.Size=New-Object System.Drawing.Size(534,2); $sep2.BackColor=$cBorder
    $rec.Controls.Add($sep2)

    $lblLog = New-Object System.Windows.Forms.Label
    $lblLog.Text="Acoes capturadas  [duplo-clique p/ editar | clique-direito p/ opcoes | col X p/ apagar]"
    $lblLog.Location=New-Object System.Drawing.Point(5,117); $lblLog.Size=New-Object System.Drawing.Size(530,16)
    $lblLog.ForeColor=$cAccent; $lblLog.Font=$fontSm; $rec.Controls.Add($lblLog)

    # ── DataGridView ──────────────────────────────────────────────
    $dgv = New-Object System.Windows.Forms.DataGridView
    $dgv.Location=New-Object System.Drawing.Point(3,135); $dgv.Size=New-Object System.Drawing.Size(534,415)
    $dgv.AllowUserToAddRows=$false; $dgv.AllowUserToDeleteRows=$false; $dgv.RowHeadersVisible=$false
    $dgv.SelectionMode="FullRowSelect"; $dgv.MultiSelect=$false
    $dgv.BackgroundColor=$cSurface; $dgv.GridColor=$cBorder; $dgv.BorderStyle="None"; $dgv.EnableHeadersVisualStyles=$false
    $dgv.DefaultCellStyle.BackColor=$cSurface; $dgv.DefaultCellStyle.ForeColor=$cText; $dgv.DefaultCellStyle.Font=$fontSm
    $dgv.DefaultCellStyle.SelectionBackColor=[System.Drawing.Color]::FromArgb(60,98,224,239)
    $dgv.DefaultCellStyle.SelectionForeColor=$cAccent
    $dgv.ColumnHeadersDefaultCellStyle.BackColor=$cBg; $dgv.ColumnHeadersDefaultCellStyle.ForeColor=$cAccent
    $dgv.ColumnHeadersDefaultCellStyle.Font=$fontSm
    $dgv.ColumnHeadersHeight=22; $dgv.ColumnHeadersHeightSizeMode="DisableResizing"; $dgv.RowTemplate.Height=20
    $rec.Controls.Add($dgv)

    # Colunas
    $mkCol = { param($n,$h,$w,$ro=$false)
        $c=New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $c.Name=$n; $c.HeaderText=$h; $c.Width=$w; $c.ReadOnly=$ro; $c.SortMode="NotSortable"; return $c }
    $colDel=New-Object System.Windows.Forms.DataGridViewButtonColumn
    $colDel.Name="Del"; $colDel.HeaderText=""; $colDel.Width=26; $colDel.Text="X"
    $colDel.UseColumnTextForButtonValue=$true; $colDel.SortMode="NotSortable"
    $dgv.Columns.AddRange([System.Windows.Forms.DataGridViewColumn[]]@(
        (& $mkCol "Type" "Tipo"       105 $true),
        (& $mkCol "X"    "X"           42),
        (& $mkCol "Y"    "Y"           42),
        (& $mkCol "Ms"   "Ms"          55),
        (& $mkCol "Text" "Texto / Msg" 200),
        (& $mkCol "Load" "Load"        38),
        $colDel
    ))
    $dgv.Columns["Text"].AutoSizeMode = "Fill"

    # ── Context menu ──────────────────────────────────────────────
    $ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxMenu.BackColor=$cBg; $ctxMenu.ForeColor=$cText; $ctxMenu.Font=$fontSm
    $miInsDelay = New-Object System.Windows.Forms.ToolStripMenuItem("+  Inserir Delay acima")
    $miInsMsg   = New-Object System.Windows.Forms.ToolStripMenuItem("+  Inserir Mensagem acima")
    $miDelRow   = New-Object System.Windows.Forms.ToolStripMenuItem("X  Apagar linha")
    $miUp       = New-Object System.Windows.Forms.ToolStripMenuItem([char]0x25B2 + "  Subir")
    $miDown     = New-Object System.Windows.Forms.ToolStripMenuItem([char]0x25BC + "  Descer")
    $ctxMenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]]@(
        $miInsDelay, $miInsMsg,
        (New-Object System.Windows.Forms.ToolStripSeparator),
        $miDelRow,
        (New-Object System.Windows.Forms.ToolStripSeparator),
        $miUp, $miDown
    ))
    $dgv.ContextMenuStrip = $ctxMenu

    # ── Estado global (evita problemas de scope com PS7 + closures) ──
    $script:recCtl = @{
        dgv=         $dgv
        lblStatus=   $lblStatus
        btnGravar=   $recBtnGravar
        numDly=      $numDly
        txtNome=     $txtNome
        parentCbo=   $parentComboBox
        logCount=    0
        previewRow=  -1
        wasRecording=$false
        timerRec=    $null
    }

    # ── Timer ─────────────────────────────────────────────────────
    $timerRec = New-Object System.Windows.Forms.Timer; $timerRec.Interval=150
    $timerRec.add_Tick({
        $ctl=$script:recCtl; if($null -eq $ctl){return}
        $dg=$ctl.dgv
        # Novos ActionJsonLines → linhas no grid
        $total=[MacroRecorder]::ActionJsonLines.Count
        while($ctl.logCount -lt $total){
            try {
                $action=[MacroRecorder]::ActionJsonLines[$ctl.logCount] | ConvertFrom-Json
                $xv="";$yv="";$msv="";$txtv="";$ldv=""
                switch($action.Type){
                    {$_ -in "Click","RightClick","MoveMouse"}{$xv=$action.X;$yv=$action.Y}
                    "Delay"   {$msv=$action.Milliseconds;$txtv=$action.Message;$ldv=$action.Load}
                    "TypeText"{$txtv=$action.Text}
                    "Message" {$txtv=$action.Text}
                }
                if($ctl.previewRow -ge 0 -and $ctl.previewRow -lt $dg.Rows.Count){
                    $r=$dg.Rows[$ctl.previewRow]
                    $r.Cells["Type"].Value=$action.Type;$r.Cells["X"].Value=$xv;$r.Cells["Y"].Value=$yv
                    $r.Cells["Ms"].Value=$msv;$r.Cells["Text"].Value=$txtv;$r.Cells["Load"].Value=$ldv
                    $ctl.previewRow=-1
                } else {
                    $dg.Rows.Add($action.Type,$xv,$yv,$msv,$txtv,$ldv,"X") | Out-Null
                }
                if($dg.Rows.Count -gt 0){$dg.FirstDisplayedScrollingRowIndex=$dg.Rows.Count-1}
            } catch {}
            $ctl.logCount++
        }
        # Preview de texto em digitação
        $preview=[MacroRecorder]::TextPreview
        if($preview -ne ""){
            $preview=$preview -replace '^> ',''
            if($ctl.previewRow -lt 0){
                $dg.Rows.Add("TypeText...","","","",($preview),"","X") | Out-Null
                $ctl.previewRow=$dg.Rows.Count-1
                if($dg.Rows.Count -gt 0){$dg.FirstDisplayedScrollingRowIndex=$dg.Rows.Count-1}
            } else {
                $dg.Rows[$ctl.previewRow].Cells["Text"].Value=$preview
            }
        }
        # Detecção de paragem via F9 (C# hook)
        if($ctl.wasRecording -and -not [MacroRecorder]::IsRecording){
            $ctl.wasRecording=$false
            $ctl.lblStatus.Text="Parado. $([MacroRecorder]::ActionLog.Count) acoes."
            $ctl.lblStatus.ForeColor=$cOrange
            $ctl.btnGravar.ForeColor=$cGreen;$ctl.btnGravar.FlatAppearance.BorderColor=$cGreen
            $ctl.btnGravar.Text="GRAVAR [F9]"
        }
    })
    $script:recCtl.timerRec=$timerRec

    # ── Botão X na coluna Del ─────────────────────────────────────
    $dgv.add_CellClick({
        param($s,$e)
        if($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0 -and $dgv.Columns[$e.ColumnIndex].Name -eq "Del"){
            $ri=$e.RowIndex; $dgv.Rows.RemoveAt($ri)
            $ctl=$script:recCtl
            if($ctl){if($ri -lt $ctl.previewRow){$ctl.previewRow--}elseif($ri -eq $ctl.previewRow){$ctl.previewRow=-1}}
        }
    })

    # ── Helpers inline para context menu ──────────────────────────
    $doInsert = {
        param($type)
        $idx=if($dgv.CurrentRow){$dgv.CurrentRow.Index}else{$dgv.Rows.Count}
        $newRow=New-Object System.Windows.Forms.DataGridViewRow; $newRow.CreateCells($dgv)
        $newRow.Cells[0].Value=$type
        if($type -eq "Delay"){$newRow.Cells[3].Value="500";$newRow.Cells[5].Value="0"}
        $newRow.Cells[6].Value="X"
        $dgv.Rows.Insert($idx,$newRow)
        $ctl=$script:recCtl; if($ctl -and $ctl.previewRow -ge $idx){$ctl.previewRow++}
        try{$focusCol=if($type -eq "Delay"){"Ms"}else{"Text"}; $dgv.CurrentCell=$dgv.Rows[$idx].Cells[$focusCol]}catch{}
    }
    $doSwap = {
        param($a,$b)
        $n=$dgv.Columns.Count-1
        $va=0..($n-1)|ForEach-Object{$dgv.Rows[$a].Cells[$_].Value}
        $vb=0..($n-1)|ForEach-Object{$dgv.Rows[$b].Cells[$_].Value}
        for($c=0;$c -lt $n;$c++){$dgv.Rows[$a].Cells[$c].Value=$vb[$c];$dgv.Rows[$b].Cells[$c].Value=$va[$c]}
        $ctl=$script:recCtl
        if($ctl){if($ctl.previewRow -eq $a){$ctl.previewRow=$b}elseif($ctl.previewRow -eq $b){$ctl.previewRow=$a}}
    }

    $miInsDelay.add_Click({ & $doInsert "Delay" })
    $miInsMsg.add_Click({   & $doInsert "Message" })
    $miDelRow.add_Click({
        if($dgv.CurrentRow -and $dgv.CurrentRow.Index -ge 0){
            $ri=$dgv.CurrentRow.Index; $dgv.Rows.RemoveAt($ri)
            $ctl=$script:recCtl
            if($ctl){if($ri -lt $ctl.previewRow){$ctl.previewRow--}elseif($ri -eq $ctl.previewRow){$ctl.previewRow=-1}}
        }
    })
    $miUp.add_Click({
        $idx=if($dgv.CurrentRow){$dgv.CurrentRow.Index}else{-1}
        if($idx -le 0){return}
        & $doSwap $idx ($idx-1)
        try{$dgv.CurrentCell=$dgv.Rows[$idx-1].Cells[0]}catch{}
    })
    $miDown.add_Click({
        $idx=if($dgv.CurrentRow){$dgv.CurrentRow.Index}else{-1}
        if($idx -lt 0 -or $idx -ge $dgv.Rows.Count-1){return}
        & $doSwap $idx ($idx+1)
        try{$dgv.CurrentCell=$dgv.Rows[$idx+1].Cells[0]}catch{}
    })

    # ── Botão GRAVAR ──────────────────────────────────────────────
    $recBtnGravar.add_Click({
        if([MacroRecorder]::IsRecording){return}
        $ctl=$script:recCtl
        $ctl.dgv.Rows.Clear();$ctl.logCount=0;$ctl.previewRow=-1
        [MacroRecorder]::ActionLog.Clear();[MacroRecorder]::ActionJsonLines.Clear()
        [MacroRecorder]::OnStop=[Action]{}
        [MacroRecorder]::Start([int]$ctl.numDly.Value)
        $ctl.wasRecording=$true
        $ctl.lblStatus.Text="A gravar... [F9] para parar"
        $ctl.lblStatus.ForeColor=$cGreen
        $ctl.btnGravar.ForeColor=$cRed;$ctl.btnGravar.FlatAppearance.BorderColor=$cRed
        $ctl.btnGravar.Text="A GRAVAR..."
    })

    # ── Botão PARAR ───────────────────────────────────────────────
    $recBtnParar.add_Click({
        [MacroRecorder]::Stop()
        $ctl=$script:recCtl; if(-not $ctl){return}
        $ctl.wasRecording=$false
        $ctl.lblStatus.Text="Parado. $([MacroRecorder]::ActionLog.Count) acoes."
        $ctl.lblStatus.ForeColor=$cOrange
        $ctl.btnGravar.ForeColor=$cGreen;$ctl.btnGravar.FlatAppearance.BorderColor=$cGreen
        $ctl.btnGravar.Text="GRAVAR [F9]"
    })

    # ── Botão LIMPAR ──────────────────────────────────────────────
    $recBtnLimpar.add_Click({
        [MacroRecorder]::Stop()
        [MacroRecorder]::ActionLog.Clear();[MacroRecorder]::ActionJsonLines.Clear()
        $ctl=$script:recCtl; if(-not $ctl){return}
        $ctl.dgv.Rows.Clear();$ctl.logCount=0;$ctl.previewRow=-1;$ctl.wasRecording=$false
        $ctl.lblStatus.Text="Limpo."; $ctl.lblStatus.ForeColor=$cAccent
        $ctl.btnGravar.ForeColor=$cGreen;$ctl.btnGravar.FlatAppearance.BorderColor=$cGreen
        $ctl.btnGravar.Text="GRAVAR [F9]"
    })

    # ── Botão +DELAY ──────────────────────────────────────────────
    $recBtnAddDly.add_Click({
        $ctl=$script:recCtl; if(-not $ctl){return}
        $newRow=New-Object System.Windows.Forms.DataGridViewRow; $newRow.CreateCells($ctl.dgv)
        $newRow.Cells[0].Value="Delay";$newRow.Cells[3].Value="500";$newRow.Cells[5].Value="0";$newRow.Cells[6].Value="X"
        $ctl.dgv.Rows.Add($newRow) | Out-Null
        $li=$ctl.dgv.Rows.Count-1; $ctl.dgv.FirstDisplayedScrollingRowIndex=$li
        try{$ctl.dgv.CurrentCell=$ctl.dgv.Rows[$li].Cells["Ms"]}catch{}
    })

    # ── Botão +MSG ────────────────────────────────────────────────
    $recBtnAddMsg.add_Click({
        $ctl=$script:recCtl; if(-not $ctl){return}
        $newRow=New-Object System.Windows.Forms.DataGridViewRow; $newRow.CreateCells($ctl.dgv)
        $newRow.Cells[0].Value="Message";$newRow.Cells[6].Value="X"
        $ctl.dgv.Rows.Add($newRow) | Out-Null
        $li=$ctl.dgv.Rows.Count-1; $ctl.dgv.FirstDisplayedScrollingRowIndex=$li
        try{$ctl.dgv.CurrentCell=$ctl.dgv.Rows[$li].Cells["Text"]}catch{}
    })

    # ── Botão GUARDAR ─────────────────────────────────────────────
    $recBtnGuardar.add_Click({
        [MacroRecorder]::Stop()
        $ctl=$script:recCtl; if(-not $ctl){return}
        $ctl.wasRecording=$false
        $nome=$ctl.txtNome.Text.Trim()
        if(-not $nome){$ctl.lblStatus.Text="Introduz um nome.";return}
        if($ctl.dgv.Rows.Count -eq 0){$ctl.lblStatus.Text="Nenhuma acao gravada.";return}
        # Reconstruir ActionJsonLines a partir do grid editado
        [MacroRecorder]::ActionJsonLines.Clear()
        foreach($row in $ctl.dgv.Rows){
            $type=$row.Cells["Type"].Value
            if([string]::IsNullOrEmpty($type) -or $type -like "TypeText...*"){continue}
            $xv=$row.Cells["X"].Value;  $yv=$row.Cells["Y"].Value
            $msv=$row.Cells["Ms"].Value;$txtv=$row.Cells["Text"].Value;$ldv=$row.Cells["Load"].Value
            $jline=$null
            if($type -in "Click","RightClick","MoveMouse"){
                $xi=if($xv -match '^-?\d+$'){[int]$xv}else{0}
                $yi=if($yv -match '^-?\d+$'){[int]$yv}else{0}
                $jline='{"Type":"'+$type+'","X":'+$xi+',"Y":'+$yi+'}'
            } elseif($type -eq "Delay"){
                $mi=if($msv -match '^\d+$'){[int]$msv}else{0}
                $li=if($ldv -match '^\d+$'){[int]$ldv}else{0}
                $te=if($txtv){$txtv.Replace('\','\\').Replace('"','\"')}else{''}
                $jline='{"Type":"Delay","Milliseconds":'+$mi+',"Message":"'+$te+'","Load":'+$li+'}'
            } elseif($type -eq "TypeText"){
                $te=if($txtv){$txtv.Replace('\','\\').Replace('"','\"')}else{''}
                $jline='{"Type":"TypeText","Text":"'+$te+'"}'
            } elseif($type -eq "Message"){
                $te=if($txtv){$txtv.Replace('\','\\').Replace('"','\"')}else{''}
                $jline='{"Type":"Message","Text":"'+$te+'"}'
            } else {
                $jline='{"Type":"'+$type+'"}'
            }
            if($jline){[MacroRecorder]::ActionJsonLines.Add($jline) | Out-Null}
        }
        $ok=Save-RecordedMacro -name $nome
        if($ok){
            $script:macros=Load-Macros
            $ctl.parentCbo.Items.Clear()
            foreach($k in $script:macros.Keys){$ctl.parentCbo.Items.Add($k) | Out-Null}
            $ctl.lblStatus.Text="Guardado: $nome"; $ctl.lblStatus.ForeColor=$cGreen
            [MacroRecorder]::ActionLog.Clear();[MacroRecorder]::ActionJsonLines.Clear()
            $ctl.dgv.Rows.Clear();$ctl.logCount=0;$ctl.previewRow=-1
        } else {$ctl.lblStatus.Text="Erro ao guardar."}
    })

    # ── F9 inicia gravação ────────────────────────────────────────
    $rec.add_KeyDown({
        param($s,$e)
        if($e.KeyCode -eq [System.Windows.Forms.Keys]::F9 -and -not [MacroRecorder]::IsRecording){
            $script:recCtl.btnGravar.PerformClick(); $e.SuppressKeyPress=$true
        }
    })

    # ── FormClosing ───────────────────────────────────────────────
    $rec.add_FormClosing({
        [MacroRecorder]::Stop()
        if($script:recCtl){
            $script:recCtl.wasRecording=$false
            $script:recCtl.timerRec.Stop()
        }
        $script:recCtl=$null
    })

    $timerRec.Start()
    $rec.Show()
}
# ── fim Open-RecorderForm ─────────────────────────────────────────


# ============================================================
#  FORMULARIO EXECUTOR (principal)
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "MacroExecutor"; $form.Size = New-Object System.Drawing.Size(500, 345)
$form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "None"
$form.BackColor = $cBg; $form.ForeColor = $cText; $form.Font = $font
$form.add_Paint({ param($s,$e) $pen=New-Object System.Drawing.Pen($cAccent,3); $e.Graphics.DrawRectangle($pen,1,1,($form.Width-3),($form.Height-3)); $pen.Dispose() })

New-TitleBar $form "MacroExecutor" 500 | Out-Null

# Macro selector
$lblM = New-Object System.Windows.Forms.Label
$lblM.Text="Macro:"; $lblM.Location=New-Object System.Drawing.Point(10,52); $lblM.Size=New-Object System.Drawing.Size(55,20); $lblM.ForeColor=$cAccent
$form.Controls.Add($lblM)

$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location=New-Object System.Drawing.Point(68,50); $comboBox.Size=New-Object System.Drawing.Size(416,20)
$comboBox.DropDownStyle="DropDownList"; $comboBox.BackColor=$cSurface; $comboBox.ForeColor=$cText; $comboBox.FlatStyle="Flat"
foreach ($k in $script:macros.Keys) { $comboBox.Items.Add($k) | Out-Null }
$comboBox.add_SelectedIndexChanged({ $script:selectedMacro = $comboBox.SelectedItem })
$form.Controls.Add($comboBox)
$script:comboBox = $comboBox

$sep1 = New-Object System.Windows.Forms.Panel
$sep1.Location=New-Object System.Drawing.Point(3,76); $sep1.Size=New-Object System.Drawing.Size(494,2); $sep1.BackColor=$cBorder
$form.Controls.Add($sep1)

# Row 1: botoes de acao
$btnPlay    = New-FlatButton "PLAY"   5   83 91 28 $cGreen  $form
$btnPause   = New-FlatButton "PAUSA" 100  83 91 28 $cOrange $form
$btnStop    = New-FlatButton "STOP"  195  83 91 28 $cRed    $form
$btnGravar  = New-FlatButton "GRAVAR" 290 83 91 28 $cPink   $form
$btnPasta   = New-FlatButton "PASTA" 385  83 91 28 $cAccent $form
$btnRefresh = New-FlatButton "○"     479  83 18 28 $cBorder $form

# Row 2: loop / repeat — linha separada para nao sobrepor os botoes
$chkLoop = New-Object System.Windows.Forms.CheckBox
$chkLoop.Text="Loop"; $chkLoop.Location=New-Object System.Drawing.Point(8,118); $chkLoop.Size=New-Object System.Drawing.Size(60,20); $chkLoop.ForeColor=$cAccent
$form.Controls.Add($chkLoop)

$chkRepeat = New-Object System.Windows.Forms.CheckBox
$chkRepeat.Text="Repetir"; $chkRepeat.Location=New-Object System.Drawing.Point(75,118); $chkRepeat.Size=New-Object System.Drawing.Size(68,20); $chkRepeat.ForeColor=$cAccent
$form.Controls.Add($chkRepeat)

$txtRepeat = New-Object System.Windows.Forms.TextBox
$txtRepeat.Location=New-Object System.Drawing.Point(147,118); $txtRepeat.Size=New-Object System.Drawing.Size(35,20)
$txtRepeat.BackColor=$cSurface; $txtRepeat.ForeColor=$cText; $txtRepeat.Enabled=$false; $txtRepeat.Text="1"
$form.Controls.Add($txtRepeat)

$lblRepeat = New-Object System.Windows.Forms.Label
$lblRepeat.Text="vezes"; $lblRepeat.Location=New-Object System.Drawing.Point(186,121); $lblRepeat.Size=New-Object System.Drawing.Size(42,16); $lblRepeat.ForeColor=$cBorder; $lblRepeat.Font=$fontSm
$form.Controls.Add($lblRepeat)

$chkLoop.add_CheckedChanged({ if($chkLoop.Checked){$chkRepeat.Checked=$false;$txtRepeat.Enabled=$false} })
$chkRepeat.add_CheckedChanged({ if($chkRepeat.Checked){$chkLoop.Checked=$false;$txtRepeat.Enabled=$true} else{$txtRepeat.Enabled=$false} })

$sep2 = New-Object System.Windows.Forms.Panel
$sep2.Location=New-Object System.Drawing.Point(3,145); $sep2.Size=New-Object System.Drawing.Size(494,2); $sep2.BackColor=$cBorder
$form.Controls.Add($sep2)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline=$true; $outputBox.ScrollBars="Vertical"
$outputBox.Location=New-Object System.Drawing.Point(3,149); $outputBox.Size=New-Object System.Drawing.Size(494,190)
$outputBox.BackColor=$cSurface; $outputBox.ForeColor=$cAccent; $outputBox.BorderStyle="None"; $outputBox.ReadOnly=$true; $outputBox.Font=$font
$form.Controls.Add($outputBox)

# --- Expor globais ---
$script:outputBox          = $outputBox
$script:loopCheckBox       = $chkLoop
$script:repeatCheckBox     = $chkRepeat
$script:repeatCountTextBox = $txtRepeat

# --- Acoes dos botoes ---
$btnPlay.add_Click({
    if ($script:selectedMacro) {
        Start-Macro -macroName $script:selectedMacro
    } else {
        $outputBox.AppendText("Escolhe um macro.`n")
    }
})
$btnPause.add_Click({ Toggle-Pause })
$btnStop.add_Click({ Stop-Macro })
$btnGravar.add_Click({ Open-RecorderForm -parentComboBox $comboBox })
$btnPasta.add_Click({
    $path = $script:macrosFolder
    if (Test-Path $path) { Start-Process explorer.exe -ArgumentList "`"$path`"" }
})
$btnRefresh.add_Click({
    $script:macros = Load-Macros
    $comboBox.Items.Clear()
    foreach ($k in $script:macros.Keys) { $comboBox.Items.Add($k) | Out-Null }
    $outputBox.AppendText("Macros recarregados ($($script:macros.Count))`n")
})

$form.ShowDialog()
