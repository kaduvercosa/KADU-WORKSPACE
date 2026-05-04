import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# I accidentally deleted applySettings entirely when trying to delete oldApplySettings.
# I need to restore it.

apply_fn = """
    function applySettings() {
      const saved = localStorage.getItem('pokedex-settings');
      if (!saved) return;

      try {
        const s = JSON.parse(saved);

        if (document.getElementById('setting-theme')) {
            document.getElementById('setting-theme').value = s.theme || 'auto';
            document.getElementById('setting-monochrome').checked = s.monochrome || false;
            document.getElementById('setting-fontsize').value = s.fontsize || 'normal';
            document.getElementById('setting-units').value = s.units || 'metric';
            document.getElementById('setting-startup').value = s.startup || 'random';
            document.getElementById('setting-glass').checked = s.glass !== undefined ? s.glass : true;
            document.getElementById('setting-glow').checked = s.glow !== undefined ? s.glow : true;
            document.getElementById('setting-anim').checked = s.anim !== undefined ? s.anim : true;
            document.getElementById('setting-stats').checked = s.stats !== undefined ? s.stats : true;
            document.getElementById('setting-moves').checked = s.moves !== undefined ? s.moves : true;
            document.getElementById('setting-extra').checked = s.extra !== undefined ? s.extra : true;
            document.getElementById('setting-evo').checked = s.evo !== undefined ? s.evo : true;
        }

        isImperial = s.units === 'imperial';

        if (s.theme === 'auto' || !s.theme) { document.documentElement.removeAttribute('data-theme'); }
        else { document.documentElement.setAttribute('data-theme', s.theme); }

        document.body.classList.toggle('monochrome', s.monochrome === true);
        document.body.classList.remove('font-small', 'font-large');
        if (s.fontsize === 'small') document.body.classList.add('font-small');
        if (s.fontsize === 'large') document.body.classList.add('font-large');

        document.body.classList.toggle('no-glass', s.glass === false);
        document.body.classList.toggle('no-glow', s.glow === false);
        document.body.classList.toggle('no-anim', s.anim === false);

        document.body.classList.toggle('hide-stats', s.stats === false);
        document.body.classList.toggle('hide-moves', s.moves === false);
        document.body.classList.toggle('hide-extra', s.extra === false);
        document.body.classList.toggle('hide-evo', s.evo === false);

      } catch (e) { console.error("Error applying settings", e); }
    }
"""

content = content.replace("function updatePokemonUI(data) {", apply_fn + "\n    function updatePokemonUI(data) {")

with open("Pokedex/index.html", "w") as f:
    f.write(content)
