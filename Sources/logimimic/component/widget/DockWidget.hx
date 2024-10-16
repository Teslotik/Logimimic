package logimimic.component.widget;

import crovown.component.FactoryComponent;
import crovown.backend.Backend.Mouse;
import crovown.component.widget.Widget;
import crovown.component.widget.LayoutWidget;
import crovown.component.Component;
import crovown.Crovown;
import crovown.component.widget.RadioProperty;

@:build(crovown.Macro.component())
class DockWidget extends LayoutWidget {
    // public var active:Widget = null;
    public var active:FactoryComponent = null;

    public static function build(crow:Crovown, component:DockWidget) {
        

        return component;
    }

    // override function mouseInput(crow:Crovown, mouse:Mouse):Bool {
    //     if (!super.mouseInput(crow, mouse)) return false;

    //     for (child in children) child.isActive = child == active;

    //     return true;
    // }
}