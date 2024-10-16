package logimimic.plugin;

import logimimic.types.EntityType;
import crovown.ds.Area;
import logimimic.types.Icons;
import haxe.Json;
import logimimic.component.widget.entity.Entity;
import crovown.ds.Vector;
import crovown.backend.Context;
import logimimic.shader.GridShader;
import crovown.types.Gap;
import crovown.types.Resizing;
import crovown.types.Anchor;
import crovown.types.BorderRadius;
import crovown.types.Fill;
import crovown.ds.Assets;
import crovown.algorithm.Easing;
import crovown.algorithm.MathUtils;
import crovown.ds.Matrix;
import crovown.Crovown;
import crovown.plugin.Plugin;
import crovown.backend.Backend.ColoredShader;
import logimimic.solver.BinarySolver;
import logimimic.types.Snap;
import crovown.Storage.UserStorage;

using crovown.component.Component;
using crovown.component.RegistryComponent;
using crovown.component.animation.Animation;
using crovown.component.animation.Animation;
using crovown.component.animation.SequenceAnimation;
using crovown.component.filter.AdjustColorFilter;
using crovown.component.filter.Filter;
using crovown.component.filter.SequenceFilter;
using crovown.component.network.Network;
using crovown.component.widget.BoxWidget;
using crovown.component.widget.LayoutWidget;
using crovown.component.widget.StageGui;
using crovown.component.widget.TextWidget;
using crovown.component.widget.Widget;
using crovown.component.widget.SpacerWidget;
using crovown.component.widget.SplitWidget;
using crovown.component.widget.AspectWidget;
using crovown.component.widget.RadioProperty;
using logimimic.component.widget.DiamondLayout;
using logimimic.component.widget.entity.ElementEntity;
using logimimic.component.element.Socket;
using crovown.component.OperationComponent;
using crovown.component.FactoryComponent;
using logimimic.component.widget.ViewportWidget;
using logimimic.component.widget.DockWidget;
using logimimic.component.widget.entity.WireEntity;
using logimimic.component.ContextComponent;
using logimimic.component.widget.property.Button;
// using logimimic.component.widget.factory.Tool;
using logimimic.component.widget.property.Tool;
using crovown.algorithm.Shape;

using Lambda;

typedef Theme = {
    background:Int,
    foreground:Int,
    ghost:Int,
    accent:Int,
    alert:Int,
    spacing:Int,
    padding:Int,
    insets:Int,
    header:Int,
    radius:Int,
    title:Int,
    icon:Int,
    size:Int
}


@:build(crovown.Macro.plugin(true))
class LogimimicPlugin extends Plugin {
    public var tree:Component = null;
    public var binarySolver = new BinarySolver();
    public var storage = new UserStorage();
    public var filename = "save";
    public var clipboard:Dynamic = {};
    public var theme:Theme = null;

    
    public function showSettings(builder:Widget->Void) {
        var settings:Widget = tree.get("settings");
        settings.parent.isEnabled = true;
        hideHud();

        settings.addChild(crow.TextWidget(text -> {
            text.text = "Settings";
            text.size = 24;
        }));
        
        builder(settings);
        
        settings.addChild(crow.Button(button -> {
            button.text = "Close";
            button.onClick = button -> {
                hideSettings();
            }
        }, {
            label: "button"
        }));
    }

    public function hideSettings() {
        var settings:Widget = tree.get("settings");
        settings.removeChildren();
        settings.parent.isEnabled = false;
    }

    public function showHud(builder:Widget->Void) {
        var hud:Widget = tree.get("hud");

        if (hud.parent.isEnabled) hideHud();
        hud.parent.isEnabled = true;
        
        builder(hud);
    }

    public function hideHud() {
        var hud:Widget = tree.get("hud");
        hud.removeChildren();
        hud.parent.isEnabled = false;
    }

    /*
    public function buildSolver() {
        // trace("Building solver");
        binarySolver.clear();
        
        var elements = new Array<ElementEntity>();
        ElementEntity.collectRequest.emit(slot -> slot(elements));
        for (element in elements) {
            var sockets:Array<Socket> = element.sockets.getChildren();
            binarySolver.addLock(sockets.filter(s -> s.isInput), sockets.filter(s -> s.isOutput), element.onExecute, "element", true);
        }

        var wires = new Array<WireEntity>();
        WireEntity.collectRequest.emit(slot -> slot(wires));
        for (wire in wires) {
            var sockets:Array<Socket> = wire.sockets.getChildren();
            binarySolver.addLock(sockets, sockets, wire.onExecute, "wire", false);
        }

        // Searching for sockets at the same spot and connecting them
        // Collect
        var sockets = new Array<Socket>();
        Socket.collectRequest.emit(slot -> slot(sockets));
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
                binarySolver.addLock(n, n, lock -> {
                    var isActive = lock.inputs.exists(s -> s.value != 0);
                    for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                }, "spot", false);
            }
        }

        binarySolver.build();
        binarySolver.init();
        // trace("Done");
    }
    */

    public function buildSolver() {
        var viewport:ViewportWidget = tree.get("window/viewport");
        var entities:Array<Entity> = viewport.getChildren();
        // trace("Building solver");
        binarySolver.clear();
        
        for (entity in entities) {
            entity.addLocks(binarySolver);
        }

        binarySolver.build();
        binarySolver.init();
        // trace("Done");
    }
    
    public function updateSaves() {
        var widget:Widget = tree.get("app/saves");
        widget.removeChildren();
        for (entry in storage.entries()) {
            var entry = entry;
            widget.addChild(crow.TextWidget(text -> {
                text.text = entry;
                text.onMouseInput = (widget, mouse) -> {
                    var area = widget.getArea();
                    if (area.isReleased) {
                        trace("loading", entry);
                        filename = text.text;
                        var viewport:ViewportWidget = tree.get("window/viewport");
                        viewport.removeChildren();
                        var save = Json.parse(storage.read(entry));
                        var data:Array<Dynamic> = save.data;
                        var itemRegistry:RegistryComponent = tree.get("registry/item");
                        for (item in data) {
                            if (item.type == ElementEntity.type) {
                                var factory = cast(itemRegistry.emit(item.factory), FactoryComponent);
                                ElementEntity.fromStruct(crow, cast factory.execute(crow), item);
                            } else if (item.type == WireEntity.type) {
                                var q = null;
                                // @todo фабрика проводов
                                var factory:FactoryComponent = tree.get(item.factory);
                                viewport.addChild(WireEntity.fromStruct(crow, cast factory.execute(crow), item));
                            } else if (item.type == Socket.type) {
                                trace("Not supported");
                            }
                        }
                        crow.application.delay(app -> buildSolver());
                    }
                    return true;
                }
            }));
        }
    }

    public function deserialize(entry:Dynamic, selection = true) {
        var viewport:ViewportWidget = tree.get("window/viewport");
        if (selection) {
            for (c in viewport.children) c.isActive = false;
        }
        var data:Array<Dynamic> = entry.data;
        var itemRegistry:RegistryComponent = tree.get("registry/item");
        for (item in data) {
            var entity:Entity = null;
            if (item.type == ElementEntity.type) {
                var factory = cast(itemRegistry.emit(item.factory), FactoryComponent);
                entity = ElementEntity.fromStruct(crow, cast factory.execute(crow), item);
            } else if (item.type == WireEntity.type) {
                var q = null;
                // @todo фабрика проводов
                var factory:FactoryComponent = tree.get(item.factory);
                viewport.addChild(entity = WireEntity.fromStruct(crow, cast factory.execute(crow), item));
            } else if (item.type == Socket.type) {
                trace("Not supported");
                continue;
            }
            if (selection) entity.isActive = true;
        }
    }

    public function serialize(items:Array<Entity>) {
        var content = [for (c in items) c.toStruct()];
        return {data: content};
    }

    public function generateFilename() {
        var date = Date.now();
        return 'save_${date.getFullYear()}-${date.getMonth()}-${date.getDay()}_${date.getHours()}-${date.getMinutes()}-${date.getSeconds()}';
    }

    public function optimize(viewport:Widget) {
        var entities:Array<Entity> = viewport.getChildren();
        for (entity in entities) {
            if (entity.getType() == WireEntity.type) {
                var wire = cast(entity, WireEntity);
                var sockets:Array<Socket> = wire.sockets.getChildren();
                var snap = sockets[0].snap;
                if (!sockets.foreach(s -> s.snap.equals(snap))) continue;
                crow.application.delay(app -> wire.free());
            }
        }
    }

