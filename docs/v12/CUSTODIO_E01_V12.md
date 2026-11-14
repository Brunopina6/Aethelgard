# meshy_e01 · Custodio de Porcelana (V12, fase 9, PILOTO)

Fecha: 14/11/2026. Rama local `claude/v12-custodio` (desde `claude/rebelum-v12` @ b451518), worktree
`D:\Aethelgard_v12_custodio`. Encargo: el enemigo e01 del paquete «Aethelgard_Paquete_Claude_4_Enemigos» (13/11) desde su
FBX de Meshy, con rig, locomoción y UN especial, «Prensa del Umbral» (e01_a1). Espacio de nombres `meshy_e01` (no es el
`common_e01` del bestiario de producción: Peón de Linde).

«Custodio de Porcelana» es un nombre de diseño propuesto por el paquete, no un nombre canónico del juego.

## 1. Qué hay

| Pieza | Archivo |
|---|---|
| Inspección del FBX (paso 1) | `aethelgard/enemigos/meshy_e01/fuente/p0_inspeccionar.py` |
| Escala, esqueleto y pesos (paso 2) | `aethelgard/enemigos/meshy_e01/fuente/p1_rig.py` (+ `e01_comun.py`, `hoja.py`) |
| Clips, medidas, renders y GLB (pasos 3 y 4) | `aethelgard/enemigos/meshy_e01/fuente/p2_clips.py` |
| Modelo del juego | `aethelgard/enemigos/meshy_e01/meshy_e01.glb` (1,09 MB) y `meshy_e01_clips.json`; texturas extraídas `meshy_e01_e01_*.webp` (1024, VRAM) |
| Nodo 3D | `aethelgard/enemigos/meshy_e01/meshy_e01_3d.gd` (sobre `enemigos/v12_comun/enemigo_v12_3d.gd`) |
| Combate (paso 5) | `aethelgard/combate_meshy_e01.gd` y los ganchos «V12, Custodio» de `combate.gd`; `recursos.gd` (fuera de la precarga) |
| Pruebas (paso 6) | `aethelgard/pruebas/prueba_meshy_e01.gd` (auto) y `fotos_meshy_e01.gd` (ventana) |
| `.blend` (fuera de Git) | `D:\REBELUM_entrada_13_11\custodio_trabajo\e01_rig.blend` (rig y pesos), `e01_autoria.blend` (con IK y controles), `e01_exportar.blend` (lo exportado) |
| Fuente intacta | `D:\REBELUM_entrada_13_11\extraido\Meshy_AI_Original_fantasy_game_enemy_Custodio_de_20261108_texture_fbx\` (no se ha tocado; se trabajó en `custodio_trabajo\fuente_copia\`) |
| Evidencias | `D:\REBELUM_diagnostico\v12\custodio\` (`p1_inspeccion`, `p2_rig`, `p3_clips`, `p6_godot`) |

Los guiones de Blender se ejecutan así (Blender 5.2.3, sin complementos):

```
blender -b --factory-startup -P p0_inspeccionar.py -- <fbx copia> <carpeta render> <json>
blender -b --factory-startup -P p1_rig.py -- <fbx copia> <e01_rig.blend> <carpeta render> [sin_render]
blender -b --factory-startup -P p2_clips.py -- <e01_rig.blend> <carpeta GLB> <carpeta render> [sin_render]
```

## 2. Cifras

| | Valor |
|---|---|
| ZIP fuente | SHA-256 `780f37202ea1b819352b6f0ca744a682fa838feeeae6ad891484dff8111fcd4c` (= `inspeccion_real_modelos.json`) |
| FBX | 1 malla, 5 277 vértices, **10 541 triángulos**, 0 armatures, 0 Actions, 0 grupos; 1 material; 4 texturas 2048 empaquetadas |
| Orientación medida | mira a −Y, izquierda +X, Z arriba; 0,951 × 0,649 × 0,265 (unidades del FBX), centrado en el origen |
| Normales / UV | 0 aristas con orientación incoherente, 9 aristas de borde, 0 caras degeneradas; UV dentro de 0-1 (0 fuera) |
| Piezas | 3: el cuerpo soldado (5 098 vértices) y las dos rodilleras sueltas (90 y 89) |
| Escala de juego | **1,85 m** (×1,94497), pies en z = 0, transformación aplicada antes del skin (Velador v2 1,73 m) |
| Huesos | **24** (21 deformantes + `raiz` y las 2 clavículas sin pesos); controles de autoría `ik_mano.*`, `ik_pie.*` no exportados |
| Influencias | **máximo 2** por vértice (≤ 4), normalizadas; lejos de las juntas, 1 |
| Clips | **3**: `e01__idle` 2,4 s (bucle), `e01__walk` 1,2 s (bucle, en el sitio), `e01__attack_prensa` 2,4 s; 30 fps |
| GLB | 1 089 388 bytes; texturas a 1024 (color, normal, metálico-rugosidad) |

Huesos deformantes: `cadera`, `columna`, `pecho` (la llave, rígida a él), `cuello`, `cabeza`, y por lado `hombrera`, `brazo`,
`antebrazo`, `mano`, `muslo`, `pierna` (con su rodillera), `pie`, `punta`. Sin arma ni dedos (el paquete lo pide así).
21 deformantes está por debajo del rango orientativo del PDF (24-32): no hacen falta más para placas rígidas y juntas.

## 3. Método (y por qué)

- **Pesos sin «automáticos»:** la malla es una sola pieza soldada; los pesos por calor doblarían las placas. Se asigna la
  CADENA de cada vértice por distancia geodésica sobre la malla (la mano solo llega al muslo pasando por el hombro), el
  HUESO por el plano de cada junta, y solo a ±r de la junta se mezclan dos huesos (smoothstep). Correcciones medidas
  sobre la primera pasada (renders `p2_rig\hoja_pesos.png`): el borde alto de las placas de los muslos caía en la cadera
  (por geodésica) → por debajo del cinturón todo lo que no es brazo va a la pierna de su lado salvo la pieza central; las
  placas del cuello del peto caían en el cuello → cuello y cabeza solo dentro de |x| < 7,5 cm; el plano del pecho cortaba
  el peto → la junta pecho/columna baja al borde del peto (z 0,125 del FBX).
- **Clips por función del tiempo con IK de autoría** (pies y manos a objetivos, IK de 2 huesos sin estirar), horneados a
  30 fps a cuaterniones de los 24 huesos (posición solo en la cadera). Después se borran controles y restricciones; se mide
  y se exporta lo horneado.
- **Raíz quieta:** locomoción y Prensa en el sitio; el combate desplaza el nodo (como el resto de enemigos v12).

### Medidas de los clips (Blender, lo horneado)

| Clip | Medida |
|---|---|
| e01__idle | pies quietos (0,1 mm); cadera −3,8 cm; salto del bucle 0,000° |
| e01__walk | pie apoyado a velocidad constante 0,866-0,867 m/s (teórica 0,867; el combate puede escalarla) y a ras de suelo (0,7 mm); salto del bucle 0,000°; malla −4,8 mm bajo el suelo como mucho |
| e01__attack_prensa | pies quietos (0,6 mm); cadera −0,262 m = **14,2 % ≤ 15 %**; manos a **1 cm** del suelo en el impacto (0,90 s); mínimo de la malla −4,4 mm (puntas de los dedos, 1,10 s); empieza y acaba en la pose del reposo (0,000°) |

Tiempos de e01_a1 (los del JSON; los segundos mandan): 0,00 pies abiertos · 0,25 flexiona y recoge los brazos · 0,65 puños
por encima de los hombros (fija la dirección) · 0,90 descarga los puños al suelo (IMPACTO; activo [0,90, 1,10)) · 1,10
sostiene el peso · recupera hasta 2,40. Durante el arco de la descarga (≈ 0,70-0,90) los brazos van estirados al máximo
(la IK no alcanza el objetivo intermedio: 24 fotogramas con aviso en el guion; es la pose buscada, brazos rectos).

## 4. Integración (APAGADA)

- Interruptor **propio** `meshy_e01` (`Engine.set_meta("meshy_e01", true)` o `-- meshy_e01`); no es `enemigos_v12` para no
  mezclarlo con el bestiario. No está en `progreso.gd CLAVES` (no se guarda).
- **Nunca al azar**: no hay gancho en `grupo_al_azar`. Solo en sus combates de prueba `GRUPOS[28]` (él solo) y `[29]`
  (con un Slime), que hay que pedir (`-- grupo=28 meshy_e01`). Los índices 0-27 no cambian.
- `ENEMIGOS["meshy_e01"]`: PV 130 (ficha 110-150), ataque 13, velocidad 10 (más lento que el Velador), exp 36, oro 24.
- Carpeta fuera de la precarga mientras está apagado (`recursos.gd APAGADOS`).
- Separación: IA `turno()/_elegir` · ejecutor `_prensa` (objetivos, daño propuesto, recarga) · daño `combate.gd
  _animar_golpe` (el principal) y `animar_golpe/_registrar` (el de detrás) · presentación `meshy_e01_3d.gd` (clip,
  instantes) y la marca.
- **Prensa del Umbral en el ATB** (reglas de `docs/v12/BESTIARIO_V12.md` §2): aviso DENTRO del clip (0,90 s < un turno; no
  se inventa una ocasión de esquivar); marca en el suelo sobre el elegido y el de detrás al empezar el clip, que se FIJA a
  0,65 s y no persigue; en fila: ×1,4 del ataque al elegido (el que menos vida tiene, o la curandera) y ×0,5 de eso al de
  detrás; la Guardia de Garon cubre al principal; Retroceso del 15 % de la barra ATB a quien lo recibe sin defender (el
  empuje de 0,4 m); recarga `cooldown_own_turns = 2` (no `cooldown_s`): en esos dos turnos propios se pone en guardia (golpes
  a la mitad, la regla de siempre) hasta su turno siguiente.
- **Una vez por ejecución y objetivo:** `attack_instance_id` (contador por ejecución) + `target_id` (nombre del héroe); un
  segundo intento cuenta `duplicado_evitado` y no daña.
- **Limpieza:** muerto a media Prensa no golpea (la base no llama al impacto y aquí se comprueba la vida) y la marca se va
  (`vigilar`, `repasar`, `al_acabar`); sin clip de derrota, se queda en su pose (`stop` con estado) y el combate lo
  desvanece (`caida` 0,6 s).

## 5. Pruebas reales

Todas con `pruebas/ejecutar_pruebas.ps1` (datos aislados; la partida real y la carpeta real de datos, sin cambios en
todas las pasadas). Comprobado ejecutando el 14/11/2026 en el PC.

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_meshy_e01` (nueva, auto) | SUPERADA (5,2 s) | `D:\REBELUM_diagnostico\pruebas6-11-14_033850esumen.md` |
| `fotos_meshy_e01` (nueva, ventana) | MANUAL, sin errores, 101 capturas (revisadas) | misma pasada; copia en `D:\REBELUM_diagnostico12\custodio\p6_godot\` |
| Regresiones: `prueba_combate_huella`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_audio_memoria`, `prueba_equilibrio`, `prueba_ia`, `prueba_hud_combate`, `prueba_enemigos_v12`, `prueba_peon_v12`, `prueba_velador_v12` | 10 SUPERADAS | `D:\REBELUM_diagnostico\pruebas6-11-14_032221esumen.md` («proyecto: CAMBIADO» en esa pasada = mis propios archivos editados mientras corría: lista, documentos y el guion de fotos) |

