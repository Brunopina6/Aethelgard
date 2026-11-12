# Migración 3D, V12 fase 2 · región 3: Oakhaven, la ciudad central (lugar 0)

## 12/11/2026 · rama `claude/v12-fase2-oakhaven` (LOCAL, desde `claude/rebelum-v12` @ `36a84c2`), copia `D:\Aethelgard_v12_oakhaven`

Encargo: Oakhaven 3D completa (no un tramo) sin perder ningún sistema de la 2D («No acepto una región visualmente bonita
si al convertirla desaparecen sus sistemas originales»); por defecto solo si todo está y las pruebas pasan; la 2D siempre
elegible. Sin push ni merge. Todo con datos aislados (`ejecutar_pruebas.ps1`, o `APPDATA`/`LOCALAPPDATA` a una carpeta
temporal para `--import` y los guiones sueltos); `partida.save` real sin cambios en todas las pasadas; `project.godot`
sin cambios (la primera importación de la copia vació los directorios de Dialogic: `git restore` y reimportar).
No se tocaron `combate*.gd`, `artes.gd`, `grupo.gd`, `investigacion.gd`, `personajes/`, `enemigos/`, `sonido.gd`,
`musica.gd` ni otras zonas.

Leyenda: **[C]** observado en el código · **[E]** comprobado ejecutando (aislado, PC) · **[?]** pendiente.

### 1. Inventario 2D frente a 3D

| Sistema | 2D (`ciudad_oakhaven.gd` + `ciudades/oakhaven.gd`) | 3D antes (`36a84c2`) | 3D ahora |
|---|---|---|---|
| Acceso desde el mapa | lugar 0 → `ciudad_oakhaven.tscn` | solo con `oakhaven3d` (en pruebas) | **por defecto** con la exploración 3D; 2D elegible (Ajustes u `oakhaven2d`) [E] |
| Trazado (27 lugares) | todo | el suelo y los modelos de gráficos; sin muralla, torre, ronda, colina en alto, crematorio, patio cerrado | **todo**: muralla, torre, ronda en alto, altozano con rampa, crematorio, urnas, muro y grieta, Patio de las Velas [E] |
| Vecinos (11) | los 11, con rutina por franja | 5 (Aldric y la posadera de primitivas; Ferro, Hilda y Mirta del distrito) | **11**: Selene, Pip, Rosa, Albar, Bastián y Doña Encina nuevos (y Aldric rehecho) con su rutina; figuras PROVISIONALES [E] |
| Diálogos | `Oak.dialogo_de` (misión primero, turnos) | Aldric, la posadera solo con servicios, los tres oficios | **todos** con `Oak.dialogo_de`; la posadera, «Hablar» en su panel [E] |
| Misiones | favores, faroles, secreto de Pip, lavanda; encargos de Ferro y Mirta | solo los encargos | **las cuatro** y los encargos (señales `oak:` con `Oak.aplicar_senal`) [E] |
| Cofres (4, ids escritos) | velas, raíces, ronda, requisados | ninguno | **los 4, mismos ids**; los requisados esperan a `pv_02`; destellos [E] |
| Secretos y vistas (6) | 4 cofres-secreto, vista de la torre y de las raíces | ninguno | **los 6** (vistas con su texto y su estado) [E] |
| Piezas | barril, torre, bajar, 3 faroles, grieta, 3 páginas, tablón, mesa | ninguna (el pozo, del distrito) | **todas** (la ronda y la grieta con fundido, como en la 2D) [E] |
| Notas (5 + requisados) | Diario («lore_visto») | ninguna | **las 5** con `examinables_3d.gd`; la de los requisados sale del cofre [E] |
| Detalles de canon | `oak_sello`, `oak_tapiz` (páginas del Acto) | no | **sí** (texto, página del Diario, hallazgo si lo hay) [E] |
| Hallazgos | Rama Milenaria (Árbol), Gemelas (barril) | no | **sí** («Examinar el Árbol» y el barril sin favor) [E] |
| Gremio | tablón de la plaza, braseros | no | **sí** (`gremio_menu.gd`; los dos braseros del proyecto) [E] |
| Tienda | botón TIENDA | no | **«Comprar en el mercado»** (`tienda.gd`, lugar 0) [E] |
| Parejas | mesa del Patio del Cuervo | no | **sí** (`taberna_parejas.gd`) [E] |
| Posada | dormir, sopa, rumores, noche gratis, charla al despertar | sí (dentro) | igual, y «Hablar» (favores) [E] |
| La hora | `oak_franja` (mañana, tarde, anochecer; 240 s) | fija («anochecer») | **la misma clave y ritmo** que la 2D; dormir trae la mañana [E] |
| Voces al pasar | vecinos y 4 voces | las 4 voces | **vecinos y voces** [C] |
| Brazalete | cerca de la grieta y de los detalles sin ver | no | **sí** [C] |
| Sonido de la ciudad | murmullo, fuente, mercado, la hora, campana | pasos y oyente | **murmullo, fuente y mercado en 3D** (`fuente_3d`), la hora (`fijar_momento`) y la campana [C] |
| Música | `ciudad` | `ciudad` | igual (`musica.gd:124`) |
| Guardado | automático | al entrar, al pausar, tras dormir | además tras cofre, nota, detalle, pieza con señal, misión, gremio, parejas, tienda [E] |
| **Lo que no está** | — | — | los comentarios de los héroes al explorar (llegar, cofre, quieto: no existen en ninguna región 3D); el velo oscuro del Patio de las Velas (en la 3D lo cierra el muro); la fauna (en la 2D tampoco se pone: solo datos) |

