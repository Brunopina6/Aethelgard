# Animaciones, V12: Bramavidrio pulido (sin reconstruirlo)

## 12/11/2026, 10:40-11:50 · rama `claude/v12-hito-brama-pulido` (LOCAL, nace de `claude/rebelum-v12` @ `a0bab37`)

**Encargo:** pulir Bramavidrio desde la cámara real del combate (combate fijo `mc_bramavidrio`, grupo 13, Kael, Lya y
Garon con la interfaz; perfiles bajo, medio y alto) sin crear modelos nuevos: las tres versiones (v1, v2 por defecto y
v3 «el Excavador») y sus variantes siguen elegibles; `VERSION_DEFECTO` sigue en 2. Copia
`D:\Aethelgard_v12_brama_pulido`. Sin push, sin merge, sin ADB, sin sonidos nuevos.

**Método:** una herramienta nueva, `pruebas/fotos_bramavidrio_pulido.gd`, juega combates de verdad QUE CORREN (no
congelados, con ventana y datos aislados) con la versión y el perfil pedidos, saca fotos en los instantes de cada ataque
y mide en CADA fotograma el orden de dibujo frente a cada héroe con los huesos del modelo (cabeza, mandíbula, cuello y
garras) proyectados con la cámara del combate y su sombra en la arena. Apunta:
- `queda_detras`: el gusano se dibuja detrás de un héroe aunque un tramo que cae sobre su figura está más cerca de la
  cámara que sus pies;
- `tapa_mal`: lo tapa con tramos que están detrás;
- `cambios`: cuántas veces pasa de detrás a delante de cada héroe (o al revés): un parpadeo sube la cuenta.

Además: la limpieza al acabar (efectos, cartel, succión, marca, el bucle de la succión al cortarlo y al cerrar el combate
a medias, nodos huérfanos) y, con `giros=`, dónde cae la Fractura.

Todo lo de abajo está **comprobado ejecutando** en el PC (aislado: `APPDATA`/`LOCALAPPDATA` de mi carpeta temporal o
`ejecutar_pruebas.ps1`), salvo lo marcado como observado en el código o pendiente. **Nada en el Redmi**, nada de
rendimiento medido y **nada escuchado** (solo medido).

### Commits (rama local, sin push)

| Commit | Qué |
|---|---|
| `ce4f8d7` | `enemigos/bramavidrio/v3/bramavidrio3_3d.gd` (`ordenar_en_combate` corregido, `fin_orden_combate`) y `combate_bramavidrio.gd` (3 líneas en `_al_frente(false)`) |
| `ce90cf3` | `pruebas/prueba_bramavidrio_combate.gd` (parpadeo, bucle al cerrar, partes H e I) y `pruebas/fotos_bramavidrio_pulido.gd` (nueva) |
| `44594bb` | `MARGEN_DELANTE` con nombre (mismo valor), la medida «sombra-pies» en la herramienta y `pruebas/lista_pruebas.txt` (2 líneas) |
| `0e39c8e` | `pruebas/fotos_bramavidrio3.gd`: cada pose ordena sin lo que tapaba la anterior |
| `0790031` | `pruebas/lista_pruebas.txt`: repara la línea de `prueba_bramavidrio_combate` |
| (este) | este informe |

**Para integrar copiando:**
- `aethelgard/enemigos/bramavidrio/v3/bramavidrio3_3d.gd`;
- `aethelgard/combate_bramavidrio.gd` (si ha cambiado en la V12, solo el bloque «pulido, 12/11» de `_al_frente`, 3 líneas);
- `aethelgard/pruebas/prueba_bramavidrio_combate.gd`, `aethelgard/pruebas/fotos_bramavidrio_pulido.gd` (Godot crea su
  `.uid` al importar) y `aethelgard/pruebas/fotos_bramavidrio3.gd`;
- `aethelgard/pruebas/lista_pruebas.txt` (la línea de `prueba_bramavidrio_combate` y la nueva de `fotos_bramavidrio_pulido`);
- este informe.

