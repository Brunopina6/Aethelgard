# La Garganta del Diablo en 3D: diseño (fase 0) y maqueta jugable (fase 1)

> Propuesta del especialista de gráficos para aprobar. Rama `area-garganta3d` (desde `c74b872`), 09/11/2026.
> Petición del usuario (09/11): «Garganta del diablo hay que empezar a crearla en 3d como en pastos verdes solo que
> garganta del diablo es una mazmorra». El plan 3D la dejaba en 2D hasta después de la alfa; el usuario lo cambia.
> Código: `aethelgard/zonas3d/garganta_3d.gd` y `aethelgard/zonas3d/garganta/`. La 2D (`garganta.gd`) no se toca y se
> queda como alternativa.

## 1. En pocas líneas

- La mazmorra de la 2D, con las mismas piezas en el mismo orden y el mismo progreso, en una garganta cerrada que
  corre de sur a norte, por donde mira la cámara: los muros quedan a los lados y nunca tapan a Kael.
- Dos caminos a distinta altura: el de arriba (P1 → P4) por la cornisa del oeste y el de abajo (P5 → P8) por la del
  este, 8 m más abajo. Entre ellos, el abismo, con un fondo de ámbar que brilla entre la niebla.
- Lo que cruza el abismo se ve de perfil: la escalera de la presa, el ascensor (una cesta colgada de un cable) y el
  puente levadizo que baja la palanca. El nido está en una repisa del abismo, bajo P6: se ve brillar desde los puentes.
- Paleta propia de mazmorra: roca fría en capas, luz del cielo desde una rendija, rebote cálido, niebla azul que se
  vuelve ámbar al bajar y acentos de fuego en el camino. Nada de cielo ni de pradera: es lo contrario de Pastos Verdes.
- Se juega ya, de la entrada al nido y a Gorthor, con `-- 3d garganta3d`. La APK sigue llevando la 2D.

## 2. De la 2D a la 3D

### 2.1 La estructura que se conserva (`garganta.gd`)

- Circuito: arriba P1 entrada → P2 puentes colgantes → P3 puerta sellada → P4 Gorthor; abajo P5 cornisas I → P6
  cornisas II → P7 palanca → P8 grieta oculta; el nido, bajo P6; P1 y P5 unidos por una escalera tallada.
- La palanca de P7 abre la puerta de P3, baja un puente de P7 a P3 y enciende el ascensor de P5 a la entrada.
- Encuentros: muchos en los puentes (×2), pocos en las cornisas de abajo (×0,5), ninguno en el resto.
- Combates fijos: el nido (grupo 6, el gólem de ámbar y un Grimfang) y Gorthor (grupo 5, jefe); si se pierde, se
  vuelve un poco antes del disparo.
- Secretos: el cofre raro del nido (300 monedas, 2 Éter y un Incienso de Ceniza), los pilares del anillo (P2) y el
  pilar del peregrino (P8).

### 2.2 Planta de la 3D

```
                         NORTE (z = −42): muro del fondo y la cascada
   ┌──────────────────────────────────────────────────────────────────────┐
   │ P4 ARENA sobre su pilar (Gorthor, trono)  ║cascada║   P8 GRIETA       │
   │      ▲ disparo z < −26                     ║      ║   (pilar del       │
   │ ─── puerta sellada (P3/P4) ───             ║      ║    peregrino)      │
   │ P3  guardado 2                             aguja ── paso bajo        │
   │ P3 ◄═════════ puente levadizo (lo baja la palanca) ═══════► P7 palanca│
   │ P2 puente colgante 2         ┌─────────┐                      P6      │
   │ islote (pilares del anillo)  │  NIDO   │◄── bajada tallada ── P6      │
   │ P2 puente colgante 1         └─────────┘ (repisa a −14 m)     P6      │
   │ P1 ascensor ~~~~~~~~~~~~~~~ cesta y cable ~~~~~~~~~~~~~~~~~~~ P5      │
   │ P1 ════════════════ escalera de la presa ═══════════════════► P5      │
   │ P1 entrada, guardado 1         hondonada de la boca (niebla)          │
   └──────────────── SUR: salida al mapa (z = 42,5) ──────────────────────┘
     oeste: cornisa alta, y = 0     abismo (x −8 … +7)     este: cornisa baja, y = −8
```

Escala: una casilla de la 2D es un metro (cada «pantalla» de 20 casillas es lo que abarca la cámara a 20 m). Las piezas
siguen el orden de la 2D con z = 40 − x (x en casillas).

