# Ciudad de Oakhaven, maqueta: sectores del agente A (16/11, EXPERIMENTAL [P])

Agente de maqueta **A** (plan `docs/v12/CIUDAD_OAKHAVEN_PLAN.md` §6): sector 1 **Puerta del Sur y Caravanas**
(`zonas3d/ciudad/sectores/puerta_sur/`) y sector 2 **Plaza del Tapiz y Gran Mercado** (`zonas3d/ciudad/sectores/plaza_tapiz/`).
Blockout recorrible a escala de los personajes, NO acabado. Contrato: `docs/v12/CIUDAD_OAKHAVEN.md` §3-§4. Marcas: **[C]**
canon citado (`ciudades/oakhaven.gd`, `zonas3d/oakhaven/mundo_vivo.gd`, plan §0), **[P]** propuesta. Rama `area-ciudad-a`,
desde la punta integrada `4f67e4b`; arreglos de la revisión en `area-ciudad-a-2` (sección final). No se tocó nada compartido.

## Puerta del Sur y Caravanas (sector 1)

### Superficie andable (medida con `prueba_ciudad_plano`, rejilla de 0,25 m)
**1 508 m²** (1 507,94; M0: 866; primera maqueta de A: 1 468; objetivo del plan 1 000-1 700). Caja 75 × 33 m (x −30..45,
z 62..95). Cotas 0 y 1.

### Plano (z al sur; la cámara, al sur, mira al norte)
Bandas de oeste a este (x) y de norte a sur (z); entre paréntesis, la cota:
```
 x −30..−14  z 62..65  casas de la rayuela (una con puerta)
             z 65..72  PATIO DE LA RAYUELA (1), sin salida
             z 72..79  dos casas y, entre ellas (x −23..−20), el ZAGUÁN (1)
 x −30..−10  z 79..91  TERRAZA DEL ARCO (1); el arco entra por x −30, z 80..83; escalera (1→0) en x −10..−7, z 85..88
 x −14..−5   z 62..75  casa de la Calle Mayor;  z 75..79  CALLEJÓN DE LOS ARRIEROS (1→0), atajo hasta la Calle Mayor
 x −5..8     z 62..81  CALLE MAYOR (0) con su acera oeste y el SOPORTAL DE LA GUARDIA (x 4..8), faroles
 x 8..18     z 62..76  CUERPO DE GUARDIA (garita encima);  z 76..81  PATIO DE LA GUARDIA (0), cerrado, portillo x 9..10,6
 x −7..18    z 81..93  EXPLANADA (0) ante la Puerta del Sur (x −4..4, z 93); poste de caminos en (5,5, 87,5)
 x 18..30    z 62..73  ESTABLO;  x 30..45  z 62..66  ALMACÉN DE PORTES;  x 31..41  z 66..73  MUELLE (1) + borde + escalera
 x 18..41    z 73..93  PATIO DE CARAVANAS (0);  x 41..45  z 76..82  salida a la Rampa de los Carros
 x 41..45    z 66..76  casa del este (puerta al muelle);  z 82..93  COBERTIZO DE CARROS (tejado sobre postes)
 z 93..95,5  muralla sur, torres y Puerta del Sur [C]
```

