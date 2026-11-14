# Capa de Garon (V12, fase 6 del encargo del 13/11)

14/11/2026, rama local `claude/v12-capa-garon` (desde `claude/rebelum-v12` @ 710fdae). Encargo: sección 7 de
`docs/v12/encargos/ENCARGO_COORDINADOR_13_11.md` y «CAPA DE GARON» de las instrucciones complementarias del 14/11.

**Estado:** hay una capa **articulada** nueva (`aethelgard/capa_garon.gd`), probada en PC en las tres variantes de Garon,
detrás de una opción **APAGADA**. Por defecto el juego sigue con la capa de siempre («rígida»), sin ningún cambio, y esa
rígida queda como respaldo seleccionable. **Pendiente: verla en el Redmi** (aspecto y coste) antes de encenderla por
defecto.

## 1. Recursos y variantes

| Variante | Script | Modelo | Esqueleto | Cuerpo |
|---|---|---|---|---|
| original | `garon_3d.gd` | `garon.fbx` (Meshy, Mixamo) | 44 huesos, reposo con Y arriba | `output_unwrapped`, 19 299 vértices |
| v2 | `personajes/heroes_v2/garon_v2_3d.gd` | `personajes/heroes_v2/garon/garon_v2.glb` | el mismo + `arma_d`, `arma_i` (46), reposo girado (−Z arriba) | 19 323 vértices |
| v3 | `personajes/heroes_v3/garon_v3_3d.gd` | `personajes/heroes_v3/garon/garon_v3.glb` | el mismo que el v2 | `cuerpo_v3`, 4 607 vértices (geometría propia) + `cara_v3` |

El interruptor es `personajes/heroes_v2/heroes_v2.gd` → `version()` («originales», «v2» o «v3»; por defecto originales).
Las tres crean la capa en `garon_3d.gd` (`_crear_capa`, por herencia). La capa no es un modelo: es la imagen
`garon_capa.png` (744 × 1024, con transparencia en el borde roto y el yugo oscuro con el águila arriba) puesta sobre una
tela de 14 × 18 cuadros hecha por código. No hay `.blend` ni GLB de capa.

## 2. Diagnóstico de la capa de siempre (la rígida, con el arreglo de cefed0a)

Medido con `pruebas/prueba_capa_garon.gd` (mismo guion para todas: reposo, andar y correr desplazándose, media vuelta
corriendo, pararse, Juicio, Giro, avanzar en guardia, la Guardia, victoria y derrota; piel del cuerpo calculada en la CPU
en el mismo instante en que se coloca la capa) y visto en las capturas de `pruebas/fotos_capa_garon.gd`.

| Problema | Medida (rígida) | Causa |
|---|---|---|
| **Separada del cuerpo** | hueco entre el centro de arriba de la capa y el cuerpo: **0,18 m** en las tres; centro de arriba a 0,30-0,45 m de las clavículas | el origen va `ATRAS_CAPA` (0,14 × escala) detrás del cuello y la curva lleva el centro 0,18 unidades más atrás (≈ 0,31 m detrás del cuello). Se ve en `v3_defensa_lado.png` (antes): la tela flota detrás |
| **Bloque rígido** | separación de cada fila respecto a la pose pegada al pecho: **0,000** arriba, en medio y abajo en todas las fases | una sola malla sin huesos (`MeshInstance3D` bajo un `Node3D`) que `_colocar_capa` coloca ENTERA cada fotograma; solo la onda del shader la mueve. En el Juicio sale por detrás como una tabla (`originales_juicio_impacto_lado.png`) |
| **Anclaje inestable** | distancia capa-clavículas: varía **0,15 m** (original) y **0,34 m** (v2/v3) | la caída por gravedad (`CAPA_GRAVEDAD`) y el giro anti-suelo giran la capa entera sobre su origen |
| **Atraviesa el cuerpo tumbado** | derrota de v2/v3 (boca arriba): hasta **25 %** de los vértices dentro del cuerpo | al tumbarse, la capa entera gira para no bajar del suelo y corta el cuerpo |
| **Bajo el suelo** | v2/v3: la parte libre de la tela llega a 7,7 cm bajo el suelo | el giro anti-suelo solo mira tres puntos de la curva y las esquinas; con el cuerpo roto por `AvanzarDoble` (§7) no basta |
| Sin reacción a la marcha | nula | sin inercia: al correr, girar o pararse no se queda atrás ni se balancea |
| Escala y orientación | correctas | ya las arregló cefed0a (talla con el esqueleto, orientación con pecho y hombros); se conservan |
| Pesos y huesos | no tiene | — |

