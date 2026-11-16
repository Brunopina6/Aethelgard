# Sunken City 3D: «La Quilla, de la costilla 44 a la rampa» (V12, EXPERIMENTAL y APAGADA)

16/11/2026 · especialista de Sunken City · rama `area-sunken-quilla` (desde `claude/rebelum-v12` @ `2d7745d`).
Encargo: apartado 2 de `docs/v12/SUNKEN_ARBOLEDA_PLAN.md` (§2.10). Estudio de apoyo:
`D:\REBELUM_diagnostico\sunken_arboleda\estudio\sunken.md`. Referencia de acabado: la muestra de la calle de Oakhaven
(`docs/v12/MUESTRA_CALLE_OAKHAVEN.md`), con el mismo método y la identidad propia de una ciudad dentro de un barco.

**Estado: EXPERIMENTAL y APAGADA.** Solo en Auditoría o en el editor, y solo con el interruptor de sesión
`sunken_quilla_v12`: en el banco de pruebas, selector «Sunken: Quilla horneada (solo en el banco)» → «Sí», y después el
caso «Sunken City 3D (en pruebas)»; en las pruebas, el argumento `sunken_quilla_v12`. Apagada, la Sunken de siempre no
cambia (ni se carga nada de la carpeta nueva) y las partidas tampoco. **Todo lo narrativo es PROPUESTA [P].**

