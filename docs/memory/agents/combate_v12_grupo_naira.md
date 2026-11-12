# Combate y grupo, V12: grupo con reserva y Naira como cuarto héroe (APAGADA)

## 12/11/2026, 02:15-03:30 · rama LOCAL `claude/v12-fase2-grupo` (`D:\Aethelgard_v12_grupo`, desde `claude/rebelum-v12` @ `fa0a818`)

Encargo del usuario: integrar un cuarto protagonista sin romper nada, con **tres combatientes activos y reservas**.
Sin push ni merge. Naira es una **propuesta, no canon** (`docs/v12/NAIRA.md`): todo lo suyo está detrás de su hito
(`nr_union`, que hoy nada pone) o del interruptor de desarrollo `naira_v12`, **APAGADO**. Sin él, el juego es el de
antes (comprobado: batería, huella C0 y pruebas de grupo).

### Commits

| Commit | Qué |
|---|---|
| `8330d4d` | `grupo.gd` (reserva, Formación, Naira en `HEROES`) y `progreso.gd` (clave `grupo_miembros`, `FORMATO` 3) |
| `b76fb2b` | `inventario.gd` (Astrolabio, `preparar_recluta`) y `magia_negra.gd` (`DE_RECLUTA`, Eclipse, Penumbra) |
| `0de687b` | `personajes/naira/naira_3d.gd` (nuevo), retrato provisional, `combate.gd` y `zonas3d/grupo_3d.gd` |
| `3a70e2f` | `menus.gd`: Formación y fichas de la reserva |
| `7a9a84a` | `pruebas/prueba_grupo_reserva.gd`, `prueba_naira_combate.gd`, `fotos_grupo_naira.gd` y `lista_pruebas.txt` |
| el último | este informe |

## 1. Diseño del grupo (`grupo.gd`)

- `EN_EL_GRUPO` **no cambia** (`Kael, Lya, Garon`): las regiones 3D la leen para sus acompañantes y `datos()` solo crea
  a esos tres si faltan, como siempre. Los reclutas van aparte: `RECLUTAS = ["Naira"]`, `ORDEN` (Kael, Lya, Garon,
  Naira) para menús, combate y fila.
- `disponible(n)`: los tres, siempre; Naira, solo con `naira_v12` (Engine o `-- naira_v12`; `NAIRA_POR_DEFECTO =
  false`) o con su hito `SE_UNE_EN["Naira"] = "nr_union"`. Una partida que trae datos de Naira sin eso los conserva,
  pero Naira no sale en ningún sitio.
- `miembros()`: quién tiene datos y existe en esta versión (en `ORDEN`). `en_el_grupo()`: quién va con el grupo
  (activos + reserva). `activos()`: máximo `MAX_ACTIVOS = 3`, Kael delante. `reserva()`: miembros no activos.
  Los **ausentes** (Lya antes de PV-03) no son miembros ni reserva.
- `unir(n)` (API de la misión futura: `Grupo.unir("Naira")`): un recluta sin datos nace a `NIVEL_AL_UNIRSE = 1`
  (la nivelación automática sigue retirada, D-062) con su plantilla y su equipo; entra **al grupo si cabe y a la
  reserva si no**. Devuelve `"activo"`, `"reserva"` o `""`. Sin `grupo_activo` (versión estable) primero fija los
  tres de siempre. Nota: con el grupo lleno, también uno de los de siempre que se una después iría a la reserva
  (no pasa en la historia: Naira llega en el acto II).
- Formación: `motivo_formacion`, `formar`, `alternar`, `cambiar`, `hay_formacion`. `KAEL_SIEMPRE_ACTIVO = true`
  (NAIRA.md §4.6, pendiente del usuario: con `false`, Kael puede ir a la reserva; **la exploración seguiría con Kael
  de líder**, eso no está resuelto).
- La reserva: conserva sus datos; `curar_todos()` la cura también (derrota, posada, descansos); gana
  `PARTE_EXP_RESERVA = 0.5` de la experiencia de cada combate ganado, sin avisos (NAIRA.md «[D]», pendiente).
- `CRECIMIENTO["Naira"]` + `repartir_recomendado()`: el reparto de §5.2 (magia y espíritu cada nivel, velocidad y
  vitalidad alternas, defensa nunca), solo con el botón «Repartir como recomienda» de su ficha.

