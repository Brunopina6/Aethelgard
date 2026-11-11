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
