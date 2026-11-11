# Segunda gran fase · Fase A: auditoría técnica

**Fecha:** 11/11/2026, 23:55 (empieza la madrugada del 12/11). **Rama:** `claude/v12-fase2-auditoria` (LOCAL), en
`D:\Aethelgard_v12_auditoria`, desde `claude/rebelum-v12` @ `1b8f720`. **Sin cambios en el código del juego.**

**Cómo se ha hecho:**
- leyendo el código de esa revisión, con las líneas citadas;
- los clips, triángulos y huesos de los GLB y FBX se han **medido leyendo las cabeceras de los archivos** (script de
  PowerShell propio en el directorio temporal, sin Godot);
- **no se ha ejecutado Godot ni la batería:** la copia no tiene `.godot` y una importación nueva puede tocar
  `project.godot` (aviso de `RETOMAR.md`). La última batería conocida es la del informe de la noche: 120 · 0 · 50 · 0.

**Leyenda:**
- **[C]** observado en el código (archivo:línea);
- **[A]** medido leyendo los archivos de recursos;
- **[D]** solo en documentos, del historial (con su archivo);
- **[?]** pendiente de verificar.

Nombres de lugares, enemigos y personajes nuevos: los del código. Lo que no está aprobado sigue siendo propuesta.

---

## 1. Ubicaciones

### 1.1 Cómo se llega a cada sitio [C]

- **Mapa del mundo:** `mapa.gd`, en 2D. Diez lugares en `LUGARES` (`mapa.gd:39-61`).
  - Con la exploración 3D activa se añade Pastos Verdes como lugar 10 (`mapa.gd:65-66, 109-110`).
  - **Activa:** característica `rebelum3d` o argumento `3d`; `modo3d.gd:29-30`.
- **Al entrar** (`mapa.gd:640-683`):
  1. el portal lleva a `isla.tscn`;
  2. si `modo3d.escena_de(i)` devuelve una escena 3D, a esa escena;
  3. si no: el lugar 2 va a `garganta.tscn`, el 0 a `ciudad_oakhaven.tscn` y el resto a `zona.tscn` (zona generada).
- **Regiones 3D:** `modo3d.gd:21-24`. Las del índice 2, 0 y 4 están `EN_PRUEBAS`: hacen falta el argumento o el ajuste
  `garganta3d`, `oakhaven3d` o `mardecristal`.
- **Equivalencias de partida:** `EQUIVALENTES` (`modo3d.gd:26`) solo traduce `garganta.tscn` y `ciudad_oakhaven.tscn`.
  Una partida guardada en una **zona generada** (`zona.tscn`) sigue en 2D aunque su lugar tenga versión 3D (la del
  Mar de Arena de Calid, por ejemplo).
- **Templo Sumergido (7) y Abismo de Ceniza (8):**
  - el mapa los genera como islas aparte (`mapa.gd:36, 164-166`) y `_es_tierra` impide andar por el mar
    (`mapa.gd:500-508`);
  - no hay barco Astraea en el código (solo el aviso de `mapa.gd:610`);
  - **conclusión:** a pie no se llega [C]. Falta comprobarlo jugando [?].

### 1.2 Clasificación

| # | Lugar | 2D | 3D | Clase |
|---|---|---|---|---|
| 10 | Pastos Verdes (+ «El bosque que no recuerda» y el Claro del Guardián) | — (solo existe en 3D) | `zonas3d/pastos_verdes_3d.tscn`, por defecto con la exploración 3D | **3D implementado y probado** (Redmi: bajo y medio a 30 FPS) |
| 2 | Garganta del Diablo | `garganta.tscn` (hecha a mano) | `zonas3d/garganta_3d.tscn`, en pruebas | **3D implementado y probado** (Redmi a 30/30 FPS); cubre la 2D y añade cosas |
| 4 | Mar de Arena de Calid → primer sector «Mar de Cristal» | `zona.tscn` (generada, estilo desierto) | `zonas3d/mar_cristal_3d.tscn`, en pruebas | **3D implementado y probado, solo un sector** (Redmi: 30,4 / 30,4 / 23,6 FPS) |
| 0 | Oakhaven | `ciudad_oakhaven.tscn` (hecha a mano, completa) | `zonas3d/oakhaven_3d.tscn`, en pruebas | **3D implementado pero mejorable:** un tramo de la ciudad |
| 1 | Gran Bosque Verde | `zona.tscn`, generada | — | **Solo 2D** |
| 3 | Cumbres de Ciclópea | `zona.tscn`, generada | — | **Solo 2D** |
| 5 | Sunken City | `zona.tscn`, generada (estilo «ciudad») | — | **Solo 2D** |
| 6 | Valle de los Ecos | `zona.tscn`, generada | — | **Solo 2D** |
| 7 | Templo Sumergido de Atlantis | `zona.tscn`, generada | — | **Solo 2D, sin acceso a pie** |
| 8 | Abismo de Ceniza | `zona.tscn`, generada | — | **Solo 2D, sin acceso a pie** |
| 9 | Portal del Vacío → Arboleda Mítica | `isla.tscn` (fondo pintado del render de una isla de Meshy) | — | **Solo 2D** |
| — | Mapa del mundo | `mapa.tscn` | — | 2D (fuera del plan 3D) |

### 1.3 Ficha de cada lugar jugable [C]

#### Pastos Verdes 3D (`zonas3d/pastos_verdes_3d.gd`; hereda de `prototipos/sendero_puente.gd`)

| Sistema | Qué hay |
|---|---|
| Acceso | Lugar 10 del mapa (solo con la exploración 3D). Dos salidas, en los dos extremos del camino (`:35-36`) |
| Misión | PV-02, PV-03 (se une Lya), PV-05 (Garon), PV-06 (centinela), PV-07, PV-14 y `mecha_tilo` (`:22-24`). Después, «El bosque que no recuerda» (`bosque_pastos.gd`, hitos `bq_*`, 15 timelines) con sus dos desenlaces (decisión `guardian_bosque`) |
| NPC | Tilo, figura de primitivas (`:1021-1031`); Lya y Garon se unen y siguen a Kael (`zonas3d/grupo_3d.gd`) |
| Diálogos | 8 `pv_*` y 15 `bq_*`; los rincones, con variantes según el grupo |
| Enemigos | Al azar por pasos (`:32-34`, como en `zona.gd`). Fijos: «pastos_centinela» (GRUPOS[0], dos Grimfang) y el Guardián del Bosque (GRUPOS[11]) |
| Cofres | `pastos3d_arbol_magico` (`:71`), el cofre de la senda (`bq_cofre_senda`) y el nido (`rin_nido`: 25 monedas y 1 Moneda antigua, con Garon) |
| Objetos | Recolección: Hierba lunar, Musgo de piedra y Savia clara (`bosque_pastos.gd:28-38`); la lavanda para Rosa |
| Secretos | La estela (`pastos_estela`), las notas (`dialogos/notas/pastos_verdes.gd` y `pastos_rincones.gd`), el orbe de los futuros y los rincones V12 |
| Eventos | Cinemática del mirador; encargo «Canela se ha perdido» (`enc_perro`) |
| Guardado | Al entrar, tras cada combate y escena de la misión, y al pausar (`:18-20, 164, 524`) |
| Música | Contexto `pradera`, o `pradera_musica` (Pastoral Pulse, elegible): `musica.gd:120-121` |
| Frente al 2D | No hay versión 2D: no falta nada |

