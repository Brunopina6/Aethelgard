# Animaciones V12 · Fase B: protagonistas v2 (Kael, Lya y Garon)

## 12/11/2026, 00:50 · rama LOCAL `claude/v12-fase2-heroes` (`D:\Aethelgard_v12_heroes`), desde `c703625`

Commits: `563aa11` (Blender: rig, biblioteca, cara y GLB), `5754002` (interruptor y scripts), `bdcd63b` (pruebas),
`8ec3359` (retratos de Garon), `8138e39` (prueba de combate real), `e4ce4c2` (Lya en el suelo) y el de este informe.
Sin push ni merge. **No he tocado** `combate.gd`, `grupo.gd`, `artes.gd`, `menus.gd`, las zonas, `kael_3d.gd`,
`maga_3d.gd`, `garon_3d.gd`, `gestos_3d.gd`, los FBX originales, `garon.dch` ni `project.godot` (la importación lo
vació otra vez; `git restore` y reimportado: estable). **Con el interruptor apagado el juego no cambia** (ningún archivo
existente apunta a lo nuevo).

### Qué hay (observado y comprobado ejecutando, aislado, el 12/11)

**1. Arquitectura común** (`aethelgard/personajes/heroes_v2/fuentes_blender/`, Blender 5.2.3 por guion, `.gdignore`)
- `rig_comun.py`: los tres tienen el mismo esqueleto Mixamo en T, con proporciones distintas. Una pose se escribe en el
  espacio del personaje (cadera, columna, cuello y cabeza en grados; manos respecto al hombro en largos de brazo con IK
  de dos huesos, codo, dedos, palma y cierre; pies apoyados donde están en reposo, con IK y rodilla adelante; «mirada»
  que compensa la inclinación del cuerpo), así que **el mismo clip vale para los tres**. Huesos nuevos `arma_d` y
  `arma_i` (hijos de la mano, eje Y = hoja, X = filo): las armas van donde se diseñaron en cada clip.
- `biblioteca_clips.py`: el contrato y los clips, con el ESTILO de cada uno (Kael: pecho fuera, rebota, gestos amplios;
  Lya: erguida, cabeza ladeada, pies juntos, más lenta; Garon: base ancha, rodillas dobladas, hombros atrás, ×1,25 más
  lento, apenas se mueve al recibir un golpe) y su arma (sable, cetro, dos espadas).
- `cara_expresiva.py`: Meshy pinta ojos y boca en la textura (sin formas de cara). Por rayos se toman las caras de la
  PIEL de la zona de ojos y boca (sin el flequillo), se duplican en la malla `cara_v2` (mismos pesos, 0,8 mm delante) y
  se proyecta su color en un atlas de 4 × 2 losetas: normal, cerrados, sonrisa, dolor, grito, sorpresa, entrecerrados.
  Con «normal» la malla se oculta (cara original exacta). Garon no lleva: yelmo cerrado.
- `construir_heroe.py`: importa el FBX original (sin tocarlo), renombra los clips de captura, crea huesos, clips y cara,
  exporta el GLB (texturas WebP 2048, q90) y el JSON, y hace hojas de contacto de cada clip.
  Orden: `blender -b --factory-startup -P personajes/heroes_v2/fuentes_blender/construir_heroe.py -- Kael|Lya|Garon <aethelgard> <evidencias>`.
  Los `.blend` resultantes, fuera de Git (D-075): `D:\REBELUM_diagnostico\animaciones\2026-11-12\heroes\blender\<héroe>\<héroe>_v2.blend`.

**2. Contrato de clips (30 fps, «en el sitio»; los instantes están en `<héroe>_v2_clips.json`)**

