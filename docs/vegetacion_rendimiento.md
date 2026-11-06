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
