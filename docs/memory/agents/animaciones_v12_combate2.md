# Animación de combate V12 (combate2): ataques sin deslizarse, impacto, reacciones y cámara

## 12/11/2026, noche · rama LOCAL `claude/v12-combate2` (`D:\Aethelgard_v12_combate2`), desde `d8a65d3`

Commits: `04a519f` (clips nuevos con Blender), `089a51a` (módulo, enganches, Ajustes y prueba), `2cb5340` (técnica de
Lya, defensa en la prueba, propuesta táctica), `ed0520d` (las esperas, en un nodo hijo del combate) y el de este
informe. Sin push ni merge.

**Todo APAGADO por defecto** (`combate_anim_v12.gd`, `ACTIVO_POR_DEFECTO = false`) y **solo con los héroes v2**.
Apagado, `combate.gd` sigue exactamente su camino de siempre: cada enganche pregunta `AnimV12.activo(f)` (interruptor
encendido y héroe v2 con su biblioteca de clips) y, si no, hace lo de antes. Comprobado: la huella del combate
(`prueba_combate_huella`, dos pasadas y la referencia) y 24 pruebas de combate siguen iguales con el interruptor apagado.

### Cómo se enciende
- Ajustes → «Combate: ● Animación de siempre / ○ Animación v12 (prueba)» y «Cámaras: sí / no» (`menus.gd`, tras
  «Protagonistas»; `user://ajustes.cfg`, `[combate] anim_v12` y `[combate] camaras`). Necesita también
  «Protagonistas: v2 (prueba)».
- Pruebas: `-- heroes_v2 combate_anim_v12` (y `sin_camaras`), o `Engine.set_meta("combate_anim_v12", true)` /
  `("camaras_combate", false)`.

### 1. La causa del deslizamiento (demostrada) y el arreglo en su origen
- **Causa** (medida con `prueba_combate_anim_v12.gd`: combate real de tres, semilla 7, el pie apoyado proyectado a la
  pantalla fotograma a fotograma): el combate movía el sprite de cada héroe con un `Tween` de 0,55 s con aceleración y
  frenada senoidales mientras el clip de correr iba a su ritmo fijo (el cuerpo, a 0 en los extremos y a 600-900 px/s en
  medio; el clip, siempre igual). El pie apoyado se corría en pantalla, en horizontal, **274 px por ataque (Kael), 142
  (Lya) y 169-355 (Garon)**. Además: (a) la carrera de captura de Garon, con la cadera quitada, **arrastra los pies
  ella misma** (en el clip, el pie «apoyado» avanzaba con el cuerpo); (b) el arco del salto de Kael empezaba a subir a
  0,20 s y el clip despega los pies a 0,27 s (subía con los pies en el suelo); (c) al pasar de correr a golpear, el
  fundido recolocaba los pies sobre el suelo en 2-3 fotogramas.
- **Arreglo** (`combate_anim_v12.gd`, `_correr`): el cuerpo avanza en pantalla lo que retrocede el pie apoyado en el
  clip (el clip avanza a mano en ese bucle, sin un fotograma de retraso; la velocidad del clip sube y baja con la del
  cuerpo); la carrera empieza en el instante del clip que hace falta para que la **llegada caiga en una fase de vuelo**
  (los dos pies en el aire, medidas en el propio clip), y la frenada (`c12_frenada`) o el salto empiezan en el aire: su
  primer apoyo es la llegada. Si el enemigo está cerca (< 150 px), Kael salta desde su sitio y Lya y Garon dan un
  saltito, sin carrera. Garon corre con una **carrera nueva hecha por IK** (`c12_carrera`: una clave por fotograma, el
  pie apoyado recto hacia atrás a velocidad fija, medida en Godot sobre el clip). El arco de Kael empieza al despegar.
  El desplazamiento vertical en pantalla (la «profundidad» del escenario 2D, que los pies del clip no hacen) va en una
  diagonal suave a la par que el horizontal (medido aparte).
