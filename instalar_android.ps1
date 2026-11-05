# Instala lo necesario para exportar Aethelgard a Android desde Godot 4.7:
#   1. Java 17 (Temurin) con winget
#   2. Android SDK (solo herramientas de linea de comandos, sin Android Studio):
#      platform-tools, build-tools 35 y la plataforma android-35
#   3. Pone las rutas de Java y del SDK en la configuracion del editor de Godot
# Cierra Godot antes de ejecutarlo (si no, Godot puede sobrescribir la configuracion al cerrarse).
# Uso:  powershell -ExecutionPolicy Bypass -File D:\Aethelgard\instalar_android.ps1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # sin barra de progreso: Invoke-WebRequest descarga mucho mas rapido
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$urlHerramientas = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

Write-Host "== 1/3 Java 17 ==" -ForegroundColor Cyan
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue | Where-Object Name -like "jdk-17*" | Select-Object -First 1
if (-not $jdk) {
    winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
    $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory | Where-Object Name -like "jdk-17*" | Select-Object -First 1
}
if (-not $jdk) { throw "No se encontro Java 17 despues de instalarlo." }
$env:JAVA_HOME = $jdk.FullName
$env:Path = "$($jdk.FullName)\bin;$env:Path"
Write-Host "Java 17 en $($jdk.FullName)"

Write-Host "== 2/3 Android SDK ==" -ForegroundColor Cyan
$sdkman = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkman)) {
    New-Item -ItemType Directory -Force "$sdk\cmdline-tools" | Out-Null
    $zip = "$env:TEMP\android_cmdline_tools.zip"
    $tmp = "$env:TEMP\android_cmdline_tools"
    Write-Host "Descargando herramientas de Android..."
    Invoke-WebRequest $urlHerramientas -OutFile $zip -UseBasicParsing
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip -DestinationPath $tmp
    Move-Item "$tmp\cmdline-tools" "$sdk\cmdline-tools\latest"
    Remove-Item $zip -Force
}
Write-Host "Aceptando licencias..."
("y`n" * 30) | & $sdkman --sdk_root="$sdk" --licenses | Out-Null
Write-Host "Instalando platform-tools, build-tools y plataforma (tarda unos minutos)..."
& $sdkman --sdk_root="$sdk" "platform-tools" "build-tools;35.0.0" "platforms;android-35"
if (-not (Test-Path "$sdk\build-tools") -or -not (Test-Path "$sdk\platform-tools")) { throw "El SDK no se instalo bien." }
Write-Host "SDK en $sdk"

Write-Host "== 3/3 Configurar Godot ==" -ForegroundColor Cyan
$ajustes = Get-ChildItem "$env:APPDATA\Godot" -Filter "editor_settings-4*.tres" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ajustes) {
    $javaGodot = $jdk.FullName -replace '\\', '/'
    $sdkGodot = $sdk -replace '\\', '/'
    $texto = Get-Content $ajustes.FullName -Raw
    $texto = $texto -replace 'export/android/java_sdk_path = "[^"]*"', "export/android/java_sdk_path = `"$javaGodot`""
    $texto = $texto -replace 'export/android/android_sdk_path = "[^"]*"', "export/android/android_sdk_path = `"$sdkGodot`""
    Set-Content $ajustes.FullName $texto -NoNewline -Encoding UTF8
    Write-Host "Rutas puestas en $($ajustes.Name)"
} else {
    Write-Host "No encontre la configuracion de Godot: pon las rutas a mano en Editor > Configuracion del Editor > Exportar > Android"
    Write-Host "  Java SDK Path:    $($jdk.FullName)"
    Write-Host "  Android SDK Path: $sdk"
}

Write-Host ""
Write-Host "Listo. Abre Godot y ve a Proyecto > Exportar > Android > Exportar proyecto." -ForegroundColor Green
