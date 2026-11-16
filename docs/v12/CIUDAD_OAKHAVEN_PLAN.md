# Ciudad completa de Oakhaven — plano y plan de la maqueta (16/11, PROPUESTA [P])

Encargo del usuario (16/11, mañana): una ciudad completa de Oakhaven, experimental (solo desde el banco de Auditoría,
apagada por defecto), con ≈ 10 veces la superficie EXPLORABLE del barrio ya hecho; primero el PLANO y una MAQUETA 3D
completa, recorrible y a escala de los personajes; después la biblioteca modular de Blender con el acabado aprobado.
NO sustituye a Oakhaven 3D ni a la 2D (siguen siendo el juego). La imagen de referencia es una propuesta visual: no
cambia el canon ni sustituye edificios. Marcas: **[C]** canon (código o documento citado), **[P]** propuesta.

## 0. Fuentes
- Lugares y PNJ de Oakhaven [C]: `ciudades/oakhaven.gd:53-247` (recinto 80×56, casilla = 1 m); resumen en
  `D:\REBELUM_diagnostico\barrio_oakhaven\estudio\canon.md`.
- Canon fijo: `mapa.gd:37-41` («Ciudadela de Oakhaven: el crematorio, la Taberna del Cuervo Oxidado y el Árbol
  Milenario»), `progreso.gd:24-31` (sello raspado del crematorio, tapiz recortado), `progreso.gd:46-48` (Acto I).
- Restricciones: D-033 (nada de Érebo, corazones ni recuerdos antes del acto III), versión neutra D-073 (sin Olvido,
  Aldea Rocío, cripta, trampilla, Cónclave, «crió», diecisiete años), la niebla no se explica, «nadie conoce un secreto
  antes de descubrirlo», vetos de `pruebas/prueba_ciudad_datos.gd`. La biblia v2 dice [P] que el crematorio esconde
  algo bajo tierra: la ciudad NO construye nada bajo el crematorio y su puerta sigue sellada.
- El paquete «Oakhaven: La Corona Viva» no existe en el disco (búsqueda del 15/11): nada sale de él. «Corona» se evita
  en nombres nuevos (roza la corona del Sello).
- Barrio experimental ya hecho: `docs/v12/BARRIO_OAKHAVEN.md` (6 tramos horneados, 3 interiores, vida y misión).

## 1. Medidas: de dónde sale el ×10
| | Barrio actual (medido) | Ciudad completa (objetivo) |
|---|---|---|
| Superficie ANDABLE | **1 055 m²**, todo alcanzable desde el inicio (medido el 16/11 con `pruebas/medir_superficie_barrio.gd`, rejilla de 0,25 m: caravanas 208, plaza 276, talleres 217, comercial 127, residencial 156, atajo 72) | **≈ 10 500-11 500 m²** |
| Caja total | 63 × 48 m (3 024 m²) | ≈ 210 × 185 m (≈ 39 000 m²) |
| Proporción andable / caja | 35 % | 27-32 % (el resto, CONSTRUIDO: casas, patios, tejados, muralla) |
| Recorrido principal | bucle ≈ 128 m; grafo de 15 nodos, 164 m de aristas | eje Puerta del Sur → Árbol Milenario ≈ 190 m; anillo por los 8 sectores ≈ 650-750 m |
| Desnivel | 0 → 1,4 m | 0 → ≈ 16 m (ladera hacia el norte, el Árbol arriba) |

Regla contra el vacío: ningún tramo andable de más de 12 m sin una fachada con puerta, un banco, un puesto o una
vista a cada lado; ninguna plaza de más de ≈ 600 m² (la mayor, la Plaza del Tapiz y su mercado, ≈ 1 200 m² en dos
niveles). Cada sector tiene entre 1 000 y 1 700 m² andables.

## 2. El plano: los 8 sectores encajados en Oakhaven
Coordenadas de la maqueta en metros: x hacia el este, z hacia el SUR (como `trazado.gd`), y hacia arriba. Origen: el
centro de la fuente de la Plaza del Tapiz. Se conservan las relaciones del Oakhaven actual [C]: Puerta del Sur al sur
y la Calle Mayor subiendo al norte hasta la Plaza del Tapiz; el Árbol Milenario y sus Raíces al norte; la Casa del
Concejo al noreste de la plaza; la Taberna del Cuervo Oxidado al oeste por la Calle del Cuervo; el callejón de Pip, la
grieta y el Patio de las Velas al suroeste; la Botica de Selene al sur de la plaza; el Mercado y la Calle de los Oficios
al este; la Colina del Crematorio al noreste; la Torre de la Campana y la ronda al este; el cuerpo de guardia junto a
la Puerta del Sur.

