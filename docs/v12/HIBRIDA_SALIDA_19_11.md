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
- Liberando antes de salir (la híbrida con `free()` o `queue_free()`, o el combate entero, y 5 fotogramas; 1 pasada cada una): 139 igual.
  No es un nodo, ni el vídeo, ni el teatro, ni sombras, ni hilos: con todo liberado sigue.
- Por piezas, llamando sin `combate._invocar_sobre`: el tween de la música, `_senalar`, `_montar_escenario`,
  `dirigir` y hasta `H.invocar` con una anónima del propio diagnóstico: 0. Solo falla con la anónima de `combate.gd`
  en la pila de la estática (`_invocar_sobre` → `invocar` → `dirigir`), lo que llevó al caso mínimo.
- `--verbose`: el registro bueno sigue tras el `quit` con «XR: Clearing primary interface» (limpieza de Godot); el
  malo se corta antes, sin traza ni error de script.

Por qué el vídeo del ritual no falla: no se ha medido en detalle (en esa fase la espera de `dirigir` queda colgada de
otra forma y Godot suelta antes la de la estática). No cambia el arreglo.

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
`animar_golpe(..., impacto)`). Todos van detrás de interruptores APAGADOS por defecto. Medido: la Hoguera de Gorthor v12
(`enemigos_v12`, `gt_ataque`, grupo 5) cortada a 10, 20 y 40 fotogramas: 0 (5 de 5); el ataque de Lya sin v12: 0 (6 de 6). No se
ha visto el cierre en ellos, pero el patrón es el mismo y el orden en que Godot descarga los scripts no está garantizado.

## Lo que queda

- Propuesta (no hecha): al encender cualquiera de esos interruptores, aplicar el mismo cambio (la anónima en el nodo,
  no en la pila de la estática) o medirlos con `diag_salir_hibrida.gd` (`golpe_enemigo:N`) antes.
- Propuesta (no hecha): una prueba de la batería que salga a mitad de la híbrida (`diag_salir_hibrida.gd fase=mano`
  sale con 0 desde el arreglo; antes, 0xC0000005), como `prueba_salir_en_cambio`. Lo decide el coordinador.
- No se ha probado el cierre de la ventana con el ratón (WM_CLOSE_REQUEST) en Auditoría; se ha probado `quit()` con
  ventana, que recorre la misma limpieza.
