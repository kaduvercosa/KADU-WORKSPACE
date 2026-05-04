import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# 1. Update Settings Modal HTML to add new options
settings_html = """      <div class="setting-group">
        <h4>Visual e Efeitos</h4>
        <div class="setting-item">
          <span class="setting-label">Tema Visual</span>
          <select id="setting-theme" class="modal-select" onchange="saveSettings()">
            <option value="auto">Automático</option>
            <option value="light">Forçar Claro</option>
            <option value="dark">Forçar Escuro</option>
          </select>
        </div>
        <div class="setting-item">
          <span class="setting-label">Modo Monocromático</span>
          <label class="switch"><input type="checkbox" id="setting-monochrome" onchange="saveSettings()"><span class="slider"></span></label>
        </div>
        <div class="setting-item">
          <span class="setting-label">Tamanho da Fonte</span>
          <select id="setting-fontsize" class="modal-select" onchange="saveSettings()">
            <option value="small">Pequena</option>
            <option value="normal" selected>Normal</option>
            <option value="large">Grande</option>
          </select>
        </div>
        <div class="setting-item">
          <span class="setting-label">Efeito de Vidro (Blur)</span>
          <label class="switch"><input type="checkbox" id="setting-glass" onchange="saveSettings()" checked><span class="slider"></span></label>
        </div>
        <div class="setting-item">
          <span class="setting-label">Efeitos de Brilho (Glow)</span>
          <label class="switch"><input type="checkbox" id="setting-glow" onchange="saveSettings()" checked><span class="slider"></span></label>
        </div>
        <div class="setting-item">
          <span class="setting-label">Animação de Flutuação</span>
          <label class="switch"><input type="checkbox" id="setting-anim" onchange="saveSettings()" checked><span class="slider"></span></label>
        </div>
      </div>

      <div class="setting-group">
        <h4>Dados e Sistema</h4>
        <div class="setting-item">
          <span class="setting-label">Sistema de Medidas</span>
          <select id="setting-units" class="modal-select" onchange="saveSettings()">
            <option value="metric" selected>Métrico (m/kg)</option>
            <option value="imperial">Imperial (ft/lbs)</option>
          </select>
        </div>
        <div class="setting-item">
          <span class="setting-label">Tela Inicial</span>
          <select id="setting-startup" class="modal-select" onchange="saveSettings()">
            <option value="random" selected>Aleatório</option>
            <option value="grid">Grade Completa</option>
          </select>
        </div>
      </div>"""

content = re.sub(r'      <div class="setting-group">\s*<h4>Visual e Efeitos</h4>.*?</div>\s*</div>\s*</div>', settings_html + '\n\n      <div class="setting-group">\n        <h4>Ocultar/Mostrar Seções</h4>\n        <div class="setting-item">\n          <span class="setting-label">Atributos Base</span>\n          <label class="switch"><input type="checkbox" id="setting-stats" onchange="saveSettings()" checked><span class="slider"></span></label>\n        </div>\n        <div class="setting-item">\n          <span class="setting-label">Movimentos (Moves)</span>\n          <label class="switch"><input type="checkbox" id="setting-moves" onchange="saveSettings()" checked><span class="slider"></span></label>\n        </div>\n        <div class="setting-item">\n          <span class="setting-label">Dados Extra (Captura, Fraquezas)</span>\n          <label class="switch"><input type="checkbox" id="setting-extra" onchange="saveSettings()" checked><span class="slider"></span></label>\n        </div>\n        <div class="setting-item">\n          <span class="setting-label">Evoluções e Formas Alt.</span>\n          <label class="switch"><input type="checkbox" id="setting-evo" onchange="saveSettings()" checked><span class="slider"></span></label>\n        </div>\n      </div>\n    </div>\n  </div>', content, flags=re.DOTALL)

with open("Pokedex/index.html", "w") as f:
    f.write(content)
