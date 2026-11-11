# Animaciones (y modelado), V12: Bramavidrio definitivo

## 11/11/2026, 15:35 · rama `claude/v12-bramavidrio` (LOCAL, nace de `claude/rebelum-v12` @ `8e328d9`)

Encargo del usuario (11/11): el modelo y las animaciones DEFINITIVOS de Bramavidrio, el gusano colosal del Mar de
Cristal. Copia `D:\Aethelgard_v12_bramavidrio`. Todo lo de aquí es **obra propia**: geometría, textura, esqueleto y
clips hechos con Blender 5.2.3 por guion. No se ha usado nada de terceros. La referencia del usuario
(`D:\REBELUM_diagnostico\v12\referencias\bramavidrio_presencia_referencia.webp`) solo se miró para la sensación de
escala; no se ha copiado nada de ella.

**Estado: modelo, clips, guion y exploración hechos y probados en el PC. El combate NO está enganchado** (no toca
`combate.gd`: lo hará el especialista de combate con la entrada de `MODELOS` de abajo). Nada se ha probado en el Redmi.

### Commits

| Commit | Qué |
|---|---|
| `e9e8bd7` | `aethelgard/fuente/crear_bramavidrio.py` (generador) y `fuente/capturas_bramavidrio.py` (renders de Blender) |
| `25c6623` | los tres GLB, sus tres texturas WebP (con sus `.import`) y `bramavidrio_clips.json` |
| `bff1fbe` | `enemigos/bramavidrio/bramavidrio_3d.gd` y sus sombreadores (`_piel`, `_vidrio`, `_chorro`), con sus `.uid` |
| `c3fc542` | `zonas3d/mar_cristal/gusano.gd`: el modelo definitivo en la exploración (el provisional sigue) |
| `05047ed` | `pruebas/prueba_bramavidrio_modelo.gd`, `pruebas/fotos_bramavidrio.gd` y sus dos líneas en `lista_pruebas.txt` |
| este | este informe |

Sin confirmar a propósito: `enemigos/bramavidrio/bramavidrio_v1.png.import`, que lo generó Godot para la foto
anterior y no es mío.

## 1. Concepto (escrito) y variantes de cabeza

**Qué es:** un gusano larguísimo y muy grueso: 22 m de cuerpo con 18 anillos y 3,2 m de cabeza (×1,3: 4,2 m). El
diámetro llega a 3,7 m. En reposo asoma unos 11 m de cuerpo por su agujero en forma de «?». La cabeza queda a 9 m de
altura y 9 m por delante; en el ataque sísmico se alza hasta 20 m.

**Cómo es:**
- **El cuerpo:** cada anillo lleva una **placa dorsal de mineral**. Es una teja: su labio trasero monta sobre el anillo
  siguiente, y así la armadura no se estira al doblarse.
- **El vidrio:** en el lomo, **aletas de vidrio fundido** inclinadas hacia la cola, en una cresta y dos hileras, más
  algunos cristales sueltos en el alto. Brillan con una onda de luz que recorre el cuerpo.
- **Las marcas:** en los surcos entre anillos, la piel deja ver un **brillo mineral tenue**. También hay **cicatrices
  viejas selladas con vidrio que brilla**: una grande en el escudo de la cabeza y cuatro que cruzan anillos. Una aleta
  está rota (anillo 7) y otras placas tienen grietas.
- **Los costados:** **espolones de queratina**, que empujan en la arena. El vientre es más claro y plano.
- **El canon que se respeta** (`NARRATIVA_DESIERTO.md` §4): pasta vidrio, las placas de vidrio del lomo brillan, la boca
  de placas muele, no se monta, no es sagrado y no guarda nada.
- **Lo que cambia del canon:** el «corto y grueso» de antes deja paso a «cuerpo largo y gigantesco», que es lo que pide
  ahora el usuario. Conviene que narrativa actualice §4.

**Tres cabezas probadas** (siluetas en negro, de perfil y de tres cuartos:
`D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio\blender\siluetas_variantes_cabeza.png`):
- **A, el arado** (la elegida): un escudo ancho y bajo que se estrecha en una cuchilla para cavar, con crestas que
  corren hacia atrás.
  - **La mandíbula:** enorme, en forma de **cazo de excavadora**, con cinco **dientes de cincel** planos. Debajo de la
    cuchilla, cuatro más cortos que encajan entre ellos.
  - **Dentro de la boca:** **placas planas que muelen**: tres pares arriba y tres abajo, como muelas de molino.
  - **La garganta:** un túnel oscuro con luz mineral al fondo.
  - **Los ocelos:** seis de vidrio, tres a cada lado.
  - Nada apunta hacia arriba (no es una corona). No hay pétalos ni anillos de dientes (nada de Dune).
