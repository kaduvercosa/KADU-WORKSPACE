import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# Update fetchEvolutions to extract conditions
new_evo = """    async function fetchEvolutions(url) {
      try {
        const evoRes = await fetch(url); const evoData = await evoRes.json(); let evolutions = [];

        function extractEvo(node) {
            let id = node.species.url.split('/')[6];

            // Extract details safely
            let detailsObj = node.evolution_details && node.evolution_details.length > 0 ? node.evolution_details[0] : null;
            let conditionText = '';

            if (detailsObj) {
                if (detailsObj.min_level) conditionText = `Lvl ${detailsObj.min_level}`;
                else if (detailsObj.item) conditionText = detailsObj.item.name.replace(/-/g, ' ');
                else if (detailsObj.trigger.name === 'trade') conditionText = 'Troca';
                else if (detailsObj.min_happiness) conditionText = 'Amizade';
                else conditionText = '?';
            }

            evolutions.push({ name: node.species.name, id: id, condition: conditionText });
            node.evolves_to.forEach(evo => extractEvo(evo));
        }

        extractEvo(evoData.chain);
        const evoDiv = document.getElementById('evolutions'); const evoList = document.getElementById('evo-list'); evoList.innerHTML = '';
        if (evolutions.length > 1) {
          evoDiv.style.display = 'block'; evolutions.forEach(evo => {

            let card = document.createElement('div'); card.className = 'evo-card';
            const glassBg = document.createElement('div');
            glassBg.className = 'glass-bg liquid-glass';
            card.appendChild(glassBg);

            card.onclick = () => { document.getElementById('search-input').value = ''; fetchPokemon(evo.id); };

            const idDiv = document.createElement('div');
            idDiv.className = 'evo-id';
            idDiv.textContent = `#${evo.id.padStart(3,'0')}`;

            const img = document.createElement('img');
            img.src = `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${evo.id}.png`;

            const nameDiv = document.createElement('div');
            nameDiv.className = 'evo-name';
            nameDiv.textContent = evo.name.replace(/-/g, ' ');

            card.appendChild(idDiv);
            card.appendChild(img);
            card.appendChild(nameDiv);

            if (evo.condition) {
                const condDiv = document.createElement('div');
                condDiv.style.fontSize = '9px';
                condDiv.style.fontWeight = '800';
                condDiv.style.background = 'rgba(0,0,0,0.3)';
                condDiv.style.color = '#fff';
                condDiv.style.padding = '2px 6px';
                condDiv.style.borderRadius = '8px';
                condDiv.style.marginTop = '4px';
                condDiv.style.textTransform = 'capitalize';
                condDiv.textContent = evo.condition;
                card.appendChild(condDiv);
            }

            evoList.appendChild(card);

            fetch('https://pokeapi.co/api/v2/pokemon/' + evo.id).then(r => r.json()).then(pData => {

                   const pType = pData.types[0].type.name;
                   let bgColor = typeColors[pType] || '#777';
                   if (pData.types.length > 1) {
                       const secColor = typeColors[pData.types[1].type.name] || '#777';
                       bgColor = `linear-gradient(180deg, ${bgColor} 0%, ${secColor} 100%)`;
                   }
                   card.style.setProperty('--card-bg', bgColor); card.classList.add('colored-card');

            }).catch(e=>{ console.error("Error fetching evolution data:", e); });
          });
        } else { evoDiv.style.display = 'none'; }
      } catch (e) { console.error("Error fetching evolutions:", e); }
    }"""

content = re.sub(r'async function fetchEvolutions\(url\) \{.*?\} catch \(e\) \{ console\.error\("Error fetching evolutions:", e\); \}\n    \}', new_evo, content, flags=re.DOTALL)

with open("Pokedex/index.html", "w") as f:
    f.write(content)
