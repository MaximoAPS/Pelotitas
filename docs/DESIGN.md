# Documento de Diseño - Pelotitas

## Visión General

Juego **mobile-first** online 2D top-down de batallas entre pelotitas elementales. Arquitectura modular y escalable pensada para agregar nuevos modos, habilidades y mecánicas sin reescribir código existente.

**Plataforma primaria**: **Android** con controles táctiles  
**Plataforma futura**: iOS (posterior a Android)  
**Plataformas secundarias**: Desktop y web para desarrollo y testing

**Estado actual**: Scaffolding inicial - solo estructura base y stubs, no gameplay completo.

---

## Decisiones de Diseño Bloqueadas

### 1. Género y Temática

**Batallas de pelotitas elementales**: Fuego, Agua, Tierra, Aire/Viento.

- Cada elemento tiene habilidades únicas que spawnen más pelotitas de diferentes colores
- Tipos de habilidades:
  - **Disparos simples hacia adelante**
  - **Invocaciones (summons)** que atacan automáticamente
  - **Muros** para cobertura y defensa

### 2. Vista y Gráficos

**2D top-down con apariencia pseudo-3D**:

- La física y las escenas son **completamente 2D**
- Las esferas se renderizan con **sombreado y highlights** para dar sensación de volumen 3D
- Estilo visual estilizado (no realista)
- **Orientación landscape** (horizontal) para combate en arena

### 3. Multijugador y Plataforma

**Android-first con PvP online**:

- **Plataforma primaria**: **Android** con controles táctiles (gama media/alta target)
- **Plataforma futura**: iOS (mismo código base, requiere Mac para build)
- **Plataformas secundarias**: Desktop/web para desarrollo y testing
- Sistema de autoridad de red (Godot High-Level Multiplayer API)
- **Servidor autoritativo** para combate y física
- **Path local/bots** para testing e iteración sin oponente remoto
- Optimización de red para WiFi/4G/5G móvil

**Controles táctiles (Android-optimized) - Layout y mecánicas bloqueadas**:

Layout estilo **twin-stick-ish** (stick izquierda, botones derecha):

```
┌──────────────────────────────────────────────┐
│ [███ HP 100/100 ██████████████]              │  ← Barra de vida
│                                              │
│                         →                    │  ← Indicador de apuntado
│                    ARENA        (hold+drag)  │     (visual feedback)
│                                              │
│                                              │
│                                              │
│  [  ◉  ]                        [ 1 ]        │  ← Izquierda: Palanca
│   PALANCA                       [ 2 ]        │  ← Derecha: 3 botones
│                                 [ 3 ]        │     (press-hold-drag-release)
└──────────────────────────────────────────────┘
```

### Mecánicas de Control

**Movimiento (Palanca / Joystick virtual - izquierda inferior)**:
- Movimiento 360° con deadzone
- Drag dentro del área de la palanca
- Independiente del sistema de habilidades

**Habilidades usables (3 botones - derecha inferior)**:

Sistema **press-and-hold-drag-release** para apuntado preciso:

1. **Press y hold** en botón de habilidad (1, 2, o 3)
   - Inicia modo de apuntado
   - Habilidad no se activa todavía
   - Visual feedback: botón resaltado

2. **Drag** en la dirección deseada
   - Mientras mantienes presionado, arrastra el dedo
   - La dirección del arrastre determina hacia dónde se lanzará la habilidad
   - Visual feedback: flecha/línea de apuntado desde el jugador (TODO)

3. **Release** para disparar
   - Suelta el dedo para activar la habilidad
   - La habilidad se lanza en la dirección que arrastraste
   - Si no hay arrastre significativo (< 30px), usa dirección por defecto (derecha)

**Habilidad pasiva**: 
- NO tiene botón - siempre está activa automáticamente en segundo plano
- Sin interacción del jugador requerida

**HUD superior**: 
- Barra de vida
- Cooldowns visuales en botones (futuro: overlay circular)

**Feedback**: 
- Visual al presionar y durante drag
- Vibración háptica Android al disparar (futuro)

⚠️ **Este layout y mecánica de control son definitivos** y no deben cambiarse sin aprobación del usuario.

### 4. Sistema de Modos Modular

**Arquitectura plug-in** para modos de juego:

- **Núcleo de combate compartido**: jugador, movimiento, habilidades, daño
- **Cada modo solo define**:
  - Condiciones de victoria
  - Reglas de spawn (jugadores, objetos)
  - Configuración de mapa
  - Lógica específica de eventos

**Primer modo shippable**: **Duelo por Vida** (1v1)
- Gana el primero en reducir la vida del rival a 0
- Mapa: arena simple

**Futuros modos fáciles de agregar** (solo requieren nueva clase de `Mode`):
- Captura la Bandera
- Destruye la Estructura
- Team Deathmatch
- King of the Hill
- Knockout (empujar rivales fuera del mapa)

### 5. Progresión y Skill Tree

**Subir de nivel otorga puntos de habilidad elementales**:

- Al subir de nivel, recibes **1 punto de habilidad** de un elemento
- Los puntos se usan para **comprar o mejorar habilidades**
- Las habilidades pueden **desbloquear otras habilidades** (árbol de dependencias)

**Sistema de Afinidad (estilo DinoRPG)**:

- Al **crear una pelotita**, se generan pesos elementales aleatorios **permanentes**
  - Ejemplo: Fuego 15%, Aire 15%, Agua 35%, Tierra 35%
  - Suma total: 100%
- Estos pesos son **secretos** y nunca se muestran al jugador
- Al subir de nivel, el **elemento del punto otorgado** se tira aleatoriamente según estos pesos
- Cada pelotita tiene sus propios pesos únicos **para toda la vida**

**Ejemplo**:
```
Pelotita "Chispa":
  Afinidad secreta: Fuego 40%, Agua 20%, Tierra 10%, Aire 30%
  
  Level up 1: tira 40% → Fuego (+1 punto Fuego)
  Level up 2: tira 85% → Aire (+1 punto Aire)
  Level up 3: tira 15% → Agua (+1 punto Agua)
```

### 10. Loadout por Duelo

Cada pelotita equipa **3 habilidades usables + 1 pasiva** antes de entrar al duelo.

- **Habilidades usables**: se activan con botones táctiles (1, 2, 3) o teclas en desktop
  - Tienen cooldown
  - Requieren presionar botón para ejecutar
  - Cada una tiene su propio slot en el HUD (derecha inferior)
- **Habilidad pasiva**: efecto permanente automático (ej: +10% velocidad, regeneración)
  - NO tiene botón en el HUD
  - Siempre está activa durante el duelo
  - Efecto aplicado automáticamente al jugador

### 7. Stats de Combate

Cada pelotita tiene cuatro estadísticas base que afectan su desempeño en combate:

#### Stats Principales

- **Ataque** (`ataque`): Determina el daño que inflige la pelotita con sus habilidades
- **Defensa** (`defensa`): Reduce el daño recibido de ataques enemigos
- **Velocidad** (`velocidad`): Multiplicador de la velocidad de movimiento de la pelotita
- **Masa** (`masa`): Determina la respuesta en colisiones elásticas con otras pelotitas (valores mayores empujan más)

#### Fórmula de Daño

El daño final aplicado cuando un proyectil impacta a un enemigo se calcula como:

```
Daño Final = max(1, Ataque_atacante - Defensa_víctima × 0.5)
```

**Explicación**:
- El ataque del atacante se reduce por la mitad de la defensa de la víctima
- El daño mínimo es siempre 1 (no puede ser 0 o negativo)
- Valores típicos iniciales: Ataque 10, Defensa 5 → Daño = max(1, 10 - 5×0.5) = 7.5 ≈ 8

**Ejemplo de cálculo**:
```
Pelotita A (Ataque: 15) ataca a Pelotita B (Defensa: 8)
Daño = max(1, 15 - 8 × 0.5) = max(1, 15 - 4) = 11
```

#### Velocidad de Movimiento (Sistema Relativo)

La velocidad de movimiento usa un sistema **relativo** basado en la media geométrica de todos los participantes del match. Esto garantiza que las velocidades sean proporcionales entre jugadores independientemente de los valores absolutos de sus stats.

**Fórmula**:

1. **Media geométrica** de velocidades de participantes:
   ```
   G = (∏ V_i)^(1/n)
   ```
   Donde `V_i` es el stat de velocidad de cada participante y `n` es el número de participantes.

2. **Velocidad en metros virtuales por segundo** para cada pelotita:
   ```
   speed_m_s = V_i / G
   ```
   Una pelotita con `velocidad = G` se mueve a exactamente **1.0 m/s**.

