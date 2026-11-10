# La forja de Kael (V10)

Rama LOCAL `claude/rebelum-v10` (`D:\Aethelgard_v10`).
- Commits: `f2a960b` (sistemas), `db043de` (Maese Ferro, de narrativa), `580b40e` y `d61cdeb` (arreglos y veta).
- Comprobado ejecutando, aislado, el 10/11/2026.

## Cómo se juega

1. **Maese Ferro** está en la herrería de Oakhaven 2D (casilla 70.5, 26, al final de la Calle del Mercado). Al acabar
   su diálogo se abre **la forja de Kael** (`servicios.gd` → `alquimia_menu.gd`, taller `forja`).
2. **Investigación «Acero de la Falla»** (`kael_forja_falla`): pide tener 1 Hierro de la Falla.
3. **Receta «Frostfang templada en la Falla»** (`frostfang_falla`), una sola vez:
   - gasta Hierro de la Falla ×1 y Musgo de piedra ×1;
   - da **Frostfang +4 de ataque, para siempre**.
4. La mejora va **en esa pieza**, no en un segundo inventario (`inventario.mejoras_objeto["frostfang"]`). Al equiparla
   se ve el nombre «Frostfang +» y el ataque sumado (`inventario.gd`, `con_mejoras`).

## El Hierro de la Falla

- Es un material nuevo (`datos/materiales/hierro_falla.tres`, venta 30).
- Sale de **una veta** en la Garganta 3D, junto al pilar del peregrino, solo tras la pista de Garon (encargo A).
- Picarla da 1 hierro y el hito `enc_herrero_veta`. Con Lya y Garon en el grupo, lo comentan (`gg_veta`).
- Lo que pasa después depende de la decisión del encargo:
  - si se entrega a Ferro (`entregado`), **Ferro lo vende a 45** monedas en su tienda;
  - si Kael se lo queda (`kael`), no hay más hierro: hay que elegir entre la Frostfang y la cota reforzada de Hilda.

## Estado

| Parte | Estado |
|---|---|
| Servicio de Ferro (la forja al acabar el diálogo) | implementado y probado (`prueba_oakhaven_v10`, `prueba_oakhaven`) |
| Investigación, receta y mejora por pieza, una sola vez | implementado y probado (`prueba_oakhaven_v10`, `prueba_oficios`) |
| Veta en la Garganta 3D y `gg_veta` | implementado y probado (`prueba_veta_garganta`) |
| Hierro a la venta tras entregarlo | implementado y probado (`prueba_oakhaven_v10`) |
| Lectura en el móvil (botones y textos) | pendiente de validación manual en el Redmi |
| Ferro en el distrito 3D | ver `OAKHAVEN_CIUDAD_VIVA.md` |

Las magias, el ATB y las fórmulas de combate no cambian. La mejora suma al `ataque` del arma, como cualquier arma mejor.
