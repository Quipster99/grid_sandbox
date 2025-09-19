# Implementation Phases

## Phase 1: Core Grid + Excavation

**Goal:** Establish grid data model, excavation flow, Dirt floors, and Dirt walls.

### Tasks

#### Data Structures
- [x] Implement CellData with terrain + floor
- [x] Implement LayerData with sparse dict "x,z" → CellData
- [x] Add has_any_floor() helper (counts Dirt + Built)

#### GridSystem
- [x] Create GridSystem singleton to manage layers
- [x] Implement active_layer() + excavate(points)
- [x] Excavation → set terrain=EXCAVATED, floor=DIRT

#### Auto Walls
- [x] Implement AutoGeo.is_wall_edge() (floor vs Solid)
- [x] Add wall material lookup for Dirt

#### Rendering
- [x] Create SliceRenderer node
- [x] Add temporary floor/wall meshes (no pillars yet)

#### Testing
- [x] Excavate 1×1 → Dirt floor + walls
- [x] Excavate strip → parallel Dirt walls appear

---

## Phase 2: Floors + Auto Walls/Pillars

**Goal:** Support Built floors, wall upgrades, and pillar generation.

### Tasks

#### Floor Tool
- [x] Implement GridSystem.build_floor(points, floor_type)
- [x] Floors allowed only on Excavated cells

#### Wall Upgrades
- [x] Extend AutoGeo.edge_floor_material() to use strongest floor material
- [x] Implement downgrade on floor removal

#### Pillar Rules
- [x] Implement AutoGeo.corner_has_pillar()
- [x] Require ≥2 perpendicular walls + Built floor adjacency
- [x] Pillar material = strongest wall

#### Renderer
- [x] Add pillar rendering
- [x] Differentiate materials for Stone/Concrete/Metal walls

#### Testing
- [x] Build Stone floors in a corner → pillars appear **FIXED LOGIC**
- [x] Remove floor → pillar disappears, walls downgrade to Dirt

---

## Phase 3: Layers + Renderer

**Goal:** Multi-layer navigation and clean rendering per slice.

### Tasks

#### LayerController
- [x] Implement active_y + set_layer(y) (integrated into GridSystem)
- [x] Emit layer_changed signal (layer_rebuilt signal) **FIXED**

#### GridSystem Integration
- [x] Switch between layers with active context **NOW WORKING**
- [x] Ensure excavation/floor placement affects only active layer

#### SliceRenderer
- [x] Render only active layer **NOW WORKING**
- [ ] Ghost above/below layers (optional translucency)

#### Testing
- [x] Excavate on layer 0, switch to layer 1 → nothing visible **NOW WORKING**
- [x] Switch back → excavation intact **NOW WORKING**

---

## Additional Features Implemented

**Goal:** Enhanced user experience and visual feedback systems.

### Tasks

#### Camera System
- [x] Robust camera controller with WASD panning
- [x] Q/E rotation around focal point
- [x] Mouse wheel zoom with min/max limits
- [x] Middle mouse free look mode
- [x] Smooth interpolated movement

#### Visual Feedback
- [x] Terrain visualization (solid dirt cubes)
- [x] Smart mouse hover highlights (top face for solid, floor level for excavated)
- [x] Rectangular selection area highlights
- [x] Proper 3D ray-casting with surface detection
- [x] Anti-Z-fighting highlight positioning

#### Input System
- [x] Tool selection (1-5 keys)
- [x] Layer switching (Z/X keys)
- [x] Click and drag selection
- [x] Visual tool feedback
- [x] Floor removal tool (Tool 5)

#### Enhanced Materials
- [x] Distinct colors for all floor/wall/pillar types
- [x] Proper material differentiation
- [x] Lighter terrain color for better contrast

---

## Phase 4: Chunks + Optimization

**Goal:** Performance scalability with dirty chunk updates.

### Tasks

#### ChunkMap
- [ ] Partition layers into 16×16 chunks
- [ ] Implement mark_dirty(p) for edges/corners

#### ChunkUpdater
- [ ] Track dirty chunks on excavation/floor placement
- [ ] Trigger selective rebuilds instead of full slice redraw

#### Renderer Updates
- [ ] Maintain instancing/multi-mesh per chunk & material
- [ ] Rebuild only dirty chunks

#### Testing
- [ ] Excavate large area → FPS remains stable
- [ ] Verify only changed chunks rebuild

---

## Phase 5: Save/Load

**Goal:** Persist excavation and floor state; rebuild geometry on load.

### Tasks

#### SaveSchema
- [ ] Serialize all non-solid cells { "t": terrain, "f": floor }
- [ ] Exclude derived walls/pillars

#### Deserialize
- [ ] Rebuild LayerData from save dict
- [ ] Trigger wall/pillar recompute for all excavated cells

#### Integration
- [ ] Connect to Godot save/load system
- [ ] Add save_to_file() and load_from_file() helpers

#### Testing
- [ ] Excavate, build floors, save → quit → reload → floors/walls/pillars restored