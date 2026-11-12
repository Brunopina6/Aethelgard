# Animaciones · V12 · Humbaba, el Corazón del Bosque Muerto

## 12/11/2026, tarde (especialista de animaciones; rama `claude/v12-humbaba` desde `claude/rebelum-v12` @ 2c0f872)

Encargo: `docs/v12/ENCARGO_HUMBABA.md` (jefe nuevo a partir de la lámina del usuario; APAGADO). Todo lo de abajo está
**comprobado ejecutando** (Blender 5.2.3 por guion y Godot 4.7.2 con datos aislados) salvo lo que se marca como
pendiente. El rendimiento en el Redmi **no está medido** (el teléfono no estaba conectado; no se usó ADB).

### Qué hay

- **Generador** `aethelgard/fuente/crear_humbaba.py` (Blender por guion, obra propia, procedural). La lámina del
  usuario solo se mira y se compara (`fuente/hoja_referencia_humbaba.py`); no se copia al juego ni sirve de textura.
  No se usó Hunyuan3D ni ningún servicio.
  - **Etapa 1 (auditoría y esqueleto):** esqueleto humanoide adaptado de **72 huesos deformantes** (todos los que
    se exportan): raíz, pelvis, 3 de columna, pecho, 2 de cuello, cabeza, mandíbula, ojo, núcleo, «luz» (sin pesos:
    su escala X es la intensidad del brillo de cada clip); por brazo hombro, brazo, antebrazo, muñeca, palma y 4 dedos
    de 2 tramos (3 dedos y pulgar: abren, cierran, agarran, aprietan y señalan); por pierna muslo, pierna, tobillo, pie
    y punta (las raíces delanteras); corona en 3 conjuntos de 2 huesos; 5 cadenas de raíces colgantes de 3 tramos;
    «baston» (hijo de la palma derecha: el anclaje del arma) y «guadana» (la hoja que brota del antebrazo izquierdo
    en su ataque; escala 0,01 fuera de él). Por qué 72 y no menos: los 16 de los dedos (las garras que agarran y
    aprietan) y los 15 de las raíces colgantes son lo que pide el encargo; el resto es el humanoide mínimo.
  - **Controles de Blender (no se exportan):** IK de las piernas (pie y polo de la rodilla; el tobillo copia el giro
    del pie), IK/FK de los brazos (mano y polo del codo; la influencia se anima: 0 = FK), mira del ojo (Damped Track)
    y mira del bastón. Los polos se ajustan solos (error < 0,12° en la pose de enlace). El exportador muestrea la pose
    con las restricciones.
  - **Etapa 2 (malla, rig, deformaciones):** primero un blockout gris (`etapa1_2_blender/01_blockout_hoja.png`) y
    luego la malla: cada miembro es un tronco con un haz de raíces enroscadas encima (hélices), cabeza-tronco con la
    placa de corteza en punta y dos espirales talladas, el ojo turquesa en su cuenca, boca negra con colmillos de
    madera y mandíbula con hueso, núcleo en el pecho engastado en un marco de raíces en forma de corazón con vetas que
    irradian, corona de ramas secas (recursiva), brazos asimétricos (el izquierdo, el de la garra, más largo), manos de
    tres dedos y pulgar con garras de madera clara, piernas de raíces con raíces y garras en los pies, musgo en lo alto
    y colgando, raíces colgantes, amuletos; **armadura aparte** (hombreras con espiral y brazales: se rompe en la fase
    3) y **bastón aparte** (fuste retorcido de 12 m, cabeza de ramas con gemas, cuerdas y amuletos). Pesos por cadena
    (mezcla suave solo en las articulaciones) y rígidos en garras, placas y bastón. Fotos de pesos por hueso
    (`03_pesos_hoja.png`) y de poses extremas (`04_deformaciones_hoja.png`: brazos arriba, agachado, giro de tronco con
    la boca abierta, zancada).
  - **Etapa 3 (clips):** 23 acciones a 30 fps, con anticipación, golpe y recuperación, y el último fotograma en el
    reposo (o en la pose de la que sigue): `idle` (4 s, bucle), `idle_angry` (2 s, bucle), `walk` (2,4 s, bucle; 2 m
    por paso → 1,67 m/s a escala real), `turn_left`/`turn_right` (45° en dos pasos sin que patinen los pies; el juego
    pasa el giro al pivote), `roar`, `hit_light`, `hit_heavy` (paso atrás y vuelta), `stagger` (apoya la garra en el
    suelo), `phase_transition`, `death` (de rodillas y de bruces), `atk_puno`, `atk_raices`, `atk_aliento`,
    `atk_guadana`, `atk_ojo`, `atk_llamada`, `atk_abrazo`, `requiem_inicio`, `requiem_carga` (bucle), `requiem_golpe`,
    `vulnerable` (bucle) y `vulnerable_fin`. La corona y las raíces colgantes se mueven con muelles simulados y
    **horneados** (sin simulación en el juego). Los pies no se mueven fuera de andar, girar, el golpe fuerte y los
    pasos de los ataques (medido: 0,0 m en reposo, rugido, Ojo, Aliento y golpe leve). La mano derecha lleva el bastón
    con IK y su punta queda apoyada en el suelo (medido en Godot: −0,03 m a escala de combate).
  - **Eventos:** cada clip trae sus instantes con nombre (`aviso`, `impacto`, `hundir`, `aliento_inicio`/`_fin`,
    `carga`, `rayo_inicio`/`_fin`, `invocar`, `agarre`, `apretar_1`/`_2`, `soltar`, `troncos`, `cambio`…) y los puntos
    del cuerpo (ojo, núcleo, boca, manos, puntas del bastón) en ejes de Godot, en `humbaba_clips.json`.
  - **LOD y texturas:** alto / medio / bajo = **35 874 / 19 249 / 12 005 triángulos** (medidos en Blender y en Godot);
    textura de corteza repetible pintada con numpy, WebP 2048 / 1024 / 512, importadas comprimidas en VRAM con mipmaps;
    dos materiales (madera y brillo). GLB: 4,6 / 3,7 / 3,2 MB.
  - Ajuste tras compararlo con la lámina (12/11, 14:55): piernas 1 m más largas (13,3 m en total), tronco más
    estrecho, brazos menos gruesos, madera más gris y más musgo colgando; hombreras por encima del hombro (antes solo
    asomaba su canto). Antes y después: `etapas_blender_final/` (antes) y `etapas_blender_v2/` (después),
    `comparacion_lamina_vistas.png` (antes) y `comparacion_lamina_vistas_v2.png` (después).
