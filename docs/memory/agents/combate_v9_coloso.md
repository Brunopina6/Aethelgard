# Combate · V9, jefe 2: el Coloso de la Falla (10/11/2026)

Rama `claude/v9-coloso-combate` (copia `D:\Aethelgard_v9_coloso-combate`), sobre `45724ea`. Encargo: directiva V9,
jefe 2. Un guardián de piedra con inscripciones, jefe opcional de la Garganta 3D, con el Guardián del Bosque como
modelo y sin un sistema paralelo.

## 2026-11-10 18:45 · El Coloso de la Falla: combate, Garganta 3D, premio y pruebas

### Qué se ha hecho

- **`aethelgard/combate_coloso.gd`** (nuevo, solo cálculos, como `combate_bosque.gd`). Las reglas:
  - **Fase 1, «La piedra que vigila».**
    - Ataques: puñetazo (×1,25 a uno), lluvia de rocas (×0,5 a todos) y el Puño de la Falla (×2 a uno, avisado un
      turno antes).
    - **Piel de piedra:** los golpes físicos le hacen la mitad.
  - **Ventana.** Tras descargar su golpe cargado queda **expuesto** hasta su turno siguiente. En ese turno se recompone
    y no ataca.
    - Los golpes físicos hacen ×1,5, y los de Kael ×1,25 más (×1,875).
    - Tres brillos laten sobre sus juntas (sin partículas, para el perfil bajo), sale el rótulo «¡Puntos débiles!» y
      sobre su vida pone «✦ Expuesto».
    - Pide el sonido `coloso_expuesto` una vez (`_sonar`).
  - **Fase 2, «Las runas despiertan»** (al 50 %).
    - Destello ámbar, temblor, el escenario y el Coloso se tiñen de ámbar, aparecen chispas, cambia la música de fase
      2 y va ×1,25 más rápido.
    - Su golpe cargado pasa a ser el Derrumbe rúnico (×1,6 a todos).
    - **Cada turno suyo alterna** la coraza rúnica (la magia hace la mitad y la piel se abre) y la piel de piedra.
    - Cada cambio se avisa con un rótulo y se lee sobre su vida.
  - **Garon lee las inscripciones.** «Leer runas» en ESGRIMA, solo si hay un Coloso en pie.
    - Cuesta 3 PM y no hace daño.
    - La piel de piedra se apaga durante los 2 turnos siguientes del Coloso; la coraza rúnica no.
    - Es útil pero no obligatorio: la magia en la fase 1 y las ventanas bastan.
  - Ninguna función tira del generador aleatorio. Con otro enemigo, `dano_recibido` devuelve el daño tal cual.
- **`combate.gd`.** Se ha añadido o tocado:
  - las tablas: `ENEMIGOS["coloso_falla"]` (520 PV, 21 de ataque, 8 de velocidad, 80 de experiencia y 120 de oro,
    personalidad «coloso», con fases y título), `GRUPOS[12]`, `MODELOS` (respaldo 2D y entrada 3D) y `ANIM`;
  - el turno: `_turno_coloso`, `_accion_coloso`, `_avisos_coloso`, `_marcar_puntos`, `_coloso_vivo`,
    `_cambio_fase_coloso` y `_leer_runas`;
  - el daño, en `_animar_golpe`, `_magia_grupal`, Juicio y Giro (que van por su cuenta) y la réplica;
  - el resto: el estado sobre su vida (`_actualizar`), el premio en `_fin_combate`, «coloso» entre los que no huyen y
    `ALTO_DOBLE` para Érebo.
- **Premio, una sola vez.** Lo da el combate fijo `garganta_coloso`, apuntado en `combates_ganados`.
  - 2 de **Mineral rúnico**: `datos/materiales/mineral_runico.tres`, nuevo, la tienda lo compra por 140.
  - El **Fragmento de armadura antigua** (`equipo_extra.gd`, accesorio): empieza el combate con una coraza del 20 % de
    los PV (`barrera_inicio`, M3, ya enganchado).
  - Lo que explica cómo se consigue está en el `FUERA` de `hallazgos.gd`. `prueba_equipo` cuenta ahora 12 accesorios.
  - Perder no apunta nada, así que se puede reintentar. Repetirlo ya ganado no da más.
