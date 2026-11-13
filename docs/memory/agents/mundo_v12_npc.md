# Mundo 3D y NPC · V12 · inventario del mundo, familia de NPC chibi y Oakhaven vivo

## 12/11/2026 · rama LOCAL `claude/v12-mundo` (copia `D:\Aethelgard_v12_mundo`, desde `d8a65d3`)

Encargo (coordinador): Parte 1, inventario completo del mundo con orden de migración y una actividad por región sin Orbes
Cristalinos; Parte 2, una familia propia de NPC chibi con Blender por guion y un Oakhaven 3D que parezca vivo, todo
APAGADO tras un interruptor, medido con y sin él y con capturas comparativas. Sin push ni merge; todo Godot con datos
aislados (APPDATA, LOCALAPPDATA, TEMP y TMP en `D:\Aethelgard_v12_mundo\.datos_aislados`, sin versionar); sin ADB ni
Redmi. La primera importación de la copia vació los directorios de Dialogic de `project.godot` (aviso conocido de
RETOMAR): `git restore` y reimportar; desde entonces `project.godot` sin cambios.

Leyenda: **[C]** observado en el código · **[E]** comprobado ejecutando (aislado, PC) · **[?]** pendiente (Redmi).

### 1. Parte 1 · Inventario del mundo (`docs/v12/INVENTARIO_MUNDO.md`)

- Tabla de los 11 lugares + subzonas apagadas (Humbaba, Naira): **terminadas en 3D** Pastos Verdes, Oakhaven, Garganta y
  Gran Bosque; **incompleta/en pruebas** el Mar de Cristal (solo el primer sector de Calid); **siguen en 2D** Cumbres de
  Ciclópea, Sunken City, Valle de los Ecos, Templo Sumergido, Abismo de Ceniza y la Arboleda Mítica (2D pintada a
  propósito); **lugares de la historia sin jugar** (Cripta de las Urnas, Templo del Cristal del Cielo, Océano de Bruma,
  Abismo Quebrado, Gruta del Velo, Escalera del Cielo, Aldea Rocío, Collado de Ámbar, el resto de Calid, el pico de Glacius,
  el casco de Sunken City y el «santuario» del Gran Bosque que el texto del mapa promete y no existe).
- Para cada región, la lista del usuario (terreno, arquitectura, vegetación, luz, animales, NPC, enemigos, secretos,
  interacciones, misiones, cofres, música, entradas/salidas, navegación, colisiones, guardado, mapamundi) y lo que falta.
- **Orden de migración razonado:** (1) Oakhaven vivo (este encargo), (2) Mar de Cristal fuera de pruebas y el resto de
  Calid, (3) **Cumbres de Ciclópea** (el único hueco 2D en la ruta 3D Garganta → Ciclópea → Calid; reutiliza el kit de
  roca de la Garganta y el clima del desierto), (4) Sunken City (con la familia de NPC y los sistemas de Oakhaven),
  (5) Valle de los Ecos, (6) Arboleda (solo si se pide), (7) Templo y Abismo (Astraea, acto III).
- **Una actividad distinta por región** (rumores por horas en Oakhaven, cuaderno de naturalista en Pastos, herbolaria en
  el Gran Bosque, ruta de poleas en la Garganta, arqueología en Calid, refugios de montaña en Ciclópea, trueque en Sunken
  City, puzles de eco en el Valle, mareas en el Templo, braseros en el Abismo, libro de firmas en la Arboleda). Ninguna
  recompensa en Orbes Cristalinos. Todo propuesta [P].
- **Siguiente migración:** no empezada (no daba para dejarla jugable, apagada y probada); plan detallado de Cumbres de
  Ciclópea en el §8 del inventario.

### 2. Parte 2 · La familia de NPC chibi (`fuente/crear_npc_chibi.py` → `personajes/npc_v12/`)

Blender 5.2 por guion, obra propia (sin recursos descargados ni Modelado/TripoSR: no hizo falta). Reutiliza, SIN tocarla,
la biblioteca de los NPC del desierto (`personajes/desierto/fuentes_blender/desierto_comun.py`: atlas pintado, malla por
partes, esqueleto, clips, exportación). Estilo de Ismena y Oren, que ya seguía a los héroes: cabeza grande, ojos grandes
de anime con brillos, manos sencillas; proporciones propias por oficio, sin copiar personajes de otros juegos.

