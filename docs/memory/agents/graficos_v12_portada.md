# Gráficos · V12 · Pantalla de inicio alternativa (11/11/2026)

Especialista de gráficos e interfaz. Copia `D:\Aethelgard_v12_portada`, rama local `claude/v12-portada` (nace de
`claude/rebelum-v12` @ `8e328d9`). Commits: `6a2358b`, `e821b1b`, `7bb32d5` y el de este informe. Sin push ni merge.

**Estado: prototipo en pruebas, no sustituye a nada.** La pantalla original (`carga.tscn` + `carga.gd`) sigue siendo
la escena principal y, con la opción apagada, se comporta igual (comprobado ejecutando, aislado). La alternativa
funciona en el PC con teclado, toques simulados y mando simulado por las pruebas; **en el Redmi no se ha probado**.

## Qué es

`aethelgard/portada/inicio_alternativo.tscn`: otra pantalla de inicio, oscura y cinematográfica, con:

- **El mismo logo** (`marca/logo_rebelum.webp`, sin tocar), en el mismo sitio y tamaño (370, 14; 540 × 381) y con el
  mismo modo aditivo que `carga.gd`. Detrás, un hueco oscuro (para que el modo aditivo se vea como sobre negro) y un
  aura violeta que respira; encima, un destello que lo cruza en diagonal cada 9 s (otra pasada del mismo archivo con
  un sombreador; el logo no cambia). Entra con un fundido de 1,6 s.
- **«CÓNCLAVE DE LAS CENIZAS»** con la misma fuente, tamaño y color que la original, y dos filetes dorados con rombo.
- **Entorno hecho por código** (`portada/fondo_portada.gd`), en capas con paralaje suave (3, 7, 10 y 16 px):
  1. cielo (un solo sombreador a pantalla completa): degradado nocturno violeta y azul, nebulosa lenta, estrellas que
     titilan, dos cordilleras lejanas con niebla en la falda y la **luz mágica**: el haz azulado de un cristal en lo
     alto de una aguja, que respira y alumbra un poco lo que tiene cerca;
  2. **fortalezas en ruinas** (polígonos generados): un torreón sobre un risco con un puente roto (izquierda) y la
     ciudadela de la aguja con su acueducto roto (derecha), con niebla hacia la base, luz del cristal y ventanas con
     luz dorada que parpadean como velas;
  3. niebla baja que se mueve despacio;
  4. primer plano en sombra violácea (columna rota con su tambor caído, arco partido y escombros) y viñeta;
  5. partículas: brasas doradas que suben, ceniza que cae flotando de lado y chispas alrededor del cristal.
- **Carga separada del menú.** Una línea fina con una chispa en la punta y la cifra pequeña. Al terminar, la línea se
  llena, brilla, se encoge hacia el centro y desaparece (con la cifra); suena una campana suave hecha por código y sale
  «TOCA PARA EMPEZAR» («PULSA INTRO» / «PULSA A» según `entrada.gd`, igual que la original). Las frases de la carga
  rotan cada 4 s, como en la original, y se ocultan al abrir el menú.
- **Menú** (al tocar o pulsar): CONTINUAR (solo si hay partida), NUEVA PARTIDA, OPCIONES y CRÉDITOS, con un selector
  (franja de luz y dos rombos) que sigue al ratón, al dedo, al teclado y al mando, un «tic» al moverse y un golpe de
  luz al elegir. ↑ ↓ dan la vuelta; Esc / B vuelve a «toca para empezar».
  - **Continuar** hace lo mismo que tocar en la original (`_empezar()` de `carga.gd`: carga la partida y vuelve donde
    estabas).
  - **Nueva partida** sin partida: lo mismo que la original sin partida (mapa con el prólogo). **Con partida**: pide
    confirmación (el foco empieza en «Volver») y, si se confirma, primero copia aparte la partida (principal, `.bak` y
    `.tmp`, los que haya) como `<archivo>.antes_de_nueva_<fecha>`, comprueba que la copia es idéntica y, si no lo es,
    no empieza nada. Después hace lo mismo que `progreso.cargar()` cuando no hay archivo.
  - **Cargar partida: no está, a propósito.** `progreso.gd` tiene **una sola partida por versión** (`partida.save` en
    la de siempre, `partida_exp.save` en la experimental). La ranura `partida_exp_prueba.save` es una herramienta de
    desarrollo que siempre empieza desde cero (los botones de prueba), no una ranura del jugador. Inventar ranuras
    habría sido mentir; si un día hay ranuras reales, el sitio es este menú.
  - **Opciones** abre los Ajustes de siempre (`menus.gd`) con solo su pestaña de Ajustes (allí aún no hay partida).
  - **Créditos**: una ventana sencilla y honesta (motor, Dialogic, fuentes OFL, ambientes CC0, Sonniss, Meshy, y que
    los créditos completos están pendientes; la lista de trabajo es `docs/recursos.md`).
