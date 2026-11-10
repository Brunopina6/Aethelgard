# El taller de armaduras de Garon (V10)

Rama LOCAL `claude/rebelum-v10`.
- Commits: `f2a960b`, `db043de` y `580b40e`.
- Comprobado ejecutando, aislado, el 10/11/2026.

## Cómo se juega

1. **Hilda la Armera** está en el puesto de armaduras, a la entrada de la Calle del Mercado (casilla 47, 25.6). Al
   acabar su diálogo se abre **el taller de armaduras de Garon** (`alquimia_menu.gd`, taller `armaduras`).
2. **Investigación «Malla rúnica»** (`garon_cota_runica`): pide el bosque resuelto (`bq_resuelto`, purificado o
   derrotado) y Musgo de piedra ×1.
3. Desbloquea dos recetas, que se hacen una vez cada una:
   - **Cota de malla reforzada** (`cota_reforzada`): Musgo ×2 + Hierro de la Falla ×1 → la cota gana **+3 de defensa**.
   - **Runa de la Falla en la cota** (`cota_runica`): Savia clara ×1 + Mineral rúnico ×1 (del Coloso) → quien lleve la
     cota **empieza cada combate con una coraza pequeña** (efecto `barrera_inicio` 0,1 de `equipo_extra.gd`).
4. Las dos mejoras van **en la pieza** (`inventario.mejoras_objeto["cota_malla"]`):
   - la defensa, en su `bonus`;
   - la runa, en sus `efectos`, que `equipo_extra.gd` suma al héroe que la lleva puesta.
5. Hace falta tener la cota para mejorarla. Si no, el taller dice «Necesitas Cota de malla».

## Reacciones

Al pasar, Hilda comenta si el bosque se purificó o si el Guardián cayó, y si Garon va en el grupo
(`ciudades/oakhaven_vida.gd`).

## Estado

| Parte | Estado |
|---|---|
| Servicio de Hilda, investigación y dos recetas por pieza | implementado y probado (`prueba_oakhaven_v10`) |
| Runa: el efecto al equipar | implementado y probado (`prueba_oakhaven_v10`, efectos de `equipo_extra.gd`) |
| Coraza al empezar el combate con la runa | observado en el código (el efecto ya existía); sin prueba de combate propia |
| Lectura en el móvil | pendiente de validación manual en el Redmi |