- **Esqueleto común** de 22 huesos (los de Ismena y Oren): raíz, cadera, columna, pecho, cuello, cabeza, párpados, hombros,
  brazos, antebrazos, manos, muslos, piernas y pies. Las proporciones cambian por oficio (`Figura`: altura, anchura,
  barriga, cabeza), los clips son giros: una biblioteca para todos. [E `prueba_mundo_vivo` parte 0: 22 huesos en los 12]
- **12 oficios** (una malla y un GLB cada uno, 2 304-3 544 triángulos, un material): herrero (delantal de cuero, calvo con
  barba y bigote, martillo), mercader (barriga, chaleco, gorro, bolsas), alquimista (túnica larga, gafas, coleta, matraz),
  guardia de Oakhaven (tabardo con el roble y el farol pintados, casco de ala, lanza), campesino (sombrero de paja, azada),
  campesina (falda, pañuelo, trenzas, cesta), anciano (encorvado, barba larga, bastón), anciana (chal, moño, bolsa de
  grano), niño (cabeza más grande, espada de madera), niña (coleta, vestido), viajero (capa, capucha, mochila con manta,
  bastón de camino) y barrendera (delantal, gorro, escoba).
- **21 personas** = oficio + atlas propio de 512 (colores, piel, pelo, ojos, boca, pecas, gafas, arrugas): 14 secundarias
  nuevas y 7 para los vecinos con nombre (Aldric, Rosa, Albar, Bastián, Doña Encina; Ferro y Mirta preparados pero sin
  usar, ver §6). Mismo oficio a la vez en pantalla: los dos guardias (uniforme), las dos niñas del corro (otro pelo, otro
  vestido y otra cara) y, a veces, Rosa y la vendedora de ciruelas (otros colores, otra cara); vigilar si el usuario los
  ve repetidos.
- **Clips** (30 fps): `reposo` (4 s, respira, cambia el peso, parpadea dos veces), `caminar` (1 s, en el sitio; el brazo
  que lleva algo apenas se balancea), `correr` (0,6 s, niños), `hablar` (2,5 s, la mano libre hacia quien escucha y
  asiente), `saludar` (1,6 s) y `tarea` del oficio: martillar, pregonar, remover, vigilar, cavar, recoger, estirar,
  echar_grano, jugar (saltitos), ajustar (las correas de la mochila) y barrer.
- **Objetos en la mano** escritos en la pose de reposo del oficio y llevados a la de descanso con la inversa del hueso
  (`EnPose`): la lanza queda vertical aunque el brazo esté doblado.
- **Pesos:** el guion avisa de vértices sin hueso («SIN PESO»). Encontró un fallo de la biblioteca común
  (`desierto_comun.por_altura` pierde el peso cuando dos puntos seguidos son del mismo hueso: el exportador añadía
  `neutral_bone` y el esqueleto dejaba de ser común); aquí se usa una versión que suma los pesos. **La de Ismena y Oren
  sigue igual** (no es mía): avisar al especialista de animaciones.
- **Velocidad al andar** de cada oficio calculada en el guion (lo que avanza el pie apoyado), para que no patinen:
  `npc_chibi.gd` acelera o frena el clip según lo que se mueve de verdad.
- **LOD:** el automático de la importación (`meshes/generate_lods=true`); atlas en VRAM (S3TC/ETC2) con mipmaps;
  las imágenes que el GLB llevaba dentro se descartan al importar (`embedded_image_handling=0`), el atlas lo pone Godot.
