# Inventario del mundo de REBELUM (V12, 12/11/2026)

Especialista de mundo 3D y NPC, rama LOCAL `claude/v12-mundo` (copia `D:\Aethelgard_v12_mundo`, desde `d8a65d3`).
Sustituye y amplía `docs/inventario_zonas_3d.md` (09/11), que ya no refleja el estado real.

**Leyenda:** **[C]** observado en el código de `d8a65d3` · **[I]** según el informe del especialista que lo hizo (se cita) ·
**[P]** propuesta, no canon, sin aprobar. Nada de esto se ha medido en el Redmi en esta sesión.

**Fuentes:** `mapa.gd` (LUGARES, RUTAS, ISLAS, LUGAR_PASTOS), `regiones.gd` (ids estables), `modo3d.gd` (REGIONES, EN_PRUEBAS,
POR_DEFECTO_2D_ELEGIBLE, EQUIVALENTES), `progreso.gd` (DETALLES, ACTOS), `hallazgos.gd`, `zona.gd` (la zona 2D generada),
las escenas `zonas3d/*`, `ciudad_oakhaven.*`, `garganta.*`, `isla.*`, y los informes `docs/memory/agents/migracion_v12_*.md`,
`rendimiento_v12_gran_bosque.md`, `graficos_v12_desierto2.md`, `narrativa_v12_exploracion.md`, `docs/v12/RETOMAR.md`,
`docs/diseno/ciudades_y_lugares.md` y `docs/v11/HISTORIA.md`.

---

## 0. Resumen en una tabla

| Id (índice) | Lugar | Tipo | 2D | 3D | Estado | Escena 3D |
|---|---|---|---|---|---|---|
| `pastos_verdes` (10) | Pastos Verdes | región | — (solo existe con la exploración 3D) | **sí** | **3D terminada** | `zonas3d/pastos_verdes_3d.tscn` |
| `oakhaven` (0) | Oakhaven | ciudad | `ciudad_oakhaven.tscn` (elegible) | **sí, por defecto** | **3D terminada** (vecinos con figuras provisionales) | `zonas3d/oakhaven_3d.tscn` |
| `garganta_del_diablo` (2) | Garganta del Diablo | mazmorra | `garganta.tscn` (elegible) | **sí, por defecto** | **3D terminada** | `zonas3d/garganta_3d.tscn` |
| `gran_bosque_verde` (1) | Gran Bosque Verde | región | `zona.tscn` (elegible) | **sí, por defecto** | **3D terminada**, con huecos de contenido | `zonas3d/gran_bosque_3d.tscn` |
| `mar_de_arena_de_calid` (4) | Mar de Arena de Calid → Mar de Cristal | región | `zona.tscn` | solo el **primer sector**, **en pruebas** | **3D incompleta / en desarrollo** | `zonas3d/mar_cristal_3d.tscn` |
| `cumbres_de_ciclopea` (3) | Cumbres de Ciclópea | región | `zona.tscn` (generada, «nieve»), la de siempre | primer sector **en pruebas** (`ciclopea3d`, 13/11) | **3D en pruebas** | `zonas3d/ciclopea_3d.tscn` |
| `sunken_city` (5) | Sunken City | ciudad | `zona.tscn` (generada, 4 vecinos genéricos) | no | **sigue en 2D** | — |
| `valle_de_los_ecos` (6) | Valle de los Ecos | región | `zona.tscn` (generada, «yermo») | no | **sigue en 2D** | — |
| `templo_sumergido_de_atlantis` (7) | Templo Sumergido de Atlantis | mazmorra | `zona.tscn` (isla: solo con el Astraea) | no | **sigue en 2D** | — |
| `abismo_de_ceniza` (8) | Abismo de Ceniza | mazmorra final | `zona.tscn` (isla: solo con el Astraea) | no | **sigue en 2D** | — |
| `portal_del_vacio` (9) | Portal del Vacío → Arboleda Mítica | portal / ciudad flotante | `isla.tscn` (fondo pintado de Meshy, 3 vecinos) | no | **sigue en 2D** (pintada a propósito) | — |
| — | Santuario de Humbaba (en el Gran Bosque) | jefe | — | **sí, APAGADO** (`humbaba_v12`) | **en desarrollo** | dentro de `gran_bosque_3d` |
| — | Observatorio de Naira (en el Mar de Cristal) | misión | — | **sí, APAGADO** (`naira_v12`) | **prototipo sin aprobar** | dentro de `mar_cristal_3d` |

