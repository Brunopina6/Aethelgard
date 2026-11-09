# Informe del especialista de combate

Rama `area-combate`, copia `D:\Aethelgard_combate`. Cada entrega añade una sección; no se borran las anteriores.

## 2026-11-09, 00:25 · Fase 0 de T-091, T-092 y T-093 (solo diseño)

**Encargo:** diseñar, sin tocar código ni ejecutar Godot, las magias nuevas (T-091), los accesorios y las armas
especiales (T-092) y los enemigos nuevos (T-093), según D-071 y D-072.

**1. Archivos y commits** (base `dddbddb`):
- `docs/diseno/combate_ampliaciones.md` (nuevo): el diseño completo. Commit `4911e50`.
- `docs/memory/agents/combate.md` (este informe, nuevo): commit siguiente.
- Ningún archivo de código tocado.

**2. Pruebas:** ninguna. Es una fase de diseño y el encargo pedía no ejecutar Godot.

**3. Evidencias:**
- **Observado en el código** de `dddbddb`: las líneas se citan en el documento.
- **Ganchos de sonido** mirados en `area-sonido` @ `1359386` (`Sonido.efecto`, `Sonido.golpe`), sin integrar todavía.
- **Memoria contrastada** el 09/11 a las 00:05: la rama remota `memoria-desarrollo` (`19982f0`) es igual que la copia
  local.

**4. Hallazgos que condicionan el diseño** (observado en el código):
- **El sistema de equipo ya existe:** 7 ranuras, 6 armas y 16 protecciones. Frostfang ya es un arma especial
  (congela). Por eso se añade una ranura y no un sistema nuevo.
- **El menú de magia no admite una quinta familia:** Lya ya llena las 4 filas que caben sobre el bloque del grupo
  (y = 562 con tres héroes). Por eso, una pestaña con icono por familia nueva.
- **Nadie revive en combate,** pero los tres modelos 3D tienen `revivir()` sin usar.
- **La personalidad «apoyo»** (chamán) existe y no la usa ningún enemigo.
- **Encuentros:** los mismos 5 grupos en todo el mundo. Los enemigos no tienen debilidades ni botín.
- **El Templo Sumergido** usa el estilo «llanura» (nivel 2): sus enemigos huirían casi siempre por «zona limpia».
- **Riesgos de código:**
  - poner el ATB a 100 a mano deja a un héroe sin turno (no vuelve a la cola);
  - un héroe que muere con la barra llena se queda sin turno al revivir si no se le vacía;
  - `_golpe_visual` con «Fuego» encendería una quemadura en un héroe que nadie apagaría;
  - un id de equipo desconocido rompe los menús (`menus.gd:283`, `inventario.gd:162`).

**5. Límites:**
- Nada comprobado ejecutando: las cifras son de partida y la geometría del menú sale de las constantes.
- El determinismo de la prueba de huella (C0) está pendiente de comprobar.
- Las licencias del limo y de las tiras del Hollín están sin registrar.
- Algunos lugares de los secretos dependen de T-089 y T-090.

**6. Siguiente paso propuesto:**
- **C0** (semilla y huella del combate) y después **M1** (familias y Compás del Alba). Orden completo en el documento,
  §6.
- **Decisiones para el usuario,** en §7: el menú por pestañas, las debilidades contra los enemigos nuevos, el
  aprendizaje por nivel o por tomos, P1 «Guardia a tiempo»…

**7. Cambios que necesito en archivos de otros** (§8 del documento):
- **`sonido.gd`:** el catálogo de efectos nuevos; sin usar el generador aleatorio global durante el combate.
- **`material_arma.gd`:** `tinte` y `color_brillo` opcionales.
- **`goblin_3d.gd`:** la variante con bastón y la señal «antes del golpe».
- **Mundo** (`zona.gd`, `garganta.gd`, `isla.gd`, `zonas3d/`): cofres que llamen a `Recompensas.dar(id)`.
- **`fondo_combate.gd`:** fondo «templo».
- **`diario.gd`:** fichas nuevas.
- **`carga.gd`:** precargar las tres escenas nuevas de `vfx/`.
- **`docs/recursos.md`:** la procedencia del limo y del Hollín.

## 2026-11-09, 08:50 · Fase 1 de T-091 a T-093: C0, y M1, M2 y C1 preparados en archivos nuevos

**Encargo** (coordinador, 09/11): la red de seguridad C0 (huella del combate con semilla fija y su referencia) y la
preparación de M1, M2 y C1 en archivos nuevos, **sin enganchar** a `combate.gd`, los menús ni `grupo.gd`, con sus
pruebas y la lista exacta de enganches.
- **Base:** `area-combate` @ `2cb8221`; tras la parada por el límite de uso, @ `2386761` (con la tanda 2 de sonido),
  importada con datos aislados (`D:\REBELUM_diagnostico\importaciones\combate_20261109_073909`).
- **Decisiones del coordinador aplicadas:** pestañas por familia detrás de I · II · III; la ranura se llama
  «Accesorio»; las artes se aprenden por nivel y con libros o tomos.
- **Pendientes del usuario, sin implementar:** las debilidades, P1 «Guardia a tiempo», P2 «Eclipse», los aspectos
  provisionales y las Fauces de Gorthor (por eso, nada de E1 a E3).

**1. Commits** (todos en `area-combate`; ningún archivo ajeno tocado):
- `1139d38` · C0: `pruebas/prueba_combate_huella.gd`, `pruebas/referencias/huella_combate.txt` y su línea en
  `lista_pruebas.txt`.
- `0127900` · M1 y M2: `artes.gd` y `pruebas/prueba_artes.gd` (con sus `.uid` y el de la huella) y su línea.
- `81ac8ba` · C1: `equipo_extra.gd` y `pruebas/prueba_equipo.gd` (con sus `.uid`) y su línea.
- `dbb27c5` · Enganches: `docs/diseno/combate_enganches.md`; `pruebas/combate_con_artes.gd` (solo pruebas) y
  `pruebas/prueba_artes_combate.gd` (con sus `.uid`) y su línea; «con_enganches» en la huella.
- Este informe: el commit siguiente.
- **Sin tocar:** `combate.gd`, `menu_combate.gd`, `menus.gd`, `tienda.gd`, `grupo.gd`, `inventario.gd`, `progreso.gd`,
  `sonido.gd`, `zona.gd`, `garganta.gd`, `zonas3d/`, `dialogos/` y `mapa*`.

**2. C0: la huella es estable** (comprobado ejecutando, aislado, 09/11, `2386761`)
- **Ocho combates** con guion:
  - E1, Kael solo: Fuego, Defender, Rayo, Éter y Poción;
  - E2, Kael y Lya: Agua, Cura, Fuego, Rayo y Poción;
  - E3, los tres: Érebo, Juicio, Éter, Giro, Cura y Agua;
  - E4 y E5, nivel 10: Llamarada, Tormenta, Torrente, Bendición, Maremoto y Gracia Divina;
  - E6, huida; E7, derrota (`curar_todos`);
  - E8, Gorthor: presentación, quemadura, golpe devastador cargado, Érebo sobre el jefe, segunda fase, Embuir, Juicio,
    Giro, último aliento y «perdonar», con `combates_ganados` y `decisiones`.
