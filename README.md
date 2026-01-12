# BoatsForGodot
The goal is to implement the required resources to implement boats into Godot.
So far, the basic concept seems to work.

## Requirements
- Easy Charts: https://godotengine.org/asset-library/asset/643

## Use
### Setup
- Add this repository to your Godot project folder

### Test scene
- In Godot, open BoatsForGodot > TestScene > MainScene.tscn
- Press F6 to test it
  - You can move the mouse to scroll wheel to move around.
  - You can drive the boat by using the 'Drive around' button

### Create a boat
- The up to date description should be found in the inspector

## Current implementation
### Buoyancy and drag
The core is a hull calculation script, that calculats the proper forces on any closed mesh that interacts with the water. This is done by summing up the pressure on each triangle surface.

Note: Meshes with higher triangle counts will require more performance!

Previous implementations:
- https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games
- https://www.habrador.com/tutorials/unity-boat-tutorial
- https://github.com/iffn/iffnsBoatsForVRChat/blob/main/Scripts/HullCalculator.cs

### Water level
You can create your own water level and assign it to the boats by deriving from the WaterLevelProvider class. 

### Inertia
A script was added, that is able to calculate the proper inertia based on the shape of a CollisionShape3D. Note: The script assumes that the box is centered around the center of gravity.

### Input system
The repository also includes a script that assigns the controls in the `_ready()` function. They are therefore not saved to the project.