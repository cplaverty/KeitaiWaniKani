// GreaseMonkey stub for inserting style element
function GM_addStyle(cssContents) {
    var style = document.createElement('style');
    style.setAttribute('type', 'text/css');
    style.appendChild(document.createTextNode(cssContents));
    document.head.appendChild(style);
}


// Add close button to timeout full-screen popup
$('#timeout').prepend('<button id="timeout-close" type="button">&times;</button>');

$(document).on('touchstart', '#timeout-close', function(e) {
    e.preventDefault();
    $("html, body").css("overflow", "");
    $('#timeout-idle').hide();
    $('#timeout-session-end').hide();
    $('#timeout').hide();
});

// Once the timeout screen is shown, every time the web view is resized overflow: hidden is set again.
// We overwrite idleTime.view so that this only happens if #timeout is visible
if (this.idleTime !== undefined) {
    this.idleTime.view = function() {
        var setTimeoutPadding = function() {
            var t = $(window).innerHeight();
            var e = $("#timeout div");
            e.css("padding-top", (t - e.height()) / 2)
            $("html, body").css("overflow", "hidden")
        };
        
        $("#timeout").show();
        $("#timeout-idle").show();
        setTimeoutPadding();
        $(window).resize(function() {
            if ($("#timeout").is(":hidden")) return;
            
            setTimeoutPadding();
        });
    };
}


// Use email keyboard for user login input
var userLogin = $('#user_login');
if (userLogin !== null) {
    userLogin.prop('type', 'email');
    userLogin.attr('style', 'width: 100%;');
    userLogin.removeAttr('size');
    
    $('#new_user').attr('novalidate', 'novalidate');
    $('#user_remember_me').prop('checked', true);
}


// Polyfills

// String.repeat (Jitai)
if (!String.prototype.repeat) {
    String.prototype.repeat = function(count) {
        'use strict';
        if (this == null) {
            throw new TypeError('can\'t convert ' + this + ' to object');
        }
        var str = '' + this;
        count = +count;
        if (count != count) {
            count = 0;
        }
        if (count < 0) {
            throw new RangeError('repeat count must be non-negative');
        }
        if (count == Infinity) {
            throw new RangeError('repeat count must be less than infinity');
        }
        count = Math.floor(count);
        if (str.length == 0 || count == 0) {
            return '';
        }
        // Ensuring count is a 31-bit integer allows us to heavily optimize the
        // main part. But anyway, most current (August 2014) browsers can't handle
        // strings 1 << 28 chars or longer, so:
        if (str.length * count >= 1 << 28) {
            throw new RangeError('repeat count must not overflow maximum string size');
        }
        var rpt = '';
        for (;;) {
            if ((count & 1) == 1) {
                rpt += str;
            }
            count >>>= 1;
            if (count == 0) {
                break;
            }
            str += str;
        }
        // Could we try:
        // return Array(count + 1).join(this);
        return rpt;
    }
}
