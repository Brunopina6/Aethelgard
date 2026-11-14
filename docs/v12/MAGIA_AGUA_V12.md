# Magia Agua v12 (V12, 14/11/2026) — fase 3C del encargo coordinador

**Encargo (sección 4, última línea):** «mejora una magia representativa, conservando identidad elemental, legibilidad y
sincronización. No amplíes el lote hasta comprobarla.» Elegida **AGUA** (Agua, Torrente y Maremoto): la magia elemental
de Lya, que conserva la magia.

**Estado:** EXPERIMENTAL y **APAGADA por defecto**. Comprobada en PC (pruebas aisladas y capturas en ventana).
**Pendiente: verla en el Redmi** (APK de Auditoría, Ajustes → «Magia Agua v12: Sí»).

## Qué cambia (solo presentación)

| Momento | Antes (apagada) | Ahora (encendida) |
|---|---|---|
| Anticipación (carga) | Círculo mágico y halo en la mano | Además: ondas que se **cierran** hacia los pies (el agua acude a Lya) y tres corrientes de agua que suben en espiral hasta la punta del cetro, con gotas. Sigue al círculo (aparece y se apaga con él). Al soltar la magia, se recogen en la mano y salpican |
| Vuelo (Agua y Torrente) | Bola de luz azul con estela | Un **orbe de agua** con volumen (más claro arriba, borde brillante) que tiembla, se estira en la dirección del vuelo y deja gotas; el brillo de siempre queda debajo, más suave |
| Impacto | Fogonazo azul de toda la pantalla, globo de luz, 3 aros, géiser 3D, espiral de burbujas, salpicadura a los 0,7 s y vapor | Fogonazo más suave (0,10 en vez de 0,22; ninguno con «reducir destellos»), **aro de salpicadura**, **membrana de agua** que envuelve al enemigo, tiembla y **revienta a los 0,66 s** (Agua y Torrente), **gotas con gravedad que salpican al tocar el suelo**, bruma, **aro de espuma** y un **charco que se seca** (disipación). Se conservan el géiser 3D, la espiral y la salpicadura final (con menos partículas) |
| Maremoto | 6 manchas de luz + espuma: en el impacto, un resplandor blanco que tapaba a todos | La **ola tiene cuerpo**: agua translúcida con degradado, cara iluminada, **cresta de espuma**, rizo que cabecea, cortina que cae y rompiente; deja un **rastro de espuma** que se seca. Las manchas de luz quedan al 30 %. Los impactos de Maremoto no llevan membrana (manda la ola) |

**Identidad:** agua, no hielo: azules hondos y saturados con espuma blanca, formas redondas que tiemblan, caen con
gravedad y salpican; nada de aristas ni de cian pálido quieto.

**Legibilidad:** todo se dibuja en la escena del combate, **por debajo** de la capa de números, barras y avisos. La ola
es translúcida y pasa en unos 0,4 s por cada sitio; con ella encendida se ve a los personajes en el impacto de Maremoto,
que antes quedaba tapado por un resplandor blanco (comparativa abajo). En Torrente, cada impacto lleva menos (membrana
más pequeña, menos gotas).

**Sincronización:** la pieza de impacto nace en el **mismo fotograma** en que baja la vida de su enemigo (combate.gd:
`_quitar_pv` → `_golpe_visual` → `_efecto_agua`), uno por enemigo golpeado (Torrente: los tres a la vez; Maremoto:
cuando la cresta pasa por cada uno). Las 12 magias de siempre **no tienen sonido** (sonido.gd: «no suenan»): si un día
lo tienen, su sitio es ese mismo `impacto.call()`.

## Dónde está

| Archivo | Qué hace |
|---|---|
| `aethelgard/vfx/agua_v12.gd` (nuevo) | Todo el efecto: `activo()`, `elegir()`, `permitido()`, `reducir_destellos()`, `vivos()` y los ganchos `carga()`, `proyectil()`, `impacto()` y `ola()`. Cada pieza es un `Node2D` que se dibuja a mano y se borra sola |
| `aethelgard/combate.gd` | **7 líneas**: el `preload` y un gancho de una línea en `_carga_magia`, `_proyectil` y `_maremoto` (solo si la magia es Agua y la opción está encendida), y tres líneas al principio de `_efecto_agua` (si está encendida, el impacto nuevo y `return`) |
| `aethelgard/menus.gd` | Ajustes → «Magia Agua v12» No/Sí, en el bloque de pruebas junto a «Érebo: orbe experimental». **Solo en la APK de Auditoría o en el editor**. Clave `[calidad_pruebas] magia_agua_v12` de `user://ajustes.cfg` |
| `pruebas/prueba_magia_agua_v12.gd` | Prueba automática (abajo) |
| `pruebas/fotos_magia_agua_v12.gd` | Comparación apagada/encendida en el mismo combate y fotograma, con medidas |

