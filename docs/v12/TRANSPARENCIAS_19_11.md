# Transparencias en los perfiles bajo y medio (PC-9, 19/11)

Origen: `MUESTRA_CALLE_OAKHAVEN.md` §7 («en bajo y medio una capa transparente oscura no oscurecía nada en
Compatibility; en el alto sí se dibujaba, mal; ¿escala 3D < 1?») y §7.b, y `ENTREGA_NOCHE_16_11.md` («transparencias
que no oscurecen en bajo/medio, sin investigar»). Investigación en el PC (Godot 4.7.2, Compatibility, Windows);
**no se ha cambiado nada del juego**.

> **Revisión (19/11, TRANSPARENCIAS_19_11_REVISION).** La primera versión de este documento (commit 25c1635) tenía
> tres errores que aquí se corrigen: (1) la fila «a 5 mm» de la calle caía **fuera de la pantalla** (la herramienta
> recortaba el punto al borde, y = 719, sin avisar) y sobre el camino de tierra con hierba: sus cifras no valían, ni
> la hipótesis «el relieve del adoquín tapa la capa» ni la regla «separar ≥ 1,5 cm» que salían de ellas; (2) la
> hipótesis «la mezcla va antes del mapeo de tonos» no encajaba: la capa «negra» ya salía clara por sí sola, y ahora
> está **medido** que es la **niebla** del ambiente; (3) unir el fallo de multiplicar con resplandor con lo visto el
> 15/11 es **probable**, no demostrado. Además, las filas «a 4 cm» y «a 1,5 cm» del primer informe estaban sobre el
> camino de tierra naranja, no sobre el adoquín, y las cifras redondas del mensaje del commit 25c1635 («×0,64-0,69 en
> los 8 casos, sobre el adoquín») no son ciertas: valen las de las tablas de abajo. La herramienta de la calle se ha
> corregido (avisa «fuera» e «inestable») y se ha vuelto a medir con las filas **sobre el adoquín y dentro de la
> pantalla**.

## Resumen

| | Resultado | Estado |
|---|---|---|
| ¿La escala 3D 0,75 / 0,80 (bajo / medio) cambia las transparencias? | **No.** Mismo color a 3 decimales con 1,0 / 0,99 / 0,80 / 0,75, con y sin MSAA 2×, en todos los tipos (mínima); en la calle, `bajo` = `bajo@1.0` y `medio` = `medio@1.0` (±0,01 en las capas negras, también en la segunda medida sobre el adoquín) | DEMOSTRADO (PC) |
| ¿Una capa oscura deja de oscurecer en bajo o medio en la calle? | **No hay diferencia entre perfiles** (19/11): bajo, medio y alto dan las mismas relaciones | DEMOSTRADO que hoy no depende del perfil |
| ¿Por qué una capa negra al 50 % oscurece poco en la calle? | **La niebla del ambiente** (`fog_enabled`, densidad 0,0025, color cálido) se aplica también a la capa, que no la desactiva: un negro **opaco** sin luz sale en (0,15-0,19, 0,11-0,14, 0,06-0,08) en los tres perfiles; con la niebla apagada (en el ambiente o en el material con `disable_fog` / `fog_disabled`) sale **0,000**. Una mezcla negra al 50 % sobre el adoquín deja ×0,69-0,87 con niebla y ×0,23-0,32 sin ella | DEMOSTRADO (PC) que la niebla aclara la capa; PROBABLE que sea lo visto el 15/11 |
| Multiplicar (`BLEND_MODE_MUL`, `blend_mul`) con **resplandor (glow)** encendido | **Mal:** oscurece de más; ×1,0 (blanco), que no debería cambiar nada, deja el suelo de 0,905 en 0,170; ×0,5 lo deja casi negro (0,04). Sin resplandor, casi bien (×1,0 deja 0,903 en 0,859: el blanco no queda neutro, como ya anotaba `mancha_sombra.gdshader`). Lo decide solo el resplandor (`alto#singlow` bien, `bajo#glow` mal) | DEMOSTRADO. Solo el alto lleva resplandor: PROBABLE explicación del «en el alto se dibujaba mal» (el tipo de capa del 15/11 no se conserva: la nota dice «mezcla o multiplicación») |
| Trama (`TRANSPARENCY_ALPHA_HASH`) sin resplandor | El color está bien, pero escribe **alfa 0,333 en el búfer** → en las capturas PNG (`get_image`) esos píxeles salen medio transparentes y un visor los pinta claros. Con resplandor, alfa 1 | DEMOSTRADO en capturas; en pantalla (ventana opaca) no se ve: PROBABLE |
| Mezcla, prepasada, premultiplicado, color de vértice, Sprite3D, sombreado propio con ALPHA, sumar | Iguales en los tres perfiles | DEMOSTRADO |
| ¿Una capa a 5 mm del adoquín queda tapada a trozos por su relieve? | **No:** sobre adoquín de verdad y dentro de la pantalla, la mezcla a 5 mm cubre 0,96-1,00 del cuadro y la mezcla sin niebla 1,00, como a 4 cm | DEMOSTRADO (PC, segunda medida); la hipótesis del primer informe queda descartada |