| Pieza | 2D (casillas) | 3D (x, y, z en m) | Notas |
|---|---|---|---|
| Entrada y salida | (3, 10.8); salida en x < 0,6 | entra en (−12, 0, 37); salida en (−12, 0, 42,5) | disco dorado y «Mapa del mundo», como Pastos |
| Guardado 1 | (5, 8.6) | altar en (−14,4, 0, 35) | cristal verde y blanco, como el brillo de la 2D |
| Escalera P1 → P5 | x 9..12 | z 28..31, de (−8, 0) a (7, −8): 20 escalones de 0,4 m | sobre la presa que cierra el abismo |
| Ascensor | x 19 (13,4 y 31,6) | z 22: (−9,6, 0) arriba y (8,6, −8) abajo | cesta en un cable; parada sin la palanca |
| Puentes colgantes | (25, 10.8) 8 casillas; (34,5, 10.8) 9 | z 19 → 11 y 10 → 1, por x = −12 | sobre dos huecos de la cornisa |
| Pilares (detalle «p2») | (29,5, 9.0) | islote z 9..12, se examina en (−14,3, 0, 10,5) | anillo más gastado cuanto más lejos |
| Guardado 2 | (48, 8.6) | (−14,4, 0, −8) | |
| Puente de la palanca | (52, 22.5), de P7 a P3 | levadizo en z = −12: bisagra (−7,6, 0), apoyo (8,6, −8) | levantado, de pie; cae al tirar |
| Puerta sellada | (60, 11.9); paso x 58..62 | (−12, 0, −20); paso de 2,5 m | se hunde en el suelo |
| Arena y Gorthor | x 62..78; disparo x > 66; vuelta (63, 10.8) | centro (−8,5, 0, −31), radio 9,5; disparo z < −26; vuelta (−12, 0, −23,2) | Gorthor espera ante el trono |
| Palanca | (47, 33.2) | (13, −8, −7) | |
| Paso bajo y grieta | x 60..65 y 65..77 | z −20..−25 y −25..−38,5 | entre el muro y una aguja de roca |
| Pilar del peregrino («p8») | (72, 34.2) | (12,6, −8, −32) | obelisco con velas y un hilo de luz |
| Bajada al nido | x 29..32 | escalera z 19 → 11, x 4,5..6,5, de −8 a −14 | tallada en el acantilado |
| Nido y cofre | nido x 22..40; cofre (31, 50.6); disparo y > 47,4; vuelta (30,8, 44) | repisa centro (1,5, −14, 7); cofre (1,1, −14, 6,6); disparo a 4,2 m del cofre; vuelta al pie de la bajada (5,5, −14, 10,5) | |
| Brillo del nido | (30, 24), pintado en el abismo | el nido de verdad, 14 m bajo los puentes | se ve desde los dos puentes |

### 2.3 Por qué la garganta corre de sur a norte

La cámara de juego mira siempre al norte, a 45° y 20 m, y nunca gira (`prototipos/vista3d.gd`). Se probaron tres
orientaciones sobre el papel:

- **Este-oeste, como la 2D:** los muros del lado de la cámara taparían a Kael en el camino de ese lado, y el fondo del
  abismo quedaría siempre detrás de la cámara.
- **Los dos caminos en la misma pared:** lo de abajo queda tapado por lo de arriba o fuera del encuadre.
- **Sur-norte, la elegida:** la cámara está siempre dentro de la garganta, entre los dos muros. Los muros enmarcan la
  pantalla a los lados y no se interponen. El jugador avanza «hacia dentro» de la pantalla y ve lo que le espera. El
  fondo del abismo queda delante y abajo, a la vista. Lo que cruza el abismo se lee de perfil.

## 3. Cámara

- **La de siempre** (Pastos Verdes): 45°, la distancia que elija el jugador (9 a 34 m; rueda, pellizco, + y −).
- **Zonas** (`trazado.gd`, `CAMARA`): al entrar en una zona, la inclinación y los límites de distancia cambian
  suavemente (unos 0,5 s). La distancia del jugador se respeta dentro de lo que permite cada zona.

