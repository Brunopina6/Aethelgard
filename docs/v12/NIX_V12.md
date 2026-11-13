# Nix, cuarta heroína y maga negra (V12, 13/11/2026) — PROTOTIPO APAGADO

Encargo del usuario del 13/11: `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\Aethelgard_Nix_Maga_Negra.pdf`
(especificación propuesta, 16 páginas) y la lámina de concepto que facilitó el usuario
(`D:\REBELUM_diagnostico\v12\expansion\nix\referencia_nix_usuario.webp`; referencia, no se copia ni entra en el juego).

**Interruptor:** `nix_v12` (grupo.gd), APAGADO. Se enciende con `Engine.set_meta("nix_v12", true)` o con el argumento
`-- nix_v12`; con él Nix puede unirse (`Grupo.unir("Nix")`) y entra en el combate si va entre los activos. Sin él no
existe en ninguna partida ni combate, aunque una partida traiga sus datos.

**Estado por etapas** (como pide la especificación, pág. 14): diseñado · generado · importado · integrado · probado ·
validado en Android. Nada está validado en Android (el Redmi no está conectado). Ver la tabla del final.

## 0. Versión 2 (13/11, segunda pasada, centrada en la silueta)

El coordinador vio en la v1 que el modelo se alejaba mucho de la lámina del usuario. La v2 corrige la silueta con el
mismo generador (`fuente/crear_nix*.py`); la v1 se conserva entera en `aethelgard/personajes/nix/v1/` (con `.gdignore`:
GLB, JSON de clips, retrato y copia de sus guiones). Hoja con las mismas cámaras:
`D:\REBELUM_diagnostico\v12\expansion\nix\comparar\hoja_v1_v2_referencia.jpg`.
- **Sombrero** (la pieza clave): ala muy ancha (0,98 m de lado a lado, más de dos veces el pelo), ondulada, caída a su
  izquierda y levantada a su derecha, donde está la muesca de media luna (más honda, se ve de frente); canto lavanda
  levantado; copa más alta con la punta doblada hacia atrás; cinta de cobre ancha con rebordes, dos hebillas «#» y el
  broche redondo grande con la luna creciente.
- **Proporciones chibi:** piernas ×0,66 (antes 0,78) y más gruesas, caderas más anchas, cabeza más grande (≈ 3,4
  cabezas sin sombrero), botas anchas con suela gruesa y vuelta ancha, guantes ×1,36.
- **Pelo:** melena con volumen en campana, siete mechones encima que la parten en capas, flequillo de lado desde la
  raya a su izquierda (junto al mechón gris) que barre hacia su derecha, un mechón largo que enmarca la cara.
- **Ropa con vuelo:** faldón en dos alturas que se abre en picos (pico hacia la línea del centro, ribete de cobre y
  franja lila, forro lila); peto crema con pecho, costura y tres botones, en punta bajo el cinturón; capa corta en tres
  paños (dos aberturas a los lados) con picos delante y detrás, franja lila sobre el ribete y el rombo detrás.
- **Cara:** sombra de ojos violeta, raya alargada hacia el rabillo, cejas más marcadas y media sonrisa con los labios
  algo teñidos.
- **Bastón:** arco de hierro en media luna (grueso en el lomo, afilado en las puntas, con picos) alrededor del cristal,
  atravesado por una barra de cobre; la parte de arriba más corta para que la luna quede junto al ala, no debajo.
- **Bastón y sombrero no se atraviesan:** comprobación automática nueva (`fuente/crear_nix_verificar.py`: cada arista
  del bastón contra los triángulos del sombrero en 16 instantes de cada clip). Con el ala nueva chocaban 15 de los 20 clips; se
  rehicieron las poses con el bastón en alto (victoria, ritual, trazo, concentrarse) y el bastonazo (de lado y bajo, ya
  no por encima del hombro): **0 choques en los 20 clips** (`modelo\nix_baston_sombrero.json`). La victoria ya no se
  toca el ala (con brazos chibi no llega): mano en la cadera.
- Presupuesto: LOD0 9 779 + cara 184 = 9 963 triángulos (más en sombrero, pelo y faldón; menos en cabeza, manos,
  mangas y puños).

## 1. Qué se hizo de la especificación (v1; lo que la v2 cambia, en §0)

