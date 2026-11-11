# Informe de la noche del 11 al 12/11/2026 (V12, desarrollo autónomo)

**Rama:** `claude/rebelum-v12` (local) en `D:\Aethelgard_v12`.

- **Punto de recuperación:** la etiqueta local `v12-antes-noche-20261111` (= `373e7db`).
- **Sin push, merges ni releases.** No se han tocado las apps estables ni las partidas reales: todas las pruebas se han
  hecho con datos aislados.
- **Sin Redmi esta noche.** Todo está comprobado en el PC; lo que falta ver en Android se indica en cada apartado.

## 1. Bramavidrio

**v3, «el Excavador»** (`enemigos/bramavidrio/v3/`; informe `docs/memory/agents/animaciones_v12_bramavidrio3.md`):
- **Se elige en Ajustes:** «Bramavidrio» → «Prueba v3: el Excavador». Por defecto sigue la v2 y la v1 está intacta, así
  que no se ha sustituido nada.
- **La boca está reconstruida.** Por qué estaba mal en la v2:
  - el clip de reposo la dejaba abierta 5-9°;
  - entre el labio y la mandíbula quedaba una rendija de 8-13 cm;
  - el cráneo y la mandíbula eran dos piezas sueltas.
- **Cómo es ahora:**
  - una sola piel, con la boca como ranura hasta la comisura y el labio solapando la mandíbula;
  - por dentro, paladar, encías, lengua, mejillas que se estiran y garganta;
  - los dientes, sin cruzarse.
- **Medido:**
  - en Godot, en reposo, distancia labio-mandíbula 0,0000 m y giro 0,00°;
  - en Blender, ningún par de triángulos que se cruce en 30 instantes de 8 clips;
  - apertura máxima: 55,9° en el rugido y 58° en el Aliento.
- **Tres variantes, con fotos de frente, de perfil, con la boca cerrada y abierta, en el encuadre del combate y junto a
  los héroes:**
  - «garras», la elegida: dos brazos de basalto con garras de cristal clavadas en el borde del agujero;
  - «geoda»;
  - «columnas».

  Hoja comparativa: `D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio3\comparar_combate_v2_y_variantes.png`.
  Vídeos: `...\bramavidrio3\video\v3_boca_cerca.mp4` y `v3_combate.mp4`.
- **Por qué «garras»:** con los brazos deja de leerse como un gusano. Se afianza en la Embestida, golpea con las dos
  garras en la Fractura, da un manotazo en el rugido y en la derrota los brazos caen sin fuerza.
- **Presupuesto:** 9 197 / 4 496 / 2 360 triángulos (la v2: 15 197 / 5 528 / 2 430).
- **Los tres ataques:** mantienen los mismos 10 clips, duraciones, instantes y señales, así que la Embestida, la Fractura,
  el Aliento y sus efectos funcionan igual.
- **Héroes dibujados encima:**
  - **la causa:** cada luchador 3D va en su propia ventana sin profundidad compartida, y el gusano solo se adelantaba
    mirando el hocico;
  - **el arreglo:** con la v3, mientras ataca, se mira por tramos del cuerpo y su sombra, y al acabar vuelve detrás;
  - **comprobado** en el combate de prueba con las tres versiones.
- **Falta:**
  - verlo en el Redmi y escuchar el manotazo, que no tiene sonido propio;
  - un clip de aturdimiento (no está en el contrato);
  - que narrativa revise los brazos antes de hacer la v3 la de por defecto.

**Sonido de Bramavidrio** (`audio/bramavidrio/`, 25 OGG; informe `docs/memory/agents/sonido_v12_bramavidrio.md`):
- **Momentos con sonido propio:**
  - el rugido (dos variantes), la emersión y la voz herida y la de la caída;
  - en la Embestida, el recogerse, fijar el objetivo, el latigazo, el surco y el impacto;
  - en la Fractura, la caída, el impacto y las placas al subir y al asentarse;
  - en el Aliento, la succión en bucle, el chorro, la arena que alcanza a los héroes, el atragantarse y el jadeo;
  - y el derrumbe final.
- **Origen:** capas de los paquetes GDC de Sonniss (licencia comercial sin atribución, comprobada; 57 originales con su
  SHA-256 en el informe).
