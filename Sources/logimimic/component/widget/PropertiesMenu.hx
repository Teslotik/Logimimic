package logimimic.component.widget;

import crovown.component.widget.BoxWidget;
import crovown.Crovown;
import crovown.component.widget.Widget;

// @todo remove? - unused
@:build(crovown.Macro.component())
class PropertiesMenu extends BoxWidget {
    public static function build(crow:Crovown, component:PropertiesMenu) {
        return component;
    }

    // override function layout() {
    //     var parent:Widget = getParent();
    //     if (parent.w < parent.h) {
    //         maxW = parent.w;
    //         maxH = null;
    //     } else {
    //         maxW = parent.w;
    //         maxH = null;
    //     }
    //     super.layout();
    // }
}