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
- La franja clara del pecho bajo los mechones; los texeles de la mandíbula; `RightHandMiddle1` sin pesos. **15/11: arreglado** (la mano del cetro cierra los dedos; ver `REVISION_PERSONAJES_15_11.md` §3).
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

## 9. Vestuario canónico (segunda pasada, 14/11/2026 04:30) — sigue APAGADO tras `nix_fbx`

Rama local `claude/v12-nix-vestuario` (desde `claude/rebelum-v12` @ `80ac41a`), sin subir. Canon aplicado: encargo
§5-6 e `INSTRUCCIONES_COMPLEMENTARIAS_14_11.md`, con las referencias `Nix_TPose_Vestida_Frente/Perfil/Espalda_Emblema`.
**Rostro e identidad sin tocar** (cara, ojos, flequillo, mechón superior y los dos delanteros son los del FBX).

### 9.1 Qué se hizo (guiones en `personajes/nix/fbx/fuente_blender/`)

- `p8_vestuario.py` (parte de `p4_rig.blend`), `p8_pintura.py` (rasterizar UV e interpolar por texel) y
  `p8_dibujos.py` (los dibujos, en metros del cuerpo); `p9_cetro.py` (el cetro). Todo por guion, rehacible:
  `blender -b -P p8_vestuario.py -- <p4_rig.blend> <texturas> <render> <blend salida> <glb salida>` (≈ 1 min con renders)
  y `blender -b --factory-startup -P p9_cetro.py -- <glb> <render>`. Después: copiar los GLB a `personajes/nix/fbx/` e
  importar (las texturas nuevas que extrae el importador se ponen en VRAM comprimida en su `.import`).
- **Ropa como piezas separadas, en UNA malla aparte `ropa_nix` con UN material `nix_ropa`** (atlas de 1024: color y
  metal/rugosidad, comprimidos en VRAM). El cuerpo sigue entero debajo (no es una carcasa vacía). Dos tipos de pieza:
  - **ceñidas**: copias de caras del cuerpo desplazadas por la normal (heredan sus pesos: no atraviesan al doblarse) y
    cortadas con planos para que los bordes visibles sean rectos: corpiño (6,5 mm), mangas (4 mm, hasta la muñeca),
    medias (3,5 mm), botas (8,5-18 mm, con la boca abierta) y **capa corta** (16-20 mm sobre hombros, espalda alta, lados
    del pecho y brazo hasta medio bíceps, con vuelo y forro púrpura);
  - **construidas** (rejillas de dos capas, exterior negra y forro púrpura, con ribete dorado: superficies cerradas):
    **capucha** amplia (rostro visible, forro púrpura, sin sombrero), **peplo** (faldón corto, abierto delante),
    **dos faldones largos** abiertos por delante, **tabardo** delantero, **bolsas** del cinturón y colgantes de los
    faldones. Se empujan fuera del cuerpo y de las piezas ya hechas con un margen de 4 mm (mismo desplazamiento para la
    capa y su forro: no se cruzan). Pesos copiados del punto más cercano del cuerpo o de sus huesos propios.
- **Pelo recogido dentro de la capucha:** el pelo de los lados y de detrás se comprime con suavidad hacia un elipsoide
  del cráneo (556 vértices, 4,6 cm como mucho); el de delante de la cara, el mechón superior y los mechones delanteros no
  se tocan. Los dos mechones delanteros se adelantan 2 cm en la punta (raíz quieta) para caer por delante de la ropa.
  Sin melena larga.
- **Textura del cuerpo** (por texel según el triángulo al que pertenece): el mono gris → negro con un punto de púrpura
  (398.831 texeles; guantes incluidos; conserva el relieve) y rugosidad de tela (≥ 0,8); el pelo casi blanco → **gris
  ceniza** (×0,70/0,715/0,755; 418.426 texeles). La piel, los ojos y el flequillo se reconocen y no cambian. Con eso
  desaparece la **franja clara del pecho** bajo los mechones (era textura de pelo del mono).
