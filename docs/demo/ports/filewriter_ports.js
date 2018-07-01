"use strict";

const filewriter_ports = function () {

    function elaborate (app) {

        app.ports.filer_saveFile.subscribe( ([fname, content]) => {
            const URL = window.URL || window.webkitURL;
            const blob = new Blob( [content], {"type" : "text/plain"} );

            const a = document.createElement("a");
            a.href     = URL.createObjectURL(blob);
            a.download = fname;

            a.click();
            URL.revokeObjectURL( a.href );
        });

    }

    return { elaborate: elaborate };
}();

