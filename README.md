# Pelotitas

Juego online 2D top-down de batallas entre pelotitas elementales (Fuego, Agua, Tierra, Aire).

## Estado Actual

**Scaffolding inicial** - Estructura del proyecto, stubs de sistemas, y documentación de diseño. No es un juego jugable todavía.

## Requisitos

- **Godot Engine 4.3+** (o cualquier versión 4.x compatible)
- Sistema operativo: Windows, Linux, o macOS

## Cómo Abrir el Proyecto

1. Clona este repositorio:
   ```bash
   git clone https://github.com/MaximoAPS/Pelotitas.git
   cd Pelotitas
   ```

2. Abre **Godot 4** y selecciona "Importar" en el Project Manager

3. Navega a la carpeta del proyecto y selecciona `project.godot`

4. Haz clic en "Importar y Editar"

5. La escena principal se encuentra en `scenes/boot/boot.tscn`

## Arquitectura

Ver **`docs/DESIGN.md`** para documentación completa de diseño y decisiones técnicas.

### Estructura de Alto Nivel

```
pelotitas/
├── scenes/          # Escenas de Godot (boot, menús, arena)
├── scripts/         # Scripts GDScript organizados por sistema
│   ├── core/        # Autoloads: Game, Net, Progression
│   ├── combat/      # Player, Projectile
│   ├── abilities/   # Sistema de habilidades y loadout
│   ├── modes/       # Modos de juego (Duelo por Vida, etc.)
│   ├── progression/ # Level-up, afinidad, skill tree
│   └── net/         # Networking y multiplayer
├── assets/          # Arte, audio, fuentes (placeholders)
└── docs/            # Documentación de diseño
```

### Sistemas Clave

- **Modos de Juego Modulares**: arquitectura plug-in para agregar nuevos modos sin modificar el núcleo
- **Multiplayer Online**: servidor autoritativo usando Godot High-Level Multiplayer API
- **Progresión Elemental**: sistema de afinidad secreta que determina qué puntos de habilidad obtienes al subir de nivel
- **Loadout**: 3 habilidades usables + 1 pasiva por duelo
- **Primer Modo**: **Duelo por Vida** (1v1, gana el primero en reducir HP rival a 0)

## Controles (Provisional)

- **WASD**: Movimiento
- **1, 2, 3**: Usar habilidades equipadas
- **ESC**: Menú de pausa (TODO)

## TODOs Críticos

Ver `docs/DESIGN.md` para lista completa. Prioridades inmediatas:

1. Implementar sincronización multiplayer real (MultiplayerSynchronizer)
2. Crear 3-5 habilidades concretas por elemento
3. UI de vida, cooldowns, y loadout
4. Lobby para esperar jugadores
5. Persistencia de progresión (save/load)

## Contribuir

Por ahora, este proyecto está en fase de scaffolding inicial. Consulta `docs/DESIGN.md` para decisiones de diseño bloqueadas antes de proponer cambios grandes.

## Licencia

TODO: Definir licencia
