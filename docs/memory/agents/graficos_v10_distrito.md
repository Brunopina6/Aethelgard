# Gráficos · V10: el distrito de los oficios de Oakhaven 3D

## 2026-11-10 21:25 · Entrega (rama `claude/v10-distrito`, copia `D:\Aethelgard_v10_distrito`)

Encargo (V10, hitos 2 y 10): el primer distrito funcional de Oakhaven 3D junto a la plaza, sin duplicar la ciudad: una
herrería, un taller de armaduras, la botica con frente, puestos de mercado, una zona residencial con patios y un rincón
secreto con una interacción; modelado por guion de Blender, versiones ligeras, mallas juntadas, colisiones simples,
cartel legible en cada comercio; cada establecimiento con su encargado y su botón, que abre su diálogo si existe y
después el servicio (`servicios.gd`) si existe. Enganche mínimo en `oakhaven_3d.gd`.

### Qué hay (observado en el código y comprobado ejecutando, 10/11, commits `219c62e` a `0329461` y el de este informe)

| Archivo | Qué es |
|---|---|
| `aethelgard/zonas3d/oakhaven/fuente/crear_distrito.py` | Genera el kit con Blender 5.2.3: `blender -b --factory-startup -P crear_distrito.py -- <carpeta>`. Misma semilla, mismo GLB (SHA-256 igual en dos pasadas) |
| `aethelgard/zonas3d/oakhaven/modelos/distrito.glb` (0,85 MB) y `distrito_ligero.glb` (0,56 MB), con sus `.import` | El distrito ya montado en coordenadas de la ciudad: 12 618 / 8 035 triángulos. Importación sin LOD, tangentes ni mallas de sombra (como el claro) |
| `aethelgard/zonas3d/oakhaven/distrito.gd` | `Distrito.crear(region, ciudad, mat, perfil, nombre_perfil)`: junta, choca, pone suelo, fuego, humo, chispas, luciérnagas y encargados; `piezas()`, `accion(id)`, `ocupado()`, `camara(p, por_defecto)` |
| `aethelgard/zonas3d/oakhaven_3d.gd` | El enganche (unas 10 líneas): crear, sumar sus puntos al botón, pasarle la acción, `ocupado()` y su zona de cámara |
| `aethelgard/pruebas/prueba_distrito_oakhaven.gd` (auto, en `lista_pruebas.txt`) | La prueba sin ventana |
| `aethelgard/pruebas/fotos_distrito_oakhaven.gd` | Capturas con ventana, con y sin el distrito (`sin_distrito`); no es prueba |
| `docs/recursos.md` | Fila de procedencia: obra propia |

**Dónde** (una casilla es un metro; la cámara mira al norte):
- **Calle de los Oficios**, al sureste de la Plaza del Tapiz, de la Calle Mayor (x 41) a la Calle de la Torre (x 68),
  z 34,6-37. Al norte, los oficios (sin pisar el mercado, z < 32, ni la plaza); al sur, los jardines de la fila de casas.
- **Herrería de Maese Ferro** (x 42-48): taller de piedra con tejado rojo de una vertiente y, al aire libre delante, la
  fragua con las brasas a la vista, campana tiznada, chimenea de sillares con humo, fuelle, yunque sobre tocón, tina de
  templar, carbón, barras, expositor de espadas y herramientas colgadas en la fachada. Ferro golpea el yunque (alza el
  martillo, golpe, chispas; cada tres golpes se para a mirar la pieza) y deja de hacerlo para atender.
- **Taller de armaduras de Hilda** (x 48,6-54,4): entramado con zócalo de piedra, tejado de pizarra a dos aguas,
  escudos (redondo con umbo, rojo con banda dorada, azul con galón), lanzas cruzadas, mostrador con yelmo y piedra de
  afilar y, a la derecha, el maniquí con la armadura completa y penacho rojo.
- **Dos puestos** (x 55-60) con toldos a rayas (rojo y verde con crema), género en cajones (manzanas, pan, cebollas,
  coles, calabazas), sacos y ristras colgando.
- **Dos casas con patio** (x 60,4-67): una de hastial al sur (piedra abajo, entramado volado arriba, tejado rojo) y otra
  estrecha de pizarra con buhardilla y porche; murete con cancela, banco, macetas, árbol con manzanas, ropa tendida,
  barril de lluvia y leña.
- **Jardines de la fila de casas** (al sur de la calle): valla encalada, murete, seto o valla de madera; macizos de
  flores, huerto, banco, tendedero, carretilla con leña y espantapájaros. No se pisan (ver «Por qué la cámara…»).