### Modelo 3D (págs. 5, 6 y 13)

- **Hecho con Blender 5.2.3 por guion**, sin mallas ni texturas de nadie: `aethelgard/fuente/crear_nix.py` (y sus
  módulos `crear_nix_diseno.py`, `crear_nix_texturas.py`, `crear_nix_clips.py`, `crear_nix_final.py`,
  `crear_nix_hojas.py`, `crear_nix_retrato.py`). Se rehace entero con una orden (unos 9 min en el PC):
  `blender -b --factory-startup -P fuente/crear_nix.py -- <raíz aethelgard> <carpeta de evidencias>`.
- **Rig compatible con el común de los héroes v2:** el esqueleto es el de Lya (mismos nombres Mixamo, jerarquía y
  orientaciones), re-proporcionado sin girar ningún hueso: piernas ×0,78, brazos ×0,9 y la cadera 17,6 cm más baja.
  Así valen la biblioteca de clips de los v2 (`biblioteca_clips.py`, por IK), los de combate v12
  (`clips_combate_v12.py`) y los de captura de andar y correr. 51 huesos deformantes (los 24-40 de la
  especificación se cumplen en los que mueven la malla; los demás son del rig común: dedos, cadenas de Lya sin
  pesos), cuatro pesos por vértice como mucho.
- **Proporción chibi del grupo:** la cabeza es geometría más grande sobre el mismo esqueleto. Unas 3,7 cabezas sin
  sombrero (la especificación propone 3,2; los demás héroes andan por 4,5: se buscó el punto medio para que no
  desentone junto a ellos). En el combate se escala a 0,56 (Lya 0,6, Kael y Garon 0,67): la cabeza de Nix queda a la
  altura de la de Lya y el sombrero por encima (hoja `nix_junto_al_grupo.png`).
- **Diseño** (original con la dirección de la lámina, sin calcarla): sombrero alto facetado de 9 caras inclinado
  hacia atrás con la punta doblada una vez, ala elíptica de dos niveles (ciruela arriba, lavanda debajo y en el canto)
  con una muesca de media luna, banda de cobre con tres grapas y un broche de disco negro descentrado con una luna;
  bob ciruela casi negro (una masa con volumen que cae en campana y acaba en ondas recogidas, flequillo de lado en
  tres masas, un mechón a cada lado de la cara) con el mechón plateado a su izquierda; cara propia (ojos almendrados
  amatista con pestañas, cejas por formas clave, boca, rubor y nariz pequeña modelada); abrigo corto ciruela con
  cuello alto y broche en rombo, peto marfil con dos botones, ribetes de cobre, falda de cuatro paneles en punta con
  forro lavanda y franjas lavanda delante, el peto que sigue en punta bajo el cinturón; capa corta con forro lavanda
  y un rombo de cobre en la espalda; cinturón de cuero con hebilla cuadrada; mangas ajustadas con puños marfil
  acampanados; guantes; medias grafito; botines de cuero con vuelta, correa y hebilla. Bastón: asta ciruela oscura,
  contera de cobre en punta, anillos de cobre, un arco de hierro roto y asimétrico que sostiene un cristal lavanda
  opaco con tres garras.
- **Sombrero y bastón rígidos, sin simulación:** el sombrero pesa 100 % en la cabeza; el bastón, 100 % en el hueso
  `arma_d` (en la mano derecha). La especificación propone un hueso para la punta del sombrero y dos para la capa,
  horneados: **no se hizo** (queda pendiente; ver §3).
- **Texturas:** un atlas de 1024 para todo el cuerpo (color pintado con su luz, grano, hebras del pelo y su anillo de
  brillo, pliegues, rubor y oclusión; metal y rugosidad; relieve horneado de una copia subdividida), comprimido en el
  juego (VRAM, ETC2/ASTC en Android) por el importador de Godot. Se hornea a 2048 y se reduce; los de 2048 quedan en
  las evidencias (un perfil PC con 2K es posible sin rehacer nada). Material del cuerpo: el de los héroes v2
  (`heroe_v2.gdshader`: mate en piel y tela, reflejo del ambiente solo en el cobre y el hierro, borde de luz). Dos
  materiales de personaje (cuerpo y cara) y el bastón dentro del atlas del cuerpo.
