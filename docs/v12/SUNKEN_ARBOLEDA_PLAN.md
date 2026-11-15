# Plan: llevar el cuidado de la muestra de Oakhaven a Sunken City, a la Arboleda Mítica y a los demás poblados

Situación de partida: repositorio `D:/Aethelgard_v12`, rama `claude/rebelum-v12` en el commit `2d7745d`. Para este plan solo he leído archivos: no he cambiado nada ni he ejecutado Godot ni Blender. Uso estas marcas: **[C]** canon, **[P]** propuesta sin aprobar, **[D]** decisión pendiente del usuario.

---

## 0. Lo que he comprobado en el código (y corrige o precisa los estudios)

| Comprobación | Dónde | Qué significa para el plan |
|---|---|---|
| Para apartar lo que tapa a Kael, el juego solo sabe volver transparente un `StandardMaterial3D`. Con cualquier otro material, `_material_transparente` devuelve `null` y no hace nada, sin avisar. | `prototipos/vista3d.gd:440-466` (`return null` en l.457-458) | Si las costillas y las casas de la Quilla pasan a los sombreados `calle_*`, dejarán de apartarse y taparán a Kael. Hay que resolverlo antes de integrar. |
| `casco.apartar` recibe la z de Kael y la de la cámara. Lo llama `sunken_3d.gd:411`. | `zonas3d/sunken/casco.gd:130-139` | Es el punto donde enganchar el ocultado de «coronas» (el arco alto de cada costilla). |
| Los faroles de la Quilla llevan halo en el aire, disco en el suelo y, en alto, hasta 4 luces omni. El 38 se salta: es la costilla que no alumbra. | `casco.gd:336-372` | Con la luz horneada sobran el disco del suelo y las omni de la Quilla. |
| Al abrir el juego se precarga **todo `res://`** salvo lo que está en `EXCLUIR` y en `APAGADOS`. `APAGADOS` asocia cada carpeta a un interruptor. | `recursos.gd:12-16`, `347-360`, `403-406` | Las carpetas nuevas deben entrar en `APAGADOS` con su interruptor, o se precargarán en Auditoría y en el editor. El PSS del Redmi ya está en 879 MB. |
| Exportación: el preset 0 (estable) excluye `zonas3d/*` (l.10). Los presets 1 (prueba 3D) y 2 (experimental) excluyen `zonas3d/muestra_calle/*` (l.37 y l.64). El 3 (auditoría, l.94) no excluye nada de eso. | `export_presets.cfg` | Los `calle_*.gdshader` **no existen** en las APK de prueba 3D ni en la experimental. Sunken solo puede cargarlos con `ResourceLoader.exists` y con el interruptor encendido. Las carpetas nuevas se excluyen igual que la muestra. |
| Los programas de la muestra se compilan durante la carga, pero solo si `banco_pruebas.permitido()` (Auditoría o editor). | `carga.gd:358-364` | Si Sunken usa **los mismos archivos** `calle_*.gdshader`, no habrá programas nuevos. Hay que comprobarlo en el registro `[carga]`. |
| El banco tiene interruptores de sesión (`METAS_SESION`, l.30, que se borran al salir, l.130 y l.177), selectores (l.256-269, como «Muestra: precalentar») y la lista `EXPLORAR` (l.88-104). `permitido()` está en l.113-114 y la partida aislada en l.120-135. | `banco_pruebas.gd` | Patrón para «apagado por defecto, solo de sesión». |
| Interruptores leídos desde `Engine.get_meta(...)` **o** desde los argumentos de la línea de órdenes. | `personajes/desierto/npc_desierto_3d.gd:36`; `recursos.gd:398` | Las pruebas pueden encender la Quilla con un argumento, sin tocar el banco. |
| Andable de la Quilla: `QUILLA = Rect2(38.4, 31.2, 3.2, 13.2)` y `RAMPA` (l.24-25). La tabla está en (38,75; 38,0) con radio 1,0 (l.68). Costillas en z 44, 38 y 32 (l.58-59). | `zonas3d/sunken/trazado.gd` | Por la pasarela (x 38,4-41,6) pasan las rutas de la prueba (x 40 y 38,8). **Los obreros no caben dentro**: van fuera de lo andable. |
| Rutas en línea recta de la prueba: `A_QUILLA` pasa por x=40 y la ruta de la tabla por (38,8; 40) → (38,8; 38,2). | `pruebas/prueba_sunken3d.gd:37-52` | Ni las rutas ni el trazado se tocan. |
| Casas colgadas: tramos z 32,5-37,5 y 38,5-43,5; las del oeste en x 32,6-37,6 y las del este en 42,4-47,6. Las chozas de la rampa: oeste 34,0-37,6 y este 42,4-46,0, en z 28,9-31,6. Tendederos en z 35,2 y 41,0. | `zonas3d/sunken/fuente/crear_sunken.py:518-544` | Entre la pasarela y las casas del este quedan solo **0,8 m**. El paso de babor (z 33,8-35,4) atraviesa la primera casa del oeste y el tendedero de z 35,2. Hay que confirmar que esa casa es `edif_casa_1`. |
| No hay posada en Sunken 3D. La 2D cobra `PRECIO_POSADA = 30` (`zona.gd:2371`), y `_posada` (l.2399-2412) solo hace `gastar_oro`, `grupo.curar_todos()` y `Sonido.efecto("posada")`. Los datos de la posada de Oakhaven (`ciudades/oakhaven_posada.gd`) sirven de patrón. | `zona.gd`; `oakhaven_posada.gd` | Una posada nueva puede reutilizar esas tres llamadas sin tocar `zona.gd`. |
| Al guardar dentro de la posada, Oakhaven 3D guarda la puerta de la calle. | `zonas3d/oakhaven_3d.gd:621-627` | Patrón para guardar en el Ancla Seca. Sin él, `_sitio_libre` (`sunken_3d.gd:228-238`) mandaría a Kael al muelle. |
| La isla: `_ready` (l.101-117) llama a `guardar_posicion()` y a `Progreso.guardar(scene_file_path)`. `_se_anda` está en l.390-400, `_poner_z` en l.404-411 y `guardar_posicion` en l.507-509. Las `const` están en l.16-25. | `isla.gd` | Se puede heredar de la isla (`extends "res://isla.gd"`) sobrescribiendo `_se_anda`, `_poner_z` y `guardar_posicion`. En el banco, la partida aislada guardaría la ruta de la escena nueva: aceptable, porque el banco borra su archivo al salir. |
| Música: `"res://isla.tscn"` → `"viento"`. | `musica.gd:121-122` | Una escena nueva con otra ruta **no** tendría música de viento: hace falta una línea en `musica.gd`. |
| `render_isla.gd` recibe el modelo como argumento (`<res://modelo.fbx> <carpeta> <ancho> <trozos x/y> <inclinación> <pasada>`). | `pruebas/herramientas/render_isla.gd:7` | Sirve para renderizar el interior. Falta comprobar que acepta `.glb`; si no, se exporta FBX. |
| Diseño de «Una flor para Lumi»: el premio es **un dibujo de Lumi** (nota en el Diario). La Cinta de Lumi es otra cosa, el «regalo de Lumi» (`equipo_extra.gd:109-113`), y sigue en `FUERA` (`hallazgos.gd:51`). | `docs/diseno/ciudades_y_lugares.md:450-456` | El estudio mezclaba las dos: la Cinta queda como [D]. |
| La lavanda de los Pastos ya se usa en `oak_lavanda` (Rosa la lleva al Árbol). | `ciudades/oakhaven.gd:158-160`, `330-334` | Qué flor recibe Lumi es [D]: o una segunda lavanda, o la flor de Rosa. |
| Frases de Ilia, Orun, Lumi y Vex: «Apareció la misma noche que la niebla», «nunca he bajado», etc. | `isla.gd:26-43` | Son [C] y no se tocan. |
| Oficios de chibi que ya existen: alquimista, anciana, anciano, barrendero, campesina, campesino, guardia, herrero, mercader, nina, nino y viajero. «tarea» es el clip de cada oficio: el del herrero martilla, el del viajero ajusta. | `personajes/npc_v12/`; `fuente/crear_npc_chibi.py:17-20` | No hay marinero ni clip «halar». En la fase A se usan las tareas que ya existen, con atlas nuevos. |

