# Combate, V12: los efectos de Bramavidrio v2 y la superposición con los héroes

## 11/11/2026, 21:45 · rama `claude/v12-bramavidrio2-efectos` (LOCAL, nace de `claude/rebelum-v12` @ `3699144`)

Encargo (coordinador, con las palabras del usuario): más espectáculo en los tres ataques de Bramavidrio con la v2
«la Sierpe de la Vela» (Embestida rápida y violenta con anticipación; Fractura con temblor, placas, arena levantada y
peso; Aliento que succiona arena del suelo y suelta un chorro que barre a los tres), arreglar la superposición con los
héroes (dentro de la mandíbula en los cuerpo a cuerpo, encima del gusano caído en la victoria, la cabeza de la v2 sobre
Kael y Garon), sin bajar de ~45 FPS en el Redmi y con la v1 funcionando. Copia `D:\Aethelgard_v12_brama_efectos`.

**Estado:** hecho y probado en el PC (aislado; sin ventana las pruebas, con ventana las capturas), con la v2 y con la
v1. **Nada probado en el Redmi: ni FPS ni lectura en pantalla pequeña.** Ni daños, ni fórmulas, ni IA, ni turnos
cambian (las pruebas de patrón, de daño defendido y de sonidos una vez siguen pasando).

### Commits

| Commit | Qué |
|---|---|
| `98f9420` | `aethelgard/combate.gd`: `GRUPOS[13]` (288, 600) → (108, 600); `MODELOS["bramavidrio"]["pies_golpe"]`; `_sitio_golpe` y sus ganchos en `_crear_rig`, `_anim_fisico_3d` y `_anim_ataque_3d` (todo marcado «V12, Bramavidrio v2») |
| `50978a7` | `aethelgard/combate_bramavidrio.gd`: los efectos, el orden de dibujo y la derrota |
| `d4ab368` | `aethelgard/pruebas/prueba_bramavidrio_combate.gd`: las comprobaciones nuevas y más capturas |
| este | este informe |

Para integrar copiando: esos tres archivos. Ningún `.uid` nuevo (no hay archivos nuevos de código). `combate.gd` cambia
en 29 líneas; si en la V12 ha cambiado mientras tanto, los ganchos son los cuatro bloques «V12, Bramavidrio v2».

## 1. Qué hay y en qué instante (observado en el código y comprobado ejecutando, 11/11)

Todo son efectos 2D temporales en la capa del combate (`combate_bramavidrio.gd`), con el modo móvil de siempre
(`c.movil`, `c.calidad` 0,4 y cantidades propias para el móvil en cada emisor). Los instantes se leen del clip del modelo
en curso (`_en_instante`: el clip llega a ese segundo; si no llega, un límite de 8 s de juego) o de sus señales. Con la
v1 salen los mismos efectos en los mismos instantes (sus clips tienen los mismos tiempos; donde la v1 no tiene la señal,
se usa el instante del clip).