#### Garganta del Diablo 2D (`garganta.gd`) y 3D (`zonas3d/garganta_3d.gd`)

| Sistema | 2D | 3D |
|---|---|---|
| Estructura | 8 pantallas y el nido; la palanca abre la puerta, baja el puente y enciende el ascensor (`garganta.gd:3-12`) | La misma, en el mismo orden y con los mismos identificadores (`garganta_3d.gd:9-17`) |
| Fijos | Nido (GRUPOS[6]) y Gorthor (GRUPOS[5], con el perdón) | Los mismos, y además el **Coloso de la Falla** (GRUPOS[12], opcional, solo en 3D: `:52-66`) |
| Cofres | El raro del nido, `2_1984_3238`, más los generados | El mismo id (`:39`) |
| Detalles | `garganta_puentes` y `garganta_pilar` | Los mismos |
| Encargo de Ferro | La veta **no existe** | La veta `enc_herrero_veta` (`:136, 537, 956-999`, con `gg_veta.dtl`) |
| Notas | `dialogos/notas/garganta.gd`: datos listos, **sin enganchar** (`:6-22`) | **Sin enganchar** |
| Hallazgo «Báculo del Peregrino» (`hallazgos.gd:26`) | Sí: lo da `zona.gd:2325` al examinar el pilar | **No:** ninguna escena 3D usa `hallazgos.gd` |
| Guardado | Puntos de guardado y automático | Lo mismo |
| Música | `mazmorra` | `mazmorra` (`musica.gd:118-119`) |

- **Falta en la 3D:** el Báculo del Peregrino.
- **Falta en las dos:** las notas.
- **Para activarla por defecto:** quitar `GARGANTA` de `EN_PRUEBAS` (`docs/diseno/garganta_3d.md`, «Activarla por
  defecto»).

#### Oakhaven 2D (`ciudad_oakhaven.gd` + datos en `ciudades/oakhaven.gd`) y 3D (`zonas3d/oakhaven_3d.gd`)

| Sistema | 2D (completo) | 3D (tramo) |
|---|---|---|
| Recorrido | Toda la ciudad: 27 lugares de `LUGARES` (`oakhaven.gd:52-112`) | Puerta del Sur → Calle Mayor → Plaza del Tapiz → Calle del Cuervo → taberna por dentro, y el distrito de los oficios (`oakhaven_3d.gd:2-8`; `oakhaven/distrito.gd`). Lo demás se ve, pero sin uso |
| Vecinos | 11 (`oakhaven.gd:124-243`): Aldric, Selene, Pip, Rosa, posadera, Albar, Bastián, Encina, Ferro, Hilda y Mirta; con rutinas por franja (`ciudad_oakhaven.gd:1152-1216`) | 5: Aldric y la posadera (primitivas), y Ferro, Hilda y Mirta (mallas de Blender sin esqueleto, `distrito.gd:221-260`) |
| Misiones | `oak_favores`, `oak_faroles`, `oak_secreto_pip` y `oak_lavanda` (`oakhaven.gd:297-334`); encargos `enc_herrero` y `enc_formula` (`datos/encargos_oakhaven.gd`) | Solo los encargos que se abren con Ferro y Mirta (señales `oak:`). **Sin** favores, faroles, secreto de Pip ni entrega de la lavanda (Rosa no está) |
| Cofres | 4 (`oakhaven.gd:340-350`) | **Ninguno** |
| Secretos y vistas | 6 (`oakhaven.gd:353-380`) | **Ninguno** |
| Piezas | Barril, torre, ronda, 3 faroles, grieta, escalera, tablón del gremio y mesa de juego (`oakhaven.gd:384-421`) | **Ninguna**; solo el pozo del distrito |
| Notas | 5 (`ciudad_oakhaven.gd:758-779`) | **Ninguna** |
| Servicios | Tienda y posada (`zona.gd:2140-2146`), gremio (`ciudad_oakhaven.gd:160-180`), parejas (`:128-140`) y talleres por diálogo | Posada (dormir con su charla, comer y rumores: `oakhaven_3d.gd:476-505`), forja, armaduras y botica (`servicios.gd`). **Sin** tienda general, gremio ni parejas |
| Hallazgos | Rama Milenaria (Árbol) y Gemelas de la Muralla (barril): `hallazgos.gd:40-43` | **No** |
| Lore | `oak_sello` y `oak_tapiz` (actos) | **No** |
| Guardado | Automático | Al entrar, al pausar y tras dormir (`:503-516`) |
| Música | `ciudad` | `ciudad` |

**Riesgo [C]:** con `oakhaven3d` elegido, una partida guardada en la ciudad 2D abre la 3D (`modo3d.gd:26, 83-98`). No se
pierde nada, porque las claves son las mismas, pero el jugador no puede terminar lo que solo existe en la 2D hasta que
quite el ajuste.

#### Mar de Arena de Calid: 2D generada y 3D «Mar de Cristal» (`zonas3d/mar_cristal_3d.gd`)

