# Procedural Map Generation Algorithms

An interactive
[demo](https://klistwan.itch.io/procedural-map-generation-algorithms) of some of
the algorithms discussed in my paper on procedural map generation algorithms for
the course, COMP4121: Advanced Algorithms, at the University of New South Wales.

The demo can be accessed at <https://klistwan.itch.io/procedural-map-generation-algorithms>

## Summary

Implementation for the following algorithms is included:

- Random Dungeon Generation, using L-shaped hallway connections
- Rogue's Dungeon Generation, using two-turn hallway connections[^1]
- Cave Generation using Random Walk
- Cellular Automata with three rules (Anneal, Assimilation, and Diamoeba),
using weighted random walks[^2] for connections and contour bombing[^3] for
improving connections
- World Generation using Perlin Noise
- World Generation using Simplex Noise
- Voronoi Diagram with Random Seeds
- Voronoi Diagram with Lloyd's Algorithm for Voronoi relaxation

## Credits

- [Quale](https://imgur.com/a/uHx4k) for the tileset
- [SelinaDev](https://github.com/SelinaDev/Godot-Roguelike-Tutorial) for the
Godot Roguelike Tutorial series and implementation of various classes

## References

[^1]: <https://gamedev.stackexchange.com/a/60936>
[^2]: <https://abitawake.com/news/articles/procedural-generation-with-godot-creating-caves-with-cellular-automata>
[^3]: <https://www.darkgnosis.com/2018/03/03/contour-bombing-cave-generation-algorithm/>
