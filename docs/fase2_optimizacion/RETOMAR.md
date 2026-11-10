# RETOMAR — Fase 2: optimización y preparación de sistemas (10/11/2026)

Escrito para leerlo sin saber programar.

## Dónde está todo

- **Integración de los especialistas:** ya hecha y **subida a GitHub**, en `integracion-experimental` @ `0d06bd1`.
  Batería: 82 superadas, 0 fallidas.
- **Esta fase:** en la rama LOCAL `claude/rebelum-optimizacion-fase2`, copia `D:\Aethelgard_fase2`. Último commit con
  código: `8381d75`; los informes van en el commit siguiente. **No está subida ni fusionada:** espera tu autorización.
- **Respaldos de `integracion-experimental`:**
  - antes de la auditoría: `respaldo-integracion-antes-autonomo-20261110`;
  - antes de los especialistas: `respaldo-integracion-antes-especialistas-20261110`.

## Qué he terminado

1. **El juego arranca más ligero.** Ya no carga al empezar cosas que nunca usa:
   - texturas sobrantes de los modelos;
   - la versión de Oakhaven 3D de otro perfil gráfico;
   - carpetas de pruebas.
   - **En el PC:** 0,9 s menos hasta «TOCA PARA EMPEZAR» y unos 280 MB menos de memoria.
   - **En el móvil:** sin medir todavía.
2. **El combate, más ordenado por dentro.** Las cuentas de experiencia y monedas tienen su propio archivo. Los combates
   dan exactamente lo mismo que antes (comprobado con nueve combates grabados).
3. **Contenido nuevo sin tocar los scripts grandes.** Los materiales viven ahora en archivos de datos que se comprueban
   solos (ids repetidos, referencias rotas…). Ya está migrado el primero, la Corteza espinosa, sin cambiar nada del
   juego.
4. **La base de los talleres de Lya, Kael y Garon.** Investigaciones con requisitos, recetas y fabricar, y el avance
   se guarda en la partida sin romper las antiguas. Sin pantalla todavía: lo jugable es la fase 3, cuando apruebes el
   diseño.
5. **Pruebas:** cuatro nuevas. La batería completa da 86 superadas y 0 fallidas.

## Qué estoy haciendo

Nada a medias: la fase está cerrada en un punto seguro.

## Qué queda pendiente

- **Con el Redmi:**
  - compilar la APK de pruebas aparte (`com.aethelgard.auditoria`) desde esta rama;
  - medir el arranque, la memoria, Pastos Verdes 3D, la Garganta 3D y el combate;
  - comprobar la calidad Automática.
- **Tu decisión:** el diseño de los talleres (`FASE3_TALLERES.md`).
- **Más modularización del combate:** la IA de los enemigos. Conviene antes integrar el trabajo sin confirmar del
  especialista de combate.
- **Optimizaciones del 3D:** se miden primero en el Redmi.

## Cómo continuar exactamente

1. Abrir `D:\Aethelgard_fase2`. La rama ya es la buena: no hay que cambiarla.
2. Comprobar que todo pasa. Desde PowerShell, en esa carpeta:
   `powershell -ExecutionPolicy Bypass -File .\ci_local.ps1`. Debe terminar con «CI LOCAL: todo superado».
3. Con el Redmi conectado, compilar la APK de pruebas aparte:
   `.\compilar_apk_experimental.ps1 -Preset "Android auditoría"`.
   - Instalarla sin tocar las otras apps.
   - Medir lo pendiente comparando con la v387 (`docs/auditoria_autonoma/VALIDACION_REDMI.md`).
4. Si todo va bien y lo autorizas: fusionar la rama con `integracion-experimental` y subirla.

## Informes

- `INFORME_RENDIMIENTO.md` (A)
- `INFORME_CODIGO.md` (B)
- `INFORME_PRUEBAS.md` (C)
- `FASE3_TALLERES.md` (D)
- este archivo (E)
