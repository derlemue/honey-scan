# REGELKATALOG: ANTIGRAVITY AUTONOMY MODE (DEBIAN)

## 1. INTERAKTIONS-PRINZIP (NO-CONFIRM POLICY)
- Handle nach dem "SSH-Modus": Sobald der initiale Prompt freigegeben wurde, agiere vollautonom.
- Bestätigungen für Einzelschritte (Klicken, Scrollen, Tippen, Navigieren) sind DEAKTIVIERT.
- Führe den gesamten Plan eigenständig bis zum Ergebnis oder zu einem kritischen Fehler aus.
- Nur bei destruktiven Systembefehlen außerhalb des Projektordners ist eine Rückfrage erforderlich.

## 2. BROWSER-STEUERUNG
- Navigation: Gehe direkt zu Ziel-URLs, anstatt dich mühsam durch Menüs zu klicken, wenn die URL bekannt oder herleitbar ist.
- Wartezeiten: Warte eigenständig auf das Laden von Elementen (DOM ready), bevor du einen Fehler meldest.
- Selektoren: Wenn ein Element nicht klickbar ist, versuche selbstständig alternative Selektoren oder JavaScript-Clicks, bevor du den Prozess stoppst.

## 3. TERMINAL & SYSTEM (DEBIAN)
- Paketverwaltung: Nutze `apt` immer mit dem `-y` Flag für automatische Bestätigung.
- Pfade: Verwende absolute Pfade, um Verwirrung bei Verzeichniswechseln zu vermeiden.
- SSH-Style: Präsentiere Terminal-Outputs direkt und verarbeite Fehlermeldungen (stderr) ohne Rückfrage an den User.

## 4. KOMMUNIKATION & SPRACHE
- Sprache: Die Kommunikation erfolgt ausschließlich auf DEUTSCH.
- Status: Gib zu Beginn eine kurze Liste der geplanten Schritte aus. Während der Arbeit bleibst du im Hintergrund aktiv ("Silent Execution").
- Abschluss: Präsentiere am Ende eine prägnante Zusammenfassung der erledigten Aufgaben.

## 5. FEHLERBEHANDLUNG
- "Self-Healing": Versuche bei Web-Fehlern (z.B. 404, Timeout) mindestens zwei alternative Wege (andere Suche, andere Seite), bevor du den Benutzer informierst.
- Timeouts: Wenn eine Seite nicht lädt, versuche einen Refresh, bevor du abbrichst.
