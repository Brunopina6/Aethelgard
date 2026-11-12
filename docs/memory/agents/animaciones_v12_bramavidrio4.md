# Animaciones (y modelado), V12: Bramavidrio versión 4, «el Ancestral»

## 12/11/2026, 12:25-13:50 · rama `claude/v12-bramavidrio4` (LOCAL, nace de `claude/rebelum-v12` @ `a23e131`)

**Encargo:** llevar a 3D, animado y con la mayor fidelidad posible, el gusano de la lámina que aportó el usuario
(`D:\REBELUM_diagnostico\v12\referencias\bramavidrio_v4_referencia_usuario.png`, copia de «Concepto del gusano de arena
ancestral.png», SHA-256 `3a6044c0…a904c5d18`, comprobado). Boca circular sin mandíbula, chorro desde la garganta, los
tres ataques con el mismo contrato, niveles de detalle y comparación por etapas frente a la lámina. Copia
`D:\Aethelgard_v12_bramavidrio4`. Sin push, sin merge, sin ADB.

**Procedencia:** la lámina es una **referencia aportada por el usuario**; no sé su licencia y no la invento: la registro
así. El modelo, la textura, el esqueleto y los clips son **procedurales, generados por mi guion** con Blender 5.2.3
(`fuente/crear_bramavidrio4.py`); no se ha copiado ni recortado nada de la lámina dentro del juego (solo se usa en las
hojas de comparación, fuera del proyecto). **No he usado Hunyuan3D** (ni ningún generador de modelos): el aviso del
coordinador llegó a mitad del trabajo y no había nada que descartar.

**Estado:**
- La v4 está hecha, integrada y probada en el PC (aislado). **No es la de por defecto:** `VERSION_DEFECTO` sigue en 2. Se
  elige en Ajustes → «Bramavidrio» → «Prueba v4: el Ancestral» (`[bramavidrio] version = 4`), o con
  `bramavidrio_version=4` / `Engine.set_meta("bramavidrio_version", 4)`.
- La v1, la v2 y la v3 no se han tocado (archivos intactos; sus pruebas, superadas con el combate cambiado).
- **Nada se ha probado en el Redmi** y **no he medido rendimiento** (había 4-8 Godot de otros especialistas abiertos).

### Commits (rama local, sin push)

| Commit | Qué |
|---|---|
| `d3b5614` | `fuente/crear_bramavidrio4.py`, el generador |
| `44c31d3` | `enemigos/bramavidrio/v4/`: los tres GLB, las tres texturas WebP (con sus `.import`) y `bramavidrio4_clips.json` |
| `464b8f7` | `v4/bramavidrio4_3d.gd`, los 4 sombreadores (con sus `.uid`), `bramavidrio_version.gd` (versión 4) y `menus.gd` (la opción) |
| `c912de5` | `combate_bramavidrio.gd`: el chorro y la succión desde la garganta (`_origen_chorro`) |
| `9495883` | la Fractura más baja y corta (GLB regenerados), `prueba_bramavidrio_modelo.gd` (v4), `fotos_bramavidrio_pulido.gd`, `lista_pruebas.txt`, `fuente/hoja_referencia_bramavidrio4.py` |
| (este) | este informe y `DEPURAR = False` en el generador |

**Para integrar copiando:** `aethelgard/enemigos/bramavidrio/v4/*` (todo), `aethelgard/fuente/crear_bramavidrio4.py`,
`aethelgard/fuente/hoja_referencia_bramavidrio4.py`, `aethelgard/enemigos/bramavidrio/bramavidrio_version.gd`,
`aethelgard/menus.gd` (solo el bloque «Bramavidrio», 3 líneas), `aethelgard/combate_bramavidrio.gd` (las 5 sustituciones
de `_boca()` por `_origen_chorro()` en la succión y el chorro, el ancho de salida y las dos funciones nuevas antes de
`_boca()`; 24 líneas), `aethelgard/pruebas/prueba_bramavidrio_modelo.gd`, `aethelgard/pruebas/fotos_bramavidrio_pulido.gd`
(una línea) y `aethelgard/pruebas/lista_pruebas.txt` (la nota de `prueba_bramavidrio_modelo`). **No cambian:** `combate.gd`,
`gusano.gd`, `recursos.gd` (la precarga ya filtra por la carpeta de la versión en uso), sonidos ni zonas.