- **Láminas:** `fuente/render_npc_chibi.py` (lee los GLB, como Godot) → `familia.png` (las 21 con Kael a escala),
  `clips_<oficio>.png` y `caras.png` en `D:\REBELUM_diagnostico\v12\expansion\mundo\npc\`.

### 3. Oakhaven vivo (`zonas3d/oakhaven/mundo_vivo.gd`, `palomas.gd`; `personajes/npc_v12/npc_chibi.gd`)

**Interruptor `mundo_vivo_v12`, APAGADO.** Se enciende con `Engine.set_meta("mundo_vivo_v12", true)`, el argumento
`-- mundo_vivo_v12`, Ajustes → «Oakhaven: Mundo vivo (prueba)» (`user://ajustes.cfg`, `[mundo] vivo_v12`; una línea en
`menus.gd`, junto a «Protagonistas») o `ACTIVO_POR_DEFECTO = true`. **Apagado, Oakhaven queda exactamente igual** [E parte 1].
`Engine.set_meta("mundo_vivo_sin_vecinos", true)` deja a los vecinos con nombre con su figura de siempre (para comparar).

| Persona | Rutina | Dónde (casillas = m) | Franjas |
|---|---|---|---|
| Guardia de la puerta | vigila | Puerta del Sur, frente a Aldric | todas |
| Guardia de ronda | patrulla ida y vuelta, vigila en cada punto | Calle Mayor → plaza → Calle del Árbol | todas |
| Aprendiz de la forja | martilla (a ratos descansa) | delante de la fragua, junto a Ferro | mañana, tarde |
| Frutero | pregona | puesto del mercado | mañana, tarde |
| Vendedora de ciruelas | anda de la Puerta del Sur al mercado y vuelve; en el mercado, recoge | | mañana, tarde |
| Aprendiz de la botica | remueve un matraz | plazuela de la botica | mañana, tarde |
| Hortelano | cava | huerto del distrito | mañana, tarde |
| Abuela de las palomas | echa grano; 7 palomas | plaza, junto al tablón | mañana, tarde |
| Abuelo paseante | pasea despacio y se estira | plaza → Calle del Árbol | tarde, anochecer |
| Tres niños | corren alrededor de la fuente y a ratos saltan (pillar) | la fuente | mañana, tarde |
| Viajero | busca la taberna: Puerta del Sur → plaza → Calle del Cuervo | | tarde, anochecer |
| Barrendera | barre avanzando | Calle del Mercado | mañana, tarde |

- **Hablar:** «Hablar con …» como con los vecinos; se para, se gira hacia Kael, gesto `hablar` y una frase de ambiente en
  el aviso (se turnan). Frases cortas (≤ 48 letras), del tono de `oakhaven_vida.gd`, sin giros: faroles, niebla, la
  campana, el mercado, el Árbol, la forja de Ferro, la taberna. Ninguna abre un diálogo ni toca hitos.
- **Saludo:** los que saludan (frutero, vendedora, dos niños) y los vecinos con nombre se giran y saludan una vez si Kael
  pasa a menos de 4,2 m (pausa de 45 s).
- **Vecinos con nombre** (Aldric, Rosa, Albar, Bastián, Doña Encina): con el interruptor, su figura de la familia en lugar
  de la provisional; el **mismo** diálogo (`Oak.dialogo_de`), sitio, rutina por franja y paseo (andan de verdad y hacen
  su gesto al hablar) [E parte 7]. Ferro y Mirta (distrito, con el brazo del martillo de Ferro animado aparte) y la
  posadera (dentro de la posada) no cambian.
- **Palomas** (fauna que `oakhaven_vida.gd` tenía solo como datos): 7 en UNA llamada de dibujo (MultiMesh), picotean,
  saltan a otro grano, se espantan con Kael a 2,3 m (sonido `pajaro`) y vuelven a los 16 s; se van con la abuela.
- **Barato** (lo que pide el Mali-G57): sin físicas; animación en modo manual: los **6 más cercanos** que se ven y a
  menos de 12 m, cada fotograma (`MAX_CERCA`, `CERCA`); los demás visibles hasta 28 m, a 15 Hz (`ANIM_MEDIA`); fuera de la
  cámara o más lejos, quietos; a más de 34 m, ni se dibujan (`OCULTO`). La rutina se piensa a 4 Hz fuera de la vista
  (se simplifica, no se para: al volver no están todos donde se dejaron). Nadie aparece ni se va con Kael a menos de 18 m.
  Un material por persona, compartido; una sola variante de sombreado (StandardMaterial3D con esqueleto) para todos.
