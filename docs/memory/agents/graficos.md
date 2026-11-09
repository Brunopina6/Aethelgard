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

## 2026-11-09 18:30 · T-102: la Garganta 3D, primer tramo pulido (entrada, primera cornisa y primer puente)

Especialista de gráficos en `D:\Aethelgard_garganta3d`, rama `area-garganta3d`. Antes de empezar, unión `--no-ff` de
`integracion-experimental` (`eb8bd94`) → `cc9a07a`. Referencia de ambiente: «Aventura entre Cascadas y Ruinas»
(`D:\REBELUM_diagnostico\entradas\2026-11-09_imagenes\rebelum_paisaje.webp`): senda empedrada, roca con estratos y
musgo, puente de cuerda con postes y faroles, agua que cae entre acantilados.

### 1. Qué se ha hecho (observado en el código y comprobado ejecutando, aislado)

**Por qué se veía plano** (capturas de antes): la pared era un gris liso de grano grande; el suelo, gravilla parda con
losas hexagonales sueltas y esferas grises; el puente, tablas casi iguales y cuerdas finas; el abismo, sin agua ni
bruma cerca del camino; los faroles, un cubo encendido sin llama.

- **Entrada (umbral, z = 33,6):** dos piedras hincadas de los peregrinos con el anillo partido en bronce, una cuerda
  de cintas de oración combada entre ellas y una antorcha en cada una (llama viva, halo y calor en la roca).
- **Vía del Peregrino:** adoquines irregulares y gastados (cuatro formas en MultiMesh), juntos en el centro y sueltos
  en los bordes, algunos verdosos u ocres; peñas facetadas con el sombreado de la roca y musgo encima; helechos y
  matas verdes al pie del muro y junto al agua; la hierba de esos rincones, verde (el resto sigue seca).
- **Roca:** vetas finas de los estratos (cada 0,85 m) con su labio claro y musgo vivo en los labios; roca mojada,
  más oscura y con luz fría junto a la caída; resplandor cálido de hasta 8 fuegos pintado en la roca, sin luces
  reales. Fuegos, humedad y distancia se calculan en los vértices.
- **La caída del primer puente:** agua que brota de una grieta del muro del oeste junto al primer hueco y cae al
  abismo, en arco; espuma, resplandor frío, bruma que sube (4/7/11 partículas por perfil), rocío que llega al puente
  (medio y alto) y un colchón de niebla fría bajo el puente (medio y alto): la profundidad se lee.
- **Primer puente colgante (y el segundo):** cada tabla con su ancho, grosor, giro y tono (algunas de un arreglo,
  otras partidas, clavos en medio y alto); largueros y travesaños; pasamanos gruesos, cuerda baja, tirantes con nudo;
  vueltas de cuerda en los pilares; vientos a estacas; dos faroles colgados en la entrada del primero. **Se mece**:
  5 cm de lado a lado y 2 cm arriba y abajo en el centro, nada en los extremos, a destiempo en el segundo. Solo se
  mueve el dibujo: **la colisión es la misma de antes** (no hay atascos ni caídas, comprobado).
- **Faroles de piedra:** con su llama; los del primer tramo tiñen la roca de al lado. En el perfil alto, sus luces
  reales tiemblan como el fuego. El farol de la cabeza del primer puente deja su sitio a los faroles colgados.
- **Escalera de la presa** (se ve desde la entrada): sillares con su tono y albardilla con musgo; misma colisión.
- **Intacto:** `trazado.gd` (geografía, piezas, posiciones, por dónde se anda, zonas de cámara), identificadores,
  encuentros, progreso, combates fijos y la 2D.

**Perfiles** (detalle escalonado; el alto no se rebaja): bajo sin relieve, sin grano cercano, veta sencilla, una capa de
agua, 4 brumas, sin rocío ni colchón de niebla, menos piezas pequeñas en el puente (sin cuerda baja, nudos ni clavos);
medio y alto, todo.

### 2. Archivos y commits (rama `area-garganta3d`)

