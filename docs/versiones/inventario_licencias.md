# Inventario de licencias de REBELUM / Aethelgard

**Hecho el 2026-11-07** sobre `rebelum-alpha`, recorriendo `aethelgard/` y dejando fuera `.godot` y `addons`. Las
condiciones de Meshy y Suno se leyeron ese mismo día en sus páginas oficiales.

**Para qué sirve:** decir con exactitud qué recursos tienen derechos pendientes y qué usos bloquean. Lo pidió el usuario
el 07/11: es la decisión D-050 de la memoria (`D:\Aethelgard\DECISIONS.md` o `git show memoria-desarrollo:DECISIONS.md`).

**Las reglas que se aplican**
- Se avanza con recursos autorizados o con sustitutos.
- El **paquete entregable** (toda APK que salga del PC para distribuirse, también por GitHub) **no lleva nada sin
  acreditar**.
- Las compilaciones de **prueba privada** del usuario son locales y llevan el aviso `NO_DISTRIBUIR`.
- `compilar_apk_experimental.ps1` busca en cada APK los patrones de [licencias_pendientes.txt](licencias_pendientes.txt).

## 1. Lo que dicen hoy las condiciones oficiales

**Meshy.** Páginas de ayuda del 27/08/2026 ([9992001](https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects),
[10137554](https://help.meshy.ai/en/articles/10137554-what-is-the-ownership-of-the-generated-models)) y
[precios](https://docs.meshy.ai/en/webapp/pricing):
- **Plan gratuito:** licencia CC BY 4.0. Permite el uso comercial **con atribución**. El formato que proponen es «Model
  created with Meshy – CC BY 4.0 License».
- **Planes de pago:** el usuario es dueño de lo que genera y no necesita atribución, siempre que lo que subió no viole
  derechos de terceros.
- **Lo que esas páginas no aclaran:** qué pasa al cambiar de plan, y no mencionan restricciones para videojuegos.
- **En consecuencia:** con los créditos de Meshy, sus modelos se pueden distribuir con cualquiera de los dos planes. Lo
  que queda por confirmar es que las imágenes que el usuario subió a Meshy fueran suyas o libres.

**Suno.** Ayudas [2425729](https://help.suno.com/en/articles/2425729),
[9601665](https://help.suno.com/en/articles/9601665) y [9601601](https://help.suno.com/en/articles/9601601), y
[condiciones](https://suno.com/terms) (revisión del 10/08/2026, en vigor desde el 03/09/2026):
- **Plan gratuito:** solo uso personal y no comercial; no se puede monetizar.
- **Suscribirse después no da derechos retroactivos.**
- **Con Pro o Premier:** las canciones descargadas durante la suscripción tienen uso comercial, también en videojuegos,
  y lo conservan al cancelarla.
- **Proyecto personal:** el plan gratuito permite usarlas en «un proyecto personal que no se monetiza». Las páginas no
  hablan de juegos expresamente.

## 2. Recursos acreditados

Se pueden distribuir.

| Recurso | Dónde | Licencia y evidencia |
|---|---|---|
| Código del juego, Posador y textura de matas | `*.gd`, `addons/posador`, `modelos/hojas/matas.png` | Propios |
| Godot y Dialogic | Motor y `addons/dialogic` | MIT |
| Quaternius | `decorado/quaternius/`, `vegetacion_prueba/quaternius/` | CC0 (`LICENCIA_CC0.txt`, `LICENSE_Quaternius.txt`) |
| Poly Haven | `texturas/` | CC0 (`texturas/CREDITOS.txt`) |
| Fuentes Cormorant y Saira Condensed | `fuentes/` | OFL (`OFL_*.txt`, que deben ir con ellas) |
| Logo de REBELUM | `marca/rebelum_logo.webp` | Del autor |
| Movimientos de doble espada | `garon_espadas.res` | Uso comercial permitido. El original del pack de Patreon no se redistribuye; solo va el convertido |

## 3. Recursos con derechos pendientes y usos que bloquean

**Cómo leer la tabla**
- **Commit:** guardarlo en el repositorio privado.
- **Prueba privada:** usarlo en el PC o en el móvil del usuario sin distribuirlo.
- «Sí» quiere decir que hoy está permitido.

| # | Recurso | Archivos | Origen | Commit | Prueba privada | APK entregable | Qué lo desbloquea |
|---|---|---|---|---|---|---|---|
| 1 | Personajes 3D | `kael.fbx`, `Meshy_AI_Anime_Girl_…fbx` (Lya), `garon.fbx` y `Meshy_AI_Crimson_Helm_Guardian_*`, `goblin.fbx` y `Meshy_AI_Grimfang_Goblin_*`, `erebo_*.fbx` (6), con sus texturas | Meshy. Las animaciones son de Mixamo, dentro de los FBX | Sí (ya están) | Sí | **No**, sin créditos | Créditos de Meshy y confirmar las imágenes de partida. Los términos de Mixamo no se han comprobado hoy |
| 2 | Armas 3D | `sable.obj` (Frostfang), `vara.obj`, `espada2.obj`, `hacha.obj`, `hoja_infernal.obj`, `averno.obj`, `diamante_azul.obj` y sus texturas | Meshy, según el historial (ZIP `Meshy_AI_…` del 02/11 al 04/11) | Sí | Sí | **No** | Confirmar el origen de cada una y añadir los créditos |
| 3 | Ciudad flotante | `isla/` (7) | Renders de «Meshy_AI_Myth_Grove_Starter_Island» | Sí | Sí | **No** | Créditos de Meshy |
| 4 | Guardián de piedra (estatua) | `modelos/guardian/` | Meshy | Sí | Sí | **No** | Créditos de Meshy |
| 5 | Decorado 2D que no es de Quaternius | `decorado/{abedul, arce, cerezo, flor_azul, glicinia, helecho, hierba_alta, pino, platanera}.png` | Sin registrar; probablemente renders de vegetación de Meshy | Sí | Sí | **No** | Registrar el origen |
| 6 | Dibujos 2D | En la raíz: `hollin_*`, `kael_*` y `kael2_*` (recortables), `kael_ilu_*`, `kael.png`, `nyx*`, `aventurero_*`, `fondo.png` y `mapa_kael.png`. Además: `personajes/` (Hollín, Kael y Nyx recortables), `personajes/kael_mapa/`, `personajes/npc/`, `enemigos/`, `dialogos/retratos/` y `objetos/` | Sin registrar: aportados por el usuario o hechos con renders | Sí | Sí | **No** | Registrar el origen de cada grupo |
| 7 | Slime | `personajes/slime/` (42) | «Free RPG Sprites» (aportado el 30/10) | Sí | Sí | **No** | Encontrar la licencia del pack |
| 8 | Efectos de magia | `vfx/*.png` y `vfx/*.res` (los `.gdshader` son propios) | Hechos con los GLB que aportó el usuario (`realistic_fire_vortex.glb`, etc.) | Sí | Sí | **No** | Registrar el origen de los GLB |
| 9 | Sonidos de Érebo | `sonidos/erebo_*.wav` (7) | Del ZIP `erebo_aethelgard.zip` del usuario | Sí | Sí | **No** | Registrar el origen |
| 10 | Música de combate | `musica_combate_normal.mp3` | Sin registrar | Sí | Sí | **No** | Registrar el origen |
| 11 | Cuatro pistas de Suno | Fuera del proyecto (ZIP en Descargas) | Suno, con el plan sin confirmar | **No** | Solo como proyecto personal sin monetizar | **No** | Saber con qué plan se generó y descargó cada pista |
| 12 | Césped EmacE | `vegetacion_prueba/emace/`, solo en la copia del usuario | EmacEArt: «prohibido vender o redistribuir los archivos… ni dentro de otro paquete» | **No** (está en `.gitignore`) | Sí, en el PC del autor | **No** | Un sustituto: matas opacas (T-062) |
| 13 | Arce de Meshy, descartado | `modelos/arce/`, solo en la copia del usuario | Meshy | **No** (`.gitignore`) | Sí | **No** | No hace falta: no se usa |

**Uso que ya se hizo y conviene revisar:** la pre-release `v0.1.0` de GitHub lleva una APK con los grupos 1 a 10. La
decisión de mantenerla es del usuario. No se ha tocado.

## 4. Qué significa para la APK experimental

- **Hoy no hay paquete entregable jugable:** casi todo el arte del juego está en los grupos 1 a 10.
- **La compilación experimental** es una prueba privada con el aviso `NO_DISTRIBUIR`.
- **El paso que más desbloquea:**
  1. Añadir los créditos de Meshy, que cubren los grupos 1 a 4 con cualquier plan.
  2. Que el usuario confirme el origen de las imágenes que subió a Meshy y de los grupos 5 a 10.
- **Pastos Verdes 3D** (T-021) usa recursos del grupo 1 (Kael) y, si existe, el guardián del grupo 4. Su vegetación
  (árboles estilizados, matas propias y césped del prototipo) es propia. No usa EmacE.
