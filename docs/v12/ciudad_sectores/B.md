# Ciudad de Oakhaven, maqueta: sectores del agente B (16/11, EXPERIMENTAL [P])

Calle de los Oficios (sector 3, `oficios`) y La Ribera Baja (sector 8, `ribera`). Es un blockout recorrible a la escala
de los personajes, no el acabado. Los trazados están en `aethelgard/zonas3d/ciudad/sectores/{oficios,ribera}/trazado.gd`
y siguen el contrato de `docs/v12/CIUDAD_OAKHAVEN.md` §3. El plano y las tablas de partida están en
`docs/v12/CIUDAD_OAKHAVEN_PLAN.md` §2-§4. Marcas: **[C]** canon (con su fuente), **[P]** propuesta.

Este archivo se llamaba `b.md`; desde la rama `area-ciudad-b-2` es `B.md`, como `A.md`, `C.md` y `D.md`. La segunda
pasada (B-2, §6) arregla lo que encontraron las dos revisiones de `area-ciudad-b`.

No se ha tocado nada compartido: ni `plano.gd`, ni `trazado_comun.gd`, ni el blockout, el cargador, la escena o las
pruebas. Los bordes acordados son los de M0, sin cambios:

| Conexión | Lado B | Cota | Cómo llega |
|---|---|---|---|
| Calle del Mercado (x 45, z 20..26) | oficios | 3 | Remate llano de 5 m y después la Calle de los Oficios |
| Subida de la Colina (z −15, x 50..54) | oficios | 10 | Llegada llana de 5 m, unida al Paseo de la Colina y a la Escalerilla |
| Escalera del Molino (z 55, x 60..63) | oficios ↔ ribera | 3 | Remate de la Bajada al Molino (oficios); arriba de la escalera (ribera) |
| Rampa de los Carros (x 45, z 76..82) | ribera | 0 | Entrada llana de 1 m y después la rampa al 14 % |

## 1. Medidas (de `prueba_ciudad_plano`, rejilla de 0,25 m)

| Sector | Andable | Objetivo | Desnivel | Puertas previstas | Grafo local |
|---|---|---|---|---|---|
| Calle de los Oficios | **1 595 m²** (B-1: 1 603; M0: 1 017) | 1 000-1 700 | 3 → 10 | 12 | 21 nodos |
| La Ribera Baja | **1 092 m²** (B-1: 1 080; M0: 935) | 1 000-1 700 | −2 → 3 | 7 | 20 nodos |

Desglose por lugar, contando lo que se pisa y descontando lo sólido:

| Oficios | m² | Ribera | m² |
|---|---|---|---|
| Calle de los Oficios con su remate, el Ensanche de la Forja, el Callejón del Carbón y el soportal | 384 | Entrada y Rampa de los Carros | 90 |
| Bajada al Molino y Placeta de la Fuente | 163 | Escalera del Molino, placeta del molino y Puente de los Carros | 95 |
| Paso del Fuelle, Calle del Horno y bajada del patio | 333 | Patio de los almacenes, con el lavadero | 550 |
| Patio de los Talleres | 327 | Andén de carga y su rampa | 70 |
| Subida del patio, Paseo de la Colina y llegada al Barrio Alto | 280 | La torre por dentro, el Mirador de la Ronda y el adarve | 174 |
| Escalerilla de la Colina con su mirador | 109 | Callejón de los Fardos | 39 |
| | | Senda, pasarela y Rincón de la Acequia | 75 |

Comprobaciones aparte, solo de estos dos sectores y en **todas** las casillas de 0,25 m (no cada metro, como la
prueba): no hay ningún bloque sin aclarar ni ningún suelo que tape a Kael, y **ningún borde de lo andable da a un
hueco** sin suelo ni bloque (un foso hasta el fondo de la escena o una pared invisible). El mayor salto entre casillas
vecinas sigue siendo de 0,20 m, en la unión del soportal con el Paso del Fuelle.

## 2. Calle de los Oficios (sector 3)

Hay tres calles escalonadas que suben hacia el norte, con lo alto siempre al norte de cada calle, que es lo que pide la
cámara:

- **Calle de los Oficios [C]**, de x 45 a 90, en rampa del 10 % entre las cotas 3 y 7. Al norte están el taller de
  **Hilda la Armera [C]** con su **puesto** a la entrada de la calle [C: `ciudades/oakhaven.gd`, «puesto de armaduras, a
  la entrada de la Calle del Mercado»], el **Callejón del Carbón** [P] y la **forja de Maese Ferro [C]**. La forja está
  retranqueada tras el **Ensanche de la Forja** [P], con un tejadillo sobre la boca de la fragua, el **yunque** [C:
  «Herrería, junto al yunque»], la pila de temple y el poste de los caballos. Es la casa más alta de su fila (cima 11,7)
  y su chimenea llega a 16,7. Siguen dos casas más bajas. Al sur hay un **soportal** [P] de 24 m con siete pilares, la
  planta encima, tres puertas (una casa, el **talabartero** y el **cordelero** [P]) y un puesto bajo los arcos.
- **Paso del Fuelle** [P]: un paso bajo las casas, en pendiente del 10 %, que lleva del soportal a la calle de abajo.
  Al pie de la cubierta hay **fuelles viejos** y un vecino remendándolos (el nombre del paso), y a media bajada, la
  puerta lateral de un taller.
- **Calle del Horno** [P], de 3,1 a 5, con el **horno de Maela** [P, del barrio] y dos casas con la fachada al sur. Al
  sur tiene un **pretil** en tramos (siempre unos 0,9-1,3 m sobre la calle) donde se asoman los vecinos. **Desde aquí
  no se ve la Ribera**: la cámara mira al norte y la Ribera queda detrás de ella. Al revés sí: desde el patio de la
  Ribera se ve, al norte y arriba, el pretil con los vecinos y las fachadas de la calle. Es la calle comercial del
  barrio que se reparte aquí (plan §4).
- **Patio de los Talleres** [P, el patio del barrio] al final de la calle, a cota 7: el **taller del carretero
  Damián** [P, del barrio; bajo, de 3,6 m, como en el barrio] y el portón del **tonelero** [P], el carro, el abrevadero,
  la leña, un árbol con niños jugando alrededor, **ruedas apoyadas** en la muralla y un **tajo de leña**. Queda al este
  de Ferro y de Hilda y no añade una tercera forja (plan §4).
- **Bajada al Molino** (M0) y **Placeta de la Fuente** [P]: una fuente con pilón, el sitio de los niños y un pretil.
  Por la bajada se baja a la Escalera del Molino.
- **Escalerilla de la Colina** [P]: atajo de la entrada de la calle al Paseo de la Colina y al Barrio Alto, sin pasar por
  el patio. Son dos tramos, del 19 % y del 40 %, con un rellano que tiene banco y hornacina, la **puerta trasera del
  taller de Hilda** a media subida y un mirador arriba.
- **Paseo de la Colina** [P] al pie de la **Colina del Crematorio [C]**, con un pretil a cada lado, dos bancos, un
  **ciprés** con un vecino paseando y el sitio de **Albar** [C: «Junto al crematorio»]. **La colina no es andable, la
  puerta del crematorio sigue SELLADA** (no tiene entrada prevista) **y no se construye nada debajo ni dentro.** El
  crematorio solo se ve por fuera.

Funciones pedidas, una a una:

- **Punto de referencia.** La forja: la más alta de la fila, con su tejadillo y una chimenea que saca 5 m a todo, ante
  la que está el ancla global `ref_oficios`. Con Kael justo delante, la chimenea queda por encima del encuadre (cámara
  fija); se ve desde el soportal, el Paso del Fuelle y la Calle del Horno.
- **Plaza o ensanche para orientarse.** El Patio de los Talleres al este y el Ensanche de la Forja en el centro.
- **Escaleras y rampas.** La Escalerilla (19 % y 40 %), las rampas de las tres calles, el Paso del Fuelle y la bajada
  del patio (12 %).
- **Distintas alturas separadas.** Tres calles a 3-7, 3,1-5 y 8,5-10, separadas por casas, por la ladera (`terreno`) y
  por pretiles.
- **Corredores cubiertos y paso bajo edificios.** El soportal, el tejadillo de la forja y el Paso del Fuelle.
- **Callejón sin salida con razón.** El Callejón del Carbón, que lleva a la carbonera de la forja, donde trabaja el
  aprendiz [C mundo vivo].
- **Atajos entre lugares reconocibles.** La Escalerilla (Calle del Mercado → Paseo de la Colina → Barrio Alto, unos
  36 m frente a unos 125 m por el patio) y el Paso del Fuelle (forja → horno, unos 27 m frente a unos 60 m).
- **Ningún tramo de más de 12 m sin nada.** Los que lo eran (Paso del Fuelle, tramo bajo de la Escalerilla, mitad del
  Paseo de la Colina) tienen ahora puerta, fuelles, ciprés o banco.