- **LOD** en el mismo GLB, elegido por distancia (`visibility_range` en `nix_3d.gd`): ver la tabla de triángulos.

### Clips (pág. 4)

Hechos con la biblioteca común (poses en el espacio del personaje, por IK) y el estilo de Nix (serena, erguida, la
barbilla algo baja bajo el ala, gestos precisos). Mapa REAL de clips del GLB (`personajes/nix/nix_clips.json`):

| Clip | s | Bucle | Instantes | Perfil de la especificación |
|---|---|---|---|---|
| reposo | 6,0 | sí | | idle (respira, cambia el peso una vez; nada de movimiento constante) |
| guardia | 2,4 | sí | | combat_idle |
| andar / correr | captura | sí | | walk_fwd / run_fwd (derivados del rig de Lya) |
| magia_lanzar | 1,4 | | lanzamiento 0,7 | P01 gesto_punta (Ascuas de Nácar) |
| magia_estado | 1,6 | | lanzamiento 0,8 | P02 trazo_lateral (Aguja de Invierno) |
| magia_culminante | 3,2 | | preparación 1,12 · lanzamiento 1,6 | P07 ritual_mayor (Colapso del Firmamento) |
| magia_concentrar | 2,2 | sí | | mientras prepara un hechizo largo |
| recibir_golpe | 0,35 | | impacto 0 | hit_front (0,35 s) |
| defender / defensa | 1,0 / 1,6 | no / sí | | defend (1 s) y la guardia alta mientras dura |
| victoria | 2,0 | | | victory (gira el bastón y se toca el ala del sombrero) |
| derribo / derrota | 1,5 / 3,0 | no / sí | suelo 0,95 | defeat (de rodillas: tumbada, el sombrero rígido se clavaba en el suelo) |
| levantarse | 1,3 | | | revive (1,2 s propuesto) |
| ataque | biblioteca | | impacto | bastonazo flojo |
| hablar, hablar_b, asentir, interactuar, saltar, girar | biblioteca | | | exploración y conversación |

Los perfiles siguen las ventanas normalizadas (anticipación 0-35 %, preparación 35-50 %, liberación al 50 %,
recuperación). **No hechos:** strafe_l/r, turn_l/r, hit_back, stagger y equip_idle (la biblioteca tiene «girar»; el
juego no usa los demás todavía).

### Magia negra: piloto de tres (págs. 7, 12 y 15)

| Id | Hechizo | Rango | Especificación | En el juego (ATB) |
|---|---|---|---|---|
| nix_01 | Ascuas de Nácar | I | 5 PM, 1,15 M, uno, Fuego | 5 PM, daño 40, uno, Fuego; da 1 sello. Efecto «ascua» de la magia negra (presupuesto Android ya medido por su especialista), color marfil |
| nix_02 | Aguja de Invierno | I | 5 PM, 1,10 M, uno, Hielo, Lento 10 % 1 turno, base 70 % | 5 PM, daño 38, uno, Hielo; **Lento del juego** (−40 % de velocidad ATB) 1 turno con 70 %; si falla se lee «Falla: Lento»; da 1 sello. Efecto «aguja_glacial», color lavanda |
| nix_21 | Colapso del Firmamento | VI | 48 PM, 4,00 M, grupo, Arcano, 3 sellos, CD 4, preparación visible | 48 PM, daño 140 a todos (con 4 o más, ×3/n cada uno), sin elemento; gasta 3 sellos, espera 4 turnos propios; se prepara (0,7 de barra, interrumpible como toda magia negra) y se suelta solo. Efecto «colapso_astral» (estrellas que se cierran en un punto: «un aro roto que se contrae») |

## 2. Qué se adaptó al ATB real (conversión documentada)

- **Ruta:** la de la magia negra que ya existe (`magia_negra.gd` + `combate.gd` `_lanzar_negra` / `_resolver_negra` /
  `_golpe_negra`), sin sistema paralelo. Cada hechizo es una «escuela» de un hechizo (el elemento va por escuela en el
  juego), en la pestaña «Magia negra» de Nix. Las reglas que el juego no tenía viven en
  `personajes/nix/nix_combate.gd` y solo tocan sus hechizos (clave `nix`).
- **Potencia:** el juego no tiene M = 100; el daño es `dano` × multiplicador mágico del héroe (`combate_formulas.gd`).
  Conversión: `dano = coeficiente × 35` (1,15 M → 40, igual que la Ascua de 5 PM de la magia negra existente).
