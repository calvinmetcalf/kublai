// from https://github.com/danzel/Leaflet.utfgrid

L.Util.jsonp = function (url, cb, cbParam, callbackName){
    var cbName,ourl,cbSuffix,scriptNode,
       head = document.getElementsByTagName('head')[0];
    var cbParam = cbParam || "callback";
    if(callbackName){
        cbName= callbackName;
    }else{
        cbSuffix = "_" + ("" + Math.random()).slice(2);
        cbName = "L.Util.jsonp.cb." + cbSuffix;
    }
    scriptNode = L.DomUtil.create('script', '', head);
    scriptNode.type = 'text/javascript';
    if(cbSuffix) {
        L.Util.jsonp.cb[cbSuffix] = function(data){
            head.removeChild(scriptNode);
            delete L.Util.jsonp.cb[cbSuffix]
            cb(data);
        };
    }
    if (url.indexOf("?") === -1 ){
        ourl =  url+"?"+cbParam+"="+cbName;
    }else{
        ourl =  url+"&"+cbParam+"="+cbName;
    }
    scriptNode.src = ourl;   
};
L.Util.jsonp.cb = {};
L.UtfGrid = L.Class.extend({
    includes: L.Mixin.Events,
	options: {
		subdomains: 'abc',

		minZoom: 0,
		maxZoom: 18,
		tileSize: 256,

		resolution: 2,

		useJsonP: true
	},

	//The thing the mouse is currently on
	_mouseOn: null,

	initialize: function (url, options) {
		L.Util.setOptions(this, options);

		this._url = url;
		this._cache = {};

		//Find a unique id in window we can use for our callbacks
		//Required for jsonP
		var i = 0;
		while (window['lu' + i]) {
			i++;
		}
		this._windowKey = 'lu' + i;
		window[this._windowKey] = {};
	},

	onAdd: function (map) {
		this._map = map;

		this._update();

		var zoom = this._map.getZoom();

		if (zoom > this.options.maxZoom || zoom < this.options.minZoom) {
			return;
		}

		map.on('click', this._click, this);
		map.on('mousemove', this._move, this);
		map.on('moveend', this._update, this);
	},

	onRemove: function () {
		var map = this._map;
		map.off('click', this._click, this);
		map.off('mousemove', this._move, this);
		map.off('moveend', this._update, this);
	},

	_click: function (e) {
		this.fire('click', this._objectForEvent(e));
	},
	_move: function (e) {
		var on = this._objectForEvent(e);

		if (on.data != this._mouseOn) {
			if (this._mouseOn) {
				this.fire('mouseout', { latlng: e.latlng, data: this._mouseOn });
			}
			if (on.data) {
				this.fire('mouseover', on);
			}

			this._mouseOn = on.data;
		}
	},

	_objectForEvent: function (e) {
		var map = this._map,
		    point = map.project(e.latlng),
		    tileSize = this.options.tileSize,
		    resolution = this.options.resolution,
		    x = Math.floor(point.x / tileSize),
		    y = Math.floor(point.y / tileSize),
		    gridX = Math.floor((point.x - (x * tileSize)) / resolution),
		    gridY = Math.floor((point.y - (y * tileSize)) / resolution),
			max = map.options.crs.scale(map.getZoom()) / tileSize;

		x = (x + max) % max;
		y = (y + max) % max;

		var data = this._cache[map.getZoom() + '_' + x + '_' + y];
		if (!data) {
			//console.log('not cached ' + map.getZoom() + '_' + x + '_' + y);
			return { latlng: e.latlng, data: null };
		}

		var idx = this._utfDecode(data.grid[gridY].charCodeAt(gridX)),
		    key = data.keys[idx],
		    result = data.data[key];

		if (!data.data.hasOwnProperty(key))
			result = null;

		return { latlng: e.latlng, data: result};
	},

	//Load up all required json grid files
	//TODO: Load from center etc
	_update: function () {

		var bounds = this._map.getPixelBounds(),
		    zoom = this._map.getZoom(),
		    tileSize = this.options.tileSize;

		if (zoom > this.options.maxZoom || zoom < this.options.minZoom) {
			return;
		}

		var nwTilePoint = new L.Point(
				Math.floor(bounds.min.x / tileSize),
				Math.floor(bounds.min.y / tileSize)),
			seTilePoint = new L.Point(
				Math.floor(bounds.max.x / tileSize),
				Math.floor(bounds.max.y / tileSize)),
				max = this._map.options.crs.scale(zoom) / tileSize;

		//Load all required ones
		for (var x = nwTilePoint.x; x <= seTilePoint.x; x++) {
			for (var y = nwTilePoint.y; y <= seTilePoint.y; y++) {

				var xw = (x + max) % max, yw = (y + max) % max;
				var key = zoom + '_' + xw + '_' + yw;

				if (!this._cache.hasOwnProperty(key)) {
					this._cache[key] = null;

					if (this.options.useJsonP) {
						this._loadTileP(zoom, xw, yw);
					} else {
						this._loadTile(zoom, xw, yw);
					}
				}
			}
		}
	},

	_loadTileP: function (zoom, x, y) {
		var head = document.getElementsByTagName('head')[0],
		    key = zoom + '_' + x + '_' + y,
		    functionName = 'lu_' + key,
		    wk = this._windowKey,
		    self = this;

		var url = L.Util.template(this._url, L.Util.extend({
			s: L.TileLayer.prototype._getSubdomain.call(this, { x: x, y: y }),
			z: zoom,
			x: x,
			y: y,
			cb: wk + '.' + functionName
		}, this.options));

		var script = document.createElement('script');
		script.setAttribute("type", "text/javascript");
		script.setAttribute("src", url);

		window[wk][functionName] = function (data) {
			self._cache[key] = data;
			delete window[wk][functionName];
			head.removeChild(script);
		};

		head.appendChild(script);
	},

	_loadTile: function (zoom, x, y) {
		var url = L.Util.template(this._url, L.extend({
			s: L.TileLayer.prototype._getSubdomain.call(this, { x: x, y: y }),
			z: zoom,
			x: x,
			y: y
		}, this.options));

		var key = zoom + '_' + x + '_' + y;

		//TODO: This uses jquery, would be nice to not!
		$.ajax({
			url: url,
			context: this,
			type: 'GET'
		})
		.done(function (data) {
			this._cache[key] = data;
		});
	},

	_utfDecode: function (c) {
		if (c >= 93)
			c--;
		if (c >= 35)
			c--;
		return c - 32;
	}
});