- **Kael y ellos:** quien anda se para si Kael está delante (a menos de 0,95 m), y Kael no los atraviesa (`ocupa()` en
  `_prohibido`, radio 0,42): nunca acaba dentro de nadie [E parte 3].

### 4. Coste medido (PC: Ryzen 7 4800H + RTX 3050 portátil, 1280×720, Compatibility; **no son cifras del Redmi**)

**Ojo:** durante las medidas había otros Godot y Blender de otros especialistas en el mismo PC (`procesos.txt` de cada
carpeta: Blender en las pasadas «con» de medio y alto). Los tiempos de fotograma del PC varían ±1-4 ms entre pasadas
iguales; las llamadas y primitivas, no.

**a) `medir_escenas.ps1 -Escenas oakhaven -Perfiles bajo,medio,alto -Ciclos 3`** (Kael en la Puerta del Sur, el sitio de
la herramienta; ahí se ven pocos NPC), sin y con `-Extra mundo_vivo_v12`, dos tandas:

| Perfil | Dibujos | Primitivas | Repetida (ms) 1.ª / 2.ª tanda | Activo mediana (ms) 1.ª / 2.ª | Tirones > 50 ms |
|---|---|---|---|---|---|
| bajo | 74 → 77 | 166 709 → 178 905 | 1 499 → 2 613 / 1 534 → 1 564 | 5,18 → 5,22 / 4,62 → 5,23 | 0 → 0 / 0 → 0 |
| medio | 87 → 92 | 257 492 → 279 255 | 2 395 → 2 062 / 2 077 → 2 465 | 5,24 → 5,05 / 4,47 → 6,43 | 0 → 0 / 0 → 0 |
| alto | 220 → 236 | 754 620 → 804 181 | 2 575 → 3 224 / 2 325 → 2 488 | 5,55 → 5,42 / 5,35 → 6,68 | 0 → 3 (un pico de 210 ms en el ciclo 2) / 0 → 0 |

Memoria estática +1-3 MB por ciclo y sin huérfanos al salir. Montar el mundo vivo: 57 ms la primera vez, 3-5 ms las
siguientes (`ms_montar`; sin contar las 5 figuras de los vecinos). El pico de 210 ms del alto no se repitió en la
segunda tanda (sin causa clara; con Blender de otro especialista corriendo).

**b) La plaza, el peor sitio** (`fotos_mundo_vivo.gd`, cámara del juego, mismos sitios sin/con; `capturas2\dibujos.txt`):

| Vista | Bajo: llamadas · primitivas | Medio | Alto |
|---|---|---|---|
| Plaza (fuente y corro) | 80 → 91 · 187 k → 218 k | 98 → 117 · 286 k → 346 k | 179 → 198 · 844 k → 906 k |
| Mercado | 78 → 87 · 193 k → 220 k | 94 → 113 · 293 k → 350 k | 184 → 202 · 930 k → 990 k |
| Forja y huerto | 63 → 71 · 160 k → 186 k | 83 → 100 · 254 k → 308 k | 172 → 192 · 804 k → 867 k |
| Puerta del Sur | 84 → 87 · 173 k → 189 k | 101 → 107 · 265 k → 296 k | 229 → 245 · 769 k → 821 k |
| Botica | 94 → 99 · 178 k → 198 k | 114 → 124 · 269 k → 311 k | 222 → 240 · 857 k → 917 k |

Cada NPC visible: 1 llamada (2 con sombras: medio y alto) y unos 2,5-3,5 k triángulos (el doble con la sombra). En la
plaza, con el corro, la abuela, el viajero y la ronda a la vista: **bajo +11 llamadas y +17 % de primitivas; medio +19 y
+21 %**. GPU del PC por vista: de 0,8-1,2 ms a 0,8-1,1 ms en bajo y medio, de 1,6 a 2,2 ms en alto (no dice nada del
Mali-G57).

**c) CPU del guion:** `us_proceso` (rutinas + animación de los cercanos) 0,25-0,55 ms por fotograma en la plaza. El tiempo
de proceso total del PC sube de forma muy ruidosa (+1 a +4 ms entre pasadas iguales, con otros procesos): la actualización
de los esqueletos va aparte y **hay que medirla en el Redmi**. Palancas si pesa: `MAX_CERCA` (6), `CERCA` (12 m),
`ANIM_MEDIA` (15 Hz), quitar la sombra de los NPC en medio (cambia el aspecto: solo si el usuario lo aprueba) o menos
personas por franja.

