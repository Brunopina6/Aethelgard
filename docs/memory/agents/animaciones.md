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
