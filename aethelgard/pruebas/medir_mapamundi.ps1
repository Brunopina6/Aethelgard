<#
  MEDIDA del mapamundi (T-085, fase 2): el mapa de siempre («antes») frente al pintado («después»), con y sin agua
  animada: carga, tiempo por fotograma (quieto y andando), memoria de vídeo y estática.
  NO LA EJECUTES CON OTRA CARGA EN EL PC (otros Godot, compilaciones, juegos, vídeos): falsea la medida. El
  coordinador decide el hueco.

  Uso:
    powershell -ExecutionPolicy Bypass -File <copia>\aethelgard\pruebas\medir_mapamundi.ps1
    powershell -ExecutionPolicy Bypass -File <copia>\aethelgard\pruebas\medir_mapamundi.ps1 -Repeticiones 5 -Experimental
    powershell -ExecutionPolicy Bypass -File <copia>\aethelgard\pruebas\medir_mapamundi.ps1 -Ventana 1600x720
  - Se niega a empezar si hay cualquier Godot abierto (de cualquier copia) o si la CPU pasa del 20 % en reposo.
    -Forzar lo salta (y lo apunta en el resumen: esa medida no vale para decidir).
  - Datos aislados (APPDATA, LOCALAPPDATA, TEMP y TMP propios), como ejecutar_pruebas.ps1. Cada condición empieza en
    una carpeta de datos nueva («en frío»: sin caché de sombreados) y repite en la misma («en caliente»).
  - Condiciones: clasico («-- mapa_clasico», el antes), pintado (con agua animada) y pintado_agua_quieta
    («-- agua_quieta»), en orden alterno en cada repetición. -Experimental añade «3d» (con Pastos Verdes, como la app
    experimental del móvil).
  - Cada proceso: res://pruebas/medir_mapamundi.gd (ventana, sin sincronía vertical, sin tope de FPS, --fixed-fps 30).
  - Resultados en <Salida>\<fecha_hora>\: un JSON por proceso, resumen.csv y resumen.md (medianas de las
    repeticiones y diferencia con el mapa de siempre), con la huella de la carpeta real de datos antes y después.
  Código de salida: 0 bien; 2 hay carga en el PC (sin -Forzar); 3 algún proceso falló; 254 cambió la carpeta real
  de datos; 255 falta Godot.
#>
param(
    [int]$Repeticiones = 3,
    [int]$Fotogramas = 600,
    [string]$Ventana = "1280x720",
    [switch]$Experimental,
    [switch]$Forzar,
    [string]$Godot = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Salida = "D:\REBELUM_diagnostico\mapamundi\medidas"
)

$ErrorActionPreference = "Continue"
$proyecto = Split-Path $PSScriptRoot -Parent
$raiz = Split-Path $proyecto -Parent
$dir = Join-Path $Salida (Get-Date -Format "yyyy-MM-dd_HHmmss")
$datosReales = Join-Path $env:APPDATA "Godot\app_userdata\Aethelgard"
if (-not (Test-Path $Godot)) { Write-Host "No encuentro Godot en $Godot" -ForegroundColor Red; exit 255 }