**Ojo al importar:** `--import` vació los directorios de Dialogic en `project.godot` (como avisó el coordinador); lo
restauré con `git restore` y reimporté. `project.godot` no está en ningún commit.

## 1. Lo que conserva de la lámina y cómo se ha hecho

- **Cuerpo:** una sola piel continua (carne rojiza estriada, vientre de anillos rosados con surcos rojos), gruesa (radio
  1,84-1,95 m) y que se estrecha en el último tercio hasta una punta cónica acorazada. 22 m de cuerpo + 3,6 m de cabeza:
  proporción largo/grosor ≈ 6,6 (la lámina, ≈ 6,4).
- **Placas superpuestas como tejas:** en cada anillo, una dorsal ancha con chevrón atrás que se monta sobre la siguiente y
  dos laterales más cortas con pico hacia abajo, que dejan ver la carne rojiza entre anillos. Cantos de bronce, arista
  central, picaduras y grietas, **runas doradas que brillan** (alfa de la textura, ámbar) y **zarpazos rojos** (tres
  cortes paralelos) en algunas losetas. Más pequeñas hacia la cola.
- **Crestas dorsales:** once cuchillas de hueso curvadas hacia atrás (2,7 m las grandes, 0,4 m en la cola) con una
  **vela de carne rojiza** entre su borde de atrás y el lomo (pesos repartidos: se estira al erizarse).
- **Cabeza acorazada** (1,35 veces más ancha que el cuerpo): dos cuernos grandes que se abren y se curvan hacia atrás,
  dos medianos a los lados, dos pequeños atrás y dos bajos; la **testera** en rombo con el **núcleo ámbar** (gema
  facetada en un engaste de bronce, brilla con el hueso «brillo»); placas de la cabeza hacia el collar y un **marco** de
  siete placas en punta alrededor de la boca.
- **Boca circular enorme:** collar de bronce, un rodete grueso de carne (los labios de la lámina), labios en embudo (38°)
  con pliegues concéntricos y arrugas radiales, **tres coronas de dientes curvos** (26 del collar, 12 colmillos de los
  sectores y 45 en tres filas del embudo) y la **garganta** al fondo: un túnel con luz mineral ámbar que se enciende con
  el hueso «garganta».
- **Sin brazos ni patas.**

## 2. Lo que la lámina no enseña: decisiones (documentadas)

1. **La boca cerrada.** La lámina solo la enseña abierta. Un cierre por pétalos (que tapen un hueco del radio de la boca)
   o sobresale como un pico de 1,4 m o, abierto, se hace una flor el doble de ancha que la cabeza; las dos cosas cambian
   la forma de la cabeza, que el encargo pide conservar. Así que es un **esfínter**: el collar, el marco, los cuernos y
   los dientes del collar y del embudo son fijos; los labios se fruncen hacia el centro (contracción radial: el borde de
   dentro va al eje y el de fuera se queda) y avanzan 0,85 m en un frunce; los doce colmillos de los sectores se inclinan
   hacia delante y se cruzan sobre los labios como una trampa. La silueta de la cabeza no cambia.
2. **Sin ojos.** La lámina no enseña ojos; el núcleo ámbar de la frente hace de mirada y brilla.
3. **El vientre:** anillos rosados con surcos rojos (lo que se ve en la vista principal, bajo el cuerpo); en la vista de
   frente con el gusano erguido queda delante, más rojo que en la lámina.
4. **La punta de la cola:** placas cada vez menores y la punta acorazada, sin la carne.
5. **Lo enterrado / la emersión:** sale del agujero como las otras versiones (el contrato lo exige); bajo la arena asoman
   las crestas y los cuernos.
