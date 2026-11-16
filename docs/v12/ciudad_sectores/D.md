# Ciudad de Oakhaven, maqueta: agente D — Las Terrazas (4) y Barrio Alto de las Raíces (7) (16/11, EXPERIMENTAL [P])

Blockout recorrible a escala de los personajes, NO acabado. Archivo propio del agente D (ramas `area-ciudad-d` y, con los arreglos de la revisión, `area-ciudad-d-2`; §7). Plano y
reglas: `docs/v12/CIUDAD_OAKHAVEN_PLAN.md` (§2-§4); contrato y cómo trabaja un agente: `docs/v12/CIUDAD_OAKHAVEN.md`.
Solo se tocaron `aethelgard/zonas3d/ciudad/sectores/terrazas/trazado.gd` y `.../barrio_alto/trazado.gd` (los `sector.tscn`
siguen como los dejó M0: solo dicen su `id`). Marcas: **[C]** canon citado en el plan, **[P]** propuesta.

## 1. Medidas (de `prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Antes (M0, mínimo) | Ahora | Regla del plan §1 | Cotas | Puertas | Grafo local | Ocultables | Casillas que aclaran algo |
|---|---|---|---|---|---|---|---|---|
| 4 Las Terrazas | 1 796 m² | **1 435 m²** | 1 000-1 700 | 3 → 12 (cuatro terrazas: 6, 8, 10, 12) | 12 | 23 nodos | 12 casas | ≈ 29 % (lo esperable en terrazas: las casas de cada nivel quedan al sur de la calle de arriba) |
| 7 Barrio Alto | 2 226 m² | **1 603 m²** | 1 000-1 700 | 4 → 16 | 10 | 18 nodos | 4 casas/tronco + 2 pilares | 4 % |

- Ciudad entera tras estos dos sectores (los otros seis, como estaban en `4f67e4b`): 9 705 m² (tras los arreglos).
- Visibilidad comprobada además cada 0,25 m en los dos sectores (guion de comprobación fuera del proyecto): **ningún
  bloque tapa a Kael sin aclararse y ningún suelo más alto queda al sur de él.**
- Sin saltos > 0,3 m; todas las rampas y escalones ≤ 33 % (el tramo más empinado: 1 m en 3 m).
- Conexiones intactas: Escaleras de las Terrazas (z −5, cota 3), su remate alto (x −30, cota 12), Calle del Árbol
  (z −15, cota 4) y Subida de la Colina (z −15, cota 10), llanas ≥ 1 m hacia dentro. Anclas globales que caen aquí, en
  su sitio y a su cota: `ref_terrazas` (−60, 12, −64), `reserva_piezas_patio` (−80, 10, −50), `ref_barrio_alto` (0, 16, −83).
- Sin `CAMARA_ZONAS`: el foco es Kael. Una zona «eje» en calles de 4-10 m de ancho haría saltar el foco junto a sus
  bordes (margen de 2,5 m; en la Calle del Árbol, ≈ 0,7 m por 0,25 m de Kael, calculado); no hacía falta.

## 2. Las Terrazas (sector 4)

El recorrido es el **atajo de la taberna al barrio alto** sin pasar por la plaza, desde el Patio del Cuervo (cota 3) hasta
el Barrio Alto (12). La **subida directa** va por el este en una sola línea de escaleras (Glicinias → Escalera de los
Tendederos → Escalera del Este → Escalera del Lavadero): ≈ 85 m de grafo dentro del sector (antes, 158 m en zigzag), unos
135-140 m desde la taberna hasta la plaza del Árbol, menos que por la Calle del Cuervo y la plaza (≈ 155-170 m). El
**oeste** es el rodeo del barrio, con su razón: la casa de Odila y Nela, el Atajo de la Hornacina, la plazuela con la
fuente, el Patio de la Pieza y el lavadero.

