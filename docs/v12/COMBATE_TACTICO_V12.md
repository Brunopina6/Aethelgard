# Combate táctico V12: propuesta (solo documento)

12/11/2026 · especialista de animación de combate (`claude/v12-combate2`). **Nada de esto está implementado.** Son ideas
para que el ATB pida más decisiones, respetando lo que ya existe y funciona:

- la interrupción (V11: quitar el 25 % de la vida a quien prepara un golpe lo corta y lo deja aturdido; la magia rompe la
  guardia del Slime; Quiebra corta siempre);
- Defender (la mitad del daño hasta su turno) y la Guardia de Garon (cubre a un aliado);
- los dúos (Filo Arcano, Quiebra, Barrera Rúnica; con Naira, Contrapeso y Equinoccio), que gastan el turno de los dos;
- la magia de siempre (12 magias, niveles I-III), las artes (Alba, Escarcha, Lumbre), la magia negra con sus afinidades
  (`combate_afinidades.gd`, solo para las escuelas nuevas: D-048), Embuir, Esgrima, la Armonía y Érebo.

Ninguna toca las fórmulas de daño ni las 12 magias de siempre (la huella de `prueba_combate_huella` no cambiaría salvo
donde se dice). Todas irían detrás de un interruptor, como el resto de V12.

## Qué falta hoy (observado jugando los combates automáticos y leyendo `combate.gd`)

1. **El orden de turnos no se ve.** El ATB llena barras, pero el jugador no sabe quién actúa después de quién. Sin eso,
   «interrumpir antes de que suelte el golpe» es una apuesta.
2. **Pocas razones para no atacar.** Fuera de los avisos (⚠) y de los jefes, Atacar casi siempre es la mejor orden.
3. **La posición no existe.** Garon es «el muro», pero delante o detrás no cambia nada salvo con la Guardia.
4. **El ritmo de la Armonía es plano**: +0,15 por acción, haga lo que haga.

## Propuestas (de menos a más cambio)

### A. Línea de turnos visible (sin cambiar reglas) — la más clara
Una tira pequeña arriba con los próximos 5 turnos (iconos de cabeza) calculada con el `vel` y el `atb` de cada uno
(lo que ya hace `_process`). Con una orden marcada, la tira enseña dónde caería el turno de quien actúa (Compás del Alba
mueve el ATB: se vería). **Por qué:** convierte la interrupción y Defender en decisiones informadas. No toca el azar.
**Coste:** un `Control` con 5 `TextureRect`; se recalcula al cambiar la cola. **Riesgo:** ninguno en las reglas.

### B. «Romper» en vez de solo interrumpir (premio por leer el aviso)
Hoy, cortar una carga deja al enemigo aturdido un turno. Propuesta: además, durante ese turno recibe +25 % de daño
físico («roto»). Empuja a cambiar el plan cuando sale ⚠: cargar contra él (Kael, Garon) en vez de defenderse.
**Respeta** el umbral del 25 % y Quiebra. **Cambia** el daño solo en ese turno (la huella cambiaría solo en combates con
interrupción).

### C. Guardia posicional de Garon (delante / detrás)
Una orden barata «Adelantarse» (0 PM, gasta el turno): Garon pasa a primera fila y los golpes «a uno» de los enemigos
cuerpo a cuerpo le eligen a él con más probabilidad (no siempre), pero los golpes «a todos» le hacen +10 %. Hasta su
siguiente turno o hasta que ataque. La animación v12 ya tiene su postura (`c12_defensa`) y la carrera corta.
**Por qué:** da sentido a «el muro» sin gastar la Guardia (que sigue siendo la protección fuerte, con PM).

### D. Armonía por variedad
La Armonía sube +0,15 por acción como hoy, y +0,05 más si la acción es de un tipo distinto a la anterior del grupo
(físico → magia → dúo → objeto). Premia combinar en lugar de repetir Atacar. **No cambia** Érebo ni su coste.

### E. Contraataque al defender (pequeña, clara, la recomendada para probar primero)
Quien Defiende y recibe un golpe cuerpo a cuerpo responde con un golpe débil (×0,5, sin crítico, sin Embuir), una vez
por turno. Hace que Defender ante un aviso sea una apuesta interesante (aguantar y devolver) y no solo esperar. La
animación v12 ya tiene el bloqueo (`c12_bloqueo`); faltaría un `c12_contra` corto (0,5 s) en la biblioteca de clips.
**Por qué esta primero:** una sola regla, local (`_golpe_visual` del enemigo → réplica), que ya existe en forma de
accesorio (C2, «Guardiana de Ámbar», `Extra.replica`): reutiliza su camino de daño y su número «Réplica».
**Riesgo:** sube el daño del grupo en combates largos; con ×0,5 y una vez por turno, poco. No la he implementado:
cambia el equilibrio y la huella del combate, y eso lo decide el usuario.

### F. Dúos con ventana de tiempo
Los dúos exigen hoy que el socio tenga ≥ 50 % de ATB. Propuesta: si el socio tiene la barra LLENA (en cola), el dúo
no le quita el turno, solo lo retrasa medio turno. Premia guardar el turno para combinar. **No cambia** costes ni daño.

### G. Elementos y estados de verdad en las 12 magias (la grande; decisión del usuario)
`combate_afinidades.gd` ya sabe debilidades y resistencias, pero solo la usan las escuelas nuevas
(`APLICAR_A_LAS_DE_SIEMPRE = false`, D-048). Encenderlo daría sentido a elegir Fuego, Agua o Rayo por enemigo. Es el
cambio de equilibrio más grande: rehacer `prueba_equilibrio` y la huella. Solo si el usuario lo quiere.

## Recomendación

1. **A** (línea de turnos) primero: no cambia reglas y hace legibles las que ya hay.
2. **E** (contraataque al defender) como la primera regla nueva, apagada, para probarla en el móvil.
3. **B** y **C** después, viendo cómo se juega con A y E.
4. **G** solo con decisión expresa.

La animación v12 (`combate_anim_v12.gd`) ya deja sitio a todo esto: reacciones distintas (ligera, fuerte, bloqueo), la
postura de defensa, la preparación visible de las técnicas y una cámara corta para los momentos grandes.
