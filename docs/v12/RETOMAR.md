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
- **13/11, 03:45 — estado al agotarse el límite de uso:** subido hasta la capa de Garon (`cefed0a`) y el arreglo de
  `prueba_bosque_pastos` (`35f493d`). Batería 152 · 0 · 70 · 0. **Sin integrar, en curso o cortado:** arte del
  bestiario v2 (`claude/v12-bestiario`, Peón y Velador; los pilotos v1 en `1c057f7` aún sin integrar) y la pasada
  final de rendimiento y fallos (`claude/v12-rend3` desde `cefed0a`, en `D:\Aethelgard_v12_rend2`). Al reanudar:
  revisar el estado de esas dos ramas, integrar lo probado y pasar la batería.
- **13/11, mañana:** APK de Auditoría `androidauditora-20261113-dfe5867` copiada al Redmi (Descargas, SHA-256 `558299e9…2f7e` verificado en el teléfono), sin instalar. Vistas de Nix para Meshy en `D:\REBELUM_diagnostico\v12\expansion\nix\para_meshy\`.

## RELEVO 13/11, 23:59: punto de recuperación verificable (contexto agotado; LEER PRIMERO)

**Nombre:** el juego se llama **REBELUM**. El usuario lo corrigió a las 23:55: «perdón, el nombre es rebelum».
«Aethelgard» es solo el nombre técnico del repositorio y del proyecto de Godot.

### Estado exacto de Git (comprobado a las 23:59)

- **Rama de trabajo:** `claude/rebelum-v12` en `D:\Aethelgard_v12`.
  - El último commit de código es `ed59483`, igual que `origin/claude/rebelum-v12` (comprobado con `git fetch`).
  - Encima solo está el commit LOCAL de este relevo, que es documentación y no se ha subido.
- **Intactas:** `main` = `d4b2d16` y `desarollo`. No hay merges ni releases.
- **Sin rastrear y AJENOS** (no tocarlos ni añadirlos a commits): `.agents/`, `.codex/`, `.verificacion-local/`.
- **Especialistas y workflows activos:** ninguno.
  - Las ramas `claude/v12-*` están terminadas e integradas, o cerradas como se documenta arriba.
  - No hay ningún archivo a medio editar.
- **Etiquetas de recuperación:** `v12-antes-expansion`, `v12-antes-hito-calidad`, `v12-antes-noche-20261111` y
  `v12-antes-rendimiento-personajes`.
  - La etiqueta de la noche del 13/11 **no está creada todavía**. Créala en local antes de tocar código:
    `git tag v12-antes-coordinador-20261113 ed59483`.
- **Copias de trabajo relacionadas:**
  - `D:\REBELUM_laboratorio_plugins`: rama LOCAL `claude/laboratorio-plugins` @ `5c4447c`, limpia y sin publicar.
  - `D:\REBELUM_entrada_13_11\`: la entrada de esta noche (ver abajo).
  - Las demás copias de `git worktree list` son históricas: no hay que escribir en ellas.

### Hecho y comprobado el 13/11 (subido a GitHub hasta `ed59483`)

- **`021ae11`: los protagonistas v2 y v3 ya no se tumban** al quedarse quietos.
  - Se desactivaron sus esperas (`prueba_esperas_v2`).
  - Verificado en el Redmi (v694): 30 s quietos y siguen de pie.
- **`135c6dd`: opción «Gran Bosque: pruebas de rendimiento»** en Ajustes, solo en la Auditoría y en el editor.
  - Código: `calidad_proto.gd` `EXTRA_PRUEBAS` y sección `[calidad_pruebas]` de `ajustes.cfg`.
  - Opciones `gb_matas_casco` y `gb_hojas_mipmaps` (sesgo −1). Las dos van APAGADAS.
- **`1204dd4`: los NPC de Oakhaven ya no bloquean la Puerta del Sur** (`mundo_vivo.gd`).
  - Hay zonas de paso, los NPC se apartan a los 0,35 s y Kael pasa tras 0,8 s de empuje (`prueba_npc_paso`).
  - En el Redmi está PENDIENTE: la prueba quedó cortada.
- **`941c4ac` y `ed59483`: octava y novena pruebas en el Redmi** (`docs/v12/INFORME_REDMI_V12.md`).
  - Gran Bosque en calidad media, parado/andando:
    - referencia: 24,3/26,2;
    - matas: 23,8/25,9;
    - mipmaps: 25,0/27,6;
    - las dos: 24,2/26,9.
  - Ninguna combinación llega a 30. Las matas se descartan.
  - Los mipmaps son candidatos, pero siguen apagados hasta que decida el usuario.
- **Redmi:**
  - instalada la Auditoría v694 (`1204dd4`, SHA-256 `9ca721bc…e136`);
  - partida restaurada idéntica desde `D:\REBELUM_respaldos\2026-11-13_redmi_auditoria_antes_1204dd4`;
  - el usuario se ha llevado el móvil: esta noche está prohibido tocarlo.

### Prototipos y opciones APAGADOS (no encenderlos sin decisión del usuario)

- **Héroes:** `heroes_v2`/`version` (versiones v2 y v3).
- **Mundo y personajes:**
  - `mundo_vivo_v12`;
  - `enemigos_v12` (bestiario y Gorthor);
  - `nix_v12`;
  - `orbes_v12`;
  - `ciclopea3d`.
- **Combate:** `combate` (`anim_v12`, `turnos`, `esgrima`), además de la magia blanca de Lya.
- **Gráficos:** `[calidad_pruebas]`.
- **Sonido:** los de los enemigos v12 y del bestiario, en `recursos.gd`.

### Laboratorio de tecnologías (13/11)

Informe: `D:\REBELUM_laboratorio_plugins\laboratorio\INFORME_LABORATORIO.md`.

- **Pixelpart:** DESCARTADO. Su editor es de pago y la partícula cuesta de 1,7 a 4,2 veces la nativa.
- **ProtonScatter:** DESCARTADO. Hace 319 llamadas de dibujo frente a 150.
- **Terrain3D:** DESCARTADO en el móvil. Cuesta de 15 a 50 ciclos A frente a 7,75 del terreno propio.
- **Jolt:** se mantiene.
- **Raymarching:** solo para efectos puntuales.
- **Binarios GDExtension descargados:** el clasificador bloquea ejecutarlos. No hay que saltarlo.
- **Efecto experimental de Érebo** (`proto_a_pixelpart/`, partículas nativas):
  - violeta, negro y plata, con una espiral hacia la mano y una onda;
  - en el PC cuesta +4 llamadas de dibujo y +0,12 ms;
  - SIN integrar todavía: es la tarea 3 del encargo de esta noche.

### Encargo coordinador del 13/11, 23:50 (el usuario duerme y mañana conecta el Redmi)

- **El texto LITERAL completo está en `D:\REBELUM_entrada_13_11\ENCARGO_COORDINADOR_13_11.md`.** Es la autoridad:
  léelo entero.
  - Desde el 14/11 también está versionado en `docs/v12/encargos/ENCARGO_COORDINADOR_13_11.md`.
  - **Documento de tareas vivo, con fases y estado de cada una:** `docs/v12/encargos/FASES_ENCARGO_COORDINADOR.md`.
    Después de compactar, sigue desde la primera fase sin «HECHA».
  - **Directiva de continuidad del usuario** (guardar tras cada fase, pruebas y commit, sin preguntas):
    `docs/v12/encargos/DIRECTIVA_CONTINUIDAD_14_11.md`.
- **Orden de trabajo:**
  1. Inspeccionar y proteger.
  2. Desbloqueos.
  3. Orbe de Érebo y una magia representativa.
  4. Menús y permisos de los héroes (solo Lya invoca).
  5. Nix desde su FBX.
  6. Capa de Garon con huesos propios.
  7. Primera experiencia jugable: misiones de Oakhaven, caravana, secreto, cerradura rúnica y gremio (13 frente a
     15 puntos).
  8. Oficios y armas especiales.
  9. Enemigos FBX (piloto `meshy_e01`) y arsenal.
  10. Historias personales y mundo vivo.
  11. Gráficos.
  12. APK de Auditoría SIN instalar y guion de pruebas.
  13. Matriz por elemento y continuidad.
- **GitHub:**
  - a `claude/rebelum-v12` solo se puede subir la integración COMPROBADA del orbe de Érebo, con sus pruebas y su
    documentación;
  - el resto se queda en commits LOCALES para que el usuario lo revise;
  - sin force push ni releases.
- **Progreso al agotarse el contexto: solo el paso 1, a medias. NO se ha cambiado código.**
  - Los 7 ZIP están copiados en `D:\REBELUM_entrada_13_11\zips\`. Los originales siguen en
    `C:\Users\G513\Downloads\aaaa\`, con la carpeta `Enemigos_Especiales_Claude\`.
  - Leídos: MANIFIESTO, LEEME, `PROMPT_MAESTRO_CLAUDE.md`, `ataques_propuestos.json` e
    `inspeccion_real_modelos.json`.
    - Los 4 FBX no tienen armature, actions ni vertex groups.
    - Triángulos: e01 10541, e02 6240, e03 6287, e04 9371.
    - ZIP de cada enemigo: Custodio = e01, moth = e02, stylized_fantasy_enemy = e03, cavern_creature = e04.
  - **Falta del paso 1:**
    - extraer cada ZIP en su propia carpeta vacía;
    - comprobar si el FBX `Meshy_AI_Silver_Sentinel` (24 MB) es Nix, comparándolo con las 6 referencias en T-pose
      de `Nix_Referencias_TPose_6_Vistas.zip`;
    - leer por páginas los PDF de Nix (3 MB) y de los 4 enemigos (3,9 MB);
    - crear la etiqueta de recuperación.
  - **Documentos citados en el encargo pero AUSENTES:** registrarlos como bloqueados y no inventarlos.
    - `PROMPT_GENERAL_AETHELGARD_CLAUDE.md`;
    - «Texto pegado(7).txt» y «Texto pegado(8).txt»;
    - `CATALOGO_GENERAL_PROPUESTO.json`;
    - el PDF de Kael y el PDF del arsenal.
- **14/11, paso 1 TERMINADO** (detalle en `D:\REBELUM_entrada_13_11\INSPECCION_PASO1.md`):
  - etiqueta local `v12-antes-coordinador-20261113` en `ed59483`;
  - los 7 ZIP extraídos en `D:\REBELUM_entrada_13_11\extraido\`;
  - resumen de los PDF de Nix y de los 4 enemigos en `RESUMEN_PDFS_NIX_ENEMIGOS.md`.
  - **El Silver Sentinel es Nix, base lisa** (renders en `D:\REBELUM_diagnostico\v12\expansion\nix\silver_sentinel\`):
    - es el cuerpo con mono gris, pelo corto plateado con dos mechones delanteros y ojos amatista;
    - tiene 436.194 triángulos (hay que reducirla a unos 15-25 mil), sin rig, y mide 1,90 m;
    - es la base para vestirla, no la Nix vestida.
  - **Contradicción resuelta:** el PDF de Nix describe un diseño anterior (sombrero de bruja, pelo ciruela, sin
    emblema).
    - Manda el canon vigente: capucha, pelo gris ceniza con dos mechones y emblema del Ojo de Horus.
    - Del PDF se conservan las mecánicas (Eclipse 3, 24 magias, no invoca) y los presupuestos: rig de 24-40 huesos,
      LOD0 de 7-10 mil triángulos, atlas de 1024².
    - Tabla completa en `INSPECCION_PASO1.md`.
  - **Coordinación:** desde el 14/11 existen la coordinación de sesiones (`D:\REBELUM_coordinacion`) y el gancho
    `proteger.sh` (bloquea fusiones de ramas, push forzado, reset duro y escrituras en las partidas reales).
- **14/11, 03:30 — avance de la noche** (detalle y estado de cada fase en
  `docs/v12/encargos/FASES_ENCARGO_COORDINADOR.md`):
  - **Hecho y validado en el PC** (`validado/v12/20261114-032918` en `84ff2c1`, batería 164 · 0 · 76 · 0):
    - 3A, el orbe de Érebo (`5c045b7`);
    - 3B, solo Lya invoca (`b451518`);
    - 3C, Agua v12;
    - 5, el piloto de Nix desde el FBX, SIN ropa;
    - 6, la capa de Garon articulada.
    - Todo lo nuevo va APAGADO y se enciende en Ajustes, solo en Auditoría.
  - **APK de Auditoría SIN instalar:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-e318629.apk`,
    SHA-256 `de0475…d50a`. Guion: `docs/v12/GUION_REDMI_14_11.md`.
  - **GitHub, sin subir.** Decisión del usuario:
    - subir los commits locales juntos;
    - o subir solo `claude/v12-orbe-solo` @ `a4db536` (solo el orbe sobre `ed59483`) y rehacer la historia local.
  - **Bloqueada:** la fase 4 (menús y catálogo de habilidades). Falta `CATALOGO_GENERAL_PROPUESTO.json` y los PDF de
    Kael y del arsenal. Además, Kael no tiene ataques rúnicos (sus artes son magia de apoyo).
  - **Activos** (especialistas, en sus worktrees):
    - Custodio `meshy_e01` en `D:\Aethelgard_v12_custodio`;
    - Oakhaven jugable en `D:\Aethelgard_v12_oakhaven_jugable`.