| Ataque | Instante (clip) | Qué se ve |
|---|---|---|
| Embestida | `anticipacion` 0,2 | arena que le resbala del cuello, polvo que se levanta en el agujero, retumbo leve (2,5 px) |
| | `fijado` 0,55 | destello en su cabeza (el anillo rojo y «⚠» sobre el objetivo, como antes) |
| | 0,8 (se lanza) | se dibuja delante de los héroes que quedan detrás de su hocico; estela de arena hacia el objetivo; si el objetivo está más lejos de donde llega su hocico (Lya), su dibujo avanza sobre la arena lo que falta (como mucho 160 px de escena, ~118 de pantalla) levantando un surco, y vuelve a su agujero en 0,9 s |
| | `impacto` 1,0 | golpe de arena a los pies del alcanzado (abanico, terrones, polvo bajo y onda), arena que salta del hocico, empujón y sacudida con peso (8 px, vertical); el golpe sordo `gusano_temblor`, una vez |
| Fractura | `caida` 2,1 | se dibuja delante de los héroes que quedan detrás de su cabeza; su sombra crece en el suelo donde va a dar |
| | `impacto` = `placas_suelo` 2,5333 | sacudida pesada (16 px, cae y rebota) con réplica a 0,3 s (6 px); grietas en el suelo; placas de costra que saltan, chocan y tiemblan (7; 4 en el móvil); nube de arena a ras de suelo bajo los héroes; esquirlas de vidrio; dos ondas; a 0,3 s, terrones que caen sobre los héroes. En la v2 las placas salen con la señal `placas_suelo`; en la v1, con el golpe |
| | `placas_asientan` 3,1 | las placas se hunden con un soplo de polvo en su base, el polvo de la nube se posa sobre el grupo, retumbo leve |
| | `placas_fin` 3,65 | no queda nada en pie; la nube acaba de disiparse |
| Aliento | `succion` 0,45 (en el turno del aviso) | arena que sube del suelo (de debajo de su cabeza hasta más allá de los héroes) a su boca en motas alargadas, polvo que se levanta, la garganta encendida; los héroes se inclinan hacia él (solo su dibujo, 4-9 px) |
| | `fin_succion` 1,7 | deja de aspirar y los héroes vuelven a su sitio (v2: la señal; v1: el instante del clip) |
| | `impacto` = `descarga` 1,85 → `fin_descarga` 2,6 | un chorro de arena ocre casi opaco de su boca que BARRE a los vivos de delante atrás (Garon → Kael → Lya) en 0,75 s: cuerpo, grano que hierve, sombra y dos corrientes (el móvil sin sombra ni corrientes), núcleo claro, la nube donde rompe, rayas de arena a toda velocidad y granos; al alcanzar a cada uno, salpicadura, lo arrastra mientras le da y le cae arena encima; velo de arena (0,16) y sacudida (9 px). El daño se resuelve en el golpe, una vez, como antes |
| Derrota | al morir | se retuerce hacia atrás (`DIR_DERROTA`) mientras se desploma y cae detrás de los héroes |
| | `caida` 1,6 | arena que salta a lo largo del cuerpo caído y retumbo |

**Sonidos:** no hay ninguno nuevo. Siguen los mismos y en los mismos fotogramas (`gusano_temblor` en el impacto de la
Embestida y de la Fractura, `Sonido.golpe(true)` en la Fractura y el Aliento, `gusano_rugido` en el Aliento). En
`sonido.gd` no hay ninguno propio y licenciado que encaje (los que hay son de otras bestias). **Faltan** (para el
especialista de sonido): el choque de las placas de la Fractura y su asiento, la succión de arena (bucle corto), el
chorro de arena (ráfaga), el latigazo de la Embestida al lanzarse y el surco de arena cuando avanza.

## 2. La superposición

| Problema (Redmi, v610; captura de animaciones) | Arreglo |
|---|---|
| En reposo, la cabeza (v2) encima de Kael y Garon | **Encuadre:** `GRUPOS[13]` de (288, 600) a (108, 600): 100 px de pantalla más a la izquierda (el agujero en (86, 575)). Mismo tamaño (no pierde presencia). En reposo su hocico queda en x ≈ 466 y Garon empieza en ≈ 490 (comprobado midiendo con la herramienta de encuadre y en capturas) |
| Héroes dentro de la mandíbula al atacarle | **Sitio propio por héroe** (`MODELOS["bramavidrio"]["pies_golpe"]` y `_sitio_golpe` en `combate.gd`): Garon se planta con los pies en (495, 600) de pantalla, a la derecha del hocico; Lya en (450, 650), delante de Garon y bajo su cabeza, sin pisarle; Kael salta (`_anim_salto_3d`) y ya cae a su derecha. Solo cambia con un modelo que lo diga |
| Héroes dibujados encima del gusano cuando él ataca | **Orden de dibujo:** mientras se lanza (Embestida) o cae (Fractura) se dibuja delante de los héroes que quedan detrás de su hocico (en profundidad, sus pies frente al punto del suelo bajo su hocico) y, al acabar, vuelve a su sitio detrás de todos. Se cambia el orden en el árbol, no `z_index`: la vida, el menú y los efectos siguen encima |
| Héroes encima del gusano caído en la victoria | **Derrota:** al morir se vuelve hacia atrás (`DIR_DERROTA` = (0,85, 0, −0,53), 1,3 s, durante el retorcerse) y cae detrás de los héroes y a su izquierda, no encima; se dibuja detrás de todos. Su cabeza caída queda detrás de Garon (la prueba lo mide) |

