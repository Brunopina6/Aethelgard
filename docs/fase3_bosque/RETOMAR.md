# RETOMAR — Fase 3: «El bosque que no recuerda» (10/11/2026, ~16:20)

Escrito para leerlo sin saber programar.

## Dónde está todo

- **La fase 2 está fusionada y subida:** `integracion-experimental` @ `b4e26e2`, en GitHub, batería 87/0.
- **Esta fase**, en la rama LOCAL `claude/rebelum-bosque-fase3` (copia `D:\Aethelgard_fase3`):
  - último commit seguro: el de este documento, justo después de `b9d9300`;
  - **sin subir ni fusionar**, como pediste.
- **Trabajo de especialistas, ya integrado en esta rama:**
  - narrativa: rama `claude/f3-dialogos`, copia `D:\Aethelgard_f3_dialogos`;
  - animaciones: rama `claude/f3-guardian-modelo`, copia `D:\Aethelgard_f3_modelo`.
- **APK de prueba,** compilada solo en el PC (no publicada ni instalada):
  - `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-b9d9300.apk`;
  - v449, «REBELUM Auditoría» (paquete aparte), 279,8 MB, SHA-256 `c8cb43a5…`.

## Qué he terminado (jugable y probado en el PC)

1. **La aventura en Pastos Verdes:**
   - tras la misión de Tilo, el árbol junto a su puesto amanece marcado y Tilo recuerda una tormenta que no hubo;
   - tres pistas repartidas por la región (los lirios del río, los surcos del este y la inscripción de las ruinas);
   - una senda escondida que Garon abre;
   - nueve plantas y musgos que recoger, un manantial, un ciervo de niebla y un cofre.
2. **La alquimia de Lya:**
   - una pantalla con recetas, investigaciones y materiales;
   - se fabrican de verdad la Poción, la Esencia de enfoque y el Elixir de savia purificada, y se usan en el combate;
   - se abre desde Pastos Verdes y desde el menú del juego.
3. **El Guardián del Bosque Olvidado:**
   - jefe con modelo 3D propio y dos fases;
   - avisa sus golpes fuertes y en la segunda fase se cubre de raíces y es débil al fuego;
   - lo que Lya investiga le da ventaja.
4. **Dos desenlaces:**
   - **purificarlo** con el Elixir: el bosque florece y recibes el Brote del Guardián;
   - **derrotarlo**: queda un tocón y recibes el Corazón de roble y la Corteza.
   - Todo se guarda y no se puede cobrar dos veces.
5. **Oakhaven reacciona:** Doña Encina habla de lo que pasó y vende hierbas en la tienda.
6. **Pruebas:** la batería completa da 92 superadas y 0 fallidas, con 6 pruebas nuevas que juegan la aventura y el
   combate solas.

## Qué estoy haciendo

Nada a medias: la fase está cerrada en un punto seguro.

## Qué queda pendiente

- **Probarlo en el Redmi:** `PENDIENTES_REDMI.md`, con la lista exacta.
- **Revisar dos detalles de canon** (en `INFORME_DESARROLLO.md` y en el informe de narrativa):
  - los nombres «El corazón del bosque» y «Corazón de roble»;
  - que el Guardián hable.
- **Para más adelante:** la forja de Kael y las armaduras de Garon (la base ya sirve), y sonidos y música propios del
  Guardián.

## Cómo continuar exactamente

1. Abrir `D:\Aethelgard_fase3`. La rama ya es la buena.
2. Comprobar que todo pasa. Desde PowerShell, en esa carpeta:
   `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`. Debe terminar con «CI LOCAL: todo superado».
3. **Con el Redmi:**
   - copiar la APK v449 a Descargas e instalarla tocándola (MIUI cancela las instalaciones por USB si nadie pulsa);
   - seguir `PENDIENTES_REDMI.md`.
4. Si todo va bien y lo autorizas: fusionar la rama con `integracion-experimental` y subirla.

## Informes de esta fase

- `AVENTURA_JUGABLE.md`: el diseño y los identificadores.
- `INFORME_DESARROLLO.md`: qué está hecho, decisiones y correcciones.
- `PRUEBAS.md`
- `PENDIENTES_REDMI.md`
- `docs/memory/agents/narrativa_fase3_bosque.md` y `docs/memory/agents/animaciones_fase3_guardian.md`: los informes
  de los especialistas.
