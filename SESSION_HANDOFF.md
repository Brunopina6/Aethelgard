# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 21:20 (hora local, UTC+1).
- **Hecho después (21:20):** los encuentros con los niveles reales de incorporación se superan todos, sin cambiarlos
  (`9bfd288`); el gestor de música y ambiente con ambientes CC0 (`40fb5b8`, [D-067](DECISIONS.md#d-067)); la
  **Prueba v57**, publicada y copiada al Redmi.
- **Hecho y comprobado** (hito de seguridad del encargo de las 20:20):
  - la Prueba v54 está en las Descargas del Redmi, copiada por USB y comprobada en el teléfono
    ([D-065](DECISIONS.md#d-065));
  - la copia habitual (`rebelum-3d`) ya no pisa la partida en una sesión que no la cargó (`b8e042d`,
    [D-066](DECISIONS.md#d-066)), validado antes en una copia aislada;
  - el ejecutor de pruebas solo cierra lo suyo, verificado con otro Godot abierto (`d5fd793`,
    [D-010](DECISIONS.md#d-010)).
- **Antes, en la misma noche:** T-025 (teclado, mando y foco, simulado), la base del audio (T-030) y las Pruebas v52 y
  v54. Detalle en [TASKS.md](TASKS.md).
- **Relevo anterior** (del 07/11 por la tarde hasta las 16:40 del 08/11, con las tablas del Redmi): en
  [docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md).

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `b8e042d` (la protección del guardado encima de `ce84422`), local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `40fb5b8`, local y nunca subida |
| Copia de validación | `D:\Aethelgard_guardado` (árbol de trabajo sin rama sobre `ce84422`, con el estado de la copia habitual y el arreglo). Solo para validar; se puede quitar con permiso |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| APK de prueba | Repositorio privado `Brunopina6/Aethelgard-pruebas`: v57 («Latest»), v54, v52, v50, v47, v44, v41, v39 y la original ([D-054](DECISIONS.md#d-054)). En el Redmi: `Download/Aethelgard_Exp_2026-11-08_v54.apk` y `…_v57.apk` |
| Grabaciones del sonido | `D:\REBELUM_diagnostico\pruebas\2026-11-08_210056\prueba_musica_senal\` (5 s de cada contexto, para escuchar) |
| Redmi | REDMI A7 Pro, Android 16, por USB con ADB del SDK (`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`) |
| Respaldo del guardado | `D:\REBELUM_respaldos\2026-11-08_antes_guardado_copia_habitual` |
| Procesos en marcha | Ninguno a las 20:45. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Encargo en curso

- **Petición** (08/11, hacia las 20:20; pegada): «Continúa desde la Prueba v54 y la memoria publicada en 11d5469. Este
  encargo reúne la entrega al Redmi, el cierre de seguridad y audio y la mejora del diálogo inicial y las
  animaciones.» Sin preguntas rutinarias dentro del alcance. Resumen de los 9 puntos en
  [MEMORIA_CHAT.md](MEMORIA_CHAT.md).

| Punto | Estado |
|---|---|
| 1. La v54 al Redmi por USB | **Hecho** (20:24): en Descargas, tamaño y SHA-256 comprobados en el teléfono |
| 2. La copia habitual y el ejecutor | **Hecho**: protección del guardado en `rebelum-3d` (`b8e042d`) y ejecutor verificado (`d5fd793`) |
| 3. Progresión original y encuentros con los niveles reales de incorporación | **Hecho** (`9bfd288`): 80 combates de 80 ganados; curando, no cae nadie; no hace falta tocar los encuentros |
| 4. Gestor de música (T-030) | **Hecho** (`40fb5b8`): ambientes CC0 por lugar, combate y vuelta, pausa; Prueba v57; falta la escucha |
| 5-7. Primer diálogo: presentación, gestos, cámara y texto ([T-081](TASKS.md#t-081)) | **Siguiente**: es el prólogo del mapa (partida nueva) |
| 8-9. Integración, medidas, APK al Redmi y memoria por hitos | En cada hito |

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (se publican en `memoria-desarrollo`) y los cambios del usuario
  (bloque B), sin tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- **Nada probado en el Redmi todavía:** la v54 está copiada, pero sin instalar. Falta el banco GRUPO.
- **T-025, sin hardware:** ningún mando real ni teclado real; el táctil, solo con las pruebas simuladas. No es una
  validación completa de las plataformas. Pruebas manuales abiertas en [T-025](TASKS.md#t-025).
- **Sonidos sin escuchar:** el cofre, las campanas y los volúmenes de los ajustes.
- **Combates:** se ganan con ataques automáticos; no prueban la estrategia de un jugador.
- **Guardado:** lo comprobado reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **La copia habitual** sigue con el ejecutor de pruebas antiguo (traer el nuevo necesita autorización).

## Próximo paso concreto (por dependencias)

1. **El primer diálogo ([T-081](TASKS.md#t-081)):** es el prólogo (`dialogos/prologo.dtl`, Kael y Lya, 11 frases),
   que arranca en el mapa del mundo con una partida nueva (`mapa.gd`); con una partida existente no aparece. Retratos
   2D de cuerpo entero, uno por personaje. Plan: capturas «antes», retrato vivo propio de Dialogic (respiración, foco
   en quien habla, gestos breves con `extra_data`), entrada con cámara y franjas, texto legible en el móvil, botón
   para saltar que devuelva cámara y control; capturas «después» y medidas.
2. Cuando esté comprobado: APK nueva, release privada y copia al Redmi.

## Pendiente del usuario

- **Instalar y probar la v57** (está en Descargas; incluye todo lo de la v54):
  - con el dedo, que todo funcione como antes y que no salga ningún marco dorado al tocar;
  - que Lya, al unirse con su propio nivel, deje ganar los combates siguientes;
  - **escuchar** el ambiente (Pastos Verdes, mapa), su vuelta tras el combate y los volúmenes de «Ajustes».
- **Opcional:** un mando o un teclado Bluetooth.
- **Decidir** la nivelación al unirse ([D-062](DECISIONS.md#d-062)); no hace falta para seguir.
- Licencias ([T-070](TASKS.md#t-070)): qué sustituye a la música de Suno en una APK entregable; los créditos de
  Meshy.

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Encargo:** cambios pequeños, reversibles y comprobados en `rebelum-alpha`; se puede compilar y probar en local.
- **Push:** solo la memoria, en `memoria-desarrollo` ([D-049](DECISIONS.md#d-049)), y las APK de prueba, en el
  repositorio privado `Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)). Nada de push de `rebelum-alpha`.
- **Redmi:** solo copiar APK de prueba a Descargas por USB y comprobarlas ([D-065](DECISIONS.md#d-065)). Instalar y lo
  demás, el usuario.
- **Copia habitual:** solo la protección del guardado ([D-066](DECISIONS.md#d-066)); el bloque B no se toca.
- **Privacidad y licencias:** las APK siguen siendo `NO_DISTRIBUIR`; ninguna lleva música de Suno.
- **Git:** nada en `main` ni en `desarollo`; nada destructivo.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)).