Lugares mencionados en la historia que **aún no son jugables** (§5): la Cripta de las Urnas (Oakhaven), el Templo del Cristal
del Cielo (Arboleda), la costa del Océano de Bruma y la Gruta de la Marea, los Acantilados del Abismo Quebrado, la Gruta
del Velo (Pastos), la Escalera del Cielo, la Aldea Rocío, el Collado de Ámbar con la Gruta de los Centinelas, el resto del
Mar de Arena de Calid (la máquina enterrada, las ruinas sepultadas, «el Lente del Sol»), el pico de Glacius Niflheim y el
interior del casco de Sunken City.

---

## 1. Regiones 3D terminadas

Checklist del usuario, una fila por lugar. **Sí** = existe y está enganchado; **parcial**; **no**.

| Requisito | Pastos Verdes | Oakhaven | Garganta del Diablo | Gran Bosque Verde |
|---|---|---|---|---|
| Terreno y relieve | sí: colinas, río, cascada, puente, mirador [C] | sí: altozano de la colina con rampa, ronda en alto [I] | sí: cornisas, puentes P1-P8, abismo, cascada, arena [I] | sí: lomas, cauce y charcas hundidos, loma del mirador [I] |
| Arquitectura | estela, puente de piedra, faroles, mojón | **toda la ciudad 2D**: 27 lugares, muralla, torre, ronda, crematorio, Patio de las Velas, distrito de oficios, posada por dentro [I] | puentes, pilares, levadizo, ascensor, arena de Gorthor | ruinas, campamento, altar, puentes y pasarela |
| Vegetación | densa, con viento y perfiles [C] | árbol milenario, jardines, setos, cipreses | escasa (roca) | 652 árboles de la 2D + 9 árboles viejos + sotobosque [I] |
| Iluminación | día; luz por perfil; cinemática del mirador | hora azul con faroles y ventanas; `brillo_sin_sombras` 1,17 | cañón con contraluz; niebla | haces de luz, bruma verde, manchas de sol |
| Animales | conejos, pájaros que planean, mariposas, **bandadas que reaccionan a Kael** [I] | **no** (la 2D solo tiene datos de fauna; nadie la pone) | casi nada | conejos y pájaros de primitivas (`fauna_simple.gd`) |
| NPC | Tilo, Rosa (lavanda), Canela (tras PV-14), los que se unen al grupo | 11 vecinos con rutina por franja y diálogo; **figuras PROVISIONALES sin esqueleto** [I] | ninguno (Ferro solo por encargo) | **ninguno** |
| Enemigos | encuentros por pasos; centinela; combates de misión | ninguno (ciudad) | encuentros por pasos, nido, Gorthor, Coloso de la Falla | encuentros por pasos; Humbaba APAGADO |
| Secretos | rincones: montón de los peregrinos, nido de la urraca, puente; cofre del árbol mágico | 4 cofres-secreto, 2 vistas, grieta, Patio de las Velas | pilar del peregrino (Báculo) | armadura del árbol (Hoja sin Nombre), Diente de Grimfang |
| Interacciones | estela, notas (3), lavanda, piedra, nido, asomarse | piezas (barril, torre, ronda, faroles, grieta, páginas, tablón, mesa), 5 notas, tienda, gremio, parejas, posada | palanca, levadizo, altares, notas, veta de Ferro | altar, detalle, cofres |
| Misiones | PV-02 a PV-14, «El bosque que no recuerda» | favores, faroles, secreto de Pip, lavanda; encargos de Ferro y Mirta | encargo de Ferro (veta) | **ninguna** (tampoco en la 2D) |
| Cofres | sí | 4 (mismos ids que la 2D) | 1 (nido, mismo id) | 3 generados + Grimfang (mismos ids) |
| Música | sí («Pastoral Pulse» elegible) | `ciudad` + murmullo, fuente, mercado y campana en 3D | `mazmorra` + cascada | ambiente «bosque» pedido por la escena (**falta la línea en `musica.gd`**) [I] |
| Entradas y salidas | desde el mapa; salida señalada | Puerta del Sur ↔ mapa; posada entrar/salir | entrada del cañón ↔ mapa | pie del camino ↔ mapa |
| Navegación | `_prohibido`, alturas, puente | `_prohibido` + bloqueos del GLB; adarve en alto; cámara por zonas | cornisas, puentes, `T.ritmo` | trazado 1,25 m/casilla, puentes alargados |
| Colisiones | sí | sí (cajas del GLB, vecinos con cilindro) | sí | sí |
| Guardado y carga | al entrar, pausar, combate, hitos | al entrar, pausar, dormir, cofre, nota, misión, tienda…; 2D↔3D en la misma casilla | al entrar, altares, palanca, cofre; 2D↔3D | al entrar, cofres, hallazgos, combate; 2D↔3D |
| Conexión con el mapamundi | lugar 10 (solo con la 3D) | lugar 0 | lugar 2 | lugar 1 |
| **Lo que falta** | medir el medio en el Redmi (23-25 FPS el 09/11, después optimizado); la Gruta del Velo [P] | **figuras con rig** de los vecinos (→ Parte 2 de este encargo); fauna; comentarios del grupo al explorar; el velo del Patio de las Velas; Hilda y compañía no cambian de sitio con la hora | Redmi en medio; notas y veta solo en la 3D (la 2D elegida no las tiene) | NPC y misión propios; el texto del mapa promete un santuario con Lya y el Núcleo que no existe; armadura de primitivas; fauna de primitivas |