| Pieza | Cota | Qué es |
|---|---|---|
| **Escalinata de las Glicinias** [P] | 3 → 6 | Dos tramos (30 %) y un rellano de 10 × 3 m con **pérgola de glicinias** (cubierta) y banco; jardineras con glicinias a los lados. El punto de referencia que se ve desde el Patio del Cuervo. |
| **Calle de las Casas** (T1) | 6 | La calle residencial del barrio (plan §4): seis casas distintas al norte (anchos 4-9 m, alturas 4,5-7 m, una retranqueada, una estrecha junto a la escalera), **la vivienda de Odila y Nela** [P] retranqueada tras un patio delantero cerrado por **tapias bajas** con 4 m de paso ante la puerta, banco y rosal; **tendederos** con ropa; pretil al sur sobre los **huertos en bancales** (1 m más bajos que la calle); al oeste acaba en la Casa del fondo (con puerta) y al este en un mirador que asoma 1,5 m sobre el terreno. |
| **Escalera de los Tendederos** [P] | 6 → 8 | La subida directa de T1 a T2 (x −49..−45), dos tramos (25 %) y rellano, entre la casa estrecha y la casa del este; sale enfrente de la Escalera del Este. |
| **Atajo de la Hornacina** [P] | 6 → 8 | El atajo del barrio (plan §4): callejón de 4 m entre dos casas, dos tramos de escalones (33 %), rellano con **arco de paso** (cubierta) y la **hornacina** en la pared. |
| **Plazuela de los Juegos** [P] (T2) | 8 | El ensanche para orientarse (16 × 12 m con la calle): **fuente de las Terrazas** [P] con pilón y caño, glicinia, banco; sitio de **niños jugando**. Al norte, el muro de la terraza de arriba con su pretil (se ve la plazuela desde T3). |
| **Escalera del Este** [P] | 8 → 10 | Dos tramos y rellano entre dos casas; parte de la subida directa. |
| **Calle del Patio** (T3) | 10 | Pasa **bajo la Casa Puente** [P] (paso bajo edificio: la planta de arriba cruza la calle, 2,8 m libres, y apoya al sur en dos pilares sobre la línea del pretil). Pretil en sus 16 m de borde sobre la plazuela. |
| **Patio de la Pieza** [P] | 10 | **Callejón sin salida con razón**: patio de vecinos de 13 × 9 m cerrado por tres casas, con la peana donde aparecerá la **Pieza Huérfana** [P] contra su pared sur, justo detrás del ancla global `reserva_piezas_patio` (−80, 10, −50) (lugar reservado del plan §3; el sistema no se implementa). |
| **Escalera del Lavadero** [P] | 10 → 12 | Dos tramos y rellano (x −48..−44), en línea con la del Este. |
| **Terraza del Lavadero** [P] (T4) | 12 | El **lavadero cubierto** (pila, tejadillo sobre cuatro pilares finos, ropa tendida, 2 m de paso por detrás) en un ensanche de 12 × 6 m: la **referencia** del sector, marcada desde lejos por el **Palomar del Lavadero** [P] (torre de 2 × 2 m, techo 21, por encima de todos los tejados; la Casa Puente baja a techo 14 para no taparlo); casas altas al norte, huertos y muralla detrás; al este, pretil sobre el relleno y el remate hacia el Barrio Alto. |

Puertas previstas (12): casa de Odila y Nela («Llamar a la casa de Odila»), Casa de las Glicinias, casa estrecha, Casa
del fondo y ocho casas más (una por tramo de calle, ninguna calle de más de 12 m sin puerta, banco o vista). Anclas con nombre para la vida:
`odila_costura`, `nela_juego`, `vecina_tendedero`, `banco_t1`, `mirador_t1`, `hornacina`, `ninos_juego_1/2`,
`fuente_terrazas`, `vecino_patio`, `lavandera_1/2`, `tendedero_lavadero`, `glicinias`, `banco_glicinias`.

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| Las glicinias de la escalinata, el palomar del lavadero, la ropa tendida, las vistas sobre el Patio del Cuervo y la plaza | Subir por el atajo directo hasta el Barrio Alto, o dar el rodeo del oeste; la casa de Odila y Nela (la del barrio, plan §4); la hornacina con velas; la plazuela con la fuente; el Patio de la Pieza (sitio de una **Pieza Huérfana** [P]); el lavadero | Odila y Nela [P, del barrio], vecinas en el lavadero y en los tendederos, niños en la plazuela y en la calle [C mundo vivo, sitios P], un vecino en el patio | Barrio de vecinos sin canon propio: todo [P] | Ropa tendida y vecinos según la hora [C franjas]; la Pieza Huérfana devuelta aparece en su peana [P, sin implementar] |

