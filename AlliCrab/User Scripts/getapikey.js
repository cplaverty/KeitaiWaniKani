$.get('/settings/account').done(function(data, textStatus, jqXHR) {
    var apiKey = $(data).find('#user_api_key').attr('value');
    if (typeof apiKey === 'string') {
        window.webkit.messageHandlers.apiKey.postMessage(apiKey);
    }
}).fail(function(jqXHR, textStatus) {
    window.webkit.messageHandlers.apiKeyError.postMessage(textStatus);
});
