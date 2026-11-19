# Sonido de las regiones (AM-9) · Sunken City con olas y gaviotas, la Arboleda con campanillas · 19/11/2026

Encargo AM-9: los huecos de sonido por región que quedaban tras la ciudad y el barrio (`f421017`, `029c7f6`). Este
documento cubre **Sunken City** (antes, en el puerto solo sonaba el viento: `musica.gd` decía «no hay olas ni gaviotas en
audio/: pendiente») y la **Arboleda Mítica** (el plan, `docs/v12/SUNKEN_ARBOLEDA_PLAN.md` §3.2, pide «viento y
campanillas»). Las charcas y la lava de las zonas 2D **no** se han hecho (§6).

**Nadie lo ha oído.** Todo lo que sigue está medido (forma de onda, niveles por el bus Master) o comprobado con pruebas
mudas; la escucha final es del usuario, con las muestras de
`D:\REBELUM_diagnostico\sonido_muestras\2026-11-19_regiones\indice.md`.

## 1. Qué suena ahora

| Lugar | Antes | Ahora |
|---|---|---|
| Sunken City 3D (`zonas3d/sunken_3d.tscn`) | contexto «puerto»: `viento.wav` a −15 dB | contexto «puerto»: **`audio/ambiente/puerto.ogg`** (olas lejanas y agua que lame la madera, bucle de 36 s) a −12 dB, y **gaviotas** de vez en cuando (cada 12-26 s, `DETALLES["puerto"]`) |
| Sunken City 2D (`zona.tscn`, lugar 5 de `mapa.gd`) | contexto «ciudad»: la pradera y pájaros | contexto «puerto», como la 3D |
| Arboleda Mítica (`isla.tscn`) y su tramo de la Hospedería (`zonas3d/arboleda_tramo/`) | contexto «viento»: `viento.wav` a −10 dB y ráfagas de hierba | contexto **«arboleda»**: el mismo viento a −10 dB y **campanillas de viento** (2 de cada 3 detalles; cada 9-20 s) o una ráfaga |
| Dentro de la Hospedería del Peregrino | lo mismo que fuera | contexto **«arboleda_interior»**: el mismo viento, **sin reiniciarse**, a −24 dB, y **ningún detalle** |

- Las Cumbres de Ciclópea y los lugares 2D de nieve siguen con «viento» (sin campanillas). El mapa, sin cambios.
- La música aprobada no cambia: ninguna de estas pistas es música ni toca la capa «musica».
- Los efectos de la escena de Sunken (el agua junto al casco, el puente, las cuerdas y el mercado: `sunken_3d.gd`
  `_sonido_3d`) siguen igual. Sunken no tiene interiores separados (el Archivo y la Quilla son sitios abiertos de la
  misma escena), así que las olas y las gaviotas suenan en toda ella.

## 2. Archivos de sonido nuevos: origen y licencia

Todos son **derivados propios** de los paquetes GDC de **Sonniss** de la biblioteca del usuario (`D:\qtorrent\sound
effect`, solo lectura; los originales no se han tocado). **Licencia Sonniss «#GameAudioGDC»**: uso ilimitado en proyectos
personales y comerciales, sin atribución, sincronizado con juegos; editarlos como parte de la producción; no venderlos
tal cual ni atribuirse su autoría. Leída hoy en `Sonniss.com - GDC 2019 - Game Audio Bundle/License.pdf`; la de 2016
(`Licensing.pdf`), del historial (leída el 08/11 y el 09/11, `docs/audio/inventario_sonidos.md`). Nada de Suno.

