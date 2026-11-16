# Ciudad de Oakhaven (maqueta M0): medidas en el PC

> **Medido en el PC. El Redmi está SIN MEDIR.** Ninguna cifra de este documento vale para Android: los ms del PC no dicen
> nada del Mali-G57, y las llamadas y primitivas solo dicen cuánto se le pedirá. El presupuesto del plan (§5) es para el
> Redmi y solo se cumple o no **midiendo en el Redmi**.

- **Fecha**: 16/11/2026, de 12:54 a 13:20 (rama `area-ciudad-medidas`, desde `area-ciudad-recorrido-2`, 1face66).
- **PC**: NVIDIA GeForce RTX 3050 Laptop (OpenGL 3.3, NVIDIA 621.01) · AMD Ryzen 7 4800H (Godot informa 14 hilos) · Godot 4.7.2, renderizador **Compatibility**. Ningún otro Godot ni Blender abierto (comprobado con
  `tasklist` antes de cada pasada).
- **Ventana**: 1600×720 (`--resolution 1600x720`, la pantalla del Redmi). El proyecto conserva 16:9: se dibuja en
  **1280×720** con franjas negras de 160 px a los lados.
- **Escala y perfil** (siempre fijados con `Engine.set_meta("calidad_proto")`: así el **regulador de calidad NO actúa**;
  la escala es la del perfil, FIJA):

| Pasada | Perfil | Escala 3D | 3D dibujado a | MSAA | Sombras | Tope |
|---|---|---|---|---|---|---|
| bajo | bajo | 0,75 fija | 960×540 | no | no | 30 FPS |
| bajo a resolución completa | bajo + `calidad_extra {"escala_3d": 1.0}` | 1,0 fija | 1280×720 | no | no | 30 FPS |
| medio | medio | 0,8 fija | 1024×576 | no | sí, 24 m, 1 tramo | 30 FPS |
| alto | alto | 1,0 fija | 1280×720 | 2× | sí, 55 m, 2 tramos | 60 FPS |

  Lo que NO se ha medido: el **regulador normal** (perfil del sistema en automática, que baja la escala por escalones
  si no llega). En el PC no actuaría (sobra margen) y en el Redmi es justo lo que hay que medir. El mensaje del juego
  «[calidad] ciudad.tscn: 3D ×0.75 (1200×540)» calcula con el ancho de la VENTANA (1600): lo dibujado de verdad es
  960×540. La pasada «bajo a 0,75» **no es calidad completa**: para eso está la de resolución completa (mismas llamadas
  y primitivas; en el PC, los mismos ms).
