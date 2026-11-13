# Combate V12 · Bestiario de producción (e01-e10)

## 13/11/2026 · rama LOCAL `claude/v12-bestiario` (`D:\Aethelgard_v12_bestiario`, desde `dc167b0`)

Encargo: el bestiario común del PDF `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Bestiario_Produccion.pdf`
(leído entero: 29 págs.; especificación propuesta para combate en tiempo real). Sin push ni merge. Todo lo nuevo,
APAGADO tras `enemigos_v12`. Matriz honesta e01-e10, conversión al ATB y región de cada uno: **`docs/v12/BESTIARIO_V12.md`**.

### 1. Qué hay (diseñado / generado / importado / integrado / probado / validado en Android)

| | e01 Peón de Linde | e02 Velador de Corteza | e03-e10 |
|---|---|---|---|
| Diseñado (ficha adaptada al ATB) | sí | sí | conversión propuesta en la tabla del apartado 4 del documento, sin producir |
| Generado (Blender por guion) | sí | sí | no |
| Importado en Godot 4.7.2 | sí (20 clips, instantes comprobados) | sí (20 clips) | no |
| Integrado (módulo, ganchos, sonidos, grupos) | sí, APAGADO | sí, APAGADO | no |
| Probado (PC, aislado) | sí | sí | no |
| Validado en Android | **no** (Redmi desconectado) | **no** | no |

Elegí, tras el piloto verificado, la familia **pesada** (el Velador) para comprobar que el rig base sirve a otra
altura y anchura sin tocarlo (1,65 → 1,95 m, `ancho` 1,22, `hombros` 1,28). Mejor dos terminados que diez a medias.

### 2. El piloto · e01 Peón de Linde (Pastos Verdes y caminos)

- **Arte (Blender 5.2.3 por guion):** `aethelgard/enemigos/peon_linde/fuente/crear_peon_linde.py` sobre el rig base común
  `aethelgard/enemigos/bestiario_comun/fuente/bestiario_rig.py` (nuevo: plantilla de 22 deformantes + raíz con los nombres
  del proyecto y su equivalencia con los del documento, sockets, pasos en el sitio, giro, tambaleo, lámina y relleno de
  pesos huérfanos). Máscara de mojón con la cruz de deslinde y la coronilla pintada de hito, chaqueta de fibras salvia con
  la franja blanca (pegada a la chaqueta con rayos), faldón de cuatro placas (cadera + muslo), mitones grandes y dos
  estacas de agrimensor, más dos de repuesto cruzadas a la espalda. 3 536 triángulos, 24 deformantes (22 + las estacas),
  atlas 1024 / 512 pintado por código (barro craquelado, fibra, arenisca, madera, bandas, cal, arcilla).
- **Clips (20):** los 18 del documento con los nombres del juego (equivalencia en `peon_linde_clips.json`, `mapa_pdf`) y
  `carga`/`carga_espera` del ATB. Revisión: lámina frente / perfil / espalda junto a Kael y hoja de 28 poses
  (`D:\REBELUM_diagnostico\v12\expansion\bestiario\laminas\peon_linde_lamina.png`, `peon_linde_poses.png`). Defectos
  corregidos durante la revisión: dos vértices sin peso en las hombreras (se estiraban como púas al alzar el brazo;
  ahora el guion rellena los huérfanos y lo dice), el cruce de estacas del Piquete (con IK de manos) y la estaca lanzada
  (se guarda bajo el suelo mientras «vuela» y reaparece en la mano tras el hombro al recoger; nada de escala animada).
- **Combate (`aethelgard/combate_peon.gd`, nuevo):** Piquete cruzado (a uno ×1,0), Estaca de aviso (a distancia ×0,85,
  daño al llegar, nunca dos seguidas), Zancada de lindero (turno de aviso con marca; en fila ×1,3 + ×0,5 al de detrás en el
  mismo impacto; Retroceso −15 % de la barra ATB), tras dos ataques se repliega y busca flanco. Tabla y conversión en el
  documento. Vida 72, ataque 11, velocidad 15 (región «llanura», base 2).
- **Sonido:** 8 WAV mono 48 kHz (QOA) en `aethelgard/audio/efectos/peon/`, derivados de Sonniss GDC 2017-2018 con el guion
  `D:\REBELUM_diagnostico\v12\expansion\bestiario\sonido\preparar_peon.py` (método del de enemigos); filas en
  `docs/audio/efectos_procedencia.csv`. **Medidos, no escuchados.** Voz «piedra».

