# Invocación cinematográfica de Érebo (V12, desde el 14/11/2026)

**Estado:** en producción. Es una pieza experimental. **No sustituye** a la invocación actual, que sigue siendo la
predeterminada y recuperable.

**Encargo:** «Segunda producción cinematográfica: invocación de Érebo» (usuario, 14/11). Debe tener la misma calidad que
la introducción cinematográfica. **Esa introducción todavía no existe en el repositorio**, así que este documento fija
también la dirección artística común que la introducción deberá seguir (§1).

## 0. Reglas que no se tocan

- **La invocación de siempre queda intacta** (`invocacion_erebo.gd` / `invocacion_erebo_nueva.gd` / `_teatro_erebo`). El
  vídeo es una opción de Auditoría APAGADA por defecto.
- **Las mismas reglas de juego:** coste (Armonía llena), quién invoca (solo Lya), dado de muerte o daño y daño a jefes
  (`INVOCACION`). El daño se aplica **una sola vez**, por `combate.gd`, al terminar o saltar el vídeo.
- **El mismo ATB que la invocación de siempre.** Con el teatro, el ATB corre mientras dura (14-20 s según el
  resultado; el del enemigo llega a 100) y no se abre ningún turno porque el combate está en `estado = "accion"`. El
  vídeo, dure lo que dure, da **exactamente** ese mismo tiempo de ATB. Es la regla que ya usan las animaciones v12
  (`pausa_atb`, activa por defecto): el ATB corre hasta el menor de esos tiempos y se para; al acabar, se abona de
  golpe lo que falte según el resultado (`combate.gd` `_avanzar_atb`). Tiempos medidos con
  `pruebas/medir_erebo_teatro.gd`, que están en `invocacion_erebo_video.gd` (`ATB_TEATRO`):

  | Invocación de siempre | Éxito | Fallo |
  |---|---|---|
  | Teatro original | 19,69 s | 14,35 s |
  | «Ladrón de Corazones» | 15,11 s | 12,45 s |

  Si se desactiva `pausa_atb`, el ATB corre libre durante el vídeo, como en las demás acciones.
- **Sin cambios en el guardado.** La opción vive en `user://ajustes.cfg` `[calidad_pruebas]`, como las demás de Auditoría.
- **Sin revelar el acto III** (biblia v3, ver la memoria de dirección): el orbe **no** contiene siluetas, hilos de
  recuerdos ni corazones, y la gema del pecho de Érebo **no** late con el orbe. El orbe es energía prohibida, sin más.
- **El diseño de Érebo es el aprobado:** el mismo modelo `erebo_*.fbx` (*chibi*, encapuchado, máscara blanca sonriente,
  gema carmesí, armadura ciruela con ribetes dorados y capa carmesí desgarrada). La expresividad sale de la cabeza, la
  silueta, la luz sobre la máscara y las manos. **No se redibuja la máscara.**

## 1. Dirección artística común (cinemáticas de REBELUM)

| Aspecto | Regla |
|---|---|
| Paleta | Negro azulado de fondo (no negro puro: `#07050c`). Violeta del orbe `#8a3cff` → magenta `#ff2a6d` (el carmesí de Érebo). Plata fría `#cfd6ff` para chispas y cristal. Oro tenue solo en los ribetes |
| Luz | Una fuente motivada (el orbe) más un contraluz frío. Sin relleno plano: las sombras se dejan caer. La máscara se ilumina **desde abajo** con la luz del orbe |
| Lente | 35-50 mm en planos medios y 85-100 mm en detalle. Profundidad de campo real. Movimientos lentos con aceleración y frenada suaves; nada de cámara fija «de prueba» |
| Ritmo | Silencio y oscuridad antes del golpe. Cada clímax va precedido de una pausa (casi inmóvil, sonido abajo) |
| Partículas | Siempre con dirección e intención (atraídas, en espiral, detenidas, expulsadas). Ningún «confeti» decorativo |
| Legibilidad | Formato 16:9. Lo importante en el tercio central, porque la pantalla del Redmi es 20:9 y el juego la recorta con bandas |
| Montaje | Cortes con motivo (en el gesto, en el destello). Fundidos solo para entrar y salir |
| Sonido | Identidad propia, sin música comercial. Graves profundos más un motivo de tres notas (ver §5) |