3. **Conversión a píxeles**:
   ```
   speed_px_s = speed_m_s × PIXELS_PER_METER
   ```
   **Constante de escala**: `PIXELS_PER_METER = 200 px/m`
   - Elegida para pantallas 1920×1080 landscape (Android)
   - Define la escala visual de la arena

**Ejemplo numérico (Duelo 1v1)**:

```
Participantes:
- Pelotita A: velocidad = 1.5
- Pelotita B: velocidad = 0.75

Media geométrica:
G = (1.5 × 0.75)^(1/2) = (1.125)^0.5 ≈ 1.061

Velocidades normalizadas:
- Pelotita A: speed_m_s = 1.5 / 1.061 ≈ 1.414 m/s
  → speed_px_s = 1.414 × 200 ≈ 283 px/s
  
- Pelotita B: speed_m_s = 0.75 / 1.061 ≈ 0.707 m/s
  → speed_px_s = 0.707 × 200 ≈ 141 px/s

Relación: A es ~2× más rápida que B (1.5 / 0.75 = 2.0)
```

**Ventajas del sistema relativo**:
- Las velocidades son **proporcionales** entre jugadores
- Un jugador con el doble de stat de velocidad se mueve al doble de velocidad
- Independiente de valores absolutos (funciona igual con 1-2 que con 100-200)
- Se recalcula al inicio de cada match según participantes

**Guardas de seguridad**:
- `V_i <= 0` se clampea a `0.01` (epsilon mínimo)
- Previene división por cero y valores inválidos

**Nota importante**: La velocidad de **proyectiles** es independiente del stat de velocidad del personaje. Cada habilidad define su propia velocidad de proyectil (puede usar m/s con la misma constante PIXELS_PER_METER, ej: 2.0 m/s = 400 px/s para disparos básicos elementales).

#### Knockback (Retroceso)

Cuando un proyectil impacta a una pelotita:
- La víctima es empujada en dirección opuesta al impacto
- La fuerza de knockback es fija: **150 píxeles/segundo** inicialmente
- El knockback puede escalarse ligeramente con el ataque en el futuro
- Propósito: Separar combatientes y crear dinámica posicional

### 8. Sistema de Física y Colisiones

El juego implementa física de esferas rígidas para colisiones entre pelotitas y daño por impacto contra paredes.

#### Colisiones entre Jugadores (Pelotita vs Pelotita)

**Mecánica**: Colisiones elásticas perfectas (sin deformación)

- Las pelotitas se comportan como esferas rígidas que rebotan al colisionar
- **NO causan daño** por sí mismas
- La respuesta de colisión depende de la **masa** de cada pelotita:
  - Una pelotita con mayor masa empuja más a una con menor masa
  - Conservación de momento lineal y energía cinética (colisión perfectamente elástica)
- **Fórmula de impulso elástico**:
  ```
  impulse_scalar = -(1 + e) × v_rel · n / (1/m1 + 1/m2)
  ```
  Donde:
  - `e = 1.0` (coeficiente de restitución, perfectamente elástico)
  - `v_rel` = velocidad relativa entre pelotitas
  - `n` = normal de colisión (dirección de separación normalizada)
  - `m1`, `m2` = masas de las pelotitas

**Propósito estratégico**:
- Empujar al rival contra la pared para causar daño indirecto
- Habilidades como dash/empuje permiten knockback direccional
- Diferencias de masa crean asimetrías tácticas (pasivas que aumentan masa vienen en futuro)

#### Colisiones con Paredes (Pelotita vs Arena)

**Mecánica**: Daño por impacto basado en velocidad

- Las paredes de la arena son `StaticBody2D` con colisión
- **SÍ causan daño** al impactar, escalando con velocidad de impacto
- **Fórmula de daño por pared**:
  ```
  if impact_speed > WALL_DAMAGE_THRESHOLD:
      wall_damage = (impact_speed - threshold) × WALL_DAMAGE_MULTIPLIER × masa
  ```
  Donde:
  - `WALL_DAMAGE_THRESHOLD = 100.0 px/s` (velocidad mínima para causar daño)
  - `WALL_DAMAGE_MULTIPLIER = 0.02` (daño por unidad de velocidad)
  - `impact_speed` = velocidad del jugador proyectada sobre la normal de la pared
  - `masa` = stat de masa de la pelotita

