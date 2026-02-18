# BoatsForGodot
The goal is to implement the required resources to implement boats into Godot.
So far, the basic concept seems to work.

Web demo: https://iffn.itch.io/boatsforgodot?secret=jzp0cNoIxExIhayPwXS5mqKk0NY

## Requirements
- Easy Charts: https://godotengine.org/asset-library/asset/643
- Debug Draw 3D https://godotengine.org/asset-library/asset/1766

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
### GLB import and export
- .glb files can be directly dragged into the running application to load them. A save system either saves or 'downloads' them when running inside a browser.
- Currently uses extras to transfer metadata like thrust to keep it compatible during Blender import end export.

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