Hallado además (no es de la capa; no se ha tocado): ver §7.

## 3. Solución: la capa articulada (`aethelgard/capa_garon.gd`)

Se repara conservando el diseño: **la misma imagen, la misma talla** (largo y ancho de `_medidas_capa`), **la misma curva
que envuelve, la misma apertura del 30 % hacia abajo y la misma caída hacia atrás**. Cambia cómo se sujeta y se mueve:

- **Pieza independiente con huesos propios.** Un `Skeleton3D` propio («EsqueletoCapa», hijo de la capa): una raíz y 5
  cadenas de 4 huesos (21 huesos). La tela (285 vértices) lleva su `Skin` con 4 pesos por vértice (las dos cadenas y los
  dos tramos que lo rodean): se deforma en la GPU. No toca el esqueleto de Garon, solo lo lee. La malla va como hermana
  del esqueleto, no como hija: los ayudantes v2/v3 cambian el material de toda malla hija de un `Skeleton3D`
  (`heroe_v3_ayudante.gd`, `_materiales`) y la capa se quedaba gris (visto en la primera prueba).
- **Bien sujeta a los hombros.** La fila de arriba va pegada al pecho (`Spine2`), girada un 60 % hacia la línea de los
  hombros (como la rígida: en la guardia del original el pecho va 47° girado respecto a los hombros) y sus esquinas
  siguen a medias a las clavículas. Distancia capa-clavículas en todo el guion: **0,173 / 0,180 / 0,156 m (original /
  v2 / v3), varía < 1 mm**.
- **Ajustada a la espalda de cada variante.** Al crearla mide la malla del cuerpo en reposo (piel en la CPU, 1 de cada
  n vértices, unas 4 000; se guarda por malla para el siguiente Garon) y pone la tela a 2 cm de la espalda, sin pasar
  nunca por delante del perfil del cuerpo (sin el yelmo; los brazos solo en las hombreras). Hueco centro-espalda de pie:
  **0,066 / 0,067 / 0,060 m** (antes 0,18; la medida usa 1 de cada 3-4 vértices del cuerpo).
- **Movimiento progresivo.** Cada junta vuelve a su sitio con menos fuerza cuanto más abajo (`RIGIDEZ` 1 · 0,6 · 0,22 ·
  0,1 · 0,06); el resto es inercia (andar, correr, girar, pararse, saltar) y gravedad relativa al pecho (erguido no tira:
  la forma ya cuelga; inclinado o tumbado, hacia el suelo, en vez de salir como una tabla). Separación media respecto a la
  pose pegada al pecho (arriba / abajo, las tres variantes): correr 0,010-0,013 / 0,27-0,34 m, media vuelta
  0,009-0,012 / 0,32-0,47, Giro 0,006-0,008 / 0,27, Juicio 0,005-0,007 / 0,29-0,33, pararse 0,006-0,011 / 0,11-0,15
  (vuelve). La rígida da 0,000 en todo.
- **Sin atravesar.** Juntas y tramos chocan con cápsulas del cuerpo entre huesos (tronco, cabeza, muslos, piernas,
  brazos y antebrazos; el radio sale de la malla, sin pasar del hueco que deja la tela en reposo) y con las **dos
  espadas** (también los tramos de lado a lado, porque una hoja puede pasar entre dos cadenas). Nunca baja del suelo (las
  juntas guardan además lo que la tela se aparta de la línea de sus huesos).