**Ejemplo**:
```
Pelotita con masa=1.0 impacta pared a 300 px/s:
wall_damage = (300 - 100) × 0.02 × 1.0 = 4 puntos de daño

Pelotita con masa=1.5 impacta pared a 400 px/s:
wall_damage = (400 - 100) × 0.02 × 1.5 = 9 puntos de daño
```

**Propósito estratégico**:
- Crear zonas de peligro en los bordes del mapa
- Recompensar posicionamiento defensivo central
- Habilidades de empuje/dash se vuelven ofensivas al forzar colisiones de pared
- Mayor masa = mayor daño recibido de paredes (trade-off táctico)

#### Configuración de Arena

- **Dimensiones**: 1920×1080 píxeles (landscape móvil)
- **Paredes**: Rectángulos de 20px de grosor en los 4 bordes
- **Color de paredes**: Rojo oscuro (Color(0.6, 0.2, 0.2, 1)) para indicar peligro
- **Posiciones de spawn**: Alejadas de las paredes (300px desde borde izquierdo, 1620px desde derecho)

### 9. Sistema de Triggers para Habilidades

Las habilidades pueden responder a eventos del juego mediante **triggers** (hooks). Esto permite mecánicas complejas sin hardcodear comportamientos específicos.

#### Triggers Disponibles

Todos los triggers están definidos en la clase base `Ability` y pueden ser sobrescritos en habilidades concretas:

**Triggers de ciclo de vida**:
- `on_equip(player: Player)`: Llamado cuando se equipa la habilidad en el loadout (antes del match)
- `on_match_start(player: Player)`: Llamado al inicio del match (ej: aplicar buff de velocidad)

**Triggers de combate** (solo `UsableAbility`):
- `on_activate(caster: Player, aim_direction: Vector2)`: Llamado al usar la habilidad (después de pasar cooldown)
- `on_hit_enemy(caster: Player, target: Player, projectile: Node2D)`: Llamado cuando un proyectil de esta habilidad impacta enemigo

**Triggers de colisión**:
- `on_collide_player(self_player: Player, other_player: Player)`: Llamado cuando el jugador colisiona con otro jugador
- `on_collide_wall(player: Player, impact_point: Vector2, wall_normal: Vector2)`: Llamado cuando el jugador colisiona con pared

#### Flujo de Ejecución de Triggers

```
1. Equipar loadout:
   loadout.trigger_on_equip()
   → ability.on_equip(player)

2. Iniciar match:
   loadout.trigger_on_match_start()
   → ability.on_match_start(player)

3. Usar habilidad:
   ability.try_use(caster, aim_dir)
   → ability.on_activate(caster, aim_dir)
   → ability.execute(caster, aim_dir)  # Lógica principal

4. Proyectil impacta enemigo:
   projectile._on_body_entered(enemy)
   → ability.on_hit_enemy(caster, enemy, projectile)

5. Jugador colisiona con otro jugador:
   player._handle_player_collisions()
   → loadout.trigger_on_collide_player(self, other)
   → ability.on_collide_player(self, other)

6. Jugador colisiona con pared:
   player._handle_wall_collisions()
   → loadout.trigger_on_collide_wall(player, point, normal)
   → ability.on_collide_wall(player, point, normal)
```

#### Ejemplos de Uso de Triggers

**Ejemplo 1: Pasiva de velocidad al inicio de match**
```gdscript
# PassiveSpeedBoost.gd
extends PassiveAbility

func on_match_start(player: Player) -> void:
    player.velocidad *= 1.2  # +20% velocidad
    print("[PassiveSpeedBoost] Velocidad aumentada")
```

**Ejemplo 2: Habilidad que hace daño extra al contacto**
```gdscript
# ContactDamage.gd
extends PassiveAbility

func on_collide_player(self_player: Player, other_player: Player) -> void:
    var damage = self_player.ataque * 0.5
    other_player.take_damage(int(damage))
    print("[ContactDamage] Daño por contacto aplicado")
```

**Ejemplo 3: Dash que empuja al enemigo contra la pared**
```gdscript
# DashAbility.gd
extends UsableAbility

func on_activate(caster: Player, aim_direction: Vector2) -> void:
    # Aplicar velocidad instantánea en dirección del dash
    caster.velocity = aim_direction.normalized() * 800.0
    print("[Dash] Empuje direccional aplicado")
```

