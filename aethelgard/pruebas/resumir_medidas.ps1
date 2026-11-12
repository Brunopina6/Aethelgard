# Tabla en Markdown de las medidas de medir_escenas.gd (una o dos carpetas: antes y después).
#   .\resumir_medidas.ps1 -Carpeta <antes> [-Despues <despues>] [-Etiqueta x]
param([Parameter(Mandatory)][string]$Carpeta, [string]$Despues = "", [string]$Etiqueta = "")

function Leer($dir) {
	$t = @{}
	Get-ChildItem $dir -Filter "medicion_*.json" | ForEach-Object {
		$j = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
		if ($Etiqueta -and $j.etiqueta -ne "_$Etiqueta") { return }
		if (-not $Etiqueta -and $j.etiqueta) { return }
		$t["$($j.escena)|$($j.perfil)"] = $j
	}
	return $t
}

function Fila($j) {
	$c = $j.cargas_ms.PSObject.Properties
	$f = $j.fases.PSObject.Properties
	$prim = ($c | Where-Object { $_.Name -match "^(carga|carga_combate)#1$" } | Select-Object -Last 1).Value
	$rep = @($c | Where-Object { $_.Name -match "^(carga|carga_combate)#[2-9]$" } | ForEach-Object { $_.Value })
	$repm = if ($rep.Count) { ($rep | Measure-Object -Average).Average } else { $null }
	$vuelta = @($c | Where-Object { $_.Name -match "^carga_vuelta#" } | ForEach-Object { $_.Value })
	$act = if ($j.escena -like "combate*") { "combate" } else { "activo" }
	$rep_f = if ($j.escena -eq "titulo") { "reposo" } elseif ($j.escena -like "combate*") { "tras_volver" } else { "reposo" }
	function Junta($nombre) {      # todos los ciclos de una fase juntos (medianas y percentiles de cada ciclo, la peor)
		$x = @($f | Where-Object { $_.Name -like "$nombre#*" } | ForEach-Object { $_.Value })
		if (-not $x.Count) { return $null }
		[pscustomobject]@{ med = ($x | ForEach-Object { $_.fotograma_ms.mediana } | Measure-Object -Average).Average
			p95 = ($x | ForEach-Object { $_.fotograma_ms.p95 } | Measure-Object -Maximum).Maximum
			p99 = ($x | ForEach-Object { $_.fotograma_ms.p99 } | Measure-Object -Maximum).Maximum
			tir = ($x | ForEach-Object { $_.fotograma_ms.tirones_50ms } | Measure-Object -Sum).Sum
			dib = ($x | ForEach-Object { $_.dibujos.mediana } | Measure-Object -Average).Average
			pri = ($x | ForEach-Object { $_.primitivas.mediana } | Measure-Object -Average).Average }
	}
	$r = Junta $rep_f; $a = Junta $act
	# memoria: la de la fase activa del primer y del último ciclo (estática y de vídeo) y lo que queda fuera
	$mem = @($f | Where-Object { $_.Name -like "$act#*" } | Sort-Object Name | ForEach-Object { $_.Value.memoria })
	$fuera = @($f | Where-Object { $_.Name -like "fuera#*" -or $_.Name -like "tras_volver#*" } | Sort-Object Name | ForEach-Object { $_.Value.memoria })
	[pscustomobject]@{ prim = $prim; rep = $repm; vuelta = if ($vuelta.Count) { ($vuelta | Measure-Object -Average).Average } else { $null }
		r = $r; a = $a; est = if ($mem.Count) { $mem[-1].estatica_mb } else { $null }; vid = if ($mem.Count) { $mem[-1].video_mb } else { $null }
		fuera = ($fuera | ForEach-Object { "{0:N0}" -f $_.estatica_mb }) -join " → "
		huer = ($fuera | ForEach-Object { $_.huerfanos }) -join " → " }
}

function N($x, $d = 1) { if ($null -eq $x) { "—" } else { ("{0:N$d}" -f [double]$x) } }

$A = Leer $Carpeta
$D = if ($Despues) { Leer $Despues } else { @{} }
"| Escena | Perfil | 1.ª carga (ms) | Repetida (ms) | Vuelta (ms) | Reposo med / p95 / p99 (ms) | Activo med / p95 / p99 (ms) | Tirones > 50 ms | Dibujos | Primitivas | Memoria estática / vídeo (MB) | Estática fuera por ciclo (MB) | Huérfanos fuera |"
"|---|---|---|---|---|---|---|---|---|---|---|---|---|"
foreach ($k in ($A.Keys | Sort-Object)) {
	foreach ($cual in @(@("", $A), @(" (después)", $D))) {
		if (-not $cual[1].ContainsKey($k)) { continue }
		$x = Fila $cual[1][$k]
		$e, $p = $k -split "\|"
		$rr = if ($x.r) { "$(N $x.r.med 2) / $(N $x.r.p95 2) / $(N $x.r.p99 2)" } else { "—" }
		$aa = if ($x.a) { "$(N $x.a.med 2) / $(N $x.a.p95 2) / $(N $x.a.p99 2)" } else { "—" }
		$tir = ([int]$(if ($x.r) { $x.r.tir } else { 0 }) + [int]$(if ($x.a) { $x.a.tir } else { 0 }))
		$dib = if ($x.a) { N $x.a.dib 0 } elseif ($x.r) { N $x.r.dib 0 } else { "—" }
		$pri = if ($x.a) { N $x.a.pri 0 } elseif ($x.r) { N $x.r.pri 0 } else { "—" }
		"| $e$($cual[0]) | $p | $(N $x.prim 0) | $(N $x.rep 0) | $(N $x.vuelta 0) | $rr | $aa | $tir | $dib | $pri | $(N $x.est 0) / $(N $x.vid 0) | $($x.fuera) | $($x.huer) |"
	}
}
