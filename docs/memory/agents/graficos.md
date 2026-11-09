# Informe del especialista de gráficos

## 2026-11-09 00:30 · T-085, fase 1: el mapamundi (análisis, propuesta y prototipo)

Rama `area-graficos` en `D:\Aethelgard_graficos`, desde `dddbddb`. `mapa.gd` y `mapa.tscn` sin tocar. Detalle completo:
[`docs/graficos/mapamundi.md`](../../graficos/mapamundi.md).

**Análisis (causas, observado en el código y comprobado ejecutando).**
- *Costas escalonadas:* el terreno se genera al cargar en una imagen de 600×337 (1 píxel = 4×4 px del mundo) con un
  corte binario tierra/mar por píxel y se estira ×4 con filtro lineal: escalones de 4 px emborronados.
- *Manchas planas:* un color constante por zona más un único ruido de ~250 px; el 77,2 % de los bloques de 16×16 px
  del mapa entero apenas varía (desviación < 2/255).
- *Poco detalle:* sin alturas, ríos, montañas, bosques ni caminos; la tierra son «cápsulas» alrededor de las rutas y
  los biomas, celdas de Voronoi.
- Además: marcas genéricas, rótulos de 20 px que Kael tapa al abrir el mapa, 2 px sin pintar en el borde inferior,
  la máscara del juego 2 px más abajo que el dibujo en la mitad inferior, y ≈ 1 s de CPU (PC) para generar el
  terreno en cada carga (indicativo).

**Técnica elegida:** mapa pintado **horneado sin conexión** desde los mismos datos de `mapa.gd` (réplica exacta),
con relieve, hondura del agua, costa continua, biomas con textura, picos, bosques, ríos, caminos, lagos y lava; en el
juego, una textura con agua viva barata (1,00 frente a 0,75 ciclos por píxel en la Mali-G57, `malioc`) e iconos y
rótulos en vivo en la posición de cada lugar. Toda la calidad cara se paga una vez en el PC.

**Archivos creados** (todos nuevos):
- `aethelgard/mapa_arte/`: `datos_mapa.gd`, `generar_mapa.gd`, `hornear_mapa.gdshader`, `iconos_mapa.gd`,
  `mapa_arte.gd`, `agua_mapa.gdshader`, `prototipo_mapa.tscn`, y los generados `mapa_mundo.webp`, `mapa_zonas.png`,
  `agua_datos.png`, `costa_datos.png`, `iconos/0-10.png` (con sus `.import` y `.uid`).
- `aethelgard/pruebas/prueba_mapamundi.gd` y `prueba_mapamundi_fotos.gd` (+ `.uid`), dos líneas al final de
  `pruebas/lista_pruebas.txt`.
- `docs/graficos/mapamundi.md` y tres comparaciones reducidas (`mapamundi_comparacion_{juego,mapa,costa}.jpg`).
- Commits en `area-graficos`: `32395b1` (generador y datos), `d2ced14` (imágenes generadas), `cbaf895` (prototipo),
  `8baf3f7` (pruebas) y el de esta documentación. Sin push.

**Pruebas** [ejecutado, datos aislados, 2026-11-09]:
- Ejecutor oficial: `prueba_mapamundi`, `prueba_escenas`, `prueba_dpad` y `prueba_toque`: **4 SUPERADAS**, partida real
  y carpeta real de datos sin cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_002331\resumen.md`.
- `prueba_mapamundi` también con `3d` (11 lugares, con Pastos Verdes) y con `mapa_clasico` (alternativa): 0 fallos.
- Resultados clave: réplica y máscara horneada idénticas (0 píxeles distintos); alineación exacta en 1 080 000 puntos;
  costa dibujada en desacuerdo con la del juego en el 0,30 % de los puntos, todos a ≤ 2,8 px de la línea; lugares,
  rutas, radio de «Entrar», iconos y rótulos en su sitio.

**Evidencias:** `D:\REBELUM_diagnostico\mapamundi\2026-11-08\` → `antes\`, `propuesta\`, `comparacion\` (9 encuadres:
juego al abrir, mapa entero 1:1 y reducido, costa 1× y 3×, Oakhaven, Garganta, Cumbres, móvil 20:9), `malioc\`
(equivalentes ESSL y salida) y `registros\` (cada ejecución, aislada). Planitud: 77,2 % → 32,7 % de bloques planos.

**Límites:**
- Sin medidas de rendimiento (memoria, carga, tiempo por fotograma): esperan el hueco sin otra carga de la fase 2.
- La resolución del Redmi no consta: simulé un HD+ 20:9 (1600×720; con el aspecto `keep`, el juego va a 1:1 con
  franjas de 160 px). Falta `adb shell wm size` (usuario o coordinador).
- El prólogo, el portal, los menús y los combates no se probaron sobre el prototipo (heredan `mapa.gd`).
- `--import` creó `.uid` de archivos ajenos (`dialogos/retrato_vivo.gd.uid`, `escena_dialogo.gd.uid`,
  `pruebas/prueba_prologo.gd.uid`, `pruebas/prueba_prologo_fotos.gd.uid`): **no los he confirmado**.

**Siguiente paso y cambios en archivos de otros:**
- Fase 2: integrar con la alternativa. Opción recomendada: en `mapa.tscn`, el script pasa a ser
  `res://mapa_arte/mapa_arte.gd` (hereda `mapa.gd`; `mapa.gd` no cambia). Revisar al integrar si sonido añadió algo
  dentro de `_crear_mapa` o `_generar_terreno` (el prototipo no llama a la original de esas dos con el arte activo).
