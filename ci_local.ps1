<#
  Integración continua LOCAL de REBELUM (10/11): lo que hay que hacer antes de dar por buena una rama, en un paso.
    1. Importación aislada de Godot (APPDATA, LOCALAPPDATA, TEMP y TMP en una carpeta de diagnóstico).
    2. Deshace lo que la importación sin editor cambia en project.godot (borra el registro de personajes de Dialogic):
       solo si project.godot no tenía cambios antes de importar.
    3. La batería completa (aethelgard/pruebas/ejecutar_pruebas.ps1), que ya incluye la auditoría de recursos.
  No compila ni publica nada, no toca la partida real y no hace commits. Sale con 0 si todo pasa.
  Uso (desde PowerShell, en la raíz de la copia):  powershell -ExecutionPolicy Bypass -File .\ci_local.ps1
#>
param(
    [string]$Godot = $(if ($env:REBELUM_GODOT) { $env:REBELUM_GODOT } else { "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe" }),
    [string]$Diagnostico = "D:\REBELUM_diagnostico"
)
$ErrorActionPreference = "Continue"
$raiz = $PSScriptRoot
$proyecto = Join-Path $raiz "aethelgard"
if (-not (Test-Path $Godot)) { Write-Host "No encuentro Godot en $Godot" -ForegroundColor Red; exit 255 }

# 1. Importación aislada
$marca = Get-Date -Format "yyyy-MM-dd_HHmmss"
$imp = Join-Path $Diagnostico "importaciones\ci_$marca"
New-Item -ItemType Directory -Force (Join-Path $imp "appdata"), (Join-Path $imp "local"), (Join-Path $imp "temp") | Out-Null
$godotLimpio = -not (git -C $raiz status --porcelain -- aethelgard/project.godot)
$o = @{A=$env:APPDATA; L=$env:LOCALAPPDATA; T=$env:TEMP; M=$env:TMP}
$env:APPDATA = Join-Path $imp "appdata"; $env:LOCALAPPDATA = Join-Path $imp "local"
$env:TEMP = Join-Path $imp "temp"; $env:TMP = Join-Path $imp "temp"
try {
    & $Godot --headless --path $proyecto --import *> (Join-Path $imp "import.log")
} finally {
    $env:APPDATA = $o.A; $env:LOCALAPPDATA = $o.L; $env:TEMP = $o.T; $env:TMP = $o.M
}
Write-Host "Importación aislada: $imp"

# 2. project.godot como estaba (si estaba limpio)
if ($godotLimpio -and (git -C $raiz status --porcelain -- aethelgard/project.godot)) {
    git -C $raiz restore -- aethelgard/project.godot
    Write-Host "project.godot: deshecho el cambio de la importación (registro de Dialogic)"
}

# 3. Batería completa
& (Join-Path $proyecto "pruebas\ejecutar_pruebas.ps1") -Godot $Godot
$codigo = $LASTEXITCODE
if ($codigo -eq 0) { Write-Host "CI LOCAL: todo superado" -ForegroundColor Green } else { Write-Host "CI LOCAL: código $codigo" -ForegroundColor Red }
exit $codigo