- **Estable.** Si el pecho salta más de 0,6 m en un fotograma (teletransporte, recolocación del combate, cambio de padre)
  se recoloca sin estirarse; no se simula si Garon está oculto. La onda del shader sigue (`_viento` igual), más suave
  (0,03 en vez de 0,06), y ahora usa `UV.y` para saber cuánto ondear.
- **Barata.** Sin física del motor ni `SpringBoneSimulator3D` (existe en 4.7.2, comprobado con `ClassDB`, pero no deja
  la sujeción a medias con las clavículas ni la gravedad relativa al pecho). Por fotograma: 20 juntas, 2 pasadas de
  restricciones y choques con 13 cápsulas, 20 poses de hueso. En PC, `colocar()` tarda **0,48-0,52 ms** de media
  (medido durante las pruebas, con otros Godot de otra copia en marcha: no es una medida de rendimiento). En el Redmi,
  pendiente. Si hiciera falta, `ITERACIONES := 1`.

Se enciende (cualquiera, antes de crear a Garon):

- `Engine.set_meta("capa_garon", "articulada")` («rigida» la apaga);
- el argumento de usuario `capa_articulada` (`godot ... -- capa_articulada`; `capa_rigida` la apaga);
- `user://ajustes.cfg`, `[garon] capa = "articulada"`;
- `CAPA_ARTICULADA_POR_DEFECTO = true` en `garon_3d.gd` (cuando se apruebe tras verla en el Redmi).

## 4. Variantes

| Variante | Rígida (por defecto) | Articulada (opción) |
|---|---|---|
| original | igual que antes | **reparada y comprobada en PC** (prueba automática y capturas de estudio, combate y regiones) |
| v2 | igual que antes | **reparada y comprobada en PC**; tumbada en la derrota, ver §7 (el clip hunde el cuerpo) |
| v3 | igual que antes | **reparada y comprobada en PC**; tumbada en la derrota, ver §7 |

Las tres en el dispositivo: **pendiente** («verificar en el Redmi»).

## 5. Pruebas (ejecutadas, datos aislados)

`aethelgard/pruebas/prueba_capa_garon.gd` (nueva, en `lista_pruebas.txt`, modo auto, 900 s). Mide las dos capas en las
tres variantes y **exige a la articulada**: anclaje (varía ≤ 3 cm), pegada a la espalda (hueco ≤ 7 cm), dentro del cuerpo
≤ 5 % de los vértices en cada muestra y ≤ 2 % de media, tela libre dentro de una espada ≤ 3 %, tumbado (derrota) ≤ 10 %,
nunca bajo el suelo, movimiento progresivo en correr, media vuelta, pararse y Giro, el borde se mueve al correr, nada
a más de 15 m/s respecto al pecho; y a las dos: una sola capa al crearlo, al cambiar de versión, de escena
(`change_scene_to_node`) y de padre, ningún nodo de más al quitarlas, recolocación tras un salto de 9 m, y que **sin
elegir nada la capa es la rígida**. Los umbrales de «dentro» llevan el margen de la propia medida (piel en la CPU con 1
de cada 3-4 vértices del cuerpo y la normal del más cercano): la rígida, que flota a 18 cm de la espalda, da con este
mismo guion 2,8-3,2 % en el cuerpo y 2,1 % en las espadas.

Resultados de la última pasada (PC, Godot 4.7.2 de consola, `--fixed-fps 30`, 14/11 02:19; rutas en §8):