6. **El interior:** embudo de 2,45 m con tres filas de dientes, luego la garganta encendida y cerrada al fondo (no se ve a
   través de la cabeza).
7. **Colores:** los de la lámina (arena, piedra y bronce, carne rojiza, luz ámbar), algo menos saturados que la primera
   prueba porque bajo el sol del combate se iban a naranja.

## 3. Rig, boca y medidas (comprobado en Blender y en Godot)

**Esqueleto de 61 huesos:** raiz, col_01…col_18, cabeza, **esfinter** (escala en el plano de la boca y avance),
**labio_01…labio_12** (los sectores), garganta (luz), **garganta_ancla** (el anclaje del chorro), chorro, succion, brillo,
monticulo, placa_02…placa_17 (crestas y armadura, se erizan) y losa_1…losa_6. Spline IK de la columna y horneado de la
v3 (copia literal; clips con claves en cada fotograma).

**Sectores sin piezas sueltas:** la base de cada colmillo va EXACTAMENTE adonde va el labio debajo de ella (la misma
mezcla cabeza/esfínter de su peso, 0,317), y el colmillo gira sobre el eje tangente del anillo (30° hacia dentro abierta,
50° cerrada). Medido en Godot fotograma a fotograma en los 10 clips: **holgura máxima 1,0 mm** (muestreo del clip).

**Intersecciones (BVH sobre la malla deformada, en Blender):** colmillos entre sí, colmillos con labios, con los dientes
fijos y con la cabeza; dientes fijos con labios. **0 pares** en 41 instantes de 8 clips (reposo, rugido, embestida,
Fractura, Aliento, herida, derrota y emersión), en el alto (`bramavidrio4_clips.json`, «intersecciones»). No cuentan las
bases de los dientes (metidas en la carne a propósito). Hubo tres causas que corregí por el camino: anillos de la base de
los dientes por debajo del labio, un diente del embudo que el esfínter rozaba y **pesos mal puestos en las placas de la
cabeza** (las de delante cogían pesos del cuello; un error mío de signo en `placas_cabeza`, demostrado con las
posiciones deformadas).

**Esfínter:** contracción radial monótona para toda apertura (paso mínimo 1,3 mm > 0: sin pliegues). Cerrada, la entrada
mide 1,8 cm de radio; abierta, 0,9 m. Reposo: cerrada en todo el bucle. Apertura máxima por clip (grados nominales,
60 = la lámina): rugido 67, Aliento 66, Fractura 62, embestida 57, derrota 52, emersión 34, herida 18. En el mordisco
(1,0 s) cerrada.

## 4. El chorro sale de la GARGANTA

- **En el modelo:** el hueso `garganta_ancla` está dentro de la garganta, 2,3 m detrás del plano de la boca, en su eje;
  hijo de «cabeza», así que sigue la animación, la orientación y la escala. El chorro 3D (hueso «chorro», con la cabeza
  en el mismo punto) nace ahí, va por el eje del embudo (más estrecho que él: no cruza dientes ni labios) y se abre al
  salir; ahora se ve también en el combate (va por dentro, no hacia la cámara como el de la v1-v3).
- **En el combate** (`combate_bramavidrio.gd`): `_origen_chorro()` proyecta `origen_chorro()` con la cámara del combate si
  el modelo lo tiene; si no (v1, v2, v3), `_boca()` como siempre. Lo usan la succión (la arena converge al interior de la
  boca, con la luz ámbar de la garganta ahí), su seguimiento, la dirección de salida y la banda del chorro, que en la v4
  nace estrecha (12 % del ancho) y se abre al salir. Daño, objetivos, estados y tiempos no cambian.
- **En la descarga el gusano gira la cabeza hacia la cámara** (−48° → −38°) para que la boca se vea de frente.
- **Medido:** en Blender (rayo desde el anclaje hacia la cámara hasta el plano de la boca): ángulo con la vista ≤ 28°,
  el anclaje cae al 53 % del radio del collar y al 62 % del de la entrada del embudo. En Godot
  (`prueba_bramavidrio_modelo`, `_comprobar_boca4`): el origen proyectado cae **dentro del collar y dentro de la entrada
  en los 23 fotogramas de la descarga** (peor: 0,58 del radio) y el chorro 3D nace en el anclaje en los 23.