```
 z(m)   x: -100        -60          -20    0    20          60           100
 -90   ┌───────────────────────── MURALLA NORTE ─────────────────────────────────┐
       │  [4] VIVIENDAS ESCALONADAS │    [7] BARRIO ALTO: RAÍCES Y      │ COLINA DEL    │
 -60   │  terrazas y patios (y 6-12)│    ÁRBOL MILENARIO (y 14-16)      │ CREMATORIO [C]│
       │  escalinatas, tendederos   │    jardines, miradores, Concejo   │ (solo fuera;  │
 -30   │                            │    (y 8-10, al NE de la plaza)    │ puerta sellada)│
       │                            ├───── Calle del Árbol ↑ ───────────┤               │
   0   │──── Calle del Cuervo ──────│ [2] PLAZA DEL TAPIZ Y GRAN MERCADO│ [3] CALLE DE  │
       │ [6] PLAZA DE ENCUENTRO:    │  fuente [C], tablón, lonja (y 2-4)│ LOS OFICIOS   │
  30   │ Taberna del Cuervo [C],    │                                   │ talleres en   │
       │ Patio del Cuervo, juegos   │         Calle Mayor ↓             │ rampa (y 3-7) │
  60   │──[5] PASAJES ANTIGUOS: callejón de Pip, grieta,  │ Botica     │ [8] ZONA BAJA │
       │  Patio de las Velas, pasos bajo casas (y 1-3)    │ de Selene  │ almacenes,    │
  90   │                  [1] PUERTA DEL SUR Y CARAVANAS (y 0)          │ Torre [C] y   │
       └──────────────────────────── MURALLA SUR · Puerta del Sur ─────┴───────────────┘
```

| # | Sector (nombre en la ciudad) | Caja aprox. (x; z) | Cota y | Punto de referencia | Función jugable |
|---|---|---|---|---|---|
| 1 | **Puerta del Sur y Caravanas** | -45..45; 55..92 | 0 | La Puerta del Sur [C] con Aldric [C] y el patio de caravanas con el establo | Llegada y salida (la única salida al mapa, como hoy); establo con Avena y Brena; porteadores |
| 2 | **Plaza del Tapiz y Gran Mercado** | -30..45; -15..55 | 0 → 2 → 4 (dos niveles con escalinata) | La fuente de la Plaza del Tapiz [C] (con el aspecto dorado de la referencia [P]) y el tablón del Gremio [C] | Orientación central; tienda [C], puestos, Rosa [C]; reparto de misiones |
| 3 | **Calle de los Oficios** | 45..105; -10..55 | 3 → 7 (rampa al este) | La forja de Maese Ferro [C pendiente] con su chimenea y el taller de Hilda | Artesanos y talleres: Ferro, Hilda, Damián el carretero y el horno de Maela [P, del barrio] |
| 4 | **Las Terrazas** (viviendas escalonadas) | -100..-30; -90..-5 | 6 → 12 (cuatro terrazas) | Una escalinata larga con glicinias y un lavadero en la terraza alta [P] | Viviendas con patios (Odila y Nela [P]), atajos por escaleras, vistas sobre la plaza |
| 5 | **Pasajes Viejos** (callejones) | -65..5; 55..92 | 1 → 3 | El Patio de las Velas [C] y la grieta de Pip [C] | Callejones, pasos bajo casas y corredores cubiertos; secretos [C] (grieta, Canela), Botica de Selene [C] al borde |
| 6 | **Patio del Cuervo** (plaza de encuentro y ocio) | -100..-30; -5..55 | 2 → 3 | La Taberna del Cuervo Oxidado [C] con su letrero | Encuentro y ocio: la posada [C], los juegos de taberna [C: `ciudades/taberna_juegos.gd`], el lugar reservado para la **Feria de los Oficios** |
| 7 | **Barrio Alto de las Raíces** | -30..60; -92..-15 | 8 → 16 | El Árbol Milenario [C] (gigante, visible desde toda la ciudad) y la Casa del Concejo [C] con el tapiz [C] | Jardines y miradores; Doña Encina [C pendiente: no aprobada en canon.md] (guarda del Árbol); el Concejo; la vista del valle |
| 8 | **La Ribera Baja** (almacenes y servicios) | 45..110; 55..95 | -2 → 0 | La Torre de la Campana [C] con la ronda y una acequia con molino [P] | Almacenes, lavaderos, cuerpo de guardia [C] junto a la puerta, Bastián y los faroles [C] |