### Compatibilidad (comprobado en `prueba_grupo_reserva`, parte 1 y 4)

- Partida nueva, estable (sin `grupo_activo`) y las cuatro «de antes» de `prueba_grupos_combate`: los mismos activos
  que antes. Con datos de Naira pero sin hito ni interruptor: no sale (ni miembros, ni reserva, ni combate).
- `grupo_miembros` (clave nueva al final de `CLAVES`) **solo se guarda si hay reserva**: sin ella el volcado es el de
  siempre. `FORMATO` sube a 3 (la clave nueva); una partida sin la clave carga igual. Si una versión antigua
  vuelve a guardar sin conocer la clave, se pierde la reserva y quedan los activos.
- Sin el interruptor, una partida que tenía a Naira activa se juega con los demás activos (probado).

## 2. Menú de Formación (`menus.gd`, pestaña Grupo)

- Solo aparece si hay reserva (o más miembros que sitios): con los tres de siempre el menú es idéntico (prueba 7 y
  `prueba_grupos_combate` 6).
- Fila de héroes: los activos y, tras «Reserva:», los de la reserva (en gris); botón **Formación** a la derecha.
- Formación: «En el grupo: n de 3», una línea de ayuda, una **tarjeta por miembro** (retrato, clase y nivel, PV/PM,
  «En el grupo»/«En la reserva» y un botón grande «A la reserva»/«Al grupo» de 212 × 48; si no se puede, apagado y
  con el motivo debajo: «Kael va siempre en el grupo.», «Grupo lleno: pasa antes a alguien a la reserva.»).
  4 tarjetas de 236 px caben en la lista sin desplazar en horizontal (captura 03). Con teclado/mando, el foco va de
  botón en botón (claves `formacion:<nombre>`); Esc/B vuelve a la ficha.
- Ficha: «(reserva)», «Personaje provisional, en pruebas.» para Naira y el botón de reparto recomendado.
- Habilidades: también la reserva («· reserva») y la magia negra de quien la tenga, escuela a escuela, con ✔, «se
  aprende al nivel n» o «falta su investigación».

## 3. Naira (PROPUESTA; modelo y retrato PROVISIONALES)

- **Estadísticas** (NAIRA.md §5.2): fuerza 5, magia 18, defensa 3, velocidad 19, vitalidad 6, espíritu 12;
  `mult_fisico` 0,3, `mult_magia` 1,0, arma «cetro». A nivel 10: 142 PV, 58 PM (Lya 134/64, Kael 174/34).
- **Equipo**: «Astrolabio de Bronce» (`astrolabio_bronce`, +1 ataque, +6 daño mágico, `solo: Naira`), que entra en el
  inventario y se lo pone al unirse; el resto de ranuras como Lya (cetro/todos).
- **Magia**: `magia_negra.gd` `DE_RECLUTA["Naira"]` = las seis escuelas + su firma `naira_eclipse`, solo mientras
  `grupo.disponible("Naira")`. `DE_HEROE` sigue vacío (lo exige `prueba_magia_negra`). Aprende por nivel como
  cualquiera (a nivel 1: Ascua, Aguja Glacial, Chispa y Eclipse). Ninguna de las 12 de siempre.
- **Eclipse**: 30 PM, a todos, daño 90, preparación 0,7 (un turno), estado nuevo **Penumbra** 2 turnos (golpes y
  magia ×1,2). Va por la ruta de la magia negra: preparación interrumpible (25 % de sus PV), afinidades, un sonido
  (`naira_eclipse`, respaldo `arte_ocaso`). La forma es la del Manto del Eclipse. **Simplificación**: NAIRA.md dice
  «los demás héroes les hacen +20 %»; aquí también Naira.
- Menú: la lista de escuelas va en 3 páginas de 4 filas con el **Eclipse primero**; en la página de una escuela, 7
  pestañas de icono (caben, 416 px de 432). Icono propio (eclipse total con corona).
