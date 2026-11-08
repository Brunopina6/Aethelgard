# Informe del especialista de animaciones

Cada entrega añade una sección con fecha y hora (las anteriores no se borran). Formato en `LEEME.md`.

## 2026-11-08 23:55 · T-084, tanda 1: la mano de Kael en el diálogo inicial y gestos naturales

**Versión de partida:** rama `area-animaciones` @ `1c17763` (igual que `integracion-experimental`), copia
`D:\Aethelgard_animaciones`. Todas las comprobaciones son del 2026-11-08, entre las 22:45 y las 23:55, con datos
aislados. La captura del usuario no llegó: el problema se reprodujo con una partida nueva.

**Commits** en `area-animaciones`, sin publicar:
- `256d06d`: los retratos y sus fuentes de Blender;
- `0744c9c`: el retrato vivo con poses, `kael.dch` y la etiqueta del prólogo;
- `3d922c5`: `grupo_3d.gd`;
- `7829c79`: las pruebas;
- `c2f50cb`: los `.uid`;
- y el de este informe.

### 1. La causa, demostrada

- **La mano junto a la cabeza está en la propia ilustración** `dialogos/retratos/kael.png`, la única de Kael. Y esa
  ilustración es un **render de su modelo 3D** (`kael.fbx`, de Meshy) **congelado en el fotograma 5 de su reposo
  `_01a19b86`**: el reposo con el sable al hombro. En el retrato no hay sable, así que la mano que lo sujeta queda
  junto a la cabeza, en las nueve frases y también mientras habla Lya.
  - *Comprobado ejecutando* (Blender 5.2): con la cámara girada −13,5° y 6° hacia abajo, la silueta del render
    coincide con la del retrato en un **98,9 %** (IoU), con una diferencia media de color de 0,07 sin igualar el
    color. La cámara se buscó por silueta (`buscar_camara.py`: 0,97 en la búsqueda gruesa de 13 fotogramas × 21 giros ×
    2 inclinaciones; 0,98 en la fina).
  - No es un clip en juego, ni una duración, transición, mezcla, esqueleto o pose procedural: el retrato vivo
    (`retrato_vivo.gd`, `375cc8c`) solo escala, mueve y gira la imagen entera. Las capturas de antes de T-081
    (retrato «normal») ya la tenían (`D:\REBELUM_diagnostico\prologo_antes_despues\antes\antes_frase_01.png`).
  - En 3D ese reposo sí lleva el sable (`kael_3d.gd`, `con_arma`) y se lee bien (primeros planos de Pastos Verdes).
  - El mismo retrato salía en **todos los diálogos de Pastos Verdes con Kael** (`kael (normal)`): PV-02, PV-03, PV-05,
    PV-06 y PV-07.

### 2. Corrección en el origen: el prólogo

- **Retratos nuevos** renderizados desde el mismo modelo, con la misma cámara, la luz de
  `pruebas/herramientas/foto_3d.gd` y el color igualado al original (mínimos cuadrados entre el reposo original
  re-renderizado y `kael.png`; diferencia 0,068 → 0,054):
  - `kael_reposo.png`: los brazos relajados (el derecho, como en un espejo del izquierdo), mirando a Lya;
  - `kael_mano_cadera.png` (gesto «ligero»: «a mí ni me roza»), `kael_brazalete.png` (levanta el antebrazo y lo mira),
    `kael_sorpresa.png` (antebrazos arriba y cabeza atrás, breve) y `kael_puno.png` («decidido»).
  - Las cinco con el **mismo lienzo**, 254 × 624: el cuerpo no se desplaza al cambiar de pose. La escala del `.dch`
    se compensa (×624/620): Kael sale del mismo tamaño y en el mismo sitio que antes.
  - Se rehacen **idénticas** (diferencia 0, comprobado) con `dialogos/retratos/fuentes_blender/` (Blender 5.2, sin
    complementos). Procedencia en `docs/recursos.md`.
  - `kael.png` se conserva, sin uso.
- **`retrato_vivo.gd`**: poses por gesto (`poses` en el `.dch`: gesto → imagen) con un fundido corto. La pose nueva
  aparece encima (0,18 s) y después se retira la anterior (0,14 s), así que el cuerpo no se transparenta. Vuelve al
  reposo al dejar de hablar (`_unhighlight`) o a los 3,2 s (la sorpresa, a los 1,8 s). Si la etiqueta va justo
  antes de la frase del otro, la pose se toma como reacción y se mantiene su tiempo. **El resaltado de quien habla no
  cambia.**
- **`kael.dch`**: el retrato «vivo» usa `kael_reposo.png` y las cuatro poses; el «normal» usa `kael_reposo.png`, con lo
  que se arregla también Pastos Verdes.
- **`prologo.dtl`**: una etiqueta nueva, `update kael [extra_data="brazalete"]`, antes de su frase del brazalete. **El
  texto no cambia.** Kael tiene un gesto distinto en cada una de sus cuatro frases (mano en la cadera, brazalete,
  sorpresa, puño) y ninguno se repite. Lya no cambia.

