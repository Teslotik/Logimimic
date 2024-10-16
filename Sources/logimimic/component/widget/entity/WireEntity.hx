package logimimic.component.widget.entity;

import logimimic.solver.ISolver;
import crovown.ds.Area;
import crovown.ds.Vector;
import crovown.component.widget.StageGui;
import crovown.component.widget.Widget;
import crovown.Crovown;
import crovown.component.Component;
import logimimic.component.element.Socket;
import crovown.backend.Backend.ColoredShader;
import crovown.ds.Signal;
import crovown.algorithm.MathUtils;
import logimimic.component.widget.ViewportWidget;
import logimimic.ds.Lock;
import logimimic.types.Snap;

using crovown.component.Component;
using logimimic.algorithm.Serialization;
using logimimic.component.widget.entity.WireEntity;

using Lambda;

@:build(crovown.Macro.component())
class WireEntity extends Entity {
    public static var active:WireEntity = null;
    // public static var clickRequest = new Signal<Int->Int->Array<WireEntity>->Void>();
    // public static var clickRequest = new Signal<Snap->Snap->Array<WireEntity>->Void>();
    // public static var clickRequest = new Signal<Float->Float->Array<WireEntity>->Void>();
    // public static var collectRequest = new Signal<Array<WireEntity>->Void>();

    @:p public var sockets:Component = null;
    @:p public var thickness:Float = 8.0;

    var support1 = new Vector();
    var support2 = new Vector();
    
    public function new() {
        super();
        entityType = Wire;
        // clickRequest.subscribe(this, function(x, y, items) {
        //     if (getSegment(x, y) != null) items.push(this);
        // });
        // clickRequest.subscribe(this, function(free, items) {
        //     switch (free) {
        //         case Free(x, y):
        //             if (getSegment(x, y) != null) items.push(this);
        //         default:
        //     }
        // });

        isHideable = false;
        // isSolid = false;

        // collectRequest.subscribe(this, function(items) {
        //     items.push(this);
        // });
    }

    public static function build(crow:Crovown, component:WireEntity) {
        return component;
    }

    override public function free() {
        // clickRequest.unsubscribeBy(this);
        // collectRequest.unsubscribeBy(this);
        sockets.free();
        super.free();
    }

    override function canSelect(x:Float, y:Float) {
        return getSegment(x, y) != null;
    }

    override function addLocks(solver:ISolver) {
        var sockets:Array<Socket> = sockets.getChildren();
        solver.addLock(sockets, sockets, onExecute, "wire", false);
    }

    override function draw(crow:Crovown, stage:StageGui) {
        colored ??= crow.application.backend.shader(ColoredShader.label);

        stage.buffer.pushTransform(world);
        
        setupFill(stage.buffer, color);
        
        var scale = world.getScale();
        var sockets:Array<Socket> = sockets.getChildren();
        scale.ones();
        for (i in 1...sockets.length) {
            var prev = sockets[i - 1];
            var socket = sockets[i];

            var unit = ViewportWidget.unit;
            switch (prev.snap) {
                case Grid(x, y): support1.set((x * unit) * scale.x, (y * unit) * scale.y);
                default:
            }

            switch (socket.snap) {
                case Grid(x, y): support2.set((x * unit) * scale.x, (y * unit) * scale.y);
                default:
            }

            



            // @todo
            // switch (prev.position) {
            //     case Grid: support1.set(prev.gridX, prev.gridY);
            //     default: continue;
            // }

            // switch (socket.position) {
            //     case Grid: support2.set(socket.gridX, socket.gridY);
            //     default: continue;
            // }

            // support1.multVal(ViewportWidget.unit + ViewportWidget.unit / 2).multVec(scale);
            // support2.multVal(ViewportWidget.unit + ViewportWidget.unit / 2).multVec(scale);
            // support1.multVal(ViewportWidget.unit).multVec(scale);
            // support2.multVal(ViewportWidget.unit).multVec(scale);
            
            //
            // support1.multVal(ViewportWidget.unit).addVal(ViewportWidget.unit / 2, ViewportWidget.unit / 2).multVec(scale);
            // support2.multVal(ViewportWidget.unit).addVal(ViewportWidget.unit / 2, ViewportWidget.unit / 2).multVec(scale);
            // trace(support1, support2);
            stage.buffer.drawLine(
                support1.x, support1.y,
                support2.x, support2.y,
                thickness
            );

        }
        stage.buffer.flush();
        
        stage.buffer.popTransform();
    }

    // @todo
    // override function getAABB():Area {
    //     var sockets:Array<Socket> = getChildren();
    //     // for (socket in sockets) {

    //     // }

    //     var sx = sockets.fold((i, r) -> i.x)
    //     return super.getAABB();
    // }

    override function toStruct():Null<Dynamic> {
        return {
            type: getType(),
            factory: label,
            snap: snap.snap(),
            sockets: [for (s in sockets.children) s.toStruct()],
            thickness: thickness
        }
    }

    public static function fromStruct(crow:Crovown, wire:WireEntity, v:Dynamic) {
        wire.label = v.factory;
        wire.snap = v.snap.unsnap();
        var sockets:Array<Socket> = v.sockets;
        wire.sockets = crow.Component({
            children: [for (s in sockets) Socket.fromStruct(crow, s)]
        });
        wire.thickness = v.thickness;
        return wire;
    }

    public function getSegment(x:Float, y:Float, epsilon = 0.01) {
        var sockets:Array<Socket> = sockets.getChildren();
        if (sockets.length < 2) return null;
        var last = sockets[0];
        for (i in 1...sockets.length) {
            var socket = sockets[i];
            switch [last.snap, socket.snap] {
                case [Grid(x1, y1), Grid(x2, y2)]:
                    if (MathUtils.isOnSegment(x, y, x1, y1, x2, y2, epsilon)) {
                        return i - 1;
                    }
                default:
            }
            last = socket;
        }
        return null;
    }
}