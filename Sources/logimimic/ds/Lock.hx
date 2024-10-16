package logimimic.ds;

import logimimic.component.element.Socket;

// @todo почистить
typedef Lock = {
    inputs:Array<Socket>,
    outputs:Array<Socket>,
    sockets:Array<Socket>,
    op:Lock->Void,
    isResolved:Bool,
    label:String,    // @todo remove
    ?depth:Int,
    isSolid:Bool,
    wasSimplified:Bool
}