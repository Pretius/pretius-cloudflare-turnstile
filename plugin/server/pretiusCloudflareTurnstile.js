/*!
 * Pretius Cloudflare Turnstile - Oracle APEX item plug-in
 * https://github.com/pretius/pretius-cloudflare-turnstile
 * MIT License
 */
/* global apex */
window.pretiusCloudflareTurnstile = window.pretiusCloudflareTurnstile || (function ($, apex) {
    "use strict";

    var VERSION = "26.1.0",
        LOG_PREFIX = "Pretius Cloudflare Turnstile:",
        ONLOAD_CALLBACK = "pretiusCloudflareTurnstileOnload",
        SCRIPT_ID = "pretius-cloudflare-turnstile-api",
        SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=" + ONLOAD_CALLBACK,
        queue = [],
        widgets = {},       // item name -> { widgetId, config }
        scriptFailed = false;

    function isApiReady() {
        return !!(window.turnstile && window.turnstile.render);
    }

    function setToken(itemName, value) {
        // Write straight to the hidden input: the token is not user data, so it
        // must not raise change events or trigger "unsaved changes" warnings.
        $("#" + $.escapeSelector(itemName)).val(value || "");
    }

    function currentResponse(itemName) {
        var widget = widgets[itemName];
        if (!widget || widget.widgetId === undefined || !isApiReady()) {
            return "";
        }
        return window.turnstile.getResponse(widget.widgetId) || "";
    }

    function registerItem(cfg) {
        apex.item.create(cfg.item, {
            item_type: "PRETIUS_CLOUDFLARE_TURNSTILE",
            isChanged: function () {
                return false;
            },
            // Required: once an item interface is created, APEX page submit
            // reads the value through getValue, not from the input directly.
            getValue: function () {
                return $("#" + $.escapeSelector(cfg.item)).val() || "";
            },
            setValue: function (value) {
                setToken(cfg.item, value);
            },
            setFocusTo: function () {
                return $("#" + $.escapeSelector(cfg.container));
            },
            // Client-side check used by apex.page.validate when a button
            // submits with validation. The server always verifies again.
            getValidity: function () {
                var valid = currentResponse(cfg.item) !== "";
                return { valid: valid, valueMissing: !valid };
            },
            getValidationMessage: function () {
                return currentResponse(cfg.item) !== "" ? "" : cfg.errorMessage;
            }
        });
    }

    function render(cfg) {
        var options = {
            sitekey: cfg.siteKey,
            theme: cfg.theme,
            size: cfg.size,
            appearance: cfg.appearance,
            callback: function (token) {
                setToken(cfg.item, token);
            },
            "expired-callback": function () {
                setToken(cfg.item, "");
            },
            "timeout-callback": function () {
                setToken(cfg.item, "");
            },
            "error-callback": function (code) {
                setToken(cfg.item, "");
                apex.debug.warn(LOG_PREFIX, "widget error for", cfg.item, code);
            }
        };

        if (cfg.action) {
            options.action = cfg.action;
        }

        try {
            widgets[cfg.item].widgetId = window.turnstile.render("#" + cfg.container, options);
        } catch (e) {
            apex.debug.error(LOG_PREFIX, "render failed for", cfg.item, e);
        }
    }

    function loadScript() {
        if (document.getElementById(SCRIPT_ID)) {
            return;
        }
        var script = document.createElement("script");
        script.id = SCRIPT_ID;
        script.src = SCRIPT_URL;
        script.async = true;
        script.defer = true;
        script.onerror = function () {
            scriptFailed = true;
            apex.debug.error(LOG_PREFIX, "could not load " + SCRIPT_URL +
                ". Check the network and the Content Security Policy (script-src and frame-src https://challenges.cloudflare.com).");
        };
        document.head.appendChild(script);
    }

    window[ONLOAD_CALLBACK] = function () {
        queue.splice(0).forEach(render);
    };

    // Each token can only be verified once. Once the page is actually being
    // submitted (after client-side validation), start a fresh challenge so a
    // failed server-side validation can be resubmitted. The submitted token is
    // left in the item: it is replaced when the new challenge completes.
    $(document).on("apexpagesubmit", function () {
        setTimeout(function () {
            Object.keys(widgets).forEach(function (itemName) {
                reset(itemName, true);
            });
        }, 0);
    });

    function reset(itemName, keepValue) {
        var widget = widgets[itemName];
        if (!widget || widget.widgetId === undefined || !isApiReady()) {
            return;
        }
        if (!keepValue) {
            setToken(itemName, "");
        }
        window.turnstile.reset(widget.widgetId);
    }

    return {
        /**
         * Called by the plug-in render procedure for every Turnstile item.
         * @param {Object} cfg item, container, siteKey, theme, size, appearance, action, errorMessage
         */
        init: function (cfg) {
            if (widgets[cfg.item]) {
                return;
            }
            widgets[cfg.item] = { config: cfg };
            registerItem(cfg);

            if (isApiReady()) {
                render(cfg);
                return;
            }
            queue.push(cfg);
            loadScript();
        },

        /** Clears the token and starts a new challenge for the item. */
        reset: function (itemName) {
            reset(itemName, false);
        },

        /** Returns the current token for the item, or "" if none. */
        getResponse: function (itemName) {
            return currentResponse(itemName);
        },

        /** True when the Cloudflare script could not be loaded. */
        hasLoadError: function () {
            return scriptFailed;
        },

        getVersion: function () {
            return VERSION;
        }
    };
})(apex.jQuery, apex);
