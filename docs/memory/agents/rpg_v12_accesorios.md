# Informe: diseño RPG, accesorios y equipamiento V12 (12/11/2026)

Rama local `claude/v12-accesorios` (desde `d8a65d3`), copia `D:\Aethelgard_v12_accesorios`. Sin push.

## Qué se ha hecho
1. **Diseño** en `docs/v12/ACCESORIOS_V12.md`: lo que ya existía, principios (sin ranuras nuevas, táctica antes que
   números, topes, sin Orbes), categorías encajadas en las ranuras Anillo, Amuleto y Accesorio, rarezas con color y
   precio orientativo, la primera tanda con números y comparación con los objetos de hoy y el crecimiento por nivel,
   propuestas para después (Reliquia del Confino solo como PROPUESTA narrativa, resistencias elementales y a
   estados, ahorro de PM, personales de Garon y Naira) y decisiones pendientes.
2. **Primera tanda: 11 objetos** en `equipo_extra.gd` `ACCESORIOS` (marcados `"tanda": "v12"`): Anillo de cuarzo,
   Anillo del Alba, Colgante del Eco, Talismán de Ceniza, Colgante de savia, Broche del Guardián, Brazalete del
   centinela, Velo de bruma, Brazal del último muro, Fiador de empuñadura (Kael) y Rosario del Loto (Lya). Pueden ir en
   las ranuras Anillo y Amuleto (`objeto()` respeta su «ranura»), sumar atributos (`bonus`, que `grupo.estadisticas()`
   ya suma sin tocarla) y ser de un héroe (`solo`).
3. **11 efectos nuevos** en `EFECTOS` (gancho «A1», añadido a `HECHOS`) y funciones nuevas al final de
   `equipo_extra.gd`, neutras sin el accesorio (mismo número, ningún dado). Ganchos de una o dos líneas en
   `combate.gd` (`_quitar_pv`, `_animar_golpe`, `_dano_magia`, `_aplicar_cura`, `_lanzar_cura`, `_usar_objeto`,
   `_defender`, las esporas de `_turno_guardian` y la variable `dano_magico_entrante`) y en `combate_humbaba.gd`
   (corrupción y Aliento). No se han tocado `efectos_de()` ni `grupo.estadisticas()`, ni cámara, animaciones o
   precalentado.
4. **Interruptor `accesorios_v12` (APAGADO)**: `Engine.set_meta("accesorios_v12", true)` o `-- accesorios_v12`. Sin él,
   `disponible()` los da por no disponibles y ninguna tienda los vende. Con él, **cualquier tienda** los ofrece como
   tienda de prueba, bajo el aviso «Prueba V12: accesorios nuevos (apagados en la partida normal)». Ningún precio ni
   recompensa en Orbes. Lo que ya se tiene sigue funcionando aunque se apague (no se quita equipo de una partida).
5. **Menús**: icono dibujado por código (`icono_equipo.gd`, sin texturas) y nombre en el color de su rareza en la
   tienda, la ficha del menú Grupo y la lista de equipo de Objetos; nota «Raro · Todos» / «Raro · Solo Kael» en la
   tienda. Los objetos de antes no tienen rareza y se ven igual.
6. **Pruebas**: `pruebas/prueba_accesorios_v12.gd` (nueva, al final de la lista) y `pruebas/fotos_accesorios_v12.gd`
   (capturas, ventana; no está en la lista). `prueba_equipo.gd` aplica sus invariantes de siempre solo a los
   accesorios de antes (`_base()`); `hallazgos.gd` `FUERA` explica los 11 nuevos (si no, `prueba_hallazgos` falla).

## Resultados
- Batería (ejecutar_pruebas.ps1, datos aislados): **13 SUPERADAS, 0 FALLIDAS** — prueba_accesorios_v12, prueba_equipo,
  prueba_equipo_combate, prueba_hallazgos, **prueba_combate_huella** (la huella del combate no cambia),
  prueba_controles_nuevos, prueba_m4_c2, prueba_tienda_bosque, prueba_magia_negra, prueba_humbaba_combate,
  prueba_encuentro_desierto, prueba_garon, prueba_huir. Partida real, carpeta real y proyecto: sin cambios.
  Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-12_195034\resumen.md`.
- **Comprobación de que la prueba muerde:** con cinco ganchos desactivados a propósito (Alba/Broche, Brazal/Fiador,
  Rosario, Velo y Centinela) la prueba dio 7 fallos, uno por gancho; restaurado, 0.
- Capturas en `D:\REBELUM_diagnostico\v12\expansion\accesorios\`: 01 tienda sin interruptor (como siempre), 02 y 03
  tienda de prueba, 04 ficha de Lya, 05 ficha de Garon, 06 Objetos.

## Observaciones
- Hoy los enemigos casi no hacen daño mágico a los héroes y **ninguno los quema**: el Anillo del Alba solo actúa
  contra las esporas del Guardián del Bosque y el Aliento de Humbaba, y el Talismán contra la corrupción de Humbaba.
  Por eso llevan también un atributo. Dar elemento o quemaduras a ataques enemigos es una decisión de diseño de
  enemigos (documentada como tanda 2).
- La ficha del menú Grupo ya se pasa de alto cuando muchas piezas tienen resumen (el resumen va en una línea propia):
  con tres accesorios puestos hay que desplazar para ver el último. Pasa también con objetos de antes; no lo he
  cambiado (es del menú, no de los accesorios). Propuesta: resumen a la derecha del nombre o más pequeño.
- El color «poco común» (verde) se parece al verde de los resúmenes; se lee, pero el usuario puede preferir otro.

## Para validar en el Redmi
Nada de rendimiento (no hay texturas ni modelos nuevos). Solo lectura: que iconos, colores y notas se lean a la
distancia del móvil con el interruptor encendido.

## Lo que queda
Decisiones del usuario (ACCESORIOS_V12.md §8): encenderlos y dónde se consigue cada uno, rareza de los de antes,
Reliquia del Confino, enemigos mágicos o que quemen, y una posible segunda ranura Accesorio (no recomendada).
