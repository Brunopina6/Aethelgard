# RETOMAR — Directiva V9 (10/11/2026, tarde)

Escrito para leerlo sin saber programar.

## Dónde está todo

- **Rama de la V9:** `claude/rebelum-v9`, copia `D:\Aethelgard_v9`.
  - Nace de la **v293 verificada** (`dca4c1c`).
  - Incluye, tras examinarlo, todo lo validado después: fase 2 y fase 3.
  - Último commit seguro: `4e88022` o el posterior que figure en el registro de git.
  - **No está subida ni fusionada.**
- **Especialistas trabajando ahora**, cada uno en su copia:
  - combate: escalado de enemigos, en `D:\Aethelgard_v9_escalado` (rama `claude/v9-escalado`);
  - gráficos: el Claro del Guardián con Blender, en `D:\Aethelgard_v9_sector` (rama `claude/v9-sector`).
  - Lo que entreguen se revisa y se fusiona en `claude/rebelum-v9`.
- **El resumen de cada hito** está en `ESTADO_V9.md`.

## Qué está terminado (y probado en el PC)

- La primera gran aventura de Pastos Verdes:
  - investigación con exploración;
  - materiales y recetas;
  - el Guardián de dos fases;
  - una decisión que cambia el bosque para siempre;
  - Oakhaven reacciona.
- **El orbe del altar:** enseña los dos futuros del bosque.
- **Los oficios:** forja de Kael, runas de Garon y taller conjunto, además de la alquimia de Lya.
- **El escalado de enemigos por región** y **el Claro del Guardián** (sector 3D de Blender).
- **Batería completa:** 95 superadas, 0 fallidas.

## Qué queda pendiente (por orden)

2. Probarlo todo en el Redmi: `docs/fase3_bosque/PENDIENTES_REDMI.md`, más el orbe y los talleres.
3. El cuarto protagonista (magia negra). Antes, revisar el «Mago negro» antiguo de `grupo.gd`.
4. **Siguientes jefes:**
   - el Coloso de la Falla (Garganta 3D);
   - el Campanero del Porvenir;
   - el Emperador Slime (opcional).
5. El sistema de encargos reutilizable y la ampliación de Oakhaven. Oakhaven ya tiene misiones propias, como la de la
   lavanda, los faroles o los favores: hay que partir de ellas.
6. Sonido y música propios del Guardián.

## Cómo continuar

1. En `D:\Aethelgard_v9`, desde PowerShell: `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`. Debe terminar
   con «CI LOCAL: todo superado».
2. APK de pruebas en local: `.\compilar_apk_experimental.ps1 -Preset "Android auditoría"`. Instalarla desde Descargas
   en el Redmi.
3. **Subir a GitHub o fusionar, solo con tu autorización.**
