# RETOMAR la V12 (El Mar de Cristal)

Punto seguro del 11/11 a las 13:35 (sesión «REBELUM V12 desarrollo continuo»). Antes de seguir, lee
`D:\Aethelgard\CLAUDE.md` (protocolo) y `CONTINUAR_V12_NUEVA_SESION.md`, en la raíz de esta copia.

## Git

- **Trabajo:** `claude/rebelum-v12` en `D:\Aethelgard_v12`. Ver `git -C D:\Aethelgard_v12 log --oneline -15`.
- **Publicada en GitHub desde el 12/11** (autorización expresa del usuario): `origin/claude/rebelum-v12`, primera
  subida `d8a65d3`. Se suben a esa misma rama los hitos probados, sin force. **Sin merge** con `main` (`d4b2d16`),
  `desarollo` ni otras compartidas; sin releases. Las ramas `claude/v12-*` de los especialistas siguen locales. La
  integración de especialistas se hace copiando sus archivos de su rama (`git checkout <rama> -- <rutas>`), no
  fusionando ramas.
- **La sesión anterior** («Aethelgard documento base en Godot») está detenida desde las 12:50: no escribe en esta copia.
- **Especialistas, todos terminados e integrados:**

| Especialista | Rama @ commit | Integrado en | Informe |
|---|---|---|---|
| Narrativa | `claude/v12-desierto-narrativa` @ `1120cc2` | `b13bb11` | `docs/v12/NARRATIVA_DESIERTO.md` |
| Sonido | `claude/v12-desierto-sonido` @ `7b4d090` | `02717e6` | `docs/memory/agents/sonido_v12_desierto.md` |
| Gráficos | `claude/v12-desierto-arte` @ `2d15ef1` | `8658f6f` (archivos copiados) | `docs/memory/agents/graficos_v12_desierto.md` |

## Decisiones del usuario (11/11)

Aprobados: **Ismena** (cartógrafa) y **Oren** (su hermano); **Bramavidrio**, el gusano; el mural deja leer
**«…de los Espejismos»**; la recompensa es la **Aguja de Resonancia**. Todo lo demás sigue siendo propuesta.

## Hecho y probado (aislado, en el PC)

- **El Mar de Cristal se juega en pruebas:** `-- 3d mardecristal` o Ajustes → «Mar de Arena de Calid» → «Mar de Cristal
  3D (en pruebas)». `modo3d.gd` REGIONES[4] y EN_PRUEBAS.
- **Buscador de Kael** (`buscador.gd`, `buscador_hud.gd`): tiene/dar, área real del sector, únicos que esperan su hito
  (sello: `mc_caravana`; llave: `mc_ruinas`), sitios que evitan el estanque y las rocas, **MEJORAR** (nivel 2: 2
  Fragmentos de espada + 1 Mineral rúnico; nivel 3: 2 Reliquias de vidrio + 5 Monedas antiguas), la Aguja oye +2 m.
  La excavación ya acaba aunque la región esté «ocupada» (fallo encontrado por la prueba).
- **«La caravana perdida»** (`zonas3d/mar_cristal/mision.gd`): los 8 hitos `mc_*`, diálogos según el grupo, efectos
  aunque un diálogo se corte, tormenta de la misión que se repite si se recarga a medias, recompensa una vez (150
  monedas, buscador nivel 2, Aguja de Resonancia), Oren en el campamento, cofre del espejismo (una vez).
- **Tormenta** (`clima.gd`): niebla, luz, viento y arena; el buscador no oye y no se excava; amaina en el cobijo.
  Sonido por `musica.gd` (contextos `mar_cristal` −13 dB y `tormenta_arena` −9 dB).
- **Bramavidrio** (`gusano.gd`): aviso tras 3 s en la arena blanda, surco que avanza (5 m/s), rugido, se va si Kael
  sale; si no, emerge y lanza su combate fijo (`mc_bramavidrio`, grupo 13, «embiste» con sus frases). Vencido, solo
  asoma y se va. Foto de combate provisional (`enemigos/bramavidrio/bramavidrio.png`, de `foto_bramavidrio.gd`).
- **Gráficos en la región** (`terreno.gd`): ALIAS de nombres, piezas con su material y choques, arena con su sombreado,
  arena arrastrada, ondas de calor en alto, espejismo y trampilla con sus piezas; fogata con llamas y sonido 3D.
- **Dialogic:** Ismena, Oren y las 19 timelines `mc_*` registradas en `project.godot` (importación aislada).
  Ojo: la primera importación de una copia sin `.godot` vació esos directorios; se restauró. **Revisar siempre
  `git diff project.godot` tras importar.**
- **Pruebas superadas** (11/11, 13:00): `prueba_mar_cristal` (nueva), `prueba_buscador`, `prueba_equipo`,
  `prueba_hallazgos`, `prueba_audio_desierto`, `prueba_huir`. **Falta pasar la batería entera** tras tocar
  `combate.gd`, `menus.gd`, `modo3d.gd` y `musica.gd`.

## Luz, arena, rocas y Bramavidrio (13:00-13:35, con capturas en `D:\REBELUM_diagnostico\v12\`)

- **Batería completa:** 110 · 0 · 44 · 0 (pasada de las 13:00 con 7 fallos arreglados y repetidos a las 13:13: un
  error de tipos en `gusano.gd` y `prueba_musica`, que solo aceptaba WAV). Después de la luz, las 25 pruebas de
  regiones y `prueba_mar_cristal`, `prueba_integridad` y `prueba_precalentado`: superadas.
- **Arena naranja como lava:** el sombreado de gráficos multiplica su color por el color de vértice, y la malla de
  dunas traía colores de arena. Ahora el vértice es un matiz casi blanco; la luz del desierto es fría de cielo y cálida
  de sol (más bajo); los colores de arena se fijan desde `terreno.gd` (COLORES_ARENA). En alto: arena dorada, sin
  quemarse (captura `luz_131920\fotos\mar_cristal_alto.png`).
- **El perfil bajo oscurecía las regiones:** medido cambiando un valor cada vez, solo las sombras aclaran la escena en
  Compatibility. `vista3d.gd` sube el brillo final sin sombras por región (`brillo_sin_sombras`: Mar de Cristal 1,3,
  Garganta 1,2, Oakhaven 1,17; Pastos ya lo compensaba). Bajo/medio después: 0,792/0,792 · 0,406/0,405 · 0,283/0,285.
  Herramienta: `pruebas/herramientas/medir_luz_perfiles.gd` (con ventana; `sin_compensar`, `extra=`, `perfiles=`,
  `regiones=`, `pos=x,z`). La ventana a veces deja de dibujar a mitad de una pasada larga: mejor una región por pasada.