## 2. Regiones 3D incompletas o en desarrollo

### 2.1 Mar de Arena de Calid · primer sector «Mar de Cristal» (EN PRUEBAS: `-- 3d mardecristal` o Ajustes)

| Requisito | Estado |
|---|---|
| Terreno y relieve | sí: dunas, arena blanda, cañón al oeste, chimeneas de roca, estanque/oasis [I] |
| Arquitectura | ruinas, mural «…de los Espejismos», trampilla, cobijo, campamento de Ismena |
| Vegetación | matorrales y cristales (`paisaje.gd`) |
| Iluminación | sol cálido, tormenta de arena (`clima.gd`), bajo aún «lavado» en el teléfono [I] |
| Animales | **no** (solo Bramavidrio, que es jefe) |
| NPC | Ismena y Oren (cápsulas; modelos de Blender APAGADOS con `npc_desierto_v12`), Naira (prototipo APAGADO) |
| Enemigos | encuentros; Bramavidrio (v2 por defecto, v1 elegible); Vidracrán y Tolvanera propuestos, sin aprobar |
| Secretos | excavación con el buscador de Kael (únicos que esperan su hito) |
| Interacciones | buscador (niveles 1-3), excavar, cobijo, trampilla |
| Misiones | «La caravana perdida» (8 hitos `mc_*`) |
| Cofres | el del espejismo (una vez); el resto son excavaciones |
| Música | contextos `mar_cristal` y `tormenta_arena` |
| Entradas/salidas, navegación, colisiones | salida señalada, borde del mundo; dunas lejanas sin choque; **Kael pisa el agua en el borde oeste** [I] |
| Guardado | al entrar, hitos, pausa; misión rehecha si se recarga a medias |
| Mapamundi | lugar 4, solo con `mardecristal`; sin él, la zona 2D genérica |
| **Falta** | salir de «en pruebas» (validación en el Redmi del perfil bajo); los **demás sectores** de Calid (la máquina enterrada `calid_maquina` y su Tomo del Alba, las ruinas sepultadas, el Lente del Sol del texto del mapa); fauna; figuras definitivas de Ismena y Oren |

### 2.2 Dentro de regiones terminadas, apagados

- **Santuario de Humbaba** (Gran Bosque, `humbaba_v12`): modelo, 23 clips, combate ATB propio de 3 fases. Falta que el usuario lo vea.
- **Observatorio y misión de Naira** (Mar de Cristal, `naira_v12`): prototipo; Naira **no está aprobada**.

## 3. Ubicaciones que siguen en 2D

