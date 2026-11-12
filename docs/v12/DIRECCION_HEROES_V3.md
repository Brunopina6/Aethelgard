# Dirección de los protagonistas v3 (V12, 12/11/2026)

Documento breve de dirección para Kael, Lya y Garon v3 (`aethelgard/personajes/heroes_v3/`). Sale del estudio
comparativo de los originales y los v2 con las mismas cámaras y la misma luz:
`D:\REBELUM_diagnostico\v12\expansion\heroes3\estudio\hoja_<héroe>_original_v2.png` (frente, tres cuartos, perfil,
silueta en negro de frente y de perfil, tamaño del combate y primer plano).

## Lo que dice el estudio (observado en las hojas)

- **Los v2 son geométricamente los originales:** misma malla y texturas de Meshy; cambian clips, cara (atlas sobre la
  textura) y sombreador. En una hoja de Blender con la misma luz se ven iguales salvo la pose.
- **A la distancia del combate** (unos 200 px de alto en 1280 × 720) el detalle pintado de Meshy se convierte en ruido:
  lo que se lee es la silueta, las masas de color y los ojos. Kael se lee por el pelo negro y el abrigo blanco; Lya,
  por la melena rubia y la falda; Garon, por el penacho rojo y la masa oscura.
- **Siluetas en negro:** Kael y Lya son reconocibles de frente; de perfil, Kael es una masa con un pico de pelo y Lya
  una campana. Garon es un bloque: el penacho es lo único que lo distingue.
- **Proporción:** Kael y Garon tienen cabeza grande (casi un tercio del alto con el pelo o el yelmo); Lya, piernas
  largas en su esqueleto y cabeza más pequeña. Para la influencia chibi, la v3 agranda la cabeza y lo que va en ella
  dentro del mismo esqueleto, desde la base del cráneo: **×1,16 Kael, ×1,12 Lya, ×1,08 Garon** (`ESCALA_CABEZA`).
  Medido a ojo en las capturas del combate: la cabeza de la v3 queda del tamaño de la original (antes de agrandarla
  era más pequeña); no hay una cifra de «cabezas» fiable porque el pelo y el yelmo de Meshy no tienen límite claro.
- **Licencia:** las mallas, texturas y caras de los originales y los v2 son de Meshy (licencia pendiente).

## Principios

1. **Mismo esqueleto, cuerpo nuevo:** la v3 es geometría propia hecha por guion (`fuente/crear_heroes_v3.py`,
   `personajes/heroes_v3/fuentes_blender/`) sobre el rig común de los v2, sin una sola cara ni textura de Meshy. Así
   valen todos los clips (los de los v2 y los del especialista de combate) y la licencia avanza.
2. **Formas grandes y claras antes que detalle:** la silueta se lee a 200 px; el detalle se añade con color por
   vértice, oclusión, una textura de detalle pequeña común (trama, hebras, grano, pliegues) y un contorno de tinta del
   color del material.
3. **Luz pintada:** dos tonos con terminador suave y degradado, sombra teñida (fría en tela y pelo, rosada en la piel),
   borde de luz y brillos por material (metal, pelo en anillo, cristal, cuero). Sin texturas de 2048: una de detalle de
   512 para los tres y un atlas de cara por héroe.
4. **Cara de anime propia:** ojos grandes de atlas dibujado por código, boca y cejas independientes; las cejas se
   mueven por formas clave (arriba, ceño, tristes) y el parpadeo solo toca los ojos. Nada copiado de otro juego.
5. **Personalidad en la silueta, no en el ruido:** un rasgo dominante por héroe y colores de familia (blanco, azul
   hielo y oro comunes a Kael y Lya; acero oscuro, oro y rojo en Garon).

## Por héroe

| | Kael (espadachín) | Lya (maga) | Garon (guardián) |
|---|---|---|---|
| Rasgo dominante | Pelo negro azulado alborotado: picos hacia fuera y arriba, flequillo en punta con un mechón entre los ojos y un mechón rebelde arriba | Melena rubia larga y ondulada hasta la cadera, con lirios blancos y lazo | Yelmo cerrado grande con visera de rejilla y penacho rojo largo hacia atrás |
| Cara | Ojos azules afilados (forma «viva»), cejas rectas algo bajas, la cicatriz en cruz de la mejilla izquierda | Ojos azul cielo grandes y redondos (forma «dulce», pliegue del párpado), cejas finas y claras, rubor | La mirada en la sombra de la visera: dos brillos ámbar que cambian con la expresión (el yelmo sigue cerrado) |
| Ropa y oficio | Abrigo largo blanco abierto, cuello alto azul por dentro, bajos en degradado azul hielo con ribete dorado, cuatro faldones que se separan al moverse, hombreras, camisa azul marino, colgante de estrella, dos cinturones, guantes sin dedos con brazalete dorado, botas altas con correas | Vestido blanco de hombros descubiertos, falda corta delante con cola detrás, degradado azul, cinturón dorado con gema, mangas sueltas acampanadas, zapatos de tacón con cristales | Coraza de acero oscuro con el águila dorada, hombreras de tres láminas, faldar de placas con tela roja, quijotes, rodilleras en punta, grebas y escarpes; broquel en el antebrazo izquierdo |
| Paleta (sRGB) | blanco 0,88; azul hielo 0,62-0,77-0,92; azul marino 0,15-0,18-0,31; oro 0,86-0,74-0,50; pelo 0,25-0,22-0,25 | blanco 0,95; azul hielo 0,64-0,80-0,95; oro 0,90-0,80-0,56; pelo 0,97-0,88-0,62 | acero 0,27-0,28-0,33; oro 0,88-0,72-0,46; rojo 0,66-0,12-0,14 |
| Silueta clave | Picos del pelo + abrigo largo en A | Melena + falda en campana asimétrica | Cabeza-yelmo grande + penacho + hombros anchos |

## Lo que debe conservarse para reconocerles

Kael: pelo negro en picos, ojos azules, cicatriz en cruz, abrigo blanco largo con azul y oro, botas marrones.
Lya: melena rubia muy larga, flores blancas, vestido blanco y azul de falda asimétrica, mangas sueltas.
Garon: yelmo cerrado con penacho rojo, armadura oscura con oro, águila del pecho, tela roja del faldar, base ancha.

## Pendiente de decidir (no lo decide esta versión)

- La mirada de Garon en la visera y el broquel son propuestas: si el usuario prefiere el yelmo sin ojos, basta con no
  dibujarlos (`garon_v3.py`, `CARA`).
- Naira (prototipo sin aprobar) no se toca. Nota de estilo: si se aprueba, encajaría con la misma receta (geometría
  propia sobre el rig común, cara de atlas, luz pintada y contorno) y una paleta que no repita el blanco y azul de Kael
  y Lya.
