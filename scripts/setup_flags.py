import urllib.request
import re
import json
import os

# ISO 3166-1 alpha-2 codes and names (simplified list for major countries, can be expanded)
# I will try to fetch a full list if possible, otherwise I will use a very large hardcoded list.
# For robustness, I'll include a comprehensive list.

COUNTRIES = {
    "ad": "Andorra", "ae": "United Arab Emirates", "af": "Afghanistan", "ag": "Antigua and Barbuda",
    "ai": "Anguilla", "al": "Albania", "am": "Armenia", "ao": "Angola", "aq": "Antarctica", "ar": "Argentina",
    "as": "American Samoa", "at": "Austria", "au": "Australia", "aw": "Aruba", "ax": "Åland Islands",
    "az": "Azerbaijan", "ba": "Bosnia and Herzegovina", "bb": "Barbados", "bd": "Bangladesh", "be": "Belgium",
    "bf": "Burkina Faso", "bg": "Bulgaria", "bh": "Bahrain", "bi": "Burundi", "bj": "Benin", "bl": "Saint Barthélemy",
    "bm": "Bermuda", "bn": "Brunei", "bo": "Bolivia", "bq": "Caribbean Netherlands", "br": "Brazil",
    "bs": "Bahamas", "bt": "Bhutan", "bv": "Bouvet Island", "bw": "Botswana", "by": "Belarus", "bz": "Belize",
    "ca": "Canada", "cc": "Cocos (Keeling) Islands", "cd": "DR Congo", "cf": "Central African Republic",
    "cg": "Republic of the Congo", "ch": "Switzerland", "ci": "Côte d'Ivoire", "ck": "Cook Islands",
    "cl": "Chile", "cm": "Cameroon", "cn": "China", "co": "Colombia", "cr": "Costa Rica", "cu": "Cuba",
    "cv": "Cabo Verde", "cw": "Curaçao", "cx": "Christmas Island", "cy": "Cyprus", "cz": "Czechia", "cz": "Czech Republic",
    "de": "Germany", "dj": "Djibouti", "dk": "Denmark", "dm": "Dominica", "do": "Dominican Republic",
    "dz": "Algeria", "ec": "Ecuador", "ee": "Estonia", "eg": "Egypt", "eh": "Western Sahara", "er": "Eritrea",
    "es": "Spain", "et": "Ethiopia", "eu": "European Union", "fi": "Finland", "fj": "Fiji", "fk": "Falkland Islands",
    "fm": "Micronesia", "fo": "Faroe Islands", "fr": "France", "ga": "Gabon", "gb": "United Kingdom",
    "gb-eng": "England", "gb-wls": "Wales", "gb-sct": "Scotland", "gb-nir": "Northern Ireland",
    "gd": "Grenada", "ge": "Georgia", "gf": "French Guiana", "gg": "Guernsey", "gh": "Ghana", "gi": "Gibraltar",
    "gl": "Greenland", "gm": "Gambia", "gn": "Guinea", "gp": "Guadeloupe", "gq": "Equatorial Guinea",
    "gr": "Greece", "gs": "South Georgia", "gt": "Guatemala", "gu": "Guam", "gw": "Guinea-Bissau",
    "gy": "Guyana", "hk": "Hong Kong", "hm": "Heard Island and McDonald Islands", "hn": "Honduras",
    "hr": "Croatia", "ht": "Haiti", "hu": "Hungary", "id": "Indonesia", "ie": "Ireland", "il": "Israel",
    "im": "Isle of Man", "in": "India", "io": "British Indian Ocean Territory", "iq": "Iraq", "ir": "Iran",
    "is": "Iceland", "it": "Italy", "je": "Jersey", "jm": "Jamaica", "jo": "Jordan", "jp": "Japan",
    "ke": "Kenya", "kg": "Kyrgyzstan", "kh": "Cambodia", "ki": "Kiribati", "km": "Comoros", "kn": "Saint Kitts and Nevis",
    "kp": "North Korea", "kr": "South Korea", "kw": "Kuwait", "ky": "Cayman Islands", "kz": "Kazakhstan",
    "la": "Laos", "lb": "Lebanon", "lc": "Saint Lucia", "li": "Liechtenstein", "lk": "Sri Lanka", "lr": "Liberia",
    "ls": "Lesotho", "lt": "Lithuania", "lu": "Luxembourg", "lv": "Latvia", "ly": "Libya", "ma": "Morocco",
    "mc": "Monaco", "md": "Moldova", "me": "Montenegro", "mf": "Saint Martin", "mg": "Madagascar",
    "mh": "Marshall Islands", "mk": "North Macedonia", "ml": "Mali", "mm": "Myanmar", "mn": "Mongolia",
    "mo": "Macau", "mp": "Northern Mariana Islands", "mq": "Martinique", "mr": "Mauritania", "ms": "Montserrat",
    "mt": "Malta", "mu": "Mauritius", "mv": "Maldives", "mw": "Malawi", "mx": "Mexico", "my": "Malaysia",
    "mz": "Mozambique", "na": "Namibia", "nc": "New Caledonia", "ne": "Niger", "nf": "Norfolk Island",
    "ng": "Nigeria", "ni": "Nicaragua", "nl": "Netherlands", "no": "Norway", "np": "Nepal", "nr": "Nauru",
    "nu": "Niue", "nz": "New Zealand", "om": "Oman", "pa": "Panama", "pe": "Peru", "pf": "French Polynesia",
    "pg": "Papua New Guinea", "ph": "Philippines", "pk": "Pakistan", "pl": "Poland", "pm": "Saint Pierre and Miquelon",
    "pn": "Pitcairn Islands", "pr": "Puerto Rico", "ps": "Palestine", "pt": "Portugal", "pw": "Palau",
    "py": "Paraguay", "qa": "Qatar", "re": "Réunion", "ro": "Romania", "rs": "Serbia", "ru": "Russia",
    "rw": "Rwanda", "sa": "Saudi Arabia", "sb": "Solomon Islands", "sc": "Seychelles", "sd": "Sudan",
    "se": "Sweden", "sg": "Singapore", "sh": "Saint Helena, Ascension and Tristan da Cunha", "si": "Slovenia",
    "sj": "Svalbard and Jan Mayen", "sk": "Slovakia", "sl": "Sierra Leone", "sm": "San Marino", "sn": "Senegal",
    "so": "Somalia", "sr": "Suriname", "ss": "South Sudan", "st": "São Tomé and Príncipe", "sv": "El Salvador",
    "sx": "Sint Maarten", "sy": "Syria", "sz": "Eswatini", "tc": "Turks and Caicos Islands", "td": "Chad",
    "tf": "French Southern Territories", "tg": "Togo", "th": "Thailand", "tj": "Tajikistan", "tk": "Tokelau",
    "tl": "Timor-Leste", "tm": "Turkmenistan", "tn": "Tunisia", "to": "Tonga", "tr": "Turkey", "tt": "Trinidad and Tobago",
    "tv": "Tuvalu", "tw": "Taiwan", "tz": "Tanzania", "ua": "Ukraine", "ug": "Uganda", "um": "United States Minor Outlying Islands",
    "un": "United Nations", "us": "United States", "uy": "Uruguay", "uz": "Uzbekistan", "va": "Vatican City",
    "vc": "Saint Vincent and the Grenadines", "ve": "Venezuela", "vg": "British Virgin Islands",
    "vi": "United States Virgin Islands", "vn": "Vietnam", "vu": "Vanuatu", "wf": "Wallis and Futuna",
    "ws": "Samoa", "xk": "Kosovo", "ye": "Yemen", "yt": "Mayotte", "za": "South Africa", "zm": "Zambia", "zw": "Zimbabwe"
}

