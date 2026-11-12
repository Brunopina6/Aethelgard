# Firmamento de los Ecos — tablero de Orbes Cristalinos (V12, 12/11/2026)

**Estado: PROTOTIPO APAGADO. Nada de este documento está aprobado.** Los tres conceptos visuales, los valores de los
nodos, los precios y la forma de conseguir orbes esperan la decisión del usuario. Con el interruptor apagado el juego
es exactamente el de antes (lo comprueba `prueba_firmamento`, y `prueba_combate_huella` sigue igual).

## 1. Cómo se enciende y dónde está

| Qué | Cómo |
|---|---|
| Interruptor | `Engine.set_meta("orbes_v12", true)` o el argumento `-- orbes_v12`. Por defecto, apagado (`orbes.gd ACTIVO_POR_DEFECTO`). |
| En el teléfono (solo APK de Auditoría) y en el editor | Ajustes → «Firmamento de los Ecos (prueba)» → Encendido (`user://ajustes.cfg`, `[firmamento] activo`). En las versiones normales esa línea no sale y el interruptor no lee Ajustes. |
| Entrada | Menú → Grupo → botón «Firmamento · N orbes» junto a los héroes (abre el tablero del héroe de la ficha). |
| Probar compras | Botón «+10 (prueba)» del panel, **solo** en Auditoría o en el editor (`Orbes.conceder_prueba`, `OS.has_feature("auditoria")` o `"editor"`). |
| Comparar conceptos | Botón «Concepto n/3» del panel (se recuerda en `user://ajustes.cfg [firmamento] estilo`). En el editor: F6 sobre `firmamento/firmamento_demo.tscn` (enciende el interruptor solo en esa sesión y da 30 orbes de prueba). |

Archivos: `aethelgard/firmamento/` (`orbes.gd` servicio, `firmamento_datos.gd` configuración editable,
`firmamento.gd` pantalla, `firmamento_lienzo.gd` dibujo, `pincel.gd` lote de triángulos, `shaders/` fondos,
`firmamento_demo.*`); pruebas `pruebas/prueba_firmamento.gd` y `pruebas/fotos_firmamento.gd`. Compartidos, con bloques
pequeños: `grupo.gd` (`estadisticas()`), `equipo_extra.gd` (final de `efectos_de()`), `progreso.gd` (clave
`firmamento` en `CLAVES`) y `menus.gd` (botón de la ficha y línea de Ajustes).

## 2. Reglas

- **Moneda: Orbes Cristalinos.** Un saldo común para todo el grupo (decisión pendiente: común o por héroe; ver §9).
- **Única entrada: `Orbes.ganar(cantidad, motivo)`.** Devuelve el saldo nuevo, ignora cantidades ≤ 0 y apunta los 30
  últimos `[motivo, cantidad]` en el historial (para medir la economía). **No hay ninguna fuente permanente
  implementada**: ni enemigos, ni tiendas, ni misiones, ni cofres. Con el interruptor apagado, `ganar` no hace nada.
- **Un tablero por protagonista** (Kael, Lya, Garon; Naira solo con su interruptor `naira_v12`, provisional).
  21 nodos cada uno: un nodo inicial junto al símbolo del centro que abre **dos caminos**, y una **Memoria** abajo (o
  arriba, en Lya) que une los dos caminos por un rodeo.
- **Requisitos**: cada nodo pide uno de sus nodos anteriores (`req`); los excepcionales piden **todos** (`"todos":
  true`, los dos avanzados de su camino). No hay exclusiones: todo nodo despierto acaba siendo alcanzable; elegir es
  elegir el **orden**, no perder nada (sin elecciones trampa).
- **Estados**: bloqueado · disponible · caro (requisitos sí, orbes no) · despertado · **dormido** (lo que daría no tiene
  aún gancho en el combate: se ve y se explica, pero no se compra ni bloquea a nadie; despierta solo cuando su efecto
  exista en `equipo_extra.gd EFECTOS` con su gancho en `HECHOS`).
- **Comprar pide confirmación**: tocar el nodo lo elige; «Despertar · N orbes»; «Confirmar: gastar N» / «Cancelar».
  Con teclado o mando, Intro dos veces; Esc cancela.
