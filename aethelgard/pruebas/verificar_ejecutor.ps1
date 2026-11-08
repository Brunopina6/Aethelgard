<#
  Comprueba que ejecutar_pruebas.ps1 solo cierra lo que lanza él (DECISIONS.md, D-010).
  - Lanza el ejecutor con una lista de una sola prueba, sonda_tiempo, que no termina nunca (8 s de plazo).
  - Con la sonda en marcha abre OTRO Godot: un proyecto vacío en una carpeta temporal y con datos aislados (no toca
    la carpeta real del juego ni este proyecto). Hace de editor o juego ajeno a la prueba.
  - Al acabar la pasada, la sonda (y su proceso hijo) deben estar cerrados, el otro Godot debe seguir vivo y el
    resumen debe apuntarlo entre los «otros Godot». Después cierra el Godot que abrió ella misma.
  Uso, desde D:\Aethelgard_alpha:
    powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\verificar_ejecutor.ps1
  Código de salida: 0 si todo está bien; 1 si algo falla; 2 si ya había un Godot abierto.
#>
param([string]$Godot = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe")

$ErrorActionPreference = "Continue"
if (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Godot*" }) {
    Write-Host "Hay un Godot abierto: ciérralo antes." -ForegroundColor Red
    exit 2
}

$tmp    = Join-Path $env:TEMP ("rebelum_verificar_ejecutor_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$proy   = Join-Path $tmp "proyecto_ajeno"
$datos  = Join-Path $tmp "datos_ajeno"
$pasada = Join-Path $tmp "pasadas"
New-Item -ItemType Directory -Force -Path $proy, (Join-Path $datos "Roaming"), (Join-Path $datos "Local"),
    (Join-Path $datos "Temp"), $pasada | Out-Null
$utf8 = New-Object Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $proy "project.godot"), "config_version=5`n`n[application]`n`nconfig/name=`"Ajeno de prueba`"`n", $utf8)
[IO.File]::WriteAllText((Join-Path $proy "espera.gd"), "extends SceneTree`n`nfunc _initialize() -> void:`n`tcreate_timer(180.0).timeout.connect(quit)`n", $utf8)
$lista = Join-Path $tmp "lista_tiempo.txt"
[IO.File]::WriteAllText($lista, "sonda_tiempo | auto | | 8 | user:// | no termina nunca: el ejecutor debe cerrarla, y solo a ella`n", $utf8)

function Godots([string]$texto) {
    @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$texto*" })
}

# 1. El ejecutor, con la sonda que no termina.
$ejecutor = Join-Path $PSScriptRoot "ejecutar_pruebas.ps1"
$r = Start-Process powershell -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $tmp "ejecutor.txt") `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$ejecutor`" -Lista `"$lista`" -Salida `"$pasada`""
$null = $r.Handle
$limite = (Get-Date).AddSeconds(90)
while ((Godots "sonda_tiempo").Count -eq 0 -and (Get-Date) -lt $limite -and -not $r.HasExited) { Start-Sleep -Milliseconds 300 }
$sondaVista = (Godots "sonda_tiempo").Count
Write-Host "Sonda en marcha: $sondaVista proceso(s)"

# 2. Otro Godot, ajeno a la pasada, con datos aislados.
$orig = @{ A = $env:APPDATA; L = $env:LOCALAPPDATA; T = $env:TEMP; M = $env:TMP }
$env:APPDATA = Join-Path $datos "Roaming"; $env:LOCALAPPDATA = Join-Path $datos "Local"
$env:TEMP = Join-Path $datos "Temp"; $env:TMP = $env:TEMP
try {
    $ajeno = Start-Process -FilePath $Godot -PassThru -WindowStyle Hidden -ArgumentList "--headless --path `"$proy`" --script res://espera.gd"
} finally { $env:APPDATA = $orig.A; $env:LOCALAPPDATA = $orig.L; $env:TEMP = $orig.T; $env:TMP = $orig.M }
Start-Sleep -Seconds 2
Write-Host "Godot ajeno abierto: $((Godots 'espera.gd').Count) proceso(s)"

# 3. Que acabe la pasada (la sonda se cierra a los 8 s).
$null = $r.WaitForExit(180000)
Start-Sleep -Milliseconds 800

$fallos = @()
if ($sondaVista -eq 0) { $fallos += "la sonda no llegó a arrancar" }
$ajenosVivos = Godots "espera.gd"
if ($ajenosVivos.Count -eq 0) { $fallos += "el ejecutor ha cerrado el Godot ajeno" }
if ((Godots "sonda_tiempo").Count -gt 0) { $fallos += "la sonda sigue abierta: el ejecutor no la cerró" }
$resumen = Get-ChildItem $pasada -Recurse -Filter resumen.md -ErrorAction SilentlyContinue | Select-Object -First 1
$textoResumen = if ($resumen) { Get-Content $resumen.FullName -Raw -Encoding UTF8 } else { "" }
if ($textoResumen -notmatch "TIEMPO") { $fallos += "el resumen no marca la sonda por tiempo" }
if ($textoResumen -notmatch "Otros Godot abiertos durante la pasada: \*\*") { $fallos += "el resumen no apunta el Godot ajeno" }
if ($r.ExitCode -ne 1) { $fallos += "el ejecutor devolvió $($r.ExitCode) (esperaba 1: una prueba por tiempo)" }

# 4. Cerrar el Godot que abrió esta comprobación (el suyo, no otro).
foreach ($q in $ajenosVivos) { Stop-Process -Id ([int]$q.ProcessId) -Force -ErrorAction SilentlyContinue }

($textoResumen -split "`r?`n" | Where-Object { $_ -match "Otros Godot|sonda_tiempo \|" }) | ForEach-Object { Write-Host "  $_" }
Write-Host "Archivos de la comprobación: $tmp"
if ($fallos.Count -eq 0) {
    Write-Host "VERIFICADO: el ejecutor cerró la sonda por tiempo y dejó vivo el Godot ajeno, que apuntó en el resumen." -ForegroundColor Green
    exit 0
}
foreach ($f in $fallos) { Write-Host "FALLO: $f" -ForegroundColor Red }
exit 1