Conexiones (todas andables con los controles normales; anchos mínimos 2,5 m en calles y 1,6 m en pasajes):
- **Calle Mayor** (S1 → S2): eje norte con escalones bajos; un **soportal** [C: hay soportal junto al cuerpo de guardia] al este.
- **Calle del Árbol** (S2 → S7): escalinata con balaustrada en tres tramos y rellanos (≈ +8 m), el eje visual de la ciudad.
- **Calle del Cuervo** (S2 → S6) [C] y **Calle del Mercado** (S2 → S3) [C]: las dos calles largas este-oeste.
- **Escaleras de las Terrazas** (S6 → S4 → S7): un **atajo** de la taberna al barrio alto sin pasar por la plaza.
- **Paso Cubierto de la Botica** [P] (S5 → S2): corredor bajo una casa, de los Pasajes Viejos a la plaza.
- **Subida de la Colina** [C] (S3 → borde de S7): rampa al pie del crematorio; la puerta sigue SELLADA [C].
- **Ronda en alto** [C] (S8 → torre): adarve sobre la muralla este; mirador.
- **Rampa de los Carros** [P] (S1 → S8): baja de las caravanas a los almacenes; atajo para el porteador.
- **Callejones sin salida con razón**: la grieta de Pip [C] (secreto), el Patio de las Velas [C] (velas y notas), un
  patio de vecinos en las Terrazas con el sitio de una Pieza Huérfana [P], el fondo del almacén con la pista de
  Rastreadores [P], el mirador del Concejo (vista del valle).
- **Pasos bajo edificios y corredores cubiertos**: el Paso Cubierto de la Botica, un arco bajo una casa en los Pasajes
  Viejos, el soportal de la Calle Mayor y la lonja del mercado.

Lo que NO hace la ciudad [C]: no mueve ni duplica el Concejo, el Árbol, el crematorio, la taberna, la torre ni a los
vecinos; no abre la puerta del crematorio ni construye nada debajo; no añade salidas al mapa (solo la Puerta del Sur,
y desde el banco, «Volver al banco»); no explica la niebla; el templo de vidrieras de la imagen NO se construye (no es
canon): en su lugar, un pórtico de piedra entre las raíces [P] sin función narrativa nueva.

## 3. Qué hay en cada sector
| Sector | Qué atrae al jugador | Qué puede descubrir o hacer | Quién vive o trabaja allí | Conexión con el lore | Qué cambia tras una actividad |
|---|---|---|---|---|---|
| 1 Puerta del Sur y Caravanas | La puerta, el bullicio de las caravanas, los caballos | Hablar con Aldric [C]; el establo (Brena y Avena [P]); el porteador Tobías [P] | Aldric [C], guardias [C mundo vivo], Brena, Tobías [P] | Aldric deja salir a Kael en el prólogo [C]; Garon «a caballo antes del alba» [C pv_05] | Tras «Antes de que se enfríe» [P], las caravanas descargan para el horno; **Rastreadores** [P]: las lonas rasgadas empiezan aquí |
| 2 Plaza del Tapiz y Gran Mercado | La fuente, los toldos, el tablón | Tienda [C], tablón del Gremio [C], comprar a Rosa [C], leer el bando [C] | Rosa [C], vendedores [C mundo vivo: frutero, ciruelas] | La plaza del tapiz [C]; «no se nombran en voz alta las aldeas perdidas» [C, bando] | Los contratos cumplidos del Gremio cambian los rumores del mercado; la **Feria de los Oficios** [P] puede instalar puestos aquí |
| 3 Calle de los Oficios | El ruido de la forja, las chispas | Encargos de Ferro [C pendiente: enc_herrero] e Hilda; el taller de Damián [P]; el horno de Maela [P] | Ferro, Hilda [C pendiente], Damián, Maela [P], aprendiz de la forja [C mundo vivo] | El pedido de Maese Ferro [C enc_herrero] | Las **Piezas Huérfanas** [P] se reconstruyen en estos talleres; el carro reparado sale cargado |
| 4 Las Terrazas | Las glicinias, las vistas sobre la ciudad | Escaleras y patios, atajos; la vivienda de Odila y Nela [P]; un patio con una **Pieza Huérfana** [P] | Odila, Nela [P], vecinos [C rutinas], niños jugando [C mundo vivo] | Barrio de vecinos sin canon propio (todo [P]) | Los patios se llenan de ropa tendida y vecinos según la hora [C franjas]; la pieza devuelta aparece en su sitio |
| 5 Pasajes Viejos | Lo estrecho y antiguo, lo escondido | La grieta de Pip [C secreto], el Patio de las Velas [C], la Botica de Selene [C] y «La fórmula desaparecida» [C] | Pip [C], Selene [C], Mirta [C pendiente] | Secretos ya escritos [C]: la grieta, Canela | Tras el secreto de Pip, la grieta queda abierta [C]; las velas cambian con las notas leídas |
| 6 Patio del Cuervo | La taberna, la música, los juegos | Posada [C] (dormir, comer, rumores), juegos de taberna [C], «Tres favores para el Cuervo» [C] | Posadera [C], parroquianos [C voces] | La taberna es el hogar de Kael [C] | Tras «Tres favores» [C], noche gratis; la **Feria de los Oficios** [P] se anuncia y se celebra aquí |
| 7 Barrio Alto de las Raíces | El Árbol gigante, las vistas | Doña Encina [C pendiente: no aprobada en canon.md]; el Concejo [C] y el tapiz [C, no se revela más]; miradores; el arcón del Concejo [C enc_arcon, sitio P] | Doña Encina [C pendiente: no aprobada en canon.md], miembros del Concejo [P] | El tapiz recortado [C], el Árbol Milenario [C] | Los miradores se abren al recorrerlos (se marcan en el Diario como vistas [C sistema de vistas]) |
| 8 La Ribera Baja | La torre, el agua, el trabajo pesado | Almacenes, lavadero, la torre y la ronda [C], «oak_faroles» de Bastián [C]; la pista de **Rastreadores** [P] en el fondo del almacén | Bastián [C], guardias [C], mozos de almacén [P] | La torre de la campana y la ronda [C] | Tras «oak_faroles» [C], los faroles de la ronda encendidos; los almacenes se llenan tras Rastreadores [P] |

