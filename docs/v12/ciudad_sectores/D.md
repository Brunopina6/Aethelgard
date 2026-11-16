# Ciudad de Oakhaven, maqueta: agente D — Las Terrazas (4) y Barrio Alto de las Raíces (7) (16/11, EXPERIMENTAL [P])

Blockout recorrible a escala de los personajes, NO acabado. Archivo propio del agente D (rama `area-ciudad-d`). Plano y
reglas: `docs/v12/CIUDAD_OAKHAVEN_PLAN.md` (§2-§4); contrato y cómo trabaja un agente: `docs/v12/CIUDAD_OAKHAVEN.md`.
Solo se tocaron `aethelgard/zonas3d/ciudad/sectores/terrazas/trazado.gd` y `.../barrio_alto/trazado.gd` (los `sector.tscn`
siguen como los dejó M0: solo dicen su `id`). Marcas: **[C]** canon citado en el plan, **[P]** propuesta.

## 1. Medidas (de `prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Antes (M0, mínimo) | Ahora | Regla del plan §1 | Cotas | Puertas | Grafo local | Ocultables | Casillas que aclaran algo |
|---|---|---|---|---|---|---|---|---|
| 4 Las Terrazas | 1 796 m² | **1 398 m²** | 1 000-1 700 | 3 → 12 (cuatro terrazas: 6, 8, 10, 12) | 10 | 20 nodos | 12 casas | 30 % (lo esperable en terrazas: las casas de cada nivel quedan al sur de la calle de arriba) |
| 7 Barrio Alto | 2 226 m² | **1 597 m²** | 1 000-1 700 | 4 → 16 | 10 | 18 nodos | 4 casas/tronco + 2 pilares | 4 % |

- Ciudad entera tras estos dos sectores (los otros seis, como estaban en `4f67e4b`): 9 662 m².
- Visibilidad comprobada además cada 0,25 m en los dos sectores (guion de comprobación fuera del proyecto): **ningún
  bloque tapa a Kael sin aclararse y ningún suelo más alto queda al sur de él.**
- Sin saltos > 0,3 m; todas las rampas y escalones ≤ 33 % (el tramo más empinado: 1 m en 3 m).
- Conexiones intactas: Escaleras de las Terrazas (z −5, cota 3), su remate alto (x −30, cota 12), Calle del Árbol
  (z −15, cota 4) y Subida de la Colina (z −15, cota 10), llanas ≥ 1 m hacia dentro. Anclas globales que caen aquí, en
  su sitio y a su cota: `ref_terrazas` (−60, 12, −64), `reserva_piezas_patio` (−80, 10, −50), `ref_barrio_alto` (0, 16, −83).
- Sin `CAMARA_ZONAS`: el foco es Kael. Una zona «eje» en calles de 4-10 m de ancho haría saltar el foco junto a sus
  bordes (margen de 2,5 m; en la Calle del Árbol, ≈ 0,7 m por 0,25 m de Kael, calculado); no hacía falta.

## 2. Las Terrazas (sector 4)

El recorrido es el **atajo de la taberna al barrio alto** sin pasar por la plaza: sube en zigzag (centro, oeste, este,
centro) desde el Patio del Cuervo (cota 3) hasta el Barrio Alto (12).

