# Rendimiento de cargas · V12 (12/11/2026)

Especialista de rendimiento de carga. Copia `D:\Aethelgard_v12_cargas`, rama LOCAL `claude/v12-hito-cargas` (desde
`claude/rebelum-v12` @ `a0bab37`). Sin push ni merge. Sin Redmi: todo se midió en el PC (RTX 3050 portátil, OpenGL 3.3,
Compatibility, 1280×720, perfil **medio**), siempre con datos aislados. Encargo: eliminar las esperas sin información.

## 1. Cómo se midió (comprobado ejecutando, aislado)

- **`pruebas/herramientas/medir_cargas.gd`** (+ `medir_cargas.ps1`, que crea su carpeta de datos en
  `D:\REBELUM_diagnostico\v12\cargas\<fecha>_<etiqueta>` y desvía APPDATA, LOCALAPPDATA, TEMP y TMP). Con ventana (si no,
  no se compila ningún sombreador). Se niega si `user://` es la carpeta real. Una pasada: arranque → «Continuar» con una
  partida en el Mar de Cristal → aviso de Bramavidrio → combate → ganar → vuelta → el mismo combate otra vez → N combates al
  azar con su vuelta. Por caso: cuándo se pone negro, cuándo entra la escena, su `_ready` (y en el combate cada parte:
  `combate.gd tiempos_carga`), primer fotograma, cuándo deja de verse negro, el peor fotograma tapado, **los programas de
  sombreado compilados por primera vez** (archivos nuevos en `user://shader_cache`) y la memoria (estática, de vídeo,
  privada y de trabajo del proceso, objetos, nodos y huérfanos). `-Repetir` hace una segunda pasada con la caché ya llena.
- **`pruebas/herramientas/listar_precarga.gd`**: lo que precarga el arranque, archivo a archivo, por peso importado.
- **Marcas de tiempo en `combate.gd _ready`** (`_marca`, solo leen el reloj).
- **Ojo:** el PC compila un programa en milisegundos; el Mali-G57, no. Por eso se cuenta cuántos se compilan y dónde.
  Durante las medidas había otros Godot de otros especialistas abiertos: los tiempos del PC tienen ±0,5 s de ruido.

## 2. Causas medidas

1. **El arranque precargaba lo que no se usa** (929 archivos, 268 MB importados en medio): los héroes v2 (apagados), sus
   mapas de normales y color de 4K; las **tres** versiones de Bramavidrio con sus **tres** perfiles cada una; Naira, los
   NPC del desierto y los enemigos v12 (apagados); Cencerrante, Vidracrán y Tolvanera (no los engancha nadie). Todo se
   quedaba en memoria toda la partida. Es la causa más probable de la subida del Redmi de 745-948 MB a 1,0-1,1 GB y de
   parte de la carga del título (15,5 → 18,5-21 s).
2. **La recogida de archivos iba al ritmo de los fotogramas:** una vuelta por fotograma (lo terminado esperaba al
   fotograma siguiente para dejar sitio). Fase de archivos: 8,0 s en el PC.
3. **La fase de «zonas» volvía a leer, para nada, las texturas de zona ya guardadas en caché** (0,6 s en cada arranque).
4. **Bramavidrio se montaba en el aviso:** su modelo, el surco y el polvo se creaban al temblar la arena y sus sombreadores
   se compilaban al dibujarse, **en mitad del aviso y de la aparición** (v1: 4 programas, v2 ≈ 5, v3: 5) y después el combate
   compilaba otros 4. En el Redmi (v615) eso coincide con 35 y 61 fotogramas en ventanas de 5 s (imagen congelada) entre
   las 21:53:41 y las 21:54:03: los «~18 s de negro». Calibrando con esos datos, ≈ 1 s por programa en el Mali-G57.
