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

## 2026-11-09, 19:20 · Arreglos de la coraza, M4 (los III y los tomos), C2 (armas especiales) y las voces de sonido t5

**Encargo** (coordinador, 09/11; el usuario delegó las decisiones, reversibles): arreglar los dos detalles de la
tanda anterior; después M4 y C2 con el mismo acabado (motivos, fichas, pruebas); y, al integrar `6adc4d9`, las voces de
sonido t5 y el sonido propio de la Guardia. Huella igual o regenerada con justificación en un commit aparte.
- **Merges** (`--no-ff`): `d3e5116` (`6adc4d9`): conflicto solo en `lista_pruebas.txt` (se quedan las dos partes); aparté
  al scratchpad dos `.uid` sueltos de narrativa que la importación había creado con otro identificador (los buenos son
  los de la integración). `e58c546` (`dca4c1c`, la de la APK de prueba v293), limpio: no toca mis archivos de combate;
  aparté antes un `.uid` suelto, idéntico al que traía. Importada después con datos aislados
  (`D:\REBELUM_diagnostico\importaciones\combate_20261109_224422`), sin `.uid` nuevos.
- **Interrupción:** un límite de uso cortó la batería de las 19:00 (23 pruebas, sin resumen); la repetí entera tras el
  último merge.

**1. Commits** (en `area-combate`, sin publicar)
- `8e3174c` · arreglos: `combate.gd` (`_cura_devorar` y el golpe parado entero) y su prueba.
- `4fc38f6` · M4 y C2: `artes.gd`, `equipo_extra.gd`, `combate.gd` y `vfx/sena_arte.gd`.
- `f13d556` · pruebas: `prueba_m4_c2.gd` (nueva) y la de Escarcha con el III.
- `ebae3ed` · **la huella, referencia nueva, aparte y justificada** (ver § 3).
- `55e8ee2`, `f7cc79e` · `.uid`; `f4e7617` · `prueba_m4_fotos.gd`.
- `028f74c` · voces de sonido t5 y la Guardia con «guardia»; `ce84503` · `prueba_voces_combate.gd` (nueva).
- Y el de este informe.

**2. Qué hace ya** (observado en el código y comprobado ejecutando, aislado, 09/11)
- **Arreglos:**
  - **El mordisco de Gorthor** (Devorar) se cura el 60 % de lo que de verdad mordió: lo que paró la coraza no cuenta
    (el impacto apunta «absorbido»; `_cura_devorar`). Sin coraza, como siempre.
  - **Un golpe que la coraza para entero** no tiñe de rojo (tinte frío), ni hace la reacción de dolor, ni sale «¡0!».
- **M4, los niveles III** (`ACTIVOS` a 3; se aprenden a los niveles 16, 20 y 18, el aviso «aprende» al subir):
  - **Hora Dorada** (Kael, 30 PM): llena la barra de los demás aliados; entran una vez en la cola y tienen un turno
    cada uno (sin turnos dobles). Anillo dorado sobre cada uno y un destello dorado. Con Kael solo: «Kael va solo: no
    hay otro aliado.».
  - **Invierno Guardián** (Kael, 32 PM): corazas del 30 % a todos, en un cristal más azul; **quien la rompe queda
    Congelado** (el enemigo que actúa, `atacante_actual`).
  - **Última Brasa** (Lya, 34 PM): una llama baja sobre cada aliado y queda en su icono del HUD; **quien cae se levanta
    una vez** con el 30 % (columna de luz, «¡Kael se levanta!», sonido «brasa» y su fila iluminada). El segundo golpe
    mortal ya lo tumba.
  - **Tomos:** `Artes.dar_tomo(id)` para el código del mundo: enseña el III a quien usa la familia, una vez, con su aviso
    («Lya aprende Última Brasa.»). **Falta ponerlos en el mundo** (petición abajo).
  - **Diario:** fichas nuevas «Hora Dorada», «Invierno» y «Tomos» (y ya salía «Brasa»).
  - **Accesorios** (HECHOS M3 y M4): la Lágrima de ámbar empieza con coraza (15 %) y la Brasa en frasco con Brasa (25 %).
- **C2, armas especiales** (HECHOS C2; se consiguen con `Extra.conseguir(id)`):
  - **Fauces de Gorthor** (Garon): se cura el 15 % del daño físico que hace («+N»).
  - **Guardiana de Ámbar** (Kael): en guardia, devuelve el golpe («Réplica»).
  - **Gemelas de la Muralla** (Garon): reciben el golpe de un aliado con menos del 30 % de vida (`_cubre_gemelas`,
    también sin la Guardia).
  - **Rama del Árbol Milenario** (Lya): al empezar, Aliento de 2 turnos al aliado más herido.
  - **Hoja sin Nombre** (Kael): +1 de ataque por recuerdo visto (Progreso «lore_visto»), en combate.
  - **Báculo del Peregrino:** ya alargaba el Aliento.
  - **Recompensas** (decisión del coordinador): la primera victoria contra Gorthor da las **Fauces** (se le perdone o
    no) y la del nido de la Garganta, la **Lágrima de ámbar**; lo dice el cartel.
- **Voces (sonido t5):** el esfuerzo de Kael al saltar y el de Lya al golpear, el alivio si una Poción cura PV, y el
  gesto de victoria de uno de los que siguen en pie. La Guardia suena «guardia». La Cura (magia protegida, D-048) no
  pide alivio.

**3. La huella:** con C2 cambia, **solo por diseño**, y la regeneré en un commit aparte (`ebae3ed`): en E8 (combate fijo
«garganta_gorthor») sale una línea más, «02229 · Has conseguido Fauces de Gorthor.», tras el reparto. E1 a E9, línea a
línea, iguales a la anterior; dos pasadas iguales en un proceso (SHA-256 `65bb9817…`,
`D:\REBELUM_diagnostico\pruebas\2026-11-09_184233`). Los arreglos, M4, el resto de C2 y las voces no la cambian (las
voces usan el generador propio de `sonido.gd`).

**4. Pruebas** (datos aislados; la partida real y la carpeta real de datos, sin cambios)
- **Nueva `prueba_m4_c2`:** aprendizaje (16, 20, 18), fichas, tomos (una vez); Hora Dorada (motivo con Kael solo; una
  entrada y un turno por aliado; su sonido una vez); Invierno (coraza helada; quien la rompe, Congelado; «barrera_rota»
  una vez); Última Brasa (se levanta una vez con el 30 %; «brasa» una vez; la segunda vez cae); Lágrima y Brasa en
  frasco; Fauces, Guardiana, Gemelas, Rama, Hoja sin Nombre y las Fauces al vencer a Gorthor. Zona «ceniza» (nivel 34),
  para que con héroes de nivel 20 nadie huya solo.
- **Nueva `prueba_voces_combate`:** cada voz se pide una vez (con la señal `voz_pedida`); ni el Éter ni la Cura piden
  alivio.
