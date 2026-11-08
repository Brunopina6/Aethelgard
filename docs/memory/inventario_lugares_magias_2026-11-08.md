# Inventario de lugares, canon pendiente y sistema de magia (08/11/2026, 23:30)

Hecho por un agente de búsqueda de solo lectura sobre `integracion-experimental` (`dddbddb`) y la biblia v2
(`D:\Aethelgard\docs\biblia\rebelum_biblia_narrativa_v2.md`, que marca [C] lo que es canon y [P] lo que es
propuesta). Sirve para planificar [T-089](../../TASKS.md#t-089), [T-090](../../TASKS.md#t-090) y
[T-091](../../TASKS.md#t-091). Observado en el código; pendiente de comprobar ejecutando.

## 1. Lugares que existen

**Destinos del mapamundi** (`mapa.gd:39-66`). `_entrar` (:620-661) guarda el índice en `Engine.meta("lugar")`. El
estilo de cada zona sale de `ZONA_LUGAR` (:37).

| Índice | Lugar | Escena y estilo |
|---|---|---|
| 0 | Oakhaven | `zona.tscn`, estilo ciudad |
| 1 | Gran Bosque Verde | `zona.tscn`, «bosque» |
| 2 | Garganta del Diablo | `garganta.tscn` |
| 3 | Ciclópea | `zona.tscn`, «nieve» |
| 4 | Calid | `zona.tscn`, «desierto» |
| 5 | Sunken City | `zona.tscn`, estilo ciudad |
| 6 | Valle de los Ecos | `zona.tscn`, «yermo» |
| 7 | Templo Sumergido | `zona.tscn`, «llanura». Es una isla: no se llega andando, porque el Astraea no existe (`mapa.gd:591`) |
| 8 | Abismo de Ceniza | `zona.tscn`, «ceniza». También es una isla |
| 9 | Portal del Vacío | `isla.tscn` |
| 10 | Pastos Verdes | `zonas3d/pastos_verdes_3d.tscn`, solo en modo 3D (`modo3d.gd:12-25`) |

**Ciudades**
- **Oakhaven y Sunken City** son la misma ciudad, generada por `zona.gd` con un TileMapLayer y objetos dibujados por
  código; solo cambia la semilla (:345). Tienen:
  - plaza, hasta 34 casas y farolas (:362-485);
  - los **mismos 4 NPC** (:2181-2198, `dialogos/npc_aldric|selene|pip|rosa.dtl`);
  - TIENDA (`tienda.gd:11-17`) y POSADA a 30 monedas (:2308-2342);
  - estelas de lore (`progreso.gd:24-40`);
  - ni cofres ni encuentros (:2474).
- **Arboleda Mítica** (`isla.gd`): una imagen renderizada de Meshy con máscaras de paso y profundidad (:2-14). Tiene 4
  NPC con frases, sin Dialogic (:26-43), y la salida por el portal (:488-501).

**Otros lugares**
- **Zonas generadas** (1, 3, 4, 6, 7 y 8): un camino del sur a un altar; ruinas, campamento y claro, con un cofre cada
  uno (:370-387, :535-555); río con puentes, salvo en el desierto; encuentros aleatorios (:2469); salida por el sur
  (:2461).
- **Garganta** (`garganta.gd`, que hereda de `zona.gd` con un trazado fijo): 8 pantallas y el nido, con palanca,
  puerta y ascensor (:233-262); puntos de guardado y un cofre raro (:297); combates fijos y Gorthor (:344-347).
- **Pastos Verdes 3D** (hereda de `prototipos/sendero_puente.gd`; código y MultiMesh): la misión PV-02 a PV-14 con
  Tilo, la estela, el cofre, el centinela, la cinemática y dos salidas.
- En 2D no hay misiones: el botón «Misiones» muestra un texto fijo (`mapa.gd:592`).

## 2. Canon (v2) que falta en el juego

- **Tienen destino, pero su zona es genérica:**
  - Bosque: santuario y Núcleo.
  - Ciclópea: Glacius.
  - Calid: Lente del Sol y máquina.
  - Sunken City: buque, Compañía del Águila y Astraea.
  - Valle de los Ecos: la v2 propone cerrarlo hasta el acto III (:151).
  - Templo Sumergido y Abismo de Ceniza.
- **No tienen destino** (v2 :235-252 y :769-785):
  - [C] Taberna del Cuervo Oxidado, crematorio y Árbol Milenario: irían dentro de Oakhaven;
  - [C] Templo del Cristal del Cielo (`isla.gd:28`): está cerrado;
  - [C] Océano de Bruma y Abismo Quebrado: hoy solo son rótulos (`mapa.gd:68-71`);
  - [P] Cripta de las Urnas, Vía del Peregrino, Escalera del Cielo, Aldea Rocío, Gruta del Velo, Arcos de la Sombra,
    Fábrica de Calid, Casco del buque, Pico de la Escarcha y el Confino.
- **D-033:** nada antes del acto III sobre Érebo y los corazones o recuerdos. Afecta a los Arcos de la Sombra, la
  Gruta del Velo, el Confino, el Templo Sumergido y la gema de Érebo. En esos sitios caben pistas, pero sin
  explicación.

## 3. Magia

- **Datos:**
  - `combate.gd:65-71`, `MAGIAS`: coste, daño base, color, `quemadura` y `cura`;
  - `combate.gd:85-99`, `NIVELES_MAGIA`: tres niveles con nombre, coste, daño y `todos`;
  - el elemento es el nombre de la familia;
  - efectos visuales en :77-80 (`vfx/*.tscn`), con alternativa en 2D (:3003);
  - la magia no tiene sonido: solo lo tiene Érebo (`invocacion_base.gd:197`).
- **El comportamiento se decide por el nombre:** `_golpe_visual` (:2912), `_lanzar` (:3397), `_magia_grupal`
  (:3290-3303), `_desc_magia` (:1765) y el daño (:1868).
- **Aprendizaje** (`grupo.gd:21-30`):
  - Kael: Fuego y Rayo.
  - Lya: Cura, Agua, Fuego y Rayo.
  - Garon: ninguna (D-037).
  - Los niveles llegan en los niveles 1, 5 y 10 (:16, :171) o con los libros de la tienda (:182; `tienda.gd:16-17`).
- **Menú:** MAGIA (:1507) abre `_menu_magia` (:1737), con pestañas I-III (`menu_combate.gd:309`); los iconos y
  colores, en :22-23 y :515-543. La pestaña Habilidades está en `menus.gd:323`.
- **Para añadir una magia sin tocar las existentes:**
  - una familia nueva en los dos diccionarios, con tres niveles (`menus.gd:332` y `_hechizos` (:1719) lo dan por
    hecho);
  - el aprendizaje en `HEROES` (nunca para Garon);
  - ramas nuevas en los `match`; si no, su nivel III acaba en `_maremoto`;
  - efecto visual y sonido en el bus Efectos;
  - si aplica estados, campos y turnos nuevos: hoy solo los enemigos procesan quemadura y congelación (:1206-1213).
- **Decisiones relacionadas:**
  - D-015: PM infinitos, solo en pruebas.
  - D-017: Frostfang congela.
  - D-037: Garon no usa magia.
  - D-038 y D-039: Érebo.
  - D-060: ningún enemigo aturde ni duerme.
  - D-062: la nivelación automática es una propuesta.
  - D-071: magias nuevas.
  - D-H03 y D-H07.
  - Las propuestas de estados, talentos e IA están en `MEMORIA_CHAT.md:392-430`.
- **D-048** congela las 12 magias actuales (ID, nombre, aprendizaje, coste, daño, fórmulas, objetivos, animaciones y
  comportamiento), además de Esgrima, Embuir, Érebo, la Armonía y el ATB. Lo nuevo se añade sin modificar nada de eso.

## 4. Riesgos

- **Partidas antiguas:**
  - el índice del lugar identifica `lugar`, `DETALLES` y los cofres (`zona.gd:1761`); si se regenera una zona
    existente, sus cofres se mueven y se pueden volver a abrir;
  - los lugares nuevos van **al final** de `LUGARES` (Pastos es el 10), con `ZONA_LUGAR` creciendo a la vez
    (`mapa.gd:178`);
  - cambiar `RUTAS` rehace el continente (:103);
  - las claves nuevas, solo al final de `CLAVES` (`progreso.gd:60`);
  - el nivel de magia se calcula, no se guarda: una magia nueva aparece al momento en las partidas viejas.
- **Rendimiento:**
  - la caché de zonas (`zona.gd:911`) y las farolas con luz;
  - la imagen grande de la isla y el precalentado 3D;
  - `carga.gd:290-293` precarga todos los efectos visuales;
  - en el móvil, como mucho 2 efectos 3D a la vez (`combate.gd:76`).
- **Pruebas afectadas:**
  - lugares: `prueba_zona3d.gd:152`, `prueba_isla.gd:25` y `prueba_foco.gd:276`, más las de escenas, cofres,
    música, guardado y 3D;
  - magia: `prueba_menu_magia`, `prueba_equilibrio.gd:17`, `prueba_mando.gd:291`, `prueba_ia` y `prueba_audio`.