**Lo del 15/11 («no oscurecía nada en bajo/medio»): NO demostrado, con una causa probable.** El código de aquella
prueba no se guardó. Lo que encaja con todas las medidas:
1. **La niebla aclara la capa** (medido arriba). Sobre el adoquín en sombra (≈ 0,25-0,45) una capa negra al 50 % queda
   en ×0,7-0,8: se nota poco y puede parecer que «no oscurece». Es igual en los tres perfiles; si el 15/11 en el alto
   se usó multiplicar, allí salía negro por el resplandor, y la diferencia entre perfiles sería la del resplandor, no
   la de la capa de mezcla. Probable, no demostrado.
2. Si se miró en capturas PNG con una capa de trama, el alfa 0,333 la hace parecer clara (ver arriba).

Descartado con medidas: la escala 3D, el MSAA, el formato del búfer en bajo/medio frente a alto sin resplandor
(mismos valores en `alto#singlow`, `bajo@1.0`, `medio@1.0`), el orden mezcla / mapeo de tonos (con escala < 1 el mapeo
va en otra pasada, `muestra_calle.gd:121`, y aun así `bajo` = `bajo@1.0`; con mapeo lineal y sin ajustes la capa con
niebla sigue sin llegar a negro: `bajo#lineal`, `bajo#sinajustes`) y la altura de la capa sobre el adoquín
(4 cm, 1,5 cm y 5 mm cubren igual).

## Herramientas (no son pruebas: no están en `lista_pruebas.txt`)

- `aethelgard/pruebas/herramientas/medir_transparencias.gd` — escena mínima: suelo opaco de color conocido (mitad
  `StandardMaterial3D` sin luz, mitad sombreado propio `unshaded, depth_draw_opaque` como el de la calle) y una fila de
  cuadros negros al 50 % de cada tipo; 18 configuraciones (ambiente sencillo / el de la calle / el de la calle con
  resplandor × escala 1,0, 1,0+MSAA 2×, 0,80, 0,75, 0,75+MSAA 2×, 0,99). Lee el color (y el alfa) del centro de cada
  cuadro con `get_viewport().get_texture().get_image()`.
  `Godot --path aethelgard --resolution 640x360 --script res://pruebas/herramientas/medir_transparencias.gd -- salida=<carpeta>`
