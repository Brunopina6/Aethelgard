# Matriz por elemento — encargo coordinador (estado del 19/11, 14:00)

- **Antes:** estado del 14/11 a las 05:00 (`6da1c74`; la fila del Custodio, en `0c49b87`). Esta versión recoge lo hecho
  del 14 al 19/11 (relevos de `RETOMAR.md` del 14/11 por la mañana al «RELEVO 19/11, 11:50», las tandas 1, 2 y 3 de
  `PENDIENTES_GENERALES.md` y `git log`) y la columna del Redmi con `REDMI_15_11.md`, `REDMI_16_11.md` y `REDMI_18_11.md`.
- **Base en el PC:** tanda 3 VALIDADA con la batería completa **211 · 0 · 117 · 0** (`2026-11-19_111045`, etiqueta
  `validado/v12/20261119-114555`, en GitHub en `claude/rebelum-v12-validado-20261118`). Encima, sin batería completa
  (solo las pruebas de su zona): `208ea8b` y `1ee5644` (salir a mitad de la híbrida y de los ataques v12 ya no da
  0xC0000005, `HIBRIDA_SALIDA_19_11.md`) y `77fb9c4` (pestañas de Ajustes y ficha del Grupo sin repintar).
- **APK más reciente probada en el Redmi:** la del validado `3ff3c7b` (v1022, 18/11). La de `9d1baef` (v1026) está en el
  PC, sin instalar (`GUION_REDMI_19_11.md`). **Nada de las tandas 1, 2 y 3 del 19/11 está visto en Android.**

**Estados:**
- **V** = verificado. En las columnas del PC, con prueba automática de la batería (o la prueba que se nombra);
- **P** = parcial;
- **—** = pendiente o no aplica;
- **B** = bloqueado.

**Las dos últimas columnas no se mezclan:**
- **PC (batería):** validado en el PC con las pruebas que se nombran. Una medida del PC nunca se cuenta como Android.
- **Visto en el Redmi:** solo lo que dice un informe del Redmi (`REDMI_15_11`, `REDMI_16_11`, `REDMI_18_11`, o
  `INFORME_REDMI_V12.md` para el 13/11). Lo del 14/11 (v717) solo está en `RETOMAR.md:652-683`, sin informe `REDMI_*`
  propio: se cita como «14/11 (RETOMAR)» y nunca cuenta como V.

## Elementos del encargo del 13/11