## 3. Barrio Alto de las Raíces (sector 7)

| Pieza | Cota | Qué es |
|---|---|---|
| **Calle del Árbol** [P] | 4 → 12 | El eje visual de la ciudad: tres tramos de escalinata (33 %), 10 m de ancho, y dos rellanos. En el primero (16 m de ancho), dos casas con su puerta y dos cipreses; en el segundo sale el paseo del Concejo. A los lados, casas y jardines escalonados con la escalinata y una **balaustrada** sobre el terreno junto al tramo 2, el rellano 2 y el tramo 3. |
| **Paseo del Concejo** [P] | 10 | 4 m de ancho, pretil al sur sobre los jardines; al norte, casas con puerta y la **Casa del Concejo** [C] (22 × 18 m, 9 m de alto) con su **atrio** (banco, dos cipreses). Dentro está el tapiz [C]: la maqueta no enseña nada más. |
| **Mirador del Concejo** [P] | 10 | El fin del paseo: **sin salida, con la vista del valle** (plan §2), pretil y banco. |
| **Borde con la Subida de la Colina** [C] | 10 | 25 m llanos hasta el borde con los Oficios (z −15): una casa con puerta, banco y ciprés; al oeste, pretil y muro de contención sobre los jardines. La Colina y la puerta SELLADA del crematorio son del sector 3; aquí no se construye nada debajo. |
| **Plaza del Árbol** [P] | 12 | 32 × 13 m: dos parterres con cipreses (los **jardines**) y un banco en la cara sur de cada uno, casas con puerta al este y al norte; setos al oeste y pretiles al sur sobre los jardines bajos; al oeste, el **paso de las Terrazas** con su seto (la llegada del atajo). |
| **Rampa de las Raíces** | 12 → 16 | Dos tramos (33 %) y un rellano, entre jardineras. |
| **Pórtico de piedra entre las raíces** [P] | 16 | Dos pilares y dintel sobre la llegada a la terraza. Sustituye al templo de vidrieras de la imagen, que **NO se hace**; sin función narrativa. |
| **Terraza de las Raíces** | 16 | El **Árbol Milenario** [C] (tronco 9 × 6 m y 18 m de alto, copa a 30-50 m que se ve desde toda la ciudad): se **anda alrededor** entre cuatro raíces bajas, por los dos lados y por detrás, donde se pasa **bajo una raíz en arco**. **Doña Encina** [C pendiente], guarda del Árbol, junto al pórtico, con un banco contra el pretil. Al oeste, el **Mirador de las Raíces** [P] (sin salida, con banco: asoma 2 m sobre el terreno de poniente, con pretil, hacia la terraza alta de las Terrazas y la plaza). Al este, la meseta de levante con casas, huertos y el jardín de detrás del Concejo [P] (no andable). |

Puertas previstas (10): la Casa del Concejo y nueve casas. Anclas con nombre: `encina`, `mirador_raices`, `tras_arbol`,
`mirador_concejo`, `atrio_concejo`, `vecino_paseo`, `vecina_plaza`, `ninos_plaza`, `banco_bajada`. El arcón del Concejo
[C enc_arcon] queda dentro del Concejo (interior aún sin hacer).

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| El Árbol gigante (desde toda la ciudad), la escalinata, las vistas | Rodear el Árbol entre sus raíces; hablar con Doña Encina; el Concejo [C] y su tapiz [C] (no se revela más); los dos miradores (valle y ciudad); los jardines | Doña Encina [C pendiente], miembros del Concejo [P], vecinos regando y niños en la plaza [sitios P] | El tapiz recortado [C], el Árbol Milenario [C] | Los miradores se marcan en el Diario al recorrerlos [C sistema de vistas, sin conectar en la maqueta] |

