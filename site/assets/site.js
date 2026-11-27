// Scroll buttons for the horizontal blog rows
document.querySelectorAll('.author-row').forEach(function (row) {
  var scroller = row.querySelector('.scroller');
  row.querySelectorAll('.scroll-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      scroller.scrollBy({ left: Number(btn.dataset.dir) * (scroller.clientWidth * 0.8), behavior: 'smooth' });
    });
  });
});

// Scroll animation: plays each time an element enters the viewport (and resets when it leaves)
(function () {
  var els = document.querySelectorAll('.reveal');
  if (!els.length || !('IntersectionObserver' in window)) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  document.documentElement.classList.add('js-reveal');
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) { e.target.classList.toggle('in-view', e.isIntersecting); });
  }, { threshold: 0.15 });
  els.forEach(function (el) { io.observe(el); });
})();

// Make the landing panel exactly fill the screen below the ticker and nav bar
(function () {
  var hero = document.querySelector('.hero-about');
  if (!hero) return;
  function fit() {
    var top = 0;
    ['.ticker', '.site-header'].forEach(function (s) {
      var el = document.querySelector(s);
      if (el) top += el.offsetHeight;
    });
    hero.style.setProperty('--hero-h', Math.max(window.innerHeight - top, 420) + 'px');
  }
  fit();
  window.addEventListener('resize', fit);
  window.addEventListener('load', fit);
})();