| Elemento | Diseño | Modelo | Rig | Animación | Integración | Combate / equipo | Guardado | PC (batería) | Visto en el Redmi |
|---|---|---|---|---|---|---|---|---|---|
| Orbe experimental de Érebo | V | — | — | V (evento «orbe_fuera») | V (APAGADO, Auditoría) | V (mismo resultado; desde el 15/11 el azar posterior es idéntico con el orbe encendido o apagado) | — | V (`prueba_erebo_orbe_v12*`) | P: `REDMI_18_11` con el orbe experimental y la invocación «Vídeo», entera, 58 FPS. El instante del agarre en el teatro, sin ver (14/11 (RETOMAR): 44,0 frente a 44,2 FPS, sin captarlo). Encenderlo es PD-23 |
| Solo Lya invoca | V | — | — | — | V (por defecto, `b451518`) | V | — (las partidas no guardan la invocación por héroe) | V (`prueba_solo_lya_invoca`, `prueba_rasgos_grupo`) | P: Lya invoca en `REDMI_15_11` y `REDMI_18_11`. «Kael sin INVOCACIÓN», solo 14/11 (RETOMAR) |
| Magia Agua v12 | V | — | — | V | V (APAGADA, Auditoría) | V (mismo daño, golpe y azar) | — | V (`prueba_magia_agua_v12`) | — Sin ver (14/11 (RETOMAR): «no se llegó a probar»). BR-6 |
| Nix: cuerpo desde el FBX | V (canon fijado) | V (11.968 tri.) | V (54 huesos; mano del cetro con pesos desde el 15/11) | P (23 clips; proporciones adultas frente a las *chibi*: decisión del usuario) | V (APAGADO, `nix_fbx`) | V (carga en combate real, cetro en la mano; derrota sin nada bajo el suelo, medida en el PC el 19/11, C-5) | — | V (`prueba_nix_fbx`, 90 OK) | P: en combate en `REDMI_15_11` (cetro con la mano cerrada, 62,4 FPS; grupo de cuatro, 56 FPS) y `REDMI_18_11` (canaliza Ascuas de Nácar, 58 FPS). Sin ver en exploración ni su derrota (BR-1, BR-2) |
| Nix: vestuario canónico | V (canon) | V (19.481 + 612 tri.) | V (faldones, capa y capucha) | V (horneado en los 23 clips; iris con emisión suave, `89269b7`; ornamentos en 3 intensidades, `bbe3d96` y `0777cad`, APAGADO) | V (APAGADO) | P (cetro de aspecto; socket `arma_d`, encuadre `nix3d` y texturas de 2048 en PC-20) | — | V (`prueba_nix_fbx`, `prueba_nix_emision` 28 OK; con la emisión a 0, 0 píxeles distintos) | P: el vestuario se ve en los combates de `REDMI_15_11` y `REDMI_18_11`. La emisión de iris y ornamentos, sin ver. Decisiones en PC-4 |
| Capa de Garon articulada | V | V (misma imagen) | V (21 huesos) | V (procedural; giro instantáneo y media vuelta desde parado arreglados el 14/11, `f47964c` y `61a62a8`) | V (APAGADA, Auditoría) | V (anclaje, colisiones con armas) | — | V (`prueba_capa_garon`, `prueba_capa_garon_estados`) | — Sin informe `REDMI_*` (14/11 (RETOMAR): «ondea detrás al atacar»). Coste sin medir. PD-21 |
| Garon v2/v3: pasos dobles | — | — | — | V (usa su clip de correr) | V (por defecto, `80ac41a`) | V | — | V | — |
| Kael: Ataque rúnico (24) | **B** (faltan el catálogo y el PDF de Kael) | — | — | — | — | — | — | — | — (PD-28) |
| Garon: Esgrima (18) y Compás | P (3 de 18 técnicas y el Compás, interruptor `esgrima_v12`, APAGADO; filas «D» por decidir) | — | — | — | P | P | — | V (`prueba_acciones_v12`) | — (AM-6) |
| Lya: Magia blanca (18) e invocaciones (6) | P (3 de 18, Aurel, 1 de 6 invocaciones; interruptor `magia_blanca_v12`, APAGADO) | — | — | — | P | P | — | V (`prueba_acciones_v12`) | — (AM-6) |
| Nix: Magia negra (24) y Eclipse | P (3 de 24: nix_ascuas, nix_aguja, nix_colapso; lista en `RESUMEN_PDFS_NIX_ENEMIGOS.md`) | — | — | — | P | P | — | P | P: Ascuas de Nácar canalizada en `REDMI_18_11`. El resto, sin ver (AM-5) |
| `meshy_e01` Custodio de Porcelana | V (paquete) | V (10.541 tri., 1,85 m) | V (24 huesos, placas rígidas) | V (12 de 12 clips desde `1e776f6`, 19/11: idle, walk, 3 ataques, golpe, derrota, alert, guard, stagger, turn_l y turn_r; giro con el pie que pivota 1 s, sin arreglar) | V (APAGADO, grupos 28 y 29; sonido propio y «llave iluminada», `93f9fa7` y `2c28607`, APAGADOS) | P (Prensa, Avance y Sello con su rotación y su contador; cifras PROPUESTAS, afinidades neutras provisionales: PD-25) | — | V (`prueba_meshy_e01` con las secciones L y N, `medir_custodio_rotacion`, `trazar_custodio_contador`) | P: `REDMI_15_11` (rotación ×8, Avance, contador legible hasta «Sello en 2»; el Sello no llegó a lanzarse) y `REDMI_18_11` (victoria, 54-56 FPS). Los 5 clips nuevos, el sonido y la llave, sin ver (AM-4, PC-5) |
| `meshy_e02`…`e04` | V (paquete) | — (FBX sin rig) | — | — | — | — | — | — | — (PC-3) |
| `common_e01`…`e10` | V (bestiario V12) | P (Peón y Velador del bestiario v12) | P | P | P (`enemigos_v12`, apagado) | P | — | P (`prueba_enemigos_v12`) | — (PC-3) |
| 32 conjuntos equipables | **B** (faltan el PDF del arsenal y el catálogo) | — | — | — | — | — | — | — | — (PD-28) |
| Oakhaven jugable: gremio (Oro 13), Diario con pistas, caravana y arcón con cerradura rúnica | V | — | — | — | V (ACTIVO) | — | V (premio único; partidas atascadas en el gremio) | V (`prueba_gremio_progresion`, `prueba_cerradura_runica` y `_3d`) | P: Oakhaven de noche andado sin atascos (`REDMI_15_11`). La cerradura con el dedo, sin ver (BR-7) |
| «Las tres marcas del cantero» (secundaria con secreto y segunda cerradura) | V (PROPUESTA) | — | — | — | V (APAGADA, `0f460ab`; losa primero y Diario, `d9dc733`, `178c9cd`, `ee6a02e`) | — | V (guardar y cargar con la losa abierta) | V (`prueba_oakhaven_propuestas` y `_3d`; recorridos con ventana `fotos_cantero_recorrido` y `fotos_cantero_losa_primero`, 0 fallos) | — Sin ver («no en el Redmi», `REDMI_15_11`). Aprobarla es del usuario |
| Fase 8: talleres y oficios | P (talleres más claros, `a5a519e`; receta validada antes de gastar, `629c75f`) | — | — | — | P | — | — | V (`prueba_investigacion`, `prueba_oficios`) | — (AM-7) |