- **Resultado** (horizontal, px por acción, apagado → encendido, mismo combate): **Kael 274 → 0, Lya 142 → 56,
  Garon 169 → 0** (cerca); con `magia=Fuego` (Garon ataca a uno lejano y en diagonal) **Garon 355 → 146**. Lo que queda
  de Lya es el fundido de entrada a la carrera (los 2-3 primeros fotogramas); lo de Garon lejos, su vuelo bajo (la
  medida lo cuenta como apoyo). Vertical (profundidad): Kael 57 → 8, Lya 21 → 27, Garon 279 → 0 (cerca) y 426 → 217.

### 2. Ataque normal (hito 1): preparación → ejecución → impacto → recuperación
- **Kael**: anticipación (`c12_arranque`: baja el peso, recoge el sable atrás) y carrerilla, o salto desde su sitio si
  está cerca; el salto con corte de siempre (clip v2 «ataque») con su arco; **impacto a 0,64 s del clip, como siempre**
  (llama a `_impacto_fuerte`: daño, sonido y temblor de siempre); pausa de impacto (0,085 s, Kael y el golpeado
  congelados), retroceso del golpeado (22 px y vuelta), tajo de luz con 9 chispas; recuperación del clip y **dos
  brincos hacia atrás sin dar la espalda** (`c12_salto_atras`, el cuerpo solo se mueve en el aire).
- **Lya**: `c12_arranque`, carrera, frenada en el aire, su golpe de cetro v2 (prepara y **golpea a los 0,28 s, el impacto
  0,1 s después, como siempre**), pausa, retroceso, se gira con pasos en el sitio (clip v2 «girar»), vuelve corriendo y
  frena.
- **Garon**: `c12_arranque` (o, en Juicio/Giro, la preparación de la técnica), carrera por IK o saltito, frenada,
  **Juicio (1,10 s) o Giro (0,90/1,50 s) de captura, sin cambiar sus instantes**, pausa fuerte (0,12 s en técnica),
  retroceso, vuelta.
- Comprobado (prueba, apagado y encendido): el clip y su instante en el fotograma en que baja la vida del enemigo son los
  mismos: Kael «ataque» 0,667 · 0,667; Lya «ataque» 0,503 · 0,503; Garon «juicio» 1,100 · 1,100 y «giro» 0,900 · 0,900;
  magia de Kael y Lya, igual. El sonido del golpe va en la misma llamada que el daño.

### 3. Magia y técnica por héroe (hito 2)
- **Kael, magia**: concentra con el sable vertical a un lado (`c12_magia_carga`, la cara libre) mientras el círculo y la
  luz se reúnen en la punta; estocada (clip v2 «magia_lanzar», lanza a 0,85 s), proyectil, impacto con onda del color
  del elemento y pausa breve en el golpeado. **Técnica**: Filo Arcano y Quiebra (dúos) cargan el sable sobre la cabeza
  (`c12_tecnica_carga`) con chispas de fuego o runa y cámara corta antes de lanzarse.
- **Lya, magia**: se concentra (clip v2 «magia_concentrar»), lanza (0,5 s). **Técnica**: con magia de nivel II o III,
  la **magia poderosa** (clip v2 que nadie usaba: concentra, alza el cetro, lo baja; sale a 1,5 s), círculo mayor y cámara.
- **Garon**: Juicio y Giro anunciados (`c12_tecnica_carga`: cruza las espadas ante el yelmo y las abre de golpe, con
  destello y onda) y **Embuir** (`c12_embuir`: pasa la mano por la hoja). Garon no usa magia (D-037).

### 4. Reacciones (hito 3)
- Golpe **ligero**: el `recibir_golpe` v2 de siempre. **Fuerte** (crítico, ≥ 22 % de su vida o un efecto potente):
  `c12_recibir_fuerte` (se dobla, medio paso atrás, se rehace). **Con Defender**: postura `c12_defensa` hasta su turno y
  `c12_bloqueo` en cada golpe (destello frío); la defensa sigue restando lo de siempre (comprobado: un golpe de 20 le
  quita la mitad). **Victoria**: cada uno a su tiempo (Kael, Lya +0,22 s, Garon +0,45 s) y la cámara se acerca un poco.
  Derrota: la de los héroes v2 (derribo y KO con su personalidad), sin cambios.
