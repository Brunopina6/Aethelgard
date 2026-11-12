# Informe: Firmamento de los Ecos, tablero de Orbes Cristalinos (V12, 12/11/2026)

Especialista: interfaz/progresión «orbes». Copia `D:\Aethelgard_v12_orbes`, rama local `claude/v12-orbes` (desde
`d8a65d3`). Sin push, sin merge. Diseño completo y decisiones pendientes: `docs/v12/FIRMAMENTO_DE_LOS_ECOS.md`.

**Todo va APAGADO** (interruptor `orbes_v12`). Ningún concepto está aprobado: el usuario elige.

## Qué se ha hecho

1. **Servicio** `firmamento/orbes.gd`: saldo, `ganar(cantidad, motivo)` como **única** entrada (sin ninguna fuente
   implementada), estados (bloqueado, disponible, caro, despertado, dormido), requisitos «uno» y «todos»,
   `desbloquear`, `bonos` calculados al vuelo, vista previa antes → después con las fórmulas reales, y
   `conceder_prueba` solo en Auditoría o editor.
2. **Configuración editable** `firmamento/firmamento_datos.gd` (un `.gd` y no un JSON porque los presets de Android solo
   exportan recursos): precios 1/3/6/10, 21 nodos de Kael, Lya y Garon (dos caminos desde el nodo inicial y una
   Memoria que los une), Naira con 5 nodos provisionales que solo salen con `naira_v12`. Valores calibrados con
   `grupo.gd`, `equipo_extra.gd`, `inventario.gd`, `combate.gd` y `combate_formulas.gd` (ningún nodo > ~3 niveles).
   Resistencia mágica y elemental: **dormidas** (los enemigos no lanzan magia al grupo; haría falta un gancho en
   `combate.gd`, que no se ha tocado).
3. **Pantalla** `firmamento/firmamento.gd` + `firmamento_lienzo.gd` + `pincel.gd` + `shaders/`: tablero a la
   izquierda, panel con retrato, orbes, nodo, estado con icono, bonos, vista previa, precio y requisitos; tres
   **conceptos** elegibles con el botón «Concepto» (astrolabio de latón, constelación nocturna, vidriera de geoda),
   pellizco/arrastre/rueda/gestos, teclado y mando, confirmación de gasto, animación de energía y estallido, temblor
   de error, sonidos de la biblioteca (`ui_*` y `orbe_vision`), leyenda de estados por forma y trazo.
4. **Rendimiento**: capas fija/giro/viva/luz; cada capa es **una lista de triángulos** (`pincel.gd`) → de 520-650
   llamadas de dibujo a **114** en toda la pantalla; fondo solo detrás del tablero; hash sin `sin()` en la vidriera;
   `viewport.disable_3d` mientras el tablero está abierto (tapa toda la pantalla; se devuelve al cerrar).
5. **Entrada en el juego**: ficha del Grupo → «Firmamento · N orbes» (`menus.gd`); en Auditoría/editor, Ajustes →
   «Firmamento de los Ecos (prueba)» para encenderlo en el teléfono. Prototipo navegable para el editor:
   `firmamento/firmamento_demo.tscn` (F6).
6. **Pruebas**: `prueba_firmamento` (auto) y `fotos_firmamento` (capturas y medidas).

## Commits

- `8e94517` V12, Firmamento de los Ecos (PROTOTIPO APAGADO…): sistema, tablero, tres conceptos, pruebas.
- `c74f581` encuadre, Naira en la prueba, leyenda con el color del héroe, documento de diseño e informe.

## Archivos

NUEVOS:
- `aethelgard/firmamento/orbes.gd`
- `aethelgard/firmamento/firmamento_datos.gd`
- `aethelgard/firmamento/firmamento.gd`
- `aethelgard/firmamento/firmamento_lienzo.gd`
- `aethelgard/firmamento/pincel.gd`
- `aethelgard/firmamento/firmamento_demo.gd`, `aethelgard/firmamento/firmamento_demo.tscn`
- `aethelgard/firmamento/shaders/fondo_astrolabio.gdshader`, `fondo_constelacion.gdshader`, `fondo_vidriera.gdshader`
- `aethelgard/pruebas/prueba_firmamento.gd`, `aethelgard/pruebas/fotos_firmamento.gd`
- `docs/v12/FIRMAMENTO_DE_LOS_ECOS.md`, `docs/memory/agents/interfaz_v12_orbes.md`

COMPARTIDOS (bloques pequeños):
- `aethelgard/grupo.gd`: un bloque en `estadisticas()` (atributos, ataque y magia_extra del tablero, al vuelo).
- `aethelgard/equipo_extra.gd`: un bloque al final de `efectos_de()` (pasivas con el tope de `EFECTOS`). No toca
  `ACCESORIOS` ni `EFECTOS` (los amplía otro especialista): si se añade allí un efecto nuevo con su gancho, los nodos
  que lo usen despiertan solos.
