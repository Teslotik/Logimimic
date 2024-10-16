package logimimic.component.widget;
// package crovown.component.widget;

// class DiamondLayout {
    
// }

// /*
import crovown.backend.Backend.GradientShader;
import crovown.backend.Backend.ColoredShader;
import crovown.component.widget.StageGui;
import crovown.Crovown;
import crovown.component.widget.Widget;
import crovown.component.widget.LayoutWidget;
import crovown.component.widget.BoxWidget;
// */

// /*
@:build(crovown.Macro.component(false))
class DiamondLayout extends LayoutWidget {

    override public function draw(crow:Crovown, stage:StageGui) {
        colored ??= crow.application.backend.shader(ColoredShader.label);
        gradient ??= crow.application.backend.shader(GradientShader.label);

        // buildTransform();
        stage.buffer.pushTransform(world);
        
        setupFill(stage.buffer, color);
        
        var w = w / 2;
        var h = h / 2;
        if (w > h) {
            var chamfer = h;
            stage.buffer.drawTri(-w + chamfer, -h, -w, 0, w, 0);
            stage.buffer.drawTri(-w + chamfer, -h, w, 0, w - chamfer, -h);
            stage.buffer.drawTri(-w + chamfer, h, -w, 0, w, 0);
            stage.buffer.drawTri(-w + chamfer, h, w, 0, w - chamfer, h);
            stage.buffer.flush();
        } else {
            var chamfer = w;
            stage.buffer.drawTri(-w, -h + chamfer, 0, -h, 0, h);
            stage.buffer.drawTri(-w, -h + chamfer, 0, h, -w, h - chamfer);
            stage.buffer.drawTri(w, -h + chamfer, 0, -h, 0, h);
            stage.buffer.drawTri(w, -h + chamfer, 0, h, w, h - chamfer);
            stage.buffer.flush();
        }
        
        stage.buffer.popTransform();
    }


    static public function build(crow:Crovown, component:DiamondLayout) {
        return component;
    }
}
// */