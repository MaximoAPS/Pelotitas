# Pelotitas

Juego **mobile-first** online 2D top-down de batallas entre pelotitas elementales (Fuego, Agua, Tierra, Aire).

🎮 **Plataforma primaria**: **Android** con controles táctiles  
📱 **Plataforma futura**: iOS (posterior a Android)  
🖥️ **Plataformas secundarias**: Desktop y web para desarrollo/testing

## Estado Actual

**Scaffolding inicial** - Estructura del proyecto, stubs de sistemas, y documentación de diseño. No es un juego jugable todavía.

## Requisitos

- **Godot Engine 4.3+** (o cualquier versión 4.x compatible)
- Sistema operativo: Windows, Linux, o macOS
- **Para export Android**: Android SDK + build tools (ver `docs/MOBILE_EXPORT.md`)

## Cómo Abrir el Proyecto

### Desarrollo en Desktop (PC/Mac/Linux)

1. Clona este repositorio:
   ```bash
   git clone https://github.com/MaximoAPS/Pelotitas.git
   cd Pelotitas
   ```

2. Abre **Godot 4.3+** y selecciona "Importar" en el Project Manager

3. Navega a la carpeta del proyecto y selecciona `project.godot`

4. Haz clic en "Importar y Editar"

5. La escena principal se encuentra en `scenes/boot/boot.tscn`

6. **Testing con mouse**: El proyecto tiene touch emulation habilitado, así que puedes:
   - Hacer click y arrastrar en el área del joystick para simular touch
   - Click en botones de habilidades
   - Usar arrow keys/WASD como fallback para movimiento

### Testing en Android (Plataforma Target)

Ver **`docs/MOBILE_EXPORT.md`** para guía completa de configuración Android.

**Setup rápido**:
1. Instalar Android SDK (via Android Studio recomendado)
2. Configurar rutas en Godot: Editor → Editor Settings → Export → Android
3. Instalar export templates de Godot 4.3 para Android
4. Conectar dispositivo por USB con USB debugging habilitado
5. Project → Export → Android (APK) → One-click deploy

**Package name**: `com.maximoaps.pelotitas`  
**Min SDK**: Android 7.0 (API 24)  
**Target SDK**: Android 14+ (API 34)

## Arquitectura

Ver **`docs/DESIGN.md`** para documentación completa de diseño y decisiones técnicas.

### Estructura de Alto Nivel

```
pelotitas/
├── scenes/          # Escenas de Godot (boot, menús, arena)
│   ├── boot/        # Pantalla de inicio
│   ├── menus/       # Menú principal
│   ├── duel/        # Arena de combate
│   └── ui/          # HUD móvil con controles táctiles
├── scripts/         # Scripts GDScript organizados por sistema
│   ├── core/        # Autoloads: Game, Net, Progression, TouchInput
│   ├── combat/      # Player, Projectile
│   ├── abilities/   # Sistema de habilidades y loadout
│   ├── modes/       # Modos de juego (Duelo por Vida, etc.)
│   ├── progression/ # Level-up, afinidad, skill tree
│   └── net/         # Networking y multiplayer
├── assets/          # Arte, audio, fuentes (placeholders)
└── docs/            # Documentación de diseño
```

### Sistemas Clave

- **Android-First**: Layout twin-stick-ish (palanca izq + 3 botones der) optimizado para touch
- **Modos de Juego Modulares**: arquitectura plug-in para agregar nuevos modos sin modificar el núcleo
- **Multiplayer Online**: servidor autoritativo optimizado para redes móviles (WiFi/4G/5G)
- **Progresión Elemental**: sistema de afinidad secreta que determina qué puntos de habilidad obtienes al subir de nivel
- **Loadout**: 3 habilidades usables + 1 pasiva por duelo
- **Primer Modo**: **Duelo por Vida** (1v1, gana el primero en reducir HP rival a 0)
- **Orientación**: Landscape (horizontal) para mejor experiencia en combate arena
- **iOS**: Target futuro (posterior a lanzamiento Android)

## Controles

### Mobile (Touch) - Press-Hold-Drag-Release para Apuntado

**Movimiento**:
- **Palanca / Joystick virtual** (izquierda inferior): Movimiento 360° con deadzone

**Habilidades** (derecha inferior):
- **Press y hold** en botón (1, 2, o 3): Inicia apuntado
- **Drag** en la dirección deseada: Apunta hacia donde lanzar
- **Release**: Dispara la habilidad en esa dirección
- Cooldowns entre usos

**Pasiva**:
- Sin botón - siempre activa automáticamente

**HUD**:
- **Barra de vida** (superior): HP actual en tiempo real

### Desktop (Testing/Desarrollo)
- **WASD / Arrow keys**: Movimiento (fallback automático)
- **1, 2, 3**: Habilidades
- **Mouse click + drag**: Simula joystick virtual
- **ESC**: Menú de pausa (TODO)

## TODOs Críticos

Ver `docs/DESIGN.md` para lista completa. Prioridades inmediatas:

1. **Testing en dispositivo Android real**
2. Implementar sincronización multiplayer optimizada para mobile
3. Crear 3-5 habilidades concretas por elemento
4. Optimización de rendimiento para móviles gama media/baja
5. Lobby para esperar jugadores
6. Persistencia de progresión (save/load)
7. Vibración háptica en habilidades y daño
8. Manejo de diferentes aspect ratios móviles

## Contribuir

Por ahora, este proyecto está en fase de scaffolding inicial. Consulta `docs/DESIGN.md` para decisiones de diseño bloqueadas antes de proponer cambios grandes.

## Licencia

TODO: Definir licencia
