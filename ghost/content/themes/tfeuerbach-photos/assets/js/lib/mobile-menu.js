(function () {
    'use strict';

    // Only run on mobile
    if (window.innerWidth > 768) return;

    // Get existing elements
    var darkModeToggle = document.querySelector('.gh-head-actions .gh-color-mode-toggle');
    var searchBtn = document.querySelector('.gh-head-actions .gh-search');
    
    if (!darkModeToggle && !searchBtn) return;

    // Create bottom nav
    var bottomNav = document.createElement('div');
    bottomNav.className = 'mobile-bottom-nav';

    // Create hamburger button
    var burger = document.createElement('button');
    burger.className = 'mobile-burger';
    burger.setAttribute('aria-label', 'Toggle menu');

    // Clone dark mode toggle
    var darkModeClone = null;
    if (darkModeToggle) {
        darkModeClone = darkModeToggle.cloneNode(true);
        // Copy click handler by triggering original on clone click
        darkModeClone.addEventListener('click', function(e) {
            e.preventDefault();
            darkModeToggle.click();
        });
    }

    // Clone search button
    var searchClone = null;
    if (searchBtn) {
        searchClone = searchBtn.cloneNode(true);
        searchClone.addEventListener('click', function(e) {
            e.preventDefault();
            searchBtn.click();
        });
    }

    // Add buttons to nav (order: burger, dark mode, search)
    bottomNav.appendChild(burger);
    if (darkModeClone) bottomNav.appendChild(darkModeClone);
    if (searchClone) bottomNav.appendChild(searchClone);

    // Add to body
    document.body.appendChild(bottomNav);

    // Hamburger click handler - toggle Ghost's menu
    burger.addEventListener('click', function(e) {
        e.preventDefault();
        document.body.classList.toggle('is-head-open');
    });

    // Close menu when clicking a nav link
    var navLinks = document.querySelectorAll('.gh-head-menu .nav a');
    navLinks.forEach(function(link) {
        link.addEventListener('click', function() {
            document.body.classList.remove('is-head-open');
        });
    });

    // Handle resize - hide/show bottom nav
    var mediaQuery = window.matchMedia('(max-width: 768px)');
    function handleResize(e) {
        if (e.matches) {
            bottomNav.style.display = 'flex';
        } else {
            bottomNav.style.display = 'none';
            document.body.classList.remove('is-head-open');
        }
    }
    mediaQuery.addListener(handleResize);
})();
