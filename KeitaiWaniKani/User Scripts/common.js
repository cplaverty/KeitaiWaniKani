// startsWith and endsWith are not (currently) defined by WKWebView
if (typeof String.prototype.startsWith != 'function') {
    String.prototype.startsWith = function (str){
        return this.slice(0, str.length) == str;
    };
}
if (typeof String.prototype.endsWith != 'function') {
    String.prototype.endsWith = function (str){
        return this.slice(-str.length) == str;
    };
}

function addStyle(aCss) {
    var head, style;
    head = document.getElementsByTagName('head')[0];
    if (head) {
        style = document.createElement('style');
        style.setAttribute('type', 'text/css');
        style.textContent = aCss;
        head.appendChild(style);
        return style;
    }
    return null;
}

function addScript(aScript) {
    var head, script;
    head = document.getElementsByTagName('head')[0];
    if (head) {
        script = document.createElement('script');
        script.setAttribute('type', 'text/javascript');
        script.textContent = aScript;
        head.appendChild(script);
        return script;
    }
    return null;
}

function linkStyleSheet(location) {
    var head, link;
    head = document.getElementsByTagName('head')[0];
    if (head) {
        link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('type', 'text/css');
        link.setAttribute('href', location);
        head.appendChild(link);
        return link;
    }
    return null;
}

function linkScript(location) {
    var head, script;
    head = document.getElementsByTagName('head')[0];
    if (head) {
        script = document.createElement('script');
        script.setAttribute('type', 'text/javascript');
        script.setAttribute('src', location);
        head.appendChild(script);
        return script;
    }
    return null;
}
