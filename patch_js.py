import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# 4. Update JS logic to handle new settings and open Details Modal
js_new_logic = """
    let currentSpeciesData = null; // Store species data for details modal
    let isImperial = false; // Store unit preference

    function openDetailsModal() {
        if (!currentPokemonData || !currentSpeciesData) return;

        document.getElementById('dm-title').innerText = currentPokemonData.name.replace(/-/g, ' ') + ' - Detalhes';

        // 1. Sprites Gallery
        const gallery = document.getElementById('dm-gallery');
        gallery.innerHTML = '';
        const sprites = currentPokemonData.sprites;
        const addSprite = (url, label) => {
            if(!url) return;
            const box = document.createElement('div'); box.className = 'dm-sprite-box';
            const img = document.createElement('img'); img.className = 'dm-sprite-img'; img.src = url;
            const span = document.createElement('span'); span.className = 'dm-sprite-label'; span.innerText = label;
            box.appendChild(img); box.appendChild(span); gallery.appendChild(box);
        };

        addSprite(sprites.front_default, 'Frente (Padrão)');
        addSprite(sprites.back_default, 'Costas (Padrão)');
        addSprite(sprites.front_shiny, 'Frente (Shiny)');
        addSprite(sprites.back_shiny, 'Costas (Shiny)');
        addSprite(sprites.other?.showdown?.front_default, 'Animado');
        addSprite(sprites.other?.home?.front_default, 'Home 3D');

        if (gallery.innerHTML === '') gallery.innerHTML = '<span style="font-size:12px; opacity:0.6;">Nenhum sprite adicional encontrado.</span>';

        // 2. Breeding
        const genderRate = currentSpeciesData.gender_rate;
        let genderText = 'Desconhecido';
        if (genderRate === -1) genderText = 'Sem Gênero';
        else if (genderRate >= 0) {
            const femalePct = (genderRate / 8) * 100;
            const malePct = 100 - femalePct;
            genderText = `♂ ${malePct}% | ♀ ${femalePct}%`;
        }
        document.getElementById('dm-gender').innerText = genderText;

        const hatchCounter = currentSpeciesData.hatch_counter;
        document.getElementById('dm-cycles').innerText = hatchCounter ? `${hatchCounter} ciclos (~${hatchCounter * 257} passos)` : 'N/A';

        const eggGroups = currentSpeciesData.egg_groups;
        document.getElementById('dm-egggroups').innerText = eggGroups && eggGroups.length > 0 ? eggGroups.map(e => e.name.replace(/-/g, ' ')).join(', ') : 'Desconhecido';

        // 3. Training
        document.getElementById('dm-baseexp').innerText = currentPokemonData.base_experience || 'N/A';
        document.getElementById('dm-basehappiness').innerText = currentSpeciesData.base_happiness || 'N/A';
        document.getElementById('dm-capturerate').innerText = currentSpeciesData.capture_rate || 'N/A';

        const evs = currentPokemonData.stats.filter(s => s.effort > 0);
        document.getElementById('dm-evs').innerText = evs.length > 0 ? evs.map(e => `${e.effort} ${statMap[e.stat.name] || e.stat.name}`).join(', ') : 'Nenhum';

        // 4. Encounters
        const encContainer = document.getElementById('dm-encounters');
        encContainer.innerHTML = 'Carregando...';
        fetch(currentPokemonData.location_area_encounters)
            .then(r => r.json())
            .then(data => {
                if (data.length === 0) {
                    encContainer.innerHTML = '<span style="opacity:0.6;">Não encontrado na natureza (Apenas evolução/evento).</span>';
                } else {
                    encContainer.innerHTML = '';
                    // Translate area names roughly (replace dashes)
                    const areas = data.slice(0, 15).map(enc => {
                        let name = enc.location_area.name.replace(/-/g, ' ');
                        return `<span class="dm-enc-item">${name}</span>`;
                    });
                    encContainer.innerHTML = areas.join('');
                    if (data.length > 15) encContainer.innerHTML += `<span class="dm-enc-item">...e mais ${data.length - 15} locais</span>`;
                }
            }).catch(e => {
                encContainer.innerHTML = '<span style="opacity:0.6; color:red;">Erro ao carregar locais.</span>';
            });

        document.getElementById('details-modal').classList.add('show-modal');
    }

    function closeDetailsModal() { document.getElementById('details-modal').classList.remove('show-modal'); }

    // Settings adjustments
    function saveSettings() {
      const settings = {
        theme: document.getElementById('setting-theme').value,
        monochrome: document.getElementById('setting-monochrome').checked,
        fontsize: document.getElementById('setting-fontsize').value,
        units: document.getElementById('setting-units').value,
        startup: document.getElementById('setting-startup').value,
        glass: document.getElementById('setting-glass').checked,
        glow: document.getElementById('setting-glow').checked,
        anim: document.getElementById('setting-anim').checked,
        stats: document.getElementById('setting-stats').checked,
        moves: document.getElementById('setting-moves').checked,
        extra: document.getElementById('setting-extra').checked,
        evo: document.getElementById('setting-evo').checked
      };
      localStorage.setItem('pokedex-settings', JSON.stringify(settings));
      applySettings();
      // Re-render current pokemon to apply unit changes
      if(currentPokemonData) updatePokemonUI(currentPokemonData);
    }

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

    function updatePokemonUI(data) {
        if (!data) return;

        let heightM = data.height / 10;
        let weightKg = data.weight / 10;

        if (isImperial) {
            // Convert to ft/in and lbs
            let totalInches = heightM * 39.3701;
            let ft = Math.floor(totalInches / 12);
            let inc = Math.round(totalInches % 12);
            document.getElementById('poke-height').innerText = `${ft}'${inc}"`;

            let lbs = (weightKg * 2.20462).toFixed(1);
            document.getElementById('poke-weight').innerText = `${lbs} lbs`;
        } else {
            document.getElementById('poke-height').innerText = heightM.toFixed(1) + ' m';
            document.getElementById('poke-weight').innerText = weightKg.toFixed(1) + ' kg';
        }
    }
"""