Todas usan `zona.gd` (la zona generada por casillas), salvo la isla. Lo que da esa zona 2D genérica [C]: trazado de 80×56
casillas con camino al altar del norte y tres ramas (ruinas, campamento, claro) con **3 cofres** de premio por `hash(id)`,
el **altar** con su orbe y el texto del mapa, los **detalles** de `progreso.gd` y los **hallazgos** de `hallazgos.gd`,
encuentros por pasos con el nivel de la zona, clima por estilo y, en las ciudades, **4 vecinos genéricos** (Aldric,
Selene, Pip, Rosa: las mismas fotos que Oakhaven). **Ninguna tiene NPC propios, misiones, música propia ni fauna.**

| Lugar | Estilo 2D | Detalle (Acto) | Hallazgos | Ruta del mapa | Qué falta para la 3D (todo) |
|---|---|---|---|---|---|
| Cumbres de Ciclópea (3) | «nieve» | `ciclopea_estatua` (II) | Guardiana de Ámbar (detalle), Pluma de Arpía (cofre, ruinas), Tomo de Escarcha (cofre, mirada) | Garganta ↔ Ciclópea ↔ Calid | todo; el texto del mapa nombra a **Glacius Niflheim** (sin combate ni lugar propio) |
| Sunken City (5) | «llanura» (ciudad) | `sunken_contratos` (II) | — | Calid ↔ Sunken | todo; la ciudad del diseño («ciudad en las costillas», posada el Ancla Seca [P]) no existe: hoy es un prado genérico con 4 vecinos de Oakhaven |
| Valle de los Ecos (6) | «yermo» | — | Tomo de Lumbre (cofre, agua), Frasco de Brasa (cofre, ruinas) | Garganta ↔ Valle | todo; el texto («Kael se enfrenta a sí mismo», espejos de agua) no tiene contenido |
| Templo Sumergido de Atlantis (7) | isla | `templo_mural` (II) | — | solo con el Astraea | todo, y el Astraea |
| Abismo de Ceniza (8) | «ceniza», isla | — | — | solo con el Astraea | todo; mazmorra final de Morgath |
| Arboleda Mítica (9, por el portal) | fondo pintado (Meshy) con máscara de paso | — | — | portal ↔ portal | es 2D **a propósito** (biblia de arte); el diseño [P] le añade hospedería, libro de firmas y cinco secretos |

## 4. Mapamundi

`mapa.gd` es 2D (2400×1350) con RUTAS por tierra `[0,1] [1,2] [2,3] [2,6] [3,4] [4,5]` e ISLAS 7 y 8 (Astraea). Pastos
Verdes (10) se añade solo con la exploración 3D. La entrada a cada lugar pasa por `modo3d.escena_de(i)`: si hay 3D en uso,
la 3D; si no, `garganta.tscn`, `ciudad_oakhaven.tscn` o `zona.tscn`. Las partidas guardan el índice del lugar; `regiones.gd`
tiene ya los ids de texto estables para una migración futura (sin usar).

## 5. Lugares de la historia que aún no son jugables

| Lugar | Origen | Dónde iría | Nota |
|---|---|---|---|
| Cripta de las Urnas | crematorio [C], cripta [P v2] | bajo el crematorio de Oakhaven (trampilla del Cuervo) | el crematorio y el jardín de urnas ya están en 3D: la cripta sería una gruta corta |
| Templo del Cristal del Cielo | [C] (Arboleda: «el templo de arriba guarda el Cristal del Cielo») | terraza de la Arboleda | acto III |
| Cala de los Mástiles y Gruta de la Marea | Océano de Bruma [C], contenido [P] | marcador nuevo (1160, 790) | |
| Acantilados del Abismo Quebrado | [C] | dentro de la zona del Abismo | final |
| Gruta del Velo | [P v2/v3] | dentro de Pastos Verdes | |
| Escalera del Cielo | [P v2] | marcador (520, 500) | |
| Aldea Rocío | aldea tragada [C], nombre [P v2] | marcador (500, 175), al recordar su nombre | sin encuentros |
| Collado de Ámbar y Gruta de los Centinelas | [P] | marcador (1160, 480) | aldea con posada |
| Resto del Mar de Arena de Calid | [C] (texto del mapa y `calid_maquina`) | región 4 | la máquina enterrada, las ruinas sepultadas, el Lente del Sol |
| Pico de Glacius Niflheim | [C] (texto del mapa) | región 3 | |
| Casco del buque | [P] | dentro de Sunken City | |
| Santuario del Gran Bosque con Lya y el Núcleo | texto del mapa [C] | región 1 | **contradice lo jugable**: decisión de narrativa pendiente |