- **Frente de la botica** (x 33-36, en la plazuela): el tenderete de Mirta delante de la ventana, toldo corto y alto
  (verde y crema) que no la tapa, estante con tarros, mostrador con frascos de colores, mortero y balanza, ramilletes
  de hierbas, macetas y el cartel del mortero.
- **Rincón del pozo** (secreto, x 46,3-49,7; z 39,6-44,6): entre dos casas, tras un arco de piedra y madera comido por
  la hiedra con un farolillo; pozo de brocal con musgo, tejadillo, cubo, farolillo, luciérnagas posadas dentro y otras
  en el aire; banco de piedra, helechos e hiedra por las paredes.
- **Carteles** (silueta oscura sobre tablero iluminado, legibles a 1280 × 720 y a 1600 × 720): yunque (cuelga de un
  brazo de la chimenea, encima del fuego), escudo (en la fachada de Hilda) y mortero (de un brazo en la esquina de la
  botica).

**Interacción** (comprobado ejecutando en la prueba, sin diálogos ni `servicios.gd` en esta rama):
- Puntos: forja (46,4; 35,3), armaduras (50,55; 35,35), botica (34,75; 42,25) y pozo (47,95; 40,6); botones «Hablar con
  Maese Ferro», «Hablar con Hilda», «Hablar con Mirta» y «Examinar el pozo viejo».
- Al pulsar: si existe el diálogo (`Oak.dialogo_de(pnj)` si narrativa añade a Ferro, Hilda o Mirta a `NPCS`; si no,
  `dialogos/oakhaven/oak_ferro.dtl`, `oak_hilda.dtl`, `oak_mirta.dtl`), se abre con Dialogic (antes,
  `Oak.registrar_dialogic()`); al acabar, el servicio se abre **solo si el diálogo emitió `oak:servicio_<tipo>`** (el
  contrato de DISENO_V10: así «no, gracias» no lo abre). Las demás señales `oak:` del diálogo (encargos) se aplican con
  `Oak.aplicar_senal` y su aviso se enseña, como en la 2D. Sin diálogo: el servicio directamente.
- Servicio: `load("res://servicios.gd").abrir(region, "forja" | "armaduras" | "botica")` si el archivo existe y tiene
  `static func abrir`; si devuelve un nodo, la escena queda «ocupada» (Kael quieto) mientras siga visible. Si no existe:
  aviso «Servicio en preparación». `auditar_recursos` lo apunta como ruta opcional que falta (no falla).
- El pozo: una ráfaga de luciérnagas sube del pozo y un texto (tres, se turnan). **Los textos son propuesta de
  gráficos, sin canon** (narrativa puede cambiarlos en `distrito.gd`, `TEXTOS_POZO`); no tocan el progreso ni la
  partida.

### Por qué la cámara mira algo más desde arriba en la calle (y lo que pido en `ciudad.gd`)

Comprobado en las primeras capturas (`D:\REBELUM_diagnostico\v10\distrito\iter1\d02_herreria_despues_1280x720_alto.png`):
justo al sur de la manzana están cuatro casas del relleno de la ciudad (`ciudad.gd`/`oakhaven_piezas.gd`: x 42-46,
50-55, 56-62 y 63-67, z 40-45) con tejados de 7,4 a 8,3 m (medidos con Blender en sus GLB). Con la cámara de la ciudad
(52°), tapan a Kael en todo lo que queda a menos de ~5,5 m de ellas: la mitad sur de la manzana. No van en el grupo
`ocluye` (están juntadas con su trozo de ciudad), así que no se vuelven transparentes.

Lo que hice, sin tocar `ciudad.gd`:
- Lo que se pisa y los puntos de servicio, al norte (z ≤ ~36,5); la franja tapada son jardines cerrados (no se pisan).
- En la Calle de los Oficios (x 41-68, z 31,5-37,2) la zona de cámara del distrito pide 60° en vez de 52° (misma
  distancia); fuera, la de siempre. Con eso Kael se ve en toda la calle (capturas `d04` y `d05`). Es lo único que cambia
  la sensación de la cámara; la transición es la suave de siempre (`_camara_zona`).

**Lo que pido al coordinador (archivo de otro: no lo he tocado):** que esas cuatro casas se junten aparte y cuelguen de
su choque, como `TAPAN` (botica y guardia). Así se vuelven transparentes al tapar a Kael y el distrito podría volver a
52° (quitar `CAMARA`/`camara()` o dejarla en 52). Cambio exacto en `aethelgard/zonas3d/oakhaven/ciudad.gd`:

```gdscript
# junto a TAPAN:
# Casas del relleno al sur de la Calle de los Oficios (V10, distrito.gd): pueden tapar a Kael; van aparte, como TAPAN.
const TAPAN_RELLENO := [Rect2i(42, 40, 4, 5), Rect2i(50, 40, 5, 4), Rect2i(56, 40, 6, 4), Rect2i(63, 40, 4, 4)]

func _clave_relleno(r: Rect2i) -> String:
	return "casa_%d_%d" % [r.position.x, r.position.y] if r in TAPAN_RELLENO else ""

# en _relleno(): «_fundir(n)» pasa a «_fundir(n, _clave_relleno(r))», y
#     _caja_choque(Rect2(r), ALTO_EDIFICIO)
# pasa a
#     var cuerpo := _caja_choque(Rect2(r), ALTO_EDIFICIO)
#     if _clave_relleno(r) != "":
#         _cuerpos[_clave_relleno(r)] = cuerpo
# en _fundir_relleno(): «_fundir(n)» pasa a «_fundir(n, _clave_relleno(r))»
# y VERSION_CACHE := "t103a" pasa a "v10a" (cambia cómo se juntan: la caché vieja no vale)
```

(Con la caché, `_relleno` ya crea los cuerpos antes de `_edificios_de_cache`, que los busca por `propio:casa_…`.)
Pendiente de verificar: no lo he ejecutado (es archivo de otro); son 4 mallas más (4 llamadas de dibujo) en la ciudad.

### Presupuesto (comprobado ejecutando, prueba del 10/11 21:20)

| Perfil | Kit | Triángulos montados (con suelo y losas) | Mallas | Choques | Montaje (PC, sin ventana) |
|---|---|---|---|---|---|
| alto | `distrito.glb` | 15 184 (tope 20 000) | 23 | 40 | 38,8 ms |
| medio y bajo | `distrito_ligero.glb` | 8 799 (tope 10 000) | 22 | 39 | 18,5 ms |

Mallas: 4 edificios × (base + brillo), lo bajo (base + brillo), el suelo, 3 encargados + el brazo de Ferro, 2-3 llamas,
el resplandor del suelo y 4 sistemas de partículas por CPU (humo 14/8, chispas 12/6, luciérnagas 9/5, ráfaga 26/14).
Luz real: solo la de la fragua y solo con `luces_faroles` (perfil alto), que parpadea. Sin texturas propias (el grano
es el de `mat.sillar()`, como los edificios de la ciudad; las figuras, color de vértice sin grano). Sombras de los
edificios solo donde el perfil las pide (`sombras_edificios`). Los choques son cajas; sus huellas pasan a
`ciudad.bloqueos` (las respeta `_prohibido` y `_ajustar_destino`) y la hierba de la ciudad que caía debajo se quita
(escala cero): 125 matas/flores/arbustos en alto, 46 en bajo.

**Orientación en el PC** (no es una medida: 1280 × 720, mediana de la GPU de `RenderingServer` en los fotogramas de
espera de cada vista, con otro Godot de pruebas en `D:\Aethelgard_v10` al empezar y sin confirmación de un hueco sin
carga). **No declaro FPS de Android.**

| Vista | Perfil | Llamadas antes → después | Primitivas | GPU (ms) |
|---|---|---|---|---|
| barrio desde el sur (`d09`) | alto | 323 → 353 | 939 211 → 965 826 (+2,8 %) | 2,19 → 2,26 |
| barrio desde el sur (`d09`) | bajo | 177 → 196 | 287 602 → 296 113 (+3,0 %) | 0,75 → 0,76 |
| herrería (`d02`) | alto | 143 → 156 | 884 902 → 827 761 (a 60° se ve menos ciudad) | 1,91 → 1,93 |
| herrería (`d02`) | bajo | 56 → 62 | 195 600 → 177 047 | 0,64 → 0,62 |

### Pruebas (comprobado ejecutando, 10/11, datos aislados)

- Importación aislada como `ci_local.ps1` (última: `D:\REBELUM_diagnostico\importaciones\v10_distrito_2026-11-10_211357`);
  `project.godot` restaurado por el guion tras cada importación (la importación sin editor le borra el registro de
  Dialogic); no queda cambiado.
