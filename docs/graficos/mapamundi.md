# Mapamundi de REBELUM: análisis y propuesta (T-085, fase 1)

- **Fecha:** 2026-11-08/09. **Rama:** `area-graficos` (base `dddbddb`). **Responsable:** especialista de gráficos.
- **Estado:** propuesta con prototipo jugable. `mapa.gd` y `mapa.tscn` **no se han tocado**: el mapa actual sigue
  siendo el del juego. La integración es la fase 2, con el coordinador.
- Convención: **[código]** observado en el código · **[ejecutado]** comprobado ejecutando (aislado) ·
  **[pendiente]** sin verificar.

## 1. Cómo se genera y se dibuja hoy [código, `mapa.gd` @ `dddbddb`]

| Pieza | Qué hace | Dónde |
|---|---|---|
| Tamaño y cámara | Mundo de 2400×1350 px; `Camera2D` hija de Kael, zoom 1, límites en el borde: en pantalla se ven 1280×720 px del mundo a escala 1:1 | `MAPA_TAM` (l. 9), `_crear_jugador` (l. 280-289) |
| Imagen del mapa | No existen `mapa_mundo.jpg` ni `mapa_zonas.png`: el terreno se **genera al cargar** en una imagen de **600×337** (1 píxel = 4×4 px del mundo) y se dibuja con un `Sprite2D` a escala 4 y filtro lineal | `RES_TERRENO = 4` (l. 33), `_generar_terreno` (l. 138-186), `_crear_mapa` (l. 201-207) |
| Tierra | Campo `v = 1 − distancia(ruta o isla)/170 + 0,9·ruido`: la tierra es la unión de «cápsulas» alrededor de las rutas entre lugares y de círculos en las islas | l. 156-164 |
| Costa | Corte binario por píxel de 4 px (`v < 0` → mar) y banda de arena binaria (`v < 0,08`) | l. 165, 181-182 |
| Biomas | Zona = la del lugar más cercano (Voronoi deformado por ruido de 260 px). Color: **una constante por zona** (`ZONAS`) oscurecida un 15 % y aclarada por un único ruido de frecuencia 0,004 (≈ 250 px de periodo) | l. 170-180 |
| Agua | Dos azules mezclados según `−v`, ±8 % de ruido | l. 150-151, 166-167 |
| Máscara de juego | La misma pasada guarda tierra y zona en una máscara (600×337 → 1200×675 con `resize` NEAREST). `_es_tierra` (choques) y `_zona_en` (encuentros y «Zona: …») la leen | l. 179, 184, 494-516 |
| Marcas y rótulos | Círculo (ciudad) o rombo naranja (lugar) de 26-32 px, la foto del portal de Meshy, rótulos de 20 px debajo del punto y dos regiones de 34 px | l. 218-265 |

## 2. Por qué se ve así: causas

1. **Costas escalonadas.** La costa es un umbral binario evaluado una vez por bloque de 4×4 px y estirado ×4: escalones
   de 4 px en pantalla (6 px en un móvil de 1080 px de alto), suavizados por el filtro lineal, que los emborrona sin
   quitarlos. La banda de arena tiene el mismo escalón. [ejecutado: `antes/5_costa_3x.png`]
2. **Grandes manchas planas.** Cada bioma es un color constante; la única variación es un ruido de ~250 px de periodo,
   más grande que el personaje (≈ 100 px) y que un tercio de la pantalla. Medido en el mapa entero a 1:1: el
   **77,2 %** de los bloques de 16×16 px tienen una desviación de luminancia < 2/255 (desviación media 5,73/255).
   [ejecutado]
3. **Poco detalle geográfico.** El generador no tiene altura, ríos, montañas, bosques ni caminos: la forma sale de
   los datos de juego (rutas y lugares) y nada más. Los biomas son celdas de Voronoi (con islotes sueltos de una zona
   dentro de otra, que se leen como manchas al azar).
4. **Legibilidad.** Marcas iguales para todos los destinos; rótulos de 20 px **debajo** del punto, justo donde aparece
   Kael (al abrir el mapa, Kael tapa «Oakhaven»: `antes/1_juego_inicio.png`); la foto del portal no casa con el resto.
5. **Detalles técnicos.** 337 filas × 4 = 1348 px: abajo quedan **2 px sin pintar** (el color de fondo, visible al
   llegar al borde) [ejecutado]. La máscara del juego va **2 px más abajo** que el dibujo en la mitad inferior del mapa
   (el `resize` NEAREST de Godot muestrea por centros y repite la fila 168) [ejecutado: réplica exacta en
   `datos_mapa.gd`]. Coste de carga: generar el terreno tarda **≈ 1,0 s de CPU** en el PC cada vez que se abre el
   mapa (indicativo, no es una medida formal; en el Redmi será más). [ejecutado]

