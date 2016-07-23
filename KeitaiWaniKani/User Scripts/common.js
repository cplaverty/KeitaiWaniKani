// GreaseMonkey stub for inserting style element
function GM_addStyle(cssContents) {
    var style = document.createElement('style');
    style.setAttribute('type', 'text/css');
    style.appendChild(document.createTextNode(cssContents));
    document.head.appendChild(style);
}


// Add close button to timeout full-screen popup
$('#timeout').prepend('<button id="timeout-close" type="button">&times;</button>');

$(document).on('click', '#timeout-close', function() {
    $('#timeout-idle').hide();
    $('#timeout-session-end').hide();
    $('#timeout').hide();
});


// Use email keyboard for user login input
var userLogin = document.getElementById('user_login');
if (userLogin !== null) {
    userLogin.type = 'email';
}


// Update navigation controller title
function setTitleToCurrentQuizItem() {
    if (typeof setWebViewPageTitle !== "function") return;
    
    // "Fake" radicals can either be represented by a custom font using <i class="radical-xxx"> or an image
    if ($('#character img').length > 0 || $('#character i').length > 0) {
        setWebViewPageTitle('Radical');
        return;
    }
    var quizItemText = $.trim($('#character').text());
    setWebViewPageTitle(quizItemText);
}

var ob = new MutationObserver(setTitleToCurrentQuizItem);
var reviews = document.getElementById('reviews')
if (reviews !== null) {
    console.log('Is reviewing');
    ob.observe(reviews, {subtree: true, childList: true, attribute: false});
} else {
    var lessons = document.getElementById('main-info');
    if (lessons !== null) {
        console.log('Is new lessons');
        ob.observe(lessons, {subtree: true, childList: true, attribute: false});
    }
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
