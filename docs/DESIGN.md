# Documento de Diseño - Pelotitas

## Visión General

Juego online 2D top-down de batallas entre pelotitas elementales. Arquitectura modular y escalable pensada para agregar nuevos modos, habilidades y mecánicas sin reescribir código existente.

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

### 3. Multijugador

**Online desde el día 1**:

- Sistema de autoridad de red (Godot High-Level Multiplayer API)
- **Servidor autoritativo** para combate y física
- **Path local/bots** para testing e iteración sin oponente remoto

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

### 6. Loadout por Duelo

Cada pelotita equipa **3 habilidades usables + 1 pasiva** antes de entrar al duelo.

- **Habilidades usables**: se activan con teclas (1, 2, 3)
- **Habilidad pasiva**: efecto permanente (ej: +10% velocidad, regeneración)

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
│   └── duel/
│       ├── arena_duelo.tscn
│       ├── arena_duelo.gd
│       └── player_prefab.tscn
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

### Combate y Jugadores

**Player** (`scripts/combat/player.gd`):
- Movimiento WASD
- Vida y daño
- Usa habilidades del loadout (teclas 1, 2, 3)
- Sincronización de red (solo owner controla movimiento)

**Projectile** (`scripts/combat/projectile.gd`):
- Movimiento en línea recta
- Colisión y daño
- Opciones: pierce, lifetime, velocidad

---

## TODOs Críticos para Gameplay Completo

### Red y Multiplayer
- [ ] Implementar MultiplayerSynchronizer en Player
- [ ] Lobby para esperar jugadores
- [ ] Sincronizar spawn de proyectiles
- [ ] Manejo de latencia y desconexiones

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

## Notas Finales

Este documento debe **actualizarse** cuando se tomen nuevas decisiones de diseño o se implementen sistemas críticos.

**Prioridad actual**: Completar red y sincronización multiplayer, luego implementar 3-5 habilidades básicas por elemento para hacer el primer modo jugable.
