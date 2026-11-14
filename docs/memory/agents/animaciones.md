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

## 2026-11-09 08:10 · T-084, tanda 2: pies sin patinar, presencia en PV-03 y PV-05, retratos vivos y poses de Lya

**Versión de partida:** rama `area-animaciones` @ `713fe8d`, copia `D:\Aethelgard_animaciones`, con lo nuevo de sonido
importado con datos aislados (`D:\REBELUM_diagnostico\importaciones\anim_20261109_001449`). Todo lo comprobado es del
2026-11-09, con datos aislados; la carpeta real de datos no cambió en ninguna ejecución.

**Commits** en `area-animaciones`, sin publicar:
- `361495b`: marcha por velocidad (`maga_3d.gd`, `kael_3d.gd`, `garon_3d.gd`, `prototipos/vista3d.gd`);
- `b29540e`: al pararse, sin un paso de más (`maga_3d.gd`, `vista3d.gd`);
- `2c1c160`: `zonas3d/grupo_3d.gd` (marcha, esperar y seguir, pasos);
- `adb3f8c`: `zonas3d/pastos_verdes_3d.gd` (PV-03, PV-05 y pasos de Lya y Garon);
- `2bbf973`: pruebas (`prueba_anim_pies.gd` nueva, `prueba_anim_pv_fotos.gd`, `lista_pruebas.txt`);
- `b579b50`: retratos de Lya y sus fuentes de Blender;
- `f5ab5bf`: `kael.dch`, `lya.dch`, `retrato_vivo.gd`, `prologo.dtl`, `pv_0{2,3,5,6,7}.dtl`, `prueba_prologo.gd`;
- `65f7a52`: el `.uid` de la prueba nueva;
- `4ea2eab`: `prueba_anim_pies.gd` comprueba un solo nodo de pasos por personaje;
- y el de este informe, con la fila nueva de `docs/recursos.md`.

### 1. Pies que patinan (decisión 1 del coordinador)

**La causa, medida** (`pruebas/prueba_anim_pies.gd`, *comprobado ejecutando*): los clips son «en el sitio» y el pie
apoyado va hacia atrás a una velocidad fija. Medida en Godot, a cámara lenta y a 1,7 m de alto: Kael anda a 1,18 m/s y
corre a 3,90; Lya, 1,50 y 5,26; Garon, 1,09 y 3,64 (en Blender, tanda 1: 1,20/4,14, 1,51/5,40 y 1,22/3,57). Los tres
vienen del mismo movimiento: ciclo de 1,03 s al andar y de 0,63 s al correr, y el pie izquierdo apoya al 26 % y al 29 %
del ciclo. Se andaba a 4,2 m/s con el clip de andar: el pie apoyado resbalaba a unos 3 m/s.

**Qué he hecho:**
- `maga_3d.gd`, **`marcha(v)`**: elige andar o correr por la velocidad real en el suelo y pone el ritmo que deja el pie
  quieto (velocidad / velocidad del clip, escalada con el tamaño del personaje). Cambia por la media geométrica de los
  dos clips, con un margen de ±8 % para que no parpadee, y entra por el mismo punto de la zancada. El ritmo al correr
  llega hasta ×1,8: a 7,56 m/s Kael pediría ×1,94 (6,2 pasos por segundo, como un molinillo) y con ×1,8 su pie se corre
  un 7 %. Al arrancar desde quieto, fundido de 0,1 s entrando por la mitad del apoyo. Al pararse, **`parar_marcha()`**
  congela la zancada mientras se funde con el reposo (antes daba un paso más con el cuerpo quieto, que además sonaba).
  `andar()` y `correr()` del combate no cambian.
- `prototipos/vista3d.gd`: Kael anima por su velocidad real. **La velocidad de juego no cambia**: 4,2 m/s con el
  teclado y los toques cercanos, 7,56 con los lejanos. Decisión mía: **el stick del mando pasa a ser analógico**, como
  en el mapa y en las zonas 2D (`mapa.gd`, `zona.gd`), del 30 % (1,3 m/s: el clip de andar a ×1,1) al 100 % (4,2). Sin
  eso no había «stick poco inclinado»: la dirección se normalizaba. Se deshace con una línea (`fuerza`, `STICK_MIN`).
- No he puesto aceleración a Kael, porque cambiaría cómo responde: el clip de andar sale con el stick suave y en el grupo.
- `grupo_3d.gd`: Lya y Garon usan `marcha()` y se acercan andando los últimos pasos (`VEL_ACERCARSE` 1,3 m/s; antes 2,52
  y se paraban en seco). Probé también una aceleración de 10 m/s² para sus arranques y la quité: se quedaban a 4,0 m del
  de delante (`prueba_grupo3d` falla por encima de 4), frente a 1,8 m sin ella.

