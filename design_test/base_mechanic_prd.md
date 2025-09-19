# PRD: Terrain Slice Excavation & Construction System

**Godot 4, Base-Building Game**

## 1. Overview

We are building a 3D grid-based excavation and construction system where the player carves out a mountain slice, builds rooms/corridors, and gets automatic walls and pillars.

This mechanic is the foundation of the game loop:

1. **Excavate terrain** → Dirt floor appears
2. **Place floors** → Rooms & corridors form
3. **Walls auto-generate** along floor/solid boundaries
4. **Pillars auto-generate** at corners where perpendicular walls meet

System must be modular, performant, and deterministic.

## 2. Goals

- Provide an intuitive excavation mechanic using a 3D layered grid
- Support multi-layer navigation (slice view)
- Auto-generate walls & pillars from simple player actions
- Ensure DIRT floors produce walls (bug fix: walls appear even without built floors)
- Keep system performant with chunking & dirty flags
- All derived geometry (walls/pillars) should be recomputed, not saved

## 3. Key Features

### Excavation
- Player selects cells (click or marquee)
- Solid → Excavated → Dirt floor by default
- Excavation triggers wall/pillar recompute

### Floor Construction
- Player places built floors (Stone, Concrete, Metal)
- Built floors upgrade wall material and unlock pillars
- Floor removal downgrades walls/pillars

### Auto Walls
- Appear where Excavated+Floor (DIRT or Built) borders Solid
- Wall material = floor material of excavated side

### Auto Pillars
- Appear where ≥2 perpendicular walls meet and ≥1 adjoining floor is Built (DIRT excluded)
- Pillar material = strongest adjacent wall material

### Layer Navigation
- Player can move slice up/down
- Only active layer is editable; others ghosted

### Performance
- Grid stored sparsely (Solid is implicit)
- Chunk system (16×16 per layer) with dirty flags
- Only dirty chunks rebuild meshes

## 4. Non-Goals

- No structural stability simulation (optional future)
- No physics-based destruction
- No decorative detail meshes beyond floors/walls/pillars

## 5. Data Structures

### CellData
```gdscript
terrain: {SOLID, MARKED, DIGGING, EXCAVATED}
floor: {NONE, DIRT, STONE, CONCRETE, METAL}
```

### LayerData
```gdscript
Dict "x,z" → CellData
```

### ChunkMap
- Partition layer into 16×16 chunks
- Track dirty flag, walls, floors, pillars

## 6. Rules (must match code)

- **Excavation** → Dirt floor appears
- **Walls**: placed if `has_any_floor()` (DIRT or Built) vs Solid
- **Pillars**: require ≥2 perpendicular walls + Built adjacency
- **Materials**: Dirt wall has valid material; no empty slot
- **Save/Load**: save only non-solid cells; recompute geometry on load

## 7. System Architecture

### Components

- **GridSystem** – orchestrator, holds layers/chunks, applies changes
- **LayerController** – manages active layer index
- **InputController** – handles tool selection and cell input
- **AutoGeo** – pure logic for wall/pillar eligibility
- **SliceRenderer** – instancing/drawing floors, walls, pillars
- **ChunkUpdater** – dirty flag tracking, signals for rebuild
- **MaterialMap** – maps floor type → wall/pillar materials
- **RegionFinder** – optional room/corridor detection

## 8. User Flows

### Excavation Flow
1. Player drags Excavate tool over Solid cells
2. Each cell → EXCAVATED + DIRT
3. GridSystem marks edges/corners dirty
4. AutoGeo recomputes:
   - Walls appear along Dirt vs Solid
   - Pillars not placed (DIRT floors excluded)
5. Renderer updates meshes

### Floor Placement Flow
1. Player drags Floors tool over Excavated cells
2. Cells → Built floor type
3. Adjacent walls upgrade to new material
4. Pillars appear at eligible corners
5. Renderer updates only dirty chunks

### Layer Switching
1. Player presses up/down
2. Active layer index changes
3. Renderer clears/rebuilds that slice

## 9. Implementation Plan

### Phase 1: Core Grid + Excavation
- GridSystem, LayerData, CellData
- Excavation tool → Dirt floors
- Walls appear correctly on Dirt

### Phase 2: Floors + Auto Walls/Pillars
- Floor tool → Built floors
- Walls upgrade; pillars spawn

### Phase 3: Layers + Renderer
- Add LayerController + SliceRenderer
- Visualize active layer slice

### Phase 4: Chunks + Optimization
- Implement ChunkMap + dirty flags
- Only rebuild dirty chunks

### Phase 5: Save/Load
- Serialize only non-solid cells
- Geometry recomputed on load

## 10. Acceptance Criteria

- ✅ Excavating creates Dirt floors and Dirt walls (fix for "walls only on Built")
- ✅ Upgrading floors updates wall material instantly
- ✅ Pillars appear only with Built floors at perpendicular wall corners
- ✅ Switching layers redraws slice with no artifacts
- ✅ Save/load restores floors & excavation state; walls/pillars auto-regenerate
- ✅ Chunk rebuild keeps FPS > 60 on a 50×50×20 grid

## 11. Edge Cases

- **Excavating a single isolated cell** → walls on all 4 edges, no pillars
- **Corridor excavation (long strip)** → parallel walls, no pillars until Built floor
- **Inside corner excavation around a Solid "column"** → pillars only when floors are Built
- **Floor removal** → downgrade adjacent walls; remove ineligible pillars

## 12. Deliverables for Claude Code

### Core Classes
- GridSystem, LayerData, CellData, ChunkMap
- AutoGeo, SliceRenderer, InputController, LayerController
- MaterialMap

### Testing & Debug
- Unit tests / harness: Verify excavation, floor placement, auto walls/pillars
- Debug overlay: Draw edge lines to confirm Dirt walls appear

### Configuration
- Config resource: Expose chunk size, material maps, and auto-pillar rules