**Ejemplo 4: Proyectil que cura al impactar**
```gdscript
# VampireShot.gd
extends UsableAbility

func on_hit_enemy(caster: Player, target: Player, projectile: Node2D) -> void:
    var heal_amount = 5
    caster.heal(heal_amount)
    print("[VampireShot] %d vida recuperada" % heal_amount)
```

#### Implementación Técnica

- **`Loadout`** gestiona los triggers y los propaga a todas las habilidades equipadas
- **`Projectile`** almacena referencias a `source_ability` y `source_player` para invocar `on_hit_enemy`
- **`Player`** detecta colisiones en `_physics_process()` y llama a los triggers del loadout
- Las habilidades **no necesitan implementar todos los triggers**, solo los relevantes (implementación por defecto vacía en `Ability`)

---

## Flujo de App v0.1

### Secuencia de Pantallas

El flujo básico de la aplicación para la versión 0.1 local:

```
Boot (1s splash)
    ↓
Main Menu
    ├─→ Prueba Local → Arena Duelo → Results Screen
    │                      ↓              ├─→ Otra vez (restart arena)
    │                   (combate)         └─→ Menú principal
    ├─→ Crear Servidor (stub, no implementado)
    ├─→ Unirse a Partida (stub, no implementado)
    └─→ Salir (cierra app)
```

### Descripción de Pantallas

**1. Boot (`scenes/boot/boot.tscn`)**
- Splash screen de 1 segundo
- Carga recursos globales y autoloads
- Transiciona automáticamente al menú principal
- **NO auto-start** al arena (debug mode removido)

**2. Main Menu (`scenes/menus/main_menu.tscn`)**
- Título: "PELOTITAS" + subtítulo "v0.1 local"
- Botones:
  - **Prueba Local**: Inicia duelo 1v1 local (player vs dummy)
  - **Crear Servidor**: Stub para networking futuro
  - **Unirse a Partida**: Stub para networking futuro
  - **Salir**: Cierra la aplicación
- Layout centrado, botones grandes y mobile-friendly
- Sin auto-start timer que salte al arena

**3. Arena Duelo (`scenes/duel/arena_duelo.tscn`)**
- Duelo 1v1: Player controlable vs Dummy estacionario
- Player 1 (azul): Controlado por joystick/teclado
- Player 2 (rojo/naranja): Dummy que NO se mueve, solo recibe daño
- Física de colisiones y habilidades activas
- HUD móvil con controles táctiles
- **Victory detection**: Cuando un jugador muere (HP = 0), se llama `Game.end_duel()`

**4. Results Screen (`scenes/ui/results_screen.tscn`)**
- Overlay CanvasLayer sobre la arena
- Muestra resultado:
  - **"¡GANASTE!"** si el jugador local ganó
  - **"PERDISTE"** si el jugador local perdió
  - **"¡EMPATE!"** si ambos murieron simultáneamente
- Botones:
  - **Otra vez**: Reinicia el duelo (recarga arena con nuevo modo)
  - **Menú principal**: Vuelve al menú principal
- Aparece automáticamente cuando `Game.duel_ended` signal se emite

### Flujo Técnico

**Inicio de Duelo (Prueba Local)**:
1. Usuario presiona "Prueba Local" en menú
2. `MainMenu._on_local_test_pressed()` crea instancia de `DueloPorVida`
3. Llama `Game.start_duel(mode)` (cambia estado a `IN_DUEL`)
4. Cambia escena a `arena_duelo.tscn`

**Durante Duelo**:
1. `ArenaDuelo._ready()` spawns jugadores y registra en modo
2. `Mode.register_player()` conecta signal `player.died` a `_on_player_died`
3. Jugadores combaten usando habilidades y movimiento
4. `Mode.process(delta)` actualiza lógica del modo cada frame

**Fin de Duelo**:
1. Jugador muere → `Player.take_damage()` detecta `current_health <= 0`
2. `Player._die()` emite signal `died`
3. `Mode._on_player_died()` → `DueloPorVida.on_player_death()`
4. `DueloPorVida.check_victory_conditions()` verifica jugadores vivos
5. `DueloPorVida._declare_victory(winner_id)` → `Game.end_duel(winner_id)`
6. `Game.end_duel()` emite signal `duel_ended` y cambia estado a `POST_DUEL`
7. `ArenaDuelo._on_duel_ended()` llama `results_screen.show_results(winner_id)`
8. Results screen overlay aparece con botones de reinicio o menú

