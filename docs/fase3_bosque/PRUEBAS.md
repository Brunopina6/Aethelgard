# PRUEBAS — Fase 3, «El bosque que no recuerda» (10/11/2026)

**Cómo se ejecutaron:**
- con `aethelgard/pruebas/ejecutar_pruebas.ps1`, desde PowerShell, sin ventana y con `--fixed-fps 30`;
- con datos aislados;
- en todas las pasadas, «partida.save real: sin cambios · carpeta real de datos: sin cambios».
- **El Redmi no estaba:** nada se ha probado en Android (`PENDIENTES_REDMI.md`).

## Batería completa (`ci_local.ps1`: importación aislada y todas las pruebas)

| Hora | Commit | Superadas | Fallidas | Manuales | No seguras | Notas |
|---|---|---|---|---|---|---|
| 15:37 | `a6276d0` (aventura y alquimia) | 86 | **4** | 41 | 0 | `prueba_ruta_alpha` y `prueba_centinela` esperaban el final de Tilo de antes de la aventura; `prueba_equipo` y `prueba_hallazgos` contaban los accesorios de antes. Actualizadas (`f4cb14f`) |
| 15:53 | `db65947` | 91 | 0 | 41 | 0 | |
| 16:07 | `529dcd1` (con el modelo 3D) | **92** | **0** | 42 | 0 | resumen `D:\REBELUM_diagnostico\pruebas\2026-11-10_160727\resumen.md` |

## Pruebas nuevas de la fase 3 (automáticas)

| Prueba | Qué comprueba | Pedido de la orden |
|---|---|---|
| `prueba_bosque_pastos` | Jugado en la región de verdad, colocando a Kael junto a cada cosa y pulsando el botón: Tilo inicia; el árbol; las tres pistas en sitios distintos y el contador; las ramas no se abren sin la pista y con Garon sí; los 9 materiales una vez; manantial (una vez); cofre (una vez); la alquimia en su pantalla (estudiar, fabricar Esencia y Poción, investigar y completar «La savia que recuerda», fabricar el Elixir, las tres pestañas); el Guardián y su combate fijo; lo que se guarda; y tras purificar, la región recargada con el claro en flor, el diálogo final, Tilo y el objetivo | 1, 2, 3, 4, 5, 6, 7, 14, 16 |
| `prueba_guardian_bosque` | Combates de verdad: fase 1 → fase 2 (coraza: físico a la mitad, fuego ×1,5), victoria «derrotado» con su premio; repetir no lo duplica; el Elixir no se gasta en la fase 1 y purifica en la 2 con su premio; la Esencia de enfoque (×1,3 a la magia, 3 turnos) y la ventaja de Lya | 8, 9, 10, 11, 12, 13, 14, 17 |
| `prueba_guardian_modelo` | El modelo 3D: 8 clips, ≤ 12 000 triángulos, huesos, guion | — |
| `prueba_dialogos_bosque` | 15 diálogos registrados y recorridos con Dialogic; quién habla; longitud; nada de Érebo, recuerdos ni Final Fantasy X; textos de los avisos | narrativa |
| `prueba_tienda_bosque` | Hierbas de Encina en la tienda de Oakhaven según el desenlace; solo allí; sin dinero gratis | 15 |
| `prueba_datos` (fase 2, con los datos nuevos) | Materiales, recetas e investigaciones reales sin errores | — |
| `prueba_ciudad_datos` | Los diálogos de Encina enganchados en Oakhaven | 15 |
| `prueba_combate_huella` y `prueba_combate_seguro` | El combate normal da exactamente lo mismo (huella `725aef4a…`, 9 de 9) y no se rompe | 18 |

## Manuales y capturas (con ventana, para revisar a ojo; no cuentan como superadas)

- **`fotos_bosque.gd`:**
  - la región con los objetos de la aventura, el Guardián dormido y la pantalla de alquimia;
  - capturas: `D:\REBELUM_diagnostico\fase3\fotos_160649\`.
- **`fotos_guardian_combate.gd`:**
  - el combate contra el Guardián (inicio, fase 1, cambio de fase y fase 2);
  - capturas: `D:\REBELUM_diagnostico\fase3\combate_guardian_160526\`.
- **`prueba_guardian_fotos`** (animaciones): los clips en un combate.

## Lo que requiere una persona jugando (pendiente)

Todo lo de `PENDIENTES_REDMI.md`:
- el recorrido con toques;
- la alquimia en pantalla pequeña;
- el combate con sus avisos y las dos resoluciones;
- cerrar y reabrir la app;
- los FPS y los registros en el Redmi.

En el PC tampoco se ha jugado entero a mano: lo comprueban las pruebas automáticas, que pulsan los mismos botones.
