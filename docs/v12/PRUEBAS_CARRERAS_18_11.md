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

## Barrido completo con retraso (18/11, 11:35)

Batería entera (sobre `6a554c5`, con los 8 arreglos y prueba_grupo_despejado) con el parche de retraso aplicado solo en
la copia de trabajo, sin commit y quitado al terminar (`recursos.gd` limpio), y `REBELUM_RETRASO_CARGA_MS=5000`:
**197 superadas, 0 fallidas, 116 manuales**; partida real, carpeta real y proyecto sin cambios. 28 pruebas pasaron por
al menos una carga retrasada (85 cargas en total, «[contraprueba] retraso» en sus registros); las demás no usan la carga
en hilo. Con 5 s por carga ya no queda ninguna prueba automática con esta carrera. Siguen sin cubrir las pruebas con
ventana (MANUALES) y, para las que agotan topes globales en fotogramas según el ritmo (caso naira), un retraso mayor.
Registros: `D:\REBELUM_diagnostico\pruebas\2026-11-18_105737_CONTRAPRUEBA_retraso_5s`.

## El fallo intermitente de Tobías en A7 (`fotos_barrio_recorrido`): causa y arreglo (18/11, 13:05)

**No era esta carrera de cargas ni un fallo del juego.** Con un volcado del estado de Tobías en el momento del fallo
(pasada con 5 s de retraso, `D:\REBELUM_diagnostico\pruebas\2026-11-18_124909`):
- al pulsar: reloj del barrio 244,16 s, charla vacía, tramo «ir» (andando hacia el carro), en ningún paso, a **1,91 m** de
  Kael;
- 2 s después: charla vacía, a 3,23 m; 8 s más: el diálogo NO empieza, a 8,17 m.

El radio para hablar es 1,9 m (`barrio_vivo.RADIO_HABLAR`). La prueba vio el botón «Hablar con Tobías» justo en el borde
mientras él se alejaba; Intro se procesa 1-2 fotogramas después, cuando ya estaba fuera: el botón se había ocultado y la
pulsación no llegó a nadie (`barrio._unhandled_input` exige el botón visible). La hipótesis previa, «charla pendiente
por coger o dejar», quedó **refutada** por el volcado (la charla nunca pasó a «pendiente»). Es intermitente porque
depende del punto del paseo de Tobías en que llega Kael, y los retrasos de carga desplazan ese momento.

Para quien juega es lo mismo que pulsar cuando el vecino ya se ha ido: no pasa nada, se acerca y vuelve a pulsar. Así
lo hace ahora la prueba: si tras Intro no hay diálogo y la charla del vecino sigue vacía, anota «pulsación perdida» y
vuelve a acercarse, dentro de su tope de 180 s. El volcado se queda para cualquier otro fallo de «no empieza ningún
diálogo».

Comprobación con el arreglo y el mismo retraso (`D:\REBELUM_diagnostico\pruebas\2026-11-18_125636`): se da el mismo caso (244,12 s, 1,91 m),
la prueba lo detecta, se acerca, Tobías cuenta lo del reparto y la pasada termina con 0 fallos (49 capturas, MANUAL).
Antes, con el mismo retraso: 2 de 3 pasadas fallaban (pasadas 16 y 17 de este documento, y la de las 12:49).

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

## Seguimiento del 19/11 (PRUEBAS_19_11, C-11 / PC-10, y su revisión)

Hecho: la lista de arriba (`medir_mapamundi3d`, `medir_sunken3d`, `medir_memoria_texturas` y las esperas de
`fotos_barrio_recorrido`) espera ya por reloj, con FALLO al agotarse. En la revisión, `fotos_barrio_recorrido` termina
en cuanto se agota la carga del barrio (antes seguía con la región nula: cinco errores de script «on a base object of
type 'Nil'» y fallos de rebote en A5 y A6); «carga_falla=N» lo comprueba.

Sigue pendiente (PC-10 no queda cerrado):

- Los otros 46 archivos de `pruebas/` que esperan a «cambiando» (`BOSQUE_RECARGA_18_11.md`, «Pendiente»): no se ha
  mirado cuáles cuentan fotogramas en vez de reloj.
- Herramientas con ventana que siguen esperando por fotogramas, por ejemplo `fotos_erebo_hibrida.gd` (l. 79 y 95, 3000 y 4000 fotogramas),
  `grabar_erebo_transicion.gd` (l. 38) y `grabar_erebo_hibrida.gd` (l. 45), hasta 3000 fotogramas, y `medir_erebo_teatro.gd` (l. 19). No se han barrido.
