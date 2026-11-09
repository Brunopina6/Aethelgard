# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-09 a la 01:15 (hora local, UTC+1). Noche de trabajo autónomo: el usuario duerme y
pidió no preguntar ([MEMORIA_CHAT.md](MEMORIA_CHAT.md)). **La memoria describe `integracion-experimental` @ `c74b872`, que está en GitHub.**

- **Encargos vigentes, de más antiguo a más nuevo** (todos en [MEMORIA_CHAT.md](MEMORIA_CHAT.md)):
  1. Organización por especialistas ([D-069](DECISIONS.md#d-069)) y GitHub por ramas de trabajo
     ([D-070](DECISIONS.md#d-070)).
  2. Sesión larga y autónoma, con prioridades 1-7 (22:40). El usuario: «acepto todo… no me preguntes más».
  3. Ciudades, sitios nuevos y magias nuevas ([D-071](DECISIONS.md#d-071)).
  4. Equipo, enemigos, compañeros, secretos, grutas y posadas ([D-072](DECISIONS.md#d-072)). Puede usar cualquier
     programa del PC y debe centrarse mucho en lo visual y el lore.
- **Decisiones de la noche, para que el usuario las revise:** [D-073](DECISIONS.md#d-073).

## Reanudado el 09/11 (después del límite de uso)

- **Nueva petición:** la Garganta del Diablo en 3D, como mazmorra ([T-095](TASKS.md#t-095),
  [D-074](DECISIONS.md#d-074)). Especialista de gráficos en `D:\Aethelgard_garganta3d`, rama `area-garganta3d`
  (desde `c74b872`): diseño y maqueta jugable, activable con `-- garganta3d`.
- **Mapamundi pintado: integrado** (`a04a9d2`) con el selector en Ajustes (`14aea04`). Batería: 40 superadas, 0
  fallidas. Falta medirlo. La memoria describe `integracion-experimental` @ `14aea04`.
- **09/11 ~19:20, punto de control por el límite de uso (sesión «calidad AAA, sin Redmi»).** Subido y comprobado:
  `integracion-experimental` @ `955345a` (batería 64/0, `D:\REBELUM_diagnostico\pruebas\2026-11-09_184606\`) y todas
  las ramas de área. Local sin subir: `f2e9c9f` (une la Garganta completa y Oakhaven viva, ramas ya subidas); su
  batería quedó en marcha (`D:\REBELUM_diagnostico\pruebas\bateria_f2e9c9f.log`), **pendiente de verificar**.
  - **Integrado hoy:** HUD de PM (T-099), Zarzalín jugable con sonidos y botín (T-097), Escarcha y Guardia de Garon
    (T-100), esperas con personalidad y gestos de diálogo, charlas de posada, vecinos vivos, posada como servicios,
    comentarios de los héroes (2D, Pastos Verdes 3D y Garganta 3D), Garganta 3D pulida entera (T-102), voces de
    esfuerzo, logotipo e icono REBELUM (T-098), prueba de integridad y el lanzador de pruebas más seguro.
  - **Detenidos por el límite, con trabajo sin confirmar en sus copias:** combate (M4 y C2, voces t5), sonido
    (tanda 6: Oakhaven y mezcla), gráficos (optimizar la Garganta; luego T-103 en rama nueva `area-oakhaven3d`),
    narrativa (pregunta de la posadera y notas de lore) y animaciones (T-101, la invocación nueva de Érebo).
  - **Siguiente:** comprobar la batería de `f2e9c9f` y subirla; retomar los cinco encargos; compilar la APK de prueba
    (nada se ha compilado hoy) y anotar en `docs/pruebas_redmi_pendientes.md` lo que falte en el teléfono.
- **09/11 ~17:50, sesión autónoma «calidad AAA, sin Redmi».** El usuario está fuera: **no se usa el Redmi** (ni ADB
  ni copias); lo que lo necesite va a `docs/pruebas_redmi_pendientes.md` (en la integración). Subido
  `integracion-experimental` @ `eef300c`, comprobado con `git ls-remote`; después, `cd2a405` (local):
  - **T-098 hecha en el PC** (`96b2a37`): logotipo REBELUM en la pantalla de carga e icono nuevo; app «REBELUM Exp».
  - Pruebas de mando y teclado arregladas (`9f94601`): esperaban el diálogo de Tilo al instante.
  - El lanzador de pruebas vigila la carpeta real que da Windows aunque APPDATA venga desviada (`eef300c`).
  - Prueba nueva `prueba_integridad` (`cd2a405`): 63 scripts, 17 escenas y 1 recurso cargan; sin fallos.
  - **Batería** sobre `ad5d416`: 57 superadas, 0 fallidas (`D:\REBELUM_diagnostico\pruebas\2026-11-09_173627\`).
  - **Trabajan:** combate (HUD de PM, luego Zarzalín en combate), sonido (tanda 4 y respiraciones de los héroes),
    gráficos (T-102, Garganta 3D: entrada, cornisa y puente), animaciones (esperas con personalidad, gestos de
    diálogo, luego T-101) y narrativa (arte de Oakhaven enganchado, guía de voz de los héroes, comentarios al explorar).
- **09/11, punto de control por el límite de uso.** Subido y comprobado con `git ls-remote`:
  `integracion-experimental` @ `eb8bd94`, `area-narrativa` @ `01eca69`, `area-sonido` @ `778ea75`,
  `area-animaciones` @ `f6dc571` y `area-graficos` @ `9cc0cbd` (revisión previa sin alertas: nada grande, prohibido
  ni secreto).
  - **Integrado:** arte de Oakhaven (T-089), Zarzalín preparado para el combate (T-097), tanda 3 de sonido, texto de
    T-086 y el orden de PV-03.
  - **Corregido:** la unión `68aa383` dejó marcas de conflicto en `docs/recursos.md` y `prueba_combate_huella`
    duplicada; arreglado en `a9b4b07`. Licencias pendientes de Zarzalín y de los muñecos de Oakhaven en `eb8bd94`.
  - **Pendiente de verificar:** la batería completa sobre `eb8bd94`.
  - **Detenidos por el límite de uso**, con su trabajo sin confirmar en sus copias: combate (HUD: barra de PM, motivos,
    Érebo visible; `D:\Aethelgard_combate`) y sonido tanda 4 (las seis bestias; `D:\Aethelgard_sonido`). Se reanudan
    leyendo su copia y su informe.
  - **Siguiente:** batería aislada; memoria completa (TASKS, DECISIONS, MEMORIA_CHAT); reanudar combate y sonido;
    después T-102 (Garganta), T-103 (Oakhaven 3D), T-101 (Érebo) y la APK de ruta corta.
- **09/11, 13:10, integrado y subido** (`integracion-experimental` @ `808a836`, batería con 51 superadas y 0
  fallidas):
  - Oakhaven 2D jugable, hecha a mano;
  - las partidas antiguas, redirigidas;
  - combate fase 2: Alba y Lumbre jugables, ranura Accesorio y la huella con C0;
  - las fichas de las artes en el Diario.

  **Trabajan:** combate (HUD: barra de PM, motivos, Érebo visible y señas de las artes), narrativa (texto de T-086),
  gráficos (arte de Oakhaven), sonido (tanda 3) y animaciones (Zarzalín). La memoria describe `808a836`.
- **Objetivo vigente para todas las ciudades, pueblos y posadas: 3D jugable al nivel de Pastos Verdes**
  ([D-076](DECISIONS.md#d-076), [T-103](TASKS.md#t-103)). Primero, el tramo pulido de la Garganta
  ([T-102](TASKS.md#t-102)); después, el primer recorrido 3D de Oakhaven con su posada. Va cuando termine lo que está
  en marcha.
- **09/11, 12:05, encargos nuevos** (T-096 a T-101; recursos en [D-075](DECISIONS.md#d-075)). Van después de integrar lo que está en
  marcha, en este orden:
  1. las skills de Godot y Blender Animation;
  2. el bestiario, con Zarzalín primero;
  3. REBELUM en la carga y el icono;
  4. la barra de PM;
  5. las artes jugables y la guardia de Garon;
  6. la cinemática de Érebo.

  El Redmi está conectado por ADB.
- **09/11, 11:50:**
  - integradas la Garganta 3D (`ea067b1`, elegible en Ajustes con `cff2323`) y la fase 1 de combate (`555fc29`, en
    GitHub). Batería de `555fc29`: 47 superadas, 0 fallidas (`D:REBELUM_diagnosticopruebas�6-11-09_084703`);
  - un límite de uso cortó a cuatro especialistas: combate fase 2, sonido tanda 3, narrativa fase 2 y el arte de
    Oakhaven. Su trabajo quedó sin confirmar en sus copias. A las 11:50 se reanudan con su contexto: primero combate y
    narrativa; sonido y gráficos, después de compilar la APK con la Garganta 3D elegible.
  - La memoria describe `integracion-experimental` @ `555fc29`.
- **Oakhaven:** la fase 1 (datos y diálogos, en archivos nuevos) está integrada en `ab250c9`, que ya está en GitHub.
  La fase 2 va en marcha desde las 09:00: narrativa la engancha en `D:\Aethelgard_narrativa` y gráficos hace el arte
  en `D:\Aethelgard_graficos`. **Especialistas activos:** Garganta 3D, combate (fase 1), narrativa y gráficos.
- **Animaciones, tanda 2: integrada** (`4414ebf`): pies sin patinar, presencia en PV-03 y PV-05, retratos vivos y
  poses de Lya. Batería: 41 superadas, 0 fallidas. La memoria describe `integracion-experimental` @ `4414ebf`.
- **Reanudados con su contexto:** el mapamundi (fase 2), animaciones (tanda 2), combate (fase 1) y narrativa (fase 1).
- **Sonido, tanda 2: terminada e integrada** (`c74ee66`; subida con `integracion-experimental` @ `4c6fafc`): voces de
  enemigos, el río 2D, la puerta de la Garganta y el Diario. Batería: 39 superadas, 0 fallidas. La memoria describe
  `integracion-experimental` @ `4c6fafc`.
- Dejaron muy poco a medias: dos archivos sin confirmar en total.

## Relevo por límite de uso (09/11, hacia la 01:15)

- Se alcanzó el límite de uso de la sesión. Se pararon los cinco especialistas en marcha. Lo que hicieran quedó en
  sus copias, **sin revisar ni integrar**: puede haber cambios sin confirmar. Hay que revisar `git status` y `git log` en
  cada una antes de seguir:
  - animaciones, tanda 2 (`D:Aethelgard_animaciones`): estaba empezando la medida del deslizamiento de los pies;
  - sonido, tanda 2 (`D:Aethelgard_sonido`): voces de enemigos, ríos 2D, Garganta y propuesta de sonido de magias;
  - combate, fase 1 (`D:Aethelgard_combate`, desde `2cb8221`): red de seguridad (huella) y datos de magias y equipo;
  - narrativa, fase 1 (`D:Aethelgard_narrativa`, desde `1977bff`): Oakhaven en archivos nuevos;
  - gráficos, fase 2 (`D:Aethelgard_graficos`, desde `e11a882`): integrar el mapamundi pintado. La fase 1 está
    revisada y aprobada (comparaciones en `D:REBELUM_diagnosticomapamundi�6-11-08mparacion`).
- Lo publicado y comprobado sigue igual: `integracion-experimental` @ `c74b872` y la Prueba v77.
- **Para retomar:** revisar cada copia y relanzar cada especialista con su tarea (los encargos están en este relevo, en
  TASKS.md y en el informe de cada uno, en `docs/memory/agents/`).

## Hecho y comprobado esta noche

| Qué | Commit | Comprobación |
|---|---|---|
| Sonido, tanda 1 ([T-083](TASKS.md#t-083)): 100 efectos de la biblioteca (CC0 y Sonniss 2016-2024, licencias comprobadas), API con voces, prioridades y variantes, enganches en eventos reales | `091bcfb` (rama `area-sonido`) | Batería de la integración: 39 superadas, 0 fallidas. **Sin escuchar:** muestras en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-08\` |
| Animaciones, tanda 1 ([T-084](TASKS.md#t-084)): la mano de Kael venía de la ilustración (render del reposo con sable, sin sable). Cinco retratos nuevos desde el modelo; Kael escucha en reposo; en 3D quien escucha mira a quien habla | `e84cf32` (rama `area-animaciones`) | Batería del especialista: 37 superadas, 0 fallidas. Antes y después y vídeos en `D:\REBELUM_diagnostico\animaciones\2026-11-08\` |
| El ejecutor solo se niega si hay un Godot en su misma copia (los demás, aviso y vigilancia) | `d2df536` | Batería con 8 Godot ajenos abiertos: limpia |
| Botón «Probar el prólogo (partida nueva)» en la carga ([T-081](TASKS.md#t-081)) | `713fe8d` | `prueba_boton_prologo` (nueva) y regresiones de mando, teclado, foco, prólogo, ranura y precalentado: superadas |
| `prueba_efectos` estable (comparaba con −6 dB fijos) | `713fe8d` | 5 de 5 pasadas |
| Batería completa de todo lo integrado | `713fe8d` | 39 superadas, 0 fallidas, 0 no seguras; partida real, carpeta real y proyecto sin cambios (`D:\REBELUM_diagnostico\pruebas\2026-11-09_000605\`) |
| Push revisado: `integracion-experimental`, `area-sonido` y `area-animaciones` | `713fe8d` | `git ls-remote`; repositorio privado, un solo usuario |
| Script de compilación: solo se niega si hay un Godot sobre su proyecto | `c74b872` | Compilación de la v77 con otros Godot abiertos: «TODO CORRECTO» |
| **Prueba v77** (versionCode 77, `com.aethelgard.experimental`, 254,1 MB, SHA-256 `ffffeb69…`) | `c74b872` | Firma verificada; sin partidas, claves ni Suno; release «09/11/2026 · Prueba v77» (Latest) con el resumen SHA-256 igual al local. **No copiada al Redmi: no estaba conectado** |

## Dónde está todo

| Qué | Valor |
|---|---|
| Integración | `D:\Aethelgard_alpha`, rama `integracion-experimental` @ `c74b872`, en GitHub |
| Especialistas | Copias `D:\Aethelgard_<área>`, ramas `area-<área>`: sonido (terminada, integrada), animaciones (terminada, integrada), gráficos (fase 1 del mapamundi, en marcha desde las 23:12), combate y narrativa (fase 0, solo diseño, en marcha desde las 23:45). Todas son ya carpetas de trabajo de la sesión |
| Configuración de los especialistas | `.claude/agents/especialista-*.md`. Esta sesión no los reconoce por nombre: se lanzan como `general-purpose` que leen su archivo |
| Copia del usuario | `D:\Aethelgard`, rama `rebelum-3d` @ `b8e042d` con el bloque B sin tocar. Su editor se cerró antes de las 23:10 |
| Memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo` |
| Respaldo | `D:\REBELUM_respaldos\2026-11-08_rebelum-alpha_375cc8c\rebelum-alpha.bundle`; los `.uid` generados que se apartaron al integrar, en `D:\REBELUM_respaldos\2026-11-09_uid_generados_integracion\` |
| Redmi | No conectado a las 23:20. La copia de las APK de la noche queda para mañana; las APK irán a `Aethelgard-pruebas` |
| Programas | `docs/herramientas/programas_pc.md`. Cascadeur pide la sesión del usuario; las herramientas de Arm en el teléfono necesitan permiso |
| Inventario para ciudades, lugares y magias | `docs/memory/inventario_lugares_magias_2026-11-08.md` |
| Partida real | `A3F3C402…` (19:37 del 08/11), sin cambios en todas las pasadas |

## Próximo paso concreto (por dependencias)

1. **Hecho (00:35):** la batería, el push y la APK v77.
2. **Copiar la v77 al Redmi** cuando esté conectado, y comprobar tamaño y SHA-256.
3. **Gráficos, fase 2:** cuando entregue la fase 1, se integra `integracion-experimental` en `area-graficos` y pasan a
   gráficos `mapa.gd` y `mapa.tscn`.
4. **Animaciones, tanda 2** (en marcha desde las 00:25):
   - que los pies no patinen (Kael anda a 4,2 m/s con un clip pensado para 1,2-1,5 m/s);
   - Lya y Garon presentes cuando hablan en PV-03 y PV-05 (`pastos_verdes_3d.gd`, ya libre);
   - retratos vivos en Pastos Verdes, poses de Lya y la señal `pisada` para los pasos.
5. **Sonido, tanda 2:** voces de enemigos, agua en los ríos 2D, pasos de Lya, Garon y los enemigos, y la puerta de
   la Garganta. Las magias, como propuesta (están protegidas).
6. **Combate y narrativa:** revisar sus diseños e implementarlos por incrementos (magias, equipo, enemigos, ciudades,
   lugares y compañeros).

## Límites de lo comprobado

- **Escucha:** nada escuchado por una persona. Las pruebas miden la señal, no la calidad.
- **Redmi:** nada de esta noche probado en el teléfono. La v57 sigue sin probar por el usuario.
- **T-025:** ni mando ni teclado reales; el táctil, solo simulado.
- **Combates:** se ganan con ataques automáticos.
- **Rendimiento:** lo nuevo de esta noche (efectos, retratos y el botón) no está medido.

## Pendiente del usuario (mañana)

- **La Prueba v136 ya está en el Redmi:** `Download/Aethelgard_Exp_2026-11-09_v136.apk`, copiada por USB el 09/11 a las
  12:05 y comprobada (tamaño y SHA-256 iguales).
- **Instalar la Prueba v136** (la más reciente; incluye todo lo de las v109, v98 y v77): está en la release privada
  «09/11/2026 · Prueba v136» de `Aethelgard-pruebas` (versionCode 136, commit `555fc29`, SHA-256 `e1f1bc5d…`,
  comprobado). Novedad: la Garganta del Diablo 3D, que se elige en Ajustes. Qué probar, en sus notas. El Redmi no
  estaba conectado para copiarla a Descargas. Qué probar, en sus notas: el mapamundi pintado (y compararlo con «De
  siempre» en Ajustes), el prólogo con el botón nuevo, las voces de los enemigos y el táctil.
- **Escuchar las muestras** y elegir la victoria, los golpes, el cofre y el tesoro (el especialista duda de ellos).
- Revisar las decisiones de la noche ([D-073](DECISIONS.md#d-073)) y las propuestas de historia que dejen narrativa y
  combate.
- Sigue pendiente de decidir la nivelación al unirse ([D-062](DECISIONS.md#d-062)).

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Push:** memoria en `memoria-desarrollo`; APK de prueba en `Aethelgard-pruebas`; código revisado en ramas de
  trabajo de `Brunopina6/Aethelgard` ([D-070](DECISIONS.md#d-070)). Nunca en `main` ni en `desarollo`; nunca force
  push; nunca APK, bibliotecas completas, partidas, cachés, secretos ni la exportación del chat.
- **Redmi:** solo copiar APK de prueba a Descargas por USB y comprobarlas; instala el usuario.
- **Copia habitual:** solo la protección del guardado; el bloque B no se toca.
- **Licencias:** nada de Suno en APK ni en GitHub; Sonniss solo dentro del juego (no se revende ni sirve para entrenar
  IA).
- **Magias:** las 12 existentes no cambian ([D-048](DECISIONS.md#d-048)); las nuevas se añaden ([D-071](DECISIONS.md#d-071)).
- **Narrativa:** biblia v2 como canon; nada sobre Érebo y los corazones antes del acto III; un compañero nuevo en el
  grupo es una propuesta.
- **Pruebas:** el ejecutor se lanza desde PowerShell, no desde Bash, porque Bash expande el `*` de `*>` y le pasa
  parámetros falsos.
