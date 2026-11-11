# RETOMAR la V12 (El Mar de Cristal)

Punto seguro del 11/11 a las 13:00 (sesión «REBELUM V12 desarrollo continuo»). Antes de seguir, lee
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

## Siguiente (en este orden)

1. Batería completa (`ci_local.ps1` o `ejecutar_pruebas.ps1` sin `-Solo`) y arreglar regresiones.
2. Capturas con ventana del sector en alto y bajo y, con ellas:
   - **arena quemada a blanco en el perfil alto** (gráficos: píxel 255,255,147): luz de la región y parámetros del
     sombreado de arena (desde la región, sin tocar los archivos de gráficos si no hace falta);
   - **rocas algo cilíndricas:** componer varias piezas por roca, giros y escalas no uniformes;
   - **perfil bajo más oscuro** (hallazgo de gráficos: en Compatibility, con sombras, ambiente y bruma suman más):
     compensar el ambiente sin sombras, medido antes y después, sin rebajar el alto; afecta a todas las regiones
     (`prototipos/vista3d.gd` o `calidad_proto.gd`), así que con capturas de las demás.
3. Bramavidrio mejor: modelo provisional más orgánico (o GLB de gráficos) y su foto.
4. Enemigos del desierto al azar: Vidracrán y Tolvanera (nombres de narrativa, sin aprobar).
5. Rendimiento en el PC (llamadas, primitivas) y, con permiso, APK de auditoría para el Redmi.
6. Volúmenes del desierto sin escuchar (nadie los ha oído).

## Notas

- `--check-only` sin autoloads da «Identifier not found: Sonido» en cualquier guion que lo use: no es un error.
- Con `--fixed-fps 30` sin ventana, los fotogramas van más rápido que el reloj: lo que carga en un hilo (el combate)
  se espera en milisegundos reales.
