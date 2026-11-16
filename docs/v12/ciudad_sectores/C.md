# Ciudad de Oakhaven, maqueta: sectores del agente C (16/11, EXPERIMENTAL [P])

Sectores 5 **Pasajes Viejos** (`pasajes`) y 6 **Patio del Cuervo** (`cuervo`) de la maqueta recorrible de la ciudad
(plan: `docs/v12/CIUDAD_OAKHAVEN_PLAN.md`; contrato y cargador: `docs/v12/CIUDAD_OAKHAVEN.md`). Rama `area-ciudad-c`
(desde `4f67e4b`) y, con los arreglos tras la revisión, `area-ciudad-c-2` (§7). Solo se tocaron
`aethelgard/zonas3d/ciudad/sectores/{pasajes,cuervo}/trazado.gd` y este archivo; los `sector.tscn` siguen igual (solo
dicen su `id`). Es un BLOCKOUT a escala de los personajes, no el acabado.

Marcas: **[C]** canon citado (`ciudades/oakhaven.gd`, `ciudades/taberna_juegos.gd`, el plan §0), **[P]** propuesta.

## 1. Superficies medidas (`prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Antes (M0) | `area-ciudad-c` | Ahora (`-c-2`) | Objetivo | Suelos | Bloques | Ocultables | Puertas | Grafo local |
|---|---|---|---|---|---|---|---|---|---|
| 5 Pasajes Viejos | 360 m² | 1 160 m² | **1 121 m²** | 1 000-1 700 | 22 | 87 | 20 | 14 | 25 nodos |
| 6 Patio del Cuervo | 1 348 m² | 1 331 m² | **1 310 m²** | 1 000-1 700 | 15 | 72 | 13 | 10 | 16 nodos |

Ciudad entera: 11 412 m²; entradas previstas en toda la ciudad: 34. Cotas: Pasajes 1 · 1,44 · 1,5 · 2; Cuervo 2 · 3 (las
de `plano.gd`). Las cinco conexiones de estos sectores (Calle del Cuervo, Escaleras de las Terrazas, Paso Cubierto de la
Botica, Pasaje de las Velas, Arco de los Pasajes) quedan a su cota, llanas ≥ 1 m, con su ancho acordado y andables en los
dos sentidos.

Por suelo (m² andables): Patio del Cuervo 506 + porche 77 = **583** (bajo el tope de ≈ 600 del plan); Pie de las
Escaleras 120 (ensanche aparte); boca de la calle 48; Corro de los Niños 196; Plazuela del Pozo 149; Patio de los
Vecinos 260; Patio de las Velas **62** (era 104).

## 2. Pasajes Viejos (sector 5)

Caja x −100..−30, z 50..95. Lo estrecho y antiguo: callejones de 2-3 m, cinco pasos bajo casa, cuatro sin salida con razón.

```
 z 50  Pasaje de las Velas ↓ (del Cuervo)                PALOMAR VIEJO      Paso Cubierto de la Botica → plaza (x −30)
       Corral del Rincón ─ Callejón de las Macetas ─┬─ Callejón Alto ──┬── Plazuela del Pozo ── Paso Cubierto
       (sin salida)      (pilón)  │                 │     callejón de  │        │             │
       Escalera de las Macetas   Bajada de los      │     Pip (sin     │   Pasaje Bajo   Escalerilla de
                          │      Vecinos            │     salida) ↓    │   las Casas     la Botica
 z 65  Rincón Fresco ─ PATIO DE LOS VECINOS ────────┘     la GRIETA    │   (cubierto)    (paso bajo casa,
       (sin salida)            │                    (luz que asoma)    │        │         escalera)
 z 70                          │                   PATIO DE LAS VELAS  │        │             │
                         paso bajo casa            (solo por la grieta)│        │             │
 z 80  ────────────── Calle Baja (cerería) ────────────────────────────── Plazuela del Arco ── Arco → Puerta del Sur
                               paso bajo casa ↓
 z 86-92              Huerto de la Muralla (sin salida; casa del huertano)
```