- **14/11, 05:30 — cierre de la noche:**
  - **Integrado todo** lo de los especialistas:
    - Custodio `meshy_e01`;
    - Oakhaven jugable (gremio con Oro a 13, Diario con pistas, caravana y cerradura rúnica del arcón);
    - vestuario canónico de Nix;
    - Garon v2 y v3 andando;
    - 4 correcciones de una revisión adversarial del código.
  - **Validado:** `validado/v12/20261114-052612` en `c0b199a`, batería **171 · 0 · 78 · 0**.
  - **APK NUEVA sin instalar:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-6da1c74.apk`, SHA-256
    `794114686382954d3604ceb4e48208856555e81d540a99cb1a60427b19c1259c`. Sustituye a la `e318629`.
  - **No hay especialistas activos.** Las ramas `claude/v12-*` de esta noche se conservan.
  - **GitHub:** nada subido. La decisión pendiente está en `FASES_ENCARGO_COORDINADOR.md`, apartado «Decisiones».
- **Siguiente acción concreta:**
  1. Por la mañana, el guion del Redmi (`docs/v12/GUION_REDMI_14_11.md`) con la APK `6da1c74`, respaldando y
     restaurando la partida.
  2. Pedir al usuario sus decisiones:
     - la subida a GitHub;
     - la Nix adulta frente a la *chibi*;
     - el gremio con Oro a 13;
     - aprobar «Las tres marcas del cantero»;
     - las afinidades del Custodio;
     - el catálogo y los PDF que faltan para la fase 4 y los 32 conjuntos.
  3. Después, siguiendo `FASES_ENCARGO_COORDINADOR.md`:
     - la emisión de iris y ornamentos de Nix y su encuadre `nix3d`;
     - los 9 clips y los especiales a2 y a3 del Custodio;
     - e02-e04;
     - la alquimia (fase 8).

### Decisiones que se conservan

- **Bramavidrio:** se integró la v5; las versiones anteriores se conservan.
- **Nix:**
  - es la cuarta heroína y va apagada (`nix_v12`);
  - sigue abierta la pregunta de Nix frente a Naira;
  - apariencia canónica, en el encargo y en `docs/v12/NIX_V12.md`: capucha sin sombrero de bruja, pelo gris ceniza
    corto con dos mechones delanteros, y en la espalda un Ojo de Horus dentro de una estrella de seis puntas.
- **Protagonistas:** v2 y v3 son opcionales; por defecto van los originales.
- **Mundos 3D:** Pastos, Gran Bosque, Garganta, Oakhaven y Ciclópea (apagada).
- **Firmamento de los Ecos:** en `docs/v12/FIRMAMENTO_DE_LOS_ECOS.md`.
- **Redmi:**
  - solo se usa la Auditoría, respaldando y restaurando su partida;
  - MIUI bloquea `adb install`: se copia la APK a Descargas y la instala el usuario;
  - las medidas del PC no son resultados de Android.

## RELEVO 14/11, mañana: validación de lo de la noche (LEER PRIMERO)

### Git
- **Rama:** `claude/rebelum-v12`, con commits LOCALES encima del validado `c0b199a`:
  - `8200909`: banco de pruebas de Auditoría;
  - `f47964c`: correcciones del banco tras la revisión adversarial y arreglo de la capa tras un giro instantáneo;
  - `bd858f8`: cara y cetro de Nix.
- **Remoto:** `origin/claude/rebelum-v12` = `a4db536`.
  - Es solo el orbe de Érebo sobre `ed59483`, subido el 14/11 como avance normal y AUTORIZADO.
  - La rama local NO contiene `a4db536`: es una copia del orbe con otro hash, el de `5c045b7`. Para publicar lo demás habrá que integrar el remoto en la local sin perder ninguno de los dos lados. Eso necesita autorización, y el gancho bloquea esa operación.
- **Puntos de recuperación:**
  - `respaldo/v12-antes-validacion-20261114` → `19ba694`;
  - `respaldo/origin-rebelum-v12-antes-orbe` → `ed59483`.
- **Sin versionar, a propósito:**
  - `aethelgard/personajes/nix/fbx/anterior_14_11/` (la Nix anterior; también está en `c0b199a`);
  - y, ajenos, `.agents/`, `.codex/`, `.verificacion-local/`, `docs/continuidad/` y `CLAUDE.proyectos-respaldo-20261114.md`.

### Hecho y comprobado en el PC, en el proyecto real y sin otros Godot a la vez
- **Banco de pruebas** (solo Auditoría o editor): accesos sin comandos a Érebo, Agua, Nix, la capa, los protagonistas, el Custodio, Oakhaven y la misión del cantero.
  - Su partida es aislada y rehecha desde BASE: nada es permanente.
  - Revisión adversarial con 5 defectos, todos corregidos.
  - `prueba_banco_pruebas` y su variante `_3d` pasan.
- **Capa de Garon:** arreglo SALTO_GIRO.
  - `prueba_capa_garon_estados`: 526 ok. La contraprueba sin el arreglo da 16 fallos, todos de giro brusco y reaparecer.
  - Capturas de combate de las tres variantes: utilizables.
  - Capturas de regiones: «andar» y «correr» son clips en el sitio, y algunas salen tapadas o lejanas.
  - **Pendiente:** capturas con MOVIMIENTO REAL (`fotos_capa_garon_movimiento`).
  - **Pendiente:** el roce de 1 a 5 triángulos de la hoja en Juicio y Giro, que la prueba tolera hasta 6.
- **Nix:**
  - Cara y cetro corregidos. La cara mejora pero no queda idéntica al FBX.
  - Ya va en la fila de la exploración, solo con su interruptor.
  - `prueba_nix_fbx` 60/60.
  - **Decisión del usuario:** proporciones realistas frente a los *chibi* (revisión en `D:\REBELUM_diagnostico\v12\nix_revision_14_11\`).
- **Gremio con Oro a 13:** aprobado. Cubierto por `prueba_gremio` (cobro único) y `prueba_gremio_progresion` (desde cero y persistencia).
- **Custodio:** afinidades neutras PROVISIONALES, documentadas.
- **Kael:** siguen faltando `CATALOGO_GENERAL_PROPUESTO.json`, el PDF de Kael y el del arsenal. Conserva su comportamiento actual.
- **Interferencias:**
  - El fallo de `prueba_audio` (312 ms) era la CPU compartida: sola da 82 ms.
  - La batería de las 11:00 se paró porque el árbol cambiaba a mitad de pasada. No vale como validación.

### Redmi (REDMI A7 Pro, Android 16, conectado y autorizado)
- **Instalada:** la v694 (`1204dd4`), sin tocar.
- **Respaldo verificado** (538 archivos con el mismo SHA-256): `D:\REBELUM_respaldos\2026-11-14_redmi_auditoria_antes_v694_a_nueva`.
- MIUI rechaza `adb install`. La v713 (`8200909`) está en Descargas, pero **es obsoleta**: con la portada que sale por defecto no se llega al banco. **No instalarla.**

### Siguiente acción concreta
1. Terminar las capturas de la capa con movimiento real y revisarlas.
2. Pasar la batería completa SOLA, sin otros Godot ni Blender abiertos.
3. Compilar la APK nueva y sustituir la v713 en Descargas (la instala el usuario).
4. Seguir el guion del Redmi, con la v2 y la v3 de pie y los vecinos de Kael primero.

### Redmi, 14/11 13:10-13:40: resultados REALES con la v717 (`687dbe7`)
- **Instalación:** la hizo el usuario desde Descargas, porque MIUI bloquea `adb install` y el sistema de permisos no deja pulsar su confirmación desde el PC.
  - Datos de Auditoría idénticos al respaldo tras instalar (538 archivos, comprobado por SHA-256).
- **Arranque en frío:** 13,0 s hasta la portada (967 archivos, 0 fallos). La portada alternativa muestra «Banco de pruebas».
- **v2 de pie 30 s:** sí. 30,4 FPS de media, 0 perdidos de 987, PSS 953 MB (517 MB de gráficos), 30,6 °C.
- **v3 de pie 30 s:** sí. 30,2 FPS, 0 perdidos de 971, PSS 848 MB, 30,8 °C.
- **Kael entre los vecinos:**
  - Cruza la Puerta del Sur y la calle junto al guardia y al mago sin bloquearse, con 30,4 FPS y 0 perdidos.
  - En la plaza, lo que lo frenó fue la fuente, que es un obstáculo fijo, no los vecinos.
  - Era de noche, con pocos vecinos: **la hora de más gente queda sin probar.**
- **Solo Lya invoca:** confirmado. Kael no tiene INVOCACIÓN.
- **Custodio (`meshy_e01`):**
  - Aparece con su modelo y hace la Prensa del Umbral con las marcas de aviso bajo Lya y Garon.
  - 56,7 FPS, 0 perdidos de 1922.
  - Al acabar se vuelve al banco.
  - Detalle sin investigar: su PV máximo pasó de 161 a 145 tras quedar «Congelado».
- **Capa articulada en combate** (original): ondea detrás al atacar.
- **Érebo, misma ventana de unos 20 s y sin capturas:** original 44,0 FPS y experimental 44,2 FPS, los dos con 0 perdidos.
  - En los primeros planos el contador baja a unos 15 FPS, se use o no el orbe.
  - La invocación entera funciona y no deja restos.
  - **El instante del orbe no se captó** (solo una captura por segundo).
- **Agua original:** 60,7 FPS en 10 s. La Mejorada **no se llegó a probar**: el usuario desconectó el teléfono.
- **Defectos del banco vistos y ya corregidos** (`c4369bb`):
  - los enemigos huían a nivel 12;
  - «Volver al banco» tapaba CAL y RND;
  - la etiqueta pisaba el contador de FPS.
- **Sin probar en el Redmi:** Agua mejorada, Nix (combate y exploración), cerradura y misión del cantero, ciclos exploración → combate → exploración.
- **AL RECONECTAR (obligatorio):** la app quedó dentro del banco.
  1. Borrar `files/banco_pruebas.save`.
  2. Restaurar `files/ajustes.cfg` desde `D:\REBELUM_respaldos\2026-11-14_redmi_auditoria_antes_v694_a_nueva`.
  3. Comprobar por SHA-256 que los 538 archivos coinciden con `sha_tel_todo.txt`.
  - La partida de siempre (`partida_exp.save`) no la tocó el banco: compruébalo también.

### 14/11, tarde: mejoras de personajes y rendimiento (en el PC; pendientes de ver en el Redmi)
Hechas por tres agentes en worktrees aislados, cada uno revisado por otro agente escéptico. Integradas aquí por el coordinador con `cherry-pick` y verificadas en el proyecto real.
- **Rendimiento de Érebo** (`84a39fe`): ninguna imagen cambia; comparadas con antes, la diferencia máxima es de 1/255.
  - El combate tapado deja de dibujarse durante la invocación: de 78 a 54 llamadas de dibujo y de 105.000 a 47.000 primitivas por fotograma.
  - El cuerpo sin disolución pasa de 17,0 a 12,4 ciclos de Mali-G57 y deja de tener ZS tardío.
  - El orbe ya no calcula el Voronoi de las grietas mientras estas no se ven.
  - Las partículas son octógonos en lugar de cuadrados: un 17 % menos de fragmentos.
  - Precalentado de los 11 programas: antes se compilaban en mitad de los primeros planos y probablemente causaban la caída a unos 15 FPS. Ahora se compilan durante el fundido de entrada.
  - **Efecto secundario aceptado:** la invocación empieza 2 fotogramas más tarde y cambian las tiradas de azar posteriores. Por eso la referencia de `prueba_combate_huella` es nueva (`4d5fe36`); los resultados de sus nueve combates no cambian.
  - El tope de 30 FPS en el perfil bajo es INTENCIONADO (encargo del 09/11).
- **Nix** (`89269b7`, sigue APAGADA):
  - Emisión suave solo en el iris: a la distancia de juego, dos puntos violetas.
  - Fuera las placas púrpura de los puños y los rectángulos de la espalda, que eran artefactos del guion de vestuario.
  - Lo anterior queda en `anterior_14_11b/`.
  - **Pendiente:** ver en el Redmi si el punto violeta parpadea en movimiento y decidir si brilla de noche.
  - Ya no asoma forro púrpura de la capa; recuperarlo sería una decisión de diseño del usuario.
- **Capa de Garon** (`61a62a8`): la media vuelta desde parado ya no cruza el muslo.
  - El trabajo es del agente, corregido por el coordinador tras la revisión: subpasos rígidos y centros de cuadro solo tras un giro rápido.
  - Contraprueba: 6 fallos con la capa anterior.
- **`prueba_velador_v12`:** falló una vez en la batería y pasó sola sin cambios. Es estadística (media de PV perdidos), así que queda anotada como inestable.

### 14/11, noche: invocación cinematográfica de Érebo en vídeo (encargo «segunda producción cinematográfica»)
Todo está en `docs/v12/EREBO_CINEMATICA_V12.md`. Es EXPERIMENTAL y está APAGADA por defecto: Ajustes →
«Érebo: invocación cinematográfica», solo en Auditoría. La invocación de siempre no cambia.
- **Producción:** Blender por script (`animaciones/erebo/fuentes/cinematica_erebo.py`, `montaje_erebo.py` y `sonido/`), con el modelo aprobado de Érebo.
  - Versión completa de 20 s y abreviada de 6,8 s.
  - Agarre medido: ningún dedo atraviesa el orbe; quedan a 3,3-4,8 mm.
  - Sonido original más paquetes de Sonniss, con su licencia leída.
- **Vídeos:**
  - Para Godot: `aethelgard/videos/erebo_invocacion_{completa,abreviada}.ogv` (Theora 960×540, 6,4 y 2,3 MB). Solo entran en la APK de Auditoría.
  - Para revisar: `D:\REBELUM_diagnostico\erebo_cine\final\*.mp4`.
- **Reglas:**
  - El daño se aplica una sola vez, con la misma tirada.
  - El ATB es exactamente el de la invocación de siempre (`ATB_TEATRO`, medido con `pruebas/medir_erebo_teatro.gd`).
  - Se puede saltar, también durante el fundido.
  - Si el vídeo falla, sale el teatro de siempre.
- **Pruebas:** `prueba_erebo_video` sin fallos. Medida en tiempo real en el PC: llega al final del vídeo, fotograma de 33 ms y ninguno de más de 50 ms.
- **PENDIENTE:**
  - Que el usuario vea y oiga los vídeos.
  - Redmi: decodificación de Theora, sincronía del audio, memoria y carga, y comprobar que con el vídeo desaparece la caída a 15 FPS de los primeros planos.

## RELEVO 14/11, noche (21:40): aventura del cantero y taller de Lya (LEER PRIMERO)

Encargo del usuario (fuera de casa, sin Redmi): Érebo cinematográfico CONGELADO en `5e5458d` (apagado; no sustituir
la invocación original). Prioridades: 1) cerrar «Las tres marcas del cantero»; 2) taller de Lya conectado; 3) pulido
de Oakhaven y Pastos Verdes; después, el siguiente lote de la matriz (personajes, enemigos o armas con archivos).
- **Punto de recuperación:** etiqueta `recuperacion/v12/20261114-antes-cantero` → `dee61fc`.
- **Hecho y comprobado en el PC (commits locales, sin subir):**
  - `a5a519e`: talleres más claros (lo que falta, pistas, «No se gasta», orden; investigación con «si»).
  - `0f460ab`: «Las tres marcas del cantero» completa (PROPUESTA; en Auditoría: Ajustes o banco de pruebas).
    Todo en `docs/v12/CANTERO_V12.md`. Recorrido JUGADO con controles normales (`fotos_cantero_recorrido`, 0 fallos);
    capturas en `D:\REBELUM_diagnostico\cantero\recorrido_14_11\`. Regresión de Oakhaven, talleres y banco: 20/20.
- **En curso:** prioridad 3 (revisión de Oakhaven y Pastos Verdes en busca de defectos concretos).
- **Siguiente lote de la matriz elegido:** Custodio de Porcelana (`meshy_e01`): ataque e01_a2 «Avance del Portón» (ficha
  en `D:\REBELUM_entrada_13_11\extraido\Aethelgard_Paquete_Claude_4_Enemigos\ataques_propuestos.json`), con su clip en
  Blender (`enemigos/meshy_e01/fuente/p2_clips.py`) y su lógica en `combate_meshy_e01.gd`. Kael rúnico y el arsenal
  siguen BLOQUEADOS (faltan sus PDF y el catálogo).
- **Redmi:** nada nuevo instalado. Al reconectar, lo de siempre (restaurar `ajustes.cfg`, borrar `banco_pruebas.save`,
  comprobar SHA) y probar también el cantero (legibilidad de las placas, la losa con el dedo).

### 14/11, 23:30: cierre de la noche (prioridades 1-3 y un lote de la matriz)
- **Validado:** `720d193` (etiqueta `validado/v12/20261114-232613`), batería 175 · 0 · 92 · 0 (`2026-11-14_224714`).
  - En la batería anterior (`b92af51`), `prueba_gorthor_v12` falló una vez; sola pasa 4 de 4. Queda como
    INTERMITENTE: sus combates dependen del azar global, que comparten otros nodos.
- **Commits locales (sin subir):**
  - `a5a519e`: talleres.
  - `0f460ab`: cantero.
  - `9a9be6c`: documentación.
  - `1beaf1e`: Custodio, Avance del Portón, golpe y derrota.
  - `b92af51`: pulido, 8 defectos.
  - `720d193`: arreglos de la revisión adversarial.
- **Documentos:** `CANTERO_V12.md`, `PULIDO_RECORRIDO_14_11.md` y `CUSTODIO_E01_V12.md` §8.
- **APK:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-720d193-local.apk`, en el PC. El guion de
  pruebas está en `GUION_REDMI_14_11.md`.