- `aethelgard/pruebas/herramientas/medir_transparencias_calle.gd` — la muestra REAL de la calle con la cámara de la
  muestra sobre Kael; captura sin y con capas de 0,5 m (mezcla estándar, con luz, multiplicar, sombreado propio con
  ALPHA, trama, mezcla sin niebla, sombreado propio con `fog_disabled`, y un **negro opaco** con y sin niebla, que da el
  color de «el negro» por sí solo) a 4 cm, 1,5 cm y 5 mm del **adoquín** (detrás de Kael, z = −0,7 / −1,4 / −2,1 m) y en
  el aire a 1,5 m (z = +3 m); relación con/sin en el centro, cobertura (de 9×9 puntos del cuadro, cuántos salen ≥ 5 %
  más oscuros) y alfa. Desde la revisión: un punto fuera de la ventana o detrás de la cámara sale «fuera» (y un AVISO
  en la salida), y uno cuyo color «sin» cambia entre dos capturas seguidas (hierba con viento, Kael) sale
  `"estable": false` y no cuenta en la cobertura. Casos: `perfil`, `perfil@escala` (escala cambiada con
  `calidad_extra`), `perfil#mod+mod` con `glow`, `singlow`, `sinniebla`, `lineal`, `sinajustes`. `filas=antigua`
  repite la colocación del primer informe (para enseñar la fila fuera de la pantalla).
  `Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/medir_transparencias_calle.gd -- 3d sin_prologo salida=<carpeta> casos=bajo,medio,alto,bajo@1.0,bajo#sinniebla`
  No comprueba qué hay delante del punto (una mata, un barril): eso solo se ve en las capturas o como «inestable».

## Medidas (PC, 19/11)