- **Garganta 3D.** En `zonas3d/garganta_3d.gd` y `zonas3d/garganta/coloso.gd` (nuevo):
  - **Dónde:** el Coloso duerme en el rincón sin salida del fondo de la grieta oculta, en (13,4, −8, −38,3), más allá
    del pilar del peregrino. No corta ningún camino.
  - **Al llegar** (2,4 m):
    - Kael se para y las runas se encienden.
    - Sale el aviso «Al fondo de la falla, un coloso de piedra alza la cabeza. Sus runas se encienden.». Si Garon va en
      el grupo, se añade «Garon: «Esas runas dicen cómo se cierra su piel. Puedo leerlas.»».
    - A los 2,8 s empieza el combate fijo (grupo 12, «jefe»).
    - Tras perder, se vuelve a (11, −8, −33,4), fuera del disparo.
  - **Ya vencido:** no está. Quedan placas caídas sin colisión y el aviso «Solo quedan placas de piedra con las runas
    apagadas.».
  - **La arena de Gorthor y el nido no se han tocado.**
- **Figura y respaldo.** Mientras no haya modelo propio se usa el guardián de piedra.
  - En la Garganta, a 4,4 m de alto, gris y con las runas de emisión ámbar.
  - En el combate, la imagen `enemigos/guardian.png` a 1,45, gris cálido; con la coraza rúnica, ámbar dorado.
  - El encuadre se corrigió con capturas: a 1,6, su vida y sus estados quedaban fuera de la pantalla.

### Pruebas (comprobado ejecutando, datos aislados, 10/11; código de `ca8096b` salvo donde se indica)

- **`prueba_coloso`** (nueva, «-- auto»): SUPERADA.
  - Fase 1: un golpe de 100 hace 50 y la magia hace 100.
  - Ventana tras el Puño: un golpe de verdad de Kael de 80 quita 150 (×1,875). Hay puntos débiles y su sonido suena
    una vez. Se recompone en su turno siguiente.
  - Leer runas: 3 PM, el menú se abre con la orden y la piel se abre 2 turnos.
  - Fase 2: con la coraza, un Fuego de verdad de Lya de 100 quita 50. Alterna a la piel. El Derrumbe alcanza a los
    tres.
  - Victoria con el premio; repetirlo no da más; perder no apunta nada.
- **`prueba_coloso_garganta`** (nueva, «-- 3d garganta3d sin_prologo»): SUPERADA.
  - El sitio, el aviso con Garon y el combate fijo.
  - Perder: vuelta fuera del disparo, sin repetir el combate; el pilar se examina.
  - Ganar: premio, el Coloso no reaparece ni despierta y la partida guardada lo lleva.
- **La batería pedida y las de la Garganta 3D,** todas SUPERADAS: `prueba_combate_huella`, `prueba_combate_seguro`,
  `prueba_guardian_bosque`, `prueba_escalado`, `prueba_equipo`, `prueba_hallazgos`, `prueba_garganta3d`,
  `prueba_garganta3d_tramo`, `prueba_datos` y `prueba_tienda_bosque`.
  - Resúmenes: `D:\REBELUM_diagnostico\pruebas\2026-11-10_183207\resumen.md` (el tramo, FALLIDA ahí, se corrigió) y
    `...\2026-11-10_183500\resumen.md`.
- **Huella del combate:** 9 de 9 combates iguales a la referencia, dos pasadas iguales. Huella completa `725aef4a…`;
  la referencia no se ha regenerado.
- **`prueba_garganta3d_tramo` falló a mitad del trabajo, por una causa mía, y está corregida** (`ca8096b`).
  - Esa prueba pone a Kael en (11,4, −36) para el comentario de la cascada, y ese punto quedaba dentro de mi disparo
    (2,76 m).
  - Comprobado: con la `garganta_3d.gd` de `45724ea`, SUPERADA; con la mía, FALLIDA.
  - Ahora ese punto queda a 3,05 m y `prueba_coloso_garganta` lo comprueba.
