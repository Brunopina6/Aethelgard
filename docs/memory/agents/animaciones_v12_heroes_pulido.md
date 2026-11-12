# Animaciones V12 · Héroes v2, pulido (Kael, Lya y Garon)

## 13/11/2026 (sesión del 12/11, tarde) · rama LOCAL `claude/v12-heroes-pulido` (`D:\Aethelgard_v12_heroes_pulido`), desde `fadb5fa`

Commits: `5f666b9` (victoria de Kael, caras y materiales; GLB de Kael y Lya regenerados), `b55b762` (Ajustes
«Protagonistas»), `c1aff03` (pruebas y `docs/recursos.md`) y el de este informe (esperas en pausa
en las capturas de regiones: misma pose antes y después). Sin push ni merge. **Los originales no se tocan** (`kael_3d.gd`, `maga_3d.gd`, `garon_3d.gd`,
`gestos_3d.gd`, FBX). **Por defecto siguen los originales** (`ACTIVO_POR_DEFECTO = false`; sin elegir en Ajustes,
`[heroes] v2` no existe y manda la constante). No he tocado nada de Humbaba ni `combate.gd`, `grupo_3d.gd` ni `vista3d.gd`
(ya llamaban a `HeroesV2.script_de`).

### Las tres mejoras visibles, verificadas (y cómo)

**1. Victoria de Kael: el sable ya no atraviesa la cabeza ni queda detrás de ella.**
- Causa (demostrada, cámara de combate): el clip `victoria` v2 acababa en el reposo (sable al hombro, hoja hacia atrás y
  arriba); al girarse hacia la cámara, la hoja asomaba por detrás de la cabeza como un pincho, y la clave «gira» llevaba
  la mano por dentro (fuera = −0,1) con la hoja vertical: pasaba por la cabeza.
- **El original también falla:** `k_victoria` sube el brazo a 175° y la mano y la empuñadura quedan detrás de la cabeza;
  la hoja sale de ella. Medido en `prueba_heroes_v2` (solo se imprime): distancia mínima hoja-cabeza 0,15 m y, al final,
  1 de 6 puntos de la hoja tapado por la cabeza desde la cámara del combate. La solución es encender el v2.
- Arreglo (`biblioteca_clips.py`, `c_victoria`): alza el sable por fuera del hombro (fuera 0,38), saltito, barrido por el
  costado y final con el sable a un lado, en diagonal hacia delante y abajo, con la cara plana de la hoja hacia la cámara
  y el puño en la cadera, sonriendo. 1,8 s como antes.
- Verificado: `prueba_heroes_v2` (v2: mínimo 0,28 m, 0 puntos tapados al final, punta a 0,11 m del suelo y por debajo de la
  mano) y capturas en 6 instantes y vídeo (rutas abajo).

**2. Caras: sin parches, sin tapar el flequillo y con una expresión nueva.**
- Causas (demostradas): (a) la loseta era opaca entera y la malla `cara_v2` va 0,8 mm por delante de la piel: tapaba los
  mechones pegados a la frente y dejaba ver la sombra pintada debajo (banda oscura en «sonrisa»; captura del 12/11); (b) el
  color proyectado pasaba por la transformada de vista de fábrica de Blender 5 (AgX) y salía gris: con la luz del juego,
  los párpados cerrados se veían como parches beis más oscuros que la piel (lo comprobé: el atlas, mirado solo, casaba;
  en el juego no; con «Standard» casa).
- Arreglo (`cara_expresiva.py`): transparencia solo en ojos y boca (máscara de lo que cambia, borde suave); párpados y boca
  rellenados por difusión desde la piel clara de alrededor (no un color plano de la mejilla); proyección con
  `view_transform = 'Standard'`; la octava loseta («normal2», repetida) es ahora **«decidido»** (párpado de arriba algo bajo,
  la boca de siempre). En el juego (`heroe_v2_ayudante.gd`) el material de la cara es transparente y con la misma luz que la
  piel (mate, envolvente, mismo borde).
- Expresiones en uso: Kael en guardia de combate, «decidido» (en exploración, normal); Lya al lanzar magia, «decidido»;
  daño, «dolor»; victoria, «sonrisa»; diálogo, la de su ánimo (`hablar(animo)`: alegre/broma → sonrisa, decidido → decidido,
  enfado → grito, triste/cansado → entrecerrados…).
