<#
  Compila en local el APK experimental de REBELUM y lo comprueba.
  La app se llama «Aethelgard Exp» y su paquete es com.aethelgard.experimental, distinto del de la estable.

  Fase 2.0: solo modo ENSAYO.
    - No publica nada, no usa GitHub, no hace push ni crea etiquetas.
    - No instala en el móvil: eso lo hace el autor.
    - No deja cambios: export_presets.cfg se restaura byte a byte después de exportar.

  Uso, desde D:\Aethelgard:
    powershell -ExecutionPolicy Bypass -File .\compilar_apk_experimental.ps1

  Salida en D:\REBELUM_compilaciones\:
    - el APK (Aethelgard_exp-AAAAMMDD-sha7.apk) y su .sha256;
    - el registro de Godot;
    - un resumen de las comprobaciones;
    - si el APK lleva recursos con licencia pendiente, un aviso NO_DISTRIBUIR.
#>
param(
    [string]$Godot  = "C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Sdk    = (Join-Path $env:LOCALAPPDATA "Android\Sdk"),
    [string]$Jdk    = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot",
    [string]$Salida = "D:\REBELUM_compilaciones"
)

$ErrorActionPreference = "Continue"
$PRESET     = "Android experimental"
$PAQUETE    = "com.aethelgard.experimental"
$PROTEGIDAS = @("refs/heads/main", "refs/heads/desarollo", "refs/tags/v0.1.0")
# Carpetas que el preset excluye: lo que cambie en ellas no entra en el APK.
$EXCLUIDAS  = @("aethelgard/para_meshy/", "aethelgard/pruebas/", "aethelgard/prototipos/",
                "aethelgard/modelos/", "aethelgard/vegetacion_prueba/")

$raiz      = $PSScriptRoot
$proyecto  = Join-Path $raiz "aethelgard"
$presets   = Join-Path $proyecto "export_presets.cfg"
$licencias = Join-Path $raiz "docs\versiones\licencias_pendientes.txt"
$resumen   = New-Object System.Collections.Generic.List[string]

