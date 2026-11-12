# Sonido · V12, magia negra de Naira (seis escuelas, avanzados, preparar y rotura)

## 12/11/2026, 03:00 · rama `claude/v12-fase2-sonido-magia` (LOCAL, nace de `claude/rebelum-v12` @ `daa7dfb`)

Especialista de sonido, en `D:\Aethelgard_v12_sonido_magia`. Sin push ni merge. Archivos míos:
`aethelgard/audio/magia_negra/*` (20 OGG y sus `.import`), `EFECTOS_MAGIA_NEGRA` y `definicion()` de
`aethelgard/sonido.gd`, `aethelgard/pruebas/prueba_audio_magia_negra.gd` (y su línea en `pruebas/lista_pruebas.txt`) y
este informe; además, **dos líneas** de `aethelgard/combate.gd` (apartado 3.2, en su propio commit) sin las que el
combate no ve las claves nuevas.

**No he podido escuchar nada.** Todo lo que sigue está medido (pico, RMS, LUFS, bandas, duración, arranque, nivel frente
a la música) con herramientas reales, no oído. Los montajes son **simulados** fuera del motor. Nadie lo ha jugado: la
magia negra sigue apagada (interruptor `magia_negra_v12`), así que en el juego normal no suena nada de esto todavía.

### 1. La identidad

Encargo: una identidad sonora para cada escuela, los avanzados más grandes y distintos (no los mismos más fuertes),
coherente con el estilo fantástico de REBELUM y sin estridencias. La magia de Naira «tapa y pesa» (no borra). Lo que
comparten todos sus sonidos, para que se reconozcan como una sola magia:

1. **Firma:** en la cola de cada hechizo, una resonancia oscura de cristal frotado una octava por debajo (Raconteur
   Sound, «Tall Narrow… _05», ×0,5) sobre un dron grave (Raconteur, «Drone, Dark, Eerie_08»): la luz tapada. Más
   presente en Sombras, preparar y la Noche Absoluta; al fondo en lo demás. Es otro vaso y otro tono que la firma de
   Bramavidrio («Red Wine… _07»), para no confundirlas.
2. **Espacio común:** una sala arcana sintética, más larga y oscura que el desierto de Bramavidrio (ruido decorrelado,
   caída de 2,4 s, 25 ms de retardo, paso bajo 3,2-4 kHz, paso alto 140 Hz), a −15/−17 dB en las escuelas y −12/−13 en
   los avanzados.
3. **Nada estridente:** cada capa brillante pasa por un paso bajo de 4-6,5 kHz y casi todas van remuestreadas a ×0,7-0,9
   (más graves y lentas). Agudos (>2,5 kHz) a −8/−22 dB del total. Como el altavoz del móvil casi no da nada por debajo
   de ~250 Hz, una ecualización final quita el sobrante de graves (`highpass=f=45,bass=g=-6:f=120`): la banda <120 Hz
   queda a −7/−20 dB y los medios (120-2 500 Hz) mandan (−2/−7 dB). (La primera pasada tenía <120 Hz a −1/−2 dB en
   fuego, gravedad, Sol de Ceniza y Colapso: se corrigió antes de integrar.)
4. **Nivel común:** todos los archivos con el mismo LUFS momentáneo máximo (−12 ±0,4); el «db» del catálogo decide su
   papel en la mezcla.

| Escuela | Materia (qué la distingue) | Capas principales |
|---|---|---|
| Fuego | una brasa que prende de golpe y crepita al apagarse | hechizo de fuego y explosión mágica cortos, ráfaga de llama diseñada, chisporroteo (fuegos artificiales y fuego pequeño, filtrados) |
| Hielo | cristal que se quiebra y escarcha que sisea | impacto de hielo mágico, grieta de hielo, bloque de hielo, brillo frío, siseo de hielo seco |
| Rayo | chispa violeta sin el chasquido agudo y un trueno sordo debajo | descarga eléctrica, impacto eléctrico mágico, arco reverberante, palmada de trueno con paso bajo a 1,2 kHz |
| Sombras | un golpe que se traga el aire | energía oscura, empuje mágico, «whoosh» de fantasma **al revés** (se va hacia dentro), drenaje de vida |
| Gravedad | algo muy pesado que cae y se hunde | impacto de suelo con rocas, golpes de tráiler, tonos que bajan («downer»), roca melódica, pulso grave |
| Debilitamiento (`negra_maldicion`) | un sello: campana sorda que baja y un susurro al revés | «pings» de tráiler a ×0,8, tic de reloj (el sello), tono que baja, voz fantasma al revés |

| Avanzado | Su forma propia | Duración |
|---|---|---|
| Sol de Ceniza | el sol cae: golpe grave y una ola de fuego que barre, arde y luego llueven ceniza y brasas | 5,7 s |
| Invierno Eterno | golpe de hielo y una ventisca que entra (el cielo se pone blanco); el glaciar cruje y las grietas se extienden | 6,8 s |
| Juicio del Relámpago | el sello del cielo suena (golpe metálico grave y un «ping») y cae la columna de luz: trueno muy cercano y un arco que se sostiene; el único de su escuela con un trueno de verdad | 5,5 s |
| Noche Absoluta | la luz se apaga: un tono enorme que baja, un aliento que se la lleva, un coro lejano que sube y estrellas (campanas muy bajas); la firma, más presente que en ningún otro | 7,0 s |
| Colapso Astral | las estrellas caen a un punto: impacto deformado que ondula, un peso que se hunde (sub, metal grave, un tono que baja de marcha) y roca rota | 5,0 s |
| Prisión de Hielo | los barrotes crecen en golpes seguidos, la jaula se cierra (un clic sordo a 0,55 s) y escarcha | 3,6 s |
| preparar | la oscuridad se junta: un crecimiento grave y un aliento hacia dentro; **sin golpe**: llega a su máximo a ~1,2 s | 3,6 s |
| conjuro roto | la energía chisporrotea y se cae (un tono que baja deprisa) con un poco de vidrio | 2,9 s |

### 2. Qué suena y cuándo (observado en el código; comprobado ejecutando, apartado 6.3)

`combate.gd` pide el sonido **una vez por hechizo, en el primer impacto real** (`_resolver_negra`, también con varios
objetivos y con la cadena), uno al empezar a preparar (`_lanzar_negra`) y otro si se rompe (`_conjuro_roto`). La clave la
elige `magia_negra.gd` (`SONIDO`, `SONIDO_FORMA`, `SONIDO_PREPARAR`, `SONIDO_ROTO`): la nueva si existe, si no la de
respaldo. **Las 14 claves que pide el código son exactamente las 14 creadas** (comprobado en la prueba, apartado A): no
hace falta cambiar qué clave pide ningún hechizo; `magia_negra.gd` no se ha tocado.

| Clave | Archivos | Hechizos que la piden | Respaldo (lo que sonaba hasta hoy) |
|---|---|---|---|
| `negra_fuego` | `fuego_1.ogg`, `fuego_2.ogg` | Ascua, Llama Voraz, Lluvia de Brasas | `brasa` |
| `negra_hielo` | `hielo_1.ogg`, `hielo_2.ogg` | Aguja Glacial, Escarcha Profunda | `congelar` |
| `negra_rayo` | `rayo_1.ogg`, `rayo_2.ogg` | Chispa, Rayo Encadenado, Tormenta del Cielo Roto | `golpe_critico` |
| `negra_sombras` | `sombras_1.ogg`, `sombras_2.ogg` | Aguja Umbría, Manto del Eclipse, Marca del Vacío | `arte_ocaso` |
| `negra_gravedad` | `gravedad_1.ogg`, `gravedad_2.ogg` | Peso del Abismo, Pozo Gravitatorio | `arte_ocaso` |
| `negra_maldicion` | `maldicion_1.ogg`, `maldicion_2.ogg` | Quebranto, Velo Roto, Paso Torcido, Maldición Menguante, Herida Elemental | `arte_ocaso` |
| `negra_prision` | `prision.ogg` | Prisión de Hielo | `arte_escarcha` |
| `negra_sol_ceniza` | `sol_ceniza.ogg` | Sol de Ceniza | `brasa` |
| `negra_invierno` | `invierno.ogg` | Invierno Eterno | `arte_escarcha` |
| `negra_juicio` | `juicio.ogg` | Juicio del Relámpago | `golpe_critico` |
| `negra_noche` | `noche.ogg` | Noche Absoluta | `arte_ocaso` |
| `negra_colapso` | `colapso.ogg` | Colapso Astral | `golpe_critico` |
| `negra_preparar` | `preparar.ogg` | empezar a preparar (los de `prep` > 0) | `embuir` |
| `negra_conjuro_roto` | `roto.ogg` | rotura del conjuro (25 % de la vida o caer) | `barrera_rota` |