- **Referencias**: la oficial es el Patio de las Velas [C] (`ref_pasajes`, −56; 70), secreto por canon. La que se ve de
  lejos es el **Palomar Viejo** [P]: una torre estrecha de 2 × 2 m y 12 m de cota al fondo norte de la Plazuela del Pozo,
  entre dos tapias, 3-4 m por encima de los tejados de alrededor (8-8,5), con su puerta al sur (la cámara la ve de fondo).
- **El secreto** [C]: al fondo del callejón de Pip (sin salida, 2 m) hay un paso de 1,2 m entre dos muros que baja 0,56 m
  al Patio de las Velas (22 %), su ÚNICA entrada (como la 2D: callejón → grieta al fondo → patio al sur). La luz [C: «de
  lejos solo se ve luz en una grieta del callejón»] sube entre los muros (6 m) y asoma 1,2 m por encima
  (`resplandor_grieta`, y 7,4..8,6): con la cámara de la ciudad se ve a 34-41° bajo el horizonte (el cuadro llega a 44°)
  desde TODO el Callejón Alto; antes solo dentro del callejón. En la maqueta la grieta se anda; cuando haya sistemas, se
  abrirá tras el secreto de Pip [C].
- **El Patio de las Velas** [C], pequeño: 11 × 6 m (62 m² andables; la 2D, 9 × 4 casillas). El altar con el anillo partido y
  las velas [C] contra el muro este; el sitio del cofre `oak_cofre_velas` [C] al oeste, como en la 2D; un banco de piedra
  al sur. Anclas `velas`, `nota_velas` (la nota del altar, `nota_oak_velas` [C]) y `cofre_velas`.
- **Para orientarse**: la Plazuela del Pozo [P] (149 m², pozo con caño, árbol, banco, el puesto y el taller del cestero, el
  Palomar), justo a la entrada desde el Paso Cubierto de la Botica.
- **Corredores y pasos bajo casa**: el Paso Cubierto de la Botica (bajo una casa, sigue el de la plaza), el Pasaje Bajo
  las Casas (cubierto en su tramo central, 2 → 1 al 9 %), el paso de la Escalerilla de la Botica, el del Patio de los
  Vecinos a la Calle Baja, el del huerto y el Arco de los Pasajes (planta encima, z 80..83 como lo acordado).
- **Escaleras de piedra y rampas**: la escalera de la Escalerilla (2 → 1 en 3 m, 33 %), la grieta (22 %), la del paso de
  los vecinos (25 %), la Escalera de las Macetas y la Bajada de los Vecinos (suaves). Niveles: norte a 2, Patio de las
  Velas a 1,44, Patio de los Vecinos a 1,5, sur a 1; los separan casas y tapias.
- **Atajo**: la Escalerilla de la Botica, del Paso Cubierto al Arco sin pasar por la plazuela (unos 20 m menos que por el
  Pasaje Bajo).
- **Sin salida con razón**: el callejón de Pip (la grieta, el secreto), el Huerto de la Muralla (bancales, pozo,
  cobertizo y la casa del huertano; trabajo), el **Rincón Fresco** [P] (un banco a la sombra de la muralla, para las tardes
  de calor: el sol de la escena, bajo y del oeste-suroeste, no llega nunca, así que el antiguo «Rincón del Sol» no podía
  serlo) y el Corral del Rincón (gallinero y leña).

| Qué atrae | Qué se descubre o se hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| Lo estrecho y antiguo; el Palomar Viejo que asoma sobre los tejados; la luz de la grieta [C] vista desde el Callejón Alto; el ir y venir de la Plazuela del Pozo | La grieta y el Patio de las Velas [C] (el cofre y la nota del altar [C]); el paso a la Botica de Selene [C] (en la plaza) por el Paso Cubierto; el atajo de la Escalerilla; los rincones sin salida | Pip [C] (`pip`, en su callejón); el cestero, el cerero y el huertano [P]; vecinos tendiendo y con las gallinas [P]; niños en la plazuela y en el patio [P] | El secreto de Pip y la grieta [C]; «La fórmula desaparecida» [C]: Pip vio volar las páginas de Mirta (la Botica queda al otro lado del Paso Cubierto) | Tras el secreto de Pip, la grieta queda abierta [C] (hoy se anda: sin sistema); el cofre del patio, abierto; las velas cambian con las notas leídas (plan §3) |