| Derivado | Original (paquete / carpeta / archivo) | Tramo y tratamiento | Dur. · pico / RMS (dBFS) | SHA-256 del original |
|---|---|---|---|---|
| `audio/ambiente/puerto.ogg` | GDC 2019 / The Sound Pack Tree - Sonic Seaside/209300 - Distant Ocean Waves - Loop.wav | 2,0-42,0 s (bucle de 36 s, cruce de potencia constante de 4 s), paso alto 30 Hz | 36,00 s estéreo · −7,5 / −25,1 (en el OGG, q4) | `5b9f602152aa1feb270e4f199160c467778eea3dbbc91b967036026fe38e35d0` |
| | GDC 2016 / TS Sound - Savannah, GA Ambiences/AMB_EXT_Fort_McAllister_Water_Lapping_Boat_Ramp.wav | 20,0-60,0 s (bucle de 36 s, cruce 4 s), paso alto 120 Hz, −2 dB | | `25a051004fb9bc88264f21465048008d9edce39e9ba1ad4a905368f14eaa21b2` |
| `audio/efectos/ambiente/gaviota_1.wav` | GDC 2019 / Borys Peter - Rural zone/countryside quiet forest bird gull call.wav | 233,9-236,0 s (los dos gritos de la gaviota; el resto del archivo son pájaros del bosque, que no se usan), banda 400 Hz-6 kHz, fundidos 0,05/0,25 s | 2,10 s mono · −3,0 / −17,6 | `5eea1ebbe6017800bfd6abac4e3e4af718298511cc682a87fd246d2fa68e5f7a` |
| `audio/efectos/ambiente/gaviota_2.wav` | GDC 2019 / The Sound Pack Tree - Sonic Seaside/205300 - Crazy Harbor Seagulls - Loop.wav | 0,0-3,2 s, banda 450 Hz-7 kHz (sin el retumbo grave del puerto), fundidos 0,3/0,6 s | 3,20 s · −3,0 / −19,2 | `cd7c4557e5307fac21938ce2fbf421ac0be9a3471a60dd469fdf7be5c6552f77` |
| `audio/efectos/ambiente/gaviota_3.wav` | ídem | 19,5-22,4 s, igual tratamiento | 2,90 s · −3,0 / −17,9 | `cd7c4557e5307fac21938ce2fbf421ac0be9a3471a60dd469fdf7be5c6552f77` |
| `audio/efectos/ambiente/campanilla_1.wav` | GDC 2019 / Eiravaein Works - Helina/Helinä,windchimes,aluminum,pipes,woodclapper,aluminumwindcatcher,metalchain,twine,release,gentle,lingering,MidSide,alt.wav | canal Mid (grabado en Mid-Side: el canal 2 es el Side, 17 dB más bajo), 0,3-4,6 s, paso alto 150 Hz, fundido de salida 1,2 s | 4,30 s · −3,0 / −26,3 | `296439cca6b7c1ef7b5ad62cb653b5765d50d5566f6ed895b3bc54ebd7b89af6` |
| `audio/efectos/ambiente/campanilla_2.wav` | ídem | canal Mid, 8,8-13,0 s (la segunda ráfaga) | 4,20 s · −3,0 / −19,5 | `296439cca6b7c1ef7b5ad62cb653b5765d50d5566f6ed895b3bc54ebd7b89af6` |
| `audio/efectos/ambiente/campanilla_3.wav` | GDC 2019 / Eiravaein Works - Helina/Helinä,windchimes,mixed,paper,aluminum,tuned,glassclappermini,windcatcher,cottonrope,release,gentle,lingering,MidSide.wav | canal Mid, 0,0-6,0 s, paso alto 150 Hz, fundido de salida 1,5 s | 6,00 s · −3,0 / −26,7 | `ca9649eafb7a150bedd9b5a86271f3dc122a6675a726049e003bc7fcc53c3b77` |

