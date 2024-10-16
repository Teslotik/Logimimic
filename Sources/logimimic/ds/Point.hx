package logimimic.ds;

import logimimic.component.widget.entity.ElementEntity;
import logimimic.component.widget.entity.WireEntity;
import logimimic.component.element.Socket;
import logimimic.types.Snap;

// @todo
typedef Point = {
    grid:Snap,
    cells:Snap,
    free:Snap,
    elements:Array<ElementEntity>,
    wires:Array<WireEntity>,
    sockets:Array<Socket>,
}