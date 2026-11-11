# Animaciones (y modelado), V12: Bramavidrio versión 3, «el Excavador»

## 12/11/2026, 00:00 · rama `claude/v12-bramavidrio3` (LOCAL, nace de `claude/rebelum-v12` @ `373e7db`)

**Encargo (noche autónoma):** la v2, «la Sierpe de la Vela», todavía no convence al usuario y su boca parece partida,
siempre entreabierta. Pide una criatura original, colosal y con personalidad, que encaje con Kael, Lya y Garon, con una
boca articulada de verdad (cerrada en reposo), dos o tres variantes con capturas comparables, animaciones con peso y
el arreglo de los héroes que se dibujan encima del cuerpo.

Copia `D:\Aethelgard_v12_bramavidrio3`. Todo es **obra propia**: geometría, textura, esqueleto y clips hechos con
Blender 5.2.3 por guion. No hay recursos de terceros ni se ha copiado ningún diseño.

**Estado:**
- La v3 está hecha, integrada y probada en el PC (aislado), en el combate y en la exploración. **No es la de por
  defecto:** `VERSION_DEFECTO` sigue en 2. El usuario la elige en Ajustes → «Bramavidrio» → «Prueba v3: el Excavador».
- La v1 y la v2 no se han tocado.
- **Nada se ha probado en el Redmi** y no se ha medido el rendimiento.

### Commits

| Commit | Qué |
|---|---|
| `6cd6f15` | `fuente/crear_bramavidrio3.py` (el generador: las tres variantes y el modelo) y `fuente/hoja_fotos.py` (hojas de fotos) |
| `f3ed79f` | `enemigos/bramavidrio/v3/`: los tres GLB, las tres texturas WebP (con sus `.import`) y `bramavidrio3_clips.json` |
| `23374a5` | `v3/bramavidrio3_3d.gd`, los 4 sombreadores (con sus `.uid`), `bramavidrio_version.gd` (versión 3) y `menus.gd` (la opción) |
| `bb0805c` | `pruebas/prueba_bramavidrio_modelo.gd` (versión 3), `pruebas/fotos_bramavidrio3.gd` y `lista_pruebas.txt` |
| (siguiente) | la cabecera del sombreador de vidrio de la v3 y este informe |

**Para integrar copiando:** `aethelgard/enemigos/bramavidrio/v3/*` (todo), `aethelgard/fuente/crear_bramavidrio3.py`,
`aethelgard/fuente/hoja_fotos.py`, `aethelgard/enemigos/bramavidrio/bramavidrio_version.gd`, `aethelgard/menus.gd`
(solo el bloque «Bramavidrio», 5 líneas), `aethelgard/pruebas/prueba_bramavidrio_modelo.gd`,
`aethelgard/pruebas/fotos_bramavidrio3.gd` y `aethelgard/pruebas/lista_pruebas.txt` (2 líneas). Godot crea el `.uid`
de `fotos_bramavidrio3.gd` al importar. `combate.gd`, `combate_bramavidrio.gd` y `zonas3d/mar_cristal/gusano.gd` **no
cambian** (gusano.gd ya pide guion y modelo al interruptor).

**Incidente:** a las 22:58, un bucle mío con rutas relativas creó tres archivos vacíos en la raíz de la copia del
coordinador (`D:\Aethelgard_v12\bramavidrio3_piel*.webp.import`). El coordinador los limpia; los buenos están en
`v3/`. Desde entonces, solo rutas absolutas.

## 1. Por qué la boca de la v2 parecía rota (demostrado en `fuente/crear_bramavidrio2.py`)

1. **El clip no la cerraba nunca:** `pose_reposo` abre la mandíbula de 5 a 9° en todo el bucle (`p.boca = 5 + 4·…`) y
   `Pose()` la deja en 4° por defecto.
