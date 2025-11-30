# BoatsForGodot
The goal is to implement the required resources to implement boats into Godot.
So far, the basic concept seems to work.

## Use
### Test scene
- Add this repository to your Godot project folder
- In Godot, open BoatsForGodot > TestScene > BuoyancyTest.tscn
- Press F6 to test it
  - Control with WASD
  - Inputs are automatically assigned when running the game, but not saved to the project


### Create a boat
- Model a closed buoyancy mesh (Limit the number of triangles for performance reasons)
- Setup a boat similar to the test boats:
    - Rigidbody base
    - Buoyancy mesh (closed, otherwise you'll get phantom forces)
    - HullCalculator script linked to the Rigidbody and Buoyancy mesh
    - InertiaCalculation if not set properly
    - Thruster if required
    - Input setter if needed

## Current implementation
### Buoyancy and drag
The core is a hull calculation script, that calculats the proper forces on any closed mesh that interacts with the water. This is done by summing up the pressure on each triangle surface.

Note: Meshes with higher triangle counts will require more performance!

Previous implementations:
- https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games
- https://www.habrador.com/tutorials/unity-boat-tutorial
- https://github.com/iffn/iffnsBoatsForVRChat/blob/main/Scripts/HullCalculator.cs

### Water level
The current version is simplified and assumes that the water height is at 0. This can be changed within the `BoatHull` script in the static `get_distance_to_water` function. (To be ipmroved)

### Inertia
A script was added, that is able to calculate the proper inertia based on the shape of a CollisionShape3D. Note: The script assumes that the box is centered around the center of gravity.

### Input system
The repository also includes a script that assigns the controls in the `_ready()` function. They are therefore not saved to the project.