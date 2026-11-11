# Sonido · V12, el Mar de Cristal (primer sector) · 2026-11-11

Especialista de sonido. Rama `claude/v12-desierto-sonido` en `D:\Aethelgard_v12_sonido`, desde `claude/rebelum-v12` @
`e9eebf1` (contrato `docs/v12/DISENO_V12.md`). Archivos míos: `aethelgard/audio/desierto/*`, las claves nuevas de
`aethelgard/sonido.gd`, `aethelgard/pruebas/prueba_audio_desierto.gd` y su línea en `pruebas/lista_pruebas.txt` (los
pidió el encargo) y este informe. **No he podido escuchar nada**: lo que sigue está medido, no oído.

## 1. Qué hay

### Derivados (`aethelgard/audio/desierto/`, OGG Vorbis, 48 kHz; 1,36 MB en total)

Medido el 11/11 sobre el OGG ya codificado (pico y RMS en dBFS; «costura»: el salto al dar la vuelta frente al salto
típico entre muestras, ~1 = no se nota en la forma de onda).

| Archivo | Clave | Evento previsto | Canales · dur. · calidad | Pico / RMS | Bucle |
|---|---|---|---|---|---|
| `viento.ogg` | `desierto_viento` | el viento del Mar de Cristal en calma (todo el sector) | estéreo · 36,0 s · q4 | −6,2 / −24,2 | sí (costura 0,25; en el OGG 1,25) |
| `tormenta.ogg` | `desierto_tormenta` | la tormenta de arena (paso 4 y las sistémicas) | estéreo · 30,0 s · q4 | −3,3 / −19,4 | sí (1,01 / 1,07) |
| `fogata.ogg` | `fogata_bucle` | la fogata del campamento (36, 92) | mono · 14,0 s · q4 | −2,8 / −32,3 | sí (1,08 / 1,38) |
| `oasis.ogg` | `oasis_bucle` | el agua y los juncos del oasis (74, 72) | mono · 24,0 s · q4 | −3,3 / −26,7 | sí (1,20 / 0,83) |
| `gusano_temblor.ogg` | `gusano_temblor` | el aviso del gusano en la arena que tiembla | mono · 4,60 s · q4 | −1,6 / −14,4 | no |
| `gusano_rugido.ogg` | `gusano_rugido` | el rugido sordo bajo la arena (antes de emerger) | mono · 5,20 s · q4 | −1,4 / −15,5 | no |
| `excavar_arena_1.ogg` | `excavar_arena` (1) | «Excavar» con el buscador encima | mono · 1,56 s · q4 | −2,2 / −27,5 | no |
| `excavar_arena_2.ogg` | `excavar_arena` (2) | ídem, más grave y con arena que cae | mono · 1,73 s · q4 | −2,8 / −27,5 | no |
| `buscador_pitido.ogg` | `buscador_pitido` | cada pitido del buscador (más rápidos al acercarse) | mono · 0,15 s · q5 | −3,0 / −19,5 | no |
| `buscador_pitido_raro.ogg` | `buscador_pitido_raro` | ídem, si lo que hay es raro (otro tono) | mono · 0,22 s · q5 | −2,8 / −21,6 | no |

Niveles de referencia de lo que ya había (del historial, `docs/audio/efectos_procedencia.csv`): bucles de −22 a −30 RMS
con pico ≤ −2; efectos con pico de −1 a −3. Los cuatro bucles llevan `loop=true` en su `.import`; los demás, `false`.

### Origen y licencia de cada archivo (tramos y capas)

Todos salen de los **paquetes GDC de Sonniss** de la biblioteca del usuario (`D:\qtorrent\sound effect`, solo lectura),
salvo los pitidos, que son **síntesis propia** (sin licencia de terceros). **Licencia Sonniss «#GameAudioGDC»**: uso en
proyectos personales y comerciales ilimitados, **sin atribución**, sincronizados con juegos, editarlos como parte de la
producción; no venderlos tal cual ni atribuirse su autoría (y el de 2024, sin entrenar IA). Leído hoy en
`Sonniss.com - GDC 2023 - Game Audio Bundle/License.pdf`; los PDF de 2016, 2017, 2018, 2019 y 2020 se leyeron el 08/11 y
se comprobaron otra vez el 09/11 (del historial: `docs/audio/inventario_sonidos.md`, «Licencias y evidencia»). Ninguno
es de la colección CC0 ni de Suno.