### 3. e02 · Velador de Corteza (Gran Bosque Verde)

- **Arte:** `aethelgard/enemigos/velador_corteza/fuente/crear_velador_corteza.py` (mismo rig base a 1,95 m): corteza de
  surcos y placas con musgo turquesa, máscara oval de corcho, escudo de anillos (rodaja de tronco con médula y grietas) en
  el antebrazo izquierdo, maza de poda con hoja de podadera, alero de corteza en el hombro, placas en codos y rodillas.
  2 872 triángulos, 24 deformantes, atlas 1024 / 512. Lámina y poses en `..\laminas\velador_corteza_lamina.png` y
  `velador_corteza_poses.png`.
- **Clips (20):** los 18 del documento (su propio, guard_loop → `guardia_espera`, que es su reposo en combate) y
  `carga`/`carga_espera`.
- **Combate (`aethelgard/combate_velador.gd`, nuevo):** Guardia de anillos (la defensa de siempre de los enemigos fuera
  de sus ataques; se abre al segundo golpe parado hasta su turno siguiente), Mazazo (×1,35), Empuje (×0,65 + Retroceso
  −20 %), Raíz de umbral (turno de aviso, desde su sitio, ×0,9 + Retroceso −15 % = la lentitud del documento). Vida 115,
  ataque 13, velocidad 11 (región «bosque», base 4).
- **Sonido:** 9 WAV en `aethelgard/audio/efectos/velador/` (`preparar_velador.py`), voz «corteza». Medidos, no escuchados.

### 4. Interruptor y cómo se enciende

`enemigos_v12` (el de los modelos propios): `Engine.set_meta("enemigos_v12", true)` o `-- enemigos_v12`. APAGADO por
defecto y fuera de la partida. Encendido: uno de cada cuatro encuentros al azar de la **llanura** trae Peones y uno de
cada cuatro del **bosque**, al Velador, del tamaño del grupo. Combates de prueba: `-- grupo=22|23|24 enemigos_v12` (Peón:
1, 2 o 3) y `-- grupo=25|26|27 enemigos_v12` (Velador: solo, con Slime, con Grimfang y Slime). **Apagado, el azar no
cambia** (la prueba compara 300 semillas por tamaño con la fórmula de siempre, incluida la tirada siguiente) y la
huella del combate es la misma.

### 5. Pruebas (aisladas; partida real y carpeta real de datos sin cambios)

Resúmenes en `D:\REBELUM_diagnostico\v12\expansion\bestiario\pruebas\<fecha_hora>\resumen.md`:
- `2026-11-13_015917` (solo el Peón integrado): **15 SUPERADAS, 0 FALLIDAS**: `prueba_peon_v12`, `prueba_combate_huella`
  (la huella igual: apagado no cambia nada), `prueba_enemigos_v12`, `prueba_efectos`, `prueba_grupos_combate`, `prueba_ia`,
  `prueba_equilibrio`, `prueba_huir`, `prueba_centinela_v12`, `prueba_golem_v12`, `prueba_sincronia_golpes`, `prueba_garon`,
  `prueba_menu_magia`, `prueba_centinela`, `prueba_incorporacion`.
- `2026-11-13_022834` (con el Velador integrado): las mismas 15 y `prueba_velador_v12`: **14 SUPERADAS y 2 FALLIDAS**, las
  dos mías y en el mismo punto (D, el encuentro al azar): la prueba predecía desde fuera la semilla que da su grupo, y el
  arranque del combate gasta azar antes de elegirlo. **No era un fallo del juego**: ahora D arranca 24 encuentros al azar
  de verdad y cuenta cuántos traen su grupo (Peón 4/24, Velador 8/24; los demás, los de siempre).
- Repetición tras el arreglo de D (y quitar del A, que depende del azar, la exigencia de ver la Estaca / la Zancada / el
  Empuje, que el B fuerza siempre): `2026-11-13_025555` → `prueba_velador_v12` **SUPERADA**; `2026-11-13_030647` →
  `prueba_peon_v12` **SUPERADA** («partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin
  cambios»). Las otras 14 no dependen de las pruebas cambiadas y estaban en verde con el mismo `combate.gd`
  (`2026-11-13_022834`).

