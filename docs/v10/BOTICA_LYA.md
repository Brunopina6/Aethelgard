# La botica de Mirta y la alquimia de Lya (V10)

Rama LOCAL `claude/rebelum-v10`.
- Commits: `f2a960b`, `db043de` y `580b40e`.
- Comprobado ejecutando, aislado, el 10/11/2026.

## Cómo se juega

1. **Mirta la Boticaria** está en la plazuela de la Botica (casilla 33.5, 41.5). Selene sigue en la puerta.
2. Al acabar su diálogo sale **«¿Qué necesitáis?»** (`servicios_botica.gd`, botones grandes; Esc cierra):
   - **Comprar ingredientes**: la tienda de siempre, solo con la pestaña Botica (Hierba lunar 15, Musgo de piedra 12,
     Savia clara 30);
   - **Alquimia de Lya**, si Lya va en el grupo y ya tiene la alquimia (`bq_alquimia`): el mismo taller de la V9;
   - **Nada, gracias**.
3. Tras el encargo B:
   - **la botica vende el Bálsamo de Mirta** (40);
   - Lya puede investigar **«La fórmula de Mirta»** (`lya_formula_mirta`), que desbloquea la receta del **Bálsamo de
     Mirta** (Hierba lunar ×2 + Savia clara ×1).
4. **El Bálsamo de Mirta**, en combate, da **+45 PV a todo el grupo** vivo (`combate.gd`, tipo `PV_TODOS`, sin elegir
   objetivo). Las magias y su comportamiento no cambian.

## Estado

| Parte | Estado |
|---|---|
| Menú de la botica, compra de ingredientes y alquimia de Lya | implementado y probado (`prueba_oakhaven_v10`) |
| Bálsamo a la venta tras el encargo B | implementado y probado (`prueba_oakhaven_v10`) |
| Bálsamo en combate (cura a todo el grupo) | observado en el código; sin prueba de combate propia |
| Lectura en el móvil | pendiente de validación manual en el Redmi |
