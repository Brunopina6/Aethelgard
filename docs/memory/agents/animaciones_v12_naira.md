# Animaciones V12 · Naira, «la Astrónoma del Eclipse» (nombre provisional)

## 12/11/2026, 00:00-00:40 · rama LOCAL `claude/v12-fase2-naira-concepto` (`D:\Aethelgard_v12_naira_concepto`)

Desde `claude/rebelum-v12` @ `1b8f720`. Sin push ni merge. No he tocado `combate.gd`, `grupo.gd`, `menus.gd`, las
zonas, `lista_pruebas.txt` ni `docs/recursos.md`. **Nada de esto se ve hoy en el juego.**

### Qué hay

**Tres conceptos 3D** (forma y color, no finales), hechos con Blender 5.2.3 por guion: geometría propia por partes,
atlas pintado por código y un esqueleto común de 23-24 huesos. No se ha descargado nada: es **obra propia del
proyecto**.
- `personajes/naira/fuentes_blender/naira_comun.py`: la base de las tres.
  - Cuerpo de 1,55 m (unas 4,2 cabezas, entre Kael y Lya).
  - Cara pintada con ojos grandes, el párpado algo caído (reservada), una ceja más alta y media sonrisa torcida
    (irónica), y un destello de estrella de cuatro puntas en el iris, que es su firma.
  - Mechones aplanados que se afilan y llevan el degradado del pelo (negro azulado con un reflejo azul).
  - Telas de dos caras: fuera, el color; dentro, el forro, con mapa estelar.
  - Aros, discos y estrellas para los accesorios.
  - Importa a Kael, Lya y Garon desde sus FBX del juego. Lya no trae reposo (su clip de reposo es la pose en T), así
    que se le bajan los brazos a mano.
- `naira_conceptos.py`: los tres conceptos, sus láminas y la comparativa.
- Orden: `blender -b --factory-startup -P naira_conceptos.py -- <raíz aethelgard> <carpeta> <A|B|C|ABC|comparativa>`.

