# Vegetación premium (EmacEArt + Quaternius): rendimiento — Fase 2

Escena de prueba aislada: `prototipos/vegetacion_paquetes.tscn`. Pastos Verdes **no** cambia.
Banco A/B: botón **VEG** (o en el PC: `--script res://pruebas/prueba_banco.gd -- veg sin_vsync`).
Todos los casos usan el mismo recorrido de Kael, la misma cámara y el perfil medio; se esperan 3 s y se miden 8 s.

## PC (G513), perfil medio, sin tope de FPS — dos tandas válidas, 2026-11-06

Las dos tandas coinciden en dibujos, triángulos y memoria; los FPS del PC varían ±15 % entre tandas, porque al PC le
sobra potencia y el tiempo por fotograma lo marca casi todo la CPU. **El PC no decide: manda el Redmi.**
Una tercera tanda se descartó: casos distintos daban exactamente los mismos dibujos y triángulos (medición rota).

| Caso (20 m) | FPS | mediana | p95 | GPU | dibujos | triáng. | memoria vídeo |
|---|---|---|---|---|---|---|---|
| Vegetación original | 287–292 | 3,3 ms | 4,5–4,7 ms | 0,8 ms | 151 | 331k | 74–76 MB |
| Solo césped nuevo, material simple (sin viento) | 277–352 | 2,7–3,4 ms | 3,7–5,7 ms | 1,0 ms | 120 | 329k | 74–76 MB |
| Solo césped nuevo con viento | 280–309 | 3,1–3,4 ms | 4,6–5,0 ms | 1,5 ms | 120 | 329k | 74–76 MB |
| Solo árboles nuevos (sombra hoja a hoja) | 284–306 | 3,2–3,4 ms | 4,3–4,7 ms | 0,9 ms | 145 | 412k | 78–80 MB |
| Solo arbustos, flores y helechos | 267–341 | 2,9–3,7 ms | 3,7–5,1 ms | 0,9 ms | 105 | 299k | 79–81 MB |
| Todo, versión bonita | 221–250 | 3,9–4,5 ms | 5,7–6,0 ms | 1,9–2,0 ms | 177 | 501k | 83–85 MB |
| **Todo, versión optimizada** | 264–280 | 3,4–3,7 ms | 4,9–5,2 ms | 1,5–1,6 ms | 171 | 422k | 83–85 MB |
| Todo optimizada con tope 30 (20 m / 34 m) | 30,1 / 30,0 | 33,3 ms | 33,6 ms | — | 171 | 422k | 83–85 MB (0 % tirones) |

Lo que se ve (en el PC):
- El **sombreado de viento** del césped es lo que más GPU suma: +0,5 ms sobre el mismo césped con material simple.
- La **sombra hoja a hoja** de los árboles añade ~80 000 triángulos (se pintan otra vez para la sombra).
- Las **texturas** eran el problema de memoria: venían sin comprimir y sin mipmaps (ver abajo). Corregido.

## Redmi A7 Pro — PENDIENTE
APK de prueba enviado a `Download/Aethelgard_veg.apk` (arranca en la escena de prueba). Se mide con el botón VEG.

## Cambios de la versión optimizada y si afectan a la calidad

| Cambio | Perfil | ¿Afecta a la calidad? |
|---|---|---|
| Texturas comprimidas en la GPU (ETC2 en Android), con mipmaps; corteza y hojas sueltas a 1024 px | todos | No visible a estas distancias. Memoria de «todo»: 159 → 75–85 MB en el PC. Además, sin mipmaps la hierba centelleaba de lejos |
| Césped en rejilla con desorden en vez de azar puro (mismas matas, sin montones ni calvas) | medio/bajo | Mejora: menos suelo desnudo con el mismo número de matas |
| Detalle por distancia: cerca todas las matas; lejos (hasta +22 m) una de cada dos | medio/bajo | Lejos hay algo menos de densidad; el suelo tiene el color del césped y no se ven calvas |
| Manchas de color del césped calculadas por vértice y no por píxel | medio/bajo | Las manchas pequeñas se ven algo más suaves de cerca |
| Sombra de los árboles con un disco y un tronco sencillos, no hoja a hoja | medio/bajo | La sombra del suelo es más lisa; la copa no se sombrea a sí misma (se compensa oscureciendo un 8 % su tono) |
| Perfil **alto** | alto | Sin recortes: rejilla, detalle por distancia y texturas comprimidas sí; tinte por píxel y sombra hoja a hoja también |