## 3. Técnica elegida: mapa pintado horneado sin conexión + agua viva barata

**Qué es.** Un generador (`aethelgard/mapa_arte/generar_mapa.gd`) que parte de **los mismos datos de `mapa.gd`**
(reproduce su campo de tierra y sus zonas con las mismas semillas) y pinta con la GPU, una vez y fuera del juego, un
mapa ilustrado de 2400×1350 (`mapa_mundo.webp`). En el juego solo se dibuja esa imagen, con un sombreado de agua muy
ligero encima, y los iconos y rótulos en vivo, en la posición de cada lugar.

**Lo que pinta** (luz de arriba a la izquierda y sombras azuladas, como `docs/guia_visual.md`):
- costa continua con borde suavizado a partir del campo continuo (sin escalones), línea de tinta fina, playa o roca
  según la zona, espuma y tres líneas de oleaje rotas «a pincel»;
- agua con hondura: turquesa en la orilla, plataforma azul y añil en mar abierto, cáusticas, trazos de ola y la bruma
  del borde del mundo (Océano de Bruma); los lagos interiores son agua dulce y, en la isla de la ceniza, **lava**;
- relieve (mapa de alturas con sombreado y sombras proyectadas): colinas, cordilleras, el macizo de Ciclópea, dunas
  en media luna, mesetas del yermo, la caldera del Abismo y el **tajo de la Garganta del Diablo**;
- picos dibujados (2,5D) en las cimas de montaña y nieve, sin tapar caminos, ríos ni lugares; bosques de copas
  redondas con sombra, pinos y pinos nevados, cristales y charcas-espejo en el Valle de los Ecos, árboles secos y
  vetas de brasa en la ceniza;
- **caminos** (uno por cada ruta de `mapa.gd`) y cuatro ríos que bajan de las montañas al mar.

**Iconos y rótulos** (`iconos_mapa.gd`, dibujados por código a 4× y reducidos): un hito por destino: la ciudadela de
Oakhaven con el Árbol Milenario, el árbol santuario con el Núcleo, el puente colgante sobre la Garganta, el pico
helado de Ciclópea, las ruinas y el Lente del Sol, el barco-esqueleto de Sunken City, los espejos de agua del Valle,
el templo sumergido, la fortaleza de Morgath, el arco de oro del portal y el puente con cascada y faroles de Pastos
Verdes. Rótulos encima del icono (Kael ya no los tapa al llegar), Saira Condensed de 22 px (ciudades 25 px, en oro y
con la estrella de la marca), regiones en Cormorant cursiva, brújula añil y oro con la estrella de cuatro puntas, y el
**anillo del radio real de «Entrar»** (`RADIO_LUGAR`) cuando Kael está cerca.

**Por qué esta técnica** (y no otras):
- *Ampliar o suavizar la imagen actual:* descartado (lo pide el encargo y no añade relieve ni detalle).
- *Todo en un sombreador en tiempo real* (campo de distancias + biomas + relieve en la GPU del móvil): costas igual de
  limpias, pero cada píxel pagaría ruido, sombreado y sombras cada fotograma en la Mali-G57 (limitada por la GPU), y
  los picos, árboles e iconos seguirían necesitando sprites. Más coste y menos control artístico.
- *Horneado sin conexión* (elegido): toda la calidad cara se paga una vez, en el PC; en el juego cuesta **una
  textura**. Calidad visual primero sin coste en el móvil, reproducible (el generador está en el repositorio) y atado
  a los datos del juego.

