---
name: blender-animation
description: Editar esqueletos, preparar clips, revisar deformaciones y exportar animaciones (GLB) para REBELUM con Blender 5.2.3 por script. Úsala para crear o ajustar clips de héroes y enemigos (reposo, ataques, recibir golpe, derrota, entrada), renderizar poses y llevar el resultado a Godot.
---

# Animación con Blender en REBELUM

**Origen.**
- Ideas y estructura de la skill «blender-animation» de terminal-skills (su cabecera declara Apache-2.0), vista en
  `Andrew1326/dominations`, `.claude/skills/blender-animation/SKILL.md`, revisión `e8c31141fdc7` (2026-05-29).
- Ese repositorio no tiene archivo de licencia, así que **no se copia su texto**. Solo se usan patrones de la API de
  Blender (`bpy`), que son de uso general. El resto está escrito para REBELUM (aviso en `NOTICE.txt`).
- **Las normas de `CLAUDE.md` prevalecen.** Para estas tareas sustituye a `aet-rigging-animacion` y
  `aet-meshy-blender`, que están desfasadas.

## La herramienta
- **Blender 5.2.3 LTS:** `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`. Se usa siempre por script:
  `blender --background <archivo.blend> --python <guion.py> -- <argumentos>`.
- **Dónde van los guiones:**
  - los temporales, en la subcarpeta de tu área de la carpeta temporal de la sesión;
  - los que hay que conservar, en `pruebas/herramientas/` o junto a sus fuentes, con `.gdignore`.
- **Los `.blend` grandes,** fuera del historial (D-075), documentados con su ruta.
- **Nada de instalar complementos.** Cascadeur pide la sesión del usuario: no se usa.
- **Nunca se edita el original.** Se trabaja sobre una copia con nombre nuevo, y la fuente se conserva.

## Esqueletos
- Inspecciona antes de tocar: los huesos, su jerarquía y la pose de reposo
  (`for b in arm.data.bones: print(b.name, b.parent)`).
- No cambies el nombre ni la pose de reposo de los huesos que ya usan los clips, Posador o el IK del juego.
- Los huesos se editan en modo EDIT y las poses en modo POSE.

## Clips (acciones)
- **Una acción por clip,** con el nombre exacto que usa el juego, en español: `reposo`, `embestida_espinosa`,
  `recibir_golpe`, `derrota`, `entrada`…
- **«En el sitio»:** sin trasladar la raíz, salvo que se acuerde. La posición del combate es lógica.
- **Un ataque** tiene aviso (anticipación clara), impacto y recuperación:
  - el fotograma del impacto se documenta en segundos, porque es el ancla de daño, sonido y reacción;
  - el último fotograma vuelve a la pose del reposo para que la mezcla sea limpia.
- **En bucle,** solo el reposo.
- **Claves:**
  - `pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=n)`, o `rotation_euler` según el modo del hueso;
  - interpolación Bézier; los cortes secos, a propósito y anotados.
- **Exportación:** que el exportador vea todas las acciones, con `export_animation_mode='ACTIONS'` o con pistas de NLA.

## Revisar deformaciones
- **Poses clave** renderizadas con cámara y luz fijas (frente y 3/4), antes y después, a
  `D:\REBELUM_diagnostico\<área>\<fecha>\`.
- **Qué mirar:** codos, rodillas, hombros y cuello; pesos que se escapan; piezas que se cruzan; pies que no apoyan o
  que patinan; armas en su sitio.
- **Cómo medirlo:** el deslizamiento del pie (la velocidad del pie apoyado frente al suelo) y la silueta frente a la
  referencia, cuando haga falta demostrar una causa.

## Exportar a GLB
- `bpy.ops.export_scene.gltf(filepath=..., export_format='GLB', export_animations=True,
  export_animation_mode='ACTIONS', export_force_sampling=True)`.
- En Blender 5.x comprueba antes los nombres de las opciones:
  `bpy.ops.export_scene.gltf.get_rna_type().properties.keys()`.
- **Texturas:** en el móvil cuestan memoria. Prepara una variante de 1K para el perfil bajo solo si la medida lo pide;
  el perfil alto no se rebaja.

## Comprobar en Godot
Sigue la skill `godot` (§ Importar un modelo):
- importa con datos aislados y lista los clips;
- reproduce cada uno desde la cámara de combate;
- comprueba el tiempo del impacto, el bucle, la escala y la orientación;
- haz capturas o un vídeo corto (`--write-movie`);
- registra la procedencia en `docs/recursos.md`.