## APK
- APK principal (perfil «Android»): ahora excluye `vegetacion_prueba/*`. Comprobado: solo la usan `prototipos/` y
  `pruebas/`, que ya estaban excluidas; el APK principal exportado no contiene ningún archivo de esa carpeta.
- APK de prueba («Android prueba 3D»): la incluye. Para que arranque en la prueba se cambia `run/main_scene.prueba3d`
  solo durante la exportación y se restaura después (`project.godot` queda igual).

## Licencias
- **EmacEArt Stylized Grass**: se puede usar en proyectos propios, personales y comerciales; **no** se puede vender
  ni redistribuir el material (solo, modificado o dentro de otro paquete). Por eso `aethelgard/vegetacion_prueba/emace/`
  está en `.gitignore`: no se sube a GitHub, ni siquiera al repositorio privado. El original está en
  `Descargas/EmacEArtStylizedGrass_Godot_2026-09-01_v1.3.0.zip`; para otra copia del proyecto hay que volver a
  copiar de ahí `EA_GrassWind.gdshader`, `EA_Grass_Clump.mesh`, `GRASS_DIFF.tga` y `GRASS_NMAP.tga`.
- **Quaternius Stylized Nature MegaKit**: CC0 (dominio público). Se puede subir.

## Redmi A7 Pro (Mali-G57, Android 16, driver r54p1), perfil medio salvo indicación — 2026-11-06
Medición directa: tiempo real de cada fotograma (`Time.get_ticks_usec`), 3 s de espera + 8 s de medida, Kael andando
por el mismo recorrido. GPU: el temporizador de la Mali devuelve basura («—»), así que **no hay tiempo de GPU directo**.
Las rondas 1-3 se midieron con el banco antiguo: sus **medianas y p95 son válidos**, pero su columna FPS no lo era en
casos lentos (se calculaba con el delta de Godot, recortado a ~133 ms: salía 7,6 FPS). La ronda 4 ya usa el reloj real.

| Ronda | Caso (20 m) | mediana | p95 | coste sobre «sin vegetación» |
|---|---|---|---|---|
| 2-4 | Sin vegetación | 27,5-27,6 ms | 32 ms | — |
| 1-4 | Vegetación original | 34,8-35,1 ms | 41-43 ms | +7,3 ms |
| 1 | Césped EmacE sin viento / con viento | 111 / 194 ms | 124 / 222 ms | +84 / +166 ms |
| 2 | Césped opaco ×1,6 / ×1,0 | 34,2 / 31,6 ms | 39 / 36 ms | +6,6 / +4,0 ms |
| 3 | Árboles Quaternius con recorte / mismas hojas opacas | 50,2 / 30,2 ms | 67 / 35 ms | +22,7 / +2,7 ms |
| 3 | Plantas con recorte / mismas hojas opacas | 49,2 / 32,0 ms | 59 / 37 ms | +21,6 / +4,5 ms |
| 3 | Solo arbustos / solo flores / solo helechos | 42,7 / 31,4 / 28,8 ms | 49 / 37 / 34 ms | +15,2 / +3,9 / +1,3 ms |
| 4 | Árboles con hojas de geometría opaca | 36,0 ms | 55 ms | +8,4 ms |
| 4 | Plantas con hojas de geometría opaca | 40,4 ms | 47 ms | +12,8 ms |
| 4 | Candidata con recorte («alfa») | 73,5 ms | 92 ms | +46 ms |
| 4 | **Candidata (medio)** 20 m / 34 m | 54,4 / 91,1 ms | 130 / 371 ms | +27 ms (20 m) |
| 4 | **Candidata (bajo)** 20 m / 34 m | 37,5 / 65,4 ms | 44 / 143 ms | — |
| 4 | Original 34 m | 44,4 ms | 49,5 ms | — |

Conclusiones medidas: el recorte de transparencia en la Mali es la causa principal (césped, copas, arbustos). Pasar
las hojas a geometría opaca reduce el coste de los árboles de +22,7 a +8,4 ms, pero suma triángulos (593k). Ninguna
candidata llega a 30 FPS; la más cercana es la del perfil bajo a 20 m (26 FPS). A 34 m todo empeora mucho y con picos
grandes (p95 371 ms en medio): causa **sin determinar** (más árboles en pantalla, geometría o memoria; pendiente de
medir con una herramienta de GPU antes de tocar nada).

