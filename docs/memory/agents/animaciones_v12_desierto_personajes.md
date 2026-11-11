# Animaciones V12 · Personajes y criaturas del desierto (PROTOTIPOS)

## 12/11/2026, madrugada (noche autónoma) · rama LOCAL `claude/v12-personajes-desierto` (`D:\Aethelgard_v12_personajes`)

Desde `claude/rebelum-v12` @ `373e7db`. Commits: `5d2d884` (Ismena y Oren), `fd1f7e4` (Vidracrán y Tolvanera),
`dd5e186` (pruebas) y el de este informe. Sin push ni merge. No se ha tocado `combate.gd`, `combate_bramavidrio.gd`,
`zonas3d/mar_cristal*`, `menus.gd`, `sonido.gd`, `musica.gd`, `enemigos/bramavidrio/*`, `GRUPOS` ni los encuentros.
**Todo es PROTOTIPO**: nada se ve en el juego hoy.

### Qué hay (observado y comprobado ejecutando, aislado, el 12/11)

| Quién | Archivos | Malla | Clips (30 fps) |
|---|---|---|---|
| Ismena | `personajes/desierto/ismena/ismena.glb` | 5706 tri, 22 huesos, atlas 512, 1 material | reposo (4 s, bucle, parpadeo), hablar (señala con el lápiz), mapa (sube la tablilla y traza), horizonte (se vuelve al camino del sur, aprieta la tablilla y suspira), reganar (mano en la cadera y lápiz al aire) |
| Oren | `personajes/desierto/oren/oren.glb` | 5660 tri, 22 huesos, atlas 512, 1 material | reposo (3 s, inquieto, se mece), hablar (abre los brazos), risa (mano en la barriga, cabeza atrás), encogerse (se hace el tonto) |
| Vidracrán | `enemigos/vidracran/vidracran.glb` | 2330 tri, 34 huesos, atlas 512, 2 superficies | reposo, pinzas (impacto 0,467 s), enterrarse, enterrado (bucle), aviso_aguijon (latidos 0,133 y 0,4 s), emerger_aguijon (impacto 0,5 s), recibir_golpe, derrota, entrada, correr |
| Tolvanera | `enemigos/tolvanera/tolvanera.glb` | 1144 tri, 10 huesos, atlas 256 (solo escombros), 5 superficies | reposo, aviso_rafaga, rafaga (impacto 0,433 s), torbellino (a todos, impacto 0,867 s), curarse_viento, agua_asienta, recibir_golpe, derrota, entrada, correr |

Referencia de presupuesto (medida con Blender): Zarzalín 8107 tri y 3 texturas de 2048; Cencerrante 6368 tri y 3 de
2048. Los cuatro prototipos quedan por debajo en triángulos y muy por debajo en texturas. Los GLB suman 2,7 MB (las
pistas van muestreadas en cada fotograma). **Rendimiento en el Redmi: sin medir** (esta noche no había Redmi ni ADB).

