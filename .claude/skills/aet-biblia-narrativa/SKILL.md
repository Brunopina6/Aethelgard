---
name: aet-biblia-narrativa
description: Biblia narrativa y escritura emocional de Aethelgard (mundo, cronología, personajes, arcos, diálogos y misiones) como material en desarrollo, sin canon hasta aprobación.
---

# aet-biblia-narrativa — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía original. Personajes existentes que se respetan con sus rasgos y habilidades:
**Kael** (protagonista), **Lya** (maga, invoca a Érebo), **Garon «El Muro»** (dos espadas, Esgrima y Embuir) y
**Érebo** (invocación «Ladrón de Corazones»). Enemigos y jefes existentes: Grimfang, Gorthor el Devorador (decisión
perdonar/acabar guardada en Progreso). Ya hay lore en el juego (`progreso.gd`, diálogos de Dialogic en
`dialogos/`). Referencias de **emoción y ritmo**, no de contenido: FFIX (ternura, crecimiento, humor),
Clair Obscur (puesta en escena). Nada de copiar nombres, tramas, frases ni personajes de otras obras.

## Reglas
- Todo lo nuevo es **material en desarrollo** hasta que el autor lo apruebe; se marca «PROPUESTA» en el documento.
- Nunca cambiar diálogos, nombres, misiones ni datos del juego sin aprobación; la biblia vive en `docs/biblia/`.
- Leer primero el material del autor (por ejemplo, su guion o conversación de trabajo) y citarlo como fuente.

## Procedimiento
1. **Inventario**: qué existe ya en el juego (diálogos, lore, decisiones) y en los documentos del autor.
2. **Biblia** en `docs/biblia/`: mundo y cronología; reinos, dioses y mitología; personajes y relaciones; arcos
   emocionales; secretos y revelaciones con su «semilla» temprana; temas musicales y momentos clave.
3. **Arcos emocionales** por personaje: herida, deseo, miedo, cambio; un momento de alegría, uno de humor, uno de
   tristeza y uno de esperanza por capítulo.
4. **Diálogos**: frases cortas (pantalla de móvil), voz distinta por personaje, subtexto; probar leyéndolos en voz
   alta; máximo ~3 líneas por globo.
5. **Misiones secundarias** que cuenten algo del mundo y usen lugares de `aet-diseno-exploracion`.
6. **Coherencia**: cada revelación necesita al menos dos pistas anteriores; tabla de semillas → pagos.

## Ejemplos para Aethelgard (PROPUESTA)
- Érebo como invocación que «roba corazones»: posible conflicto moral con la ternura de Lya.
- La decisión sobre Gorthor ya existe: puede volver más adelante (gratitud o venganza).

## Herramientas
- Solo texto (Markdown) y Dialogic ya instalado para integrar cuando se apruebe.

## Riesgos
- Contradecir lo ya implementado (comprobar con `grep` en `dialogos/` y `progreso.gd`).
- Textos largos ilegibles en Android: limitar longitud y probar en el Redmi.

## Cómo medir y aceptar
- El autor aprueba cada bloque; tabla de semillas → pagos sin huecos; diálogos que caben en pantalla.

## Reversión
- La biblia es documentación en Git: cada versión en un commit; nada entra en el juego sin aprobación.

## Formato de respuesta
**Fuentes leídas → Propuesta (marcada) → Dudas para el autor → Aprobación**. En español.
