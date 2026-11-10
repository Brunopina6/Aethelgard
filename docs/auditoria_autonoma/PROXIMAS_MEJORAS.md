# PRÓXIMAS MEJORAS RECOMENDADAS — REBELUM (10/11/2026)

Escrito tras fusionar la auditoría autónoma en `integracion-experimental` (`218155a`). Es un plan: **nada de esto está
hecho**. Cada punto dice qué se gana, cómo hacerlo sin romper nada, cómo se demuestra y qué necesita tu aprobación.

## Orden recomendado

| # | Mejora | Por qué primero | Necesita |
|---|---|---|---|
| 1 | Carga inicial por zonas | El arranque tarda 22-25 s (61 s la primera vez) y retiene 277 MB todo el juego | Medir en el Redmi antes y después |
| 2 | Tope de FPS coherente en la Garganta 3D | Va a 60 en perfil bajo: más batería y calor | Integrar `area-rendimiento` |
| 3 | Combate modular, paso a paso | `combate.gd` tiene 4594 líneas: cada cambio es arriesgado | Nada nuevo: la huella lo vigila |
| 4 | Datos de combate en recursos | Base para talleres, investigaciones y equilibrio | Nada nuevo: comparación campo a campo |
| 5 | Talleres e investigaciones | Progresión nueva | **Tu aprobación del diseño** (es mecánica nueva) |

## 1. Optimización de la carga inicial

**Hoy (medido):** la pantalla de carga precarga 760 archivos (679 en la APK), 277 MB importados, y los deja en memoria
toda la partida. En el Redmi, 12,7 s de esa precarga; arranque total 22-25 s, 61 s el primero (compila sombreadores).

**Pasos, de menos a más riesgo:**
1. **Quitar de la precarga lo que nunca va en la APK** (`vegetacion_prueba/`, 42 archivos, 30 MB). Solo acelera el PC,
   porque en la APK ya no está, pero el riesgo es nulo.
2. **Música de combate al empezar el combate**, no al arrancar (6,6 MB; ya aprobado el 09/11, en `area-sonido`).
3. **Precarga por zonas:** cada región precarga lo suyo (`zonas3d/<zona>`, `ciudades/<ciudad>`, sus bucles de audio)
   detrás del fundido a negro al entrar, con `Recursos.cambiar_escena`, que ya carga en segundo plano; y lo libera
   al salir con `Recursos.liberar_grupo("<zona>")`. Lo común (personajes, combate, interfaz) sigue al arrancar.
4. **Sombreadores:** precalentar en la pantalla de carga solo los de la primera escena y los demás al entrar en cada
   zona, para que el primer arranque no tarde 61 s seguidos.

**Cómo se demuestra:** `pruebas/medir_precarga.gd` en el PC, y en el Redmi el tiempo hasta «TOCA PARA EMPEZAR», la
memoria (`dumpsys meminfo`) y los tirones al entrar por primera vez en cada zona (SurfaceFlinger, p95 y fotograma
máximo). **Se acepta solo si** el arranque baja, la memoria baja y no aparecen tirones nuevos (la precarga existe para
evitarlos, T-023).

## 2. Tope de FPS coherente

La Garganta 3D va a 60 FPS en perfil bajo, cuando el perfil bajo debería ir a 30 como Pastos Verdes. Lo tiene la rama
`area-rendimiento` (`d8d2834`, sin integrar). Paso: revisarla, integrarla y medir en el Redmi. Sin cambios visuales.

## 3. Modularización del combate

**Hecho:** `combate_formulas.gd` (daño físico y mágico), con la huella idéntica (`725aef4a…`, 9 de 9).

**Regla:** un módulo cada vez, con funciones estáticas que reciben lo que necesitan; la huella
(`prueba_combate_huella`) y los invariantes (`prueba_combate_seguro`, cinco semillas) antes y después. Si la huella
cambia, se deshace.

**Orden propuesto:**
1. **Recompensas** (líneas ~4440-4594: experiencia, oro, botín, subida de nivel) → `combate_recompensas.gd`. Es lo que
   usarán los talleres, así que conviene tenerlo aislado y probado primero.
2. **IA de los enemigos normales** (`_turno_enemigo` y patrones) → `combate_ia.gd`. Los jefes, después y aparte.
3. **Datos** (`ENEMIGOS`, `NIVELES_MAGIA`, `EMBUIR`) → punto 4.
4. **Presentación** (HUD, animaciones, efectos de magia): la última, porque toca lo visual y necesita capturas.

**Coordinación:** `area-combate` tiene trabajo sin integrar (`ac3b889`). Hay que integrarlo antes de mover código de
`combate.gd`, o los cambios chocarán.

## 4. Datos independientes

Una carpeta `datos/` con un recurso por tipo (enemigos, magias, armas, accesorios, materiales) y un cargador que
devuelva **los mismos diccionarios** que hoy, para no cambiar ningún llamador. Se pasa una tabla cada vez, con una
prueba que compare la tabla vieja y la nueva campo a campo; si difieren en algo, no se activa. Primero los
**materiales** (hoy solo existe el botín de las bestias, como la Corteza espinosa de Zarzalín), porque son la base de
los talleres.

## 5. Talleres e investigaciones (preparación, sin mecánicas hasta que las apruebes)

Esto es **mecánica nueva**: necesita tu diseño o tu aprobación antes de que llegue al juego. Lo que sí se puede dejar
preparado sin cambiar nada de lo que se juega:

**Talleres (Lya, Kael y Garon):**
- Recurso `Receta`: id, taller, materiales, coste, resultado.
- `Taller`: `puede(receta, partida)` (devuelve el motivo si no se puede) y `aplicar(receta, partida)`.
- Lo hecho se guarda por id en la partida. El formato ya está versionado (`progreso.FORMATO = 2`), así que una partida
  antigua carga con el taller vacío.
- Pruebas: no gastar materiales si falla, no dar dos veces, y las partidas antiguas cargan igual.

**Investigaciones:**
- Propuesta para que la valores: un progreso por id («investigar» un material, una bestia o un tomo) que se alimenta
  de lo que ya existe: botín de combate, hallazgos (`hallazgos.gd`, ya apuntados por id en `cofres_abiertos`) y
  detalles examinados. Al completarse, desbloquea recetas del taller.
- Mismo contrato que los talleres: datos en recursos, avance guardado por id y comprobado con pruebas.
- Hace falta decidir contigo qué se investiga, quién investiga, qué desbloquea y dónde se ve en el menú.

**Antes de empezar:** el módulo de recompensas (punto 3.1) y los datos de materiales (punto 4), para que talleres e
investigaciones se enganchen a algo estable.

## Lo que no hay que olvidar

- **Ramas de especialistas sin integrar:** animaciones `625abfb`, combate `ac3b889`, narrativa `82cf257`, Oakhaven 3D
  `ec939e3`, rendimiento `d8d2834`, Garganta 3D `9513b4c`, sonido `4f917e5`; interfaz y controles, a medias.
  Conviene integrarlas antes de las mejoras 1 a 4, que tocan los mismos archivos.
- **Pendiente en el Redmi:** volver a medir la Garganta 3D con esta compilación, tocar el sensor de huellas durante la
  partida, un mando y un teclado reales, y el sonido y la temperatura en sesiones largas.
- **Tres pruebas desfasadas** que reescribir: `prueba_toque`, `prueba_dialogo` y `prueba_menu_nuevo`.