- **B, la maza:** cabeza bulbosa y acorazada con la boca por debajo. **Descartada:** de perfil es una bola, la boca no
  se ve y no asusta.
- **C, el pico de prensa:** dos losas largas, como una tenaza. **Descartada:** se lee como un ave y resulta frágil
  para su tamaño.

**Por qué A:** es la única que se reconoce de perfil y de tres cuartos. Además, la boca, que es la amenaza, queda
delante, su forma cuenta qué come y cómo cava, y es original.

## 2. Modelo y materiales (cómo se hace)

`blender -b --factory-startup -P aethelgard/fuente/crear_bramavidrio.py -- <carpeta> [alto,medio,bajo] [<salida.blend>]`
regenera todo con la misma semilla y en unos 20 s. Con `-- <carpeta> siluetas` hace los bocetos de las tres cabezas.

**Geometría:** procedural, con bmesh y listas propias.
- El tubo del cuerpo tiene secciones abombadas por anillo.
- Las placas son tejas con bordes que cierran contra el tubo.
- Las aletas son prismas de 6 lados con canto.
- La cabeza y la mandíbula se hacen por secciones interpoladas. La cabeza se modela a escala 1 y se agranda ×1,3.
- La boca, las mejillas que se estiran y el montículo de arena se hacen aparte.
- El chorro del aliento es un cono doble.

**Normales:** cada cara se orienta con un punto de referencia por pieza (lejos de un punto o hacia él). Luego, bordes
vivos a partir de 38°.

**Textura de la piel (2048), pintada con numpy en un atlas con UV calculadas** (sin desplegar): tubo, 18 bandas de
placas, cráneo, mandíbula, carne de la boca, neutro (dientes y espolones) y arena.
- **Contenido:** manchas por ruido, desgaste claro en cantos y en lo alto, polvo, rayado de arena, grietas con brillo,
  cicatrices vitrificadas, cuencas de las aletas y de los ocelos.
- **RGB:** el color.
- **A:** el brillo, guardado como **0,04 + 0,96 × brillo**.
  - **Causa demostrada:** WebP con pérdida no conserva el color de los píxeles con alfa 0. Era el 90 % de la textura y
    su error de color medio era de 0,106, frente a 0,006 en el resto. En Godot se veía la piel «a rayas».
  - Con el mínimo no queda ningún píxel con alfa 0. El sombreador lo deshace.
- **Medio y bajo:** la misma textura reducida (1024 y 512).

**Colores de vértice** en sRGB: oclusión de surcos, de bajo las placas y de la boca, y los tintes de dientes, vidrio y
garganta.

**Materiales en Godot:** los pone `bramavidrio_3d.gd` por nombre de superficie. Todos son de Compatibility.
- `bramavidrio_piel.gdshader`: textura × color de vértice × `tono` (0,8). Lo añadí tras ver el combate: con su luz
  cálida la piel quedaba clara y sin contraste. Las grietas brillan × `energia`.
- `bramavidrio_vidrio.gdshader`: opaco, con brillo especular, borde según se mire y una onda de luz. Con `GARGANTA`
  hace la luz del túnel de la garganta: un degradado hacia dentro, casi negro en reposo (energía 0,35) y encendido al
  aspirar (2,6).
- `bramavidrio_chorro.gdshader`: sin sombreado, aditivo y sin sombra.
- **Recorte:** la variante `RECORTE` (con `discard` de lo que queda bajo el suelo) **solo se compila en el combate**.
  En la exploración lo enterrado lo tapa el terreno y no se paga el `discard`.

**Por versión** (alto ≤ 25 000, medio ≤ 12 000 y bajo ≤ 6 000 triángulos: medido en el GLB y en Godot):

| Versión | Triángulos (Blender / Godot) | Textura | GLB | Qué quita |
|---|---|---|---|---|
| alto | 16 380 / 16 348 | 2048 (WebP 424 KB) | 2,38 MB | — |
| medio | 7 990 / 7 958 | 1024 (170 KB) | 2,02 MB | menos lados y filas; sin cristales sueltos; 2 pares de muelas y 2 de dientes laterales |
| bajo | 3 594 / 3 562 | 512 (68 KB) | 1,79 MB | 12 lados; aletas de los flancos solo en anillos pares; sin espolones; 1 par de muelas |

- **Los GLB:** pesan sobre todo por la animación, muestreada en cada fotograma (41 huesos × 10 clips). Las pistas no se
  optimizan a propósito: si falta una pista, Godot deja el último valor del clip anterior (por ejemplo, el chorro
  encendido).
