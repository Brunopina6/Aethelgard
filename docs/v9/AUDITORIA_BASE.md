# AUDITORÍA DE LA BASE — Directiva V9 (10/11/2026)

## La v293, verificada

| Comprobación | Resultado |
|---|---|
| Release en `Brunopina6/Aethelgard-pruebas` | `exp-20261109-dca4c1c`, «09/11/2026 · Prueba v293», publicada el 09/11 a las 21:43 UTC; APK `Aethelgard_Exp_2026-11-09_v293.apk`, 293 147 570 bytes |
| Commit fuente en `Brunopina6/Aethelgard` | `dca4c1c7e76df3880b93c91520bbf2644a6d1e75` (09/11, 18:06 UTC) |
| ¿Son la misma versión? | Sí: la etiqueta lleva `dca4c1c`; el versionCode 293 es el número de commits hasta `dca4c1c` (`git rev-list --count` = 293); la fila del README de pruebas apunta a esa release. El `target_commitish` de la release es el commit del README del repositorio de pruebas, por la norma del proyecto (CLAUDE.md §4), no el del código. |

**Rama nueva:** `claude/rebelum-v9` (copia `D:\Aethelgard_v9`), creada en `dca4c1c`. Nada se cambió en `main`,
`desarollo`, `integracion-experimental` ni en las copias de los especialistas.

## Cambios posteriores a la v293: examinados antes de recuperarlos

`dca4c1c..claude/rebelum-bosque-fase3`: 157 commits, de los que 44 son de primer nivel. Todos son integraciones
revisadas por el coordinador, y cada una pasó la batería completa. Por bloques:

| Bloque | Commits | Validación | ¿Compatible con la V9? |
|---|---|---|---|
| Especialistas del 09/11 noche: combate M4/C2, sonido t6, animaciones T-101, narrativa, Garganta 3D optimizada, Oakhaven 3D tramo 1, Cencerrante | `b86ef60`…`2889213` | baterías del 09/11, subidas a GitHub | Sí. **Cencerrante es de Meshy** (añadido antes de esta orden, con su línea en `licencias_pendientes.txt`); la V9 prohíbe usar Meshy **a partir de ahora**: no se crea nada nuevo con Meshy |
| Auditoría autónoma: guardado seguro, mapa, prólogo, pruebas, combate modular | `218155a` | 79/0 y Redmi (v386/v387) | Sí |
| Especialistas del 10/11: sonido t7, rutinas de Oakhaven, modelos ligeros, calidad adaptable | `f891b0c`…`c75806b` | 82/0 | Sí |
| Fase 2: precarga, recompensas en su módulo, catálogo de datos, base de talleres, teclas del teléfono | `5678bfa`, `b4e26e2` | 87/0 y Redmi (v418/v420: 30 FPS en Pastos Verdes, arranque 19-21 s) | Sí |
| Fase 3, «El bosque que no recuerda»: aventura, alquimia de Lya, Guardián de dos fases (modelo propio de Blender, obra propia), desenlaces y Oakhaven | `bbda8c2`…`dda5473` | 92/0/42/0; APK v449 compilada; **sin Redmi** | Sí: es justo el «Hito 2» y la primera aventura que pide la V9 |

**Decisión:** se recuperan con una fusión explícita (`git merge` de `claude/rebelum-bosque-fase3`). Volver a hacer ese
trabajo desde la v293 perdería lo validado en el teléfono sin ganar nada. Lo que sigue de la V9 se construye encima.
