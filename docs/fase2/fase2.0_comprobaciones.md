# Fase 2.0, preparación: comprobaciones

Fecha: 2026-11-07. Rama: `rebelum-3d` (local). Estado: **terminada; espera tu autorización para las fases 2.1 y 2.2**.

Lo que autorizaste: la copia recuperable, la rama local con un punto de recuperación, commits locales pequeños solo en `rebelum-3d` (indicando sus archivos) y compilaciones locales. Sin push, sin publicar, sin instalar herramientas, sin tocar la partida, y el bloque B queda aparte.

---

## 1. Copia recuperable (verificada)

Carpeta: `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0\` (1,9 GB). Su `LEEME.txt` explica cómo recuperar.

| Qué | Comprobación | Resultado |
|---|---|---|
| Copia completa del árbol de trabajo (`copia\`): `.git`, cambios sin confirmar y archivos ignorados (EmacE, arce…); sin la caché `.godot` | SHA-256 de cada archivo comparado con el manifiesto del original (`sha256sum -c`) | **4382 de 4382 archivos idénticos** (código 0) |
| Bundle con todas las ramas y etiquetas | `git bundle verify` | **Correcto**, historial completo |
| Partida del PC (`partida.save`), copiada solo para leerla | SHA-256 de la copia y del original | **Iguales**: `de2bbe37…3d17e` |
| Referencias y estado del repositorio en ese momento | `referencias_git.txt` y `estado_git.txt` | Guardados |

## 2. Punto de recuperación y rama

- **Etiqueta local anotada `recuperacion-antes-fase2.0`:** apunta a `2d1adc4`, que era `desarollo` antes de empezar.
- **Rama local `rebelum-3d`:** creada desde `desarollo`, en el mismo commit.
- **Sin push.** `main` (`d4b2d16`), `desarollo` (`2d1adc4`) y `v0.1.0` (`fd71d6a`) siguen igual, tanto en local como en GitHub.
- **Bloque B:** lo pendiente (el reflejo, la ronda 8 y los documentos de la Fase 1) sigue **sin confirmar** en el árbol de trabajo. No entra en ningún commit: cada commit se hizo nombrando sus archivos uno a uno.

## 3. Commits locales en `rebelum-3d`

| Commit | Qué hace | Archivos |
|---|---|---|
| `379122b` | Preset «Android experimental» (app aparte); la versión estable excluye `zonas3d/*` | `aethelgard/export_presets.cfg` |
| `475b155` | Compilación local del APK experimental, con comprobaciones; lista de licencias pendientes | `compilar_apk_experimental.ps1`, `docs/versiones/licencias_pendientes.txt` |
| `1063b98` | La exportación se hace en un entorno de datos aislado; se comprueba que el APK no lleva partidas ni claves y que los datos reales no cambian | `compilar_apk_experimental.ps1` |
| `ef3cbb3` | Ejecutor de pruebas en un entorno de datos aislado, con cuatro resultados, y sonda de aislamiento | `aethelgard/pruebas/ejecutar_pruebas.ps1`, `aethelgard/pruebas/lista_pruebas.txt`, `aethelgard/pruebas/sonda_datos.gd`, `aethelgard/pruebas/LEEME.md` |
| `d09ae1c` | Corrige una llamada recursiva del script de compilación. La función «Git» tapaba al propio git; falló en la primera comprobación, sin tocar nada | `compilar_apk_experimental.ps1` |
| (este) | Este informe | `docs/fase2/fase2.0_comprobaciones.md` |

## 4. App experimental, separada de la estable

| | App estable | App experimental |
|---|---|---|
| Nombre en el móvil | Aethelgard | **Aethelgard Exp** |
| Paquete | `com.aethelgard.juego` | **`com.aethelgard.experimental`** |
| Característica | — | `rebelum3d`; por ahora no cambia nada, porque la región 3D llega en la Fase 2.3 |
| Datos y partidas en Android | Los suyos | **Los suyos**: otro paquete, otra carpeta de datos |
| Exclusiones | `para_meshy`, `pruebas`, `prototipos`, `modelos`, `vegetacion_prueba` y `zonas3d` | Las mismas, salvo `zonas3d` |

**Aviso para la Fase 2.3:** en el PC, el editor usa la misma carpeta `user://` para los dos modos, porque el proyecto se llama igual. Por eso, cuando se active el modo 3D, su partida tendrá que ir en **otro archivo** (por ejemplo, `partida_exp.save`). Así la partida actual del PC no se toca nunca.

## 5. Pruebas: línea base, en un entorno de datos aislado

**Cómo se aíslan.**
- El ejecutor (`aethelgard/pruebas/ejecutar_pruebas.ps1`) lanza Godot con `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP` apuntando a carpetas propias de cada pasada.
- Antes de nada, la sonda (`sonda_datos.gd`) comprueba que `user://` cae dentro de la carpeta aislada. Si no, no se ejecuta ninguna prueba.
- Se compara la huella SHA-256 de **toda** la carpeta real de datos del juego (`%APPDATA%\Godot\app_userdata\Aethelgard`, 170 archivos, `partida.save` incluida) y el `git status` del proyecto, antes y después.
- Hace falta incluso para las pruebas que «no escriben»: solo con arrancar el juego, Dialogic escribe `user://dialogic/saves/global_info.txt` y Godot escribe sus registros en `user://logs/`.

**Pasada completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-07_033800\`, con `-Manual`), las 27 pruebas:

| Resultado | Cuántas | Cuáles |
|---|---|---|
| **SUPERADAS** | 15 | `huir`, `garon`, `dpad`, `toque`, `dialogo`, `cofre`, `choque`, `equilibrio`, `ia`, `menu_nuevo`, `tema`, `rio`, `posador`, `andar` y `guardado` (esta, dentro de la carpeta aislada) |
| **FALLIDAS** | 2 | `prueba_escenas` (error de script) y `prueba_menu_magia` (no termina en 150 s). Están explicadas abajo |
| **MANUALES** (necesitan a una persona) | 10 | Con capturas para revisar, todas sin errores: `sendero` (8), `vista3d` (6), `isla` (4), `garganta` (3), `agua3d` (2), `gorthor` (1), `lore` (1) y `tapa` (1). Sin ejecutar, porque necesitan a alguien: `material` (hay que elegir la base) y `banco` (se usa en el móvil, en la Fase 2.1) |
| **NO SEGURAS** | 0 | Con el aislamiento comprobado, ninguna lo es. `prueba_guardado` escribe en `user://partida.save`: el ejecutor solo la lanza si la sonda confirma el aislamiento; si no, sale como NO SEGURA |

**Comprobaciones de la pasada**

| Qué | Resultado |
|---|---|
| `partida.save` real (`de2bbe37…3d17e`) | Antes y después idéntica |
| Carpeta real de datos del juego (170 archivos) | Sin cambios |
| `git status` | Aparecía un cambio, pero era mi edición de `compilar_apk_experimental.ps1` durante la pasada. Una segunda pasada corta sin ediciones (`2026-11-07_034314`: `huir`, `guardado` y `sendero` con ventana) dio el proyecto **sin cambios** y código de salida 0. Las pruebas no crearon ni cambiaron ningún `.uid` ni `.import` |

**Las dos FALLIDAS ya fallaban antes de la Fase 2.0.**
- Se ejecutan sobre código del juego idéntico al de `desarollo`: los commits de esta fase no tocan ningún script del juego.
- `prueba_escenas`: llama a `_entrar()` en el mapa sin que el jugador esté junto a un lugar, así que no entra en la zona; después llama a `_salir()` sobre el mapa, que no tiene esa función (`SCRIPT ERROR: Nonexistent function '_salir' in base 'Node2D (mapa.gd)'`). La prueba no está al día con el mapa.
- `prueba_menu_magia`: espera el turno de Lya en combate (`prueba_menu_magia.gd:16`) y ese turno no llega, así que no termina. También se quedó colgada en la primera pasada.
- Revisarlas queda para una fase posterior, cuando se toquen el mapa o el combate.

**La primera pasada, que interrumpí.**
- La lancé antes de tu indicación sobre el aislamiento y la detuve en cuanto llegó. Las pruebas usaron entonces la carpeta real de datos.
- **No tocó la partida:** huella idéntica y fecha del 06/11, 11:43.
- **Escribió 5 registros de Godot** en `logs/` de esa carpeta. Por la rotación de Godot, que guarda 5 como máximo, se borraron los registros antiguos de `logs/`. No cambió ningún otro dato del juego (`dialogic`, `cache_zonas` ni `shader_cache`).
- Ahora el aislamiento lo impide.

## 6. APK experimental (compilación local)

Se compila con `compilar_apk_experimental.ps1`, en un entorno de datos aislado.

| Qué | Resultado |
|---|---|
| Archivo | `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-c66f29d.apk` (241,8 MB) |
| SHA-256 | `13a74f97d71947bd2fc8d8a4582d268594401c36d72805b0efef23d2566053ca` (también en el `.sha256`) |
| Identificador | **`com.aethelgard.experimental`**, distinto del de la estable (`com.aethelgard.juego`) |
| Nombre visible | Aethelgard Exp |
| Versión | `versionCode` 22, `versionName` `exp-20261107-c66f29d`: el commit `c66f29d`, sin cambios sin confirmar dentro |
| Firma | Verificada con apksigner. El mismo certificado de depuración que el APK estable del PC (`3413edcd…85f3`) |
| Carpetas excluidas | Ninguna dentro (`para_meshy`, `pruebas`, `prototipos`, `modelos` y `vegetacion_prueba`) |
| Partidas, claves, credenciales y ajustes del editor | Ninguno dentro |
| Carpeta real de datos del juego en el PC | Sin cambios: 170 archivos, `partida.save` incluida |
| `export_presets.cfg` | Restaurado idéntico tras exportar |
| Licencias | Lleva los personajes y las armas de Meshy, los 7 sonidos de Érebo y la música de combate, todos de origen sin registrar. Por eso es **NO DISTRIBUIR**: solo para tu móvil (aviso en `.NO_DISTRIBUIR.txt`) |
| Avisos de Godot | Solo «2 ObjectDB instances were leaked at exit», inofensivo al cerrar |

**La primera compilación** (`Aethelgard_exp-20261107-d09ae1c-local.apk`) tiene el mismo contenido. Su versión acababa en «-local» por un fallo del script, ya corregido en `c66f29d`: se tomaba por un cambio un archivo de `prototipos/`, carpeta que el preset excluye. Se puede borrar.

## 6.1 Comprobaciones finales que pediste

| Comprobación | Resultado |
|---|---|
| La APK usa un identificador distinto del de la estable | **Sí:** `com.aethelgard.experimental` frente a `com.aethelgard.juego` |
| No modifica ni comparte la partida estable | **Sí:** <ul><li>En Android, otro paquete tiene otra carpeta de datos y otra partida.</li><li>El APK no lleva ninguna partida dentro.</li><li>En el PC, las pruebas y la exportación se hicieron aisladas: `partida.save` sigue con `de2bbe37…3d17e`.</li></ul> |
| Sin claves privadas, secretos ni recursos de licencia pendiente en los commits | **Sí.** En los commits de `rebelum-3d`: <ul><li>ninguna coincidencia de claves, tokens ni contraseñas;</li><li>ningún archivo de claves ni binario;</li><li>ningún modelo, sonido, textura ni recurso de licencia pendiente.</li></ul>Solo hay scripts, configuración y documentos (7 archivos) |
| `main`, `desarollo` y `v0.1.0` intactos | **Sí**, en local y en GitHub, iguales al registro anterior a la fase: `d4b2d16`, `2d1adc4` y `fd71d6a` |
| Todos los commits son locales y están en `rebelum-3d` | **Sí.** Cada commit está solo en `rebelum-3d`. La rama no tiene upstream ni existe en GitHub, y no se ha hecho ningún push |

## 6.2 Qué verás al abrir la APK en el Redmi

- **Se instala aparte.** Aparece como una app nueva, «Aethelgard Exp», junto a la estable. No la sustituye y no ve su partida.
- **Arranca en el juego 2D**, igual que la versión estable: pantalla de carga, «TOCA PARA EMPEZAR» y una **partida nueva** con el prólogo, el mapa 2D, las zonas 2D y los combates, con los personajes 3D del combate.
- **No lleva el prototipo de Pastos Verdes 3D.** La característica `rebelum3d` todavía no hace nada, porque la región 3D entra en la Fase 2.3, y el preset excluye `prototipos/`.
- **Para qué sirve:** comprobar que la app experimental se instala y convive con la estable, que es el criterio de la Fase 2.0.

## 7. Hallazgos

- **`prueba_guardado` escribe en `user://partida.save`.** Fuera del entorno aislado escribiría en la partida real del PC: la copia, la sustituye y la restaura al final, así que si falla a mitad la partida podría perderse. Ahora solo se ejecuta aislada. En la Fase 2.3, junto con la partida separada del modo 3D, conviene que use su propia ruta de prueba.
- **Casi todas las pruebas son «de humo».** Recorren el juego e imprimen datos, pero no deciden si algo está bien. El ejecutor marca como fallo los errores de script, el tiempo agotado y los fallos que declara la propia prueba. Cuando una fase toque una prueba, se le añadirá `quit(1)` para que dé un resultado propio.
- **Licencias.** Cualquier APK del juego lleva los personajes de Meshy, además de sonidos y música de origen sin registrar. Hasta verificarlos, **todo APK es solo para pruebas locales**; la lista está en `docs/versiones/licencias_pendientes.txt`. Los recursos de `vegetacion_prueba/` (EmacE) y de `modelos/` (árboles de Meshy) no entran en la app experimental.

## 8. Cómo volver atrás

- **Volver al estado de antes:** `git switch desarollo`. Los commits de la Fase 2.0 se quedan en `rebelum-3d` y no afectan a `desarollo`.
- **Borrar la rama:** si quieres descartarla del todo, solo con tu permiso.
- **Recuperar todo** (código, historial y partida): desde la copia de `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0\`, siguiendo su `LEEME.txt`.

## 9. Siguiente paso (espera tu autorización)

**Para probar Pastos Verdes 3D en el Redmi cuanto antes.** Queda fuera de la Fase 2.0, así que no se ha hecho nada.

- **Opción A, inmediata y sin tocar el juego.** Compilar en local el preset que ya existe, «Android prueba 3D» (`com.aethelgard.prueba3d`), que arranca directamente en el prototipo de Pastos Verdes 3D.
  - **Qué verás:** a Kael andando (toca para andar), la cámara elevada, el sendero, el puente, el río, la cascada, la vegetación con viento, los faroles y la fauna, con los botones de calidad (bajo, medio y alto) y del banco. No hay NPC, combate, menús ni guardado: eso es la alpha, en las fases 2.3 a 2.5.
  - **Qué hace falta:**
    - Un cambio pequeño en `compilar_apk_experimental.ps1` para poder elegir el preset, con las mismas comprobaciones y el entorno aislado.
    - Exportar ese preset.
  - **Avisos:**
    - Lleva el estado actual del prototipo, incluidos los cambios sin confirmar del bloque B (el reflejo apagado en bajo y medio). No hace falta confirmarlos.
    - Lleva recursos de licencia pendiente (EmacE en el perfil alto, y los árboles y el guardián de Meshy). Solo para tu móvil: NO DISTRIBUIR.
    - Es otra app («Aethelgard Prueba 3D»). Si ya la tienes de las rondas anteriores, se actualiza.
- **Opción B, la del plan.** Entrar en Pastos Verdes 3D desde la app experimental (título, partida nueva, región 3D), con NPC, encuentros, combate y guardado. Son las fases 2.1 → 2.2 → 2.3 → 2.4 → 2.5, cada una con tu autorización.

Después, las fases 2.1 (cierre del perfil bajo) y 2.2 (mando y foco), en paralelo, según `docs/plan_migracion_3d.md`.