- `cc9a07a` unión de `integracion-experimental` (`eb8bd94`).
- `acfb5e3` `zonas3d/garganta/roca.gd`: `Lotes.poner_color` (color por vértice en un lote).
- `a331006` `zonas3d/garganta/materiales.gd`: sombreados (roca, puente que se mece, llama, bruma, hierba verde).
- `c69c045` `zonas3d/garganta/piezas.gd` y `zonas3d/garganta_3d.gd`: los puentes colgantes y el temblor del fuego.
- `a0ee5ff` `zonas3d/garganta/escenario.gd`: entrada, adoquines, peñas, helechos, caída, faroles y escalera.
- `b266e61` pruebas: `pruebas/prueba_garganta3d_tramo.gd` (nueva, auto), `pruebas/prueba_garganta3d_tramo_fotos.gd`
  (nueva, ventana) con su `.uid`, y sus dos líneas en `pruebas/lista_pruebas.txt`.
- Este informe, en su propio commit.
- `.uid` ajeno apartado (no confirmado): `pruebas/prueba_orden_pv03.gd.uid` →
  `D:\REBELUM_respaldos\2026-11-09_uids\aethelgard\pruebas\`. El de `prueba_garganta3d_tramo.gd` no lo generó Godot
  (lo hará el editor).

### 3. Pruebas

- **Importación aislada** de la copia tras la unión: sin errores (datos en
  `D:\REBELUM_diagnostico\importaciones\garganta3d_2026-11-09\`).
- **`prueba_garganta3d_tramo`** (nueva, auto, SUPERADA en todas las pasadas): entrada → umbral → cornisa → cabeza
  del puente → mitad → islote y vuelta con el dedo (26-65 fotogramas por tramo); de la entrada al islote y de vuelta
  con la cruceta (183 y 162 fotogramas); empujando a izquierda y derecha en mitad del puente, Kael se queda en el
  tablero (x = −12,70 y −11,30; el tablero va de −13,1 a −10,9); altura mínima −0,54 m (la comba del puente); los
  158 cuerpos que chocan, quietos; la escena trae caída, bruma, luz fría, cintas, helechos y llamas.
- **`prueba_garganta3d`** (la de siempre): SUPERADA tras los cambios.
- **Batería completa aislada** sobre `b266e61`: SUPERADAS 56 · FALLIDAS 2 · MANUALES 32 · NO SEGURAS 0; `partida.save`
  real, carpeta real de datos y proyecto sin cambios
  (`D:\REBELUM_diagnostico\garganta3d\2026-11-09\bateria\2026-11-09_181258\resumen.md`). Las dos fallidas son
  `prueba_mando` y `prueba_teclado` («Intro / A junto a Tilo no abre el diálogo», en Pastos Verdes): **no vienen de
  T-102**. Fallan igual con el código de la Garganta de antes
  (`D:\REBELUM_diagnostico\garganta3d\2026-11-09\bateria\con_codigo_de_antes\2026-11-09_182317\`) y fallaron igual a
  las 17:46-17:47 en las copias de animaciones y combate (`D:\REBELUM_diagnostico\pruebas\2026-11-09_174617\` y
  `2026-11-09_174741\`): llegan con la unión de `eb8bd94`. `prueba_dpad`, `prueba_toque` y `prueba_escenas`: SUPERADAS
  (repetidas en `D:\REBELUM_diagnostico\garganta3d\2026-11-09\bateria\2026-11-09_182231\`).
- Aviso que no es mío: «N resources still in use at exit» sale en casi todas las pruebas de esta integración (también
  en las de otras copias) y con `--verbose` son reproducciones de audio vivas al salir; es intermitente.
- **Cortes de Godot con ventana:** 4 de unas 20 pasadas con ventana terminaron a los pocos segundos con código 0 y sin
  error ni rastro en el registro de Windows, **también con el código de antes** (2 de ellas). Lanzado a mano (aislado)
  no se repitió. Pendiente de averiguar; no parece de la escena (había 4-12 Godot de otros especialistas abiertos).

### 4. Evidencias (PC: Intel + RTX 3050 Laptop, OpenGL 3.3 Compatibility; NO es el Redmi)

- **Comparación antes/después desde los mismos puntos** (9 vistas: 6 con la cámara del juego y 3 fijas):
  `D:\REBELUM_diagnostico\garganta3d\2026-11-09\comparacion_tramo_alto.jpg` y `comparacion_tramo_bajo.jpg`.
  Las capturas sueltas: antes en `...\2026-11-09\ab\antes_1\...\prueba_garganta3d_tramo_fotos\` (y
  `...\antes\2026-11-09_174027\`), después en `...\ab\despues_1\...` (1280 × 720) y
  `...\despues\2026-11-09_181206\` (1600 × 720, el móvil 20:9: con el aspecto «keep» el juego dibuja 1280 × 720 con
  franjas, así que la imagen del juego es la misma; antes en `...\antes\2026-11-09_173045\`).
- **Dibujo por vista** (deterministas; `...\2026-11-09\ab\comparacion_dibujo.txt`): llamadas de dibujo bajo
  +9 a +32 (p. ej. cornisa 119 → 143, puente 104 → 123), alto +15 a +44 (cornisa 207 → 242); primitivas +8-10 % en
  bajo (168 k → 185 k en la cornisa) y +11-14 % en alto (453 k → 521 k).
- **GPU del PC por vista** (medianas, dos pasadas alternas antes/después): bajo 0,58 → 0,64 ms en la cornisa y el
  puente (+0,06 ms); alto 1,50 → 1,29-1,63 ms (dentro del ruido).
- **Tiempos por fotograma** (`medir_garganta3d`, PC, alterno; `...\2026-11-09\ab_medida\comparacion_medida.txt`):
  con otros Godot en marcha, el ruido (±1 ms) es del tamaño de la diferencia: bajo, entrada 4,35 → 4,03 ms y puentes
  3,85 → 4,29 ms (mediana); alto, entrada 4,21 → 7,13 ms y puentes 4,20 → 5,94 ms (la arena, que no cambia, también
  subió 1,2 ms: no concluyente). Hay que repetirlo en un hueco sin otra carga.
- **Memoria** (misma medida): vídeo +0,6 MB (bajo) y +1,5 MB (alto); estática +1 MB.
- **Carga de la región** (conteo sin ventana, alterno): bajo 1,44-1,69 s → 1,59-1,82 s, alto 1,75-2,01 s →
  2,11-2,46 s (+0,1 a +0,4 s: la generación por código de peñas, adoquines y tablas). Con ventana: alto 3,52 → 3,69 s,
  bajo 2,52 → 2,50 s.
- **Conteo de la escena** (bajo/alto): mallas 173/188 → 198/215, MultiMesh 15 → 23, transparentes 40/46 → 56/63,
  partículas 36/130 → 40/169, triángulos de malla 192 k/260 k → 196 k/276 k, roca igual, luces reales igual (0/6).
- **malioc (Mali-G57)**, estimación con el código del sombreado de roca pasado a ESSL 3.0 (sin la iluminación de
  Godot): ciclos aritméticos del fragmento, bajo 3,10 → 4,12 y alto 4,00 → 6,78, registros 32 → 31 (ocupación 100 %).
  Llama 1,50 ciclos; madera del puente 1,12. Archivos en `D:\REBELUM_diagnostico\garganta3d\2026-11-09\malioc\`.
  Primer intento: 8,60 ciclos en bajo con los fuegos por píxel; por eso fuegos, humedad y distancia pasaron a los
  vértices y la veta del bajo va sin suavizado.

### 5. Límites

- **Pendiente en Redmi:** fluidez de la entrada y del puente en el perfil bajo (la roca cuesta +1 ciclo por píxel
  según malioc), las ~25 llamadas de dibujo más, la carga (+0,1-0,4 s en el PC) y cómo se ven las vetas, la bruma y la
  llama a 720 p. Nada de esto se ha probado en el teléfono.
- Los tiempos por fotograma del PC no son concluyentes (otros Godot abiertos).
- El aspecto lo he juzgado yo en las capturas; falta el juicio del usuario (sobre todo la caída nueva junto al primer
  puente y el tono de las tablas).
- Sonido del tramo (agua de la caída, crujido del puente, viento): no es mío; lo pido abajo.
- Kael no sube y baja con el vaivén (2 cm): no se nota en las capturas.

### 6. Siguiente paso y cambios que pido

1. Medir en el Redmi el perfil bajo en la entrada y el primer puente; si no llega a 30 FPS: quitar las vetas del
   bajo (−0,6 ciclos) y juntar las llamas en una malla (−10 llamadas).
2. El mismo acabado en el resto (segundo puente ya mece; faltan islote, levadizo, puerta, arena, cornisa baja, nido,
   palanca y grieta).
3. **Sonido** (especialista de sonido), en `garganta_3d.gd`, `_sonido_3d`: una `fuente_3d` de agua en la caída del
   primer puente (x ≈ −15, y ≈ −2, z = 15,2) y crujidos de madera al pisar los puentes colgantes.
4. Que el coordinador repita `medir_garganta3d` en un hueco sin otra carga (alterno antes/después) para cerrar los
   tiempos del PC.
5. **Coordinador:** `prueba_mando` y `prueba_teclado` fallan desde la unión de `eb8bd94` (también en otras copias):
   revisar el diálogo de Tilo con Intro / A en `integracion-experimental`.


## 2026-11-09 19:10 · T-102, segunda parte: el resto de la Garganta, Kael en el puente, comentarios y el agua de la caída

Encargo del coordinador tras integrar la primera parte (`0366da1`): unir `integracion-experimental` (`--no-ff`, con el
arreglo de mando y teclado `9f94601`) → `a5df880`; después, el mismo acabado en el resto del recorrido, que Kael se meza
con el puente si es barato, y los enganches de narrativa y de sonido en `garganta_3d.gd`.

### 1. Qué se ha hecho (observado en el código y comprobado ejecutando, aislado)

- **Kael se mece con el puente.** El vaivén ya no usa el `TIME` del sombreado, sino un reloj que pone la región cada
  fotograma (`piezas.mecer`). Con la misma cuenta (`piezas.vaiven_en`), el modelo de Kael, Lya y Garon (su nodo
  `ajuste`, no su posición) se mueve con las tablas: hasta 4-5 cm de lado y 2 cm en vertical en el centro.
  - El recorrido, la colisión, el guardado y `_prohibido` siguen usando la posición quieta.
  - Coste: unas cuentas por personaje y fotograma, más 6 `set_shader_parameter`.
- **Comentarios de narrativa** (`dialogos/comentarios.gd`, informe de narrativa §6):
  - al llegar, a los 2,5 s;
  - la primera vez que Kael queda a menos de 12 m de la cascada del fondo;
  - 1,2 s después de abrir el cofre del nido.

  Salen en la interfaz de la región solo si no hay nada en marcha (`ocupado()`, saliendo).
- **Sonido:** en `_sonido_3d`, una `fuente_3d` de «cascada_grande» a −6 dB en la caída del primer puente
  (x = −15, y = −2, z = 15,2). La línea de la cascada del fondo, igual que antes (ahora con sus constantes, que
  comparte con el comentario).
- **Resto del recorrido:**
  - **arena de Gorthor:** enlosado de dovelas en anillos, en una sola malla. Teñidas de rojo junto al trono, algunas
    rotas o con musgo, y el anillo partido de bronce embutido en el centro. Bordillo con su tono.
  - **puerta sellada:** marco de sillares con su tono; sigue volviéndose medio transparente si tapa a Kael. Dos braseros
    a los lados, fuera de donde se anda, con llama y calor en la roca: los dos huecos de fuego que quedaban.
  - **levadizo:** cada tabla con su tono, y el estribo en sillares.
  - **palanca:** pedestal de sillares.
  - **cornisa baja:** senda de adoquines sueltos, sin colisión, y helechos al pie del muro y en la grieta (junto a la
    cascada del fondo).
  - **bajada al nido:** rellano, peldaños y pretil en sillares, con la misma colisión.
  - La roca de todo el recorrido ya tenía el sombreado nuevo de la primera parte.
- **Sin sombreados nuevos en esta parte.** `sillar()` y `madera_color()` son StandardMaterial3D con color por vértice,
  así que no hace falta malioc; la primera parte ya lo midió.
- **Intacto:** `trazado.gd`, los identificadores, los encuentros, el progreso y la 2D.

### 2. Commits (rama `area-garganta3d`)

- `a5df880`: unión de `integracion-experimental` (`0366da1`).
- `ec77c4e`: vaivén de Kael, comentarios y el agua de la caída. Toca `materiales.gd`, `piezas.gd`, `garganta_3d.gd`, la
  prueba del tramo y su `.uid`.
- `5836b05`: resto del recorrido. Toca `escenario.gd`, `piezas.gd`, `materiales.gd` y `prueba_garganta3d_fotos.gd` (que
  ahora anota llamadas, primitivas y GPU de cada vista).
- `bdb6ac6`: unión de `integracion-experimental` (`6adc4d9`): el `.uid` de `prueba_garganta3d_tramo.gd`, en conflicto,
  se queda con el de la integración.
- `21f8832`: los crujidos de los puentes y el viento en las cuerdas, en `_sonido_3d`.
- Este informe, en su propio commit.
- **`.uid` ajenos apartados** (no confirmados): `dialogos/comentarios.gd.uid`, `pruebas/prueba_comentarios.gd.uid` y `pruebas/prueba_comentarios_3d.gd.uid`, en
  `D:\REBELUM_respaldos\2026-11-09_uids\`.
- **Importación aislada repetida** tras la unión: había sonidos nuevos sin importar.

### 3. Pruebas

- **`prueba_garganta3d_tramo`** (ampliada): SUPERADA. Además de lo de antes:
  - en mitad del puente, el modelo de Kael va con las tablas (0,038; −0,012) m, y fuera del puente vuelve a su sitio;
  - salen los tres comentarios: llegar, cascada y cofre.
- **`prueba_garganta3d`** y **`prueba_comentarios`**: SUPERADAS.
- **Batería completa aislada** sobre `5836b05`: SUPERADAS 60 · FALLIDAS 0 · MANUALES 33 · NO SEGURAS 0; `partida.save` real, carpeta real de datos
  y proyecto sin cambios (`D:\REBELUM_diagnostico\garganta3d\2026-11-09\bateria_resto\2026-11-09_184409\resumen.md`).
  Mando y teclado vuelven a pasar con el arreglo de la integración (`9f94601`).
- **Tras unir `6adc4d9` y enganchar los sonidos de la tanda 5** (`21f8832`), 13 pruebas escogidas: Garganta (las dos),
  efectos, audio, comentarios (2D y 3D), esperas, mando, teclado, cruceta, toque, escenas e integridad, todas
  SUPERADAS; datos reales sin cambios (`D:\REBELUM_diagnostico\garganta3d\2026-11-09\bateria_sonidos\2026-11-09_185350\resumen.md`).
  Sin avisos de efecto desconocido en la Garganta; **nada oído** (prueba muda).

### 4. Evidencias (PC con RTX 3050 Laptop; no es el Redmi)

- **Antes y después desde los mismos puntos** (`ec77c4e` → `5836b05`, 10 vistas por perfil):
  `D:\REBELUM_diagnostico\garganta3d\2026-11-09\comparacion_resto_alto.jpg` y `comparacion_resto_bajo.jpg`.
  - Capturas sueltas: `...\2026-11-09\resto_ab\fotos_antes_1\` y `fotos_despues_1\`.
  - Las de antes de esta parte también están en `...\2026-11-09\resto_antes\`.
- **Dibujo por vista** (dos pasadas alternas; `...\resto_ab\comparacion_dibujo.txt`):
  - llamadas de dibujo: bajo +2 a +11 (puerta 76 → 87, arena 70 → 78); alto +0 a +14;
  - primitivas: +14 a +16 k en todas las vistas. Son las mallas grandes de una pieza (la senda baja y las dovelas): se
    dibujan aunque no se vean (pendiente: partirlas por tramos);
  - GPU del PC: igual dentro del ruido (bajo ~0,6-0,7 ms, alto ~1,3-1,7 ms).
- **Conteo** (`...\resto_ab\conteo.txt`), bajo/alto:
  - mallas 198/215 → 207/224;
  - MultiMesh 23 → 24;
  - transparentes 56/63 → 60/67;
  - triángulos 196 k/276 k → 202 k/283 k.
- **Carga de la región:**
  - sin ventana: bajo 1,65-1,89 → 1,73-1,77 s; alto 2,03-2,07 → 2,11-2,55 s;
  - con ventana (una pasada): bajo 2,69 → 3,29 s; alto 3,12 → 3,88 s.
  - Ruidoso, pero apunta a +0,1-0,6 s por la generación por código. Pendiente: guardar las mallas hechas.
- **Tiempos por fotograma** (`medir_garganta3d`, una pasada de cada; `...\resto_ab\comparacion_medida.txt`):
  - subieron 0,5-1,5 ms en todas las fases, también en «puentes», que en esta parte casi no cambia;
  - con 4-12 Godot de otros especialistas en marcha no es concluyente: hay que repetirlo en un hueco sin carga;
  - memoria de vídeo: +0,4-0,5 MB.

### 5. Límites

- **Pendiente en Redmi:** todo lo de la primera parte, más las ~5-14 llamadas de dibujo, los +15 k triángulos y la
  carga.
- **Los comentarios salen en las capturas** de `prueba_garganta3d_fotos`, abajo a la derecha. Es lo previsto, pero en
  la vista 04 tapan algo del abismo: que lo mire narrativa.
- **Kael se mece y el tablero también**, pero los pies pueden adelantarse 1-2 cm en los extremos de un tramo: no se ve
  en las capturas.
- Sonidos enganchados sin oírlos: el agua de la caída, `puente_cruje` en cada puente y `viento_cuerdas` por el borde
  de la cornisa (las tres líneas de sonido, `docs/audio/inventario_sonidos.md`, tanda 5).

### 6. Siguiente paso

1. Partir por tramos la senda baja, la Vía del Peregrino y el enlosado de la arena, para que no se dibujen enteros.
2. Que la generación (peñas, sillares, dovelas) se haga una vez y se guarde: la carga vuelve a lo de antes.
3. Medir en un hueco sin carga y en el Redmi (perfil bajo). Si hace falta, sacar las vetas del bajo y juntar las llamas.
4. Luego, T-103 (Oakhaven 3D), como ha dicho el coordinador.

## 2026-11-09 23:10 · T-102, optimización: roca guardada, peñas reutilizadas y piezas por tramos

Unión previa de `integracion-experimental` @ `dca4c1c` → `4eb98e4`. Nota: un primer intento (hacia las 19:00) se cortó
a mitad de una medida alterna que había dejado los archivos «de antes» en disco: por eso se perdió lo hecho. Ahora se
confirma antes de medir y la medida restaura con `try/finally`.

**Qué se ha hecho** (`873bb33`, `85db81a`; comprobado ejecutando, aislado)
- **Roca guardada:** cada malla de roca (26) y la colisión de los suelos se guardan en `user://cache_garganta/` la
  primera vez por perfil (1,4 MB en alto) y se leen después. Si falta o no se lee, se genera como antes. Hay que subir
  `VERSION_CACHE` si cambia la roca. Se apaga con «sin_cache» (`medir_garganta3d`).
