if (window.location.hostname.endsWith('wanikani.com') &&
    (window.location.pathname.startsWith('/review/session') || window.location.pathname.startsWith('/lesson/session'))) {
    addStyle(
        '#reviews #question #character, #lessons header.quiz #main-info #character { font-size: 10vh !important; line-height: 20vh !important }' +
        '@media (max-width: 767px) { #answer-form { font-size: 1.3em } #summary-button, #stats { font-size: 16px } }'
    )
}