5. **La espera del combate era negro mudo:** la línea dorada medía la lectura de `combate.tscn`, que ya estaba en memoria,
   y se quedaba quieta mientras se montaba el combate. Durante la espera la ventana seguía recibiendo toques y teclas, y la
   música de la exploración seguía a todo volumen hasta montar la escena nueva.
6. **No es carga:** el `_ready` del combate cuesta 50-120 ms en el PC (fondo 51 ms la primera vez y 5 ms después; cada
   rig 3D 6-10 ms; efectos 13-20 ms). La **vuelta** a la región cuesta 1,0-1,1 s de `_ready` del Mar de Cristal cada vez
   (`mar_cristal_3d.gd`/`terreno.gd`, de otro especialista: no lo he tocado).

## 3. Cambios

- **`recursos.gd`:** la precarga deja fuera lo de un interruptor apagado (lo mira con la función del propio interruptor:
  al encenderlo se vuelve a precargar), los prototipos sin enganchar y, de Bramavidrio, todo menos la versión en uso y el
  modelo y la piel de su perfil. **Aviso de carga** sobre el negro: un rombo dorado que gira y «Preparando el combate…»,
  «Volviendo al mapa…» o «Cargando…», **sin cifra**; se deja ver un fotograma **antes** de montar la escena (si el móvil
  se congela compilando, lo que queda en pantalla informa). **Sin entrada** durante el cambio (`gui_disable_input`: ni
  toques, ni teclas, ni lo acumulado en una congelación). Al ir al combate, **la música se funde ya** (`Musica.pedir
  ("combate")`, que recuerda por dónde iba). `precargar(rutas)` en segundo plano, sin bloquear.
- **`carga.gd`:** recoge archivos durante 8 ms por fotograma (la pantalla sigue moviéndose); el precalentado usa **los
  mismos estudios que el combate**; solo genera las texturas de zona que faltan.
- **`combate.gd`** (solo carga): `estudio_3d`, `modelo_3d`, `estudio_vfx` y `brillo_vfx` estáticos, sacados de
  `_crear_rig_3d` y `_vfx_3d` sin cambiar lo que hacen; `_ruta_3d` estática; las marcas de tiempo.
- **`zonas3d/mar_cristal/gusano.gd`:** Bramavidrio se prepara **al entrar en la región**, bajo el negro (dos fotogramas
  delante de la cámara y escondido; sigue vivo toda la visita). El aviso pide en segundo plano el combate. Su versión de
  combate **no** se prepara en la región: sus sombreadores se crean y se liberan con cada modelo (`Shader.new` en
  `bramavidrio*_3d.gd`), así que solo valdría con la caché de Godot y, sin ella, se pagaría en cada entrada.
- **Prueba nueva `prueba_cargas`** (en `lista_pruebas.txt`).

## 4. Antes y después (PC, perfil medio; frío = `user://` vacío, caché = segunda pasada)

| Caso | Antes frío | Antes caché | Después frío | Después caché |
|---|---|---|---|---|
| Arranque hasta «TOCA PARA EMPEZAR» | 14,8 s | 9,6 s | **10,6 s** | **5,6 s** |
| «Continuar» → Mar de Cristal (negro → visible) | 1,7 s · 19 prog. | 1,5 s | 2,3 s · 24 prog. | 1,6 s |
| Aviso → aparición de Bramavidrio (v2): programas | ≈ 5 | 0 | **0** | 0 |
| Entrada al combate de Bramavidrio (negro → visible) | 0,36 s · 4 prog. | 0,33 s | 0,47 s · 3 prog. | 0,45 s |
| v1: aparición / combate | 4 / 4 prog. | — | **0** / 3 | — |
| v3: aparición / combate | 5 / 4 prog. | — | **0** / 3 | — |
| Repetir el combate · combate normal | 0,32 s · 0,32 s | — | 0,40 s · 0,39 s | — |
| Vuelta a la región | 1,3 s | 1,4 s | 1,5 s | 1,5 s |

