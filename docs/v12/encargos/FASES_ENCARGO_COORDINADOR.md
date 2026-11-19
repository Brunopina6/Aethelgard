# Fases del encargo coordinador (13/11) — documento de tareas vivo

- **Encargo literal:** `ENCARGO_COORDINADOR_13_11.md`, en esta carpeta.
- **Directiva de continuidad:** `DIRECTIVA_CONTINUIDAD_14_11.md`.
- **Al terminar cada fase:** marcarla aquí, apuntar las decisiones y los especialistas, pasar sus pruebas, hacer
  commit y resumirla en el RELEVO de `docs/v12/RETOMAR.md`.
- **Después de una compactación:** retomar desde la primera fase sin «HECHA».

**Límites que se aplican a todas las fases** (los literales están en el encargo):
- nada de fusiones con `main` ni `desarollo`, push forzado ni releases;
- no tocar las partidas reales;
- no borrar nada;
- trabajar sobre copias de los FBX y los ZIP.

**GitHub:** solo se sube la fase 3A, el orbe comprobado. El resto se queda en commits locales.
- **Al día el 19/11:** el orbe se subió el 14/11 (`a4db536` en `origin/claude/rebelum-v12`, que no se toca). Desde el
  18/11, con la autorización del usuario, lo VALIDADO se sube por avance normal, sin forzar, a la rama nueva
  `claude/rebelum-v12-validado-20261118` (`3ff3c7b`, `9d1baef`, `0970c02`, `5ace0bd` y la tanda 3; `RETOMAR.md`,
  relevos del 18 y 19/11). `main` y `desarollo` siguen sin tocar.