| | original | v2 | v3 |
|---|---|---|---|
| Anclaje rígida → articulada (varía) | 0,153 → 0,000 m | 0,344 → 0,000 m | 0,344 → 0,000 m |
| Hueco espalda rígida → articulada | 0,180 → 0,066 m | 0,180 → 0,067 m | 0,180 → 0,060 m |
| Dentro del cuerpo, articulada (media / peor) | 0,6 % / 3,2 % | 0,9 % / 2,8 % | 1,5 % / 3,9 % |
| Tumbado (cuerpo o espadas), rígida → articulada | 7,7 → 3,9 % | 7,7 → 8,8 % | 8,1 → 1,8 % |
| Derrota con el cuerpo hundido por el clip, rígida → articulada | — | 25,3 → 12,3 % | 13,0 → 6,0 % |
| Tela libre dentro de una espada, articulada | 1,1 % | 2,5 % | 1,1 % |
| Sujeción dentro de una espada, articulada | 2,1 % | 2,5 % | 1,8 % |
| Suelo (tela) | +0,023 m | +0,038 m | +0,021 m |

Otras pruebas de Garon y héroes, por defecto y con `capa_articulada`: `prueba_garon`, `prueba_heroes_v2`,
`prueba_heroes_v3`, `prueba_escarcha_guardia` (la Guardia), `prueba_acciones_v12` (esgrima), `prueba_grupo3d`,
`prueba_anim_pies`, `prueba_grupos_combate`, más `prueba_esperas` y `prueba_esperas_v2` por defecto: todas SUPERADAS (§8).

## 6. Capturas (mismo guion antes y después)

`pruebas/fotos_capa_garon.gd` ampliada: media vuelta corriendo, pararse y la Guardia; andar y correr se desplazan de
verdad con las cámaras siguiendo a Garon (si no, la tela no tiene marcha a la que reaccionar); `capa=rigida|articulada`;
y la medida con la tela deformada (`puntos_mundo()`). Las de combate (`fotos_capa_garon_combate.gd`) y regiones
(`fotos_capa_garon_regiones.gd`) no cambian: la articulada se pide con el argumento `capa_articulada`.

Las más claras para comparar (antes → después, mismos nombres):

- `v3_defensa_lado.png`: antes, la tela flota a un palmo de la espalda; después, sujeta y cayendo.
- `originales_juicio_impacto_lado.png`: antes, una tabla horizontal; después, tela que se queda atrás al caer el salto.
- `originales_correr_b_lado.png`, `*_media_vuelta_*`: después, la tela ondea hacia atrás y se abre al girar.
- `originales_reposo_espalda.png`: después, centrada y envolviendo los hombros.
- `hoja_combate_v2.png` (combate real): antes, la tela sale de lado en la guardia; después, cae sobre la espalda.

## 7. Problemas hallados que no son de la capa (sin tocar)

1. **v2 y v3: `AvanzarDoble` (y seguramente `RetrocederDoble`) rompen el cuerpo.** Son del paquete de doble espada
   (`garon_espadas.res`), redirigidos al esqueleto de los ORIGINALES; los v2/v3 tienen el reposo girado (−Z arriba) y la
   pista de posición de la cadera se aplica en otros ejes: la cadera queda a y = −0,04 m y 0,55-0,71 m de lado (en el
   original, a 0,71-0,74 m de alto). Comprobado ejecutando (`avanzar()` en el v2). El combate los usa para acercarse
   (`avanzar`/`retroceder`). Propuesta (archivo `garon_v2_3d.gd`, no es mío): en `_mapear_animaciones` del v2, no añadir
   esos dos clips o quitarles la pista de posición de `Hips`, o usar «andar» del v2 para acercarse.
2. **v2 y v3: la derrota hunde el cuerpo** 0,29 m (v2) y hasta 0,56 m (v3) bajo el suelo (clip «derrota»). La sujeción
   de la capa va con la espalda y por eso baja con él; la tela libre no baja del suelo.
3. En la prueba, durante la Guardia (`cubrir`, que llega justo después de `avanzar`) el cuerpo del original baja hasta
   0,22 m bajo el plano de los pies en algunas muestras. Observado solo en la medida (no en una captura); sin
   investigar.
