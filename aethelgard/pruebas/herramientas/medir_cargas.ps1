<#
  Lanza pruebas/herramientas/medir_cargas.gd CON VENTANA y con DATOS AISLADOS (V12, 12/11, rendimiento de cargas).
  Cada pasada crea su carpeta (Roaming, Local y Temp) en D:\REBELUM_diagnostico\v12\cargas\<fecha>_<etiqueta> y desvía
  APPDATA, LOCALAPPDATA, TEMP y TMP a ella: user:// (la partida de la medida y la caché de sombreadores) empieza vacío,
  como en una instalación nueva. Con -Repetir, la segunda pasada reutiliza esa carpeta (caché ya llena: el segundo
  arranque). Se niega si ya hay un Godot abierto sobre esta misma copia.
  Uso: powershell -ExecutionPolicy Bypass -File aethelgard\pruebas\herramientas\medir_cargas.ps1 -Etiqueta antes
         [-Perfil medio] [-Version 2] [-Combates 3] [-Repetir] [-Extra "otro=1"]
#>
param(
    [string]$Etiqueta = "medida",
    [string]$Perfil = "medio",
    [int]$Version = 0,
    [int]$Combates = 3,
    [switch]$Repetir,
    [string]$Extra = "",
    [string]$Godot = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe"
)
$proyecto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$dir = Join-Path "D:\REBELUM_diagnostico\v12\cargas" ((Get-Date -Format "yyyy-MM-dd_HHmmss") + "_" + $Etiqueta)
foreach ($s in "Roaming", "Local", "Temp") { New-Item -ItemType Directory -Force -Path (Join-Path $dir $s) | Out-Null }
$env:APPDATA = Join-Path $dir "Roaming"; $env:LOCALAPPDATA = Join-Path $dir "Local"
$env:TEMP = Join-Path $dir "Temp"; $env:TMP = $env:TEMP
$argumentos = @("3d", "mardecristal", "perfil=$Perfil", "combates=$Combates")
if ($Version -gt 0) { $argumentos += "bramavidrio_version=$Version" }
if ($Extra -ne "") { $argumentos += ($Extra -split " ") }
$pasadas = if ($Repetir) { 2 } else { 1 }
for ($i = 1; $i -le $pasadas; $i++) {
    $json = Join-Path $dir ("medidas_{0}.json" -f $i)
    $log = Join-Path $dir ("salida_{0}.txt" -f $i)
    $todo = @("--path", $proyecto, "--resolution", "1280x720", "-s", "res://pruebas/herramientas/medir_cargas.gd", "--") +
        $argumentos + @("salida=$($json -replace '\\','/')", "etiqueta=$Etiqueta-$i")
    $todo = $todo | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
    $p = Start-Process -FilePath $Godot -ArgumentList $todo -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError ($log -replace '\.txt$', '_err.txt')
    Write-Host ("Pasada {0}: código {1}; {2}" -f $i, $p.ExitCode, $log)
    Get-Content $log, ($log -replace '\.txt$', '_err.txt') -Encoding UTF8 | Select-String -Pattern "^  \S|ready:|MEDIR_CARGAS|leaked|ObjectDB|ERROR|SCRIPT" | ForEach-Object { $_.Line }
}
Write-Host "Carpeta: $dir"