Cosas del código que conviene saber (no las he cambiado; son de `combate.gd`/`magia_negra.gd`):
- Los avanzados suenan en el **impacto**: lo que pasa antes en pantalla (el sol que nace y cae 1,25 s, el sello del
  Juicio, el cielo que se agrieta) va en silencio, salvo el «preparar» del principio. Para sonorizar esa subida habría
  que pedir una clave más desde `_vfx_negra` (p. ej. `negra_sol_nace` antes del `await`); propuesta, no hecho.
- Los hechizos de una escuela comparten clave (Ascua y Lluvia de Brasas suenan igual salvo la variante y el tono ±3 %).
  Si se quiere distinguirlos, el cambio es en `magia_negra.gd` (`SONIDO_FORMA` con su forma) más una clave nueva aquí.

### 3. Código

#### 3.1 `aethelgard/sonido.gd` (solo se añade)

- `MAGIA_NEGRA` y `EFECTOS_MAGIA_NEGRA` (14 claves, el formato de `EFECTOS_BRAMAVIDRIO` con `dir`/`ext`), con su
  comentario; `definicion()` busca también ahí; cabecera del archivo con la línea de V12 (12/11). Va aparte de `EFECTOS`
  porque `prueba_efectos` exige WAV QOA mono en `audio/efectos/` para todo `EFECTOS`, y aparte de `EFECTOS_DESIERTO`
  porque `prueba_audio_desierto` cuenta sus claves.

| Clave | dB · prioridad · máx · espera · tono | En el juego (Mmax del archivo + dB) |
|---|---|---|
| las 6 escuelas (2 variantes que alternan) | −10 · p3 · 1 · 0,3 s · ±3 % | −22,1/−22,8 (como `golpe_critico` −22,1 y `arte_escarcha` −21,7) |
| `negra_prision` | −8 · p3 · 1 · 0,5 s | −20,6 |
| `negra_sol_ceniza`, `negra_invierno`, `negra_juicio`, `negra_colapso` | −5 · p3 · 1 · 1,0 s | −17,2/−17,3 (por debajo de `jefe` −15,8 y como la `victoria` −17,1) |
| `negra_noche` | −6 · p3 · 1 · 1,0 s | −18,1 (larga y envolvente: menos golpe) |
| `negra_preparar` | −10 · p2 · 1 · 0,3 s · ±2 % | −22,2 en el archivo, pero sin golpe (en el montaje con música, −4/−7 dB bajo la música) |
| `negra_conjuro_roto` | −9 · p3 · 1 · 0,3 s · ±3 % | −21,2 |

Prioridades como el resto del juego: nada de la magia negra es p4 (no baja a los demás; una victoria o un «jefe», p4,
bajan 8 dB lo de prioridad 0-2: aquí, solo preparar); los hechizos son p3, como las artes; preparar es p2, como un golpe (si las 10 voces de Efectos están
ocupadas por p3 o más, se pierde: es un aviso suave). «max 1» y la espera: un hechizo no se duplica aunque se pida dos
veces seguidas (comprobado, apartado C de la prueba).

#### 3.2 `aethelgard/combate.gd` (dos líneas, commit aparte: **aplicarlas a mano** si `combate.gd` ha cambiado)

`_existe_sonido` y `_sonar` solo miraban `EFECTOS` y `EFECTOS_DESIERTO`: sin esto el combate nunca elige la clave nueva
(siempre el respaldo) y, si la pidiera, no la haría sonar. Es lo único imprescindible fuera de mi lista; otro
especialista trabaja en `combate.gd`, así que **no copiar mi `combate.gd` entero**: aplicar este cambio sobre el suyo.

```
 func _existe_sonido(k: String) -> bool:
-	return Sonido.EFECTOS.has(k) or Sonido.EFECTOS_DESIERTO.has(k)
+	return Sonido.EFECTOS.has(k) or Sonido.EFECTOS_DESIERTO.has(k) or Sonido.EFECTOS_MAGIA_NEGRA.has(k)   # V12: magia negra
@@ func _sonar(nombre: String) -> void:
-	if Sonido.EFECTOS.has(nombre) or Sonido.EFECTOS_DESIERTO.has(nombre):   # V12: también el gusano (gusano_rugido…)
+	if Sonido.EFECTOS.has(nombre) or Sonido.EFECTOS_DESIERTO.has(nombre) or Sonido.EFECTOS_MAGIA_NEGRA.has(nombre):   # V12: el gusano y la magia negra
```

(Una alternativa más general sería `not Sonido.definicion(k).is_empty()` en los dos sitios; la dejo al coordinador.)

#### 3.3 Cómo volver a lo de antes (sin borrar nada)

Quitar las dos líneas de `combate.gd` (o vaciar `EFECTOS_MAGIA_NEGRA`): `magia_negra.gd` vuelve sola a los respaldos.
Los OGG pueden quedarse.

### 4. Derivados (`aethelgard/audio/magia_negra/`, OGG Vorbis 48 kHz estéreo q4, 20 archivos, 1 086 KB)

Medido el 12/11 sobre el OGG ya codificado (lo que suena en el juego). «Mmax»: LUFS momentáneo máximo (400 ms).
«En juego»: Mmax + db del catálogo (bus Efectos al 100 %). Bandas: RMS de cada banda respecto al total. «Limitador»: lo
que recortó el limitador con anticipación a −1 dBFS en el pico más alto (solo transitorios). Referencias del proyecto
medidas igual hoy (Mmax + db): `golpe` −25,4, `golpe_critico` −22,1, `arte_escarcha` −21,7, `brasa` −20,8, `arte_ocaso`
−28,5, `embuir` −19,7, `barrera_rota` −18,4, `jefe` −15,8, `victoria` −17,1.

| Archivo | Clave | Can. · dur. · q | Pico / RMS dBFS | LUFS-I / Mmax | Bandas <120 · 120-500 · 500-2,5k · >2,5k (dB rel.) | db catálogo → Mmax en juego | Limitador | KB |
|---|---|---|---|---|---|---|---|---|
| `fuego_1.ogg` | `negra_fuego (1)` | estéreo · 2.94 s · q4 | -3.0 / -21.8 | -16.1 / -12.3 | -13.6 · -4.4 · -3.6 · -10.9 | -10 → -22.3 | 0.0 dB | 40 |
| `fuego_2.ogg` | `negra_fuego (2)` | estéreo · 3.06 s · q4 | -1.9 / -21.6 | -15.4 / -12.3 | -11.7 · -4.2 · -4.9 · -8.6 | -10 → -22.3 | 0.0 dB | 43 |
| `hielo_1.ogg` | `negra_hielo (1)` | estéreo · 2.85 s · q4 | -3.0 / -23.1 | -17.7 / -12.3 | -12.9 · -4.1 · -4.1 · -9.6 | -10 → -22.3 | 0.0 dB | 41 |
| `hielo_2.ogg` | `negra_hielo (2)` | estéreo · 2.77 s · q4 | -0.7 / -22.7 | -17.1 / -12.8 | -13.5 · -4.8 · -3.9 · -8.5 | -10 → -22.8 | 2.9 dB | 39 |
| `rayo_1.ogg` | `negra_rayo (1)` | estéreo · 2.96 s · q4 | -3.1 / -22.3 | -16.6 / -12.4 | -11.0 · -4.2 · -5.0 · -8.5 | -10 → -22.4 | 0.0 dB | 41 |
| `rayo_2.ogg` | `negra_rayo (2)` | estéreo · 3.24 s · q4 | -2.0 / -21.0 | -16.1 / -12.3 | -8.0 · -4.0 · -6.4 · -9.3 | -10 → -22.3 | 0.0 dB | 44 |
| `sombras_1.ogg` | `negra_sombras (1)` | estéreo · 3.41 s · q4 | -2.1 / -19.1 | -13.8 / -12.1 | -10.9 · -3.6 · -4.1 · -15.0 | -10 → -22.1 | 0.0 dB | 45 |
| `sombras_2.ogg` | `negra_sombras (2)` | estéreo · 3.21 s · q4 | -2.6 / -20.5 | -15.9 / -12.2 | -12.5 · -2.7 · -4.4 · -22.1 | -10 → -22.2 | 0.0 dB | 42 |
| `gravedad_1.ogg` | `negra_gravedad (1)` | estéreo · 3.84 s · q4 | -2.3 / -20.6 | -15.5 / -12.3 | -9.4 · -5.8 · -3.3 · -11.6 | -10 → -22.3 | 0.0 dB | 54 |
| `gravedad_2.ogg` | `negra_gravedad (2)` | estéreo · 3.96 s · q4 | -4.1 / -22.5 | -18.3 / -12.3 | -10.6 · -5.4 · -2.9 · -14.2 | -10 → -22.3 | 0.0 dB | 54 |
| `maldicion_1.ogg` | `negra_maldicion (1)` | estéreo · 3.97 s · q4 | -2.8 / -19.6 | -14.9 / -12.2 | -14.4 · -3.8 · -3.2 · -15.8 | -10 → -22.2 | 0.0 dB | 54 |
| `maldicion_2.ogg` | `negra_maldicion (2)` | estéreo · 4.14 s · q4 | -3.8 / -19.5 | -14.9 / -12.1 | -12.5 · -1.9 · -7.2 · -14.2 | -10 → -22.1 | 0.0 dB | 55 |
| `prision.ogg` | `negra_prision` | estéreo · 3.56 s · q4 | -1.5 / -20.8 | -15.7 / -12.6 | -15.1 · -4.4 · -3.4 · -10.3 | -8 → -20.6 | 0.9 dB | 53 |
| `sol_ceniza.ogg` | `negra_sol_ceniza` | estéreo · 5.70 s · q4 | -1.3 / -20.2 | -16.7 / -12.2 | -7.1 · -3.5 · -6.0 · -17.8 | -5 → -17.2 | 0.0 dB | 76 |
| `invierno.ogg` | `negra_invierno` | estéreo · 6.80 s · q4 | -3.1 / -19.4 | -15.7 / -12.3 | -13.7 · -2.8 · -4.6 · -15.0 | -5 → -17.3 | 0.0 dB | 94 |
| `juicio.ogg` | `negra_juicio` | estéreo · 5.46 s · q4 | -1.5 / -21.1 | -17.2 / -12.2 | -13.3 · -2.1 · -5.8 · -16.2 | -5 → -17.2 | 0.0 dB | 70 |
| `noche.ogg` | `negra_noche` | estéreo · 6.97 s · q4 | -1.7 / -18.6 | -15.2 / -12.1 | -6.9 · -3.2 · -6.4 · -18.2 | -6 → -18.1 | 0.0 dB | 88 |
| `colapso.ogg` | `negra_colapso` | estéreo · 4.97 s · q4 | -3.4 / -21.2 | -16.0 / -12.3 | -10.8 · -3.6 · -4.3 · -14.3 | -5 → -17.3 | 0.0 dB | 66 |
| `preparar.ogg` | `negra_preparar` | estéreo · 3.64 s · q4 | -4.3 / -21.8 | -15.1 / -12.2 | -19.6 · -5.1 · -3.5 · -7.6 | -10 → -22.2 | 0.0 dB | 48 |
| `roto.ogg` | `negra_conjuro_roto` | estéreo · 2.86 s · q4 | -2.3 / -20.9 | -16.1 / -12.2 | -7.7 · -4.3 · -5.3 · -13.0 | -9 → -21.2 | 0.0 dB | 39 |

