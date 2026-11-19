# CIERRES_19_11 (AM-11 y PC-21): los cierres de Godot con 0xC0000005 al apagar

Fecha: 19/11/2026. Rama `claude/rebelum-v12`, Godot 4.7.2 (consola). Registros, lanzadores, copias de antes y
comparaciones en `D:\REBELUM_diagnostico\cierres_19_11\` (fuera del repositorio): `resumen.txt` (una línea por pasada
con su `rc`), `logs\` (cada `.log` acaba en `rc=<código>`), `banco_antes\resumen.txt`, `banco_antes_carga\resumen.txt`,
`bat_antes\`, `bat_despues\`, `contraprueba\`, `comparar.txt`, `comparar_ruido.txt` y `capturas\`. Todas las pasadas
con APPDATA, LOCALAPPDATA, TEMP y TMP en una carpeta temporal (lanzador propio o el ejecutor, datos aislados). En Git
Bash, `rc=139` es el 0xC0000005 de Windows; el ejecutor lo da como «código de salida -1073741819».

Antecedentes: `HIBRIDA_SALIDA_19_11.md` (la causa demostrada en la híbrida de Érebo y en el ataque v12 de los héroes:
una función ESTÁTICA que espera a un método de un nodo con una función anónima de otro guion en su pila).

## 1. AM-11: el cierre intermitente tras `prueba_banco_pruebas`

### Cuántas veces ocurre ahora

| Medida | Pasadas | 0xC0000005 |
|---|---|---|
| Historial del ejecutor (`D:\REBELUM_diagnostico\pruebas\*\resumen.csv`), `prueba_banco_pruebas`, hasta el 16/11 14:49 | 96 | **4** (15/11 02:40, 19:35 y 21:48; 16/11 14:49) |
| Lo mismo desde el 16/11 14:49 hasta hoy | 36 | 0 |
| Historial, `prueba_banco_pruebas_3d` (todas) | 69 | 0 |
| Hoy, ejecutor con `-Solo prueba_banco_pruebas,prueba_banco_pruebas_3d`, 20 pasadas seguidas | 20 + 20 | **0** (40 de 40 con código 0) |
| Hoy, lo mismo con el PC cargado (12 procesos ocupando una CPU cada uno, de 14), 10 pasadas | 10 + 10 | **0** (20 de 20 con código 0; la prueba tarda 41 s en vez de 31) |

**No se reproduce**: 0 en 30 + 30 pasadas de hoy y 0 en las 36 + 16 del ejecutor desde el 16/11 por la tarde. Antes
salía 4 de 96 (≈ 4 %): con esa frecuencia, 30 pasadas sin ninguna tienen una probabilidad de ≈ 0,3 si nada hubiera
cambiado; las 66 seguidas sin ninguna (36 + 30), ≈ 0,07. Es un indicio de que ya no ocurre, no una prueba.

### ¿Es el mismo mecanismo (estática + anónima en la pila)?

Por inspección, **probablemente no** (no demostrado con instrumentación):

- En todo el proyecto solo hay `await` dentro de funciones estáticas en 13 guiones (208 líneas): `combate_anim_v12.gd`,
  `invocacion_erebo_hibrida.gd`, `invocacion_erebo_video.gd` y los diez de los enemigos v12 (`combate_gorthor.gd`,
  `combate_golem.gd`, `combate_peon.gd`, `combate_velador.gd`, `combate_velaria.gd`, `combate_centinela.gd`,
  `combate_cencerrante.gd`, `combate_humbaba.gd`, `combate_meshy_e01.gd`, `combate_vidracran.gd`).
- `prueba_banco_pruebas` no invoca a Érebo, ningún héroe ataca (no hay animación v12 de héroes) y cada combate se
  cierra 4 + 4 fotogramas después de abrirse, sin turnos de enemigos, salvo el de Garon (grupo 0, enemigos de siempre),
  donde la prueba espera cada `_turno_enemigo` hasta el final. Al salir no queda ninguna de esas estáticas a medias.
- Además, ese mecanismo es determinista (en el caso mínimo y en la híbrida, siempre 0xC0000005), y AM-11 era
  intermitente.

La otra hipótesis (los recursos retenidos por cachés estáticas que se liberan sin los servidores de render y texto:
`MUESTRA_CALLE_OAKHAVEN.md` §8, `pruebas/diag_cierre_banco.gd`) **sigue sin demostrar**: sin reproducir el cierre no se
puede comparar con y sin vaciarlas. Al salir hoy siguen vivos, en `prueba_banco_pruebas`, 420 objetos y 151 recursos
(«Pages in use exist at exit in PagedAllocator» incluido) y, en `prueba_banco_pruebas_3d`, 6 objetos.

**No se ha cambiado nada del juego por AM-11.** Queda abierto, sin causa: si vuelve a salir en la batería, repetir la
pasada que falle con `--verbose` y comparar `prueba_banco_pruebas` con `diag_cierre_banco` en ese mismo PC y momento.

## 2. PC-21: los golpes de los enemigos v12

### Casos mínimos nuevos (`aethelgard/pruebas/herramientas/diag_estatica_lambda.gd`, 3 pasadas cada uno)

| Caso | Qué hay pendiente al salir (forma de) | Resultado |
|---|---|---|
| `cadena_lambda`, `otra_clase` (controles) | los de `HIBRIDA_SALIDA_19_11.md` | 139, 3 de 3 cada uno |
| `metodo_ligado` (control) | a la estática le llega un método ligado | 0, 3 de 3 |
| `envuelta` | la estática envuelve la anónima de A en una suya («golpe») y la pasa al método esperado de otro nodo (Gólem, Peón, Velador, Centinela, Velaria, Cencerrante, Gorthor, Custodio) | 0, 3 de 3 |
| `anidada` | la pasa tal cual a otra estática que la envuelve (Humbaba: `animar_golpe` → `_atacar`) | 0, 3 de 3 |
| `propia_arg` | solo una anónima de la propia estática, como argumento del método esperado | 0, 3 de 3 |
| `a_padre` | la estática espera a un método de A (quien la llamó) pasándole la anónima de A (Vidracrán, pinzas: `c._anim_zarzalin(o, obj, impacto, …)`) | **139, 3 de 3** |
| `envuelta_ligado`, `anidada_ligado`, `a_padre_ligado` | las mismas con un método de A ligado a una clave en vez de la anónima (el arreglo) | 0, 3 de 3 cada uno |

### Arreglo (`aethelgard/combate.gd`)

En `_animar_golpe`, las diez ramas de los enemigos v12 pasan `_ligar(impacto)` en vez de `impacto`. `_ligar` guarda
la anónima en `_impactos` (un diccionario del nodo del combate) y devuelve `_impacto_guardado.bind(clave)`, que la llama.
Así a ninguna estática le llega una anónima de `combate.gd` (la forma `metodo_ligado`); la anónima vive en el nodo y se
va con él. Se llama igual y las veces que la llamen; no se borra al acabar el golpe (alguna estática podría llamarla
después, p. ej. con un proyectil en el aire), y son unas pocas por combate. Bramavidrio no cambia (su `animar_golpe`
es un método de su nodo, no una estática). Nada de los guiones de los enemigos cambia.

### Antes y después en el juego (`aethelgard/pruebas/herramientas/diag_salir_hibrida.gd fase=golpe_enemigo:…`)

El diagnóstico se ha ampliado: dice qué estática le toca al enemigo (mismo orden que `_animar_golpe`), y con el arreglo
comprueba que de verdad pasa por ella (un `impacto` guardado nuevo en `c._impactos`, que se envuelve para apuntar desde
qué guiones se llama al llegar el golpe: `Engine.capture_script_backtraces`). `fase=golpe_enemigo:impacto+N` sale N
fotogramas después de que el golpe quite PV a Kael; `ene:clave=valor` elige el ataque; al Custodio se le pone su
`e01_ataque` (sin él, su `animar_golpe` daba el golpe al momento sin pasar por su 3D: así se midió en
`HIBRIDA_SALIDA_19_11.md`, que no llegó a cubrirlo).

13 variantes: Gorthor (Hoguera, grupo 5), Gólem (puñetazo y terrón, 20), Peón (22), Velador (25), Guardián de piedra
(Centinela, 18), Velaria (30), Humbaba (17), Vidracrán (pinzas y aguijón, 14), Custodio (Prensa y Portón, 28) y
Cencerrante (32, que no se había medido). Sin ventana.

| Medida | Antes (`combate.gd` de HEAD) | Después |
|---|---|---|
| `golpe_enemigo:10` y `golpe_enemigo:impacto+20` | 0 en 30 de 30 (12 variantes × 2, con el Custodio aún sin su ataque; + Prensa y Portón × 2; + 2 del Vidracrán) | **0 en 26 de 26** (13 × 2) |
| `golpe_enemigo:impacto+20` con `--fixed-fps 30` | 0 en 13 de 13 | **0 en 13 de 13** |
| Fotograma del impacto con `--fixed-fps 30` | 19, 39, 33, 38, 50, 42, 33, 45, 31, 32, 46, 40, 34 | **los mismos, 13 de 13** |
| ¿Pasa por su estática? | la rama sí («DIAG estatica combate_<x>.gd» en 13 de 13) | sí, 13 de 13: el golpe llega desde la anónima de `combate_<x>.gd` (el Vidracrán con pinzas, desde `combate.gd` `_anim_zarzalin`, adonde lo manda su estática) |

**En el juego, antes del arreglo, ningún enemigo v12 se ha cerrado con 0xC0000005** (0 en 43 pasadas hoy; 0 en 33 de
`HIBRIDA_SALIDA_19_11`). El arreglo es preventivo: lo que lo sostiene es el caso mínimo (`a_padre`, la forma del
Vidracrán con pinzas, y `otra_clase`: 139 siempre; con el método ligado, 0). Por qué en el juego no falla (el orden en
que Godot descarga los guiones, que no está garantizado) no se ha medido.

### Que no cambia nada de lo que se ve ni de lo que pasa

- Pruebas de los enemigos, antes (HEAD puesto un momento) y después, en el ejecutor: superadas todas, antes y después.
  Registros (`comparar.txt`, quitando los milisegundos de las líneas «TRAZA»): **idénticos** en
  `prueba_cencerrante_combate`, `prueba_centinela_v12` (700 líneas), `prueba_encuentro_desierto`, `prueba_golem_v12`,
  `prueba_gorthor_v12` (967), `prueba_humbaba_combate`, `prueba_meshy_e01` y `prueba_velaria_combate`. Distintos en
  `prueba_peon_v12`, `prueba_velador_v12` y `prueba_vida_enemigos_solape`, pero lo son igual entre dos pasadas con el
  código de HEAD (la batería de las 14:20 y la de «antes» de esta tarea: 240, 230 y 80 líneas; `comparar_ruido.txt`: el
  caso D del Peón elige grupos al azar; las posiciones de los Slime varían en décimas). `prueba_patrones_enemigos`
  apunta del Gólem (el de siempre, sin `enemigos_v12`, que no pasa por aquí) «golpe 1» o «golpe 2» según la pasada:
  después, 1, 1 y 2 en tres pasadas; antes, 1.
- Capturas con ventana y `--fixed-fps 30`, 20 fotogramas después del impacto (Gólem, Velaria, Humbaba, Vidracrán,
  Custodio y Cencerrante; `capturas\`): **no se puede demostrar píxel a píxel**, porque la escena no es igual entre dos
  pasadas del MISMO código (brasas, bordes de los modelos, el brillo de las barras ATB y la cifra de FPS): después contra
  después, 1,5-5,6 % de píxeles distintos; antes contra después, 1,9-7,7 % (`dif_*.png`). Lo que sí es idéntico es el
  fotograma del impacto (arriba) y los registros deterministas. (Revisión: con una sola captura de antes, «en los mismos
  sitios» no estaba demostrado; con la referencia de antes contra antes y 4 + 4 capturas, ver la sección 6.)

## 3. Prueba nueva: `prueba_salir_a_mitad` (batería, `lista_pruebas.txt`)

`aethelgard/pruebas/prueba_salir_a_mitad.gd`. El cierre ocurre en el apagado, después del último `print`: la prueba
lanza un Godot HIJO por caso con `diag_salir_hibrida.gd` (sin ventana, con `--log-file` en `user://`, tope de 150 s) y
comprueba su código de salida (0), que llegó al punto de salida y que no dejó errores de script:

