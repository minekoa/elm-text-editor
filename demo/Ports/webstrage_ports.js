"use strict";

const webstrage_ports = function () {

    function elaborate (app) {

        app.ports.localStrage_setItem.subscribe( ([key, value]) => {
            const strage = window.localStorage;
            try {
                strage.setItem( key, value );
                app.ports.localStrage_setItemEnded.send( [key, true]);
            }
            catch (e) {
                app.ports.localStrage_setItemEnded.send( [key, false] );
            }
        });

        app.ports.localStrage_getItem.subscribe( (key) => {
            const strage = window.localStorage;
            try {
                const val = strage.getItem( key );
                app.ports.localStrage_getItemEnded.send( [key, val] );
            }
            catch (e) {
                app.ports.localStrage_getItemEnded.send( [key, null] );
            }
        });

        app.ports.localStrage_removeItem.subscribe( ([key, value]) => {
            const strage = window.localStorage;
            try {
                strage.removeItem( key );
                app.ports.localStrage_removeItemEnded.send( [key, true] );
            }
            catch (e) {
                app.ports.localStrage_removeItemEnded.send( [key, false] );
            }
        });

        app.ports.localStrage_clear.subscribe( (x) => {
            const strage = window.localStorage;
            strage.clear();
        });

    }

    return { elaborate: elaborate };
}();