Total: 20 archivos, 1086 KB.


### 5. Licencias (verificadas hoy, 12/11)

Todas las capas salen de los **paquetes GDC de Sonniss** de la biblioteca del usuario (`D:\qtorrent\sound effect`, solo
lectura: se lee con ffmpeg; nada se ha copiado entero al proyecto, solo los 20 derivados). **Licencia Sonniss
«#GameAudioGDC»**, leída hoy en `Sonniss.com - GDC 2017 - Game Audio Bundle/Licensing.pdf` y en `Sonniss.com - GDC 2024 -
Game Audio Bundle/License - GDC Game Audio.pdf`: uso en proyectos personales y comerciales ilimitados, **sin
atribución**, sincronización con juegos, editarlos como parte de la producción; no venderlos tal cual ni atribuirse la
autoría del original; el de 2024, además, **sin entrenar IA**. Huellas comprobadas hoy: los PDF de 2016, 2017, 2018,
2019, 2020 y 2023 son el mismo archivo (SHA-256 `d5da822dce9462890c4c…`, 95 184 bytes); el de 2024,
`8a26e0113e8b00a4dc95…` (60 375 bytes); las mismas huellas que verificó el informe de Bramavidrio. Ninguna carpeta de
paquete trae una licencia propia distinta. **No se usa** el paquete «GDC» sin año (sin archivo de licencia), ni la
colección CC0, ni las carpetas `01_…`-`20_…`, ni el `.zip`, ni nada de Suno. Cada capa: paquete, archivo, tramo, tono,
filtros, peso y SHA-256 del original, abajo y en `procedencia.json`.

#### Capas de cada derivado (tramo en s del original; «tono»: remuestreo, < 1 más grave y lento; peso en dB sobre la capa a pico 0; «desde»: cuándo entra)

- **`fuego_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2019 «Fire_Spell_Dragon_Trap_03.wav» 0.30-1.90 s ×0.85 [highpass=f=120,lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Explosion_Short19.wav» 0.00-0.90 s ×0.8 [lowpass=f=5500], -5 dB desde 0.00 s; Sonniss GDC 2019 «Boom 036.wav» 0.00-0.80 s ×1.0 [lowpass=f=400], -12 dB desde 0.00 s; Sonniss GDC 2023 «FRWKComr_InsJ_Fireworks_Multi_Close_01-04-Crackle.wav» 1.80-3.40 s ×0.85 [highpass=f=300,lowpass=f=5500], -13 dB desde 0.12 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.00 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`fuego_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2018 «Designed Fire - Swooshes - Burst, evolving 34.wav» 2.15-4.00 s ×0.85 [highpass=f=150,lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Explosion_Short19.wav» 0.00-0.90 s ×0.75 [lowpass=f=5000], -8 dB desde 0.00 s; Sonniss GDC 2018 «sm-fire-cotton-02-8040.wav» 4.60-6.40 s ×0.9 [highpass=f=250,lowpass=f=5500], -9 dB desde 0.05 s; Sonniss GDC 2023 «FRWKComr_InsJ_Fireworks_Multi_Close_01-04-Crackle.wav» 1.80-3.40 s ×0.85 [highpass=f=300,lowpass=f=5500], -12 dB desde 0.20 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.00 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`hielo_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Magic_Spells_Impact_Ice13.wav» 0.15-1.80 s ×0.9 [lowpass=f=6500], +0 dB desde 0.00 s; Sonniss GDC 2023 «Bluezone_BC0278_ice_crack_break_078.wav» 0.18-0.85 s ×0.8 [lowpass=f=6000], -6 dB desde 0.00 s; Sonniss GDC 2018 «dry ice sizzle - serrated hot knife blade pressed against block of dry ice 006.wav» 0.10-1.80 s ×0.75 [highpass=f=600,lowpass=f=5000], -15 dB desde 0.05 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.00 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`hielo_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2016 «Ice_chunk_heavy_07.wav» 0.00-1.00 s ×0.85 [lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2019 «MAGIC ICE Whoosh, Ice Bloc, Debris 01.wav» 0.75-2.30 s ×0.85 [lowpass=f=6000], -4 dB desde 0.00 s; Sonniss GDC 2019 «Ice_Spell_Ice_Spell_Buff_Positive_02.wav» 0.00-1.50 s ×0.7 [lowpass=f=6000], -9 dB desde 0.03 s; Sonniss GDC 2018 «dry ice sizzle - serrated hot knife blade pressed against block of dry ice 006.wav» 0.10-1.60 s ×0.75 [highpass=f=600,lowpass=f=5000], -17 dB desde 0.10 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.00 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`rayo_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2018 «electric_surge_blast_04.wav» 0.20-1.60 s ×0.9 [lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Spells_Impact_Electricity25.wav» 0.05-1.80 s ×0.85 [lowpass=f=6000], -6 dB desde 0.00 s; Sonniss GDC 2018 «thunder_clap_04.wav» 0.40-2.80 s ×1.0 [lowpass=f=1200], -10 dB desde 0.02 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`rayo_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Magic_Spells_Impact_Electricity25.wav» 0.05-2.00 s ×0.9 [lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2023 «MagicPack2_ElectricitySpells_Spell2-002.wav» 1.15-2.40 s ×0.9 [lowpass=f=6000], -5 dB desde 0.00 s; Sonniss GDC 2020 «Electric_Arc_Reverberant_Shock_Long_05.wav» 0.50-2.50 s ×0.9 [lowpass=f=5000], -10 dB desde 0.05 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`sombras_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2023 «MAGEvil_Dark Spell Dark Energy Attack_RogueWaves_DruidMagic.wav» 0.05-1.90 s ×0.85 [highpass=f=100,lowpass=f=5000], +0 dB desde 0.00 s; Sonniss GDC 2020 «SFX_Ghost_Whoosh_Male_03.wav» 0.30-1.90 s ×0.8 [lowpass=f=4000] al revés, -7 dB desde 0.03 s; Sonniss GDC 2019 «Dark_Spell_Life_Tap_03.wav» 0.10-1.80 s ×0.75 [lowpass=f=4500], -9 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -14 dB desde 0.08 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -19 dB desde 0.08 s.
- **`sombras_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Magic_Spells_CastShort_Push14.wav» 0.10-1.30 s ×0.8 [lowpass=f=5000], +0 dB desde 0.00 s; Sonniss GDC 2020 «SFX_Ghost_Whoosh_Male_10.wav» 1.00-2.90 s ×0.8 [lowpass=f=4000] al revés, -6 dB desde 0.02 s; Sonniss GDC 2020 «Dark_Sci-Fi_Transition_01.wav» 0.30-1.80 s ×0.85 [lowpass=f=5000], -8 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -14 dB desde 0.08 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -19 dB desde 0.08 s.
- **`gravedad_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2019 «GROUND IMPACT Large, Falling Rocks, Various 04.wav» 0.12-2.40 s ×0.75 [highpass=f=60,lowpass=f=5000], +0 dB desde 0.00 s; Sonniss GDC 2019 «Boom 040.wav» 0.00-1.50 s ×1.0 [lowpass=f=6000], -4 dB desde 0.00 s; Sonniss GDC 2020 «Downer 111.wav» 0.00-2.60 s ×0.9 [lowpass=f=4000], -7 dB desde 0.00 s; Sonniss GDC 2018 «Designed Rocks - ELEM017 - Melodic 4.wav» 1.75-3.30 s ×0.8 [lowpass=f=4500], -11 dB desde 0.10 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`gravedad_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2019 «Ruin B.wav» 0.00-3.00 s ×0.8 [highpass=f=120,lowpass=f=4500], +0 dB desde 0.00 s; Sonniss GDC 2019 «GROUND IMPACT Large, Falling Rocks, Various 04.wav» 0.12-2.00 s ×0.8 [highpass=f=200,lowpass=f=5000], -6 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Spells_Impact_Air24.wav» 0.05-1.80 s ×0.7 [lowpass=f=4000], -3 dB desde 0.00 s; Sonniss GDC 2023 «Dark Pad Deep Pulsating Movement.wav» 10.00-12.50 s ×1.0 [lowpass=f=1500], -10 dB desde 0.05 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.00-2.00 s ×1.0 [lowpass=f=200], -12 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -17 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -22 dB desde 0.10 s.
- **`maldicion_1.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Ping 036.wav» 0.05-2.60 s ×0.8 [highpass=f=150,lowpass=f=4500], +0 dB desde 0.00 s; Sonniss GDC 2024 «CLOCKTick_Clock53_InMotionAudio_SinisterTextures3.wav» 0.00-0.60 s ×0.8 [lowpass=f=5000], -4 dB desde 0.00 s; Sonniss GDC 2020 «Downer 087.wav» 0.00-2.20 s ×1.0 [lowpass=f=4000], -9 dB desde 0.00 s; Sonniss GDC 2020 «Male Ghostly Voice, Hide, Creepy, Air, Spirit, Ethereal, Wet.wav» 2.00-4.60 s ×0.85 [lowpass=f=4500] al revés, -11 dB desde 0.10 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -16 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -21 dB desde 0.10 s.
- **`maldicion_2.ogg`** (espacio común -16 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Ping 010.wav» 0.05-2.60 s ×0.8 [highpass=f=150,lowpass=f=4500], +0 dB desde 0.00 s; Sonniss GDC 2019 «Dark_Spell_Life_Tap_03.wav» 0.10-1.60 s ×0.8 [lowpass=f=4500], -4 dB desde 0.00 s; Sonniss GDC 2017 «GHOSTS Spell Hocus Pocus 2.LR.wav» 0.80-2.60 s ×0.8 [lowpass=f=4500], -10 dB desde 0.20 s; Sonniss GDC 2020 «Downer 013.wav» 0.20-2.50 s ×1.0 [lowpass=f=3500], -11 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -16 dB desde 0.10 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.20 s ×1.0 [highpass=f=60,lowpass=f=900], -21 dB desde 0.10 s.
- **`prision.ogg`** (espacio común -15 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2018 «Designed Ice - HIT26 - Rhythmic crack impact 6.wav» 0.00-2.60 s ×0.9 [lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2016 «Ice_chunk_heavy_07.wav» 0.00-1.00 s ×0.7 [lowpass=f=5500], -6 dB desde 0.00 s; Sonniss GDC 2017 «Ice,Impact,Medium,Slide_04.wav» 0.25-1.60 s ×0.85 [lowpass=f=6000], -4 dB desde 0.00 s; Sonniss GDC 2023 «Bluezone_BC0278_ice_crack_break_189.wav» 0.00-2.60 s ×0.85 [lowpass=f=6000], -8 dB desde 0.10 s; Sonniss GDC 2024 «CLOCKTick_Clock53_InMotionAudio_SinisterTextures3.wav» 0.00-0.60 s ×0.55 [lowpass=f=4000], -9 dB desde 0.55 s; Sonniss GDC 2018 «dry ice sizzle - serrated hot knife blade pressed against block of dry ice 006.wav» 0.10-1.80 s ×0.75 [highpass=f=600,lowpass=f=5000], -16 dB desde 0.20 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.20 s ×0.5 [highpass=f=150,lowpass=f=2200], -15 dB desde 0.20 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.40 s ×1.0 [highpass=f=60,lowpass=f=900], -20 dB desde 0.20 s.
- **`sol_ceniza.ogg`** (espacio común -13 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2024 «Bluezone_BC0294_modern_cinematic_impact_boom_003.wav» 0.00-2.70 s ×0.9 [lowpass=f=6000], -3 dB desde 0.00 s; Sonniss GDC 2019 «Boom 091.wav» 0.00-3.20 s ×1.0 [lowpass=f=5000], -8 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Explosion_Short19.wav» 0.00-0.90 s ×0.7 [lowpass=f=5500], -3 dB desde 0.00 s; Sonniss GDC 2018 «Designed Fire - Impacts - Large, ignition 03.wav» 0.00-4.50 s ×0.85 [highpass=f=150,lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2018 «Designed Fire - Winds - Binaural, swoosh, waves 02.wav» 1.50-4.00 s ×0.9 [lowpass=f=6000], -9 dB desde 0.15 s; Sonniss GDC 2023 «FRWKComr_InsJ_Fireworks_Multi_Close_01-04-Crackle.wav» 1.80-3.70 s ×0.85 [highpass=f=300,lowpass=f=5500], -9 dB desde 0.80 s; Sonniss GDC 2018 «sm-fire-cotton-02-8040.wav» 4.00-7.50 s ×0.9 [highpass=f=250,lowpass=f=5500], -10 dB desde 1.20 s; Sonniss GDC 2016 «Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav» 1.00-5.00 s ×1.0 [highpass=f=1200,lowpass=f=6000], -15 dB desde 1.40 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-8.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -13 dB desde 0.20 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-10.00 s ×1.0 [highpass=f=60,lowpass=f=900], -18 dB desde 0.20 s.
- **`invierno.ogg`** (espacio común -13 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Magic_Spells_Impact_Ice13.wav» 0.15-1.80 s ×0.7 [lowpass=f=6000], +0 dB desde 0.00 s; Sonniss GDC 2016 «Ice_chunk_heavy_07.wav» 0.00-1.00 s ×0.6 [lowpass=f=5500], -5 dB desde 0.00 s; Sonniss GDC 2019 «Boom 005.wav» 0.00-2.50 s ×1.0 [lowpass=f=3000], -8 dB desde 0.00 s; Sonniss GDC 2019 «07 Blizzard_Snow melting_wind_MS stereo.wav» 4.00-10.00 s ×1.0 [highpass=f=120,lowpass=f=6000], -3 dB desde 0.10 s; Sonniss GDC 2018 «glacier_huge_shift_01.wav» 0.20-5.00 s ×0.8 [lowpass=f=5000], -6 dB desde 0.20 s; Sonniss GDC 2020 «Magic_Ambience_Ice09.wav» 1.00-6.00 s ×0.85 [lowpass=f=6000], -7 dB desde 0.30 s; Sonniss GDC 2023 «Bluezone_BC0278_ice_crack_break_002.wav» 0.30-2.90 s ×0.85 [lowpass=f=6000], -10 dB desde 0.40 s; Sonniss GDC 2019 «Ice_Spell_Ice_Spell_Buff_Positive_02.wav» 0.00-1.50 s ×0.6 [lowpass=f=6000], -11 dB desde 0.20 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-8.10 s ×0.5 [highpass=f=150,lowpass=f=2200], -13 dB desde 0.30 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-10.20 s ×1.0 [highpass=f=60,lowpass=f=900], -18 dB desde 0.30 s.
- **`juicio.ogg`** (espacio común -13 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2023 «THUN_InsJ_Thunder_Extremely-Close_03.wav» 1.15-6.50 s ×0.95 [lowpass=f=7000], +0 dB desde 0.00 s; Sonniss GDC 2018 «thunder_mountainous_big_crack_02.wav» 0.10-3.00 s ×0.9 [lowpass=f=6000], -4 dB desde 0.00 s; Sonniss GDC 2018 «electric_surge_blast_04.wav» 0.20-1.60 s ×0.85 [lowpass=f=6000], -3 dB desde 0.00 s; Sonniss GDC 2024 «DSGNBoom_Cinematic Metallic Hit, Boom, Trailer, Sub_JF_Haunted Metal Vol 1_60.wav» 0.15-4.60 s ×0.9 [lowpass=f=5000], -4 dB desde 0.00 s; Sonniss GDC 2020 «Electric_Arc_Reverberant_Shock_Long_05.wav» 0.30-3.40 s ×0.85 [lowpass=f=5000], -9 dB desde 0.10 s; Sonniss GDC 2020 «Ping 003.wav» 0.00-4.00 s ×0.75 [lowpass=f=4500], -9 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.90 s ×0.5 [highpass=f=150,lowpass=f=2200], -13 dB desde 0.25 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-9.80 s ×1.0 [highpass=f=60,lowpass=f=900], -18 dB desde 0.25 s.
- **`noche.ogg`** (espacio común -12 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2020 «Downer 049.wav» 0.00-5.90 s ×1.0 [lowpass=f=4000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Braam 035 (G#).wav» 0.00-2.60 s ×0.9 [lowpass=f=3500], -5 dB desde 0.00 s; Sonniss GDC 2020 «Female Ghostly Breath, Reverse, Exhale, Air, Spirit, Ethereal, Wet 4.wav» 1.50-7.50 s ×0.9 [lowpass=f=4500] al revés, -8 dB desde 0.00 s; Sonniss GDC 2020 «Ghostly Presence, Angelic, Vocal, Layer, Creepy, Horror 4.wav» 2.00-8.00 s ×0.9 [lowpass=f=4000], -10 dB desde 0.30 s; Sonniss GDC 2023 «Enchanting_Bells_4.wav» 1.00-8.00 s ×0.5 [lowpass=f=3500], -16 dB desde 1.20 s; Sonniss GDC 2023 «Dark Drone Deep Waves Of Darkness.wav» 4.00-10.00 s ×1.0 [lowpass=f=1200], -10 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-8.30 s ×0.5 [highpass=f=150,lowpass=f=2200], -10 dB desde 0.20 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-10.60 s ×1.0 [highpass=f=60,lowpass=f=900], -15 dB desde 0.20 s.
- **`colapso.ogg`** (espacio común -13 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2023 «CINEMATIC - IMPACT - Hit - Upfront - 30 Warped Ripping Thundering Long Warbling tail.wav» 0.00-3.10 s ×0.85 [highpass=f=100,lowpass=f=5000], +0 dB desde 0.00 s; Sonniss GDC 2020 «Sub Drop 2.wav» 0.00-3.50 s ×1.0 [lowpass=f=200], -9 dB desde 0.00 s; Sonniss GDC 2024 «DSGNTonl_Deep Metallic Hits, Epic, Sub, Bass_JF_Haunted Metal Vol 3_12.wav» 1.15-6.00 s ×0.9 [lowpass=f=4000], -6 dB desde 0.00 s; Sonniss GDC 2019 «GROUND IMPACT Large, Falling Rocks, Various 04.wav» 0.12-2.60 s ×0.75 [highpass=f=180,lowpass=f=5500], -1 dB desde 0.05 s; Sonniss GDC 2024 «DSGNMisc_Gore Downshifter_MWSFX_CF 01.wav» 1.80-4.60 s ×0.9 [lowpass=f=4500], -9 dB desde 0.30 s; Sonniss GDC 2019 «Ruin B.wav» 0.00-3.00 s ×0.8 [lowpass=f=3500], -8 dB desde 0.00 s; Sonniss GDC 2018 «Designed Rocks - ELEM017 - Melodic 4.wav» 1.75-3.30 s ×0.8 [highpass=f=200,lowpass=f=5000], -8 dB desde 0.60 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.90 s ×0.5 [highpass=f=150,lowpass=f=2200], -13 dB desde 0.25 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-9.80 s ×1.0 [highpass=f=60,lowpass=f=900], -18 dB desde 0.25 s.
- **`preparar.ogg`** (espacio común -14 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2018 «casting_charge_matter_grow_04.wav» 0.00-1.15 s ×0.8 [lowpass=f=5000], +0 dB desde 0.10 s; Sonniss GDC 2020 «Magic_Spells_CastLong_Combo_Dark02.wav» 0.10-2.40 s ×0.85 [lowpass=f=4500], -4 dB desde 0.00 s; Sonniss GDC 2020 «Female Ghostly Breath, Reverse, Exhale, Air, Spirit, Ethereal, Wet 4.wav» 6.30-7.60 s ×0.9 [lowpass=f=4000], -8 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-7.00 s ×0.5 [highpass=f=150,lowpass=f=2200], -10 dB desde 0.20 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-8.00 s ×1.0 [highpass=f=60,lowpass=f=900], -15 dB desde 0.20 s.
- **`roto.ogg`** (espacio común -17 dB; ecualización final `highpass=f=45,bass=g=-6:f=120`): Sonniss GDC 2017 «Energy - electric_fuse-08.wav» 0.00-1.40 s ×0.85 [lowpass=f=5500], +0 dB desde 0.00 s; Sonniss GDC 2017 «Window,Small,Break,Medium Impact,Large Amount of Clinking Pieces.wav» 0.00-1.38 s ×0.7 [highpass=f=200,lowpass=f=5000], -7 dB desde 0.00 s; Sonniss GDC 2020 «Downer 111.wav» 0.10-2.00 s ×1.25 [lowpass=f=4000], -8 dB desde 0.00 s; Sonniss GDC 2020 «Magic_Spells_CastShort_Push14.wav» 0.10-1.30 s ×0.8 [lowpass=f=4500] al revés, -10 dB desde 0.00 s; Sonniss GDC 2017 «Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav» 6.00-6.70 s ×0.5 [highpass=f=150,lowpass=f=2200], -16 dB desde 0.05 s; Sonniss GDC 2017 «Drone, Dark, Eerie_08.wav» 6.00-7.40 s ×1.0 [highpass=f=60,lowpass=f=900], -21 dB desde 0.05 s.

#### Originales usados (biblioteca del usuario, solo lectura) y su SHA-256

| Paquete (licencia) | Carpeta / archivo | SHA-256 |
|---|---|---|
| Sonniss GDC 2016 | Eiravaein Sound - Grit/Grit,ultrafine,hardsurface,palms,smearing,spilling,moderate.wav | `f47f250739d23be482161919a3cec28e82ec8be3d3248f50e7d647c07b896f07` |
| Sonniss GDC 2016 | Stuart Duffield - Ice SFX/Ice_chunk_heavy_07.wav | `d0058efb434e02b1b0225e6a460de62ffb3b59c125a8bf328391b568c27bd4de` |
| Sonniss GDC 2017 | Articulated Sounds - Ghosts/GHOSTS Spell Hocus Pocus 2.LR.wav | `b861ccb684646844d57d49f910e6982e5829c1be8bd5056512a17df8c5440dda` |
| Sonniss GDC 2017 | Chris Skyes - Shards Broken Glass/Window,Small,Break,Medium Impact,Large Amount of Clinking Pieces.wav | `c2552ae7d0988bc1e8ac8cc9ce5d2081ec43a371cb1242f2788aadde95700909` |
| Sonniss GDC 2017 | Mattia Cellotto - Glacier Ice/Ice,Impact,Medium,Slide_04.wav | `059d45a794b9b269c32ae1505b6f87a6868684b9486b9a335cc7a32fe4a306ea` |
| Sonniss GDC 2017 | Raconteur Sound - Crystal Glasses- Tones and Drones_/Crystal, Glass, Tall Narrow, Tone, Rubbing, Musical_05.wav | `f21adaec601e84e83d2f3c34e80ef5a3e954a9ed0e3407445f95ab38f3218b54` |
| Sonniss GDC 2017 | Raconteur Sound - Subtext Drone Library Vol. 1/Drone, Dark, Eerie_08.wav | `1910eb367d657866c94919e4cb5d6f102469f4e6ac1874531d81d6936208715e` |
| Sonniss GDC 2017 | SoundMorph - ENERGY/Energy - electric_fuse-08.wav | `7880942049de411052fbe7a4fe9752f025346f025618949067125f314a3472f8` |
| Sonniss GDC 2018 | Alexander Kopeikin - The Dry Ice Library/dry ice sizzle - serrated hot knife blade pressed against block of dry ice 006.wav | `e81b679010cfda70e6f845405916eb23b02a65d9f2060f057e80ef1b1589da7e` |
| Sonniss GDC 2018 | Gamemaster Audio - Magic and Spell Sounds/casting_charge_matter_grow_04.wav | `27c0faf91f7c4909e3b4db6fddde295d4fe504c95d87449db36329babb3af0f4` |
| Sonniss GDC 2018 | Gamemaster Audio - Magic and Spell Sounds/electric_surge_blast_04.wav | `c8cb6d5c07cad87277bfdf577b8f95e47916f2fff932dc48ad771c3b7640e474` |
| Sonniss GDC 2018 | Gregor Quendel - Designed Ice/Designed Ice - HIT26 - Rhythmic crack impact 6.wav | `54603102cd3e905afa9264d3384abd680499997f43e50fdf2c69026a72646dd8` |
| Sonniss GDC 2018 | Gregor Quendel - Designed Rocks/Designed Rocks - ELEM017 - Melodic 4.wav | `7dc4eb29b6c7c56cb3ee3da84c64345784e2f1504c8a534c8fb392ec16884d21` |
| Sonniss GDC 2018 | Gregor Quendel – Designed Fire/Designed Fire - Impacts - Large, ignition 03.wav | `1d0632a644f86c655d1203a5c45478637e1b0b8732ba7e312c1eab585c8a341a` |
| Sonniss GDC 2018 | Gregor Quendel – Designed Fire/Designed Fire - Swooshes - Burst, evolving 34.wav | `0517904da7122d13608ba4dd4d4278290dc981a902242741471ded69f200f183` |
| Sonniss GDC 2018 | Gregor Quendel – Designed Fire/Designed Fire - Winds - Binaural, swoosh, waves 02.wav | `be9458793cf4a4f7dbecb7ec71e55d0a722605a88740ec5aa58fefe0b2ef60d4` |
| Sonniss GDC 2018 | Soundrangers - Foley Elements Ice and Snow/glacier_huge_shift_01.wav | `a85c9c4fa880be3a271f59e4d2d493333206856c39c1ebe237495c4cdac7809f` |
| Sonniss GDC 2018 | Soundrangers – Thunder/thunder_clap_04.wav | `968767e05079fccb5c28d1a7e8647742c0a74a0d9c0a88aae3cc70e7d82b4a26` |
| Sonniss GDC 2018 | Soundrangers – Thunder/thunder_mountainous_big_crack_02.wav | `a0724e5de1a41df680cb805c9a8bd3cced7886b0adbf293386bf62f7401260c3` |
| Sonniss GDC 2018 | The Sound Keeper - Small Fire/sm-fire-cotton-02-8040.wav | `1bf74c3b6ce0bca8b641c91865f96a671f19ab5f44d652e4761e407bbdcb51e1` |
| Sonniss GDC 2019 | Articulated Sounds - Magic Elements vol.1/GROUND IMPACT Large, Falling Rocks, Various 04.wav | `2f578e6a54f50842117c96a66bac0cafb5a3d7e30cd1e73b88f073441e313f1b` |
| Sonniss GDC 2019 | Articulated Sounds - Magic Elements vol.1/MAGIC ICE Whoosh, Ice Bloc, Debris 01.wav | `2eb4176c9b7cd7e4eac702ee97312dba9ce3e3fb54b34362b9e3a4eb9fa21ece` |
| Sonniss GDC 2019 | Federico Soler Fernández - Effective Trailer Booms/Boom 005.wav | `758fa7fed147657aeac4b868b3c40a82561b19cc2173242a162cddff8d706795` |
| Sonniss GDC 2019 | Federico Soler Fernández - Effective Trailer Booms/Boom 036.wav | `d5deec6b816cee60cd5964040f27268cbb1fb80e5fd84f07231fd322832875ff` |
| Sonniss GDC 2019 | Federico Soler Fernández - Effective Trailer Booms/Boom 040.wav | `b520fb32fce4c29722f5bfcd58c5ba6beffd50c5bd900604dfebbea1ec2ab8d4` |
| Sonniss GDC 2019 | Federico Soler Fernández - Effective Trailer Booms/Boom 091.wav | `a3414e9deb5baeebaf93a65a9a357b54967d504a864710b7586204b2cb6b6650` |
| Sonniss GDC 2019 | Federico Soler Fernández - Effective Trailer Hits & Impacts/Ruin B.wav | `186f828009bb74aa81cddd9c5ac26551f607f4e5dac54c835fd00f906dc4e1df` |
| Sonniss GDC 2019 | Ivo Vicic - Winter textures vol.1/07 Blizzard_Snow melting_wind_MS stereo.wav | `78fc8cc21ce339aeb8085d55e573f12422cd5bd845fb1eb7dd779296d82c3591` |
| Sonniss GDC 2019 | Sound Spark LLC – Magic Spells, Buffs and Attacks/Dark_Spell_Life_Tap_03.wav | `dd1d0dd1c90ef7ee80627b6d8630358d48cf955b82086433cf8ef365a150d5c4` |
| Sonniss GDC 2019 | Sound Spark LLC – Magic Spells, Buffs and Attacks/Fire_Spell_Dragon_Trap_03.wav | `668f3b508896f298b409e75e161d9ad2ed75402c9ef7ec4b97673b95fe82c45a` |
| Sonniss GDC 2019 | Sound Spark LLC – Magic Spells, Buffs and Attacks/Ice_Spell_Ice_Spell_Buff_Positive_02.wav | `67cfc88cca9fc8276c1d3c85153d60299f26ee612c553ee37257bff7cb4dcb5b` |
| Sonniss GDC 2020 | 344 Audio - Supernatural Ghosts/Female Ghostly Breath, Reverse, Exhale, Air, Spirit, Ethereal, Wet 4.wav | `60971c20b59f3a0249d3ad87c6e82166a1dfcdf56ecb0502a68c33f435d3f28f` |
| Sonniss GDC 2020 | 344 Audio - Supernatural Ghosts/Ghostly Presence, Angelic, Vocal, Layer, Creepy, Horror 4.wav | `c9315415b0a482d074a4472a178c8cdda256e04a9967ec8d045b8639c4206fa5` |
| Sonniss GDC 2020 | 344 Audio - Supernatural Ghosts/Male Ghostly Voice, Hide, Creepy, Air, Spirit, Ethereal, Wet.wav | `fdeba435073a3f1bbbe8d7aaa4a37903f0d9a42f428935ceb4a5f4712e2cf6f0` |
| Sonniss GDC 2020 | 344 Audio - Trailer Instruments Designed/Sub Drop 2.wav | `7ab8a270e86e050fbf17265f520a609a61fc18d8dae3ffddb9aeda18490cc456` |
| Sonniss GDC 2020 | David Dumais Audio - Air Magic 1/Magic_Spells_Impact_Air24.wav | `8675e05bd5517e84b057aca93ce2be935ae928a6e65b90411d79395fea9381c7` |
| Sonniss GDC 2020 | David Dumais Audio - Electricity Magic 1/Magic_Spells_Impact_Electricity25.wav | `645d3ececc92f4e6864a9d1338807830fedfe4782ab7d797c5adf0532fd619e8` |
| Sonniss GDC 2020 | David Dumais Audio - Ice & Frost Magic 1/Magic_Spells_Impact_Ice13.wav | `2c903c8a848ee424e906ad27e11f803aa3d6672dedac7b80458171023654885d` |
| Sonniss GDC 2020 | David Dumais Audio - Magic Sound FX Pack 1/Magic_Ambience_Ice09.wav | `bdc78c22653ad10c142f0d0cab882b5e840e228504bc4cde1a51f1e39b5b6bee` |
| Sonniss GDC 2020 | David Dumais Audio - Magic Sound FX Pack 1/Magic_Explosion_Short19.wav | `44a6dd54ddcffc31354ff4d59af5fb0ba49c40dd7a881302050ff064280750d4` |
| Sonniss GDC 2020 | David Dumais Audio - Spells Magic 1/Magic_Spells_CastLong_Combo_Dark02.wav | `1f2bf762607dc5ca30bff6568889eb146602c0dc64e19447282a2009aedacc6c` |
| Sonniss GDC 2020 | David Dumais Audio - Spells Magic 1/Magic_Spells_CastShort_Push14.wav | `86667cb398850afb38c9973db6e469b34578ca2e22aca63ccfd14a91a90fa0e0` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Braams/Braam 035 (G#).wav | `dc79bfe5056f9ecece78d890b2c900a691231a9a188ca24835303726b73372e3` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Downers/Downer 013.wav | `df77d7ca6bc87df52fbc6c4d6ced5d36231c041a18044a7d25f5c09a347041c7` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Downers/Downer 049.wav | `2ef755bc5f82c3040db47c31b1728f3e54ad705eb5beae62edec9d20f64d68e2` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Downers/Downer 087.wav | `7756f47e3b46a9ef5b9404d4a2de0ca3777502c7282d7528ef32c264a227ee01` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Downers/Downer 111.wav | `b5906fb876fbd1650f1f64fcc8ba529fa69dda66fe64f1f0cbbafdbef31efb1c` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Pings/Ping 003.wav | `be438dcd6bf3587e87142263c72aca8cc28b601680bb86ea8aa3542c73a17c6d` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Pings/Ping 010.wav | `95ca3fffa30d99b34e652a2eac3135ad5ffccbba384158fe1ecf2661e7bf6359` |
| Sonniss GDC 2020 | Federico Soler Fernandez - Effective Trailer Pings/Ping 036.wav | `513940374499bf5dce8627442582d0516637fa6281e03d4ed430e5881f915f9f` |
| Sonniss GDC 2020 | Fox Audio Post-Production - Ghost Whoosh – Male&Female/SFX_Ghost_Whoosh_Male_03.wav | `06eccbc5f6d3668f55cda79dfdd5b9655fa6f451c87cdd082d64cd352ce6cb45` |
| Sonniss GDC 2020 | Fox Audio Post-Production - Ghost Whoosh – Male&Female/SFX_Ghost_Whoosh_Male_10.wav | `fc39378bc88e5b365b1c8eb5dda75c2d1d87c5dd5a1e4dc3b0f6465cfefed2d0` |
| Sonniss GDC 2020 | Sound Spark LLC - Electric Arcs and Energy/Electric_Arc_Reverberant_Shock_Long_05.wav | `4c27cc0903f7e5e592860497b5608eb03c14ead7925ae8598759f2947ac541a9` |
| Sonniss GDC 2020 | Sound Spark LLC - Whooshes Impacts and Transitions/Dark_Sci-Fi_Transition_01.wav | `45d8aa9383f37be68c2df26032fd4a419e7234dfcf3c320d6acd19caa56aa401` |
| Sonniss GDC 2023 | BluezoneCorp - Ice Cracking/Bluezone_BC0278_ice_crack_break_002.wav | `9354cbd10dc3a46e92baa518fe432db61f05bd3eb0d9afecfad0c8a9fa745879` |
| Sonniss GDC 2023 | BluezoneCorp - Ice Cracking/Bluezone_BC0278_ice_crack_break_078.wav | `903348ceb82a7954eef572d90d2137ca9e5c470daedc32639189a58432b5bee0` |
| Sonniss GDC 2023 | BluezoneCorp - Ice Cracking/Bluezone_BC0278_ice_crack_break_189.wav | `b319cfcd8d34fcd4fb309488ac89d458d463c9d11c362600c3b6e70b5d18f9b0` |
| Sonniss GDC 2023 | CB Sound Design - Dreamcatcher - The Sound of Dreams & Magic/Enchanting_Bells_4.wav | `258e6f969c0f1eda68d22ce1ecc1913f8186ebf72e74e56e662487d5578dfd95` |
| Sonniss GDC 2023 | David Dumais Audio - Magic Sound FX Pack 2/MagicPack2_ElectricitySpells_Spell2-002.wav | `0a5e5e6ef7283cc2344baf8b1c123b5ce142f72da26bb092328730d2aaf6e38f` |
| Sonniss GDC 2023 | InspectorJ - Essentials 01 Thunder/THUN_InsJ_Thunder_Extremely-Close_03.wav | `9761f1b47f73027f5e409b5c4b2faff8bd2736b0bd54fd9fe84f104c338f4ac4` |
| Sonniss GDC 2023 | InspectorJ - Essentials 03 Fireworks/FRWKComr_InsJ_Fireworks_Multi_Close_01-04-Crackle.wav | `6eb2de0b639bfb0d0efed56c614dff17d89f12e5c89045128cd0cf1b34450102` |
| Sonniss GDC 2023 | Pole Position Production - The Cinematic Transformation Library/CINEMATIC - IMPACT - Hit - Upfront - 30 Warped Ripping Thundering Long Warbling tail.wav | `61d952a264d4fc895b5bb101ccb930cfbb6e3c8c1c806bec3e578b382ab52260` |
| Sonniss GDC 2023 | Rogue Waves - Druid Magic/MAGEvil_Dark Spell Dark Energy Attack_RogueWaves_DruidMagic.wav | `622df7d912e25c9fb62542f86ba0a5f4e2bc9cf61033b00ab12e38d38ae386c6` |
| Sonniss GDC 2023 | Systematic Sound - Tonal Elements Obscurum – Dark Drones/Dark Drone Deep Waves Of Darkness.wav | `701f6f91123e3dd44b9d29e8f03ce19a3cce1777748b950d7ed645ab5f5ecedd` |
| Sonniss GDC 2023 | Systematic Sound - Tonal Elements Obscurum – Dark Drones/Dark Pad Deep Pulsating Movement.wav | `53be5f050c782a789a86a49643cd2b3d8c6dbe286733c389aea6372ed20e02e3` |
| Sonniss GDC 2024 | BluezoneCorp - Modern Cinematic Impact/Bluezone_BC0294_modern_cinematic_impact_boom_003.wav | `1998a1524b2f9f4e36a2f3d523228657c1966c631d49909f89335c43306d42f7` |
| Sonniss GDC 2024 | InMotionAudio - Sinister Textures 3/CLOCKTick_Clock53_InMotionAudio_SinisterTextures3.wav | `1d3e5415f102e33a33a5e0f7c8f9ac580001e7ba6b68033217ad0640a7a28d09` |
| Sonniss GDC 2024 | Jake Fielding - Haunted Metal Vol.1 - Cinematic Hits & Impacts/DSGNBoom_Cinematic Metallic Hit, Boom, Trailer, Sub_JF_Haunted Metal Vol 1_60.wav | `e0f5c0bcd9b9c380a4b2c4e9352d0e684ff52ff81757122296efd5a5e0885619` |
| Sonniss GDC 2024 | Jake Fielding - Haunted Metal Vol.3 - Cinematic Tones & Textures/DSGNTonl_Deep Metallic Hits, Epic, Sub, Bass_JF_Haunted Metal Vol 3_12.wav | `5cb2a8af0a7119dcc1cc6fde8400e0d7f1e085d1e0d60a6a9788e415abc318ba` |
| Sonniss GDC 2024 | Mechanical Wave - Cinematic Feel/DSGNMisc_Gore Downshifter_MWSFX_CF 01.wav | `b955aca3936839d643661e058a96395f7f37033e8779c305214400eff2aaff74` |

Originales distintos: 70.

**Cómo se hicieron:** `crear_negra.py` + `motor.py` (el de Bramavidrio, con la carpeta de temporales configurable) en
Python 3.10 de la biblioteca estándar (`py -3 -I`) y el `ffmpeg.exe` 4.4.1 que ya estaba en el PC (Stremio) para leer,
remuestrear, filtrar, convolucionar (`afir`) y codificar (libvorbis q4). Nada instalado. Cada capa se normaliza a pico 0
y entra con su peso; mezcla, sala común, ecualización final, recorte de la cola, nivel por LUFS momentáneo y limitador
con anticipación a −1 dBFS. Elegir capas: `explorar.py` (duración, bandas, tramos activos) y `envolvente.py` (energía
cada 0,1-0,2 s, para cortar cada capa en su golpe) sobre 203 candidatos de 52 paquetes. Scripts, procedencia completa
(`procedencia.json`), la sala sintética y las listas de candidatos: `D:\REBELUM_diagnostico\sonido\2026-11-12_magia_negra\herramientas\`.
Importación: `--import` con `APPDATA`/`LOCALAPPDATA` propios en mi carpeta temporal; vació los directorios de Dialogic de
`project.godot`, que se restauró con `git restore` (no se confirma ningún cambio de `project.godot`). Los `.import` son
los de Godot por defecto para OGG (`loop=false`).

### 6. Verificación

#### 6.1 Señal (medida con ffmpeg sobre los OGG y con Godot, `mix_audio`, en la prueba)

- Ningún pico por encima de −0,7 dBFS (Godot: ≤ −0,7); ninguno mudo (RMS −18,6/−23,1 dBFS); todos callan tras su final
  (< −140 dBFS).
- Nivel común: LUFS momentáneo máximo −12,1/−12,8 (ffmpeg); energía sin ponderar en 400 ms −14,0/−17,2 dB (Godot; la
  diferencia es la ponderación K, que pesa poco los graves de gravedad y Colapso).
- Arranque (primer bloque de 20 ms a ≤ 12 dB del más fuerte, Godot): todos los de impacto en 0,00-0,04 s (suenan en el
  fotograma del impacto); preparar arranca a 0,16 s y llega a su máximo a 1,22 s (se junta, sin golpe).

#### 6.2 Montajes (SIMULADOS fuera del motor) y muestras

`D:\REBELUM_diagnostico\sonido\2026-11-12_magia_negra\` (índice en `LEEME.md`): `muestras/` (los 20 OGG),
`montajes/01_catalogo_al_volumen_del_juego.ogg`, `02_antes_y_ahora.ogg` (cada clave: el respaldo de hoy y después lo
nuevo) y `03_combate_simulado_con_musica.ogg`: un combate inventado con la música del combate a −6 dB que se aparta
como en el juego (compresor con la entrada de Efectos: −30 dB, 2:1, 30/800 ms) y el limitador del Master a −1 dBFS. La
música (`musica_combate_normal.mp3`, del proyecto; su licencia figura como pendiente en `docs/audio/inventario_sonidos.md`)
solo se usa ahí, en local, como fondo de escucha. Medidas (`montajes_medidas.json`, LUFS momentáneo máximo en 1,2 s
desde cada momento):

| s | Momento | Archivo | Efectos (Mmax) | Música apartada | Efectos sobre la música |
|---|---|---|---|---|---|
| 3,0 | golpe de Kael (referencia) | `golpe_1.wav` | −25,4 | −17,3 | −8,1 |
| 6,0 | Chispa | `rayo_1.ogg` | −22,4 | −20,5 | −1,9 |
| 8,5 | crítico de Garon (referencia) | `critico_1.wav` | −22,1 | −20,7 | −1,4 |
| 10,5 | Rayo Encadenado | `rayo_2.ogg` | −22,3 | −20,5 | −1,8 |
| 13,0 | prepara Prisión de Hielo | `preparar.ogg` | −23,2 | −16,2 | −7,0 |
| 15,5 | suelta Prisión de Hielo | `prision.ogg` | −20,6 | −22,2 | +1,6 |
| 18,0 | Aguja Umbría | `sombras_1.ogg` | −22,5 | −19,4 | −3,1 |
| 20,5 | prepara Sol de Ceniza | `preparar.ogg` | −23,2 | −18,7 | −4,5 |
| 24,5 | suelta Sol de Ceniza | `sol_ceniza.ogg` | −17,2 | −23,9 | +6,7 |
| 31,2 | golpe fuerte y se rompe el conjuro | `critico_2.wav` + `roto.ogg` | −17,5 | −22,3 | +4,8 |
| 34,0 | Quebranto | `maldicion_1.ogg` | −22,2 | −22,2 | 0,0 |
| 36,0 | Peso del Abismo | `gravedad_1.ogg` | −21,6 | −21,3 | −0,3 |
| 38,5 | Escarcha Profunda | `hielo_2.ogg` | −22,8 | −18,9 | −3,9 |
| 41,0 | Ascua | `fuego_2.ogg` | −22,3 | −22,9 | +0,6 |
| 43,5 | suelta Noche Absoluta | `noche.ogg` | −19,3 | −25,4 | +6,1 |
| 50,0 | suelta Colapso Astral | `colapso.ogg` | −17,3 | −21,9 | +4,6 |
| 55,5 | suelta Invierno Eterno | `invierno.ogg` | −17,3 | −21,4 | +4,1 |
| 61,5 | suelta Juicio del Relámpago | `juicio.ogg` | −17,2 | −26,1 | +8,9 |
| 67,5 | victoria (referencia) | `victoria.wav` | −17,1 | −21,6 | +4,5 |

Lectura (medida, no oída): las escuelas quedan donde el golpe crítico (−1/−4 dB bajo la música apartada, como las artes);
los avanzados, 4-9 dB por encima, como la victoria; preparar, 4-7 dB por debajo de la música: es un aviso suave y
puede perderse en el altavoz del móvil (subirlo es cambiar su «db»: −10 → −7). Ningún momento pasa del limitador
(pico antes del limitador −5,3 dBFS).

#### 6.3 Pruebas (aisladas, `ejecutar_pruebas.ps1`)

**Batería completa** (todas las automáticas, con todo confirmado hasta `137217e`):
`D:\REBELUM_diagnostico\pruebas\2026-11-12_025138\resumen.md` → **SUPERADAS 124 · FALLIDAS 0 · MANUALES 54 · NO SEGURAS
0**; partida real, carpeta real de datos y proyecto sin cambios (había otros Godot abiertos sobre otras copias; el
ejecutor los vigila y no tocaron la carpeta real).

Antes, la lista de audio, magia y combate:
Comprobado ejecutando el 12/11 en `D:\Aethelgard_v12_sonido_magia`, con datos aislados:
`D:\REBELUM_diagnostico\pruebas\2026-11-12_024655\resumen.md` → **SUPERADAS 13 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0**;
partida real, carpeta real de datos y proyecto sin cambios. `prueba_audio_magia_negra` (nueva), `prueba_magia_negra`
(sus apartados A y E aceptan la clave nueva o el respaldo y piden uno solo: ahora piden la nueva), `prueba_audio`,
`prueba_audio_memoria`, `prueba_audio_guardian`, `prueba_audio_desierto`, `prueba_audio_bramavidrio`, `prueba_efectos`,
`prueba_musica`, `prueba_combate_huella` (la huella C0 del combate no cambia con las dos líneas de `combate.gd`),
`prueba_combate_seguro`, `prueba_artes_combate` y `prueba_bramavidrio_combate`.

**`prueba_audio_magia_negra`** (sin ventana y muda, ~5 s), SUPERADA:
- A. Las 14 claves, solo en `EFECTOS_MAGIA_NEGRA`, por Efectos, p2-p3, una a la vez, sin bucle; 20 OGG que cargan como
  `AudioStreamOggVorbis` con su duración; 1 086 KB (presupuesto 1 300); cada archivo con su fila aquí. Las tablas de
  `magia_negra.gd` piden exactamente estas 14 (ninguna sobra ni falta) y, con `_existe_sonido` de `combate.gd`, los 24
  hechizos, preparar y la rotura eligen la clave nueva. Los avanzados, por encima de las escuelas; preparar, lo más bajo.
- B. Señal (apartado 6.1).
- C. `Sonido.efecto`: por Efectos y a su volumen (±0,8 dB); pedida dos veces seguidas suena una; las escuelas alternan
  sus dos variantes; en pausa no suena.
- D. Combate de verdad (grupo 1, Kael con el interruptor de pruebas, combate parado): los 24 hechizos piden su clave
  nueva una vez (ni el respaldo) y suena una vez sin descartes; Lluvia de Brasas prepara (`negra_preparar` una vez) y
  un golpe del 25 % la rompe (`negra_conjuro_roto` una vez); todo por Efectos.

Fallos encontrados y arreglados por el camino: el nivel común se medía primero con ±3 dB de energía sin ponderar (da
3,2 dB por los graves; ahora 4 dB, con el LUFS igualado a ±0,4 en ffmpeg); y preparar no sonaba en el apartado D porque,
sin driver de audio, las 10 voces de Efectos seguían «sonando» con los hechizos anteriores (p3) y preparar (p2) no puede
quitarles el sitio: la prueba corta lo que suena antes (en el juego los efectos acaban solos; ver Límites).

`prueba_audio_memoria`: el audio sigue en 20,36 MB de RAM (límite 21; los OGG van en streaming: 0 MB de RAM decodificada)
y el paquete de audio en 33,61 MB (`audio/magia_negra`: 20 sonidos, 1,11 MB).

### 7. Límites

- **No he escuchado nada.** Las descripciones de cada sonido dicen qué capas lleva y cómo se ha medido, no cómo suena.
  Falta que el usuario escuche `muestras/` y los montajes (preguntas concretas en el `LEEME.md` de la carpeta).
- No probado en el Redmi ni con el altavoz del móvil: el reparto por bandas está pensado para él (graves recortados,
  medios presentes), pero no medido allí. Tampoco jugado a mano: la magia negra está apagada y nadie la tiene.
- Sin driver de audio (pruebas sin ventana), los reproductores no terminan nunca y se quedan con su voz: por eso la
  prueba corta lo que suena antes de preparar (apartado D). En el juego los efectos acaban solos; pero si 10 efectos de
  prioridad 3 o más suenan a la vez, preparar (p2) se pierde: está así a propósito (es un aviso suave).
- La subida de los avanzados (el sol que nace, el sello del Juicio…) no tiene sonido: el combate pide el sonido en el
  impacto. Propuesta en el apartado 2.
- Los hechizos de una escuela suenan igual entre sí (dos variantes por escuela). Propuesta en el apartado 2.
- Tamaño: +1 086 KB en el APK (20 OGG en streaming, sin RAM extra por decodificar entero). `prueba_audio_memoria` sigue superada (20,36 MB de RAM de audio, límite 21).

### 8. Para integrar (copiando archivos)

- `aethelgard/audio/magia_negra/` entera (20 `.ogg` y 20 `.ogg.import`).
- `aethelgard/sonido.gd` (solo añade `MAGIA_NEGRA`, `EFECTOS_MAGIA_NEGRA`, una rama en `definicion()` y comentarios; si
  `claude/rebelum-v12` cambió `sonido.gd` después de `daa7dfb`, aplicar el diff en vez de copiar).
- `aethelgard/combate.gd`: **no copiar**: aplicar a mano las dos líneas del apartado 3.2 sobre el `combate.gd` del otro
  especialista.
- `aethelgard/pruebas/prueba_audio_magia_negra.gd` y su `.uid` (si Godot lo creó), y la línea de
  `aethelgard/pruebas/lista_pruebas.txt`.
- Este informe.
- Propuesta para `docs/recursos.md` (no es mío; la fila, igual que la de Bramavidrio):
  `| Magia negra (12/11): audio/magia_negra/* (20 OGG; claves EFECTOS_MAGIA_NEGRA de sonido.gd) | Derivados propios de
  capas de los paquetes GDC de Sonniss 2016-2024 (licencia «#GameAudioGDC»: uso comercial sin atribución; el de 2024, sin
  entrenar IA), con tramos, filtros y SHA-256 de los 70 originales en docs/memory/agents/sonido_v12_magia_negra.md |
  Sonniss GDC | Combate, magia negra (apagada: interruptor magia_negra_v12) | Sí |`