## 2. Storyboard: versión completa (≈20 s, 30 fps)

| Plano | Tiempo | Imagen | Cámara | Sonido |
|---|---|---|---|---|
| **P1 · El orbe prohibido** | 0,0-3,8 | Negro. Un latido. La luz violeta revela un orbe suspendido sobre un suelo de obsidiana mojada. Motas de luz derivan hacia él. Se encienden una a una las runas de un anillo que orbita. El orbe vibra | Travelling lento hacia el orbe (85 mm), de 3,2 m a 1,6 m | Latidos a 0,3 / 1,4 / 2,4 / 3,1 / 3,6 s (cada vez más rápidos). Zumbido que crece desde 0,6. Campanillas de runa desde 2,0. Temblor desde 3,0 |
| **P2 · El despertar** | 3,8-8,0 | La oscuridad detrás del orbe se mueve (humo que gira). Primero las **manos**: salen de la sombra y se abren (3,8-5,4). Después el **cuerpo** se incorpora desde la capucha encogida (clip «salir», 5,4-6,8). Al final la cámara sube hasta la **máscara**, iluminada desde abajo por el orbe (6,8-8,0) | 3,8 detalle de las manos (100 mm); 5,4 plano medio bajo (35 mm), contrapicado; 6,8 grúa hasta la máscara (60 mm) | Ráfaga grave al moverse la sombra; tela y crujidos de las garras; rumor grave; un destello metálico en la máscara a 7,4 con el acorde del motivo |
| **P3 · La mano y el orbe** | 8,0-11,6 | La mano derecha se tiende hacia el orbe con los dedos abiertos (8,0-9,2). Se cierran **de uno en uno**, del meñique al índice y el pulgar al final, sin atravesarlo (9,2-9,85). **Agarre a 9,85:** la luz cambia de violeta a magenta, las partículas se detienen 0,25 s, el orbe se agrieta con luz, las runas se encienden de golpe y la energía sube por la mano y el brazo como venas (10,1-11,6) | Detalle de la mano, 100 mm, con foco sobre los dedos y el orbe. Ligero desplazamiento lateral. Al agarrar, empujón de cámara de 2 cm | Tensión creciente. **Golpe grave con crujido de cristal a 9,85.** Silencio hasta 10,1. Chisporroteo de grietas. Siseo eléctrico subiendo |
| **P4 · Absorción** | 11,6-15,4 | La luz exterior del orbe se apaga mientras su energía fluye a la mano en remolinos negros, violetas y plateados. Las sombras se extienden por el suelo como raíces. Érebo **reacciona**: se encorva a 12,5 y a 13,8, la capa se abre, la cabeza sube. A 15,0 el orbe queda muerto (cristal oscuro) | Órbita de 25° alrededor de Érebo (50 mm) que muestra la magnitud | Vórtice de viento al revés, subgrave de las sombras y dos sacudidas (12,5 y 13,8). Fin del zumbido a 15,0 |
| **P5 · Clímax** | 15,4-19,0 | Érebo **comprime** la energía: cierra el puño y lo lleva al pecho (15,4-16,4). Todo queda casi inmóvil (16,4-17,0). **Libera** a 17,0: adelanta la palma, estalla la energía oscura, salen ondas, fragmentos cristalinos y partículas que cruzan el encuadre | 15,4 primer plano de máscara y puño (60 mm) con un ligero acercamiento; 17,0 corte a plano general (28 mm), con la onda hacia cámara y una vibración breve y legible | Gruñido de presión que sube; a 16,4 el sonido cae casi a nada (un único latido a 16,7); **estallido a 17,0** (golpe, cristal, onda); cola de restos |
| **P6 · Regreso al combate** | 19,0-20,0 | La descarga, un haz violeta y negro, sale hacia el enemigo (hacia cámara). Destello blanco violáceo a 19,7. El vídeo termina en ese destello y Godot abre el combate desde él | Plano frontal; el haz llena el cuadro | Ráfaga que se aleja. El golpe en el enemigo lo pone el combate (su sonido de impacto, como siempre) |