- **Las bonificaciones se calculan al vuelo** a partir de los nodos despertados (`Orbes.bonos`), dentro de
  `grupo.estadisticas()` y `equipo_extra.efectos_de()`: los atributos guardados no cambian nunca, así que **cargar
  una partida no puede aplicarlas dos veces**. Llegan a todo lo que ya usa esas dos funciones: ficha del Grupo,
  combate (`combate.gd` las lee al empezar: ataque, defensa, PV/PM máximos, velocidad del ATB, multiplicador y extra
  de magia, crítico, esquiva, coraza, réplica, cubrir, robo de vida, regeneración, Aliento), curar, subir de nivel y
  la tienda. No hay estadísticas paralelas y `combate.gd` no se ha tocado.
- **Topes**: los efectos se suman con el **mismo tope** que el equipo (`EFECTOS[k]["max"]`): por ejemplo, el crítico
  extra entre accesorios y tablero no pasa de +30 %.
- **Apagado = sin efecto**: si una partida trae nodos (de cuando estaba encendido) y el interruptor está apagado, los
  datos se conservan pero no suman nada.
- **Guardado**: `Engine["firmamento"] = {"orbes", "nodos": {héroe: [ids]}, "gastados": {héroe: n}, "historial"}`,
  en `progreso.gd CLAVES`. Solo se crea al ganar o gastar orbes: con el interruptor apagado una partida no lleva la
  clave, y una partida antigua sin ella carga con todo a cero. No hace falta subir `FORMATO`.

## 3. Fórmulas revisadas y calibración

Revisadas el 12/11 en `grupo.gd`, `equipo_extra.gd`, `inventario.gd`, `combate.gd` y `combate_formulas.gd`:

| Fuente | Qué da |
|---|---|
| Un nivel | 3 puntos de atributo, +6 PV y +2 PM (nivel máximo 50) |
| 1 Fuerza | +1 de ataque (el daño físico es ataque × multiplicadores ± azar) |
| 1 Vitalidad | +8 PV máximos |
| 1 Espíritu | +3 PM máximos |
| 1 Magia | +2,5 % de daño mágico (`magia_mult`) |
| 2 Defensa | −1 de daño por golpe físico recibido |
| Velocidad | la barra ATB se llena antes |
| Crítico | base 12 % (`PROB_CRITICO`), ×`MULT_CRITICO`; los extras suman a la misma tirada |

Escala elegida (provisional): **básica = 2 puntos** (⅔ de nivel), **intermedia = 3 puntos o una pasiva pequeña**,
**avanzada = 4-5 puntos o una pasiva** (≈ 1,5 niveles), **excepcional = pasiva propia + algo de atributo**
(≈ 2-3 niveles). Ningún nodo pasa de ~3 niveles (`prueba_firmamento` lo comprueba con una equivalencia aproximada).
Un tablero completo: 74 orbes y unos 30-34 puntos equivalentes (≈ 10-11 niveles de puntos, sin la vida por nivel).

**Lo que el combate de hoy no sabe aplicar** (por eso esos nodos están **dormidos**): resistencia mágica y
resistencias elementales. Los enemigos solo golpean físicamente al grupo (`_animar_golpe` con magia "" contra héroes;
`combate_afinidades.gd` solo afecta a las escuelas de magia negra contra enemigos). Para despertarlos haría falta un
gancho en `combate.gd` (decisión del usuario; ver §9). Lya tiene, mientras tanto, la **coraza al empezar**
(`barrera_inicio`, gancho M3) como su «defensa mágica» real.

## 4. Precios

`firmamento_datos.gd PRECIOS` (editables): básica **1**, intermedia **3**, avanzada **6**, excepcional **10**.
Por tablero: 9 básicas (9) + 5 intermedias (15) + 5 avanzadas (30) + 2 excepcionales (20) = **74 orbes**.

## 5. Tablas de nodos

Generadas de `firmamento_datos.gd` (si se cambian los datos, manda el archivo). «Requiere» con «o» = basta uno; con
«y» = todos. Los efectos en fracción (0.04 = 4 %); `atb_inicio` en % de barra.

#### Kael

