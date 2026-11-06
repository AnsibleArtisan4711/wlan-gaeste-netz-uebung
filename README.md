# WLAN- und Gästenetz-Übung

Praxisübungen zu einem Firmen-WLAN mit Anmeldung (802.1X) und einem getrennten Gäste-WLAN. Zwei Wege zum selben Ziel: **Cisco Packet Tracer** (mit Wireless LAN Controller) und eine **Hyper-V-Umgebung ohne Funk** (OPNsense, Windows NPS, `eapol_test`). Alle Namen, Firmen und Domänen sind frei erfunden (`alpenwerk.example`).

## Inhalt

| Modul | Übung | Stufe |
|---|---|---|
| [01-packet-tracer](01-packet-tracer/) | 01.1 WLAN für Firma und Gäste in Packet Tracer (VLANs, WLC, WPA2-Enterprise und WPA2-PSK, ACL) | Aufbau |
| [02-hyper-v-opnsense-nps](02-hyper-v-opnsense-nps/) | 02.1 WLAN und Gästenetz mit Hyper-V, OPNsense und NPS (Netztrennung, 802.1X, Isolationstest) | Aufbau bis Vertiefung |

## Stand

**Entwurf.** Packet Tracer, OPNsense, NPS, Hyper-V und `eapol_test` wurden **nicht** ausgeführt. Die PowerShell-Skripte wurden mit nachgebauten Cmdlets geprüft, `02.1-isolationstest.ps1` zusätzlich gegen echte lokale TCP-Ports. Was nicht gegen eine Quelle geprüft ist, steht in den Übungen als „nicht bestätigt“. Abweichungen bitte als Issue melden.

## Sicherheit

- Nur in einer isolierten Testumgebung ausführen (private Hyper-V-Switches, Simulator), nie in einem Firmen- oder Heimnetz.
- Alle Kennwörter und Geheimnisse in den Texten sind Übungswerte. Die Skripte fragen Kennwörter verdeckt ab und speichern sie nicht.
- Der Isolationstest sendet nur einzelne TCP-Verbindungsversuche an die aufgelisteten Ziele.

## Lizenz

Skripte: MIT ([LICENSE](LICENSE)). Texte und Anleitungen: CC BY-NC-SA 4.0 ([LICENSE-DOCS.md](LICENSE-DOCS.md)). Cisco, Cisco IOS und Packet Tracer sind Marken von Cisco Systems, Inc. OPNsense, Microsoft, Windows, Hyper-V und Debian sind Marken ihrer Inhaber. Dieses Projekt steht in keiner Verbindung zu diesen Unternehmen.
