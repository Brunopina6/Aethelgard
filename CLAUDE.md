# CLAUDE.md: AETHELGARD / REBELUM

REBELUM (nombre técnico **Aethelgard**) es un JRPG de fantasía hecho con **Godot 4.7.2** (renderizador
Compatibility).
- **Plataforma principal:** Android (móvil de pruebas: Redmi con Mali-G57).
- **Plataformas futuras:** PC, Android TV e iOS.
- **Rutas:** repositorio en `D:\Aethelgard`; proyecto de Godot en `aethelgard/` (`project.godot`).
- **Remoto:** GitHub privado `Brunopina6/Aethelgard`.

Este archivo guarda las **normas permanentes**. El estado cambiante vive en los documentos enlazados abajo.

## 1. Protocolo de inicio de sesión (obligatorio)

**Consulta obligatoria de memoria antes de responder o actuar.** Antes de responder a una petición sobre el proyecto
o de modificar archivos:

1. **Comprueba el último commit de la rama `memoria-desarrollo`** del repositorio de GitHub
   `Brunopina6/Aethelgard`, solo leyendo: `git ls-remote origin refs/heads/memoria-desarrollo`.
   - Se creó el 2026-11-07 y solo contiene la documentación de memoria. Su copia de trabajo es `D:\Aethelgard_memoria`.
   - Si el remoto tiene un commit que esa copia no tiene, y la copia está limpia, tráelo con
     `git -C D:\Aethelgard_memoria pull --ff-only`. Después compáralo con los documentos de `D:\Aethelgard`.
   - Si GitHub no responde, usa la última memoria local verificada y dilo en una frase.
   - No afirmes que has consultado GitHub si el acceso falló.
2. **Lee la memoria local,** en este orden:
   1. [SESSION_HANDOFF.md](SESSION_HANDOFF.md)
   2. [TASKS.md](TASKS.md)
   3. el resumen y el índice de [MEMORIA_CHAT.md](MEMORIA_CHAT.md)
   4. los apartados que pida la tarea de [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) y [DECISIONS.md](DECISIONS.md)
3. **Contrasta con el estado real:**
   - `git status`, `git branch -vv`, `git worktree list`, el commit actual y los cambios sin confirmar;
   - qué commit describe cada documento (lo indican en su cabecera).
   - Si hay discrepancias, averigua su origen antes de cambiar nada y conserva el trabajo local.
4. **Actúa** sobre ese estado contrastado y sobre las **instrucciones actuales del usuario**, que prevalecen sobre los
   encargos antiguos.
   - La memoria es documentación histórica: contrástala con el código y con lo que puedas comprobar.

Si ya leíste la memoria en esta sesión, comprueba si el commit remoto ha cambiado y relee solo lo modificado y lo que
pida la tarea.

**Consulta GitHub sin cambiar nada.**
- Usa `git ls-remote`, `git fetch` a referencias remotas o `gh api`.
- **Nunca** hagas `checkout`, `reset` ni `pull` en una copia con trabajo pendiente.

## 2. Durante y al terminar

- **Al completar una tarea importante:**
  - [TASKS.md](TASKS.md): estado y evidencia, con el commit o los archivos;
  - [DECISIONS.md](DECISIONS.md): las decisiones nuevas o sustituidas;
  - [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md): si cambia la arquitectura;
  - el resumen de [MEMORIA_CHAT.md](MEMORIA_CHAT.md);
  - [SESSION_HANDOFF.md](SESSION_HANDOFF.md).
- **Puntos de control:** guarda uno en `SESSION_HANDOFF.md` en cada hito de trabajo, no solo al final. Una
  interrupción o una compactación del contexto pueden llegar sin aviso.
- **Antes de compactar, cambiar de conversación o terminar:** guarda el punto de control.
- **Tamaño de la memoria:**
  - si un documento crece demasiado, archiva el detalle en `docs/memory/archive/AAAA-MM-DD_tema.md` y enlázalo;
  - mantén el relevo centrado en el presente.
