# VALIDACIÓN EN EL REDMI — Fase 2 (10/11/2026, tarde)

**Montaje de la prueba:**
- REDMI A7 Pro (Mali-G57, Android 16), por USB y ADB, conectado y autorizado por el usuario («pruebalo ya está
  conectado»).
- **Solo se actualizó la app de pruebas aparte**, «REBELUM Auditoría» (`com.aethelgard.auditoria`): v387 → v418
  (`ddcc1d3`). La instaló el usuario desde Descargas, porque MIUI canceló los avisos por USB.
- **No se tocaron** la estable (v1), la «Prueba 3D» (v24) ni la «Exp» (v365).
- La partida de la app de pruebas se copió al PC antes de actualizar: `D:\REBELUM_diagnostico\redmi\2026-11-10_fase2\`.

## Medidas (v418, comprobado en el teléfono)

| Medida | v418 (esta fase) | Antes (v386/v387, esta mañana, mismo Redmi) |
|---|---|---|
| Arranque, de abrir la app a «TOCA PARA EMPEZAR» (reloj del PC, 3 veces) | **19,0 / 20,2 / 19,0 s** | 22-25 s |
| Carga según el propio juego («Carga terminada en…», 6 veces) | 13,5-14,0 s, 694 archivos | 12,7 s, 679 archivos (09/11, con menos contenido integrado) |
| Entrada en Pastos Verdes 3D desde la carga | modelos listos ~2,5 s después del toque | ~24 s la primera vez (compilaba sombreadores) |
| Pastos Verdes 3D, calidad Automática (eligió **bajo**) | **30,0 / 30,1 / 30,0 FPS**, p95 33,7-33,9 ms, 0-4 fotogramas de más de 50 ms de 125 | bajo: 30,1, p95 34,0 |
| Memoria gráfica en Pastos Verdes 3D | 381 MB | 390-398 MB (v386) |
| Memoria total (PSS) en Pastos Verdes 3D | 741 MB | no medida igual |
| Memoria gráfica en la pantalla de carga | 386-395 MB | no medida |
| Tamaño de la APK | 293 074 534 bytes | 292 917 900 bytes (v387) |
| Errores de script y cierres | ninguno (búfer de cierres vacío) | ninguno |

**Cuidado al comparar:**
- La v418 lleva además lo que se integró hoy de los especialistas: 15 archivos más en la precarga, los modelos
  ligeros de Oakhaven y la calidad adaptable.
- La comparación exacta (la misma integración sin los cambios de esta fase, v413 `0d06bd1`, ya compilada) no se pudo
  instalar: volver a una versión anterior solo se puede por USB, con el aviso de MIUI aceptado en el teléfono.
- **Por eso los segundos de arranque ganados no se atribuyen solo a esta fase.**

## Calidad Automática (comprobado)

- **Detección:** «bajo a 30 FPS», con la GPU «Mali-G57», 8 núcleos y pantalla de 1600x720.
- **Calibración jugando en Pastos Verdes 3D:** «bajo a 30 FPS (p95 34,2 ms, mediana 33,3 ms, 180 fotogramas)».
- Guardado en `ajustes.cfg`: `auto=true`, `perfil_auto="bajo"`, `calibrado=true`.
- **Sin oscilaciones** en los minutos de prueba.

## Fallo encontrado y corregido

- **Bajar el volumen pasaba los textos del juego a los de teclado.**
  - Registro de la v418: «Entrada: modo puntero → teclado por VolumeDown».
  - Corregido en `c88e4df`: los botones del teléfono (volumen, atrás, menú, encendido, multimedia) y las teclas sin
    código (como el sensor de huellas) ya no cambian el modo.
  - Prueba nueva: `prueba_teclas_sistema`.
  - APK v420 compilada y copiada a Descargas: `Aethelgard_Auditoria_2026-11-10_v420.apk`, SHA-256 `0f72c3ad…`.
  - **Comprobación en el teléfono:** ver abajo.

## Pendiente

- **Combate en el teléfono:** no salió ningún encuentro en unos 50 s de paseo por Pastos Verdes 3D, y no se forzó.
  - Esta fase solo cambió cómo se cuentan las recompensas, y la huella de los nueve combates del PC es idéntica.
  - Esta mañana, la v387 iba a 59,9 FPS en combate.
- **Garganta 3D:** no se intentó; llegar a ella con toques no es fiable.
- **Comparación exacta del arranque con la v413:** necesita aceptar en el teléfono el aviso de instalar por USB.
