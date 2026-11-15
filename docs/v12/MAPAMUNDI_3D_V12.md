# Mapamundi 3D explorable y viaje rápido (V12, 15/11/2026)

**Estado: EXPERIMENTAL DE AUDITORÍA, APAGADO POR DEFECTO.** El mapa de siempre (`mapa.tscn`) no cambia. Todo lo nuevo
(relieve, campamento, cueva, secreto, nombres y textos) es **PROPUESTA**, no canon. Rama `claude/v12-mapamundi3d`
(desde `1239e78`).

Encargo: *«Autorizo implementar esta función como experimental de Auditoría, apagada por defecto, conservando el mapa
actual.»* Primera región, «Tierras de Oakhaven» (continente Norte).

## 1. Cómo se activa y qué se juega

- **Activar:** con la exploración 3D activa (la app experimental o `-- 3d`), en **Ajustes → «Mapamundi: Mapamundi 3D
  (en pruebas)»**. La fila solo sale en la APK de Auditoría o en el editor (`calidad_proto.pruebas_permitidas`). Se
  guarda en `user://ajustes.cfg`, `[regiones] mapamundi3d`. Para las pruebas: argumento `mapamundi3d` (lo enciende) o
  `mapamundi2d` (lo apaga). Código: `modo3d.gd`, `mapamundi_activo()`.
- **Encendido:** al **salir de Oakhaven 3D o de Pastos Verdes 3D** se llega al mapamundi 3D, junto a la entrada de ese
  lugar (`modo3d.salida_al_mapa`). Desde ahí se anda por la maqueta y, al pisar el círculo dorado de una miniatura (o
  con «Entrar: …»), se carga la ubicación a escala del personaje.
- **Apagado:** las salidas van al mapa de siempre; una partida guardada en el mapamundi o en la cueva vuelve al mapa de
  siempre en el sitio equivalente (`pos_mapa`, que el mapamundi siempre deja apuntado).

Lo que hay en la región (escala: 1 px del mapa 2D = 0,25 m):

| Sitio | Qué es | Entrada lleva a |
|---|---|---|
| Oakhaven | maqueta: muralla, Puerta del Sur, tejados, Taberna del Cuervo Oxidado, torre, crematorio con humo frío, **Árbol Milenario** | `zonas3d/oakhaven_3d.tscn` (o la 2D si se eligió en Ajustes) |
| Pastos Verdes | lomas, río con franjas que bajan, puente de piedra, cascada, estela, faroles de Tilo, flores | `zonas3d/pastos_verdes_3d.tscn` |
| Camino principal | Oakhaven → campamento → Pastos → hacia el Gran Bosque (sureste) | — |
| Bifurcación (con poste) | senda hacia la sierra del oeste y la cueva | — |
| **Corro de los Mirlos** (secreto, PROPUESTA) | piedras con musgo en un soto cerrado, por una senda casi borrada de losas sueltas | descubrimiento + ofrenda una vez (2 Pociones y 1 Éter) |
| **Cueva de los Helechos** (PROPUESTA) | peñasco con boca oscura y helechos al pie de la sierra | `zonas3d/cueva_provisional_3d.tscn` |
| **Campamento de Pastos Verdes** (PROPUESTA) | dos tiendas, hoguera animada (luz real solo en alto) y mojón de viaje con runa | descubrimiento + punto de viaje rápido |
| Portal del Vacío | arco de oro con remolino morado animado | la ciudad flotante (`isla.tscn`), como en el mapa 2D (vuelve al mapa de siempre) |
| Poste del sureste | «Hacia el Gran Bosque Verde» | el mapa de siempre junto al Gran Bosque |