- **Rocas:** peñones y chimeneas (escala por forma, inclinación, bloque al pie) y paredes del cañón al oeste.
- **Bramavidrio provisional:** larva de segmentos con placas de vidrio y boca de placas planas; su foto de combate,
  inclinada hacia los héroes.
- **Rendimiento en el PC** (1280×720, al empezar, no vale para el Redmi): Mar de Cristal bajo 31 llamadas y 79 k
  primitivas; medio 52 y 158 k; alto 91 y 176 k (las sombras doblan las primitivas).

## Operación «Calidad y espectáculo» (encargo del 11/11, 14:30)

- **Fase 1 hecha** (`040bd00`…`8e328d9`), los 8 problemas del Redmi (`docs/v12/INFORME_REDMI_V12.md`): salida señalada
  (disco, «Mapa del mundo», postes) y se arma a 2,4 m; dunas lejanas sin choque (sin franja blanca); botón de acción
  oculto 1 s tras un diálogo; Bramavidrio en combate con la barra visible, sin plato de arena y «Bramavidrio cierra el
  paso» en HUIR (obligatorio; foto anterior en `bramavidrio_v1.png`); la tormenta no amaina con un diálogo abierto; el
  bajo del desierto con brillo 1,15 (antes 1,3: lavado en el Redmi; **falta verlo en el teléfono**); rocas bajas junto
  al cobijo; licencias registradas (`docs/recursos.md`, `docs/versiones/licencias_pendientes.txt`).
  `prueba_mar_cristal` comprueba la salida, la arena lejana y la tormenta con el diálogo abierto.
- **Especialistas lanzados a las 14:40** (ramas LOCALES, sin push ni merge):

| Encargo | Especialista | Copia | Rama | Informe esperado |
|---|---|---|---|---|
| Bramavidrio definitivo: concepto, modelo, rig y 10 clips en Blender, LOD, `bramavidrio_3d.gd` y la aparición en exploración | animaciones | `D:\Aethelgard_v12_bramavidrio` | `claude/v12-bramavidrio` | `docs/memory/agents/animaciones_v12_bramavidrio.md` |
| Pantalla principal alternativa (la original intacta; selector en Ajustes) | gráficos/interfaz | `D:\Aethelgard_v12_portada` | `claude/v12-portada` | `docs/memory/agents/graficos_v12_portada.md` |

