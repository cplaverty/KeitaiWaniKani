function GM_addStyle(cssContents) {
    var style = document.createElement('style');
    style.setAttribute('type', 'text/css');
    style.appendChild(document.createTextNode(cssContents));
    document.head.appendChild(style);
}
