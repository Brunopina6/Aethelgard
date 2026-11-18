# Ciudad de Oakhaven, maqueta: RECORRIDO con los controles normales (16/11, EXPERIMENTAL [P])

Rama `area-ciudad-recorrido` (desde `b5cafa7`). Herramienta: `aethelgard/pruebas/recorrido_ciudad.gd` (con ventana).
**Arreglos** de lo que encontraron este recorrido y dos verificaciones independientes: rama `area-ciudad-recorrido-2`
(desde `1a38acf`, la punta de `area-ciudad-recorrido`), §7. **Arreglos tras el Redmi (17/11)**: rama `area-ciudad-redmi`
(desde `70b5f82`), §8.
Plano y contrato: `docs/v12/CIUDAD_OAKHAVEN_PLAN.md`, `docs/v12/CIUDAD_OAKHAVEN.md`; sectores: `A.md`-`D.md` de esta
carpeta. No se ha medido rendimiento (encargo): la herramienta quita el tope de FPS de la escena para ir más deprisa y el
tiempo del juego lo fija `--fixed-fps 30`.

## 1. Qué hace la herramienta

Recorre la maqueta entera con Kael, Lya y Garon como lo haría una persona, sin poner `destino` ni posiciones a mano:

- **Entrar**: el banco de pruebas y su botón «Ciudad de Oakhaven (maqueta, en pruebas)» (clic).
- **Andar con clics**: `InputEventMouseButton` en coordenadas de la VENTANA (`root.get_final_transform()` pasa del viewport
  1280×720 a la ventana; a 1600×720, 160 px de franja negra a cada lado). Adónde tocar: una ruta A* por lo andable del
  plano (rejilla de 0,25 m, la de `prueba_ciudad_plano`, con más coste junto a las paredes), recortada en el punto más
  lejano (≤ 9 m) al que Kael llega en línea recta: todo andable, sin escalón de más de 0,3 m y sin caja sólida más alta
  que las rodillas a 0,45 m por delante (lo que mira `vista3d`/`ciudad._altura_suelo`). Antes de cada clic se comprueba
  con la propia escena (`_punto_suelo` y `_ajustar_destino`) que el toque cae en ese punto (a menos de 0,5 m); si en la
  ruta no hay ninguno, se prueba a 0,7 y 1,4 m a cada lado (como quien toca más al centro de la calle). Al acercarse al
  punto tocado se toca el siguiente, sin pararse.
- **Teclas**: un tramo con las flechas (↑ 4 s por la Calle Mayor hacia el norte, ← 0,6 s, → 1,2 s, ↓ 1 s).
- **Botones** con clics: la acción de cada puerta prevista (que diga «Aún no se puede entrar (en obras).»), la de la
  Puerta del Sur (que diga que en la maqueta no se sale), «Guardar y recargar» y «Volver al banco».

En **cada parada** (fin de tramo) comprueba:

| Qué | Cómo | Fallo si |
|---|---|---|
| Kael llega | distancia en planta al destino | más de 0,5 m (0,35 en puertas, 0,4 en cubiertas) |
| No pisa lo sólido | cada fotograma, 4 puntos del paso del fotograma con `plano.andable` (lo sólido no es andable) y la altura contra `plano.altura` | una sola vez, o más de 0,15 m fuera del suelo del plano |
| No se atasca | tiempo contra el largo de la ruta (a 4,2 m/s) | más de 1,6 × lo previsto + 6 s, o se para 7 veces antes de donde se toca (dice qué lo frena: el rayo de las rodillas y contra qué) |
| El grupo le sigue | tras pararse (hasta 2,5 s): cada uno sobre lo andable (0,12 m de tolerancia: el rastro que siguen son puntos de Kael cada 0,2 m y la cuerda roza las esquinas) y a menos de 6 m; cada fotograma, fuera de lo andable y saltos (reaparecer) | fuera de lo andable al pararse o más de 15 fotogramas en el tramo; más lejos de 6 m |
| Kael se ve | cabeza (1,5 m) y pies proyectados con la cámara dentro del cuadro; el rayo cámara → cabeza (`trazado_comun.tapan`, las mismas cajas que dibuja la escena) contra los bloques de los OCHO sectores: si es de un sector montado y ocultable, su malla ha de estar aclarada (`material_override` = el material claro); si no es ocultable, fallo; si su sector no está montado y su bloque sale en la maqueta lejana (≥ 1,5 m), fallo (la lejana no se aclara); y `plano.suelos_que_tapan`. Desde `area-ciudad-recorrido-2`, además: nada ocultable sin aclarar delante de su cintura (0,8 m) y sus pies (0,25 m) | cualquiera de esos; en marcha, cada medio segundo, como aviso |
| El grupo se ve (desde `area-ciudad-recorrido-2`) | ya parado, rayos de la cámara a la cabeza (1,4 m) y la cintura (0,8 m) de Lya y Garon si están a menos de 8 m de Kael | algo ocultable sin aclarar delante |

Imprime una línea por tramo (`TRAMO n [sector] tipo «nombre»: llega en s, clics, falta, grupo a, aclarados · foto`), los
avisos, lo cubierto y «RECORRIDO: n tramos, m fallos» (y «FALLOS: m»). Guarda `recorrido.txt`, capturas JPG en los sitios
críticos y en cada fallo, y un fotograma de vídeo cada 15 del juego (`video/`).

Uso:

```
Godot --path aethelgard --script res://pruebas/recorrido_ciudad.gd --fixed-fps 30 --resolution 1600x720 --
  salida=<carpeta fuera del proyecto> [perfil=bajo|medio|alto] [video=0] [solo=plaza_tapiz,oficios] [rapido]
```

En `lista_pruebas.txt` va como **ventana** (`recorrido_ciudad`, `salida={salida} perfil=bajo`, 3000 s): se ejecuta con
`-Manual`; con «tam=1600x720» se ven las franjas del Redmi. **Sin ventana no vale**: con `--headless` la ventana es de
64×64 (los clics no caben) y, con `--fixed-fps`, la primera carga en hilo de la escena (Recursos.cambiar_escena) falla
(§5, problema 5).

