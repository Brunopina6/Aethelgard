# Ciudad de Oakhaven, maqueta: sectores del agente C (16/11, EXPERIMENTAL [P])

Sectores 5 **Pasajes Viejos** (`pasajes`) y 6 **Patio del Cuervo** (`cuervo`) de la maqueta recorrible de la ciudad
(plan: `docs/v12/CIUDAD_OAKHAVEN_PLAN.md`; contrato y cargador: `docs/v12/CIUDAD_OAKHAVEN.md`). Rama `area-ciudad-c`,
desde `4f67e4b`. Solo se tocaron `aethelgard/zonas3d/ciudad/sectores/{pasajes,cuervo}/trazado.gd` y este archivo; los
`sector.tscn` siguen igual (solo dicen su `id`). Es un BLOCKOUT a escala de los personajes, no el acabado.

Marcas: **[C]** canon citado (`ciudades/oakhaven.gd`, `ciudades/taberna_juegos.gd`, el plan §0), **[P]** propuesta.

## 1. Superficies medidas (`prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Antes (M0) | Ahora | Objetivo | Suelos | Bloques | Ocultables | Puertas | Grafo local |
|---|---|---|---|---|---|---|---|---|
| 5 Pasajes Viejos | 360 m² | **1 160 m²** | 1 000-1 700 | 22 | 74 | 19 | 13 | 25 nodos |
| 6 Patio del Cuervo | 1 348 m² | **1 331 m²** | 1 000-1 700 | 15 | 62 | 10 | 9 | 16 nodos |

Ciudad entera tras el cambio: 11 473 m² (era 10 689); entradas previstas en toda la ciudad: 32 (eran 11). Cotas: Pasajes
1 · 1,44 · 1,5 · 2; Cuervo 2 · 3 (las de `plano.gd`). Mayor salto entre casillas vecinas de la ciudad: 0,143 m (en
Oficios, no en estos sectores). Las cinco conexiones de estos sectores (Calle del Cuervo, Escaleras de las Terrazas,
Paso Cubierto de la Botica, Pasaje de las Velas, Arco de los Pasajes) quedan a su cota, llanas ≥ 1 m y andables en los
dos sentidos.

## 2. Pasajes Viejos (sector 5)

Caja x −100..−30, z 50..95. Lo estrecho y antiguo: callejones de 2-3 m, cinco pasos bajo casa, dos sin salida con razón.

```
 z 50  Pasaje de las Velas ↓ (del Cuervo)          Paso Cubierto de la Botica → plaza (x −30)
       Corral del Rincón ─ Callejón de las Macetas ─┬─ Callejón Alto ──┬── Plazuela del Pozo ── Paso Cubierto
       (sin salida)        │                        │     callejón de  │        │             │
       Escalera de las Macetas   Bajada de los      │     Pip (sin     │   Pasaje Bajo   Escalerilla de
                          │      Vecinos            │     salida) ↓    │   las Casas     la Botica
 z 65  Rincón del Sol ─ PATIO DE LOS VECINOS ───────┘     la GRIETA    │   (cubierto)    (paso bajo casa,
       (sin salida)            │                          ↓            │        │         escalera)
 z 70                          │                   PATIO DE LAS VELAS  │        │             │
                         paso bajo casa            (solo por la grieta)│        │             │
 z 80  ────────────── Calle Baja ──────────────────────────────────────── Plazuela del Arco ── Arco → Puerta del Sur
                               paso bajo casa ↓
 z 86-92              Huerto de la Muralla (sin salida)
```

- **Referencia**: el Patio de las Velas [C] (`ref_pasajes`, −56; 70), rincón escondido con el altar pequeño y las velas
  [C] contra su muro norte. Su ÚNICA entrada es la grieta [C]: al fondo del callejón de Pip (sin salida, 2 m) hay un paso
  de 1,2 m entre dos muros que baja 0,56 m al patio (22 %). Es la misma disposición que la 2D [C] (callejón → grieta al
  fondo → patio al sur). En la maqueta se anda; cuando haya sistemas, se abrirá tras el secreto de Pip [C].
- **Para orientarse**: la Plazuela del Pozo [P] (156 m², pozo con caño, árbol, banco, el puesto y el taller del cestero)
  justo a la entrada desde el Paso Cubierto de la Botica.
- **Corredores y pasos bajo casa**: el Paso Cubierto de la Botica (bajo una casa, sigue el de la plaza), el Pasaje Bajo
  las Casas (cubierto en su tramo central, 2 → 1 al 9 %), el paso de la Escalerilla de la Botica, el del Patio de los
  Vecinos a la Calle Baja, el del huerto y el Arco de los Pasajes (planta encima, entre dos casas).