La costa, las praderas y los bosques salen de **la misma máscara del mapa 2D** (`mapa_arte/mapa_zonas.png`): las
posiciones relativas de Oakhaven (520, 330), el Portal (650, 405), Pastos (660, 478) y el camino al Gran Bosque
(720, 540) se respetan (`D:\REBELUM_diagnostico\mapamundi_15_11\ref_mapa2d_region.png` frente a
`capturas_1600x720\00_region_desde_arriba_*.png`). La sierra del oeste y los cerros del nordeste son relieve propuesto
(el mapa 2D no dibuja montañas en esa zona). Para no inventar canon, la cueva **no** es la Gruta del Velo (que va dentro
de Pastos) ni la Escalera del Cielo: es una escena provisional nueva.

**Solo Kael en el mapamundi:** no se crea `grupo_3d.gd`; Kael va a escala ×1,45 (se lee en el móvil). Los compañeros
siguen en la partida con sus datos intactos (botón «GRUPO» abre `menus.gd`) y vuelven a seguirle dentro de Pastos,
Oakhaven y la cueva: la formación de dentro no cambia.

## 2. Controles

| Acción | Táctil | PC / mando |
|---|---|---|
| Andar | tocar o arrastrar en el suelo (como las regiones 3D) | flechas / WASD / stick |
| Zoom | pellizco | rueda / `camara_acercar`, `camara_alejar` |
| Entrar en un sitio | pisar su círculo dorado, o el botón «Entrar: …» | Intro / A cerca de la entrada |
| Viaje rápido | botón «VIAJE RÁPIDO» o, junto al mojón del campamento, «Viaje rápido» | Tab / Esc / Start (`menu_juego`) o V |
| En el menú de viaje | tocar un destino; «Cancelar» | ↑ ↓, Intro / A; Esc / B cancela |
| Grupo | botón «GRUPO» | — |

Cámara elevada fija (55°, 27 m, la de `prototipos/vista3d.gd`), sin giro.

## 3. Viaje rápido (primera entrega: Oakhaven y el campamento de Pastos Verdes)

- **Desbloqueo al visitar por primera vez:** Oakhaven al entrar en ella o volver de ella; el campamento al pasar a 5 m.
- **Elegir:** desde el mapamundi (botón) o desde el punto habilitado (el mojón del campamento).
- Cada destino enseña **nombre y región** («Tierras de Oakhaven · Norte», «Tierras de Oakhaven · Pastos Verdes»). El
  destino donde ya estás sale apagado («estás aquí»).
- **Los desconocidos no aparecen** (ni su nombre). Sin destinos: «Aún no conoces ningún destino.»
- **Gratis y con llegada segura:** fundido, Kael en la «llegada» del sitio, fuera del círculo (no entra solo), pasos de
  encuentro a cero, guardado.
- **Bloqueado y explicado** (`datos.motivo_bloqueo`): durante un combate o su emboscada («No puedes viajar durante un
  combate.»), una escena de Dialogic o cinemática («…mientras dura una escena.»), al estar llegando, y antes de terminar
  el prólogo (restricción narrativa).
- **Barreras de progresión:** cada destino puede pedir un hito (`DESTINOS[id]["requiere"]`); hoy ninguno lo pide.
- **Guardado:** descubrimientos en `mazmorras["mapamundi"]` (clave EXISTENTE de la partida, diccionario de sí/no; no hace
  falta tocar `progreso.gd`). Posición en el mapamundi: `pos_3d` con `pos_3d_lugar = 100` (cueva: 101).
- **Partidas antiguas:** sin la clave no hay nada descubierto ni ningún destino; no se revela nada.

## 4. Transiciones y recuperación

- Al salir de una ubicación, Kael aparece fuera de su círculo y la entrada no se arma hasta alejarse 2,6 m (sin
  reentradas automáticas). La llegada es de la sesión (`Engine «mm3d_llegada»`), no de la partida.
- Grupo, inventario, misiones e hitos no se tocan: el mapamundi solo lee y escribe `mazmorras["mapamundi"]`,
  `cofres_abiertos` (el secreto y el frasco de la cueva) y las posiciones.
- Encuentros por el camino como en el mapa 2D (un paso cada 5 m, los mismos pasos seguros y probabilidad de
  `progreso.gd`), nunca junto a los sitios; el combate vuelve al mismo sitio del mapamundi.