| Sistema | 2D (`zona.tscn`, lugar 4) | 3D (primer sector) |
|---|---|---|
| Recorrido | Zona generada de desierto, con altar | 90 × 110 m: campamento, caravana, oasis, cañón con cobijo, ruinas con trampilla, arena que tiembla, espejismo y nicho (`docs/v12/DISENO_V12.md` §1) |
| Misión | — | «La caravana perdida», con 8 hitos `mc_*` (`zonas3d/mar_cristal/mision.gd`) y 19 timelines `mc_*` |
| NPC | — | Ismena y Oren como **cápsulas**. Sus prototipos GLB están **apagados** (`npc_desierto_v12`; `mar_cristal_3d.gd:19`) |
| Mecánicas | — | Buscador de metales (`buscador.gd`), tormenta (`clima.gd`), gusano y Bramavidrio (`gusano.gd`, combate fijo GRUPOS[13]) |
| Enemigos al azar | Los genéricos (§3) | **Los mismos genéricos** (Slime, Grimfang, Guardián de piedra), con el nivel del desierto |
| Cofres | Generados | El del espejismo, una vez |
| Lore | `calid_maquina` (`progreso.gd:36-37`), necesario para el **Acto II** (`progreso.gd:52-53`) | **No está** |
| Hallazgo | **Tomo del Alba** (`hallazgos.gd:34`, al examinar `calid_maquina`) | **No está** |
| Guardado | Automático | Al entrar y al pausar (`:101`) |
| Música | `desierto` (ambiente) | `mar_cristal` y `tormenta_arena` (`musica.gd:31-32, 122-123`) |

**Falta en la 3D:** la máquina enterrada (lore del Acto II), el Tomo del Alba y los enemigos propios. Vidracrán y
Tolvanera son prototipos sin enganchar (§3).

#### Zonas generadas (`zona.gd`): lugares 1, 3, 5, 6, 7 y 8

Todas usan el mismo generador, con su semilla `1000 + índice × 7919` (`zona.gd:356`):
- **encuentros:** por pasos, con los 5 grupos genéricos;
- **cofres:** generados, con id `lugar_x_y` (`zona.gd:1790`);
- **altar** al final del camino;
- **detalle de lore** si existe en `progreso.DETALLES`, y **hallazgos** (`zona.gd:2510`);
- **salida:** el borde, que lleva al mapa (`zona.gd:2759`);
- **guardado:** automático (`zona.gd:333`);
- **en una ciudad:** tienda, posada y los 4 NPC de `zona.gd:2216-2233`.

Ninguna tiene misión, Dialogic propio ni enemigos de su región.

| # | Lugar | Estilo | Lore | Hallazgos | Notas |
|---|---|---|---|---|---|
| 1 | Gran Bosque Verde | bosque | `bosque_armadura` | Hoja sin Nombre (detalle) y Diente de Grimfang (cofre) | El texto del mapa promete a Lya y el Núcleo de la Naturaleza; no hay nada de eso |
| 3 | Cumbres de Ciclópea | nieve | `ciclopea_estatua` | Guardiana de Ámbar, Pluma de arpía y Tomo de Escarcha | Glacius Niflheim solo está en el texto del mapa |
| 5 | Sunken City | ciudad | `sunken_contratos` | — | **Los NPC son los mismos 4 de Oakhaven** (Aldric, Selene, Pip y Rosa), con sus diálogos (`zona.gd:2216-2233, 962`) |
| 6 | Valle de los Ecos | yermo | — | Tomo de la Lumbre y Frasco de brasa | «Kael se enfrenta a sí mismo» solo está en el texto del mapa |
| 7 | Templo Sumergido | llanura | `templo_mural` (Acto II) | — | Sin acceso a pie: **el Acto II no se puede completar jugando** [C; ?] |
| 8 | Abismo de Ceniza | ceniza | — | — | Sin acceso a pie; es la fortaleza final según el texto del mapa |

#### Arboleda Mítica (`isla.gd`)

- **Qué es:** un fondo pintado con el render de la isla de Meshy, con máscaras de paso y de profundidad
  (`isla.gd:5-13`).
- **Qué tiene:** 4 NPC con frases (Ilia, Orun, Lumi y Vex: `isla.gd:27-41`) y guardado al entrar (`:115`).
- **Qué no tiene:** encuentros, cofres y misiones.

### 1.4 Prototipos 3D (no son ubicaciones del juego) [C]

| Archivo | Qué es |
|---|---|
| `prototipos/vista3d.gd/.tscn` | La base de todas las regiones 3D: cámara, Kael y perfiles |
| `prototipos/sendero_puente.gd/.tscn` | El escenario de Pastos Verdes (la región hereda de él) |
| `prototipos/vegetacion_paquetes`, `arboles_prueba`, `arbol_estilizado`, `fauna_simple`, `agua_sin_refraccion.gdshader` | Bancos de vegetación, fauna y agua |
| `prototipos/posador_prueba.tscn` | Pruebas de poses (IK) |
| `prototipos/titulo_rebelum` | El título |
| `prototipos/calidad_auto`, `calidad_proto`, `regulador_calidad` | Perfiles de calidad |
| `ciudades/oakhaven_arte/maqueta_oakhaven.tscn` | La maqueta del arte 2D de Oakhaven |
| `zonas3d/bosque/claro_guardian.gd` | Un sector ya integrado en Pastos Verdes (6 930 triángulos [A]) |
| `personajes/desierto/`, `enemigos/vidracran/`, `enemigos/tolvanera/`, `enemigos/cencerrante/` | Personajes y enemigos sin enganchar (§2 y §3) |

### 1.5 Mencionadas en la historia o el diseño, pero no jugables

- **En el código:**
  - etiquetas del mapa: «Océano de Bruma» y «El Abismo Quebrado» (`mapa.gd:68-71`);
  - el Lente del Sol y el barco Astraea (textos del mapa).
- **En documentos [D]:**
  - `docs/diseno/ciudades_y_lugares.md` §3: Crematorio y Cripta de las Urnas, Templo del Cristal del Cielo, Cala de
    los Mástiles, Gruta de la Marea, Acantilados del Abismo Quebrado, Gruta del Velo, Escalera del Cielo, Aldea Rocío,
    Collado de Ámbar y Gruta de los Centinelas;
  - `docs/v11/HISTORIA.md` §1.4: el fondo del Mar de Cristal, con la Reina de los Espejismos, y el Campanero del
    Porvenir (sin región);
  - **todo eso es propuesta, no canon.**

### 1.6 Matriz de migración a 3D (de menor a mayor riesgo)

Esfuerzo **estimado**, en días de especialista:
- **S:** 1 o menos;
- **M:** de 2 a 4;
- **L:** de 1 a 2 semanas;
- **XL:** más de 2 semanas.