El aviso tarda 8,0-8,1 s hasta pedir el combate en todos los casos: es la animación (surco, emersión, rugido), no carga.
Las transiciones son 80-100 ms más largas en el PC: el fotograma con el aviso antes de montar la escena y el fundido.

**Estimación para el Redmi (sin medir; la medición la hará el coordinador):**
- **Arranque:** 18,5-21 s → **12-15 s** (menos archivos y bytes, y recogida por presupuesto).
- **Bramavidrio:** la aparición deja de congelarse (≈ 5 s de imagen quieta menos); la entrada al combate, 2-4 s con
  «Preparando el combate…» en vez de negro mudo. De aviso a combate: unos 8 s de animación + 2-4 s, frente a ~18 s.
- **Primera entrada en el Mar de Cristal:** +3-5 s (los ≈ 5 programas de Bramavidrio, bajo el aviso de carga).
- **Caché de sombreadores de Godot:** en el PC escribe `user://shader_cache` (58 programas, 36 MB) y la segunda vez no
  compila nada. **En Android, pendiente de verificar**: si funciona, todo lo anterior solo se paga la primera vez.

## 5. Memoria

| Momento | Antes (privada · vídeo · estática) | Después |
|---|---|---|
| Pantalla de inicio | 1252 · 519 · 203 MB | **978 · 316 · 191 MB** |
| En la región tras 1-5 combates | 1418-1421 · 544 · 226 MB | **1191-1197 · 343 · 212 MB** |

En el Mali-G57 las texturas ocupan memoria del sistema: se espera bajar el PSS de 1,0-1,1 GB a unos 0,8-0,9 GB (estimado).
**Sin crecimiento:** cinco vueltas región → combate → región dejan los mismos objetos (9573), 0 huérfanos y la misma
memoria; en `prueba_cargas`, de la 2.ª a la 4.ª vuelta: 2903 → 2905 objetos, 526 nodos, 0 huérfanos, +0,2 MB.
**Avisos al cerrar:** `medir_cargas` deja 1 instancia (igual antes que después); `prueba_cargas`, 12-14 instancias y 6-7
recursos: con `--verbose`, son reproducciones de los OGG de ambiente del desierto (fogata, oasis, viento) vivas al salir
sin ventana; no crecen y no son de la carga (sonido/región).

## 6. Pruebas (aisladas, 12/11)

`prueba_cargas` (nueva), `prueba_precarga`, `prueba_precalentado`, `prueba_escenas`, `prueba_mar_cristal` y
`prueba_integridad`: superadas. **Batería completa: 131 · 0 · 58 · 0** (`D:\REBELUM_diagnostico\pruebas\2026-11-12_114026`;
partida y carpeta real sin cambios; «proyecto cambiado» porque durante la pasada se confirmó una opción de `medir_cargas` y
se escribió este informe). Capturas del aviso de carga: `D:\REBELUM_diagnostico\v12\cargas\fotos_aviso\` («Preparando el
combate…», «Cargando…»).

## 7. Para integrar (copiando)

- **Archivos nuevos** (copiar tal cual): `aethelgard/pruebas/prueba_cargas.gd`,
  `aethelgard/pruebas/herramientas/medir_cargas.gd`, `medir_cargas.ps1`, `listar_precarga.gd`.
- **Archivos compartidos** (`combate.gd`, `recursos.gd`, `carga.gd`, `zonas3d/mar_cristal/gusano.gd`,
  `pruebas/lista_pruebas.txt`): si nadie más los ha tocado desde `a0bab37`, copiarlos; si sí (`combate.gd` lo editan
  otros), aplicar el parche: `D:\REBELUM_diagnostico\v12\cargas\parches\*.patch` (`git diff a0bab37 HEAD`, por archivo).
- **Pendiente en el Redmi:** arranque, «Continuar» al Mar de Cristal, aviso → combate de Bramavidrio (v2, y v1/v3),
  repetir el combate, cerrar y volver a abrir la app (¿funciona la caché de sombreadores?) y PSS en la portada y tras
  varios combates.