- **Aturdimiento**: en el sistema solo existe para enemigos (interrupción), no para héroes: no hay clip de héroe aturdido.

### 5. Cámara (hito 4)
- `camara()`: acerca la escena y el fondo (no la interfaz) hacia la acción, **≤ 10 %**, sin giros, ida 0,25-0,4 s,
  vuelta 0,35-0,5 s; en Juicio/Giro, dúos, magia de nivel II-III y victoria. **Nunca en combates de jefe** (Bramavidrio,
  Humbaba, Coloso, Guardián y cualquier «jefe»): su encuadre medido no cambia. Interruptor propio (Ajustes «Cámaras»).
  `_a_pantalla` usa la escala real de la escena (sin cámara es `TAM_ESCENA` exacto): los números siguen al luchador.

### 6. Efectos (hito 5) y presupuesto Android
- Tajo: un trazo de luz (el `_trazo_luz` de siempre: 3 `Line2D`) y 9 chispas (14 en técnica) con el `_particulas` de
  siempre (CPUParticles2D, textura y material aditivo ya existentes); onda del elemento al impactar la magia; brillo que
  se reúne en el arma (un `Sprite2D`). **Sin sombreadores nuevos** (por eso no hay nada que pasar por malioc).
- Retroceso y pausa de impacto: solo transformaciones y `speed_scale`.
- Clips nuevos en el APK: tres bibliotecas importadas de 76-106 KB (≈ 270 KB en total); sin mallas ni texturas.

### 7. Propuesta táctica (hito 6, solo documento)
`docs/v12/COMBATE_TACTICO_V12.md`: línea de turnos visible, «roto» tras interrumpir, Garon adelantado, Armonía por
variedad, contraataque al defender (la recomendada para probar primero), dúos con ventana de tiempo y afinidades en las
12 magias (decisión del usuario). Nada implementado.

### Pruebas (aisladas, `ejecutar_pruebas.ps1 -Lista`; «partida.save real: sin cambios · carpeta real: sin cambios»)
- **Apagado** (24 de combate + `prueba_audio`, `-Lista lista_apagado`): **24 SUPERADAS**, entre ellas
  `prueba_combate_huella` (la huella igual), `prueba_garon` (grupo 1), `prueba_grupos_combate` (1, 2 y 3), jefes
  (Guardián, Coloso, Bramavidrio, Humbaba, encuentro del desierto, clímax) y `prueba_heroes_v2`.
  `D:\REBELUM_diagnostico\pruebas\2026-11-12_202438\resumen.md`. (La 25.ª, la mía, falló por una comprobación mal
  aislada: corregida y superada después.)