| Orden | Lugar | Qué falta | Esfuerzo | Riesgo | Dependencias |
|---|---|---|---|---|---|
| 1 | **Garganta 3D por defecto** | Báculo del Peregrino (enganchar `hallazgos.gd`); notas (datos listos); medio p95 50 ms; quitar de `EN_PRUEBAS` | S | Bajo: misma estructura e ids | Batería y Redmi |
| 2 | **Mar de Cristal por defecto** (como sector de Calid) | `calid_maquina` y el Tomo del Alba; enemigos propios (Vidracrán y Tolvanera); decidir Ismena y Oren; añadir `zona.tscn`+4 a las equivalencias | M | Bajo-medio: el resto de Calid sigue en 2D, así que hay que decidir si el mapa lleva al sector o a la zona | Fase C (enemigos) y nombres aprobados |
| 3 | **Oakhaven 3D completo** | 6 vecinos con rutinas, 4 misiones, 4 cofres, 6 secretos, 5 notas, piezas, gremio, parejas, tienda, el Árbol con sus hallazgos, la colina y el crematorio | XL | Medio-alto: es la ciudad central, el alto va a 15 FPS en el Redmi y faltan los NPC con esqueleto | Fase B (NPC 3D) y rendimiento |
| 4 | **Gran Bosque Verde** | Región nueva con el kit de Pastos; hoy solo tiene un detalle y dos hallazgos, así que hace falta diseño | L | Medio: no duplicar «El bosque que no recuerda», que ya está en Pastos | Narrativa y vegetación medida |
| 5 | **Cumbres de Ciclópea** | Kit de nieve y montaña, y su jefe (Glacius, solo nombre) | L | Medio | Arte nuevo y fase C |
| 6 | **Valle de los Ecos** | Espejos de agua (reflejos en Compatibility) | L | Medio-alto: técnico | Prueba de sombreado en el Mali-G57 |
| 7 | **Arboleda Mítica** | Del render 2D a 3D (¿el modelo de Meshy?, revisar licencia); NPC | L | Medio | Licencias |
| 8 | **Sunken City** | Segunda ciudad (diseño en `ciudades_y_lugares.md` §2.2); hoy repite los NPC de Oakhaven | XL | Alto | Fase B y narrativa |
| 9 | **Templo Sumergido y Abismo de Ceniza** | Acceso (Astraea), historia de los actos III y IV | XL | Alto: canon sin aprobar | Historia y navegación del mapa |

**Contrato común de cada migración [C]:**
- `REGIONES` y `EN_PRUEBAS` en `modo3d.gd`;
- `posicion_desde_2d` en la escena 3D;
- equivalencia en `EQUIVALENTES`; para `zona.tscn` hay que ampliar `escena_equivalente` para que mire el índice del
  lugar, porque hoy se busca por la ruta de la escena;
- `contexto_de` en `musica.gd`;
- `hallazgos.gd`, `progreso.detalles_de` y `notas_de`, que ninguna región 3D usa hoy salvo Pastos (notas).

---

## 2. Personajes

### 2.1 Los tres héroes [C][A]

Los mismos modelos se usan en la exploración (`prototipos/vista3d.gd:48-49`, `zonas3d/grupo_3d.gd:45`) y en el
combate (`combate.gd:174-185`).

| | Kael | Lya | Garon |
|---|---|---|---|
| Archivo | `kael.fbx` (17,9 MB) | `Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx` (8,6 MB) | `garon.fbx` (17,1 MB) |
| Origen | Meshy «Azure Starblade», con esqueleto Mixamo | Meshy «Anime Girl 10k Remesh», con esqueleto Mixamo | Meshy «Crimson Helm Guardian», con esqueleto Mixamo |
| Triángulos [A] | ~10 300 | ~10 300 | ~10 300 |
| Texturas [A] | 4 de 2048² (`kael_0..3.png`) | 3 de 2048² | 4 de 2048², y la capa (744 × 1024) |
| Esqueleto | Mixamo (Hips, Spine…, `gestos_3d.gd:8-29`) | Mixamo | Mixamo |
| Formas de la cara | **No** (0 BlendShape [A]) | **No** | **No** |
| Clips del FBX [A] | `_01a19b86` (reposo con el sable al hombro), `_01a19ba8` (andar pesado), Walking, Running, Face_Punch_Reaction, dying_backwards y mage_soell_cast_7 | Running, Walking y `_01a19663` (pose quieta con los brazos abiertos) | Thoughtful_Walk, Walking, Running, Sword_Judgment, Double_Blade_Spin y Shot_in_the_Back_and_Fall |
| Por código (`gestos_3d.gd:38-…`) | Ataque saltando (`k_agachar`, `k_alto`, `k_corte`), victoria, cansancio y magia | Reposo, cansancio, conjuro, golpe, herida, victoria y caída | Guardia (dos instantes de «Juicio», `garon_3d.gd:47-50`), herida y victoria |
| Esperas de Blender (`animaciones/esperas/*.res`) | Vigilar, empuñadura, brazalete e impaciencia | Flor, cetro y pelo | Hombros, espalda y apoyarse |
| Arma | Sable Frostfang (`sable.obj`, Meshy) | Cetro, según el inventario | Dos espadas (`hoja_infernal.obj`) |
| Retratos de Dialogic | 5 renders de Blender y retrato vivo (`dialogos/personajes/kael.dch`) | 4 y retrato vivo | **Ninguno:** «Provisional: sin retrato todavía» (`garon.dch`) |
| Licencia (`docs/recursos.md`) | Meshy, según el plan del autor; **faltan los créditos para un APK entregable** (en `licencias_pendientes.txt`) | Igual | Igual |

**Respaldo 2D:** también existen las figuras recortables `kael2_*` (6 caras: `combate.gd:336-338`), la maga Nyx 2D
(`nyx_*`) y el aventurero de fotogramas. Solo salen si falta el 3D (`RESPALDO`, `combate.gd:35`).

### 2.2 Animaciones frente al mínimo que pide el usuario

**Leyenda:**
- **clip:** un clip propio del modelo;
- **cód.:** hecho por código (`gestos_3d.gd`) o por giro del nodo;
- **✗:** no existe.

| Animación | Kael | Lya | Garon |
|---|---|---|---|
| Reposo | clip | clip (pose de brazos abiertos) + cód. | cód. (de «Juicio») |
| Caminar | clip (dos) | clip | clip |
| Correr | clip | clip | clip |
| Girar | cód. (`mirar()`, `maga_3d.gd`) | cód. | cód. |
| Saltar (exploración) | ✗ | ✗ | ✗ |
| Interactuar (coger, examinar, abrir) | ✗ | ✗ | ✗ (aupar en Pastos es un fundido) |
| Expresiones faciales | ✗ en 3D (solo los retratos 2D) | ✗ en 3D | ✗ (ni retrato) |
| Guardia de combate | = reposo | cód. | cód. |
| Ataques | cód. (salto) | cód. (golpe) | clip (Juicio y Giro) |
| Magia | clip (Casting) | cód. (conjuro) | — (Embuir sin clip) |
| Recibir daño | clip (Hit) | cód. | cód. |
| Derribo | clip (Death) | cód. (caída) | clip (Morir) |
| Victoria | cód. | cód. | cód. |
| Derrota (KO en el suelo) | = Death | = caída | = Morir |
| Conversación (hablar, gestos) | ✗ (el grupo solo se gira hacia quien habla: `grupo_3d.gd:389-460`) | ✗ | ✗ |

