# V12 · Prueba en el Redmi (11/11/2026, 13:45-14:25)

**APK:** «REBELUM Auditoría» (`com.aethelgard.auditoria`), versionCode **581**, del commit **`42d79d9`** (rama LOCAL
`claude/rebelum-v12`). `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261111-42d79d9.apk`, 283,6 MB, SHA-256
`8c11a6e3f69acec1b0afe70123afebd69a5e2254605d7801b3ae9bf67c74791a`. Firma v2 y v3, un firmante, el **mismo certificado**
que la v542 instalada (`3413edcd…7785f3`). Lleva recursos con licencia pendiente: **no se distribuye** (ni GitHub).

**Antes de instalar:**
- **Batería en `42d79d9`:** 110 superadas · 0 fallidas · 44 manuales · 0 no seguras. Partida real, carpeta de datos
  y proyecto sin cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_133539\resumen.md`.
- **Respaldo de la partida de Auditoría:** `D:\REBELUM_respaldos\2026-11-11_redmi_auditoria_antes_v12` (la carpeta
  `files/` entera, 513 archivos; los 7 de su raíz con el mismo SHA-256 en el teléfono y en el PC).

**Instalación:** `adb install -r` a la primera, sin confirmación de MIUI. Las otras apps siguen igual: estable v1, Exp
v365 y Prueba 3D v24 (mismas versiones y fechas). Al acabar, la partida, su `.bak` y los ajustes de la Auditoría se
restauraron desde el respaldo (mismo SHA-256). No quedan archivos temporales en el teléfono.

**Cómo se probó:** por USB, solo en la app de Auditoría, con partidas editadas en cada punto de la misión
(`D:\REBELUM_diagnostico\v12\redmi\partidas`). Toques con `input tap`, capturas en `D:\REBELUM_diagnostico\v12\redmi\sesion`
y FPS con las estadísticas de SurfaceFlinger (`--timestats`: 10 s, media e histograma de tiempos entre fotogramas). En
este Android 16, `--latency` ya no da datos.

## 1. Rendimiento real en Android

FPS a los 22 s de entrar, en el punto de inicio de cada región, sin moverse. Bajo y medio tienen un tope de 30 FPS y
el alto, de 60. Memoria: PSS total de la app.

| Región | Bajo | Medio | Alto | Memoria (bajo · medio · alto) |
|---|---|---|---|---|
| **Mar de Cristal** (campamento) | **30,3** (p95 33 ms) | **30,4** (p95 33) | **23,3** (p95 50) | 745 · 774 · 865 MB |
| Pastos Verdes | 30,3 (p95 33) | 30,4 (p95 33) | 13,4 (p95 86) | 796 · 809 · 948 MB |
| Garganta 3D | 30,4 (p95 33) | 30,2 (p95 50) | 12,8 (p95 86) | 770 · 805 · 933 MB |
| Oakhaven 3D | 30,3 (p95 33) | 30,3 (p95 33) | 15,4 (p95 86) | 773 · 835 · 944 MB |

- **Tormenta de arena** (medio, en el cobijo): 30,4 FPS (p95 33).
- **Combate con Bramavidrio** (medio): **62,4 FPS** (p95 16).
- **Ningún fotograma perdido** en ninguna medida.
- **El Mar de Cristal es la región 3D más ligera:** la que menos memoria usa y la única con el alto por encima de 20 FPS.
- **El perfil alto no se puede jugar en el Redmi** en las otras regiones (13-15 FPS). La detección automática ya
  elige el bajo.
- **Arranque:**
  - 2,1 s hasta la primera imagen (`am start -W`);
  - la carga del juego tarda de 15,2 a 15,8 s (788 archivos, 0 fallos), así que «TOCA PARA EMPEZAR» sale a unos 19 s;
  - tras un cierre forzado, 1,4 s hasta la primera imagen y la misma carga.
- **Entrada en el Mar de Cristal:** a los 9 s de tocar ya estaba dentro, con el aviso de Bramavidrio (captura
  `bv_03_t9`). No se midió al fotograma.
- **Cierres:** las 16 salidas de la app en la sesión fueron cierres forzados míos. Ningún cierre inesperado, ningún
  «no responde» y ningún cierre por falta de memoria; el búfer de cierres está vacío y no hay errores de script.

## 2. Funciones (comprobado en el teléfono)

| Prueba | Resultado |
|---|---|
| Entrada en el Mar de Cristal (partida guardada dentro) | **bien**, en bajo, medio y alto |
| Bramavidrio | **bien**: aviso «La arena tiembla…», surco junto a Kael, aparición y combate (60 FPS) |
| Tormenta y cobijo | **bien**: diálogo de la tormenta con retratos; amaina en el cobijo; la partida guarda `mc_tormenta` y `mc_ruinas` |
| Buscador | **bien**: botón, barra (5 de 7) y «Algo hay cerca (y suena raro)»; GUARDAR y MEJORAR |
| Excavación | **bien**: encima de la llave sale «Una llave de vidrio…»; la partida guarda `mc_llave`, la llave y que está desenterrada |
| Trampilla, mural y Oren | **bien**: la tapa gira en su bisagra, el mural («¿Y esta señora?…») y `mc_superviviente` guardado |
| Final y recompensa | **bien**: `mc_fin`, 318 monedas (168 + 150), la Aguja de Resonancia, el buscador de nivel 2 y de Kael; Oren junto a Ismena |
| Guardado, cierre y recuperación | **bien**: tras un cierre forzado vuelve al campamento con el buscador, Oren y la misión |
| Andar tocando el suelo | **bien** (sin vibraciones ni saltos) |
| Salida al mapa | **no comprobada en el teléfono**: sin señal en el suelo no se encontró a ciegas (problema 1). En el PC funciona desde la entrada (158 fotogramas hasta el mapa) |

## 3. Problemas que hay que arreglar antes de seguir

1. **(Alta) La salida del Mar de Cristal no está señalizada y se ve el borde del mundo.**
   - La Garganta marca su salida con un círculo y «Mapa del mundo»; el desierto, nada.
   - Al sur y al este, más allá de la arena, se ve una franja blanca vacía.
   - Arreglo: el mismo marcador que la Garganta y dunas o bruma más allá del borde.
2. **(Alta) SEGUIR y el botón de acción se solapan** (abajo a la derecha). Al acabar un diálogo, el siguiente toque
   en SEGUIR pulsa «Hablar con la cartógrafa» y vuelve a abrir la conversación.
   - Arreglo: más espera tras un diálogo (hoy 0,4 s) o separar los botones.
3. **(Media) Bramavidrio en el combate:**
   - su barra de vida y su nombre salen cortados por arriba (`barra_y`);
   - el montón de arena de la foto parece un plato;
   - no se puede huir (es de tipo jefe): decidir si debe poderse.
4. **(Media) La tormenta de la misión puede amainar con su propio diálogo abierto:** el tiempo en el cobijo corre
   también durante los diálogos.
5. **(Media) El perfil bajo del desierto se ve más lavado y rosado en el teléfono que en el PC.**
   - Revisar en el Redmi el `brillo_sin_sombras` de 1,3 (probar 1,15-1,2), con capturas.
6. **(Baja) El cobijo queda rodeado de rocas grandes que tapan la vista.**
7. **(Baja) La salida se arma solo a más de 3,0 m exactos.** Una partida guardada justo a 3 m no podía salir.
8. **(Baja) Licencias:** la comprobación de la APK da como «origen sin registrar» `modelos/desierto/*` (Blender, de
   gráficos) y `enemigos/bramavidrio/bramavidrio.png` (render propio). Hay que registrarlos en `docs/recursos.md`.

## 4. No comprobado en el teléfono

- Entrar en el Mar de Arena desde el mapa (llegar al lugar 4 andando).
- El sonido: nadie ha escuchado los volúmenes del desierto.
- La tormenta sistémica (tras la misión).
- La misión seguida de principio a fin sin partidas editadas.
- Temperatura y batería en sesiones largas.
- Mando y teclado reales.

# V12 · Segunda prueba en el Redmi: v597 (11/11, 18:40-19:30)

**APK:** «REBELUM Auditoría», versionCode **597**, del commit **`a9317a3`**. Archivo
`D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261111-a9317a3.apk`, 292,4 MB, SHA-256
`5dee787dd7040bf2c1135d85459af49ec36344578f98900955c955a10c3fb75f`. Firma v2 y v3 con el mismo certificado que la v581.
Lleva la fase 1, el Bramavidrio de Blender con sus tres ataques y la pantalla de inicio alternativa (desactivada por
defecto).

- **Batería en `a9317a3`:** 114 superadas · 0 fallidas · 47 manuales · 0 no seguras.
- **Respaldo de la partida de Auditoría:** `D:\REBELUM_respaldos\2026-11-11_redmi_auditoria_antes_v597`, íntegro.
- **Instalación:** `adb install -r` a la primera. Las otras apps no cambian (estable v1, Exp v365, Prueba 3D v24).
- **Al acabar:** la partida, su `.bak` y los ajustes se restauraron idénticos al respaldo.

## Rendimiento: v597 frente a v581

| Medida | v581 | v597 |
|---|---|---|
| Mar de Cristal, bajo | 30,3 FPS · 745 MB | **30,4** · 745 MB |
| Mar de Cristal, medio | 30,4 · 774 MB | **30,4** · 761 MB |
| Mar de Cristal, alto | 23,3 (p95 50) · 865 MB | **23,6** (p95 50) · 908 MB |
| Combate con Bramavidrio (medio) | 62,4 (foto 2D) | **56,7-57,9** (modelo 3D; p95 33 ms) · 814 MB |
| Pantalla de inicio | original: 30,4 · 749 MB | alternativa: **35,9-36,8** (p95 33) · 791 MB |
| Carga hasta «empezar» | 15,2-15,8 s | original 15,4-15,6 s · alternativa 14,1 s |

- Ningún fotograma perdido en ninguna medida.
- Sin errores de script y sin cierres inesperados: el búfer de cierres está vacío.
- **El modelo 3D de Bramavidrio cuesta unos 5 FPS en el combate** (de 62 a 57); sigue muy por encima de 30.
- **La pantalla alternativa cuesta unos 42 MB más**, sin pérdida de fluidez.

## Comprobado en el teléfono

| Prueba | Resultado |
|---|---|
| Salida señalada | **bien**: disco, «Mapa del mundo» y postes bien visibles; tocar el disco lleva al mapa |
| Franja blanca del borde | **arreglada**: dunas lejanas al sur |
| Bramavidrio en exploración | **bien**: aviso y aparición, combate obligatorio |
| Combate con el modelo 3D | **bien**: ocupa media pantalla e impone; vida «PV 1150/1150» visible entera; HUIR dice «Bramavidrio cierra el paso»; la Embestida alcanza (Lya a 19/86); recibe daño (925/1150) |
| Pantalla alternativa | **bien**: se ve como en el PC; accesos de pruebas en Auditoría; «Continuar» entra en la partida |

## Sigue pendiente

- **El perfil bajo del desierto sigue algo lavado y con bruma en el teléfono.** Con brillo 1,15 mejora poco frente a
  la v581. Probar 1,0 con más contraste, o menos bruma en el bajo, y medirlo en el teléfono.
- **La Fractura y el Aliento no se cazaron en el teléfono.** Con toques a ciegas no llegué a verlos; están comprobados en
  el PC por `prueba_bramavidrio_combate` y sus capturas. Nadie ha escuchado el combate.
- **Rendimiento de los ataques especiales** en el teléfono (sus partículas): sin medir.
- **Bramavidrio:**
  - el vientre de frente aún flojo;
  - los héroes se dibujan sobre el gusano caído;
  - sin sonidos propios de succión, chorro y caída.
- **Pantalla alternativa:** sin escuchar; Créditos, todavía una pantalla provisional.

# V12 · Tercera prueba en el Redmi: v607, el clímax de los grandes jefes (11/11, 18:58-19:10)

**APK:** «REBELUM Auditoría», versionCode **607**, del commit **`b7daacc`**. 301,8 MB, SHA-256
`f99aba25913f1935282c50025491ef0868bc071e9c7da9470e446a7b55e2f7b9`, el mismo certificado. Lleva las tres canciones de Suno
Pro y el clímax con Bramavidrio. Publicada en el repositorio privado `Brunopina6/Aethelgard-pruebas` («11/11/2026 ·
Prueba v607», etiqueta `exp-20261111-b7daacc`).

- **Respaldo:** `D:\REBELUM_respaldos\2026-11-11_redmi_auditoria_antes_climax`, íntegro.
- **Instalación:** `adb install -r` la canceló MIUI (`INSTALL_FAILED_USER_RESTRICTED`: nadie aceptó en el teléfono).
  La APK se copió a Descargas (SHA-256 comprobado) y el usuario la instaló a mano. Después se borró de Descargas.
- **Partidas de prueba:** `mc7_gusano_fuerte.save` (la de `mc7_gusano` con fuerza 45, vitalidad 40 y defensa 25 para
  llegar al 20 % en pocos turnos) y `cmp_pastos.save`, con `ajustes_v607.cfg` (medio y «Pastoral Pulse»). En
  `D:\REBELUM_diagnostico\v12\redmi\partidas`.
- **Los argumentos de pruebas no llegan en Android:** `--esa command_line_params` no tuvo efecto (sin `auto` ni
  `nivel=`). Por eso se reforzaron los héroes en la partida.
- **Al acabar:** partida, `.bak` y ajustes restaurados idénticos al respaldo. La Exp sigue en la v365. Sin cierres y
  sin errores de script en logcat.

| Medida (medio) | v597 | v607 |
|---|---|---|
| Pantalla de inicio con «When the World Forgets» | 35,9-36,8 FPS · 791 MB | **36,8** · 762 MB |
| Carga hasta «empezar» | 14,1 s | **14,4-14,7 s** |
| Combate con Bramavidrio | 56,7-57,9 | **55-56** antes del clímax |
| **Combate durante el clímax** (10 s) | — | **57,2 FPS**, 0 perdidos · 896 MB |
| Pastos Verdes con «Pastoral Pulse» | 30,4 · 809 MB (v581, sin música) | **30,4** · 828 MB |

Capturas en `D:\REBELUM_diagnostico\v12\redmi\sesion_v607`.

| Prueba | Resultado |
|---|---|
| Clímax | **bien**: el golpe de Kael lo deja en 213/1134 (18,8 %). Al acabar el golpe sale «¡Momento decisivo!» (`h3`). El contador baja a 45 FPS solo en ese instante, por el velo |
| Una sola vez | **bien**: con más golpes no se repite |
| Victoria | **bien**: el combate acaba normal («Kael aprende Llamarada»), sin errores |
| Fractura del Mar de Cristal | **vista por fin en el teléfono** (`d3`): aviso, grietas rojas bajo Garon y «Fractura: defendeos» |
| Pastos con «Pastoral Pulse» | **bien**: entra sin fallos de carga |

**Pequeño defecto visual:** en el teléfono, «¡Momento decisivo!» toca el borde izquierdo del menú de órdenes («—
ATACAR»). Se centra en los 1280 px de la pantalla, pero el menú ocupa el 40 % derecho. Arreglo: centrarlo en el campo de
batalla, a la izquierda.

**Sin comprobar:** no se ha escuchado nada (el teléfono mezcla todo en una sola pista, así que no se puede saber por
`dumpsys` qué canción suena). Falta oír el volumen del clímax frente a los avisos y los empalmes de los bucles.
