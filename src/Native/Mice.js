
var _minekoa$elm_text_editor$Native_Mice = function() {

    function ensureVisible( frame_id, target_id ) {
        /*
         * TODO:
         *    * marginでごまかしているが、行番号カラムを考慮したスクロールをしないと、左移動しても行番号が出きらない問題がある
         */

        requestAnimationFrame( () => {
            /* note:
             *     requestAnimationFrame は、描画更新をまつため .. だったのだけれど
             *     効いたり効かなかったりする
             *         * 複数行のペーストのときには、これがないと正しくカーソルが見えない
             *         * フレーム外にカーソルがいる時の、タップでのカーソル移動だと、何故か上手く行かない
             *     (?? カーソルの点滅制御が悪さしてる ??)
             */

            const frame  = document.getElementById(frame_id);
            const target = document.getElementById(target_id);
            if (frame == null || target == null) {
                return false;
            }

            const frame_rect  =  frame.getBoundingClientRect();
            const target_rect =  target.getBoundingClientRect()
            const margin = target_rect.height * 2.1;

            /* dbg */
            console.log( "B: frm: top=" + frame_rect.top.toString()  + " left=" + frame_rect.left.toString()  + " bottom=" + frame_rect.bottom.toString()  + " right=" + frame_rect.right.toString()  );
            console.log( "B: tgt: top=" + target_rect.top.toString() + " left=" + target_rect.left.toString() + " bottom=" + target_rect.bottom.toString() + " right=" + target_rect.right.toString() );

            /* vertincal */
            var new_scr_top = null;
            if      ( target_rect.top    - margin < frame_rect.top    ) {
                new_scr_top = frame.scrollTop + (target_rect.top - frame_rect.top) - margin;
            }
            else if ( target_rect.bottom + margin > frame_rect.bottom ) {
                new_scr_top = frame.scrollTop + (target_rect.bottom - frame_rect.bottom) + margin;
            }

            /* horizontal */
            var new_scr_left = null;
            if      ( target_rect.left  - margin < frame_rect.left ) {
                new_scr_left = frame.scrollLeft + (target_rect.left - frame_rect.left) - margin;
            }
            else if ( target_rect.right + margin > frame_rect.right ) {
                new_scr_left = frame.scrollLeft + (target_rect.right - frame_rect.right) + margin;
            }

            /* set scroll pos */
            if (new_scr_top  != null) {
                frame.scrollTop  = new_scr_top;
            }
            if (new_scr_left != null) {
                frame.scrollLeft = new_scr_left;
            }

            return (new_scr_top != null) || (new_scr_left != null);
        } );

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

        return w;
    }

    function getBoundingClientRect(_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return {"left":0, "top":0, "right":0, "bottom":0, "x":0, "y":0, "width":0, "height":0};
        }
        const rect = element.getBoundingClientRect();
        return rect;
    }

    function getBoundingPageRect(_id) {
        const element = document.getElementById(_id); 
        if (element == null) {
            return {"left":0, "top":0, "right":0, "bottom":0, "x":0, "y":0, "width":0, "height":0};
        }
        const rect = element.getBoundingClientRect();
        const scrollX = window.pageXOffset;
        const scrollY = window.pageYOffset;

        return { "left": rect.left + scrollX,
                 "top" : rect.top  + scrollY,
                 "right": rect.right + scrollX,
                 "bottom": rect.bottom + scrollY,
                 "x"     : (rect.x ? rect.x : rect.left) + scrollX,
                 "y"     : (rect.y ? rect.y : rect.reft) + scrollY,
                 "width" : rect.width,
                 "height": rect.height,
               }
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
        input_area.isComposing = false;
        console.log("regist inpt-ctrl event handlers");


        /* IMEを考慮した input_area のクリア制御
         *      - input
         *      - compositionend
         * note:
         *   一見 Elm 世界でやれそうに見えるが、
         *   TEA は、1周の処理が終えるまでの間、 以降のJSイベントを待たせてくれるわけではないので、
         *   結果、イベントが非同期となってしまい、状態遷移が上手く行かない。
         *   よって、JS 世界で行う必要がある
         */

        input_area.addEventListener( "input", e => {
            if (!input_area.isComposing) {
                input_area.value = "";
            }
        });

        input_area.addEventListener( "compositionstart", e => {
            input_area.isComposing = true; /* EdgeがKeyboardEvent.isComposingに対応したら自前でフラグ管理するのやめたい...*/
        });

        input_area.addEventListener( "compositionend", e => {
            /* chrome と firefox の挙動を違いを吸収するため、valueをここでクリアする
             *
             *     chrome  :: keydown 229 -> compositionUpdate s -> compositionend s -> (null)
             *     firefox ::   (null)    ->     (null)          -> compositionend s -> input s
             *
             * compositionEnd で、textarea.valueをクリアすれば、
             * firefoxの最後の `input s` の s を空文字にできる(後はelm側で切り分ければ良い)
             */

            input_area.value = "";
            input_area.isComposing = false;
        });



        /* クリップボード制御
         *      - paste
         *      - copy
         *      - cut
         * note:
         *   クリップボードイベントはセキュリティのため、
         *   イベントハンドラ内でないと、クリップボードに対する操作ができない
         *   (Firefox は厳しくブロックしてくる為、paste を execCommand でTEAから叩く手段もダメ)
         */

        input_area.addEventListener( "paste", pasteEventListener );
        input_area.addEventListener( "copy" , copyEventListener );
        input_area.addEventListener( "cut"  , cutEventListener );

        return true;
    }





    function elaborateTapArea(id_tap_area) {
        const tap_area = document.getElementById(id_tap_area);
        if (tap_area == null) {
            return false;
        }

        if (tap_area.tap_controll_handlers_registerd) {
            return true;
        }
        tap_area.tap_controll_handlers_registerd = true;
        console.log("regist tap-ctrl event handlers");

        tap_area.addEventListener( "mousedown", e => {
            if (e.button == 2) { /* RightClick*/
                tap_area.focus();
                document.execCommand('SelectAll');
            }
        });

        tap_area.addEventListener( "paste", pasteEventListener );
        tap_area.addEventListener( "copy" , copyEventListener );
        tap_area.addEventListener( "cut"  , cutEventListener );

        return true;
    }


    /**
     * クリップボードイベントハンドラ
     *     clipboardイベントを処理した後、
     *     Elm世界の状態を合わせるため、clipboard への操作・からの操作を
     *     カスタムイベントで事後通知する
     *     また、Elm世界からclipboardに渡すデータは、
     *     イベント登録先オブジェクトのカスタム属性 selecteddata に設定されている
     */

    function pasteEventListener (e) {
        e.preventDefault();

        const data_transfer = (e.clipboardData) || (window.clipboardData);
        const str = data_transfer.getData("text/plain");

        const evt = new CustomEvent("pasted", { "bubbles": true,
                                                "cancelable": true,
                                                "detail": str
                                              }
                                   );
        this.dispatchEvent(evt);
    }

    function copyEventListener (e) {
        e.preventDefault();

        const str = this.selecteddata
        e.clipboardData.setData('text/plain', str);

        const evt = new CustomEvent("copied", { "bubbles": true,
                                                "cancelable": true,
                                                "detail": str
                                              }
                                   );
        this.dispatchEvent(evt);
    }

    function cutEventListener (e) {
        e.preventDefault();

        const str = this.selecteddata
        e.clipboardData.setData('text/plain', str);

        const evt = new CustomEvent("cutted", { "bubbles": true,
                                                "cancelable": true,
                                                "detail": str
                                              }
                                   );
        this.dispatchEvent(evt);
    }



  return {
      ensureVisible: F2(ensureVisible),
      calcTextWidth: F2(calcTextWidth),
      getBoundingClientRect: getBoundingClientRect,
      getBoundingPageRect : getBoundingPageRect,
      elaborateInputArea : elaborateInputArea,
      elaborateTapArea : elaborateTapArea,
  }
}();

