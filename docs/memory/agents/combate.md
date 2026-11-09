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