- **Escaleras de piedra y rampas**: la escalera de la Escalerilla (2 → 1 en 3 m, 33 %), la grieta (22 %), la del paso de
  los vecinos (25 %), la Escalera de las Macetas y la Bajada de los Vecinos (suaves). Niveles: norte a 2, Patio de las
  Velas a 1,44, Patio de los Vecinos a 1,5, sur a 1; los separan casas y tapias.
- **Atajo**: la Escalerilla de la Botica, del Paso Cubierto al Arco sin pasar por la plazuela (de la Botica a la Puerta
  del Sur por dentro de los pasajes).
- **Sin salida con razón**: el callejón de Pip (la grieta, el secreto), el Huerto de la Muralla (bancales, pozo,
  cobertizo; trabajo), el Rincón del Sol (un banco al sol junto a la muralla) y el Corral del Rincón (gallinero y leña).

| Qué atrae | Qué se descubre o se hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| Lo estrecho y antiguo; la luz de la grieta al fondo del callejón de Pip [C]; el ir y venir de la Plazuela del Pozo | La grieta y el Patio de las Velas [C]; el paso a la Botica de Selene [C] (en la plaza) por el Paso Cubierto; el atajo de la Escalerilla; los rincones sin salida | Pip [C] (`pip`, en su callejón); el cestero [P]; vecinos tendiendo y con las gallinas [P]; el huertano [P]; niños en la plazuela y en el patio [P] | El secreto de Pip y la grieta [C]; «La fórmula desaparecida» [C]: Pip vio volar las páginas de Mirta (la Botica queda al otro lado del Paso Cubierto) | Tras el secreto de Pip, la grieta queda abierta [C] (hoy se anda: sin sistema); las velas cambian con las notas leídas (plan §3) |

Puertas previstas (13, todas «en obras»): 11 casas, el Taller del cestero [P] y el Cobertizo del huerto [P].
Anclas de vida: `pip`, `velas`, `grieta_pip`, `fuente_pozo`, `ninos_pozo`, `cestero`, `vecina_tendiendo`, `ninos_vecinos`,
`fuente_vecinos`, `sol`, `huertano`, `gallinas`.

## 3. Patio del Cuervo (sector 6)

Caja x −100..−30, z −5..50. Encuentro y ocio en dos niveles (3 arriba, 2 abajo).

```
 z −5  Cuadra │ TABERNA DEL CUERVO OXIDADO [C]   │ Pie de las Escaleras ↑ Terrazas (arco) │ casas
       Corral │ porche, mesas · letrero de hierro│ fuente   ── Callejón del Tonel ─┐
 z 5   (sin   │ terraza ─────────────────────────┼──────────                     │ (paso bajo casa)
       salida)│ PATIO DEL CUERVO: fuente, árbol, bancos, barriles [C],           │ soportal · tonelería
 z 20         │ mesa de juegos · FERIA (sitio libre) ──── boca ── Calle del Cuervo [C] → plaza (x −30)
 z 27          pretil + muro de tierra │escalinata│              Callejón del Corro ↓
 z 30-39       CORRO DE LOS NIÑOS (rayuela, árbol, tronco) ──────┘
 z 39-50                     Pasaje de las Velas ↓ (a los Pasajes Viejos)
```

- **Referencia**: la Taberna del Cuervo Oxidado [C] (`ref_cuervo`, −78; 6,4), al norte del patio, con su letrero de
  hierro con un cuervo [C] saliendo de la fachada sobre la puerta y un porche con mesas; la posadera [C] a la puerta.
- **Plaza de encuentro**: el Patio del Cuervo (≈ 540 m², bajo el tope de 600 del plan): fuente, árbol con banco, los
  barriles del favor de la posadera [C], una mesa de juegos al aire libre [P] (los juegos de taberna [C] siguen dentro) y
  el sitio LIBRE de la Feria de los Oficios [P] (`reserva_feria_patio`, −74; 22: nada sólido alrededor).
- **Niños**: el Corro de los Niños [P], un nivel más abajo (cota 2), con rayuela, árbol y un tronco de banco; se baja por
  una escalinata (33 %) entre un pretil y un muro de tierra con la tapa a la cota del patio.
- **Caballos**: el Corral de la Posada [P] (sin salida), con la cuadra, el abrevadero, dos caballos y el mozo.
- **Arranque de las Escaleras de las Terrazas**: el Pie de las Escaleras [P], ensanche con fuente y un arco sobre el
  arranque (borde z −5, cota 3).
- **Atajo**: el Callejón del Tonel [P], del Pie de las Escaleras a la Calle del Cuervo por detrás del patio, con el
  almacén de la posada [P] y un paso bajo casa: de la plaza a las Terrazas sin cruzar el patio.
