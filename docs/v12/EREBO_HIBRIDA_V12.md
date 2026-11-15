# Invocación híbrida de Érebo (V12, desde el 15/11/2026)

**Estado:** EXPERIMENTAL, APAGADA por defecto. Nada de lo que hay aquí está aprobado: espera la revisión del usuario.

**Encargo** (usuario, 15/11, resumido): conservar el diseño, el ambiente y los efectos de Érebo que ya vio en el vídeo,
y mejorar la ACCIÓN y su CONEXIÓN con el enemigo, como UNA sola acción: (1) se ve claramente al enemigo elegido;
(2) Érebo aparece y se acerca a él; (3) le lleva la mano al pecho y (4) le saca un corazón espectral, que queda en su
mano; (5) sigue el ritual del orbe (energía violeta, negra y plateada, absorción y onda); (6) vuelta al combate con el
resultado aplicado UNA vez. Nunca debe aparecer directamente con el orbe sin haber visto la extracción.

## 0. Reglas que no cambian

- **El mismo dado** (`invocacion_erebo.gd` / `combate.gd` `INVOCACION`): un `randf()` contra el 20 % para un enemigo
  normal; los jefes, sin dado (siempre `maxi(1, round(PV × 0,2))`). La híbrida lo tira **antes de cualquier efecto**,
  con el mismo generador y la misma expresión que la variante de vídeo, y el resultado lo aplica `combate.gd` **una
  sola vez** (`al_resultado`) al volver al combate, también si se salta.
- **El mismo ATB** que la invocación de siempre con ese resultado (`invocacion_erebo_video.gd` `ATB_TEATRO`, la regla
  `pausa_atb` de las animaciones v12): corre hasta el menor de esos tiempos y, al acabar, se abona lo que falte. No
  depende de lo que dure la híbrida.
- **Sin cambios en textos de resultado** ni nuevos textos que revelen que Érebo guarda corazones o recuerdos (acto III).
  El único texto nuevo es la descripción de la opción en Ajustes (solo Auditoría).
- **Los vídeos originales no se tocan.** El ritual usa dos `.ogv` NUEVOS derivados de los mismos renders maestros.
- **El enemigo de verdad no se toca**: la extracción ocurre en el escenario 3D de la invocación (el de siempre) sobre
  una COPIA de su modelo (`combate.gd` `_doble_3d`, la misma que usa el teatro de siempre). La prueba compara su nodo,
  mallas y materiales antes y después.

## 1. Cómo se activa

- **Ajustes → «Érebo: invocación cinematográfica» → «Híbrida» (≈24 s) o «Híbrida abreviada» (≈16 s)** (solo APK de
  Auditoría o editor; desde el 15/11 tarde, las dos en una segunda línea bajo los botones del vídeo). Es un valor más del
  selector del vídeo (la misma clave `[calidad_pruebas] erebo_cine` de `user://ajustes.cfg`); con él, el vídeo queda
  apagado (`invocacion_erebo_video.gd` no conoce ese valor y devuelve «no»). Elegir «No», «Abreviada»… lo devuelve
  todo a como estaba.
- **Banco de pruebas → «Érebo: invocación»**: «De siempre», «Vídeo» (abreviada), «Híbrida» e «Híbrida abreviada»
  («Híbrida 3D» queda solo por argumento).
- **Valores** (`invocacion_erebo_hibrida.gd`, `MODOS`):
  - `hibrida`: ritual con el tramo de la versión COMPLETA del vídeo (12 s);
  - `hibrida_breve` («Híbrida abreviada»): la MISMA parte en tiempo real (señal, acercamiento, mano, extracción del
    corazón y orbe) y el ritual con el tramo de la ABREVIADA (5 s). Mismas reglas, mismo ATB;
  - `hibrida_3d`: todo en tiempo real (el ritual es el de la invocación nueva: aplastar el orbe y hundirse).
- **Pruebas**: `erebo_cine=hibrida|hibrida_breve|hibrida_3d` en la línea de órdenes manda sobre el ajuste.
- **Integración** (ganchos mínimos, comentados «V12, Érebo híbrida»): `combate.gd` `_invocar_sobre` (6 líneas antes
  del vídeo), `menus.gd` (un botón más en la fila del vídeo) y `banco_pruebas.gd` (un selector). Con la opción apagada
  el camino es exactamente el de hoy (de siempre, nueva o vídeo).

## 2. La secuencia por fases (tiempos de juego medidos en la captura con ventana, Grimfang)