- **Encendido** (las mismas 21 con `heroes_v2 combate_anim_v12` + la mía), última pasada tras `ed0520d`:
  **19 SUPERADAS · 3 FALLIDAS**, `D:\REBELUM_diagnostico\pruebas\2026-11-12_205656\resumen.md`. Las tres son pruebas de guion
  fijo que dependen del ORDEN de los turnos y del azar, no de las reglas (demostrado con sondas que imprimen cada turno,
  `_aislado\sonda\zarz.gd` y `m4.gd` de mi copia, fuera de Git):
  - `prueba_m4_c2` («la Guardiana no devuelve el golpe en guardia»): con la v12, en ese turno Grimfang **elige preparar
    el Hachazo** (tirada de su patrón) en lugar de atacar; sin golpe no hay réplica. Sin la v12, ataca.
  - `prueba_zarzalin_combate` («defendiendo, la embestida quita 19»): la embestida sale **crítica** (×1,6; la cota de
    la prueba no cuenta el crítico) y el combate acaba antes del turno de recuperación de Zarzalín.
  - `prueba_coloso` («no termina»): en la pasada anterior encendida la superó, y suelta la supera dos veces de dos
    encendida y dos de dos apagada: intermitente, con el PC cargado (otros 8-10 Godot de otras copias).
  Por qué cambia el orden: las acciones de los héroes duran distinto (Kael ~2,7 s frente a ~2,3; Lya ~3,0 frente a
  ~1,8), el ATB se sigue llenando mientras se anima y las tiradas caen en otros turnos. Comprobado aparte que las
  partículas no gastan el azar global [CORREGIDO el 13/11: sí lo gastan, una tirada al crearse; ver la segunda pasada] y que el módulo no usa `randf()`. **La defensa sigue restando la mitad** con la v12
  (mi prueba lo comprueba con un golpe real). Para dejarlas en verde encendidas habría que fijar el orden en esas
  pruebas (no son mías: no las he tocado).
  En la primera pasada encendida también falló `prueba_guardian_bosque` (cierre de Godot al salir: una variable estática
  con un `Tween`); arreglado en `2cb5340` y superada después. Y la medida de escenas se cerró una vez a mitad de un
  ataque de Lya: las esperas de funciones estáticas se reanudaban sobre nodos ya liberados; arreglado en `ed0520d`.
- `prueba_combate_anim_v12` (nueva, auto, al final de `lista_pruebas.txt`): **SUPERADA** también con `esgrima=Giro`,
  `magia=Fuego` y `embuir=Fuego`.

