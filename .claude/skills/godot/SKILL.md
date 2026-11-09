---
name: godot
description: Escenas, GDScript, importación de modelos (GLB y FBX), señales y comprobaciones de combate en REBELUM (Godot 4.7.2, renderizador Compatibility). Úsala al tocar código o escenas del juego, al importar un modelo o al enganchar un enemigo o un ataque al combate ATB.
---

# Godot en REBELUM

**Origen.** Adaptada de la skill «godot» de Atlas Agent Teams (`MonumentalSystems/Atlas-Agent-Teams`,
`teams/game-dev/skills/godot/SKILL.md`, revisión `898df03641be`), con licencia MIT, © 2026 Monumental Systems
(texto en `LICENSE-ATLAS.txt`). De ella vienen las reglas generales de GDScript. Lo propio de REBELUM (proyecto,
importación de modelos y combate) es nuevo. **Las normas de `CLAUDE.md` prevalecen sobre esta guía.** Para estas
tareas sustituye a `aet-auditoria-godot`, `aet-pruebas-depuracion` y `aet-combate-jrpg`, que están desfasadas.

## El proyecto
- **Motor:** Godot 4.7.2, renderizador Compatibility (GLES3).
- **Plataformas:** Android primero (Redmi A7 Pro con Mali-G57); luego PC, Android TV e iOS.
- **Proyecto:** `aethelgard/`. Consola: `C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe`.
- **Nunca dos Godot sobre la misma copia.**
- **Estructura real:**
  - los guiones principales están en la raíz del proyecto: `combate.gd`, `mapa.gd`, `zona.gd`, `menus.gd`,
    `progreso.gd`…;
  - las regiones 3D, en `zonas3d/` (el «contrato» lo describe `modo3d.gd`);
  - los diálogos, en `dialogos/` (Dialogic 2);
  - las ciudades, en `ciudades/`;
  - las pruebas, en `pruebas/`.
- **Autoloads:** `Sonido`, `Musica`, `Dialogic`, `BotonDialogo`, `Recursos`, `Entrada`…
- **Idioma:** español en comentarios, textos y nombres nuevos.

## GDScript: reglas generales (de la base)
1. `@onready` para los nodos hijos y `@export` para lo que se ve en el inspector.
2. Señales para comunicar sin acoplar; no tirar del árbol hacia arriba.
3. `_physics_process` para la física y `_process` para lo visual.
4. Tipos en todo (`func atacar(objetivo: Dictionary) -> int:`); arrays y diccionarios tipados cuando se pueda.
5. `queue_free()` para destruir y `call_deferred()` para cambiar el árbol mientras se recorre.
6. Tweens para las animaciones sencillas; grupos para las operaciones en lote.
7. Nada de `get_node()` con rutas largas ni de `find_child()` en `_process`: se guardan las referencias.
8. Nombres: `snake_case` en funciones y variables, `PascalCase` en clases, `MAYÚSCULAS` en constantes y `_privado`.

## Reglas propias de REBELUM
- **Nunca guardes un recurso (Resource) en los metadatos de `Engine`:** Godot se cae al cerrar (0xC0000005). Guarda
  su ruta.
- **Partidas:** las claves nuevas van al final de `CLAVES` (`progreso.gd`), con valores por defecto. Una partida
  antigua debe cargar igual. Nada escribe en la partida real.
- **Señales de una vez** (fin de un clip, de un diálogo o de un combate): `CONNECT_ONE_SHOT`, y desconéctalas al salir.
  No vuelvas a conectarlas en cada turno.
- **Pruebas:**
  - guiones que heredan de `SceneTree`, lanzados con `pruebas/ejecutar_pruebas.ps1` **desde PowerShell**, que aísla
    los datos;
  - sin ventana y con `--fixed-fps 30`, salvo las capturas;
  - antes de un combate determinista, espera unos fotogramas a que el paso fijo se asiente.
- **Importar con datos aislados:**
  `$t='D:\REBELUM_diagnostico\importaciones\<área>_<fecha>'; New-Item -ItemType Directory -Force "$t\A","$t\L","$t\T";`
  `$env:APPDATA="$t\A"; $env:LOCALAPPDATA="$t\L"; $env:TEMP="$t\T"; $env:TMP="$t\T"; & <godot> --headless --path <proyecto> --import`
- **Los `.uid`** los genera Godot. Confirma solo los de tus archivos.

## Importar un modelo (GLB o FBX)
1. Cópialo a su carpeta del proyecto (por ejemplo `enemigos/<nombre>/`). Si una fuente es grande (un `.blend`), déjala
   fuera del historial y documéntala (D-075). Si vive dentro del proyecto, ponle `.gdignore`.
2. Impórtalo con datos aislados y revisa su `.import`:
   - escala (alturas relativas frente a los enemigos y héroes actuales);
   - orientación (mirando a la cámara de combate);
   - materiales (Compatibility: `StandardMaterial3D`, sin efectos que no existan en GLES3);
   - compresión de texturas (ETC2/ASTC en Android). Las de 2K pueden necesitar una variante de 1K para el perfil bajo:
     mídelo antes de decidir.
3. **Esqueleto y clips:**
   - lista los clips (`AnimationPlayer.get_animation_list()`) y comprueba sus nombres;
   - en bucle solo el reposo;
   - los ataques, «en el sitio»: la posición lógica del combate va aparte y no se suma otro avance visual sin probarlo;
   - revisa los huesos que usan Posador o el IK.
4. **Escena de prueba:** instancia el modelo, reproduce cada clip y haz capturas con ventana desde la cámara real.
5. **Procedencia:** una fila en `docs/recursos.md` (origen, licencia y estado).

## Enganchar un ataque al combate ATB
- **El combate decide** (`combate.gd`): los objetivos y el daño se resuelven **una sola vez**. El clip solo lo
  representa.
- **Anclas de tiempo de cada ataque:** aviso → impacto → recuperación → vuelta al reposo. En el impacto, en el mismo
  instante:
  - la resolución del daño;
  - el sonido (`Sonido.golpe` / `Sonido.efecto`), que no se dispara dos veces;
  - la reacción del objetivo (`recibir_golpe`).
- **Interrupciones:** la carga, la pausa, la huida, la derrota y el final del combate resuelven o cancelan el ataque
  según el ATB vigente, sin dejarlo a medias ni duplicarlo.
- **Lo protegido no cambia:** las 12 magias, Esgrima, Embuir, Érebo, la Armonía y el ATB (D-048). Garon no usa magia
  (D-037).
- **Comprobaciones:**
  - la huella de combate (`prueba_combate_huella`), que no debe cambiar sin explicarlo;
  - las pruebas de grupos de 1, 2 y 3 (`prueba_grupos_combate`, `prueba_incorporacion`);
  - `prueba_equilibrio`, `prueba_ia` y `prueba_menu_magia`;
  - y una prueba nueva del enemigo: aviso, ataques, defensa, victoria, huida y vuelta.
- **En el Redmi:** lo medido en el PC describe el PC. Texturas, huesos y coste de render se revisan antes de ampliar
  encuentros en Android.