- El barrido completo con `REBELUM_RETRASO_CARGA_MS` (solo en una copia local) sigue sin hacerse.

## ESPERAS_19_11 (PC-10, el resto; commit `709e03a`)

Revisados uno a uno los 67 archivos de `pruebas/` que nombran «cambiando» (los 46 de `BOSQUE_RECARGA_18_11.md` y los
ya arreglados). Criterio de arriba: contar fotogramas solo es una carrera si se espera una carga **en hilo**
(`Recursos.cambiar_escena`). En las 39 automáticas de la lista, todas esas esperas ya iban por reloj (arreglos del
18/11) o por un tope de reloj en cada paso (`ESPERA_MAX_MS`). Lo que quedaba eran esperas por fotogramas tras
`change_scene_to_file` (síncrono: correctas, pero sin FALLO claro si se agotaban, o siguiendo en silencio). Se han
pasado a reloj, sin cambiar lo que miden ni el juego:

- Batería (auto): `prueba_bosque_pastos`, `prueba_comentarios_3d`, `prueba_orden_pv03`, `prueba_mc_rincon`,
  `prueba_rincones_pastos` (montar la región, `_hasta_reloj`; el resto sigue en tiempo de juego), `prueba_sunken3d`
  (`_montar`, 60 s; antes 300 fotogramas y seguía en silencio), `prueba_barrio_interiores` (`_cargar`, 60 s, y termina),
  `prueba_barrio_trazado`, `prueba_foco` (el mapa), `prueba_calidad_auto` (entrada y recarga: la recarga agotada seguía
  con la escena vieja y podía pasar en falso), `prueba_ciclopea3d` (los 25 fotogramas de siempre y hasta 60 s más) y
  `prueba_veta_garganta` (60 s por paso en vez de 3600 fotogramas en total).
- Érebo (a mano, sin tocar su contenido): `fotos_erebo_hibrida` (l. 79 y 95), `grabar_erebo_transicion` (l. 38 y la
  espera del vídeo), `grabar_erebo_hibrida` (l. 45 y la de la invocación) y `medir_erebo_teatro` (l. 19). Topes de 120 s
  (turno de Lya) y 180-300 s (invocación o vídeo; holgados por el Movie Maker). Al agotarse: FALLO, «FALLOS: 1», la opción
  en «no» y salida 1. `medir_erebo_teatro` no cargaba desde `661c1c5` («Too few arguments for "_combate()"»): ahora
  `_combate(9)`, el de antes; mide **19,69 s**, lo mismo que `EREBO_CINEMATICA_V12.md`.
- Con ventana o a mano: `fotos_mc_oasis`, `fotos_mc_rincon`, `fotos_rincones_pastos` (con ventana, «120 s» en
  fotogramas eran 25 s a 144 Hz), `fotos_bosque`, `fotos_claro_guardian`; y `medir_isla`, `medir_muestra_calle`,
  `medir_barrio` y `grabar_mapamundi3d`, que ya esperaban 60 s por reloj pero al agotarse seguían en silencio.

Comprobaciones (registros en `D:\REBELUM_diagnostico\pruebas\<carpeta>`):

- Sin retraso, las 12 automáticas tocadas y `prueba_integridad`: 13 superadas, 0 fallidas (`2026-11-19_104755`).
- Herramientas de Érebo con el ejecutor (`D:\REBELUM_diagnostico\esperas_19_11\lista_erebo.txt`): `medir_erebo_teatro`,
  `grabar_erebo_transicion` y `grabar_erebo_hibrida` (sin Movie Maker) superadas; `fotos_erebo_hibrida` con ventana, 16
  capturas, MANUAL (`2026-11-19_104008`). Las demás herramientas tocadas, solo `--check-only` (sin errores).
- Contraprueba local (copias `zz_cp_*` con el tope a 0, sin commit y ya borradas; `lista_contraprueba.txt`): las 11
  acaban FALLIDAS por su propio «FALLO: …» y código 1, sin errores de script (`2026-11-19_104151`). Excepción:
  `grabar_erebo_hibrida` cortada a MITAD de la híbrida sale con 0xC0000005 (con ventana y sin ella, también saliendo sin
  liberar nada); el FALLO ya está escrito y el código es distinto de 0. `fotos_erebo_hibrida` cortada igual sale con 1.
  No se ha investigado ese cierre (es del juego, opción de Auditoría apagada). **Resuelto en HIBRIDA_SALIDA_19_11**
  (`HIBRIDA_SALIDA_19_11.md`): era la función anónima `al_resultado` en la pila de `invocar()` (estática), colgada al
  salir; ahora espera en el nodo de la invocación y la misma contraprueba sale con 1 (5 de 5, con ventana y sin ella).

