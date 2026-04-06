Add-Type @"
using System;
using System.Runtime.InteropServices;
public class User32 {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    public struct POINT {
        public int X;
        public int Y;
    }
}
"@

function Get-CursorPosition {
    $point = New-Object User32+POINT
    [User32]::GetCursorPos([ref]$point) | Out-Null
    return $point
}

# Função para copiar a posição do mouse para a área de transferência
function Copy-MousePosition {
    $pos = Get-CursorPosition
    $posString = "X = $($pos.X); Y = $($pos.Y)"
    Write-Host " Copiado $posString"
    $posString | Set-Clipboard
}

# Pressione F9 para copiar a posição do mouse
while ($true) {

    $pos = Get-CursorPosition
    Write-Host "X=$($pos.X); Y=$($pos.Y)" -NoNewline
    
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "F9") {
            Copy-MousePosition
        }
    }
    Write-Host "`r" -NoNewline
    Start-Sleep -Milliseconds 100
}



