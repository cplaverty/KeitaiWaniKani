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