- **Godot** (`aethelgard/enemigos/humbaba/`): los tres GLB, texturas, `humbaba_clips.json`, `humbaba_3d.gd` y los
  sombreadores `humbaba_madera.gdshader` (detalle × color de vértice, vetas en el alfa que siguen al hueso «luz»,
  color de la fase, grietas y recorte bajo el suelo) y `humbaba_brillo.gdshader` (ojo, núcleo, vetas y gemas; el
  núcleo, marcado con UV.x ≥ 5, se vuelve verde enfermizo y se agrieta en la fase 2 y late expuesto en la 3).
  `humbaba_3d.gd`: el contrato de los enemigos 3D del combate y lo suyo (`atacar` con un impacto por evento, eventos
  con nombre, Réquiem en dos tiempos, `cambiar_fase`, `romper_armadura`, `girar`, `punto`); perfil por
  `prototipos/calidad_proto.gd`; escala 0,4 en el combate (con recorte) y 1,0 en el mundo.
- **Combate** (`aethelgard/combate_humbaba.gd`, patrón de Vidracrán/Coloso, ATB de siempre): máquina de estados por
  turno (cambio de fase pendiente → transformación sin daño; vulnerable → se levanta; Réquiem cargado → lo descarga;
  si no, el ataque del ciclo de su fase). Fichas en `ATAQUES` (nombre, clip, multiplicador, objetivos, estado,
  sonido, fases y contrarresto). Fases por vida en `UMBRALES` = 70 % y 35 %.
  1. Puño del Bosque Primordial (fases 1-3): zona marcada = el objetivo y el héroe más cercano (los demás no reciben
     nada); deja el **núcleo al alcance** (×1,4 a los golpes) hasta su turno siguiente: su punto débil.
  2. Raíces Devoradoras (1-3): raíces 2D aparte bajo cada héroe; daño a todos y **pierde su turno** quien no defendía.
  3. Aliento de la Putrefacción (2-3): cono de esporas (CPUParticles2D con el tope de calidad del combate); daño a todos
     y **corrupción** (6 % de la vida al empezar cada turno, 3 turnos; no mata; la cura la limpia).
  4. Guadaña de Raíces (1-3): la hoja crece del antebrazo y barre a todos (tajo 2D).
  5. El Ojo del Juicio (2-3): carga visible en el ojo (luz que sube durante 1,4 s) y rayo desde el ojo a uno (×2,1).
  6. Llamada de los Condenados (2-3): clava el bastón e invoca Zarzalines con el mismo alta que al empezar el combate
     (datos, escalado, rig, sombra, vida); tope 2 vivos; caen con él.
  7. Abrazo de la Muerte (3): agarre (la presa sigue a la garra en pantalla), dos aprietos y entre ambos una
     oportunidad de soltarse (35 %, +35 % defendiendo); la Guardia de Garon se lo lleva él.
  - Fase 3: armadura rota (sin corteza), combinados (dos ataques ×0,7) y el **Réquiem del Bosque Eterno**: un turno de
    aviso sin daño (se hunde, raíces por la arena, cartel, «⚠ Réquiem» sobre su vida, señal, marca bajo cada héroe) y el
    siguiente estalla (troncos bajo los héroes, onda, ×2 a todos; Defender a la mitad) y queda **vulnerable** (×1,6 a
    todo) hasta su turno siguiente.
  - Defensa: corteza ×0,8 a los golpes en las fases 1 y 2; el fuego ×1,4 siempre.
  - Sonido: **solo efectos que el juego ya tenía** (Guardián del Bosque, corteza, carga del jefe, fase), cada uno en su
    evento. No se añadió audio (la biblioteca de qtorrent queda para una identidad propia).
