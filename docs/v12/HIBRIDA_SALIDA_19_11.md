# HIBRIDA_SALIDA_19_11 (PC-19): el cierre con 0xC0000005 al salir a mitad de la híbrida

Fecha: 19/11/2026. Rama `claude/rebelum-v12`, Godot 4.7.2 (consola), sin ventana salvo donde se dice. Registros,
lanzador y copias en `D:\REBELUM_diagnostico\hibrida_salida_19_11\` (fuera del repositorio). Todas las pasadas con
APPDATA, LOCALAPPDATA, TEMP y TMP en una carpeta temporal nueva por pasada (o con el ejecutor, datos aislados).
En Git Bash, «rc=139» es el 0xC0000005 de Windows (comprobado con PowerShell: `ExitCode -1073741819`).

## Causa (demostrada)

`invocacion_erebo_hibrida.gd` `invocar()` es una función **estática** que espera (`await`) a `inv.dirigir(...)`, un
método del nodo de la invocación, y lleva en su pila `al_resultado`, una **función anónima** de `combate.gd`
(`_invocar_sobre`). Si el juego sale a mitad, esa espera no vuelve nunca: liberar los nodos no la suelta (es estática,
no es de ninguna instancia) y queda colgada hasta que Godot descarga los scripts al cerrar. Entonces vacía su pila y
destruye la función anónima cuando el código de `combate.gd` ya está descargado: 0xC0000005.

Caso mínimo sin nada del juego (`aethelgard/pruebas/herramientas/diag_estatica_lambda.gd`, 3 pasadas cada caso):

| Caso | Qué hay pendiente al salir | Resultado |
|---|---|---|
| `cadena_lambda` | método de A → estática con anónima → método de B (hijo) que espera `process_frame` | **139, 3 de 3** |
| `sin_captura`, `sin_self` | igual, con `func(): print("x")` o `func(): pass` | **139, 3 de 3** |
| `cadena` | igual, sin anónima (`Callable()`) | 0, 3 de 3 |
| `a_miembro` | igual, pero la función del medio NO es estática | 0, 3 de 3 |
| `estatica_sola` | estática con anónima que espera al árbol (`process_frame`, un temporizador), no a B | 0, 3 de 3 |
| `ligado` | estática con `print.bind("y")` (no anónima) | 0, 3 de 3 |
| `nada`, `miembro`, `estatica` | controles | 0, 3 de 3 |
| `guardada` | **el arreglo**: la anónima se guarda en B y la pila de la estática queda sin ella | 0, 3 de 3 |
| `senal` | alternativa: la estática espera una señal de B en vez de su método | 0, 3 de 3 |

## Bisección en el juego (`aethelgard/pruebas/herramientas/diag_salir_hibrida.gd`)

Combate de verdad (Kael y Lya, grupo 9), Lya invoca y se sale con `quit(0)`; antes del arreglo:

- Por fase: `senalar` (el primer fotograma), `medida`, `objetivo`, `aparece`, `acercamiento`, `mano`, `agarra`: 139
  siempre (3 de 3 en `senalar`, `mano` y `agarra`); `hibrida_breve` y `hibrida_3d` en `mano`: 139 (2 de 2).
  En el vídeo del ritual (`ritual_video`, `video_arranca` y 30 fotogramas después): 0 (7 de 7).
- Por modo, 2 y 30 fotogramas después de invocar: teatro de siempre (`no`) y vídeo (`abreviada`): 0; `hibrida` e
  `hibrida_3d`: 139. Sin invocar (menú de Lya): 0.
- Liberando antes de salir (la híbrida con `free()` o `queue_free()`, o el combate entero, y 5 fotogramas; **n = 1**
  pasada por variante, sin el rc guardado en el registro: el lanzador solo lo escribía en la consola): 139 igual.
  Indicio (no medida repetida) de que no es un nodo, ni el vídeo, ni el teatro, ni sombras, ni hilos; lo que sostiene
  la causa es el caso mínimo de arriba, sin nada del juego.
- Por piezas, llamando sin `combate._invocar_sobre`: el tween de la música, `_senalar`, `_montar_escenario`,
  `dirigir` y hasta `H.invocar` con una anónima del propio diagnóstico: 0. Solo falla con la anónima de `combate.gd`
  en la pila de la estática (`_invocar_sobre` → `invocar` → `dirigir`), lo que llevó al caso mínimo.
- `--verbose`: el registro bueno sigue tras el `quit` con «XR: Clearing primary interface» (limpieza de Godot); el
  malo se corta antes, sin traza ni error de script.

Por qué el vídeo del ritual no falla: **no se ha medido**. Hipótesis sin medir: en esa fase la espera de `dirigir`
queda colgada de otra forma y Godot suelta antes la de la estática. No cambia el arreglo.

## Arreglo (`aethelgard/invocacion_erebo_hibrida.gd`, 7 líneas)

En `invocar()`, justo antes del `await inv.dirigir(...)`: `inv._resultado_combate = al_resultado` y
`al_resultado = Callable()`; después del `await`, `al_resultado = inv._resultado_combate`. Variable nueva
`_resultado_combate` (no `_al_resultado`, que es de `invocacion_base.gd` y la usa `saltar()`: aplicaría el resultado
dos veces). Tras el `await` no hay más esperas: se llama una vez, como antes. No cambia el orden, el dado, el ATB, el
resultado ni nada de lo que se ve; la función anónima vive en el nodo y se va con él al liberarse el árbol.

## Antes y después

| Medida | Antes | Después |
|---|---|---|
| `diag_salir_hibrida` `fase=senalar / mano / agarra` (3 cada una) | 139, 9 de 9 | **0, 9 de 9** |
| `hibrida_breve` y `hibrida_3d` en `mano` (2 cada uno) | 139, 4 de 4 | **0, 4 de 4** |
| `video_arranca` (3) | 0 | 0 |
| contraprueba de PC-10: copia `zz_cp_grabar_erebo_hibrida` (tope de la invocación a 0), sin ventana (3) | 139, 3 de 3 | **1, 3 de 3** (su «FALLO: …») |
| la misma con ventana (2) | 139, 2 de 2 | **1, 2 de 2** |

La copia `zz_cp_*` se hizo para medir y se borró (sin commit). El «antes» de la contraprueba se midió con el archivo de
`HEAD` puesto un momento en la copia de trabajo y devuelto después.

Pruebas con el arreglo (ejecutor, datos aislados, proyecto sin cambios, ningún otro Godot):

- `2026-11-19_122648`: `prueba_integridad`, `prueba_erebo_saltar`, `prueba_erebo_video`, `prueba_erebo_video_fallo`,
  `prueba_erebo_hibrida` (37,2 s), `prueba_erebo_hibrida_fallo`: 6 superadas, 0 fallidas.
- `2026-11-19_122838`: `grabar_erebo_hibrida` entera (sin Movie Maker): superada; sus líneas «GRAB» (fases y
  segundos, música −18 dB y vuelta a 0 dB, PV 110 → 0) **idénticas** a las de `2026-11-19_104008` (antes).
- `grabar_erebo_hibrida saltar=agarra` (2 pasadas): 0, «saltada en «agarra»», PV 110 → 0.

## ¿Llega el juego normal a este camino?

No con la opción apagada. La híbrida solo corre si `H.activa()`: con `permitido()` (rasgo `auditoria` o el editor)
y el valor del selector en Ajustes, o con `erebo_cine=` en la línea de órdenes (Android no la tiene). En Android,
Atrás no cierra el juego (`quit_on_go_back=false`; en el combate va a `_atras()`), y pasar a segundo plano no ejecuta
la salida (si el sistema mata el proceso, no se descarga nada). En PC, cerrar la ventana a mitad de la híbrida con la
opción encendida (Auditoría) sí era este camino: queda cubierto por el arreglo.

El mismo patrón (estática que espera a un método de un nodo con una anónima en la pila) está en `combate_anim_v12.gd`
(`ataque_kael`, `ataque_lya`, `ataque_garon`, `magia`: `impacto`) y en las animaciones estáticas de los enemigos v12
(`combate_gorthor.gd`, `combate_golem.gd`, `combate_peon.gd`, `combate_velador.gd`, `combate_velaria.gd`,
`combate_centinela.gd`, `combate_cencerrante.gd`, `combate_humbaba.gd`, `combate_meshy_e01.gd`, `combate_vidracran.gd`:
`animar_golpe(..., impacto)`). Todos van detrás de interruptores APAGADOS por defecto. Lo que pasa con cada uno, en la
revisión de abajo.

## Revisión (HIBRIDA_SALIDA_19_11_REVISION, 19/11)

Registros, lanzador, copias de antes y comparaciones en `D:\REBELUM_diagnostico\hibrida_salida_19_11_revision_aplicada\`.
El lanzador nuevo (`lanzar.sh`) escribe `rc=<código>` al final de cada `.log` y una línea por pasada en `resumen.txt`:
las cifras de esta sección se pueden revisar con los archivos (el de la primera tanda solo lo dejaba en la consola).

### Casos mínimos nuevos (`diag_estatica_lambda.gd`, 3 pasadas cada uno)

| Caso | Qué hay pendiente al salir | Resultado |
|---|---|---|
| `cadena_lambda` (control) | el de siempre | 139, 3 de 3 |
| `guardada` (control) | el arreglo de la híbrida | 0, 3 de 3 |
| `guardada_arg` | como `guardada`, pero la estática pasa `inv._cb` como **argumento** del método esperado | **139, 3 de 3** |
| `guardada_campo` | como `guardada`, y el método del nodo **lee** la anónima del nodo | 0, 3 de 3 |
| `otra_clase` | la estática espera a un nodo de **otro** script (como los enemigos v12, que esperan al modelo 3D) | **139, 3 de 3** |
| `propia` | la anónima es de la propia estática; nadie le pasa ninguna | 0, 3 de 3 |
| `metodo_ligado` | a la estática le llega un método de A ligado a una clave (`_llamar_pendiente.bind(0)`), no la anónima | 0, 3 de 3 |

Consecuencias: (1) vaciar la variable no basta si después se pasa la anónima como argumento de la llamada esperada: la
copia temporal se queda en la pila de la estática (`guardada_arg`); el nodo tiene que leerla él (`guardada_campo`).
(2) Que la estática espere a un nodo de otro script no la libra (`otra_clase`): el riesgo de los enemigos v12 existe en
el caso mínimo, aunque en el juego no se ha visto (abajo).

### `combate_anim_v12.gd`: arreglado

Con `heroes_v2 combate_anim_v12`, `diag_salir_hibrida.gd fase=ataque:N` (el ataque de Lya v12 a medias; el registro
dice «v12 true»):

| Medida | Antes (archivo de `HEAD` puesto un momento) | Después |
|---|---|---|
| `ataque:10`, `ataque:30`, `ataque:60`, sin ventana | **139, 8 de 8** (2 + 4 + 2) | **0, 10 de 10** (3 + 5 + 2) |
| `ataque:30` con ventana y `antes=cerrar_ventana` | **139, 2 de 2** | **0, 2 de 2** |

Arreglo: las cuatro estáticas guardan `impacto` en el nodo (`_impacto`), vacían la suya y esperan a `d_ataque_kael`,
`d_ataque_lya`, `d_ataque_garon` o `d_magia`, que la toman del nodo (`_tomar_impacto()`, en la misma llamada, antes de
la primera espera) y llaman a los `i_*` de siempre con ella. Mismo orden (`_accion`, la acción, `_fin_accion`) y mismos
instantes. `prueba_combate_anim_v12` antes y después (ejecutor): por defecto superada y superada; `esgrima=Juicio`
superada y superada; `magia=Fuego` FALLIDA y FALLIDA con el mismo «FALLO: encendido: el pie de Garon patina (146 px por
acción; apagado 195; …)», que ya estaba en `HEAD` (no es de este cambio y no está en la batería). En las tres, los
registros de antes y después tienen las mismas líneas de impacto, duraciones (fotogramas animando) y fotogramas por
pasada; solo cambian en ±1 la mediana en px/s o los px en vertical de algún pie, que también cambian en la pasada
APAGADA (donde este código no corre): ruido de la medida. Comparación en `comparar.txt`.

### Enemigos v12: medidos, sin cambios

`diag_salir_hibrida.gd fase=golpe_enemigo:N` (golpe del primer enemigo a Kael, cortado a N fotogramas), sin ventana:

| Enemigo (interruptor, grupo) | Pasadas | Resultado |
|---|---|---|
| Gorthor, Hoguera (`enemigos_v12 gt_ataque`, 5; «hoguera true») | 10, 20 (2), 40 | 0, 4 de 4 |
| Gólem (`enemigos_v12`, 20), Peón (22), Velador (25), «Guardián de piedra» (18) | 10, 20, 40 | 0, 3 de 3 cada uno |
| Velaria (`velaria_v12`, 30), Humbaba (`humbaba_v12`, 17), Vidracrán (`encuentro_desierto_v12`, 14), Custodio (`meshy_e01`, 28) | 10, 20, 40 | 0, 3 de 3 cada uno |

Ninguno se ha cerrado con 0xC0000005 en el juego (28 de 28 con 0, más los 5 de 5 de Gorthor de la primera tanda), pero
el caso mínimo `otra_clase` dice que el mecanismo les alcanza; el orden en que Godot descarga los scripts no está
garantizado. Salvo Gorthor, el registro no comprueba que cada uno vaya por su `animar_golpe` estático (el combate
lo elige por su `es()`/`de_ella()`/`de_el()` con el interruptor puesto). No se ha medido el Cencerrante (sin grupo de
prueba propio). No se han cambiado: la cadena de estáticas de cada uno (`animar_golpe` → `_ir_y_golpear`, `_lanzar`,
`_atacar`… → el modelo 3D) lleva `impacto` o anónimas que lo capturan en varias pilas, y arreglarlo enemigo por enemigo
no es un cambio pequeño. La forma segura medida en el caso mínimo es que a la estática no le llegue la anónima de
`combate.gd` sino un método ligado (`metodo_ligado`), por ejemplo en `combate.gd` `_animar_golpe`, solo en las ramas de
los enemigos v12; no hecho.

### Cierre de la ventana (WM_CLOSE_REQUEST)

`diag_salir_hibrida.gd antes=cerrar_ventana`: en lugar de `quit()`, la notificación `WM_CLOSE_REQUEST` a todos los nodos
y la señal `close_requested` de la raíz, con la que SceneTree sale solo (lo que hace Godot al cerrar la ventana con el
ratón). Híbrida en `mano`: antes (`HEAD~1` puesto un momento) **139, 4 de 4** (2 sin ventana y 2 con ella); después
**0, 4 de 4**. El ataque de Lya v12: arriba.

## Lo que queda

- Enemigos v12: antes de encender `enemigos_v12`, `velaria_v12`, `cencerrante_v12`, `humbaba_v12`,
  `encuentro_desierto_v12` o `meshy_e01` por defecto, quitar la anónima de las pilas estáticas (propuesta de arriba) o
  aceptar el riesgo medido (0 en 28 de 28 en el juego, 139 en el caso mínimo). Lo apunta el coordinador.
- Propuesta (no hecha): una prueba de la batería que salga a mitad de la híbrida (`diag_salir_hibrida.gd fase=mano`
  sale con 0 desde el arreglo; antes, 0xC0000005), como `prueba_salir_en_cambio`. Lo decide el coordinador.
- El clic real en la X de la ventana no se ha hecho (se ha simulado lo que Godot hace con él, arriba).