function Abortar([string]$m) { Write-Host "ABORTADO: $m" -ForegroundColor Red; exit 1 }
function Titulo([string]$m)  { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Anotar([string]$m)  { Write-Host $m; $resumen.Add($m) }
function GitTexto([string[]]$a) {          # no se llama «Git»: en PowerShell taparía al propio git y se llamaría a sí misma
    $o = & git.exe -C $raiz @a 2>$null
    if ($LASTEXITCODE -ne 0) { Abortar ("git " + ($a -join " ") + " ha fallado") }
    return ($o | Out-String).Trim()
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
function CertificadoSha256([string]$ruta, [string]$apksigner) {
    $t = (& $apksigner verify --print-certs $ruta 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { return "" }
    return [regex]::Match($t, "certificate SHA-256 digest: ([0-9a-f]+)").Groups[1].Value
}

# ------------------------------------------------------------------ comprobaciones previas
Titulo "Comprobaciones previas"
if (-not (Test-Path $Godot))     { Abortar "No encuentro Godot en $Godot" }
if (-not (Test-Path $licencias)) { Abortar "Falta la lista de licencias pendientes: $licencias" }
$rama = GitTexto @("branch", "--show-current")
if ($rama -eq "" -or $rama -eq "main" -or $rama -eq "desarollo") {
    Abortar "No se compila desde '$rama': usa la rama rebelum-3d."
}
if (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Godot*" }) {
    Abortar "Hay un Godot abierto: ciérralo antes de exportar (dos Godot sobre el mismo proyecto se pisan)."
}
$antes = @{}
foreach ($r in $PROTEGIDAS) { $antes[$r] = GitTexto @("rev-parse", $r) }

$sha     = GitTexto @("rev-parse", "--short=7", "HEAD")
$cuenta  = [int](GitTexto @("rev-list", "--count", "HEAD"))
$fecha   = GitTexto @("show", "-s", "--format=%cd", "--date=format:%Y%m%d", "HEAD")
$version = "exp-$fecha-$sha"
$cambios = @((GitTexto @("status", "--porcelain", "--", "aethelgard")) -split "`r?`n" | Where-Object { $_ -ne "" })
$entran  = @($cambios | Where-Object {
    $ruta = $_.Substring(3)
    -not ($EXCLUIDAS | Where-Object { $ruta.StartsWith($_) })
})
if ($entran.Count -gt 0) {
    $version += "-local"
    Anotar "AVISO: el APK lleva cambios sin confirmar (por eso la versión acaba en -local):"
    $entran | ForEach-Object { Anotar "   $_" }
}
Anotar "Rama $rama · commit $sha · versionCode $cuenta · versionName $version"

# ------------------------------------------------------------------ versión en el preset (temporal)
$original = [System.IO.File]::ReadAllBytes($presets)
$huella   = (Get-FileHash $presets -Algorithm SHA256).Hash
$texto    = [System.Text.Encoding]::UTF8.GetString($original)
$m = [regex]::Match($texto, '\[preset\.(\d+)\]\s*name="' + [regex]::Escape($PRESET) + '"')
if (-not $m.Success) { Abortar "No existe el preset '$PRESET' en export_presets.cfg" }
$n   = $m.Groups[1].Value
$ini = $texto.IndexOf("[preset.$n.options]")
if ($ini -lt 0) { Abortar "Falta [preset.$n.options]" }
$fin = $texto.IndexOf("[preset.", $ini + 1)
if ($fin -lt 0) { $fin = $texto.Length }
$opciones = $texto.Substring($ini, $fin - $ini)
if ($opciones -notmatch [regex]::Escape("package/unique_name=`"$PAQUETE`"")) {
    Abortar "El preset '$PRESET' no usa el paquete $PAQUETE"
}
$opciones2 = [regex]::Replace($opciones, 'version/code=\d+', "version/code=$cuenta")
$opciones2 = [regex]::Replace($opciones2, 'version/name="[^"]*"', "version/name=`"$version`"")
$nuevo = $texto.Substring(0, $ini) + $opciones2 + $texto.Substring($fin)

New-Item -ItemType Directory -Force -Path $Salida | Out-Null
$base = Join-Path $Salida "Aethelgard_$version"
$r = 2
while (Test-Path "$base.apk") { $base = Join-Path $Salida ("Aethelgard_$version-r" + $r); $r++ }   # nunca sobrescribe
$apk = "$base.apk"

# ------------------------------------------------------------------ entorno de datos aislado para Godot
# Godot exporta con APPDATA, LOCALAPPDATA, TEMP y TMP apuntando a carpetas propias. Lleva una copia de los
# ajustes del editor (rutas del SDK y del JDK, y la ruta de la clave de depuración, que solo se lee) y la
# plantilla android_debug.apk. Así no escribe nada en la carpeta real de datos del juego.
$aislado = Join-Path $Salida "entorno_aislado"
$roam = Join-Path $aislado "Roaming"; $loc = Join-Path $aislado "Local"; $tmp = Join-Path $aislado "Temp"
$tpl  = Join-Path $roam "Godot\export_templates\4.7.2.stable"
New-Item -ItemType Directory -Force -Path $tpl, $loc, $tmp | Out-Null
Copy-Item (Join-Path $env:APPDATA "Godot\editor_settings-4.7.tres") (Join-Path $roam "Godot") -Force
if (-not (Test-Path (Join-Path $tpl "android_debug.apk"))) {
    Copy-Item (Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\android_debug.apk") $tpl
}
$datosReales  = Join-Path $env:APPDATA "Godot\app_userdata\Aethelgard"
$huellasAntes = Huellas $datosReales

# ------------------------------------------------------------------ exportar
Titulo "Exportando con Godot en el entorno aislado (puede tardar varios minutos)"
$codigo = -1
$entornoOriginal = @{ A = $env:APPDATA; L = $env:LOCALAPPDATA; T = $env:TEMP; M = $env:TMP }
try {
    [System.IO.File]::WriteAllText($presets, $nuevo, (New-Object System.Text.UTF8Encoding($false)))
    $env:APPDATA = $roam; $env:LOCALAPPDATA = $loc; $env:TEMP = $tmp; $env:TMP = $tmp
    $argumentos = "--headless --path `"$proyecto`" --export-debug `"$PRESET`" `"$apk`""
    $p = Start-Process -FilePath $Godot -ArgumentList $argumentos -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "$base.godot.log" -RedirectStandardError "$base.godot.err.log"
    $codigo = $p.ExitCode
} finally {
    $env:APPDATA = $entornoOriginal.A; $env:LOCALAPPDATA = $entornoOriginal.L
    $env:TEMP = $entornoOriginal.T; $env:TMP = $entornoOriginal.M
    [System.IO.File]::WriteAllBytes($presets, $original)
    if ((Get-FileHash $presets -Algorithm SHA256).Hash -eq $huella) {
        Anotar "export_presets.cfg restaurado (idéntico al original)"
    } else {
        Write-Host "AVISO: export_presets.cfg NO ha quedado igual que antes" -ForegroundColor Red
    }
}
if ($codigo -ne 0 -or -not (Test-Path $apk)) {
    Abortar "La exportación ha fallado (código $codigo). Revisa $base.godot.log y $base.godot.err.log"
}

# ------------------------------------------------------------------ comprobaciones del APK
Titulo "Comprobaciones del APK"
$ok = $true
$bt = Get-ChildItem (Join-Path $Sdk "build-tools") -Directory |
    Sort-Object { try { [version]($_.Name -replace '[^\d.]', '') } catch { [version]"0.0" } } -Descending |
    Select-Object -First 1
if ($null -eq $bt) { Abortar "No encuentro build-tools en $Sdk" }
$aapt2     = Join-Path $bt.FullName "aapt2.exe"
$apksigner = Join-Path $bt.FullName "apksigner.bat"
$env:JAVA_HOME = $Jdk
$env:Path = (Join-Path $Jdk "bin") + ";" + $env:Path

$badging  = (& $aapt2 dump badging $apk 2>&1 | Out-String)
$pm       = [regex]::Match($badging, "package: name='([^']+)' versionCode='(\d+)' versionName='([^']*)'")
$etiqueta = [regex]::Match($badging, "application-label:'([^']*)'").Groups[1].Value
if ($pm.Groups[1].Value -ne $PAQUETE) {
    Anotar "FALLO: el paquete es '$($pm.Groups[1].Value)', no $PAQUETE"; $ok = $false
} else {
    Anotar "Paquete: $PAQUETE (la app estable es com.aethelgard.juego: datos y partidas separados)"
}
if ($pm.Groups[2].Value -ne "$cuenta") { Anotar "FALLO: versionCode $($pm.Groups[2].Value), se esperaba $cuenta"; $ok = $false }
Anotar "versionCode $($pm.Groups[2].Value) · versionName $($pm.Groups[3].Value) · nombre visible «$etiqueta»"

$cert = CertificadoSha256 $apk $apksigner
if ($cert -eq "") { Anotar "FALLO: la firma del APK no se verifica"; $ok = $false }
else {
    Anotar "Firma verificada. Certificado SHA-256: $cert"
    $estable = Join-Path $raiz "Aethelgard.apk"
    if (Test-Path $estable) {
        $certEstable = CertificadoSha256 $estable $apksigner
        if ($certEstable -eq $cert) { Anotar "Mismo certificado de depuración que el APK estable del PC" }
        else { Anotar "AVISO: certificado distinto del APK estable del PC ($certEstable)" }
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($apk)
$entradas = @($zip.Entries | ForEach-Object { $_.FullName })
$zip.Dispose()
$pendientes = @()
foreach ($linea in (Get-Content -Encoding UTF8 $licencias)) {
    $t = $linea.Trim()
    if ($t -eq "" -or $t.StartsWith("#")) { continue }
    $partes = $t.Split("|")
    $patron = $partes[0].Trim().ToLower()
    $que    = if ($partes.Count -gt 1) { $partes[1].Trim() } else { $patron }
    $motivo = if ($partes.Count -gt 2) { $partes[2].Trim() } else { "" }
    $hallados = @($entradas | Where-Object { $_.ToLower().Contains($patron) })
    if ($hallados.Count -gt 0) { $pendientes += "$que · $motivo · $($hallados.Count) archivo(s), p. ej. $($hallados[0])" }
}
if ($pendientes.Count -gt 0) {
    Anotar "LICENCIAS PENDIENTES dentro del APK: SOLO PARA PRUEBAS LOCALES, NO DISTRIBUIR (tampoco por GitHub):"
    $pendientes | ForEach-Object { Anotar "   - $_" }
    $aviso = @("NO DISTRIBUIR: este APK lleva recursos con licencia sin verificar.", "") + $pendientes
    $aviso | Set-Content -Encoding UTF8 -Path "$base.NO_DISTRIBUIR.txt"
} else {
    Anotar "Ningún recurso de la lista de licencias pendientes."
}

$prohibidos = @($entradas | Where-Object { $_ -match '(?i)(partida\.save|\.save$|export_credentials|keystore|\.jks$|\.p12$|editor_settings|override\.cfg)' })
if ($prohibidos.Count -gt 0) {
    Anotar "FALLO: el APK contiene partidas, claves o ajustes que no deben ir dentro:"; $prohibidos | ForEach-Object { Anotar "   $_" }; $ok = $false
} else { Anotar "El APK no lleva partidas guardadas, claves, credenciales ni ajustes del editor" }

$huellasDespues = Huellas $datosReales
$cambiados = @()
foreach ($k in $huellasAntes.Keys)   { if (-not $huellasDespues.ContainsKey($k)) { $cambiados += "borrado: $k" } elseif ($huellasDespues[$k] -ne $huellasAntes[$k]) { $cambiados += "cambiado: $k" } }
foreach ($k in $huellasDespues.Keys) { if (-not $huellasAntes.ContainsKey($k)) { $cambiados += "nuevo: $k" } }
if ($cambiados.Count -gt 0) {
    Anotar "FALLO: la carpeta real de datos del juego ha cambiado al exportar:"; $cambiados | ForEach-Object { Anotar "   $_" }; $ok = $false
} else { Anotar "Carpeta real de datos del juego ($($huellasAntes.Count) archivos, partida.save incluida): sin cambios" }

foreach ($ref in $PROTEGIDAS) {
    if ((GitTexto @("rev-parse", $ref)) -ne $antes[$ref]) { Anotar "FALLO: $ref ha cambiado"; $ok = $false }
}
Anotar "main, desarollo y v0.1.0 sin cambios"

$h = (Get-FileHash $apk -Algorithm SHA256).Hash.ToLower()
"$h  $(Split-Path $apk -Leaf)" | Set-Content -Encoding ASCII "$apk.sha256"
Anotar "SHA-256 del APK: $h"
Anotar ("Tamaño: {0:N1} MB · {1}" -f ((Get-Item $apk).Length / 1MB), $apk)
$resumen | Set-Content -Encoding UTF8 "$base.resumen.txt"

if ($ok) { Write-Host "`nTODO CORRECTO" -ForegroundColor Green; exit 0 }
Write-Host "`nHAY FALLOS (ver arriba)" -ForegroundColor Red
exit 1