| Derivado | Original (paquete / carpeta / archivo) | Tramo y tratamiento | SHA-256 del original |
|---|---|---|---|
| `viento.ogg` | GDC 2018 / Soundrangers - Wind / `wind_desert_01_60_loop.wav` | 4,0-43,0 s → bucle de 36 s (cruce de 3 s), paso alto 35 Hz | `f1302790e4ac24fa024b6a45409b165afe3d72e21e6aaa52717e6128505d6674` |
| | + GDC 2016 / Eiravaein Sound - Grit / `Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav` | arena fina: bucle de 9 s ×4, paso alto 1,5 kHz, −20 dB | `f47f250739d23be482161919a3cec28e82ec8be3d3248f50e7d647c07b896f07` |
| `tormenta.ogg` | GDC 2018 / Soundrangers - Wind / `wind_blustery_08_loop.wav` | rachas: su bucle ×2, 0-33 s → bucle de 30 s, paso alto 60 Hz | `29d11a429ee3da7d7ee3347075015f4a957ede2adfcacc67b6224c0b084a46d7` |
| | + GDC 2018 / Soundrangers - Wind / `wind_harsh_mountain_02_30_loop.wav` | silbido: su bucle ×2, 2-35 s, paso alto 200 Hz, −5 dB | `df2c0f7af4e6158f93b31fb1d9eb432c043d4d7a223ca9be95c786fff647afdb` |
| | + GDC 2020 / Articulated Sounds - Rare Winds / `WEATHER WIND Beach, Strong, Gusty, Storm, Sands & Seaweed, Tierra Del Fuego, Argentina, LOOP.wav` | cuerpo grave: 70-103 s, banda 45-900 Hz, −9 dB | `6ec0562cacd948656875f7c068ac4192b0180913d893397b61f6ff577f0d2291` |
| | + GDC 2016 / Eiravaein Sound - Grit / (el mismo de la arena fina) | arena que golpea: bucle de 7,5 s ×4, paso alto 1,2 kHz, −4 dB; RMS −19 y limitador a −1,5 dBFS | (arriba) |
| `fogata.ogg` | GDC 2023 / Stefano Cremona - Pure Nature Ambiences / `Campfire.wav` | 2-18 s → bucle de 14 s (cruce 2 s), paso alto 110 Hz, RMS −30 y limitador a −3 dBFS (los chasquidos mayores, hasta ~9 dB) | `de8d346de318528d40daea1d2a5cd1b47211323a65bf9007b8c28890f8f4c48f` |
| `oasis.ogg` | GDC 2018 / Soundrangers - Hydrology Streams, Rivers And Lakes / `lake_waves_lapping_gentle_02_60_loop.wav` | 3-30 s → bucle de 24 s (cruce 3 s), paso alto 90 Hz | `d59050075d092c82cc3d2c654d4449d7b1279b8b0c869975551ccdec2fdaac7e` |
| | + GDC 2017 / Hzandbits - Wind In Trees / `Wind,Ext,Breeze,Reeds,Rustle,Howl,Whip,Whistle.wav` | juncos: el tramo tranquilo 24-51 s (sin aullidos ni látigos) → bucle de 24 s, paso alto 250 Hz, −7 dB | `96cf4d24eeb1e0afc354d9eea2cfba96a77fdf283c378aa397b056e124784681` |
| `gusano_temblor.ogg` | GDC 2018 / Olivier Girardot - Guns & Explosions / `Earthquake 3 - Big.wav` | 1,0-5,6 s (el original satura de 8 a 38 s: no se usa), banda 30 Hz-4 kHz; fundidos 0,7 y 1,4 s | `ce7d78c8f5cead043c51a16a8288eee40b87ecd7a3fd32b8dcb89873b6217639` |
| | + GDC 2016 / Eiravaein Sound - Grit / (arena fina) | arena que se escurre: 1-5 s, paso alto 900 Hz, −10 dB, desde 0,4 s | (arriba) |
| `gusano_rugido.ogg` | GDC 2020 / Articulated Sounds - Camel Growl Vocalizations / `ANIMAL WILD Camel A, Grunt, Groan, Roar x13.wav 12.wav` | el gruñido entero, una octava más grave (×0,5), paso bajo 750 Hz («oído a través de la arena»), desde 0,55 s | `fd2cc936a68344396c7eef7b5f1551f1f492d3ac2de1d3539f8b6665713ca2c2` |
| | + GDC 2018 / Bluezone Corporation - KOSMONAUT - CINEMATIC / `Bluezone_BC0238_rumble_004.wav` | retumbo: 0,5-5,7 s, banda 28-220 Hz, −6 dB | `6a5c227b09799ad42e0544e781a3cf0a9282dd707821babedd4923ffaca09581` |
| `excavar_arena_1.ogg` | GDC 2019 / Matt Script - You Me & Debris / `impact_gritty_grit_sandy_dirt_dig_shovel_shingle_roof_02.wav` | 0,06-1,62 s, paso alto 80 Hz | `fd59551b49d2af7b9f35c2ac90a7ad616ce063e4b15980cd85656584d280af3f` |
| `excavar_arena_2.ogg` | ídem | ×0,9 de tono, paso alto 80 Hz | (arriba) |
| | + GDC 2016 / Eiravaein Sound - Grit / `Grit,course,hardsurface,throw,scatter.wav` | la arena que cae de la pala: entero, paso alto 300 Hz, −4 dB, desde 0,95 s | `75dc3bae91eb931b922db93c547f638af251659388ca412bc3740e54c17d2f29` |
| `buscador_pitido.ogg` | síntesis propia | seno de 1320 Hz + su octava (−13 dB) + 3× (−24 dB); ataque 4 ms, caída exponencial | — |
| `buscador_pitido_raro.ogg` | síntesis propia | seno de 1976 Hz + parciales de campana 2,76× (−10 dB) y 5,40× (−18 dB): más agudo y «de cristal» | — |