- **`prueba_escarcha_guardia`:** los dos arreglos y la Guardia con «guardia».
- **Batería completa final**, tras el merge de `dca4c1c` (`D:\REBELUM_diagnostico\pruebas\2026-11-09_224444\resumen.md`):
  **69 SUPERADAS, 0 FALLIDAS, 36 MANUALES y 0 NO SEGURAS**; la partida real, la carpeta real de datos y el proyecto, sin
  cambios (había 205 Godot de otras copias, vigilados). Dentro, SUPERADAS: la huella (con la referencia nueva),
  `prueba_m4_c2`, `prueba_voces_combate`, `prueba_escarcha_guardia`, `prueba_hud_combate`, `prueba_zarzalin_combate`,
  `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_equilibrio`, `prueba_ia`, `prueba_menu_magia`, `prueba_garon`,
  `prueba_huir`, `prueba_centinela`, `prueba_mando` y `prueba_teclado`.
- **Capturas antes y después** (`D:\REBELUM_diagnostico\combate\2026-11-09\m4_c2\`): `antes\` (proyecto de `8e3174c`
  exportado con `git archive`, datos aislados), `despues\`, `comparar\` y `hoja_antes_despues.png`: la pestaña del Alba
  con la Hora Dorada; la Hora Dorada; el Invierno; la coraza helada rota (después, Grimfang «Congelado»); la Última
  Brasa (después, las llamas); Kael cae con Brasa (antes cae; después se levanta con «¡Kael se levanta!»); y las Fauces.

**5. Límites**
- **Pendiente en Redmi:** la lectura de las señas nuevas y su coste. No se usa el teléfono.
- **Los tomos y las armas no están todavía en el mundo** (salvo las Fauces y la Lágrima, que dan Gorthor y el nido): sin
  código del mundo que llame a `dar_tomo` y `conseguir`, un jugador no los encuentra.
- **La Hoja sin Nombre** suma su ataque en combate; el menú Grupo no lo enseña (lo calcula `grupo.gd`, que no es mío).
- **Las armas especiales se ven como su malla de siempre:** `tinte` y `color_brillo` esperan a `material_arma.gd`
  (gráficos).
- La captura «antes» de M4 se hizo fuera del ejecutor; en ella, lanzar dos III seguidos con `_lanzar_arte` (sin pasar
  por el menú) deja los PM de Kael en negativo: es la prueba, no el juego (el menú no lo permite).
- Los sonidos y las voces se piden a tiempo; **no se han oído**. Los combates con guion no prueban la estrategia.

**6. Peticiones**
- **Mundo (narrativa / gráficos, quien lleve las zonas):** colocar los tres tomos con `load("res://artes.gd").dar_tomo(id)`
  (`tomo_alba`, `tomo_escarcha`, `tomo_lumbre`) y las armas y accesorios que faltan con
  `load("res://equipo_extra.gd").conseguir(id)` en los sitios de su campo «donde».
- **Gráficos:** `tinte` y `color_brillo` en `material_arma.gd` (las armas especiales).
- **Grupo (`grupo.gd`, si se quiere ver en el menú):** el ataque de la Hoja sin Nombre.
- **Sonido / animaciones:** ya pedidos por el coordinador (la Guardia y el gesto de cubrir).

## 2026-11-09, 23:45 · Armas especiales a la vista, la Hoja sin Nombre en el menú, los enemigos de siempre con su ataque anunciado y el arreglo de saltar a Érebo

Rama `area-combate`, sobre la integración `45a49e6` (merge `448a977`). Sin Redmi (lo lleva el coordinador), sin push.

**1. Qué se ha hecho (observado en el código y comprobado ejecutando, aislado, 09/11)**
- **Saltar la invocación de Érebo ya no cuelga el combate** (`738a510`). Se reproducía: con la importación limpia y sin
  el arreglo, `prueba_erebo_saltar` (nueva, `f8ed668`) se quedaba en estado «accion» al saltar durante «invocacion» y
  «pulso». La causa: `_teatro_erebo` esperaba un tween que `limpiar()` mata al saltar, y esa espera no volvía nunca.
  Ahora espera la señal `terminada` de la invocación (`lanzar()` y `saltar()` la emiten una vez), y `_resultado_erebo`
  no toca un doble que ya no existe. Probado en cuatro momentos: «invocacion», «penetra», «sostiene» y «pulso».
- **Armas especiales a la vista** (`8cd22e1`): `material_arma.gd` tiene `tinte`, `color_brillo`, `aura` (un filo de luz en
  el borde) y `fuerza_tinte`. Solo color en el shader, sin luces ni partículas (barato en Mali). `de_arma` los aplica
  desde la ficha; las espadas de Garon, que se cargan con su modelo, se tiñen con `tenir()` en `_crear_rig_3d`
  (`inventario.arma_de` ya da también las armas de `equipo_extra`). Sin arma especial, el material es el de siempre.
  Capturas: `D:\REBELUM_diagnostico\combate\2026-11-09\armas\` (seis armas y `hoja_armas.png`).
- **La Hoja sin Nombre en el menú Grupo** (`8cd22e1`): `grupo.estadisticas()` suma su +1 de ataque por recuerdo, así que
  el menú y el combate dan lo mismo; `combate.gd` ya no la suma aparte (no cuenta dos veces).
- **Los enemigos de siempre con su ataque anunciado** (`42c172e`, T-097), como Zarzalín: avisan un turno antes, golpean
  el siguiente y recuperan el aliento el otro.
  - Grimfang (también con el dibujo del Hollín y en los grupos del centinela, que usan a Grimfang): «alza el hacha: ¡va a
    por Kael!» y el Hachazo a ese héroe, ×1,6.
  - Slime: «se encoge» (recibe la mitad hasta su turno, y se aplasta) y rebota contra uno, ×1,3.
  - Gólem de ámbar: «levanta los puños» y el Pisotón a todo el grupo, ×1,0, un impacto por héroe.
  - Guardián y Gorthor (jefes) ya avisaban su golpe devastador: ahora llevan además la señal dibujada; Zarzalín, también.
  - El aviso se lee de cuatro maneras: el cartel, el texto flotante, «⚠ Cargando» sobre su vida y una señal dibujada
    (un triángulo con «!», vectorial, sin nodos hijos ni partículas: igual en el perfil bajo). Se quita al golpear, al
    morir y al huir. Pide su voz de ataque una vez; el golpe usa las animaciones y los sonidos que ya tenían.
  - Defender lo reduce a la mitad y la Guardia de Garon lo cubre. Probabilidad del aviso: 30 % por turno.
  - No cambian las 12 magias, costes, fórmulas de los golpes de siempre ni el ATB: es un ataque nuevo del enemigo.
- **La señal, encima de «⚠ Cargando»** (`f3022a1`): en la primera captura con `-- movil`, el triángulo tapaba la
  etiqueta y los PV. Antes y después en `D:\REBELUM_diagnostico\combate\2026-11-09\avisos\` (`*_antes.png` y
  `*_aviso.png`; `despues\`, la buena), con Grimfang, el Slime y el Gólem con Grimfang.
- **Huella regenerada en su commit** (`07fe3ce`): los patrones tiran `randf` y añaden turnos, así que E1, E2, E3, E5, E6,
  E7 y E9 cambian desde el primer turno de enemigo; E4 y E8 (jefes) salen iguales línea a línea; los resultados no
  cambian. Dos pasadas iguales: `D:\REBELUM_diagnostico\pruebas\2026-11-09_232628` (SHA-256 `725aef4a...`).

**2. Pruebas** (datos aislados; importación aislada tras el merge, que hace falta: sin ella, la caché vieja del goblin
daba fallos falsos en la huella)
- Nuevas: `prueba_erebo_saltar`, `prueba_patrones_enemigos` (aviso sin daño, con señal, «Cargando» y voz; golpe al
  avisado o a todos, un impacto por héroe; recuperación sin daño; defendido, la mitad o menos; Slime encogido en
  guardia; el Guardián pone y quita la señal) y `prueba_armas_especiales` (tinte, brillo y aura en el material del arma
  de cada héroe en combate; las de siempre, sin aura; la Hoja sin Nombre en `grupo.gd`).
- **Batería completa final** sobre `f3022a1` (`D:\REBELUM_diagnostico\pruebas\2026-11-09_233213\resumen.md`):
  **73 SUPERADAS, 1 FALLIDA, 36 MANUALES y 0 NO SEGURAS**; la partida real, la carpeta real de datos y el proyecto, sin
  cambios (185 Godot de otras copias, vigilados). La FALLIDA es `prueba_zona3d` («sigue el botón de banco DIAG»): viene
  de `45a49e6` (botones DIAG y MEDIO de Pastos Verdes 3D), no de combate; el coordinador ya la arregló en `5c6ac76`,
  que esta rama aún no tiene. SUPERADAS, entre otras: la huella (referencia nueva), `prueba_patrones_enemigos`,
  `prueba_armas_especiales`, `prueba_erebo_saltar`, `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_huir`,
  `prueba_garon`, `prueba_equilibrio`, `prueba_ia`, `prueba_menu_magia`, `prueba_menu_nuevo`, `prueba_centinela`,
  `prueba_m4_c2`, `prueba_voces_combate`, `prueba_escarcha_guardia` y `prueba_zarzalin_combate`.

**3. Límites**
- **Pendiente en Redmi:** la lectura de la señal de aviso y de las armas teñidas en el teléfono, y su coste.
- Los sonidos y las voces se piden a tiempo y una vez; **no se han oído**.
- Los combates de las pruebas se juegan con guion: no prueban la estrategia de un jugador. No he medido cuánto más
  difícil es Pastos Verdes con los patrones (la batería de equilibrio sigue pasando).
- El Hollín no tiene ficha propia: es el dibujo 2D de Grimfang, y hereda su patrón.

**4. Peticiones**
- **Animaciones (si se quiere):** un gesto de «carga» propio para Grimfang y el Gólem; hoy el aviso usa el texto, la
  señal y la voz, y el golpe, su animación de ataque de siempre.
- **Sonido (si se quiere):** un sonido corto para el aviso (hoy, la voz de ataque del enemigo).

## 2026-11-15, 02:10 · Estabilidad de las pruebas de combate V12 (auditoría sobre da0e336): orbe y vídeo de Érebo, Gorthor, Velador y Gólem

Rama `claude/v12-pruebas-combate-estabilidad`, desde `claude/rebelum-v12` @ `178c9cd`, en el worktree
`D:\Aethelgard\.claude\worktrees\agent-a5473fc2726e08dbd`. Solo pruebas: **Érebo (original, orbe y vídeo) no se ha
tocado**, ni fórmulas ni equilibrio. Sin push. Commits: `141eeb6` (G1), `38586b3` (G2), `89fb8d6` (F1), `dae1f2e` (F2).

**1. Causas reproducidas (comprobado ejecutando, aislado, 15/11)**
- **G1, Gorthor y Velador al azar.** `seed(semilla)` iba antes de `root.add_child(c)` y `combate._ready` hace
  `randomize()` (sin `-- semilla=N`): A, C, E y Q eran combates al azar. Tres pasadas del A original con la misma
  «semilla 5» dieron tres combates distintos (`D:\REBELUM_diagnostico\pruebas\2026-11-15_012810`, `_012827`, `_012844`:
  Devorar 3 / 1 / 2, acciones distintas). Fallos de batería por esto: Gorthor A el 14/11 (`2026-11-14_215231`) y el Q del
  Velador dos veces (`2026-11-14_031907`, `2026-11-14_144902`). Con el arreglo, tres pasadas del A con la misma traza
  (MD5 `F6-8E-CF-CB`, `2026-11-15_013221`, `_013237`, `_013252`). Barrido de semillas del A con estrategia (1-4, 6-11 y la
  5): gana en las 11; la derrota del 14/11 fue una semilla al azar que no se puede recuperar (randomize).
- **G2, mismo patrón en el Gólem**: su Q falló una vez por esto (`2026-11-14_040607`, «se pierden 70 PV y con el de
  siempre 35»). Arreglado igual.
- **F1, orbe:** `muerte_o_dano` daba `true` en los dos lados con `erebo=exito` pasara lo que pasara.
- **F2, vídeo:** con un VideoStream que no arranca, ni la unidad ni el combate tenían prueba; tampoco fallo, jefe, nueva,
  completa ni sin pausa.

**2. Cambios (solo `aethelgard/pruebas/`)**
- `prueba_gorthor_v12.gd`, `prueba_velador_v12.gd`, `prueba_golem_v12.gd`: semilla después de `add_child` y el ATB
  inicial de los enemigos otra vez con ella (como `prueba_combate_huella.gd`); «SEMILLA» por combate; Gorthor y Velador,
  además, una «TRAZA» por turno (quién, qué, PV) y `semilla_A=N` (o `_C`, `_D`, `_E`, `_Q`); `_cerrar` espera 75
  fotogramas y, solo si aún suena algo suyo, hasta 5 s reales (el audio sin ventana va con el reloj real; antes, 2,5 s
  reales siempre). Velador D: el grupo lo sigue eligiendo `_ready` al azar (a propósito); si en 24 no salen los dos
  tipos, hasta 48 (0,75^48 ≈ 1 en un millón).
- `prueba_erebo_orbe_v12.gd` (y `_nueva`, que la hereda): apagado / encendido / apagado de control con la semilla tras
  `add_child` y otra antes de `_invocar_sobre`; comparación exacta de PV antes y después, daño, cambios de PV del objetivo
  y de los demás, PV y PM de todos, Armonía, ATB de todos (ATB lento, sin tope), estado, fotogramas hasta volver y
  registro. Casos: Grimfang (muerte, 1 cambio) y JEFE `GRUPOS[18]` (Guardián de piedra: 180 → 144, `maxi(1, round(PV ×
  0,2))`, 1 cambio). Nuevas `prueba_erebo_orbe_v12_fallo.gd` y `_nueva_fallo.gd` (`erebo=fallo`: sin orbe, sin daño).
- `prueba_erebo_video.gd`: semilla fija; `reproducir()` a solas con ruta inexistente (false al momento) y con un
  `VideoStream` sin reproductor puesto en la caché con `take_over_path` (false en 2,17 s, música devuelta, sin restos);
  en el combate, el abreviado sustituido así (solo en la prueba): cae al teatro, resultado una vez, `c12_accion` a 0;
  jefe (36 de 180, «roba parte de su vida»); nueva con vídeo (ATB de `ATB_TEATRO["nueva"]`); completa hasta el final;
  `pausa_atb_v12 = false` (el ATB corre todo el rato). Nueva `prueba_erebo_video_fallo.gd` (`erebo=fallo`: apagado y
  abreviada «sale vacía» sin daño con el ATB de fallo, nueva con fallo, jefe con fallo forzado = 20 %).
- `lista_pruebas.txt`: tres líneas nuevas (orbe con fallo, orbe nueva con fallo, vídeo con fallo) y notas al día.

**3. Verificación (aislada; partida real, carpeta real de datos y proyecto sin cambios en todas las pasadas)**
- Tres pasadas seguidas de las afectadas, JUNTAS (orbe ×4, vídeo ×2, Gorthor, Velador, Gólem, `prueba_solo_lya_invoca`
  y `prueba_combate_huella`), 11/11 SUPERADAS cada una: `D:\REBELUM_diagnostico\pruebas\2026-11-15_015055`,
  `2026-11-15_015844` y `2026-11-15_020627` (la 2.ª marca «proyecto: CAMBIADO» porque durante ella escribí este informe,
  `docs/memory/agents/combate.md`; ninguna prueba toca archivos). Huellas MD5 de las líneas TRAZA / SEMILLA / OK (sin el número de fotograma absoluto, que
  cambia con lo que tarda en callar el audio entre combates, y sin el D del Velador, al azar a propósito): **iguales en
  las tres** para las once pruebas. Duraciones (pasada 1): Gorthor 112 s (antes 157), Velador 136 s (antes 264), Gólem
  98 s, orbe 17,6 / 16,3 / 7,2 / 7,6 s, vídeo 14,9 / 7,8 s. Antes, además, un pase completo de Gorthor y Velador
  (`2026-11-15_014405`) y el A de Gorthor ×3 solo; las TRAZA, iguales salvo el fotograma absoluto.
- Contraprueba F1 (copia temporal `prueba_erebo_orbe_v12_contra.gd`, NO confirmada y borrada): quitando 1 PV de más
  solo en el lado encendido al sacar el orbe, la prueba FALLA con 7 fallos (`2026-11-15_014928`: «cambios_objetivo»
  1 / 2; jefe «pv1» 144 / 143, «dano» 36 / 37…). La comparación vieja («muerte_o_dano») habría dado `true` igual.
- Contraprueba G1: el A original con la misma semilla, tres combates distintos; el arreglado, la misma traza tres veces.

**4. Hallazgos que NO se arreglan (Érebo congelado) y siguen como AVISO**
- **El orbe gasta azar global.** Con todo lo demás exacto, la tirada `randi()` siguiente a la invocación cambia con el
  orbe encendido (Grimfang: apagado 1520304005 = control, encendido 8125373; jefe: 3445666316 / 3853673737; con la
  nueva, igual). Las CPUParticles3D del orbe tiran del generador global. Hoy no cambia nada del combate (el resultado ya
  está aplicado y el ATB es el mismo), pero lo siguiente que tire el azar (el siguiente golpe, crítico o decisión
  enemiga) sale distinto con el efecto encendido. Propuesta (para cuando se descongele): `seed`/`use_fixed_seed` propios
  en las partículas del orbe, o guardar y restaurar el estado del generador alrededor de su creación.
- **Un vídeo Theora que no se abre cuelga `reproducir()` hasta el toque.** `is_playing()` da `true` y el largo 0, así que
  ni el corte de 1,5 s ni la salvaguarda (largo + 2 s) actúan: en el combate sería pantalla negra hasta tocar; al tocar
  devuelve `true` (el resultado se aplica sin teatro). Propuesta: considerar que arrancó solo si `stream_position`
  avanza, y salir si a los 1,5 s sigue en 0.
- **ATB de más si el vídeo no arranca.** Con `pausa_atb`, el intento fallido (≈2,17 s: fundidos y la espera de 1,5 s)
  corre el ATB de todos y después el teatro da el suyo entero: 5,63 s de ATB frente a 3,47 s del teatro solo, en el
  mismo combate (≈2,2 s de más para héroes y enemigos por igual).
- **Sin ventana, el vídeo no acaba solo.** La posición sigue más allá del final (8,77 s en el de 6,8; 21,97 en el de
  20,0) e `is_playing()` no se apaga: «completa hasta el final» y «abreviada» terminan por la salvaguarda (largo + 2 s).
  La prueba lo admite (dura < largo + 5 s); el final natural en el teléfono, pendiente de verificar.

**5. Siguen frágiles o sin arreglar (G2: el mismo patrón `seed()` antes de `add_child`, sin `semilla=` en la lista)**
- Con apartado Q estadístico (riesgo como el Gólem y el Velador; sin fallos al azar vistos en el historial):
  `prueba_centinela_v12` (191/198) y `prueba_peon_v12` (`_combate`, seed antes de add_child).
- Combates al azar sin Q (en el historial, sus fallos son de desarrollo, no de azar): `prueba_acciones_v12` (91/93),
  `prueba_audio_bramavidrio` (300/313), `prueba_bramavidrio5`, `prueba_bramavidrio_combate`, `prueba_climax_jefe`,
  `prueba_coloso`, `prueba_combate_seguro`, `prueba_encuentro_desierto`, `prueba_guardian_bosque`,
  `prueba_humbaba_combate`, `prueba_meshy_e01`, `prueba_nix_v12`, `prueba_sincronia_golpes` y `prueba_banco_pruebas`.
  Con `semilla=` en la lista (no afectadas): `prueba_combate_anim_v12`, `prueba_equilibrio`, `prueba_turnos_v12`.
- `prueba_velador_v12` D: el grupo del encuentro al azar sigue al azar (es lo que prueba); fallaría con probabilidad
  ≈ 1 en un millón.

**6. Límites**
- Los combates de las pruebas son guiones (estrategia fija o ataques automáticos), no un jugador.
- El orbe: comparado en el PC sin ventana (calidad «alta», 96 partículas); en el móvil no.
- Las TRAZA llevan el fotograma absoluto (`Engine.get_process_frames()`): para comparar dos pasadas hay que quitarlo.
- Los nuevos `.gd` no tienen `.uid` (no se abre el editor); Godot los crea al abrirlo.
- Errata del mensaje de `dae1f2e`: dice «las cuatro líneas nuevas» de la lista; son tres.

**7. Peticiones**
- Ninguna en archivos de otros. Si se descongela Érebo: las dos propuestas del apartado 4.

## 2026-11-15, 02:45 · Centinela y Peón con semilla; Custodio: Sello de Clausura (e01_a3) y los tres especiales

Rama `claude/v12-custodio-sello` desde `723a97d`, en el mismo worktree. Sin push. Érebo, sin tocar. `combate.gd`, sin
tocar. Todo comprobado ejecutando, aislado, el 15/11.
- `136eb3f` Centinela y Peón: semilla tras add_child, «SEMILLA»/«TRAZA», `semilla_X=N` (suma), `_cerrar` sin 2,5 s reales;
  Peón D hasta 48. Tres pasadas iguales (`2026-11-15_021748`, `_022153`, `_022555`: 2/2, mismas huellas).
- `f447312` clip `e01__attack_sello`.
  - El GLB sin cambios se reprodujo byte a byte antes de cambiar nada.
  - Tras añadir el clip, los 6 clips anteriores tienen las mismas pistas; la malla no baja del suelo y la raíz no se
    mueve.
- `78e9bc5` el Sello en combate y la rotación Prensa, G, G, Avance, G, G, Sello, G, G, G. La marca del Sello va bajo los
  luchadores, porque encima tapaba los pies (visto en captura).
- `8745c2b` pruebas.
  - `prueba_meshy_e01` E y R: 3/3, mismas huellas, en `2026-11-15_023714`, `_023727` y `_023738`.
  - Contraprueba con el radio a 3,0: 8 fallos.
  - Regresión 4/4 en `2026-11-15_023503`.
- `2b6d086` medida del conjunto: `medir_custodio_rotacion`.
- `30ebeac` docs: §9 de `docs/v12/CUSTODIO_E01_V12.md` y la fila de la matriz.
- Cifras PROPUESTAS, sin equilibrar. Lo observado está en §9.4.
- Pendientes:
  - Redmi.
  - Sonido propio.
  - La nota del caso «custodio» en `banco_pruebas.gd`, que no es un archivo de este encargo.

## 2026-11-15, 11:40 · Semillas en las pruebas de combate que quedaban (rama `claude/v12-semillas-restantes`)

Rama `claude/v12-semillas-restantes` desde `aeb4399`, en el worktree
`D:\Aethelgard\.claude\worktrees\agent-ac0e10038a79dc528`. **Solo `aethelgard/pruebas/`**: ni el juego ni Érebo. Sin
push. Commits: `9c0de81`, `cd1721e`, `9ff7f4c` (y este informe). Lo que comprueba cada prueba no cambia.

**Arreglo (el de `prueba_gorthor_v12.gd`)**: `seed()` DESPUÉS de `root.add_child(c)` (el `_ready` de combate.gd hace
`randomize()`), el ATB inicial de los enemigos otra vez con la semilla, «SEMILLA» por combate y «TRAZA» por turno o por
paso del guion, con el fotograma relativo al combate (no el absoluto).

**Dos trampas nuevas (comprobado ejecutando, aislado):**
- **Encuentros al azar**: sin `grupo_combate`, el grupo de enemigos lo elige `_ready` con `randi()` ya «randomizado».
  En `prueba_acciones_v12` salieron Grimfang ×2, Slime y Grimfang, y Guardián de piedra y Grimfang en tres casos
  seguidos (`2026-11-15_111942` y `_111959`: huellas distintas). Ahora el grupo se elige con la semilla
  (`grupo_al_azar` de combate.gd, estática) y se fija con `grupo_combate`. Igual en `prueba_combate_seguro`. Con eso
  deja de contar `encuentros_azar` (élite cada 6), que con 3 y 5 combates no llegaba nunca.
- **Combate creado en `_initialize`**: la raíz aún no está en el árbol y el `_ready` llega DESPUÉS de la semilla. Con
  una copia temporal de `prueba_coloso` (no confirmada y borrada): al sembrar, `enemigos` vacío y `is_inside_tree()`
  falso; el ATB del Coloso salió 4,5 y 20,6 en dos pasadas (`2026-11-15_112723`, `_112737`). Ahora el primer combate
  va con `call_deferred` en `prueba_coloso`, `prueba_guardian_bosque` y `prueba_combate_seguro`.

**Por prueba** (2 pasadas seguidas con la misma huella MD5 de las líneas SEMILLA/TRAZA; todas SUPERADAS)
- `prueba_acciones_v12`: semilla 7 tras add_child, grupo con la semilla (Slime y Grimfang), TRAZA por turno de héroe.
  `2026-11-15_112124` y `_112146`: 47 líneas, `9C-93-3B-22` las dos.
- `prueba_audio_bramavidrio`: semilla 97 tras add_child. `_112124`/`_112146`: `1E-DF-CD-48`; el resto del registro,
  igual salvo «archivos de Bramavidrio que han sonado: 24 / 23» (variantes de sonido.gd con su propio `_rng`, al azar a
  propósito; solo se imprime, no se comprueba).
- `prueba_bramavidrio5`: semilla 5 tras add_child en E. `_112332`/`_112422`: registro entero idéntico.
- `prueba_bramavidrio_combate`: semilla tras add_child; TRAZA por turno del gusano y de cada héroe.
  `_112332`/`_112422`: 212 líneas, `CD-32-03-34` las dos. Ver el residuo abajo.
- `prueba_coloso` y `prueba_guardian_bosque`: el `seed()` único de `_initialize` pasa a cada caso (12 y 11), primer
  caso diferido, TRAZA por paso. `_112956`/`_113102`: `30-96-89-4A` y `06-4C-5A-D4`.
- `prueba_combate_seguro`: grupo con cada semilla, primer combate diferido, TRAZA por turno enemigo (con «auto» los
  héroes no pasan por «menu»). `_112956`/`_113102`: `AD-24-52-F2`. Grupos: 1 Slime A, Grimfang, Slime B; 7 Slime,
  Grimfang; 42 Slime ×2 y Grimfang; 2026 Guardián de piedra y Grimfang; 31337 Slime y Grimfang; las cinco, victoria.
- `prueba_encuentro_desierto`: semilla tras add_child, TRAZA por turno; `_cerrar` espera 75 fotogramas y, solo si aún
  suena algo suyo, hasta 5 s reales (antes 2,5 s reales siempre). `_112956`/`_113102`: 160 líneas, `F1-54-83-F6`.
  U (seed antes de `grupo_mar_cristal()`, sin combate) ya era fijo: sin tocar.
- `prueba_humbaba_combate`: semilla tras add_child, TRAZA por turno de héroe en B y C. `_113230`/`_113310`:
  `ED-19-A8-F2`.
- `prueba_nix_v12`: no tenía el patrón: su `seed(12345)` es la probabilidad del Lento en R, sin combate (ya fijo); los
  combates A y C no sembraban nada (daño y Lento o «Falla» al azar; la prueba acepta los dos). Ahora SEMILLA 13 tras
  add_child y TRAZA por turno de Nix. `_113230`/`_113310`: `F9-91-F7-EC`.
- `prueba_sincronia_golpes`: semilla 11 tras add_child. `_113230`/`_113310`: `85-34-2E-1A` y las líneas OK iguales.

**Dejadas como estaban (la semilla no influye en lo que comprueban)**
- `prueba_climax_jefe`: congela el combate al momento (velocidad y ATB a 0, cola vacía) y quita vida con
  `_quitar_pv`, sin azar; `_escapar` tampoco tira dados. Sus esperas en ms reales son a propósito (la posición de la
  canción va con el reloj).
- `prueba_banco_pruebas`: combates de 4 fotogramas para mirar datos (vida ×6, Armonía, héroes, interruptores); la
  huida ya se siembra antes de cada `_turno_enemigo` y en el banco nadie huye.

**Pasada conjunta (las 13, una vez)**: `D:\REBELUM_diagnostico\pruebas\2026-11-15_113415`, **13/13 SUPERADAS**,
partida real, carpeta real de datos y proyecto sin cambios. Había 10 Godot de otras copias abiertos (otro
especialista en `D:\Aethelgard_v12`). Huellas iguales a las de las pasadas dobles en 10 de 11 con traza; distinta en
`prueba_bramavidrio_combate` (`B3-7D-F0-4C`).

**Residuo que NO es de la prueba: el clímax de Bramavidrio va por el reloj real.** En esa pasada, el combate D (Kael y
Lya, semilla 20261112) diverge en el golpe de Lya del fotograma 3549 (el gusano 41 → 39 en vez de 41 → 36); mismos
fotogramas, mismas acciones y mismo resultado (gana, 38 turnos de héroe). Causa probable, observada en el código y no
aislada ejecutando: `combate.gd` lanza `_climax_destello()` cuando `musica_climax.get_playback_position()` llega al
estallido (línea 1916, «en su momento real»), y el destello crea un `CPUParticles2D` (`_particulas`), que toma su
semilla del azar global. El fotograma en que pasa depende de la carga de la máquina, y desplaza las tiradas
siguientes. Solo Bramavidrio tiene el clímax activo (`combate_climax.gd`, JEFES). Lo que comprueba la prueba no
depende de eso (las cuatro pasadas, SUPERADAS), pero su traza no es reproducible bajo carga una vez el gusano baja del
20 %. No se ha forzado desde la prueba.

**Límites**
- Combates guionizados o automáticos, no un jugador.
- Sin la batería completa ni medidas de rendimiento (por encargo).
- La causa del residuo, deducida del código; para confirmarla, una pasada del D con `combate_climax.ACTIVO = false`
  (cambio del juego, no hecho).

**Peticiones (archivos de otros)**
- `combate.gd` (`_climax_destello` / `_particulas`): que las partículas no tiren del azar global (semilla propia o
  `use_fixed_seed` si este Godot lo tiene en CPUParticles2D), o disparar el destello por fotogramas desde que empieza la
  canción. La misma idea vale para el orbe de Érebo (informe de las 02:10).


## 2026-11-15, 15:00 · Contador del Custodio («Sello en 3») y grupo de cuatro solo en el banco (rama `claude/v12-custodio-contador`)

Rama `claude/v12-custodio-contador` desde `1239e78`. Commits: `cf122a6` (contador del Custodio) y `01f69de` (grupo de
cuatro en el banco); este informe va en un tercero. Comprobado ejecutando en el PC con datos aislados; la partida real,
sin cambios en todas las pasadas.

### Tarea 1 · Custodio: «Sello en 3» y el Sello no llegaba (Redmi, APK cbc0536, caso ×8)

**Causa (comprobada).**
- La rotación es correcta y la congelación de Frostfang no le quita turnos: `_tic_congelacion` solo cuenta y devuelve
  los PV máximos.
- El contador contaba bien sus turnos, pero explicaba mal lo que faltaba:
  - no decía la unidad;
  - con recarga 0 (el turno anterior al especial) la etiqueta se quedaba sin contador;
  - el panel solo decía «En guardia».
- A ritmo de menú, un turno suyo cada ~22 s: «Sello en 3» se leía como «atascado».

**Pruebas de la causa.**
- Vídeo del Redmi: fotogramas sacados con el secuenciador de Blender y hojas de recortes en
  `D:\REBELUM_diagnostico\custodio_contador\video\hoja_00-07.png`.
  - Se ve Prensa ≈ 30 s, G, G, Avance ≈ 100 s, G ≈ 123 s («Guardia Sello en 2»).
  - Después, el menú MAGIA abierto ~45 s hasta el final: el vídeo acaba antes del Sello.
- Traza por turno: `pruebas/trazar_custodio_contador.gd`, en `2026-11-15_143000`, con el contador de antes. Turno 3 →
  etiqueta «❄ Congelado  Guardia», recarga 0; turno 4 = porton sin aviso; igual en los turnos 6 → 7 (sello).
- Con «pensar=4» (`143406`): un turno suyo cada ~22 s y el Sello a los 164 s.

**Cambio.** `combate_meshy_e01.gd`, `estados()` e `info()`; solo el texto, la rotación y las cifras siguen igual:
- «X en N turnos suyos» cuando faltan N ≥ 2;
- «⚠ X: su próximo turno» cuando toca ya;
- la guardia va delante sin quitar el contador.
- Detalle en `docs/v12/CUSTODIO_E01_V12.md` §10.

**Pruebas.**
- `prueba_meshy_e01` K: 24 combinaciones de textos, más el caso del banco ×8 con el ATB de verdad y Kael congelándolo
  (11 de 11 turnos empezados congelado). Resultado: rotación entera con los tres especiales y el contador acertado en
  cada turno. SUPERADA.
- Contraprueba con los textos de antes: FALLIDA con 66 fallos (`143324`).
- Los ataques son automáticos: **no prueban la estrategia de un jugador.**

### Tarea 2 · Nix en un grupo de cuatro SOLO en el banco

- **Cambios:**
  - `grupo.gd`: `max_activos()` devuelve 4 solo con `banco_grupo4`, `banco_pruebas` y Auditoría o editor;
    `MAX_ACTIVOS` sigue en 3.
  - `banco_pruebas.gd`: caso `grupo4`; `poner_grupo` pone o quita el permiso; el permiso está en `METAS_SESION`.
  - `combate.gd`: `SITIO_CUARTO` (640, 190), provisional.
- **Capturas** (`fotos_banco_grupo4`, con ventana, revisadas): `D:\REBELUM_diagnostico\pruebas\2026-11-15_144423\fotos_banco_grupo4\`.
  - Hay cuatro sitios y cuatro filas.
  - Los cuatro abren su menú, eligen objetivo y atacan.
  - Un turno enemigo y la línea de turnos con Nix.
  - Sin el permiso, tres.
- **`prueba_banco_pruebas`:** 10 casos; combate de cuatro con victoria y experiencia (Kael 18 → 22, Nix 0 → 4); sin el
  permiso o fuera del banco, tres. Contraprueba: 2 fallos (`144328`).
- **Documento:** `docs/v12/NIX_GRUPO_CUATRO.md`, con lo que pediría la incorporación definitiva (sin aplicar).
- **Observado:**
  - En el cuarto sitio, Nix tapa un poco a Lya. Delante, entre Garon y Lya, tapaba más.
  - Con cuatro filas, un menú de 5 opciones queda justo encima de la cabecera del grupo.

### Verificación (las pruebas afectadas, dos pasadas)

- Pasada 1, `D:\REBELUM_diagnostico\pruebas\2026-11-15_145303`: SUPERADAS 7, FALLIDAS 1.
- Pasada 2, `D:\REBELUM_diagnostico\pruebas\2026-11-15_145539`: SUPERADAS 7, FALLIDAS 1.
- Superadas en las dos pasadas: `prueba_meshy_e01`, `prueba_banco_pruebas`, `prueba_banco_pruebas_3d`,
  `prueba_enemigos_v12`, `prueba_rasgos_grupo`, `prueba_solo_lya_invoca` y `prueba_grupo_reserva` (añadida por el
  cambio en `grupo.gd`).
- FALLIDA en las dos: `prueba_combate_huella`, con E8_gorthor y la misma diferencia que con `1239e78` (ver Límites).

### Límites

- No hay Redmi: falta ver que «Sello en 3 turnos suyos» y «⚠ Sello: su próximo turno» se leen a tamaño de teléfono.
  También el caso de cuatro en el teléfono.
- `prueba_combate_huella` sale FALLIDA en esta copia **también con el código de `1239e78`** (`145144`): E8_gorthor,
  línea 2, Lya «PV 115/116» al empezar frente a 116/116 en la referencia.
  - No lo causan estos cambios: esos combates no usan al Custodio, y el grupo de cuatro no se alcanza con tres activos.
  - Se vio también el 15/11 a las 11:33 en otra pasada (`113345`), y a las 13:03 pasaba.
  - Pendiente de que lo mire quien lleve la huella. Parece depender del combate anterior (E7) o de la caché importada.

### Peticiones (archivos de otros)

- Ninguna obligatoria.
- Si el coordinador lo quiere, la nota del caso «custodio_rotacion» del banco puede decir «unos 7 turnos suyos (2-3 min
  a ritmo de menú)». No la he cambiado.

## 2026-11-19, 03:45 · PV_SLIMES_19_11: la vida de los enemigos ya no se pisa (PC-11 / C-3; rama `claude/rebelum-v12`)

Fallo del Redmi del 18/11 (`REDMI_18_11.md`, problema 7, `garon_menu.png`): en el combate de tres slimes (GRUPOS[1]) los
cuerpos se solapaban y las etiquetas «PV» se veían encima del slime de al lado.

### Qué pasaba (comprobado ejecutando, aislado, 19/11, sobre `41b38a9`)

- Pasa también **fuera del banco**: GRUPOS[1] con la vida normal mide lo mismo que el caso del banco (×6).
- GRUPOS[1]: el slime de atrás pisaba a los de delante (17-18 × 34 px), la barra del izquierdo y la etiqueta, la barra y
  el estado del derecho caían sobre el cuerpo del de atrás (hasta 17 × 31 px). Entre etiquetas no había cruce estricto.
- Cruces estrictos entre vidas en otros grupos al azar: GRUPOS[0] (dos Grimfang congelados), [2] (barra de un slime
  sobre el «⚠ Cargando» del otro y cuerpos 20 × 66 px), [3] (la señal «⚠» del slime sobre la barra del Grimfang) y, con
  `enemigos_v12`, [24] (Peones) y [27] (el estado largo del Velador sobre la vida del Grimfang, 70 × 19 px).

### Arreglo (solo presentación; fórmulas, turnos, dianas y PV sin tocar)

- `combate.gd`, GRUPOS[1] y [2]: los slimes, separados (≈ 8 px entre cuerpos). Antes [1] (250, 40), (60, 130),
  (440, 130) y [2] el primero en (30, 90); ahora (200, 40), (-40, 130), (440, 130) y (-25, 90).
- `combate.gd`, `_repartir_vidas()`: de delante hacia atrás, la vida que chocaría con otra (estado, «PV», barra y la
  señal «⚠») sube lo justo (2 px de hueco, sin pasar de y = 70). Se llama al crear las vidas, en `_actualizar()` y en
  `_marcar_aviso()`; `_ancla_vida()` suma «vida_dy». Mueve los nodos solo lo que cambia (respeta sitios puestos a mano).

### Pruebas

- Nueva `pruebas/prueba_vida_enemigos_solape.gd` (auto, en `lista_pruebas.txt`): 16 casos (GRUPOS 0-4, 7-10, 22-27 y
  GRUPOS[1] del banco «agua» ×6), con tres estados (todos cargando con señal, todos congelados y la mezcla de la captura).
  - Sin el arreglo (`032216`): **FALLOS: 52**. Con él (`032521`): **PRUEBA SUPERADA**.
- Superadas con el arreglo: `prueba_hud_combate`, `prueba_banco_pruebas`, `prueba_enemigos_v12`, `prueba_integridad`,
  `prueba_huir`, `prueba_garon`, `prueba_equilibrio`, `prueba_ia`, `prueba_menu_magia` (`032800`);
  `prueba_grupos_combate`, `prueba_centinela`, `prueba_turnos_v12`, `prueba_patrones_enemigos`,
  `prueba_zarzalin_combate`, `prueba_cencerrante_combate`, `prueba_velaria_combate`, `prueba_incorporacion` (`032927`);
  `prueba_peon_v12`, `prueba_velador_v12` (`033245`); `prueba_guardian_modelo`, `prueba_zarzalin_modelo`,
  `prueba_bramavidrio_combate`, `prueba_coloso`, `prueba_meshy_e01`, `prueba_centinela_v12`, `prueba_golem_v12`
  (`033648`); `prueba_combate_huella` (`034123`: la huella de 9 combates, E2 con GRUPOS[2], sigue igual).
- Capturas con ventana (`-- fotos=<carpeta>`), antes y después: `D:\REBELUM_diagnostico\pv_slimes_19_11\antes` y
  `\despues` (banco_GRUPOS1_mezcla, GRUPOS0/1/2/3/27).

### Límites

- No se ha visto en el Redmi. Los cuerpos 3D (Grimfang, Velador, Peón) no se miden: solo los del Slime (de sus PNG).
- Con un estado que aparece y desaparece, la vida del de detrás puede subir y bajar (solo si no, se pisarían).
- La espada de Garon sigue rozando al slime derecho de GRUPOS[1] (estaba antes; ese slime no se ha movido).

## 2026-11-19, 04:20 · PV_SLIMES_19_11_REVISION: arreglos de la revisión (rama `claude/rebelum-v12`, sobre `4452229`)

### Hallazgo medio: el solape de cuerpos seguía en el estado real del Redmi (confirmado ejecutando)

- La revisión tenía razón. Con el Slime **aplastado** como en el juego cuando prepara su golpe (`_turno_patron`, plan
  «encoge»: rig ×(1,12; 0,78), el estado de `garon_menu.png`), con las posiciones de `4452229` los cuerpos se volvían a
  pisar: GRUPOS[1] «cargando» A↔B 6 × 11 px y A↔C 4 × 12 px; «mezcla» A↔C 8 × 74 px; GRUPOS[2] 4-8 px; y también
  **GRUPOS[8]** (dos slimes, no tocado antes) 5-9 px. La frase del informe anterior «los tres slimes quedan separados»
  solo valía SIN aplastar (las capturas de `pv_slimes_19_11\despues` no tenían el aplastamiento). Cifra corregida: los
  cuerpos de GRUPOS[2] eran 20 × 68 px (registro `032216`), no 20 × 66.
- Arreglo (`combate.gd`, GRUPOS): [1] (230, 40), (-40, 130), (505, 130) (antes de la revisión (200, 40) y (440, 130));
  [2] (-50, 90) y (222, 135) (antes (-25, 90) y (215, 135)); [8] el segundo en (416, 125) (antes 380). Medido: ≥ 9,8 px
  entre cuerpos, aplastados o no (GRUPOS[1] «cargando»: A 168-307, B …-158, C 321-…; «mezcla»: A 187-311, C 321-…).
  **Cambia el juego normal**: dónde están esos slimes, adónde corren los héroes, partículas, etc.

### Hallazgos bajos

- Comprobación «solo presentación» de la prueba: reescrito el comentario (comprueba que e["pos"] sale de su fila de
  GRUPOS, no que la colocación sea la de antes; GRUPOS[1], [2] y [8] cambiaron a propósito).
- Cámara (×1,08): `_ancla_vida`, `_piezas_vida`, `_repartir_vidas` y `_marcar_aviso` miden y colocan con la escena **en
  reposo** (`_en_reposo()`: PIVOTE_ESCENA·(1−TAM_ESCENA) + p·TAM_ESCENA). Antes, con la escena acercada, la señal «⚠»
  quedaba 10-85 px fuera de su sitio y la vida del Grimfang de GRUPOS[3] o del Peón B de [24] cambiaba de «vida_dy».
- Estados largos: nuevo `_texto_estado()` (ANCHO_ESTADO = 130 px): si el rótulo no cabe, sigue en otra línea y crece
  hacia arriba (la última línea donde estaba; la señal «⚠» sube con él). Con uno o con los que caben, el texto es el
  de siempre. Motivo: «❄ Congelado  ⚠ Cargando» (se da en el juego normal: congelar no corta la carga) caía sobre el
  cuerpo del slime de detrás (79-80 × 27 px). `combate_turnos_v12.gd _avisos()` lee también el rótulo en varias líneas.
- Techo (y = 70): **no arreglado, anotado**. Con la magia negra de desarrollo (APAGADA en el juego normal) y cinco
  estados por enemigo, en GRUPOS[0], [24] y [27] una vida llega al techo y sigue cruzando a la otra (3-23 px de ancho).
  La prueba lo saca como AVISO (12 cruces), no como fallo. Recortar el texto o mover la vida en horizontal queda para
  cuando la magia negra entre en el juego normal (decisión del usuario).

### Pruebas (comprobado ejecutando, aislado, 19/11)

- `prueba_vida_enemigos_solape` ampliada: Slime aplastado al cargar, cuerpos en todos los estados, cinco estados
  («doble» = «❄ Congelado  ⚠ Cargando»; «negra» = la doble con tres estados de magia negra), su señal sin tapar su
  rótulo y la cámara acercada. Sin el arreglo (código de `4452229`, prueba nueva): **FALLOS: 61** (7 cargando,
  5 mezcla, 7 doble, 8 negra, 34 cámara; `D:\REBELUM_diagnostico\pruebas\2026-11-19_035703`). Con él: **PRUEBA
  SUPERADA** (`2026-11-19_035632` y `035749`).
- Superadas con el arreglo: `prueba_integridad`, `prueba_hud_combate`, `prueba_banco_pruebas`, `prueba_enemigos_v12`,
  `prueba_huir`, `prueba_garon`, `prueba_equilibrio`, `prueba_ia`, `prueba_menu_magia` (`035749`; `prueba_menu_nuevo`
  es MANUAL); `prueba_grupos_combate`, `prueba_centinela`, `prueba_turnos_v12`, `prueba_patrones_enemigos`,
  `prueba_zarzalin_combate`, `prueba_cencerrante_combate`, `prueba_velaria_combate`, `prueba_incorporacion`,
  `prueba_peon_v12`, `prueba_velador_v12`, `prueba_magia_negra`, `prueba_bramavidrio_combate`, `prueba_coloso`
  (`035916`); `prueba_combate_huella`, `prueba_meshy_e01`, `prueba_guardian_modelo`, `prueba_zarzalin_modelo`,
  `prueba_centinela_v12`, `prueba_golem_v12`, `prueba_naira_combate`, `prueba_humbaba_combate` (`040653`).
- Capturas con ventana, slimes aplastados: `D:\REBELUM_diagnostico\pv_slimes_19_11\revision\antes` y `\despues`
  (`banco_GRUPOS1_mezcla`, `_doble`, `_negra`, GRUPOS0/1/2/3/27).

### Límites

- No se ha visto en el Redmi. Los cuerpos 3D (Grimfang, Velador, Peón) siguen sin medirse: en GRUPOS[2] el arma del
  Grimfang queda muy cerca del borde derecho del slime B (≈ 4 px más cerca que antes); en GRUPOS[1] el slime derecho,
  ahora más a la derecha, queda justo encima de la espada de Garon (no se pisan en la captura, pero casi).
- El aplastamiento se reproduce poniendo el final de su tween, no pasando por `_turno_patron` (azar y temporizadores).
