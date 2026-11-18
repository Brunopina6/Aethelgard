# Pruebas que esperan a una carga en hilo: la carrera del bosque en las demás (18/11)

Rama `area-pruebas-carreras-18`, desde `4dc8179`. Registros de todas las pasadas en
`D:\REBELUM_diagnostico\pendientes_18_11\pruebas_carreras\` (una carpeta por pasada, numeradas como en la tabla). No
se ha tocado el juego: solo `aethelgard/pruebas/` y este documento.

## La carrera que se busca

La de `prueba_bosque_pastos` (docs/v12/BOSQUE_RECARGA_18_11.md): una prueba espera a que acabe un
`Recursos.cambiar_escena` **contando fotogramas** («30 s» = 900 fotogramas), pero la carga va en un hilo y tarda en
tiempo **real**. Con `--fixed-fps 30` y sin ventana, 900 fotogramas pasan en 1-2 s reales; con ventana, el ritmo lo
pone la pantalla (en este PC, 144 Hz: 1200 fotogramas son unos 8 s). Si la espera se agota con el cambio en curso,
la prueba sigue: pide otra escena (que `cambiar_escena` **ignora** mientras cambia, a propósito), toma la escena vieja
por la nueva, o se acaba el tope y falla sin motivo.

Para que haya carrera hacen falta tres cosas:

1. la escena llega por `Recursos.cambiar_escena` (carga en hilo). Con `change_scene_to_file` la carga es síncrona:
   no corre ningún fotograma mientras carga y `R.cambiando` no se pone a `true`, así que contar fotogramas es correcto;
2. la espera, o un tope global, cuenta fotogramas;
3. al agotarse, la prueba sigue y hace algo que depende del cambio, o falla, o termina en silencio.

## Contraprueba determinista

Solo en mi copia y **sin commit** (ya quitado; el parche está en
`D:\REBELUM_diagnostico\pendientes_18_11\pruebas_carreras\retraso_contraprueba_recursos.diff`): en `recursos.gd`, justo después de la carga en hilo de `cambiar_escena`, un retraso
por reloj si existe la variable de entorno `REBELUM_RETRASO_CARGA_MS` (imprime «[contraprueba] retraso de N ms en la
carga de …»). Alarga el tramo con `R.cambiando = true` y no cambia nada más. Las pasadas se lanzaron con
`ejecutar_pruebas.ps1` (datos aislados) desde un lanzador propio con tope de 1200 s, de una en una; en todas, la
partida real y la carpeta real de datos quedaron sin cambios y no había otro Godot abierto.

Con el retraso, casi toda prueba que espere una carga en hilo contando fotogramas falla siempre, en vez de una vez de
cada muchas con el PC cargado (revisión del 18/11: no siempre; `prueba_naira_mision` sin arreglo pasó con 5 s por carga,
porque agotar sus 27000 fotogramas depende del ritmo sin ventana; su arreglo es correcto, pero esa fila no lo demuestra:
haría falta un retraso de 15-20 s por carga): sirve para encontrar las que faltaban, no solo para comprobar las ya sospechosas.

| Pasada | Prueba | Retraso | Resultado |
|---|---|---|---|
| 01 | `prueba_arboleda_tramo` **sin arreglo** | 25 s | FALLIDA en 30 s: «C: no se abre el tramo» (los 1200 fotogramas se agotan antes de los 25 s) |
| 02 | `prueba_arboleda_tramo` con arreglo | 25 s | 0 fallos, 6 cargas retrasadas, 170 s, 10 capturas |
| 03 | `prueba_arboleda_tramo` con arreglo | 70 s | FALLIDA en 64 s con el fallo propio («…arboleda_tramo.tscn no termina de cargarse en 60 s (R.cambiando=true…): no se pide nada más»), sin errores de guion |
| 04 | `prueba_arboleda_tramo` con arreglo | 0 | 0 fallos, 20 s, 10 capturas |
| 05 | `prueba_isla` **sin arreglo** | 25 s | salida 0 y «terminó sin errores», pero 2 de 4 capturas: llega a la isla y se corta a los 1500 fotogramas, sin volver al mapa |
| 06 | `prueba_isla` con arreglo | 25 s | 4 de 4 capturas y «de vuelta en el mapa» (las dos cargas retrasadas) |
| 07 | `medir_memoria_texturas` sin cambios | 90 s | mide bien Oakhaven; no pasa por `cambiar_escena` (ver abajo) |
| 08 | `prueba_bosque_pastos` **sin arreglo** (`c72bc5b`) | 5 s | FALLIDA en 70 s: «8: la región no vuelve a cargarse»; volcado «1010 ms reales y 900 fotogramas · R.cambiando=true · Preparando el combate» |
| 09 | `prueba_bosque_pastos` con arreglo (`3d354b5`) | 5 s | SUPERADA en 21 s |
| 10 | barrido A, 18 pruebas sin ventana | 5 s | 18 superadas (26 cargas retrasadas en 10 de ellas) |
| 11 | barrido B, 17 pruebas sin ventana | 5 s | 15 superadas, **2 fallidas**: `prueba_sunken3d`, `prueba_barrio_interiores` (40 cargas retrasadas en 8) |
| 12 | barrido C, 15 pruebas sin ventana más | 5 s | 13 superadas, **2 fallidas**: `prueba_naira_mision`, `prueba_ciclopea3d` (5 cargas retrasadas en 2) |
| 13 | las 4 fallidas, con arreglo | 5 s | 4 superadas |
| 14 | las 4, más `prueba_bosque_pastos`, `prueba_banco_pruebas`, `prueba_cargas` | 0 | 7 superadas |
| 15 | `fotos_barrio_recorrido` con un arreglo de prueba | 5 s | 0 fallos, 49 capturas, 375 s; las 2 recargas retrasadas |
| 16 | lo mismo, repetido | 5 s | FALLIDA: «no empieza ningún diálogo» y «A7: Tobías no cuenta lo del reparto», lejos de cualquier carga |
| 17 | `fotos_barrio_recorrido` **sin arreglo** | 5 s | FALLIDA con los mismos dos fallos de Tobías; la recarga pasa (foto «A13 tras recargar») |

La 08-09 es la contraprueba determinista que faltaba para el bosque (el 18/11 solo se reprodujo con carga de CPU, 3
de 9).

Los barridos A y B son las 35 pruebas sin ventana de la lista que nombran «cambiando» (más `prueba_musica` y
`prueba_sunken3d`); el C, 15 pruebas sin ventana que no lo nombran pero cambian de escena (encuentros, salidas,
banco, «Guardar y recargar»). En la pasada 10 el ejecutor dijo «proyecto: CAMBIADO»: fui yo, que escribí este
documento y hice dos commits mientras corría; en las demás, «sin cambios».

## Arreglos (un commit por grupo, en esta rama)

El mismo patrón que el bosque: la espera de la carga, **por reloj**, y si no termina, un fallo con mensaje propio en
vez de seguir a ciegas. Las esperas de juego (diálogos, andar, fundidos del barrio) siguen en fotogramas a propósito.

| Prueba | Modo | Antes | Ahora | Contraprueba |
|---|---|---|---|---|
| `prueba_arboleda_tramo` | ventana | `_esperar_escena`: 1200 fotogramas, y después pedía la escena siguiente (C, F, H) | 60 s de reloj; si no, FALLO propio, `FALLOS`, salida 1 y no pide nada más | 01 / 02, 03, 04 |
| `prueba_isla` | ventana | tope de 1500 fotogramas para todo, incluidas dos cargas en hilo; terminaba **en silencio** (salida 0) | cada carga, 60 s de reloj; si no, «FALLO: fase N…» y salida 1 | 05 / 06 |
| `prueba_barrio_interiores` | auto | tras `guardar_y_recargar()` (que recarga la MISMA escena), `_cargar()` aceptaba la región **vieja**, aún montada | espera por reloj a una región distinta de la vieja y al final del cambio; si no en 60 s, fallo y no sigue | 11 / 13, 14 |
| `prueba_sunken3d` | auto | el final del muelle: 400 fotogramas hasta el mapa | 60 s de reloj hasta el mapa y el final del cambio | 11 / 13, 14 |
| `prueba_ciclopea3d` | auto | la salida del sur: 300 fotogramas mientras la región sigue montada | 60 s de reloj; Kael solo recibe destino mientras no se ha pedido el cambio | 12 / 13, 14 |
| `prueba_naira_mision` | auto | tope global de 27000 fotogramas, que las 4 cargas se comían | tope global de 300 s de reloj (normal: 11 s) | 12 / 13, 14 |

**`fotos_barrio_recorrido`: no se ha cambiado.** Tiene la misma forma que `prueba_barrio_interiores` (tras «Guardar y
recargar», 300 fotogramas hasta ver una región distinta de la vieja; después `_cargar_region()` toma la que haya), y
probé el mismo arreglo (pasadas 15 y 16). Pero con 5 s de retraso la versión sin arreglo también pasa la recarga
(pasada 17), probablemente porque con ventana este recorrido va más lento que la pantalla y 300 fotogramas duran más
de 5 s (no lo medí). La mejora no quedó demostrada, así que se conserva lo que había. Un retraso de 15 s lo diría (dos
pasadas de unos 6,5 min; no cabían en el tiempo). Las pasadas 16 y 17 fallaron por otra cosa, lejos de cualquier
carga: Tobías no abre su diálogo tras el reparto (A7). Falló en 2 de las 3 pasadas con retraso (una con el arreglo
de prueba, otra sin él). No lo he investigado y no sé si sale sin retraso.

Con los fallos de los barridos: sin arreglo, `prueba_barrio_interiores` daba «5: «Guardar y recargar» dentro: vuelve
fuera», «Kael en la puerta de fuera de la vivienda» y otro en cascada; `prueba_sunken3d`, «8: el final del muelle no
lleva al mapa»; `prueba_ciclopea3d`, «la salida del sur no lleva al mapa»; `prueba_naira_mision`, «se pasa de tiempo
en la fase «aclara»».

Nota: `prueba_sunken3d` (línea 416) entra en la región con `change_scene_to_file` porque «la carga en segundo plano de
Recursos.cambiar_escena falla en las pruebas sin ventana con --fixed-fps 30». Lo más probable es que fuera esta misma
carrera (esperas en fotogramas); no lo he cambiado: entra bien así y la salida al mapa ya prueba `cambiar_escena`.

## Lista revisada (61 archivos que nombran «cambiando», más los del barrido C)

### Con la carrera: arreglados

`prueba_bosque_pastos` (ya el 18/11, confirmado ahora con 08-09), `prueba_arboleda_tramo`, `prueba_isla`,
`prueba_barrio_interiores`; y, sin nombrar «cambiando», `prueba_sunken3d`, `prueba_ciclopea3d` y
`prueba_naira_mision` (tabla de arriba).

**Añadidas tras la revisión (18/11):** `prueba_oakhaven3d` (la salida al mapa esperaba 300 fotogramas, y tope global de
8000) y `prueba_mar_cristal` (tope global de 12000 fotogramas, que se comen las cargas del mapa y del combate). No nombran
«cambiando», y la búsqueda por palabras no las vio; el revisor las encontró pasando la batería con el retraso: con 5 s
fallaban siempre y con su arreglo (esperas y topes por reloj, commit propio en claude/rebelum-v12) pasan con y sin retraso.
La lista, por tanto, no es completa: cerrarla exige pasar la batería entera sin ventana con el retraso (parche por argumento
en D:\REBELUM_diagnostico\pendientes_18_11\revisa_carreras\retraso_contraprueba_con_argumento.diff).

### Con la misma forma, sin cambiar

`fotos_barrio_recorrido` (ventana): ver arriba; la contraprueba con 5 s no lo distingue.

### Esperas por reloj: no necesitan cambio

Su `_hasta` (o su bucle) mide `Time.get_ticks_msec()` y, si se agota, fallan con un mensaje:
`prueba_cargas`, `prueba_charlas_posada`, `prueba_comentarios`, `prueba_efectos`, `prueba_efectos_senal`,
`prueba_foco_fotos`, `prueba_garganta3d_examinables`, `prueba_gran_bosque3d`, `prueba_hallazgos`, `prueba_mando`,
`prueba_mapamundi3d`, `prueba_mapamundi3d_apagado`, `prueba_notas_exploracion`, `prueba_oakhaven`,
`prueba_oakhaven_ciudad_arte`, `prueba_oakhaven_fotos`, `prueba_oakhaven_rutinas`, `prueba_oakhaven_vida`,
`prueba_posadera_servicios`, `prueba_foco` (la ciudad), `prueba_musica`, `fotos_gran_bosque3d`, `grabar_mapamundi3d`,
`medir_memoria_escenas`, `medir_ciudad`, `recorrido_ciudad`, `diag_ciudad_romper` (sus `_pulsar` y las esperas del
banco y de «Guardar y recargar» son por reloj; la de recargar compara con la escena vieja), `medir_barrio`,
`medir_isla`, `medir_muestra_calle` y `medir_sunken3d` (`_entrar`, 60 s).

En `prueba_cargas`, `await _hasta(not R.cambiando, 60.0)` no mira lo que devuelve, pero es por reloj y la línea
siguiente comprueba la escena con `_ok`.

### Máquinas de pasos: no necesitan cambio

`_process` con `paso`/`fase`; cada paso avanza solo cuando se cumple «escena = X **y** `not R.cambiando`», y el tope
de cada paso es por reloj (`ESPERA_MAX_MS`, 20-120 s) con `_fallo`. Nunca piden otra escena sin haber visto acabado el
cambio anterior: `prueba_centinela`, `prueba_cofre3d`, `prueba_coloso_garganta`, `prueba_garganta3d`,
`prueba_mirador`, `prueba_ruta_alpha`, `prueba_zona3d`, `prueba_escenas` (todas superadas en los barridos con 5 s).

### Cuentan fotogramas, pero la escena llega con `change_scene_to_file`: no necesitan cambio

`prueba_comentarios_3d`, `prueba_orden_pv03`, `prueba_mc_rincon`, `prueba_rincones_pastos`, `prueba_calidad_auto`
(apartado 6), `prueba_foco` (el mapa), `prueba_veta_garganta` (tope global de 3600 fotogramas, «se pasa el tiempo»),
`fotos_mc_rincon`, `fotos_rincones_pastos`, `fotos_bosque`, `fotos_claro_guardian`. Las auto, superadas con el
retraso; ninguna pasa por `cambiar_escena` en estas esperas (la única carga retrasada de `prueba_foco` es la de la
ciudad, que espera por reloj).

### Herramientas de medida con tope en fotogramas: no necesitan cambio

`medir_escenas` (30000), `medir_garganta3d`, `medir_ruta`, `medir_primeras_veces` (20000): máquinas de fases que solo
avanzan con «escena = X y `not R.cambiando`» y miden la carga por reloj (`get_ticks_usec`); el tope solo corta una
medida colgada. Son manuales; no se han ejecutado.

### «cambiando» de otra cosa

- `prueba_barrio_trazado` y el resto de `prueba_barrio_interiores` y `fotos_barrio_recorrido`: `v.cambiando` es el
  fundido de entrar o salir de un interior del barrio (un tween en tiempo de juego), no `Recursos`; contar fotogramas
  es lo correcto.
- `prueba_calidad_auto` (línea 418) y `sonda_oclusion_repetida`: «cambiando» en un texto o un comentario.

### `medir_memoria_texturas`: otra espera, sin esta carrera

Con `con_carga` espera hasta 6000 fotogramas a que la pantalla de carga quede lista y después monta Oakhaven con
`change_scene_to_file`. Parecía el mismo caso, pero la pasada 07 lo descarta: con la portada alternativa, la carga pasa
a la portada con `change_scene_to_file` y `cambiar_escena` solo se llama al tocar, así que `R.cambiando` no interviene.
Sí espera en fotogramas una precarga que va en tiempo real (11,3 s en la pasada 07, frente a unos 40 s que dan 6000
fotogramas a 144 Hz): es otro riesgo, pequeño, que esta contraprueba no puede demostrar. No lo he cambiado.

### Barrido C sin cargas retrasadas

`prueba_grupos_combate`, `prueba_guardian_bosque`, `prueba_escalado`, `prueba_coloso`, `prueba_gremio`,
`prueba_bramavidrio_combate`, `prueba_climax_jefe`, `prueba_grupo_reserva`, `prueba_naira_combate`, `prueba_nix_v12`,
`prueba_banco_pruebas`, `prueba_barrio_vivo`, `prueba_ciudad_cargador`: superadas con el retraso sin pasar por él
(montan el combate o la escena directamente).

## Esperas sin tope (no son esta carrera)

`medir_mapamundi3d` (línea 53, `while _esc() != MM or R.cambiando`) y `medir_sunken3d` (línea 122, la vuelta al mapa)
esperan sin límite. Son manuales y las mata el tope del ejecutor, pero si `_entrar` de `medir_sunken3d` agota sus
60 s con el cambio en curso, su `cambiar_escena("res://mapa.tscn")` se ignoraría y la espera siguiente no acabaría
nunca. No se han tocado (no cuentan fotogramas y no se pueden comprobar sin medir).

## Lo que no se ha hecho

- No se ha ejecutado la batería completa: solo las 17 pasadas de la tabla (73 ejecuciones de pruebas).
- Las capturas de las pruebas con ventana (02, 04, 06, 15) no las ha revisado una persona; siguen siendo MANUALES.
- No se ha probado nada en Android: este documento habla solo de las pruebas del PC.
- El retraso de `recursos.gd` no está en ningún commit y ya no está en la copia.

## Pendiente

- `medir_mapamundi3d` y `medir_sunken3d`: tope por reloj en sus dos esperas sin límite.
- `medir_memoria_texturas`: la espera de la pantalla de carga, por reloj.
- Las 145 pruebas sin ventana de la lista (196 en total) que no entraron en los barridos no se han pasado con el retraso; las que
  usan `cambiar_escena` sin nombrar «cambiando» se buscaron por palabras (encuentros, salidas, banco, recargar), no
  una a una. Un barrido completo con `REBELUM_RETRASO_CARGA_MS=5000` (añadiendo el retraso solo en una copia local)
  diría si queda alguna.
- Volver a probar en `prueba_sunken3d` la entrada desde el mapa con `cambiar_escena` (la nota de su línea 416).
- `fotos_barrio_recorrido`: repetir la contraprueba con 15 s de retraso (sin y con el arreglo de `prueba_barrio_interiores`)
  y mirar el fallo intermitente de Tobías en A7 (2 de 3 pasadas con 5 s de retraso).
