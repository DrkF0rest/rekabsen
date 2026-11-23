/**
 * REKABSEN Application Script
 * JavaScript entry point for the REKABSEN web application.
 *
 * This file is a companion to app/app.html and app/css/style.css.
 * Landing page interactions are handled inline within index.html.
 */

'use strict';

/* ---- Utility helpers ---- */

/**
 * Query selector shorthand.
 * @param {string} selector
 * @param {Element} [scope=document]
 * @returns {Element|null}
 */
const $ = (selector, scope = document) => scope.querySelector(selector);

/**
 * Query selector all shorthand.
 * @param {string} selector
 * @param {Element} [scope=document]
 * @returns {NodeList}
 */
const $$ = (selector, scope = document) => scope.querySelectorAll(selector);

/**
 * Write text to clipboard with legacy fallback.
 * @param {string} text
 * @returns {Promise<void>}
 */
const copyToClipboard = async (text) => {
    if (navigator.clipboard) {
        return navigator.clipboard.writeText(text);
    }
    const area = document.createElement('textarea');
    area.value = text;
    area.style.cssText = 'position:fixed;opacity:0;';
    document.body.appendChild(area);
    area.focus();
    area.select();
    document.execCommand('copy');
    document.body.removeChild(area);
};

/**
 * Debounce a function call.
 * @param {Function} fn
 * @param {number} delay
 * @returns {Function}
 */
const debounce = (fn, delay) => {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
};

/* ---- App initialisation ---- */

document.addEventListener('DOMContentLoaded', () => {
    // Application bootstrap goes here.
    // This script is intentionally minimal.
    // Feature-specific modules should be imported or appended below.
    console.info('[REKABSEN] App initialised.');
});
