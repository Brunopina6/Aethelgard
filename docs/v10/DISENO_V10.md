# DISEÑO V10 — «Oakhaven, el corazón vivo del reino»: contrato técnico (10/11/2026)

Rama LOCAL `claude/rebelum-v10` (`D:\Aethelgard_v10`), desde `claude/rebelum-v9` @ `3795769`. Sin push ni fusión.

**Qué Oakhaven:**
- **2D** (`ciudad_oakhaven.gd`, datos en `ciudades/oakhaven.gd`): la que se juega por defecto. Los servicios y los
  encargos se enganchan aquí, por datos (vecinos, diálogos y señales `oak:`).
- **3D** (`zonas3d/oakhaven_3d.gd`, elegible en Ajustes): el distrito nuevo de Blender. Llama a los mismos servicios
  (`servicios.gd`).

## Personajes nuevos (propuesta, pendiente de canon)

| id (`personaje`) | Nombre | Dónde (2D) | Oficio |
|---|---|---|---|
| `ferro` | Maese Ferro | la herrería, junto al yunque | herrero: abre la **forja de Kael** |
| `hilda` | Hilda la Armera | el taller de armaduras | armera: abre las **armaduras y runas de Garon** |
| `mirta` | Mirta la Boticaria | dentro de la botica (Selene sigue en la puerta, sin tocar) | boticaria: vende ingredientes y abre la **alquimia de Lya** |

## Servicios (`servicios.gd`)

- `Servicios.abrir(padre, "forja" | "armaduras" | "botica")`:
  - la forja y las armaduras abren su taller (`alquimia_menu.gd`, con `taller` = `forja` o `armaduras`);
  - la botica pregunta «¿Qué necesitáis?»: **Comprar ingredientes** (tienda, pestaña Botica) o **Alquimia de Lya**
    (si está en el grupo).
- Las señales de diálogo `oak:servicio_forja`, `oak:servicio_armaduras` y `oak:servicio_botica` se aplican al acabar
  el diálogo, igual que «dormir».

## Mejoras por pieza (inventario, sin segundo inventario)

- Resultado de receta `pieza:<objeto>:<atributo>:<n>`. Suma a ese objeto concreto: `ataque` en un arma, o un
  atributo de `bonus` en una protección. Se ve al equiparlo; se guarda en `inventario.mejoras_objeto`.
- Resultado `runa:<objeto>:<efecto>:<v>`: un efecto de `equipo_extra.gd` EFECTOS en ese objeto.
- Cada receta se hace una vez (`hechas`).

## Materiales

- **Nuevo:** `hierro_falla`, «Hierro de la Falla». Una veta en la Garganta 3D, tras el encargo del herrero.
- **Ya existen:** Musgo de piedra, Savia clara, Hierba lunar, Corteza espinosa, Mineral rúnico (Coloso), Corazón de
  roble (Guardián derrotado).

## Investigaciones y recetas

**Forja de Kael:**
- **Investigación `kael_forja_falla`, «Acero de la Falla»:** pide Hierro de la Falla ×1 (tener).
  - **Receta `frostfang_falla`:** Hierro de la Falla ×1 + Musgo ×1 → `pieza:frostfang:ataque:4`.

**Armaduras de Garon:**
- **Investigación `garon_cota_runica`, «Malla rúnica»:** pide hito `bq_resuelto` y Musgo de piedra ×1.
  - **Receta `cota_reforzada`:** Musgo ×2 + Hierro de la Falla ×1 → `pieza:cota_malla:defensa:3`.
  - **Receta `cota_runica`:** Savia clara ×1 + Mineral rúnico ×1 → `runa:cota_malla:barrera_inicio:0.1`
    (resistencia limitada).

**Alquimia de Lya:**
- **Investigación `lya_formula_mirta`, «La fórmula de Mirta»:** pide hito `enc_formula_paginas`.
  - **Receta `balsamo_mirta`:** Hierba lunar ×2 + Savia clara ×1 → objeto «Bálsamo de Mirta» (combate: +45 PV a
    todo el grupo).

## Encargos (`datos/encargos_oakhaven.gd`, formato de encargos.gd)

**A, «El pedido de Maese Ferro»** (`enc_herrero`). Hitos:
- `enc_herrero_pedido`: Ferro pide un hierro que «canta»; habla del de la Falla.
- `enc_herrero_pista`: Garon reconoce el hierro de las inscripciones de la Garganta (diálogo o detalle).
- `enc_herrero_veta`: se coge en la Garganta 3D.
- **Decisión en la herrería**, `decisiones.hierro_ferro`:
  - `entregado`: Ferro forja para la ciudad, paga 80 monedas y vende Hierro de la Falla;
  - `kael`: Kael se queda el hierro y Ferro le enseña «Acero de la Falla».
- `enc_herrero_fin`.

**B, «La fórmula desaparecida»** (`enc_formula`). Hitos:
- `enc_formula_pedido`: Mirta perdió su cuaderno.
- `enc_formula_pip`: Pip vio volar unas páginas con el viento.
- `enc_formula_paginas`: tres páginas en Oakhaven 2D (puntos examinables).
- `enc_formula_fin`: Lya recompone la fórmula con Mirta.
- **Consecuencia:** la receta del Bálsamo y la botica lo vende.
- **Recompensa:** 2 Bálsamos y 40 monedas, una vez.

## Diálogos (narrativa; `dialogos/oakhaven/`, registrados en `project.godot`)

**Personajes y oficios:**
- `oak_ferro`: saludo y servicio. Al final, `[signal arg="oak:servicio_forja"]`.
- `oak_ferro_v` (variante con el bosque resuelto o con la técnica aprendida).
- `oak_hilda` (servicio armaduras).
- `oak_mirta` (servicio botica).

**Encargo A:**
- `oak_ferro_pedido` (empieza, con la señal `oak:herrero_pedido`);
- `oak_ferro_veta` (decide; dos señales, `oak:hierro_entregar` y `oak:hierro_kael`, en una pregunta);
- `oak_ferro_despues`.

**Encargo B:**
- `oak_mirta_pedido` (`oak:formula_pedido`);
- `oak_pip_paginas` (`oak:formula_pip`);
- `oak_mirta_formula` (`oak:formula_fin`);
- `oak_mirta_despues`.

**Pastos y Garganta:** `gg_veta` (Garganta, al coger la veta).

## Reacciones (estados persistentes ya existentes)

- Ferro y Hilda comentan si el Guardián se purificó o se derrotó.
- Ferro reconoce la técnica de Kael si ya está hecha (`hecha:frostfang_falla`).
- Pip recuerda a Canela (ya existe).
