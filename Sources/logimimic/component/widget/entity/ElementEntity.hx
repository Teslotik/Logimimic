package logimimic.component.widget.entity;

import logimimic.solver.ISolver;
import logimimic.ds.Lock;
import crovown.ds.Signal;
import crovown.algorithm.MathUtils;
import crovown.ds.Vector;
import crovown.backend.Backend.Mouse;
import crovown.ds.Assets;
import logimimic.component.element.Socket;
import crovown.backend.Backend.ColoredShader;
import crovown.component.widget.StageGui;
import crovown.component.widget.BoxWidget;
import crovown.Crovown;
import crovown.component.widget.Widget;
import crovown.component.Component;
import crovown.types.Color;
import logimimic.types.Position;

using crovown.component.widget.TextWidget;
using crovown.algorithm.Shape;
using crovown.component.widget.LayoutWidget;
using logimimic.algorithm.Serialization;
using logimimic.component.widget.entity.ElementEntity;

using Lambda;

@:build(crovown.Macro.component())
class ElementEntity extends Entity {
    public static var active:ElementEntity = null;
    // public static var onClick = new Signal<ElementEntity->Void>();
    // public static var clickRequest = new Signal<Int->Int->Array<ElementEntity>->Void>();
    // public static var collectRequest = new Signal<Array<ElementEntity>->Void>();

    @:p public var foreground:Color = Red;
    @:p public var width:Int = 2;
    @:p public var height:Int = 2;
    @:p public var name:String = "Element";
    @:p public var view:String = "E";

    @:p public var sockets:Component = null;

    // @:p public var gridX:Int = 0;
    // @:p public var gridY:Int = 0;

    var support = new Vector();
    // var support2 = new Matrix();
    // var clickSlot

    public function new() {
        super();
        entityType = Element;
        // clickRequest.subscribe(this, function(x, y, items) {
        //     switch (snap) {
        //         case Cells(x1, y1):
        //             if (x >= x1 && y >= y1 && x < x1 + width && y < y1 + height) {
        //                 items.push(this);
        //             }
        //         default:
        //     }
        // });
        
        // collectRequest.subscribe(this, function(items) {
        //     items.push(this);
        // });
    }

    public static function build(crow:Crovown, component:ElementEntity) {
        component.children = [
            crow.TextWidget(widget -> {
                widget.color = Color(component.foreground);
                widget.top = Fixed(5);
                widget.left = Fixed(5);
                widget.text = component.name;
                widget.font = Assets.font_arial;
                widget.size = 12;
                component.onName.subscribe(f -> widget.text = component.name);
            }),
            crow.LayoutWidget(widget -> {
                widget.color = Color(Transparent);
                widget.hjustify = 0;
                widget.vjustify = 0;
                widget.anchors = Fixed(5);
            }, {
                children: [
                    crow.TextWidget(widget -> {
                        widget.color = Color(component.foreground);
                        widget.anchors = Fixed(5);
                        widget.text = component.view;
                        widget.font = Assets.font_arial;
                        widget.size = 50;
                        component.onView.subscribe(t -> widget.text = t);
                        widget.onCreate = _ -> widget.size = 50;
                    })
                ]
            })
        ];

        return component;
    }
    
    override function free() {
        // clickRequest.unsubscribeBy(this);
        // collectRequest.unsubscribeBy(this);
        sockets.free();
        super.free();
    }

    override function canSelect(x:Float, y:Float) {
        return switch (snap) {
            case Cells(x1, y1): Math.floor(x + 0.5) >= x1 && Math.floor(y + 0.5) >= y1 && Math.floor(x + 0.5) < x1 + width && Math.floor(y + 0.5) < y1 + height;
            default: false;
        }
    }

    override function addLocks(solver:ISolver) {
        var sockets:Array<Socket> = sockets.getChildren();
        solver.addLock(sockets.filter(s -> s.isInput), sockets.filter(s -> s.isOutput), onExecute, "element", true);
    }

    override public function relative() {
        w = width * ViewportWidget.unit;
        h = height * ViewportWidget.unit;
    }

