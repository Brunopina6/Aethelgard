# Informe de la «segunda gran fase» (V12, 12/11/2026, madrugada)

- **Rama:** `claude/rebelum-v12` (local). Sin push, sin merges y sin releases.
- **Pruebas:** con datos aislados, en el PC.
- **Sin Redmi:** todo lo de Android queda pendiente.
- **Corte:** hubo uno por el límite de uso (hacia la 1:00); los especialistas cortados se reanudaron sin perder nada.

## Cómo se ve lo nuevo

Todo lo que cambia la historia o la apariencia de algo que el usuario ya conoce va **APAGADO**, para que lo compare antes
de decidir. Para probar con todo encendido:
`-- heroes_v2 magia_negra_v12 naira_v12 enemigos_v12`, o `Engine.set_meta("<nombre>", true)`. Lo de cada uno:

| Interruptor | Qué enciende |
|---|---|
| `heroes_v2` | Kael, Lya y Garon con rig común, 14 clips nuevos, cara expresiva (Kael y Lya) y materiales nuevos |
| `magia_negra_v12` | La escuela de magia negra en el menú de quien la sepa |
| `naira_v12` | Naira: su misión tras `mc_fin`, su combate y la reserva con la Formación |
| `enemigos_v12` | Los modelos propios del Guardián de piedra, el Gólem de ámbar y Gorthor |

Lo que **sí está encendido**:
- la Garganta, Oakhaven y el Gran Bosque Verde en 3D, con la 2D elegible en Ajustes;
- el grupo con reserva, que no cambia nada mientras no haya un cuarto miembro;
- los sonidos de la magia negra, que solo suenan si está encendida.

## 1. Personajes (fase B)

**Kael, Lya y Garon v2** (`personajes/heroes_v2/`; informe `docs/memory/agents/animaciones_v12_heroes.md`):
- **Rig común** en Blender, con clips nuevos: reposo, guardia, hablar (dos), asentir, interactuar, saltar, girar, ataque,
  recibir golpe, derribo, derrota, levantarse y victoria. Para la magia: lanzar (Kael y Lya), y concentrar y magia
  poderosa (Lya).