- **Accesos de pruebas**: los dos de la original («Probar el prólogo (partida nueva)» y «Probar la misión desde el
  principio»), con el mismo texto y la misma acción (`_empezar(true, …)` de `carga.gd`), abajo a los lados, con otro
  estilo (borde verde azulado) y el rótulo «PRUEBAS · solo en la versión de pruebas». Salen con el menú y **solo donde
  los enseña hoy `carga.gd`**: con la exploración 3D activa (`modo3d.activo()`: APK experimental y de Auditoría, o
  «-- 3d»). No se ha quitado ninguna herramienta de prueba.
  - Aviso: hoy la APK experimental y la de Auditoría tienen la misma característica (`rebelum3d`), así que no se
    pueden distinguir. Si se quieren **solo** en Auditoría, hay que añadir una característica propia a su preset en
    `export_presets.cfg` (por ejemplo `custom_features="rebelum3d,auditoria"`) y mirarla aquí y en `carga.gd`. No lo
    he tocado: no es de mi encargo.
- **Sonido**: el viento del mapa (`audio/ambiente/viento.wav`, CC0, ya registrado) bajo (−18 dB, bus Ambiente) que
  entra en 4 s y se apaga con el fundido a negro; la campana del final de la carga (síntesis propia); y los sonidos de
  interfaz ya existentes (`ui_abrir`, `ui_tic`, `ui_confirmar`, `ui_cerrar`, `ui_atras` de `sonido.gd` y el
  «confirmar» de `menu_combate.gd`). Nada nuevo de terceros. **No se ha escuchado**: las pruebas son mudas.

La carga es **la misma**: `inicio_alternativo.gd` hereda de `carga.gd` y usa sus pasos sin cambiarlos (archivos en
segundo plano, sombreadores fuera de la vista, interfaz de los diálogos y cachés de las zonas).

## Cómo activarla y desactivarla

- **En el juego (versión experimental):** Ajustes → «Pantalla de inicio» → «Original» / «Alternativa (en pruebas)».
  Se guarda en `user://ajustes.cfg`, sección `[portada]`, clave `alternativa` (como las demás opciones en pruebas). Se
  nota la próxima vez que se abre el juego. Desde la alternativa, en Opciones, está la misma opción para volver.
- **Con argumento:** `-- portada_alternativa` la usa (también en la versión de siempre); `-- portada_original` la
  impide aunque esté elegida.
- **Sin nada de eso:** la original, exactamente como hoy. Lo de Ajustes solo vale con la exploración 3D activa, para
  que la versión estable (que en el PC comparte `user://`) nunca la vea.

## Archivos

Nuevos (todo código, sin imágenes):
- `aethelgard/portada/inicio_alternativo.tscn` y `inicio_alternativo.gd` (pantalla, menú y ventanas).
- `aethelgard/portada/fondo_portada.gd` (entorno).
- `aethelgard/portada/eleccion.gd` (original o alternativa).
- `aethelgard/pruebas/prueba_portada_alternativa.gd`, `prueba_portada_estable.gd` y `fotos_portada.gd`.
- Los `.uid` que Godot generó para los guiones nuevos.

Cambiados:
- **`aethelgard/carga.gd`**: solo un enganche de 8 líneas, comentado, al principio de `_ready`: si
  `eleccion.usar_alternativa()`, para su proceso y cambia a la alternativa; si no, sigue como siempre.
- **`aethelgard/menus.gd`**: `var solo_ajustes := false` y `var pestanas` (la lista de pestañas, que por defecto es
  la de siempre; las 4 líneas que usaban `PESTANAS` usan ahora `pestanas`), y la opción «Pantalla de inicio» al final
  del bloque de opciones en pruebas (solo en la versión experimental).
- `aethelgard/pruebas/lista_pruebas.txt`: tres líneas (dos automáticas y la de capturas, en modo ventana).
- `docs/recursos.md`: la procedencia del arte nuevo.

