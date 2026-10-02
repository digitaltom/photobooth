// Countdown dialog while the camera takes 4 pictures (record mode only).
// Delegated listener, so it keeps working after Turbo page swaps.
document.addEventListener('click', function (event) {
  if (!event.target.closest('[data-shoot]')) return;

  var countdownDelay = 2000; // ms before shooting
  var pictureDelay = 4000; // ms for each camera picture
  var dialog = document.getElementById('shoot-dialog');
  var txt = document.getElementById('shoot-txt');
  var progress = document.getElementById('shoot-progress');
  var progressTxt = document.getElementById('shoot-progress-txt');

  var showStep = function (current) {
    dialog.querySelectorAll('[data-step]').forEach(function (img) {
      var step = Number(img.dataset.step);
      var state = current < step ? 'before' : (current === step ? 'during' : 'after');
      img.classList.toggle('hidden', img.dataset.show !== state);
    });
  };

  txt.textContent = 'Take pose!';
  progressTxt.textContent = '';
  progress.value = 100;
  showStep(0);
  dialog.showModal();

  var countdown = setInterval(function () {
    progress.value -= 5;
    if (progress.value <= 0) clearInterval(countdown);
  }, countdownDelay / 20);

  setTimeout(function () {
    txt.textContent = 'Action, taking 4 pictures';
    // Turbo replaces the page (and closes the dialog) after the response
    document.getElementById('shoot-form').requestSubmit();
  }, countdownDelay);

  [1, 2, 3, 4].forEach(function (counter) {
    setTimeout(function () {
      showStep(counter);
      progress.value = 25 * counter;
      progressTxt.textContent = counter + ' / 4';
    }, pictureDelay * counter + countdownDelay);
  });

  setTimeout(function () {
    showStep(5);
    txt.textContent = 'Processing animation';
  }, pictureDelay * 5 + countdownDelay);
});