- **Siguiente tarea exacta:** el Sello de Clausura (e01_a3) del Custodio. Ficha en `ataques_propuestos.json`:
  - un círculo de 1,3 m a un máximo de 5 m, fijado antes de activar;
  - anticipación de 1,30 s, ventana activa [1,30, 1,50) y 9-13 de daño.

  Mismo método que el Avance: el clip en `p2_clips.py` sobre una copia del `.blend` y la lógica en
  `combate_meshy_e01.gd`, con su prueba. Después, los clips alert, turn y guard.
- **Pendiente de decisiones del usuario:**
  - aprobar el cantero como canon y encenderlo por defecto;
  - ver y oír los vídeos de Érebo;
  - las cifras propuestas del Custodio.

## RELEVO 15/11, noche autónoma (LEER PRIMERO): auditoría externa, Sunken City 3D y revisión de personajes

Encargo del usuario del 15/11 (noche, sin Redmi): reparar los fallos comprobados de la auditoría externa (hecha sobre
`da0e336`), conservar lo funcional, construir la siguiente ubicación 3D y dejar una APK de Auditoría consolidada.
Punto de recuperación: etiqueta `recuperacion/v12/20261115-antes-noche` → `da0e336`.

### Punto de control 01:40 (commits locales, sin subir)
- `d9dc733` A: cantero, la losa abierta primero empieza la misión (antes, oculta en el Diario). Casos 3c/3d.
- `3596779` B: Hierro de la Falla perdido en partidas antiguas: Ferro lo nota, el Diario lo explica, la veta da UNO.
- `178c9cd` A (detalles): marca suelta sin misión no dice «Diario»; el brazalete no brilla con la losa abierta.
- `629c75f` C: talleres.error_receta(): la receta se valida entera antes de gastar; equipable repetido no gasta.
- `1a2f0a1` D: ciclos de investigaciones (catalogo.ciclos_investigacion, en_ciclo; antes, Stack overflow).
- `7de9482` E: progreso.errores_estructura() en leer(); 29 copias reales de partidas de los respaldos: 29 válidas.
- `5f32cec` prueba_rasgos_grupo (solo Lya invoca, Nix, par de Garon una vez, Oro a 13).
- Cada arreglo con contraprueba (sin él, su prueba falla: 2, 2, 42, 3+Stack overflow y 14 fallos).
- Cerrado sin cambio: el PV máximo del Custodio de 161 a 145 tras «Congelado» es la congelación de Frostfang
  (combate.gd `_congelar`: −2 de Vitalidad = −16 PV máximos durante RONDAS_CONGELACION; se devuelven al acabar).