content = content.replace("function saveSettings() {", js_new_logic + "\n    // OVERRIDDEN saveSettings")
content = content.replace("function applySettings() {", "function oldApplySettings() {")
content = content.replace("img id=\"poke-image\" src=\"\" alt=\"\" onclick=\"randomPokemon()\"", "img id=\"poke-image\" src=\"\" alt=\"\" onclick=\"openDetailsModal()\" title=\"Clique para ver mais detalhes!\"")

# Update fetchPokemon to save currentSpeciesData and call updatePokemonUI
content = content.replace("let speciesUrl = data.species.url; let speciesData = null;", "let speciesUrl = data.species.url; let speciesData = null;\n        currentSpeciesData = null;")
content = content.replace("if (speciesData) {", "if (speciesData) {\n           currentSpeciesData = speciesData;")
content = content.replace("document.getElementById('poke-height').innerText = (data.height / 10).toFixed(1) + ' m';\n        document.getElementById('poke-weight').innerText = (data.weight / 10).toFixed(1) + ' kg';", "updatePokemonUI(data);")

# Update startup logic
content = content.replace("""    const urlId = getPokemonFromUrl();
    if (urlId && urlId.trim() !== "" && urlId !== "null") {
      fetchPokemon(urlId);
    } else {
      fetchPokemon(Math.floor(Math.random() * 1025) + 1);
    }

    // SETTINGS LOGIC""", """    const urlId = getPokemonFromUrl();

    // Initialize settings FIRST so startup pref is known
    applySettings();

    if (urlId && urlId.trim() !== "" && urlId !== "null") {
      fetchPokemon(urlId);
    } else {
      const saved = localStorage.getItem('pokedex-settings');
      let startup = 'random';
      if (saved) { try { startup = JSON.parse(saved).startup; } catch(e){} }

      if (startup === 'grid') {
          toggleView();
          document.getElementById('gen-filter').value = '1';
          loadPokedex('1', 'gen');
      } else {
          fetchPokemon(Math.floor(Math.random() * 1025) + 1);
      }
    }

    // SETTINGS LOGIC""")

content = content.replace("applySettings();\n    adjustSpacer();", "adjustSpacer();") # Remove the duplicate applySettings at the end

with open("Pokedex/index.html", "w") as f:
    f.write(content)
