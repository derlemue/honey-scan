<div align="center">

# 🍯 Honey-Scan
### Aktives Verteidigungs-Ökosystem

<img src="docs/img/logo.png" width="200">

<br>

![Version](https://img.shields.io/badge/version-4.2.0-blue.svg)
![Fork](https://img.shields.io/badge/Forked%20from-hacklcx%2FHFish-9cf?style=flat&logo=github)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Shell](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=flat&logo=nginx&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat&logo=mariadb&logoColor=white)

*Verwandle deinen Honeypot in ein aktives Verteidigungssystem, das zurück beißt.*

[🇬🇧 English](README.md) | [🇩🇪 Deutsch](README_DE.md) | [🇩🇪 Einfache Sprache](README_DE2.md) | [🇺🇦 Українська](README_UA.md)

</div>

---

> [!WARNING]
> **⚠️ HAFTUNGSAUSSCHLUSS: HOCHRISIKO-TOOL ⚠️**
>
> Dieses Tool führt **AKTIVE AUFKLÄRUNG** (Nmap-Scans) gegen IP-Adressen durch, die sich mit deinem Honeypot verbinden.
> *   **Rechtliches Risiko**: Das Scannen von Systemen ohne Erlaubnis kann in deiner Gerichtsbarkeit illegal sein.
> *   **Vergeltung**: Aggressives Scannen von Angreifern kann stärkere Angriffe (DDoS) provozieren oder deine Infrastruktur exponieren.
> *   **Nutzung**: Nutzung streng für Bildungszwecke oder in kontrollierten Umgebungen, in denen du die volle Haftung übernimmst. **Die Autoren sind nicht verantwortlich für Missbrauch oder rechtliche Konsequenzen.**

---

## 🔴 Live Vorschau (Early Beta)

Testen Sie das System live!

### Dashboard (Early Beta)
*   **URL**: [https://sec.lemue.org/web/login](https://sec.lemue.org/web/login)
*   **Benutzer**: `beta_view`
*   **Passwort**: `O7u1uN98H65Lcna6TV`

### Feed (Live)
*   **URL**: [https://feed.sec.lemue.org/](https://feed.sec.lemue.org/)

---

## 📖 Übersicht

**Honey-Scan** transformiert einen passiven HFish-Honeypot in ein **Aktives Verteidigungssystem**. Anstatt Angriffe nur zu protokollieren, reagiert es (informativ).

Wenn ein Angreifer deinen Honeypot berührt, wird Honey-Scan automatisch:
1.  **🕵️ Erkennen**: Die Intrusion über die HFish-Datenbank erkennen.
2.  **🔍 Scannen**: Den Angreifer sofort mit `nmap` scannen.
3.  **📢 Veröffentlichen**: Die Informationen in einem lokalen Feed bereitstellen.
4.  **🛡️ Blockieren**: Den Angreifer auf deiner Produktionsinfrastruktur blockieren (über Client-Skripte).

---

## 🚀 Hauptfunktionen

*   **⚡ Echtzeit-Reaktion**: Python-Sidecar überwacht `hfish.db` und löst Sekunden nach einem Angriff Scans aus.
*   **📊 Automatisierte Intel**: Generiert detaillierte `.txt`-Berichte für jede eindeutige Angreifer-IP.
*   **🚫 Netzwerk-Schutzschild**: Stellt eine dynamische `banned_ips.txt`-Liste bereit, die andere Server nutzen können, um Bedrohungen präventiv zu blockieren.
*   **🖥️ Dashboard**: Einfache Weboberfläche zum Durchsuchen von Scan-Berichten und Bannlisten.
*   **🖼️ Visualisierungen**:
    *   **Login Interface**:
        <br>
        <div align="center">
        <img src="docs/img/login_v2.png" width="80%">
        <p><em>Anmeldebildschirm</em></p>
        </div>
    *   **Live Threat Feed**:
        <br>
        <div align="center">
        <img src="docs/img/feed_dashboard_v5.png" width="80%">
        <p><em>Feed Dashboard</em></p>
        </div>
    *   **lemueIO SecMonitor ("Screen")**:
        <br>
        <div align="center">
        <img src="docs/img/hfish_screen_v4.png" width="80%">
        <p><em>Angriffskarte Dashboard</em></p>
        </div>
    *   **lemueIO Statistics** (Intern):
        <br>
        <div align="center">
        <img src="docs/img/hfish_dashboard_v4.png" width="80%">
        <p><em>Statistics Dashboard</em></p>
        </div>

---

## 🏗️ Architektur

Das System läuft als eine Reihe von Docker-Containern als Erweiterung der Kern-HFish-Binary:

| Dienst | Typ | Beschreibung |
| :--- | :--- | :--- |
| **HFish** | 🍯 Core | Die Basis-Honeypot-Plattform (Management & Nodes). (Standard-Ports `80`/`443`) |
| **Sidecar** | 🐍 Python | Das Gehirn. Überwacht die DB, orchestriert Nmap, aktualisiert Feeds. |
| **Feed** | 🌐 Nginx | Stellt Berichte und Bannlisten auf Port `8888` bereit. |

```mermaid
graph LR
    A[👹 Angreifer] -- 1. Hacks --> B(🍯 HFish)
    B -- 2. Logs --> C[(💽 DB)]
    D[🐍 Sidecar] -- 3. Überwacht --> C
    D -- 4. Nmap Scan --> A
    D -- 5. Aktualisiert --> E[📂 Feed]
    F[💻 Dashboard] -- Liest --> E
    G[🛡️ Prod Server] -- 6. Feeds & Blockiert --> E
```

## 🛠️ Installation

### 📦 Datenbank-Setup (MariaDB)
1.  Kopiere die Beispiel-Environment-Datei:
    ```bash
    cp .env.example .env
    ```
2.  **Bearbeite `.env`** und setze sichere Passwörter für `DB_PASSWORD` und `MYSQL_ROOT_PASSWORD`.
3.  Nutze diese Werte beim Konfigurieren des HFish-Assistenten.

| Einstellung | Wert |
| :--- | :--- |
| **Datenbank Typ** | **MySQL / MariaDB** |
| **Adresse** | `127.0.0.1` |
| **Port** | `3307` |
| **Name** | `hfish` |
| **Benutzername** | `hfish` |
| **Passwort** | *(Der Wert aus `.env`)* |

### 0. Automatisches Host-Setup (Debian 13)
Wir stellen ein Setup-Skript bereit, das:
1.  **Docker** & **Git** installiert.
2.  SSH härtet, indem es auf Port **2222** verschoben wird (um Port 22 für den Honeypot freizugeben).
3.  Das System neu startet.

```bash
# Herunterladen und als root ausführen
wget https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/setup_host.sh
chmod +x setup_host.sh
sudo ./setup_host.sh
```

> [!CAUTION]
> **SSH WARNUNG**: Nach Abschluss des Skripts ändert sich dein SSH-Port auf **2222**.
> Stelle sicher, dass du dich mit `ssh user@host -p 2222` verbindest und diesen Port in deiner Firewall erlaubst!

### 1. Server Starten
Klone das Repo und starte den Stack:

```bash
git clone https://github.com/derlemue/honey-scan.git
cd honey-scan
docker compose up -d --build
```

### 2. Dashboards erreichen
*   **lemueIO Active Intelligence Feed**: `http://localhost:8888`
*   **HFish Admin**: `https://localhost:4433` (Standard: `admin` / `HFish2021`)

### 3. Client Shield deployen (Fail2Ban Integration)
Schütze deine *anderen* Server, indem du IPs automatisch bannst, die von diesem Honeypot erkannt wurden.
Benötigt **Fail2Ban**. Das Skript bietet die Installation an, falls es fehlt.

Führe dies auf deinen Produktionsservern aus:
```bash
# Skript herunterladen
wget https://feed.sec.lemue.org/scripts/client_banned_ips.sh

# Ausführbar machen
chmod +x client_banned_ips.sh

# Ausführen (Benötigt Root für Fail2Ban)
sudo ./client_banned_ips.sh
```

### 4. Automatische Updates (Cron)
Halte deine Bannliste aktuell, indem das Skript alle 15 Minuten ausgeführt wird.

```bash
# Root-Crontab öffnen
sudo crontab -e

# Folgende Zeile hinzufügen (Pfad anpassen!):
*/15 * * * * /pfad/zu/client_banned_ips.sh > /dev/null 2>&1
```

## 📜 Über Core HFish

Dieses Projekt basiert auf [HFish](https://hfish.net), einem leistungsstarken Community-Honeypot.
*   **Basis-Funktionen**: Unterstützt SSH, Redis, Mysql Web-Honeypots und mehr.
*   **Visualisierung**: Schöne Angriffskarten und Statistiken im nativen HFish-Admin-Panel.
*   **Hinweis**: Dieses Repository konzentriert sich auf die *Active Defense* Erweiterung. Für Core-HFish-Dokumentation siehe die [offiziellen Docs](https://hfish.net/#/docs).

---
*Gepflegt von der Honey-Scan Community.*