Lo que miran (todo con el interruptor encendido salvo donde se dice):
- **U** sin escena: interruptor apagado y fuera de la partida; apagado, `grupo_al_azar` da lo mismo que la fórmula de
  siempre en 300 semillas × 3 tamaños, y la tirada siguiente es la misma (no gasta azar); encendido, solo en su región
  (≈ 25 %) y en el grupo de su tamaño; sonidos QOA mono 48 kHz con su fila de procedencia; el modelo: 20 clips, duraciones
  del documento ±1/30 s, bucles, instantes iguales en el JSON y en Godot, triángulos y huesos dentro del presupuesto.
- **S**: apagado, su grupo forzado lo trae sin personalidad (nadie lo fuerza en el juego); encendido, con la suya.
- **A**, estrategia de jugador (vida ×3 solo aquí): en cada turno suyo, un impacto por golpe, todo el daño en ese fotograma
  (±1), el golpe de siempre una vez y su sonido propio una vez en el impacto; la Zancada / la Raíz solo tras su aviso y un
  turno de héroe; la Estaca: su sonido al soltar, el daño y su sonido al llegar (6-14 fotogramas después) y sin moverse;
  el aviso y el repliegue sin daño; el Peón nunca tres ataques seguidos; el Velador vuelve a la guardia tras su turno.
- **B**, controlado (Peón): Estaca 8 / defendida 4 / con Guardia a Garon 5; Zancada al marcado 8 y al de detrás 2 en el
  mismo fotograma, defendiendo 4 y 1 (sin Retroceso), con Guardia 6; Retroceso, nunca a quien tiene el turno en la cola;
  cortada por daño y por Quiebra (aturdido, pierde el turno, la rotura suena una vez, no la vuelve a preparar enseguida);
  repliegue tras dos ataques y flanco a la curandera; herida fuerte; derrota con su derrumbe una vez.
  (Velador): guardia [20, 20, 40] (los dos primeros a la mitad, al segundo se abre con su sonido una vez, el tercero
  entero; vuelve tras su turno); Mazazo 14 / defendido 7; Empuje 4 / 2 con Retroceso solo sin defender; Raíz 11 /
  defendida 5 / con Guardia 8, desde su sitio; cortada por daño y por Quiebra; herida fuerte; derrota.
- **C**, niveles REALES de incorporación (Lya llega a nivel 1 en PV-03 y Garon a nivel 1 en PV-05; Kael 1-4), solo ataques
  automáticos: Peón — Kael 1 solo, Kael 3 solo, Kael 3 + Lya 1, Kael 4 + Lya 2 + Garon 1: **ganan todos**. Velador (bosque,
  nivel base 4) — Kael 4 solo, Kael 5 + Lya 4, los tres a 5/4/4: ganan.
- **D** encuentros al azar de su región; **E** derrota (sin monedas) y huida (sin marcas colgando); al cerrar cada
  combate, sin nodos huérfanos ni sonidos suyos sonando.
- **Q** equilibrio (6 semillas, solo ataques automáticos: el caso pesimista, no prueba la estrategia de un jugador), PV
  perdidos de media, frente al encuentro de siempre del mismo tamaño en la misma región:

| Héroes (niveles) | De siempre | PV perdidos | Nuevo | PV perdidos | Victorias |
|---|---|---|---|---|---|
| Kael 2 (llanura) | GRUPOS[10] Zarzalín | 18-21 | [22] un Peón | 13 | 6/6 y 6/6 |
| Kael 3 + Lya 1 (llanura) | [3] Grimfang + Slime | 56-59 | [23] dos Peones | 42-48 | 6/6 y 6/6 |
| Kael 4 + Lya 2 + Garon 1 (llanura) | [2] Slime, Grimfang, Slime | 39-41 | [24] tres Peones | 28-33 | 6/6 y 6/6 |
| Kael 4 (bosque) | [9] Grimfang | 37 | [25] el Velador | 55 | 6/6 y 6/6 |
| Kael 5 + Lya 4 (bosque) | [3] Grimfang + Slime | 76 | [26] Velador + Slime | 92 | 6/6 y 6/6 |
| Kael 5 + Lya 4 + Garon 4 (bosque) | [2] Slime, Grimfang, Slime | 53 | [27] Velador, Grimfang, Slime | 66 | 6/6 y 6/6 |

  El Peón queda algo más fácil que lo de siempre (es el común de entrada: el documento pide presentarlo poco a poco) y el
  Velador algo más duro (es el defensor del bosque). Los dos, dentro del margen de la prueba (ganar igual y no perder más
  de 1,6 × + 25 PV). Ajustar `MULT_*` en los módulos si el usuario los quiere de otra manera.