### 3. Diálogos 3D de Pastos Verdes

*Observado ejecutando* con `prueba_anim_pv_fotos` (misión desde cero y Kael solo, como «Probar la misión desde el
principio»), que imprime en cada frase la animación de cada personaje, hacia dónde mira y si se ha movido:
- **PV-02 (Kael solo):** en 3D, reposo con el sable al hombro, correcto. El retrato era el de la mano: arreglado.
- **PV-03:** Lya dice tres frases **sin estar en la escena 3D**; se une al acabar (`pastos_verdes_3d.gd`,
  `_tras_dialogo`) y llega andando desde 4 m por detrás. No lo he tocado: el archivo no es mío (ver §7).
- **PV-05:** Garon dice cinco frases **sin estar**; aparece al acabar, junto a Tilo. Además había tres fallos en
  `zonas3d/grupo_3d.gd`, ya corregidos:
  - aparecía con la **guardia de combate** de `garon_3d.gd` (las dos espadas hacia delante) porque el primer
    `_poner_estado(m, "")` no hacía nada con el estado inicial «» (pasaba igual al cargar la región con Garon en el
    grupo, hasta que andaba);
  - su guardia tranquila («Calma») no era un bucle: a los 3,2 s se quedaba parado del todo;
  - salía a 1 m de Kael, con una espada cruzada a la altura de sus piernas. Ahora aparece con 1,3 m de holgura (y, si
    no hay sitio, como antes).
- **Miradas:** quien escucha no se volvía hacia quien habla (con Tilo hablando, Kael a 68° y Lya a 35°). Ahora Kael y
  los acompañantes quietos se vuelven (0,45 s), una vez por cambio de interlocutor, si quien habla está en la escena
  y a menos de 12 m. Después del cambio: 0° en todas las frases en que habla alguien presente.
- **Pies que patinan** (medido en Blender sobre los clips): los clips de andar y correr son «en el sitio» y piden, a
  1,7 m de alto, 1,20 m/s al andar (Kael), 1,51 (Lya) y 1,22 (Garon), y 4,14, 5,40 y 3,57 al correr. En la región se
  anda a 4,2 m/s y se corre a 7,56 (`prototipos/vista3d.gd`):
  - Kael patina ×3,5 al andar y ×1,8 al correr;
  - los acompañantes, ×2,5 a ×3,1 en sus llegadas (`speed_scale` limitado a 0,75–1,25).
  - **No lo he cambiado:** cambia cómo se ve toda la exploración. Opciones en §7.

### 4. Pruebas (comprobado ejecutando, aislado)

- **`prueba_prologo` ampliada:** entero con poses (Kael en reposo en las cinco frases de Lya, sin la ilustración de
  la mano, y los gestos `ligero`, `brazalete`, `sorpresa` y `decidido` con su ilustración en sus cuatro frases);
  saltado en mitad y en la entrada; **deprisa** (una pulsación cada 0,1 s: 9 frases vistas con 45 pulsaciones y los
  retratos nunca a medias); **reabierto** en el mismo mapa (empieza en reposo, se salta y se vuelve a jugar).
  Superada.
- **Nuevas, con ventana:** `prueba_prologo_video` (el prólogo a ritmo de lectura, reabierto deprisa con Esc a la
  quinta frase y vuelta al mapa con Kael andando) y `prueba_anim_pv_fotos`. Terminan sin errores (MANUAL: capturas).
- **Batería completa** con el código definitivo (2026-11-08 23:47–23:55): **37 SUPERADAS, 0 FALLIDAS**, más las dos de
  capturas (MANUAL, sin errores). La partida y la carpeta real de datos no cambiaron. «Proyecto: cambiado» se debe a
  mis propios archivos, editados durante la pasada (comentarios de las fuentes y este informe). Resumen:
  `D:\REBELUM_diagnostico\animaciones\2026-11-08\bateria\2026-11-08_234735\resumen.md`. Hubo una pasada completa
  anterior, también sin fallos (`bateria\2026-11-08_233455`), y otra de comprobación final del prólogo y de los
  diálogos 3D (`final\2026-11-08_234213`: 8 superadas y 3 de capturas).
- **En 3D, después del cambio** (`bateria\2026-11-08_234735\prueba_anim_pv_fotos.log`): con Lya o Tilo hablando,
  Kael y Lya los miran a 0°. Tras PV-05, Garon está en «Calma» (bucle) a 2,1 m de Kael; antes, en «Guardia» a 1,0 m.
- **Ejecutor:** el usuario tenía el editor abierto en `D:\Aethelgard` (PID 31124) y el especialista de sonido lanzaba
  sus pruebas. `ejecutar_pruebas.ps1` se niega a empezar con cualquier Godot abierto, así que usé una copia en mi
  carpeta temporal que solo se niega si hay un Godot en `D:\Aethelgard_animaciones`. El aislamiento (sonda y huellas
  SHA-256 de la carpeta real) es el mismo: la partida real no cambió en ninguna pasada.