- Fotos del combate real: `combate_v4_*\v4_*_aliento_2_descarga.png` y `_3_barrido.png`.

## 5. Clips y contrato (los mismos 10, instantes y señales que la v1-v3)

reposo, subterraneo, aviso, emerger, rugido, ataque, ataque_sismico, ataque_aliento, herida, derrota; señales
`placas_suelo` y `fin_succion`; los instantes del contrato caen en su fotograma (ajuste automático del generador:
`emerger_ua` −3,8, `derrota_dz` −0,6, `sismico_dz` 2,115). Reposo: la cabeza a 9,09 m de alto y 9,36 m por delante del
agujero (la v2: 9,03 y 9,42, así que los sitios de golpe de `combate.gd` le valen).
- **Embestida:** se recoge con la boca cerrada, fija temblando, se lanza abriendo la boca entera y la cierra de golpe en
  el impacto (1,0 s; el mordisco del esfínter), sacude dos veces y vuelve. Alcance 11,19 m.
- **Fractura (rediseñada con lo aprendido en el pulido):** la ventana 3D del combate solo llega a unos 12,5 m; erguido
  se queda por debajo (altura máx. 12,4 m incl. margen; la v3, 21,8) y cae **delante** de los héroes (alcance 11,56 m;
  la v3, 18,2). `prueba_bramavidrio_modelo`: la Fractura ya no se sale de la ventana 3D (0 puntos; la v3, 32). En el
  combate real la boca y el cuello se ven en el aviso (lo alto de la cabeza aún toca el borde de la pantalla) y en el
  impacto la cabeza da en la arena a la izquierda de Garon, sin taparlo.
- **Aliento:** abre la boca, aspira (arena en cintas hasta dentro de la boca, garganta encendida), se recoge, y en la
  descarga vuelve la cabeza hacia la cámara con la boca abierta de más; el chorro sale de la garganta.
- **Rugido, emersión, herida, derrota:** con el cuello, las crestas (se erizan 45° al rugir), la luz y la boca; nada de
  desplazar el modelo entero.

## 6. Niveles de detalle (medidos)

| Nivel | Triángulos (presupuesto) | GLB | Textura WebP |
|---|---|---|---|
| alto | 13 659 (≤ 18 000) | 3,05 MB | 2048, 437 KB |
| medio | 7 146 (≤ 8 000) | 2,70 MB | 1024, 173 KB |
| bajo | 3 474 (≤ 3 500) | 2,46 MB | 512, 60 KB |

Los tres conservan cabeza, boca, colmillos, cuernos y silueta; lo que baja es lados del cuerpo, filas de las placas,
dientes del collar y del embudo (el bajo, 2 filas en el embudo), crestas (una de cada dos en el bajo) y velas. El detalle
secundario (runas, zarpazos, grietas, pliegues de la boca) está en la textura. **No he hecho mapa de normales**
(pendiente: costaría 1-4 MB de VRAM más; lo dejo para cuando se mida en el Redmi). El GLB pesa sobre todo por los clips
(61 huesos × 10 clips × claves en cada fotograma, como la v3).

## 7. Pruebas (aisladas; partida, carpeta real de datos y proyecto sin cambios en todas)

- Con `bramavidrio_version=4`: `prueba_bramavidrio_modelo` (las CUATRO versiones), `prueba_bramavidrio_combate`,
  `prueba_climax_jefe` y `prueba_audio_bramavidrio`: **4 SUPERADAS** (`D:\REBELUM_diagnostico\pruebas\2026-11-12_132404\resumen.md`).
- Con v1, v2 y v3 (combate, clímax y audio, con el `combate_bramavidrio.gd` cambiado): **3 SUPERADAS cada una**
  (`2026-11-12_132504`, `_132555` y `_132649`).