| Pieza | Cota | Qué es |
|---|---|---|
| **Escalinata de las Glicinias** [P] | 3 → 6 | Dos tramos (30 %) y un rellano de 10 × 3 m con **pérgola de glicinias** (cubierta) y banco; jardineras con glicinias a los lados. El punto de referencia que se ve desde el Patio del Cuervo. |
| **Calle de las Casas** (T1) | 6 | La calle residencial del barrio (plan §4): cinco casas distintas al norte (anchos 7-9 m, alturas 4,5-7 m, una retranqueada), **la vivienda de Odila y Nela** [P] retranqueada tras un patio delantero con tapias, banco y rosal; **tendederos** con ropa; pretil al sur sobre los **huertos** en bancales; al este acaba en un mirador sobre la plaza. |
| **Atajo de la Hornacina** [P] | 6 → 8 | El atajo del barrio (plan §4): callejón de 4 m entre dos casas, dos tramos de escalones (33 %), rellano con **arco de paso** (cubierta) y la **hornacina** en la pared. |
| **Plazuela de los Juegos** [P] (T2) | 8 | El ensanche para orientarse (16 × 12 m con la calle): **fuente de las Terrazas** [P] con pilón y caño, glicinia, banco; sitio de **niños jugando**. Al norte, el muro de la terraza de arriba con su pretil (se ve la plazuela desde T3). |
| **Escalera del Este** [P] | 8 → 10 | Dos tramos y rellano entre una casa y la ladera. |
| **Calle del Patio** (T3) | 10 | Pasa **bajo la Casa Puente** [P] (paso bajo edificio: la planta de arriba cruza la calle, 2,8 m libres). |
| **Patio de la Pieza** [P] | 10 | **Callejón sin salida con razón**: patio de vecinos de 13 × 9 m cerrado por tres casas, con la peana donde aparecerá la **Pieza Huérfana** [P] (lugar reservado del plan §3, `reserva_piezas_patio`; el sistema no se implementa). |
| **Escalera del Lavadero** [P] | 10 → 12 | Dos tramos y rellano, entre la Casa Puente y otra casa. |
| **Terraza del Lavadero** [P] (T4) | 12 | El **lavadero cubierto** (pila, tejadillo sobre cuatro pilares finos, ropa tendida) en un ensanche de 12 × 6 m: la **referencia** del sector; casas altas al norte, huertos y muralla detrás; al este, el remate hacia el Barrio Alto. |

Puertas previstas (10): casa de Odila y Nela («Llamar a la casa de Odila»), Casa de las Glicinias, y ocho casas más (una
por tramo de calle, ninguna calle de más de 12 m sin puerta, banco o vista). Anclas con nombre para la vida:
`odila_costura`, `nela_juego`, `vecina_tendedero`, `banco_t1`, `mirador_t1`, `hornacina`, `ninos_juego_1/2`,
`fuente_terrazas`, `vecino_patio`, `lavandera_1/2`, `tendedero_lavadero`, `glicinias`, `banco_glicinias`.

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| Las glicinias de la escalinata, la ropa tendida, las vistas sobre el Patio del Cuervo y la plaza | Subir por el atajo hasta el Barrio Alto; la casa de Odila y Nela (la del barrio, plan §4); la hornacina con velas; la plazuela con la fuente; el Patio de la Pieza (sitio de una **Pieza Huérfana** [P]); el lavadero | Odila y Nela [P, del barrio], vecinas en el lavadero y en los tendederos, niños en la plazuela y en la calle [C mundo vivo, sitios P], un vecino en el patio | Barrio de vecinos sin canon propio: todo [P] | Ropa tendida y vecinos según la hora [C franjas]; la Pieza Huérfana devuelta aparece en su peana [P, sin implementar] |

## 3. Barrio Alto de las Raíces (sector 7)

| Pieza | Cota | Qué es |
|---|---|---|
| **Calle del Árbol** [P] | 4 → 12 | El eje visual de la ciudad: tres tramos de escalinata (33 %), 10 m de ancho, y dos rellanos. En el primero (16 m de ancho), dos casas con su puerta y dos cipreses; en el segundo sale el paseo del Concejo. A los lados, casas y jardines escalonados con la escalinata. |
| **Paseo del Concejo** [P] | 10 | 4 m de ancho, pretil al sur sobre los jardines; al norte, casas con puerta y la **Casa del Concejo** [C] (22 × 18 m, 9 m de alto) con su **atrio** (banco, dos cipreses). Dentro está el tapiz [C]: la maqueta no enseña nada más. |
| **Mirador del Concejo** [P] | 10 | El fin del paseo: **sin salida, con la vista del valle** (plan §2), pretil y banco. |
| **Borde con la Subida de la Colina** [C] | 10 | 25 m llanos hasta el borde con los Oficios (z −15): una casa con puerta, banco y ciprés. La Colina y la puerta SELLADA del crematorio son del sector 3; aquí no se construye nada debajo. |
| **Plaza del Árbol** [P] | 12 | 32 × 13 m: dos parterres con cipreses (los **jardines**), bancos, casas con puerta al este y al norte; al oeste, el **paso de las Terrazas** con su seto (la llegada del atajo). |
| **Rampa de las Raíces** | 12 → 16 | Dos tramos (33 %) y un rellano, entre jardineras. |
| **Pórtico de piedra entre las raíces** [P] | 16 | Dos pilares y dintel sobre la llegada a la terraza. Sustituye al templo de vidrieras de la imagen, que **NO se hace**; sin función narrativa. |
| **Terraza de las Raíces** | 16 | El **Árbol Milenario** [C] (tronco 9 × 6 m y 18 m de alto, copa a 30-50 m que se ve desde toda la ciudad): se **anda alrededor** entre cuatro raíces bajas, por los dos lados y por detrás, donde se pasa **bajo una raíz en arco**. **Doña Encina** [C según el plan], guarda del Árbol, junto al pórtico, con un banco. Al oeste, el **Mirador de las Raíces** [P] (sin salida, con banco: la vista de la ciudad). |