Los mismos SHA-256 están en `docs/audio/efectos_procedencia.csv` (las seis filas de `ambiente/gaviota_*` y
`ambiente/campanilla_*`) y en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-19_regiones\derivados\procedencia.json`.

**Formato:** `puerto.ogg`, Ogg Vorbis estéreo 48 kHz q4 (533 KB), `loop=true` en su `.import`, como los vientos del Mar
de Cristal; lo carga `musica.gd` como los demás ambientes. Las gaviotas y las campanillas, WAV mono 48 kHz de 16 bits
importados en QOA y sin bucle, como el resto de `audio/efectos/ambiente/`.

**Cómo se hicieron:** `preparar_regiones.py` (Python de la biblioteca estándar más el `ffmpeg.exe` que ya estaba en el
PC, el mismo del Mar de Cristal; no se ha instalado nada), con las funciones de `preparar_desierto.py` (bucle por cruce
de potencia constante, normalización por RMS con techo de pico o por pico). Guion, copia de las funciones y procedencia
en JSON en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-19_regiones\herramientas\` y `…\derivados\`.

**Lo que no se usó y por qué:** `Port ambience, small waves hitting boats.wav` (GDC 2017, Sound Ex Machina) habría sido
lo más parecido, pero es un puerto mediterráneo real y no puedo comprobar sin oírlo si lleva voces o motores. Los otros
dos archivos de Helinä (la campana japonesa con ráfaga fuerte; las cuentas de obsidiana) suenan, por su descripción, más a
golpeteo que a campanillas.

## 3. Volúmenes y mezcla

- `puerto.ogg` a −12 dB en la capa de ambiente (RMS −25,1 → por el bus Master −35,1 dBFS de RMS con dos gaviotas,
  medido por `prueba_musica_senal`). Referencia: la ciudad −33,0, el mapa −38,7.
- Gaviotas a −20 dB (RMS del derivado ~−18 → unos −38 dBFS: a la altura de las olas, sin taparlas), variación de tono
  ±6 %, nunca la misma variante dos veces seguidas, una a la vez (`max` 1), prioridad 0 (la más baja: cualquier efecto
  del juego pasa por encima).
- Campanillas a −15 dB, tono ±4 %, una a la vez, espera de 5 s, prioridad 0. Por el bus Master, la Arboleda con
  campanillas da −31,2 dBFS de RMS (pico −17,2).
- Dentro de la Hospedería, el viento baja de −10 a −24 dB con el fundido normal de `musica.gd` (2 s) y no se reinicia
  (es la misma pista): −48,7 dBFS por el bus Master, 17 dB por debajo de fuera.
- Pausa, cambio de escena, combate y «Sin sonido»: lo de siempre de `musica.gd` y de los detalles de `sonido.gd` (nunca
  en pausa ni en combate; se cortan al cambiar de escena).

## 4. Código

- `aethelgard/musica.gd`: «puerto» pasa a `puerto.ogg` a −12 dB; contextos nuevos «arboleda» y «arboleda_interior»;
  `contexto_de` da «arboleda» a `isla.tscn` y al tramo, y «puerto» a la zona 2D del lugar 5 (`LUGAR_SUNKEN`).
- `aethelgard/sonido.gd`: efectos `gaviota` (3 variantes) y `campanillas` (3), y `DETALLES["puerto"]` y
  `DETALLES["arboleda"]`. Sin `DETALLES["arboleda_interior"]`: dentro no suena ningún detalle.
- `aethelgard/zonas3d/arboleda_tramo/arboleda_tramo.gd` (`_cambiar_sala`): al entrar en la Hospedería pide
  «arboleda_interior» y al salir «arboleda». No se toca `isla.gd` (§3.5 del plan).
- `aethelgard/zonas3d/sunken_3d.gd`: solo el comentario de `_sonido_3d` (ya no dice que falten las olas).

## 5. Pruebas (datos aislados, 19/11, sobre el código de este commit)

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_musica` (aserciones nuevas 1b y 3b) | SUPERADA, «FALLOS: 0» | `D:\REBELUM_diagnostico\pruebas\2026-11-19_203630\` |
| la misma con `musica.gd` y `sonido.gd` del commit anterior | FALLIDA, «FALLOS: 5» (isla y tramo dan «viento», la Sunken 2D da «ciudad», el puerto pide `viento.wav`, no suena ninguna gaviota) | `…\2026-11-19_203705\` |
| `prueba_integridad` | SUPERADA | `…\2026-11-19_203630\` |
| `prueba_efectos` (catálogo: 228 efectos, 335 archivos QOA mono) y `prueba_audio_memoria` (20,79 MB de 21) | SUPERADAS | `…\2026-11-19_203727\` |
| `prueba_musica_senal` (con ventana, driver real; aserción nueva: la Hospedería 6 dB más baja) y `prueba_arboleda_tramo` (con ventana; aserciones nuevas: «arboleda», y dentro «arboleda_interior» sin detalles) | MANUAL (terminan sin errores, «FALLOS: 0»; dejan grabaciones y capturas) | `…\2026-11-19_203816\` |
| `prueba_sunken3d`, `prueba_sunken3d_apagada` | SUPERADAS | `…\2026-11-19_204038\` |
| `prueba_isla` (con ventana), `prueba_sunken_quilla` | MANUAL sin errores / SUPERADA | `…\2026-11-19_204105\` |

**El empalme del bucle**, comprobado con `empalme.py` sobre el OGG ya codificado (el final seguido del principio):
el paso alto (> 4 kHz) en ±5 ms del empalme es 1,12 veces el percentil 99,9 del resto de la ventana (lo mismo que el
agua alrededor: sin clic), el salto de muestra en la vuelta es 2,05 y 0,84 veces la mediana y la envolvente de 50 ms no
tiene un escalón mayor que sus vecinos. Dibujos y cifras en `…\sonido_muestras\2026-11-19_regiones\empalme_puerto_*.png`
y `empalmes.txt` (el `viento.wav` de siempre, que usa la Arboleda: clic 0,64, costura 0,95).

## 6. Lo que queda

- **Escucharlo** (usuario): `D:\REBELUM_diagnostico\sonido_muestras\2026-11-19_regiones\indice.md`. Lo más dudoso: si
  las olas lejanas suenan a mar abierto en una laguna; si las gaviotas 2 y 3 (de una bandada) se oyen como «muchas»; si
  las campanillas son demasiado brillantes o frecuentes.
- **En el Redmi:** nada de esto se ha oído ni medido en el móvil.
- **Memoria del audio:** 20,79 MB de los 21 de `prueba_audio_memoria` (las seis WAV nuevas suman unos 0,4 MB). Queda
  poco margen para la siguiente tanda: si hace falta, bajar estas seis a 32 kHz (añadiéndolas a `FRECUENCIA`).
- **Sunken 3D:** el agua junto al casco sigue siendo el bucle del río (`rio`, −15 dB, dos líneas en `sunken_3d.gd`). Un
  emisor propio de olas contra la madera (por ejemplo, de la rampa de barcas de arriba, en mono) sería mejor.
- **Charcas y lava de las zonas 2D:** no hechas. `sonido.gd` (`agua_zona`, `AGUA_2D`) solo pone sonido al río de agua;
  la lava (`ceniza`) y el veneno (`yermo`) no suenan, y las charcas tampoco (por diseño, `mascara_rio`). Haría falta un
  bucle de lava (burbujeo grave) y otro de charca, y que `agua_zona` acepte esos estilos y las manchas que no son río.