### Qué hay
| Lugar | Qué es | Cota |
|---|---|---|
| Calle Mayor, tramo sur [C] | Llega de la plaza (borde z 62). Al oeste, la casa de la Calle Mayor con su puerta; acera oeste (x −5..−4) continua con la de la plaza; **faroles** [C «un farol cada 5 casillas»] alternos | 0 |
| Soportal de la guardia [C] | Continuo con el de la plaza; pilares a la calle y la planta del cuerpo de guardia encima (`cubierta`); faroles colgados; el atril del **libro de guardia** [C] | 0 |
| Cuerpo de guardia [C] y **garita** [P] | Puerta al soportal. La garita con su mástil y **bandera** es el hito que se ve con la cámara al sur desde la explanada y las caravanas (la Puerta queda a la espalda de la cámara) | 0 |
| Patio de la guardia [C] | Los **trastos requisados** y su cofre [C `oak_cofre_requisados`]. **Cerrado** con valla y un portillo a la vista de Aldric: no es un paso (el canon lo trata como secreto) | 0 |
| Explanada ante la Puerta del Sur | El ensanche para orientarse; **Aldric** [C] junto a la puerta; el **pilón** [P] con su caño; banco al pie de la muralla; el **poste de caminos** [P] en el centro, con tablillas a la Plaza, las Caravanas y los Pasajes | 0 |
| Patio de caravanas (del barrio, plan §4) | **Establo** con dos cuadras a medio portón y puerta, gancho del cepillo; abrevadero, pozo, heno, cerca y **amarradero**; dos carros de caravana con sus **lonas** y un **toldo de lonas** entre ellos (paso cubierto); pila de cajas de Tobías; fardos; banco; sitio de **mulas** y del caballo de portes | 0 |
| Muelle de carga [P] | Plataforma a la altura de la caja de un carro: el **borde de carga** queda abierto sobre el **carro de portes**; escalera de piedra (33 %), pretiles; el **almacén de portes** [P] y la casa del este abren a él; sacos junto al borde. **Fondo sin salida con razón** (los portes) | 1 |
| Cobertizo de carros [P] | Tejado sobre postes, abierto al patio, pared de fondo, un carro guardado | 0 |
| Rampa de los Carros (salida) | Al este (borde x 45, z 76..82): baja a la Ribera Baja | 0 |
| Terraza del Arco [P] | Llega del Arco de los Pasajes (borde x −30, cota 1) con su dintel (a la altura del arco de C); banco, tendedero, arriate; pretiles y **escalera de piedra** (33 %) a la explanada; una casa con puerta | 1 |
| Callejón de los Arrieros [P] | **Atajo** del Arco de los Pasajes a la Calle Mayor sin cruzar la explanada: tramo llano y rampa (17 %), pretil al sur, el **dornajo** donde beben las mulas de los arrieros | 1 → 0 |
| Zaguán [P] | Corredor de 3 m bajo una casa (`cubierta` a 2,8 m), de la terraza al patio de la rayuela | 1 |
| Patio de la Rayuela [P] | **Callejón sin salida con razón**: la rayuela pintada y los niños, el pozo, banco, tinajas, una vivienda con puerta | 1 |

Muralla sur, torres y Puerta del Sur [C]: los de M0 (la única salida al mapa; en la maqueta avisa «Volver al banco»).

### Puertas previstas (7)
Establo, Cuerpo de guardia, Casa (Calle Mayor), Almacén de portes [P], Casa del este (al muelle), Casa (Terraza del Arco),
Casa (Patio de la Rayuela). Todas «Aún no se puede entrar (en obras).».

### Gente prevista (anclas con nombre, para la fase de vida)
`aldric` (junto a la puerta), `guardia_soportal` (junto al libro, sin tapar su frente), `brena` y `avena` (ante el establo),
`porteador` (Tobías, entre el carro de portes y la pila), `caballo_portes`, `mulas_caravana_1`, `mulas_caravana_2`,
`arriero_muelle` (cargando desde el borde), `mula_arrieros` (en el dornajo), `ninos_pozo` (en la rayuela), `vecina_pozo`,
`ninos_terraza`, `vecino_terraza`, `viajero_pilon`. Cosas: `libro_guardia`, `cofre_requisados`, `portillo_guardia`,
`poste_caminos`, `pilon`, `pozo_patio`, `abrevadero`. Reserva: `reserva_rastreadores_caravanas` (25, 0, 85), bajo el toldo
de lonas (= el ancla global del plano).

### Grafo local y cámara
18 nodos, tramos rectos andables (`n_mayor_n` ↔ `c_calle_mayor`, `n_carros` ↔ `c_rampa_carros`, `n_arco` ↔ `c_arco_pasajes`).
De la explanada a las caravanas por `n_caravanas_o` (19, 81,5), ya en el patio de caravanas: el patio de la guardia queda
fuera del grafo. Sin zonas de cámara: el foco es Kael. Ocultables (11): la muralla, las torres, la puerta y su dintel (M0),
las dos casas al sur del patio de la rayuela, el muro al sur del arco, la pared de fondo del cobertizo (al sur de la rampa)
y el tendedero.