- **Si una carga falla:** `recursos.gd` (`cambiar_escena`) avisa a la escena que lo pidió si tiene `carga_fallida`; el
  mapamundi y la cueva quitan el fundido, devuelven el control, desarman la entrada y avisan. Una ruta que no existe ni
  siquiera empieza a fundir. Las demás escenas siguen como siempre.

## 5. Estructura futura (SOLO estructura, nada implementado)

| Continente | Bioma | Estado |
|---|---|---|
| **Norte** | bosques y praderas | **primera región implementada: Tierras de Oakhaven** |
| Oeste | desiertos y cañones | sin construir (el Mar de Arena y la Garganta siguen en el mapa 2D y sus 3D) |
| Sur | nieve, glaciares y cuevas | sin construir |
| Este | ríos, lagos, mares y archipiélagos | sin construir |

Previsto, **no implementado**: navegación por el mar y remolinos que lleven a escenarios submarinos al obtener la
capacidad correspondiente. Encaje pensado: un sitio más en `datos.SITIOS` con `"requiere"` (hito de la capacidad),
una entrada en el agua (el mar ya existe en la maqueta, `terreno.crear_agua`) y su escena; el viaje rápido ya admite
barreras por hito. Nada de esto existe hoy en el juego.

Para crecer: cada región nueva es otro trozo del mapa 2D con su `ORIGEN_2D` (mismo `terreno.gd` y `maquetas.gd`); hay
que convertir `datos.gd` en datos por región y decidir cómo se pasa de una a otra (hoy, el poste del sureste lleva al
mapa de siempre).

## 6. Archivos

Nuevos: `zonas3d/mapamundi_3d.gd/.tscn`, `zonas3d/cueva_provisional_3d.gd/.tscn`, `zonas3d/mapamundi/` (`datos.gd`,
`terreno.gd`, `kit.gd`, `vegetacion.gd`, `maquetas.gd`, `menu_viaje.gd`, `agua_mapamundi.gdshader`,
`efectos_mapamundi.gdshader`), `pruebas/prueba_mapamundi3d.gd`, `prueba_mapamundi3d_apagado.gd`,
`fotos_mapamundi3d.gd`, `grabar_mapamundi3d.gd`, `medir_mapamundi3d.gd`.
Tocados (mínimo, comentados «V12, mapamundi 3D»): `modo3d.gd` (activación, salida, partida apagada), `recursos.gd`
(aviso `carga_fallida`), `menus.gd` (una línea en Ajustes), `musica.gd` (música del mapa y de la cueva),
`zonas3d/oakhaven_3d.gd` y `zonas3d/pastos_verdes_3d.gd` (una línea en `_salir`). Sin tocar: `mapa.gd`, `progreso.gd`,
`banco_pruebas.gd`, Érebo, Custodio, Sunken, Nix, `combate.gd`.

## 7. Pruebas (resultados literales, `D:\REBELUM_diagnostico\pruebas\2026-11-15_152051`)

`powershell -ExecutionPolicy Bypass -File aethelgard\pruebas\ejecutar_pruebas.ps1 -Solo …`: **17 SUPERADAS, 0 FALLIDAS**
(prueba_escenas, prueba_zona3d, prueba_ruta_alpha, prueba_grupo3d, prueba_cofre3d, prueba_guardado, prueba_partida,
prueba_restaurar_escenas, prueba_mapamundi, prueba_oakhaven3d, prueba_oakhaven3d_completo, prueba_integridad,
prueba_formato_regiones, prueba_ciclopea3d_apagada, prueba_sunken3d_apagada, prueba_mapamundi3d,
prueba_mapamundi3d_apagado); «partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin
cambios».

