package logimimic.types;

enum Snap {
    Grid(x:Int, y:Int);
    Cells(x:Int, y:Int);
    Free(x:Float, y:Float);
}