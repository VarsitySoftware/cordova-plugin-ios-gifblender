var GifBlender = function ()
{

};

GifBlender.prototype.blend = function (success, fail, options)
{
    if (!options) {
        options = {};
    }

    var params = {
        url: options.url ? options.url : null,
        filter: options.filter ? options.filter : null,
        cssPath: options.cssPath ? options.cssPath : null,
        overlayBase64: options.overlayBase64 ? options.overlayBase64 : null,
        loadDelay: options.loadDelay ? options.loadDelay : null,
        quality: options.quality ? options.quality : 0
    };

    return cordova.exec(success, fail, "GifBlender", "blend", [params]);

};

window.gifBlender = new GifBlender();