## Diagnóstico con Arm Streamline (Mali-G57, contadores reales del controlador) — 2026-11-06
Dos capturas completas del banco VEG (330 s y 300 s), temperatura 31,6 → 33,1 °C y 31,9 → 32,7 °C, sin limitación
térmica en ningún momento. Las dos tandas coinciden caso a caso con diferencias < 5 %. Plantilla oficial «Mali-G57 -
Valhall» (106 contadores). Valores por segundo, promediados en cada caso del banco (sin el primer segundo de transición).

| Caso | GPU ocupada | Cola fragmentos | Cola geometría (tiler) | Píxeles/fotograma | Fragmentos/píxel | Primitivas/fotograma | Subpíxel | Lectura ext. |
|---|---|---|---|---|---|---|---|---|
| Sin vegetación (medio 20 m) | ~100 % | 100 % | 16 % | ~19 M | 1,1 | ~0,26 M | 10 % | 0,8 GB/s |
| Original (medio 20 m) | ~100 % | 100 % | 17 % | ~19 M | 2,2 | ~0,31 M | 8 % | 1,2 GB/s |
| Candidata con recorte («alfa») | ~100 % | 99 % | 23 % | ~18 M | **10** | ~0,49 M | 6 % | 0,7 GB/s |
| Candidata (medio 20 m) | ~100 % | 85-88 % | **73 %** | ~17 M | 2,4 | ~0,84 M | 17 % | 1,7 GB/s |
| Candidata (medio 34 m) | ~100 % | 73 % | **82-83 %** | ~19 M | 3,1 | ~1,36 M | **28-31 %** | 1,8 GB/s |
| Candidata (bajo 20 m) | ~100 % | 86 % | **87-90 %** | ~6 M | 2,6 | ~0,63 M | 26 % | 1,7 GB/s |
| Candidata (bajo 34 m) | ~100 % | 74 % | **95-98 %** | ~6,5 M | 3,1 | ~1,1 M | **40-45 %** | 2,1-2,2 GB/s |

Bloqueos de memoria externa: 2-11 % (lectura) y 2-5 % (escritura): la memoria no es el límite.
CPU: el núcleo grande (A75) pasa ~10 % del tiempo en la app: la CPU no es el límite.
«Por fotograma» = contador por segundo ÷ FPS medidos en el banco (cálculo, no medición directa).

Causas comprobadas:
1. El juego está limitado por la GPU en todos los casos (GPU ocupada ~100 %, CPU ~10 %).
2. La escena base ya está limitada por fragmentos: ~19 M píxeles procesados por fotograma para una pantalla de ~0,9 M
   (unas 20 veces). En el perfil bajo (sin sombras y al 75 %) bajan a ~6 M.
3. Hojas con recorte: 10 fragmentos por píxel (sobredibujado). Con geometría opaca bajan a 2,4-3,1.
4. La candidata con hojas de geometría pasa a estar limitada por la geometría (tiler 73-98 %), sobre todo a 34 m y en
   bajo, y el 17-45 % de sus primitivas son subpíxel: trabajo desperdiciado.
Hipótesis (sin comprobar): que la mayor parte de los ~19 M píxeles de la base sean el mapa de sombras y pases a
pantalla completa (la diferencia medio-bajo apunta a ello; confirmarlo con una captura de Frame Advisor); que los picos
a 34 m vengan de la saturación del tiler cuando entran más árboles en pantalla.