---

## 1. Lo que se traslada de la muestra y lo que no

**Se traslada el método**, que es lo que el usuario aprobó:
- pasadas en orden: composición → arquitectura → materiales → iluminación → atrezo → integración → optimización, con capturas de antes y después en las mismas cámaras;
- kit generado por guion con semilla fija;
- luz horneada (mapa de luz para lo grande, vértices para lo menudo), sondas para Kael y sombra de contacto;
- cero luces dinámicas en bajo y medio, y presupuesto medido en el Redmi.

**No se traslada**:
- la paleta ocre de Oakhaven;
- la cámara de 25° de la muestra (Sunken mantiene su cámara de 50° a lo largo del barco, `trazado.gd:81`);
- la técnica 3D a la Arboleda.

**Sombreados**: se **referencian** los archivos `zonas3d/muestra_calle/calle_*.gdshader`, nunca se copian. Una copia añadiría programas que compilar (1,26 s en negro en el Redmi, MUESTRA §7.c). A cambio, cualquier cambio futuro en esos sombreados obliga a repetir las capturas de la muestra.

---

## 2. Sunken City: «La Quilla, de la costilla 44 a la rampa»

### 2.1 Tramo
- **Fase A, la Quilla**: `QUILLA` + `RAMPA` (z 28,8-44,4), de la salida de la cubierta de popa a la subida a la Cubierta Mayor. Motivos:
  - es la calle principal, con la silueta propia de Sunken (las costillas en arco);
  - concentra el arte más provisional (las casas colgadas);
  - es el tramo más caro: 72 llamadas en bajo, 90-94 en medio y 134 en alto (`SUNKEN_3D_V12.md:165-194`);
  - y es donde la luz horneada sirve al juego: la costilla 38 queda **sin charco de luz** entre la 44 y la 32, así que el secreto de la tabla se lee con la vista.
- **Fase B, conexión útil**: el **paso de babor**, que lleva a la posada **El Ancla Seca** [P]. Recupera la POSADA que la 2D tiene y la 3D perdió.

### 2.2 Qué se construye: identidad de «ciudad dentro de un barco»
- **Base**:
  - un guion nuevo, `zonas3d/sunken/quilla/fuente/crear_quilla.py` (Blender 5.2.3 en segundo plano);
  - **importa `zonas3d/sunken/modelos/sunken.glb`** como base, sin importar `crear_sunken.py`, que llama a `construir_sunken()` sin guarda en l.896-897;
  - quita los grupos de la Quilla (`edif_casa_*`, `bajo_casa_*` y las costillas 44, 38 y 32) y pone el kit nuevo;
  - fuera de la Quilla solo añade UV2 y luz horneada, para que no haya costura de luz con la popa ni con la cubierta.
  - **COMPROBAR primero** qué nodos llegan separados en el GLB, porque `casco.gd:71-78` monta una malla por material. Si la Quilla llega fundida con el resto, el plan B es ejecutar el guion de Sunken dentro de Blender con `construir_sunken` parcheado en memoria, sin tocar el archivo.
- **Kit**:
  - cuaderna doble con baos, cartelas y flejes de hierro, y percebes y verdín en la línea de flotación;
  - tracas con juntas de brea;
  - pasarela sobre caballetes, con huecos donde asoma la quilla;
  - casas colgadas hechas con restos del barco: portas de cañón como ventanas, tapas de escotilla como puertas, toldos de vela remendada, escalas de gato, motones, cabos con comba y estufas de hojalata;
  - faroles de barco;
  - empalme con abrazaderas en el trozo que falta de la costilla 32 (`crear_sunken.py:257`, `rota=(0.08,0.17)`);
  - siluetas: una cabria de pluma, ropa tendida y velas-toldo inclinadas.
