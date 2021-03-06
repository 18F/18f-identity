import { loadPolyfills } from '@18f/identity-polyfill';
import domready from 'domready';
import { isValidNumber } from 'libphonenumber-js';

const isPhoneValid = (phone, countryCode) => {
  let phoneValid = isValidNumber(phone, countryCode);
  if (!phoneValid && countryCode === 'US') {
    phoneValid = isValidNumber(`+1 ${phone}`, countryCode);
  }
  return phoneValid;
};

const updatePlaceholder = (phoneInput) => {
  if (phoneInput && phoneInput.placeholder) {
    const exPhoneElement = document.querySelector('#ex-phone');
    if (exPhoneElement) {
      exPhoneElement.textContent = phoneInput.placeholder;
      phoneInput.placeholder = '';
    }
  }
};

const checkPhoneValidity = () => {
  /** @type {HTMLInputElement?} */
  const sendCodeButton = document.querySelector(
    '[data-international-phone-form] input[name=commit]',
  );
  /** @type {HTMLInputElement?} */
  const phoneInput =
    document.querySelector('[data-international-phone-form] .phone') ||
    document.querySelector('[data-international-phone-form] .new-phone');
  updatePlaceholder(phoneInput);
  /** @type {HTMLInputElement?} */
  const countryCodeInput = document.querySelector(
    '[data-international-phone-form] .international-code',
  );

  if (phoneInput && countryCodeInput && sendCodeButton) {
    const phone = phoneInput.value;
    const countryCode = countryCodeInput.value;

    const phoneValid = isPhoneValid(phone, countryCode);

    sendCodeButton.disabled = !phoneValid;

    if (!phoneValid) {
      phoneInput.dispatchEvent(new CustomEvent('invalid'));
    }
  }
};

Promise.all([new Promise((resolve) => domready(resolve)), loadPolyfills(['custom-event'])]).then(
  () => {
    const intlPhoneInput =
      document.querySelector('[data-international-phone-form] .phone') ||
      document.querySelector('[data-international-phone-form] .new-phone');
    const codeInput = document.querySelector('[data-international-phone-form] .international-code');
    if (intlPhoneInput) {
      intlPhoneInput.addEventListener('keyup', checkPhoneValidity);
      intlPhoneInput.addEventListener('focus', checkPhoneValidity);
    }
    if (codeInput) {
      codeInput.addEventListener('change', checkPhoneValidity);
    }
    checkPhoneValidity();
  },
);
