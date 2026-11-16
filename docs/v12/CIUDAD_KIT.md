# Ciudad completa de Oakhaven: la biblioteca modular (kit) — 16/11, EN PRUEBAS, todo PROPUESTA [P]

Rama `area-ciudad-kit` (desde `claude/rebelum-v12` @ `b6c1f6e`). Encargo: punto 3 del reparto de
`docs/v12/CIUDAD_OAKHAVEN_PLAN.md` §6 (biblioteca modular de Blender con el acabado aprobado). Carpeta propia:
`aethelgard/zonas3d/ciudad/kit/`. **No toca** `zonas3d/barrio/` ni `zonas3d/muestra_calle/`: los reutiliza leyendo e
importando. Ninguna escena del juego usa todavía el kit (lo usarán los sectores de la ciudad, que hace otro agente).

Láminas, comparaciones y tramo de prueba: `D:\REBELUM_diagnostico\ciudad_oakhaven\kit\` (fuera del repositorio).

## 1. Qué hay

| Archivo | Qué es |
|---|---|
| `kit/fuente/kit_ciudad.py` | El generador (Blender 5.2 por guion, sin interfaz): los módulos, la API `colocar()`, el horneado, la exportación, las láminas y el tramo de prueba |
| `kit/modelos/<módulo>.glb` (+ `.import`) | Un GLB por módulo: objetos `<módulo>_fijo` (con mapa de luz, UV2), `<módulo>_piezas` y `<módulo>_vegetacion` (luz en los vértices), vacíos `choque_*` (caja: escala = medio tamaño) y `ancla_<módulo>_*` |
| `kit/modelos/kit_luz_2048.png`, `kit_luz_1024.png` | El **atlas de luz** de lo fijo de TODOS los módulos (una sola textura de luz para todo el kit) |
| `kit/modelos/kit_ciudad.json` | Por módulo: sector, uso, tipo, envolvente, medidas, huella, «sube», triángulos, anclas y choques |
| `kit/kit_ciudad.gd` | Para usar un módulo en Godot tal cual: `instanciar()`, `vestir()` (los sombreados de la muestra), `choques()`, `anclas()` |
| `kit/herramientas/comprobar_kit.gd` | Comprobación sin ventana de todos los GLB importados (ver §5) |

**El acabado** es el aprobado, sin cambios: la arquitectura de entramado del barrio y la muestra (se reutilizan sus
constructores: `casa_alero`, `casa_hastial`, `nave`, `puerta_calle`, `toldo`, `escaparate`, `letrero_con`, `porton`,
`arco_rebajado`, `farol_pie`, `hornacina`, `tendedero`… leídos de `crear_barrio.py` con `ast`, sin ejecutar su
`main`), sus colores, **las 8 texturas de `muestra_calle/texturas`** (ninguna textura nueva), sus 11 materiales
(en Godot, los 4 sombreados de la muestra, ningún programa nuevo) y la misma luz de la tarde dorada (sol 252°/24°,
cielo frío, escala de luz 2,229). Colores nuevos solo dentro de esa paleta: la glicinia (violeta → lavanda), el
verde oscuro del ciprés, el latón dorado de la fuente y la piedra noble del Barrio Alto.

**Escala** (Kael ≈ 1,7 m): puertas de 2,2-2,5 m (la noble, 3,1 m; los arcos de paso, clave a 3,0-3,6 m), escalones de
0,165 m × 0,32 m (la escalera exterior de la vivienda: 0,176 × 0,30), libres de paso ≥ 2,3 m bajo toldos, aleros,
porches, pérgola y corredores, balcones con el suelo a ≥ 2,6 m, pretiles y balaustradas de 0,85-1,0 m.

**Lo que NO se hace** (plan §2 y encargo): ni templo de vidrieras, ni emblemas en la portada noble (cartela lisa),
ni nombres ni edificios canónicos (la forja es «una forja», no la de Maese Ferro; la torre es «una torre de muralla»).
La fuente dorada es una PROPUESTA de aspecto (decisión del usuario pendiente, plan §8).

## 2. Los módulos

Convenciones (las de `crear_barrio.py`): coordenadas de Godot (x este, y arriba, z SUR); la cámara de juego mira al
norte sin girar, así que **las fachadas miran a +z**. Medidas: x (ancho) × z (fondo) × y (alto), con lo que vuela.
Triángulos: los del generador (en Godot, iguales o hasta un 5 % menos: §5). Medidas con punto decimal (del json).

#### Fachadas (una casa entera; pivote en la esquina oeste del frente, mira a +z)

| Módulo | Medidas x × z × y (m) | Triángulos GLB (fijo · piezas · vegetación) | Sector | Qué es |
|---|---|---|---|---|
| `vivienda_terrazas` | 7.7 × 8.2 × 10.0 | **8 146** (4881 · 602 · 2663) | 4 Las Terrazas | Vivienda de las Terrazas: hastial a la calle, balcón de madera con macetas y una glicinia que trepa por la jamba y corre bajo el balcón. Puerta en arco 1,15 × 2,4 m. |
| `vivienda_terrazas_escalera` | 9.0 × 7.4 × 9.2 | **6 080** (4586 · 350 · 1144) | 4 Las Terrazas | Vivienda de las Terrazas con escalera exterior de 17 peldaños (0,176 × 0,30 m) a la puerta del piso y rellano volado sobre la puerta de abajo; macetas en los peldaños y baranda de madera. |
| `forja` | 8.6 × 8.7 × 10.2 | **4 284** (3969 · 315 · 0) | 3 Calle de los Oficios | Taller y forja: planta baja de sillería con la boca del taller en arco rebajado, fragua encendida bajo un tejadillo, yunque, pila de templar, chimenea ancha y letrero de la herradura. |
| `tienda_toldo` | 7.9 × 7.5 × 9.3 | **6 106** (4288 · 720 · 1098) | 2 Plaza del Tapiz, 3 Calle de los Oficios | Tienda con escaparate encendido de telas, toldo a rayas (borde a 2,28 m), letrero y puerta de dintel. |
| `casa_pasajes` | 5.1 × 8.7 × 12.0 | **4 790** (3627 · 0 · 1163) | 5 Pasajes Viejos | Casa de los Pasajes Viejos: estrecha (3,8 m), de tres alturas con dos vuelos, revoque gris de cal, hiedra, farol y un leve desplome hacia el este (antigua). |
| `casa_noble` | 10.3 × 9.3 × 12.6 | **7 530** (6263 · 210 · 1057) | 7 Barrio Alto de las Raíces | Casa noble del Barrio Alto: planta baja de sillería con portada en arco (1,7 × 3,1 m) entre pilastras, rejas, piso noble con balcón corrido de hierro, cornisa y tejado de pizarra con dos chimeneas. |
| `almacen_ribera` | 10.0 × 9.0 × 7.6 | **5 181** (3838 · 1196 · 147) | 8 La Ribera Baja | Almacén de la Ribera: nave de tablas sobre zócalo, portón doble abierto (2,8 × 3,0 m), puerta del pajar con viga de polea, muelle de carga de piedra, sacos y toneles. |
| `arco_paso` | 5.4 × 1.0 × 4.6 | **934** (290 · 0 · 644) | 5 Pasajes Viejos, 1 Puerta del Sur, 7 Barrio Alto | Arco de paso en un muro de sillería de 0,7 m: vano de 2,4 m de medio punto (clave a 3,6 m), dovelas en las dos caras y albardilla. |
| `arco_rebajado_paso` | 5.3 × 1.4 × 4.4 | **424** (424 · 0 · 0) | 3 Calle de los Oficios, 8 La Ribera Baja, 2 Plaza del Tapiz | Arco rebajado de paso (vano 3,2 m, clave a 3,1 m) en un muro de revoque de 0,6 m con dovelas de sillería. |
| `soportal_arcos` | 8.1 × 7.6 × 10.4 | **5 403** (4714 · 115 · 574) | 2 Plaza del Tapiz (lonja), 2 Calle Mayor | Soportal de piedra de dos arcos de medio punto sobre columnas (fondo 2,4 m; clave a 4,2 m) con piso de entramado encima y tejado de alero (7,2 × 6 m). |
| `paso_bajo_casa` | 6.6 × 6.7 × 9.7 | **3 633** (2814 · 0 · 819) | 5 Pasajes Viejos (Paso Cubierto de la Botica) | Paso bajo casa: bóveda rebajada de 2,8 m de luz (clave a 3,0 m) que atraviesa 5 m de casa, con piso de entramado volado encima y tejado; farol dentro. |
| `torre_muralla` | 5.2 × 5.6 × 17.8 | **1 802** (1074 · 0 · 728) | 8 Ribera (ronda), 1 Puerta del Sur, muralla | Torre cuadrada de muralla (4,6 × 4,6 m, 11 m hasta las almenas) con saeteras, puerta en arco, matacán y chapitel de pizarra (cumbre a 15,5 m). |

#### Piezas de muro: arcos, puertas, ventanas, balcones, tejados, porches, balaustradas, muros

| Módulo | Medidas x × z × y (m) | Triángulos GLB (fijo · piezas · vegetación) | Sector | Qué es |
|---|---|---|---|---|
| `puerta_arco` | 2.8 × 1.0 × 3.7 | **704** (532 · 70 · 102) | todos | Puerta de calle en arco de dovelas (1,2 × 2,5 m), hoja verde de tablas con aldaba, en un paño de muro de 2,8 × 3,4 m. |
| `puerta_dintel` | 2.6 × 0.6 × 3.5 | **478** (478 · 0 · 0) | todos | Puerta de dintel de madera sobre jambas de piedra (1,1 × 2,3 m), hoja roja, en un paño de 2,6 × 3,2 m. |
| `porton_doble` | 5.5 × 1.0 × 3.9 | **310** (310 · 0 · 0) | 3 Calle de los Oficios, 8 La Ribera Baja, 1 Caravanas | Portón de dos hojas abierto (2,6 × 2,8 m) en un paño de tablas de 4 × 3,6 m. |
| `ventana_postigos` | 1.6 × 0.9 × 2.3 | **573** (286 · 0 · 287) | todos | Ventana de 0,7 × 1,0 m con postigos abiertos, jardinera y flores, en un paño de 1,6 × 2,0 m (para cosido de fachadas). |
| `ventana_encendida` | 1.6 × 0.7 × 2.3 | **274** (274 · 0 · 0) | todos | Ventana encendida (cristal que da luz) de 0,6 × 0,95 m con postigos azules. |
| `hornacina` | 2.2 × 0.7 × 3.7 | **766** (155 · 0 · 611) | 5 Pasajes Viejos | Paño de muro (1,8 × 3,4 m) con la hornacina de la muestra: arco, velas encendidas, figurilla y flores. |
| `balcon_madera` | 2.6 × 1.1 × 3.0 | **982** (466 · 210 · 306) | 4 Las Terrazas, 5 Pasajes Viejos | Balcón volado de madera (2,0 × 0,8 m) con ménsulas, balaustres de tabla, puerta-ventana y macetas; se pega a una fachada con el suelo a ≥ 2,6 m. |
| `balcon_hierro` | 3.2 × 1.1 × 3.2 | **842** (670 · 70 · 102) | 7 Barrio Alto de las Raíces, 2 Plaza del Tapiz | Balcón de losa de piedra con moldura y baranda de barrotes de hierro (2,6 × 0,75 m) y puerta-ventana. |
| `tejado_dos_aguas` | 7.0 × 6.1 × 2.5 | **1 382** (1382 · 0 · 0) | todos | Tejado suelto a dos aguas de teja (cubre 6 × 5 m, alero de 0,45 m, cumbrera a 2,2 m sobre el alero) con hastiales de revoque; para cuerpos añadidos. |
| `tejado_alero_largo` | 5.3 × 2.4 × 3.9 | **384** (384 · 0 · 0) | 3 Calle de los Oficios, 1 Caravanas, 8 La Ribera Baja | Tejadillo de un agua con alero largo (5 × 2 m) sobre canes y tornapuntas, pegado a un muro (de 3,2 m a 2,6 m: se pasa debajo). |
| `tejado_soportal` | 6.5 × 2.9 × 3.4 | **628** (628 · 0 · 0) | 1 Caravanas, 2 Plaza (Calle Mayor), 6 Patio del Cuervo | Porche de madera: tejado de un agua sobre pies derechos con zapatas (6 × 2,4 m; libre 2,55 m), para delante de una fachada. |
| `corredor_cubierto` | 4.2 × 3.2 × 3.4 | **704** (704 · 0 · 0) | 5 Pasajes Viejos, 6 Patio del Cuervo | Corredor cubierto de madera (tramo de 4 m que se repite en x; 2,4 m de ancho, libre 2,5 m): pies derechos con zapatas, carreras, tirantes y tejadillo a dos aguas. |
| `balaustrada` | 3.1 × 0.4 × 1.2 | **828** (828 · 0 · 0) | 4 Las Terrazas, 7 Barrio Alto (miradores) | Balaustrada de piedra de 3 m (1,0 m de alto): plinto, balaustres torneados, pasamanos y pilares; se repite en x. |
| `muro_terraza` | 5.3 × 1.6 × 3.0 | **966** (70 · 0 · 896) | 4 Las Terrazas, 7 Barrio Alto | Muro de contención de una terraza: sillería de 5 m × 2,4 m con albardilla, mechinales, plantas que cuelgan y flores en las juntas (la terraza alta queda detrás, a +2,4). |
| `muralla_almena` | 6.7 × 3.3 × 9.5 | **2 045** (662 · 0 · 1383) | muralla (1, 7, 8) | Tramo de muralla de 6 m: 7 m de alto y 2,4 m de grueso, talud, dos arcos ciegos de descarga en la cara de dentro (la que ve la cámara), adarve a 7 m y parapeto almenado hacia fuera. |
| `farol_pared` | 0.2 × 0.7 × 0.6 | **136** (136 · 0 · 0) | todos | Farol en brazo de hierro para colgar de una fachada (pivote en el muro, a 2,9 m). |
| `tendedero` | 4.0 × 0.8 × 0.8 | **372** (192 · 180 · 0) | 4 Las Terrazas | Cuerda de tender de 4 m con ropa, entre dos escuadras de hierro a 3,2 m (por encima de Kael); se cuelga de una fachada. |
| `glicinia_muro` | 3.4 × 0.8 × 4.5 | **1 236** (12 · 264 · 960) | 4 Las Terrazas, 5 Pasajes Viejos | Glicinia en flor para arrimar a una fachada (3,2 m de ancho, hasta 4,3 m): tronco que sube junto a una puerta y dos ramas con racimos. |

#### Escaleras y rampas (pivote en el borde oeste del primer peldaño; suben hacia −z)

| Módulo | Medidas x × z × y (m) | Triángulos GLB (fijo · piezas · vegetación) | Sector | Qué es |
|---|---|---|---|---|
| `escalera_recta` | 2.9 × 1.9 × 1.5 | **372** (324 · 0 · 48) | 4 Las Terrazas, 7 Barrio Alto, 5 Pasajes Viejos | Escalera recta de 6 peldaños (contrahuella 0,165 m, huella 0,32 m; sube 0,99 m en 1,92 m), 2,2 m de ancho, con zancas de sillería escalonadas. |
| `escalera_rellano` | 3.2 × 5.5 × 4.6 | **2 077** (1544 · 284 · 249) | 4 Las Terrazas, 7 Barrio Alto (Calle del Árbol) | Escalera de dos tramos de 6 peldaños con rellano de 1,6 m (sube 1,98 m en 5,44 m), 2,4 m de ancho, pretiles de piedra, balaustrada en el rellano, farol y macetas. |
| `rampa` | 2.6 × 6.0 × 1.1 | **1 769** (64 · 1705 · 0) | 3 Calle de los Oficios, 8 Rampa de los Carros | Rampa empedrada de 2,6 × 6 m que sube 0,6 m (5,7°), con bordillos de sillería y costados de piedra. |

#### Suelos (4 × 4 m; x 0…4, z −4…0)

| Módulo | Medidas x × z × y (m) | Triángulos GLB (fijo · piezas · vegetación) | Sector | Qué es |
|---|---|---|---|---|
| `empedrado_4x4` | 4.0 × 4.0 × 0.1 | **2 753** (8 · 2745 · 0) | todos | Losa de suelo de 4 × 4 m: losas irregulares de Voronoi (las de la muestra) sobre tierra; se repite sin costura visible. |
| `losas_plaza_4x4` | 4.0 × 4.0 × 0.1 | **768** (8 · 760 · 0) | 2 Plaza del Tapiz, 7 Barrio Alto | Losa de suelo de 4 × 4 m: losas rectangulares a matajunta (las de la plaza del barrio). |

#### Fuente, toldos, mobiliario y vegetación (pivote en el centro de la base)

| Módulo | Medidas x × z × y (m) | Triángulos GLB (fijo · piezas · vegetación) | Sector | Qué es |
|---|---|---|---|---|
| `fuente_plaza` | 4.5 × 4.5 × 3.5 | **1 114** (1006 · 0 · 108) | 2 Plaza del Tapiz | Fuente de la plaza (propuesta del aspecto «dorado» de la referencia, adaptado a la paleta): grada y pila octogonales de sillería (Ø 4,6 m), fuste con dos tazas de latón dorado, remate de piña y cortinas de agua. |
| `toldo_mercado` | 3.1 × 2.6 × 2.9 | **1 459** (324 · 1039 · 96) | 2 Gran Mercado, 6 Patio del Cuervo (Feria) | Puesto de mercado con toldo a dos aguas de lona a rayas (2,8 × 2,2 m; borde a 2,3 m, cumbrera a 2,85 m) sobre cuatro postes, mesa de caballetes con fruta, coles y cestas. |
| `toldo_vela` | 4.3 × 3.7 × 3.5 | **200** (200 · 0 · 0) | 2 Gran Mercado, 4 Las Terrazas (patios), 6 Patio del Cuervo | Toldo de vela a rayas tendido entre cuatro mástiles (3,6 × 3,0 m; de 3,0 m detrás a 2,55 m delante) con sus cuerdas; para dar sombra a un paso o un patio. |
| `banco_piedra` | 1.6 × 0.5 × 0.5 | **36** (0 · 36 · 0) | todos | Banco de piedra (1,6 × 0,45 m, asiento a 0,45 m). |
| `banco_madera` | 1.7 × 0.5 × 0.9 | **108** (0 · 108 · 0) | todos | Banco de tablas con respaldo (1,7 × 0,5 m). |
| `barriles` | 1.3 × 1.4 × 0.8 | **744** (0 · 744 · 0) | 3 Oficios, 6 Patio del Cuervo, 8 Ribera Baja | Grupo de tres barriles (dos de pie y uno tumbado sobre calzos). |
| `cajas` | 1.5 × 1.2 × 1.0 | **770** (0 · 770 · 0) | 1 Caravanas, 3 Oficios, 8 Ribera Baja | Pila de cajones y sacos de mercancía. |
| `puesto_mercado` | 3.3 × 0.8 × 1.1 | **832** (0 · 832 · 0) | 2 Gran Mercado | Puesto sin toldo: mesa de caballetes (2,2 × 0,8 m) con cajones de fruta, cesta de pan y tinaja. |
| `farol_pie` | 0.8 × 0.3 × 3.4 | **148** (148 · 0 · 0) | todos | Farol de pie de la muestra (poste de 3,3 m con brazo y farol encendido). |
| `macetas` | 1.1 × 0.9 × 0.7 | **516** (0 · 210 · 306) | 4 Las Terrazas, todos | Grupo de tres macetas de barro con flores (geranios, margaritas, lavanda). |
| `maceta_limonero` | 1.2 × 0.9 × 1.8 | **588** (0 · 228 · 360) | 4 Las Terrazas, 7 Barrio Alto, 2 Plaza | Tinaja grande con un limonero (1,9 m) y sus limones. |
| `abrevadero` | 3.1 × 0.8 × 1.7 | **140** (110 · 0 · 30) | 1 Caravanas, 8 La Ribera Baja, 3 Oficios | Abrevadero de piedra (2,2 × 0,7 × 0,6 m) con agua y su pilar con caño de latón. |
| `carro` | 4.0 × 1.8 × 1.5 | **1 337** (0 · 1337 · 0) | 1 Caravanas, 3 Oficios, 8 La Ribera Baja | Carro de dos ruedas (Ø 1,2 m) cargado de sacos, un tonel y cajones, con la lanza apoyada en el suelo. |
| `carretilla` | 2.1 × 0.8 × 0.8 | **450** (0 · 450 · 0) | 3 Oficios, 4 Las Terrazas | La carretilla de la muestra, con sacos. |
| `glicinia_pergola` | 3.6 × 3.1 × 3.3 | **2 956** (204 · 348 · 2404) | 4 Las Terrazas, 7 Barrio Alto (jardines) | Pérgola de madera (3,0 × 2,4 m, libre 2,6 m) cubierta por una glicinia en flor: tronco retorcido en un pie, hojas por encima y racimos colgantes (el más bajo a ≈ 2,0 m). |
| `cipres_alto` | 1.5 × 1.5 × 7.1 | **1 266** (0 · 108 · 1158) | 7 Barrio Alto, 4 Las Terrazas, muralla | Ciprés estilizado de 7 m (Ø 1,4 m). |
| `cipres_bajo` | 1.0 × 1.1 × 4.3 | **590** (0 · 108 · 482) | 7 Barrio Alto, 4 Las Terrazas, 2 Plaza | Ciprés joven de 4,2 m (Ø 1 m). |

Total de los 52 módulos: 88 916 triángulos en los GLB.

Presupuesto: una casa entera (fachada, tejado, chimenea, atrezo de la puerta y vegetación) cuesta 4 300-8 100
triángulos; las piezas de muro, 270-2 100; el atrezo, 36-1 500; los 52 módulos juntos, 88 900. Cada módulo son hasta
3 mallas (fijo, piezas, vegetación) con los materiales del kit que use (≤ 9 superficies por malla). Referencias: el
barrio pide ≤ 60 000 triángulos y ≤ 18 llamadas por sector; la muestra entera dibuja 77 000 primitivas en 31 llamadas.
**Sin medir en Godot (llamadas, primitivas) ni en el Redmi.**

## 3. Cómo se regenera

1. Turno de Blender: crear `D:\REBELUM_coordinacion\horneado.lock` (nombre y hora) si no existe; borrarlo al acabar.
2. `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P aethelgard/zonas3d/ciudad/kit/fuente/kit_ciudad.py -- aethelgard/zonas3d/ciudad/kit --laminas D:/REBELUM_diagnostico/ciudad_oakhaven/kit/laminas`
   - construye los módulos (cada uno con su semilla: rehacer uno no cambia los demás), hornea con Cycles (OptiX)
     el atlas de luz de lo fijo (2048, 128 muestras) y la luz de las piezas y la vegetación en los vértices, exporta los
     GLB, el atlas y el json, y renderiza una lámina por módulo y la de conjunto (≈ 5,5 min en el PC);
   - `--tramo DIR`: además, el tramo de prueba (§4); `--sin-modulos`: solo el tramo;
   - `--depurar`: en las láminas, las caras de espaldas en magenta (Godot no las dibuja: `cull_back`);
   - `--res N` (atlas), `--muestras N`, `--sin-horneado` (solo construir y contar), `--solo a,b` (no exporta: el
     atlas es de todo el kit).
3. Reimportar en Godot con datos aislados: `godot --headless --path aethelgard --import` (con APPDATA y LOCALAPPDATA
   en una carpeta temporal). Los `.import` los escribe el generador con los ajustes de la muestra (sin LOD, tangentes
   ni mallas de sombra; el atlas en VRAM con mipmaps).
4. Comprobar: `godot --headless --path aethelgard --script res://zonas3d/ciudad/kit/herramientas/comprobar_kit.gd`.