| id | Nombre | Rango (orbes) | Requiere | Da |
|---|---|---|---|---|
| k_inicio | Primer destello | Básica (1) | — (centro) | fuerza: 1, velocidad: 1 |
| k_filo1 | Filo templado | Básica (1) | k_inicio | fuerza: 2 |
| k_filo2 | Hoja despierta | Básica (1) | k_filo1 | fuerza: 2 |
| k_crit1 | Ojo del corte | Intermedia (3) | k_filo1 | critico: 0.04 |
| k_filo3 | Peso del acero | Intermedia (3) | k_filo2 | ataque: 3 |
| k_crit2 | Estrella fugaz | Avanzada (6) | k_crit1 | critico: 0.06 |
| k_tec1 | Guardia que responde | Avanzada (6) | k_crit1 o k_filo3 | contra_defendiendo: 0.3 |
| k_filo4 | Pulso de la hoja | Básica (1) | k_filo3 | fuerza: 2 |
| k_exc_filo | Filo del Eco | Excepcional (10) | k_crit2 y k_tec1 | critico: 0.05, ataque: 5 |
| k_vie1 | Paso ligero | Básica (1) | k_inicio | velocidad: 2 |
| k_vie2 | Aliento firme | Básica (1) | k_vie1 | vitalidad: 2 |
| k_vie3 | Primer movimiento | Intermedia (3) | k_vie1 | atb_inicio: 15.0 |
| k_vie4 | Sombra que se aparta | Intermedia (3) | k_vie2 | esquiva: 0.05 |
| k_vie5 | Ráfaga | Avanzada (6) | k_vie3 | velocidad: 3, esquiva: 0.03 |
| k_vie6 | Raíz del viento | Avanzada (6) | k_vie3 o k_vie4 | vitalidad: 3, defensa: 2 |
| k_vie7 | Temple | Básica (1) | k_vie4 | defensa: 2 |
| k_exc_vie | Viento del Eco | Excepcional (10) | k_vie5 y k_vie6 | atb_inicio: 20.0, velocidad: 3 |
| k_mem1 | Recuerdo del filo | Básica (1) | k_filo3 | espiritu: 2 |
| k_mem3 | Recuerdo del viento | Básica (1) | k_vie4 | vitalidad: 2 |
| k_mem2 | Chispa guardada | Intermedia (3) | k_mem1 o k_mem3 | magia: 3 |
| k_mem4 | Latido del cristal | Avanzada (6) | k_mem2 | regen: 0.03 |

Total del tablero: 74 orbes.

#### Lya

| id | Nombre | Rango (orbes) | Requiere | Da |
|---|---|---|---|---|
| l_inicio | Primera nota | Básica (1) | — (centro) | magia: 1, espiritu: 1 |
| l_ma1 | Corriente | Básica (1) | l_inicio | magia: 2 |
| l_ma2 | Marea alta | Básica (1) | l_ma1 | magia: 2 |
| l_ma3 | Runa de la corriente | Intermedia (3) | l_ma1 | magia_extra: 3 |
| l_ma4 | Pulso del manantial | Intermedia (3) | l_ma2 | pm_turno: 1.0 |
| l_ma5 | Runa profunda | Avanzada (6) | l_ma3 | magia_extra: 5 |
| l_ma6 | Mar en calma | Avanzada (6) | l_ma3 o l_ma4 | magia: 4 |
| l_ma7 | Gota clara | Básica (1) | l_ma4 | espiritu: 2 |
| l_exc_ma | Canto del Eco | Excepcional (10) | l_ma5 y l_ma6 | magia_extra: 4, magia: 3 |
| l_am1 | Manos abiertas | Básica (1) | l_inicio | espiritu: 2 |
| l_am2 | Paso sereno | Básica (1) | l_am1 | defensa: 2 |
| l_am3 | Velo de escarcha | Intermedia (3) | l_am1 | barrera_inicio: 0.06 |
| l_am4 | Raíz serena | Intermedia (3) | l_am2 | vitalidad: 3 |
| l_am5 | Aliento que perdura | Avanzada (6) | l_am3 | apoyo_turnos: 1.0 |
| l_am6 | Brote de vida | Avanzada (6) | l_am3 o l_am4 | regen: 0.03 |
| l_am7 | Pie firme | Básica (1) | l_am4 | vitalidad: 2 |
| l_exc_am | Coro del Eco | Excepcional (10) | l_am5 y l_am6 | aliento_inicio: 1.0, barrera_inicio: 0.06 |
| l_me1 | Cántaro | Básica (1) | l_ma2 | espiritu: 2 |
| l_me3 | Paso de viento | Básica (1) | l_am2 | velocidad: 2 |
| l_me2 | Cántaro sin fondo | Intermedia (3) | l_me1 o l_me3 | espiritu: 3 |
| l_me4 | Velo contra la magia | Avanzada (6) | l_me2 | res_magica: 0.15 |

