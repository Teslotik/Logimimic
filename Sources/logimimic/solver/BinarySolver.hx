package logimimic.solver;

import logimimic.types.Snap;
import logimimic.component.element.Socket;
import logimimic.ds.Lock;

using Lambda;

class BinarySolver implements ISolver {
    // @todo list
    public var locks = new Array<Lock>();
    public var queue = new Array<Lock>();
    public var sockets = new Array<Socket>();

    public function new() {
        
    }

    public function addLock(inputs:Array<Socket>, outputs:Array<Socket>, op:Lock->Void, label:String, isSolid:Bool) {
        var sockets = makeLock(inputs, outputs, op, label, isSolid);
        for (socket in sockets) {
            if (!this.sockets.contains(socket)) this.sockets.push(socket);
        }
    }

    public function getSockets() {
        return sockets;
    }

    public function getInputs() {
        var inputs = new Array<Socket>();
        for (lock in locks) {
            if (lock.inputs.length > 0) continue;
            if (lock.outputs.length == 0) continue;
            for (s in lock.outputs) inputs.push(s);
        }
        return inputs;
    }

    public function getOutputs() {
        var outputs = new Array<Socket>();
        for (lock in locks) {
            if (lock.inputs.length == 0) continue;
            if (lock.outputs.length > 0) continue;
            for (s in lock.inputs) outputs.push(s);
        }
        return outputs;
    }

    function makeLock(inputs:Array<Socket>, outputs:Array<Socket>, op:Lock->Void, label:String, isSolid:Bool) {
        var sockets = inputs.copy();
        for (s in outputs) if (!sockets.contains(s)) sockets.push(s);
        locks.push({
            inputs: inputs,
            outputs: outputs,
            sockets: sockets,
            op: op,
            isResolved: false,
            label: label,
            isSolid: isSolid,
            wasSimplified: false
        });
        return sockets;
    }

    public function clear() {
        locks.resize(0);
        queue.resize(0);
        sockets.resize(0);
    }

    public function build() {
        // PHASE 0 - Grouping sockets

        // Searching for a sockets at the same spot and connecting them
        var neighbors = new Map<Snap, Array<Socket>>();
        // Group
        for (socket in sockets) {
            var n = neighbors.get(socket.snap);
            if (n == null) {
                neighbors.set(socket.snap, n = new Array<Socket>());
            }
            n.push(socket);
        }
        // Connect
        for (n in neighbors) {
            if (n.length > 1) {
                makeLock(n, n, lock -> {
                    var isActive = lock.inputs.exists(s -> s.value != 0);
                    for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                }, "spot", false);
            }
        }
        
        // PHASE 1 - simplification

        var simplified = new Array<Lock>();
        for (lock in locks) {
            if (lock.wasSimplified) continue;

            // Lock sockets
            var group = new List<Socket>();

            // The goal is to recursively collect all linked sockets and
            // remain only determinated (which isInput or isOutput is not null)
            // We must do this because otherwise it is not possibly to correctly
            // propagate values and restore sockets state at the next cycle
            // for wires with multiple input and output connections
            function simplify(lock:Lock) {
                lock.wasSimplified = true;
                for (socket in lock.sockets) {
                    if (socket.isInput != null || socket.isOutput != null) continue;
                    for (l in locks) {
                        if (l == lock) continue;
                        if (l.wasSimplified) continue;
                        if (!l.sockets.exists(s -> s.snap.equals(socket.snap))) continue;
                        
                        if (l.isSolid) {
                            // We are adding only sockets at the same spot for solid locks
                            for (s in l.sockets) {
                                if (s.snap.equals(socket.snap) && !group.has(s)) group.add(s);
                            }
                        } else {
                            // For non-solid locks all sockets will be added
                            for (s in l.sockets) {
                                if (!group.has(s)) group.add(s);
                            }
                            simplify(l);
                        }
                    }
                }
            }
            if (!lock.isSolid) {
                for (s in lock.sockets) group.add(s);
                simplify(lock);
            }

            if (lock.isSolid) {
                simplified.push(lock);
            } else {
                var group = group.filter(s -> s.isInput != null || s.isOutput != null).array();
                simplified.push({
                    inputs: group.filter(s -> s.isOutput).array(),
                    outputs: group.filter(s -> s.isInput).array(),
                    sockets: group,
                    // op: lock -> {
                    //     var isActive = lock.inputs.exists(s -> s.value != 0);
                    //     for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                    // },
                    op: lock.op,
                    isResolved: false,
                    label: "simplified",
                    isSolid: true,
                    wasSimplified: true
                });
            }

        }

        // PHASE 2 - propagating depth

        // We need to propagate depth from inputs and unconnected sockets
        // to correctly resolve cycles
        // The lower depth the higher priority to make lock is next
        var inputs = simplified.filter(lock -> lock.inputs.length == 0 || lock.inputs.exists(s -> !simplified.exists(l -> l.outputs.contains(s))));
        function propagate(lock:Lock, depth = 0) {
            lock.depth = depth;
            for (socket in lock.sockets) {
                for (l in simplified) {
                    if (l == lock) continue;
                    if ((l.depth == null || l.depth > depth) && l.sockets.contains(socket)) {
                        propagate(l, depth + 1);
                    }
                }
            }
        }
        for (lock in inputs) propagate(lock);
        for (lock in locks) {
            if (lock.depth == null) lock.depth = 0;
        }

        // PHASE 3 - resolution

        function next() {
            for (lock in simplified) {
                if (lock.isResolved) continue;

                // If all inputs are resolved then return a lock
                if (lock.inputs.foreach(s -> simplified.foreach(l -> !l.outputs.contains(s) || l.isResolved || l == lock))) {
                    return lock;
                }
            }
            // If cycle then return lock with lower depth
            return simplified.fold((i, r) -> (r == null || i.depth < r.depth) && !i.isResolved ? i : r, null);
        }

        while (true) {
            var lock = next();
            if (lock == null) break;
            queue.push(lock);
            lock.isResolved = true;
        }

        // trace(queue);
        // for (item in queue) trace(item, "\n");
    }

    public function init() {
        for (lock in queue) {
            lock.sockets.iter(s -> if (!queue.exists(l -> l != lock && l.sockets.contains(s))) s.value = 0);
            // lock.sockets.iter(s -> if (!queue.exists(l -> l != lock && l.sockets.exists(socket -> s.snap.equals(s.snap)))) s.value = 0);
        }
    }

    public function step() {
        for (i in 0...queue.length) {
            var lock = queue[i];
            if (lock.op != null) lock.op(lock);
        }
    }
}