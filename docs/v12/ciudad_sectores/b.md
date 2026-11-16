# Ciudad de Oakhaven, maqueta: sectores del agente B (16/11, EXPERIMENTAL [P])

Calle de los Oficios (sector 3, `oficios`) y La Ribera Baja (sector 8, `ribera`). Es un blockout recorrible a la escala
de los personajes, no el acabado. Los trazados están en `aethelgard/zonas3d/ciudad/sectores/{oficios,ribera}/trazado.gd`
y siguen el contrato de `docs/v12/CIUDAD_OAKHAVEN.md` §3. El plano y las tablas de partida están en
`docs/v12/CIUDAD_OAKHAVEN_PLAN.md` §2-§4. Marcas: **[C]** canon (con su fuente), **[P]** propuesta.

No se ha tocado nada compartido: ni `plano.gd`, ni `trazado_comun.gd`, ni el blockout, el cargador, la escena o las
pruebas. Los bordes acordados son los de M0, sin cambios:

| Conexión | Lado B | Cota | Cómo llega |
|---|---|---|---|
| Calle del Mercado (x 45, z 20..26) | oficios | 3 | Remate llano de 5 m y después la Calle de los Oficios |
| Subida de la Colina (z −15, x 50..54) | oficios | 10 | Llegada llana de 5 m, unida al Paseo de la Colina y a la Escalerilla |
| Escalera del Molino (z 55, x 60..63) | oficios ↔ ribera | 3 | Remate de la Bajada al Molino (oficios); arriba de la escalera (ribera) |
| Rampa de los Carros (x 45, z 76..82) | ribera | 0 | Entrada llana de 5 m y después la rampa al 20 % |

## 1. Medidas (de `prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Andable | Objetivo | Desnivel | Puertas previstas | Grafo local |
|---|---|---|---|---|---|
| Calle de los Oficios | **1 603 m²** (M0: 1 017) | 1 000-1 700 | 3 → 10 | 7 | 21 nodos |
| La Ribera Baja | **1 080 m²** (M0: 935) | 1 000-1 700 | −2 → 3 | 7 | 18 nodos |

Desglose por lugar, contando lo que se pisa y descontando lo sólido:

| Oficios | m² | Ribera | m² |
|---|---|---|---|
| Calle de los Oficios con su remate, el Ensanche de la Forja, el Callejón del Carbón y el soportal | 386 | Entrada y Rampa de los Carros | 90 |
| Bajada al Molino y Placeta de la Fuente | 163 | Escalera del Molino, placeta del molino y Puente de los Carros | 95 |
| Paso del Fuelle, Calle del Horno y bajada del patio | 334 | Patio de los almacenes, con el lavadero | 546 |
| Patio de los Talleres | 331 | Andén de carga y su rampa | 70 |
| Subida del patio, Paseo de la Colina y llegada al Barrio Alto | 280 | La ronda: pie, escalera, Mirador de la Ronda y adarve | 168 |
| Escalerilla de la Colina con su mirador | 109 | Callejón de los Fardos | 41 |
| | | Senda, pasarela y Rincón de la Acequia | 71 |

Visibilidad de Kael: `prueba_ciudad_plano` lo comprueba cada metro y una comprobación aparte, solo de estos dos
sectores, lo comprueba en las **42 930 casillas de 0,25 m**. No hay ningún bloque sin aclarar ni ningún suelo que tape. En
14 252 de esas casillas la escena aclara algo: las cubiertas (soportal, Paso del Fuelle, lavadero), la copa del patio y
las casas del lado sur de las calles. El mayor salto entre casillas vecinas es de 0,20 m, en la unión del soportal con el
Paso del Fuelle.

## 2. Calle de los Oficios (sector 3)

Hay tres calles escalonadas que suben hacia el norte, con lo alto siempre al norte de cada calle, que es lo que pide la
cámara:

- **Calle de los Oficios [C]**, de x 45 a 90, en rampa del 10 % entre las cotas 3 y 7. Al norte están el taller de
  **Hilda la Armera [C]** con su **puesto** a la entrada de la calle [C: `ciudades/oakhaven.gd`, «puesto de armaduras, a
  la entrada de la Calle del Mercado»], el **Callejón del Carbón** [P] y la **forja de Maese Ferro [C]**. La forja está
  retranqueada tras el **Ensanche de la Forja** [P], con el **yunque** [C: «Herrería, junto al yunque»], la pila de
  temple y el poste de los caballos. Siguen dos casas de alturas distintas (8 y 6 m). Al sur hay un **soportal** [P] de
  24 m con siete pilares y la planta encima.
