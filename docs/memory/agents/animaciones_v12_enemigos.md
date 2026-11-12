# Animaciones V12 · Fase C: enemigos con identidad propia (Guardián de piedra, Gólem de ámbar y Gorthor)

## 12/11/2026, 02:50 · rama LOCAL `claude/v12-fase2-enemigos` (`D:\Aethelgard_v12_enemigos`, desde `92a511d`)

Commits: `bda31b5` (generadores de Blender), `1d0ef19` (modelos, texturas, JSON y guiones), `a27401d` (pruebas y
parche), `4ec9f3a` (vetas y grietas, prueba robusta) y el de este informe. Sin push ni merge. **No he tocado
`combate.gd`** (lo edita magia): los cambios que pido están, exactos, en `pruebas/herramientas/parche_enemigos_v12.gd`.
Todo es **obra propia** (Blender 5.2.3 por guion, sin recursos externos). Los originales siguen: `enemigos/guardian.png`
y el goblin (`goblin.fbx`) quedan como `respaldo` en MODELOS.

### Qué hay (comprobado ejecutando, aislado, el 12/11)

| Enemigo | Concepto | Triángulos | Huesos | Textura | Clips (30 fps) |
|---|---|---|---|---|---|
| Guardián de piedra, «el Centinela del Anillo» | Estatua de templo de caliza tallada (greca), yelmo con rendija en T verde agua, musgo, mandoble de granito con runa y un **anillo de piedra que flota y gira** tras la cabeza. Erguido, 2,34 m | 5 720 | 24 | WebP 1024 / 512 | reposo, caminar, correr, entrada, ataque (impacto 0,8), carga, carga_espera, golpe_fuerte (0,92; desde la carga 0,5), recibir_golpe, victoria, derrota |
| Gólem de ámbar, «el Guardián del Nido» | Terrones **facetados de resina fósil con insectos dentro** (aislante: encaja con su inmunidad al Rayo), atados con ramas petrificadas, **el nido con tres huevos a la espalda**, puños enormes y pies de pisar. Ancho y bajo, 2,24 m | 3 654 | 22 | WebP 1024 / 512 | reposo, caminar, correr, entrada, ataque (0,7), carga («levanta los puños»), carga_espera, golpe_fuerte = Pisotón (0,75; desde la carga 0,45; con onda de polvo), recibir_golpe, **aturdido**, victoria, derrota |
| Gorthor el Devorador | El caudillo del clan Grimfang crecido a monstruo: panza y hombros enormes, orejas con argollas, **mandíbula prognata articulada** (cerrada sin rendija en reposo) con colmillos, corona de hueso con cuernos, estandartes rojos con su emblema, cuchilla con el filo al rojo y **vetas de brasa** (resiste el Fuego, débil al Hielo). 2,74 m (3,14 con cuernos) | 7 123 | 25 | WebP 1024 / 512 | reposo, caminar, correr, entrada (ruge 1,4), ataque (0,75), carga, carga_espera, golpe_fuerte (0,95; desde la carga 0,5), **devorar** (abre 0,6, muerde 0,9, traga 1,5), **fase2** (ruge 0,9), recibir_golpe, **rendirse** (rodillas 0,8), **rendido**, **arrastrarse**, victoria, derrota, **derrota_rendido** |

- Presupuesto: ≤ 8 000 (Gorthor ≤ 10 000); una malla, 2 o 3 superficies, sin LOD (no hace falta con estos números).
- Oclusión ambiental horneada en el color de vértice (llega en sRGB: medido, mínimo 0,416).
- Pies apoyados por IK de dos huesos en cada fotograma (medido: no patinan en reposo ni en las esperas).
- **Instantes** en `enemigos/<nombre>/<nombre>_clips.json` y en `EVENTOS` de cada guion (la prueba los compara).

**Archivos (para integrar copiando, todos nuevos):**
- `aethelgard/enemigos/v12_comun/` (`enemigo_v12_3d.gd` + `.uid`, `fuente/enemigos_v12_blender.py`, `fuente/.gdignore`);
- `aethelgard/enemigos/guardian_piedra/`, `golem_ambar/`, `gorthor/` (cada uno: `*_3d.gd` + `.uid`, `.glb` + `.import`,
  `.webp` y `_bajo.webp` + `.import`, `_clips.json`, `fuente/crear_*.py`, `fuente/.gdignore`);
- `aethelgard/pruebas/prueba_enemigos_v12.gd`, `fotos_enemigos_v12.gd`, `herramientas/parche_enemigos_v12.gd` (+ `.uid`).
- Regenerar: `blender -b --factory-startup -P enemigos/<n>/fuente/crear_<n>.py -- <raíz aethelgard> <carpeta láminas>`
  (unos 25 s; misma semilla, mismo resultado). Necesita `personajes/desierto/fuentes_blender/desierto_comun.py`.

