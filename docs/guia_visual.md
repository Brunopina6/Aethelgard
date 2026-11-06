# Guía visual de Aethelgard — Fase 2 (documento vivo)

Objetivo: un mundo de fantasía **luminoso, limpio y amable**, con naturaleza abundante y lugares que invitan a
explorar. Referencias de *sensación* (no de contenido): la luz y el color de Infinity Nikki, la ternura de
Final Fantasy IX y la puesta en escena de Clair Obscur. Aethelgard tiene identidad propia: no se copian modelos,
texturas, personajes, logotipos ni composiciones de ningún juego.

Estado: **propuesta** para aprobar. Lo marcado «(medido)» sale de pruebas reales en el Redmi A7 Pro o en el PC.

## 1. Luz
- Sol cálido (1,0 · 0,9 · 0,72) desde arriba a la izquierda; relleno ambiente azulado (0,62 · 0,7 · 0,88).
- Mismo brillo en los tres perfiles: con sombras se baja la exposición a 0,58 (medido: con sombras la imagen se
  aclara un 38 % en Compatibility).
- Hora del día de Pastos Verdes: **mañana luminosa**. Más adelante, atardecer dorado como segunda variante.
- Brillos de ambiente (faroles, cristales, magia): emisión + halos pintados. Luces reales solo en el perfil alto
  (medido: dos luces de farol = ~7 ms en el Redmi).

## 2. Color
- Hierba: verdes amarillentos y saturados; cumbres algo más frías. Flores: lavanda, rosa, blanco y amarillo.
- Piedra: gris cálido (nunca blanco quemado). Madera: marrón rojizo. Agua: turquesa con crestas claras.
- Ajuste final: saturación 1,3 y contraste 1,1 (en el entorno de la escena).
- Cielo: azul intenso arriba, horizonte claro; bruma ligera que da profundidad.

## 3. Formas y escala
- Cámara de exploración: perspectiva, 45°, 20 m (elegida por el autor). Kael ≈ 7 % de la altura de pantalla.
- Siluetas redondeadas y legibles a esa distancia: copas grandes y suaves, rocas redondeadas, caminos claros.
- Árboles: 5–8 m; arbustos 0,6–1,2 m; casas de 1 planta y media; puentes de piedra con arco.
- La decoración guía al jugador (ver Skill `aet-diseno-exploracion`).

## 4. Presupuestos por objeto (perfil medio, Redmi A7 Pro)
| Tipo | Triángulos | Texturas | Notas |
|---|---|---|---|
| Árbol grande | ≤ 6 000 | 1024 | follaje con alfa recortado, sin mezcla |
| Arbusto | ≤ 1 500 | 512–1024 | MultiMesh si hay muchos |
| Roca | ≤ 800 | 512 | agrupadas por material |
| Casa | ≤ 8 000 | 1024 | interior aparte |
| Prop pequeño | ≤ 500 | 256–512 | farol, cartel, barril |
| Personaje principal | ~27 500 (Kael, medido sin coste apreciable) | 1024–2048 | |

Escena completa a la vista (medido como seguro en el Redmi, perfil medio, 30 FPS sin tirones): ~140 dibujos y
~325 000 triángulos. Cualquier añadido se mide con el banco «TOPE» antes de quedarse.

## 5. Qué evitar en móvil (medido o documentado)
- Luces puntuales reales a pleno día (medido), sombras en 4 tramos y mapas de sombra de 4096 (medido).
- Sombreados que leen la pantalla (refracción) fuera del perfil alto.
- Transparencias grandes superpuestas (follaje semitransparente), texturas de 4K, modelos de Meshy sin reducir.

## 6. Perfiles
- **Bajo**: misma paleta y luz; sin sombras; menos hierba; 3D al 75 % (interfaz nítida).
- **Medio**: sombras en 2 tramos; halos falsos en faroles; 3D al 90 %.
- **Alto**: luces reales, refracción del agua, MSAA, sombras de 4096 (para móviles potentes y PC; a medir).
