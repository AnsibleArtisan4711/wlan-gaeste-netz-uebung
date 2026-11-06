<#
.SYNOPSIS
    Prueft vom Gaeste-Client aus, was erreichbar ist und was nicht.

.DESCRIPTION
    Oeffnet fuer jedes Ziel eine TCP-Verbindung mit kurzer Wartezeit und vergleicht das Ergebnis
    mit der Erwartung (Offen oder Gesperrt). Gibt eine Tabelle aus und liefert einen Rueckgabewert:
      0 = alle Ergebnisse wie erwartet
      1 = mindestens eine Abweichung
    Es werden keine Pakete ausser den Verbindungsversuchen gesendet.

.PARAMETER Ziele
    Liste von Zielen. Jedes Ziel ist eine Hashtable mit Name, Adresse, Port, Erwartet ('Offen' oder 'Gesperrt').
    Ohne Angabe gilt die Liste der Uebung (Firewall, Firmennetz, NPS, Internet-Stellvertreter).

.PARAMETER TimeoutMs
    Wartezeit je Verbindungsversuch in Millisekunden (Standard 2000).

.PARAMETER Ausgabe
    Optional: Pfad einer CSV-Datei fuer das Ergebnis.

.EXAMPLE
    .\02.1-isolationstest.ps1

.EXAMPLE
    .\02.1-isolationstest.ps1 -Ziele @(@{Name='Test';Adresse='127.0.0.1';Port=80;Erwartet='Gesperrt'})

.NOTES
    Zu Uebung 02.1 (WLAN und Gaestenetz mit Hyper-V, OPNsense und NPS).
    Laeuft in Windows PowerShell 5.1 und PowerShell 7. Nur im eigenen Testnetz verwenden.
    Ein Verbindungsversuch ohne Antwort (Paket verworfen) und eine Ablehnung zaehlen beide als 'Gesperrt'.
#>
[CmdletBinding()]
param(
    [hashtable[]]$Ziele,
    [int]$TimeoutMs = 2000,
    [string]$Ausgabe
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not $Ziele) {
    $Ziele = @(
        @{ Name = 'Firewall Web-Oberflaeche (Gast-Seite)'; Adresse = '192.168.20.1';  Port = 443; Erwartet = 'Gesperrt' },
        @{ Name = 'Firewall DNS';                          Adresse = '192.168.20.1';  Port = 53;  Erwartet = 'Offen' },
        @{ Name = 'Firewall Firmen-Seite';                 Adresse = '192.168.10.1';  Port = 443; Erwartet = 'Gesperrt' },
        @{ Name = 'NPS-Server (RDP)';                      Adresse = '192.168.10.10'; Port = 3389; Erwartet = 'Gesperrt' },
        @{ Name = 'Firmen-Client (SMB)';                   Adresse = '192.168.10.50'; Port = 445; Erwartet = 'Gesperrt' },
        @{ Name = 'Internet-Stellvertreter (Web)';         Adresse = '203.0.113.80';  Port = 80;  Erwartet = 'Offen' }
    )
}

function Test-TcpPort {
    param([string]$Adresse, [int]$Port, [int]$TimeoutMs)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync($Adresse, $Port)
        if ($task.Wait($TimeoutMs) -and $client.Connected) { return 'Offen' }
        return 'Gesperrt'
    } catch {
        return 'Gesperrt'
    } finally {
        $client.Dispose()
    }
}

$ergebnis = foreach ($z in $Ziele) {
    $ist = Test-TcpPort -Adresse $z.Adresse -Port $z.Port -TimeoutMs $TimeoutMs
    [pscustomobject]@{
        Ziel     = $z.Name
        Adresse  = '{0}:{1}' -f $z.Adresse, $z.Port
        Erwartet = $z.Erwartet
        Ist      = $ist
        Urteil   = if ($ist -eq $z.Erwartet) { 'OK' } else { 'ABWEICHUNG' }
    }
}
$ergebnis = @($ergebnis)
($ergebnis | Format-Table -AutoSize | Out-String -Width 200) | Write-Host

if ($Ausgabe) {
    $ergebnis | Export-Csv -LiteralPath $Ausgabe -NoTypeInformation -Encoding UTF8
    Write-Host "CSV geschrieben: $Ausgabe"
}

$fehler = @($ergebnis | Where-Object { $_.Urteil -ne 'OK' }).Count
if ($fehler -gt 0) {
    Write-Host "$fehler Abweichung(en) von der Erwartung." -ForegroundColor Yellow
    exit 1
}
Write-Host 'Alle Ergebnisse wie erwartet.' -ForegroundColor Green
exit 0