`prueba_mapamundi3d` (`-- 3d mapamundi3d sin_prologo`):
```
OK 1 interruptor: encendido con el argumento; Oakhaven y Pastos salen al mapamundi; los demás, al mapa de siempre
OK Oakhaven → mapamundi: solo Kael en el mapamundi; el grupo (["Kael", "Lya", "Garon"]) sigue con sus datos intactos
OK 2 Oakhaven → mapamundi: junto a la entrada, sin reentrar en 1,5 s, Oakhaven descubierta y guardado (t _ready 490 ms)
OK 3a campamento descubierto al pasar (nombre visible, destino de viaje: ["oakhaven", "campamento"])
OK 3b Pastos Verdes 3D cargado al pisar su miniatura; el grupo le sigue dentro (2)
OK Pastos → mapamundi: solo Kael en el mapamundi; el grupo (["Kael", "Lya", "Garon"]) sigue con sus datos intactos
OK 3c Pastos → mapamundi junto a su entrada, sin reentrar
OK 4a cueva provisional cargada (grupo dentro: 2)
OK 4b el frasco de la cueva: +1 Éter, una sola vez
OK 4c cueva: descubierta, entrada y salida junto a su entrada, sin reentrar
OK 5 secreto: descubierto por su senda, premio una sola vez (+2 Pociones, +1 Éter)
OK 6a menú: ["Oakhaven", "Campamento de Pastos Verdes"] con su región; Esc lo cierra sin viajar
OK 6b viaje rápido al campamento: llegada segura (pasos 0)
OK 6c viaje rápido a Oakhaven (desde el mojón): junto a su entrada, sin entrar solo
OK 7a bloqueos explicados: combate, escena, prólogo, barrera de hito y destino que no existe
OK 7b encuentro → combate (viaje bloqueado dentro) → vuelta al mismo sitio
OK 8a guardar y cargar: misma escena, mismo sitio, descubrimientos ["oakhaven", "campamento", "pastos", "cueva", "secreto"]
OK 8b partida antigua sin la clave: nada descubierto, menú vacío con su aviso, sin nombres de sitios ocultos
OK 9 tres vueltas mapamundi → Oakhaven → mapamundi sin duplicar (nodos 143, Kael 1, conexiones de Dialogic 3)
OK 10a ruta que no existe: sigue en el mapamundi, con control y sin negro
OK 10b escena rota: Recursos avisa al mapamundi (carga_fallida), sin negro, con control y Kael anda
FALLOS: 0
```
(La prueba 9 compara también nodos de la raíz, huérfanos, modelos de Kael y conexiones de `process_frame`: iguales en las
tres vueltas. La 10b usa un recurso que existe pero no es una escena.)

`prueba_mapamundi3d_apagado` (`-- 3d sin_prologo`):
```
OK 1 apagado por defecto: Oakhaven y Pastos salen al mapa de siempre
OK 2 Oakhaven 3D → mapa de siempre (11 lugares, con Pastos Verdes)
OK 3 partidas del mapamundi y de la cueva → mapa de siempre en el sitio equivalente; descubrimientos intactos
OK 4 la opción de Ajustes lo enciende y lo apaga
FALLOS: 0
```

Recorrido con ventana: las dos grabaciones del Movie Maker (abajo) son el juego real con ventana y sonido, sin errores.

## 8. Capturas, vídeos y medidas