- **En la GPU (estimado, no medido en el teléfono):** comprimidas (ETC2/ASTC en Android) y con mipmaps, unos 5,3 MB
  la alta, 1,3 MB la media y 0,35 MB la baja.
- **Godot quita 32 triángulos degenerados** en cada versión; la prueba tolera un 1 %.

## 3. Esqueleto (rig)

**41 huesos:**
- `raiz`.
- La cadena **`col_18` (cola) → … → `col_01` (nuca)**, de 1,222 m cada uno, que nace en la cola.
- `cabeza` y `mandibula`, con la bisagra atrás y abajo.
- `placa_02` … `placa_17`: cada grupo de aletas, hijo de su anillo; se erizan y vibran.
- **De datos, por su escala:** `brillo` (luz de aletas, ocelos y grietas), `garganta` (luz del túnel), `chorro` (el
  aliento: 0,01 escondido y 1 entero) y `monticulo` (la arena revuelta del agujero).

**Pesos:**
- **Tubo:** mezcla suave en cada unión de anillos (±0,32 del anillo); como mucho 2 huesos por vértice.
- **Placas, aletas, espolones y dientes:** rígidos a su hueso. La armadura no se deforma: gira entera.
- **Mejillas y pared de la garganta:** mezcla cabeza/mandíbula, para que se estiren al abrir la boca.

**Método (la «spline IK» resuelta en el guion y horneada):**
- Cada fotograma es una curva de columna: ángulos de elevación, giro y torsión a lo largo del cuerpo, más un punto
  ancla (el agujero, por donde pasa el cuerpo).
- Se integra la curva y la cadena se ajusta por longitud de arco: así el cuerpo se desliza por el agujero sin
  estirarse.
- Luego se escriben las claves de cada fotograma, lineales.
- Las poses clave se mezclan entre sí y encima se suman ondas: respiración, vaivén, olas bajo la arena, vibración de
  las aletas y sacudidas del rugido.
- Elegí esto en vez del Spline IK de Blender, horneado con `nla.bake`: es determinista, se controla por números (el
  agujero fijo) y da los instantes medidos (impacto, rotura de la arena) en el mismo paso.

## 4. Clips e instantes (`bramavidrio_clips.json`, 30 fps; «en el sitio»: el agujero no se mueve)

| Clip | Duración | Bucle | Instantes (s) y medidas |
|---|---|---|---|
| `reposo` | 3,0 | sí | respira (aletas, cuello y boca), vaivén y mirada; cabeza a 9 m de alto y 9,2 m delante |
| `subterraneo` | 2,0 | sí | bajo la arena (eje a −2,4 m): olas que viajan hacia la cola; asoma la hilera de aletas |
| `aviso` | 1,6 | no | vibración 0,1 – 1,2: sube 0,4 m, aletas erizadas y vibrando, la luz bajo la arena; acaba como `subterraneo` |
| `emerger` | 2,8 | no | rompe_arena 0,233 · pico 0,867 (columna de 13 m) · erguido 2,45; acaba en `reposo` |
| `rugido` | 2,6 | no | inicio_rugido 0,55 · pico_rugido 0,8 (boca a 68°, aletas +28°) · fin_rugido 1,9 |
| `ataque` (embestida) | 2,3 | no | se retrae hasta fijado 0,55 · impacto 1,0 (se estira y muerde abajo); alcance 11,5 m |
| `ataque_sismico` | 3,8 | no | erguido 1,0 (20,4 m) · rugido 1,15 · caída 2,1 · impacto 2,533 (cae a lo largo); alcance 17 m |
| `ataque_aliento` | 3,6 | no | apertura 0,3 · inicio_succion 0,45 · carga_max 1,6 · descarga 1,85 · fin_descarga 2,6; chorro de 11 m |
| `herida` | 1,0 | no | golpe 0,1 |
| `derrota` | 3,4 | no | dolor 0,5 · caída 1,6 (se desploma de lado y rueda) · apagado 3,0; se hunde a medias y se queda |

- **Medidos en el propio clip:** los impactos y la rotura de la arena se calculan sobre el hocico y la barbilla (por
  ejemplo, el impacto de la embestida es el fotograma en que la barbilla llega más lejos).
- **Empiezan y acaban en la pose del reposo** (comprobado en Godot): todos los clips sin bucle salvo `aviso` (acaba como
  `subterraneo`), `emerger` (solo acaba en el reposo) y `derrota`.

## 5. Godot: `enemigos/bramavidrio/bramavidrio_3d.gd`