| Zona | Inclinación | Distancia | Para qué |
|---|---|---|---|
| Entrada | 40° | 16..26 m | ver la garganta por delante al llegar |
| Puentes colgantes | 53° | 16..24 m | asomarse al abismo: el nido brilla abajo |
| Paso de la puerta | 50° | 12..18 m | tramo estrecho: más cerca y más desde arriba |
| Arena | 42° | 18..28 m | que quepan Gorthor, el trono y la cascada |
| Bajada y nido | 52° | 12..18 m | dentro del abismo: no se ve el acantilado de enfrente |
| Paso bajo y grieta | 54° | 11..16 m | el tramo más estrecho |

- **Tramos estrechos.** Como la garganta va a lo largo de la cámara, ningún muro queda entre la cámara y Kael. Kael
  no se pega al muro (margen de 1,3 m), así que la cámara nunca entra en la roca, ni con la distancia máxima. Los
  muros solo se hunden hacia dentro de su línea, nunca hacia el camino.
- **Lo que sí puede tapar** (el marco de la puerta, los pilares, el obelisco) se vuelve medio transparente, como los
  árboles de Pastos (grupo `ocluye`).
- **La palanca:** mientras cae el levadizo, la cámara mira un momento hacia el puente y vuelve a Kael (unos 5 s, sin
  control).
- **Las cadenas del levadizo** se sueltan al bajarlo. Antes cruzaban la garganta justo delante de la cámara de la
  arena (captura del 09/11).

## 4. Dirección visual

**Composición.** La cascada que cae del muro del norte es el hito: se ve desde casi toda la garganta. La arena,
sobre su pilar de roca, queda ante ella. El abismo se abre delante y abajo, y la luz cae en haces desde la rendija.

**Luz.**
- La luz del cielo entra por la rendija desde el este, muy alta. Ilumina el muro del oeste (el fondo del camino de
  arriba, más abierto y con más esperanza) y deja en sombra el del este (el camino de abajo, más misterioso).
- La sombra se lee azulada (relleno frío).
- Un rebote cálido de la pared al sol aclara la pared en sombra. Va dentro del sombreado de la roca: no es una luz
  real, que en Compatibility redibuja todo lo que toca.
- Desde el fondo sube un resplandor de ámbar que enciende la roca de abajo.

**Paleta.**
- Roca gris pizarra en capas (ocre, gris y oscura), con chorreones verticales y grietas finas.
- Musgo oliva en lo que mira arriba.
- Niebla azul y violeta arriba que, al bajar, se vuelve ámbar.
- Fuego cálido en los faroles, los braseros y los rescoldos.
- Verde y blanco en los altares de guardado, como el brillo de la 2D.
- Bronce en el anillo partido.

**Materiales.** Un único sombreado de roca (`materiales.gd`, `SHADER_ROCA`) para todas las paredes y cornisas:
- triplanar con grano, grietas y gravilla;
- color por vértice: estratos, chorreones, oclusión al pie de los muros y huecos más oscuros;
- tinte de niebla con la profundidad, resplandor de ámbar del fondo y rebote.
- Mapa de normales solo en los perfiles medio y alto.

**Formas.**
- Muros y acantilados son rejillas de roca hundidas con ruido, con estratos que forman cornisitas y ranuras cada
  2,5 a 4 m y diaclasas verticales.
- Los bordes de los huecos de los puentes están rotos.
- Las mallas se generan por código (`roca.gd`) y salen igual cada vez (semillas fijas).

**Lo que cuenta el escenario.** Todo es visual, sin textos nuevos; la marca indica si es canon [C] o propuesta [P].
- [C] El anillo partido en los pilares de los puentes, más gastado cuanto más lejos. Los cuatro pares van de nuevo
  (0) a muy gastado (0,8): más fino, más roto y más apagado.
- [C] La puerta sellada con el anillo partido y el pilar del peregrino «gastado por miles de manos», con un anillo
  grande, liso y que brilla un poco.
- [C] Gorthor esperando en su arena («Aquí espera Gorthor el Devorador»): el goblin del combate, al doble de tamaño y
  teñido de rojo, como en `combate.gd`.
- [C] El gólem de ámbar en el nido (`combate.gd`: el gólem del nido): el guardián de piedra teñido de ámbar, dormido y
  medio hundido, que «respira» con un brillo lento.
- [C, propuesta de la biblia] La Vía del Peregrino por el camino de arriba: losas gastadas (faltan algunas), faroles
  de piedra, mojones de piedras apiladas.