- **Vida, con anclas.** `ferro`, `hilda_puesto`, `aprendiz_carbon`, `caballo_forja`, `damian`, `caballo_carro`,
  `maela`, `vecina_soportal`, `puesto_soportal`, `fuellero`, `vecino_ruedas`, `ninos_arbol`, `ninos_placeta`,
  `fuente_placeta`, `asomados_horno`, `vecino_paseo` y `albar`.
- **Puertas previstas (12).** Forja, taller de Hilda (delantera y trasera), taller del carretero, tonelero, horno,
  talabartero, cordelero, taller del Paso del Fuelle y tres casas (soportal, placeta y bajada).

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| El ruido, el tejadillo y la chimenea de la forja, el puesto de armaduras, el olor del horno | Los encargos de Ferro [C pendiente: `enc_herrero`] y de Hilda; los talleres del soportal y del patio [P]; el horno de Maela [P]; el atajo de la Escalerilla; el crematorio sellado, solo por fuera | Ferro [C], Hilda [C], el aprendiz de la forja [C mundo vivo], Damián y Maela [P, del barrio], el talabartero, el cordelero y el tonelero [P, sin nombre], vecinos, Albar [C] en el paseo | «El pedido de Maese Ferro» [C]; la puerta que «no se abre» [C: Albar]. Nada nuevo sobre el crematorio | Las **Piezas Huérfanas** [P] se reconstruyen en el taller de Hilda (reserva `reserva_piezas_taller`, ante su puerta). El carro de Damián, reparado, sale cargado del patio [P, plan §3]. El soportal puede ser un segundo sitio para la Feria de los Oficios [P] (ancla `puesto_soportal`) |

## 3. La Ribera Baja (sector 8)

Es lo más bajo de la ciudad, a cota −2, junto a la muralla este y la sur:

- **Rampa de los Carros** [P, M0]: baja de las caravanas (0) a los almacenes (−2) entre dos casas y el almacén de la
  puerta, en 14 m al 14 % (un carro cargado la sube).
- **Escalera del Molino** [P, M0]: dos tramos al 40 % con un rellano que es un **balcón sobre la rueda del molino**,
  en la **acequia** [P]. El pretil va en tramos, 1 m sobre la escalera, así que la rueda y el agua se ven. El agua sale
  de una **boca** bajo la Calle del Horno. Abajo están la placeta del molino y el **Puente de los Carros** [P].
- **Patio de los almacenes** [P]. Tiene el **lavadero** [P], cubierto, con su pila junto a la acequia; el **andén de
  carga** [P] a −1, ante el almacén grande, con su rampa, su bordillo de 1 m y una polea; el **almacén del aceite** [P];
  y, al este, el pie de la **Torre de la Campana [C]**, donde está el ancla `ref_ribera`. Desde el patio se ve, al
  norte y arriba, el pretil de la Calle del Horno con sus vecinos asomados.
- **La torre y la ronda [C]** (`ciudades/oakhaven.gd`: la torre «se sube por dentro: vista y paso a la ronda», su
  puerta está en el «Pie de la torre» y la ronda está «en alto, solo desde la torre»). La **puerta de la torre** está a
  pie de patio, a −2. Se entra andando y la escalera (40 %) sube **por dentro** de un cuerpo de la torre cerrado por los
  dos lados y cubierto [P: en la maqueta es un cuerpo pegado a la cara sur de la torre]. Arriba están el **Mirador de
  la Ronda** [P] y el **adarve** sobre la muralla del este, a cota 3, con los **tres faroles de la ronda** [C:
  `oak_faroles`] y el **cofre al final** [C: `oak_cofre_ronda`, ancla `cofre_ronda`]. En la cara sur de la torre, a la
  altura del adarve, está la puerta del **campanario**, «Subir al campanario» (la vista de la torre [C:
  `oak_vista_torre`]; el interior aún no existe). Así el encargo se hace en su orden: torre, faroles, cofre.
- **Callejón de los Fardos** [P]: sin salida, al fondo del almacén, con fardos y lonas rasgadas. Es la reserva de
  **Rastreadores** [P], con el ancla global `reserva_rastreadores_almacen`.
- **Senda de la Acequia, pasarela y Rincón de la Acequia** [P]: un bucle corto junto al agua, donde los niños echan
  barquitos. La acequia sale bajo la muralla sur por una **reja**, y eso **no es una salida**: solo la Puerta del Sur
  sale al mapa.

Funciones pedidas, una a una:

