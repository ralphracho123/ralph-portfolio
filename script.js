/* =========================================================
   Ralph Lorence Racho — Portfolio
   Vanilla JS. No dependencies, no build step.
   ========================================================= */
(function () {
  "use strict";

  var CV_PATH = "assets/ralph-racho-cv.pdf";
  var root = document.documentElement;
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* =======================================================
     Theme (light / dark)
     The initial value is set by the inline script in <head>
     so the page never flashes the wrong theme.
     ======================================================= */
  var themeToggle = document.getElementById("themeToggle");
  var themeMeta = document.getElementById("themeColorMeta");
  var THEME_COLORS = { light: "#FDFBF5", dark: "#0D1120" };

  function syncToggle(theme) {
    var dark = theme === "dark";
    themeToggle.setAttribute("aria-pressed", dark ? "true" : "false");
    themeToggle.setAttribute(
      "aria-label", dark ? "Switch to light theme" : "Switch to dark theme"
    );
    if (themeMeta) themeMeta.setAttribute("content", THEME_COLORS[theme]);
  }

  function applyTheme(theme, remember) {
    // Suppress transitions for a frame so the whole page doesn't
    // animate every property at once during the swap.
    root.classList.add("is-theming");
    root.setAttribute("data-theme", theme);
    syncToggle(theme);
    if (remember) {
      try { localStorage.setItem("theme", theme); } catch (e) { /* ignore */ }
    }
    window.setTimeout(function () { root.classList.remove("is-theming"); }, 60);
  }

  /* Where supported, the new theme is revealed as a circle expanding from
     the toggle itself. Everywhere else it is a plain swap. */
  function setTheme(theme, remember, origin) {
    if (!document.startViewTransition || reduceMotion || !origin) {
      applyTheme(theme, remember);
      return;
    }

    var box = origin.getBoundingClientRect();
    var x = box.left + box.width / 2;
    var y = box.top + box.height / 2;
    var radius = Math.hypot(
      Math.max(x, window.innerWidth - x),
      Math.max(y, window.innerHeight - y)
    );

    var transition = document.startViewTransition(function () {
      applyTheme(theme, remember);
    });

    transition.ready.then(function () {
      document.documentElement.animate(
        { clipPath: ["circle(0px at " + x + "px " + y + "px)",
                     "circle(" + radius + "px at " + x + "px " + y + "px)"] },
        { duration: 620, easing: "cubic-bezier(.22,.61,.36,1)",
          pseudoElement: "::view-transition-new(root)" }
      );
    }).catch(function () { /* nothing to clean up */ });
  }

  syncToggle(root.getAttribute("data-theme") || "light");

  themeToggle.addEventListener("click", function () {
    var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
    setTheme(next, true, themeToggle);
  });

  // Follow the OS setting unless the visitor has made their own choice.
  var systemDark = window.matchMedia("(prefers-color-scheme: dark)");
  function onSystemChange(e) {
    var chosen = null;
    try { chosen = localStorage.getItem("theme"); } catch (err) { /* ignore */ }
    if (!chosen) setTheme(e.matches ? "dark" : "light", false);
  }
  if (systemDark.addEventListener) systemDark.addEventListener("change", onSystemChange);
  else if (systemDark.addListener) systemDark.addListener(onSystemChange);

  /* =======================================================
     Mobile navigation
     ======================================================= */
  var burger = document.getElementById("burger");
  var mobileNav = document.getElementById("mobileNav");
  var scrim = document.getElementById("navScrim");

  function openNav() {
    mobileNav.hidden = false;
    scrim.hidden = false;
    requestAnimationFrame(function () {
      mobileNav.classList.add("is-open");
      scrim.classList.add("is-open");
    });
    burger.setAttribute("aria-expanded", "true");
    burger.setAttribute("aria-label", "Close menu");
    document.body.classList.add("is-locked");
  }

  function closeNav(returnFocus) {
    if (burger.getAttribute("aria-expanded") !== "true") return;
    mobileNav.classList.remove("is-open");
    scrim.classList.remove("is-open");
    burger.setAttribute("aria-expanded", "false");
    burger.setAttribute("aria-label", "Open menu");
    document.body.classList.remove("is-locked");
    window.setTimeout(function () {
      mobileNav.hidden = true;
      scrim.hidden = true;
    }, 260);
    if (returnFocus) burger.focus();
  }

  burger.addEventListener("click", function () {
    if (burger.getAttribute("aria-expanded") === "true") closeNav(false);
    else openNav();
  });

  scrim.addEventListener("click", function () { closeNav(false); });

  // Close after choosing a destination.
  mobileNav.addEventListener("click", function (e) {
    if (e.target.closest("a")) closeNav(false);
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeNav(true);
  });

  // Keep focus inside the panel while it is open.
  mobileNav.addEventListener("keydown", function (e) {
    if (e.key !== "Tab") return;
    var items = mobileNav.querySelectorAll("a[href]");
    if (!items.length) return;
    var first = items[0];
    var last = items[items.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault(); last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault(); first.focus();
    }
  });

  // Drop the panel if the viewport grows past the mobile breakpoint.
  var wide = window.matchMedia("(min-width: 921px)");
  function onBreakpoint(e) { if (e.matches) closeNav(false); }
  if (wide.addEventListener) wide.addEventListener("change", onBreakpoint);
  else if (wide.addListener) wide.addListener(onBreakpoint);

  /* =======================================================
     Scroll: header state, progress bar, back-to-top
     ======================================================= */
  var header = document.getElementById("siteHeader");
  var toTop = document.getElementById("toTop");
  var progress = document.getElementById("scrollProgress");
  var ticking = false;

  function onScroll() {
    var y = window.pageYOffset || document.documentElement.scrollTop;
    var max = document.documentElement.scrollHeight - window.innerHeight;

    header.classList.toggle("is-stuck", y > 8);
    toTop.hidden = y < 600;
    progress.style.transform = "scaleX(" + (max > 0 ? y / max : 0) + ")";

    // parallaxItems is declared further down; it is empty until then
    if (parallaxItems && parallaxItems.length) updateParallax();

    ticking = false;
  }

  window.addEventListener("scroll", function () {
    if (!ticking) { ticking = true; window.requestAnimationFrame(onScroll); }
  }, { passive: true });
  window.addEventListener("resize", onScroll);
  onScroll();

  /* =======================================================
     Reveal on scroll
     ======================================================= */
  var revealables = document.querySelectorAll(".reveal, .timeline li");

  if ("IntersectionObserver" in window && !reduceMotion) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-in");
        io.unobserve(entry.target);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });

    revealables.forEach(function (el, i) {
      el.style.transitionDelay = Math.min(i % 4, 3) * 70 + "ms";
      io.observe(el);
    });
  } else {
    revealables.forEach(function (el) { el.classList.add("is-in"); });
  }

  /* =======================================================
     Count-up for the about figures
     ======================================================= */
  var counters = document.querySelectorAll("[data-count]");

  function countUp(el) {
    var target = parseInt(el.getAttribute("data-count"), 10) || 0;
    if (reduceMotion) { el.textContent = String(target); return; }

    var start = null;
    var duration = 900;
    function step(now) {
      if (start === null) start = now;
      var p = Math.min((now - start) / duration, 1);
      // ease-out so it settles rather than stopping dead
      el.textContent = String(Math.round(target * (1 - Math.pow(1 - p, 3))));
      if (p < 1) window.requestAnimationFrame(step);
    }
    window.requestAnimationFrame(step);
  }

  if ("IntersectionObserver" in window) {
    var countObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        countUp(entry.target);
        countObserver.unobserve(entry.target);
      });
    }, { threshold: 0.6 });
    counters.forEach(function (el) { countObserver.observe(el); });
  } else {
    counters.forEach(function (el) {
      el.textContent = el.getAttribute("data-count");
    });
  }

  /* =======================================================
     Project previews
     The screenshot is the poster; the clip loads and plays
     only when the card is on screen, on wide viewports, and
     only if motion is welcome. Phones keep the still image.
     ======================================================= */
  var videos = document.querySelectorAll(".mockup__video");
  var wantsVideo = window.matchMedia("(min-width: 721px)").matches && !reduceMotion;

  if (videos.length && wantsVideo && "IntersectionObserver" in window) {
    var videoObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var video = entry.target;
        if (entry.isIntersecting) {
          if (!video.src) video.src = video.getAttribute("data-src");
          var played = video.play();
          if (played && played.catch) {
            // Autoplay can be blocked; the poster image stays, which is fine.
            played.catch(function () {});
          }
          video.classList.add("is-playing");
        } else {
          video.pause();
          video.classList.remove("is-playing");
        }
      });
    }, { threshold: 0.45 });

    videos.forEach(function (v) { videoObserver.observe(v); });
  }

  /* =======================================================
     Section titles: wrap each word so it can mask upward
     ======================================================= */
  Array.prototype.forEach.call(
    document.querySelectorAll(".section-title"),
    function (title) {
      var words = title.textContent.trim().split(/\s+/);
      title.textContent = "";
      words.forEach(function (word, i) {
        var outer = document.createElement("span");
        outer.className = "w";
        var inner = document.createElement("span");
        inner.textContent = word;
        outer.appendChild(inner);
        title.appendChild(outer);
        if (i < words.length - 1) title.appendChild(document.createTextNode(" "));
      });
    }
  );

  /* =======================================================
     Pointer flourishes — fine pointers only, so nothing here
     affects phones or anyone who asked for less motion.
     ======================================================= */
  var finePointer = window.matchMedia("(hover: hover) and (pointer: fine)").matches;

  if (finePointer && !reduceMotion) {

    // Buttons lean very slightly towards the cursor.
    Array.prototype.forEach.call(
      document.querySelectorAll(".btn, .to-top"),
      function (btn) {
        btn.addEventListener("pointermove", function (e) {
          var b = btn.getBoundingClientRect();
          var dx = (e.clientX - (b.left + b.width / 2)) / b.width;
          var dy = (e.clientY - (b.top + b.height / 2)) / b.height;
          btn.style.transform = "translate(" + (dx * 7).toFixed(2) + "px," +
                                (dy * 5 - 2).toFixed(2) + "px)";
        });
        btn.addEventListener("pointerleave", function () {
          btn.style.transform = "";
        });
      }
    );

    // Project mockups tilt towards the cursor.
    Array.prototype.forEach.call(
      document.querySelectorAll(".project"),
      function (card) {
        card.addEventListener("pointermove", function (e) {
          var b = card.getBoundingClientRect();
          var dx = (e.clientX - (b.left + b.width / 2)) / b.width;
          var dy = (e.clientY - (b.top + b.height / 2)) / b.height;
          card.style.setProperty("--ry", (dx * 7).toFixed(2) + "deg");
          card.style.setProperty("--rx", (-dy * 5).toFixed(2) + "deg");
        });
        card.addEventListener("pointerleave", function () {
          card.style.setProperty("--ry", "0deg");
          card.style.setProperty("--rx", "0deg");
        });
      }
    );
  }

  /* =======================================================
     Parallax — the portrait and the screenshots drift a
     little slower than the page they sit on.
     ======================================================= */
  var parallaxItems = [];
  if (!reduceMotion) {
    Array.prototype.forEach.call(
      document.querySelectorAll("[data-parallax]"),
      function (el) {
        parallaxItems.push({ el: el, rate: parseFloat(el.getAttribute("data-parallax")), prop: "translate" });
      }
    );
    Array.prototype.forEach.call(
      document.querySelectorAll(".mockup__screen img, .mockup__video"),
      function (el) { parallaxItems.push({ el: el, rate: 0.045, prop: "var" }); }
    );
  }

  function updateParallax() {
    var vh = window.innerHeight;
    parallaxItems.forEach(function (item) {
      var box = item.el.getBoundingClientRect();
      if (box.bottom < -200 || box.top > vh + 200) return;
      // -1 at the top of the viewport, +1 at the bottom
      var progress = (box.top + box.height / 2 - vh / 2) / (vh / 2);
      var shift = -progress * (item.rate * 100);
      if (item.prop === "var") {
        item.el.style.setProperty("--py", shift.toFixed(2) + "px");
      } else {
        item.el.style.translate = "0 " + shift.toFixed(2) + "px";
      }
    });
  }

  /* =======================================================
     Active link while scrolling
     ======================================================= */
  var navLinks = Array.prototype.slice.call(
    document.querySelectorAll(".nav-desktop ul a[href^='#']")
  );
  var sections = navLinks
    .map(function (a) { return document.querySelector(a.getAttribute("href")); })
    .filter(Boolean);

  if ("IntersectionObserver" in window && sections.length) {
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        navLinks.forEach(function (a) {
          a.classList.toggle(
            "is-active", a.getAttribute("href") === "#" + entry.target.id
          );
        });
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    sections.forEach(function (s) { spy.observe(s); });
  }

  /* =======================================================
     CV viewer
     ======================================================= */
  var cvToggle = document.getElementById("cvToggle");
  var cvViewer = document.getElementById("cvViewer");
  var cvEmbed = document.getElementById("cvEmbed");

  // Embedded PDFs are unreliable on phones and on iOS in particular,
  // so below this width we open a real tab instead.
  function canEmbedPdf() {
    var narrow = window.matchMedia("(max-width: 640px)").matches;
    var iOS = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
              (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
    return !narrow && !iOS;
  }

  function showNote(message) {
    cvEmbed.innerHTML = "";
    var p = document.createElement("p");
    p.className = "cv__note";
    p.textContent = message;
    cvEmbed.appendChild(p);
    cvEmbed.style.height = "auto";
  }

  cvToggle.addEventListener("click", function () {
    var open = cvToggle.getAttribute("aria-expanded") === "true";

    if (!canEmbedPdf()) {
      window.open(CV_PATH, "_blank", "noopener");
      return;
    }

    if (open) {
      cvViewer.hidden = true;
      cvToggle.setAttribute("aria-expanded", "false");
      cvToggle.textContent = "View CV";
      return;
    }

    cvViewer.hidden = false;
    cvToggle.setAttribute("aria-expanded", "true");
    cvToggle.textContent = "Hide CV";

    if (!cvEmbed.dataset.loaded) {
      cvEmbed.dataset.loaded = "1";
      var frame = document.createElement("iframe");
      frame.src = CV_PATH;
      frame.title = "Curriculum vitae of Ralph Lorence Racho";
      frame.loading = "lazy";
      cvEmbed.appendChild(frame);

      // If the file is missing, say so rather than showing a blank box.
      if (window.fetch && location.protocol !== "file:") {
        fetch(CV_PATH, { method: "HEAD" })
          .then(function (res) {
            if (!res.ok) showNote("The CV file isn't available yet. Please check back soon.");
          })
          .catch(function () { /* offline or blocked — leave the iframe alone */ });
      }
    }

    cvViewer.scrollIntoView({ behavior: "smooth", block: "nearest" });
  });

  // first pass, now that the parallax list exists
  updateParallax();

  /* ---------- Footer year ---------- */
  document.getElementById("year").textContent = String(new Date().getFullYear());
})();
