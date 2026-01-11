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
        .analytics-value { font-size: 1.5rem; color: var(--primary); font-weight: bold; margin: 10px 0; }
        .analytics-label { font-size: 0.8rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
        .top-country-item { display: flex; align-items: center; justify-content: space-between; margin-bottom: 5px; font-size: 0.9rem; }
        .top-country-bar-bg { background: rgba(255,255,255,0.05); height: 4px; border-radius: 2px; width: 100%; margin-top: 4px; }
        .top-country-bar-fg { background: var(--primary); height: 100%; border-radius: 2px; }
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

        if (is_dir($scanDir)) {
            $files = scandir($scanDir);
            foreach ($files as $file) {
                if (str_ends_with($file, '.txt')) {
                    $filePath = $scanDir . '/' . $file;
                    if (filemtime($filePath) >= $thirtyMinsAgo) {
                        $handle = fopen($filePath, "r");
                        if ($handle) {
                            $firstLine = fgets($handle);
                            fclose($handle);
                            if (str_contains($firstLine, 'Geolocation:')) {
                                $parts = explode(':', $firstLine);
                                if (isset($parts[1])) {
                                    $geoContent = explode(',', $parts[1]);
                                    $country = trim($geoContent[0]);
                                    if ($country) {
                                        $topCountries[$country] = ($topCountries[$country] ?? 0) + 1;
                                        $totalRecent++;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            arsort($topCountries);
            $top3 = array_slice($topCountries, 0, 3, true);
            $top3Sum = array_sum($top3);
        }

        $countryEmojis = [
            'Germany' => '🇩🇪', 'United States' => '🇺🇸', 'China' => '🇨🇳', 'Russia' => '🇷🇺',
            'France' => '🇫🇷', 'United Kingdom' => '🇬🇧', 'Japan' => '🇯🇵', 'Brazil' => '🇧🇷',
            'Canada' => '🇨🇦', 'India' => '🇮🇳', 'Netherlands' => '🇳🇱', 'Ukraine' => '🇺🇦',
            'Cyprus' => '🇨🇾', 'Seychelles' => '🇸🇨', 'Singapore' => '🇸🇬', 'Hong Kong' => '🇭🇰'
        ];
        ?>

        <div class="section">
            <h2>Real-time Analytics (Last 30m)</h2>
            <div class="analytics-grid">
                <div class="analytics-card">
                    <div class="analytics-label">Active Scans</div>
                    <div class="analytics-value"><?php echo number_format($totalRecent); ?></div>
                    <div class="analytics-label">Last 30 Minutes</div>
                </div>
                <div class="analytics-card" style="grid-column: span 2;">
                    <div class="analytics-label">Top 3 Threat Origins</div>
                    <div style="margin-top: 10px;">
                        <?php if (empty($top3)): ?>
                            <div style="color: #64748b; font-style: italic;">No recent scan data</div>
                        <?php else: ?>
                            <?php foreach ($top3 as $country => $count): 
                                $pct = $top3Sum > 0 ? round(($count / $top3Sum) * 100) : 0;
                                $emoji = $countryEmojis[$country] ?? '🏳️';
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
            <input type="text" id="searchInput" class="search-box" placeholder="Search reports..." onkeyup="filterReports()">
            <ul class="report-list">
                <?php
                if (is_dir($scanDir)) {
                    usort($txtFiles, function($a, $b) use ($scanDir) {
                        return filemtime($scanDir . '/' . $b) - filemtime($scanDir . '/' . $a);
                    });
                    foreach ($txtFiles as $file) {
                        echo '<li class="report-item"><a href="scans/' . htmlspecialchars($file) . '">' . htmlspecialchars($file) . '</a></li>';
                    }
                } else {
                    echo '<!-- Scans dir not found -->';
                }
                ?>
            </ul>
        </div>
        
        <footer style="margin-top: 50px; text-align: center; color: #64748b; font-size: 0.8rem;">
            &copy; <?php echo date("Y"); ?> Honey-Scan Active Defense System. for you by lemue.org &hearts;
        </footer>
    </div>
    <script>
        window.onload = checkStatus;

        function filterReports() {
            var input, filter, ul, li, a, i, txtValue;
            input = document.getElementById('searchInput');
            filter = input.value.toUpperCase();
            ul = document.querySelector('.report-list');
            li = ul.getElementsByTagName('li');
            for (i = 0; i < li.length; i++) {
                a = li[i].getElementsByTagName("a")[0];
                txtValue = a.textContent || a.innerText;
                if (txtValue.toUpperCase().indexOf(filter) > -1) {
                    li[i].style.display = "";
                } else {
                    li[i].style.display = "none";
                }
            }
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