2. **La geometría no cerraba ni a 0°:** el labio del cráneo está a z = −0,33…−0,37 y el borde de la mandíbula a
   `ZB_MAND = −0,43`. Queda una rendija de 6 a 10 cm a escala 1 (8 a 13 cm en el modelo) por la que se ve la carne roja.
   Es lo que se ve en las capturas del Redmi (`215416_combate1`, `220439_alto0`).
3. **Dos cáscaras sueltas:** el paladar cuelga del labio y la mandíbula es una canoa, unidas solo por una membrana corta.
   Al abrir se leen como dos piezas desplazadas.

## 2. La cabeza nueva (la misma en las tres variantes)

- **Una sola piel** con la boca cortada como una ranura desde el hocico hasta la comisura. Detrás de la comisura el
  anillo es uno; delante, el borde del labio y el de la mandíbula son vértices distintos.
- **Cierre con solape (sobremordida):** el labio de arriba baja 7 cm por fuera del borde de la mandíbula, que sube 5 cm
  por dentro del labio. Se ve una línea de cierre limpia, sin rendija. El solape se desvanece en la comisura, donde los
  dos bordes son el mismo vértice.
- **Bisagra en la comisura** (`mandibula`), con los pesos de la garganta repartidos para que la piel se estire al abrir.
- **Interior:** labio con encía, paladar con pliegues, suelo con lengua y surco, mejillas de piel doble que se estiran
  al abrir, y la garganta, un túnel cerrado con la luz al fondo. El paladar y el suelo bajan con el alto del cráneo
  cerca del hocico, para no atravesarlo.
- **Dientes:** los de arriba cuelgan por fuera de la mandíbula (se ven con la boca cerrada; el colmillo de cristal
  delante); los de abajo caben bajo el paladar.
- **El tubo del cuello empieza detrás de la garganta.** En la v2 su punta cruzaba la boca, y con la mandíbula abierta
  chocaba con el suelo de la boca: lo encontró la comprobación BVH.
- **Cejas articuladas** (`ceja_izq`/`ceja_der`): fruncen el ceño en los ataques y lo levantan al recibir.
- **Ojos grandes** de vidrio encendido: almendra inclinada, pupila en rendija y un brillo blanco.
- **Fosetas sensoriales:** tres hoyos de cristal a cada lado del hocico.

**Comprobado en Blender (BVH sobre la malla deformada):** cero pares de triángulos del cráneo y de la mandíbula que se
atraviesen. Se miró en reposo (4 instantes), rugido (5), embestida (4), Fractura (4), Aliento (5), herida (2),
derrota (3) y emersión (3), en las tres variantes. Quedan fuera las 24 caras que tocan el vértice de la comisura, que es
una costura a propósito. Está en `bramavidrio3_clips.json`, clave «intersecciones».

**Comprobado en Godot** (`prueba_bramavidrio_modelo`, fotograma a fotograma con el modelo importado):
- **Reposo:** la boca está cerrada en todo el bucle (0,0000 m entre labio y mandíbula, giro 0,00°).
- **Nunca cierra de más:** en ningún clip el borde de la mandíbula sube por encima del labio.
- **En el mordisco** (1,0 s) la boca está cerrada.
- **Apertura máxima por clip:** rugido 55,9°, Aliento 58,0°, Fractura 52°, embestida 45,8°, derrota 46°, emersión 26°
  y herida 16°.

## 3. Las tres variantes

Fotos de Blender (frente, boca cerrada, boca abierta, perfil, boca abierta de frente y la vista del combate con tres
muñecos de los héroes): `D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio3\variantes\<variante>\bramavidrio3_<variante>_*.png`.
Cada variante tiene su hoja (`..._hoja.png`) y las tres juntas están en `variantes\comparativa_variantes.png`. El GLB,
la textura y el JSON de cada una también están ahí, fuera del proyecto; se regeneran con
`blender -b --factory-startup -P fuente/crear_bramavidrio3.py -- <carpeta> variantes`.