Comparaciones visuales (mismas cámaras): `docs/capturas/vegetacion_paquetes_comparacion.jpg`,
`docs/capturas/vegetacion_bonita_vs_optimizada.jpg`, `docs/capturas/vegetacion_candidata.jpg` (copias JPG; los PNG
originales se conservan solo en el PC). Capturas originales de Streamline (.apc) e informes: fuera del repositorio,
en `D:\REBELUM_diagnostico\streamline_2026-11-06\` (≈3,7 GB con las bases de análisis de Streamline; no se suben a GitHub).

## Sombras y resolución: banco DIAG + Streamline (Redmi, 2026-11-06)
Dos tandas cortas (≈3 min cada una) con enfriamiento entre ellas (31,4→32,1 °C y 31,2→31,4 °C; sin limitación
térmica). Perfil medio, cámara a 20 m, **con la vegetación candidata**: los valores absolutos no son los de la escena
sin vegetación; lo comparable son las diferencias, porque cada caso cambia una sola variable.
«Por fotograma» = contador por segundo ÷ FPS del banco (cálculo). «Píxeles» es el contador de la Mali de píxeles
escritos en todas las pasadas (incluido el mapa de sombras), no píxeles de pantalla.

| Caso (media de 2 tandas) | Mediana | Δ | Píxeles/fotograma | Primitivas/fotograma | Dibujos | Escritura memoria/fotograma |
|---|---|---|---|---|---|---|
| medio (referencia) | 55,0 ms | — | 17,8 M | 0,85 M | 193 | 79 MB |
| medio sin sombras | 48,0 ms | **−7,0 ms (−13 %)** | **6,3 M (−65 %)** | 0,68 M | 135 | 50 MB |
| medio resolución 75 % (en vez de 90 %) | 47,7 ms | **−7,3 ms (−13 %)** | 17,4 M | 0,84 M | 193 | 72 MB |
| medio con menos hierba y flores | 50,8 ms | −4,2 ms | — | — | 192 | — |
| medio sin relieve | 54,0 ms | −1,0 ms (ruido) | — | — | 194 | — |
| medio sin faroles (control: no cambia nada) | 55,1 ms | ±0 | — | — | 193 | — |

Comprobado: el mapa de sombras es ~65 % de los píxeles escritos por fotograma (era la hipótesis pendiente), además
del 30 % de las llamadas de dibujo y de ~1/3 de las escrituras a memoria, y cuesta ~7 ms. Bajar la resolución apenas
cambia los píxeles totales (los domina la sombra) pero ahorra lo mismo: la pasada principal es cara por píxel.
El perfil alto no es medible en el Redmi (~570 ms por fotograma: hierba EmacE y hojas recortadas); el caso
«alto-sombra2k» no dio un resultado repetible (471 y 564 ms) y no se usa.
Sin medir todavía (no hay casos en el banco): terreno, agua, cielo y pasadas a pantalla completa por separado.

## Experimento de sombras A/B/C (Redmi, 2026-11-06, ronda 5)
Prototipo `vegetacion_paquetes` con la vegetación candidata; opción `sombra_modo` (sin ella, todo como antes).
A: sombra dinámica actual. B (diagnóstico): solo Kael y la fauna dan sombra dinámica. C: sombra precalculada al
cargar (mapa en planta 1024 px, 10,7 cm/px) para árboles, rocas, puente, postes, estatua y contacto de arbustos,
leída por terreno, losas, césped, plantas bajas y Kael. C+: C con la sombra de los móviles en 1 tramo, 1024 px, 40 m.
Dos tandas completas (28,5→30,2 °C y 29,1→30,1 °C), medianas medidas; sin Streamline en esta ronda.

| Caso | Mediana 20 m (t1 / t2) | p95 20 m | Mediana 34 m (t1 / t2) | Dibujos 20 m | Triángulos 20 m | Memoria |
|---|---|---|---|---|---|---|
| A dinámica (medio) | 57,1 / 56,3 ms | 159 / 155 ms | 95,1 / 99,8 ms | 192 | 0,86 M | 85 MB |
| B solo móviles | 51,4 / 51,8 ms | 60 / 59 ms | 92,2 / 93,4 ms | 160 | 0,73 M | 85 MB |
| C horneada | 53,0 / 52,9 ms | 59 / 60 ms | 104,1 / 95,0 ms | 162 | 0,76 M | 89 MB |
| C+ ajustada | 51,5 / 51,4 ms | 70 / 69 ms | 90,7 / 88,2 ms | 168 | 0,76 M | 89 MB |
| Bajo actual (sin sombras) | 38,0 / 38,0 ms | 45 / 43 ms | — | 134 | 0,65 M | 79 MB |
| Bajo C | 39,7 / 39,4 ms | 44 / 45 ms | — | 136 | 0,67 M | 83 MB |
| Bajo C+ (con sombra de Kael) | 40,4 / 40,2 ms | 48 / 47 ms | — | 166 | 0,71 M | 83 MB |

Generación de la sombra horneada: 2,07 s por carga en el Redmi (0,5 s en PC) + 45 ms para aplicarla.
Conclusiones medidas: a 20 m, quitar la sombra dinámica de lo estático ahorra ~5 ms de mediana (−9 %) y, sobre todo,
el p95 baja de ~157 a ~60 ms (los picos venían del mapa de sombras). Leer el mapa horneado cuesta ~1,5 ms. A 34 m la
escena está limitada por la geometría (Streamline, ronda 4) y el ahorro es pequeño y con ruido. En bajo, ganar sombras
cuesta +1,5 ms (C) o +2,3 ms (C+). Ninguna variante llega a 33 ms en medio: falta el LOD de árboles y arbustos.
Comparación visual: `docs/capturas/sombras_experimento.jpg`.

## Experimento LOD (Redmi, 2026-11-06, ronda 6)
Prototipo `vegetacion_paquetes`, opción `veg_lod` (sin ella, todo como antes; mallas originales intactas).
Árboles: LOD0 la malla de siempre (23-35 k triángulos de copa); LOD1 desde 28 m (la mitad de las hojas de fuera, algo más
grandes, con un núcleo de racimos: 10-12 k); LOD2 desde 50 m (22 racimos opacos + piel de hojas grandes: ~3 k).
Arbustos: LOD1 desde 24 m (48-53 %). Césped: desde 24 m, mismas matas con 6 hojas en vez de 11. Mallas generadas fuera del
juego (`pruebas/herramientas/hojas_a_geometria.gd`); impostores con `pruebas/herramientas/impostores.gd`.
Dos tandas (28,0→30,2 °C y 29,0→29,9 °C). Medianas medidas; en la tanda 1, «B» y «C» a 34 m salieron anómalas (88 y
100 ms, p95 ~500 ms) y la primera carga tardó 9,6 s: probablemente la compilación de los sombreados nuevos la primera vez
que aparecen (sin confirmar). Los demás casos coinciden entre tandas.

| Caso (medio) | Mediana 20 m (t1 / t2) | p95 20 m | Mediana 34 m (t1 / t2) | p95 34 m (t2) | Triáng. 20 / 34 m | Memoria |
|---|---|---|---|---|---|---|
| A actual | 54,8 / 55,4 ms | 103 / 152 | 97,9 / 92,2 ms | 281 | 0,87 / 1,25 M | 85 MB |
| B LOD | 51,6 / 51,7 ms | 65 / 71 | (88,3) / 68,9 ms | 116 | 0,70 / 0,76 M | 90 MB |
| C LOD + sombras C+ | 48,2 / 46,9 ms | 124 / 84 | (100,1) / 70,1 ms | 181 | 0,58 / 0,69 M | 94 MB |
| B con impostor (recorte) | — | — | 72,9 / 72,2 ms | 157 | — / 0,76 M | 91 MB |
| C con fundido de Godot | — | — | 71,4 / 70,3 ms | 214 | — / 0,77 M | 94 MB |
| Bajo LOD + C+ | 36,1 / 36,0 ms | 91 / 45 | 51,5 / 50,8 ms | 73 | 0,55 / 0,65 M | 88 MB |
| C con tope 30 | 58,3 / 60,3 ms | — | 69,1 / 68,6 ms | — | — | 94 MB |

Carga de la escena en el Redmi: actual 2,55 s; con LOD 3,1 s; con LOD y sombra horneada ~5,0 s (2,1 s de calcularla).
Conclusiones medidas: a 34 m el LOD baja la mediana de ~95 a ~70 ms (−26 %) y los triángulos de 1,25 a 0,7 M; a 20 m,
LOD + C+ baja de ~55 a ~47,5 ms (−14 %). El impostor no es más rápido que los racimos (72 frente a 69-70 ms) y se ve peor;
el fundido de Godot no cambia la mediana y da más picos: se descartan por ahora. Bajo LOD + C+ a 20 m: 36 ms (27,7 FPS).
El medio sigue lejos de 33 ms: falta saber qué consume ahora (captura de Streamline de «C LOD + C+»).
Comparación visual: `docs/capturas/lod_experimento.jpg`.

## Streamline del experimento LOD (Redmi, 2026-11-06)
Misma APK de la ronda 6. Una captura de 620 s: el banco completo una vez para calentar (compilar sombreados; no se usa)
y otra vez medido. 27,5 → 29,4 °C, sin limitación térmica. Contadores reales de la Mali-G57; «por fotograma» = contador
por segundo ÷ FPS del banco medido (cálculo). La utilización (%) NO se convierte en milisegundos.

| Caso (banco medido) | Mediana / p95 | Píxeles escritos/fot. | Primitivas/fot. | Subpíxel | Fragm./píxel | Núcleo de sombreado ocupado | Cola fragmentos | Cola vértices+tiler | ALU | Ciclos/hilo vértice | Cobertura parcial |
|---|---|---|---|---|---|---|---|---|---|---|---|
| A actual 20 m | 56,0 / 98,9 ms | 18,2 M | 0,87 M | 20 % | 2,4 | 99,0 % | 85 % | 76 % | 53 % | 30 | 44 % |
| B LOD 20 m | 51,6 / 81,2 ms | 18,7 M | 0,73 M | 14 % | 2,2 | 98,4 % | 88 % | 67 % | 53 % | 19 | 44 % |
| C LOD + C+ 20 m | 46,4 / 82,8 ms | 8,8 M | 0,61 M | 19 % | 2,5 | 98,8 % | 90 % | 73 % | 60 % | 18 | 50 % |
| A actual 34 m | 91,4 / 388 ms | 18,2 M | 1,28 M | 29 % | 2,7 | 99,7 % | 69 % | 84 % | 45 % | 157 | 46 % |
| B LOD 34 m | 74,0 / 219 ms | 19,7 M | 0,91 M | 22 % | 2,8 | 97,5 % | 84 % | 72 % | 50 % | 25 | 51 % |
| C LOD + C+ 34 m | 66,9 / 206 ms | 8,7 M | 0,76 M | 26 % | 2,5 | 97,2 % | 79 % | 78 % | 45 % | 35 | 50 % |
| Bajo LOD + C+ 20 m | 36,6 / 44,9 ms | 8,0 M | 0,52 M | 25 % | 2,7 | 99,1 % | 91 % | 81 % | 61 % | 20 | 50 % |

Medido: la GPU está ocupada > 99,5 % de los milisegundos en B y C (los picos son fotogramas con más trabajo de GPU, no
esperas de CPU ni tirones de carga). C reduce a la mitad los píxeles escritos (fuera el mapa de sombras de lo estático),
pero el tiempo baja solo ~10 %: el límite es el núcleo de sombreado (~98-99 % ocupado), repartido entre vértices (cola de
vértices 67-84 %) y fragmentos (79-91 %), con un 44-51 % de fragmentos en cuadros parcialmente cubiertos (hojas y briznas
finas) y un 14-29 % de primitivas subpíxel. Memoria externa: sin bloqueos relevantes.
Picos de C frente a B: el p95 es igual (82,8 frente a 81,2 ms); C tiene más «picos» porque su mediana es menor y el umbral
(1,5 × mediana) también: es la variación del recorrido (vistas con más vegetación), no un tirón propio de C.
Hecho comprobado en las mallas: las hojas hexagonales y las matas de césped se generan SIN índices (cada triángulo con sus
3 vértices: 12 por hoja en vez de 6, 9 por brizna en vez de 5), así que el sombreado de vértices se ejecuta ~2 veces más
de lo necesario.
Hipótesis (sin medir): indexar esas mallas reduciría mucho la cola de vértices sin cambiar la imagen.
Capturas: D:\REBELUM_diagnostico\streamline_lod_2026-11-06\.

## Mallas indexadas (`veg_indexada`, Redmi, 2026-11-06, ronda 7)
Copias `_idx` de las mallas de hojas, racimos y matas de césped (las originales y el LOD no cambian): solo se comparten
vértices con TODOS sus atributos idénticos (SurfaceTool.index()). Mismos triángulos en todas (lo comprueba la herramienta).
Vértices: árboles LOD0 54-55 %, LOD1 55 %, LOD2 57-58 %; arbustos 49-53 % (racimos 34-38 %); mata de césped 99 → 55
(lejana 54 → 30). Imagen (PC, fotogramas de duración fija; control C frente a C = 0): diferencia máxima 1/255, media
0,000, en 6 vistas con el viento en fases distintas.
Redmi: un banco de calentamiento y otro medido (con Streamline), orden alterno C / indexada / indexada / C; 27,3 → 28,3 °C.
«FPS» = fotogramas / tiempo real (equivale al tiempo medio de fotograma); mediana y p95, del tiempo de cada fotograma.

| Caso | FPS (calent. / medido) | Mediana | p95 | Memoria vídeo |
|---|---|---|---|---|
| C 20 m (2 + 2 casos) | 17,4 · 18,0 / 19,7 · 18,8 → media 18,5 | 46-59 ms (media 50,5) | 90-128 ms (media 110) | 94 MB |
| C indexada 20 m | 19,6 · 21,6 / 22,3 · 21,8 → media 21,3 (+15 %) | 47-51 ms (media 49,2) | 81-90 ms (media 84) | 89 MB |
| C 34 m | 11,6 · 13,4 / 13,0 · 12,3 → media 12,6 | 64-75 ms (media 68,8) | 134-218 ms (media 181) | 94 MB |
| C indexada 34 m | 15,4 · 15,8 / 16,1 · 15,5 → media 15,7 (+25 %) | 72-78 ms (media 74,9) | 105-113 ms (media 110) | 89 MB |
| Bajo C 20 m | 27,3 / 26,7 | 35,5 / 36,0 ms | 46 / 53 ms | 88 MB |
| Bajo C indexada 20 m | 29,5 / 29,7 (+10 %) | 37,4 / 34,9 ms | 58 / 55 ms | 83 MB |

Contadores (banco medido, por milisegundo; la utilización no se convierte en milisegundos):
| Caso | Cola de vértices activa | Utilización vértices | Utilización fragmentos | Núcleo de sombreado | Grupos de vértices/fot.* |
|---|---|---|---|---|---|
| C 20 m | 595-664 k ciclos | 71-79 % | 84 % | 98 % | ~115 k |
| C indexada 20 m | 402-406 k ciclos | 48-49 % | 89-90 % | 98 % | ~75 k |
| C 34 m | 660-691 k | 78-82 % | 81-84 % | 98 % | — |
| C indexada 34 m | 441-464 k | 53-55 % | 88-89 % | 98 % | — |
| Bajo C / indexada 20 m | 698 / 486 k | 83 / 58 % | 85 / 88 % | 98 % | — |
*cálculo: grupos por ms × 1000 ÷ FPS.

Medido: la indexación quita ~1/3 del trabajo de vértices sin cambiar la imagen; sube el FPS medio (+15 % a 20 m, +25 % a
34 m, +10 % en bajo), baja el p95 (−24 % y −39 %) y ahorra 5 MB. La mediana no mejora: el núcleo de sombreado sigue al
98 % y ahora lo limitan los fragmentos (89-90 %); la indexación solo acelera los fotogramas con más geometría. Carga sin
cambios (~5 s con sombra horneada). Capturas: D:\REBELUM_diagnostico\streamline_indexada_2026-11-06\.

## Coste de los sombreados (Mali Offline Compiler, 2026-11-07)
Método: GLSL FINAL que genera Godot 4.7.2 (plantilla + nuestro código), capturado con RenderDoc for Arm en el PC
(OpenGL 3.3, configuración C indexada, perfil medio, 20 m), convertido a OpenGL ES 3.0 (cambio de cabecera; la plantilla
ya trae la rama ES) y compilado con Mali Offline Compiler 2026.5 para Mali-G57 (controlador r51p0; el Redmi usa r54p1).
Ciclos por píxel/vértice del camino más largo: A = aritmética, LS = carga/almacenamiento, V = interpolación, T = textura.

| Sombreado | Registros (ocupación) | A | V | T | Limita | 16 bits |
|---|---|---|---|---|---|---|
| Terreno (material estándar, triplanar + relieve + sombra horneada) | 64 (50 %) | 11,65 | 3,38 | 6,00 | A | 0 % |
| Losas | 64 (50 %) | 12,19 | 3,88 | 7,00 | A | 0 % |
| Rocas / puente | 64 (50 %) | 11,12 | 2,75 | 4,75 | A | 0 % |
| Copas de los árboles (follaje) | 64 (50 %) | 10,02 | 2,12 | 2,25 | A | 0 % |
| Arbustos y flores (follaje) | 64 (50 %) | 10,02 | 2,12 | 2,25 | A | 0 % |
| Agua | 64 (50 %) | 9,94 | 2,38 | 2,25 | A | 0 % |
| Césped | 31 (100 %) | 8,75 | 2,00 | 2,00 | A | 0 % |
| Tonemapping + ajustes de color (pantalla completa) | 26 (100 %) | 2,81 | 0,25 | 0,25 | A | 0 % |
| Copia final (pantalla completa) | 4 (100 %) | 0 | 0,25 | 0,25 | V, T | — |
| Vértices del césped | 64 (50 %) | 6,40 | LS 7,00 | — | LS | 0 % |
| Vértices de arbustos/flores | 32 (100 %) | 5,75 | LS 7,00 | — | LS | 0 % |
| Vértices de las copas | 21 (100 %) | 2,06 | LS 4,00 | — | LS | 0 % |

Hechos comprobados:
- Godot 4.7 Compatibility pinta cada objeto en UNA pasada (el sol con sombra va dentro, «USE_ADDITIVE_LIGHTING»).
- Todo lo iluminado lee el reflejo del cielo («USE_RADIANCE_MAP», bloque condicionado por un valor en tiempo de
  ejecución) y la sombra del sol con filtro de 5 lecturas («SHADOW_MODE_PCF_5»), aunque con C+ solo Kael y la fauna dan
  sombra dinámica.
- Nada se calcula en 16 bits (la plantilla de Godot usa precisión alta en todo): no se puede cambiar sin tocar el motor.
- En el PC Godot hace una pasada previa de profundidad; en la Mali la desactiva por defecto (fabricantes con renderizado
  por teselas), así que en el Redmi hay sobredibujado (2,2-3,2 fragmentos por píxel, Streamline) y el terreno, el
  sombreado más caro y el que más pantalla cubre, puede pintarse bajo el césped.

Variantes (mismo código, cambiando solo los interruptores que pone Godot), ciclos A del camino más largo:
| | Terreno | Copa | Césped | Rocas | Losas | Agua |
|---|---|---|---|---|---|---|
| Actual | 11,65 | 10,02 | 8,75 | 11,12 | 12,19 | 9,94 |
| Sin reflejo del cielo | 8,60 | 7,88 | 7,62 | 8,06 | 9,12 | 7,75 |
| Sombra de 1 lectura | 11,12 (T 5,0) | 9,50 (T 1,25) | 8,62 (T 1,0) | 10,60 | 11,65 | 9,40 |
| Iluminación Lambert | 11,19 | 9,60 | 8,50 | 10,65 | 11,73 | 9,50 |
| Sin especular | 10,44 | 9,23 | 8,75 | 9,90 | 10,98 | 8,69 |
| Todo junto | 7,00 (55 reg.) | 7,12 (31 reg., 100 %) | 7,12 | 7,00 | 7,00 | 7,12 (31 reg.) |
| Sin contraluz (no se propone) | 11,65 | 9,77 | 8,75 | — | — | — |

Ajustes reales comprobados (nueva captura con RenderDoc):
- `RenderingServer.directional_soft_shadow_filter_set_quality(SHADOW_QUALITY_HARD)` quita el filtro de 5 lecturas de
  todos los sombreados (14 → 0 programas).
- `Environment.reflected_light_source = REFLECTION_SOURCE_DISABLED` NO quita el código del reflejo, pero desactiva su
  condición en tiempo de ejecución: la Mali se salta ese bloque (ahorro de ciclos), aunque los registros reservados
  siguen siendo 64 (la ocupación no mejora).
Impacto visual (PC, capturas deterministas; control = 0): sin reflejo, cambio uniforme de ~3/255 de media (brillo −0,7 %;
solo 0,03-0,15 % de píxeles cambian más de 8 niveles, en agua y brillos); sombra de 1 lectura, solo los bordes de la
sombra de Kael y la fauna (media 0,01-0,09/255). Comparación: `docs/capturas/shaders_ajustes.jpg`.
Estimación (no medida en el móvil): ponderando por los fragmentos visibles del PC, el terreno sería ~39 % del trabajo de
fragmentos de la escena, el tonemapping ~23 %, las copas ~10 %, el césped ~6 %. En el Redmi, sin pasada previa de
profundidad, el reparto cambia (más sobredibujado). Archivos: D:\REBELUM_diagnostico\malioc_2026-11-07\.