## 2. Los tramos

El recorrido (perfil bajo, el del Redmi: como mucho 3 sectores montados, lo demás en maqueta lejana):

1. Entrar desde el banco (Kael en el patio de caravanas) y el tramo de teclas por la Calle Mayor.
2. Visita de **Puerta del Sur**, la Puerta del Sur (su botón), Calle Mayor → **Plaza**, Calle del Mercado → **Oficios**,
   Escalera del Molino → **Ribera**, Rampa de los Carros → Puerta del Sur, **«Volver al banco»** y entrar otra vez,
   Arco de los Pasajes → **Pasajes**, Paso Cubierto de la Botica (ida y vuelta), Pasaje del Corro → **Cuervo**, Calle del
   Cuervo (ida y vuelta), Escaleras de las Terrazas → **Terrazas**, su remate alto → **Barrio Alto**, Subida de la Colina
   (ida y vuelta), Calle del Árbol → Plaza, Calle Mayor → Puerta del Sur, su botón y «Volver al banco».
3. Cada conexión del recorrido se anda ida, vuelta e ida (las de ida y vuelta, dos veces), a 4 m del borde de cada lado,
   con captura al cruzar el borde la primera vez.
4. En cada sector (la parada más cercana primero): cada SUELO en pendiente del trazado (escaleras, escalinatas y
   rampas) de punta a punta, ida y vuelta, con captura a mitad (entre niveles); cada `cubierta` con suelo debajo
   (soportales, corredores, pasos bajo casa, arcos, toldos, tejadillos y tendederos), con captura bajo ella; cada puerta
   prevista (captura en la primera de cada sector); sus callejones sin salida (entrar y volver, captura al fondo); sus
   atajos y bucles (captura a mitad); «Guardar y recargar» a mitad del sector (captura).

| Sector | Pendientes | Cubiertas con suelo | Puertas | Sin salida | Atajos y bucles |
|---|---|---|---|---|---|
| Puerta del Sur | 3 | 5 (2 lonas sobre carros, sin suelo) | 7 | Patio de la Rayuela (por el zaguán), muelle de carga | Callejón de los Arrieros |
| Plaza del Tapiz | 6 | 9 | 13 | rincón del mirador del pretil | Plazuela de la Botica |
| Oficios | 11 | 4 | 12 | Callejón del Carbón | Escalerilla de la Colina |
| Ribera | 5 | 2 | 7 | Callejón de los Fardos | Escalera del Molino y bucle de la acequia |
| Pasajes | 6 | 8 | 14 | Pip → grieta → Patio de las Velas, Huerto, Rincón Fresco, Corral del Rincón | Escalerilla de la Botica |
| Cuervo | 4 | 6 | 10 | Corral de la Posada | bucle del Callejón del Corro |
| Terrazas | 10 | 8 | 12 | Patio de la Pieza | Atajo de la Hornacina; subida directa |
| Barrio Alto | 5 | 2 | 10 | Mirador del Concejo, Mirador de las Raíces | vuelta al Árbol bajo la raíz en arco |
| **Total** | **50** | **44** (+2 sin suelo) | **85** | **13** | **9** |

(La Plaza no tiene un callejón sin salida propiamente dicho: el rincón del mirador del pretil, al fondo de la plaza alta,
hace de «entrar y volver».)

## 3. Resultados

Pasada final (perfil bajo, `--fixed-fps 30`, con ventana, en el PC; rama con el arreglo de `ciudad.gd`):

| | 1600×720 (franjas de 160 px, como el Redmi) | 1280×720 |
|---|---|---|
| Ventana → viewport | 1600×720 → 1280×720, desplazamiento (160, 0) | 1280×720, identidad |
| **RECORRIDO** | **430 tramos, 0 fallos** | **430 tramos, 0 fallos** |
| Tramos por tipo | 86 ir · 100 escalera/rampa · 44 cubierta · 85 puerta · 34 conexión · 26 sin salida · 39 atajo · 8 recarga · 4 teclas · 2 Puerta del Sur · 2 banco | igual |
| Cubierto | 8/8 sectores; 24/24 sentidos de las 12 conexiones; 50/50 pendientes ida y 50/50 vuelta; 44/44 cubiertas con suelo; 85/85 puertas «en obras»; 13 sin salida; 9 atajos; 8/8 «Guardar y recargar»; 2 «Volver al banco»; 2 Puerta del Sur; 1 tramo de teclas (4 pulsaciones) | igual |
| Clics en el suelo | 1 579 | 1 579 |
| Botones pulsados otra vez | 0 | 0 |
| Grupo al pararse | siempre a ≤ 3,6 m, sobre lo andable; 0 reapariciones | igual |
| Kael visible | en las 430 paradas y en marcha (sin avisos); en 275 paradas la escena tenía algo aclarado | igual |
| Avisos | 2 roces del grupo con una esquina (1-2 fotogramas: un pilar del soportal de los Oficios y el jardín de la plaza del Árbol) | igual |

Las dos pasadas dan las MISMAS 430 líneas (comparadas sin los nombres de las capturas): el tiempo del juego es fijo y los
clics, convertidos a la ventana, caen en el mismo sitio con y sin franjas. ≈ 17 min de juego en los tramos; ≈ 25 min
reales cada pasada (las dos a la vez).

Antes de los arreglos (pasadas de depuración del mismo día): 51 fallos en la primera (la herramienta: probaba solo los
14 toques más lejanos), 11 (todos en el Paseo del Concejo: problema 1), 4 (roces del grupo y la esquina del Callejón de
los Fardos), 6 (esquinas: el cobertizo y los Fardos; la comprobación de las rodillas en rejilla de 0,25 m no veía los
bordes) y 1-2 (clics de botón a 1600×720: problema 4).