| Fase | Desde | Qué se ve | Cámara |
|---|---|---|---|
| 1 · Señalar | 0,0 s | En el combate, todo se oscurece salvo el enemigo elegido; dos aros (violeta y plata) se cierran sobre él (0,9 s). Mientras, se monta el escenario | La del combate |
| 2a · El enemigo | ≈1,2 s | Fundido a negro y, del negro, el escenario de la invocación (el de siempre: Lya y el modelo del enemigo). Plano del enemigo con un sello violeta a sus pies; Lya alza el bastón, la luz baja | Plano medio del objetivo, encuadre según su alto |
| 2b · Aparece | ≈2,2 s | La sombra de Lya corre por el suelo hasta él; Érebo surge del charco junto al enemigo («Ladrón de Corazones») | A ras de suelo, luego plano de los dos |
| 3 · Se acerca | ≈4,6 s | Érebo se desliza hasta el enemigo (flota si el núcleo está alto) | Por encima de su hombro, hacia el pecho |
| 4 · La mano | ≈5,6 s | Mete la mano abierta; la luz carmesí del corazón crece y se ve a través del cuerpo. Contacto a ≈6,7 s: onda en el pecho, pausa de impacto, el enemigo se arquea | Lateral, del lado de su mano |
| 5 · Extraer | ≈7,2 s | Agarra; el corazón espectral aparece en su mano, atado al pecho por un hilo de esencia; tira (la IK lleva la mano por un camino visible) y el hilo se rompe con plata (≈7,9 s) | Lateral |
| 6a · En la mano | ≈8,8 s | Se aparta, se vuelve hacia la cámara y muestra el corazón, que late dos veces; el enemigo se queda sin fuerzas | Frontal, mano y máscara |
| 6b · El orbe | ≈9,9 s | El corazón sube de su palma y se deshace en espiral (violeta, plata, negro) en el orbe, que queda flotando ante la máscara; destello | Se acerca al orbe |
| 6c · Ritual | ≈11,3 s | Corte al vídeo en el primer plano del orbe: la mano lo agarra, absorción, estallido y haz (12 s; o 5 s en «breve») | La del vídeo |
| 7 · Vuelta | ≈23,6 s | El vídeo acaba en su destello y el combate aparece debajo; `combate.gd` aplica el resultado una vez («¡Érebo le arranca el corazón!») | La del combate |

Total ≈23,6 s con `hibrida` y ≈16,6 s con `hibrida_breve` (la invocación de siempre dura ≈19,7 s con éxito). El ATB es
el de siempre en los dos casos.

### Fallo (invocación resistida)

Igual hasta el agarre. El tirón se para a medio camino: el corazón tiembla atado al pecho, se le escapa de los dedos y
vuelve dentro con una onda de plata; la mano se cierra sobre nada (humo), en un plano cercano de la mano vacía. Sin
orbe ni ritual: corte al plano general, Érebo se hunde y la sombra vuelve a Lya; el escenario se funde al combate
(«La mano de Érebo sale vacía», «Falla»). ≈11,7 s.

### Jefe (roba el 20 %)

El corazón se resiste igual, pero en el tirón se PARTE: el corazón vuelve al pecho y en la mano de Érebo queda un trozo
(algo menos de la mitad del corazón, abierto por el corte, más violeta y plateado). Ese trozo es el que se condensa en el orbe y sigue el ritual. Resultado: el de
hoy (`maxi(1, round(PV × 0,2))`, «Érebo le roba parte de su vida»).

### Saltar

Un toque o Esc/Intro en cualquier momento (como ya hacía la invocación): se cortan Érebo, el corazón y los efectos, el
escenario se funde en 0,7 s (o el vídeo sale por su camino) y el resultado se aplica una vez. La música vuelve a su
volumen exacto, el tiempo a 1, las ventanas 3D del combate a su modo y no queda ninguna capa.

## 3. Cómo se adapta a cada objetivo

- **Punto de contacto** (`_punto_contacto`), por orden: `corazon()` (Bramavidrio: «el corazón para Érebo», la garganta),
  `nucleo()` (Coloso), `punto("nucleo")` (Humbaba), el hueso del pecho (`gestos.idx["pecho"]`, humanoides: Grimfang,
  Gorthor, Custodio…; el de la invocación nueva, con la profundidad del torso), la constante `CENTRO` del modelo
  (Guardián 3D) o, si no hay nada, la mitad de su caja. Si el núcleo está hondo, la mano entra solo hasta poco antes,
  por el lado de Érebo.
- **Caja del modelo** (`_medir`): con los HUESOS en su pose de ahora (las mallas con piel dan la caja de reposo: la de
  Bramavidrio salía tumbada) más las mallas sin piel y los dibujos.
- **Érebo se coloca por la mano** (como la invocación nueva): escala 0,8-1,6 según la altura del contacto; si el
  contacto queda más alto de lo que alcanza, **flota** hasta él (Bramavidrio, a 2 m); si queda más bajo, asoma hundido
  en su charco (Slime, Zarzalín). La IK de alcance lleva la punta de la mano al contacto (error medido ≤ 5 cm).