**Faltan, para los tres, como clip:** saltar, interactuar, conversación, expresiones, victoria y recibir daño (salvo
Kael). Además, los ataques de Kael y Lya, la magia de Lya y el reposo de combate de Garon.

**Conclusión:** casi todo lo que no es andar o correr es pose por código encima del FBX de Meshy. Para la fase B lo
coherente es un **rig de Blender propio** por héroe, que conserve el FBX original (norma del usuario).

### 2.3 NPC y otros personajes 3D [C][A]

| Personaje | Cómo está hecho | Animación |
|---|---|---|
| Tilo (Pastos) | Primitivas (`pastos_verdes_3d.gd:1021-1031`) | Ninguna |
| Aldric, posadera y parroquianos (Oakhaven 3D) | Primitivas (`oakhaven_3d.gd:336-375`, `oakhaven/posada3d.gd:170-…`) | Ninguna |
| Ferro, Hilda y Mirta (distrito) | Mallas estáticas de Blender (`distrito.glb`) | Ninguna |
| Ismena e Oren (Mar de Cristal) | Cápsulas en el juego. Prototipos GLB de 5 706 y 5 660 triángulos, con 23 y 22 huesos [A] | Prototipo: 5 clips (reposo, hablar, mapa, horizonte, regañar) y 4 (reposo, hablar, risa, encogerse). **Apagado** |
| Érebo (invocación) | 6 FBX de Meshy, de ~15 200 triángulos cada uno [A] (`erebo_*.fbx`) | Idle, conjuro, coger, mano, mano 2 y salir |

---

## 3. Enemigos

`combate.gd`:
- `ENEMIGOS`: `:273-303`;
- `GRUPOS`: `:304-323`;
- `MODELOS`: `:127-270`;
- los turnos por personalidad: `_turno_enemigo`, `:1667-…`;
- los patrones: `:2056-2063`.

| Enemigo | Modelo en combate | Clips [A] | Mecánica propia | ¿Provisional? |
|---|---|---|---|---|
| Slime | Sprite 2D de Segel2D (5 animaciones) | — | «cobarde»: se encoge (la mitad de daño físico; la magia rompe la guardia) y Rebote ×1,3; puede huir si queda solo | **Sí** (único 2D de los comunes) |
| Grimfang | `goblin.fbx`, de Meshy (~10 300 triángulos) | Heavy_Hammer_Swing, Left_Slash, Face_Punch_Reaction, Walking y Running | «agresivo»: Hachazo ×1,6 con aviso; se puede interrumpir | Aceptable |
| Guardián de piedra | Imagen 2D `enemigos/guardian.png` | — | «jefe» (golpe devastador avisado). **Sale al azar** (GRUPOS[4]) | **Sí** |
| Gólem de ámbar (nido) | **La misma imagen** del Guardián | — | «bruto»: Pisotón a todos | **Sí** |
| Gorthor | **El Grimfang ×1,2, teñido de rojo** (`combate.gd:198-202`) | Los de Grimfang | Fases (al 50 %: música, color, velocidad y Devorar), último aliento y perdón | **Sí** (sin modelo propio) |
| Zarzalín | GLB de Blender, 8 027 triángulos y 12 huesos | 9: reposo, entrada, aviso_embestida, aviso_espera, embestida_espinosa, colmillo_lateral, recibir_golpe, correr y derrota | «embiste»: aviso, Embestida ×1,8 (Defender la reduce) y recupera el aliento | No (solo sale con 1 o 2 héroes: `combate.gd:328`) |
| Guardián del Bosque | GLB, 7 774 triángulos y 28 huesos | 8: reposo, dormido, carga, ataque, golpe_fuerte, herido, fase2 y derrota | Dos fases, coraza de raíces, débil al fuego, el Elixir lo purifica y Lya con la investigación hace más (`combate_bosque.gd`) | No |
| Coloso de la Falla | GLB, 9 042 triángulos y 29 huesos | Los mismos 8 | Piel de piedra, ventana tras su golpe cargado, coraza rúnica alterna y «Leer runas» de Garon (`combate_coloso.gd`) | No (el comentario de `combate.gd:238-241` y `293-296` está desfasado: `MODELO_3D = true`) |
| Bramavidrio | v2 por defecto (15 197 / 5 528 / 2 430 triángulos y 52 huesos); v1 (19 327, 43 huesos) y v3 (9 197 / 4 496 / 2 360, 56 huesos) elegibles | 10 en todas: reposo, subterráneo, emerger, aviso, ataque, ataque_sismico, ataque_aliento, rugido, herida y derrota | Embestida, Fractura avisada a todos, Aliento que se puede cortar, clímax al 20 % y no huye (`combate_bramavidrio.gd`, `combate_climax.gd`) | Pendiente de elegir la versión. Sin clip de aturdimiento |
| Hollín | Solo como respaldo 2D del Grimfang | — | — | Retirado |
| **Cencerrante** (T-097) | GLB de 6 288 triángulos y 9 huesos, con escena y guion | 7: reposo, entrada, toque_de_alarma, campanada_baja, recibir_golpe, correr y derrota | **No está en ENEMIGOS** | Prototipo |
| **Vidracrán** | GLB de 2 330 triángulos y 34 huesos | 10: enterrarse, enterrado, emerger_aguijon, aviso_aguijon, pinzas… | Pensada para enterrarse sin poder ser objetivo (una regla nueva). **No está en ENEMIGOS** | Prototipo apagado |
| **Tolvanera** | GLB de 1 144 triángulos y 11 huesos | 10: rafaga, torbellino, agua_asienta, curarse_viento… | Pensada para que el Agua la asiente y el viento la cure. **No está en ENEMIGOS** | Prototipo apagado |

**Huecos principales [C]:**
1. **No hay enemigos por región.** Los encuentros al azar eligen entre los 5 primeros grupos o, con 1 o 2 héroes, la
   tabla `AL_AZAR_POR_TAMANO` (`combate.gd:324-328, 518-523`). En el desierto, la nieve o la ceniza salen Slimes,
   Grimfang y el Guardián de piedra. Solo cambia el nivel (`combate_escalado.gd`).