Lugares RESERVADOS (sitio y entrada previstos; los sistemas no se implementan en esta fase):
- **Rastreadores** [P]: el patio de caravanas (señales en las lonas) y el fondo del almacén de la Ribera Baja.
- **Piezas Huérfanas** [P]: un patio de las Terrazas (la pieza) y los talleres de la Calle de los Oficios (reconstruirla).
- **Feria de los Oficios** [P]: la Plaza del Tapiz (puestos) y el Patio del Cuervo (celebración).

## 4. El barrio ya construido dentro de la ciudad
El «Arrabal de las Carretas» (6 tramos, 3 interiores) se REPARTE en la ciudad conservando su arquitectura, colores y
luz: su patio de caravanas y establo → sector 1; su calle comercial con el horno y su patio de talleres con el taller
del carretero → sector 3 (al este de Ferro e Hilda, sin tercera forja); su plaza de mercado con la lonja → la lonja del
sector 2; su calle residencial y la vivienda de Odila y Nela → sector 4; su atajo con escalones y hornacina → una de las
escaleras de las Terrazas. Sus interiores (horno, taller, vivienda) se reutilizan tal cual. En la MAQUETA se ponen como
bloques en su sitio; en el acabado se reutilizan sus GLB/kit.

## 5. Arquitectura técnica
- **Escena** `zonas3d/ciudad/ciudad.tscn` + `ciudad.gd` (extends `prototipos/vista3d.gd`), con la API de región del
  barrio (avisar, guardar, iniciar_dialogo, sonda, ancla…). Solo desde el banco: caso `EXPLORAR["ciudad"]`, meta de
  sesión `ciudad_v12`; fuera del banco vuelve a la carga. Carpeta en `recursos.gd` APAGADOS y fuera de las APK sin banco.
- **Plano en datos**: `zonas3d/ciudad/plano.gd` (estático): `SECTORES` (id, caja, cota, vecinos), `CONEXIONES`,
  `ANCLAS` globales (puertas, referencias, reservas), `GRAFO` de la ciudad, `CAMARA_ZONAS`. Cada sector tiene su
  **trazado propio** `zonas3d/ciudad/sectores/<id>/trazado.gd` con el MISMO contrato que el del barrio (SUELOS con
  rampas y escalones, BLOQUES con altura y tipo, `andable`, `altura`, `anclas`, `puertas`) en coordenadas de ciudad.