En el **combate real** (grupo 13, los tres héroes, la interfaz y la cámara de `_crear_rig_3d`), en 13 instantes cada
una:
- `combate_variantes\<variante>_<clip>_<s>.png`;
- la v2 para comparar: `combate_v2\v2_<clip>_<s>.png`;
- la hoja `comparar_combate_v2_y_variantes.png`: filas v2, garras, geoda y columnas; columnas reposo (boca cerrada),
  rugido (boca abierta), Aliento y caída de la Fractura.

| Variante | Qué la distingue | Triángulos (alto) |
|---|---|---|
| **garras, el Excavador (ELEGIDA)** | dos brazos de basalto con garras de cristal clavados en el borde del agujero (IK, no patinan), cabeza ancha y pesada con cuernos cortos y púas en las mejillas, placas y racimos de cristal | 9 197 |
| geoda, la Corona de Geoda | sin brazos; la frente y el lomo se abren en geodas, racimos grandes que salen de grietas; cabeza más larga | 8 617 |
| columnas, la Calzada | sin brazos; una cresta de columnas de basalto hexagonales de alturas escalonadas en la cabeza y el lomo | 9 113 |

**Por qué «garras»:**
1. **Es la que deja de ser un gusano.** Con brazos y garras apoyadas en el borde del agujero, se lee como una bestia
   que sale de la arena, no como un tubo. Geoda y columnas siguen siendo sierpes con adornos.
2. **Tiene más peso y personalidad en las animaciones:** clava las garras para la embestida, levanta los brazos y
   golpea el suelo con las dos en la Fractura, da un manotazo al final del rugido y los brazos caen sin fuerza en la
   derrota.
3. **Pies apoyados de verdad.** Las garras están ancladas en el mundo con IK de dos huesos; en el reposo la muñeca se
   mueve 1,9 cm como mucho (medido).
4. **Su silueta funciona en pantalla pequeña:** cabeza ancha con cuernos y púas, y garras abajo a la izquierda.

**Lo que conservan las otras dos:** geoda tiene la corona más llamativa (si el usuario quiere más cabeza, se puede
añadir un racimo en la frente a «garras» con una línea del generador). Columnas tiene la silueta de lomo más fuerte. Las
dos se regeneran con el mismo guion.

**Lo que evité para no copiar:**
- nada de boca en pétalos ni anillos de dientes;
- nada de corona de cuernos ni de bigotes o aletas de pez en la cabeza;
- las columnas son basalto hexagonal (geología), no las placas dorsales de un monstruo conocido.

## 4. El modelo final (`enemigos/bramavidrio/v3/`)

**Se regenera con:**
`blender -b --factory-startup -P fuente/crear_bramavidrio3.py -- aethelgard/enemigos/bramavidrio/v3 alto,medio,bajo [<.blend>]`
Tarda unos 40 s.

| Versión | Triángulos | Techo (los de la v2) | GLB | Textura WebP |
|---|---|---|---|---|
| alto | 9 197 | 15 197 | 2,60 MB | 2048, 565 KB |
| medio | 4 496 | 5 528 | 2,34 MB | 1024, 225 KB |
| bajo | 2 360 | 2 430 | 2,18 MB | 512, 82 KB |

- **Esqueleto de 56 huesos:** raiz, col_01 … col_18, cabeza, mandibula, ceja_izq/der, placa_02 … placa_17 (la armadura
  y los racimos del lomo, que se erizan), brillo, garganta, chorro, succion, monticulo, losa_1 … losa_6, y
  hombro/codo/mano a cada lado.
- **Contrato:** los mismos 10 clips, duraciones e instantes que la v1/v2. Las señales `placas_suelo` y `fin_succion`
  de la v2 siguen.
- **Instantes ajustados por el generador** para que caigan en el fotograma del contrato con la cabeza nueva:
  - `rompe_arena` a 0,2333 s, con `emerger_ua` = −6,25;
  - `pico` a 0,8667 s;
  - impacto de la Fractura a 2,5333 s;
  - `caida` de la derrota a 1,6 s;
  - impacto de la embestida a 1,0 s.
