package logimimic.shader;

import crovown.ds.Matrix;
import crovown.backend.Context;
import crovown.ds.Vector;
import crovown.types.Color;
import crovown.backend.Backend.Surface;
import crovown.backend.LimeBackend.LimeSurface;
import crovown.backend.LimeBackend.AttributeStructure;
import crovown.backend.LimeBackend.LimeShader;
import lime.graphics.opengl.GLProgram;
import crovown.backend.Backend.Shader;
import lime.utils.Float32Array;

class GridShader extends Shader {
    var program:GLProgram = null;
    var spacing:Float = 10;
    var size:Float = 5;
    var color = new Vector();
    var camera = new Float32Array(16);

    public var start = new Vector();
    public var end = new Vector();

    public var dimensions = new Vector();

    public function new(context:Context) {
        program = LimeShader.createProgram(context.structure.generateVertex(), "
            const float Pi = 3.1415926;

            in vec3 pos;
            in vec4 col;
            in vec2 uv;
            in vec4 canvas;

            uniform vec4 color;
            uniform float size;
            uniform float spacing;
            uniform mat4 camera;

            uniform vec2 start;
            uniform vec2 end;
            uniform vec2 dim;

            out vec4 frag;

            float lerp(float t, float x0, float y0, float x1, float y1) {
                return y0 + (t - x0) * (y1 - y0) / (x1 - x0);
            }

            void main() {
                // float x = int(pos.x) % int(spacing) < size ? 1.0 : 0.0;
                // float y = int(pos.y) % int(spacing) < size ? 1.0 : 0.0;
                // frag = vec4(x * y) * color;

                // float y = step(0.5, sin(pos.y / 100.0));
                // frag = color;
                // frag = vec4(1);
                
                // float x = abs(sin(lerp(pos.x * (1.0 / spacing), Pi / 2.0, 0.0, Pi, 1.0)));
                // float x = step(0.9, abs(sin(pos.x * Pi / spacing)));
                // float x = abs(sin(pos.x * Pi / spacing));
                // float x = abs((int(pos.x) % int(spacing) - spacing / 2));
                // float x = abs(int(pos.x) % int(spacing));
                // float m = 1;
                // float x = m - abs(int(pos.x) % int(2*m) - m);
                // float x = int(abs(pos.x)) % int(spacing) < size ? 1.0 : 0.0;
                
                
                // // float x = 2 * abs(pos.x / p - int(pos.x / p + 0.5));
                // float x = 4.0 * a / p * abs((int(pos.x - p / 4) % int(p)) - p / 2) - a;
                

                //
                // float p = spacing;
                // float a = 2.0;
                // https://en.wikipedia.org/wiki/Triangle_wave
                // float x = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * pos.x));
                // float y = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * pos.y));

                // float x = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * canvas.x));
                // float y = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * canvas.y));
                // float x = sin(canvas.x);
                float p = spacing;
                float a = 2.0;
                // float x = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * canvas.x));

                // float pp = vec4(end.x - start.x, end.y - start.y, 0, )
                // vec4 pp = camera * vec4(uv.x, uv.y, 0, 1);
                
                // vec4 co = camera * vec4(1 / (dim.x * uv.x), 1 / (dim.y * uv.y), 0, 1);
                // vec4 co = camera * vec4(1 / ((end.x - start.x) * uv.x), 1 / ((end.y - start.y) * uv.y), 0, 1);
                
                
                // vec4 co = camera * vec4(1 / pos.x, 1 / pos.y, 0, 1);
                // float x = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * (1 / co.x)));
                // float y = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * (1 / co.y)));

                // vec4 aa = camera * vec4(uv.x, uv.y, 0, 1);
                // vec4 co = vec4((dim.x * aa.x), (dim.y * aa.y), 0, 1);

                // vec4 co = camera * vec4(uv.x * dim.x, -uv.y * dim.y, 0, 1);
                
                vec4 co = camera * vec4(pos.x, pos.y, 0, 1);
                float x = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * (co.x)));
                float y = a - 2.0 * a / Pi * acos(cos(2.0 * Pi / p * (co.y)));

                x = step(1.5, x);
                y = step(1.5, y);
                frag = vec4(color.x, color.y, color.z, color.a * x * y);
                // frag = vec4(1, 1, 1, color.a * x);
            }
        ");
        context.structure.bind(program);
    }

    override public function apply(surface:Surface) {
        var surface = cast(surface, LimeSurface);
        surface.useProgram(program);
        LimeShader.setMatrix4(program, "mvp", surface.getLimeTransform());
        LimeShader.setMatrix4(program, "camera", camera);
        LimeShader.setFloat4(program, "color", color.x, color.y, color.z, color.w);
        LimeShader.setFloat(program, "spacing", spacing);
        LimeShader.setFloat(program, "size", size);

        LimeShader.setFloat2(program, "start", start.x, start.y);
        LimeShader.setFloat2(program, "end", end.x, end.y);
        // trace(end.x - start.x, end.y - start.y, dimensions);

        LimeShader.setFloat2(program, "dim", dimensions.x, dimensions.y);

        // trace(surface.getTransform().multVec(new Vector(10, 0)));
    }

    public function setColor(v:Color) {
        color.load(crovown.types.Color.fromARGB(v));
    }
    
    public function setDimensions(w:Float, h:Float) {
        dimensions.set(w, h);
    }
    
    public function setSpacing(v:Float) {
        spacing = v;
    }

    public function setSize(v:Float) {
        size = v;
    }

    public function setCamera(v:Matrix) {
        // var v = v.Inverse();
        camera[0] = v._00;
        camera[1] = v._01;
        camera[2] = v._02;
        camera[3] = v._03;
        camera[4] = v._10;
        camera[5] = v._11;
        camera[6] = v._12;
        camera[7] = v._13;
        camera[8] = v._20;
        camera[9] = v._21;
        camera[10] = v._22;
        camera[11] = v._23;
        camera[12] = v._30;
        camera[13] = v._31;
        camera[14] = v._32;
        camera[15] = v._33;
    }
}