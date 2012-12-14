//from https://github.com/perliedman/leaflet-tilejson
if (typeof L == "undefined"
    || typeof L.version == "undefined"
    || L.version < '0.4') {
    throw "Leaflet not loaded or version is < 0.4";
}

L.TileJSON = (function() {
    var handlers = {
        tilejson: function(context, tilejson) {
            var v = semver.parse(tilejson);
            if (!v || v[1] != 2) {
                throw new Error('This parser supports version 2 '
                                    + 'of TileJSON. (Provided version: "'
                                    + tilejson.tilejson + '"');
            }

            context.validation.version = true;
        },
        minzoom: function(context, minZoom) {
            context.tileLayer.minZoom = minZoom;
        },
        maxzoom: function(context, maxZoom) {
            context.tileLayer.maxZoom = maxZoom;
        },
        center: function(context, center) {
            context.map.center = new L.LatLng(center[1], center[0]);
            context.map.zoom = center[2];
        },
        attribution: function(context, attribution) {
            context.map.attributionControl = true;
            context.tileLayer.attribution = attribution;
        },
        projection: function(context, projection) {
            context.crs.projection = projection;
        },
        transform: function(context, t) {
            context.crs.transformation =
                new L.Transformation(t[0], t[1], t[2], t[3]);
        },
        crs: function(context, crs) {
            context.crs.code = crs;
        },
        scales: function(context, s) {
            context.crs.scale = function(zoom) {
                return s[zoom];
            };
        },
        scheme: function(context, scheme) {
            context.tileLayer.scheme = scheme;
        },
        tilesize: function(context, tileSize) {
            context.tileLayer.tileSize = tileSize;
        },
        tiles: function(context, tileUrls) {
            context.tileUrls = tileUrls;
        }
    };

    var semver = (function() {
        var pattern = "\\s*[v=]*\\s*([0-9]+)"    // major
            + "\\.([0-9]+)"                  // minor
            + "\\.([0-9]+)"                  // patch
            + "(-[0-9]+-?)?"                 // build
            + "([a-zA-Z-][a-zA-Z0-9-\.:]*)?"; // tag
        var semverRegEx = new RegExp("^\\s*"+pattern+"\\s*$");

        return {
            parse: function(v) {
                return v.match(semverRegEx);
            }
        };
    })();

    function defined(o){
        return (typeof o !== "undefined" && o !== null);
    }

    function parseTileJSON(tileJSON, options) {
        var context = {
            tileLayer: L.Util.extend({
                minZoom: 0,
                maxZoom: 22
            }, options.tileLayerConfig || {}),

            map: L.Util.extend({}, options.mapConfig || {}),

            crs: {},

            validation: {
                version: false
            }
        };

        for (var key in handlers) {
            if (defined(tileJSON[key])) {
                handlers[key](context, tileJSON[key], tileJSON);
            }
        }

        /*for (var validationKey in context.validation) {
            if (!context.validation[validationKey]) {
                throw new Error('Missing property "'
                    + validationKey + '".');
            }
        }*/

        if (defined(context.crs.projection)) {
            context.map.crs =
                new L.CRS.proj4js(
                    context.crs.code,
                    context.crs.projection,
                    context.crs.transformation);
            if (defined(context.crs.scale)) {
                context.map.crs.scale = context.crs.scale;
            }
            // TODO: only set to true if bounds is not the whole
            // world.
            context.tileLayer.continuousWorld = true;
        }

        return context;
    }

    function createTileLayer(context) {
    	var tUrls = context.tileUrls.reduce(reduceTiles,{url:"",domains:[]})
        var tileUrl = tUrls.url.replace(/(\%)+/,"{s}");
        context.tileLayer.subdomains=tUrls.domains;
        return new L.TileLayer(tileUrl, context.tileLayer);
    };
	function reduceTiles(a,b){
		if(a.url.length === 0){
			return {domains:[],url:b};
		}else{
			if(a.url.length == b.length){
				var len = a.url.length,out = [], i=0;
				while(i<len){
					if(a.url[i]!==b[i]){out.push(i);}
					i++;
				}if(a.domains.length === 0){
					a.domains.push(a.url.substr(out[0],out.length));

					a.url = a.url.slice(0,out[0])+(function(x){var i=0,out=[];while(i<x){out.push("%");i++};return out.join("")}(out.length))+a.url.slice(out[0]+out.length)
				}
				a.domains.push(b.substr(out[0],out.length));
				return a;
			}
		}
	}
    return {
        createMapConfig: function(tileJSON, cfg) {
            return parseTileJSON(tileJSON, {mapConfig: cfg}).map;
        },
        createTileLayerConfig: function(tileJSON, cfg) {
            return parseTileJSON(tileJSON, {tileLayerConfig: cfg}).tileLayer;
        },
        createTileLayer: function(tileJSON, cfg) {
            return createTileLayer(this.createMapConfig(tileJSON, cfg));
        },
        createMap: function(id, tileJSON, options) {
            var context = parseTileJSON(tileJSON, options || {});
            context.map.layers = [createTileLayer(context)];
            return new L.Map(id, context.map);
        }
    };
}());