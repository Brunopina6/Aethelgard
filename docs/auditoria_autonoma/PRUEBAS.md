# PRUEBAS — qué se ha ejecutado de verdad

Todas con `aethelgard/pruebas/ejecutar_pruebas.ps1` lanzado desde PowerShell, con datos aislados (APPDATA, LOCALAPPDATA,
TEMP y TMP redirigidos a la carpeta de cada pasada). En todas: «partida.save real: sin cambios · carpeta real de
datos: sin cambios». Godot 4.7.2 de consola, sin ventana, `--fixed-fps 30`. Resúmenes en `D:\REBELUM_diagnostico\pruebas\`.

**Importación aislada** (antes de probar): `Godot_v4.7.2-stable_win64_console.exe --headless --path
D:\Aethelgard_autonomo\aethelgard --import` con APPDATA, LOCALAPPDATA, TEMP y TMP en
`D:\REBELUM_diagnostico\importaciones\2026-11-10_autonomo`. Después, `git restore aethelgard/project.godot` (ver
RETOMAR.md).

| Hora (10/11) | Pruebas | Resultado |
|---|---|---|
| 11:41 | prueba_guardado_fallos, prueba_guardado, prueba_guardado_protegido, prueba_restaurar_escenas | 4 superadas |
| 11:44 | prueba_mapa_cercano, prueba_prologo, prueba_boton_prologo, prueba_partida, prueba_ranura_prueba, prueba_guardado_protegido, prueba_escenas, prueba_mapamundi | 7 superadas, 1 fallida (un caso mal elegido en la prueba nueva del mapa: corregido) |
| 11:45 | prueba_mapa_cercano | superada |
| 11:46 | prueba_ia, prueba_equilibrio (antes de convertirlas) | «superadas» sin comprobar nada (falso positivo detectado) |
| 11:47 | prueba_ia, prueba_equilibrio (convertidas) | 2 superadas |
| 11:48 | prueba_choque, prueba_andar, prueba_tema, prueba_garon, prueba_cofre, prueba_dpad (+3 manuales) | 5 superadas, 1 fallida (error mío en la conversión de prueba_choque: corregido) |
| 11:50 | prueba_choque | superada |
| 11:51 | prueba_tema (lanzador con REBELUM_GODOT) | superada |

Pendiente: la batería completa sobre la rama al cerrar cada fase grande.