**Lo que sigue pasando a propósito:** en la Fractura su cuerpo cae delante de Garon y le tapa las piernas ~1,5 s (cae
más cerca de la cámara que él); en la Embestida contra Lya su cabeza pasa por delante de Kael. Es el orden correcto en
profundidad.

## 3. Pruebas (aisladas con `ejecutar_pruebas.ps1`, sin ventana, `--fixed-fps 30`; 11/11, código de `d4ab368`)

**`prueba_bramavidrio_combate` ampliada.** Además de lo de antes (cada turno, patrón, daños defendidos, sonidos una vez
en el fotograma del impacto, corte del Aliento, premio, derrota, dos héroes, automático, tambaleo):
- en cada turno, que se crea cada efecto de ese ataque una vez: Embestida (anticipación, destello, estela, golpe de
  arena), Fractura (sombra, grietas, nube, 7 placas o 4 en el móvil, y `placas_suelo`, `placas_asientan` y
  `placas_fin` una vez cada uno), aviso del Aliento (succión) y Aliento (el chorro una vez y alcanza a cada héroe en
  pie; la succión parada y los héroes ya no inclinados; se inclinaron mientras aspiraba);
- que mientras se lanza o cae se dibuja delante de algún héroe y al acabar su turno vuelve detrás de todos; que tras la
  Embestida su dibujo vuelve a su agujero;
- al vencerle: se ha vuelto hacia `DIR_DERROTA`, se dibuja detrás de todos y su cabeza caída queda detrás de Garon;
- al cerrar cada combate: ningún efecto suyo en la escena (espera a que acaben), el chorro borrado, los dibujos de los
  héroes en su sitio y los nodos huérfanos (`Performance.OBJECT_ORPHAN_NODE_COUNT`) no crecen respecto al principio.

**Resultados:**
- v2, batería de 18: `D:\REBELUM_diagnostico\pruebas\2026-11-11_211955\resumen.md`: **18 SUPERADAS, 0 FALLIDAS**
  (`prueba_bramavidrio_combate`, `prueba_bramavidrio_modelo`, `prueba_climax_jefe`, `prueba_huir`, `prueba_garon`,
  `prueba_grupos_combate`, `prueba_combate_seguro`, `prueba_combate_huella`, `prueba_coloso`,
  `prueba_coloso_garganta`, `prueba_mar_cristal`, `prueba_hud_combate`, `prueba_integridad`,
  `prueba_zarzalin_combate`, `prueba_v11_combate`, `prueba_equipo_combate`, `prueba_patrones_enemigos`,
  `prueba_audio_desierto`).
- v1 (`bramavidrio_version=1`): `D:\REBELUM_diagnostico\pruebas\2026-11-11_212307\resumen.md`: **3 SUPERADAS**
  (`prueba_bramavidrio_combate`, `prueba_bramavidrio_modelo`, `prueba_climax_jefe`).
- v2 en modo móvil (`movil`): `D:\REBELUM_diagnostico\pruebas\2026-11-11_212351\resumen.md`: **SUPERADA**
  `prueba_bramavidrio_combate`.
- En las tres pasadas: partida y carpeta real de datos sin cambios, proyecto sin cambios, ningún otro Godot.
- `prueba_combate_huella` igual: ningún otro enemigo cambia. No he pasado la batería entera.

**Ojo (no es un cambio de reglas):** los efectos ya no llaman a `c._temblor` (que tira del azar global) sino a una
sacudida con azar propio; con la misma semilla, las tiradas del combate pueden salir distintas que antes (en la prueba,
el combate automático F perdió esta vez y ganaba antes). Los daños y fórmulas son los mismos.

## 4. Capturas (`D:\REBELUM_diagnostico\combate\2026-11-11_bramavidrio2_efectos\`)

- **`comparar_antes_izq_despues_der.png`**: antes (izquierda) y después (derecha) en el PC: impacto de la Embestida,
  impacto de la Fractura y su polvo a 0,5 s, Aliento al aspirar, el chorro a 0,23 s y a 0,57 s del golpe, Garon
  golpeándole y el gusano caído en la victoria.