### Tabla del plan §3
| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La garita y su bandera, la explanada con el poste de caminos, el bullicio del patio de caravanas (mulas, carros, lonas), el establo y Avena, el muelle con el carro | Hablar con Aldric [C]; leer el libro de guardia [C]; los requisados tras el portillo [C]; el establo (Brena y Avena [P]); el muelle y el almacén de portes [P]; el patio de la rayuela (rincón sin salida); el atajo de los Arrieros | Aldric [C], guardias [C mundo vivo], Brena, Tobías, mozo de portes [P], arrieros, vecinos y niños de la rayuela y de la terraza | Aldric deja salir a Kael en el prólogo [C]; Garon «a caballo antes del alba» [C pv_05]; el libro y los requisados de la guardia [C]; los faroles de la Calle Mayor [C] | Tras «Antes de que se enfríe» [P, del barrio] las caravanas descargan para el horno (el carro de portes y el muelle); **Rastreadores** [P]: las señales en las lonas empiezan bajo el toldo (`reserva_rastreadores_caravanas`) |

## Plaza del Tapiz y Gran Mercado (sector 2)

### Superficie andable
**2 150 m²** (2 149,62; M0: 2 141; el plan admite ≈ 2 100 para la plaza). Caja 75 × 77 m. Cotas 0 → 2 → 4.

### Lo que añadió A al ejemplo de M0 (marcado «(A)» en el trazado)
- **Mercado**: toldos (`cubierta`) sobre los tres puestos; puesto de fruta [C mundo vivo: el frutero] con su toldo; dos
  puestos y cestos **bajo la lonja** (la lonja del barrio, plan §4); la **pila del mercado** [P] con su caño en la fachada
  oeste de la plaza baja. El tablón del Gremio [C], más bajo (no tapa a Kael).
- **Plaza alta**: el **puesto de flores de Rosa** [C: «fuente, tablón de anuncios y puesto de flores»] con su toldo; dos
  árboles con copa (troncos finos, ≤ 0,5 m) y un banco a la sombra del noroeste; un banco junto a la fuente; el **mirador
  del pretil** [P] (banco que mira al mercado desde la plaza alta).
- **Plazuela de la Botica** [C] (`plazuela_botica`, «Selene, a la puerta»): entre la botica y la casa del suroeste, rampa
  del 12 % del callejón (cota 2) a la acera (≈ 0,9); la puerta de la botica da a ella y Selene está ahí. Es el **atajo** de
  la Calle Mayor a la botica, al callejón y al Paso Cubierto (de ≈ 31 m a ≈ 12).
- **Calle Mayor**: **faroles** [C «un farol cada 5 casillas»] alternos cada 5 m (fachadas del oeste y colgados en el
  soportal); **acera oeste** (x −5..−4) y **soportal** continuos hasta el sector 1 (llanos a cota 0 en z 60..62); la planta
  del soportal baja a la altura de la casa que la sostiene; escaparate de la botica.
- **Calles largas** (regla de los 12 m): puertas en la Calle del Cuervo, el callejón de la Botica (dos), la fachada oeste
  de la plaza baja, la Calle Mayor oeste, bajo el soportal (dos), ante la lonja, en el Paso Cubierto y la Calle del
  Mercado; banco en la Calle del Mercado; **secadero de hierbas** [P] de la botica en el callejón; faroles en el callejón y
  en el Paso Cubierto.
- **Sin rendijas**: las casas del sur de la plaza baja y de la Calle Mayor llegan al suelo (antes quedaban zanjas de 1 m),
  con la base siguiendo la acera en pendiente; la casa del sureste se adelanta a z 27 (−45 m²).
- **Gente prevista**: `rosa`, `frutero`, `vendedora_ciruelas`, `vecinos_lonja`, `ninos_fuente`, `selene` (en la plazuela);
  rincones `mirador_pretil`, `banco_arbol`, `pila_mercado`, `secadero_botica`. Grafo local de 15 nodos (`n_lonja`,
  `n_plazuela`, `n_callejon_m`).