- **Paso del Fuelle** [P]: un paso bajo las casas, en pendiente del 10 %, que lleva del soportal a la calle de abajo.
- **Calle del Horno** [P], de 3,1 a 5, con el **horno de Maela** [P, del barrio] y dos casas con la fachada al sur. Al
  sur tiene un **pretil con la vista de la Ribera Baja**: la torre, la acequia y los almacenes. Es la calle comercial del
  barrio que se reparte aquí (plan §4).
- **Patio de los Talleres** [P, el patio del barrio] al final de la calle, a cota 7: el **taller del carretero Damián**
  [P, del barrio; bajo, de 3,6 m, como en el barrio], su carro, el abrevadero, la leña y un árbol. Queda al este de
  Ferro y de Hilda y no añade una tercera forja (plan §4).
- **Bajada al Molino** (M0) y **Placeta de la Fuente** [P]: una fuente con pilón, el sitio de los niños y un pretil
  sobre la ribera. Por la bajada se baja a la Escalera del Molino.
- **Escalerilla de la Colina** [P]: atajo de la entrada de la calle al Paseo de la Colina y al Barrio Alto, sin pasar por
  el patio. Son dos tramos, del 19 % y del 40 %, con un rellano que tiene banco y hornacina, y un mirador arriba.
- **Paseo de la Colina** [P] al pie de la **Colina del Crematorio [C]**, con un pretil, dos bancos y el sitio de **Albar**
  [C: «Junto al crematorio»]. **La colina no es andable, la puerta del crematorio sigue SELLADA** (no tiene entrada
  prevista) **y no se construye nada debajo ni dentro.** El crematorio solo se ve por fuera.

Funciones pedidas, una a una:

- **Punto de referencia.** La forja con su chimenea, ante la que está el ancla global `ref_oficios`.
- **Plaza o ensanche para orientarse.** El Patio de los Talleres al este y el Ensanche de la Forja en el centro.
- **Escaleras y rampas.** La Escalerilla (19 % y 40 %), las rampas de las tres calles, el Paso del Fuelle y la bajada
  del patio (12 %).
- **Distintas alturas separadas.** Tres calles a 3-7, 3,1-5 y 8,5-10, separadas por casas, por la ladera (`terreno`) y
  por pretiles.
- **Corredores cubiertos y paso bajo edificios.** El soportal y el Paso del Fuelle.
- **Callejón sin salida con razón.** El Callejón del Carbón, que lleva a la carbonera de la forja, donde trabaja el
  aprendiz [C mundo vivo].
- **Atajos entre lugares reconocibles.** La Escalerilla (Calle del Mercado → Paseo de la Colina → Barrio Alto) y el Paso
  del Fuelle (forja → horno).
- **Vida, con anclas.** `ferro`, `hilda_puesto`, `aprendiz_carbon`, `caballo_forja`, `damian`, `caballo_carro`,
  `maela`, `vecina_soportal`, `ninos_placeta`, `fuente_placeta`, `albar` y `vista_ribera`.
- **Puertas previstas.** Forja, taller de Hilda, taller del carretero, horno y tres casas (soportal, placeta y bajada).

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| El ruido y la chimenea de la forja, el puesto de armaduras, el olor del horno | Los encargos de Ferro [C pendiente: `enc_herrero`] y de Hilda; el taller de Damián [P]; el horno de Maela [P]; la vista de la ribera desde el pretil; el atajo de la Escalerilla; el crematorio sellado, solo por fuera | Ferro [C], Hilda [C], el aprendiz de la forja [C mundo vivo], Damián y Maela [P, del barrio], vecinos, Albar [C] en el paseo | «El pedido de Maese Ferro» [C]; la puerta que «no se abre» [C: Albar]. Nada nuevo sobre el crematorio | Las **Piezas Huérfanas** [P] se reconstruyen en el taller de Hilda (reserva `reserva_piezas_taller`, ante su puerta). El carro de Damián, reparado, sale cargado del patio [P, plan §3] |

## 3. La Ribera Baja (sector 8)

Es lo más bajo de la ciudad, a cota −2, junto a la muralla este y la sur:

- **Rampa de los Carros** [P, M0]: baja de las caravanas (0) a los almacenes (−2) entre dos casas y el almacén de la
  puerta.
- **Escalera del Molino** [P, M0]: dos tramos al 40 % con un rellano ante la **rueda del molino**, en la **acequia**
  [P]. Abajo están la placeta del molino y el **Puente de los Carros** [P] sobre la acequia.
- **Patio de los almacenes** [P]. Tiene el **lavadero** [P], cubierto, con su pila junto a la acequia; el **andén de
  carga** [P] a −1, ante el almacén grande, con su rampa y una polea; el **cuerpo de faroles** [P, el edificio; Bastián
  y los faroles son C]; y, al este, el pie de la **Torre de la Campana [C]**, donde está el ancla `ref_ribera`.