- **Paleta propia** (`ciudades_y_lugares.md:384-392`):
  - madera blanqueada `#CDB79A` y hueso `#E3D5BC`;
  - hierro oxidado `#8A4B2A` y cobre con verdín `#4E9C8A`;
  - lona `#EFE6D2`;
  - sombras verde azulado `#24484F`, el rebote de la laguna.
  - Se conserva el ambiente frío de `sunken_3d.gd:162`, para no confundirla con la tarde ocre de Oakhaven (`BARRIO_OAKHAVEN_PLAN.md:47`).
- **Texturas**: pintadas por código, 512² cada una (madera blanqueada, tablazón embreada, lona, hierro y cabo).
- **Horneado**:
  - Cycles, con el mismo sol y cielo de `sunken_3d.gd:155-198`; el plano de la laguna entra como rebote turquesa en el intradós;
  - mapa de luz de 1024 en bajo y de 2048 en medio y alto; las piezas pequeñas, a vértices;
  - el farol 38 no existe: su costilla queda a oscuras;
  - las sondas se escriben en `quilla_luz.json`, con el formato que lee `muestra_calle.gd:590-647`.
- **Integración** (`quilla.gd`):
  - `ShaderMaterial` con `calle_estatico`, `calle_vertice` y `calle_brillo`, cargados por su ruta;
  - sondas y sombra de contacto **solo para Kael**, como en la muestra;
  - Lya y Garon se tiñen con la sonda y quedan sin sombra de contacto: es [D] (ver 2.9);
  - **sin transparencias**: cada costilla se parte en «patas» y «corona», y la corona se oculta (`visible=false`) cuando queda entre la cámara y Kael. Se engancha en `casco.apartar`. La sombra de la corona ya va horneada en las tablas;
  - se conservan los nombres de ancla `costilla_<dm>`, `edif_`, `bajo_`, `ancla_farol_44/32` y `farol_38` sin luz (`prueba_sunken3d.gd:242-249`).

### 2.3 Actividad: «la cuadrilla de la Quilla» [P]
Trabajan para la proa en obras, un texto que ya existe (`ciudades/sunken.gd:60`): laguna → Quilla → proa. **Ninguno de los tres pisa lo andable.**

| Obrero | Sitio (fuera de lo andable) | Figura y movimiento | Objetos |
|---|---|---|---|
| Calafate | Plataforma de la casa este, x ≈ 42,6, z 40-41,5 (el pasamanos queda en 41,6) | Oficio `herrero`, clip `tarea` (martillar); persona nueva `calafate` | Mazo, hierro de calafatear, olla de brea; el humo solo en alto |
| Carpintera de ribera | Andamio en el hueco x 36,8-38,2 / z 31,6-32,8, junto a la costilla 32 rota. **COMPROBAR en Blender** de qué lado está rota | Oficio `herrero`, clip `tarea`; persona nueva `carpintera` | Andamio, tablón, abrazaderas a medio poner |
| Dos marineros | Sobre la choza este de la rampa (x 42,4-46,0, z 28,9-31,6), con la cabria | Oficio `viajero`, clip `tarea` (ajustar) en la fase A; clip `halar` más adelante | Un fardo de tablas que sube y baja en bucle de 10-14 s con un tween, y el cabo que se estira con escala. **COMPROBAR en `fotos_sunken3d`** que el agua se ve desde la cámara de la Quilla. Si no, el fardo sube de la Quilla a la Cubierta (1,2 m) |

- **Lista propia `obreros`**, no `vecinos`. Así no entran en `_prohibido` (`sunken_3d.gd:206-212`) ni en las 11 rutas.
- `npc_chibi.avanzar` solo cuando se ven.
- Su contacto con el suelo se hornea como oclusor en Cycles, y su sonda se calcula una sola vez.
- Sonido con lo que ya hay: `madera_1-4`, `puente_cruje` y `viento_cuerdas`.
- Una frase por aviso, de 110 letras como máximo. Las que rozan el secreto solo salen tras `paga_encontrada()`.
- Sin misión nueva. El microencargo «Brea para la Quilla» (premio ≤ 100) es [D].

### 2.4 Conexión útil (fase B): paso de babor → El Ancla Seca [P]
- **Paso andable** `PASO_BABOR = Rect2(22.0, 33.8, 16.4, 1.6)`:
  - sale en ángulo recto de la Quilla entre las costillas 32 y 38 (como pide `trazado.gd:9-11`);
  - cruza las tracas por una porta abierta en x ≈ 29,6;
  - acaba en la puerta este de la posada (x ≈ 21), que coincide con el diseño (14-21, 29-35; `ciudades_y_lugares.md:314`).
- **El paso se define en `quilla/babor.gd`, no en `trazado.gd`**. `sunken_3d._prohibido` lo consulta solo con el interruptor encendido. Con la región apagada, nada cambia.
- La casa colgada del oeste del primer tramo se rehace dentro del kit para dejar el hueco. El punto (28,0; 40,0), que la prueba exige prohibido, sigue prohibido.
- **Cámara propia** en el paso, mirando de este a oeste. Aquí sí sirve la receta de la muestra.
- **Interior**: sala aparte con origen lejano y fundido, con el patrón de `zonas3d/oakhaven/posada3d.gd`.
  - Kit pequeño horneado: hamacas colgadas de una costilla, el ancla clavada junto a la puerta y una estufa.
  - Doña Coral [P], con atlas propio de chibi; el gato Almirante, de atrezo fijo.
  - Dormir: `Inventario.gastar_oro(30)` + `grupo.curar_todos()` + `Sonido.efecto("posada")`. El precio, 30, es igual a `zona.gd:2371` hasta que el usuario decida entre 30 y 40 [D].
  - `guardar_posicion` dentro guarda la puerta de fuera en `pos_3d` (patrón de `oakhaven_3d.gd:621-627`).
- **Alternativa barata**, si la fase B se pasa de presupuesto: puerta en el borde oeste de la Quilla, z ≈ 34,5, sin paso.