- **Dibujos** (dorado envejecido con metal; amatistas): ribetes de capucha, capa, faldones, peplo y tabardo; enredaderas
  con hojas; cierres y costuras de princesa del corpiño; cinturones de cuero con hebilla y amatista; **emblema dorado de
  la espalda: Ojo de Horus dentro de una estrella de SEIS puntas formada por dos triángulos** (no pentagrama, no en el
  pecho), centrado a 1,23 m bajo la capa; **medias asimétricas como la referencia de frente: la derecha con ramas y
  hojas, la izquierda geométrica** (línea, estrellas de cuatro puntas, rombos y arcos); detrás, línea y estrellas en las
  dos; botas negras con puntera dorada, boca dorada, rombo con amatista y correa.
- **Huesos nuevos: 6** (54 en total, 42 deforman): `faldon_i_1/2`, `faldon_d_1/2` (2 por lado, pivote en la cadera de
  cada pierna), `capa` (espalda de la capa corta) y `capucha` (punta y nuca). **Sin física por hueso:** su movimiento va
  **horneado en los 23 clips** (todos tienen pistas de los 6, así ningún clip deja la ropa donde la dejó otro):
  - faldones: siguen el balanceo de su muslo con retraso (raíz 0,06 s, punta 0,16 s); hacia delante poco (×0,45: el
    muslo sale por la abertura), hacia atrás más (×0,9: lo empuja); muslo muy arriba → lo de abajo cuelga; cadera baja
    (de rodillas) → se abren y se quedan atrás para no hundirse en el suelo;
  - **canalización** (`canalizar` y el bucle `magia_concentrar`): los faldones se **abren** hacia fuera y atrás con
    **oscilación desfasada** (izquierda y derecha, raíz y punta con fases distintas; el bucle cierra con dos ondas), además
    de los mechones de antes; la capa se levanta y la capucha hace un leve vaivén.
- **Cetro propio** `cetro_nix.glb` (612 triángulos, 1 material con textura de 128 y la amatista con emisión suave):
  asta negra con anillos dorados y empuñadura de cuero, aro dorado con la estrella de seis puntas y la amatista; punta
  mágica a 0,50 m del puño. `nix_3d.gd` lo pone en el socket `arma_d` cuando Nix no lleva arma equipada (si la lleva, la
  del inventario como antes); la magia sale de la amatista. El provisional (Loto Lunar) queda solo de respaldo.