Puertas previstas (14, todas «en obras»): la cerería [P], el taller del cestero [P], el Palomar Viejo [P], el cobertizo
del huerto [P], la casa del huertano [P] y 9 casas. Anclas de vida: `pip`, `velas`, `nota_velas`, `cofre_velas`,
`grieta_pip`, `palomar`, `fuente_pozo`, `pilon_macetas`, `ninos_pozo`, `cestero`, `cerero`, `vecina_tendiendo`,
`ninos_vecinos`, `fuente_vecinos`, `banco_fresco`, `huertano`, `gallinas`.

## 3. Patio del Cuervo (sector 6)

Caja x −100..−30, z −5..50. Encuentro y ocio en dos niveles (3 arriba, 2 abajo).

```
 z −5  Cuadra │ TABERNA DEL CUERVO OXIDADO [C]     │ Pie de las Escaleras ↑ Terrazas (arco) │ casas
       Corral │ (hastial y chimenea que asoman)    │ fuente   ── Callejón del Tonel (servicio) ─┐
 z 5   (sin   │ porche, mesas · letrero de hierro  │casa│ (ensanche aparte)                    │ almacén · paso bajo casa
       salida)│ PATIO DEL CUERVO: fuente, árbol, bancos, barriles [C], mesa de parejas [C]     │ soportal · tonelería
 z 20         │ FERIA (área: carro y bancos de cada día) ─── boca ── Calle del Cuervo [C] → plaza (x −30)
 z 27          pretil + muro de tierra │escalinata│              Callejón del Corro ↓ (puerta en el recodo)
 z 30-39       CORRO DE LOS NIÑOS (rayuela, árbol, tronco) ──────┘
 z 39-50                     Pasaje de las Velas ↓ (a los Pasajes Viejos)
```

- **Referencia**: la Taberna del Cuervo Oxidado [C] (`ref_cuervo`, −78; 6,4), al norte del patio. Su letrero de hierro
  con un cuervo [C] cuelga de un brazo sobre la puerta, DE CARA AL SUR (la cámara mira siempre al norte: la placa de
  antes, perpendicular a la fachada, se veía de canto). Un hastial [P] de 6 × 6 m y la chimenea suben a 14-15 m, 3-4 m
  sobre las casas vecinas (11): se reconoce desde la boca de la Calle del Cuervo. La posadera [C] a la puerta.
- **Plaza de encuentro**: el Patio del Cuervo con su porche, **583 m²** (bajo el tope de ≈ 600 del plan; antes, sin
  separar el Pie, eran unos 760): fuente, árbol con bancos, los barriles del favor de la posadera [C] y la **mesa de juego
  [C]** (`oak_mesa_parejas`, «Jugar a las parejas», `taberna_parejas.gd`, en el patio como en la 2D; los demás juegos de
  taberna [C], dentro).
- **La Feria de los Oficios** [P]: un ÁREA, `FERIA_PATIO` (x −84..−72, z 16,5..23,5, con el ancla global
  `reserva_feria_patio`), que deja libres el paso de 3 m a la escalinata del corro y el centro del patio (el nodo `n_patio`
  ya no está en ella: los puestos no cortarán las rutas de los vecinos). De cada día hay en ella el carro de la posada y
  unos bancos corridos [P], que la Feria sustituye.
- **Pie de las Escaleras** [P]: ensanche aparte (120 m²) con fuente y un arco sobre el arranque (borde z −5, cota 3); una
  casa estrecha (x −68..−64, con su puerta al patio) lo separa del porche y se entra desde el patio por 6 m.
