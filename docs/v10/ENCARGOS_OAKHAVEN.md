# Los encargos de Oakhaven (V10)

Rama LOCAL `claude/rebelum-v10`.
- Datos en `datos/encargos_oakhaven.gd`, con el formato de `encargos.gd` (pestaña Encargos del Diario).
- Diálogos de narrativa en `dialogos/oakhaven/`.
- Comprobado ejecutando, aislado, el 10/11/2026.

## A. «El pedido de Maese Ferro» (`enc_herrero`)

1. **Empieza** tras PV-05, con Garon en el grupo: Ferro pide un hierro que «canta» (`oak_ferro_pedido`).
2. **Pista:** en la Garganta 3D, al examinar el pilar del peregrino, Garon reconoce el hierro de las piedras escritas.
3. **Veta:** aparece junto al pilar. Picarla da 1 Hierro de la Falla; si van Lya y Garon, lo comentan (`gg_veta`).
4. **Decisión** con Ferro (`oak_ferro_veta`), guardada en `decisiones.hierro_ferro`:
   - **entregarlo**: 80 monedas; Ferro forja rejas para la muralla y vende Hierro de la Falla (45);
   - **quedárselo**: Kael lo usa en su forja, y Ferro le enseña «Acero de la Falla». No hay más hierro.
5. **Después,** Ferro lo recuerda (`oak_ferro_despues` y frases al pasar, según la decisión).

## B. «La fórmula desaparecida» (`enc_formula`)

1. **Empieza** tras PV-03, con Lya en el grupo: Mirta perdió su cuaderno (`oak_mirta_pedido`).
2. **Pip** vio volar unas páginas (`oak_pip_paginas`).
3. **Tres páginas** que se examinan en Oakhaven 2D, solo después de hablar con Pip:
   - en la casilla 18.5, 26;
   - en la Calle Mayor (40, 30);
   - junto a las raíces (36.5, 12.5).
4. **Final** con Mirta y Lya (`oak_mirta_formula`): 40 monedas y 2 Bálsamos de Mirta, una sola vez.
5. **Consecuencias:** la botica vende el Bálsamo y Lya puede investigar su fórmula.

## Estado

| Parte | Estado |
|---|---|
| Los dos encargos de principio a fin, con las dos decisiones de A | implementado y probado (`prueba_oakhaven_v10`) |
| Diario, pestaña Encargos | implementado y probado (`prueba_encargos`) |
| Datos de la ciudad (páginas en calles, a 2,5 casillas de todo) | implementado y probado (`prueba_ciudad_datos`, `prueba_oakhaven_rutinas`) |
| Veta en la Garganta 3D | implementado y probado (`prueba_veta_garganta`) |
| Personajes Ferro, Hilda y Mirta | propuesta de narrativa, **pendiente de que el usuario la apruebe como canon** |
| Jugarlo entero en el Redmi | pendiente de validación manual |