| Clip | Kael | Lya | Garon | Instantes |
|---|---|---|---|---|
| reposo (bucle) | 4,0 s, sable al hombro (su identidad), mano en la cadera, mira a un lado | 4,6 s, cetro al lado | 5,0 s, espadas bajas, plantado | |
| guardia (bucle) | 1,0 s, rebota de puntillas | 2,4 s | 3,0 s, espadas al frente | |
| hablar / hablar_b / asentir | mano abierta / mano al pecho / cabeza | igual, más suave | igual; hablar_b = puño al pecho | |
| interactuar | 1,4 s | 1,6 s | 1,75 s | contacto 0,6·ritmo |
| saltar · girar | 0,95 s · 0,6 s | | | despegue 0,3, aterrizaje 0,65 |
| ataque | salto y corte, 1,3 s | golpe de cetro, 1,0 s | tajo doble, 1,5 s | impacto 0,64 / 0,45 / 0,7 |
| magia_lanzar | 1,4 s (estocada con el sable) | 1,1 s | — (D-037) | lanzamiento 0,85 / 0,5 |
| magia_concentrar (bucle), magia_poderosa | — | 2,0 s · 2,4 s | — | poderosa: lanzamiento 1,5 |
| recibir_golpe · derribo · derrota (bucle) · levantarse · victoria | 0,7 · 1,3 · 3,0 · 1,3 · 1,8 | ídem (victoria 1,8) | ídem (victoria 2,0) | impacto 0; suelo 0,9 |
| de captura, renombrados | andar, correr, andar_pesado, reposo_original, golpe_original, derribo_original, magia_original | andar, correr, reposo_original | andar, correr, paseo, **juicio**, **giro**, morir_original | Juicio 1,10 y Giro 0,90/1,50 (sin cambios) |

Kael conserva los tiempos del combate (impacto a 0,64 s = T_AGACHAR + T_SALTO + T_CORTE, magia a 0,85 s) y Lya los suyos
(magia a 0,5 s). Garon conserva Juicio, Giro, la Guardia que cubre, Embuir, la capa y los pasos de doble espada.

**3. Modelos** (mismas mallas y texturas de Meshy; los FBX originales siguen y son el respaldo)

| | Triángulos | Cara | Huesos | Texturas | GLB |
|---|---|---|---|---|---|
| Kael | 10 324 + cara 326 | sí | 66 + arma_d | 3 × 2048 WebP (color, normal, metal/rugosidad) + atlas de cara 1560 × 640 | 4,9 MB (el FBX: 17,9) |
| Lya | 10 315 + cara 182 | sí | 50 + arma_d | 2 × 2048 + atlas | 3,2 MB (8,6) |
| Garon | 10 327 | no | 44 + arma_d, arma_i | 3 × 2048 | 4,3 MB (17,1) |

**4. Godot** (`aethelgard/personajes/heroes_v2/`)
- `heroes_v2.gd`: el interruptor, **APAGADO**: `Engine.set_meta("heroes_v2", true)`, el argumento `heroes_v2` o
  `ACTIVO_POR_DEFECTO = true`. `script_de(ruta)` devuelve el script v2 o el mismo.
- `kael_v2_3d.gd`, `lya_v2_3d.gd`, `garon_v2_3d.gd`: **heredan de los originales**; el combate y la exploración les
  llaman igual (`ataque_salto`, `lanzar_magia`, `herida`, `morir`, `revivir`, `victoria`, `marcha`, `activar_esperas`,
  `atacar_juicio`, `cubrir`…). Si recibe la ruta del FBX original la cambia por su GLB; si falta el GLB, carga el FBX y
  hace exactamente lo de siempre. En combate su reposo es la guardia; con `activar_esperas(true)` (exploración), el
  reposo. Las esperas de exploración (`animaciones/esperas/*.res`) y los pasos de doble espada siguen valiendo: las
  rutas de pista del GLB son las del FBX (`SmartRigArmature/Skeleton3D:mixamorig_Hips`).
- API nueva para diálogos y exploración: `hablar(animo)` (un gesto distinto del anterior o ninguno; ánimo: alegre,
  broma, sorpresa, enfado, decidido, dolor, triste o cansado → expresión 2,2 s), `expresion(nombre, dur)`,
  `gesto(clip)`, `saltar()`, `interactuar()`; Lya además `concentrar()` y `magia_poderosa()` (await al lanzamiento).
