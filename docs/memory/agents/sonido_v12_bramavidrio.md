# Sonido · V12, identidad sonora de Bramavidrio · noche del 11 al 12/11/2026

Especialista de sonido. Rama LOCAL `claude/v12-sonido-bramavidrio` en `D:\Aethelgard_v12_sonido_brama`, desde
`claude/rebelum-v12` @ `373e7db`. Sin push ni merge. Archivos míos: `aethelgard/audio/bramavidrio/*`, las claves nuevas
de `aethelgard/sonido.gd`, las llamadas de sonido de `aethelgard/combate_bramavidrio.gd`,
`aethelgard/pruebas/prueba_audio_bramavidrio.gd` (y su línea en `pruebas/lista_pruebas.txt`) y este informe; además,
seis líneas de `pruebas/prueba_bramavidrio_combate.gd` (apartado 3.4, en su propio commit).

**No he podido escuchar nada.** Todo lo que sigue está medido (pico, RMS, LUFS, bandas, duración, instante, costura)
con herramientas reales, no oído. Las mezclas de prueba son **simuladas** fuera del motor.

## 1. La identidad

Encargo: tamaño colosal, nada estridente, artificial ni genérico; rugido grave, respiración y mandíbula, cristales que
chocan, placas minerales que rozan, desplazamiento bajo la arena, succión de arena, chorro de arena comprimida, impacto
sísmico, fragmentación de roca y la derrota de una criatura colosal. Lo que comparten todos sus sonidos (para que se
reconozca como uno solo y no como una colección de efectos sueltos):

1. **Tamaño:** todas las capas van más graves y lentas que el original (remuestreo ×0,45-0,85), ataques que no son
   secos, colas largas y un retumbo por debajo; pero con medios presentes (120-2 500 Hz a −2/−8 dB del total), porque el
   altavoz del móvil casi no da nada por debajo de ~250 Hz.
2. **Materia:** roca, arena y **vidrio** (Mar de Cristal: costra mineral con placas de vidrio). El vidrio va con paso
   bajo (5-6,5 kHz) y por debajo de lo grave y lo medio: los agudos (>2,5 kHz) quedan a −10/−28 dB del total.
3. **Firma:** un tono de cristal frotado (copa de vino, Raconteur Sound) dos octavas por debajo, muy bajo, que resuena
   en el rugido, al aspirar y al morir: su cuerpo de vidrio vibra.
4. **Espacio común:** la misma respuesta al impulso sintética (desierto abierto, eco difuso de roca: ruido decorrelado
   con caída de 1,5 s, 30 ms de retardo, paso bajo 2,6-4,2 kHz) en todos, a −13/−20 dB.
5. **Nivel común:** todos los archivos con el mismo LUFS momentáneo máximo (−12; el bucle, el surco y la arena que
   alcanza, por RMS); el «db» del catálogo decide su papel en la mezcla (los grandes momentos, como el «jefe» de siempre).

### Qué suena y cuándo (combate; observado en el código y comprobado ejecutando, apartado 4)

| Momento (dónde se pide) | Identidad propia (clave) | Lo de antes (con el interruptor apagado) |
|---|---|---|
| Entra: rompe la arena (señal `rompe_arena`, 0,233 s de «emerger») | `brama_emerge` | `gusano_temblor` |
| Entra: 0,9 s después | `brama_rugido` | `gusano_rugido` |
| Embestida: se recoge (clip «ataque» 0,2 s) | `brama_recoge` | — |
| Embestida: fija al objetivo (0,55) | `brama_fija` | — |
| Embestida: se lanza (0,8) | `brama_latigazo` | — |
| Embestida: avanza sobre la arena (`_deslizar`, solo si el objetivo está lejos) | `brama_surco` | — |
| Embestida: impacto (señal del modelo, 1,0) | `brama_embestida` (2 variantes) + el `golpe` de siempre | `gusano_temblor` |
| Aviso de la Fractura: `rugido_pico` (1,25 s de «ataque_sismico») | `brama_rugido` (+ `carga_jefe` de siempre) | `gusano_rugido` |
| Fractura: cae (2,1) | `brama_caida_aire` | — |
| Fractura: impacto (2,5333) | `brama_fractura` + `golpe_critico` de siempre | `gusano_temblor` |
| Fractura: `placas_suelo` (v2; la v1, con el impacto) | `brama_placas` (con los terrones a +0,3 s dentro) | — |
| Fractura: `placas_asientan` (3,1) | `brama_placas_asientan` | — |
| Aviso del Aliento: `succion` (0,45 de «ataque_aliento») | `brama_succion` + el bucle `brama_succion_bucle` (hasta `fin_succion` 1,7, el golpe o el corte; puede durar turnos) | `gusano_temblor` |
| Aliento: el chorro (1,85) | `brama_chorro` + `golpe_critico` de siempre | `gusano_rugido` |
| Aliento: el chorro alcanza a cada héroe (`_alcanzar`, de delante atrás) | `brama_arena_alcanza` (2 variantes, una por héroe) | — |
| Le cortan el Aliento (`cortar`) | `brama_atraganta` (+ la «rota» de siempre) | — |
| El turno que jadea o escupe la arena (`turno`, «recupera») | `brama_jadeo` | — |
| Un héroe le golpea (`Sonido.recibe`, combate.gd) | voz `brama_herido` (3 variantes) | `piedra_herido` |
| El golpe que lo vence (`Sonido.recibe` / «muerte») | voz `brama_caida` | `piedra_caida` |
| Se desploma (señal `caida`, 1,6 s de «derrota») | `brama_derrumbe` | `gusano_temblor` |

### Derivados (`aethelgard/audio/bramavidrio/`, OGG Vorbis 48 kHz, 25 archivos, 1 043 KB)

Medido el 11/11 por la noche sobre el OGG ya codificado (lo que suena en el juego). «Mmax»: LUFS momentáneo máximo
(ventana de 400 ms). «En juego»: Mmax + db del catálogo (bus Efectos al 100 %). Bandas: RMS de cada banda respecto al
total. Referencias medidas igual (del proyecto): `golpe` −24/−25, `golpe_critico` −22, `jefe` −15,8, `victoria` −17,1,
`gusano_rugido` −20,1, `gusano_temblor` −20,3; música del combate −18,2 LUFS integrados (Mmax −14,9) y el clímax «Volverá
a amanecer» −20,9 LUFS integrados con su −7 dB.

