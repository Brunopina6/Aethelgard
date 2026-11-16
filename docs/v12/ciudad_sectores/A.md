# Ciudad de Oakhaven, maqueta: sectores del agente A (16/11, EXPERIMENTAL [P])

Agente de maqueta **A** (plan `docs/v12/CIUDAD_OAKHAVEN_PLAN.md` §6): sector 1 **Puerta del Sur y Caravanas**
(`zonas3d/ciudad/sectores/puerta_sur/`) y sector 2 **Plaza del Tapiz y Gran Mercado** (`zonas3d/ciudad/sectores/plaza_tapiz/`).
Blockout recorrible a escala de los personajes, NO acabado. Contrato: `docs/v12/CIUDAD_OAKHAVEN.md` §3-§4. Marcas: **[C]**
canon citado (`ciudades/oakhaven.gd`, `zonas3d/oakhaven/mundo_vivo.gd`, plan §0), **[P]** propuesta. Rama `area-ciudad-a`,
desde la punta integrada `4f67e4b`. No se tocó nada compartido.

## Puerta del Sur y Caravanas (sector 1)

### Superficie andable (medida con `prueba_ciudad_plano`, rejilla de 0,25 m)
**1 468 m²** (M0: 866; objetivo del plan 1 000-1 700). Caja 75 × 33 m (x −30..45, z 62..95). Cotas 0 y 1.

### Plano (z al sur; la cámara, al sur, mira al norte)
Bandas de oeste a este (x) y de norte a sur (z); entre paréntesis, la cota:
```
 x −30..−14  z 62..65  casas del pozo (una con puerta)
             z 65..72  PATIO DEL POZO (1), sin salida
             z 72..79  dos casas y, entre ellas (x −23..−20), el PASO BAJO CASA (1)
 x −30..−10  z 79..91  TERRAZA DEL ARCO (1); el arco entra por x −30, z 80..83; escalera (1→0) en x −10..−7, z 85..88
 x −14..−5   z 62..75  casa de la Calle Mayor;  z 75..79  CALLEJÓN DE LOS ARRIEROS (1→0), atajo hasta la Calle Mayor
 x −5..8     z 62..81  CALLE MAYOR (0) con su acera oeste y el SOPORTAL DE LA GUARDIA (x 4..8)
 x 8..18     z 62..76  CUERPO DE GUARDIA;  z 76..81  PATIO DE LA GUARDIA (0)
 x −7..18    z 81..93  EXPLANADA (0) ante la Puerta del Sur (x −4..4, z 93)
 x 18..30    z 62..73  ESTABLO;  x 31..45  z 62..66  ALMACÉN DE PORTES;  x 31..41  z 66..70  MUELLE (1) + escalera
 x 18..41    z 73..93  PATIO DE CARAVANAS (0);  x 41..45  z 76..82  salida a la Rampa de los Carros
 x 41..45    z 66..76  casa del este;  z 82..93  cobertizo de carros
 z 93..95,5  muralla sur, torres y Puerta del Sur [C]
```

