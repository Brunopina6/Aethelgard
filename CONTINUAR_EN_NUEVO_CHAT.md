# CONTINUAR EN UN CHAT NUEVO — REBELUM (10/11/2026, 21:50)

Para una conversación nueva de Claude Code. Léelo entero antes de tocar nada.

## Quién y qué

- **El usuario y el juego:**
  - el usuario es principiante, escribe en español y quiere las respuestas en español sencillo;
  - REBELUM (nombre técnico Aethelgard) es un JRPG en Godot 4.7.2 (Compatibility), Android primero (Redmi A7 Pro,
    Mali-G57);
  - repositorio privado `Brunopina6/Aethelgard`.
- **Normas permanentes:** `D:\Aethelgard\CLAUDE.md`, obligatorio. Protocolo de inicio:
  1. comprobar la rama `memoria-desarrollo`;
  2. leer `SESSION_HANDOFF.md`, `TASKS.md` y `MEMORIA_CHAT.md` en `D:\Aethelgard`;
  3. contrastar con Git.
- **El usuario acepta que se trabaje sin preguntar** dentro del encargo. Los límites de CLAUDE.md siguen valiendo
  siempre.

## Dónde está el trabajo

- **Rama de trabajo actual:** `claude/rebelum-v10`, copia **`D:\Aethelgard_v10`**.
  - Mírala con `git -C D:\Aethelgard_v10 log -1`. El último código está en `c2eb155`; después, solo documentos.
  - Es **LOCAL**: no está en GitHub.
  - Nace de `claude/rebelum-v9` @ `3795769` (fase 3 y V9) y añade la directiva V10, «Oakhaven, el corazón vivo del
    reino»:
    - servicios de Ferro, Hilda y Mirta;
    - mejoras por pieza;
    - dos encargos;
    - el distrito de los oficios en 3D.
- **Lo subido a GitHub con autorización:** `integracion-experimental` @ `b4e26e2` (fase 2) y la memoria
  (`memoria-desarrollo`).
- **Leer primero:**
  1. `D:\Aethelgard_v10\docs\v10\RETOMAR.md`: estado de Git, pruebas, APK y siguiente paso.
  2. `D:\Aethelgard_v10\docs\v10\ESTADO_V10.md`: los hitos de la V10, hecho o pendiente, y los problemas conocidos.
  3. `D:\Aethelgard_v10\docs\v10\DISENO_V10.md`: el contrato técnico (identificadores, recetas y encargos).

## Reglas de esta etapa

- **NO fusionar ni subir** `claude/rebelum-v10` ni `claude/rebelum-v9` sin autorización expresa del usuario.
- **La APK de la V10 no está validada en el Redmi:**
  - es la **v520**, en `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-c2eb155.apk`;
  - es la app aparte «REBELUM Auditoría»;
  - lleva recursos con licencia pendiente: **no va a GitHub**;
  - la v499 es de la V9: no sirve para probar la V10.
- **El Redmi:**
  - solo recibe APK de prueba;
  - la instala el usuario desde Descargas, porque MIUI cancela el USB si nadie pulsa;
  - nunca se tocan la app estable ni sus datos.
- **Pruebas:**
  - desde **PowerShell**: `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`, en `D:\Aethelgard_v10`;
  - la última dio 103 superadas, 0 fallidas, 43 manuales y 0 no seguras;
  - nunca declarar superado lo que no se ha ejecutado.
- **Git:**
  - nada destructivo;
  - nunca `git add .`;
  - commits en español terminando con «Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>»;
  - no cambiar de rama en `D:\Aethelgard` (copia del usuario, con trabajo suyo sin confirmar).
- **Datos:** la partida real del PC no se toca; todas las pruebas usan datos aislados.
- **Canon:**
  - Ferro, Hilda, Mirta, los encargos y los textos del pozo son propuestas pendientes del usuario;
  - sin revelar antes del acto III que Érebo guarda corazones o recuerdos;
  - nada de Final Fantasy X.

## Siguiente paso concreto

1. **Si el usuario tiene el Redmi:** copiar la v520 a Descargas y comprobarla. El usuario la instala. Después se valida
   con `docs/v10/PENDIENTES_REDMI.md`.
2. **Si no,** lo pendiente de `ESTADO_V10.md`, una cosa cada vez y con su prueba:
   - el sonido del distrito (martillo, fragua y pozo, y los pasos de la calle nueva);
   - las rutinas 3D de Hilda y Mirta;
   - una prueba de combate del Bálsamo y la runa.
3. **Los especialistas** (`.claude/agents/` en `D:\Aethelgard`) se lanzan con copias propias, creadas con
   `git worktree add -b claude/v10-<tarea> D:\Aethelgard_v10_<tarea> claude/rebelum-v10`. El coordinador revisa e
   integra su trabajo en `claude/rebelum-v10`.
