// Scroll buttons for the horizontal blog rows
document.querySelectorAll('.author-row').forEach(function (row) {
  var scroller = row.querySelector('.scroller');
  row.querySelectorAll('.scroll-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      scroller.scrollBy({ left: Number(btn.dataset.dir) * (scroller.clientWidth * 0.8), behavior: 'smooth' });
    });
  });
});