2. **No hay tabla general de afinidades.** La debilidad al fuego del Guardián y la piel del Coloso son ganchos propios
   (`combate.gd:4276-4277, 5226-5227`).
3. **Estados enemigos:** quemadura, congelación (resta PV máximos: `:2297-2320`), aturdido (interrupción), encogido,
   fases y estados de jefe. **No hay** veneno, ralentizar, bajar ataque o defensa, silencio ni ceguera (búsqueda sin
   resultados).
4. **Sin modelo propio:** Gorthor, el Gólem de ámbar y el Guardián de piedra.

---

## 4. Sistemas para la magia negra y el cuarto personaje

### 4.1 Cómo funciona hoy [C]

| Sistema | Dónde | Cómo |
|---|---|---|
| Magias de siempre (congeladas, D-048) | `combate.gd:91-97` (`MAGIAS`) y `:111-125` (`NIVELES_MAGIA`) | 4 familias (Fuego, Agua, Rayo y Cura) × 3 niveles. El I es a uno; el II y el III, a todos. Coste y daño fijos. El Fuego quema 2 rondas (`:23, 31`) |
| Daño mágico | `combate_formulas.gd:16-18` | `dano × magia_mult + magia_extra`, × `mult_magia` del héroe, ±3 |
| Aprendizaje | `grupo.gd:16, 180-197` | Niveles 1, 5 y 10 (`NIVEL_MAGIA`) o libros de la tienda (`grupo[heroe]["libros"][familia]`, que ya se guarda en la partida) |
| Quién usa qué | `grupo.gd:21-30` | Kael: Fuego y Rayo; Lya: Cura, Agua, Fuego y Rayo; Garon: nada. **«Nyx, Mago negro» sigue en HEROES, sin usar** (Fuego, Agua y Rayo) |
| Artes (T-091, sin daño) | `artes.gd` | Alba y Escarcha (Kael) y Lumbre (Lya), con umbrales propios (`:21`), libros y tomos (`:69-70`), estados en el diccionario del luchador (barrera, aliento, brasa) y fichas del Diario. **Como mucho 2 familias por héroe: no caben más pestañas** (`:17-18`) |
| Menú de magia | `combate.gd:2872-2925`; `artes.gd:430-443`; `menu_combate.gd:532-570` | Pestañas I · II · III (96 px), una de icono por familia (64 px) y DÚO (110 px), desde x = 808 hasta X_DERECHA = 1240 (unos 432 px) |
| Estados | Quemadura, congelado, aturdido, barrera, aliento, brasa, guardia, enfoque y los de los jefes | Viven en el diccionario del luchador y **no se guardan** |
| Afinidades | No hay tabla general; solo los ganchos de cada jefe | — |
| Garon | `combate.gd:2540-2558` (D-037) | Esgrima (Juicio y Giro) y Embuir (Fuego, Hielo, Rayo o Agua; el Hielo congela) |
| Dúos (V11) | `combate.gd:2925-2995` | Filo Arcano (Kael + Lya), Quiebra (Kael + Garon) y Barrera Rúnica (Lya + Garon). **Escritos pareja a pareja**, por nombre (`_duos_de`) |
| ATB | `combate.gd:17, 1630` | `atb += vel × delta` hasta 100. El Alba lo mueve |
| Armonía e invocación | `combate.gd:67-70, 2495-2512, 3718, 3994-4011` (D-038) | +0,15 por acción de héroe. **Solo la invoca Lya** (Érebo). Sin llenar no se puede |
| Investigación | `investigacion.gd`, `datos/tipos/investigacion.gd`, `datos/investigaciones/*.tres` (8) | Requisitos por material, hito, otra investigación o nivel (`:25-50`). Avanza un paso por combate ganado (`combate.gd:5708`). **Solo desbloquea recetas de taller** (`desbloquea`, `recetas_de`). Pantalla: `alquimia_menu.gd`. Talleres en `menus.gd:266-269` |
| Buscador (Kael) | `buscador.gd` (clave `buscador`) | Hallazgos con semilla, por región y nivel; hoy solo en el Mar de Cristal |
| Gremio | `gremio.gd` y `gremio_menu.gd` (clave `gremio`) | Contratos de derrotar, entregar y cumplir; solo en la Oakhaven 2D |
| Grupo | `grupo.gd:31, 57-93` | `EN_EL_GRUPO = [Kael, Lya, Garon]` es a la vez **la lista de héroes y el orden**. Activos según `grupo_activo`; sin esa clave, todos. Se unen por hitos (`SE_UNE_EN`). **No hay reserva ni cambio de grupo** |
| Combatientes | `combate.gd:373-381, 451-454` | Tres entradas fijas, con su sitio en pantalla por nombre; se filtran por los activos |
| Inventario y equipo | `inventario.gd:8, 71-99` | 8 ranuras. Equipo inicial por héroe, con migración para Garon. Armas de tipo `espada` o `cetro` (`grupo.gd:200`, `menus.gd:215`) |
| Menús | `menus.gd:18, 149-161, 367-397` | Grupo, Objetos, Habilidades y Ajustes. Solo enseñan a los activos |
| Guardado | `progreso.gd:60-64` | Claves `grupo`, `grupo_activo`, `inventario`, `investigaciones`… Sin reserva ni magias nuevas que guardar: se deducen de nivel + libros |

### 4.2 (a) Escuelas de magia negra sin duplicar sistemas

**Propuesta técnica (pendiente de que la fase E la diseñe):**

1. **Datos:** un módulo hermano de `artes.gd` (por ejemplo `magia_negra.gd`), con:
   - el mismo contrato: `NIVELES`, `UMBRALES`, `COLOR`, `DESCRIPCION`, `LIBROS`, `TOMOS`, `FICHAS`,
     `SONIDO_LANZAR`, `hechizos(heroe)` y `filas_familia(...)`;
   - **no** entrar en `NIVELES_MAGIA` ni en `MAGIAS`, que están congeladas (D-048). Así `_hechizos`
     (`combate.gd:2852-2861`) solo suma una lista más.
2. **Cada escuela, enlazada con lo que ya hay:**