### Interfaz con el combate (`enemigos/v12_comun/enemigo_v12_3d.gd`)
- Entran por el **mismo camino que el Gorthor de antes** (`_anim_ataque_3d`): `atacar_hacha(cb)`, `golpe_fuerte(cb)`
  (desde la carga si estaba cargando), `correr`, `reposo`, `herida`, `morir`, `cansada`, `mirar`, `mirar_frente`,
  `entrada`, `victoria`, `revivir`, `punto_magia`, `const ALTURA` (Érebo). Impacto **una vez**, en el fotograma del clip.
- No tiene `avisar`, `despertar`, `avanzar/retroceder` (para no caer en los caminos de Zarzalín, el Guardián del Bosque o Garon).
- Ganchos: `cargar()`, `aturdido()`, `fase2()`, `devorar(cb)`, `rendirse()`, `retirarse()`. Señales `impacto`,
  `ataque_terminado`, `clip_terminado` y `evento(clip, nombre)` (rugido, trago, pisotón, rodillas…: para sonido).
- El brillo (ojos, runas, vetas, filo) sigue al hueso «luz» de cada clip; en la fase 2, ×2,2.

### Cambios que pido en `combate.gd` (los aplica el coordinador)
Exactos en `aethelgard/pruebas/herramientas/parche_enemigos_v12.gd` (`CAMBIOS`, cada uno «ancla única → sustitución»,
con `VALORES`). Probados aplicándolos **en memoria** al `combate.gd` de `92a511d` (encajan, compila, se juega).
1. **MODELOS** (al final): `guardian3d` (esc 0,6, vp 1280×1300, alto_vista 4,7, centro_y 1,8, barra_y 216,
   centro_3d 1,35, pos_grupo (-191, -186), caida 1,6, respaldo «guardian»); `golem_ambar3d` (vp 1000×910, 3,3, 1,15,
   barra_y 49, centro_3d 1,25, pos_grupo (-79, 37), caida 1,4, respaldo «guardian»); `gorthor_v12` (vp 1420×1520,
   5,2, 1,6, barra_y 183, centro_3d 1,6, pos_grupo (-60, -247), caida 1,4, respaldo «gorthor3d»). Todos con
   `"gestos": "res://gestos_3d.gd"` (lo exige `_ruta_3d`). Encuadre medido proyectando todos los clips (menos derrota,
   victoria y arrastrarse) con la cámara de `_crear_rig_3d`; `pos_grupo`: los pies justo donde los del dibujo de antes.
2. **ENEMIGOS**: `guardian` → `"modelo": "guardian3d"`; `golem_ambar` → `"golem_ambar3d"`; `gorthor` → `"gorthor_v12"`
   (vida, ataque, personalidad y premios sin cambiar).
3. **ANIM**: `guardian3d` 310, `golem_ambar3d` 220, `gorthor_v12` 220 (medido: la punta del arma queda a −17…+14 px del
   centro del héroe en el impacto; el Pisotón y el golpe fuerte de Gorthor caen algo antes, en el suelo).
4-5. Tras `_marcar_aviso(f, true)` del jefe y del patrón: `if _p3d(f) != null and _p3d(f).has_method("cargar"): _p3d(f).cargar()`.
6. `_interrumpir`: `aturdido()`; y en el turno «recupera» de `_turno_patron`: `reposo()`.
7. Devorar: en la rama de `atacar_hacha` de `_animar_golpe`, `metodo_3d = "devorar"` si `origen.devora` y el modelo
   tiene `devorar`; en el `match` de `_anim_ataque_3d`, `"devorar": await p.devorar(al_golpear)`.
8. `_cambio_fase`: tras «¡FURIA DEL ABISMO!», `fase2()`.
9. `_decidir`: `rendirse()` en vez de bajar el rig 24 px (si el modelo lo tiene).
10. `_perdonar`: `retirarse()` tras el texto.
11. Caída: `t.tween_interval(2.8 if Brama.es(f) else float(MODELOS[f["modelo"]].get("caida", 0.9)))`.
Sin 4-11, los tres funcionan con su ataque y su golpe fuerte de siempre.

**Propuesta aparte (no está en el parche):** en `_cambio_fase`, el tinte `Color(1.0, 0.45, 0.38)` de la ventana 3D
deja a Gorthor rojo plano y apaga sus vetas (captura `combate/gorthor/32_furia.png`); con un modelo que tenga `fase2`,
mejor un tinte suave (p. ej. `Color(1.0, 0.8, 0.75)`).