**Láminas** en `D:\REBELUM_diagnostico\animaciones\2026-11-12\naira\conceptos\`:
- Una por concepto, `naira_<X>_lamina.png`, con siete columnas: silueta de frente, de perfil y de espalda; color de
  frente, a 3/4 y de espalda; y la pose de lanzar un hechizo.
- `naira_<X>_cara.png`: la cara en primer plano.
- `naira_<X>_hechizo.png`: la pose de hechizo, grande y con el círculo en el suelo. El círculo es un adorno de la
  lámina, no forma parte del modelo.
- `naira_<X>_escala.png`: Naira junto a Kael (1,70 m), Lya (1,52 m) y Garon (1,70 m), los modelos FBX del juego con
  las alturas relativas de `grupo_3d.gd`.
- **`comparativa_naira.png`**: los tres conceptos junto a los tres héroes, a 3/4 y a escala.
- `comparativa_naira_siluetas.png`: lo mismo, solo en silueta.
- Los `.blend` de cada concepto (`naira_<X>.blend`), fuera de Git (D-075).

| Concepto | Silueta (lo que la distingue) | Paleta | Instrumento | Triángulos (concepto) |
|---|---|---|---|---|
| **A · La Viajera del Eclipse** | Capa corta con la capucha bajada, faldones de tres largos (corto delante, a media pierna detrás), bufanda de lino con una punta delante y otra a la espalda, media melena con un mechón largo | Índigo de medianoche, ciruela, lino marfil y latón; forro de mapa estelar | Astrolabio de latón a la cadera, con un eclipse en el centro; flota y se abre al lanzar | 14 090 |
| **B · La Archivista de Constelaciones** | Abrigo largo de erudita, abierto, con mangas acampanadas; gafas redondas; trenza gruesa sobre el hombro; cinturones cruzados con estuches de pergaminos | Tinta azul verdosa, pizarra, forro violeta, lino y latón | Bastón-catalejo con una luna creciente y un tomo encadenado a la cadera | 14 020 |
| **C · La Portadora del Eclipse** | Media capa sujeta a un hombro (larga detrás y a la izquierda, corta a la derecha), tabardo bordado de constelaciones y pelo largo liso con corte princesa | Negro violáceo, ciruela y oro pálido | Planetario de aros de luz que flota a su espalda y libro en la mano; ojos de eclipse (pupila oscura con corona) | 13 136 |

**Por qué encajan con REBELUM.**
- Las tres comparten el chibi de fantasía del grupo: cabeza grande, ojos grandes de anime, botas y cinturones de
  aventurero, como Kael.
- Su tema es el pedido: estudiosa de constelaciones olvidadas, del eclipse y de la magia antigua. Lleva instrumentos
  de investigación (astrolabio, catalejo, tomo, planetario) y símbolos astrales pequeños: estrellas de cuatro
  puntas, lunas crecientes y el eclipse.
- **No es una maga cubierta de gemas:** no lleva gemas facetadas. Lo que brilla son bordados, el anillo del eclipse y
  el instrumento.

**Cómo se diferencia de Lya.**
- Lya es rubia, de blanco, azul cielo y oro, con gemas cian, vestido abierto de hombros y flores.
- Naira es morena con reflejos azules y viste de oscuro, cerrada y en capas de viaje. El metal es latón, no oro con
  cian, y los ojos son ámbar (A y C) o violeta (B), no azules.
- Su silueta tampoco es la de Lya: capa corta y faldones (A), abrigo largo (B) o media capa (C), no un vestido de
  vuelo.
- C lleva un tabardo y no una falda asimétrica, para no ser una «Lya oscura».

**Cómo se diferencia de una antagonista de magia negra.** Ninguna lleva:
- negro con rojo (el rojo es de Garon);
- picos, cuernos, garras, calaveras ni espinas;
- escote de reina oscura;
- ojos rojos.

En cambio:
- tiene formas redondeadas y prácticas;
- los acentos son cálidos (latón y ámbar) y el lino es claro;
- lleva cosas de investigación;
- la expresión es tranquila e irónica, no amenazante.

El concepto C es el que más se acerca a una hechicera oscura, por el negro violáceo, la capa larga y el pelo liso que
le tapa la espalda. Hay que tenerlo en cuenta si se elige.

**Recomendación: A, «La Viajera del Eclipse».** B y C se conservan enteros.
1. Tiene la silueta más propia del grupo: capa corta, faldones y bufanda. Se lee a 20 m y no repite el abrigo largo de
   Kael (B lo repite) ni la melena larga de Lya (C la recuerda).
2. Es la más clara frente a la antagonista: el lino marfil y el latón dan calidez sin perder la paleta oscura.
3. El astrolabio es un instrumento de investigación y también el foco de su magia. Da animaciones legibles (cuelga,
   flota, gira, crece y se lanza) y efectos que se pueden reutilizar.
4. Es el más barato de animar: tiene menos tela larga que B y C, y no lleva un bastón que atraviese el cuerpo.

Lo mejor de los otros dos, para añadir más adelante sin cambiar de concepto: las gafas o el tomo de B (por ejemplo,
unas gafas subidas a la frente) y el planetario de C como efecto de «magia poderosa».

### Modelo PROVISIONAL (concepto A) con esqueleto y clips

- `personajes/naira/fuentes_blender/crear_naira.py` (orden: `blender -b --factory-startup -P crear_naira.py --
  <raíz aethelgard> <carpeta de láminas>`).
- Genera `personajes/naira/naira_provisional.glb`, que pesa 1,37 MB y tiene:
  - **14 090 triángulos** y **23 huesos**;
  - **2 materiales**: la tela con el atlas de 1024 y el brillo emisivo;
  - el hueso `astrolabio`, hijo de la raíz.
- Genera también `naira_provisional_clips.json` (`"PROVISIONAL": true`), con la duración, el bucle y el impacto de
  cada clip.
- Referencia: los héroes de Meshy rondan los 10 300 triángulos y usan un solo material. Naira lleva unos 3 800 más y
  un material más (el brillo).
- `.blend` y lámina de clips: `D:\REBELUM_diagnostico\animaciones\2026-11-12\naira\modelo\`
  (`naira_provisional_clips.png`).

| Clip | Duración | Bucle | Impacto | Qué hace |
|---|---|---|---|---|
| reposo | 4,0 s | sí | | Respira, cambia el peso y parpadea; mano derecha en el cinturón; el astrolabio se mece |
| caminar | 1,0 s | sí | | Ciclo en el sitio, brazos opuestos, bote y giro de cadera |
| correr | 0,6 s | sí | | Inclinada, brazos doblados, zancada amplia |
| ataque | 1,2 s | | 0,40 s | El astrolabio sube a la mano, ella gira y lo empuja con un golpe de palma |
| recibir_golpe | 0,8 s | | 0,10 s | Retrocede con los ojos cerrados y se recupera |
| victoria | 2,0 s | acaba en pose | | Lo hace girar sobre la palma y se queda mirándolo |
| derrota | 1,6 s | acaba en pose | | Se tambalea, cae de rodillas y se encorva; el astrolabio cae al suelo |
| lanzar_hechizo | 1,5 s | | 0,87 s | Lo alza sobre la mano, gira y crece, y lo empuja hacia delante |
| concentracion | 2,0 s | sí | | Manos juntas delante del pecho, ojos cerrados; el astrolabio gira entre ellas |
| magia_poderosa | 2,5 s | | 1,70 s | Se recoge, alza los brazos con el astrolabio enorme sobre la cabeza y lo descarga |

Todos los clips son «en el sitio». Los que no son bucle vuelven a la pose del reposo, salvo victoria y derrota.

**Cómo se corrigieron las poses.** Primero se demostró la causa con medidas:
- **Brazos en alto:** el brazo se inclinaba hacia atrás porque, con el brazo levantado, doblar el antebrazo (−ax) lo
  lleva hacia atrás. Es la anatomía, no un fallo del giro: se comprobó la dirección del hueso a −90°, −158° y con el
  pecho inclinado. Arreglo: antebrazo recto. Además, con el brazo en alto, +ay es el que abre la izquierda.
- **Mano en el cinturón, manos juntas, palma del ataque y mano de la victoria:** se buscaron con una rejilla de giros
  de brazo y antebrazo hasta que la mano quedó a menos de 1,7 cm de su objetivo.

### Pruebas (aisladas, `ejecutar_pruebas.ps1 -Lista`, con listas propias en la carpeta temporal de mi área)

- **Importación:** la primera `--import` de esta copia (que no tenía `.godot`) vació los directorios de Dialogic en
  `project.godot`. Hice `git restore aethelgard/project.godot` y reimporté; después quedó estable. La importación se
  hizo con `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP` aislados.
- **`pruebas/fotos_naira.gd -- solo_comprobar`** (modo auto, sin ventana): **SUPERADA**, con `FALLOS: 0`.
  - Resumen: `D:REBELUM_diagnosticopruebas�6-11-12_002102esumen.md`.
  - Comprueba que el GLB carga, que hay AnimationPlayer y Skeleton3D con 23 huesos (y el del astrolabio, sin
    `neutral_bone`) y que los 10 clips duran lo esperado (±1 fotograma). Las 10 duraciones coinciden exactas.
  - También comprueba la altura de la malla en reposo (1,523 m; se esperaban 1,55 ± 0,03) y que hay 2 superficies.
- **Fallos que encontró la prueba antes de pasar** (FALLIDA a las 00:17 y a las 00:19): el GLB traía un hueso
  «neutral_bone».
  - **Causa demostrada:** 4 vértices sin peso en el borde del abrigo (z = 0,84).
  - `desierto_comun.por_altura` devuelve `{ha: 1 - t, hb: t}`. Cuando `ha` y `hb` son el mismo hueso, el
    diccionario se queda con `{hb: t}`, y justo en el borde (t ≈ 0) el peso cae por debajo del umbral.
  - **Arreglo en mi archivo:** `naira_comun.por_altura` suma los pesos de los tramos seguidos del mismo hueso, y
    `crear_naira.py` repasa los vértices sin peso (ahora quedan 0).
  - **Ismena tiene el mismo problema:** su `ismena.glb` también trae `neutral_bone` (observado con `grep` en el
    GLB; Oren no). Ver «Cambios que pido».
- **`pruebas/fotos_naira.gd`** (modo ventana): **MANUAL**. Terminó sin errores y sacó 85 capturas en
  `D:REBELUM_diagnosticopruebas�6-11-12_002116otos_naira`:
  - `naira_grupo.png`: con Kael, Lya y Garon, a 20 m y a 9 m con la cámara de la exploración, el grupo de cerca y la
    cara;
  - `naira_clips.png`: 16 instantes clave con una cámara como la del combate;
  - `naira_secuencia_lanzar_hechizo.png` y `naira_secuencia_magia_poderosa.png`: 12 fotogramas de cada uno;
  - `naira_cadena_mezclas.png`: reposo → ataque → reposo → recibir_golpe… con 0,2 s de mezcla, en tiempo real.
- En las tres pasadas: «partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios».
  En la de las 00:17, el ejecutor avisó de otro Godot que no era suyo (PID 29584, de otra copia). Los datos reales no
  cambiaron.

### Límites (honesto)

- **Es un concepto y un modelo PROVISIONAL**, no definitivo.
  - **Calidad:** las formas son sencillas, el atlas está pintado por código y las manos son manoplas con pulgar. Queda
    claramente por debajo del detalle de textura de Kael, Lya y Garon (Meshy). Las láminas se ven junto a ellos para
    que se note.
  - **Cara:** pintada, sin expresiones ni labios; solo parpadea con el hueso del párpado.
- **Presupuesto:** 14 090 triángulos y 2 materiales, frente a unos 10 300 triángulos y 1 material de los héroes.
  **Sin medir en el Redmi.** Los clips van muestreados en cada fotograma (GLB de 1,37 MB).
- **Telas:** se mueven con el esqueleto, sin física.
  - En «correr» y «derrota» los faldones y la capa pueden atravesar las piernas.
  - En «magia_poderosa» la capa corta se levanta poco con los brazos en alto.
  - Con el brazo muy alto, el hombro se pellizca un poco: solo hay un hueso de hombro.
- **Capturas de Godot:** la luz de mi escena de pruebas sale sobreexpuesta (Lya casi blanca y la piel de Naira
  lavada). Es la escena, no el modelo, y no compara la luz de una región real.
- **Mezclas:** la cadena con mezclas está capturada, pero en miniaturas pequeñas. No he revisado fotograma a fotograma
  si hay saltos.
- **Sin probar:** en una región, en el combate o con los sistemas de grupo, que no existen para ella.
- **Pendiente:** el nombre «Naira» sigue siendo provisional, y su historia es de narrativa.

### Cambios que pido (no los he hecho: no son archivos míos)

1. **`personajes/desierto/fuentes_blender/desierto_comun.py`, `por_altura`.** Sustituir el `return {ha: 1 - t, hb: t}`
   por:

   ```python
   w = {ha: 1 - t}
   w[hb] = w.get(hb, 0.0) + t
   return w
   ```

   Después, regenerar `ismena.glb` (lleva un `neutral_bone` por el mismo motivo).
2. **`pruebas/lista_pruebas.txt`.** Añadir:

   ```
   fotos_naira | ventana | salida={salida} | 400 | {salida} | V12 Naira PROVISIONAL: capturas con el grupo, clips en su instante clave, secuencias y mezclas
   ```

   Para que también pase en cada batería sin ventana, la comprobación es la misma prueba con `solo_comprobar`.
   Como el ejecutor busca el guion por el nombre, haría falta un envoltorio `prueba_naira_modelo.gd` que llame a
   `fotos_naira.gd`; puedo hacerlo si se quiere.
3. **`docs/recursos.md`.** Una fila: «Naira (V12, conceptos A, B y C y modelo provisional del A): obra propia,
   Blender 5.2.3 por guion (`personajes/naira/fuentes_blender/`), sin recursos externos».

### Siguiente paso propuesto

1. Que el usuario mire `comparativa_naira.png` y las tres láminas, y elija un concepto (o mezcle: por ejemplo, A con
   las gafas de B subidas a la frente).
2. Con el elegido:
   - una segunda pasada de calidad: manos con dedos, pliegues pintados, una loseta de expresiones (enfado, sorpresa,
     sonrisa abierta) y el pelo con más capas;
   - bajar a unos 10-11 mil triángulos;
   - huesos de capa y faldón para que la tela siga el movimiento;
   - medir en el Redmi un combate de prueba (lo programa el coordinador).
3. El enganche al grupo, al combate y a los menús, cuando existan sus sistemas. Por ahora el GLB solo se usa en
   `fotos_naira.gd`.