Primera medida: `D:\REBELUM_diagnostico\transparencias_19_11\` (`minima\` y `calle\`: capturas, `medidas.json`,
`tabla.txt`, `salida.txt`; `recortes\`: la zona de las capas ampliada ×2, `*_con.png` tal cual y `*_con_opaco.png` sin
el canal alfa, que es lo que enseña la ventana). Segunda medida (revisión), con la herramienta corregida:
`D:\REBELUM_diagnostico\transparencias_19_11_revision\` (`antigua\`: la colocación vieja con los avisos; `calle\`: 15
casos, `medidas.json`, `tabla.txt`, `tabla_corta.txt`, `salida.txt`).

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

(El recorte negro sale 0,064-0,068 y no 0 con el ambiente de la calle: es la misma niebla, con la cámara más cerca.)

### Calle real, primera medida (corregida)

Las filas «a 4 cm» (y ≈ 632) y «a 1,5 cm» (y ≈ 688) caían sobre el **camino de tierra** delante de Kael, no sobre el
adoquín, y la de «5 mm» (z = +3,4 m) caía **fuera de la pantalla**: lo que se midió es la última fila de la imagen
(y = 719), tierra con hierba. **Las filas de 5 mm no valen.** Tampoco valen `multiplicar_suelo` (matas de hierba que se
mueven con el viento entre las dos capturas), `sh_mix_suelo15mm` (su punto, (742, 688), es hierba verde oscura que se
mueve: cobertura 0,25-0,41 y relación 0,50-2,21, más claro que sin capa en `alto@0.75`) ni `multiplicar_aire` (cae
sobre Kael). La herramienta corregida, con `filas=antigua`, marca las cinco de 5 mm como «fuera» y esas tres como
`"estable": false` (salida literal en «Pruebas»).

| Capa (relación con/sin del centro · cobertura) | bajo (0,75) | bajo@1,0 | medio (0,80) | medio@1,0 | alto (1,0, MSAA, glow) | alto@0,75 | alto sin glow | bajo con glow |
|---|---|---|---|---|---|---|---|---|
| mezcla a 4 cm (tierra) | 0,65 · 0,93 | 0,64 · 0,90 | 0,64 · 0,90 | 0,65 · 0,91 | 0,65 · 0,91 | 0,65 · 0,93 | 0,65 · 0,95 | 0,65 · 0,99 |
| mezcla a 1,5 cm (tierra) | 0,65 · 0,95 | 0,65 · 0,93 | 0,65 · 0,94 | 0,65 · 0,93 | 0,65 · 0,94 | 0,65 · 0,94 | 0,65 · 0,95 | 0,65 · 0,94 |
| ~~mezcla a 5 mm~~ (fuera de la pantalla: no vale) | — | — | — | — | — | — | — | — |
| sombreado propio ALPHA a 4 cm (tierra) | 0,66 · 0,95 | 0,65 · 0,93 | 0,68 · 0,96 | 0,65 · 0,93 | 0,66 · 0,93 | 0,67 · 0,99 | 0,66 · 0,94 | 0,67 · 0,96 |
| mezcla en el aire (fondo oscuro) | 0,86 · 1,00 | 0,91 · 1,00 | 0,90 · 1,00 | 0,91 · 1,00 | 0,92 · 1,00 | 0,87 · 1,00 | 0,91 · 1,00 | 0,86 · 1,00 |
| **multiplicar a 1,5 cm** (tierra) | 0,31 | 0,32 | 0,35 | 0,35 | **0,00** | **0,00** | 0,35 | **0,00** |
| trama a 4 cm (alfa) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (0,33) | 0,47 (1,0) | 0,47 (1,0) | 0,47 (0,33) | 0,47 (1,0) |

Es decir: sobre la tierra, ×0,64-0,65 a 4 cm y 1,5 cm en los 8 casos; en el aire, ×0,86-0,92. La trama, que no mezcla,
dejaba R = 0,165 en el aire en los 8 casos: la capa «negra» no era negra.

### Calle real, segunda medida (revisión: sobre el adoquín, todo dentro de la pantalla)

Relación con/sin del centro · cobertura (todos los centros estables salvo donde se indica; ningún punto fuera). Capas
de 0,5 m; «sn» = el material con la niebla desactivada (`disable_fog` / `fog_disabled`).

| Capa | bajo | bajo@1,0 | medio | medio@1,0 | alto | alto@0,75 | alto sin glow | bajo con glow | bajo sin niebla | medio sin niebla | alto sin niebla | bajo lineal | bajo sin ajustes | bajo sin niebla, lineal, sin ajustes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| negro opaco, suelo | 0,37 | 0,37 | 0,39 | 0,37 | 0,39 | 0,38 | 0,38 | 0,38 | **0,00** | **0,00** | **0,00** | 0,38 | 0,47 | **0,00** |
| negro opaco «sn», suelo | **0,00** | **0,00** | **0,00** | **0,00** | **0,00** | **0,00** | **0,00** | **0,00** | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 | 0,00 |
| mezcla a 4 cm | 0,81 · 0,95 | 0,81 · 0,90 | 0,87 · 0,96 | 0,81 · 0,90 | 0,82 · 0,91 | 0,86 · 0,97 | 0,81 · 0,91 | 0,82 · 0,95 | 0,10 · 0,94 | 0,00 · 0,93 | 0,15 · 0,89 | 0,81 · 0,96 | 0,86 · 0,94 | 0,39 · 0,95 |
| mezcla a 1,5 cm | 0,74 · 0,94 | 0,69 · 0,85 | 0,69 · 0,96 | 0,69 · 0,85 | 0,69 · 0,89 | 0,71 · 0,96 | 0,69 · 0,91 | 0,75 · 0,95 | 0,21 · 0,89 | 0,34 · 0,90 | 0,36 · 0,89 | 0,75 · 0,95 | 0,79 · 0,94 | 0,43 · 0,97 |
| mezcla a 5 mm | 0,73 · 0,97 | 0,73 · 0,93 | 0,73 · 0,99 | 0,73 · 0,93 | 0,72 · 0,96 | 0,72 · 1,00 | 0,73 · 0,96 | 0,72 · 0,97 | 0,30 · 0,95 | 0,29 · 0,97 | 0,29 · 0,95 | 0,73 · 0,97 | 0,77 · 0,97 | 0,46 · 0,99 |
| mezcla «sn» a 4 cm | 0,23 · 1,00 | 0,24 · 1,00 | 0,24 · 1,00 | 0,24 · 1,00 | 0,24 · 1,00 | 0,25 · 1,00 | 0,24 · 1,00 | 0,25 · 1,00 | 0,00 · 0,97 | 0,00 · 0,97 | 0,06 · 0,96 | 0,20 · 1,00 | 0,41 · 1,00 | 0,29 · 1,00 |
| mezcla «sn» a 5 mm | 0,31 · 1,00 | 0,31 · 1,00 | 0,29 · 1,00 | 0,31 · 1,00 | 0,32 · 1,00 | 0,28 · 1,00 | 0,31 · 1,00 | 0,32 · 1,00 | 0,24 · 1,00 | 0,15 · 0,99 | 0,25 · 0,99 | 0,30 · 1,00 | 0,43 · 1,00 | 0,43 · 1,00 |
| sombreado propio ALPHA a 4 cm | 0,66 · 0,99 | 0,67 · 0,93 | 0,66 · 1,00 | 0,67 · 0,93 | 0,67 · 0,93 | 0,67 · 1,00 | 0,67 · 0,95 | 0,67 · 0,99 | 0,36 · 0,97 | 0,36 · 0,94 | 0,37 · 0,91 | 0,67 · 0,99 | 0,70 · 0,99 | 0,48 · 1,00 |
| sombreado propio `fog_disabled` a 4 cm | 0,37 · 1,00 | 0,38 · 1,00 | 0,38 · 1,00 | 0,38 · 1,00 | 0,39 · 1,00 | 0,37 · 1,00 | 0,38 · 1,00 | 0,38 · 1,00 | 0,35 · 0,99 | 0,35 · 0,96 | 0,39 · 0,93 | 0,38 · 1,00 | 0,46 · 1,00 | 0,48 · 1,00 |
| multiplicar ×0,5 a 4 cm | 0,36 | 0,35 | 0,36 | 0,35 | **0,00** | **0,00** | 0,35 | **0,00** | 0,33 | 0,33 | **0,00** | 0,36 | 0,44 | 0,44 |

Color del centro del **negro opaco** (R, G, B): con niebla, en el suelo (0,184, 0,141, 0,078) en bajo y medio y
(0,188, 0,141, 0,082) en alto; en el aire (0,153, 0,114, 0,059) en bajo y medio y (0,157, 0,110, 0,055) en alto; la
trama en el aire (0,149-0,153, 0,110-0,114, 0,055-0,059). Sin niebla (en el ambiente o en el material): (0, 0, 0) en
todos los casos. Una mezcla al 50 % de ese «negro» de 0,15-0,19 sobre adoquín de 0,3-0,5 se queda en ×0,7-0,8.

Notas: las relaciones de la mezcla cambian de una fila a otra porque cambia el adoquín de debajo (más oscuro → la capa
con niebla oscurece menos), no por la altura. Sin niebla y con el mapeo fílmico + ajustes (contraste 1,12), una capa
al 50 % sobre adoquín oscuro llega a 0 (×0,00-0,15): el contraste aplasta los oscuros. La fila del aire (z = +3 m) no
vale para las relaciones: `mezcla_aire` cae sobre la farola (con la niebla apagada su «sin» es 0 y salen relaciones de
0 o 98) y `mezcla_luz_aire` / `multiplicar_aire` sobre fondos oscuros o con hierba (`"estable": false` en varios
casos); solo se usan de ella los colores del negro opaco y de la trama.

Capturas por perfil: `transparencias_19_11_revision\calle\bajo_con.png`, `medio_con.png`, `alto_con.png` frente a
`bajo#sinniebla_con.png`, `medio#sinniebla_con.png`, `alto#sinniebla_con.png` (los cuadros negros con niebla salen
pardos; sin niebla, negros). De la primera medida: `transparencias_19_11\recortes\medio_con.png` frente a
`recortes\medio_con_opaco.png` (la trama sale gris clara en el PNG con alfa y oscura sin él) y `recortes\alto_con.png`
(multiplicar negro con resplandor).

