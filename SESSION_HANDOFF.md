# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 19:05 (hora local, UTC+1).
- **Hecho y comprobado en el PC:**
  - el grupo activo manda en todo: Kael solo hasta PV-03, con encuentros a su medida
    ([D-060](DECISIONS.md#d-060));
  - avisos del guardado y la opción de desarrollo «Probar la misión desde el principio»;
  - sin tirones al abrir diálogos ni al ver algo por primera vez ([D-061](DECISIONS.md#d-061)).
- **Subida:** la Prueba v50.
- **Relevo anterior** (del 07/11 por la tarde hasta las 16:40 del 08/11, con las tablas del Redmi): en
  [docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md).

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `36502e9`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| APK de prueba para el móvil | `Brunopina6/Aethelgard-pruebas`, privado: v50 («Latest»), v47, v44, v41, v39 y la original ([D-054](DECISIONS.md#d-054)) |
| Mediciones de este hito | `D:\REBELUM_diagnostico\primeras_veces\` (`comparacion.md`, los JSON y las capturas de los diálogos) |
| Procesos en marcha | Ninguno a las 19:05. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Encargo en curso

- **Petición** (08/11, hacia las 16:55): «Continúa el desarrollo de AETHELGARD desde la Prueba v41…». Detalle en
  [MEMORIA_CHAT.md](MEMORIA_CHAT.md#5-autorizaciones-y-restricciones-vigentes-y-sustituidas).
- **Última orden** (08/11, hacia las 17:45): Kael solo antes de PV-03; el grupo activo como fuente común; encuentros
  para Kael; pruebas de grupos de 1, 2 y 3; después, los tirones del primer diálogo y de los primeros efectos, midiendo
  el arranque en frío y los recorridos posteriores por separado, y lo que crecen las cargas; completar las pruebas del
  guardado; una partida de prueba aislada. **«Mantén pendientes la escucha y la validación de la v47 en el Redmi.»**

| Hito | Commit (`rebelum-alpha`) | Comprobado | Estado |
|---|---|---|---|
| Hasta la Prueba v47 (guardado, cofre, mirador, grupo con la misión, centinela) | `86a58af` … `091d1d1` | Ver [T-022](TASKS.md#t-022) | Hecho |
| Grupo activo, encuentros para Kael solo, avisos del guardado y partida de prueba | `e670a5d` | Batería `2026-11-08_175301`: 27 superadas y 0 fallidas | Hecho ([D-060](DECISIONS.md#d-060)) |
| Sin tirones de diálogos ni de la primera vez | `e630b02` | Batería `2026-11-08_184433`: 28 superadas y 0 fallidas; `medir_primeras_veces.gd`; capturas | Hecho en el PC ([D-061](DECISIONS.md#d-061)) |
| Prueba v50 en GitHub | `36502e9` (los `.uid`) | `digest` igual, cabecera `50 4b 03 04`, repositorio privado | Subida ([T-079](TASKS.md#t-079)) |

## Medido en el PC en este hito (detalle en [T-023](TASKS.md#t-023))

| | Antes | Después |
|---|---|---|
| Primer diálogo | 184 ms | 9-11 ms |
| Cada diálogo siguiente | 54-56 ms | 6-7 ms |
| Primer paseo tras instalar (fotograma más lento) | 41 ms | 4,0 ms |
| Primer paseo con caché / al volver a entrar | 18-20 ms | 4-5 ms |
| Pantalla de carga | — | +1 fotograma de unos 30 ms |
| Entrada en la región, en negro | 1,21 s (tras instalar), 1,03 s (con caché) | 1,43 s y 1,10-1,13 s |

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (se publican en `memoria-desarrollo`) y los cambios del usuario, sin
  tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- **Nada probado en el Redmi:** ni la v41, ni la v44, ni la v47, ni la v50. Falta el banco GRUPO.
  - Los tiempos de este hito son del PC. En el Redmi, compilar sombreados y leer archivos cuesta más: las cargas y los
    tirones que queden se miden allí.
  - Sin comprobar si la caché de sombreados de Godot funciona en el Mali-G57. Si no funcionara, cada arranque sería
    como el primero (la vitrina sigue llevando ese coste a la entrada, en negro).
- **Sonidos sin escuchar:** el del cofre
  (`D:\REBELUM_diagnostico\pruebas\2026-11-08_184646\prueba_region3d_fotos\sonido_cofre.wav`) y las campanas.
- **Combates:** se ganan con ataques automáticos (`prueba_centinela` y `prueba_grupos_combate`); no prueban la
  estrategia de un jugador.
- **Guardado:** lo comprobado reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **Revisión visual:** solo con mis capturas. Falta la opinión del usuario.

## Próximo paso concreto (por dependencias)

1. **El encargo único por dependencias:** estabilidad, controles (T-025), audio (T-030) e integración, antes de las
   magias, estados y habilidades nuevas (T-040). Las magias existentes no cambian.
2. **Del perfil bajo (T-023), cuando haya Redmi:** medir las cargas y los tirones con la v50, y después la sombra
   precalculada.

## Pendiente del usuario

- **Probar la v50 en el móvil** (sustituye a la v47), a ser posible con «Probar la misión desde el principio»:
  - si Kael va solo hasta que llega Lya y los combates de antes se pueden ganar;
  - si los diálogos y el primer paseo van sin parones, y cuánto tardan las cargas;
  - el cofre (si se ve y se oye bien), la cinemática y el grupo.
- Si quiere medir, el banco GRUPO en el Redmi y una captura de la tabla.
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
