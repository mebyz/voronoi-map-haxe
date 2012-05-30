package voronoimap;

import as3.ac3core.PointCore;
import as3.as3types.TypeDefs;
import de.polygonal.math.PM_PRNG;
import voronoimap.graph.Center;
import voronoimap.graph.Edge;

using as3.ac3core.ConversionCore;
using as3.ac3core.PointCore;

class NoisyEdges {

	static public var NOISY_LINE_TRADEOFF:Number = 0.5;  // low: jagged vedge; high: jagged dedge
    
    public var path0:Array<Vector<Point>>;  // edge index -> Vector.<Point>
    public var path1:Array<Vector<Point>>;  // edge index -> Vector.<Point>

	public function new():Void {
		path0 = [];
		path1 = [];
	}
	
    // Build noisy line paths for each of the Voronoi edges. There are
    // two noisy line paths for each edge, each covering half the
    // distance: path0 is from v0 to the midpoint and path1 is from v1
    // to the midpoint. When drawing the polygons, one or the other
    // must be drawn in reverse order.
    public function buildNoisyEdges(map:Map, lava:Lava, random:PM_PRNG):Void {
      var p:Center, edge:Edge;
      for (p in map.centers) {
          for (edge in p.borders) {
              if (edge.d0.isNotNull() && edge.d1.isNotNull() && edge.v0.isNotNull() && edge.v1.isNotNull() && path0[edge.index].isNull()) {
                var f:Number = NOISY_LINE_TRADEOFF;
                var t:Point = PointCore.interpolate(edge.v0.point, edge.d0.point, f);
                var q:Point = PointCore.interpolate(edge.v0.point, edge.d1.point, f);
                var r:Point = PointCore.interpolate(edge.v1.point, edge.d0.point, f);
                var s:Point = PointCore.interpolate(edge.v1.point, edge.d1.point, f);

                var minLength:Int = 10;
                if (edge.d0.biome != edge.d1.biome) minLength = 3;
                if (edge.d0.ocean && edge.d1.ocean) minLength = 100;
                if (edge.d0.coast || edge.d1.coast) minLength = 1;
				if (edge.river.booleanFromInt() || lava.lava[edge.index].isNotNull()) minLength = 1;
				path0[edge.index] = buildNoisyLineSegments(random, edge.v0.point, t, edge.midpoint, q, minLength);
                path1[edge.index] = buildNoisyLineSegments(random, edge.v1.point, s, edge.midpoint, r, minLength);
              }
            }
        }
    }
	
    // Helper function: build a single noisy line in a quadrilateral A-B-C-D,
    // and store the output points in a Vector.
    static public function buildNoisyLineSegments(random:PM_PRNG, A:Point, B:Point, C:Point, D:Point, minLength:Number):Vector<Point> {
      var points:Vector<Point> = new Vector<Point>();
		
	  var limit = 10;
	  
      function subdivide(A:Point, B:Point, C:Point, D:Point):Void {
        if (A.subtract(C).distanceFromOrigin() < minLength || B.subtract(D).distanceFromOrigin() < minLength) {
          return;
        }

        // Subdivide the quadrilateral
        var p:Number = random.nextDoubleRange(0.2, 0.8);  // vertical (along A-D and B-C)
        var q:Number = random.nextDoubleRange(0.2, 0.8);  // horizontal (along A-B and D-C)

        // Midpoints
        var E:Point = PointCore.interpolate(A, D, p);
        
		var F:Point = PointCore.interpolate(B, C, p);
        var G:Point = PointCore.interpolate(A, B, q);
        var I:Point = PointCore.interpolate(D, C, q);
        
        // Central point
        var H:Point = PointCore.interpolate(E, F, q);
		
        // Divide the quad into subquads, but meet at H
        var s:Number = 1.0 - random.nextDoubleRange(-0.4, 0.4);
        var t:Number = 1.0 - random.nextDoubleRange(-0.4, 0.4);
		
		//if(limit-- > 0) {trace([p, q, s, t]);}
		
		
        subdivide(A, PointCore.interpolate(G, B, s), H, PointCore.interpolate(E, D, t));
        points.push(H);
        subdivide(H, PointCore.interpolate(F, C, s), C, PointCore.interpolate(I, D, t));
      }

      points.push(A);
      subdivide(A, B, C, D);
      points.push(C);
      return points;
    }	
	
}