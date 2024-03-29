// --
// Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

// taken from: http://stackoverflow.com/a/2641047
// [name] is the name of the event "click", "mouseover", ..
// same as you'd pass it to on()
// [fn] is the handler function
$.fn.unshiftOn = function(name, fn) {
    // on as you normally would
    // don't want to miss out on any jQuery magic
    this.on(name, fn);

    // Thanks to a comment by @Martin, adding support for
    // namespaced events too.
    this.each(function() {
        var handlers = $._data(this, 'events')[name.split('.')[0]];

        // take out the handler we just inserted from the end
        var handler = handlers.pop();
        // move it at the beginning
        handlers.splice(0, 0, handler);
    });
};

Core.AJAX.FunctionCallSynchronous = function (URL, Data, Callback, DataType) {

    // store the original state
    // this is basically an example how to access
    // the current state of the $.ajaxSetup values
    var OriginalAsyncState = $.ajaxSetup()['async'];

    // make a custom callback that gets passed to the standard Core.AJAX.FunctionCall
    // that resets back to asynchronous AJAX calls as before and executes the regualar
    // given Callback function as usual
    var ResetCallback = function (Response) {

        // set requests back to asynchronous
        $.ajaxSetup({
            async: OriginalAsyncState
        });

        // call given callback function as usual
        Callback(Response);
    };

    // set this request as synchronous
    $.ajaxSetup({
        async: false
    });

    // start the wanted request by the framework functionality with our
    // manipulated callback function and disabled async flag
    Core.AJAX.FunctionCall(URL, Data, ResetCallback, DataType);
};