- `ejecutar_pruebas.ps1 -Solo prueba_distrito_oakhaven,prueba_oakhaven3d,auditar_recursos`: **3 SUPERADAS**, código 0;
  partida real, carpeta real de datos y proyecto sin cambios; ningún Godot más en esta copia. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-10_212032\resumen.md` (y las pasadas anteriores `2026-11-10_211908` y
  `2026-11-10_211055`).
- `prueba_distrito_oakhaven` comprueba: los dos GLB (colores de vértice, 9 objetos, 36-37 cajas, 12 anclas); sin el
  distrito con `oakhaven_sin_distrito`; en alto y bajo, presupuesto, mallas, choques en los bloqueos de la ciudad,
  hierba quitada, ningún punto en un bloqueo; Kael anda de la Calle Mayor a los cuatro puntos sin atascarse, sale cada
  botón con su texto y su acción hace lo que toca; no entra en la herrería ni en los jardines; el brazo de Ferro se
  mueve.
- `prueba_oakhaven3d` (el tramo 1: Aldric, Calle Mayor, plaza, Calle del Cuervo, posada, guardar y volver, salida)
  sigue superada con el distrito puesto.

### Evidencias (`D:\REBELUM_diagnostico\v10\distrito\`)

- `comparacion_antes_despues_alto.png` y `comparacion_antes_despues_bajo.png`: láminas antes / después (barrio desde el
  sur, herrería, puestos, botica y rincón del pozo).
- `antes\` y `despues\`: las 10 vistas (`d01` a `d10`), perfiles alto y bajo, 1280 × 720, mismos encuadres (Kael en los
  puntos de servicio; antes, la misma cámara de la ciudad sin el distrito).
- `movil_1600x720\`: las mismas vistas a 1600 × 720 (proporción del Redmi, con las franjas de «keep»), bajo y alto.
- `iter1\`: la primera versión, donde se ve el problema de las casas del sur tapando a Kael (`d02`, `d03`, `d05`).
- `fotos.ps1`, `importar.ps1` y `comparar.ps1`: cómo se hicieron (datos aislados en `_aislado\`).

### Límites

- **Sin medidas de rendimiento de verdad** (tiempos por fotograma, memoria): no tengo confirmado un hueco sin carga; lo
  de arriba es orientación. Nada probado en el Redmi.
- **Sin diálogos ni `servicios.gd` en esta rama**: el camino con diálogo (abrirlo, la señal `oak:servicio_…`, las
  señales de encargos) está escrito pero solo se ha ejecutado el camino sin diálogo (aviso «Servicio en preparación»).
  Cuando lleguen `oak_ferro`, `oak_hilda`, `oak_mirta` y `servicios.gd`, la misma prueba recorre el otro camino (lo
  detecta sola); conviene volver a pasarla.
- **La cámara a 60° en la calle** es un apaño hasta que `ciudad.gd` haga transparentes las cuatro casas del sur (arriba).
- El pozo se ve a través de la guardia medio transparente (la de la ciudad, `TAPAN`), algo turbio.
- `suelo_de_pasos` sigue diciendo «hierba» en la calle nueva (no es un lugar de `Oak.LUGARES`); no lo he tocado.
- El martillo de Ferro no suena (sonido no es mi área).
- No comprobado: que Lya y Garon (`grupo_3d.gd`) no se metan en los jardines o los oficios al seguir a Kael (no miran
  `ciudad.bloqueos` si no lo hacen ya).
- El mostrador de Mirta cae en la plazuela de la botica (lugar pisable): una partida 2D guardada justo ahí volvería a la
  3D dentro de su caja (muy improbable; el resto del distrito está fuera de los lugares de la ciudad).

### Siguiente paso propuesto y lo que necesito de otros

1. Coordinador: el cambio de `ciudad.gd` de arriba (casas del sur como `TAPAN`) y, con él, probar la calle a 52°
   (`distrito.gd`, `CAMARA`).
2. Narrativa: `oak_ferro`, `oak_hilda`, `oak_mirta` con la señal `oak:servicio_<tipo>` al final (DISENO_V10) y, si
   quiere, los textos del pozo (`TEXTOS_POZO`).
3. Sonido: el golpe del martillo (el momento está en `distrito.gd`, `_martillo`, donde saltan las chispas), el fuego de
   la fragua y el pozo (eco, luciérnagas).
4. Coordinador: `servicios.gd` con `static func abrir(padre, servicio)`; si devuelve su nodo de interfaz, Kael se queda
   quieto mientras esté visible.
5. Medir en el Redmi (banco de Oakhaven 3D) antes y después, perfil bajo, en un hueco sin carga.