- **Punto de referencia.** La torre, de 22 m, con su campanario.
- **Ensanche para orientarse.** El patio, de unos 550 m².
- **Escaleras y rampas.** La Rampa de los Carros (14 %), la Escalera del Molino (40 %), la escalera de la torre (40 %)
  y la rampa del andén (33 %).
- **Distintas alturas separadas.** Tres niveles: −2, −1 (el andén) y 3 (la ronda), separados por muros, pretiles y el
  bordillo del andén.
- **Corredores cubiertos.** El lavadero y la escalera de la torre.
- **Callejón sin salida con razón.** El Callejón de los Fardos: la pista de los Rastreadores.
- **Atajos.** La Escalera del Molino (Calle del Horno → patio) y el bucle de la acequia.
- **Vida, con anclas.** `bastian`, `farol_1`, `farol_2`, `farol_3`, `cofre_ronda`, `mirador`, `lavanderas`, `molinero`,
  `mozos_anden`, `caballo_carro`, `ninos_acequia` y `rueda_molino`.
- **Puertas previstas (7).** Almacén grande, molino, almacén del aceite, campanario, almacén del sur, almacén del fondo
  y una casa de la rampa. La torre no lleva puerta «en obras»: se entra andando.

| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La torre, el agua y la rueda, el trabajo pesado del andén | Subir por dentro de la torre a la ronda; encender los tres faroles y llegar al cofre [C: `oak_faroles`]; desde el Mirador, el patio y el andén vistos desde arriba; el lavadero; el fondo del almacén con la pista de **Rastreadores** [P] | Bastián [C, su sitio es la Calle Mayor; aquí, al pie de la torre, mirando a la ronda], guardias [C mundo vivo], mozos de almacén, lavanderas y el molinero [P] | La Torre de la Campana y la ronda [C]; «faltan tres, en la muralla del este» [C] | Tras `oak_faroles` [C], los tres faroles de la ronda encendidos («la muralla se ilumina»); tras Rastreadores [P], los almacenes se llenan y el callejón se despeja |

## 4. Nombres nuevos [P] de B (se suman a las decisiones del plan §8)

- **Oficios:** Ensanche de la Forja, Callejón del Carbón, Paso del Fuelle, Calle del Horno, Patio de los Talleres (el
  nombre del barrio), Placeta de la Fuente, Escalerilla de la Colina y Paseo de la Colina. Oficios sin nombre propio:
  talabartero, cordelero y tonelero.
- **Ribera:** Puente de los Carros, andén de carga, lavadero, almacén del aceite, cuerpo de la escalera de la torre,
  Mirador de la Ronda, Callejón de los Fardos, Senda de la Acequia y Rincón de la Acequia.

Son lugares y oficios, no personajes: no se ha inventado a nadie. Los vecinos sin nombre (mozos, lavanderas, molinero,
el fuellero, los oficios del soportal y del patio) son anclas de vida. Fuera del encargo no hay nada nuevo de historia:
ni sobre la niebla, ni el Sello, ni el crematorio por dentro. **Para decidir:** el nombre y el uso del almacén del
aceite (era el «cuerpo de faroles», que no es canon) y si el cuerpo de la escalera debe ser parte de la torre misma
cuando llegue el kit.

## 5. Pendiente

- **Recorrido con los controles normales** a 1600×720 y 1280×720 (contrato §4, paso 4). No está hecho: no hay ventana
  en esta sesión. Solo pasan las pruebas sin ventana.
- **Ronda de la Ribera.** El adarve está a cota 3, el máximo de la caja de la Ribera en `plano.gd`, unos 5 m sobre el
  patio, y la muralla queda como pretil de 1,3 m. Si se quiere más alta, hay que subir la cota máxima del sector, que es
  un cambio compartido.
- **Vistas hacia el sur.** Con la cámara fija al norte, ningún mirador enseña lo que tiene al sur. No se ha puesto
  ninguna `CAMARA_ZONA` para adelantar el foco: si se quiere una vista al sur de verdad (el pretil de la Calle del
  Horno, el Mirador de la Ronda), o se añade esa zona y se comprueba en pantalla, o se decide que la cámara gire, que
  no lo decide B.
- **Agua.** La acequia y la rueda son bloques `decor` del color ocre del blockout, y la rueda no gira.
- **Pendiente de otras fases.** Los interiores (forja, talleres, horno, molino, campanario…), los vecinos, los sistemas
  reservados (Piezas Huérfanas, Rastreadores) y el acabado con el kit.

