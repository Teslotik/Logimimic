package logimimic.component.factory;

import crovown.Crovown;
import crovown.component.widget.LayoutWidget;
import crovown.component.Component;

class ToolFactory extends Component {
    @:p public var name:String = "";
    @:p public var onExecute:ToolFactory->Component = null;

    public static function build(crow:Crovown, component:ToolFactory) {
        return component;
    }
}