Pruebas al final (ejecutor, `-Solo prueba_ciudad_plano,prueba_ciudad_cargador`): **SUPERADAS 2 · FALLIDAS 0** (pasada
`D:\REBELUM_diagnostico\pruebas\2026-11-16_114839`; plano 64 OK, cargador 91 OK; partida real y carpeta real sin
cambios).

## 4. Capturas y vídeos

Fuera del repositorio, en `D:\REBELUM_diagnostico\ciudad_oakhaven\recorrido\area-ciudad-recorrido\`:

| Qué | 1600×720 | 1280×720 |
|---|---|---|
| Vídeo (70 s, 40 fps, 640×360; un fotograma cada 0,5 s de juego: ≈ ×20) | `recorrido_ciudad_1600x720.mp4` | `recorrido_ciudad_1280x720.mp4` |
| Capturas (JPG, 1280×720) | `1600x720\*.jpg` (163) | `1280x720\*.jpg` (163) |
| Registro (una línea por tramo) | `1600x720\recorrido.txt`, `out.log` | `1280x720\recorrido.txt`, `out.log` |
| Fotogramas del vídeo | `1600x720\video\` (2 806) | `1280x720\video\` (2 806) |

Las capturas se llaman `NNN_<sector>_<tipo>_<nombre>.jpg`. Las de los sitios críticos:

- **Bajo aleros, toldos y tejadillos**: `…_cubierta_lonja_tejado…`, `…_toldo_flores…`, `…_toldo_puesto_1..3…`,
  `…_toldo_fruta…`, `…_toldo_lonas…` (caravanas), `…_tejadillo_forja…`, `…_porche_taberna…`, `…_tejadillo_almacen…`,
  `…_tejadillo_lavadero…`, `…_pergola_glicinias…`, los tendederos.
- **Soportales**: `…_cubierta_soportal_gu…` (guardia), `…_cubierta_soportal__`, `…_soportal_s…` (Calle Mayor),
  `…_soportal_o…`, `…_soportal_e…` (Oficios), `cuervo_cubierta_cubierta_soportal…`.
- **Pasos cubiertos y bajo edificios**: `…_cubierta_paso_pozo…` (zaguán de la rayuela), `plaza_tapiz_cubierta_cubierta_paso…`
  (Paso Cubierto de la Botica), `…_cubierta_fuelle…` (Paso del Fuelle), `…_pasaje_bajo…`, `…_corredor…`,
  `…_escalerilla…`, `…_paso_huerto…`, `…_paso_vecinos…` (Pasajes), `…_paso_tonel…`, `…_tejadillo_pasaje…` (Cuervo),
  `…_paso_casa_puente…` (Terrazas), `…_cubierta_lavadero…`, `…_techo_escalera_torre…` (Ribera); arcos: `…_dintel_arco_pasajes…`,
  `…_arco_pasajes…`, `…_arco_escaleras…`, `…_arco_atajo…`, `…_portico_dintel…`, `…_raiz_arco…`.
- **Escaleras entre niveles** (a mitad de la subida): `…_escalera_suelo_…_ida_medio` de cada sector (la escalinata de
  la plaza `plaza_tapiz_escalera_suelo_2_z_4_0_2_0…`, las de las Terrazas 6 → 12, la Escalera del Molino, la torre…).
- **Junto a la muralla sur**: `016_puerta_sur_puerta_sur…` y `163_puerta_sur_puerta_sur…` (la Puerta del Sur y su
  aviso), `002_puerta_sur_teclas…`.
- Además: la entrada, la primera puerta de cada sector con su botón, cada «Guardar y recargar», el fondo de cada
  callejón sin salida, la mitad de cada atajo, cada conexión al cruzar el borde y «Volver al banco».

## 5. Problemas y arreglos

| # | Problema | Dónde | Gravedad | Estado |
|---|---|---|---|---|
| 1 | **Un pretil se quedaba los toques del suelo que tapa.** `_punto_suelo` ignoraba lo que está a más de 1 m sobre el suelo (tejados), pero lo alto de un pretil de 0,9 m sí contaba como «suelo»: en el Paseo del Concejo (Barrio Alto, cota 10) el pretil del sur recogía los toques del metro de paseo que hay detrás de él, y Kael iba hacia el pretil y se paraba. Lo encontró el recorrido (todos los toques en esa franja «caían» en `Choque_pretil_colina_1` o `Choque_pretil_paseo_o`). | `zonas3d/ciudad/ciudad.gd`, `_punto_suelo` | media (afecta al toque en cualquier sitio con un pretil o banco delante) | **Arreglado**: lo alto de un bloque que no se pisa queda solo de reserva; si el rayo encuentra suelo andable detrás, vale ese suelo. Comprobado aparte (Kael en dos puntos del paseo, 30 toques en la franja de 1 m tras el pretil cada uno): antes **27 de 60** caían donde se tocaba, ahora **60 de 60**. Sin cambio de comportamiento donde no hay pretil (si detrás no hay suelo, vale como antes). |
| 2 | **Kael se para en las esquinas** al ir en diagonal: el rayo de las rodillas de `vista3d` (0,3 m más allá de cada paso) corta de lado la esquina de una caja y Kael no se desliza. Visto saliendo del Callejón de los Fardos hacia el patio (esquina del `almacen_so`) y saliendo del cobertizo de carros (el `carro_cobertizo`). Quien juega tiene que tocar otra vez, más recto. | `prototipos/vista3d.gd` (compartido por todas las regiones 3D) | baja | **Pendiente** con clics (no es local a la ciudad). La herramienta lo evita como lo haría una persona: no toca en diagonal pegado a una esquina. Con teclas o mando, arreglado en la ciudad (§7, problema 9: Kael se desliza a lo largo de la pared). |
| 3 | **El grupo roza las esquinas** de las cajas sólidas unos centímetros (Lya en la esquina del puesto de flores, 8 cm, quieta 8 s mientras Kael esperaba bajo el toldo; Garon 7 cm dentro del muro de la grieta; Lya en un bancal del huerto): siguen el rastro de Kael (un punto cada 0,2 m) y la cuerda entre dos puntos, al doblar, corta la esquina. Por eso la tolerancia de 0,12 m; quedan 3 avisos de 1-6 fotogramas por pasada. | `zonas3d/grupo_3d.gd` (compartido) | baja (no se ve: el cuerpo es más ancho que el roce) | **Pendiente**, descrito. Nunca se quedan atrás (0 reapariciones) ni a más de 3,6 m al pararse. |
| 4 | **Clics de botón que no entraban** a 1600×720 (2 de unos 200 en una pasada: una puerta «en obras» y el último «Volver al banco»; a 1280×720, ninguno): lo más probable, el puntero real del PC sobre la ventana, que mueve el ratón entre la pulsación y la suelta del clic simulado (el botón deja de contar la pulsación). | entorno de la prueba | — | **Arreglado en la herramienta**: el puntero se mueve antes al botón y, si el clic no hace nada, se vuelve a pulsar (hasta 3 veces, como quien vuelve a tocar); las repeticiones se cuentan («botones pulsados otra vez»). No es del juego. |
| 5 | **Sin ventana no se puede**: con `--headless` la ventana es de 64×64, y con `--fixed-fps 30` la PRIMERA carga en hilo de una escena con guiones (`Recursos.cambiar_escena`) falla con «Parse Error: Failed» (también el barrio y la muestra de la calle desde el banco; con ventana, o sin `--fixed-fps`, carga bien). | entorno de pruebas (`recursos.gd`/cargas en hilo + `--headless --fixed-fps`) | baja (solo pruebas) | **Pendiente**, descrito; por eso la prueba va como «ventana». |
| 6 | Dos `cubierta` sin suelo debajo: las lonas de los carros de caravana (encima de un carro sólido). No son un paso. | `puerta_sur/trazado.gd` | — | Correcto, no se recorren. |
| 7 | Los rótulos 3D «… (en obras)» se dibujan por delante de Kael cuando está junto a la puerta (p. ej. «Almacén del fondo» en el Callejón de los Fardos). | `sector.gd`, `_rotulos` | baja (maqueta) | Visto en las capturas; sin cambiar (son de la maqueta; las puertas de verdad no llevarán rótulo). En §7 (problema 7) los rótulos, de sector y de puerta, dejan de dibujarse a menos de 10 m de la cámara; este caso (a unos 16 m) sigue igual. |
| 8 | Algunos tramos largos piden muchos toques (hasta ≈ 30 del Paseo del Concejo a la Calle del Árbol): pretiles, giros y escaleras donde el siguiente punto al que se llega en línea recta queda cerca. | — | — | Observación (no es un fallo: Kael llega a su tiempo). |

Lo que NO falló en ninguna pasada: Kael nunca pisó lo no andable ni atravesó una caja sólida; siempre se vio (cabeza y
pies en cuadro y ningún bloque sin aclarar delante, también en marcha y con los sectores sin montar en maqueta lejana del
perfil bajo); las 12 conexiones en los dos sentidos; todas las pendientes; «Guardar y recargar» en los 8 sectores (Kael
reaparece a menos de 1 m, en el mismo sector, con el grupo); la Puerta del Sur no saca de la ciudad; «Volver al banco» y
volver a entrar (Kael en el patio de caravanas). Las dos resoluciones dan los MISMOS tramos y resultados (los clics se
pasan bien a la ventana con la franja de 160 px).

## 6. Pendiente

- Problemas 2 (con clics), 3 y 5 (§5): fuera de lo local a la ciudad (`vista3d.gd`, `grupo_3d.gd`, cargas en hilo con
  `--headless --fixed-fps`). Lo de §7 está en su tabla.
- Pasar el recorrido también en los perfiles medio y alto (`perfil=medio|alto`): aquí, el bajo (el del Redmi y el que más
  maqueta lejana deja ver); y en el Redmi de verdad con el dedo (no hay guion de móvil para esto).
- Cuando los sectores cambien (casas, patios, la vida), volver a pasarlo: las paradas salen de los trazados (pendientes,
  cubiertas, puertas), pero los callejones sin salida y los atajos están escritos en la herramienta (`SIN_SALIDA`,
  `ATAJOS`) con los nombres de las anclas de hoy.
- Rendimiento: sin medir (encargo).

## 7. Arreglos (rama `area-ciudad-recorrido-2`, 16/11)

Desde `1a38acf`. Lo que encontraron este recorrido y dos verificaciones independientes (visibilidad y «romper»). Cada
problema se reprodujo antes de tocarlo, con los controles normales (entrar por el botón del banco, clics en coordenadas
de ventana, flechas), con dos herramientas de diagnóstico (no son pruebas de la lista):

- `aethelgard/pruebas/diag_ciudad_visibilidad.gd` (de la verificación de visibilidad, sin cambios): el mismo recorrido
  y, cada 2 fotogramas, rayos de la cámara a los pies, la cintura, la cabeza y los lados de Kael y a la cintura y la
  cabeza del grupo; los aclarados que parpadean (3 cambios en 1 s); con `sitios=1`, solo los 17 sitios donde se vio algo.
- `aethelgard/pruebas/diag_ciudad_arreglos.gd` (nueva): el grupo en el primer cuadro al entrar; tocar el suelo de los
  Pasajes desde la entrada del Paso de la Botica viniendo de la Calle Mayor (pasajes sin montar, bajo); ↑ y ↑+→ pegado a
  la pared norte del Paso de la Botica; rótulos dibujados a menos de 10 m de la cámara.

| # | Problema (gravedad) | Reproducido | Arreglo | Estado |
|---|---|---|---|---|
| 1 | Kael tapado de los hombros abajo (o entero) por una hoja de puerta, un tejado, una lona o un arco que se pueden aclarar, justo donde se pulsa «Entrar»: la escena solo miraba la cabeza (media) | sí: hojas del soportal 1-3 de los Oficios, casa del huertano, lona del carro 1, arco de las Escaleras de las Terrazas (`sitios_antes`, 3,5-4,7 s cada uno) | `ciudad._oclusion` pasa varios puntos a `cargador.aclarar` / `sector.aclarar`: cabeza (1,5 m), cintura (0,8), pies (0,25) y los dos lados (±0,25 m en x, a 0,8 y 1,4); se aclara lo ocultable que corte cualquier segmento cámara → punto, con un descarte rápido por la caja de todos los segmentos | **arreglado**: 0 casos en la pasada entera |
| 2 | Lya o Garon tapados por lo ocultable que no se aclaraba (solo contaba Kael) (media) | sí: 33 casos (29 claves bloque-persona) en la pasada de la verificación, 4 en `sitios_antes` | cabeza (1,4), cintura (0,8) y pies (0,25) de quien del grupo esté a menos de 8 m de Kael | **arreglado**: 0 casos |
| 3 | Medio Kael tapado de lado, pegado a la esquina de algo ocultable (baja) | sí: corredor cubierto de los Pasajes, `casa_escalerilla_o`, 3,7 s | los puntos de los lados (problema 1) | **arreglado**: 0 casos |
| 4 | Aclarados que parpadean al andar: el rayo entra y sale del borde de una caja (baja) | sí: dintel de la Puerta del Sur y casa del paso de los vecinos (`sitios_antes`) | `sector.aclarar`: lo aclarado sigue aclarado `SOSTEN` = 1,0 s de juego después de dejar de tapar. Con 0,35 s (lo propuesto) y con 0,6 s seguían 1-3 parpadeos por pasada (los puntos del grupo, en marcha); con 1,0, ninguno. Al colocar a Kael de golpe (`_colocar_kael`), el sostén se olvida: la prueba del cargador («vuelve a opaca al apartarse», a los 3 fotogramas) pasa sin cambiarla | **arreglado**: 0 parpadeos en la pasada entera |
| 5 | Bajo los toldos del mercado, el mostrador del puesto (bajo, sólido, no ocultable) tapa a Kael (baja) | sí, en la pasada de la verificación (puestos 1-3 y de fruta, 1,1-1,4 s) | `puesto_1/2/3`, `puesto_fruta`, `puesto_lonja_1/2` y `puesto_flores` a OCULTABLES de `sectores/plaza_tapiz/trazado.gd`, con los puntos de la cintura y los pies | **arreglado**: 0 casos; antes y después en `antes_y_despues\02` a `04` |
| 6 | Al entrar, la hoja de la Puerta del Sur corta las piernas de Lya y Garon en el primer cuadro (baja) | sí: `diag_antes_1600x720`, «Lya y Garon a 0,25 m: puerta_sur/puerta_sur» | los pies del grupo (problema 2); el ancla de inicio no se mueve | **arreglado**: el grupo se ve entero (`antes_y_despues\09_entrada_grupo.jpg`) |
| 7 | Rótulos 3D de sector enormes y cortados cerca de la cámara, o encima del grupo (baja) | sí: el de la plaza a 5,8 m y el del Barrio Alto a 6,7 m de la cámara, dibujados | `sector._rotulos`: `visibility_range_begin` = 10 m (margen 2, fundido propio) en los rótulos de sector y de puerta. El título de la pantalla ya nombra el sector | **arreglado**: ninguno a menos de 10 m; `antes_y_despues\08` (Barrio Alto) |
| 8 | Un sector que se ve pero no está montado pierde los toques: ante el Paso de la Botica viniendo de la Calle Mayor (bajo: puerta_sur, plaza_tapiz y cuervo montados), el suelo de los Pasajes a 4-10 m no se podía tocar (media) | sí: 3 de 3 toques perdidos, `_punto_suelo` da null y Kael no se mueve | `ciudad._punto_suelo`: si los choques no dan suelo, `_punto_plano` recorre el mismo rayo contra el plano (pasos de 0,25 m hasta 120 m, afinado a 2,5 cm) y devuelve el primer punto andable con el rayo a su cota; `_ajustar_destino` sigue cortando en lo no andable. Sin cambio cuando los choques dan suelo o reserva. El cargador no cambia | **arreglado**: 0 de 3 perdidos (Kael anda 6,6 m hacia el pasaje y el cargador monta los Pasajes) |
| 9 | Con teclas o mando, Kael no se desliza a lo largo de una pared en diagonal (baja) | sí: ↑+→ 1,5 s pegado a la pared norte del Paso de la Botica, 0,20 m | `ciudad._deslizar` (tras `vista3d._process`): si el paso entero no pasa, prueba solo en x y solo en z con el mismo `_altura_suelo` (escalón, rodillas, lo no andable), el más alineado primero, y anima la marcha. `vista3d.gd` NO cambia (las otras regiones siguen igual). Con clics, no (el toque va a un punto) | **arreglado** en la ciudad: 4,45 m (libre, unos 4,5); al soltar, Kael no sigue andando en el sitio |
| 10 | Kael se para en las esquinas con CLICS en diagonal (rayo de las rodillas de `vista3d`) (baja) | no se repite aparte (la herramienta lo evita) | ninguno: `vista3d.gd` es compartido | **pendiente** (§5, problema 2) |
| 11 | El grupo roza las esquinas de cajas sólidas unos centímetros (baja) | sí: 2 avisos de 1-2 fotogramas por pasada (pilar del soportal 1, jardín de la plaza del Árbol) | ninguno: `grupo_3d.gd` es compartido | **pendiente** (§5, problema 3) |
| 12 | Sin ventana no se puede pasar (64×64; carga en hilo con `--fixed-fps`) (baja) | no se repite (descrito en §5) | ninguno: entorno de pruebas | **pendiente**; la prueba sigue como «ventana» |
| 13 | Rótulos «… (en obras)» por delante de Kael junto a la puerta (baja) | visto en las capturas | ninguno (son de la maqueta); a menos de 10 m de la cámara ya no se dibujan (problema 7), pero este caso está a unos 16 m | **sin cambiar** (descartado: maqueta) |
| 14 | Dos cubiertas sin suelo: las lonas de los carros 1 y 2 | — | ninguno | **descartado**: correcto, no son un paso |

`recorrido_ciudad.gd` comprueba ahora en cada parada también la cintura y los pies de Kael y la cabeza y la cintura del
grupo (§1), y `prueba_ciudad_cargador.gd`, el aclarado por varios puntos, el sostén, que se olvida al colocar a Kael y el
toque contra el plano (y que el cielo y el campo de fuera de la ciudad no dan toque).

Pasada final (perfil bajo, `--fixed-fps 30`, con ventana, en el PC; cada pasada con su propia carpeta de datos):

| | 1600×720 | 1280×720 |
|---|---|---|
| **RECORRIDO** (con las comprobaciones nuevas) | **430 tramos, 0 fallos** | **430 tramos, 0 fallos** |
| Cubierto | lo mismo que en §3 | igual |
| Clics en el suelo / botones repetidos | 1 579 / 0 | 1 579 / 0 |
| Paradas con algo aclarado | 297 (antes 275) | 297 |
| Avisos | los 2 roces del grupo de siempre (problema 11) | igual |
| Visibilidad (`diag_ciudad_visibilidad.gd`: la pasada entera más la ronda, el Árbol y la muralla, 438 tramos, 0 fallos) | **0 casos** (antes, en la verificación, por claves: 11 Kael solo cabeza, 7 aclarado sin llegar a la cintura, 29 grupo tapado, 2 parpadeos) | — |
| Sitios (`sitios=1`, 17) | 0 casos (antes 19 claves) | — |
| `diag_ciudad_arreglos.gd` | 0 fallos (antes 4) | 0 fallos |

Las dos resoluciones dan las MISMAS 430 líneas (sin los nombres de las capturas). Pruebas (ejecutor, `-Solo
prueba_ciudad_plano,prueba_ciudad_cargador`): **SUPERADAS 2 · FALLIDAS 0** (pasada
`D:\REBELUM_diagnostico\pruebas\2026-11-16_124224`; plano 64 OK, cargador 98 OK; partida real y carpeta real sin
cambios).

Capturas y vídeos, fuera del repositorio, en `D:\REBELUM_diagnostico\ciudad_oakhaven\recorrido\arreglos-2\`:
`1600x720\` y `1280x720\` (163 capturas, `recorrido.txt`, `out.log`, `video\`), `recorrido_ciudad_1600x720.mp4` y
`recorrido_ciudad_1280x720.mp4`; `visibilidad_1600x720\visibilidad.txt`; `sitios_antes\` y `sitios_despues\`;
`diag_antes_1600x720\`, `diag_despues_1600x720\` y `diag_despues_1280x720\`; `antes_y_despues\` (izquierda, antes, en la
rama `area-ciudad-recorrido`; derecha, después: la entrada, los toldos de fruta, flores y puesto 2, el corredor, las
Escaleras de las Terrazas, el tendedero del lavadero, la raíz en arco, el grupo al entrar, la pared con teclas y el
toque en los Pasajes sin montar); `sosten_0_6\`, las pasadas con el sostén de 0,6 s (1-3 parpadeos).

No se ha medido rendimiento (encargo). El aclarado hace ahora hasta 13 segmentos por ocultable montado en cada
fotograma, con un descarte por caja; `_punto_plano` solo corre en un toque que los choques no resuelven.

## 8. Arreglos tras el Redmi, 17/11 (rama `area-ciudad-redmi`, desde `70b5f82`)

Lo que se vio en la pantalla real el 16/11 con la APK `2afc6ed` (`docs/v12/REDMI_16_11.md`, «Lo que se ve en la pantalla
real») y los fallos de «Guardar y recargar» de `diag_ciudad_romper.gd`. El Redmi NO estaba conectado: todo se ha
reproducido y comprobado en el PC (ventana 1600×720, la del Redmi con sus franjas, `--fixed-fps 30`, datos aislados). No
se ha medido rendimiento (encargo; otra ventana de Godot podía estar abierta) ni se declara nada de Android. El
renderizador (Compatibility) no cambia.

Herramientas: `fotos_ciudad_optimiza.gd` con `sitios=redmi` (14 sitios con la MISMA cámara antes y después: Kael colocado,
o colocado y andando hacia un punto como tras un toque; anota las piezas aclaradas, dónde se para Kael y los rótulos
que se dibujan con su ancho en pantalla); `diag_ciudad_silueta.gd` (nueva, sin ventana: en toda la rejilla andable,
cuánto del torso y la cabeza de Kael, 5 × 3 puntos, tapa lo que la escena NO aclara); `diag_ciudad_romper.gd` con
`recargas` (solo las recargas difíciles); `recorrido_ciudad.gd` y `diag_ciudad_visibilidad.gd` enteros.

| # | Lo visto en el Redmi | Reproducido en el PC | Causa | Arreglo | Estado |
|---|---|---|---|---|---|
| 1 | Un pilar fino de la lonja delante de Kael lo tapa casi entero (`t07_norte.png`) | sí: `r01_lonja_pilar_fino_t07` (Kael 2,5 m al norte de `lonja_p4`: solo asoma la espada) | la regla «lo de ≤ 0,6 m no tapa» (`trazado_comun.fino`): los pilares no eran ocultables y ni la escena ni las pruebas los miraban; Kael mide unos 0,5 m de ancho en pantalla y un pilar más cerca de la cámara se ve más ancho | `trazado_comun`: los finos que llegan al pecho (`fino_alto`: pilares, postes, troncos y lo pequeño colgado, faroles y tablillas) son ocultables: la escena los aclara cuando cortan un rayo a Kael o al grupo, cerca o lejos; `tapan()` (plano y recorrido) cuenta los finos a menos de `FINO_CERCA` = 2 m de Kael. Ocultables por sector: como mucho 59 de 64 (plaza) | **arreglado**: el pilar se aclara (`r01`, `r03` soportal) |
| 2 | Medio Kael tapado de lado por el canto de un parterre/pretil del Barrio Alto (`t10_escalinata.png`) y por un pilar del pórtico (`t13_alto_norte.png`, `antes_recarga.png`: media Lya) | sí: Kael pegado a la jardinera de la Rampa de las Raíces (`r04`) y al pilar del pórtico (`r07`); media Lya tras el pilar (`r06`). `diag_ciudad_silueta`: en **4 442** de 189 019 casillas andables la escena dejaba tapado ≥ 40 % del torso | Kael choca como un PUNTO: pegado a una pared, media figura queda dentro del bloque (y de lado, desde la cámara, tapada); el grupo solo tenía rayos al centro | Kael tiene CUERPO: `Comun.RADIO_CUERPO` = 0,3 m junto a lo sólido que sube más de 1 m sobre su suelo (`ALTO_PARED`) y no es fino (`plano.holgura/holgado`; `ciudad._altura_suelo` no deja meterse en esa franja, sí salir de ella; `_ajustar_destino` lleva el toque al último punto de la recta donde cabe). Lo bajo (bancos, parterres, el pilón, pretiles de 0,9, el puesto del tonelero) y los finos (se aclaran) no tienen franja; desde la Puerta del Sur, con su cuerpo, Kael sigue llegando junto a todas las anclas, puertas y conexiones (prueba_ciudad_plano 8d: 93,4 % de las casillas andables tienen sitio para él, todas conectadas). El grupo, rayos también a sus lados (±0,25 m a 0,8 y 1,4) | **arreglado**: `diag_ciudad_silueta` después, **35** de 176 611 casillas donde Kael cabe (carros de 1,5 m justo delante, la columna de la fuente [C], un caño y el tablón: tapan como cualquier cosa delante); la Lya del pórtico se ve (`r06`) |
| 3 | El rótulo del sector enorme y cortado en el Barrio Alto y al pie de la escalinata, en bajo y en alto | sí: «Barrio Alto de las Raíces (maqueta)» a 13,6-16,9 m de la cámara con el 36-42 % del ancho de la pantalla (`r05`, `r06`, `r07`, `r12`); el de la plaza, 30-35 % (`r13`, `r14`) | ocultarlos a menos de 10 m de la cámara no basta: la cámara está a unos 18 m de Kael (10,8 arriba y 14,2 al sur), así que con Kael cerca del ancla el rótulo (6,5 m sobre ella) queda a 13-17 m y mide 7-8 m de ancho | `sector._rotulo`: el rótulo del sector se dibuja solo desde la distancia a la que su ancho ocupa como mucho `ROTULO_PANTALLA` = 1/4 del ancho del cuadro (cámara de la ciudad, 38° en 16:9; ancho con la fuente del rótulo), nunca a menos de 10 m: el del Barrio Alto, desde ≈ 29-31 m; el de la plaza, ≈ 34-36 m. Los «(en obras)», todos desde 10 m, como antes (corrección del 18/11: en la primera versión la regla se aplicaba también a ellos y 19 de 85 rótulos de puerta largos, como la taberna o la botica, dejaban de verse ante su puerta; `sector.inicio_rotulo` y una comprobación en `prueba_ciudad_cargador`). El título de la pantalla ya dice el sector | **arreglado**: en los 14 sitios, bajo y alto, ningún rótulo de sector a menos de ≈ 29 m; los «(en obras)» que se ven, ≤ 15 % del ancho |
| 4 | La fuente corta el camino directo de la Calle Mayor a la escalinata y con toques Kael se queda pegado al pilón | sí: de (0, 28) tocando la Calle del Árbol, Kael se para ante el pilón a 16,8 m (`r13`); de este a oeste, a 12,3 m (`r14`) | `_ajustar_destino` cortaba el toque en lo primero que no se pisa (el pilón) y `vista3d` no rodea | la solución menos invasiva, sin tocar el trazado ni la fuente [C] en el centro: con TOQUES Kael RODEA lo que corta el paso. `_ajustar_destino` deja el destino detrás de un obstáculo bajo (≤ 1,5 m y ≤ 8 m de largo) o pequeño (≤ 2 × 2 m) si detrás hay suelo a la misma cota; `ciudad._bordear`: si `vista3d` no avanza y lo que frena es un bloque, Kael anda a lo largo de su cara (apartándose hasta 0,5 m de ella) hacia la esquina por la que se llega antes y conserva el destino; como mucho 4 s por destino (no busca caminos: tras una pared larga, o tocando dentro de una casa, se para como antes) | **arreglado**: llega a 0,02 y 0,11 m (`r13`, `r14`) |
| 5 | `diag_ciudad_romper.gd`: 3 fallos de «Guardar y recargar» (también en `2afc6ed`) | sí, los 3 (`romper_recargas_antes\`): en el borde del Paso de la Botica y de la Calle del Cuervo, Kael «reaparece» 0,3-0,4 m al otro lado de la linde, y recargando andando, 1,0 m más allá | Kael seguía andando: el guardado era al SOLTAR el botón y Kael seguía hacia su destino entre el toque y la suelta (y, ya guardado, bajo el negro de la carga); la herramienta comparaba con su sitio de antes de mover el puntero. Lo guardado y lo que reaparecía eran iguales (0,00 m) | la escena para a Kael al TOCAR el botón (`button_down` → `_parar_kael`) y no lo mueve más hasta que se va (`_recargando`); `recorrido_ciudad._recargar` compara con el sitio de Kael al tocar el botón | **arreglado**: `romper_recargas_despues\`, 5 recargas y 0 fallos (reaparece a 0,00 m de donde se tocó) |

Lo que se encontró por el camino y se arregló (ninguno estaba en `2afc6ed`: salieron de los propios arreglos y los cazó
el recorrido en tres pasadas intermedias, `recorrido_1600x720_pasada1..3\`):

- con el rodeo, al doblar la esquina de un banco bajo, un tramo de 0,15 m podía cortarla (Kael «pisaba» el banco del
  mirador del pretil): `_altura_suelo` mira ahora el tramo entero cada 5 cm;
- tocando JUNTO al pilón (el pie de la escalinata), el rodeo movía a Kael de lado hasta 4 s: solo rodea si el destino
  está DETRÁS de la cara que lo frena;
- con la franja en lo que sube 0,8 m y en los pilares finos, el puesto del tonelero (0,85 m) y el pilar 4 cerraban el
  soportal del Cuervo (deja 0,6 m entre ellos): la franja es para lo que sube más de 1 m y no para los finos (se aclaran);
- la herramienta: buscaba sitios «bajo la cubierta» dentro de la franja del cuerpo (`_bajo_cubierta` busca primero
  donde Kael cabe: con 0,6 m entre el borde del toldo de la fruta y su mostrador, Lya acababa dentro del puesto mientras
  Kael lo intentaba 52 veces), su rejilla A* quita la franja y su recta mira la holgura solo en lo que se anda de un toque.

### Comprobaciones

Pasadas finales (perfil bajo, 1600×720, `--fixed-fps 30`, con ventana, en el PC, cada una con su carpeta de datos; las
tres a la vez, con el código de la rama):

| Comprobación | Antes (`70b5f82`) | Después |
|---|---|---|
| `recorrido_ciudad.gd` | 430 tramos, 0 fallos (§7) | **430 tramos, 0 fallos**; lo mismo cubierto (8/8 sectores, 24/24 sentidos, 50 + 50 pendientes, 44 cubiertas, 85 puertas, 13 sin salida, 9 atajos, 8 recargas); 0 botones repetidos; 4 avisos de 1-3 fotogramas del grupo rozando una esquina o un borde (antes 2; §5, problema 3) |
| `diag_ciudad_visibilidad.gd` | 438 tramos, 0 casos | **438 tramos, 0 fallos, 0 eventos**; cámara sin saltos (el mayor, 0,36 m); Kael siempre en el cuadro |
| `diag_ciudad_romper.gd` (entero) | 3 fallos de «Guardar y recargar» (4 con `2afc6ed`) | **94 tramos, 0 fallos, 0 hallazgos**: rejillas de toques sin toques perdidos, salidas, clics rápidos, arrastre, teclas, recargas difíciles, 4 ciclos banco/ciudad y CAL sin fugas (huérfanos 0), vigía del cargador sin errores |
| `diag_ciudad_romper.gd recargas` | 5 recargas, **3 fallos** | 5 recargas, **0 fallos** (reaparece a 0,00 m de donde se tocó el botón) |
| `diag_ciudad_silueta.gd` (sin ventana) | 4 442 casillas con ≥ 40 % del torso tapado | **35** (carros, columna de la fuente, caño y tablón) |
| `fotos_ciudad_optimiza.gd sitios=redmi` (bajo y alto) | pilar de la lonja sin aclarar, media Lya tras el pilar, rótulos del 30-42 % del ancho, la fuente para a Kael a 16,8 y 12,3 m | pilares aclarados, Lya entera, ningún rótulo de sector cerca (los «(en obras)», ≤ 15 %), la fuente se rodea (llega a 0,02 y 0,11 m) |
| Pruebas (`-Solo prueba_ciudad_plano,prueba_ciudad_cargador`) | plano 64 OK, cargador 106 OK | **SUPERADAS 2 · FALLIDAS 0** (`D:\REBELUM_diagnostico\pruebas\2026-11-18_005621`; plano 68 OK con 8b-8d, cargador 115 OK con las 9 del Redmi; partida real, carpeta real y proyecto sin cambios) |

No se ha pasado a 1280×720 (en §3 y §7 daba las mismas líneas que a 1600×720) ni en los perfiles medio y alto (solo
las capturas de los 14 sitios en alto).

### Capturas

Fuera del repositorio, en `D:\REBELUM_diagnostico\pendientes_17_11\ciudad_redmi\`: `fotos_antes_bajo\`, `fotos_antes_alto\`
(con `70b5f82`), `fotos_despues_bajo\`, `fotos_despues_alto\` (los 14 sitios, misma cámara) y `antes_y_despues\`
(28 láminas, izquierda antes y derecha después); `silueta_antes\` y `silueta_despues\`; `romper_recargas_antes\` y
`romper_recargas_despues\`; `recorrido_1600x720\`, `visibilidad_1600x720\` y `romper_1600x720\` (las pasadas finales,
sin vídeo) y las intermedias `*_pasada1..3\` (con los fallos que llevaron a los arreglos de arriba).

### Pendiente

- Probarlo en el Redmi con el dedo (sin teléfono hoy): el rodeo de la fuente, el cuerpo junto a pilares y jardineras,
  los rótulos y «Guardar y recargar» andando.
- Los carros de 1,5 m, la columna de la fuente [C], el caño del pilón de caravanas y el tablón del Gremio siguen tapando
  el torso de Kael si se pone justo detrás (como cualquier cosa delante): si molesta en el teléfono, ponerlos en
  OCULTABLES de su trazado (agentes A y B).
- El rodeo no busca caminos (4 s como mucho, una cara tras otra): tras una pared larga o un recodo cerrado, Kael se para
  como antes. Con teclas, `_deslizar` sigue igual.
- El grupo (`grupo_3d.gd`, compartido, sin tocar) sigue rozando esquinas 1-3 fotogramas (4 avisos por pasada) y, si
  Kael da muchas vueltas pegado a un mostrador, Lya pudo acabar dentro de él (pasada intermedia 1, ya no se repite con
  la herramienta arreglada): mirarlo si se ve en el teléfono.
- Rendimiento sin medir: el aclarado mira ahora hasta 21 puntos (Kael y dos del grupo) y hasta 59 ocultables por sector
  (plaza), con el descarte por caja; `_altura_suelo` consulta la holgura (los bloques de 1-2 sectores) en cada tramo.
