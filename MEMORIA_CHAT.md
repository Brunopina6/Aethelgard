# MEMORIA_CHAT: lo aprendido en las conversaciones sobre AETHELGARD / REBELUM

> **Actualizado el 2026-11-08 a las 15:55** (hora local, UTC+1), en la rama `rebelum-3d` @ `ce84422`. Se publica en la
> rama `memoria-desarrollo` de GitHub.
>
> Es un **resumen**, no una transcripción. El chat legible está en
> `D:\REBELUM_respaldos\2026-11-07_chat_exportado\` y el alcance de las fuentes, en el [§1](#1-fuentes-y-alcance).
>
> **Etiquetas**
> - **[usuario]:** lo pidió o lo decidió el usuario.
> - **[asistente]:** lo propuse yo.
> - **[comprobado]:** verificado en el código o ejecutando, con fecha.
> - **[historial]:** viene de la conversación y no se ha vuelto a comprobar.

## Resumen actualizado

- **El proyecto:**
  - REBELUM (nombre técnico Aethelgard) es un JRPG de fantasía en Godot 4.7.2 (Compatibility).
  - Android primero, en un Redmi con Mali-G57. Después, PC, iOS y Android TV.
  - El usuario es principiante, escribe en español y prepara muchas órdenes largas con ayuda de otro asistente
    (ChatGPT o Codex). Las órdenes pegadas son suyas, pero sus datos se contrastan.
- **El juego hoy:**
  - Mapa y zonas en 2D.
  - Combate ATB con personajes 3D, cada uno en su ventana.
  - La invocación de Érebo, Dialogic, el guardado, la tienda, la mazmorra y la isla flotante.
  - Pastos Verdes en 3D existe **solo como prototipo**. Detalle en [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).
- **La gran meta:** pasar la exploración a 3D poco a poco, región a región, empezando por Pastos Verdes, en una APK
  experimental separada. El plan aprobado es [docs/plan_migracion_3d.md](docs/plan_migracion_3d.md).
- **Hecho el 07/11:**
  - la Fase 2.0 (rama `rebelum-3d`);
  - la Fase 0 del encargo único (rama `rebelum-alpha` en `D:\Aethelgard_alpha`): dos pruebas corregidas y los PM
    infinitos solo con un argumento;
  - la APK «Prueba 3D», compilada.
- **Hecho el 07/11 por la tarde** (rama `rebelum-alpha`, commits locales):
  - Pastos Verdes 3D ya se juega desde el mapa de la app experimental: encuentros, combate con vuelta y salidas
    (T-021);
  - el inventario de licencias (T-070);
  - la APK experimental `Aethelgard_exp-20261107-03b960a.apk`, de prueba privada.
- **Hecho después** (`e212400`):
  - la misión del corte alfa, de PV-02 a PV-14, con Tilo, la estela y el centinela;
  - la APK `Aethelgard_exp-20261107-07ac036.apk`.
- **Medido en el Redmi el 08/11** (D-053): en el perfil bajo, la región va a **30 FPS sostenidos y sin tirones** con
  el tope de 30, a 20 m. Sin tope, la mediana es de 21,5 ms y el p95 de 38,4 ms. Las tablas están en
  [SESSION_HANDOFF.md](SESSION_HANDOFF.md).
- **APK en GitHub para el móvil (08/11, por la tarde):** el usuario, fuera de casa, pidió un sitio en GitHub para
  descargar las pruebas.
  - Se creó el repositorio privado `Brunopina6/Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)).
  - Lleva la APK `exp-20261108-aabe5ad`, que incluye el arreglo del banco ([T-079](TASKS.md#t-079)).
  - Después pidió ordenar las pruebas **por fecha y versión** y conservarlas todas, junto con la original (`v0.1.0`).
    El resto sigue como se configuró.
  - Ese mismo mensaje: «la música de suno no son libres». Una APK con esa música no se sube.
  - Con «Sí, cópiala», la original (`v0.1.0`) también está en el repositorio de pruebas, al final de la lista.
- **Siguiente:** T-022: Lya y Garon siguiendo a Kael (hay unos 12 ms de margen), el cofre y la cinemática del mirador.
- **Vigente:**
  - el Redmi está reservado;
  - la partida del PC se conserva tal cual;
  - ni push ni publicaciones, salvo dos:
    - la memoria en `memoria-desarrollo`, tras cada hito;
    - las APK de prueba en el repositorio privado `Aethelgard-pruebas`;
  - no se toca `main`, `desarollo` ni el bloque B;
  - las pruebas, siempre aisladas;
  - calidad visual primero.
- **Pendiente del usuario:**
  - licencias: el origen de las imágenes que subió a Meshy y el de los recursos sin registrar. La música de Suno ya
    se sabe que no es libre (08/11): falta decidir qué la sustituye en una APK entregable;
  - decisiones de narrativa, de Érebo (D1-D12), de las Skills y de GitHub.
- **Siguiente paso:** el de [SESSION_HANDOFF.md](SESSION_HANDOFF.md).

## Índice

1. [Fuentes y alcance](#1-fuentes-y-alcance): qué se conserva y qué se perdió.
2. [Glosario de fases](#glosario-de-fases): hay **tres** numeraciones de «fase», y el encargo vuelve a numerar
   los puntos 2.1 a 2.5.
3. [Visión y objetivos](#3-visión-y-objetivos)
4. [Peticiones del usuario y sus correcciones](#4-peticiones-del-usuario-y-sus-correcciones)
5. [Autorizaciones y restricciones: vigentes y sustituidas](#5-autorizaciones-y-restricciones-vigentes-y-sustituidas)
6. [Propuestas pendientes](#6-propuestas-pendientes): combate, magia, estados, personajes, talentos, enemigos,
   invocaciones y exploración.
7. [Música, efectos, modelos, animaciones, herramientas y licencias](#7-música-efectos-modelos-animaciones-herramientas-y-licencias)
8. [Diagnósticos, errores y soluciones](#8-diagnósticos-errores-y-soluciones)
9. [Trabajo terminado, en curso y pendiente](#9-trabajo-terminado-en-curso-y-pendiente)
10. [Rutas](#10-rutas)
11. [Detalles que el código no cuenta](#11-detalles-que-el-código-no-cuenta)
12. **Historial por días:**
    [docs/memory/historial_2026-10-30_a_2026-11-07.md](docs/memory/historial_2026-10-30_a_2026-11-07.md)

**Documentos relacionados:**
- normas: [CLAUDE.md](CLAUDE.md);
- decisiones: [DECISIONS.md](DECISIONS.md);
- tareas: [TASKS.md](TASKS.md);
- arquitectura: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).

## 1. Fuentes y alcance

**Registros locales de Claude Code.** Están completos, pero contienen datos sin revisar: no se comparten.

| Registro | Periodo | Contenido |
|---|---|---|
| `C:\Users\G513\.claude\projects\D--Aethelgard-aethelgard\01fe04af-8fa2-417a-a9ef-c72745be1c17.jsonl` (≈370 MB) | 31/10 a 07/11 | La conversación principal, esta |
| `…\D--Aethelgard-aethelgard\5c0f7486-8deb-4336-ac67-dfa3d7b1ec0f.jsonl` | Desde el 30/10 | Una sesión anterior breve (mapa y sprites) |
| `…\D--Aethelgard\ca2d0f19-2309-4bac-aaee-a1400f5e4fb7.jsonl` | 06/11, de 23:17 a 00:35 | Una sesión paralela: Cascadeur, Posador y, probablemente, el commit `d155a36` |

**Copia revisada** (la que pidió el usuario): `D:\REBELUM_respaldos\2026-11-07_chat_exportado\`.
- Es privada y se queda fuera de GitHub ([D-049](DECISIONS.md#d-049)).
- Contiene los mensajes del usuario, los textos de Claude, los informes de subagentes y los resúmenes.
- El número de serie del móvil y los correos están enmascarados.
- Explicación y sumas SHA-256 en su `LEEME.txt` y su `SHA256SUMS.txt`.

**Compactaciones.** La conversación principal se compactó 5 veces: 03/11 13:12, 05/11 11:09, 06/11 10:02, 07/11 01:56
y 07/11 15:45. Tras cada una, Claude solo conservaba un resumen. Esta memoria se ha reconstruido con el registro
completo, no solo con los resúmenes.

**Lo que no está o se perdió**
- **Las imágenes** que adjuntó el usuario: no están en la copia revisada. Las originales se quedaron en carpetas
  temporales de Claude y pueden haber desaparecido.
- **El 31/10, un reinicio del PC** («NO SE GUARDO SE REINICIO EL PC») hizo perder trabajo que se rehízo. No queda rastro
  de lo perdido.
- **La historia anterior al 05/11 no está en Git:** el primer commit (`fd71d6a`) lo mete todo junto. La evolución de
  esos días solo está en el chat; resumida en el [historial por días](docs/memory/historial_2026-10-30_a_2026-11-07.md).
- **Las conversaciones del usuario con otros asistentes** (ChatGPT o Codex) solo se conocen por lo que adjuntó:
  - el TXT de la conversación original;
  - el encargo único;
  - los `cambios_aethelgard*.md`;
  - los documentos base.
- **Los resúmenes de compactación** cuentan algunos tramos con poco detalle. Por ejemplo, la mañana del 05/11 (la
  integración de Érebo y del menú de Garon). Lo comprobable está en el código y en Git.

## Glosario de fases

Se han usado tres numeraciones distintas. Indica siempre a cuál te refieres.

| Numeración | Nombre | Cuándo | Qué fue |
|---|---|---|---|
| 1. «Orden maestra definitiva» | «Fase 1» de Pastos Verdes | 05/11 a 06/11 | La escena de prueba de Pastos Verdes con calidad JRPG, la optimización y el banco TOPE. Cerrada en `79a34c3` |
| 1. «Orden maestra definitiva» | «Fase 2» y «Fase 2.1» | 06/11 | Skills, guía visual y guardián de Meshy (`2d8fa6a`); después, árboles, REBELUM y el diagnóstico de rendimiento |
| 2. Departamentos y plan 3D | «Fase 1» de los departamentos | 07/11, de 01:14 a 03:00 | Auditorías de siete departamentos ([docs/fase1_resumen_departamentos.md](docs/fase1_resumen_departamentos.md)) |
| 2. Departamentos y plan 3D | Fases 2.0 a 2.8 del plan 3D | Desde el 07/11 | La hoja de ruta 3D ([docs/plan_migracion_3d.md](docs/plan_migracion_3d.md)). La 2.0 está terminada |
| 3. Encargo único | Fases 0 a 5 | 07/11, 15:15 | 0, línea base. 1, exploración 3D. 2, magia, estados, tablero e IA. 3, invocaciones y cinemáticas. 4, audio. 5, optimización |

**Cuidado:** el encargo vuelve a numerar sus puntos 2.1 a 2.5 **de otra manera** que el plan 3D.

| Punto | Plan 3D | Encargo único (Fase 1) |
|---|---|---|
| 2.1 | Cierre del perfil bajo (precalentado, mediciones en el Redmi) | Verificar y estabilizar Pastos Verdes 3D |
| 2.2 | Entrada y foco (DS4) | Variante 3D de la primera zona, conectada al recorrido normal |
| 2.3 | Base 3D: interruptor, contrato, `pos_3d` y lugar 10 | Límites, NPC, diálogos, interacción y encuentros |
| 2.4 | Escenario y personajes (Pastos Verdes en `zonas3d/`, seguidores y Tilo) | Zona → combate → regreso |
| 2.5 | Primera misión (corte PV-02 → PV-14) | Guardado y carga; repetir en otras zonas |
| 2.6 | Audio unificado | Es la Fase 4 del encargo |
| 2.7 | Invocación de Érebo | Parte de la Fase 3 del encargo |
| 2.8 | Validación de la alfa | Es la Fase 5 y los criterios de entrega |

[TASKS.md](TASKS.md) indica las dos numeraciones en cada tarea.

## 3. Visión y objetivos

- **Lo que quiere el usuario** [usuario]: «un JRPG de fantasía 2.5D/3D visualmente espectacular, con un mundo vivo e
  inmersivo», mejorado poco a poco y **conservando** lo que ya funciona.
- **Objetivo artístico:** «una fantasía luminosa y exuberante, con la belleza ambiental que nos gusta de Infinity Nikki,
  pero con identidad propia para REBELUM».
  - Cámara elevada e inclinada, según la imagen de referencia del 05/11.
  - Vegetación con viento, agua y fauna.
- **Referencias emocionales:** Final Fantasy IX, Final Fantasy VII y Clair Obscur: Expedition 33. No se copian sus
  argumentos, personajes ni escenas. De Final Fantasy X no se revelan detalles, porque el usuario no lo ha jugado.
- **Historia:**
  - Luminosa, divertida, sorprendente y emocional.
  - Temas: recuerdos perdidos, reinos desaparecidos, guerras antiguas, dioses y secretos, amistad, sacrificio, identidad
    y esperanza.
  - Una verdad que cambia lo que el jugador creía saber.
  - La base es la historia A+C ([D-030](DECISIONS.md#d-030)).
- **Técnica:**
  - Medir en el dispositivo y no prometer mejoras sin medirlas.
  - El perfil alto nunca se rebaja.
  - El Redmi es la referencia del perfil bajo.
- **Siguiente gran etapa:** Pastos Verdes como primera región 3D jugable, con encuentros, combate, inventario, menús,
  guardado, diálogos y una misión completa. Irá en una APK experimental que no pise la estable y que luego pueda ser
  beta.

## 4. Peticiones del usuario y sus correcciones

La lista completa de peticiones está en el [historial por días](docs/memory/historial_2026-10-30_a_2026-11-07.md).
Estas son las **correcciones**, que conviene no repetir:

| Fecha | Qué pasó | Lo que vale ahora |
|---|---|---|
| 02/11 | «El fogonazo es demasiado blanco» | Fuego con más color |
| 03/11 | En el móvil no se podían pasar los diálogos | Botón «Seguir» (`boton_dialogo.gd`) |
| 03/11 | «Los mapas son muy simplones» | Zonas grandes, decorado de Quaternius y texturas de Poly Haven |
| 04/11 | «Garon sale andando en batalla» | «Guardia viva» hecha con su animación Juicio |
| 04/11 | Quité a Grimfang por error, cuando el usuario quería quitar el «Goblin» 2D | Grimfang se queda; el orco 2D está en `retirado/` |
| 06/11 | Árboles de tarjeta («como una hoja de papel») y arces de Meshy («muy pobres») | Los paquetes como base visual ([D-025](DECISIONS.md#d-025)) |
| 06/11 | «¿No puedes clonar la potencia de mi móvil?» | No: hay que medir en el propio Redmi |
| 07/11 | 30 FPS en medio | El Redmi es la referencia del perfil bajo ([D-021](DECISIONS.md#d-021)) |
| 07/11 | Avisé de que el storyboard de Érebo revelaba el secreto en la primera invocación | Las etapas E0-E5 de la v3 revelan poco a poco |
| 07/11 | «¿Qué veré en el Redmi?»: la APK experimental arranca en 2D | Se compiló la APK «Prueba 3D» para ver Pastos Verdes ya |
| 07/11 | La partida del PC perdió la clave `grupo` | «No, déjala así» ([D-011](DECISIONS.md#d-011)) |
| 07/11 | Diagnostiqué mal que la carga de `zona.tscn` no terminaba | Lo deshice: era un fallo de la prueba (decisión 0.10 del registro del encargo) |

**Matices que importan**
- **Lo que el usuario no ha concedido:** «No lo interpretes como aprobado automáticamente» (el bloque B). Una
  aprobación vale para lo que dice y nada más.
- **Las instrucciones actuales prevalecen** sobre los encargos antiguos.
- **Contestaciones cortas:** el usuario suele responder con frases breves, como «Sí, commit y subir», «Ya está
  instalado» o «Inténtalo de nuevo». Las preguntas tienen que ser concretas y con opciones claras.

## 5. Autorizaciones y restricciones: vigentes y sustituidas

Las normas vigentes están en [CLAUDE.md](CLAUDE.md) y su historia, en [DECISIONS.md](DECISIONS.md).

| Autorización | Fecha | Estado |
|---|---|---|
| «Sí, commit y subir», cada vez para un commit concreto en `desarollo` | Del 05/11 al 06/11 | Usadas. Hoy cada push necesita un permiso expreso; ver D-002 |
| Streamline, Frame Advisor e instalaciones en el Redmi por ADB | 06/11 | **Sustituida** por el Redmi reservado ([D-013](DECISIONS.md#d-013)) |
| Commits 1, 3 y 5 en `desarollo` | 06/11, 13:12 | Hechos: `a240ae9`, `f06caec` y `eadf785` |
| Revisar, dividir y subir `d155a36` | 07/11, 01:08 | Hecho: `f5f3c4e` y `2d1adc4`; queda `respaldo-d155a36` |
| Fase 1 de los departamentos (solo auditoría) | 07/11, 01:14 | **Sustituida** por el encargo único ([D-044](DECISIONS.md#d-044)) |
| Redactar el plan 3D (A1-A4); no implementar | 07/11, 03:01 | Hecho |
| Fase 2.0 (commits locales solo en `rebelum-3d`); esperar antes de 2.1 y 2.2 | 07/11, 03:18 | Hecha. La espera la **sustituyó** el encargo ([D-045](DECISIONS.md#d-045)) |
| Compilar la APK «Prueba 3D» | 07/11, 03:51 | Hecho |
| Copiar la APK al Redmi («dónde lo pruebo») | 07/11, 04:00 | Hecho una vez. Hoy no: el Redmi está reservado |
| Encargo único de implementación | 07/11, 15:15 | En pausa de 15:40 a 16:30; **reanudado** ([D-046](DECISIONS.md#d-046)) |
| Solo documentación de memoria y continuidad | 07/11, 15:40 | Terminó a las 16:30 |
| Publicar la memoria en `memoria-desarrollo` | 07/11, 16:30 | **Vigente**, tras cada hito. El push solo vale para la memoria ([D-049](DECISIONS.md#d-049)) |
| Licencias: recursos autorizados o sustitutos; el entregable, sin lo no acreditado | 07/11, 16:30 | **Vigente** ([D-050](DECISIONS.md#d-050)) |
| «Haz una cosa cra en GitHub un lugar donde subir las pruebas y súbela allí…» | 08/11, hacia las 14:40 | **Vigente:** repositorio privado `Aethelgard-pruebas` ([D-054](DECISIONS.md#d-054)) |
| «a partir de ahora ordena las relese de pruebas por fecha y versión…» | 08/11, hacia las 14:55 | **Vigente:** convención de [D-054](DECISIONS.md#d-054); ninguna prueba se borra |
| «Sí, cópiala» (la APK original al repositorio de pruebas) | 08/11, hacia las 15:50 | Hecho: «05/11/2026 · Original v0.1.0» ([T-079](TASKS.md#t-079)) |

**Restricciones del usuario, con sus palabras**
- «La autorización de push se limita a la documentación de memoria» (07/11, 16:30).
  - Sustituye a «No hagas push ni publiques archivos», de la tarea de memoria.
  - El 08/11 se amplió con las APK de prueba en el repositorio privado ([D-054](DECISIONS.md#d-054)).
- «No incluyas secretos, claves, credenciales, contenido privado ni registros sin revisar en la documentación.»
- «El Redmi queda reservado para una validación posterior solicitada al usuario.»
- «No cambies todavía el nombre técnico del repositorio o de las carpetas de Aethelgard a REBELUM.»
- «No reduzcas la calidad del perfil alto para adaptarlo al Redmi.»
- «No instales herramientas, compres recursos, abras suscripciones ni subas archivos del proyecto a servicios externos
  sin autorización específica.»

## 6. Propuestas pendientes

Nada de esto está implementado. Las magias que existen no cambian ([D-048](DECISIONS.md#d-048)).

### Del encargo único [usuario, redactado con su otro asistente]

**Magias nuevas** (ideas que se pueden adaptar al lore)
- **Utilidad:**
  - Desatar Nudos: limpia estados.
  - Segundo Aliento: regenera.
  - Compás del Alba: acelera el ATB, con límite.
  - Peso del Ocaso: ralentiza.
  - Velo de Ámbar: mitiga la magia.
  - Muralla de Ceniza: amortigua el daño físico.
  - Lumbre de Retorno: reanima.
  - Última Brasa: una sola reanimación diferida.
- **Ofensivas:**
  - Quiebrasello: abre una defensa.
  - Marca del Eclipse: premia coordinar al grupo.
  - Cénit Quebrado: gran descarga de área, con preparación visible.
  - Caída del Firmamento: pulsos escalonados, con contrajuego.

**Estados**
- **Negativos:** veneno, quemadura, sangrado, frío y congelación, silencio, ceguera, sueño, aturdimiento, miedo,
  maldición y vulnerabilidad.
- **Positivos:** prisa, regeneración, barreras y protección.
- **Reglas:** de aplicación, inmunidad, acumulación y limpieza.
- **Contra el abuso:** límite a encadenar controles; los jefes tienen respuestas anunciadas.

**Tablero por héroe:** rutas cortas e IDs estables. Ni compras dobles ni saltarse requisitos. Reinicio seguro.

**Talentos de los héroes**
- **Kael:** ritmo, guardia y contraataque; acumula impulso para el «Corte del Umbral».
- **Lya:** teje marcas y las consume en el «Remate de Constelación».
- **Garon:** posturas y cobertura de aliados; «Juramento de Acero».

**IA de los enemigos**
- Intenciones y prioridades visibles, con enfriamientos.
- Ataques especiales con aviso:
  - la embestida de Grimfang, que se puede interrumpir;
  - la guardia agrietada del Guardián;
  - el golpe anunciado de Gorthor.

**Invocaciones nuevas** (ajustarlas al canon y sin adelantar revelaciones)
- **Nhal-Zareth, Rey de los Nombres Borrados.** Ligada al Sello; aplica «Olvido».
- **La Vigía de las Raíces.** De Oakhaven; un refugio temporal.
- **El Estandarte de los Ausentes.** De la Compañía del Águila; una ventana de contraataque.
- **La Mano del Último Juramento.** Del caballero del brazo dorado; devuelve una amenaza.
- **Antes, comprobar en el canon:** el Sello del crematorio, Oakhaven, la Compañía del Águila, el caballero del brazo
  dorado y la pista del niño.

### De los departamentos (Fase 1, 07/11) [asistente]

| Tema | Dónde está |
|---|---|
| Invocación de Érebo | [docs/erebo/](docs/erebo/): plan final y cinemática (≈11,8 s la completa y ≈5,6 s la corta; D1-D12) |
| Audio | [docs/audio/](docs/audio/): auditoría de efectos, 157 candidatos y música adaptativa |
| Android TV y DualShock 4 | [docs/entrada/android_tv_dualshock4_plan.md](docs/entrada/android_tv_dualshock4_plan.md) |
| Pre-releases automáticas | [docs/versiones/automatizacion_prereleases.md](docs/versiones/automatizacion_prereleases.md) |
| Skills | [docs/herramientas/propuesta_skills.md](docs/herramientas/propuesta_skills.md) |
| Perfiles gráficos | [docs/perfiles_graficos_propuesta.md](docs/perfiles_graficos_propuesta.md) |

### Narrativa y exploración [asistente; pendientes de aprobar]

- **Biblia v3** ([docs/biblia/rebelum_biblia_narrativa_v3.md](docs/biblia/rebelum_biblia_narrativa_v3.md)):
  - historia A+C;
  - etapas E0-E5 del orbe y la gema (§5);
  - guion de Pastos Verdes con Tilo, la Gruta del Velo, el centinela y el niño de la niebla (§6);
  - una matriz de 169 diálogos con sus condiciones (§7);
  - 12 preguntas (§8.2).
- **Ideas recuperadas del TXT** (§10): el Atlas de los Nombres (páginas coleccionables; la primera, un secreto de Pastos
  Verdes), el reino de Elaria, los dioses antiguos, la ciudad reflejada en el río, «la Isla Borrada» como contenido
  opcional y el joven con recuerdos ajenos. Quedan 16 decisiones (§10.7).
- **Pastos Verdes en 3D:** el contrato de región y el lugar 10 del mapa ([D-042](DECISIONS.md#d-042)).
- **Lugares con sentido:** ruinas con un secreto, un mirador y una aldea pequeña.

## 7. Música, efectos, modelos, animaciones, herramientas y licencias

**Música**
- **En el juego:** solo `musica_combate_normal.mp3`. Los temas de jefe no existen, así que suena el normal.
- **Las cuatro pistas de Suno** (`sunlit_paths`, `morning_waltz`, `promised_horizon` y `waltz_starlit_path`):
  - OGG Vorbis a 48 kHz, válidos;
  - ninguna sirve de bucle tal cual: terminan con una caída de 3 a 5 s;
  - están en `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Musica_Pastos_Verdes_Godot.zip`;
  - ese ZIP trae una «orden para Claude Code» (`claude/01_ORDEN_CLAUDE_CODE.md`), que se trató como información y no se
    ejecutó;
  - los dos repartos propuestos están en [D-043](DECISIONS.md#d-043).
- **«The Last Encounter»:** CC-BY-SA 3.0.

**Efectos de sonido**
- **En el juego:**
  - 7 `sonidos/erebo_*.wav` (susurros, sombra, extracción, pulso, tensión, fractura y resonancia), de origen sin
    registrar;
  - tic, confirmar y clac, sintetizados en el menú.
- **La biblioteca del usuario,** `D:\qtorrent\sound effect`: 10 533 archivos de 11 orígenes.
  - Sonniss GDC: uso comercial; no se puede redistribuir ni usar para entrenar IA.
  - TomMusic: sin regalías.
  - Pixel Combat: CC BY 4.0.
  - «500 Game Sound Effects»: CC0 declarada, sin verificar.
  - 12 WAV del GDC 2017 posiblemente truncados.
  - Los 157 candidatos están en `docs/audio/efectos_candidatos.csv`.

**Modelos**
- **De Meshy** (el plan del usuario está sin confirmar):
  - Kael (`kael.fbx`), Lya (`Meshy_AI_Anime_Girl_…fbx`), Garon (`garon.fbx`), Grimfang (`goblin.fbx`; Gorthor es el
    mismo, teñido) y Érebo (6 FBX);
  - armas, árboles y el guardián (reducido a 5 711 triángulos).
- **Quaternius MegaKit:** CC0; se usaron 68 de sus 116 modelos.
- **EmacE Stylized Grass:** no se puede redistribuir.
- **Texturas:** de Poly Haven, CC0.
- **«Free RPG Sprites»:** el slime y otros personajes 2D; licencia sin registrar.
- **Movimientos de Garon:** del pack de Patreon «Dual-Blade Combat Essentials». Permite uso comercial, pero no
  redistribuir el original.

**Animación**
- Gestos procedurales (`gestos_3d.gd`).
- La «guardia viva» de Garon.
- El complemento Posador (`addons/posador`): IK y grabación de poses para esqueletos de Mixamo.
- La solución para la mano de Érebo: colocarlo por la mano y ajustar con IK.
- Herramientas: Blender como principal y Cascadeur Free solo de apoyo ([D-026](DECISIONS.md#d-026)).

**Herramientas del PC:** las verificadas están en [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md#1-repositorio-y-entorno).

**Licencias:** en [T-070](TASKS.md#t-070) y [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt).
El inventario completo, con las condiciones oficiales de Meshy y Suno leídas el 07/11, está en
`D:\Aethelgard_alpha\docs\versiones\inventario_licencias.md`. En resumen:
- **Meshy:** CC BY 4.0 con el plan gratuito y propiedad del usuario con el de pago. Con créditos se puede distribuir.
- **Suno:** con el plan gratuito, solo uso personal; suscribirse después no da derechos retroactivos.
  - El 08/11 el usuario dijo «la música de suno no son libres» [usuario].
  - Las cuatro pistas solo van en pruebas privadas locales: ni en commits ni en APK que salgan del PC, tampoco en el
    repositorio de pruebas.

## 8. Diagnósticos, errores y soluciones

**Rendimiento en el Redmi** [historial, medido allí]. Detalle en
[docs/vegetacion_rendimiento.md](docs/vegetacion_rendimiento.md).
- El límite es la GPU.
- **Los mayores costes:**
  - las hojas con recorte de transparencia;
  - las mallas sin indexar;
  - el mapa de sombras;
  - el reflejo del cielo.
- **El sombreado más caro es el del terreno.**
- **Medidas que no se deben usar:**
  - el temporizador de la GPU Mali devuelve basura;
  - el `delta` de Godot está suavizado.
  - Hay que medir con `Time.get_ticks_usec()`.
- **Peculiaridades del renderizador Compatibility:**
  - las sombras aclaran la imagen (`EXPO_CON_SOMBRAS = 0.58`);
  - cada luz omni cuesta unos 7 ms en el Redmi;
  - en el móvil, el filtro de sombras es duro.

**La mano de Érebo no llega al pecho del enemigo**
- **Causa:**
  - posición fija a 0,95 m (`invocacion_erebo.gd:43`);
  - el brazo chibi solo alcanza entre 0,275 y 0,369 m;
  - no hay IK;
  - el pecho está mal calculado.
- **Solución medida:** colocarlo por la mano y ajustar con IK. El error baja a entre 0,000 y 0,022 m.

**Dos pruebas que fallaban** (el 07/11)
- **`prueba_menu_magia`:** usaba una API antigua del menú.
- **`prueba_escenas`:**
  - el prólogo bloqueaba;
  - contaba fotogramas cuando debía esperar en tiempo real. Sin ventana y con `--fixed-fps`, los fotogramas van más
    rápido que el reloj.
- Las dos se corrigieron. Mi diagnóstico intermedio sobre `recursos.gd` era falso y se deshizo.

**La partida del PC**
- Una sesión del editor que no había cargado la partida la sobrescribió con una parcial.
- La causa está en el código ([T-076](TASKS.md#t-076)).

**Errores de Godot ya resueltos** [historial]
- **Armas blancas:** las texturas de emisión salen blancas en Compatibility. Se usa `material_arma.gd`.
- **El cetro de Lya colgando de otros personajes:** los que heredan de `maga_3d.gd` necesitan `usa_vara = false`.
- **FBX:**
  - el error 567 al convertirlos se resolvió con el importador ufbx;
  - importarlos todos a la vez agotaba la memoria, así que se importan de uno en uno en miniproyectos.
- **El editor borra `java_sdk_path`** si está abierto mientras se cambian sus ajustes.
- **El tema no llegaba a los CanvasLayer:** se fusiona con el tema por defecto.

**Errores de herramientas ya resueltos**
- **PowerShell 5.1:**
  - un script con caracteres no ASCII necesita UTF-8 con BOM;
  - una función llamada `Git` tapa el comando `git`;
  - `.Trim()` se come el espacio inicial de `git status`.
- **adb desde Git Bash:** las rutas necesitan `MSYS_NO_PATHCONV=1`.
- **Xiaomi** bloquea `adb install`.

## 9. Trabajo terminado, en curso y pendiente

Todo, con su evidencia, en [TASKS.md](TASKS.md). En breve:
- **Terminado:**
  - T-001 y T-002: esta memoria, publicada en `memoria-desarrollo`;
  - T-010: la Fase 2.0;
  - T-011 y T-012: las dos APK compiladas;
  - T-020: la Fase 0 del encargo.
- **Terminado por la tarde:** T-021, Pastos Verdes 3D desde el mapa, en el PC. Falta probarlo en el Redmi.
- **Siguiente:** T-022.
- **Pendiente:**
  - la región completa, el perfil bajo, la entrada, el audio, la magia, las invocaciones y la optimización;
  - el riesgo de guardado (T-076).
- **Bloqueado por el usuario:** licencias, decisiones, el bloque B, el Redmi y la publicación de la memoria.

## 10. Rutas

| Qué | Ruta |
|---|---|
| Repositorio y proyecto | `D:\Aethelgard`; el proyecto de Godot está en `D:\Aethelgard\aethelgard` |
| Árbol del encargo | `D:\Aethelgard_alpha` (rama `rebelum-alpha`) |
| Godot de consola | `C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe` |
| Partida del PC (no tocar) | `%APPDATA%\Godot\app_userdata\Aethelgard\partida.save` |
| Compilaciones, registros y respaldos | `D:\REBELUM_compilaciones`, `D:\REBELUM_diagnostico` y `D:\REBELUM_respaldos` |
| Copia revisada del chat | `D:\REBELUM_respaldos\2026-11-07_chat_exportado\` |
| El encargo único | `C:\Users\G513\Documents\Codex\2026-11-07\referenced-chatgpt-conversation-this-is-an-2\outputs\Aethelgard_Encargo_Claude_Opus.txt` |
| La conversación original (TXT) | `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Conversacion_y_Biblia_del_Guion.txt` |
| Las pistas de Suno (ZIP) | `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Musica_Pastos_Verdes_Godot.zip` |
| La biblioteca de efectos | `D:\qtorrent\sound effect` |
| Los documentos base del usuario [historial] | `C:\Users\G513\Desktop\jueo personal\nuev acatu\Aethelgard_documento_base.pdf`, `C:\Users\G513\Desktop\Diseño de juego de Aethelgard.docx` y `cambios_aethelgard*.md` (en Descargas y en `C:\Users\G513\Desktop\jueo personal\act3\`) |
| La memoria automática de Claude | `C:\Users\G513\.claude\projects\D--Aethelgard\memory\` |

## 11. Detalles que el código no cuenta

- **Nombres y rutas:**
  - La rama se llama `desarollo`, con una sola r.
  - El nombre técnico (Aethelgard) no se cambia.
  - `user://` depende de `config/name`, así que en el PC todos los presets comparten la carpeta de datos.
- **Guardado y pruebas:**
  - `Progreso.guardar()` no guarda con `--script` ni con argumentos de usuario. Por eso las pruebas no tocan la partida
    y, en cambio, F6 desde el editor sí.
  - En el modo sin ventana con `--fixed-fps`, el tiempo de juego va más rápido que el real. Las cargas en segundo plano
    hay que esperarlas en tiempo real.
- **Peculiaridades de los modelos:**
  - Los personajes que heredan de `maga_3d.gd` llevan el cetro de Lya salvo que tengan `usa_vara = false`.
  - Convención de las armas: el puño en el origen, la hoja hacia +Y y longitud 1.
  - La ciudad flotante es un fondo pintado, prerrenderizado, con máscara de paso y pasada de profundidad.
  - La «guardia viva» de Garon existe porque su animación de reposo era una de andar (Thoughtful_Walk).
- **Herramientas y Git:**
  - El editor reescribe los `.import` al abrir el proyecto: esos cambios no son del usuario.
  - El token de `gh` del PC tiene permisos `repo` y `workflow`: puede hacerlo todo, así que hay que ir con cuidado.
  - `.agents/skills/` es una copia de las Skills para otro agente, sin seguimiento. No se toca.
  - Las órdenes largas que pega el usuario suelen venir de otro asistente. Sus datos («diagnóstico aportado») se
    contrastan con el repositorio.