- Decidir el interruptor del mapa clásico (hoy `-- mapa_clasico`).
- `docs/recursos.md` (coordinador): añadir la fila de procedencia de `docs/graficos/mapamundi.md` § 6.
- Medidas y pruebas de la fase 2: `docs/graficos/mapamundi.md` § 10.

## 2026-11-09 07:49 · T-085, fase 2: el mapamundi pintado, integrado (con el de siempre como alternativa)

Rama `area-graficos` en `D:\Aethelgard_graficos`, desde `e11a882` (con la integración `c74b872`). Detalle completo:
[`docs/graficos/mapamundi.md`](../../graficos/mapamundi.md), § 11.

**Integración** [código; ejecutado]: `mapa.tscn` usa `res://mapa_arte/mapa_arte.gd`, que hereda `mapa.gd` (los
enganches de sonido y el prólogo vienen de `mapa.gd` sin cambios). `mapa_arte/prototipo_mapa.tscn`, retirado.

**Cómo se elige el mapa de siempre:**
- `-- mapa_clasico` (PC, editor y pruebas), en cualquier versión;
- sin argumentos, **solo en la versión experimental** (`modo3d.activo()`: la app «Aethelgard Exp» o `-- 3d`):
  `[mapa]` `clasico=true` en `user://ajustes.cfg`. También `[mapa]` `agua_quieta=true` (o `-- agua_quieta`) quita el
  agua animada. El código solo lee el archivo; `mapa_arte.gd.elegir(clave, si)` lo escribe sin tocar `[volumen]`
  (`sonido.gd` no se ha tocado). En el móvil, hasta que haya botón: `adb shell "run-as com.aethelgard.experimental sh
  -c 'printf \"\n[mapa]\nclasico=true\n\" >> files/ajustes.cfg'"` (lo hace el usuario) [pendiente de probar en el
  teléfono].

**Corregido** [ejecutado]:
- Kael tapaba «Oakhaven» al abrir: los rótulos van por encima de Kael en los dos mapas; al abrir el pintado, Kael
  queda 26 px por debajo de «Oakhaven» y ningún rótulo queda bajo la interfaz (botón «Entrar», barra, «Misiones»,
  brújula, «Zona» y la cruceta del móvil).
- «Portal del Vacío» pegado al castillo: 34 px a la derecha; ningún rótulo a menos de 6 px del dibujo de otro icono.
- Los 2 px sin pintar abajo: `mapa.gd._generar_terreno` con 338 filas (antes 337 × 4 = 1348 px). Las filas
  1348-1349 eran el gris de fondo (76, 76, 76); ahora, mar.
- La máscara 2 px desplazada en la mitad de abajo: ×2 exacto y recorte (antes, `resize` de 337 a 675 filas);
  `datos_mapa.gd` con desfase constante y el mapa pintado re-horneado (los iconos salen idénticos, byte a byte).
  **Efecto en el juego:** en la mitad de abajo (y ≥ 676), la colisión con la costa y los bordes de zona suben 2 px, a
  donde está el dibujo; ningún lugar, ruta, radio, encuentro ni dato del guardado cambia.