**No cambian:** los GLB, las texturas, los clips, `bramavidrio_version.gd` (`VERSION_DEFECTO` = 2), `combate.gd`,
`gusano.gd`, `sonido.gd`, `zonas3d/mar_cristal/*` ni los sonidos.

## 1. Lo que fallaba y está corregido: el orden de dibujo de la v3 en combates que corren

**Síntoma** (`antes\v3_medio_movil\`, combate real en medio con `movil`): en la Embestida contra Lya, Garon se pintaba
un fotograma encima de la cabeza y el siguiente debajo; en la segunda Embestida y en la recuperación de la Fractura,
Garon quedaba encima de una cabeza que estaba por delante de él (`..._orden_embestida_queda_detras_Garon.png` y
`..._orden_fractura_queda_detras_Garon.png`).

**Causa** (demostrada en `bramavidrio3_3d.gd`, `ordenar_en_combate`, con los índices del árbol de cada foto):
1. **Su sitio de siempre estaba mal apuntado.** `_indice_combate` se guardaba en la primera llamada, cuando
   `_al_frente(true)` (combate_bramavidrio.gd) ya había movido al gusano delante de Kael y Lya con la regla del hocico.
   Sin héroes tapados volvía a ESE sitio (índice 3: delante de Kael y Lya, detrás de Garon), no detrás de todos (1).
2. **Contaban tramos que no tocaban el dibujo del héroe** (solo se miraba el ancho, ±85 px): un tramo del cuello por
   encima de su cabeza decidía igual que la cabeza que le pasa por el pecho.
3. **Parpadeo:** cuando un tramo entraba y salía del ancho del héroe, el orden cambiaba en cada fotograma.

**Arreglo** (en el guion de la v3; la v1 y la v2 siguen con su regla del hocico, que no fallaba):
- su sitio es «justo antes del primer héroe del árbol», sin depender de lo anterior;
- solo cuentan los tramos que caen sobre la figura del héroe (de los pies a lo alto) y cuya sombra en la arena queda
  más de `MARGEN_DELANTE` (4 px) por delante de sus pies;
- una vez delante de un héroe en un ataque, sigue delante hasta que el ataque acaba: `fin_orden_combate()`, que llama
  `combate_bramavidrio.gd` en `_al_frente(false)` (3 líneas). Decide por tramos mientras ataca y vuelve detrás al acabar.

**Medido** (combates 1 y 2 de la herramienta, medio con `movil`, mismas semillas; `RESUMEN_ORDEN` de sus registros):

| v3 | Embestida (2) | Fractura | Vuelta al reposo | Aliento, derrota, héroes atacando |
|---|---|---|---|---|
| Antes: fotogramas con el gusano detrás de un tramo que debía tapar | 8 | 1-2 | 0 | 0 |
| Antes: cambios de orden | 15 | 7 | 12 | 0 |
| Después: fotogramas mal | **0** | **0** | 0 | 0 |
| Después: cambios de orden | **9** | **3** | 12 | 0 |
| v1 y v2 (referencia, sin tocar) | 0 · 9 cambios | 0 · 3 cambios | 0 · 12 | 0 |

Ningún fotograma con «tapa_mal» (tapar a un héroe con tramos que están detrás), ni antes ni después, en ninguna versión
ni variante, en bajo, medio ni alto (`despues\*\registro.txt`). Antes y después: `orden_v3_antes_despues.png`.

**La prueba ahora lo vigila:** `prueba_bramavidrio_combate` pide como mucho dos cambios de orden por héroe en cada turno
del gusano. Con el código de antes da **25 FALLOS** (Garon cambia 4 veces en una Embestida; Lya, de 6 a 12 en la
Fractura: `D:\REBELUM_diagnostico\pruebas\2026-11-12_111417\`); con el arreglo, SUPERADA con v1, v2 y v3.

## 2. Revisado desde la cámara real y correcto (sin cambios)

Todo en combates que corren: `despues\<versión>_<perfil>\` (unas 35 fotos por pasada) y la limpieza en su registro.
- **Mandíbula de la v3** (ángulo medido en cada foto):
  - cerrada (0,0°) en reposo y en los impactos de la Embestida y de la Fractura;
  - 43,9° al lanzarse y 52° en el aviso de la Fractura;
  - en el Aliento abre poco a poco: 47,9° aspirando y 57,9° en la descarga; 9,9° al recuperarse;
  - 15,6° herida y de 46° a 24° en la derrota (la mandíbula floja).
  Dientes, encías y garganta se leen en la descarga (`v3_alto_aliento_2_descarga.png`).
- **Embestida:** objetivo claro (anillo rojo, «⚠» y «clava sus ocelos en Lya»), anticipación de 0,2 a 0,8 s, impacto
  con la boca cerrada a 1,0 s, sacudida y recuperación. Un impacto y un sonido por turno (prueba).
- **Fractura:** aviso (cartel, «⚠ Fractura», grietas que laten), caída, placas, polvo y réplica. Defender la deja a la
  mitad y sin tambalearse (prueba). Lo que no está bien, en §3.
- **Aliento:** succión de 0,45 a 1,7 s con los héroes inclinados y descarga a 1,85 s, que barre a los tres hasta 2,6 s
  con arrastre y arena encima. El corte («¡Interrumpido!», se atraganta) le quita el turno siguiente (prueba B y
  combate 2).
- **Derrota:** se vuelve hacia `DIR_DERROTA` y cae detrás de los héroes en las tres versiones (0 fotogramas mal).
- **Interfaz:** el nombre, la vida («PV 1150/1150»), los avisos y el menú se dibujan encima del gusano en todas las fotos
  (la capa del menú va después de la escena).
- **Limpieza** (con ventana y audio de verdad), tras la victoria, el corte y cerrar el combate a medias mientras aspira:
  - 0 efectos de Bramavidrio, sin cartel, succión ni marca y 0 nodos huérfanos;
  - el bucle de la succión, callado (0,8 s después del corte ya no suena).
- **Sonidos** (`prueba_audio_bramavidrio`, medido, sin escuchar): cada uno sale en su instante del clip con un fotograma
  de margen como mucho. En la v3:
  - Embestida: recoge 0,233 (esperado 0,2), fija 0,567 (0,55), latigazo 0,833 (0,8) y embestida 1,000;
  - Fractura: rugido 1,233 (1,25), caída 2,1, fractura y placas 2,533 y asientan 3,133 (3,1);
  - Aliento: succión y bucle 0,467 (0,45), el bucle calla a 1,72 (fin_succion 1,7) y el chorro, a 1,85.
  Los volúmenes relativos son los del catálogo del especialista de sonido y no los he cambiado. No hace falta ningún
  sonido nuevo.
- **ATB y daño:** ninguna animación duplica el daño (un impacto por ataque) ni deja el combate parado (todas las partes
  de la prueba acaban); ver §4.

## 3. Medido y NO corregido (necesita decisión o archivos de otros)

1. **La Fractura cae encima de Garon y la cabeza se va de cuadro.** Pasa en las tres versiones y las variantes, en todos
   los perfiles (columna «Fractura: impacto» de `comparar_versiones.png`).
   - En el impacto, los tramos que caen sobre Garon quedan **49-51 px por delante de sus pies**: por profundidad, el
     cuerpo va delante y lo tapa casi entero ~0,9 s (de 2,53 a 3,45 s). No es un fallo del orden: es dónde cae.
   - La cabeza de la v3 llega a x ≈ 811 px de pantalla, bajo el panel de vida (que va encima y se sigue leyendo). La de
     la v1 y la v2 sale de la pantalla por abajo (y ≈ 781-829 de 720).
   - En el aviso la cabeza queda **380-450 px por encima del borde de arriba** en las tres: el rugido en lo alto no se ve.
   - **Probé girarlo antes de caer** (`giros=`, de −45° a +40°; fotos en `giros\`). Hacia la cámara, la caída se acorta
     pero la cabeza cae delante de Garon o encima de él. Hacia el fondo, cae más a la derecha, bajo el panel. Ningún giro
     arregla las dos cosas, así que no lo he puesto.
   - **Origen:** el clip `ataque_sismico` (en `crear_bramavidrio3.py`: `ua=17` erguido y `ua=13,6` caído). Propuesta para
     la v3: erguido a ~12,5 (con la cabeza a la vista) y una caída ~2 m más corta. Supone regenerar los tres GLB de la v3
     (el mismo modelo con otro clip) y actualizar `ALCANCES` y los instantes. Lo dejo para que se decida.
2. **Lya y Garon golpean al aire con la v3.** Sus sitios (`MODELOS["bramavidrio"]["pies_golpe"]` de `combate.gd`, comunes
   a las tres versiones) quedan bajo la cabeza de la v3, que en reposo está más adelante y más alta (`heroe_lya_golpea` y
   `heroe_garon_golpea`): el bastón de Lya se queda a ~80 px de la mandíbula. Propuesta para `combate.gd` (no es mío): en
   `_crear_rig`, tras `if m.has("pies_golpe")`, añadir
   `if f["p3d"].has_method("pies_golpe"): f["pies_golpe"] = f["p3d"].pies_golpe()`, y que el guion de cada versión dé
   los suyos (hay que medirlos).
3. **La v2 enseña la boca entreabierta en reposo** por una rendija de su geometría (demostrada en el informe de la v3).
   Cerrarla es rehacer su cabeza, es decir, reconstruirla: queda fuera de este encargo.

## 4. Pruebas (aisladas; la partida y la carpeta real de datos, sin cambios en todas)

- **Antes de tocar nada** (`a0bab37`), `prueba_bramavidrio_modelo`, `prueba_bramavidrio_combate`, `prueba_climax_jefe` y
  `prueba_audio_bramavidrio`: 4 SUPERADAS con cada versión (`D:\REBELUM_diagnostico\pruebas\2026-11-12_105303`, `_105356`
  y `_105451`, v1, v2 y v3).
- **La prueba de combate ampliada contra el código de antes** (v3): FALLIDA, 25 FALLOS de parpadeo (`2026-11-12_111417`).
  H e I ya pasaban: el bucle de la succión se limpiaba bien.
- **Con el arreglo**, la de combate ampliada: SUPERADA con v3, v2 y v1 (`2026-11-12_111509`, `_111543` y `_111616`).
- **Las cuatro de Bramavidrio al final**, con `bramavidrio_version=1|2|3` (listas propias con `-Lista`): **4 SUPERADAS con
  cada versión** (`2026-11-12_112847`, `_112938` y `_113030`).
- **Batería completa:** **129 SUPERADAS · 1 FALLIDA · 59 MANUALES · 0 NO SEGURAS** (`2026-11-12_113121`; partida y proyecto sin cambios). La fallida era una línea de `lista_pruebas.txt` que rompí yo: una sustitución se comió el comienzo de la de `prueba_bramavidrio_combate`, así que esa prueba no corrió en la batería. Reparada (`0790031`) y pasada desde la lista: SUPERADA (`2026-11-12_114721`). Con ella son 130 automáticas superadas, como la última batería de la V12 (130 · 0 · 58 · 0); la manual de más es la herramienta nueva.
- **Herramienta con ventana** (`fotos_bramavidrio_pulido`, 15 pasadas): `FALLOS: 0` en todas; sus registros en cada
  carpeta de `antes\` y `despues\`.

**Incidente menor (sin consecuencias):** el lanzador de mis primeras pasadas encadenaba dos guiones de PowerShell y
cortaba la ruta del GLB de las variantes («3\geoda\…»). La primera hoja salió con la v3 en las filas de las variantes;
la detecté, rehice esas dos pasadas llamando a Godot directamente y rehíce la hoja. No afectó a ninguna otra pasada
(no llevaban rutas en los argumentos, y sus fotos y registros cuadran con la versión y el perfil).

## 5. Comparación de versiones (ninguna es definitiva)

`D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio_pulido\comparar_versiones.png`: el combate real del grupo 13 en
alto (PC, sin `movil`), con las mismas semillas, encuadre y luz. Filas: v1, v2 (por defecto), v3 «el Excavador», v3
variante geoda y v3 variante columnas (los GLB de las variantes, de `bramavidrio3\variantes\`, solo para fotos). Columnas:
reposo, Embestida (se recoge e impacto), Fractura (aviso e impacto), Aliento (succión y descarga) y la caída de la derrota.

Lo que se ve, sin elegir:
- **v1:** el gusano de anillos, con la silueta más simple. La cabeza de la Fractura cae fuera de cuadro.
- **v2:** la vela de cristal es la silueta más llamativa, pero en reposo enseña la boca entreabierta. La cabeza de la
  Fractura también cae fuera de cuadro.
- **v3 (garras):** es la única con la boca cerrada en reposo y con las garras apoyadas. La cabeza de la Fractura se ve,
  aunque bajo el panel. Lya y Garon golpean al aire (§3).
- **Variantes de la v3:** geoda tiene la corona de cristal, más visible arriba, y columnas, la cresta de basalto más
  fuerte. Las dos sin brazos y con la misma boca y los mismos clips.

**Otras hojas:**
- `perfiles_v3_v2.png`: la v3 en bajo, medio y alto y la v2 en bajo y alto, en reposo, el impacto de la Embestida y de
  la Fractura, la descarga del Aliento, Garon golpeando y la derrota. Se leen igual en los tres perfiles.
- `orden_v3_antes_despues.png` (§1).

**Carpetas** (`D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio_pulido\`), cada una con su `registro.txt` y sus
fotos:
- `antes\v1_medio_movil`, `antes\v2_medio_movil` y `antes\v3_medio_movil`: unas 35 fotos cada una, y `antes\v3_medio_movil_medida`;
- `despues\`: la v1, la v2 y la v3 en alto, las variantes geoda y columnas en alto, la v3 en medio con `movil` y la v3 y
  la v2 en bajo con `movil`, más las pasadas de medida (`_medida*`, `_prof`);
- `giros\`: la Fractura girada, de −45° a +40°, en v1, v2 y v3.

## 6. Límites (lo que no he podido comprobar)

- **Redmi:** nada (sin ADB, por encargo). El arreglo del orden no añade dibujo; el coste es proyectar 11 puntos por
  fotograma mientras ataca, como antes. Sin medir.
- **Rendimiento:** no medido (otros especialistas trabajan en el PC).
- **Sonido:** medido, no escuchado. En las pasadas con ventana, a 30 FPS fijos el juego va más deprisa que el reloj y
  los sonidos sueltos siguen sonando un rato después de cerrar el combate (`brama_emerge`, `brama_rugido`…). No son
  bucles y acaban solos; el único bucle, el de la succión, calla siempre.
- **Huir:** este combate no deja huir («Bramavidrio cierra el paso»). Lo que se ha probado es cerrarlo a medias (H) y la
  huida de otros combates (`prueba_climax_jefe`).
- **Vídeo:** no he grabado `--write-movie`. Las pasadas son combates que corren, con fotos y medidas en cada fotograma.
- **La herramienta no es del todo determinista:** las decisiones de los héroes van por fotogramas y, con ventana, a
  veces se defienden un turno antes o después (el daño del Aliento cambia de 30 a 46 entre pasadas). No afecta al orden
  ni a las fotos de cada instante.

## 7. Siguiente paso y peticiones

1. **Coordinador:** integrar copiando los archivos de arriba y pasar la batería.
2. **Decisión del usuario:** la caída de la Fractura (§3.1). Si se aprueba, rehago el clip `ataque_sismico` de la v3 en
   `crear_bramavidrio3.py`, con el mismo modelo y la cabeza a la vista. La v1 y la v2 las dejaría como están.
3. **`combate.gd` (no es mío):** los sitios de golpe por versión (§3.2), con el cambio exacto de arriba. Los mido y los
   doy en el guion de la v3 cuando se acepte.
4. **Redmi:** medir el combate con la v3 en bajo y medio (Embestida y Fractura) y ver el orden en la pantalla pequeña.
