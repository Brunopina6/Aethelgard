# D. PREPARACIÓN PARA LA FASE 3 — talleres de Lya, Kael y Garon (propuesta)

**Estado:** propuesta de diseño, **no canon y sin implementar**. Necesita la aprobación del usuario antes de tocar el
juego: es mecánica nueva y cambia la economía. La base técnica ya está hecha y probada (fase 2): `datos/catalogo.gd`,
`investigacion.gd`, `talleres.gd` y la clave `investigaciones` en la partida.

## 1. Idea en una frase

Lo que los héroes encuentran y derrotan alimenta tres oficios. Cada uno investiga para aprender recetas y fabrica cosas
útiles, sin sustituir a la tienda ni romper el equilibrio del combate.

## 2. Los tres talleres

| Taller | Quién | Investiga | Fabrica (primera versión) | Dónde (propuesta) |
|---|---|---|---|---|
| `alquimia` | Lya | ingredientes y hechizos | pociones y éteres (los objetos que ya existen) | un rincón de la posada de Oakhaven, junto a la botica |
| `forja` | Kael | armas y materiales especiales | mejoras de espada (+ataque) y propiedades elementales | la herrería de Oakhaven (por decidir) |
| `armaduras` | Garon | protecciones y runas | refuerzos de armadura y resistencias | ídem |

**Primera versión jugable, recomendada:** solo alquimia.
- Es la más sencilla: los objetos que da ya existen, así que no hacen falta modelos ni equilibrio nuevos.
- Forja y armaduras, después, con lo aprendido.

## 3. Cómo se juega (primera versión)

1. **Conseguir materiales:**
   - el botín de las bestias (ya existe: la Corteza espinosa de Zarzalín);
   - puntos de recolección en Pastos Verdes 3D: plantas que brillan y se recogen una vez por visita (nuevo; necesita
     arte y aprobación);
   - y los hallazgos.
2. **Investigar** en el taller:
   - cada investigación pide tener ciertos materiales, un hito de la historia, otra investigación o un nivel;
   - avanza con «pasos». Propuesta: un paso por combate ganado mientras está en curso, para que avance jugando, sin
     esperas de tiempo real.
3. **Fabricar:**
   - las recetas desbloqueadas gastan materiales y dan el objeto, todo o nada (ya probado en `talleres.gd`);
   - el precio de venta de lo fabricado no puede superar el de sus materiales, para que no sea una fuente de dinero.

## 4. Vínculos con misiones y progresión

- **Una misión presenta cada taller:**
  - Lya descubre la botica de Oakhaven, sin revelar nada del acto III;
  - el taller se abre con un hito (`taller_alquimia_abierto`), que ya es un tipo de requisito.
- **Recetas por etapas:** las primeras, desde el principio; las mejores piden hitos de actos posteriores. Así crecen
  con la historia.
- **Guardado:**
  - investigaciones en `investigaciones` (ya existe);
  - recetas aprendidas: se deducen de las investigaciones completadas, sin otra clave;
  - materiales en el inventario (ya existe).
  - Formato de partida: subir `progreso.FORMATO` a 3 solo si cambia algo incompatible. Con lo diseñado, no hace falta.

## 5. Qué hay que construir en la fase 3

1. **Datos aprobados** (`.tres`): 3-4 materiales, 2-3 investigaciones y 3-4 recetas de alquimia. `prueba_datos` los
   valida solos.
2. **Pantalla del taller:**
   - tres pestañas: Investigar, Fabricar y Materiales;
   - con el estilo de los menús actuales;
   - legible en el Redmi, con botones grandes.
3. **Enganches:**
   - `combate.gd` avanza las investigaciones en curso al ganar: una línea en `_fin_combate`, con
     `investigacion.avanzar`;
   - la recolección, en Pastos Verdes 3D.
4. **Pruebas:**
   - pantalla: abrir, investigar, fabricar y volver, con una partida antigua;
   - economía: ninguna receta da más monedas de las que cuesta;
   - partida: el taller sobrevive a guardar y cargar.
5. **Redmi:** abrir el taller y fabricar, con toques; ver que los textos caben.

## 6. Lo que decide el usuario

- Qué hace cada taller exactamente, y si la forja y las armaduras mejoran el equipo que ya hay o fabrican equipo nuevo.
- Dónde está cada taller en el mundo y qué misión lo abre.
- Si la investigación avanza con combates, con tiempo de juego o con materiales.
- Nombres, textos y aspecto (biblia narrativa y dirección de arte).

## 7. Pendiente de medir en el Redmi (para las siguientes fases de rendimiento)

1. Con la APK de esta rama: el arranque frío y los siguientes, la memoria (`dumpsys meminfo`) y la entrada en Pastos
   Verdes 3D y en Oakhaven 3D. Compararlo con la v387.
2. La calidad Automática: qué perfil elige, que no oscile y que no cambie en combate.
3. Pastos Verdes 3D en medio, con el candidato B: debería ir a 30 FPS (sin medir con esta integración).
4. Si la carga diferida de lo del combate (informe A) da tirones al entrar en el primer combate.