- `heroe_v2_ayudante.gd`: expresiones (parpadeo cada 2,5-6 s, a veces doble; no parpadea con ojos cerrados ni en KO),
  conversación sin repetir y materiales. `heroe_v2.gdshader`: las MISMAS texturas, con reflejo de cielo y suelo en lo
  metálico (en Compatibility no hay sondas: el metal salía negro; se nota en la armadura de Garon y los adornos), borde de
  luz suave y algo más de relieve. Solo `fragment()`.

**5. Retrato de Garon** (`dialogos/retratos/garon_reposo.png`, `garon_espalda.png`, `garon_saludo.png`, `garon_alto.png`,
300 × 636; fuente `dialogos/retratos/fuentes_blender/retratos_garon.py`): mismo modelo del juego, misma cámara
ortográfica (6° desde arriba, girada −12° como Kael), misma luz y sin metal, como los de Kael y Lya; silueta del reposo
de 632 px (Kael y Lya, 620). Poses: firme, manos a la espalda (en descanso, reservado), puño al pecho y «¡Quietos!».

### Cómo se activa (cambios mínimos que NO he hecho; son de otros)

Arriba de cada archivo: `const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")`.
- `combate.gd:1325` (y igual en `:4208`): `var maga = load(HeroesV2.script_de(BramaVersion.elegir(m["script"]))).new()`.
  MODELOS no necesita cambiar (el script v2 sustituye la ruta del FBX). El encuadre (`vp`, `alto_vista`, `centro_y`)
  vale: en las capturas del combate real nada se sale.
- `prototipos/vista3d.gd:48`: `kael = load(HeroesV2.script_de("res://kael_3d.gd")).new()`.
- `zonas3d/grupo_3d.gd:157`: `var nodo = load(HeroesV2.script_de(RUTAS[n])).new()`.
- Con eso, `Engine.set_meta("heroes_v2", true)` (o una opción de Ajustes) enciende los tres; apagado, todo igual.
- Diálogos (propuesta): en cada frase, `heroe.hablar(animo)` de quien habla (el ánimo podría salir del `extra_data` que
  ya usa `retrato_vivo.gd`), y `heroe.mirar(...)` hacia quien habla (ya existe).
- Retrato de Garon: sustituir en `dialogos/personajes/garon.dch` `"default_portrait": ""` por `"normal"`, la
  descripción por `""` y `"portraits": {}` por los de Kael con estas rutas: `normal` → `garon_reposo.png` (escala 1.0);
  `vivo` (escena `retrato_vivo.tscn`, desplazamiento (0, 70), escala 1.1272258) con
  `poses = {"espalda": garon_espalda, "saludo": garon_saludo, "alto": garon_alto}`. **No lo he hecho**: con el retrato
  puesto, `pv_05`-`pv_07` mostrarían a Garon de inmediato (no va detrás de un interruptor).