- **Callejón del Tonel** [P], CALLEJÓN DE SERVICIO (no atajo: del Pie de las Escaleras al borde de la plaza son ≈ 48 m
  cruzando el patio y ≈ 50 m por él): por detrás del patio, con el almacén de la posada [P] (puerta con tejadillo) y un paso
  bajo casa. Es el camino de los barriles: del almacén a la calle y al patio [P, ancla `mozo_almacen` para la vida].
- **Niños**: el Corro de los Niños [P], un nivel más abajo (cota 2), con rayuela, árbol y un tronco de banco; se baja por
  una escalinata (33 %) entre un pretil y un muro de tierra con la tapa a la cota del patio.
- **Caballos**: el Corral de la Posada [P] (sin salida), con la cuadra, el abrevadero, dos caballos y el mozo.
- **Calle del Cuervo** [C]: baja de 3 a 2 hacia la plaza (5,6 %), con un soportal [P] (cuatro pilares que siguen la
  rampa y la planta encima), la tonelería [P] con su puesto y un banco.
- **Callejón del Corro** [P]: de la boca al corro; en su recodo (−56; 34), la puerta de la casa de la esquina, al fondo
  del tramo este-oeste (la cámara la ve; antes eran 15 m sin nada).
- **Bucles**: patio → boca → Callejón del Corro → corro → escalinata → patio; patio → Pie de las Escaleras → Callejón
  del Tonel → calle → boca.

| Qué atrae | Qué se descubre o se hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La taberna, su hastial y su letrero que chirría [C]; el bullicio del patio; los niños del corro | Posada [C] (dormir, comer, rumores); la mesa de parejas del patio [C] y los juegos de dentro [C]; «Tres favores para el Cuervo» [C] (los barriles); los caballos del corral; el callejón de servicio | La posadera [C] (`posadera`); parroquianos [C voces] (`parroquianos`); el tonelero, el mozo de cuadra y el del almacén [P]; niños [P] | La taberna es el hogar de Kael [C] | Tras «Tres favores» [C], noche gratis; la Feria de los Oficios [P] se anuncia y se celebra en `FERIA_PATIO` (sus puestos sustituyen al carro y a los bancos); propuesta [P]: los barriles del favor dejan su sitio libre cuando se cumple |

Puertas previstas (10): la taberna [C], la cuadra [P], la tonelería [P], el almacén de la posada [P] y 6 casas. Anclas de
vida: `posadera`, `parroquianos`, `barriles`, `mesa_parejas`, `fuente_patio`, `ninos_patio`, `ninos_corro`, `caballo_1`,
`caballo_2`, `mozo_cuadra`, `mozo_almacen`, `tonelero`, `fuente_escaleras`, y la reserva `reserva_feria_patio`.

## 4. Reglas del plan cumplidas y cómo

- **Contra el vacío**: ningún tramo de más de 12 m sin puerta, banco, puesto o vista (Callejón Alto: banco, puerta, la
  boca de Pip y la luz de la grieta; Callejón de las Macetas: el pilón a media tapia; Calle Baja: cerería, banco, el paso
  al huerto y la puerta del fondo; Escalerilla: paso bajo casa, puerta, escalera; Pasaje de las Velas: una puerta a media
  bajada; Calle del Cuervo: soportal, tonelería, banco; Callejón del Corro: la puerta del recodo; la franja sur del
  patio: el carro, los bancos corridos y la vista del corro desde el pretil).
- **Fachadas variadas**: casas de 2 a 20 m de frente y de 3,5 a 8,5 m de alto (el palomar, 10; el hastial de la taberna,
  sobre 8,5), con bases a la cota de cada calle.
- **Puertas que se ven** (la cámara está al sur y no gira): 19 de las 24 en caras al sur o al este/oeste al fondo de una
  calle este-oeste o de una plaza; 3 en pasos de norte a sur llevan un tejadillo saliente que la cámara ve desde arriba
  (Escalerilla, almacén, Pasaje de las Velas); 2 siguen al norte (ver §6). Todas las hojas sobresalen 0,08 m de su fachada
  (antes 8 compartían cara con su casa y parpadeaban).