## 6. Segunda pasada (B-2): lo que encontraron las revisiones y qué se ha hecho

Cada hallazgo se comprobó antes de tocar nada (con las pruebas y con una medida propia en todas las casillas de 0,25 m).

| Hallazgo | Gravedad | ¿Real? | Qué se ha hecho |
|---|---|---|---|
| Las «vistas» al sur (pretil de la Calle del Horno, Placeta, Mirador) no salen con la cámara fija | media | Sí | Ya no se venden: el ancla `vista_ribera` pasa a `asomados_horno` (vecinos que se ven desde el patio de la Ribera) y el Mirador enseña el patio desde arriba. Sin `CAMARA_ZONA` (§5) |
| Canto del andén sin muro, hueco al este del andén y franja vacía ante la puerta del cuerpo de faroles | media | Sí | Bordillo `canto_anden` (1 m sobre el andén), el almacén del aceite llega a x 92 y un suelo nuevo (21) ante su puerta y la de la torre |
| Foso de 9 × 2 m entre el Paseo de la Colina y el taller del carretero | media | Sí | `talud_carretero`, 0,7-1,2 m sobre el paseo y la subida |
| Paso del Fuelle: 18 m sin puerta ni nada | media | Sí | Puerta lateral de un taller (`hoja_fuelle`), fuelles viejos y el ancla `fuellero` |
| Tramo bajo de la Escalerilla: cañón de 17 m | media | Sí | El taller de Hilda llega a la escalerilla y le abre una puerta trasera a media subida |
| Paseo de la Colina: 16 m sin nada | media | Sí | Ciprés con un vecino paseando y el primer banco movido a x 65 |
| El pretil de la Escalera del Molino tapa la rueda | media | Sí | Seis tramos, 1 m sobre la escalera; en el rellano, balcón de 0,9 m; rueda de 5 m |
| Soportal con dos casas ciegas | media | Sí | Talabartero y cordelero [P], con sus puertas (ocultables) y un puesto bajo los arcos |
| Patio de los Talleres con un solo taller y la mitad sur vacía | media | Sí | Portón del tonelero [P] al patio, ruedas apoyadas, tajo de leña y niños junto al árbol |
| La forja no se distingue y su chimenea apenas sobresale | media | Sí | Forja a 7,5 m, chimenea a 16,7, casa vecina a 6 m y tejadillo sobre el Ensanche. Con Kael delante la chimenea sigue fuera del encuadre: es la cámara fija |
| Canon: la ronda se sube por una escalera abierta, no desde la torre; sin cofre | media | Sí | Puerta de la torre a pie de patio, escalera por dentro (cerrada y cubierta), campanario arriba y ancla `cofre_ronda` (§3) |
| Huecos junto a la Bajada al Molino y al oeste de la Escalera del Molino | baja | Sí | `casa_bajada_o` hasta z 39; talud y `casa_carros_2` cierran el oeste de la escalera |
| Pretiles de la Calle del Horno a 0,35 m de la calle | baja | Sí | Seis tramos de 6 m, cima = cota más alta del tramo + 0,9 |
| Paseo de la Colina sin antepecho al sur | baja | Sí | `pretil_paseo_1..3`, de 0,9 a 1,3 m sobre el paseo |
| La acequia aparece sin origen | baja | Sí | `boca_acequia` bajo la Calle del Horno y terraplén en el hueco |
| Rampa de los Carros al 20 % | baja | Sí | 14 m al 14 %; puertas y anclas de la rampa a su nueva cota |
| Pasarela de 1,5 m | baja | Sí | 2 m |
| Puerta del cuerpo de faroles separada del suelo | baja | Sí | Suelo 21 ante ella (umbral a 0,05 m de la hoja) |
| Huecos sin suelo ni bloque (zanja de la Calle del Horno y otros) | baja | Sí | Terraplenes en los dos sectores; lo andable de la Ribera llega a la muralla sur; casas y almacenes cerrados. La medida propia ya no encuentra ningún borde que dé a un hueco |
| Rendijas de 0,2-0,5 m | baja | Sí | Pila de temple, leña, abrevadero, sacos, grúa, fardos, lonas, barriles, banco del mirador y faroles, pegados a su muro |
| «Cuerpo de faroles» inventado y Bastián trabajando allí | baja | Sí | Almacén del aceite [P]; Bastián sin edificio, al pie de la torre |
| `b.md` en minúscula | baja | Sí | Ahora `B.md`; rutas cambiadas en los dos trazados |