- **Modelo**: `personajes/naira/naira_3d.gd` hereda de `maga_3d.gd` (el combate y la exploración la llaman igual que a
  Lya), carga `naira_provisional.glb`, engancha sus 23 huesos a los gestos (`HUESOS_NAIRA`, sin el aviso de Mixamo),
  normaliza a 1,7 m y usa sus 10 clips: reposo, caminar/correr (exploración), ataque (se para en la preparación y
  golpea a 0,4 s), recibir_golpe, victoria, derrota, lanzar_hechizo (sale a 0,87 s), **concentracion** mientras
  prepara y **magia_poderosa** para el Eclipse (1,7 s). Sin vara (lleva el astrolabio en el modelo).
- En combate (`MODELOS["naira3d"]`, esc 0,61): **el recluta ocupa el sitio y el puesto del ausente** (preferencia
  Lya → Garon → Kael): con Lya en la reserva, Naira está donde Lya; con Garon en la reserva, donde Garon. Con los tres
  de siempre, `heroes` es exactamente el de antes.
- Exploración (`grupo_3d.gd`): `RUTAS`/`ESCALA` (1,55 m); `preparar()` añade los reclutas activos al final de la fila,
  así las regiones (que no son mías) no cambian. Comprobado con la misma lógica de las regiones, también tras guardar
  y cargar en otra región.
- **Retrato**: `personajes/naira/naira_retrato_provisional.png` (350 × 640, fondo transparente, sacado de su modelo
  provisional como los `*_reposo.png`). Lo usa la Formación. **No** hay `.dch` (Dialogic es de narrativa).

## 4. Técnicas combinadas (sistema de dúos de la V11)

- **Contrapeso** (pestaña DÚO de Kael): Naira paga 8 PM y su turno (mitad de ATB); ataque de Kael + 50 % del Umbral
  (la Aguja Umbría, 42) de Naira; cuenta como golpe mágico (rompe la guardia, `contrapeso` en `_animar_golpe`); contra
  un enemigo Lento (el «Lastre»), ×1,3 y se lo gasta.
- **Equinoccio** (pestaña DÚO de Lya; pide `nr_l2` o el interruptor): Lya paga 10 PM, Naira presta su turno y lanza
  su Umbral ×1,2; la mitad del daño hecho cura a cada héroe en pie (tope: 20 % de su vida máxima).
- **Vigilia** y **Doble Fondo**: no hechas. Desvían los golpes de los enemigos hacia otro héroe: hay que tocar la
  elección de objetivo de todas las IA (y Bramavidrio, el Coloso…), con riesgo para la huella. Propuesta: un campo
  `f["provoca"] = quien` que `_turno_enemigo` consulte antes de elegir, con su prueba de huella.
- Sin Naira en el combate, `_duos_naira` devuelve nada: los dúos de siempre no cambian.

## 5. Interruptores

| Interruptor | Por defecto | Qué enciende |
|---|---|---|
| `naira_v12` (Engine o `-- naira_v12`; `grupo.gd NAIRA_POR_DEFECTO`) | APAGADO | Naira disponible: `unir("Naira")`, su magia, su combate, su fila |
| hito `nr_union` | nadie lo pone | lo mismo, para la misión futura |
| hito `nr_l2` | nadie lo pone | Equinoccio (con el interruptor, ya está) |
| `grupo.gd KAEL_SIEMPRE_ACTIVO` | `true` | Kael fijo en la Formación |
| `grupo.gd PARTE_EXP_RESERVA` | 0,5 | experiencia de la reserva |

## 6. Pruebas y evidencias (todo aislado, 12/11/2026)

- `prueba_grupo_reserva` (nueva, auto, `3d sin_prologo auto`, ~7 s): SUPERADA. Compatibilidad, unirse, Formación,
  máximo 3, ausentes, guardar/cargar (archivo propio), sin la clave, sin interruptor, perder/ganar/huir con Naira en
  la reserva (vida llena tras perder, la mitad de experiencia al ganar, nada al huir), fila de la exploración tras
  cambiar de región, menú (sin reserva igual; Formación con tarjetas que cambian el grupo; Habilidades).
- `prueba_naira_combate` (nueva, auto, sin `auto`, ~7 s): SUPERADA. A: Kael, Naira y Garon (sitio de Lya, modelo y
  clips, datos y Astrolabio, la de menos defensa, escuelas con el Eclipse primero y 7 pestañas que caben, Eclipse
  preparado con 30 PM y clip de concentrarse, suelto solo a todos con daño, Penumbra legible y un sonido; Penumbra ×1,2;
  Ascua; Eclipse roto por un golpe fuerte con PM perdidos, sin daño y un sonido; Contrapeso; Lya en reserva gana la
  mitad). B: Kael, Lya y Naira (sitio de Garon, Equinoccio, la invocación sigue con Lya). C: sin interruptor, el combate
  de siempre. Los combates los lleva el guion de la prueba (enemigos de 400 PV casi quietos), **no la estrategia de un
  jugador**.
