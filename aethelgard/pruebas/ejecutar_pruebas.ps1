<#
  Ejecuta las pruebas de REBELUM en un ENTORNO DE DATOS AISLADO y las clasifica.

  Uso, desde D:\Aethelgard:
    powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1
    powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1 -Manual
    powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1 -Solo prueba_garon,prueba_huir
  -Manual ejecuta también, con ventana, las pruebas que sacan capturas. Una persona tiene que revisarlas.

  AISLAMIENTO
  - Cada pasada crea sus propias carpetas de datos (Roaming, Local y Temp) y lanza Godot con APPDATA,
    LOCALAPPDATA, TEMP y TMP apuntando a ellas. Así, user:// queda dentro de la pasada.
  - Antes de nada se ejecuta la sonda (sonda_datos.gd). Si user:// no cae dentro de la carpeta aislada, NO se
    ejecuta ninguna prueba: todas salen como NO SEGURA.
  - Se toma la huella SHA-256 de toda la carpeta real de datos del juego
    (%APPDATA%\Godot\app_userdata\Aethelgard, partida.save incluida) antes y después. Si cambia algo, se avisa con
    la hora de cada archivo.
  - Esa carpeta es la misma para todas las copias del proyecto (D:\Aethelgard y D:\Aethelgard_alpha): un editor o
    un juego abiertos en cualquiera de ellas escriben ahí. Por eso no se empieza con un Godot abierto y, entre prueba
    y prueba, se mira si alguien ha abierto otro: si aparece, el resumen lo apunta con su línea de órdenes.
  - Al pasarse de tiempo una prueba, solo se cierra lo que lanzó esta pasada (el proceso y sus hijos), nunca otro
    Godot.
  - También se compara «git status» antes y después, para detectar cambios en archivos del proyecto.

  RESULTADOS
    SUPERADA   terminó sola, sin errores de script y sin declarar fallos
    FALLIDA    error de script, código de salida distinto de 0, la prueba imprime FALLO o «FALLOS: n»,
               o no terminó a tiempo (TIEMPO)
    MANUAL     necesita intervención de una persona: capturas que revisar, argumentos que elegir o el móvil
    NO SEGURA  no se puede ejecutar sin riesgo para los datos reales (modo insegura, o sin aislamiento)

  Código de salida:
    número de FALLIDAS (0 = ninguna);
    254 si cambiaron los datos reales del juego;
    255 si no se pudo garantizar el aislamiento o falta Godot.
  Registros, capturas y resumen en D:\REBELUM_diagnostico\pruebas\<fecha_hora>\.
#>
param(
    [switch]$Manual,
    [string[]]$Solo = @(),
    [string]$Godot  = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Salida = "D:\REBELUM_diagnostico\pruebas"
)