En pruebas se puede forzar con el argumento `agua_v12` (encendida) o `agua_v12_no` (apagada).

## Lo que no cambia

- **Con la opción apagada, la magia es exactamente la de siempre:** los ganchos ni se crean (comprobado: 0 piezas en
  Agua, Torrente y Maremoto).
- No cambian daño, costes, tiempos de reglas ni el orden del combate.
- **El azar tampoco.** Cada `CPUParticles2D` que se crea toma una tirada del azar global (ya visto en
  `combate_anim_v12.gd`, `_chispas`), y en Torrente el daño del segundo y el tercer enemigo se tira después del efecto
  del primero. Por eso el impacto nuevo **conserva las mismas llamadas que crean partículas** (géiser 3D o chorro 2D,
  espiral y, a los 0,7 s, la salpicadura y el vapor), en el mismo orden y momento; solo cambia cuántas partículas sueltan
  (eso no toma tiradas). Lo nuevo se dibuja con valores fijos. La prueba lo comprueba con el daño a cada enemigo, los
  fotogramas de cada golpe y la **tirada siguiente** del azar, idénticos apagada y encendida.

## Presupuesto

- Dos texturas pequeñas (gota de 32 px y aro de 64 px), creadas una vez por combate y guardadas en él (se van con él).
- Gotas, aros, charco y espuma son rectángulos **sin girar** de la misma textura, para que se agrupen en pocas llamadas
  de dibujo; solo la membrana, el orbe, las corrientes y la ola usan polígonos o líneas.
- Sin luces nuevas, sin 3D, sin sombreadores, sin resplandor. Móvil (`CALIDAD_MOVIL`): todas las cantidades se
  multiplican por la calidad del combate (0,4); la prueba lo comprueba (≤ 12 gotas por impacto).
- «Reducir destellos» (argumento `reducir_destellos` o `Engine.set_meta("reducir_destellos", true)`; hoy el juego no
  tiene ese ajuste en el combate): sin fogonazo y con los brillos a la mitad.

## Limpieza

Cada pieza se borra sola al acabar su vida (impacto 1,5 s, charco 2,1 s, carga cuando se suelta o desaparece el círculo,
ola y rastro al acabar la ola). Cuelgan de la escena del combate, de su capa de sombras, de la bola o de la ola. El único
temporizador es el de siempre (0,7 s) y lleva una referencia débil al combate: si el combate ya no está, no hace nada y no
da error. Comprobado: repetir ×3 no acumula nodos y borrar el combate a mitad del impacto no deja nada.

## Pruebas (14/11, PC, datos aislados)