### Pruebas (aisladas; partida real, carpeta real y proyecto: sin cambios)
- `prueba_enemigos_v12` (auto, `-- auto`): **SUPERADA**, `D:\REBELUM_diagnostico\pruebas\2026-11-12_024802\resumen.md`.
  Carga, triángulos = JSON y presupuesto, huesos, texturas 1024/512 y la de 512 con calidad baja, todos los clips con
  su duración, bucle e instantes, bucles sin salto, pies sin patinar (< 3 cm), boca de Gorthor cerrada en reposo
  (< 1°) y abierta al rugir y al abrir para morder (> 40°), cerrada al morder; en marcha: un impacto por ataque en su
  fotograma (±2), desde la carga, señales evento, herida no corta un ataque, aturdido, fase 2 (×2,2), devorar,
  rendirse, derrota_rendido, retirarse; encuadre; y **el combate de verdad con el parche en memoria** (grupos 4, 6 y 5,
  75 s con `auto`): su modelo, actúa, sus golpes llegan; Gorthor pasa solo por carga, Devorar, fase 2, rodillas y perdón.
- `fotos_enemigos_v12` (ventana, `salida=… auto`): **MANUAL**, FALLOS 0, `D:\REBELUM_diagnostico\pruebas\2026-11-12_024623\`.
- **Pido** en `pruebas/lista_pruebas.txt`:
  ```
  prueba_enemigos_v12 | auto    | auto                 | 600 | user://  | V12 fase C: Guardián de piedra, Gólem de ámbar y Gorthor (modelos, clips, instantes, señales, pies, boca, encuadre) y el combate con pruebas/herramientas/parche_enemigos_v12.gd en memoria
  fotos_enemigos_v12  | ventana | salida={salida} auto | 400 | {salida} | V12 fase C: los tres en el combate de verdad, antes y después del parche (pies, alcance y ganchos medidos)
  ```
  Cuando el parche esté en `combate.gd`, `aplicar()` dirá que faltan las anclas: entonces hay que usar el guion tal cual
  (quitar la parte del parche de las dos pruebas o comprobar `"guardian3d" in MODELOS`).
- **Pido** en `docs/recursos.md`: «Guardián de piedra, Gólem de ámbar y Gorthor (V12, fase C): `enemigos/guardian_piedra/`,
  `golem_ambar/`, `gorthor/`, `v12_comun/` | Obra propia: modelo, textura, esqueleto y clips generados con Blender 5.2.3
  por `fuente/crear_*.py` | Propia | Combate (cuando se apliquen los cambios de combate.gd) | Sí».

### Evidencias: `D:\REBELUM_diagnostico\animaciones\2026-11-12\enemigos\`
- Láminas (silueta, frente, 3/4, perfil y Kael a escala): `guardian_piedra\guardian_piedra_lamina.png`,
  `golem_ambar\golem_ambar_lamina.png`, `gorthor\gorthor_lamina.png`; las tres juntas, `comparativa_laminas.png`.
- Color: `*_atlas.png`. Poses de cada clip: `*_poses.png` y `poses\`. Boca de Gorthor de cerca: `gorthor\gorthor_boca.png`.
- Combate de verdad: `combate\<guardian|golem|gorthor>\` (antes/después, preparación e impacto, carga, golpe fuerte,
  herido, aturdido, furia, Devorar, rodillas, perdón, derrota), `combate\*_antes_despues.png` y `*_secuencia.png`.
- Los `.blend` (fuera de Git, D-075): `<enemigo>\<enemigo>.blend`.

### Límites (honesto)
- **Sin Redmi y sin medir rendimiento.** Las ventanas 3D son grandes (Gorthor 1420×1520, el Guardián 1280×1300; el
  Bramavidrio, 1920×1000): medir memoria y FPS en el teléfono antes de darlo por bueno.
- Visto en capturas y hojas, **no en vídeo** corriendo (`--write-movie` pendiente).
- El Guardián se lee algo pálido y de bloques en el combate; el ámbar del Gólem, muy saturado (ya rebajado a 0,22).
- La exploración no usa estos modelos: la estatua de Pastos, el gólem dormido del nido y Gorthor ante su trono
  (`zonas3d/garganta/piezas.gd`, `golem()` y `gorthor()`) siguen con `modelos/guardian/` y el goblin. Se puede
  instanciar `*_3d.gd` ahí (reposo / entrada); no lo he tocado.
- Sin sonidos propios: las señales `evento` están listas para el especialista de sonido.
- La victoria de los enemigos no la llama el combate (el clip existe).
- Láminas con la luz y el suelo del desierto (las utilidades comunes); el título se monta sobre el modelo central.

### Siguiente paso propuesto
1. Coordinador: aplicar los 11 cambios (o solo 1-3), pasar `prueba_enemigos_v12` y la batería, y medir en el Redmi.
2. Que el usuario mire las láminas y las capturas de combate; ajustes rápidos en los generadores (colores, tamaños).
3. Enganchar los modelos en la exploración de la Garganta y en la estatua de Pastos; sonidos por `evento`.