$ErrorActionPreference = "Continue"
$Solo = @($Solo | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
$proyecto = Split-Path $PSScriptRoot -Parent
$raizRepo = Split-Path $proyecto -Parent
$lista    = Join-Path $PSScriptRoot "lista_pruebas.txt"
$dir      = Join-Path $Salida (Get-Date -Format "yyyy-MM-dd_HHmmss")
$aislado  = Join-Path $dir "datos_aislados"
New-Item -ItemType Directory -Force -Path (Join-Path $aislado "Roaming"), (Join-Path $aislado "Local"),
    (Join-Path $aislado "Temp") | Out-Null

# Errores de GDScript y del motor que indican un fallo, más los fallos que declaran las propias pruebas.
$PATRONES = @('SCRIPT ERROR', 'Parse Error', 'Failed to load script', 'Invalid call', 'Invalid access',
              'Invalid get index', 'Invalid set index', 'Cannot call method', 'Attempt to call function',
              'Invalid operands', 'Nonexistent function', '\bFALLO\b', 'FALLOS:\s*[1-9]')

$datosReales = Join-Path $env:APPDATA "Godot\app_userdata\Aethelgard"
$partida     = Join-Path $datosReales "partida.save"
$propios     = New-Object 'System.Collections.Generic.HashSet[int]'   # procesos que lanza esta pasada
$ajenos      = [ordered]@{}                                           # Godot abiertos por otros durante la pasada

# Apunta cada Godot abierto que no lanzó esta pasada (ni es hijo de uno suyo).
function Vigilar([string]$momento) {
    foreach ($q in @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue)) {
        if ($propios.Contains([int]$q.ProcessId) -or $propios.Contains([int]$q.ParentProcessId)) { continue }
        $clave = "pid$($q.ProcessId)"                   # clave de texto: con un número, [ordered] indexa por posición
        if (-not $ajenos.Contains($clave)) {
            $ajenos[$clave] = "PID $($q.ProcessId), visto $($momento): $($q.CommandLine)"
            Write-Host "AVISO: hay un Godot que no lanzó esta pasada (PID $($q.ProcessId)); puede escribir en la carpeta real de datos." -ForegroundColor Yellow
        }
    }
}
function Hora([string]$relativa) {
    $f = Join-Path $datosReales $relativa.TrimStart("\")
    if (Test-Path $f) { return (Get-Item $f -Force).LastWriteTime.ToString("HH:mm:ss") } else { return "?" }
}

function Huellas([string]$carpeta) {
    $h = @{}
    if (Test-Path $carpeta) {
        Get-ChildItem $carpeta -Recurse -File -Force | ForEach-Object {
            $h[$_.FullName.Substring($carpeta.Length)] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    return $h
}
function Lanzar([string]$argumentos, [string]$log, [string]$err) {
    $orig = @{ A = $env:APPDATA; L = $env:LOCALAPPDATA; T = $env:TEMP; M = $env:TMP }
    $env:APPDATA = Join-Path $aislado "Roaming"; $env:LOCALAPPDATA = Join-Path $aislado "Local"
    $env:TEMP = Join-Path $aislado "Temp"; $env:TMP = $env:TEMP
    try {
        $p = Start-Process -FilePath $Godot -ArgumentList $argumentos -NoNewWindow -PassThru `
            -RedirectStandardOutput $log -RedirectStandardError $err
        $null = $p.Handle                               # para poder leer ExitCode después (PowerShell 5.1)
        $null = $propios.Add($p.Id)
        return $p
    } finally { $env:APPDATA = $orig.A; $env:LOCALAPPDATA = $orig.L; $env:TEMP = $orig.T; $env:TMP = $orig.M }
}

# ------------------------------------------------------------------ preparación
if (-not (Test-Path $Godot)) { Write-Host "No encuentro Godot en $Godot" -ForegroundColor Red; exit 255 }
if (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Godot*" }) {
    Write-Host "Hay un Godot abierto: ciérralo antes (dos Godot sobre el mismo proyecto se pisan)." -ForegroundColor Red
    exit 255
}
$huellasAntes  = Huellas $datosReales
$partidaAntes  = if (Test-Path $partida) { (Get-FileHash $partida -Algorithm SHA256).Hash } else { "(no existe)" }
$gitAntes      = (& git --no-optional-locks -C $raizRepo status --porcelain 2>$null | Out-String)
Write-Host "partida.save (real) antes: $partidaAntes"

# ------------------------------------------------------------------ sonda de aislamiento
$p = Lanzar "--headless --path `"$proyecto`" --script res://pruebas/sonda_datos.gd" (Join-Path $dir "sonda.log") (Join-Path $dir "sonda.err.log")
$null = $p.WaitForExit(120000)
$sonda = (Get-Content (Join-Path $dir "sonda.log") -Raw -Encoding UTF8)
$userDir = [regex]::Match($sonda, "SONDA_USER_DIR=(.+)").Groups[1].Value.Trim().Replace("/", "\")
$esperado = Join-Path $aislado "Roaming"
$aislamientoOk = ($userDir -ne "") -and $userDir.ToLower().StartsWith($esperado.ToLower())
if ($aislamientoOk) { Write-Host "Aislamiento comprobado: user:// = $userDir" -ForegroundColor Green }
else { Write-Host "AISLAMIENTO NO GARANTIZADO (user:// = '$userDir'): no se ejecuta ninguna prueba" -ForegroundColor Red }

# ------------------------------------------------------------------ pruebas
$filas = New-Object System.Collections.Generic.List[object]
function Fila($n, $m, $r, $s, $d) { $filas.Add([pscustomobject]@{ prueba = $n; modo = $m; resultado = $r; segundos = $s; detalle = $d }) }

foreach ($linea in (Get-Content -Encoding UTF8 $lista)) {
    $t = $linea.Trim()
    if ($t -eq "" -or $t.StartsWith("#")) { continue }
    $c = $t.Split("|") | ForEach-Object { $_.Trim() }
    $nombre = $c[0]; $modo = $c[1]; $argTxt = $c[2]; $seg = [int]$c[3]; $escribe = $c[4]; $nota = $c[5]
    if ($Solo.Count -gt 0 -and $Solo -notcontains $nombre) { continue }

    if (-not $aislamientoOk) { Fila $nombre $modo "NO SEGURA" 0 "sin aislamiento comprobado: no se ejecuta"; continue }
    if ($modo -eq "insegura") { Fila $nombre $modo "NO SEGURA" 0 $nota; continue }
    if ($modo -eq "manual")   { Fila $nombre $modo "MANUAL" 0 $nota; continue }
    if ($modo -eq "ventana" -and -not $Manual) { Fila $nombre $modo "MANUAL" 0 "$nota (con ventana: usa -Manual y revisa las capturas)"; continue }

    $sal = Join-Path $dir $nombre
    New-Item -ItemType Directory -Force -Path $sal | Out-Null
    $argTxt = $argTxt.Replace("{salida}", $sal)
    $argumentos = ""
    if ($modo -eq "auto") { $argumentos = "--headless " }
    $argumentos += "--path `"$proyecto`" --script res://pruebas/$nombre.gd --fixed-fps 30"
    if ($argTxt -ne "") { $argumentos += " -- $argTxt" }
    $log = Join-Path $dir "$nombre.log"; $err = Join-Path $dir "$nombre.err.log"

    Vigilar "antes de $nombre"
    Write-Host ("{0,-20} " -f $nombre) -NoNewline
    $inicio = Get-Date
    $p = Lanzar $argumentos $log $err
    $resultado = ""; $detalle = ""
    if (-not $p.WaitForExit($seg * 1000)) {
        # El Godot «_console» abre el Godot de verdad como hijo: se cierran los dos, y nada más.
        $hijos = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $($p.Id)" -ErrorAction SilentlyContinue)
        try { $p.Kill() } catch {}
        foreach ($h in $hijos) { Stop-Process -Id ([int]$h.ProcessId) -Force -ErrorAction SilentlyContinue }
        $resultado = "FALLIDA"; $detalle = "TIEMPO: más de $seg s"
        Start-Sleep -Milliseconds 300                   # deja que se cierren los registros
        $texto = ""
        if (Test-Path $log) { $texto += (Get-Content $log -Raw -Encoding UTF8) }
        if (Test-Path $err) { $texto += "`n" + (Get-Content $err -Raw -Encoding UTF8) }
        $causa = ($texto -split "`r?`n" | Where-Object { $l = $_; $PATRONES | Where-Object { $l -match $_ } } | Select-Object -First 1)
        if ($causa) { $detalle += " · causa probable: " + ("" + $causa).Trim() }
    } else {
        $p.WaitForExit()
        $texto = ""
        if (Test-Path $log) { $texto += (Get-Content $log -Raw -Encoding UTF8) }
        if (Test-Path $err) { $texto += "`n" + (Get-Content $err -Raw -Encoding UTF8) }
        $hallados = @($PATRONES | Where-Object { $texto -match $_ })
        if ($p.ExitCode -ne 0) { $resultado = "FALLIDA"; $detalle = "código de salida $($p.ExitCode)" }
        elseif ($hallados.Count -gt 0) {
            $resultado = "FALLIDA"
            $primera = ($texto -split "`r?`n" | Where-Object { $l = $_; $hallados | Where-Object { $l -match $_ } } | Select-Object -First 1)
            $detalle = ("" + $primera).Trim()
            if ($detalle.Length -gt 160) { $detalle = $detalle.Substring(0, 160) + "…" }
        } elseif ($modo -eq "ventana") {
            $n = @(Get-ChildItem $sal -File -ErrorAction SilentlyContinue).Count
            $resultado = "MANUAL"; $detalle = "terminó sin errores; $n captura(s) para revisar en $sal"
        } else { $resultado = "SUPERADA" }
    }
    $s = [math]::Round(((Get-Date) - $inicio).TotalSeconds, 1)
    $color = switch ($resultado) { "SUPERADA" { "Green" } "MANUAL" { "Yellow" } default { "Red" } }
    Write-Host ("{0,-9} {1,6} s  {2}" -f $resultado, $s, $detalle) -ForegroundColor $color
    Fila $nombre $modo $resultado $s $detalle
}

# ------------------------------------------------------------------ comprobaciones finales
Vigilar "al terminar"
$huellasDespues = Huellas $datosReales
$partidaDespues = if (Test-Path $partida) { (Get-FileHash $partida -Algorithm SHA256).Hash } else { "(no existe)" }
$gitDespues     = (& git --no-optional-locks -C $raizRepo status --porcelain 2>$null | Out-String)
$cambiados = @()
foreach ($k in $huellasAntes.Keys)   { if (-not $huellasDespues.ContainsKey($k)) { $cambiados += "borrado: $k" } elseif ($huellasDespues[$k] -ne $huellasAntes[$k]) { $cambiados += "cambiado: $k ($(Hora $k))" } }
foreach ($k in $huellasDespues.Keys) { if (-not $huellasAntes.ContainsKey($k)) { $cambiados += "nuevo: $k ($(Hora $k))" } }

$filas | Export-Csv -Path (Join-Path $dir "resumen.csv") -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$cuenta = @{}
foreach ($r in @("SUPERADA", "FALLIDA", "MANUAL", "NO SEGURA")) { $cuenta[$r] = @($filas | Where-Object { $_.resultado -eq $r }).Count }
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Pasada de pruebas: $(Split-Path $dir -Leaf)")
$md.Add("")
$md.Add("- Aislamiento: " + $(if ($aislamientoOk) { "comprobado (user:// = ``$userDir``)" } else { "NO garantizado: no se ejecutó nada" }))
$md.Add("- partida.save real: antes ``$partidaAntes``, después ``$partidaDespues`` → " + $(if ($partidaAntes -eq $partidaDespues) { "**sin cambios**" } else { "**CAMBIADA**" }))
$md.Add("- Carpeta real de datos del juego ($($huellasAntes.Count) archivos): " + $(if ($cambiados.Count -eq 0) { "**sin cambios**" } else { "**CAMBIOS:** " + ($cambiados -join "; ") }))
$md.Add("- Otros Godot abiertos durante la pasada: " + $(if ($ajenos.Count -eq 0) { "ninguno" } else { "**" + $ajenos.Count + "** (los cambios de la carpeta real pueden venir de ellos): " + (@($ajenos.Values) -join "; ") }))
$md.Add("- Archivos del proyecto (git status): " + $(if ($gitAntes -eq $gitDespues) { "**sin cambios**" } else { "**han cambiado** (revisar)" }))
$md.Add("- Totales: SUPERADAS $($cuenta['SUPERADA']) · FALLIDAS $($cuenta['FALLIDA']) · MANUALES $($cuenta['MANUAL']) · NO SEGURAS $($cuenta['NO SEGURA'])")
$md.Add("")
$md.Add("| Prueba | Modo | Resultado | s | Detalle |")
$md.Add("|---|---|---|---|---|")
foreach ($f in $filas) { $md.Add("| $($f.prueba) | $($f.modo) | **$($f.resultado)** | $($f.segundos) | $($f.detalle -replace '\|', '/') |") }
$md | Set-Content -Path (Join-Path $dir "resumen.md") -Encoding UTF8

Write-Host ""
Write-Host "SUPERADAS $($cuenta['SUPERADA']) · FALLIDAS $($cuenta['FALLIDA']) · MANUALES $($cuenta['MANUAL']) · NO SEGURAS $($cuenta['NO SEGURA'])"
Write-Host "partida.save real: $(if ($partidaAntes -eq $partidaDespues) { 'sin cambios' } else { 'CAMBIADA' }) · carpeta real de datos: $(if ($cambiados.Count -eq 0) { 'sin cambios' } else { 'CAMBIADA' }) · proyecto: $(if ($gitAntes -eq $gitDespues) { 'sin cambios' } else { 'CAMBIADO' }) · otros Godot: $($ajenos.Count)"
Write-Host "Resumen: $(Join-Path $dir 'resumen.md')"
if (-not $aislamientoOk) { exit 255 }
if ($cambiados.Count -gt 0 -or $partidaAntes -ne $partidaDespues) { exit 254 }
exit ([math]::Min($cuenta["FALLIDA"], 253))