- [P] Cintas de colores atadas a los pasamanos de los puentes.
- [P] Un campamento Grimfang en la cornisa de abajo: hoguera con rescoldos, troncos, cobertizo de pieles y huesos.
- [P] Tótems y estandartes rojos del clan en la arena.
- [P] La cascada y el ámbar del fondo. El ámbar es coherente con el gólem de ámbar; no explica nada.
- Nada sobre Érebo ni sobre corazones o recuerdos (D-033), ni detalles de otras obras.

**Diferencia con Pastos Verdes.** Allí, mañana luminosa, cielo, hierba y saturación 1,3. Aquí no se ve el cielo:
- profundidad en capas, roca fría, contraste entre luz y sombra;
- saturación 1,1 y contraste 1,12;
- un color propio para lo que brilla (el ámbar).
Comparte el estilo (formas redondeadas, legibles a 20 m, luz cálida con emisión y halos pintados) y la interfaz.

## 5. Progreso y partidas

- **Los mismos identificadores que la 2D**, así que una partida avanzada en la 2D vale en la 3D y al revés:
  - `mazmorras.garganta.palanca`;
  - el cofre `2_1984_3238` (el `_id_cofre` de la 2D: casilla (31, 50.6) × 64 px);
  - los combates `garganta_nido` y `garganta_gorthor`;
  - los detalles `garganta_puentes` y `garganta_pilar`.
  Si la palanca ya se tiró en la 2D, en la 3D la puerta está abierta, el levadizo bajado y el ascensor encendido.
- **Guardado:**
  - automático al entrar, en los dos altares, tras la palanca, tras el cofre, tras cada combate (`combate.gd`) y al
    pausar o cerrar la app (`guardar_posicion`);
  - posición en `pos_3d`, `pos_3d_ok` y `pos_3d_lugar = 2`, como Pastos Verdes;
  - con un combate fijo en marcha, se guarda el sitio de vuelta.
- **Partidas guardadas dentro de la Garganta 2D:**
  - `modo3d.escena_equivalente()` las lleva a la 3D, al sitio equivalente (la ancla del trazado más cercana a
    `pos_zona`);
  - **falta que `progreso.gd` lo use** (cambio pedido, §11). Hasta entonces, cargar una partida guardada dentro de la
    2D abre la 2D aunque la 3D esté activa (la prueba lo avisa);
  - entrar desde el mapa y volver de un combate ya llevan a la 3D.
- **Una partida guardada en la 3D con la Garganta 3D apagada** (sin el argumento) vuelve a la 3D al cargarla: lo
  decide `progreso.gd`, porque la escena existe en la APK experimental. Solo puede pasar en el PC con el argumento.

## 6. Encuentros y combates

- **Al azar:** como Pastos (un paso cada 0,5 m, 40 pasos seguros, probabilidad 0,012) por el ritmo de la 2D:
  - ×2 en los puentes y el islote;
  - ×0,5 en P5 y P6 (la cornisa de abajo, al sur de z = 0);
  - 0 en el resto (la escalera, el nido, la arena, la grieta…).
  Zona «garganta» para el nivel, la experiencia y el fondo del combate.
- **El nido:**
  - al pisar el nido (a 4,2 m del cofre), «¡Algo se mueve en el nido!» y el combate del grupo 6;
  - se vuelve al pie de la bajada;
  - ganado, el gólem desaparece y el cofre se puede abrir.
- **Gorthor:**
  - al entrar en la arena, «¡Gorthor el Devorador!» y el combate del jefe (grupo 5, tipo «jefe»);
  - se vuelve ante la arena;
  - ganado, Gorthor y el fuego de los braseros desaparecen, y al entrar sale «La arena guarda silencio. Gorthor ya no
    espera a nadie.» (el texto de la 2D).

## 7. Presupuesto para el Mali-G57 del Redmi

**Objetivo.** El perfil bajo a 30 FPS, como Pastos Verdes, y el perfil alto sin rebajarse. Lo que cambia con el
perfil son cantidades y resolución, nunca la paleta ni la composición.

| | bajo | medio | alto |
|---|---|---|---|
| Rejilla de la roca (a lo largo × en altura) | 1,15 × 1,2 m | 0,9 × 0,95 m | 0,65 × 0,7 m |
| Mapa de normales de la roca | no | sí | sí |
| Sombras del sol | no | 2 tramos, 30 m | 2 tramos, 55 m, 4096 |
| Capas de niebla del abismo | 1 | 2 | 3 |
| Haces de luz | 3 | 5 | 7 |
| Hierba seca (matas) | 520 | 950 | 1 600 |
| Polvo / brasas (partículas) | 22 / 14 | 40 / 30 | 70 / 60 |
| Cuervos | 3 | 4 | 5 |
| Luces reales | 0 (halos pintados) | 0 (halos pintados) | 4 faroles y 2 braseros |
| Resplandor (glow) | no | no | sí |
| Capas de la cascada | 1 | 2 | 2 |