- **Para volver a los de antes:** `BRAMAVIDRIO_IDENTIDAD := false` en `sonido.gd`.
- **Medido, no escuchado.** En la mezcla simulada, los grandes momentos quedan 10-14 dB por encima de la música ya bajada.

## 2. El Mar de Cristal

Informe: `docs/memory/agents/graficos_v12_desierto2.md`.

- **Perfil bajo lavado.**
  - **La causa principal era la niebla.** Las capturas del PC y del Redmi dan las mismas cifras, así que la referencia
    del PC sirve.
  - **El arreglo, solo en esta región:**
    - niebla a un tercio;
    - el sol más fuerte en lugar del brillo final;
    - arena crema en vez de rosada;
    - sombras horneadas de rocas, tiendas, carro y palmeras, y una mancha bajo cada personaje.
  - **Para volver:** `LUZ_SIN_SOMBRAS = LUZ_SIN_SOMBRAS_ANTES`.
  - **Cifras en bajo:** el punto negro en el cobijo baja de 0,420 a 0,247. Medio y alto no cambian.
- **Lugares:**
  - el humo de la fogata se ve de lejos;
  - la caravana tiene un rastro;
  - el oasis tiene agua nueva, con orilla, ondas y espuma, y palmeras solo al norte;
  - junto al cobijo hay un hito con un trapo azul;
  - hay cristales en las ruinas, el nicho, el costillar y el espejismo;
  - quedan surcos viejos del gusano;
  - las rocas que tapan a Kael se aclaran.
- **Arreglos:**
  - la franja lejana asomaba en parches;
  - las cintas de arena parecían losas;
  - había una fuga al cerrar.
- **Coste en el PC:** de +3 a +10 llamadas de dibujo y de +1 a +9 k primitivas, según el perfil.
- **Falta:**
  - medir los FPS en el Redmi (con la v615: 30,4 / 30,4 / 23,6);
  - ver la tormenta con la luz nueva;
  - en la orilla oeste del oasis se puede pisar el agua (ya pasaba antes).
