# Animaciones (y modelado), V12: Bramavidrio versión 2, «la Sierpe de la Vela»

## 11/11/2026, 20:30 · rama `claude/v12-bramavidrio2` (LOCAL, nace de `claude/rebelum-v12` @ `63832d4`)

**Encargo del usuario (11/11):** el Bramavidrio actual no le convence. Pega poco con el juego y parece un «gusano
genérico / larva por segmentos». Pide un rediseño de fantasía JRPG clásica con el espíritu de FFIX, **sin copiar nada**.
Quiere más cabeza, mandíbula, cristales integrados, basalto, arena y turquesa, una silueta clara y más elegancia. También
pide animaciones con peso para la embestida, la Fractura (con placas del suelo) y el Aliento (succión y chorro). La v1
no se pierde: un solo interruptor elige la versión.

Copia `D:\Aethelgard_v12_bramavidrio2`. Todo es **obra propia**: geometría, textura, esqueleto y clips hechos con
Blender 5.2.3 por guion. No hay recursos de terceros ni se ha copiado ningún diseño.

**Estado:**
- La v2 está hecha, integrada y probada en el PC, en combate y en exploración. Es la versión **por defecto**.
- La v1 sigue intacta y se recupera con un interruptor.
- **Nada se ha probado en el Redmi** y no se ha medido el rendimiento.

### Commits

| Commit | Qué |
|---|---|
| `6d019ff` | `fuente/crear_bramavidrio2.py` (las tres propuestas y el modelo elegido) y `fuente/capturas_bramavidrio2.py` |
| `3d6bc4d` | `enemigos/bramavidrio/v2/`: los tres GLB, las tres texturas WebP (con sus `.import`) y `bramavidrio2_clips.json` |
| `618af46` | `v2/bramavidrio2_3d.gd`, los 4 sombreadores de la v2 (con sus `.uid`) y `enemigos/bramavidrio/bramavidrio_version.gd` (el interruptor) |
| `6424aae` | `combate.gd` (3 líneas) y `zonas3d/mar_cristal/gusano.gd` (2 líneas): eligen la versión |
| `eba680f` | `pruebas/prueba_bramavidrio_modelo.gd` (las dos versiones y el interruptor), `fotos_bramavidrio.gd`, `fotos_bramavidrio_combate.gd` y `lista_pruebas.txt` |
| `35fc80e` | el vientre corregido (texturas regeneradas) y `emerger`, que ahora acaba exactamente en el reposo |
| `30bdbc4` | `v2/bramavidrio2_chorro.gdshader`: el chorro escondido ya no se dibuja (antes salía un cono negro) |
| este | este informe |

**Archivos de la v1 que no he tocado:** `bramavidrio*.glb`, `bramavidrio_piel*.webp`, `bramavidrio_3d.gd`,
`bramavidrio_*.gdshader`, `bramavidrio_clips.json` y `fuente/crear_bramavidrio.py`.

## 1. Las tres propuestas

