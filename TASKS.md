# TASKS: tareas de AETHELGARD / REBELUM

**Actualizado el 2026-11-07 a las 16:35 (hora local, UTC+1).**
- Copia del usuario: `rebelum-3d` @ `ce84422`.
- Árbol del encargo: `rebelum-alpha` @ `c2a524c`.

**Estados**
- **Pendiente:** sin empezar.
- **En curso:** con trabajo activo.
- **Bloqueada:** espera una decisión, un permiso o un dispositivo del usuario, o está en pausa por orden suya.
- **Terminada:** con evidencia comprobable.

**Reglas de este archivo**
- Los identificadores son estables y no se reutilizan.
- Una tarea terminada sin evidencia vuelve a pendiente.
- Una prueba que nadie ha ejecutado figura como pendiente.

**Cuidado con la palabra «fase»:** hay tres numeraciones distintas. Están explicadas en el glosario de
[MEMORIA_CHAT.md](MEMORIA_CHAT.md#glosario-de-fases).

## Resumen

| ID | Tarea | Estado | Prioridad |
|---|---|---|---|
| [T-001](#t-001) | Sistema de memoria y continuidad | Terminada (sin confirmar en Git) | — |
| [T-002](#t-002) | Publicar la memoria en `memoria-desarrollo` | Terminada; se repite en cada hito | — |
| [T-010](#t-010) | Fase 2.0 del plan 3D: preparación segura | Terminada | — |
| [T-011](#t-011) | APK experimental local | Terminada (compilada) | — |
| [T-012](#t-012) | APK «Prueba 3D» de Pastos Verdes | Terminada (compilada) | — |
| [T-020](#t-020) | Encargo, Fase 0: línea base, respaldo y diagnóstico | Terminada | — |
| [T-021](#t-021) | Pastos Verdes 3D desde el mapa (encargo 2.1-2.2; plan 2.3-2.4) | En curso | Alta |
| [T-022](#t-022) | Región 3D completa (encargo 2.3-2.5; plan 2.4-2.5) | Pendiente | Alta |
| [T-023](#t-023) | Cierre del perfil bajo: precalentado y sombra precalculada (plan 2.1) | Pendiente | Media |
| [T-024](#t-024) | Métricas de referencia y matriz de cobertura | Pendiente | Media |
| [T-025](#t-025) | Entrada: mando, teclado y foco; Android TV (plan 2.2) | Pendiente | Media |
| [T-026](#t-026) | Combate híbrido: coste de las ventanas 3D | Pendiente | Baja |
| [T-027](#t-027) | Preset de exportación para PC | Pendiente | Baja |
| [T-030](#t-030) | Audio unificado (Fase 2.6) | Pendiente | Media |
| [T-040](#t-040) | Magia aditiva, estados, tablero, habilidades e IA | Pendiente | Media |
| [T-050](#t-050) | Invocaciones nuevas, cinemáticas y VFX | Pendiente | Baja |
| [T-051](#t-051) | Nueva invocación de Érebo (Fase 2.7) | Bloqueada (decisiones) | Media |
| [T-060](#t-060) | Optimización continua y cierre técnico | Pendiente | Media |
| [T-061](#t-061) | Activar por defecto las optimizaciones de vegetación | Bloqueada (autorización) | Media |
| [T-062](#t-062) | Césped distribuible en lugar de EmacE | Pendiente | Media |
| [T-070](#t-070) | Licencias pendientes | Bloqueada (usuario) | Alta |
| [T-071](#t-071) | Decisiones narrativas de la biblia v3 | Bloqueada (usuario) | Media |
| [T-072](#t-072) | Decisiones D1-D12 de la cinemática de Érebo | Bloqueada (usuario) | Media |
| [T-073](#t-073) | Decisiones D1-D7 sobre las Skills | Bloqueada (usuario) | Baja |
| [T-074](#t-074) | Preguntas de GitHub y pre-releases | Bloqueada (usuario) | Baja |
| [T-075](#t-075) | Commit del bloque B | Bloqueada (usuario) | Media |
| [T-076](#t-076) | Que una sesión sin partida cargada no pise la partida completa | Pendiente | Alta |
| [T-077](#t-077) | `prueba_guardado` con un archivo propio | Pendiente | Media |
| [T-078](#t-078) | Validar las APK en el Redmi | Bloqueada (dispositivo) | Media |

## Continuidad

### T-001
**Sistema de memoria y continuidad**
- **Estado:** terminada el 2026-11-07, sin confirmar en Git. **Decisión:** [D-047](DECISIONS.md#d-047).
- **Objetivo:** retomar el trabajo en cualquier conversación nueva sin depender de lo que recuerde el chat.
- **Dependencias:** ninguna.
- **Criterio de aceptación:**
  - Están los siete archivos de la raíz y `docs/memory/`, con enlaces y rutas válidos.
  - `git status` solo muestra documentos nuevos o cambiados.
  - No hay secretos.
  - `MEMORIA_CHAT.md` empieza con un resumen y un índice.
  - Hay una copia revisada del chat fuera del repositorio.
- **Evidencia** (comprobada el 2026-11-07 hacia las 16:10, sobre `ce84422`):
  - **Archivos nuevos, sin seguimiento:** `CLAUDE.md`, `PROJECT_CONTEXT.md`, `TASKS.md`, `DECISIONS.md`,
    `SESSION_HANDOFF.md`, `MEMORIA_CHAT.md`, `CONTINUAR_EN_NUEVO_CHAT.txt` y
    `docs/memory/historial_2026-10-30_a_2026-11-07.md`.
  - **Enlaces:** 224 relativos, sin fallos, incluidas las anclas. De las 72 rutas absolutas solo falta una, la del
    siguiente paso, que todavía no existe: `zonas3d\pastos_verdes_3d.gd`.
  - **Sin cambios en lo que ya existía:** `git diff` de los archivos con seguimiento es idéntico byte a byte a
    `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico\cambios_sin_confirmar.patch`.
  - **Sin datos sensibles:** ni el número de serie del móvil, ni correos, ni tokens.
  - **Copia revisada del chat:** `D:\REBELUM_respaldos\2026-11-07_chat_exportado\`.
- **Siguiente acción:** mantener los documentos al día en cada hito. Publicarlos es [T-002](#t-002).

### T-002
**Publicar la memoria en `memoria-desarrollo`**
- **Estado:** terminada el 2026-11-07, con la autorización de las 16:30 ([D-049](DECISIONS.md#d-049)). Se repite en cada
  hito.
- **Objetivo:** tener la memoria en GitHub para consultarla al empezar cualquier sesión.
- **Dependencias:** T-001.
- **Criterio de aceptación:**
  - La rama `memoria-desarrollo` de `Brunopina6/Aethelgard` contiene solo los documentos de memoria, revisados.
  - `git ls-remote origin refs/heads/memoria-desarrollo` devuelve su commit.
- **Evidencia:**
  - La rama sale de `desarollo` (`2d1adc4`), en la copia aparte `D:\Aethelgard_memoria`.
  - Los commits publicados se ven con `git log origin/memoria-desarrollo`, y el último, en
    [SESSION_HANDOFF.md](SESSION_HANDOFF.md).
- **Siguiente acción:** publicar tras cada hito, siguiendo el procedimiento de [CLAUDE.md](CLAUDE.md) §2.

## Fase 2.0 y compilaciones

### T-010
**Fase 2.0 del plan 3D: preparación segura**
- **Estado:** terminada. **Decisión:** [D-004](DECISIONS.md#d-004).
- **Evidencia:**
  - **Commits:** 9 locales en `rebelum-3d`, de `379122b` a `ce84422`. Nunca se han subido.
  - **Informe:** [docs/fase2/fase2.0_comprobaciones.md](docs/fase2/fase2.0_comprobaciones.md).
  - **Respaldo:** `D:\REBELUM_respaldos\2026-11-07_antes_fase2.0`, con el paquete Git de todas las ramas, el manifiesto
    SHA-256 y la copia histórica de `partida.save`.
  - **Pruebas en `rebelum-3d`:** 15 superadas, 2 fallidas (eran fallos de las propias pruebas; se corrigieron en T-020),
    10 manuales y 0 no seguras.
- **Lo que queda fuera:** instalar la APK experimental junto a la estable en el Redmi (T-078).

### T-011
**APK experimental local**
- **Estado:** terminada como compilación. La prueba en el Redmi está en T-078.
- **Evidencia:**
  - **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-c66f29d.apk`, de 253 574 579 bytes.
  - **SHA-256:** `13a74f97d71947bd2fc8d8a4582d268594401c36d72805b0efef23d2566053ca`.
  - **Al lado:** `.resumen.txt` y `.NO_DISTRIBUIR.txt`.
  - **Paquete:** `com.aethelgard.experimental`.
- **Qué hace:** arranca el juego 2D, porque todavía no tiene la región 3D.
- **Nota:** la compilación anterior, `…-d09ae1c-local.apk`, se hizo antes de corregir el script.
- **No se distribuye:** lleva recursos de licencia pendiente.

### T-012
**APK «Prueba 3D» de Pastos Verdes**
- **Estado:** terminada como compilación. Instalarla y probarla en el Redmi queda pendiente del usuario.
- **Evidencia:**
  - **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_prueba3d-20261107-98ac41f-local.apk`, de 284 816 787 bytes.
  - **SHA-256:** `8677785d0c0dbc8714e2282d13c7809ec455fbca82ebaae629a1cb2266710d51`.
  - **Paquete:** `com.aethelgard.prueba3d`, versionCode 24, nombre visible «Aethelgard Prueba 3D».
  - **Firma:** de depuración, verificada.
  - **Por qué acaba en `-local`:** lleva los cambios sin confirmar del bloque B y archivos nuevos de
    `vegetacion_prueba/quaternius`.
- **Entrega:** a petición del usuario, se copió el 2026-11-07 a las 04:00 a la carpeta Descargas del Redmi. Desde
  entonces el móvil está reservado ([D-013](DECISIONS.md#d-013)) y no se ha vuelto a consultar.
- **No se distribuye.**

## Encargo único (reanudado el 07/11 a las 16:30: ver [D-046](DECISIONS.md#d-046))

### T-020
**Encargo, Fase 0: línea base, respaldo y diagnóstico**
- **Estado:** terminada.
- **Evidencia:**
  - **Commits** en `rebelum-alpha`: `3a16db2`, `872517a`, `aa709dd` y `c2a524c`.
  - **Pruebas:**
    - Pasada completa `2026-11-07_152737`: 17 superadas, 0 fallidas, 10 manuales y 0 no seguras.
    - Repetición de las dos pruebas corregidas (`2026-11-07_152859`): las dos superadas.
    - Los registros están en `D:\REBELUM_diagnostico\pruebas\`.
  - **Respaldo:** `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico`.
  - **Registro:** `D:\Aethelgard_alpha\docs\fase2\registro_encargo.md`, con las decisiones 0.1 a 0.10.
- **Lo que no cubre:** las métricas de rendimiento y la matriz de cobertura, que también pedía la Fase 0 (T-024).

### T-021
**Pastos Verdes 3D accesible desde el recorrido normal (encargo: Fase 1, puntos 2.1-2.2; plan 3D: 2.3-2.4)**
- **Estado:** en curso; se retomó el 2026-11-07 a las 16:30. Hay trabajo a medias, sin confirmar. **Prioridad:** alta.
- **Objetivo:** en la compilación experimental, ir del mapa a Pastos Verdes 3D y volver, sin abrir escenas a mano, con
  la variante 2D como respaldo.
- **Dependencias:** T-020.
- **Hecho, sin probar ni confirmar** (en `D:\Aethelgard_alpha`):
  - **`aethelgard/progreso.gd`:** `partida_exp.save`, `hitos`, `pos_3d`, `volcar()`/`restaurar()` y el detalle
    «Estela del camino».
  - **`aethelgard/modo3d.gd`** (nuevo).
  - **`aethelgard/mapa.gd`:** el lugar 10.
  - **`aethelgard/project.godot`:** diálogos `pv_*`, personajes garon y tilo, y `ui_accept`/`ui_cancel` con mando.
  - **Diálogos nuevos:** 8 archivos `aethelgard/dialogos/pv_*.dtl`, más `dialogos/personajes/garon.dch` y `tilo.dch`.
  - **Copia** en `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico\`:
    `rebelum-alpha_fase1_parcial_sin_confirmar.patch` y `rebelum-alpha_archivos_nuevos.tar`.
- **Falta:**
  - **`aethelgard/zonas3d/pastos_verdes_3d.gd` y `.tscn`.** El diseño ya está pensado:
    - hereda de `prototipos/sendero_puente.gd`;
    - Lya y Garon siguen a Kael;
    - Tilo como personaje provisional;
    - un cofre y la estela;
    - HUD;
    - encuentros: paso de 0,5 m, 40 pasos seguros, probabilidad de 0,012;
    - combate fijo «pastos_centinela»;
    - salidas al mapa.
  - **Pruebas:** `prueba_zona3d` y una del recorrido alfa.
  - **Preset experimental:** que su lista de exclusiones conserve `prototipos/{vista3d.gd, sendero_puente.gd,
    calidad_proto.gd, arbol_estilizado.gd, fauna_simple.gd, agua_sin_refraccion.gdshader}`.
- **Criterio de aceptación:**
  - Se entra y se sale de Pastos Verdes 3D desde el mapa de la compilación experimental, con la posición y el estado
    coherentes.
  - Sin el modo 3D, todo vuelve al mapa 2D.
  - Las pruebas de siempre y las nuevas pasan en el ejecutor aislado.
  - Commits locales pequeños en `rebelum-alpha`.
- **Siguiente acción** (cuando el usuario lo ordene):
  1. Revisar el trabajo a medias con `git -C D:\Aethelgard_alpha diff`.
  2. Escribir la escena de la región y su prueba.
  3. Ejecutar `aethelgard/pruebas/ejecutar_pruebas.ps1`.
  4. Confirmar.

### T-022
**Región 3D completa (encargo: Fase 1, puntos 2.3-2.5; plan 3D: 2.4-2.5)**
- **Estado:** pendiente. **Prioridad:** alta. **Dependencias:** T-021.
- **Objetivo:**
  - NPC, diálogos, interacción, cofres y encuentros.
  - De la zona al combate y de vuelta, tras ganar, huir o perder, sin resolver dos veces el mismo encuentro o botín.
  - Guardado y carga de partidas antiguas y nuevas, con campos ausentes y vuelta al 2D.
- **Criterio de aceptación:**
  - Un recorrido reproducible desde el flujo experimental, con las pruebas aisladas registradas.
  - Del plan 3D, punto 2.5:
    - la misión de PV-02 a PV-14 se completa en el PC;
    - los hitos sobreviven a guardar y cargar;
    - `prueba_dialogos` y `prueba_ruta_alpha` salen en verde.

### T-023
**Cierre del perfil bajo: precalentado de sombreados y sombra precalculada (plan 3D: 2.1)**
- **Estado:** pendiente. **Prioridad:** media.
- **Dependencias:** necesita el Redmi para medir (T-078).
- **Contexto [historial]:** el perfil bajo daba unos 34,5 ms de mediana en el Redmi, todavía sin 30 FPS estables.
- **Criterio de aceptación** (plan 3D, punto 2.1), medido en el Redmi con el escenario y Kael en bajo:
  - mediana ≤ 31 ms y p95 ≤ 38 ms;
  - ningún pico > 100 ms después del precalentado;
  - carga de la escena ≤ 4 s;
  - sin pérdida visual;
  - el perfil alto queda intacto ([D-020](DECISIONS.md#d-020)).

### T-024
**Métricas de referencia y matriz de cobertura**
- **Estado:** pendiente. **Prioridad:** media.
- **Objetivo:** lo que piden las fases 0 y 5 del encargo:
  - FPS, mediana y percentil 95 del tiempo por fotograma, y picos;
  - memoria, llamadas de dibujo, tiempos de carga y tamaño de la APK;
  - una matriz breve de cobertura por fase.
- **Criterio de aceptación:** una tabla en `docs/` con el equipo, la escena, el perfil y el resultado. No se atribuyen al
  móvil resultados medidos en el PC.

### T-025
**Entrada: mando, teclado y foco; Android TV (plan 3D: 2.2)**
- **Estado:** pendiente. **Prioridad:** media.
- **Criterio de aceptación** (plan 3D, punto 2.2):
  - el juego 2D se juega entero solo con un DS4: inicio, mapa, zona, combate, menús y diálogos;
  - el táctil sigue funcionando como hoy;
  - `prueba_mando`, `prueba_foco` y las pruebas táctiles salen en verde.
- **Objetivo:** jugar con DualShock 4, teclado o pantalla táctil, con menús navegables por foco. Después, Android TV
  (Ugoos SK1).
- **Hecho a medias:** las acciones `ui_accept` y `ui_cancel` con mando, en el `project.godot` de `rebelum-alpha`
  (sin confirmar).
- **Plan:** [docs/entrada/android_tv_dualshock4_plan.md](docs/entrada/android_tv_dualshock4_plan.md).

### T-026
**Combate híbrido: coste de las ventanas 3D**
- **Estado:** pendiente. **Prioridad:** baja.
- **Objetivo:** medir lo que cuestan los SubViewports por personaje antes de cambiar la arquitectura (Fase 1 del
  encargo).

### T-027
**Preset de exportación para PC**
- **Estado:** pendiente. **Prioridad:** baja.
- **Objetivo:** el encargo pide probar el ejecutable de PC exportado, y hoy no hay preset para Windows.

### T-030
**Audio unificado (Fase 2.6; Fase 4 del encargo)**
- **Estado:** pendiente. **Prioridad:** media.
- **Dependencias:** un flujo jugable estable (T-021 y T-022). Para distribuir algo, además, las licencias (T-070).
- **Objetivo:**
  - Buses y un gestor de música.
  - Música para el mapa, las zonas, la isla, la mazmorra, el título, Pastos Verdes y los jefes.
  - Efectos de sonido para ataques, impactos, magia, objetos, victoria, derrota, pasos, cofres, puertas y menús.
- **Criterio de aceptación:**
  - Cada evento suena una sola vez.
  - La escucha en el PC se registra aparte de la ejecución muda.
  - Inventario de cada sonido: original, recurso derivado, evento, licencia y evidencia.
- **Referencias:**
  - [D-043](DECISIONS.md#d-043) y [docs/audio/](docs/audio/);
  - el ZIP de Suno: `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Musica_Pastos_Verdes_Godot.zip`;
  - la biblioteca `D:\qtorrent\sound effect`, con 157 candidatos.

### T-040
**Magia aditiva, estados, tablero, habilidades e IA (Fase 2 del encargo)**
- **Estado:** pendiente. **Prioridad:** media. **Regla:** [D-048](DECISIONS.md#d-048): el catálogo actual no cambia.
- **Criterio de aceptación:**
  - Regresiones del catálogo actual antes y después.
  - Identificadores estables.
  - Las partidas antiguas siguen cargando.
- **Propuestas de partida:** en [MEMORIA_CHAT.md](MEMORIA_CHAT.md).

### T-050
**Invocaciones nuevas, cinemáticas y VFX (Fase 3 del encargo)**
- **Estado:** pendiente. **Prioridad:** baja.
- **Dependencias:** el canon que decida el usuario (T-071).

### T-051
**Nueva invocación de Érebo (Fase 2.7)**
- **Estado:** bloqueada: faltan las decisiones D1-D12 (T-072). **Prioridad:** media.
- **Plan:** [docs/erebo/invocacion_erebo_plan_final.md](docs/erebo/invocacion_erebo_plan_final.md) y
  [docs/erebo/invocacion_erebo_cinematica.md](docs/erebo/invocacion_erebo_cinematica.md).
- **Criterio de aceptación:**
  - Se cumplen las reglas de [D-038](DECISIONS.md#d-038).
  - La animación no decide el daño dos veces.
  - El salto deja la misma resolución.

### T-060
**Optimización continua y cierre técnico (Fase 5 del encargo)**
- **Estado:** pendiente. **Prioridad:** media.
- **Metas:** 30 FPS en el perfil ligero del Redmi y 60 FPS en un PC capaz ([D-021](DECISIONS.md#d-021)).

### T-061
**Activar por defecto las optimizaciones de vegetación (LOD, mallas indexadas y sombras C+)**
- **Estado:** bloqueada: necesita la autorización del usuario ([D-025](DECISIONS.md#d-025)). **Prioridad:** media.

### T-062
**Césped distribuible en lugar de EmacE**
- **Estado:** pendiente. **Prioridad:** media.
- **Objetivo:** un césped con licencia clara para la app, como matas opacas más densas, porque EmacE no se puede
  redistribuir.

## Decisiones y recursos que dependen del usuario

### T-070
**Licencias pendientes**
- **Estado:** bloqueada: depende del usuario. **Prioridad:** alta.
- **Falta confirmar:**
  - el plan de Meshy (personajes, armas, árboles y guardián);
  - el plan de Suno de las cuatro pistas;
  - «The Last Encounter» (CC-BY-SA 3.0) y la recopilación «500 Game Sound Effects»;
  - el origen de `sonidos/erebo_*.wav` y `musica_combate_normal.mp3`;
  - el origen de `espada2.obj`, `hacha.obj`, `hoja_infernal.obj`, `vara.obj`, `averno.obj` y `diamante_azul.obj`, que
    no figuran en `docs/recursos.md`.
- **Criterio de aceptación:**
  - Cada recurso tiene su licencia y su evidencia en [docs/recursos.md](docs/recursos.md).
  - [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt) está al día.

### T-071
**Decisiones narrativas de la biblia v3**
- **Estado:** bloqueada: depende del usuario.
- **Qué falta:** las 12 preguntas de §8.2 y las 16 decisiones de §10.7 de
  [docs/biblia/rebelum_biblia_narrativa_v3.md](docs/biblia/rebelum_biblia_narrativa_v3.md).

### T-072
**Decisiones D1-D12 de la cinemática de Érebo**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/erebo/invocacion_erebo_cinematica.md](docs/erebo/invocacion_erebo_cinematica.md).

### T-073
**Decisiones D1-D7 sobre las Skills**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/herramientas/propuesta_skills.md](docs/herramientas/propuesta_skills.md). Las 26 Skills `aet-*` están
  desfasadas.

### T-074
**Preguntas de GitHub y pre-releases**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/versiones/automatizacion_prereleases.md](docs/versiones/automatizacion_prereleases.md).

### T-075
**Commit del bloque B**
- **Estado:** bloqueada: depende del usuario ([D-006](DECISIONS.md#d-006)).

### T-076
**Que una sesión sin partida cargada no pise la partida completa**
- **Estado:** pendiente. **Prioridad:** alta, por el riesgo de perder datos.
- **Hecho observado en el código** (`aethelgard/progreso.gd:181-194`):
  - `guardar()` solo escribe las metas que existen en ese momento.
  - Una sesión que no cargó la partida, por ejemplo con F6 desde el editor, la sustituye por una parcial.
  - Así perdió la partida del PC la clave `grupo` el 07/11 a las 03:50.
- **Criterio de aceptación:**
  - Con partidas sintéticas y en el ejecutor aislado, una sesión que no cargó la partida no reduce las claves guardadas.
  - Las pruebas de guardado pasan.
- **Restricción:** la partida del PC no se restaura ([D-011](DECISIONS.md#d-011)).

### T-077
**`prueba_guardado` con un archivo propio**
- **Estado:** pendiente. **Prioridad:** media.
- **Hecho observado en el código:**
  - `aethelgard/pruebas/prueba_guardado.gd` escribe en `user://partida.save` (`P.GUARDADO`) y luego lo restaura.
  - Solo es segura con el ejecutor aislado (`lista_pruebas.txt:26`).
- **Objetivo:** que use una ruta de pruebas propia, para que sea segura también fuera del ejecutor.

### T-078
**Validar las APK en el Redmi**
- **Estado:** bloqueada: el usuario conecta el móvil cuando lo decida ([D-013](DECISIONS.md#d-013)).
- **Qué validar:**
  - que se instala junto a la app estable sin tocar sus datos;
  - el arranque;
  - Pastos Verdes 3D;
  - el rendimiento del perfil bajo;
  - el control táctil.