---

## 6. Orden de migración propuesto (razonado)

Criterios, por este orden: (1) **el recorrido de la historia** (no dejar huecos 2D entre regiones 3D que el jugador cruza
seguidas); (2) **reutilizar kits que ya existen** (cuanto más se reutiliza, menos riesgo en el Mali-G57); (3) **dependencias**
(Astraea, actos); (4) cerrar antes lo empezado.

1. **Terminar Oakhaven 3D con vida** (este encargo, Parte 2): los vecinos tienen figuras sin esqueleto y la ciudad se ve
   quieta. Es la primera ciudad, la que más se pisa, y su familia de NPC sirve para todas las demás ciudades.
2. **Mar de Cristal fuera de «en pruebas»** (validar en el Redmi el perfil bajo y el agua del borde oeste) y, detrás, el
   **resto del Mar de Arena de Calid** (la máquina enterrada y el Tomo del Alba ya tienen datos). Cierra lo empezado.
3. **Cumbres de Ciclópea.** Es el único hueco 2D en la ruta ya 3D Garganta → Ciclópea → Calid. Reutiliza el kit de roca,
   cornisas y materiales de la Garganta (`zonas3d/garganta/roca.gd`, `materiales.gd`, `piezas.gd`), el clima del desierto
   (`clima.gd`, cambiando arena por nieve) y la vegetación de Pastos con tono frío. Tiene ya 1 detalle y 3 hallazgos con
   ids: la migración es «misma disposición, más relieve», como el Gran Bosque. Plan detallado en §8.
4. **Sunken City.** Segunda ciudad: reutiliza los sistemas de Oakhaven (`vida3d.gd`, posada, tienda, gremio) y la familia
   de NPC chibi de este encargo. Necesita diseño de narrativa antes (hoy es un prado con 4 vecinos de Oakhaven).
5. **Valle de los Ecos.** Rama sur de la Garganta; necesita contenido narrativo («Kael se enfrenta a sí mismo») antes del
   trazado. El agua de Pastos y el cielo nocturno del Mar de Cristal sirven de base.
6. **Arboleda Mítica**: su 2D pintada es una decisión de arte; solo pasar a 3D si el usuario lo pide. Primero, sus
   añadidos [P] (hospedería, libro de firmas) en la 2D.
7. **Templo Sumergido** y **Abismo de Ceniza**, al final: dependen del Astraea y del acto III.

Los sitios nuevos de §5 entran como **subzonas de regiones ya 3D** cuando narrativa los apruebe (la Cripta de las Urnas en
Oakhaven, la Gruta del Velo en Pastos), que es más barato que una región nueva.

## 7. Una actividad característica por región (propuesta, sin Orbes Cristalinos)

Cada región con una actividad **distinta**, que nace de lo que ya tiene (sistemas y datos) y premia con monedas, objetos,
equipo, páginas del Diario o atajos. **Ninguna recompensa en Orbes Cristalinos.** Todo [P]: no inventa giros, solo usa
lo que la región ya cuenta.

