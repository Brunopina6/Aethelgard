# PROJECT_CONTEXT: arquitectura real de AETHELGARD / REBELUM

**Verificado el 2026-11-07** sobre `desarollo` @ `2d1adc4`. El código del juego es idéntico en `rebelum-3d` @ `ce84422`.
La rama `rebelum-alpha` @ `03b960a` añade la región 3D de Pastos Verdes (ver §5). El 08/11 se añadió el repositorio
privado de APK de prueba (§9). Las novedades de `rebelum-alpha` hasta `e630b02` (08/11, 19:00) están en §3 a §6 y
§10.

Cómo leer las etiquetas:
- **[código]**: observado en el código.
- **[ejecutado]**: comprobado ejecutando, siempre con datos aislados.
- **[historial]**: viene de la conversación o de documentos anteriores; hay que contrastarlo.
- **[alpha sin confirmar]**: cambio a medias en `D:\Aethelgard_alpha` (rama `rebelum-alpha`), sin probar.
- **[pendiente]**: sin verificar.

## 1. Repositorio y entorno

| Elemento | Valor |
|---|---|
| Raíz de Git | `D:\Aethelgard`. Proyecto de Godot en `D:\Aethelgard\aethelgard\` (`project.godot`) |
| Remoto | GitHub privado `Brunopina6/Aethelgard`. Ramas remotas: `main` (`d4b2d16`) y `desarollo` (`2d1adc4`). Etiqueta `v0.1.0` (`fd71d6a`) |
| Ramas locales | Ver la tabla de ramas, debajo |
| Árbol aparte | `D:\Aethelgard_alpha`: árbol de trabajo de `rebelum-alpha` |
| Godot | Declarado: `config/features = "4.7", "GL Compatibility"`. Instalado: `4.7.2.stable.official.ed1daf0bf` [ejecutado `--version`] |
| Render y física | `gl_compatibility` (también en móvil), Jolt Physics, importación ETC2/ASTC activa [código: `project.godot`] |
| Complementos | Dialogic (autoload por uid) y Posador (`addons/posador`: complemento de editor de IK y grabación de poses para Mixamo) [código] |

**Ramas locales**

| Rama | Commit | Qué es |
|---|---|---|
| `main` | `d4b2d16` | Estable |
| `desarollo` | `2d1adc4` | Desarrollo (se escribe así, con una sola r) |
| `rebelum-3d` | `ce84422` | Fase 2.0: herramientas; no tiene cambios de juego |
| `rebelum-alpha` | `c2a524c` | Encargo de implementación |
| `respaldo-d155a36` | `d155a36` | Respaldo: no se borra |

La etiqueta local `recuperacion-antes-fase2.0` apunta a `2d1adc4`.

**Herramientas del PC** [historial; parte ejecutada]:
- Godot de consola en `C:\Users\G513\Desktop\jueo personal\` [ejecutado].
- Android SDK (adb y build-tools 35.0.0 con aapt2 y apksigner) y JDK 17 de Adoptium [ejecutado].
- `gh` 2.103.3. Su token tiene permisos `repo` y `workflow`: cuidado.
- Blender 5.2.3.
- Arm Performance Studio: Streamline, Mali Offline Compiler, RenderDoc for Arm y Frame Advisor.
- Cascadeur Free.
- **No hay:** emulador de Android (ni imágenes del sistema), FFmpeg, Audacity ni SoX.

**Carpetas fuera del repositorio**
- `D:\REBELUM_diagnostico`: registros de pruebas y mediciones.
- `D:\REBELUM_compilaciones`: APK locales.
- `D:\REBELUM_respaldos`: respaldos con fecha.

## 2. Flujo del juego y navegación [código]

1. **`carga.tscn`** (`carga.gd`) es la escena principal (`project.godot:14`).
   - Precarga los recursos (`Recursos.listar()` según `EXTENSIONES` y `EXCLUIR`, en `recursos.gd:12-16`).
   - Precalienta los sombreados: Kael y Lya en 3D, `vfx/` y la hierba y el agua de las zonas.
   - Prepara la caché de texturas de las zonas.
   - «TOCA PARA EMPEZAR» → `Progreso.cargar()` → escena guardada o `mapa.tscn`.
2. Con la característica `prueba3d`, la escena principal es `prototipos/sendero_puente.tscn` (`project.godot:18`).
3. **`mapa.tscn`** (`mapa.gd`): el mapa del mundo, en 2D.
   - 10 lugares (`LUGARES`):
     - 0: Oakhaven (ciudad);
     - 1: Gran Bosque Verde;
     - 2: Garganta del Diablo (la mazmorra `garganta.tscn`);
     - 3: Cumbres de Ciclópea;
     - 4: Mar de Arena de Calid;
     - 5: Sunken City;
     - 6: Valle de los Ecos;
     - 7: Templo Sumergido de Atlantis;
     - 8: Abismo de Ceniza;
     - 9: Portal del Vacío (lleva a `isla.tscn`).
   - El prólogo de Dialogic sale la primera vez (`mapa.gd:103-105`).
   - Encuentros por pasos (`_paso`, `_encuentro`).
   - Menús: Grupo, Objetos y Habilidades (`menus.gd`) y el Diario (`diario.gd`).
4. **`zona.tscn`** (`zona.gd`): zona 2D generada a partir de `Engine.get_meta("lugar")`.
   - NPC con Dialogic (`npc_*.dtl`), tienda y posada.
   - Cofres (`cofres_abiertos`) y detalles de lore (`Progreso.DETALLES`).
   - Encuentros (paso de 20 px, 40 pasos seguros, probabilidad 0,012) y salida al mapa.
5. **`garganta.tscn`**: mazmorra hecha a mano, con combates fijos y palancas (`Progreso.estado`).
6. **`isla.tscn`**: la Arboleda Mítica, la ciudad flotante.
7. **`combate.tscn`** (`combate.gd`): al terminar guarda y vuelve a `escena_retorno` (`combate.gd:3758-3764`).
8. **Autoloads:** `Dialogic`, `BotonDialogo` (`boton_dialogo.gd`) y `Recursos` (`recursos.gd`).
   - `Recursos` cambia de escena con carga en segundo plano y un fundido, y fija los FPS: 60 en combate y 30 en el
     resto.
   - Al pausar o cerrar la app, `Recursos` guarda llamando a `guardar_posicion()` de la escena (`recursos.gd:173-178`).

## 3. Guardado [código]

- **`progreso.gd`:** guarda en `user://partida.save` las metas de `Engine` que hay en `CLAVES` (`var_to_str`).
  - Guardado automático: al entrar en una zona, al volver al mapa, tras cada combate y al pausar o cerrar.
  - Las pruebas no guardan: `guardar()` no hace nada con `--script` o con argumentos de usuario.
