package logimimic.component.element;

import logimimic.types.Snap;
import logimimic.component.widget.entity.Entity;
import crovown.Crovown;
import crovown.component.Component;
import logimimic.solver.BinarySolver;
import logimimic.solver.ISolver;

using Lambda;

@:build(crovown.Macro.component())
class SimulationZone extends Component {
    @:p public var solver:ISolver = new BinarySolver();

    public static function build(crow:Crovown, component:SimulationZone) {
        return component;
    }

    public function buildSolver(entities:Array<Entity>) {
        // trace("Building solver");
        solver.clear();
        
        for (entity in entities) {
            entity.addLocks(solver);
        }

        solver.build();
        solver.init();
        // trace("Done");
    }
}