**Qué hay en cada perfil.** Contado con `pruebas/medir_garganta3d.gd … conteo` el 09/11, en el PC, sin ventana: es la
escena entera, no lo que se ve a la vez; comprobado ejecutando, sin tiempos.

| | bajo | medio | alto |
|---|---|---|---|
| Triángulos de roca (26 mallas) | 39 500 | 62 800 | 106 200 |
| Triángulos de todas las mallas, personajes incluidos (sin MultiMesh) | 192 200 | 216 000 | 259 800 |
| Nodos de malla (cada uno, al menos una llamada de dibujo si se ve) | 173 | 181 | 188 |
| MultiMesh (instancias: losas, hierba seca, raíces…) | 15 (928) | 15 (1 358) | 15 (2 009) |
| Mallas transparentes (halos en el aire, nieblas, haces, cascada) | 40 | 43 | 46 |
| Partículas | 36 | 70 | 130 |
| Luces reales | 0 | 0 | 6 |
| Carga de la escena en el PC | 1,5 s | 1,6-2,5 s | 1,7 s |

La referencia medida en el Redmi (`docs/guia_visual.md`, perfil medio de Pastos Verdes, 30 FPS sin tirones) es de
unas 140 llamadas de dibujo y 325 000 triángulos **a la vista**. Aquí la escena entera queda por debajo en triángulos.
En llamadas de dibujo hay que medir lo que entra en cuadro: las piezas fijas ya van juntas por material (de 243 nodos de
malla a 173 en bajo, sin cambiar nada de lo que se ve).

**Qué puede costar más en el Mali** (que va justo de GPU; lo medido en Pastos):
- las transparencias grandes: niebla, haces y halos;
- las lecturas de textura de la roca por píxel: 7 en bajo, 10 con normales;
- las sombras;
- el resplandor del perfil alto.
Preparado sin aplicar, porque no se ha medido: quitar la gravilla o las grietas en bajo (−1 y −3 lecturas), una sola
capa de niebla más baja o haces más estrechos. Calidad visual primero: no se rebaja nada sin medirlo.

**Medida.** `pruebas/medir_garganta3d.gd` (modo `manual` en la lista). Un proceso por perfil, con ventana y sin tope
de FPS, recorre:
1. la entrada;
2. los puentes;
3. un puente asomado al abismo (el peor caso de niebla y fondo);
4. el paso de la puerta;
5. la cornisa baja;
6. la bajada al nido;
7. la palanca con el puente cayendo;
8. la arena;
9. la grieta;
10. un combate con su carga y su vuelta.
Escribe `medicion_garganta3d_<perfil>.json` (mediana, p95, p99, picos, memoria, llamadas de dibujo y cargas). Pendiente
del hueco que dé el coordinador, en el PC y en el Redmi.

## 8. Recursos y procedencia

- **Nuevos:** ninguno. Todo se genera por código al cargar:
  - texturas de ruido (`NoiseTexture2D`);
  - mallas de roca, puentes, nido, piezas y decorado;
  - sombreados propios (roca, niebla, fondo, haces, cascada, hierba seca).
- **Ya del proyecto:**
  - Kael (`kael.fbx`) y el grupo (`grupo_3d.gd`);
  - el goblin (`goblin.fbx`, `hacha.obj`) para Gorthor;
  - el guardián de piedra (`modelos/guardian/`) para el gólem;
  - los pájaros de `prototipos/fauna_simple.gd`, en negro, como cuervos;
  - la fuente del título.
  Sus licencias son las que ya tenían; no se añade nada a `licencias_pendientes.txt`.
- **Blender 5.2 no ha hecho falta en esta fase.** Puede servir más adelante para piezas de detalle (relieves del
  anillo, el trono).

## 9. Sonido (lo engancha el especialista de sonido)

- **Ya suenan los mismos efectos que en la 2D:**
  - `guardado`, `palanca` y, con retraso, `puente_baja`;
  - `ascensor` y `atascado`;
  - `cerrada`;
  - `cofre` y `tesoro`;
  - `emboscada`;
  - `examinar`, y `pagina` con `misterio` al completar un acto.
