# Registro del encargo único de implementación (rama `rebelum-alpha`)

Aquí se anotan las decisiones importantes y sus motivos, en orden.

**Lugar de trabajo:**
- Árbol de trabajo: `D:\Aethelgard_alpha`, rama `rebelum-alpha`.
- La copia del usuario (`D:\Aethelgard`, rama `rebelum-3d`) no cambia.

**Límites:**
- El Redmi, `main` y `desarollo` no se tocan.
- No hay push ni publicación.
- La partida del PC se conserva.

## Fase 0: línea base, respaldo y diagnóstico

| # | Decisión | Motivo |
|---|---|---|
| 0.1 | Árbol de trabajo separado: `D:\Aethelgard_alpha`, rama `rebelum-alpha`, que sale de `rebelum-3d` (`ce84422`) | `rebelum-3d` es `desarollo` más 9 commits de herramientas y documentos de la Fase 2.0, cada uno con sus archivos identificados y sin código del juego. Así la copia del usuario no cambia de rama |
| 0.2 | Se copia la caché `.godot` desde la copia del usuario | Evita reimportar 1,6 GB. Es una caché: no se confirma |
| 0.3 | Se recupera el cambio del reflejo del cielo, autorizado el 06/11 (commit `3a16db2`) | Estaba sin confirmar en la copia del usuario (bloque B). En `desarollo` no se confirma nada |
| 0.4 | Respaldo en `D:\REBELUM_respaldos\2026-11-07_1518_antes_encargo_unico` | Bundle de todas las ramas, parche de los cambios sin confirmar, manifiestos y copia de la partida actual, solo para leerla |
| 0.5 | `prueba_menu_magia`: **fallo previo de la prueba**, no del juego | La prueba leía `c.lista` y llamaba a `_menu_magia_nivel()`, que ya no existen: ahora el menú está en `c.menu.filas` y el nivel se pide con `_menu_magia(n)`. El error abortaba el fotograma antes de avanzar de paso, así que la prueba esperaba para siempre. El turno de Lya sí llegaba. Se actualiza la prueba y se le pone un límite de fotogramas con `FALLO` y `quit(1)` |
| 0.6 | `prueba_escenas`: **fallo previo de la prueba**, no del juego. Tenía dos causas | **Primera:** sin partida, el mapa lanza el prólogo. Con un diálogo abierto, `mapa.gd` (`_process`) no actualiza el lugar cercano, así que `_entrar()` no hacía nada. Ahora se ejecuta con `sin_prologo`, que el mapa ya admite. **Segunda:** la prueba esperaba un número fijo de fotogramas (200). Sin ventana y con `--fixed-fps`, los fotogramas pasan mucho más deprisa que el tiempo real, así que miraba la escena antes de que la zona terminara de cargarse en segundo plano. Al salir con la carga a medias aparecía un `Parse Error` en `zona.tscn`. Ahora la prueba espera a que cada cambio de escena ocurra de verdad, con un máximo de 20 s de tiempo real |
| 0.10 | **Corrección de un diagnóstico intermedio mío.** Llegué a creer que la carga en segundo plano de `zona.tscn` no terminaba nunca y cambié `recursos.gd` con un límite de tiempo. **Era falso y se ha deshecho** | Mis sondas contaban fotogramas, con el mismo error que la prueba antigua. Con la prueba nueva, que espera en tiempo real, la zona se carga en segundo plano sin usar ninguna reserva, y la prueba pasa con `recursos.gd` **original**. No hay evidencia de ningún fallo del juego en el cambio de escena, así que no se toca código que funciona |
| 0.7 | `MODO_PRUEBAS` deja de estar activo en el juego normal | Era una regla de depuración: `combate.gd:10`, `const MODO_PRUEBAS := true`, daba PM infinitos en cualquier partida. Ahora solo se activa con `-- pm_infinitos` al arrancar, y en el juego normal se pagan los PM, como ya prevé el código |
| 0.8 | Frostfang: se mantiene la congelación en cada golpe | `PROB_CONGELAR = 1.0` coincide con la regla del diario del juego («Los golpes con Frostfang congelan», `diario.gd:17`). La congelación **no bloquea turnos**: baja 16 PV máximos durante 2 rondas y los devuelve al descongelarse (`combate.gd:1323-1346`). No hay bloqueo que corregir |
| 0.9 | El ejecutor, cuando se agota el tiempo, añade la causa probable que encuentre en los registros | El cuelgue de `prueba_menu_magia` solo aparecía como «TIEMPO», aunque el registro mostraba el error que lo causaba |

### Línea base de pruebas (en el entorno aislado)

| Pasada | Superadas | Fallidas | Manuales | No seguras |
|---|---|---|---|---|
| Antes de corregir (`2026-11-07_151957`) | 15 | 2 (`escenas` y `menu_magia`, las dos de la prueba) | 10 | 0 |
| Con las correcciones de la Fase 0 (`2026-11-07_152737`) | **17** | **0** | 10 | 0 |

En todas las pasadas, `partida.save` y la carpeta real de datos se quedaron sin cambios.

### Recorrido normal del juego (verificado en el código)

1. `carga.tscn`: carga de recursos, precalentado de sombreados y «TOCA PARA EMPEZAR» (`carga.gd`).
2. `Progreso.cargar()`: va a la escena guardada o a `mapa.tscn`. La primera vez se lanza el prólogo de Dialogic (`mapa.gd:103-105`).
3. Desde el mapa: `zona.tscn` (2D, generada a partir del lugar), `garganta.tscn` (mazmorra) o `isla.tscn` (por el portal).
4. Encuentros por pasos (`progreso.gd` `prob_encuentro`): `combate.tscn` con `escena_retorno`.
5. Al terminar el combate: guardado automático y vuelta a la escena de origen (`combate.gd:3758-3764`).
6. Más guardados automáticos: al entrar en las zonas, al volver al mapa y al pausar o cerrar la app (`recursos.gd:173-178`).