## 3. Storyboard: versión abreviada (≈6,8 s)

Mismo escenario, mismos recursos y mismas cámaras, con otros tiempos.

| Plano | Tiempo | Imagen |
|---|---|---|
| P1′ | 0,0-0,8 | El orbe se enciende con su anillo de runas (detalle) |
| P2′ | 0,8-1,8 | Érebo ya incorporado; la cámara sube a la máscara iluminada |
| P3′ | 1,8-3,0 | La mano se cierra sobre el orbe. **Agarre a 2,6**, con el congelado de 0,15 s, las grietas y las runas |
| P4′ | 3,0-4,2 | Absorción rápida en remolino. Una sacudida del cuerpo |
| P5′ | 4,2-6,3 | Comprime (4,2-4,9), pausa (4,9-5,15), **libera a 5,15**, onda y fragmentos |
| P6′ | 6,3-6,8 | Haz y destello final |

## 4. Guion técnico

- **Herramienta:** Blender 5.2.3 por script (`aethelgard/animaciones/erebo/fuentes/cinematica_erebo.py`, con su
  `.gdignore`). Construye la escena entera desde los archivos del juego. Es reproducible y no hay archivos .blend a mano.
- **Render:** EEVEE (el único motor de esta instalación), con niebla volumétrica, profundidad de campo y *bloom* en el
  compositor. 1280×720 maestro en PNG, por planos.
- **Érebo:** `erebo_idle.fbx` (malla y esqueleto de Mixamo con 4 falanges por dedo) más estos clips:
  - «salir» para incorporarse;
  - «coger» para la apertura y el cierre de los dedos;
  - «conjuro» para el empuje final.
  Encima va una capa de animación propia: IK del brazo al orbe, cierre de los dedos de uno en uno, columna, cabeza y
  sacudidas.
- **Contacto sin atravesar:** el cierre de cada dedo se detiene cuando su malla toca la esfera del orbe más 3 mm. Se
  calcula por geometría en el script, no a ojo, y el script imprime la holgura mínima de cada dedo.
- **Efectos:**
  - partículas propias deterministas (las mueve el script en cada fotograma): atracción, congelado, espiral y estallido;
  - grietas del orbe por sombreador (Voronoi con umbral animado);
  - venas de energía por la malla del brazo (atributo de distancia a la mano más ruido);
  - sombras por el suelo (máscara de ruido que crece);
  - runas (anillo de glifos emisivos);
  - ondas (anillos) y fragmentos de cristal.
- **Vídeo para Godot:** Ogg Theora con audio Vorbis (`.ogv`), el formato que Godot 4 reproduce sin complementos
  (`VideoStreamTheora`). Se comprueba en Godot 4.7.2 antes de darlo por bueno. Para Android: 960×540 a 30 fps, con un
  tamaño objetivo menor de 10 MB la completa y de 4 MB la abreviada (se ajustará tras medir en el Redmi).
- **Montaje y sonido:** las mezclas se hacen con Python (identidad sonora más efectos de la biblioteca, con licencia
  comprobada) y se unen al vídeo en el editor de vídeo de Blender, que exporta el `.ogv`.

## 5. Identidad sonora de Érebo

- **Motivo:** tres notas descendentes con un semitono final (re - la♭ - sol), en registro grave, sobre un bordón. Se
  sintetiza: es original y no lleva música ajena.
- **Capas:**
  - latido grave (corazón y tambor muy filtrado);
  - zumbido del orbe (síntesis);
  - susurros o coro difuso (de la biblioteca, con licencia comprobada);
  - cristal y estallidos (de la biblioteca).
- **Mezcla:** −1 dBFS de pico y −16 LUFS aproximados, en estéreo a 44,1 kHz.

## 6. Integración en Godot (experimental)

- **Ajustes → «Érebo: invocación cinematográfica»** (solo Auditoría o editor): «No» (predeterminado), «Abreviada»,
  «Completa» y «Completa la primera vez».
