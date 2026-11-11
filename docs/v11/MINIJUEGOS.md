# V11 · Minijuegos (hito E)

Rama LOCAL `claude/rebelum-v11`. Probado **solo en el PC**. Nombres y textos: **PROPUESTA**.

## Hecho: «Las parejas del Cuervo» (juego de taberna, completo)

- **Dónde:** en la mesa de juego del Patio del Cuervo, junto a la taberna de Oakhaven 2D. Su sitio está en la casilla
  (14,5; 30,5). Kael se acerca y el botón dice «Jugar a las parejas».
- **Cómo se juega:**
  - 12 cartas boca abajo, con 6 parejas de símbolos del reino: fuego, agua, rayo, cura, runa y luna;
  - se levantan dos: si son iguales se quedan; si no, se ven un momento y se vuelven;
  - hay 14 intentos, y se gana con las 6 parejas.
- **Premio, sin apuestas:** no se pone dinero.
  - La primera victoria da 15 monedas y una Poción.
  - Después, solo **batir el récord** (menos intentos) da 10 monedas, así que no se puede repetir para sacar dinero.
  - El récord y las victorias van en la partida (clave `taberna`).
- **Controles:** el dedo o el ratón (tocar una carta); teclado o mando (las flechas mueven e Intro levanta); Esc, Atrás
  de Android o «Salir» para salir. Mientras se juega, Kael no anda; al salir se guarda.
- **Archivos:** `taberna_parejas.gd` (la ventana y el juego) y `ciudades/taberna_juegos.gd` (premios y récord).
- **Dibujo:** las cartas se dibujan con figuras sencillas, sin imágenes nuevas. La mesa usa por ahora el dibujo del
  atril.
- **Pruebas:** `prueba_taberna` comprueba:
  - los premios (primera vez, récord) y el guardado, también con una partida antigua;
  - una partida perfecta y que dos distintas se vuelven;
  - perder sin premio;
  - el teclado y Atrás, y la mesa en la ciudad.
- **Capturas:** `D:\REBELUM_diagnostico\fase2\2026-11-11_v11_fotos_taberna\fotos` (la mesa, una partida a medias y la
  ganada).

## Pendiente

- **Dibujo propio de la mesa** de juego, por gráficos.
- **El segundo minijuego.** Lo más prometedor, por este orden:
  1. el buscador de metales de Kael (hito D), que necesita una región;
  2. el laboratorio de Lya (combinaciones con pistas), que reutiliza la alquimia.
- **El deporte ESPIRAL:** sin empezar. La directiva pide un partido completo y divertido antes de nada más; es un
  trabajo grande.
- En el Redmi: el tamaño de las cartas con el dedo y la lectura en pantalla pequeña.