- **Publicar la memoria:** el usuario lo autorizó el 2026-11-07 para cada hito. **El push solo vale para la
  documentación de memoria:** nunca código, recursos ni la exportación privada del chat.
  1. Edita los documentos en `D:\Aethelgard`.
  2. Cópialos a `D:\Aethelgard_memoria` (rama `memoria-desarrollo`): los siete de la raíz y `docs/memory/`.
  3. Revisa `git status` y `git diff`, busca datos sensibles y confirma nombrando cada archivo.
  4. Haz `git -C D:\Aethelgard_memoria push origin memoria-desarrollo` y comprueba con `git ls-remote` que llegó.

## 3. Normas permanentes

**Git**
- No escribas en `main` (estable) ni en `desarollo` (desarrollo; se escribe **con una sola r**) sin autorización.
- Nada de push, merge a ramas compartidas, release, despliegue ni publicación sin autorización expresa. Las únicas
  autorizaciones vigentes son estas dos:
  - el push de la memoria (§2);
  - las APK de prueba en el repositorio privado `Brunopina6/Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)).
- Nada destructivo: ni `reset --hard`, ni `push --force`, ni reescribir historial, ni borrados o limpiezas masivas.
  No borres la rama `respaldo-d155a36` ni las etiquetas.
- Nunca `git add .`: commits locales pequeños, nombrando cada archivo, y revisando `git status` y `git diff` antes.
- No cambies de rama en la copia del usuario (`D:\Aethelgard`): para otra rama, usa un **árbol de trabajo
  aparte** (`git worktree`).
- Los cambios sin confirmar del usuario (el llamado «bloque B») no se tocan ni se confirman sin su permiso.

**Partidas y datos**
- La partida actual del PC (`%APPDATA%\Godot\app_userdata\Aethelgard\partida.save`) **se conserva tal cual**, aunque le
  falte la clave `grupo`, porque así lo decidió el usuario. No la restaures ni ofrezcas restaurarla.
- La copia histórica `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0\partida.save` queda **intacta**.
- **Toda prueba usa datos aislados:**
  - `aethelgard/pruebas/ejecutar_pruebas.ps1` redirige `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP` y lo comprueba con
    `sonda_datos.gd`;
  - no ejecutes el juego de forma que pueda escribir en la partida real.

**Móvil, licencias e instalaciones**
- **El Redmi está reservado.** Nada de ADB, USB, MTP, conexión inalámbrica ni escritorio remoto. No copies, instales,
  actualices ni borres APK en el móvil. Pide al usuario que lo conecte cuando haga falta validar algo en él.
- No distribuyas ningún APK que lleve recursos de licencia pendiente (lista en
  [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt)). Eso incluye GitHub.
  - Las compilaciones locales para pruebas sí están permitidas.
  - **Excepción, desde el 2026-11-08 ([D-054](DECISIONS.md#d-054)):** las APK de prueba pueden ir a
    `Brunopina6/Aethelgard-pruebas` para que el usuario las descargue en su móvil.
    - No cuenta como distribución si el repositorio sigue privado, sin colaboradores y sin enlaces compartidos.
    - Una APK con música de Suno no se sube sin preguntar antes.
  - La música de Suno, solo en pruebas privadas locales, fuera de los commits y de cualquier APK entregable.
- No instales herramientas ni compres recursos.
- No cambies ajustes globales, permisos, credenciales ni claves de firma.
- No subas archivos del proyecto a servicios externos sin autorización.
- No pongas en la documentación secretos, claves, el número de serie del móvil ni registros sin revisar.

**Diseño**
- **Calidad visual primero.** No sacrifiques belleza por rendimiento sin medirlo y sin mostrar el antes y el después.
  El perfil alto nunca se rebaja para que quepan los demás.
- **Conserva las magias existentes** y su comportamiento: ID, coste, daño, objetivos y animaciones (Fuego,
  Llamarada, Infierno, Agua, Torrente, Maremoto, Rayo, Tormenta, Cólera del Cielo, Cura, Bendición y Gracia Divina).
  Conserva también Esgrima, Embuir, Érebo, la Armonía y el ATB. Las ampliaciones son plan futuro.
- **Narrativa:**
  - las propuestas de la biblia v3 no son canon hasta que el usuario las apruebe;
  - no reveles antes del acto III que Érebo guarda corazones o recuerdos;
  - **no reveles detalles de Final Fantasy X**: el usuario todavía no lo ha jugado;
  - FFIX, FFVII y Expedition 33 sirven solo como referencia de principios, sin copiar diseños, escenas ni argumentos.

**Comprobaciones**
- Distingue siempre entre:
  - **observado en el código**;
  - **comprobado ejecutando** (aislado);
  - **del historial**;
  - **pendiente de verificar**.
- Indica la fecha y el commit de cada comprobación.
- Una prueba muda no demuestra cómo se oye algo. Una escena que solo se abre en el editor no está integrada.

## 4. Convenciones

- **Idioma:** español en los documentos, los commits, los comentarios y los textos del juego.
- **Commits:** terminan con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Pruebas:** sin ventana, con `--fixed-fps 30`, mediante `aethelgard/pruebas/ejecutar_pruebas.ps1`. Da 4 resultados
  (SUPERADA, FALLIDA, MANUAL y NO SEGURA) y devuelve un código de salida.
- **Compilación local:** `compilar_apk_experimental.ps1 [-Preset "…"]` se niega a compilar la app estable, exporta en
  un entorno aislado y comprueba licencias, firma y paquete.
- **Carpetas fuera del proyecto:**
  - `D:\REBELUM_diagnostico`: registros;
  - `D:\REBELUM_compilaciones`: APK;
  - `D:\REBELUM_respaldos`: respaldos (nunca se sobrescriben: carpetas con fecha).
- **Godot de consola:** `C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe`. Dos Godot sobre
  el mismo proyecto se pisan, así que comprueba que no haya otro abierto.
- **Skills:**
  - `.claude/skills/aet-*` (26) están desfasadas: ver [docs/herramientas/propuesta_skills.md](docs/herramientas/propuesta_skills.md);
  - `.agents/skills/` es una copia para otro agente, sin seguimiento: no la toques.

## 5. Mapa de documentos

| Documento | Para qué |
|---|---|
| [SESSION_HANDOFF.md](SESSION_HANDOFF.md) | Fotografía del último estado y siguiente paso concreto |
| [TASKS.md](TASKS.md) | Tareas con identificador, estado, criterio de aceptación y evidencia |
| [MEMORIA_CHAT.md](MEMORIA_CHAT.md) | Lo aprendido en las conversaciones: peticiones, correcciones, diagnósticos y matices |
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | Arquitectura real, sistemas y rutas; qué está integrado y qué es prototipo |
| [DECISIONS.md](DECISIONS.md) | Decisiones aprobadas, propuestas y sustituidas, con sus motivos |
| [CONTINUAR_EN_NUEVO_CHAT.txt](CONTINUAR_EN_NUEVO_CHAT.txt) | Mensaje para pegar en una conversación nueva |
| [docs/memory/](docs/memory/) | Historial detallado y archivo de la memoria |
| [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md) | Hoja de ruta 3D aprobada (fases 2.0 a 2.8) |
| [docs/fase1_resumen_departamentos.md](docs/fase1_resumen_departamentos.md) | Auditorías de la Fase 1 |
| `D:\Aethelgard_alpha\docs\fase2\registro_encargo.md` | Registro del encargo de implementación (rama `rebelum-alpha`) |

**Copias de trabajo**
- `D:\Aethelgard`: la del usuario (rama `rebelum-3d`). Aquí se editan los documentos de memoria.
- `D:\Aethelgard_alpha`: la del encargo (rama `rebelum-alpha`).
- `D:\Aethelgard_memoria`: la de `memoria-desarrollo`, solo para publicar la memoria.

En la rama `memoria-desarrollo` solo están estos documentos. Sus enlaces a otros archivos de `docs/` funcionan en
`D:\Aethelgard`, pero no en GitHub.
