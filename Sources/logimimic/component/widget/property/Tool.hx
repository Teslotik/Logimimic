package logimimic.component.widget.property;

import crovown.backend.Backend.Mouse;
import crovown.Crovown;
import crovown.component.widget.LayoutWidget;
import crovown.ds.Assets;
import crovown.types.Fill;

using crovown.component.widget.Widget;
using crovown.component.widget.TextWidget;

@:build(crovown.Macro.component())
class Tool extends LayoutWidget {
    @:p public var icon:Fill = null;
    @:p public var text:String = "Tool";
    @:p public var onClick:Tool->Void = null;

    // public function new() {
    //     super();
    //     label = "button";
    // }

    public static function build(crow:Crovown, component:Tool) {
        // component.children = [
        //     crow.Widget(widget -> {
        //         widget.color = component.icon;
        //     }, {
        //         label: "icon"
        //     }),
        //     crow.TextWidget(text -> {
        //         // text.color = Color(foreground);
        //         text.font = Assets.font_arial;
        //         text.text = component.text;
        //         text.onCreate = _ -> {
        //             component.onText.subscribe(t -> text.text = t);
        //         }
        //     }, {
        //         label: "tool-text"
        //     })
        // ];
        
        // @todo implement using isEnabled

        if (component.icon != null) {
            component.addChild(crow.Widget(widget -> {
                widget.color = component.icon;
            }, {
                label: "icon"
            }));
        }

        if (component.text != null) {
            component.addChild(crow.TextWidget(text -> {
                // text.color = Color(foreground);
                text.font = Assets.font_arial;
                text.text = component.text;
                text.onCreate = _ -> {
                    component.onText.subscribe(t -> text.text = t);
                }
            }, {
                label: "tool-text"
            }));
        }

        return component;
    }

    override function mouseInput(crow:Crovown, mouse:Mouse):Bool {
        if (!super.mouseInput(crow, mouse)) return false;
        var area = getArea();
        if (area.isReleased && onClick != null) onClick(this);
        return !area.isOver;
    }
}