### 2.5 Qué NO se toca
- **Canon y progresión**:
  - no se crea ninguna clave de partida (`progreso.gd:60-63`); el estado va en `hitos`, `mazmorras` y `cofres_abiertos`;
  - ningún DETALLE nuevo en el lugar 5, porque volvería a ocultar la página del Acto II (`progreso.gd:24-53`); `sunken_contratos` conserva su id;
  - la Astraea solo se ve bajo la lona: ni se nombra ni se trabaja hacia el dique; no se tocan las islas 7 y 8 ni el viaje rápido (`mapa.gd:36`, `610`);
  - la escotilla sigue «cerrada hasta la marea baja» y la mazmorra del Casco no se toca;
  - nada de Érebo, corazones ni recuerdos (D-033); nada con forma de brazalete (es de Calid); nada de que Garon sirviera en la Compañía;
  - Ulla, Brea y «El sello de la capitana» no cambian;
  - la costilla 38 sigue a oscuras.
- **Archivos**:
  - `trazado.gd`, `crear_sunken.py`, `sunken.glb` y `sunken_ligero.glb`;
  - `ciudades/sunken.gd`, `datos/encargos_sunken.gd` y los diálogos;
  - `zona.gd`, `mapa.gd`, `progreso.gd` y `modo3d.gd`;
  - los `calle_*.gdshader`, que tampoco se copian.
- **Técnica**: la cámara de la Quilla (50°, sin giro), el camino 2D (`prueba_sunken3d_apagada`) y la región, que sigue «en pruebas».

### 2.6 Archivos nuevos y únicos cambios fuera de la carpeta
**Nuevos**, en `aethelgard/zonas3d/sunken/quilla/`:
- `fuente/crear_quilla.py`
- `fuente/crear_ancla_seca.py` (fase B)
- `modelos/quilla.glb` y `quilla_ligero.glb`, si hace falta, con la regla de `recursos.gd:296-300`
- `modelos/ancla_seca.glb`
- `texturas/*.png` (512²)
- `luz/quilla_luz_1024.png`, `luz/quilla_luz_2048.png` y `luz/quilla_luz.json` (escala y sondas)
- `quilla.gd`: interruptor `activado()`, materiales, sondas, sombra y coronas
- `obreros.gd`: datos [P] y frases
- `babor.gd` y `ancla_seca.gd` (fase B)

Pruebas nuevas:
- `aethelgard/pruebas/prueba_sunken_quilla.gd`
- en la fase B, `aethelgard/pruebas/prueba_sunken_babor.gd`

Documento: `docs/v12/SUNKEN_QUILLA.md`.

**Cambios fuera de la carpeta**, todos pequeños y sin efecto con el interruptor apagado:
1. `zonas3d/sunken/casco.gd`:
   - si `Quilla.activado()`, monta el kit en lugar de la geometría de la Quilla;
   - salta `halo_suelo` y las omni de los faroles de la Quilla (l.354-372);
   - `apartar` oculta las coronas (l.135-139).
2. `zonas3d/sunken_3d.gd`:
   - llama a `quilla` para las sondas y la sombra de Kael en `_process`, junto a l.405-411;
   - `obreros.avanzar` solo si se ven;
   - en la fase B: `_prohibido` (l.206) con `babor`, la cámara del paso y el `guardar_posicion` de dentro (l.673-678).
3. `banco_pruebas.gd`: `"sunken_quilla_v12"` en `METAS_SESION` (l.30), un selector «Sunken: Quilla horneada (solo en el banco)» junto a l.267-269 y una entrada en `EXPLORAR` (l.95-97).
4. `recursos.gd`, en `APAGADOS` (l.347): `"res://zonas3d/sunken/quilla/": "sunken_quilla_v12"`.
5. `export_presets.cfg`: añadir `zonas3d/sunken/quilla/*` a `exclude_filter` de los presets 1 y 2 (l.37 y l.64).
6. `fuente/crear_npc_chibi.py`: **solo añadir** las personas `calafate`, `carpintera`, `marinero_1`, `marinero_2` y `coral`, que son atlas nuevos en `personajes/npc_v12/<oficio>/`. No se cambia ningún oficio ni clip existente, y se conservan los atlas anteriores. El clip `halar` queda para después.
7. `pruebas/lista_pruebas.txt`: las líneas de las pruebas nuevas.

### 2.7 Presupuesto móvil (Redmi, Mali-G57)
| Medida | Hoy (Quilla) | Objetivo |
|---|---|---|
| Llamadas de dibujo, bajo | 72 | ≤ 45 |
| Llamadas de dibujo, medio | 90-94 | ≤ 55 |
| Llamadas de dibujo, alto | 134 | sin empeorar |
| Primitivas, bajo | 25,7 mil | ≤ 90 mil (la muestra: 77 mil) |
| Luces omni en bajo y medio | halos | 0 |
| Transparencias **nuevas** | — | 0. Las existentes (`halo_aire`, laguna, brillo del brazalete en `sunken_3d.gd:596-609`) se revisan en el teléfono (MUESTRA §7-8) |
| FPS en el Redmi, bajo y medio | 30,3-30,4 | ≥ 30 sostenidos, 0 fotogramas perdidos en muelle → Quilla → rampa → (Ancla Seca) |
| FPS en alto | 16,8-18,1 | se mide; no se promete |
| PSS en bajo | 775-879 MB | ≤ 880 MB con la Ancla Seca incluida |
| Texturas nuevas | — | 5 × 512² más un mapa de luz (1024 en bajo, 2048 en medio y alto), VRAM comprimida con mipmaps. Se revisan las bandas del ETC2 |
| Carga | 1 fotograma de ≈ 1 s | igual, y **0 programas nuevos** en el registro `[carga]` |

