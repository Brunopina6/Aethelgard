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