No he tocado nada del desierto, del combate ni de `zonas3d/`, ni `project.godot` (la primera importación lo vació de
los directorios de Dialogic, como se avisaba: lo restauré con `git restore` e importé otra vez). Queda sin seguimiento
`aethelgard/enemigos/bramavidrio/bramavidrio_v1.png.import`, que generó la importación y no es mío: no lo he confirmado.

## Procedencia de todo lo nuevo

Todo hecho por código en este repositorio el 11/11 (sombreadores, polígonos, degradados, partículas y la campana
sintetizada), sin imágenes, modelos ni sonidos nuevos de terceros y sin servicios. No he usado Blender: con
polígonos y sombreadores bastaba, pesa cero bytes de arte y se ve nítido a cualquier resolución. Reutiliza sin
cambiarlos el logo, las fuentes Cormorant y Saira Condensed (OFL), el ambiente `viento.wav` (CC0) y los sonidos de
interfaz del juego. Registrado en `docs/recursos.md`.

## Capturas (con ventana, datos aislados, «3d», con una partida mínima para que salga Continuar)

`D:\REBELUM_diagnostico\graficos\2026-11-11_portada\final\ronda1\` (y `ronda2\`, iguales):
- Original: `original_1280x720_1_cargando.png`, `original_1280x720_2_lista.png`, y las mismas en `1600x720`.
- Alternativa: `alternativa_1280x720_{1_cargando,2_lista,3_menu,4_creditos,5_opciones}.png`, y las mismas en
  `1600x720`.
- Las de 1600 × 720 son el lienzo de 1280 × 720 con las bandas negras que pone el juego en el Redmi (estiramiento
  `canvas_items`, aspecto `keep`): `fotos_portada.gd` lo compone así porque la textura de la ventana es solo el lienzo.
  No es una captura del teléfono.
- Borradores anteriores (antes de aclarar el primer plano y ocultar la frase bajo el menú): `borrador1\` y `borrador2\`.

## Tiempos y memoria (PC, 11/11 hacia las 15:05, `fotos_portada.gd`, dos rondas por pantalla y tamaño)

Cada medida en un proceso nuevo y con datos aislados nuevos, alternando original y alternativa. **No pude confirmar
que el PC estuviera sin otra carga** (otro especialista estaba pasando pruebas en otra copia al empezar la sesión): son
orientativas y sirven para comparar las dos, no como cifras absolutas.

| | Original | Alternativa |
|---|---|---|
| Carga, segundos de pantalla hasta «empezar» | 8,19 – 8,36 | 8,13 – 8,30 |
| Carga, reloj desde el cambio de escena | 12,2 – 12,5 s | 12,4 – 12,8 s (+0,2 a 0,5 s: el cambio de escena extra y crear el entorno) |
| Memoria estática al acabar la carga | 166,8 – 167,2 MB | 167,5 – 167,9 MB (+0,5 MB) |
| Memoria de vídeo al acabar la carga | 324,8 MB | 324,9 – 326,9 MB (+0,1 a 2 MB) |
| Con el menú y tras abrir Ajustes | — | estática 172,6 – 175 MB, vídeo 327,6 – 330,4 MB (incluye `menus.gd`) |
| Nodos / llamadas de dibujo | 150 / 22 | 239 / 96 |
| Sin límite ni vsync, 6 s, 1280 × 720 | 418 – 641 FPS (1,56 – 2,39 ms) | 421 – 443 FPS (2,26 – 2,38 ms) |
| Sin límite ni vsync, 6 s, 1600 × 720 | 580 – 583 FPS (1,71 – 1,72 ms) | 448 – 520 FPS (1,92 – 2,23 ms) |
| Dibujo en CPU / GPU (lo que da Godot) | 0,52 – 0,76 / 0,57 – 0,89 ms | 0,83 – 0,97 / 0,48 – 0,63 ms |

Lectura: la carga dura lo mismo (hace lo mismo); la pantalla nueva añade muy poca memoria y unos 0,3 – 0,7 ms por
fotograma en el PC, casi todo de CPU (más nodos, partículas por CPU y 96 llamadas de dibujo frente a 22). Ambas van a
60 FPS como la original (`Engine.max_fps = 60` durante la carga, como `carga.gd`).

**Para el Redmi (Mali-G57) no hay medida.** Riesgos que habría que mirar allí: el cielo es un sombreador a pantalla
completa (ruido de valor, 3 octavas + 4 crestas de 4) y hay tres capas grandes con mezcla (niebla, viñeta y el hueco
del logo). Si cuesta, lo primero sería pintar el cielo en una SubViewport a media resolución o bajar a 30 FPS cuando
el menú está quieto, enseñando antes y después.

## Comprobado

Ejecutando, aislado (11/11, sobre los commits de esta rama):
- `prueba_portada_alternativa` (versión experimental, «3d»): la elección (argumentos, Ajustes y versión; elegir no
  borra los demás ajustes); **sin elegirla, `carga.tscn` se queda en la de siempre, termina, enseña sus botones y ↓
  elige «Probar la misión»**; elegida, `carga.tscn` lleva a la alternativa, el logo es el mismo archivo en el mismo
  sitio y con el mismo modo, la línea y la cifra se apagan al terminar, los accesos de pruebas no salen antes del menú;
  menú con teclado (Continuar, ↓, ↑ con vuelta, ← → a los accesos de pruebas, ↑ vuelve, sin taparse ni salirse);
  Opciones con teclado (solo Ajustes, con «Pantalla de inicio»; Esc vuelve a Opciones); Créditos y Continuar con
  **toques simulados** (`InputEventScreenTouch`; Godot emula el clic, como en Android); Nueva partida con partida
  (pregunta, «Volver» no cambia nada, confirmar hace una copia idéntica y una partida nueva con Kael solo en el mapa).
  Deja la carpeta aislada como estaba.
- `prueba_portada_estable` (versión de siempre, «-- portada_alternativa»): sin accesos de pruebas, sin Continuar sin
  partida, un toque abre el menú sin pulsar lo que aparece debajo y Nueva partida lleva al mapa (esa comprobación del toque se
  añadió al final: `D:\REBELUM_diagnostico\pruebas\2026-11-11_151022\resumen.md`, 2 de 2, con otro Godot de otra copia
  abierto y la partida real sin cambios).
- Las de la carga y el foco, superadas con estos cambios: `prueba_escenas`, `prueba_ranura_prueba`,
  `prueba_boton_prologo`, `prueba_dialogo_interfaz`, `prueba_foco`, `prueba_mando`, `prueba_teclado`,
  `prueba_precalentado` y `prueba_musica`. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_150737\resumen.md`
  (11 de 11; partida real, carpeta real de datos y proyecto sin cambios).
