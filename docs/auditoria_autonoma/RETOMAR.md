# RETOMAR — trabajo autónomo del 10/11/2026 (informe final)

**Dónde está todo:** copia `D:\Aethelgard_autonomo`, rama LOCAL `claude/rebelum-autonomo-2026-11-10` (no subida a
GitHub, sin PR: lo pidió la orden). Sale de `integracion-experimental` @ `2889213`. Commits: `3762b15`, `9889d95`,
`b28bc74`, `04eba69`, `21b6b6a`, `0f525c5` y este informe.

## QUÉ HE MEJORADO

1. **Guardado más seguro.** Si el disco falla a mitad de un guardado, la partida ya no puede quedarse sin copia buena:
   la principal solo se quita cuando su copia está comprobada, y si algo sale mal se restaura.
2. **Mapa.** Entre Portal del Vacío y Pastos Verdes, el botón «Entrar» ofrece siempre el lugar más cercano (antes
   podía ofrecer el otro).
3. **Prólogo.** Si cierras el juego a mitad del prólogo, vuelve a salir; solo queda visto al terminarlo o saltarlo.
4. **Pruebas de verdad.** Diez pruebas automáticas no podían fallar nunca (una ni siquiera llegaba a jugar el
   combate). Ahora comprueban de verdad. Tres que estaban desfasadas ya no cuentan como superadas.
5. **Combate más fácil de mantener.** Una prueba nueva vigila en cada fotograma de cinco combates que nadie tenga
   dos turnos, que las barras y la vida estén en su sitio y que el combate termine. Primera parte separada de
   `combate.gd` (las fórmulas de daño), con el combate exactamente igual que antes (misma «huella»).
6. **Preparado para crecer.** Las partidas guardan su versión; cada región tiene un nombre fijo para el futuro; una
   herramienta revisa que ninguna escena apunte a un archivo que no existe; y `ci_local.ps1` lo comprueba todo con un
   comando.

## QUÉ SIGUE IGUAL

Gráficos, sonido, historia, misiones, equilibrio, magias, invocaciones, controles y personajes. Las partidas antiguas
cargan igual. El combate da exactamente los mismos resultados.

## QUÉ HE PROBADO

Todo con datos aislados (tu partida real no se ha tocado en ninguna prueba). Detalle en PRUEBAS.md. Batería completa:
ver el resultado final más abajo.

## QUÉ NO HE PODIDO PROBAR

Nada en el móvil (no estaba disponible): la lista está en PENDIENTES_MOVIL.md.

## QUÉ QUEDA PENDIENTE

- Precarga por zonas (arranque más rápido y menos memoria): propuesta en RENDIMIENTO.md; hay que medirla en el Redmi.
- Separar más partes del combate, datos en recursos, eventos, misiones y talleres: plan en ARQUITECTURA.md.
- Reescribir tres pruebas desfasadas (toques, diálogos y menú de combate).
- Nada de esto está integrado en `integracion-experimental`: espera tu aprobación.

## CÓMO VOLVER ATRÁS

Esta rama no ha cambiado ninguna otra: `integracion-experimental` sigue en `2889213`. Basta con no usar esta rama.

## QUÉ TIENES QUE HACER AL VOLVER

1. Leer este archivo y CAMBIOS.md.
2. Si te parece bien, pedirme que lo una a `integracion-experimental` y lo suba.
3. Con la siguiente APK, hacer las comprobaciones de PENDIENTES_MOVIL.md en el Redmi.

## RESULTADO DE LA VERIFICACIÓN FINAL

`ci_local.ps1` (10/11, 12:11): importación aislada y batería completa: **79 superadas, 0 fallidas**, 41 manuales,
0 no seguras; partida real y carpeta real de datos sin cambios. Resumen:
`D:\REBELUM_diagnostico\pruebas\2026-11-10_121154\resumen.md`. La huella del combate, igual que la referencia.
