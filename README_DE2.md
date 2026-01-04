<div align="center">

# 🍯 Honey-Scan
### Aktive Verteidigung

<img src="docs/img/logo.png" width="200">

<br>

![Version](https://img.shields.io/badge/version-4.1.1-blue.svg)
![Fork](https://img.shields.io/badge/Forked%20from-hacklcx%2FHFish-9cf?style=flat&logo=github)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)

*Mach deinen Honeypot stark. Er soll sich wehren.*

[🇬🇧 English](README.md) | [🇩🇪 Deutsch](README_DE.md) | [🇩🇪 Einfache Sprache](README_DE2.md) | [🇺🇦 Українська](README_UA.md)

</div>

---

> [!WARNING]
> **⚠️ ACHTUNG: GEFÄHRLICHES WERKZEUG ⚠️**
>
> Dieses Programm scannt Angreifer zurück (Nmap).
> *   **Gefahr**: Das kann illegal sein.
> *   **Risiko**: Angreifer könnten wütend werden und stärker angreifen.
> *   **Benutzung**: Nur zum Lernen benutzen. Du bist selbst verantwortlich.

---

## 📖 Was ist das?

**Honey-Scan** macht aus einem normalen Honeypot (HFish) eine **Aktive Verteidigung**.
Normalerweise sammelt ein Honeypot nur Daten. Honey-Scan beißt zurück.

Wenn dich jemand angreift:
1.  **🕵️ Merken**: Das System merkt den Angriff.
2.  **🔍 Scannen**: Das System scannt den Angreifer sofort zurück.
3.  **📢 Teilen**: Das System schreibt einen Bericht.
4.  **🛡️ Blocken**: Deine anderen Server können den Angreifer automatisch blockieren.

---

## 🚀 Was kann es?

*   **⚡ Schnell**: Es reagiert in Sekunden.
*   **📊 Berichte**: Es macht Text-Dateien mit Infos über den Angreifer.
*   **🚫 Schutz-Liste**: Es gibt eine Liste mit bösen IPs (`banned_ips.txt`). Deine Server können diese Liste nutzen, um sich zu schützen.
*   **🖥️ Übersicht**: Es gibt eine Webseite, wo man alles sehen kann.

---

## 🛠️ HFish Login

<div align="center">
<img src="docs/img/login_v2.png" width="80%">
<p><em>Login Seite</em></p>
</div>

Wenn du dich einloggen willst:
1.  Gehe auf die Login-Seite.
2.  Gib deinen Benutzernamen und dein Passwort ein.
3.  Löse das kleine Rätsel (Captcha).
4.  Klicke auf "Sign In" (Anmelden).

---

## 🏗️ Wie funktioniert es?

Es sind drei Teile, die zusammenarbeiten (Docker):

| Teil | Was er macht |
| :--- | :--- |
| **HFish** | Der Honigtopf. Er lockt Angreifer an. |
| **Sidecar** | Das Gehirn. Es merkt Angriffe und startet den Gegen-Scan. |
| **Feed** | Die Webseite. Sie zeigt die Berichte. |

---

## 🛠️ Installation (Kurz)

### 1. Starten
Lade das Programm herunter und starte es:

```bash
git clone https://github.com/derlemue/honey-scan.git
cd honey-scan
docker compose up -d --build
```

### 2. Anschauen
*   **Berichte**: `https://feed.sec.lemue.org/`
*   **Admin**: `https://sec.lemue.org`

---

*Gemacht von der Honey-Scan Community.*
