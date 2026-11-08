# Tareas terminadas: detalle archivado

Archivado el 08/11/2026 a las 23:00 desde `TASKS.md`, para que los documentos de inicio sean breves. En `TASKS.md`
queda una ficha de cada tarea con su título y el enlace a esta página. El texto se conserva tal cual.

### T-001
**Sistema de memoria y continuidad**
- **Estado:** terminada el 2026-11-07, sin confirmar en Git. **Decisión:** [D-047](DECISIONS.md#d-047).
- **Objetivo:** retomar el trabajo en cualquier conversación nueva sin depender de lo que recuerde el chat.
- **Dependencias:** ninguna.
- **Criterio de aceptación:**
  - Están los siete archivos de la raíz y `docs/memory/`, con enlaces y rutas válidos.
  - `git status` solo muestra documentos nuevos o cambiados.
  - No hay secretos.
  - `MEMORIA_CHAT.md` empieza con un resumen y un índice.
  - Hay una copia revisada del chat fuera del repositorio.
- **Evidencia** (comprobada el 2026-11-07 hacia las 16:10, sobre `ce84422`):
  - **Archivos nuevos, sin seguimiento:** `CLAUDE.md`, `PROJECT_CONTEXT.md`, `TASKS.md`, `DECISIONS.md`,
    `SESSION_HANDOFF.md`, `MEMORIA_CHAT.md`, `CONTINUAR_EN_NUEVO_CHAT.txt` y
    `docs/memory/historial_2026-10-30_a_2026-11-07.md`.
  - **Enlaces:** 224 relativos, sin fallos, incluidas las anclas. De las 72 rutas absolutas solo falta una, la del
    siguiente paso, que todavía no existe: `zonas3d\pastos_verdes_3d.gd`.
  - **Sin cambios en lo que ya existía:** `git diff` de los archivos con seguimiento es idéntico byte a byte a
    `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico\cambios_sin_confirmar.patch`.
  - **Sin datos sensibles:** ni el número de serie del móvil, ni correos, ni tokens.
  - **Copia revisada del chat:** `D:\REBELUM_respaldos\2026-11-07_chat_exportado\`.
- **Siguiente acción:** mantener los documentos al día en cada hito. Publicarlos es [T-002](#t-002).

### T-002
**Publicar la memoria en `memoria-desarrollo`**
- **Estado:** terminada el 2026-11-07, con la autorización de las 16:30 ([D-049](DECISIONS.md#d-049)). Se repite en cada
  hito.
- **Objetivo:** tener la memoria en GitHub para consultarla al empezar cualquier sesión.
- **Dependencias:** T-001.
- **Criterio de aceptación:**
  - La rama `memoria-desarrollo` de `Brunopina6/Aethelgard` contiene solo los documentos de memoria, revisados.
  - `git ls-remote origin refs/heads/memoria-desarrollo` devuelve su commit.
- **Evidencia:**
  - La rama sale de `desarollo` (`2d1adc4`), en la copia aparte `D:\Aethelgard_memoria`.
  - Los commits publicados se ven con `git log origin/memoria-desarrollo`, y el último, en
    [SESSION_HANDOFF.md](SESSION_HANDOFF.md).
- **Siguiente acción:** publicar tras cada hito, siguiendo el procedimiento de [CLAUDE.md](CLAUDE.md) §2.

### T-010
**Fase 2.0 del plan 3D: preparación segura**
- **Estado:** terminada. **Decisión:** [D-004](DECISIONS.md#d-004).
- **Evidencia:**
  - **Commits:** 9 locales en `rebelum-3d`, de `379122b` a `ce84422`. Nunca se han subido.
  - **Informe:** [docs/fase2/fase2.0_comprobaciones.md](docs/fase2/fase2.0_comprobaciones.md).
  - **Respaldo:** `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0`, con el paquete Git de todas las ramas, el manifiesto
    SHA-256 y la copia histórica de `partida.save`.
  - **Pruebas en `rebelum-3d`:** 15 superadas, 2 fallidas (eran fallos de las propias pruebas; se corrigieron en T-020),
    10 manuales y 0 no seguras.
- **Lo que queda fuera:** instalar la APK experimental junto a la estable en el Redmi (T-078).

### T-011
**APK experimental local**
- **Estado:** terminada como compilación. La prueba en el Redmi está en T-078.
- **Evidencia:**
  - **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-c66f29d.apk`, de 253 574 579 bytes.
  - **SHA-256:** `13a74f97d71947bd2fc8d8a4582d268594401c36d72805b0efef23d2566053ca`.
  - **Al lado:** `.resumen.txt` y `.NO_DISTRIBUIR.txt`.
  - **Paquete:** `com.aethelgard.experimental`.
- **Qué hace:** arranca el juego 2D, porque todavía no tiene la región 3D.
- **Nota:** la compilación anterior, `…-d09ae1c-local.apk`, se hizo antes de corregir el script.
- **No se distribuye:** lleva recursos de licencia pendiente.

### T-012
**APK «Prueba 3D» de Pastos Verdes**
- **Estado:** terminada como compilación. Instalarla y probarla en el Redmi queda pendiente del usuario.
- **Evidencia:**
  - **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_prueba3d-20261107-98ac41f-local.apk`, de 284 816 787 bytes.
  - **SHA-256:** `8677785d0c0dbc8714e2282d13c7809ec455fbca82ebaae629a1cb2266710d51`.
  - **Paquete:** `com.aethelgard.prueba3d`, versionCode 24, nombre visible «Aethelgard Prueba 3D».
  - **Firma:** de depuración, verificada.
  - **Por qué acaba en `-local`:** lleva los cambios sin confirmar del bloque B y archivos nuevos de
    `vegetacion_prueba/quaternius`.
- **Entrega:** a petición del usuario, se copió el 2026-11-07 a las 04:00 a la carpeta Descargas del Redmi. Desde
  entonces el móvil está reservado ([D-013](DECISIONS.md#d-013)) y no se ha vuelto a consultar.
- **No se distribuye.**

### T-020
**Encargo, Fase 0: línea base, respaldo y diagnóstico**
- **Estado:** terminada.
- **Evidencia:**
  - **Commits** en `rebelum-alpha`: `3a16db2`, `872517a`, `aa709dd` y `c2a524c`.
  - **Pruebas:**
    - Pasada completa `2026-11-07_152737`: 17 superadas, 0 fallidas, 10 manuales y 0 no seguras.
    - Repetición de las dos pruebas corregidas (`2026-11-07_152859`): las dos superadas.
    - Los registros están en `D:\REBELUM_diagnostico\pruebas\`.
  - **Respaldo:** `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico`.
  - **Registro:** `D:\Aethelgard_alpha\docs\fase2\registro_encargo.md`, con las decisiones 0.1 a 0.10.
- **Lo que no cubre:** las métricas de rendimiento y la matriz de cobertura, que también pedía la Fase 0 (T-024).

### T-021
**Pastos Verdes 3D accesible desde el recorrido normal (encargo: Fase 1, puntos 2.1-2.2; plan 3D: 2.3-2.4)**
- **Estado:** terminada en el PC el 2026-11-07. Falta verla en el Redmi (T-078) y revisar su aspecto con ventana.
- **Objetivo:** en la compilación experimental, ir del mapa a Pastos Verdes 3D y volver, sin abrir escenas a mano, con
  la variante 2D como respaldo.
- **Dependencias:** T-020.
- **Criterio de aceptación:**
  - Se entra y se sale de Pastos Verdes 3D desde el mapa de la compilación experimental, con la posición y el estado
    coherentes.
  - Sin el modo 3D, todo vuelve al mapa 2D.
  - Las pruebas de siempre y las nuevas pasan en el ejecutor aislado.
  - Commits locales pequeños en `rebelum-alpha`.
- **Antes de empezar** se verificó que el trabajo a medias era idéntico byte a byte a su respaldo (el parche y los 11
  archivos nuevos del `.tar`). Se reutilizó tal cual, sin aplicar nada.
- **Evidencia** (commits locales en `rebelum-alpha`):
  - **`d066fe9`:**
    - `modo3d.gd`, el interruptor;
    - `mapa.gd`, el lugar 10;
    - `progreso.gd`: `partida_exp.save`, `hitos`, `pos_3d`, `volcar()`/`restaurar()` y la «Estela del camino».
  - **`f039c72`:**
    - los 8 diálogos `pv_*` y los personajes garon y tilo;
    - `ui_accept` y `ui_cancel` con mando en `project.godot`.
  - **`a89a8a5`:** la región `zonas3d/pastos_verdes_3d.gd` y `.tscn`, más `pruebas/prueba_zona3d.gd`.
    - Hereda de `sendero_puente.gd`.
    - Entrada por el principio del camino.
    - Encuentros: paso de 0,5 m, 40 pasos seguros y probabilidad 0,012.
    - Combate con vuelta al mismo sitio.
    - Guardado automático al entrar y al pausar.
    - Dos salidas al mapa, marcadas con un círculo dorado y el letrero «Mapa del mundo».
    - Del panel del prototipo solo quedan CAL y RND.
  - **`03b960a`:** el preset experimental incluye lo que necesita la región y deja fuera los bancos y la vegetación
    de prueba.
  - **Pruebas:**
    - `prueba_zona3d`, pasada `2026-11-07_164457`: entrada, 39 pasos seguros sin encuentro, encuentro, **combate de
      verdad** y vuelta a 0,00 m del sitio, salida al mapa con el lugar 10 y guardado en `partida_exp.save`.
    - Batería completa `2026-11-07_164526`: **18 superadas, 0 fallidas**, 10 manuales y 0 no seguras. Ni la partida
      real ni el proyecto cambiaron.
  - **APK:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-03b960a.apk`.
    - 244,7 MB, versionCode 34.
    - SHA-256 `1a2b43178cd4ff1944a71d205a879af79e2d9b1aaa4b7e6297e74980d04ef08b`.
    - Paquete `com.aethelgard.experimental` y firma verificada.
    - Lleva la región y sus dependencias, y no lleva pruebas, prototipos de banco, EmacE ni partidas.
    - Es una **prueba privada**, con el aviso `NO_DISTRIBUIR`: lleva recursos de la tabla de licencias.
- **Lo que no cubre:**
  - **Aspecto:** no se ha visto con ventana: las pruebas van sin ventana.
  - **Redmi:** no se ha probado en el móvil.
  - **Grupo y contenido:** los seguidores, Tilo, la estela, el cofre y el combate fijo están en T-022.

### T-076
**Que una sesión sin partida cargada no pise la partida completa**
- **Estado:** **terminada en `rebelum-alpha`** el 2026-11-08 (`86a58af`, [D-056](DECISIONS.md#d-056)). En `desarollo`
  sigue el problema.
- **Hecho observado en el código** (antes del arreglo, `aethelgard/progreso.gd:181-194`):
  - `guardar()` solo escribe las metas que existen en ese momento.
  - Una sesión que no cargó la partida, por ejemplo con F6 desde el editor, la sustituye por una parcial.
  - Así perdió la partida del PC la clave `grupo` el 07/11 a las 03:50.
- **Arreglo:**
  - Solo se guarda encima de una partida si la sesión la cargó (o no había ninguna).
  - Se escribe en `.tmp`, se comprueba y se sustituye; la anterior queda en `.bak`.
  - Una partida dañada se recupera de `.tmp` o `.bak`, y la dañada se aparta en `.danada`.
- **Evidencia** (ejecutado aislado; batería `2026-11-08_170008`: **21 superadas, 0 fallidas**, 11 manuales):
  - `prueba_partida`, nueva, con partidas sintéticas: sesión sin cargar (no guarda y la partida no cambia), cofre,
    misión y posición tras un combate, partida antigua sin claves ni lista de objetos, dañada, escritura fallida y
    corte al guardar.
  - La partida real del PC no cambió.
- **Ampliado en `e670a5d`** ([D-060](DECISIONS.md#d-060)): avisos al jugador; casos 7 (la partida y su `.bak`
  dañadas: se apartan las dos y empieza una nueva) y 8 (partida nueva sin archivos). **Alcance:** lo comprobado
  reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **Restricción:** la partida del PC no se restaura ([D-011](DECISIONS.md#d-011)).
- **08/11, 19:37:34:** volvió a pasar en la copia del usuario (`rebelum-3d`, sin este arreglo). Un juego lanzado desde
  su editor reescribió la partida del PC ([D-011](DECISIONS.md#d-011)).
- **Traído a la copia habitual** (08/11, 20:36, `b8e042d`, [D-066](DECISIONS.md#d-066)), con permiso del usuario: solo
  la protección (`progreso.gd`) y las 3 líneas de `inventario.gd`.
  - **Evidencia** (ejecutado aislado en `D:\Aethelgard_guardado`, copia del mismo estado): batería 15 → 16 superadas
    con las mismas 2 fallidas de antes; `prueba_guardado_protegido`; y de punta a punta, abrir `mapa.tscn` suelto y
    cerrar la ventana ya no reescribe una partida completa (sin el arreglo, perdía `grupo` e `inventario`).
  - Respaldo: `D:\REBELUM_respaldos\2026-11-08_antes_guardado_copia_habitual`. El bloque B, idéntico.

### T-077
**`prueba_guardado` con un archivo propio**
- **Estado:** **terminada en `rebelum-alpha`** el 2026-11-08 (`86a58af`).
- **Antes:** `aethelgard/pruebas/prueba_guardado.gd` escribía en `user://partida.save` (`P.GUARDADO`) y luego lo
  restauraba. Solo era segura con el ejecutor aislado.
- **Ahora:** usa `user://prueba_guardado.save` con Engine `archivo_partida_prueba`. `progreso.gd` nunca acepta ahí la
  ruta de una partida de verdad.

### T-079
**Repositorio privado para descargar las APK de prueba en el móvil**
- **Estado:** terminada el 2026-11-08, a las 14:46 ([D-054](DECISIONS.md#d-054)).
- **Repositorio:** `https://github.com/Brunopina6/Aethelgard-pruebas`, privado.
  - Su único colaborador es el dueño, y no tiene incidencias ni wiki.
  - El `README.md` (commit `9c83ac3`) explica cómo instalar una prueba en el móvil.
- **Primera versión:** `exp-20261108-aabe5ad`.
  - **APK:** `Aethelgard_exp-20261108-aabe5ad.apk`, compilada con `compilar_apk_experimental.ps1` («TODO CORRECTO»).
  - Sale de `rebelum-alpha` @ `aabe5ad`, con versionCode 39 y el mismo certificado que las anteriores: se instala
    encima y conserva la partida del móvil.
  - **Tamaño:** 256 596 467 bytes (244,7 MB).
  - **SHA-256:** `06bf212add337a3afda056bd7a79f3d354e84eb2698940e92ee66bee3cdd3b6c`.
  - Lleva los mismos recursos pendientes que `989d35e`, y ninguno es de Suno.
- **Evidencia** (comprobado con `gh api` a las 14:46):
  - el recurso está en estado `uploaded`, con el mismo tamaño;
  - el `digest` de GitHub coincide con el SHA-256 local;
  - `releases/latest` apunta a esta versión;
  - el repositorio es privado.
- **Ordenada por fecha y versión** (08/11, 14:58), como pidió el usuario ([D-054](DECISIONS.md#d-054)):
  - la release se titula «08/11/2026 · Prueba v39»;
  - el archivo se llama ahora `Aethelgard_Exp_2026-11-08_v39.apk`, con el mismo tamaño y el mismo `digest`;
  - el `README.md` (commit `d82abaa`) lleva la tabla de pruebas y el enlace a la original, `v0.1.0`, en el repositorio
    principal. El texto publicado es idéntico al local.
- **Evidencia de la descarga** (14:59): una petición de los 4 primeros bytes del archivo de GitHub devuelve `50 4b 03 04`,
  igual que la APK local.
- **Copia de la original** (08/11, 15:53), como pidió el usuario («Sí, cópiala»):
  - se descargó de la release `v0.1.0` del repositorio principal y su SHA-256 coincide con el `digest` de allí:
    `8d4f3107816f9b5a0dd5074e40bb3aafd230b391d2a46aef0c9f7b50a87cb67b`;
  - es la app estable: `com.aethelgard.juego`, versionCode 1 y versionName `0.1`;
  - ninguno de sus 1731 archivos es una pista de Suno;
  - en el repositorio de pruebas, la release se titula «05/11/2026 · Original v0.1.0», con el archivo
    `Aethelgard_2026-11-05_v0.1.0.apk` y el mismo `digest`;
  - va etiquetada sobre el primer commit (`8ece9e3`). `gh release list`, que ordena por fecha como GitHub, la muestra
    la última, debajo de la Prueba v39. «Latest» sigue en la Prueba v39;
  - el `README.md` (commit `d0eb7fa`) la añade al final de la tabla;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04`.
- **Sin ver:** la página web de releases. El orden se comprobó con `gh release list`.
- **Prueba v41** (08/11, 16:39), con la convención de [D-054](DECISIONS.md#d-054):
  - la fila del `README.md` va en el commit `4b929d9`, y la release `exp-20261108-3976565` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v41.apk` tiene 256 608 906 bytes, y su `digest` coincide con el SHA-256 local
    (`8f3f52ef…`);
  - `gh release list` da el orden v41 («Latest»), v39 y la original.
- **Prueba v44** (08/11, 17:17), con la misma convención:
  - la fila del `README.md` va en el commit `71931ae`;
  - la release `exp-20261108-21d2e21` contiene el archivo `Aethelgard_Exp_2026-11-08_v44.apk`, de 256 625 290 bytes;
  - su `digest` coincide con el SHA-256 local (`09b3c0f0…`);
  - el certificado es el mismo y los grupos de licencia, iguales a los de la v41; no lleva Suno;
  - el orden es v44 («Latest»), v41, v39 y la original;
  - el `README.md` ya separa la privacidad del repositorio de los permisos de los recursos.
- **Prueba v47** (08/11, hacia las 17:40), con la misma convención:
  - la release `exp-20261108-091d1d1` contiene el archivo `Aethelgard_Exp_2026-11-08_v47.apk`, de 256 629 386 bytes;
  - SHA-256 `988f9a8e…`; certificado y grupos de licencia, iguales a los de la v44; sin Suno.
- **Prueba v50** (08/11, 18:53), con la misma convención:
  - sale de `rebelum-alpha` @ `36502e9` (`e630b02` más los `.uid`), compilada dos veces: la segunda, con el árbol
    limpio («TODO CORRECTO»);
  - la fila del `README.md` va en el commit `6a6f27c`, y la release `exp-20261108-36502e9` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v50.apk` tiene 256 637 578 bytes, y su `digest` coincide con el SHA-256 local
    (`a374a858…`);
  - certificado `3413edcd…`, el mismo de siempre; sin Suno (sus canciones no están en el proyecto del encargo);
  - el repositorio sigue privado, con el dueño como único colaborador y sin invitaciones;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04` (HTTP 206);
  - el orden es v50 («Latest»), v47, v44, v41, v39 y la original.
- **Prueba v52** (08/11, 19:58), con la misma convención:
  - sale de `rebelum-alpha` @ `edf52cd` (`e6e52c4`, T-025, más los `.uid`), compilada dos veces: la segunda, con el
    árbol limpio («TODO CORRECTO»);
  - la fila del `README.md` va en el commit `2bac6a9`, y la release `exp-20261108-edf52cd` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v52.apk` tiene 256 649 999 bytes, y su `digest` coincide con el SHA-256 local
    (`2788ed92…`);
  - certificado `3413edcd…`, el mismo de siempre; los mismos grupos de licencia; sin Suno (el audio son los sonidos de
    Érebo, `musica_combate_normal` y los tecleos de Dialogic);
  - el repositorio sigue privado, con el dueño como único colaborador y sin invitaciones;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04` (HTTP 206);
  - el orden es v52 («Latest»), v50, v47, v44, v41, v39 y la original.
- **Prueba v54** (08/11, 20:17), con la misma convención:
  - sale de `rebelum-alpha` @ `2776729` (`e44fb9e`, la base del audio de T-030, más los `.uid`), compilada dos veces:
    la segunda, con el árbol limpio («TODO CORRECTO»);
  - la fila del `README.md` va en el commit `b9f0ff2`, y la release `exp-20261108-2776729` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v54.apk` tiene 256 658 545 bytes, y su `digest` coincide con el SHA-256 local
    (`c00f0ff6…`);
  - certificado `3413edcd…`; los mismos grupos de licencia y el mismo audio que la v52, sin Suno; lleva la disposición
    de buses (`default_bus_layout`);
  - el repositorio sigue privado, con el dueño como único colaborador y sin invitaciones;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04` (HTTP 206);
  - el orden es v54 («Latest»), v52, v50, v47, v44, v41, v39 y la original.
- **Copiada al Redmi por USB** (08/11, 20:24, [D-065](DECISIONS.md#d-065)): la v54, como
  `Download/Aethelgard_Exp_2026-11-08_v54.apk`; en el teléfono, 256 658 545 bytes y el mismo SHA-256. No se borró nada.
- **Prueba v57** (08/11, 21:13), con la misma convención: de `40fb5b8` (el gestor de música y los ambientes), compilada
  una vez con el árbol limpio («TODO CORRECTO»; el script le dio el versionCode 57). Fila del `README.md` en
  `a2b4562`, release `exp-20261108-40fb5b8` etiquetada sobre él; `Aethelgard_Exp_2026-11-08_v57.apk`, 261 751 034
  bytes, `digest` igual al SHA-256 local (`ae82484d…`); certificado `3413edcd…`; sin Suno (el audio nuevo son los cinco
  ambientes CC0); cabecera `50 4b 03 04` (HTTP 206); orden v57 («Latest»), v54, v52…; repositorio privado.
  - **Copiada al Redmi** (21:15): `Download/Aethelgard_Exp_2026-11-08_v57.apk`, mismo tamaño y SHA-256 en el
    teléfono; la v54 sigue allí.
- **Pendiente de verificar:** la instalación y la prueba en el móvil, que hace el usuario.