- Ocultables (10): las casas del sur (M0), la casa al sur de la plazuela y las hojas de puerta de fachadas norte.

Puertas del sector: 13 (tienda [C], botica [C], 11 casas).

### Tabla del plan §3
| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La fuente, los toldos, la lonja, el tablón; las flores de Rosa; la escalinata entre los dos niveles; los faroles de la Calle Mayor | Tienda [C], tablón del Gremio [C] y el bando [C], comprar a Rosa [C], la botica de Selene [C] en su plazuela y el atajo al Paso Cubierto; mirador del pretil; la pila | Rosa [C], frutero y vendedora de ciruelas [C mundo vivo], Selene [C], vecinos de las casas de las calles | La plaza del tapiz [C]; «no se nombran en voz alta las aldeas perdidas» [C, bando]; la Plazuela de la Botica [C] | Los contratos del Gremio cambian los rumores; la **Feria de los Oficios** [P] instala puestos en la plaza baja (`reserva_feria_plaza`, libre de puestos) |

## Nombres nuevos [P] (se suman a las decisiones del plan §8)
Terraza del Arco, Callejón de los Arrieros (y su dornajo), Patio de la Rayuela, el zaguán de la rayuela, Muelle de carga,
Almacén de portes, el pilón de la Puerta, la garita de la guardia, el poste de caminos, el toldo de lonas, el cobertizo de
carros, la pila del mercado, el mirador del pretil y el secadero de hierbas de la botica. Del barrio (ya [P]): Brena, Avena,
Tobías. (Retirados para no repetir a los vecinos: «Patio del Pozo», «paso bajo casa» y la hornacina de los Arrieros.)

## Comprobación
- `prueba_ciudad_plano` y `prueba_ciudad_cargador` con el ejecutor (`-Solo prueba_ciudad_plano,prueba_ciudad_cargador`):
  **SUPERADAS 2 · FALLIDAS 0** (pasada `D:\REBELUM_diagnostico\pruebas\2026-11-16_102404`, rama `area-ciudad-a-2`).
  Ciudad entera: 11 340 m²; 26 entradas previstas.
- Réplica en Python de `trazado_comun.gd` y `plano.gd` (misma superficie que la prueba) con la visibilidad en **todas** las
  casillas de 0,25 m de los dos sectores y de lo vecino a 16 m (la prueba muestrea una cada metro): ningún bloque no
  ocultable tapa a Kael; sin huecos sin suelo pegados a lo andable; salto máximo 0,15 m.
- No se ha medido rendimiento (encargo). Cada ocultable es una malla aparte al montar el sector: el 1 tiene 11, el 2 tiene 10.
- **Pendiente**: el recorrido con ventana y controles normales a 1600×720 y 1280×720 (no hecho aquí).

## Para el coordinador (cambios compartidos, NO hechos)
- `plano.gd`, CONEXIONES `calle_mayor`: el paso real por z 62 va de x −5 a x 8 (acera oeste, calzada y soportal, todo llano
  a cota 0 en los dos lados). Propuesta: `desde −5.0`, `hasta 8.0`, o aceptarlo así.
- `plano.gd`/C: el Arco de los Pasajes. El dintel de A ya queda dentro de su caja (x −30..−29) y a la altura del de C
  (4..6 m); los muros de A miden 7 (norte) y 6 (sur) como las casas de C. Falta decidir quién dibuja la clave y si el hueco
  empieza en z 79,4 (C) o en z 80 (A y la conexión).
- `prueba_ciudad_plano`, regla 8: muestrear la visibilidad también en las casillas a menos de 1 m de un bloque (hoy, una cada
  metro: no veía la casa del noreste de la rayuela ni los carros). Y una regla nueva: ninguna casilla andable con una vecina
  sin suelo ni bloque dentro de la caja de su sector.
- `trazado_comun.gd`, `fino()`: compara `r.size <= FINO` con `Rect2` en float32; un poste de exactamente 0,6 m (0,6 →
  0,60000002) NO cuenta como fino. Se esquivó con piezas de ≤ 0,55 m; propuesta: `<= FINO + 0.001`.