Carpeta `D:\REBELUM_diagnostico\mapamundi_15_11\`:
- `capturas_1600x720\` — 14 fotos × 3 perfiles (región desde arriba y en diorama, llegada de Oakhaven, bifurcación,
  campamento, Pastos, Portal, cueva, secreto, camino del Gran Bosque, viaje rápido, cueva por dentro y sus cristales),
  con `medidas_fotos_<perfil>.txt`.
- `mapamundi3d_recorrido_15_11.mp4` (28,7 s, H.264 + AAC): Oakhaven 3D → Puerta del Sur → mapamundi → campamento
  (descubierto) → Pastos Verdes 3D con el grupo → salida → mapamundi junto a su entrada. Hoja: `hoja_recorrido.png`.
- `mapamundi3d_viaje_rapido_15_11.mp4` (14 s): menú → campamento → mojón → Oakhaven. Hoja: `hoja_viaje_rapido.png`.
- `medidas_mapamundi3d_pc.txt` (después) y `medidas_mapamundi3d_pc_antes_cache_suelo.txt` (antes).

Medidas de PC (RTX 3050 Laptop, ventana 1600×720; **durante la medida había otros Godot de otras sesiones lanzando
pruebas sin ventana**; no certifica Android):

| Perfil | Carga (1.ª del proceso / repetida) | Dibujos | Primitivas | CPU dibujo | GPU | Memoria estática / vídeo | Árboles |
|---|---|---|---|---|---|---|---|
| bajo | 1380 / 560 ms | 40-58 | 50-60 mil | 0,89-1,02 ms | 0,53-0,59 ms | 112 / 43 MB | 557 |
| medio | 572 / 566 ms | 51-62 | 82-96 mil | 1,00-1,04 ms | 0,54-0,57 ms | 113 / 43 MB | 742 |
| alto | 577 / 519 ms | 64-78 | 105-167 mil | 1,10-1,20 ms | 0,94-1,00 ms | 113 / 60 MB | 947 |

El relieve se calcula una vez por sesión (223 ms) y las mallas del suelo se reutilizan. **Optimización medida:** con la
caché de las mallas del suelo, la `_ready` repetida baja de 266-285 ms a 109-118 ms y la carga repetida de 665-725 ms a
519-566 ms (mismo PC, mismas condiciones). Lo demás para Android (trozos de 4 × 4 del suelo y de los bosques que Godot
descarta fuera de cámara, versión lejana simplificada de los árboles a partir de 48 m, densidad por perfil, sombras de
los árboles solo en alto, luz de la hoguera solo en alto, agua opaca sin texturas) es diseño: **no se ha medido en el
Redmi**, así que no se afirma que mejore allí.

## 9. Estado artístico

- **Provisional (PROPUESTA, hecho por código):** todas las maquetas (Oakhaven, Pastos, Portal, campamento, cueva, corro,
  postes), los árboles, el relieve inventado (sierra, cerros), los nombres «Tierras de Oakhaven», «Campamento de Pastos
  Verdes», «Cueva de los Helechos», «Corro de los Mirlos» y sus textos, y la cueva entera.
- **Revisado en capturas a 1600×720** (este agente): paleta corregida (Compatibility no pasaba el color del vértice a
  lineal: salía lavado), Kael ×1,45, camino más estrecho, entrada de Pastos fuera del camino (antes se entraba sin
  querer al seguir el camino), poste en la bifurcación, borde del bosque difuminado, tiendas de pico, cueva más clara.
- Pendiente de arte: maquetas en Blender (sobre todo Oakhaven y Pastos), vegetación con hojas, rótulos con el estilo del
  mapa pintado, la entrada de Pastos dice «Mapa del mundo» en su letrero aunque lleve al mapamundi.

## 10. Pendientes

- **Redmi:** activar en Ajustes (APK de Auditoría) y medir con RND en la llegada de Oakhaven, el campamento y el camino
  del Gran Bosque en bajo y medio; carga desde Oakhaven y desde Pastos; tocar para andar entre árboles (los troncos son
  obstáculos: sin búsqueda de caminos, Kael se para ante ellos); legibilidad de rótulos y botones en 20:9.
- El Portal y el poste del sureste llevan al mapa de siempre (y de allí no se vuelve al mapamundi salvo entrando en
  Oakhaven o Pastos): falta decidir la convivencia entre ambos mapas (p. ej. una entrada al mapamundi desde el mapa 2D).
- Gran Bosque Verde y el resto de regiones no salen al mapamundi (solo Oakhaven y Pastos).
- Los encuentros del mapamundi usan los grupos de enemigos del mapa 2D; sin revisar el equilibrio.
- `mazmorras["mapamundi"]` vale para una región; con más regiones, prefijar por región.
- Sin cinemática de llegada ni música propia (usa la del mapa).