- Capturas antes/después: `D:\REBELUM_diagnostico\graficos\2026-11-12_desierto\comparar\`.

## 3. Personajes y enemigos del desierto (prototipos APAGADOS)

Informe: `docs/memory/agents/animaciones_v12_desierto_personajes.md`.

- **Ismena y Oren:**
  - **Ismena:** sombrero, trenza, tablilla con mapa y estuche; 5 706 triángulos y clips de reposo, hablar, mapa,
    horizonte y regañar.
  - **Oren:** pañuelo rojo, chaleco, cuerda y bota de agua vacía; 5 660 triángulos y clips de reposo, hablar, risa y
    encogerse.
  - **En la región:** están enganchados detrás de un interruptor apagado (`npc_desierto_v12`). `prueba_mar_cristal`
    pasa con el interruptor encendido y apagado.
- **Vidracrán:** escorpión de vidrio ámbar que se entierra con la cola fuera; 2 330 triángulos y 10 clips.
- **Tolvanera:** remolino de polvo con brasas por ojos, que el Agua oscurece como barro; 1 144 triángulos y 10 clips.
- **Los dos enemigos** no están en los encuentros. Lo que haría falta en el combate está en el informe.
- **Falta:**
  - la valoración del usuario (son formas sencillas);
  - expresiones faciales y clip de andar;
  - la pose sentada de Oren;
  - medirlos en el Redmi;
  - aprobar los nombres de los enemigos.
- Capturas: `D:\REBELUM_diagnostico\animaciones\2026-11-12\desierto\`.

## 4. Exploración en Pastos Verdes

Informe: `docs/memory/agents/narrativa_v12_exploracion.md`. Cuatro mejoras pequeñas y completas:
- **bandadas** que levantan el vuelo si Kael se acerca y vuelven después;
- **el montón de los peregrinos**, donde Kael deja una piedra;
- **un nido de urraca** que brilla: con Garon, él aúpa a Kael y el premio es 25 monedas y 1 Moneda antigua, una sola vez;
- **asomarse al puente**, con una charla distinta según quién vaya con Kael.

Diálogos breves con la voz de cada uno, sin tocar el canon. Las partidas antiguas siguen cargando.

**Falta:** medirlo en el Redmi, un aleteo propio y la animación de aupar (hoy es un fundido).

## 5. Música y pantalla de inicio

- **Las tres canciones están en el proyecto y pasan sus pruebas:**
  - «When the World Forgets» en la pantalla de inicio;
  - «Pastoral Pulse» en Pastos Verdes, elegible;
  - «Volverá a amanecer» en el clímax al 20 %, que no se activa si el jefe muere de un golpe.
- **El clímax estaba bajo y ahora va a −4,5 dB.** Medido con `ebur128`, sonaba 2,7 dB por debajo de la música de combate
  que sustituye.
- **No existe música propia de jefe** (`musica_jefe*`). Los jefes usan la normal, como ya preveía el código.
- **La pantalla de inicio en 1600×720, 1024×768 y 2340×1080:** sin errores, menús legibles y carga de 7,8 a 9,5 s en el
  PC. En pantallas 20:9 todo el juego sale con franjas negras laterales: es el ajuste de escalado del proyecto entero.
  Queda como **propuesta**, sin hacer, porque afecta a toda la interfaz.

## 6. Pruebas

- **Batería completa a las 23:06** (antes de la v3): **120 superadas, 0 fallidas, 49 manuales y 0 no seguras.**
- **Batería final:** ver el apartado 9.
- **Bramavidrio con cada versión** (combate, clímax y sonido), con listas propias:
  - v3, v2 y v1: 3 de 3 cada una;
  - modelo de las tres versiones: superada.
- **Regresión encontrada y corregida:** la ordenación de la v3 dejaba al gusano delante de los héroes al acabar su turno.
  Ahora solo decide mientras ataca y al acabar vuelve detrás.

## 7. Incidentes

- **Importaciones sin aislar.** Algunas (mías y de especialistas) crearon y borraron `.recovery_mode_lock` en la carpeta
  real de datos. La partida real no cambió nunca. Desde las 22:50 importo con datos aislados.
- **Archivos sueltos de un especialista.** El de Bramavidrio v3 creó tres `.webp.import` vacíos en la raíz de
  `D:\Aethelgard_v12`: borrados y avisado.
- **Carpetas `.agents/` y `.codex/`.** Aparecieron a las 22:54 en la raíz, con carpetas de skills vacías. No son mías ni
  van en ningún commit; no las he borrado.

## 8. Pendiente para el Redmi (por orden)

1. Compilar una APK de Auditoría con todo esto y medir:
   - el Mar de Cristal en bajo, medio y alto (el bajo ya no debería verse lavado);
   - el combate con la v2 y con la v3;
   - Pastos Verdes con los rincones.
2. Escuchar los sonidos de Bramavidrio, el clímax a −4,5 dB y los bucles.
3. Elegir la v2 o la v3 de Bramavidrio, y la variante de la v3.
4. Valorar a Ismena, Oren, Vidracrán y Tolvanera, y decidir si se encienden.

## 9. Batería final (23:28, con todo integrado)

**120 superadas · 0 fallidas · 50 manuales · 0 no seguras.** La partida real, la carpeta de datos y el proyecto no
cambiaron. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-11_232844\resumen.md`.
- Las 50 manuales son las que sacan capturas con ventana y necesitan que una persona las mire.
- Las de Bramavidrio con la v3 y la v1 se pasan con listas propias: copia las tres líneas de `prueba_bramavidrio_combate`,
  `prueba_climax_jefe` y `prueba_audio_bramavidrio`, añade `bramavidrio_version=3` (o `=1`) a sus argumentos y ejecútalas
  con `ejecutar_pruebas.ps1 -Lista <archivo>`.

## 10. Commits de la noche (local)

| Commit | Qué |
|---|---|
| `9f85e77` | el clímax a −4,5 dB |
| `a730794` | prototipos del desierto (apagados) |
| `9335ccc` | exploración de Pastos Verdes |
| `74eb59c` | sonido de Bramavidrio |
| `3481784` | arte del Mar de Cristal |
| `c9e143c` | enganche apagado de Ismena y Oren |
| `4b57934` | Bramavidrio v3 |

Además, los de documentación (RETOMAR e informes).
