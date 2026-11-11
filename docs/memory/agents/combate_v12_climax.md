# Combate, V12: el clímax musical de los grandes jefes

## 11/11/2026, 18:30 · rama `claude/v12-climax` (LOCAL, nace de `claude/rebelum-v12` @ `f6e177f`)

Encargo del usuario (11/11): cuando un gran jefe autorizado baja al 20 % de su vida, entra su canción de clímax
(«REBELUM — Volverá a amanecer», Suno Pro del usuario). Debe ser configurable por jefe y reversible, y en la
demostración solo se activa con Bramavidrio. Copia `D:\Aethelgard_v12_climax`.

**Estado:** hecho y probado en el PC (aislado, sin ventana; capturas con ventana). **Nadie lo ha escuchado y no se ha
probado en el Redmi.**

### Commits

| Commit | Qué |
|---|---|
| `d00ef60` | `aethelgard/combate_climax.gd` (nuevo) y los ganchos «V12, clímax» de `aethelgard/combate.gd` |
| `74cadc0` | `aethelgard/pruebas/prueba_climax_jefe.gd` y su línea en `aethelgard/pruebas/lista_pruebas.txt` |
| este | la sección «El sistema» de `docs/v12/MUSICA_JEFES.md` y este informe |

Sin confirmar a propósito: `audio/musica/jefes/volvera_a_amanecer_climax.ogg.import`. Lo generó la importación aislada,
la rama no lo llevaba y la canción no se ha editado. Que decida el coordinador si se confirma.

## 1. Cómo funciona

Está descrito para quien lo use en `docs/v12/MUSICA_JEFES.md`, sección «El sistema». En resumen:
- **Detección:** en `_quitar_pv`, el mismo sitio por donde pasa todo daño a un enemigo (golpes, magias, técnicas, Érebo,
  quemaduras, Réplica). Se mira la vida de antes y la de después: tiene que cruzar el 20 % y seguir en pie.
- **Arranque:** se hace en `_process`, cuando el combate vuelve a esperar o a pedir órdenes («esperando», «menu» u
  «objetivo»). No cambia el estado del combate, así que el ATB, los turnos y el menú siguen igual.
- **Música:**
  - la canción sustituye a `musica` (el reproductor del combate), por eso la cierran sin código nuevo la victoria y la
    derrota (`_comprobar_fin` → `_bajar_musica`), la huida (`_escapar`) y el último aliento (`_decidir`);
  - si el combate acaba durante el fundido, la canción no llega a sonar;
  - la fase 2 (`_musica_fase2`) ya no cambia la música si el clímax está activo.
- **Lo que se ve:**
  - «¡Momento decisivo!» (50 px, dorado, ~2,4 s);
  - un velo dorado de 0,16 de opacidad durante 0,8 s;
  - un destello y 40 partículas sobre el jefe (16 en el móvil) cuando la canción llega a su estallido. Se mira la
    posición real de la canción: con `--fixed-fps` el tiempo de juego no va al ritmo del audio.
- **Sonido:** el golpe de energía es `fase2` de `sonido.gd` (existente y licenciado), pedido una vez. La canción va por
  el bus Musica a −7 dB (la música de combate va a −6 dB). En combate, ese bus ya se aparta cuando suenan efectos
  (compresor que escucha a Efectos).

## 2. Pruebas (aisladas, `--fixed-fps 30`)

**`prueba_climax_jefe`** (nueva), SUPERADA. Comprueba:
- del 30 % al 21 %: no se activa;
- del 21 % al 20 %: se activa, pero no a mitad de una acción, solo al acabar;
- del 50 % al 10 %: se activa;
- un golpe que lo mata: no se activa;
- más golpes después: ni se reinicia ni vuelve atrás la canción;
- se cura por encima y vuelve a bajar: nada nuevo;
- victoria y derrota: el sonido de siempre, una vez, y la canción por debajo de −30 dB;
- huida en un combate normal: se cierra; huida durante el fundido: no llega a sonar;
- dos jefes autorizados: un solo clímax y una sola canción;
- el Coloso, un élite o un enemigo normal: sin clímax, y la música del Coloso intacta;
- cambio de escena: ningún reproductor;
- `hp_max` 0, la vida sin poner o empezar por debajo: nunca se activa;
- la fase 2 no pisa la canción;
- la canción: bus Musica, bucle, `loop_offset` 13,62, empieza en 0 y avanza (posición medida en milisegundos reales);
- la música de antes se quita;
- el destello cae cuando la canción pasa de 1,2 s.

