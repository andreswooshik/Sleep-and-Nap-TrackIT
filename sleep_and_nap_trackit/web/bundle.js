// Passkeys stub for passkeys_web 2.9.0.
//
// This app uses email/password auth only — passkeys are never used. But the
// passkeys_web plugin calls window.close() during registration if it cannot
// find a global `PasskeyAuthenticator`, which closes the browser tab and
// prevents the app from running. This stub defines that global with no-op
// methods so registration succeeds and the tab stays open.
window.PasskeyAuthenticator = {
  init: function () {},
  register: function () { return Promise.reject('passkeys not supported'); },
  login: function () { return Promise.reject('passkeys not supported'); },
  cancelCurrentAuthenticatorOperation: function () {},
  isUserVerifyingPlatformAuthenticatorAvailable: function () { return Promise.resolve(false); },
  isConditionalMediationAvailable: function () { return Promise.resolve(false); },
  hasPasskeySupport: function () { return false; },
};
