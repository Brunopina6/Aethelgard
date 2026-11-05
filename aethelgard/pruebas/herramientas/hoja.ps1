# Hoja de contactos: junta varios fotogramas en una sola imagen.
param([string]$dir, [string]$prefijo, [int]$desde, [int]$hasta, [int]$paso, [string]$salida)
Add-Type -AssemblyName System.Drawing
$lista = @()
for ($i = $desde; $i -le $hasta; $i += $paso) { $f = Join-Path $dir ("{0}{1:D8}.png" -f $prefijo, $i); if (Test-Path $f) { $lista += $f } }
$cols = 3; $w = 640; $h = 360
$rows = [math]::Ceiling($lista.Count / $cols)
$hoja = New-Object Drawing.Bitmap ($cols * $w), ($rows * $h)
$gr = [Drawing.Graphics]::FromImage($hoja)
for ($k = 0; $k -lt $lista.Count; $k++) {
  $im = [Drawing.Image]::FromFile($lista[$k])
  $gr.DrawImage($im, ($k % $cols) * $w, [math]::Floor($k / $cols) * $h, $w, $h)
  $gr.DrawString([IO.Path]::GetFileNameWithoutExtension($lista[$k]), (New-Object Drawing.Font 'Arial', 14), [Drawing.Brushes]::Yellow, ($k % $cols) * $w + 5, [math]::Floor($k / $cols) * $h + 5)
  $im.Dispose()
}
$hoja.Save($salida)