    override function onEnable(crow:Crovown) {
        filename = generateFilename();

        var desktop:Theme = {
            background: 0xFF000000,
            foreground: 0xFFC8C8C8,
            ghost: 0x40C8C8C8,
            accent: 0xFFA0B72F,
            alert: 0xFFDB0B0B,
            
            spacing: 16,
            padding: 16,
            insets: 12,
            header: 40,
            radius: 6,
            
            title: 24,
            icon: 24,
            size: 16,
        }

        var mobile:Theme = {
            background: 0xFF000000,
            foreground: 0xFFC8C8C8,
            ghost: 0x40C8C8C8,
            accent: 0xFFA0B72F,
            alert: 0xFFDB0B0B,
            
            spacing: 16,
            padding: 16,
            insets: 12,
            header: 40,
            radius: 6,
            
            title: 24,
            icon: 24,
            size: 16,
        }

        if (crow.application.isMobile) {
            var scale = 1.5;
            mobile.spacing = Std.int(desktop.spacing * scale);
            mobile.padding = Std.int(desktop.padding * scale);
            mobile.insets = Std.int(desktop.insets * scale);
            mobile.header = Std.int(desktop.header * scale);
            mobile.radius = Std.int(desktop.radius * scale);
            mobile.title = Std.int(desktop.title * scale);
            mobile.icon = Std.int(desktop.icon * scale);
            mobile.size = Std.int(desktop.size * scale);
            theme = mobile;
        } else {
            theme = desktop;
        }

        Assets.font_arial.setSize(18);


        // var regular = window.backend.font("InterBold", 18);
        // var selection = window.backend.font("InterBold", 18);
        // var info = window.backend.font("InterBold", 102);
        // var title = window.backend.font("InterRegular", 14);
        // var designation = window.backend.font("InterRegular", 56);

        // var github = window.backend.image("github");
        // var discord = window.backend.image("discord");

        crow.rule(component -> {
            if (component.getType() != "TextWidget") return;
            var text = cast(component, TextWidget);
            text.color = Color(theme.foreground);
            text.font = Assets.font_arial;
            text.size = theme.size;
        });

        crow.rule(component -> {
            if (component.getType() != "Tool") return;
            var tool = cast(component, Tool);
            // tool.color = Color(foreground);
            // tool.color = Color(Transparent);
            tool.color = Color(theme.background);
            tool.horizontal = Hug;
            tool.vertical = Hug;
            tool.minW = theme.icon;
            tool.minH = theme.icon;
            tool.borderRadius = All(theme.radius);
            tool.padding = theme.insets;
            tool.borderWidth = All(2);
            tool.borderColor = Color(theme.ghost);
            tool.hjustify = 0;
        });

        crow.rule(component -> {
            if (component.label != "tool-text") return;
            var text = cast(component, TextWidget);
            text.color = Color(theme.foreground);
        });

        crow.rule(component -> {
            if (component.getType() != "Button") return;
            var button = cast(component, Button);
            button.color = Color(theme.foreground);
            button.horizontal = Fill;
            button.vertical = Hug;
            button.borderRadius = All(theme.radius);
            button.padding = theme.insets;
            button.hjustify = 0;
        });

        crow.rule(component -> {
            if (component.label != "button-text") return;
            var text = cast(component, TextWidget);
            text.color = Color(theme.background);
        });

        crow.rule(component -> {
            if (component.getType() != "Button" || component.label != "alert") return;
            var button = cast(component, Button);
            button.color = Color(theme.alert);
        });

        crow.rule(component -> {
            if (component.label != "icon") return;
            var widget = cast(component, Widget);
            widget.horizontal = Fixed(theme.icon);
            widget.vertical = Fixed(theme.icon);
        });

        crow.application.onLoad = application -> {
            // /*
            crow.application.framerate = 60;

            var grid = new GridShader(Context.active);
            grid.setColor(theme.ghost);
            grid.setSize(5);
            grid.setSpacing(ViewportWidget.unit);

            var ghostColored:ColoredShader = application.backend.shader(ColoredShader.label);
            ghostColored.setColor(theme.ghost);
            var icons = application.backend.loadImage(logimimic.ds.Assets.image_icons);

            tree = crow.Component({
                onReady: function(component:Component) {
                    // var context:ContextComponent = component.get("context");

                    var itemRegistry:RegistryComponent = component.get("registry/item");

                    // @todo вынести в отдельные плагины
                    itemRegistry.subscribe("input", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "input";
                            factory.name = "Input";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.foreground = theme.foreground;
                                    element.name = "Input";
                                    element.view = "0";
                                    element.width = 2;
                                    element.height = 1;
                                    var isActive = false;
                                    element.onExecute = lock -> {
                                        lock.outputs.iter(s -> s.value = isActive ? 1 : 0);
                                    }
                                    element.onSettings = widget -> {
                                        widget.addChild(crow.Button(button -> {
                                            button.text = "Delete";
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }, {
                                            label: "alert"
                                        }));
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(tool -> {
                                            tool.text = null;
                                            tool.icon = Tile(0, Icons.Power, 1, 1 / 4, icons);
                                            tool.onClick = tool -> {
                                                var output:Socket = element.sockets.getChildAt(0);
                                                isActive = !isActive;
                                                output.value = isActive ? 1 : 0;
                                                element.view = Std.string(output.value);
                                            }
                                        }));
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = false;
                                                socket.isOutput = true;
                                                socket.position = Right(0);
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });

                    itemRegistry.subscribe("output", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "output";
                            factory.name = "Output";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.foreground = theme.foreground;
                                    element.name = "Output";
                                    element.view = "0";
                                    element.width = 2;
                                    element.height = 1;
                                    // element.onExecute = lock -> {
                                        
                                    // }
                                    element.onSettings = widget -> {
                                        widget.addChild(crow.Button(button -> {
                                            button.text = "Delete";
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }, {
                                            label: "alert"
                                        }));
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(0);
                                                socket.onValue.subscribe(v -> element.view = Std.string(v));
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });

                    itemRegistry.subscribe("or-gate", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "or-gate";
                            factory.name = "|";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.foreground = theme.foreground;
                                    element.name = "OR Gate";
                                    element.view = "|";
                                    element.onExecute = lock -> {
                                        var isActive = lock.inputs.exists(s -> s.value != 0);
                                        for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(0);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(1);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = false;
                                                socket.isOutput = true;
                                                socket.position = Right(0);
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });

                    itemRegistry.subscribe("and-gate", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "and-gate";
                            factory.name = "&";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.foreground = theme.foreground;
                                    element.name = "AND Gate";
                                    element.view = "&";
                                    element.onExecute = lock -> {
                                        var isActive = lock.inputs.foreach(s -> s.value != 0);
                                        for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(0);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(1);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = false;
                                                socket.isOutput = true;
                                                socket.position = Right(0);
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });

                    itemRegistry.subscribe("xor-gate", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "xor-gate";
                            factory.name = "^";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.foreground = theme.foreground;
                                    element.name = "XOR Gate";
                                    element.view = "^";
                                    element.onExecute = lock -> {
                                        var isActive = lock.inputs.exists(s -> s.value != 0) && !lock.inputs.foreach(s -> s.value != 0);
                                        for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(0);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(1);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = false;
                                                socket.isOutput = true;
                                                socket.position = Right(0);
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });

                    itemRegistry.subscribe("not-gate", () -> {
                        return crow.FactoryComponent(factory -> {
                            factory.label = "not-gate";
                            factory.name = "!";
                            factory.onExecute = data -> {
                                var op:OperationComponent = component.getRoot().get("operation/window/add-element");
                                var element:ElementEntity = null;
                                op.execute(crow, element = crow.ElementEntity(element -> {
                                    element.label = factory.label;
                                    element.color = Color(theme.background);
                                    element.borderRadius = All(6);
                                    element.height = 1;
                                    element.width = 1;
                                    element.foreground = theme.foreground;
                                    element.name = "NOT Gate";
                                    element.view = "!";
                                    element.onExecute = lock -> {
                                        var isActive = lock.inputs.exists(s -> s.value != 0);
                                        for (socket in lock.outputs) socket.value = isActive ? 0 : 1;
                                    }
                                    element.onHud = widget -> {
                                        widget.addChild(crow.Tool(button -> {
                                            button.text = null;
                                            button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                            button.onClick = button -> {
                                                var op:OperationComponent = component.getRoot().get("operation/window/delete-entity");
                                                op.execute(crow, element);
                                            }
                                        }));
                                    }
                                    element.sockets = crow.Component({
                                        children: [
                                            crow.Socket(socket -> {
                                                socket.isInput = true;
                                                socket.isOutput = false;
                                                socket.position = Left(0);
                                            }),
                                            crow.Socket(socket -> {
                                                socket.isInput = false;
                                                socket.isOutput = true;
                                                socket.position = Right(0);
                                            })
                                        ]
                                    });
                                }));
                                return element;
                            }
                        });
                    });
                    
                    
                    ViewportWidget.onClick.subscribe(function(viewport:ViewportWidget, x:Float, y:Float) {
                        // trace("----------", viewport.isWiring);
                        var local = viewport.unsnap(viewport.toLocal(x, y)).clone();
                        
                        // var settings:Widget = component.get("settings");
                        var area = viewport.getArea();
                        buildSolver();
                        var entities:Array<Entity> = viewport.getChildren();
                        
                        // ----------------------------- Handling click -----------------------------
                        // @todo проверить везде ниже toGrid или toCells

                        // var elements = [];
                        // switch (viewport.toGrid(x, y)) {
                        //     case Grid(x, y):
                        //         ElementEntity.clickRequest.emit(slot -> slot(x, y, elements));
                        //     default:
                        // }

                        // var elements:Array<ElementEntity> = cast entities.filter(c -> switch (c.snap) {
                        //     case Cells(x1, y1): x >= x1 && y >= y1 && x < x1 + width && y < y1 + height;
                        //     default: false;
                        // });

                        var elements:Array<ElementEntity> = cast entities.filter(e -> e.getType() == ElementEntity.type && e.canSelect(local.x, local.y));


                        // var wires = [];
                        //
                        // switch (viewport.toGrid(x, y)) {
                        //     case Grid(x, y):
                        //         WireEntity.clickRequest.emit(slot -> slot(x, y, wires));
                        //     default:
                        // }
                        // WireEntity.clickRequest.emit(slot -> slot(viewport.toLocal(x, y), wires));
                        // switch (viewport.toLocal(x, y)) {
                        //     case Free(x, y):
                        //         WireEntity.clickRequest.emit(slot -> slot(x, y, wires));
                        //     default:
                        // }

                        // var wires:Array<WireEntity> = cast entities.filter(e -> e.getType() == WireEntity.type && switch (viewport.toLocal(x, y)) {
                        //     case Free(x, y): cast(e, WireEntity).getSegment(x, y) != null;
                        //     default: false;
                        // });

                        var wires:Array<WireEntity> = cast entities.filter(e -> e.getType() == WireEntity.type && e.canSelect(local.x, local.y));
                        
                        // var sockets = [];
                        // switch (viewport.toGrid(x, y)) {
                        //     case Grid(x, y):
                        //         Socket.clickRequest.emit(slot -> slot(x, y, sockets));
                        //     default:
                        // }

                        // var sockets = binarySolver.sockets.filter(s -> switch [viewport.toGrid(x, y), s.snap] {
                        //     case [Grid(x1, y1), Grid(x2, y2)]: x1 == x2 && y1 == y2;
                        //     default: false;
                        // });

                        var sockets = binarySolver.sockets.filter(s -> s.canSelect(local.x, local.y));

                        


                        // -----------------------------  -----------------------------
                        var hasActive = false;

                        {
                            // var all = new Array<ElementEntity>();
                            // ElementEntity.collectRequest.emit(slot -> slot(all));
                            var all:Array<ElementEntity> = cast entities.filter(e -> e.entityType == Element);
                            hasActive = hasActive || all.exists(e -> e.isActive);
                            for (e in all) e.isActive = false;
                        }

                        {
                            // var all = new Array<WireEntity>();
                            // WireEntity.collectRequest.emit(slot -> slot(all));
                            var all:Array<WireEntity> = cast entities.filter(e -> e.getType() == WireEntity.type);
                            hasActive = hasActive || all.exists(w -> w.isActive);
                            for (w in all) w.isActive = false;
                        }
                        
                        if (hasActive) {
                            hideHud();
                            hideSettings();
                            return;
                        }
                        viewport.isSelecting = false;

                        if (!viewport.isWiring) {
                            var current = elements.length == 0 ? null : elements[0];
                            // Select / hud
                            if (current != null && current != ElementEntity.active) {
                                hideHud();
                                hideSettings();
                                viewport.click = current.snap;
                                if (current.onHud != null) showHud(current.onHud);
                                ElementEntity.active = current;
                                return;
                            }
                            // Settings
                            if (ElementEntity.active != null && ElementEntity.active == current) {
                                hideHud();
                                hideSettings();
                                if (current.onSettings != null) showSettings(current.onSettings);
                                ElementEntity.active = current;
                                return;
                            }
                            // Unselect
                            if (ElementEntity.active != null && current == null) {
                                ElementEntity.active = null;
                                hideHud();
                                hideSettings();
                                return;
                            }
                            if (ElementEntity.active != null) return;
                        }

                        if (!viewport.isWiring) {
                            var current = wires.length == 0 ? null : wires[0];
                            // trace("------ 0", current);
                            // Select / hud
                            if (current != null && current != WireEntity.active) {
                                // @todo попробовать вынести выше
                                hideHud();
                                hideSettings();
                                viewport.click = viewport.toGrid(area.mouseLocal.x, area.mouseLocal.y);
                                if (current.onHud != null) showHud(current.onHud);
                                WireEntity.active = current;
                                // trace("------ 1");
                                return;
                            }
                            // Settings
                            if (WireEntity.active != null && WireEntity.active == current) {
                                hideHud();
                                hideSettings();
                                if (current.onSettings != null) showSettings(current.onSettings);
                                WireEntity.active = current;
                                // trace("------ 2");
                                return;
                            }
                            // Unselect
                            if (WireEntity.active != null && current == null) {
                                WireEntity.active = null;
                                hideHud();
                                hideSettings();
                                // trace("------ 3");
                                return;
                            }
                            if (WireEntity.active != null) return;
                        }
                        // trace("------ 4");

                        // trace(Math.random(), "----------------");
                        // trace(sockets);
                        {
                            // trace("a");
                            // Select
                            var current = sockets.length == 0 ? null : sockets[0];
                            // var current = sockets.length == 0 ? null : sockets.find(s -> s);
                            Socket.active = current;
                            // Socket drag
                            // var all = new Array<Socket>();
                            // Socket.collectRequest.emit(slot -> slot(all));
                            // trace(all);
                            // trace(binarySolver.sockets);
                            // trace(binarySolver.locks);
                            var all = binarySolver.sockets;
                            // if (all.exists(s -> s.area.isDragging || s.area.isDropped)) return;
                            var isDragging = all.exists(s -> s.area.isDragging);
                            var isDropped = all.exists(s -> s.area.isDropped);
                            if (isDropped) buildSolver();   // @todo не всегда работает даже с задержкой
                            if (isDragging || isDropped) return;
                        }
                        // trace("b");
                        // trace(Socket.active);

                        // -----------------------------  -----------------------------

                        if (viewport.isWiring && wires.length > 0) {
                            trace("Cross connection");
                            for (wire in wires) {
                                var sockets:Array<Socket> = wire.sockets.getChildren();
                                if (sockets.exists(s -> s.snap.equals(viewport.click))) continue;
                                var segment = switch (viewport.toLocal(x, y)) {
                                    case Free(x, y): wire.getSegment(x, y);
                                    default: continue;
                                }
                                if (segment == null) continue;
                                wire.sockets.insertChild(segment + 1, crow.Socket(socket -> {
                                    socket.snap = viewport.toGrid(x, y);
                                }));
                            }
                            WireEntity.active.sockets.addChild(crow.Socket(socket -> {
                                socket.snap = viewport.toGrid(area.mouseLocal.x, area.mouseLocal.y);
                            }));
                            WireEntity.active = null;
                            Socket.active = null;
                            viewport.isWiring = false;
                            buildSolver();
                            return;
                        }

                        if (Socket.active == null) {
                            if (viewport.isWiring) {
                                trace("adding socket");
                                // return;
                                var socket = crow.Socket(socket -> {
                                    socket.snap = viewport.toGrid(area.mouseLocal.x, area.mouseLocal.y);
                                });
                                WireEntity.active.sockets.addChild(socket);
                            } else {
                                // return;
                                trace("adding element");
                                application.delay(application -> {
                                    var dock:DockWidget = cast component.get("dock");
                                    dock.active?.execute(crow);
                                    return;
                                });
                            }
                        } else {
                            if (viewport.isWiring) {
                                trace("closing wire");
                                WireEntity.active.sockets.addChild(
                                    crow.Socket(socket -> {
                                        socket.snap = viewport.toGrid(area.mouseLocal.x, area.mouseLocal.y);
                                    })
                                );
                                WireEntity.active = null;
                                Socket.active = null;
                                viewport.isWiring = false;
                                buildSolver();
                            } else {
                                trace("creating wire");
                                viewport.addChild(
                                    WireEntity.active = crow.WireEntity(wire -> {
                                        wire.label = "entity/wire";
                                        wire.color = Color(theme.ghost);
                                        wire.onMouseInput = (widget, mouse) -> {
                                            widget.color = Color(widget.isActive || WireEntity.active == widget ? theme.accent : theme.ghost);
                                            return true;
                                        }
                                        wire.sockets = crow.Component({
                                            children: [
                                                Socket.active = crow.Socket(socket -> {
                                                    socket.snap = viewport.toGrid(x, y);
                                                })
                                            ]
                                        });
                                        wire.onHud = widget -> {
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire-line"), FactoryComponent).execute(crow, wire));
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire-segment"), FactoryComponent).execute(crow, wire));
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire"), FactoryComponent).execute(crow, wire));
                                        }
                                        // @todo move to the factory
                                        wire.onExecute = lock -> {
                                            var isActive = lock.inputs.exists(s -> s.value != 0);
                                            for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                                        }
                                    })
                                );
                                viewport.isWiring = true;
                            }
                        }
                    });
                },
                children: [
                    // crow.ContextComponent(context -> {
                    //     context.url = "window/context";
                    // }),
                    crow.Component({
                        children: [
                            crow.RegistryComponent(registry -> {
                                registry.url = "registry/item";
                            }),
                            crow.OperationComponent(component -> {
                                component.url = "operation/window/add-element";
                                component.onExecute = data -> {
                                    var viewport:ViewportWidget = component.getRoot().get("window/viewport");
                                    var area = viewport.getArea();
                                    
                                    var element = cast(data, ElementEntity);

                                    element.snap = viewport.toCells(area.mouse.x - viewport.w / 2 - viewport.x, area.mouse.y - viewport.h / 2 - viewport.y);

                                    element.onMouseInput = (widget, mouse) -> {
                                        var a = widget.getArea();
                                        if (widget.isActive || ElementEntity.active == widget) {
                                            widget.borderColor = Color(theme.accent);
                                            widget.borderWidth = All(4);
                                        } else {
                                            widget.borderColor = Color(theme.background);
                                            widget.borderWidth = All(0);
                                        }
                                        if (ElementEntity.active == widget) {
                                            var widget = ElementEntity.active;
                                            if (a.isDragging) {
                                                widget.snap = viewport.toFree(area.mouseLocal.x, area.mouseLocal.y);
                                                hideHud();
                                                hideSettings();
                                            } else if (a.isDropped) {
                                                widget.snap = viewport.toCells(area.mouseLocal.x, area.mouseLocal.y);
                                                application.delay(app -> buildSolver());
                                            }
                                            return true;
                                        }
                                        return true;
                                    }

                                    viewport.addChild(data);
                                    buildSolver();
                                    // application.delay(app -> buildSolver());
                                    return true;
                                };
                            }),
                            crow.OperationComponent(component -> {
                                component.url = "operation/window/delete-entity";

                                component.onExecute = data -> {
                                    data.free();
                                    Socket.active = null;
                                    WireEntity.active = null;
                                    ElementEntity.active = null;
                                    hideHud();
                                    hideSettings();
                                    buildSolver();
                                    return true;
                                }
                            }),
                            crow.FactoryComponent(factory -> {
                                factory.url = "entity/wire";
                                factory.onExecute = data -> {
                                    return crow.WireEntity(wire -> {
                                        wire.label = factory.url;
                                        wire.color = Color(theme.ghost);
                                        wire.onMouseInput = (widget, mouse) -> {
                                            widget.color = Color(widget.isActive || WireEntity.active == widget ? theme.accent : theme.ghost);
                                            return true;
                                        }
                                        wire.onHud = widget -> {
                                            // @todo tools collect request
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire-line"), FactoryComponent).execute(crow, wire));
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire-segment"), FactoryComponent).execute(crow, wire));
                                            widget.addChild(cast(tree.get("tool/entity/delete-wire"), FactoryComponent).execute(crow, wire));
                                        }
                                        // @todo move to the factory
                                        wire.onExecute = lock -> {
                                            var isActive = lock.inputs.exists(s -> s.value != 0);
                                            for (socket in lock.outputs) socket.value = isActive ? 1 : 0;
                                        }
                                    });
                                }
                            }),
                            crow.FactoryComponent(factory -> {
                                factory.url = "tool/entity/delete-wire";
                                factory.onExecute = wire -> {
                                    var wire = cast(wire, WireEntity);
                                    return crow.Tool(button -> {
                                        // button.text = "Rem Wire";
                                        button.text = null;
                                        // button.icon = Color(Orange);
                                        button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                        button.onClick = button -> {
                                            var op:OperationComponent = factory.getRoot().get("operation/window/delete-entity");
                                            op.execute(crow, wire);
                                        }
                                    });
                                }
                            }),
                            crow.FactoryComponent(factory -> {
                                factory.url = "tool/entity/delete-wire-line";
                                factory.onExecute = wire -> {
                                    var wire = cast(wire, WireEntity);
                                    return crow.Tool(button -> {
                                        button.text = null;
                                        button.icon = Tile(0, Icons.RemoveLine, 1, 1 / 4, icons);
                                        button.onClick = button -> {
                                            application.delay(app -> {
                                                var viewport:ViewportWidget = factory.getRoot().get("window/viewport");
                                                hideHud();
                                                hideSettings();
                                                Socket.active = null;
                                                WireEntity.active = null;
                                                ElementEntity.active = null;
                                                var start = switch (viewport.point) {
                                                    case Free(x, y): wire.getSegment(x, y);
                                                    default: return;
                                                }
                                                // @todo удалять провода у которых меньше двух сокетов
                                                if (start == null) return;
                                                if (start < 1) {
                                                    wire.sockets.getChildAt(start).free();
                                                    return;
                                                }
                                                if (start + 2 >= wire.sockets.children.length) {
                                                    wire.sockets.getChildAt(start + 1).free();
                                                    return;
                                                }
                                                var w = crow.WireEntity(w -> {
                                                    w.sockets = crow.Component();
                                                    w.onMouseInput = wire.onMouseInput;
                                                    w.snap = wire.snap;
                                                    // @todo move to registry or factory
                                                    w.onExecute = wire.onExecute;
                                                    w.onSettings = wire.onSettings;
                                                    w.onHud = widget -> {
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire-line"), FactoryComponent).execute(crow, w));
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire-segment"), FactoryComponent).execute(crow, w));
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire"), FactoryComponent).execute(crow, w));
                                                    }
                                                    w.thickness = wire.thickness;
                                                });

                                                start++;
                                                var socket:Socket = wire.sockets.getChildAt(start); // @todo ++start
                                                while (socket != null) {
                                                    w.sockets.addChild(crow.Socket(s -> {
                                                        s.label = socket.label;
                                                        s.isInput = socket.isInput;
                                                        s.isOutput = socket.isOutput;
                                                        s.snap = socket.snap;
                                                        s.position = socket.position;
                                                    }));
                                                    socket.free();
                                                    socket = wire.sockets.getChildAt(start);
                                                }
                                                viewport.addChild(w);
                                                buildSolver();
                                            });
                                        }
                                    });
                                }
                            }),
                            crow.FactoryComponent(factory -> {
                                factory.url = "tool/entity/delete-wire-segment";
                                factory.onExecute = wire -> {
                                    var wire = cast(wire, WireEntity);
                                    return crow.Tool(button -> {
                                        button.text = null;
                                        button.icon = Tile(0, Icons.RemoveSegment, 1, 1 / 4, icons);
                                        button.onClick = button -> {
                                            var viewport:ViewportWidget = factory.getRoot().get("window/viewport");
                                            hideHud();
                                            hideSettings();
                                            Socket.active = null;
                                            WireEntity.active = null;
                                            ElementEntity.active = null;
                                            buildSolver();
                                            var start = switch (viewport.point) {
                                                case Free(x, y): wire.getSegment(x, y);
                                                default: return;
                                            }
                                            // trace(start);
                                            if (start == null) return;

                                            // var sockets = new Array<Socket>();
                                            // Socket.collectRequest.emit(slot -> slot(sockets));
                                            var sockets = binarySolver.sockets;

                                            var sc:Array<Socket> = wire.sockets.getChildren();
                                            var end = sc.foldi((socket, result, index) -> index > start + 1 && sockets.exists(s -> sc[result] != s && s.snap.equals(sc[result].snap)) ? result : index, 0);
                                            var start = sc.foldi((socket, result, index) -> index <= start && sockets.exists(s -> socket != s && s.snap.equals(socket.snap)) ? index : result, 0);
                                            // trace(start, end);

                                            if (end + 1 < wire.sockets.children.length) {
                                                // trace("Added right wire");
                                                var w = crow.WireEntity(w -> {
                                                    w.sockets = crow.Component();
                                                    w.onMouseInput = wire.onMouseInput;
                                                    w.snap = wire.snap;
                                                    // @todo move to registry or factory
                                                    w.onExecute = wire.onExecute;
                                                    w.onSettings = wire.onSettings;
                                                    w.onHud = widget -> {
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire-line"), FactoryComponent).execute(crow, w));
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire-segment"), FactoryComponent).execute(crow, w));
                                                        widget.addChild(cast(tree.get("tool/entity/delete-wire"), FactoryComponent).execute(crow, w));
                                                    }
                                                    w.thickness = wire.thickness;
                                                });

                                                for (i in end...wire.sockets.children.length) {
                                                    var socket:Socket = wire.sockets.getChildAt(i);
                                                    w.sockets.addChild(crow.Socket(s -> {
                                                        s.label = socket.label;
                                                        s.isInput = socket.isInput;
                                                        s.isOutput = socket.isOutput;
                                                        s.snap = socket.snap;
                                                        s.position = socket.position;
                                                    }));
                                                }

                                                viewport.addChild(w);
                                            }

                                            if (start > 0) {
                                                // trace("Removed sockets from left wire");
                                                var socket:Socket = wire.sockets.getChildAt(++start);
                                                while (socket != null) {
                                                    socket.free();
                                                    socket = wire.sockets.getChildAt(start);
                                                }
                                            } else {
                                                // trace("Removed left wire");
                                                // @todo operator
                                                wire.free();
                                            }
                                            buildSolver();
                                        }
                                    });
                                }
                            })
                        ]
                    }),
                    crow.StageGui({
                        label: "gui",
                        children: [
                            crow.BoxWidget(widget -> {
                                widget.color = Color(theme.background);
                            }, {
                                children: [
                                    crow.BoxWidget(widget -> {
                                        widget.label = "workspace";
                                        widget.color = LinearGradient(0, 0, 0.3, 1, [{
                                            stop: 0.0,
                                            color: 0xFF474747
                                        }, {
                                            stop: 0.7,
                                            color: 0xFF2B2B2B
                                        }]);
                                        widget.borderRadius = All(8);
                                        widget.left = Fixed(40);
                                        widget.right = Fixed(8);
                                        widget.top = Fixed(8);
                                        widget.bottom = Fixed(8);
                                    }, {
                                        children: [
                                            crow.ViewportWidget(widget -> { // @todo rename viewport
                                                widget.url = "window/viewport";
                                                widget.label = "viewport";
                                                widget.color = Shader(grid);
                                                widget.anchors = Fixed(15);
                                                widget.clip = true;
                                                // widget.transform = Matrix.Scale(1, 1);
                                                // widget.transform = Matrix.RotationZ(MathUtils.radians(30));
                                                // widget.camera = Matrix.Scale(0.5, 0.5, 1);
                                                // widget.camera = Matrix.Scale(1, 1, 1);
                                                // widget.camera = Matrix.Translation(0, 0);
                                                widget.animation = crow.Animation(animation -> {
                                                    animation.isLooped = true;
                                                    animation.play(crow);
                                                    animation.onFrameChanged = (animation, progress) -> {
                                                        binarySolver.step();
                                                    }
                                                });
                                                widget.onDraw = (_, stage) -> {
                                                    if (widget.selection != null) {
                                                        stage.buffer.pushTransform(widget.camera);
                                                        stage.buffer.setShader(ghostColored);
                                                        stage.buffer.drawLine(widget.selection.left, widget.selection.top, widget.selection.right, widget.selection.top, 5);
                                                        stage.buffer.drawLine(widget.selection.right, widget.selection.top, widget.selection.right, widget.selection.bottom, 5);
                                                        stage.buffer.drawLine(widget.selection.right, widget.selection.bottom, widget.selection.left, widget.selection.bottom, 5);
                                                        stage.buffer.drawLine(widget.selection.left, widget.selection.bottom, widget.selection.left, widget.selection.top, 5);
                                                        // stage.buffer.drawRoundedRect(widget.selection.left, widget.selection.top, widget.selection.right, widget.selection.bottom, 6, 6, 6, 6);
                                                        stage.buffer.flush();
                                                        stage.buffer.popTransform();
                                                    }


                                                    if (WireEntity.active == null || !widget.isWiring) return;
                                                    var area = widget.getArea();
                                                    stage.buffer.pushTransform(widget.camera);
                                                    var scale = widget.getCameraInverse().getScale();
                                                    stage.buffer.setShader(ghostColored);
                                                    var socket:Socket = WireEntity.active.sockets.getChildLast();
                                                    var start = widget.unsnap(socket.snap);
                                                    var sx = start.x;
                                                    var sy = start.y;
                                                    var end = widget.toGrid(area.mouseLocal.x, area.mouseLocal.y);
                                                    var end = widget.unsnap(end);
                                                    stage.buffer.drawLine(sx, sy, end.x, end.y, 8);
                                                    stage.buffer.flush();
                                                    stage.buffer.popTransform();
                                                }
                                                widget.onMouseInput = (_, mouse) -> {
                                                    var input = application.backend.input(0);

                                                    if (input.isReleased(KeyCode(Space))) {
                                                        buildSolver();
                                                    }

                                                    if (input.isReleased(KeyCode(E))) {
                                                        trace("step");
                                                        binarySolver.step();
                                                    }

                                                    var area = widget.getArea();
                                                    var local = widget.unsnap(widget.toLocal(area.mouseLocal.x, area.mouseLocal.y)).clone();

                                                    if (widget.isSelecting) {
                                                        // var elements = new Array<ElementEntity>();
                                                        // ElementEntity.collectRequest.emit(slot -> slot(elements));
                                                        // var wires = new Array<WireEntity>();
                                                        // WireEntity.collectRequest.emit(slot -> slot(wires));

                                                        var elements:Array<Entity> = widget.getChildren();  // @todo rename entities

                                                        // var clicked = [];
                                                        // switch (widget.toGrid(area.mouseLocal.x, area.mouseLocal.y)) {
                                                        //     case Grid(x, y):
                                                        //         ElementEntity.clickRequest.emit(slot -> slot(x, y, clicked));
                                                        //     default:
                                                        // }
                                                        var clicked:Array<ElementEntity> = cast elements.filter(e -> e.getType() == ElementEntity.type && e.canSelect(local.x, local.y));

                                                        if (area.isDragging) {
                                                            if (clicked.length > 0) widget.isGrabbing = true;

                                                            // @todo убрать проверки на getType - сделть унифицированную систему
                                                            if (widget.isGrabbing) {
                                                                for (element in elements) {
                                                                    if (!element.isActive) continue;
                                                                    var scale = widget.getCameraInverse().getScale();

                                                                    switch (element.snap) {
                                                                        case Grid(x, y):
                                                                            // trace("qq", element.snap);
                                                                            // if (element.getType() == WireEntity.type) {
                                                                            //     var sockets:Array<Socket> = cast(element, WireEntity).sockets.getChildren();
                                                                            //     for (socket in sockets) {
                                                                            //         var pos = widget.camera.MultVec(widget.unsnap(socket.snap));
                                                                            //         socket.snap = widget.toFree(pos.x, pos.y);
                                                                            //     }
                                                                            // }
                                                                            var pos = widget.camera.MultVec(widget.unsnap(element.snap));
                                                                            element.snap = widget.toFree(pos.x, pos.y);
                                                                        case Cells(x, y):
                                                                            var pos = widget.camera.MultVec(widget.unsnap(element.snap));
                                                                            element.snap = widget.toFree(pos.x, pos.y);
                                                                        case Free(x, y):
                                                                            // проблема в том, что после смщения дельта считается от центра экрана до нулевой точки
                                                                            // поэтому toFree не будет работать - нужен только scale без смещения
                                                                            element.snap = Free(x + scale.x * area.mouseDelta.x, y + scale.y * area.mouseDelta.y);
                                                                        default:
                                                                    }

                                                                    // if (element.getType() == WireEntity.type) {
                                                                    //     var sockets:Array<Socket> = cast(element, WireEntity).sockets.getChildren();
                                                                    //     for (socket in sockets) {
                                                                    //         var pos = widget.camera.MultVec(widget.unsnap(socket.snap));
                                                                    //         socket.snap = widget.toFree(pos.x, pos.y);
                                                                    //     }

                                                                    //     // trace("zzzzzzzz");
                                                                    //     var sockets:Array<Socket> = cast(element, WireEntity).sockets.getChildren();
                                                                    //     for (socket in sockets) {
                                                                    //         switch (socket.snap) {
                                                                    //             case Free(x, y):
                                                                    //                 socket.snap = Free(x + scale.x * area.mouseDelta.x, y + scale.y * area.mouseDelta.y);
                                                                    //                 trace("aa", socket.snap);
                                                                    //             default:
                                                                    //         }
                                                                    //     }
                                                                    // }
                                                                }
                                                                // trace("a");
                                                            }
                                                        } else if (area.isDropped && widget.isGrabbing) {
                                                            widget.isGrabbing = false;
                                                            // for (element in elements) {
                                                            //     switch (element.snap) {
                                                            //         case Free(x, y):
                                                            //             var d = new Vector(x, y);
                                                            //             widget.camera.multVec(d);
                                                            //             // element.snap = widget.toCells(x, y);
                                                            //             element.snap = widget.toCells(d.x, d.y);
                                                            //         default:
                                                            //     }
                                                            // }

                                                            for (element in elements) {
                                                                // if (element.getType() == WireEntity.type) {
                                                                //     var sockets:Array<Socket> = cast(element, WireEntity).sockets.getChildren();

                                                                //     for (socket in sockets) {
                                                                //         switch (socket.snap) {
                                                                //             case Free(x, y):
                                                                //                 var d = new Vector(x, y);
                                                                //                 widget.camera.multVec(d);
                                                                //                 socket.snap = widget.toGrid(d.x, d.y);
                                                                //                 // trace(socket.snap);
                                                                //             default:
                                                                //         }
                                                                //     }
                                                                //     continue;
                                                                // }

                                                                // switch (element.snap) {
                                                                //     case Free(x, y):
                                                                //         var d = new Vector(x, y);
                                                                //         widget.camera.multVec(d);

                                                                //         if (element.getType() == WireEntity.type) {
                                                                //             element.snap = widget.toGrid(d.x, d.y);
                                                                //         } else {
                                                                //             element.snap = widget.toCells(d.x, d.y);
                                                                //         }
                                                                //     default:
                                                                // }

                                                                switch (element.snap) {
                                                                    case Free(x, y):
                                                                        var d = new Vector(x, y);
                                                                        widget.camera.multVec(d);

                                                                        if (element.getType() == WireEntity.type) {
                                                                            element.snap = widget.toGrid(d.x, d.y);
                                                                            var sockets:Array<Socket> = cast(element, WireEntity).sockets.getChildren();
                                                                            for (socket in sockets) {
                                                                                switch [element.snap, socket.snap] {
                                                                                    case [Grid(x1, y1), Grid(x2, y2)]:
                                                                                        socket.snap = Grid(x1 + x2, y1 + y2);
                                                                                    default:
                                                                                }
                                                                            }
                                                                            element.snap = Grid(0, 0);
                                                                        } else {
                                                                            element.snap = widget.toCells(d.x, d.y);
                                                                        }
                                                                    default:
                                                                }

                                                                // trace(element.snap);
                                                            }
                                                            application.delay(app -> buildSolver());
                                                            widget.click = widget.toFree(area.mouseLocal.x, area.mouseLocal.y);
                                                            showHud(hud -> {
                                                                hud.addChild(crow.Tool(button -> {
                                                                    button.text = null;
                                                                    button.icon = Tile(0, Icons.Trashcan, 1, 1 / 4, icons);
                                                                    button.onClick = button -> {
                                                                        var op:OperationComponent = widget.getRoot().get("operation/window/delete-entity");
                                                                        while (true) {
                                                                            var entity = Lambda.find(widget.children, c -> c.isActive);
                                                                            if (entity == null) break;
                                                                            op.execute(crow, entity);
                                                                        }
                                                                    }
                                                                }));
                                                            });
                                                            // trace("b");
                                                        }
                                                    }
                                                    
                                                    // if (widget.isSelecting) return true;
                                                    // if (area.isDropped) widget.isGrabbing = false;

                                                    // if (application.backend.input(0).isDown(KeyCode(W))) trace("W");
                                                    if (application.backend.input(0).isCombination([KeyCode(Ctrl), KeyCode(C)])) {
                                                        var entities:Array<Entity> = widget.getChildren();
                                                        clipboard = serialize(entities.filter(c -> c.isActive));
                                                        // trace("W", clipboard);
                                                    }

                                                    if (application.backend.input(0).isCombination([KeyCode(Ctrl), KeyCode(V)])) {
                                                        if (clipboard != null) {
                                                            deserialize(clipboard, true);
                                                            // trace("W", clipboard);
                                                            widget.isGrabbing = true;
                                                        }
                                                    }


                                                    if (area.isPressed) {
                                                        if (application.backend.input(0).isDown(KeyCode(Ctrl))) {
                                                            var free = widget.toFree(area.mouseLocal.x, area.mouseLocal.y);
                                                            switch (free) {
                                                                case Free(x, y): widget.selection = new Area(x, y, x, y);
                                                                case _:
                                                            }
                                                            // trace("selecting");
                                                            widget.isSelecting = true;
                                                        }
                                                    } else if (area.isReleased && widget.selection != null) {
                                                        // trace("selection null");
                                                        
                                                        // var elements = new Array<ElementEntity>();
                                                        // ElementEntity.collectRequest.emit(slot -> slot(elements));
                                                        // var wires = new Array<WireEntity>();
                                                        // WireEntity.collectRequest.emit(slot -> slot(wires));
                                                        var entities:Array<Entity> = widget.getChildren();
                                                        var elements:Array<ElementEntity> = cast entities.filter(e -> e.entityType == Element);
                                                        var wires:Array<WireEntity> = cast entities.filter(e -> e.entityType == Wire);

                                                        var start = widget.camera.MultVec(widget.unsnap(Free(widget.selection.left, widget.selection.top)));
                                                        var end = widget.camera.MultVec(widget.unsnap(Free(widget.selection.right, widget.selection.bottom)));
                                                        // trace(widget.toLocal(s.x, s.y));
                                                        // switch [widget.toLocal(widget.selection.left, widget.selection.top), widget.toLocal(widget.selection.right, widget.selection.bottom)] {
                                                        //     case [Free(x1, y1), Free(x2, y2)]: trace(x1, y1, x2, y2);
                                                        //     case _:
                                                        // }

                                                        switch [widget.toLocal(start.x, start.y), widget.toLocal(end.x, end.y)] {
                                                            case [Free(x1, y1), Free(x2, y2)]:
                                                                // trace(x1, y1, x2, y2);
                                                                for (element in elements) {
                                                                    switch (element.snap) {
                                                                        case Cells(x, y):
                                                                            if (x + element.width > x1 && x < x2 && y + element.height > y1 && y < y2) {
                                                                                element.isActive = true;
                                                                            }
                                                                        case _:
                                                                    }
                                                                }

                                                                for (wire in wires) {
                                                                    var sockets:Array<Socket> = wire.sockets.getChildren();
                                                                    if (sockets.exists(s -> switch (s.snap) {
                                                                        case Grid(x, y): x > x1 && y > y1 && x < x2 && y < y2;
                                                                        case _: false;
                                                                    })) wire.isActive = true;
                                                                }
                                                            case _:
                                                        }
                                                        // trace(widget.selection.left, widget.selection.top, widget.selection.right, widget.selection.bottom);

                                                        ElementEntity.active = null;
                                                        WireEntity.active = null;
                                                        Socket.active = null;
                                                        widget.selection = null;
                                                    }
                                                    if (widget.selection != null && area.isDown) {
                                                        var free = widget.toFree(area.mouseLocal.x, area.mouseLocal.y);
                                                        switch (free) {
                                                            case Free(x, y):
                                                                widget.selection.right = x;
                                                                widget.selection.bottom = y;
                                                            case _:
                                                        }
                                                        // widget.selection.right = area.mouseLocal.x;
                                                        // widget.selection.bottom = area.mouseLocal.y;
                                                        return true;
                                                    }

                                                    if (widget.isGrabbing) return true;

                                                    if (ElementEntity.active != null && ElementEntity.active.getArea().isDragging) return true;
                                                    static var deltaMove = new Vector();
                                                    static var deltaScroll = 0.0;
                                                    if (area.isPressed) deltaMove.zeros();
                                                    if (area.isDragging) {
                                                        deltaMove.addVal(area.mouseDelta.x, area.mouseDelta.y);
                                                    }
                                                    if (area.isOver) {
                                                        deltaScroll += (mouse.wheelDeltaY + mouse.wheelDeltaX) * 0.25;
                                                    }
                                                    var deceleration = 8.0;
                                                    var offsetX = deltaMove.x * MathUtils.clamp(deceleration * application.deltaTime, -1, 1);
                                                    var offsetY = deltaMove.y * MathUtils.clamp(deceleration * application.deltaTime, -1, 1);
                                                    var offsetScroll = deltaScroll * MathUtils.clamp(deceleration * application.deltaTime, -1, 1);

                                                    widget.camera.translate(offsetX, offsetY);
                                                    // widget.camera.scale(1 + mouse.wheelDeltaY * 0.1, 1 + mouse.wheelDeltaY * 0.1);
                                                    // widget.camera.scale(1 + offsetScroll, 1 + offsetScroll);
                                                    var scale = Matrix.Scale(1 + offsetScroll, 1 + offsetScroll).MultMat(widget.camera);
                                                    widget.camera = scale;
                                                    // if (Math.abs(offsetScroll) > 0.01) {
                                                    //     widget.camera.translate(area.mouseDelta.x - (area.left + area.right) / 2, area.mouseDelta.y);
                                                    // }
                                                    deltaMove.subVal(offsetX, offsetY);
                                                    deltaScroll -= offsetScroll;

                                                    // Hiding grid when zoom is too small
                                                    var scale = widget.camera.getScale();
                                                    widget.color = (scale.x + scale.y) / 2 > 0.25 ? Shader(grid) : Color(Transparent);

                                                    // WireEntity.active ??= widget.getRoot().get("test-wire");

                                                    // if (!area.isReleased) {
                                                    if (WireEntity.active != null && !area.isReleased) {
                                                        var socket:Socket = WireEntity.active.sockets.getChildLast();
                                                        // trace(socket.gridX, socket.gridY);
                                                        // /*
                                                        if (socket != null) {
                                                            /*
                                                            var pos = widget.toGrid(mouse.x - widget.w / 2 - widget.x, mouse.y - widget.h / 2 - widget.y);
                                                            // socket.position = Grid;
                                                            // socket.gridX = Math.floor(pos.x);
                                                            // socket.gridY = Math.floor(pos.y);
                                                            socket.snap = pos;
                                                            */
                                                            // trace(pos);
                                                        }
                                                        // */
                                                        // trace(WireEntity.active.sockets.children);
                                                    // } else if (area.isReleased && !area.isDropped) {
                                                    } else if (area.isReleased && !area.isDropped && WireEntity.active != null) {
                                                        // WireEntity.active.sockets.addChild(crow.Socket(socket -> {

                                                        // }));

                                                    // } else if (area.isReleased && !area.isDropped && ElementEntity.active == null) {
                                                    } else if (area.isReleased && !area.isDropped) {
                                                        
                                                    }
                                                    return true;
                                                }
                                            }, {
                                                children: [
                                                    /*
                                                    crow.ElementEntity(widget -> {
                                                        widget.color = Color(background);
                                                        widget.foreground = foreground;
                                                        // widget.x = 100;
                                                        // widget.y = 100;
                                                        // widget.horizontal = Fixed(60);
                                                        // widget.vertical = Fixed(60);
                                                        // widget.posX = 90;
                                                        widget.snap = Cells(0, 0);
                                                        widget.sockets = crow.Component(
                                                            crow.Socket(socket -> {
                                                                socket.isInput = true;
                                                                socket.isOutput = true;
                                                            })
                                                        );
                                                    }),
                                                    */
                                                    /*
                                                    crow.WireEntity(widget -> {
                                                        widget.url = "test-wire";
                                                        widget.color = Color(ghost);
                                                        widget.sockets = crow.Component({
                                                            children: [
                                                                crow.Socket(socket -> socket.position = Grid(0, 0)),
                                                                crow.Socket(socket -> socket.position = Grid(10, 0)),
                                                                crow.Socket(socket -> socket.position = Grid(10, 5))
                                                            ]
                                                        });
                                                    })
                                                    */
                                                ]
                                            }),
                                            crow.LayoutWidget(layout -> {
                                                layout.label = "overlays";
                                                layout.color = Color(Transparent);
                                                layout.anchors = Fixed(theme.padding);
                                                layout.hjustify = -1;
                                                layout.vjustify = 1;
                                                layout.direction = Column;
                                                layout.gap = Fixed(4);
                                                function generateHotkey(info:String) {
                                                    return crow.LayoutWidget(layout -> {
                                                        layout.color = Color(theme.background);
                                                        layout.padding = theme.insets;
                                                        layout.horizontal = Hug;
                                                        layout.vertical = Hug;
                                                        layout.align = -1;
                                                    }, {
                                                        children: [
                                                            crow.TextWidget(text -> {
                                                                text.label = "info";
                                                                text.text = info;
                                                                text.size = 16;
                                                            })
                                                        ]
                                                    });
                                                }

                                                layout.onReady = component -> {
                                                    var keys:Widget = layout.search("keys");
                                                    keys.addChild(generateHotkey("[Single Click] Select"));
                                                    keys.addChild(generateHotkey("[Empty Area Click] Unselect"));
                                                    keys.addChild(generateHotkey("[Single Click] Context Menu"));
                                                    keys.addChild(generateHotkey("[Double Click] Settings"));
                                                    keys.addChild(generateHotkey("[Ctrl + Drag] Area Selection"));
                                                    keys.addChild(generateHotkey("[Socket Click] Wiring"));
                                                    keys.addChild(generateHotkey("[Single Click + Drag] Move Element"));
                                                    keys.addChild(generateHotkey("[Drag] Move Socket"));
                                                }
                                            }, {
                                                children: [
                                                    crow.LayoutWidget(layout -> {
                                                        layout.label = "keys";
                                                        layout.color = Color(Transparent);
                                                        layout.horizontal = Hug;
                                                        layout.vertical = Hug;
                                                        layout.direction = Column;
                                                        layout.gap = Fixed(4);
                                                    }),
                                                    crow.LayoutWidget(layout -> {
                                                        layout.color = Color(theme.background);
                                                        layout.padding = theme.insets;
                                                        layout.horizontal = Hug;
                                                        layout.vertical = Hug;
                                                        layout.align = -1;
                                                        layout.onMouseInput = (widget, mouse) -> {
                                                            var keys:Widget = layout.parent.search("keys");
                                                            var area = widget.getArea();
                                                            if (area.isOver) {
                                                                keys.isEnabled = true;
                                                            } else {
                                                                keys.isEnabled = false;
                                                            }
                                                            return !area.isOver;
                                                        }
                                                    }, {
                                                        children: [
                                                            crow.TextWidget(text -> {
                                                                text.label = "info";
                                                                text.text = "Hot Keys";
                                                                text.size = 16;
                                                            })
                                                        ]
                                                    })
                                                ]
                                            }),
                                            crow.BoxWidget(widget -> {
                                                widget.color = Color(theme.background);
                                                widget.label = "menu";
                                                widget.left = Fixed(0);
                                                widget.top = Fixed(0);
                                                widget.bottom = Fixed(0);
                                                widget.horizontal = Fixed(0);
                                                widget.onMouseInput = (widget, mouse) -> {
                                                    return !widget.getArea().isOver;
                                                }
                                            }, {
                                                animation: crow.SequenceAnimation({
                                                    children: [
                                                        crow.Animation(animation -> {
                                                            animation.label = "close";
                                                            animation.duration = 0.6;
                                                            animation.easing = Easing.easeInOutQuart;
                                                            animation.onFrameChanged = (animation, progress) -> {
                                                                var widget:Widget = animation.getParent().getParent();
                                                                widget.horizontal = Fixed(MathUtils.mix(progress, 350, 0));
                                                            }
                                                        }),
                                                        crow.Animation(animation -> {
                                                            animation.label = "open";
                                                            animation.duration = 0.6;
                                                            animation.easing = Easing.easeInOutQuart;
                                                            animation.onFrameChanged = (animation, progress) -> {
                                                                var widget:Widget = animation.getParent().getParent();
                                                                widget.horizontal = Fixed(MathUtils.mix(progress, 0, 350));
                                                            }
                                                        }),
                                                        crow.Animation(animation -> {
                                                            animation.label = "toggle";
                                                            animation.duration = 0.6;
                                                            animation.easing = Easing.easeInOutQuart;
                                                            animation.onStart = animation -> {
                                                                var widget = animation.find("..");
                                                                widget.isActive = !widget.isActive;
                                                                
                                                                var content = widget.find("content");
                                                                if (!widget.isActive) content.isEnabled = false;
                                                            }
                                                            animation.onEnd = animation -> {
                                                                var widget = animation.find("..");
                                                                var content = widget.find("content");
                                                                if (widget.isActive) content.isEnabled = true;
                                                                updateSaves();
                                                            }
                                                            animation.onFrameChanged = (animation, progress) -> {
                                                                var widget:Widget = animation.getParent().getParent();
                                                                if (widget.isActive) {
                                                                    widget.horizontal = Fixed(MathUtils.mix(progress, 0, 350));
                                                                } else {
                                                                    widget.horizontal = Fixed(MathUtils.mix(progress, 350, 0));
                                                                }
                                                            }
                                                        })
                                                    ]
                                                }),
                                                children: [
                                                    crow.LayoutWidget(widget -> {
                                                        widget.label = "content";
                                                        widget.color = Color(Transparent);
                                                        widget.isEnabled = false;
                                                        widget.anchors = Fixed(theme.padding);
                                                        widget.gap = Fixed(theme.spacing);
                                                        widget.direction = Column;
                                                    }, {
                                                        children: [
                                                            crow.LayoutWidget(layout -> {
                                                                layout.url = "app/saves";
                                                                layout.color = Color(Transparent);
                                                                layout.horizontal = Fill;
                                                                layout.vertical = Hug;
                                                                layout.gap = Fixed(theme.spacing);
                                                                layout.direction = Column;
                                                            }),
                                                            crow.Button(button -> {
                                                                button.text = "Save";
                                                                button.onClick = button -> {
                                                                    trace("saving");
                                                                    var viewport:ViewportWidget = button.getRoot().get("window/viewport");
                                                                    var content = [for (c in viewport.children) c.toStruct()];

                                                                    var data = Json.stringify({data: content}, null, "    ");
                                                                    storage.write(filename, data);
                                                                    updateSaves();
                                                                }
                                                            }),
                                                            crow.Button(button -> {
                                                                button.text = "Save Inc";
                                                                button.onClick = button -> {
                                                                    trace("saving incremental");
                                                                    var viewport:ViewportWidget = button.getRoot().get("window/viewport");
                                                                    var content = [for (c in viewport.children) c.toStruct()];

                                                                    filename = generateFilename();

                                                                    var data = Json.stringify({data: content}, null, "    ");
                                                                    storage.write(filename, data);
                                                                    updateSaves();
                                                                }
                                                            })
                                                        ]
                                                    }),
                                                    crow.DiamondLayout(widget -> {
                                                        widget.label = "menu-tab";
                                                        widget.color = Color(Black);
                                                        widget.direction = Column;
                                                        widget.top = Fixed(40);
                                                        widget.right = Fixed(-15);
                                                        widget.vertical = Hug;
                                                        widget.horizontal = Fixed(30);
                                                        widget.padding = 20;
                                                        widget.vjustify = 0;
                                                        widget.hjustify = 0;
                                                        widget.onMouseInput = (widget, mouse) -> {
                                                            var area = widget.getArea();
                                                            if (area.isReleased) {
                                                                var player = cast(widget.parent.animation, SequenceAnimation);
                                                                player.playAnimation(crow, "toggle");
                                                            }
                                                            return !area.isOver;
                                                        }
                                                    }, {
                                                        children: [
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "m";
                                                                widget.color = Color(theme.foreground);
                                                            }),
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "e";
                                                                widget.color = Color(theme.foreground);
                                                            }),
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "n";
                                                                widget.color = Color(theme.foreground);
                                                            }),
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "u";
                                                                widget.color = Color(theme.foreground);
                                                            }),
                                                        ]
                                                    }),
                                                ]
                                            }),
                                            crow.LayoutWidget(widget -> {
                                                widget.label = "overlays";
                                                widget.color = Color(Transparent);
                                                widget.anchors = Fixed(theme.padding);
                                                widget.hjustify = 0;
                                                widget.vjustify = 1;
                                            }, {
                                                children: [
                                                    crow.DockWidget(dock -> {
                                                        dock.label = "dock";
                                                        dock.url = "dock";
                                                        dock.color = Color(theme.background);
                                                        dock.vertical = Fixed(theme.header);
                                                        dock.horizontal = Hug;
                                                        dock.borderRadius = All(theme.header / 2);
                                                        dock.gap = Fixed(theme.spacing);
                                                        dock.paddingLeft = theme.padding;
                                                        dock.paddingRight = theme.padding;
                                                        dock.vjustify = 0;
                                                        dock.onReady = component -> {
                                                            var registry:RegistryComponent = dock.getRoot().get("registry/item");
                                                            registry.onAdd.subscribe((registry, label, callback) -> {
                                                                // Должен срабатывать, если активен, нажали на viewport и не выделены объекты
                                                                var factory = cast(callback(), FactoryComponent);
                                                                dock.addChild(crow.LayoutWidget(layout -> {
                                                                    layout.label = factory.label;
                                                                    layout.color = Color(Transparent);
                                                                    layout.hjustify = 0;
                                                                    layout.vjustify = 0;
                                                                    layout.horizontal = Hug;
                                                                    layout.minW = theme.icon;
                                                                    layout.onMouseInput = (widget, mouse) -> {
                                                                        var text:TextWidget = layout.getChildAt(0);
                                                                        text.color = Color(widget.isActive || widget.getArea().isOver ? theme.accent : theme.foreground);
                                                                        var area = widget.getArea();
                                                                        if (area.isReleased) dock.active = factory;
                                                                        widget.isActive = widget.label == dock.active?.label;
                                                                        return !area.isOver;
                                                                    }
                                                                }, {
                                                                    children: [
                                                                        crow.TextWidget(text -> {
                                                                            text.font = Assets.font_arial;
                                                                            text.text = factory.name;
                                                                            text.label = factory.label;
                                                                        })
                                                                    ]
                                                                }));
                                                                dock.active ??= factory;
                                                            });
                                                        }
                                                    })
                                                ]
                                            }),
                                            crow.LayoutWidget(widget -> {
                                                widget.label = "overlays";
                                                widget.color = Color(Transparent);
                                                widget.anchors = Fixed(theme.padding);
                                                widget.hjustify = 1;
                                                widget.vjustify = -1;
                                                // @todo show only in fullscreen
                                                // if (application.isDesktop && application.isFullscreen) {
                                                //     widget.is
                                                // }
                                            }, {
                                                children: [
                                                    crow.LayoutWidget(widget -> {
                                                        widget.color = Color(theme.background);
                                                        widget.vertical = Fixed(theme.header);
                                                        widget.horizontal = Hug;
                                                        widget.borderRadius = All(theme.header / 2);
                                                        widget.gap = Fixed(theme.spacing);
                                                        widget.paddingLeft = theme.padding;
                                                        widget.paddingRight = theme.padding;
                                                        widget.vjustify = 0;
                                                    }, {
                                                        children: [
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "_";
                                                                widget.onMouseInput = (widget, mouse) -> {
                                                                    if (widget.getArea().isReleased) application.minimize();
                                                                    widget.color = Color(widget.getArea().isOver ? theme.accent : theme.foreground);
                                                                    return true;
                                                                }
                                                            }),
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "O";
                                                                widget.onMouseInput = (widget, mouse) -> {
                                                                    if (widget.getArea().isReleased) application.maximize();
                                                                    widget.color = Color(widget.getArea().isOver ? theme.accent : theme.foreground);
                                                                    return true;
                                                                }
                                                            }),
                                                            crow.TextWidget(widget -> {
                                                                widget.font = Assets.font_arial;
                                                                widget.text = "X";
                                                                widget.onMouseInput = (widget, mouse) -> {
                                                                    if (widget.getArea().isReleased) application.stop();
                                                                    widget.color = Color(widget.getArea().isOver ? theme.accent : theme.foreground);
                                                                    return true;
                                                                }
                                                            }),
                                                        ]
                                                    })
                                                ]
                                            })
                                        ]
                                    }),
                                    crow.LayoutWidget(layout -> {
                                        layout.label = "menu";
                                        layout.color = Color(Transparent);
                                        layout.hjustify = 0;
                                        layout.padding = 60;
                                        layout.paddingTop = theme.padding + 8;
                                        layout.isEnabled = false;
                                        layout.onMouseInput = (widget, mouse) -> {
                                            var area = widget.getArea();
                                            if (area.isReleased) {
                                                var settings = layout.get("settings");
                                                hideSettings();
                                                // if (settings.isEnabled) {
                                                //     application.delay(app -> {
                                                //     });
                                                //     return false;
                                                // }
                                            }
                                            return true;
                                        }
                                        layout.children = [
                                            crow.LayoutWidget(layout -> {
                                                layout.url = "settings";
                                                layout.label = "content";
                                                layout.color = Color(theme.background);
                                                layout.borderRadius = All(theme.radius);
                                                layout.horizontal = Fill;
                                                layout.vertical = Hug;
                                                layout.maxW = 600;
                                                layout.direction = Column;
                                                layout.padding = theme.padding;
                                                layout.hjustify = -1;
                                                layout.gap = Fixed(theme.spacing);
                                            }, {
                                                children: [
                                                    // crow.TextWidget(text -> {
                                                    //     text.color = Color(foreground);
                                                    //     text.font = Assets.font_arial;
                                                    //     text.text = "Settings";
                                                    //     text.size = title;
                                                    // }),
                                                    // crow.TextWidget(text -> {
                                                    //     text.color = Color(foreground);
                                                    //     text.font = Assets.font_arial;
                                                    //     text.text = "name: AND Gate";
                                                    // })
                                                ]
                                            })
                                        ];
                                    }),
                                    crow.Widget(widget -> {
                                        widget.label = "menu";
                                        widget.color = Color(Transparent);
                                        widget.isEnabled = false;
                                    }, {
                                        children: [
                                            crow.LayoutWidget(layout -> {
                                                layout.url = "hud";
                                                layout.label = "content";
                                                // layout.color = Color(background);
                                                layout.color = Color(Transparent);
                                                // layout.borderWidth = All(1);
                                                layout.borderColor = Color(theme.foreground);
                                                // layout.borderRadius = All(radius);
                                                // layout.horizontal = Fixed(300);
                                                // layout.vertical = Fixed(header);
                                                layout.borderRadius = All(theme.header / 2);
                                                layout.vertical = Fixed(theme.header);
                                                layout.horizontal = Hug;
                                                layout.gap = Fixed(theme.spacing);
                                                layout.paddingLeft = theme.padding;
                                                layout.paddingRight = theme.padding;
                                                layout.vjustify = 0;
                                                layout.onMouseInput = (widget, mouse) -> {
                                                    var viewport:ViewportWidget = layout.getRoot().get("window/viewport");
                                                    if (viewport.click != null) {
                                                        var pos:Vector = null;
                                                        switch (viewport.click) {
                                                            case Grid(x, y): pos = viewport.unsnap(Grid(x, y - 1));
                                                            case Cells(x, y): pos = viewport.unsnap(Cells(x, y - 1));
                                                            case Free(x, y): pos = viewport.unsnap(Free(x, y - theme.header - theme.padding));
                                                        }
                                                        viewport.world.multVec(pos);
                                                        layout.x = pos.x;
                                                        layout.y = pos.y;
                                                    }

                                                    // if (ElementEntity.active == null) return true;
                                                    // var pos = new Vector(-ElementEntity.active.w / 2, -ElementEntity.active.h / 2);
                                                    // ElementEntity.active.world.multVec(pos);
                                                    // layout.x = pos.x;
                                                    // layout.y = pos.y - header - padding;
                                                    return true;
                                                }
                                            })
                                        ]
                                    })
                                ]
                            })
                        ]
                    }),
                ]
            });


            
        }
    }

}