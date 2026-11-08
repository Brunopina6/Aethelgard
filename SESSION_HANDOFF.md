# SESSION_HANDOFF: punto de control

**Último punto de control:** 2026-11-09 a las 00:20 (hora local, UTC+1). Noche de trabajo autónomo: el usuario duerme y
pidió no preguntar ([MEMORIA_CHAT.md](MEMORIA_CHAT.md)). **La memoria describe `integracion-experimental` @ `713fe8d`.**

- **Encargos vigentes, de más antiguo a más nuevo** (todos en [MEMORIA_CHAT.md](MEMORIA_CHAT.md)):
  1. Organización por especialistas ([D-069](DECISIONS.md#d-069)) y GitHub por ramas de trabajo
     ([D-070](DECISIONS.md#d-070)).
  2. Sesión larga y autónoma, con prioridades 1-7 (22:40). El usuario: «acepto todo… no me preguntes más».
  3. Ciudades, sitios nuevos y magias nuevas ([D-071](DECISIONS.md#d-071)).
  4. Equipo, enemigos, compañeros, secretos, grutas y posadas ([D-072](DECISIONS.md#d-072)). Puede usar cualquier
     programa del PC y debe centrarse mucho en lo visual y el lore.
- **Decisiones de la noche, para que el usuario las revise:** [D-073](DECISIONS.md#d-073).

## Hecho y comprobado esta noche

| Qué | Commit | Comprobación |
|---|---|---|
| Sonido, tanda 1 ([T-083](TASKS.md#t-083)): 100 efectos de la biblioteca (CC0 y Sonniss 2016-2024, licencias comprobadas), API con voces, prioridades y variantes, enganches en eventos reales | `091bcfb` (rama `area-sonido`) | Batería de la integración: 39 superadas, 0 fallidas. **Sin escuchar:** muestras en `D:\REBELUM_diagnostico\sonido_muestras\2026-11-08\` |
| Animaciones, tanda 1 ([T-084](TASKS.md#t-084)): la mano de Kael venía de la ilustración (render del reposo con sable, sin sable). Cinco retratos nuevos desde el modelo; Kael escucha en reposo; en 3D quien escucha mira a quien habla | `e84cf32` (rama `area-animaciones`) | Batería del especialista: 37 superadas, 0 fallidas. Antes y después y vídeos en `D:\REBELUM_diagnostico\animaciones\2026-11-08\` |
| El ejecutor solo se niega si hay un Godot en su misma copia (los demás, aviso y vigilancia) | `d2df536` | Batería con 8 Godot ajenos abiertos: limpia |
| Botón «Probar el prólogo (partida nueva)» en la carga ([T-081](TASKS.md#t-081)) | `713fe8d` | `prueba_boton_prologo` (nueva) y regresiones de mando, teclado, foco, prólogo, ranura y precalentado: superadas |
| `prueba_efectos` estable (comparaba con −6 dB fijos) | `713fe8d` | 5 de 5 pasadas |

## Dónde está todo

| Qué | Valor |
|---|---|
| Integración | `D:\Aethelgard_alpha`, rama `integracion-experimental` @ `713fe8d`. En GitHub, `1c17763` hasta el próximo push |
| Especialistas | Copias `D:\Aethelgard_<área>`, ramas `area-<área>`: sonido (terminada, integrada), animaciones (terminada, integrada), gráficos (fase 1 del mapamundi, en marcha desde las 23:12), combate y narrativa (fase 0, solo diseño, en marcha desde las 23:45). Todas son ya carpetas de trabajo de la sesión |
| Configuración de los especialistas | `.claude/agents/especialista-*.md`. Esta sesión no los reconoce por nombre: se lanzan como `general-purpose` que leen su archivo |
| Copia del usuario | `D:\Aethelgard`, rama `rebelum-3d` @ `b8e042d` con el bloque B sin tocar. Su editor se cerró antes de las 23:10 |
| Memoria | `D:\Aethelgard_memoria`, rama `memoria-desarrollo` |
| Respaldo | `D:\REBELUM_respaldos\2026-11-08_rebelum-alpha_375cc8c\rebelum-alpha.bundle`; los `.uid` generados que se apartaron al integrar, en `D:\REBELUM_respaldos\2026-11-09_uid_generados_integracion\` |
| Redmi | No conectado a las 23:20. La copia de las APK de la noche queda para mañana; las APK irán a `Aethelgard-pruebas` |
| Programas | `docs/herramientas/programas_pc.md`. Cascadeur pide la sesión del usuario; las herramientas de Arm en el teléfono necesitan permiso |
| Inventario para ciudades, lugares y magias | `docs/memory/inventario_lugares_magias_2026-11-08.md` |
| Partida real | `A3F3C402…` (19:37 del 08/11), sin cambios en todas las pasadas |

## Próximo paso concreto (por dependencias)

1. **Batería completa de `713fe8d`** (en marcha a las 00:15). Si sale limpia: push de `integracion-experimental`,
   `area-sonido` y `area-animaciones`. La revisión ya está hecha: 264 archivos y 18,9 MB, sobre todo efectos con
   licencia comprobada, y ningún `.blend`.
2. **APK de prueba** con `compilar_apk_experimental.ps1` (el versionCode se numera solo), su release en
   `Aethelgard-pruebas` (primero la fila del README) y las notas: qué probar.
3. **Gráficos, fase 2:** cuando entregue la fase 1, se integra `integracion-experimental` en `area-graficos` y pasan a
   gráficos `mapa.gd` y `mapa.tscn`.
4. **Animaciones, tanda 2:**
   - que los pies no patinen (Kael anda a 4,2 m/s con un clip pensado para 1,2-1,5 m/s);
   - Lya y Garon presentes cuando hablan en PV-03 y PV-05 (`pastos_verdes_3d.gd`, ya libre);
   - retratos vivos en Pastos Verdes, poses de Lya y la señal `pisada` para los pasos.
5. **Sonido, tanda 2:** voces de enemigos, agua en los ríos 2D, pasos de Lya, Garon y los enemigos, y la puerta de
   la Garganta. Las magias, como propuesta (están protegidas).
6. **Combate y narrativa:** revisar sus diseños e implementarlos por incrementos (magias, equipo, enemigos, ciudades,
   lugares y compañeros).

## Límites de lo comprobado

- **Escucha:** nada escuchado por una persona. Las pruebas miden la señal, no la calidad.
- **Redmi:** nada de esta noche probado en el teléfono. La v57 sigue sin probar por el usuario.
- **T-025:** ni mando ni teclado reales; el táctil, solo simulado.
- **Combates:** se ganan con ataques automáticos.
- **Rendimiento:** lo nuevo de esta noche (efectos, retratos y el botón) no está medido.

## Pendiente del usuario (mañana)

- Instalar la APK de la noche cuando esté en Descargas (el Redmi no estaba conectado), y la v57 si no la ha probado.
- **Escuchar las muestras** y elegir la victoria, los golpes, el cofre y el tesoro (el especialista duda de ellos).
- Revisar las decisiones de la noche ([D-073](DECISIONS.md#d-073)) y las propuestas de historia que dejen narrativa y
  combate.
- Sigue pendiente de decidir la nivelación al unirse ([D-062](DECISIONS.md#d-062)).

## Restricciones y autorizaciones vigentes

Las normas completas están en [CLAUDE.md](CLAUDE.md). Lo esencial:
- **Push:** memoria en `memoria-desarrollo`; APK de prueba en `Aethelgard-pruebas`; código revisado en ramas de
  trabajo de `Brunopina6/Aethelgard` ([D-070](DECISIONS.md#d-070)). Nunca en `main` ni en `desarollo`; nunca force
  push; nunca APK, bibliotecas completas, partidas, cachés, secretos ni la exportación del chat.
- **Redmi:** solo copiar APK de prueba a Descargas por USB y comprobarlas; instala el usuario.
- **Copia habitual:** solo la protección del guardado; el bloque B no se toca.
- **Licencias:** nada de Suno en APK ni en GitHub; Sonniss solo dentro del juego (no se revende ni sirve para entrenar
  IA).
- **Magias:** las 12 existentes no cambian ([D-048](DECISIONS.md#d-048)); las nuevas se añaden ([D-071](DECISIONS.md#d-071)).
- **Narrativa:** biblia v2 como canon; nada sobre Érebo y los corazones antes del acto III; un compañero nuevo en el
  grupo es una propuesta.
- **Pruebas:** el ejecutor se lanza desde PowerShell, no desde Bash, porque Bash expande el `*` de `*>` y le pasa
  parámetros falsos.
