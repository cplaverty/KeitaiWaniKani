$.get('/account').done(function(data, textStatus, jqXHR) {
    var apiKey = $(data).find('#api-button').parent().find('input').attr('value');
    if (typeof apiKey === 'string') {
        window.webkit.messageHandlers.apiKey.postMessage(apiKey);
    }
}).fail(function(jqXHR, textStatus) {
    window.webkit.messageHandlers.apiKeyError.postMessage(textStatus);
});
