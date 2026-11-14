# Orbe experimental de Érebo (V12, 14/11/2026) — fase 3A del encargo coordinador

**Qué es:** el efecto nativo del laboratorio (`D:\REBELUM_laboratorio_plugins\laboratorio\proto_a_pixelpart`), hecho
con partículas propias y sin complementos, llevado a la invocación de Érebo como **opción experimental APAGADA por
defecto**.

**Cómo se ve:** en el instante en que Érebo agarra y saca el orbe, la energía violeta, negra y plateada gira en espiral
y se absorbe en él. Al llegar, el orbe responde con una onda mágica y una ráfaga de chispas plateadas. Dura
aproximadamente 1,1 s y se borra solo.

## Dónde está

| Archivo | Qué hace |
|---|---|
| `aethelgard/erebo_orbe_v12.gd` (nuevo) | El efecto: 3 espirales, una ráfaga y una onda de un solo quad. Contiene `activo()`, `elegir()`, `apagar()` y `quitar()` |
| `aethelgard/erebo_3d.gd` | Enganche mínimo: `_orbe_v12_evento` lo crea en el evento de animación **«orbe_fuera»** y lo quita en «estalla», «vacia», «se_hunde» y «desaparece», y en `limpiar()` (saltar o cancelar). Como es hijo de Érebo, también se va al salir del árbol (morir o cambiar de escena) |
| `aethelgard/menus.gd` | Ajustes → «Érebo: orbe experimental» No/Sí. **Solo en la APK de Auditoría o en el editor**. Clave `[calidad_pruebas] erebo_orbe_v12` de `user://ajustes.cfg` |
| `pruebas/prueba_erebo_orbe_v12.gd` y `_nueva.gd` | Pruebas automáticas con las dos invocaciones |
| `pruebas/fotos_erebo_orbe_v12.gd` | Comparación apagado/encendido en el mismo combate: capturas y medidas |

## Lo que no cambia

- **La invocación original queda íntegra.** Con la opción apagada, o con el argumento `erebo_orbe_no`, es exactamente
  la de siempre.
- No cambian el daño, los costes, el dado ni los tiempos. Tampoco el material del orbe.
- Funciona igual con las dos invocaciones (la de siempre y «Ladrón de Corazones»), porque las dos emiten
  «orbe_fuera» en el agarre.
- **Solo Lya invoca:** queda para la fase 3B. Este cambio no toca quién puede invocar.

## Presupuesto

- 96 partículas en calidad «alta» y 48 en «movil». La onda es un solo quad aditivo. Sin luces nuevas.
- Con «reducir destellos» solo queda la espiral: ni onda ni ráfaga.

## Pruebas (14/11)

**`prueba_erebo_orbe_v12` y `prueba_erebo_orbe_v12_nueva`:** SUPERADAS, 7 casos cada una, 0 fallos y 0 avisos de
Godot.

| Caso | Qué se comprueba | Resultado |
|---|---|---|
| apagado | no se crea nada | correcto |
| encendido | nace en «orbe_fuera», sobre el orbe, con 96 partículas; la onda se lanza; se borra solo | correcto |
| reglas | el resultado es idéntico con la opción apagada y encendida | idéntico |
| saltar | al saltar con el efecto vivo no queda nada | 0 restos |
| repetir | tres invocaciones seguidas | como máximo 1 a la vez y 0 al final |
| salir | al borrar el combate (cambio de escena) | 0 restos |
| tiempo | `time_scale` vuelve a 1 | correcto |

**`fotos_erebo_orbe_v12`** (ventana, RTX 3050, Compatibility). **Son medidas de PC, NO de Android.**

- **Capturas:** `D:\REBELUM_diagnostico\pruebas\2026-11-14_011844\fotos_erebo_orbe_v12\` (+0,15, +0,45 y +0,8 s del
  agarre).
- La espiral se lee alrededor del orbe y no tapa a los protagonistas, las barras ni los textos.

| Medida (1,2 s desde el agarre) | Apagado | Encendido |
|---|---|---|
| Fotograma medio | 5,26 ms | 5,41 ms (+0,15) |
| p95 | 6,98 ms | 6,99 ms |
| Máximo | 7,65 ms | 7,02 ms |
| Fotograma del agarre | 4,32 ms | 4,55 ms |
| Llamadas de dibujo (media) | 90,8 | 94,7 (+4) |

## Pendiente

- **Medir en el Redmi**, en la APK de Auditoría con la opción en «Sí»:
  - la compilación de los sombreadores en frío (en el PC, unos 2 s con la caché vacía, según el laboratorio);
  - el coste por píxel de las partículas aditivas en la Mali-G57.
- **Fase 3B:** solo Lya invoca.
- **Fase 3C:** mejorar una magia representativa.
