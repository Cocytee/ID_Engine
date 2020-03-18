# ID_Engine

### ! Work in Progress !

The ID Engine, is a Julia based "realtime shading engine" for 2d graphics.

It's mainly to try Julia features into the gaming field and eventuelly provide a raw engine for thoses who want. 

Nothing serious.

## Goal

I want to recreate a 3d lighting system with 2D object.

The engine work on two features : Custom Normal Maps and Layers

The user can import a sprite with raw/bland/unshaded colors, then import the sprite's custom normal map (call ID map).

Thanks to the current sprite layer position (2D plan with fixed distance for the other object so basically a 2D plan in av 3D world), the engine could calculate the distance between the object and the lights and their 3D orientation.

The engine will influence the render so the choosen orientation ,when designing the ID map, with be reproduced on the 2D sprite.

*** That's quite complicated when you can do the same with normal maps and any game engine but that's for the fun of making something on my own ***

## Status
- "Julia Structures" for Lights , Objects and Layers
- Mutliples methods for solo and global actions
- Render function that process the scene
> Render function does not work
> Cannot decide between polar and cartesian coordinates
