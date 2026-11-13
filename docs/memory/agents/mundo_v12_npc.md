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
---

## 13/11/2026 · tercera pasada: Cumbres de Ciclópea 3D, primer sector (misma copia y rama)

Encargo: el primer sector de las Cumbres según el plan del §8 del inventario, apagado tras `ciclopea3d` (`EN_PRUEBAS`), con la
2D intacta: laderas a la altura del camino (sin trinchera), entrada y salida, colisiones, guardado y carga, hallazgos y
cofres de la 2D en su sitio (comprobando el Tomo de Escarcha), vegetación y luz de cumbre fría con identidad propia,
presupuesto Android de las otras regiones (pocos recortados, orden de dibujo), pruebas, capturas en los tres perfiles y
medida con `medir_escenas` (con «ciclopea»). La sesión se cortó por el límite de uso y se reanudó sin perder nada
(todo estaba en la copia; se confirmó en `4ae30a4`).

### 15. Qué hay (todo [E] en el PC, aislado)

- **Escena** `zonas3d/ciclopea_3d.tscn/.gd` (el contrato de las regiones, copiado del Gran Bosque sin tocarlo):
  Kael, cámara, grupo, encuentros por pasos con la zona «nieve», combate y vuelta al mismo sitio, cofres, detalle,
  hallazgos, altar, brazalete, comentarios del grupo, Incienso, guardado (al entrar, tras cofre, hallazgo, combate y al
  pausar), salida señalada al sur y partidas 2D ↔ 3D.
- **Trazado** `zonas3d/ciclopea/trazado.gd`: el de la 2D (`disposicion_2d.gd`, volcado de `zona.gd` con
  `pruebas/herramientas/volcar_ciclopea_2d.gd`: 80 × 56 casillas, 298 objetos, 3 cofres, 1 puente) a 1,25 m por casilla.
  El camino sube **7,5 m** del sur al altar (mitad lineal, mitad suave: ≤ 14 %). **Sin trinchera:** el suelo tiene la
  altura del camino de su misma latitud en 2,6 casillas a cada lado y solo más allá suben las lomas de nieve; la prueba
  mide como mucho **+0,23 m** a 2,1 casillas del camino en todo su recorrido. Paredes de roca en el borde que crecen hacia
  el norte, lagos y arroyo helados hundidos (no se pisan), el paso de la entrada abierto.
- **Escenario** `zonas3d/ciclopea/escenario.gd`, identidad propia de cumbre fría: nieve azulada con su relieve y la
  nieve pisada del camino, roca donde la pendiente no sujeta la nieve, cumbres nevadas al fondo (una malla), pinos
  nevados de varios pisos y abetos achaparrados en las laderas (los 195 de la 2D en su casilla y 70/110/170 más según el
  perfil, fuera del paso), rocas con su capa de nieve (las 84 de la 2D y peñascos al pie de las paredes), hielo
  azul-verdoso, el puente de madera con barandas nevadas sobre el arroyo, las ruinas (columnas, muros), **la estatua
  sin brazo izquierdo** que mira al pico con su brazo caído al pie, el campamento con su tienda, leña y el brasero de la
  2D (luz real en alto, halo pintado en bajo y medio), el altar con el orbe azul y menhires, y la nevada que sigue a
  Kael. Luz: sol bajo blanco frío, ambiente azulado, bruma fría, sin la verde del Gran Bosque ni la cálida de Pastos.
  Fauna: dos aves que planean alto (sin conejos en la nieve).
- **Rendimiento** (lo aprendido en las otras regiones): ningún recortado ni transparencia en lo grande (pinos y rocas
  son geometría opaca con color por vértice, un material para todos); pinos y rocas en MultiMesh por trozos de 25 m con
  su distancia por perfil (46/56/90 m); lo pequeño junto en lotes (y la estatua en una malla por material: de 32 a 6
  llamadas con sombra); **el suelo y el hielo con `render_priority = 2`** (después de lo que los tapa); bajo y medio,
  el suelo con una lectura de textura (sin triplanar); sombras solo de pinos, rocas y piezas en medio y alto; la nevada
  con partículas opacas (50/80/130).