- **ci_local completo** (código `ca8096b`): SUPERADAS 97, FALLIDAS 0 y MANUALES 43 (las de ventana o a mano), «CI
  LOCAL: todo superado», y la partida real y el proyecto sin cambios. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-10_183551\resumen.md`.
- **Capturas** (`fotos_coloso`, con ventana): `D:\REBELUM_diagnostico\pruebas\2026-11-10_183006\fotos_coloso\`.
  Muestran el combate (inicio, Puño cargado, expuesto, cambio de fase y coraza) y la grieta.

### Límites

- **Equilibrio sin medir con un jugador.** Las pruebas fuerzan los turnos y rellenan vidas, así que no dicen si el
  combate es justo con la estrategia de una persona. Los números se eligieron frente a Gorthor (460 PV, 22 de ataque) y
  el Guardián (420, 17). Con el escalado, en la Garganta (base 7, jefe hasta 9) son hasta 603 PV y 24 de ataque.
- **Una prueba muda no demuestra cómo se oye.** Los sonidos `coloso_expuesto`, `coloso_coraza`, `coloso_piel` y
  `leer_runas` aún no existen; se piden con `_sonar` y no suenan. «Leer runas» usa de momento `misterio`. Las rocas
  usan un solo `Sonido.golpe`.
- **El Coloso no tiene voz:** `sonido.gd FAMILIAS` no conoce `coloso_falla`.
- **Las frases del aviso son propuesta,** no canon: las revisa narrativa.
- **No se ha comprobado en el móvil.**

### Observado en el código, fuera del encargo (sin tocar)

- **Juicio y Giro de Garon no pasan por `Bosque.dano_recibido`.** En `_tecnica_garon`, con su modelo 3D, quitan los PV
  directamente, así que la coraza de raíces del Guardián no reduce su daño. Para el Coloso sí lo he aplicado.
- **El respaldo 2D del Guardián del Bosque** (1,45 en y = −120) tiene el mismo encuadre que dejaba fuera la vida del
  Coloso. Hoy no se ve porque el Guardián usa su modelo 3D.

### Para enganchar el modelo 3D cuando llegue (de animaciones, `enemigos/coloso_falla/`)

1. El guion `coloso_falla_3d.gd` y `coloso_falla.glb` deben tener la interfaz de `guardian_bosque_3d.gd`:
   - `dormido_al_empezar` y `despertar()`;
   - `cargar("golpe_fuerte")`;
   - `atacar(ataque, al_golpear)`, que se espera con `await` y llama a `al_golpear` una vez; `ataque()`;
   - `fase2()`, `morir()` y `cansada(bool)`.
   Con `despertar`, `combate.gd` lo anima por `_anim_guardian`, desde su sitio.
2. En `combate_coloso.gd`, `MODELO_3D := true`: la figura dormida de la Garganta.
3. En `combate.gd`, `ENEMIGOS["coloso_falla"]["modelo"] = "coloso_falla"`. La entrada 3D de `MODELOS` ya existe y, sin
   el GLB, usa el respaldo 2D.
4. Ajustar el encuadre de `MODELOS["coloso_falla"]` (`vp`, `alto_vista`, `centro_y`, `barra_y`, `centro_3d`; hoy son
   los del Guardián) y quizá la posición de `GRUPOS[12]`. Para comprobarlo, `ejecutar_pruebas.ps1 -Manual -Solo
   fotos_coloso`.
5. Volver a pasar `prueba_coloso`, `prueba_coloso_garganta` y `prueba_combate_huella`.

### Cambios que pido en archivos de otros

- **Sonido** (`sonido.gd`):
  - `FAMILIAS["coloso_falla"] = "piedra"`, para que tenga voz;
  - si se quiere, efectos `coloso_expuesto`, `coloso_coraza`, `coloso_piel` y `leer_runas` (`combate.gd` ya los pide).
- **Narrativa:** revisar o sustituir `TEXTO_COLOSO` y `TEXTO_COLOSO_GARON` (`garganta_3d.gd`), y los nombres «Puño de
  la Falla», «Derrumbe rúnico» y «Coraza rúnica».
- **Gráficos:** si se quiere, un rincón propio para el Coloso en la grieta, como el Claro del Guardián.
