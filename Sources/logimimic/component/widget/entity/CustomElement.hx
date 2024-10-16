package logimimic.component.widget.entity;

import crovown.component.Component;
import logimimic.component.element.Socket;
import logimimic.solver.BinarySolver;
import logimimic.solver.ISolver;
import crovown.Crovown;

using logimimic.component.element.Socket;

using Lambda;

@:build(crovown.Macro.component())
class CustomElement extends ElementEntity {
    @:p public var solver:ISolver = new BinarySolver();

    @:p public var entities:Component = null;

    var connections = new Map<Int, Int>();

    public static function build(crow:Crovown, component:CustomElement) {
        return component;
    }

    override function addLocks(solver:ISolver) {
        // buildSolver();
        // solver.addLock(solver.getInputs(), solver.getOutputs(), lock -> solver.step(), "custom", true);

        // @todo передача значений сокетов solver'а в сокеты этого компонента
        // var sockets:Array<Socket> = sockets.getChildren();
        // solver.addLock(sockets.filter(s -> s.isInput), sockets.filter(s -> s.isOutput), lock -> solver.step(), "custom", true);
    }

    public function updateSockets() {
        // buildSolver();
        // var inputs = solver.getInputs();
        // var outputs = solver.getOutputs();
        // // socket.position, sync
    }

    // синхронизируем сокеты solver'а и сокеты элемента
    // передаём значения от solver'а и обратно
    // сериализация - id пересоздаются и теряются
    // копирование - id дублируются

    public function bake() {
        var inputs = solver.getInputs();
        var outputs = solver.getOutputs();
        // var sockets:Array<Socket> = sockets.getChildren();

        for (input in inputs) {
            if (connections.exists(input.id)) continue;
            var socket = crow.Socket(socket -> {
                socket.isInput = true;
                socket.isOutput = false;
                socket.position = Left(0);  // @todo
                socket.snap = null; // @todo
            });
            sockets.addChild(socket);
            connections.set(input.id, socket.id);
        }

        for (output in outputs) {
            if (connections.exists(output.id)) continue;
            var socket = crow.Socket(socket -> {
                socket.isInput = false;
                socket.isOutput = true;
                socket.position = Right(0);  // @todo
                socket.snap = null; // @todo
            });
            sockets.addChild(socket);
            connections.set(output.id, socket.id);
        }

        // @todo лишние
        var excess = connections.filter(id -> !inputs.exists(s -> s.id == id) && !outputs.exists(s -> s.id == id));
        for (id in excess) {
            connections.remove(id);
            sockets.removeChild(sockets.children.find(s -> s.id == id));
        }


        // for (socket in sockets) {
        //     con
        // }


        // trace("Building solver");
        solver.clear();
        
        var entities:Array<Entity> = entities.getChildren();
        for (entity in entities) {
            entity.addLocks(solver);
        }

        solver.build();
        solver.init();
        // trace("Done");
    }
}