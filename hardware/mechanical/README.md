# Mechanical hardware

Native CAD files for the Walking Beam mechanism. All parts are 3D printed and assembled with bolts, nuts and pins.

- **CAD software:** Autodesk Fusion 360 (`.f3d`)
- **Simulation model:** [`simulation/Multibody/walking_beam.slx`](../../simulation/Multibody/walking_beam.slx), which uses `.step` files exported from the files in this folder

## Parts list

| File | Part | Qty | Color | Layer height |
|---|---|---|---|---|
| `ground_1.f3d` | Ground 1 (base frame) | 1 | Black | 0.2 mm |
| `ground_2.f3d` | Ground 2 (base frame) | 1 | Black | 0.2 mm |
| `link 2.f3d` | Link 2 (crank, input) | 1 | Blue | 0.12 mm |
| `link 3.f3d` | Link 3 | 1 | Red | 0.16 mm |
| `link 4,7.f3d` | Link 4 and Link 7 (identical geometry) | 2 | Emerald | 0.16 mm |
| `link 5.f3d` | Link 5 | 1 | Orange | 0.16 mm |
| `link 6.f3d` | Link 6 | 1 | Yellow | 0.16 mm |
| `link 8.f3d` | Link 8 (walking beam with teeth that push the specimen) | 1 | White | 0.16 mm |
| — | Specimen (the conveyed workpiece) | 1 | Light Purple | 0.2 mm |

## Material and printing

- **Material:** PETG
- **Layer height:** see the table above

## Assembly

### 1. Ground 1 and Ground 2

Fasten together with **M5 bolts and nuts**.

### 2. Revolute joints

- Every revolute joint uses a **4.6 mm diameter pin**, locked at the end with a **retaining ring diameter 4 mm**.
- The holes in the printed parts are designed with clearance at **Ø5 mm** so the pins rotate freely.
- The revolute joints in the mechanism are O2, O4, O7 (attached to ground) and A, B, C, D, E, F, G (between links), named as in the Multibody model.
- Link 2 is the driving crank (input) at joint O2.

## Additional hardware

| Item | Size | Used for |
|---|---|---|
| Bolt + nut | M5 | Fastening Ground 1 to Ground 2 |
| Retaining ring | For Ø4 mm shaft | Locking the pin ends |