## 4. Nombres nuevos [P] (se suman a las decisiones del plan §8)

Escalinata de las Glicinias, Calle de las Casas, Escalera de los Tendederos, Palomar del Lavadero, Atajo de la Hornacina, Plazuela de los Juegos, fuente de las Terrazas,
Escalera del Este, Calle del Patio, Casa Puente, Patio de la Pieza, Escalera del Lavadero, Terraza del Lavadero, Casa de
las Glicinias; Plaza del Árbol, Rampa de las Raíces, Terraza de las Raíces, paseo y atrio del Concejo, Mirador del
Concejo, Mirador de las Raíces, paso de las Terrazas. (De M0: Calle del Árbol, Escaleras de las Terrazas.)

## 5. Para el coordinador

- **Cambios compartidos pedidos** (no hechos):
  1. `trazado_comun.gd`, `FINO := 0.6`: los `Rect2` guardan `float` de 32 bits y un tamaño de 0,6 queda en 0,6000000238,
     así que un pilar de 0,6 × 0,6 NO cuenta como fino (me pasó con dos cipreses; los dejé en 0,5). Proponer
     `FINO := 0.6 + 0.001` o decirlo en el comentario.
  2. Canon: el plan marca a **Doña Encina** como [C], pero `estudio/canon.md:171` dice que Encina no es canon aprobado. En
     la maqueta solo es un ancla con su nombre y ya va como [C pendiente] (la marca del plan para Ferro e Hilda);
     conviene decidir la marca en el plan.
- Observado: `prueba_ciudad_cargador` termina sin fallos pero su `.err.log` dice «4 resources still in use at exit»; no
  comprobé si ya pasaba antes de estos cambios.
- La superficie total de la ciudad baja a 9 705 m² (plan: ≈ 10 500-11 500) porque estos dos sectores bajan a la regla de
  1 000-1 700 m² cada uno; el resto depende de los otros agentes.

## 6. Pendiente

- Recorrer los dos sectores en el banco con clics y teclas a 1600×720 y 1280×720 (no hecho: sin ventana en esta pasada).
- Vecinos, niños y lavanderas en sus anclas (fase de vida); la Pieza Huérfana, el sistema de vistas en los miradores y
  los interiores (la vivienda de Odila y Nela del barrio, el Concejo con el tapiz y el arcón).
- Acabado con el kit de Blender (glicinias, ropa tendida, hornacina con velas, raíces, pórtico).
- Rendimiento: sin medir (el encargo no lo pide). Terrazas tiene 12 ocultables (una malla cada uno en la escena).
- Medir con la escena los anchos de paso que la prueba no mira (Kael tiene cápsula): los arreglos de §7 dejan los pasos
  señalados por la revisión en ≥ 1,6 m, pero no hay una comprobación automática de holgura.

## 7. Arreglos tras la revisión (rama `area-ciudad-d-2`, 16/11)

Dos revisiones de `area-ciudad-d` (solo lectura). Cada hallazgo se comprobó con el trazado antes de tocarlo; todos se
sostenían. `prueba_ciudad_plano` y `prueba_ciudad_cargador` siguen sin fallos.

