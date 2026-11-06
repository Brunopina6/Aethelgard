---
name: aet-direccion-arte
description: Define y verifica una dirección artística JRPG 2.5D coherente y realizable en Android.
---

# aet-direccion-arte — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía Godot, actualmente con sistemas existentes que no pueden romperse, Android primero y PC futuro. En el proyecto se trabaja preferentemente en `desarrollo`; `main` es estable. Conservar Érebo, Garon, combate, guardados y assets originales. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Confirmar la versión del motor, estado Git, archivos y subsistemas implicados mediante evidencia de solo lectura. Si falta acceso a datos o imagen, declararlo sin inventar.
2. Estudiar referencia nueva generada y los diseños originales chibi. Registrar paleta, proporciones, luz superior izquierda cuando encaje, sombras azuladas, materiales, siluetas, escala de personaje, ambiente y densidad visual. Comparar capturas de situación actual sin inventar detalles de imágenes ausentes. Priorizar identidad Aethelgard y legibilidad en móvil.
3. Comparar alternativas, compatibilidad Mobile/Compatibility/PC, riesgos de migración, coste en batería/FPS/memoria, licencias y esfuerzo.
4. Proponer **una primera mejora mínima** en área aislada, con archivos exactos que cambiarían, dependencias y criterios de éxito en Android. No ejecutarla hasta autorización.
5. Tras una autorización futura concreta, exigir checkpoint verificable, aplicar cambios pequeños, pruebas de regresión, evidencias antes/después y rollback.

## Ampliación (Fase 2): estilo luminoso de Aethelgard
Objetivo artístico: la sensación luminosa, limpia y amable de los mundos de fantasía «de cuento» (referencia de
sensación: Infinity Nikki; emoción: Final Fantasy IX; puesta en escena: Clair Obscur), con identidad propia.
Nunca copiar modelos, texturas, personajes, logotipos ni composiciones concretas de esos juegos.
La guía viva está en `docs/guia_visual.md` (paleta, luz, formas, presupuestos). Reglas que salen de lo medido:
1. Luz: sol cálido arriba-izquierda, relleno azulado, exposición igualada entre perfiles (EXPO_CON_SOMBRAS en
   `prototipos/sendero_puente.gd`: con sombras la imagen se aclara en Compatibility). Comprobar siempre el brillo
   medio de la misma vista en bajo/medio/alto (≤ 5 % de diferencia).
2. Color: verdes amarillentos y saturados, piedra cálida, agua turquesa; ajuste de saturación 1,3 y contraste 1,1.
3. Formas: siluetas redondeadas y legibles desde 20 m de cámara (Kael ~7 % de la altura de pantalla).
4. Brillos de ambiente baratos: emisión + halos pintados (como los faroles del perfil medio), no luces reales.
5. Cada cambio visual: captura antes/después en el mismo sitio y con el mismo perfil (scripts en `pruebas/`).

### Criterios de aceptación
- Capturas de los tres perfiles reconocibles como el mismo juego y fieles a la guía.
- Ningún cambio artístico baja el perfil medio del Redmi A7 Pro de 30 FPS con tope (banco «TOPE»).

### Reversión
- Cada cambio en un commit propio en `desarollo`; los parámetros de luz/color viven en constantes con nombre.

## Entrega requerida
Minibiblia visual con guía de personajes, vegetación, edificios, efectos y tres comparaciones de costes.

## Restricciones especiales
No copiar assets protegidos ni sustituir modelos originales sin aprobación.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