- **`antes\`**: el combate real con la v2 antes de los cambios (27 capturas de la prueba).
- **`despues\`** (v2, PC), **`despues_movil\`** (v2 con `movil`) y **`despues_v1\`** (v1): 47 capturas de cada una con
  la herramienta temporal de mi carpeta (combate real, tres héroes a nivel 10, el Aliento defendido para verlo
  entero): `aviso_aliento` y `_aspira`, `aliento_1_impacto+00…+22` (fotogramas a 30 FPS desde el golpe),
  `embestida_N_se_recoge/_fija/_se_lanza/_impacto+…`, `fractura_cae`, `sismico_1_impacto+00…+22`,
  `kael/lya/garon_ataca_golpe`, `derrota_caida`, `derrota_suelo` y `victoria`.
- **`encuadre\` y `encuadre_giros\`**: las opciones de encuadre (actual, −100 px, −80 px a 1,0, −60 px a 0,95) y de giro
  de la derrota y la Fractura con las que elegí (hojas `hoja_*.png`).
- **`intermedias\`**: pasadas de trabajo (y las fotos de la primera pasada de encuadre, que un fallo de mi lanzador dejó
  en la carpeta del proyecto: las saqué antes de confirmar nada).

## 5. Rendimiento (lo que se sabe y lo que no)

**Medido (PC, sin ventana):** partículas en CPU vivas a la vez como mucho, contando las del combate: 251-314 en el PC y
**109-127 con `movil`** (antes, según mi informe anterior: ~180-350 y ~86-200).

**No medido: el Redmi.** Lo que más cuesta a su GPU es el relleno de transparencias. Estimación (no medida): el chorro
cubre ~0,2 de pantalla por capa durante 0,75 s; en el móvil son cuerpo, grano y núcleo (sin sombra ni corrientes), unas
0,6 pantallas de relleno, más el velo de arena (una pantalla a 0,16, ya existía). La nube de la Fractura son 9 motas
grandes en el móvil (~0,35 pantallas) durante ~2 s. Con 53-58 FPS de partida, calculo que no baja de ~45, pero hay que
medirlo: FPS en el golpe de la Fractura, en el chorro y en la Embestida con avance, en los tres perfiles.

## 6. Lo que falta o no está comprobado

- **Redmi:** FPS (arriba), cómo se lee el chorro y la nube en pantalla pequeña, y el avance de la Embestida contra Lya
  (su dibujo entero, base incluida, se desliza hasta 118 px y vuelve: en el PC se lee como que se lanza sobre la arena,
  pero es lo más discutible a ojo; si no gusta, `ALCANCE_EXTRA = 0` lo quita y entonces muerde delante del grupo).
- **Sonido:** nadie lo ha escuchado; faltan sonidos propios (§1).
- **Visto en fotogramas sueltos**, no a velocidad real ni en vídeo.
- **Kael** al golpearle sigue con su salto de siempre (cae a la derecha del hocico; no lleva sitio propio).
- **Las placas 2D** son polígonos sencillos; las de verdad son las 6 losas 3D del modelo, junto a su cabeza (que en la
  Fractura cae abajo a la derecha, en parte bajo el panel de vida). Mejorables con una textura.
- **El respaldo 2D** (`bramavidrio2d`, sin GLB) no tiene prueba: los efectos con modelo se saltan sin él y los golpes
  van como antes.
- **Controles** (táctil, teclado, mando) contra este combate: no simulados; el menú y el cartel no cambian.

## 7. Siguiente paso y peticiones a otros

1. **Coordinador:** integrar copiando los tres archivos; medir en el Redmi (§5) y enseñar al usuario el chorro y el
   avance de la Embestida.
2. **Sonido** (`sonido.gd`, no es mío): los cinco sonidos de §1. Los ganchos ya existen en los instantes (dónde
   llamarlos: `_placas_suelo`, `_placas_asientan`, `_empezar_succion`/`_parar_succion`, `_chorro_barrido`,
   `_lanza_embestida`/`_deslizar`); habría que actualizar los recuentos de sonidos de la prueba.
3. **Animaciones:** si se quiere que la Fractura caiga a la vista (hoy la cabeza da abajo a la derecha, a ~(764, 786)
   de pantalla, en parte fuera), un alcance algo menor del clip `ataque_sismico` en la v2.
