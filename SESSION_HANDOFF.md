# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-08 a las 22:55 (hora local, UTC+1). **La tanda 1 está en marcha:** sonido y
animaciones trabajan desde las 22:27, cada uno en su copia.
- **Encargo vigente (22:40, pegado):** sesión prolongada y autónoma para mejorar REBELUM, con prioridades de 1 a 7
  ([MEMORIA_CHAT.md](MEMORIA_CHAT.md)). **El usuario (22:50):** «acepto todo no me preguntes mas solo hazlo»: no se
  para a preguntar dentro del alcance; las normas de [CLAUDE.md](CLAUDE.md) siguen.
- **Comprobado a las 22:45:**
  - la protección del guardado está en todas las copias de prueba;
  - la partida real no ha cambiado (`A3F3C402…`, de las 19:37);
  - inventario de programas en `docs/herramientas/programas_pc.md` (`integracion-experimental` @ `dddbddb`).
- **Nuevo encargo (22:00, pegado, 10 puntos):** organizar el desarrollo con **un coordinador y cinco especialistas**
  (gráficos, sonido, narrativa, combate y animaciones). Prioridades: los **efectos de sonido de la biblioteca** del
  usuario, **la mano de Kael** en el diálogo inicial y **el mapamundi**. Amplía la autorización de GitHub
  ([D-070](DECISIONS.md#d-070)). Resumen en [MEMORIA_CHAT.md](MEMORIA_CHAT.md); reparto en [D-069](DECISIONS.md#d-069);
  tareas [T-082](TASKS.md#t-082) a [T-088](TASKS.md#t-088).
- **Hecho antes en esta sesión** (encargo de las 20:20, 9 puntos):
  - la v54 y la v57 en las Descargas del Redmi; la protección del guardado en la copia habitual (`b8e042d`);
  - el ejecutor de pruebas solo cierra lo suyo (`d5fd793`); los encuentros con los niveles reales (`9bfd288`);
  - el gestor de música con ambientes CC0 (`40fb5b8`, v57);
  - **el prólogo con puesta en escena y retratos vivos** (`375cc8c`, [T-081](TASKS.md#t-081),
    [D-068](DECISIONS.md#d-068)).
- **Relevo anterior:** [docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md).

## Dónde está todo

| Qué | Valor |
|---|---|
| Raíz del repositorio | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard\` |
| Copia del usuario | Rama `rebelum-3d` @ `b8e042d`, local. Aquí se editan los documentos de memoria. **El usuario tiene abierto su editor de Godot sobre esta copia** (desde las 21:52): aquí no se lanza otro Godot |
| Integración | `D:\Aethelgard_alpha`, rama `integracion-experimental` @ `1c17763`, en GitHub. `rebelum-alpha` se queda en `375cc8c`, como estaba |
| Especialistas (tanda 1) | Sonido: `D:\Aethelgard_sonido`, rama `area-sonido`. Animaciones: `D:\Aethelgard_animaciones`, rama `area-animaciones`. Las dos parten de `1c17763` y están en GitHub. Configuración: `.claude/agents/especialista-*.md` (en `D:\Aethelgard` y en la rama de integración). Cada uno deja su informe en `docs/memory/agents/` de su rama |
| Respaldo de lo local | `D:\REBELUM_respaldos\2026-11-08_rebelum-alpha_375cc8c\rebelum-alpha.bundle`: los commits de `rebelum-alpha` y `rebelum-3d` que no están en GitHub (`git bundle verify`: correcto) |
| Copias temporales | `D:\Aethelgard_guardado` (validación del guardado) y `D:\Aethelgard_antes` (medidas «antes» del prólogo, en `40fb5b8`), unos 1,4 GB cada una. Se pueden quitar con permiso |
| Copia de la memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo` |
| GitHub (`Brunopina6/Aethelgard`) | `main` @ `d4b2d16`, `desarollo` @ `2d1adc4`, `v0.1.0` y `memoria-desarrollo`. Desde las 22:20, también `integracion-experimental`, `area-sonido` y `area-animaciones` (@ `1c17763`), que llevan dentro el contenido de `rebelum-alpha`. `rebelum-3d` no está subida |
| APK de prueba | `Brunopina6/Aethelgard-pruebas`: v57 («Latest»), v54, v52… y la original. En el Redmi: `Download/Aethelgard_Exp_2026-11-08_v54.apk` y `…_v57.apk` |
| Redmi | REDMI A7 Pro, Android 16, por USB con el ADB del SDK (`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`) |
| Última batería | 22:00, `rebelum-alpha` con el prólogo: 37 superadas, 0 fallidas, 19 manuales, 0 no seguras. Código 254 solo porque el editor del usuario cambió un archivo de la caché de sombreadores de la carpeta real; `partida.save`, sin cambios. `D:\REBELUM_diagnostico\pruebas\2026-11-08_214904\resumen.md` |
| Procesos en marcha | El editor del usuario y, desde las 22:27, los especialistas de sonido y animaciones (subagentes en segundo plano), cada uno en su copia. El PC tiene 15,4 GB de memoria y quedaban unos 2,5 GB libres con el editor abierto: como mucho, dos especialistas a la vez |

## Encargo en curso (22:00)

| Punto | Estado |
|---|---|
| 1. Guardar la continuidad | **Hecho** (22:05): `375cc8c`, respaldo, memoria publicada y `CONTINUAR_EN_NUEVO_CHAT.txt` para coordinar |
| 2. Comprobar los subagentes y configurarlos | **Hecho** (22:25), con un límite (abajo) |
| 3. Coordinación e integración | Siempre; reglas en [D-069](DECISIONS.md#d-069) |
| 5. Sonido: primera tanda de efectos ([T-083](TASKS.md#t-083)) | **En curso** (tanda 1, desde las 22:27) |
| 6. Animaciones: la mano de Kael ([T-084](TASKS.md#t-084)) | **En curso** (tanda 1, desde las 22:27) |
| 4. Gráficos: el mapamundi ([T-085](TASKS.md#t-085)) | Tanda 2 |
| 7. Narrativa ([T-086](TASKS.md#t-086)) | Tanda 2, con animaciones |
| 8. Combate ([T-087](TASKS.md#t-087)) | Tanda 3, con sonido |
| 9. GitHub: ramas por área e integración ([T-088](TASKS.md#t-088)) | **Hecho para la tanda 1** (22:20): tres ramas subidas tras revisarlas |
| 10. Validación final, APK y Redmi | Tras integrar |

## Subagentes: lo comprobado (22:25)

- **Subagentes reales:** sí. Se lanzan en segundo plano y avisan al terminar; la documentación permite hasta 20 a la
  vez, y aquí se usan dos por la memoria del PC.
- **Tipos propios** (`.claude/agents/especialista-*.md`): el formato se comprobó con la documentación oficial (`name`,
  `description`, `disallowedTools`, `model`, `color`…). Pero **esta sesión no los reconoce**, porque la carpeta no
  existía cuando empezó; la documentación avisa de que entonces hace falta reiniciar. Probado: «Agent type
  'especialista-sonido' not found». En esta sesión se lanzan como subagentes `general-purpose` que leen su archivo como
  instrucciones (mismas reglas y área; ejecución real). En una sesión nueva se pueden llamar por su nombre.
- **Aislamiento:** el `isolation: worktree` de los subagentes parte de `main`, no de nuestra rama, así que no se usa.
  Cada especialista tiene una copia de trabajo manual desde `integracion-experimental`, con la caché `.godot`
  copiada (2087 archivos, 501 MB) para no reimportar.

## Hallazgo para animaciones (22:00, observado en el archivo)

- En el prólogo, Kael tiene **la mano junto a la cabeza en la propia ilustración** (`dialogos/retratos/kael.png`, la
  única que tiene). Sale igual en las 9 frases, también mientras habla Lya. No es un clip ni una mezcla: el arreglo es
  otra pose del retrato (por ejemplo, renderizada desde su modelo 3D), no un ajuste de animación.
- Los diálogos 3D de Pastos Verdes (PV-02…) son otra cosa: allí se revisan clips, miradas, pies y armas.
- Las capturas que menciona el encargo no llegaron con el mensaje: se trabaja con reproducciones propias.

## Trabajo a medio hacer y cómo retomarlo

- **Botón de desarrollo «Probar el prólogo (partida nueva)»** en la pantalla de carga (`carga.gd`), sin empezar. Hace
  falta para ver el prólogo en el Redmi: con una partida existente no sale, y «Probar la misión desde el principio» lo
  salta.
  - **Diseño:** abajo a la izquierda, simétrico al botón actual (860, 652; 400×56). Usa la misma ranura aislada
    (`P.empezar_ranura_prueba()`, `P.cargar()`, `Recursos.marcar_partida_prueba()`), **sin** marcar
    `prologo_visto`, y va a `res://mapa.tscn`.
  - **Teclado y mando:** ↓ sigue eligiendo el botón actual (lo esperan `prueba_mando` y `prueba_teclado`); ← y → pasan
    de uno a otro; ↑ y Esc sueltan el foco.
  - **Prueba:** ampliar `prueba_ranura_prueba.gd`.
  - **Cuándo:** al integrar la tanda 1, porque `carga.gd` es de sonido mientras dure (un solo responsable por archivo).

## Cambios sin confirmar

- **`D:\Aethelgard`:** los documentos de memoria y los cambios del usuario (bloque B), sin tocar.
- **`D:\Aethelgard_alpha`:** solo el `CLAUDE.md` puntero.

## Límites de lo comprobado

- **Redmi:** v54 y v57 copiadas y comprobadas (tamaño y SHA-256); el usuario aún no las ha probado.
- **T-025, sin hardware:** ni mando ni teclado reales; el táctil, solo simulado. No es una validación completa.
- **Escucha:** nadie ha escuchado todavía los ambientes, el cofre, las campanas ni los volúmenes. Las pruebas de señal
  miden, no escuchan.
- **Combates:** se ganan con ataques automáticos; no prueban la estrategia de un jugador.
- **Guardado:** lo comprobado reduce el riesgo, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **La copia habitual** sigue con el ejecutor de pruebas antiguo.

## Próximo paso concreto

1. **Recibir las entregas de la tanda 1** (llegan como aviso al terminar cada especialista). Revisar cada una:
   diferencias, pruebas, evidencias y licencias.
2. **Integrarlas en `integracion-experimental`** con un merge normal, resolviendo a mano `pruebas/lista_pruebas.txt` y
   `docs/recursos.md`, que tocan los dos. Después, la batería completa y el push de las ramas.
3. **El botón «Probar el prólogo»** (lo hace el coordinador, tras integrar sonido).
4. **Tanda 2:** gráficos (el mapamundi) y narrativa con animaciones. **Tanda 3:** combate con sonido.
5. **Recorrido real con ventana**, APK nueva al Redmi y memoria.

## Pendiente del usuario

- **Instalar y probar la v57** (en Descargas; incluye la v54): con el dedo, que todo funcione y no salga ningún marco
  dorado al tocar; que Lya, al unirse, deje ganar los combates; **escuchar** los ambientes, su vuelta tras el combate
  y los volúmenes de «Ajustes».
- **Opcional:** las capturas del mapamundi y de la mano de Kael que menciona el encargo; un mando o teclado Bluetooth.
- **Decidir** la nivelación al unirse ([D-062](DECISIONS.md#d-062)); no hace falta para seguir.
- Licencias ([T-070](TASKS.md#t-070)): qué sustituye a la música de Suno en una APK entregable; créditos de Meshy.

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Push:** la memoria, en `memoria-desarrollo`; las APK de prueba, en `Aethelgard-pruebas`; y desde las 22:00,
  código, configuraciones de agentes y documentación revisados, en **ramas de trabajo** de `Brunopina6/Aethelgard`
  ([D-070](DECISIONS.md#d-070)). Nunca en `main` ni en `desarollo`; nunca force push; nunca APK, bibliotecas
  completas, partidas, cachés, secretos ni la exportación del chat. Publica el coordinador.
- **Redmi:** solo copiar APK de prueba a Descargas por USB y comprobarlas; instala el usuario
  ([D-065](DECISIONS.md#d-065)).
- **Copia habitual:** solo la protección del guardado ([D-066](DECISIONS.md#d-066)); el bloque B no se toca.
- **Licencias:** las APK siguen siendo `NO_DISTRIBUIR`; ninguna lleva música de Suno, y Suno nunca va a GitHub.
- **Datos:** la partida del PC se conserva tal cual; las pruebas, siempre aisladas.
- **Magias:** las existentes no cambian ([D-048](DECISIONS.md#d-048)). Si sonorizar una exige cambiar su
  presentación, se deja para una decisión aparte.