- **Hallazgos y cofres de la 2D en su sitio:** los tres cofres con sus ids (`3_1644_2905` ruinas, `3_1466_2229`
  campamento, `3_4168_1815` claro) y el premio de la 2D (`hash(id)`); los cofres de hallazgo donde los pone la 2D
  (`zona.gd`, `_sitio_hallazgo`, volcado en `HALLAZGOS`): **Pluma de Arpía** (24,3, 47,0, junto a las ruinas) y **Tomo de
  Escarcha** en **(25,7, 42,0)**: la 2D, para «mirada», usa el rincón de las ruinas + (−1,4, 1,0) + (1,4, −5,0), es
  decir **4 casillas al norte de las ruinas, adonde mira la estatua** (y luego la casilla libre más cercana). El
  detalle `ciclopea_estatua` (Guardiana de Ámbar al examinarlo) en (27,1, 46,9), donde lo pone la 2D.
- **Interruptor:** `modo3d.gd`: `CICLOPEA = 3` en `REGIONES`, `EN_PRUEBAS[3] = "ciclopea3d"` y en `EQUIVALENTES_ZONA`.
  Sin el argumento ni la elección en Ajustes, el mapa lleva a la 2D de siempre (`zona.tscn` con el lugar 3, intacta), y
  **una partida guardada en la 3D con la región apagada abre la 2D en la misma casilla** (cambio en
  `escena_equivalente`: la vuelta a la 2D vale también para las regiones en pruebas con 2D; hoy solo Ciclópea, el Mar de
  Cristal no está en esas tablas). Ajustes: «Cumbres de Ciclópea: 2D (la de siempre) / 3D (en pruebas)», una línea en
  `menus.gd` en el bloque de las regiones en pruebas.
- **Música:** `musica.gd` no conoce la escena (no es mío): se pide el ambiente de la 2D de este lugar, «viento», como
  hace el Gran Bosque. Para el coordinador: una línea en `musica.gd` (`"res://zonas3d/ciclopea_3d.tscn": return "viento"`).

### 16. Pruebas

- **`prueba_ciclopea3d`** (con `3d ciclopea3d`): **superada**. Disposición = `zona.gd`; el Tomo donde la 2D; el
  interruptor (sin el argumento, apagada; sin la exploración 3D, apagada; en pruebas, no por defecto); partida de la 2D →
  3D en la misma casilla; el camino principal entero sin prohibidos ni escalones (≤ 0,3 m por 0,2 casillas) y sube 7,5 m;
  sin trinchera; Kael anda de verdad (destino, como un jugador) de la entrada a la primera curva; pinos y rocas chocan;
  cofres y cofres de hallazgo en su sitio y alcanzables; abrir un cofre lo apunta (y una segunda vez no da nada); la
  estatua: «Examinar», su texto y el detalle visto; guardar y cargar al mismo sitio (0,00 m); 3D ↔ 2D; un encuentro
  apunta zona «nieve», vuelta y sitio; la salida del sur lleva al mapa.
- **`prueba_ciclopea3d_apagada`** (con `3d` sin el argumento): **superada**. El mapa lleva a la 2D, una partida de la 2D
  se queda en la 2D y una de la 3D abre la 2D en su casilla.
- `prueba_restaurar_escenas` y `prueba_hallazgos` (la Ciclópea 2D con sus hallazgos): superadas.
- **Batería completa:** **138 · 0 · 64 · 0** sobre `4d9ac67` (`D:\REBELUM_diagnostico\pruebas\2026-11-13_012252`): `partida.save` real, carpeta real de datos y proyecto sin cambios (169 avisos de «otros Godot», de otros especialistas).

