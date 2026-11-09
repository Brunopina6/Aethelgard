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
