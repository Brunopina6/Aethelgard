# Transparencias en los perfiles bajo y medio (PC-9, 19/11)

Origen: `MUESTRA_CALLE_OAKHAVEN.md` §7 («en bajo y medio una capa transparente oscura no oscurecía nada en
Compatibility; en el alto sí se dibujaba, mal; ¿escala 3D < 1?») y §7.b, y `ENTREGA_NOCHE_16_11.md` («transparencias
que no oscurecen en bajo/medio, sin investigar»). Investigación en el PC (Godot 4.7.2, Compatibility, Windows);
**no se ha cambiado nada del juego**.

## Resumen

| | Resultado | Estado |
|---|---|---|
| ¿La escala 3D 0,75 / 0,80 (bajo / medio) cambia las transparencias? | **No.** Mismo color a 3 decimales con 1,0 / 0,99 / 0,80 / 0,75, con y sin MSAA 2×, en todos los tipos | DEMOSTRADO (PC) |
| ¿Una capa oscura deja de oscurecer en bajo o medio en la calle? | **No se reproduce** (19/11): a 4 cm, 1,5 cm y 5 mm del suelo y en el aire, igual en los 8 casos medidos | DEMOSTRADO que hoy no pasa; la causa del 15/11 sigue sin saberse |
| Multiplicar (`BLEND_MODE_MUL`, `blend_mul`) con **resplandor (glow)** encendido | **Mal:** oscurece de más; ×1,0 (blanco), que no debería cambiar nada, deja el suelo de 0,905 en 0,170; ×0,5 lo deja casi negro (0,04). Sin resplandor, casi bien (×1,0 deja 0,903 en 0,859: el blanco no queda neutro, como ya anotaba `mancha_sombra.gdshader`) | DEMOSTRADO. Solo el alto lleva resplandor: es el «en el alto se dibujaba mal» |
| Trama (`TRANSPARENCY_ALPHA_HASH`) sin resplandor | El color está bien, pero escribe **alfa 0,333 en el búfer** → en las capturas PNG (`get_image`) esos píxeles salen medio transparentes y un visor los pinta claros. Con resplandor, alfa 1 | DEMOSTRADO en capturas; en pantalla (ventana opaca) no se ve: PROBABLE |
| Mezcla, prepasada, premultiplicado, color de vértice, Sprite3D, sombreado propio con ALPHA, sumar | Iguales en los tres perfiles | DEMOSTRADO |

**Causa demostrada de lo que se vio «mal» en el alto:** en Compatibility, con el resplandor encendido, la escena 3D se
dibuja en un búfer intermedio de alto rango (lineal) y la mezcla por multiplicación da un resultado mucho más oscuro que
el esperado (incluso multiplicar por blanco oscurece). No depende de la escala ni del MSAA: lo enciende o apaga solo el
resplandor (`alto#singlow` → bien; `bajo#glow` → mal).

**«No oscurecía nada en bajo/medio»: NO demostrado.** Hipótesis que encajan con las medidas, sin poder confirmar cuál
pasó el 15/11 (el código de aquella prueba no se guardó):
1. La mezcla se hace **antes** del mapeo de tonos FÍLMICO y de los ajustes (contraste 1,12) de la calle: una capa negra
   al 50 % no deja el píxel a la mitad. Sobre suelo claro (0,90) queda en 0,56 (×0,62); sobre las zonas oscuras de la
   calle solo baja un 8-16 % (`mezcla_aire`: ×0,86-0,92 sobre fondo de 0,15-0,23). Una sombra falsa sobre el adoquín en
   sombra se nota muy poco: puede parecer que «no oscurece». Es igual en los tres perfiles.
2. Una capa a pocos milímetros del adoquinado (que tiene relieve) queda tapada a trozos (cobertura 0,72-0,84 a 5 mm).
3. Si se miró en capturas PNG con una capa de trama, el alfa 0,333 la hace parecer clara (ver arriba).
Descartado: la escala 3D (medida), el MSAA (medido), el formato del búfer en bajo/medio frente a alto sin resplandor
(mismos valores en `alto#singlow`, `bajo@1.0`, `medio@1.0`).

## Herramientas (no son pruebas: no están en `lista_pruebas.txt`)

