# Especialista de magia — V12, fase 3C: magia Agua mejorada

## 14/11/2026, 02:40 — rama claude/v12-magia-agua (desde claude/rebelum-v12 @ aa7f55f)

**1. Hecho.** Agua, Torrente y Maremoto con anticipación, orbe de agua, impacto (salpicadura, membrana que revienta,
gotas con gravedad, espuma, charco) y ola con cuerpo en `aethelgard/vfx/agua_v12.gd`, EXPERIMENTAL y APAGADO por
defecto (Ajustes → «Magia Agua v12», solo Auditoría o editor). Enganche de 7 líneas en `combate.gd` y opción en
`menus.gd`. Mismo daño, mismos golpes y misma tirada del azar (comprobado). Detalle: `docs/v12/MAGIA_AGUA_V12.md`.

**2. Pruebas (aisladas, PC).** `prueba_magia_agua_v12` SUPERADA; batería de combate y magia 13 · 0
(`D:\REBELUM_diagnostico\v12\magia_agua\pruebas\2026-11-14_023027\resumen.md`); capturas `fotos_magia_agua_v12`
(`D:\REBELUM_diagnostico\v12\magia_agua\comparativas\`).

**3. Límites.** Sin verificar en el Redmi. Medidas de PC con otros Godot en marcha (ms orientativos). Sin capturas con
`combate_anim_v12` encendido.

**4. Peticiones.** Ninguna a otros archivos. Los `.uid` del orbe de Érebo (`erebo_orbe_v12.gd.uid` y sus pruebas) faltan
en `claude/rebelum-v12`; aquí se generaron al importar y NO se han confirmado (no son de esta tarea).