- `prueba_bramavidrio_combate` con la v4: los tres ataques con un impacto y su sonido una vez, avisos, defensa, corte del
  Aliento, guardado del premio (A2: sin premio la segunda vez), derrota, salir aspirando y el orden de dibujo (≤ 2 cambios
  por héroe y turno).
- Herramienta con ventana `fotos_bramavidrio_pulido` (combates que corren) en alto, medio con `movil` y bajo con `movil`:
  `FALLOS: 0`, limpieza correcta (0 efectos, 0 nodos huérfanos, bucle de la succión callado). Orden de dibujo en los
  ataques del gusano: **0 fotogramas mal** (queda_detras y tapa_mal) en los tres perfiles. Cuando atacan los héroes, 7-9
  fotogramas de 2 000 con Lya pintada encima de la boca al saltarle a la cara (el combate solo reordena mientras ataca el
  gusano; le pasa igual a cualquier versión y no es de la v4).
- **Batería completa** (al final, con todo confirmado salvo este informe): **132 SUPERADAS · 0 FALLIDAS · 60 MANUALES · 0 NO
  SEGURAS**; partida, carpeta real de datos y proyecto sin cambios (`D:\REBELUM_diagnostico\pruebas\2026-11-12_132806\resumen.md`;
  había hasta 67 Godot de otras copias abiertos y la pasada lo apunta). Las carpetas `2026-11-12_133526` y `_133605`
  (`prueba_encuentro_desierto` FALLIDA) **no son mías**: son de otro especialista que trabaja a la vez.
- `prueba_mar_cristal` con `bramavidrio_version=4` (la exploración: aviso, huida y emersión con la v4): **SUPERADA**
  (`2026-11-12_134442`).

## 8. Evidencias (`D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio4\`)

- **Hojas por etapa frente a la lámina** (arriba recortes de la lámina con franja ocre; abajo el modelo con franja gris):
  `comparar_referencia_etapa_1.png` (silueta y proporciones, en arcilla: frente, perfil, 3/4, espalda),
  `_2` (cabeza, boca y garganta: abierta, a medias, cerrada, interior y perfil de la cabeza), `_3` (materiales: las
  cuatro vistas y los detalles corona, placas con runas y zarpazos, cresta con vela y cola), `_4` (rig y deformaciones:
  la boca de 0 a 112 %, el cuerpo en S y las crestas erizadas), `_5` (los clips con tres muñecos a la escala de los
  héroes) y `_6` (Godot, el combate real: reposo, embestida, aviso e impacto de la Fractura, succión, descarga y barrido
  del Aliento, derrota; y reposo y descarga en medio y bajo con `movil`).
