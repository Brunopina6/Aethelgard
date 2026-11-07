# DECISIONS: decisiones de AETHELGARD / REBELUM

**Actualizado el 2026-11-07** sobre la copia del usuario (`rebelum-3d` @ `ce84422`) y el árbol del encargo
(`rebelum-alpha` @ `c2a524c`). Las horas son locales (UTC+1).

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
| [D-012](#d-012) | Versión experimental con paquete y partida propios | Aprobada (partida a medias) |
| [D-013](#d-013) | El Redmi queda reservado | Aprobada |
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
| [D-049](#d-049) | La memoria se publica en `memoria-desarrollo`, y solo la memoria | Aprobada |
| [D-050](#d-050) | Licencias: recursos autorizados o sustitutos; el entregable excluye lo no acreditado | Aprobada |
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

### D-012
**Versión experimental con paquete y partida propios**
- **Fecha y estado:** 2026-11-07. Aprobada [usuario]: paquetes y partidas separados. La partida propia está a medias,
  sin confirmar en `rebelum-alpha`.
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
  esto. Se retomó a las 16:30 (D-046) desde el trabajo a medias en `rebelum-alpha`.
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
