// 이 첫 줄은 반드시 주석이어야 합니다 (autoconfig 규칙)
(function () {
  function setup(win) {
    if (win.location.href !== "chrome://browser/content/browser.xhtml") return;

    const gB = win.gBrowser;
    const sp = Services.scriptSecurityManager.getSystemPrincipal();
    let orig = null, temp = null;

    win.addEventListener("deactivate", () => {
      if (temp) return;
      orig = gB.selectedTab;
      temp = gB.addTab("about:blank", { triggeringPrincipal: sp });
      gB.selectedTab = temp;
    });

    win.addEventListener("activate", () => {
      if (!temp) return;
      if (orig && orig.parentNode && !orig.closing) {
        gB.selectedTab = orig;
      }
      gB.removeTab(temp);
      temp = null;
      orig = null;
    });
  }

  Services.obs.addObserver({
    observe(subject, topic) {
      if (topic !== "browser-delayed-startup-finished") return;
      try {
        setup(subject);
      } catch (e) {
        console.error("pip-desktop-script:", e);
      }
    },
  }, "browser-delayed-startup-finished");
})();