| Escuela | Qué reutiliza | Qué es nuevo |
|---|---|---|
| Fuego | Quemadura (`DANO_QUEMADURA`, `RONDAS_QUEMADURA`) y el VFX de fuego | Nombres y niveles propios: no repetir Fuego, Llamarada ni Infierno |
| Hielo | `_congelar` y `_tic_congelacion` (`:2297-2320`); el color Hielo ya está en `menu_combate.gd:27` | La familia; hoy el Hielo solo existe en Embuir y en las artes |
| Rayo | `golpe_magico` (cuenta para cortar golpes preparados: `:2068-2069`) y el VFX de rayo | Variante que interrumpe |
| Sombras | La propuesta de `HISTORIA.md` §1.3 (Umbral, Lanza Sombría, Eclipse…) | VFX; **sin hablar de corazones ni recuerdos** (CLAUDE.md, D-038) |
| Gravedad | El tope de jefes del 20 % de Érebo (`INVOCACION.dano_jefe`) y el ATB del Alba | Daño en % de la vida actual, con tope en los jefes |
| Debilitamiento | Los estados del diccionario (como barrera o aliento) y sus iconos (`artes.gd:83-85`) | Bajar ataque o defensa con duración: hay que leerlo en `Formulas.dano_fisico` y en el daño recibido |

3. **Afinidades:** un `combate_afinidades.gd` con una tabla en `ENEMIGOS` (por ejemplo `"debil": ["Fuego"]`):
   - aplicada en los **dos únicos puntos** donde ya se ajusta el daño mágico por familia (`combate.gd:4276-4277` y
     `5226-5227`), junto a `Bosque.dano_recibido` y `Coloso.dano_recibido`;
   - el nombre de la familia ya llega como `magia`.
4. **Menú:** seis escuelas no caben como pestañas junto a I · II · III y DÚO (432 px):
   - opción recomendada: para quien sabe magia negra, **una pestaña de icono por escuela** (6 × 64 + 5 × 4 = 404 px),
     con los niveles en filas, como `filas_familia`, y **sin** pestañas I · II · III;
   - el DÚO ya no cabría: hay que pasarlo a la lista de órdenes o desplazar las pestañas;
   - **pendiente de verlo en pantalla** [?].
5. **Aprendizaje e investigación:**
   - el nivel y los libros ya se guardan (`grupo[heroe]["libros"]`): no hacen falta claves nuevas;
   - para «investigar» una escuela, ampliar `investigacion.gd` con un tipo de desbloqueo `magia:<escuela>:<nivel>`
     (hoy `desbloquea` solo admite recetas: `investigacion.gd:101-110`) y un taller nuevo en `alquimia_menu.gd` y
     `menus.gd:266-269`;
   - el avance por combates ganados ya existe (`combate.gd:5708`).
6. **Efectos visuales:**
   - `MAGIAS[magia]["color"]` se lee sin protección en `combate.gd:4659, 4740, 5067, 5192`;
   - la línea `:5008` ya hace `MAGIAS.has(...) else Artes.COLOR[...]`: hay que seguir ese patrón o la magia negra
     fallará al dibujarse.
7. **Pruebas:**
   - copiar `prueba_artes` y `prueba_artes_combate`;
   - no usar el generador global, para que la huella C0 no cambie (como dice `artes.gd:12`).

### 4.3 (b) Un cuarto protagonista con tres activos y reservas

| Qué | Archivo:línea | Cambio |
|---|---|---|
| Datos del héroe | `grupo.gd:21-30` | Una entrada nueva (clase, arma, multiplicadores, magias y atributos). Decidir qué hacer con «Nyx» |
| Lista y orden | `grupo.gd:31, 38-45, 60-66, 88-93` | Separar `EN_EL_GRUPO` (todos) de `MAX_ACTIVOS := 3`. `activos()` sin clave devuelve **todos** (serían 4) y `datos()` **crea al que falte en cualquier partida**, al nivel más alto: el cuarto aparecería en todas las partidas antiguas. Hay que ponerlo detrás de un hito, como `SE_UNE_EN` |
| Reserva | `grupo.gd` (nuevo) | `cambiar(activo, reserva)`, con Kael siempre activo. `grupo_activo` ya se guarda (`progreso.gd:63`) |
| Combate | `combate.gd:373-381, 451-454` | Entrada nueva en `heroes` y **sitio en pantalla por puesto** (1.º, 2.º, 3.º), no por nombre. `MODELOS` (naira3d) y `ANIM` (distancia) |
| Ganchos por nombre en el combate | `combate.gd:262` (`pies_golpe` de Bramavidrio), `2496-2512` (invocación solo de Lya), `2560` (Garon), `2971-2995` (dúos por pareja), `3938` y `4159` (Kael) | Revisar uno a uno: en el combate hay 22 apariciones de nombres |
| Color e iconos | `menu_combate.gd:26` | `COLOR_HEROE` (ya trae «Nyx») |
| Artes y magias | `artes.gd:18`; el módulo nuevo | El cuarto héroe es el natural para la magia negra |
| Equipo | `inventario.gd:77-79, 98-99` | Equipo inicial y migración (como la de Garon). Si su arma no es espada ni cetro: `grupo.gd:200` y `menus.gd:213-216` |
| Menús | `menus.gd:149-161, 266-269, 367-397` | Una pantalla de **Formación** (activos y reserva). Hoy los ausentes no salen en ningún menú |
| Exploración 3D | `zonas3d/grupo_3d.gd:45-46` | `RUTAS` y `ESCALA`. Con 3 activos siguen siendo 2 acompañantes |
| Esperas y gestos | `esperas_3d.gd:15-19` | Su `.res` y su clave |
| Experiencia | `combate.gd:5758-5761` | Hoy solo la ganan los que luchan: decidir si la reserva gana una parte (relacionado con D-062) |
| Dialogic y textos | `dialogos/personajes/`; las timelines con variantes `_lya` o `_solo` (`dialogos/mar_cristal/`) | Su `.dch` y retratos. Las variantes por grupo se multiplican |
| Talleres e investigación | `menus.gd:266-269`; `datos/tipos/investigacion.gd:8` | Requisitos de nivel con su nombre |

### 4.4 (c) Riesgos de compatibilidad con las partidas

1. **`grupo.datos()` crea a los héroes que faltan** (`grupo.gd:38-44`):
   - si se añade el cuarto a `EN_EL_GRUPO`, entra en toda partida al cargarla;
   - eso incluye la del PC, que **no tiene la clave `grupo`** y que no se toca (CLAUDE.md).
2. **`activos()` sin `grupo_activo` devuelve a todos:** el combate tendría 4 héroes y solo 3 sitios. La versión
   estable no guarda `grupo_activo`.