### 2.8 Pruebas
**Automáticas.** Con el interruptor encendido basta añadir el argumento `sunken_quilla_v12`.
- `prueba_sunken3d`, **sin cambios**, en dos pasadas: apagada (regresión idéntica) y con `sunken_quilla_v12`. Las 16 secciones deben pasar en las dos.
- `prueba_sunken3d_apagada`, `prueba_restaurar_escenas`, `prueba_equipo_combate` (lugar 5), `prueba_encargos`, `prueba_diario_misiones` y `prueba_ciudad_datos`.
- **`prueba_sunken_quilla`** (nueva) comprueba:
  - apagada por defecto, y sin efecto fuera del banco (`permitido()` falso);
  - las anclas del GLB coinciden con `COSTILLAS_QUILLA`, `PIEZAS["tabla"]` y los faroles 44 y 32; `farol_38` no existe;
  - la sonda en (40; 38) tiene menos luz cálida que en (40; 44) y en (40; 32);
  - con Kael en z 40 y la cámara al sur, la corona de la costilla 44 se oculta y vuelve a verse al pasar;
  - ningún material de la Quilla es transparente en bajo ni en medio, y no hay `OmniLight3D` en bajo ni en medio;
  - ningún obrero está en lo andable ni a menos de 1,2 m de las rutas, y las 11 rutas siguen alcanzables;
  - frases de 110 letras como máximo y sin los términos vetados de `prueba_ciudad_datos.gd:28-39`;
  - con el interruptor apagado no queda en memoria ningún recurso de `zonas3d/sunken/quilla/`.
- **`prueba_sunken_babor`** (fase B):
  - ruta del muelle a la Quilla, al paso y a la puerta;
  - dormir cobra 30 y cura;
  - guardar dentro deja `pos_3d` en la puerta de fuera, y al cargar se aparece fuera;
  - salir de la posada, ir al mapa y volver;
  - (28; 40) y (44,5; 25,6) siguen prohibidos.

**Con ventana y medidas:**
- `fotos_sunken3d` con `perfil=alto|medio|bajo`, con y sin `sunken_quilla_v12`, con las mismas cámaras más la del paso. Dan las láminas de antes y después.
- `medir_sunken3d`: entrada en frío y con caché, en muelle, Quilla, cubierta y posada.
- `malioc` solo si cambia algún sombreado (no debería).
- Redmi: la APK de Auditoría se **copia por USB a Download** (D-065) y el usuario la instala.

**Con controles normales**, a mano:
- PC con teclado, mando y ratón; Redmi con cruceta y toque;
- del muelle hasta la rampa sin perder a Kael bajo ninguna costilla;
- hablar con cada obrero;
- «Mirar bajo la tabla» con y sin pista;
- cambiar de perfil en el banco;
- paso de babor, posada (dormir y guardar), salir al mapa y volver;
- pausar y reanudar la app dentro de la posada.

### 2.9 Fases y cuándo parar
| Fase | Qué incluye | Cuándo parar |
|---|---|---|
| **A1** | Kit, horneado e integración **sin obreros**, con capturas de antes y después | Si en el PC la Quilla en bajo pasa de 45 llamadas o la prueba de anclas falla, no se sigue |
| **A2** | Obreros y sonido | — |
| **A3** | Medida en el Redmi | Si bajo o medio bajan de 30 FPS, se recorta antes de seguir |
| **B** | Paso de babor y Ancla Seca | Solo si A3 cumple |

Abiertas para el usuario: la sombra de contacto de Lya y Garon (ampliar el sombreado a 3 posiciones cambiaría la muestra), el precio de la posada (30 o 40), los nombres [P] (Ancla Seca, Coral, Almirante) y el microencargo.

### 2.10 Encargo para UN agente (copia aislada)
> **Encargo: Sunken City, la Quilla horneada (fase A) y, si cumple, el paso de babor con El Ancla Seca (fase B). Todo experimental: solo Auditoría o editor, interruptor `sunken_quilla_v12` APAGADO.**
> Trabaja en una copia aislada propia, en la rama `area-sunken-quilla` creada desde `claude/rebelum-v12@2d7745d`. Solo commits locales: sin push, PR ni fusiones, y sin instalar nada en el teléfono. La APK se copia por USB a Download y la instala el usuario. Sin Hunyuan3D, sin descargas y sin GDExtension. Blender 5.2.3 y Godot 4.7.2, por guion.
> **Lee primero:** `D:/Aethelgard/CLAUDE.md` (protocolo); `docs/v12/MUESTRA_CALLE_OAKHAVEN.md` entero (método, §4 medidas, §7-8 transparencias y carga); `docs/v12/SUNKEN_3D_V12.md`; `docs/v12/REDMI_15_11.md:49-66`; `docs/diseno/ciudades_y_lugares.md:300-400` (Sunken: plano y paleta); `zonas3d/sunken/trazado.gd`; `zonas3d/sunken/casco.gd`; `zonas3d/sunken_3d.gd`; `zonas3d/sunken/fuente/crear_sunken.py:250-260` y `:518-544`; `zonas3d/muestra_calle/muestra_calle.gd:537-647` (sondas y sombra); `zonas3d/muestra_calle/calle_estatico.gdshader`; `prototipos/vista3d.gd:440-466`; `pruebas/prueba_sunken3d.gd:30-60` y `:220-250`; `recursos.gd:347-406`; `banco_pruebas.gd:30,88-135,250-270`; `export_presets.cfg`; `zonas3d/oakhaven/posada3d.gd` y `zonas3d/oakhaven_3d.gd:615-630` (fase B).
> **Haz:** el apartado 2 de este plan, con sus archivos nuevos en `zonas3d/sunken/quilla/` y SOLO los 7 cambios de fuera de 2.6. Pasadas: composición → arquitectura → materiales → iluminación → atrezo → integración → optimización, con capturas `fotos_sunken3d` de antes y después en cada una. Respeta 2.5 y el presupuesto de 2.7. Pasa todas las pruebas de 2.8 (`ejecutar_pruebas.ps1`, datos aislados).
> **Primero comprueba:** qué nodos trae `sunken.glb` por separado; qué casa ocupa z 32,8-37,2 al oeste; de qué lado está rota la costilla 32; si el agua se ve desde la cámara de la Quilla; y que el registro `[carga]` no muestra programas nuevos.
> **Entrega:** `docs/v12/SUNKEN_QUILLA.md`, con medidas de antes y después (PC, y el guion para el Redmi), láminas, decisiones [D] y lo que quedó provisional. No des por final nada que sea prototipo.

