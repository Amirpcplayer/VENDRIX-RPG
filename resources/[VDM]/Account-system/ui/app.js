(() => {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const form = $("authForm");
  const username = $("username");
  const password = $("password");
  const loginTab = $("loginTab");
  const registerTab = $("registerTab");
  const tabs = document.querySelector(".tabs");
  const submitButton = $("submitButton");
  const submitText = document.querySelector(".submit-text");
  const status = $("status");
  const statusText = $("statusText");
  const togglePassword = $("togglePassword");
  const music = $("backgroundMusic");
  const musicToggle = $("musicToggle");
  let mode = "login";
  let busy = false;

  function setMode(next) {
    mode = next;
    const registering = mode === "register";
    loginTab.classList.toggle("active", !registering);
    registerTab.classList.toggle("active", registering);
    loginTab.setAttribute("aria-selected", String(!registering));
    registerTab.setAttribute("aria-selected", String(registering));
    tabs.classList.toggle("register", registering);
    submitText.textContent = registering ? "ساخت حساب و ورود" : "ورود به شهر";
    password.autocomplete = registering ? "new-password" : "current-password";
    setStatus(registering ? "نام کاربری ۳ تا ۲۴ حرف؛ رمز عبور حداقل ۸ نویسه." : "اطلاعات حساب خود را وارد کن.", "info");
  }

  function setStatus(message, type) {
    status.className = "status " + (type || "info");
    statusText.textContent = String(message || "");
  }

  function setBusy(value) {
    busy = Boolean(value);
    submitButton.disabled = busy;
    submitText.textContent = busy ? "لطفاً صبر کن..." : (mode === "register" ? "ساخت حساب و ورود" : "ورود به شهر");
  }

  function updateMusicButton(playing) {
    musicToggle.classList.toggle("playing", playing);
    musicToggle.setAttribute("aria-pressed", String(playing));
    musicToggle.querySelector("span").textContent = playing ? "موسیقی روشن" : "موسیقی خاموش";
  }

  async function toggleMusic() {
    if (!music) return;
    if (!music.paused) {
      music.pause();
      updateMusicButton(false);
      return;
    }
    try {
      music.volume = 0.28;
      await music.play();
      updateMusicButton(true);
    } catch (_) {
      updateMusicButton(false);
      setStatus("فایل ui/background.mp3 را بررسی کن؛ پخش خودکار ممکن است به کلیک نیاز داشته باشد.", "error");
    }
  }

  musicToggle.addEventListener("click", toggleMusic);
  music.addEventListener("ended", () => updateMusicButton(false));
  music.addEventListener("pause", () => updateMusicButton(false));
  music.addEventListener("play", () => updateMusicButton(true));

  loginTab.addEventListener("click", () => setMode("login"));
  registerTab.addEventListener("click", () => setMode("register"));
  togglePassword.addEventListener("click", () => {
    const visible = password.type === "text";
    password.type = visible ? "password" : "text";
    togglePassword.textContent = visible ? "◉" : "◎";
  });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    if (busy) return;
    const user = username.value.trim();
    const pass = password.value;
    if (!/^[A-Za-z0-9_]{3,24}$/.test(user)) {
      setStatus("نام کاربری باید ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط باشد.", "error");
      username.focus();
      return;
    }
    if (pass.length < 8 || pass.length > 64 || /[\u0000-\u001F\u007F]/.test(pass)) {
      setStatus("رمز عبور باید ۸ تا ۶۴ نویسه و بدون نویسه کنترلی باشد.", "error");
      password.focus();
      return;
    }
    if (!window.mta || typeof window.mta.triggerEvent !== "function") {
      setStatus("ارتباط رابط با کلاینت بازی برقرار نیست. Resource را دوباره اجرا کن.", "error");
      return;
    }
    setBusy(true);
    window.mta.triggerEvent("vendrix:account:uiSubmit", mode, user, pass);
  });

  window.VENDRIX = { setBusy, setStatus };
  updateMusicButton(false);
  setMode("login");
})();
