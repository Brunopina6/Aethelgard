# RETOMAR la V12 (El Mar de Cristal)

Punto seguro del 11/11 a las 13:35 (sesión «REBELUM V12 desarrollo continuo»). Antes de seguir, lee
`D:\Aethelgard\CLAUDE.md` (protocolo) y `CONTINUAR_V12_NUEVA_SESION.md`, en la raíz de esta copia.

## Git

- **Trabajo:** `claude/rebelum-v12` en `D:\Aethelgard_v12`, LOCAL. Ver `git -C D:\Aethelgard_v12 log --oneline -15`.
- **Sin push ni merge** (orden del usuario). La integración de especialistas se hace copiando sus archivos de su rama
  (`git checkout <rama> -- <rutas>`), no fusionando ramas.
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

- **Después:** el especialista de combate hará los tres ataques (Embestida del Abismo, Fractura del Mar de Cristal y
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