### Qué hay
| Lugar | Qué es | Cota |
|---|---|---|
| Calle Mayor, tramo sur [C] | Llega de la plaza (borde z 62, x −4..4). Al oeste, la casa de la Calle Mayor con su puerta; acera oeste (x −5..−4) que sigue la de la plaza | 0 |
| Soportal de la guardia [C] | Pilares a la calle y la planta del cuerpo de guardia encima (`cubierta`); el atril del **libro de guardia** [C] | 0 |
| Cuerpo de guardia [C] | Puerta al soportal | 0 |
| Patio de la guardia [C] | Los **trastos requisados** y su cofre [C `oak_cofre_requisados`], valla con el patio de caravanas | 0 |
| Explanada ante la Puerta del Sur | El ensanche para orientarse; **Aldric** [C] junto a la puerta; el **pilón** [P] con su caño; banco al pie de la muralla | 0 |
| Patio de caravanas (del barrio, plan §4) | **Establo** con dos cuadras a medio portón y puerta, gancho del cepillo; abrevadero, pozo, heno y cerca; dos carros de caravana con sus **lonas** y un **toldo de lonas** entre ellos (paso cubierto); carro de portes y pila de cajas de Tobías; fardos; banco | 0 |
| Muelle de carga [P] | Plataforma a la altura de la caja de un carro, con escalera de piedra (33 %) y pretiles; el **almacén de portes** [P] con su puerta; sacos. **Fondo sin salida con razón** (los portes) | 1 |
| Rampa de los Carros (salida) | Al este (borde x 45, z 76..82): baja a la Ribera Baja | 0 |
| Terraza del Arco [P] | Llega del Arco de los Pasajes (borde x −30, cota 1) con su dintel; banco, tendedero, arriate; pretiles y **escalera de piedra** (33 %) a la explanada; una casa con puerta | 1 |
| Callejón de los Arrieros [P] | **Atajo** del Arco de los Pasajes a la Calle Mayor sin cruzar la explanada: tramo llano y rampa (17 %), pretil al sur, hornacina | 1 → 0 |
| Paso bajo casa [P] | Corredor de 3 m bajo una casa (`cubierta` a 2,8 m), de la terraza al patio del pozo | 1 |
| Patio del Pozo [P] | **Callejón sin salida con razón**: el pozo, niños jugando, banco, tinajas, una vivienda con puerta | 1 |

Muralla sur, torres y Puerta del Sur [C]: los de M0 (la única salida al mapa; en la maqueta avisa «Volver al banco»).

### Puertas previstas (6)
Establo, Cuerpo de guardia, Casa (Calle Mayor), Almacén de portes [P], Casa (Terraza del Arco), Casa (Patio del Pozo). Todas
«Aún no se puede entrar (en obras).».

### Gente prevista (anclas con nombre, para la fase de vida)
`aldric` (junto a la puerta), `guardia_soportal` (ante el libro), `brena` y `avena` (ante el establo), `porteador` (Tobías,
entre el carro de portes y la pila), `arriero_muelle`, `ninos_pozo`, `vecina_pozo`, `ninos_terraza`, `vecino_terraza`,
`viajero_pilon`. Cosas: `libro_guardia`, `cofre_requisados`, `pilon`, `pozo_patio`, `abrevadero`. Reserva:
`reserva_rastreadores_caravanas` (25, 0, 85), bajo el toldo de lonas (= el ancla global del plano).

### Grafo local y cámara
18 nodos, tramos rectos andables (`n_mayor_n` ↔ `c_calle_mayor`, `n_carros` ↔ `c_rampa_carros`, `n_arco` ↔ `c_arco_pasajes`).
Sin zonas de cámara: el foco es Kael. Ocultables (11): la muralla, las torres, la puerta y su dintel (M0), las dos casas al
sur del patio del pozo, el muro al sur del arco, el cobertizo de carros (al sur de la rampa) y el tendedero.

### Tabla del plan §3
| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La Puerta del Sur y su explanada, el bullicio del patio de caravanas, el establo y Avena, el toldo de lonas | Hablar con Aldric [C]; leer el libro de guardia [C]; los requisados [C]; el establo (Brena y Avena [P]); el muelle y el almacén de portes [P]; el patio del pozo (rincón sin salida); el atajo de los Arrieros | Aldric [C], guardias [C mundo vivo], Brena, Tobías, mozo de portes [P], vecinos y niños del pozo y de la terraza | Aldric deja salir a Kael en el prólogo [C]; Garon «a caballo antes del alba» [C pv_05]; el libro y los requisados de la guardia [C] | Tras «Antes de que se enfríe» [P, del barrio] las caravanas descargan para el horno (el carro de portes y el muelle); **Rastreadores** [P]: las señales en las lonas empiezan bajo el toldo (`reserva_rastreadores_caravanas`) |

## Plaza del Tapiz y Gran Mercado (sector 2)

### Superficie andable
**2 150 m²** (M0: 2 141; el plan admite ≈ 2 100 para la plaza). Caja 75 × 77 m. Cotas 0 → 2 → 4.

