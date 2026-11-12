# Personajes V12 · Protagonistas v3 (Kael, Lya y Garon) con geometría propia

## 12/11/2026, 22:00 · rama LOCAL `claude/v12-heroes3` (`D:\Aethelgard_v12_heroes3`), desde `6c8ad51`

Sin push ni merge. **No he tocado** los v2 (`personajes/heroes_v2/*` salvo el selector `heroes_v2.gd`, como pedía el
encargo), los originales (`kael_3d.gd`, `maga_3d.gd`, `garon_3d.gd`, FBX), `combate.gd`, `grupo.gd`, `equipo_extra.gd`,
`inventario.gd` ni Naira. **Por defecto siguen los originales**: la v3 solo sale si se elige en Ajustes
«Protagonistas: v3 (prueba)», con la meta `heroes_version`/`heroes_v3` o con el argumento `heroes_v3`.

### 1. Estudio (hecho)

- Hoja comparativa en Blender con las mismas cámaras y luz (las de los retratos): frente, tres cuartos, perfil, silueta
  en negro de frente y de perfil, tamaño del combate (≈ 200 px de alto, ampliado ×2) y primer plano.
  `D:\REBELUM_diagnostico\v12\expansion\heroes3\estudio\hoja_<héroe>_original_v2.png` (solo originales y v2) y
  `hoja_<héroe>_original_v2_v3.png` (con la v3; sueltas, `<héroe>_<versión>_<vista>.png`). Guion:
  `personajes/heroes_v3/fuentes_blender/hoja_comparativa.py`.
- Documento de dirección: `docs/v12/DIRECCION_HEROES_V3.md` (proporciones, rasgos, paleta, siluetas, qué se conserva).
- Observado: los v2 son geométricamente los originales (misma malla y texturas de Meshy); a 200 px el detalle pintado
  se vuelve ruido y se leen silueta, masas de color y ojos.

### 2. Geometría nueva (obra propia; esqueleto y clips de captura, derivados)

`fuente/crear_heroes_v3.py <Héroe> <raíz> <evidencias> [modelo|sin_render|sin_glb]` (Blender 5.2.3 por guion, ≈ 1-4 min):
importa el FBX original **solo por su esqueleto y sus clips de captura** y BORRA sus mallas, texturas y materiales;
construye las piezas del diseño, les da pesos por distancia a sus huesos (suavizados), calcula la oclusión con rayos,
pasa los materiales a color por vértice, agranda la cabeza (influencia chibi), proyecta la cara, crea los huesos de arma
y los clips de la biblioteca común de los v2 (sin tocarla) y exporta GLB + JSON + hojas de contacto.

- `geometria_v3.py`: tubos por anillos (extremidades, torso, botas, mangas, faldones abiertos), mechones (lente que se
  afila, por curva o por la superficie del cráneo), esferas deformadas, gemas, cajas; UV de detalle en metros; pesos;
  oclusión; color por vértice (sRGB; el alfa guarda el tipo de material).
- `kael_v3.py`, `lya_v3.py`, `garon_v3.py`: el diseño de cada uno (ver la dirección).
  - **Kael**: cabeza chibi con cara de atlas, pelo de ~60 mechones en capas desde un remolino (picos hacia fuera y
    arriba, flequillo en punta con uno entre los ojos, mechón rebelde), abrigo blanco abierto con cuello alto azul por
    dentro, cuatro faldones separados (siguen a cada pierna), hombreras, mangas con vuelta azul y franja dorada,
    camisa marino, colgante de estrella, dos cinturones con hebillas y cristales colgando, guantes sin dedos con
    brazalete, pantalón y botas altas con correas, hebillas y suela. Manos con cinco dedos.
  - **Lya**: melena larga ondulada (usa sus huesos de pelo `Bone_018/017`), flequillo suelto, lirios con lazo, vestido de
    hombros descubiertos, corpiño con ribete y cinturón dorado con gema, falda corta delante y con cola detrás (sus huesos
    `Bone_008…005`), mangas sueltas acampanadas (hasta `Bone_040/041`), zapatos de tacón con tobillera y cristales.
    Su esqueleto solo trae pulgar y corazón: los otros dedos se mueven con el corazón.
  - **Garon**: yelmo grande con cresta y adorno dorados, visera de rejilla y la mirada en su sombra, penacho rojo,
    gola, coraza con el águila, cinturón, faldar de placas con tela roja, quijotes, rodilleras en punta, grebas,
    escarpes, hombreras de tres láminas, brazales, guanteletes y **broquel en el antebrazo izquierdo** (propuesta: su
    oficio de guardián sin cambiar el combate). La capa y las dos espadas las sigue poniendo el juego.