**Interfaz de los enemigos 3D** (la de `zarzalin_3d.gd` y `coloso_falla_3d.gd`):
- `ruta_modelo`, `rutas_extra`.
- `reposo`, `andar`/`correr` (se queda en su agujero), `cansada`, `herida`/`recibir_golpe`, `morir`/`derrota`.
- `victoria` (ruge), `revivir`, `entrada` (emerge), `mirar`/`mirar_frente`.
- `lanzar_magia`/`fin_magia`/`punto_magia`, `preparar_golpe`/`golpear`/`fin_golpe`.
- `play`, `duracion`, `tiempo_impacto`, `alcance`.
- Constantes `ALTURA` y `CENTRO`.

**Lo nuevo:**
- `atacar(ataque, al_impactar)`, con «embestida», «sismico», «aliento» y sus alias del combate: `embestida_espinosa`,
  `colmillo_lateral`, `golpe_fuerte`, `terremoto`, `chorro`…
- `embestida()`, `sismico()`, `aliento()` y `golpe_fuerte()`.
- `avisar(ataque)` / `cargar(ataque)`: el aviso se queda repitiendo su tramo y el ataque sigue desde ahí sin repetirlo.
- Para la exploración: `emerger()`, `rugir()`, `subterraneo()` y `vibrar()`.
- Puntos en el mundo: `cabeza()` (hocico), `boca()`, `nucleo()`/`corazon()` (garganta) y `centro()`.

**Señales:**
- `aviso`, `impacto` (una vez por ataque).
- `succion`, `descarga`, `fin_descarga`.
- `rompe_arena`, `rugido_pico`, `caida`.
- `ataque_terminado` y `clip_terminado`.

**Decisiones:**
- **Escala automática.** `_crear_rig_3d` pone su cámara ortográfica **a 6 m del origen**: a escala 1, la cabeza (9 a
  17 m por delante) quedaría detrás de la cámara. Por eso el combate usa `ESCALA_COMBATE` = 0,32 y la exploración, 1.
  Comprobado: ningún punto queda detrás de la cámara en ningún clip.
- **Versión según el perfil** (`calidad_proto.actual()`), aunque `combate.gd` le pase la ruta del GLB alto. Para forzar
  una, se usa `calidad`.
- **Recorte de lo enterrado,** por defecto en el combate (`recortar_suelo`).
- **Los instantes van como constantes** (`INSTANTES`, `ATAQUES`, `ALCANCES`), porque el `.json` no entra en el APK
  (`include_filter` vacío). La prueba comprueba que coinciden con el JSON.

### Entrada de `MODELOS` que hace falta en `combate.gd` (no la he puesto)

```gdscript
	# V12: Bramavidrio, modelo definitivo (animaciones; enemigos/bramavidrio/, fuente/crear_bramavidrio.py). El guion se
	# escala solo a 0,32 (la cámara de _crear_rig_3d está a 6 m); recorta lo enterrado; versión según el perfil.
	"bramavidrio": {
		"tipo": "3d", "esc": 0.9, "script": "res://enemigos/bramavidrio/bramavidrio_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/bramavidrio/bramavidrio.glb"],
		"vp": Vector2i(1800, 1400), "alto_vista": 7.0, "centro_y": 2.3, "barra_y": 498.0, "centro_3d": 1.9,
		"respaldo": "bramavidrio2d"},
	"bramavidrio2d": {"tipo": "imagen", "imagen": "res://enemigos/bramavidrio/bramavidrio.png", "cadera": Vector2(160, 470),
		"tam": 1.15, "barra_y": -150.0, "centro_y": 60.0},
```

- **Encuadre** (medido en `prueba_bramavidrio_modelo`): 180 px por metro en la escena, que con la escala 0,32 son 58
  px por metro del gusano. El reposo ocupa 507 px de alto. En la ventana 3D los pies caen en y = 1150 y lo alto del
  reposo en y = 587.
- **Qué cabe:** reposo, rugido, embestida, aliento, herida, emerger y derrota caben enteros. El sísmico se sale por
  arriba **a propósito**: se alza por encima de la pantalla.
- **`barra_y`** sale de la fórmula de la prueba del Coloso (lo alto × esc − 30); **hay que comprobarla en un combate
  de verdad**. `centro_3d` = el cuello a escala 0,32.

**Cómo lo lleva hoy el combate** (y qué hay que cambiar):
- `_animar_golpe` elige la rama de Zarzalín (`_anim_zarzalin`) porque el guion tiene `avisar()`, que la orden pedía.
  Esa rama desplaza el sprite hacia el objetivo y lo devuelve. A un gusano con agujero no le va.
- **Propuesta,** antes de la rama de Zarzalín:

  ```gdscript
  elif _p3d(origen) != null and _p3d(origen).has_method("aliento"):        # Bramavidrio: ataca desde su agujero
      await _anim_guardian(origen, impacto, str(origen.get("ataque_3d", "embestida")))
  ```