| Prueba | Resultado | Resumen |
|---|---|---|
| `prueba_magia_agua_v12` (nueva) | **SUPERADA** | `D:\REBELUM_diagnostico\v12\magia_agua\pruebas\2026-11-14_023027\resumen.md` |
| `fotos_magia_agua_v12` (nueva, ventana) | MANUAL (capturas revisadas) | `D:\REBELUM_diagnostico\v12\magia_agua\pruebas\2026-11-14_022849\` |

Pasada final `2026-11-14_023027` (13 pruebas, **13 SUPERADAS · 0 FALLIDAS**, partida real y carpeta real de datos sin
cambios; el ejecutor marca «proyecto cambiado» porque este documento se escribió durante la pasada): las nuevas y las
de combate y magia que ya había — `prueba_grupos_combate`, `prueba_efectos`, `prueba_menu_magia`,
`prueba_combate_huella` (huella C0 con semilla fija: igual, la opción va apagada por defecto), `prueba_artes_combate`,
`prueba_hud_combate`, `prueba_combate_seguro`, `prueba_v11_combate`, `prueba_magia_negra`, `prueba_combate_anim_v12`,
`prueba_calidad_pruebas` y `prueba_erebo_orbe_v12`. Sin «SCRIPT ERROR» ni errores del efecto en los registros (solo los
avisos de recursos al salir que ya dan las demás pruebas).

Qué comprueba `prueba_magia_agua_v12` (grupo 2: tres enemigos con PV de sobra que no actúan; semilla fija):

- La opción solo existe en Auditoría o editor; `elegir()` la guarda en `[calidad_pruebas]` y `activo()` la lee.
- Apagada: ninguna pieza nueva en Agua, Torrente y Maremoto.
- Encendida: anticipación antes del golpe; orbe en el proyectil (I y II); la ola antes del primer golpe (III); en cada
  fotograma, tantas piezas de impacto nuevas como enemigos golpeados (y ninguna antes); al final, ninguna.
- Mismo daño a cada enemigo, mismos fotogramas de golpe y misma tirada siguiente apagada y encendida:
  Agua [57, 0, 0] en el fotograma 48; Torrente [87, 84, 81] en el 47; Maremoto [161, 161, 166] en el 67, 71 y 75.
- Calidad del móvil, reducir destellos, repetir ×3 (nodos de la escena iguales tras cada lanzamiento) y borrar el
  combate a mitad del impacto (nada queda y sin errores).

## Capturas antes/después (mismo combate, misma semilla, mismo fotograma)

Agua va a Grimfang (el del centro); Maremoto a los tres. Momentos: anticipación (golpe − 0,7 s), vuelo (− 0,2 s),
impacto (+ 0,07 s), impacto pleno (+ 0,33 s), disipación (+ 1,0 s) y final (+ 1,8 s).

- Hojas comparativas (izquierda apagada, derecha encendida): `D:\REBELUM_diagnostico\v12\magia_agua\comparativas\comparativa_agua.png`
  y `comparativa_maremoto.png`.
- Capturas sueltas y medidas: `D:\REBELUM_diagnostico\v12\magia_agua\capturas\` (`agua_<magia>_<apagado|encendido>_<momento>.png`).

Lo que se ve: en la anticipación, las corrientes en espiral suben hasta el cetro de Lya; el proyectil es un orbe de agua;
en el impacto, aro de salpicadura y membrana con su brillo; en la disipación, el aro de espuma y el charco. En Maremoto,
la ola tiene forma y cresta, y en el impacto los personajes se ven (apagada, el resplandor blanco los tapaba).

## Medidas de PC (NO son de Android)

RTX 3050 Laptop, Compatibility, 1280 × 720, `--fixed-fps 30`. Con otros Godot de otros especialistas en marcha a la vez,
así que los ms son orientativos; las llamadas de dibujo sí son fiables.

| Caso | ms medio (todo) | ms p95 | Llamadas de dibujo medias en el impacto | Máximas |
|---|---|---|---|---|
| Agua apagada | 19,26 | 31,93 | 95,1 | 108 |
| Agua encendida | 19,40 | 32,09 | 112,6 (+17,5) | 127 (+19) |
| Maremoto apagado | 19,58 | 31,78 | 155,5 | 171 |
| Maremoto encendido | 19,52 | 31,82 | 185,9 (+30,4) | 221 (+50) |

La primera versión giraba cada gota (`draw_set_transform`) y costaba +78/+112 llamadas máximas; con rectángulos sin
girar se quedó en +19/+50.

## Pendientes

1. **Verlo en el Redmi** (APK de Auditoría → Ajustes → «Magia Agua v12: Sí»): fluidez del impacto de Maremoto con tres
   enemigos (es el pico: +50 llamadas de dibujo en PC), lectura del orbe y de la membrana a tamaño de móvil, y que las
   corrientes de la anticipación se vean sobre fondos claros.
2. Decidir con el usuario si se queda; si se queda, el siguiente lote (Fuego/Rayo/Cura) con el mismo método. **No se ha
   ampliado el lote.**
3. El aro de salpicadura del primer instante puede leerse algo «energético»; si en el móvil molesta, bajar su brillo
   aditivo (`_dibujar_impacto`, rama `luz`).
4. Con la animación de combate v12 encendida (`combate_anim_v12`), la magia pasa por `AnimV12.magia`, que usa los mismos
   `_carga_magia` y `_proyectil`: los ganchos valen igual, pero esa combinación no tiene capturas.
