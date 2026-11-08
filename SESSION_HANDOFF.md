# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 14:50 (hora local, UTC+1), tras subir la APK de prueba al repositorio
privado para el móvil.

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `ce84422`, local. Aquí se editan los documentos de memoria |
| Árbol del encargo | `D:\Aethelgard_alpha`, rama `rebelum-alpha` @ `aabe5ad`, local y nunca subida |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo`. Las publicaciones se ven con `git log origin/memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo` (solo memoria) |
| APK de prueba para el móvil | `Brunopina6/Aethelgard-pruebas`, privado: una versión por APK. La última está en `releases/latest` ([D-054](DECISIONS.md#d-054)) |
| Procesos en marcha | Ninguno a las 14:46 del 08/11. Compruébalo antes de lanzar Godot: dos Godot sobre el mismo proyecto se pisan |

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

## En marcha: validación en el Redmi, pedida por el usuario («Probemos en el Redmi», 07/11)

- **APK:** `Aethelgard_exp-20261107-989d35e.apk` (commit `989d35e`), instalada en el Redmi por el usuario desde
  Descargas el 08/11. `adb install` falló dos veces con `INSTALL_FAILED_USER_RESTRICTED`, porque Xiaomi pide
  confirmarla en la pantalla.
- **No se ha tocado nada más del móvil:** la app estable, «Aethelgard Prueba 3D» y las APK antiguas siguen igual.
- **Banco PRUEBA** (08/11, hacia las 10:30), sin tope de FPS y con la región tal como está, sin seguidores:

  | Perfil | Distancia | FPS | Mediana | p95 | CPU de dibujo | Llamadas | Memoria de vídeo |
  |---|---|---|---|---|---|---|---|
  | bajo | 20 m | 42,5 | 21,5 ms | 38,4 ms | 7,1 ms | 80 | 414 MB |
  | bajo | 34 m | 35,6 | 27,1 ms | 49,6 ms | 6,0 ms | 113 | 414 MB |
  | medio | 20 m | 28,0 | 35,5 ms | 41,5 ms | 7,8 ms | 163 | 416 MB |
  | medio | 34 m | 23,0 | 44,0 ms | 48,2 ms | 7,2 ms | 143 | 416 MB |
  | alto | 20 m | 10,5 | 93,0 ms | 133,7 ms | 18,0 ms | 173 | 421 MB |
  | alto | 34 m | 8,7 | 116,8 ms | 125,5 ms | 10,0 ms | 221 | 421 MB |

  - Tiempo de GPU: «—», porque el temporizador de Mali no da datos.
  - **Frente al plan 3D, punto 2.1** (bajo a 20 m):
    - mediana ≤ 31 ms: **se cumple** (21,5 ms);
    - p95 ≤ 38 ms: **no se cumple por 0,4 ms** (38,4 ms);
    - picos > 100 ms y carga ≤ 4 s: sin medir.
  - **Registros:** `D:\REBELUM_diagnostico\redmi_2026-11-08_region\` (`logcat_godot.txt`). El CSV del banco está en
    el móvil, en `files/banco_pastos_verdes_3d.csv`.
- **Banco TOPE** (08/11, hacia las 10:43), con el tope de FPS de cada perfil, «como se jugará»:

  | Perfil | Distancia | FPS | Mediana | p95 | Tirones |
  |---|---|---|---|---|---|
  | bajo, tope 30 | 20 m | 30,1 | 33,4 ms | 34,0 ms | 0,0 % |
  | medio, tope 30 | 20 m | 28,2 | 35,2 ms | 40,8 ms | 0,0 % |
  | medio, tope 30 | 34 m | 23,1 | 44,0 ms | 48,0 ms | 0,5 % |
  | alto, tope 60 | 20 m | 10,8 | 93,2 ms | 101,1 ms | 100 % |

  - **El perfil bajo cumple la meta del encargo:** 30 FPS sostenidos en el Redmi, sin tirones, a la distancia de juego
    (20 m).
  - **Margen:** sin tope, la mediana es de 21,5 ms; quedan unos 12 ms por fotograma para Lya, Garon y lo que venga.
  - **Registros:** `logcat_tope.txt` y `banco_tope.csv`, en la misma carpeta.
- **Error corregido:** `!is_inside_tree()` al recargar la escena entre casos del banco (commit `aabe5ad`). Volvió a
  salir con esta APK, que es anterior al arreglo. Ya está en la APK `aabe5ad`.
- **Validación terminada:** el Redmi vuelve a quedar reservado. Falta la opinión visual del usuario.

## APK en GitHub para el móvil (08/11, 14:46)

- **Petición del usuario,** que está fuera de casa: un sitio en GitHub para descargar las pruebas en el móvil
  ([D-054](DECISIONS.md#d-054) y [T-079](TASKS.md#t-079)).
- **Repositorio:** `https://github.com/Brunopina6/Aethelgard-pruebas`, privado y sin colaboradores.
- **Versión `exp-20261108-aabe5ad`:**
  - APK compilada a las 14:44 desde `rebelum-alpha` @ `aabe5ad`, con versionCode 39 y el mismo certificado: se
    instala encima de la anterior;
  - SHA-256 `06bf212add337a3afda056bd7a79f3d354e84eb2698940e92ee66bee3cdd3b6c`, que coincide con el `digest` de GitHub.
- **Lo instala el usuario.** No se ha tocado el móvil.

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
- **Push:** solo la memoria, en `memoria-desarrollo` ([D-049](DECISIONS.md#d-049)), y las APK de prueba, en el
  repositorio privado `Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)). Nada de push de `rebelum-alpha`.
- **Git:** nada en `main` ni en `desarollo`; nada destructivo; no tocar el bloque B.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Redmi:** reservado.
- **Licencias:** recursos autorizados o sustitutos. El paquete entregable no lleva nada sin acreditar
  ([D-050](DECISIONS.md#d-050)).
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)).