- **Colosos**: en el escenario, el doble se limita a 3,4 m de alto (solo esa copia; misma forma). Los anchos se apartan
  para que quepan Érebo y la cámara.
- **Cámaras**: los planos se calculan con el alto del objetivo y la escala de Érebo; el plano lateral del tirón se pone
  del lado de la mano (medido en el momento); el de «en la mano» deja al enemigo detrás de Érebo.
- **Tamaño del corazón**: 0,085 × alto de Érebo × su escala (≈14 cm a escala 1); el trozo del jefe (algo menos de medio corazón), a la misma escala.

## 4. Qué reutiliza

- **Del vídeo**: el ritual entero desde el primer plano del orbe (P3-P6 de `EREBO_CINEMATICA_V12.md`): `videos/erebo_ritual.ogv`
  = completa 8,0-20,0 s (fotogramas 241-600) y `videos/erebo_ritual_breve.ogv` = abreviada 1,8-6,8 s (fotogramas 55-204),
  codificados con ffmpeg desde los PNG maestros (`D:\REBELUM_diagnostico\erebo_cine\final\`) y las mezclas de sonido
  (`...\sonido\erebo_cine_*.wav`, con 0,12 s de entrada suave), Theora 960×540 a 30 fps, 2 500 kbit/s, Vorbis 160 kbit/s
  (4,0 MB y 1,8 MB). Godot 4.7.2 los carga como `VideoStreamTheora` y los reproduce (prueba). Excluidos de las APK que no
  son de Auditoría por el filtro `videos/erebo_*` que ya había. Se reproducen con `invocacion_erebo_video.reproducir()`
  (con su recuperación si no abre o se para); el escenario 3D se quita debajo en cuanto el vídeo avanza (`al_arrancar`).
  Para el empalme, el orbe en tiempo real se tiñe del violeta del vídeo y queda flotando, como en el primer plano del vídeo.
- **De la invocación nueva** (`invocacion_erebo_nueva.gd`, la clase madre): colocación por la mano, IK de alcance, luces,
  gestos del enemigo, aplastar el orbe y la salida (ritual en tiempo real y fallo).
- **De `erebo_3d.gd`** (sin tocarlo): modelo, clips, surgir, deslizar, orbe, aura de la mano, charco, sonidos `erebo_*`.
- **De `combate.gd`**: el escenario del teatro (copiado, con el doble y Lya), `_tapar_combate`, `_destapar_combate`.

## 5. Azar independiente

- El dado se tira en `invocar()` ANTES de crear nada, con la expresión de la variante de vídeo.
- Los efectos nuevos (`vfx/erebo_extraccion.gd`) usan un `RandomNumberGenerator` propio con semilla fija y **no usan
  CPUParticles3D** (en 4.7 gastan el generador global aunque lleven semilla): las motas son un MultiMesh movido por
  script. Érebo (`erebo_3d.gd`) sí tiene partículas propias; para eso está el aislamiento del coordinador en
  `_invocar_sobre` (`azar_tras_invocar`, 38baaad).
- **Medido**: la tirada `randi()` siguiente a la invocación es la misma apagada (teatro), encendida y apagada otra vez
  (ver §6).

## 6. Pruebas y resultados

Con el ejecutor (`ejecutar_pruebas.ps1 -Solo ...`, datos aislados, `--fixed-fps 30`, sin ventana). Tiempos de JUEGO.

**`prueba_erebo_hibrida` (erebo=exito): SUPERADA, `FALLOS: 0`.** Casos y lo que comprueba en cada uno:

| Caso | Modo | Dura | Comprobado |
|---|---|---|---|
| Selector | — | — | «hibrida» enciende la híbrida y deja el vídeo en «no»; «abreviada» al revés; «no» las dos; los dos `.ogv` del ritual son `VideoStreamTheora` |
| Apagada (teatro de siempre) | no | 3,5 s (saltado a los 30 fotogramas) | sale el teatro de siempre, nada de la híbrida |
| Grimfang, humanoide 3D | hibrida | 25,7 s | fases en orden; punta de la mano a 0,05 m del contacto; corazón en la mano (0,00 m, visible); orbe; vídeo; resultado UNA vez (muerte), «arranca el corazón» una vez |
| Slime, pequeño 2D | breve | 18,7 s | ídem (Érebo ×0,8, hundido en su charco) |
| Zarzalín, sin pecho humano | breve | 18,7 s | ídem (contacto en el pecho del jabalí, a 0,5 m) |
| Bramavidrio, grande con núcleo | breve | 18,7 s | ídem (núcleo en la garganta a 2,07 m; Érebo ×1,6 flotando; doble a 3,4 m) |
| JEFE Guardián de piedra (2D) | hibrida | 26,1 s | trozo en la mano; −20 % exacto (36 de 180), sin morir, «roba parte de su vida» una vez; enemigo de verdad intacto |
| JEFE Gorthor (3D) | breve | 19,1 s | ídem (−92 de 460); su nodo 3D, mallas y materiales iguales antes y después |
| Saltar en la señal / acercamiento / extracción / ritual (vídeo) | breve/completa | vuelve en < 3 s | se salta en ESA fase; resultado una vez; sin restos |
| Todo en tiempo real | hibrida_3d | 15,4 s | ritual en tiempo real, sin vídeo; resultado una vez |
| Ritual que no arranca (VideoStream sin reproductor y Theora sin archivo, sustituidos en la caché) | breve | 18,9 s | ritual en tiempo real; resultado una vez; sin restos |

En todos: el estado sigue en «accion» toda la híbrida; la música se aparta y vuelve EXACTA; ATB de Kael igual al de la
invocación de siempre con ese resultado (±0,6, como la prueba del vídeo); `c12_accion` a 0; sin capas
(`EreboHibrida*`, `EreboCinematica`); tiempo a 1; `inv_erebo` nulo; luchadores visibles; ventanas 3D del combate en su
modo. **Azar**: `AZAR randi() tras la invocación: apagada 518376512 · híbrida 518376512 · apagada (control) 518376512`.

**`prueba_erebo_hibrida_fallo` (erebo=fallo): SUPERADA, `FALLOS: 0`.** Apagada con fallo (teatro); Grimfang y Zarzalín
resistidas (12,0 s: el corazón se escapa, sin orbe ni vídeo, PV sin cambios, «sale vacía» una vez, enemigo de verdad
intacto); jefe con el fallo forzado (siempre 20 %, con trozo y ritual); resistida saltada en la extracción.

**Regresión**: `prueba_erebo_video`, `prueba_erebo_video_fallo`, `prueba_erebo_saltar`, `prueba_erebo_nueva` y
`prueba_combate_huella` SUPERADAS con la híbrida apagada. `prueba_banco_pruebas` pedía 6 selectores: ahora 7 (el nuevo);
con eso, `prueba_banco_pruebas` y `prueba_banco_pruebas_3d` SUPERADAS.

Pasada final con el código entregado: `D:\REBELUM_diagnostico\pruebas\2026-11-15_122027\` (las dos híbridas, el vídeo,
saltar y los dos bancos: 6 SUPERADAS, 0 FALLIDAS; mismas cifras que la tabla, la resistida 12,0 s). Regresión anterior
(huella del combate y la invocación nueva): `...\2026-11-15_120454\`.

## 7. Grabaciones y capturas

**Grabaciones con sonido** dentro de un combate de verdad (Kael, Lya y Garon; Movie Maker de Godot a 30 fps, 1280×720,
convertidas con ffmpeg a MP4 H.264 + AAC), desde el menú de Lya con la Armonía llena hasta 4 s después de recuperar el
control (`pruebas/grabar_erebo_hibrida.gd`), en `D:\REBELUM_diagnostico\erebo_hibrida\videos\`:

| Archivo | Caso | Resultado |
|---|---|---|
| `REBELUM_Erebo_hibrida_exito_Grimfang.mp4` | éxito, humanoide, ritual completo | PV 110 → 0 |
| `REBELUM_Erebo_hibrida_exito_Bramavidrio_grande.mp4` | éxito, coloso sin pecho (núcleo en la garganta), Érebo flota | PV 1150 → 0 |
| `REBELUM_Erebo_hibrida_jefe_Gorthor.mp4` | JEFE: arranca un trozo, ritual | PV 460 → 368 (20 %) |
| `REBELUM_Erebo_hibrida_resistida_Grimfang.mp4` | resistida: el corazón se escapa, sin orbe | PV 110 → 110, «Falla» |
| `REBELUM_Erebo_hibrida_saltada_en_la_extraccion.mp4` | Esc a mitad de la extracción | PV 110 → 0, una vez |
| `REBELUM_Erebo_hibrida_exito_Zarzalin_breve.mp4` | éxito, criatura pequeña sin pecho humano, ritual breve | PV 80 → 0 |

**Capturas** de los momentos clave (`pruebas/fotos_erebo_hibrida.gd`, con ventana: antes, señalado, el objetivo, Érebo
surge, acercamiento, mano en el pecho, corazón saliendo, corazón fuera / se escapa / trozo, en la mano, orbe, ritual,
vuelta y control) para Grimfang (9), Slime (7), Zarzalín (10), Bramavidrio (13), Gorthor (5, jefe) y el Guardián de
piedra (18, jefe), y las resistidas de Grimfang y Zarzalín: `D:\REBELUM_diagnostico\erebo_hibrida\capturas\`
(`g<grupo>_<modelo>_<exito|fallo>_<nn>_<momento>.png`). Los borradores de ajuste están en `...\borrador1..5\`.

## 8. Pendiente, provisional y Redmi

- **Nada está aprobado.** Falta la revisión del usuario (aspecto, ritmo, duración y sonido).
- **Duración**: con el ritual completo dura ≈24 s (≈11,5 s en tiempo real + 12 s de vídeo), más que la de siempre
  (≈19,7 s); con «Híbrida breve», ≈16,5 s. El ATB es el mismo en todos los casos. Si se queda, decidir cuál es la
  predeterminada (desde el 15/11 tarde Ajustes y el banco ofrecen las dos; «3D» solo por argumento).
- **Sonido de la parte en tiempo real**: son los `sonidos/erebo_*.wav` de la invocación de siempre (susurros, sombra,
  pulso, extracción, tensión). El corazón no tiene sonido propio (latido) todavía; lo diseñaría el especialista de sonido.
- **El empalme con el vídeo** es un corte (destello violeta, 0,25 s de negro del reproductor y el primer plano del orbe).
  Sin fundido cruzado: `reproducir()` funde a negro antes de empezar.
- **Gorthor** sale sin su tinte rojo en el escenario (el doble de `_doble_3d` no lleva el `tinte` del sprite del
  combate): es lo mismo que en la invocación de siempre.
- **Enemigos 2D** (Slime, Guardián de piedra): su doble es su dibujo de pie, que mira siempre a la cámara; la mano entra
  en el dibujo. Es el mismo doble que usa la invocación de siempre.
- **Colosos** a 3,4 m en el escenario (solo la copia). Humbaba y el Coloso de la Falla no se han probado (Humbaba está
  apagado; el Coloso usa su respaldo 2D).
- **Redmi (pendiente, no medido)**: el escenario 3D es el del teatro de siempre (mismo coste medido el 14/11), más el
  corazón (2 mallas pequeñas aditivas, ≤ 72 motas en un MultiMesh y un brillo); el vídeo del ritual es Theora 960×540 a
  2,5 Mbit/s, como la cinemática (decodificación en el UMS9230E sin medir: el paso 12 de `EREBO_CINEMATICA_V12.md`).
  Hay que medir fotogramas en la parte en tiempo real, el salto al vídeo (carga del .ogv) y la memoria.
- **Relevo**: para integrar, el coordinador puede añadir «hibrida» a `MODOS` de `invocacion_erebo_video.gd` si prefiere
  que el vídeo conozca el valor (hoy no hace falta: lo trata como «no»).

## 9. 15/11 (tarde): cabeza firme, «Híbrida abreviada», cobertura y sonido

**Encargo** (usuario, tras probarla en el Redmi contra un Slime): conservar el diseño (objetivo visible → acercamiento
→ mano en el cuerpo → extracción del corazón → ritual del orbe → vuelta), mantener la completa (≈24 s) y ofrecer la
abreviada, sin sustituir la invocación de siempre ni encender nada por defecto. Y: «Érebo mueve la cabeza de forma
rara… la cabeza tiene que estar de una forma imponente y segura de lo que hace».

### 9.1 Qué era lo de la cabeza y cómo se arregló

Revisado fotograma a fotograma en las grabaciones del 15/11 (`videos\`), las capturas y la cinemática original:

- **En tiempo real** (acercamiento, mano, «en la mano»): Érebo usa el clip de reposo de Mixamo «Thriller Idle»
  (`erebo_idle.fbx`), un reposo de ZOMBI: la cabeza se mece y cae a los lados. Encima, el clip de agarrar («Picking Up
  Object») baja la cabeza a mirar el suelo. Medido en el Érebo de la híbrida desde el contacto: la cara **ladeada 19,9°**
  al enseñar el corazón y giros de la cabeza de hasta **≈494 °/s** (tirones).
- **En el vídeo** (la cinemática del 14/11, que también usa ese reposo desde los 8,0 s), además de ese balanceo:
  - 6,8-9,85 s (completa) / 0,8-2,6 s (abreviada): la cabeza se **ladea 9°** «con curiosidad» al descubrir el orbe;
  - 12,5 y 13,8 s: en las sacudidas, el **cuello da un tirón** (-7°);
  - 15,4-17,0 s (completa) / 4,2-5,15 s (abreviada): al comprimir, **agacha la cabeza 12°** sobre el puño (en 16,4-17,0 s
    la capucha tapa la máscara: se ve encogido, no imponente);
  - 16,4-17,0 s: un temblor de 0,4° a 61 rad/s en la quietud.

**Arreglo en tiempo real** (`vfx/erebo_cabeza_firme.gd`, nuevo; `erebo_3d.gd` NO se toca): un `SkeletonModifier3D`
propio que la híbrida añade solo a SU Érebo, después de los gestos (`gestos_3d.gd`) y de la IK de los brazos. Con su
«peso» (0 → 1 al empezar el acercamiento) deja el cuello en su pose de descanso respecto al pecho (erguido) y la cabeza
NIVELADA (su eje arriba con el del personaje, aunque el pecho se ladee con el clip), con la barbilla 7° alta, mirando al
pecho del enemigo, luego al corazón (o al trozo), al orbe y, en la resistida, a la mano vacía; giro máximo 45°, ±25°
arriba/abajo, suavizado y con velocidad limitada (140 °/s). Medido desde el contacto, en todos los casos de la prueba:
**ladeo 0,00° (máx. 0,00°) y giro máx. 31 °/s** (resistida: 53 °/s). Con `erebo_cabeza=original` se ve como antes (solo
para comparar). Además, el plano «en la mano» entra por corte (el viaje de la cámara cruzaba la capucha).

**Arreglo del vídeo**: los vídeos originales (`videos/erebo_invocacion_*.ogv`) NO se tocan. El script de la
cinemática tiene una opción nueva `cabeza=firme` (`animaciones/erebo/fuentes/cinematica_erebo.py`; por defecto hace lo
mismo que el 14/11): cuello y cabeza erguidos sobre el reposo de zombi (entran en 0,4 s antes del primer plano de la
máscara), sin el ladeo «curioso» (al agarrar el orbe solo baja la barbilla 8°, sin ladear), comprime con el PECHO y la
cabeza alta, la espalda se arquea en las sacudidas (a la mitad) sin tirón de cuello, y sin el temblor. Se volvieron a
renderizar con Blender 5.2.3 (EEVEE, 20 muestras, 1280×720) los fotogramas desde 6,4 s (completa, 408) y desde 0,4 s
(abreviada, 192); los anteriores son idénticos y se reutilizan. ≈1,4 s por fotograma (9,7 y 4,7 min).
- Los tramos del ritual de la híbrida (`videos/erebo_ritual.ogv` y `erebo_ritual_breve.ogv`, que son nuestros) se
  sacaron otra vez de esos renders: **la híbrida ya lleva la cabeza firme también en el vídeo**.
- Para la invocación cinematográfica de siempre, hay CANDIDATOS listos (mismo formato que los originales) para que el
  coordinador los ponga si el usuario lo aprueba: `D:\REBELUM_diagnostico\erebo_hibrida\cabeza\candidatos_ogv\`
  (`erebo_invocacion_completa.ogv`, 6,5 MB; `erebo_invocacion_abreviada.ogv`, 2,3 MB). Fotogramas en
  `...\cabeza\completa_entera\` y `...\abreviada_entera\`.

### 9.2 «Híbrida abreviada»

Valor `hibrida_breve`, ahora elegible en Ajustes (segunda línea: «Híbrida» e «Híbrida abreviada») y en el banco
(«Híbrida abreviada» en lugar de «Híbrida 3D», que sigue por argumento). Reutiliza TODA la parte en tiempo real (la
misma extracción: señal, acercamiento, mano, corazón, orbe) y cambia solo el tramo del ritual (5 s en vez de 12 s).
Duraciones en tiempo de juego: completa ≈25,7 s y abreviada ≈18,7 s (éxito); resistida ≈12 s en las dos. Mismas reglas,
mismo dado, mismo ATB (`ATB_TEATRO`) y resultado una vez.

### 9.3 Cobertura (pruebas sin ventana, resultados literales)

Pasada final con el código entregado: `D:\REBELUM_diagnostico\pruebas\2026-11-15_150229\`. **8 SUPERADAS**:
`prueba_erebo_hibrida`, `prueba_erebo_hibrida_fallo`, `prueba_erebo_video`, `prueba_erebo_video_fallo`,
`prueba_erebo_saltar`, `prueba_erebo_nueva` (las invocaciones de siempre, intactas), `prueba_banco_pruebas` y
`prueba_banco_pruebas_3d`. **1 FALLIDA que no es de esta rama**: `prueba_combate_huella`, «E8_gorthor: distinta de la
referencia» (Lya empieza con 116/116 PV y la referencia dice 115/116). Falla IGUAL con los archivos de la base
`1239e78` (comprobado volviendo a ellos: `...\2026-11-15_150650\`); la referencia está desfasada respecto a la
integración. Lo tiene que mirar el coordinador.

`prueba_erebo_hibrida` (erebo=exito), `FALLOS: 0`. Duraciones en tiempo de juego:

| Caso | Dura |
|---|---|
| apagada (teatro de siempre), y otra vez de control | 3,5 s (saltado a los 30 fotogramas) |
| Grimfang, completa · Zarzalín (sin pecho humano), completa · Bramavidrio (grande, núcleo), completa | 25,7 s |
| Grimfang, abreviada · Slime (pequeño 2D), abreviada · Bramavidrio, abreviada | 18,7 s |
| JEFE Guardián de piedra (2D), completa / JEFE Gorthor (3D), abreviada | 26,1 s / 19,1 s |
| Saltar en la señal (completa y abreviada) | 1,0 s |
| Saltar en el acercamiento (abreviada) / en la extracción (las dos) | 5,6 s / 8,0 s |
| Saltar al ENTRAR en el vídeo (las dos, a 0,05 s de que avance) | 11,8 s |
| Saltar en el DESTELLO FINAL del vídeo (completa / abreviada) | 25,7 s / 18,7 s |
| Saltar a mitad del ritual (completa) | 15,8 s |
| Todo en tiempo real (`hibrida_3d`) | 15,4 s |
| Ritual que no se puede cargar (VideoStream sin reproductor / Theora sin archivo) → ritual en tiempo real | 18,9 s |

En cada caso comprueba: fases en orden (o, al saltar, que se saltó en ESA fase y vuelve en < 3 s); la punta de la mano
en el contacto; el corazón (o el trozo) en la mano; orbe solo con éxito; vídeo del ritual; estado «accion» todo el
rato; resultado UNA vez (muerte, −20 % exacto del jefe o nada) y el texto de siempre una vez; música apartada y devuelta
exacta; ATB igual al de la invocación de siempre (±0,6); sin capas; tiempo a 1; luchadores visibles; ventanas 3D del
combate en su modo; la **cámara del combate** (`escena.position/scale`) igual; los **controles**: cuando el combate
sigue, el menú vuelve y responde a una orden (Defender); el enemigo de verdad intacto (jefes y resistidas); y la
**cabeza**: `CABEZA ladeo 0.00° (máx. 0.00° desde el contacto) · giro máx. 31 °/s` en todos los éxitos y jefes.
**Azar**: `AZAR randi() tras la invocación: apagada 518376512 · híbrida completa 518376512 · híbrida abreviada
518376512 · apagada (control) 518376512`.

`prueba_erebo_hibrida_fallo` (erebo=fallo), `FALLOS: 0`: apagada con fallo (3,5 s); resistidas de Grimfang (completa y
abreviada) y Zarzalín (abreviada), 12,0 s, sin orbe ni vídeo, PV intactos, «sale vacía» una vez, `CABEZA ladeo -0.00°
(máx. 0.00°) · giro máx. 53 °/s`; jefes con el fallo forzado (Guardián completa 26,1 s y Gorthor abreviada 19,1 s: siempre
el 20 %); resistida saltada en la extracción (las dos, 8,0 s).

### 9.4 Sonido (grabaciones del Movie Maker, que llevan el audio del juego)

Medido con `pruebas/herramientas/analizar_sonido_erebo.py` (ffmpeg `volumedetect` por tramos y, para la sincronía,
los destellos de la imagen —subida de brillo medio > 25 en un fotograma— frente al golpe de sonido más cercano, en
ventanas de 10 ms). Informes en `D:\REBELUM_diagnostico\erebo_hibrida\videos_15_11b\registros\*_sonido.txt`.

| Grabación | Antes de invocar | Tiempo real | Ritual (vídeo) | Al volver |
|---|---|---|---|---|
| Completa, Grimfang | media −19,8 / pico −6,2 dB | −18,4 / −1,0 | −16,7 / −1,2 | −23,0 / −6,0 |
| Abreviada, Grimfang | −19,8 / −6,2 | −18,4 / −1,0 | −16,8 / −1,7 | −22,8 / −5,7 |
| Completa, Bramavidrio | −18,8 / −5,8 | −18,4 / −1,1 | −16,7 / −0,9 | −19,1 / −3,9 |
| Jefe Gorthor, completa | −19,8 / −6,2 | −18,0 / −1,0 | −16,7 / −0,8 | −19,5 / −6,7 |
| Resistida, Grimfang | −19,8 / −6,2 | −18,3 / −1,0 (toda) | — | −19,8 / −6,3 |
| Saltada en la extracción | −19,8 / −6,2 | −19,8 / −1,0 (toda) | — | −23,0 / −4,9 |

- **Sin saturar**: ningún pico pasa de −0,8 dBFS. El ritual queda ≈1,5 dB por encima de la parte en tiempo real (la
  mezcla del vídeo, −16 LUFS). «Al volver» baja en los éxitos porque el enemigo muere y cambia la música del combate.
- **Música**: el bus «Musica» baja a −18 dB durante toda la híbrida y vuelve EXACTO a 0,00 dB al terminar y al saltar
  (registro de cada grabación: `GRAB vuelta … música 0.00 dB (la más baja durante: -18.00 dB)`; y la prueba lo
  comprueba en cada caso con `is_equal_approx`).
- **Sincronía**: la primera medida encontró dos destellos SIN golpe (el corazón que sale, +450 ms hasta el siguiente
  sonido, y el destello antes del vídeo, +490 ms). Arreglado (fractura y resonancia en ese fotograma; también al partir
  el trozo y al escaparse el corazón). Ahora: corazón que sale **+30 ms**, destello antes del vídeo **+20 ms**, estallido
  del ritual completo **0 ms** (−3 ms con el jefe). Quedan, del vídeo original: el destello final llega 0,3-0,4 s después
  de la ráfaga (así se montó: el golpe en el enemigo lo pone el combate) y en el ritual abreviado el estallido suena
  +183 ms tras su destello. En el jefe, el golpe más fuerte cerca del trozo cae a +350 ms (el pulso de «en la mano»; el
  del trozo es más suave).
- **Pendiente**: la salida AUDIBLE en el teléfono (altavoz del Redmi, volumen, que se oiga y que no se corte al pasar
  al vídeo). Las grabaciones de pantalla del Redmi no llevan audio: hay que escucharlo en el teléfono.


### 9.5 Vídeos y capturas (15/11 tarde)

En `D:\REBELUM_diagnostico\erebo_hibrida\videos_15_11b\` (Movie Maker → MP4 H.264 + AAC, combate de verdad con Kael,
Lya y Garon, desde el menú de Lya hasta 4 s después de volver):

| Archivo | Caso | Resultado |
|---|---|---|
| `REBELUM_Erebo_hibrida_completa_Grimfang.mp4` | completa, enemigo normal | PV 110 → 0 |
| `REBELUM_Erebo_hibrida_abreviada_Grimfang.mp4` | abreviada, el mismo | PV 110 → 0 |
| `REBELUM_Erebo_hibrida_completa_Bramavidrio_grande_sin_pecho.mp4` | grande, núcleo en la garganta | PV 1150 → 0 |
| `REBELUM_Erebo_hibrida_jefe_Gorthor_completa.mp4` | JEFE: el trozo, 20 % | PV 460 → 368 |
| `REBELUM_Erebo_hibrida_resistida_Grimfang_completa.mp4` | resistida: el corazón se escapa | PV 110 → 110 |
| `REBELUM_Erebo_hibrida_saltada_en_la_extraccion_completa.mp4` | Esc a mitad de la extracción | PV 110 → 0, una vez |
| `REBELUM_Erebo_hibrida_cabeza_antes_izquierda_despues_derecha.mp4` | cabeza en TIEMPO REAL: antes / después | — |
| `REBELUM_Erebo_cinematica_cabeza_antes_izquierda_despues_derecha.mp4` | cabeza en la CINEMÁTICA (20 s): antes / después | — |
| `REBELUM_Erebo_cinematica_completa_cabeza_firme.mp4` / `..._abreviada_...` | la cinemática nueva, con su sonido | — |
| `REBELUM_Erebo_hibrida_cabeza_ANTES_abreviada_Grimfang.mp4` | la misma abreviada sin la cabeza firme (referencia) | — |

Registros y análisis de sonido de cada grabación en `...\videos_15_11b\registros\`. Capturas de la cabeza en tiempo
real (cada 0,4 s, del acercamiento al orbe): `D:\REBELUM_diagnostico\erebo_hibrida\cabeza\tiempo_real_antes\` y
`...\tiempo_real_despues\`; de la cinemática, `...\cabeza\firme\` (7,4 / 12,6 / 16,7 s).

### 9.6 Pendiente

- **Nada está aprobado**: falta que el usuario vea los vídeos nuevos (la cabeza, la abreviada y el sonido).
- **Redmi**: medir y escuchar con la APK nueva: la abreviada y la completa, una resistida, un jefe y saltar (en la
  extracción, al entrar en el vídeo y en el destello final); el coste de la cabeza firme es mínimo (un modificador con
  dos huesos), pero no está medido en el teléfono. La salida AUDIBLE (altavoz) sigue sin comprobar.
- **La invocación cinematográfica de siempre** sigue con los vídeos del 14/11: los candidatos con la cabeza firme están
  listos (9.1) para cambiarlos si el usuario lo aprueba.
- `prueba_combate_huella`: referencia desfasada en la integración (E8), ajena a esta rama.
