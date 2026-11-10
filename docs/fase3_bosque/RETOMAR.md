# RETOMAR — Fase 3: «El bosque que no recuerda» (punto de control provisional, 10/11/2026 ~15:35)

- **Rama local:** `claude/rebelum-bosque-fase3`, copia `D:\Aethelgard_fase3`, que sale de `integracion-experimental`
  @ `b4e26e2` (ya en GitHub, con la fase 2 fusionada). **Nada de esta fase está subido ni fusionado.**
- **Diseño y contrato:** `AVENTURA_JUGABLE.md`.

## Hecho y probado (sin ventana, datos aislados)

- **Combate:** Guardián del Bosque Olvidado (dos fases, avisos, coraza de raíces, débil al fuego), Esencia de
  enfoque, Elixir (purifica en la fase 2) y premios por desenlace sin duplicar.
  - `prueba_guardian_bosque` superada. Huella del combate idéntica.
- **Datos de la alquimia:** 3 materiales + Corazón de roble, 3 recetas y 2 investigaciones de Lya.
  - `prueba_datos` superada.
- **Diálogos** (narrativa, rama `claude/f3-dialogos`, fusionada): 15 diálogos, avisos (`dialogos/notas/bosque.gd`)
  y `prueba_dialogos_bosque`.
- **Oakhaven:** Encina según el desenlace y sus hierbas en la tienda.
  - `prueba_ciudad_datos` superada.

## En curso / pendiente

- **Aventura en Pastos Verdes 3D**, el módulo `zonas3d/bosque_pastos.gd`:
  - pistas, materiales, senda, manantial, ciervo, cofre, el Guardián dormido y el claro tras el desenlace;
  - enganche en `pastos_verdes_3d.gd`.
- Pantalla de alquimia (`alquimia_menu.gd`).
- **Modelo 3D del Guardián:** lo hace el especialista de animaciones en `D:\Aethelgard_f3_modelo` (rama
  `claude/f3-guardian-modelo`). Mientras, el respaldo 2D teñido de verde.
- Batería completa, APK de auditoría y documentos finales.