3. **Una partida nueva en una versión antigua:** `activos()` filtra por `EN_EL_GRUPO` (`grupo.gd:65`), así que un
   cuarto héroe se ignora sin error. Hay que revisar `menus.gd:163` y `372`, que leen `datos()[heroe]` solo de los
   activos (correcto).
4. **Magias y estados:**
   - las magias nuevas no necesitan claves si se deducen del nivel y los libros (como las artes);
   - los estados de combate no se guardan.
5. **Inventario:** el equipo del cuarto héroe necesita su migración en `inventario.datos()`.
6. **Dos archivos de partida:** `partida.save` y `partida_exp.save` (`progreso.gd:54-57`). Hay que probar las dos y
   las ranuras de prueba (`archivo_partida_prueba`).
7. **`FORMATO := 2`** (`progreso.gd:372`): si se añade la reserva, subirlo y migrar de forma explícita.

---

## 5. Rendimiento conocido

**Redmi A7 Pro (Mali-G57)** [D: `docs/v12/INFORME_REDMI_V12.md`, v581, v597, v607, v610 y v615]:
- FPS a los 22 s, en el punto de inicio y sin moverse;
- bajo y medio con tope de 30; el alto, con tope de 60.

| Región | Bajo | Medio | Alto | Memoria (bajo · medio · alto) |
|---|---|---|---|---|
| Mar de Cristal | 30,3-30,4 | 30,4 | 23,3-23,6 (p95 50 ms) | 745 · 761-774 · 865-908 MB |
| Pastos Verdes | 30,3 | 30,4 (con Pastoral Pulse: 30,4 · 828 MB) | 13,4 (p95 86) | 796 · 809 · 948 MB |
| Garganta 3D | 30,4 | 30,2 (**p95 50**) | 12,8 (p95 86) | 770 · 805 · 933 MB |
| Oakhaven 3D | 30,3 | 30,3 | 15,4 (p95 86) | 773 · 835 · 944 MB |
| Tormenta (medio) | — | 30,4 | — | — |

| Combate | Resultado |
|---|---|
| Bramavidrio v2, medio (v615) | Media 58,9, mínimo 47,5 en el Aliento, 0 perdidos. Alto 50-57. 879-924 MB |
| Bramavidrio v1, foto 2D | 62,4 |
| Clímax | 57,2 |
| Combates de la V11 | 54-60 [D: `docs/v11/PENDIENTES_REDMI.md`] |
| Ciudad 2D | 30 (su tope) |
| Pantalla de inicio alternativa | 36,8 · 762 MB |
| Carga del juego | 15-16 s |
| Carga del combate de Bramavidrio | **unos 18 s de negro** |

**Falta medir:**
- el Mar de Cristal con el arte de la noche (+3 a +10 llamadas de dibujo en el PC) y el bajo nuevo;
- Bramavidrio v3;
- Pastos con los rincones;
- los combates con el Guardián y el Coloso en el Redmi (sin cifras en los informes);
- las zonas 2D generadas y la Arboleda;
- recorrer cada región, no solo quedarse quieto en la entrada;
- la memoria en sesiones largas (ya llega a 900 MB);
- la carga del combate en general;
- el perfil alto, que **no se puede jugar** en Pastos, la Garganta ni Oakhaven (13-15 FPS).

---

## 6. Prioridades recomendadas

| Fase | Primero | Después | Riesgos |
|---|---|---|---|
| **B · Protagonistas** | Rig de Blender propio para Kael, Lya y Garon, que conserve los FBX de Meshy, con los clips que faltan (§2.2): saltar, interactuar, hablar, victoria, recibir daño, guardia y ataques de Lya y Kael. **Retrato de Garon** para Dialogic | Expresiones: los retratos 2D ya existen; en 3D, mejor cara por textura o huesos que formas, por el coste en el Mali | Que el rig nuevo cambie los tiempos de impacto del combate (`SALTO_T`, `combate.gd:33`). El presupuesto de 3 × 10 k triángulos ya es alto en Oakhaven. Licencia de Meshy |
| **C · Enemigos** | Tabla de **encuentros por región** (hoy no hay ninguna) y modelos propios para Gorthor, el Gólem y el Guardián de piedra | Enganchar Vidracrán, Tolvanera y Cencerrante; tabla de afinidades (§4.2.3) | Cambia el azar (la huella C0 de las pruebas) y el equilibrio. Cada modelo nuevo cuesta unos 5 FPS en combate |
| **D · Migración 3D** | Matriz §1.6: Garganta por defecto, el Mar de Cristal completo con el lore del Acto II, y después Oakhaven entera | Bosque, Cumbres… | Las partidas guardadas en `zona.tscn` no saltan a 3D. Contenido que solo existe en 2D (hallazgos). Rendimiento de Oakhaven |
| **E · Magia negra** | Módulo de escuelas con el patrón de `artes.gd` y afinidades; menú por escuela | Investigación arcana (desbloqueos de magia en `investigacion.gd`) | D-048 (no tocar las 12). Las pestañas no caben. `MAGIAS[...]` sin protección en 4 sitios |
| **F · Naira** | Tres conceptos y su encaje en la biblia; grupo con reserva (§4.3), con el cuarto detrás de un hito | Modelo y rig de Blender con el contrato de clips de la fase B | `grupo.datos()` y `activos()` con partidas antiguas (§4.4). Decidir qué pasa con «Nyx». Su historia no puede revelar nada antes del acto III |
| **G · Integración** | Batería completa y pruebas nuevas por fase; APK de Auditoría; Redmi con la tabla del §5 | Pasar las regiones a «por defecto» | Las importaciones sin aislar (incidentes del 11/11). `project.godot` tras importar. Copiar archivos, no fusionar |

**Orden propuesto dentro de la fase:**
1. Garganta por defecto (S).
2. Grupo con reserva y sin cuarto héroe visible (base de F, sin riesgo de contenido).
3. Encuentros por región (C).
4. Clips mínimos de la fase B.
5. Escuelas de la fase E.
6. Naira (F).
7. Oakhaven 3D completo (D), que depende de los NPC con esqueleto.

---

## 7. Sin verificar en esta auditoría

- **Nada se ha ejecutado:** ni Godot, ni la batería ni el Redmi. Las cifras de rendimiento y de las pruebas son de los
  informes.
- **Triángulos de los FBX:** contados por los índices de `PolygonVertexIndex` divididos entre 3, así que son
  aproximados. Los de los GLB son exactos (la suma de las mallas).
- **Templo y Abismo inalcanzables a pie:** deducido del generador del mapa, sin jugarlo.
- **El ancho de las pestañas para seis escuelas:** calculado con las constantes, sin verlo en pantalla.