- **Parpadeo con ritmo propio:** Kael cada 2,0-4,6 s, doble el 22 %, rápido (×0,85); Lya cada 3,4-6,8 s, doble el 8 %, lento
  (×1,35). No parpadean con ojos cerrados, entrecerrados, sonrisa, dolor ni en KO. Garon, yelmo cerrado: sin cara.
- Verificado: `prueba_heroes_v2` (atlas: «normal» con alfa máx. 0,00; «cerrados» opaca solo en los ojos, alfa media 0,16-0,20;
  material transparente y con la luz de la piel; loseta «decidido»; ritmos distintos) y primeros planos antes/después.

**3. Materiales: piel y tela mates, metal diferenciado, cara legible con luz lateral y sin emisión en piel ni tela.**
- Causa (medida en el mapa de Meshy): G = rugosidad ≈ 0,55 en piel, tela y cuero (con zonas casi a 0, charol) y especular
  0,5 por defecto (plástico); B = metal en adornos y armadura, con valores sueltos fuera. El borde de luz iba por EMISSION
  (brillaba igual a oscuras).
- Arreglo (`heroe_v2.gdshader`, solo `fragment()`, Compatibility): metal o no por umbral suave; lo que no es metal, rugosidad
  ≥ 0,72 y especular 0,28; luz envolvente (`diffuse_lambert_wrap`: la mitad en sombra de la cara ya no se va a negro);
  borde con `RIM` (depende de las luces); el reflejo del metal (lo único por EMISSION, solo en metal; sustituye a las sondas
  que Compatibility no tiene) toma el color y la energía del ambiente de cada región (`_leer_entorno`, cada 3 s, solo si
  cambia).
- Verificado: comparación con el sombreador del 12/11 (`fadb5fa`) con el mismo modelo, pose y luz (soleada, sombra fría y
  atardecer) y las cinco regiones y cinco fondos de combate. **Revisión visual: la mejora es sutil a la distancia del
  juego** (cara menos dura con luz lateral, piel sin brillo de plástico); se nota más de cerca.

**Además (animaciones):** golpe de Lya con anticipación (carga 0,12 s, cetro atrás del todo 0,3, pausa 0,36, golpe 0,45,
seguimiento 0,55; impacto sin cambiar; `PREPARA_GOLPE` 0,25 → 0,3: la pausa cae en la carga, y el combate sigue mandando:
golpea a los 0,28 s de preparar y el impacto llega 0,1 s después, como siempre); magia de Kael con el sable por encima de la
cabeza y algo por fuera (antes la empuñadura tapaba la cara); victoria de Lya con el cetro al lado (antes, delante de la
cara). Instantes intactos: Kael 0,64 / 0,85, Lya 0,45 (golpe) / 0,5 (magia), Juicio de Garon 1,10 (comprobados en la prueba).
Garon: su GLB no cambia (solo el material nuevo).

**Opción de Ajustes** (`menus.gd`, tras «Bramavidrio»): «Protagonistas: ● Originales / ○ v2 (prueba)». `heroes_v2.gd`:
`en_ajustes()` lee `[heroes] v2` de `user://ajustes.cfg`; `elegir_en_ajustes(si)` hace `Engine.set_meta("heroes_v2", si)` y
lo guarda. Orden: meta → argumento → Ajustes → `ACTIVO_POR_DEFECTO`. Se nota en el próximo combate o región (combate.gd,
vista3d.gd y grupo_3d.gd ya pasan por `script_de`).

### Pruebas (aisladas, `ejecutar_pruebas.ps1`; «partida.save real: sin cambios · carpeta real de datos: sin cambios»)
- `prueba_heroes_v2` (auto): **SUPERADA, 201 comprobaciones, 0 fallos** (antes 176): todo lo anterior más Ajustes, loseta
  «decidido», atlas transparente, luz de la cara, materiales mates, ritmos de parpadeo y la victoria de Kael medida.
  `D:\REBELUM_diagnostico\pruebas\2026-11-12_154546\resumen.md`.
- `fotos_heroes_v2`, `fotos_heroes_v2_combate`, `fotos_heroes_pulido` (ventana): **MANUAL, sin errores** (83, 16 y 36
  capturas), mismo resumen. `fotos_heroes_pulido` es nueva (combates de verdad y regiones; modo vídeo).