    override public function draw(crow:Crovown, stage:StageGui) {
        colored ??= crow.application.backend.shader(ColoredShader.label);

        super.draw(crow, stage);
        stage.buffer.pushTransform(world);
        
        // stage.buffer.pushTransform(world);
        // setupFill(stage.buffer, color);
        // stage.buffer.drawRect(-w / 2, -h / 2, w, h);
        // stage.buffer.drawRoundedRect(-w / 2, -h / 2, w, h, 6, 6, 6, 6);
        // stage.buffer.flush();

        var unit = ViewportWidget.unit;
        var scale = world.getScale();

        var sockets:Array<Socket> = sockets.getChildren();
        for (socket in sockets) {
            stage.buffer.setShader(colored);    // @todo remove
            var offset = unit / 2;
            var size = 8.0;
            var radius = 9.0;
            var x = 0.0;
            var y = 0.0;
            switch (color) {
                case Color(v): colored.setColor(v);
                case null | _: colored.setColor(colorId);
            }
            if (socket.area.isDragging) {
                var pos = world.Inverse().multVec(new Vector(socket.area.mouse.x, socket.area.mouse.y));
                var area = getArea();
                if (socket.area.mouse.x < area.left || area.isOver) {
                    x = -w / 2 - offset;
                    y = MathUtils.clamp(pos.y, -h / 2, h / 2);
                    var p:Position = Left(MathUtils.clampi(Math.floor((area.h / 2 + y) / (ViewportWidget.unit * scale.y)), 0, height - 1));
                    if (!sockets.exists(s -> s.position.equals(p))) {
                        socket.position = p;
                    }
                    stage.buffer.drawLine(x, y, -w / 2, y, size);
                } else if (socket.area.mouse.y < area.top) {
                    x = MathUtils.clamp(pos.x, -w / 2, w / 2);
                    y = -h / 2 - offset;
                    var p:Position = Top(MathUtils.clampi(Math.floor((area.w / 2 + x) / (ViewportWidget.unit * scale.x)), 0, width - 1));
                    if (!sockets.exists(s -> s.position.equals(p))) {
                        socket.position = p;
                    }
                    stage.buffer.drawLine(x, y, x, -h / 2, size);
                } else if (socket.area.mouse.x > area.right) {
                    x = w / 2 + offset;
                    y = MathUtils.clamp(pos.y, -h / 2, h / 2);
                    var p:Position = Right(MathUtils.clampi(Math.floor((area.h / 2 + y) / (ViewportWidget.unit * scale.y)), 0, height - 1));
                    if (!sockets.exists(s -> s.position.equals(p))) {
                        socket.position = p;
                    }
                    stage.buffer.drawLine(x, y, w / 2, y, size);
                } else if (socket.area.mouse.y > area.bottom) {
                    x = MathUtils.clamp(pos.x, -w / 2, w / 2);
                    y = h / 2 + offset;
                    var p:Position = Bottom(MathUtils.clampi(Math.floor((area.w / 2 + x) / (ViewportWidget.unit * scale.x)), 0, width - 1));
                    if (!sockets.exists(s -> s.position.equals(p))) {
                        socket.position = p;
                    }
                    stage.buffer.drawLine(x, y, x, h / 2, size);
                }
            } else {
                switch (socket.position) {
                    case Left(v):
                        x = -w / 2 - offset;
                        y = -h / 2 + offset + unit * v;
                        stage.buffer.drawLine(x, y, 0, y, size);
                    case Top(v):
                        x = -w / 2 + offset + unit * v;
                        y = -h / 2 - offset;
                        stage.buffer.drawLine(x, y, x, 0, size);
                    case Right(v):
                        x = w / 2 + offset;
                        y = -h / 2 + offset + unit * v;
                        stage.buffer.drawLine(x, y, 0, y, size);
                    case Bottom(v):
                        x = -w / 2 + offset + unit * v;
                        y = h / 2 + offset;
                        stage.buffer.drawLine(x, y, x, 0, size);
                }
            }
            // /*
            stage.buffer.drawCircle(x, y, radius, radius);
            stage.buffer.flush();
            // stage.buffer.setColor()  // @todo оптимизация - уменьшение количества draw call
            if (socket.isInput) {
                colored.setColor(foreground);
                stage.buffer.drawCircle(x, y, radius - 4, radius - 4);
                stage.buffer.flush();
            }
            // */

            world.multVec(support.set(x, y, 0, 1));
            socket.area.set(support.x - radius * scale.x, support.y - radius * scale.y, radius * 2 * scale.x, radius * 2 * scale.y);

            socket.drawLevel(crow, stage, x, y);
        }
        
        stage.buffer.popTransform();
    }

