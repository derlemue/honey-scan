<?php
// Performance & Security Headers
header("Cache-Control: public, max-age=300");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: SAMEORIGIN");
header("X-XSS-Protection: 1; mode=block");
if (extension_loaded('zlib')) {
    ob_start('ob_gzhandler');
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>lemueIO Active Intelligence Feed</title>
    <style>
        :root { --primary: #4ade80; --bg: #0f172a; --panel: #1e293b; --text: #e2e8f0; }
        body { background-color: var(--bg); color: var(--text); font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 0; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        header { display: flex; align-items: center; gap: 20px; padding-bottom: 20px; border-bottom: 1px solid #334155; margin-bottom: 30px; flex-wrap: wrap; }
        .header-brand { display: flex; align-items: center; gap: 20px; flex: 1; min-width: 250px; }
        .logo { width: 60px; height: 60px; border-radius: 50%; object-fit: cover; border: 2px solid var(--primary); }
        h1 { margin: 0; font-size: 1.5rem; color: var(--text); font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
        .section { background: var(--panel); border-radius: 8px; padding: 20px; margin-bottom: 20px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        h2 { margin-top: 0; font-size: 0.9rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 15px; border-bottom: 1px solid #334155; padding-bottom: 10px; }
        .resource-link { display: flex; align-items: center; gap: 10px; text-decoration: none; color: var(--primary); font-family: monospace; font-size: 1.1rem; padding: 5px 0; }
        .resource-link:hover { text-decoration: underline; }
        .resource-desc { color: #94a3b8; font-size: 0.9rem; font-family: sans-serif; }
        .report-list { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 10px; }
        .report-item a { display: block; padding: 12px; background: rgba(255,255,255,0.03); color: var(--primary); text-decoration: none; border-radius: 4px; font-family: monospace; transition: all 0.2s; border: 1px solid transparent; }
        .report-item a:hover { background: rgba(74, 222, 128, 0.1); border-color: var(--primary); transform: translateY(-2px); }
        
        .search-box { width: 100%; padding: 12px; background: rgba(255,255,255,0.05); border: 1px solid #334155; color: var(--text); border-radius: 4px; font-size: 1rem; margin-bottom: 20px; box-sizing: border-box; }
        .search-box:focus { outline: none; border-color: var(--primary); background: rgba(255,255,255,0.1); }

        .status-btn { padding: 8px 16px; background: rgba(255,255,255,0.05); border: 1px solid #334155; color: var(--text); border-radius: 20px; cursor: pointer; font-size: 0.9rem; transition: all 0.2s; display: flex; align-items: center; gap: 8px; text-decoration: none; white-space: nowrap; }
        .status-btn:hover { background: rgba(255,255,255,0.1); border-color: var(--primary); }
        .status-dot { width: 8px; height: 8px; border-radius: 50%; background: #94a3b8; box-shadow: 0 0 5px rgba(148, 163, 184, 0.5); }
        .status-safe .status-dot { background: #4ade80; box-shadow: 0 0 8px #4ade80; }
        .status-banned .status-dot { background: #ef4444; box-shadow: 0 0 8px #ef4444; }

        /* Scrollbar */
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: var(--bg); }
        ::-webkit-scrollbar-thumb { background: #334155; border-radius: 4px; }
        ::-webkit-scrollbar-thumb:hover { background: var(--primary); }

        @media (max-width: 600px) {
            .report-list { grid-template-columns: 1fr; }
        }

        .analytics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 25px; }
        .analytics-card { background: rgba(255,255,255,0.03); border: 1px solid #334155; border-radius: 8px; padding: 15px; text-align: center; }
        .analytics-value { font-size: 4.5rem; color: var(--primary); font-weight: bold; margin: 10px 0; }
        .analytics-label { font-size: 0.8rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
        .top-country-item { display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px; font-size: 0.9rem; }
        .top-country-bar-bg { background: rgba(255,255,255,0.05); height: 4px; border-radius: 2px; width: 100%; margin-top: 4px; }
        .top-country-bar-fg { background: var(--primary); height: 100%; border-radius: 2px; }
        
        /* Grouping Styles */
        .country-group { margin-top: 20px; }
        .country-group-header { display: flex; align-items: center; gap: 10px; font-size: 1rem; color: var(--primary); font-weight: bold; margin-bottom: 15px; border-bottom: 1px solid rgba(74, 222, 128, 0.2); padding-bottom: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="header-brand">
                <img src="logo.jpg" alt="Logo" class="logo">
                <h1>lemueIO Active Intelligence Feed</h1>
            </div>
            <button class="status-btn" onclick="fillSearch()" id="statusBtn">
                <div class="status-dot"></div>
                <span id="statusText">Check My Status</span>
            </button>
        </header>
        
        <div class="section">
            <h2>Resources<?php
                $bannedIpsFile = './banned_ips.txt';
                if (file_exists($bannedIpsFile)) {
                    $lines = file($bannedIpsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                    $bannedCount = count($lines);
                    echo ' (' . number_format($bannedCount) . ' Banned IPs)';
                }
            ?></h2>
            <a href="banned_ips.txt" class="resource-link">banned_ips.txt <span class="resource-desc">List of unique attacker IPs (Fail2Ban Compatible)</span></a>
        </div>

        <?php
        $scanDir = './scans';
        $topCountries = [];
        $totalRecent = 0;
        $thirtyMinsAgo = time() - (30 * 60);
        $metaCacheFile = './reports_meta.json';
        $metaCache = [];

        if (file_exists($metaCacheFile)) {
            $metaCache = json_decode(file_get_contents($metaCacheFile), true) ?: [];
        }

        $countryEmojis = [
            'Afghanistan' => 'AF', 'Albania' => 'AL', 'Algeria' => 'DZ', 'Andorra' => 'AD', 'Angola' => 'AO', 'Antigua and Barbuda' => 'AG', 
            'Argentina' => 'AR', 'Armenia' => 'AM', 'Australia' => 'AU', 'Austria' => 'AT', 'Azerbaijan' => 'AZ', 'Bahamas' => 'BS', 
            'Bahrain' => 'BH', 'Bangladesh' => 'BD', 'Barbados' => 'BB', 'Belarus' => 'BY', 'Belgium' => 'BE', 'Belize' => 'BZ', 
            'Benin' => 'BJ', 'Bhutan' => 'BT', 'Bolivia' => 'BO', 'Bosnia and Herzegovina' => 'BA', 'Botswana' => 'BW', 'Brazil' => 'BR', 
            'Brunei' => 'BN', 'Bulgaria' => 'BG', 'Burkina Faso' => 'BF', 'Burundi' => 'BI', 'Cabo Verde' => 'CV', 'Cambodia' => 'KH', 
            'Cameroon' => 'CM', 'Canada' => 'CA', 'Central African Republic' => 'CF', 'Chad' => 'TD', 'Chile' => 'CL', 'China' => 'CN', 
            'Colombia' => 'CO', 'Comoros' => 'KM', 'Congo' => 'CG', 'Costa Rica' => 'CR', 'Croatia' => 'HR', 'Cuba' => 'CU', 
            'Cyprus' => 'CY', 'Czech Republic' => 'CZ', 'Denmark' => 'DK', 'Djibouti' => 'DJ', 'Dominica' => 'DM', 'Dominican Republic' => 'DO', 
            'Ecuador' => 'EC', 'Egypt' => 'EG', 'El Salvador' => 'SV', 'Equatorial Guinea' => 'GQ', 'Eritrea' => 'ER', 'Estonia' => 'EE', 
            'Eswatini' => 'SZ', 'Ethiopia' => 'ET', 'Fiji' => 'FJ', 'Finland' => 'FI', 'France' => 'FR', 'Gabon' => 'GA', 'Gambia' => 'GM', 
            'Georgia' => 'GE', 'Germany' => 'DE', 'Ghana' => 'GH', 'Greece' => 'GR', 'Grenada' => 'GD', 'Guatemala' => 'GT', 
            'Guinea' => 'GN', 'Guinea-Bissau' => 'GW', 'Guyana' => 'GY', 'Haiti' => 'HT', 'Honduras' => 'HN', 'Hungary' => 'HU', 
            'Iceland' => 'IS', 'India' => 'IN', 'Indonesia' => 'ID', 'Iran' => 'IR', 'Iraq' => 'IQ', 'Ireland' => 'IE', 'Israel' => 'IL', 
            'Italy' => 'IT', 'Jamaica' => 'JM', 'Japan' => 'JP', 'Jordan' => 'JO', 'Kazakhstan' => 'KZ', 'Kenya' => 'KE', 'Kiribati' => 'KI', 
            'Korea' => 'KR', 'Kuwait' => 'KW', 'Kyrgyzstan' => 'KG', 'Laos' => 'LA', 'Latvia' => 'LV', 'Lebanon' => 'LB', 'Lesotho' => 'LS', 
            'Liberia' => 'LR', 'Libya' => 'LY', 'Liechtenstein' => 'LI', 'Lithuania' => 'LT', 'Luxembourg' => 'LU', 'Madagascar' => 'MG', 
            'Malawi' => 'MW', 'Malaysia' => 'MY', 'Maldives' => 'MV', 'Mali' => 'ML', 'Malta' => 'MT', 'Marshall Islands' => 'MH', 
            'Mauritania' => 'MR', 'Mauritius' => 'MU', 'Mexico' => 'MX', 'Micronesia' => 'FM', 'Moldova' => 'MD', 'Monaco' => 'MC', 
            'Mongolia' => 'MN', 'Montenegro' => 'ME', 'Morocco' => 'MA', 'Mozambique' => 'MZ', 'Myanmar' => 'MM', 'Namibia' => 'NA', 
            'Nauru' => 'NR', 'Nepal' => 'NP', 'Netherlands' => 'NL', 'The Netherlands' => 'NL', 'New Zealand' => 'NZ', 
            'Nicaragua' => 'NI', 'Niger' => 'NE', 'Nigeria' => 'NG', 'North Macedonia' => 'MK', 'Norway' => 'NO', 'Oman' => 'OM', 
            'Pakistan' => 'PK', 'Palau' => 'PW', 'Panama' => 'PA', 'Papua New Guinea' => 'PG', 'Paraguay' => 'PY', 'Peru' => 'PE', 
            'Philippines' => 'PH', 'Poland' => 'PL', 'Portugal' => 'PT', 'Qatar' => 'QA', 'Romania' => 'RO', 'Russia' => 'RU', 
            'Rwanda' => 'RW', 'Saint Kitts and Nevis' => 'KN', 'Saint Lucia' => 'LC', 'Saint Vincent and the Grenadines' => 'VC', 
            'Samoa' => 'WS', 'San Marino' => 'SM', 'Sao Tome and Principe' => 'ST', 'Saudi Arabia' => 'SA', 'Senegal' => 'SN', 
            'Serbia' => 'RS', 'Seychelles' => 'SC', 'Sierra Leone' => 'SL', 'Singapore' => 'SG', 'Slovakia' => 'SK', 'Slovenia' => 'SI', 
            'Solomon Islands' => 'SB', 'Somalia' => 'SO', 'South Africa' => 'ZA', 'South Sudan' => 'SS', 'Spain' => 'ES', 
            'Sri Lanka' => 'LK', 'Sudan' => 'SD', 'Suriname' => 'SR', 'Sweden' => 'SE', 'Switzerland' => 'CH', 'Syria' => 'SY', 
            'Taiwan' => 'TW', 'Tajikistan' => 'TJ', 'Tanzania' => 'TZ', 'Thailand' => 'TH', 'Timor-Leste' => 'TL', 'Togo' => 'TG', 
            'Tonga' => 'TO', 'Trinidad and Tobago' => 'TT', 'Tunisia' => 'TN', 'Turkey' => 'TR', 'Turkmenistan' => 'TM', 'Tuvalu' => 'TV', 
            'Uganda' => 'UG', 'Ukraine' => 'UA', 'United Arab Emirates' => 'AE', 'United Kingdom' => 'GB', 'United States' => 'US', 
            'Uruguay' => 'UY', 'Uzbekistan' => 'UZ', 'Vanuatu' => 'VU', 'Vatican City' => 'VA', 'Venezuela' => 'VE', 'Vietnam' => 'VN', 
            'Yemen' => 'YE', 'Zambia' => 'ZM', 'Zimbabwe' => 'ZW'
        ];

        function getEmoji($country) {
            global $countryEmojis;
            $code = $countryEmojis[$country] ?? null;
            if (!$code) return '🏳️';
            
            // Convert ISO code to regional indicator emojis
            return mb_convert_encoding('&#' . (127397 + ord($code[0])) . ';', 'UTF-8', 'HTML-ENTITIES') . 
                   mb_convert_encoding('&#' . (127397 + ord($code[1])) . ';', 'UTF-8', 'HTML-ENTITIES');
        }

        if (is_dir($scanDir)) {
            $files = scandir($scanDir);
            $newMeta = false;
            foreach ($files as $file) {
                if (str_ends_with($file, '.txt')) {
                    $filePath = $scanDir . '/' . $file;
                    $mtime = filemtime($filePath);
                    
                    // Analytics logic (Recent only)
                    if ($mtime >= $thirtyMinsAgo) {
                        $country = "Unknown";
                        if (isset($metaCache[$file]) && $metaCache[$file]['mtime'] == $mtime) {
                            $country = $metaCache[$file]['country'];
                        } else {
                            $handle = fopen($filePath, "r");
                            if ($handle) {
                                $firstLine = fgets($handle);
                                fclose($handle);
                                if (str_contains($firstLine, 'Geolocation:')) {
                                    $parts = explode(':', $firstLine);
                                    if (isset($parts[1])) {
                                        $geoContent = explode(',', $parts[1]);
                                        $country = trim($geoContent[0]);
                                    }
                                }
                            }
                            $metaCache[$file] = ['country' => $country, 'mtime' => $mtime];
                            $newMeta = true;
                        }

                        if ($country && $country != "Unknown") {
                            $topCountries[$country] = ($topCountries[$country] ?? 0) + 1;
                            $totalRecent++;
                        }
                    }
                }
            }
            if ($newMeta && is_writable('.')) {
                @file_put_contents($metaCacheFile, json_encode($metaCache));
            }
            arsort($topCountries);
            $top10 = array_slice($topCountries, 0, 10, true);
            $top10Sum = array_sum($top10);
        }
        ?>

        <div class="section">
            <h2>Real-time Analytics (Last 30m)</h2>
            <div class="analytics-grid">
                <div class="analytics-card" style="display: flex; flex-direction: column; justify-content: center; height: 100%;">
                    <div class="analytics-label">Active Scans</div>
                    <div class="analytics-value"><?php echo number_format($totalRecent); ?></div>
                    <div class="analytics-label">Last 30 Minutes</div>
                </div>
                <div class="analytics-card" style="grid-column: span 2;">
                    <div class="analytics-label">Top 10 Threat Origins</div>
                    <div style="margin-top: 10px; display: grid; grid-template-columns: 1fr 1fr; gap: 0 20px;">
                        <?php if (empty($top10)): ?>
                            <div style="color: #64748b; font-style: italic; grid-column: span 2;">No recent scan data</div>
                        <?php else: ?>
                            <?php foreach ($top10 as $country => $count): 
                                $pct = $top10Sum > 0 ? round(($count / $top10Sum) * 100) : 0;
                                $emoji = getEmoji($country);
                            ?>
                                <div style="margin-bottom: 8px;">
                                    <div class="top-country-item">
                                        <span><?php echo $emoji . ' ' . htmlspecialchars($country); ?></span>
                                        <span><?php echo $count; ?> (<?php echo $pct; ?>%)</span>
                                    </div>
                                    <div class="top-country-bar-bg">
                                        <div class="top-country-bar-fg" style="width: <?php echo $pct; ?>%;"></div>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>Scan Reports<?php
                $scanDir = './scans';
                if (is_dir($scanDir)) {
                    $files = scandir($scanDir);
                    $txtFiles = array();
                    foreach ($files as $file) {
                        if (str_ends_with($file, '.txt')) {
                            $txtFiles[] = $file;
                        }
                    }
                    $reportCount = count($txtFiles);
                    echo ' (' . number_format($reportCount) . ' Reports)';
                }
            ?></h2>
            <input type="text" id="searchInput" class="search-box" placeholder="Search reports (grouping starts at 2 octets)..." onkeyup="filterReports()">
            <div id="reportContainer">
                <ul class="report-list" id="mainReportList">
                    <?php
                    if (is_dir($scanDir)) {
                        usort($txtFiles, function($a, $b) use ($scanDir) {
                            return filemtime($scanDir . '/' . $b) - filemtime($scanDir . '/' . $a);
                        });
                        foreach ($txtFiles as $file) {
                            $country = $metaCache[$file]['country'] ?? 'Unknown';
                            echo '<li class="report-item" data-country="' . htmlspecialchars($country) . '"><a href="scans/' . htmlspecialchars($file) . '">' . htmlspecialchars($file) . '</a></li>';
                        }
                    } else {
                        echo '<!-- Scans dir not found -->';
                    }
                    ?>
                </ul>
            </div>
        </div>
        
        <footer style="margin-top: 50px; text-align: center; color: #64748b; font-size: 0.8rem;">
            &copy; <?php echo date("Y"); ?> Honey-Scan Active Defense System. for you by lemue.org &hearts;
        </footer>
    </div>
    <script>
        window.onload = checkStatus;

        const countryEmojis = <?php 
            $jsMap = [];
            foreach($countryEmojis as $c => $code) {
                $jsMap[$c] = getEmoji($c);
            }
            echo json_encode($jsMap); 
        ?>;
        const originalList = document.getElementById('mainReportList').innerHTML;

        function filterReports() {
            const input = document.getElementById('searchInput');
            const filter = input.value.trim().toUpperCase();
            const container = document.getElementById('reportContainer');
            
            // Trigger grouping only if at least 2 blocks are present (e.g. 1.2)
            const parts = filter.split('.').filter(p => p !== '');
            if (parts.length < 2) {
                // Normal plain list
                container.innerHTML = '<ul class="report-list" id="mainReportList">' + originalList + '</ul>';
                const li = container.getElementsByTagName('li');
                for (let i = 0; i < li.length; i++) {
                    const txtValue = li[i].textContent || li[i].innerText;
                    li[i].style.display = txtValue.toUpperCase().indexOf(filter) > -1 ? "" : "none";
                }
                return;
            }

            // Grouped results (3+ chars)
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = originalList;
            const items = Array.from(tempDiv.getElementsByTagName('li'));
            
            const filteredItems = items.filter(li => {
                const txtValue = li.textContent || li.innerText;
                return txtValue.toUpperCase().indexOf(filter) > -1;
            });

            const groups = {};
            filteredItems.forEach(li => {
                const country = li.getAttribute('data-country') || 'Unknown';
                if (!groups[country]) groups[country] = [];
                groups[country].push(li.outerHTML);
            });

            let html = '';
            // Sort countries alphabetically
            const sortedCountries = Object.keys(groups).sort();
            
            sortedCountries.forEach(country => {
                const emoji = countryEmojis[country] || '🏳️';
                html += `<div class="country-group">`;
                html += `<div class="country-group-header"><span>${emoji}</span> ${country} (${groups[country].length})</div>`;
                html += `<ul class="report-list">${groups[country].join('')}</ul>`;
                html += `</div>`;
            });

            if (html === '') html = '<div style="padding: 20px; color: #64748b; text-align: center;">No reports found for this query</div>';
            container.innerHTML = html;
        }

        let currentUserIp = '';

        async function checkStatus() {
            const btn = document.getElementById('statusBtn');
            const txt = document.getElementById('statusText');
            
            // txt.innerText = "Checking..."; // Don't show loading text on auto-check to avoid flicker
            
            try {
                // 1. Get User IP
                const ipResp = await fetch('https://api.ipify.org?format=json');
                const ipData = await ipResp.json();
                currentUserIp = ipData.ip;
                
                // 2. Get Banned List
                const listResp = await fetch('banned_ips.txt');
                const listText = await listResp.text();
                
                // Use exact matching to avoid false positives (e.g. 1.2.3.4 matching 11.2.3.4)
                const bannedIps = listText.split('\n').map(ip => ip.trim()).filter(ip => ip !== '');
                const isBanned = bannedIps.includes(currentUserIp);
                
                if (isBanned) {
                    btn.className = "status-btn status-banned";
                    txt.innerText = "You are BANNED (" + currentUserIp + ")";
                } else {
                    btn.className = "status-btn status-safe";
                    txt.innerText = "You are Safe (" + currentUserIp + ")";
                }
            } catch (e) {
                console.error(e);
                txt.innerText = "Check Failed";
            }
        }

        function fillSearch() {
            if (currentUserIp) {
                const input = document.getElementById('searchInput');
                input.value = currentUserIp;
                filterReports();
            } else {
                checkStatus(); // Retry check if empty
            }
        }
    </script>
</body>
</html>