- **Anchos**: pasajes ≥ 1,6 m salvo la grieta [C] (1,2 m, «se pasa de lado»): las macetas del callejón están sobre la
  tapia (en el suelo lo dejaban en 1,5) y los bancales del huerto dejan pasos de 1,75-2,4 m.
- **Visibilidad**: lo que tapa al sur de lo andable está en `OCULTABLES`; pasos, corredores y tejadillos son `cubierta`;
  árboles y caños finos (0,5 m: con 0,6 el redondeo de `Rect2` los dejaba en 0,6000001 y no contaban como finos). Repasado
  CASILLA A CASILLA (0,25 m, no solo la muestra de cada metro de la prueba) en los dos sectores y en las casillas de los
  vecinos a menos de 30 m: nada tapa a Kael sin aclararse. Lo que salió así: `casa_corro_ne` (Kael pegado al pretil del
  patio), el gallinero y la tapia del corral (ahora pegados a la pared y bajo la cabeza), el caño del pozo, `casa_pie`, el
  resplandor de la grieta, la tapia del borde de la Escalerilla y, desde las Terrazas, el hastial y la chimenea de la
  taberna (ocultables). La ropa tendida va por encima de la cabeza (1,8-2,5 m sobre el patio).
- **Cámara**: sin `CAMARA_ZONAS` propias: no hacen falta (no hay corredores largos de norte a sur con fachadas al sur del
  foco); una zona aquí rozaría la del Paso Cubierto de la plaza (x −31..−12).

## 5. Nombres nuevos [P] (a las decisiones del plan §8)

Pasajes Viejos: Callejón de las Macetas (y su pilón), Callejón Alto, Plazuela del Pozo, Palomar Viejo, Escalerilla de la
Botica, Pasaje Bajo las Casas, Plazuela del Arco, Calle Baja, la cerería, Patio de los Vecinos, Bajada de los Vecinos,
Escalera de las Macetas, Rincón Fresco (antes Rincón del Sol), Corral del Rincón, Huerto de la Muralla; el cestero y su
taller, el cerero, el huertano y su casa.
Patio del Cuervo: Corral de la Posada (cuadra), Pie de las Escaleras, Callejón del Tonel (de servicio), almacén de la
posada, Corro de los Niños, Callejón del Corro, soportal y tonelería de la Calle del Cuervo, el carro de la posada; el
tonelero, el mozo de cuadra, el mozo del almacén. (La mesa de juego del patio NO es nombre nuevo: es canon.)

## 6. Pendiente y peticiones

- **Al coordinador (`plano.gd`)**: (1) el «Pasaje de las Velas [P]» (conexión `pasaje_velas`, el paso público del Corro a
  los Pasajes) lleva el nombre del patio secreto, al que NO lleva: confunde y anticipa el secreto («nadie conoce un
  secreto antes de descubrirlo»). Propuesta: «Pasaje del Corro [P]». Si se cambia, se cambia aquí el comentario de los dos
  trazados. (2) El ancla global `ref_pasajes` está escrita a y 1,43 y el Patio de las Velas queda llano a 1,44 (la prueba
  admite 0,02): conviene escribir 1,44.
- **Al coordinador (`prueba_ciudad_plano`, sección 8)**: mirar la visibilidad en TODAS las casillas (o en las que están a
  menos de 0,5 m de un bloque): la muestra de cada metro no vio casa_corro_ne, el gallinero, la tapia del corral ni el
  caño del pozo. Y en `trazado_comun.gd`, `fino()` debería admitir un margen (p. ej. `FINO + 0.001`): un `Rect2` de 0,6
  queda en 0,6000001 y no cuenta como fino.
- **Al coordinador (`blockout.gd`)**: un tipo para luz (emisivo, sin sombra) para el resplandor de la grieta y las velas;
  hoy es una caja «decor».
- **Puertas que siguen al norte** (la cámara no las ve; solo su rótulo «(en obras)» y cuando la casa se aclara):
  `casa_velas_no` (al Callejón Alto; sus otras caras dan de canto a la Bajada de los Vecinos y al callejón de Pip, o al
  Patio de las Velas, que no puede tener otra entrada) y `casa_arco` (a la Plazuela del Arco; su casa no tiene otra cara a
  lo andable). En el acabado: marcar el umbral con algo que asome (farol, escalón alto) o dejarlas como puertas traseras.