- **Turnos:** el ATB tiene turnos propios: la espera (CD) cuenta los turnos de Nix («CD 4» bloquea sus cuatro
  oportunidades siguientes) y los estados, los turnos del afectado al empezar (como toda la magia negra). Sin
  equivalencias en segundos.
- **Lento:** se usa el Lento del juego (−40 % de velocidad de la barra), no un −10 % nuevo: un estado paralelo con
  otra magnitud sería otro sistema. La probabilidad base (70 %) sí es nueva y se tira solo cuando lanza Nix.
- **Eclipse (sellos):** hasta 3, en el diccionario del luchador (se pierden al acabar el combate). Un hechizo de rango
  I-IV que resuelve y alcanza a un blanco válido da 1 (uno por acción). Los de V gastan 2 y los de VI, 3; los que
  gastan no dan. Se gastan al confirmar (con los PM); si el conjuro se rompe, no se devuelven (regla de la
  especificación). Se ve en el menú («◈3 · 48 PM» y el motivo si faltan) y al ganar uno («Eclipse ◆◆◇»).
- **Arcano:** el juego no tiene ese elemento: va sin elemento (ninguna afinidad lo resiste ni lo debilita).
- **Área:** «con 4 o más blancos, ×3/n» en `magia_negra.gd dano_base` (`reparto_area`), solo para hechizos que lo
  piden.
- **Ruptura, crítico, evasión, precisión:** el juego no tiene barra de postura ni precisión: los hechizos que dependen
  de ello (nix_03, 04, 07, 08, 19, 20) quedan para cuando se decida; ninguno del piloto los usa.
- **Desbloqueo:** el piloto se aprende al unirse (umbral 1) para poder probarlo; la especificación propone niveles 1
  y 50.
- **Menú:** Atacar / Magia (pestaña Magia negra) / Objeto / Defender / Huir. Nix no tiene invocación propia; la orden
  INVOCACIÓN del menú común es la de siempre (Érebo lo invoca Lya con la Armonía llena) y se ve igual que para Kael:
  no se tocó (Érebo y la Armonía no cambian).
- **Sonido:** por ahora, los de la magia negra de su elemento (`negra_fuego`, `negra_hielo`, `negra_colapso`).

## 3. Qué queda

- El catálogo completo (24 hechizos en seis rangos), con elemento por hechizo y agrupado por rangos en el menú.
- Huesos secundarios horneados de la punta del sombrero y de la capa (especificación pág. 5); hoy la capa sigue a los
  hombros y a los brazos por pesos.
- Pulido de arte: más detalle pintado de cerca (costuras, bordados, mechones con hebras en relieve); los héroes de
  Meshy tienen más textura que Nix. La silueta, los colores y la cara se leen bien a la distancia del combate.
- Retrato de diálogo y personaje de Dialogic; esperas de exploración; acompañante en las regiones 3D
  (`zonas3d/grupo_3d.gd`); sonidos y voz propios; su arma en el inventario (hoy el bastón va en el modelo).
- Medir en el Redmi (combate de cuatro con efectos; protocolo de la pág. 13) y comparar el coste de su material.
- Las licencias: el esqueleto y los clips de captura de andar y correr son derivados del rig de Lya (Meshy).

## 4. Pregunta abierta para el usuario: Nix y Naira

El proyecto ya tiene a **Naira** (maga negra, «Astrónoma del Eclipse», prototipo sin aprobar con su misión, sus
escuelas y su firma, el Eclipse) y unos dibujos 2D antiguos de «Nyx». **Nix** es otra maga negra, también prototipo
y apagada. Las dos pueden convivir en el código (cada una con su interruptor), pero no en la historia. ¿Qué prefieres?
1. Nix sustituye a Naira (su misión y sus escuelas pasarían a Nix o se retirarían).
2. Nix toma el diseño visual y Naira la historia (o al revés).
3. Las dos, con papeles distintos (otra cosa que no sea maga negra para una de ellas).
Además: el nombre del recurso «Eclipse» de Nix coincide con la firma de Naira; si conviven, uno debería cambiar.

## 5. Evidencias y pruebas

Ver el informe `docs/memory/agents/animaciones_v12_nix.md`.