- `hibrida_mano`: la híbrida de Érebo en «mano»;
- `ataque_v12`: el ataque v12 de Lya, 30 fotogramas después de empezar («v12 true»);
- `golpe_v12`: el golpe del Vidracrán, 10 fotogramas después, y que ese golpe guardó un `impacto` nuevo en
  `combate.gd` (`_ligar`: «impacto guardado nuevo [» seguido de una cifra; desde la revisión, sección 6);
- y, sin lanzar hijos (desde la revisión), en el texto de `combate.gd`: que la llamada a la estática `animar_golpe` de
  cada uno de los diez enemigos v12 pasa `_ligar(impacto)`. El código de salida no vigila PC-21 (sin el arreglo ya
  salía con 0): lo vigilan estas dos comprobaciones.

| Pasada (ejecutor) | Resultado |
|---|---|
| Con todo (`bateria\2026-11-19_160232`, `bat_despues\2026-11-19_162225`) | SUPERADA (30 s), dos veces |
| Con `invocacion_erebo_hibrida.gd` de `208ea8b~1` y `combate_anim_v12.gd` de `1ee5644~1` puestos un momento (`contraprueba\2026-11-19_160320`) | **FALLIDA**: «hibrida_mano: código de salida -1073741819», «ataque_v12: código de salida -1073741819» |
| Con `combate.gd` de HEAD (`bat_antes\2026-11-19_161057`) | **FALLIDA**: «golpe_v12: el hijo no llegó a «DIAG estatica combate_vidracran.gd · impacto guardado nuevo»» (los dos primeros, 0); falló solo porque ese archivo no tenía `_impactos` (ver la sección 6) |

Los archivos de antes se devolvieron después de cada pasada (`git status` sin cambios en ellos).

## 4. Pruebas de la zona (después, ejecutor, datos aislados, proyecto sin cambios durante la pasada, ningún otro Godot)

- `bat_despues\2026-11-19_161544`: `prueba_centinela_v12`, `prueba_golem_v12`, `prueba_gorthor_v12`,
  `prueba_peon_v12`: 4 superadas, 0 fallidas.
- `bat_despues\2026-11-19_162225`: `prueba_integridad`, `prueba_banco_pruebas`, `prueba_banco_pruebas_3d`,
  `prueba_erebo_hibrida`, `prueba_combate_anim_v12`, `prueba_vida_enemigos_solape`, `prueba_velador_v12`,
  `prueba_velaria_combate`, `prueba_cencerrante_combate`, `prueba_humbaba_combate`, `prueba_encuentro_desierto`,
  `prueba_meshy_e01`, `prueba_patrones_enemigos`, `prueba_salir_a_mitad`: 14 superadas, 0 fallidas.

## 5. Lo que queda

- AM-11: abierto y sin causa; no se reproduce hoy (0 en 60) ni desde el 16/11 por la tarde. No se ha tocado el juego.
- Por qué en el juego no se cierran los enemigos v12 sin el arreglo, cuando el caso mínimo de su forma sí: sin medir.
- `invocacion_erebo_video.gd` `reproducir` es estática y espera a señales del árbol y de tweens (la forma
  `estatica_sola` del caso mínimo: 0; el vídeo del ritual, 0 en 7 de 7 en `HIBRIDA_SALIDA_19_11`): no se ha cambiado.
- El clic real en la X de la ventana sigue sin hacerse (se simula con `antes=cerrar_ventana`).
- Android: nada de esto cambia allí (los interruptores siguen apagados; Atrás no cierra el juego).
- Al generar el `.uid` de la prueba nueva (`--import`), Godot creó también los de `pruebas/herramientas/salir_en_precarga.gd`,
  `prueba_ajustes_parcial.gd`, `prueba_pestanas.gd`, `prueba_salir_en_cambio.gd` y `prueba_salir_en_precarga.gd`, que
  están en el repositorio sin el suyo; se han borrado (no son de esta tarea). Lo decide el coordinador.

## 6. Revisión (CIERRES_19_11_REVISION)

Medidas en `D:\REBELUM_diagnostico\cierres_19_11_revision\` (datos aislados; `git status` igual antes y después de cada
pasada; ningún Godot abierto al acabar).

**`prueba_salir_a_mitad` vigilaba PC-21 de forma débil (media).** Aceptaba «impacto guardado nuevo []»: con la rama del
Vidracrán de `_animar_golpe` devuelta a `impacto` (y `_ligar` en el archivo), la prueba de `463f68d` daba **SUPERADA**
(`pruebas\2026-11-19_164239`: «golpe_v12: código de salida 0 … impacto guardado nuevo [] …», «FALLOS: 0»). Ahora:

- el registro del hijo tiene que cumplir «impacto guardado nuevo \[\d» (una clave de verdad);
- y, en el texto de `combate.gd`, cada una de las diez llamadas `await <Enemigo>.animar_golpe(` (Humbaba, Vidracrán,
  Centinela, Gólem, Gorthor, Peón, Velador, Custodio, Velaria, Cencerrante) tiene que ser única y pasar `_ligar(impacto)`.

| `combate.gd` (prueba nueva) | Resultado |
|---|---|
| Rama del Vidracrán devuelta a `impacto` (`2026-11-19_164401`) | **FALLIDA**: «combate.gd: Vidracran.animar_golpe no recibe «_ligar(impacto)» (PC-21)» y «golpe_v12: el registro no cumple «… impacto guardado nuevo \[\d»» |
| Rama del Gólem devuelta a `impacto` (`2026-11-19_164436`) | **FALLIDA**: «combate.gd: Golem.animar_golpe no recibe «_ligar(impacto)» (PC-21)» (el hijo, «impacto guardado nuevo [0]») |
| El de HEAD (`2026-11-19_165111`) | SUPERADA: «ligados en combate.gd: 10 de 10», «golpe_v12: código de salida 0 … impacto guardado nuevo [0]» |

La comprobación de los diez es de texto: demuestra que las diez ramas pasan `_ligar`, no que cada enemigo pase por su
estática en ese momento (eso lo demostró la traza «DIAG impacto desde» de la sección 2, a mano).

**Tope de los hijos (baja).** `TOPE_MS` pasa de 150 s a 100 s: 3 × 100 s queda por debajo de los 450 s de la lista, y la
prueba siempre cierra a su hijo antes de que el ejecutor la cierre a ella. Hoy cada hijo tarda 7-13 s.

**Capturas (baja).** Faltaba la referencia de antes contra antes. Con `combate.gd` de `HEAD~1` se sacaron más capturas
de antes (las seis, y del Gólem, el Vidracrán y el Cencerrante, 4 de antes y 4 de después en total), con la misma orden
(`capturas.sh`, ventana, `--fixed-fps 30`, 20 fotogramas después del impacto). Medida: píxeles con algún canal que
difiere más de 0,1 (`comparar_4x4_*.txt`, `comparar_capturas.txt`):

| Enemigo | antes-antes (6 parejas) | después-después (6) | antes-después (16) |
|---|---|---|---|
| Gólem | 1,47-3,86 % (media 2,68) | 1,20-3,65 % (2,50) | 0,75-3,78 % (2,32) |
| Vidracrán | 1,07-1,57 % (1,29) | 0,89-1,70 % (1,21) | 0,52-1,70 % (1,17) |
| Cencerrante | 0,67-1,62 % (1,18) | 0,53-1,30 % (0,95) | 0,27-1,48 % (1,00) |

Con 2 + 2 capturas (Velaria, Humbaba, Custodio), antes contra después cae dentro de lo que varían dos pasadas del mismo
código, o en el borde (Humbaba: antes-antes 3,16 %, después-después 1,66 %, antes-después 1,99-2,46 %; Custodio: 1,40 y
0,61 %, antes-después 0,94-1,17 %; Velaria: 1,37 y 1,32 %, antes-después 0,93-1,39 %). El fotograma del impacto
es idéntico en las capturas nuevas (31 a 46 según el enemigo, igual que antes). Demostrado: la diferencia antes-después
no se distingue del ruido de la escena en estas medidas. No demostrado: igualdad píxel a píxel (la escena no la permite).

**`_impactos` sin vaciar (baja): no se cambia.** El nodo del combate se crea de nuevo en cada combate y el diccionario se
va con él; vaciarlo al terminar no libera antes nada y obligaría a que `_impacto_guardado` tolerase una clave ya borrada
(un proyectil en el aire). Queda como estaba, documentado.

**`.gd.uid` de cinco guiones ajenos (baja): no es de esta tarea**, sigue para el coordinador (sección 5).

Pruebas después (ejecutor, `pruebas\2026-11-19_165111`): `prueba_integridad`, `prueba_salir_a_mitad`,
`prueba_erebo_hibrida`, `prueba_combate_anim_v12`, `prueba_encuentro_desierto`: 5 superadas, 0 fallidas; «proyecto: sin
cambios · otros Godot: 0». El juego (`combate.gd` y los enemigos) no cambia en esta revisión.
