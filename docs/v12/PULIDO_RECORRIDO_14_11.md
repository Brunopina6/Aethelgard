# Pulido del recorrido de Oakhaven y Pastos Verdes (14/11, noche)

Encargo del usuario, prioridad 3: buscar en Oakhaven y Pastos Verdes objetivos confusos, interacciones poco visibles,
NPC que bloqueen caminos, conversaciones repetidas, recompensas sin explicación y problemas al volver del combate.
Corregir defectos concretos, sin cambiar canon ni fórmulas.

**Método:**
- Un revisor de solo lectura siguió el código de las seis categorías.
- El coordinador comprobó cada hallazgo en el código antes de corregirlo.
- El recorrido jugado del cantero (`fotos_cantero_recorrido`) encontró además los obstáculos reales de la plaza.
- Todo comprobado en el PC; nada en el Redmi.

## Corregido

1. **Grave. Ferro repetía su escena para siempre si se vendía o gastaba el Hierro de la Falla** antes de entregárselo.
   - Causa: la veta da un solo hierro y la tienda dejaba venderlo. Además, sin la señal de servicio, la forja del
     distrito no volvía a abrirse.
   - Arreglo: `talleres.gd` → `reservado()`. Mientras «El pedido de Maese Ferro» está pendiente, la tienda no lo
     ofrece para vender y el taller no lo gasta («Maese Ferro espera ese Hierro de la Falla: llévaselo antes»).
   - Prueba: `prueba_oakhaven_v10`. La contraprueba, sin el arreglo, da 2 fallos.
2. **Ferro y Mirta repetían siempre el mismo diálogo en la 3D.** El contador se guardaba por oficio y se leía por
   vecino (`distrito.gd`). Ahora se turnan, como en la 2D; por ejemplo, `oak_ferro_v` ya sale.
3. **Avisos de premio del distrito a mitad de diálogo, y sin guardar.** Ahora van a la cola de avisos de la ciudad
   (salen al acabar el diálogo) y se guarda al terminar, como con los demás vecinos.
4. **«La fórmula desaparecida» pedía a Lya en el grupo sin decirlo.** El aviso de la tercera página y el paso del
   Diario lo dicen.
5. **«Canela se ha perdido»:** el Diario decía que Garon apartaba las ramas, pero antes hace falta la pista del
   bosque. El paso y el aviso de las ramas lo dicen, sin revelar dónde está la pista.
6. **Al volver de un combate, el ciervo de las ruinas volvía a salir y el manantial a curar.** Ahora es una vez por
   visita de verdad: se recuerda en la sesión, sin clave nueva de partida, y se olvida al salir de la región.
7. **Los lirios, los surcos y la inscripción brillaban antes de poder examinarse.** Ahora brillan desde que se
   examina el árbol.
8. **«2 Bálsamo de Mirta»** → «2 Bálsamos de Mirta».

## No corregido (y por qué)

- **El secreto de Pip:** dice «detrás de mí» aunque en la 3D, por la mañana o al anochecer, esté en otro sitio.
  - Hallazgo PROBABLE y menor; el Diario lo aclara al pagar.
  - Cambiar el aviso obliga a cambiar dos pruebas que lo fijan.
  - Queda anotado.
- **NPC que bloqueen caminos:** el revisor no encontró ninguno.
- **Sin búsqueda de caminos:** un toque lejano se para en el primer obstáculo (por ejemplo, el puesto de flores de
  Rosa, junto a la fuente). Es el comportamiento de siempre del movimiento por toque, no un defecto de la ciudad.

## Pruebas

13 superadas:
- `prueba_oakhaven_v10`, `prueba_distrito_oakhaven`, `prueba_oakhaven3d_completo` y `prueba_toque_oakhaven`;
- `prueba_dialogos_bosque`, `prueba_guardian_bosque`, `prueba_bosque_pastos`, `prueba_tienda_bosque` y
  `prueba_rincones_pastos`;
- `prueba_oficios`, `prueba_ciudad_datos`, `prueba_encargos` y `prueba_diario_misiones`.