- **Alcances:** embestida 12,73 m, Fractura 18,21 m y Aliento 18,64 m (la v2: 11,76, 16,69 y 17,99). Son 0,3 a 0,6 m
  más en el combate; los efectos de `combate_bramavidrio.gd` siguen a `cabeza()` y `boca()`, así que se adaptan solos.
- **En reposo** la cabeza está a 9,03 m de alto (igual que la v2) y 10,09 m por delante del agujero (la v2: 9,42).
- **Placas del suelo:** las centra el generador donde cae el hocico en la Fractura (y = −16,9).

**Clips:**
- **reposo:** respira (el cuello sube y baja), se mece y vigila a los héroes, ladeando la cabeza sin barrer de lado a
  lado. El ceño late, la armadura ondula y las garras están quietas en el suelo. La boca está cerrada.
- **ataque (la Embestida del Abismo):**
  - se recoge con la boca cerrada y las garras clavadas;
  - fija al objetivo temblando, con el ceño fruncido;
  - se lanza acelerando con los brazos por delante, abre las fauces a mitad de camino y las cierra de golpe en el
    impacto (1,0 s);
  - sacude la presa dos veces, tira de la cabeza hacia atrás y vuelve a clavar las garras donde estaban.
- **ataque_sismico (la Fractura del Mar de Cristal):**
  - se alza a 21,8 m con los brazos en alto y ruge arriba;
  - se echa atrás y se desploma como una torre, acelerando;
  - la cabeza (cerrada) y las dos garras golpean a la vez (2,5333 s), las placas saltan y el cuerpo vibra;
  - las garras se levantan antes de volver a su sitio (no patinan).
- **ataque_aliento (el Aliento del Desierto Eterno):** abre despacio y se afianza con las garras. Aspira con la arena
  en cintas y la garganta encendida, cierra un poco al acumular (1,7 s), escupe con las fauces abiertas del todo
  (1,85 s) barriendo de −16° a +16°, y cierra.
- **rugido:** toma aire con la boca cerrada, se enrosca y lanza la cabeza. Ruge con las fauces, el ceño y los brazos en
  alto, cierra de golpe y da un manotazo con las dos garras (2,18 s).
- **emerger:** sube en columna con la boca cerrada y los brazos plegados, se presenta arriba con los brazos abiertos
  y las fauces, cae, clava las garras en el borde del agujero (1,88 s) y acaba exactamente en el reposo.
- **herida:** gruñido corto (16°), las cejas suben, una garra pierde el apoyo y se vuelve a clavar.
- **derrota:** se retuerce, los brazos pierden la fuerza, se desploma de lado y se hunde con la mandíbula floja.
- **subterraneo y aviso:** solo asoman los racimos del lomo; los brazos van plegados.

**Aturdimiento:** no hay clip nuevo, porque el contrato tiene 10 clips fijos y la prueba lo exige. Si el combate quiere
uno, se puede añadir como clip 11 con su instante (pendiente).

**Guion `v3/bramavidrio3_3d.gd`:**
- es copia de la v2, con la misma interfaz y las mismas señales;
- `cierre_boca()`, `angulo_boca()` y `borde_sobre_labio()`, para las pruebas;
- `puntos_profundidad()` y `ordenar_en_combate(c, f)`, para el orden de dibujo (§5);
- para las fotos de las variantes, puede cargar un GLB de fuera del proyecto: `Engine.set_meta("bramavidrio3_glb", …)`
  y `"bramavidrio3_textura"`. En el juego no se usa.

**Cómo se elige la v3:**
- en Ajustes → «Bramavidrio» → «Prueba v3: el Excavador» (`[bramavidrio] version = 3`);
- en las pruebas, `-- bramavidrio_version=3` o `Engine.set_meta("bramavidrio_version", 3)`.

Para hacerla la de por defecto, basta `const VERSION_DEFECTO := 3` en `bramavidrio_version.gd`; no lo he cambiado.

## 5. Héroes dibujados encima del cuerpo: causa y arreglo