- Con `ataque_3d` = "embestida_espinosa", "colmillo_lateral", "golpe_fuerte"… funcionan los alias. Para usar el
  sísmico y el aliento, la IA tendría que pedir «sismico» y «aliento».
- La personalidad «embiste» ya llama a `p.avisar("embestida_espinosa")`, que funciona (alias).
- **El texto actual** «se hunde en la arena: ¡va a emerger bajo X!» ya no describe el aviso, que es retraerse y fijar.
  Que narrativa y combate decidan si cambian el texto (no lo he tocado).

## 6. La exploración: `zonas3d/mar_cristal/gusano.gd` (la interfaz pública no cambia)

Se usa el modelo definitivo si existen el guion y el GLB. El provisional sigue entero en `_modelo_provisional()` y se
recupera con `Engine.set_meta("bramavidrio_provisional", true)`. `_modelo_gusano()` mantiene su nombre: devuelve el
modelo definitivo en reposo y, si no está, el GLB de `modelos/desierto` o el provisional.

**El recorrido:**
1. **Aviso:** el gusano va bajo el surco con `vibrar()` y luego `subterraneo`, mirando a Kael. Solo asoma la hilera de
   aletas y siguen el bulto de arena (`_lomo`) y el polvo. Si Kael sale de la arena blanda, se hunde 4 m y desaparece.
2. **Aparición:** sale a 11 m de Kael **al este-noreste**. Desde la cámara se ve de tres cuartos, con la silueta en S, y
   nunca tapa a Kael.
3. **`emerger`:** al romper la arena estalla el polvo y suena el rugido con sacudida. Después viene `rugido`.
4. **Cámara:** sobre la que coloca la región, se aleja a 34 m y baja a 20° hacia un punto entre Kael y el agujero, con
   una mezcla suave de 0,9 s, sin giros. Vuelve sola antes del combate, que empieza 0,9 s después del rugido (unos 6,3 s
   en total).
5. **Si ya fue vencido:** se hunde por su agujero y vuelve al descanso.

**Corregido mirando la secuencia real** (antes y después en las capturas):
- La cabeza asomaba demasiado en el surco: ahora va 0,5 m más honda y sin levantar el hocico.
- Al salir justo detrás de Kael se le veía de frente y no se leía su forma: ahora sale al este-noreste.

## 7. Pruebas (aisladas, sin ventana y `--fixed-fps 30`)

- **`prueba_bramavidrio_modelo`** (nueva; línea en `lista_pruebas.txt`): SUPERADA, 255 comprobaciones y 0 fallos.
  - Los tres GLB: 41 huesos, los 10 clips con su duración, giro de los 36 que se mueven y escala de los 4 de datos,
    superficies, presupuesto y texturas comprimidas con mipmaps.
  - El JSON frente al guion.
  - Bucles y finales.
  - El chorro y el montículo.
  - Los ataques: un impacto en su ancla, también desde el aviso.
  - Las señales del aliento, herida, derrota y clips de la exploración.
  - El encuadre.
- **Última pasada** (`D:\REBELUM_diagnostico\pruebas\2026-11-11_153308\resumen.md`): `prueba_bramavidrio_modelo`,
  `prueba_mar_cristal` y `prueba_integridad`, las tres SUPERADAS. Partida y datos reales sin cambios.
  - La advertencia «5 resources still in use at exit» de `prueba_mar_cristal` ya salía en pasadas anteriores, de vez en
    cuando: no es de este trabajo.
- **`fotos_bramavidrio`** (nueva, con ventana; línea en la lista): FALLOS 0.

**Importación aislada:** la primera vació los directorios de Dialogic en `project.godot`, como avisaba la orden. Lo
restauré y volví a importar. `project.godot` está sin cambios.

## 8. Capturas (`D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio\`)

- **Godot con ventana (datos aislados):**
  - `combate_alto.png`, `combate_medio.png` y `combate_bajo.png`: 12 instantes clave con la cámara del combate.
  - `region_alto.png`, `region_medio.png` y `region_bajo.png`: aviso, surco, rotura de la arena, subida, cuelga, baja,
    rugido y vuelta de la cámara, en el Mar de Cristal real.
  - Cada foto suelta, en la misma carpeta.
