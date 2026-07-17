/* markdown-to-html v2.1.0 — generated from reference/html-spec.md */
function savePDF() {
  window.print();
}

(function () {
  'use strict';
  var links = {};
  document.querySelectorAll('nav a[href^="#"]').forEach(function (a) {
    links[a.getAttribute('href').slice(1)] = a;
  });
  var rail = document.querySelector('.scroll-rail');
  function updateRail() {
    if (!rail) return;
    var pct = (window.scrollY / Math.max(1,
      document.documentElement.scrollHeight - window.innerHeight)) * 100;
    rail.style.setProperty('--scroll-pct', Math.min(100, Math.round(pct)));
  }
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        Object.values(links).forEach(function (a) {
          a.classList.remove('active');
          a.removeAttribute('aria-current');
        });
        var link = links[entry.target.id];
        if (link) {
          link.classList.add('active');
          link.setAttribute('aria-current', 'true');
        }
      }
    });
  }, { threshold: 0.3 });
  document.querySelectorAll('main section').forEach(function (s) {
    observer.observe(s);
  });
  document.querySelectorAll('.svg-node').forEach(function (node) {
    node.addEventListener('click', function () {
      var id = node.dataset.section;
      var el = id && document.getElementById(id);
      if (el) el.scrollIntoView({ behavior: 'smooth' });
    });
  });
  window.addEventListener('scroll', updateRail, { passive: true });
  updateRail();
})();

(function () {
  'use strict';
  var STORE_KEY = 'plan-steps-' + encodeURIComponent(document.title);
  var saved = {};
  try { saved = JSON.parse(localStorage.getItem(STORE_KEY) || '{}'); } catch (e) {}

  function updateProgress() {
    var bar = document.querySelector('.progress-bar[role="progressbar"]');
    var fill = document.querySelector('.progress-fill');
    if (!fill) return;
    var boxes = document.querySelectorAll('.step-checkbox');
    if (!boxes.length) return;
    var checked = Array.from(boxes).filter(function (b) { return b.checked; }).length;
    var pct = Math.round((checked / boxes.length) * 100);
    fill.style.width = pct + '%';
    if (bar) {
      bar.setAttribute('aria-valuenow', String(pct));
      bar.setAttribute('aria-valuetext', pct + '% complete');
    }
  }

  document.querySelectorAll('.step-card').forEach(function (card, idx) {
    var id = card.dataset.stepId;
    var cb = card.querySelector('.step-checkbox');
    var chip = card.querySelector('.step-chip');
    var status = card.querySelector('.step-status');
    if (!cb || !id) return;
    if (saved[id]) {
      cb.checked = true;
      card.classList.add('completed');
      if (chip) chip.textContent = 'done';
    }
    cb.addEventListener('change', function () {
      var done = cb.checked;
      card.classList.toggle('completed', done);
      if (chip) chip.textContent = done ? 'done' : 'todo';
      if (status) {
        status.textContent = 'Step ' + (idx + 1) + ' marked as ' +
          (done ? 'complete' : 'incomplete');
      }
      saved[id] = done;
      try { localStorage.setItem(STORE_KEY, JSON.stringify(saved)); } catch (e) {}
      updateProgress();
    });
  });
  updateProgress();
})();