- Además, con la exploración 3D (como en el móvil): el icono de Pastos Verdes pisaba el árbol del Gran Bosque. Icono
  de Pastos Verdes a 0,85 y 30 px a la izquierda (sigue conteniendo su lugar); rótulos de Pastos Verdes y Cumbres a
  la izquierda y del Gran Bosque a la derecha (debajo tocaba el botón «Entrar» al abrir; encima, Cumbres quedaba bajo
  la brújula).
- Lo dibujado frente a las zonas de interacción (`prueba_mapamundi`): costa (colisión) a ≤ 2,8 px, zonas (encuentros
  y «Zona: …») a ≤ 1,4 px de un borde, «Entrar» en los 11 lugares con su anillo de RADIO_LUGAR, cada icono contiene
  su lugar, ni iconos ni rótulos se pisan.

**Archivos:** `aethelgard/mapa.gd` (`_generar_terreno` y el orden de sus rótulos), `mapa.tscn`,
`mapa_arte/{mapa_arte.gd, datos_mapa.gd, generar_mapa.gd}`, `mapa_arte/{mapa_mundo.webp, mapa_zonas.png,
agua_datos.png, costa_datos.png}` (re-horneados), `mapa_arte/prototipo_mapa.tscn` (retirado),
`pruebas/{prueba_mapamundi.gd, prueba_mapamundi_fotos.gd, lista_pruebas.txt}` y nuevos `pruebas/medir_mapamundi.gd`
(+ `.uid`) y `medir_mapamundi.ps1`; `docs/graficos/mapamundi.md` (§ 11) y `mapamundi_fase2_antes_despues.jpg`;
`docs/recursos.md` (solo la fila del mapamundi). Commits en `area-graficos`: `9f4b6b5` (integración), `8b6e6e1`
(máscara y re-horneado), `d852ed6` (pruebas y medida) y el de esta documentación. Sin push.