Total del tablero: 74 orbes.

#### Garon

| id | Nombre | Rango (orbes) | Requiere | Da |
|---|---|---|---|---|
| g_inicio | Primer bastión | Básica (1) | — (centro) | vitalidad: 1, defensa: 1 |
| g_mu1 | Piedra | Básica (1) | g_inicio | defensa: 2 |
| g_mu2 | Sillar | Básica (1) | g_mu1 | defensa: 2 |
| g_mu3 | Coraza de runas | Intermedia (3) | g_mu1 | barrera_inicio: 0.08 |
| g_mu4 | Escudo del hermano | Intermedia (3) | g_mu2 | cubrir: 0.2 |
| g_mu5 | Muralla que responde | Avanzada (6) | g_mu3 | contra_defendiendo: 0.4 |
| g_mu6 | Almena | Avanzada (6) | g_mu3 o g_mu4 | defensa: 3, cubrir: 0.1 |
| g_mu7 | Contrafuerte | Básica (1) | g_mu4 | defensa: 2 |
| g_exc_mu | Bastión del Eco | Excepcional (10) | g_mu5 y g_mu6 | barrera_inicio: 0.1, defensa: 4 |
| g_ra1 | Tronco | Básica (1) | g_inicio | vitalidad: 2 |
| g_ra2 | Savia | Básica (1) | g_ra1 | vitalidad: 2 |
| g_ra3 | Corteza viva | Intermedia (3) | g_ra1 | regen: 0.03 |
| g_ra4 | Anillo del roble | Intermedia (3) | g_ra2 | vitalidad: 3 |
| g_ra5 | Mordisco de la tierra | Avanzada (6) | g_ra3 | robo_vida: 0.08 |
| g_ra6 | Raíz honda | Avanzada (6) | g_ra3 o g_ra4 | vitalidad: 4, espiritu: 1 |
| g_ra7 | Hombros de piedra | Básica (1) | g_ra4 | fuerza: 2 |
| g_exc_ra | Raíz del Eco | Excepcional (10) | g_ra5 y g_ra6 | regen: 0.04, vitalidad: 3 |
| g_me1 | Brazo de hierro | Básica (1) | g_mu2 | fuerza: 2 |
| g_me3 | Brasa de runa | Básica (1) | g_ra2 | espiritu: 2 |
| g_me2 | Martillo de forja | Intermedia (3) | g_me1 o g_me3 | ataque: 3 |
| g_me4 | Piel de basalto | Avanzada (6) | g_me2 | res_elemental: 0.2 |

Total del tablero: 74 orbes.

#### Naira

| id | Nombre | Rango (orbes) | Requiere | Da |
|---|---|---|---|---|
| n_inicio | Provisional | Básica (1) | — (centro) | magia: 1, espiritu: 1 |
| n_a1 | Provisional A | Básica (1) | n_inicio | magia: 2 |
| n_a2 | Provisional A2 | Intermedia (3) | n_a1 | magia_extra: 3 |
| n_b1 | Provisional B | Básica (1) | n_inicio | espiritu: 2 |
| n_b2 | Provisional B2 | Intermedia (3) | n_b1 | vitalidad: 3 |

Total del tablero: 9 orbes.

### Configuraciones viables (ejemplos con 15 orbes, sin trampas)

- **Kael ofensivo**: Primer destello → Filo templado → Ojo del corte → Hoja despierta → Peso del acero → Estrella
  fugaz (+8 ataque, +10 % crítico, +1 velocidad).
- **Kael esquivo**: Primer destello → Paso ligero → Primer movimiento → Aliento firme → Sombra que se aparta → Ráfaga
  (+15 % de barra al empezar, +8 % de esquiva, +6 velocidad, +16 PV).
- **Kael equilibrado**: los dos primeros de cada camino y la Memoria (vida, PM y magia para Fuego/Rayo).
- **Lya**: Marea (daño de magia y PM por turno), Amparo (coraza, Aliento más largo, regeneración) o mezcla.
- **Garon**: Muralla (defensa, coraza, cubrir, réplica en guardia) o Raíz (vida, regeneración, robo de vida).