- `blender\`: todas las fotos sueltas y **los vídeos** (FFmpeg de Blender, 30 fps): `v4_boca_rugido.mp4` (la boca se abre y
  se cierra de cerca), `v4_aliento_garganta.mp4` (el Aliento con el origen del chorro bien visible) y
  `v4_aliento_combate.mp4` (el Aliento desde la vista del combate con los muñecos).
- `combate_v4_alto\`, `combate_v4_medio_movil\`, `combate_v4_bajo_movil\`: unas 32 fotos de combate real cada una y su
  `registro.txt` (orden de dibujo y limpieza).
- `blend\bramavidrio4.blend`: el `.blend` fuente (también en la carpeta temporal de la sesión). Se regenera con
  `blender -b --factory-startup -P fuente/crear_bramavidrio4.py -- aethelgard/enemigos/bramavidrio/v4 alto,medio,bajo [<.blend>] [<carpeta de fotos>] [1,2,3,4,5,video]`
  (unos 25 s sin fotos; las fotos y los vídeos, unos 10 min).

## 9. Diferencias que quedan con la lámina (no es «exacto»)

- **Detalle y modelado:** la lámina es una ilustración muy esculpida (placas abombadas con relieve, carne con volumen,
  cientos de dientes); el modelo es procedural y de presupuesto móvil: placas finas de formas regulares, dientes cónicos
  simples (83 en el alto) y la carne pintada en la textura, sin relieve ni mapa de normales.
- **Boca:** la lámina tiene filas de dientes más densas y una espiral de luz naranja al fondo; aquí son tres coronas y una
  luz ámbar redonda. Los doce colmillos de los sectores, de frente, se leen algo como los radios de una rueda.
- **Corona:** la de la lámina es más alta y recargada (una cresta central y cuernos más gruesos y curvos); la mía es más
  sobria y los cuernos de arriba algo rectos. Las placas del marco de la boca son más pequeñas que las de la lámina.
- **Crestas:** en la lámina son más anchas, curvas y con la vela más grande y dorada; las mías son más finas y regulares.
- **Postura:** la lámina enseña el cuerpo ondulado y casi tendido; en el juego sale del agujero (contrato de los clips).
- **Proporciones:** largo/grosor y cabeza/cuerpo parecidos (6,6 y 1,35; la lámina ≈ 6,4 y ≈ 1,3-1,4).
- **Color:** en el combate, con el sol del desierto y el borde de luz, la armadura sale más naranja que en la lámina.

## 10. Límites (lo que no he podido comprobar)

- **Redmi:** nada (sin ADB, por encargo). Triángulos y texturas dentro del presupuesto; el coste de la boca es de 13 huesos
  más que la v3 (61 frente a 56), sin IK en tiempo de juego.
- **Rendimiento y memoria en el PC:** no medidos: durante todo el trabajo había 4-8 Godot de otros especialistas abiertos
  (lo dice cada resumen). Pido al coordinador que lo programe sin otra carga.
- **Sonido:** medido (`prueba_audio_bramavidrio`), no escuchado. No hace falta ningún sonido nuevo.
- **Exploración (Mar de Cristal) con la v4:** pasa `prueba_mar_cristal`, pero no he sacado fotos de la región con la v4
  (la herramienta `fotos_bramavidrio` no la tiene en su lista de versiones).
- **El aviso de la Fractura:** la boca y el cuello se ven, pero lo alto de la cabeza y los cuernos rozan el borde de
  arriba de la pantalla (el agujero está pegado al borde izquierdo).
- **Vídeo del combate de Godot** (`--write-movie`): no lo he grabado; los vídeos son de Blender y el combate de Godot está
  en fotos de combates que corren.

## 11. Siguiente paso y peticiones

1. **Coordinador:** integrar copiando los archivos de arriba y pasar la batería.
2. **Usuario:** mirar `comparar_referencia_etapa_2.png`, `_3`, `_6` y los vídeos y decir si la boca cerrada (esfínter) y
   la corona van por buen camino. Siguientes mejoras si se aprueba: más filas y dientes más curvos en la boca, la espiral
   de luz en la garganta, la cresta central de la corona y crestas más anchas (todo en el generador, sin tocar el rig ni
   el contrato).
3. **Medición en el Redmi** (coordinador): el combate con la v4 en bajo y medio, y la decisión sobre el mapa de normales.
4. **`docs/recursos.md` (no es mío):** la fila que pido:
   `| Bramavidrio v4 «el Ancestral»: enemigos/bramavidrio/v4/* | Modelo, textura, esqueleto y clips generados con Blender 5.2.3 por fuente/crear_bramavidrio4.py a partir de la lámina de referencia aportada por el usuario («Concepto del gusano de arena ancestral.png», SHA-256 3a6044c0…a904c5d18; licencia de la lámina sin registrar) | Propia (la lámina: referencia del usuario) | Combate fijo «mc_bramavidrio» y exploración del Mar de Cristal (si se elige la versión 4) | Sí |`
5. **Narrativa:** la v4 no tiene ojos y tiene un núcleo ámbar en la frente; conviene que lo revise antes de hacerla la de
   por defecto (no revela nada del acto III).
6. **`combate.gd` (no es mío):** nada imprescindible. Si se quiere que el combate reordene también cuando atacan los
   héroes, sería llamar a `ordenar_en_combate` del modelo durante `_anim_salto_3d`/`_anim_fisico_3d`; no lo he propuesto en
   detalle porque afecta a todas las versiones.