**Causa** (observada en `combate.gd`):
- Cada luchador 3D se dibuja en su propia ventana 3D (`_crear_rig_3d`: `own_world_3d`, fondo transparente), y esa
  imagen entra en la escena 2D como un `Sprite2D`. **No hay profundidad compartida:** manda el orden del árbol y el
  `z_index`.
- El gusano se crea **antes** que los héroes (`for f in enemigos + heroes`, `_crear_interfaz`), así que queda siempre
  detrás aunque su cabeza o su cuello pasen por delante.
- El héroe que actúa sube a `z_index = 5` (`_anim_fisico_3d`, `_anim_salto_3d`, `_anim_ataque_3d`…) y se pinta encima
  de todo.
- `combate_bramavidrio.gd` solo lo adelanta (`_al_frente`) en la embestida y en la caída de la Fractura, y mirando solo
  el hocico. En el Aliento, el rugido, la herida, la emersión y los turnos de los héroes no lo adelanta.

**No es** un material transparente: los sombreadores de la piel y del vidrio son opacos. Tampoco es la cámara.

**Arreglo** (en mi guion, sin tocar el combate): `ordenar_en_combate(c, f)`.
- Proyecta varios tramos del cuerpo (hocico, mandíbula, cuello en cinco tramos y garras) y su sombra en la arena con la
  misma cámara del combate.
- Pone al gusano delante de cada héroe al que tapa un tramo más cercano a la cámara (su sombra más abajo en pantalla
  que los pies del héroe) que cae encima de él en horizontal.
- Toma el `z_index` más alto de esos héroes (el 5 del que actúa). Sin héroes tapados, vuelve a su sitio y a
  `z_index` 0.
- **Comprobado con el combate congelado:** en `combate_v3\v3_<clip>_<s>_antes.png` (el orden de ahora) frente a
  `..._despues.png` (el propuesto). En el mordisco, Garon y Kael ya no se pintan encima de la cabeza
  (`v3_ataque_1.00_*`). Pasa lo mismo en el rugido, el Aliento a 1,2 s y la caída de la Fractura.
- **Lo que falta:** no se ha probado en un combate que corre, porque no puedo editar `combate_bramavidrio.gd`.

**Cambio exacto que pido en `combate_bramavidrio.gd`** (lo aplica el coordinador; no toca la v1 ni la v2):
1. En `_process()`, líneas 1515-1516 de `373e7db`, sustituir:
   ```gdscript
   	if _frente:
   		_ordenar(_suelo_cabeza().y)
   ```
   por:
   ```gdscript
   	var p_orden = c._p3d(f)
   	if p_orden != null and p_orden.has_method("ordenar_en_combate"):   # v3: por profundidad de todo el cuerpo
   		p_orden.ordenar_en_combate(c, f)
   	elif _frente:
   		_ordenar(_suelo_cabeza().y)
   ```
2. En `_al_frente()`, línea 963, al principio de la función, para que la v3 no salte un fotograma al sitio de antes:
   ```gdscript
   	if c._p3d(f) != null and c._p3d(f).has_method("ordenar_en_combate"):
   		return
   ```

## 6. Pruebas (aisladas; la partida y la carpeta real, sin cambios)

