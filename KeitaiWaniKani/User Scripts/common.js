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