| Hallazgo (gravedad) | Comprobado | Arreglo |
|---|---|---|
| El atajo de las Terrazas es un rodeo: 158 m de grafo en zigzag (alta) | Sí: 158 m medidos por el grafo | **Escalera de los Tendederos** [P] de T1 a T2 (x −49..−45; casa_t1_e1 pasa a casa estrecha de 4 m, con puerta) y Escalera del Lavadero movida a x −48..−44 (casa_t3_e a x −56..−48). Subida directa: ≈ 85 m. Grafo con `n_t1_esc`, `n_escalera_t1`, `n_t4_esc`. |
| El lavadero (la referencia) no se ve desde fuera de T4 (media) | Sí: Casa Puente a techo 16,5 delante del tejadillo (15,2) | Casa Puente a techo 14 (paso, 2,8 m libres) y **Palomar del Lavadero** [P] de techo 21 dentro de la casa de detrás. |
| T3 acaba en 8 m sin pretil sobre la plazuela (media) | Sí | `pretil_plazuela` en los 16 m del borde. |
| La Casa Puente vuela sin apoyo al sur (media/baja) | Sí | Dos pilares finos (0,5 m) en la línea del pretil bajo el borde del paso. |
| La peana de la Pieza está a 7 m del ancla global (media) | Sí | Peana contra la pared sur del patio, justo detrás de `reserva_piezas_patio` (−80, 10, −50); `vecino_patio` apartado. No hace falta tocar `plano.gd`. |
| Bancales de T1 a la cota de la calle; el mirador de T1 sin caída (media) | Sí: techo 6 = cota de T1 | Bancales a 5,0; fin de T1 a 4,5; huerto del fin de T2 desde 4,5. |
| Paredes invisibles en el sur de T4 y de T2 (media) | Sí | `pretil_t4_e` sobre el relleno (base 11,5, 0,9 sobre T4; no sobre el suelo, porque el pretil en z −60,4 cortaba el llano del borde `terrazas_altas`); la franja de T2 pasa a jardinera de 0,8 m. |
| La Calle del Árbol sin balaustrada (media) | Sí | Balaustradas sobre el terreno junto al tramo 2, el rellano 2 y el tramo 3. Junto al tramo 1 no: allí los lados son las dos casas. |
| La Plaza del Árbol rodeada de bordes a ras (media) | Sí: unos 31 m | Seto del paso alargado hasta x −30 sobre el jardín (en la calle habría cortado el borde con las Terrazas), seto al oeste y pretiles al sur, todo sobre el terreno. |
| El paso hacia la Colina sin pretil al oeste; el atrio a ras (media) | Sí | Pretil a la cota 10 y muro de contención donde el terreno baja (jardines a 8,5, ladera a 7); pretiles a los dos lados del atrio. |
| El Mirador de las Raíces sin borde ni vista (media) | Sí | Poniente a 14, casa_paso_n a techo 16 y pretil-muro en todo el borde oeste de la terraza (z −92..−79), no solo en el mirador. |
| Paso de 1,5 m tras el lavadero (media) | Sí | Pila a 2 m del fondo, pilares contra la casa, `lavandera_2` movida. |
| Pasos de 1,0-1,5 m ante el Árbol (media) | Sí | Raíces delanteras más cortas (2,1 m al tronco) y banco de Encina contra el pretil (2,3 m). |
| Hueco de 99 m² sin bloque tras T4 (baja) | Sí | Huertos y un relleno (techo 13,5). |
| Meseta vacía de 1 100 m² al este del Árbol (baja) | Sí | Tres casas, huerto y el jardín de detrás del Concejo [P] (no andables); pretiles donde la terraza queda a ras. |
| Fondo de saco oeste de T1 sin razón (baja) | Sí | Puerta en la Casa del fondo. |
| Patio de Odila abierto a la calle (baja) | Sí | Tapias bajas al frente con 4 m de paso; las de los lados pasan a medianeras. |
| Bancos de la plaza en franjas de 2 m (baja) | Sí | En la cara sur de cada parterre. |
| Copas de glicinia a 1 m sobre lo andable; hornacina fuera de la pared (baja) | Sí | Copas ceñidas a las jardineras; hornacina dentro de la pared. |
| Mobiliario a menos de 0,6 m de su borde (baja) | Sí | Cada pieza pegada a su borde (la peana, con su cambio de sitio). |
| Doña Encina marcada [C según el plan] (baja, canon) | Sí: `estudio/canon.md:171` | [C pendiente] en el trazado y en este documento. |

Superficies tras los arreglos (`prueba_ciudad_plano`, rejilla de 0,25 m): **Las Terrazas 1 435 m²**, **Barrio Alto
1 603 m²**; ciudad, 9 705 m².
