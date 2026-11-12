# Medida de las escenas principales en el PC (medir_escenas.gd), un proceso por escena y perfil, con datos aislados.
#   .\medir_escenas.ps1 -Salida <carpeta> [-Escenas titulo,pastos,...] [-Perfiles medio] [-Ciclos 3] [-Etiqueta x]
# Antes de cada pasada apunta en <carpeta>\procesos.txt los Godot, Blender y compiladores que estén corriendo (si los
# hay, la pasada compite por la CPU y la GPU: compárese solo con pasadas en las mismas condiciones).
param([Parameter(Mandatory)][string]$Salida,
	[string[]]$Escenas = @("titulo", "pastos", "garganta", "oakhaven", "granbosque", "marcristal", "combate_brama", "combate3"),
	[string[]]$Perfiles = @("medio"), [int]$Ciclos = 3, [string]$Etiqueta = "", [string[]]$Extra = @())
$godot = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe"
$proyecto = Split-Path $PSScriptRoot
New-Item -ItemType Directory -Force $Salida | Out-Null
$datos = Join-Path $Salida "datos_aislados"
foreach ($p in $Perfiles) { foreach ($e in $Escenas) {
	$otros = Get-Process | Where-Object { $_.ProcessName -match "^(Godot|blender|gradle|java|ffmpeg)" } |
		ForEach-Object { "$($_.ProcessName)#$($_.Id) cpu=$([math]::Round($_.CPU,0))s" }
	"$(Get-Date -Format s) $e $p : $($otros -join ', ')" | Add-Content (Join-Path $Salida "procesos.txt")
	Remove-Item -Recurse -Force $datos -ErrorAction SilentlyContinue
	New-Item -ItemType Directory -Force "$datos\R", "$datos\L" | Out-Null
	$env:APPDATA = "$datos\R"; $env:LOCALAPPDATA = "$datos\L"
	$a = @("--path", $proyecto, "--script", "res://pruebas/medir_escenas.gd", "--fixed-fps", "30", "--", $Salida,
		"escena=$e", "perfil=$p", "ciclos=$Ciclos", "3d", "sin_prologo", "auto")
	if ($Etiqueta) { $a += "etiqueta=$Etiqueta" }
	$a += $Extra
	$log = Join-Path $Salida "log_${e}_$p$(if ($Etiqueta) {"_$Etiqueta"}).txt"
	$t = Measure-Command { & $godot @a *> $log }
	"$e $p : $([math]::Round($t.TotalSeconds,0)) s, $(Select-String -Path $log -Pattern '^MEDICION' -Quiet)"
}}