- **Pendiente** (en `garganta_3d.gd`, `_sonido_3d`, con la API que ya usa Pastos Verdes 3D):
  - el oyente en Kael (`Sonido.oyente_3d`);
  - los pasos según el suelo (`madera` en los puentes colgantes, el levadizo y las estaciones del ascensor; `piedra`
    en lo demás);
  - la cascada (`Sonido.fuente_3d` al pie, hacia (3,6, −20, −40));
  - el viento del abismo a lo largo de su eje;
  - las gotas.
- **El ambiente:** `musica.gd` aún no conoce esta escena, así que suena «silencio». Cambio pedido: que
  `res://zonas3d/garganta_3d.tscn` use el contexto «mazmorra», como `garganta.tscn`.

## 10. Cómo se activa

- **Ahora:** con la exploración 3D y el argumento:
  `Godot --path aethelgard -- 3d garganta3d` (o la escena suelta, `zonas3d/garganta_3d.tscn`).
- **Sin el argumento,** también en la APK experimental, el mapa lleva a la Garganta 2D. La APK estable excluye
  `zonas3d/*`: no cambia nada.
- **Activarla por defecto,** cuando la 3D supere las pruebas y la medida en el Redmi:
  1. quitar `GARGANTA: "garganta3d"` de `EN_PRUEBAS` en `modo3d.gd`;
  2. hacer los cambios de `progreso.gd` y `musica.gd` del §11;
  3. en la lista de pruebas, el argumento `garganta3d` deja de hacer falta (no estorba).

## 11. Cambios que se piden en archivos de otros

- **`progreso.gd`, en `restaurar()`:** justo después de
  `var escena: String = d.get("escena_guardada", MAPA)`, añadir:

  ```gdscript
  	var en_3d: String = load("res://modo3d.gd").escena_equivalente(escena)   # mazmorra 2D con versión 3D en uso
  	if en_3d != "":
  		escena = en_3d
  ```

  `escena_equivalente` ya deja `pos_3d` en el sitio equivalente. `prueba_garganta3d` lo comprueba (paso 11c) en cuanto
  esté.
- **`musica.gd`, en `contexto_de()`:** añadir `"res://zonas3d/garganta_3d.tscn"` al caso de `"res://garganta.tscn"`
  («mazmorra»). Y en `pruebas/prueba_musica.gd`, la escena con ese contexto.
- **`.uid` de los scripts nuevos:** los creará el editor al abrir el proyecto. No se han generado aquí para no
  reimportar en esta copia.

## 12. Pruebas

| Prueba | Modo | Qué comprueba |
|---|---|---|
| `prueba_garganta3d` | auto | Ver lista debajo |
| `prueba_garganta3d_fotos` | ventana | Las capturas de los sitios clave en los perfiles bajo y alto, una vista de lejos y el plano desde arriba |
| `medir_garganta3d` | manual | La medida (§7) y el conteo |

`prueba_garganta3d` recorre la mazmorra de verdad (escenas, física, `combate.tscn`):
- modo3d: la 3D solo con el argumento;
- los identificadores de la 2D y las equivalencias de posiciones;
- por dónde se anda;
- del mapa a la 3D por la entrada;
- los puentes cruzados andando, con el grupo detrás;
- los pilares;
- sin la palanca: el ascensor parado y la puerta cerrada, que no deja pasar;
- la escalera de la presa;
- la palanca: el levadizo se cruza en los dos sentidos, la puerta se cruza y el ascensor sube;
- el nido: su combate se gana y no se repite;
- el cofre raro: una sola vez, y la partida guardada lo lleva;
- Gorthor: se pierde, se vuelve antes de la arena y el combate no se repite;
- guardar en el altar y cargar;
- salida al mapa y vuelta a entrar en la 3D;
- partida de la 2D llevada a la 3D.

## 13. Siguiente paso

- **Medir** en el hueco del coordinador (PC y Redmi). Ajustar con antes y después si el perfil bajo no llega a 30 FPS.
- **Recorrido del ascensor:** la cesta cruzando el abismo con Kael dentro, en vez del fundido a negro.
- **Revisión del usuario:** que mire las capturas y diga si la orientación y la paleta le convencen antes de pulir.
- **El sonido 3D** y el ambiente (§9).
- **Más vida:** murciélagos al pasar por la grieta y polvo que cae de los puentes al cruzarlos.
- **Gorthor:** que se levante del trono al acercarse; necesita animación.