## Añadidos del 14 al 19/11

| Elemento | Diseño | Modelo | Rig | Animación | Integración | Combate / equipo | Guardado | PC (batería) | Visto en el Redmi |
|---|---|---|---|---|---|---|---|---|---|
| Érebo: invocación en vídeo (cinemática) | V (EXPERIMENTAL; `EREBO_CINEMATICA_V12.md`) | — | — | V (20 s y 6,8 s) | V (APAGADA, Auditoría) | V (daño una vez, mismo ATB, se puede saltar) | — | V (`prueba_erebo_video`) | P: `REDMI_18_11`, el vídeo se ve entero y el enemigo cae (58 FPS, peor 150 ms). Sonido sin oír |
| Érebo: invocación híbrida | V (EXPERIMENTAL; `EREBO_HIBRIDA_V12.md`) | — | — | V (cabeza firme, §9) | V (APAGADA, Auditoría) | V (resistida y éxito; salir a mitad ya no da 0xC0000005 desde `208ea8b` y `1ee5644`, solo pruebas de zona) | — | V (`prueba_erebo_hibrida`) | P: `REDMI_15_11`, completa (éxito), abreviada (resistida) y saltada, 52-55 FPS. Contra un jefe y Bramavidrio, sin ver. La duración es PD-22 |
| Grupo de cuatro (solo banco) | P (`NIX_GRUPO_CUATRO.md`) | — | — | — | P (permiso de sesión en el banco) | V | — | P (`prueba_banco_pruebas` y `prueba_rasgos_grupo` en la batería; las fotos del caso, `fotos_banco_grupo4`, son de ventana) | P: `REDMI_15_11`, las cuatro filas caben, 56 FPS. Hacerlo definitivo es PD-18 y PD-19 |
| Sunken City 3D (Popa Rota → Cubierta Mayor) y la Quilla horneada | V (narrativa PROPUESTA) | V (procedural; Quilla horneada) | — | — | V (EN PRUEBAS; Quilla APAGADA) | — | — | V (`prueba_sunken3d`, `prueba_sunken_quilla`) | P: `REDMI_15_11`, bajo y medio a 30 FPS, alto 17-18 FPS. `REDMI_16_11`, muelle y popa con la Quilla a 30,37 FPS y 979 MB. La Quilla por dentro, sin ver (BR-4) |
| Mapamundi 3D «Tierras de Oakhaven» | V (PROPUESTA) | V | — | — | V (APAGADO, Auditoría) | — | — | V (`prueba_mapamundi3d` y `_apagado`) | P: `REDMI_15_11`, 30,3 FPS, viaje rápido y vuelta a Oakhaven. Campamento y cueva, sin ver |
| Muestra gráfica de una calle de Oakhaven | V (dirección aprobada el 15/11) | V (Blender, luz horneada) | — | — | V (solo banco de Auditoría) | — | — | V (`prueba_muestra_calle`) | **V**: `REDMI_15_11`, 30 FPS en 7 ciclos, memoria estable y las tres correcciones vistas (v849). Extenderla es PD-8 |
| Barrio «Arrabal de las Carretas» (exterior, 3 interiores, chibis, misión) | V (PROPUESTA) | V (horneado) | — | — | V (solo banco) | — | V (en el PC) | V (`prueba_barrio_*`) | P: `REDMI_16_11`, exterior a 30,36 FPS (953 MB al entrar). Interiores y misión, sin ver (BR-3) |
| Arboleda Mítica: escalera y Hospedería | V (experimental) | V | — | — | V (solo Auditoría) | — | — | P (`prueba_arboleda_tramo` es de ventana; controles a mano pendientes) | P: `REDMI_16_11`, entrada a 29,85 FPS con un 5 % de fotogramas de 50 ms. La escalera, sin subir (IP-2) |
| Ciudad de Oakhaven (maqueta de 8 sectores) | P (PROPUESTA; kit de 52 módulos sin usar) | P (maqueta; luz provisional) | — | — | V (solo banco; interruptor `ciudad_v12`) | — | V («Guardar y recargar») | V (`prueba_ciudad_*`; recorrido 430 y 598 tramos, 0 fallos) | P: `REDMI_16_11` y `REDMI_18_11`, 30 FPS en bajo, medio y regulador; alto 33 FPS y 998 MB; fuente rodeada, grupo que sigue, rótulos gigantes arreglados y recarga en su sitio. Oficios, Ribera, Terrazas, Pasajes y Cuervo, sin andar (BR-2). AM-1 |
| Ciudad: esquinas, fachada de lado, rótulos «(en obras)» (`af3e1f9`, `9d1baef`) y rodeo al tocar un edificio (`22856a0`, `41b38a9`) | — | — | — | — | V (el rodeo, con interruptor `ciudad_rodeo`) | — | — | V (`prueba_ciudad_esquinas`, `_fachadas`, `_cargador`, `prueba_ciudad_toque_edificio`) | — Los fallos se vieron en `REDMI_18_11` (problemas 1 a 4); los arreglos, sin ver (BR-1, BR-8, PC-16) |
| «Parameter "material" is null» con los Protagonistas v3 | — | — | — | — | V (`heroe_v3_ayudante.gd`) | — | — | P (`prueba_material_null` es de ventana) | **V**: `REDMI_18_11`, 0 errores con los v3 (el 16/11 salían 12) |
| Derrotas de los héroes (Lya original, Naira, Nix, v2 y v3) | — | — | — | P (Lya original apoyada, `00a4bbd`; v2 y v3 meten la cabeza: decisión) | V (casos «Derrotas…» del banco, `69e85b9`) | — | — | V (`prueba_banco_derrotas`; medidas `diag_derrota_suelo`, C-5) | — Sin ver: ningún héroe cayó en `REDMI_18_11` (BR-1) |
| Etiquetas «PV» de los enemigos que se pisaban (`4452229`, `ab006a7`) | — | — | — | — | V (cambia la posición de los slimes de los grupos 1, 2 y 8) | V | — | V (`prueba_vida_enemigos_solape`) | — El fallo se vio en `REDMI_18_11` (problema 7); el arreglo, sin ver (PC-11) |
| Velaria (`velaria_v12`) y Cencerrante (`cencerrante_v12`) | V (bestiario, T-097) | V | V | V | V (APAGADOS; grupos 30, 31 y 32 solo en el banco) | P (cifras, botín y afinidades: decisión) | — | V (`prueba_velaria_combate`, `prueba_cencerrante_combate`) | — (CS-1, CS-2) |
| Ajustes y menú: sin repintar la pestaña entera (`5ace0bd`, `77fb9c4`) | — | — | — | — | V | — | — | V (`prueba_ajustes_parcial` en la batería; `prueba_pestanas`, solo pruebas de zona) | — Sin medir en el teléfono (PC-13) |