---

## 3. Arboleda Mítica: «La escalera de la Hospedería» (2D pintada, sin pasar a 3D)

### 3.1 Tramo
Recorrido: la plaza este (Lumi en 1700,1980) → la escalera pintada a la derecha del cristal (≈ 2030-2250, 2050-2160) → la terraza de la casa de la cúpula verde (andable en `isla_paso`, x 2288-2740 e y 1920-2176, pero **desconectada** hoy) → la puerta naranja (≈ 2330,2050; **COMPROBAR** en la máscara) → el interior de la **Hospedería del Peregrino** [P] (`ciudades_y_lugares.md:428-438`).

### 3.2 Qué se construye: el cuidado de la muestra traducido a su técnica
- **Conexión del exterior**:
  - `paso_extra.png` a 1/4, del mismo tamaño que `isla_paso`, se une a la máscara en un `_se_anda` sobrescrito;
  - la profundidad la da `isla_suelo`. **COMPROBAR** que en los píxeles de la escalera `suelo > 0`, porque `_poner_z` ignora el 0 (`isla.gd:404-411`);
  - la imagen pintada no se toca (`ciudades_y_lugares.md:417`), y no se puede volver a renderizar porque falta el modelo de Meshy.
- **Atrezo exterior** en la terraza: lino tendido, faroles de peregrino, macetas, un banco y un cántaro.
  - Se modela en Blender y se **renderiza con `render_isla.gd` y `preparar_isla.gd`**, con la misma cámara ortográfica a 38° y la misma luz: dorada `FFE2B0` a 1,25, relleno `7FA0D8` a 0,3 y ambiente 0,55 (`render_isla.gd:108-120`). Así el «revelado» es el mismo que el del fondo de Meshy.
  - Cada pieza lleva su color y su profundidad, y se tapa con el mismo `SHADER_TAPA` (`isla.gd:44-57`), para que Kael pase por detrás.
- **Interior**:
  - un solo trozo de 1536 px como máximo, con planta baja, el arranque de la escalera, camas con colchas de lino y ventanas a las nubes;
  - en el modelo, oclusión de rincones y luz de mañana por las ventanas, horneadas en Cycles a la textura; el render final, con `render_isla.gd`;
  - detalle en tres escalas: masa (muros, vigas y colchas); elementos (cántaro, faroles y libro de huéspedes); menudo (pan de higo, llaves colgadas y campanillas);
  - paleta de §2.3 (`:474-477`).
- **«Sondas» en 2D**:
  - `luz_tramo.png` a 1/4, la luz del suelo calculada a partir de la pasada de color, suavizada, para el exterior y el interior;
  - bajo los pies de Kael y de los NPC tiñe su `modulate`: más frío y oscuro bajo los aleros;
  - la mancha de contacto actual (`isla.gd:225-228`) más una sombra larga hacia abajo a la derecha, coherente con la luz.
- **Animación ligera**: el lino ondea con un sombreado de lienzo sobre su sprite pequeño, nunca a pantalla completa, y el cristal de la plaza late con un brillo aditivo, como el del portal.
- **Sonido**: pasos de madera dentro con `Sonido.pasos_2d` (`sonido.gd:1587`), viento y campanillas.
- **Figuras nuevas**: Yedra [P] y la abuela Nívea [P] se hacen como sprites renderizados a 38° desde los chibis v12 (oficios `campesina` y `anciana`, con atlas nuevos). **Riesgo de estilo** frente a los 4 sprites antiguos: hay que enseñar el antes y el después.

### 3.3 Actividad: «Una flor para Lumi» [P v2 n.º 1]
- Lumi pide una flor de abajo, con la frase [P] del diseño; Nívea, en la misma plaza, da contexto.
- En el banco, la flor es un interruptor de sesión, «Llevar una flor de abajo». Qué flor es [D], porque la lavanda ya va a `oak_lavanda`.
- Al entregarla:
  - Lumi dice: «Entonces abajo no es gris.»;
  - el **dibujo de Lumi aparece clavado en la pared de la Hospedería**: el premio del diseño, que cambia de estado;
  - el hito `isla_flor_lumi` se guarda solo en la partida aislada.
- **No** se da la Cinta de Lumi ([D]; `hallazgos.gd:51` sigue igual).
- No se tocan el templo (acto III), el libro de firmas, el islote ni la Escalera del Cielo.

### 3.4 Interior útil: la Hospedería del Peregrino
- **Dentro de la misma escena**, como un nodo lejos de la isla, con fundido. Se cambian los límites de cámara (`isla.gd:234-243`). Mientras se está dentro, los 4 trozos de la isla, las nubes y las motas se ocultan, para no pagar ese dibujo.
- Dormir: `Inventario.gastar_oro(20)` + `grupo.curar_todos()` + `Sonido.efecto("posada")`. El precio, 20, es [D] y va como constante propia, sin tocar `zona.gd`.
- La escena de descanso se da en avisos encadenados (Yedra, Kael, Lya y Garon), sin Dialogic. Pasarla a Dialogic es un cambio aparte.
- Al salir, se vuelve a la terraza. `guardar_posicion` dentro guarda la puerta de la terraza en `pos_isla`.

### 3.5 Qué NO se toca
- **Archivos**: `isla.gd`, `isla.tscn` y `res://isla/*`; tampoco `render_isla.gd` ni `preparar_isla.gd` (se usan tal cual), ni `mapa.gd`, `mapamundi_3d.gd`, `progreso.gd`, `hallazgos.gd`, `equipo_extra.gd` y `zona.gd`.
- **Técnica**: sigue siendo 2D pintada (`INVENTARIO_MUNDO.md:111`, `157`); nada en 3D en tiempo real ni sin su tapa.
- **Canon**:
  - las frases [C] de Ilia, Orun, Lumi y Vex no cambian;
  - Lumi «nunca ha bajado»;
  - el templo sigue cerrado hasta el acto III;
  - la niebla no se explica (D-033);
  - nadie conoce un secreto antes de descubrirlo.
