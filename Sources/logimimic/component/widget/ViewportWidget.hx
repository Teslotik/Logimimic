package logimimic.component.widget;

import logimimic.component.widget.entity.Entity;
import crovown.backend.Backend.Mouse;
import crovown.ds.Signal;
import crovown.ds.Area;
import crovown.ds.Vector;
import logimimic.shader.GridShader;
import crovown.backend.Backend.GradientShader;
import crovown.backend.Backend.ColoredShader;
import crovown.ds.Matrix;
import crovown.component.widget.StageGui;
import crovown.component.widget.Widget;
import crovown.Crovown;
import logimimic.component.element.Socket;
import logimimic.types.Snap;

@:build(crovown.Macro.component())
class ViewportWidget extends Widget {
    public static var unit = 60;
    public static var onClick = new Signal<ViewportWidget->Float->Float->Void>(true);

    @:p public var gridX:Int = 0;
    @:p public var gridY:Int = 0;
    @:p public var camera = Matrix.Identity();

    @:p public var isWiring = false;    // @todo remove @:p ?
    @:p public var isSimulating = false;
    @:p public var isGrabbing = false;
    @:p public var isSelecting = false;

    public var selection:Area = null;
    public var click:Snap = null;
    public var point:Snap = null;

    // var selfTransform = Matrix.Identity();   // @todo

    var support = new Vector();
    var inverseCamera = Matrix.Identity();

    public static function build(crow:Crovown, component:ViewportWidget) {
        


        return component;
    }

    override public function draw(crow:Crovown, stage:StageGui) {
        switch (color) {
            case Shader(s):
                var shader = cast(s, GridShader);
                // shader.setCamera(camera);
                // shader.setCamera(Matrix.Orthogonal(0, crow.application.w, crow.application.h, 0, 0.1, 100).multMat(camera));
                // shader.setCamera(world.MultMat(camera.Inverse()));
                // shader.setCamera(world.MultMat(camera).Inverse());
                // shader.setCamera(world.MultMat(camera));
                // shader.setCamera(Matrix.Scale(2, 2));
                // shader.setCamera(camera.Inverse().Inverse());
                shader.setCamera(getCameraInverse());
                // var d = new Vector(w, h);
                // d = camera.Inverse().multVec(camera.Inverse().multVec(d));
                // trace(d, w, h);
                // shader.setDimensions(d.x, d.y);
                shader.setDimensions(w, h);
                // shader.start.set(x, y);
                // shader.end.set(x + w, y + h);
                shader.start.set(-w / 2, -h / 2);
                shader.end.set(w / 2, h / 2);
            case null | _:
        }
        super.draw(crow, stage);

        // if (WireWidget.active != null && Socket.active != null) {
        //     stage.buffer.drawLine()
        // }

        // selfTransform.load(world);
        world.multMat(camera);
    }

    override public function getAABB() {
        // world.load(selfTransform);
        // return super.getArea();
        aabb.set(x, y, w, h);
        return aabb;
    }

    /*
    override public function draw(crow:Crovown, stage:StageGui) {
        colored ??= crow.application.backend.shader(ColoredShader.label);
        gradient ??= crow.application.backend.shader(GradientShader.label);

        buildTransform();

        stage.buffer.pushTransform(world);
        // stage.buffer.pushTransform(camera);
        setupFill(stage.buffer, color);

        stage.buffer.drawRect(-w / 2, -h / 2, w, h);
        stage.buffer.flush();

        stage.buffer.popTransform();
        // stage.buffer.popTransform();

        world.multMat(camera);
    }
    */

    override public function position() {
        var children:Array<Entity> = getChildren();
        for (child in children) {
            // child.x = x + w / 2 + unit / 2 + child.posX ?? 0;
            // child.y = y + h / 2 + unit / 2 + child.posY ?? 0;
            
            // child.x = x + w / 2 + child.posX ?? 0;
            // child.y = y + h / 2 + child.posY ?? 0;

            //
            // child.x = x + w / 2 + Math.floor((child.posX ?? 0) / unit) * unit + unit / 2;
            // child.y = y + h / 2 + Math.floor((child.posY ?? 0) / unit) * unit + unit / 2;


            switch (child.snap) {
                case Grid(x, y):
                    child.x = this.x + w / 2 + x * unit;
                    child.y = this.y + h / 2 + y * unit;
                case Cells(x, y):
                    child.x = this.x + w / 2 + x * unit - unit / 2;
                    child.y = this.y + h / 2 + y * unit - unit / 2;
                case Free(x, y):
                    child.x = this.x + w / 2 + x;
                    child.y = this.y + h / 2 + y;
            }
            // trace(child.snap, child.x, child.y);
        }
    }

    override function mouseInput(crow:Crovown, mouse:Mouse):Bool {
        if (!super.mouseInput(crow, mouse)) return false;

        var area = getArea();
        if (area.isReleased && !area.isDropped) {
            // var pos = toGrid(mouse.x - w / 2 - x, mouse.y - h / 2 - y);
            // var pos = toGrid(mouse.x - w / 2 + x, mouse.y - h / 2 + y);
            // onClick.emit(slot -> slot(this, Std.int(pos.x), Std.int(pos.y)));    // @todo
            // onClick.emit(slot -> slot(this, Math.floor(area.mouse.x - w / 2 - area.x), Math.floor(area.mouse.y - h / 2 - area.y)));
            click = toGrid(area.mouseLocal.x, area.mouseLocal.y);
            point = toLocal(area.mouseLocal.x, area.mouseLocal.y);
            onClick.emit(slot -> slot(this, area.mouseLocal.x, area.mouseLocal.y));
        }

        return true;
    }
    
    override function toStruct():Null<Dynamic> {
        return {
            code: code,
            children: [for (c in children) c.toStruct()]
        }
    }

    public inline function getCameraInverse() {
        return inverseCamera.load(camera).inverse();
    }

    public function toGrid(x:Float, y:Float):Snap {
        getCameraInverse().multVec(support.set(x, y));
        return Grid(
            Math.floor((support.x + unit / 2) / unit),
            Math.floor((support.y + unit / 2) / unit)
        );
    }

    public function toCells(x:Float, y:Float):Snap {
        getCameraInverse().multVec(support.set(x, y));
        return Cells(
            Math.floor((support.x + unit) / unit),
            Math.floor((support.y + unit) / unit)
        );
    }

    public function toFree(x:Float, y:Float):Snap {
        getCameraInverse().multVec(support.set(x, y));
        return Free(support.x, support.y);
    }

    public function toLocal(x:Float, y:Float):Snap {
        getCameraInverse().multVec(support.set(x, y));
        return Free(support.x / unit, support.y / unit);
    }

    public function toClosest(x:Float, y:Float) {
        var grid = toGrid(x, y);
        var cells = toCells(x, y);
        var a = unsnap(grid).clone();
        var b = unsnap(cells).clone();
        getCameraInverse().multVec(support.set(x, y));
        return support.distance(a) < support.distance(b) ? grid : cells;
    }

    public function unsnap(snap:Snap) {
        return switch (snap) {
            case Grid(x, y):
                support.set(
                    x * unit,
                    y * unit
                );
            case Cells(x, y):
                // @todo not tested yet
                support.set(
                    x * unit - unit / 2,
                    y * unit - unit / 2
                );
            case Free(x, y): support.set(x, y);
        }
    }
}