- `prueba_bramavidrio_modelo` (las tres versiones), `prueba_bramavidrio_combate` y `prueba_climax_jefe` con
  `bramavidrio_version=3`: **3 SUPERADAS**. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_230552\resumen.md`.
  - «proyecto: CAMBIADO» en esa pasada se debe a que hice el commit del generador mientras corría; los otros Godot
    abiertos eran de otras copias.
- Con `bramavidrio_version=2`: combate y clímax **SUPERADAS** (`2026-11-11_230645`).
- Con `bramavidrio_version=1`: combate y clímax **SUPERADAS** (`2026-11-11_230737`).
- `prueba_bramavidrio_modelo version=3` sola: **SUPERADA** (`2026-11-11_230049`).
- `prueba_mar_cristal` con `bramavidrio_version=3` (la exploración, con el aviso, la huida y la emersión de Bramavidrio): **SUPERADA** (`2026-11-11_231212`). Su registro no dice qué modelo carga; el interruptor elige la v3 por el argumento, y la prueba del modelo comprueba la v3 en la exploración (escala 1, subterraneo, vibrar, emerger y rugir). «proyecto: CAMBIADO» de nuevo por mis ediciones durante la pasada.
- Capturas con ventana (`fotos_bramavidrio3`, MANUAL): `2026-11-11_230312` (v3 con el orden antes y después) y
  `2026-11-11_230403` (v2 y las variantes).

## 7. Evidencias (`D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio3\`)

- `variantes\`: las fotos de Blender de cada variante, sus hojas y `comparativa_variantes.png`.
- `comparar_combate_v2_y_variantes.png`: el combate real (v2 y las tres variantes, en reposo, rugido, Aliento y
  Fractura).
- `combate_v3\`: la v3 final en el combate real, en 13 instantes, con el orden de dibujo antes y después.
- `combate_v2\` y `combate_variantes\`: lo mismo para la v2 y las variantes (sin el orden).
- `blender\`: hojas de clips.
  - `boca_rugido_cerca.png`: la boca se abre y se cierra en 8 instantes.
  - `embestida_combate.png`, `fractura_combate.png`, `aliento_combate.png` y `emerger_herida_derrota.png`, con un
    muñeco a la escala del combate.
- `region\`: la v3 en el Mar de Cristal (alto y bajo), con el aviso, la emersión, el rugido y la vuelta.
- `video\`: vídeos a velocidad real hechos con el FFmpeg de Blender: `v3_boca_cerca.mp4` (reposo, rugido, embestida,
  Aliento y herida, de cerca) y `v3_combate.mp4` (la vista del combate).

## 8. Lo que falta o no está comprobado

- **Redmi:** nada probado ni medido.
  - Los triángulos de la v3 están por debajo de la v2 en los tres perfiles.
  - Lo nuevo es la IK horneada, que no cuesta nada en tiempo de juego, y 4 huesos más (56 frente a 52).
- **El orden de dibujo en un combate que corre:** depende del cambio de §5.
- **Visto en el PC:**
  - con el combate congelado (seek) y en vídeos de Blender;
  - no he grabado con `--write-movie` el combate de Godot corriendo con la v3.
- **La exploración con la v3** pasa `prueba_mar_cristal`.
  - Fotos de la región en `region\region_{alto,bajo}.png` (`fotos_bramavidrio solo=region bramavidrio_version=3`): los racimos cortan la arena en el aviso, emerge, clava las garras en el borde y ruge con la boca abierta, y vuelve con la boca cerrada.
  - A 34 m, la bruma del desierto agrisa el basalto, igual que con la v1 y la v2.
- **Sonidos propios** del manotazo de las garras (rugido y Fractura): son del especialista de sonido.
  - El rugido da con las garras en el suelo a 2,18 s.
  - La emersión las clava a 1,88 s.
  - Ninguno de los dos tiene señal; si sonido la quiere, se añade como instante nuevo.
- **Procedencia:** falta la fila en `docs/recursos.md`, que no es mío. La que pido:
  `| Bramavidrio v3 «el Excavador»: enemigos/bramavidrio/v3/* | Obra propia: modelo, textura, esqueleto y clips generados con Blender 5.2.3 por fuente/crear_bramavidrio3.py | Propia | Combate fijo «mc_bramavidrio» y exploración del Mar de Cristal (si se elige la versión 3) | Sí |`
- **Narrativa:** la v3 tiene brazos con garras, cosa que el canon de `NARRATIVA_DESIERTO.md` §4 no menciona. Conviene que
  narrativa lo revise antes de hacerla la de por defecto.
- **La foto 2D de respaldo** (`bramavidrio2d`) sigue siendo la del modelo provisional.
- **El `.blend` del modelo** está fuera del historial, en la carpeta temporal de la sesión: `bramavidrio3.blend`. Se
  regenera con el guion.