- **Riesgo encontrado (2026-11-07):**
  - Una sesión que no carga la partida, por ejemplo con F6 desde el editor, puede sobrescribirla con datos parciales.
  - Así ocurrió con la partida del PC, que perdió la clave `grupo`.
  - Está en la tarea T-076.
- **En `rebelum-alpha`** (`d066fe9`, probado aislado):
  - partida experimental en `user://partida_exp.save`;
  - claves nuevas `hitos`, `pos_3d`, `pos_3d_ok` y `pos_3d_lugar`;
  - funciones `volcar()` y `restaurar()`;
  - si la escena guardada no existe en esta versión, se vuelve al mapa.
- **Desde `e670a5d`** ([D-060](DECISIONS.md#d-060)), también en `rebelum-alpha`:
  - la clave `grupo_activo` (quién está en el grupo ahora); `restaurar()` saca el grupo de los hitos en las partidas de
    antes con la misión empezada;
  - avisos al jugador (`Recursos.avisar`): no se pudo guardar, se recuperó una copia o no se pudo leer nada;
  - con la partida y su `.bak` dañadas se apartan las dos (`.danada` y `.bak.danada`) y empieza una partida nueva;
  - la ranura de prueba `partida_exp_prueba.save` (opción de desarrollo de `carga.gd`, solo en la versión
    experimental).
  - **Alcance:** reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).

## 4. Combate, magia, estados y progresión [código]

**Combate** (`combate.gd`, 3784 líneas):
- **ATB:** `ATB_MAX` 100 (`:16`) y una cola de turnos.
- **Menú de los héroes:** `menu_combate.gd`.
- **Enemigos:**
  - personalidades: agresivo, bruto, cobarde, apoyo y jefe;
  - entran en furia por debajo del 30 % de vida.
- **Grupos de enemigos** (`GRUPOS`, `:210`): los 5 primeros salen al azar.
  - En `rebelum-alpha` (`e670a5d`, [D-060](DECISIONS.md#d-060)), los grupos al azar dependen de cuántos héroes hay
    (`AL_AZAR_POR_TAMANO`): con uno, un slime, dos slimes o un Grimfang; con dos, tres slimes, Grimfang y slime, dos
    slimes o un Grimfang; con tres, como siempre.
  - Solo luchan los del grupo activo (`grupo.gd`, `activos()`); los ausentes no actúan ni cambian.
- **Combates fijos:** se piden con `grupo_combate` y `combate_fijo`.
- **Experiencia y oro:** al ganar.
- **Derrota:** se vuelve con la vida llena.
- **Huir:** desactivado en los combates que no son normales.

**Magias** (`MAGIAS`, `:64`):
- **Catálogo:** Fuego, Llamarada, Infierno, Agua, Torrente, Maremoto, Rayo, Tormenta, Cólera del Cielo, Cura,
  Bendición y Gracia Divina.
- **Niveles:** I, II y III (`grupo.gd` `NIVEL_MAGIA` [1, 5, 10]), elegidos en el menú por pestañas.
- **Coste en PM:** `MODO_PRUEBAS := true` en `desarollo` da **PM infinitos** en cualquier partida. En `rebelum-alpha`
  solo se activan con `-- pm_infinitos`.

**Técnicas:**
- **Embuir** (`:1526`): 5 PM, 3 turnos, +20 %, con Fuego, Hielo, Rayo o Agua.
- **Esgrima de Garon:** Juicio y Giro.
- **Armonía:** la barra de Lya, que sube 0,15 por cada acción de un héroe (`:46`). Llena, permite la invocación de
  Érebo.

**Estados que existen:**
- **Quemadura.**
- **Congelación:** Frostfang congela en cada golpe de Kael y quita 16 PV máximos durante 2 rondas (`:11-15` y
  `:1323-1346`). El diario lo describe como regla (`diario.gd:17`).
- **Defensa, furia, carga del jefe, rendición** (el último aliento de Gorthor: perdonar o acabar) **y huida.**
- **No existen** veneno, sueño, silencio, ceguera, prisa ni regeneración: son propuestas.

**Objetos de combate** (`OBJETOS_COMBATE`, `:39`): Poción (60 PV) y Éter (25 PM). El menú de campo lista todos los
objetos.

**Progresión** (`grupo.gd`):
- **Héroes:**
  - Kael: espadachín.
  - Lya: maga blanca.
  - Garon: tanque.
  - Nyx: mago negro, que existe pero **no está en el grupo**.
- **Grupo:** `EN_EL_GRUPO` = Kael, Lya y Garon.
- **Atributos:** 6, con 3 puntos por nivel; nivel máximo 50.
- **Experiencia:** se ajusta al nivel de la zona (`progreso.gd` `NIVEL_ZONA`). Los jefes dan ×10 y hay «zona limpia».
- **Objeto:** Incienso de Ceniza.

**Inventario, equipo y oro:** `inventario.gd`. Kael lleva Frostfang.

## 5. 3D: combate en parte 3D y exploración 3D sin integrar

- **Combate en parte 3D** [código + ejecutado]:
  - Kael (`kael_3d.gd`, `kael.fbx`), Lya (`maga_3d.gd`, `Meshy_AI_Anime_Girl_…fbx`), Garon (`garon_3d.gd`,
    `garon.fbx`), Grimfang y Gorthor (`goblin_3d.gd`, `goblin.fbx`; Gorthor, teñido y a ×1,2).
  - Cada uno se dibuja en su propio `SubViewport`, con una `Camera3D` ortográfica, sobre el fondo 2D (`combate.gd:4`
    y `:840-913`). Si falta el modelo, hay un respaldo en 2D.
  - El Slime, el Guardián de piedra y el Gólem de ámbar son **2D**.
  - Los gestos se generan por código (`gestos_3d.gd`).
- **Invocación de Érebo** (3D): `erebo_3d.gd`, `invocacion_base.gd`, `invocacion_erebo.gd`, `sombra_invocacion.gd`,
  `muneco_invocacion.gd` y 6 archivos `erebo_*.fbx`.
  - [ejecutado 2026-11-07]: con éxito, el enemigo pasa de 55 a 0 PV; con fallo, no hay daño.
  - Problema conocido: la mano no llega al pecho del enemigo ([docs/erebo/](docs/erebo/)).
- **Exploración 3D: NO integrada en el juego** [código]. Los prototipos de `aethelgard/prototipos/` solo se abren
  desde el editor o con la APK «Android prueba 3D»:
  - `vista3d.gd`: cámara a 45°, movimiento seguro por rayos, tocar para andar y WASD, objetos que se vuelven
    transparentes si tapan a Kael, y el panel `RND`/`CAL` con los bancos.
  - `sendero_puente.gd`/`.tscn`: Pastos Verdes generado por código (terreno, sendero, puente, río, cascada,
    `arbol_estilizado.gd`, hierba, faroles, la estatua del guardián en `modelos/guardian` y `fauna_simple.gd`).
  - `vegetacion_paquetes.gd`/`.tscn`: Quaternius y EmacE, con LOD, mallas indexadas y sombras C+ como opciones.
  - `calidad_proto.gd`: los perfiles bajo, medio y alto; sin reflejo del cielo en bajo y medio.
  - `titulo_rebelum.gd`: el título con el logo `marca/rebelum_logo.webp`.
- **En `rebelum-alpha`** (app experimental; confirmado y probado aislado el 2026-11-07):
  - el interruptor `modo3d.gd` (característica `rebelum3d` o `-- 3d`);
  - Pastos Verdes como lugar 10 del mapa, que abre la región `zonas3d/pastos_verdes_3d.tscn`
    ([D-051](DECISIONS.md#d-051)):
    - hereda de `sendero_puente.gd`;
    - tiene encuentros, combate con vuelta al mismo sitio, guardado y salidas al mapa;
    - la prueba es `pruebas/prueba_zona3d.gd`.
  - Tiene la misión del corte alfa PV-02 → PV-14 con Tilo, la estela y el centinela (`e212400`,
    [D-052](DECISIONS.md#d-052)). La prueba es `pruebas/prueba_ruta_alpha.gd`.
  - Desde el 2026-11-08 (`65fda8b`, [D-055](DECISIONS.md#d-055)), Lya y Garon siguen a Kael:
    - `zonas3d/grupo_3d.gd`, con los scripts del combate (`maga_3d.gd` y `garon_3d.gd`);
    - el botón GRUPO mide lo que cuestan;
    - las pruebas son `pruebas/prueba_grupo3d.gd` y `pruebas/prueba_grupo3d_fotos.gd`.
  - Desde el 2026-11-08 (`d4db508`), también tiene:
    - el cofre del árbol mágico ([D-057](DECISIONS.md#d-057)), que se guarda en `cofres_abiertos`;
    - la cinemática del mirador, PV-07 ([D-058](DECISIONS.md#d-058)), que se puede saltar.
    - Las pruebas son `prueba_cofre3d.gd`, `prueba_mirador.gd` y `prueba_region3d_fotos.gd`.
  - **Guardado** (`progreso.gd`, `86a58af`, [D-056](DECISIONS.md#d-056)):
    - no guarda encima de una partida que la sesión no cargó;
    - escribe en `.tmp`, lo comprueba y deja la anterior en `.bak`;
    - recupera una partida dañada.
  - Desde `3d5f63d` ([D-059](DECISIONS.md#d-059)):
    - Lya y Garon se unen con la misión (PV-03 y PV-05);
    - hay objetivo en pantalla y un rombo dorado sobre Tilo o el centinela.
    - Las pruebas son `prueba_grupo3d_rutas.gd` (rutas al azar, ruta válida) y `prueba_centinela.gd` (combate real con
      `-- auto`).
  - **Medición en el PC:** `pruebas/medir_ruta.gd`, el mismo recorrido con y sin grupo (T-022).
  - **Grupo activo** (`e670a5d`, [D-060](DECISIONS.md#d-060)): en la versión experimental la misión empieza con Kael
    solo; Lya se une en PV-03 y Garon en PV-05 (`grupo.gd`, `unir()`). Es la misma fuente para la exploración, el
    combate, los menús, la tienda y el guardado.
  - **Sin tirones de la primera vez** (`e630b02`, [D-061](DECISIONS.md#d-061)), en `prototipos/vista3d.gd`:
    - lo que tapa a Kael usa una copia transparente de su material, hecha una vez y guardada (`_material_transparente`;
      `sendero_puente.gd` la hace para las copas con sombreado propio);
    - al entrar, con la pantalla en negro, una «vitrina» dibuja dos fotogramas una miniatura de cada material de la
      escena delante de la cámara (`_preparar_sombreados`), para que Godot compile o lea de su caché los sombreados
      ahí y no al andar.
    - Se mide con `pruebas/medir_primeras_veces.gd`.

## 6. Diálogos y narrativa

- **Dialogic** [código]:
  - Timelines: `prologo`, `npc_aldric`, `npc_pip`, `npc_rosa` y `npc_selene`.
  - Personajes: aldric, kael, lya, pip, rosa y selene.
  - En `rebelum-alpha`: `pv_02`, `pv_03`, `pv_05`, `pv_06`, `pv_07`, `pv_14`, `pv_tilo` y `pv_tilo_fin` (la misión de
    Pastos Verdes 3D desde `e212400`), más garon y tilo, sin retrato.
  - **Interfaz reutilizada** (`rebelum-alpha`, `e630b02`, [D-061](DECISIONS.md#d-061)):
    - `dialogic/layout/end_behaviour` = 1: al acabar un diálogo la interfaz se oculta en vez de borrarse;
    - `carga.gd` lee el estilo en segundo plano y la crea oculta (`Recursos.precalentar_dialogos`), con el estilo de la
      biblia de arte (`BotonDialogo.estilar`);
    - al acabar cada diálogo, `Recursos._al_acabar_dialogo` limpia el texto, el nombre y los retratos.
    - La prueba es `pruebas/prueba_dialogo_interfaz.gd`.
- **Biblia:** [docs/biblia/rebelum_biblia_narrativa_v3.md](docs/biblia/rebelum_biblia_narrativa_v3.md), en propuesta.
  También la v2 y `rebelum_propuesta.md`.
- **La conversación original del director:** en `C:\Users\G513\Downloads\Telegram Desktop\`, fuera del repositorio.

## 7. Audio [código + ejecutado]

- **Música:**
  - Solo hay `musica_combate_normal.mp3` (`combate.gd:21` y `:407-420`); [ejecutado]: «música: true» en
    `prueba_gorthor`.
  - `musica_jefe*.mp3` **no existen**, así que los jefes usan la música normal.
  - **No hay** buses (falta `default_bus_layout.tres`) ni gestor de música.
  - El mapa, las zonas, la isla, el título y Pastos Verdes 3D **no tienen música**.
- **Efectos:**
  - **De Érebo:** 7 `sonidos/erebo_*.wav` (`invocacion_erebo.gd:55-162`); [ejecutado] se cargan y se lanzan sin
    errores.
  - **De menú, generados por código:** tic, confirmar y clac (`menu_combate.gd:550-697`; `combate.gd:1424` y
    `:1442`).
  - **De la pantalla de carga:** «confirmar» (`carga.gd:359`).
  - **Sin sonido:** ataques, impactos, magia, objetos, victoria, derrota, pasos, cofres, puertas, menús fuera del
    combate, mapa, zonas, título y VFX.
  - **Las pruebas usan audio mudo:** no se ha comprobado cómo suenan.
- **Fuera del repositorio:**
  - Las 4 pistas de Suno (ver §11).
  - La biblioteca `D:\qtorrent\sound effect`, que indicó el usuario: 10 533 archivos de 11 orígenes. Inventario y
    157 candidatos en [docs/audio/](docs/audio/).
  - Los planes de audio, en [docs/audio/musica_adaptativa.md](docs/audio/musica_adaptativa.md) y en
    [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md) §6.

## 8. Rendimiento y renderizado [historial; medido en el Redmi]

- **Detalle:** [docs/vegetacion_rendimiento.md](docs/vegetacion_rendimiento.md) y
  [docs/perfiles_graficos_propuesta.md](docs/perfiles_graficos_propuesta.md).
- **Redmi (Mali-G57):**
  - Limitado por la GPU.
  - Las hojas con transparencia recortada eran el mayor coste.
  - El terreno es el sombreado más caro.
  - Sin reflejo del cielo ahorra 3,3 ms a 20 m y 8 ms a 34 m.
- **Perfil bajo:** unos 34,5 ms de mediana, todavía sin 30 FPS estables.
- **Pendiente:** precalentar los sombreados en 3D y precalcular la sombra.

## 9. Exportación y versiones [código]

- **Presets** (`aethelgard/export_presets.cfg`):

  | Preset | Paquete | Notas |
  |---|---|---|
  | «Android» (estable) | `com.aethelgard.juego` | Excluye `prototipos`, `modelos`, `vegetacion_prueba`, `pruebas` y `para_meshy`. En `rebelum-3d`, también `zonas3d` |
  | «Android prueba 3D» | `com.aethelgard.prueba3d` | Característica `prueba3d`. Incluye prototipos y recursos con licencia pendiente |
  | «Android experimental» (solo en `rebelum-3d` y `rebelum-alpha`) | `com.aethelgard.experimental` | «Aethelgard Exp», característica `rebelum3d` |

  Todos usan la firma de depuración y solo arm64.
- **PC:** no hay preset. **iOS:** necesita un Mac.
- **GitHub:**
  - `v0.1.0` es una pre-release (Android, 223,7 MB);
  - sin protección de ramas;
  - Actions habilitado y sin workflows.
  - Plan: [docs/versiones/automatizacion_prereleases.md](docs/versiones/automatizacion_prereleases.md).
- **APK locales** en `D:\REBELUM_compilaciones`: ver [TASKS.md](TASKS.md) (T-011 y T-012).
- **APK de prueba para el móvil** (desde el 2026-11-08): se suben al repositorio privado
  `Brunopina6/Aethelgard-pruebas`, una versión por APK ([D-054](DECISIONS.md#d-054) y [T-079](TASKS.md#t-079)).
  - No es el repositorio del juego y no lleva código.
  - Se ordenan por fecha y versión, y ninguna se borra. La convención está en [CLAUDE.md](CLAUDE.md) §4.
  - También guarda una copia idéntica de la original, `v0.1.0`, al final de la lista.

## 10. Pruebas y herramientas [código + ejecutado]

- **Pruebas:** 27 en `aethelgard/pruebas/prueba_*.gd`, más `sonda_datos.gd`.
  - **Ejecutor y lista** (en `rebelum-3d` y `rebelum-alpha`): `pruebas/ejecutar_pruebas.ps1` y `lista_pruebas.txt`.
  - **Línea base:**
    - `rebelum-3d`: 15 superadas, 2 fallidas, 10 manuales y 0 no seguras.
    - `rebelum-alpha` (2026-11-07 15:27): **17 superadas, 0 fallidas**, 10 manuales y 0 no seguras.
    - `rebelum-alpha` (2026-11-08 16:35, batería `2026-11-08_163510`): **20 superadas, 0 fallidas**, 11 manuales y
      0 no seguras.
    - `rebelum-alpha` (2026-11-08 17:27, batería `2026-11-08_172719`): **25 superadas, 0 fallidas**, 12 manuales y
      0 no seguras.
    - `rebelum-alpha` (2026-11-08 18:45, `e630b02`, batería `2026-11-08_184433`): **28 superadas, 0 fallidas**,
      16 manuales y 0 no seguras.
  - **Nuevas desde el 08/11 por la tarde:** `prueba_grupos_combate`, `prueba_ranura_prueba` y
    `prueba_dialogo_interfaz` (automáticas); `medir_primeras_veces`, `sonda_dialogic_carga` y
    `sonda_oclusion_repetida` (manuales, para medir y atribuir).
- **Utilidades de arte** (`pruebas/herramientas/`): `hojas_a_geometria.gd`, `impostores.gd`, `preparar_meshy.gd`,
  `textura_hojas.gd` y `hoja.ps1`.
- **Compilación local:** `compilar_apk_experimental.ps1`, en la raíz (`rebelum-3d` y `rebelum-alpha`).
- **`instalar_android.ps1`** (raíz): instala por adb. **No se usa mientras el Redmi esté reservado.**
- **Raíz:**
  - Copias antiguas: `combate_backup_antes_mejoras.gd`, `mapa_backup_antes_mejoras.gd` y `project_backup.godot`.
  - `retirado/` (goblin_2d y grimfang).

## 11. Recursos y licencias

| Recurso | Estado |
|---|---|
| Personajes de Meshy (Kael, Lya, Garon, Érebo y Grimfang) y sus armas | El plan de Meshy del usuario está **sin confirmar** |
| Árboles y guardián de Meshy (`modelos/`) | Igual. El arce está en `.gitignore` |
| Quaternius MegaKit | CC0 |
| EmacE Stylized Grass (`vegetacion_prueba/emace`, en `.gitignore`) | **Prohibido redistribuir** sus archivos |
| Pack «Dual-Blade Combat Essentials» (`garon_espadas.res`) | Uso comercial permitido, sin redistribuir el original |
| `sonidos/erebo_*.wav` y `musica_combate_normal.mp3` | **Origen sin registrar** |
| Las 4 pistas de Suno (`sunlit_paths`, `morning_waltz`, `promised_horizon` y `waltz_starlit_path`, OGG a 48 kHz, sin bucle continuo) | **No son libres** (lo dijo el usuario el 08/11). ZIP en `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Musica_Pastos_Verdes_Godot.zip`. Solo para pruebas privadas locales |
| «The Last Encounter» | CC-BY-SA 3.0, según el informe de audio [historial] |
| Sonniss GDC | Uso comercial, sin redistribuir y sin uso para IA |
| TomMusic | Sin regalías, sin redistribuir |
| Pixel Combat | CC BY 4.0, con atribución |
| «500 Game Sound Effects» | CC0 declarada pero **sin verificar** |
| Logo `marca/rebelum_logo.webp` | Del autor |

Lista que aplica la compilación: [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt).
Registro de recursos: [docs/recursos.md](docs/recursos.md).

## 12. Resumen: integrado, prototipo y propuesta

En `rebelum-alpha` (app experimental), Pastos Verdes 3D ya está dentro del recorrido: mapa → región → combate →
región → mapa. La tabla describe `desarollo`.

| Integrado en el juego | Prototipo aislado | Propuesta (sin hacer) |
|---|---|---|
| Mapa y zonas 2D, mazmorra, isla, combate ATB con modelos 3D, Érebo, guardado, Dialogic, menús, diario, música de combate, sonidos de Érebo y de menú | Pastos Verdes 3D, bancos de vegetación y perfiles de calidad, título con logo | Región 3D jugable (fases 2.3-2.5), audio unificado (2.6), nueva invocación de Érebo (2.7), magias, estados, tablero, IA e invocaciones nuevas, Android TV, pre-releases |