- **Lo que anota:** cada turno, cada cartel y cada cambio de PV y PM con su fotograma; el final, el grupo (también los
  ausentes), el oro y los objetos. 506 líneas, SHA-256 `a33fdae7…`.
- **Estable:** dos pasadas en un proceso (`D:\REBELUM_diagnostico\pruebas\2026-11-09_080207`), otro proceso
  (`…_080259`) y E3 y E8 solos (`…_080327`) dan exactamente lo mismo. Contra la referencia, desde la lista:
  `…_080448`.
- **Cubre 10 de las 12 magias.** Infierno y Cólera del Cielo quedan fuera hasta el arreglo de C0 (abajo).
- **Determinismo sin tocar `combate.gd`:** la prueba siembra el generador global justo después de `_ready` (que llama a
  `randomize()`) y vuelve a repartir el ATB inicial de los enemigos con la semilla. Cada combate lleva su semilla:
  `solo=E3` da la misma huella que la lista entera.
- **Hallazgos al buscar el determinismo** (comprobado ejecutando):
  1. Con `--fixed-fps 30`, los fotogramas 4 a 6 del proceso dan pasos de 0,029167, 0,030 y 0,0325 s. El primer
     combate de cada proceso salía distinto (E1: 24 de daño o 28; `…_075602` y `…_075614`). La prueba espera 15 pasos
     fijos seguidos antes de empezar. **Afecta a cualquier prueba que quiera ser determinista desde el fotograma 1.**
  2. En Godot 4.7, `RandomNumberGenerator.new()` **empieza al azar** (dos procesos: 1189864965 y 2393320160).
     `_lluvia_meteoros` (Infierno, sin semilla) y `_tormenta` (Cólera del Cielo, `randomize()`) reparten sus adornos
     al azar. E4 con Infierno dio 3 huellas distintas en 6 pasadas (`…_080026`); sin él, 6 iguales (`…_080114`).
  3. **Deducido, sin verlo en el código del motor:** las `CPUParticles2D` tiran del generador global. Los adornos de
     Infierno no llaman a `randf()` en GDScript; solo crean partículas. Por eso la huella depende también de los
     efectos visuales.
- **Arreglo propuesto para `combate.gd`** (no aplicado): `rng.seed = randi()` en `_lluvia_meteoros` y `_tormenta`, y
  `-- semilla=N` en `_ready` para las demás pruebas. Detalle en `docs/diseno/combate_enganches.md` §1. Con él,
  Infierno y Cólera del Cielo entran en la huella.
- **La huella cambia** si cambian las reglas, el equilibrio, el orden de las tiradas del generador global (también las
  visuales: `_temblor`, partículas, el rayo 3D) o lo que duran las animaciones. Entonces se mira la primera línea
  distinta y, si el cambio es el esperado, se saca otra referencia (cómo, en su cabecera) y se explica en el commit.

**3. Módulos nuevos** (observado en el código y comprobado con sus pruebas)
- **`artes.gd` (M1 y M2):**
  - **Datos:** las nueve artes, que no hacen daño (Alba, Escarcha y Lumbre, con los PM del diseño), con descripciones
    y motivos de fila apagada.
  - **Aprendizaje:** Alba 3/9/16, Escarcha 6/12/20 y Lumbre 4/10/18. Ninguna en el nivel 1 y ninguna para Garon. Se
    calcula con `grupo.datos()`; libros y tomos van en `libros`, como los de siempre.
  - **Lógica sobre los diccionarios de luchador:** el ATB no llega a 100 a mano, y el retraso saca de la cola (los
    jefes, la mitad); a quién va cada arte; revivir con la barra a 0 y fuera de la cola; Aliento; coraza que no se
    suma; Brasa.
  - **Menú:** pestañas (caben hasta x = 1240), filas e iconos de familia y de estado, dibujados por código.
  - **`ACTIVOS`** limita lo que saldrá en el juego: Alba I y II, y Lumbre I y II.
  - **Grupo:** no necesita `grupo.gd` cambiado.
- **`equipo_extra.gd` (C1, y los datos de C2):**
  - **Objetos:** la ranura «accesorio», 8 accesorios y 6 armas especiales con «solo». Las armas reutilizan las mallas
    de hoy, con `tinte` y `color_brillo`.
  - **Efectos:** se suman con topes; el equipo de hoy y los ids desconocidos dan `{}`.
  - **Ganchos puros:** ATB inicial, crítico con la misma tirada, esquiva que solo tira con la pluma, monedas una vez,
    PM por turno, robo de vida, ataque por recuerdos, réplica y cubrir.
  - **`HECHOS`:** solo se vende y se da lo enganchado. También las tiendas por lugar y `conseguir(id)`.
- **Ninguno de los dos tira del generador global** (salvo la esquiva con la pluma puesta, una tirada). Así lo
  comprueban sus pruebas.
- **Un detalle del diseño:** Peso del Ocaso (Alba II) no estaba en ningún incremento. Lo dejo con M1, porque es el
  mismo mecanismo (`ACTIVOS["Alba"] = 2`); si se prefiere, se pone a 1.

**4. Pruebas** (todas con datos aislados, 09/11; resultados SUPERADA salvo donde se dice)
- **`prueba_combate_huella`:** dos pasadas, referencia y una tercera pasada con los enganches de M1 y M2.
- **`prueba_artes`** (10 apartados):
  - lo protegido de D-048 y D-037 en `combate.gd` y `grupo.gd`: las 12 magias, Esgrima, Embuir, Érebo, la Armonía,
    el ATB y Garon sin artes;
  - umbrales, ATB, objetivos, Lumbre y Escarcha, y las nueve artes con sus valores;
  - menú, iconos (el modo sin ventana sí dibuja) y generador global;
  - guardar y cargar.
- **`prueba_equipo`** (7 apartados): datos; «solo»; suma; ganchos; lo disponible; guardar y cargar, en memoria y en
  `user://prueba_equipo.save`; partidas antiguas; ids desconocidos; generador global.
- **`prueba_artes_combate`:** el código de los enganches de M1 y M2 en un combate de verdad, con
  `pruebas/combate_con_artes.gd`, una subclase de `combate.gd` solo para pruebas:
  - el Compás del Alba: una entrada en la cola, un solo turno de Lya, 6 PM y Armonía +0,15;
  - Segundo Aliento: cura un 8 % al empezar el turno y le quedan 2;
  - Peso del Ocaso baja la barra de los Slimes;
  - Lumbre de Retorno: vuelve con el 25 %, la barra a 0, fuera de la cola, y actúa;
  - el Compás sale apagado, con su motivo, con Kael solo;
  - el menú de Lya a nivel 1 es el de hoy.
  - Evidencia: `…_083028`.
- **La huella con los enganches de M1 y M2 es la misma** que la referencia (`…_083028`): sin usar las artes, los
  enganches no cambian el combate.
- **Mutaciones** (`…_081752`), y los módulos, restaurados: con el Compás a +55, `prueba_artes` FALLIDA; sin «solo»,
  `prueba_equipo` FALLIDA, con 3 fallos. Las pruebas no están vacías.