## Propuesta (sin cambios en el juego)

- **No hay arreglo que hacer en bajo/medio**: hoy las transparencias oscurecen igual en los tres perfiles, y la escala
  3D no influye. No se añade interruptor.
- **Niebla en las capas oscuras (decisión de arte, no fallo):** que la niebla aclare una capa negra es lo que hace la
  niebla con todo (el suelo de debajo también la lleva), pero con la densidad de la calle a ≈ 19 m de cámara deja un
  velo de 0,15-0,19 que una sombra falsa no puede bajar. Si una sombra falsa o un velo oscuro tiene que verse más
  oscuro: subir su alfa, meter la sombra en el sombreado del suelo (lo que ya hace la muestra) o desactivar la niebla
  en ese material (`disable_fog` / `render_mode fog_disabled`: la capa queda ×0,23-0,32 sobre el adoquín, pero ya no
  lleva el velo de la distancia; mirarlo con capturas antes de usarlo).
- **Regla para lo nuevo:** para oscurecer (sombras falsas, velos, manchas) usar **mezcla con negro** (`blend_mix`,
  `ALBEDO = vec3(0)`, `ALPHA = 1 − factor`) y **no `blend_mul`**: en un búfer sRGB (sin resplandor) da lo mismo que
  multiplicar (0,400 = 0,400 en la mínima) y con resplandor sigue bien. `mancha_sombra.gdshader` ya lo hace.
  Hoy nada del juego publicado usa `blend_mul`: solo la capa de Kael de `prototipos/vegetacion_paquetes.gd` (banco de
  vegetación); el `detail_blend_mode = BLEND_MODE_MUL` de los materiales va dentro del sombreado y no le afecta.