**Capturas** (`D:\REBELUM_diagnostico\v12\expansion\mundo\`):
- `capturas2\comparar_<perfil>_<vista>.png`: sin (izquierda) y con (derecha), bajo, medio y alto; las sueltas,
  `<perfil>_<sin|con>_1280x720_<vista>.png`. Las vistas `w02_mercado_cerca` y `w04_calle_mayor_cerca` (cámara fija) salen
  tapadas por tejados: no valen; las buenas son las `v0*` (cámara del juego) y `w01_plaza_cerca`, `w03_forja_cerca`.
- `npc\familia.png` (las 21 personas y Kael a escala), `npc\caras.png`, `npc\clips_<oficio>.png` (reposo, caminar, tarea,
  hablar, saludar y correr).
- `medidas\sin`, `con_vivo`, `sin_2`, `vivo_2` y `resumen_sin_con.md`, `resumen_sin_vivo_2.md`.

### 5. Pruebas (aisladas, PC)

- **`prueba_mundo_vivo`** (nueva, al final de `lista_pruebas.txt`): **superada**. Partes: familia (12 oficios con los
  clips del contrato, 22 huesos, 1 malla, 2 304-3 544 triángulos, atlas por persona, material compartido, frases de una
  línea y sin nombres vetados); apagado igual que siempre; 14 personas; rutas, corro y barrido sin bloqueos; todos se
  alcanzan; andan y nunca encima de Kael, que no los atraviesa; palomas (se espantan y vuelven); hablar (botón, frase que
  se turna, gesto y giro); lejos sin animar ni dibujar; al anochecer se van niños, mercado y palomas; los vecinos con
  figura nueva conservan diálogo y sitio; «mundo_vivo_sin_vecinos».
- **`fotos_mundo_vivo`** (ventana, capturas y llamadas por vista): hecha en bajo, medio y alto (§4).
- **Batería completa:** **136 · 0 · 63 · 0** sobre `51531f4` (`D:\REBELUM_diagnostico\pruebas\2026-11-12_202414`): `partida.save` real y carpeta real de datos sin cambios; «proyecto cambiado» = este informe, `docs/recursos.md` y `fotos_mundo_vivo.gd` (vistas), editados durante la pasada. Con 308 avisos de «otros Godot» (los de otros especialistas en el mismo PC).

### 6. Lo que queda y lo que hay que validar en el Redmi

- **Redmi (nada probado en el teléfono):** encender Ajustes → «Oakhaven: Mundo vivo (prueba)» y medir FPS en bajo y medio
  en la plaza (el corro, la abuela y la ronda), el mercado y la forja frente a «De siempre»; mirar si los esqueletos pesan
  en la CPU (si sí: bajar `MAX_CERCA` a 4 o `ANIM_MEDIA` a 10 Hz) y si los niños y las caras se leen a esa distancia.
- **Que el usuario vea la familia** (`npc\familia.png`, `caras.png`, `clips_*.png`) antes de encender nada por defecto.
- **Ferro y Mirta** tienen persona preparada (`herrero/ferro.png`, `alquimista/mirta.png`) pero siguen con su figura del
  distrito: cambiarlas pide rehacer el brazo del martillo de Ferro (`distrito.gd`), que no es de este encargo. Hilda y la
  posadera no tienen persona aún.
- **Fallo de la biblioteca común** (`desierto_comun.por_altura`, vértices sin peso cuando dos puntos seguidos son del mismo
  hueso): avisar al especialista de animaciones (Ismena y Oren podrían llevar `neutral_bone`). Aquí está corregido en
  `crear_npc_chibi.py`.
- Las vistas fijas `w02` y `w04` de `fotos_mundo_vivo.gd` salen tapadas: recolocar la cámara si se quieren.
- Los GLB llevan el atlas de su primera persona dentro (600 KB cada uno en el repositorio); la importación lo descarta. Si
  pesa en el repositorio, exportar sin imagen.
- La actividad de Oakhaven del inventario («rumores por horas») encaja con estos vecinos: sus frases ya cambian por
  franja de presencia; falta el contenido (narrativa).
- **Siguiente migración** (Cumbres de Ciclópea): plan en `docs/v12/INVENTARIO_MUNDO.md` §8; no empezada.

### 7. Commits (rama `claude/v12-mundo`, LOCAL)

- `96bd0e3` inventario del mundo.
- `93b31d7` familia de NPC chibi y Oakhaven vivo (apagado), `prueba_mundo_vivo`.
- `51531f4` palomas, límite de animados, opción de Ajustes, capturas.
- (último) este informe, la fila de `docs/recursos.md`, las caras de la lámina y las vistas fijas.

### 8. Archivos para integrar (copiando, sin fusionar)

**Nuevos:**
- `docs/v12/INVENTARIO_MUNDO.md`, `docs/memory/agents/mundo_v12_npc.md`
- `aethelgard/fuente/crear_npc_chibi.py`, `aethelgard/fuente/render_npc_chibi.py`
- `aethelgard/personajes/npc_v12/` entera (`npc_chibi.gd` + `.uid`; por oficio: `<oficio>.glb` + `.import`,
  `<oficio>.json`, `<persona>.png` + `.import`)
- `aethelgard/zonas3d/oakhaven/mundo_vivo.gd` + `.uid`, `aethelgard/zonas3d/oakhaven/palomas.gd` + `.uid`
- `aethelgard/pruebas/prueba_mundo_vivo.gd` + `.uid`, `aethelgard/pruebas/fotos_mundo_vivo.gd` + `.uid`

**Compartidos modificados:**
- `aethelgard/zonas3d/oakhaven_3d.gd` (crear `vivo`, `ocupa` en `_prohibido`, sus piezas y su acción: 13 líneas)
- `aethelgard/zonas3d/oakhaven/vida3d.gd` (la figura de la familia de los vecinos con nombre, su paseo y su gesto al
  hablar; con el interruptor apagado, el código de siempre)
- `aethelgard/menus.gd` (UNA línea, tras «Protagonistas»)
- `aethelgard/pruebas/lista_pruebas.txt` (una línea al final)
- `docs/recursos.md` (una fila al final)
- `project.godot` sin cambios. Tras copiar, `--import` (los GLB y atlas nuevos) y revisar `git diff project.godot`.

**Cómo se enciende:** Ajustes → «Oakhaven: Mundo vivo (prueba)» (`user://ajustes.cfg`, `[mundo] vivo_v12 = true`), o
`-- 3d mundo_vivo_v12`, o `Engine.set_meta("mundo_vivo_v12", true)`, o `ACTIVO_POR_DEFECTO = true` en
`zonas3d/oakhaven/mundo_vivo.gd`. Por defecto, APAGADO.
---

## 13/11/2026 · segunda pasada (misma copia y rama)

Encargo: (1) pulir la familia (en `familia.png` se veía tosca al lado de Kael), con antes/después en la misma lámina y
sin pasar del presupuesto; (2) repetir las vistas `w02` y `w04`; (3) si daba tiempo, un primer sector de Ciclópea 3D
jugable, apagado y probado, o si no un plan concreto y un esbozo del terreno.

### 9. Familia v2 (`fuente/crear_npc_chibi.py`; la v1 en `personajes/npc_v12/v1/` con `.gdignore` y su guion)

- **Sombreado suave:** más segmentos en todo lo redondo (cabeza 28 × 18, tronco 16, brazos 10, piernas 10, mangas 12,
  túnicas 22, faldas 21); las caras de las telas planas (delantales) ahora lisas.
- **Manos:** manopla redonda (palma, dedos juntos y pulgar), no un tubo aplastado. **Pies:** puntera abombada sobre una
  suela con canto, caña que se ensancha y vuelta de cuero en la bota.
- **Pelo:** mechones anchos que salen de la cabeza y caen a los lados y la nuca (con sombrero, solo los de abajo); el
  flequillo, con mechones gruesos y curvos en vez de hojas planas; el moño de las abuelas, recogido.
- **Telas:** pliegues que se abren hacia el bajo en túnicas, faldas, delantales y capas, y ribetes en los bajos
  (dobladillo, canto de la capa).
- **Caras:** loseta de 384 px (antes 256) en el mismo atlas de 512 (las muestras de color pasan a celdas de 32):
  contorno del iris, reflejo bajo, tres brillos, párpado más grueso con pliegue, pestaña de abajo, cejas con forma, rubor
  con rayitas, nariz con brillo, boca con dientes y lengua; la barba del herrero ya no tapa las mejillas.
- **Presupuesto: 6 000 triángulos por NPC** (el del prototipo del desierto, Ismena, 5 706). El guion avisa si se pasa y
  `prueba_mundo_vivo` lo comprueba [E]:

| Oficio | v1 | v2 |
|---|---|---|
| herrero | 2 304 | 4 130 |
| mercader | 2 972 | 5 374 |
| alquimista | 3 240 | 5 984 |
| guardia | 3 192 | 5 600 |
| campesino | 2 832 | 5 096 |
| campesina | 3 544 | 5 954 |
| anciano | 2 429 | 4 229 |
| anciana | 2 952 | 4 936 |
| niño | 2 944 | 5 912 |
| niña | 2 728 | 5 570 |
| viajero | 3 270 | 5 904 |
| barrendera | 2 992 | 5 570 |

- **Coste en Oakhaven (PC, las mismas vistas):** las llamadas de dibujo no cambian (una por NPC, dos con sombra). Las
  primitivas de la plaza con todo encendido: bajo 218 k (v1) → 234 k (v2) (sin el mundo vivo, 187 k); medio 346 k → 378 k
  (286 k); alto 906 k → 939 k (844 k). Atlas igual (512, VRAM comprimido). No es una medida del Redmi.
- **Láminas** (`D:\REBELUM_diagnostico\v12\expansion\mundo\npc\`): **`comparar_v1_v2.png`** (cada oficio, v1 a la
  izquierda y v2 a la derecha, con Kael), **`caras_v1_v2.png`** (primeros planos v1 | v2), `primer_plano_v2.png`
  (cinco junto a Kael de cerca), y `familia.png`, `caras.png`, `clips_<oficio>.png` ya con la v2 (las de la v1:
  `familia_v1.png`, `caras_v1.png`).
- **Lo que no llega:** siguen siendo personajes de geometría por partes y atlas pintado; la distancia con los
  protagonistas (modelos de Meshy con textura horneada) se acorta en manos, pelo, telas y caras, pero no desaparece.
  El siguiente salto sería hornear normales y oclusión de un modelo con más detalle (es otro presupuesto).

### 10. Vistas `w02` y `w04` repetidas

Cámara más alta (`fotos_mundo_vivo.gd`). Ya se ven el mercado (el frutero, la vendedora, los niños y la ronda al fondo)
y la Calle Mayor (Aldric, la vendedora y Bastián). Todas las capturas de la v2, en bajo, medio y alto, sin y con:
`D:\REBELUM_diagnostico\v12\expansion\mundo\capturas3_v2\comparar_<perfil>_<vista>.png` (y `log.txt` con las
llamadas y primitivas de cada vista).

### 11. Cumbres de Ciclópea: esbozo y plan (sin sector jugable)

No hay escena: no daba para dejar un sector jugable, apagado y probado. Hecho en su lugar:
`pruebas/herramientas/volcar_ciclopea_2d.gd` (vuelca la zona 2D del lugar 3 y propone el relieve) y
`fuente/esbozo_ciclopea.py` (maqueta de Blender). Salida en `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\`
(`plano_2d.png`, `relieve.png`, `ciclopea_2d.json`, `esbozo_desde_la_entrada.png`, `esbozo_de_arriba.png`). El plan
concreto (los ids y los sitios de la 2D, el relieve, los archivos, el interruptor `ciclopea3d` en `EN_PRUEBAS`, las
pruebas y la estimación) está en `docs/v12/INVENTARIO_MUNDO.md` §8. Dos cosas que salen del esbozo:
- Con laderas más altas que el camino, el camino queda como una trinchera: mejor que las laderas bajen a su altura.
- El hallazgo Tomo de Escarcha pide `cerca: "mirada"`, pero la 2D de este lugar no genera ningún rincón con ese
  nombre. Hay que comprobar dónde lo pone la 2D.

### 12. Pruebas de la segunda pasada

- `prueba_mundo_vivo` con la v2: **superada** (12 oficios por debajo de 6 000, 22 huesos, clips, atlas, rutinas,
  palomas, hablar, lejos, anochecer, vecinos).
- **Batería completa:** **136 · 0 · 63 · 0** sobre `499e897` (`D:\REBELUM_diagnostico\pruebas\2026-11-12_211428`): `partida.save` real y carpeta real de datos sin cambios («proyecto cambiado» = este informe, escrito durante la pasada; 359 avisos de «otros Godot» de otros especialistas). Tras el cambio del prado (§14), las 6 de Oakhaven (`prueba_oakhaven3d`, `_completo`, `prueba_distrito_oakhaven`, `prueba_toque_oakhaven`, `prueba_mundo_vivo`, `prueba_precarga`): **6 · 0**, proyecto y datos reales sin cambios.

### 13. Commits y archivos de la segunda pasada

- `1d8ddcd` familia v2 (y v1 conservada).
- `499e897` esbozo y plan de Ciclópea.
- (último) el prado de Oakhaven (§14) y este informe.

**Nuevos:** `aethelgard/personajes/npc_v12/v1/` (entera: `.gdignore`, los 12 GLB, atlas y JSON de la v1 y
`crear_npc_chibi_v1.py`), `aethelgard/pruebas/herramientas/volcar_ciclopea_2d.gd` + `.uid`,
`aethelgard/fuente/esbozo_ciclopea.py`.
**Cambiados (míos):** `aethelgard/fuente/crear_npc_chibi.py`, `aethelgard/fuente/render_npc_chibi.py`, los GLB, JSON y
atlas de `aethelgard/personajes/npc_v12/<oficio>/` (los `.import` no cambian), `aethelgard/pruebas/prueba_mundo_vivo.gd`,
`aethelgard/pruebas/fotos_mundo_vivo.gd`, `docs/v12/INVENTARIO_MUNDO.md`, `aethelgard/zonas3d/oakhaven/ciudad.gd` (el prado, §14) y este informe.
**Compartidos:** `aethelgard/pruebas/lista_pruebas.txt` (la nota de `prueba_mundo_vivo`: ≤ 6 000 triángulos). Nada más
compartido cambia en esta pasada. Tras copiar, `--import` (atlas y GLB nuevos) y revisar `git diff project.godot`.
### 14. El prado de Oakhaven después de los edificios (propuesta del especialista de rendimiento)

- **Hecho** en `zonas3d/oakhaven/ciudad.gd`: el material del «Prado» (el suelo fuera de la muralla) es una copia del de
  `materiales.detalle` (que se comparte por caché) con `render_priority = 2`: se dibuja después de los edificios.
- **Misma imagen:** las mismas vistas antes y después (`fotos_mundo_vivo.gd`, bajo, medio y alto; carpetas
  `D:\REBELUM_diagnostico\v12\expansion\mundo\prado\antes` y `\despues`). La plaza sale idéntica píxel a píxel (PSNR
  infinita); en las demás, las únicas diferencias son el contador de FPS, la fase de la respiración de Lya y Garon y
  alguna chispa (`prado\diferencia_medio_v04_puerta_sur.png`, `diferencia_medio_v06_calle_cuervo.png`: diferencia
  ampliada a la derecha). El suelo no cambia en ninguna.
- **Medida (PC, GPU por vista, medianas):** sin cambio apreciable en las seis vistas de la cámara del juego (por ejemplo,
  medio: plaza 1,04 → 1,04 ms, Puerta del Sur 0,92 → 0,92, Calle del Cuervo 0,99 → 0,99; alto: 2,03 → 2,02, 1,80 → 1,81).
  Con la cámara del juego dentro de la ciudad, el prado apenas queda bajo los edificios. El 10-15 % que midió rendimiento
  sería en otras vistas (desde fuera de la muralla) que estas capturas no tienen. En el Mali, que ya descarta lo
  tapado por su cuenta, se espera aún menos. Se deja aplicado: no cambia la imagen ni cuesta nada.