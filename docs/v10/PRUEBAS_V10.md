# Pruebas de la V10

Rama LOCAL `claude/rebelum-v10`. Todas las pruebas se ejecutaron **aisladas**, con APPDATA, LOCALAPPDATA, TEMP y TMP
redirigidos y comprobados con `sonda_datos.gd`. Se lanzaron desde PowerShell con `ci_local.ps1` o con
`aethelgard/pruebas/ejecutar_pruebas.ps1`.

## Batería completa

| Momento | Commit | Resultado | Resumen |
|---|---|---|---|
| Base V10 (V9 tal cual) | `3795769` | 100 superadas · 0 fallidas · 43 manuales · 0 no seguras | `D:\REBELUM_diagnostico\pruebas\2026-11-10_203508` |
| Sistemas, narrativa y veta | `d437eca` | 102 · 0 · 43 · 0 | `D:\REBELUM_diagnostico\pruebas\2026-11-10_210828` |
| **Con el distrito 3D** | `ab5077e` | **103 · 0 · 43 · 0** | `D:\REBELUM_diagnostico\pruebas\2026-11-10_213109` |

En las tres pasadas:
- la partida real del PC no cambió (mismo SHA-256 antes y después);
- la carpeta real de datos no cambió;
- no había otro Godot abierto.

En la última, «archivos del proyecto: han cambiado» se debe a `docs/v10/OAKHAVEN_CIUDAD_VIVA.md`, que se escribió
durante la pasada. Ningún archivo del juego cambió.

La huella del combate (`prueba_combate_huella`) sigue superada: las magias, el ATB y las fórmulas no han cambiado.

## Pruebas nuevas

| Prueba | Qué comprueba |
|---|---|
| `prueba_oakhaven_v10` | forja, armaduras y botica (servicios, investigaciones, recetas y mejoras por pieza de una vez); la runa al equipar; encargo A con las dos decisiones; encargo B de principio a fin; la botica y el Bálsamo |
| `prueba_veta_garganta` | sin el encargo no hay veta; con la pista sí; da 1 hierro y el hito una vez; `gg_veta` con Lya y Garon; sin ellos, sin diálogo |
| `prueba_distrito_oakhaven` | distrito 3D en alto y bajo: modelos, presupuesto, choques, Kael andando a cada punto, botones, diálogo → servicio, pozo, que no se entra en la herrería ni en los jardines, y el martillo de Ferro |

## Pruebas antiguas adaptadas

En ningún caso se cambió lo que esperan.

- **`prueba_oakhaven`:** habla con todos los vecinos. Ahora cierra el servicio que abren Ferro, Hilda y Mirta, como
  haría quien juega: mientras está abierto, la ciudad retiene los avisos.
- **`prueba_ciudad_datos`:** un diálogo que exige un héroe del grupo (`grupo:Lya`) no cuenta a ese héroe como segundo
  vecino.
- **`prueba_distrito_oakhaven`** (de gráficos): ahora sigue el camino diálogo → servicio, que ya existe en la rama.

## Lo que las pruebas no cubren

- Cómo se ve y se juega en el móvil, y los FPS: está en `PENDIENTES_REDMI.md`.
- El Bálsamo y la runa dentro de un combate entero (está observado en el código).
- Cómo suenan las cosas: una prueba muda no demuestra cómo se oye algo.
