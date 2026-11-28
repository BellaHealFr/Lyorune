// Lyorune : la page de présentation. Démo de soin, petit groupe de l'accueil, couronne du logo, quatre voies du
// soin, version en direct, codes de profil, inscription runique, compteur de visites.
(function () {
  'use strict';

  var CONFIG = JSON.parse(document.getElementById('config').textContent);
  var T = CONFIG.textes;
  var CALME = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var TAU = Math.PI * 2;

  function format(modele, valeurs) {
    return modele.replace(/\{(\w+)\}/g, function (m, cle) { return valeurs[cle] !== undefined ? valeurs[cle] : m; });
  }
  function hasard(min, max) { return min + Math.random() * (max - min); }
  function rgba(c, a) {
    return 'rgba(' + Math.round(c[0] * 255) + ',' + Math.round(c[1] * 255) + ',' + Math.round(c[2] * 255) + ',' +
      (a !== undefined ? a : (c[3] !== undefined ? c[3] : 1)) + ')';
  }
  function visible(el, rappel) {
    if (!('IntersectionObserver' in window)) { rappel(true); return; }
    new IntersectionObserver(function (e) { rappel(e[0].isIntersecting); }).observe(el);
  }

  // ---------- statistiques : GoatCounter, sans cookie (événements et nombre de visiteurs) ----------
  function evenement(nom) {
    if (window.goatcounter && window.goatcounter.count) {
      window.goatcounter.count({ path: nom + '-' + CONFIG.lang + '-' + CONFIG.cible, title: nom, event: true });
    }
  }
  document.addEventListener('click', function (e) {
    var cible = e.target.closest && e.target.closest('[data-evenement]');
    if (cible) evenement(cible.getAttribute('data-evenement'));
    var langue = e.target.closest && e.target.closest('[data-langue]');
    if (langue) {
      try { localStorage.setItem('lyorune-langue', langue.getAttribute('data-langue')); } catch (x) { /* navigation privée */ }
      evenement('langue');
    }
  });
  // Langue choisie la dernière fois : jamais de redirection, seulement le lien mis en avant
  try {
    var memoire = localStorage.getItem('lyorune-langue');
    if (memoire && memoire !== CONFIG.lang) {
      document.querySelectorAll('.haut [data-langue="' + memoire + '"]').forEach(function (a) { a.classList.add('principale'); });
    }
  } catch (x) { /* navigation privée */ }

  var visites = document.getElementById('visites');
  if (visites && CONFIG.goatcounter && window.fetch) {
    var base = 'https://' + CONFIG.goatcounter + '.goatcounter.com/counter/';
    var lire = function (chemin) {
      return fetch(base + encodeURIComponent(chemin) + '.json')
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (d) { return (d && parseInt(String(d.count).replace(/\D/g, ''), 10)) || 0; })
        .catch(function () { return 0; });
    };
    Promise.all([lire('TOTAL'), lire(CONFIG.chemins[0]), lire(CONFIG.chemins[1])]).then(function (v) {
      var n = Math.max(v[0], v[1] + v[2]);
      if (!n) return;
      visites.textContent = n.toLocaleString(CONFIG.lang) + ' ' + CONFIG.visites[n > 1 ? 1 : 0];
      visites.hidden = false;
    });
  }

  // ---------- version en direct (API GitHub), la version du dépôt reste en place sinon ----------
  if (window.fetch) {
    fetch('https://api.github.com/repos/BellaHealFr/Lyorune/releases/latest', { headers: { Accept: 'application/vnd.github+json' } })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (rel) {
        if (!rel || !rel.tag_name) return;
        var version = rel.tag_name.replace(/^v/, '');
        document.querySelectorAll('[data-version]').forEach(function (e) { e.textContent = version; });
        if (rel.published_at) {
          var iso = rel.published_at.slice(0, 10), p = iso.split('-');
          var j = parseInt(p[2], 10), m = CONFIG.mois[parseInt(p[1], 10) - 1];
          var texte = CONFIG.lang === 'fr' ? j + (j === 1 ? 'er ' : ' ') + m + ' ' + p[0] : m + ' ' + j + ', ' + p[0];
          document.querySelectorAll('[data-date]').forEach(function (e) { e.textContent = texte; e.setAttribute('datetime', iso); });
        }
        var zips = (rel.assets || []).filter(function (a) { return /\.zip$/i.test(a.name); });
        var zip = zips.filter(function (a) { return a.name === 'Lyorune-' + version + '.zip'; })[0] || zips[0];
        if (zip) document.querySelectorAll('[data-archive]').forEach(function (a) { a.href = zip.browser_download_url; });
      })
      .catch(function () { /* la page des versions reste le lien */ });
  }

  // ---------- les cases de soin ----------
  var CLASSES = {
    WARRIOR: '#c69b6d', PALADIN: '#f48cba', HUNTER: '#aad372', ROGUE: '#fff468', PRIEST: '#ffffff',
    SHAMAN: '#0070dd', MAGE: '#3fc7eb', WARLOCK: '#8788ee', DRUID: '#ff7c0a'
  };
  // Couleurs de dissipation, les mêmes que dans l'addon (Auras.lua)
  var DISSIP = { magic: 'rgb(51,153,255)', curse: 'rgb(166,51,255)', disease: 'rgb(191,128,26)', poison: 'rgb(26,217,51)' };
  var ROLES = {
    TANK: '<path d="M10 1 3 4v5c0 4.4 3 8.2 7 10 4-1.8 7-5.6 7-10V4z"/>',
    HEALER: '<path d="M7 2h6v5h5v6h-5v5H7v-5H2V7h5z"/>',
    DAMAGER: '<path d="M15 1h4v4L9 15l2 2-2 2-3-3-3 3-2-2 3-3-3-3 2-2 2 2z"/>'
  };
  // Le premier groupe reprend les joueurs des captures de Lyorune ; les autres noms sont inventés
  var JOUEURS = [
    ['Bella', 'DRUID', 'HEALER'], ['Yops', 'WARRIOR', 'TANK'], ['Traqueuse', 'HUNTER', 'DAMAGER'], ['Orion', 'WARLOCK', 'DAMAGER'], ['Azuriel', 'SHAMAN', 'HEALER'],
    ['Sylvane', 'PRIEST', 'HEALER'], ['Grimdor', 'PALADIN', 'TANK'], ['Elandra', 'MAGE', 'DAMAGER'], ['Vorik', 'ROGUE', 'DAMAGER'], ['Maëlis', 'HUNTER', 'DAMAGER'],
    ['Torvald', 'WARRIOR', 'DAMAGER'], ['Isendre', 'PALADIN', 'HEALER'], ['Kazrak', 'SHAMAN', 'DAMAGER'], ['Lunelle', 'MAGE', 'DAMAGER'], ['Fendrin', 'DRUID', 'DAMAGER'],
    ['Oriane', 'PRIEST', 'DAMAGER'], ['Brumeval', 'WARLOCK', 'DAMAGER'], ['Séraphe', 'PRIEST', 'HEALER'], ['Talrik', 'ROGUE', 'DAMAGER'], ['Nyssa', 'HUNTER', 'DAMAGER'],
    ['Gorvak', 'WARRIOR', 'TANK'], ['Elwyn', 'MAGE', 'DAMAGER'], ['Mirabel', 'DRUID', 'HEALER'], ['Ardric', 'PALADIN', 'DAMAGER'], ['Kethra', 'WARLOCK', 'DAMAGER'],
    ['Morwen', 'SHAMAN', 'HEALER'], ['Halvard', 'WARRIOR', 'DAMAGER'], ['Ysolde', 'MAGE', 'DAMAGER'], ['Corvin', 'ROGUE', 'DAMAGER'], ['Thessa', 'HUNTER', 'DAMAGER'],
    ['Aldaron', 'PRIEST', 'HEALER'], ['Faelan', 'DRUID', 'DAMAGER'], ['Rowena', 'PALADIN', 'HEALER'], ['Ulric', 'WARLOCK', 'DAMAGER'], ['Zéphyra', 'MAGE', 'DAMAGER'],
    ['Garnoth', 'WARRIOR', 'DAMAGER'], ['Ilyana', 'SHAMAN', 'DAMAGER'], ['Brisk', 'ROGUE', 'DAMAGER'], ['Kaelis', 'HUNTER', 'DAMAGER'], ['Odrel', 'PRIEST', 'DAMAGER']
  ];
  var TYPES = ['magic', 'curse', 'disease', 'poison'];
  // Les soins vivants, réglés comme dans l'addon (Frames.lua, Hots.lua) : mon soin à incantation, puis mon soin sur
  // la durée (4 coups, toutes les 3 secondes), part perdue en ambre puis en cuivre au-delà d'un quart de la vie
  var SOIN = { montant: 28, incantation: 1500 }; // (1,5 s : la durée du voile dans style.css)
  var SUR_LA_DUREE = { coup: 6, coups: 4, intervalle: 3000, fin: 3000 };
  var AUTRES = { montant: 18, delai: 1400 };
  // Une couleur de classe verte reçoit la teinte de contraste du thème (même règle que l'addon)
  function estVert(hex) {
    var r = parseInt(hex.slice(1, 3), 16) / 255, g = parseInt(hex.slice(3, 5), 16) / 255, b = parseInt(hex.slice(5, 7), 16) / 255;
    return g - Math.max(r, b) >= 0.15;
  }
  var ORDRE_ROLE = { TANK: 0, HEALER: 1, DAMAGER: 2 };

  function Groupe(racine, options) {
    this.racine = racine;
    this.interactif = options.interactif;
    this.titres = options.titres;
    this.base = options.base || 1;
    this.reglages = { theme: 'PURE', joueurs: 5, taille: 100, alpha: 100, rangement: 'GROUP', contraste: false };
    this.compte = { s: 0, d: 0, r: 0 };
    this.pause = false;
    this.vu = false;
    this.nouveauCombat();
  }

  Groupe.prototype.nouveauCombat = function () {
    // les minuteurs du combat d'avant s'arrêtent (soins sur la durée) ou ne touchent plus rien (voir enCombat)
    (this.joueurs || []).forEach(function (j) { if (j.hot) clearTimeout(j.hot.minuteur); });
    this.incantation = null;
    this.joueurs = JOUEURS.map(function (j, i) {
      return { nom: j[0], classe: j[1], role: j[2], groupe: Math.floor(i / 5) + 1, vie: 100, mien: 0, autres: 0, hot: null, bouclier: 0,
               mana: j[2] === 'HEALER' ? 100 : 0, dissip: null, mort: false, loin: false, max: j[2] === 'TANK' ? 9200 : 4600 };
    });
    this.compte = { s: 0, d: 0, r: 0 };
    this.dessiner();
  };

  Groupe.prototype.actifs = function () { return this.joueurs.slice(0, this.reglages.joueurs); };
  Groupe.prototype.enCombat = function (j) { return this.joueurs.indexOf(j) >= 0; }; // pas un joueur d'un combat fini

  Groupe.prototype.appliquerTheme = function () {
    var r = this.reglages, th = CONFIG.themes[r.contraste ? 'CONTRAST' : r.theme] || CONFIG.themes.PURE, s = this.racine.style;
    s.setProperty('--fond', rgba(th.bg));
    s.setProperty('--bord', rgba(th.border, 1));
    s.setProperty('--bord-taille', th.borderSize + 'px');
    s.setProperty('--couleur-entrant', rgba(th.incoming));
    s.setProperty('--couleur-vert', rgba(th.incomingOnGreen || th.incoming));
    var hot = th.hot || th.incoming;
    s.setProperty('--couleur-hot', rgba(hot));
    s.setProperty('--couleur-hot-franc', rgba(hot, Math.min(1, (hot[3] !== undefined ? hot[3] : 1) * 1.9)));
    s.setProperty('--couleur-bouclier', rgba(th.absorb));
    s.setProperty('--relief-haut', String(th.shade[1] || 0));
    s.setProperty('--relief-bas', String(th.shade[0] || 0));
    s.setProperty('--echelle', String(r.taille / 100 * this.base));
    s.setProperty('--alpha', String(r.alpha / 100));
    this.racine.className = this.racine.className.replace(/\s*(texture-\w+|contour|haut-contraste)/g, '') +
      ' texture-' + th.texture + (th.outline ? ' contour' : '') + (r.contraste ? ' haut-contraste' : '');
  };

  Groupe.prototype.dessiner = function () {
    var self = this, r = this.reglages, liste = this.actifs().slice();
    this.appliquerTheme();
    if (r.rangement === 'ROLE') liste.sort(function (a, b) { return ORDRE_ROLE[a.role] - ORDRE_ROLE[b.role]; });
    this.racine.textContent = '';
    for (var c = 0; c < liste.length; c += 5) {
      var colonne = document.createElement('div');
      colonne.className = 'colonne';
      if (this.titres && liste.length > 5) {
        var titre = document.createElement('div');
        titre.className = 'colonne-titre';
        titre.setAttribute('aria-hidden', 'true');
        titre.textContent = r.rangement === 'GROUP' ? format(T.groupe, { n: c / 5 + 1 }) : '';
        colonne.appendChild(titre);
      }
      liste.slice(c, c + 5).forEach(function (j) { colonne.appendChild(self.creerCase(j)); });
      this.racine.appendChild(colonne);
    }
    this.compter();
  };

  Groupe.prototype.creerCase = function (j) {
    var self = this, el = document.createElement(this.interactif ? 'button' : 'div');
    if (this.interactif) el.type = 'button';
    el.className = 'case';
    el.style.setProperty('--classe', CLASSES[j.classe]);
    if (estVert(CLASSES[j.classe])) el.classList.add('vert');
    // (la part perdue après la mana, qu'elle recouvre, et sous le bouclier en bande, comme dans l'addon)
    el.innerHTML = '<span class="vie"></span><span class="mien"><i class="voile"></i></span>' +
      '<span class="autres"></span><span class="sur-la-duree"></span><span class="prochain"></span>' +
      '<span class="eclat"></span><span class="hot"></span><span class="mana"><i></i></span>' +
      '<span class="part-perdue"></span><span class="bouclier"></span><span class="nom"></span><span class="chiffre"></span>' +
      '<span class="role"><svg viewBox="0 0 20 20" aria-hidden="true">' + ROLES[j.role] + '</svg></span>';
    el.querySelector('.nom').textContent = j.nom;
    if (this.interactif) {
      el.addEventListener('click', function (e) { self.agir(j, e.shiftKey); });
      el.addEventListener('contextmenu', function (e) { e.preventDefault(); self.agir(j, true); });
    }
    j.el = el;
    this.majCase(j);
    return el;
  };

  Groupe.prototype.majCase = function (j) {
    var el = j.el;
    if (!el) return;
    var s = el.style;
    // Sur la barre, dans l'ordre : la vie, mon soin, celui des autres, mes soins sur la durée (bornés à la vie max)
    var vie = j.mort ? 0 : j.vie, place = 100 - vie;
    var mien = Math.min(j.mien, place), autres = Math.min(j.autres, place - mien);
    var reste = j.hot ? j.hot.coups * SUR_LA_DUREE.coup : 0, hot = Math.min(reste, place - mien - autres);
    s.setProperty('--vie', vie + '%');
    s.setProperty('--mien', mien + '%');
    s.setProperty('--autres', autres + '%');
    s.setProperty('--hot', hot + '%');
    s.setProperty('--prochain', Math.min(SUR_LA_DUREE.coup, hot) + '%');
    // Alerte de gaspillage : mon soin ambre si les soins en route dépassent la vie qui manque, cuivre au-delà d'un
    // quart ; la part qui sera perdue (soins sur la durée compris) se voit sur la fin de la vie, même à pleine vie
    var trop = j.mien + j.autres - place, perdu = j.mort ? 0 : Math.min(vie, Math.max(0, j.mien + j.autres + reste - place));
    el.classList.toggle('gaspi', j.mien > 0 && trop > 0);
    el.classList.toggle('gaspi-plus', j.mien > 0 && trop > 25);
    s.setProperty('--perdu', perdu + '%');
    el.classList.toggle('perte-plus', perdu > 25);
    el.classList.toggle('a-hot', !!j.hot && !j.mort);
    el.classList.toggle('hot-fin', !!j.hot && j.hot.finit);
    el.classList.toggle('incante', !!j.incante);
    s.setProperty('--bouclier', Math.min(j.bouclier, 100) + '%');
    s.setProperty('--mana-h', j.role === 'HEALER' ? 'calc(4px * var(--echelle, 1))' : '0px');
    s.setProperty('--mana', j.mana + '%');
    if (j.dissip && !j.mort) { el.setAttribute('data-dissip', j.dissip); s.setProperty('--dissip', DISSIP[j.dissip]); }
    else el.removeAttribute('data-dissip');
    el.classList.toggle('morte', j.mort);
    el.classList.toggle('loin', j.loin && !j.mort);
    var deficit = Math.round((100 - j.vie) / 100 * j.max);
    el.querySelector('.chiffre').textContent = j.mort ? T.mort : (deficit > 0 ? '-' + deficit : '');
    if (this.interactif) {
      var classe = T.classes[j.classe];
      var label = j.mort ? format(T.aria_mort, { nom: j.nom, classe: classe })
        : format(T.aria_case, { nom: j.nom, classe: classe, vie: Math.round(j.vie) });
      if (j.dissip && !j.mort) label += format(T.aria_dissip, { type: T.types[j.dissip] });
      if (j.loin && !j.mort) label += ', ' + T.loin;
      el.setAttribute('aria-label', label);
    }
  };

  Groupe.prototype.annoncer = function (texte) {
    var zone = document.querySelector('[data-annonce]');
    if (zone) zone.textContent = texte;
  };

  Groupe.prototype.compter = function () {
    var p = document.querySelector('[data-compteur]');
    if (p && this.interactif) p.textContent = format(T.compteur, this.compte);
  };

  // Un clic : relever un mort, sinon dissiper, sinon soigner ; clic droit ou Maj + clic : mon soin sur la durée
  // (dans le jeu, chaque clic a son propre sort)
  Groupe.prototype.agir = function (j, surLaDuree) {
    var self = this;
    if (j.mort) {
      if (j.releve) return;
      j.releve = true;
      setTimeout(function () {
        if (!self.enCombat(j)) return;
        j.mort = false; j.releve = false; j.vie = 35; j.dissip = null; self.compte.r++;
        self.majCase(j); self.compter(); self.annoncer(format(T.fait_releve, { nom: j.nom }));
      }, 1500);
      evenement('demo-releve');
    } else if (j.dissip && !surLaDuree) {
      var type = T.types[j.dissip];
      j.dissip = null; this.compte.d++;
      this.annoncer(format(T.fait_dissip, { type: type, nom: j.nom }));
      evenement('demo-dissip');
    } else if (surLaDuree) {
      this.poserSurLaDuree(j);
      this.compte.s++;
      this.annoncer(format(T.fait_hot, { nom: j.nom }));
      evenement('demo-soin');
    } else {
      if (this.incantation) return; // une incantation à la fois, comme dans le jeu
      this.incanter(j);
      this.compte.s++;
      this.annoncer(format(T.fait_soin, { nom: j.nom }));
      evenement('demo-soin');
    }
    this.majCase(j); this.compter();
  };

  // Mon soin à incantation : posé tout de suite au bout de la vie, un voile le remplit au rythme de l'incantation,
  // puis la vie avance d'autant pendant que mon soin se vide, et un bref éclat montre où il est tombé
  Groupe.prototype.incanter = function (j) {
    var self = this;
    this.incantation = j; j.incante = true; j.mien = SOIN.montant;
    setTimeout(function () {
      if (!self.enCombat(j)) return;
      self.incantation = null; j.incante = false; j.mien = 0;
      var avant = j.vie;
      if (!j.mort) j.vie = Math.min(100, j.vie + SOIN.montant);
      if (j.vie > avant && j.el) { // éclat sur ce que le soin a vraiment rendu
        var e = j.el;
        e.style.setProperty('--eclat', (j.vie - avant) + '%');
        e.classList.remove('arrivee'); void e.offsetWidth; e.classList.add('arrivee');
        setTimeout(function () { e.classList.remove('arrivee'); }, 450);
      }
      self.majCase(j);
    }, SOIN.incantation);
  };

  // Mon soin sur la durée : ce qu'il va encore rendre sur la barre, le prochain coup plus franc, la descente à
  // chaque coup ; relancé, il repart du début ; éclairci les 3 dernières secondes ; il tombe avec le joueur
  Groupe.prototype.poserSurLaDuree = function (j) {
    var self = this, hot = { coups: SUR_LA_DUREE.coups, finit: false };
    if (j.hot) clearTimeout(j.hot.minuteur);
    j.hot = hot;
    function coup() {
      if (j.hot !== hot) return;
      if (j.mort) { j.hot = null; self.majCase(j); return; }
      j.vie = Math.min(100, j.vie + SUR_LA_DUREE.coup);
      hot.coups--;
      hot.finit = hot.coups * SUR_LA_DUREE.intervalle <= SUR_LA_DUREE.fin;
      if (hot.coups <= 0) j.hot = null; else hot.minuteur = setTimeout(coup, SUR_LA_DUREE.intervalle);
      self.majCase(j);
    }
    hot.minuteur = setTimeout(coup, SUR_LA_DUREE.intervalle);
  };

  // Le combat : dégâts sur le tank et au hasard, affaiblissements, boucliers, soins des autres soigneurs
  Groupe.prototype.tour = function () {
    if (this.pause || !this.vu || document.hidden) return;
    var vivants = this.actifs().filter(function (j) { return !j.mort; });
    if (!vivants.length) return;
    var tanks = vivants.filter(function (j) { return j.role === 'TANK'; });
    var self = this;
    function frapper(j, degats) {
      if (j.bouclier > 0) { var absorbe = Math.min(j.bouclier, degats); j.bouclier -= absorbe; degats -= absorbe; }
      j.vie -= degats;
      if (j.vie <= 0) { j.vie = 0; j.mort = true; j.dissip = null; j.mien = 0; j.autres = 0; j.hot = null; j.bouclier = 0; }
    }
    tanks.forEach(function (j) { frapper(j, hasard(2, 6)); });
    for (var n = 0; n < Math.max(1, Math.round(vivants.length / 8)); n++) frapper(vivants[Math.floor(Math.random() * vivants.length)], hasard(2, 10));
    if (Math.random() < 0.05) vivants.forEach(function (j) { frapper(j, hasard(4, 11)); });
    if (Math.random() < 0.07) {
      var cible = vivants[Math.floor(Math.random() * vivants.length)];
      if (!cible.dissip) cible.dissip = TYPES[Math.floor(Math.random() * TYPES.length)];
    }
    if (tanks.length && Math.random() < 0.06) tanks[Math.floor(Math.random() * tanks.length)].bouclier = 30;
    vivants.forEach(function (j) {
      if (j.dissip) frapper(j, 1.2);
      if (!j.mort) j.vie = Math.min(100, j.vie + 0.8);
      if (j.role === 'HEALER') j.mana = Math.max(20, Math.min(100, j.mana + hasard(-2, 1.5)));
    });
    // les autres soigneurs : un soin en route sur le plus blessé, qui arrive un peu plus tard
    var blesse = vivants.reduce(function (p, j) { return !j.mort && (!p || j.vie < p.vie) ? j : p; }, null);
    if (blesse && Math.random() < 0.35) {
      if (blesse.vie < 85 && !blesse.aide) {
        blesse.aide = true; blesse.autres += AUTRES.montant;
        setTimeout(function () {
          blesse.aide = false; blesse.autres = Math.max(0, blesse.autres - AUTRES.montant);
          if (!blesse.mort) blesse.vie = Math.min(100, blesse.vie + AUTRES.montant);
          self.majCase(blesse);
        }, AUTRES.delai);
      }
    }
    // le petit groupe de l'accueil, sans clic : mes soins partent tout seuls, pour montrer les soins vivants
    if (!this.interactif) {
      if (blesse && !this.incantation && blesse.vie < 75 && Math.random() < 0.3) this.incanter(blesse);
      var tank = tanks[0];
      if (tank && !tank.mort && !tank.hot && Math.random() < 0.15) this.poserSurLaDuree(tank);
    }
    if (Math.random() < 0.04) {
      var dps = vivants.filter(function (j) { return j.role === 'DAMAGER'; });
      if (dps.length) {
        var loin = dps[Math.floor(Math.random() * dps.length)];
        loin.loin = true;
        setTimeout(function () { loin.loin = false; self.majCase(loin); }, 5000);
      }
    }
    this.actifs().forEach(function (j) { self.majCase(j); });
  };

  Groupe.prototype.lancer = function (delai) {
    var self = this;
    visible(this.racine, function (vu) { self.vu = vu; });
    setInterval(function () { self.tour(); }, delai);
  };

  // ---------- la démo ----------
  var scene = document.getElementById('demo-groupe');
  var demo = null;
  if (scene) {
    demo = new Groupe(scene, { interactif: true, titres: true, base: 1.3 });
    var form = document.querySelector('.demo-reglages');
    var boutonPause = form.querySelector('[data-pause]');
    var lireReglages = function () {
      var r = demo.reglages, ancien = r.joueurs + r.rangement;
      r.theme = form.theme.value;
      r.joueurs = parseInt(form.querySelector('[name=joueurs]:checked').value, 10);
      r.taille = parseInt(form.taille.value, 10);
      r.alpha = parseInt(form.alpha.value, 10);
      r.rangement = form.rangement.value;
      r.contraste = form.contraste.checked;
      form.querySelector('[name=taille-v]').textContent = r.taille + ' %';
      form.querySelector('[name=alpha-v]').textContent = r.alpha + ' %';
      if (ancien !== r.joueurs + r.rangement) demo.dessiner(); else demo.appliquerTheme();
    };
    form.addEventListener('input', lireReglages);
    form.addEventListener('change', function (e) { if (e.target.name === 'theme') evenement('demo-theme'); });
    form.addEventListener('submit', function (e) { e.preventDefault(); });
    boutonPause.addEventListener('click', function () {
      demo.pause = !demo.pause;
      boutonPause.textContent = demo.pause ? T.reprendre : T.pause;
    });
    form.querySelector('[data-zero]').addEventListener('click', function () { demo.nouveauCombat(); });
    lireReglages(); // un navigateur peut avoir gardé les choix d'avant un rechargement
    if (CALME) { demo.pause = true; boutonPause.textContent = T.reprendre; }
    demo.lancer(650);

    // « Voir dans la démo » d'un profil : ses réglages appliqués à la démo
    document.querySelectorAll('[data-essayer]').forEach(function (lien) {
      lien.addEventListener('click', function () {
        var p = JSON.parse(lien.getAttribute('data-essayer'));
        form.querySelector('[name=joueurs][value="' + p.joueurs + '"]').checked = true;
        form.taille.value = p.taille;
        form.rangement.value = p.rangement;
        form.contraste.checked = p.contraste;
        lireReglages();
      });
    });
  }

  // ---------- le petit groupe de l'accueil ----------
  var mini = document.querySelector('[data-mini]');
  if (mini) {
    var accueil = new Groupe(mini, { interactif: false, titres: false });
    accueil.reglages.taille = 140;
    accueil.dessiner();
    if (!CALME) accueil.lancer(800);
  }

  // ---------- case agrandie : pastilles et explications liées ----------
  function montrer(n, oui) {
    document.querySelectorAll('[data-pin="' + n + '"]').forEach(function (e) { e.classList.toggle('vue', oui); });
  }
  document.querySelectorAll('.pastille, .pins li').forEach(function (e) {
    var n = e.getAttribute('data-pin');
    ['mouseenter', 'focus'].forEach(function (ev) { e.addEventListener(ev, function () { montrer(n, true); }); });
    ['mouseleave', 'blur'].forEach(function (ev) { e.addEventListener(ev, function () { montrer(n, false); }); });
    if (e.classList.contains('pastille')) {
      e.addEventListener('click', function () {
        var li = document.getElementById('pin-' + n);
        if (li && window.innerWidth < 900) li.scrollIntoView({ block: 'nearest', behavior: CALME ? 'auto' : 'smooth' });
      });
    }
  });

  // ---------- codes de profil ----------
  document.querySelectorAll('[data-copier]').forEach(function (bouton) {
    var champ = bouton.closest('.profil').querySelector('input');
    var texte = bouton.textContent;
    bouton.addEventListener('click', function () {
      var fini = function () {
        bouton.textContent = bouton.getAttribute('data-copie');
        setTimeout(function () { bouton.textContent = texte; }, 1800);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(champ.value).then(fini, function () { champ.select(); });
      else { champ.select(); try { document.execCommand('copy'); fini(); } catch (x) { /* le code reste sélectionné */ } }
    });
    champ.addEventListener('focus', function () { champ.select(); });
  });

  // ---------- inscription runique : une lueur la parcourt quand elle apparaît ----------
  var inscription = document.querySelector('.inscription');
  if (inscription) {
    inscription.querySelectorAll('.rune').forEach(function (r, i) { r.style.setProperty('--i', i); });
    if (!CALME) visible(inscription, function (vu) { if (vu) inscription.classList.add('lueur'); });
  }

  // ---------- couronne du logo et quatre voies du soin (dessins sur toile) ----------
  var COULEURS = {
    druide: '110, 230, 120', paladin: '255, 210, 110', pretre: '225, 235, 255', chaman: '90, 170, 255'
  };
  function preparer(canvas) {
    var ctx = canvas.getContext('2d');
    function taille() {
      var r = window.devicePixelRatio || 1;
      canvas.width = Math.round(canvas.clientWidth * r); canvas.height = Math.round(canvas.clientHeight * r);
      ctx.setTransform(r, 0, 0, r, 0, 0);
    }
    taille();
    window.addEventListener('resize', taille);
    return ctx;
  }
  function animer(el, dessiner) {
    var actif = false, debut = performance.now(), id = 0;
    function boucle(now) { dessiner((now - debut) / 1000); if (actif) id = requestAnimationFrame(boucle); }
    if (CALME) { dessiner(1.2); return; }
    visible(el, function (vu) {
      if (vu && !actif) { actif = true; id = requestAnimationFrame(boucle); }
      else if (!vu && actif) { actif = false; cancelAnimationFrame(id); }
    });
  }
  function lueur(ctx, x, y, r, rgb, a) {
    var g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, 'rgba(' + rgb + ',' + a + ')'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
  }
  function feuille(ctx, x, y, t, ang, rgb, a) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang); ctx.fillStyle = 'rgba(' + rgb + ',' + a + ')';
    ctx.beginPath(); ctx.moveTo(-t, 0); ctx.quadraticCurveTo(0, -t * 0.55, t, 0); ctx.quadraticCurveTo(0, t * 0.55, -t, 0);
    ctx.fill(); ctx.restore();
  }
  function etoile(ctx, x, y, r1, r2, n, rot, couleur) {
    ctx.fillStyle = couleur; ctx.beginPath();
    for (var i = 0; i < n * 2; i++) {
      var r = i % 2 ? r2 : r1, a = rot + i * Math.PI / n;
      ctx[i ? 'lineTo' : 'moveTo'](x + r * Math.cos(a), y + r * Math.sin(a));
    }
    ctx.closePath(); ctx.fill();
  }
  function eclair(ctx, x0, y0, x1, y1, graine, rgb, a, larg) {
    var n = 9, dx = x1 - x0, dy = y1 - y0, l = Math.hypot(dx, dy) || 1, nx = -dy / l, ny = dx / l, s = graine;
    ctx.strokeStyle = 'rgba(' + rgb + ',' + a + ')'; ctx.lineWidth = larg || 2; ctx.lineJoin = 'round';
    ctx.beginPath(); ctx.moveTo(x0, y0);
    for (var i = 1; i < n; i++) {
      s = (s * 9301 + 49297) % 233280;
      var o = (s / 233280 - 0.5) * l * 0.18, k = i / n;
      ctx.lineTo(x0 + dx * k + nx * o, y0 + dy * k + ny * o);
    }
    ctx.lineTo(x1, y1); ctx.stroke();
  }
  var EFFETS = {
    druide: function (ctx, x, y, s, t) {
      var c = COULEURS.druide;
      lueur(ctx, x, y, s * 0.9, c, 0.35 + 0.1 * Math.sin(t * 3));
      for (var i = 0; i < 7; i++) {
        var a = i * TAU / 7 + t * 0.9, r = s * (0.32 + 0.08 * Math.sin(t * 2 + i));
        feuille(ctx, x + r * Math.cos(a), y + r * Math.sin(a), s * 0.16, a, c, 0.95);
      }
      for (var j = 0; j < 10; j++) {
        var p = ((t * 0.35 + j / 10) % 1);
        feuille(ctx, x + Math.sin(j * 7.1 + t) * s * 0.9, y + s * (0.9 - 1.8 * p), s * 0.08, t * 2 + j, c, 0.7 * Math.sin(Math.PI * p));
      }
    },
    paladin: function (ctx, x, y, s, t) {
      var c = COULEURS.paladin;
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
      var c = COULEURS.pretre;
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
      var c = COULEURS.chaman;
      lueur(ctx, x, y, s * 0.7, c, 0.35);
      for (var k = 0; k < 3; k++) {
        ctx.strokeStyle = 'rgba(' + c + ',' + (0.7 - k * 0.18) + ')'; ctx.lineWidth = 2; ctx.beginPath();
        for (var px = -s; px <= s; px += 4) {
          var py = y + s * 0.45 + k * s * 0.16 + Math.sin(px / (s * 0.18) + t * 3 + k) * s * 0.06;
          ctx[px === -s ? 'moveTo' : 'lineTo'](x + px, py);
        }
        ctx.stroke();
      }
      var pts = [[x - s * 0.6, y], [x, y - s * 0.35], [x + s * 0.6, y]], cycle = t % 1.6;
      for (var i = 0; i < 2; i++) {
        if (cycle > 0.15 + i * 0.25 && cycle < 1.2) eclair(ctx, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], Math.floor(t * 14) + i * 50, '215, 238, 255', 0.95, 2.2);
      }
      for (var j = 0; j < 3; j++) lueur(ctx, pts[j][0], pts[j][1], s * 0.18, c, cycle > 0.15 + Math.max(0, j - 1) * 0.25 && cycle < 1.3 ? 0.9 : 0.35);
    }
  };

  var couronne = document.querySelector('.couronne canvas');
  if (couronne) {
    var cx = preparer(couronne), ordre = ['druide', 'paladin', 'pretre', 'chaman'];
    animer(couronne, function (t) {
      var w = couronne.clientWidth, h = couronne.clientHeight, x0 = w / 2, y0 = h / 2;
      var R = Math.min(w, h) * 0.41, s = Math.min(w, h) * 0.085;
      cx.clearRect(0, 0, w, h);
      cx.strokeStyle = 'rgba(212, 169, 78, 0.35)'; cx.lineWidth = 1.5;
      cx.beginPath(); cx.arc(x0, y0, R, 0, TAU); cx.stroke();
      cx.setLineDash([2, 10]); cx.strokeStyle = 'rgba(240, 212, 138, 0.5)';
      cx.beginPath(); cx.arc(x0, y0, R + 8, -t * 0.1, TAU - t * 0.1); cx.stroke(); cx.setLineDash([]);
      var actif = Math.floor(t / 1.5) % 4;
      for (var k = 0; k < 4; k++) {
        var a = -Math.PI / 2 + k * TAU / 4 + t * 0.22;
        cx.save(); cx.globalAlpha = k === actif ? 1 : 0.75;
        EFFETS[ordre[k]](cx, x0 + R * Math.cos(a), y0 + R * Math.sin(a), s * (k === actif ? 1.25 : 1), t + k);
        cx.restore();
      }
      lueur(cx, x0, y0, R * 0.9, '212, 169, 78', 0.12 + 0.05 * Math.sin(t * 1.5));
    });
  }
  document.querySelectorAll('canvas[data-classe]').forEach(function (cv) {
    var ctx = preparer(cv), nom = cv.getAttribute('data-classe');
    animer(cv, function (t) {
      var w = cv.clientWidth, h = cv.clientHeight;
      ctx.clearRect(0, 0, w, h);
      EFFETS[nom](ctx, w / 2, h / 2, Math.min(w, h) * 0.42, t);
    });
  });
})();
