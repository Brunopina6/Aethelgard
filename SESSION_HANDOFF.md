# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 20:05 (hora local, UTC+1).
- **Hecho y comprobado en el PC:**
  - quien se une al grupo conserva sus datos: la nivelación al unirse la había puesto yo y queda como propuesta
    ([D-062](DECISIONS.md#d-062), [T-080](TASKS.md#t-080));
  - **T-025:** teclado y mando sin ratón, foco visible, una pulsación una acción y el mando desconectado deja seguir
    ([D-063](DECISIONS.md#d-063)). Comprobado con eventos **simulados**: aquí no hay mando.
- **Subida:** la Prueba v52, para la prueba táctil en el Redmi.
- **Relevo anterior** (del 07/11 por la tarde hasta las 16:40 del 08/11, con las tablas del Redmi): en
  [docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md).

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `edf52cd`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| APK de prueba para el móvil | `Brunopina6/Aethelgard-pruebas`, privado: v52 («Latest»), v50, v47, v44, v41, v39 y la original ([D-054](DECISIONS.md#d-054)) |
| Capturas del foco | `D:\REBELUM_diagnostico\pruebas\2026-11-08_195003\prueba_foco_fotos\` (`lamina_foco.png` y las 7 sueltas) |
| Procesos en marcha | Ninguno a las 20:05. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Encargo en curso

- **Petición** (08/11, hacia las 16:55): «Continúa el desarrollo de AETHELGARD desde la Prueba v41…». Detalle en
  [MEMORIA_CHAT.md](MEMORIA_CHAT.md#5-autorizaciones-y-restricciones-vigentes-y-sustituidas).
- **Última orden** (08/11, hacia las 19:00): «continúa con estabilidad y controles, T-025 […] No necesitas volver a
  pedirme permiso para cada tarea rutinaria ya incluida». Antes, comprobar la nivelación al unirse. Prioridad, Android y
  PC; distinguir lo simulado de lo probado con hardware; avisar cuando haga falta su prueba en el móvil; después,
  seguir con el siguiente trabajo autorizado que se pueda hacer en local.

| Hito | Commit (`rebelum-alpha`) | Comprobado | Estado |
|---|---|---|---|
| Grupo activo, encuentros para Kael solo, avisos del guardado y partida de prueba | `e670a5d` | Batería `2026-11-08_175301`: 27 superadas y 0 fallidas | Hecho ([D-060](DECISIONS.md#d-060)) |
| Sin tirones de diálogos ni de la primera vez | `e630b02` | Batería `2026-11-08_184433`: 28 superadas y 0 fallidas | Hecho en el PC ([D-061](DECISIONS.md#d-061)) |
| Quien se une conserva sus datos; T-025 (teclado, mando y foco) | `e6e52c4` | Batería `2026-11-08_195103`: **32 superadas, 0 fallidas**, 17 manuales y 0 no seguras; capturas del foco revisadas | Hecho en el PC, simulado ([D-063](DECISIONS.md#d-063)) |
| Prueba v52 en GitHub | `edf52cd` (los `.uid`) | `digest` igual, cabecera `50 4b 03 04`, repositorio privado | Subida ([T-079](TASKS.md#t-079)) |

## Hecho en este hito, además

- **La partida del PC se reescribió a las 19:37:34**, pero no fue la batería. Fue un juego lanzado desde un editor
  abierto en la copia del usuario, que aún no tiene el arreglo de T-076. Se conserva tal cual
  ([D-011](DECISIONS.md#d-011)).
- **El ejecutor de pruebas** apunta cualquier Godot que no haya lanzado y, al pasarse de tiempo una prueba, solo cierra
  lo suyo. Antes podía cerrar un editor del usuario ([D-010](DECISIONS.md#d-010)).
- **`prueba_grupos_combate`** ya no falla al azar: si el único Slime huye, se gana sin experiencia, como manda el juego.

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (se publican en `memoria-desarrollo`) y los cambios del usuario, sin
  tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- **Nada probado en el Redmi:** ni la v41, ni la v44, ni la v47, ni la v50, ni la v52. Falta el banco GRUPO.
- **T-025, sin hardware:** ningún mando real ni teclado real; el táctil, solo con las pruebas simuladas
  (`prueba_toque`, `prueba_dpad`, las de la región y la captura con el dedo). Lista de pruebas manuales abiertas en
  [T-025](TASKS.md#t-025).
- **Sonidos sin escuchar:** el del cofre
  (`D:\REBELUM_diagnostico\pruebas\2026-11-08_184646\prueba_region3d_fotos\sonido_cofre.wav`) y las campanas.
- **Combates:** se ganan con ataques automáticos; no prueban la estrategia de un jugador.
- **Guardado:** lo comprobado reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **Revisión visual:** solo con mis capturas. Falta la opinión del usuario.

## Próximo paso concreto (por dependencias)

1. **Audio (T-030), la base técnica:** buses Música, Efectos, Interfaz y Ambiente; volúmenes guardados como
   preferencias; una ventana de ajustes mínima navegable con el foco (cubre también los «ajustes» que faltan en
   T-025). Sin canciones de Suno; el reparto de pistas de D-043 sigue sin decidir.
2. **Después:** integración, y solo entonces las magias, estados y habilidades nuevas (T-040). Las magias existentes
   no cambian.
3. **Del perfil bajo (T-023), cuando haya Redmi:** medir las cargas y los tirones con la v52, y después la sombra
   precalculada.

## Pendiente del usuario

- **Probar la v52 en el móvil** (sustituye a la v50), con el dedo:
  - que todo funcione como antes: andar, la barra, «Entrar», la acción, los diálogos con «SEGUIR», el combate, los
    menús, la tienda y el diario;
  - que no salga ningún marco dorado al tocar ni se quede marcado un botón;
  - que Lya, al unirse con su propio nivel, deje ganar los combates siguientes;
  - y lo pendiente de la v50: Kael solo hasta Lya, diálogos y paseos sin parones, cargas, el cofre y la cinemática.
- **Opcional:** un mando o un teclado Bluetooth en el móvil o en el PC.
- **Decidir** la nivelación al unirse ([D-062](DECISIONS.md#d-062)).
- **Ver** la lámina del foco.
- Licencias ([T-070](TASKS.md#t-070)): qué sustituye a la música de Suno en una APK entregable; los créditos de
  Meshy.

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Encargo único:** reanudado ([D-046](DECISIONS.md#d-046)). Cambios pequeños, reversibles y comprobados; se puede
  compilar y probar en local.
- **Push:** solo la memoria, en `memoria-desarrollo` ([D-049](DECISIONS.md#d-049)), y las APK de prueba, en el
  repositorio privado `Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)). Nada de push de `rebelum-alpha`.
- **Privacidad y licencias:** que el repositorio sea privado no cambia los permisos de los recursos.
  - Las APK siguen siendo `NO_DISTRIBUIR`.
  - Ninguna lleva música de Suno.
- **Git:** nada en `main` ni en `desarollo`; nada destructivo; no tocar el bloque B.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Redmi:** reservado.
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)).