**Baterías** (`ejecutar_pruebas.ps1`, partida y datos reales sin cambios):
- `D:\REBELUM_diagnostico\pruebas\2026-11-11_180949\resumen.md`: **19 superadas, 0 fallidas, 1 manual**
  (`prueba_musica_senal`, que necesita a una persona). Incluye `prueba_climax_jefe`, `prueba_bramavidrio_combate`,
  `prueba_huir`, `prueba_grupos_combate`, `prueba_combate_seguro`, `prueba_coloso`, `prueba_coloso_garganta`,
  `prueba_efectos`, `prueba_audio`, `prueba_musica`, `prueba_musica_titulo`, `prueba_musica_pastos`,
  `prueba_guardado`, `prueba_guardado_fallos`, `prueba_guardado_protegido`, `prueba_combate_huella`, `prueba_garon`,
  `prueba_mar_cristal` y `prueba_audio_desierto`.
- Después de ajustar el destello: `D:\REBELUM_diagnostico\pruebas\2026-11-11_181855\resumen.md`, **6 superadas**
  (clímax, Bramavidrio, combate seguro, huella, huir y Coloso).

`prueba_bramavidrio_combate` pasa también con el clímax activo, en combates enteros con victoria, derrota y Aliento
cortado. No he pasado la batería entera.

## 3. Capturas (con ventana, datos aislados): `D:\REBELUM_diagnostico\combate\2026-11-11_climax\`

| Captura | Qué se ve |
|---|---|
| `01_antes_24` | Bramavidrio al 24 %, con la música de jefe sonando |
| `02_cruza_20_momento_decisivo` | justo tras el golpe de Garon que lo deja al 17 %: aparece el aviso y la canción aún no suena (fundido) |
| `03_aviso` | «¡Momento decisivo!» entero, con el velo |
| `04_estallido_cancion` | la canción a 1,5 s y el destello dorado sobre el cuello |
| `05_despues` | la canción sigue (4,3 s) y el combate, igual |

Las tomó un guion de herramienta de mi carpeta temporal, que no va al proyecto. En esa pasada con ventana el juego iba
más rápido que el reloj (`--fixed-fps` con 144 FPS de pantalla). Por eso la canción entra antes de 0,9 s reales; en el
juego normal coinciden.

## 4. Lo comprobado y lo que NO

**Comprobado:** lo de §2, en el PC.

**NO comprobado:**
- **Cómo suena:** el volumen relativo de la canción frente a la música de jefe (−7 dB frente a −6 dB, a ojo por el
  análisis de `MUSICA_JEFES.md`), que las voces no tapen los avisos, el compresor y la entrada a los 0,9 s. Hay que
  escucharlo.
- **El Redmi.**
- Un combate de un jugador real llegando al 20 %: en las pruebas, la vida se pone y se quita con el mismo `_quitar_pv`
  de los golpes. Los combates automáticos de `prueba_bramavidrio_combate` sí pasan por él de verdad, pero no miran la
  música.
- Que el golpe `fase2` mejore la entrada: es una elección mía. Si estorba, se quita con `GOLPE = ""`.

## 5. Siguiente paso y peticiones

1. **Usuario y coordinador:** escuchar el momento en un combate real contra Bramavidrio (Mar de Cristal) y decidir:
   - el volumen (`PISTAS[...]["db"]`);
   - si se queda el golpe `fase2`;
   - qué otros jefes lo llevan (`JEFES`, «activo»).
2. **Coordinador:** integrar copiando `combate.gd`, `combate_climax.gd`, la prueba, `lista_pruebas.txt` y la sección de
   `MUSICA_JEFES.md`; decidir si se confirma el `.import` de la canción.
3. **Sonido** (si hace falta): un golpe orquestal propio para la entrada en `sonido.gd`, y cambiar `GOLPE`.