- **Licencia**: geometría, caras, atlas, textura de detalle y materiales, propios; el esqueleto (rig común de los v2) y
  los clips de captura que se conservan (andar, correr…) son de los FBX de Meshy: anotado como derivado en
  `docs/versiones/licencias_pendientes.txt` («personajes/heroes_v3/»). Si se rehacen esqueleto y esos clips, la v3
  queda libre.
- **Proporciones**: la cabeza y lo que va en ella, agrandados desde la base del cráneo (×1,16 Kael, ×1,12 Lya,
  ×1,08 Garon; `ESCALA_CABEZA` de cada diseño). A ojo, en las capturas del combate, la cabeza de la v3 queda del
  tamaño de la original.

### 3. Rig (comprobado ejecutando)

- **El mismo esqueleto que el v2** de cada uno: `prueba_heroes_v3` compara nombre, padre y reposo de cada hueso con el
  GLB v2: 67 (Kael), 51 (Lya) y 46 (Garon) huesos iguales, ninguno distinto ni añadido. Los mismos clips (22, 20 y
  20) con las mismas duraciones e instantes que el v2 (impacto de Kael 0,64 s, magia 0,85 / 0,5 s, Juicio
  de Garon 1,10 s). Así valen los clips del especialista de combate.
- **Deformación medida en la CPU** (la piel aplicada a mano con los pesos y las matrices de unión del GLB, 5 instantes de
  cada clip): la arista más estirada respecto al reposo y el vértice más lejano de la cadera. Peor caso: ×2,53 (Kael, «golpe_original», un clip de captura), ×2,45 (Lya, «levantarse») y ×2,16
  (Garon, «levantarse»); el límite de la prueba es ×3,2 y lo marcan aristas cortas de las uniones (hombro y codo).
  Ningún vértice se escapa (todo a < 1,6 m de la cadera). Revisado a ojo en las hojas de contacto de cada clip
  (`D:\REBELUM_diagnostico\v12\expansion\heroes3\<héroe>\<héroe>_v3_clip_<clip>.png`).

### 4. Expresiones (comprobado ejecutando)

- Cara propia (`cara_v3.py`): atlas de 1024 × 768 dibujado con numpy (ocho ojos y ocho bocas, la marca y el color de
  las cejas) y la malla `cara_v3` proyectada sobre la cabeza nueva. Ojos y boca independientes (el parpadeo solo toca
  los ojos); cejas con formas clave (`ceja_arriba`, `ceja_enfado`, `ceja_triste`) que van a su sitio en ~0,12 s.
- Juego: normal (neutro), decidido, sonrisa (alegre), dolor, sorpresa, entrecerrados (cansado), cerrados y grito;
  parpadeo con el ritmo de cada uno (el de los v2).
- Enganche: Kael y Lya, los momentos de los v2 (guardia → decidido, golpe → grito, daño → dolor, victoria → sonrisa,
  derribo → dolor y cerrados, levantarse → cansado). Garon (`garon_v3_3d.gd`): los mismos momentos con su mirada en la
  visera (los v2 de Garon no tenían cara).
- Capturas de cada expresión: `...\heroes3\godot_final\NN_<héroe>_cara_<expresión>.png`.

### 5. Materiales y presupuesto

