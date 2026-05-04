import re

with open("Pokedex/index.html", "r") as f:
    content = f.read()

# remove old saveSettings completely to avoid syntax errors
# The replacement in the previous step created a syntax error by just prepending the new functions.

# Regex to find the broken block:
#     // OVERRIDDEN saveSettings
#       const settings = {
#         theme: document.getElementById('setting-theme').value,
#         ...
#       applySettings();
#     }
import re

pattern = re.compile(r'// OVERRIDDEN saveSettings.*?applySettings\(\);\n    }', re.DOTALL)
content = re.sub(pattern, '', content)

with open("Pokedex/index.html", "w") as f:
    f.write(content)
