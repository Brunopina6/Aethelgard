# TASKS: tareas de AETHELGARD / REBELUM

**Actualizado el 2026-11-08 a las 20:05 (hora local, UTC+1).**
- Copia del usuario: `rebelum-3d` @ `ce84422`.
- Árbol del encargo: `rebelum-alpha` @ `edf52cd`.

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
| [T-021](#t-021) | Pastos Verdes 3D desde el mapa (encargo 2.1-2.2; plan 2.3-2.4) | Terminada en PC; falta el móvil | Alta |
| [T-022](#t-022) | Región 3D completa (encargo 2.3-2.5; plan 2.4-2.5) | Hecha en el PC (misión, grupo activo, cofre, mirador, objetivo y combate real); faltan escuchar y el Redmi | Alta |
| [T-023](#t-023) | Cierre del perfil bajo: precalentado y sombra precalculada (plan 2.1) | En curso: tirones de diálogos y de la primera vez, arreglados en el PC; faltan el Redmi y la sombra | Media |
| [T-024](#t-024) | Métricas de referencia y matriz de cobertura | Pendiente | Media |
| [T-025](#t-025) | Entrada: mando, teclado y foco; Android TV (plan 2.2) | En curso: hecha en el PC con eventos simulados (`e6e52c4`); faltan el Redmi, un teclado y un mando reales, los ajustes y la TV | Media |
| [T-026](#t-026) | Combate híbrido: coste de las ventanas 3D | Pendiente | Baja |
| [T-027](#t-027) | Preset de exportación para PC | Pendiente | Baja |
| [T-030](#t-030) | Audio unificado (Fase 2.6) | Pendiente | Media |
| [T-040](#t-040) | Magia aditiva, estados, tablero, habilidades e IA | Pendiente | Media |
| [T-050](#t-050) | Invocaciones nuevas, cinemáticas y VFX | Pendiente | Baja |
| [T-051](#t-051) | Nueva invocación de Érebo (Fase 2.7) | Bloqueada (decisiones) | Media |
| [T-060](#t-060) | Optimización continua y cierre técnico | Pendiente | Media |
| [T-061](#t-061) | Activar por defecto las optimizaciones de vegetación | Bloqueada (autorización) | Media |
| [T-062](#t-062) | Césped distribuible en lugar de EmacE | Pendiente | Media |
| [T-063](#t-063) | Créditos de Meshy y paquete entregable | Pendiente | Media |
| [T-070](#t-070) | Licencias pendientes (inventario hecho) | Bloqueada (usuario) | Alta |
| [T-071](#t-071) | Decisiones narrativas de la biblia v3 | Bloqueada (usuario) | Media |
| [T-072](#t-072) | Decisiones D1-D12 de la cinemática de Érebo | Bloqueada (usuario) | Media |
| [T-073](#t-073) | Decisiones D1-D7 sobre las Skills | Bloqueada (usuario) | Baja |
| [T-074](#t-074) | Preguntas de GitHub y pre-releases | Bloqueada (usuario) | Baja |
| [T-075](#t-075) | Commit del bloque B | Bloqueada (usuario) | Media |
| [T-076](#t-076) | Que una sesión sin partida cargada no pise la partida completa | Terminada en alpha (`86a58af`) | — |
| [T-077](#t-077) | `prueba_guardado` con un archivo propio | Terminada en alpha (`86a58af`) | — |
| [T-078](#t-078) | Validar las APK en el Redmi | Bloqueada (dispositivo) | Media |
| [T-079](#t-079) | Repositorio privado para descargar las APK de prueba en el móvil | Terminada | — |
| [T-080](#t-080) | Decidir la nivelación automática de quien se une al grupo (D-062) | Bloqueada (usuario) | Baja |

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
- **Estado:** terminada en el PC el 2026-11-07. Falta verla en el Redmi (T-078) y revisar su aspecto con ventana.
- **Objetivo:** en la compilación experimental, ir del mapa a Pastos Verdes 3D y volver, sin abrir escenas a mano, con
  la variante 2D como respaldo.
- **Dependencias:** T-020.
- **Criterio de aceptación:**
  - Se entra y se sale de Pastos Verdes 3D desde el mapa de la compilación experimental, con la posición y el estado
    coherentes.
  - Sin el modo 3D, todo vuelve al mapa 2D.
  - Las pruebas de siempre y las nuevas pasan en el ejecutor aislado.
  - Commits locales pequeños en `rebelum-alpha`.
- **Antes de empezar** se verificó que el trabajo a medias era idéntico byte a byte a su respaldo (el parche y los 11
  archivos nuevos del `.tar`). Se reutilizó tal cual, sin aplicar nada.
- **Evidencia** (commits locales en `rebelum-alpha`):
  - **`d066fe9`:**
    - `modo3d.gd`, el interruptor;
    - `mapa.gd`, el lugar 10;
    - `progreso.gd`: `partida_exp.save`, `hitos`, `pos_3d`, `volcar()`/`restaurar()` y la «Estela del camino».
  - **`f039c72`:**
    - los 8 diálogos `pv_*` y los personajes garon y tilo;
    - `ui_accept` y `ui_cancel` con mando en `project.godot`.
  - **`a89a8a5`:** la región `zonas3d/pastos_verdes_3d.gd` y `.tscn`, más `pruebas/prueba_zona3d.gd`.
    - Hereda de `sendero_puente.gd`.
    - Entrada por el principio del camino.
    - Encuentros: paso de 0,5 m, 40 pasos seguros y probabilidad 0,012.
    - Combate con vuelta al mismo sitio.
    - Guardado automático al entrar y al pausar.
    - Dos salidas al mapa, marcadas con un círculo dorado y el letrero «Mapa del mundo».
    - Del panel del prototipo solo quedan CAL y RND.
  - **`03b960a`:** el preset experimental incluye lo que necesita la región y deja fuera los bancos y la vegetación
    de prueba.
  - **Pruebas:**
    - `prueba_zona3d`, pasada `2026-11-07_164457`: entrada, 39 pasos seguros sin encuentro, encuentro, **combate de
      verdad** y vuelta a 0,00 m del sitio, salida al mapa con el lugar 10 y guardado en `partida_exp.save`.
    - Batería completa `2026-11-07_164526`: **18 superadas, 0 fallidas**, 10 manuales y 0 no seguras. Ni la partida
      real ni el proyecto cambiaron.
  - **APK:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-03b960a.apk`.
    - 244,7 MB, versionCode 34.
    - SHA-256 `1a2b43178cd4ff1944a71d205a879af79e2d9b1aaa4b7e6297e74980d04ef08b`.
    - Paquete `com.aethelgard.experimental` y firma verificada.
    - Lleva la región y sus dependencias, y no lleva pruebas, prototipos de banco, EmacE ni partidas.
    - Es una **prueba privada**, con el aviso `NO_DISTRIBUIR`: lleva recursos de la tabla de licencias.
- **Lo que no cubre:**
  - **Aspecto:** no se ha visto con ventana: las pruebas van sin ventana.
  - **Redmi:** no se ha probado en el móvil.
  - **Grupo y contenido:** los seguidores, Tilo, la estela, el cofre y el combate fijo están en T-022.

### T-022
**Región 3D completa (encargo: Fase 1, puntos 2.3-2.5; plan 3D: 2.4-2.5)**
- **Estado:** en curso desde el 2026-11-07. **Prioridad:** alta. **Dependencias:** T-021. **Decisión:**
  [D-052](DECISIONS.md#d-052).
- **Hecho** (`e212400`, rama `rebelum-alpha`): la misión del corte alfa.
  - PV-02 al entrar y PV-03 en el camino.
  - Tilo, el farolero (figura provisional), junto al puente: PV-05, su recordatorio, PV-14 con la mecha y la despedida.
  - La estela del camino (detalle de lore «pastos_estela»).
  - El centinela del mirador: PV-06, el combate fijo «pastos_centinela» con dos Grimfang, y PV-07 al ganarlo.
  - Botón «Hablar con Tilo» o «Examinar».
  - **Pruebas:** `prueba_ruta_alpha`, nueva, recorre la misión entera con Dialogic de verdad y el combate fijo
    cargado. Batería `2026-11-07_170431`: **19 superadas, 0 fallidas**, 10 manuales y 0 no seguras.
  - **APK:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-07ac036.apk`, de 244,7 MB.
    - SHA-256 `f63e99b18f5172705454d12ec25e693ae35beacd2e29848925f018cb6cf444b9`.
    - Es de prueba privada, con el aviso `NO_DISTRIBUIR`.
- **Hecho el 2026-11-08** (`65fda8b` y `3976565`, rama `rebelum-alpha`): **Lya y Garon siguen a Kael**
  ([D-055](DECISIONS.md#d-055)).
  - `zonas3d/grupo_3d.gd`, que la región crea si los dos están en el grupo de la partida.
  - El botón GRUPO mide lo que cuestan.
  - **Pruebas** (batería `2026-11-08_163510`): **20 superadas, 0 fallidas**, 11 manuales y 0 no seguras. La partida
    real no cambió.
    - `prueba_grupo3d`, nueva, recorre el camino, cruza el puente y da media vuelta sobre él: Lya queda a 1,80 m como
      mucho de Kael y Garon a 1,93 m de Lya; nadie pisa zonas prohibidas, flota ni atraviesa a otro. También comprueba
      que reaparecen detrás de Kael y que con «grupo»: false no salen.
    - `prueba_grupo3d_fotos`, nueva, saca 14 capturas en los perfiles bajo y alto. Revisadas a ojo
      (`D:\REBELUM_diagnostico\pruebas\2026-11-08_163228\prueba_grupo3d_fotos`): siguen en fila por el puente y se
      apartan en la media vuelta.
    - Con las capturas se corrigieron dos cosas: la separación pasó de 1,5 a 1,8 m, y Garon, quieto, ya no apunta a
      Lya con las espadas.
  - **Coste medido en el PC** (banco GRUPO, sin tope, a 20 m; `D:\REBELUM_diagnostico\sondas\2026-11-08_163317`):

    | Perfil | Sin grupo | Con grupo | Diferencia |
    |---|---|---|---|
    | bajo | 2,8 ms | 3,2 ms | +0,4 ms, +6 dibujos, +44k triángulos y +46 MB de vídeo |
    | medio | 3,0 ms | 3,4 ms | +0,4 ms |
    | alto | 3,1 ms | 3,6 ms | +0,5 ms |

    Con el tope de 30 FPS, el bajo con grupo da 30,1 FPS sin tirones. Son datos del PC; falta medir en el Redmi.
  - **APK:** `Aethelgard_exp-20261108-3976565.apk` (versionCode 41), subida como «08/11/2026 · Prueba v41»
    ([T-079](#t-079)).
    - SHA-256 `8f3f52ef4275c85c20672e3aa0e44236a5e1068e460c71238e4180d636392188`.
- **Hecho el 2026-11-08 por la tarde** (`d4db508` y `21d2e21`, rama `rebelum-alpha`):
  - **El cofre del árbol mágico** ([D-057](DECISIONS.md#d-057)). `prueba_cofre3d` comprueba:
    - que Kael llega andando desde el puente;
    - el premio una sola vez (50 monedas) y el sonido sin saturar;
    - que sigue abierto tras guardar (en el archivo de verdad de la prueba), un combate real con vuelta, volver a
      entrar y cargar la partida.
  - **La cinemática del mirador** ([D-058](DECISIONS.md#d-058)). `prueba_mirador` comprueba:
    - la primera vez, con el hito guardado antes de terminar;
    - que no hay control y que vuelven la cámara y el control;
    - que no se repite en una visita posterior;
    - saltarla con Escape, tras lo que no suena nada más.
  - **Capturas** (`prueba_region3d_fotos`, `D:\REBELUM_diagnostico\pruebas\2026-11-08_171143`): cofre y cinemática en
    bajo y alto, revisadas a ojo. Por ellas se giró el cofre y se subieron los planos de la cinemática.
  - **Batería `2026-11-08_171230`: 23 superadas, 0 fallidas**, 12 manuales y 0 no seguras. La partida real no cambió.
  - **APK:** subida como «08/11/2026 · Prueba v44» (`exp-20261108-21d2e21`) ([T-079](#t-079)).
- **Hecho después** (`3d5f63d`, [D-059](DECISIONS.md#d-059)):
  - el grupo se une con la misión;
  - el objetivo en pantalla y el rombo dorado.
  - **`prueba_grupo3d_rutas`**, nueva: 3 series de destinos al azar, alcanzables y con semilla fija, más sitios
    difíciles, medias vueltas y la cámara a 9, 20 y 34 m.
    - Kael anda 181 m y llega a todos los destinos.
    - En cada fotograma: 0 zonas prohibidas, 0 fuera del suelo, 0 obstáculos atravesados y 0 rezagados; dos
      fotogramas juntos.
    - Comprueba también que en el juego normal se cuentan los pasos: los encuentros siguen activos. Solo las pruebas
      los ponen a 0.
  - **`prueba_centinela`**, nueva: el combate del centinela **jugado de verdad** (ataques automáticos, `-- auto`).
    - El grupo inicial lo gana en 64 s de juego y pasa de 150 a 186 monedas; se guarda.
    - Después: cinemática, PV-07, PV-14, salir al mapa, volver y cargar, sin repetir nada.
    - **Alcance:** ataques automáticos, sin magias ni objetos. No prueba la estrategia de un jugador.
  - `prueba_ruta_alpha` comprueba quién acompaña a Kael y el objetivo en cada paso de la misión.
  - **Batería `2026-11-08_172719`: 25 superadas, 0 fallidas** y 12 manuales.
- **Medido en el PC** (08/11, 17:30; `pruebas/medir_ruta.gd`, commit `3d5f63d`):
  - **Condiciones:** el mismo recorrido para todas (andar, puente ida y vuelta, cofre, Tilo, entrada al combate,
    combate y vuelta), los mismos fotogramas (`--fixed-fps 30`), sin tope, a 1280×720 y con un proceso por condición.
  - **Equipo:** Ryzen 7 4800H, RTX 3050 Laptop, 16 GB, Godot 4.7.2.
  - **Datos:** `D:\REBELUM_diagnostico\mediciones\2026-11-08_ruta_grupo\` (`comparacion.md` y los JSON).

  | Fase | Bajo, mediana (p95) | Alto, mediana (p95) |
  |---|---|---|
  | andar | 2,93 → 3,42 ms (17,7 → 19,1) | 3,27 → 3,68 ms (20,4 → 19,0) |
  | puente | 2,92 → 3,56 ms (3,5 → 4,7) | 3,24 → 3,85 ms (3,7 → 4,5) |
  | interacción | 2,91 → 3,33 ms (3,5 → 4,1) | 3,21 → 3,73 ms (3,9 → 4,5) |
  | combate | 4,07 → 3,97 ms (el grupo no está) | 3,87 → 3,93 ms |

  - **Con el grupo:** +46 MB de memoria de vídeo (texturas de los dos modelos) y +6 dibujos y +43k triángulos en bajo
    (+12 y +86k en alto). La carga de la región pasa de 1,7 a 2,2 s.
  - **Coste identificado y arreglado** (`ce2094b`): generar el sonido del cofre al abrirlo daba un tirón de unos 180 ms.
    Ahora se prepara al cargar, y el p99 de la interacción baja de 33 a 6 ms.
  - **Costes identificados y sin tocar:**
    - la primera vez que se abre un diálogo de Dialogic, unos 180 ms (con y sin grupo);
    - al empezar a andar, el p95 sube a unos 18 ms con picos de 50 ms, con y sin grupo. Probablemente son sombreados
      que se compilan (T-023).
  - **Solo orienta:** el PC no es el Redmi. Lo que cuesta el grupo allí se mide con el banco GRUPO.
- **APK:** «08/11/2026 · Prueba v47» (`exp-20261108-091d1d1`) ([T-079](#t-079)).
- **Hecho después** (`e670a5d`, [D-060](DECISIONS.md#d-060)), a petición del usuario («Sí. Antes de que Lya se una en
  PV-03, los combates aleatorios deben ser solo de Kael…»):
  - el grupo activo es la fuente común de la exploración, el combate, los menús, la tienda y el guardado;
  - los encuentros al azar dependen de cuántos son, para que Kael solo pueda ganarlos;
  - avisos del guardado y la opción de desarrollo «Probar la misión desde el principio», en otra ranura.
  - **Pruebas:** `prueba_grupos_combate` (grupos de 1, 2 y 3), `prueba_partida` (casos 7 y 8) y
    `prueba_ranura_prueba`. Batería `2026-11-08_175301`: **27 superadas, 0 fallidas** y 13 manuales.
- **Después, los tirones** (`e630b02`, [D-061](DECISIONS.md#d-061)): ver [T-023](#t-023).
- **APK:** «08/11/2026 · Prueba v50» (`exp-20261108-36502e9`) ([T-079](#t-079)).
- **Falta:**
  - **escuchar** el sonido del cofre y las campanas;
  - la opinión visual del usuario y medir el grupo en el Redmi (botón GRUPO);
  - revisar con ventana el aspecto de Tilo, la estela y las salidas.
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
- **Estado:** en curso. **Prioridad:** media.
- **Hecho el 2026-11-08 por la tarde** (`e630b02`, [D-061](DECISIONS.md#d-061)), medido en el PC con
  `pruebas/medir_primeras_veces.gd` (pantalla de carga real, dos pasadas, primer arranque y con caché; datos en
  `D:\REBELUM_diagnostico\primeras_veces\comparacion.md`):
  - **Diálogos:** la interfaz de Dialogic se prepara oculta en la pantalla de carga y se reutiliza. El primer diálogo
    pasa de 184 a 9-11 ms y cada uno de los siguientes, de 54-56 a 6-7 ms.
  - **Al andar:** los árboles que tapan a Kael usan una copia transparente guardada, y una vitrina dibuja en la entrada,
    en negro, cada material de la escena. El primer paseo pasa de picos de 41 ms (tras instalar) y 19 ms (con caché) a
    4-5 ms; cada oclusión, de unos 11 a 3-4,7 ms.
  - **Lo que crece:** la pantalla de carga, un fotograma de unos 30 ms; la entrada en la región, en negro, unos
    0,1-0,2 s en el PC.
  - **Pruebas:** `prueba_dialogo_interfaz`, nueva. Batería `2026-11-08_184433`: **28 superadas, 0 fallidas** y
    16 manuales; capturas de la región, del grupo y del diálogo revisadas, iguales que antes.
  - **Falta:** medirlo en el Redmi (tiempos de carga, tirones que queden y si la caché de sombreados funciona en el
    Mali-G57), y la sombra precalculada.
- **Dependencias:** necesita el Redmi para medir (T-078).
- **Contexto [historial]:** el perfil bajo daba unos 34,5 ms de mediana en el Redmi, todavía sin 30 FPS estables.
- **Medido en el Redmi el 2026-11-08** (región 3D, APK `989d35e`, sin seguidores):
  - **TOPE** (con el tope de 30 FPS), bajo a 20 m: **30,1 FPS**, p95 de 34,0 ms y 0 % de tirones.
  - **PRUEBA** (sin tope), bajo a 20 m: mediana de **21,5 ms** (cumple ≤ 31) y p95 de **38,4 ms** (se pasa de ≤ 38 por
    0,4 ms). A 34 m: 27,1 y 49,6 ms.
  - **Sin medir:** los picos de más de 100 ms y el tiempo de carga.
  - **Registros:** `D:\REBELUM_diagnostico\redmi_2026-11-08_region\`. Las tablas completas están en el relevo
    archivado ([docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md)).
  - **Cuidado al leerlo** (corrección del 08/11): que la mediana sin tope sea 21,5 ms no garantiza unos 12 ms libres
    dentro de los 33,3 ms de 30 FPS. Cuentan el p95 (38,4 ms), los picos, la memoria y las cargas. Lo que cueste el
    grupo hay que medirlo en el Redmi (banco GRUPO).
  - **Siguiente:** precalcular la sombra para bajar el p95 sin tope, y medir en el Redmi los picos y las cargas.
  - **Candidatos medidos en el PC el 08/11** (`medir_ruta.gd`; ver [T-022](#t-022)), ya arreglados en `e630b02`:
    - picos de unos 50 ms al empezar a andar (sombreados que se compilan);
    - unos 180 ms la primera vez que se abre un diálogo de Dialogic.
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
- **Estado:** **hecha en el PC con eventos simulados** (`rebelum-alpha` @ `e6e52c4`, 08/11 a las 19:55). Falta
  validarla con hardware: el Redmi, un teclado y un mando reales. Android TV, después. **Prioridad:** media.
- **Criterio de aceptación** (plan 3D, punto 2.2):
  - el juego 2D se juega entero solo con un DS4: inicio, mapa, zona, combate, menús y diálogos;
  - el táctil sigue funcionando como hoy;
  - `prueba_mando`, `prueba_foco` y las pruebas táctiles salen en verde.
- **Objetivo:** jugar con DualShock 4, teclado o pantalla táctil, con menús navegables por foco. Después, Android TV
  (Ugoos SK1).
- **Hecho el 2026-11-08 por la noche** (rama `rebelum-alpha`, [D-063](DECISIONS.md#d-063)), con prioridad para
  Android y PC:
  - acciones de teclado y mando, el autoload `Entrada` y el foco visible;
  - exploración, ventanas, combate, diálogos y pantalla de carga sin ratón;
  - una pulsación, una acción; el mando desconectado deja seguir.
  - **Pruebas nuevas** (todas con eventos **simulados**: teclas y botones de mando de verdad inyectados en Godot):
    - `prueba_foco`: menús, tienda, diario, barra del mapa, ciudad y mando desconectado;
    - `prueba_mando` y `prueba_teclado`: el recorrido sin ratón, desde la pantalla de carga (partida de prueba) hasta
      el mapa, con PV-02, andar, la cámara, hablar con Tilo y un combate;
    - `prueba_precalentado`: lo que se prepara antes de jugar no provoca nada de juego;
    - `prueba_dialogo_interfaz`, ampliada: opciones, señales y una pulsación, una acción (con control: sin el filtro,
      falla).
  - **Táctil:** `prueba_toque`, `prueba_dpad` y las de la región siguen en verde; la prueba de las capturas con el dedo
    enseña el menú sin el marco del foco.
  - `prueba_grupos_combate` exige la experiencia exacta que reparte `combate.gd`, y que huir o perder no den
    ninguna. Fallaba al azar: si el único enemigo del grupo 7 (un Slime cobarde) huye, se gana sin experiencia, como
    manda el juego.
  - **El ejecutor** apunta cualquier Godot que no haya lanzado y da la hora de cada cambio de la carpeta real. Al
    pasarse de tiempo una prueba, solo cierra lo suyo ([D-010](DECISIONS.md#d-010)).
- **Evidencia** (ejecutado aislado; batería `2026-11-08_195103`, sobre lo que es `e6e52c4`): **32 superadas, 0
  fallidas**, 17 manuales y 0 no seguras. La partida real, la carpeta real de datos y el proyecto, sin cambios; ningún
  otro Godot.
  - `prueba_foco_fotos` (con ventana, `2026-11-08_195003`): 7 capturas revisadas a ojo. El marco dorado se ve en la
    carga, la barra del mapa, el menú del grupo, el «+» de un atributo, la ciudad y la tienda; con el dedo no sale.
  - `prueba_grupos_combate`, tres pasadas sueltas en verde; en una se repitió el Slime huido del grupo 7.
- **APK:** «08/11/2026 · Prueba v52» (`exp-20261108-edf52cd`, [T-079](#t-079)), para la prueba táctil en el Redmi.
- **Pruebas manuales abiertas** (no las puedo hacer yo: aquí no hay mando, y el Redmi está reservado):
  1. **Redmi, táctil:**
     - andar tocando y con la cruceta;
     - los botones de la barra, «Entrar» y la acción;
     - diálogos con «SEGUIR»;
     - el combate tocando (filas, deslizar ATACAR, pestañas de magia, objetivo, saltar la invocación);
     - menús, tienda y diario.
     - Comprobar que al tocar no sale el marco dorado y que la barra no se queda con el foco.
  2. **Teclado real en el PC:** el recorrido sin ratón (Intro, Esc, Tab, flechas, WASD, Q / E y + / -).
  3. **Mando real** (DS4 o de tipo Xbox), en el PC y en Android por Bluetooth:
     - que cada botón haga lo que dice la tabla de D-063;
     - una desconexión de verdad y su aviso.
  4. **A ojo, tu opinión:** las capturas del foco las revisé yo (lámina en
     `D:\REBELUM_diagnostico\pruebas\2026-11-08_195003\prueba_foco_fotos\lamina_foco.png`); falta la tuya.
  5. **Android TV** (Ugoos SK1) y su mando a distancia: más adelante.
- **Falta:**
  - una pantalla de ajustes (no existe);
  - los textos de combate en modo mando («TOCA UN ENEMIGO»);
  - los iconos por mando;
  - pausa y salir con Atrás fuera del combate;
  - Android TV.
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

### T-063
**Créditos de Meshy y paquete entregable**
- **Estado:** pendiente. **Prioridad:** media. **Decisión:** [D-050](DECISIONS.md#d-050).
- **Objetivo:** que algún día pueda haber una APK **entregable**.
- **Pasos:**
  1. Una pantalla o un archivo de créditos con la atribución de Meshy: «Model created with Meshy – CC BY 4.0 License».
     Con ella, los modelos de Meshy se pueden distribuir con cualquier plan (las condiciones están en el inventario).
  2. Un preset o un modo del script de compilación que **se niegue** a compilar si queda dentro algo de
     `licencias_pendientes.txt`.
- **Dependencias:** las respuestas del usuario en T-070.
- **Criterio de aceptación:** una compilación entregable sin ningún patrón de `licencias_pendientes.txt`.

## Decisiones y recursos que dependen del usuario

### T-070
**Licencias pendientes**
- **Estado:** bloqueada: depende del usuario. **Prioridad:** alta.
- **Inventario hecho el 2026-11-07:** `D:\Aethelgard_alpha\docs\versiones\inventario_licencias.md` (commit `e8b9ed4`,
  rama `rebelum-alpha`).
  - Tiene 13 grupos con derechos pendientes. Para cada uno dice qué usos bloquea: commit, prueba privada o APK
    entregable.
  - Recoge las condiciones de Meshy y de Suno, leídas ese día en sus páginas oficiales.
  - `licencias_pendientes.txt` tiene ya los patrones que faltaban.
- **Meshy:**
  - Con el plan gratuito, CC BY 4.0 (uso comercial con atribución). Con plan de pago, los modelos son del usuario.
  - Con los créditos (T-063), se pueden distribuir con cualquiera de los dos planes.
  - **Falta que el usuario confirme** que las imágenes que subió a Meshy eran suyas o libres.
- **Suno:**
  - Con el plan gratuito, solo uso personal no comercial. Suscribirse después no da derechos retroactivos.
  - **El 08/11 el usuario dijo:** «la música de suno no son libres».
    - Las cuatro pistas se tratan como no libres: solo en pruebas privadas locales, nunca en commits ni en APK que salgan
      del PC, tampoco en el repositorio de pruebas.
    - Para el juego publicado harían falta pistas generadas y descargadas con un plan de pago durante la suscripción,
      o sustitutas.
- **Falta confirmar:**
  - el plan de Meshy (personajes, armas, árboles y guardián);
  - con qué se sustituyen las cuatro pistas de Suno en una APK entregable, o si se generan de nuevo con plan de pago;
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
- **Estado:** **terminada en `rebelum-alpha`** el 2026-11-08 (`86a58af`, [D-056](DECISIONS.md#d-056)). En `desarollo`
  sigue el problema.
- **Hecho observado en el código** (antes del arreglo, `aethelgard/progreso.gd:181-194`):
  - `guardar()` solo escribe las metas que existen en ese momento.
  - Una sesión que no cargó la partida, por ejemplo con F6 desde el editor, la sustituye por una parcial.
  - Así perdió la partida del PC la clave `grupo` el 07/11 a las 03:50.
- **Arreglo:**
  - Solo se guarda encima de una partida si la sesión la cargó (o no había ninguna).
  - Se escribe en `.tmp`, se comprueba y se sustituye; la anterior queda en `.bak`.
  - Una partida dañada se recupera de `.tmp` o `.bak`, y la dañada se aparta en `.danada`.
- **Evidencia** (ejecutado aislado; batería `2026-11-08_170008`: **21 superadas, 0 fallidas**, 11 manuales):
  - `prueba_partida`, nueva, con partidas sintéticas: sesión sin cargar (no guarda y la partida no cambia), cofre,
    misión y posición tras un combate, partida antigua sin claves ni lista de objetos, dañada, escritura fallida y
    corte al guardar.
  - La partida real del PC no cambió.
- **Ampliado en `e670a5d`** ([D-060](DECISIONS.md#d-060)): avisos al jugador; casos 7 (la partida y su `.bak`
  dañadas: se apartan las dos y empieza una nueva) y 8 (partida nueva sin archivos). **Alcance:** lo comprobado
  reduce el riesgo de perder la partida, no lo elimina ([D-056](DECISIONS.md#d-056)).
- **Restricción:** la partida del PC no se restaura ([D-011](DECISIONS.md#d-011)).
- **08/11, 19:37:34:** volvió a pasar en la copia del usuario (`rebelum-3d`, sin este arreglo). Un juego lanzado desde
  su editor reescribió la partida del PC ([D-011](DECISIONS.md#d-011)). El arreglo llegará a esa copia cuando el
  usuario decida integrar `rebelum-alpha`.

### T-077
**`prueba_guardado` con un archivo propio**
- **Estado:** **terminada en `rebelum-alpha`** el 2026-11-08 (`86a58af`).
- **Antes:** `aethelgard/pruebas/prueba_guardado.gd` escribía en `user://partida.save` (`P.GUARDADO`) y luego lo
  restauraba. Solo era segura con el ejecutor aislado.
- **Ahora:** usa `user://prueba_guardado.save` con Engine `archivo_partida_prueba`. `progreso.gd` nunca acepta ahí la
  ruta de una partida de verdad.

### T-078
**Validar las APK en el Redmi**
- **Estado:** bloqueada: el usuario conecta el móvil cuando lo decida ([D-013](DECISIONS.md#d-013)).
- **Primera validación hecha el 2026-11-08** ([D-053](DECISIONS.md#d-053)):
  - la APK experimental `989d35e`, instalada por el usuario desde Descargas, se instala aparte de la app estable;
  - Pastos Verdes 3D funciona;
  - los bancos PRUEBA y TOPE dan los resultados de [T-023](#t-023).
  - **Faltan** la opinión visual del usuario y validar el control táctil a fondo.
- **Qué validar:**
  - que se instala junto a la app estable sin tocar sus datos;
  - el arranque;
  - Pastos Verdes 3D;
  - el rendimiento del perfil bajo;
  - el control táctil.

### T-079
**Repositorio privado para descargar las APK de prueba en el móvil**
- **Estado:** terminada el 2026-11-08, a las 14:46 ([D-054](DECISIONS.md#d-054)).
- **Repositorio:** `https://github.com/Brunopina6/Aethelgard-pruebas`, privado.
  - Su único colaborador es el dueño, y no tiene incidencias ni wiki.
  - El `README.md` (commit `9c83ac3`) explica cómo instalar una prueba en el móvil.
- **Primera versión:** `exp-20261108-aabe5ad`.
  - **APK:** `Aethelgard_exp-20261108-aabe5ad.apk`, compilada con `compilar_apk_experimental.ps1` («TODO CORRECTO»).
  - Sale de `rebelum-alpha` @ `aabe5ad`, con versionCode 39 y el mismo certificado que las anteriores: se instala
    encima y conserva la partida del móvil.
  - **Tamaño:** 256 596 467 bytes (244,7 MB).
  - **SHA-256:** `06bf212add337a3afda056bd7a79f3d354e84eb2698940e92ee66bee3cdd3b6c`.
  - Lleva los mismos recursos pendientes que `989d35e`, y ninguno es de Suno.
- **Evidencia** (comprobado con `gh api` a las 14:46):
  - el recurso está en estado `uploaded`, con el mismo tamaño;
  - el `digest` de GitHub coincide con el SHA-256 local;
  - `releases/latest` apunta a esta versión;
  - el repositorio es privado.
- **Ordenada por fecha y versión** (08/11, 14:58), como pidió el usuario ([D-054](DECISIONS.md#d-054)):
  - la release se titula «08/11/2026 · Prueba v39»;
  - el archivo se llama ahora `Aethelgard_Exp_2026-11-08_v39.apk`, con el mismo tamaño y el mismo `digest`;
  - el `README.md` (commit `d82abaa`) lleva la tabla de pruebas y el enlace a la original, `v0.1.0`, en el repositorio
    principal. El texto publicado es idéntico al local.
- **Evidencia de la descarga** (14:59): una petición de los 4 primeros bytes del archivo de GitHub devuelve `50 4b 03 04`,
  igual que la APK local.
- **Copia de la original** (08/11, 15:53), como pidió el usuario («Sí, cópiala»):
  - se descargó de la release `v0.1.0` del repositorio principal y su SHA-256 coincide con el `digest` de allí:
    `8d4f3107816f9b5a0dd5074e40bb3aafd230b391d2a46aef0c9f7b50a87cb67b`;
  - es la app estable: `com.aethelgard.juego`, versionCode 1 y versionName `0.1`;
  - ninguno de sus 1731 archivos es una pista de Suno;
  - en el repositorio de pruebas, la release se titula «05/11/2026 · Original v0.1.0», con el archivo
    `Aethelgard_2026-11-05_v0.1.0.apk` y el mismo `digest`;
  - va etiquetada sobre el primer commit (`8ece9e3`). `gh release list`, que ordena por fecha como GitHub, la muestra
    la última, debajo de la Prueba v39. «Latest» sigue en la Prueba v39;
  - el `README.md` (commit `d0eb7fa`) la añade al final de la tabla;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04`.
- **Sin ver:** la página web de releases. El orden se comprobó con `gh release list`.
- **Prueba v41** (08/11, 16:39), con la convención de [D-054](DECISIONS.md#d-054):
  - la fila del `README.md` va en el commit `4b929d9`, y la release `exp-20261108-3976565` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v41.apk` tiene 256 608 906 bytes, y su `digest` coincide con el SHA-256 local
    (`8f3f52ef…`);
  - `gh release list` da el orden v41 («Latest»), v39 y la original.
- **Prueba v44** (08/11, 17:17), con la misma convención:
  - la fila del `README.md` va en el commit `71931ae`;
  - la release `exp-20261108-21d2e21` contiene el archivo `Aethelgard_Exp_2026-11-08_v44.apk`, de 256 625 290 bytes;
  - su `digest` coincide con el SHA-256 local (`09b3c0f0…`);
  - el certificado es el mismo y los grupos de licencia, iguales a los de la v41; no lleva Suno;
  - el orden es v44 («Latest»), v41, v39 y la original;
  - el `README.md` ya separa la privacidad del repositorio de los permisos de los recursos.
- **Prueba v47** (08/11, hacia las 17:40), con la misma convención:
  - la release `exp-20261108-091d1d1` contiene el archivo `Aethelgard_Exp_2026-11-08_v47.apk`, de 256 629 386 bytes;
  - SHA-256 `988f9a8e…`; certificado y grupos de licencia, iguales a los de la v44; sin Suno.
- **Prueba v50** (08/11, 18:53), con la misma convención:
  - sale de `rebelum-alpha` @ `36502e9` (`e630b02` más los `.uid`), compilada dos veces: la segunda, con el árbol
    limpio («TODO CORRECTO»);
  - la fila del `README.md` va en el commit `6a6f27c`, y la release `exp-20261108-36502e9` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v50.apk` tiene 256 637 578 bytes, y su `digest` coincide con el SHA-256 local
    (`a374a858…`);
  - certificado `3413edcd…`, el mismo de siempre; sin Suno (sus canciones no están en el proyecto del encargo);
  - el repositorio sigue privado, con el dueño como único colaborador y sin invitaciones;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04` (HTTP 206);
  - el orden es v50 («Latest»), v47, v44, v41, v39 y la original.
- **Prueba v52** (08/11, 19:58), con la misma convención:
  - sale de `rebelum-alpha` @ `edf52cd` (`e6e52c4`, T-025, más los `.uid`), compilada dos veces: la segunda, con el
    árbol limpio («TODO CORRECTO»);
  - la fila del `README.md` va en el commit `2bac6a9`, y la release `exp-20261108-edf52cd` está etiquetada sobre él;
  - el archivo `Aethelgard_Exp_2026-11-08_v52.apk` tiene 256 649 999 bytes, y su `digest` coincide con el SHA-256 local
    (`2788ed92…`);
  - certificado `3413edcd…`, el mismo de siempre; los mismos grupos de licencia; sin Suno (el audio son los sonidos de
    Érebo, `musica_combate_normal` y los tecleos de Dialogic);
  - el repositorio sigue privado, con el dueño como único colaborador y sin invitaciones;
  - la petición de los 4 primeros bytes devuelve `50 4b 03 04` (HTTP 206);
  - el orden es v52 («Latest»), v50, v47, v44, v41, v39 y la original.
- **Pendiente de verificar:** la descarga completa y la instalación en el móvil, que hace el usuario.

### T-080
**Decidir la nivelación automática de quien se une al grupo**
- **Estado:** bloqueada: espera la decisión del usuario. **Prioridad:** baja.
- **Contexto:** en `e670a5d` puse que Lya y Garon llegaran al nivel del más alto al unirse. El usuario pidió
  comprobarlo, y esa regla no existía en el juego: se quitó el 08/11 por la noche y quien se une conserva sus datos
  ([D-060](DECISIONS.md#d-060)). Queda como propuesta: [D-062](DECISIONS.md#d-062).
- **Comprobado:** `prueba_grupos_combate` comprueba que unirse no cambia ningún dato y que los combates de dos y tres
  héroes se ganan con todos en el nivel 1.
- **Para cerrarla:** que el usuario decida si la quiere (y si también «llegar descansado»).