- `aethelgard/pruebas/herramientas/medir_transparencias.gd` — escena mínima: suelo opaco de color conocido (mitad
  `StandardMaterial3D` sin luz, mitad sombreado propio `unshaded, depth_draw_opaque` como el de la calle) y una fila de
  cuadros negros al 50 % de cada tipo; 18 configuraciones (ambiente sencillo / el de la calle / el de la calle con
  resplandor × escala 1,0, 1,0+MSAA 2×, 0,80, 0,75, 0,75+MSAA 2×, 0,99). Lee el color (y el alfa) del centro de cada
  cuadro con `get_viewport().get_texture().get_image()`.
  `Godot --path aethelgard --resolution 640x360 --script res://pruebas/herramientas/medir_transparencias.gd -- salida=<carpeta>`
- `aethelgard/pruebas/herramientas/medir_transparencias_calle.gd` — la muestra REAL de la calle con la cámara de la
  muestra sobre Kael; captura sin y con capas (mezcla estándar, mezcla con luz, multiplicar, sombreado propio con ALPHA,
  trama) a 4 cm, 1,5 cm y 5 mm del suelo y en el aire a 1,5 m; relación con/sin en el centro, cobertura (de 9×9 puntos
  del cuadro, cuántos salen ≥ 5 % más oscuros) y alfa. Casos: `perfil`, `perfil@escala` (escala cambiada con
  `calidad_extra`), `perfil#glow` / `perfil#singlow` (resplandor forzado).
  `Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_transparencias_calle.gd -- 3d sin_prologo salida=<carpeta> casos=bajo,medio,alto,bajo@1.0,medio@1.0,alto@0.75,alto#singlow,bajo#glow`

## Medidas (PC, 19/11)