- `heroe_v3.gdshader` + `heroe_v3_luz.gdshaderinc` (Compatibility, `light()` propio): color por vértice (sRGB → lineal),
  detalle por tipo con `heroe_v3_detalle.png` (512², común, VRAM comprimida), luz en dos tonos con terminador suave y
  degradado, sombra teñida (fría; la piel, malva clara), borde de luz, brillos de metal, pelo (anillo roto por hebras),
  cristal y cuero; el reflejo del ambiente en el metal como los v2. Contorno de tinta del color del material
  (`heroe_v3_borde.gdshader`, casco invertido, grosor en pantalla). Cara: `heroe_v3_cara.gdshader` (atlas sin comprimir,
  como los v2).
- Presupuesto (triángulos; los GLB):

| | Original / v2 | v3 |
|---|---|---|
| Kael | 10 324 + cara 326; 3 texturas de 2048 + atlas 1560 × 640; GLB v2 4,9 MB | 14 292 + cara 186; atlas 1024 × 768; GLB 2,4 MB |
| Lya | 10 315 + cara 182; 2 de 2048 + atlas; 3,2 MB | 10 764 + cara 172; atlas; 1,6 MB |
| Garon | 10 327; 3 de 2048; 4,3 MB | 6 484 + cara 144; atlas; 1,6 MB |

  Más la textura de detalle común (512², comprimida). Un material y un dibujo por cuerpo (+ el contorno) y uno por la cara.
  LOD: los genera Godot al importar (`meshes/generate_lods=true`, como los v2).

### 6. Integración (apagada)

- `personajes/heroes_v2/heroes_v2.gd` (el selector al que ya llaman `combate.gd`, `grupo_3d.gd` y `vista3d.gd`):
  `version()` = originales | v2 | v3 (meta `heroes_version` → meta `heroes_v3` → meta `heroes_v2` → argumentos
  `heroes_v3`/`heroes_v2` → Ajustes `[heroes] version` (o el `[heroes] v2` de antes) → originales). `elegir_version(v)`
  lo guarda; `elegir_en_ajustes(si)` y `activado()` siguen valiendo para los v2. Con «v3», quien aún no tenga v3 usa su v2.
- `menus.gd` (bloque «Protagonistas»): tres opciones: Originales / v2 (prueba) / v3 (prueba).
- `personajes/heroes_v3/heroes_v3.gd` (rutas y cambio de ayudante), `kael_v3_3d.gd`, `lya_v3_3d.gd`, `garon_v3_3d.gd`
  (heredan de los v2: mismo combate, exploración y conversación) y `heroe_v3_ayudante.gd` (hereda del ayudante v2).

### 7. Comparación y medidas

