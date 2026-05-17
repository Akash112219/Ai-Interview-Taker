(function () {
    var THEME_KEY = 'ai_interviewer_theme';
    var CURRENCY_KEY = 'ai_interviewer_currency';

    var rates = {
        USD: 1,
        INR: 83.2,
        PKR: 278,
        EUR: 0.92
    };

    var symbols = {
        USD: '$',
        INR: '₹ ',
        PKR: '₨ ',
        EUR: '€ '
    };

    function formatPrice(usd, currency) {
        var value = usd * rates[currency];

        if (currency === 'INR') {
            return symbols[currency] + Math.round(value).toLocaleString('en-IN');
        }

        if (currency === 'PKR') {
            return symbols[currency] + Math.round(value).toLocaleString('en-PK');
        }

        if (Number.isInteger(value)) {
            return symbols[currency] + value.toString();
        }

        return symbols[currency] + value.toFixed(2);
    }

    function applyCurrency(currency) {
        var selectedCurrency = rates[currency] ? currency : 'USD';

        document.querySelectorAll('[data-currency-select]').forEach(function (select) {
            select.value = selectedCurrency;
        });

        document.querySelectorAll('[data-price-usd]').forEach(function (el) {
            var baseUsd = Number(el.getAttribute('data-price-usd') || 0);
            el.textContent = formatPrice(baseUsd, selectedCurrency);
        });

        try {
            localStorage.setItem(CURRENCY_KEY, selectedCurrency);
        } catch (err) {
            // Ignore storage errors in restricted contexts.
        }
    }

    function applyTheme(theme) {
        var selectedTheme = theme === 'light' ? 'light' : 'dark';
        document.body.classList.toggle('light-mode', selectedTheme === 'light');
        document.documentElement.classList.toggle('dark', selectedTheme === 'dark');

        document.querySelectorAll('[data-theme-toggle]').forEach(function (btn) {
            var icon = selectedTheme === 'light' ? 'mdi:weather-night' : 'mdi:weather-sunny';
            var label = selectedTheme === 'light' ? 'Dark Mode' : 'Light Mode';
            btn.setAttribute('aria-label', label);
            if (btn.hasAttribute('data-theme-icon-only')) {
                btn.innerHTML = '<span class="iconify text-base" data-icon="' + icon + '"></span>';
            } else {
                btn.innerHTML = '<span class="iconify text-base" data-icon="' + icon + '"></span>' + label;
            }
        });

        try {
            localStorage.setItem(THEME_KEY, selectedTheme);
        } catch (err) {
            // Ignore storage errors in restricted contexts.
        }
    }

    function initHeaderControls() {
        var storedTheme = 'dark';
        var storedCurrency = 'USD';

        try {
            storedTheme = localStorage.getItem(THEME_KEY) || 'dark';
            storedCurrency = localStorage.getItem(CURRENCY_KEY) || 'USD';
        } catch (err) {
            // Ignore storage errors in restricted contexts.
        }

        document.querySelectorAll('[data-currency-select]').forEach(function (select) {
            select.addEventListener('change', function (event) {
                applyCurrency(event.target.value);
            });
        });

        document.querySelectorAll('[data-theme-toggle]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var nextTheme = document.body.classList.contains('light-mode') ? 'dark' : 'light';
                applyTheme(nextTheme);
            });
        });

        applyCurrency(storedCurrency);
        applyTheme(storedTheme);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initHeaderControls);
    } else {
        initHeaderControls();
    }
})();