# ------------------------------------------------------------------ ¿hay otra carga?
$avisos = @()
$godots = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue)
if ($godots.Count -gt 0) { $avisos += "hay $($godots.Count) procesos de Godot abiertos: " + (($godots | ForEach-Object { "PID $($_.ProcessId)" }) -join ", ") }
$cpu = @()
for ($i = 0; $i -lt 5; $i++) {
    $cpu += (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    Start-Sleep -Milliseconds 600
}
$cpuMedia = [math]::Round(($cpu | Measure-Object -Average).Average, 1)
if ($cpuMedia -gt 20) { $avisos += "la CPU está al $cpuMedia % en reposo" }
if ($avisos.Count -gt 0 -and -not $Forzar) {
    Write-Host "No mido: $($avisos -join '; '). Espera a un hueco sin otra carga (o -Forzar, que no vale para decidir)." -ForegroundColor Red
    exit 2
}
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Huellas([string]$carpeta) {
    $h = @{}
    if (Test-Path $carpeta) {
        Get-ChildItem $carpeta -Recurse -File -Force | ForEach-Object {
            $h[$_.FullName.Substring($carpeta.Length)] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    return $h
}
$huellasAntes = Huellas $datosReales
$commit = (& git -C $raiz rev-parse --short HEAD 2>$null)
$cambios = (& git -C $raiz status --porcelain 2>$null | Measure-Object).Count

# ------------------------------------------------------------------ las medidas
$condiciones = @(
    @{ n = "clasico"; a = "mapa_clasico" },
    @{ n = "pintado"; a = "" },
    @{ n = "pintado_agua_quieta"; a = "agua_quieta" }
)
$fallos = 0
function Medir([string]$nombre, [string]$extra, [string]$datos, [string]$carpeta) {
    $orig = @{ A = $env:APPDATA; L = $env:LOCALAPPDATA; T = $env:TEMP; M = $env:TMP }
    New-Item -ItemType Directory -Force -Path (Join-Path $datos "Roaming"), (Join-Path $datos "Local"), (Join-Path $datos "Temp") | Out-Null
    $env:APPDATA = Join-Path $datos "Roaming"; $env:LOCALAPPDATA = Join-Path $datos "Local"
    $env:TEMP = Join-Path $datos "Temp"; $env:TMP = $env:TEMP
    $argumentos = "--path `"$proyecto`" --script res://pruebas/medir_mapamundi.gd --fixed-fps 30 -- `"$carpeta`" condicion=$nombre $extra ventana=$Ventana fotogramas=$Fotogramas sin_prologo"
    if ($Experimental) { $argumentos += " 3d" }
    try {
        $log = Join-Path $carpeta "$nombre.log"
        $p = Start-Process -FilePath $Godot -ArgumentList $argumentos -NoNewWindow -PassThru `
            -RedirectStandardOutput $log -RedirectStandardError (Join-Path $carpeta "$nombre.err.log")
        $null = $p.Handle
        if (-not $p.WaitForExit(300000)) {
            $hijos = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $($p.Id)" -ErrorAction SilentlyContinue)
            try { $p.Kill() } catch {}
            foreach ($h in $hijos) { Stop-Process -Id ([int]$h.ProcessId) -Force -ErrorAction SilentlyContinue }
            Write-Host "  $($nombre): TIEMPO agotado" -ForegroundColor Red
            return $false
        }
        $p.WaitForExit()
        $linea = (Get-Content $log -Encoding UTF8 | Select-String "^MEDIDA" | Select-Object -First 1)
        Write-Host "  $linea"
        return ($p.ExitCode -eq 0 -and (Test-Path (Join-Path $carpeta "$nombre.json")))
    } finally { $env:APPDATA = $orig.A; $env:LOCALAPPDATA = $orig.L; $env:TEMP = $orig.T; $env:TMP = $orig.M }
}

for ($r = 1; $r -le $Repeticiones; $r++) {
    $carpeta = Join-Path $dir "r$r"
    New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
    $orden = @(0, 1, 2 | ForEach-Object { $condiciones[($_ + $r - 1) % 3] })     # orden alterno
    Write-Host "Repetición $r de $($Repeticiones): $(($orden | ForEach-Object { $_.n }) -join ', ')"
    foreach ($c in $orden) {
        $datos = Join-Path $dir "datos_aislados\r$($r)_$($c.n)"
        foreach ($t in @("frio", "caliente")) {
            if (-not (Medir "$($c.n)_$t" $c.a $datos $carpeta)) { $fallos++ }
        }
    }
}

# ------------------------------------------------------------------ resumen
function Mediana($xs) {
    $s = @($xs | Where-Object { $_ -ne $null } | Sort-Object)
    if ($s.Count -eq 0) { return $null }
    if ($s.Count % 2 -eq 1) { return $s[[int](($s.Count - 1) / 2)] }
    return ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2
}
$filas = @()
foreach ($c in $condiciones) {
    foreach ($t in @("frio", "caliente")) {
        $js = @(Get-ChildItem $dir -Recurse -Filter "$($c.n)_$t.json" | ForEach-Object { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
        if ($js.Count -eq 0) { continue }
        $filas += [pscustomobject]@{
            condicion = $c.n; carga = $t; n = $js.Count
            carga_ms = Mediana ($js | ForEach-Object { $_.carga_ms })
            quieto_mediana_ms = Mediana ($js | ForEach-Object { $_.fotograma_ms.quieto.mediana })
            quieto_p95_ms = Mediana ($js | ForEach-Object { $_.fotograma_ms.quieto.p95 })
            andando_mediana_ms = Mediana ($js | ForEach-Object { $_.fotograma_ms.andando.mediana })
            andando_p95_ms = Mediana ($js | ForEach-Object { $_.fotograma_ms.andando.p95 })
            andando_peor_ms = Mediana ($js | ForEach-Object { $_.fotograma_ms.andando.peor })
            gpu_andando_ms = Mediana ($js | ForEach-Object { $_.gpu_ms.andando.mediana })
            video_mb = Mediana ($js | ForEach-Object { $_.memoria.quieto.video_mb })
            texturas_mb = Mediana ($js | ForEach-Object { $_.memoria.quieto.texturas_mb })
            estatica_mb = Mediana ($js | ForEach-Object { $_.memoria.quieto.estatica_mb })
            estatica_base_mb = Mediana ($js | ForEach-Object { $_.memoria.base.estatica_mb })
            video_base_mb = Mediana ($js | ForEach-Object { $_.memoria.base.video_mb })
        }
    }
}
$filas | Export-Csv -Path (Join-Path $dir "resumen.csv") -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$huellasDespues = Huellas $datosReales
$cambiados = @()
foreach ($k in $huellasAntes.Keys) { if (-not $huellasDespues.ContainsKey($k) -or $huellasDespues[$k] -ne $huellasAntes[$k]) { $cambiados += $k } }
foreach ($k in $huellasDespues.Keys) { if (-not $huellasAntes.ContainsKey($k)) { $cambiados += $k } }
$equipo = $null
$uno = Get-ChildItem $dir -Recurse -Filter "*.json" | Select-Object -First 1
if ($uno) { $equipo = (Get-Content $uno.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).equipo }

$f = { param($x) if ($x -eq $null) { "—" } else { "{0:N2}" -f [double]$x } }
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Medida del mapamundi (T-085): $(Split-Path $dir -Leaf)")
$md.Add("")
$md.Add("- Copia: ``$raiz`` @ ``$commit`` ($cambios archivos con cambios sin confirmar)")
if ($equipo) { $md.Add("- Equipo: $($equipo.gpu) ($($equipo.api)), $($equipo.cpu), $($equipo.nucleos) hilos; $($equipo.renderizador)") }
$md.Add("- Ventana $Ventana · $Fotogramas fotogramas por fase · $Repeticiones repeticiones (medianas) · " + $(if ($Experimental) { "versión experimental (3d)" } else { "sin 3d" }))
$md.Add("- Carga en el PC al empezar: CPU $cpuMedia % · " + $(if ($avisos.Count -gt 0) { "**FORZADA con avisos: $($avisos -join '; ') (no vale para decidir)**" } else { "sin otros Godot" }))
$md.Add("- Carpeta real de datos: " + $(if ($cambiados.Count -eq 0) { "**sin cambios**" } else { "**CAMBIOS:** " + ($cambiados -join "; ") }))
$md.Add("- Procesos fallidos: $fallos")
$md.Add("")
$md.Add("| Condición | Carga | n | Carga (ms) | Quieto mediana / p95 (ms) | Andando mediana / p95 / peor (ms) | GPU andando (ms) | Vídeo (MB) | Texturas (MB) | Estática (MB) |")
$md.Add("|---|---|---|---|---|---|---|---|---|---|")
foreach ($x in $filas) {
    $md.Add("| $($x.condicion) | $($x.carga) | $($x.n) | $(& $f $x.carga_ms) | $(& $f $x.quieto_mediana_ms) / $(& $f $x.quieto_p95_ms) | $(& $f $x.andando_mediana_ms) / $(& $f $x.andando_p95_ms) / $(& $f $x.andando_peor_ms) | $(& $f $x.gpu_andando_ms) | $(& $f $x.video_mb) | $(& $f $x.texturas_mb) | $(& $f $x.estatica_mb) |")
}
$md.Add("")
$md.Add("Diferencia con el mapa de siempre (misma carga, medianas):")
$md.Add("")
foreach ($t in @("frio", "caliente")) {
    $base = $filas | Where-Object { $_.condicion -eq "clasico" -and $_.carga -eq $t } | Select-Object -First 1
    if (-not $base) { continue }
    foreach ($x in ($filas | Where-Object { $_.condicion -ne "clasico" -and $_.carga -eq $t })) {
        $md.Add("- $($x.condicion) ($t): carga $(& $f ($x.carga_ms - $base.carga_ms)) ms · andando $(& $f ($x.andando_mediana_ms - $base.andando_mediana_ms)) ms · vídeo $(& $f ($x.video_mb - $base.video_mb)) MB · texturas $(& $f ($x.texturas_mb - $base.texturas_mb)) MB · estática $(& $f ($x.estatica_mb - $base.estatica_mb)) MB")
    }
}
$md | Set-Content -Path (Join-Path $dir "resumen.md") -Encoding UTF8
Write-Host ""
Write-Host "Resumen: $(Join-Path $dir 'resumen.md')"
if ($cambiados.Count -gt 0) { exit 254 }
if ($fallos -gt 0) { exit 3 }
exit 0