- **Juego**: ninguna escena del juego enlaza el tramo; no se crean claves de partida ni se cambia `pos_isla`.
- **Licencias**: lo nuevo es propio, hecho en Blender, con su procedencia anotada. Los renders de Meshy siguen sin licencia para una APK entregable (`inventario_licencias.md:64`).

### 3.6 Archivos nuevos y únicos cambios fuera de la carpeta
**Nuevos**, en `aethelgard/zonas3d/arboleda_tramo/`. Aunque el tramo es 2D, esta carpeta la excluye ya el preset estable (`zonas3d/*`).
- `arboleda_tramo.tscn` y `arboleda_tramo.gd`, con `extends "res://isla.gd"`:
  - `_ready`: `super()`, piezas, puerta y figuras nuevas;
  - sobrescribe `_se_anda`, `_poner_z`, `_comprobar_cerca`, `_accion` y `guardar_posicion`;
  - las constantes nuevas llevan nombres propios, porque las de `isla.gd` no se pueden redefinir.
- `hospederia.gd`: el interior, el descanso y Yedra.
- `lumi_flor.gd`: la actividad, con frases [P].
- `fuente/crear_hospederia.py`, `fuente/crear_terraza.py` y los modelos FBX o GLB que exportan.
- `tramo/paso_extra.png`, `tramo/luz_tramo.png`, `interior/{color,paso,suelo,tapa,luz}.png` y `piezas/*`.

Pruebas y documento:
- `aethelgard/pruebas/prueba_arboleda_tramo.gd`
- `aethelgard/pruebas/medir_isla.gd` (manual)
- `docs/v12/ARBOLEDA_HOSPEDERIA.md`

**Cambios fuera de la carpeta:**
1. `banco_pruebas.gd`: entrada `EXPLORAR["arboleda"]` con `activos ["Kael"]`, como `muestra_calle` en l.98-103, más el selector de sesión «Llevar una flor de abajo» y su meta en `METAS_SESION`.
2. `recursos.gd`: `"res://zonas3d/arboleda_tramo/"` en `APAGADOS` con el interruptor `arboleda_tramo_v12`, o en `EXCLUIR` como `res://isla/` (l.15).
3. `musica.gd:121`: añadir `"res://zonas3d/arboleda_tramo/arboleda_tramo.tscn"` al caso `"viento"`.
4. `export_presets.cfg`: `zonas3d/arboleda_tramo/*` en los presets 1 y 2.
5. `pruebas/lista_pruebas.txt`: las líneas nuevas. Ya puestos, corregir la descripción de `prueba_tapa` (l.90).
6. En la fase de figuras: personas nuevas en `fuente/crear_npc_chibi.py` (solo añadir).

### 3.7 Presupuesto móvil
- **Hoy no hay ninguna medida de `isla.tscn`.** El primer paso es `medir_isla.gd` (PC: ms reales, ms de GPU y de CPU en portal, plaza y terraza) y el guion para el Redmi, **antes** de tocar nada.
- Objetivos:
  - el exterior del tramo cuesta como mucho +1 ms de GPU en el PC respecto a la línea base;
  - en el Redmi, ≥ 30 FPS sostenidos;
  - el interior, con la isla oculta, cuesta menos que el exterior.
- Ninguna capa transparente nueva a pantalla completa; el lino y el brillo, sobre sprites pequeños.
- Texturas nuevas como mucho de ≈ 8 MB en VRAM: un trozo de 1536 comprimido con mipmaps, y las máscaras a 1/4 sin pérdida. Se sueltan al volver al mapa, con el tipo «zona» de `Recursos.obtener`.

### 3.8 Pruebas
**Automáticas o con ventana:** `prueba_arboleda_tramo`, del mismo tipo que `prueba_isla` (ventana, `sin_prologo`). Comprueba:
- **BFS** en la máscara combinada: desde `LLEGADA` se llega a la terraza y a la puerta, y no aparece ninguna parcela nueva desconectada;
- `isla_paso.png` no ha cambiado (suma de comprobación);
- Kael queda tapado detrás de cada pieza nueva (lectura de píxel, como `prueba_tapa`);
- entrar y dormir (cobra 20 y cura) y quedarse sin dinero (aviso de error);
- guardar dentro deja `pos_isla` en la puerta de la terraza; al cargar, se aparece en la terraza;
- salir, volver al portal y llegar al mapa;
- la flor: sin ella, Lumi dice su frase [C]; con ella, el hito queda en la partida aislada y el dibujo se ve;
- frases de 110 letras como máximo y sin vetados;
- `mapa.gd` y `mapamundi_3d.gd` no nombran la escena nueva;
- con el interruptor apagado, la carpeta no se precarga.

Siguen pasando: `prueba_isla`, `prueba_tapa`, `prueba_musica` (y el tramo da «viento»), `prueba_guardado`, `prueba_partida`, `prueba_guardado_protegido` y `prueba_hallazgos`.

**Con controles normales**: teclas y mando (`ui_*`), toque y arrastre con el ratón, y la cruceta del móvil. Subir la escalera en diagonal, comprobando que Kael resbala por un eje y no se queda atascado. Hablar con Lumi y Nívea, entrar y salir de la Hospedería, y pausar y reanudar la app dentro.

