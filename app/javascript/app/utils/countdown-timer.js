const msFormatter = require('./ms-formatter').default;

export default (el, timeLeft = 0, endTime = null, interval = 1000) => {
  let remaining = timeLeft;
  let currentTime;
  let timer;

  if (!el || !('innerHTML' in el)) {
    return;
  }

  function tick() {
    /* eslint-disable no-param-reassign */
    if (endTime) {
      currentTime = new Date().getTime();
      remaining = endTime - currentTime;
    }

    el.innerHTML = msFormatter(remaining);

    if (remaining <= 0) {
      cancelInterval(timer);
      return;
    }

    remaining -= interval;
  }

  timer = setInterval(tick, interval);
  return timer;
};