| Fase | Contenido (sección del encargo) | Verificación | Estado |
|---|---|---|---|
| 1 | Inspección y protección: etiqueta, ZIP extraídos, PDF leídos, Silver Sentinel identificado | `D:\REBELUM_entrada_13_11\INSPECCION_PASO1.md` | **HECHA** (14/11, `36fee13`) |
| 2 | Desbloqueos que impidan desarrollar o probar | Batería en verde en el PC | **HECHA**: no hay ninguno. Validado `ed59483`; coordinación y `proteger.sh` activos |
| 3A | Orbe nativo de Érebo (sección 4): opción de Auditoría APAGADA, sincronizada con el agarre del orbe y con limpieza | Prueba nueva, batería completa, capturas activado/desactivado | **HECHA** (14/11): commit local `5c045b7`; batería 160 · 0; `docs/v12/EREBO_ORBE_V12.md`. ~~**SIN SUBIR**~~ (14/11, ya superado), por la decisión de GitHub (ver «Decisiones»); la rama `claude/v12-orbe-solo` @ `a4db536` (solo el orbe sobre `ed59483`) está lista para subirse. **19/11:** subido el 14/11 como `a4db536` (ver arriba). Redmi: invocación entera con el orbe experimental y el modo «Vídeo» en `REDMI_18_11`; el instante del agarre, sin ver. Encenderlo es PD-23 |
| 3B | Solo Lya invoca: quitar la Invocación a Kael y migrar sin perder progreso | Prueba de menús y migración | **HECHA** (14/11, `b451518`): la orden solo existe para Lya y la ejecución comprueba el actor. Las partidas no guardan la invocación por héroe, así que no hay nada que migrar. `prueba_solo_lya_invoca`; batería 160 + 1 corregida |
| 3C | Mejorar UNA magia representativa | Capturas y prueba | **HECHA en el PC** (14/11): Agua, Torrente y Maremoto (`vfx/agua_v12.gd`), APAGADA, opción «Magia Agua v12» de Auditoría. Mismo daño, mismo fotograma de golpe y misma tirada del azar. +17 a +30 llamadas de dibujo. `docs/v12/MAGIA_AGUA_V12.md`. **Falta el Redmi.** No se amplía el lote hasta que la apruebe el usuario. **19/11:** sigue sin verse en el teléfono (el 14/11, con la v717, «no se llegó a probar», `RETOMAR.md:673`); es BR-6 |
| 4 | Menús y permisos de los héroes y catálogo de habilidades; recursos Eclipse, Compás e Inscripciones (máximo 3) | Pruebas de combate | **BLOQUEADA en parte.** Los 24 ataques rúnicos de Kael, las 18 técnicas, las 18 magias, las 6 invocaciones y las 24 magias negras vienen de `CATALOGO_GENERAL_PROPUESTO.json` y de los PDF de Kael y del arsenal, que **no se han entregado**. Además, Kael no tiene ataques rúnicos: sus «artes» (Alba y Escarcha) son magia de apoyo. Quitarle la Magia hoy lo dejaría con solo Atacar, así que se conserva el comportamiento vigente y se registra para el usuario. Hecho: solo Lya invoca (3B) |
| 5 | Piloto de Nix desde su FBX: reducir la malla (LOD0 de 7-10 mil triángulos), rig con mechones, vestuario canónico | Blender, reimportación en Godot y capturas | **HECHA en el PC** (14/11, dos pasadas de especialista; integrada APAGADA, opciones «Nix (cuarta heroína)» y «Nix: modelo FBX» en Auditoría). **Cuerpo:** 11.968 triángulos; esqueleto de Lya con 54 huesos (mechones, faldones, capa y capucha). **Vestuario canónico** (`c0b199a`): capucha con forro púrpura y pelo recogido, capa, faldones, medias asimétricas, botas, emblema y cetro propio. 19.481 + 612 triángulos. 23 clips (`canalizar` abre los faldones). Brillo corregido. Arreglada la carga del modelo en combate real. `prueba_nix_fbx` 60/60. **Faltan:** la emisión de iris y ornamentos, el ajuste del encuadre `nix3d` y el Redmi. Es una figura adulta frente a la Nix *chibi* actual (decisión de arte para el usuario). `docs/v12/NIX_PILOTO_FBX.md`. **Del 14 al 19/11, en el PC:** cara y cetro (`bd858f8`), emisión suave del iris (`89269b7`), mano del cetro con pesos (15/11), emisión de los ornamentos en 3 intensidades, APAGADA (`bbe3d96`, `0777cad`; `prueba_nix_emision`), derrota medida sin nada bajo el suelo (C-5); `prueba_nix_fbx` 90 OK. **Visto en el Redmi** en combate (`REDMI_15_11`: cetro en la mano, 62,4 FPS; `REDMI_18_11`: canaliza, 58 FPS); la emisión, la exploración y la derrota, sin ver. Quedan el socket `arma_d`, el encuadre `nix3d` y las texturas de 2048 (PC-20) y las decisiones de PC-4, PD-18 y PD-19 |
| 6 | Capa de Garon como pieza independiente con huesos propios; se conserva la original | Capturas en movimiento | **HECHA en el PC** (14/11, especialista; integrada APAGADA, opción «Capa de Garon articulada» en Auditoría): `capa_garon.gd` con 21 huesos; anclaje con < 1 mm de variación (antes 0,15-0,34 m); se mueve abajo al correr y girar; original, v2 y v3; `prueba_capa_garon`. La capa rígida de siempre sigue por defecto. **Falta el Redmi.** Hallado aparte: en v2 y v3, `AvanzarDoble` descoloca la cadera (clips del esqueleto original) y la derrota los hunde en el suelo. `docs/v12/CAPA_GARON_V12.md`. **Del 14 al 19/11:** `AvanzarDoble` de v2 y v3 arreglado (`80ac41a`); la capa tras un giro instantáneo (`f47964c`) y la media vuelta desde parado (`61a62a8`), con `prueba_capa_garon_estados`. **Sin informe `REDMI_*`** (el 14/11, v717, «ondea detrás al atacar», solo en `RETOMAR.md:668`); su coste, sin medir. Encenderla es PD-21; la derrota de los v2/v3, decisión del usuario |
| 7 | Primera experiencia jugable: misiones de Oakhaven, caravana, secundaria nueva, secreto, cerradura rúnica, gremio 13 frente a 15 | Pruebas de misión | **HECHA en el PC** (14/11, especialista; integrada). **Gremio:** el bloqueo existía (13 puntos alcanzables frente a 15); Oro pasa a 13 y las partidas atascadas cargan en Oro. **Diario:** objetivos cumplidos, paso actual y pistas vistas, sin revelar los siguientes; contratos del gremio. **Caravana:** faltaba `datos/encargos_desierto.gd` y el Diario no la recordaba (corregido). **Cerradura rúnica:** el arcón del Concejo, ACTIVO, en 2D y 3D, con premio único. **«Las tres marcas del cantero»** (secundaria con secreto y segunda cerradura): PROPUESTA APAGADA (`oakhaven_propuestas_v12`). Pruebas nuevas ×6, con contrapruebas. `docs/v12/OAKHAVEN_JUGABLE_V12.md`. Falta el Redmi. **Del 14 al 19/11:** el cantero completo como PROPUESTA apagada (`0f460ab`, `CANTERO_V12.md`), con la losa primero y el Diario corregidos (`d9dc733`, `178c9cd`, `ee6a02e`); el Hierro de la Falla en partidas antiguas (`3596779`). **Visto en el Redmi:** solo Oakhaven de noche, sin atascos (`REDMI_15_11`); la cerradura con el dedo y el cantero, sin ver (BR-7) |
| 8 | Oficios, armas especiales y minijuegos (primero la cerradura) | Pruebas | **EN PARTE** (19/11). Hecho: la cerradura rúnica (fase 7), los talleres más claros (`a5a519e`) y la receta que se valida antes de gastar (`629c75f`). Faltan los talleres de Kael y Garon y la evolución de un arma especial (AM-7) y los minijuegos 2-5, sin código (PC-1) |
| 9 | Enemigos y arsenal: piloto `meshy_e01` Custodio (idle, walk, Prensa del Umbral), después e02-e04 y los comunes; 32 conjuntos | Prueba de ataques y GLB reimportado | **PILOTO HECHO en el PC** (14/11, especialista; integrado APAGADO en `ab814f6`). `meshy_e01`: rig de 24 huesos; clips idle, walk y attack_prensa; Prensa del Umbral en el combate real (daño una vez por objetivo, limpieza al morir); solo en los grupos 28 y 29. **Faltan:** 9 clips, a2/a3, sonido, afinidades (fila neutra) y el Redmi. e02-e04, los comunes y los 32 conjuntos: pendientes (los conjuntos, BLOQUEADOS: falta el PDF del arsenal). `docs/v12/CUSTODIO_E01_V12.md`. **Del 14 al 19/11, en el PC:** Avance del Portón, golpe y derrota (`1beaf1e`), Sello de Clausura y rotación de los tres especiales (`0c49b87`, §9), contador «Sello en N turnos suyos» (§10), los 5 clips que faltaban, ya 12 de 12 (`1e776f6`, §11), y sonido propio y «llave iluminada», APAGADOS (`93f9fa7`, `2c28607`, §12). Del bestiario de T-097, Velaria (`33e4203`, `50f6487`) y el Cencerrante (`9fe7565`) en el combate, APAGADOS. **Visto en el Redmi:** la rotación y el contador hasta «Sello en 2» (`REDMI_15_11`) y la victoria (`REDMI_18_11`); el Sello lanzado, los clips nuevos, el sonido y la llave, sin ver. Siguen pendientes e02-e04 y los comunes (PC-3), las tres bestias de PC-17 y las cifras (PD-25) |
| 10 | Historias personales y mundo vivo | Pruebas | pendiente (19/11): las historias personales y «Los Ecos de los Olvidados» sin empezar (PC-2, riesgo de canon); las conversaciones que recuerdan decisiones, a medias (AM-8). Mundo vivo hecho fuera de esta fase: el barrio con rutinas y su misión (BR-3) |
| 11 | Gráficos y rendimiento (matas recortadas apagadas, mipmaps experimentales) | Medida en el PC; el Redmi, solo con autorización | continua. **Del 14 al 19/11:** rendimiento de Érebo sin cambiar la imagen (`84a39fe`), perfil bajo de la ciudad (`d09a6c7`, `c581109`, `70b5f82`), «material is null» de los v3 (`MATERIAL_NULL_17_11.md`; **0 errores en `REDMI_18_11`**), memoria entre escenas sin fuga en el PC (`MEMORIA_ESCENAS_17_11.md`; en el Redmi, 1 045 MB tras muchas escenas, `REDMI_18_11`: PD-5) y Ajustes sin repintar (`5ace0bd`, `77fb9c4`; sin medir en el teléfono). Las matas recortadas, descartadas para el móvil (v694, `INFORME_REDMI_V12.md`); los mipmaps, PD-30 |
| 12 | APK de Auditoría SIN instalar y guion de pruebas para el Redmi (v2 y v3 de pie; NPC de Oakhaven) | SHA-256 y guion | **HECHA y repetida** (19/11). APK y guion por hito: `720d193` con `GUION_REDMI_14_11.md`; `c04d07b`, `cbc0536` y siguientes con `GUION_REDMI_15_11.md`; `65e6f58` con `GUION_REDMI_18_11.md`; `9d1baef` (v1026, SHA `6bdf79a8…6738db60`) con `GUION_REDMI_19_11.md`, en el PC y SIN instalar. Las instaló el usuario desde Descargas y se probaron: v717 (14/11, `RETOMAR.md:652`), v801, v834, v843 y v849 (`REDMI_15_11`), v975 (`REDMI_16_11`) y v1022 (`REDMI_18_11`). Los v2 y v3 de pie, vistos en la v694 (`INFORME_REDMI_V12.md` §2); los NPC de Oakhaven, de noche (`REDMI_15_11`) |
| 13 | Matriz por elemento y entrega con continuidad | Documento | **HECHA** (19/11, DOCUMENTOS_19_11): `MATRIZ_ELEMENTOS_V12.md` al día con la columna «Visto en el Redmi» separada de la del PC; la continuidad, en `RETOMAR.md` («RELEVO 19/11») y `PENDIENTES_GENERALES.md` (139 trabajos con su Id). Se pone al día con cada tanda |