**Capturas** (`D:\REBELUM_diagnostico\v12\expansion\heroes3\`):
- `godot_final\`: los tres a la vez (izquierda original, centro v2, derecha v3) con la cámara y la luz del combate de
  `fotos_heroes_v2.gd`: guardia, ataque (4 instantes), magia, golpe, victoria (0,6 y 2,0 s), caída y KO; de cerca (cuerpo
  y cabezas); y la v3 sola con cada expresión (`NN_<héroe>_cara_<expresión>.png`). 58 capturas.
- `combate_real\{originales,v2,v3}\` y `combate_real\pares\combate_NN__original_v2_v3.png`: el mismo combate real
  (`combate.tscn`, grupo de 3, automático, semilla 7) con cada versión; 16 instantes, lado a lado.
- `estudio\hoja_<héroe>_original_v2_v3.png`: la hoja de Blender con la v3 (sin la luz ni el contorno del juego).
- `<héroe>\<héroe>_v3_clip_<clip>.png`: cada clip en 8 instantes; `<héroe>_v3_modelo.png`: el modelo en T (frente, 3/4,
  perfil, espalda y cara); los `.blend` (fuera de Git).
- `iteraciones\godot_1..8`: las pasadas intermedias (de la primera, sin cara ni color, a la final);
  `diagnostico\dbg_cara_*.png`: la causa de la cara invisible (abajo).

**Medidas** (`medir_escenas.ps1 -Escenas combate3,pastos -Extra heroes_v2|heroes_v3`, perfil medio, 3 ciclos, dos
pasadas intercaladas v2 → v3 → v2 → v3; `medidas\resumen_v2_frente_v3.txt`). **PC, no Redmi; y con 4-8 Godot de otros
especialistas corriendo a la vez (`medidas\*\procesos.txt`): los tiempos son orientativos.**

| Escena | Memoria de vídeo (MB) v2 → v3 | Dibujos | Primitivas | Fotograma activo med (ms) | Carga repetida (ms) |
|---|---|---|---|---|---|
| Combate de tres (1.ª / 2.ª) | 136 → 106 / 136 → 88 | 101 → 107 / 101 → 113 | 83 k → 111 k / 78 k → 106 k | 5,20 → 5,29 / 4,94 → 6,15 | 806 → 850 / 736 → 898 |
| Pastos (1.ª / 2.ª) | 105 → 77 / 105 → 77 | 116 → 125 | 328 k → 392 k | 5,58 → 4,75 / 5,10 → 4,49 | 1098 → 892 / 953 → 901 |

- **Memoria**: −30 a −48 MB de vídeo (sin las texturas de 2048 de Meshy; la v3 usa un atlas de cara por héroe y una de
  detalle común).
- **Coste de dibujo**: +6 a +12 dibujos y +27 k a +64 k primitivas por el contorno (casco invertido: cada cuerpo se dibuja
  dos veces) y la cara. El fotograma se mueve dentro del ruido de esta máquina cargada (unas veces mejor, otras peor).
  En el Mali-G57 lo que más puede pesar es el contorno: si hiciera falta, se puede quitar solo en el perfil bajo (es la
  `next_pass` del material; no lo he hecho porque no está medido en el teléfono).

### 8. Pruebas (aisladas; «partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios»)

- `prueba_heroes_v3` (auto, nueva, al final de `lista_pruebas.txt`): **SUPERADA, 268 comprobaciones, 0 fallos**: elección
  y Ajustes, esqueleto común, clips e instantes, presupuesto, material, cara (formas clave, cejas sin saltos, parpadeo
  solo de los ojos), combate y deformación de cada clip de los tres.
- Batería por opción (`ejecutar_pruebas.ps1 -Lista`, combate y grupo: `prueba_garon`, `prueba_grupos_combate`,
  `prueba_combate_seguro`, `prueba_hud_combate`, `prueba_grupo3d`, `prueba_ia`, `prueba_artes_combate`):
  - originales (+ `prueba_heroes_v2`, `prueba_heroes_v3` y `prueba_audio`, que abre Ajustes): **10 · 0 · 0 · 0**,
    `D:\REBELUM_diagnostico\pruebas\2026-11-12_211601\resumen.md`;
  - con `heroes_v2`: **7 · 0 · 0 · 0**, `...\2026-11-12_211749\resumen.md`;
  - con `heroes_v3`: **7 · 0 · 0 · 0**, `...\2026-11-12_211916\resumen.md`.
- `prueba_heroes_v2` sigue en verde (201 comprobaciones): la opción v2 de antes funciona igual.
- `fotos_heroes_v3` (ventana, nueva en la lista) y `fotos_heroes_v3_combate.gd` (ventana; `version=originales|v2|v3`):
  MANUAL, sin errores.
- Tras el último cambio de colores (piel más clara, acero de Garon y pelo de Kael más claros) repetí `prueba_heroes_v3`
  (268 · 0) y las capturas; la batería por opción es de antes de ese cambio (solo cambian colores del GLB).

### Problemas encontrados y su causa (demostrada)

- **La cara no se veía en Godot** (sí en Blender): el sombreador de la cara escribía `POSITION` solo en las cejas; en
  Godot, si se escribe `POSITION`, deja de proyectar por su cuenta y los demás vértices quedaban sin posición. Probado
  con materiales de sustitución (`diagnostico\dbg_cara_*.png`: rojo sin luz → se ve la malla; el atlas sin transparencia
  → se ve; el sombreador sin alfa → no se ve). Arreglo: escribir `POSITION` en todos los vértices.
- **Colores lavados y piel amarilla**: el color por vértice iba en lineal con 8 bits (los oscuros, en escalones); ahora va
  en sRGB y el sombreador lo pasa a lineal. Además la luz en dos tonos daba más luz que una lambert (el lado iluminado,
  entero a 1): se compensa con `exposicion`, y la sombra de la piel es malva clara (la cálida, con el sol y el ambiente
  cálidos del combate, la dejaba naranja).
- **Muslos atravesando los faldones** de Kael: el radio del muslo en la cadera era mayor que el del faldón; reducido.

### Límites (honesto)

- **Calidad frente a los originales:** la v3 es una base PROPIA que funciona en todo el juego y se lee bien a la
  distancia del combate (silueta, cara, colores), pero **su superficie es mucho más simple que la de Meshy** (sin
  bordados, pliegues modelados ni texturas pintadas): de cerca se nota. Mi valoración: hoy no la pondría por defecto;
  es un primer paso hacia unos protagonistas con licencia propia, para que el usuario decida si sigue por aquí.
- **Garon**: el yelmo es casi una esfera (el original tiene una forma mucho más trabajada) y el cuello se ve entre yelmo
  y gola en algunos planos; la mirada en la visera y el broquel son propuestas. **Lya**: la melena es una cortina de
  mechones (sin las ondas grandes del original); los tres dedos que no tiene su esqueleto se mueven con el corazón.
  **Kael**: el pelo negro pesa mucho en la silueta del combate.
- **Clips**: los de la biblioteca de los v2, sin cambios; la cabeza agrandada puede rozar el sable al hombro de Kael en el
  reposo (revisado en hojas, no medido) y la falda de Lya se levanta con las piernas en el derribo.
- **Esqueleto y clips de captura, derivados de Meshy** (anotado): la licencia aún no queda limpia del todo.
- **Sin Redmi** (por encargo): nada medido en Android; el `light()` propio, el contorno, las formas clave y la cara
  transparente están sin ver en el Mali-G57.
- **Medidas con el PC cargado** por otros especialistas: los milisegundos no son concluyentes; memoria, dibujos y
  primitivas sí.
- Diálogos: no hay retratos 2D de la v3 ni enganche nuevo con Dialogic (sigue `hablar(animo)` de los v2).

### Siguiente paso propuesto

1. Que el usuario mire `combate_real\pares\`, `godot_final\` y las hojas de `estudio\` y diga si sigue por la geometría
   propia (y con qué héroe empezar a refinar) o prefiere seguir puliendo los v2.
2. Si sigue: esculpir y hornear (Blender, por guion) mapas de color y normales propios sobre la geometría v3 (pliegues,
   bordados del abrigo, ondas del pelo de Lya, forma del yelmo de Garon) y rehacer los clips de captura que quedan de
   Meshy para dejar la licencia limpia.
3. Medir en el Redmi un combate de tres y Pastos con «v3 (prueba)»; si el contorno pesa, quitarlo en el perfil bajo.

### Cambios que pido en archivos de otros

- `docs/recursos.md`, una fila: «Héroes v3 (12/11, APAGADOS; se eligen en Ajustes «Protagonistas: v3 (prueba)»):
  `personajes/heroes_v3/` (GLB de Kael, Lya y Garon, atlas de cara, textura de detalle, sombreadores y guiones) | Obra
  propia con Blender 5.2.3 por guion (`fuente/crear_heroes_v3.py`, `personajes/heroes_v3/fuentes_blender/`): geometría,
  caras, atlas, detalle y materiales; el esqueleto y los clips de captura que se conservan vienen de los FBX de Meshy
  (ver `licencias_pendientes.txt`) | Propia + Meshy (pendiente) | Ninguno por defecto | Pendiente».