- **Peñas:** 6 formas hechas una vez, giradas y escaladas (antes, una desde cero por peña).
- **Por tramos:** Vía del Peregrino y senda baja en MultiMesh de 12 m (antes, una de 70 m dibujada siempre); enlosado
  de la arena en cuatro cuartos.
- `construir()` apunta lo que tarda cada paso (`escenario.tiempos`); `medir_garganta3d … conteo` lo escribe, con
  `etiqueta=` para varias cargas en la misma pasada.

**Medidas** (PC, alternas: dos rondas antes `4eb98e4` / después `873bb33`)
- **Carga de la región** (`D:\REBELUM_diagnostico\garganta3d\2026-11-09\optimizar_ab2\cargas.txt`):

  | Perfil | Antes | Después, primera vez (caché fría) | Después, segunda vez (caché caliente) |
  |---|---|---|---|
  | alto | 2,10-2,77 s | 2,18-2,22 s | 1,60-1,61 s (−0,5 s) |
  | bajo | 1,74-1,85 s | 1,76-1,87 s | 1,37-1,40 s (−0,4 s) |

  La primera vez cuesta igual que antes: lo que se ahorra en peñas se gasta en guardar.
- **Dibujo por vista** (`...\optimizar_dibujo\comparacion_dibujo.txt`):
  - primitivas: −7 k a −29 k en las vistas de juego (−4 a −15 %); igual en las vistas de toda la garganta;
  - llamadas de dibujo: −3 a +10 en las vistas de juego, +29 en las de toda la garganta (se ven más tramos);
  - GPU del PC: igual o algo menos (alto 1,6 → 1,2-1,5 ms).
- **Mismo aspecto y misma colisión.** `prueba_garganta3d` y `prueba_garganta3d_tramo` superadas; la segunda, leyendo
  ya la caché que dejó la primera (`...\optimizar\2026-11-09_*`).

**Límites:**
- **Pendiente en Redmi:** si las ~10 llamadas de dibujo más pesan más que los ~20 k vértices menos. Si pesan, tramos
  de 18-24 m.
- **La caché vive en `user://`,** fuera de las partidas: no toca `partida.save`. Si el usuario borra los datos de la
  app, se regenera sola.