Diferencias de sitio (la 3D manda donde la 2D no cabía, sin cambiar ids): Ferro, Hilda y Mirta atienden en el distrito
de los oficios (V10) y no en sus casillas 2D; Selene, a un lado del tenderete de Mirta (37,6, 41,6); Albar, por la
mañana, entre las urnas; Bastián, a un lado de la Calle Mayor (en medio cerraba el paso); el tapiz, en el del Concejo
(45,4, 21,9). Todo en `vida3d.gd` (RUTINA_3D, SITIO_3D).

### 2. Geografía nueva (`zonas3d/oakhaven/barrios.gd`, `fuente/crear_barrios.py` → `modelos/barrios.glb` y `barrios_ligero.glb`)

Con las funciones del distrito de los oficios (el guion carga `crear_distrito.py` sin su llamada final): muralla de
sillares con almenas (los dos tramos del sur se vuelven transparentes si tapan a Kael), la Torre de la Campana con su
campana de bronce y tejado de pizarra, la ronda (bloque de 4 m, adarve de losas, pretil, almenas, tres faroles con su
fuego y la trampilla), el altozano de la colina (1,2 m, hierba fría con escarcha, muro de contención, rampa empedrada con
pretil, cipreses), el crematorio de piedra hueso (chimenea con humo blanco, puerta sellada con lacre y anillo, faroles de
luz fría), el jardín de urnas, el muro del callejón con la grieta (luz de velas dentro) y el Patio de las Velas cerrado
(suelo de losas con musgo, altar con el anillo partido y cinco velas con llama y, en alto, su luz), la raíz cortada con su
anillo negro, el tablón del gremio, la mesa de las parejas, el cofre y el brasero. 22 078 triángulos (alto) y 14 113
(ligero); 7 figuras de vecinos de 274-464 triángulos.
Paso: `_prohibido` mira el adarve en alto y el bloque de la ronda abajo; la rampa es una caja inclinada; las cajas del
GLB van a los bloqueos de la ciudad; se añaden los torreones de la Puerta del Sur, la franja al sur de la muralla y los
barriles, el tablón del bando y el puesto de flores (no tenían choque). La cámara de la ronda va más cerca y más alta
(a 52° quedaba dentro de la torre).

### 3. Partidas

- **2D → 3D** (`escena_equivalente` → `posicion_desde_2d`): la misma casilla; la ronda, en el adarve a 4 m; la colina,
  sobre el altozano [E `prueba_oakhaven3d_completo` 0b].
- **3D → 2D elegida** (nuevo, `posicion_a_2d` en `modo3d.escena_equivalente`): la misma casilla (si no se puede estar en
  la 2D, la 2D lo pone en la Puerta del Sur) [E 0a]. La Garganta sigue entrando por la entrada de su 2D.
- **Oakhaven generada** (`zona.tscn`, lugar 0): abre la versión en uso por su entrada (`progreso.gd`, 2 líneas) [E].
- Mismas claves: la partida que se juega en la 3D, abierta en la 2D, trae los 4 cofres abiertos, las misiones y los
  faroles [E parte 11].
- Ajustes: la clave `[regiones] oakhaven3d` es la de cuando estaba en pruebas (quien eligió la 2D la conserva).

### 4. Pruebas (aisladas, PC, 12/11)

- `prueba_oakhaven3d_completo` (nueva, partes 0-11): **superada**. Las de Oakhaven, distrito, gremio, taberna, posada,
  tienda, rutinas, vida, charlas, comentarios, `prueba_zona3d`, `prueba_integridad`, guardado (`prueba_guardado`,
  `_protegido`, `_fallos`), `prueba_partida`, `prueba_restaurar_escenas`, música, efectos, hallazgos, notas y la Garganta:
  29 de 29 (`D:\REBELUM_diagnostico\pruebas\2026-11-12_021249` y la repetición de las 5 corregidas).
- Ajustadas: `prueba_oakhaven3d` (paso 0: la 3D por defecto y `oakhaven2d`), `prueba_restaurar_escenas` (parte 1: la
  versión en uso), `prueba_garganta3d_examinables` (Oakhaven ya no está en pruebas), `prueba_oakhaven` con `oakhaven2d`.