### Lo que añadió A al ejemplo de M0 (marcado «(A)» en el trazado; nada se rehízo)
- **Mercado**: toldos (`cubierta`) sobre los tres puestos; puesto de fruta [C mundo vivo: el frutero] con su toldo; dos
  puestos y cestos **bajo la lonja** (la lonja del barrio, plan §4); la **pila del mercado** [P] con su caño en la fachada
  oeste de la plaza baja.
- **Plaza alta**: el **puesto de flores de Rosa** [C: «fuente, tablón de anuncios y puesto de flores»] con su toldo; dos
  árboles con copa (troncos finos, ≤ 0,5 m) y un banco a la sombra del noroeste; un banco junto a la fuente; el **mirador
  del pretil** [P] (banco que mira al mercado desde la plaza alta).
- **Calles largas** (regla de los 12 m): seis puertas nuevas (Calle del Cuervo, callejón de la Botica, fachada oeste de la
  plaza baja, Calle Mayor oeste y bajo el soportal, Calle del Mercado) y un banco en la Calle del Mercado. **Acera oeste** de
  la Calle Mayor (x −5..−4) hasta las fachadas (antes quedaba un hueco de 1 m sin suelo); sigue en el sector 1.
- **Gente prevista**: `rosa`, `frutero`, `vendedora_ciruelas`, `vecinos_lonja`, `ninos_fuente`, `selene` (a la puerta de la
  botica [C]); rincones `mirador_pretil`, `banco_arbol`, `pila_mercado`. Nodo `n_lonja` en el grafo local (13 nodos).
- Ocultables: además de las casas del sur (M0), las hojas de puerta de sus fachadas norte.

Puertas del sector: 9 (tienda [C], botica [C], 7 casas).

### Tabla del plan §3
| Qué atrae | Qué se descubre o hace | Quién vive o trabaja | Lore | Qué cambia tras una actividad |
|---|---|---|---|---|
| La fuente, los toldos, la lonja, el tablón; las flores de Rosa; la escalinata entre los dos niveles | Tienda [C], tablón del Gremio [C] y el bando [C], comprar a Rosa [C], la botica de Selene [C] y su paso cubierto; mirador del pretil; la pila | Rosa [C], frutero y vendedora de ciruelas [C mundo vivo], Selene [C], vecinos de las casas de las calles | La plaza del tapiz [C]; «no se nombran en voz alta las aldeas perdidas» [C, bando] | Los contratos del Gremio cambian los rumores; la **Feria de los Oficios** [P] instala puestos en la plaza baja (`reserva_feria_plaza`, libre de puestos) |

## Nombres nuevos [P] (se suman a las decisiones del plan §8)
Terraza del Arco, Callejón de los Arrieros, Patio del Pozo, el paso bajo casa del pozo, Muelle de carga, Almacén de portes,
el pilón de la Puerta, el toldo de lonas, el cobertizo de carros, la pila del mercado y el mirador del pretil. Del barrio
(ya [P]): Brena, Avena, Tobías.

## Comprobación
- `prueba_ciudad_plano` y `prueba_ciudad_cargador` con el ejecutor (`-Solo prueba_ciudad_plano,prueba_ciudad_cargador`):
  **SUPERADAS 2 · FALLIDAS 0** (pasada `D:\REBELUM_diagnostico\pruebas\2026-11-16_095129`). Ciudad entera: 11 300 m².
- No se ha medido rendimiento (encargo). Cada ocultable es una malla aparte al montar el sector: el 1 tiene 11, el 2 tiene 7.
- **Pendiente**: el recorrido con ventana y controles normales a 1600×720 y 1280×720 (no hecho aquí).

## Para el coordinador (cambios compartidos, NO hechos)
- `trazado_comun.gd`, `fino()`: compara `r.size <= FINO` con `Rect2` en float32; un poste de exactamente 0,6 m (0,6 →
  0,60000002) NO cuenta como fino. Se esquivó con troncos de 0,5 m; propuesta: `<= FINO + 0.001`.
- `docs/v12/CIUDAD_OAKHAVEN.md` §0 y §7: actualizar la superficie por sector (Puerta del Sur 1 468, Plaza 2 150) al integrar.
