# Nix desde el FBX del usuario: piloto (V12, 14/11/2026) — APAGADO

Fase 5 del encargo coordinador (`docs/v12/encargos/ENCARGO_COORDINADOR_13_11.md`, apartados 5 y 6). Se aprovecha el
FBX recibido (Meshy «Silver Sentinel» = Nix «base lisa»): **no se reconstruye ni se cambia su rostro**. Rama local
`claude/v12-nix-piloto` (desde `claude/rebelum-v12` @ `710fdae`), sin subir.

**Interruptor:** `nix_fbx` (`aethelgard/personajes/nix/fbx/nix_fbx.gd`), APAGADO. Solo cuenta con el de Nix
(`nix_v12`, también apagado). Se enciende con `Engine.set_meta("nix_fbx", true)` o `-- nix_fbx`. Apagado,
`nix_3d.gd` carga su `nix.glb` de siempre: lo que hoy se ve no cambia.

## 1. Fuente (sin modificar)

`D:\REBELUM_entrada_13_11\extraido\Meshy_AI_Silver_Sentinel_20261113_texture_fbx\…\` (FBX de 24 MB y cuatro texturas
de 2048). Se trabajó sobre una copia en `D:\REBELUM_entrada_13_11\nix_trabajo\fuente_copia\`.

Inspección (comprobado con Blender 5.2, `p0_inspeccionar.py`): **una sola malla cerrada y conexa** (218.063
vértices, 436.194 triángulos, 0 bordes abiertos), 1 material, 1 UV de Meshy (21.722 aristas de costura),
1,90 m en T con los pies en z = −0,951, mira a −Y. El 66 % de los triángulos está en la cabeza y el pelo (z > 0,4 en
coordenadas del FBX). El pelo, los mechones y el cuerpo están **soldados** en una sola pieza (los mechones delanteros
también al pecho: ver §3). Mapa de metal casi negro (media 0,005; máximo 0,51 en zonas pequeñas): se usa metal 0.

## 2. Malla reducida y textura (paso 1) — verificado en render

| | Original | Piloto |
|---|---|---|
| Triángulos | 436.194 | **11.968** (5.950 vértices) |
| Materiales | 1 | 1 (`nix_cuerpo`) |
| Texturas | 2048 color / metal / normal / rugosidad | rehorneadas a 2048 (color, normal, rugosidad); **1024 en el GLB** |
| Bordes abiertos | 0 | 0 tras reducir (los mechones se despegan después, §3) |

- **Reducción:** `Decimate` por colapso con un grupo de vértices que frena la reducción en la cara (peso 0,8 en la
  cara y el flequillo, 1 en el resto, factor 1). Hallado probando: los vértices **sin** peso en el grupo no se reducen
  nunca (con solo la cara en el grupo se quedaba en 418.196; con todo el pelo, en 161.650). Sin grupo, la cara perdía
  la nariz y la boca (render `cmp_cara_pesos.png`).
- **UV de Meshy conservadas** por el colapso; con la textura original sobre la malla baja la textura «resbalaba» en
  los triángulos grandes (costuras del mono onduladas, sombra en la barbilla). **Rehorneado** con Cycles (GPU) de la
  malla alta a la baja en las mismas UV: color difuso, normal en espacio tangente (incluye el relieve de la alta y su
  mapa normal) y rugosidad. Resultado casi idéntico al original en cara, ojos, pelo y mechones.
- Defecto menor visible de cerca: unos texeles oscuros en la línea mandíbula–cuello (el rayo del horneado toca el
  cuello por debajo). No se ve a la distancia del combate.
- **1024 frente a 2048:** el GLB del juego lleva 1024 (presupuesto del PDF: atlas 1024²). Las de 2048 están en
  `D:\REBELUM_diagnostico\v12\expansion\nix\piloto_fbx\texturas_2048\` para un perfil de PC sin rehacer nada.
  **Pendiente:** comparación 1024/2048 a la distancia del combate en el PC y en el Redmi.

Capturas (frente, perfil, espalda, tres cuartos y cara; antes y después):
`D:\REBELUM_diagnostico\v12\expansion\nix\piloto_fbx\render\cmp_p2.png`, `cmp_p2_cara.png`, `cmp_cara_pesos.png`,
`render\p1\antes_*.png`, `render\p2\horneada_2048_*.png`.

## 3. Esqueleto y pesos (paso 2) — verificado en render con poses de prueba

- **Esqueleto común de los héroes v2:** el de Lya (FBX del juego, solo la armadura: nombres `mixamorig:`, jerarquía
  y giros) **re-situado** en las articulaciones medidas en la malla de Nix (`p3_medir.py`: secciones de piernas,
  brazos y tronco) conservando el giro de cada hueso (`align_roll` con su eje Z anterior). Así valen la biblioteca de
  clips por IK (`rig_comun.py`, `biblioteca_clips.py`), los clips de Nix (`fuente/crear_nix_clips.py`) y la captura de
  andar y correr de Lya. Ningún archivo de esas bibliotecas se ha tocado.
- Se quitan los huesos propios de Lya (pelo de detrás `Bone_017/018`, faldón `Bone_005…008`, `headfront` y las puntas
  `Bone_040/041`). Se añaden **`mechon_i_1/2`, `mechon_d_1/2`** (los dos delanteros, hijos del cuello) y
  **`mechon_sup_1/2`** (el superior, hijo de la cabeza), y el socket **`arma_d`** (no deforma).
- **48 huesos, 36 deforman** (35 con pesos: `RightHandMiddle1` se quedó sin vértices por el calor; la mano derecha usa
  `RightHandMiddle2`). Presupuesto del PDF: 24-40. **4 pesos por vértice como mucho, normalizados** (0 vértices mal,
  0 sin peso).
- **Pesos:** calor de Blender (`ARMATURE_AUTO`) en el cuerpo; luego, por zonas:
  - pelo (detectado por el color horneado: claro y poco saturado; 3.865 vértices) → cabeza al 100 %;
  - cara y cuello (no pelo, z > 1,53 m) → cabeza, con una franja cuello→cabeza entre 1,555 y 1,60 m. Antes, al girar
    la cabeza la mandíbula se quedaba en el cuello y la cara se rasgaba (render `p5`, corregido en `p5d`);
  - mechones delanteros: raíz anclada (rígida con la cabeza hasta 1,60 m), degradado `_1` → `_2` hacia la punta;
  - mechón superior: por encima de 1,842 m, `mechon_sup_1` → `_2`.
- **Mechones despegados del pecho:** en la malla de Meshy los mechones estaban soldados al mono; al levantarlos
  arrastraban triángulos del pecho («aletas» oscuras). Ahora las caras del mechón (los tres vértices de pelo) se
  separan del mono y de la piel con `split_edges` (181 aristas) y solo siguen unidas al pelo de la cabeza.
  Queda: al levantarlos se ve en el pecho una franja clara donde apoyaban (restos de textura de pelo del mono).
- Poses de prueba (`p5_revisar.py`, `rig_estres`): brazos arriba y abajo (axilas y hombros), codos y rodillas muy
  doblados, sentadilla, cabeza girada 35° y bajada 15°, manos cerradas, mechones levantados. **Bien** a la distancia
  del juego; de cerca, el hombro con el brazo arriba aplana algo el deltoides (calor sin corrección).

Capturas: `render\p4\rig_T_*.png`, `rig_estres_*.png`, `render\p5d\hoja_revisar.png` y sus vistas.

## 4. Clips (paso 4 parcial) — verificado en render

23 clips en el GLB (`personajes/nix/fbx/nix_fbx_clips.json`, el contrato de `nix_3d.gd`):
- **Captura de Lya:** `andar` y `correr` (la cadera escalada ×1,153 a las piernas de Nix).
- **Los de Nix por IK** (`crear_nix_clips.py` con la biblioteca común, sin tocarlos): reposo, guardia, hablar,
  hablar_b, asentir, interactuar, saltar, girar, ataque, recibir_golpe, derribo, derrota, levantarse, victoria,
  magia_lanzar (P01), magia_estado (P02), magia_culminante (P07), defender, defensa.
- **`magia_concentrar`** rehecho para proporciones adultas (la mano libre de la Nix chibi le tapaba la cara: ahora
  ante el pecho; solo en este piloto) y con los mechones **arriba ondulando**, desfasados, en un bucle que cierra.
- **Nuevo `canalizar` (0,9 s):** de la guardia a la concentración; los mechones delanteros suben **con retraso** (la
  raíz a 0,10/0,14 s, la punta a 0,28/0,33 s) y el superior responde después (0,22/0,38 s); evento
  `mechones_arriba` a 0,75 s. `nix_3d.gd concentrar()` (solo con el interruptor) pone `canalizar` y enlaza el bucle.
- No es el mismo clip renombrado: cada uno es una secuencia distinta de poses.
- Con proporciones adultas, varios clips de Nix pensados para la versión chibi con bastón deberían reajustarse (el
  andar de Lya cruza algo los pies; la derrota de rodillas y la victoria se ven bien). Ver la hoja
  `render\p4\hoja_clips_34.png` y `render\p6\hoja_canalizar.png`.

## 5. Integración en Godot (paso 3) — comprobada en el PC (§7)

- `aethelgard/personajes/nix/fbx/`: `nix_fbx.glb` (2,37 MB: malla, 48 huesos, 23 clips, texturas WebP de 1024),
  `nix_fbx_clips.json`, `nix_fbx.gd` (interruptor y rutas) y `fuente_blender/` (guiones, con `.gdignore`).
- `aethelgard/personajes/nix/nix_3d.gd`: con el interruptor, carga el GLB y el JSON nuevos; el cetro va por socket en
  `arma_d` (el arma equipada de Nix o, si no tiene, la malla del «Cetro del Loto Lunar» solo como aspecto provisional;
  no se equipa ni da estadísticas); la magia sale de la punta del cetro; sin LOD manuales (`visibility_range` de los
  tres cuerpos de la Nix de siempre no se aplica: el importador genera LOD); `concentrar()` empieza por `canalizar`.
  Velocidades de andar y correr 1,55 y 5,4 m/s **sin medir**. Apagado: idéntico a antes.
- Pruebas nuevas: `pruebas/prueba_nix_fbx.gd` (auto) y `pruebas/fotos_nix_fbx.gd` (ventana), en `lista_pruebas.txt`;
  sondas de diagnóstico `pruebas/herramientas/sonda_material_nix_fbx.gd` y `sonda_brillo_nix_fbx.gd`.
- Las tres texturas que el importador extrae del GLB (`nix_fbx_nix_*_1024.webp`) van **comprimidas en VRAM**
  (S3TC en PC, ETC2/ASTC en Android) con mipmaps y el relieve marcado como mapa normal: con el importador por
  defecto quedaban sin comprimir (RGBA8, 4 MB cada una) hasta que el editor las detectara en 3D.

## 6. Lo que falta (vestuario canónico y más)

No se hizo en esta sesión (registrado con precisión para el siguiente paso):
- **Ropa como piezas separadas** sobre este cuerpo y este esqueleto: capucha amplia con forro púrpura (sin sombrero),
  capa corta, faldones abiertos con interior púrpura y bordados dorados, medias asimétricas (ramas/hojas en una,
  geometría en la otra), guantes y calzado, emblema dorado en la espalda (Ojo de Horus en estrella de seis puntas de
  dos triángulos). El cuerpo está bajo el mono liso; las prendas deben ir encima con sus propios huesos (faldones y
  capucha) y pesos copiados del cuerpo.
- **Cetro canónico** independiente (malla propia) en el socket `arma_d`.
- **Huesos de faldones** y su oscilación desfasada en la canalización; **emisión separada** de iris y ornamentos con
  intensidades básica, fuerte y suprema; limpieza del viento y la emisión en interrupción, muerte, pausa y fin de
  combate (hoy el viento es un clip: al salir del clip vuelve solo; probado volver a la guardia).
- Retoque de los clips de la Nix chibi a proporciones adultas; medir `vel_andar`/`vel_correr` con
  `prueba_anim_pies.gd`; cara expresiva (parpadeo y expresiones: el FBX no tiene párpados ni boca separados; la cara
  es textura); retrato de diálogo.
- La franja clara del pecho bajo los mechones; los texeles de la mandíbula; `RightHandMiddle1` sin pesos.
- Escala: el PDF da 1,18 m; el juego normaliza a 1,7 m por los huesos (como a los demás héroes). Decidir la altura
  de Nix junto al grupo.

## 7. Pruebas y evidencias (14/11, PC; todas con datos aislados por `ejecutar_pruebas.ps1`)

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_nix_fbx` (auto) | **SUPERADA**, 35 comprobaciones, 0 fallos | `D:\REBELUM_diagnostico\pruebas\2026-11-14_021258\resumen.md` |
| `prueba_nix_v12` (la de siempre, interruptor FBX apagado) | **SUPERADA** | mismo resumen |
| `prueba_nix_v12` con `-- nix_fbx` (combate real Kael, Lya y Nix FBX) | FALLIDA con **2 fallos esperados**: comprueba el LOD manual y el bastón dentro del modelo de la Nix de siempre. El resto pasa: Ascuas, Aguja con Lento, sellos hasta 3, Colapso preparado y suelto sobre todos, defensa, golpe, victoria y, sin interruptor, el combate de siempre | `D:\REBELUM_diagnostico\pruebas\2026-11-14_021326\resumen.md` |
| `fotos_nix_fbx` (ventana) | MANUAL, 11 capturas revisadas | `D:\REBELUM_diagnostico\pruebas\2026-11-14_021357\resumen.md` |
| sondas de material y brillo | SUPERADA / MANUAL | `…\2026-11-14_020913\` y `…\2026-11-14_021030\` |

En todas: partida.save real y carpeta real de datos **sin cambios**; había otros Godot abiertos de otras copias
(anotados en cada resumen).

**Visto en las capturas de Godot** (`D:\REBELUM_diagnostico\v12\expansion\nix\piloto_fbx\godot\`):
- Carga, se normaliza a la altura de los héroes, el cetro sigue al socket, los clips se reproducen y la canalización
  levanta los mechones con retraso.
- **Con la luz de frente de la foto el mono y el pelo se ven muy claros** (mono gris claro, pelo casi blanco).
  Causa medida: no es la exportación (la media de la textura dentro del GLB es la misma que la horneada: 0,4526
  frente a 0,4523; `p7_medir_glb_textura.py`) ni el mapa normal (la sonda con y sin relieve da lo mismo): el albedo
  del FBX es gris medio (≈ 0,45) y el pelo casi blanco (≈ 0,8); con luz lateral (sonda) el mono se ve gris oscuro, y
  Lya v2 con la misma luz también queda muy clara. **Pendiente de ver en los escenarios reales y en el Redmi**; la
  ropa canónica (negro y púrpura) cubrirá el mono; para el pelo, si hiciera falta, un tono en el material, no en la
  textura.
- El cetro provisional (el de Lya) se ve grande en Nix, igual que en Lya.

**Evidencias (fuera del repositorio):** `D:\REBELUM_diagnostico\v12\expansion\nix\piloto_fbx\` con `blend\`
(`p1_cara0.8.blend` reducción, `p2_horneada.blend` alta y baja con el horneado, `p4_rig.blend` esqueleto, pesos y
clips), `texturas_2048\`, `texturas_1024\`, `nix_fbx.glb`, `render\` (Blender: antes/después, poses de prueba, clips,
canalización) y `godot\`. Carpeta de trabajo con la copia del FBX y los guiones: `D:\REBELUM_entrada_13_11\nix_trabajo\`.

**Cómo se rehace** (Blender 5.2, guiones en `aethelgard/personajes/nix/fbx/fuente_blender/`):
1. `p1_reducir.py -- <fbx copia> <render> <blend1> 12000` con `NIX_FACTOR=1 NIX_PESO_CARA=0.8`;
2. `p2_hornear.py -- <blend1> <texturas> <render> <blend2> 2048`;
3. `p4_rig.py -- <blend2> <FBX de Lya del juego> <raíz aethelgard> <render> <blend3> <glb> <json> 1024`
   (unos 2 min sin renders); luego copiar GLB y JSON a `personajes/nix/fbx/` e importar.

**No medido:** rendimiento (ni en el PC ni en Android: el encargo pide medir sin otra carga y había otros Godot
trabajando), memoria, coste del material.

## 8. Matriz

| Elemento | Estado |
|---|---|
| Diseño (canon vigente) | parcial: cuerpo, cara, pelo y mechones del FBX; ropa pendiente |
| Modelo (malla reducida + texturas) | verificado en render (Blender) |
| Rig (esqueleto común + mechones, pesos) | verificado en render con poses de prueba |
| Animación (23 clips, canalización) | parcial: verificada en render; reajuste adulto pendiente |
| Integración (GLB en Godot, interruptor apagado) | verificado en el PC: prueba_nix_fbx y combate real con el interruptor; apagado, la Nix de siempre |
| Combate / equipo | parcial: hechizos piloto, defensa, golpe, victoria, derrota y revivir con el modelo FBX; cetro provisional por socket |
| Guardado | sin cambios (el interruptor no se guarda; el modelo no toca la partida) |
| PC | verificado funcional (capturas); rendimiento sin medir |
| Android (Redmi) | pendiente: no se ha medido ni instalado nada |