- **Blender (`blender\`):**
  - `siluetas_variantes_cabeza.png` y las seis siluetas sueltas.
  - `clips_frente_1.png` y `clips_frente_2.png` (todos los clips), `cabeza.png` (reposo, rugido y aspirando, con la
    garganta encendida), `subterraneo.png` y `perfil.png`.
- **Antes y después** (renders intermedios en la carpeta temporal de la sesión; los del proyecto ya muestran lo
  corregido):
  - la cabeza plana por la tabla invertida;
  - la piel a rayas por WebP;
  - la cabeza que asomaba en el surco;
  - la aparición de frente.

## 9. Lo que NO está terminado o no está comprobado

- **El combate no está enganchado:** falta `MODELOS`, la rama de ataque y que la IA use el sísmico y el aliento. No hay
  capturas del combate de verdad, solo de su cámara. La tarea es del especialista de combate.
- **Nada probado en el Redmi** y nada de rendimiento medido. La orden pide no medir con otros especialistas trabajando.
  Hay que medir:
  - la ventana 3D del combate: 1800 × 1400, dibujada al 75 % (en el móvil, al 70 %), del orden de la del Coloso;
  - la piel con `discard` en el combate;
  - las sombras del gusano en la región en el perfil alto.
- **El cuerpo bajo el surco no sigue las dunas:** solo toma la altura de la cabeza. En pendientes fuertes, la cola o las
  aletas pueden asomar o quedar enterradas de más. No lo he visto en las capturas, pero no está comprobado en todo el
  sector.
- **Sonido:** se reutilizan `gusano_temblor` y `gusano_rugido`. El sísmico y el aliento no tienen sonido propio (le toca
  al especialista de sonido).
- **El chorro del aliento** es una malla aditiva sencilla. Unas partículas o un destello en el impacto los pondría el
  combate.
- **`pruebas/herramientas/foto_bramavidrio.gd`** (la foto 2D del combate) llama a `_modelo_gusano()`. Si se vuelve a
  ejecutar, fotografiará el modelo nuevo a escala de combate. No la he ejecutado ni tocado.
- **Procedencia:** falta la fila en `docs/recursos.md`, que no es mío. La fila exacta que pido:

  | Recurso | Origen | Licencia | Uso | Entregable |
  |---|---|---|---|---|
  | Bramavidrio definitivo: `enemigos/bramavidrio/bramavidrio{,_medio,_bajo}.glb`, `bramavidrio_piel{,_medio,_bajo}.webp`, `bramavidrio_clips.json` y sus sombreadores | Obra propia: modelo, textura, esqueleto y clips generados con Blender 5.2.3 por `fuente/crear_bramavidrio.py` | Propia | Combate fijo «mc_bramavidrio» y exploración del Mar de Cristal | Sí |

## 10. Siguiente paso propuesto

1. **Combate:** añadir la entrada de `MODELOS`, la rama `has_method("aliento")` y los ataques «sismico» y «aliento» en
   la IA. Luego, capturas del combate de verdad y ajuste de `barra_y`.
2. **Medida en el Redmi** (la programa el coordinador), en los tres perfiles: el combate con el gusano y la aparición en
   la región.
3. **Narrativa:** actualizar §4 («largo», no «corto y grueso») y el texto del aviso del combate.

## 11/11/2026, 16:05 · Pasada 2 de calidad (encargo del coordinador: «realmente convincente»)

Mismo esqueleto de trabajo y misma rama (`claude/v12-bramavidrio`). **No cambian:**
- los nombres de los 10 clips y sus instantes (el JSON solo cambia en los huesos y los triángulos; la prueba compara
  guion y JSON);
- la interfaz de `bramavidrio_3d.gd`: solo añade `escala_monticulo`;
- los tres LOD y los presupuestos.

No he tocado `combate.gd` ni nada del combate. La copia del especialista de combate, que salió de `b4157a6`, sigue
siendo compatible.

**La entrada de `MODELOS` de §5 queda sustituida** por la de «Encuadre del combate» de esta sección.

### Commits de la pasada 2

| Commit | Qué |
|---|---|
| `dec5c04` | `fuente/crear_bramavidrio.py`: la geometría, los clips y la paleta nuevos |
| `735aa74` | los GLB y las texturas regenerados y `bramavidrio_clips.json` |
| `1d774da` | `bramavidrio_piel.gdshader` (máscara de basalto) y `bramavidrio_3d.gd` (montículo en el combate) |
| `5221d71` | `prueba_bramavidrio_modelo.gd`, `fotos_bramavidrio.gd`, `fotos_bramavidrio_combate.gd` (nueva) y `lista_pruebas.txt` |
| este | esta sección |

### Qué cambia (por orden de impacto)

1. **Cabeza:** el cráneo es ahora una cuña que baja hasta la cuchilla, sin el «labio» claro que lo hacía parecer un
   pico de pato. Encima lleva:
   - **tres placas de basalto superpuestas**, con bisel y grosor: la frontal, la central y la de la nuca, que se abre
     hacia los lados y nunca hacia arriba (no es una corona);
   - **dos arcos superciliares** gruesos y **placas en las mejillas**. Los seis ocelos quedan hundidos entre ellos y
     brillan desde la sombra.
2. **Boca:**
   - **Colmillos curvos e irregulares** de hueso y de cristal (este, emisivo): arriba cuelgan por fuera de la mandíbula
     y abajo, delante, salen como defensas; cuatro grandes colmillos en las esquinas y una fila interior en el alto.
   - **Dos mandíbulas laterales** (huesos nuevos `mandibula_izq` y `mandibula_der`, hijos de `mandibula`): hojas curvas
     de basalto a los lados del cazo, con gancho y púas de cristal. Se abren hacia fuera unos 40° al rugir, 46° al
     escupir y 34° al morder; se cierran en el impacto. No forman un anillo de pétalos: la boca sigue siendo cráneo y
     cazo.
   - **Anillos de placas que muelen** hacia dentro de la garganta, que se encienden con ella. Al aspirar, la garganta
     sube a 3,0 y se ve.
3. **Cuerpo:**
   - **Escamas de pangolín:** en el alto, 2 filas × 3 placas por anillo; en el medio y el bajo, 1 × 3. La dorsal monta
     sobre las laterales; el borde trasero de cada placa se levanta y acaba en punta, y monta sobre la siguiente, lo que
     da una silueta dentada. Los cantos llevan bisel y las juntas, arena metida.
   - **Vientre** más blando, estriado y estrecho (las laterales bajan hasta 125°), con surcos poco hondos.
   - **Racimos de cristal irregulares:** de 1 a 3 por anillo, más 5 grandes a lo largo del lomo, con cristales de
     tamaños, inclinaciones y tonos distintos. Sustituyen a la hilera regular de aletas.
4. **Material y color:**
   - basalto casi negro azulado en placas, cabeza y mandíbulas, con cantos gastados en gris y arañazos;
   - arena ocre en juntas, surcos y poros;
   - turquesa en las grietas, las cicatrices y los halos de los racimos.
   - El **alfa del color de vértice** es la máscara del «mineral» (1 en el basalto, 0,5 en los dientes y 0 en la carne
     y la arena). El sombreador da al basalto más reflejo (rugosidad 0,4 frente a 0,86) y borde de luz (`RIM`).
   - No horneé normales ni oclusión a textura: la oclusión va en los colores de vértice y en la pintura. Un mapa de
     normales costaría otra textura y tangentes en el Mali sin medirlo.
5. **Escala en el combate,** medida en la pantalla real: ver más abajo.
6. **`rugido` y `emerger`:**
   - **`rugido`:** toma aire, se enrosca hondo hacia atrás y abajo (anticipación), lanza la cabeza con sobrepaso en el
     pico (0,8), ruge con las mandíbulas abiertas, cierra pasándose hacia abajo y rebota.
   - **`emerger`:** la arena se abomba antes de romper (el montículo crece); sube; la cabeza cae por su peso por debajo
     del reposo, con un temblor en el golpe, y se asienta en dos vaivenes.
   - Los instantes no cambian.

### Triángulos, texturas y huesos

| Versión | Triángulos (antes → ahora) | Textura | GLB |
|---|---|---|---|
| alto | 16 380 → **19 359** (≤ 25 000) | 2048, WebP 458 KB | 2,82 MB |
| medio | 7 990 → **8 823** (≤ 12 000) | 1024, 182 KB | 2,23 MB |
| bajo | 3 594 → **3 124** (≤ 6 000) | 512, 68 KB | 1,87 MB |

- **Huesos:** 41 → **43**.
- **El bajo tiene menos triángulos** que antes: sus placas no llevan bisel. Gana identidad: tres placas por anillo,
  mejillas, colmillos y racimos.

### Encuadre del combate (medido con `pruebas/fotos_bramavidrio_combate.gd`, en pantalla de 1280 × 720)

**Por qué se veía pequeño:** con el encuadre de la pasada 1 (`vp` 1800 × 1400, `alto_vista` 7, `esc` 0,9 y el grupo 13
en (250, 60)), **el agujero caía en y = 942, por debajo de la pantalla.** Solo asomaba la cabeza (ver la comparación).

**Propuesta:** `pies_como` 0 deja el agujero exactamente en la posición del grupo. Es el mecanismo que ya usan los jefes
grandes en `_crear_rig`.

```gdscript
	"bramavidrio": {
		"tipo": "3d", "esc": 1.07, "script": "res://enemigos/bramavidrio/bramavidrio_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/bramavidrio/bramavidrio.glb"],
		"vp": Vector2i(1920, 1000), "alto_vista": 5.1, "centro_y": 1.45, "pies_como": 0.0, "centro_3d": 1.9,
		"respaldo": "bramavidrio2d"},
	# y en GRUPOS[13]: [["bramavidrio", Vector2(288, 600)]]   (el agujero cae en la pantalla en (186, 575))