- **Batería completa** (`ejecutar_pruebas.ps1`, solo automáticas, tras `c1aff03`): **133 SUPERADAS · 0 FALLIDAS ·
  61 MANUALES · 0 NO SEGURAS**; partida.save real, carpeta real de datos y proyecto sin cambios.
  `D:\REBELUM_diagnostico\pruebas\2026-11-12_155304\resumen.md`.
- Revisión visual (no automática): todas las capturas y vídeos de abajo, mirados uno a uno.

### Evidencias: `D:\REBELUM_diagnostico\animaciones\2026-11-13\heroes_pulido\`
- `comparaciones\`: pares **izquierda original · derecha v2**, mismo encuadre, luz, perfil (medio) y fotogramas:
  `combate_llanura_{kael,lya,garon,kael_lya_garon}`, `combate_{bosque,montana,ciudad,desierto}_kael_lya_garon` (combates de
  verdad, en guardia, sin órdenes, misma semilla) y `region_{pastos,garganta,oakhaven,gran_bosque,mar_cristal}_{lejos,cerca}`
  (cámara del juego y a 9 m; esperas en pausa). Sueltas en `sueltas\`.
- `combate_secuencia\`: combate real automático con `semilla=7`, 16 instantes antes y después; `pares\` lado a lado.
- `videos\`: `kael_original_vs_v2.mp4`, `lya_original_vs_v2.mp4`, `garon_original_vs_v2.mp4` (grabados en Godot con
  `--write-movie`, cámara y luz del combate, original a la izquierda y v2 a la derecha a la vez): guardia, ataque, magia,
  golpe recibido, victoria y reposo de exploración (≈15 s cada uno).
- `estudio_combate_y_exploracion\`: las 83 de `fotos_heroes_v2` (victoria en 6 instantes, caras con «decidido»).
- `material\`: `material_comparado_izq_12-11_der_13-11.png` y las tres luces.
- `diagnostico\`: causas y arreglos (victoria en dos intentos, caras con parche AgX → final, atlas con su alfa, Lya).
- `blender\kael`, `blender\lya`: hojas de contacto de cada clip, atlas y `.blend` (fuera de Git).

### Límites (honesto)
- **Nada medido en el Redmi** (sin ADB por encargo) ni rendimiento en el PC. Coste esperado: el sombreador hace las mismas 3
  lecturas de textura; `RIM` y la luz envolvente son unas operaciones por luz; la cara pasa a transparente (182-326
  triángulos, solo mientras hay una expresión que no es la normal). Los GLB de Kael y Lya, como antes (4,97 y 3,23 MB).
- La mejora de materiales es de sombreado sobre las texturas de Meshy, no de texturas ni geometría nuevas: a la distancia del
  juego se nota poco. Las facetas del modelo de Meshy en la cara siguen (solo en primeros planos que el juego no usa).
- Caras: proyección plana de frente; con la cabeza muy girada, el trazo se estira un poco. Sin labios sincronizados.
- En las capturas de cerca de las regiones, **los originales no se giran hacia la cámara con `mirar()`** y los v2 sí (no
  he buscado por qué; no afecta al juego). Y en la primera visita de algunas regiones sale un comentario (solo en «antes»).
- Las esperas de exploración (`animaciones/esperas/*.res`) con el esqueleto v2 no las he vuelto a revisar una a una.
- Deslizamiento de pies de los clips nuevos: no medido con números (el rig apoya los pies por IK salvo en los saltos);
  revisado a ojo en vídeo y hojas.
- El enganche de `hablar(animo)` en Dialogic sigue sin hacer (archivos de diálogos, fuera de esta tarea).

### Pendiente de Android
- Elegir Ajustes → «Protagonistas: v2 (prueba)» en el Redmi y mirar un combate de tres y Pastos: tiempo por fotograma y
  memoria (programado por el coordinador), y a ojo la cara transparente, el borde `RIM` y la luz envolvente en Mali-G57.

### Siguiente paso propuesto
1. Que el usuario compare en `comparaciones\` y los tres vídeos y, si le gusta, lo pruebe en el móvil con la opción de Ajustes.
2. Si se aprueba: `ACTIVO_POR_DEFECTO = true` (o dejar la opción) y el retrato de Garon en `garon.dch` (informe del 12/11).
3. Pulido siguiente: enganchar `hablar(animo)` a Dialogic (con `retrato_vivo.gd`), revisar las esperas con el rig v2, y medir
   pies con `prueba_anim_pies.gd` en los clips nuevos.
