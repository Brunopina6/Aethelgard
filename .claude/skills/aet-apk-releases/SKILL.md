---
name: aet-apk-releases
description: Planifica export APK/AAB Android y publicaciones GitHub Releases con aprobaciones.
---

# aet-apk-releases — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Inspeccionar Godot/export presets sin mostrar credenciales, SDK/JDK/plantillas y keystore existente; comprobar package name y versionCode para actualizaciones. Separar APK debug/prueba de release, checksum, tamaño y pruebas en dispositivo. Preparar GitHub Actions opcional con secretos seguros y permisos mínimos, tag único y Release adjuntando APK.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Ampliación: iOS (sin abandonar Android)
Requisitos según la documentación oficial de Godot («Exporting for iOS»):
1. Mac con macOS y Xcode; desde Windows no se compila para iOS (alternativas: Mac en la nube o equipos macOS de GitHub Actions, con la firma guardada como secreto).
2. Plantillas de exportación de la misma versión de Godot del proyecto.
3. Team ID de Apple (10 caracteres) e identificador de paquete único (p. ej. `com.aethelgard.juego`); sin ellos el exportador da error.
4. Cuenta de Apple: con un Apple ID gratuito se puede probar en el propio iPhone con limitaciones; TestFlight y App Store requieren el Apple Developer Program (de pago anual).
5. Godot genera un proyecto de Xcode; se compila, firma e instala desde Xcode.
6. Renderizador: el simulador de iOS solo admite Compatibility; comprobar en la documentación de la versión exacta qué renderizador usa el dispositivo antes de diseñar el perfil alto.

### Criterios de aceptación (iOS)
- Build abierto en Xcode, instalado en un iPhone real y con el CSV del perfilador del recorrido de prueba.

### Seguridad (iOS)
- Nunca guardar certificados, perfiles de aprovisionamiento ni claves de Apple en Git.
- No publicar en TestFlight ni App Store sin permiso explícito.
- No afirmar rendimiento en iPhone sin medirlo en el dispositivo.

## Entrega requerida
Checklist de build reproducible y propuesta de release v0.1.x/v0.2.0 sin ejecutar.

## Restricciones especiales
No compilar, firmar, crear tag, subir APK, publicar Release o modificar claves hasta autorización explícita.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