- `docs/v12/CIUDAD_OAKHAVEN.md` §0, §2 y §7: superficie por sector (Puerta del Sur 1 508, Plaza 2 150) y entradas previstas:
  `puertas()` pasa de 11 a **26** con esta rama (puerta_sur 7, plaza_tapiz 13, oficios 3, cuervo 1, barrio_alto 1,
  ribera 1). La cifra de 23 de la primera entrega era errónea (eran 21).

## Arreglos tras la revisión (rama `area-ciudad-a-2`, 16/11)
Dos revisiones de solo lectura de `area-ciudad-a`. Cada hallazgo se comprobó con la réplica antes de tocarlo.

| Hallazgo | Gravedad | Qué se hizo |
|---|---|---|
| La Puerta del Sur queda a espaldas de la cámara; explanada vacía | alta | Garita de la guardia con mástil y bandera sobre el cuerpo de guardia (hito al norte); poste de caminos con tablillas en el centro de la explanada |
| `casa_pozo_ne` tapa a Kael en el Paso Cubierto de la Botica (66 casillas) | media | Alto 6 → 5 m: no tapa en ninguna casilla |
| El patio de la guardia (requisados, secreto) era el paso principal | media | Valla completa (z 76..81) y valla sur con portillo de 1,6 m; nodo `n_caravanas_o` en el patio de caravanas; ancla `portillo_guardia` |
| Soportal y acera cortados en z 60..62; rendija entre casas | media | Suelos llanos a cota 0 en z 60..62; planta del soportal hasta z 62 y escalonada; `casa_mayor_so` hasta z 62. El ancho del paso, pedido al coordinador |
| Rendijas sin suelo de 1 m junto a las fachadas | media | Botica, `casa_sur_e`, `casa_e_baja` y `casa_mayor_so` llegan al suelo; almacén hasta el establo |
| Regla de los 12 m y faroles canónicos | media | Faroles [C] en la Calle Mayor; puertas nuevas en el soportal, callejón, lonja y Paso Cubierto; escaparate y secadero de la botica; faroles en callejón y paso |
| Falta la Plazuela de la Botica [C] y un atajo | media | Plazuela con la puerta de la botica y Selene; arista Calle Mayor ↔ plazuela ↔ callejón |
| Carros de 1,6 m tapan la cabeza | baja | Carros a 1,4 m (lonas encima) |
| Tablón del Gremio tapa la cabeza | baja | Alto 2,2 → 1,5 m (sin malla extra) |
| Casas que flotan sobre la acera | baja | Base bajada y alto subido (misma cumbrera) |
| Muelle sin carro | baja | Borde de carga abierto (suelo a cota 1 hasta z 73) con el carro de portes debajo; pretiles; sacos al borde; Tobías y su caballo al lado |
| Cobertizo cerrado; casa del este sin puerta | baja | Cobertizo abierto (cubierta, postes, pared de fondo, carro); puerta de la casa del este al muelle |
| Arco de los Pasajes que no casa con el de C | baja | Dintel dentro de la caja de A, a 4..6 m; muros a 7 y 6 m. La clave y el hueco, al coordinador |
| Nombres repetidos con C y D; hornacina repetida | baja | «Patio de la Rayuela» con su rayuela; «zaguán»; dornajo y mula de los Arrieros |
| Sin animales de tiro | baja | Anclas de mulas y caballo; amarradero junto a la cerca |
| Valla que se mete en el cuerpo de guardia (z-fighting) | baja | Valla desde z 76 |
| Dintel del arco dentro de la caja de pasajes | baja | Dentro de la de A |
| Guardia encima del sitio de lectura del libro | baja | Guardia a (5,4, 67,4) |
| Recuento de puertas mal en la petición | baja | Corregido arriba (26 con esta rama) |
| Plaza por encima de lo previsto | baja | En parte: −45 m² (casa del sureste a z 27) compensan la plazuela (+36) y los remates del soportal y la acera (+10). Queda en 2 150 |

Además (visto al arreglar): las hojas de puerta de las fachadas sur y este estaban DENTRO de la caja de su casa (cara
coplanaria con la fachada); ahora van fuera, como las del resto.