- Kael «Ataque rúnico»: el catálogo y el PDF de Kael NO existen (buscados en docs, `D:\REBELUM_entrada_13_11` y
  `D:\REBELUM_diagnostico\v12`). Se conserva su menú de hoy (MAGIA Fuego/Rayo, sin INVOCACIÓN). Dependencia abierta.
- En marcha (agentes en worktrees propios): sector 3D de Sunken City; pruebas exactas del orbe, vídeo de Érebo y
  Gorthor/Velador con semilla; revisión visual de Nix y de la capa de Garon.

### Punto de control 03:20 (todo integrado en claude/rebelum-v12; commits locales, sin subir)
- **Agentes (cada uno en su worktree; los tres TERMINADOS, integrados con cherry-pick y revisados):**
  - Revisión de personajes (`claude/v12-revision-personajes`): la mano del cetro de Nix cerraba mal (RightHandMiddle1
    sin pesos) → arreglada, GLB anterior en `personajes/nix/fbx/anterior_15_11/`. Capa de Garon (independiente,
    anclada < 1 mm, móvil), dos espadas con una ranura y protagonistas v2/v3 de pie: bien. `REVISION_PERSONAJES_15_11.md`.
  - Pruebas de combate (`claude/v12-pruebas-combate-estabilidad`, `claude/v12-custodio-sello`): orbe de Érebo con
    comparación exacta (Grimfang y jefe 180 → 144) y casos de fallo; vídeo con fallos de carga, jefe, nueva, completa
    y sin pausa; Gorthor, Velador, Gólem, Centinela y Peón con el azar fijo DE VERDAD (la semilla se ponía antes de que
    combate._ready hiciera randomize()). **Sello de Clausura (e01_a3)** del Custodio: clip, combate, rotación de los
    tres especiales y medida de conjunto (CUSTODIO_E01_V12.md §9); cifras PROPUESTAS.
  - Sunken City 3D (`claude/v12-sunken3d`): sector «Popa Rota → Cubierta Mayor», EN PRUEBAS y apagado
    (SUNKEN_3D_V12.md). Arte provisional (procedural).