**Cómo están hechos.** Blender 5.2.3 por guion, geometría propia por partes, atlas pintado por código, esqueleto con
pesos por parte y clips con claves en espacio de armadura. Nada descargado: **obra propia del proyecto**.
- `personajes/desierto/fuentes_blender/desierto_comun.py` (utilidades) y `crear_ismena_oren.py`.
- `enemigos/vidracran/fuentes_blender/crear_vidracran.py` y `enemigos/tolvanera/fuentes_blender/crear_tolvanera.py`.
- Orden: `blender -b --factory-startup -P <guion> -- <raíz aethelgard> <carpeta de láminas> [ismena|oren|ambos]`.
- Los `.blend` resultantes están fuera de Git (D-075), en `D:\REBELUM_diagnostico\animaciones\2026-11-12\desierto\`.

**Diseño (sin cambiar personalidad ni relaciones; NARRATIVA_DESIERTO.md §1, §4 y §5).**
- Ismena y Oren son chibi como Kael, Lya y Garon (cabeza grande, ojos de anime). Son hermanos, así que comparten piel,
  pelo castaño rojizo y ojos ámbar.
- Ismena conserva lo de su cápsula: túnica azul verdosa, pañuelo y sombrero de ala ancha. Añadidos: una trenza sobre
  el hombro, un estuche de mapas cruzado a la espalda con rollos, una tablilla con un mapa pintado (costa, dunas, oasis
  y ruta) y un lápiz. Párpados a media altura y media sonrisa («ironía cansada»).
- Oren conserva el chaleco pardo y el pañuelo rojo del toldo en la cabeza. Añadidos: camisa remangada, faja ocre,
  cuerda de arriero en bandolera (su silueta propia), la bota de agua vacía y la bolsa de cuentas, y remiendos.
  Ojos grandes, sonrisa abierta y pecas.
- Vidracrán: bajo y ancho, de placas facetadas de vidrio ámbar esmerilado con arena dentro. Patas de vidrio ahumado,
  pinzas planas como esquirlas y una cola alta con un bulbo de vidrio de botella verde que brilla (el cebo). No se
  parece al basalto de Bramavidrio, a la corteza de Zarzalín ni a Cencerrante.
- Tolvanera: un embudo de 1,95 m que se ensancha hacia arriba, con una falda de arena, núcleo y capa exterior de polvo
  que gira, dos brasas rasgadas por ojos y piedras, esquirlas y un jirón de tela que giran alrededor.

**Scripts de Godot**
- `personajes/desierto/npc_desierto_3d.gd`:
  - en reposo respira, cambia el peso y parpadea; cada 9-18 s hace un gesto de oficio, nunca el mismo dos veces;
  - `hablar()` alterna el gesto con su variante y a veces no hace nada (nada de un gesto en cada frase);
  - también tiene `gesto(clip)`, `en_dialogo(si)` (sin gestos sueltos durante un diálogo) y `mirar_a(punto)`.
- `enemigos/vidracran/vidracran_3d.gd`:
  - el contrato de `zarzalin_3d.gd` más `enterrarse()`, `avisar()` y `puede_ser_objetivo()` (falso enterrado);
  - `atacar("emerger_aguijon"|"pinzas", cb)` y la señal `enterrado_cambio`;
  - sombreados opacos de vidrio (`vidracran_vidrio.gdshader`) y brillo (`vidracran_brillo.gdshader`), más un halo
    aditivo en el bulbo, que late en el aviso y se apaga en la derrota.
- `enemigos/tolvanera/tolvanera_3d.gd`:
  - el contrato de `zarzalin_3d.gd` más `avisar()`, `atacar("rafaga"|"torbellino", cb)`, `curarse_viento()` (señal
    `curado`) y `asentar_agua()` (se oscurece como barro);
  - el polvo gira por sombreado (`tolvanera_polvo.gdshader`: 3 capas transparentes, `cull_back`, sin profundidad);
  - los escombros giran por script sobre el hueso `escombros`; las brasas (`tolvanera_brasas.gdshader`) se dibujan
    después del polvo.

### Cómo se activa (todo apagado por defecto)

**Ismena y Oren.** `Engine.set_meta("npc_desierto_v12", true)` (o `ACTIVO_POR_DEFECTO` en `npc_desierto_3d.gd`).
Además, el coordinador tiene que hacer este cambio en `zonas3d/mar_cristal_3d.gd`, que no he tocado:
- al principio de `_crear_cartografa()`, después de `add_child(cartografa)`:

  ```gdscript
  const NPC_DESIERTO := preload("res://personajes/desierto/npc_desierto_3d.gd")   # (a nivel de clase)
  if NPC_DESIERTO.activado():
      cartografa.add_child(NPC_DESIERTO.crear("ismena"))
      return
  ```
- y lo mismo en `poner_oren()`, después de `add_child(oren)`, con `crear("oren")`.
- Propuesta: llamar a `hablar()` de quien habla en cada frase de Dialogic, `en_dialogo(true/false)` al abrir y cerrar
  `mc_cartografa_*` y `mc_superviviente`, y `mirar_a(kael.global_position)` al empezar.
- Pendiente de verificar: si `mc_superviviente` ocurre en la trampilla, allí Oren necesitaría una pose sentada o
  agotada, que no existe.

**Vidracrán y Tolvanera.** No están en `GRUPOS` ni en los encuentros. Lo que haría falta en el combate (de
`combate.gd`, que no he tocado):
1. Crearlos como a Zarzalín: `load("res://enemigos/vidracran/vidracran_3d.gd").new()`; `ALTURA` y `CENTRO` están en
   cada script.
2. **Vidracrán:**
   - su turno A, `enterrarse()`; mientras `puede_ser_objetivo()` sea falso, no se le puede apuntar (una regla nueva
     del combate);
   - su turno B, `avisar()`, y en la señal `aviso` el indicador del objetivo;
   - moverlo bajo el objetivo (no se ve; solo la cola);
   - después `atacar("emerger_aguijon", daño)`, con el impacto a 0,5 s;
   - fuera de la arena, `atacar("pinzas", daño)`, que avanza 0,25 m;
   - el suelo del combate tiene que tapar el cuerpo enterrado (se hunde 0,5 m).
3. **Tolvanera:**
   - solo en encuentros con tormenta;
   - con un golpe de Agua, `asentar_agua()` y más daño (en vez de `recibir_golpe()`);
   - con viento, `curarse_viento()` y curación en la señal `curado`;
   - `atacar("torbellino")` es a todos.
4. Posibilidades tácticas (propuesta para el coordinador; sin cambiar magias ni Esgrima):
   - Vidracrán: el aviso deja un turno para defenderse o curarse antes del aguijón; al salir queda expuesto; el vidrio
     podría ser débil a los golpes contundentes de Garon.
   - Tolvanera: el Agua la asienta; no conviene el viento.
   - Nombres sin aprobar (§4).

### Pruebas (aisladas, `ejecutar_pruebas.ps1 -Lista`)

- `pruebas/prueba_desierto_prototipos.gd` (auto): **SUPERADA**, con 85 comprobaciones y `FALLOS: 0`.
  - Comprueba clips, duraciones frente a `*_clips.json`, señales, impactos ±2 fotogramas, el enterrado sin poder
    apuntarle, los gestos sin repetir y el interruptor apagado.
  - Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_224742\resumen.md`.
