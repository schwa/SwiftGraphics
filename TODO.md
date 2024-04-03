# TODO

- [ ]: Clean up Geometry/GeometryX/Projection/VectorSupport/LegacyGraphics etc. There should be _one_ Polygon type.
  - Should there be Geometry2D and Geometry3D libraries?
- [ ]: Clean up example projects
- [ ]: Remove Sketches
- [ ]: Accessor2D needs to be fleshed out more. Everything should be related going from N-dimensional index to 1-D index
- [ ]: Clean up all deprecated code.
- [ ]: Move all unsafe conformances
- [ ]: Get test coverage up for Support targets
- Polygon2D actions
  - Boolean algebra
  - Offset
  - Mirror
  - Linear Pattern
  - Circular Pattern
  - Transform
  - "Fill" spine
  - Extrude
  - isSimple
  - isConvex
  - isConcave
  - Equiangular: all corner angles are equal.
  - Equilateral: all edges are of the same length.
  - Regular: both equilateral and equiangular.
  - cyclic
  
- Polygon3D
  - isPlanar/isSkew
  - Flip Normals

- Pathable - one way to convert to path
- PointLike/GenericPoints/VertexLike - sort it out mate
