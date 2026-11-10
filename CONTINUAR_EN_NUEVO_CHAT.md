# CONTINUAR EN UN CHAT NUEVO — REBELUM (10/11/2026, 19:20)

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

- **Rama de trabajo actual:** `claude/rebelum-v9`, copia **`D:\Aethelgard_v9`**, último commit seguro: el del traspaso
  del 10/11 a las 19:20.
  - Mírala con `git -C D:\Aethelgard_v9 log -1`.
  - Es **LOCAL**: no está en GitHub.
  - Contiene la fase 3 («El bosque que no recuerda»), la directiva V9 y todo el trabajo de los especialistas.
- **Lo subido a GitHub con autorización:** `integracion-experimental` @ `b4e26e2` (fase 2) y la memoria
  (`memoria-desarrollo`).
- **Leer primero:**
  1. `D:\Aethelgard_v9\docs\v9\RETOMAR.md`: estado de Git, qué hay, pruebas, APK, errores conocidos y pendiente.
  2. `D:\Aethelgard_v9\docs\v9\ESTADO_V9.md`: los hitos de la directiva V9, hecho o pendiente.
  3. `D:\Aethelgard_v9\docs\fase3_bosque\AVENTURA_JUGABLE.md`: el diseño y los identificadores de la aventura.

## Reglas de esta etapa

- **NO fusionar ni subir** `claude/rebelum-v9` (ni `claude/rebelum-bosque-fase3`) sin autorización expresa del usuario.
- **La APK de esta fase no está validada en el Redmi:**
  - la última compilada es la **v499**, en `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-56dfb9c.apk`;
  - es la app aparte «REBELUM Auditoría»;
  - la última validada fue la v420.
- **El Redmi:**
  - solo recibe APK de prueba;
  - la instala el usuario desde Descargas, porque MIUI cancela el USB si nadie pulsa;
  - nunca se tocan la app estable ni sus datos.
- **Pruebas:**
  - desde **PowerShell**: `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`, en `D:\Aethelgard_v9`;
  - la última dio 100 superadas, 0 fallidas, 43 manuales y 0 no seguras;
  - nunca declarar superado lo que no se ha ejecutado.
- **Git:**
  - nada destructivo;
  - nunca `git add .`;
  - commits en español terminando con «Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>»;
  - no cambiar de rama en `D:\Aethelgard` (copia del usuario, con trabajo suyo sin confirmar).
- **Datos:** la partida real del PC no se toca; todas las pruebas usan datos aislados.
- **Canon:** sin revelar antes del acto III que Érebo guarda corazones o recuerdos, y nada de Final Fantasy X.

## Siguiente paso concreto

1. **Si el usuario tiene el Redmi:** que instale la v499 y se valide con `docs/fase3_bosque/PENDIENTES_REDMI.md`, más
   el orbe, los talleres de Kael y Garon, el Coloso de la Falla y «Canela se ha perdido».
2. **Si no:** seguir con los hitos pendientes de la V9, uno cada vez y con su prueba:
   - el Campanero del Porvenir;
   - los efectos de sonido del Coloso;
   - el cuarto protagonista de magia negra (revisar antes el «Mago negro» Nyx de `grupo.gd`);
   - la ampliación de Oakhaven y más encargos;
   - el Emperador Slime.
3. **Los especialistas** (`.claude/agents/` en `D:\Aethelgard`) se lanzan con copias propias, creadas con
   `git worktree add -b claude/v9-<tarea> D:\Aethelgard_v9_<tarea> claude/rebelum-v9`. El coordinador revisa e
   integra su trabajo en `claude/rebelum-v9`.