Puertas previstas (10): la Casa del Concejo y nueve casas. Anclas con nombre: `encina`, `mirador_raices`, `tras_arbol`,
`mirador_concejo`, `atrio_concejo`, `vecino_paseo`, `vecina_plaza`, `ninos_plaza`, `banco_bajada`. El arcón del Concejo
[C enc_arcon] queda dentro del Concejo (interior aún sin hacer).

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| El Árbol gigante (desde toda la ciudad), la escalinata, las vistas | Rodear el Árbol entre sus raíces; hablar con Doña Encina; el Concejo [C] y su tapiz [C] (no se revela más); los dos miradores (valle y ciudad); los jardines | Doña Encina [C según el plan], miembros del Concejo [P], vecinos regando y niños en la plaza [sitios P] | El tapiz recortado [C], el Árbol Milenario [C] | Los miradores se marcan en el Diario al recorrerlos [C sistema de vistas, sin conectar en la maqueta] |

## 4. Nombres nuevos [P] (se suman a las decisiones del plan §8)

Escalinata de las Glicinias, Calle de las Casas, Atajo de la Hornacina, Plazuela de los Juegos, fuente de las Terrazas,
Escalera del Este, Calle del Patio, Casa Puente, Patio de la Pieza, Escalera del Lavadero, Terraza del Lavadero, Casa de
las Glicinias; Plaza del Árbol, Rampa de las Raíces, Terraza de las Raíces, paseo y atrio del Concejo, Mirador del
Concejo, Mirador de las Raíces, paso de las Terrazas. (De M0: Calle del Árbol, Escaleras de las Terrazas.)

## 5. Para el coordinador

- **Cambios compartidos pedidos** (no hechos):
  1. `trazado_comun.gd`, `FINO := 0.6`: los `Rect2` guardan `float` de 32 bits y un tamaño de 0,6 queda en 0,6000000238,
     así que un pilar de 0,6 × 0,6 NO cuenta como fino (me pasó con dos cipreses; los dejé en 0,5). Proponer
     `FINO := 0.6 + 0.001` o decirlo en el comentario.
  2. Canon: el plan marca a **Doña Encina** como [C], pero `estudio/canon.md:171` dice que Encina no es canon aprobado. En
     la maqueta solo es un ancla con su nombre; conviene decidir la marca.
- Observado: `prueba_ciudad_cargador` termina sin fallos pero su `.err.log` dice «4 resources still in use at exit»; no
  comprobé si ya pasaba antes de estos cambios.
- La superficie total de la ciudad baja a 9 662 m² (plan: ≈ 10 500-11 500) porque estos dos sectores bajan a la regla de
  1 000-1 700 m² cada uno; el resto depende de los otros agentes.

## 6. Pendiente

- Recorrer los dos sectores en el banco con clics y teclas a 1600×720 y 1280×720 (no hecho: sin ventana en esta pasada).
- Vecinos, niños y lavanderas en sus anclas (fase de vida); la Pieza Huérfana, el sistema de vistas en los miradores y
  los interiores (la vivienda de Odila y Nela del barrio, el Concejo con el tapiz y el arcón).
- Acabado con el kit de Blender (glicinias, ropa tendida, hornacina con velas, raíces, pórtico).
- Rendimiento: sin medir (el encargo no lo pide). Terrazas tiene 12 ocultables (una malla cada uno en la escena).
