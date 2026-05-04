import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# 2. Add New Details Modal HTML
details_html = """  <!-- DETAILS MODAL -->
  <div id="details-modal">
    <div class="modal-overlay" onclick="closeDetailsModal()"></div>
    <div class="modal-content details-content">
      <div class="modal-header">
        <h3 class="modal-title" id="dm-title">Detalhes do Pokémon</h3>
        <button class="close-btn" onclick="closeDetailsModal()">×</button>
      </div>

      <div class="dm-section">
        <h4 class="dm-subtitle">Galeria de Sprites</h4>
        <div class="dm-gallery" id="dm-gallery">
           <!-- Sprites will be injected here -->
        </div>
      </div>

      <div class="dm-section">
        <h4 class="dm-subtitle">Reprodução (Breeding)</h4>
        <div class="info-grid">
          <div class="info-box"><span class="info-label">Gênero</span><span class="info-value" id="dm-gender">-</span></div>
          <div class="info-box"><span class="info-label">Ciclos (Passos)</span><span class="info-value" id="dm-cycles">-</span></div>
          <div class="info-box full-width"><span class="info-label">Grupos de Ovos</span><span class="info-value" id="dm-egggroups">-</span></div>
        </div>
      </div>

      <div class="dm-section">
        <h4 class="dm-subtitle">Treinamento</h4>
        <div class="info-grid">
          <div class="info-box"><span class="info-label">Exp Base</span><span class="info-value" id="dm-baseexp">-</span></div>
          <div class="info-box"><span class="info-label">Amizade Base</span><span class="info-value" id="dm-basehappiness">-</span></div>
          <div class="info-box"><span class="info-label">Taxa de Captura</span><span class="info-value" id="dm-capturerate">-</span></div>
          <div class="info-box full-width"><span class="info-label">Pontos de Esforço (EV Yield)</span><span class="info-value" id="dm-evs">-</span></div>
        </div>
      </div>

      <div class="dm-section">
        <h4 class="dm-subtitle">Localizações de Encontro</h4>
        <div class="dm-encounters" id="dm-encounters">Carregando...</div>
      </div>
    </div>
  </div>

  <!-- SETTINGS MODAL -->"""

content = content.replace("  <!-- SETTINGS MODAL -->", details_html)

# 3. Add CSS for new options and Details Modal
css_overrides = """
    /* FONT SIZES */
    body.font-small { font-size: 12px; }
    body.font-small #poke-name { font-size: clamp(24px, 6vw, 36px); }
    body.font-small .info-value { font-size: 12px; }

    body.font-large { font-size: 16px; }
    body.font-large #poke-name { font-size: clamp(32px, 8vw, 48px); }
    body.font-large .info-value { font-size: 16px; }

    /* MONOCHROME MODE */
    body.monochrome {
      --type-color: #888888 !important;
      --type-dark: #333333 !important;
      --nav-bg: #444444 !important;
      --bg-gradient: linear-gradient(135deg, #dddddd 0%, #aaaaaa 100%) !important;
    }
    @media (prefers-color-scheme: dark) {
      body.monochrome:not([data-theme="light"]), :root[data-theme="dark"] body.monochrome {
        --bg-gradient: linear-gradient(135deg, #333333 0%, #111111 100%) !important;
        --nav-bg: #222222 !important;
      }
    }
    body.monochrome .type-badge, body.monochrome .mini-type, body.monochrome .stat-bar-fill { background: #888 !important; filter: grayscale(100%); }
    body.monochrome #main-card, body.monochrome #search-container, body.monochrome .colored-card { --card-bg: transparent !important; }

    /* DETAILS MODAL CSS */
    #details-modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 10000; display: none; align-items: center; justify-content: center; opacity: 0; transition: opacity 0.3s ease; }
    #details-modal.show-modal { display: flex; opacity: 1; }
    .details-content { width: 95%; max-width: 600px; max-height: 90vh; }
    .dm-section { margin-bottom: 25px; background: rgba(0,0,0,0.03); padding: 15px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.05); }
    @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) .dm-section { background: rgba(255,255,255,0.02); } }
    :root[data-theme="dark"] .dm-section { background: rgba(255,255,255,0.02); }
    .dm-subtitle { margin: 0 0 15px 0; font-size: 13px; color: var(--type-color); text-transform: uppercase; letter-spacing: 1px; font-weight: 900; }

    .dm-gallery { display: grid; grid-template-columns: repeat(auto-fit, minmax(80px, 1fr)); gap: 10px; justify-items: center; }
    .dm-sprite-box { display: flex; flex-direction: column; align-items: center; padding: 5px; background: var(--glass-panel); border-radius: 12px; border: 1px solid var(--glass-border); width: 100%; }
    .dm-sprite-img { width: 70px; height: 70px; object-fit: contain; filter: drop-shadow(0 4px 6px rgba(0,0,0,0.2)); }
    .dm-sprite-label { font-size: 9px; font-weight: 800; text-transform: uppercase; margin-top: 5px; text-align: center; color: var(--text-muted); }

    .dm-encounters { font-size: 12px; line-height: 1.5; max-height: 120px; overflow-y: auto; padding-right: 5px; }
    .dm-enc-item { background: var(--glass-panel); padding: 6px 10px; border-radius: 8px; margin-bottom: 5px; display: inline-block; margin-right: 5px; font-weight: 600; border: 1px solid var(--glass-border); }

    /* Make image clickable */
    #poke-image { cursor: pointer; }
"""

content = content.replace("body.hide-evo #evolutions, body.hide-evo #varieties { display: none !important; }", "body.hide-evo #evolutions, body.hide-evo #varieties { display: none !important; }\n" + css_overrides)


with open("Pokedex/index.html", "w") as f:
    f.write(content)
