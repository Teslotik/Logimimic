package logimimic.component.element;

import crovown.ds.Assets;
import crovown.backend.Backend.SdfShader;
import crovown.component.widget.StageGui;
import logimimic.component.widget.ViewportWidget;
import crovown.ds.Area;
import crovown.Crovown;
import crovown.component.Component;
import logimimic.types.Position;
import crovown.ds.Signal;
import logimimic.types.Snap;
import crovown.backend.Backend.Surface;
import crovown.backend.Backend.Font;

using logimimic.algorithm.Serialization;
using logimimic.component.element.Socket;

@:allow(logimimic.solver.BinarySolver)
@:build(crovown.Macro.component())
class Socket extends Component {
    public static var active:Socket = null;
    // public static var clickRequest = new Signal<Int->Int->Array<Socket>->Void>();
    // public static var collectRequest = new Signal<Array<Socket>->Void>();

    
    @:p public var value:Int = 0;
    @:p public var position:Position = Right(0);
    @:p public var snap:Snap = Free(0, 0);
    // @:p public var isVisible:Bool = true;

    @:p public var isInput:Null<Bool> = null;
    @:p public var isOutput:Null<Bool> = null;

    // Solver data
    // @todo remove, not used
    // var _isInput:Null<Bool> = null;
    // var _isOutput:Null<Bool> = null;




    // public var isDirty
    // public var prev:Int = 0;
    // public var input:Int = 0;
    // public var output:Int = 0;
    // public var isResolved = false;
    public var area = new Area();

    public function new() {
        super();

        // @todo move to the build function?
        // clickRequest.subscribe(this, function(x, y, items) {
        //     switch (snap) {
        //         case Grid(x1, y1):
        //             if (x1 == x && y1 == y) {
        //                 items.push(this);
        //             }
        //         default:
        //     }
        // });

        // collectRequest.subscribe(this, function(items) {
        //     items.push(this);
        // });
    }

    public static function build(crow:Crovown, component:Socket) {
        return component;
    }

    override public function toString() {
        // return '{value: ${value}}';
        return '{snap: ${snap}, value: ${value}}';
        // return '{id: ${id}, snap: ${snap}, value: ${value}}';
        // return '{id: ${id}, snap: ${snap}, input: ${input}, output: ${output}}';
    }

    override public function free() {
        // clickRequest.unsubscribeBy(this);
        // collectRequest.unsubscribeBy(this);
        super.free();
    }

    override function toStruct():Null<Dynamic> {
        return {
            type: getType(),
            position: position.pos(),
            snap: snap.snap(),
            isInput: isInput,
            isOutput: isOutput,
            value: value
        }
    }

    public static function fromStruct(crow:Crovown, v:Dynamic) {
        return crow.Socket(socket -> {
            socket.position = v.position.unpos();
            socket.snap = v.snap.unsnap();
            socket.isInput = v.isInput;
            socket.isOutput = v.isOutput;
            socket.value = v.value;
        });
    }

    public function canSelect(x:Float, y:Float) {
        return switch (snap) {
            case Grid(x1, y1): Math.floor(x + 0.5) == x1 && Math.floor(y + 0.5) == y1;
            default: false;
        }
    }
    
    public var shader:SdfShader = null;
    public var texture:Surface = null;
    public var font:Font = null;
    // public var x = 0.0;
    // public var y = 0.0;
    public function drawLevel(crow:Crovown, stage:StageGui, x, y) {
        shader ??= crow.application.backend.shader(SdfShader.label);
        texture ??= crow.application.backend.loadSurface("arial2");
        font ??= Assets.font_arial;

        shader.setThreshold(0.45);
        shader.setSurface(texture);
        stage.buffer.setShader(shader);
        stage.buffer.setFont(font);
        font.setSize(16);
        stage.buffer.drawString(Std.string(value), x, y);
        stage.buffer.flush();
    }
}