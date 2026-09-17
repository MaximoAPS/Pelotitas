# Pelotitas

Juego **mobile-first** online 2D top-down de batallas entre pelotitas elementales (Fuego, Agua, Tierra, Aire).

🎮 **Plataforma primaria**: **Android** con controles táctiles  
📱 **Plataforma futura**: iOS (posterior a Android)  
🖥️ **Plataformas secundarias**: Desktop y web para desarrollo/testing

## Estado Actual

**Jugable** en Godot **4.7.2**: menú, host/join LAN, duelo vs dummy, 4 disparos elementales, física (choque elástico, antimateria tiro-tiro), shrink de arena, XP/level-up y roster (cap 1, con reset). Árbol de habilidades **diseñado** (`docs/GDD.md` §5.5); UI de rangos/T2/pasivas y más skills, no.

## Requisitos

- **Godot Engine 4.7.2** (el `project.godot` declara feature `4.7`)
- Sistema operativo: Windows, Linux, o macOS
- **Para export Android**: Android SDK + build tools (ver `docs/MOBILE_EXPORT.md`)

## Cómo Abrir el Proyecto

### Desarrollo en Desktop (PC/Mac/Linux)

1. Clona este repositorio:
   ```bash
   git clone https://github.com/MaximoAPS/Pelotitas.git
   cd Pelotitas
   ```

2. Abre **Godot 4.7** y selecciona "Importar" en el Project Manager

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
3. Instalar export templates de Godot **4.7.2.stable** (no .NET)
4. Project → Export → Android (APK). Detalle: `docs/MOBILE_EXPORT.md`

**Package name**: `com.maximoaps.pelotitas`  
**SDK Platform**: 35 (Android 15). Min SDK: el default del template (no overridear sin Gradle).

## Arquitectura

Ver **`docs/ARCHITECTURE.md`** para autoloads, `GameRules` y cómo correr tests.  
Ver **`docs/GDD.md`** §5.5 para el árbol locked. **`docs/DESIGN.md`** para el resto de decisiones.

### Estructura de Alto Nivel

```
pelotitas/
├── scenes/          # Escenas de Godot (boot, menús, arena, HUD)
├── scripts/
│   ├── core/        # Autoloads + GameRules
│   ├── combat/      # Player, Projectile, trayectorias (stubs)
│   ├── abilities/   # Ability / Loadout / ElementalShot
│   ├── modes/       # Mode + DueloPorVida + ModeRegistry
│   └── progression/ # PelotitaData
├── resources/abilities/
├── tests/           # logic_tests + duel_integration (headless)
└── docs/
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

1. Probar choque de tiros en LAN (hitbox); gastar puntos / equipar 3
2. Rangos del disparo básico y primer usable T2 (muro)
3. UI de XP / árbol / pasiva (1 slot)
4. Testing en dispositivo Android real

## Contribuir

Por ahora, este proyecto está en fase de scaffolding inicial. Consulta `docs/DESIGN.md` para decisiones de diseño bloqueadas antes de proponer cambios grandes.

## Licencia

TODO: Definir licencia