# Add common aliases
ALIASES = {
    "England": "gb-eng", "Scotland": "gb-sct", "Wales": "gb-wls", "Britain": "gb", "Great Britain": "gb",
    "USA": "us", "UK": "gb", "Deutschland": "de", "The Netherlands": "nl", "Korea": "kr", "South Korea": "kr",
    "Russia": "ru", "Viet Nam": "vn"
}

OUTPUT_SVG = "web/assets/symbol-defs.svg"
OUTPUT_JS_MAP = "web/assets/country_map.js"

def fetch_svg(code):
    url = f"https://flagcdn.com/{code}.svg"
    try:
        with urllib.request.urlopen(url) as response:
            return response.read().decode('utf-8')
    except Exception as e:
        print(f"Failed to fetch {code}: {e}")
        return None

def main():
    if not os.path.exists("web/assets"):
        os.makedirs("web/assets", exist_ok=True)

    header = '<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">\n'
    footer = '</svg>'
    
    content = ""
    
    print("Fetching flags...")
    count = 0
    # Use sorted codes for consistency
    codes = sorted(list(set(COUNTRIES.keys()))) # .keys() contains some dupes because of my dict definition if I repeated any? No, dict keys are unique.
    # Ah, I have "cz": "Czechia" and "cz": "Czech Republic" in my pasted text?
    # Python dict literal will just take the last one. That's fine.

    for code in codes:
        svg_data = fetch_svg(code)
        if svg_data:
            # Extract content and viewBox
            # FlagCDN returns <svg ... viewBox="..."> ... </svg>
            viewbox_match = re.search(r'viewBox="([^"]+)"', svg_data)
            viewbox = viewbox_match.group(1) if viewbox_match else "0 0 640 480"
            
            # Remove svg tag
            inner_content = re.sub(r'<svg[^>]*>', '', svg_data)
            inner_content = re.sub(r'</svg>', '', inner_content)
            
            symbol = f'  <symbol id="icon-{code}" viewBox="{viewbox}">\n  {inner_content}\n  </symbol>\n'
            content += symbol
            count += 1
            if count % 10 == 0:
                print(f"Fetched {count} flags...")
        else:
            print(f"Skipping {code}")

    with open(OUTPUT_SVG, "w") as f:
        f.write(header + content + footer)
    
    print(f"Written {count} flags to {OUTPUT_SVG}")

    # Generate Reverse Map (Country Name -> Code)
    reverse_map = {}
    for code, name in COUNTRIES.items():
        reverse_map[name] = code
    
    # Add aliases
    for alias, code in ALIASES.items():
        reverse_map[alias] = code
        
    js_content = f"window.COUNTRY_MAP = {json.dumps(reverse_map, indent=2)};"
    with open(OUTPUT_JS_MAP, "w") as f:
        f.write(js_content)
    
    print(f"Written JS map to {OUTPUT_JS_MAP}")

if __name__ == "__main__":
    main()