- **Del coordinador tras integrar:** el Bronce del Águila reservado hasta forjar la Guarda; Sunken en el banco de pruebas;
  el Custodio del banco con vida ×8; `_vigilar_atasco` (tocar más lejos ya no para a Kael, todas las regiones); Bastián
  y Rosa por la orilla de su calle (24 de 24 travesías en `fotos_paso_vecinos`).
- **Hallazgos sin arreglar (Érebo congelado):** el orbe gasta azar global (la tirada siguiente cambia); un vídeo que no
  abre puede dejar negro hasta tocar; si el vídeo no arranca, el ATB corre ~2 s de más. Propuestas en
  `docs/memory/agents/combate.md` (15/11).
- **Intermitente anotado:** `prueba_banco_pruebas` acabó una vez con FALLOS: 0 y cierre anómalo de Godot (0xC0000005).

### 04:10: cierre de la noche (LEER PRIMERO)
- **Validado:** `270c8ed` (etiqueta `validado/v12/20261115-035801`), batería completa **183 · 0 · 94 · 0**
  (`2026-11-15_032759`). HEAD `c04d07b` solo añade la medida de memoria de PC (no va en la APK).
  - La primera batería (`2026-11-15_025150`) dio 182 · 1: `prueba_bosque_pastos` (el combate fijo del Guardián no
    empezaba tras usar la alquimia). Causa: el arreglo C leía `load("res://combate.gd").OBJETOS_COMBATE` desde el
    taller. Arreglo `270c8ed`: la tabla vive en `datos/objetos_combate.gd` (combate.gd la usa igual).
