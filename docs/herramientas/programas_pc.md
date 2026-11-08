# Programas del PC para REBELUM

Inventario comprobado el 08/11/2026 a las 22:45 (coordinador; versiones leídas de los propios programas). REBELUM es
el nombre oficial del juego; Aethelgard es el nombre técnico de las carpetas y los repositorios.

| Programa | Versión y ruta | Para qué | Estado |
|---|---|---|---|
| Godot | 4.7.2 stable (`C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64_console.exe`) | Integración, escenas, pruebas, capturas, vídeo (`--write-movie`), exportación | Operativo. Dos Godot sobre la misma copia se pisan |
| Blender | 5.2.3 LTS (`C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`) | Poses, clips, renders de retratos, modelos y materiales | Operativo (`--background` con scripts) |
| Posador | complemento del proyecto (`aethelgard/addons/posador`) | IK y poses para Mixamo dentro de Godot | Se comprueba en cada uso (`prueba_posador`) |
| Cascadeur | 2024.1.1 (`C:\Program Files\Cascadeur`) | Animación asistida | **No utilizable por el coordinador:** pide iniciar sesión con la cuenta del usuario (`cascadeur_auth.exe`) y no hay sesión guardada en este PC. Las credenciales no las introduce el agente |
| Herramientas de Android | build-tools 35.0.0 (apksigner, aapt2, zipalign) y adb 1.0.41 (`%LOCALAPPDATA%\Android\Sdk`) | Comprobar paquete y firma de las APK; copiarlas al Redmi por USB | Operativas. En el Redmi solo se copian APK de prueba a Descargas (D-065) |
| Arm Performance Studio | 2026.6 (`C:\Program Files\Arm\Arm Performance Studio 2026.6`) | `malioc` (coste de sombreadores en Mali-G57, sin el teléfono); Streamline, Frame Advisor y RenderDoc for Arm | `malioc`, operativo sin el teléfono. Los demás necesitan instalar un agente o una capa en el Redmi: hace falta una autorización nueva |
| Java | 17.0.20 (Eclipse Adoptium) | apksigner y exportación de Godot | Operativo |
| Python | 3.10.11 (lanzador `py`) | Scripts auxiliares (audio, imágenes, informes) | Operativo; el `python` de WindowsApps es solo el atajo de la Tienda |
| Git, GitHub CLI, Git LFS | `git`, `gh`, `git-lfs` 3.8.1 | Respaldo, revisión y publicación (D-070) | Operativos. LFS no está configurado en el repositorio y no se usa |

**No instalados:** ffmpeg, ImageMagick, Krita, GIMP, Inkscape y Audacity. No se instalan sin permiso. Las alternativas
locales son Godot (vídeo, capturas y procesado de imágenes y audio con scripts), Blender (vídeo e imágenes) y Python.