**Antes y después** (mismo recorrido, mismas entradas y 30 fps fijos; registros y CSV en
`D:\REBELUM_diagnostico\animaciones\2026-11-09\medidas\`: `pies_antes.log` con `antes\pies.csv`, y
`pies_despues_final.log` con `despues\pies.csv`, del código final). Cuánto se corre el pie apoyado (plano) en cada paso:

| | Kael | Lya | Garon |
|---|---|---|---|
| Andar con el stick (4,2 m/s) | 52 → 1,2 cm | 61 → 6,5 cm | 31 → 5 cm (5 apoyos: casi siempre apoya de puntillas) |
| Correr hacia un toque (7,56 m/s) | 35 → 1,3 cm | 20 → 1,9 cm | 41 → 5 cm (un solo apoyo plano) |
| Arranques y paradas | 66 → 1,3 cm | 55 → 1,9 cm | — |
| Media vuelta | 66 → 1,0 cm | 85 → 4,7 cm | 55 → 50 cm (un apoyo, girando sobre sí) |
| Stick poco inclinado | 57 → 1,9 cm (ahora anda a 1,3-2,5 m/s) | 79 → sin apoyos planos | — |

Con el pie de apoyo aunque no esté plano (mediana de su velocidad con el cuerpo avanzando; incluye el rodar del talón a
la punta, que en un paso bien hecho ronda 0,5-0,8 m/s): andando a 4,2 m/s, Kael pasa de 3,09 a 0,77 m/s, Lya de 2,91 a
0,98 y Garon de 3,19 a 1,22; corriendo a 7,56, Kael de 3,63 a 0,86, Lya de 3,01 a 0,74 y Garon de 4,23 a 2,49 (su clip
pediría ×2,1 y con el tope ×1,8 se corre un 13 %; más aún cuando alcanza a Lya a 8,7 m/s).

**Vídeo:** `D:\REBELUM_diagnostico\animaciones\2026-11-09\video\pies_antes_despues.mp4` (35 s; antes a la izquierda y
después a la derecha, con el zoom más cercano del juego, 9 m). Sus fotogramas están en `video\antes\` y `video\despues\`.
Gráfica: `laminas\grafica_kael_andar_pie_apoyado_rojo_antes_verde_despues.png` (el pie apoyado de Kael, fotograma a
fotograma, andando por el camino: en rojo, antes, siempre a unos 3 m/s; en verde, después, casi 0 tras cada apoyo; la
línea gris es el cuerpo a 4,2 m/s y la rejilla va de 1 en 1 m/s).

### 2. Presencia en PV-03 y PV-05 (decisión 2)

- **PV-03:** al llegar al punto se pone el hito, Lya entra en el grupo y aparece en el camino, 4,5 m detrás de Kael.
  Kael se para y no hay control durante 1,2 s mientras ella llega corriendo; luego empieza el diálogo. Quitada la unión
  de `_tras_dialogo` (el sonido «union» sigue al acabar, como con Garon).
- **PV-05:** Garon espera junto a Tilo desde que se entra, del lado por el que se llega y a 2 m o más de donde se pone
  quien habla con Tilo. Está en su «Calma», con un cilindro de choque como el de Tilo, y mira a quien habla si la
  conversación es a menos de 6 m. Al acabar PV-05 se pone en la fila desde ahí.
- Lya y Garon entran en el grupo de la partida al empezar su escena, a la vez que el hito. Antes entraban al acabarla: si
  la app se cerraba a media escena, se guardaba el hito sin ellos y ya no se unían.
- **`grupo_3d.gd` mantiene su API** (para la Garganta 3D): todo lo de antes sigue igual. Lo nuevo es `esperar(nombre,
  sitio, mirada)`, `seguir(nombre)`, `unir(n, desde, exacto := false)`, `esperando` y `pasos_superficie` (opcional).
- *Comprobado ejecutando* (`prueba_anim_pv_fotos`, sin ventana y con ventana):
  - Garon espera al entrar, y Lya está a 1,8 m de Kael antes de su primera frase.
  - En todas las frases, quien escucha mira a quien habla (0°), salvo Tilo, que es una figura sin animación.
  - Tras PV-05, el grupo es Lya y Garon (Garon a 2,1 m, en «Calma»).
  - `prueba_ruta_alpha`: la misión entera, superada.

### 3. Retratos vivos en Pastos Verdes (decisión 3)

`kael.dch` y `lya.dch` tienen un retrato **`vivo_pv`**: el vivo (respira, resalta a quien habla y cambia de pose) con
la escala y el desplazamiento del «normal». No sale un 12 % más grande ni 70 px más abajo (comprobado en las capturas:
mismo tamaño y mismo sitio). En los `pv_0{2,3,5,6,7}.dtl`, los `join` pasan de `(normal)` a `(vivo_pv)` y algunas
frases de Kael y Lya llevan delante una etiqueta de gesto, sin repetir seguidas. **El texto no cambia** (comprobado
línea a línea). Garon y Tilo no tienen retrato: cuando hablan, los dos retratos quedan atenuados.

### 4. Poses de Lya (decisión 4)

- **De dónde sale su retrato** (*comprobado ejecutando*, Blender 5.2): `lya.png` es un render de su modelo en el clip
  quieto `_01a19663` (fotograma 20), con los brazos bajados como el gesto «reposo» del juego y la cámara girada +14° y
  6° hacia abajo. La silueta coincide en un 98,4 % (sin bajar los brazos, como mucho en un 84,8 %). La de Kael va a
  −13,5°: los dos retratos se miran.
- **Nuevas**, con su modelo, cámara, luz y un lienzo común (342 × 624; el original, 335 × 620; escala del `.dch`
  compensada ×624/620):
  - `lya_reposo`: el reposo original;
  - `lya_preocupada`: las manos cruzadas sobre el pecho y la cabeza baja y ladeada hacia Kael;
  - `lya_decidida`: la mano abierta sobre el pecho y la barbilla arriba;
  - `lya_duda`: los dedos en la barbilla, el otro brazo bajo el codo y la cabeza ladeada.
- **Sus manos no se cierran:** el modelo solo tiene el pulgar y una cadena «Middle», y los dedos no deforman (probado por
  los tres ejes). Por eso los gestos son de mano abierta.
- **Color y nitidez:** el color se ajusta como el de Kael (diferencia 0,089 → 0,042). Su original es además más nítido y
  contrastado que estos renders (alta frecuencia ×0,56 y contraste ×0,82). La luz no lo arregla: probé 12 intensidades y
  7 direcciones, y el preset de Kael ya era el mejor. Por eso `finalizar.py` tiene un «afinar» opcional (enfoque de 1 px
  y contraste local de 6 px, sin halos) que lo deja en ×1,00 y ×0,93. Sin «afinar», los retratos de Kael se rehacen
  **idénticos byte a byte** (comprobado). Queda una diferencia: el pelo del original tiene sombras algo más oscuras.
- **Uso** (solo etiquetas):
  - en el prólogo, sus cinco frases van en reposo (con «inquieta» solo se acerca), reposo, duda, decidida (etiqueta
    nueva) y preocupada; nunca repite ilustración;
  - en Pastos Verdes: preocupada (PV-05 y PV-07), decidida (PV-03) y duda (PV-07), más gestos breves sin ilustración
    (inquieta, firme, sorpresa).
  - `retrato_vivo.gd`: «decidida» hace el mismo gesto breve que «decidido».
  - `prueba_prologo` comprueba ahora también sus poses (superada).
- Hoja: `D:\REBELUM_diagnostico\animaciones\2026-11-09\retratos\lya_original_reposo_diferencia_y_poses.png` (el
  original, el reposo nuevo, su diferencia y las tres poses; la silueta del reposo coincide con la del original al 99,1 %).

### 5. Pasos de Lya y Garon (decisión 5)

`grupo_3d.gd` les pone `Sonido.pasos_3d(nodo, pasos_superficie)` al crearlos: uno por personaje, también a Garon
mientras espera (no suena porque no anda). `pastos_verdes_3d.gd` le da `suelo_de_pasos`, el mismo suelo que a Kael:
piedra a menos de 1,15 m del sendero y hierba fuera. *Comprobado ejecutando* (`prueba_anim_pies`): Kael, Lya y Garon
llevan un solo nodo «Pasos» cada uno; Kael no lleva dos. En `prueba_efectos` (superada), Kael da ahora 13 pasos en 2,6 s
por el camino en vez de 8: son los apoyos que se ven (antes resbalaba en vez de pisar).

### 6. Pruebas

- Sueltas, todas superadas:
  - `prueba_grupo3d` (Lya-Kael hasta 1,80 m, como antes) y `prueba_grupo3d_rutas` (hasta 3,45 m, como antes);
  - `prueba_ruta_alpha`, `prueba_efectos` y `prueba_prologo`;
  - `prueba_anim_pv_fotos`;
  - `prueba_anim_pies limite=1.0` (nueva y automática: falla si vuelven a patinar).
- **Batería completa** (2026-11-09 08:09-08:20, con el código final de los commits): **40 superadas, 0 fallidas**, 23
  manuales (con ventana o a mano: no se pasan en lote) y 0 no seguras. La partida y la carpeta real de datos, sin
  cambios. Había 13 Godot de otras copias (Garganta 3D y narrativa), anotados por el ejecutor. «Proyecto: cambiado» se
  debe a la fila de `docs/recursos.md` que añadí durante la pasada y a un `__pycache__` de mis scripts de Blender en
  `fuentes_blender\` (borrado). Resumen:
  `D:\REBELUM_diagnostico\animaciones\2026-11-09\bateria\2026-11-09_080900\resumen.md`.
- Después de la batería, `prueba_anim_pies` comprueba también los nodos de pasos (`pies_despues_final.log`, superada).
- Giros, paradas y el puente están en el recorrido de `prueba_anim_pies`. La reentrada, la carga y la vuelta del combate,
  en las pruebas de la batería (`prueba_grupo3d`, `prueba_zona3d`, `prueba_cofre3d`, `prueba_centinela`): `marcha()` no
  guarda nada de una escena a otra, y al volver cada uno empieza en su reposo.

### 7. Evidencias

En `D:\REBELUM_diagnostico\animaciones\2026-11-09\`:
- `video\pies_antes_despues.mp4` y `medidas\`, con los registros y CSV de antes y después;
- `laminas\grafica_kael_andar_pie_apoyado_rojo_antes_verde_despues.png` y `laminas\pies_fotogramas_antes_izq_despues_dcha.png`
  (los mismos fotogramas del recorrido, antes y después);
- `pastos_verdes\despues\`: cada frase de PV-02, PV-03 y PV-05, la llegada de Lya, Garon esperando y uniéndose, y
  primeros planos. Las de antes son las de la tanda 1, en `2026-11-08\pastos_verdes\despues\`;
- `prologo\despues\`: cada frase al salir (`_a`) y al final de la lectura (`_b`), el reabierto deprisa, la vuelta al
  mapa y los fotogramas para el vídeo;
- `laminas\pastos_verdes_antes_izq_despues_dcha.png` y `laminas\prologo_lya_frases_1_3_5_7_9_antes_izq_despues_dcha.png`;
- `retratos\`: la hoja de Lya y `lya_afinado_prueba.png` (el original, sin afinar y afinado);
- `ejecuciones\` y `bateria\`.

### 8. Incidente: la carpeta temporal compartida

A las 07:19, el especialista de gráficos escribió en la raíz de la carpeta temporal compartida un `godot_aislado.ps1`
que pisó el mío. Mis dos órdenes de las 07:19:58 y las 07:24:59 (`prueba_grupo3d` y `prueba_grupo3d_rutas`) lanzaron su
ejecutor y abrieron el juego sobre `D:\Aethelgard_graficos`, con datos aislados. Sus registros están en
`D:\REBELUM_diagnostico\mapamundi\2026-11-09\registros\_071958` y `_072459`.
- Lo vi en la salida y cerré el segundo Godot (PID 24304 y 6808, hijos de mi orden).
- Pasé mis herramientas a `scratchpad\animaciones\`: `anim_godot.ps1` apunta a `D:\Aethelgard_animaciones`.
- Borré mi copia de la raíz y repetí las dos pruebas, a las 07:29 y a las 07:37, sin fallos.

### 9. Límites

- **Sin probar en el Redmi** (no compilo APK) y **sin medir rendimiento** (había otros trabajando): `marcha()` hace unas
  cuentas por fotograma y personaje; los cuatro retratos nuevos, de 342 × 624, van comprimidos como los demás.
- **Giros rápidos:** el cuerpo gira entero en 0,12 s y el pie apoyado barre un arco (en el eslalon, Lya y Garon llegan a
  unos 3 m/s en esos fotogramas). Garon corriendo a 7,56-8,7 m/s se corre un 13-30 % (tope ×1,8).
- **El stick analógico** cambia el tacto del mando (no el del teclado ni el de los toques). Si no gusta, se quita.
- **Pasos del grupo:** suenan como los de Kael, con el mismo volumen y sin posición. Ver §10.
- **Lya:** su pelo sale algo más claro que en el original, y sus manos no se pueden cerrar.
- **La aparición de Lya** a 4,5 m sigue viéndose: la cámara no gira y a 20 m cubre unos 12 m a cada lado. Para que
  entrara desde fuera de la pantalla, tendría que aparecer a 13 m o más y habría que esperar unos 2,5 s.
- `pruebas/prueba_boton_prologo.gd.uid` (de T-081, no mío) queda sin confirmar.

### 10. Siguiente paso y cambios que necesito en archivos de otros

- **Sonido (`sonido.gd`, `Pasos3D`):** una opción de volumen por cuerpo, o pasos 3D con posición, para que los de Lya y
  Garon suenen algo por debajo de los de Kael. Hoy los tres comparten los «paso_*» (2 voces y 0,09 s entre dos iguales).
- **Garganta 3D:** puede usar `grupo_3d.gd` igual que antes. Si quiere pasos para el grupo, que le dé `pasos_superficie`
  antes de `preparar()`; `esperar()` y `seguir()` sirven para quien espera en la zona.
- **Decidir:** el stick analógico (§1) y si Lya debe aparecer más lejos en PV-03 (§9).

## 2026-11-09 13:25 · T-097, primer paso: Zarzalín preparado para el combate (modelo, clips y escena)

**Versión de partida:** rama `area-animaciones` @ `129b517` (igual que `integracion-experimental`), copia
`D:\Aethelgard_animaciones`. Todo lo comprobado es del 2026-11-09, entre las 12:20 y las 13:25, con datos aislados
(importaciones en `D:\REBELUM_diagnostico\importaciones\animaciones_zarzalin_*`); la carpeta real de datos no cambió en
ninguna ejecución. **No toco `combate.gd`:** el enganche lo hace el especialista de combate.

**Commits** en `area-animaciones`, sin publicar:
- `399f5b3`: `enemigos/zarzalin/` (el GLB completo con sus texturas, la escena, su guion y el guion de Blender);
- `2821e99`: las pruebas (`prueba_zarzalin_modelo.gd`, `prueba_zarzalin_fotos.gd`, sus `.uid` y `lista_pruebas.txt`);
- `2be546e`: la fila de `docs/recursos.md`;
- y el de este informe.

### 1. El modelo del usuario, revisado (*comprobado ejecutando*, Godot 4.7.2 y Blender 5.2.3)

- **`zarzalin.glb`** (6,3 MB, SHA-256 `d76d92bd08c19e06…`): una malla de 8.027 triángulos (8.954 vértices en glTF), un
  material y un esqueleto de **12 huesos** (root, body, head, tail y dos por pata). Mide **0,92 m de alto** (el lomo),
  1,35 m de largo y 0,47 m de ancho, con los pies en y = 0. **Mira a +Z** (la cámara del combate está en +Z): con el
  giro de los enemigos 3D (`FRENTE_ENEMIGO`, 53°) queda de 3/4 mirando a los héroes, como Grimfang.
- **Material:** `StandardMaterial3D` (vale para Compatibility): color, normales y una textura de rugosidad (canal G,
  media 0,74) y metal (canal B, media 0,002: no es metálico), a doble cara. Nada que no exista en GLES3.
- **Texturas 2K** (2048 × 2048, JPG de 2,5, 1,5 y 1,7 MB). En la GPU:
  - como las importa Godot sin ventana (sin comprimir, RGB8 con mipmaps): **48 MB** las tres, 16 MB cada una;
  - **comprimidas para la GPU** (`compress/mode=2`; las normales, con `normal_map=1`): **10,7 MB** (color 2,7, rugosidad
    y metal 2,7, normales 5,3; S3TC/RGTC en el PC y ETC2 en Android, del mismo tamaño). Es lo que hace el editor al
    detectar una textura 3D; aquí queda fijado en sus `.import`.
  - **Antes y después**, en el mismo fotograma, misma pose y luz del combate: diferencia media 2,5/255, máxima 24/255;
    el 0,03 % de los píxeles del jabalí cambia más de 16/255. No se distingue a simple vista (lámina en § 6).
  - No hago una variante de 1K: comprimidas ocupan 10,7 MB. Si el Redmi lo pide, se mide antes.
- **Clips:** reposo (1,1 s), embestida_espinosa (1,3), colmillo_lateral (1,07) y recibir_golpe (0,63), con todas las
  claves muestreadas a 30 fps. Ninguno en bucle (glTF no lo guarda).
- **Hallazgo 1, las anclas iban un fotograma tarde** (*comprobado*: tiempos de las claves del GLB). El exportador
  escribió cada clip con el tiempo del fotograma de Blender (fotograma 1 = 1/30 s), así que el impacto de la embestida
  (fotograma 18) caía a 0,600 s y el del colmillo (fotograma 15) a 0,500 s, no a los 0,57 y 0,47 de la ficha, que
  cuentan desde el fotograma 1. El reposo, además, repetía un fotograma al dar la vuelta. **Corregido en el origen:** el
  GLB nuevo se exporta con `export_anim_slide_to_zero`; el impacto queda a **0,567 s** y **0,467 s**, y el reposo dura
  1,067 s con el primer y el último fotograma iguales.
- **Hallazgo 2, la embestida no baja el hocico** (*comprobado*, cinemática del clip en Godot). En su preparación
  (fotogramas 1-13) retrocede 0,22 m y se agacha 0,07 m, pero la cabeza **sube** 12° (de −4,2° a +7,8°): el hocico solo
  baja 5 cm con el cuerpo. Para el aviso que pide la ficha («anuncia con dos golpes de pezuña») he hecho un clip propio.
- **Avance dentro del clip:** en el impacto de la embestida, el hocico está **0,635 m** por delante de su reposo, y al
  aterrizar (0,73 s) llega a 0,87 m: sigue 0,24 m más allá del golpe y vuelve solo a su sitio al final del clip. El
  colmillo lateral apenas avanza el hocico (1 cm) y lo barre 0,40 m hacia su lado.

### 2. Clips nuevos (Blender 5.2.3, sobre una copia del `.blend`)

`enemigos/zarzalin/fuentes_blender/crear_clips.py` (con `.gdignore`) abre una copia, crea las acciones y exporta el
GLB. **No toca los cuatro clips del usuario** (las poses de sus claves son las mismas; las texturas del GLB nuevo son
idénticas byte a byte a las suyas). Cada pose se escribe como giros sobre una pose base (el reposo o el fotograma 13 de
la embestida) y la raíz se apoya sola en el suelo con la malla deformada: los pies no se hunden ni flotan. **Se rehace
idéntico:** desde una copia nueva del `.blend` del usuario sale el mismo GLB byte a byte (SHA-256 `4245e115…`,
*comprobado ejecutando*); el `.blend` del usuario sigue intacto (`785fc3b3…`).

| Clip | Duración | Qué hace | Anclas |
|---|---|---|---|
| `derrota` | 1,167 s | Encaje del golpe, dobla las patas delanteras y cae sobre su costado izquierdo (patas y vientre hacia la cámara del combate), rebota y se queda quieto | En el suelo a 0,6 s; el combate lo desvanece a los 0,9 s, como a los demás enemigos 3D |
| `entrada` | 1,167 s | Salta a su sitio desde 0,85 m por detrás, aterriza, sacude la cabeza, da un pisotón y acaba en la pose del reposo | Aterriza a 0,47 s |
| `aviso_embestida` | 0,967 s | Retrocede, **baja el hocico 22° más que en la embestida** (la pose de carga) y da dos golpes con la pezuña delantera derecha | Hocico abajo 0,267 s; pezuña 0,467 y 0,733 s |
| `aviso_espera` | 1,0 s, bucle | La pose de carga respirando hasta su turno | — |
| `correr` | 0,5 s, bucle | Galope en el sitio, para acercarse al objetivo y volver | — |

La pose de carga es la del fotograma 13 de la embestida con el hocico bajo: desde ella la embestida sigue en su
segundo 0,4 (una mezcla de 0,1 s) sin repetir la preparación. Hojas de poses en § 6.

### 3. La escena y su API (para combate)

`enemigos/zarzalin/zarzalin_3d.tscn` (Node3D con `zarzalin_3d.gd` y el GLB dentro). También se puede crear como
Grimfang: `load("res://enemigos/zarzalin/zarzalin_3d.gd").new()` con `ruta_modelo` (lo comprueba la prueba).
- **Lo que el combate ya llama a un enemigo 3D** (mismos nombres que `maga_3d.gd`): `reposo()`, `correr()` y `andar()`
  (galope), `herida()` (= `recibir_golpe()`), `morir()` (= `derrota()`), `cansada(si)` (solo hace más lento el reposo:
  los ataques no cambian de tiempo), `revivir()`, `victoria()`, `mirar(dir, dur)`, `mirar_frente(dur)`,
  `punto_magia()` (la punta del hocico), `ALTURA` (0,92, para Érebo) y `anim`, `skel`, `pivote`, `caida`, `ajuste`.
- **Lo nuevo:**
  - `atacar(ataque: String, al_impactar := Callable()) -> void` (con `await`): `"embestida_espinosa"` o
    `"colmillo_lateral"`. En el ancla emite `impacto(ataque)` y llama a `al_impactar` **una sola vez** (también si
    algo corta el clip antes); vuelve al reposo y emite `ataque_terminado(ataque)`. Si está derrotado, no hace nada.
    Un golpe recibido a mitad no lo corta.
  - `avisar(ataque := "embestida_espinosa") -> void` (con `await` hasta acabar el aviso): emite `aviso(ataque)` al bajar
    el hocico (0,267 s) y `pezuna(1)` y `pezuna(2)` en cada golpe; luego queda en `aviso_espera`. Un golpe recibido
    en carga reacciona y vuelve a la carga. `reposo()` la anula.
  - `recibir_golpe()`, `derrota()` (emite `clip_terminado("derrota")` y se queda en el suelo) y `entrada()` (emite
    `clip_terminado("entrada")` y queda en reposo; empieza sin mezcla, 0,85 m por detrás).
  - `alcance(ataque) -> float` (0,635 m la embestida; 0,011 el colmillo), `tiempo_impacto(ataque) -> float`
    (0,467, 0,567 o, desde la carga, 0,167), `duracion(clip)` y `hocico() -> Vector3`.
  - Constantes: `ATAQUES` (anclas), `HOCICO_BAJO`, `GOLPES_PEZUNA`, `CENTRO` (0,5 m: el centro del cuerpo), `CLIPS` y
    `BUCLES` (los bucles los pone el guion: glTF no los trae y el `_subresources` del `.import` de Godot 4.7 crece a
    6.216 líneas, así que no lo uso).
- **Precisión de las anclas:** el guion se procesa después del AnimationPlayer (`process_priority = 10`) y dispara cada
  ancla en el fotograma más cercano a su segundo del clip (medio fotograma como mucho).

### 4. Encuadre en la cámara del combate y propuesta para `combate.gd`

- Proyectando la malla de cada fotograma de cada clip con la cámara del combate (ortográfica, 12°), con el jabalí
  girado al frente y hacia los héroes, todo cabe en x ∈ [−1,15, +1,58] m e y ∈ [−0,22, +1,16] m (lo más ancho: la
  entrada por la izquierda y la embestida por la derecha). De ahí sale una ventana 3D de 1,5 m de alto mirando a
  0,48 m del suelo.
- **Escala:** a su tamaño (0,92 m) y con los 280 px/m de Grimfang, su lomo queda a la altura del pecho del goblin y
  por debajo de la cadera de Kael. **Propongo ×1,25**: se lee mejor como enemigo y sigue por debajo de los héroes
  (lámina en § 6). Cuesta más píxeles: 347.000 por fotograma a 0,75 de resolución, frente a 223.000 de Grimfang y
  315.000 de Kael. La alternativa barata es `"esc": 0.75` con la ventana de ×1,0 (mismos píxeles que Grimfang, algo
  más blanda). Lo decide el usuario o el coordinador.
- Entrada propuesta para `MODELOS` (×1,25):
  `"zarzalin": {"tipo": "3d", "esc": 0.6, "script": "res://enemigos/zarzalin/zarzalin_3d.gd", "gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/zarzalin/zarzalin_completo.glb"], "vp": Vector2i(1175, 525), "alto_vista": 1.5, "centro_y": 0.48, "barra_y": 40.0}`
  (a ×1,0: `"vp": Vector2i(940, 420)` y `"barra_y": 32.0`).
- **Lo que combate tiene que tener en cuenta:**
  - `_crear_rig_3d` pone el centro del cuerpo a 0,85 m (`centro_ofs`), pensado para personas: para Zarzalín es
    **0,5 m** (`CENTRO`), o los números y los destellos salen por encima del lomo.
  - **Colocación para atacar** (en píxeles de la escena, con `px_m = vp.y / alto_vista * esc`, 210 a ×1,25): los pies
    en `centro_objetivo.x − 30 − 0,632 · px_m − alcance(ataque) · px_m` y a la altura de los pies del objetivo. Así los
    colmillos llegan al frente del héroe en el impacto. **Durante el clip no se mueve el rig**: el clip ya lleva el
    avance y vuelve a su sitio.
  - El acercamiento y la vuelta, con `mirar(ida)` y `correr()` (el galope) y, al llegar a casa, `mirar_frente()` y
    `reposo()`, como hoy en `_anim_ataque_3d`.
  - El ataque cargado de la ficha: en su turno, `await p.avisar()` y el indicador con la señal `aviso`; en su
    siguiente turno, `await p.atacar("embestida_espinosa", al_golpear)` (el impacto llega 0,13-0,17 s después:
    entra por la carga). El turno de recuperación es lógica del combate.
  - `morir()` ya lo llama `_restablecer_color`: la derrota se ve entera antes del desvanecido (en el suelo a 0,6 s).
  - `entrada()` al empezar el combate es opcional; si se usa, conviene un fundido corto del rig en los primeros
    0,15 s, porque aparece 0,85 m por detrás de su sitio.
  - La huida (`_huir`) solo desliza y desvanece el rig: si se quiere, antes `mirar(Vector3(-1, 0, 0.1))` y `correr()`.
  - La huella del combate no cambia (no he tocado `combate.gd`).

### 5. Pruebas

- **Nueva `prueba_zarzalin_modelo`** (automática, en `lista_pruebas.txt`): los 9 clips; en la escena, en bucle solo
  reposo, aviso_espera y correr; cada clip gira los 12 huesos (con `remove_immutable_tracks=false`, ninguna pose se
  queda de un clip anterior: tras la derrota, `revivir()` vuelve a 0°); ataques, golpe y entrada acaban en la pose del
  reposo y los bucles cierran sin salto (0,00°); texturas 2K comprimidas; impacto una vez por ataque y en su ancla con
  el clip a 0,466 s (colmillo, ancla 0,467) y 0,567 s (embestida, desde el reposo y desde la carga); aviso a 0,267 s y
  pezuña a 0,467 y 0,733 s; pausa de 1 s a mitad (no golpea en pausa; luego, un golpe a 0,467); un golpe recibido a
  mitad no corta el ataque; derrota que no ataca ni avisa; entrada; liberado a mitad de un ataque, sin errores; creado
  con `.new()`.
- **Nueva `prueba_zarzalin_fotos`** (con ventana, `-Manual`): lo mismo y las capturas desde el combate de verdad
  (`combate.tscn` de Pastos Verdes con los grupos 0 y 9; Zarzalín sustituye a un Grimfang en su ventana 3D con el
  encuadre propuesto, el combate no avanza turnos y la prueba llama a sus efectos, `_golpe_visual` y
  `_restablecer_color`, como lo haría `combate.gd`). Con `tam=1.25`, más grande.
- Con el ejecutor y el código de los commits: `D:\REBELUM_diagnostico\pruebas\2026-11-09_131921\resumen.md`
  (prueba_zarzalin_modelo **SUPERADA**, prueba_zarzalin_fotos **MANUAL** con 29 capturas, revisadas; código de salida
  0; datos reales y proyecto sin cambios; había 4 Godot de otras copias).
- **Incidente:** en la pasada de las 13:13 (`2026-11-09_131323`), `prueba_zarzalin_fotos` se quedó esperando a que la
  ventana dibujara y agotó los 300 s, sin capturas. Ahora cada captura espera como mucho 10 fotogramas y avisa si la
  ventana no dibuja; la pasada siguiente, la de arriba, terminó en 19 s.
- Comprobación de que no rompo nada: `prueba_escenas`, `prueba_huir` y **`prueba_combate_huella`** SUPERADAS
  (`D:\REBELUM_diagnostico\pruebas\2026-11-09_130917\resumen.md`; «proyecto: CAMBIADO» es la fila de `recursos.md`, que
  escribí durante la pasada).

### 6. Evidencias

En `D:\REBELUM_diagnostico\bestiario\2026-11-09\zarzalin\`:
- `capturas\` (×1,0) y `capturas_tam_1_25\` (×1,25), desde la cámara del combate: `10_reposo`, `20-24_entrada_*`,
  `30_aviso_hocico_bajo`, `31_aviso_pata_alzada`, `32_aviso_golpe_pezuna`, `33_aviso_espera_carga`,
  `40_embestida_galope`, `41_embestida_empuje`, **`42_embestida_impacto`** (Kael en rojo con su número),
  `43_embestida_aterriza`, `50_colmillo_gira`, **`51_colmillo_impacto`**, `52_vuelve_galopando`, `60_recibir_golpe`,
  `70-72_derrota_*`, y `00/01/02` con Grimfang antes y Zarzalín junto a él;
- `capturas\80_texturas_jpg_sin_comprimir`, `81_texturas_comprimidas_gpu` y `82_diferencia_x8`;
- `capturas_sin_comprimir\`: la primera pasada, con las texturas sin comprimir;
- `laminas\`: `secuencia_combate_tam_1_25.png` (la secuencia entera), `escala_1_0_arriba_1_25_abajo.png`,
  `texturas_sin_comprimir_izq_comprimidas_centro_diferencia_x8_dcha.png`, `originales_poses.png` y
  `originales_embestida_cerca.png` (los clips del usuario), y `nuevos_v1_*.png` (los clips nuevos, en Blender);
- `registros\`: la inspección del GLB original en Godot, el encuadre medido en Blender y las salidas de las pruebas;
- `referencia_video\`: un fotograma por segundo del MP4 del usuario;
- `blender\zarzalin_completo.blend` (la copia con los clips nuevos; fuera del repositorio, D-075) y
  `exportado\zarzalin_completo.glb`.

### 7. Límites

- **Sin enganchar al combate** (lo hace combate) y **sin probar en el Redmi** ni medir rendimiento (había otros
  trabajando y no compilo APK). Las cifras de memoria son de los `.ctex` importados.
- **Escala:** ×1,25 es mi propuesta, no una decisión.
- **El galope** es un ciclo sencillo en el sitio y no he medido si patina en el acercamiento de 0,55 s del combate.
- **La embestida** aterriza 0,24 m más allá del punto del golpe: con la colocación propuesta, la cabeza pasa por
  delante del héroe al aterrizar (se ve como una embestida, pero solapa).
- **La entrada** empieza visible, 0,85 m por detrás: la ventana 3D no deja entrar desde fuera de la pantalla.
- El sonido (tierra, ramas y cuero, según la ficha) no está: las señales `pezuna` e `impacto` son sus anclas.
- `aviso_espera` y `correr` no se piden en la tarea: los añado porque el flujo real del combate los necesita (la espera
  hasta su turno y el acercamiento con `correr()`).

### 8. Siguiente paso y cambios que necesito en archivos de otros

- **Coordinador, `docs/versiones/licencias_pendientes.txt`:** añadir
  `enemigos/zarzalin/ | Zarzalín, bestiario 01 (Meshy + Blender, D-075) | Plan de Meshy sin confirmar`, para que
  `compilar_apk_experimental.ps1` marque como «NO DISTRIBUIR» un APK que lo lleve.
- **Combate, `combate.gd`:** el enganche de § 4 (entradas de `MODELOS`, `ENEMIGOS`, `ANIM` y un grupo de Pastos Verdes;
  la rama de `_animar_golpe` con `atacar()`; el aviso con un turno de antelación; el centro a 0,5 m) y su prueba de
  combate (aviso, daño único, defensa, victoria, huida, regreso y guardado).
- **Sonido, `sonido.gd`:** la voz y los golpes de Zarzalín (`clave` "zarzalin") y la tierra de la pezuña con la señal
  `pezuna`.
- **Para decidir:** la escala (×1,0 o ×1,25). Y las texturas 2K de Grimfang, Garon y Érebo siguen **sin comprimir**
  (`compress/mode=0`, 16 MB cada una en la GPU; Kael y Lya sí lo están): con la misma comparación de antes y después,
  bajarían a la cuarta parte.
- **Aviso de la integración:** al importar, Godot crea 43 `.uid` de Oakhaven, de la Garganta 3D y de algunas pruebas, y
  añade los diálogos de Oakhaven al directorio de Dialogic de `project.godot`. No son míos: no los he confirmado y he
  devuelto `project.godot` a como estaba.

## 2026-11-09 18:50 · Personalidad: esperas y porte de los héroes en la exploración 3D, y gestos por intención en los diálogos

**Versión de partida:** rama `area-animaciones` @ `f6dc571`, unida con `integracion-experimental` @ `eb8bd94`
(`git merge --no-ff`, `697dfed`, sin conflictos). Los 43 `.uid` sin seguimiento que generó la importación (todos
venían en `eb8bd94`) se apartaron antes a `D:\REBELUM_respaldos\2026-11-09_uids\animaciones\`. Todo lo comprobado es
del 2026-11-09, entre las 17:20 y las 18:50, con datos aislados; la carpeta real de datos no cambió en ninguna
ejecución. **No he usado el Redmi** (ni ADB). **T-101 (Érebo) no ha entrado:** no quedaba margen (§ 8).

**Commits** en `area-animaciones`, sin publicar:
- `697dfed`: unión de `integracion-experimental` (`eb8bd94`);
- `07486da`: el código (`esperas_3d.gd` nuevo, `maga_3d.gd`, `gestos_3d.gd`, `kael_3d.gd`, `garon_3d.gd`);
- `8bfc29e`: los clips (`animaciones/esperas/*.res`), sus fuentes de Blender, las herramientas de captura y conversión y
  la fila de `docs/recursos.md`;
- `2c94481`: la activación en la exploración (`prototipos/vista3d.gd`, `zonas3d/grupo_3d.gd`);
- `ec33301`: las pruebas (`prueba_esperas.gd`, `prueba_esperas_fotos.gd`, `lista_pruebas.txt`);
- `50f7ccb`: los gestos por intención (`dialogos/retrato_vivo.gd`, `prologo.dtl`, `pv_03.dtl`);
- `33b2bfc`: Garon, las espadas al estirar la espalda;
- `ae25958`: ajustes de las pruebas;
- y el de este informe.

### 1. La causa: por qué los héroes no tenían personalidad (*observado en el código*)

- Quietos en la exploración, los tres repetían siempre lo mismo: Kael su clip de reposo de Meshy (`_01a19b86`, el
  sable al hombro), Lya una pose quieta de Meshy con los brazos bajados por código (`gestos_3d.gd`, «reposo») y
  respiración, y Garon su guardia tranquila «Calma» (dos instantes de «Juicio» que van y vienen). Ningún clip propio.
- Al andar y al correr, **los tres usan el mismo movimiento** de Meshy (ciclo de 1,03 s al andar y 0,63 s al correr,
  medido en la tanda 2) y su ritmo lo fija la velocidad para que el pie apoyado no patine (`marcha()`). Lo único
  distinto eran sus armas.

### 2. Esperas: clips propios hechos en Blender 5.2.3 por script

**Cómo se hacen** (reproducible, sin complementos):
1. `pruebas/herramientas/capturar_reposo.gd` captura el reposo **tal como se ve en el juego** (el clip más los gestos de
   `gestos_3d.gd`, después del último modificador del esqueleto): `animaciones/esperas/fuentes/reposo_<héroe>.json`.
2. `animaciones/esperas/fuentes/esperas.py` (con `esperas_lib.py`; carpeta con `.gdignore`, no va en el APK) importa el
   FBX del héroe en Blender, pone esa pose (relación entre los dos esqueletos por Kabsch con las posiciones de reposo:
   error 0,00000) y resuelve cada fotograma a 30 fps a partir de unas claves de control en ejes del personaje:
   tronco, IK analítica de brazos (con su codo) y de piernas (**los pies no se mueven del suelo**: 0,0000 en todos
   los clips), dirección de las armas (sable, cetro, espadas), punta de un arma apoyada en el suelo, la mano izquierda
   agarrando el arma de la derecha y dedos. Las claves se interpolan con Hermite monótona (pasa por ellas sin
   detenerse). El primer y el último fotograma son **exactamente** la pose del juego (0,000°). Exporta un GLB por héroe
   (armadura y un triángulo; 1,0-1,7 MB, fuera del historial: `D:\REBELUM_diagnostico\animaciones\2026-11-09\esperas\glb\`).
3. `pruebas/herramientas/convertir_esperas.gd` pasa el GLB a los huesos del héroe (giro respecto al reposo en el espacio
   del esqueleto, llevado al del héroe por Kabsch), quita las claves que se deducen de sus vecinas (error < 0,23°) y
   guarda `animaciones/esperas/<héroe>.res`. **Comprobado:** el primer fotograma del clip convertido difiere de la
   pose capturada en el juego **0,056° (Kael) y 0,040° (Lya y Garon) como mucho**.

**Posador:** no ha hecho falta: la IK de dos huesos está en `esperas_lib.py` (la misma idea que `posador_ik.gd`, con
codo hacia un polo) y así cada fotograma se resuelve por script, sin arrastrar objetivos en el editor.

**Los clips** (*comprobado ejecutando*, `prueba_esperas`):

| Héroe | Espera | Duración | Qué hace | Claves |
|---|---|---|---|---|
| Kael | `espera_vigilar` | 4,8 s | Mano en la cadera; mira a su izquierda y luego por encima del hombro derecho | 422 |
| | `espera_empunadura` | 5,2 s | Baja el sable del hombro y apoya la punta en el suelo, delante y a su derecha; lo agarra también con la izquierda, lo gira para mirarle el filo y lo sube al hombro por fuera | 1.049 |
| | `espera_brazalete` | 4,8 s | Alza el antebrazo izquierdo, gira la muñeca mirando el brazalete, cierra y abre el puño dos veces y sacude la mano. **Nada nuevo de la historia:** sin brillo ni efecto | 921 |
| | `espera_impaciencia` | 4,2 s | Carga el peso en la pierna izquierda, golpea tres veces el suelo con la punta del pie derecho y resopla (hombros arriba y abajo) | 357 |
| Lya | `espera_flor` | 6,2 s | Ve una flor a sus pies, se agacha (la cadera baja 30 cm con las rodillas por IK) con el cetro inclinado a un lado, la roza con la mano izquierda ladeando la cabeza y se levanta | 439 |
| | `espera_cetro` | 5,4 s | Cruza el cetro delante con las dos manos, lo inclina para mirar el loto y se mece | 471 |
| | `espera_pelo` | 3,6 s | Se recoloca el pelo detrás de la oreja izquierda, ladeando la cabeza | 286 |
| Garon | `espera_hombros` | 5,4 s | Rueda los hombros dos veces y estira el cuello a un lado y al otro | 208 |
| | `espera_espalda` | 5,4 s | Baja las espadas a los lados con la punta en el suelo, saca pecho, mira arriba y se inclina a un lado y al otro | 687 |
| | `espera_apoyarse` | 5,6 s | Clava las dos espadas de punta en el suelo, delante y a los lados, y descansa el peso en ellas | 596 |

- **Nombres definitivos** (los de `animaciones/esperas/fuentes/esperas.py`, iguales en los `.res` y en
  `prueba_esperas.gd`): Kael `espera_vigilar`, `espera_empunadura`, `espera_brazalete` y `espera_impaciencia`; Lya
  `espera_flor`, `espera_cetro` y `espera_pelo`; Garon `espera_hombros`, `espera_espalda` y `espera_apoyarse`.
- **El brazalete de Kael** (aclaración del coordinador, 09/11): en el canon no hay «mano marcada»; es la mano del
  brazalete. `espera_brazalete` solo mira el brazalete del antebrazo izquierdo, gira la muñeca y abre y cierra la mano:
  no inventa una marca, no lo hace brillar ni añade ningún efecto.
- **Garon no lleva escudo** (`RUTA_ESCUDO` vacío en `garon_3d.gd`; lucha con dos espadas): «apoya el escudo» se ha
  hecho como «se apoya en las espadas».
- **Coste:** sin huesos nuevos. Cada clip lleva dos pistas por hueso (giro y posición; las que no cambian, con una
  clave): 132 pistas en Kael, 100 en Lya y 88 en Garon, y entre 208 y unas 1.000 claves. Los tres `.res` ocupan
  120 KB. Nada medido en el móvil (§ 7).

### 3. Esperas en el juego (`esperas_3d.gd`, nuevo)

- **Cuándo:** si el héroe lleva **de 6 a 9 s** quieto en su reposo de exploración (Kael con el reposo de su clip, Lya con
  el suyo, Garon en «Calma»), hace una de sus esperas al azar, **nunca la misma dos veces seguidas**; las siguientes,
  cada 10-16 s quieto. **Dos héroes no empiezan a la vez** (3 s entre una y otra, contados con el tiempo del juego).
- **Entrada y salida:** fundido de 0,45 s desde el reposo y de 0,5 s de vuelta (empieza antes de que acabe el clip).
  Como el clip empieza y acaba en la pose del juego, no salta. Los gestos que hubiera (los brazos relajados de Lya) se
  quitan al entrar y vuelven al salir; el cetro de Lya va con la mano durante la espera y vuelve a ir derecho al acabar.
- **Se corta** (0,2 s) al moverse (`marcha`, `andar`, `correr`), con cualquier otra animación (`play`) o al empezar un
  diálogo de Dialogic; no empieza ninguna durante un diálogo. Las miradas a quien habla (`grupo_3d.gd`) no cambian.
- **Dónde:** `prototipos/vista3d.gd` las activa para Kael y `zonas3d/grupo_3d.gd` para Lya y Garon, así que salen en
  Pastos Verdes 3D y en la Garganta 3D (que heredan de `vista3d.gd` y usan `grupo_3d.gd`). **El combate no las activa**
  (comprobado: Kael 12 s quieto, sin esperas). Los enemigos que heredan de `maga_3d.gd` no tienen ni esperas ni porte.

### 4. Porte al andar y al correr (`maga_3d.gd`, ESTILOS)

El esqueleto lo permite y el clip es el mismo para los tres, así que el porte va **sumado** al clip con un tipo de gesto
nuevo de `gestos_3d.gd` («+hueso»: un giro que se suma al del clip en vez de orientar el hueso, fijo o de ida y vuelta):
- **Kael:** echado hacia delante (columna 5° al andar, 9° al correr) con la cabeza alta: tira del grupo.
- **Lya:** erguida (pecho 3° atrás) y **mirando alrededor sin prisa** al andar (la cabeza va y viene ±9° cada 4,8 s y se
  ladea ±3°); al correr, 4° adelante.
- **Garon:** pecho fuera (4° atrás) y la mirada al frente, algo baja (5°); al correr, 6° adelante con el pecho firme.
- **El ritmo no cambia:** lo fija la velocidad para que el pie apoyado no patine (tanda 2). Cambiarlo pediría clips de
  andar propios (§ 9).
- *Comprobado ejecutando* (capturas de lado, mismas fases del clip, sin y con porte): el cambio es **sutil**, sobre todo
  en Kael (cuerpo pequeño y cabeza grande). Lámina en § 7. No lo he exagerado sin que lo vea alguien.

### 5. Diálogos: gestos por la intención de la frase

- `dialogos/retrato_vivo.gd`: tres movimientos nuevos, breves (menos de 1,3 s) y que vuelven al reposo:
  - **risa:** tres botes cortos que se apagan, con el cuerpo suelto;
  - **enfado:** se tensa, se echa hacia el otro con una sacudida seca y vuelve;
  - **animo:** se yergue, se inclina hacia el otro y asiente.

  Y etiquetas **«pose+movimiento»**: la ilustración de un gesto con el movimiento de otro («ligero+risa»: la mano en la
  cadera mientras se ríe). La «duda» ya existía (ladea la cabeza). **El resaltado de quien habla no cambia** (el foco
  va en `$Foco`; los gestos, en `$Foco/Gesto`).
- **Etiquetas** (solo líneas `update`; **ninguna frase cambia**, comprobado línea a línea con `diff`):

| Diálogo | Frase | Antes | Ahora | Por qué |
|---|---|---|---|---|
| Prólogo | Kael: «Lo he visto. Y como siempre, a mí ni me roza…» | ligero | ligero+risa | Bromea |
| | Lya: «No bromees. Nadie es inmune a la niebla…» | — | enfado | Le riñe |
| | Kael: «Entonces vamos…» | decidido | decidido+animo | Anima a ir |
| | Lya: «Los Hollines ya no son solo sombras…» | — | firme | Advierte |
| PV-03 | Kael: «Pensaba dejarte dormir. Es distinto.» | ligero | ligero+risa | Se escabulle con una broma |
| | Lya: «Te dije «ten cuidado». No «vete solo».» | decidida | decidida+enfado | Le reprocha |

  Las demás frases conservan su gesto (o ninguno): nadie se mueve en cada frase y nadie repite el mismo gesto seguido.
- *Comprobado ejecutando*: `prueba_prologo` superada (retratos, poses de Kael y de Lya en cada frase, saltar, deprisa y
  reabrir) y `prueba_prologo_video` con ventana, sin fallos (las 11 frases a ritmo de lectura, reabierto deprisa con 5
  frases y 8 pulsaciones, saltado con Esc y vuelta al mapa).

### 6. Pruebas
- **`prueba_esperas`** (nueva, automática; *comprobado ejecutando*): los clips de cada héroe (duración, pistas, claves,
  sin bucle); cada espera, de principio a fin, vuelve a su reposo con sus gestos y el cetro derecho; seis disparos
  seguidos estando quieto **sin repetir** (p. ej. Kael: empuñadura, brazalete, vigilar, empuñadura, impaciencia,
  vigilar); **se cortan al andar** (`marcha`: pasa a «Running»/«Correr») y con otra animación (`reposo()`); **en
  combate no hay** (12 s quieto); y **en Pastos Verdes 3D** con Lya y Garon: Lya a los 7,4 s quieta, Garon a los 9,9 y
  Kael a los 13,4 (esperó su turno), y al andar Kael con el stick se cortan todas. Superada.
- **`prueba_esperas_fotos`** (nueva, con ventana): capturas en estudio y, con «porte», el porte al andar.
- **Batería completa** (`ejecutar_pruebas.ps1`, 18:08-18:16): **56 superadas, 2 fallidas, 32 manuales, 0 no seguras**.
  Partida real (`A3F3C402…`) y carpeta real de datos **sin cambios** (había 147 Godot de otras copias). Resumen:
  `D:\REBELUM_diagnostico\animaciones\2026-11-09\bateria_personalidad\2026-11-09_180819\resumen.md`.
  - **Las dos fallidas, `prueba_mando` y `prueba_teclado`, no vienen de este trabajo:** «Intro / A junto a Tilo no abre
    el diálogo». Desde `c3f5692` (en `eb8bd94`), hablar con Tilo antes de PV-03 hace llegar a Lya y el diálogo empieza
    1,2 s después (`_escena_pendiente`, `LLEGADA_LYA`), pero la prueba mira `current_timeline` pocos fotogramas después
    de pulsar. **Comprobado:** con las esperas desactivadas a mano (sin confirmar y deshecho después), `prueba_mando`
    falla igual (`D:\REBELUM_diagnostico\animaciones\2026-11-09\causa_prueba_mando_sin_esperas\`). Arreglo en § 9.
- **Pasada final** con el código definitivo (`ae25958`, 18:23): `prueba_esperas`, `prueba_prologo`, `prueba_grupo3d`,
  `prueba_anim_pies`, `prueba_dialogo`, `prueba_ruta_alpha` y `prueba_efectos`: **7 superadas, 0 fallidas**; partida y
  carpeta real sin cambios. Resumen:
  `D:\REBELUM_diagnostico\animaciones\2026-11-09\bateria_personalidad_final\2026-11-09_182347\resumen.md`.
- Importaciones aisladas: `D:\REBELUM_diagnostico\importaciones\anim_personalidad_20261109_172526\` (tras la unión) y
  `anim_esperas_20261109_180622\` (tras los archivos nuevos).

### 7. Evidencias
En `D:\REBELUM_diagnostico\animaciones\2026-11-09\esperas\`:
- `laminas\antes_reposo_izq_despues_esperas_{kael,lya,garon}.png`: el reposo de siempre (antes, a la izquierda) y un
  momento de cada espera; `laminas\<héroe>_esperas_filas_34_y_lado_7_momentos.png`: cada espera en 7 momentos, de 3/4
  y de lado (filas alternas);
- `laminas\<héroe>_porte_filas_andar_antes_despues_correr_antes_despues.png`: el porte, sin y con él;
- `video\esperas_estudio.mp4` (44 s, 720 × 900, las diez esperas seguidas, con su nombre);
- `region\region_*.jpg`: Pastos Verdes 3D con la cámara del juego (9 m): Kael, Lya y Garon haciendo sus esperas uno
  tras otro;
- `estudio\` (fotogramas sueltos), `porte\`, `glb\` (los GLB intermedios) y `registros\`.

En `D:\REBELUM_diagnostico\animaciones\2026-11-09\personalidad_dialogos\`: `prologo_gestos_intencion.mp4` (el prólogo
en movimiento con los gestos nuevos, reabierto deprisa y saltado) y `prologo\despues_frase_*_{a,b}.png` (cada frase al
salir y al final de la lectura). El «antes» comparable es el de la tanda 2:
`D:\REBELUM_diagnostico\animaciones\2026-11-09\prologo\despues\` y `...\2026-11-08\prologo\videos\prologo_despues.mp4`
(el prólogo tenía entonces 9 frases; ahora 11, por T-086).

### 8. Límites
- **Pendiente en Redmi:** el coste de las esperas y del porte en el Mali-G57 (unas cuentas más por fotograma: el clip
  de espera en lugar del de reposo y, en Lya, el cetro), cómo se leen a la distancia de la cámara del juego en la
  pantalla del teléfono y el tacto de los fundidos. **No he medido rendimiento** (había otros especialistas trabajando)
  ni afirmo nada del móvil.
- **No visto por una persona:** las capturas y los vídeos los he revisado yo. Las poses son sobrias a propósito (cuerpo
  chibi, armas grandes): el sable de Kael mide casi como él, así que la empuñadura se revisa con la punta en el suelo
  (con el sable en alto le tapaba la cara: lo vi en la primera versión y lo corregí).
- **Colisiones finas:** no hay comprobación automática de que un arma no roce el cuerpo; lo he mirado en las capturas
  de 3/4 y de lado (corregido: el sable delante de la cara de Kael y las espadas de Garon atravesando el suelo).
- **Lya no cierra las manos** (tanda 2): sus gestos son de mano abierta.
- **El porte no cambia el ritmo:** los tres usan el mismo clip de Meshy y el ritmo lo fija el pie quieto en el suelo.
- **T-101 (cinemática de Érebo): no empezada**, no quedaba margen. Nada de esta tanda toca a Érebo ni revela nada.
- `pruebas/prueba_orden_pv03.gd.uid` (de la integración, no mío) queda sin confirmar.

### 9. Siguiente paso y cambios que necesito en archivos de otros
- **Para quien lleve `pruebas/prueba_mando.gd` y `pruebas/prueba_teclado.gd`:** tras pulsar «aceptar» junto a Tilo,
  esperar a que empiece el diálogo en vez de mirar enseguida, porque ahora Lya llega antes (1,2 s). Por ejemplo, en el
  paso 4 cambiar `if D.current_timeline == null:` por
  `if not await _hasta(func(): return D.current_timeline != null, 3.0):`.
- **`docs/versiones/licencias_pendientes.txt`** (del coordinador): las esperas son animación propia, sin geometría de
  Meshy, pero solo sirven con sus modelos; si se quiere el mismo trato que los retratos, añadir `animaciones/esperas/`.
- **Siguiente paso propuesto:**
  1. probarlo en el Redmi (pendiente en Redmi) y medir el coste con el banco de la región;
  2. si gusta, más esperas por héroe (alguna propia de cada zona) y esperas en pareja (Lya le enseña algo a Kael) con
     las miradas de `grupo_3d.gd`;
  3. andares propios (clips de Blender con el mismo método) si el porte sumado se queda corto;
  4. T-101, la cinemática de Érebo.

## 2026-11-09 23:10 · T-101: la invocación nueva de Érebo (variante elegible en Ajustes; la de siempre, intacta) y el gesto de cubrir de Garon

**Versión de partida:** `area-animaciones` @ `4705db9`. Uní `integracion-experimental` dos veces con `--no-ff` y sin
conflictos: `6adc4d9` durante el trabajo (`da13602`) y `dca4c1c` al reanudar tras el límite de uso (`501fc78`). Los
`.uid` sin seguimiento que ya venían en la integración (`prueba_orden_pv03.gd.uid` y `prueba_comentarios_3d.gd.uid`)
están apartados en `D:\REBELUM_respaldos\2026-11-09_uids\animaciones\`. Todo lo comprobado es del 2026-11-09, con datos
aislados; la carpeta real de datos no cambió en ninguna ejecución. **Sin Redmi.** Leídos T-101, T-051, T-072, las
decisiones D1-D12 (`D:\Aethelgard\docs\erebo\invocacion_erebo_cinematica.md` y `invocacion_erebo_plan_final.md`) y la
memoria `erebo-invocacion-direccion`.

**Al reanudar:** las esperas a prueba de saltos (`_hasta_fin`) y los recortes de tiempo sí estaban guardados, en
`ba858aa` (comprobado con `git show 095f2cf:aethelgard/invocacion_erebo_nueva.gd`). Lo que no había acabado era la
batería: la de las 18:55 se cortó a medias y en ella `prueba_erebo_nueva` salió FALLIDA con «FALLOS: 0». **Causa:**
`ejecutar_pruebas.ps1` busca `\bFALLO\b` sin distinguir mayúsculas (`-match`), y la prueba escribía «TEATRO fallo: …» en
el caso de la mano vacía. Arreglado en la prueba (`521f2f0`: ahora escribe «mano vacía»); el ejecutor no lo toco.

**Commits** en `area-animaciones`, sin publicar:
- `ba858aa`: `invocacion_erebo_nueva.gd` (nuevo) y `erebo_3d.gd`;
- `8ca0bc9`: la elección en Ajustes (`menus.gd`) y el enganche en el teatro (`combate.gd`, `_teatro_erebo`);
- `64a9fb9`: `pruebas/prueba_erebo_nueva.gd`, `lista_pruebas.txt` y `animaciones/erebo/fuentes/referencia_erebo.py`;
- `da13602` y `501fc78`: las uniones; `095f2cf`: los `.uid`;
- `521f2f0`: la prueba no escribe «fallo» en lo normal y tiene un modo «video»;
- `13708c0`: el plano lateral de P8 llega al agarrar el orbe (también con la mano vacía) y el enemigo se vacía mientras tira;
- `f2d8960`: el gesto de cubrir de Garon en la Guardia (`garon_3d.gd` y `combate.gd`);
- y el de este informe.

### 1. Antes: la invocación de siempre (*comprobado ejecutando*, la misma prueba con «variante=actual»)
- Dura **17,3 s** con éxito y **12,0 s** con fallo (la memoria hablaba de ≈16,4 s).
- **La mano no llega al pecho:** Érebo se coloca a 0,95 m fijos del enemigo y la mano se queda en el aire (se ve en
  `hoja_actual_exito_cada_0,5s.png`, filas 3-4). Es la causa medida en la Fase 1 (0,52-0,56 m de error).

### 2. Vídeo de referencia (Blender 5.2.3 por script)
`animaciones/erebo/fuentes/referencia_erebo.py` (con `.gdignore`) monta con los modelos del juego (Érebo con sus clips
de Mixamo, Lya, Kael y Grimfang) los planos P1-P11 de la propuesta con sus tiempos y cámaras, y coloca a Érebo por la
mano (corrección de 0,45 m: la mano quedaba a 0,46 m del pecho). Es una previsualización: sin efectos del juego.
- `D:\REBELUM_diagnostico\animaciones\2026-11-09\erebo\referencia\erebo_nueva_exito_referencia.mp4` (11,8 s) y
  `erebo_nueva_fallo_referencia.mp4` (9,0 s), 640 × 360, con el tiempo y el fotograma impresos;
- `planos\exito_P*.png` y `planos\fallo_P*.png` (un fotograma por plano) y `hoja_planos_exito.png`.

### 3. La nueva, en el juego (`invocacion_erebo_nueva.gd`)
Sigue P1-P11 con las recomendaciones de D1-D12 que **siguen abiertas (T-072)**, tomadas como variante experimental:
- **P1** Lya alza el cetro, la luz baja al 60 % y Kael se vuelve hacia ella; **P2** la sombra se desprende y corre a ras
  de suelo; **P3** el enemigo se pone alerta, el suelo tiembla y sale el título; **P4** grúa en órbita de 140° mientras
  Érebo **surge con la pose quieta** (D7), la cabeza baja y la levanta al final, y queda **levitando 5 cm** (D8); Kael da
  medio paso atrás en guardia; **P5** por encima del hombro del enemigo, la máscara arriba; **P6-P7** por detrás del
  hombro derecho de Érebo (D4), **se acerca flotando 0,3 m** (D6) y mete **la mano abierta** con un solo clip,
  «Extraer» (D2); cámara lenta y pausa de impacto en el contacto, onda en el pecho y el enemigo se arquea; **P8** tira
  del orbe (el enemigo se vacía) y se aparta flotando; **P9** de frente a la máscara, **tres latidos y 0,3 s de
  silencio**; **P10** el resultado se aplica al cerrarse las palmas, plano general, Kael aparta la cara; **P11** se hunde
  mientras la sombra vuelve a Lya, la luz sube, la cámara vuelve a la del teatro y Lya respira hondo.
- **Fallo:** P1-P7, la mano sale vacía con humo, Kael resopla (su `espera_impaciencia`), a Lya se le escapa el aire, y
  Érebo se hunde.
- **Colocación por la mano** (el arreglo de la Fase 1, que se conserva): pecho real del enemigo (su `Spine2` más la
  profundidad del torso, 0,133 × alto), la punta de la mano de Érebo en «Extraer» a 0,80 s medida en el propio juego
  (`erebo_3d.gd`, `punta_en`), la escala `k = clamp(alto del pecho / alto de la mano, 0,8, 1,6)` (al menos ×1 si el pecho
  está a 0,7 m o más) y una **IK de alcance** de dos huesos (`ik_mano`, dos pasadas por fotograma) que corrige el resto.
  **Comprobado:** en el contacto, la punta queda a **1,0 cm** del punto del pecho con Grimfang y a **0,4 cm** con el
  doble de jefe ×1,6 (Fase 1: 0-2 cm).
- **Reglas sin cambios:** el mismo dado que la de siempre (`randf()` una vez, ninguna con un jefe), el resultado se aplica
  **una vez** en el fotograma en que se cierran las palmas (o al saltar), y saltar devuelve tiempo, cámara, luces,
  sombra y personajes. **Saltar ya no se puede quedar colgado:** las esperas largas de Érebo y la sombra van por
  `_hasta_fin`, que también acaba si se salta (al saltar, `limpiar()` mata sus tweens y un `await tween.finished` no
  volvería).
- **Nada del acto III:** el orbe va vacío, sin hilos cálidos, sin puntos que se acumulen y sin reverencia; el título
  sigue siendo «Ladrón de Corazones». Las variantes por etapa (E0-E4) no están: dependen de la biblia v3 (D5).
- **Coste:** sin partículas nuevas (las de siempre de `erebo_3d.gd`, que ya bajan en «movil»); Kael es el mismo modelo
  del combate. Sin medir en el móvil.
- **`erebo_3d.gd`:** funciones nuevas (`emerger_quieto`, `deslizar`, `extraer_abierto`, `punta_en`, la IK de alcance) y
  `aplastar` con latidos, silencio y modo rápido como parámetros. **Con los valores por defecto, la de siempre hace lo
  mismo** (mismos tiempos, mismo número de latidos).

### 4. Elegirla en Ajustes
- `menus.gd`: «Invocación de Érebo: La de siempre / Nueva (en pruebas)», en los Ajustes de la versión experimental,
  junto al mapa y la Garganta 3D; se guarda en `user://ajustes.cfg`, sección `[combate]`. **Por defecto, la de siempre.**
- `combate.gd`, `_teatro_erebo`: si se ha elegido la nueva, usa `invocacion_erebo_nueva.gd` y le dice si Kael está en
  pie. **No toco** las reglas, la Armonía ni el HUD de disponibilidad y motivo.

### 5. Pruebas (aisladas, desde PowerShell)
- **`prueba_erebo_nueva`** (nueva, automática; *comprobado ejecutando*). En un teatro como el del combate (Lya, Kael,
  Grimfang y la cámara):

  | Caso | Dura (con los 0,6 s en que vuelve la cámara) | Resultado aplicado | La punta de la mano, del pecho |
  |---|---|---|---|
  | Éxito | 12,7 s | una vez: muerte | 1,0 cm |
  | Mano vacía | 10,0 s | una vez: nada | 1,0 cm |
  | Jefe (doble ×1,6) | 12,7 s | una vez: 20 % de su vida actual, sin muerte | 0,4 cm |
  | Saltada a los 0,5 s | 1,1 s | una vez | — |
  | Saltada a los 9,5 s | 9,5 s | una vez | 1,0 cm |
  | Mano vacía saltada a los 7,5 s | 7,5 s | una vez | 1,0 cm |

  En todos, el tiempo vuelve a ×1, la cámara a su sitio, las luces a su energía y Érebo queda oculto. Y **en un combate
  de verdad** (`combate.tscn` con «-- invocar erebo=exito erebo_nueva»): Lya invoca con la variante nueva, el enemigo
  muere una vez, el teatro se cierra y el combate sigue. La de siempre, con la misma prueba («variante=actual»): 17,3 s y
  12,0 s, resultado aplicado una vez.
- **Batería completa** sobre `521f2f0` (tras unir `dca4c1c`; 22:46-23:00): **68 superadas, 0 fallidas, 35 manuales, 0 no
  seguras**. Partida real (`A3F3C402…`) y carpeta real de datos **sin cambios**. Resumen:
  `D:\REBELUM_diagnostico\animaciones\2026-11-09\bateria_t101_final\2026-11-09_224646\resumen.md`.
  - **La huella del combate, intacta:** `prueba_combate_huella`, 9 de 9 combates iguales a la referencia y dos pasadas
    iguales (con «Érebo» dentro, que usa la invocación de siempre). La invocación de siempre no cambia.
  - `prueba_mando` y `prueba_teclado`, superadas (la integración ya traía su arreglo).
- **Pasada final** con el código definitivo (`f2d8960`, 23:01-23:03): `prueba_erebo_nueva`, `prueba_combate_huella`,
  `prueba_artes`, `prueba_artes_combate`, `prueba_hud_combate`, `prueba_esperas`, `prueba_grupo3d` y
  `prueba_escarcha_guardia` (la Guardia de Garon en combates de verdad, con el gesto nuevo): **8 superadas, 0
  fallidas**; partida y carpeta real sin cambios. Resúmenes en
  `D:\REBELUM_diagnostico\animaciones\2026-11-09\bateria_t101_cubrir\`.
- Importaciones aisladas: `D:\REBELUM_diagnostico\importaciones\anim_t101_*`.

### 5 bis. Garon: el gesto de cubrir (la Guardia, T-100)
- **Antes** (*observado en el código*): al elegir la Guardia, Garon se volvía hacia el aliado, daba un paso y a los
  0,7 s volvía a su guardia de combate de siempre: nada distinguía que estaba cubriendo.
- **Ahora** (`garon_3d.gd`, `cubrir()` y `fin_cubrir()`; `f2d8960`): se planta (rodillas dobladas, el peso abajo y el
  cuerpo echado hacia el golpe, de cara a los enemigos y con las espadas en su guardia cruzada) y se queda así mientras
  cubre: su reposo no lo quita. Lo deja al atacar o al caer, y `combate.gd` lo quita en `_quitar_guardia` cuando se
  acaba la Guardia. Sin cambios de reglas ni de ATB (la huella, igual).
- Probé antes unas espadas cruzadas en aspa delante del pecho (con giros de brazo): las hojas salían en horizontal, como
  alas, porque la dirección de cada espada sale del pulgar de su mano. Lo dejé en la postura plantada, que se lee bien.
- Capturas: `D:\REBELUM_diagnostico\animaciones\2026-11-09\garon_cubrir\garon_guardia_izq_cubre_dcha.png` (de 3/4 y de
  lado, la guardia de siempre y cubriendo).

### 6. Evidencias
En `D:\REBELUM_diagnostico\animaciones\2026-11-09\erebo\`:
- **`erebo_antes_izq_despues_dcha.mp4`** (30 s, 1920 × 600, 15 fps): la de siempre a la izquierda y la nueva a la
  derecha, en el mismo teatro y con la misma luz, primero con éxito (17,3 s frente a 12,7 s) y después con la mano vacía
  (12,0 s frente a 10,0 s). Sus fotogramas, en `video_juego\`;
- `referencia\`: los dos vídeos de Blender, los planos y su hoja;
- `hoja_actual_exito_cada_0,5s.png` y `hoja_nueva_exito_cada_0,5s.png` (antes y después, una captura cada 0,5 s en el
  teatro con la luz del combate); `hoja_actual_fallo_…` y `hoja_nueva_fallo_…`;
- `juego\`: las capturas sueltas y sus registros.

### 7. Límites
- **Pendiente en Redmi:** el coste en el Mali-G57 (no he medido rendimiento) y cómo se ven la luz que baja, la cámara
  lenta y la grúa en el teléfono.
- **D1-D12 siguen abiertas (T-072):** esto es la variante con las recomendaciones; lo decide el usuario viéndola.
- **No hay versión corta (≈5,6 s)** de la nueva ni la regla de D11 (la completa la primera vez); con la nueva elegida
  siempre se ve la completa (se puede saltar).
- **Sin sonido nuevo** (D9, D12): usa los `erebo_*.wav` de siempre en los momentos nuevos (pulso en el contacto,
  fractura, resonancia, susurros).
- **El enemigo** solo se arquea, se vacía y muere como siempre (sin la ceniza violeta de D3) y no se gira hacia Érebo si
  es un dibujo 2D.
- **Las capturas** de la variante están hechas en el teatro de la prueba (mismo suelo, fondo y luces que el del
  combate, sin el dibujo de la zona al fondo); la prueba también la juega en un combate de verdad (sin capturas).
- **La de siempre** podría quedarse colgada si se salta justo durante el aplastamiento (espera un tween que `limpiar()`
  mata). No lo he comprobado ni tocado: es su código. La nueva no tiene ese problema.
- **La señal `aviso` de las otras cinco bestias** (cencerrante, custodio_cal, hilandera_eco, posadero_hueco y velaria): no
  está hecha. Sus modelos solo están en la entrada del usuario
  (`D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\REBELUM_Bestiario\modelos\`), no en el juego: cada una pide
  prepararla como Zarzalín (T-097: modelo, clips de aviso, escena y guion) antes de poder emitir `aviso`.
- **El plano lateral de P8** (lado B, como pide la propuesta) sale más oscuro que los demás: la luz del teatro viene del
  lado A. Se ve la mano con el orbe, pero es el plano más apagado de la secuencia.

### 8. Siguiente paso
- Que el usuario vea la nueva (Ajustes → Invocación de Érebo → Nueva) y decida D1-D12; con lo que apruebe, la versión
  corta, la regla de D11, la ceniza (D3) y las variantes por etapa (D5) cuando la v3 se cierre.
- Medir en el Redmi y, si hiciera falta, los perfiles de D10.
- **Pendiente en Redmi:** ver la nueva y el gesto de cubrir en el teléfono, y medir su coste.
- **Cambios en archivos de otros (ya hechos en mi rama, para revisar al integrar):** `combate.gd` (la elección de la
  invocación en `_teatro_erebo`; `cubrir` en `_guardia` y `fin_cubrir` en `_quitar_guardia`) y `menus.gd` (la opción de
  Ajustes). Son pocas líneas y no tocan reglas, ATB ni HUD.
- **Para el ejecutor (`pruebas/ejecutar_pruebas.ps1`, del coordinador):** `\bFALLO\b` se busca sin distinguir mayúsculas,
  así que cualquier «fallo» en minúsculas de una línea normal marca la prueba como FALLIDA. Si se quiere, `-cmatch` en
  ese patrón; mientras tanto, las pruebas no deben escribir «fallo» salvo para declarar uno.

## 2026-11-09 23:50 · T-097, segunda bestia: Cencerrante preparado para el combate (modelo, clips y escena)

**Versión de partida:** `area-animaciones` @ `187fb08`, unida con `integracion-experimental` @ `45a49e6` (`a27713e`,
`--no-ff`, sin conflictos). Todo lo comprobado es del 2026-11-09, entre las 23:10 y las 23:50, con datos aislados; la
carpeta real de datos no cambió en ninguna ejecución. **Sin Redmi. No toco `combate.gd`:** el enganche es de combate.

**Commits** en `area-animaciones`, sin publicar: `2d0f8ed` (modelo, escena, guion y guion de Blender), `ddfa667` (las
pruebas y `lista_pruebas.txt`), `83670c6` (`docs/recursos.md` y `docs/versiones/licencias_pendientes.txt`) y el de este
informe.

### 1. El modelo del usuario (*comprobado ejecutando*, Blender 5.2.3 y Godot 4.7.2)
- `cencerrante.blend` y `cencerrante.glb` del bestiario (`D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\`): una
  malla de 6.288 triángulos (1,52 m de alto, 0,86 de ancho y 0,38 de fondo, pies en y = 0), un material y un esqueleto
  de **9 huesos** (root, body, bell y muslo, espinilla y pie de cada lado). Mira a -Y en Blender y a +Z en Godot, como
  Zarzalín: con `FRENTE_ENEMIGO` queda de 3/4 mirando a los héroes (53°).
- Clips del usuario, sin tocar: `reposo` (1,07 s), `toque_de_alarma` (1,4 s; la campana toma impulso y **repica a
  0,733 s**, el valor de la ficha), `campanada_baja` (1,17 s; el marco carga hacia delante 0,48 m y **golpea a
  0,533 s**) y `recibir_golpe` (0,6 s).
- Material de Compatibility (`StandardMaterial3D`): color, normales y rugosidad y metal (canal B), a doble cara.
- El reposo del usuario sube y baja la raíz 2 cm, y los pies con ella: no lo cambio (es su clip), pero se nota de cerca.

### 2. Clips nuevos (Blender 5.2.3 por script, sobre una copia)
`enemigos/cencerrante/fuentes_blender/crear_clips.py` (con `.gdignore`; el método del de Zarzalín: giros sobre una pose
base y la raíz apoyada en el suelo con la malla deformada) añade:
- `derrota` (1,2 s): las patas ceden, la campana da un último golpe y el marco **cae de espaldas** (lejos de los
  héroes), rebota y se queda;
- `entrada` (1,2 s): **dos saltos** desde 0,85 m por detrás, la campana se balancea al caer y queda en reposo;
- `correr` (0,53 s, en bucle): anda **a saltitos** en el sitio, una pata y otra, con la campana meciéndose (para el
  acercamiento del combate).

El `.blend` del usuario sigue igual (SHA-256 `bd2d3464dd502a11…`). La copia con los clips nuevos y el GLB exportado están
fuera del historial, en `D:\REBELUM_diagnostico\bestiario\2026-11-09\cencerrante\blender\` y `exportado\`.

### 3. Texturas (la medida de Garon, `D:\REBELUM_diagnostico\optimizacion\2026-11-09_texturas\`)
Las tres 2K van **comprimidas para la GPU**: 10,7 MB en total (sin comprimir serían unos 48). Las normales, con
`normal_map=1`. **El color también:** en un primer plano de la campana (0,75 m de alto de vista, más cerca que cualquier
cámara del juego), sin comprimir frente a comprimida, diferencia media **1,3/255**, máxima 24/255; el 0,5 % de los
píxeles cambia más de 8/255 y el 0,013 % más de 16/255. A simple vista son iguales (lámina en § 6).

### 4. La escena y su API (para combate)
`enemigos/cencerrante/cencerrante_3d.tscn` (o `cencerrante_3d.gd` con `.new()` y `ruta_modelo`), con lo que el combate
ya llama a un enemigo 3D (`reposo`, `correr`/`andar`, `herida`, `morir`, `cansada`, `revivir`, `victoria`, `mirar`,
`mirar_frente`, `punto_magia`, `ALTURA` = 1,52 m, `anim`, `skel`, `pivote`…) y además:
- `atacar("campanada_baja", al_impactar)` (con `await`): **un único impacto** a 0,533 s (señal `impacto` y
  `al_impactar`, una vez, también si algo corta el clip); vuelve al reposo y emite `ataque_terminado`.
- `avisar("toque_de_alarma")` (con `await`): **señal `aviso` una vez, en el repique** (0,733 s), y vuelve al reposo.
  La regla de la ficha (el siguiente golpe de un aliado reforzado, o el suyo si está solo, con una sola activación) es
  del combate.
- `recibir_golpe()`, `derrota()` y `entrada()` (emiten `clip_terminado`).
- `alcance("campanada_baja")` = **0,379 m** (lo que adelanta la boca de la campana en el impacto), `tiempo_impacto()`,
  `campana()` (la boca de la campana) y `CENTRO` = 0,95 m (la campana: números y destellos).
- Un golpe recibido no corta ni el ataque ni el toque ni la entrada.
- **Encuadre propuesto (inferencia, sin medir clip a clip como con Zarzalín):** a escala ×1,0 es casi tan alto como Kael
  (lámina en § 6). Una ventana 3D de unos 840 × 560 px, con 2,0 m de alto de vista y el centro a 0,8 m (280 px/m, como
  Grimfang), cabe la carga hacia delante y la caída de espaldas.

### 5. Pruebas
- **Nueva `prueba_cencerrante_modelo`** (automática; en `lista_pruebas.txt`). Comprueba:
  - los 7 clips; en bucle solo reposo y correr; cada clip gira los 9 huesos;
  - campanada, toque, golpe y entrada acaban en el reposo y los bucles cierran (0,00°); texturas comprimidas;
  - el impacto, una vez y en su ancla (0,533 s; el clip va por 0,532), también con 1 s de pausa a medias y con un golpe
    recibido a medias; el aviso, una vez y en el repique (0,733 s);
  - la derrota de espaldas (raíz a 88°, el marco hacia atrás), que no ataca ni avisa; revivir; la entrada desde 0,84 m
    atrás; liberado a mitad de un ataque; creado con `.new()`.

  **FALLOS: 0.**
- **Nueva `prueba_cencerrante_fotos`** (con ventana): lo mismo y las capturas. FALLOS: 0.
- Con el ejecutor (23:22): `prueba_cencerrante_modelo`, `prueba_zarzalin_modelo`, `prueba_escenas` y
  **`prueba_combate_huella`**, SUPERADAS (`D:\REBELUM_diagnostico\bestiario\2026-11-09\cencerrante\pruebas\2026-11-09_232252\resumen.md`).
- **Aviso: `prueba_integridad` se cae a veces al salir desde que está Cencerrante** (código -1073741819, sin mensaje y
  con «FALLOS: 0» ya escrito): 4 de 15 pasadas.
  - Sin la escena de Cencerrante: 0 de 17. Sin la de Zarzalín (y con la de Cencerrante): 0 de 6. Cargando solo las dos
    escenas, sin el resto del proyecto: 0 de 8.
  - Solo pasa con las dos bestias y el resto del proyecto cargados a la vez, al cerrar Godot sin ventana. No he
    encontrado la causa: no es un uid repetido, ni la cámara del `.blend` (el GLB no la lleva).
  - Registros en `D:\REBELUM_diagnostico\bestiario\2026-11-09\cencerrante\pruebas_integridad_ab\`.

### 6. Evidencias
En `D:\REBELUM_diagnostico\bestiario\2026-11-09\cencerrante\`:
- `laminas\secuencia_clips.png`: junto a Kael (la escala), el toque (impulso y repique), la campanada (impulso e
  impacto), el golpe recibido, la entrada, el andar y la derrota;
- `laminas\color_sin_comprimir_izq_comprimido_centro_diferencia_x8_dcha.png`;
- `capturas\` (cada clip en varios momentos, con la luz y la cámara del combate) y los registros de las pruebas.

### 7. Límites
- **Sin enganchar al combate** y **pendiente en Redmi** (no he medido rendimiento).
- El encuadre es una propuesta sin medir clip a clip; la escala la decide el coordinador.
- El sonido (bronce hueco y cuerda) no está: `aviso` e `impacto` son sus anclas.
- La caída de `prueba_integridad` al salir (§ 5).

### 8. Siguiente paso y cambios en archivos de otros
- **Combate (`combate.gd`):** las entradas de `MODELOS` y `ENEMIGOS` con el encuadre de § 4 y el centro a 0,95 m; la
  campanada con `atacar()`, colocándolo a `alcance()` del objetivo; el toque con `avisar()` y la regla de una sola
  activación; y su prueba de combate.
- **Coordinador (`prueba_integridad` y el ejecutor):** decidir qué hacer con la caída al salir: repetir la prueba una
  vez si el código es -1073741819 y la salida ya dice «FALLOS: 0», o buscar la causa con un Godot con símbolos.
- **Sonido:** el bronce y la cuerda, con las señales `aviso` e `impacto`.

## 14/11/2026 02:20 — Nix piloto desde el FBX del usuario (rama claude/v12-nix-piloto)

Informe completo: `docs/v12/NIX_PILOTO_FBX.md`. En corto:
- **Hecho y comprobado (PC):** el FBX Silver Sentinel (Nix base lisa) reducido de 436.194 a 11.968 triángulos con la
  cara protegida; textura rehorneada (1024 en el GLB, 2048 fuera); esqueleto común de los héroes v2 re-situado,
  48 huesos (36 deforman, 6 de mechones) y 4 pesos normalizados; mechones despegados del pecho; 23 clips con
  «canalizar» (mechones con retraso). En Godot tras el interruptor `nix_fbx` (APAGADO): `prueba_nix_fbx` SUPERADA
  (35/35), `prueba_nix_v12` SUPERADA, combate real con el FBX encendido sin fallos salvo dos comprobaciones propias del
  modelo antiguo; capturas en `D:\REBELUM_diagnostico\v12\expansion\nix\piloto_fbx\`.
- **Pendiente:** toda la ropa canónica como piezas separadas, cetro propio, faldones, emisión de iris y ornamentos,
  reajuste adulto de clips, velocidades de andar/correr medidas, brillo en escenarios reales, Redmi y rendimiento.

## 14/11/2026 02:30 — Capa de Garon (V12, fase 6), rama `claude/v12-capa-garon`

- Informe completo: `docs/v12/CAPA_GARON_V12.md`. Commits ff7aaaf y 2f198bc (locales, sin subir).
- Capa ARTICULADA nueva (`aethelgard/capa_garon.gd`: misma tela y talla, esqueleto propio de 21 huesos con Skin,
  sujeta al pecho y a los hombros, ajustada a la espalda de cada variante, movimiento progresivo, choques con cuerpo y
  las dos espadas). Opción APAGADA (`garon_3d.gd`, `capa_articulada()`); la rígida de siempre queda igual por defecto.
- Prueba nueva `prueba_capa_garon` (en `lista_pruebas.txt`) y `fotos_capa_garon` ampliada. Pasada aislada: 11 SUPERADAS
  por defecto, 8 con `capa_articulada`; capturas antes/después en `D:\REBELUM_diagnostico\v12\capa_garon\`.
- Hallado sin tocar: `AvanzarDoble` rompe el cuerpo de los v2/v3 (cadera a −0,04 m y 0,55 m de lado); la derrota de los
  v2/v3 hunde el cuerpo 0,29-0,56 m.
- Pendiente: verla y medirla en el Redmi; opción de Ajustes en `menus.gd`.

## 2026-11-14 03:45 · V12, fase 9 (PILOTO): meshy_e01 Custodio de Porcelana desde el FBX de Meshy

Rama local `claude/v12-custodio` (worktree `D:\Aethelgard_v12_custodio`, desde `claude/rebelum-v12` @ b451518). Detalle,
cifras, matriz y pendientes: `docs/v12/CUSTODIO_E01_V12.md`.

- **Hecho y comprobado ejecutando (PC, aislado, 14/11):** inspección del FBX (copia; SHA-256 del ZIP igual al del
  paquete); escala 1,85 m; rig bípedo de 24 huesos (21 deformantes) con pesos propios rígidos por placas (≤ 2 influencias);
  clips `e01__idle`, `e01__walk`, `e01__attack_prensa` horneados a 30 fps con IK de autoría (pies quietos, cadera 14,2 %,
  manos a 1 cm del suelo en el impacto 0,90); GLB reimportado en Godot; integración APAGADA (interruptor propio
  `meshy_e01`, solo GRUPOS[28]/[29], nunca al azar) con la Prensa del Umbral en el combate real (aviso en el clip, marca
  fija a 0,65, en fila, una vez por ejecución y objetivo, Retroceso, recarga de 2 turnos propios en guardia, limpieza al
  morir o cerrar).
- **Pruebas:** `prueba_meshy_e01` SUPERADA; `fotos_meshy_e01` MANUAL sin errores (revisada); 10 regresiones SUPERADAS
  (huella del combate incluida). Resúmenes en `D:\REBELUM_diagnostico\pruebas\2026-11-14_032221\` y `..._033850\`.
- **Evidencias:** `D:\REBELUM_diagnostico\v12\custodio\` (p1_inspeccion, p2_rig, p3_clips, p6_godot).
- **Límites:** 3 de 12 clips (sin muerte, golpe recibido ni guardia propios); 1 de 3 especiales; sin sonido propio; sin
  medir rendimiento (otros Godot abiertos) ni Android.
- **Archivos compartidos tocados:** `combate.gd` (ganchos «V12, Custodio»), `recursos.gd` (APAGADOS), `pruebas/lista_pruebas.txt`
  (2 líneas), `docs/recursos.md` (1 fila), `docs/versiones/licencias_pendientes.txt` (1 línea `meshy_e01`).