### 3.9 Encargo para UN agente (copia aislada)
> **Encargo: Arboleda Mítica, «La escalera de la Hospedería». Se mantiene la técnica 2D pintada; experimental, solo Auditoría y editor, entrada solo desde el banco.**
> Trabaja en una copia aislada propia, en la rama `area-arboleda-hospederia` creada desde `claude/rebelum-v12@2d7745d`. Solo commits locales: sin push, PR ni fusiones, y sin instalar en el teléfono. Sin Hunyuan3D ni Meshy, y sin descargas.
> **Lee primero:** `D:/Aethelgard/CLAUDE.md`; `aethelgard/isla.gd` entero (510 líneas); `pruebas/herramientas/render_isla.gd` y `preparar_isla.gd`; `pruebas/prueba_isla.gd` y `prueba_tapa.gd`; `docs/diseno/ciudades_y_lugares.md:405-480`; `docs/v12/INVENTARIO_MUNDO.md` (l.31, 111 y 157); `docs/v12/MUESTRA_CALLE_OAKHAVEN.md` (el método, no la técnica 3D); `docs/versiones/inventario_licencias.md:64`; `recursos.gd:12-16` y `347-406`; `musica.gd:110-125`; `banco_pruebas.gd:88-135` y `250-270`; `zona.gd:2395-2420` (posada); `equipo_extra.gd:109-113` y `hallazgos.gd:48-54`.
> **Haz, en este orden:**
> 1. `medir_isla.gd` y la línea base en el PC, más el guion para el Redmi.
> 2. Comprobar en `isla_paso`, `isla_suelo` y `isla_tapa` la escalera, la terraza y la puerta naranja.
> 3. `paso_extra` y la prueba BFS.
> 4. El interior: Blender, `render_isla` y `preparar_isla`.
> 5. El atrezo de la terraza con su tapa.
> 6. Las sondas 2D y la sombra.
> 7. Lumi y Nívea con «Una flor para Lumi».
> 8. La integración y la medida de antes y después.
>
> Archivos nuevos solo en `zonas3d/arboleda_tramo/` y en `pruebas/`, más SOLO los cambios de fuera de 3.6. Respeta 3.5 y 3.7. Pasa las pruebas de 3.8. Enseña el antes y el después en el mismo encuadre: si lo nuevo se ve más nítido o más saturado que el fondo de Meshy, iguálalo antes de seguir.
> **Entrega:** `docs/v12/ARBOLEDA_HOSPEDERIA.md`, con medidas, láminas y decisiones [D] (precio 20, qué flor, Cinta de Lumi, Yedra y Nívea como [P], y si los NPC pasan a Dialogic).

---

## 4. Lista priorizada de los demás poblados (después de Oakhaven, Sunken y Arboleda)

Criterio: un tramo completo con actividad y una conexión o interior, antes que la decoración. Todos experimentales, con su interruptor propio, en `APAGADOS` y excluidos de los presets 1 y 2.

| # | Poblado | Tramo, actividad e interior | Bloqueos y presupuesto | Datos |
|---|---|---|---|---|
| 1 | **Campamento de Ismena** (Mar de Cristal, lugar 4) | Llegada (45; 101,5) → campamento (36; 92) con la fogata (35; 94,5) → interior de una de las dos tiendas (30; 89 / 41; 88): la mesa de mapas de la cartógrafa → arranque del camino de la caravana (50; 60). Actividad: «La caravana perdida», que es una misión real (8 hitos `mc_*`). Paleta de lona y arena, no la de Oakhaven | Ismena y Oren son [P] y van tras `npc_desierto_v12`; la región sigue en pruebas («mardecristal»); falta validar el «lavado» del perfil bajo. Sin Naira. Hay margen: 30,3 FPS y 745 MB en bajo | `zonas3d/mar_cristal/trazado.gd:10-16`; `datos/encargos_desierto.gd:13-24`; `INFORME_REDMI_V12.md:30,38` |
| 2 | **Refugios de Ciclópea** (lugar 3) | El refugio del paso (`PLAN[0]`, fracción 0,12) con su tramo de camino; interior: leña, pedernal y hogar encendido. La actividad ya existe: encender, descansar, atajo y abrigo de la ventisca, con los hitos `cc_refugio_1-3` y `cc_refugios` | **Antes** hay que medir en el Redmi y bajar la región: en el PC, en medio, va a 68-84 llamadas y 178-185 mil primitivas, por encima de ≤ 65 llamadas y ≤ 160 mil | `zonas3d/ciclopea/refugios.gd:1-22`; `docs/memory/agents/rendimiento_v12_rend3.md:102` |
| 3 | **Collado de Ámbar** (solo diseño) | Aldea minera con la posada La Lámpara de Ámbar; prototipo de aldea y posada, sin la gruta. Llena el hueco de niveles entre 7 y 15 | Contenido [P] por aprobar. Un lugar nuevo en `LUGARES` desplaza a Pastos (índice 10) y obliga a ampliar `ZONA_LUGAR` | `ciudades_y_lugares.md:79-91`, `663-690` |
| 4 | **Aldea Rocío** (solo diseño) | Mucho valor emocional | Bloqueada por la decisión n.º 3, por la cadena `oak_deuda → rocio_nombre`, que no existe en la versión neutra D-073 de Oakhaven, y por D-033. La desaturación radial hay que medirla en el Mali | `ciudades_y_lugares.md:630-661`, `905-907` |
| 5 | **Campamento de Pastos** (maqueta del mapamundi 3D) | Solo mejorar la maqueta cuando el mapamundi salga de pruebas. Es decoración: prioridad baja | — | `zonas3d/mapamundi/maquetas.gd:276-302` |
| — | Sin valor para esta línea | Los campamentos Grimfang (enemigos), el Observatorio de Naira (no aprobada) y la ciudad generada de `zona.gd` (respaldo, no se toca) | — | — |

---

## 5. Decisiones pendientes del usuario [D]
1. Sombra de contacto de Lya y Garon en lo horneado: ampliar `calle_estatico` a 3 posiciones, que cambia también la muestra y cuesta ciclos, o quedarse solo con Kael.
2. Precio de las posadas: Sunken 30 o 40; Arboleda 20.
3. Nombres [P] de Sunken: El Ancla Seca, Doña Coral, el gato Almirante y la cuadrilla. Y si se hace el microencargo «Brea para la Quilla».
4. Arboleda: qué flor recibe Lumi, si se da la Cinta de Lumi, si Yedra y Nívea entran, y si los NPC pasan a Dialogic.
5. Que Brea pilote la Astraea (`ciudades_y_lugares.md:906`). Mientras no se decida, la cuadrilla no trabaja hacia el dique.