Las láminas están en `D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio2\conceptos\`:
- `lamina_sierpe.png`, `lamina_tragador.png` y `lamina_capuchon.png`. Cada una tiene la silueta de perfil, la silueta de
  tres cuartos con la vista del combate, una vista a color con materiales provisionales, la cabeza y la espalda.
- `comparativa_conceptos.png`: las tres juntas.
- `render\`: cada imagen suelta.

**Cómo se hicieron las láminas:**
- Las tres están en la misma pose, con la misma luz y la cámara del combate (el gusano mira a los héroes, a la derecha).
- Llevan un muñeco gris a la escala con la que se ven los héroes en el combate. Ahí el gusano va a 0,32 y los héroes son
  mucho más grandes en proporción que en la exploración.
- Se regeneran con `blender -b --factory-startup -P fuente/crear_bramavidrio2.py -- <carpeta> conceptos`.

**A. La Sierpe de la Vela (la elegida).**
- **Cuerpo:** de sierpe, se afina hacia la cola y **no tiene anillos**. Lleva escamas de basalto escalonadas (cada fila va
  desplazada media escama), un vientre de arena gastada y una «línea lateral» de cristalitos que brillan.
- **Lomo:** una **vela** de espinas de cristal unidas por una membrana de vidrio con el borde en festón.
- **Cuello:** dos aletas de remo a los lados.
- **Cabeza:** de basalto, pesada, con una ceja que hace una «V» enfadada y un ojo grande de pupila en rendija. Tiene dos
  cuernos que barren hacia atrás y hacia fuera (no son una corona) y dos colmillos de cristal que cuelgan por fuera de la
  barbilla.
- **Mejillas:** dos abanicos de vidrio que se abren al rugir y al aspirar.

**B. El Gran Tragador.**
- Cabeza enorme de boca ancha, con un peine de láminas de cristal que filtra la arena.
- Colmillos que suben de la mandíbula.
- Tres macizos de cristal en el lomo y aletas de remo.

**C. La Cobra Vitral.**
- Una capucha de basalto en el tramo erguido del cuello, con vidrieras de colores por delante.
- Cabeza en punta de flecha y dos colmillos de cristal que suben de la mandíbula.

**Por qué A:**
1. **Es la única con una silueta clara en todas las vistas.** La vela le da un perfil propio de perfil, de tres cuartos y
   de espaldas. B se lee como «cabeza grande con cristales» y C solo funciona de frente: de perfil es una sierpe lisa.
2. **Deja de ser una larva.** El cuerpo no tiene anillos, se afina, tiene contrasombra (oscuro arriba y arena abajo) y su
   cabeza es más ancha que el cuello. Así se lee como un animal y no como un tubo.
3. **El cristal está integrado y no pegado.** Los cristales forman la vela, la línea lateral, los abanicos y las vetas, y
   todos se animan: la vela se eriza, ondula y se apaga. En B los macizos seguían siendo «racimos encima». Una hilera
   continua de B, además, recordaba demasiado a las placas dorsales de un monstruo de cine muy conocido; por eso la dejé
   en tres macizos.
4. **Sirve al juego.**
   - Bajo la arena, la vela plegada corta el surco como una aleta, y eso es un aviso que se lee de lejos (comprobado en
     la región).
   - Al cargar ataques, la vela se eriza y se enciende.
   - En la Fractura vibra con el golpe.
5. **Encaja con Kael, Lya y Garon.** Tiene colores limpios y pocos (basalto azul oscuro, arena y turquesa), formas
   grandes que se leen pequeñas y una cara expresiva. C tenía el encanto de las vidrieras, pero su capucha parecía un
   farol pegado al cuello.

**Lo que evité a propósito para no copiar:**
- Nada de aletas de pez ni bigotes en la cabeza: es lo que haría pensar en la serpiente marina de la saga.
- No hay boca en pétalos ni anillos de dientes (nada de Dune).
- No hay corona de cuernos ni una hilera dorsal continua de placas de cristal.
- La vela es de espinas de cristal con membrana y sale del basalto, no es una aleta de pez.

## 2. Modelo (`fuente/crear_bramavidrio2.py`)

**Cómo se regenera:**
`blender -b --factory-startup -P fuente/crear_bramavidrio2.py -- aethelgard/enemigos/bramavidrio/v2 alto,medio,bajo [<.blend>]`
Tarda unos 30 s, usa la misma semilla y da el mismo resultado: al regenerar, los GLB salieron idénticos byte a byte.

**Lo que reutiliza de la v1:**
- la «spline IK» horneada (la curva de columna integrada desde el agujero);
- el pintor de la textura con numpy;
- el alfa mínimo de 0,04 en la textura WebP (la causa se demostró en la v1);
- la exportación.

**Lo nuevo:**
- **Tubo continuo.** Pesos lineales entre los centros de los huesos de la columna, sin anillos.
- **Escamas de relieve.** En el alto son 5 filas escalonadas y en el medio, 2. Se doblan con el tubo.
- **La vela.** Unas 24 espinas de cristal y una membrana de dos caras. Lo alto de la membrana sigue a `placa_kk`.
- **Aletas y abanicos.** Las aletas del cuello van con los huesos nuevos `aleta_izq` y `aleta_der`. Los abanicos de las
  mejillas, con `mandibula_izq` y `mandibula_der`.
- **Línea lateral** de cristales.
- **Cuernos, púas del pómulo y de la barbilla.**
- **Ojos** de almendra con una pupila en rendija hecha con colores de vértice.
- **6 placas del suelo** (`losa_1` … `losa_6`) alrededor del punto donde cae la cabeza en la Fractura.
- **Cintas de arena aspirada** (hueso `succion`, superficie `polvo`).
- **La cara de atrás de las membranas** lleva vértices propios. Con los mismos vértices la malla «no era válida» al
  exportar.

**Textura (2048, con atlas):**
- **El cuerpo:**
  - escamas en rejilla escalonada, con sombra bajo la escama de delante, el canto de atrás gastado y arena en las juntas;
  - un vientre de placas de arena irregulares;
  - la línea lateral encendida y vetas de cristal en el lomo.
- **El resto:** losas de escama, cráneo (la ceja gastada, escamas pequeñas, cuencas oscuras y vetas que brillan bajo el
  ojo), mandíbula (basalto por los lados y arena estriada por debajo), carne, arena y roca de las placas.

**Por versión:**

| Versión | Triángulos (Blender / Godot) | Techo (los de la v1) | GLB | Textura WebP |
|---|---|---|---|---|
| alto | 15 197 / 15 197 | 19 359 | 2,68 MB | 2048, 511 KB |
| medio | 5 528 / 5 528 | 8 823 | 2,13 MB | 1024, 210 KB |
| bajo | 2 430 / 2 430 | 3 124 | 1,92 MB | 512, 76 KB |

- **El medio y el bajo** quitan las escamas de relieve (el bajo, todas), reducen los lados y las filas, la membrana y los
  dientes, y no llevan línea lateral de relieve (el bajo).
- **Los GLB** pesan sobre todo por la animación: 52 huesos × 10 clips muestreados en cada fotograma, como en la v1.

## 3. Esqueleto: 52 huesos

- **Los 43 de la v1, con los mismos nombres:** `raiz`, `col_01` … `col_18`, `cabeza`, `mandibula`, `mandibula_izq` y
  `mandibula_der` (ahora mueven los abanicos de las mejillas), `placa_02` … `placa_17` (ahora, la vela), y los de datos
  `brillo`, `garganta`, `chorro` y `monticulo`.
- **9 nuevos:**
  - `aleta_izq` y `aleta_der`: las aletas del cuello, hijas de `col_04`;
  - `succion`: un dato por su escala (0,01 escondida), hijo de `cabeza`;
  - `losa_1` … `losa_6`: escala 0,01 cuando están escondidas; se levantan e inclinan con traslación y giro.

## 4. Clips: el mismo contrato que la v1

Son los mismos 10 nombres, con las mismas duraciones e instantes. Los instantes que se miden en el clip caen en el mismo
fotograma que en la v1, y el generador avisa si no:
- impacto de la embestida a 1,0 s;
- impacto de la Fractura a 2,5333 s;
- `rompe_arena` a 0,2333 s y `pico` a 0,8667 s;
- `caida` de la derrota a 1,6 s.

**Instantes nuevos** en `bramavidrio2_clips.json` y en `INSTANTES`:
- `ataque.anticipacion` (0,2);
- `ataque_sismico.placas_suelo` (2,5333), `placas_asientan` (3,1) y `placas_fin` (3,65);
- `ataque_aliento.fin_succion` (1,7).

**Alcances:** embestida 11,76 m, Fractura 16,69 m y Aliento 17,99 m. En la v1 eran 11,52, 17,0 y 17,0.

**Cada clip:**
- **`reposo`:** el cuello se mece en S, la cabeza vigila de un lado a otro, la vela ondula de la nuca a la cola, las
  aletas reman y los abanicos laten. Cierra el bucle a los 3 s.
- **`ataque` (la Embestida del Abismo):**
  - **0 a 0,55 s:** se recoge hacia atrás y abajo, con la vela y las aletas pegadas (la anticipación).
  - **0,55 a 0,8 s:** tiembla fijando al objetivo.
  - **0,8 a 1,0 s:** se lanza acelerando (curva cúbica); abre las fauces y los abanicos a mitad de camino y **las cierra
    de golpe en el impacto**. La inercia echa la vela hacia delante.
  - **Después:** dos sacudidas de cabeza (desgarra) y vuelve.
- **`ataque_sismico` (la Fractura del Mar de Cristal):**
  - **Se alza** a lo más alto (21 m) con la vela erizada y las aletas abiertas, y ruge arriba sacudiéndose.
  - **De 2,0 a 2,1 s** se echa atrás: es la anticipación de la caída.
  - **Se desploma** como una torre, acelerando, hasta dar con la cabeza delante de los héroes (2,5333).
  - **En el golpe:**
    - las **6 placas del suelo** saltan e inclinan alrededor de la cabeza, chocan y tiemblan cada una a su ritmo;
    - el cuerpo vibra y la vela tiembla;
    - de 3,1 a 3,65 s las placas se asientan y se hunden;
    - por último se levanta.
- **`ataque_aliento` (el Aliento del Desierto Eterno):**
  - **0 a 0,4 s:** baja la cabeza con las fauces y los abanicos abiertos.
  - **0,45 a 1,6 s:** aspira. La **arena sube en cintas** hasta la boca, la garganta y la vela se encienden y el cuello se
    echa atrás tragando.
  - **1,7 s:** deja de aspirar y se recoge.
  - **1,85 s:** escupe hacia delante **barriendo de un lado a otro** (de −16° a +16°: a los tres héroes) hasta 2,6 s.
- **`rugido`:** toma aire con todo plegado, se enrosca hacia atrás y lanza la cabeza pasándose. Ruge con la boca, los
  abanicos, las aletas y la vela abiertos del todo, y rebota.
- **`emerger`:** sube en columna con la vela plegada (corta el aire). Arriba la abre de golpe, con las aletas y los
  abanicos, como presentándose. La cabeza cae por su peso, rebota y acaba **justo** en el reposo.
- **`herida`:** la cabeza salta y se aparta, la vela se encoge y tiembla y la luz parpadea.
- **`derrota`:** se retuerce y la vela se desmorona espina a espina. Se desploma de lado, rebota y se hunde apagándose.
- **`subterraneo` y `aviso`:** solo asoma la vela plegada. En el aviso se yergue, vibra y se enciende.

## 5. Godot e interruptor

- **`enemigos/bramavidrio/v2/bramavidrio2_3d.gd`:** es una copia de la v1 con **la misma interfaz pública**:
  - las señales `ataque_terminado`, `clip_terminado`, `impacto`, `aviso`, `succion`, `descarga`, `fin_descarga`,
    `rompe_arena`, `rugido_pico` y `caida`;
  - `en_exploracion`, `recortar_suelo`, `escala` y `calidad`;
  - `atacar`, `avisar`, `embestida`, `sismico`, `aliento`, `reposo`, `herida`, `morir`, `entrada`, `emerger`, `rugir`,
    `vibrar`, `cabeza`, `boca`, `nucleo` y `centro`;
  - y las variables internas que leen las pruebas (`_clip`, `_entrando`, `_muerta`).
- **Lo que añade:**
  - las señales `placas_suelo` (en el fotograma del impacto de la Fractura) y `fin_succion`;
  - la superficie `polvo` (la arena que aspira), que se ve también en el combate;
  - si recibe la ruta del alto de la v1 (la que pasa `combate.gd`), elige el nivel por el perfil.
- **Sombreadores de la v2:** copias de los de la v1 dentro de `v2/` más `bramavidrio2_polvo.gdshader`. Este mezcla
  normal, no escribe profundidad y sus vetas corren hacia la boca.
- **`enemigos/bramavidrio/bramavidrio_version.gd`: el interruptor.** Por orden de prioridad:
  1. el argumento `-- bramavidrio_version=1` (para pruebas);
  2. `Engine.set_meta("bramavidrio_version", 1)`;
  3. la constante `VERSION_DEFECTO := 2`.

  Si faltan los archivos de la versión pedida, usa la otra.
- **Cómo volver a la v1 en el juego:** poner `const VERSION_DEFECTO := 1` en ese archivo. No hay que cambiar nada más.

### Cambios mínimos en archivos de otros (para integrar copiando, ojo si `combate.gd` ha cambiado en otra rama)

**`combate.gd`, tres líneas** (la entrada de `MODELOS` no cambia):

```gdscript
const BramaVersion := preload("res://enemigos/bramavidrio/bramavidrio_version.gd")   # tras const Brama
var maga = load(BramaVersion.elegir(m["script"])).new()                                # _crear_rig_3d (antes load(m["script"]))
var p = load(BramaVersion.elegir(m["script"])).new()                                   # _doble_3d (antes load(m["script"]))
```

`elegir()` solo cambia el guion de Bramavidrio. Con los demás enemigos devuelve la misma ruta.

**`zonas3d/mar_cristal/gusano.gd`, en `_modelo_gusano()`:** usa `V.guion()` y `V.modelo()` con
`V = load("res://enemigos/bramavidrio/bramavidrio_version.gd")` en vez de `GUION_3D` y `MODELO_3D`.

**`combate_bramavidrio.gd` no cambia.**

## 6. Pruebas (aisladas, sin ventana y `--fixed-fps 30`)

- **Con la v2 (por defecto):**
  - `prueba_integridad`, `prueba_bramavidrio_modelo`, `prueba_bramavidrio_combate` y `prueba_climax_jefe`: las cuatro
    SUPERADAS.
  - Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_202644\resumen.md`.
