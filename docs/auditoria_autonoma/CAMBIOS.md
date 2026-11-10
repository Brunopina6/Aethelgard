# CAMBIOS — por incidencia

Rama local `claude/rebelum-autonomo-2026-11-10`. Cada cambio: problema, solución, archivos y pruebas ejecutadas.

## 1. Guardado: riesgo de perder la partida principal (`3762b15`)

- **Archivos:** `aethelgard/progreso.gd` (`escribir()` y `_renombrar()` nuevo; antes líneas 297-323),
  `aethelgard/pruebas/prueba_guardado_fallos.gd` (nueva), `pruebas/lista_pruebas.txt`.
- **Problema:** si fallaba el renombrado del «.tmp», se borraba la principal; si el reintento también fallaba, solo
  quedaban «.bak» y «.tmp». Un guardado posterior que fallara al escribir truncaba ese «.tmp» (la copia más reciente).
  La copia «.bak» nunca se comprobaba.
- **Solución:** la principal solo se quita si su «.bak» está escrita y se lee; si el reintento falla, se restaura desde
  esa copia; un «.tmp» bueno sin principal se guarda en «.bak» antes de reescribirlo; una principal ilegible se aparta
  en «.danada». Interruptores solo para pruebas (`fallos_renombrar`, `falla_copia`, `falla_escritura`), a cero en el
  juego. El formato de la partida no cambia (compatible con todas las partidas).
- **Pruebas:** `prueba_guardado_fallos` (7 casos), `prueba_guardado`, `prueba_guardado_protegido`,
  `prueba_restaurar_escenas`: 4 de 4 superadas.

## 2. Mapa: no se elegía el lugar más cercano (`9889d95`)

- **Archivos:** `aethelgard/mapa.gd` (`lugar_mas_cercano()` nuevo y `_comprobar_cerca()`; antes líneas 525-534),
  `aethelgard/pruebas/prueba_mapa_cercano.gd` (nueva).
- **Problema:** se quedaba con el último lugar de la lista dentro del radio. Portal del Vacío (650, 405) y Pastos Verdes
  (660, 478) están a ~74 px con radios de 70: entre los dos podía ofrecer el que no tocaba.
- **Solución:** función pura que devuelve el más cercano dentro del radio, en cualquier orden.
- **Pruebas:** `prueba_mapa_cercano` (posiciones exactas; comprueba además que el algoritmo anterior fallaría).

## 3. Prólogo: una interrupción lo daba por visto (`9889d95`)

- **Archivos:** `aethelgard/mapa.gd` (`_ready`, `_empezar_prologo`, `_prologo_terminado()` nuevo),
  `aethelgard/pruebas/prueba_prologo.gd`.
- **Problema:** `prologo_visto` se ponía antes de mostrarlo y el mapa guardaba enseguida: cerrar la app a mitad lo
  perdía para siempre.
- **Solución:** queda visto (y se guarda) al terminar o saltarlo.
- **Pruebas:** `prueba_prologo` (ahora exige que no esté visto al empezar, que sí al acabar, y un caso nuevo de
  interrupción y reanudación), `prueba_boton_prologo`, `prueba_partida`, `prueba_ranura_prueba`,
  `prueba_guardado_protegido`, `prueba_escenas`, `prueba_mapamundi`: superadas.

## 4. Pruebas que no podían fallar (`b28bc74`)

- **Archivos:** `prueba_ia.gd`, `prueba_equilibrio.gd`, `prueba_cofre.gd`, `prueba_dpad.gd`, `prueba_choque.gd`,
  `prueba_andar.gd`, `prueba_tema.gd`, `prueba_garon.gd`, `lista_pruebas.txt`, `ejecutar_pruebas.ps1`.
- **Problema:** diez pruebas automáticas solo imprimían. `prueba_ia` ni siquiera avanzaba del «¡Combate!» y salía
  superada.
- **Solución:** aserciones reales y código de salida; `prueba_ia` con «auto semilla=7». Tres diagnósticos desfasados
  (`prueba_toque`, `prueba_dialogo`, `prueba_menu_nuevo`) pasan a «manual» con su motivo, en vez de contar como
  superados sin comprobar nada. La ruta de Godot también puede venir de `REBELUM_GODOT`.
- **Pruebas:** las ocho convertidas, superadas. Valores: golpe Kael/Lya 5,01 y magia Lya/Kael 3,00 (aprobado: 5 y 3).