- **Herramienta**: `aethelgard/pruebas/medir_ciudad.gd` (medida, NO prueba: no está en `lista_pruebas.txt`). Textos
  completos fuera del repositorio: `D:\REBELUM_diagnostico\ciudad_oakhaven\recorrido\medidas_pc\`
  (`medidas_ciudad_{bajo,medio,alto,bajo_escala100}.txt`, `consola_*.txt` y `experimento\`).

## 1. Cómo se mide

- **Marcas por fotograma** (no `Performance.TIME_PROCESS`, que se publica una vez por segundo): dos nodos en la raíz,
  uno que procesa el primero (prioridad −10⁶) y otro el último (+10⁶). Por fotograma:
  - **real**: de un final de proceso al siguiente (el fotograma entero);
  - **proceso**: del primer `_process` al último (el juego: Kael, cámara, cargador, oclusión, grupo);
  - **herramienta**: lo que gasta la propia medida (rutas A* y clics), que se resta al buscar tirones;
  - **dibujo CPU / GPU**: `viewport_get_measured_render_time_cpu/gpu` (+ preparación del fotograma);
  - **llamadas / primitivas**: `RenderingServer.get_rendering_info(TOTAL_*_IN_FRAME)` del último fotograma dibujado (las
    mismas que `Performance.RENDER_TOTAL_*`, las del barrio: comparables). **Incluyen la interfaz 2D** (20-22 llamadas:
    6 de la interfaz de la ciudad y el resto de los botones comunes del banco y de `Recursos`). En Compatibility las
    pasadas de sombra se cuentan dentro de «visibles» (el reparto de sombras sale 0 en todos los perfiles; en medio y alto
    las primitivas se doblan o triplican por eso).
- **Entrada**: como una persona, clic en «Ciudad de Oakhaven (maqueta, en pruebas)» del banco hasta tener el control
  (escena lista, sin fundido). En frío (la primera del proceso) y en caliente (tras «Volver al banco», con clic).
- **Recorrido**: Kael andando con **clics en el suelo** (en coordenadas de ventana, `root.get_final_transform()`; ruta
  A* por lo andable del plano, como `recorrido_ciudad.gd`), en tiempo real (sin `--fixed-fps`) y con el tope del perfil
  (como se juega), por 10 de las 12 conexiones: Puerta del Sur → Plaza → Oficios → Ribera → Puerta del Sur → Pasajes →
  Cuervo → Terrazas → Barrio Alto → Plaza → Pasajes (faltan la Calle del Cuervo y la Subida de la Colina). Los 21 tramos
  llegan en las tres pasadas.
- **Barrido**: Kael (con Lya y Garon) colocado cada 8 m de lo andable (184 vistas), sin tope: llamadas y primitivas de
  cada vista y sectores montados.
- **Puntos**: la referencia de cada sector (ancla `ref_*` del plano) y las **4 vistas más cargadas** del barrido
  (separadas ≥ 20 m): 3 s con el tope y 3 s sin tope ni sincronía vertical.
- **Experimento** (`experimento=1`): en las vistas más cargadas, cuánto pesa cada cosa ocultándola un momento (el
  juego no cambia).

## 2. Resultados por perfil

### 2.1 Bajo (escala 0,75 fija; 30 FPS)

| Punto | Montados | Llamadas (2D incl.) | Primitivas | ms con tope (med / p95 / máx) | ms sin tope (med / p95) | proceso (med) | CPU dib. / GPU (med) |
|---|---|---|---|---|---|---|---|
| ref. Puerta del Sur | 2 | 53 | 70 718 | 33,3 / 34,0 / 38,4 | 3,9 / 5,2 | 1,15 | 1,11 / 0,63 |
| ref. Plaza del Tapiz | 2 | 46 | 66 758 | 33,3 / 33,8 / 34,1 | 3,5 / 4,3 | 1,00 | 1,00 / 0,54 |
| ref. Oficios | 3 | 45 | 66 802 | 33,4 / 33,8 / 34,2 | 3,7 / 4,5 | 1,14 | 1,03 / 0,53 |
| ref. Terrazas | 3 | 42 | 65 490 | 33,3 / 33,7 / 34,2 | 3,7 / 4,5 | 1,14 | 1,07 / 0,55 |
| ref. Pasajes (Patio de las Velas) | 3 | **79** | 68 860 | 33,3 / 33,9 / 34,2 | 3,8 / 4,8 | 1,13 | 1,11 / 0,53 |
| ref. Patio del Cuervo | 3 | 65 | 67 060 | 33,3 / 33,7 / 34,0 | 3,8 / 4,9 | 1,22 | 1,09 / 0,53 |
| ref. Barrio Alto (Árbol) | 2 | 37 | 64 390 | 33,3 / 33,6 / 35,3 | 3,4 / 4,4 | 0,98 | 0,96 / 0,52 |
| ref. Ribera Baja | 2 | 45 | 67 174 | 33,3 / 33,7 / 34,0 | 3,4 / 4,3 | 1,02 | 0,98 / 0,51 |
| **vista 1**: Pasajes, junto al Arco (−39,9; 80,1) | 3 (puerta_sur, plaza, pasajes) | **95** | 71 440 | 33,3 / 33,9 / 34,1 | 3,8 / 4,9 | 1,13 | 1,17 / 0,54 |
| **vista 2**: Caravanas, terraza oeste (−15,9; 80,1) | 3 (ídem) | **89** | 71 232 | 33,4 / 33,8 / 34,2 | 3,7 / 4,5 | 1,11 | 1,11 / 0,52 |
| **vista 3**: Pasajes, Paso de la Botica (−31,9; 56,1) | 3 (ídem) | **68** (83 en el barrido) | 69 656 | 33,3 / 34,0 / 34,5 | 3,7 / 4,7 | 1,16 | 1,08 / 0,52 |
| **vista 4**: Pasajes, alto de Pip (−55,9; 56,1) | 3 (plaza, pasajes, cuervo) | **78** | 68 904 | 33,3 / 33,9 / 34,4 | 3,7 / 4,8 | 1,15 | 1,13 / 0,53 |

- **Barrido** (184 vistas): llamadas por sector Puerta del Sur 49-91, Plaza 36-80, Oficios 33-69, Terrazas 33-52,
  Pasajes 51-95, Cuervo 44-64, Barrio Alto 32-40, Ribera 42-53. **32 de 184 vistas pasan de 65 llamadas**; ninguna pasa
  de 160 mil primitivas (máx. 71 432). Como mucho 3 sectores montados (el límite del bajo).
- **Andando** (175 s, 5 239 fotogramas): llamadas mediana 52 · p95 **79** · máx **98** (Caravanas, junto a la casa de la
  terraza, −25,3; 83,5); primitivas máx 71 682. Real mediana 33,3 ms; ningún fotograma de más de 50 ms (sin lo de la
  herramienta).
- **Bajo a resolución completa (1,0)**: las mismas llamadas y primitivas en todos los puntos (95, 89, 79…); en el PC, los
  mismos ms (sin tope 3,3-3,7 ms de mediana, GPU 0,44-0,53 ms). La diferencia de coste de los píxeles solo se verá en el
  Redmi.

### 2.2 Medio (escala 0,8 fija; sombras a 24 m; 30 FPS)

| Punto | Montados | Llamadas | Primitivas | ms sin tope (med / p95) | GPU (med) |
|---|---|---|---|---|---|
| ref. Puerta del Sur | 2 | 73 | 133 634 | 3,6 / 4,5 | 0,63 |
| ref. Plaza del Tapiz | 2 | 63 | 132 510 | 3,6 / 4,4 | 0,63 |
| ref. Oficios | 3 | 69 | 136 614 | 3,8 / 4,9 | 0,77 |
| ref. Terrazas | 3 | 63 | 134 562 | 3,7 / 4,6 | 0,64 |
| ref. Pasajes | 3 | 107 | 133 544 | 3,8 / 4,8 | 0,74 |
| ref. Patio del Cuervo | 4 | 84 | 131 980 | 4,1 / 5,1 | 0,62 |
| ref. Barrio Alto | 2 | 57 | 131 602 | 3,6 / 4,4 | 0,61 |
| ref. Ribera Baja | 2 | 64 | 132 546 | 3,6 / 4,6 | 0,67 |
| vista 1: Pasajes, escalera sur (−31,9; 80,1) | 3 | **127** | 140 968 | 4,0 / 5,2 | 0,71 |
| vista 2: Plaza, Paso de la Botica (−23,9; 56,1) | 4 | **119** | 143 960 | 4,0 / 5,0 | 0,75 |
| vista 3: Pasajes, pozo (−47,9; 64,1) | 4 | **112** | 134 640 | 3,9 / 4,8 | 0,72 |
| vista 4: Pasajes, huerto (−55,9; 88,1) | 4 | **126** | 134 520 | 4,1 / 4,9 | 0,69 |

Con tope, 33,3 ms de mediana en todos (p95 ≤ 34,0). Barrido: 114 de 184 vistas pasan de 65 llamadas; primitivas máx.
143 864. Andando: llamadas mediana 75 · p95 116 · máx **138**; primitivas máx **144 462**; hasta 5 sectores montados.

### 2.3 Alto (escala 1,0 fija, MSAA 2×; sombras a 55 m, 2 tramos; 60 FPS)

| Punto | Montados | Llamadas | Primitivas | ms sin tope (med / p95) | GPU (med) |
|---|---|---|---|---|---|
| ref. Puerta del Sur | 2 | 96 | 195 390 | 3,5 / 4,4 | 0,78 |
| ref. Plaza del Tapiz | 2 | 77 | 194 350 | 3,4 / 4,2 | 0,79 |
| ref. Oficios | 3 | 97 | 198 634 | 3,8 / 4,9 | 1,00 |
| ref. Terrazas | 3 | 75 | 196 366 | 3,6 / 4,4 | 0,79 |
| ref. Pasajes | 3 | 145 | 197 222 | 3,8 / 4,7 | 0,94 |
| ref. Patio del Cuervo | 4 | 113 | 193 724 | 4,0 / 4,8 | 0,77 |
| ref. Barrio Alto | 2 | 69 | 193 034 | 3,4 / 4,3 | 0,75 |
| ref. Ribera Baja | 2 | 86 | 194 426 | 3,6 / 4,4 | 0,82 |
| vista 1: Caravanas, paso sur (−23,9; 80,1) | 3 | **179** | 203 000 | 3,9 / 4,8 | 0,76 |
| vista 2: Plaza, callejón sur (−15,9; 56,1) | 4 | **175** | 206 604 | 3,9 / 4,7 | 0,93 |
| vista 3: Pasajes, bajo norte (−39,9; 64,1) | 4 | **173** | 204 484 | 3,9 / 4,6 | 0,95 |
| vista 4: Calle Mayor (0,1; 72,1) | 4 | **154** | 201 438 | 3,9 / 4,8 | 0,78 |

Con tope, 16,7 ms de mediana en todos (p95 ≤ 17,2). Andando: llamadas mediana 106 · p95 168 · máx **189**; primitivas
máx **207 388**; hasta 6 sectores montados. (El alto no tiene presupuesto de Redmi: es la referencia para aparatos
potentes; se da para ver hacia dónde crece.)

### 2.4 Memoria (Godot: estática y de vídeo; NO es el PSS del Redmi)

| | Banco (antes) | Al entrar en la ciudad | Tras el recorrido | Máx. estática |
|---|---|---|---|---|
| bajo 0,75 | 154,7 MB · vídeo 15,9 | 167,7 MB · vídeo 60,8 (texturas 44,1) | 175,8 MB · vídeo 61,2 | 178,7 MB |
| bajo 1,0 | 154,7 · 15,9 | 167,7 · vídeo 63,9 (texturas 47,2) | (sin recorrido) | 175,4 MB |
| medio | 154,7 · 15,9 | 167,8 · vídeo 61,4 (texturas 44,7) | 177,0 · 61,8 | 179,7 MB |
| alto | 154,7 · 15,9 | 167,9 · vídeo 70,9 (texturas 54,2) | 183,4 · 71,4 | 186,2 MB |

Nodos: 520 al entrar (2 sectores), ~700 con 3 montados (bajo) y ~900 con 4-5 (medio y alto). Sin fugas a la vista: la
segunda entrada vuelve a 167,7 MB y 520 nodos.

### 2.5 Entrada y cruces (tirones del cargador)

| | Entrada en frío: hasta el control · peor fotograma | Entrada en caliente | 2 s siguientes (máx) |
|---|---|---|---|
| bajo 0,75 | **990 ms** · 329 ms | 697 ms · 205 ms | 33,9 ms (proceso máx 1,7) |
| bajo 1,0 | 981 ms · 321 ms | 684 ms · 191 ms | 34,4 ms |
| medio | 1 322 ms · 608 ms | 704 ms · 179 ms | 34,1 ms |
| alto | 1 034 ms · 375 ms | 700 ms · 218 ms | 18,1 ms |

(Los peores fotogramas son DURANTE la carga, detrás del fundido de `Recursos`. El barrio: 1,15-1,33 s hasta el control.)

**Montar un sector** (señal `sector_montado`, en su fotograma): en el bajo, 14 montajes y 13 desmontajes en el
recorrido; el fotograma de un montaje sube de ~1,2 ms de proceso a **5,4-8,0 ms** (real 37-40 ms con el tope de 30: un
fotograma algo largo, sin tirón visible en el PC). En medio, máx 7,5 ms; en alto, 7,4 ms (cruces: peor fotograma ±0,5 s
19,6 ms con el tope de 60). Desmontar cuesta 1,4-2 ms. **Esperas del cargador: 0** (la carga en hilo siempre terminó
antes de montar). En cada uno de los 10 cruces de sector, el peor fotograma ±0,5 s fue 34-36 ms (bajo y medio) con
proceso ≤ 3 ms: los montajes ocurren antes, a 25 m del sector, no al cruzar.

Por qué cuesta montar: la carga en hilo solo trae el `sector.tscn` (diminuto); el **blockout, las mallas y los 66-113
cuerpos de choque se construyen en `_ready`, en el hilo principal** (`construir()` fuera del árbol: 3,2-4,7 ms por
sector en el PC; el resto, crear los nodos en el árbol y los cuerpos de física).

### 2.6 Lo que tiene cada sector (fuera del árbol)

| Sector | Mallas (de ellas ocultables) | Triángulos | Rótulos (Label3D) | Choques | construir() |
|---|---|---|---|---|---|
| puerta_sur | 19 (18) | 1 464 | 8 | 84 | 4,0-4,5 ms |
| plaza_tapiz | 29 (28) | 1 396 | 14 | 66 | 3,8-4,0 ms |
| oficios | 20 (19) | 1 600 | 13 | 90 | 4,2-4,3 ms |
| terrazas | 25 (24) | 1 512 | 13 | 93 | 4,1-4,6 ms |
| pasajes | 31 (30) | 1 540 | 15 | 81 | 4,2-4,7 ms |
| cuervo | 22 (21) | 1 242 | 11 | 66 | 3,3-3,5 ms |
| barrio_alto | 10 (9) | 1 560 | 11 | 113 | 4,0-4,3 ms |
| ribera | 12 (11) | 1 072 | 8 | 68 | 3,2-3,3 ms |

Maqueta lejana: 8 mallas, 7 450 triángulos en total (en las vistas medidas, 0 llamadas: queda fuera del cuadro).

### 2.7 De qué están hechas las llamadas y las primitivas (experimento en las 4 vistas más cargadas)

| Vista | Total | − rótulos | − ocultables | − Lya y Garon | − interfaz de la ciudad | − maqueta lejana |
|---|---|---|---|---|---|---|
| bajo, vista 1 (95) | 95 ll. · 71 440 pr. | −26 ll. | −33 ll. | −6 ll. · **−43 182 pr.** | −6 ll. | 0 |
| bajo, vista 2 (89) | 89 · 71 224 | −22 | −31 | −6 · −43 182 | −6 | 0 |
| bajo, vista 3 (68) | 68 · 69 648 | −14 | −19 | −6 · −43 182 | −6 | 0 |
| bajo, vista 4 (78) | 78 · 68 896 | −20 | −24 | −6 · −43 182 | −6 | 0 |
| alto, vista 1 (179) | 179 · 203 000 | −22 | **−96** | −18 · −129 546 | −6 | 0 |
| alto, vista 2 (175) | 175 · 206 596 | −18 | −92 | −18 · −129 546 | −6 | 0 |

- Las **primitivas son casi todas de los personajes**: Lya y Garon, 43 mil en el bajo (130 mil en alto, con las dos
  pasadas de sombra); Kael, unas 20-25 mil (estimado por diferencia). Los bloques de la ciudad suman 3-6 mil a la vista.
- Las **llamadas son de la maqueta**: cada ocultable es su propia malla (76-97 montadas en la zona Pasajes/Caravanas/
  Plaza) y cada rótulo de «(en obras)» o de sector, otra. En el alto, cada ocultable además proyecta sombra en 2 tramos
  (×3).

## 3. Comparación con el presupuesto (plan §5, perfil bajo) y con el barrio

| | Presupuesto bajo | Ciudad, bajo (PC) | Barrio, bajo (PC, §8.4 y §9.3 de BARRIO_OAKHAVEN.md) |
|---|---|---|---|
| Llamadas en pantalla | ≤ 65 | referencias 37-79; vistas cargadas 68-95; andando p95 79, máx **98**; 32 de 184 vistas por encima | 40-66 |
| Primitivas | ≤ 160 mil | 64-72 mil (máx 71 682) | 105-153 mil |
| Entrada a un sector sin tirón | sin tirón visible | PC: montar = 5,4-8 ms de proceso en un fotograma (37-40 ms con el tope); Redmi SIN MEDIR | (no aplica) |
| PSS ≤ 950 MB | Redmi | SIN MEDIR (PC: 168-186 MB estática de Godot) | — |

- **Se pasa: las LLAMADAS del perfil bajo** en el sur-oeste (Pasajes Viejos, junto al Arco y al Paso de la Botica; el
  patio de Caravanas junto a la terraza; la referencia de Pasajes, 79). El resto de la ciudad (Plaza, Oficios, Terrazas,
  Barrio Alto, Ribera) queda en 32-69.
- **Las primitivas sobran** (menos de la mitad del presupuesto y del barrio): la maqueta es de bloques. Cuando lleguen
  los modelos horneados, este margen es el que tendrán.
- **Medio y alto** no tienen cifra de presupuesto en el plan («más sectores visibles a la vez»): en medio, 57-127
  llamadas y hasta 144 mil primitivas; en alto, 69-189 llamadas y hasta 207 mil (más de 160 mil en todas las vistas).

## 4. Propuestas para bajarlo (NO aplicadas)

Por orden de lo que ahorran en el bajo (cifras del experimento §2.7):

1. **Fundir los ocultables contiguos** (−19 a −33 llamadas en las vistas cargadas del bajo; −78 a −96 en el alto):
   hoy cada casa ocultable es una malla. Opciones: (a) una malla por manzana o por grupo de ocultables contiguos, que se
   aclara entera (más superficie aclarada a la vez); (b) **todos los ocultables de un sector en una sola malla** con un
   índice por vértice (UV2 o color) y una lista de «aclarados» como uniforme del sombreado, con el aclarado por **tramado
   en el pase opaco** (sin transparencia): 1 llamada por sector y sin ordenar transparencias; (c) en medio y alto, que los
   ocultables pequeños no proyecten sombra.
2. **Rótulos** (−14 a −26 llamadas): son de la maqueta (nombre del sector y «(en obras)» por cada puerta prevista), con
   contorno. Propuesta: en el bajo, mostrar solo el del sector actual y los de puerta a menos de ~8 m de Kael (o
   `visibility_range_end`), o quitarlos cuando cada sector tenga su modelo; el título de la pantalla ya dice el sector.
3. **Límite de sectores en el bajo**: las vistas por encima son siempre con 3 montados en la esquina Pasajes/Puerta del
   Sur/Plaza. Con `MAXIMO["bajo"] = 2` (el actual y el vecino más cercano) o con `RADIO_MONTAJE` más corto en el bajo
   (p. ej. 15 m) se quitaría un sector entero (≈ 15-25 llamadas) a cambio de ver más maqueta lejana cerca del borde.
4. **Maqueta lejana más simple**: hoy no pesa (0 llamadas en las vistas medidas, 7 450 triángulos); fundir las 8 en una
   sola malla (con los sectores montados tapados por la propia geometría montada) solo ahorraría 1-5 llamadas cuando se
   vea. No es prioridad.
5. **Tirón al montar** (para el Redmi): construir el blockout fuera del hilo principal o repartirlo en varios fotogramas
   (suelos, luego bloques, luego choques), o guardar la malla ya hecha en el `sector.tscn` (que es lo que viene en hilo)
   y **un solo cuerpo de choque compuesto por sector** en vez de 66-113 cuerpos. En el PC son 5,4-8 ms; en el Redmi,
   con una CPU varias veces más lenta, podría pasar de un fotograma de 33 ms: **hay que medirlo allí**.
6. La interfaz 2D cuenta 20-22 llamadas en el total (6 de la ciudad); el presupuesto de 65 las incluye (como en el
   barrio). Si se quiere el presupuesto solo para el 3D, decirlo en el plan; las del 3D en las vistas cargadas del bajo
   son 48-75.

Con 1 + 2 (ocultables fundidos por sector y rótulos solo cerca) las cuatro vistas cargadas del bajo bajarían de 68-95 a
unas 37-40 llamadas (estimación sumando lo medido por separado: total − ocultables − rótulos + 3 mallas fundidas; sin
medir con los cambios hechos), dentro del presupuesto sin tocar el
límite de sectores.

## 5. Pendiente

- **Redmi SIN MEDIR**: FPS reales, PSS (≤ 950 MB), tirones al montar un sector y la escala que deje el regulador normal.
  Ninguna cifra de este documento vale para Android.
- Medir las dos conexiones que el recorrido no anda (Calle del Cuervo, Subida de la Colina).
- Repetir estas medidas cuando los sectores tengan modelo horneado (las primitivas cambiarán mucho; las llamadas, según
  cómo se fundan).
- Decidir (usuario/coordinador) qué propuesta de §4 se aplica; ninguna está aplicada.
