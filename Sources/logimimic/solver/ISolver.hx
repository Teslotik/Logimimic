package logimimic.solver;

import logimimic.ds.Lock;
import logimimic.component.element.Socket;

interface ISolver {
    // @todo remove label
    public function addLock(inputs:Array<Socket>, outputs:Array<Socket>, op:Lock->Void, label:String, isSolid:Bool):Void;
    public function getSockets():Array<Socket>;
    public function getInputs():Array<Socket>;
    public function getOutputs():Array<Socket>;
    public function init():Void;
    public function clear():Void;
    public function build():Void;
    public function step():Void;
}