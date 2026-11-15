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

- **Ajustes → «Érebo: invocación cinematográfica» → «Híbrida»** (solo APK de Auditoría o editor). Es un valor más del
  selector del vídeo (la misma clave `[calidad_pruebas] erebo_cine` de `user://ajustes.cfg`); con él, el vídeo queda
  apagado (`invocacion_erebo_video.gd` no conoce ese valor y devuelve «no»). Elegir «No», «Abreviada»… lo devuelve
  todo a como estaba.
- **Banco de pruebas → «Érebo: invocación»**: «De siempre», «Vídeo» (abreviada), «Híbrida» y «Híbrida 3D».
- **Valores** (`invocacion_erebo_hibrida.gd`, `MODOS`):
  - `hibrida`: ritual con el tramo de la versión COMPLETA del vídeo (12 s);
  - `hibrida_breve`: ritual con el tramo de la ABREVIADA (5 s);
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
resistidas (11,7 s: el corazón se escapa, sin orbe ni vídeo, PV sin cambios, «sale vacía» una vez, enemigo de verdad
intacto); jefe con el fallo forzado (siempre 20 %, con trozo y ritual); resistida saltada en la extracción.

**Regresión**: `prueba_erebo_video`, `prueba_erebo_video_fallo`, `prueba_erebo_saltar`, `prueba_erebo_nueva` y
`prueba_combate_huella` SUPERADAS con la híbrida apagada. `prueba_banco_pruebas` pedía 6 selectores: ahora 7 (el nuevo).

Pasadas: `D:\REBELUM_diagnostico\pruebas\2026-11-15_120303\` (las dos híbridas) y `...\2026-11-15_120454\` (regresión).

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
  predeterminada (Ajustes solo ofrece hoy «Híbrida» = completa; «breve» y «3D» están en el banco y por argumento).
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
