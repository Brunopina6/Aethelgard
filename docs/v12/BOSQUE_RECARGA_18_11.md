# prueba_bosque_pastos: «8: la región no vuelve a cargarse» (18/11)

Rama `area-bosque-recarga`, desde `3f37c9a`. Registros en `D:\REBELUM_diagnostico\pendientes_18_11\bosque_recarga\`.

## El fallo

En la batería completa del 18/11 a las 01:59 (`D:\REBELUM_diagnostico\pruebas\2026-11-18_015954\`),
`prueba_bosque_pastos` falló con «FALLO: 8: la región no vuelve a cargarse» tras 69,6 s (lo normal son unos 10 s).
Sola pasaba. Ya había fallado así el 15/11; los commits `5e8e097` y `cbc0536` pusieron la espera de la recarga por
reloj (60 s), pensando que la región solo tardaba en cargarse.

## Causa real: la prueba pedía la región con el cambio al combate aún en curso

Es un fallo de la prueba, no del juego. El paso 8 hacía esto:

1. Tras el diálogo del Guardián, la región llama a `Recursos.cambiar_escena("res://combate.tscn")`, que carga el
   combate en segundo plano (`load_threaded_request`) y, ya montado, funde el negro en 0,3 s. Mientras dura,
   `R.cambiando` vale `true`.
2. La prueba esperaba a que terminara con `_hasta(not R.cambiando, 30.0)`, que cuenta **fotogramas**:
   30 s × 30 = 900 fotogramas. Con `--fixed-fps 30` en modo sin ventana, los fotogramas no esperan al reloj: 900
   fotogramas pasan en unos 1,5-3 s reales.
3. Si la carga del combate tardaba más que esos 900 fotogramas (un PC cargado), la prueba seguía y llamaba a
   `R.cambiar_escena(REGION)` **con el cambio al combate aún en marcha**. `cambiar_escena` ignora lo que se le pide
   mientras cambia (`if cambiando: return`, a propósito: evita dobles peticiones; `prueba_cargas` lo comprueba).
4. El combate terminaba de montarse, `R.cambiando` volvía a `false` y nadie volvía a pedir la región. La espera por
   reloj de 60 s se agotaba: 60 s de más, justo la diferencia entre los ~10 s normales y los 69,6 s del fallo.

La espera por reloj del 15/11 se puso en la espera equivocada: la de **después** de pedir la región. La que se
quedaba corta era la de **antes**, la del combate.

### Pruebas que lo demuestran

- **El registro de la batería del 18/11 ya lo decía**: cada montaje de la región imprime las animaciones de los tres
  héroes con la línea `[calidad] pastos_verdes_3d.tscn` en medio; el combate, las mismas tres sin esa línea. En las
  pasadas buenas salen región + combate + región (14 líneas). En la fallida, región + combate y nada más (11 líneas):
  la región nunca se volvió a montar.
- **El margen era muy pequeño**: con el volcado nuevo, en pasadas buenas sin carga la prueba pedía la región a los
  752, 817 y 863 fotogramas (1,3-1,4 s reales) de los 900 posibles más los del primer `_hasta`.
- **Reproducido con carga de CPU** (14 procesos de PowerShell en bucle, 14 hilos lógicos; ningún Godot más):
  con la prueba sin arreglar falló **3 de 9** veces (`2026-11-18_024112` y, en `sin_arreglo_estres\`, dos de seis),
  con 77-79 s y este volcado:

  ```
  VOLCADO 8 (al pedir la región): 1704 ms reales y 900 fotogramas desde el combate del Guardián ·
    R.cambiando=true · texto_carga=«Preparando el combate» · negro=true · escena=res://zonas3d/pastos_verdes_3d.tscn…
  FALLO: 8: la región no vuelve a cargarse
  VOLCADO 8 (tras la espera): 61709 ms reales y 36529 fotogramas … R.cambiando=false · escena=res://combate.tscn…
  ```

  En uno de los fallos el combate ya estaba montado pero aún en el fundido (`escena=res://combate.tscn`,
  `R.cambiando=true`): la misma carrera, en su último tramo.