### Pruebas (aisladas, `ejecutar_pruebas.ps1 -Lista`; «partida.save real: sin cambios · carpeta real: sin cambios»)
- `pruebas/prueba_heroes_v2.gd` (auto): **SUPERADA, 176 comprobaciones, FALLOS: 0** (12/11 00:48, tras `e4ce4c2`):
  interruptor, clips y duraciones frente al JSON, huesos de arma, cara y losetas, impacto de Kael a 0,64 s, Juicio de
  Garon a 1,10 s, magia a 0,85 / 0,5 s, golpe recibido y vuelta, KO en bucle, levantarse, victoria, reposo de
  exploración, conversación sin repetir y saltar. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-12_004807\resumen.md`.
  (La primera pasada dio 12 fallos: comprobaba `current_animation`, que queda vacío al acabar un clip; arreglado con
  `assigned_animation`.)
- `pruebas/fotos_heroes_v2.gd` (ventana): **MANUAL**, sin errores, 66 capturas (antes a la izquierda, después a la derecha).
  Resúmenes: `...\2026-11-12_004518\resumen.md` (los tres) y `...\2026-11-12_004807\resumen.md` (Lya, tras su arreglo).
- `pruebas/fotos_heroes_v2_combate.gd` (ventana): **MANUAL**, sin errores, combate real (`combate.tscn`, `grupo=3 auto`)
  antes y después, 16 + 16 capturas; los tres cargan su GLB. Para la prueba, sin tocar `combate.gd`, los scripts v2
  toman la ruta de los originales en la caché (`take_over_path`). Resumen: `...\2026-11-12_004344\resumen.md`.
- **Pido** añadir a `pruebas/lista_pruebas.txt`:

  ```
  prueba_heroes_v2         | auto    |                                       | 300 | nada     | V12 héroes v2: interruptor, clips, instantes y expresiones
  fotos_heroes_v2          | ventana | salida={salida} heroes=Kael,Lya,Garon | 600 | {salida} | V12 héroes v2: antes y después
  fotos_heroes_v2_combate  | ventana | salida={salida} grupo=3 auto          | 200 | {salida} | V12 héroes v2: combate real (añadir «antes» para el de siempre)
  ```
- **Pido** una fila en `docs/recursos.md`: «Héroes v2 (12/11, apagados): `personajes/heroes_v2/*` (GLB derivados de los
  modelos de Meshy de Kael, Lya y Garon —misma licencia y créditos pendientes que los originales— con clips, huesos,
  cara expresiva y material propios, obra del proyecto con Blender 5.2.3 por guion) y `dialogos/retratos/garon_*.png`
  (render del modelo de Garon)». Los GLB heredan la licencia pendiente de los FBX (`licencias_pendientes.txt`).

### Evidencias: `D:\REBELUM_diagnostico\animaciones\2026-11-12\heroes\`
- `godot_antes_despues\`: 66 capturas de Godot. Combate (cámara de `combate.gd`): guardia, ataque (0,2 · 0,5 · 0,64 ·
  0,84 s), magia, golpe, victoria, caída, KO y levantarse. Exploración: lejos, cerca, andar, hablar, hablar_b, saltar,
  interactuar. Caras de Kael y Lya, una por expresión.
- `godot_combate_real\`: `combate_antes_NN.png` y `combate_despues_NN.png` (mismo combate, mismos instantes).
- `blender\<héroe>\`: hoja de contacto de cada clip (8 instantes, lado de la cámara de combate), el atlas de cara y el `.blend`.
- `retratos_comparados.png`: Kael, Lya y los cuatro de Garon juntos.

### Límites (honesto)
- **Sin medir en el Redmi** (ni en el PC con carga quieta): el sombreado nuevo añade una lectura por textura y unas
  operaciones de emisión; la cara son 182-326 triángulos y una textura pequeña; los GLB, muestreados por fotograma. La
  medida la programa el coordinador.
- **No he rehecho geometría**: pelo, ropa y equipamiento son los de Meshy. La mejora de materiales es de sombreado
  (metal, borde, relieve), no de texturas nuevas. Mejorar pelo y tela de verdad exige retopología o modelos nuevos.
- Las expresiones son losetas pintadas por código: legibles a la distancia del juego, sin sincronía de labios ni cejas
  móviles (dibujar cejas encima del pelo quedaba mal y lo quité). Los trazos de Kael son algo finos de cerca.
- Clips hechos por poses clave (sin captura): el arco del sable en la victoria y el golpe de Lya son mejorables; la guardia
  de Garon sustituye a «GuardiaDoble» del paquete (sigue dentro por si se prefiere). El sable de Kael mide 1,45 m, como
  en el juego: atraviesa a veces la capa en el corte.
- Garon: piernas muy abiertas en el retrato (es su estilo de base ancha); se puede cerrar para los retratos.
- Exploración probada en mi escena (suelo plano), no en Pastos ni con el grupo andando; combate real probado con el
  `take_over_path` de la prueba, no con el cambio aplicado en `combate.gd`.
- La cara de Lya y Kael solo cambia si alguien llama a `expresion()`/`hablar()` o en los momentos del combate.

### Siguiente paso propuesto
1. Que el usuario mire `godot_combate_real\` y `godot_antes_despues\` y decida si encender los héroes v2.
2. Si sí: los tres cambios de una línea, `garon.dch` y medir en el Redmi un combate de tres y Pastos.
3. Pulido: arco de la victoria de Kael, golpe de Lya con más anticipación, magia de Kael con el sable más alto,
   enganche de `hablar(animo)` en Dialogic, y un `girar` acompañado por el giro del nodo en `grupo_3d.gd`.
