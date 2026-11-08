# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 17:20 (hora local, UTC+1).
- **Hecho:** el guardado protegido, el cofre y la cinemática del mirador. La Prueba v44 está subida.
- **Relevo anterior** (del 07/11 por la tarde hasta las 16:40 del 08/11, con las tablas del Redmi): en
  [docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md).

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `21d2e21`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| APK de prueba para el móvil | `Brunopina6/Aethelgard-pruebas`, privado: v44 («Latest»), v41, v39 y la original ([D-054](DECISIONS.md#d-054)) |
| Procesos en marcha | Ninguno a las 17:17. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Encargo en curso

- **Petición** (08/11, hacia las 16:55): «Continúa el desarrollo de AETHELGARD desde la Prueba v41…».
  - **Orden pedido:** cerrar la región de Pastos Verdes y la sensación de exploración, proteger antes el guardado y
    medir antes de optimizar.
  - Después, seguir el encargo único por dependencias.
  - Detalle en [MEMORIA_CHAT.md](MEMORIA_CHAT.md#5-autorizaciones-y-restricciones-vigentes-y-sustituidas).

| Hito | Commit (`rebelum-alpha`) | Comprobado | Estado |
|---|---|---|---|
| Guardado protegido (T-076 y T-077) | `86a58af` | `prueba_partida` y `prueba_guardado` | Hecho ([D-056](DECISIONS.md#d-056)) |
| Cofre del árbol mágico | `d4db508` | `prueba_cofre3d` y capturas | Hecho; **sonido sin escuchar** ([D-057](DECISIONS.md#d-057)) |
| Cinemática del mirador (PV-07) | `d4db508` | `prueba_mirador` y capturas | Hecho; **campanas sin escuchar** ([D-058](DECISIONS.md#d-058)) |
| Prueba v44 en GitHub | `21d2e21` (los `.uid`) | Batería `2026-11-08_171230`: 23 superadas, 0 fallidas y 12 manuales; `digest` igual | Subida ([T-079](TASKS.md#t-079)) |

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (se publican en `memoria-desarrollo`) y los cambios del usuario, sin
  tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- **Sonidos sin escuchar:**
  - el del cofre está en `D:\REBELUM_diagnostico\pruebas\2026-11-08_171143\prueba_region3d_fotos\sonido_cofre.wav`;
  - las campanas solo se han comprobado en cifras.
- **Nada probado en el Redmi:** ni la v41 ni la v44. Falta el banco GRUPO.
- **Combate del centinela:** en `prueba_ruta_alpha` la victoria es simulada. Falta una prueba con el combate real.
- **Revisión visual:** solo con mis capturas. Falta la opinión del usuario.

## Próximo paso concreto (por dependencias)

1. **Recorrido, grupo y pantalla pequeña** (encargo §3 y §4):
   - el grupo en varias rutas, en posiciones difíciles y con distintas distancias de cámara;
   - indicadores de objetivo y de interacción legibles en el móvil.
2. **Combate real del centinela**, con el combate automático si es viable, y el recorrido completo.
3. **Medir en el PC con y sin grupo** con el mismo recorrido (andar, puente, interacción, entrada al combate y
   vuelta), apuntando equipo, commit, tiempos por fotograma y memoria.
4. **APK nueva y memoria publicada.**

## Pendiente del usuario

- Probar la v44 en el móvil:
  - el cofre: si se ve y se oye bien;
  - la cinemática;
  - el grupo.
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