- **Arreglo de integración hallado aquí:** `combate.gd modelo_3d()` pone `ruta_modelo = nix.glb` DESPUÉS de `_init`, así
  que en un combate real **el piloto nunca cargaba el GLB del FBX** (se veía la Nix de siempre con el JSON y el cetro del
  piloto: eso eran los «2 fallos esperados» de `prueba_nix_v12 -- nix_fbx` del §7). Ahora `nix_3d.gd _ready` fija el GLB
  del FBX si el interruptor está encendido (captura antes/después en `godot\combate\`). Apagado, nada cambia.

### 9.2 Cifras

| | Triángulos | Notas |
|---|---|---|
| Cuerpo `cuerpo_nix` | 11.968 | sin cambios de malla salvo el pelo recogido y los mechones adelantados |
| Ropa `ropa_nix` | **7.513** | corpiño 1.450, mangas 454, medias 831, botas 592, capa 990, capucha 1.284, peplo 456, faldones 2 × 620, tabardo y bolsas 216 |
| **Personaje (LOD0)** | **19.481** | objetivo ≤ 18-20 mil con ropa; con el cetro, 20.093 |
| Cetro `cetro_nix` | 612 | |

Materiales: **2 de personaje** (`nix_cuerpo`, `nix_ropa`) + **1 de arma** (`cetro_nix`). Texturas: cuerpo 3 × 1024
(color retocado, normal y rugosidad), ropa 2 × 1024 (color y metal/rugosidad; aprovecha ≈ 49 % del atlas), cetro 3 × 128;
las de 1024, comprimidas en VRAM con mipmaps (S3TC/ETC2). Pesos: ≤ 4 por vértice, normalizados, 0 sin peso. GLB 3,19 MB
(antes 2,37). Sin medir el rendimiento (había otros Godot trabajando; el encargo pide medir sin otra carga).

### 9.3 Pruebas (PC, datos aislados con `ejecutar_pruebas.ps1`; partida.save y carpeta real sin cambios en todas)

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_nix_fbx` (ampliada: 54 huesos, ropa aparte, 2 materiales, ≤ 20.000, pesos, huesos de la ropa con peso, atlas comprimido, sin restos, cetro propio, faldones que se abren al canalizar y se cierran al volver) | **SUPERADA**, 60 comprobaciones, 0 fallos | `D:\REBELUM_diagnostico\pruebas\2026-11-14_042515\resumen.md` |
| `prueba_nix_v12` (interruptor apagado: la Nix de siempre) | **SUPERADA** | mismo resumen |
| `prueba_nix_v12 -- nix_fbx` (combate real Kael, Lya y Nix con el vestuario; la prueba ya distingue el modelo del FBX) | **SUPERADA** (antes del arreglo y de adaptar la prueba: 6 fallos, todos de comprobar la Nix de siempre) | `D:\REBELUM_diagnostico\pruebas\2026-11-14_042653\resumen.md` |
| `fotos_nix_fbx` (ampliada) | MANUAL, 19 capturas revisadas | `D:\REBELUM_diagnostico\pruebas\2026-11-14_042024\resumen.md` |
| `fotos_nix_fbx_combate` (nueva: combate real en la llanura) | MANUAL, 12 capturas revisadas | `D:\REBELUM_diagnostico\pruebas\2026-11-14_042351\resumen.md` |

No se pasó la batería completa (solo toca archivos de Nix y sus pruebas). Había otros Godot abiertos de otras copias
(anotados en cada resumen).

### 9.4 Evidencias (`D:\REBELUM_diagnostico\v12\expansion\nix\vestuario\`)

- Blender (`render\v4\`): `hoja_T.png` (frente, perfil, espalda, tres cuartos, cabeza y emblema), `hoja_canalizar.png`,
  `hoja_poses.png` y `hoja_poses2.png` (andar, correr, derrota, victoria, culminante, saltar, ataque, defensa, golpe,
  derribo, levantarse, girar, hablar y la cadera de cerca); cada clip en frente/perfil/espalda/tres cuartos
  (`clip_<clip>_<cs>_<vista>.png`). Etapas: `render\cuerpo\`, `piezas\`, `textura\`, `v1`-`v3`. Cetro: `render\cetro\`.
- Godot: `godot\estudio\` (las 19 de `fotos_nix_fbx`, `hoja1.png`, `hoja2.png`) y `godot\combate\` (12 del combate real,
  `hoja.png` y `antes_del_arreglo_ruta_modelo_00.png`).
- `blend\p8_v4.blend` (todo: cuerpo, ropa, esqueleto, clips), `glb\nix_fbx.glb`, `cetro\cetro_nix.glb`,
  `texturas\*.png` (1024) y los registros de cada pasada en `trabajo\log_*.txt`.

### 9.5 Revisión visual (lo visto, no medido)

- Axilas, hombros, caderas, rodillas y faldones en los clips de las hojas: **sin atravesar** a la distancia del juego.
  Mangas, medias, corpiño y botas siguen al cuerpo (mismos pesos). La capa corta se apoya en hombros y brazo; al bajar
  el brazo, el puño de la capa queda como una hombrera con vuelo.
- Correr: el faldón de detrás se levanta con la pierna que va atrás (vuelo amplio, algo rígido: dos huesos por lado).
- Derrota y derribo (de rodillas o en el suelo): los faldones se abren y quedan detrás; con dos huesos no se pliegan, así
  que en la derrota parte del bajo roza el suelo.
- **Brillo (prioridad 6), comprobado en un combate real** (llanura, luz y fondo del juego): ya no se ve «lavada» (mono y
  pelo claros del piloto); el traje se lee negro y púrpura con el dorado, la cara se ve dentro de la capucha y el pelo
  gris. En el estudio de `fotos_nix_fbx` (luz frontal fuerte) el pelo sigue viéndose muy claro.

### 9.6 Matriz del vestuario

| Pieza (prioridad) | Estado |
|---|---|
| 1. Capucha + forro, pelo recogido | **verificado** en render y en Godot (estudio y combate real) |
| 2. Capa corta y faldones con huesos | **verificado** en render (23 clips) y en Godot; la apertura desfasada en la canalización, comprobada por prueba |
| 3. Medias asimétricas y calzado | **verificado** en render y en Godot (estudio) |
| 4. Emblema de la espalda | **verificado** en render y en Godot (`24_emblema_cerca.png`) |
| 5. Cetro propio por socket | **verificado** en Godot (prueba: es `cetro_nix` y sigue a `arma_d`; la magia sale de la amatista) |
| 6. Brillo excesivo | **corregido** en la textura (mono negro, pelo ceniza, tela mate); visto en combate real en el PC; Redmi pendiente |
| Emisión de iris y ornamentos (básica, fuerte, suprema) | iris: **hecho** (suave, fija; §11). Ornamentos con las tres intensidades y su limpieza: **hecho en el PC** (§12, 19/11); intensidades y colores sin decidir por el usuario; Redmi **pendiente** |
| Android (Redmi) | **pendiente**: ni instalado ni medido |

### 9.7 Pendientes

- Emisión separada de iris y ornamentos con las tres intensidades y su limpieza en interrupción, muerte, pausa y fin.
  **19/11: hecho en el PC** (§12); falta la decisión del usuario sobre intensidades y colores y verlo en el Redmi.
- Verla en el Redmi y medir (coste de 19,5 mil triángulos y 2 materiales; overdraw de capucha y faldones) sin otra carga.
- Texturas de 2048 para el perfil de PC: no se rehicieron con el mono negro y el pelo ceniza (solo las de 1024).
- `RightHandMiddle1` sigue sin pesos; los texeles oscuros de la mandíbula quedan bajo la capucha y el cuello alto negro, **15/11: arreglado** (la mano del cetro cierra los dedos; ver `REVISION_PERSONAJES_15_11.md` §3).
  sin corregir en su origen.
- Faldones: con 2 huesos por lado no se pliegan al arrodillarse; las bolsas son cajas sencillas.
- El encuadre del combate (`combate.gd`, entrada `nix3d`: `esc` 0,56, `alto_vista` 2,45, `centro_y` 1,12) es el de la
  Nix chibi con sombrero; con el FBX conviene revisarlo (archivo del coordinador, no tocado).
- Registrar en `docs/recursos.md` la Nix del FBX (piloto y vestuario): fila propuesta en el informe de la rama.
- Retrato de diálogo, cara expresiva y retoque adulto de los clips chibi, como en el §6.

## 10. Arreglo de la cara y del cetro al andar/correr (14/11/2026, tras la revisión visual) — sigue APAGADO

Informe con hojas de antes y después: `D:\REBELUM_diagnostico\v12\nix_arreglo_14_11\INFORME.md`. Sin rediseño:
mismos triángulos (11.968 + 7.513), esqueleto, clips y texturas de 1024. Lo anterior, en
`aethelgard/personajes/nix/fbx/anterior_14_11/` (con `.gdignore`).
- **Cara.** Causas: el «pelo recogido» de `p8_vestuario.py` tomaba la piel pálida por pelo y la comprimía hacia el
  cráneo (904 vértices de barbilla, boca y mandíbula, hasta 9 mm: boca torcida, barbilla abollada); el recoloreado de
  p8 pasaba esa piel a «ceniza» (manchas grises); el horneado de p2 con rayos largos ponía borde claro en el cuello
  alto. Arreglo (`fuente_blender/p10_cara.py`): esa piel vuelve a su sitio de p4, normales de la alta en la piel,
  rehorneado con rayos cortos y recoloreado con máscaras suavizadas solo en la piel de la cara y el cuello.
  `nix_cara.gdshader` no interviene (es de la Nix chibi).
- **Cetro.** `andar` y `correr` (captura de Lya) no tenían pistas de `arma_d`: el socket se quedaba en reposo respecto
  a la mano y el cetro iba horizontal y giraba. Ahora llevan pistas (`fuente_blender/p10_cetro.py`): la orientación
  de `reposo` con un balanceo suave del braceo. Los demás clips (guardia, canalizar, combate) no cambian.
- Rehacer: `p10_posiciones_p4.py` → `p10_cara.py` → `p10_cetro.py` → `p10_exportar.py`, copiar el GLB e importar.
- Pruebas: `prueba_nix_fbx` (60 · 0), `prueba_nix_v12` y `prueba_magia_negra` SUPERADAS
  (`D:\REBELUM_diagnostico\pruebas\2026-11-14_120908\resumen.md`).
- Queda: un punto pequeño bajo la comisura y algo de irregularidad junto a la raíz de los mechones (solo de muy cerca);
  bajo la barbilla se ve algo más de cuello que en el FBX (geometría reducida).

## 11. Iris con emisión suave y capa corta sin placas (14/11/2026, tarde) — sigue APAGADO

Rama `claude/wf-nix-iris-puños` (desde `claude/rebelum-v12` @ `d7fc8d6`). Evidencias en
`D:\REBELUM_diagnostico\v12\nix_iris_capa_14_11\` (`hojas\HOJA_CONTACTO.png` y una hoja por tema). Sin rediseño:
mismos triángulos (11.968 + 7.513 = 19.481), mismos 54 huesos, mismos 23 clips, mismas texturas (los `.webp` no
cambian). Lo anterior, en `aethelgard/personajes/nix/fbx/anterior_14_11b/` (con `.gdignore`).

- **Iris** (`nix_fbx_cuerpo.gdshader`, lo pone `nix_fbx.gd poner_iris()` desde `nix_3d.gd` solo con `nix_fbx`): el
  material de los v2 copiado tal cual más una emisión SOLO en el iris. La máscara va sobre la propia textura (sin
  textura nueva): dentro de los dos rectángulos del atlas donde están los iris (`fuente_blender/p11_iris.py`) y solo en
  los texeles violetas (color normalizado: azul y rojo por encima del verde); la esclerótica, la piel, las pestañas y la
  pupila quedan fuera. De cerca (retrato) la emisión es apenas ×0,35 del color del iris; a la distancia del juego
  (≥ 6 texeles por píxel, igual con la cámara ortográfica del combate y la de la exploración) ×0,9 y, como allí el
  mipmap mezclaba el iris con la piel, se usa el texel exacto del iris: en combate y en exploración los ojos son dos
  puntos violetas en vez de color piel, sin halo con resplandor de umbral 0,85 (`hojas\iris_distancia_sin_con.png`).
  Probado y descartado: subir la emisión sin el texel exacto (×1,5-2,5: puntos blancos, «faro»).
- **Capa corta** (`fuente_blender/p11_capa.py` sobre la copia de `p8_final.blend`, después `p10_exportar.py`): los
  «puños» y los rectángulos de la espalda eran **artefactos** del vuelo de `p8_vestuario.py` (`extra_capa`), no canon
  (la referencia vestida tiene el borde dorado continuo y el forro solo asoma por debajo): 45 de las 106 caras del vuelo
  miraban hacia dentro (Godot las descarta) y su forro, desplazado según su propia normal, quedaba 4 mm por fuera de
  cara a la cámara; y el puño se abría 2,6 cm hacia fuera del brazo. Ahora el vuelo mira hacia fuera, el forro va 4 mm
  por dentro mirando hacia dentro, el borde de abajo conserva su medida con la dirección suavizada y el puño sigue el
  brazo (1,8 cm a lo largo, 6 mm hacia él) con su ribete dorado (`hojas\capa_godot_antes_despues.png`,
  `capa_blender_guardia_ids.png`, `capa_poses_antes_despues.png`).
- Cifras deterministas: llamadas de dibujo y triángulos iguales; memoria de texturas igual (ninguna nueva); malioc
  (Mali-G57, traducción aproximada de `pruebas/herramientas/malioc/`): fragmento del cuerpo 16,88 → 18,62 ciclos con el
  sol y 11,62 → 13,38 sin él (+1,75 de aritmética; textura 1,50 → 1,75, la lectura extra solo dentro de los
  rectángulos del iris). La ropa no cambia de material. GLB 3.194.328 → 3.195.836 bytes (`69027f55…398a9d`).
- Pruebas: `prueba_nix_fbx` (63 · 0, con 3 comprobaciones nuevas del iris), `prueba_nix_v12` y `prueba_magia_negra`
  SUPERADAS (`D:\REBELUM_diagnostico\pruebas\2026-11-14_141122\resumen.md`). Capturas: `pruebas/fotos_nix_iris.gd`
  (con y sin emisión en la misma pasada) y `fotos_nix_revision.gd` (estudio, combate, Pastos y Oakhaven).
- Queda: en exploración la capucha y el flequillo tapan a menudo los ojos (desde arriba solo se ve uno); sin forro
  púrpura visible en la capa salvo desde abajo (antes asomaba por los defectos); tiempos en el Redmi.

## 12. Emisión de los ornamentos en tres intensidades y su limpieza (19/11/2026, C-6 / PC-4) — sigue APAGADO

Encargo del 13/11 §6 («emisión separada para iris y ornamentos; intensidades básica, fuerte y suprema»; «interrupciones,
muerte, pausa y fin de combate deben resolver correctamente [...] la emisión»). Rama `claude/rebelum-v12`. Solo con
`nix_fbx` (que sigue APAGADO, `nix_fbx.gd:21`) y `nix_v12`: sin ellos no se carga ningún material nuevo y el juego no
cambia. Evidencias en `D:\REBELUM_diagnostico\v12\nix_emision_19_11\`.

**Qué se hizo**
- **Máscara sin textura nueva** (`personajes/nix/fbx/nix_fbx_ropa.gdshader`): los ornamentos están solo en la ropa
  (`ropa_nix`; el cuerpo tiene metal 0 en su material). En el atlas de la ropa (`p8_dibujos.py`) el **oro** es lo único
  con metal = 1 (tela, forro, cuero y botas: 0) y las **amatistas** tienen rugosidad 0,12 (oro 0,36; tela y cuero ≥ 0,55)
  y color violeta. La máscara es la «m» de metal que el material de los v2 ya calcula (mismo umbral) más las amatistas
  por rugosidad y color; se leen las mismas tres texturas que antes (ninguna lectura de más). Sonda del atlas
  descomprimido: 60.357 texeles de oro (m > 0,5) y 213 de amatista de 1.048.576; el forro púrpura (9.483 texeles
  violetas) no entra por rugosidad.
  - **De cerca**, emisión = color del propio texel × máscara: nítida, y los bloques de la compresión (BC1/ETC2) que marcan
    metal en tela negra no emiten porque su color es negro.
  - **De lejos** (≥ 6 texeles por píxel, como el iris: combate y exploración) los ribetes finos ocupan menos de un píxel y
    el umbral del mipmap los borraba (primera prueba, `prueba1\`: el combate casi sin brillo y, con «dorado × metal
    medio», bloques dorados sobre los faldones: 13-14 % de la energía fuera de los ornamentos). Ahora: color MEDIO del
    mipmap × puerta baja de metal medio (0,03-0,2): «dorado × cobertura», sin parpadeos y sin bloques.
- **Intensidades** (`nix_fbx.gd NIVELES`, valor del uniforme `ornamentos`): apagada 0 · **básica 0,8** · **fuerte 1,6** ·
  **suprema 2,8**. Color: el **propio** de cada ornamento (oro envejecido y violeta de la amatista), sin tinte añadido.
- **Habilidad → intensidad** (`nix_fbx.gd NIVEL_HECHIZO`, DECISIÓN REVISABLE): en el juego solo existen los tres
  hechizos piloto, así que:

  | Momento | Intensidad | Cómo sube | Gancho |
  |---|---|---|---|
  | Ascuas de Nácar (rango I, P01) y Aguja de Invierno (rango I, P02) | básica | durante la anticipación, hasta el lanzamiento (0,7 / 0,8 s) | `nix_3d.gd lanzar_negra` |
  | Canalizar (concentrarse mientras se prepara un hechizo con barra; hoy, el Colapso) | fuerte | 0,6 s; se mantiene mientras prepara (volver a la guardia por un golpe no la corta) | `concentrar` |
  | Colapso del Firmamento (rango VI, gasta los 3 sellos de Eclipse, P07) | suprema | desde la fuerte hasta el lanzamiento (1,6 s) | `lanzar_negra` |
  | Otras magias y artes de Nix (magia normal, artes y el gesto del dúo: pasan por `lanzar_magia`, que llama a `lanzar_negra("nix_ascuas")`; revisión del 19/11) | básica | como Ascuas; vuelve a 0 con `fin_magia` | `lanzar_magia` |
  | Fin del hechizo | 0 | 0,5 s | `fin_magia` |

  Un hechizo nuevo sin fila toma la intensidad por los sellos que gasta (3 suprema, 2 fuerte, si no básica).
- **Limpieza** (a 0 en el acto, parando la subida en curso; `nix_3d.gd apagar_emision`): **conjuro roto**
  (`combate.gd _conjuro_roto`: 3 líneas, solo actúa si el modelo tiene `apagar_emision`, que solo tiene Nix), **muerte**
  (`morir`; ya muerta no vuelve a subir aunque el hechizo termine de resolverse), **pausa** (`NOTIFICATION_PAUSED` del
  árbol y `NOTIFICATION_APPLICATION_PAUSED`, Android en segundo plano; tras la pausa sigue a 0 hasta la siguiente
  habilidad), **fin del combate** (`victoria`; en la derrota todos han muerto; la huida sale de la escena) y **salida de
  la escena** (`NOTIFICATION_EXIT_TREE`). Hoy el combate no tiene menú de pausa: lo cubierto es la pausa del árbol y la
  de la aplicación. El «deja ir» del conjuro (sin blancos) solo ocurre con todos los enemigos caídos: lo cubre la victoria.
- El iris (§11) no cambia: emisión separada y fija.

**Cifras**
- Apagada = igual que antes: misma pose y luz con el material de siempre (`heroe_v2.gdshader`) en la ropa frente al
  nuevo a 0: **0 píxeles distintos** en 7 de 8 fotos; en la octava, 449 píxeles, todos en el contador de FPS de la
  esquina (caja 39×12 en y = 8), ninguno en Nix (`fotos\*_antes_heroe_v2.png`, `medidas_estudio.txt`).
- Fugas (luz del combate, suprema; referencia: la fuente `.webp` sin comprimir con sus mipmaps): de la energía que se
  aclara, a más de 1 px de un ornamento 0,65-0,77 % de cerca, 2,61 % en la cámara del combate y 2,67 % en la de
  exploración; **a más de 3 px, 0,29-0,66 %**. Básica: 0,15-1,18 % (> 1 px) y 0,05-0,28 % (> 3 px). Son bordes
  pegados a los ribetes (`diferencia_*.png`: amarillo dentro, cian fuera). La cámara de exploración varía algo de una
  pasada a otra (en una anterior, 3,16 % y 0,63 % con la suprema).
- Coste: ninguna textura nueva (0 bytes), mismas llamadas de dibujo y triángulos, el mismo número de lecturas de textura
  (1,50 en malioc). malioc (Mali-G57, traducción aproximada, `malioc\malioc_ropa.txt`), fragmento de la ropa: con el sol
  16,88 → 18,75 ciclos y sin él 11,62 → 13,50 (+1,87, el camino más largo: con la emisión encendida; apagada se salta
  por una rama uniforme). Sin medir en el Redmi.

**Pruebas** (datos aislados con `ejecutar_pruebas.ps1`; partida y carpeta real sin cambios en todas)
- `prueba_nix_fbx`: 64 → **90** comprobaciones, 0 fallos (26 nuevas: material de la ropa, cada nivel, cada limpieza y
  la Nix de siempre sin nada). Sin el arreglo (`nix_3d.gd` y `combate.gd` de `99d7b7c`): **25 fallos**.
- `prueba_nix_emision` (nueva, combate de verdad, 28 comprobaciones): Ascuas básica; Colapso fuerte y suprema; conjuro
  roto por un golpe real (`_quitar_pv`); muerte; pausa; victoria; salida; sin `nix_fbx` nada. Sin el arreglo: **10 fallos**;
  solo sin las 3 líneas de `combate.gd`: **3 fallos** (el conjuro roto se queda en la fuerte, 1,59-1,60).
- También SUPERADAS: `prueba_integridad`, `prueba_nix_v12` (y con `-- nix_fbx`), `prueba_magia_negra`,
  `prueba_audio_magia_negra`, `prueba_combate_huella`, `prueba_naira_combate`, `prueba_banco_derrotas` y
  `prueba_rasgos_grupo`.
- Fotos: `pruebas/fotos_nix_emision.gd` (estudio con luz del combate y anochecer con resplandor; «modo=combate» en un
  combate real). Hojas: `fotos\HOJA_combate.png`, `fotos\HOJA_anochecer.png` (filas: frente, espalda, cámara del
  combate, exploración; columnas: apagada, básica, fuerte, suprema) y `fotos\HOJA_combate_llanura.png` (combate real).

**Decisiones del usuario (pendientes)**
- Intensidades (0,8 / 1,6 / 2,8). Visto en las fotos: la básica se nota de cerca y poco a la distancia del combate; la
  suprema hace casi blancas las punteras de las botas y el ribete de la capucha y, con resplandor (anochecer), un halo.
- Colores: hoy el propio de cada ornamento. Alternativas: teñir la fuerte o la suprema con el violeta del Colapso
  (`A58ACB`) o el púrpura del sello.
- La correspondencia habilidad → intensidad (tabla de arriba), sobre todo «fuerte = canalizar», porque el piloto no tiene
  un hechizo intermedio; si se añaden rangos II-V, darles fila en `NIVEL_HECHIZO`.
- Si el cetro propio (su amatista ya emite suave y fija) debe subir con los niveles.

**Fuera de esta tarea (pendiente, sin hacer)**
- Mover el socket `arma_d` 1-2 cm para que el asta quede dentro del puño (`REVISION_PERSONAJES_15_11.md` §3): obliga a
  volver a exportar los 23 clips en Blender.
- El encuadre del combate `nix3d` (`combate.gd`: `esc` 0,56, `alto_vista` 2,45, `centro_y` 1,12), que es el de la Nix
  chibi.
- Las texturas de 2048 del perfil de PC (solo se rehicieron las de 1024).
- **Redmi**: ni instalado ni medido (coste real de la rama de emisión y de las 19,5 mil caras; si la básica se lee a
  tamaño de teléfono).