## 6. Los tres conceptos visuales (escenas reales de Godot, elegibles en el propio tablero)

Los tres comparten datos, reglas, panel y controles; cambian el fondo (un shader por concepto, sin texturas) y el
dibujo del tablero (geometría 2D por código). Capturas en `D:\REBELUM_diagnostico\v12\expansion\orbes\capturas\`
(`<resolución>_<concepto>_<escena>.png`; `comparar_*.png` los pone uno encima de otro).

1. **Astrolabio de latón** — un instrumento: limbo graduado con 72 marcas, órbitas, una eclíptica excéntrica y una red
   que gira despacio con doce punteros; cada nodo es un cristal engastado en un bisel de latón; los enlaces son raíles
   dobles de latón por los que corre la luz del héroe. Fondo de bronce torneado (vetas radiales muy tenues).
2. **Constelación nocturna** — cielo profundo con nebulosa del color del héroe y dos capas de estrellas que titilan
   (con paralaje al desplazar); los nodos son estrellas con más puntas cuanto más alto el rango; los enlaces, líneas
   de constelación finas (discontinuas si están cerradas); dieciocho runas orbitan por fuera.
3. **Vidriera de geoda** — un rosetón de vidrio emplomado (80 paños en cuatro anillos) dentro de una geoda de amatista
   (facetas de Voronoi); al despertar un nodo, su paño se enciende con el color del héroe; los nodos son gemas
   talladas y los enlaces, varillas de plomo con un hilo de luz.

### Comparación artística (opinión del equipo de diseño; no es una elección)

| Criterio | Astrolabio | Constelación | Vidriera de geoda |
|---|---|---|---|
| Legibilidad del estado | Muy buena: el bisel de latón separa cada nodo del fondo; la luz del camino recorrido destaca sobre el bronce | Buena de cerca, algo menor de lejos: los nodos bloqueados se confunden un poco con las estrellas del fondo (por eso van con trazo discontinuo) | Muy buena para ver **lo recorrido** (los paños encendidos dibujan la ruta), algo más ruidosa: el color de los paños compite con los nodos |
| Atractivo «antes de usarlo» | Alto: el instrumento ya es bonito apagado | El más evocador y sereno | El más vistoso y colorido |
| Coherencia con REBELUM | Encaja con el oro de la interfaz (estilo.gd), las runas del Coloso y el brazalete; mecanismo astral | Encaja con «Ecos», la memoria y la noche de la magia de Naira (Astrónoma); la más cercana a «constelación» | Encaja con el Mar de Cristal y Bramavidrio (vidrio); más «catedral» que el resto del juego |
| Tacto | Igual en los tres (mismos objetivos de 88 px como mínimo, mismo panel) | Igual | Igual; los paños dan una pista grande de dónde tocar |
| Coste GPU del fondo (malioc, Mali-G57, por píxel) | **4,5 ciclos** (el más barato) | 8,5 ciclos | 8,6 ciclos (10,4 antes de quitar `sin()`) |
| Coste CPU / dibujo (PC) | 114 llamadas, 23 900 primitivas | 114 llamadas, 16 300 primitivas | 113 llamadas, 20 100 primitivas |
| Riesgo | Bajo | Bajo; en pantallas con poco brillo el fondo puede verse vacío | El color de los paños por héroe (Garon salmón) necesita ajuste de paleta |

## 7. Interfaz y controles

- **Pantalla**: tablero a la izquierda (860 px del lienzo de 1280×720), panel opaco a la derecha (420 px) con retrato
  (busto del retrato de diálogo, ya existente), nombre en cursiva, clase y nivel, **orbes disponibles** con su icono,
  nodos e invertidos; debajo, el nodo elegido: forma de su rango, nombre, rango y precio, **estado con icono y texto**,
  lo que da, una línea de ambiente y la **vista previa antes → después** (`Orbes.lineas_previa`: PV/PM máx., ataque,
  defensa, daño mágico, poder mágico, velocidad y cada efecto, calculados con las fórmulas reales), el botón principal
  y los mensajes.
- **Estados distinguibles sin color**: bloqueado = contorno discontinuo y sin relleno; disponible = contorno entero +
  anillo que respira + etiqueta de precio; caro = contorno entero tenue + precio apagado; despertado = relleno de luz,
  halo y chispas; dormido = contorno punteado violeta y una luna en lugar del glifo. Leyenda fija abajo. El rango se
  lee por la forma (círculo/rombo, hexágono, estrella de 8, estrella grande con anillo) y cada nodo lleva un glifo de
  lo que da (espada, escudo, ala, corazón, gota, espiral, ojo, runa, llama, raíz, mano, estrella, luna).
- **Táctil**: tocar elige (alcance de al menos 88 px de diámetro en pantalla, el nodo más cercano gana), arrastrar
  desplaza (umbral de 14 px para no confundirlo con un toque), pellizcar acerca y aleja (0,85×-2× del encuadre);
  botones «-», «+» y «Centrar» de 60 px para quien no pellizca; pestañas de héroe de 132×56. Los toques que Godot
  emula como ratón se ignoran (no cuentan dos veces).
- **PC**: clic, arrastre, rueda y gestos del panel táctil. **Teclado / mando**: flechas o cruceta eligen el nodo más
  cercano en esa dirección (cono de ~60°) y la cámara lo sigue; Intro/A despierta (dos veces), Esc/B cancela o cierra,
  Q/E (L1/R1) cambian de héroe, +/- acercan.
- **Lectura a 1600×720 y 2400×1080**: el juego usa `canvas_items` con aspecto «keep» (bandas a los lados en 20:9),
  así que el lienzo de 1280×720 se ve a ×1 en 1600×720 y a ×1,5 en 2400×1080. Textos de 15 px como mínimo (la
  mayoría 17-22); los precios del tablero se compensan con el zoom para leerse siempre a unos 18 px.

## 8. Animación, sonido y rendimiento

- **Desbloqueo** (1,35 s): una cuenta de energía con estela recorre cada enlace desde lo ya despierto (0,55 s), el
  tramo recorrido se enciende, y el nodo estalla: destello, onda que se abre y doce chispas; el fondo late un instante
  (`pulso`). En la vidriera, el paño se llena de color. **Error** (bloqueado, caro o dormido): el nodo tiembla 0,4 s
  y el panel dice por qué.
- **Sonido** (biblioteca ya integrada en `sonido.gd`, nada nuevo): `ui_abrir`/`ui_cerrar`, `ui_tic` al elegir,
  `ui_confirmar` al gastar, `orbe_vision` (la resonancia cristalina del orbe del altar) cuando la energía llega,
  `ui_error`, `ui_atras` al cancelar y `ui_mejora` con los orbes de prueba. No se ha escuchado: solo se ha
  comprobado que existen y se piden.
- **Cómo se dibuja barato**: cuatro capas. La **fija** (decorado, enlaces, nodos, precios) se rehace solo cuando
  cambia algo; la de **giro** se dibuja una vez y gira con `rotation`; la **viva** (anillos, chispas, trazos que
  fluyen, selección) y la **luz** (halos aditivos con un degradado de 64×64) se rehacen a 30 FPS en reposo. Todo lo
  geométrico va en **una lista de triángulos por capa** (`pincel.gd`, con suavizado propio): de 520-650 llamadas de
  dibujo a **114 en toda la pantalla** (la mayoría, el panel y sus textos). Mientras el tablero está abierto, **el 3D
  de debajo no se dibuja** (`viewport.disable_3d`, se devuelve al cerrar): el tablero tapa toda la pantalla.
- **Medido en el PC** (`fotos_firmamento.gd medir`, sin límite ni vsync, redibujando todo cada fotograma, que es el
  peor caso): 4,3-4,7 ms por fotograma, dibujo en CPU ~1,0-1,1 ms y en GPU ~0,4-0,5 ms; memoria de vídeo 20 MB a
  1600×720 y 31 MB a 2400×1080 (casi todo, búferes de la ventana y fuentes; el tablero solo añade los tres retratos ya
  existentes, ~1,8 MB, y el degradado de 16 KB). **El PC no es el Redmi.**
- **Previsión para el Mali-G57 (estimación estática, malioc)**: fondo 4,5 / 8,5 / 8,6 ciclos por píxel (aritmética,
  sin texturas). Con el fondo solo detrás del tablero (860×720 px del lienzo), a 1600×720 son ~0,62 M píxeles: unos
  1,5 ms (astrolabio) y 2,8 ms (constelación, vidriera) por fotograma con el modelo de presupuesto de Arm
  (núcleos × frecuencia / píxeles), ×2,25 a 2400×1080. Más unas 24 000 primitivas 2D y ~114 llamadas: holgado para
  30 FPS en un menú **sin el 3D debajo**. Hay que medirlo en el Redmi (Streamline) antes de darlo por bueno.

## 9. Propuestas de obtención (varias, SIN elegir)

| # | Propuesta | Cómo | A favor | En contra | Ritmo orientativo |
|---|---|---|---|---|---|
| A | **Ecos del mundo** | Cada detalle de lore visto (`lore_visto`) o recuerdo/visión da 1 orbe, una vez | Encaja con el nombre «Ecos» y premia explorar; finito, sin farmeo | Depende de cuánto lore haya; el jugador que no explora va corto | 1 por detalle |
| B | **Jefes y élites** | Cada jefe 3-5 la primera vez; élites (encuentros_azar) 1 la primera vez | Hitos claros, sin farmeo | Pocas fuentes al principio | 20-30 en el juego actual |
| C | **Hitos de misión** | Al completar misiones/actos (`hitos`), 2-4 | Ritmo controlado por la historia | Lineal; no premia la exploración | 2-4 por misión |
| D | **Cofres y secretos** | Un orbe en algunos cofres y rincones (como el del Mar de Cristal) | Premia la exploración 3D | Hay que colocar a mano | 1 por secreto |
| E | **Subir de nivel** | 1 orbe cada nivel (o cada 2) | Sencillo, siempre llega | Se solapa con los puntos de atributo; poco especial | 1 por nivel (49 en total) |
| F | **Taller / alquimia** | Fabricar un orbe con materiales de las bestias (talleres.gd) | Da salida a los materiales; elección del jugador | Abre la puerta al farmeo; hay que limitarlo | según receta |
| G | **Bestiario / logros** | Completar familias del bestiario o retos (ganar sin pociones…) | Rejugabilidad | Necesita un sistema de logros que no existe | 1-3 por logro |

Combinaciones razonables para estudiar: A + B (finito, temático), o B + C + D (ritmo de historia más exploración).
Lo que haya que decidir: ¿saldo común o por héroe?, ¿cuántos orbes en el juego actual (¿un tablero y medio
completo hacia el final?), ¿se pueden ganar en combates repetibles?

## 10. Reinicio futuro (solo estudio, no implementado)

Como las bonificaciones se calculan desde la lista de nodos, reiniciar es **seguro y barato**: vaciar
`nodos[héroe]` y devolver `gastados[héroe]` al saldo; nada que deshacer en atributos ni en el equipo. Opciones:

1. **Gratis y total**, en un punto de guardado o en la posada (sin coste definitivo, como pide el usuario).
2. **Total con una «Lágrima en blanco»** (un objeto raro: una por acto) — sin coste en orbes.
3. **Parcial**: deshacer solo las hojas (nodos de los que no depende ninguno despierto), gratis, en cualquier momento.
4. Mientras se decide: un reinicio de desarrollo en Auditoría (no implementado aún, sería una línea).

Cuidado: con «todos» en los excepcionales, un reinicio parcial no puede quitar un avanzado del que dependa uno
despierto (la opción 3 ya lo evita).

## 11. Pendiente de decisión del usuario

1. **Elegir concepto** (o mezcla: p. ej. el astrolabio con el cielo de la constelación).
2. **Obtención** (§9) y si el saldo es común o por héroe. Hoy no hay ninguna fuente.
3. **Precios y valores** (provisionales, en `firmamento_datos.gd`).
4. **Resistencias**: ¿se engancha la magia/elementos enemigos en `combate.gd` para despertar los nodos dormidos
   («Velo contra la magia» de Lya y «Piel de basalto» de Garon) o se cambian por otros?
5. **Reinicio** (§10).
6. **Naira**: su tablero está preparado y apagado (5 nodos de relleno, «provisional»), como el personaje.
7. ¿Con el interruptor apagado deben conservarse los efectos de una partida que ya los tenía? (hoy: no suman).
8. Nombres y textos de los nodos (de ambiente, sin narrativa nueva).