**Restart o Return**:
- **Otra vez**: `ResultsScreen._on_restart_pressed()` recrea modo y recarga escena actual
- **Menú principal**: `ResultsScreen._on_main_menu_pressed()` cambia estado a `MAIN_MENU` y carga `main_menu.tscn`

### Decisiones de Diseño

**¿Por qué no auto-start al arena?**
- Testing y debugging requieren acceso al menú
- Usuario debe elegir explícitamente el modo de juego
- Facilita testing de networking cuando se implemente

**¿Por qué overlay en lugar de cambio de escena?**
- Permite ver el estado final del duelo (posiciones, HP)
- Más rápido que recargar toda la escena
- Mejor UX para mobile (sin flash de carga)

**¿Por qué reload_current_scene() para restart?**
- Limpia todo el estado del duelo anterior
- Garantiza spawn fresco de jugadores y proyectiles
- Evita bugs de estado persistente

---

## Arquitectura del Proyecto

### Estructura de Carpetas

```
pelotitas/
├── project.godot
├── README.md
├── icon.svg
├── scenes/
│   ├── boot/
│   │   ├── boot.tscn
│   │   └── boot.gd
│   ├── menus/
│   │   ├── main_menu.tscn
│   │   └── main_menu.gd
│   ├── duel/
│   │   ├── arena_duelo.tscn
│   │   ├── arena_duelo.gd
│   │   └── player_prefab.tscn
│   └── ui/
│       ├── mobile_hud.tscn
│       └── mobile_hud.gd
├── scripts/
│   ├── core/
│   │   ├── game.gd          (Autoload: estado global)
│   │   ├── net.gd           (Autoload: multiplayer)
│   │   └── progression.gd   (Autoload: niveles y afinidad)
│   ├── combat/
│   │   ├── player.gd        (Jugador/pelotita en duelo)
│   │   └── projectile.gd    (Proyectiles base)
│   ├── abilities/
│   │   ├── ability.gd       (Clase base abstracta)
│   │   ├── usable_ability.gd
│   │   ├── passive_ability.gd
│   │   └── loadout.gd       (Contenedor 3+1)
│   ├── modes/
│   │   ├── mode.gd          (Clase base abstracta)
│   │   ├── duelo_por_vida.gd
│   │   └── mode_registry.gd
│   ├── progression/
│   │   └── (futuros: skill tree editor, unlock logic)
│   └── net/
│       └── (futuros: lobby, matchmaking)
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── docs/
    └── DESIGN.md (este documento)
```

### Autoloads (Singletons)

1. **Game** (`scripts/core/game.gd`)
   - Gestiona estado global (menú, lobby, duelo)
   - Mantiene referencia al modo activo
   - Coordina transiciones de escenas

2. **Net** (`scripts/core/net.gd`)
   - Maneja conexiones multiplayer (ENet)
   - Provee helpers para autoridad de red y RPCs
   - Emite señales de conexión/desconexión

3. **Progression** (`scripts/core/progression.gd`)
   - Sistema de nivel y experiencia
   - Gestiona afinidades elementales secretas
   - Otorga puntos de habilidad en level-ups
   - Maneja aprendizaje de skills

4. **TouchInput** (`scripts/core/touch_input.gd`)
   - Manejo de controles táctiles móviles
   - Joystick virtual con deadzone
   - Emite señales para movimiento y habilidades
   - Fallback a teclado para testing en desktop

### Sistema de Modos

**Clase base**: `Mode` (`scripts/modes/mode.gd`)

Métodos abstractos:
- `on_match_start()`: inicializa el modo
- `check_victory_conditions()`: verifica ganador
- `on_player_death(player)`: maneja muerte
- `get_spawn_positions()`: posiciones de spawn
- `process(delta)`: lógica por frame

**Modo concreto**: `DueloPorVida` (`scripts/modes/duelo_por_vida.gd`)

- Victoria: último jugador vivo
- Spawn: 2 posiciones fijas (izq/der)

**Agregar nuevo modo** (futuro):
1. Crear clase heredando de `Mode`
2. Implementar métodos abstractos
3. Registrar en `ModeRegistry`