### 5. Evidencias

En `D:\REBELUM_diagnostico\animaciones\2026-11-08\`:
- **`retratos\`**:
  - `origen_kael_png_original_render_diferencia.png`: la prueba de origen (original | render del reposo | diferencia);
  - `hoja_original_control_y_poses.png`: el original, el reposo original re-renderizado y las cinco poses.
- **`prologo\`**:
  - `antes\` y `despues\`: las mismas frases y encuadres. `_a` es la frase recién escrita y `_b` la frase al final de
    la lectura; `fotos_*` son las de `prueba_prologo_fotos`, `rapido_*` el reabierto deprisa y `vuelta` el mapa;
  - `laminas\frases_*_antes_izq_despues_dcha.png`, con las nueve frases;
  - `laminas\tira_100_131.png`: un fundido entre poses, fotograma a fotograma;
  - `videos\`: `prologo_antes.mp4`, `prologo_despues.mp4` y `prologo_antes_despues.mp4` (los dos a la par; 52 s,
    15 fps, 960 × 540 cada uno).
- **`pastos_verdes\`**: `antes\` y `despues\`. Las láminas comparan cada frase de PV-02, PV-03 y PV-05 y sus
  **primeros planos** (a 5,5 m, más cerca de lo que deja el zoom del juego, 9 m).
- **`ejecuciones\`, `final\` y `bateria\`**: las pasadas con su `resumen.md`.

### 6. Límites

- **Sin probar en el Redmi:** no compilo APK.
- **Lya:** mira a la cámara, no a Kael, y tiene una sola ilustración. Su modelo sirve igual (`fuentes_blender/` se
  adapta cambiando el FBX y las poses), pero no ha entrado en esta tanda.
- **Los diálogos de Pastos Verdes** siguen con el retrato «normal»: sin gestos ni resaltado.
- **Rendimiento sin medir.** Son 4 texturas más de 254 × 624, comprimidas como las de siempre, que lee la pantalla de
  carga como el resto de `dialogos/retratos/`.
- **Las miradas en 3D** giran el cuerpo entero; no hay giro de cabeza ni de ojos.
- **El vídeo** sale de fotogramas JPG que guarda la prueba (Godot con `--fixed-fps 30`) montados con el editor de
  vídeo de Blender; `--write-movie` no se puede pasar a través del ejecutor.

### 7. Siguiente paso y cambios que necesito en archivos de otros

- **`zonas3d/pastos_verdes_3d.gd`** (de sonido en esta tanda). Para que nadie hable sin estar:
  - **PV-03:** unir a Lya **antes** del diálogo y empezarlo cuando ya esté cerca. En `_escena_mision`, con
    `id == "pv_03"`, llamar a `_unir("Lya", kael.global_position + _atras_en_camino(kael.global_position) * 4.0)`,
    esperar ~1,2 s (llega andando) y después `_empezar_dialogo(id)`. Quitar la rama `"pv_03"` de `_tras_dialogo`. Con
    las miradas nuevas, Kael se vuelve hacia ella cuando habla.
  - **PV-05:** que Garon esté junto a Tilo antes de hablar, por ejemplo uniéndolo al empezar PV-05 en vez de al
    acabar (`_unir("Garon", tilo.global_position)` antes de `_empezar_dialogo`). Mejor aún: que espere allí desde que
    se carga la región, sin seguir a nadie hasta el final de PV-05. Puedo añadir a `grupo_3d.gd` una función
    `esperar(nombre, sitio)` / `seguir(nombre)` si se aprueba.
- **Pies que patinan.** Hay que elegir:
  - **(a)** mantener las velocidades y usar el clip de correr para los 4,2 m/s (encaja casi exacto: 4,14 m/s) y
    correr más deprisa a 7,56 m/s (`speed_scale` de ~1,5 a 1,8);
  - **(b)** mantener los clips y bajar la velocidad de andar a ~1,5–2 m/s (es un cambio de jugabilidad);
  - **(c)** clips de trote nuevos.
  
  Afecta a `prototipos/vista3d.gd` (velocidades), `kael_3d.gd`, `maga_3d.gd` y `grupo_3d.gd`.
- **Diálogos de Pastos Verdes con retrato «vivo»** (resaltado y gestos, como el prólogo): solo hace falta cambiar
  `(normal)` por `(vivo)` en sus `.dtl`, pero cambia su presentación (retratos un 12 % más grandes y 70 px más
  abajo). Hay que decidirlo; las poses de Kael ya sirven («Matices.» → mano en la cadera, por ejemplo).
- **`pruebas/ejecutar_pruebas.ps1`:** propongo que la comprobación de «hay un Godot abierto» mire solo la copia propia,
  para que los especialistas puedan probar a la vez, siempre que la vigilancia y las huellas sigan como están.
- **Las fuentes de los retratos** están en `dialogos/retratos/fuentes_blender/`, con `.gdignore` (Godot no las lee y no
  van en el APK). Si se prefiere, pueden pasar a `pruebas/herramientas/`.