- **Con la v1 (`bramavidrio_version=1`):**
  - `prueba_bramavidrio_combate` y `prueba_climax_jefe`: las dos SUPERADAS.
  - Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_202745\resumen.md`.
- **En las dos pasadas:** la partida y los datos reales sin cambios; el proyecto sin cambios; ningún otro Godot.
- **`prueba_bramavidrio_modelo`:** 545 comprobaciones y ningún fallo; comprueba las dos versiones. Para la v2, además:
  - 52 huesos;
  - el techo de triángulos de la v1;
  - la superficie `polvo`;
  - placas del suelo solo en la Fractura (salen en 2,53 y se hunden al final);
  - arena aspirada solo en el Aliento (entre 0,45 y 1,7);
  - aletas del cuello abiertas en el rugido;
  - `fin_succion` antes de la descarga;
  - `placas_suelo` en el fotograma del impacto.

  También comprueba el interruptor: por defecto la 2, la meta a 1 y a 2, y que `elegir()` solo toca a Bramavidrio.
- **Fallo encontrado y corregido:** `emerger` acababa en la fase 0,35 s de la respiración, no en el fotograma 0 del
  reposo.
- **Importación:** la primera vació los directorios de Dialogic en `project.godot`, como avisaba la orden. Lo restauré
  con `git restore` y volví a importar. `project.godot` está sin cambios.

## 7. Capturas (`D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio2\`)

- **`conceptos\`:** las láminas (§1).
- **`godot\comparar_combate_real_v1_izq_v2_der.png`:** el combate fijo real (grupo 13) con los tres héroes y la
  interfaz. De izquierda a derecha: la v1, la v2 antes de corregir el vientre y la v2 final.
- **`godot\comparar_<clip>_<s>.png`:** la v1 y la v2 en el mismo instante del combate real, en 8 instantes: reposo,
  anticipación e impacto de la embestida, impacto de la Fractura, succión y chorro del Aliento, rugido y derrota.
- **Otras carpetas de `godot\`:**
  - `v1_antes\`, `v2_vientre_antes\` y `v2_despues\`: las 13 fotos de cada una;
  - `region_y_camara\`: la cámara del combate en los tres niveles (`combate_{alto,medio,bajo}.png`) y el Mar de Cristal
    real (`region_{alto,medio,bajo}.png`): el aviso con la vela cortando el surco, la emersión, el rugido y la vuelta de
    la cámara.
- **`blender\`:**
  - `clips_embestida.png`, `clips_fractura.png`, `clips_aliento.png`, `clips_reposo_rugido_herida.png` y
    `clips_emerger_derrota.png` (anticipación, impacto y recuperación, con un muñeco a la escala del combate);
  - `perfil.png`, `cabeza.png` y `subterraneo.png`.

**Corregido mirando el combate real:**
1. **El vientre.** Unas placas claras, regulares y muy marcadas se leían como los anillos de una larva justo de frente a
   la cámara. Ahora es una franja más estrecha y oscura, de arena gastada, con juntas irregulares y suaves.
2. **Un cono NEGRO durante el Aliento.**
   - **La causa:** el chorro escondido es aditivo y, en la ventana 3D de fondo transparente, un aditivo negro escribe
     alfa.
   - **La v1 tiene el mismo fallo** (foto `godot\v1_antes\combate_propuesta_ataque_aliento_2.10.png`).
   - **En la v2:** el sombreador descarta cuando `fuerza < 0,01`.
   - **En la v1 no lo he tocado** (debe quedar intacta). El arreglo es esa misma línea en
     `enemigos/bramavidrio/bramavidrio_chorro.gdshader`.

## 8. Lo que falta o no está comprobado

- **Rendimiento en el Redmi: nada medido.**
  - La v2 tiene menos triángulos que la v1 en los tres niveles.
  - Lo nuevo es la superficie transparente `polvo` (pequeña, solo mientras aspira) y una membrana de dos caras.
  - Hay que medir el combate y la aparición en los tres perfiles.
- **Efectos del combate** (son del especialista de combate, en `combate_bramavidrio.gd`): engancharlos a las señales
  nuevas.
  - `placas_suelo`: polvo, temblor de la cámara y grietas 2D donde saltan las placas.
  - `succion` y `fin_succion`: partículas de arena hacia la boca, sumadas a las cintas 3D.
  - El barrido del chorro: el 3D se esconde en el combate (decisión de la v1) y lo dibuja `combate_bramavidrio.gd`.
    Ahora la cabeza barre de −16° a +16°, así que quizá convenga que el chorro 2D también barra.
- **Sonidos:** reutiliza los de la v1. Faltan propios para el choque de las placas, la succión, el chorro y el chasquido
  de la vela (especialista de sonido).
- **Narrativa:** el aspecto cambia (vela de cristal, cabeza con cuernos y ojo grande). El canon de `NARRATIVA_DESIERTO.md`
  §4 sigue valiendo: pasta vidrio, el vidrio del lomo brilla y no se monta. Conviene que narrativa lo revise.
- **Procedencia:** falta la fila en `docs/recursos.md`, que no es mío. La que pido:
  `| Bramavidrio v2 «la Sierpe de la Vela»: enemigos/bramavidrio/v2/* | Obra propia: modelo, textura, esqueleto y clips generados con Blender 5.2.3 por fuente/crear_bramavidrio2.py | Propia | Combate fijo «mc_bramavidrio» y exploración del Mar de Cristal | Sí |`
- **Visto solo en fotogramas sueltos, no a velocidad real:** no grabé vídeo.
- **En la región, a 34 m,** la bruma del desierto agrisa el basalto, igual que con la v1.
- **La `foto_bramavidrio.png` 2D de respaldo** (`bramavidrio2d`) sigue siendo la del modelo provisional.