Lo que comprueba `prueba_meshy_e01` (salida literal de la última pasada):
- U: apagado por defecto, fuera de la partida y de la precarga; el azar igual apagado y encendido (1 080 tiradas).
- M: 3 clips, alias = mismo recurso, 24 huesos (21 con pesos), 10 541 triángulos, 2 influencias, 1,85 m; Prensa: pie quieto
  (0,0005 m), cadera −0,237 m (12,8 %, muestreo cada 0,1 s), muñeca en el impacto (0,30; 0,29; 0,42) = delante (+Z) y a
  0,29 m, a 0,65 s a 1,83 m.
- S: apagado, sin personalidad; encendido, con la suya y su modelo 3D.
- A: aviso → fija 19 fotogramas → impacto 27 (0,63 y 0,90 s a 30 fps); marca fija los 27 fotogramas; Lya −17 y Garon −3
  una vez cada uno en el fotograma del impacto; Retroceso 15 % (50 → 35); 2 guardias (recarga 2 → 0); Prensa contra Lya
  defendiendo (−7, sin Retroceso; Garon sí).
- B: muerte durante el aviso: sin impacto ni daño, marca fuera, victoria.
- C: a velocidad ×2 el impacto llega a 14 fotogramas del aviso y golpea una vez a cada uno.
- D: cerrar el combate a media Prensa no deja nodos huérfanos.