**Láminas fieles al juego.** Las láminas no son un render bonito de Blender: cada material se sustituye por uno de
emisión que hace lo mismo que los sombreados de la muestra (textura × color del vértice × mapa de luz × escala) y
después se aplica el ambiente de la muestra (Filmic con exposición 0,86, contraste y saturación 1,12). Se validó
renderizando así la propia calle aprobada (`muestra_calle/modelos/calle.glb`) con su cámara y comparándola con su
captura de Godot (`D:\REBELUM_diagnostico\ciudad_oakhaven\kit\validacion\`): lo fijo casa; el color de los vértices se
ajustó a mano (potencia 1,5) porque la curva exacta con la que Godot lo lee no está aislada. Sin Kael, sin
niebla, sin brillo ni sombra de contacto.

## 4. Cómo se usa desde el trazado de un sector

**Acabado (recomendado): montar y hornear el sector en Blender con la API del kit**, como `crear_barrio.py`:

```python
import sys; sys.path.insert(0, "<aethelgard>/zonas3d/ciudad/kit/fuente")
import kit_ciudad as KC                      # (importar no ejecuta nada: main solo corre con -P)
sec = KC.K.Sector("terrazas", 4001); KC.K.usar(sec)
M, P, V = KC.Malla(), KC.Malla(), KC.Malla()  # fijo (mapa de luz), piezas y vegetación (vértices)
KC.colocar("vivienda_terrazas", (M, P, V), (x, y, z), giro)      # giro: 0 sur, 90 este, −90 oeste, 180 norte
KC.colocar("escalera_rellano", (M, P, V), (x, y, z))
# … y se hornea como un sector del barrio: K.materiales, K.a_blender(…, True), K.preparar_cycles(sec.anclas),
#   K.hornear(fijo, [piezas, vegetación], img), K.escala_y_guardar(…), K.vacios(sec), K.exportar(…)
```
- **Pivotes**: fachadas, muros, arcos y puertas: la esquina inferior OESTE del frente, ocupan x ∈ [0, W], z ∈ [−F, 0]
  (`huella` del json; lo que vuela, balcones y porches, a z > 0); escaleras y rampas: el borde oeste del primer
  peldaño, suben hacia −z (norte) desde z = 0 (`sube` y `largo` en el json); suelos: x ∈ [0, 4], z ∈ [−4, 0]; atrezo,
  fuente y árboles: el centro de la base. y = 0 es el umbral (o el suelo); las fachadas tienen zócalo hasta −0,6 m
  para asentarse en cuestas.
- **Choques y anclas**: cada módulo deja en el sector sus cajas (`choque()`: las casas, una caja de su huella hasta 3 m;
  el atrezo, la suya) y sus anclas (`puerta`, `puerta_alta`, `paso`, `pie`, `rellano`, `cima`, `sentarse`,
  `vendedor`, `adarve`, `farol_*` y `brasa_*`, que además alumbran el horneado). Lo que se pisa lo manda el trazado
  (`SUELOS`), como en el barrio: escaleras y rampas no llevan choque.
- **Cotas**: `sube` del json es el desnivel de escaleras, rampas y muros de terraza (escalera_recta 0,99 m,
  escalera_rellano 1,98 m, rampa 0,6 m, muro_terraza 2,4 m, muralla 7 m).
- **Repetición**: `corredor_cubierto` (cada 4 m en x), `balaustrada` (3 m), `muro_terraza` (5 m), `muralla_almena`
  (6 m), `empedrado_4x4` y `losas_plaza_4x4` (4 m) encajan sin costura.

**Rápido (maqueta o fondo): el GLB del módulo tal cual en Godot**, ya con su luz horneada suelto (sin las sombras de los
vecinos):

```gdscript
const KitCiudad := preload("res://zonas3d/ciudad/kit/kit_ciudad.gd")
var casa := KitCiudad.instanciar("vivienda_terrazas", sector, Vector3(x, y, z), 0.0)   # viste, choques
var anclas := KitCiudad.anclas(casa)                                                   # {"puerta": Vector3…}
```
`KitCiudad.res_luz = 1024` en el perfil bajo; `KitCiudad.soltar_caches()` al salir. Comparten materiales todos los
módulos: lo fijo de varias casas con el mismo material se dibuja con el mismo programa y la misma textura de luz.

## 5. Tramo de prueba y verificación

**Tramo de prueba (horneado, montado SOLO con el kit)** — `ejecutar_tramo()` / `--tramo`; salidas en
`D:\REBELUM_diagnostico\ciudad_oakhaven\kit	ramo_terrazas\`. Una calle de las Terrazas de 28 m a la cota 0: al
norte, `vivienda_terrazas` (dos), `vivienda_terrazas_escalera` y entre ellas `escalera_rellano`, que sube a la terraza
de arriba (+1,98) con un ciprés y su muro; al sur, el lado BAJO (regla del barrio): `balaustrada` sobre `muro_terraza`,
que baja a la terraza de abajo (−2,4) con cipreses; el suelo, 14 `empedrado_4x4`; atrezo: `glicinia_pergola` (al norte,
al final de la calle), `banco_piedra`, `farol_pie`, `barriles`, `macetas`, `maceta_limonero`. Horneado como un sector
del barrio (`kit_barrio.hornear`: lo fijo con mapa de luz de 2048 y 256 muestras, piezas y vegetación en los vértices,
la escala común): ≈ 40 s.
- Triángulos: 25 640 fijos + 42 386 de piezas (casi todo, las losas: 14 × 2 750) + 20 232 de vegetación = 88 258 (la muestra entera: 58 900 entre calle, piezas y vegetación, tras su recorte; el tramo NO
  está recortado: lo que ninguna cámara ve sigue dentro).
- `comparar_arriba_muestra_aprobada_abajo_tramo_kit.png`: arriba, la captura de Godot de la muestra aprobada
  (perfil medio, cámara «muestra»: 10,8 m arriba y 14,2 m al sur de Kael, −25°, 38°); abajo, el tramo con la MISMA
  cámara, renderizado con la emulación de §3. Se lee como la misma ciudad: entramado, tejas, revoques crema, postigos
  de color, luz rasante de la tarde con sus sombras, losas de la muestra; lo nuevo de las Terrazas (glicinias, escalera
  exterior con geranios, escalinata con rellano y farol, balaustrada) entra en esa paleta.
- `tramo_terrazas_vista_libre_1280x720.png` y `tramo_terrazas_escalera_1280x720.png`: otras dos vistas;
  `tramo_terrazas.glb` + `tramo_luz_2048/1024.png`: el tramo horneado (para meterlo en Godot si se quiere).
- NO está en el juego ni en el banco: es una prueba del kit en Blender.

**Verificación**
- `comprobar_kit.gd` (sin ventana, sobre los GLB importados): **52 módulos, 88 786 triángulos, 0 fallos** (carga, triángulos, solo materiales del kit, choques, anclas, caja y ≥ 2,2 m libres sobre las anclas de puertas, pasos y pies de escalera). La diferencia con el json (≤ 5 % en `carretilla`, `puesto_mercado` y `toldo_mercado`) son caras repetidas o degeneradas que Blender quita al soldar vértices.
- Láminas de cada módulo (`laminas\modulo_NN_<módulo>.png`, 1200 × 900, con su rótulo de medidas, triángulos y
  sector, y la silueta de Kael de 1,70 m al lado) y la de conjunto (`laminas\conjunto_kit_ciudad.png`). Una pasada
  con `--depurar` (`laminas_depuracion\`, de una versión anterior) sirvió para ver caras de espaldas: quedan las de
  los aros de los barriles y los cantos de algunas tejas, que son del kit del barrio (igual en el barrio aprobado).
- Validación de la emulación: `validacionalidar_arriba_godot_abajo_blender.png` (potencia 2,2 del color de
  vértice) y `validacion\g1.5\`, `g1.0\` (las otras pruebas).
- Lo medido es Blender y la importación de Godot en el PC. **Sin medir: llamadas, primitivas y FPS en Godot, y el
  Redmi.**

## 6. Pendiente y dudas

- **Decisiones del usuario**: el aspecto «dorado» de la fuente de la plaza (aquí, tazas de latón; plan §8); si el kit
  sustituye a los constructores del barrio en el acabado de la ciudad; la hora (todo es la tarde dorada de la muestra,
  no la hora azul canónica de Oakhaven).
- **Medir en Godot y en el Redmi**: un sector montado con el kit (llamadas, primitivas, memoria del atlas). El atlas de
  2048 da ≈ 13,6 téxeles/m (el barrio, 16,7); `--res 4096` lo duplica (el PNG pasa de 2,2 a ≈ 8 MB y el horneado, de
  1 a ≈ 4 min). En los sectores horneados enteros el mapa es del sector, no del atlas.
- **Lo que se ve flojo**: las fachadas al sur reciben el sol muy de lado (252°/24°, la luz aprobada) y salen pálidas
  frente a los costados al oeste; la casa de los Pasajes deja ciega la última planta; los módulos sueltos no tienen la
  sombra de sus vecinos (para eso, hornear el sector); hiedra y glicinia son rombos y pirámides (como la hiedra de la
  muestra); `tienda_toldo`, `forja` y `casa_noble` comparten el esquema de `casa_alero`.
- **Emulación de las láminas**: la curva con la que Godot lee el color de los vértices no está aislada (se ajustó a 1,5
  a ojo y por medias: lo fijo casa, las piezas quedan algo más oscuras que en Godot). Las láminas sirven para juzgar
  forma, paleta y luz, no para medir.
- **Sin choque** en balcones, tejados, tendedero, glicinia de muro y ventanas (no se pisan): los pone el trazado.
- `comprobar_kit.gd` no está en `lista_pruebas.txt` (no es de esta carpeta): lo decide el coordinador.
- La importación de Godot creó `pruebas/medir_superficie_barrio.gd.uid` (archivo ajeno, sin commit).