- **Batería completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_083311\resumen.md`): **43 SUPERADAS, 0 FALLIDAS**,
  23 MANUALES y 0 NO SEGURAS.
  - La partida real, la carpeta real de datos y los archivos del proyecto, sin cambios.
  - Había 14 Godot de otras copias, vigilados.
  - Dentro, la huella hizo 3 pasadas iguales a la referencia (la tercera, con los enganches), en 57,8 s.

**5. Enganches pendientes:** `docs/diseno/combate_enganches.md`.
- **Contenido:** archivo, función, línea en `2386761`, ancla exacta y código.
- **C0:** 3 líneas en `combate.gd`.
- **M1 y M2:**
  - `combate.gd`: 2 constantes, 5 cambios y 5 funciones nuevas;
  - `menu_combate.gd`: 1 constante y 3 cambios;
  - `menus.gd`, `tienda.gd` y `diario.gd`: 1 cambio cada uno.
- **C1:**
  - `inventario.gd`: 7 cambios;
  - `combate.gd`: 5;
  - `menus.gd` y `tienda.gd`: 2 cada uno.
- `grupo.gd` y `progreso.gd`: **ninguno**.
- **La huella no debe cambiar** con ningún enganche salvo C0.2 y C0.3.
- Al enganchar M1 y M2, se borra `pruebas/combate_con_artes.gd` y `prueba_artes_combate` pasa a usar `combate.tscn`.

**6. Riesgos**
- **La huella es sensible a los tiempos** (2.3): una tanda de animaciones o de sonido que alargue un golpe la cambia.
  Hay que revisar la diferencia y sacar otra referencia con su explicación. No es un fallo del combate.
- **`combate_con_artes.gd` copia** `_siguiente_turno`, `_menu_magia` y el principio de `_carga_magia` de `2386761`. Si
  `combate.gd` cambia antes de enganchar, puede quedarse atrás. La huella con «con_enganches» lo detectaría en lo que
  juega.
- **Las líneas del documento** son de `2386761`. Si otra tanda las mueve, sirven las anclas.
- **Al enganchar, cambiar `HECHOS = ["C1"]`** en `equipo_extra.gd`: sin eso, no se vende nada.
- **Partidas:**
  - las artes aparecen por nivel al cargar una partida antigua (decidido);
  - una partida nueva abierta con una versión anterior rompería sus menús con un id desconocido (diseño, §4.7).
- **Licencias:** las armas especiales reutilizan `espada2`, `diamante_azul`, `vara` y `hoja_infernal`, que están en
  `licencias_pendientes.txt` («Origen sin registrar»). No añaden recursos, pero dependen de esos.
- **Iconos de estado** (x 935-995): pueden rozar unos PV largos; solo se ve con capturas.

**7. Límites**
- **Nada enganchado en el juego:** ni los menús ni los iconos se han visto en pantalla (sin capturas), y no se ha
  medido nada en el móvil (no se pedía medir fotogramas).
- **El combate con artes** usa una subclase de prueba, no `combate.gd`.
- **Lo de las partículas** (2.3) es una deducción.
- **Los combates ganados con guion** no prueban la estrategia de un jugador.

**8. Siguiente paso propuesto y peticiones**
1. **El coordinador aplica C0** (3 líneas). Yo meto Infierno (E4) y Cólera del Cielo (un E9) en la huella, compruebo
   dos pasadas y saco otra referencia.
2. **Enganchar M1 y M2** con el documento, borrar la subclase y añadir capturas del menú y de los iconos. Después, C1
   con `HECHOS = ["C1"]`.
3. **Sonido:** catálogo `arte_alba`, `arte_ocaso`, `arte_hora_dorada`, `arte_escarcha`, `arte_lumbre`, `renacer`,
   `aliento`, `barrera_absorbe`, `barrera_rota`, `brasa` y `esquiva`.
4. **Gráficos:** `tinte` y `color_brillo` en `material_arma.gd` (C2).
5. **Para el usuario,** además de las de §7 del diseño: ¿Peso del Ocaso con M1, o más tarde?

## 2026-11-09, 12:50 · Fase 2 de T-091 y T-092: C0, M1, M2 y C1 enganchados al juego

**Encargo** (coordinador, 09/11): enganchar C0, M1, M2 y C1 con `docs/diseno/combate_enganches.md`.
- **Base:** `area-combate` @ `555fc29` (= `integracion-experimental`: mi fase 1, mapamundi, sonido y animaciones en sus
  tandas 1 y 2, Garganta 3D y Oakhaven fase 1). Importada con datos aislados
  (`D:\REBELUM_diagnostico\importaciones\combate_20261109_084817`; otra, para los `.uid` nuevos, `…_123009`).
- **Decisiones aplicadas:** C0 aprobado; Peso del Ocaso con M1; `ACTIVOS` = Alba 2, Escarcha 0, Lumbre 2;
  `HECHOS = ["C1"]`.
- **Archivos tocados:** `combate.gd`, `menu_combate.gd`, `menus.gd`, `tienda.gd`, `inventario.gd`, `artes.gd`,
  `equipo_extra.gd` y pruebas. **Sin tocar:** `grupo.gd` (no hizo falta), `diario.gd`, `progreso.gd`, `sonido.gd`,
  `audio/**`, `zonas3d/**`, `mapa*`, `zona.gd`, `ciudad_oakhaven.*`, `ciudades/**` y las filas de Ajustes de `menus.gd`.
- **Sin confirmar en la copia:** `project.godot` (los directorios de Dialogic de Oakhaven) y 43 `.uid` de narrativa y de
  la Garganta 3D. Los dejó la importación; no son míos y no los confirmo (son los «44 cambios» que vio el coordinador).

**1. Commits** (todos en `area-combate`):
- `30780e5` · **C0**: `combate.gd` (3 líneas), la huella con E9 y su referencia nueva.
- `653d7b6` · **M1 y M2**: `combate.gd`, `menu_combate.gd`, `menus.gd` (Habilidades), `tienda.gd` (libros), `artes.gd`;
  `prueba_artes_combate` con `combate.tscn`; se borra `pruebas/combate_con_artes.gd`.
- `a3c4432` · **C1**: `inventario.gd`, `combate.gd`, `tienda.gd`, `menus.gd` y `equipo_extra.gd`; `prueba_equipo_combate`.
  (El asunto dice `HECHOS = [C1]`: PowerShell 5.1 se comió las comillas. No lo reescribo.)
- `5e3bf18` · **Menú de combate**: nombres largos sin pisar el coste; `prueba_controles_nuevos` y `prueba_combate_fotos`.
- `075946e` · `prueba_huir`: el clic llega a HUIR sin ventana y la prueba comprueba que se huye.
- Este informe y el estado de `docs/diseno/combate_enganches.md` (§7): el commit siguiente.

**2. Qué se juega ya** (observado en el código y comprobado ejecutando, aislado, 09/11)
- **Kael, Alba** (pestaña con el sol, detrás de I · II · III):
  - Compás del Alba, desde el nivel 3: 6 PM; un aliado gana media barra. Sale apagado si no hay otro aliado en pie o si
    ya espera su turno.
  - Peso del Ocaso, desde el nivel 9: 15 PM; los enemigos pierden 40 de barra, los jefes 20.
- **Lya, Lumbre** (pestaña con el farol):
  - Lumbre de Retorno, desde el nivel 4: 14 PM; levanta a un caído con el 25 % de sus PV, la barra a 0 y fuera de la
    cola; el modelo 3D se levanta.
  - Segundo Aliento, desde el nivel 10: 16 PM; tres turnos de cada aliado, un 8 % de PV al empezar su turno; icono de
    hoja junto al nombre.
- **Libros** en todas las tiendas: Peso del Ocaso (350) y Segundo Aliento (450).
- **Al subir de nivel:** «Kael aprende Compás del Alba». **Habilidades** enseña las artes con su nivel.
- **Accesorio:** la octava ranura del menú Grupo.
  - Se venden el Farol de peregrino (Oakhaven, 220: empieza con 35 de barra) y la Moneda del Águila (Sunken City, 450:
    +25 % de monedas, una vez).
  - Enganchados y probados, pero todavía sin cómo conseguirlos (los dará el mundo con `conseguir(id)`): Diente de
    Grimfang (crítico de 0,12 a 0,20, la misma tirada), Gota de la cascada alta (+2 PM al acabar el turno), Cinta de Lumi
    (+5 % de PV al empezar el turno) y Pluma de arpía (esquiva el 12 % de los golpes físicos).
- **Sonidos de las artes y de la esquiva:** solo si están en el catálogo de `sonido.gd`. Hoy no están: no suenan ni
  avisan.
- **Garon** no tiene artes; las 12 magias, Esgrima, Embuir, Érebo, la Armonía y el ATB, sin cambios (la huella).

**3. La huella**
- **Sobre `555fc29`, antes de tocar nada:** igual a la referencia (8 de 8, SHA `a33fdae7…`), también con la pasada de
  los enganches (`D:\REBELUM_diagnostico\pruebas\2026-11-09_084905`). Las tandas de animación y sonido no la cambiaron:
  no hizo falta otra referencia por eso.
- **C0** (comprobado ejecutando, aislado):
  - sin las dos líneas de `rng.seed = randi()`, E9 dio 5 huellas distintas en 6 pasadas; cambió hasta el daño
    (Guardián 180 → 106 o 110) (`D:\REBELUM_diagnostico\combate\2026-11-09\ejecuciones\20261109_115849_huella_e9_sin_c0`);
  - con ellas, 3 pasadas iguales en un proceso (`…_115830_huella_e9b`) y lo mismo en todas las pasadas posteriores.
- **E9** (nivel 10, grupo 4): Lya se defiende, Kael lanza Infierno y Lya, Cólera del Cielo. Va en un combate nuevo y no
  en E4, para que E1 a E8 sigan comparándose línea a línea con la primera referencia.
- **Referencia nueva:** la de antes más E9, SHA `3372b413…` (`D:\REBELUM_diagnostico\pruebas\2026-11-09_115925`).
- **Con M1, M2 y C1 enganchados y sin usarlos, la huella es la misma:** 9 de 9 (`…\pruebas\2026-11-09_122651` y la
  batería).

**4. Pruebas** (datos aislados; la partida real y la carpeta real de datos, sin cambios)
- **Nuevas:**
  - `prueba_equipo_combate`: Farol, Gota, Cinta, Moneda, Pluma (con la esquiva forzada al 100 %) y Diente en combates de
    verdad; los atributos no cambian; la tienda de cada lugar; los libros de las artes (para quién, precio, enseñan).
  - `prueba_controles_nuevos`: con teclado, mando y toques, MAGIA, la pestaña del Alba (Q / L1 vuelve), el Compás sobre
    Lya; la fila Accesorio se ve sin desplazar, ↓ desde Amuleto, Intro / A pone y quita el Farol, ← a su ◀, y se toca.
  - `prueba_combate_fotos` (con ventana): las capturas.
- `prueba_artes_combate`, ya con `combate.tscn`, y su escenario D: el aviso «aprende» al subir al 3.
- **Mutaciones** (`…\ejecuciones\20261109_122918_mutacion_equipo`, restauradas): sin la Gota o sin la esquiva,
  `prueba_equipo_combate` FALLIDA. Las pruebas no están vacías.
- **Batería completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_123210\resumen.md`): **49 SUPERADAS, 0 FALLIDAS**,
  28 MANUALES y 0 NO SEGURAS. La partida real, la carpeta real de datos y el proyecto, sin cambios; 28 Godot de otras
  copias, vigilados. Dentro, la huella: 9 de 9 iguales a la referencia.
- **Las pedidas por el coordinador,** en esa batería: `prueba_menu_magia`, `prueba_equilibrio`, `prueba_ia`, `prueba_mando`,
  `prueba_teclado`, `prueba_foco`, `prueba_grupos_combate` y `prueba_incorporacion` (242 s), SUPERADAS.
- **`prueba_huir` arreglada** (`075946e`): sin ventana, su clic caía fuera y salía SUPERADA sin huir (en la batería, el
  combate seguía en «menu»). Ahora huye y lo comprueba (`…\pruebas\2026-11-09_124326`).

**5. Capturas con ventana** (`D:\REBELUM_diagnostico\combate\2026-11-09\capturas\`, 15, 1280 × 720):
- 01 y 01b, la pestaña I y la III de Kael con el sol del Alba detrás; 02, la pestaña del Alba;
- 03 y 04, el Compás (elegir a Lya y «¡Antes!»);
- 05, la pestaña de la Lumbre; 06 y 07, Segundo Aliento y su hoja junto a los nombres;
- 08 y 09, la Lumbre de Retorno (Kael en el suelo y de pie);
- 10, el menú Grupo con «Accesorio: Farol de peregrino» y su efecto; 11, Habilidades; 12, Objetos;
- 13, la tienda con los libros; 14, el Equipo de Oakhaven con el Farol el primero.
- **Antes del ajuste** (`…\capturas_antes_del_ajuste\`): «Compás del Alba» sobre «I · 6 PM», y lo mismo con «Cólera del
  Cielo» y «32 PM», que **ya pasaba antes de las artes** (01b).

**6. Hallazgos**
- **Nombres largos sobre el coste** en los submenús (también con Cólera del Cielo, de antes). Arreglado en
  `menu_combate.gd`: se juntan las letras y, si hace falta, baja el tamaño (no menos de 26). Los que caben no cambian.
- **Menú Grupo:** la octava ranura no cabía. Panel de 640, 3 px entre filas y «Arma: solo espadas.» junto al título.
- **Sin ventana, la ventana raíz mide 100 × 100** (comprobado con una sonda). Los toques y clics simulados tienen que
  pasar por `root.get_final_transform()`; si no, no tocan nada.
  - `prueba_huir` no tocaba HUIR (arreglada). Pendiente de verificar: `prueba_menu_nuevo` y `prueba_mirador` también
    hacen clics en coordenadas del juego.
- **Sin ventana**, al pasar el ratón simulado sobre una fila, `DisplayServer.mouse_get_button_state()` escribe un
  `ERROR` (no implementado en el modo sin ventana). No rompe nada ni cuenta como fallo.
- **Con teclado y mando, ↑ ↓ se saltan las filas apagadas:** el motivo («Nadie ha caído.») solo se lee tocándolas. Pasa
  igual con las magias de siempre.
- **`conseguir(id)` no mira `HECHOS`:** el código del mundo solo debe dar lo disponible (`disponible(id)`).

**7. Límites**
- Nada medido en el Redmi: no se pedía; los menús nuevos dibujan unos pocos iconos por código.
- **Los sonidos nuevos no existen todavía:** no se ha oído nada.
- **Los combates con guion** no prueban la estrategia de un jugador ni el equilibrio de las artes.
- **La Pluma** se probó con la esquiva forzada al 100 %; el 12 %, solo en `prueba_equipo`.
- **Diente, Gota, Cinta y Pluma** no se pueden conseguir todavía en el juego.

**8. Pendiente y peticiones**
- **Narrativa (`diario.gd`, línea 119, pestaña Combate):** `for f in FICHAS:` → `for f in FICHAS +
  load("res://artes.gd").fichas_activas():`. Hoy añade «Ritmo» y «Aliento».
- **Sonido:** `arte_alba`, `arte_ocaso`, `arte_lumbre`, `renacer`, `aliento` y `esquiva` (los demás, con M3 y M4).
  `combate.gd` ya los pide por esos nombres en cuanto estén en `Sonido.EFECTOS`.
- **Mundo (T-089, T-090):** cofres y secretos con `load("res://equipo_extra.gd").conseguir(id)` (Diente, Gota, Cinta y
  Pluma), comprobando antes `disponible(id)`.
- **Siguiente, en orden:**
  - **C2:** las armas especiales. Necesita `tinte` y `color_brillo` en `material_arma.gd` (gráficos), `arma_de` y
    `grupo.gd`, y la decisión del usuario sobre las Fauces de Gorthor.
  - **M3:** Escarcha y la coraza (`_quitar_pv`; el golpe devastador pasa a `_quitar_pv`).
  - **M4:** los III, Brasa y tomos.
  - **E1 a E3:** los enemigos nuevos, cuando el usuario decida las debilidades.

## 2026-11-09, 17:40 · T-099, y la parte de T-100 y T-101 que va en el HUD: PM por héroe, motivos, Érebo y señas

**Encargo** (coordinador, 09/11): el HUD de combate. Interrumpido por un límite de uso y reanudado; al reanudar
confirmé mi trabajo y después integré `integracion-experimental` (`eb8bd94`: arte de Oakhaven, Zarzalín, sonido t3,
licencias) con `merge --no-ff`.
- **Base:** `area-combate` @ `808a836`, importada con datos aislados
  (`D:\REBELUM_diagnostico\importaciones\combate_20261109_130548`; tras el merge, `…\combate_20261109_172316`).
- **Referencia del usuario:** la Prueba v136 (`555fc29`), con los PM solo en la cabecera del héroe activo. El HUD de
  `808a836` es ese mismo: de ahí salen las capturas «antes».
- **Sin tocar:** `sonido.gd`, `audio/**`, `enemigos/**`, `.dtl`, `zonas3d/**`, `mapa*`, `ciudad_oakhaven.*`,
  `ciudades/**`, `progreso.gd`, `diario.gd`, `fondo_combate.gd` y `equipo_extra.gd`.
- **Sin confirmar en la copia:** `aethelgard/pruebas/prueba_orden_pv03.gd.uid` (lo creó la importación; es de
  narrativa).

**1. Commits** (en `area-combate`, sin publicar)
- `1e7806e` · código: `menu_combate.gd`, `combate.gd`, `artes.gd`, `estilo.gd` y `vfx/sena_arte.gd` (nuevo).
- `7dbd3af` · pruebas: `prueba_hud_combate.gd` y `prueba_hud_fotos.gd` (nuevas), `prueba_artes.gd`,
  `prueba_artes_combate.gd` y `lista_pruebas.txt`.
- `21eb3ba` · merge de `integracion-experimental`. Un conflicto en `lista_pruebas.txt`: se quedan las dos líneas del
  HUD y las de Oakhaven y Zarzalín; quité tres líneas antiguas repetidas (`prueba_artes`, `prueba_equipo` y
  `prueba_artes_combate`, que ya estaban más arriba con su texto al día).
- `a4e2347` · los `.uid` de mis tres archivos nuevos. Y el de este informe.

**2. Qué se ve ya** (observado en el código y comprobado ejecutando, aislado, 09/11)
- **PM por héroe (T-099):** el bloque del grupo (abajo a la derecha) va en columnas con su etiqueta encima:
  **PV · PM · ATB**. Cada héroe presente, Garon incluido: nombre, estados, PV, la cifra `actual/máximo` de PM con su
  **barra azul** debajo (`#4D8EF0`, distinto del celeste de Kael, que es el de su ATB llena) y la barra ATB.
  - Se ve todo el combate: con el menú cerrado y con el turno de un enemigo.
  - La cifra cambia al momento; la barra baja de golpe dejando un rastro claro que se recoge en medio segundo, o sube
    en 0,3 s (Éter). Cambia también si cambia el máximo.
  - 0 PM: la cifra se apaga a medias y la barra queda vacía. Caído: PV, PM y sus barras en gris (también su ATB).
  - Colores: PV crema (naranja por debajo del 30 %), PM azul, ATB crema y del color del héroe al llenarse, Armonía
    dorada abajo a la izquierda. Los colores nuevos, también en `estilo.gd` (`PM` y `PM_CLARO`).
  - La cabecera «PM 34/34» del héroe activo se queda como estaba (junto a los costes de los submenús).
- **Motivos de lo apagado (T-100):**
  - **Órdenes:** a la derecha de la fila, siempre a la vista: «Necesitas 6 PM» (MAGIA, ESGRIMA, EMBUIR: lo más
    barato), «Armonía al 45 %», «Lya ha caído» o «Nadie puede invocar» (INVOCACIÓN), «No quedan objetos», «No se puede
    huir».
  - **Submenús:** la explicación de la fila elegida dice el motivo: «Necesitas 8 PM: tienes 0.» (magias, Esgrima,
    Embuir y artes; el coste sale en naranja) y «No te queda ninguno.» (objetos).
  - **Compás del Alba:** «Kael va solo: no hay otro aliado.», «No queda otro aliado en pie.», «Lya ya espera su turno.»
    o «Lya y Garon ya esperan su turno.».
  - **Con el mando y el teclado, ↑ ↓ ya no se saltan las filas apagadas:** se eligen (guion gris en las órdenes, letra
    gruesa gris en los submenús) y A / Intro solo suena a error. Con el dedo, tocarla la elige y enseña el motivo. Si
    todas están apagadas, sale elegida la primera, con su motivo.
- **Érebo en el HUD (T-101):** junto a «ARMONÍA», «45 %», **«INVOCACIÓN LISTA»** (late en dorado con la barra) o
  «LYA HA CAÍDO» (naranja). Sin Lya en el grupo (Kael solo) no se la nombra: solo el porcentaje, y la orden dice
  «Nadie puede invocar». Las reglas no cambian: `_estado_invocacion()` = Armonía llena y Lya en pie, lo mismo que antes
  decía `_mostrar_menu`. **La cinemática no se ha tocado.**
- **La seña de cada arte (T-100):** siluetas dibujadas con líneas y polígonos (`vfx/sena_arte.gd`), sin partículas ni
  luces: se leen igual en el perfil bajo. El sonido se pide una vez, en el fotograma en que el arte se aplica
  (`arte_alba`, `arte_ocaso`, `renacer`, `arte_lumbre` y `aliento`; tras el merge ya están en el catálogo de sonido).
  - **Compás del Alba:** Kael se vuelve hacia el aliado y conjura con su clip de siempre (`mage_soell_cast_7`); un anillo
    con cuatro marcas, como la esfera de un reloj, gira sobre el aliado y marca el ritmo (cada tiempo enciende una
    marca), y al cerrarse sube un destello.
  - **Peso del Ocaso:** el mismo anillo, violeta, gira al revés y baja aplastando a cada enemigo; sus marcas se apagan.
  - **Lumbre de Retorno:** Lya se vuelve hacia el caído; una brasa vuela de ella hasta él (0,45 s) y, al llegar,
    vuelve: columna de luz cálida, la llama del farol sobre su cabeza, «¡Kael vuelve!» y su fila del HUD se ilumina.
  - **Segundo Aliento:** una hoja por turno sube en espiral alrededor de cada aliado y sale «Aliento: 3 turnos» una vez;
    junto a la hoja del HUD, los turnos que le quedan (3, 2, 1). Al empezar cada turno sube una hoja; al acabarse,
    «Aliento se acaba».
  - La onda de suelo de antes se quita en el Alba, la Lumbre y el Aliento (la sustituye la silueta); las partículas de
    siempre se quedan. Nada del perfil alto baja.

**3. La huella:** igual a la referencia (`prueba_combate_huella` SUPERADA, dos pasadas, en la batería de abajo). El HUD
no tira del generador global ni cambia tiempos, y las artes no salen en la huella: no hace falta referencia nueva.

**4. Pruebas** (datos aislados; la partida real, la carpeta real de datos y el proyecto, sin cambios)
- **Nueva `prueba_hud_combate`** (automática): grupos de 1, 2 y 3 (filas, etiquetas, nada recoge toques; el bloque no
  pisa órdenes, explicaciones, vidas de enemigos ni zonas de objetivo); PM con Fuego, Juicio, Embuir, Éter, el máximo,
  0 PM y Lya caída, a la vista con el turno de un enemigo y el menú cerrado; motivos (MAGIA, ESGRIMA, EMBUIR, OBJETO,
  HUIR contra un jefe, magias, Esgrima, Embuir, objetos y el Compás) con el mando y con el dedo; Érebo (sin Lya, 45 %,
  lista, Lya caída) y sus reglas; señas del Compás (y el giro de Kael), Ocaso, Lumbre y Aliento, con su sonido una vez
  y a tiempo (±1 fotograma).
- **Mutaciones** (restauradas desde el archivo confirmado): sin actualizar la cifra de PM y sin el motivo de
  INVOCACIÓN, la prueba sale FALLIDA con 41 fallos (`D:\REBELUM_diagnostico\pruebas\2026-11-09_173750`).
- **Nueva `prueba_hud_fotos`** (con ventana): 22 capturas del mismo guion con semilla fija; vale para antes y después.
- **Batería completa tras el merge** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_172357\resumen.md`): **53 SUPERADAS,
  2 FALLIDAS, 32 MANUALES y 0 NO SEGURAS**. Entre las SUPERADAS: `prueba_combate_huella`, `prueba_hud_combate`,
  `prueba_artes`, `prueba_artes_combate`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_equilibrio`,
  `prueba_ia`, `prueba_menu_magia`, `prueba_menu_nuevo`, `prueba_huir`, `prueba_garon`, `prueba_centinela`,
  `prueba_controles_nuevos` y `prueba_equipo_combate`.
- **Las dos FALLIDAS no son de combate:** `prueba_mando` y `prueba_teclado`, paso 4 «Intro / A junto a Tilo no abre el
  diálogo» (Pastos Verdes, antes de cualquier combate). Mi rama solo difiere de `eb8bd94` en mis 13 archivos de
  combate, y la pasada `2026-11-09_172149` (otra copia, 17:21) falla igual; una de las 17:33 (`…_173333`) ya pasa.
  Viene de la integración (`c3f5692`: Tilo empieza PV-03). *Pendiente de verificar* en `integracion-experimental`.

**5. Evidencias** (`D:\REBELUM_diagnostico\combate\2026-11-09\hud\`)
- `antes\` y `despues\`: 22 capturas cada una, mismo combate y mismo momento (1280 × 720); `antes_movil\` y
  `despues_movil\`, lo mismo con la calidad del móvil (40 % de partículas, sin luces 2D).
- `comparar\` y `comparar_movil\`: cada par lado a lado, con el HUD del grupo y la Armonía ampliados debajo
  (`comparar.ps1` las rehace). Las más útiles: `01_tres_menu_kael`, `06_tres_turno_enemigo` (menú cerrado),
  `09_garon_tras_juicio`, `10_lya_erebo_listo`, `11_kael_0pm_lya_caida`, `12_mando_sobre_magia`, `13_kael_0pm_magia`,
  `15_mando_sobre_compas`, `05_tres_compas_anillo`, `16_peso_del_ocaso`, `18_lumbre_quien_vuelve`,
  `20_aliento_turnos`, `21_solo_menu` y `22_solo_compas`.
- Incidente: la pasada de capturas de las 17:33 (`…_173356`) se cortó tras la primera captura sin ningún error; la
  repetí (`…_173556`, 22 capturas).

**6. Límites**
- **Pendiente en Redmi:** si el HUD se lee de un vistazo (letras de 17 a 32 px; las etiquetas, 19 px ≈ 11 dp), el
  coste del bloque nuevo y de las señas, y si las señas se leen en su pantalla. No se usa el teléfono.
- **Sonidos:** se piden por nombre y a tiempo (comprobado con la señal); **no se han oído**.
- **Gesto de Lya:** su FBX no trae clip de conjuro; usa el gesto por código «conjuro», vuelta hacia el caído. Un gesto
  propio (ofrecer el farol, el soplo del Aliento) lo haría animaciones.
- **Cambio de manejo:** ↑ ↓ pasan ahora por las filas apagadas (antes se las saltaban): con INVOCACIÓN apagada, llegar a
  OBJETO cuesta una pulsación más. Las pruebas de mando y teclado lo aguantan.
- Los combates con guion no prueban la estrategia de un jugador.

**7. Siguiente paso y peticiones**
- **Animaciones (opcional):** gestos de Lya para la Lumbre de Retorno y el Segundo Aliento.
- **Narrativa / coordinador:** `prueba_mando` y `prueba_teclado` (paso 4, Tilo) en la integración.
- **Siguiente encargo:** Zarzalín en el combate.

## 2026-11-09, 18:00 · T-097: Zarzalín enganchado al combate

**Encargo** (coordinador, 09/11, el siguiente al HUD, en la misma rama): enganchar la escena de animaciones
(`enemigos/zarzalin/zarzalin_3d.gd`, de `eb8bd94`) al combate. **Sin tocar** `enemigos/**`, `sonido.gd` ni `zonas3d/**`.

**1. Commits:** `8be73f8` (`combate.gd`) y `f77153f` (`prueba_zarzalin_combate.gd`, su `.uid` y `lista_pruebas.txt`).

**2. Qué hace ya** (observado en el código y comprobado ejecutando, aislado, 09/11)
- **Modelo:** `MODELOS["zarzalin"]` con el encuadre ×1,25 que propuso animaciones (`vp` 1175 × 525, 1,5 m de vista
  mirando a 0,48 m, `barra_y` 40) y el centro del cuerpo a 0,5 m (clave nueva `centro_3d`; los demás siguen a 0,85).
  Respaldo 2D, el Slime, si falta el GLB.
- **Ficha:** «Zarzalín», 80 PV, 11 de ataque, velocidad 14, 20 de experiencia y 12 monedas. Personalidad nueva
  «embiste» (`_turno_zarzalin`, constantes en `ZARZALIN`):
  - **aviso** (40 % si no está cargando ni recuperándose): baja el hocico y da dos golpes de pezuña (`avisar()`); sale
    «⚠ ¡Embestida!», el cartel dice a quién va y su vida lleva «⚠ Cargando». Ese turno no hace daño;
  - **embestida** en su turno siguiente, a quien avisó (×1,8; Defender la deja en la mitad, como cualquier golpe);
  - **recupera el aliento** el turno después (no ataca): nunca dos ataques fuertes seguidos;
  - si no, **colmillo lateral** (golpe corto, ×1).
- **Ataque** (`_anim_zarzalin`): galopa (`correr()`), se planta donde sus colmillos llegan al héroe en el impacto
  (centro − 30 − 0,632 · px_m − alcance · px_m, a la altura de sus pies), `await atacar(ataque, al_golpear)` resuelve
  el golpe **una sola vez** en el ancla del clip (daño, sonido del golpe y reacción a la vez), y vuelve galopando. El
  rig no se mueve durante el clip (el avance lo lleva el clip). Tras el aviso, la embestida entra desde la carga.
- **Entrada** de un salto al empezar el combate (con un fundido de 0,15 s, porque el clip empieza 0,85 m por detrás);
  **derrota** con su clip (`morir()`), antes del desvanecido de siempre; **huida** dándose la vuelta y galopando.
- **Encuentros:** grupo 10 (Zarzalín solo), en los encuentros al azar de 1 y 2 héroes (`AL_AZAR_POR_TAMANO`), que son
  los de Pastos Verdes en la versión experimental. Se tira el dado igual (un `randi()`): la huella no cambia.
- La invocación de Érebo funciona con él sin cambios (su doble es el mismo modelo, a 0,92 m).

**3. Pruebas** (datos aislados; la partida real y la carpeta real de datos, sin cambios)
- **Nueva `prueba_zarzalin_combate`** (automática): Kael solo, nivel 1, solo con ataques: entra de un salto; el aviso
  (una señal `aviso`, «⚠ Cargando», sin daño), la embestida (un impacto y un cambio de PV) y la recuperación (sin
  golpe); el colmillo (un impacto, un cambio de PV); defendiendo, la embestida quita la mitad o menos; Kael gana y
  Zarzalín cae con su derrota. Y huir con Kael y Lya (no da experiencia). SUPERADA
  (`D:\REBELUM_diagnostico\pruebas\2026-11-09_174411`).
- **`prueba_grupos_combate`** juega ya el grupo 10 en Pastos Verdes 3D, con vuelta a la región y guardado: Kael solo,
  victoria en 27 s; Kael y Lya, en 31 s.
- **Batería completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_174617\resumen.md`): **54 SUPERADAS, 2 FALLIDAS,
  32 MANUALES y 0 NO SEGURAS**. La huella, SUPERADA (igual a la referencia). Las dos FALLIDAS son las mismas de antes
  (`prueba_mando` y `prueba_teclado`, paso 4 con Tilo, de la integración).
- **Capturas** con ventana (`D:\REBELUM_diagnostico\combate\2026-11-09\zarzalin\`): `01_entrada`,
  `02_colmillo_lateral` (el impacto en Kael), `03_aviso` («⚠ ¡Embestida!» y «Cargando»), `04_embestida_espinosa` (el
  impacto, con Kael en guardia) y `05_derrota`; y `hoja_zarzalin_combate.png`.

**4. Límites**
- **Pendiente en Redmi:** el coste de su ventana 3D (×1,25: unos 347.000 píxeles por fotograma a 0,75, según
  animaciones) y sus texturas 2K comprimidas. No se usa el teléfono.
- **Equilibrio:** 80 PV y 11 de ataque son una primera propuesta; los combates con guion no prueban la estrategia de
  un jugador. Kael nivel 1 gana con ataques en los casos probados.
- **Sonido:** sin voz ni golpes propios (el catálogo no tiene la familia «zarzalin»); suena el golpe de siempre. Las
  señales `pezuna` e `impacto` del modelo son sus anclas, para sonido.
- La embestida aterriza un poco más allá del héroe (lo avisó animaciones): se ve como una embestida, pero solapa.
- La escala ×1,25 es la propuesta de animaciones; la decisión es del usuario o del coordinador.

**5. Peticiones**
- **Sonido (`sonido.gd`):** la voz de Zarzalín (`clave` «zarzalin»: ataque, herido, caída) y la tierra de la pezuña
  con la señal `pezuna`.
- **Coordinador:** decidir la escala y el botín propuesto en la ficha (Corteza espinosa), que no he añadido.

## 2026-11-09, 18:40 · T-100: M3 (Escarcha de Kael), la Guardia de Garon, los sonidos de Zarzalín y su botín

**Encargo** (coordinador, 09/11, tras integrar `a9d316d`): M3 con la misma calidad que el Alba y la Lumbre; la
técnica de guardia de Garon ante un ataque anunciado; el botín «Corteza espinosa» como objeto de venta; y, en la misma
tanda, los sonidos de Zarzalín de la tanda 4 de sonido (integrada en `a330d77`). Zarzalín se queda a ×1,25 (decisión
del coordinador).
- **Merges** (`--no-ff`): `bada535` (`a9d316d`; un `.uid` suelto de narrativa, idéntico al que traía, apartado al
  scratchpad para poder unir) y `a673dfa` (`a330d77`, limpio).
- **Sin tocar:** `sonido.gd`, `audio/**`, `enemigos/**`, `diario.gd`, `.dtl`, `zonas3d/**`, `progreso.gd`. **Tocado
  fuera de mi lista habitual:** `tienda.gd` (vender el botín; ya lo había tocado en la fase 2 por los libros).
- **Sin confirmar en la copia:** `dialogos/comentarios.gd.uid` y `pruebas/prueba_comentarios.gd.uid` (de narrativa, los
  crea la importación).

**1. Commits** (en `area-combate`, sin publicar)
- `0d28909` · botín: `equipo_extra.gd` (BOTIN, MATERIALES, `botin_de`) y `tienda.gd` (fila «Vender», `_vender`).
- `de60656` · `combate.gd`, `artes.gd`, `menu_combate.gd` y `vfx/sena_arte.gd`: M3, la Guardia y los sonidos de Zarzalín.
- `d6be65e` · pruebas: `prueba_escarcha_guardia.gd` (nueva) y `prueba_zarzalin_combate.gd` (sonidos); ajustadas
  `prueba_artes`, `prueba_artes_combate`, `prueba_controles_nuevos`, `prueba_equipo_combate` y `prueba_hud_combate` (la
  pestaña, el libro y la Guardia en ESGRIMA).
- `aad8435` y el de este informe: `.uid`; `ffaf760`: `prueba_escarcha_fotos.gd`.

**2. Qué hace ya** (observado en el código y comprobado ejecutando, aislado, 09/11)
- **M3, Escarcha de Kael** (`ACTIVOS["Escarcha"] = 2`): Coraza de Escarcha (nivel 6, 7 PM, a un aliado o a sí mismo:
  sirve con Kael solo) y Muralla de Escarcha (nivel 12, 18 PM, a todos). Se aprende al subir («Kael aprende Coraza de
  Escarcha»), el libro de la Muralla se vende (400) y la ficha «Barrera» sale en el Diario, sin tocar `diario.gd` ni
  `tienda.gd` para eso (salen de `ACTIVOS`). Kael tiene ya dos pestañas de familia: Alba y Escarcha.
  - **La coraza absorbe antes que los PV** (`_quitar_pv` devuelve lo que llega a los PV): «❄ 12» en hielo, sonido
    `barrera_absorbe`; si se rompe, salta en esquirlas, «¡Coraza rota!» y `barrera_rota`. Un sonido por golpe, en el
    instante en que se resuelve. Sin coraza, `_quitar_pv` hace exactamente lo de siempre.
  - **HUD:** junto al cristal, lo que aguanta aún («55»).
  - **Seña** (dibujada, sin partículas ni luces): un cristal hexagonal que crece del suelo alrededor del aliado, con
    facetas y un destello que lo recorre; al absorber, el cristal aparece un instante; al romperse, seis esquirlas
    vuelan y caen. Gesto: el conjuro de Kael (`mage_soell_cast_7`), vuelto hacia el aliado si no es él mismo.
  - **Motivo:** sin PM, «Necesitas 7 PM: tienes 0.»; el coste en naranja.
  - El III (Invierno Guardián, congela a quien rompe la coraza) sigue fuera (M4).
- **La Guardia de Garon** (en ESGRIMA, 4 PM): cubre a un aliado hasta su turno siguiente. Garon queda en guardia (como
  Defender: los golpes le hacen la mitad) y **los golpes que van al cubierto los recibe él**:
  - la embestida anunciada de Zarzalín («va a embestir a Kael» → Garon cubre → «¡Zarzalín embiste a Garon!», a la
    mitad, y Kael no pierde nada); también el colmillo, los ataques normales y el mordisco de Gorthor;
  - **varios impactos:** en el golpe devastador de un jefe (a todos), el golpe de Kael también va a Garon;
  - se acaba al empezar el turno de Garon, si cae Garon o si cae el cubierto (deja de ser objetivo válido);
  - sin nadie a quien cubrir: «No hay a quién cubrir.»; ESGRIMA dice ahora «Necesitas 4 PM» (lo más barato);
  - gesto: Garon se vuelve hacia el aliado y avanza un paso en guardia; sonido `defensa`, una vez; seña: un escudo
    sobre el aliado unido a Garon por una línea; HUD: un escudo junto al nombre del cubierto; «¡Cubre a Kael!» sobre
    Garon cuando para un golpe.
- **Sonidos de Zarzalín** (tanda 4, «Cómo pedirlos»): `zarzalin_aviso_embestida` (señal `aviso`), `zarzalin_pezuna`
  (cada `pezuna`), `zarzalin_embestida` / `zarzalin_colmillo` (señal `impacto`, junto al `Sonido.golpe` de siempre),
  `zarzalin_aviso_colmillo` (al llamar a `atacar("colmillo_lateral")`), `zarzalin_entrada` (al empezar) y
  `zarzalin_derrumbe` (al caer, una vez). Su voz de herido y caída la da `Sonido.recibe` por su clave «zarzalin». Ya no
  pide la voz de «ataque» (las bestias no la tienen).
- **Botín:** al ganar, cada Zarzalín vencido (no huido) deja una «Corteza espinosa» (sale en el cartel de recompensas);
  la tienda la compra por 18 monedas (pestaña Objetos, fila «Vender»). Sin recetas.

**3. La huella:** igual a la referencia (`prueba_combate_huella` SUPERADA en la batería). `_quitar_pv` y `_cubre` no
cambian nada sin coraza ni guardia, y no tiran del generador global. No hace falta otra referencia.

**4. Pruebas** (datos aislados; la partida real y la carpeta real de datos, sin cambios)
- **Nueva `prueba_escarcha_guardia`**: aprendizaje (6 y 12; el III no), libro, ficha; pestaña; motivo sin PM; la Coraza
  sobre Kael solo (30 %, 7 PM, `arte_escarcha` una vez en el fotograma de aplicarse, su seña sin nodos, la cifra del
  HUD); absorber entero (0 a los PV, `barrera_absorbe` una vez) y romper (solo el resto, `barrera_rota` una vez, las
  esquirlas, sin icono); la Muralla a los tres (un sonido, tres señas); un golpe de verdad de Grimfang; la Guardia ante
  la embestida anunciada de Zarzalín (Kael no pierde nada; Garon, la mitad o menos); su fin en el turno de Garon; con
  Garon caído y con Kael caído; sin nadie; y varios impactos (golpe devastador del Guardián de piedra, jefe).
- **`prueba_zarzalin_combate`**, ampliada: cada sonido de Zarzalín se pide una vez por su señal y en su mismo fotograma;
  la entrada y el derrumbe, una vez; el aviso del colmillo, antes de su impacto.
- **Batería completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-09_182011\resumen.md`): **60 SUPERADAS, 0 FALLIDAS, 32
  MANUALES y 0 NO SEGURAS**. «Proyecto: CAMBIADO» es mío: añadí `prueba_escarcha_fotos` y su línea de la lista durante la
  pasada.
- **Capturas antes y después** (`D:\REBELUM_diagnostico\combate\2026-11-09\escarcha\`): `antes\` (proyecto de `bada535`
  exportado con `git archive` en `antes_proyecto_bada535\`, con datos aislados por variables de entorno, como el
  ejecutor), `despues\` (`…\pruebas\2026-11-09_182913`), `comparar\` y `hoja_antes_despues.png`: la pestaña, la Coraza
  (antes, el aro genérico; después, el cristal), el golpe absorbido (antes le quitaba 20 PV; después, «❄ 20» y nada),
  la coraza rota (esquirlas y el resto), la Guardia sobre Kael y la embestida (antes, a Kael; después, a Garon).

**5. Límites**
- **Pendiente en Redmi:** la lectura de las señas nuevas (son líneas y polígonos, sin partículas) y el coste de todo.
- **Sonidos:** se piden a tiempo (comprobado con la señal) y ya existen en el catálogo; **no se han oído**. La Guardia
  usa `defensa`: un sonido propio («guardia») lo haría sonido.
- **Gorthor y la coraza:** su mordisco se cura con el 60 % del mordisco aunque la coraza absorba parte (como hoy con la
  defensa). Un golpe que la coraza absorbe entero aún tiñe al héroe de rojo un instante.
- **Equilibrio:** la Guardia (4 PM) y la Coraza (30 % de los PV) son las cifras del diseño; con guion no se prueba la
  estrategia de un jugador.
- La captura «antes» se hizo fuera del ejecutor (en el proyecto exportado), con la misma redirección de datos.

**6. Peticiones**
- **Sonido:** un efecto propio para la Guardia (`guardia`: escudo que se planta) y, si se quiere, uno al cubrir.
- **Animaciones (opcional):** un gesto de Garon «cubrir» (escudo al frente, un paso hacia el aliado).
- **Siguiente, si se aprueba:** M4 (los III: Hora Dorada, Invierno Guardián, Última Brasa y los tomos) y C2.