**Coste** (estimado; las medidas son de la fase 2):
- Sombreado [ejecutado, `malioc` 2026.5, Mali-G57 r0p1, controlador r51p0; equivalentes ESSL en
  `D:\REBELUM_diagnostico\mapamundi\2026-11-08\malioc\`]: sprite simple (el mapa de hoy) **0,75 ciclos/píxel**
  (limitado por los *varyings*); mapa nuevo con agua viva **1,00 ciclo/píxel** (4 lecturas de textura, 24 registros,
  ocupación completa). A 1280×720 son ≈ +0,23 M ciclos por fotograma. Con `-- agua_quieta` (o en un perfil bajo) cuesta
  lo mismo que hoy.
- Memoria de vídeo [pendiente de medir]: `mapa_mundo` 2400×1350 sin pérdida ≈ 9,7-13 MB (hoy, 600×337 ≈ 0,6 MB);
  `agua_datos` 1200×675 ≈ 3,2 MB (se puede bajar a 600×338); iconos ≈ 0,5 MB.
- Tamaño: `mapa_mundo.webp` 357 KB en el repositorio y ≈ 1,7 MB en el paquete (importado sin pérdida); el resto de
  `mapa_arte/` ≈ 0,4 MB.
- Carga: el mapa nuevo **no genera el terreno** (lee la máscara ya hecha, idéntica): se ahorra ≈ 1 s de CPU en el PC
  por cada apertura del mapa [pendiente de medir en condiciones comparables y en el Redmi].

## 4. Coincidencia con el juego [ejecutado, `pruebas/prueba_mapamundi.gd`]

| Comprobación | Resultado |
|---|---|
| `datos_mapa.gd` reproduce la máscara de `mapa.gd` (tierra, mar y zona de cada píxel) | 0 píxeles distintos de 810 000 |
| `mapa_arte/mapa_zonas.png` (la que usará el mapa nuevo) es idéntica a la generada | 0 píxeles distintos |
| `tierra_juego(q)` == `_es_tierra(q)` | 1 080 000 puntos iguales |
| Costa dibujada frente a la tierra del juego | 0,30 % de puntos en desacuerdo, **todos a 2,8 px o menos** de la línea dibujada (la máscara del juego va a bloques de 4 px; el dibujo es continuo) |
| Lugares, nombres, tipos, posiciones, rutas, islas, radio de «Entrar» y tamaño del mapa | iguales que en `mapa.gd` (10 lugares; 11 con la exploración 3D) |
| Iconos y rótulos | cada icono contiene la posición de su lugar y cada rótulo está centrado sobre ella |
| «Entrar» | aparece en cada lugar y no a `RADIO_LUGAR` + 6 px |
| Alternativa (`-- mapa_clasico`) | el prototipo dibuja el mapa de siempre |

Las zonas de los encuentros, la colisión con la costa y el progreso no cambian: el prototipo **hereda** `mapa.gd` y
usa la misma máscara. Las transiciones de color entre biomas se pintan suaves (≈ 26 px) **centradas en el borde real**
de cada zona.

## 5. Comparación visual

Capturas con ventana, mismos encuadres antes y después (`pruebas/prueba_mapamundi_fotos.gd`), en
`D:\REBELUM_diagnostico\mapamundi\2026-11-08\`:
- `antes\` y `propuesta\`: `1_juego_inicio`, `2_mapa_entero_1a1` (2400×1350), `3_mapa_entero_pantalla`, `4_costa_1x`,
  `5_costa_3x`, `6_ciudad_oakhaven`, `7_destino_garganta`, `8_destino_cumbres`, `9_movil_20x9` (1600×720);
- `comparacion\`: cada pareja lado a lado (PNG y JPG);
- en el repositorio, reducidas: `docs/graficos/mapamundi_comparacion_juego.jpg`, `…_mapa.jpg` y `…_costa.jpg`.

Planitud del mapa entero a 1:1 (bloques de 16×16 px con desviación < 2/255): **77,2 % → 32,7 %**; desviación media
**5,73 → 10,76** /255 [ejecutado].

**Móvil:** el juego usa `stretch/mode = canvas_items` con el aspecto por defecto (`keep`): en un móvil HD+ 20:9 (720 px
de alto) se ve a 1:1, con franjas negras de 160 px a los lados (`9_movil_20x9.png`). La resolución exacta del Redmi no
consta en el proyecto [pendiente: `adb shell wm size`, lo hace el usuario o el coordinador]. Rótulos de 22-25 px ≈
13,5-15,5 sp en una pantalla de ≈ 260 ppi (el texto normal de Android es de 14 sp).

## 6. Procedencia de los recursos

Todo lo de `aethelgard/mapa_arte/` es **propio, generado por código de este repositorio** (sin recursos externos, sin
servicios con créditos): `generar_mapa.gd` + `hornear_mapa.gdshader` (mapa, alturas, árboles, picos, ríos, caminos),
`iconos_mapa.gd` (iconos), `datos_mapa.gd` (datos de `mapa.gd`). Fuentes de los rótulos: Saira Condensed y Cormorant
(OFL, ya en `fuentes/`). Fila propuesta para `docs/recursos.md` (archivo del coordinador):

| Mapamundi pintado e iconos de lugares | Generados por código (`aethelgard/mapa_arte/generar_mapa.gd`, `iconos_mapa.gd`, `hornear_mapa.gdshader`) | Propia | `mapa_arte/prototipo_mapa.tscn` (prototipo, fase 1) | Sí (imágenes generadas y su generador) |

## 7. Cómo se regenera

```
# con ventana (pinta con la GPU) y con los datos aislados; tarda ~20 s (cache=<carpeta> lo acelera)
Godot --path aethelgard --script res://mapa_arte/generar_mapa.gd -- [cache=<carpeta>] [salida=<carpeta>]
Godot --headless --path aethelgard --import        # importa lo nuevo (la máscara como Image, sin GPU)
```

Si cambian `LUGARES`, `RUTAS`, `ISLAS`, `ZONA_LUGAR` o el generador de `mapa.gd`, hay que regenerar: la prueba
`prueba_mapamundi` falla si la máscara horneada deja de ser idéntica.

## 8. Cambios que necesitará la fase 2 en `mapa.gd` y `mapa.tscn`

**Opción A (recomendada, mínima):** `mapa.tscn` pasa a usar `res://mapa_arte/mapa_arte.gd` como script (una línea:
el `ext_resource` del script). `mapa_arte.gd` hereda `mapa.gd` y solo sustituye `_generar_terreno`, `_crear_mapa`,
`_dibujar_marcas`, `_comprobar_cerca` (llama a la original) y `_dibujar_brujula`. **`mapa.gd` no cambia.** Al
integrar, revisar si el especialista de sonido añadió algo dentro de `_crear_mapa` o `_generar_terreno` (el prototipo
no llama a la original de esas dos cuando el arte está activo); `_comprobar_cerca` sí la llama.

