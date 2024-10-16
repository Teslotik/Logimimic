package logimimic.component.widget.entity;

import crovown.Crovown;

@:build(crovown.Macro.component())
class ZoneEntity extends Entity {
    public static function build(crow:Crovown, component:ZoneEntity) {
        return component;
    }
}