Carpeta: `D:\REBELUM_diagnostico\transparencias_19_11\` (`minima\` y `calle\`: capturas, `medidas.json`,
`tabla.txt`, `salida.txt`; `recortes\`: la zona de las capas ampliada ×2, `*_con.png` tal cual y `*_con_opaco.png` sin
el canal alfa, que es lo que enseña la ventana).

### Escena mínima (media RGB del centro de cada cuadro; suelo 0,800 con ambiente sencillo, 0,903 con el de la calle)

Cada celda vale para las 6 configuraciones de escala/MSAA de esa columna (diferencias ≤ 0,004 entre ellas).

| Cuadro (negro 50 % salvo indicación) | Sencillo | Calle (= bajo, medio) | Calle + resplandor (= alto) |
|---|---|---|---|
| mezcla (estándar, sombreado propio, color de vértice, Sprite3D, prepasada) | 0,400-0,404 | 0,555-0,561 | 0,559-0,563 |
| mezcla con luz | 0,447-0,451 | 0,586 | 0,587-0,590 |
| premultiplicado (estándar y sombreado propio) | 0,400 | 0,623-0,631 | 0,629-0,634 |
| recorte (umbral 0,4) | 0,000 | 0,064 | 0,067-0,068 |
| **multiplicar ×0,50** (estándar y `blend_mul`) | 0,400 | 0,450 | **0,038-0,040** |
| **multiplicar ×0,75** | 0,600 | 0,680 | **0,101-0,103** |
| **multiplicar ×0,90** | 0,722 | 0,793 | **0,141** |
| **multiplicar ×1,00** (no debería cambiar nada) | 0,800 | 0,859 | **0,170** |
| `blend_mul` ×0,5 con `fog_disabled` | 0,400 | 0,440 | **0,035** |
| sumar 0,1 (humo y motas del alto) | 0,890 | 0,996 | 0,997 |
| trama: color / **alfa del búfer** | 0,000 / **0,333** | 0,067 / **0,333** | 0,071 / 1,000 |

### Calle real (relación con/sin del centro · cobertura)

| Capa | bajo (0,75) | bajo@1,0 | medio (0,80) | medio@1,0 | alto (1,0, MSAA, glow) | alto@0,75 | alto sin glow | bajo con glow |
|---|---|---|---|---|---|---|---|---|
| mezcla a 4 cm | 0,65 · 0,93 | 0,64 · 0,90 | 0,64 · 0,90 | 0,65 · 0,91 | 0,65 · 0,91 | 0,65 · 0,93 | 0,65 · 0,95 | 0,65 · 0,99 |
| mezcla a 1,5 cm | 0,65 · 0,95 | 0,65 · 0,93 | 0,65 · 0,94 | 0,65 · 0,93 | 0,65 · 0,94 | 0,65 · 0,94 | 0,65 · 0,95 | 0,65 · 0,94 |
| mezcla a 5 mm | 0,68 · 0,84 | 0,68 · 0,79 | 0,68 · 0,84 | 0,69 · 0,79 | 0,83 · 0,79 | 0,82 · 0,84 | 0,84 · 0,79 | 0,68 · 0,84 |
| sombreado propio ALPHA a 4 cm | 0,66 · 0,95 | 0,65 · 0,93 | 0,68 · 0,96 | 0,65 · 0,93 | 0,66 · 0,93 | 0,67 · 0,99 | 0,66 · 0,94 | 0,67 · 0,96 |
| mezcla en el aire (fondo oscuro) | 0,86 · 1,00 | 0,91 · 1,00 | 0,90 · 1,00 | 0,91 · 1,00 | 0,92 · 1,00 | 0,87 · 1,00 | 0,91 · 1,00 | 0,86 · 1,00 |
| **multiplicar a 1,5 cm** | 0,31 | 0,32 | 0,35 | 0,35 | **0,00** | **0,00** | 0,35 | **0,00** |
| trama a 4 cm (alfa) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (1,0) | 0,47 (1,0) | 0,47 (0,33) | 0,47 (1,0) |

La mezcla a 5 mm en el alto: el suelo de debajo ya es más oscuro en el alto (0,42 frente a 0,49) y el «con» queda
igual (0,34 frente a 0,33): es el mapeo fílmico, no la capa. El cuadro de multiplicar a 4 cm cae sobre matas de hierba
que se mueven con el viento entre las dos capturas (no vale). La cobertura ≈ 0,79 con escala 1,0 y ≈ 0,84 con 0,75/0,80 a 5 mm: el adoquín la tapa a trozos.

Capturas por perfil: `calle\bajo_sin.png`, `calle\bajo_con.png`, `calle\medio_con.png`, `calle\alto_con.png`, … y
`recortes\medio_con.png` frente a `recortes\medio_con_opaco.png` (la trama sale gris clara en el PNG con alfa y oscura
sin él), `recortes\alto_con.png` (multiplicar negro con resplandor).

## Propuesta (sin cambios en el juego)

- **No hay arreglo que hacer en bajo/medio**: hoy las transparencias oscurecen igual que en el alto, y la escala 3D no
  influye. No se añade interruptor.
- **Regla para lo nuevo:** para oscurecer (sombras falsas, velos, manchas) usar **mezcla con negro** (`blend_mix`,
  `ALBEDO = vec3(0)`, `ALPHA = 1 − factor`) y **no `blend_mul`**: en un búfer sRGB (sin resplandor) da exactamente lo
  mismo que multiplicar (0,400 = 0,400 en la mínima) y con resplandor sigue bien. `mancha_sombra.gdshader` ya lo hace.
  Hoy nada del juego publicado usa `blend_mul`: solo la capa de Kael de `prototipos/vegetacion_paquetes.gd` (banco de
  vegetación); el `detail_blend_mode = BLEND_MODE_MUL` de los materiales va dentro del sombreado y no le afecta.
- **Sombras falsas sobre el adoquín:** separarlas ≥ 1,5 cm del suelo (a 5 mm el relieve las tapa a trozos) y contar
  con que, con el mapeo fílmico, sobre zonas ya oscuras se notan poco: subir el alfa ahí o meter la sombra en el
  sombreado del suelo (lo que ya hace la muestra).
- **Capturas:** la trama sin resplandor deja alfa 0,333 en el PNG; las herramientas de fotos que comparen píxeles
  deberían quitar el alfa (`convert(FORMAT_RGB8)`) antes de guardar o comparar.

## Qué mirar en el Redmi (no disponible el 19/11)

1. Muestra de la calle con el perfil **bajo** y el **medio**: con una capa de mezcla negra al 50 % a 4 cm del suelo
   (se puede montar con `medir_transparencias_calle.gd`, que solo necesita la escena) comprobar que oscurece como en
   el PC (×0,65 sobre el adoquín al sol). En Android el búfer y el controlador (Mali-G57, GLES3) son otros: es lo que
   queda por confirmar de la rareza del 15/11.
2. Si el teléfono enseñara la capa más clara que el PC: probar sin `adjustment_enabled` y con mapeo lineal para separar
   mapeo de tonos de mezcla, y leer el alfa del búfer (la trama) por si la superficie de Android no fuera opaca.
3. Nada de esto cambia el rendimiento: no hay nada que medir en FPS.

## Pruebas

`ejecutar_pruebas.ps1 -Solo prueba_integridad,prueba_calidad_auto,prueba_calidad_pruebas`: SUPERADAS 3 · FALLIDAS 0
(partida real, carpeta real de datos y proyecto sin cambios; otros Godot: 0).