- `aethelgard/progreso.gd`: `"firmamento"` al final de `CLAVES`.
- `aethelgard/menus.gd`: botón «Firmamento» en la ficha del Grupo, `_abrir_firmamento()` y la línea de Ajustes solo
  en Auditoría/editor.
- `aethelgard/pruebas/lista_pruebas.txt`: `prueba_firmamento` al final.

Sin recursos externos nuevos (retratos de diálogo y sonidos ya integrados): ninguna fila nueva en `docs/recursos.md`.

## Interruptores

- `orbes_v12`: `Engine.set_meta("orbes_v12", true)`, `-- orbes_v12`, o (solo Auditoría/editor) Ajustes →
  «Firmamento de los Ecos (prueba)» (`user://ajustes.cfg [firmamento] activo`). Por defecto, apagado.
- Concepto visual: `user://ajustes.cfg [firmamento] estilo` (`astrolabio` por defecto, sin aprobar).
- Naira: además, su `naira_v12` de siempre.

## Pruebas y resultados

- `prueba_firmamento`: SUPERADA (apagado sin cambios en estadísticas, efectos, partida y ficha; datos coherentes
  y alcanzables; compra, bloqueado, «todos», saldo insuficiente, dormido; bonificación en `grupo.estadisticas()` y
  `efectos_de()` una sola vez y con tope; guardar/cargar dos veces sin duplicar; partida antigua sin la clave; interfaz
  en los tres conceptos con los tres héroes y con Naira; toque, arrastre, pellizco, rueda, flechas, confirmar,
  animación, error, Intro/Esc, 3D apagado y devuelto, herramienta solo en Auditoría/editor; ficha del Grupo; combate
  de verdad con el ataque, la velocidad y el crítico del tablero).
- Afectadas, todas SUPERADAS (pasada 2026-11-12_195413): `prueba_grupos_combate`, `prueba_guardado_protegido`,
  `prueba_menu_magia`, `prueba_guardado`, `prueba_partida`, **`prueba_combate_huella`** (C0 igual),
  `prueba_equipo`, `prueba_equipo_combate`, `prueba_guardado_fallos`, `prueba_grupo_reserva`.
  Datos reales y proyecto sin cambios en todas las pasadas.

## Medidas (PC; NO son del Redmi)

`fotos_firmamento.gd … medir` (sin límite ni vsync, redibujando todo cada fotograma = peor caso):

| Concepto | 1600×720 | 2400×1080* | Llamadas | Primitivas | VRAM 1600×720 |
|---|---|---|---|---|---|
| Astrolabio | 4,54 ms (CPU dibujo 1,03, GPU 0,42) | 4,73 ms | 114 | 23 935 | 20,6 MB |
| Constelación | 4,70 ms (1,07 / 0,45) | 4,46 ms | 114 | 16 325 | 20,0 MB |
| Vidriera | 4,27 ms (1,10 / 0,49) | 3,65 ms | 113 | 20 110 | 20,3 MB |

\* La ventana del PC no pasa de 1924×1055; las capturas de 2400×1080 se componen como en `fotos_portada.gd` (lienzo
1280×720 escalado ×1,5 y centrado con bandas, como en el teléfono).
Antes de agrupar en triángulos: 520-650 llamadas y 6-10 ms por fotograma.

**Mali-G57 (malioc, estimación estática del fondo)**: astrolabio 4,5 ciclos/píxel, constelación 8,5, vidriera 8,6
(10,4 antes del hash sin `sin()`); con el modelo de presupuesto de Arm, ~1,5-2,8 ms por fotograma a 1600×720 y ×2,25 a
2400×1080. Fuentes GLSL usadas para malioc: `D:\REBELUM_diagnostico\v12\expansion\orbes\malioc\`.

## Capturas

`D:\REBELUM_diagnostico\v12\expansion\orbes\capturas\`: `1600x720_*` y `2400x1080_*` para cada concepto: `0_vacio`
(antes de usarlo), `1_kael`, `2_lya`, `3_garon`, `4_confirmar`, `5_energia`, `6_estallido`, `7_cerca`; y
`comparar_*.png` (los tres conceptos apilados). Medidas en `medidas_1600x720.txt` y `medidas_2400x1080.txt`.

## Lo que queda / decisiones del usuario

Ver §11 del documento de diseño: concepto, obtención (7 propuestas sin elegir), saldo común o por héroe, precios y
valores, ganchos de resistencias (nodos dormidos), reinicio (4 opciones estudiadas, nada implementado), Naira.

## Validar en el Redmi

- Fluidez del tablero a 30 FPS con el 3D apagado debajo; coste real del fondo (Streamline) frente a la estimación.
- Que el pellizco y el arrastre no se confundan con toques (umbral 14 px) y que los toques emulados no cuenten doble.
- Lectura de textos de 15-17 px y de los precios a 1600×720; contraste del concepto constelación con poco brillo.
- Que al cerrar el tablero la región 3D vuelve a dibujarse (`disable_3d` devuelto).
- Sonidos: solo se comprobó que existen y se piden; no se han escuchado.
