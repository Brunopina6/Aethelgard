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
| `prueba_meshy_e01` (nueva, auto) | SUPERADA (5,2 s) | `D:\REBELUM_diagnostico\pruebas6-11-14_033850
esumen.md` |
| `fotos_meshy_e01` (nueva, ventana) | MANUAL, sin errores, 101 capturas (revisadas) | misma pasada; copia en `D:\REBELUM_diagnostico12\custodio\p6_godot\` |
| Regresiones: `prueba_combate_huella`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_audio_memoria`, `prueba_equilibrio`, `prueba_ia`, `prueba_hud_combate`, `prueba_enemigos_v12`, `prueba_peon_v12`, `prueba_velador_v12` | 10 SUPERADAS | `D:\REBELUM_diagnostico\pruebas6-11-14_032221
esumen.md` («proyecto: CAMBIADO» en esa pasada = mis propios archivos editados mientras corría: lista, documentos y el guion de fotos) |

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
| Clips presentes / esperados | **12 / 12 desde el 18/11 (§11)**; el 14/11 eran 3 / 12 | los 12 de la lista; antes del 18/11 faltaban alert, turn_l, turn_r, guard y stagger (histórico) |
| Especiales probados | 1 / 3 | Prensa del Umbral (prueba A-D) |
| Integración Godot | verificado (PC, apagada) | GLB reimportado, nodo, alias, ganchos; prueba_meshy_e01 |
| Combate | verificado (PC, piloto) | prueba_meshy_e01 A-D y regresiones |
| PC (rendimiento) | pendiente | no medido: había otros Godot en el PC (regla: lo programa el coordinador) |
| Android (Redmi) | bloqueado | sin APK ni teléfono en esta tarea (no se compila); texturas ya a 1024 VRAM |

## 7. Pendientes

- **Afinidades: NEUTRAS PROVISIONALES (decisión del usuario, 14/11).** El paquete no trae su especificación. La fila
  `meshy_e01` de `combate_afinidades.gd` no tiene debilidades, resistencias ni inmunidades, y así se queda hasta que
  llegue la especificación. No se inventan.
- **Acceso de prueba (14/11):** en la APK de Auditoría, pantalla de carga → «Banco de pruebas (Auditoría)» →
  «Custodio de Porcelana (meshy_e01)». Usa su interruptor solo durante esa sesión y con una partida aislada.

- (18/11: hechos los cinco que quedaban, §11.) **Clips que faltan (6 de 12):** alert, turn_l, turn_r, guard (hoy la guardia usa el reposo y el tinte de defensa),
  stagger y attack_03 «Sello de Clausura» con su ataque (a3). Hechos el 14/11 por la noche: attack_02, hit_front y
  death (sección 8).
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


## 8. 14/11, noche: Avance del Portón (e01_a2), golpe y derrota

Lote de la matriz elegido por el coordinador: completar el elemento más avanzado con archivos disponibles.

