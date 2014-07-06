package uk.co.zutty.ttclone {
    import net.flashpunk.Entity;
    import net.flashpunk.FP;
    import net.flashpunk.Sfx;
    import net.flashpunk.World;
    import net.flashpunk.graphics.Image;
    import net.flashpunk.graphics.Tilemap;
    import net.flashpunk.utils.Input;
    import net.flashpunk.utils.Key;

    import uk.co.zutty.ttclone.path.Pathfinder;

    public class GameWorld extends World {

        public static const MODE_BUILD_ROAD:uint = 1;
        public static const MODE_BUILD_BUS_STOP:uint = 2;
        public static const MAP_SIZE:Number = 64;

        [Embed(source="/select.png")]
        private static const SELECT_IMAGE:Class;

        [Embed(source="/tiles.png")]
        private static const TILES_IMAGE:Class;
        private static const TILE_SIZE:uint = 16;

        [Embed(source="/construction.mp3")]
        private static const CONSTRUCTION_SOUND:Class;

        private var _constructionSound:Sfx = new Sfx(CONSTRUCTION_SOUND);

        [Embed(source="/build.mp3")]
        private static const BUILD_SOUND:Class;

        private var _buildSound:Sfx = new Sfx(BUILD_SOUND);

        private var _background:Tilemap;

        private var _road:Tilemap;
        private var _roadPathfinder:Pathfinder;

        private var _select:Entity;

        private var _lastMouseTileX:int = -1;
        private var _lastMouseTileY:int = -1;

        private var _mode:uint = MODE_BUILD_ROAD;

        private var _busStop:BusStop;
        private var _prevBusStop:BusStop;

        public function GameWorld() {
            _background = new Tilemap(TILES_IMAGE, MAP_SIZE * TILE_SIZE, MAP_SIZE * TILE_SIZE, TILE_SIZE, TILE_SIZE);
            _background.setRect(0, 0, MAP_SIZE, MAP_SIZE, 0);
            addGraphic(_background);

            _road = new Tilemap(TILES_IMAGE, MAP_SIZE * TILE_SIZE, MAP_SIZE * TILE_SIZE, TILE_SIZE, TILE_SIZE);
            addGraphic(_road);

            _roadPathfinder = new Pathfinder(_road);

            _select = new Entity();
            _select.graphic = new Image(SELECT_IMAGE);
            add(_select);
        }

        public function get roadPathfinder():Pathfinder {
            return _roadPathfinder;
        }

        override public function update():void {
            super.update();

            var mouseTileX:uint = Math.floor(mouseX / TILE_SIZE);
            var mouseTileY:uint = Math.floor(mouseY / TILE_SIZE);

            _select.visible = _mode == MODE_BUILD_ROAD;
            _select.x = mouseTileX * TILE_SIZE;
            _select.y = mouseTileY * TILE_SIZE;

            if(Input.check(Key.RIGHT)) {
                FP.camera.x++;
                FP.camera.x = FP.clamp(FP.camera.x, 0, _background.width - FP.width);
            } else if(Input.check(Key.LEFT)) {
                FP.camera.x--;
                FP.camera.x = FP.clamp(FP.camera.x, 0, _background.width - FP.width);
            }
            if(Input.check(Key.DOWN)) {
                FP.camera.y++;
                FP.camera.y = FP.clamp(FP.camera.y, 0, _background.height - FP.height);
            } else if(Input.check(Key.UP)) {
                FP.camera.y--;
                FP.camera.y = FP.clamp(FP.camera.y, 0, _background.height - FP.height);
            }

            if(_mode == MODE_BUILD_ROAD) {
                if (Input.mouseDown) {
                    if (!(mouseTileX == _lastMouseTileX && mouseTileY == _lastMouseTileY)) {
                        var roadChanged:Boolean = Input.check(Key.SHIFT)
                                ? Boolean(clearRoad(mouseTileX, mouseTileY))
                                : Boolean(setRoad(mouseTileX, mouseTileY, true));

                        if (roadChanged) {
                            _buildSound.play();
                            _constructionSound.play();
                        }

                        _lastMouseTileX = mouseTileX;
                        _lastMouseTileY = mouseTileY;
                    }
                } else {
                    _lastMouseTileX = -1;
                    _lastMouseTileY = -1;
                }

                if(Input.pressed(Key.B)) {
                    _mode = MODE_BUILD_BUS_STOP;
                    _busStop = new BusStop();
                    add(_busStop);
                    trace("ADD BUS STOP");
                }
            }

            if(_mode == MODE_BUILD_BUS_STOP) {
                _busStop.x = mouseTileX * TILE_SIZE;
                _busStop.y = mouseTileY * TILE_SIZE;

                var roadTile:uint = _road.getTile(mouseTileX, mouseTileY);
                var valid:Boolean = roadTile == 1 || roadTile == 2;

                _busStop.ns = roadTile == 1;
                _busStop.validBuild = valid;

                if(valid && Input.mousePressed) {
                    _mode = MODE_BUILD_ROAD;
                    _busStop.built = true;

                    if(_prevBusStop != null) {
                        var bus:Bus = new Bus();
                        bus.x = (mouseTileX * TILE_SIZE) + 8;
                        bus.y = (mouseTileY * TILE_SIZE) + 8;
                        bus.ns = roadTile == 1;
                        bus.addStop(_busStop);
                        bus.addStop(_prevBusStop);
                        bus.repath();
                        add(bus);
                    }

                    _prevBusStop = _busStop;

                    _busStop = null;
                }
            }
        }

        private function setRoad(tileX:uint, tileY:uint, recurse:Boolean):int {
            if (tileX < 0 || tileX > _road.columns - 1
                    || tileY < 0 || tileY > _road.rows - 1) {
                return 0;
            }

            var n:Boolean = tileY > 0 && _road.getTile(tileX, tileY - 1) > 0;
            var s:Boolean = tileY < _road.rows - 1 && _road.getTile(tileX, tileY + 1) > 0;
            var w:Boolean = tileX > 0 && _road.getTile(tileX - 1, tileY) > 0;
            var e:Boolean = tileX < _road.columns - 1 && _road.getTile(tileX + 1, tileY) > 0;

            var tile:uint = 1;

            if (!w && !e) {
                tile = 1;
            } else if (!n && !s) {
                tile = 2;
            } else if (!n && s && !w && e) {
                tile = 3;
            } else if (!n && s && w && !e) {
                tile = 4;
            } else if (n && !s && w && !e) {
                tile = 5;
            } else if (n && !s && !w && e) {
                tile = 6;
            } else if (n && s && w && !e) {
                tile = 7;
            } else if (n && s && !w && e) {
                tile = 8;
            } else if (n && !s && w && e) {
                tile = 9;
            } else if (!n && s && w && e) {
                tile = 10;
            } else if (n && s && w && e) {
                tile = 11;
            }

            var changed:int = int(_road.getTile(tileX, tileY) != tile);

            _road.setTile(tileX, tileY, tile);

            if (recurse) {
                if (n) {
                    changed += setRoad(tileX, tileY - 1, false);
                }

                if (s) {
                    changed += setRoad(tileX, tileY + 1, false);
                }

                if (w) {
                    changed += setRoad(tileX - 1, tileY, false);
                }

                if (e) {
                    changed += setRoad(tileX + 1, tileY, false);
                }
            }

            return changed;
        }

        private function clearRoad(tileX:uint, tileY:uint):int {
            if (tileX < 0 || tileX > _road.columns - 1
                    || tileY < 0 || tileY > _road.rows - 1) {
                return 0;
            }

            var changed:int = int(_road.getTile(tileX, tileY) > 0);

            _road.setTile(tileX, tileY, 0);
            _road.clearTile(tileX, tileY);

            var n:Boolean = _road.getTile(tileX, tileY - 1) > 0;
            var s:Boolean = _road.getTile(tileX, tileY + 1) > 0;
            var w:Boolean = _road.getTile(tileX - 1, tileY) > 0;
            var e:Boolean = _road.getTile(tileX + 1, tileY) > 0;

            if (n) {
                changed += setRoad(tileX, tileY - 1, false);
            }

            if (s) {
                changed += setRoad(tileX, tileY + 1, false);
            }

            if (w) {
                changed += setRoad(tileX - 1, tileY, false);
            }

            if (e) {
                changed += setRoad(tileX + 1, tileY, false);
            }

            return changed;
        }

        private function getAdjacency(tilemap:Tilemap, tileX:uint, tileY:uint):Object {
            var adj:Object = new Object();

            adj.n = tilemap.getTile(tileX, tileY - 1) > 0;
            adj.s = tilemap.getTile(tileX, tileY + 1) > 0;
            adj.w = tilemap.getTile(tileX - 1, tileY) > 0;
            adj.e = tilemap.getTile(tileX + 1, tileY) > 0;

            return adj;
        }
    }
}