- **Con el agente A**: la Botica de Selene [C] está en la plaza junto al callejón de la Botica (x −14), no en la boca del
  Paso Cubierto; si se quiere «junto al Paso Cubierto» (plan §2), es su sector.
- **Ocultables**: 33 mallas aparte en estos dos sectores (cada una, una llamada de dibujo más cuando están montados). Sin
  medir (encargo); si el perfil bajo se pasa de llamadas, fundir casas contiguas del sur en menos bloques.
- **Recorrido con los controles normales** (1600×720 y 1280×720) por una persona: no hecho (solo pruebas sin ventana).
- Vida (vecinos en sus anclas, la grieta cerrada hasta el secreto de Pip, las velas, el cofre), interiores y acabado:
  fases siguientes.

## 7. Arreglos tras la revisión (`area-ciudad-c-2`, 16/11)

Dos revisiones de solo lectura de `area-ciudad-c` (diseño, y reglas y visibilidad casilla a casilla). Cada hallazgo se
comprobó antes de tocarlo (con una revisión propia, en Godot, de cada casilla de 0,25 m de los dos sectores y de los
vecinos cercanos).

| Hallazgo | Gravedad | Qué se hizo |
|---|---|---|
| Pasajes sin referencia visible de lejos; tapia ciega al fondo de la plazuela | media | Palomar Viejo de 12 m con puerta al sur, entre dos tapias |
| Letrero de la taberna de canto; la taberna apenas destaca | media | Letrero colgado de un brazo, de cara al sur; hastial y chimenea a 14-15 m (ocultables desde las Terrazas) |
| El «atajo» del Tonel es más largo | media | Es un callejón de servicio (camino de los barriles del almacén), dicho así aquí y en el trazado |
| Patio + porche + Pie ≈ 760 m² (tope 600); franja sur vacía | media | Casa estrecha que separa el Pie (583 m² patio y porche); carro y bancos corridos en la franja |
| 12 de 22 puertas no se ven | media | 7 movidas a caras que se ven (5 en Pasajes, 2 en el Cuervo), 3 con tejadillo, 2 siguen al norte (§6); dos nuevas al sur (palomar, casa del Pie) |
| La luz de la grieta no se ve desde el Callejón Alto | media | Muros de 6 m y resplandor que asoma 1,2 m: en cuadro desde todo el callejón (medido) |
| Callejón del Corro, 15 m vacíos | media | La puerta de la casa de la esquina, en el recodo |
| Patio de las Velas sin cofre ni nota; grande y vacío | media | 11 × 6 m; altar al este, cofre al oeste, banco; anclas `cofre_velas` y `nota_velas` |
| `casa_corro_ne` tapa a Kael ante el pretil | media | Ocultable |
| Macetas: callejón de 1,5 m | media | Sobre la tapia; un pilón deja 1,65 m |
| 8 hojas de puerta en el plano de su fachada | media | Todas sobresalen 0,08 m |
| La mesa del patio es canon y estaba como [P] | media | `mesa_parejas` [C] |
| Rincón del Sol siempre a la sombra | baja | Rincón Fresco (la muralla le da sombra con cualquier geometría razonable) |
| Feria sobre el nodo central | baja | `FERIA_PATIO` (área) y `n_patio` fuera de ella |
| «Pasaje de las Velas»; casas sin oficio; losa ciega de 2 m | baja | Nombre: pedido al coordinador; cerería, casa del huertano y palomar; la losa es una tapia |
| Gallinero y leña con ranuras | baja | Pegados a la pared |
| Tapia del corral tapa la cabeza | baja | 1,4 m de alto |
| Arco de 3,6 m (acordado 3) | baja | z 80..83 |
| Bancales con pasos de 1-1,2 m | baja | Pasos de 1,75-2,4 m; el huertano, entre ellos |
| La ropa tendida se atraviesa | baja | Por encima de la cabeza |