- **Altura de las sombras falsas:** a 5 mm del adoquín la capa lo cubre igual que a 4 cm (medido en la segunda
  medida); no hace falta una separación mínima por el relieve. (La regla «≥ 1,5 cm» del primer informe salía de una
  fila fuera de la pantalla y se retira.)
- **Capturas:** la trama sin resplandor deja alfa 0,333 en el PNG; las herramientas de fotos que comparen píxeles
  deberían quitar el alfa (`convert(FORMAT_RGB8)`) antes de guardar o comparar. Y toda herramienta que mida un punto
  del mundo debe avisar si cae fuera de la ventana en vez de recortarlo al borde.

## Qué mirar en el Redmi (no disponible el 19/11)

Lo único que depende del teléfono es que su GPU y su controlador (Mali-G57, GLES3) den lo mismo que el PC; la causa
(niebla) y la independencia de la escala ya están medidas en el PC.
1. Muestra de la calle en **bajo** y **medio** con `medir_transparencias_calle.gd` (`casos=bajo,medio,bajo#sinniebla`):
   el negro opaco con niebla debería salir ≈ (0,18, 0,14, 0,08) en el suelo y (0, 0, 0) el «sn» y sin niebla; la mezcla
   a 4 cm ×0,7-0,9 con niebla y ×0,2-0,3 sin ella. Si el teléfono sacara la capa más clara que eso, ya no sería la
   niebla y habría que leer el alfa del búfer (la trama) por si la superficie de Android no fuera opaca.
2. Nada de esto cambia el rendimiento: no hay nada que medir en FPS.

## Pruebas

Primer informe: `ejecutar_pruebas.ps1 -Solo prueba_integridad,prueba_calidad_auto,prueba_calidad_pruebas`: SUPERADAS 3 ·
FALLIDAS 0 (partida real, carpeta real de datos y proyecto sin cambios; otros Godot: 0).

Revisión: la herramienta corregida con `filas=antigua casos=bajo` da (rc = 0)
`AVISO bajo: 5 cuadros caen FUERA de la pantalla (sin medida)` y `"mezcla_suelo5mm":"fuera"` (y las otras cuatro de
5 mm), y `multiplicar_suelo`, `sh_mix_suelo15mm` y `multiplicar_aire` con `"estable":false`; la herramienta del primer
informe daba para esa fila, sin aviso, `"mezcla_suelo5mm":{"cobertura":0.84,…,"ratio":0.68,…}`. La segunda medida
(15 casos) dio rc = 0, sin avisos ni ERROR. Las mismas tres pruebas tras la revisión (`git status` igual antes y
después; resumen en `D:\REBELUM_diagnostico\pruebas6-11-19_182212esumen.md`): SUPERADAS 3 · FALLIDAS 0 ·
MANUALES 0 · NO SEGURAS 0 (partida real, carpeta real de datos y proyecto sin cambios; otros Godot: 0; rc = 0).
