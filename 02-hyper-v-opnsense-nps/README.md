# Modul 02: Hyper-V, OPNsense, NPS

| Datei | Zweck |
|---|---|
| [02.1-wlan-und-gaestenetz-mit-hyper-v.md](02.1-wlan-und-gaestenetz-mit-hyper-v.md) | Übung mit Hintergrund, Prüfbefehlen, Musterlösung |
| `02.1-hyperv-netz.ps1` | Privaten Switch anlegen, VLANs an den VM-Adaptern setzen (auf dem Hyper-V-Host, `-WhatIf` möglich) |
| `02.1-nps-einrichten.ps1` | NPS-Rolle, selbstsigniertes Zertifikat, Testkonto, RADIUS-Client (auf dem NPS-Server) |
| `02.1-eapol-test.conf` | Konfiguration für `eapol_test` (simuliert Access Point und Client) |
| `02.1-isolationstest.ps1` | Prüft vom Gäste-Client aus, was erreichbar ist (Rückgabewert 0/1) |

PowerShell-Skripte sind UTF-8 mit BOM gespeichert (Windows PowerShell 5.1). Beim Kopieren Kodierung beibehalten.