Capturas, vídeo, medidas y registros: `D:\REBELUM_diagnostico\sunken_quilla\` (fuera del repositorio).
Marcas: **[C]** canon, **[P]** propuesta, **[D]** decisión del usuario. **Ninguna medida es del Redmi** (estaba
desconectado): todo lo móvil está PENDIENTE (§9).

## 0. Qué se ve

- **La Quilla** (z 28,8-44,4): las tres cuadernas rehechas como **cuadernas dobles** (dos ligazones con pernos, flejes de
  hierro, el bao alto con sus cartelas y un motón colgado; verdín y percebes en el agua); la 32, con el **empalme a medio
  poner** sobre su trozo roto (dos abrazaderas puestas y las marcas de tiza de las otras dos); la 38 **sin farol**, con
  el cabo cortado.
- **Casas colgadas hechas con restos del barco**: tracas verticales de tonos distintos (pintadas, blanqueadas y alguna
  nueva) con su junta de brea, **portas de cañón por ventanas** (con barrotes, luz dentro y la tapa levantada con un
  cabo), **tapas de escotilla por puertas** (enjaretado con bandas de hierro), **toldos de vela remendada** (remiendos
  ocre, listones, cabos y sacos de lastre) o tejados de tablas embreadas con un parche de lona, **estufas de hojalata**
  con su sombrerete, cuartos colgados con **escalas de gato**, porches, y **una plancha de cada puerta a la pasarela**.
- **La vida de la Quilla** (fase A2): la **cuadrilla** trabajando con objetos (§4), la **cabria** de la choza del este
  con su torno y la barca amarrada abajo, el **banco de la carpintera** junto a la costilla 32, la olla de brea del
  calafate, montones de tablones y fardos, redes, nasas, barriles y rollos de cabo; dos tendederos con ropa de lado a lado.
- **La luz**: la tarde dorada de siempre (mismo sol y mismo cielo que `sunken_3d.gd`), **horneada en todo el sector** con
  sombras largas de las casas y de las costillas, oclusión bajo los toldos y en los rincones, rebote turquesa de la
  laguna y el **charco cálido de los faroles 44 y 32**; entre ellos, **la costilla 38 queda a oscuras**: el secreto de la
  tabla se lee con la vista.

## 1. Comprobaciones previas (§2.10, «Primero comprueba»)

| Qué | Resultado (observado en el código y ejecutando, 16/11, `2d7745d`) |
|---|---|
| Nodos de `sunken.glb` | Las costillas (`costilla_<dm>`), las casas (`edif_casa_1..6` y `bajo_casa_1..6`) y los tendederos llegan **separados**, pero **el suelo de la Quilla viene fundido** con todos los suelos del sector en `bajo_suelos` (y la quilla con todo el casco en `bajo_casco`). Por eso se usó el **plan B**: `crear_quilla.py` ejecuta `crear_sunken.py` **en memoria, sin tocarlo** (le quita su llamada final, como él hace con `crear_distrito.py`), con su semilla y su orden: fuera de la Quilla la geometría es la de siempre. |
| La casa del oeste en z 32,8-37,2 | `edif_casa_1` (n = 1, lado oeste; `crear_sunken.py:525-531`). |
| De qué lado está rota la costilla 32 | Del **oeste**: `rota=(0.08, 0.17)` → x 29,6-30,5, a 3,1-5,3 m de altura. El empalme va ahí. |
| ¿Se ve el agua desde la cámara de la Quilla? | Sí, entre la pasarela y las casas y bajo las planchas (capturas). La barca del este queda en el borde del encuadre desde la rampa; el fardo se ve al llegar al descansillo y en la repisa. |
| Programas nuevos en `[carga]` | Observado en el código: la Quilla usa **los mismos tres archivos** `calle_estatico/vertice/brillo.gdshader` (por su ruta), el `StandardMaterial3D` sin luz con color de vértice (el de los cristales de siempre) y los de los chibis y `materiales.gd` (`liso`). Medida de la primera entrada en frío: §5. |

## 2. Las pasadas (capturas en las mismas vistas de `fotos_sunken3d`)

Cámara y vistas: las del juego (`fotos_sunken3d.gd`, modo `vistas`, 1280×720, perfil medio salvo donde se dice). Cada
carpeta tiene las 14 vistas; las de la Quilla son `_04` (sur), `_05` (costilla oscura), `_06` (norte) y `_07` (rampa).

| Pasada | Carpeta | Qué cambió |
|---|---|---|
| Antes | `antes\` (bajo, medio, alto) | La Sunken de siempre |
| 1. Composición | `p1_composicion\` | Bloques: cuadernas de 12 tramos, casas como cajas sobre su plataforma |
| 2. Arquitectura | `p2_arquitectura\` | El kit entero (cuadernas dobles, tracas, portas, escotillas, toldos, estufas, cuartos colgados, planchas), luz en tiempo real |
| 3. Materiales | `p3_materiales\` | Texturas pintadas por código (512²): tablazón, madera blanqueada, lona con costuras, hierro, cabo, grano |
| 4. Iluminación | `p4_iluminacion\` | Horneado Cycles de todo el sector. Lección: con los colores de Sunken pasados a lineal todo salía negro (el juego los trata como lineales desde la V12): se conservan tal cual, y el cielo sube un 30 % porque la sombra con oclusión ya no tiene la luz ambiente plana de antes |
| 5. Atrezo | `p5_atrezo\` | Olla de brea, montones, cabria, barca, banco, redes, nasas, barriles, rollos |
| 6. Integración | `despues\` | La cuadrilla trabajando, el sol propio de Kael con las sondas, su sombra de contacto, las coronas que se ocultan |
| 7. Optimización | `despues\` | Menos superficies (lo pequeño de hierro y cabo con el grano «liso»; coronas y fantasmas de un material), montones de una sola malla, caras que nunca ve la cámara solo en el horneado |

## 3. Antes / después en el PC (llamadas de dibujo y primitivas por vista)

`fotos_sunken3d` (modo vistas), Kael con Lya y Garon, 1280×720, un fotograma por vista: es un recuento del motor, no un
tiempo. Antes = la Sunken de siempre; después = con `sunken_quilla_v12` (cuadrilla incluida).

| Vista | bajo antes → después | medio antes → después | alto antes → después |
|---|---|---|---|
| muelle (01) | 40 · 67,7 mil → **33** · 78,0 mil | 54 · 129,7 mil → **42** · 138,5 mil | 93 · 147,2 mil → **43** · 145,1 mil |
| popa, cubierta (03) | 64 · 69,2 mil → **44** · 83,4 mil | 86 · 131,8 mil → **52** · 143,7 mil | 125 · 155,2 mil → **53** · 152,9 mil |
| Quilla sur (04) | 67 · 68,6 mil → **40** · 92,7 mil | 91 · 130,5 mil → **47** · 147,1 mil | 130 · 153,2 mil → **52** · 156,6 mil |
| costilla oscura (05) | 68 · 68,5 mil → **40** · 98,2 mil | 90 · 130,1 mil → **48** · 158,5 mil | 137 · 153,8 mil → **53** · 167,9 mil |
| Quilla norte (06) | 75 · 75,2 mil → **47** · 100,3 mil | 106 · 143,5 mil → **60** · 166,8 mil | 147 · 164,0 mil → **60** · 173,0 mil |
| rampa (07) | 72 · 75,2 mil → **46** · 99,8 mil | 96 · 143,1 mil → **55** · 166,0 mil | 133 · 164,0 mil → **55** · 172,2 mil |
| Cubierta Mayor (08) | 69 · 74,3 mil → **46** · 95,1 mil | 94 · 142,5 mil → **59** · 161,6 mil | 123 · 160,4 mil → **59** · 167,8 mil |

(llamadas de dibujo · primitivas). Láminas antes (izquierda) / después (derecha) de estas vistas en los tres perfiles:
`laminas\comparar_<perfil>_<vista>_antes_izq_despues_der.png`.

- **Llamadas**: −35 a −60 % en todas las vistas y perfiles (una superficie por material del sector entero, sin discos de
  luz en el suelo, sin omni, y menos objetos sueltos). Con la cuadrilla, en el **bajo** la Quilla queda en **40-47**
  (objetivo ≤ 45: la vista norte, 47, y la rampa, 46, se pasan por 1-2) y en el **medio** en 47-60 (objetivo ≤ 55).
  **Sin la cuadrilla** (pasada 4, `p4_iluminacion`, bajo) la Quilla en bajo estaba en 37-45: A1 cumple.
- **Primitivas**: suben (el kit es más detallado y la cuadrilla son cuatro personajes de 4-6 mil triángulos):
  **bajo 87-100 mil** en la Quilla (objetivo ≤ 90 mil: se pasa hasta un 11 % donde se ven tres obreros a la vez). El
  sector de Blender pasa de 12,2 mil triángulos (ligero) a ≈ 20 mil en todos los perfiles.
- El alto tenía omni reales en 4 faroles y sombras del sol sobre todo: ahora la luz va horneada y la sombra en tiempo
  real solo la lleva el sol de Kael, así que el alto baja de 130-147 a 52-60 llamadas.

## 4. La cuadrilla de la Quilla [P] (fase A2)

`zonas3d/sunken/quilla/obreros.gd`. Trabajan para la proa en obras («Proa en obras. Orden de la capitana», texto que ya
existe). Lista propia (no son `vecinos`: no entran en `_prohibido` ni cambian las rutas); fuera de lo andable; la
animación solo avanza si se ven; golpes de mazo y azuela con los sonidos de madera de siempre (`paso_madera`) solo si se
ven y Kael está a menos de 9 m; el crujido del puente al llegar el fardo.

| Quién | Figura | Trabajo (recoger → trabajar → llevar → entregar) | Dónde |
|---|---|---|---|
| Calafate | oficio herrero, persona nueva `calafate` (mazo) | coge estopa de la olla de brea → la mete a mazo en dos costuras de su casa → vuelve | porche de la casa del este 2 (x ≈ 42,8-43,0; z 40,2-42,3) |
| Carpintera de ribera | oficio **campesino**, persona nueva `carpintera` (la azada se lee como su azuela) | coge un tablón del montón → lo deja en el banco y lo labra → lleva la pieza hecha junto a la Quilla y la apila | plataforma nueva junto a la costilla 32 (x 35,2-38,2; z 31,65-32,75) |
| Dos marineros | oficio viajero, personas nuevas `marinero_1` y `marinero_2` (el bastón se lee como bichero) | uno hala en el torno mientras la cabria sube un fardo de la barca → el otro lo recoge en el descansillo, lo lleva por la repisa del sur y lo apila junto a la rampa → el gancho baja otra vez | choza del este de la rampa, su descansillo (x 46,0-47,5) y la repisa (z 31,55-32,3) |

- **Se puede hablar con ellos** desde la pasarela («Hablar con el calafate», «… la carpintera», «… el marinero»): se
  paran 3,8 s mirando a Kael (clip «hablar»), dicen una frase por aviso y siguen donde lo dejaron. Mientras hay un
  diálogo o la tienda abiertos, esperan.
- Frases [P] (≤ 110 letras, sin términos vetados): calafate «Estopa, brea y mazo. Si una costura llora, la Quilla entera
  se entera.» / «La laguna no quiere hundirnos. Solo entra por donde la dejamos entrar.»; carpintera «Esta costilla perdió
  un trozo. Le pongo un empalme: madera vieja, abrazaderas nuevas.» / «Aquí no se tira nada. Las casas son tablas que
  antes fueron cubierta.» / «La capitana quiere la proa lista. Primero, que la Quilla aguante.»; marinero «¡Arriba ese
  fardo! Tablas para la proa, por orden de la capitana.» / «Subimos madera de la laguna todo el día. Las gaviotas miran y
  no ayudan.». **Solo después de encontrar la paga**: calafate «¿Una tabla suelta bajo la costilla del medio? Ya decía yo
  que crujía distinto.» y marinero «¿La costilla sin farol? Nadie cuelga uno ahí. Ahora ya sabes por qué.»
- Sin misión nueva ni claves de partida. Nadie trabaja hacia el dique ni nombra la Astraea.

## 5. Medidas en el PC

`medir_sunken3d.gd` (PC: RTX 3050 Laptop + Ryzen 7 4800H, Compatibility, **ventana 1600×720**), antes y después en
los tres perfiles, sin bloqueo de horneado de nadie y sin Blender abierto (había otros Godot de otras copias; no se midió
con el PC vacío). Textos: `medidas\medida_<perfil>_<antes|despues>_<perfil>.txt`. **No certifica el Redmi.** Los ms
reales con el límite del perfil (30 FPS en bajo y medio) salen 33,3 en todos los casos; lo que compara es el coste del
dibujo (CPU y GPU que mide el motor) en los tres sitios de la herramienta (solo Kael, sin el grupo):

| Perfil · sitio | ANTES: llamadas · primitivas · CPU · GPU | DESPUÉS: llamadas · primitivas · CPU · GPU |
|---|---|---|
| bajo · muelle | 34 · 24,5 mil · 1,28 · 1,19 ms | **27** · 34,8 mil · 0,79 · 0,71 ms |
| bajo · Quilla | 72 · 25,7 mil · 0,86 · 0,57 ms | **44** · 56,5 mil · 1,60 · 0,99 ms |
| bajo · Cubierta | 64 · 31,5 mil · 2,61 · 1,82 ms | **42** · 52,3 mil · 0,84 · 0,46 ms |
| medio · muelle | 41 · 43,2 mil · 1,20 · 0,53 ms | **29** · 51,9 mil · 0,80 · 0,43 ms |
| medio · Quilla | 90 · 44,3 mil · 1,15 · 1,14 ms | **46** · 73,6 mil · 0,98 · 1,01 ms |
| medio · Cubierta | 86 · 56,7 mil · 1,17 · 0,59 ms | **49** · 75,6 mil · 0,92 · 0,51 ms |
| alto · muelle | 81 · 61,8 mil · 1,29 · 1,48 ms | **30** · 58,5 mil · 0,98 · 0,92 ms |
| alto · Quilla | 134 · 71,0 mil · 1,16 · 1,16 ms | **47** · 85,8 mil · 1,53 · 1,05 ms |
| alto · Cubierta | 110 · 74,2 mil · 1,38 · 1,71 ms | **48** · 75,9 mil · 1,13 · 1,05 ms |

| Perfil | Carga, 1.ª entrada del proceso (antes → después) | Entradas siguientes | Peor fotograma de los 2 s tras entrar | Vídeo / texturas tras entrar |
|---|---|---|---|---|
| bajo | 1372 → **1934 ms** | 1024 → 930 ms | 33,5 → 33,4 ms | 48,0 / 34,7 → 51,1 / 36,9 MB |
| medio | 1351 → **1557 ms** | 950 → 961 ms | 33,4 → 33,8 ms | 48,9 / 35,6 → 54,0 / 39,7 MB |
| alto | 1448 → 1445 ms | 942 → 927 ms | 32,9 → 32,7 ms | 70,6 / 56,8 → 75,4 / 61,0 MB |

- La Quilla en bajo cuesta algo más de CPU y GPU que antes **en este PC** (0,86 → 1,60 y 0,57 → 0,99 ms): son la
  cuadrilla (cuatro esqueletos que se animan y sus objetos) y el doble de primitivas; en la Cubierta y el muelle, donde no
  se ve la cuadrilla, todo baja. Son décimas de milisegundo en un PC: el teléfono dirá (§9).
- La **primera entrada del proceso** tarda +560 ms en bajo y +200 ms en medio: la herramienta entra desde el mapa sin
  pasar por la pantalla de carga, que en Auditoría precalienta los sombreados de la muestra (`carga.gd`,
  `precalentar_en`), así que se preparan al entrar. Las entradas siguientes son iguales o más rápidas y no hay tirones en
  los 2 s tras entrar. **Pendiente en el Redmi** el «[carga]» real tras instalar (§9, paso 6).
- Memoria de vídeo +3-5 MB (mapa de luz, seis texturas de 512² y los cuatro atlas de la cuadrilla).

## 6. Pruebas

Con `ejecutar_pruebas.ps1` (datos aislados; listas propias con `-Lista`), 16/11, rama `area-sunken-quilla`:
- **12 SUPERADAS · 0 FALLIDAS**: `prueba_sunken_quilla` (nueva), `prueba_sunken3d` (apagada), `prueba_sunken3d_apagada`,
  `prueba_restaurar_escenas`, `prueba_equipo_combate`, `prueba_encargos`, `prueba_diario_misiones`, `prueba_ciudad_datos`,
  `prueba_banco_pruebas`, `prueba_banco_pruebas_3d`, `prueba_precarga` y `prueba_muestra_calle`. Partida real, carpeta
  real de datos y proyecto sin cambios. Resumen: `pruebas\2026-11-16_015113\resumen.md`.
- **`prueba_sunken3d` CON la Quilla** (`3d sunken3d sunken_quilla_v12 sin_prologo`): **SUPERADA, sus 16 apartados**
  (las 11 rutas en línea recta, el suelo de todo lo andable, la misión, el secreto, la forja, guardar y cargar, la
  salida). `pruebas\2026-11-16_015252\`.
- `prueba_sunken_quilla` (27 comprobaciones; §2.8 del plan): apagada no carga nada de su carpeta (ni la precarga ni las
  APK de prueba la llevan); encendida monta el GLB horneado con los sombreados de la muestra y el mapa de luz del perfil;
  faroles en 44 y 32 y ninguno en 38, y la luz directa de los faroles en las tablas bajo la 38 es 2,6 frente a 15,1 y
  15,8 bajo la 44 y la 32 (lo poco que llega es de los faroles vecinos); la corona de la 44 se oculta con Kael en z 40 y
  vuelve con Kael al sur; ningún material transparente ni luz omni (medio); en 50 s nadie de la cuadrilla pisa lo
  andable y el más cercano pasa a 2,25 m de las rutas; los trabajos avanzan (3 fardos apilados, 3 piezas hechas);
  hablar para al calafate y luego sigue; frases ≤ 110 y sin vetos; el botón ofrece hablar desde la pasarela; la
  pasarela tiene suelo a su altura y lo que no se pisa sigue sin pisarse.
- Con controles normales: solo los clics y teclas que simulan las herramientas. **Pendiente**: el recorrido a mano con
  teclado, mando y ratón en el PC, y con cruceta y toque en el Redmi (§9).

**Vídeo**: `video\quilla_cuadrilla_bajo.mp4` (22 s, 1280×720, 30 FPS, perfil bajo; Movie Maker + ffmpeg;
`pruebas/grabar_sunken_quilla.gd`): de la popa por la Quilla a la rampa, con la cuadrilla trabajando y Kael parándose a
hablar con el calafate, la carpintera y el marinero. Lámina: `video\lamina_video.png`.

## 7. Archivos

**Nuevos** (`aethelgard/zonas3d/sunken/quilla/`): `fuente/crear_quilla.py`; `modelos/quilla.glb` (+ `.import`: sin LOD,
tangentes ni mallas de sombra); `texturas/{tablazon,blanqueada,lona,hierro,cabo,liso}.png` (512², VRAM con mipmaps);
`luz/quilla_luz_{1024,2048}.png` (VRAM con mipmaps) y `luz/quilla_luz.json` (escala, sol, calibración, sondas y la luz de
los faroles en las tablas); `quilla.gd`; `obreros.gd`. Pruebas: `pruebas/prueba_sunken_quilla.gd` (auto) y
`pruebas/grabar_sunken_quilla.gd` (grabación, no es prueba). Atlas nuevos: `personajes/npc_v12/herrero/calafate.png`,
`campesino/carpintera.png`, `viajero/marinero_1.png` y `marinero_2.png` (+ `.import` iguales a los de los demás atlas).

**Cambios fuera de la carpeta** (todos sin efecto con el interruptor apagado; para el coordinador):
1. `zonas3d/sunken/casco.gd`: si el interruptor está encendido (y solo entonces carga `quilla.gd`), monta la Quilla en
   lugar del GLB de siempre; `_faroles` no pone el disco del suelo ni las omni con la Quilla (su luz está horneada; los
   halos del aire siguen); `apartar` pasa a ocultar las coronas; `resumen` la describe.
2. `zonas3d/sunken_3d.gd`: tres enganches de una línea o dos: `quilla.cada_fotograma` en `_process` (sondas, sombra de
   Kael y la cuadrilla), las piezas de la cuadrilla en `piezas_al_alcance` y la rama `_:` de `_accion` para hablar con
   ella. (El plan solo citaba el primero; los otros dos son necesarios para hablar con la cuadrilla.)
3. `banco_pruebas.gd`: `"sunken_quilla_v12"` en `METAS_CALIDAD` **y no en `METAS_SESION`** (estas se borran al empezar
   cada caso, así que el selector no llegaría a la escena; `METAS_CALIDAD` duran toda la sesión y se quitan al salir,
   como «Muestra: precalentar») y el selector «Sunken: Quilla horneada (solo en el banco)». Sin entrada nueva en
   `EXPLORAR`: se usa el caso «Sunken City 3D (en pruebas)» con el selector.
4. `recursos.gd`, `APAGADOS`: `"res://zonas3d/sunken/quilla/": "sunken_quilla_v12"`.
5. `export_presets.cfg`: `zonas3d/sunken/quilla/*` en `exclude_filter` de los presets 1 y 2.
6. `fuente/crear_npc_chibi.py`: solo se **añaden** las personas `calafate` (herrero), `carpintera` (campesino),
   `marinero_1` y `marinero_2` (viajero). Los atlas existentes salen idénticos (comprobado con MD5: `ferro.png`,
   `brea.png`); los GLB de los oficios no se copiaron al proyecto (se generaron en una carpeta aparte, 4.º argumento).
7. `pruebas/lista_pruebas.txt`: la línea de `prueba_sunken_quilla`.
8. `pruebas/prueba_banco_pruebas.gd`: 10 selectores (antes 9) y comprobar que al salir no queda `sunken_quilla_v12`.
9. **`pruebas/prueba_muestra_calle.gd` (fuera de la lista de archivos compartidos):** su paso 2 exige que nadie fuera del
   banco y de `carga.gd` nombre la muestra; la Quilla **tiene** que nombrar sus sombreados por la ruta (lo pide el plan,
   para no compilar programas nuevos), así que se añadió `quilla.gd` a los usos permitidos, con su motivo. Es una línea.

**No se ha tocado**: `trazado.gd`, `crear_sunken.py`, `sunken.glb`, `sunken_ligero.glb`, `ciudades/sunken.gd`,
`datos/encargos_sunken.gd`, los diálogos, `zona.gd`, `mapa.gd`, `progreso.gd`, `modo3d.gd`, los `calle_*.gdshader`, la
cámara de la Quilla, el camino 2D, Ulla, Brea, «El sello de la capitana», la costilla 38 a oscuras, la Astraea, el canon.

## 8. Decisiones para el usuario [D] y lo provisional

**[D] para el usuario**
1. **La cuadrilla en el bajo**: con ella la Quilla pasa por 1-2 llamadas y hasta un 11 % de primitivas el objetivo del
   bajo (§3). Opciones: dejarla así si el Redmi da 30 FPS; tres obreros en vez de cuatro; o la cuadrilla solo en medio y
   alto.
2. **La carpintera** usa el cuerpo del campesino (el del herrero lleva barba y calva); su azada hace de azuela. ¿Vale, o
   se prefiere un «carpintero» o un oficio nuevo con su clip (como el «halar» de los marineros, que sigue pendiente)?
3. **Nombres y frases [P]** de la cuadrilla (§4) y si se hace el microencargo «Brea para la Quilla» (no hecho).
4. **Sombra de contacto de Lya y Garon** (plan, [D] 1): solo la lleva Kael. Lya y Garon comparten su sol (se apaga con
   las sondas de Kael); la cuadrilla, Ulla y Brea usan el sol de siempre, que no se apaga.
5. **El brillo del bajo**: con la Quilla horneada se deshace la compensación del perfil sin sombras (1,15), para que el
   bajo se vea como el medio (la luz horneada es la misma en los tres). ¿De acuerdo?
6. **La popa, el palo y la bandera** llevan la luz en los vértices sin textura (para seguir volviéndose transparentes si
   tapan a Kael, como antes): se ven menos detallados que lo demás. Alternativa: ocultarlos como las coronas.
7. **Fase B** (paso de babor y El Ancla Seca, precio 30 o 40): sin empezar (§10).

**Provisional (no es arte final)**
- Texturas pintadas por código (grano, veta, costuras): sin pincelada a mano.
- Los toldos y tejados se repiten (dos tipos); los cuartos colgados son cajas lisas; las ventanas encendidas, planas.
- La corona oculta desaparece de golpe (no se funde); la popa y el palo, sin textura ([D] 6).
- La cuadrilla: clips prestados (martillar, cavar, ajustar), sin clip «halar»; los objetos que llevan son cajas con el
  material liso de siempre; en la sombra horneada se ven con el sol de siempre (sin sondas propias). El atlas de la
  carpintera conserva el emblema del campesino (el árbol de Oakhaven) en su loseta.
- El mapa de luz de 2048 cubre el sector entero: en bajo (1024) la sombra de las casas sobre la pasarela es más blanda.
- La calibración del sol y del cielo copia la luz de la escena (sol ×1,12, cielo ×1,30 por los rebotes y la oclusión):
  ajustada a ojo en el PC; falta verla en la pantalla del Redmi.
- Los charcos de los faroles son suaves a la luz de la tarde (140 W en Blender): se leen mejor en la sombra de las casas.
- `crear_quilla.py` y `crear_sunken.py` comparten medidas (como `trazado.gd`): si cambia una, hay que regenerar.

## 9. Guion para el Redmi (PENDIENTE: el teléfono estaba desconectado)

Nada de esto se ha medido en el teléfono. Para cuando el usuario lo conecte (D-065: la APK de Auditoría se copia por USB
a Download con su nombre de fecha y versión; la instala el usuario):

1. Compilar la APK de **Auditoría** (preset 3, el único que lleva la Quilla) desde la rama integrada y copiarla.
2. En el teléfono, abrir el banco de pruebas y poner **«Calidad 3D (solo en el banco)» → «Fija: bajo · 3D ×0,75»**.
   Poner **«Sunken: Quilla horneada» → «No»** y entrar en «Sunken City 3D (en pruebas)». Con **RND** abierto: andar del
   muelle a la popa, por la Quilla hasta la rampa y la Cubierta Mayor, y volver; quedarse 20 s en la costilla 38. Anotar
   FPS medios, peor fotograma, llamadas y primitivas en la Quilla. Salir al banco.
3. Lo mismo con **«Sí»** (la Quilla horneada). Hablar con el calafate, la carpintera y el marinero.
4. Repetir 2 y 3 con **«Regulador normal»** (anotar el escalón en el que se queda y la escala 3D de logcat «[calidad]»).
5. Repetir 3 con el teléfono en **resolución completa** (perfil medio desde CAL) solo para ver la imagen, sin juzgar FPS.
6. Primera entrada **tras instalar** (caché de sombreadores vacía) con la Quilla: ¿fotograma en negro de más de 1 s?
   (`logcat | grep -E "\[carga\]|\[calidad\]"`). Las siguientes entradas, ¿tirones?
7. Memoria: `dumpsys meminfo` (PSS) en la Quilla, con y sin el interruptor. Objetivo ≤ 880 MB en bajo.
8. Mirar en la pantalla real: bandas del ETC2 en los degradados del mapa de luz (sombras de las casas sobre la pasarela),
   escalones en la luz de los vértices en las sombras oscuras, que el charco de luz de los faroles 44 y 32 se vea y el
   tramo de la 38 se lea más oscuro, que Kael no quede tapado bajo ninguna costilla, que los halos del aire de los
   faroles (transparencias que ya existían) se vean bien en bajo.
9. Objetivos (plan §2.7): bajo y medio ≥ 30 FPS sostenidos y 0 fotogramas perdidos en muelle → Quilla → rampa; alto, se
   mide y no se promete.

## 10. Fase B (paso de babor y El Ancla Seca): NO hecha

El plan pide hacerla solo si A1/A2 cumplen el presupuesto **y** tras medir en el Redmi (A3). Sin teléfono, A3 está
pendiente, y en el PC la Quilla con la cuadrilla queda algo por encima del objetivo de llamadas del bajo (§3). Queda
diseñada en el plan (§2.4). Para empezarla: rehacer en el kit la casa del oeste del primer tramo para dejar el paso
(z 33,8-35,4), ampliar las sondas (hoy empiezan en x 29,5) y el horneado hasta la posada (x ≈ 21), y su prueba.

## 10.b Incidencia de la noche (para el coordinador)

La carpeta temporal de la sesión es **compartida** por todos los agentes. Al principio usé un lanzador `godot.sh` en su
raíz y otro agente lo sobrescribió con el suyo (apuntaba a su copia `agent-a85db4f688cdc98d7`). Desde ~00:35 hasta
~00:58 algunas órdenes mías se ejecutaron **en esa otra copia**: una importación sin ventana (`--import`), las capturas
«antes» y una de la pasada de arquitectura (`fotos_sunken3d`, solo lectura de la escena y su partida de prueba en SU
carpeta de datos aislada). No escribí archivos del proyecto en esa copia, pero la importación pudo actualizar su caché
`.godot`. Lo detecté, pasé a una subcarpeta propia (`sunken_quilla_agente\`) con la ruta absoluta de mi copia y **repetí
todas** las capturas y medidas en la mía. Recomendación: un lanzador por agente con la ruta absoluta.

Los horneados respetaron el turno de `D:\REBELUM_coordinacion\horneado.lock` (esperando a «barrio-a» y «barrio-b»).

## 11. Cómo regenerarla

1. `blender -b --factory-startup -P aethelgard/zonas3d/sunken/quilla/fuente/crear_quilla.py -- <ruta>/aethelgard/zonas3d/sunken/quilla [--fase composicion|arquitectura|materiales|iluminacion|completa] [--muestras N] [--res N]`
   (≈ 25 s con OptiX; respetar el turno de `D:\REBELUM_coordinacion\horneado.lock`).
2. Reimportar en Godot con datos aislados: `godot --headless --path aethelgard --import`.
3. Capturas: `fotos_sunken3d.gd` con `sunken_quilla_v12` y `modo=vistas perfil=bajo|medio|alto`; medida:
   `medir_sunken3d.gd` con `sunken_quilla_v12`; vídeo: `grabar_sunken_quilla.gd` con `--write-movie`.
4. Personas de la cuadrilla: `blender -b --factory-startup -P aethelgard/fuente/crear_npc_chibi.py -- <aethelgard> <láminas> herrero,campesino,viajero <carpeta aparte>` y copiar solo los cuatro `.png` nuevos.
