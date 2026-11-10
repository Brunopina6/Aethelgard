# DECISIONS: decisiones de AETHELGARD / REBELUM

**Actualizado el 2026-11-09 a las 00:20** sobre la copia del usuario (`rebelum-3d` @ `b8e042d`) y la rama de
integración (`integracion-experimental` @ `1c17763`). Las horas son locales (UTC+1).

**Estados**
- **Aprobada:** la tomó o la aprobó el usuario.
- **Aprobada en el encargo:** la tomé yo dentro de un encargo autorizado. Queda registrada para que el usuario la revise.
- **Propuesta:** sin aprobar.
- **En pausa:** aprobada, pero detenida por una instrucción posterior.
- **Sustituida:** ya no vale. Enlaza a la que la reemplaza y conserva el motivo.
- **Rechazada:** el usuario la descartó.

**Fuentes:** [usuario] son palabras o decisiones del usuario; [asistente], propuestas o decisiones mías; [historial],
datos de conversaciones anteriores sin volver a comprobar en el código.

## Índice

| ID | Decisión | Estado |
|---|---|---|
| [D-001](#d-001) | REBELUM es el nombre público; Aethelgard, el técnico | Aprobada |
| [D-002](#d-002) | Ramas y permisos de Git | Aprobada |
| [D-003](#d-003) | El commit `d155a36` se dividió; queda en `respaldo-d155a36` | Aprobada |
| [D-004](#d-004) | Fase 2.0 en la rama local `rebelum-3d` | Aprobada (terminada) |
| [D-005](#d-005) | Árbol de trabajo aparte para el encargo | Aprobada en el encargo |
| [D-006](#d-006) | El bloque B no se confirma sin permiso aparte | Aprobada |
| [D-007](#d-007) | v0.1.0 intacta; pre-releases automáticas | Aprobada / propuesta |
| [D-008](#d-008) | Licencias antes de distribuir | Aprobada |
| [D-010](#d-010) | Pruebas con datos aislados | Aprobada |
| [D-011](#d-011) | La partida del PC se conserva tal cual | Aprobada |
| [D-012](#d-012) | Versión experimental con paquete y partida propios | Aprobada (hecha en `rebelum-alpha`) |
| [D-013](#d-013) | El Redmi queda reservado | Sustituida en parte por D-065 (copias de APK por USB) |
| [D-014](#d-014) | Usar el Redmi por ADB para instalar y medir | Sustituida por D-013 |
| [D-015](#d-015) | PM infinitos solo con `-- pm_infinitos` | Aprobada en el encargo |
| [D-016](#d-016) | `MODO_PRUEBAS` siempre activo | Sustituida por D-015 (en `rebelum-alpha`) |
| [D-017](#d-017) | Frostfang congela en cada golpe | Aprobada |
| [D-020](#d-020) | Calidad visual primero; medir antes de optimizar | Aprobada |
| [D-021](#d-021) | Perfiles bajo, medio y alto; el Redmi es la referencia del bajo | Aprobada |
| [D-022](#d-022) | 30 FPS en el perfil medio del Redmi | Sustituida por D-021 |
| [D-023](#d-023) | Sin reflejo del cielo en bajo y medio | Aprobada |
| [D-024](#d-024) | Árboles: tarjetas y arces rechazados; mezcla estilizada | Sustituida (como dirección) por D-025 |
| [D-025](#d-025) | Vegetación: los paquetes como base, sin integrar todavía | Aprobada (dirección) |
| [D-026](#d-026) | Blender como herramienta principal; no instalar nada | Aprobada |
| [D-030](#d-030) | Historia principal A+C | Aprobada (dirección); la v3 es propuesta |
| [D-031](#d-031) | Opción A de la propuesta de lore | Sustituida por D-030 |
| [D-032](#d-032) | Tono y relaciones | Aprobada |
| [D-033](#d-033) | Secretos y referencias externas | Aprobada |
| [D-034](#d-034) | Ideas recuperadas de la conversación original | Propuesta |
| [D-035](#d-035) | Tilo y el corte alfa de Pastos Verdes | Aprobada (no canónica) |
| [D-036](#d-036) | Grimfang se queda; el «Goblin» 2D se retira; Garon, tercer héroe | Aprobada |
| [D-037](#d-037) | Garon: Esgrima y Embuir, sin Magia ni Invocación | Aprobada |
| [D-038](#d-038) | Reglas de la invocación de Érebo | Aprobada |
| [D-039](#d-039) | Dirección futura de la invocación de Érebo (Fase 2.7) | Aprobada (dirección); D1-D12, propuestas |
| [D-040](#d-040) | Migración gradual a 3D por regiones | Aprobada |
| [D-041](#d-041) | App experimental separada y APK «prueba 3D» | Aprobada |
| [D-042](#d-042) | Pastos Verdes como lugar 10 del mapa en modo 3D | Aprobada en el encargo; en curso |
| [D-043](#d-043) | Audio unificado y reparto de las 4 pistas | Propuesta |
| [D-044](#d-044) | Fase 1 de departamentos: solo auditoría | Sustituida por D-046 |
| [D-045](#d-045) | Esperar autorización tras la Fase 2.0 | Sustituida por D-046 |
| [D-046](#d-046) | Encargo único de implementación | Aprobada; reanudada el 07/11 |
| [D-047](#d-047) | Sistema de memoria y continuidad | Aprobada |
| [D-048](#d-048) | Las magias existentes no cambian; las ampliaciones son futuras | Aprobada |
| [D-049](#d-049) | La memoria se publica en `memoria-desarrollo`, y solo la memoria | Aprobada; ampliada por [D-070](#d-070) |
| [D-050](#d-050) | Licencias: recursos autorizados o sustitutos; el entregable excluye lo no acreditado | Aprobada |
| [D-051](#d-051) | Primera versión de la región 3D de Pastos Verdes | Aprobada en el encargo |
| [D-052](#d-052) | La misión del corte alfa dentro de la región | Aprobada en el encargo |
| [D-053](#d-053) | Validación de la región en el Redmi, pedida por el usuario | Aprobada (hecha) |
| [D-054](#d-054) | Repositorio privado `Aethelgard-pruebas` para descargar las APK de prueba en el móvil | Aprobada |
| [D-055](#d-055) | Lya y Garon siguen a Kael en la exploración 3D | Aprobada en el encargo |
| [D-056](#d-056) | Guardado protegido: no pisar sin cargar, escritura segura y copia de seguridad | Aprobada en el encargo |
| [D-057](#d-057) | El cofre del árbol mágico de Pastos Verdes 3D | Aprobada en el encargo |
| [D-058](#d-058) | La cinemática del mirador (PV-07) | Aprobada en el encargo |
| [D-059](#d-059) | El grupo se une con la misión; objetivo y marcador en pantalla | Aprobada en el encargo |
| [D-060](#d-060) | El grupo activo manda: exploración, combate, menús y guardado; encuentros para Kael solo | Aprobada |
| [D-061](#d-061) | Sin tirones al abrir diálogos ni al ver algo por primera vez: se prepara en las cargas | Aprobada en el encargo |
| [D-062](#d-062) | Nivelación automática de quien se une al grupo | Propuesta (pendiente del usuario) |
| [D-063](#d-063) | Teclado y mando: acciones, foco visible y una pulsación, una acción (T-025) | Aprobada en el encargo |
| [D-064](#d-064) | Base del audio: buses, volúmenes guardados y pestaña «Ajustes» (T-030) | Aprobada en el encargo |
| [D-065](#d-065) | El Redmi recibe por USB las APK de prueba en Descargas; instalar es cosa del usuario | Aprobada |
| [D-066](#d-066) | La protección del guardado, traída a la copia habitual (`rebelum-3d`) | Aprobada |
| [D-067](#d-067) | Gestor de música y ambiente por contexto, con ambientes CC0 (T-030) | Aprobada en el encargo |
| [D-068](#d-068) | El prólogo con puesta en escena, retratos vivos y caja de texto legible (T-081) | Aprobada en el encargo |
| [D-069](#d-069) | Organización por especialistas: un coordinador y cinco subagentes | Aprobada |
| [D-070](#d-070) | GitHub: código, configuraciones de agentes y documentación revisados en ramas de trabajo | Aprobada |
| [D-071](#d-071) | Ambición: todas las ciudades mejoradas, muchos sitios nuevos y magias nuevas | Aprobada |
| [D-072](#d-072) | Más contenido: equipo, enemigos, compañeros, secretos, grutas y posadas, con inspiración solo de principios | Aprobada |
| [D-073](#d-073) | Decisiones de la noche del 08 al 09/11, para que el usuario las revise | Aprobada en el encargo |
| [D-074](#d-074) | La Garganta del Diablo pasa a 3D como mazmorra (cambia el plan 3D, que la dejaba en 2D) | Aprobada |
| [D-075](#d-075) | Recursos que aporta el usuario el 09/11: el bestiario, el paquete de dos espadas y el logotipo | Aprobada |
| [D-076](#d-076) | **Todas las ciudades, pueblos y posadas pasan a 3D jugable**, al nivel de Pastos Verdes; la Garganta, pulida como mazmorra | Aprobada |
| [D-077](#d-077) | Sesión «calidad AAA, sin Redmi» (09/11 tarde): personalidad de los héroes y decisiones del coordinador | Aprobada en el encargo |
| [D-H01 a D-H15](#6-diseño-ya-implementado-del-3010-al-0511) | Diseño ya implementado antes de Git | Aprobada (historial) |

## 1. Reglas de trabajo, Git y versiones

### D-001
**REBELUM es el nombre público; Aethelgard sigue como nombre técnico**
- **Fecha y estado:** 2026-11-06, reiterada el 2026-11-07. Aprobada [usuario]: «No cambies todavía el nombre técnico
  del repositorio o de las carpetas de Aethelgard a REBELUM».
- **Decisión:** REBELUM es el nombre del juego para el jugador. Aethelgard sigue en el repositorio, las carpetas, los
  paquetes (`com.aethelgard.*`), los identificadores y las rutas.
- **Motivo:** renombrar rompería rutas, exportaciones y guardados. La carpeta de `user://` depende de `config/name`.
- **Alternativa:** renombrarlo todo. El usuario lo descartó por ahora.
- **Consecuencias:** nada técnico cambia de nombre sin permiso explícito.
- **Archivos:** `docs/marca_rebelum.md`, `aethelgard/marca/rebelum_logo.webp` y `aethelgard/prototipos/titulo_rebelum.gd`.

### D-002
**Ramas y permisos de Git**
- **Fecha y estado:** del 2026-11-05 en adelante. Aprobada [usuario].
- **Decisión:**
  - `main` es la rama estable y no se toca.
  - `desarollo` es la rama compartida de desarrollo. Se escribe con una sola r; no existe `desarrollo`.
  - Commit y push, solo con permiso explícito. Del 05/11 al 07/11, la fórmula fue «Sí, commit y subir».
  - Prohibido: `push --force`, `reset --hard`, limpiezas destructivas, `git add .` y renombrados masivos.
- **Motivo:** proteger la versión estable y el trabajo del usuario.
- **Consecuencias:**
  - El trabajo nuevo va a ramas locales (D-004 y D-005).
  - `desarollo` está en `2d1adc4`, igual que `origin/desarollo`.

### D-003
**El commit `d155a36` se revisó y se dividió; el original queda en `respaldo-d155a36`**
- **Fecha y estado:** 2026-11-07, de 00:53 a 01:08. Aprobada [usuario]: «Revisarlo antes del push», «Sí, corregirlo»,
  «Sí, hacer push» y, después, «No borrar respaldo-d155a36».
- **Decisión:**
  - Origen: el commit `d155a36` (Posador y experimentos de vegetación) se creó a las 00:35. Por las horas, salió de
    otra sesión de Claude, la del análisis de Cascadeur (registro `ca2d0f19…`).
  - Se revisó antes de subirlo y se dividió en dos commits, que se subieron a `desarollo`: `f5f3c4e` (Posador) y
    `2d1adc4` (vegetación y documentación).
- **Motivo:** sanearlo antes de publicarlo [historial]. El detalle de lo que se quitó está en el registro de esta sesión.
- **Consecuencias:** la rama `respaldo-d155a36` no se borra.
- **Archivos:** `aethelgard/addons/posador/`, `aethelgard/prototipos/vegetacion_paquetes.gd`, `.gitignore` y `docs/`.

### D-004
**Fase 2.0 en la rama local `rebelum-3d`**
- **Fecha y estado:** 2026-11-07, 03:18. Aprobada [usuario]; terminada.
- **Decisión:**
  - Rama local `rebelum-3d`, que sale de `desarollo`.
  - Punto de recuperación: la etiqueta local `recuperacion-antes-fase2.0` (`2d1adc4`), más un respaldo verificado.
  - Commits locales pequeños y con sus archivos identificados.
  - Las palabras del usuario: «Permito commits locales pequeños únicamente en rebelum-3d, identificando sus archivos.
    Esto NO autoriza el commit pendiente del bloque B sobre desarollo. No hagas push, no publiques APK y no instales
    herramientas sin autorización adicional».
- **Consecuencias:** 9 commits locales, de `379122b` a `ce84422`, nunca subidos. No cambian el código del juego.
- **Archivos:** `aethelgard/export_presets.cfg`, `aethelgard/pruebas/{ejecutar_pruebas.ps1, lista_pruebas.txt,
  sonda_datos.gd, LEEME.md}`, `compilar_apk_experimental.ps1`, `docs/fase2/fase2.0_comprobaciones.md` y
  `docs/versiones/licencias_pendientes.txt`.

### D-005
**Árbol de trabajo aparte para el encargo (`D:\Aethelgard_alpha`, rama `rebelum-alpha`)**
- **Fecha y estado:** 2026-11-07, 15:18. Aprobada en el encargo [asistente]: el encargo pedía «una rama experimental en
  un árbol de trabajo separado». Son las decisiones 0.1 y 0.2 del registro del encargo.
- **Decisión:**
  - `rebelum-alpha` sale de `rebelum-3d` (`ce84422`).
  - Se copió la caché `.godot` de la copia del usuario para no reimportar 1,6 GB. Es caché, así que no se confirma.
- **Motivo:** no cambiar de rama en la copia del usuario, que tiene trabajo sin confirmar.
- **Consecuencias:** el trabajo del encargo solo se ve abriendo `D:\Aethelgard_alpha`.
- **Archivos:** `D:\Aethelgard_alpha\docs\fase2\registro_encargo.md`.

### D-006
**El bloque B no se confirma sin un permiso aparte**
- **Fecha y estado:** 2026-11-07 (aprobación del plan 3D y autorización de la Fase 2.0). Aprobada [usuario]. El permiso
  del commit sigue sin darse.
- **Decisión:** las palabras del usuario: «Sobre el bloque B, mantén separado el permiso para el commit local selectivo.
  No lo interpretes como aprobado automáticamente».
- **Qué es el bloque B** (en `D:\Aethelgard`, sin confirmar):
  - el reflejo del cielo (D-023), en `aethelgard/prototipos/calidad_proto.gd` y `sendero_puente.gd`;
  - la ronda 8 de `docs/vegetacion_rendimiento.md`;
  - `docs/perfiles_graficos_propuesta.md` y `docs/capturas/reflejo_agua.jpg`.
- **Consecuencias:**
  - El cambio del reflejo solo se recuperó en `rebelum-alpha` (`3a16db2`; decisión 0.3 del registro).
  - En `desarollo` no se ha confirmado nada.
  - Los 5 `.import` de `vegetacion_prueba/quaternius/` que aparecen modificados los reescribe el editor de Godot al
    abrir el proyecto; no forman parte del bloque B.

### D-007
**v0.1.0 se conserva intacta; las pre-releases automáticas son una propuesta**
- **Fecha y estado:**
  - Que v0.1.0 quede intacta: aprobada [usuario], el 2026-11-07.
  - La automatización: propuesta [asistente].
- **Hechos:**
  - La etiqueta `v0.1.0` apunta a `fd71d6a`, el primer commit, del 05/11.
  - Es una pre-release de GitHub con la APK de Android.
  - No hay flujos de GitHub Actions.
- **Propuesta:** [docs/versiones/automatizacion_prereleases.md](docs/versiones/automatizacion_prereleases.md), sin
  activar. Nada se publica sin autorización.

### D-008
**Licencias antes de distribuir**
- **Fecha y estado:** 2026-11-07 (Fase 2.0 y encargo único). Aprobada [usuario].
- **Decisión:**
  - Ninguna APK con recursos de licencia pendiente sale del PC, tampoco por GitHub.
  - La lista está en [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt).
  - El script de compilación detecta esos recursos y deja junto a la APK un aviso `NO_DISTRIBUIR`.
  - La música de Suno de derechos inciertos solo se usa en pruebas privadas locales, fuera de los commits y de toda APK
    entregable.
- **Alternativas:** recursos de licencia verificada o silencio controlado.
- **Ampliada por:** [D-050](#d-050).
- **Excepción:** [D-054](#d-054), el repositorio privado `Aethelgard-pruebas`, del que el usuario descarga las APK de
  prueba en su móvil.
- **Archivos:** `compilar_apk_experimental.ps1`, `docs/versiones/licencias_pendientes.txt` y `docs/recursos.md`.

## 2. Datos, pruebas y móvil

### D-010
**Pruebas con datos aislados**
- **Fecha y estado:** 2026-11-07, 03:32. Aprobada [usuario]: «Antes de ejecutar las 27 pruebas, asegúrate de que
  ninguna pueda modificar mi partida real ni otros datos persistentes del juego. Ejecuta las pruebas en un entorno de
  datos aislado y comprueba el SHA-256 de partida.save antes y después».
- **Decisión:** `aethelgard/pruebas/ejecutar_pruebas.ps1`
  - redirige `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP`, y lo comprueba con `sonda_datos.gd`;
  - compara los hashes de los datos reales y el `git status`;
  - da 4 resultados: SUPERADA, FALLIDA, MANUAL y NO SEGURA.
- **Motivo:** la primera ejecución sin aislar escribió 5 registros de Godot en la carpeta real. La partida no cambió.
- **Ampliado el 08/11** ([D-011](DECISIONS.md#d-011)): la carpeta real es la misma para todas las copias del proyecto.
  - El ejecutor ya no empezaba con un Godot abierto. Ahora, además, mira entre prueba y prueba si alguien abre otro y
    lo apunta en el resumen con su línea de órdenes; de cada archivo cambiado de la carpeta real da la hora.
  - Al pasarse de tiempo una prueba, solo cierra su proceso y los hijos de este. Antes cerraba cualquier Godot abierto
    después de empezar la prueba: también un editor del usuario.
  - **Verificado** (08/11, 20:38, `d5fd793`, `pruebas/verificar_ejecutor.ps1`): con una prueba que no termina nunca
    (`sonda_tiempo.gd`) y otro Godot abierto mientras tanto, con datos aislados, el ejecutor cierra la sonda a los
    8,5 s, deja vivo el otro Godot y lo apunta en el resumen. Dos pasadas; ningún Godot queda abierto.
  - **La copia habitual** (`rebelum-3d`) sigue con el ejecutor antiguo, que sí podría cerrar un editor abierto
    después de empezar una prueba que se pasa de tiempo. Traer el nuevo necesita una autorización aparte.
- **Archivos:** el ejecutor, `lista_pruebas.txt` y `sonda_datos.gd`.

### D-011
**La partida del PC se conserva tal cual**
- **Fecha y estado:** 2026-11-07, 03:59: «No, déjala así». Aprobada [usuario]; reiterada en el encargo y en la tarea de
  memoria.
- **Hecho:**
  - A las 03:50:12, una sesión del editor del propio usuario sobrescribió `partida.save`, que perdió la clave `grupo`.
  - El original está en `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0\partida.save`.
- **Decisión:**
  - No restaurarla ni volver a ofrecerlo.
  - La copia histórica queda intacta.
  - Si faltan datos, el cargador usa sus valores por defecto.
- **Consecuencias:** el fallo que lo permitió queda como tarea (T-076).
- **Se repitió el 08/11 a las 19:37:34** (comprobado leyendo fechas y huellas, sin tocar nada):
  - un juego lanzado desde el editor abierto en la copia del usuario (`D:\Aethelgard\aethelgard`, rama `rebelum-3d`,
    que aún no tiene el arreglo de T-076) reescribió `partida.save`;
  - ahora tiene la huella `A3F3C402…` y 371 bytes, con `escena_guardada` en `zona.tscn` y sin `grupo` ni
    `inventario`. No se sabe qué claves tenía antes: las baterías solo guardaban su huella (`B0A2AA40…`, la misma
    desde el 07/11);
  - **pistas:** en esa copia, el editor guardó su caché a las 19:37:04, los metadatos de ejecución a las 19:37:11 y su
    disposición a las 19:37:38. El juego dejó su registro en la carpeta real a las 19:37:12, con la tarjeta gráfica:
    ningún proceso de la batería abre ventana ni usa esa carpeta, y ninguna orden del asistente abrió Godot entonces;
  - la batería de las 19:35 terminó a las 19:37:28 con la partida intacta. Avisó (código 254) por el registro de
    Godot y los ajustes de Dialogic que escribió ese editor en la carpeta real.
  - Se conserva tal cual.
  - **Comprobado después** (08/11, 20:30, leyendo; [D-066](#d-066)): el editor de esa copia tenía abierta, como escena
    actual, `res://mapa.tscn`; su versión guarda al cerrar la ventana con la escena en curso (`recursos.gd`). La
    partida quedó con `escena_guardada = zona.tscn` y sin `grupo` ni `inventario`, lo mismo que deja una sesión
    abierta con F6 que entra en Oakhaven y se cierra. Reproducido en una copia aislada: así se pierden `grupo` e
    `inventario`. **No se puede demostrar** quién lanzó la sesión, si fue F6 ni qué claves tenía antes la partida.
  - Desde `b8e042d` (D-066), la copia habitual ya no guarda en una sesión que no cargó la partida.

### D-012
**Versión experimental con paquete y partida propios**
- **Fecha y estado:** 2026-11-07. Aprobada [usuario]: paquetes y partidas separados. La partida propia está hecha en
  `rebelum-alpha` (`d066fe9`).
- **Decisión:**
  - **Paquete:** `com.aethelgard.experimental` («Aethelgard Exp»), con el preset «Android experimental».
  - **Partida en el PC:** allí `user://` es el mismo para todos los presets, porque depende de `config/name`. Por eso el
    modo 3D usará `user://partida_exp.save` (`progreso.gd`, `archivo()`).
- **Motivo:** la app estable y su partida no se tocan nunca.

### D-013
**El Redmi queda reservado**
- **Fecha y estado:** 2026-11-07, 15:15 (encargo único); reiterada en la tarea de memoria. Aprobada [usuario], vigente.
- **Decisión:**
  - Nada de ADB, USB, MTP, conexión inalámbrica ni escritorio remoto.
  - No copiar, instalar, actualizar ni borrar APK en el móvil.
  - La APK antigua que hay en las Descargas del teléfono se deja intacta.
  - Cuando haga falta validar algo, se le pide al usuario que conecte el móvil.
- **Sustituye a:** [D-014](#d-014).
- **Sustituida en parte por [D-065](#d-065)** (08/11): ya se pueden copiar por USB las APK de prueba a Descargas, sin
  borrar las anteriores. Lo demás sigue igual: instalar, borrar o cambiar algo en el teléfono lo hace el usuario.

### D-014
**Usar el Redmi por ADB para instalar y medir: SUSTITUIDA por [D-013](#d-013)**
- **Fecha:** del 2026-11-03 al 2026-11-07, 04:00.
- **Lo que se hacía:**
  - Las APK se copiaban a las Descargas del teléfono para que las instalara el usuario, porque Xiaomi bloquea
    `adb install` (`INSTALL_FAILED_USER_RESTRICTED`).
  - El juego se arrancaba con `monkey`, se tocaba la pantalla con `input tap` y se leía `logcat`.
  - Capturas de Arm Streamline: el usuario copiaba `gatord` y ejecutaba `setprop security.perf_harden 0`. Siempre se
    restauraba al terminar.
- **Motivo del cambio:** el usuario reservó el móvil para las validaciones que pida él.
- **Consecuencias:** el procedimiento queda documentado en [docs/vegetacion_rendimiento.md](docs/vegetacion_rendimiento.md)
  por si el usuario lo vuelve a autorizar.

### D-015
**PM infinitos solo con `-- pm_infinitos`**
- **Fecha y estado:** 2026-11-07, 15:29 (`aa709dd`, solo en `rebelum-alpha`). Aprobada en el encargo [asistente]: es la
  decisión 0.7 del registro. El encargo pedía aislar las reglas de depuración.
- **Decisión:** `combate.gd:9-11`:
  `var MODO_PRUEBAS: bool = "pm_infinitos" in OS.get_cmdline_user_args()`.
  En el juego normal se pagan los PM.
- **Sustituye a:** [D-016](#d-016), solo en `rebelum-alpha`.

### D-016
**`MODO_PRUEBAS` siempre activo: SUSTITUIDA por [D-015](#d-015) en `rebelum-alpha`**
- **Fecha:** 2026-11-03, de `cambios_aethelgard.md`, como modo de pruebas pedido por el usuario.
- **Lo que hacía:** `const MODO_PRUEBAS := true` daba PM infinitos en cualquier partida. El propio comentario decía
  «false para el juego de verdad».
- **Consecuencias:** en `desarollo` y `rebelum-3d` sigue así hasta que se integre `rebelum-alpha`.

### D-017
**Frostfang congela en cada golpe**
- **Fecha y estado:**
  - La regla viene de `cambios_aethelgard.md` (2026-11-03).
  - Se confirmó el 2026-11-07: decisión 0.8 del registro.
  - Aprobada: es la regla vigente.
- **Decisión:**
  - `PROB_CONGELAR = 1.0`.
  - La congelación quita 16 PV máximos durante 2 rondas y **no bloquea turnos** (`combate.gd:1323-1346`).
  - El diario lo explica: «Los golpes con Frostfang congelan» (`diario.gd:17`).
- **Alternativa descartada:** bajar la probabilidad. No había ningún bloqueo que corregir.

## 3. Calidad visual y rendimiento

### D-020
**Calidad visual primero; medir antes de optimizar**
- **Fecha y estado:** 2026-11-05 y 2026-11-06, en las órdenes de árboles, optimización y diagnóstico. Aprobada
  [usuario]: «No reduzcas la calidad del perfil alto para adaptarlo al Redmi», «No prometas mejoras sin medirlas».
- **Decisión:**
  - Se diagnostica antes de programar: Arm Streamline, Mali Offline Compiler y, si hace falta, RenderDoc for Arm.
  - Se enseñan capturas antes de sustituir nada.
  - Cada optimización es opcional por perfil, reversible y con antes y después.
  - El perfil alto es la referencia de belleza.
- **Archivos:** [docs/vegetacion_rendimiento.md](docs/vegetacion_rendimiento.md) y `docs/capturas/`.

### D-021
**Perfiles bajo, medio y alto; el Redmi es la referencia del perfil bajo**
- **Fecha y estado:** 2026-11-07, 00:47. Aprobada [usuario]: «No quiero seguir persiguiendo obligatoriamente 30 FPS en
  calidad media en el Redmi... será nuestra referencia para el perfil bajo».
- **Metas del encargo único:** 30 FPS sostenidos en el perfil ligero del Redmi y 60 FPS en un PC capaz.
- **Sustituye a:** [D-022](#d-022).
- **Archivos:** `aethelgard/prototipos/calidad_proto.gd` y la propuesta
  [docs/perfiles_graficos_propuesta.md](docs/perfiles_graficos_propuesta.md).

### D-022
**30 FPS en el perfil medio del Redmi: SUSTITUIDA por [D-021](#d-021)**
- **Fecha:** 2026-11-06, al cerrar la «Fase 1» de Pastos Verdes.
  - Con el banco TOPE, bajo y medio iban a 30 FPS sin tirones.
  - Los árboles mezclados bajaron después el medio a 22,8 FPS a 20 m y a 18,9 FPS a 34 m.
- **Motivo del cambio:** el usuario prefirió no perseguir los 30 FPS en medio a costa de la belleza.

### D-023
**Sin reflejo del cielo en los perfiles bajo y medio**
- **Fecha y estado:** 2026-11-07, 00:47. Aprobada [usuario].
  - Confirmada en `rebelum-alpha` (`3a16db2`).
  - En la copia del usuario sigue sin confirmar (bloque B).
- **Medición en el Redmi** (ronda 8): −3,3 ms a 20 m y −8 ms a 34 m; brillo −0,7 %.
- **Condiciones del usuario:**
  - el perfil alto conserva el reflejo;
  - la opción de revertirlo se mantiene: `"reflejo_cielo": true` en el perfil, o en `calidad_extra`;
  - **no se aplica el terreno simplificado**.
- **Archivos:** `aethelgard/prototipos/calidad_proto.gd` y `aethelgard/prototipos/sendero_puente.gd`.

### D-024
**Árboles: tarjetas y arces de Meshy rechazados; mezcla de árboles estilizados. SUSTITUIDA como dirección visual por [D-025](#d-025)**
- **Fecha:** mañana del 2026-11-06.
- **Rechazados** [usuario]:
  - los árboles de tarjeta: «como una oja de papel»;
  - los arces 3D de Meshy: «muy pobres estan como sin renderizar».
- **Aplicada** al prototipo `sendero_puente`: «Los tres mezclados», es decir, pradera, abedul y mágico
  (`prototipos/arbol_estilizado.gd`).
- **Motivo del cambio:** la comparación con los paquetes de vegetación (D-025).

### D-025
**Vegetación: los paquetes (Quaternius MegaKit y EmacE) como base visual, sin integrarlos todavía**
- **Fecha y estado:** 2026-11-06, 10:13. Aprobada como dirección [usuario]: «la dirección correcta es usar los
  PAQUETES como base visual... Sin embargo, todavía no quiero integrar esta vegetación tal cual».
- **Decisión:**
  - Seguir refinando la densidad y la riqueza con mejor rendimiento.
  - Los experimentos medidos son opciones en `prototipos/vegetacion_paquetes.gd`: LOD (3 niveles en árboles y 2 en
    arbustos), mallas indexadas, sombras C+ y sombras horneadas.
  - Convertirlos en el valor por defecto **necesita autorización**. Las palabras del usuario en la Fase 1: «sin
    convertir opciones experimentales en definitivas».
- **Licencia de EmacE:** no se puede redistribuir.
  - Está fuera de Git (`.gitignore`).
  - La app necesitará una alternativa, por ejemplo matas opacas más densas.
- **Archivos:** `aethelgard/vegetacion_prueba/`, [docs/vegetacion_rendimiento.md](docs/vegetacion_rendimiento.md) y
  `docs/capturas/vegetacion_*`.

### D-026
**Blender como herramienta principal de animación; no instalar ni contratar nada**
- **Fecha y estado:** 2026-11-06, 23:09. Aprobada [usuario]: «Utiliza Blender como herramienta principal para las
  animaciones que necesitemos exportar a Godot», «No contrates ni instales nada adicional».
- **Decisión:**
  - Cascadeur Free solo sirve de apoyo; el análisis está en [docs/cascadeur_analisis.txt](docs/cascadeur_analisis.txt).
  - Herramientas como FFmpeg, Audacity o SoX no se instalan sin permiso, y no están instaladas.

## 4. Narrativa y personajes

### D-030
**Historia principal A+C (base de la biblia v3)**
- **Fecha y estado:** 2026-11-07, en el encargo de la v3. Dirección aprobada [usuario]. **El texto de la v3 es una
  propuesta** hasta que el usuario lo apruebe.
- **Decisión:**
  - Rebelum es el reino olvidado.
  - Érebo protege los corazones de los borrados.
  - Kael está relacionado con el niño del anillo, pero no es culpable de la niebla.
  - Cuatro actos, con revelaciones progresivas y consecuencias reales.
  - Al final, Érebo sacrifica su forma de invocación y sigue como una pequeña sombra junto a Lya.
- **Sustituye a:** [D-031](#d-031). La v2 queda intacta.
- **Archivos:** [docs/biblia/rebelum_biblia_narrativa_v3.md](docs/biblia/rebelum_biblia_narrativa_v3.md). Las
  preguntas abiertas están en §8.2 y §10.7.

### D-031
**Opción A de la propuesta de lore: SUSTITUIDA por [D-030](#d-030)**
- **Fecha:** 2026-11-06. Propuesta [asistente]: «la luz que se negó a ser olvidada», ligada a la niebla, el anillo
  partido, el Sello y la «Llave del Confino».
- **Archivos:** [docs/biblia/rebelum_propuesta.md](docs/biblia/rebelum_propuesta.md).

### D-032
**Tono y relaciones**
- **Fecha y estado:** 2026-11-07, en los encargos de la v3 y del TXT. Aprobada [usuario].
- **Decisión:**
  - Kael y Lya tienen una amistad profunda, nunca un romance.
  - Kael, Lya, Garon y Érebo son una familia de aventureros que bromea, discute, se apoya y evoluciona.
  - La historia es luminosa, divertida, sorprendente y emocional.
  - Se respeta a Garon y a Érebo.

### D-033
**Secretos y referencias externas**
- **Fecha y estado:** 2026-11-07. Aprobada [usuario].
- **Decisión:**
  - No se revela antes del acto III que Érebo guarda corazones o recuerdos.
  - **Final Fantasy X:** no se revelan detalles, porque el usuario todavía no lo ha jugado. Lo pidió en la conversación
    original (el TXT, línea 88).
  - Final Fantasy IX (Bahamut), Final Fantasy VII y Expedition 33 solo sirven como referencia de principios: sensación
    y ritmo. No se copian diseños, escenas ni argumentos.

### D-034
**Ideas recuperadas de la conversación original**
- **Fecha y estado:** 2026-11-07, 02:30. Propuesta. Hay 16 decisiones pendientes del usuario.
- **Contenido:**
  - Atlas de los Nombres, Elaria, los dioses antiguos, la ciudad reflejada, la isla secreta y el joven con recuerdos
    ajenos.
  - Las palabras del usuario sobre esas ideas: no sustituirlas automáticamente.
- **Archivos:** la v3, §10. El TXT está fuera del repositorio:
  `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Conversacion_y_Biblia_del_Guion.txt`.

### D-035
**Tilo y el corte alfa de Pastos Verdes**
- **Fecha y estado:** 2026-11-07, 03:18. Aprobada [usuario], pero **no canónica**.
- **Decisión:**
  - Tilo es un personaje provisional dentro del proyecto.
  - El corte de misión PV-02 → PV-14 vale para la alfa sin pasar a ser canon.
- **Archivos:** [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md) y la v3, §6. [alpha sin confirmar]:
  `dialogos/pv_*.dtl` y `dialogos/personajes/tilo.dch`.

### D-036
**Grimfang se queda; el «Goblin» 2D se retira; Garon pasa a ser el tercer héroe**
- **Fecha y estado:** 2026-11-04. Aprobada [usuario]; implementada.
- **Corrección del usuario:**
  - El usuario pidió «elimina al goblin no me gusta ese personaje».
  - Yo quité por error a Grimfang.
  - El usuario corrigió: «Grimfang no hay que quitar al enemigo llamado Goblin».
  - Grimfang volvió, y el orco 2D «Goblin» pasó a `retirado/goblin_2d`.
- **Además:**
  - Grimfang (orco 3D) sustituyó a Hollín.
  - Garon entró como tercer héroe, con la espada doble.

### D-037
**Garon: Esgrima y Embuir, sin Magia ni Invocación**
- **Fecha y estado:** 2026-11-05 (cambio 14 de `cambios_aethelgard.md`). Aprobada [usuario]; implementada.
- **Esgrima:**
  - Juicio: ×1,8 de daño, 6 PM, un objetivo.
  - Giro: 2 golpes a todos los enemigos, ×0,9 cada uno, 10 PM.
- **Embuir:** Fuego, Hielo, Rayo o Agua durante 3 turnos; +20 % de daño de ese elemento; 5 PM. Hielo puede congelar.

### D-038
**Reglas de la invocación de Érebo («Ladrón de Corazones»)**
- **Fecha y estado:** 2026-11-05 (cambio 13). Aprobada [usuario]; implementada.
- **Reglas:**
  - La invoca Lya con la Armonía llena, que sube 0,15 por cada acción de un héroe.
  - Tiene un solo objetivo.
  - Enemigos normales: 20 % de muerte instantánea; si falla, no hace daño.
  - Jefes: inmunes a la muerte; pierden el 20 % de su vida actual.
- **Comprobado ejecutando** (2026-11-07, aislado): con éxito, el enemigo pasa de 55 a 0 PV; con fallo, no recibe daño.

### D-039
**Dirección futura de la invocación de Érebo (Fase 2.7)**
- **Fecha y estado:** 2026-11-07, 02:05 y 03:18.
  - La dirección está aprobada [usuario].
  - Las decisiones D1-D12 de la cinemática son propuestas.
- **Dirección:**
  - Se conserva la colocación por la mano en el fotograma de contacto, más el ajuste IK. El error medido baja de 0,564 m
    a entre 0,000 y 0,022 m.
  - Prioridad a la calidad visual: contacto realista, movimiento fluido, reacción del enemigo y cámaras
    cinematográficas.
  - Se compara la versión de 16,4 s con una de 10-12 s, y se mantienen la versión corta y la opción de saltar.
  - La referencia es la sensación del Bahamut de FFIX, sin copiarlo, en una estructura de 15 pasos.
- **Propuesta actual:** completa ≈11,8 s y corta ≈5,6 s, en
  [docs/erebo/invocacion_erebo_cinematica.md](docs/erebo/invocacion_erebo_cinematica.md) (D1-D12).
- **Consecuencias:** no se implementa hasta la Fase 2.7.

## 5. Plan 3D, audio y encargos

### D-040
**Migración gradual a 3D por regiones**
- **Fecha y estado:** 2026-11-07. Aprobada [usuario]:
  - 03:01: recomendaciones A1-A4, con 8 condiciones;
  - 03:18: el plan, como hoja de ruta de la Fase 2.
- **Decisión:**
  - La primera región es Pastos Verdes, completamente jugable. Conserva encuentros, combate ATB, inventario,
    progresión, guardado y diálogos.
  - Interruptor por región (`rebelum3d`), con vuelta al mapa 2D y el contrato `zona_3d`.
  - Fases 2.0 a 2.8. La alfa 1 es el corte de misión PV-02 → PV-14.
  - El juego 2D sigue como referencia y respaldo.
- **Límite que puso el usuario al aprobarlo:** «Esta aprobación es para redactar el plan 3D. No autoriza todavía la
  implementación general, publicación de versiones ni cambios en GitHub». La implementación llegó después con D-046.
- **Archivos:** [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md).

### D-041
**App experimental separada y APK «prueba 3D»**
- **Fecha y estado:** 2026-11-07. Aprobada [usuario]; hecha.
- **Decisión:**
  - Preset «Android experimental», con el paquete `com.aethelgard.experimental`.
  - La app estable excluye `zonas3d`.
  - `compilar_apk_experimental.ps1 -Preset` se niega a compilar la app estable.
  - Con «Sí, compílala» (03:51) se compiló la APK «Android prueba 3D» (`com.aethelgard.prueba3d`), para ver Pastos
    Verdes 3D en el Redmi cuanto antes.

### D-042
**Pastos Verdes como lugar 10 del mapa en modo 3D**
- **Fecha y estado:** 2026-11-07, hacia las 15:30. Aprobada en el encargo [asistente]: el encargo deja que yo decida
  esto.
  - Se retomó a las 16:30 (D-046) desde el trabajo a medias en `rebelum-alpha`.
  - Está hecho en `d066fe9` y `a89a8a5` (T-021).
- **Diseño:**
  - `modo3d.gd`: `activo()` se cumple con la característica `rebelum3d` o con el argumento `-- 3d`.
  - Lugar 10 del mapa en `(660, 478)`, que abre `zonas3d/pastos_verdes_3d.tscn`. **Esa escena todavía no existe.**
  - Encuentros: paso de 0,5 m, 40 pasos seguros y probabilidad de 0,012. Combate fijo «pastos_centinela».
- **Alternativa:** si no está el modo 3D, vuelve al mapa 2D.

### D-043
**Audio unificado y reparto de las cuatro pistas (Fase 2.6)**
- **Fecha y estado:** 2026-11-07. Propuesta.
- **Sistema:**
  - Buses de música, efectos, interfaz y ambiente.
  - Un gestor de música con fundidos (`AudioStreamInteractive`, `AudioStreamPlaylist` y `AudioStreamRandomizer`).
  - OGG en streaming y WAV con compresión QOA.
  - Volumen y preferencias persistentes, y un tema de reserva si falta una pista.
- **Dos repartos de las pistas, ninguno aprobado.** Se decidirá escuchándolas.

  | Pista | Departamento de música (Fase 1) | Encargo único («asignaciones de partida») |
  |---|---|---|
  | `sunlit_paths` | Exploración | Ruta o Pastos Verdes |
  | `morning_waltz` | Claro de inicio | Título o poblado |
  | `promised_horizon` | Mirador de la cascada, la primera vez | Transición narrativa o exploración amplia |
  | `waltz_starlit_path` | Ruinas y zonas mágicas | Descanso, noche o momento íntimo |

  El departamento de música proponía además no tener ciclo de día y noche.
- **Archivos:** [docs/audio/musica_adaptativa.md](docs/audio/musica_adaptativa.md) y
  [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md) §6. Derechos: ver D-008.

### D-044
**Fase 1 de los departamentos: solo auditoría y documentación. SUSTITUIDA por [D-046](#d-046)**
- **Fecha:** 2026-11-07, 01:14, en la «Autorización de Fase 1»: siete departamentos, hasta cuatro subagentes a la vez
  y «No inicies automáticamente la Fase 2».
- **Motivo del cambio:** el encargo único dice: «Esta orden sustituye el anterior encargo de solo auditoría y la espera
  de aprobación para esas fases».

### D-045
**Esperar autorización tras la Fase 2.0 antes de las fases 2.1 y 2.2. SUSTITUIDA por [D-046](#d-046)**
- **Fecha:** 2026-11-07, 03:18: «Tras terminar la Fase 2.0, entrégame las comprobaciones y espera mi autorización antes
  de implementar la 2.1 y la 2.2».
- **Motivo del cambio:** la misma frase del encargo único que en D-044.

### D-046
**Encargo único de implementación: REANUDADO**
- **Fecha y estado:**
  - Aprobado [usuario] el 2026-11-07 a las 15:15.
  - En pausa de las 15:40 a las 16:30: «La implementación de nuevas funciones queda pendiente de mi siguiente encargo».
  - **Reanudado** a las 16:30 [usuario]: «doy por finalizada la pausa de documentación y te autorizo a retomar la
    implementación del encargo único de AETHELGARD, empezando por Pastos Verdes 3D, tarea T-021».
  - Condiciones de la reanudación:
    - verificar antes el trabajo a medias de `rebelum-alpha` y su respaldo, sin aplicar dos veces los parches;
    - poder consultar la memoria desde `D:\Aethelgard_alpha`;
    - cambios pequeños, reversibles y comprobados;
    - se puede compilar y probar en local;
    - avisar al final para una prueba en el móvil.
- **Qué autoriza:**
  - La implementación local, reversible y no destructiva de las fases 2.1 a 2.6 y del resto: magia aditiva, estados,
    tablero, IA, invocaciones, cinemáticas, audio y optimización.
  - Los commits locales en una rama aislada.
- **Límites:**
  - D-002 y D-013;
  - D-011 (la partida del PC);
  - no instalar, no comprar y no subir archivos a servicios externos;
  - no escribir en `main` ni en `desarollo`;
  - no hacer push ni publicar.
- **Sustituye a:** [D-044](#d-044) y [D-045](#d-045).
- **Estado del trabajo:** Fase 0 terminada (T-020); Fase 1 empezada y a medias (T-021).
- **Archivos:**
  - El encargo, fuera del repositorio:
    `C:\Users\G513\Documents\Codex\2026-11-07\referenced-chatgpt-conversation-this-is-an-2\outputs\Aethelgard_Encargo_Claude_Opus.txt`.
  - El registro: `D:\Aethelgard_alpha\docs\fase2\registro_encargo.md`.

### D-047
**Sistema de memoria y continuidad**
- **Fecha y estado:** 2026-11-07, hacia las 15:40. Aprobada [usuario]; hecha (T-001).
- **Decisión:**
  - Los documentos de continuidad viven en la raíz del repositorio. [CLAUDE.md](CLAUDE.md) tiene el protocolo de inicio.
  - Consulta obligatoria de la rama `memoria-desarrollo` en GitHub.
  - Se publica según [D-049](#d-049).
- **Archivos:** `CLAUDE.md`, `SESSION_HANDOFF.md`, `TASKS.md`, `MEMORIA_CHAT.md`, `PROJECT_CONTEXT.md`, este archivo,
  `CONTINUAR_EN_NUEVO_CHAT.txt` y [docs/memory/](docs/memory/).

### D-048
**Las magias existentes no cambian; las ampliaciones son plan futuro**
- **Fecha y estado:** 2026-11-07 (encargo único y tarea de memoria). Aprobada [usuario].
- **Decisión:**
  - Se congela el catálogo actual: Fuego, Llamarada, Infierno, Agua, Torrente, Maremoto, Rayo, Tormenta, Cólera del
    Cielo, Cura, Bendición y Gracia Divina.
  - De cada una se conservan el ID, el nombre, el aprendizaje, el coste, el daño, las fórmulas, los objetivos, las
    animaciones y el comportamiento.
  - También se conservan Esgrima, Embuir, Érebo, la Armonía y las reglas base del ATB.
  - Lo nuevo es aditivo y va a fases futuras, según el alcance de cada sesión: magias, estados, tablero, habilidades,
    IA e invocaciones. Las propuestas están en [MEMORIA_CHAT.md](MEMORIA_CHAT.md).

### D-049
**La memoria se publica en `memoria-desarrollo`, y solo la memoria**
- **Fecha y estado:** 2026-11-07, 16:30. Aprobada [usuario]: «autorizo publicar la documentación de memoria revisada en
  la rama memoria-desarrollo».
- **Decisión:**
  - La rama `memoria-desarrollo` sale de `desarollo` y se trabaja en una copia aparte, `D:\Aethelgard_memoria`.
  - Solo lleva los documentos de continuidad de la raíz y `docs/memory/`.
  - La exportación privada del chat **se queda fuera de GitHub**.
  - Se publica tras cada hito. Las palabras del usuario: «La autorización de push se limita a la documentación de
    memoria».
- **Alternativas descartadas:**
  - publicar también los demás documentos de `docs/`: no está autorizado;
  - dejar la memoria solo en local.
- **Consecuencias:**
  - En GitHub no funcionan los enlaces de la memoria a documentos que no están en `desarollo`, como el plan 3D, la
    biblia v3 o los informes de los departamentos.
  - Esos documentos siguen en la copia local, y [CLAUDE.md](CLAUDE.md) lo explica.

### D-050
**Licencias: avanzar con recursos autorizados o sustitutos; el paquete entregable excluye lo no acreditado**
- **Fecha y estado:** 2026-11-07, 16:30. Aprobada [usuario]: «identifica exactamente qué recursos tienen derechos
  pendientes y qué usos bloquean. Avanza en código, integración y pruebas con recursos autorizados o sustitutos. Excluye
  del paquete entregable cualquier recurso cuya distribución no esté acreditada».
- **Interpretación que aplico** [asistente], pendiente de que el usuario la confirme:
  - Un **paquete entregable** es toda APK que vaya a salir del PC para distribuirse: GitHub, otras personas o tiendas.
    No puede llevar nada sin acreditar.
  - Una **compilación de prueba privada** del usuario sigue siendo local y lleva el aviso `NO_DISTRIBUIR`
    ([D-008](#d-008)).
  - Si el usuario quiere que tampoco la prueba en su móvil lleve recursos sin acreditar, se compila una variante con
    sustitutos.
- **Amplía:** [D-008](#d-008). El inventario de licencias está en [T-070](TASKS.md#t-070).

### D-051
**Primera versión de la región 3D de Pastos Verdes**
- **Fecha y estado:** 2026-11-07, hacia las 16:45. Aprobada en el encargo [asistente]: el encargo deja que yo decida
  los detalles técnicos.
- **Decisión:**
  - **Escenario:** `zonas3d/pastos_verdes_3d.gd` hereda del prototipo (`sendero_puente.gd`). No se copia: lo que se
    mejore en el prototipo llega a la región.
  - **Contrato de zona** (`zona.gd`):
    - entrada por el principio del camino;
    - encuentros por pasos: 0,5 m por paso, 40 pasos seguros y probabilidad 0,012, con `progreso.prob_encuentro`;
    - combate con `escena_retorno` y vuelta al mismo sitio (`pos_3d`);
    - guardado automático al entrar y en `guardar_posicion()`.
  - **Salidas:** las dos puntas del camino llevan al mapa.
    - Se marcan con un círculo dorado y el letrero «Mapa del mundo».
    - Una salida solo funciona después de alejarse 2,5 m de ella: así no se sale nada más volver de un combate.
  - **Panel:** quedan CAL (perfil de calidad) y RND (rendimiento), que sirven para probar en el móvil. Los botones de
    los bancos se quitan.
  - **APK experimental:** incluye solo los prototipos de los que depende la región, y `modelos/hojas` y
    `modelos/guardian`.
- **Alternativas descartadas:**
  - **Copiar el escenario en la región:** habría dos versiones que mantener.
  - **Un botón «Mapa»:** no es propio de un JRPG. Se sale andando, como en las zonas 2D.
- **Pendiente:** la misión está en [D-052](#d-052). Faltan Lya y Garon siguiendo a Kael, el cofre y la cinemática del
  mirador (T-022).

### D-052
**La misión del corte alfa dentro de la región**
- **Fecha y estado:** 2026-11-07, hacia las 17:00. Aprobada en el encargo [asistente].
- **El corte en sí** está aprobado por el usuario como alfa y no es canon (D-035). Los textos son los de la biblia v3,
  §6.3.
- **Decisión:**
  - **Disparadores:**
    - PV-02, a los 2,5 s de entrar;
    - PV-03, al llegar a SENDERO[2];
    - PV-05, al hablar con Tilo;
    - PV-06, al acercarse al centinela, solo después de PV-05;
    - PV-07, al volver tras ganar;
    - PV-14, al hablar con Tilo después.
  - Cada escena pone su hito (`progreso.gd`, «hitos») y guarda la partida.
  - **Combate del centinela:** el fijo «pastos_centinela» con `GRUPOS[0]`, dos Grimfang («Quietos. Dos.»). Si se
    pierde, no se repite hasta alejarse y volver.
  - **Tilo:** figura provisional hecha con formas sencillas (abrigo, sombrero y pértiga con el farol), hasta que haya
    un modelo.
  - **La mecha de Tilo:** es un hito («mecha_tilo») con aviso, no un objeto del inventario, para no tocar el catálogo
    de objetos.
  - **Durante un diálogo** Kael se queda quieto y no cuenta pasos.
  - **Tras cerrar un diálogo,** la acción se ignora 0,35 s para que la misma pulsación no abra otro.
- **Alternativas descartadas:**
  - poner la mecha en el inventario: habría que tocar `inventario.gd` y sus menús;
  - usar un sprite 2D de NPC para Tilo: desentona en el 3D.
- **Archivos:** `zonas3d/pastos_verdes_3d.gd`, `pruebas/prueba_ruta_alpha.gd` y `dialogos/pv_*.dtl` (commit `e212400`).

### D-053
**Validación de la región en el Redmi, pedida por el usuario**
- **Fecha y estado:** del 2026-11-07, 17:20, al 2026-11-08, 10:45. Aprobada [usuario]: «Probemos en el Redmi»,
  «Reintenta por USB» y «La instalo yo».
- **Decisión:** es una excepción puntual a [D-013](#d-013), pedida por el usuario y solo para esta validación.
  - Por ADB solo se hizo lo necesario: intentar `adb install`, copiar la APK a Descargas y leer el registro de Godot y
    el CSV del banco de la propia app (`run-as`).
  - No se tocó nada más del móvil.
- **Consecuencias:**
  - Al terminar, el Redmi **vuelve a quedar reservado**.
  - Con Xiaomi, `adb install` necesita que el usuario confirme en la pantalla. Lo más fiable es copiar la APK a
    Descargas y que la instale el usuario.
  - El número de serie no se anota en ningún documento.

### D-054
**Repositorio privado `Aethelgard-pruebas` para descargar las APK de prueba en el móvil**
- **Fecha y estado:** 2026-11-08, hacia las 14:40. Aprobada [usuario], con sus palabras: «Haz una cosa cra en GitHub
  un lugar donde subir las pruebas y súbela allí y las descargo en mi móvil por qué estoy fuera de mis casa».
  - El nombre del repositorio y la forma de las versiones los elegí yo [asistente].
- **Decisión:**
  - **Repositorio:** `https://github.com/Brunopina6/Aethelgard-pruebas`, privado, sin colaboradores y sin incidencias
    ni wiki. Solo contiene un `README.md` con las instrucciones.
  - **Cada APK va como una versión (release)** con la etiqueta `exp-AAAAMMDD-sha7`. Las notas indican el commit de
    origen, el versionCode, el tamaño y el SHA-256.
  - El código del juego **no se sube**: `rebelum-alpha` sigue sin publicar.
  - Tras subir una APK se comprueba que el `digest` de GitHub coincide con el SHA-256 local.
- **Encaje con las licencias** ([D-050](#d-050)):
  - una APK de prueba que solo descarga el usuario en su móvil sigue siendo una prueba privada, aunque viaje por
    GitHub;
  - no es un paquete entregable mientras el repositorio siga privado, sin colaboradores y sin enlaces compartidos;
  - la primera APK (`aabe5ad`) lleva los mismos recursos pendientes que las anteriores, y ninguno es de Suno;
  - **una APK con música de Suno no se sube.** El 08/11, hacia las 14:55, el usuario dijo: «la música de suno no son
    libres». Hasta entonces la regla era preguntar antes.
- **Orden por fecha y versión** (08/11, hacia las 14:55). Aprobada [usuario]: «a partir de ahora ordena las relese de
  pruebas por fecha y versión así siempre tendré las relese de pruebas y la original,con lo demás que configuramos
  sigue igual».
  - **Título:** «DD/MM/AAAA · Prueba vNN», donde NN es el versionCode, que sale de `git rev-list --count HEAD` y
    siempre sube.
  - **Archivo:** `Aethelgard_Exp_AAAA-MM-DD_vNN.apk`. En la carpeta de descargas, el nombre los ordena por fecha.
  - **Etiqueta:** `exp-AAAAMMDD-sha7`, igual que el versionName que muestra el móvil.
  - **`README.md`:** tabla de pruebas de la más nueva a la más antigua, y enlace a la original.
  - **Cada release se etiqueta sobre su propio commit del `README.md`.** GitHub ordena las releases por la fecha del
    commit etiquetado, y así quedan en orden aunque se suban varias el mismo día.
  - **No se borra ni se sustituye ninguna.** La más nueva lleva la marca «Latest».
  - **«La original»** [asistente]: entiendo que es la app estable, «Aethelgard v0.1.0 - Android», que sigue en el
    repositorio principal.
  - **Copia de la original** (08/11, hacia las 15:50). Aprobada [usuario]: «Sí, cópiala».
    - Release «05/11/2026 · Original v0.1.0» (etiqueta `v0.1.0`), con el archivo `Aethelgard_2026-11-05_v0.1.0.apk`.
      Es el mismo archivo que la release del repositorio principal, sin cambios.
    - Va etiquetada sobre el primer commit del repositorio (`8ece9e3`). Así queda la última de la lista, por debajo
      de todas las pruebas, y nunca lleva «Latest».
    - No lleva música de Suno: ningún archivo del APK coincide con las pistas.
- **Primera subida:** `exp-20261108-aabe5ad` ([T-079](TASKS.md#t-079)).
- **Enlace estable a la última:** `https://github.com/Brunopina6/Aethelgard-pruebas/releases/latest`.
- **Alternativas descartadas:**
  - **Una versión en `Brunopina6/Aethelgard`:** obliga a crear etiquetas en el repositorio del juego. Además, la APK
    sale de commits que no están publicados.
  - **Subir la APK al repositorio como archivo:** GitHub no admite archivos de más de 100 MB fuera de las versiones.

### D-055
**Lya y Garon siguen a Kael en la exploración 3D**
- **Fecha y estado:** 2026-11-08, hacia las 16:10. Aprobada en el encargo [asistente], después de que el usuario
  dijera «Sí, empieza» (T-022).
- **Decisión** (`zonas3d/grupo_3d.gd`, rama `rebelum-alpha`):
  - **Quién sale:** los que estén en el grupo de la partida (`grupo.gd`, `EN_EL_GRUPO`), menos Kael, y tengan modelo 3D.
    Son los mismos scripts del combate (`maga_3d.gd` y `garon_3d.gd`).
  - **Cómo siguen:**
    - cada uno sigue al de delante: Lya a Kael y Garon a Lya;
    - recorren el rastro de puntos que deja el de delante, así que pasan por donde pasó él (el puente, la orilla, los
      rodeos) y no pisan el río;
    - se paran a 1,8 m del de delante; con 1,5 m, el sable de Kael casi rozaba a Lya en las capturas;
    - van a su paso y aceleran si se quedan atrás. Andan o corren según la velocidad, con las animaciones al ritmo.
  - **Media vuelta:** si el de delante viene hacia uno y está a menos de 0,9 m, se aparta a un lado. En el puente,
    el sitio para apartarse es más estrecho.
  - **Reaparecer:** si el de delante aparece en otro sitio (vuelta de un combate) o se aleja más de 8 m, se colocan
    detrás de él. Al entrar en la región, se colocan en V detrás de Kael.
  - **Sin colisión:** no estorban a Kael ni a los toques en el suelo. El suelo se comprueba con las reglas de Kael
    (escalón, pendiente, rodillas y zonas prohibidas).
  - **Tamaños:** los del combate. Lya mide un 10 % menos que Kael y Garon.
  - **Garon quieto:** usa la guardia tranquila de `garon_3d.gd`, con las espadas bajas. La guardia de combate le
    hacía apuntar a Lya con las dos espadas.
  - **Medir:** con «grupo»: false en el perfil no salen. El botón GRUPO compara sin grupo y con grupo en los tres
    perfiles.
- **Alternativas descartadas:**
  - **«Serpiente»** (cada uno a una distancia fija sobre el rastro de Kael): al dar media vuelta, atraviesan a Kael.
  - **Navegación con NavigationAgent3D:** cuesta más y necesita una malla de navegación de cada región.
  - **Darles colisión:** en el puente, que es estrecho, encerrarían a Kael.
- **Pendiente:** la opinión visual del usuario y la medición en el Redmi con el botón GRUPO.

### D-056
**Guardado protegido: no pisar sin cargar, escritura segura y copia de seguridad**
- **Fecha y estado:** 2026-11-08, hacia las 17:00. Aprobada en el encargo [asistente]. El usuario pidió proteger el
  guardado antes de ampliar el autoguardado (T-076 y T-077).
- **Decisión** (`progreso.gd`, rama `rebelum-alpha`, `86a58af`):
  - Solo se guarda encima de una partida si la sesión la cargó o no había ninguna (Engine `partida_lista`, que no se
    guarda). Lo ponen `cargar()` y `restaurar()`.
  - Escritura en tres pasos: `.tmp`, comprobación leyéndolo, y sustitución. La anterior, si se podía leer, queda en
    `.bak`.
  - Al cargar: la partida, o si no se puede leer, `.tmp` y después `.bak`. La que no se podía leer se copia a
    `.danada`: no se borra nada.
  - Las pruebas guardan solo en su propio archivo (`archivo_partida_prueba`), nunca en `partida.save` ni en
    `partida_exp.save`.
  - El formato no cambia: las partidas antiguas cargan igual y una versión antigua lee las nuevas.
  - `inventario.gd` completa con el inventario inicial lo que falte en una partida antigua.
- **Ampliado en `e670a5d`** ([D-060](#d-060)): el jugador recibe un aviso si no se pudo guardar, si se recuperó una
  copia o si no se pudo leer nada; con las dos copias dañadas se apartan las dos (`.danada` y `.bak.danada`) y empieza
  una partida nueva.
- **Alcance, según lo comprobado** (`prueba_partida`, casos 1-8, con partidas sintéticas en un archivo propio): sesión
  sin cargar, guardar y cargar, partida antigua, partida dañada con copia buena, escritura fallida, corte a medias, las
  dos copias dañadas y partida nueva. **Reduce el riesgo de perder la partida; no lo elimina.** Sin comprobar: un fallo
  real del almacenamiento del móvil o quedarse sin espacio en Android.
- **Alternativas descartadas:**
  - **Mezclar la sesión con la partida guardada:** no evita el daño, porque la sesión ya trae datos por defecto (el
    grupo a nivel 1) que pisarían los buenos.
  - **No guardar nunca si no se cargó:** impediría la primera partida en una instalación nueva.

### D-057
**El cofre del árbol mágico de Pastos Verdes 3D**
- **Fecha y estado:** 2026-11-08, hacia las 17:05. Aprobada en el encargo [asistente]. El usuario pidió integrar el
  cofre con un identificador persistente, el premio una sola vez y respuesta visual y sonora.
- **Decisión** (`zonas3d/pastos_verdes_3d.gd`, `d4db508`):
  - **Dónde:** junto al árbol mágico de la salida del puente (16, 2). Queda del lado de la cámara para que la copa no
    lo tape, fuera del camino y en un hueco sin troncos ni rocas: (14,8, 0, 3,6). Es un premio por cruzar el puente y
    se ve desde él.
  - **Aspecto:** formas sencillas hechas por código (madera, herrajes dorados y tapa curva), sin modelos de terceros.
    La cerradura mira a la cámara, que nunca gira; de espaldas parecía un barril.
  - **Respuesta:**
    - cerrado, un destello que late;
    - al abrirlo, la tapa gira, hay un destello dorado, salen las monedas del fondo y el aviso «¡Has encontrado…!»;
    - un sonido hecho por código, como los del menú: un golpe de madera y un arpegio. Dura 0,9 s, con un pico de
      0,48.
  - **Persistencia:** `cofres_abiertos["pastos3d_arbol_magico"]`, la misma estructura que los cofres 2D. Se apunta
    antes de dar el premio y después se guarda la partida.
  - **Premio:** la tabla de los cofres 2D (monedas, pociones o éter), con la semilla del identificador. Este da 50
    monedas.
  - **Si el guardado falla,** el cofre y el premio se pierden juntos, porque van en el mismo archivo: nunca se repite el
    premio.
  - **El inventario no tiene límites de cantidad.** Una partida antigua sin lista de objetos ya no rompe el premio
    ([D-056](#d-056)).
- **Alternativas descartadas:**
  - **Un modelo de cofre de un paquete:** no hay ninguno acreditado en el proyecto.
  - **Ponerlo en el mirador:** se mezclaba con el combate del centinela y con la cinemática.

### D-058
**La cinemática del mirador (PV-07)**
- **Fecha y estado:** 2026-11-08, hacia las 17:10. Aprobada en el encargo [asistente]. Sigue la biblia v3 §6.2
  (PV-07), aprobada como alfa y no como canon.
- **Decisión** (`zonas3d/pastos_verdes_3d.gd`, `d4db508`):
  - **Cuándo:** al volver al mirador tras vencer al centinela, como antes la conversación PV-07.
  - **Qué se ve:** 11 s de plano guiado, sin texto:
    - baja hacia la cascada;
    - la mira desde arriba;
    - alza la vista hasta la ciudad flotante.
    - Después hay 1,2 s de vuelta a la cámara de juego y empieza la conversación PV-07, que ya existía.
  - **Planos revisados con capturas:** a menor altura se veían laderas peladas y las lomas del norte tapaban la ciudad.
    El final va a 22 m y deja cielo bajo la ciudad.
  - **Sonido:** campanas hechas por código. No hay música porque «Promised Horizon» es de Suno y no es libre.
  - **Se salta** con el botón «Saltar», Intro o Escape. Mientras dura, no hay control, se ocultan los botones del panel
    y salen franjas negras. Lya y Garon se quedan quietos.
  - **El hito `pv_07` se pone y se guarda antes de la animación.** La animación solo enseña. Saltarla o cerrar la app a
    medias no la repite ni duplica nada. En las visitas posteriores no vuelve a empezar.
  - **Canon:** no revela nada de Érebo ni de los corazones o recuerdos. La ciudad y la cascada ya estaban en la escena.
- **Pendiente:**
  - el latido del ojo del centinela, que la biblia también propone;
  - escuchar las campanas.

### D-059
**El grupo se une con la misión; objetivo y marcador en pantalla**
- **Fecha y estado:** 2026-11-08, hacia las 17:25. Aprobada en el encargo [asistente] (encargo §3 y §4: seguir el lore
  existente, y que el recorrido se entienda en pantalla pequeña).
- **Decisión** (`zonas3d/pastos_verdes_3d.gd` y `zonas3d/grupo_3d.gd`, `3d5f63d`):
  - **Quién acompaña a Kael:** en los diálogos de la misión, Lya llega en PV-03 («¡Kael! ¿De verdad pensabas irte sin
    mí?») y Garon en PV-05, junto a Tilo («Os acompaño»).
    - En la v41 y la v44 los dos seguían a Kael desde la entrada, y eso contradecía la escena. Ahora Kael llega solo.
    - Lya aparece por el camino, detrás, al cerrarse PV-03. Garon aparece junto a Tilo al cerrarse PV-05.
    - En los bancos salen siempre los dos.
  - **Objetivo:** una línea arriba a la izquierda. Se oculta en diálogos, en la cinemática y en los bancos. Los textos
    salen de los diálogos, sin contar nada nuevo:
    - «Sigue el camino»;
    - «Sigue el camino hasta el puente»;
    - «Saluda al centinela del mirador»;
    - «Vuelve junto al centinela»;
    - «Vuelve a hablar con Tilo»;
    - «Sigue el camino hacia el noreste».
  - **Marcador:** un rombo dorado que gira, del mismo dorado que las salidas. Va sobre Tilo cuando toca hablar con él y
    sobre el centinela cuando toca ir al mirador.
  - **Antes y después:**
    - antes, `D:\REBELUM_diagnostico\pruebas\2026-11-08_171143\prueba_region3d_fotos\bajo_cofre_1_desde_el_camino.png`;
    - después, la misma captura en `...\2026-11-08_172633\...`, con el objetivo y el rombo sobre Tilo.
    - El rombo del centinela se bajó de 4,4 a 3,6 m porque se salía por arriba.
- **Pendiente (resuelto en [D-060](#d-060)):** los combates por pasos antes de PV-03 metían a Lya y Garon en el
  combate, porque `combate.gd` usaba el grupo de la partida.

### D-060
**El grupo activo manda: exploración, combate, menús y guardado; encuentros para Kael solo**
- **Fecha y estado:** 2026-11-08, hacia las 17:50. Aprobada [usuario]: «Antes de que Lya se una en PV-03, los combates
  aleatorios deben ser solo de Kael. Desde PV-03 participarán Kael y Lya, y desde PV-05 se incorporará Garon». Lo
  implementé yo [asistente].
- **Decisión** (`grupo.gd`, `combate.gd`, `menus.gd`, `tienda.gd`, `progreso.gd`, `recursos.gd`, `carga.gd` y
  `zonas3d/pastos_verdes_3d.gd`; `e670a5d`):
  - **Fuente común:** el grupo activo (`grupo_activo`, que se guarda). Lo usan la exploración, el combate, los menús, la
    tienda, el nivel del grupo y el guardado.
  - **En la versión experimental,** la misión empieza con Kael solo; Lya se une en PV-03 y Garon en PV-05.
  - **Quien se une conserva sus datos** (nivel, experiencia, atributos, vida y PM) y sube como siempre: con la
    experiencia de los combates en que lucha (`progreso.gd` da más a quien va por debajo del nivel de la zona).
    - **Corregido el 2026-11-08 por la noche**, a petición del usuario: en `e670a5d` puse que quien se unía llegaba al
      nivel del más alto y descansado. Esa regla no existía; la introduje yo. Se quitó, y queda como propuesta
      ([D-062](#d-062)).
  - **Los ausentes** conservan sus datos, no actúan, no son objetivo y no cambian (curar tras una derrota solo cura a
    los presentes).
  - **Partidas de antes:** sin la clave y con la misión empezada, el grupo sale de los hitos; sin la misión, siguen con
    todos. La versión estable no cambia.
  - **Encuentros al azar según cuántos son:**
    - con uno: un slime, dos slimes o un Grimfang;
    - con dos: tres slimes, Grimfang y slime, dos slimes o un Grimfang;
    - con tres, como siempre.
    - Los combates fijos y las magias no cambian, y ningún enemigo aturde ni duerme: Kael solo no puede quedar
      bloqueado.
  - **Guardado:** avisos al jugador ([D-056](#d-056)).
  - **Opción de desarrollo** (solo en la versión experimental): «Probar la misión desde el principio», en la pantalla de
    carga. Juega en otra ranura (`partida_exp_prueba.save`), desde cero y entrando en Pastos Verdes. La partida de
    siempre no se toca, y una etiqueta avisa de que es una partida de prueba.
- **Comprobado** (batería `2026-11-08_175301`: 27 superadas, 0 fallidas y 13 manuales; la partida real no cambió):
  - `prueba_grupos_combate`, nueva, con grupos de 1, 2 y 3:
    - gana todos sus grupos al azar solo atacando (Kael solo: 21, 39 y 47 s de juego);
    - huir y perder;
    - los ausentes ni actúan ni cambian;
    - guardar y cargar, partidas de antes, partida nueva y el menú del grupo.
  - `prueba_partida` (casos 7 y 8, nuevos) y `prueba_ranura_prueba`, nueva.
- **Alcance:** los combates se ganan con ataques automáticos, sin magias ni objetos; no prueba la estrategia de un
  jugador.

### D-061
**Sin tirones al abrir diálogos ni al ver algo por primera vez: se prepara en las cargas**
- **Fecha y estado:** 2026-11-08, hacia las 19:00. Aprobada en el encargo [asistente], por la petición del usuario:
  «Continúa después con los tirones del primer diálogo y de los primeros efectos visuales. Mide arranque en frío y
  recorridos posteriores por separado».
- **Decisión** (rama `rebelum-alpha`):
  - **Diálogos** (`recursos.gd`, `carga.gd`, `boton_dialogo.gd` y `project.godot`):
    - Dialogic borraba su interfaz al acabar cada diálogo y la rehacía en el siguiente.
    - Ahora se oculta (`dialogic/layout/end_behaviour` = 1).
    - La pantalla de carga lee su estilo en segundo plano y, en un paso propio, la crea oculta y le pone el estilo de la
      biblia de arte.
    - Al acabar cada diálogo, Recursos limpia el texto, el nombre y los retratos: el siguiente no enseña nada del
      anterior.
  - **Oclusión** (`prototipos/vista3d.gd` y `prototipos/sendero_puente.gd`):
    - lo que tapa a Kael usa una copia transparente de su material, hecha una vez y guardada mientras dura la escena;
    - antes, las copas creaban un material nuevo en cada oclusión y Godot preparaba otra vez su sombreado.
    - Se ve igual: los mismos parámetros, que solo se ponen al construir los árboles.
  - **Vitrina** (`vista3d.gd`, `_preparar_sombreados`): al entrar en la región, con la pantalla aún en negro, se dibuja
    dos fotogramas, en miniatura delante de la cámara, una copia de cada material de la escena y de las copias
    transparentes.
- **Medido en el PC** (`pruebas/medir_primeras_veces.gd`; datos y tabla en
  `D:\REBELUM_diagnostico\primeras_veces\comparacion.md`):

  | | Antes | Después |
  |---|---|---|
  | Primer diálogo | 184 ms | 9-11 ms |
  | Cada diálogo siguiente | 54-56 ms | 6-7 ms |
  | Primer paseo tras instalar (fotograma más lento) | 41 ms, y otros de 37, 25 y 23 ms | 4,0 ms |
  | Primer paseo con caché / al volver a entrar | 18-20 ms | 4-5 ms |
  | Cada vez que un árbol tapa a Kael | unos 11 ms (normal: 3,3) | 3-4,7 ms |

- **Lo que se lleva a las cargas** (PC):
  - la pantalla de carga gana un fotograma de unos 30 ms (leer el estilo va en segundo plano);
  - la entrada en la región, en negro, pasa de 1,21 a 1,43 s tras instalar, de 1,03 a 1,10-1,13 s con caché y de
    0,87-0,89 a 0,94-1,01 s al volver a entrar.
- **Sin comprobar:** el Redmi (tiempos de carga, tirones que queden y si la caché de sombreados de Godot funciona en el
  Mali-G57).

### D-062
**Nivelación automática de quien se une al grupo**
- **Fecha y estado:** 2026-11-08 por la noche. **Propuesta, pendiente de la decisión del usuario** [asistente]. El
  usuario pidió registrarla así: «Registra la nivelación automática como propuesta pendiente de mi decisión».
- **Qué se propone:** que quien se une al grupo activo (Lya en PV-03, Garon en PV-05) llegue al nivel del más alto del
  grupo, con los puntos de atributo de esos niveles para repartir, y con la vida y los PM llenos.
- **Historia:** lo puse en `e670a5d` sin que existiera esa regla en el juego. Se quitó el mismo día ([D-060](#d-060)):
  ahora quien se une conserva sus datos.
- **Lo que ya existía** (desde `fd71d6a`, `grupo.gd`, `datos()`): si a una partida antigua le falta un héroe, se crea
  al nivel más alto del grupo (el comentario dice «medio», pero el código toma el más alto). Solo crea datos que faltan;
  no cambia a nadie que ya los tenga.
- **A favor:** nadie llega muy por debajo del grupo, y los combates de dos y tres héroes se equilibran mejor.
- **En contra:** cambia la progresión del juego. Además, el juego ya tiene su forma de compensar: más experiencia para
  quien va por debajo del nivel de la zona.
- **Comprobado:** los encuentros al azar de dos y tres héroes se ganan con todos en el nivel 1, el peor caso
  (`prueba_grupos_combate`).

### D-063
**Teclado y mando: acciones, foco visible y una pulsación, una acción (T-025)**
- **Fecha y estado:** 2026-11-08 por la noche. Aprobada en el encargo [asistente], por la orden del usuario: «continúa
  con estabilidad y controles, T-025 […] prioriza los controles de Android y PC». Sigue el plan de
  [docs/entrada/android_tv_dualshock4_plan.md](docs/entrada/android_tv_dualshock4_plan.md) (fases 2A, 2B y parte de
  2C y 2E), sin la parte de Android TV.
- **Decisión** (rama `rebelum-alpha`):
  - **Acciones** (`project.godot`). Ya existían `ui_accept` (Intro, Espacio, A/✕) y `ui_cancel` (Esc, B/○). Nuevas:
    - `menu_juego`: Tab, Esc y Start/Options;
    - `pestana_anterior` y `pestana_siguiente`: Q y E, RePág y AvPág, L1 y R1;
    - `camara_acercar` y `camara_alejar`: + y -, y el stick derecho.
    - Andar sigue con las `ui_*` de Godot (flechas, cruceta y stick izquierdo), y WASD en 3D.
  - **Autoload `Entrada`** (`entrada.gd`):
    - sabe si se juega con el dedo o el ratón, con el teclado o con el mando (mira cada evento al llegar a la
      ventana);
    - da el foco y lo devuelve al mismo botón cuando una ventana se repinta;
    - encadena los botones sueltos para las flechas;
    - si se desconecta un mando, suelta lo que tuviera pulsado y avisa de que se puede seguir con la pantalla o el
      teclado.
  - **Foco visible:** un marco dorado (`estilo.gd`). Godot 4.7 solo lo dibuja al navegar con teclado o mando; al tocar
    o hacer clic, los botones se ven como siempre.
  - **Exploración** (mapa, ciudad e isla; la región 3D ya lo tenía):
    - los botones de la pantalla ya no cogen el foco al tocarlos;
    - Intro / A pulsa el botón de acción que se ve (Entrar, Examinar, Hablar, Abrir cofre, Bajar al mundo);
    - Tab, Esc o Start ponen el foco en la barra del mapa o en los botones de la ciudad, y el personaje se para;
    - Esc / B, o un toque, lo quitan.
  - **Ventanas** (grupo, objetos, habilidades, tienda y diario):
    - el foco empieza en la pestaña y se conserva al comprar, equipar o subir atributos;
    - Esc / B cierran (o vuelven atrás en la tienda);
    - Q / E (L1 / R1) cambian de pestaña;
    - ↑ ↓ desplazan el texto.
  - **Combate:** L1 / R1 (Q / E) cambian las pestañas de magia I · II · III, e Intro / A o Esc / B saltan la
    invocación. Antes, las dos cosas solo iban tocando.
  - **Diálogos:**
    - **una pulsación, una acción.** Dialogic contaba cualquier otro evento del mismo fotograma (el temblor del stick,
      la misma tecla que abría el diálogo). `BotonDialogo` se queda con esos eventos de más;
    - el botón «SEGUIR» no coge el foco.
  - **Pantalla de carga:** el texto dice qué pulsar («PULSA INTRO» o «PULSA A»). ↓ elige «Probar la misión desde el
    principio» e Intro / A lo pulsa; el botón se conserva.
  - **Región 3D:** zoom con + / - o el stick derecho.
- **Lo que no se hace aún:**
  - no hay pantalla de ajustes;
  - los textos del combate siguen diciendo «TOCA UN ENEMIGO»;
  - no hay iconos de los botones de cada mando;
  - fuera del combate, Atrás de Android no hace nada (no hay pausa ni salir);
  - Android TV queda para después.
- **Commit:** `e6e52c4` (`rebelum-alpha`).
- **Comprobado con eventos simulados en el PC** (teclas y botones de mando de verdad, inyectados en Godot; no hay
  ningún mando conectado a este PC): `prueba_foco`, `prueba_mando`, `prueba_teclado`, `prueba_dialogo_interfaz` y
  `prueba_precalentado`. Las pruebas táctiles anteriores siguen en verde. Batería `2026-11-08_195103`: 32 superadas y
  0 fallidas. Las capturas del foco, revisadas a ojo.
- **Sin comprobar con hardware:** el Redmi (táctil), un mando real y un teclado real.

### D-064
**Base del audio: buses, volúmenes guardados y pestaña «Ajustes» (T-030)**
- **Fecha y estado:** 2026-11-08 por la noche. Aprobada en el encargo [asistente]: es el paso siguiente por
  dependencias (estabilidad, controles, **audio** e integración), dentro de la orden «continúa después con el siguiente
  trabajo autorizado que puedas realizar localmente». Hace la parte técnica de [D-043](#d-043); el reparto de las
  pistas sigue sin decidir y las canciones de Suno no están en el proyecto.
- **Decisión** (rama `rebelum-alpha`):
  - **Buses** (`default_bus_layout.tres`): Musica, Efectos, Interfaz y Ambiente, todos hacia Master y a 0 dB. Con
    todo al 100 %, todo suena igual que antes.
  - **Cada sonido, a su bus:**
    - Musica: la música del combate y las campanas de la cinemática del mirador (son una melodía);
    - Efectos: Érebo y el cofre;
    - Interfaz: los tonos de la carga y del menú del combate, y el sonido al escribir de Dialogic
      (`dialogic/audio/type_sound_bus`);
    - Ambiente: lista para los sonidos de ambiente, que aún no hay. Por eso no sale en los ajustes.
  - **Volúmenes** (autoload `Sonido`, `sonido.gd`): de 0 a 100 % por bus; 0 silencia.
    - Se guardan en `user://ajustes.cfg`, aparte de la partida, y solo cuando el jugador los cambia: abrir el juego no
      escribe nada.
    - Un valor que no es un número deja ese bus al 100 %.
  - **Pestaña «Ajustes»** del menú del grupo: Música, Efectos e Interfaz con ◀ ▶ (un 10 % cada pulsación), la cifra y
    una barra dorada, como las filas del equipo. Con teclado o mando, el foco se queda en el mismo botón.
  - **Al cambiar un volumen suena una muestra corta** por ese bus, hecha por código a 11 025 Hz: dos notas de campana,
    un destello o un «tic». Primero probé con la campana del mirador y el cofre, pero la primera pulsación tardaba unos
    180 ms en el PC (un parón en el móvil). Con las muestras ligeras, unos 18 ms con 6 fotogramas incluidos.
- **Lo que no se hace aún:** el gestor de música con fundidos, los sonidos de ambiente, el inventario de cada sonido
  (criterio de T-030) y la escucha.
- **Comprobado** (aislado, sin ventana; prueba **muda**: adónde va cada sonido y con qué volumen, no cómo suena):
  `prueba_audio`. Captura de la pestaña revisada a ojo (`prueba_foco_fotos`, captura 8).
- **Sin comprobar:** cómo suena (en el PC y en el Redmi) y si el 50 % se oye como «la mitad».

### D-065
**El Redmi recibe por USB las APK de prueba en Descargas; instalar es cosa del usuario**
- **Fecha y estado:** 2026-11-08, hacia las 20:20. Aprobada [usuario]: «Autorizo expresamente el acceso al Redmi
  conectado por USB para comprobar la conexión y copiar las APK de prueba nuevas a su carpeta Descargas. Esta
  autorización sustituye la restricción anterior de móvil reservado únicamente para estas operaciones. Yo instalaré
  las APK manualmente.»
- **Decisión:**
  - por USB (ADB o transferencia de archivos): comprobar la conexión y copiar a Descargas las APK de prueba nuevas,
    exactas y verificadas, con su nombre de fecha y versión, sin borrar las anteriores;
  - comprobar la copia con el tamaño y el SHA-256 en el propio teléfono, y decir al usuario el archivo y qué probar;
  - si hay varios dispositivos, identificar el Redmi antes de copiar; si falta el cable, la transferencia de archivos
    o la autorización de depuración, decir qué seleccionar y seguir con el trabajo local;
  - instalar, desinstalar, borrar datos, ejecutar pruebas en el teléfono y cambiar ajustes, solo el usuario (salvo
    autorización posterior). La app estable y sus datos no se tocan. Las releases privadas siguen con D-054.
- **Sustituye en parte** a la reserva del Redmi ([D-013](#d-013)): solo para estas operaciones.
- **Primera entrega** (08/11, 20:24): la Prueba v54 en `Download/Aethelgard_Exp_2026-11-08_v54.apk`, con el mismo
  tamaño (256 658 545 bytes) y SHA-256 (`c00f0ff6…`) en el teléfono. ADB del SDK ya instalado; un único dispositivo,
  el REDMI A7 Pro (Android 16), autorizado. Nada más en el teléfono se ha tocado.

### D-066
**La protección del guardado, traída a la copia habitual (`rebelum-3d`)**
- **Fecha y estado:** 2026-11-08, 20:36. Aprobada [usuario]: «Autorizo trasladar únicamente la corrección de
  protección del guardado a la copia habitual si puedes hacerlo de forma pequeña, reversible y compatible con sus
  cambios locales. Prepara antes un respaldo […] Valídala en una copia aislada antes de aplicarla.»
- **Decisión:** solo `progreso.gd` (la protección de `86a58af`, sin la partida experimental 3D) e `inventario.gd` (3
  líneas), en un commit local de `rebelum-3d` (`b8e042d`) que se deshace con `git revert`. Nada del bloque B se toca.
- **Respaldo previo:** `D:\REBELUM_respaldos\2026-11-08_antes_guardado_copia_habitual` (los dos scripts, una copia
  leída de la partida actual, el diff del bloque B con su huella y el estado de Git).
- **Validación en una copia aislada** (árbol de trabajo `D:\Aethelgard_guardado`, con el mismo estado que la copia
  habitual, bloque B incluido; con datos aislados):
  - batería sin el arreglo: 15 superadas y 2 fallidas (`prueba_escenas` y `prueba_menu_magia`, que ya fallaban en
    `rebelum-3d`); con el arreglo y `prueba_guardado_protegido`: 16 superadas y las mismas 2 fallidas;
  - **de punta a punta**, como una sesión normal: con una partida completa guardada, abrir `mapa.tscn` suelto (como
    F6) y cerrar la ventana. **Sin el arreglo**, la partida se reescribe y pierde `grupo` e `inventario` (queda con
    `escena_guardada`, `pos_mapa`, `pos_mapa_ok` y `prologo_visto`); **con el arreglo**, no cambia y sale el aviso
    «Esta sesión no cargó la partida».
- **Comprobado después:** el bloque B es idéntico al del respaldo, byte a byte en su diff.
- **Lo que no cambia:** la partida actual del PC se conserva tal cual ([D-011](#d-011)); el ejecutor de pruebas de
  `rebelum-3d` sigue siendo el antiguo (ver [D-010](#d-010)): traer el nuevo necesitaría otra autorización.

### D-067
**Gestor de música y ambiente por contexto, con ambientes CC0 (T-030)**
- **Fecha y estado:** 2026-11-08 por la noche. Aprobada en el encargo [usuario]: «Sí, continúa T-030 aprovechando los
  buses y ajustes ya implementados. Integra música por contexto, transiciones y retorno del combate […] Cuando falte un
  recurso autorizado, continúa con un sustituto adecuado o una transición silenciosa controlada.»
- **Decisión** (`rebelum-alpha`, `40fb5b8`):
  - autoload `Musica` (`musica.gd`): dos capas (música y ambiente) con dos reproductores cada una para fundir; mira la
    escena cada fotograma y pide su contexto; la misma pista sigue sin cortes; sin pista con permiso, silencio
    controlado; al pausar la app, pausa;
  - el combate conserva su música (`combate.gd`); la exploración se calla con un fundido, recuerda por dónde iba y
    sigue al volver (gane, huya o pierda);
  - **ambientes CC0** de la biblioteca del usuario (`D:\qtorrent\sound effect`, colección de 500 con la fuente de cada
    archivo): pradera (pájaros y viento), bosque, viento, mazmorra y desierto. CC0 comprobado en cada página de
    OpenGameArt el 08/11. Bucles de 32 s como mucho, sonoridad pareja, QOA: 5,6 MB en la APK;
  - **no hay música con permiso** para la exploración (las canciones de Suno no son libres y no están en el
    proyecto): esa capa queda en silencio controlado. La de combate (`musica_combate_normal`) sigue con su licencia
    pendiente, como antes.
- **Evidencia, por separado** ([docs/audio/inventario_sonidos.md] en `rebelum-alpha`):
  - asignación: `prueba_musica` (muda), con el recorrido real mapa → Oakhaven → combate → mapa;
  - señal: `prueba_musica_senal` (con ventana y el driver real): ambientes de −29 a −39 dBFS, combate −20 dBFS, carga
    −120 dBFS (silencio); deja los WAV para escucharlos;
  - escucha real: **pendiente** (la hace el usuario; Prueba v57).
- **Candidatos sin usar:** el resto de la colección CC0 y los paquetes GDC de Sonniss («ROYALTY-FREE»). El paquete de
  TomMusic no dice su licencia: no se usa.

### D-068
**El prólogo con puesta en escena, retratos vivos y caja de texto legible (T-081)**
- **Fecha y estado:** 2026-11-08 por la noche. Aprobada en el encargo [usuario]: «El diálogo que aparece al abrir el
  juego me parece pobre. Quiero mejorar su presentación y las animaciones de los personajes.»
- **Cuál es:** con el arranque normal y una partida nueva, el prólogo de Kael y Lya (`dialogos/prologo.dtl`, 9
  frases) en el mapa del mundo (`mapa.gd`). Con una partida existente no sale ningún diálogo al abrir. Con «Probar la
  misión desde el principio», lo primero es PV-02 (Kael solo, en la región 3D).
- **Antes** (capturas en `D:\REBELUM_diagnostico\prologo_antes_despues\antes\`): retratos 2D de cuerpo entero sobre el
  mapa sin atenuar, con sus rótulos y el muñeco de Kael detrás; nada indica quién habla salvo el nombre; caja de 550 px
  (la frase 5 en tres líneas); sin entrada; la caja salía a los 2,3 s.
- **Decisión** (`rebelum-alpha`):
  - **Puesta en escena** (`escena_dialogo.gd`, solo para el prólogo): el mapa se oscurece con una viñeta, bajan dos
    franjas de cine, la cámara se acerca un 15 % y aparece el título «Prólogo»; el muñeco del mapa se oculta. «Saltar
    ▸▸» (o Esc / B) termina la escena; al acabar o saltar, cámara, capas y control vuelven como estaban.
  - **El diálogo arranca en el fotograma de llegada, aún en negro, en pausa y transparente**, y aparece con un fundido
    tras la entrada: lo que Dialogic hace la primera vez (unos 60-70 ms en el PC, casi todo fuera del dibujo) se sigue
    pagando donde no se ve, como antes.
  - **Retrato vivo** (`dialogos/retrato_vivo.gd`, retrato «vivo» de Kael y Lya; el «normal» no cambia): respiración
    desde los pies, foco (quien habla se ilumina y se adelanta; quien escucha se atenúa un poco), y gestos breves en 6
    de las 9 frases (inquieta, ligero, duda, sorpresa, decidido, preocupada) que vuelven al reposo.
  - **Texto:** el mismo, con pausas breves en los puntos suspensivos (`[pause]`). Hechos, hitos y canon, iguales.
  - **Caja de texto, para todos los diálogos** (`boton_dialogo.gd`): 880 px de ancho, letra de 28 px con más
    interlínea y márgenes, indicador de «sigue» en dorado y opciones más grandes. «SEGUIR» no se ve mientras Dialogic
    está en pausa.
- **Reutilizado:** las ilustraciones de los retratos, los ganchos de Dialogic (`_highlight`, `extra_data`), la cámara del
  mapa, las letras y colores de `estilo.gd`. **Creado:** el retrato vivo (gestos por código), la capa de escena y su
  prueba. **No posible en 2D:** miradas o expresiones nuevas (una sola ilustración por personaje).
- **Medido en el PC** (con ventana, `--fixed-fps 30`; misma prueba en las dos versiones, `prueba_prologo_fotos medir`):
  peor fotograma desde que se llega al mapa 9,6-11,4 ms antes y 9,9-10,8 ms después (una pasada de cinco, 101 ms); p95
  y mediana iguales (7,5 y 6,9 ms); memoria estática al terminar, unos 2 MB más (137,0 frente a 135,1 MB). Una
  versión intermedia, que arrancaba Dialogic tras la entrada, daba un tirón de 61-95 ms y se descartó.
- **Comprobado:** `prueba_prologo` (sin ventana: entero, saltado a mitad y durante la entrada; todo vuelve; sin
  hitos) y `prueba_prologo_fotos` (con ventana: una pulsación completa la frase que se escribe y la siguiente avanza;
  Dialogic ignora a propósito las pulsaciones en los 0,1 s tras escribir una frase, para no saltarse dos).
- **Pendiente:** verlo en el Redmi; extender el estilo a los demás diálogos; en los diálogos 3D (PV-02 y siguientes),
  gestos con clips (Lya no tiene reposo; Blender 5.2 está instalado).
- **Commit:** `375cc8c` en `rebelum-alpha` (08/11, 21:57), con la batería completa en verde.

### D-069
**Organización por especialistas: un coordinador y cinco subagentes**
- **Fecha y estado:** 2026-11-08, 22:00. Aprobada [usuario]: «Organiza el desarrollo de AETHELGARD mediante subagentes
  especializados, con un agente principal que coordine, revise e integre su trabajo. Quiero cinco áreas: gráficos,
  sonido, narrativa, combate y animaciones.»
- **Coordinador:**
  - contrasta la memoria con el repositorio;
  - reparte tareas acotadas, con archivos asignados, dependencias y criterios de aceptación;
  - decide quién edita cada archivo compartido;
  - revisa, integra y hace las comprobaciones finales;
  - mantiene la memoria central y publica lo autorizado.
- **Especialistas:** cada uno recibe el contexto, las restricciones y la versión de partida, y trabaja en su copia de
  trabajo y su rama. Entrega un informe en `docs/memory/agents/<área>.md`: archivos modificados, pruebas, resultados,
  límites y siguiente paso.
- **Archivos compartidos:** un solo responsable de edición a la vez; los demás le piden los cambios.
- **Concurrencia:** moderada, por tandas. Nunca dos compilaciones, importaciones o medidas que compitan: una medida se
  hace sin otra carga en el PC.
- **Orden:**
  1. tanda 1: sonido y animaciones;
  2. tanda 2: el mapamundi, y narrativa con animaciones;
  3. tanda 3: combate con sonido;
  4. integración y recorrido completo.
- **Si una capacidad no está disponible** (por ejemplo, un tipo de subagente propio), se dice y se mantiene el reparto
  trabajando por turnos.
- **Comprobado (22:25):**
  - los subagentes son reales y trabajan en segundo plano;
  - los tipos propios de `.claude/agents/` no se cargan en una sesión que empezó sin esa carpeta; mientras tanto, se
    lanzan como `general-purpose` que leen su archivo;
  - el aislamiento automático parte de `main`, así que cada especialista usa una copia de trabajo manual en
    `D:\Aethelgard_<área>`, rama `area-<área>`, que parte de `integracion-experimental`;
  - la rama de integración es `integracion-experimental`, en `D:\Aethelgard_alpha`; `rebelum-alpha` se queda en
    `375cc8c`.

### D-070
**Ampliación de la autorización de GitHub: ramas de trabajo con código revisado**
- **Fecha y estado:** 2026-11-08, 22:00. Aprobada [usuario]: «Amplío expresamente la autorización anterior. Autorizo
  subir código, configuraciones de agentes y documentación revisados a ramas de trabajo del repositorio privado
  Brunopina6/Aethelgard.»
- **Qué permite:** ramas por área y una rama experimental de integración, para respaldar y revisar el trabajo de los
  especialistas. Amplía [D-049](#d-049); la memoria sigue en `memoria-desarrollo`.
- **Qué no:**
  - cambios directos en `main` o `desarollo`;
  - force push;
  - pushes simultáneos a una misma rama o que pisen el trabajo de otro.
- **Quién:** publica y verifica el coordinador.
- **Antes de cada push:**
  - comprobar que el repositorio sigue privado;
  - revisar los archivos y sus diferencias;
  - dejar fuera secretos, credenciales, partidas, cachés, exportaciones privadas del chat y archivos ajenos;
  - comprobar los permisos de publicación de los recursos;
  - nada de bibliotecas completas, APK ni binarios grandes en el historial.
- **Lo que no pueda publicarse** se documenta con ruta local, procedencia y requisitos.
- **Git LFS:** solo si ya está disponible y bien configurado, o si su configuración queda autorizada.
- **Releases:** las APK siguen en `Aethelgard-pruebas`, por fecha y versión; una entrega nueva supera antes la
  integración, las pruebas y la revisión de recursos.
- **Primera publicación** (22:20): `integracion-experimental`, `area-sonido` y `area-animaciones`, con la revisión
  anotada en [T-088](TASKS.md#t-088).

### D-071
**Ambición: todas las ciudades mejoradas, muchos sitios nuevos y magias nuevas**
- **Fecha y estado:** 2026-11-08, 23:05. Aprobada [usuario]: «quiero que mejores todas ciudades del juego quiero un
  juego ambicioso, con muchos sitios para explorar, crea más magias … quiero que estes toda la noche mejorando el juego
  puliendo, mejorando el rendimiento y no me preguntes nada partir de ahora solo hazlo tú ya sabes cómo lo quiero».
- **Cuándo:** después del trabajo en curso (tanda 1) y de lo ya encargado (mapamundi, diálogo inicial, exploración y
  combate).
- **Ciudades** ([T-089](TASKS.md#t-089)): se mejoran todas las que existen (composición, vida, detalle y legibilidad en
  el móvil). Se conservan sus funciones (tiendas, posadas, NPC, misiones, entradas y salidas) y se mide el rendimiento.
- **Sitios para explorar** ([T-090](TASKS.md#t-090)): lugares nuevos coherentes con el canon (biblia v2) y con el
  mapamundi, cada uno con algo que hacer. Lo que toque la historia va como propuesta.
- **Magias nuevas** ([T-091](TASKS.md#t-091)): se añaden sin cambiar las existentes ([D-048](#d-048)), en
  incrementos pequeños y compatibles con partidas antiguas. Cada una tiene una función táctica clara, acceso desde el
  juego, pruebas, y un nombre y un efecto coherentes con el mundo. Sustituye a «las ampliaciones son plan futuro».
- **Calidad y rendimiento:** medir antes y después; el perfil alto no se rebaja.
- **Sin preguntas:** las decisiones rutinarias de diseño las toman el coordinador y los especialistas, y se registran.

### D-072
**Más contenido: equipo, enemigos, compañeros, secretos, grutas y posadas**
- **Fecha y estado:** 2026-11-08, 23:35. Aprobada [usuario]: «AÑADE TAMBIEN ACESORIOS CREA ARMA ESPECIALES ENEMIGOS ,
  AMIGOS DE VIAJE CREA CIUDADES CON MUCHOS SECRETO GRTUTAS,POSADAS ,CRE DIREFERENTES MAGIAS INSPIRATE EN EXPEDITION 33
  Y FINAL FANTASY Y OTROS JUEGOS RPG ,TE DEJO AL CARGO DE TODO».
- **Inspiración:** solo principios. Por ejemplo: un ritmo táctico con respuesta del jugador, sinergias entre
  personajes, riesgo y recompensa, y secretos que premian explorar. Nada de copiar nombres, diseños, escenas ni
  argumentos (norma vigente de CLAUDE.md), y ningún detalle de Final Fantasy X.
- **Equipo** ([T-092](TASKS.md#t-092)): accesorios y armas especiales.
  - Sus efectos se suman como modificadores nuevos y documentados. Las fórmulas base y las 12 magias protegidas no
    cambian ([D-048](#d-048)): sin equipo, los resultados son los de hoy.
  - Partidas antiguas compatibles.
- **Enemigos** ([T-093](TASKS.md#t-093)): con patrón y debilidad legibles, coherentes con su lugar.
- **Compañeros de viaje** ([T-094](TASKS.md#t-094)): un compañero nuevo en el grupo es una decisión importante de
  historia. Por eso:
  - va como propuesta, y el grupo jugable no cambia sin el usuario;
  - mientras, solo acompañantes que no toquen el canon.
- **Ciudades, secretos, grutas y posadas:** dentro de [T-089](TASKS.md#t-089) y [T-090](TASKS.md#t-090). Cada ciudad
  con identidad propia y su posada, con secretos (pasadizos, cofres escondidos, pequeñas misiones y lore) y grutas
  como lugares nuevos al final de `LUGARES`. Se empieza por el canon [C] de la biblia v2: Taberna del Cuervo Oxidado,
  crematorio, Árbol Milenario y Templo del Cristal del Cielo. Inventario en
  `docs/memory/inventario_lugares_magias_2026-11-08.md`.
- **Al cargo de todo:** el coordinador ordena estas tareas por dependencias, después de lo ya encargado, y deja
  registradas las decisiones importantes para que el usuario las revise.

### D-073
**Decisiones de la noche del 08 al 09/11, para revisar**
- **Estado:** aprobadas en el encargo. El usuario duerme y pidió no preguntar. Todas se pueden deshacer; esta lista
  crece durante la noche.
- **Ejecutor de pruebas** (`d2df536`): solo se niega a empezar si hay un Godot sobre su misma copia; los de otras
  copias se avisan y se vigilan. Así pueden probar varios especialistas a la vez. Amplía [D-010](#d-010).
- **Kael en los diálogos** (`e84cf32`): los retratos «normal» y «vivo» pasan a la pose de reposo (renders del modelo);
  `kael.png` se conserva. La mano junto a la cabeza era la pose del sable sin el sable.
- **Botón «Probar el prólogo (partida nueva)»** (`713fe8d`): solo en la versión experimental y en la ranura de prueba.
- **Efectos de sonido:** los eligió el especialista sin oírlos; el usuario los confirma o los cambia con las muestras.
- **Cofre de Pastos Verdes:** suena con efectos de la biblioteca; el sonido hecho por código se queda para comparar.
- **Script de compilación** (`c74b872`): como el ejecutor, solo se niega si hay un Godot sobre su proyecto.
- **Prueba v77 publicada sin pasar por el Redmi**, que no estaba conectado. Lleva `musica_combate_normal.mp3` (origen
  sin registrar, en el repositorio desde el primer commit), igual que la v57 y anteriores; no lleva Suno.
- **Pies que patinan en 3D:** a la velocidad de exploración se usará el clip de correr, que encaja con 4,2 m/s, y el
  de andar solo a poca velocidad. La velocidad de juego no cambia. Lo implementa animaciones en su tanda 2.
- **Sonido, tanda 2:** el segundo tajo del doble ataque suena 6 dB más bajo. El sonido de las 12 magias
  protegidas queda como propuesta, con muestras: decide el usuario.
- **Mapamundi pintado** (`a04a9d2`): pasa a ser el mapa por defecto. El clásico se elige en Ajustes (solo en la
  versión experimental) o con `-- mapa_clasico`. La máscara jugable se ajustó 2 px al dibujo.
- **Carpeta temporal de los especialistas:** cada uno usa una subcarpeta con su nombre, porque el 09/11 un script de
  gráficos pisó otro de animaciones con el mismo nombre (`f123920`).
- **Animaciones, tanda 2** (`4414ebf`):
  - el stick del mando es analógico en 3D, como en el mapa y en las zonas 2D;
  - en PV-03, Lya aparece a 4,5 m y llega corriendo (el usuario puede pedir que aparezca más lejos);
  - Lya y Garon entran en el grupo de la partida al ponerse el hito, para que la partida no los guarde separados.
- **Prueba v109** (`4414ebf`): pies sin patinar, stick analógico, Lya y Garon presentes y poses de Lya. Publicada en
  `Aethelgard-pruebas` y comprobada; no copiada al Redmi, que no estaba conectado.
- **Regla técnica (narrativa, 09/11):** nunca se guarda un recurso (Resource) en los metadatos de `Engine`, porque Godot
  se cae al cerrar (0xC0000005). Se guarda su ruta.
- **Oakhaven:** el arte se entrega en un módulo aparte (`crear_pieza`). Así narrativa y gráficos trabajan en paralelo
  sin tocar los mismos archivos.
- **Partidas antiguas (13:00):** una partida guardada en la Oakhaven generada abre la ciudad hecha a mano, por su entrada.
  Una de la Garganta 2D abre la 3D si está elegida. `prueba_guardado_protegido` acepta la ciudad nueva para una
  partida en Oakhaven.
- **`project.godot`:** se confirma el registro de Dialogic de los personajes y diálogos de Oakhaven, que la importación
  añade sola.
- **Combate fase 2 (`808a836`):**
  - Compás del Alba desde el nivel 3, Peso del Ocaso desde el 9, Lumbre de Retorno desde el 4 y Segundo Aliento desde
    el 10;
  - libros a la venta (350 y 450);
  - dos accesorios a la venta (Farol de peregrino, 220; Moneda del Águila, 450).
  - Todo se puede cambiar si el usuario lo prefiere de otra forma.
- **Combate: lo adoptado del diseño** (`docs/diseno/combate_ampliaciones.md`, rama `area-combate`):
  - pestañas por familia en el menú de magia;
  - la ranura se llama «Accesorio»; nada de «Quiebrasello»;
  - las magias nuevas se aprenden por nivel y con libros;
  - las familias nuevas no hacen daño y no pasan por el código de las 12 protegidas.
- **Narrativa: lo adoptado del diseño** (`docs/diseno/ciudades_y_lugares.md`, rama `area-narrativa`):
  - los lugares nuevos, desde el 11 (Pastos Verdes sigue siendo el 10);
  - el mapa colorea sus regiones solo con los 10 lugares originales;
  - las notas nuevas del Diario, en una lista aparte guardada en `lore_visto`;
  - los cofres hechos a mano, con identificador escrito;
  - el texto de T-086: 6 cambios de lectura en el móvil sin tocar hechos (entre ellos, partir dos globos del
    prólogo).
- **Pendiente del usuario** (no se implementa hasta que decida):
  - **Combate:**
    - que las debilidades de los enemigos nuevos multipliquen también el daño de las 12 magias protegidas;
    - P1, «Guardia a tiempo» (pulsar justo antes de un golpe quita un 40 %), y si va activada por defecto;
    - P2, la familia ofensiva «Eclipse»;
    - aspectos provisionales para los enemigos, o esperar al arte de Meshy;
    - si las Fauces de Gorthor se ganan se le perdone o no.
  - **Historia:**
    - Olvido, la tabernera que crió a Kael, como posadera de Oakhaven;
    - la Cripta de las Urnas bajo el crematorio;
    - Aldea Rocío y la misión «El nombre borroso»;
    - compañeros: Brea, piloto de la Astraea; Nyx, cuarto héroe en el acto III; Nerea, acompañante;
    - Pip y Lucero como acompañantes ligeros;
    - precios por posada o 30 monedas en todas;
    - la abuela de Lumi;
    - los centinelas que se apartan ante Kael;
    - «El Costillar» como apodo de Sunken City.

### D-074
**La Garganta del Diablo pasa a 3D, como mazmorra**
- **Fecha y estado:** 2026-11-09. Aprobada [usuario]: «Garganta del diablo hay que empezar a crearla en 3d como en
  pastos verdes solo que garganta del diablo es una mazmorra».
- **Qué cambia:** el plan 3D (`docs/plan_migracion_3d.md`) dejaba `garganta.gd` en 2D, sin cambios 3D, hasta después
  de la alfa. Ahora se crea su versión 3D con el patrón de Pastos Verdes ([T-095](TASKS.md#t-095)).
- **Cómo** (decidido por el coordinador):
  - se conservan la estructura y el progreso de la 2D;
  - entra por `modo3d.gd` (`REGIONES`), sin tocar `mapa.gd`;
  - mientras sea una maqueta, solo con el argumento `-- garganta3d`; la 2D sigue en las APK hasta que la 3D supere
    las pruebas.

### D-075
**Recursos que aporta el usuario el 09/11**
- **Fecha y estado:** 2026-11-09, hacia las 12:00. Aprobada [usuario], con los encargos T-096 a T-101.
- **El bestiario** (`REBELUM_Bestiario_01_con_visor.zip`):
  - contenido: seis GLB con texturas 2K de Meshy, esqueletos y animaciones hechos en Blender 5.2.3, sus `.blend`, un
    visor y un MP4;
  - procedencia: arte conceptual hecho para REBELUM; los ids de las tareas de Meshy están en
    `Fichas_e_integracion.txt`;
  - licencia: como los demás modelos de Meshy, el plan de la cuenta está **sin confirmar**. Pueden ir en las APK de
    prueba privadas (D-054), no en una entregable.
  - **en el repositorio,** solo los GLB que use el juego, de 6 a 9 MB cada uno. Los `.blend` se quedan fuera del
    historial, en `D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\`, documentados.
  - **el lore y el botín** de las fichas son propuestas que hay que validar con el canon.
- **El paquete de dos espadas** (`Patreon_Drop38_DUAL-BLADE_COMBAT_ESSENTIALS_FIXED.zip`):
  - contenido: cinco animaciones FBX y una espada corta;
  - licencia: «Permitted: commercial games…; Prohibited: resale, redistribution, or sharing of the raw asset files»;
  - uso: solo si hace falta, dentro del juego; los FBX originales no se suben a GitHub.
- **El logotipo de REBELUM:** es una imagen del usuario para la pantalla de carga y el icono
  ([T-098](TASKS.md#t-098)), y pasa a ser el icono y el título.
- **La ilustración de paisaje** («Aventura entre Cascadas y Ruinas»): es la **referencia de detalle y composición**
  para las ciudades y la Garganta en 3D ([D-076](#d-076)), no un fondo.

### D-076
**Todas las ciudades, pueblos y posadas en 3D jugable; la Garganta, pulida como mazmorra**
- **Fecha y estado:** 2026-11-09, hacia las 12:35. Aprobada [usuario]: «Quiero que todas las ciudades, pueblos y
  posadas de REBELUM sean escenarios 3D jugables, con el mismo nivel de acabado que Pastos Verdes».
- **Qué cambia:**
  - el objetivo de cada ciudad es el 3D jugable ([T-103](TASKS.md#t-103));
  - el plan 3D (región a región) se amplía a todos los asentamientos;
  - la Oakhaven 2D (T-089, fases 1 y 2) se conserva como referencia funcional, y sus datos (`ciudades/oakhaven.gd`:
    trazado, vecinos, misiones, cofres, secretos y notas) son la base del 3D.
- **La Garganta 3D** se pule por tramos, empezando por la entrada, la primera cornisa y el primer puente
  ([T-102](TASKS.md#t-102)).
- **La referencia de calidad es Pastos Verdes:** su cámara elevada en ¾, el seguimiento del grupo, la profundidad, los
  materiales y la luz. La de detalle y composición, la ilustración «Aventura entre Cascadas y Ruinas».
- **Perfiles:** el Redmi ajusta sombras, niebla, transparencias y detalle lejano; el perfil alto no se rebaja.
- **Orden:** terminar lo que está en marcha; después, primero el tramo pulido de la Garganta y luego el primer
  recorrido 3D de Oakhaven con su posada, cada uno con su APK y su ruta.

### D-077
**Sesión «calidad AAA, sin Redmi» y decisiones del coordinador (09/11, de 17:30 a 22:50)**
- **Encargo** [usuario]: «quiero que utilices los programas necesarios de mi pc para mejorar mapas animaciones
  personajes, necesito que los personajes tengan personalidad … convirtiéndolo en un juego AAA … NO PARES», con la
  instrucción de **no usar el Redmi** (fuera de casa): nada de instalar, desplegar ni pedir pruebas manuales; lo que
  dependa del teléfono se anota como pendiente (`docs/pruebas_redmi_pendientes.md`) y se sigue con otra mejora.
  No se afirma ningún rendimiento Android sin medirlo.
- **Decisiones del coordinador** (reversibles; el usuario lo delegó todo, D-073):
  - Zarzalín a ×1,25 en combate; su botín, «Corteza espinosa», se vende por 18 monedas, sin recetas.
  - Los comentarios de los héroes al explorar son por sesión (no se guardan en la partida).
  - Las charlas de posada vistas se guardan como estado de Oakhaven dentro de «mazmorras» (clave que ya existía).
  - Comer en la posada: sopa del día, 10 monedas, recupera PV y no PM; la posadera pregunta «¿Algo más?».
  - La Cura (magia protegida, D-048) no pide voz de alivio por ahora.
  - C2: la primera victoria contra Gorthor da las Fauces de Gorthor (estaba en la lista de D-073); la huella de
    combate cambia solo en esa línea de E8 y se regeneró con su justificación (`ebae3ed`, rama `area-combate`).
  - La app de pruebas se llama «REBELUM Exp» (mismo paquete `com.aethelgard.experimental`: se actualiza encima).
  - El icono del proyecto pasa a ser el de REBELUM; la app estable no se compila ni se instala.
  - En la mano de Kael no hay ninguna marca: los gestos usan el brazalete, sin revelar nada.
- **Herramientas:** el lanzador de pruebas vigila la carpeta real que da Windows aunque APPDATA venga desviada
  (`eef300c`); prueba nueva de integridad (`cd2a405`).
- **Publicado:** Prueba v293 en `Aethelgard-pruebas` (`exp-20261109-dca4c1c`, SHA-256 `3dbe855e…`), sin copiarla al
  Redmi.

### D-079
**Integración de los especialistas y criterios de la fase 2 (10/11, tarde)**
- **Integración** [usuario: «integralas»]:
  - ramas de sonido, narrativa, Oakhaven 3D y rendimiento en `integracion-experimental`;
  - batería 82/0 y subida normal (`0d06bd1`), según D-070.
  - El perfil medio pasa al candidato B (medido en el Redmi el 09/11); el alto no cambia.
- **Fase 2** [usuario: orden «FASE 2: optimización profesional», sin Redmi]. **Decisiones del coordinador:**
  - **Precarga:** se quita lo que no usa nadie, comprobado con las dependencias de cada modelo. La carga diferida de
    lo del combate no se hace sin medirla en el Redmi, por el riesgo de tirones.
  - **3D:** sin cambios visuales ni de perfiles sin el teléfono («calidad visual primero»).
  - **Datos:** una sola fuente de verdad por tipo. Las claves de inventario no cambian (compatibilidad de partidas).
  - **Talleres:** solo la base técnica, con datos de ejemplo en las pruebas. Las recetas e investigaciones reales y la
    pantalla, en la fase 3 con aprobación.
  - La rama de la fase 2 queda local: no se fusiona ni se sube sin autorización.

### D-078
**Fusión de la auditoría autónoma en `integracion-experimental` (10/11)**
- **Orden** [usuario]: «AUTORIZADO: fusiona las mejoras verificadas y súbelas a GitHub», con respaldo previo y la
  batería completa después. Sin tocar `main`, `desarollo` ni otras ramas, sin force push y sin APK nueva.
- **Hecho:**
  - respaldo local: rama y etiqueta en `2889213`;
  - fusión `--no-ff` sin conflictos (`218155a`);
  - batería 79/0;
  - push normal `dca4c1c..59c3a67`.
- **También se subieron** los commits de los especialistas que el coordinador ya había integrado y revisado en local
  (`dca4c1c..2889213`).
- **Revisado antes de subir:**
  - sin APK, partidas, claves ni música de Suno;
  - los binarios más grandes (Cencerrante, 7 MB; ambientes de plaza, 2,9 MB) son menores que otros que ya estaban en
    la rama.
- **La app «REBELUM Auditoría»** (`com.aethelgard.auditoria`) queda como forma de validar una rama en el Redmi sin
  tocar las apps instaladas.

## 6. Diseño ya implementado del 30/10 al 05/11

[historial] Son decisiones del usuario que ya están en el juego. Están anotadas para que no se pierda su origen.
Todo esto entró en Git con el primer commit, `fd71d6a` (05/11, 11:28), así que Git no guarda su historia.

| ID | Fecha | Decisión | Dónde está |
|---|---|---|---|
| D-H01 | 31/10-02/11 | Combate 2D con personajes 3D, cada uno en su SubViewport, y fondos por zona | `combate.gd` |
| D-H02 | 02/11 | Niveles; 6 atributos (3 puntos por nivel, nivel máximo 50); equipo por ranuras. Los espadachines solo llevan espadas y las magas solo cetros. El arma no se ve en el mapa | `grupo.gd`, `inventario.gd` |
| D-H03 | 02/11-03/11 | Magias en niveles I, II y III; las de nivel II y III golpean a todos los enemigos. Menú de magia con pestañas por nivel | `combate.gd` (`MAGIAS`), `menu_combate.gd` |
| D-H04 | 02/11 | Efectos de fuego, agua, rayo y cura hechos con los GLB del usuario (el fogonazo, con menos blanco) | `vfx/` |
| D-H05 | 03/11 | Modo móvil: menos partículas, sin luces 2D y como mucho 2 SubViewports de efectos; D-pad | `combate.gd`, `dpad.gd` |
| D-H06 | 03/11 | Dialogic 2 para los diálogos, con botón «Seguir» en el móvil | `boton_dialogo.gd`, `dialogos/` |
| D-H07 | 03/11 | Equilibrio: la magia de Lya vale ×3 la de Kael y el ataque físico de Kael ×5 el de Lya. IA por personalidades | `grupo.gd`, `combate.gd` |
| D-H08 | 03/11 | Monedas, tienda (objetos, equipo y libros de magia) y posada (30 monedas) | `inventario.gd`, `tienda.gd`, `zona.gd` |
| D-H09 | 03/11 | Zonas grandes (80×56) con río, puentes, ruinas y cofres. Texturas de Poly Haven y decorado de Quaternius (CC0) | `zona.gd`, `texturas/`, `decorado/` |
| D-H10 | 03/11 | Pantalla de carga con precarga; 30 FPS fuera del combate y 60 en combate | `recursos.gd`, `carga.gd` |
| D-H11 | 03/11 | Documento de diseño: ritmo sin farmeo, autoguardado, lore ambiental y diario | `progreso.gd`, `diario.gd` |
| D-H12 | 04/11 | Garganta del Diablo jugable (8 pantallas y el nido). Gorthor, jefe con fases y la decisión de perdonar o acabar | `garganta.gd`, `combate.gd` |
| D-H13 | 04/11 | Portal del Vacío y ciudad flotante (Arboleda Mítica) como fondo pintado por el que se camina | `isla.gd`, `mapa.gd` |
| D-H14 | 04/11-05/11 | Grimfang en lugar de Hollín; Garon como tercer héroe, con espada doble | `goblin_3d.gd`, `garon_3d.gd` |
| D-H15 | 05/11 | El proyecto entra en Git y GitHub. La etiqueta v0.1.0 (pre-release con la APK) apunta al primer commit | `fd71d6a` |