### Medidas (PC, `medir_escenas.ps1 -Escenas combate3,combate_brama -Ciclos 3`, perfil medio, héroes v2 en las dos)
Dos pasadas intercaladas, antes `-Extra heroes_v2` y después `-Extra heroes_v2,combate_anim_v12`:
`D:\REBELUM_diagnostico\v12\expansion\combate2\medidas\` (`tabla_pasada_1.md`, `tabla_pasada_2.md`, `procesos.txt` en
cada carpeta). **Medidas con OTROS especialistas trabajando** (6-10 Godot y un Blender de otras copias en `procesos.txt`):
el tiempo por fotograma y las cargas varían entre pasadas más que la diferencia (pasada 1: combate de tres, activo
5,84 → 6,23 ms de mediana y Bramavidrio 5,35 → 5,10; pasada 2: 5,50 → 6,83 y 6,35 → 9,01, con la segunda «después»
la más cargada). **Lo estable:** dibujos 96-102 → 103-105 en el combate de tres (el tajo y la cámara), los mismos en
Bramavidrio (89; allí no hay cámara); primitivas iguales; memoria estática +1-3 MB (las bibliotecas c12_*), vídeo igual;
sin nodos huérfanos al salir. **Hay que repetirla sin carga** (lo programa el coordinador) y en el Redmi.

### Evidencias: `D:\REBELUM_diagnostico\v12\expansion\combate2\`
- `videos\`: `ataque_normal_apagado_izq_v12_der.mp4`, `magia_fuego_…`, `tecnica_giro_…` (el MISMO combate, semilla 7,
  cámara del juego, 1280×720 por lado, a la izquierda apagado y a la derecha la v12; fotogramas de Godot cada 2,
  montados con ffmpeg a tiempo real; el lado v12 sigue con las reacciones, la defensa, Embuir, la magia poderosa, la
  cámara y la victoria escalonada de la prueba).
- `hojas\`: hojas de contacto de cada vídeo (apagado y encendido) y `blender_clips_tecnica_magia_defensa.png`.
- `fotogramas\<caso>\`: los PNG sueltos (apagado_NNNN, encendido_NNNN).
- `blender\<héroe>\`: hoja de contacto de cada clip c12_* (8 instantes, vista de la cámara de combate, con el arma).
- `medidas\`: arriba.

### Archivos
- NUEVOS: `aethelgard/combate_anim_v12.gd` (+ `.uid`), `aethelgard/fuente/clips_combate_v12.py`,
  `aethelgard/fuente/crear_clips_combate_v12.py`, `aethelgard/personajes/heroes_v2/{kael,lya,garon}/<héroe>_v2_combate_v12.glb`
  (+ `.glb.import` como `animation_library` y `.json`), `aethelgard/pruebas/prueba_combate_anim_v12.gd` (+ `.uid`),
  `docs/v12/COMBATE_TACTICO_V12.md` y este informe.
- COMPARTIDOS modificados: `aethelgard/combate.gd` (enganches de 2-4 líneas: `const AnimV12`, `_a_pantalla`,
  `_siguiente_turno` al quitar la defensa, `_embuir`, `_tecnica_garon` (pone y quita `c12_tecnica` solo encendido),
  `_defender`, al principio de `_anim_fisico_3d`, `_anim_salto_3d`, `_anim_ataque_3d` (Juicio y Giro) y `_anim_magia_3d`,
  `_golpe_visual` (herida) y la victoria en `_comprobar_fin`), `aethelgard/menus.gd` (bloque «Combate» en Ajustes, tras
  «Protagonistas») y `aethelgard/pruebas/lista_pruebas.txt` (una línea al final).
- No he tocado `grupo.gd`, `equipo_extra.gd`, `inventario.gd`, las fórmulas de daño, los GLB ni los scripts de los
  héroes v2 ni los originales.

### Límites (honesto)
- **Nada probado en el Redmi** (sin ADB por encargo); las medidas del PC no son FPS del móvil y se tomaron con carga.
- Las animaciones no las he VISTO en movimiento: las he revisado en hojas de fotogramas cada 2 (y medido los pies). El
  vídeo está montado para que lo mire el usuario.
- Pies: lo que queda (Lya ~56 px por ataque en el fundido de entrada; Garon en diagonal larga ~146 px) está medido; en
  diagonal el cuerpo se desplaza en vertical mientras un pie apoya (la profundidad del escenario 2D no la hace el clip).
- Con la v12 las acciones duran más (Kael ~0,4 s, Lya ~1,2 s): el ATB sigue corriendo durante ellas, así que el
  combate cambia de ritmo y las tiradas caen en otros turnos (las 3 pruebas de guion fijo de arriba). Si se aprueba,
  conviene acortar la vuelta de Lya o pausar el ATB durante las animaciones (decisión de diseño).
- Los clips c12_* se añaden a la biblioteca compartida del GLB v2 (como ya hace Garon con `garon_espadas.res`): tras un
  combate con la v12, siguen en esa biblioteca hasta cerrar el juego, sin usarse.
- Clips por poses (sin captura): el bloqueo de Lya y la defensa de Garon (una espada tapa la otra desde la cámara) son
  mejorables; la carga de técnica de Kael deja el sable algo tapado por la cabeza.
- Reacciones del enemigo: retroceso y pausa genéricos (no hay clip nuevo de enemigo). Aturdimiento de héroes: no existe.
- Sin sonido nuevo: la pausa de impacto va después de la llamada de siempre (daño y sonido en el mismo fotograma); no he
  escuchado nada.

### Pido (archivos de otros)
- Una fila en `docs/recursos.md`: «Clips de combate V12 de los héroes v2 (12/11, apagados): `personajes/heroes_v2/*/
  *_v2_combate_v12.glb` (solo esqueleto y animación, derivados de los modelos de Meshy de Kael, Lya y Garon —misma
  licencia y créditos pendientes que los originales—, clips obra del proyecto con Blender 5.2.3 por guion:
  `fuente/clips_combate_v12.py`)». No he usado Cascadeur ni nada de fuera.
- Si el coordinador quiere estas pruebas en verde también encendidas: fijar el orden en `prueba_m4_c2` (que Grimfang
  ataque en ese turno) y en `prueba_zarzalin_combate` (contar el crítico en la cota y no exigir la recuperación si el
  combate acaba antes). No las he tocado.

### Siguiente paso propuesto
1. Que el usuario mire los tres vídeos de `videos\` y, si le gusta, lo pruebe en el móvil con Ajustes →
   «Protagonistas: v2» y «Combate: animación v12».
2. Medir sin carga en el PC y en el Redmi un combate de tres (coordinador).
3. Pulido: contraataque al defender (propuesta E) con un `c12_contra`; reacción de enemigo con clip propio; acortar la
   vuelta de Lya; que Garon corra sin vuelo bajo (más zancada) para la diagonal larga.

## 13/11/2026, madrugada · segunda pasada (misma rama): poses, ATB al ritmo de siempre, vídeo completo

Commits: `cf43f98` (poses, ATB, chispas, vuelta de Lya), `335a1c8` (`fotos_combate_anim_v12`) y el de esta sección.

### 1. Tres poses pulidas (`fuente/clips_combate_v12.py`, GLB regenerados)
- **Bloqueo y defensa de Lya:** el cetro en alto hacia el enemigo, como un asta en guardia, con la cabeza del cetro
  delante y lejos de la cara; la izquierda sujeta el asta. Antes estaba horizontal a la altura del vientre y no paraba
  nada; en un intento intermedio la cabeza del cetro tapaba la barbilla.
- **Defensa y bloqueo de Garon:** la derecha alta y casi vertical, la izquierda más baja y tendida. Cruzan en X a
  distinta altura y desde la cámara se ven las dos; antes iban en la misma dirección y una tapaba a la otra.
- **Carga de técnica de Kael** (Filo Arcano y Quiebra): el sable alto, por encima de la cabeza y algo por fuera, de
  plano hacia la cámara (`filo` lateral). Antes estaba echado detrás de la cabeza y no se veía.
- Hoja antes/después: `D:\REBELUM_diagnostico\v12\expansion\combate2\hojas\poses_pulidas_antes_despues.png`. Las filas,
  de dos en dos (antes y después), son la carga de Kael, el bloqueo de Lya y la defensa de Garon; las hojas «antes»
  están en `blender\antes_pulido\`.

### 2. Ritmo: el ATB al ritmo de siempre (opción `pausa_atb`, encendida con la v12)
- **Qué hace:** mientras un héroe ejecuta su acción v12 (de la anticipación a la recuperación), las barras se llenan
  solo durante lo que duraba esa misma acción con la animación de siempre y luego esperan quietas. Si la acción v12
  dura menos, el héroe espera en guardia lo que falte.
  - Las duraciones de siempre (`DURACION_ANTES`) están medidas en el combate de verdad («DURACION apagado» de
    `prueba_combate_anim_v12`): ataque de Kael 71 fotogramas, de Lya 56, Juicio 102, Giro 91, magia de Kael 93 y de
    Lya 83.
- **Por qué así y no una pausa total:** con una pausa total los enemigos dejarían de cargar mientras actúa un héroe.
  Sería un regalo de tiempo para el grupo y cambiaría el equilibrio. Así, el orden de los turnos y lo que carga cada
  uno son los de siempre aunque la animación dure más.
- **Dónde se apaga:**
  - Ajustes → «ATB quieto al actuar: sí / no» (`[combate] pausa_atb`);
  - el argumento `sin_pausa_atb`;
  - `Engine.set_meta("pausa_atb_v12", false)`.
- **combate.gd:** una línea en `_process`. Solo mira la meta del combate, que con la v12 apagada no existe.
- **La causa que quedaba (demostrada con una sonda):**
  - Medí la huella del azar con `randi()` justo antes y justo después del ataque de Garon en `prueba_m4_c2`. Con la v12
    encendida se gastaba **una tirada de más** en ese ataque.
  - Cada `CPUParticles2D` que se crea toma su semilla del azar GLOBAL, y las chispas del tajo, de la magia y del dúo
    eran partículas de más.
  - Lo corrige el informe anterior, que decía que las partículas no gastaban el azar: la sonda de entonces creaba el
    nodo antes de fijar la semilla.
  - Ahora las chispas son sprites propios (≤ 14 por golpe, la misma textura y material aditivo) con su generador de
    semilla fija.
- **Resultado:** `prueba_m4_c2`, `prueba_zarzalin_combate` y `prueba_coloso` **pasan con la v12 encendida** (resultado de
  la batería, más abajo). Con la v12 apagada no cambia nada (huella igual).
- **Vuelta de Lya más corta:** se gira en 0,2 s, corre a 1,3 y quita las pausas largas. Su acción baja de unas 3,0 s
  a unas 2,9 s; casi todo el tiempo es la ida y la vuelta, y con el ATB al ritmo de siempre ya no cambia el combate.

### 3. Vídeo de un combate completo
- `D:\REBELUM_diagnostico\v12\expansion\combate2\videos\combate_completo_apagado_izq_v12_der.mp4`: 1920 px, a tiempo
  real, unos 99 s; a la izquierda apagado y a la derecha la v12.
  - Es el mismo combate de tres con semilla 7, PM infinitos y los enemigos ×3 de vida, con las mismas órdenes, que da
    `pruebas/fotos_combate_anim_v12.gd` (nueva, «ventana», añadida a `lista_pruebas.txt`).
  - Orden de las órdenes: Lya Fuego, Kael ataque, Garon Juicio, Lya Defender, Kael Fuego, Lya ataque, Garon Embuir y
    luego ataques. Lya cae cerca del final y ganan Kael y Garon.
- El orden de las órdenes es **idéntico en las dos pasadas** salvo la última: con la v12 cabe un ataque más de Garon
  antes del golpe final (19 órdenes frente a 18). Diferencia de un fotograma en el ATB acumulado al final; no la he
  perseguido.
- Hojas de contacto: `hojas\combate_completo_apagado.png` y `hojas\combate_completo_encendido.png`. Fotogramas JPG en
  `fotogramas\combate_completo\`.

### Pruebas (aisladas; «partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios»)
- **Apagado:** 24 pruebas de combate más `prueba_audio`: **25 SUPERADAS · 0 FALLIDAS**. Entre ellas, la huella del
  combate, 1, 2 y 3 héroes, jefes y `prueba_heroes_v2`. `D:\REBELUM_diagnostico\pruebas\2026-11-12_212659\resumen.md`.
- **Encendido** (las mismas con `heroes_v2 combate_anim_v12`, el ATB al ritmo de siempre por defecto, más
  `prueba_combate_anim_v12`): **22 SUPERADAS · 0 FALLIDAS**. Incluye `prueba_m4_c2`, `prueba_zarzalin_combate` y
  `prueba_coloso`. `D:\REBELUM_diagnostico\pruebas\2026-11-12_213205\resumen.md`.
- `prueba_combate_anim_v12` comprueba además que el ATB no avanza más allá de la duración de siempre durante una acción
  v12: en la pasada aislada, 43 fotogramas de acción por encima y 0 avances.
- `fotos_combate_anim_v12` (ventana): sin errores, con el combate terminado en las dos pasadas.

### Límites
- Sin Redmi. Las poses y el vídeo los he revisado en hojas de fotogramas, no en movimiento.
- Las duraciones de siempre son las del combate de tres medido. La magia de siempre dura algo distinto según la
  distancia del proyectil, así que con otro encuadre puede haber un fotograma de diferencia en el ATB y, de ahí, el
  último turno distinto del vídeo.
- Con «ATB quieto al actuar: no», las barras corren durante toda la acción, como en la primera entrega, y esas tres
  pruebas pueden volver a fallar por el orden.

### Archivos de esta pasada
- NUEVO: `aethelgard/pruebas/fotos_combate_anim_v12.gd` (+ `.uid`).
- Modificados: `aethelgard/combate_anim_v12.gd`, `aethelgard/fuente/clips_combate_v12.py`, los tres
  `<héroe>_v2_combate_v12.glb`, `aethelgard/pruebas/prueba_combate_anim_v12.gd`.
- COMPARTIDOS: `aethelgard/combate.gd` (una línea más en `_process`), `aethelgard/menus.gd` (segunda fila «ATB quieto
  al actuar»), `aethelgard/pruebas/lista_pruebas.txt` (la línea de `fotos_combate_anim_v12`).