- **15:40-16:45:** portada integrada (`48a3041`, accesos de pruebas solo en Auditoría o desarrollo: `bdcae73`; característica `auditoria` en su preset). Bramavidrio, pasada 1 entregada (`claude/v12-bramavidrio` @ `b4157a6`: 16 380/7 990/3 594 triángulos, 41 huesos, 10 clips, `bramavidrio_3d.gd`, exploración en `gusano.gd` con el provisional recuperable por `Engine.set_meta("bramavidrio_provisional", true)`), revisada: **aún no convincente** (cabeza de salchicha, dientes en bloque, rollos lisos, color plano, pequeño en combate): pasada 2 pedida al mismo especialista. Los tres ataques, en marcha con el especialista de combate en `D:Aethelgard_v12_bramavidrio_combate` (rama `claude/v12-bramavidrio-combate`, desde `b4157a6`; informe `docs/memory/agents/combate_v12_bramavidrio.md`).
- **17:00:** Bramavidrio pasada 2 en `claude/v12-bramavidrio` @ `4c5b759` (19 359/8 823/3 124 triángulos, 43 huesos; basalto oscuro, colmillos de cristal y hueso, mandíbulas laterales, escamas de pangolín; encuadre de combate medido: 61 % de la altura). Ya se lee como depredador; aún flojo: el vientre de frente, el aliento sin partículas, sin normales horneadas. Pasado al especialista de combate (que copia el modelo a su rama y usa el encuadre nuevo).
- **17:50:** integrados (copiando archivos, sin fusionar) el modelo (`dc9b5b2`) y los tres ataques (`9aa0d73`, `combate_bramavidrio.gd`; 1150 PV; Embestida a uno ×1,35; Fractura a todos ×1,2 con un turno de aviso, Defender la reduce; Aliento a todos ×1,9 con un turno de preparación, se corta con un 20 % de su vida o Quiebra; IA sin azar, sin dos especiales seguidos). En el combate el chorro 3D se esconde (salía hacia la cámara). Pruebas de combate, desierto y sonido: 16 de 16. **Incidente del especialista de combate:** a las 15:41 lanzó Godot una vez sin datos aislados; no tocó `partida.save` (fecha intacta), solo rotó el registro de Godot de la carpeta real (`logs/godot.log` y `godot2026-11-11T15.41.20.log`). Pendiente: batería completa, APK de Auditoría y Redmi; el vientre de frente aún flojo; los héroes se dibujan sobre el gusano caído; sin sonidos propios de succión, chorro y caída.
- **18:30:** batería completa en `a9317a3`: **114 · 0 · 47 · 0**. APK de Auditoría **v597** (`a9317a3`): `D:REBELUM_compilacionesAethelgard_androidauditora-20261111-a9317a3.apk`, 292,4 MB, SHA-256 `5dee787dd7040bf2c1135d85459af49ec36344578f98900955c955a10c3fb75f`, firma v2/v3 con el mismo certificado que la v581. **El Redmi estaba desconectado**: sin instalar ni medir. Respaldo bueno de la partida de Auditoría: `D:REBELUM_respaldos2026-11-11_redmi_auditoria_antes_v12` (el intento de las 18:25 salió vacío y se llama `..._v12b_FALLIDO_sin_movil`). Siguiente: con el Redmi conectado, respaldar, instalar (`adb install -r`), repetir el procedimiento de `INFORME_REDMI_V12.md` con Bramavidrio (sus tres ataques) y la portada alternativa, comparar con la v581 y restaurar la partida.
- **19:30:** v597 probada en el Redmi (`docs/v12/INFORME_REDMI_V12.md`, segunda parte): desierto igual que la v581 (30,4/30,4/23,6 FPS), combate con el modelo 3D 57 FPS (antes 62 con la foto), portada alternativa 36 FPS y +42 MB; salida, borde, Bramavidrio, HUIR y «Continuar» bien; sin cierres. Partida de Auditoría restaurada (respaldo `..._antes_v597`). Pendiente: bajo del desierto aún lavado en el teléfono; Fractura y Aliento vistos solo en el PC.
- **20:00:** el usuario eligió **la pantalla de inicio nueva** como la de por defecto: `portada/eleccion.gd` (sin elección, la nueva; «Original» en Ajustes o `-- portada_original`, la de siempre); la opción sale ya en cualquier versión. La original (`carga.tscn`, logo incluido) sigue entera y es la escena principal. Las pruebas de la pantalla original la piden con `portada_original` en `lista_pruebas.txt`. Falta compilar una APK con este cambio (la v597 aún tenía la original por defecto).
- **18:40, el clímax de los grandes jefes** (`docs/v12/MUSICA_JEFES.md`): el especialista de combate lo hizo en `claude/v12-climax` @ `c47a9e3` (copia `D:\Aethelgard_v12_climax`); integrado copiando archivos en `d8af093` y `b7daacc` (los `.uid`). `combate_climax.gd` (solo Bramavidrio activo; se apaga con `ACTIVO = false` o el «activo» del jefe) y ganchos «V12, clímax» en `combate.gd`. Batería completa: 115 · 2 · 47 · 0; las 2 fallidas solo porque esta copia no había importado el OGG nuevo (tras `--import`, 4 de 4: `D:\REBELUM_diagnostico\pruebas\2026-11-11_183717`). **Una copia recién creada o con audio nuevo necesita `--import` antes de las pruebas.**
- **18:41, APK de Auditoría v607** (`b7daacc`): `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261111-b7daacc.apk`, 301,8 MB, SHA-256 `f99aba25913f1935282c50025491ef0868bc071e9c7da9470e446a7b55e2f7b9`, mismo certificado `3413edcd…7785f3`, con las tres canciones de Suno Pro. **Publicada (autorizado por el usuario: «lanza el apk a github»)** en el repositorio privado `Brunopina6/Aethelgard-pruebas`: release «11/11/2026 · Prueba v607», etiqueta `exp-20261111-b7daacc` sobre el commit del README `ad80346`, archivo `Aethelgard_Auditoria_2026-11-11_v607.apk`, Latest. README: fila nueva, «tres apps» y la nota de Suno Pro. Sin push de código.
- **Redmi, 19:10:** v607 instalada por el usuario desde Descargas (MIUI canceló `adb install -r`) y probada (`docs/v12/INFORME_REDMI_V12.md`, tercera parte): portada 36,8 FPS · 762 MB; clímax en el teléfono bien («¡Momento decisivo!» tras el golpe que lo deja en 213/1134) y 57,2 FPS durante la canción; Pastos con «Pastoral Pulse» 30,4 FPS · 828 MB; la Fractura vista por fin en el teléfono. Partida de Auditoría restaurada idéntica (respaldo `..._antes_climax`). Pendiente: el aviso «¡Momento decisivo!» toca el menú en el teléfono (centrarlo en el campo de batalla); escuchar las tres canciones y el volumen del clímax; los argumentos de pruebas no llegan en Android.
- **20:08, v610 (`63832d4`, SIN publicar: el usuario pidió no publicar nada más hasta autorizarlo) validada en el Redmi** (`INFORME_REDMI_V12.md`, cuarta parte): clímax al 20 % con el aviso ya en el campo de batalla; matarlo de un golpe no lo activa; Embestida 55-58 FPS, Fractura 55-58 (aviso 46,6), Aliento 53-56; 0 fotogramas perdidos; partida restaurada (respaldo `..._antes_v610`). Pendientes: héroes sobre el gusano caído y dentro de su boca, chorro del Aliento casi invisible, sonidos propios de Bramavidrio, perfil bajo del desierto lavado, escuchar todo el audio.
- **Rediseño de Bramavidrio:** hecho por el especialista de animaciones (ver 20:40).
- **Pastoral Pulse:** el archivo que mandó de nuevo el usuario es idéntico (mismo SHA-256) al integrado. Demos para escucharlo en `D:\REBELUM_musica\demos` (empalme corto y 6:16 como en el juego). Sigue elegible y no por defecto hasta que lo apruebe.
- **20:40, Bramavidrio v2 «la Sierpe de la Vela» integrado** (`3699144`, de `claude/v12-bramavidrio2` @ `d553666`, copiando archivos):
  - **Propuestas:** las tres, en `D:\REBELUM_diagnostico\animaciones\2026-11-11\bramavidrio2\conceptos\` (A: la Sierpe de la Vela, la elegida; B: el Gran Tragador; C: la Cobra Vitral).
  - **Modelo y versiones:** 15 197, 5 528 y 2 430 triángulos; mismo contrato de clips. La v2 está por defecto y la v1, intacta: se cambia en Ajustes («Bramavidrio: Nuevo / Anterior», `[bramavidrio] version`) o con `VERSION_DEFECTO` en `enemigos/bramavidrio/bramavidrio_version.gd`.
  - **Arreglo:** el cono negro del chorro de la v1 (`discard`).
  - **Pruebas:** con la v2 y con la v1, superadas.
  - **Sin medir en el Redmi.**
  - **En curso:** el especialista de combate hace los efectos de la Fractura (temblor, placas y arena), la succión y el chorro del Aliento, el impacto de la Embestida y la superposición con los héroes. Trabaja en `D:\Aethelgard_v12_brama_efectos`, rama `claude/v12-bramavidrio2-efectos`, desde `3699144`.
- **22:06, v615 (`7b9b71e`, SIN publicar) con la v2 y sus efectos (integrados en `7b9b71e` desde `claude/v12-bramavidrio2-efectos` @ `4efd62f`) medida en el Redmi** (`INFORME_REDMI_V12.md`, quinta parte): combate en medio con 58,9 FPS de media, 47,5 de mínimo al empezar a aspirar el Aliento y 0 perdidos; en alto, 50-57. Falta el perfil bajo, los sonidos de los ataques y que el usuario elija la v2 o la v1 (Ajustes → «Bramavidrio»).
- **Antes, el especialista de combate hizo los tres ataques** (Embestida del Abismo, Fractura del Mar de Cristal y
  Aliento del Desierto Eterno) en `claude/v12-bramavidrio`, sobre el modelo; luego se integra todo, batería, APK de
  Auditoría y medida en el Redmi frente a la v581. Referencia de presencia del usuario (de terceros, solo inspiración):
  `D:\REBELUM_diagnostico\v12\referencias\bramavidrio_presencia_referencia.webp`.
- **Bramavidrio anterior recuperable:** el provisional de `gusano.gd` (`_modelo_gusano`) se usa si falta el GLB; la
  foto anterior, `enemigos/bramavidrio/bramavidrio_v1.png`.

## Siguiente (en este orden)

1. **Probado en el Redmi el 11/11 (v581, `42d79d9`): `docs/v12/INFORME_REDMI_V12.md`.** Arreglar sus problemas 1-5
   (salida sin señal y borde del mundo, SEGUIR solapado con la acción, Bramavidrio en combate, tormenta con diálogo
   abierto, bajo lavado en el teléfono) antes de seguir.
2. Enemigos del desierto al azar: Vidracrán y Tolvanera (nombres de narrativa, sin aprobar).
3. Ismena y Oren tienen figura provisional (cápsulas): pedir modelos a gráficos o animaciones.
4. Bramavidrio: GLB de gráficos (el provisional sirve para probar).
5. Volúmenes del desierto sin escuchar (nadie los ha oído).
6. Memoria del proyecto (`D:\Aethelgard`: SESSION_HANDOFF, TASKS…) sin actualizar con la V12: sin push (orden del
   usuario).

## Notas

- `--check-only` sin autoloads da «Identifier not found: Sonido» en cualquier guion que lo use: no es un error.
- Con `--fixed-fps 30` sin ventana, los fotogramas van más rápido que el reloj: lo que carga en un hilo (el combate)
  se espera en milisegundos reales.

## Noche del 11 al 12/11: desarrollo autónomo (el usuario duerme; sin Redmi)

- **Punto de recuperación:** etiqueta local `v12-antes-noche-20261111` (= `373e7db`). Sin push, sin merges, sin releases.
- **Especialistas lanzados** (cada uno en su copia y su rama local, con archivos separados; se integra copiando archivos):

| Trabajo | Copia · rama (desde) | Archivos suyos | Informe |
|---|---|---|---|
| Bramavidrio v3: cabeza, boca, variantes y animaciones | `D:\Aethelgard_v12_bramavidrio3` · `claude/v12-bramavidrio3` (`373e7db`) | `enemigos/bramavidrio/v3/`, `fuente/crear_bramavidrio3.py`, `bramavidrio_version.gd` (v3 elegible; **por defecto sigue la 2**), el bloque «Bramavidrio» de `menus.gd`, `prueba_bramavidrio_modelo` | `docs/memory/agents/animaciones_v12_bramavidrio3.md` |
| Sonido de Bramavidrio | `D:\Aethelgard_v12_sonido_brama` · `claude/v12-sonido-bramavidrio` (`373e7db`) | `audio/bramavidrio/`, claves nuevas de `sonido.gd`, llamadas en `combate_bramavidrio.gd` (es el único que lo edita) y quizá en `gusano.gd` | `docs/memory/agents/sonido_v12_bramavidrio.md` |
| Mar de Cristal: perfil bajo lavado y riqueza visual | `D:\Aethelgard_v12_arte2` · `claude/v12-desierto-arte2` (`373e7db`) | `zonas3d/mar_cristal/terreno.gd`, `clima.gd`, `mar_cristal_3d.gd/.tscn`, `materiales_arte.gd`, `modelos/desierto/` | `docs/memory/agents/graficos_v12_desierto2.md` |
| Ismena, Oren, Vidracrán y Tolvanera: conceptos y prototipos apagados | `D:\Aethelgard_v12_personajes` · `claude/v12-personajes-desierto` (`373e7db`) | `personajes/desierto/`, `enemigos/vidracran/`, `enemigos/tolvanera/`, pruebas propias | `docs/memory/agents/animaciones_v12_desierto_personajes.md` |
| Exploración en Pastos Verdes (y Oakhaven si da tiempo) | `D:\Aethelgard_v12_exploracion` · `claude/v12-exploracion` (`9f85e77`) | `zonas3d/pastos_verdes_3d.*`, `bosque_pastos.gd`, Oakhaven 3D | `docs/memory/agents/narrativa_v12_exploracion.md` |

- **Hecho por el coordinador:**
  - **Música revisada:** los tres OGG están y pasan sus pruebas.
  - **Clímax a −4,5 dB** (`9f85e77`): medido con `ebur128`, a −7 dB sonaba 2,7 dB por debajo de la música que sustituye.
  - **No existe música de jefe:** `musica_jefe*`; los jefes usan la normal (`MUSICA_JEFES.md`).
  - **Pantalla de inicio en 1600×720, 1024×768 y 2340×1080:** sin errores y legible, con carga de 7,8-9,5 s en el PC
    (`D:\REBELUM_diagnostico\v12\portada_resoluciones`).
  - **Propuesta, sin hacer:** con `stretch/aspect` por defecto el juego entero sale con franjas negras en 20:9. Cambiarlo
    afectaría a toda la interfaz.
- **La noche, cerrada a las 23:35:** todo integrado y batería final 120 · 0 · 50 · 0. Informe: `docs/v12/INFORME_NOCHE_12_11.md`. Los cinco especialistas terminaron; sus ramas y copias se conservan.
- **Si la sesión se corta:**
  1. mira el estado de cada copia (`git -C <copia> log --oneline -5` y su informe);
  2. integra lo terminado copiando archivos (como siempre);
  3. pasa la batería completa;
  4. no des por buenos los prototipos.

### Segunda gran fase (empezada el 12/11 a las 23:40)

**Qué abarca:**
- personajes (Kael, Lya y Garon) más expresivos;
- enemigos con identidad y mecánica propias;
- todas las ubicaciones jugables a 3D, por regiones completas y sin perder contenido;
- la escuela de magia negra: fuego, hielo, rayo, sombras, gravedad y debilitamiento, con progresión e investigación conectadas a los sistemas que ya hay;
- un cuarto protagonista, «Naira, la Astrónoma del Eclipse» (provisional; tres conceptos antes de elegir; su historia, contrastada con la biblia).

**Orden:** A auditoría, B protagonistas, C enemigos, D migración 3D, E magia negra, F Naira y G integración.

**Normas:**
- todo con Blender (GLB), animaciones mínimas y modelos originales conservados;
- tres combatientes activos y el resto en reserva, salvo que no sea compatible;
- sin push, merge ni publicaciones;
- sin Redmi.

**En marcha** (copias locales desde `1b8f720`):

| Trabajo | Copia · rama | Entrega |
|---|---|---|
| Fase A, la auditoría (solo documentos) | `D:\Aethelgard_v12_auditoria` · `claude/v12-fase2-auditoria` | `docs/v12/FASE2_AUDITORIA.md` |
| Naira: historia, contrastada con la biblia, NO canon | `D:\Aethelgard_v12_naira_historia` · `claude/v12-fase2-naira-historia` | `docs/v12/NAIRA.md` |
| Naira: tres conceptos 3D y quizá un modelo provisional | `D:\Aethelgard_v12_naira_concepto` · `claude/v12-fase2-naira-concepto` | `docs/memory/agents/animaciones_v12_naira.md` |

Después de la auditoría vienen B (protagonistas, con respaldo), C (enemigos), D (migración región a región) y E (magia
negra).

**La auditoría está integrada** (`c703625`, `docs/v12/FASE2_AUDITORIA.md`). Segunda tanda, desde `c703625`:

| Trabajo | Copia · rama | Archivos suyos |
|---|---|---|
| D: la Garganta 3D completa (Báculo del Peregrino, notas) y por defecto, con la 2D elegible | `D:\Aethelgard_v12_garganta` · `claude/v12-fase2-garganta` | `zonas3d/garganta*`, `modo3d.gd`, `hallazgos.gd` (compartible) |
| E: escuelas de magia negra, tabla de debilidades, estados e investigación | `D:\Aethelgard_v12_magia` · `claude/v12-fase2-magia` | **el único que edita `combate.gd`, `artes.gd`, `grupo.gd` e `investigacion.gd`** |
| B: rig común y clips de los héroes, materiales y retrato de Garon (apagado) | `D:\Aethelgard_v12_heroes` · `claude/v12-fase2-heroes` | `personajes/` (nuevos), sus pruebas |

**Siguen en marcha:** Naira (historia y conceptos).

**Avance de la fase 2 (madrugada del 12/11):**
- **Naira:** propuesta NO canon integrada (`87a37c9`, `docs/v12/NAIRA.md`, con 10 decisiones para el usuario) y modelo PROVISIONAL del concepto A, sin enganchar (`4f9e93b`). Los conceptos A, B y C están en `D:\REBELUM_diagnostico\animaciones\2026-11-12\naira\conceptos\`.
- **La Garganta 3D, por defecto** (`36a84c2`): Báculo del Peregrino, 4 notas y brazalete con `zonas3d/examinables_3d.gd`; la 2D sigue elegible y las partidas son compatibles en los dos sentidos.
- **En marcha:**
  - la magia negra (`D:\Aethelgard_v12_magia`, desde `c703625`; **dueño de `combate.gd`, `artes.gd`, `grupo.gd` e `investigacion.gd`**);
  - los héroes (`D:\Aethelgard_v12_heroes`, desde `c703625`);
  - Oakhaven 3D completo (`D:\Aethelgard_v12_oakhaven`, desde `36a84c2`).
- **Después:**
  - **C, los enemigos:** por región, y Vidracrán, Tolvanera y Cencerrante en los encuentros. Va después de la magia, porque toca `combate.gd`.
  - **El grupo con reserva** (base para Naira): también después de la magia.
- **Héroes v2 integrados APAGADOS** (`92a511d`). Para encenderlos faltan:
  - `combate.gd:1325` y `:4208` (`HeroesV2.script_de(...)`), después de la magia;
  - `vista3d.gd:48` y `grupo_3d.gd:157`, después de Oakhaven;
  - enganchar `garon.dch` a los retratos nuevos;
  - pulir la victoria de Kael (en la v2 la espada queda detrás de la cabeza).
- **En marcha también:** C, los modelos propios del Guardián de piedra, el Gólem de ámbar y Gorthor
  (`D:\Aethelgard_v12_enemigos`, desde `92a511d`; sin tocar `combate.gd`).
- **02:10, después del corte por límite de uso (a la 1 h aprox.):**
  - **Magia negra integrada APAGADA** (`fa0a818`, interruptor `magia_negra_v12`): 24 hechizos en 6 escuelas, tabla de afinidades y taller arcano en borrador. Batería: **123 · 0 · 54 · 0**.
  - **Héroes v2:** enganchados en `combate.gd` (siguen apagados).
  - **Oakhaven y enemigos:** se reanudaron con SendMessage después del corte.
  - **F, en marcha:** el grupo con reserva y Naira como combatiente APAGADA (`D:\Aethelgard_v12_grupo`, desde `fa0a818`; dueño de `grupo.gd`, `combate.gd`, `magia_negra.gd`, `artes.gd`, `inventario.gd`, `menus.gd` y `grupo_3d.gd`).
  - **Pendientes de la magia:**
    - las claves `negra_*` de `sonido.gd`;
    - el botón del taller arcano en `menus.gd` y su título en `alquimia_menu.gd`;
    - que la tabla de afinidades se aplique a las 12 magias de siempre: lo decide el usuario.
- **03:00:**
  - **Oakhaven 3D completo y por defecto** (`9f02435`; batería **124 · 0 · 55 · 0**).
  - **Modelos de enemigos integrados SIN enganchar** (`cc3557d`; parche en `pruebas/herramientas/parche_enemigos_v12.gd`). Hay que aplicarlo en `combate.gd` detrás de un interruptor después de integrar el grupo. Gorthor nuevo es más sencillo que el actual: no sustituir sin comparación.
  - **En marcha:**
    - el grupo con reserva y Naira (`D:\Aethelgard_v12_grupo`);
    - el sonido de la magia negra (`D:\Aethelgard_v12_sonido_magia`);
    - el Gran Bosque Verde 3D (`D:\Aethelgard_v12_gran_bosque`, desde `cc3557d`).
- **03:30:**
  - **Integrados** (`73a4cef`, `3e032c3`):
    - el grupo con reserva y la Formación;
    - Naira combatiente APAGADA (`naira_v12`);
    - los enemigos v12 enganchados en `combate.gd` detrás de `enemigos_v12` (APAGADO);
    - los 20 sonidos de la magia negra, con `naira_eclipse` provisional;
    - los héroes v2 enganchados en exploración y combate (APAGADOS).
  - **Batería:** 127 · 1 · 57 · 0. La fallida (la clave del Eclipse) está arreglada y repetida.
  - **En marcha:**
    - el Gran Bosque Verde 3D;
    - la misión de Naira como prototipo apagado (`D:\Aethelgard_v12_naira_mision`, desde `3e032c3`).
  - **Para probar con todo encendido:** `-- heroes_v2 magia_negra_v12 naira_v12 enemigos_v12`, o la meta de Engine de cada uno.
- **04:40, segunda gran fase cerrada en esta sesión** (informe: `docs/v12/INFORME_FASE2.md`):
  - **Integrado:**
    - Gran Bosque Verde 3D por defecto (`461df04`);
    - la misión de Naira, apagada (`f8cb979`);
    - `prueba_equilibrio` con semilla fija (`b719ea0`).
  - **Batería final:** **130 · 0 · 58 · 0**.
  - **APK de Auditoría v646** (`b719ea0`, SIN publicar ni instalar):
    `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261112-b719ea0.apk`, 371,3 MB (60 MB más que la v615), SHA-256
    `652273eff55844fa32f199b15ea759e77454413c580eb220b0749e7a01689883`, el mismo certificado.
  - **Siguiente:**
    1. con el Redmi, medir la Garganta, Oakhaven y el Gran Bosque 3D, y comparar lo apagado (interruptores en el informe);
    2. las decisiones del usuario;
    3. migrar las Cumbres y el Valle;
    4. encuentros por región.
  - **Etiqueta de recuperación:** `v12-antes-noche-20261111`. Hay 30 commits locales desde ella.

### Reanudación del 12/11, 09:10: validación previa al Redmi

- Rama comprobada: `claude/rebelum-v12`, HEAD `5ac3971`; sin cambios en archivos seguidos al iniciar. `.agents/` y `.codex/` ya estaban sin seguimiento y se conservan.
- Memoria remota consultada solo en lectura: `806d4a9`, coincide con la copia local. Sin push, fusiones ni publicaciones.
- APK existente verificada: `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261112-b719ea0.apk`, versionCode 646, paquete `com.aethelgard.auditoria`, etiqueta «REBELUM Auditoría». SHA-256 `652273eff55844fa32f199b15ea759e77454413c580eb220b0749e7a01689883`. Firma v2/v3 válida, certificado SHA-256 `3413edcd8c11ec1ce77a64566da5ed17582b4a2b31b869ccaeb0a120d17785f3`.
- Pruebas repetidas sobre HEAD: 7 superadas, 0 fallidas (guardado, partida, Bramavidrio, clímax, Garganta, Oakhaven y Gran Bosque). Evidencia local: `.verificacion-local/redmi_v646/2026-11-12_090655/resumen.md`. No se ha repetido la batería completa de 130.
- Los 170 archivos de datos reales del PC y la partida mantienen sus huellas. El aviso «proyecto cambiado» corresponde a la nueva carpeta de registros sin seguimiento; `git diff` vacío antes de añadir esta nota.
- Limitaciones del entorno: CIM denegado, por lo que el contador de otros procesos Godot del ejecutor no es una comprobación fiable. La sonda sí confirmó user:// aislado. Garganta dejó avisos de recursos/ObjectDB pendientes al cerrar, pese a terminar con 0 fallos: revisar su limpieza aparte.
- El usuario informa que el móvil está conectado. ADB no pudo iniciar dentro del entorno restringido; la solicitud de acceso USB ampliado fue rechazada. No se conoce la versión instalada, no se ha respaldado ni modificado la partida del teléfono, no se ha instalado nada ni medido FPS Android en esta sesión. No insistir por otra vía para eludir el rechazo.
- Siguiente: cuando se permita acceso USB, identificar Redmi y versión instalada, respaldar y verificar Auditoría antes de cualquier escritura, y validar v646: Garganta, Oakhaven y Gran Bosque en bajo/medio; luego comparaciones opcionales. Conservar todas las otras apps y partidas. APK sin publicar.
- **09:10-09:45, esta sesión (con ADB):**
  - **v646 validada en el Redmi:** el Gran Bosque no llegaba (27 en bajo, 14 en medio) y lo demás iba a 30 (`INFORME_REDMI_V12.md`, sexta prueba). Partida restaurada.
  - **Gran Bosque optimizado** (`e8f59cb`); APK v649 (`e8f59cb`) para medirlo.
  - La nota de arriba la escribió otra sesión (sin ADB) mientras tanto; se conserva.

### Hito «Siguiente hito de calidad» (12/11, desde las 10:45; el Redmi, desconectado)

- **Punto de recuperación:** etiqueta `v12-antes-hito-calidad` (= `a0bab37`).
- **Estado comprobado:**
  - HEAD `a0bab37`;
  - el Gran Bosque optimizado en `e8f59cb`;
  - la APK v649 (`e8f59cb`) existe, **sin instalar**; el Redmi tiene la v646.
- **Música verificada:** las rutas reales son las tres canciones elegidas y los originales de `D:\REBELUM_musica\maestros` tienen el mismo SHA-256 que los de Descargas. Pruebas de música, título, clímax, portadas y foco: 8/8.
- **En marcha:**

| Trabajo | Copia · rama |
|---|---|
| Cargas sin esperas a ciegas (es el dueño de `carga.gd`, `recursos.gd`, la carga de `combate.gd` y `gusano.gd`) | `D:\Aethelgard_v12_cargas` · `claude/v12-hito-cargas` |
| Pulir Bramavidrio (es el dueño de `enemigos/bramavidrio/**` y `combate_bramavidrio.gd`) | `D:\Aethelgard_v12_brama_pulido` · `claude/v12-hito-brama-pulido` |
| Una interacción opcional del Mar de Cristal (es el dueño de `mision.gd`/`rincones.gd` y del enganche en `mar_cristal_3d.gd`) | `D:\Aethelgard_v12_mc_interaccion` · `claude/v12-hito-mc-interaccion` |

- **Después:**
  1. el encuentro nuevo del desierto (toca `combate.gd`), cuando acabe el de las cargas;
  2. la validación en Android, cuando vuelva el Redmi.
- **12:20:**
  - **Integrado** (`a23e131`):
    - las cargas: precarga filtrada, aviso honesto sin cifras ni dobles toques, Bramavidrio preparado al entrar en la región;
    - el pulido de Bramavidrio: el orden de la v3 estable.
  - **Batería:** **132 · 0 · 60 · 0**.
  - **v649 medida en el Redmi:** el Gran Bosque va a 30 en bajo y a 21-25 en medio; del aviso al combate, ≤ 2,5 s y sin negro (`INFORME_REDMI_V12.md`, séptima prueba).
  - **En marcha:**

| Trabajo | Copia · rama | Notas |
|---|---|---|
| **Bramavidrio v4, «el Ancestral»**, fiel a la referencia del usuario | `D:\Aethelgard_v12_bramavidrio4` · `claude/v12-bramavidrio4` | Referencia: `D:\REBELUM_diagnostico\v12\referencias\bramavidrio_v4_referencia_usuario.png` (de `Downloads\Concepto del gusano de arena ancestral.png`, SHA-256 `3a6044c0…a904c5d18`, aportada por el usuario; licencia sin registrar). Es dueño de `enemigos/bramavidrio/**`, `bramavidrio_version.gd`, el bloque Bramavidrio de `menus.gd` y el origen del chorro en `combate_bramavidrio.gd`. Elegible; `VERSION_DEFECTO` sigue en 2 |
| Encuentro nuevo del desierto (Vidracrán o Tolvanera, detrás de un interruptor apagado) | `D:\Aethelgard_v12_encuentro` · `claude/v12-hito-encuentro-desierto` | Es dueño de `combate.gd` |

  - **Pendiente:**
    1. una APK nueva para medir en el Redmi las cargas (arranque, «Continuar», del aviso al combate, caché de sombreadores) y la memoria;
    2. la decisión del usuario sobre la caída de la Fractura y los sitios de golpe por versión (ver el informe del pulido).
- **13:20, en cola tras el Bramavidrio v4: Humbaba**, el jefe del bosque profundo (`docs/v12/ENCARGO_HUMBABA.md`, con la
  referencia en `D:\REBELUM_diagnostico\v12\referencias\humbaba_referencia_usuario.webp`).
  - **Herramientas:** Blender. **No usar Hunyuan3D:** su licencia excluye la UE.
  - **Encaje:** jefe nuevo, que no sustituye al Guardián del Bosque. Sitio propuesto: el Gran Bosque Verde, apagado.
  - **El usuario no quiere que se le pida permiso.** El Redmi, desconectado.
- **v656 medida en el Redmi:** la carga del título baja de 19,2 a 10,6 s y la memoria unos 200-250 MB
  (`INFORME_REDMI_V12.md`, octava prueba).
- **14:30, Bramavidrio v4 integrado** (`fb8b680`, de `claude/v12-bramavidrio4` @ `acfbb52`, copiando archivos): elegible
  en Ajustes («Prueba v4: el Ancestral»); **por defecto sigue la v2**. Batería 132 · 1 · 60 · 0; el fallo,
  `prueba_mc_rincon`, era inestable y ya está arreglado (5/5). v1, v3 y v4, 4/4 cada una. Procedencia en
  `docs/recursos.md`.
- **Informe final del hito:** `docs/v12/INFORME_HITO_CALIDAD.md`.
- **En marcha: Humbaba** en `D:\Aethelgard_v12_humbaba` · `claude/v12-humbaba` (desde `2c0f872`), especialista de
  animaciones con `ENCARGO_HUMBABA.md`: primero el prototipo con rig y tres animaciones; apagado (`humbaba_v12`).

### Rendimiento, personajes y estabilidad (12/11, tarde; sin Redmi)

- **Informe:** `docs/v12/INFORME_RENDIMIENTO_PERSONAJES.md` (todo medido en el PC; la lista para el Redmi está en su §9).
- **Punto de recuperación:** etiqueta `v12-antes-rendimiento-personajes` (= `fadb5fa`).
- **Commits:**
  - `e283167`: medida reproducible (`pruebas/medir_escenas.gd` y `.ps1`, `resumir_medidas.ps1`) y terreno guardado entre entradas. Vuelta del combate al Mar de Cristal 1,83 → 0,78 s; a Pastos 1,62 → 1,05 s.
  - `cb82455`: Humbaba APAGADO y héroes v2 pulidos, elegibles en Ajustes.
  - `ca71cd7` y `21dd706`: texturas comprimidas (héroes v2, Garon, goblin, Guardián). Memoria de vídeo −11 a −31 MB por región; con los v2, −102 MB.
- **Batería:** 135 · 0 · 63 · 0.
- **APK de Auditoría v665** (`21dd706`): en `D:\REBELUM_compilaciones\`, SHA-256 `851583…afb2`, firma `3413edcd…7785f3`. Sin instalar ni publicar.
- **Especialistas:** los de Humbaba (`claude/v12-humbaba` @ `be9d435`) y del pulido de héroes (`claude/v12-heroes-pulido` @ `bc91a47`) han terminado y están integrados. No hay ninguno en marcha.
- **Siguiente:**
  1. medir en el Redmi lo de la §9 del informe;
  2. decidir qué se deja de precargar en el arranque (184 MB);
  3. arreglar los tirones del primer combate.

### Expansión del mundo y evolución de personajes (12/11, noche; sin Redmi)

- **Encargo:** «REBELUM V12 — Expansión del mundo y evolución de personajes» (subida a GitHub, rendimiento, gráficos,
  combate, mundo 3D, NPC chibi, accesorios y el tablero de Orbes Cristalinos «Firmamento de los Ecos»).
- **Fase 0 hecha:** rama publicada, `origin/claude/rebelum-v12` = `d8a65d3` (comprobado con `ls-remote`); `main`
  sigue en `d4b2d16` y `desarollo` en `2d1adc4`. Revisado antes: sin claves de firma ni tokens, sin archivos de más
  de 20 MB; los 86 sonidos nuevos en el remoto tienen licencia registrada (Sonniss GDC y Suno Pro del usuario).
- **Punto de recuperación:** etiqueta local `v12-antes-expansion` (= `d8a65d3`).
- **Reglas comunes de los especialistas:** `D:\REBELUM_diagnostico\v12\expansion\REGLAS_COMUNES.md`.
- **Especialistas lanzados** (desde `d8a65d3`, copias y ramas locales, se integra copiando archivos):

| Trabajo | Copia · rama | Archivos suyos | Informe |
|---|---|---|---|
| Rendimiento: Gran Bosque, tirones del primer combate, creación del grupo, arranque | `D:\Aethelgard_v12_rend2` · `claude/v12-rend2` | `zonas3d/gran_bosque*`, vegetación, `carga.gd`, `recursos.gd`, precalentado | `docs/memory/agents/rendimiento_v12_rend2.md` |
| Tablero de Orbes Cristalinos: 3 conceptos, prototipo, tablero funcional | `D:\Aethelgard_v12_orbes` · `claude/v12-orbes` | servicio y tablero nuevos; bloques en `grupo.estadisticas()`, final de `efectos_de()`, `menus.gd`, guardado | `docs/memory/agents/interfaz_v12_orbes.md` |
| Accesorios y equipamiento | `D:\Aethelgard_v12_accesorios` · `claude/v12-accesorios` | `equipo_extra.gd` (ACCESORIOS, EFECTOS), ganchos en `combate.gd` | `docs/memory/agents/rpg_v12_accesorios.md` |
| Inventario del mundo, NPC chibi y Oakhaven vivo | `D:\Aethelgard_v12_mundo` · `claude/v12-mundo` | `docs/v12/INVENTARIO_MUNDO.md`, `personajes/npc_v12/`, Oakhaven 3D | `docs/memory/agents/mundo_v12_npc.md` |
| Animación de combate, cámaras y efectos | `D:\Aethelgard_v12_combate2` · `claude/v12-combate2` | clips de los héroes v2, módulo de animación de combate, cámaras, `vfx/` | `docs/memory/agents/animaciones_v12_combate2.md` |

- **Bramavidrio v5** (cabeza, boca y mandíbula, movimientos; la v4 intacta y la v2 por defecto): `D:\Aethelgard_v12_bramavidrio5` · `claude/v12-bramavidrio5` (desde `83d7774`), informe `docs/memory/agents/animaciones_v12_bramavidrio5.md`.
- **Programas del PC:** el usuario pide usar todo lo instalado; inventario en la sección final de `REGLAS_COMUNES.md`.
- **En cola** (cuando acabe alguno): geometría nueva de los
  protagonistas con Blender.
- **Integrado y subido** (todo APAGADO salvo las optimizaciones sin cambio visible; `origin/claude/rebelum-v12` = `b3c4e0f`, `main` intacta):
  - `16edd37`: accesorios v12 (`accesorios_v12`), 11 objetos; diseño en `docs/v12/ACCESORIOS_V12.md`.
  - `fa80e3e`: Firmamento de los Ecos, tablero de Orbes (`orbes_v12`), tres conceptos; `docs/v12/FIRMAMENTO_DE_LOS_ECOS.md`.
  - `b3c4e0f`: rendimiento (orden de dibujo del Gran Bosque, precalentado del combate, precarga de guiones; `gb_matas_casco` apagado) y el Centinela del Anillo (`enemigos_v12`).
  - Batería: 139 · 0 · 64 · 0.
- **Entregado, sin integrar todavía:** mundo y NPC (`claude/v12-mundo` @ `fb561e7`; pulido de NPC en curso), animación de combate (`claude/v12-combate2` @ `2c7ef79`; segunda pasada en curso) y Bramavidrio v5 (`claude/v12-bramavidrio5` @ `8e389aa`; la boca no convence: segunda vuelta pedida). Al integrar la v5: arreglar `prueba_cargas.gd:116` (aceptar el mapa de normales) y añadir su fila a `docs/recursos.md` (texto en §10 de su informe).
- **En curso:** segunda pasada de rendimiento (retrato de Dialogic, mipmaps de hojas, otras regiones), Gólem de ámbar y desfase del daño de los «jefe» (enemigos), protagonistas v3.
- **Aviso del especialista de mundo:** `desierto_comun.py` (`por_altura`) deja vértices sin peso y el exportador añade `neutral_bone`; Ismena y Oren podrían tenerlo.
- **13/11, 01:10 — más hitos subidos** (`origin/claude/rebelum-v12` = el último commit de abajo; `main` intacta):
  - `c07d761`: protagonistas v3 elegibles (geometría propia; de cerca peores que los v2) y rendimiento 2 (primer diálogo sin parón; mipmaps de hojas apagados). Batería 140 · 0 · 65 · 0.
  - `2694dcf`: Oakhaven vivo con NPC chibi v2 (`mundo_vivo_v12`), animación de combate v12 (`combate_anim_v12`, con los v2) y Gólem de ámbar (`enemigos_v12`); sincronía del golpe a todos de los «jefe» arreglada (huella nueva solo en Gorthor). Batería 144 · 0 · 67 · 0.
  - `c4c64e1`: Bramavidrio v5 elegible (opción 5; por defecto la v2). Pruebas de Bramavidrio 10 · 0 · 1 · 0.
- **En curso** (reanudados tras el límite de uso): Ciclópea 3D, primer sector (`claude/v12-mundo`); línea de turnos (`claude/v12-combate2`); Gorthor (`claude/v12-enemigos`).
- **Decisiones del usuario pendientes:** concepto del Firmamento y obtención de orbes; dónde se consiguen los accesorios; si se encienden mundo vivo, animación v12 y enemigos v12; Bramavidrio v5 frente a v4/v2; seguir o no con la geometría propia de los v3; Defender contra el golpe devastador de los «jefe»; la Reliquia del Confino; Naira.

### Noche del 12 al 13/11: encargos del usuario (duerme; sin Redmi)

- **Encargos:** cuatro PDF de diseño (en `D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\`): bestiario de 10
  enemigos comunes, Garon esgrima (18 técnicas, Compás), Lya magia blanca y Nix maga negra (cuarta heroína, con
  imagen de concepto del usuario). Además: «la capa de Garon está mal puesta, soluciónalo cuando termines todo» y, al
  final, «mejora el rendimiento y arregla todos los fallos». Puede usar todos los programas del PC.
- **Especialistas:** `claude/v12-nix` (modelo y piloto de magia negra, apagado `nix_v12`), `claude/v12-bestiario`
  (piloto Peón de Linde y luego por familias, `enemigos_v12`); siguen Ciclópea (`claude/v12-mundo`), línea de turnos
  (`claude/v12-combate2`) y Gorthor (`claude/v12-enemigos`). Garon esgrima y Lya magia blanca: al especialista de
  combate cuando acabe la línea de turnos.
- **Pregunta abierta para el usuario:** Nix frente a Naira (Nix va como prototipo propio; no se decide nada).