- `pruebas/fotos_desierto_prototipos.gd` (ventana): **MANUAL**, termina sin errores y saca 80 capturas.
  - Escena propia en arena con Kael a escala, cámara de exploración (45°, 20 m, 38°) y cámara ortográfica de combate a 12°.
  - Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_224715\resumen.md`.
- En las dos pasadas, «partida.save real: sin cambios · carpeta real: sin cambios · proyecto: sin cambios».
- Importación: la primera `--import` vació los directorios de Dialogic en `project.godot`. Hice `git restore` y
  reimporté; quedó estable.
- **Pido** añadir a `pruebas/lista_pruebas.txt` (no lo he tocado):

  ```
  prueba_desierto_prototipos | auto    |                  | 240 | nada      | V12 prototipos del desierto: clips, tiempos, señales e interruptor
  fotos_desierto_prototipos  | ventana | salida={salida}  | 400 | {salida}  | V12 prototipos del desierto: capturas (Ismena, Oren, Vidracrán, Tolvanera)
  ```
- **Pido** una fila en `docs/recursos.md`: «Ismena, Oren, Vidracrán y Tolvanera (V12, prototipos): obra propia,
  Blender 5.2.3 por guion (`personajes/desierto/fuentes_blender/`, `enemigos/vidracran|tolvanera/fuentes_blender/`),
  sin recursos externos».

### Conceptos y evidencias: `D:\REBELUM_diagnostico\animaciones\2026-11-12\desierto\`

- `ismena_lamina.png`, `oren_lamina.png`: silueta, frente, 3/4, espalda y Kael (kael.fbx del juego, 1,7 m).
  También `*_cara.png` y una pose por gesto (`ismena_hablar.png`…).
- `vidracran_lamina.png`, `tolvanera_lamina.png`: silueta de perfil, vistas y Kael. También
  `*_poseN_<clip>_fN.png` con los instantes clave (aviso, impacto, enterrado, derrota…).
- `godot/`: capturas reales en Godot.
  - `personajes_poses.png`, `personajes_secuencia.png` (24 fotogramas de un diálogo simulado),
    `p00_exploracion_20m.png` (cómo se ven a la distancia real del juego) y `p02_cerca_reposo.png`.
  - `criaturas_vidracran.png`, `criaturas_tolvanera.png` (12 instantes) y `*_movimiento.png`.
- En las láminas de Blender, el polvo de Tolvanera es una aproximación; el aspecto real es el de las capturas de Godot.

### Límites y lo que falta (honesto)

- **Prototipos**, no finales. Mi lectura, pendiente del usuario:
  - la calidad es la de un chibi de formas sencillas, inferior al detalle de textura de los héroes de Meshy;
  - la silueta y los colores se leen bien a 20 m, que es la distancia real de la cámara.
- Lo que no tienen:
  - expresiones de cara ni sincronía de labios: la boca y los ojos están pintados; solo parpadean;
  - manos con dedos: son manoplas con pulgar;
  - clips de andar.
- Probado: con brazos chibi la mano no llega a hacer visera. «Horizonte» se resolvió con giro, tablilla y suspiro.
- El pañuelo de Oren puede leerse como una gorra roja desde delante; habría que marcar el nudo y los pliegues.
- En Tolvanera, al final de la derrota queda un rastro tenue alto: falta ajustar el desvanecido y la escala del clip.
- Sin medir en el Redmi:
  - el sobredibujado de las 3 capas de polvo de Tolvanera, que es lo más caro;
  - las pistas muestreadas de los GLB (2,7 MB).
- El cambio en `mar_cristal_3d.gd` y el enganche al combate son del coordinador. Las escenas solo se han probado en
  mi escena de pruebas, no en la región ni en un combate real.

### Siguiente paso propuesto

1. Que el usuario revise las láminas y las capturas de `godot/`, y que apruebe los nombres de §4.
2. Si le valen:
   - aplicar el cambio de `mar_cristal_3d.gd` detrás del interruptor y probar `mc_cartografa_*` en la región;
   - medir en el Redmi Vidracrán y Tolvanera en un combate de prueba (la medida la programa el coordinador).
3. Pulido: nudo del pañuelo de Oren, expresiones (una segunda loseta de cara para gestos), pose agotada de Oren en
   la trampilla y ajustar la derrota de Tolvanera.