- **Cara expresiva** de Kael y Lya, con 8 expresiones y parpadeo.
- **Materiales:** sombreador nuevo para el metal y el borde de luz.
- **Retratos de Garon** para Dialogic, todavía sin poner en `garon.dch`.
- **Capturas antes/después:** `D:\REBELUM_diagnostico\animaciones\2026-11-12\heroes\`.
- **Límites:**
  - la geometría de Meshy es la de siempre (pelo y tela, igual);
  - en la victoria de Kael la espada queda detrás de la cabeza (hay que pulirla);
  - la licencia de Meshy sigue pendiente (registrada).

**Naira, «la Astrónoma del Eclipse»** (propuesta NO canon):
- **Historia:** `docs/v12/NAIRA.md`, contrastada con la biblia. Es la última aprendiz del Viejo Observatorio de Calid y su
  magia tapa y pesa, nunca borra (la frontera con la antagonista). Lleva 10 decisiones para el usuario en §7.
- **Conceptos:** tres (A, B y C) junto al grupo, en `D:\REBELUM_diagnostico\animaciones\2026-11-12\naira\conceptos\`. Se
  recomienda el A, «la Viajera del Eclipse».
- **Modelo provisional del A:** 14 090 triángulos y 10 clips (incluidos lanzar, concentración y magia poderosa).
  **Claramente por debajo** de la calidad de los héroes: manos de manopla, cara pintada y telas sin huesos.
- **En combate** (`naira_v12`):
  - estadísticas de mago de cristal, el Astrolabio de Bronce y las seis escuelas de magia negra;
  - su Eclipse: preparado, a todos, que deja Penumbra;
  - los dúos Contrapeso (con Kael) y Equinoccio (con Lya). Vigilia y Doble Fondo, pendientes.
- **Misión «La única noche que cabe en un día»** (prototipo apagado, en el Mar de Cristal tras `mc_fin`):
  1. el rumor en el campamento;
  2. el Viejo Observatorio;
  3. tres plomadas con el buscador;
  4. el eclipse en el cielo;
  5. el combate en el que Garon guarda la puerta (presenta la reserva);
  6. el Almanaque;
  7. la unión.

  Son 9 timelines con voz propia y sin revelar nada reservado. Capturas:
  `D:\REBELUM_diagnostico\narrativa\2026-11-12_naira_mision\`.

## 2. Enemigos (fase C)

- **Guardián de piedra, el «Centinela del Anillo»:** 5 720 triángulos y 11 clips. Antes era una imagen 2D.
- **Gólem de ámbar, el «Guardián del Nido»:** 3 654 triángulos y 12 clips. Antes compartía la imagen del Guardián.
- **Gorthor:** 7 123 triángulos y 17 clips, con Devorar, fase 2, rendirse y el perdón. Antes era el Grimfang teñido.
- **Están enganchados en `combate.gd` detrás de `enemigos_v12`.** El Gorthor nuevo es más sencillo que el modelo de
  siempre, por eso no sustituye a nada sin la comparación del usuario. Capturas:
  `D:\REBELUM_diagnostico\animaciones\2026-11-12\enemigos\`.
- **Ya estaban como prototipos (de la noche):** Vidracrán y Tolvanera, fuera de los encuentros.
- **Pendiente:**
  - encuentros distintos por región (hoy salen los mismos genéricos en todas);
  - meter a Vidracrán, Tolvanera y Cencerrante;
  - mecánicas nuevas: veneno, protectores e invocadores;
  - sus sonidos propios.

## 3. Ubicaciones en 3D (fase D)

| Lugar | Estado ahora |
|---|---|
| Pastos Verdes (10) | 3D, completo (ya lo estaba) |
| **Garganta del Diablo (2)** | **3D por defecto**, completa: Báculo del Peregrino, 4 notas y brazalete añadidos; la 2D, elegible |
| **Oakhaven (0)** | **3D por defecto**, completa: 11 vecinos con rutinas, 4 misiones, cofres, secretos, notas, gremio, tienda, parejas y la geografía nueva (muralla, campanario, adarve, colina, crematorio); la 2D, elegible |
| **Gran Bosque Verde (1)** | **3D por defecto**, completo: el trazado de la 2D, 3 cofres, la armadura con la Hoja sin Nombre, el altar y encuentros, más relieve, mirador, luz filtrada y fauna; la 2D, elegible |
| Mar de Cristal (4) | 3D en pruebas, solo el primer sector; el resto de Calid sigue en 2D |
| Cumbres de Ciclópea (3) y Valle de los Ecos (6) | Solo 2D (pendientes) |
| Arboleda Mítica (9) | Solo 2D (pendiente) |
| Sunken City (5) | Solo 2D (pendiente: repite los NPC de Oakhaven, hace falta diseño) |
| Templo Sumergido (7) y Abismo de Ceniza (8) | Solo 2D y sin acceso a pie (canon de los actos III y IV sin aprobar) |

- **Partidas:** compatibles en los dos sentidos en las tres migraciones.
- **Común para las siguientes:** `zonas3d/examinables_3d.gd`, para hallazgos y notas.

## 4. Magia negra (fase E)

- **24 hechizos en 6 escuelas:**
  - Fuego: Ascua, Llama Voraz, Lluvia de Brasas, Sol de Ceniza.
  - Hielo: Aguja Glacial, Escarcha Profunda, Prisión de Hielo, Invierno Eterno.
  - Rayo: Chispa, Rayo Encadenado, Tormenta del Cielo Roto, Juicio del Relámpago.
  - Sombras: Aguja Umbría, Manto del Eclipse, Marca del Vacío, Noche Absoluta.
  - Gravedad: Peso del Abismo, Pozo Gravitatorio, Colapso Astral.
  - Debilitamiento: cinco hechizos.
- **Sistema:**
  - preparación interrumpible;
  - estados nuevos (Lento, Prisión, Defensa ↓, Resistencia ↓, Ataque ↓, Marca, Maldición y Vulnerable);
  - tabla de afinidades con «Débil», «Resiste» e «Inmune», y jefes inmunes a la Prisión;
  - pestaña «Magia negra» por páginas, legible en el móvil;
  - investigación del taller arcano conectada a `investigacion.gd` (en borrador).
- **Sonidos propios:** 20 OGG de capas Sonniss, con licencia comprobada. Medidos, **no escuchados**.
- **Pendiente:**
  - las mejoras de cada hechizo (anotadas, no implementadas);
  - el taller arcano visible;
  - que los enemigos lancen magia negra;
  - decidir si la tabla de afinidades vale también para las 12 magias de siempre (cambia el equilibrio).

## 5. Pruebas

- Una batería completa tras cada integración, siempre con 0 fallidas. La última está en el §8.
- **Pruebas nuevas de la fase:** `prueba_magia_negra`, `prueba_audio_magia_negra`, `prueba_grupo_reserva`,
  `prueba_naira_combate`, `prueba_naira_mision`, `prueba_heroes_v2`, `prueba_enemigos_v12`,
  `prueba_garganta3d_examinables`, `prueba_oakhaven3d_completo` y `prueba_gran_bosque3d`.
- **Regresión encontrada y corregida:** la clave de sonido `naira_eclipse` no existía.

## 6. Rendimiento

- **Solo hay medidas en el PC**, que no valen para Android. Llamadas de dibujo en el PC:
  - Oakhaven, toda la ciudad en medio: 237 → 282;
  - Gran Bosque: bajo 48-102 y medio 91-176;
  - Garganta: se redujo el pomo de la palanca de 4 224 a 144 triángulos.
- **Pendiente en el Redmi:**
  - los FPS de las tres regiones nuevas en bajo y medio;
  - los combates con los enemigos v12 (ventanas 3D grandes);
  - Naira y el observatorio;
  - los héroes v2;
  - la memoria.

## 7. Siguiente fase, por prioridad

1. **Redmi**, con la APK de Auditoría de esta fase: medir las tres regiones, escuchar el sonido y comparar lo apagado.
2. **Decisiones del usuario:**
   - Naira (canon y concepto);
   - Bramavidrio v2 o v3;
   - los enemigos v12;
   - los héroes v2;
   - las afinidades de las magias de siempre;
   - las 10 de `NAIRA.md` §7.
3. **Migración:** las Cumbres de Ciclópea y el Valle de los Ecos (L); el resto del Mar de Cristal; la Arboleda.
4. **Enemigos:**
   - encuentros por región;
   - Vidracrán, Tolvanera y Cencerrante en combate;
   - mecánicas de veneno, protector e invocador;
   - sonidos.
5. **Naira definitiva** con la calidad de los héroes: manos, cara, telas y unos 10 000 triángulos.
6. **Magia negra:** las mejoras de cada hechizo, el taller arcano visible y los dúos Vigilia y Doble Fondo.

## 8. Batería final (04:22) y APK

- **Batería completa con todo integrado:** 129 superadas · **1 fallida** · 58 manuales · 0 no seguras. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-12_042234\resumen.md`.
- **La fallida, `prueba_equilibrio`, era una prueba inestable** y no la causa ningún cambio de esta fase:
  - pone `seed(7)`, pero el combate hace `randomize()` al empezar, así que su media aleatoria cambiaba en cada pasada;
  - salía 2 de cada 3 veces;
  - **arreglo:** se le pasa `semilla=7` al combate (`lista_pruebas.txt`);
  - **resultado:** 3 de 3 pasadas superadas, así que la batería queda en **130 · 0 · 58 · 0**.
