# V11 · El buscador de metales de Kael (hito D)

Rama LOCAL `claude/rebelum-v11`. **Estado: solo la lógica, hecha y probada.** Todavía **no se puede usar en el
juego**: falta la región del Mar de Cristal, que es la que pondrá el aparato en pantalla. No se debe dar por terminado.

## Qué hay (`aethelgard/buscador.gd`)

- **Reparto con semilla:**
  - cada región tiene sus hallazgos enterrados en un área;
  - la misma región y la misma semilla dan siempre los mismos sitios, igual en el PC que en el móvil;
  - el primer sector, `mar_de_cristal_1`, tiene un área de 80 × 80 m, 14 hallazgos comunes y 6 señales falsas.
- **Hallazgos comunes:** Moneda antigua (55 %), Mineral rúnico (20 %), Fragmento de espada (15 %) y Reliquia de
  vidrio (10 %, rara: su pitido es distinto).
- **Únicos:** van en un sitio fijo y salen una sola vez, con cualquier semilla. El primero es la «Llave de vidrio», que
  es la que empezaría el encargo arqueológico propuesto en `HISTORIA.md` §3.
- **Señales falsas:** pitan como metal, pero al cavar sale «Chatarra» y nada más. Con el buscador en nivel 3 ya no
  pitan.
- **La señal:**
  - va de 0 (lejos) a 1 (encima) y dice si lo más cercano es raro;
  - el alcance crece con el nivel: 6, 9 y 12 m.
- **Cavar:** solo encima (a 1,2, 1,5 o 1,8 m según el nivel), una vez por hallazgo; el objeto va al inventario.
- **Guardado:** lo desenterrado y el nivel van en la partida (clave `buscador`). Una partida antigua empieza en el
  nivel 1 sin nada.

## Pruebas

`prueba_buscador` comprueba:
- que el reparto es reproducible y el único está en su sitio;
- la señal y el alcance del nivel 2;
- cavar una sola vez, con el único sin repetirse;
- las falsas, y que el nivel 3 no las oye;
- el guardado, también con una partida antigua.

## Lo que falta para que sea jugable

1. La región del Mar de Cristal (un sector 3D, como Pastos Verdes y la Garganta).
2. En esa región:
   - el aparato en pantalla: una aguja o barra que se llena, y pitidos más rápidos al acercarse (otro tono si es raro);
   - el botón «Excavar» con su animación y su sonido;
   - el hallazgo a la vista.
3. Quién da el buscador (narrativa propone un diapasón de Hierro de la Falla que regala Ferro) y cómo se mejora
   (forja de Kael).
4. Que los hallazgos sirvan:
   - los fragmentos, para reforjar una espada antigua;
   - la Llave de vidrio, para abrir el encargo arqueológico.
5. En el Redmi: los pitidos, el indicador y el rendimiento.
