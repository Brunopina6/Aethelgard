---
name: aet-calidad-adaptable
description: Perfiles de calidad gráfica baja/media/alta para Aethelgard (desde Android modesto hasta iPhone potente y PC) sin perder la dirección artística.
---

# aet-calidad-adaptable — Aethelgard

## Contexto obligatorio
Aethelgard es un JRPG de fantasía en Godot. Android primero, iPhone y PC después. El móvil de pruebas (Redmi de gama baja) NO marca el techo visual: el perfil alto debe verse espectacular. Cada tarea empieza en **solo lectura** hasta aprobación explícita del usuario. No confundir una propuesta o simulación con prueba real.

## Procedimiento
1. Un único archivo de perfiles (p. ej. `calidad.gd`) con los valores de cada nivel; las escenas los leen, no copian números.
2. Parámetros por perfil: densidad de hierba y flores, distancia de dibujo (`visibility_range_end`), sombras y su distancia, número de luces puntuales, relieve triplanar del terreno, refracción del agua, partículas, resolución 3D (`scaling_3d_scale`), MSAA y tope de FPS (30 o 60).
3. Elección automática al primer arranque (tipo de dispositivo y una medición corta) y cambio manual en Opciones; se guarda aparte de la partida.
4. El estilo es el mismo en todos los perfiles: cambian cantidades y distancias, no la paleta, la luz principal ni los modelos de los protagonistas.
5. Medir cada perfil con el perfilador de `aet-rendimiento-android`.

## Criterios de aceptación
- Capturas de bajo, medio y alto reconocibles como el mismo juego.
- Bajo: objetivo 30 FPS estables en el Redmi (medido). Alto: aspirar a 60 FPS en dispositivos potentes (medido en ellos).
- Cambiar de perfil en caliente no da errores ni toca la partida.

## Pruebas
- Recorrido automático en los tres perfiles (sin errores) y CSV de rendimiento de cada uno en el dispositivo.

## Seguridad
- Nunca rebajar el perfil alto para que quepa el móvil modesto.
- No cambiar el renderizador global del juego sin prueba aislada y aprobación.

## Formato de respuesta
**Hechos (rutas reales) → Carencias → Opciones → Riesgos → Primera tarea con pruebas → Pregunta de aprobación**. Explicar en español y no afirmar acciones no realizadas.
