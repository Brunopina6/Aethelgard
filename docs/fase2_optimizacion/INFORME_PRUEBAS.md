# C. INFORME DE PRUEBAS — Fase 2 (10/11/2026)

**Cómo se ejecutaron:**
- con `aethelgard/pruebas/ejecutar_pruebas.ps1`, desde PowerShell, sin ventana;
- con datos aislados (APPDATA, LOCALAPPDATA, TEMP y TMP redirigidos);
- en todas las pasadas, «partida.save real: sin cambios · carpeta real de datos: sin cambios».

## Batería completa

| Cuándo | Rama y commit | Superadas | Fallidas | Manuales | No seguras | Resumen |
|---|---|---|---|---|---|---|
| 13:08 | `integracion-experimental` `218155a` (auditoría fusionada) | 79 | 0 | 41 | 0 | `pruebas\2026-11-10_130828` |
| 13:24 | ídem + especialistas `4cb20cc` | 81 | **1** | 41 | 0 | `pruebas\2026-11-10_132426` |
| 13:35 | ídem + corrección `c75806b` | 82 | 0 | 41 | 0 | `pruebas\2026-11-10_133548` |
| 14:09 | **fase 2** `8381d75` | **86** | **0** | 41 | 0 | `pruebas\2026-11-10_140944` |

(Rutas dentro de `D:\REBELUM_diagnostico\`.)

**La fallida de las 13:24** fue `prueba_boton_prologo`:
- era un cierre del Godot sin ventana (ver informe B);
- tras la corrección pasó 4 de 4 veces sola y en la batería completa.

## Pruebas nuevas de la fase 2 (automáticas)

| Prueba | Qué comprueba | Resultado |
|---|---|---|
| `prueba_recompensas` | `combate_recompensas.gd` da lo mismo que el código de antes en 2000 casos al azar y en los bordes | superada |
| `prueba_datos` | datos reales sin errores; la Corteza espinosa igual que antes; 15 errores a propósito detectados (ids repetidos o mal escritos, referencias rotas, requisitos no válidos…) | superada |
| `prueba_investigacion` | requisitos, estados, recetas en borrador, fabricar todo o nada, guardar y leer, y partida antigua sin la clave | superada |
| `prueba_precarga` | no falta ninguna textura que use un modelo; nada de lo quitado lo nombra un script; perfiles de Oakhaven 3D | superada |

**Además:**
- `prueba_combate_huella`: los 9 combates, idénticos a la referencia (`725aef4a…`) antes y después de separar las
  recompensas.
- `prueba_calidad_auto` (del especialista de rendimiento) pasa en la batería integrada.

## Cobertura de lo que pedía la orden

| Pedido | Prueba |
|---|---|
| Guardados antiguos | `prueba_formato_regiones`, `prueba_partida`, `prueba_investigacion` (parte 3), `prueba_guardado_fallos` |
| Transiciones entre regiones | `prueba_escenas`, `prueba_restaurar_escenas`, `prueba_mapamundi`, `prueba_zona3d` |
| Carga y descarga de recursos | `prueba_precarga` (nueva), `auditar_recursos` |
| Combates con distintas configuraciones | `prueba_combate_huella` (9), `prueba_combate_seguro` (5 semillas), `prueba_patrones_enemigos` |
| Equipo y estadísticas | `prueba_armas_especiales`, `prueba_equilibrio` |
| Ids duplicados, recursos que no existen, datos no válidos | `prueba_datos` (nueva), `auditar_recursos` |
| Estados de investigación que se guardan | `prueba_investigacion` (nueva) |
| **Funcionamiento en Android** | **no ejecutada: el Redmi no estaba** (el usuario pidió no usar ADB) |

## Manuales y no ejecutadas

- **41 manuales:** necesitan ventana o una persona (capturas, toques y escucha). Se listan en cada resumen. No cuentan
  como superadas.
- **No ejecutadas (Android), todas pendientes:**
  - arranque, memoria y FPS en el Redmi;
  - la calidad Automática;
  - Pastos Verdes 3D, Garganta 3D y combate con esta rama.
