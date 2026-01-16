(function () {
    const toggle = document.querySelector('.gh-color-mode-toggle');
    if (!toggle) return;

    const body = document.body;
    const isDarkMode = localStorage.getItem('darkMode') === 'true';

    if (isDarkMode) {
        body.classList.add('dark-mode');
    }

    toggle.addEventListener('click', function () {
        body.classList.toggle('dark-mode');
        localStorage.setItem('darkMode', body.classList.contains('dark-mode'));
    });
})();

