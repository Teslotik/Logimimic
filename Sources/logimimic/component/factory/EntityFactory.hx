package logimimic.component.factory;

import crovown.component.Component;
import crovown.Crovown;

@:build(crovown.Macro.component())
class EntityFactory extends Component {
    public static function build(crow:Crovown, component:EntityFactory) {
        return component;
    }
}