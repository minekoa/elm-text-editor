
var _minekoa$elm_text_editor$Native_Mice = function() {

    function doFocus(_id) { 
        const element = document.getElementById(_id); 
        if (element == null) {
            return false;
        }

        element.focus();
        return true;
    }

    function calcTextWidth(_id, txt) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return 0;
        }
        element.textContent = txt;
        const w = element.offsetWidth;
        element.textContent = null;

        return w
    }

    function getBoundingClientRect(_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return {"left":0, "top":0, "right":0, "bottom":0, "x":0, "y":0, "width":0, "height":0};
        }
        const rect = element.getBoundingClientRect();
        return rect;
    }

    function elaborateInputArea(id_input_area) {
        const input_area = document.getElementById(id_input_area);
        if (input_area == null) {
            return false;
        }

        if (input_area.input_controll_handlers_registerd) {
            return true;
        }
        input_area.input_controll_handlers_registerd = true;
        console.log("regist inpt-ctrl event handlers");


        input_area.addEventListener( "keydown", e => {
            if (e.target.id != id_input_area) {
                return true;
            }


            if (e.ctrlKey && (e.keyCode == 86 || e.keyCode == 67 || e.keyCode == 88)) { /* C-v : pasteイベントは生かしておきたい */
                ;
            }
            else if (e.altKey || e.ctrlKey) {
                e.preventDefault();
            }
            switch (e.keyCode) {
            case 37: /* '←' .. スクロールが発生してしまうことがある */
            case 38: /* '↑' */
            case 39: /* '→' */
            case 40: /* '↓' */ 
                e.preventDefault();
                break;
            }
        });

        input_area.addEventListener( "input", e => {
            if (!input_area.enableComposer) {
                input_area.value = "";
            }
        });

        input_area.addEventListener( "compositionstart", e => {
            input_area.enableComposer = true;
        });

        input_area.addEventListener( "compositionend", e => {
            input_area.value = "";
        });

        input_area.addEventListener( "keypress", e => {

            /* IME入力中にkeypress イベントがこないことを利用して IME入力モード(inputを反映するか否かのフラグ）を解除
             *  ※ compositonEnd で解除してしまうと、firefoxとchromeの振る舞いの違いでハマる
             *        chrome  :: keydown 229 -> compositionend s
             *        firefox ::   (null)    -> compositionend s -> input s
             */

            input_area.enableComposer = false;
        });

        input_area.addEventListener( "paste", e => {
            e.preventDefault();

            const data_transfer = (e.clipboardData) || (window.clipboardData);
            const str = data_transfer.getData("text/plain");

            const evt = new CustomEvent("pasted", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });

        input_area.addEventListener( "copy", e => {
            e.preventDefault();

            const str = input_area.selecteddata
            e.clipboardData.setData('text/plain', str);

            const evt = new CustomEvent("copied", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });

        input_area.addEventListener( "cut", e => {
            e.preventDefault();

            const str = input_area.selecteddata
            e.clipboardData.setData('text/plain', str);

            const evt = new CustomEvent("cutted", { "bubbles": true,
                                                    "cancelable": true,
                                                    "detail": str
                                                  }
                                       );
            input_area.dispatchEvent(evt);
        });


        return true;
    }


    /* Scrolling */

    function getScrollTop (_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return -1;
        }
        return element.scrollTop;
    }

    function setScrollTop (_id, pixels) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return false;
        }
        element.scrollTop = pixels;
        return true
    }

    function getScrollLeft (_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return -1;
        }
        return element.scrollLeft;
    }

    function setScrollLeft (_id, pixels) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return false;
        }
        element.scrollLeft = pixels;
        return true
    }

    function getScrollHeight (_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return 0;
        }
        return element.scrollHeight;
    }



  return {
      doFocus: doFocus,
      calcTextWidth: F2(calcTextWidth),
      getBoundingClientRect: getBoundingClientRect,
      elaborateInputArea : elaborateInputArea,
      getScrollTop: getScrollTop,
      setScrollTop: F2(setScrollTop),
      getScrollLeft: getScrollLeft,
      setScrollLeft: F2(setScrollLeft),
      getScrollHeight: getScrollHeight
  }
}();

