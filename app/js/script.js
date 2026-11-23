/* ============================================================
   REKABSEN — Landing Page Scripts
   File: /app/js/script.js
   ============================================================ */
'use strict';

document.getElementById('footerYear').textContent = new Date().getFullYear();

/* ---- Sticky nav ---- */
const nav = document.getElementById('nav');
const onScroll = () => { nav.classList.toggle('scrolled', window.scrollY > 20); };
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

/* ---- Active nav link ---- */
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-link');
const activeLinkObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      navLinks.forEach(link => {
        link.classList.toggle('active', link.getAttribute('href') === `#${entry.target.id}`);
      });
    }
  });
}, { rootMargin: '-50% 0px -50% 0px' });
sections.forEach(s => activeLinkObserver.observe(s));

/* ---- Mobile menu ---- */
const toggle = document.getElementById('navToggle');
const drawer = document.getElementById('navDrawer');
const closeDrawer = () => {
  toggle.classList.remove('open');
  drawer.classList.remove('open');
  toggle.setAttribute('aria-expanded', 'false');
};
toggle.addEventListener('click', () => {
  const isOpen = drawer.classList.toggle('open');
  toggle.classList.toggle('open', isOpen);
  toggle.setAttribute('aria-expanded', String(isOpen));
});
drawer.querySelectorAll('a').forEach(link => link.addEventListener('click', closeDrawer));
document.addEventListener('click', (e) => {
  if (!nav.contains(e.target) && !drawer.contains(e.target)) closeDrawer();
});

/* ---- Scroll reveal ---- */
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

/* ---- Toast ---- */
let toastTimer;
const toastEl = document.getElementById('toast');
const toastMsg = document.getElementById('toastMsg');
const showToast = (msg) => {
  toastMsg.textContent = msg;
  toastEl.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2200);
};

/* ---- Copy to clipboard ---- */
const copyText = async (text, btnEl, label) => {
  try {
    await navigator.clipboard.writeText(text);
    showToast(label || 'Copied to clipboard!');
    if (btnEl) {
      btnEl.classList.add('copied');
      const icon = btnEl.querySelector('i');
      const span = btnEl.querySelector('span');
      if (icon) {
        const orig = icon.className;
        icon.className = 'fa-solid fa-check';
        setTimeout(() => { icon.className = orig; }, 1800);
      }
      if (span) {
        const orig = span.textContent;
        span.textContent = 'Copied!';
        setTimeout(() => { span.textContent = orig; }, 1800);
      }
      setTimeout(() => btnEl.classList.remove('copied'), 1800);
    }
  } catch {
    const area = document.createElement('textarea');
    area.value = text;
    area.style.cssText = 'position:fixed;opacity:0;';
    document.body.appendChild(area);
    area.focus(); area.select();
    document.execCommand('copy');
    document.body.removeChild(area);
    showToast(label || 'Copied to clipboard!');
  }
};

/* ---- Hero copy ---- */
document.getElementById('heroCopyBtn').addEventListener('click', function () {
  copyText(this.dataset.copy, this, 'Install command copied!');
});

/* ---- Tabbed install terminal ---- */
const tabs = document.querySelectorAll('.terminal-tab');
const panels = document.querySelectorAll('.terminal-panel');
const copyBtn = document.getElementById('installCopyBtn');

tabs.forEach(tab => {
  tab.addEventListener('click', () => {
    tabs.forEach(t => { t.classList.remove('active'); t.setAttribute('aria-selected', 'false'); });
    panels.forEach(p => p.classList.remove('active'));

    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');
    const panel = document.getElementById('panel-' + tab.dataset.tab);
    if (panel) panel.classList.add('active');

    // reset copy button state
    copyBtn.classList.remove('copied');
    const icon = copyBtn.querySelector('i');
    const span = copyBtn.querySelector('span');
    if (icon) icon.className = 'fa-regular fa-copy';
    if (span) span.textContent = 'Copy';
  });
});

copyBtn.addEventListener('click', function () {
  const activePanel = document.querySelector('.terminal-panel.active');
  if (activePanel) {
    // decode HTML entities from data-copy
    const raw = activePanel.dataset.copy;
    const decoded = raw.replace(/&amp;/g, '&').replace(/&#10;/g, '\n');
    copyText(decoded, this, 'Command copied!');
  }
});

/* ---- Tabbed uninstall terminal ---- */
const uninstallTabs = document.querySelectorAll('.uninstall-terminal-tab');
const uninstallPanels = document.querySelectorAll('.uninstall-terminal-panel');
const uninstallCopyBtn = document.getElementById('uninstallCopyBtn');

uninstallTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    uninstallTabs.forEach(t => { t.classList.remove('active'); t.setAttribute('aria-selected', 'false'); });
    uninstallPanels.forEach(p => p.classList.remove('active'));

    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');
    const panel = document.getElementById('panel-' + tab.dataset.tab);
    if (panel) panel.classList.add('active');

    // reset copy button state
    uninstallCopyBtn.classList.remove('copied');
    const icon = uninstallCopyBtn.querySelector('i');
    const span = uninstallCopyBtn.querySelector('span');
    if (icon) icon.className = 'fa-regular fa-copy';
    if (span) span.textContent = 'Copy';
  });
});

uninstallCopyBtn.addEventListener('click', function () {
  const activePanel = document.querySelector('.uninstall-terminal-panel.active');
  if (activePanel) {
    // decode HTML entities from data-copy
    const raw = activePanel.dataset.copy;
    const decoded = raw.replace(/&amp;/g, '&').replace(/&#10;/g, '\n');
    copyText(decoded, this, 'Command copied!');
  }
});

/* ---- Smooth scroll ---- */
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', function (e) {
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      e.preventDefault();
      const offset = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--nav-height'), 10) || 64;
      window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - offset, behavior: 'smooth' });
      closeDrawer();
    }
  });
});

/* ---- Doc card keyboard nav ---- */
document.querySelectorAll('.doc-card').forEach(card => {
  card.setAttribute('tabindex', '0');
  card.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); card.click(); }
  });
});