**El pitido del buscador:** en la biblioteca no había ninguno limpio y adecuado (los «beep» de los paquetes son de
ciencia ficción o de interfaz moderna, y los del paquete GDC sin año no tienen archivo de licencia en su carpeta), así que lo he
sintetizado yo como archivo: el coordinador no tiene que generarlo por código.

**Cómo se hicieron:** `preparar_desierto.py` (Python de la biblioteca estándar) con el `ffmpeg.exe` que ya estaba en el
PC (`C:\Users\G513\AppData\Local\Programs\Stremio\ffmpeg.exe`, 4.4.1, con libvorbis) para leer, filtrar, remuestrear y
codificar. **No se ha instalado nada** (la tanda 7 dijo que no había codificador Vorbis: no había visto este ffmpeg).
Bucles sin costura por cruce de potencia constante; normalización por RMS con techo de pico (o por pico en los
efectos); un limitador con anticipación en la tormenta y la fogata. El script, las mezclas y la procedencia en JSON
están en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-11_desierto\herramientas\`. Los originales no se han tocado
(solo se leen; su SHA-256 arriba).

### `sonido.gd`

- **`bf742da`, solo se añade (54 líneas):** `EFECTOS_DESIERTO` (las 9 claves, con el formato de `EFECTOS` y dos campos
  más: `dir` y `ext`), `DESIERTO` y tres funciones: `definicion(nombre)` (busca en `EFECTOS` y luego en
  `EFECTOS_DESIERTO`), `ruta_archivo(d, i)` y `ruta_de(nombre)`. No cambia ninguna línea existente.
  - **Por qué aparte de `EFECTOS`:** `prueba_efectos` (`_catalogo`) exige que **todo** `EFECTOS` sea WAV en QOA mono en
    `audio/efectos/`: meter OGG ahí la habría hecho fallar, y esa prueba no es mía.
- **`249cf1f`, cambio mínimo (9 líneas) para que suenen:** el catálogo construía las rutas como
  `EF + d["a"] + ".wav"`, así que un OGG no podía sonar con `efecto()` ni con `fuente_3d()`. Ahora `efecto()`,
  `_elegir()`, `fuente_linea()`, `_emisor()`, `fuente_2d()` y `_sonar_fuente()` usan `definicion()` y `ruta_archivo()`.
  Para las claves de siempre el resultado es idéntico (`audio/efectos/` y `.wav`; lo comprueba `prueba_audio_desierto`,
  C, y `prueba_efectos` sigue pasando). `archivos()` y `agua_zona()` no se tocan. **Se puede revertir solo** sin
  perder las claves (entonces habría que pedir los OGG con un reproductor propio y `ruta_de()`).

| Clave | Bus · dB · prioridad · máx · espera | Tipo |
|---|---|---|
| `desierto_viento` | Ambiente · −13 | bucle del lugar (`bucle`) |
| `desierto_tormenta` | Ambiente · −9 (unos 9 dB por encima de la calma) | bucle del lugar (`bucle`) |
| `fogata_bucle` | Ambiente · +2 · `tres_d` unidad 3 m, máx 24 m | emisor 3D en bucle |
| `oasis_bucle` | Ambiente · −4 · `tres_d` unidad 7 m, máx 32 m, filtro −8 | emisor 3D en bucle |
| `gusano_temblor` | Efectos · −7 · p 3 · 1 · 1,5 s · tono ±5 % · `en_3d` 10 / 70 m | efecto (con `pos`) |
| `gusano_rugido` | Efectos · −6 · p 3 · 1 · 2,5 s · tono ±6 % · `en_3d` 12 / 90 m | efecto (con `pos`) |
| `excavar_arena` | Efectos · −6 · p 2 · 1 · 0,3 s · 2 variantes, tono ±5 % | efecto |
| `buscador_pitido` | Efectos · −14 · p 1 · 2 · 0,05 s · sin variar el tono | efecto |
| `buscador_pitido_raro` | Efectos · −14 · p 1 · 2 · 0,05 s · sin variar el tono | efecto |

Los dB son una primera propuesta, calculada con lo medido (la calma queda en unos −37 dBFS netos, como la pradera; la
tormenta, en unos −28): **falta escucharlos**, en el PC y en el Redmi.

## 2. Cómo engancharlo (para quien lleve `mar_cristal_3d.gd`, `buscador.gd` y `musica.gd`; no lo he tocado)

```gdscript
# mar_cristal_3d.gd, al montar la escena (los emisores son hijos suyos y se van con ella):
Sonido.fuente_3d(self, "fogata_bucle", Vector3(36, 0.4, 92))
Sonido.fuente_3d(self, "oasis_bucle", Vector3(74, 0.2, 72))
# el gusano (zona x 60-88, z 20-50): el aviso desde el surco que avanza, y el rugido si Kael sigue en la arena blanda
Sonido.efecto("gusano_temblor", {"pos": punto_del_surco})
Sonido.efecto("gusano_rugido", {"pos": punto_del_surco})
# buscador.gd: un pitido por latido (el intervalo, por la cercanía); nada con tormenta («La tormenta tapa la señal»)
Sonido.efecto("buscador_pitido_raro" if es_raro else "buscador_pitido")
Sonido.efecto("excavar_arena")                     # al excavar (nunca con tormenta)
```

Los dos vientos son bucles del lugar que se funden entre sí: lo natural es `musica.gd` (capa «ambiente», ya con
fundidos). **Propuesta para `musica.gd`** (no es mío en esta tanda), en `CONTEXTOS`:

```gdscript
"mar_cristal": {"musica": "", "ambiente": "res://audio/desierto/viento.ogg", "db": -13.0},
"tormenta_arena": {"musica": "", "ambiente": "res://audio/desierto/tormenta.ogg", "db": -9.0},
```

(o `Sonido.ruta_de("desierto_viento")` / `ruta_de("desierto_tormenta")` y `definicion(...)["db"]` desde otro
reproductor por el bus Ambiente). En el cobijo (14, 48) la tormenta podría bajar unos 6-8 dB (paso bajo o volumen):
queda para cuando se escuche.

## 3. Pruebas (con datos aislados)

- **Importación aislada** antes y después de los OGG: `D:\REBELUM_diagnostico\importaciones\v12sonido_inicial_*`,
  `v12sonido_ogg1_*` y `v12sonido_ogg2_*` (los `.import` con `loop=true` en los bucles).
- **`prueba_audio_desierto`** (nueva, `auto`, muda): A, las 9 claves en `EFECTOS_DESIERTO` (no en `EFECTOS`), cada
  archivo es un `AudioStreamOggVorbis` de `audio/desierto/`, con su duración, bucle sí o no según el catálogo (lo marca el
  `.import`), presupuesto (1 700 KB; hay 1 363) y su fila en este informe; B, la señal decodificada con `mix_audio` (ni
  muda ni saturada; los bucles siguen sonando al dar la vuelta y los demás callan; la tormenta, más de 5 dB por encima de
  la calma con el volumen del catálogo; el pitido raro, más agudo); C, se piden con `efecto()` (con `pos` el gusano; la
  pala alterna sus dos variantes; dos pitidos a 0,1 s suenan los dos) y `fuente_3d()` (fogata y oasis en bucle por
  Ambiente), `ruta_de()` de los vientos y de claves de antes (`golpe`, `rio`, `cofre`: siguen en `audio/efectos/` y WAV).
- Resultados: en la sección 5.

## 4. Evidencias

- Muestras para escuchar, con índice: `D:\REBELUM_diagnostico\sonido_muestras\2026-11-11_desierto\indice.md`
  (10 solos, los mismos OGG del juego, y 5 mezclas **simuladas** fuera del motor: campamento, calma → tormenta → calma,
  gusano, buscador y oasis).
- Medidas y huellas: `…\2026-11-11_desierto\herramientas\procedencia.json`.

## 5. Resultados y límites

**Comprobado ejecutando (aislado), 11/11 a las 12:23, con `249cf1f` más la prueba y este informe sin confirmar:**
`prueba_audio_desierto`, `prueba_efectos`, `prueba_audio`, `prueba_audio_memoria` y `prueba_audio_guardian`:
**5 superadas, 0 fallidas**. Partida real, carpeta real de datos y proyecto, sin cambios; ningún otro Godot. Resumen:
`D:\REBELUM_diagnostico\pruebas6-11-11_122325esumen.md`. (Una primera pasada a las 12:20 falló solo porque este
informe aún no existía y por dos umbrales míos de la prueba: 3 muestras de menos al remuestrear los pitidos y un oasis
que empieza entre dos olas; corregidos.)

- Señal decodificada por Godot (`mix_audio`, a la frecuencia del mezclador): los cuatro bucles vuelven a empezar al
  dar la vuelta (mismo nivel tras el final que al principio); los efectos callan después del final; ningún pico por
  encima de −1,4 dBFS. Con el volumen del catálogo, viento en calma −37,3 dB y tormenta −28,5 dB (8,8 dB más).
  Pitidos por cruces por cero (aproximado, los parciales lo suben): normal ~1 860 Hz, raro ~2 460 Hz.
- `prueba_efectos` sigue pasando con el cambio de `249cf1f` (181 efectos, 284 archivos de siempre).
- `prueba_audio_memoria`: 20,36 MB de RAM, igual que antes (los OGG van en streaming y no cuentan como datos cargados);
  paquete 21,87 MB.

**Límites (pendiente de verificar):**
- **No se ha escuchado nada.** Timbre, si el camello se reconoce, si la tormenta cansa, si los chasquidos de la
  fogata saltan y si los bucles se notan al dar la vuelta: hay que oírlo (muestras del apartado 4). Las mezclas son
  simuladas, fuera del motor.
- Los volúmenes (`db`) son una propuesta medida, no escuchada; ni en el PC ni en el Redmi. En el altavoz del móvil lo
  de menos de ~250 Hz casi no se oye: el rugido lleva medios a propósito, el temblor y el cuerpo de la tormenta no.
- No hay escena del Mar de Cristal en mi rama: nada está enganchado a eventos reales todavía (lo hace el coordinador,
  apartado 2). Los emisores se han probado en un nodo de prueba, no en la región.
- El coste de decodificar varios OGG a la vez en el Mali-G57/CPU del Redmi no está medido (no mido rendimiento con
  otros especialistas trabajando). Lo más que sonaría a la vez: un viento, fogata u oasis y algún efecto.
- No he guardado filas en `docs/audio/efectos_procedencia.csv` ni en `docs/audio/inventario_sonidos.md` ni en
  `docs/recursos.md` (no eran mis archivos en esta tanda): la procedencia completa está aquí.

**Cambios que pido en archivos de otros:**
1. `musica.gd`: los dos contextos del apartado 2 (o el reproductor que prefiera el coordinador) y su fundido al
   empezar y acabar la tormenta.
2. `mar_cristal_3d.gd`, `buscador.gd` y la lógica del gusano: las llamadas del apartado 2.
3. Si se quiere el inventario común al día: copiar la tabla del apartado 1 a `docs/audio/inventario_sonidos.md`
   (sección V12) y una fila por derivado en `docs/audio/efectos_procedencia.csv` y `docs/recursos.md`.