| Archivo | Clave | Can. · dur. · q | Pico / RMS dBFS | LUFS-I / Mmax | Bandas <120 · 120-500 · 500-2,5k · >2,5k (dB rel.) | db catálogo → Mmax en juego | KB |
|---|---|---|---|---|---|---|---|
| `emerge.ogg` | `brama_emerge` | estéreo · 5.17 s · q4 | -1.1 / -17.0 | -14.2 / -12.1 | -3.3 · -5.6 · -8.5 · -15.6 | -5 → -17.1 | 80 |
| `rugido_1.ogg` | `brama_rugido (1)` | estéreo · 6.58 s · q4 | -2.7 / -17.8 | -15.7 / -12.1 | -5.4 · -2.8 · -10.9 · -28.3 | -3 → -15.1 | 80 |
| `rugido_2.ogg` | `brama_rugido (2)` | estéreo · 6.09 s · q4 | -1.5 / -19.1 | -16.6 / -12.2 | -5.9 · -3.1 · -7.8 · -26.0 | -3 → -15.2 | 68 |
| `recoge.ogg` | `brama_recoge` | mono · 1.99 s · q5 | -1.0 / -15.0 | -14.3 / -12.5 | -4.9 · -3.4 · -10.1 · -21.4 | -10 → -22.5 | 22 |
| `fija.ogg` | `brama_fija` | mono · 1.57 s · q5 | -1.8 / -17.0 | -15.1 / -12.1 | -7.7 · -3.0 · -7.4 · -15.2 | -9 → -21.1 | 18 |
| `latigazo.ogg` | `brama_latigazo` | mono · 1.66 s · q5 | -1.2 / -15.9 | -15.0 / -12.5 | -5.5 · -4.3 · -5.8 · -16.5 | -9 → -21.5 | 18 |
| `surco.ogg` | `brama_surco` | estéreo · 2.17 s · q4 | -1.2 / -26.1 | -19.6 / -17.1 | -12.3 · -7.5 · -4.7 · -4.5 | -5 → -22.1 | 33 |
| `embestida_1.ogg` | `brama_embestida (1)` | estéreo · 2.24 s · q4 | -1.4 / -19.3 | -14.5 / -12.2 | -6.7 · -6.1 · -4.2 · -12.6 | -7 → -19.2 | 35 |
| `embestida_2.ogg` | `brama_embestida (2)` | estéreo · 2.18 s · q4 | -1.8 / -20.7 | -17.0 / -12.2 | -5.6 · -4.7 · -6.4 · -13.2 | -7 → -19.2 | 34 |
| `caida_aire.ogg` | `brama_caida_aire` | mono · 0.50 s · q5 | -0.7 / -10.5 | -13.5 / -13.1 | -1.7 · -7.2 · -11.9 · -24.6 | -9 → -22.1 | 8 |
| `fractura.ogg` | `brama_fractura` | estéreo · 5.81 s · q4 | -2.3 / -22.7 | -20.4 / -12.4 | -3.4 · -6.5 · -6.9 · -13.9 | -3 → -15.4 | 85 |
| `placas.ogg` | `brama_placas` | estéreo · 3.60 s · q4 | -1.2 / -18.3 | -14.9 / -12.2 | -4.7 · -4.5 · -8.8 · -14.0 | -7 → -19.2 | 57 |
| `placas_asientan.ogg` | `brama_placas_asientan` | estéreo · 2.10 s · q4 | -1.4 / -18.1 | -13.7 / -12.1 | -5.2 · -3.3 · -9.1 · -16.5 | -10 → -22.1 | 33 |
| `succion.ogg` | `brama_succion` | estéreo · 3.77 s · q4 | -3.8 / -21.4 | -16.9 / -12.3 | -10.3 · -4.8 · -3.7 · -13.0 | -4 → -16.3 | 48 |
| `succion_bucle.ogg` | `brama_succion_bucle` | estéreo · 6.00 s · q4 | -10.6 / -24.4 | -20.5 / -19.9 | -17.9 · -10.0 · -1.2 · -12.7 | -7 → -26.9 | 76 (bucle; costura 0,34) |
| `chorro.ogg` | `brama_chorro` | estéreo · 3.04 s · q4 | -3.1 / -20.3 | -15.6 / -12.3 | -5.0 · -5.6 · -6.6 · -10.7 | -3 → -15.3 | 44 |
| `alcanza_1.ogg` | `brama_arena_alcanza (1)` | mono · 0.95 s · q5 | -1.3 / -25.4 | -22.2 / -20.2 | -19.2 · -6.5 · -3.6 · -6.5 | -3 → -23.2 | 14 |
| `alcanza_2.ogg` | `brama_arena_alcanza (2)` | mono · 1.03 s · q5 | -0.9 / -22.0 | -21.8 / -17.5 | -10.8 · -4.5 · -4.9 · -9.0 | -3 → -20.5 | 15 |
| `jadeo.ogg` | `brama_jadeo` | mono · 3.74 s · q4 | -0.8 / -16.4 | -16.1 / -13.0 | -5.5 · -4.9 · -5.3 · -18.1 | -6 → -19.0 | 38 |
| `atraganta.ogg` | `brama_atraganta` | mono · 2.31 s · q4 | -1.1 / -16.9 | -14.9 / -12.4 | -11.4 · -2.3 · -5.7 · -18.0 | -7 → -19.4 | 21 |
| `herido_1.ogg` | `brama_herido (1)` | mono · 1.83 s · q5 | -1.3 / -16.8 | -15.8 / -12.1 | -7.9 · -3.6 · -5.5 · -17.5 | -9 → -21.1 | 18 |
| `herido_2.ogg` | `brama_herido (2)` | mono · 2.00 s · q5 | -1.1 / -16.0 | -13.9 / -12.2 | -13.2 · -4.6 · -2.5 · -18.9 | -9 → -21.2 | 20 |
| `herido_3.ogg` | `brama_herido (3)` | mono · 1.63 s · q5 | -0.8 / -16.0 | -15.3 / -13.1 | -11.9 · -1.8 · -7.0 · -23.2 | -9 → -22.1 | 17 |
| `caida.ogg` | `brama_caida` | estéreo · 6.51 s · q4 | -2.3 / -19.1 | -16.3 / -12.2 | -8.4 · -3.7 · -4.5 · -23.4 | -5 → -17.2 | 74 |
| `derrumbe.ogg` | `brama_derrumbe` | estéreo · 5.94 s · q4 | -0.9 / -18.5 | -14.9 / -12.4 | -5.9 · -4.8 · -5.6 · -12.2 | -4 → -16.4 | 88 |


## 2. Licencias (verificadas hoy)