- **La ronda en alto [C]**: una escalera al 40 % sube del patio (−2) al **Mirador de la Ronda** [P] y al **adarve**
  sobre la muralla del este, a cota 3. Allí están los **tres faroles de la ronda** [C: `oak_faroles`, «Enciende el
  primer farol de la ronda…»] y la **puerta de la torre**, «Subir a la torre» [C: «Sube a la Torre de la Campana»; el
  interior aún no existe].
- **Callejón de los Fardos** [P]: sin salida, al fondo del almacén, con fardos y lonas rasgadas. Es la reserva de
  **Rastreadores** [P], con el ancla global `reserva_rastreadores_almacen`.
- **Senda de la Acequia, pasarela y Rincón de la Acequia** [P]: un bucle corto junto al agua, donde los niños echan
  barquitos. La acequia sale bajo la muralla sur por una **reja**, y eso **no es una salida**: solo la Puerta del Sur
  sale al mapa.

Funciones pedidas, una a una:

- **Punto de referencia.** La torre, de 22 m, con su campanario.
- **Ensanche para orientarse.** El patio, de unos 550 m².
- **Escaleras y rampas.** La Rampa de los Carros (20 %), la Escalera del Molino (40 %), la escalera de la ronda (40 %) y
  la rampa del andén (33 %).
- **Distintas alturas separadas.** Tres niveles: −2, −1 (el andén) y 3 (la ronda). Entre ellos hay franjas de 0,5 m
  sin suelo, con su muro o pretil.
- **Corredor cubierto.** El lavadero.
- **Callejón sin salida con razón.** El Callejón de los Fardos: la pista de los Rastreadores.
- **Atajos.** La Escalera del Molino (Calle del Horno → patio) y el bucle de la acequia.
- **Vida, con anclas.** `bastian`, `farol_1`, `farol_2`, `farol_3`, `mirador`, `lavanderas`, `molinero`,
  `mozos_anden`, `caballo_carro`, `ninos_acequia` y `rueda_molino`.
- **Puertas previstas.** Almacén grande, molino, cuerpo de faroles, torre, almacén del sur, almacén del fondo y una casa
  de la rampa.

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La torre, el agua y la rueda, el trabajo pesado del andén | Subir a la ronda y a la torre; encender los tres faroles [C: `oak_faroles`]; la vista desde el Mirador de la Ronda; el lavadero; el fondo del almacén con la pista de **Rastreadores** [P] | Bastián [C], guardias [C mundo vivo], mozos de almacén, lavanderas y el molinero [P] | La Torre de la Campana y la ronda [C]; «faltan tres, en la muralla del este» [C] | Tras `oak_faroles` [C], los tres faroles de la ronda encendidos («la muralla se ilumina»); tras Rastreadores [P], los almacenes se llenan y el callejón se despeja |

## 4. Nombres nuevos [P] de B (se suman a las decisiones del plan §8)

- **Oficios:** Ensanche de la Forja, Callejón del Carbón, Paso del Fuelle, Calle del Horno, Patio de los Talleres (el
  nombre del barrio), Placeta de la Fuente, Escalerilla de la Colina y Paseo de la Colina.
- **Ribera:** Puente de los Carros, andén de carga, lavadero, cuerpo de faroles (el edificio), Mirador de la Ronda,
  Callejón de los Fardos, Senda de la Acequia y Rincón de la Acequia.

Son lugares, no personajes: no se ha inventado a nadie. Los vecinos sin nombre (mozos, lavanderas, molinero) son
anclas de vida. Fuera del encargo no hay nada nuevo de historia: ni sobre la niebla, ni el Sello, ni el crematorio por
dentro.

## 5. Pendiente

- **Recorrido con los controles normales** a 1600×720 y 1280×720 (contrato §4, paso 4). No está hecho: no hay ventana
  en esta sesión. Solo pasan las pruebas sin ventana.
- **Ronda de la Ribera.** El adarve está a cota 3, el máximo de la caja de la Ribera en `plano.gd`, unos 5 m sobre el
  patio, y la muralla queda como pretil de 1,3 m. Si se quiere más alta, hay que subir la cota máxima del sector, que es
  un cambio compartido.
- **Agua.** La acequia y la rueda son bloques `decor` del color ocre del blockout, y la rueda no gira.
- **Pendiente de otras fases.** Los interiores (forja, talleres, horno, molino, torre…), los vecinos, los sistemas
  reservados (Piezas Huérfanas, Rastreadores) y el acabado con el kit.
