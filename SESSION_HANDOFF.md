# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-07 a las 16:40 (hora local, UTC+1), justo antes de la primera publicación de la
memoria.

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local y nunca subida. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `c2a524c`, local |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`, que sale de `desarollo` (`2d1adc4`) |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, la etiqueta `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| Procesos en marcha | Ninguno a las 16:30: ni Godot, ni adb, ni Java. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Objetivo de la sesión y resultado

- **15:40-16:30, tarea de memoria:** los documentos de continuidad están hechos y verificados (T-001).
- **16:30, nuevas órdenes del usuario:**
  1. Publicar la memoria en `memoria-desarrollo` (D-049). Es lo que se hace ahora (T-002).
  2. Retomar el encargo único por Pastos Verdes 3D (T-021). Antes hay que verificar el trabajo a medias de
     `rebelum-alpha` y su respaldo, y asegurar el acceso a la memoria desde `D:\Aethelgard_alpha`.
  3. Inventariar las licencias pendientes y los usos que bloquean (D-050).

## Cambios sin confirmar

**En `D:\Aethelgard`**
- Los documentos de memoria, sin seguimiento: los siete de la raíz y `docs/memory/`. Su versión publicada está en
  `memoria-desarrollo`.
- Los cambios del usuario (el bloque B y otros), sin tocar. Siguen idénticos al respaldo de las 15:18.

**En `D:\Aethelgard_alpha`** (Fase 1 del encargo, a medias y sin probar)
- Modificados: `aethelgard/mapa.gd`, `aethelgard/progreso.gd` y `aethelgard/project.godot`.
- Nuevos: `aethelgard/modo3d.gd`, `aethelgard/dialogos/pv_*.dtl` (8) y `dialogos/personajes/{garon,tilo}.dch`.
- Hay copia en `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico\`.

## Pruebas: la última evidencia

- **`rebelum-alpha`**, pasada `2026-11-07_152737`: 17 superadas, 0 fallidas, 10 manuales y 0 no seguras.
- El trabajo a medias de la Fase 1 **no se ha probado todavía**.

## Errores pendientes y bloqueos

- **Riesgo de guardado:** [T-076](TASKS.md#t-076).
- **Bloqueos que dependen del usuario:**
  - licencias ([T-070](TASKS.md#t-070));
  - decisiones de narrativa, Érebo, Skills y GitHub (T-071 a T-074);
  - el bloque B ([T-075](TASKS.md#t-075));
  - el Redmi ([T-078](TASKS.md#t-078)).

## Próximo paso concreto

1. Verifica el trabajo a medias: `git -C D:\Aethelgard_alpha diff` frente a
   `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico\rebelum-alpha_fase1_parcial_sin_confirmar.patch`. No
   apliques el parche: ese trabajo ya está en la copia.
2. Sigue con [T-021](TASKS.md#t-021):
   - crea `D:\Aethelgard_alpha\aethelgard\zonas3d\pastos_verdes_3d.gd` y `.tscn`, y la prueba `prueba_zona3d`;
   - ejecuta `aethelgard\pruebas\ejecutar_pruebas.ps1`.
   - **Éxito:** se entra y se sale de Pastos Verdes 3D desde el mapa de la compilación experimental, y todo pasa
     aislado.

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Encargo único:** reanudado ([D-046](DECISIONS.md#d-046)).
  - Cambios pequeños, reversibles y comprobados.
  - Se puede compilar y probar en local.
  - Al terminar, avisar al usuario para una prueba en el móvil.
- **Push:** solo de la documentación de memoria, en `memoria-desarrollo` ([D-049](DECISIONS.md#d-049)).
- **Git:** nada en `main` ni en `desarollo`; nada destructivo; no tocar el bloque B.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Redmi:** reservado.
- **Licencias:** recursos autorizados o sustitutos. El paquete entregable no lleva nada sin acreditar
  ([D-050](DECISIONS.md#d-050)).
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)).