| Región | Actividad | Cómo se juega | Recompensa |
|---|---|---|---|
| **Oakhaven** | **Rumores de vecindario** (investigación por horas) | los vecinos nuevos (Parte 2) dicen cosas distintas por franja (mañana, tarde, anochecer); juntar tres rumores que encajan (dónde se perdió algo, quién lo vio) lleva a un objeto perdido en la ciudad. Usa `oak_franja` y la cola de avisos que ya existe | el objeto devuelto (una baratija con su página de Diario), descuento de un día en la tienda o un consumible del mercado |
| **Pastos Verdes** | **Cuaderno de naturalista** | observar fauna sin espantarla (las bandadas y los conejos ya huyen de Kael): acercarse despacio, mirar y anotar; cada especie, una página. Unas solo de mañana, otras junto al río | páginas del bestiario, cebo para pescar o un accesorio de sigilo menor |
| **Gran Bosque Verde** | **Herbolaria** (oficio) | recoger hierbas que solo crecen junto a las charcas, bajo los árboles viejos o en el mirador, y llevarlas a la botica de Oakhaven (`servicios_botica.gd`) para recetas | pociones y éteres de receta, un encargo de Selene; sin precio en Orbes |
| **Garganta del Diablo** | **Ruta alternativa por las cornisas** | contrapesos y poleas viejas (de los puentes P1-P8) que abren un atajo por la pared del cañón; puzle ambiental de pesos | el atajo permanente al nido y a la arena, y un cofre con material de forja para Ferro |
| **Mar de Cristal / Calid** | **Arqueología** (ya existe: el buscador de metales) | ampliarla a los sectores nuevos: catas que solo se oyen tras la tormenta, piezas que se juntan en una reliquia | reliquias para el gremio, mejoras del buscador, Monedas antiguas |
| **Cumbres de Ciclópea** | **Refugios de montaña** | encender los refugios abandonados (leña, pedernal) para orientarse en la ventisca: cada refugio encendido es un punto de descanso y un atajo de bajada | refugios como puntos de guardado y descanso, la capa de abrigo |
| **Sunken City** | **Trueque en las costillas** | cadena de trueques entre puestos del puerto (cada vecino quiere algo que tiene otro), con la tienda normal al lado | objetos raros de puerto, un mapa de la costa (abre la Cala de los Mástiles, si se aprueba) |
| **Valle de los Ecos** | **Puzles de eco y reflejo** | repetir una secuencia de notas que devuelve el valle, o alinear espejos de agua para que el reflejo muestre un camino que no está | caminos ocultos, el Tomo de Lumbre (ya es su hallazgo) en un rincón al que solo se llega así |
| **Templo Sumergido** | **Mareas** | subir y bajar el nivel del agua con mecanismos del templo para abrir salas distintas | equipo de agua, páginas del mural |
| **Abismo de Ceniza** | **Brasas de los vigías** | encender braseros siguiendo corrientes de calor; puentes de ceniza que se deshacen tras pasar (ruta con tiempo) | atajos antes del jefe final, equipo de fuego |
| **Arboleda Mítica** | **Libro de firmas de los peregrinos** | firmas o sellos que se encuentran por el mundo (el anillo partido de los pilares, la estela) y se llevan al libro | páginas del Diario y la llave del jardín que no olvida [P] |

## 8. Cumbres de Ciclópea 3D

**Actualización (13/11, tercera pasada):** el **primer sector ya es jugable, EN PRUEBAS y apagado** tras `ciclopea3d` (`zonas3d/ciclopea_3d.gd`; `docs/memory/agents/mundo_v12_npc.md` §15-19). El plan de abajo se ha seguido: pasos 1-4 y 6 hechos, el 5 en una primera versión (escenario propio sin la ventisca de `clima.gd`) y el 7 pendiente de narrativa. Lo de abajo es el plan tal como se escribió.

### Plan (13/11, segunda pasada)

