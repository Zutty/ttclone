package uk.co.zutty.ttclone {
    import net.flashpunk.Entity;
    import net.flashpunk.World;
    import net.flashpunk.graphics.Image;
    import net.flashpunk.graphics.Tilemap;
    import net.flashpunk.utils.Input;
    import net.flashpunk.utils.Key;

    public class GameWorld extends World {

        public static const MODE_BUILD_ROAD:uint = 1;
        public static const MODE_BUILD_BUS_STOP:uint = 2;

        [Embed(source="/select.png")]
        private static const SELECT_IMAGE:Class;

        [Embed(source="/tiles.png")]
        private static const TILES_IMAGE:Class;
        private static const TILE_SIZE:uint = 16;

        private var _background:Tilemap;
        private var _road:Tilemap;
        private var _select:Entity;

        private var _lastMouseTileX:uint = -1;
        private var _lastMouseTileY:uint = -1;

        private var _mode:uint = MODE_BUILD_ROAD;

        private var _busStop:BusStop;

        public function GameWorld() {
            _background = new Tilemap(TILES_IMAGE, 160, 208, TILE_SIZE, TILE_SIZE);
            _background.setRect(0, 0, 10, 13, 0);
            addGraphic(_background);

            _road = new Tilemap(TILES_IMAGE, 160, 208, TILE_SIZE, TILE_SIZE);
            addGraphic(_road);

            _select = new Entity();
            _select.graphic = new Image(SELECT_IMAGE);
            add(_select);
        }

        override public function update():void {
            super.update();

            var mouseTileX:uint = Math.floor(mouseX / TILE_SIZE);
            var mouseTileY:uint = Math.floor(mouseY / TILE_SIZE);

            _select.visible = _mode == MODE_BUILD_ROAD;
            _select.x = mouseTileX * TILE_SIZE;
            _select.y = mouseTileY * TILE_SIZE;

            if(_mode == MODE_BUILD_ROAD) {
                if(Input.mouseDown && !(mouseTileX == _lastMouseTileX && mouseTileY == _lastMouseTileY)) {
                    //trace(_road.getTile(mouseTileX, mouseTileY - 1));

                    Input.check(Key.SHIFT)
                        ? clearRoad(mouseTileX, mouseTileY)
                        : setRoad(mouseTileX, mouseTileY, true);

                    _lastMouseTileX = mouseTileX;
                    _lastMouseTileY = mouseTileY;
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
                    _busStop = null;

                    var bus:Bus = new Bus();
                    bus.x = (mouseTileX * TILE_SIZE) + 8;
                    bus.y = (mouseTileY * TILE_SIZE) + 8;
                    bus.ns = roadTile == 1;
                    add(bus);
                }
            }
        }

        private function setRoad(tileX:uint, tileY:uint, recurse:Boolean):void {
            var n:Boolean = tileY > 0 && _road.getTile(tileX, tileY - 1) > 0;
            var s:Boolean = tileY < _road.rows - 1 && _road.getTile(tileX, tileY + 1) > 0;
            var w:Boolean = tileX > 0 && _road.getTile(tileX - 1, tileY) > 0;
            var e:Boolean = tileX < _road.columns -1 && _road.getTile(tileX + 1, tileY) > 0;

            var tile:uint = 1;

            if(!w && !e) {
                tile = 1;
            } else if(!n && !s) {
                tile = 2;
            } else if(!n && s && !w && e) {
                tile = 3;
            } else if(!n && s && w && !e) {
                tile = 4;
            } else if(n && !s && w && !e) {
                tile = 5;
            } else if(n && !s && !w && e) {
                tile = 6;
            } else if(n && s && w && !e) {
                tile = 7;
            } else if(n && s && !w && e) {
                tile = 8;
            } else if(n && !s && w && e) {
                tile = 9;
            } else if(!n && s && w && e) {
                tile = 10;
            } else if(n && s && w && e) {
                tile = 11;
            }

            _road.setTile(tileX, tileY, tile);

            if(recurse) {
                if(n) setRoad(tileX, tileY - 1, false);
                if(s) setRoad(tileX, tileY + 1, false);
                if(w) setRoad(tileX - 1, tileY, false);
                if(e) setRoad(tileX + 1, tileY, false);
            }
        }

        private function clearRoad(tileX:uint, tileY:uint):void {
            _road.setTile(tileX, tileY, 0);
            _road.clearTile(tileX, tileY)

            var n:Boolean = _road.getTile(tileX, tileY - 1) > 0;
            var s:Boolean = _road.getTile(tileX, tileY + 1) > 0;
            var w:Boolean = _road.getTile(tileX - 1, tileY) > 0;
            var e:Boolean = _road.getTile(tileX + 1, tileY) > 0;

            if(n) setRoad(tileX, tileY - 1, false);
            if(s) setRoad(tileX, tileY + 1, false);
            if(w) setRoad(tileX - 1, tileY, false);
            if(e) setRoad(tileX + 1, tileY, false);
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