Todas las capas salen de los **paquetes GDC de Sonniss** de la biblioteca del usuario (`D:\qtorrent\sound effect`,
solo lectura: se lee con ffmpeg; nada se ha copiado entero al proyecto, solo los 25 derivados). **Licencia Sonniss
«#GameAudioGDC»**, leída hoy en `Sonniss.com - GDC 2017 - Game Audio Bundle/Licensing.pdf` y en `Sonniss.com - GDC 2024 -
Game Audio Bundle/License - GDC Game Audio.pdf`: uso en proyectos personales y comerciales ilimitados, **sin
atribución**, sincronización con juegos, editarlos como parte de la producción; no venderlos tal cual ni atribuirse la
autoría del original; el de 2024, además, **sin entrenar IA**. Los PDF de 2016, 2017, 2018, 2019, 2020 y 2023 son el
mismo archivo (SHA-256 `d5da822dce9462890c4c…`, 95 184 bytes, comprobado hoy); el de 2024, `8a26e0113e8b00a4dc95…`.
Ninguna carpeta de paquete trae una licencia propia distinta (solo listas de pistas). **No se usa** el paquete «GDC» sin
año (sin archivo de licencia en su carpeta), ni la colección CC0, ni nada de Suno.

### 2.1 Capas de cada derivado (tramo en s del original; «tono»: remuestreo, < 1 más grave y lento; peso en dB sobre la capa a pico 0)

- **`emerge.ogg`** (espacio común -15 dB): Sonniss GDC 2024 «Bluezone_BC0292_alien_tripod_debris_rock_collapse_earthquake_rumble_large_005.wav» 0.1-3.9 s ×0.9 [highpass=f=50], -3 dB desde 0.00 s; Sonniss GDC 2019 «Explosive Hit 10 Filtered, Low End.wav» 0.4-1.5 s ×0.9, -10 dB desde 0.00 s; Sonniss GDC 2016 «rocks stream down heavy 02.wav» 0.2-4.2 s ×0.8 [highpass=f=180,lowpass=f=6500], -2 dB desde 0.25 s; Sonniss GDC 2023 «Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_glass_010.wav» 0.05-2.4 s ×0.82 [highpass=f=200,lowpass=f=6000], -7 dB desde 0.35 s; Sonniss GDC 2016 «Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav» 0.0-3.5 s ×0.9 [highpass=f=1300,lowpass=f=6500], -15 dB desde 0.60 s.
- **`rugido_1.ogg`** (espacio común -13 dB): Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 0.2-4.8 s ×0.6 [lowpass=f=1800], -9 dB desde 0.00 s; Sonniss GDC 2020 «Dinosaur Growl 3_Mono.wav» 0.78-3.7 s ×0.72 [highpass=f=35,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2018 «Monster Growls 4.wav» 2.5-4.35 s ×0.82 [lowpass=f=3200], -9 dB desde 0.05 s; Sonniss GDC 2017 «Crystal, Glass, Red Wine, Tone, Rubbing, Musical_07.wav» 0.3-3.6 s ×0.5 [highpass=f=180,lowpass=f=2400], -15 dB desde 0.15 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.0-3.2 s ×1.0 [lowpass=f=110], -11 dB desde 0.00 s; Sonniss GDC 2023 «DIRTCrsh_Stone Sand Trickle Reverberant 01_JSE_SD.wav» 1.0-4.0 s ×1.0 [highpass=f=1400,lowpass=f=6500], -17 dB desde 0.60 s.
- **`rugido_2.ogg`** (espacio común -13 dB): Sonniss GDC 2023 «MonsterPack2_LargeMonster11_Roar03.wav» 0.0-0.9 s ×0.55 [highpass=f=40,lowpass=f=6500], -4 dB desde 0.00 s; Sonniss GDC 2020 «Dinosaur Growl 3_Mono.wav» 0.8-3.7 s ×0.66 [highpass=f=35,lowpass=f=6500], +0 dB desde 0.30 s; Sonniss GDC 2018 «MONSTER Yeti groan 21.wav» 2.8-6.6 s ×0.7 [lowpass=f=2500], -12 dB desde 0.50 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 0.5-4.5 s ×0.55 [lowpass=f=1600], -10 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Red Wine, Tone, Rubbing, Musical_07.wav» 0.3-3.6 s ×0.47 [highpass=f=170,lowpass=f=2200], -15 dB desde 0.30 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.0-3.2 s ×1.0 [lowpass=f=110], -11 dB desde 0.00 s.
- **`recoge.ogg`** (espacio común -16 dB): Sonniss GDC 2017 «Door - Stone Long 02.wav» 1.0-1.9 s ×0.7 [highpass=f=60], +0 dB desde 0.00 s; Sonniss GDC 2020 «Monster1_Breathing3.wav» 0.05-0.9 s ×0.6 [lowpass=f=3000], -5 dB desde 0.05 s; Sonniss GDC 2016 «Grit,course,hardsurface,dropping,scatter,alt1.wav» 1.0-2.2 s ×1.0 [highpass=f=1200,lowpass=f=6500], -12 dB desde 0.10 s.
- **`fija.ogg`** (espacio común -16 dB): Sonniss GDC 2018 «Monster Bite 3.wav» 0.0-0.8 s ×0.75 [highpass=f=50,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2017 «Mouthy,chomping,crushing,ice,slush,wet,thick,opening.wav» 0.75-1.7 s ×0.8 [highpass=f=120,lowpass=f=5500], -7 dB desde 0.02 s; Sonniss GDC 2020 «Bluezone_BC0263_creature_crab_organic_texture_carapace_crack_squishy_003.wav» 0.0-0.45 s ×0.7 [lowpass=f=6500], -9 dB desde 0.00 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 1.0-1.6 s ×0.55 [lowpass=f=1500], -11 dB desde 0.05 s.
- **`latigazo.ogg`** (espacio común -17 dB): Sonniss GDC 2019 «MAGIC AIR Large Whoosh, Swirl, Wind Gust, Foliage 01.wav» 0.42-1.25 s ×0.62 [highpass=f=60,lowpass=f=5000], +0 dB desde 0.00 s; Sonniss GDC 2018 «Dragon Tail 1.wav» 0.0-0.7 s ×0.8 [lowpass=f=5000], -5 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.6 s ×0.9 [highpass=f=800,lowpass=f=6500], -10 dB desde 0.12 s.
- **`surco.ogg`** (espacio común -17 dB): Sonniss GDC 2020 «TackleHeavy 3_Movement_Scrape-Long.wav» 13.6-15.1 s ×0.8 [highpass=f=70], +0 dB desde 0.00 s; Sonniss GDC 2016 «rocks stream down heavy 02.wav» 1.6-2.9 s ×0.9 [highpass=f=250,lowpass=f=6500], -7 dB desde 0.05 s; Sonniss GDC 2016 «Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav» 2.0-3.4 s ×1.0 [highpass=f=1200,lowpass=f=6500], -12 dB desde 0.00 s.
- **`embestida_1.ogg`** (espacio común -15 dB): Sonniss GDC 2020 «PM_RI_Designed_7 Rocks Impact Hit Big LFE Heavy Designed.wav» 0.0-1.5 s ×0.85 [lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2019 «impact_gritty_grit_sandy_dirt_dig_shovel_shingle_roof_02.wav» 0.05-1.2 s ×0.8 [highpass=f=90,lowpass=f=6500], -4 dB desde 0.00 s; Sonniss GDC 2016 «Ice_chunk_heavy_07.wav» 0.0-0.9 s ×0.75 [lowpass=f=5500], -9 dB desde 0.01 s; Sonniss GDC 2016 «soil and dirt debris heavy 13.wav» 0.8-2.3 s ×0.9 [highpass=f=120,lowpass=f=6500], -10 dB desde 0.10 s; Sonniss GDC 2019 «Trailer Hit Cavernous 10 Filtered, Low End.wav» 0.0-2.0 s ×1.0, -7 dB desde 0.00 s.
- **`embestida_2.ogg`** (espacio común -15 dB): Sonniss GDC 2020 «PM_RI_Designed_19 Rocks Impact Hit Big LFE Heavy Designed.wav» 0.0-1.6 s ×0.8 [lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2017 «punch_grit_wet_impact_05.wav» 0.0-0.5 s ×0.8 [highpass=f=80,lowpass=f=4500], -5 dB desde 0.00 s; Sonniss GDC 2018 «Monster Bite 3.wav» 0.25-0.8 s ×0.7 [lowpass=f=6500], -10 dB desde 0.00 s; Sonniss GDC 2023 «Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_glass_010.wav» 0.05-1.4 s ×0.85 [highpass=f=250,lowpass=f=5500], -12 dB desde 0.06 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.85 [highpass=f=600,lowpass=f=6500], -9 dB desde 0.04 s; Sonniss GDC 2019 «Trailer Hit Cavernous 10 Filtered, Low End.wav» 0.0-2.0 s ×0.95, -7 dB desde 0.00 s.
- **`caida_aire.ogg`** (espacio común no): Sonniss GDC 2019 «MAGIC AIR Large Whoosh, Swirl, Wind Gust, Foliage 01.wav» 0.3-1.25 s ×0.55 [highpass=f=50,lowpass=f=4000] al revés, +0 dB desde 0.00 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.0-1.0 s ×1.0 [lowpass=f=120] al revés, -8 dB desde 0.00 s.
- **`fractura.ogg`** (espacio común -14 dB): Sonniss GDC 2017 «Iceberg,Designed,Impact,Crack,Shatter,Huge_08.wav» 2.95-8.9 s ×0.85 [highpass=f=45,equalizer=f=85:width_type=o:width=1.6:g=-8,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2019 «Explosive Hit 10 Filtered, Low End.wav» 0.4-1.52 s ×0.85, -9 dB desde 0.00 s; Sonniss GDC 2020 «PM_RI_Designed_19 Rocks Impact Hit Big LFE Heavy Designed.wav» 0.0-1.6 s ×0.8 [highpass=f=90,lowpass=f=6500], -2 dB desde 0.00 s; Sonniss GDC 2018 «boulder_impact_on_stones_14.wav» 0.0-1.0 s ×0.75 [highpass=f=120,lowpass=f=6500], -5 dB desde 0.00 s; Sonniss GDC 2024 «Bluezone_BC0292_alien_tripod_debris_rock_collapse_earthquake_rumble_large_005.wav» 0.3-4.4 s ×0.85 [highpass=f=50], -10 dB desde 0.05 s; Sonniss GDC 2023 «Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_glass_010.wav» 0.05-2.4 s ×0.8 [highpass=f=220,lowpass=f=6000], -7 dB desde 0.03 s; Sonniss GDC 2017 «Window,Small,Break,Medium Impact,Large Amount of Clinking Pieces.wav» 0.0-1.38 s ×0.8 [highpass=f=300,lowpass=f=6000], -10 dB desde 0.12 s.
- **`placas.ogg`** (espacio común -15 dB): Sonniss GDC 2019 «HERO - DESIGNED - TOMB Slide Open.wav» 0.0-2.6 s ×0.75 [highpass=f=130,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2017 «Ice,Impact,Large,Slide_18.wav» 0.42-2.2 s ×0.8 [highpass=f=80,lowpass=f=6000], -3 dB desde 0.00 s; Sonniss GDC 2017 «thick ice hits impacts debris bright 03.wav» 1.55-3.1 s ×0.85 [highpass=f=150,lowpass=f=5500], -8 dB desde 0.25 s; Sonniss GDC 2017 «Window,Small,Break,Medium Impact,Large Amount of Clinking Pieces.wav» 0.0-1.38 s ×0.75 [highpass=f=300,lowpass=f=5500], -10 dB desde 0.32 s; Sonniss GDC 2016 «rocks stream down heavy 02.wav» 2.5-4.6 s ×0.9 [highpass=f=220,lowpass=f=6500], -8 dB desde 0.30 s.
- **`placas_asientan.ogg`** (espacio común -16 dB): Sonniss GDC 2017 «Door - Stone Long 02.wav» 4.15-5.1 s ×0.7 [highpass=f=50], +0 dB desde 0.00 s; Sonniss GDC 2018 «dirt_collapse_05.wav» 0.35-1.6 s ×0.85 [highpass=f=70,lowpass=f=6500], -4 dB desde 0.05 s; Sonniss GDC 2017 «Ice,Block,Crack,Distant,Medium_03.wav» 0.62-1.5 s ×0.8 [highpass=f=200,lowpass=f=5000], -13 dB desde 0.10 s.
- **`succion.ogg`** (espacio común -15 dB): Sonniss GDC 2020 «HUMAN BREATH Male_Deep Mouth Inhale and Powerful Strong Exhale with Acceleration_A.wav» 0.22-0.95 s ×0.5 [highpass=f=60,lowpass=f=4500], +0 dB desde 0.00 s; Sonniss GDC 2019 «222400 - Dynamic Vacuum Suction 01 - Loop.wav» 0.45-2.1 s ×0.7 [highpass=f=80,lowpass=f=5000], -6 dB desde 0.00 s; Sonniss GDC 2019 «253203 - Drain Suction 03.wav» 0.0-1.7 s ×0.8 [lowpass=f=2500], -12 dB desde 0.40 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.75 [highpass=f=600,lowpass=f=6500] al revés, -11 dB desde 0.50 s; Sonniss GDC 2017 «Crystal, Glass, Red Wine, Tone, Rubbing, Musical_07.wav» 0.3-3.0 s ×0.45 [highpass=f=160,lowpass=f=2000], -17 dB desde 0.40 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 0.5-2.5 s ×0.5 [lowpass=f=1400], -12 dB desde 0.30 s.
- **`succion_bucle.ogg`** (espacio común -16 dB): Sonniss GDC 2019 «222300 - Dynamic Through Draft - Loop.wav» 2.0-7.725 s ×0.75 [highpass=f=70,lowpass=f=4500], +0 dB desde 0.00 s; Sonniss GDC 2019 «222400 - Dynamic Vacuum Suction 01 - Loop.wav» 20.0-25.35 s ×0.7 [highpass=f=80,lowpass=f=4500], -4 dB desde 0.00 s; Sonniss GDC 2018 «03 Wind_grass_ strong_hurricane blast 3.wav» 4.0-11.6 s ×1.0 [highpass=f=150,lowpass=f=3000], -9 dB desde 0.00 s; Sonniss GDC 2016 «Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav» 1.0-8.6 s ×1.0 [highpass=f=1200,lowpass=f=6500], -11 dB desde 0.00 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 0.3-4.1499999999999995 s ×0.5 [lowpass=f=1200], -12 dB desde 0.00 s.
- **`chorro.ogg`** (espacio común -14 dB): Sonniss GDC 2017 «Compressed Air 06 Hiss and Spurt.wav» 1.26-1.85 s ×0.8 [highpass=f=200,lowpass=f=6500], -5 dB desde 0.00 s; Sonniss GDC 2019 «166000 - Steam Blasts.wav» 4.35-6.2 s ×0.8 [highpass=f=120,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2018 «Monster Growls 4.wav» 5.0-6.4 s ×0.8 [lowpass=f=2800], -6 dB desde 0.02 s; Sonniss GDC 2020 «Dinosaur Growl 3_Mono.wav» 0.75-2.6 s ×0.85 [highpass=f=40,lowpass=f=6500], -9 dB desde 0.05 s; Sonniss GDC 2018 «03 Wind_grass_ strong_hurricane blast 3.wav» 40.0-42.6 s ×1.0 [highpass=f=90,lowpass=f=6500], -4 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,dropping,scatter,alt1.wav» 6.0-8.6 s ×1.0 [highpass=f=1300,lowpass=f=6500], -9 dB desde 0.05 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.9 [highpass=f=500,lowpass=f=6500], -8 dB desde 0.15 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.85 [highpass=f=500,lowpass=f=6500], -8 dB desde 0.40 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.8 [highpass=f=500,lowpass=f=6500], -8 dB desde 0.65 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.0-2.0 s ×1.0 [lowpass=f=110], -9 dB desde 0.00 s.
- **`alcanza_1.ogg`** (espacio común -18 dB): Sonniss GDC 2019 «impact_gritty_grit_sandy_dirt_dig_shovel_shingle_roof_02.wav» 0.06-0.7 s ×0.9 [highpass=f=150,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.95 [highpass=f=400,lowpass=f=6500], -3 dB desde 0.02 s.
- **`alcanza_2.ogg`** (espacio común -18 dB): Sonniss GDC 2017 «punch_grit_wet_impact_05.wav» 0.0-0.5 s ×0.85 [highpass=f=150,lowpass=f=4500], -3 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.85 [highpass=f=400,lowpass=f=6500], +0 dB desde 0.02 s.
- **`jadeo.ogg`** (espacio común -15 dB): Sonniss GDC 2020 «HUMAN BREATH Male_Mouth Inhale and Exhale Like Got Frightened Intermittent _C.wav» 5.6-7.1 s ×0.5 [highpass=f=110,lowpass=f=3500], +0 dB desde 0.00 s; Sonniss GDC 2018 «MONSTER Yeti breathe 05.wav» 0.0-2.0 s ×0.72 [highpass=f=90,lowpass=f=3500], -6 dB desde 0.10 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 2.0-4.0 s ×0.55 [lowpass=f=1300], -13 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,dropping,scatter,alt1.wav» 3.0-5.6 s ×1.0 [highpass=f=1400,lowpass=f=6500], -14 dB desde 0.30 s.
- **`atraganta.ogg`** (espacio común -15 dB): Sonniss GDC 2020 «Corroded Thorat_Mono.wav» 0.21-1.3 s ×0.65 [highpass=f=40,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2020 «Monster11_Mouth2.wav» 0.0-0.9 s ×0.7 [lowpass=f=6500], -5 dB desde 0.10 s; Sonniss GDC 2019 «253203 - Drain Suction 03.wav» 0.4-1.4 s ×0.7 [lowpass=f=2500], -11 dB desde 0.00 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.8 [highpass=f=500,lowpass=f=6500], -5 dB desde 0.35 s; Sonniss GDC 2016 «Grit,course,hardsurface,throw,scatter.wav» 0.0-0.67 s ×0.75 [highpass=f=500,lowpass=f=6500], -7 dB desde 0.75 s.
- **`herido_1.ogg`** (espacio común -16 dB): Sonniss GDC 2023 «MonsterPack2_Monster06_Attack13.wav» 0.18-1.1 s ×0.62 [highpass=f=40,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2017 «Ice,Block,Crack,Distant,Medium_03.wav» 0.65-1.1 s ×0.9 [highpass=f=200,lowpass=f=5000], -11 dB desde 0.02 s.
- **`herido_2.ogg`** (espacio común -16 dB): Sonniss GDC 2023 «MonsterPack2_LargeMonster11_Roar03.wav» 0.0-0.9 s ×0.58 [highpass=f=40,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2020 «Bluezone_BC0263_creature_crab_organic_texture_carapace_crack_squishy_003.wav» 0.0-0.5 s ×0.8 [lowpass=f=6500], -9 dB desde 0.00 s.
- **`herido_3.ogg`** (espacio común -16 dB): Sonniss GDC 2018 «MONSTER Yeti grumble 02.wav» 0.38-1.15 s ×0.7 [highpass=f=40,lowpass=f=4000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Corroded Thorat_Mono.wav» 0.15-0.9 s ×0.7 [highpass=f=40,lowpass=f=6500], -5 dB desde 0.00 s; Sonniss GDC 2016 «Ice_chunk_heavy_07.wav» 0.0-0.6 s ×0.8 [lowpass=f=5000], -13 dB desde 0.03 s.
- **`caida.ogg`** (espacio común -13 dB): Sonniss GDC 2023 «MonsterPack2_Monster09_Death02.wav» 0.1-3.3 s ×0.6 [highpass=f=40,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2018 «MONSTER Yeti groan 21.wav» 0.0-3.8 s ×0.7 [lowpass=f=2500], -9 dB desde 0.40 s; Sonniss GDC 2017 «Mouthy,growl,sustained,low,steady.wav» 1.0-4.8 s ×0.5 [lowpass=f=1300], -11 dB desde 0.20 s; Sonniss GDC 2017 «Crystal, Glass, Red Wine, Tone, Rubbing, Musical_07.wav» 0.3-4.6 s ×0.42 [highpass=f=150,lowpass=f=2000], -13 dB desde 0.60 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.0-3.2 s ×0.9 [lowpass=f=100], -11 dB desde 0.00 s.
- **`derrumbe.ogg`** (espacio común -14 dB): Sonniss GDC 2023 «DESTRClpse_Massive Wall Collapsing_JSE_SD.wav» 0.6-5.4 s ×0.85 [highpass=f=60,lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2019 «Explosive Hit 10 Filtered, Low End.wav» 0.4-1.52 s ×0.8, -9 dB desde 0.00 s; Sonniss GDC 2024 «Bluezone_BC0292_alien_tripod_debris_rock_collapse_earthquake_rumble_large_005.wav» 0.3-4.6 s ×0.85 [highpass=f=50], -10 dB desde 0.00 s; Sonniss GDC 2023 «Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_008.wav» 0.1-4.0 s ×0.85 [highpass=f=120,lowpass=f=6500], -5 dB desde 0.05 s; Sonniss GDC 2023 «Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_glass_010.wav» 0.05-2.4 s ×0.8 [highpass=f=220,lowpass=f=6000], -8 dB desde 0.15 s; Sonniss GDC 2016 «rock tumble down debris long 06.wav» 0.0-4.0 s ×0.85 [highpass=f=100,lowpass=f=6500], -6 dB desde 0.40 s; Sonniss GDC 2016 «Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav» 2.0-6.5 s ×1.0 [highpass=f=1300,lowpass=f=6500], -14 dB desde 1.40 s.

### 2.2 Originales usados (biblioteca del usuario, solo lectura) y su SHA-256

| Paquete (licencia) | Carpeta / archivo | SHA-256 |
|---|---|---|
| Sonniss GDC 2016 | Alexander Kopeikin - Rocks/rock tumble down debris long 06.wav | `118965f8855561fd6d5c89eaa3f9204f2c487dfba3e8638500df4326a5b182c4` |
| Sonniss GDC 2016 | Alexander Kopeikin - Rocks/rocks stream down heavy 02.wav | `35c3074eab1c31f97c08034c1ccb7782ac8d196eb3b663f65b5aca91208e3993` |
| Sonniss GDC 2016 | Alexander Kopeikin - Rocks/soil and dirt debris heavy 13.wav | `0086b00ddff0f4f2ce0e8e6892381b07722c37b9109a9d3f127f53341a26e5e4` |
| Sonniss GDC 2016 | Eiravaein Sound - Grit/Grit,course,hardsurface,dropping,scatter,alt1.wav | `706cc6e3cd43152361f3094dee972171b05a6bff91b235a633be995d6f607854` |
| Sonniss GDC 2016 | Eiravaein Sound - Grit/Grit,course,hardsurface,throw,scatter.wav | `75dc3bae91eb931b922db93c547f638af251659388ca412bc3740e54c17d2f29` |
| Sonniss GDC 2016 | Eiravaein Sound - Grit/Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav | `f47f250739d23be482161919a3cec28e82ec8be3d3248f50e7d647c07b896f07` |
| Sonniss GDC 2016 | Stuart Duffield - Ice SFX/Ice_chunk_heavy_07.wav | `d0058efb434e02b1b0225e6a460de62ffb3b59c125a8bf328391b568c27bd4de` |
| Sonniss GDC 2017 | Chris Skyes - Shards Broken Glass/Window,Small,Break,Medium Impact,Large Amount of Clinking Pieces.wav | `c2552ae7d0988bc1e8ac8cc9ce5d2081ec43a371cb1242f2788aadde95700909` |
| Sonniss GDC 2017 | Eiravaein Sound - Mouthy/Mouthy,chomping,crushing,ice,slush,wet,thick,opening.wav | `7b858119a829e8f77688a7fea79551eaafa69ceb565c6075b856bb635521f261` |
| Sonniss GDC 2017 | Eiravaein Sound - Mouthy/Mouthy,growl,sustained,low,steady.wav | `27efa2683cd421d34966b05b522d9f44ccfa4c1ed93b39b202072147950a0b9b` |
| Sonniss GDC 2017 | Fascinated Sound - Scene Shop Tool Box/Compressed Air 06 Hiss and Spurt.wav | `baf02c605b71c2be8f8ec8af10dbcc4b4263d2ba4af44fbb53ac543bfbcfd9c5` |
| Sonniss GDC 2017 | Gamemaster Audio -  Punch Sound Pack/punch_grit_wet_impact_05.wav | `5eccd69abba716a195e81b9c0a5eafe31d599688afc892dd4f8737528aac469b` |
| Sonniss GDC 2017 | Mattia Cellotto - Glacier Ice/Ice,Block,Crack,Distant,Medium_03.wav | `debc6440e8446d8bee003fb71ac70a605cfb6058acda528f9307378195559761` |
| Sonniss GDC 2017 | Mattia Cellotto - Glacier Ice/Ice,Impact,Large,Slide_18.wav | `6ae4fc2330d1ae9b55929c65c5a9f9616908c17b39c48d4550eaeebd672fd9eb` |
| Sonniss GDC 2017 | Mattia Cellotto - Glacier Ice/Iceberg,Designed,Impact,Crack,Shatter,Huge_08.wav | `18ecd92ccf35d6729a1352f9387492a88fa9c91c825a816b97d7d9c3c4c43fee` |
| Sonniss GDC 2017 | Mindful Audio - Elements - Ice/thick ice hits impacts debris bright 03.wav | `c427cbc6b47f38754d60768f8f692338064613e8374429637a72faf3cbc27526` |
| Sonniss GDC 2017 | Raconteur Sound - Crystal Glasses- Tones and Drones_/Crystal, Glass, Red Wine, Tone, Rubbing, Musical_07.wav | `7bd7f8f262ed9fb5ae198abddc3e4d3324eca814b506cc342465fea6387a4faa` |
| Sonniss GDC 2017 | SoundMorph - Portals/Door - Stone Long 02.wav | `a36fc49a409317433143cc173064d5134e554e1aa9af3dc42616b5477a641ca7` |
| Sonniss GDC 2018 | Articulated Sounds - Yeti Monster/MONSTER Yeti breathe 05.wav | `38cad17bbd899b19d714b70256dc63ced6a914a3cf791c5de05488585a89770e` |
| Sonniss GDC 2018 | Articulated Sounds - Yeti Monster/MONSTER Yeti groan 21.wav | `3f823b6795fa06cd481fe461ebd7b606402a6a8740927d66e225c852fc765ef4` |
| Sonniss GDC 2018 | Articulated Sounds - Yeti Monster/MONSTER Yeti grumble 02.wav | `e5bf5e2989901ab6e54f0ea6f3373ab71d49f840220ef186c536c25fdd53e10f` |
| Sonniss GDC 2018 | Ivo Vicic - Bora wind - European local wind/03 Wind_grass_ strong_hurricane blast 3.wav | `8ca1048fa7844629cab43a6b4691a44eed610df5753fc2e83c61b0638e9eed1c` |
| Sonniss GDC 2018 | Olivier Girardot - Monsters/Dragon Tail 1.wav | `bff1e076dea0c298bade63ec0be7324b6761fc7ce0b0fe1d324751371e199267` |
| Sonniss GDC 2018 | Olivier Girardot - Monsters/Monster Bite 3.wav | `7193d1d8f9e4d76e383f1b80570244a74101b46c5da04efa27b620843c8c6e78` |
| Sonniss GDC 2018 | Olivier Girardot - Monsters/Monster Growls 4.wav | `94e47f779de1e11ce1252c4aaaf1491de5d927f8ca164d3ffc8741f116d5cff7` |
| Sonniss GDC 2018 | Soundrangers - Foley Elements Rocks, Dirt And Stone/boulder_impact_on_stones_14.wav | `193834e5c5ccb5c9d349480c91ab34151427bf46d4a890920c5a0bb85a669d94` |
| Sonniss GDC 2018 | Soundrangers - Foley Elements Rocks, Dirt And Stone/dirt_collapse_05.wav | `f6dfa52e71067a03136695d16ad8bdfa5acf3d7b4d15f511a76ec7f269fd95c9` |
| Sonniss GDC 2019 | 344 Audio - Low Frequency Elements/Explosive Hit 10 Filtered, Low End.wav | `e3de91cec5d11b68854ecb15c939515f1fa6b3223a4ec30c1f3e37003b87eeed` |
| Sonniss GDC 2019 | 344 Audio - Low Frequency Elements/Trailer Hit Cavernous 10 Filtered, Low End.wav | `028d02d2e983afecf95cb8c91259423f91b4dd089a5fd3e23972bc6ccabdc58d` |
| Sonniss GDC 2019 | Articulated Sounds - Magic Elements vol.1/MAGIC AIR Large Whoosh, Swirl, Wind Gust, Foliage 01.wav | `b043bd250f27486880fbfa65435cc75b1f201dfccbb0b2ddb4e85c451038e64f` |
| Sonniss GDC 2019 | Matt Script - You Me & Debris/impact_gritty_grit_sandy_dirt_dig_shovel_shingle_roof_02.wav | `fd59551b49d2af7b9f35c2ac90a7ad616ce063e4b15980cd85656584d280af3f` |
| Sonniss GDC 2019 | Rock The Speakerbox - Hero/HERO - DESIGNED - TOMB Slide Open.wav | `d4cfabc84375d8b0c47d9082dd8f6807e73dbb51b7bf0e85e278fb778c46fbc2` |
| Sonniss GDC 2019 | The Sound Pack Tree - This Library Sucks/222300 - Dynamic Through Draft - Loop.wav | `2744d3ef10be86a902e9e28055369e64d841f1b92079b8be480fa6c0fdb63791` |
| Sonniss GDC 2019 | The Sound Pack Tree - This Library Sucks/222400 - Dynamic Vacuum Suction 01 - Loop.wav | `198a300c554b96432755cbe7fa8cf1af4b338932114545c6820f0510c6519d64` |
| Sonniss GDC 2019 | The Sound Pack Tree - This Library Sucks/253203 - Drain Suction 03.wav | `68e7e3288545315eb0520b5a98454db1f8f458cb5693bcec8138f00686ec316a` |
| Sonniss GDC 2019 | The Sound Pack Tree - Trains/166000 - Steam Blasts.wav | `504b53f101363c43c52d26a9bba3325651cc4982d8a4a0bda3a50dba226f6a27` |
| Sonniss GDC 2020 | 344 Audio - Trailer Instruments Designed/Sub Drop 2.wav | `7ab8a270e86e050fbf17265f520a609a61fc18d8dae3ffddb9aeda18490cc456` |
| Sonniss GDC 2020 | Articulated Sounds - Human Male Breathe/HUMAN BREATH Male_Deep Mouth Inhale and Powerful Strong Exhale with Acceleration_A.wav | `f38f5f59fa9abd51051638a4b46fd3978edee7232580285a11f7f71032e21372` |
| Sonniss GDC 2020 | Articulated Sounds - Human Male Breathe/HUMAN BREATH Male_Mouth Inhale and Exhale Like Got Frightened Intermittent _C.wav | `02ac777f8817e108a34ae4f93968c7c299b4dc98ba3b2abc48d395441845a5db` |
| Sonniss GDC 2020 | Audiomeals - Dark Creature Sounds/Corroded Thorat_Mono.wav | `43c2088c9a0eafb2803e4cd4590204e880098ded2b89e06dbb4448da47aa3e58` |
| Sonniss GDC 2020 | Audiomeals - Dark Creature Sounds/Dinosaur Growl 3_Mono.wav | `136348bf5ff57d3ce4c63f48a7266a3fe1753c5e00905f567d5f9b9b316ff688` |
| Sonniss GDC 2020 | Bluezone - Crab - Creature/Bluezone_BC0263_creature_crab_organic_texture_carapace_crack_squishy_003.wav | `b980ceef316938337b95cdf9b35ee0ff5802db7c1ee8d129df254fc80961e183` |
| Sonniss GDC 2020 | David Dumais Audio - Monster Sound FX Pack 1/Monster11_Mouth2.wav | `7265ca9afe267c21358c9471b1a00c3c0b5a9147ecf3cad0fa494b13087edccf` |
| Sonniss GDC 2020 | David Dumais Audio - Monster Sound FX Pack 1/Monster1_Breathing3.wav | `454ecc177aac40b5a51bb7073f4a6a932d0f9b6647f087375f5b2f86ddcf92e1` |
| Sonniss GDC 2020 | Joshua Reinhardt - Ultimate Creature Footstep and Movement Library/TackleHeavy 3_Movement_Scrape-Long.wav | `bd43f3d350ce5eec26ca25b7c92c2534095dbb8dfd53ee20335308c982ac27aa` |
| Sonniss GDC 2020 | PMSFX - Rocky Impacts/PM_RI_Designed_19 Rocks Impact Hit Big LFE Heavy Designed.wav | `fbe1ae1f569cbdc85bcc66d20088a5b2661c0a9431d29b62abccebc6fe58ef3f` |
| Sonniss GDC 2020 | PMSFX - Rocky Impacts/PM_RI_Designed_7 Rocks Impact Hit Big LFE Heavy Designed.wav | `d3325b81a3e21e1f722c9ac245459a24cef8dcdb3eacd33f54801a90cfb86fe2` |
| Sonniss GDC 2023 | BluezoneCorp - Building Collapse/Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_008.wav | `e3a14f492863eeb1304cb795de394af496473c1438383cf8165afb974c29b7ee` |
| Sonniss GDC 2023 | BluezoneCorp - Building Collapse/Bluezone_BC0275_building_collapse_debris_falling_rock_rubble_glass_010.wav | `783b44977bbfef028d05e633ce9bfa91eae8b7e12433358bbc4b228b841791af` |
| Sonniss GDC 2023 | David Dumais Audio - Monster Sound FX Pack 2/MonsterPack2_LargeMonster11_Roar03.wav | `4bfe1aba3f0332a2fe8c02792d4f0d44d4df7fb10f109dbecd561ba39422def8` |
| Sonniss GDC 2023 | David Dumais Audio - Monster Sound FX Pack 2/MonsterPack2_Monster06_Attack13.wav | `cca9a928204611ea6a86a8a1c33012d52054a667410e9d81457a2b94333875ae` |
| Sonniss GDC 2023 | David Dumais Audio - Monster Sound FX Pack 2/MonsterPack2_Monster09_Death02.wav | `ee58372904f2e17f2b335951592e699157982aba37479263be35fdd2ff1a07e2` |
| Sonniss GDC 2023 | Justsoundeffects - Stones and Debris/DESTRClpse_Massive Wall Collapsing_JSE_SD.wav | `fac97cf248f5a1eacffe270ba902ecff2ae45c72dd516c3c88019879455a9460` |
| Sonniss GDC 2023 | Justsoundeffects - Stones and Debris/DIRTCrsh_Stone Sand Trickle Reverberant 01_JSE_SD.wav | `8ef3ffba582adfae71b1992ccdf4fec5252c580e90785dfab7355359e319e341` |
| Sonniss GDC 2024 | BluezoneCorp - Alien Tripod/Bluezone_BC0292_alien_tripod_debris_rock_collapse_earthquake_rumble_large_005.wav | `78a08c9aafd139c50b887e2b81d40006498019b270bf776a28f578625376cc19` |

**Cómo se hicieron:** `crear_brama.py` + `motor.py` (Python 3.10 de la biblioteca estándar, con `-I`) y el
`ffmpeg.exe` 4.4.1 que ya estaba en el PC (Stremio) para leer, remuestrear, filtrar, convolucionar (`afir`) y codificar
(libvorbis q4 los largos, q5 los cortos). Nada instalado. Cada capa se normaliza a pico 0 y entra con su peso; mezcla,
espacio común, recorte de la cola, nivel por LUFS momentáneo y limitador con anticipación a −1 dBFS (lo que recorta,
`limitado_db` en `procedencia.json`: 0-4 dB, solo en transitorios). Scripts, procedencia completa (capas, tramos, tonos,
filtros, pesos, SHA-256) y la respuesta al impulso: `D:\REBELUM_diagnostico\sonido\2026-11-12_bramavidrio\herramientas\`.

## 3. Código

### 3.1 `aethelgard/sonido.gd` (solo se añade; 4 líneas cambiadas)

- `EFECTOS_BRAMAVIDRIO` (20 claves, el formato de `EFECTOS_DESIERTO` con `dir`/`ext`; `en_bucle` en el bucle de la
  succión), `BRAMA`, `BRAMAVIDRIO_IDENTIDAD := true` y `identidad_bramavidrio()` (estática: manda
  `-- bramavidrio_sonido=anterior|propio`, luego `Engine.set_meta("bramavidrio_sonido", …)`, luego la constante).
- `definicion()` busca también en `EFECTOS_BRAMAVIDRIO` (para las claves de siempre, nada cambia).
- `familia()`: `bramavidrio` → «brama» con la identidad propia (si no, «piedra», como antes). `voz()` busca la voz con
  `_hay_voz()` (EFECTOS o EFECTOS_BRAMAVIDRIO) en las dos líneas donde miraba `EFECTOS.has`.
- Por qué aparte de `EFECTOS`: `prueba_efectos` exige WAV QOA mono en `audio/efectos/` para todo `EFECTOS`.

| Clave | dB · prioridad · máx · espera | Notas |
|---|---|---|
| `brama_rugido` (2) | −3 · p3 · 1 · 2,0 s · tono ±3 % | |
| `brama_herido` (3) | −9 · p2 · 1 · 0,25 s · ±5 % | grupo «voz» (como las voces de siempre) |
| `brama_caida` | −5 · p3 · 1 · 0,5 s | grupo «voz» |
| `brama_jadeo` | −6 · p2 · 1 · 1,0 s · ±3 % | |
| `brama_atraganta` | −7 · p3 · 1 · 1,0 s | |
| `brama_emerge` · `brama_derrumbe` | −5 / −4 · p3 · 1 · 1,0 s | |
| `brama_recoge` · `brama_fija` · `brama_latigazo` | −10 / −9 / −9 · p2 · 1 · 0,4-0,5 s · ±3-4 % | |
| `brama_surco` | −5 · p2 · 1 · 0,5 s · ±4 % | (archivo por RMS: Mmax −17) |
| `brama_embestida` (2) | −7 · p3 · 1 · 0,5 s · ±3 % | |
| `brama_caida_aire` | −9 · p2 · 1 · 1,0 s | |
| `brama_fractura` | −3 · p3 · 1 · 1,0 s | |
| `brama_placas` · `brama_placas_asientan` | −7 / −10 · p3 / p2 · 1 · 1,0 s | |
| `brama_succion` | −4 · p3 · 1 · 1,0 s | |
| `brama_succion_bucle` | −7 · p2 · 1 · 0,2 s · `en_bucle` | con `{"en": nodo de Bramavidrio}`: reproductor propio que muere con el combate; lo corta `Sonido.cortar(…, 0.3)` |
| `brama_chorro` | −3 · p3 · 1 · 1,0 s | |
| `brama_arena_alcanza` (2) | −3 · p2 · 2 · 0,12 s · ±6 % | (archivos por RMS: Mmax −20/−17,5) |

Prioridades como el resto del juego: nada de Bramavidrio es p4 (una victoria o un «jefe» siguen bajando lo de menos
prioridad); los grandes momentos son p3, como los eventos; los detalles, p2, como los golpes.

### 3.2 `aethelgard/combate_bramavidrio.gd` (solo llamadas de sonido)

`SONIDOS` (evento → [identidad propia, lo de antes]), `BUCLE_SUCCION`, `sonido(evento)` (estática) y `_son(evento)`,
que hace lo mismo que `combate.gd _sonar` (emite `sonido_pedido`, para las pruebas, y pide `Sonido.efecto`). Los 11
`c._sonar("gusano_…")` de antes pasan a `_son(…)` (con la identidad apagada piden exactamente lo mismo que antes) y se
añaden `_son` en los instantes que ya existían: `_anticipacion_embestida`, `_fija_embestida`, `_lanza_embestida`,
`_deslizar`, `_sombra_caida`, `_placas_suelo`, `_placas_asientan`, `_alcanzar`, `cortar` y el turno «recupera»; el bucle
de la succión empieza en `_empezar_succion` y se corta en `_parar_succion`. **No cambian** efectos, daños, IA, turnos
ni instantes.

### 3.3 Cómo volver a lo de antes (sin borrar nada)

- En el juego por defecto: `sonido.gd`, `BRAMAVIDRIO_IDENTIDAD := false`.
- En una prueba o un arranque: `-- bramavidrio_sonido=anterior` (o `Engine.set_meta("bramavidrio_sonido", "anterior")`).
- Con la identidad apagada suenan los `gusano_temblor`/`gusano_rugido` en los mismos sitios que antes y la voz de piedra;
  lo comprueba `prueba_audio_bramavidrio` (C, «anterior») y `prueba_bramavidrio_combate` con `bramavidrio_sonido=anterior`.
- Quitarlo del todo: revertir los commits de `combate_bramavidrio.gd` y `sonido.gd` (apartado 6); los OGG pueden quedarse.

### 3.4 `pruebas/prueba_bramavidrio_combate.gd` (no es mío: seis líneas, commit aparte)

Comprobaba los nombres `gusano_temblor`/`gusano_rugido` en cada impacto. Ahora pregunta el nombre a
`B.sonido("embestida" | "rugido" | "succion" | "fractura" | "chorro")`: la misma comprobación (una vez, en el fotograma
del impacto) para la identidad que esté elegida. Lo pedía el informe del combate («habría que actualizar los recuentos de
sonidos de la prueba»). Si el coordinador prefiere no tocarla, sin ese commit la prueba falla con la identidad propia.


## 4. Verificación

### 4.1 Señal (medida con ffmpeg sobre los OGG y con Godot, `mix_audio`, en la prueba)

- Ningún pico por encima de −0,7 dBFS (Godot: ≤ −0,8); ninguno mudo; los no-bucle callan tras su final (<−70 dBFS) y
  el bucle sigue al dar la vuelta (costura 0,34; mismo nivel al final que al principio).
- Arranque (primer bloque de 20 ms a ≤12 dB del más fuerte, medido por Godot): golpes, voces y la Fractura en 0,00-0,10
  s; el rugido llega a su pico a 0,56 s (variante 1) y 0,90 s (2): sale con `rugido_pico`, ya arriba; la caída de la
  Fractura (`caida_aire`) crece hasta el final (0,43 s después llega el golpe).

### 4.2 Mezclas de prueba (SIMULADAS fuera del motor)

`D:\REBELUM_diagnostico\sonido\2026-11-12_bramavidrio\montajes\`: un combate de 56 s con sus sonidos en orden (entrada,
Embestida contra Lya con avance, golpes de los héroes y su voz, aviso y Fractura, Embestida 2, aviso del Aliento con el
bucle mientras le golpean, el chorro y su barrido, jadeo, golpe final, caída, derrumbe y victoria), con los OGG/WAV del
juego al volumen del catálogo; la música del combate a −6 dB que pasa al clímax (−7 dB) a los 44 s, con el «apartar la
música» de `sonido.gd` emulado (compresor con la entrada de Efectos: −30 dB, 2:1, 30/800 ms) y el limitador del Master a
−1 dBFS. `01`/`02`: identidad propia sin y con música; `03`/`04`: lo de antes, la misma línea de tiempo. Medidas en
`montajes_medidas.json` (LUFS momentáneo máximo en 1,2 s desde cada momento):

| Momento | Propia: efectos / música apartada / diferencia | Antes: diferencia |
|---|---|---|
| Entrada (rompe la arena) | −15,0 / −22,6 / **+7,6** | −4,7 |
| Entrada: rugido | −13,1 / −27,6 / **+14,5** | +4,7 |
| Embestida: impacto | −14,7 / −24,4 / **+9,7** | −4,6 |
| Aviso de la Fractura: rugido | −15,4 / −25,6 / **+10,2** | −1,4 |
| Fractura: impacto, placas y golpe a todos | −13,4 / −26,4 / **+13,0** | +0,6 |
| Fractura: se asientan | −15,9 / −25,4 / +9,5 | — |
| Aviso del Aliento: aspira | −14,7 / −19,2 / +4,5 | +2,3 |
| Le golpean mientras aspira (con el bucle) | −19,3 / −23,2 / +3,9 | +4,8 |
| Aliento: el chorro | −14,3 / −26,5 / **+12,2** | +3,2 |
| Jadea | −19,0 / −23,0 / +4,0 | — |
| Su voz al caer | −17,8 / −28,3 / +10,5 | +5,7 |
| Se desploma | −14,6 / −28,5 / **+13,9** | −3,8 |
| Victoria (la de siempre) | −14,9 / −27,5 / +12,6 | +10,6 |

- **No se tapan con la música** (con el clímax tampoco: los cinco últimos momentos van sobre él): los grandes momentos
  quedan 10-14 dB por encima de la música ya apartada; lo de antes quedaba entre −4,7 y +5,7 dB.
- **No saturan:** pico de la suma antes del limitador del Master −1,2 dBFS sin música y −1,5 con música (el limitador casi
  no trabaja); lo de antes, −5,9 / −4,7.
- **A la vez:** como mucho 8 efectos (en el impacto de la Embestida, con las colas de recoge/fija/latigazo/surco, el
  golpe y la voz de Lya); en la Fractura, 5. Hay 10 reproductores de Efectos (y el bucle va en uno propio).
- Ajustado con esto: `brama_jadeo` −8 → −6 y `brama_succion` −6 → −4 (quedaban a +1,8 y +3,1 dB de la música; el aviso
  del Aliento es la señal para cortarlo).

### 4.3 Pruebas (aisladas, `ejecutar_pruebas.ps1`, sin ventana, `--fixed-fps 30`)

**`prueba_audio_bramavidrio`** (nueva, `auto`, muda; 300 s de límite, tarda ~6 s). A: las 20 claves y sus 25 OGG
(carga, duración, bucle solo el de la succión, presupuesto 1 300 KB: hay 1 043; su fila en este informe; nada de Suno;
`SONIDOS` solo nombra claves que existen). B: la señal decodificada por Godot (ni muda ni saturada, el bucle da la vuelta,
lo demás calla, los golpes arrancan en ≤0,15 s, el rugido arriba en el primer segundo, la caída crece hasta el golpe).
C: en un combate de verdad del grupo 13, con la identidad propia y con la de antes, la entrada, la Embestida, el aviso y
la Fractura, el aviso y el Aliento, el corte, el jadeo, su voz y el derrumbe: cada sonido una vez, en su instante **del
clip** (el aviso y el ataque son el mismo clip), por Efectos, sin descartes y sin nada de la otra identidad.

Instantes medidos en el clip (v2 y v1 dan lo mismo; tolerancia 0,12 s): recoge 0,233 (0,2) · fija 0,567 (0,55) ·
latigazo 0,833 (0,8) · embestida 1,000 (1,0) · rugido 1,233 (1,25) · caída 2,100 (2,1) · fractura 2,533 · placas 2,533 ·
asientan 3,133 (3,1) · succión y su bucle 0,467 (0,45) · el bucle calla a 1,72 (fin_succion 1,7) · chorro 1,850 (1,85).
Con lo de antes, el chorro (`gusano_rugido`) a 1,833. Variantes de su voz: cuatro quejidos seguidos usan ≥2 archivos.

**Resultados** (todas: partida real, carpeta real de datos y proyecto sin cambios):

| Pasada | Pruebas | Resultado | Resumen |
|---|---|---|---|
| v2 (`bramavidrio_version=2`) | `prueba_audio`, `prueba_bramavidrio_combate`, `prueba_climax_jefe` | **3 SUPERADAS** | `D:\REBELUM_diagnostico\pruebas\2026-11-11_224945\resumen.md` (*) |
| v1 (`bramavidrio_version=1`) | las mismas tres | **3 SUPERADAS** | `D:\REBELUM_diagnostico\pruebas\2026-11-11_225056\resumen.md` |
| nueva, v2 y v1, y el combate con lo de antes | `prueba_audio_bramavidrio` ×2, `prueba_bramavidrio_combate` con `bramavidrio_version=2 bramavidrio_sonido=anterior` | **3 SUPERADAS** | `D:\REBELUM_diagnostico\pruebas\2026-11-11_225406\resumen.md` |
| regresión de sonido y del jefe | `prueba_efectos`, `prueba_audio_memoria`, `prueba_audio_guardian`, `prueba_audio_desierto`, `prueba_audio_bramavidrio`, `prueba_combate_huella`, `prueba_integridad`, `prueba_mar_cristal`, `prueba_bramavidrio_modelo` | **9 SUPERADAS** | `D:\REBELUM_diagnostico\pruebas\2026-11-11_225517\resumen.md` |

(*) En esa pasada la carpeta real de datos tuvo un archivo nuevo, `.recovery_mode_lock` (22:50:40), con 8 Godot de otros
especialistas abiertos sobre otras copias (dos importaciones con `--path .` sin aislar y capturas con ventana): no viene
de mis pruebas (van con APPDATA aislada y la sonda lo confirma); la partida real no cambió. Las otras tres pasadas: sin
cambios.

`prueba_audio_memoria`: `audio/bramavidrio` 25 sonidos · 0,00 MB de RAM de datos (los OGG van en streaming) · 1,08 MB en
el paquete.

Importación aislada antes de probar (`--headless --path aethelgard --import`): la primera vació los directorios de
Dialogic de `project.godot` (lo avisó el encargo): `git restore aethelgard/project.godot` y otra importación, ya limpia.

## 5. Límites (lo que no está comprobado)

- **No se ha escuchado nada:** ni si el rugido suena colosal o a dinosaurio de película, ni si el vidrio se reconoce,
  ni si el bucle de la succión cansa en un aviso largo, ni el timbre en el altavoz del Redmi. Muestras para escuchar en
  `D:\REBELUM_diagnostico\sonido\2026-11-12_bramavidrio\indice.md`.
- Las mezclas son simuladas (la compresión que aparta la música está emulada, no es la de Godot).
- Sin ventana, el controlador de audio de prueba de Godot no avanza la reproducción (medido: «jefe» a 0,09 s tras ~2 s):
  lo que suena no acaba y los reproductores se llenan. Por eso la prueba para los reproductores entre un paso y otro, y
  el límite de voces se ha medido en la simulación (8 de 10 como mucho), no en el motor.
- Nada en el Redmi: ni nivel real, ni coste de decodificar varios OGG estéreo a la vez (como mucho ~6 de Bramavidrio
  juntos más el bucle). No he medido rendimiento (otros especialistas trabajando).
- La exploración (`zonas3d/mar_cristal/gusano.gd`: desplazamiento bajo la arena y emerger) no la he tocado: sigue con
  `gusano_temblor` y `gusano_rugido` (apartado 7).
- Las dos variantes de `brama_arena_alcanza` difieren 2,7 dB en el juego (−23,2 / −20,5): poco, pero se nota si se escucha
  con atención.

## 6. Commits y archivos para integrar copiando

| Commit | Qué |
|---|---|
| `0513ba9` | `aethelgard/audio/bramavidrio/`: los 25 OGG y sus `.import` (el bucle con `loop=true`) |
| `f2811df` | `aethelgard/sonido.gd`: `EFECTOS_BRAMAVIDRIO`, interruptor, voz «brama» |
| `d371c69` | `aethelgard/combate_bramavidrio.gd`: `SONIDOS`, `_son()` y las llamadas en sus instantes |
| `dcd2571` | `aethelgard/pruebas/prueba_audio_bramavidrio.gd` (+ `.uid`) y su línea en `lista_pruebas.txt` |
| `6f067e3` | `aethelgard/pruebas/prueba_bramavidrio_combate.gd` (3.4; no es del área de sonido) |
| (este) | este informe |

Para integrar copiando: `aethelgard/audio/bramavidrio/` (25 `.ogg` y sus 25 `.ogg.import`; el de `succion_bucle` con
`loop=true`), `aethelgard/sonido.gd`, `aethelgard/combate_bramavidrio.gd`, `aethelgard/pruebas/prueba_audio_bramavidrio.gd`
y su `.uid`, `aethelgard/pruebas/lista_pruebas.txt` (una línea), `aethelgard/pruebas/prueba_bramavidrio_combate.gd`
(3.4) y este informe. Si `sonido.gd` o `combate_bramavidrio.gd` han cambiado en la V12 mientras tanto, los bloques son
los marcados «V12 (12/11)» / «V12, sonido».

## 7. Siguiente paso y peticiones

1. **Escuchar** (usuario/coordinador): `indice.md` de las muestras; sobre todo `02_propio_con_musica_y_climax.ogg` frente
   a `04_antes_con_musica_y_climax.ogg`, y en el Redmi.
2. **Exploración** (`zonas3d/mar_cristal/gusano.gd`, no es mío esta noche): si se quiere la misma voz fuera del combate,
   cambiar sus `Sonido.efecto("gusano_rugido", …)` por `"brama_rugido"` y su emersión por `"brama_emerge"` con la misma
   `pos` (con `en_3d` en el catálogo: hoy no lo llevan; añadir `"en_3d": {"unidad": 12.0, "max": 90.0, "filtro": -18.0}`
   a las dos) y el avance bajo la arena con `"brama_surco"`; o dejarlo como está (el gusano lejano y el de cerca).
3. **Inventario común:** copiar las tablas de los apartados 1 y 2 a `docs/audio/inventario_sonidos.md` (sección V12) y
   una fila por derivado en `docs/audio/efectos_procedencia.csv` y `docs/recursos.md` (no eran mis archivos).
4. Si al escucharlo algo cansa o tapa: el nivel se cambia en el «db» del catálogo; el timbre, en la receta de
   `crear_brama.py` (cada capa, su tramo y su peso) y se rehace en un minuto.