## Elementos que ya estaban el 14/11 y no son del encargo

| Elemento | Integración | PC (batería) | Visto en el Redmi |
|---|---|---|---|
| Protagonistas v2/v3 de pie | V | V | **V**: `INFORME_REDMI_V12.md` (v694, §2): nadie se tumba en 30 s, ni v2 ni v3 (también 14/11 (RETOMAR), v717) |
| NPC de Oakhaven sin bloquear | V | V (`prueba_npc_paso`) | P: `REDMI_15_11`, Kael cruza de la Puerta del Sur a la plaza con vecinos, de noche. La hora de más gente, sin probar |
| Gran Bosque: mipmaps y matas | V (apagados) | V | V (medido): `INFORME_REDMI_V12.md` (v694, §1), ninguna combinación llega a 30 FPS en medio; las matas, descartadas para el móvil. Sigue AM-2 |

**Documentos de cada elemento:**
- `EREBO_ORBE_V12.md`, `EREBO_CINEMATICA_V12.md`, `EREBO_HIBRIDA_V12.md` y `HIBRIDA_SALIDA_19_11.md`;
- `MAGIA_AGUA_V12.md`, `NIX_PILOTO_FBX.md` (§12, emisión), `NIX_GRUPO_CUATRO.md`, `CAPA_GARON_V12.md` y
  `REVISION_PERSONAJES_15_11.md`;