### Sistema de Habilidades

**Jerarquía**:
```
Ability (Resource base)
├── UsableAbility (activables)
└── PassiveAbility (efectos permanentes)
```

**Loadout** (`scripts/abilities/loadout.gd`):
- 3 slots para `UsableAbility`
- 1 slot para `PassiveAbility`

**Crear nueva habilidad** (futuro):
1. Heredar de `UsableAbility` o `PassiveAbility`
2. Implementar `execute(caster)` o `apply(player)`
3. Definir cooldown, costo, elemento
4. Agregar a skill tree

#### Habilidades Elementales Básicas

Cada elemento tiene un **disparo básico** que funciona con la misma mecánica:

**Disparos Elementales** (Fuego, Agua, Tierra, Viento):
- Mecánica unificada: proyectil direccional activado con press-hold-drag-release
- Diferenciados por elemento y color visual:
  - **Fuego**: Rojo/naranja (Color(1, 0.2, 0, 1))
  - **Agua**: Azul (Color(0, 0.4, 1, 1))
  - **Tierra**: Marrón (Color(0.6, 0.4, 0.2, 1))
  - **Viento**: Verde claro (Color(0.7, 1, 0.7, 1))
- Al impactar enemigo:
  - Aplica daño según fórmula de stats (Ataque vs Defensa)
  - Produce knockback pequeño alejando a la víctima
  - Trigger `on_hit_enemy` disponible para efectos adicionales
- Propiedades:
  - Velocidad: 400 px/s
  - Duración: 3 segundos
  - Cooldown: 1 segundo
- Visuales placeholder: círculos coloreados hexagonales

**Implementación**: `ElementalShot` hereda de `UsableAbility`, instancia escena `projectile_elemental.tscn`

**Sistema de Triggers**: Todos los disparos elementales pueden sobrescribir triggers como `on_activate`, `on_hit_enemy`, `on_match_start` para agregar efectos especiales (ver sección 9: Sistema de Triggers)

### Combate y Jugadores

**Player** (`scripts/combat/player.gd`):
- Movimiento con joystick virtual (touch) o WASD (desktop fallback)
- **Stats de combate**: Ataque, Defensa, Velocidad
  - Velocidad afecta directamente la velocidad de movimiento
- Vida y daño
- Usa habilidades del loadout (botones táctiles o teclas 1, 2, 3)
- Recibe knockback al ser impactado
- Sincronización de red (solo owner controla movimiento)

**Mobile HUD** (`scenes/ui/mobile_hud.tscn/.gd`):
- **Layout twin-stick-ish bloqueado**:
  - Palanca/joystick virtual táctil (izquierda inferior)
  - 3 botones de habilidades usables, grandes y touch-friendly (derecha inferior)
  - Barra de vida superior
  - Cooldowns visuales (stub - futuro: overlay en botones)
- **Sin botón para pasiva**: la habilidad pasiva es automática, no requiere UI

**Projectile** (`scripts/combat/projectile.gd`):
- Movimiento en línea recta
- Colisión y daño basado en stats del caster (Ataque) y del target (Defensa)
- Aplica knockback direccional al impactar
- Opciones: pierce, lifetime, velocidad
- Los proyectiles portan el stat de Ataque del caster para calcular daño dinámicamente

---

## TODOs Críticos para Gameplay Completo

### Red y Multiplayer
- [ ] Implementar MultiplayerSynchronizer en Player
- [ ] Lobby para esperar jugadores
- [ ] Sincronizar spawn de proyectiles
- [ ] Manejo de latencia y desconexiones (crítico en mobile)
- [ ] Optimización de ancho de banda para redes móviles

### Android-Specific
- [ ] **Testing en dispositivos Android reales** (gama media: Samsung Galaxy A, Xiaomi Redmi)
- [ ] Optimización de rendimiento para Android gama media/baja
- [ ] Configuración de export templates Android (APK + AAB para Play Store)
- [ ] Vibración háptica en habilidades y daño (Android Vibrator API)
- [ ] Ajuste de tamaños de botones según DPI Android
- [ ] Manejo de diferentes aspect ratios Android (18:9, 19:9, 20:9, etc.)
- [ ] Pausa automática al perder foco (llamada entrante, home button)
- [ ] Testing en diferentes versiones Android (7.0 - 14+)
- [ ] Permisos Android: INTERNET, ACCESS_NETWORK_STATE, VIBRATE