- `combate.gd`: con la opción encendida y el vídeo presente, `_invocar_sobre` reproduce el vídeo en lugar de
  `_teatro_erebo`. Después tira el dado **con la misma fórmula** y aplica el daño una sola vez.
- **Se puede saltar** tocando la pantalla o con Intro/Esc, como ahora, también durante el fundido de entrada. Al saltar,
  el daño se aplica igual, una sola vez, y el ATB es el mismo.
- **Si no se puede reproducir** (falta el archivo o el flujo da error), se usa el teatro de siempre.

## 7. Registro de producción (14/11)

| Paso | Estado | Dónde / qué se comprobó |
|---|---|---|
| 1. Storyboard | Hecho | §2 y §3 |
| 2. Guion técnico | Hecho | §4, con los tiempos de cada acontecimiento en `cinematica_erebo.py` (diccionario `T`) |
| 3. Animática | Hecha | 480×270 con su sonido: `D:\REBELUM_diagnostico\erebo_cine\animatica\` (`animatica_completa.mp4`). Sirvió para corregir los planos antes del render definitivo |
| 4. Actuación | Hecho (primera versión) | «salir» para el despertar (primero las garras, después el cuerpo y la máscara). Encima, una capa propia: IK del brazo al orbe, dedos uno a uno, cabeza que se ladea al descubrir el orbe, dos sacudidas al absorber, encorvarse sobre el puño y erguirse de golpe al liberar |
| 5. Luz | Hecho | Orbe como luz motivada (con charco en el suelo), contraluz frío, realce frío para las garras en el P3 y luces de mano, puño y estallido. La luz del estallido apenas enciende la niebla (si no, lava la imagen) |
| 6. Efectos | Hecho | Partículas deterministas (atracción → congelado 0,25 s → espiral hacia la mano y el brazo → órbita del puño → estallido con estelas). Grietas del orbe que avanzan, venas ramificadas por la mano y el brazo, runas (anillo y círculo), humo que se mueve, sombras en el suelo, ondas, 40 fragmentos de cristal, haz y destello |
| 7. Deformaciones y contacto | Hecho y medido | Agarre calculado: se prueban 100 orientaciones de la mano y cada dedo se cierra hasta tocar. Holgura final: pulgar 3,3 mm, índice 3,3, medio 4,8, anular 4,3 y meñique 3,6; palma 19 mm. Ningún dedo atraviesa (lo imprime el script en cada render). Error del IK: 0,0 mm |
| 8. Render por planos | Hecho | 1280×720, EEVEE, 20 muestras, AgX, *bloom* y aberración ligera. Fotogramas en `D:\REBELUM_diagnostico\erebo_cine\final\` |
| 9. Montaje | Hecho | `montaje_erebo.py` (editor de vídeo de Blender) |
| 10. Sonido | Hecho | Especialista de sonido: `D:\REBELUM_diagnostico\erebo_cine\sonido\` (`INFORME.md`, `procedencia.csv`: 87 tramos de 30 archivos, todos de los paquetes GDC de Sonniss con su licencia leída). −16 LUFS; los golpes caen en su fotograma |
| 11. Integración en Godot | Hecha (experimental, apagada) | `invocacion_erebo_video.gd`, `combate.gd` y `menus.gd`. Prueba `prueba_erebo_video` (ver §8) |
| 12. Validación en Android | **PENDIENTE** | El Redmi está desconectado. Hay que medir la decodificación de Theora 960×540 en el UMS9230E, la sincronía del audio, la memoria y el tiempo de carga |

### Problemas encontrados y cómo se resolvieron

| Problema | Arreglo |
|---|---|
| El plano de las manos salía negro | La cámara quedaba dentro de la capucha agazapada, que es enorme en proporción *chibi*. Ahora `distancia_libre()` coloca la cámara fuera de la malla |
| La cámara de un plano se torcía | `to_track_quat('-Z', 'Z')` es degenerado; ahora usa `'-Z', 'Y'` |
| El orbe era una canica plana | Su ruido usaba coordenadas en metros sobre una esfera de 4 cm; se cambió a coordenadas generadas (0-1) |
| En el agarre no se veía la mano | El orbe la tapaba desde delante. Se eligió, entre 8 cámaras probadas, una por detrás y por encima del hombro, con un realce frío |
| Partículas como confeti y desenfoques enormes | Menos partículas, más finas en los primeros planos, ninguna pegada al objetivo y diafragma más cerrado en los planos de detalle |
| «conjuro» lo agachaba hasta el suelo al comprimir | La compresión y la liberación se hacen con IK: el puño ante el pecho y la palma hacia delante |
| Las venas formaban una red | Bordes de Voronoi recortados por ruido: ahora son grietas ramificadas |

## 8. Pruebas en el PC

- **`prueba_erebo_video` (sin ventana): SUPERADA, 0 fallos.**
  - Apagada: se usa el teatro de siempre, y la prueba comprueba que aparece.
  - Los dos `.ogv` se cargan como `VideoStreamTheora`, duran 20,00 s y 6,80 s y avanzan.
  - Abreviada:
    - el vídeo tapa el combate y el teatro no se crea;
    - el estado sigue en «accion» todo el rato;
    - la música se aparta y vuelve exactamente;
    - los PV cambian **una sola vez** y el registro anuncia el resultado una sola vez;
    - no quedan restos.
  - **ATB:** con la velocidad bajada a 2/s para que no llegue al tope, Kael termina con 39,98 frente a 40,05 esperado.
    Es el mismo tiempo que la invocación de siempre, también al saltar.
  - **Saltar:** con Esc a los 0,9 s corta el vídeo; durante el fundido de entrada corta en 0,7 s y no saca el teatro.
    - Sin ventana el toque simulado no llega a la pantalla, por eso la prueba usa Esc, la otra entrada real.
  - «1.ª completa» pasa de la completa a la abreviada.
- **Revisión escéptica** (4 revisores y 1 verificador por hallazgo) sobre la integración. Confirmó estos defectos, ya corregidos:
  - tocar durante el fundido de entrada daba el vídeo por fallido y sacaba entera la invocación 3D;
  - el destello se mostraba aunque el vídeo no hubiera arrancado;
  - el ATB del vídeo no se igualaba al de la invocación de siempre (y los textos afirmaban que no corría);
  - varias comprobaciones de la prueba eran demasiado blandas.
- **`fotos_erebo_video` (con ventana; RTX 3050, Compatibility): 0 fallos.**
  - Las 17 capturas, tomadas por la posición del vídeo, se ven correctas dentro del combate.
  - Con el ejecutor (`--fixed-fps 30`) el tiempo del juego corre más que el real y el vídeo, que avanza con él, también:
    sus duraciones no valen.
  - **En tiempo real** (sin fps fijos y con `user://` aislado: `D:\REBELUM_diagnostico\pruebas\2026-11-14_video_tiempo_real\`):

    | Versión | Llega hasta | En pantalla, con fundidos | Fotograma | Más de 50 ms |
    |---|---|---|---|---|
    | Abreviada | 6,78 s | 7,3 s | 33,0 ms (tope de 30 FPS del perfil) | 0 |
    | Completa | 19,99 s | 20,5 s | 33,2 ms | 0 |
- **Vídeos para Godot** (`aethelgard/videos/`): Ogg Theora 960×540 a 30 fps, 2 500 kbit/s, con Vorbis estéreo a 160 kbit/s.
  - La completa ocupa 6,4 MB y la abreviada 2,3 MB.
  - Solo van en la APK de Auditoría.
- **Vídeos para revisar (H.264 1280×720):** `D:\REBELUM_diagnostico\erebo_cine\final\erebo_invocacion_completa.mp4` y `..._abreviada.mp4`.

## 9. Lo que falta o no se ha comprobado

- **Android:** todo el paso 12.
- **Revisión del usuario:** la calidad visual y el sonido. Nadie lo ha visto ni oído todavía: el sonido lo diseñó un especialista que no puede escuchar.
- **Limitaciones conocidas de esta primera versión:**
  - La máscara no tiene animación facial; su expresividad sale de la cabeza, la luz y la silueta, como pide el diseño.
  - La capa no tiene simulación de tela: la mueven los huesos de Mixamo.
  - El haz final se ve casi de frente, como una esfera que viene hacia la cámara.
