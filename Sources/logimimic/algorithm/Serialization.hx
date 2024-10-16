package logimimic.algorithm;

import logimimic.types.Position;
import logimimic.types.Snap;

class Serialization {
    public static function snap(v:Snap) {
        return switch (v) {
            case Grid(x, y): {
                type: "Grid",
                x: x,
                y: y
            }
            case Cells(x, y): {
                type: "Cells",
                x: x,
                y: y
            }
            case Free(x, y): {
                type: "Free",
                x: x,
                y: y
            }
        }
    }

    public static function unsnap(v:Dynamic):Snap {
        return switch (v.type) {
            case "Grid": Grid(Std.int(v.x), Std.int(v.y));
            case "Cells": Cells(Std.int(v.x), Std.int(v.y));
            case "Free": Free(v.x, v.y);
            case _: null;
        }
    }

    public static function pos(v:Position) {
        return switch (v) {
            case Left(v): {
                pos: 0,
                v: v
            }
            case Top(v): {
                pos: 1,
                v: v
            }
            case Right(v): {
                pos: 2,
                v: v
            }
            case Bottom(v): {
                pos: 3,
                v: v
            }
        }
    }

    public static function unpos(v:Dynamic):Position {
        return switch (v.pos) {
            case 0: Left(v.v);
            case 1: Top(v.v);
            case 2: Right(v.v);
            case 3: Bottom(v.v);
            case _: null;
        }
    }
}