### Hipótesis descartadas

- **Carga colgada**: no. Tras la espera, `R.cambiando=false`, el combate montado y ninguna carga en hilo pendiente
  (región y combate con estado 0, sin precargas).
- **Algo que deja la prueba anterior**: no. Cada prueba es un proceso de Godot propio; la secuencia de la batería
  (de `prueba_guardado_fallos` a `prueba_tienda_bosque`, 15 pruebas) pasó 2 de 2 sin carga. Lo que importa es la
  carga del PC, no el orden.
- **Cambios entre `e8ed88f` y `3f37c9a`** (ciudad de Oakhaven, cara de los héroes v3, Recursos): no cambian la carga
  del combate de Pastos Verdes; el fallo ya había salido el 15/11, antes de todos ellos.
- **La escena vieja con el mismo id**: no es la causa, pero había un defecto en la comprobación. `id_vieja` se tomaba
  después del combate, con la región ya liberada, y `get_instance_id()` devolvía 0: la condición
  «otra instancia» no comparaba nada. Ahora se toma antes del combate, con la región viva.

## Arreglo (solo en la prueba)

`aethelgard/pruebas/prueba_bosque_pastos.gd`, paso 8:

- se espera **por reloj** (`_hasta_reloj`, 60 s) a que termine el cambio al combate antes de pedir la región;
- si a los 60 s el cambio sigue en curso, falla con un mensaje propio («el cambio al combate sigue en curso tras 60 s:
  la región se pediría y se ignoraría») y el volcado, en vez de esperar otro minuto a ciegas;
- `id_vieja` se toma con la región viva;
- volcado `_estado_8` (commit aparte): si la recarga falla, imprime el estado al pedir la región y tras la espera
  (`R.cambiando`, aviso de carga, negro, escena actual con ruta e id, lo que cuelga de `root`, estado de las cargas en
  hilo de la región, del combate y de las precargas de Recursos, ms reales y fotogramas desde el combate).

### Por qué no afecta al jugador

En el juego nadie pide la vuelta a la región mientras se carga el combate: la pide el propio combate al acabar, cuando
lleva mucho tiempo montado. Que `cambiar_escena` ignore una petición mientras cambia es lo que se quiere (dos toques
seguidos no deben montar dos escenas). La carga del combate no se cuelga: solo tarda más con el PC ocupado.

## Contraprueba

Con la misma carga de CPU (14 procesos en bucle) y la prueba arreglada, imprimiendo provisionalmente el volcado en
cada pasada (`con_arreglo_estres\`): **8 de 8 superadas**, y en 4 de ellas la región se pidió a los 923, 926, 1378 y
1404 fotogramas, más allá de los 900 de antes: con la espera vieja esas cuatro habrían fallado.

| Prueba (con carga de CPU) | Pasadas | Fallos |
|---|---|---|
| sin arreglo (`94fc963`, solo el volcado) | 9 | 3 |
| con arreglo | 8 (+6 sin volcado) | 0 |

No hay una contraprueba determinista: probé a ocupar los hilos del `WorkerThreadPool` desde la prueba, pero la carga
en hilo de Godot usa un hilo propio, y gastar CPU dentro de Godot frena más el hilo principal que la carga (salen
menos fotogramas, no más). La carga externa sí lo reproduce, aunque no siempre.

## Comprobaciones

`-Solo prueba_bosque_pastos,prueba_guardian_bosque,prueba_tienda_bosque,prueba_cargas,prueba_banco_pruebas`:
5 de 5 superadas (`regresion\2026-11-18_030150`). No se ejecutó la batería completa: el fallo se reprodujo y se
explicó sin ella.

## Pendiente

- Otros 46 archivos de `pruebas/` esperan a `not R.cambiando` (o `Recursos.cambiando`); no he revisado cuáles cuentan
  fotogramas en vez de reloj. Si alguna pide otra escena
  justo después, puede tener la misma carrera con el PC cargado. No se han tocado; conviene revisarlas si fallan de
  forma intermitente en baterías (el patrón: unos 60 s de más o «no vuelve», con la escena anterior todavía montada).
