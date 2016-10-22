var GifBlender = function ()
{

};

GifBlender.prototype.blend = function (success, fail, options)
{
    if (!options) {
        options = {};
    }

    var params = {
        fileURL: options.fileURL ? options.fileURL : null,
        cssPath: options.cssPath ? options.cssPath : null,
        overlay: options.overlay ? options.overlay : null,
        htmlString: options.htmlString ? options.htmlString : null,
    };

    return cordova.exec(success, fail, "GifBlender", "blend", [params]);

};

window.gifBlender = new GifBlender();
