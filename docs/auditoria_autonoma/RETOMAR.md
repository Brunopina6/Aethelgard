# RETOMAR — trabajo autónomo del 10/11/2026

**Dónde:** worktree `D:\Aethelgard_autonomo`, rama LOCAL `claude/rebelum-autonomo-2026-11-10` (sin push ni PR, por la
orden del propietario). **Base:** `integracion-experimental` local @ `2889213` (la auditoría citaba `dca4c1c`, ya
superado; `2889213` lo incluye). La APK v365 (instalada el 09/11 en el Redmi) se compiló de `808eb98`, anterior a
`2889213`.

**No se ha tocado:** `main`, `desarollo`, `integracion-experimental`, las ramas de los especialistas (tienen trabajo sin
terminar en sus copias), la copia del usuario `D:\Aethelgard` ni ninguna partida real. Nada subido a GitHub.

## Estado por fases

| Fase | Estado | Commit |
|---|---|---|
| 1. Guardado seguro | Hecha y probada | `3762b15` |
| 2. Mapa (lugar más cercano) y prólogo (visto al terminar) | Hecha y probada | `9889d95` |
| 3. Pruebas con aserciones reales | Hecha y probada | `b28bc74` |
| 4. Combate seguro y modular | Pendiente | — |
| 5. Carga y rendimiento | Pendiente | — |
| 6. Preparación modular | Pendiente | — |
| 7. Validación de recursos y cierre | Pendiente | — |

## Cómo seguir

1. `cd D:\Aethelgard_autonomo` (rama `claude/rebelum-autonomo-2026-11-10`).
2. Antes de importar o probar, la importación aislada (ver PRUEBAS.md). **Ojo:** la importación sin editor borra del
   `project.godot` el registro de personajes de Dialogic (`dch_directory`): tras importar, `git restore
   aethelgard/project.godot` (es un cambio que hace la importación, no del trabajo).
3. Siguiente: fase 4 — `prueba_combate_huella` antes de tocar nada del combate.

Detalle: ESTADO.md, CAMBIOS.md, PRUEBAS.md y PENDIENTES_MOVIL.md.
