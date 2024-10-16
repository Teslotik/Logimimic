package logimimic.component.widget.property;

import crovown.backend.Backend.Mouse;
import crovown.Crovown;
import crovown.component.widget.LayoutWidget;
import crovown.ds.Assets;

using crovown.component.widget.TextWidget;

@:build(crovown.Macro.component())
class Button extends LayoutWidget {
    @:p public var text:String = "Button";
    @:p public var onClick:Button->Void = null;

    // public function new() {
    //     super();
    //     label = "button";
    // }

    public static function build(crow:Crovown, component:Button) {
        component.children = [
            crow.TextWidget(text -> {
                // text.color = Color(foreground);
                text.font = Assets.font_arial;
                text.text = component.text;
                text.onCreate = _ -> {
                    component.onText.subscribe(t -> text.text = t);
                }
            }, {
                label: "button-text"
            })
        ];
        return component;
    }

    override function mouseInput(crow:Crovown, mouse:Mouse):Bool {
        if (!super.mouseInput(crow, mouse)) return false;
        var area = getArea();
        if (area.isReleased && onClick != null) onClick(this);
        return !area.isOver;
    }
}