- **Calle del Cuervo** [C]: baja de 3 a 2 hacia la plaza (5,6 %), con un soportal [P] (cuatro pilares que siguen la
  rampa y la planta encima), la tonelería [P] con su puesto, un banco y la puerta de una casa al sur.
- **Bucles**: patio → boca → Callejón del Corro → corro → escalinata → patio; patio → Pie de las Escaleras → Callejón
  del Tonel → calle → boca.

| Qué atrae | Qué se descubre o se hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La taberna y su letrero que chirría [C]; el bullicio del patio; los niños del corro | Posada [C] (dormir, comer, rumores); juegos de taberna [C]; «Tres favores para el Cuervo» [C] (los barriles); el atajo a las Terrazas; los caballos del corral | La posadera [C] (`posadera`); parroquianos [C voces] (`parroquianos`); el tonelero [P]; el mozo de cuadra [P]; niños [P] | La taberna es el hogar de Kael [C] | Tras «Tres favores» [C], noche gratis; la Feria de los Oficios [P] se anuncia y se celebra en el sitio libre del patio; propuesta de maqueta [P]: los barriles del favor dejan su sitio libre cuando se cumple |

Puertas previstas (9): la taberna [C], la cuadra [P], la tonelería [P], el almacén de la posada [P] y 5 casas.
Anclas de vida: `posadera`, `parroquianos`, `barriles`, `mesa_juegos`, `fuente_patio`, `ninos_patio`, `ninos_corro`,
`caballo_1`, `caballo_2`, `mozo_cuadra`, `tonelero`, `fuente_escaleras`, y la reserva `reserva_feria_patio`.

## 4. Reglas del plan cumplidas y cómo

- **Contra el vacío**: ningún tramo de más de 12 m sin puerta, banco, puesto o vista (Callejón Alto: banco, dos puertas y
  la boca de Pip; Calle Baja: dos puertas, banco y el paso al huerto; Escalerilla: paso bajo casa, puerta, escalera;
  Pasaje de las Velas: una puerta a media bajada; Calle del Cuervo: soportal, tonelería, banco, casa).
- **Fachadas variadas**: casas de 2 a 20 m de frente y de 3,5 a 8,5 m de alto, con bases a la cota de cada calle.
- **Visibilidad** (la cámara al sur): lo que tapa al sur de lo andable está en `OCULTABLES` (19 + 10, los que pidió la
  prueba, más el segundo muro de la grieta); pasos y corredores son `cubierta`; árboles con tronco ≤ 0,55 m (finos) y
  copa. Las hojas de puerta de las fachadas que miran al NORTE no se dibujan (tapaban a Kael ante su puerta): esas
  puertas se ven por su rótulo «(en obras)». En la ciudad, 3 346 casillas de muestra de 11 490 aclaran algo.
- **Cámara**: sin `CAMARA_ZONAS` propias: no hacen falta (no hay corredores largos de norte a sur con fachadas al sur del
  foco); una zona aquí rozaría la del Paso Cubierto de la plaza (x −31..−12).

## 5. Nombres nuevos [P] (a las decisiones del plan §8)

Pasajes Viejos: Callejón de las Macetas, Callejón Alto, Plazuela del Pozo, Escalerilla de la Botica, Pasaje Bajo las
Casas, Plazuela del Arco, Calle Baja, Patio de los Vecinos, Bajada de los Vecinos, Escalera de las Macetas, Rincón del
Sol, Corral del Rincón, Huerto de la Muralla; el cestero y su taller, el huertano.
Patio del Cuervo: Corral de la Posada (cuadra), Pie de las Escaleras, Callejón del Tonel, almacén de la posada, Corro de
los Niños, Callejón del Corro, soportal y tonelería de la Calle del Cuervo; el tonelero, el mozo de cuadra.

## 6. Pendiente y peticiones

- **Al coordinador (`plano.gd`)**: el ancla global `ref_pasajes` está escrita a y 1,43 y el Patio de las Velas queda llano
  a 1,44 (la prueba admite 0,02): conviene escribir 1,44.
- **Con el agente A**: la Botica de Selene [C] está en la plaza junto al callejón de la Botica (x −14), no en la boca del
  Paso Cubierto; si se quiere «junto al Paso Cubierto» (plan §2), es su sector.
- **Ocultables**: 29 mallas aparte en estos dos sectores (cada una, una llamada de dibujo más cuando están montados). Sin
  medir (encargo); si el perfil bajo se pasa de llamadas, fundir casas contiguas del sur en menos bloques.
- **Recorrido con los controles normales** (1600×720 y 1280×720) por una persona: no hecho (solo pruebas sin ventana).
- Vida (vecinos en sus anclas, la grieta cerrada hasta el secreto de Pip, las velas), interiores y acabado: fases
  siguientes.
