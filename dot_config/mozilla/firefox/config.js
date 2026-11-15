// 이 첫 줄은 반드시 주석이어야 합니다 (autoconfig 규칙)
(function () {
  const DEBUG = false; // 깜빡임 원인 추적이 필요하면 true로

  function setup(win) {
    if (win.location.href !== "chrome://browser/content/browser.xhtml") return;

      const gB = win.gBrowser;
    const doc = win.document;
    const sp = Services.scriptSecurityManager.getSystemPrincipal();
    let orig = null, temp = null;

    const log = (...a) => DEBUG && console.log("[pip-desktop]", Date.now(), ...a);

    // 나갈 때: 창이 화면에서 안 보이게 되면 임시 탭으로 전환
    doc.addEventListener("visibilitychange", () => {
      log("visibilitychange hidden=", doc.hidden);
      if (!doc.hidden || temp) return;
      orig = gB.selectedTab;
      temp = gB.addTab("about:blank", { triggeringPrincipal: sp });
      gB.selectedTab = temp;
      log("switched away");
    });

    // 돌아올 때: 창이 보이고 + 실제로 활성화된 경우에만 복귀
    function restore() {
      if (!temp || doc.hidden) return;
      if (orig && orig.parentNode && !orig.closing) {
        gB.selectedTab = orig;
      }
      gB.removeTab(temp);
      temp = null;
      orig = null;
      log("restored");
    }

    win.addEventListener("activate", () => {
      log("activate");
      restore();
    });
    win.addEventListener("deactivate", () => log("deactivate"));
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