**Estado (13/11, segunda pasada):** no hay sector jugable. Con el pulido de la familia de NPC no daba para dejar uno
jugable, apagado y probado (entrada y salida, choques, guardado) sin prisas, así que se deja el plan concreto y un
**esbozo de terreno** hecho con los datos reales de la 2D:
- `pruebas/herramientas/volcar_ciclopea_2d.gd` vuelca lo que `zona.gd` genera para el lugar 3 (estilo «nieve», semilla
  1000 + 3 × 7919 = 24757; 80 × 56 casillas) y propone el relieve; `fuente/esbozo_ciclopea.py` lo convierte en una maqueta
  de Blender. Salida en `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\`: `ciclopea_2d.json`, `plano_2d.png`,
  `relieve.png`, `esbozo_desde_la_entrada.png` y `esbozo_de_arriba.png`.
- **Datos de la 2D que la 3D debe conservar (mismas claves):** entrada por el sur en la columna 40; altar al norte en
  (46,2, 5,0); rincones: ruinas (25,7, 46,0), campamento (20,3, 36,0) y claro (65,1, 28,4); cofres `3_1644_2905` (ruinas),
  `3_1466_2229` (campamento) y `3_4168_1815` (claro); detalle `ciclopea_estatua` (en las ruinas; da la Guardiana de Ámbar);
  hallazgos de cofre: Pluma de Arpía (cerca de las ruinas) y Tomo de Escarcha (`cerca: "mirada"`: la 2D de este lugar no
  genera ningún rincón «mirada»; **comprobar dónde lo pone la 2D** antes de colocarlo). Objetos: 195 pinos nevados,
  84 rocas nevadas, 4 columnas y 3 muros de ruina, 3 troncos, 1 brasero, flores.
- **Relieve propuesto** (en el esbozo): el camino sube de 0 m (sur) a +9 m (altar) con una curva suave (≤ 12 % de
  pendiente); los muros de la 2D son paredes de roca de +5 a +14 m, más altas al norte; el agua de la 2D, lagos helados
  (no se pisan); laderas nevadas de +0,8 a +2 m junto al camino. **Lo que enseña el esbozo:** con laderas a +0,8-2 m el
  camino queda encajado como una trinchera; en la 3D, mejor que las laderas bajen a la altura del camino en 1,5-2 m
  de cada lado (como la loma del mirador del Gran Bosque) y que solo las paredes de roca suban.

**Pasos, en orden (cada uno se prueba antes del siguiente):**
1. `zonas3d/ciclopea/disposicion_2d.gd` (generado, como `zonas3d/gran_bosque/disposicion_2d.gd`, con una variante de
   `volcar_ciclopea_2d.gd` que escriba GDScript) y una prueba que compruebe que coincide con `zona.gd`.
2. `zonas3d/ciclopea/trazado.gd`: casillas ↔ metros (1,25 m), alturas (las del esbozo, corregidas), `_prohibido`
   (paredes, lagos, borde), entrada y salida señalada (disco, letrero «Mapa del mundo», postes) en el sur, como las otras
   regiones; `posicion_desde_2d` / `posicion_a_2d`.
3. `zonas3d/ciclopea_3d.gd/.tscn`: copia del contrato del Gran Bosque (`gran_bosque_3d.gd`, sin tocarlo): Kael, cámara,
   grupo, encuentros por pasos con la zona «nieve», combate y vuelta al mismo sitio, cofres con sus ids y premios por
   `hash`, detalle y hallazgos con `examinables_3d.gd`, altar con su texto, brazalete, comentarios del grupo,
   guardado al entrar, tras cofre/hallazgo/combate y al pausar.
4. **Interruptor, apagado:** `EN_PRUEBAS[3] = "ciclopea3d"` y `REGIONES[3]` en `modo3d.gd` (sin el argumento ni la
   elección en Ajustes, el mapa sigue llevando a la 2D), y `EQUIVALENTES_ZONA` para las partidas de la 2D.
5. `zonas3d/ciclopea/escenario.gd`: el kit de roca de la Garganta (`garganta/roca.gd`, `materiales.gd`), pinos de
   `vegetacion_paquetes` con nieve en las ramas, nieve con el sombreado de la arena del Mar de Cristal en frío, la
   estatua sin brazo (pieza propia de Blender, mirando al pico), ventisca con `mar_cristal/clima.gd` (niebla, partículas,
   viento) por perfiles, LOD y MultiMesh por zonas como el Gran Bosque optimizado.
6. Pruebas: `prueba_ciclopea3d` (entrar desde el mapa con el interruptor y sin él, andar del sur al altar sin atascos,
   los tres cofres con el mismo premio en la 2D y en la 3D desde la misma partida, detalle y hallazgos, salir, guardar y
   volver, combate y vuelta), `prueba_restaurar_escenas` y capturas y medida en bajo, medio y alto.
7. Narrativa antes de textos nuevos: Glacius Niflheim está en el texto del mapa pero no tiene combate; el altar se queda
   con el texto de la 2D. La actividad propuesta para Ciclópea (refugios de montaña, §7) va después y con su aprobación.

**Estimación:** 1-2 sesiones para los pasos 1-4 y 6 (un primer sector jugable y apagado: del sur al campamento y las
ruinas); el escenario completo (paso 5) y la ventisca, otra sesión, con medida en el Redmi.