    override function position() {
        super.position();
        var sockets:Array<Socket> = sockets.getChildren();
        var unit = ViewportWidget.unit;
        var offset = unit / 2;
        var size = 8.0;
        var radius = 9.0;
        // world.multVec(support.set(posX, posY));
        // world.multVec(support.set(-w / 2, -h / 2));
        // /*
        for (socket in sockets) {
            // socket.snap =    // @todo

            var x = 0.0, y = 0.0;

            // switch (snap) {
            //     case Grid(x, y):

            // }

            // // Relative
            // switch (socket.snap) {
            //     case Grid(x, y):
            //         socket.x = this.
            // }


            switch (snap) {
                case Cells(x, y):
                    switch (socket.position) {
                        case Left(v): socket.snap = Grid(x - 1, y + v);
                        case Top(v): socket.snap = Grid(x + v, y - 1);
                        case Right(v): socket.snap = Grid(x + width, y + v);
                        case Bottom(v): socket.snap = Grid(x + v, y + height);
                    }
                    // trace(snap, socket.snap);
                case Free(x, y):
                    // @todo
                    // case Left(v): socket.snap = Free(0, 0);
                    // case Top(v): socket.snap = Free(0, 0);
                    // case Right(v): socket.snap = Free(0, 0);
                    // case Bottom(v): socket.snap = Free(0, 0);
                default:
            }
            /*
            switch (socket.position) {
                case Left(v):
                    socket.gridX = Math.floor((posX - offset) / unit);
                    socket.gridY = Math.floor((posY + offset + unit * v) / unit);
                case Top(v):
                    socket.gridX = Math.floor((posX + offset + unit * v) / unit);
                    socket.gridY = Math.floor((posY - offset) / unit);
                case Right(v):
                    socket.gridX = Math.floor((posX + w + offset) / unit);
                    socket.gridY = Math.floor((posY + offset + unit * v) / unit);
                case Bottom(v):
                    socket.gridX = Math.floor((posX + offset + unit * v) / unit);
                    socket.gridY = Math.floor((posY + h + offset) / unit);
                case Grid: continue;
            }
            // trace(posX, posY);
            trace(gridX, gridY, socket.gridX, socket.gridY);
            */

            /*
            switch (socket.position) {
                case Left(v):
                    socket.gridX = gridX;
                    socket.gridY = gridY + v;
                case Top(v):
                    socket.gridX = gridX + v;
                    socket.gridY = gridY;
                case Right(v):
                    socket.gridX = gridX + width;
                    socket.gridY = gridY + v;
                case Bottom(v):
                    socket.gridX = gridX + v;
                    socket.gridY = gridY + height;
                case Grid: continue;
            }
            trace(socket.gridX, socket.gridY, gridX, gridY);
            */
        }
        // */
    }

    // var drag = new Vector();
    override function mouseInput(crow:Crovown, mouse:Mouse):Bool {
        if (!super.mouseInput(crow, mouse)) return false;

        var area = getArea();
        if (area.isReleased) {
            // active = this;
            // onClick.emit(slot -> slot(this));    //
        }

        var sockets:Array<Socket> = sockets.getChildren();
        for (socket in sockets) {
            socket.area.update(mouse.x, mouse.y, mouse.isLeftDown);
        }
        
        for (socket in sockets) {
            if (socket.area.isDropped) {
                // Socket.onClick.emit(slot -> slot(socket));   //
                // crow.application.delay(application -> active = null);
                continue;
            }
            if (socket.area.isReleased) {
                // onConnect.emit(slot -> slot(this, socket));
                continue;
            }
            if (!socket.area.isDragging) continue;
            // if (socket.area.isPressed) drag.set()
            // var v = switch (socket.position) {
            //     case Left(v): v;
            //     case Top(v): v;
            //     case Right(v): v;
            //     case Bottom(v): v;
            // }
            // if (mouse.x > socket.area.right) {
            //     socket.position = Right()
            // }
            // active = this;
            
            // var pos = world.Inverse().multVec(new Vector(mouse.x, mouse.y));
            // if (mouse.x < area.left) {

            // } else if (mouse.y < area.top) {

            // } else if (mouse.x > area.right) {
            
            // } else if (mouse.y > area.bottom) {

            // }
            // if (mouse.x > area.right) {
            //     socket.position = Right(Math.floor(MathUtils.clamp((area.h / 2 + pos.y) / ViewportWidget.unit, 0, height - 1)));
            // }
            // trace(pos, height);
            

            
            // if (mouse.x > area.right) {
            //     // socket.position = Right(Math.floor(world.Inverse().multVec(new Vector(mouse.x, mouse.y)).y / ViewportWidget.unit));
            //     // trace(world.MultVec(new Vector(mouse.x, mouse.y)));
            //     // trace(world.Inverse());
            //     // trace(world);
            // }
            return false;
        }

        // if (!super.mouseInput(crow, mouse)) return false;
        return true;
    }

    override function toStruct():Null<Dynamic> {
        var sockets:Array<Socket> = sockets.getChildren();
        return {
            type: getType(),
            factory: label,
            width: width,
            height: height,
            snap: snap.snap(),
            name: name,
            view: view,
            sockets: [for (s in sockets) s.toStruct()]
        }
    }

    // public static function fromStruct(crow:Crovown, v:Dynamic) {
        // return crow.ElementEntity(element -> {
    public static function fromStruct(crow:Crovown, element:ElementEntity, v:Dynamic) {
        var sockets:Array<Socket> = v.sockets;
            element.label = v.factory;
            element.width = v.width;
            element.height = v.height;
            element.snap = v.snap.unsnap();
            element.name = v.name;
            element.view = v.view;
            element.sockets.children = [for (s in sockets) Socket.fromStruct(crow, s)];
        // });
        return element;
    }
}