if (window.location.hostname.endsWith('wanikani.com') &&
    (window.location.pathname.startsWith('/review/session') || window.location.pathname.startsWith('/lesson/session'))) {
    addStyle(
        '#reviews #question #character, #lessons header.quiz #main-info #character { font-size: 10vh !important; line-height: 15vh !important; padding: 20px 20px 0px; }' +
        '@media (max-width: 767px) {' +
             '#answer-form { font-size: 1.25em; }' +
             '#summary-button, #header-buttons, #reviews #stats, #lessons #stats { font-size: 14px; }' +
        '}'
    )
}