## Especialistas activos

Lanzados el 14/11 hacia las 01:40, como subagentes de la sesión coordinadora:

| Especialista | Carpeta | Rama (local) | Archivos que toca | Fase |
|---|---|---|---|---|
| Nix (piloto desde el FBX) | `D:\Aethelgard_v12_nix_piloto` y `D:\REBELUM_entrada_13_11\nix_trabajo\` | `claude/v12-nix-piloto` (desde `710fdae`) | modelo, rig y escena de Nix; `docs/v12/NIX_PILOTO_FBX.md` | 5 |
| Capa de Garon | `D:\Aethelgard_v12_capa_garon` y `D:\REBELUM_diagnostico\v12\capa_garon\` | `claude/v12-capa-garon` (desde `710fdae`) | `garon_3d.gd`, `garon_v2_3d.gd`, sus pruebas y `docs/v12/CAPA_GARON_V12.md` | 6 |

| Agua (fase 3C) | `D:\Aethelgard_v12_magia_agua` | `claude/v12-magia-agua` (desde `aa7f55f`) | `vfx/agua_v12.gd`, ganchos en `combate.gd` y `menus.gd`, `docs/v12/MAGIA_AGUA_V12.md` | 3C |

**14/11, hacia las 02:50:** los TRES han TERMINADO y están integrados en la copia principal, copiando archivos.
- Las ramas se conservan: Nix `91426c8`, capa `2966d29`, Agua `3b46bb0`.
- Esos tres ya no están activos.

**14/11, hacia las 04:50:** los TRES de abajo han TERMINADO y están integrados en la principal:
- Custodio en `ab814f6`;
- Oakhaven en `9c6b3eb`;
- vestuario de Nix en `c0b199a`.

**No queda ningún especialista activo.** Las ramas se conservan.

**14/11, hacia las 02:55** (desde `b451518`):

| Especialista | Carpeta | Rama (local) | Archivos que toca | Fase |
|---|---|---|---|---|
| Custodio de Porcelana `meshy_e01` (piloto: rig, idle, walk, Prensa del Umbral; APAGADO) | `D:\Aethelgard_v12_custodio`, `D:\REBELUM_diagnostico\v12\custodio\` y `D:\REBELUM_entrada_13_11\custodio_trabajo\` | `claude/v12-custodio` | enemigo nuevo, registro en el combate, `docs/v12/CUSTODIO_E01_V12.md` | 9 |
| Experiencia jugable de Oakhaven (gremio 13 frente a 15, Diario, caravana, cerradura rúnica y, si da tiempo, secundaria y secreto) | `D:\Aethelgard_v12_oakhaven_jugable` | `claude/v12-oakhaven-jugable` | misiones, `diario.gd`, cerradura nueva, `docs/v12/OAKHAVEN_JUGABLE_V12.md` | 7 |
| Vestuario canónico de Nix (capucha, pelo recogido, capa, faldones, medias, emblema y cetro; brillo) — lanzado hacia las 03:40 desde `80ac41a` | `D:\Aethelgard_v12_nix_vestuario` y `D:\REBELUM_diagnostico\v12\expansion\nix\vestuario\` | `claude/v12-nix-vestuario` | `personajes/nix/fbx/*`, `prueba_nix_fbx`, `docs/v12/NIX_PILOTO_FBX.md` | 5 |

**14/11, 03:35:** arreglado en la principal el `AvanzarDoble` de Garon v2 y v3 (`80ac41a`; no está en la APK
`e318629`).

La copia principal `D:\Aethelgard_v12` la usa solo el coordinador. Las ramas de los especialistas se integran
copiando archivos, nunca con fusiones.

**Si la sesión se corta:** mira en cada carpeta `git log claude/rebelum-v12..<rama>` y `git status`, y retoma o
integra lo que esté probado.

## Decisiones registradas

- **14/11, para el usuario (fase 7):**
  - **Gremio:** Oro a 13 obliga a hacer todos los contratos anteriores. Alternativas: un contrato de Plata más, u Oro
    a 12.
  - **El arcón del Concejo** (sitio, inscripción y premio) está ACTIVO porque es juego y no historia. Se quita
    retirando la pieza.
  - **«Las tres marcas del cantero»**, apagada, necesita aprobación: interruptor `ACTIVO_POR_DEFECTO`, más una
    línea en `menus.gd`.
- **14/11, revisión adversarial del código de la noche:** 4 defectos confirmados, ninguno con las opciones apagadas.
  Corregidos en `af89e5f`:
  - Garon v2 corría hacia delante mientras retrocedía;
  - las gotas del Agua se cortaban y el orbe salía teñido;
  - el Custodio decía «En guardia» dos veces.

- **14/11, instrucciones complementarias** (`INSTRUCCIONES_COMPLEMENTARIAS_14_11.md`; prevalecen sobre el prompt de
  expansión):
  - **Pelo de Nix:** «gris RECOGIDO». Se suma al canon de la capucha, el mechón superior y los dos delanteros.
  - **Medias de Nix:** con motivos dorados asimétricos (ramas u hojas en una, geométricos en la otra).
  - **Garon:** sus armas dobles forman un par con un único bloque de estadísticas y pasivas.
  - **Paquete:** «90 habilidades» = 24 + 18 + 18 + 6 + 24.
  - **Orden:** las complementarias ponen Nix y la capa (4) antes que los permisos (5). El coordinador los pone al
    revés y pide ajustar solo por dependencias reales.
    - Se sigue el orden del coordinador para 3B (solo Lya invoca), que forma parte de la sección del orbe.
    - Las fases 4 a 6 se pueden reordenar si hay una dependencia.
- **14/11, subida a GitHub:** el remoto está en `ed59483` y en local hay 3 commits solo de documentación (`b9d094a`,
  `36fee13`, `710fdae`) antes del orbe.
  - Un push normal subiría también esos tres, y la autorización cubre ÚNICAMENTE el orbe.
  - Subir solo el orbe exigiría reordenar la historia local, que equivale a un rebase prohibido.
  - **Decisión registrada para el usuario:** subir los 4 commits juntos (los 3 solo tocan documentación), o
    autorizar que se reordene la historia local. Mientras tanto, el orbe queda en commit local.
  - **Alternativa preparada sin publicar nada:** la rama local `claude/v12-orbe-solo` @ `a4db536` contiene `ed59483`
    más solo los 8 archivos del orbe, idénticos a los probados en `5c045b7`.
    - Se sube con `git push origin claude/v12-orbe-solo:claude/rebelum-v12`, un avance normal sin forzar.
    - Después, la rama local tendría que rehacer sus commits de documentación encima de esa base, y eso requiere
      la autorización del usuario.

- **14/11, Nix:** el canon vigente (capucha, pelo gris ceniza con dos mechones, emblema del Ojo de Horus) manda
  sobre el diseño anterior del PDF (sombrero, pelo ciruela).
  - Del PDF se conservan las mecánicas y los presupuestos.
  - El Silver Sentinel es su cuerpo base.