- **Batería completa:** 122 · 0 · 52 · 0 (§7).
- **Por defecto: sí.** Todos los sistemas de la 2D están en la 3D (§1) y las pruebas pasan; la 2D sigue elegible.

### 5. Rendimiento en el PC (1280×720, RTX 3050 portátil; mismas vistas antes y después)

| Vista | Bajo: llamadas · primitivas | Medio | Alto |
|---|---|---|---|
| Ciudad desde el sur (antes → después) | 236 → 277 · 312 k → 317 k | 237 → 282 · 357 k → 362 k | 353 → 419 · 781 k → 799 k |
| Aldric en la Puerta del Sur | 78 → 91 · 177 k → 174 k | 93 → 108 · 276 k → 265 k | 199 → 236 · 769 k → 771 k |
| Plaza (gremio) | 71 → 80 · 185 k → 193 k | 85 → 91 · 283 k → 300 k | 158 → 162 · 835 k → 865 k |
| Ronda (nuevo) | 61 · 134 k | 74 · 213 k | 150 · 595 k |
| Colina y crematorio (nuevo) | 50 · 135 k | 61 · 217 k | 94 · 637 k |

- Lo que cuesta: cada vecino (1-2 llamadas), cada cofre (2), los destellos de lo que falta por coger o leer (ya con un
  solo material) y los muros nuevos (una malla por objeto y material, con su choque). Primitivas casi igual: la muralla
  y los barrios son 22 k triángulos (14 k en medio y bajo) y lo que queda debajo del altozano se quita.
- Montar los barrios: 21-25 ms en el PC (cargar el GLB y juntar; sin caché, como el distrito).
- **El PC no dice nada del Redmi**: en el alto ya iba a 15 FPS; la entrada sube ~+13-15 llamadas en bajo y medio (+41-45 en la vista de toda la ciudad).

### 6. Pendiente

- **Redmi** (sin probar): medir bajo y medio en la Puerta del Sur, la plaza, la ronda y la colina; si las llamadas
  pesan, juntar los cofres y las figuras de los vecinos en lotes (las figuras no se animan) y quitar destellos en bajo.
- **Figuras de los vecinos PROVISIONALES** (mallas sin esqueleto): hacen falta modelos con rig (fase B o animaciones).
- Los comentarios de los héroes al explorar no existen en las regiones 3D (tampoco en la Garganta ni en Pastos).
- El velo del Patio de las Velas (2D) no se ha llevado a la 3D: el patio se ve desde arriba, pero no se entra sin la
  grieta.
- Ferro, Hilda y Mirta no cambian de sitio con la hora en la 3D (sí en la 2D: Hilda pasea al anochecer).

### 7. Batería completa y capturas

- **Batería completa** sobre `0cdbd9a` (`D:\REBELUM_diagnostico\pruebas\2026-11-12_021937`): **122 · 0 · 52 · 0**;
  `partida.save` real y carpeta real de datos sin cambios (el «proyecto cambiado» es este informe, creado durante la
  pasada).
- **Capturas** en `D:\REBELUM_diagnostico\migracion\2026-11-12_oakhaven\`: `antes_tramo\` (el tramo de `36a84c2`, con
  sus medidas) y `despues\` (`fotos_oakhaven3d_completo`: vecinos, gremio, grieta y Patio de las Velas, raíces, mesa de
  las parejas, subida, crematorio, urnas, torre, ronda, mercado y requisados y cuatro vistas fijas, en bajo, medio y
  alto; y los sitios del tramo, para comparar).

### 8. Archivos para integrar (copiando, sin fusionar)

- Nuevos: `aethelgard/zonas3d/oakhaven/barrios.gd` (+ `.uid`), `vida3d.gd` (+ `.uid`), `fuente/crear_barrios.py`,
  `modelos/barrios.glb`, `modelos/barrios_ligero.glb` (+ sus `.import`), `aethelgard/pruebas/prueba_oakhaven3d_completo.gd`
  y `fotos_oakhaven3d_completo.gd` (+ `.uid`), este informe.
- Cambiados: `aethelgard/zonas3d/oakhaven_3d.gd`, `aethelgard/modo3d.gd`, `aethelgard/progreso.gd` (restaurar, 3 líneas),
  `aethelgard/menus.gd` (solo el bloque «Oakhaven», marcado), `aethelgard/zonas3d/examinables_3d.gd` (temporizadores),
  `aethelgard/pruebas/prueba_oakhaven3d.gd`, `prueba_restaurar_escenas.gd`, `prueba_garganta3d_examinables.gd`,
  `lista_pruebas.txt` (dos líneas nuevas y `oakhaven2d` en `prueba_oakhaven`).
- `modo3d.gd` y `menus.gd` los tocó también la Garganta: copiar este `modo3d.gd` entero (lleva lo de la Garganta) y
  solo el bloque marcado de `menus.gd` si hay conflicto. `project.godot` sin cambios.