Capturas (revisadas a ojo):
- Blender, lo horneado: `p3_clips\hoja_prensa_{frente,perfil,espalda,tres_cuartos}.png` (0,00 · 0,25 · 0,65 · 0,80 · 0,90
  · 1,10 · 1,65 · 2,40), `hoja_idle_walk_*.png`, `hoja_impacto.png`; pesos y esfuerzo en `p2_rig\`.
- Godot (GLB importado, Compatibility): `p6_godot\estudio_<clip>_<t>_<vista>.png` junto a Kael y Garon y
  `hoja_estudio_prensa.png`; combate real `p6_godot_*.jpg` (aviso f_00017, fija f_00026, impacto f_00030, fin f_00069).
  La versión anterior de la marca (antes de hacerla más visible en el aviso) queda en `p6_godot_v1\`.

## 6. Matriz

Estados: pendiente · parcial · verificado · bloqueado.

| Puerta | Estado | Evidencia / motivo |
|---|---|---|
| Fuente preservada | verificado | SHA-256 del ZIP igual al del paquete; se trabajó en una copia; la carpeta extraída sin tocar |
| Diseño (ficha e01, e01_a1) | parcial | e01_a1 adaptado al ATB y documentado; a2 y a3 sin hacer |
| Modelo (escala, orientación, materiales) | verificado (PC) | `p1_inspeccion`, `p6_godot\estudio_*` junto a Kael y Garon |
| Rig y pesos | verificado (PC) | `p2_rig\hoja_pesos.png`, `hoja_estres_{arriba,abajo,paso}.png`; prueba M |
| Clips presentes / esperados | 3 / 12 (parcial) | idle, walk, attack_01 (Prensa); faltan alert, turn_l, turn_r, guard, hit_front, stagger, death, attack_02, attack_03 |
| Especiales probados | 1 / 3 | Prensa del Umbral (prueba A-D) |
| Integración Godot | verificado (PC, apagada) | GLB reimportado, nodo, alias, ganchos; prueba_meshy_e01 |
| Combate | verificado (PC, piloto) | prueba_meshy_e01 A-D y regresiones |
| PC (rendimiento) | pendiente | no medido: había otros Godot en el PC (regla: lo programa el coordinador) |
| Android (Redmi) | bloqueado | sin APK ni teléfono en esta tarea (no se compila); texturas ya a 1024 VRAM |

## 7. Pendientes

- **Clips que faltan (9 de 12):** alert, turn_l, turn_r, guard (hoy la guardia usa el reposo y el tinte de defensa),
  hit_front (sin reacción al golpe), stagger, death (hoy se queda en su pose y se desvanece), attack_02 «Avance del Portón»
  y attack_03 «Sello de Clausura» con sus ataques (a2, a3) en `combate_meshy_e01.gd`.
- **Sonido propio** (golpe pétreo grave, astillas): necesita claves nuevas en `sonido.gd` y derivados con procedencia;
  hoy suena el golpe físico de siempre y el temblor. `_sonidos_bestia` pide `meshy_e01_ataque` y `meshy_e01_entrada`, que
  no existen (no suena nada; no da error).
- **Encuadre y desplazamiento en pantalla:** el combate lo lleva andando hasta el blanco con el clip de andar a su ritmo
  (0,867 m/s) y una duración por distancia (260 px/s); no se ha medido el deslizamiento de los pies en pantalla. En el
  combate se superpone a los héroes delanteros al ir a por Lya (como los demás enemigos cuerpo a cuerpo).
- **Rendimiento:** sin medir (había otros Godot abiertos; lo programa el coordinador). 10 541 triángulos y 3 texturas de
  1024 VRAM: medir en el Redmi con 4 héroes y varios enemigos antes de ampliar; una variante de 512 solo si la medida lo
  pide.
- **Android:** bloqueado (sin APK ni teléfono en esta tarea).
- **Balance:** cifras propuestas (×1,4 / ×0,5, PV 130) sin partidas reales.
- **Al terminar el especialista de Oakhaven** u otros: los grupos 28 y 29 son los últimos de `GRUPOS`; si otra rama añade
  grupos, hay que reordenar los índices al integrar (la prueba comprueba `GRUPOS.size() == 30`).