- Subconjunto de combate y grupo (27): `D:\REBELUM_diagnostico\pruebas\2026-11-12_024117\resumen.md` → **SUPERADAS
  26 · FALLIDAS 0 · MANUALES 1** (`prueba_menu_nuevo`, manual desde antes) · partida y carpeta real sin cambios
  («proyecto cambiado» porque añadí una línea a `lista_pruebas.txt` durante la pasada). Incluye
  `prueba_combate_huella` (C0 igual), `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_magia_negra`,
  `prueba_equipo`, `prueba_guardado`, `prueba_formato_regiones`, `prueba_partida`, `prueba_grupo3d`…
- **Batería completa** (con todo confirmado, `7a9a84a`): `D:\REBELUM_diagnostico\pruebas\2026-11-12_025009\resumen.md`
  → **SUPERADAS 125 · FALLIDAS 0 · MANUALES 55 · NO SEGURAS 0**; partida real y carpeta real sin cambios («proyecto
  cambiado»: este informe, escrito durante la pasada). Antes de esta tanda: 123 · 0 · 54 · 0 (+2 auto nuevas y +1 de
  ventana).
- Capturas (`fotos_grupo_naira`, con ventana): `D:\REBELUM_diagnostico\combate\2026-11-12_grupo_naira\` — `01` ficha
  de Naira en la reserva, `02`-`03` Formación, `04` Habilidades, `05` combate con Naira, `06` sus escuelas, `07` página
  del Eclipse, `08` preparando, `09`-`11` el Eclipse saliendo, `12` Penumbra sobre los Slimes y el DÚO de Kael con
  Contrapeso, `13` Kael, Lya y Naira con el DÚO de Lya; y `naira_retrato_provisional.png`.

## 7. Límites (honesto)

- Nadie lo ha jugado a mano ni en el Redmi: ni tacto real, ni rendimiento (Naira: 14 090 triángulos y 2 materiales,
  sin medir en el Mali), ni la exploración con Naira en una región real (solo la fila, sin andar).
- En combate, Naira mira más de frente que Kael (capturas 05-12): parece que su `FRENTE` 3/4 no gira igual que con el
  esqueleto Mixamo. Sin investigar: es del modelo provisional (orientación de sus clips) o de `_yaw0`.
- `vel_andar`/`vel_correr` de Naira son estimados (sin `prueba_anim_pies`): puede patinar en la exploración.
- No tiene esperas de exploración, `.dch`, voz, sonidos propios (`naira_eclipse` cae al respaldo), color de HUD propio
  ni ficha en el Diario.
- Observado en las capturas y **anterior a este trabajo**: con Kael a nivel 10 (I · II · III, Alba, Escarcha y DÚO)
  las pestañas de magia se salen por la derecha («D…»): `_encajar_pestanas` solo se usa con magia negra. Propuesta:
  llamarlo siempre que no quepan.

## 8. Lo que falta / necesito de otros

- **Narrativa**: la misión «La única noche que cabe en un día» (hitos `nr_*`, que debe llamar a `Grupo.unir("Naira")`
  tras `poner_hito("nr_union")`), `naira.dch` y retratos definitivos, `nr_l2` para Equinoccio, variantes de diálogo.
- `menu_combate.gd` (no es de esta tanda): `COLOR_HEROE["Naira"] = Color("5FB49C")` (verdín, NAIRA.md §6.1); hoy usa
  el color por defecto.
- `sonido.gd`: clave `naira_eclipse`.
- Arte/animación: versión definitiva del modelo, `vel_andar`/`vel_correr` medidas y su orientación en combate.
- Usuario: aprobar Naira; Kael fijo, experiencia de la reserva, nivel al unirse (con D-062), si se ven los cuatro en 3D.
- Para integrar: copiar los archivos de los commits de arriba (son todos de esta tanda; `progreso.gd` solo cambia
  `CLAVES` y `FORMATO`).