- **Carga por proximidad**: cada sector es una sub-escena `sectores/<id>/sector.tscn`. Un cargador mantiene montado el
  sector de Kael y sus vecinos dentro de un radio (bajo: el actual + 1-2 vecinos; medio: + 3; PC/alto: todos los que
  se vean), con `ResourceLoader.load_threaded_request` al entrar en el radio de pre-carga (≈ 40 m del borde) y
  descarga con histéresis (≈ 60 m). Lo lejano se ve como **maqueta lejana** de baja resolución (un GLB por sector con
  pocas caras, o impostor) para conservar las vistas (el Árbol desde cualquier sitio). Los interiores NUNCA se cargan a
  la vez: el patrón del barrio (ORIGEN lejano, carga diferida al acercarse a la puerta).
- **Cámara**: la de la muestra (inclinada, sin giro) con zonas locales por sector (como el callejón y el atajo), y
  cámaras de interior.
- **Choques**: un cuerpo por caja (lo medido como mejor), por sector; el suelo con las rampas del trazado.
- **Vida**: los vecinos por sector, con estado lógico fuera de los sectores cargados (patrón de `barrio_vivo.gd`).
- **Presupuesto por perfil** (a medir): bajo (Redmi) ≤ 65 llamadas y ≤ 160 mil primitivas en pantalla, PSS ≤ 950 MB,
  entrada a un sector nuevo sin tirón visible (carga en hilo); medio y alto, más sectores visibles a la vez.
  **Ninguna cifra Android se declara sin medirla en el Redmi.**

## 6. Reparto en agentes (copias aisladas, archivos propios)
1. **M0, contrato y cargador** (un agente; los demás esperan): `zonas3d/ciudad/{ciudad.gd,ciudad.tscn,plano.gd,cargador.gd}`,
   el trazado de ejemplo de un sector, el caso del banco, la meta de sesión, APAGADOS/presets, `pruebas/prueba_ciudad_plano.gd`
   (BFS de toda la ciudad a través de los sectores, conexiones, alturas continuas, cámara con Kael visible) y la prueba
   del cargador (montar/desmontar con histéresis, sin fugas).
2. **Maqueta** (blockout recorrible a escala, con cajas, rampas, escalones, soportales y pasos cubiertos), en paralelo
   tras M0, cada agente SOLO en sus carpetas `zonas3d/ciudad/sectores/<id>/`:
   - A: sectores 1 y 2 (Puerta del Sur, Caravanas, Plaza del Tapiz y Gran Mercado);
   - B: sectores 3 y 8 (Calle de los Oficios, Ribera Baja);
   - C: sectores 5 y 6 (Pasajes Viejos, Patio del Cuervo);
   - D: sectores 4 y 7 (Terrazas, Barrio Alto de las Raíces).
   Los bordes compartidos se acuerdan en `plano.gd` (M0): cotas y anchos de cada conexión.
3. **Biblioteca modular de Blender** (en paralelo desde el principio, carpeta propia `zonas3d/ciudad/kit/`): fachadas
   por oficio y por sector, arcos, puertas, ventanas, escaleras, balcones, tejados, soportales, corredores cubiertos,
   balaustradas, fuentes, toldos, mobiliario y vegetación (glicinia, ciprés), a partir del kit del barrio
   (`zonas3d/barrio/fuente/kit_barrio.py`) sin tocarlo; con láminas de cada módulo y un tramo de prueba horneado.
4. **Coordinador**: integra por cherry-pick, resuelve archivos compartidos, pasa las pruebas, recorre la ciudad.

## 7. Verificación
- Automática (sin ventana): BFS de lo andable de TODA la ciudad (todo conectado desde la Puerta del Sur), alturas
  continuas (sin saltos > 0,3 m), cada conexión andable en los dos sentidos, Kael visible desde la cámara en cada
  casilla andable (rayo a la cabeza sin choque con tejados y aleros), el cargador monta/desmonta sin fugas.
- Con controles normales (clics y teclas, a 1600×720 y 1280×720): recorrer los 8 sectores con Kael y el grupo,
  escaleras, rampas, soportales, pasos cubiertos y bajo edificios, atajos, callejones sin salida, retornos (Volver al
  banco, guardar y cargar en cada sector), visibilidad bajo aleros.
- Medidas de PC por perfil (bajo, medio, alto; resolución indicada): llamadas, primitivas, ms, memoria, tiempos de
  carga de sectores. Redmi: PENDIENTE hasta que se conecte (guion propio).

## 8. Decisiones para el usuario [D]
Los nombres nuevos (Las Terrazas, Pasajes Viejos, Barrio Alto de las Raíces, La Ribera Baja, Rampa de los Carros,
Paso Cubierto de la Botica), el aspecto de la fuente de la Plaza del Tapiz, si la ciudad tendrá agua visible (acequia,
cascada) y si el barrio, en el acabado, sustituirá al «Arrabal de las Carretas» como escena aparte.
