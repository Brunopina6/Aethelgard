# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-07 a las 17:10 (hora local, UTC+1), con la misión del corte alfa hecha en el PC.

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `549e3d8`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| Procesos en marcha | Ninguno a las 17:07. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

## Lo que se hizo desde las 16:30

1. **Memoria publicada** en `memoria-desarrollo` y comprobada en GitHub. La exportación del chat se quedó fuera.
2. **Trabajo a medias** de `rebelum-alpha`: era idéntico a su respaldo y se reutilizó sin aplicar nada.
3. **Acceso a la memoria desde `D:\Aethelgard_alpha`:** con el `CLAUDE.md` puntero (sin seguimiento, no se confirma
   nunca) y con `git show memoria-desarrollo:<archivo>`.
4. **Inventario de licencias** (`e8b9ed4`): ver [T-070](TASKS.md#t-070).
5. **T-021 terminada en el PC:** Pastos Verdes 3D desde el mapa, con encuentros, combate y vuelta, guardado y salidas
   (`d066fe9`, `f039c72`, `a89a8a5` y `03b960a`).
6. **T-022 en curso** (`e212400`): la misión PV-02 → PV-14 con Tilo, la estela y el centinela (combate fijo).
   Después, `07ac036` y `549e3d8` confirman los `.uid` que generó Godot.
7. **Pruebas:** batería aislada `2026-11-07_170431`, con 19 superadas (`prueba_zona3d` y `prueba_ruta_alpha`
   incluidas), 0 fallidas, 10 manuales y 0 no seguras. La partida real no cambió.
8. **APK para la prueba en el móvil:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-07ac036.apk`.
   - 244,7 MB, paquete `com.aethelgard.experimental` y firma verificada.
   - SHA-256 `f63e99b18f5172705454d12ec25e693ae35beacd2e29848925f018cb6cf444b9`.
   - Es de prueba privada, con el aviso `NO_DISTRIBUIR`.

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (publicados en `memoria-desarrollo`) y los cambios del usuario, sin
  tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- Las pruebas van sin ventana. **Falta ver con ventana** a Tilo, la estela y las marcas de salida.
- **El combate del centinela** carga de verdad, pero la victoria se simuló en la prueba.
- **No se ha probado en el Redmi** (T-078).

## Próximo paso concreto

**T-022**, en `D:\Aethelgard_alpha\aethelgard\zonas3d\pastos_verdes_3d.gd`:
- Lya y Garon siguen a Kael en el 3D (`maga_3d.gd` y `garon_3d.gd`);
- un cofre (`cofres_abiertos`);
- la cinemática del mirador.

**Éxito:**
- las pruebas aisladas pasan;
- el coste del grupo se mide en el PC con RND;
- en el Redmi, cuando el usuario lo conecte: perfil bajo con el grupo, mediana ≤ 33,3 ms (plan 3D, 2.4).

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Encargo único:** reanudado ([D-046](DECISIONS.md#d-046)). Cambios pequeños, reversibles y comprobados; se puede
  compilar y probar en local; al final, avisar para la prueba en el móvil.
- **Push:** solo de la memoria, en `memoria-desarrollo` ([D-049](DECISIONS.md#d-049)). Nada de push de
  `rebelum-alpha`.
- **Git:** nada en `main` ni en `desarollo`; nada destructivo; no tocar el bloque B.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Redmi:** reservado.
- **Licencias:** recursos autorizados o sustitutos. El paquete entregable no lleva nada sin acreditar
  ([D-050](DECISIONS.md#d-050)).
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)).
