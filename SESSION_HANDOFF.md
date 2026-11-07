# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-07 a las 16:55 (hora local, UTC+1), al terminar T-021 en el PC.

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `03b960a`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Primera publicación: `b50a4da` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| Procesos en marcha | Ninguno a las 16:51: ni Godot, ni adb, ni Java |

## Lo que se hizo desde las 16:30

1. **Memoria publicada** en `memoria-desarrollo` (`b50a4da`) y comprobada en GitHub. La exportación del chat se quedó
   fuera.
2. **Trabajo a medias de `rebelum-alpha` comprobado:** era idéntico byte a byte a su respaldo (el parche y el `.tar`).
   Se reutilizó sin aplicar nada.
3. **Memoria accesible desde `D:\Aethelgard_alpha`:**
   - un `CLAUDE.md` puntero, sin seguimiento y que no se confirma nunca, que importa `D:\Aethelgard\CLAUDE.md`;
   - además, `git show memoria-desarrollo:<archivo>` funciona desde esa copia.
4. **Inventario de licencias** (`e8b9ed4`): [T-070](TASKS.md#t-070) y `docs/versiones/inventario_licencias.md` en
   `rebelum-alpha`.
5. **T-021 terminada en el PC:** commits `d066fe9`, `f039c72`, `a89a8a5` y `03b960a`. Pastos Verdes 3D se juega
   desde el mapa de la app experimental: encuentros, combate con vuelta, guardado y salidas
   ([D-051](DECISIONS.md#d-051)).
6. **Pruebas:**
   - `prueba_zona3d` superada: el combate de verdad y vuelta a 0,00 m.
   - Batería completa `2026-11-07_164526`: 18 superadas, 0 fallidas, 10 manuales y 0 no seguras. La partida real no
     cambió.
7. **APK:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-03b960a.apk`.
   - 244,7 MB, paquete `com.aethelgard.experimental` y firma verificada.
   - SHA-256 `1a2b43178cd4ff1944a71d205a879af79e2d9b1aaa4b7e6297e74980d04ef08b`.
   - Es de prueba privada, con el aviso `NO_DISTRIBUIR`.

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria (su versión publicada está en `memoria-desarrollo`) y los cambios
  del usuario, sin tocar (bloque B y otros).
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero, que no se confirma nunca.

## Límites de lo comprobado

- Las pruebas van sin ventana. **Falta ver la región con ventana**, sobre todo las marcas de salida (el círculo dorado
  y el letrero).
- **No se ha probado en el Redmi:** la APK está lista para cuando el usuario lo conecte (T-078).
- Las 10 pruebas manuales (capturas) no se han revisado en esta sesión.

## Próximo paso concreto

[T-022](TASKS.md#t-022), región completa, en `D:\Aethelgard_alpha\aethelgard\zonas3d\pastos_verdes_3d.gd`:
- Lya y Garon siguiendo a Kael;
- Tilo (`dialogos/pv_tilo*.dtl`), la estela («pastos_estela») y un cofre;
- el combate fijo «pastos_centinela»;
- la misión PV-02 → PV-14.

**Éxito:** del plan 3D, punto 2.5: la misión se completa en el PC, los hitos sobreviven a guardar y cargar, y las
pruebas pasan aisladas.

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