- **combate.gd**: los mismos ganchos que Vidracrán (ENEMIGOS, GRUPOS[17], MODELOS, turno, golpe, daño recibido en las 6
  vías, información y estados, tic de los héroes, aviso del turno, fin y curas). Sin Humbaba en el combate dan lo mismo.
- **Mapa** (`zonas3d/gran_bosque_3d.gd`): con el interruptor, Humbaba duerme de rodillas al oeste del altar, a escala
  real; «Acercarse al Corazón» lo despierta (ruge) y empieza su combate fijo `gran_bosque_humbaba`. Ganado, no vuelve.
  Apagado no se crea nada (comprobado en la prueba V).
- **Interruptor** `humbaba_v12` (Engine.set_meta o «-- humbaba_v12»), **apagado** por defecto. No sustituye al Guardián
  del Bosque ni toca encuentros normales (GRUPOS[17] no está en las tablas al azar; comprobado).

### Pruebas (Godot aislado, deterministas con semilla)

- `prueba_humbaba_modelo`: los tres GLB (72 huesos, sin controles, 23 clips con las duraciones del JSON, presupuesto,
  3 mallas, texturas VRAM), puntos del cuerpo, punta del bastón en el suelo, pies quietos, cada ataque con su impacto en
  el fotograma de su evento (±2), eventos completos, luz que sube con el Ojo, Réquiem en dos tiempos, fases, giro de 45°
  que pasa al pivote y derrota que apaga.
- `prueba_humbaba_combate`: U (interruptor, grupos, daño recibido, fases, fichas), V (Gran Bosque apagado y encendido),
  A (cada ataque forzado en su fase: impactos, a quién, estados, efectos, sonidos, tope, Abrazo, Réquiem y fases), B
  (combate entero con estrategia: gana y pasa por las tres fases, sin restos), C (derrota).
- `fotos_humbaba` (ventana, MANUAL): hojas por clip con el estudio del combate, `combate=1` (capturas de un combate de
  verdad en cada evento) y `bosque=1` (el santuario con el interruptor).