### 17. Capturas y medida (PC; no es el Redmi)

- Capturas en `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\fotos_final\` (`<perfil>_1280x720_k01…k11.png`,
  `perfiles.png`, `medio_rincones.png`; `log_<perfil>.txt` con llamadas, primitivas y GPU). Un aviso de método: con los
  tres perfiles en una sola pasada la ventana dejó de dibujar (medio y alto con las mismas cifras): cada perfil se sacó
  aparte.
- **Llamadas de dibujo y primitivas por vista** (cámara del juego):

| Vista | Bajo | Medio | Alto |
|---|---|---|---|
| Entrada | 48 · 110 k | 90 · 182 k | 137 · 275 k |
| Subida | 40 · 110 k | 70 · 183 k | 102 · 273 k |
| Puente | 41 · 112 k | 67 · 187 k | 91 · 270 k |
| Ruinas y estatua | 58 · 109 k | 106 · 181 k | 134 · 267 k |
| Campamento | 39 · 108 k | 72 · 181 k | 92 · 266 k |
| Claro | 44 · 114 k | 78 · 190 k | 93 · 274 k |
| Altar | 35 · 110 k | 56 · 178 k | 65 · 261 k |

  Comparado con lo que piden las regiones (bajo y medio del orden del bajo de Pastos: 100-150 llamadas y 200-300 k
  triángulos por vista) y con Oakhaven en esta misma copia (medio, plaza: 98 llamadas y 286 k), las Cumbres quedan por
  debajo en todas las vistas. GPU del PC por vista: 0,8-1,1 ms (bajo), 1,0-1,7 ms (medio), 1,8-2,0 ms (alto).
- **`medir_escenas`** (`-Escenas ciclopea,granbosque,pastos -Perfiles bajo,medio,alto -Ciclos 3`, misma pasada para
  comparar):
| Escena | Perfil | Dibujos | Primitivas | 1.ª carga / repetida (ms) | Memoria estática / vídeo (MB) |
|---|---|---|---|---|---|
| ciclopea | bajo | 32 | 108 k | 2 648 / 639 | 123 / 63 |
| ciclopea | medio | 67 | 180 k | 4 161 / 821 | 123 / 64 |
| ciclopea | alto | 112 | 274 k | 2 758 / 777 | 123 / 82 |
| granbosque | bajo | 100 | 194 k | 2 935 / 805 | 129 / 70 |
| granbosque | medio | 176 | 300 k | 5 861 / 1 370 | 130 / 71 |
| granbosque | alto | 266 | 566 k | 3 471 / 1 072 | 131 / 105 |
| pastos | medio | 116 | 328 k | 3 636 / 1 086 | 139 / 86 |
| pastos | alto | 171 | 455 k | 3 497 / 1 007 | 141 / 106 |

  (Carpeta `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\medidas\`, `resumen.md` y `procesos.txt`.) En el sitio
  de la herramienta (Kael en la entrada, andando un cuadrado), las Cumbres piden **menos de la mitad de llamadas que el
  Gran Bosque** y menos primitivas que Pastos y el Gran Bosque en los tres perfiles, entran antes (repetida 0,6-0,8 s) y
  usan menos memoria de vídeo. **Los tiempos por fotograma de esta pasada no valen:** salen clavados en 25 ms (la
  ventana quedó limitada a 40 Hz, y en Pastos bajo ni dibujó: 0 llamadas) y había otros Godot y ffmpeg a la vez
  (`procesos.txt`). Los 5 tirones del alto son todos del ciclo 2 de «activo», sin nodos nuevos en esos fotogramas y sin
  repetirse en los ciclos 1 y 3: no parecen de la escena, pero hay que mirarlos en el Redmi.

### 18. Lo que queda

- **Redmi:** nada medido en el teléfono. Con Ajustes → «Cumbres de Ciclópea: 3D (en pruebas)», medir bajo y medio en la
  entrada, el puente, las ruinas y el altar; mirar el blanco de la nieve en el bajo (`brillo_sin_sombras` 1,12, a ojo)
  y la nevada.
- La ventisca (`mar_cristal/clima.gd`) y la estatua como pieza de Blender (ahora de primitivas, en una malla por
  material) quedan para una segunda pasada. Glacius Niflheim sigue sin combate (narrativa).
- La actividad de la región (refugios de montaña, §7 del inventario) no está hecha.
- `musica.gd`: la línea del contexto (§15).

### 19. Commits y archivos de la tercera pasada

- `4ae30a4` el primer sector, sus pruebas y la medida con «ciclopea».
- `4d9ac67` la estatua en una malla por material, el inventario y el informe; (último) el resultado de la batería.

**Nuevos:** `aethelgard/zonas3d/ciclopea_3d.gd` + `.uid`, `aethelgard/zonas3d/ciclopea_3d.tscn`,
`aethelgard/zonas3d/ciclopea/` (`disposicion_2d.gd`, `trazado.gd`, `escenario.gd` y sus `.uid`),
`aethelgard/pruebas/prueba_ciclopea3d.gd`, `prueba_ciclopea3d_apagada.gd`, `fotos_ciclopea3d.gd` (+ `.uid`).
**Cambiados (míos):** `aethelgard/pruebas/herramientas/volcar_ciclopea_2d.gd` (escribe ya `disposicion_2d.gd`),
`docs/v12/INVENTARIO_MUNDO.md`, este informe.
**Compartidos:** `aethelgard/modo3d.gd` (CICLOPEA en REGIONES, EN_PRUEBAS y EQUIVALENTES_ZONA; la vuelta a la 2D para
las regiones en pruebas con 2D: 8 líneas), `aethelgard/menus.gd` (una línea), `aethelgard/pruebas/medir_escenas.gd`
(«ciclopea» en sus escenas) y `medir_escenas.ps1` (en la lista por defecto; con BOM), `aethelgard/pruebas/lista_pruebas.txt`
(tres líneas al final). `project.godot` sin cambios. Tras copiar: `--import` y revisar `git diff project.godot`.
**Cómo se enciende:** Ajustes → «Cumbres de Ciclópea: 3D (en pruebas)» (`[regiones] ciclopea3d = true`) o
`-- 3d ciclopea3d`. Por defecto, APAGADO (el mapa lleva a la 2D de siempre).
## 13/11/2026 · cuarta pasada: Cumbres de Ciclópea 3D, segunda pasada (misma copia y rama)

Encargo: la estatua como pieza propia de Blender (sin brazo izquierdo, mirando al pico, presupuesto Android y LOD; la de
primitivas, de respaldo), la ventisca (ligera, sin transparencias grandes, que vaya y venga) y la actividad de la región
(refugios de montaña, §7 del inventario), sin Orbes Cristalinos ni giros de historia. **Todo dentro de `ciclopea3d`
(APAGADO por defecto).** Nada se ha medido en el Redmi.

### 20. La estatua (pieza propia de Blender)

- `aethelgard/fuente/crear_estatua_ciclopea.py` (Blender 5.2 por guion, `-b --factory-startup`): un caballero sobre su
  peana con placa del anillo partido; grebas, faldar con pliegues, peto con un relieve de alas, la mano derecha sobre el
  pomo de la espada clavada delante, la capa por detrás, el yelmo alzado unos 14° **hacia el pico** con la cresta rota y
  **el hombro izquierdo partido** (muñón de piedra quebrada, sin brazo). Color por vértice (piedra gastada, líquenes,
  ocre, nieve donde la cara mira arriba, carámbanos en la cornisa), sin texturas. Escribe
  `zonas3d/ciclopea/modelos/estatua.glb` (**2 788 triángulos, 1 554 vértices, 0,11 MB**; LOD y mallas de sombra de la
  importación de Godot) y la lámina `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\estatua\estatua_lamina.png`.
- Un fallo encontrado y arreglado en las capturas: con `export_vertex_color = 'ACTIVE'`, Blender 5.2 sacaba un
  `COLOR_0` blanco y el color de verdad en `COLOR_1` (Godot solo lee el primero: la estatua salía blanca). Ahora se
  exporta por nombre (`'NAME'`, «Col», sin los demás): `COLOR_0` lleva la piedra.
- `escenario.gd`, `_crear_estatua()`: instancia la pieza («Pieza») con el material de detalle de la región (grano y
  relieve triplanar sobre el color por vértice, `vertex_color_is_srgb`), su choque (0,85 m) y la misma orientación al
  norte. **Respaldo:** sin el GLB, o con `Engine.set_meta("ciclopea_estatua_primitivas", true)`, sale la de primitivas
  de la tercera pasada (`_estatua_primitivas`, 3 mallas, intacta). Examinar y el detalle `ciclopea_estatua` no cambian.

### 21. La ventisca

- `zonas3d/ciclopea/ventisca.gd` (propia; `mar_cristal/clima.gd` no se toca: su tormenta es de arena y vive en el
  Mar de Cristal). **Va y viene:** calma 70-110 s (la primera, 35-60 s, para que se vea en una visita corta) → sube 7 s →
  ventisca 24-36 s con rachas → amaina 8 s → calma.
- **Ligera:** no añade nada transparente a pantalla completa. La bruma es la del entorno (se cierra hasta 0,034 y
  blanquea, sin coste extra), el sol baja al 38 % (sombras flojas) y el ambiente sube un 15 %; la nevada que ya había se
  vuelve casi horizontal y más rápida; y pasan **ráfagas**: partículas opacas sin luz, finas (3,5 × 42 cm), alargadas en
  el viento, alrededor de Kael (40 / 70 / 110 según bajo / medio / alto), solo con la ventisca alta.
- **Al abrigo:** junto a un refugio encendido (5 m) la ventisca se nota un 80 % menos (en la prueba: 0,15 junto al fuego,
  0,84 a la intemperie).

### 22. Los refugios de montaña (la actividad de la región)

- `zonas3d/ciclopea/refugios.gd`: **tres refugios de piedra** junto al camino principal (al 12 %, 52 % y 90 % de la
  subida: «el refugio del paso», «de media ladera» y «de la cumbre»), en la casilla libre más cercana a 3,2-5,2 casillas
  del camino (sin muros, agua, objetos, cofres, rincones ni el altar; la vegetación extra se aparta). Tres paredes, tejado
  inclinado con nieve, hogar, leña y banco, en una malla por material, con choque. Fuego de conos sin luz y un halo
  pequeño; luz real solo en los perfiles con faroles.
- **Cómo se juega:** en la puerta, «Encender el refugio» (leña seca y pedernal): fuego, hito `cc_refugio_N`, **1 Poción**
  y guardado. **Los tres encendidos: 120 monedas, una vez** (hito `cc_refugios`). Encendido, «Descansar junto al fuego»
  cura al grupo y guarda. Con el de abajo y el de arriba encendidos se abre **el atajo** («Bajar / Subir por el atajo»,
  con fundido) entre los dos. Siguen encendidos al cargar. **Sin Orbes Cristalinos** y sin texto de historia: solo
  avisos de lo que pasa. La «capa de abrigo» que proponía el §7 no se hace (sería tocar el equipo, fuera de mi zona).
- `ciclopea_3d.gd`: crea refugios y ventisca, el abrigo según la posición de Kael, las piezas al alcance y la acción
  (`_usar_refugio`, `_atajo`), y el sonido de hoguera en los encendidos.

### 23. Pruebas, capturas y medida (PC; no es el Redmi)

- **Nueva:** `pruebas/prueba_ciclopea3d_v2.gd` (en `lista_pruebas.txt`, al final): estatua de Blender (presupuesto,
  mira al norte, choca) y respaldo de primitivas; ventisca (bruma, sol, ráfagas opacas), amaina y da la vuelta sola;
  tres refugios alcanzables y bien puestos; encender (hito, fuego, Poción), atajo de bajada, los tres (120 monedas una
  vez), descansar cura sin más premio, abrigo, y al cargar siguen encendidos. **FALLOS 0.**
- `prueba_ciclopea3d` y `prueba_ciclopea3d_apagada`: **superadas** con todo lo nuevo dentro.
- **Capturas** en `D:\REBELUM_diagnostico\v12\expansion\mundo\ciclopea\pasada2\` (`<perfil>_1280x720_k01…k17.png`,
  un perfil por pasada; `log_<perfil>.txt`): las de la tercera pasada más `k12_refugio_del_paso`,
  `k13_refugio_de_la_cumbre`, `k14_ventisca`, `k15_ventisca_al_abrigo`, `k16_estatua_de_frente` y
  `k17_estatua_mira_al_pico`.
- **Llamadas · primitivas** (cámara del juego): ruinas con la estatua 59 · 111 k / 107 · 186 k / 136 · 272 k (bajo /
  medio / alto; antes, con la de primitivas, 58 · 109 k / 106 · 181 k / 134 · 267 k); refugio del paso 51 · 109 k /
  104 · 183 k / 138 · 270 k; ventisca 41 · 110 k / 74 · 183 k / 109 · 274 k. GPU del PC con la ventisca igual que sin
  ella (0,76 / 1,02 / 1,99 ms). Todo sigue por debajo de Oakhaven y del Gran Bosque.
- **A mirar en el Redmi:** la ventisca en el bajo (la bruma y las ráfagas), el halo del fuego y el blanco del bajo
  (en el bajo, el arroyo helado ya brillaba mucho en la tercera pasada; no es de esta).

### 24. Commits y archivos de la cuarta pasada

- `c79c109` la estatua, la ventisca, los refugios, sus pruebas y capturas, el inventario y este informe; (último) el
  resultado de la batería.
- **Batería completa:** 139 superadas · 0 fallidas · 64 manuales · 0 no seguras (antes 138 · 0 · 64 · 0; +1, la nueva);
  partida real, carpeta de datos y proyecto sin cambios (`D:\REBELUM_diagnostico\pruebas\2026-11-13_021227\resumen.md`).

**Nuevos:** `aethelgard/fuente/crear_estatua_ciclopea.py`, `aethelgard/zonas3d/ciclopea/modelos/estatua.glb` + `.import`,
`aethelgard/zonas3d/ciclopea/ventisca.gd` + `.uid`, `aethelgard/zonas3d/ciclopea/refugios.gd` + `.uid`,
`aethelgard/pruebas/prueba_ciclopea3d_v2.gd` + `.uid`.
**Cambiados (míos):** `aethelgard/zonas3d/ciclopea/escenario.gd`, `aethelgard/zonas3d/ciclopea_3d.gd`,
`aethelgard/pruebas/fotos_ciclopea3d.gd`, `docs/v12/INVENTARIO_MUNDO.md`, este informe.
**Compartidos:** `aethelgard/pruebas/lista_pruebas.txt` (una línea nueva al final y la nota de `fotos_ciclopea3d`),
`docs/recursos.md` (una fila al final). Nada en `modo3d.gd`, `menus.gd`, `combate.gd`, `grupo.gd`, `inventario.gd` ni
`project.godot`. Tras copiar: `--import` (el GLB nuevo).
**Cómo se enciende:** como en la tercera pasada (Ajustes → «Cumbres de Ciclópea: 3D (en pruebas)» o `-- 3d ciclopea3d`);
la estatua, la ventisca y los refugios van dentro. Para ver la estatua vieja: `Engine.set_meta("ciclopea_estatua_primitivas", true)`.