- **Clips nuevos** (`fuente/p2_clips.py`, mismo método de funciones del tiempo con IK y horneado a 30 fps):
  - `e01__attack_porton` 2,7 s. Sigue las poses clave de la ficha: gira los antebrazos, postura de ariete con el peso
    atrás, arranque a 1,00, carrera en el sitio hasta 1,45 (pasos cortos), frenada en dos apoyos, guardia a 1,90 y
    reposo a 2,70. Los pies que cambian de sitio se levantan en arco.
  - `e01__hit` 0,6 s: recibir un golpe de frente.
  - `e01__death` 1,9 s: trastabilla, cae de rodillas y se vence sobre las manos; en el suelo a 1,30.
  - **Medidas de lo horneado:**
    - malla bajo el suelo como mucho 4 mm en el Avance y 11 mm en la derrota (antes de corregirla, 53 y 184 mm);
    - el Avance y la derrota empiezan en la pose del reposo, y el Avance también acaba en ella.
  - **Determinismo:** el guion sin cambios reproducía el GLB byte a byte (md5 igual), así que los tres clips anteriores
    no cambian.
  - Se trabajó sobre una copia del `.blend`: `D:\REBELUM_diagnostico\custodio_a2\trabajo\`. Las hojas de renders
    están en `D:\REBELUM_diagnostico\custodio_a2\render\` (`hoja_porton_perfil.png` y `hoja_derrota2.png`).
- **Godot:**
  - Alias del juego: `porton`, `recibir_golpe` y `derrota`. La base ya reproduce los dos últimos sola.
  - La «caida» del modelo pasa de 0,6 a 1,6 s para que se vea caer antes de desvanecerse.
- **Combate** (`combate_meshy_e01.gd`, con el mismo esquema que la Prensa):
  - Franja en el suelo desde él hasta el blanco y un poco más allá; se fija a 0,75 s.
  - Embestida durante la carrera e IMPACTO a 1,30.
  - En fila: ×1,1 al elegido y ×0,5 al de detrás.
  - Retroceso del 25 % de la barra ATB (empuje de 0,7 m frente al 15 % de 0,4 m).
  - Una vez por ejecución y objetivo; la Guardia de Garon cubre.
  - Recarga compartida: Prensa, 2 guardias, Avance, 2 guardias, Prensa…
  - **Cifras PROPUESTAS**, sin partidas reales.
- **Pruebas:**
  - `prueba_meshy_e01`: 6 clips y alias, la Prensa como antes, y luego el Avance contra Lya defendiendo. Un impacto,
    franja, golpes una vez, Lya a la mitad y sin Retroceso, Garon −25 %, y la marca borrada.
  - Regresión: `prueba_enemigos_v12`, `prueba_combate_huella` y `prueba_banco_pruebas` superadas.
  - Capturas en combate real (`fotos_meshy_e01` con «porton derrota»): `D:\REBELUM_diagnostico\custodio_a2\godot\fotos\`.
    - f_00011: la franja sobre Lya y Garon;
    - f_00020: el impacto;
    - f_00090: la derrota de rodillas.
- **Pendiente:**
  - ~~Sello de Clausura (a3)~~ (hecho el 15/11, sección 9) y los clips alert, turn y guard.
  - En combate se superpone a los héroes delanteros al embestir, como los demás enemigos cuerpo a cuerpo.
  - Sonido propio.
  - Redmi.


## 9. 15/11: Sello de Clausura (e01_a3) y los tres especiales como conjunto

Rama local `claude/v12-custodio-sello` (desde `claude/rebelum-v12` @ `723a97d`). Comprobado ejecutando en el PC el 15/11
con datos aislados; la partida real, sin cambios.

### 9.1 Clip `e01__attack_sello` (2,8 s)

- **Ficha literal** (`ataques_propuestos.json`, id `e01_a3`):
  - anticipación hasta 1,30; activo [1,30, 1,50); recupera desde 1,50; `cooldown_own_turns` 3; daño 9-13 arcano;
  - «un círculo de radio 1,3 m a máximo 5 m, fijado antes de activar»;
  - marca de cerradura desde 0,20 y centro fijo a 0,80;
  - −15 % de velocidad durante 1 turno del afectado; no silencia ni inmoviliza;
  - raíz quieta: solo torso, cabeza y brazos;
  - disco de cerradura opaco y pulso marfil.
- **Poses** (`fuente/p2_clips.py`, el mismo método de §3 y §8):
  - 0,00 reposo; 0,20 separa las manos del torso;
  - 0,45 las lleva a la llave del pecho (los dedos la enmarcan);
  - 0,95 pecho y cabeza se inclinan hacia el sello;
  - 1,30 extiende las dos palmas delante, a la altura del pecho;
  - 1,50 sostiene; 2,05 recoge; 2,80 vuelve al reposo.
  - La cadera queda en la del reposo y los pies, plantados.
- **Eventos:** `aviso` 0,20 (la marca), `fija_direccion` 0,80, `impacto` 1,30, `fin_activo` y `recupera` 1,50.
- **Método y medidas:**
  - Se trabajó sobre una copia del `.blend` en `D:\REBELUM_diagnostico\custodio_a3\trabajo\` (copiado de
    `custodio_a2\trabajo\e01_rig.blend`, md5 `7A59C4BF…`).
  - Antes de tocar nada, el guion sin cambios reprodujo el GLB byte a byte (md5 `6FD7A534…`, igual al del repositorio).
  - Tras añadir el clip, los 6 clips anteriores tienen las mismas pistas, canal a canal, con la misma malla y la misma
    piel (`D:\REBELUM_diagnostico\custodio_a3\comparar_pistas.txt`).
  - Medidas del Sello: la malla no baja del suelo (0,0 mm); pies y cadera quietos (0,0000 m en Godot); vuelve al
    reposo (0,000°); la IK llega en todos los fotogramas, sin avisos.
  - GLB: 1 210 912 bytes (antes 1 180 960).
- **Renders** (Blender, lo horneado): `D:\REBELUM_diagnostico\custodio_a3\render\hoja_sello_{perfil,frente,tres_cuartos}.png`
  (0,00 · 0,20 · 0,45 · 0,80 · 0,95 · 1,30 · 1,50 · 2,05 · 2,80).

### 9.2 Combate (`combate_meshy_e01.gd`, el esquema de `_porton()`; `combate.gd` sin tocar)

- **Centro:** el héroe vivo a ≤ 5 m con más aliados a ≤ 1,3 m (empate: el que elegiría «agresivo»). Si nadie está a
  5 m, el punto a 5 m hacia el más cercano.
  - Escala: 168 px por metro, la del propio modelo (840 px × 0,6 / 3,0 m).
  - La profundidad se aplasta ×0,32, como en las demás marcas.
- **Marca:** un disco oscuro de cerradura con el ojo de la llave y el borde marfil.
  - Aparece a 0,20 s, translúcido, sobre el centro. A 0,80 s se fija (opaco y con un pulso marfil). Ya no se mueve.
  - Va en el suelo, DEBAJO de los luchadores y de sus sombras. En la primera captura iba encima y el disco opaco tapaba
    los pies de quien estaba dentro.
- **Impacto (1,30):** golpea UNA vez a cada héroe vivo dentro del círculo en ese momento (`attack_instance_id` +
  nombre); la Guardia de Garon cubre y se lleva el golpe una vez.
  - Daño arcano: 9-13 × el multiplicador del turno. No resta la defensa física y no tiene crítico ni esquiva.
  - Defendiendo, la mitad. Cuenta como magia para el Anillo del Alba (`dano_magico_entrante`).
  - Se borra la marca y llegan otro pulso marfil, un temblor corto y el golpe de siempre (una vez).
- **Lentitud:** −15 % de la velocidad del afectado hasta que le llega su próximo turno.
  - Se guarda lo quitado y se devuelve exacto; no se acumula.
  - Si ya tenía la barra llena, cuenta la siguiente.
  - Al acabar el combate, todo vuelve.
- **Rotación de la recarga compartida:** Prensa, G, G, Avance, G, G, Sello, G, G, G, Prensa…
- **Constantes:** `SELLO_*` y `T_SELLO_*`, agrupadas y marcadas como **PROPUESTA, sin equilibrar** (daño, radio,
  alcance, reducción, turnos, recarga, tiempos y colores).

### 9.3 Pruebas

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_meshy_e01` (ampliada) | SUPERADA 3/3, mismas huellas | `D:\REBELUM_diagnostico\pruebas\2026-11-15_023714`, `_023727`, `_023738` |
| Contraprueba (radio 3,0, sin confirmar) | FALLIDA con 8 fallos («dentro» con Garon; «Garon, fuera, recibe daño») | `2026-11-15_023634` |
| Regresión: `prueba_enemigos_v12`, `prueba_combate_huella`, `prueba_banco_pruebas` (y `prueba_meshy_e01`) | 4 SUPERADAS | `2026-11-15_023503` |
| `fotos_meshy_e01 sello` (ventana) | sin errores; revisadas a ojo | `D:\REBELUM_diagnostico\custodio_a3\godot\` |

Lo que comprueba la ampliación (salida literal de la última pasada):
- M: 7 clips; alias «sello» = mismo recurso; instantes iguales en JSON, modelo y combate; Sello con pies 0.0000 m y cadera
  0.0000 m; manos a 0,45 en (±0.353, 1.236, 0.256) y palmas a 1,30 en (±0.412, 1.238, 0.497).
- E1: centro en Lya (1 aliado cerca), dentro [Kael, Lya] (calculado aparte), Kael −11 y Lya −10 una vez en el impacto;
  −15 % de velocidad y la recuperan exacta al llegarles el turno.
- E2: Lya se aparta 3 m tras fijarse el centro: el círculo no la sigue y solo golpea a Kael.
- E3: Garon cubre a Lya y Kael defiende: Kael −5 y Garon −11; Lya, nada.
- R: prensa, guardia, guardia, porton, guardia, guardia, sello, guardia, guardia, guardia, prensa.

Capturas en combate real (`indice.txt`):
- `f_00003` aviso (disco translúcido bajo Lya);
- `f_00012` y `f_00014` centro fijo (disco opaco con el ojo de la llave; Kael y Lya encima, con los pies a la vista);
- `f_00020` impacto (−11 y −10, «Lento» en los dos, pulso marfil);
- `f_00043` fin del turno.

Estudio del GLB importado junto a Kael y Garon: `estudio_sello_{045,095,130}_{frente,perfil,espalda}.png`.

### 9.4 Los tres especiales como conjunto (observado; NO es un equilibrio)

Medido con `pruebas/medir_custodio_rotacion.gd` en el combate del banco (partida BASE, nivel 12, GRUPOS[28]):
`D:\REBELUM_diagnostico\pruebas\2026-11-15_023941` y `_024008`.

- **Cifras del banco:**
  - Kael: 186 PV, defensa 9, velocidad 23. Lya: 146 PV, defensa 7, velocidad 26. Garon: 234 PV, defensa 18,
    velocidad 15. En total, **566 PV**.
  - Custodio: 161 PV, ataque 15, velocidad 10. Por cada turno suyo, **6,4 turnos de héroe**.
  - Distancias en el suelo: él a 2,50 / 3,44 / 2,72 m de Kael, Lya y Garon; Kael-Lya 0,96 m; Garon a 2,90 m de Kael.
- **Un ciclo de su rotación**, con los héroes quietos y curados antes de cada turno suyo:
  - Prensa 18 (Lya 17, Garon 1);
  - Avance 14 (Lya 13, Garon 1);
  - Sello 24 (Kael 12, Lya 12);
  - **56 en 10 turnos suyos = 9,9 % de los PV del grupo.**
  - Nunca hay dos marcas a la vez: cada una se borra al acabar su turno y entre especiales hay al menos dos turnos de
    guardia.
- **Legibilidad**, tiempo que se ve cada marca antes del golpe a 30 fps: Prensa 26 fotogramas (0,87 s), Avance 38
  (1,27 s), Sello 32 (1,07 s; su centro fijo, 0,50 s).
  - Las tres se distinguen por la forma y el color: rectángulo ámbar sobre dos, franja ámbar hacia el blanco, y disco
    oscuro con ojo de llave y borde marfil.
- **El combate del banco con los héroes atacando solos:** el grupo gana en 6 turnos de héroe. El Custodio solo llega a
  hacer una Prensa y el grupo pierde 18 PV (3,2 %). Con estas cifras, en el banco no se llega a ver la rotación entera.
- **Observaciones (no decisiones):**
  - El Sello es el especial que más daña por ejecución en esta formación, porque Kael y Lya están a menos de 1,3 m y no
    resta defensa.
  - El de detrás en la Prensa y el Avance recibe 1 de daño cuando es Garon (su defensa 18 se come el ×0,5).
  - A nivel 12 el Custodio es un enemigo corto. Para que se lea la rotación haría falta más vida (`vida` del caso del
    banco), lo que es decisión del coordinador o del usuario.

### 9.5 Pendientes

- Equilibrio de las tres cifras: sin partidas reales. Las constantes llevan «PROPUESTA».
- Sonido propio: el Sello suena con el golpe de siempre; hacen falta claves de llave girando y golpe corto.
- La nota del caso «custodio» de `banco_pruebas.gd` aún dice «Prensa del Umbral»: debería nombrar los tres especiales.
  No es un archivo de este encargo.
- Redmi: la legibilidad del disco a tamaño de teléfono y su coste (un dibujo 2D por fotograma: un círculo, dos arcos y
  el ojo).
- La «llave iluminada» de la ficha: sin máscara de UV, no se ha hecho.


## 10. 15/11, tarde: «Sello en 3» en el Redmi y el Sello no llegaba (el contador)

Rama local `claude/v12-custodio-contador` (desde `1239e78`). Comprobado ejecutando en el PC el 15/11 con datos aislados.

### 10.1 Lo observado en el Redmi (APK `cbc0536`, caso «Custodio: ver la rotación (vida ×8)»)

Vídeo `D:\REBELUM_diagnostico\redmi_15_11\rebelum_custodio_redmi.mp4` (1600 × 720, 9 036 fotogramas, unos 3 min).
Se sacó un fotograma de cada 75 con el secuenciador de Blender y se recortaron el cartel de arriba y la etiqueta del
Custodio (hojas en `D:\REBELUM_diagnostico\custodio_contador\video\`). Lo que se lee, en orden:

| Momento (fotograma ≈ s) | Cartel | Etiqueta sobre él |
|---|---|---|
| 1 500 ≈ 30 s | «alza los puños: ¡Prensa del Umbral contra Lya y Garon!» | «Congelado» → «Congelado Avance en 3» |
| ≈ 2 800 ≈ 56 s | (guardia) | «Congelado Guardia Avance en 2» |
| ≈ 3 900 ≈ 78 s | «cruza los brazos de porcelana y aguanta» | «Congelado Guardia» (sin contador) |
| ≈ 5 000 ≈ 100 s | «baja la cabeza: ¡Avance del Portón contra Lya y Ga…!» (la franja) | «Congelado Sello en 3» |
| ≈ 6 150 ≈ 123 s | «cruza los brazos de porcelana y aguanta» | «Congelado Guardia Sello en 2» |
| 6 800-9 036 ≈ 136-180 s | el menú MAGIA abierto unos 45 s, sin acciones | «Congelado Guardia Sello en 2» |

- **La rotación iba bien:** Prensa, G, G, Avance, G… El Sello tocaba dos turnos suyos después y el vídeo acaba antes.
- **Un turno suyo cada 22-24 s** a ese ritmo de juego: mientras un héroe está en su menú nadie actúa, y por cada turno
  suyo hay unos 3 de héroe.
- **Congelado todo el rato** (Frostfang congela con cada golpe de Kael): no le quita turnos ni recarga.
  `_tic_congelacion` solo cuenta las rondas y devuelve los PV máximos.
- **Lo que confundía era el contador:**
  - «Sello en 3» no decía en qué unidad (eran turnos suyos, no segundos ni turnos del grupo) y se quedaba fijo
    20-25 s.
  - En el turno anterior a cada especial (recarga 0) la etiqueta se quedaba sin contador: de «Avance en 2» se pasaba a
    nada.
  - El panel solo decía «En guardia» y no avisaba de que el siguiente era el especial.

### 10.2 Reproducción en el PC (traza por turno)

`pruebas/trazar_custodio_contador.gd` (TRAZA, no prueba). Usa el mismo caso del banco (partida BASE, nivel 12, Kael con
Frostfang, vida ×8, GRUPOS[28]) con el ATB de verdad y los héroes atacando solos. **No es la estrategia de un jugador.**
La semilla se pone tras `add_child`.
- `D:\REBELUM_diagnostico\pruebas\2026-11-15_143000` (sin esperar en los menús), con el contador de ANTES del arreglo.
  Extracto literal (etiqueta justo antes de cada turno suyo → lo que hizo):
  - `TURNO SUYO 3 … etiqueta «❄ Congelado  Guardia  Avance en 2» … recarga 1` → guardia → `etiqueta «❄ Congelado  Guardia» · panel «En guardia: golpes a la mitad hasta su próximo turno» · recarga 0 · toca porton`
  - `TURNO SUYO 4 … etiqueta «❄ Congelado  Guardia»` → **porton**: el Avance llega sin que la etiqueta ni el panel lo
    anuncien.
  - `TURNO SUYO 6` → guardia → etiqueta «❄ Congelado  Guardia»; `TURNO SUYO 7` → **sello**: igual.
  - Rotación de 11 turnos: prensa, guardia, guardia, porton, guardia, guardia, sello, guardia, guardia, guardia, prensa.
    Congelado al empezar cada turno suyo (congelado 2 → 1 en su turno; Kael lo renueva). Un turno suyo cada ~11 s de
    juego, tras 3-5 turnos de héroe.
- `D:\REBELUM_diagnostico\pruebas\2026-11-15_143406` («pensar=4»: 4 s en cada menú, como en el teléfono), ya con el
  arreglo: un turno suyo cada ~22 s y el Sello a los 164 s, el mismo ritmo que el vídeo.

**Causa:** la rotación es correcta y la congelación no le hace perder turnos. El contador contaba bien sus turnos, pero
explicaba mal lo que faltaba:
1. no decía la unidad;
2. desaparecía justo en el turno anterior al especial;
3. el panel no avisaba del especial mientras estaba en guardia.

Con un turno suyo cada ~22 s, «Sello en 3» se leía como «atascado».

### 10.3 Lo cambiado (solo el texto; la rotación y las cifras, sin tocar)

`combate_meshy_e01.gd`, `estados()` (la etiqueta) e `info()` (el panel), con `turnos_para_especial()`, `nombre_corto()`
y `nombre_largo()`:
- **Faltan N ≥ 2 turnos suyos:** etiqueta «Sello en 3 turnos suyos». Panel «Sello de Clausura en 3 turnos suyos (antes,
  2 de guardia)».
- **Es su próximo turno:** etiqueta «⚠ Sello: su próximo turno». Panel «⚠ Su próximo turno: Sello de Clausura, …».
  También al principio del combate («⚠ Prensa: su próximo turno»).
- **En guardia:** «Guardia» delante en la etiqueta y «En guardia: golpes a la mitad» delante en el panel, sin quitar el
  contador.
- Un turno que no juega (por ejemplo, la Prisión de la magia negra de Nix) no cuenta como guardia: el contador sigue
  igual. Así ya era antes. Son turnos que juega él.

### 10.4 Pruebas

- `prueba_meshy_e01`, sección K nueva:
  - K1: los textos de las 24 combinaciones (recarga 0-3 × especial que toca × guardia).
  - K2: el caso del banco ×8 con el ATB de verdad y Kael congelándolo. Once turnos suyos con la rotación entera (los
    tres especiales); en CADA turno, la etiqueta y el panel de justo antes dicen cuántos turnos suyos faltaban de verdad
    para el especial que llegó.
  - Salida: `K2 TRAZA: 1 prensa «❄ Congelado  ⚠ Prensa: su próximo turno» | 2 guardia «❄ Congelado  Avance en 3 turnos
    suyos» | 3 guardia «❄ Congelado  Guardia  Avance en 2 turnos suyos» | 4 porton «❄ Congelado  Guardia  ⚠ Avance: su
    próximo turno» | … | 7 sello «❄ Congelado  Guardia  ⚠ Sello: su próximo turno» | …`
- **Contraprueba:** con `estados()` e `info()` de antes, la misma prueba sale FALLIDA con 66 fallos
  (`2026-11-15_143324`), entre ellos «K2: turno 4 (porton): la etiqueta decía «❄ Congelado  Guardia»». Con el arreglo,
  SUPERADA.
- El resto de resultados está en el informe del agente de combate (`docs/memory/agents/combate.md`, 15/11).

### 10.5 Pendiente para el Redmi

- Comprobar que «Sello en 3 turnos suyos» y «⚠ Sello: su próximo turno» caben y se leen sobre su cabeza a tamaño de
  teléfono (en el PC caben; el panel de abajo a la derecha se cortaba ya antes por el borde de la pantalla).
- Para ver el Sello en el caso ×8: unos 7 turnos suyos (≈ 2,5-3 min a ritmo de menú). Si el menú se queda abierto, él no
  actúa.


## 11. 18/11, noche: los cinco clips que faltaban (alert, turn_l, turn_r, guard y stagger)

Rama `claude/rebelum-v12` (desde `ca8f96b`), copia `D:\Aethelgard_v12`. Comprobado ejecutando en el PC el 18/11 con datos
aislados; la partida real y la carpeta real de datos, sin cambios en todas las pasadas. **Sigue APAGADO** (interruptor
`meshy_e01`, grupos 28 y 29): los ganchos nuevos solo actúan sobre el nodo del Custodio.

### 11.1 Fuente y método

- Lista del paquete (`ataques_propuestos.json`, `enemies[e01].clips` y el PDF, «Lista explícita de clips propuestos»):
  `idle, alert, walk, turn_l, turn_r, guard, hit_front, stagger, death, attack_01-03`. El paquete no da tiempos ni poses
  para estos cinco; solo la ficha de movimiento: «paso pesado con apoyo de toda la planta, contrapeso corto de hombros
  y giros en dos pasos. No deslizar los pies ni doblar el casco», y que los impactos y recuperaciones no son bucles.
- `fuente/p2_clips.py`, el mismo método (funciones del tiempo con IK de autoría, horneado a 30 fps, 24 huesos). Los cinco
  van AL FINAL de `CLIPS`; los siete anteriores no se tocan.
- Se trabajó sobre una COPIA: `D:\REBELUM_diagnostico\custodio_clips_18_11\trabajo\e01_rig.blend` (copiado de
  `D:\REBELUM_entrada_13_11\custodio_trabajo\e01_rig.blend`, md5 `7a59c4bf…`, el mismo que usaron §8 y §9). El guion
  escribe al lado `e01_autoria.blend` y `e01_exportar.blend` (en esa carpeta; los originales del usuario, intactos).
- **Determinismo antes de tocar nada:** el guion sin cambios reprodujo el GLB del repositorio byte a byte (md5
  `89db157f…` = `89db157f…`, 1 210 912 bytes; `glb_antes\`).

| Clip | Duración | Bucle | Qué hace | Eventos |
|---|---|---|---|---|
| `e01__alert` | 1,6 s | no | ve a los héroes: se yergue con la cabeza alta (0,22), baja el peso y alza las manos delante (0,60), aguanta y vuelve al reposo (1,60). Pies plantados | `alerta` 0,22 · `listo` 0,60 |
| `e01__guard` | 2,0 s | sí | antebrazos alzados delante del pecho, muñecas hacia el centro sin tocarse (a la altura de la barbilla para que se vean los ojos), peso bajo; respira 1,5 cm | — |
| `e01__stagger` | 1,2 s | no | sacudida atrás con los brazos abiertos (0,10), un paso atrás con el pie derecho [0,06, 0,36] (0,20 m, en arco), se recompone (0,70), vuelve el pie [0,72, 1,05] y el reposo (1,20) | `sacudida` 0,10 · `paso_atras` 0,36 · `recompone` 0,70 |
| `e01__turn_l` / `e01__turn_r` | 1,0 s | no | giro en DOS PASOS en el sitio: cabeza y pecho se adelantan hacia el lado; el pie de ese lado se levanta [0,05, 0,42] con el peso en el otro, luego el otro [0,45, 0,85]; cada pie se posa donde estaba. La raíz no gira: gira el nodo (ver 11.3). Son espejo exacto | `paso_1` 0,05 · `apoyo_1` 0,42 · `paso_2` 0,45 · `apoyo_2` 0,85 |

Segundo intento (uno): en la primera pasada la guardia tapaba los ojos con las manos (`hoja_guard.png` de la v1, rehecha);
se bajaron las muñecas 10 cm (`blender_p2_v2.log`).

### 11.2 Medidas (Blender, lo horneado; `blender_p2_v2.log`, literal)

```
MEDIDA e01__alert {"min_z_malla": -0.0, "min_z_manos": 0.5495, "cadera_baja_max_m": 0.1, "pie_desliz_max_m": 0.0004, "pie_z_apoyo_max_m": 0.0, "cadera_baja_pct_altura": 5.4, "fin_vs_reposo_grados": 0.0, "inicio_vs_reposo_grados": 0.0}
MEDIDA e01__guard {"min_z_malla": -0.0, "min_z_manos": 1.1831, "cadera_baja_max_m": 0.1, "pie_desliz_max_m": 0.0001, "pie_z_apoyo_max_m": 0.0, "cadera_baja_pct_altura": 5.4, "salto_bucle_grados": 0.0}
MEDIDA e01__stagger {"min_z_malla": -0.0001, "min_z_manos": 0.5495, "cadera_baja_max_m": 0.1299, "pie_desliz_max_m": 0.2073, "pie_z_apoyo_max_m": 0.0, "cadera_baja_pct_altura": 7.0, "fin_vs_reposo_grados": 0.0, "inicio_vs_reposo_grados": 0.0}
MEDIDA e01__turn_l {"min_z_malla": -0.0, "min_z_manos": 0.5495, "cadera_baja_max_m": 0.045, "pie_desliz_max_m": 0.0799, "pie_z_apoyo_max_m": 0.0, "cadera_baja_pct_altura": 2.4, "fin_vs_reposo_grados": 0.0, "inicio_vs_reposo_grados": 0.0}
MEDIDA e01__turn_r (igual que turn_l)
```

- La malla no baja del suelo (≤ 0,1 mm); todos empiezan y acaban en la pose del reposo (0,000°); el bucle de la guardia
  cierra (0,000°).
- `pie_desliz_max_m` del tambaleo (0,207 m) y de los giros (0,080 m) es el pie que SE LEVANTA a propósito (paso atrás y
  pasos en el sitio), no un deslizamiento en apoyo **dentro de Blender**; en la alerta y la guardia, 0,4 y 0,1 mm.
  - (Revisión del 19/11) En Godot el giro lo hace el nodo entero durante el clip (`mirar` con la duración del clip),
    así que el pie apoyado SÍ barre el suelo con el modelo mientras gira (p. ej. 149° en 1 s al volver de la Prensa).
    Esa medida no puede verlo. Limitación conocida, sin medir en pantalla: mirarla en el Redmi. Arreglos posibles:
    llevar el giro a la raíz en Blender y compensarlo en `mirar`, o girar el nodo solo en las ventanas de paso.
- Avisos de IK: los 25 de siempre (24 de la Prensa, documentados en §3, y 1 del Avance); **ninguno en los clips nuevos**.
- GLB nuevo: 1 333 708 bytes (antes 1 210 912), md5 `93f040ec…`.

### 11.3 Los siete clips anteriores, idénticos (comprobado)

`fuente/comparar_glb.py` (nuevo: compara dos GLB canal a canal sin Blender ni Godot). Salida literal
(`D:\REBELUM_diagnostico\custodio_clips_18_11\comparar_pistas.txt`):

```
e01__attack_porton     2.7000 s -> 2.7000 s  pistas 72/72 iguales IGUAL
e01__attack_prensa     2.4000 s -> 2.4000 s  pistas 72/72 iguales IGUAL
e01__attack_sello      2.8000 s -> 2.8000 s  pistas 72/72 iguales IGUAL
e01__death             1.9000 s -> 1.9000 s  pistas 72/72 iguales IGUAL
e01__hit               0.6000 s -> 0.6000 s  pistas 72/72 iguales IGUAL
e01__idle              2.4000 s -> 2.4000 s  pistas 72/72 iguales IGUAL
e01__walk              1.2000 s -> 1.2000 s  pistas 72/72 iguales IGUAL
NUEVO  e01__alert             1.6000 s  72 pistas
NUEVO  e01__guard             2.0000 s  72 pistas
NUEVO  e01__stagger           1.2000 s  72 pistas
NUEVO  e01__turn_l            1.0000 s  72 pistas
NUEVO  e01__turn_r            1.0000 s  72 pistas
MALLA IGUAL · PIEL IGUAL
RESULTADO IGUALES (los clips anteriores, la malla y la piel)
```

**Para volver atrás:** `enemigos/meshy_e01/anterior_18_11/` (con `.gdignore`, como `personajes/nix/fbx/anterior_14_11b/`)
guarda el GLB y el JSON anteriores (md5 `89db157f…`). Copiarlos encima de los de `meshy_e01/` y reimportar; el código
nuevo funciona igual sin los clips (cae en el reposo y el golpe de siempre).

### 11.4 Ganchos (solo presentación; `combate.gd` sin tocar)

- **alert → entrada:** alias `entrada` = `e01__alert`. `combate.gd` ya llama a `pe.entrada()` al empezar el combate; la
  base lo reproduce y vuelve al reposo. Sin sonido propio (`meshy_e01_entrada` sigue sin existir).
- **guard → Guardia:** `combate_meshy_e01._guardia()` llama a `_pose_guardia(c, f, true)` → `meshy_e01_3d.guardia(true)`: mientras
  dure, `reposo()` pone el clip `guardia` (bucle) en vez del reposo; el tinte y `defendiendo` los sigue poniendo el combate
  como antes. Al empezar su turno siguiente (`turno()`, donde ya se quitaba la guardia) → `guardia(false)`.
- **stagger → golpe fuerte o ruptura:** `combate_meshy_e01.vigilar()` (lo llama `_vigilar_carga` con cada golpe) pone
  `golpe_pesado` en el nodo si el golpe es ≥ 12 % de su vida (`GOLPE_PESADO`, el umbral del Peón y del Gólem) o si es la
  Quiebra (`golpe_ruptura`). `recibir_golpe()` pone entonces `tambaleo`; si no, el golpe de siempre. No corta un ataque,
  la entrada ni la derrota; tras el tambaleo vuelve a la guardia si la tenía.
- **turn_l / turn_r → giros:** sí hay giros. El Custodio se gira con `mirar()` (un Tween del pivote) en sus idas y
  vueltas: hacia el blanco (≈ 31°, pequeño), media vuelta tras el ataque (180°) y de vuelta al frente al llegar (≈ 149°).
  `meshy_e01_3d.mirar()`: si el giro es ≥ 60° y está quieto o andando (`reposo`, `guardia`, `caminar`, `correr`), pone
  `girar_izq` (positivo, a su izquierda) o `girar_der` y el nodo gira DURANTE el clip (1,0 s en vez de 0,3 s; es solo el
  Tween del modelo, el combate no lo espera). `andar()`/`correr()` lo cortan (el nodo acaba su giro al ritmo pedido), así
  que la media vuelta antes de volver andando sigue como antes; **el giro en pasos se ve al llegar y volverse al frente**
  (el `reposo()` que pide el combate espera al final del giro).
- Ni fórmulas, ni turnos, ni recargas, ni daño cambian (lo comprueba la prueba N y lo confirman la medida y la traza de
  abajo, con las mismas cifras que el 15/11).

### 11.5 Pruebas (salidas literales)

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_meshy_e01` (ampliada: M con 12 clips y sección N nueva) | SUPERADA (10,9 s), `FALLOS: 0` | `D:\REBELUM_diagnostico\pruebas\2026-11-18_235530\resumen.md` |
| `prueba_enemigos_v12` | SUPERADA (9,1 s) | `2026-11-18_235606` |
| `prueba_banco_pruebas` | SUPERADA (21,1 s) | `2026-11-18_235606` |
| `medir_custodio_rotacion` (medida) | SUPERADA (5,1 s): `CICLO: 10 turnos suyos, daño 56 = 9.9 % de los PV del grupo ({ "prensa": 18, "porton": 14, "sello": 24 }); marcas a la vez como mucho: 1` (= §9.4) | `2026-11-18_235606` |
| `trazar_custodio_contador` (traza) | SUPERADA (6,6 s): `FIN TRAZA: 11 turnos suyos, contador { "prensa": 2, "retroceso": 3, "guardia": 7, "porton": 1, "sello": 1, "lentitud": 2, "lentitud_fin": 2 }, PV 700/1272, 140.4 s de juego` | `2026-11-18_235653` |
| `fotos_meshy_e01 clips1811 solo_estudio` (ventana) | MANUAL, «terminó sin errores; 73 captura(s)», revisadas a ojo | `2026-11-18_235748`; copia en `D:\REBELUM_diagnostico\custodio_clips_18_11\godot\` |

Una primera pasada de `prueba_meshy_e01` (`2026-11-18_235516`) FALLÓ por un error de tipos de la propia prueba
(`Cannot infer the type of "meta"`); corregido en la prueba, no en el juego.

Salida literal de la sección N:
`N: 12 clips; entrada 1.60 s, guardia 2.00 s (bucle), tambaleo 1.20 s, girar_izq 1.00 s, girar_der 1.00 s; alerta -> reposo; guardia en lugar del reposo y fuera al acabar; tambaleo con golpe fuerte (>= 12 %) o Quiebra y de vuelta a la guardia; giros >= 60° en pasos (girar_izq/der; el nodo gira durante el clip; andar lo corta); en combate: alerta al empezar, guardia en su turno de guardia y fuera en el siguiente, vuelta de la Prensa con guardia/caminar/ataque/girar_izq; vigilar no toca vida, recarga, ATB ni guardia`

Avisos al salir de Godot («N resources still in use», «ObjectDB instances were leaked»): ya salían antes en esta prueba
(p. ej. `2026-11-18_132217`: 20 y 6); no son de este cambio.

Capturas (revisadas a ojo):
- Blender, lo horneado: `D:\REBELUM_diagnostico\custodio_clips_18_11\hoja_{alert,guard,stagger,turn_l,turn_r}.png`
  (frente, perfil, tres cuartos y espalda; renders sueltos en `render\`).
- Godot (GLB importado, Compatibility, junto a Kael y Garon): `godot\estudio_{entrada,guardia,tambaleo,girar_izq,girar_der}_<t>_<vista>.png`
  y la hoja `godot\hoja_godot_clips_nuevos.png`.

### 11.6 Matriz (actualizada)

| Puerta | Estado |
|---|---|
| Clips presentes / esperados | **12 / 12** (verificado en el PC: nombres y duraciones en Godot, prueba M y N) |
| Integración Godot | verificado (PC, APAGADA) |
| Android (Redmi) | pendiente: implementado y apagado, sin ver en el teléfono |

### 11.7 Lo que queda y lo que necesita decisión

- **Redmi:** ver los cinco clips en el teléfono (caso «Custodio» del banco de Auditoría): la alerta al empezar, la guardia
  durante sus turnos de guardia, el giro en pasos al volver a su sitio y el tambaleo con un golpe fuerte (Quiebra). GLB
  +123 KB; sin medir el rendimiento.
- **Decisión (usuario/coordinador):** la ficha del paquete dice «Stagger en anticipación cancela el especial y borra
  marcas». Aquí el tambaleo es SOLO la animación: no corta la Prensa, el Avance ni el Sello (la regla de §4, «la Prensa no
  se corta con daño», sigue). Cambiarlo es una regla de combate nueva.
- **Giros:** el nodo gira mientras los pies dan los dos pasos; el pie apoyado gira con el nodo (no se puede evitar sin
  raíz que gire en el clip). Se lee como dos pasos, pero no es un apoyo perfecto. La media vuelta antes de volver andando
  sigue sin pasos (el combate pone a andar en el mismo fotograma).
- **Guardia:** al recibir un golpe pequeño en guardia pone el golpe de siempre y vuelve a la guardia (no hay clip de
  «bloqueo»; el paquete no lo pide).
- Sonido propio de la alerta y del tambaleo: sin claves (como en §7).