- Resultados: ver «Batería» abajo.

### Diferencias honestas con la lámina

- Proporciones: aún más **macizo** que la lámina (hombros y brazos gruesos de «gorila»; la lámina es más espigada).
- La lámina es una ilustración muy detallada: aquí las raíces son tubos y hélices con una textura de corteza
  repetible; no hay las mil raicillas finas, ni los cortes de corteza de las placas con su relieve, ni las runas
  turquesa incrustadas por todo el cuerpo (solo vetas en la textura y en el pecho).
- El musgo cuelga en tiras de tres caras; en la lámina es una cortina mucho más densa.
- La cara: la lámina tiene una calavera de madera bajo la placa; aquí, una cabeza-tronco con labio y mandíbula.
- La cabeza del bastón y los amuletos son más simples.
- En la pantalla de combate mide unas **2,8 veces a Kael**, no 6-8: con el ojo (origen del rayo) y los pies a la vista
  no cabe más (la corona se corta arriba). A escala real (13,3 m frente a 1,75 m) solo se ve en el Gran Bosque.

### Qué falta

- **Rendimiento en el Redmi: sin medir.** 35 874 triángulos en el alto y 72 huesos con 4 influencias son mucho para un
  Mali-G57 junto a los héroes; el perfil bajo (12 005) es el candidato del móvil. Hay que medir FPS y memoria en el
  teléfono antes de darlo por bueno (el coordinador programa la medida).
- Equilibrio: B gana con los tres a nivel 22; el Gran Bosque es de nivel 4. Ajustar vida y daño cuando se decida
  dónde y cuándo aparece.
- Voz e identidad sonora propias (hoy reutiliza efectos del Guardián del Bosque).
- Nombre de los Zarzalines invocados y textos del santuario: provisionales (narrativa).
- Los GLB de una exportación a otra no salen idénticos byte a byte (±1 KB; mismos triángulos, huesos, clips y JSON).

### Batería (ejecutar_pruebas.ps1, datos aislados)

- Pasada 1 (14:48, sobre `907674c` + cambios sin confirmar): 134 · 1 · 61 · 0. La fallida era mía:
  `prueba_magia_negra` exige que todo ENEMIGOS esté en `combate_afinidades.gd`; añadida la fila de Humbaba.
- Tras el ajuste de proporciones: `prueba_humbaba_modelo`, `prueba_humbaba_combate`, `prueba_magia_negra`,
  `prueba_gran_bosque3d` y `prueba_combate_huella`: 5 SUPERADAS (`D:\REBELUM_diagnostico\pruebas\2026-11-12_150856\`).
- **Pasada final (15:13, sobre `daaae49`): 135 · 0 · 61 · 0, código 0**; partida y carpeta real de datos sin cambios
  (había 18 Godot de otras pasadas en el PC). `D:\REBELUM_diagnostico\pruebas\2026-11-12_151337\resumen.md`.

### Evidencias (`D:\REBELUM_diagnostico\animaciones\2026-11-12\humbaba\`)

- `etapa1_2_blender/`: blockout, modelo, detalles, pesos, deformaciones y hojas de clips de la primera versión.
- `etapas_blender_final/` (antes del ajuste) y `etapas_blender_v2/` (después): vistas, detalles, pesos (03),
  deformaciones (04) y una hoja por clip (05_clip_*).
- `comparacion_lamina_vistas.png` / `_v2.png` y `comparacion_lamina_detalles.png` / `_v2.png`: frente a la lámina.
- `etapa3_godot/` (prototipo con idle, roar y Puño) y `etapa3_godot_v2/` (los 23 clips y las tres fases con el estudio
  del combate).
- `etapa6_combate/`: un combate de verdad (grupo 17) con una foto en cada evento de cada ataque.
- `etapa6_gran_bosque/`: el santuario con el interruptor (Humbaba a escala real tras el grupo).
- `video/humbaba_combate_ataques.avi` (960 × 540, 30 fps, 158 MB, `--write-movie`): los héroes golpean y luego cada
  ataque forzado en su fase, del Puño al Réquiem.