Evidencias: vídeos (15 fps, media resolución, de los fotogramas del juego) del Peón en
`D:\REBELUM_diagnostico\v12\expansion\bestiario\videos\` (A con tres Peones; B: piquete, estaca sin / defendida / con
Guardia, Zancada sin / defendida / con Guardia / cortada, repliegue, derrota) y del Velador en `..\videos_velador\` (A con
Grimfang y Slime; B: guardia, mazazo, empuje, Raíz sin / defendida / con Guardia / cortada, derrota). Capturas en
`..\capturas\` (`peon_hoja_combate.jpg`, `velador_hoja_combate.jpg` y sueltas). En las del B el enemigo sale azulado y
«Congelado» a ratos: Kael lleva un arma que congela (efecto de siempre), no es del módulo.

### 6. Medida en el PC (perfil medio, `medir_escenas.ps1 -Escenas combate3 -Ciclos 3`; NO son FPS del Redmi)

Con unos 50 Godot y Blender de otros especialistas en marcha (`medidas\*\procesos.txt`): comparar con cuidado. El
fotograma está en el tope del perfil (25 ms) en los dos casos.

| Pasada | Carga del combate (ms, 1.º / 2.º / 3.º) | Fotograma media / p95 en combate (ms) | Dibujos | Memoria de vídeo (MB) |
|---|---|---|---|---|
| GRUPOS[2] de siempre (Slime, Grimfang, Slime), `-Extra grupo=2` | 3 824 / 1 832 / 1 575 | 25,0 / 25,1 | 95-115 | 114,6-118,8 |
| GRUPOS[24], tres Peones, `-Extra grupo=24,enemigos_v12` | 2 614 / 1 468 / 1 433 | 25,0 / 25,1 | 108-113 | 112,5-117,1 |

Tres Peones con su ventana 3D cada uno no cuestan más que el grupo de siempre en el PC. A medir en el Redmi (cada
enemigo 3D es una ventana de 900×760 dibujada al 70 % en el móvil).

### 7. Límites (honesto)
- **Sin Redmi**: nada medido ni validado en Android. Cada enemigo 3D es una ventana propia (Peón 900×760, Velador 960×860);
  tres Peones son tres ventanas: medir en el teléfono antes de encender `enemigos_v12` para el usuario.
- **Sonidos medidos, no escuchados** (pico y RMS; volúmenes puestos por el RMS).
- **Decisiones de diseño a confirmar por el usuario:** el **Retroceso** (quita una parte de la barra ATB al héroe que
  recibe un empuje o una lentitud sin defender; nunca a quien ya tiene el turno) es mío, para traducir el empuje y la
  lentitud del documento sin crear estados nuevos. No toca el ATB en sí (las barras se llenan igual), pero es una regla de
  enemigo nueva: `RETROCESO_ATB = 0.0` en `combate_peon.gd` y `RETROCESO_* = 0.0` en `combate_velador.gd` la quitan.
  También el **repliegue** del Peón (un turno sin atacar tras dos ataques) y la **guardia** del Velador con la defensa de
  siempre de los enemigos.
- Los clips que el combate aún no usa (`lateral_*`, `girar_*`, `recibir_golpe_espalda`, `desaparecer`, `alerta` del
  Velador) están hechos para el mapa; ninguna región los usa todavía (no hay enemigos a la vista en el mapa 3D).
- Arte: estilizado y por primitivas (cajas redondeadas, tubos, rocas); revisado en láminas y en el combate, sin
  normales horneadas ni LOD propios (Godot genera los LOD al importar). Mejor que un cambio de color, pero no al nivel de
  los héroes: que lo juzgue el usuario con las láminas.
- e03-e10: solo la conversión propuesta (documento, apartado 4). No hay arte ni código suyo.
- Posible choque al integrar: si otro especialista añade grupos tras el 21, hay que renumerar `GRUPOS_POR_TAMANO` en los
  dos módulos (22-27).

### 8. Para integrar (copiando archivos)
NUEVOS:
- `aethelgard/enemigos/bestiario_comun/fuente/` (`bestiario_rig.py`, `.gdignore`)
- `aethelgard/enemigos/peon_linde/` (GLB, 2 WebP, JSON, `peon_linde_3d.gd` y sus `.import`/`.uid`; `fuente/` con
  `crear_peon_linde.py` y `.gdignore`)
- `aethelgard/enemigos/velador_corteza/` (lo mismo para el Velador)
- `aethelgard/combate_peon.gd`, `aethelgard/combate_velador.gd` (+ `.uid`)
- `aethelgard/audio/efectos/peon/` (8 WAV + `.import`), `aethelgard/audio/efectos/velador/` (9 WAV + `.import`)
- `aethelgard/pruebas/prueba_peon_v12.gd`, `fotos_peon_v12.gd`, `prueba_velador_v12.gd`, `fotos_velador_v12.gd` (+ `.uid`)
- `docs/v12/BESTIARIO_V12.md`, este informe

COMPARTIDOS modificados:
- `aethelgard/combate.gd`: ganchos «V12, Peón» y «V12, Velador» (const, ENEMIGOS, MODELOS, ANIM, GRUPOS[22]-[27],
  `grupo_al_azar`, preparar, al_entrar, turno, vigilar, animar_golpe, info, estados/repasar, al_acabar). Apagado, sin efecto.
- `aethelgard/sonido.gd`: 17 claves al final de EFECTOS y 2 en FAMILIAS.
- `aethelgard/pruebas/lista_pruebas.txt`: 4 líneas al final.
- `docs/audio/efectos_procedencia.csv` (17 filas al final) y `docs/recursos.md` (4 filas al final).
Fuera de Git: `.blend`, láminas, poses, atlas de trabajo, guiones de sonido y vídeos en
`D:\REBELUM_diagnostico\v12\expansion\bestiario\`.

### 9. Cierre (formato del documento)

| ID | Rutas reales | Clips | Ataques probados | Defectos abiertos | Arte | Integración | Android |
|---|---|---|---|---|---|---|---|
| e01 Peón de Linde | `enemigos/peon_linde/`, `combate_peon.gd`, `audio/efectos/peon/`, `pruebas/prueba_peon_v12.gd` | 18/18 (+2 del ATB) | 3/3 | sonido sin escuchar; Retroceso y repliegue por confirmar | verificado (PC) | verificado, APAGADO | bloqueado (sin Redmi) |
| e02 Velador de Corteza | `enemigos/velador_corteza/`, `combate_velador.gd`, `audio/efectos/velador/`, `pruebas/prueba_velador_v12.gd` | 18/18 (+2) | 3/3 + guardia | sonido sin escuchar; «no bloquea por detrás» sin adaptar | verificado (PC) | verificado, APAGADO | bloqueado |
| e03-e10 | — | 0/18 | 0/3 | sin producir | pendiente | pendiente | bloqueado |

Reproducir: `blender -b --factory-startup -P aethelgard/enemigos/<nombre>/fuente/crear_<nombre>.py -- <raíz aethelgard>
<carpeta de láminas>` (misma semilla, mismo resultado); importar con datos aislados; `pruebas/ejecutar_pruebas.ps1 -Solo
prueba_peon_v12,prueba_velador_v12`.

### 10. Siguiente paso propuesto
1. Que el usuario vea las láminas y los vídeos y decida si enciende `enemigos_v12`; medir en el Redmi un combate de tres
   Peones (GRUPOS[24]) y del Velador (GRUPOS[27]).
2. Confirmar o quitar el Retroceso (apartado 7).
3. Seguir por familias: la ágil (e08 Cartógrafo de Duna, e10 Recolector de Vidrio, en el Mar de Arena de Calid) sobre el
   ciclo del Peón, y la pesada (e04 Cantero de Sal) sobre el del Velador.

---

## 13/11/2026, madrugada · segunda pasada: el arte del Peón y del Velador (v2) y el coste de las ventanas 3D

Encargo del coordinador: el modelo v1 «aún no está al nivel de REBELUM» (cabeza de caja, piernas de tubo, articulaciones
de bloque, proporciones adultas junto a un Kael chibi). Misma copia y rama; la v1 se conserva entera.

### 1. Qué cambia (v1 → v2), con los mismos guiones
- **Rig base** (`bestiario_rig.py`): `huesos()`/`crear()` aceptan proporciones (`piernas`, `cabeza`, `brazos`); con 1, 1, 1
  sale la plantilla de antes. Nuevo: `torno()` (sólidos de revolución con pliegues y cara aplanada), `doblar()` (placas
  que abrazan el cuerpo), `borrar()`, `normal_desde_alturas()` y `lamina_heroes()` (frente, perfil y espalda junto a
  **Kael, Lya y Garon a su altura del combate**: los héroes miden 1,7 m y se dibujan a esc 0,67 / 0,6 / 0,67, los enemigos
  a 0,6, así que en unidades del enemigo Kael y Garon miden 1,90 m y Lya 1,70 m).
- **Guiones**: `crear_peon_linde.py` y `crear_velador_corteza.py` con `v2` ejecutan `malla_peon_v2.py` / `malla_velador_v2.py`
  (nuevos) y escriben `*_v2.glb`, `*_v2.webp`, `*_v2_bajo.webp`, `*_v2_normal.webp` y `*_v2_clips.json` al lado de la v1
  (la v1 no se reescribe: git no ve cambios en sus archivos). Las poses se escriben como en la v1 y `a_v2()` las lleva a
  las piernas cortas (altura de la raíz y de los pies × factor de piernas, manos con el tronco). Mismos huesos, mismos 20
  clips con las mismas duraciones e instantes: el combate no cambia.
- **Peón v2**: piernas ×0,70, cabeza ×1,35, brazos ×0,86 → 1,50 m (antes 1,65). Máscara de mojón abombada (torno) con ceja
  tallada, nariz de cuña, cuencas hundidas con los ojos, la cruz de deslinde y la coronilla pintada de hito; capucha
  abierta por delante; chaqueta acampanada con nueve pliegues en el bajo y ribete (la silueta triangular); faldón de cuatro
  placas curvadas que asoman bajo la chaqueta; rodilleras redondas, polainas y botas con caña, puntera y suela; mitones
  con pulgar. 5 870 triángulos (v1: 3 536).
- **Velador v2**: piernas ×0,66, cabeza ×1,25, brazos ×0,88 → 1,73 m (antes 1,95). Tronco de torno con surcos y placas de
  corteza curvadas encima, tocón por cabeza con los anillos arriba y dos ramas cortadas, máscara oval de corcho grande y
  abombada con su reborde, alero de dos tablas, escudo de anillos con canto redondo y bollón de nudo, maza con mango
  encordado, nudos y la hoja de podadera curva, piernas que acaban en raíces. 5 148 triángulos (v1: 2 872).
- **Atlas**: de 4×4 a 3×3 celdas en el mismo 1024 (341 px por material: más resolución) y pintado con más detalle (trama y
  costuras de la fibra, chorretones y paja del barro, cincel, vetas y liquen del mojón, desconchones de las placas; surcos
  con placas, liquen y musgo de la corteza, poros del corcho, espiras de la cuerda). **Mapa de normales** sacado del relieve
  pintado (por celdas), 1024, comprimido como los de Bramavidrio v5 (`compress/normal_map=1`, mipmaps); el guion de
  Godot lo pone en los materiales salvo en calidad baja. Sombreado suave en todo salvo las puntas.
- **Elección**: el juego usa la v2 si está (MODELOS pone la v2 delante de la v1, como el Centinela). Con
  `Engine.set_meta("bestiario_v1", true)` o `-- bestiario_v1`, la v1 (para comparar).

### 2. Rendimiento: una ventana 3D por enemigo
**Cómo es hoy (observado en `combate.gd` `_crear_rig_3d` y `estudio_3d`):** cada luchador 3D tiene su SubViewport, su
mundo, su cámara y su luz; su imagen se pega como un Sprite2D que el combate mueve, tiñe, ordena y desvanece por
separado. Tres Peones son tres ventanas: tres pasadas de render (en una GPU por mosaicos como la Mali-G57, cada ventana
es un cambio de destino con su borrado y su volcado) y tres veces su memoria.

**Lo hecho (sin tocar el patrón común): ventanas al tamaño justo.** `prueba_bestiario_encuadre` (nueva) proyecta los
huesos y las puntas de las armas en todos los clips a la misma nitidez de los demás v12 (277 px por metro) y da la ventana
mínima sin cortes. Con la v2:

| | Antes (MODELOS, v1) | Ahora (v2) | Píxeles | Memoria por ventana (PC, ×0,75; color + profundidad) | En el móvil (×0,7) |
|---|---|---|---|---|---|
| Peón | 900×760, 2,75 m | 850×680, 2,45 m | −15 % | 3,08 → 2,60 MB | 2,68 → 2,27 MB |
| Velador | 960×860, 3,10 m | 670×820, 2,95 m | −33 % | 3,72 → 2,47 MB | 3,24 → 2,15 MB |

Con tres Peones, −1,4 MB y un 15 % menos de relleno; con el Velador, −1,2 MB y un 33 % menos. **Misma nitidez** (los px por
metro no cambian). Las cifras de memoria son cálculo (píxeles × 8 bytes × la escala de `res_personajes`); la medida del PC
no las resuelve: entre dos sesiones el grupo de siempre varía 6 MB de memoria de vídeo (118,8 y 124,5 MB) por los demás
Godot en marcha, más que lo que se quiere ver. En la misma sesión: GRUPOS[2] de siempre 122,8-124,5 MB; tres Peones v1
132,7; tres Peones v2 130,7; Velador v2 con Grimfang y Slime 131,0 (`D:\REBELUM_diagnostico\v12\expansion\bestiario\
medidas\`). Los ~8 MB de más frente al grupo de siempre son sobre todo texturas (+7-9 MB): los atlas de los enemigos v12
se importan sin compresión (como los del Centinela y el Gólem: 4 MB cada 1024), y el mapa de normales de la v2 se
importa comprimido. El fotograma, en el tope del perfil medio (25 ms) en todas.

Hallazgo de paso: la estaca lanzada de la v1 se escondía 3 m a un lado (fuera de la ventana: no se veía, pero contaba en
el encuadre); en la v2 se esconde 1,5 m bajo los pies.

**Compartir una ventana entre enemigos del mismo tipo: NO lo hago (documentado).** Se podría: los N modelos en un solo
mundo 3D separados, una sola cámara y una sola pasada, y cada Sprite2D con su trozo (AtlasTexture) de la ventana común.
Ahorraría pasadas de render (de 3 a 1: lo que más pesa en la Mali), **no** memoria ni relleno (los trozos suman lo mismo).
Pero toca `estudio_3d`/`_crear_rig_3d`, que usan todos los héroes y enemigos 3D, y la cámara de cada enemigo se mueve
con él (las de Bramavidrio y Humbaba, propias): el riesgo de romper otros combates es alto para lo que se gana sin medir en
el teléfono. Propuesta: probarlo primero en el Redmi con Streamline (tiempo por pasada de render con 1 y con 3 Peones)
y decidir con ese número.

### 3. Pruebas (aisladas; partida real y carpeta real de datos sin cambios)
`D:\REBELUM_diagnostico\v12\expansion\bestiario\pruebas\2026-11-13_034353\resumen.md`: **17 SUPERADAS, 0 FALLIDAS**
(«proyecto: sin cambios»): `prueba_bestiario_encuadre` (nueva), `prueba_peon_v12`, `prueba_velador_v12`,
`prueba_combate_huella`, `prueba_enemigos_v12`, `prueba_efectos`, `prueba_grupos_combate`, `prueba_ia`, `prueba_equilibrio`,
`prueba_huir`, `prueba_centinela_v12`, `prueba_golem_v12`, `prueba_sincronia_golpes`, `prueba_garon`, `prueba_menu_magia`,
`prueba_centinela`, `prueba_incorporacion`.
- `prueba_peon_v12` y `prueba_velador_v12` miran ahora también la v2 (**U v2**): por debajo de 6 000 triángulos, mismo
  esqueleto, los mismos 20 clips con las mismas duraciones e instantes que la v1, más compacta (1,50 frente a 1,65 m;
  1,73 frente a 1,95 m), el juego carga la v2 con el mapa de normales (no en calidad baja) y, con `bestiario_v1`, la v1 sin
  normales. Todo lo demás (impacto, daño y sonido en el mismo fotograma, avisos, cortes, Defender, Guardia, Retroceso, 1, 2
  y 3 héroes con los niveles reales, encuentros al azar, derrota, huida, equilibrio) pasa igual con la v2: las cifras del
  apartado 5 del primer encargo no cambian de forma apreciable (Q del Peón: 11 / 47 / 28 PV perdidos; del Velador: 52 / 80
  / 64).
- Cambio en las pruebas: el A ya no exige ver la Raíz ni la Estaca (dependen del azar; en una pasada no salió ninguna
  Raíz en 11 turnos); el B las fuerza todas.

### 4. Evidencias (`D:\REBELUM_diagnostico\v12\expansion\bestiario\`)
- **Láminas v1 / v2 junto a Kael, Lya y Garon** (a su altura del combate): `laminas\peon_linde_v1_v2_heroes.jpg`,
  `laminas\velador_corteza_v1_v2_heroes.jpg` (y sueltas `*_v1_heroes.png`, `*_v2_heroes.png`); poses de la v2:
  `laminas\peon_linde_v2_poses.png`, `velador_corteza_v2_poses.png`; `.blend` de la v2 al lado (fuera de Git).
- **Fotos del combate v1 / v2**: `capturas\peon_v1_v2_combate.jpg` y `capturas\velador_v1_v2_combate.jpg` (mismos
  instantes del A y del B). Vídeos de la v2 en `videos_v2\` (Peón: tres, piquete, estaca, Zancada, Zancada cortada,
  derrota; Velador: con Grimfang y Slime, guardia, mazazo, empuje, Raíz, Raíz cortada, derrota). Fotogramas en
  `fotos_peon_v2\` y `fotos_velador_v2\`.
- Medidas: `medidas\peon_v2`, `peon_v1_vpnuevo`, `velador_v2`, `grupo2_b` (y las de la primera pasada).

### 5. Límites
- **Arte**: mucho más cerca de los héroes que la v1 (formas de torno, máscaras con volumen, pliegues, placas, botas,
  mitones, proporciones compactas), pero sigue siendo modelado por guion con primitivas: no tiene la escultura ni el
  pintado a mano de los héroes de Meshy. Las normales salen del relieve pintado (no de una escultura de alta resolución).
  Que lo juzgue el usuario en las láminas.
- Sin Redmi: ni el coste de las normales ni el de las ventanas medido en Android. Memoria de las ventanas: cálculo.
- Los atlas de los enemigos v12 se importan sin compresión (como los del Centinela y el Gólem): comprimirlos ahorraría
  más que las ventanas (unos 3 MB por atlas), pero es una decisión común a todos los enemigos v12 (no la he tocado).
- La v1 forzada (`bestiario_v1`) usa ahora el encuadre de la v2: el Peón v1 cabe; el Velador v1 (1,95 m) puede rozar el
  borde de arriba en la entrada. Solo es para comparar.

### 6. Para integrar (esta pasada; además de lo del primer encargo)
NUEVOS: `aethelgard/enemigos/peon_linde/fuente/malla_peon_v2.py`, `peon_linde_v2.glb`, `peon_linde_v2.webp`,
`peon_linde_v2_bajo.webp`, `peon_linde_v2_normal.webp` (con sus `.import`; el de las normales con `compress/normal_map=1`),
`peon_linde_v2_clips.json`; lo mismo en `aethelgard/enemigos/velador_corteza/` (`malla_velador_v2.py` y `velador_corteza_v2*`);
`aethelgard/pruebas/prueba_bestiario_encuadre.gd` (+ `.uid`).
MODIFICADOS míos: `bestiario_rig.py`, `crear_peon_linde.py`, `crear_velador_corteza.py`, `peon_linde_3d.gd`,
`velador_corteza_3d.gd`, `prueba_peon_v12.gd`, `prueba_velador_v12.gd`, `docs/v12/BESTIARIO_V12.md`, este informe.
COMPARTIDOS: `aethelgard/combate.gd` (solo MODELOS del Peón y del Velador: la v2 delante y la ventana nueva) y
`aethelgard/pruebas/lista_pruebas.txt` (1 línea al final).

### 7. Cierre

| ID | Rutas | Clips | Ataques probados | Defectos abiertos | Arte | Integración | Android |
|---|---|---|---|---|---|---|---|
| e01 Peón de Linde | `enemigos/peon_linde/` (v1 y v2), `combate_peon.gd`, `audio/efectos/peon/` | 18/18 (+2 ATB), iguales en v1 y v2 | 3/3 | sonido sin escuchar; Retroceso por confirmar; arte por guion (sin escultura) | v2 verificado en el PC | verificado, APAGADO | bloqueado |
| e02 Velador de Corteza | `enemigos/velador_corteza/` (v1 y v2), `combate_velador.gd`, `audio/efectos/velador/` | 18/18 (+2) | 3/3 + guardia | ídem | v2 verificado en el PC | verificado, APAGADO | bloqueado |
| e03-e10 | — | 0/18 | 0/3 | sin producir | pendiente | pendiente | bloqueado |

**Siguiente paso propuesto:** que el usuario compare las láminas v1 / v2; medir en el Redmi un combate de tres Peones v2
(pasadas de render y memoria) antes de decidir si se comparte la ventana; después, las familias ágil (e08, e10) y pesada
(e04) ya con la técnica de la v2.