### iOS (Futuro)
- [ ] Configuración de export templates iOS (requiere macOS + Xcode)
- [ ] Provisioning profiles y certificados Apple Developer
- [ ] Adaptaciones específicas de iOS (notch, dynamic island, gestures)

### Habilidades
- [ ] Implementar habilidades elementales concretas
  - [ ] Disparo de fuego
  - [ ] Muro de tierra
  - [ ] Invocación de aire
  - [ ] Ola de agua
- [ ] Cooldown visual (UI)
- [ ] Efectos visuales y sonidos

### Progresión
- [ ] UI de skill tree
- [ ] Persistencia de datos (save/load)
- [ ] Balance de experiencia y niveles
- [ ] Definir todas las habilidades y dependencias

### Modos Adicionales
- [ ] Captura la Bandera
- [ ] Destruye la Estructura
- [ ] Team Deathmatch

### UI/UX
- [ ] HUD de vida, cooldowns, puntos
- [ ] Menú de loadout (equipar habilidades)
- [ ] Pantalla de victoria/derrota
- [ ] Lobby con lista de jugadores

### Arte y Audio
- [ ] Sprites de pelotitas elementales
- [ ] Efectos de partículas
- [ ] Música de fondo
- [ ] SFX de habilidades

---

## Convenciones de Código

- **Lenguaje**: GDScript (Godot 4.x)
- **Nombrado**:
  - `snake_case` para variables y funciones
  - `PascalCase` para clases
  - `SCREAMING_SNAKE_CASE` para constantes
- **Comentarios**: usar `##` para doc comments de funciones/clases
- **Señales**: declarar al inicio de la clase con `signal`
- **TODOs**: marcar código incompleto con `# TODO: descripción`

---

## Configuración Android

### project.godot - Settings Clave

- **Orientación**: Landscape (sensor_landscape = 6) - rotación automática izq/der
- **Resolución base**: 1920x1080 (escalado a diferentes dispositivos Android)
- **Stretch mode**: `canvas_items` con aspect `expand`
- **Touch emulation**: Habilitado en editor para testing con mouse en desktop
- **Export template primario**: Android APK/AAB
- **Min SDK**: Android 7.0 (API 24) - compatibilidad amplia
- **Target SDK**: Android 14+ (API 34) - requerido por Google Play

### Configuración de Export Android

Ver `docs/MOBILE_EXPORT.md` para detalles completos.

**Package**: `com.maximoaps.pelotitas`  
**Permisos requeridos**:
- `INTERNET`: Multiplayer online
- `ACCESS_NETWORK_STATE`: Detectar WiFi vs datos móviles
- `VIBRATE`: Feedback háptico (opcional)

**Formato de release**: AAB (Android App Bundle) para Google Play Store

### Controles de Testing Desktop

Para desarrollo en PC/Mac sin touch:
- **Arrow keys / WASD**: Movimiento (fallback automático)
- **1, 2, 3**: Habilidades
- **Mouse click + drag**: Emula joystick virtual

### Testing Local (Sin Red)

Para pruebas sin multiplayer, el juego spawna:
- **Player 1**: Controlable con teclado/touch (azul)
- **Player 2**: Dummy estacionario que NO se mueve ni persigue (rojo/naranja)
  - Puede recibir daño de proyectiles
  - Participa en colisiones elásticas (puede ser empujado)
  - Recibe daño de paredes si es empujado contra ellas
  - **NO tiene lógica de AI** - solo es un target de prueba

Este enfoque permite testear física y habilidades sin implementar oponente inteligente.

## Notas Finales

Este documento debe **actualizarse** cuando se tomen nuevas decisiones de diseño o se implementen sistemas críticos.

**Prioridad actual (Android-first)**: 
1. **Testing en dispositivo Android real** (Samsung Galaxy A52/A53 o Xiaomi Redmi Note 11 recomendados)
2. Completar red y sincronización multiplayer optimizada para Android (WiFi/4G/5G)
3. Implementar 3-5 habilidades básicas por elemento con feedback visual touch
4. Optimización de rendimiento para Android gama media (target: 60 FPS estable)
5. Vibración háptica en Android para acciones de combate
6. Testing en múltiples aspect ratios Android