```

**Medido** (con la escala del guion, 0,32, que no cambia):
- **Reposo:** 442 px de alto (el 61 % de la pantalla), de y = 133 a 575.
- **Rugido:** 451 px.
- **Lo más adelantado:** x = 555 en reposo; 668 en la embestida, que llega a los héroes; 854 en el impacto del
  sísmico, que cae entero delante de ellos (la interfaz se dibuja encima).
- **Fuera de pantalla:** el sísmico (hasta y = −302) y la columna de `emerger` (y = −153) se salen por arriba a
  propósito. El borde de la ventana 3D queda por encima de la pantalla y no se ve el corte.

**Coste de la ventana 3D:** 1920 × 1000, dibujada al 75 % (1440 × 750, 1,08 Mpx; en el móvil, al 70 %: 0,94 Mpx), del
orden de la del Coloso (0,96 Mpx). **Sin medir en el Redmi.**

**`barra_y`:** sin calcular. La herramienta no dibuja la barra de vida del modelo 3D (en sus fotos se ve la de la foto
2D); que la ajuste el especialista de combate.

**Ojo:** con este encuadre, el sprite del gusano empieza fuera de la pantalla por la izquierda y por arriba. Cualquier
cosa del combate que use `f["pos"]` del enemigo (acercamientos, la barra…) debe comprobarse con él.

**El montículo:** en el combate, a tamaño entero, volvía a parecer un plato naranja. Ahora va al 55 % y con tono 0,62
(`escala_monticulo` y `TONO_ARENA_COMBATE` en el guion).

### Pruebas (aisladas)

- **Última pasada** (`D:\REBELUM_diagnostico\pruebas\2026-11-11_160118\resumen.md`): `prueba_bramavidrio_modelo`,
  `prueba_mar_cristal` y `prueba_integridad`, las tres SUPERADAS. Partida y datos reales sin cambios.
- **`prueba_bramavidrio_modelo` comprueba ahora además:**
  - los 43 huesos;
  - el alfa mineral del color de vértice en las tres versiones (alto: 2539 vértices de basalto y 10 226 de carne);
  - que las mandíbulas laterales se abren 39,7° en `rugido`;
  - el encuadre nuevo: ningún clip se sale por los lados ni por abajo; `emerger` y el sísmico, solo por arriba.
- **`fotos_bramavidrio` y `fotos_bramavidrio_combate`:** FALLOS 0.
- **Finales de línea:** mis parches en Windows dejaban CRLF en algunos archivos; están devueltos a LF.

### Capturas (`D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio\pasada2\`)

- **Comparaciones:**
  - `comparar_cabeza_antes_arriba_despues_abajo.png`;
  - `comparar_clips_antes_arriba_despues_abajo.png`;
  - `comparar_combate_real_antes_izq_despues_der.png`: la foto 2D de antes; el modelo nuevo con el encuadre de la
    pasada 1 (el agujero fuera de pantalla); la propuesta.
- **`antes\`:** las de la pasada 1.
- **`encuadre\`:** el combate real con cada encuadre y clip.
- **`combate_{alto,medio,bajo}.png` y `region_{alto,medio,bajo}.png`,** con sus fotos sueltas.
- **`blender\`:** la cabeza, todos los clips, el perfil y el gusano bajo la arena.

### Lo que todavía no convence o no está comprobado (sin adornos)

- **El vientre visto de frente** sigue leyéndose algo como una pila de anillos. Mejor que antes (más estrecho, oscuro y
  estriado), pero es la parte menos lograda.
- **En la región, a 34 m,** la bruma del desierto agrisa el basalto. La silueta se lee, pero el contraste del primer
  plano del combate no llega al plano general. No he tocado la niebla de la región, que no es mía.
- **Las juntas de arena** se ven naranjas y saturadas con la luz cálida del combate. Es lo pedido (arena incrustada),
  pero quizá convenga bajarlas.
- **Las mandíbulas laterales** son finas en reposo: impresionan abiertas, cerradas no tanto.
- **El chorro del aliento** sigue siendo un haz sencillo, sin partículas.
- **Sin normales horneadas.**
- **Las mejoras de `rugido` y `emerger`** solo las he revisado en fotogramas sueltos, no en vídeo ni a velocidad real.
- **Nada probado en el Redmi:** ni el coste de la ventana 3D ni el de los 19 k triángulos del alto con sombras.
- **El combate:** la entrada de `MODELOS`, `GRUPOS[13]` y `barra_y` son propuestas medidas en una maqueta del combate,
  no el combate jugado.