- `CUSTODIO_E01_V12.md` (§8 a §12), `VELARIA_V12.md` y `CENCERRANTE_V12.md`;
- `OAKHAVEN_JUGABLE_V12.md`, `CANTERO_V12.md`, `SUNKEN_3D_V12.md`, `SUNKEN_QUILLA.md`, `MAPAMUNDI_3D_V12.md`,
  `MUESTRA_CALLE_OAKHAVEN.md`, `BARRIO_OAKHAVEN.md`, `ARBOLEDA_HOSPEDERIA.md`, `CIUDAD_OAKHAVEN.md`;
- `DERROTA_SUELO_18_11.md` y `MATERIAL_NULL_17_11.md`;
- `encargos/FASES_ENCARGO_COORDINADOR.md`;
- guiones `GUION_REDMI_14_11.md`, `GUION_REDMI_15_11.md`, `GUION_REDMI_18_11.md` y `GUION_REDMI_19_11.md`;
- informes del Redmi `INFORME_REDMI_V12.md`, `REDMI_15_11.md`, `REDMI_16_11.md` y `REDMI_18_11.md`;
- lo pendiente, con su Id (AM-, CS-, PC-, PD-, BR-), en `PENDIENTES_GENERALES.md`.

Las celdas «Visto en el Redmi» se rellenan solo con un informe del Redmi. Una medida del PC nunca se cuenta como
Android.
