package logimimic.component.widget.entity;

import logimimic.types.EntityType;
import logimimic.component.element.Socket;
import logimimic.solver.ISolver;
import haxe.ds.Option;
import crovown.component.widget.Widget;
import logimimic.ds.Lock;
import logimimic.types.Snap;
import crovown.Crovown;
import crovown.component.widget.BoxWidget;

class Entity extends BoxWidget {
    @:p public var snap:Snap = Free(0, 0);

    // @:p public var onInit:Entity->Void = null;
    @:p public var onExecute:Lock->Void = null;
    @:p public var onSettings:Widget->Void = null;
    @:p public var onHud:Widget->Void = null;
    // public var isSolid = true;

    public var entityType:EntityType = null;

    // public var isEntityCollectable = false;
    // public var isWireCollectable = false;

    public static function build(crow:Crovown, component:Entity) {
        return component;
    }

    public function isInside(x:Float, y:Float, w:Float, h:Float) {
        
    }
    
    public function canSelect(x:Float, y:Float) {
        return false;
    }

    public function addLocks(solver:ISolver) {
        
    }


    // public function addSockets(sockets:Array<Socket>) {
        
    // }

    // override function simplify(variable:String):Option<Dynamic> {
    //     if (variable == "snap") {

    //     }
    //     return super.simplify(variable);
    // }
}