**Pruebas** [ejecutado, datos aislados, 2026-11-09; partida real y carpeta real de datos sin cambios en todas]:
- Las del mapa (13): `prueba_mapamundi`, `prueba_escenas`, `prueba_dpad`, `prueba_toque`, `prueba_foco`,
  `prueba_mando`, `prueba_teclado`, `prueba_prologo`, `prueba_musica`, `prueba_zona3d` y `prueba_boton_prologo`:
  **11 SUPERADAS**; `prueba_mapamundi_fotos` y `prueba_isla` (con ventana): terminan sin errores (MANUAL, revisadas).
  Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_073702\resumen.md`.
- Variantes: `prueba_mapamundi` sin 3D (`…\2026-11-09_073909`) y con `mapa_clasico` (`…\2026-11-09_073932`):
  SUPERADAS. `prueba_dpad` con `escena=mapa dpad sin_prologo` (la cruceta en el mapa del mundo; la de la lista prueba
  la zona): Kael 256 px a la derecha (`…\2026-11-09_074028`).
- El prólogo sobre cada mapa (`prueba_prologo_fotos`, antes y después): 9 frases, una pulsación por frase y control al
  acabar, sin fallos.
- **Batería completa: 40 SUPERADAS, 0 FALLIDAS** (25 MANUALES: con ventana o a mano, no van en lote): ningún
  fallo, ni nuevo ni anterior. `D:\REBELUM_diagnostico\pruebas\2026-11-09_074129\resumen.md` (su «archivos del
  proyecto: han cambiado» son mis documentos, que edité durante la pasada).

**Evidencias:** `D:\REBELUM_diagnostico\mapamundi\2026-11-09\` → `antes\` (`-- mapa_clasico`), `despues\` (los dos
con 3D, como en el móvil), `despues_estable\` (sin 3D), `prologo\` (antes y después), `comparacion\` (parejas y
**`lamina_antes_despues.jpg`**: inicio, costa ×3, Oakhaven, Garganta y el prólogo) y `registros\`. Planitud del mapa
entero: 77,1 % → 32,6 % de bloques planos.

**Medida preparada, sin ejecutar:** `aethelgard\pruebas\medir_mapamundi.ps1` (antes / pintado / pintado con el agua
quieta; carga, fotograma quieto y andando, memoria estática, de vídeo y de texturas; frío y caliente; 3
repeticiones; se niega a empezar con otros Godot abiertos o la CPU por encima del 20 %). Comprobado solo que analiza
sin errores (`--check-only` y el analizador de PowerShell). Uso:
`powershell -ExecutionPolicy Bypass -File D:\Aethelgard_graficos\aethelgard\pruebas\medir_mapamundi.ps1 [-Experimental] [-Ventana 1600x720]`.

**Procedencia:** fila añadida al final de `docs/recursos.md` (mapamundi pintado e iconos: generados por código, propia).

**Incidente (mío, ya resuelto):** el scratchpad de la sesión es compartido. A las 07:19 escribí un ayudante
`godot_aislado.ps1` y pisé, sin saberlo, el del especialista de animaciones (mismo nombre). Dos ejecuciones suyas
(07:19:58 y 07:24:59) abrieron el juego sobre MI copia, con datos aislados (la carpeta real no cambió) y sin producir
sus registros. A las 07:26 restauré su archivo byte a byte (sacado de su propia llamada Write) y renombré los míos con
el prefijo `graficos_`. **Animaciones debe repetir esas dos ejecuciones** (`grupo3d_2` y la anterior); sus registros
fallidos están en `D:\REBELUM_diagnostico\mapamundi\2026-11-09\registros\_071958` y `_072459`.

**Límites:**
- Sin medidas de rendimiento (preparadas, sin ejecutar: había otros especialistas trabajando). Indicio, no medida: en
  `prueba_prologo_fotos` la primera frase sale a los 5,9 s sobre el pintado y a los 3,1 s sobre el de siempre, con la
  misma mediana de fotograma (28,4 ms); la diferencia la explican las 24 capturas PNG de la entrada (671 frente a
  297 KB: más detalle que comprimir). Que lo confirme la medida.
- No probado en el Redmi (ni la opción con `run-as`).
- `prueba_dpad` con `escena=mapa` y **sin** `sin_prologo` da «Parse Error: Failed [retrato_vivo.tscn:6]» también con
  el mapa de siempre: la prueba termina a los 80 fotogramas mientras el prólogo carga el retrato. No es del mapa; para
  animaciones, por si quieren que esa carga cortada no avise así.
- `--import` volvió a crear `pruebas/prueba_boton_prologo.gd.uid` (ajeno): **sin confirmar**, se queda sin seguimiento.

**Siguiente paso y cambios en archivos de otros:**
- Coordinador: la medida en un hueco sin otra carga; después, una APK de prueba para el Redmi.
- `menus.gd` (sonido), si se quiere elegir el mapa sin `adb`: en la pestaña Ajustes, solo si
  `load("res://modo3d.gd").activo()`, una fila «Mapa del mundo: pintado / de siempre» que llame a
  `load("res://mapa_arte/mapa_arte.gd").elegir("clasico", si)` y lea `…clasico_elegido()` para mostrar el estado
  (vale desde la próxima vez que se abra el mapa).
- Garganta 3D: nada que hacer aquí; `_entrar` sigue preguntando a `modo3d.escena_de(i)`.

## 2026-11-09 13:20 · T-089: el arte de Oakhaven (piezas horneadas en 3/4, módulo, vecinos, maqueta y modelos 3D)

Rama `area-graficos` en `D:\Aethelgard_graficos`, desde `ab250c9` (con la fase 1 de narrativa). Sin tocar `zona.gd`,
`ciudad_oakhaven.*`, `ciudades/oakhaven.gd`, `mapa.gd`, `progreso.gd`, `diario.gd`, `sonido.gd`, `combate.gd`,
`zonas3d/**` ni `modo3d.gd`. Importación aislada al empezar: `D:\REBELUM_diagnostico\importaciones\graficos_20261109_082919\`.

**Técnica** [código; comprobado ejecutando, 2026-11-09]
- Modelos 3D hechos por código en Blender 5.2 (sin recursos externos ni servicios) y renderizados con Cycles a la hora
  azul en la proyección EXACTA de la ciudad 2D: cámara ortográfica a 45° mirando al norte y píxel √2 más alto que
  ancho, de modo que el punto (x, y, z) en casillas cae en el píxel (64·x, 64·(y − z)). Cada imagen se pega sin
  reescalar: la escala con Kael, la perspectiva y las casillas casan (comprobado en la maqueta).
- Luz pintada: cielo índigo y azul pizarra con un resto de rosa al oeste, una luz suave del oeste-suroeste y luces
  cálidas de verdad en ventanas, puertas, faroles, velas y brasero (rebotan en muros y suelo). El crematorio, frío.
- Por capas: cuerpo (ordena con su fachada), lo que cuelga y se mece (el cuervo, la ropa, el mortero), lo que se pisa
  (raíces, escalera) y una calcomanía de suelo en alfa PREMULTIPLICADA (sombra suave + charcos de luz cálida), a 1/4.
- En el juego, todo unshaded: comprobado que ni el CanvasModulate ni las luces 2D lo tocan (si no, se oscurecería dos
  veces). Humo con UNA imagen por chimenea (ruido que sube), halos que suman luz con parpadeo, vaivén en el
  sombreador, 14 luciérnagas. Si Kael pasa por detrás de un edificio, este se aclara en un círculo a su alrededor
  (`jugador_pos`, que `zona.gd` solo actualiza con hierba alta: lo pone al día UNA pieza por escena, `pieza.gd`).
- Copa del árbol con miles de hojas (partículas de Blender), raíces por «piel» procedural; tapiz, sello y anillos del
  tocón pintados por código (numpy).

**Piezas** (`ciudades/oakhaven_piezas.gd`: `crear_pieza(id, rect_casillas, tam_casilla) -> Node2D`, null sin arte;
`ids()`, `rect_de(id)`, `tiene(id)`; otra huella → centrada abajo y aviso; otro tamaño de casilla → escala).
| id (= lugar de `oakhaven.gd`) | Qué lleva | Capas y orden frente a Kael | Anclas |
|---|---|---|---|
| `taberna` | Planta baja de piedra, alto con entramado y vuelo, hastial sobre la puerta entreabierta con la luz de dentro, buhardilla, dos chimeneas, geranios, farol y el cuervo de hierro en su aro | cuerpo (y = 25), letrero (se mece) | humo, humo_chica, farol_puerta, puerta, letrero |
| `crematorio` | Piedra hueso y pizarra, contrafuertes, ventanas en arco sin luz, óculo, escalinata y la puerta SELLADA con el sello rúnico del anillo partido; chimenea con humo blanco y frío (sale del faldón sur para que se vea) | cuerpo (y = 15) | humo, puerta, sello |
| `arbol` | Árbol Milenario: tronco ensanchado, ramas, copa de hojas que sale por el borde del mapa (no cabe), raíces sobre el empedrado, el tocón con el anillo negro, tres farolillos y luciérnagas; destello del cofre de las raíces entre las hojas | raíces (se pisan), tronco (y = 9), copa (y = 9, se mece) | tronco, luciernagas, cofre_raices, anillos, encina, farolillo_1..3 |
| `concejo` | Sillería, ventanas en arco, hastial con óculo, estandartes; el pórtico de columnas con faroles y el TAPIZ de los reyes con el niño recortado | cuerpo (y = 21), pórtico (y = 23: Kael pasa entre muro y columnas) | humo, puerta, tapiz, farol_portico_1/2 |
| `torre` | Fuste de sillería, saeteras con luz, campanario con la campana, chapitel de pizarra y veleta, puerta con farol | cuerpo (y = 42) | puerta, farol_puerta, campana |
| `ronda` | Adarve almenado con pretil y remate sur; 3 faroles apagados y, aparte, encendidos | adarve (ordena arriba: quien sube va encima), farol_n_on (estado `farol_n`) | farol_1..3, subida, cofre |
| `mercado` | Tres puestos con toldos a rayas, género, cajas, sacos y guirnalda de farolillos | un puesto por capa, guirnalda | tienda |
| `plaza` | Fuente con bellota de bronce, tablón de anuncios, carro de flores de Rosa | fuente, tablón, flores | fuente, tablon, flores |
| `patio_cuervo`, `grieta`, `patio_velas`, `jardin_urnas`, `subida_colina` | Barriles; el muro del callejón con la raja de luz y hiedra; el altar con el anillo dorado y 9 velas; urnas y cipreses; la escalera de la colina | objetos / alfombra | barril; grieta, luz; velas; paseo; arriba, abajo |
| `puerta_sur`, `botica`, `guardia` | Torreones y arco con rastrillo (Kael pasa por debajo); botica con vidrios verdes, mortero y hierbas; guardia con estandarte, soportal con el libro y patio con valla y brasero | torres (54,8) y arco (56); cuerpo y letrero; cuerpo, soportal (49) y patio (53) | farol_oeste/este, salida; puerta; puerta, brasero, libro |
Sueltas, en el origen (las pone el relleno): `farol` (halo y charco de luz, sin PointLight2D), `ropa_tendida` y siete
casas `casa_3x4 … casa_6x5` (entramado o piedra, teja o pizarra, ventanas con luz o cerradas, chimeneas con humo).
Choques propios solo en objetos dentro de zonas pisables (fuente, puestos, barriles, columnas, urnas, altar…); los
edificios usan la rejilla de muros de la ciudad.

**Vecinos** [ejecutado]: muñecos 2D propios (`oakhaven_arte/munecos/`, `Piezas.muneco_de(id, imagen)`): posadera ←
aldeana (vino; panecillos en la cesta), Bastián ← pícaro (azul y pardo), Doña Encina ← maga (verde musgo, bronce,
pelo blanco), Albar ← caballero (gris ceniza y plata, pelo plateado). No es un tinte: cada color cambia por zonas de
tono y la piel, los ojos y el dibujo se conservan; mismo estilo y tamaño. Ya no se tiñen. Un muñeco nuevo de verdad
(modelo 3D) no se puede hacer digno sin un modelo base: los de `personajes/npc/` no tienen modelo en el proyecto.

**Maqueta** (`oakhaven_arte/maqueta_oakhaven.gd/.tscn`, hereda `zona.gd` como hará la ciudad): trazado de
`oakhaven.gd`, las piezas, el relleno propuesto (`RELLENO`: 31 casas, 16 farolas y 2 tendederos), jardines con la
vegetación que ya tiene el juego, los vecinos, `AMBIENTE` (0,5 · 0,52 · 0,74) y `LUZ_JUGADOR` (0,32 · 1,9; la de hoy
alumbra 400 px y es de día). Lección de la proyección: una casa tapa unas 7 casillas al norte de su huella, así que el
relleno solo pone casas al norte de calles y plaza; al sur, jardines (la prueba lo vigila).

**Coste** (estimado, SIN medir: había otros especialistas trabajando)
- GPU: 69 texturas distintas, 8,30 Mpx = 31,6 MB en RGBA8 sin comprimir (las casas iguales comparten imagen). En
  disco: 1,45 MB (WebP 94 y PNG). Comprimidas en VRAM (ETC2/ASTC, 8 bpp) serían unos 8 MB: sin probar su calidad.
- Nodos: 2-22 por pieza (Concejo, el que más); la maqueta entera, 65 piezas y 495 nodos. A la vista a la vez, unas
  6-12 piezas: 30-60 elementos de dibujo. Ninguna luz 2D (solo la de Kael, que ya existía), 14 partículas.
- Por píxel: edificio ~12 operaciones; humo 2 lecturas de textura; halo ~10 operaciones; vaivén solo en vértices.
  Sobredibujado estimado ~3× en lo más denso (casillas, calcomanía, edificio, efecto).

**Archivos y commits** (todos nuevos salvo dos líneas de `lista_pruebas.txt` y dos filas de `docs/recursos.md`):
`e43acc8` fuentes de Blender (`oakhaven_arte/fuente/`, con `.gdignore`) · `85d0cac` imágenes, calcomanías, ruido y
`arte_datos.gd` · `0012483` `oakhaven_piezas.gd`, `pieza.gd` y sombreadores · `07e2dda` muñecos · `42016b9` maqueta y
pruebas · `1c9c950` modelos 3D · `2b39965` procedencia · `3f9b04e` la foto del aclarado. Sin push.
Sin confirmar (ajenos): `project.godot` (Dialogic apuntó solo los 4 personajes y 27 diálogos de narrativa al importar)
y 34 `.uid` de archivos de narrativa.

**Pruebas** [ejecutado, datos aislados, 2026-11-09]
- Ejecutor oficial: `prueba_oakhaven_arte`, `prueba_ciudad_datos` y `prueba_escenas`: **3 SUPERADAS**; partida real y
  carpeta real de datos sin cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_131552\resumen.md`.
- `prueba_oakhaven_arte` (FALLOS: 0): 25 piezas; interfaz, huellas de canon, materiales sin luz, ni luces 2D ni
  partículas de más, cuerpo que cubre su huella, traslado y escala, anclas, estados de la ronda y del destello, humo
  dentro del mapa, relleno que no pisa ni TAPA calles, plaza, PNJ, piezas, notas, cofres ni detalles, y coste con tope.
- `prueba_oakhaven_arte_fotos` (ventana, MANUAL): capturas antes y después sin errores en el registro.

**Evidencias** (`D:\REBELUM_diagnostico\oakhaven\2026-11-09\arte\`): `antes\` (la ciudad de hoy), `despues\` (la
maqueta: entrada, plaza, taberna, crematorio, árbol, mercado, torre y ronda, callejón y velas, ciudad entera, móvil
20:9, la fachada ×2 y el aclarado detrás del Concejo), `comparacion\` (parejas y **`lamina_antes_despues.jpg`**),
`modelos_glb\` (los 25 `.glb`) y `registros\` (horneados, importaciones y capturas).

**Modelos 3D para el Oakhaven 3D** (lo pidió el coordinador): `oakhaven_arte/modelos/<id>.blend` (25, 4 MB, con
`.gdignore`): mallas con modificadores, materiales de procedimiento, imágenes empaquetadas, luces, cielo y cámara, en
su sitio de la ciudad (1 casilla = 1 m). Los `.glb` (modificadores aplicados, colores planos, sin las hojas sueltas)
se rehacen con `fuente/exportar_modelos.py -- <ids> <carpeta .blend> <carpeta .glb>`. Reutilizables tal cual (bien
por todos lados): árbol, fuente, puestos, barriles, urnas, altar y velas, faroles, tendedero, torreones, torre,
ronda y escalera. Los edificios (taberna, crematorio, Concejo, botica, guardia, casas) solo tienen detalle en la
fachada sur y el tejado: en 3D les faltan las otras tres fachadas y los interiores (la posada recorrible).

**Límites**
- Sin medidas (memoria de vídeo, tiempo por fotograma, carga) ni prueba en el Redmi: solo estimaciones.
- La maqueta no es la ciudad: diálogos, misiones, cofres y la ronda en alto son de `ciudad_oakhaven.gd` (narrativa).
- Dos piezas de canon tapan un sitio con su tejado (la regla de las 7 casillas): la botica tapa el tablón del bando
  (36, 29) y el Concejo, el tocón de los anillos (45, 10). El aclarado los descubre cuando Kael se acerca.
- Sin hacer: las dos viñetas pintadas (torre y raíces), la muralla del borde con arte propio (siguen las casillas de
  `zona.gd`), suelo propio de la colina, retratos de Dialogic de los vecinos nuevos.
- `.blend` y `.glb`: los materiales del `.glb` son colores planos; para 3D hay que hornear texturas o rehacerlos.

**Siguiente paso y cambios en archivos de otros**
- Narrativa (`ciudad_oakhaven.gd`): tras `super._crear_objetos()`, para cada `Oak.LUGARES`
  `var p := Piezas.crear_pieza(d["id"], Rect2i(d["rect"]), T)` y, si no es null, `mundo_y.add_child(p)` (el Concejo
  trae su pórtico; el árbol, sus raíces; la guardia, su soportal y su patio). Relleno: igual con `Piezas.RELLENO`
  (casas → `muros = 2`; sueltas sin muro). `estilo["ambiente"] = Piezas.AMBIENTE`, `luz_jugador` con `LUZ_JUGADOR`,
  `estilo["hierba_alta"] = 0` y sin las farolas de `zona.gd` (cada una lleva una PointLight2D). Vecinos:
  `Piezas.muneco_de(id, imagen)` y el `tinte` solo si devuelve la de siempre. Estados: `ronda.poner_estado("farol_n",
  true)`; `arbol.poner_estado("cofre_raices_abierto", true)` al abrir `oak_cofre_raices`. Muro de la grieta:
  `muros = 2` en (20-22, 35) y (24-26, 35). Si se quieren a la vista: el tablón a (37, 23) y el tocón a (42, 10.5)
  (se rehace la pieza en un minuto con `hornear.py`).
- Coordinador: añadir `aethelgard/ciudades/oakhaven_arte/munecos/` a `docs/versiones/licencias_pendientes.txt`;
  medir en un hueco sin otra carga (memoria de vídeo y fotograma en PC y Redmi) y decidir si las texturas grandes van
  comprimidas en VRAM.
- Oakhaven 3D: partir de los `.blend`; la posada necesita su interior.