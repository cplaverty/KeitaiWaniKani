// ==UserScript==
// @name          WaniKani Show Specific SRS Level in Reviews
// @namespace     https://www.wanikani.com
// @description   Show "Apprentice 3" instead of "Apprentice", etc.
// @author        seanblue
// @version       1.0.1
// @include       *://www.wanikani.com/review/session*
// @grant         none
// ==/UserScript==

const eventPrefix = 'seanblue.show_specific_srs.';

// Catch additional events.
// http://viralpatel.net/blogs/jquery-trigger-custom-event-show-hide-element/
(function($) {$.each(['hide'], function(i, ev) { var el = $.fn[ev]; $.fn[ev] = function() { this.trigger(eventPrefix + ev); return el.apply(this, arguments); }; }); })(jQuery);

(function() {
    'use strict';

    function updateSrsNames() {
        window.Srs.name = function(e) {
            switch (e) {
                case 1:
                    return "apprentice1";
                case 2:
                    return "apprentice2";
                case 3:
                    return "apprentice3";
                case 4:
                    return "apprentice4";
                case 5:
                    return "guru1";
                case 6:
                    return "guru2";
                case 7:
                    return "master";
                case 8:
                    return "enlighten";
                case 9:
                    return "burn";
            }
        };
    }

    (function() {
        $('#loading:visible').on(eventPrefix + 'hide', function() {
            updateSrsNames();
        });
    })();
})();