4. Los clips del original llevan a veces una espada por detrás de la espalda (al andar y en el Giro): las pocas
   coincidencias de la sujeción con una espada (≤ 2,5 %) vienen de ahí; la sujeción no se aparta (no debe).

## 8. Rutas (resultados y capturas)

- Medidas de antes (primera pasada, guion de cefed0a): `D:\REBELUM_diagnostico\v12\capa_garon\antes\2026-11-14_013316\`
- Pruebas por defecto (11 SUPERADAS, `prueba_capa_garon` incluida, 77 comprobaciones y FALLOS: 0):
  `D:\REBELUM_diagnostico\v12\capa_garon\pruebas\2026-11-14_021935\resumen.md` (marca «proyecto: cambiado» porque este
  documento se escribió durante la pasada; ninguna prueba lo toca)
- Pruebas con la articulada encendida (8 SUPERADAS):
  `D:\REBELUM_diagnostico\v12\capa_garon\pruebas_articulada\2026-11-14_022100\resumen.md`
- Capturas antes (rígida, guion nuevo): `D:\REBELUM_diagnostico\v12\capa_garon\capturas_antes\2026-11-14_020938\`
- Capturas después (articulada): `D:\REBELUM_diagnostico\v12\capa_garon\capturas_despues\2026-11-14_022212\`
  (`fotos_capa_garon\hoja_<variante>.png`: columnas = instantes, filas = frente, lado y espalda; `medidas.txt`;
  `fotos_capa_garon_combate\hoja_combate_<variante>.png`; `fotos_capa_garon_regiones\`)
- Listas propias (para repetirlas con `-Lista`): `D:\REBELUM_diagnostico\v12\capa_garon\lista_fotos_antes.txt`,
  `lista_fotos_despues.txt` y `lista_con_articulada.txt`.

## 9. Pendiente

- **Verificar en el Redmi**: aspecto (la onda, la piel con 4 pesos en Mali-G57) y coste de `colocar()` en la CPU del
  teléfono (en PC, ~0,5 ms; GDScript en ARM puede ser varias veces más). Medirlo sin otra carga, lo programa el
  coordinador. Si aprueba: `CAPA_ARTICULADA_POR_DEFECTO = true`.
- Opción en Ajustes/Auditoría para elegir la capa en el móvil (lee `[garon] capa`): es `menus.gd`, no es mío.
- Vídeo en movimiento (`--write-movie`): no hecho; las capturas son fotogramas sueltos.
- Los problemas de §7 (clips de los v2/v3 y la Guardia), para quien lleve a Garon.
- Revisión visual de una persona de todas las capturas (211 por pasada de estudio).

## 10. Revisión por estados (14/11, tarde)

Encargo: original, v2 y v3 en reposo y marcha; arranque, parada y giros; ataques con las dos espadas; defensa, derrota
y cambios de escena. Prueba nueva `pruebas/prueba_capa_garon_estados.gd` (526 comprobaciones; capturas con
`pruebas/fotos_capa_garon_estados.gd`). Informe completo: `D:\REBELUM_diagnostico\v12\capa_revision_14_11\REVISION.md`.

- **Arreglado (capa_garon.gd, `SALTO_GIRO`)**: tras un giro instantáneo (`mirar(…, 0.0)`: grupo_3d.gd al reaparecer,
  gran_bosque_3d.gd, piezas de la Garganta) o al volver de oculto girado, la tela se quedaba donde estaba: el primer
  fotograma quedaba DELANTE del cuerpo (borde 0,19-0,39 m por delante del pecho, huesos de cadera y piernas y las dos
  hojas cruzando la tela, 25-29 m/s) y lo atravesaba hasta volver. Ahora, si el sitio de la capa gira más de 80° en un
  fotograma, se recoloca (como ya hacía con un salto de más de 0,6 m). Lo más rápido de los giros normales: 50° por
  fotograma a 30 fps (media vuelta en 0,12 s), 35° en el Juicio.
- **Residuo conocido, sin arreglar**: en el Juicio y el Giro una hoja roza el borde de la tela libre en 1-2 muestras
  (3-6 triángulos de 504; la rígida de siempre, 2-5). Probado sin éxito: cápsulas en los filos de la hoja y la hoja
  barrida entre fotogramas. La prueba lo tolera (≤ 6) para que no empeore.
- **No es de la capa**: en la derrota de los v2/v3 el clip hunde el cuerpo bajo el suelo (§7.2) y la cadera y los
  muslos cruzan la tela, que no baja del suelo; también la hoja izquierda tumbada. Solo se informa.
### 11. Movimiento real (14/11, mediodía)

`fotos_capa_garon_movimiento` (`_v2`, `_v3`) recorre Pastos Verdes 3D de verdad: Kael anda con el stick y Garon le sigue en la fila de `grupo_3d.gd`. La cámara sigue el pecho a 3 m y un rayo comprueba que nada tapa a Garon. Revisado a ojo en las tres variantes:
- la capa va sujeta en los hombros;
- se queda atrás al arrancar, ondea al correr y se abre en los giros;
- se asienta al parar;
- no hay ninguna recolocación durante el trayecto.

**PENDIENTE (reproducible en las tres variantes):** cuando Garon da media vuelta desde parado y arranca a correr, gira 46° por fotograma, por debajo de los 80° de SALTO_GIRO. Durante un fotograma, 1/15 s, la tela pasa por delante del muslo. `prueba_capa_garon_estados` no cubre ese caso, porque allí gira corriendo.
1. Primero, añadir el caso «parado → media vuelta en 0,12 s → correr» con su contraprueba.
2. Después, probar cápsulas de piernas más gruesas o colisión entre fotogramas.

Capturas: `D:\REBELUM_diagnostico\v12\capa_revision_14_11\movimiento\2026-11-14_121849\`.

### 12. Media vuelta desde parado (14/11, tarde): ARREGLADO

- **Prueba nueva** en `prueba_capa_garon_estados.gd`: fase `media_vuelta_parado` (tras la parada corriendo: `mirar(-adelante, 0.12)`
  y a correr a 4,2 m/s a la vez, como el que sigue en la fila); sus primeros 15 fotogramas se miden todos (no 1 de cada 3).
  **Contraprueba** con el `capa_garon.gd` de antes: 6 FALLOS, todos de esta fase: `muslo_d` cruza la tela en las tres
  variantes (y `rodilla_d` en el v2) y la hoja derecha corta 3-4 triángulos de la tela libre.
- **Arreglo 1, subpasos** (`SUBPASO_GIRO` 20°, `MAX_SUBPASOS` 4): si el sitio de la capa gira más de 20° en un fotograma (sin
  llegar a `SALTO_GIRO`), el cuerpo de ese fotograma (sitios de las juntas, cápsulas y suelo) se lleva girado de vuelta hacia el
  del anterior (`interpolate_with`) y la tela avanza en n trozos (`_paso`). Quita el cruce del muslo.
- **Arreglo 2, centro de los cuadros con las piernas**: tras la media vuelta, al correr, la pierna del v2 entraba por el MEDIO
  de un cuadro de la tela (juntas a 0,20 m del hueso, cuadros de ~0,23 × 0,26 m) sin acercarse a sus bordes. `_chocar` mira
  también el centro de los 12 cuadros de la tela libre frente a las 4 cápsulas de las piernas y empuja sus cuatro juntas.
  Solo de pie: tumbado empeoraba la derrota del v2 (prueba_capa_garon, 6,7 → 10,5 %); con todas las cápsulas o con las hojas,
  nada mejor; con la mitad de empuje o un radio menor, el cruce seguía.
- Ajuste de la prueba: la parada del caso «espadon» dura 75 fotogramas como la del guion principal (con 60, la medida de
  «se asienta» caía en el vaivén lento del borde, ±2 cm, y pasaba o no según la fase: 0,018 antes, 0,023 con el arreglo).
- Resultados (PC, datos aislados): `prueba_capa_garon_estados`, `prueba_capa_garon`, `prueba_heroes_v2`, `prueba_heroes_v3`,
  `prueba_garon`: 5 SUPERADAS (`D:\REBELUM_diagnostico\pruebas\2026-11-14_135333\`). Reposo idéntico al de antes (arriba
  0,011/0,005/0,008 m, mismo borde); tumbado 3,2 / 7,0 / 1,1 % (antes 3,9 / 6,7 / 3,2).
- Coste (sin tiempos): un subpaso de más = otro paso completo (20 juntas, 2 × restricciones, 2 × 424 pruebas tramo-cápsula,
  más 52 transformaciones de puntos y un `interpolate_with`). En el guion: media vuelta desde parado 6-7 pasos de más en 4
  fotogramas; giro de 180° corriendo 7 en 4; de 90° 3 en 3; Juicio 8 en 8; Giro 2 en 2; marcha recta y reposo, 0. Los centros:
  48 `get_closest_point_to_segment` por pasada, 96 por paso, en todos los fotogramas de pie (frente a las 848 de siempre).
- Capturas `fotos_capa_garon_movimiento` (_v2, _v3): `D:\REBELUM_diagnostico\pruebas\2026-11-14_135506\`. En `giro_180_028`
  ya no cruza el muslo en ninguna variante; capturas con cruce: antes 1 / 1 / 1, ahora 0 / 1 / 0. **PENDIENTE**: el v2 tiene
  `rodilla_d` en `giro_180_040` (otra arrancada girando desde parado, 37°/fotograma de media); en la imagen la pierna se ve
  por delante de la tela. Verlo en el Redmi y, si se nota, mirar el barrido de la pierna entre fotogramas al arrancar.

**Corrección del coordinador al §12, tras la revisión escéptica (14/11, 14:45). Esto es lo que se integra:**
- **Subpasos RÍGIDOS.** `interpolate_with` mezclaba un sitio sin escala con `a_mundo`, que lleva la escala del esqueleto (0,927, con reflexión). Los subpasos deformaban el cuerpo un 3-6 %. Ahora se gira alrededor del sitio de ahora con el giro propio entre las dos orientaciones (`vuelta`, un Quaternion sin reflexión) y se desplaza en línea recta.
- **Centros de los cuadros**, solo durante `TRAS_GIRO` (12 fotogramas) tras un giro que haya necesitado subpasos. Antes actuaban en todos los fotogramas de pie y cambiaban la tela también en reposo y en la parada.
- **Prueba:** la parada del espadón vuelve a sus **60** fotogramas, sin alargarla para que pase. Pasa igual.
- **Resultados en el proyecto real, sin otros Godot:**
  - `prueba_capa_garon_estados`, `prueba_capa_garon`, `prueba_heroes_v2`, `prueba_heroes_v3` y `prueba_garon`: 5 superadas (`2026-11-14_144310`).
  - **Contraprueba** con el `capa_garon.gd` anterior y la prueba nueva: 6 fallos, todos de `media_vuelta_parado` (`2026-11-14_1444xx`).
- **Diferencias frente a la versión anterior:**
  - La velocidad máxima de 14-16 m/s en `c_reposo` sale IGUAL con la capa anterior: viene del orden nuevo de fases de la prueba, no del código.
  - El reposo del original sí cambia un poco con el código nuevo (de lado, 0,020 → 0,035 m; velocidad, 0,45 → 0,66), dentro de los límites. v2 y v3, iguales.
- **Capturas con movimiento real** (`2026-11-14_144545`): cruces 2 / 0 / 0 (original, v2, v3).
  - En el original, `giro_180_028` ya no cruza el muslo: solo roza la espada izquierda, que está dentro de la tolerancia.
  - Queda `giro_180_040` (rodilla), que en la imagen no se ve porque la tela queda detrás.
- **Pendiente:** medir en el Redmi el coste real de los subpasos en los giros.
