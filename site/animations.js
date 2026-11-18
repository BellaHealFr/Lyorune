// Lyorune : animations de la page (couronne du logo, quatre voies du soin, bouton de téléchargement).
(function () {
  'use strict';

  var CALME = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var TAU = Math.PI * 2;

  // Couleurs des quatre classes de soigneur
  var CLASSES = {
    druide:  { c: '110, 230, 120', vif: '#7dec8a' },
    paladin: { c: '255, 210, 110', vif: '#ffd77a' },
    pretre:  { c: '225, 235, 255', vif: '#eef3ff' },
    chaman:  { c: '90, 170, 255',  vif: '#7cc0ff' }
  };

  // ---------- outils ----------
  function preparer(canvas) {
    var ctx = canvas.getContext('2d');
    function taille() {
      var r = window.devicePixelRatio || 1;
      var w = canvas.clientWidth, h = canvas.clientHeight;
      canvas.width = Math.round(w * r); canvas.height = Math.round(h * r);
      ctx.setTransform(r, 0, 0, r, 0, 0);
    }
    taille();
    window.addEventListener('resize', taille);
    return ctx;
  }

  // Lance une boucle d'animation seulement quand l'élément est visible
  function animer(el, dessiner) {
    var actif = false, debut = performance.now(), id = 0;
    function boucle(now) {
      dessiner((now - debut) / 1000);
      if (actif) id = requestAnimationFrame(boucle);
    }
    if (CALME) { dessiner(1.2); return; }
    if (!('IntersectionObserver' in window)) { actif = true; id = requestAnimationFrame(boucle); return; }
    new IntersectionObserver(function (entrees) {
      var vu = entrees[0].isIntersecting;
      if (vu && !actif) { actif = true; id = requestAnimationFrame(boucle); }
      else if (!vu && actif) { actif = false; cancelAnimationFrame(id); }
    }).observe(el);
  }

  function lueur(ctx, x, y, r, rgb, a) {
    var g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, 'rgba(' + rgb + ',' + a + ')');
    g.addColorStop(1, 'rgba(' + rgb + ',0)');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
  }

  function feuille(ctx, x, y, t, ang, rgb, a) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang);
    ctx.fillStyle = 'rgba(' + rgb + ',' + a + ')';
    ctx.beginPath();
    ctx.moveTo(-t, 0);
    ctx.quadraticCurveTo(0, -t * 0.55, t, 0);
    ctx.quadraticCurveTo(0, t * 0.55, -t, 0);
    ctx.fill();
    ctx.restore();
  }

  function etoile(ctx, x, y, r1, r2, n, rot, couleur) {
    ctx.fillStyle = couleur;
    ctx.beginPath();
    for (var i = 0; i < n * 2; i++) {
      var r = i % 2 ? r2 : r1, a = rot + i * Math.PI / n;
      ctx[i ? 'lineTo' : 'moveTo'](x + r * Math.cos(a), y + r * Math.sin(a));
    }
    ctx.closePath(); ctx.fill();
  }

  function eclair(ctx, x0, y0, x1, y1, graine, rgb, a, larg) {
    var n = 9, dx = x1 - x0, dy = y1 - y0, l = Math.hypot(dx, dy) || 1;
    var nx = -dy / l, ny = dx / l, s = graine;
    ctx.strokeStyle = 'rgba(' + rgb + ',' + a + ')';
    ctx.lineWidth = larg || 2; ctx.lineJoin = 'round';
    ctx.beginPath(); ctx.moveTo(x0, y0);
    for (var i = 1; i < n; i++) {
      s = (s * 9301 + 49297) % 233280;
      var o = (s / 233280 - 0.5) * l * 0.18, k = i / n;
      ctx.lineTo(x0 + dx * k + nx * o, y0 + dy * k + ny * o);
    }
    ctx.lineTo(x1, y1); ctx.stroke();
  }

  // ---------- effets de chaque classe ----------
  // (ctx, x, y, taille, temps) : dessinés autour d'un point
  var EFFETS = {
    druide: function (ctx, x, y, s, t) {
      var c = CLASSES.druide.c;
      lueur(ctx, x, y, s * 0.9, c, 0.35 + 0.1 * Math.sin(t * 3));
      for (var i = 0; i < 7; i++) {
        var a = i * TAU / 7 + t * 0.9, r = s * (0.32 + 0.08 * Math.sin(t * 2 + i));
        feuille(ctx, x + r * Math.cos(a), y + r * Math.sin(a), s * 0.16, a, c, 0.95);
      }
      for (var j = 0; j < 10; j++) {
        var p = ((t * 0.35 + j / 10) % 1);
        var fx = x + Math.sin(j * 7.1 + t) * s * 0.9, fy = y + s * (0.9 - 1.8 * p);
        feuille(ctx, fx, fy, s * 0.08, t * 2 + j, c, 0.7 * Math.sin(Math.PI * p));
      }
    },
    paladin: function (ctx, x, y, s, t) {
      var c = CLASSES.paladin.c;
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      for (var i = 0; i < 12; i++) {
        var a = i * TAU / 12 + t * 0.25, l = s * (0.75 + 0.15 * Math.sin(t * 2 + i));
        var g = ctx.createLinearGradient(x, y, x + l * Math.cos(a), y + l * Math.sin(a));
        g.addColorStop(0, 'rgba(' + c + ',0.55)'); g.addColorStop(1, 'rgba(' + c + ',0)');
        ctx.strokeStyle = g; ctx.lineWidth = s * 0.05;
        ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + l * Math.cos(a), y + l * Math.sin(a)); ctx.stroke();
      }
      ctx.restore();
      lueur(ctx, x, y, s * 0.55, c, 0.6);
      etoile(ctx, x, y, s * (0.3 + 0.03 * Math.sin(t * 5)), s * 0.11, 8, t * 0.5, 'rgba(255, 240, 190, 0.95)');
      var p = (t % 1.2) / 1.2;
      ctx.strokeStyle = 'rgba(' + c + ',' + (1 - p) * 0.8 + ')'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(x, y, s * (0.35 + 0.5 * p), 0, TAU); ctx.stroke();
    },
    pretre: function (ctx, x, y, s, t) {
      var c = CLASSES.pretre.c;
      lueur(ctx, x, y, s * 0.6, c, 0.5);
      for (var i = 0; i < 3; i++) {
        var p = ((t + i * 0.6) % 1.8) / 1.8;
        ctx.strokeStyle = 'rgba(' + c + ',' + (1 - p) * 0.9 + ')'; ctx.lineWidth = 3 * (1 - p) + 1;
        ctx.beginPath(); ctx.arc(x, y, s * (0.2 + 0.7 * p), 0, TAU); ctx.stroke();
      }
      ctx.strokeStyle = 'rgba(255,255,255,0.9)'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.ellipse(x, y - s * 0.32, s * 0.22, s * 0.06, 0, 0, TAU); ctx.stroke();
      for (var j = 0; j < 6; j++) {
        var q = ((t * 0.25 + j / 6) % 1);
        feuille(ctx, x + Math.sin(j * 4.3 + t * 0.8) * s * 0.8, y - s + 2 * s * q, s * 0.12,
          1.1 + 0.4 * Math.sin(t * 2 + j), '245, 248, 255', 0.8 * Math.sin(Math.PI * q));
      }
    },
    chaman: function (ctx, x, y, s, t) {
      var c = CLASSES.chaman.c;
      lueur(ctx, x, y, s * 0.7, c, 0.35);
      for (var k = 0; k < 3; k++) {
        ctx.strokeStyle = 'rgba(' + c + ',' + (0.7 - k * 0.18) + ')'; ctx.lineWidth = 2;
        ctx.beginPath();
        for (var px = -s; px <= s; px += 4) {
          var py = y + s * 0.45 + k * s * 0.16 + Math.sin(px / (s * 0.18) + t * 3 + k) * s * 0.06;
          ctx[px === -s ? 'moveTo' : 'lineTo'](x + px, py);
        }
        ctx.stroke();
      }
      var pts = [[x - s * 0.6, y], [x, y - s * 0.35], [x + s * 0.6, y]];
      var cycle = t % 1.6;
      for (var i = 0; i < 2; i++) {
        if (cycle > 0.15 + i * 0.25 && cycle < 1.2) {
          eclair(ctx, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], Math.floor(t * 14) + i * 50, '215, 238, 255', 0.95, 2.2);
        }
      }
      for (var j = 0; j < 3; j++) lueur(ctx, pts[j][0], pts[j][1], s * 0.18, c, cycle > 0.15 + Math.max(0, j - 1) * 0.25 && cycle < 1.3 ? 0.9 : 0.35);
    }
  };

  // ---------- couronne autour du logo ----------
  var couronne = document.querySelector('.couronne canvas');
  if (couronne) {
    var cx = preparer(couronne);
    var ordre = ['druide', 'paladin', 'pretre', 'chaman'];
    animer(couronne, function (t) {
      var w = couronne.clientWidth, h = couronne.clientHeight, x0 = w / 2, y0 = h / 2;
      var R = Math.min(w, h) * 0.41, s = Math.min(w, h) * 0.085;
      cx.clearRect(0, 0, w, h);
      // anneau runique
      cx.strokeStyle = 'rgba(212, 169, 78, 0.35)'; cx.lineWidth = 1.5;
      cx.beginPath(); cx.arc(x0, y0, R, 0, TAU); cx.stroke();
      cx.setLineDash([2, 10]); cx.strokeStyle = 'rgba(240, 212, 138, 0.5)';
      cx.beginPath(); cx.arc(x0, y0, R + 10, -t * 0.1, TAU - t * 0.1); cx.stroke(); cx.setLineDash([]);
      var pos = [];
      for (var i = 0; i < 4; i++) {
        var a = -Math.PI / 2 + i * TAU / 4 + t * 0.22;
        pos.push([x0 + R * Math.cos(a), y0 + R * Math.sin(a), a]);
      }
      // traînées colorées entre les orbes
      for (var j = 0; j < 4; j++) {
        var nom = ordre[j], c = CLASSES[nom].c, a0 = pos[j][2];
        var g = cx.createConicGradient ? cx.createConicGradient(a0 - 1.2, x0, y0) : null;
        if (g) {
          g.addColorStop(0, 'rgba(' + c + ',0)'); g.addColorStop(1.2 / TAU, 'rgba(' + c + ',0.7)'); g.addColorStop(1.21 / TAU, 'rgba(' + c + ',0)');
          cx.strokeStyle = g; cx.lineWidth = 3;
          cx.beginPath(); cx.arc(x0, y0, R, a0 - 1.2, a0); cx.stroke();
        }
      }
      // le soin passe d'une classe à l'autre : éclat qui fait le tour
      var actif = Math.floor(t / 1.5) % 4;
      for (var k = 0; k < 4; k++) {
        cx.save(); cx.globalAlpha = k === actif ? 1 : 0.75;
        EFFETS[ordre[k]](cx, pos[k][0], pos[k][1], s * (k === actif ? 1.25 : 1), t + k);
        cx.restore();
      }
      lueur(cx, x0, y0, R * 0.9, '212, 169, 78', 0.12 + 0.05 * Math.sin(t * 1.5));
    });
  }

  // ---------- les quatre voies du soin ----------
  document.querySelectorAll('canvas[data-classe]').forEach(function (cv) {
    var ctx = preparer(cv), nom = cv.getAttribute('data-classe');
    animer(cv, function (t) {
      var w = cv.clientWidth, h = cv.clientHeight;
      ctx.clearRect(0, 0, w, h);
      EFFETS[nom](ctx, w / 2, h / 2, Math.min(w, h) * 0.42, t);
    });
  });

  // ---------- bouton de téléchargement : toujours la dernière version ----------
  var boutons = document.querySelectorAll('[data-telecharger]');
  if (boutons.length && window.fetch) {
    fetch('https://api.github.com/repos/BellaHealFr/Lyorune/releases/latest', { headers: { Accept: 'application/vnd.github+json' } })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (rel) {
        if (!rel || !rel.tag_name) return;
        var version = rel.tag_name.replace(/^v/, '');
        var zips = (rel.assets || []).filter(function (a) { return /\.zip$/i.test(a.name); });
        // l'archive « Lyorune-X.Y.Z.zip » d'abord, sinon la première archive de la version
        var zip = zips.filter(function (a) { return a.name === 'Lyorune-' + version + '.zip'; })[0] || zips[0];
        boutons.forEach(function (b) {
          if (zip) b.href = zip.browser_download_url;
          var mod = b.getAttribute('data-telecharger');
          b.textContent = mod.replace('{v}', version);
        });
        document.querySelectorAll('[data-version]').forEach(function (e) { e.textContent = version; });
      })
      .catch(function () { /* le lien vers la page des versions reste en place */ });
  }
})();