- **APK:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261115-c04d07b-local.apk`, 420,0 MB, SHA-256
  `9b42c2a4c97ef07bbfd309328041d084701fa89559bae276200880757132dd35`, «TODO CORRECTO». Guion: `GUION_REDMI_15_11.md`.
- **Medidas de PC (sin otros Godot; no certifican Android):**
  - Sunken City 3D (`D:\REBELUM_diagnostico\sunken\medida_sola_15_11\`): 40-75 llamadas de dibujo en bajo (67-75 mil
    primitivas), 54-103 en medio (130-143 mil), 81-152 en alto (147-165 mil). Los ms por fotograma del PC están
    limitados por el perfil (31,2 ms en bajo y medio): no sirven.
  - Memoria tras 5 vueltas mapa → Oakhaven → Sunken → Pastos (`2026-11-15_040111`): estable (156,0 MB estática, 88,3 MB
    de vídeo, 460 nodos, 0 huérfanos de la 2.ª a la 5.ª).
- **Pendiente del usuario:** aprobar el cantero y Sunken (narrativa PROPUESTA: Ulla, Brea, «El sello de la capitana»);
  altura y capucha de Nix; encender por defecto Nix FBX y la capa articulada; las cifras del Custodio; ver y oír los
  vídeos de Érebo; si se descongela Érebo, las tres propuestas del orbe y el vídeo.
- **Dependencias ausentes:** catálogo y PDF de Kael («Ataque rúnico»): Kael conserva su menú. Sonidos de mar,
  gaviotas y campana de barco para Sunken (usa sustitutos).
- **Siguiente acción exacta:** con el Redmi, seguir `GUION_REDMI_15_11.md` desde «Antes de instalar». Sin Redmi:
  el siguiente sector de Sunken City (el interior del Casco o el resto de vecinos del diseño) con las notas en el
  Diario (`progreso.gd`, `CIUDADES[5]`), o el resto de pruebas con el patrón de semilla antes de add_child (Centinela y Peón ya hechos)
  (`docs/memory/agents/combate.md`, lista G2).

### 15/11 (mañana): revisión de Érebo para el usuario y comprobaciones técnicas
- **Archivos para revisar Érebo** (enviados al usuario; NADA aprobado: imagen, ritmo y sonido pendientes de su
  revisión), en `D:\REBELUM_diagnostico\erebo_cine\revision_15_11\` (SHA-256 en `sha256_mp4.txt`):
  1. `REBELUM_Erebo_1_completa_del_juego.mp4` (20,00 s) y 2. `..._2_abreviada_del_juego.mp4` (6,80 s): copias H.264 +
     AAC de los `.ogv` del proyecto (los originales, comprobados intactos por SHA-256).
  3. `..._3a_en_combate_abreviada.mp4` (18,3 s) y `..._3b_en_combate_completa.mp4` (31,4 s): grabadas en el PC con el
     Movie Maker de Godot (imagen y sonido del juego), combate → vídeo → combate. Guion: `pruebas/grabar_erebo_transicion.gd`.
     La invocación se lanza por código: en la grabación el menú enseña INVOCACIÓN en gris porque la Armonía se llena
     después de pintarlo (artefacto de la grabación, no del juego).
- **Descartado como fallo del juego:** «entrar desde el mapa falla con --fixed-fps» (hallazgo del agente de Sunken). Era
  la prueba, que esperaba N fotogramas: con --fixed-fps vuelan y salía antes de acabar la carga en segundo plano.
  Esperando por reloj, todas las regiones entran (Sunken 0,9 s, Pastos 1,7 s).
- **No hace falta cambiar** menus.gd ni tienda.gd: leen combate.gd, pero en el juego ya lo carga la pantalla de carga
  (`carga.gd _preparar_shaders`). La regresión del 15/11 solo pasaba en pruebas que no pasan por ella.
- **Medida de PC, Nix** (`D:\REBELUM_diagnostico\nix_medida_15_11\`, medir_modelo en frío, sin otros Godot): FBX
  35-43 ms y +4,0 MB de texturas; la antigua 41-51 ms y +6,7 MB.

### 15/11, tarde: Érebo reparado e híbrido, Custodio separado, Sunken medido y APK `cbc0536`
- **Validado:** `cbc0536` (etiqueta `validado/v12/20261115-133330`), batería **185 · 0 · 98 · 0** (`2026-11-15_130355`).
  Recuperación: `recuperacion/v12/20261115-270c8ed` y `recuperacion/v12/20261115-antes-erebo-hibrido`.
- **Érebo (descongelado solo para lo autorizado):**
  - azar: las CPUParticles3D gastan el azar global aunque lleven semilla fija (Godot 4.7); `combate._invocar_sobre`
    reserva una semilla al empezar y la repone al acabar → mismas tiradas posteriores con el orbe encendido o apagado
    (prueba exacta). Referencia de `prueba_combate_huella` actualizada (E3 y E8, después de su Érebo);
  - vídeo: si no avanza en 1,5 s o se para 1 s a mitad, sale solo; el ATB empieza al avanzar (sin ATB de más);
  - **híbrida** (agente, `docs/v12/EREBO_HIBRIDA_V12.md`): acercamiento y extracción en tiempo real con el modelo del
    objetivo + tramo del ritual del vídeo (`videos/erebo_ritual*.ogv`, derivados; originales intactos). Apagada; solo
    Auditoría. Grabaciones en `D:\REBELUM_diagnostico\erebo_hibrida\videos\` (enviadas al usuario). Pendiente de su
    revisión: duración (≈24 s con el ritual completo, ≈16,5 s breve), el corazón algo tenue, sin sonido propio.
- **Custodio:** banco con «equilibrio normal» (×1) y «ver la rotación» (×8) separados. Cifras propuestas.
- **Pruebas:** semilla tras add_child en 11 pruebas más (agente); `prueba_bosque_pastos` espera por reloj solo en su
  recarga. Residuo conocido: el destello del clímax de Bramavidrio (por tiempo real) puede mover una tirada.
- **Nix antigua** ya no desaparece a 9 m (márgenes de sus tramos de detalle). **Comparación del grupo** (sin cambiar
  nada): `D:\REBELUM_diagnostico\comparar_grupo_15_11\` (hojas, alturas y 21 vídeos; enviados en parte).
- **Sunken City, medidas de PC reales:** `SUNKEN_3D_V12.md` (carga 1,42-1,49 s en frío, 1,28-1,31 s con caché, 0,89-0,94 s
  después; sin tirones; memoria estable).
- **APK:** `Aethelgard_androidauditora-20261115-cbc0536-local.apk`, 425,5 MB, versionCode 801, SHA-256
  `3fd18e4a6560ef58e0056805f413efe905e9481d46949bdf978ffcc9446d3869`. Guion: `GUION_REDMI_15_11.md` (sección de arriba).
- **Redmi:** respaldo nuevo y ajustes restaurados; se perdió el USB antes de instalar.
- **Siguiente acción exacta:** reconectar el Redmi y seguir `GUION_REDMI_15_11.md` desde la APK `cbc0536`.
- **Decisiones del usuario:** Nix en combate (desde cuándo y si el grupo pasa a 4); revisar Érebo híbrida y su
  duración; altura/capucha de Nix con la comparación; cifras del Custodio.

### 15/11, 14:20: corrección de fechas
El trabajo de la mañana y la tarde del 15/11 se etiquetó por error como «16/11» (la fecha real del sistema era
2026-11-15). Corregido en código, documentos y carpetas: `GUION_REDMI_15_11.md`, `REDMI_15_11.md`,
`D:\REBELUM_diagnostico\*_15_11` y `D:\REBELUM_respaldos\2026-11-15_redmi_auditoria_antes_consolidada`. Las etiquetas
`recuperacion/v12/20261116-270c8ed` y `recuperacion/v12/20261116-antes-erebo-hibrido` NO se borran (norma de no borrar
etiquetas); sus equivalentes con la fecha correcta son `recuperacion/v12/20261115-270c8ed` y
`recuperacion/v12/20261115-antes-erebo-hibrido` (mismos commits).

## RELEVO 15/11, tarde (16:00): Redmi, Custodio, Érebo híbrida 2, mapamundi 3D (LEER PRIMERO)
Recuperación: `recuperacion/v12/20261115-antes-encargo-tarde` (`1239e78`). Validado: `d0f4a65`
(`validado/v12/20261115-154738`, 186 · 0 · 100 · 0). Integrado encima: el mapamundi 3D (agente).
- **Redmi** (`REDMI_15_11.md`): Sunken bajo/medio a 30 FPS sostenidos; alto 17-18 FPS (no se fuerza); PSS por
  ciclos estable salvo tras usar alto (+≈130 MB retenidos, sin crecer); Oakhaven de noche sin atascos; el volumen
  multimedia del teléfono está a 0 (sonido sin escuchar); cómo se mide, explicado.
- **Custodio:** la rotación era correcta; el contador se explicaba mal → «Sello en N turnos suyos» y aviso del especial
  en el turno anterior (`CUSTODIO_E01_V12.md` §10). Banco: caso de rotación ×8 separado y su nota con la duración.
- **Grupo de cuatro (solo banco):** caso «Grupo de cuatro» con permiso de sesión; fuera del banco, tres
  (`NIX_GRUPO_CUATRO.md`: lo que haría falta para hacerlo definitivo, sin aplicar). Decisión del usuario pendiente.
- **Cantero:** jugado con la losa primero (0 fallos); el Diario ya no da por hechos pasos saltados (`saltado_si`).
- **Érebo híbrida 2** (`EREBO_HIBRIDA_V12.md` §9): cabeza firme (el reposo era un «Thriller Idle» de Mixamo), abreviada
  elegible en Ajustes y banco, cobertura completa y sonido medido. Candidatos de la cinemática con la cabeza firme en
  `D:\REBELUM_diagnostico\erebo_hibrida\cabeza\candidatos_ogv\` (sin sustituir los del juego).
- **En marcha (agente):** cinemática de vídeo MEJORADA (cabeza firme, más efectos, luz, animación y sonido),
  originales del 14/11 conservados en `videos/originales_14_11/`; la híbrida empalmará con ella.
- **Mapamundi 3D** (`MAPAMUNDI_3D_V12.md`): «Tierras de Oakhaven», experimental de Auditoría, apagado; viaje rápido
  Oakhaven ↔ campamento de Pastos Verdes; cueva provisional; secreto «Corro de los Mirlos». Todo PROPUESTA.
- **Fechas:** corregidas al 15/11 (ver «corrección de fechas»). Un daño de esa corrección en la referencia de la huella
  ya está deshecho (`b56fc6b`).
- **Siguiente encargo (tras cerrar esta fase y con punto de recuperación):** la muestra gráfica experimental de una
  calle de Oakhaven (encargo del usuario del 15/11 por la tarde). No se ha recibido la imagen de referencia de FFIX que
  menciona: se trabaja con lo descrito.

## RELEVO 15/11, 17:30: Redmi con `dc878e9` (v834) y comienzo de la muestra gráfica de Oakhaven (LEER PRIMERO)
Validado: `dc878e9` (`validado/v12/20261115-170245`, 188 · 0). APK v834 instalada por el usuario.
- **Redmi** (`REDMI_15_11.md`, sesión 17:05): híbrida abreviada (resistida) y completa (éxito) funcionan, con salto;
  52-55 FPS en el tramo, 2 tirones de 350 ms solo la primera vez; contador del Custodio legible hasta «Sello en 2»;
  grupo de cuatro a 56 FPS; mapamundi 3D a 30 FPS con viaje rápido y vuelta a Oakhaven. Teléfono devuelto al estado
  de antes de la sesión (mismos SHA); Descargas sin tocar.
- **Pendiente en el teléfono:** lista concreta en `GUION_REDMI_15_11.md` (jefe y Bramavidrio con la híbrida, el
  «Vídeo» mejorado, sonido con el volumen que suba el usuario, campamento y cueva, Oakhaven de mañana, Sello lanzado).
- **Siguiente acción:** muestra gráfica experimental de UNA calle de Oakhaven (escena aparte, solo Auditoría, apagada
  por defecto; no se extiende al resto del juego hasta que el usuario la vea). Plan y avance en
  `docs/v12/MUESTRA_CALLE_OAKHAVEN.md`.

## RELEVO 15/11, noche (20:00): muestra gráfica de una calle de Oakhaven integrada (LEER PRIMERO)
- **Muestra** (`MUESTRA_CALLE_OAKHAVEN.md`): escena aparte `zonas3d/muestra_calle/`, solo desde el banco de Auditoría
  («Muestra gráfica: una calle de Oakhaven (en pruebas)»), apagada para el juego; excluida de las APK sin banco. Hecha
  por un agente (rama `area-grafico/muestra-calle`, integrada por cherry-pick) con generador de Blender reproducible y
  luz horneada. Revisión independiente: 6 hallazgos corregidos en `e857b93`, validado con 189 · 0 (`2026-11-15_200905`) (faroles de pie negros, título, dos
  aserciones, medida sin vsync, comparación justa: 27 llamadas frente a 80 de la Calle del Cuervo, solo con Kael).
- **Verificado en PC:** 30 FPS con su límite en bajo y medio; 2,2-2,8 ms sin límite en el bajo; capturas antes/después,
  vídeo `kael_calle_bajo.mp4` en `D:\REBELUM_diagnostico\muestra_calle_15_11\`.
- **Pendiente:** medirla en el Redmi (hace falta una APK nueva); visto bueno del usuario a la dirección (tarde dorada,
  cámara más baja); la hora azul horneada; texturas pintadas a mano; la rareza de las transparencias en bajo/medio.
- **Siguiente acción:** esperar a que el usuario vea la muestra. NO extender la renovación al resto del juego sin su
  visto bueno.
- Batería: un cierre de Godot con fallo de memoria (0xC0000005) tras `prueba_banco_pruebas` con «FALLOS: 0» es
  intermitente y anterior (ya en `2026-11-15_024023`); sola pasa 3/3.

## RELEVO 15/11, 21:15: la muestra de la calle medida en el Redmi (LEER PRIMERO)
- APK `3a08f35` (v843, SHA `2c0f77ff…aee4b`) instalada por el usuario. Muestra en perfil bajo: **30 FPS sostenidos**
  en 7 ciclos (≈ 11 min), memoria estable (PSS 768-826 MB en la calle), sin calentamiento. Detalle en `REDMI_15_11.md`.
- El usuario aprobó la dirección artística de la muestra y pidió conservar su aspecto. NO extender la renovación sin
  que lo pida. Observaciones para él: Kael muy azul en la sombra del callejón, su sombra poco visible, el tejado del
  oeste puede taparle arriba del callejón; el regulador de calidad escribe ajustes desde el banco.
- Teléfono devuelto al estado previo (SHA iguales; `ajustes.cfg` y `calidad.log` restaurados byte a byte).
- PENDIENTES que NO se dan por resueltos: cierre intermitente de Godot (0xC0000005) y transparencias en bajo/medio.
- **Siguiente acción:** esperar la decisión del usuario sobre las observaciones de la muestra y sobre su extensión.

## RELEVO 15/11, 23:05: correcciones de la muestra probadas en el Redmi (LEER PRIMERO)
- Hecho (autorizado por el usuario): cámara en el eje del callejón, luz de Kael en sombra sin azul, sombra de contacto,
  diagnóstico de tirones, calidad del banco aislada y selector «Calidad 3D» (fija ×0,75 / regulador). Validado
  `02079bb` (`validado/v12/20261115-224238`, 189 · 0). APK `4eb4f9b` v849 instalada y probada (`REDMI_15_11.md`,
  sesión 22:45): 30 FPS, tirón de entrada tras instalar = compilar sombreados (una vez), resto CPU en negro; la 1.ª
  vuelta ya no tiene tirones; precalentado apagado (no aporta); teléfono idéntico sin restaurar.
- Versión anterior: `recuperacion/v12/20261115-antes-correcciones-muestra` (`47e8cb1`).
- ABIERTOS (no se declaran resueltos): cierre 0xC0000005 (recursos de render/texto retenidos por cachés estáticas al
  apagar; el experimento 20+20 no lo reprodujo) y transparencias en bajo/medio.
- **Siguiente acción:** decisión del usuario sobre los remedios de la entrada (compilar en la carga, caché de la luz,
  unir choques) y sobre extender la renovación. NO extender sin que lo pida.

## RELEVO 16/11, 00:20: optimizaciones cerradas; empieza el barrio de Oakhaven (LEER PRIMERO)
- Encargo nocturno del usuario (15/11, 23:50): cerrar optimizaciones → barrio jugable de Oakhaven (interiores, rutinas,
  misión «Antes de que se enfríe») → Sunken City → Arboleda Mítica. Autonomía para decisiones técnicas reversibles;
  canon y gastos: documentar y seguir. Sin push, PR, fusiones ni instalaciones en el teléfono.
- Optimizaciones (`MUESTRA_CALLE_OAKHAVEN.md` §7.d): precalentado en la carga (corregido para la misma variante),
  materiales y luz reutilizados entre entradas (soltados al salir del banco); un solo cuerpo de choques DESCARTADO (sin
  mejora). APK `eb68d54` v854 (SHA `1d318c5e…693456`) en el PC, NO instalada; guion en `GUION_REDMI_15_11.md`.
- Batería `7c8da75`: 188 · 1 (prueba_audio intermitente, sin regresión medida). Última validada: `02079bb`.
- Recuperación antes del barrio: `recuperacion/v12/20261116-antes-barrio` (`eb68d54`).
- Barrio: plan en `BARRIO_OAKHAVEN_PLAN.md` (estudio en `D:\REBELUM_diagnostico\barrio_oakhaven\estudio\`). Fase 0
  (contrato y blockout) → agentes A (exterior/kit), B (interiores), C (rutinas/misión) en ramas `area-barrio-*`.
- ABIERTOS: cierre 0xC0000005, transparencias en bajo/medio, prueba_audio intermitente.

## RELEVO 16/11, 01:15: barrio en construcción por agentes (LEER PRIMERO)
- Integrado en `claude/rebelum-v12`: fase 0 del barrio (`7ec2090`..`c3eace5`, contrato, blockout jugable, caso del
  banco; `prueba_barrio_trazado` + banco + muestra: 4·0) y los diseños `SUNKEN_ARBOLEDA_PLAN.md` y
  `ACTIVIDADES_FUTURAS.md`. Recuperación: `recuperacion/v12/20261116-antes-fase0-barrio`.
- Agentes EN MARCHA (copias aisladas, ramas desde `a4cbbe8` / `2d7745d`):
  - `area-barrio-a`: exterior con el acabado de la muestra (kit_barrio.py, sectores horneados).
  - `area-barrio-b`: interiores (horno, taller, vivienda) y utensilios.
  - `area-barrio-c`: rutinas (Maela, Tobías, Brena + Avena), misión «Antes de que se enfríe» (premio Éter ×2), sabe/oído/cree.
  - `area-sunken-quilla`: Sunken City, la Quilla horneada (+ obreros, + paso de babor y El Ancla Seca si cumple).
  - Turno de horneado de Blender con `D:\REBELUM_coordinacion\horneado.lock`.
- Siguiente acción: integrar cada rama por cherry-pick al terminar (archivos compartidos: banco_pruebas.gd,
  lista_pruebas.txt, prueba_banco_pruebas.gd, crear_npc_chibi.py, recursos.gd, export_presets.cfg), pasar las pruebas
  específicas y, con todo dentro, la batería completa, la APK de Auditoría y el guion; después, la Arboleda Mítica
  (plan en `SUNKEN_ARBOLEDA_PLAN.md` §3).

## RELEVO 16/11, 04:10: barrio y Quilla integrados; pulido y Arboleda en marcha (LEER PRIMERO)
- INTEGRADO en `claude/rebelum-v12` (cherry-pick; recuperaciones `recuperacion/v12/20261116-antes-barrio-b`, `-antes-barrio-a`,
  `-antes-sunken-quilla`, `-barrio-integrado`): barrio de Oakhaven completo (A exterior horneado de 6 tramos, B 3 interiores
  horneados, C rutinas + misión «Antes de que se enfríe» + sabe/oído/cree) y la Quilla horneada de Sunken (apagada por
  interruptor). 14 pruebas específicas: 14·0. Índice de Dialogic con los personajes y diálogos del barrio en project.godot.
- El recorrido JUGADO de la misión (`fotos_barrio_recorrido`) a 1280×720 da 30 fallos en los interiores (la herramienta se
  escribió antes que ellos); a 1600×720, además, la franja negra de 16:9 desplazaba los clics (no es un fallo del juego:
  `pruebas/diag_barrio_paso.gd`).
- EN MARCHA: pulido del barrio (workflow de 2 agentes: región — rótulos, luz dentro, NaN de altura en una costura, suelo en
  sombra con trazos blancos, cámara de atajo/talleres, precalentado, triángulos del residencial — y datos — piezas de dentro,
  galga, vecinos dentro, recorrido a cualquier resolución con la misión entera); Arboleda Mítica (`area-arboleda-hospederia`).
- Siguiente acción: integrar el pulido, pasar el recorrido jugado (0 fallos a 1280 y 1600), revisión independiente, batería
  completa, APK de Auditoría y guion; luego la Arboleda.