- La partida real del PC (SHA-256 `A3F3C402…A424F5`) sin cambios antes y después de todo, también de las capturas.

## No comprobado (pendiente)

- **El Redmi**: ni cómo se ve, ni el rendimiento, ni el táctil real, ni la tecla Atrás. Tampoco un mando real.
- **El sonido** (ambiente, campana y efectos): solo se sabe que se piden; no se ha escuchado.
- La pantalla con mucho tiempo abierta (calor y batería) y en otras proporciones (tableta, Android TV).
- Que Nueva partida con partida real funcione en el teléfono (solo se ha probado en la carpeta aislada del PC).
- La versión de Auditoría frente a la experimental: hoy no se distinguen (ver arriba).

## Cómo probarla

- Pruebas: `powershell -ExecutionPolicy Bypass -File D:\Aethelgard_v12_portada\aethelgard\pruebas\ejecutar_pruebas.ps1
  -Solo prueba_portada_alternativa,prueba_portada_estable`.
- Verla en el PC (con datos aislados): lanzar Godot sobre `D:\Aethelgard_v12_portada\aethelgard` con
  `-- 3d portada_alternativa` (o elegirla en Ajustes de la versión experimental).
- Capturas: `fotos_portada.gd` (ver su comentario), o la línea `fotos_portada` de la lista con `-Manual`.
- En el móvil: una APK experimental de esta rama (la compila el coordinador) y elegirla en Ajustes.

## Siguiente paso propuesto

1. Que el usuario compare las capturas y, si le gusta, probarla en el Redmi con la APK experimental (medir FPS con el
   menú quieto y escuchar el ambiente).
2. Si se quiere solo en Auditoría, la característica propia en `export_presets.cfg` (cambio del coordinador).
3. Si se queda, decidir entre hacerla la principal (cambiar `run/main_scene` o el valor por defecto de
   `eleccion.gd`) o seguir comparando; en cualquier caso la original se conserva.