Barrido con `REBELUM_RETRASO_CARGA_MS` (el parche de arriba, solo en la copia de trabajo, sin commit y quitado;
`recursos.gd` limpio; diff en `D:\REBELUM_diagnostico\esperas_19_11\retraso_contraprueba_recursos.diff`):

| Pasada | Pruebas | Retraso | Resultado | Cargas retrasadas |
|---|---|---|---|---|
| `2026-11-19_105002` | las 12 automáticas tocadas | 1500 ms | 12 superadas, 0 fallidas | 6, en 5 pruebas |
| `2026-11-19_105138` | las 12 automáticas tocadas | 4000 ms | 12 superadas, 0 fallidas | 6, en 5 pruebas |
| `2026-11-19_105335` | otras 14 automáticas que nombran «cambiando» | 4000 ms | 14 superadas, 0 fallidas | 47, en 10 pruebas |
| `2026-11-19_105909` | las 13 restantes de esas 39 | 4000 ms | 13 superadas, 0 fallidas | 24, en 6 pruebas |

Las 7 tocadas sin cargas retrasadas solo usan `change_scene_to_file` (síncrono): el retraso no las alcanza. En todas
las pasadas, partida real, carpeta real de datos y proyecto sin cambios y ningún otro Godot abierto.

Sigue pendiente (PC-10 no queda cerrado del todo): *(19/11: los tres primeros puntos, hechos en «KAEL_ESPERAS_19_11», al final; `prueba_salir_en_cambio` se deja así a propósito)*

- Herramientas de medida con tope GLOBAL en fotogramas que, al agotarse, escriben la medida a medias sin FALLO:
  `medir_garganta3d.gd:191` y `medir_ruta.gd:164` (20000; el combate de `_encuentro`, l. 169 y 140, va en hilo),
  `medir_primeras_veces.gd:258` (20000; `R.cambiar_escena`, l. 114) y `medir_escenas.gd:232` (30000).
  `sonda_oclusion_repetida.gd:120` (3000, carga síncrona) sale con 1 pero escribe «TIEMPO AGOTADO», no «FALLO».
- `medir_ciudad.gd:616` (`_esperar_banco`, 30 s de reloj) y `diag_ciudad_romper.gd:723` (15 s) siguen en silencio al
  agotarse; `medir_memoria_escenas` y `recorrido_ciudad` esperan por reloj (`_pulsar`), sin revisar qué hacen al agotarse.
- Fuera de los 46: `prueba_erebo_video.gd:296` y `:370` y `prueba_erebo_hibrida.gd:168` (3000 fotogramas hasta el turno
  de Lya, tiempo de juego; quien llama comprueba el turno) y `prueba_salir_en_cambio.gd:34` (900, a propósito: el primer
  fotograma con la carga en curso).
- El barrido no cubre la batería entera (211 automáticas), solo las 39 que nombran «cambiando», ni las pruebas con
  ventana, ni un retraso mayor que el tope de las esperas.

## KAEL_ESPERAS_19_11 (PC-10, lo que quedaba de la lista de arriba)

Solo pruebas y herramientas; el juego no se toca. Esperas por fotogramas pasadas a **reloj** (`Time.get_ticks_msec`) con
un «FALLO: …», «FALLOS: n» y salida 1 al agotarse; cuando no se agotan, miden lo mismo:

| Archivo | Antes | Ahora |
|---|---|---|
| `medir_garganta3d.gd`, `medir_ruta.gd`, `medir_primeras_veces.gd` | 20000 fotogramas en total y, al agotarse, escribía la medida a medias como buena | 300 s de reloj en total; al agotarse, FALLO con la fase (o pasada y paso) y salida 1, sin escribir la medida |
| `medir_escenas.gd` | 30000 fotogramas, «MEDIDA: se acaba el tiempo» y la medida a medias | 600 s de reloj, igual que las anteriores |
| `sonda_oclusion_repetida.gd` | 3000 fotogramas, «TIEMPO AGOTADO» | 300 s de reloj, «FALLO: …» y «FALLOS: 1» |
| `medir_ciudad.gd` | `_esperar_banco` (30 s de reloj) seguía en silencio; `_terminar` salía con 0 aunque hubiera FALLO | `_esperar_banco` devuelve si el banco está; si no, FALLO y se termina (o `_volver_al_banco` da false); cada línea «FALLO…» cuenta, «FALLOS: n» al final del registro y salida 1 |
| `diag_ciudad_romper.gd` | la espera tras «Salir del banco» (15 s) seguía en silencio | FALLO y cuenta en `fallos` (sale con 1 por `recorrido_ciudad._terminar`) |
| `prueba_erebo_video.gd` | turno de Lya (`_combate`) y vuelta de la invocación (`_invocar`): 3000 fotogramas | 120 s y 180 s de reloj (`TOPE_TURNO_LYA_MS`, `TOPE_VUELTA_INVOCACION_MS`); el turno agotado da su FALLO; la vuelta ya lo daba (`colgado`), ahora con el tope en el texto |
| `prueba_erebo_hibrida.gd` | turno de Lya: 3000 fotogramas; `_invocar_sin_video` invocaba sin mirar si era el turno de Lya | 120 s de reloj con FALLO; sin el turno, `_invocar_sin_video` no invoca (antes, error de script en `combate._mostrar_menu`) |
| `prueba_veta_garganta.gd` | 60 s por paso, sin tope global (el ejecutor corta a 180 s) | además, 150 s de reloj para toda la prueba, con FALLO |

`prueba_salir_en_cambio.gd:34` (900 fotogramas, a propósito) no se toca. Las subclases de las dos de Érebo
(`medir_erebo_teatro`, `grabar_erebo_*`, `prueba_erebo_*_fallo`, `diag_salir_hibrida`) cargan sin errores
(`--check-only`); los nombres de los topes nuevos no chocan con los suyos. **Hallazgo aparte, sin tocar:**
`fotos_erebo_video.gd:44` no carga («Too few arguments for "_combate()"», como `medir_erebo_teatro` antes de `709e03a`).

Comprobaciones (`D:\REBELUM_diagnostico\kael_esperas_19_11\` y `D:\REBELUM_diagnostico\pruebas\<carpeta>`):
- **Mismo resultado con el tope normal.** Antes (`2026-11-19_173649`, el código de antes) y después
  (`2026-11-19_173859` y `2026-11-19_174519`): `prueba_erebo_video`, `prueba_erebo_video_fallo`, `prueba_erebo_hibrida`,
  `prueba_erebo_hibrida_fallo` y `prueba_veta_garganta`, superadas y con el registro **idéntico byte a byte**;
  `prueba_integridad` superada. Herramientas, antes y después (`esperas\antes_*`, `esperas\despues_*`,
  `esperas\comparar_json.txt`, `esperas\cmp_escenas.txt`): `medir_ruta` (bajo, con grupo) con las mismas fases y los
  mismos fotogramas por fase salvo `entrada_combate` (338 y 348: la carga del combate va en hilo y dura lo que dura,
  2,25 y 2,30 s); `medir_escenas` (pastos, medio, 2 ciclos) con las mismas fases, fotogramas, dibujos y primitivas
  (en `reposo#1`, 327560 y 327568); los tiempos por fotograma cambian lo normal entre pasadas.
- **Contraprueba** (copias locales `zz_cp_*` con el tope a 0, sin commit y ya borradas;
  `lista_contraprueba_b.txt`; `2026-11-19_174256`, `2026-11-19_174333` y `2026-11-19_174446`): las 11 acaban FALLIDAS
  por su propio «FALLO: …» y código 1, sin errores de script. La de `diag_ciudad_romper` va directa a «Salir del banco»
  y su texto dice «15 s» aunque la copia espere 0. Para la vuelta de la invocación de `prueba_erebo_video` hay una copia
  aparte (`zz_cp_prueba_erebo_video_inv`). La primera copia de la híbrida dio dos errores de script (invocar sin el turno
  de Lya); con la guarda de `_invocar_sin_video`, ninguno.

Sigue sin revisar: `medir_memoria_escenas` y `recorrido_ciudad` (esperan por reloj en `_pulsar`); el barrido con
retraso de carga sigue sin cubrir la batería entera ni las pruebas con ventana.
