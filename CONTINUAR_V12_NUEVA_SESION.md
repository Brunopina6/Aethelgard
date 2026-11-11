# Continuar la V12 en una sesión nueva (REBELUM / Aethelgard)

Pega esto en una conversación nueva de Claude Code:

> Lee D:\Aethelgard\CLAUDE.md y sigue su protocolo de inicio. Después lee
> D:\Aethelgard_v12\CONTINUAR_V12_NUEVA_SESION.md y D:\Aethelgard_v12\docs\v12\RETOMAR.md, y continúa la V12
> («El Mar de Cristal») desde su «Falta para que cargue». Trabaja de forma autónoma, sin preguntas técnicas.
> No hagas push ni merge (tampoco de la memoria). Integra el trabajo de los especialistas solo si está terminado y
> revisado.

## Qué es y dónde está

- **REBELUM:** JRPG en Godot 4.7.2 (Compatibility), Android primero (Redmi A7 Pro). El usuario escribe en español
  sencillo y es principiante.
- **V12:** rama LOCAL `claude/rebelum-v12` en `D:\Aethelgard_v12`. Nace de la V11 (`claude/rebelum-v11`,
  `D:\Aethelgard_v11`, cerrada y probada en el Redmi con la v542).
- **El encargo del usuario** (11/11), por prioridad:
  1. el primer sector del Mar de Cristal (lugar 4 del mapa, «Mar de Arena de Calid»), muy bonito: relieve, sombras,
     luz cálida, viento y arena en movimiento, oasis, ruinas, caravana, cañón, campamento con NPC, secretos y un
     acontecimiento que no sea un combate;
  2. tormentas de arena que afecten al juego: visibilidad, luz, sonido; el buscador falla y no se puede excavar;
     cobijo; controladas, nunca dejan atrapado a nadie;
  3. el buscador de metales de Kael, jugable, con progresión por investigaciones y sin duplicar recompensas al
     recargar;
  4. la misión «La caravana perdida», completa, con pistas de la Reina de los Espejismos (el jefe **no** está hecho);
  5. criaturas del desierto originales (no Slimes recoloreados) y **el gusano gigante**, original de REBELUM, con
     vibraciones, surcos y rugidos, y una aparición espectacular;
  6. estabilidad: colisiones, caminos, guardado, regresión, FPS y memoria; LOD y culling si se demuestra que ayudan.
- **Contrato técnico:** `docs/v12/DISENO_V12.md`, con los sitios, la misión con sus hitos `mc_*`, los archivos de cada
  uno y las reglas del desierto.
- **Estado exacto y siguiente paso:** `docs/v12/RETOMAR.md`.

## Reglas que no cambian

- Sin push, merge, release ni APK oficial.
  - Las APK de auditoría se pueden compilar en el PC con `compilar_apk_experimental.ps1 -Preset "Android auditoría"`.
  - Al Redmi solo se copian a Descargas por USB; las instala el usuario si MIUI pide confirmación.
- **Datos:**
  - la partida real del PC no se toca;
  - las pruebas, con `aethelgard\pruebas\ejecutar_pruebas.ps1` o `ci_local.ps1` desde PowerShell, siempre aisladas;
  - en el Redmi, solo la app «REBELUM Auditoría», con un respaldo de su partida antes de tocarla y restaurándola
    después.
- Nunca `git add .`. Commits pequeños en español que terminan con
  «Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>».
- **Canon:**
  - todo lo nuevo es PROPUESTA;
  - nada de que Érebo guarda corazones o recuerdos antes del acto III;
  - nada de Final Fantasy X;
  - el Lente del Sol (canon de Calid) no se revela.
- **No declarar terminado** lo que no esté probado, y nunca rendimiento Android sin probarlo en el teléfono.

## Lo último verificado

- **V11:** batería 108 · 0 · 43 · 0 en `6c6dc27`. En el Redmi (v542): el gremio, el minijuego, el élite, el panel y
  Filo Arcano.
- **V12:**
  - `e9eebf1`: el contrato técnico;
  - `9531bd4`: el esqueleto del desierto, EN OBRAS, sin enganchar al juego y sin probar.
