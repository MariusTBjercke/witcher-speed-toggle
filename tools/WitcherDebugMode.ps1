# Reads (and optionally sets) g_cAuroraSettings.m_nDebugMode in the running game.
# Development aid only - the mod itself enables debug mode from testtools.lua.
# Offset from github.com/Injector/WitcherDeveloperConsole (Steam / 1.5.0.1304 build).
# Usage:  powershell -File WitcherDebugMode.ps1          -> read only
#         powershell -File WitcherDebugMode.ps1 -Set 1   -> enable the console (` character)
param([int]$Set = -1)

$offset = 0x85068C

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int size, out int read);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int size, out int written);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@

$proc = Get-Process witcher -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Write-Output "witcher.exe is not running."; exit 1 }

$base = [Int64]$proc.MainModule.BaseAddress
$addr = [IntPtr]($base + $offset)
# PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION
$h = [Mem]::OpenProcess(0x0038 -bor 0x0400, $false, $proc.Id)
if ($h -eq [IntPtr]::Zero) { Write-Output "Could not open the process."; exit 1 }

try {
    $buf = New-Object byte[] 4
    $read = 0
    [void][Mem]::ReadProcessMemory($h, $addr, $buf, 4, [ref]$read)
    Write-Output ("Base 0x{0:X}, m_nDebugMode @ 0x{1:X} = {2}" -f $base, [Int64]$addr, $buf[0])

    if ($Set -ge 0) {
        $written = 0
        $ok = [Mem]::WriteProcessMemory($h, $addr, [byte[]]@([byte]$Set), 1, [ref]$written)
        [void][Mem]::ReadProcessMemory($h, $addr, $buf, 4, [ref]$read)
        Write-Output ("Set to {0} (ok={1}), now reads: {2}" -f $Set, $ok, $buf[0])
    }
}
finally { [void][Mem]::CloseHandle($h) }