**Opción B (todo en `mapa.gd`):** añadir `arte_activo()` y, detrás de él, el contenido de esas cinco funciones de
`mapa_arte.gd`; `mapa.tscn` no cambia.

En las dos: el interruptor de la alternativa. Hoy es el argumento `-- mapa_clasico`; para el juego, una opción (por
ejemplo, en Ajustes o una constante) que el coordinador decida. Nada de lo funcional cambia (`LUGARES`, `RUTAS`,
posiciones, `RADIO_LUGAR`, encuentros, `_es_tierra`, `_zona_en`, `escena_retorno`, guardado).

## 9. Riesgos y límites

- **Sin medidas de rendimiento todavía** (lo pidió el coordinador): memoria, carga y tiempo por fotograma, en la fase 2.
- Memoria de vídeo mayor (≈ 13-17 MB frente a ≈ 0,6 MB). Si molesta en el Redmi: compresión ETC2/ASTC o `agua_datos`
  a la mitad, siempre con capturas antes y después (calidad primero).
- Picos y árboles se dibujan en el suelo: Kael puede andar por encima (también hoy: la máscara no cambia). Los picos no
  tapan caminos.
- En el juego, Kael (≈ 118 px de alto) tapa en parte el icono al llegar a un lugar: es lo esperable al estar «delante».
- La imagen es lineal-filtrada a 1:1; en móviles de 1080 px de alto se ve a 1,5× (algo más blanda) [pendiente de ver
  en el teléfono].
- El prólogo, el portal, el menú y los combates no se probaron sobre el prototipo (heredan el código; en la fase 2,
  con el mapa integrado, pasan sus pruebas).
- Las propuestas de la biblia v3 no se usaron: los iconos salen de las descripciones de `LUGARES` (canon del código).

## 10. Plan de la fase 2

1. Integración con la alternativa (opción A o B), con `mapa.gd` y `mapa.tscn` que pase el coordinador.
2. Pruebas: `prueba_mapamundi`, `prueba_escenas`, `prueba_dpad`, `prueba_toque`, `prueba_foco`, `prueba_mando`,
   `prueba_teclado`, `prueba_prologo`, `prueba_isla`, `prueba_musica`, `prueba_zona3d`, y las capturas de
   `prueba_mapamundi_fotos` con el mapa integrado.
3. Medidas en un hueco sin otra carga, antes y después y en las mismas condiciones: carga del mapa, tiempo por
   fotograma (con y sin agua viva), memoria de vídeo y estática; en el Redmi, con una APK de prueba del coordinador.
4. Según las medidas: formato de la textura (sin pérdida o comprimida), tamaño de `agua_datos` y el agua viva por
   perfil, siempre con la comparación visual.
5. Pulido artístico propuesto: más variedad en picos, campos de cultivo junto a las ciudades, puentes donde los
   caminos cruzan ríos, bruma animada en el Océano de Bruma y, si se quiere, una vista del mundo entero para el botón
   «Mapa».
