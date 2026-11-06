<#
.SYNOPSIS
    Bereitet einen Windows Server fuer die 802.1X-Anmeldung vor (NPS, Zertifikat, Testkonto, RADIUS-Client).

.DESCRIPTION
    Schritte:
      1. installiert die Rolle Netzwerkrichtlinien- und Zugriffsdienste (NPS),
      2. erstellt ein selbstsigniertes Serverzertifikat (nur fuer die Uebung) im Computerspeicher,
      3. legt ein lokales Testkonto an (Kennwort wird abgefragt, nicht gespeichert),
      4. traegt den "Access Point" (hier: den Linux-Client mit eapol_test) als RADIUS-Client ein.
    Die Netzwerkrichtlinie selbst wird in der NPS-Konsole angelegt (siehe Uebung), dafuer gibt es hier
    keinen Befehl.

.PARAMETER ClientName
    Anzeigename des RADIUS-Clients (Standard AP-Simulator).

.PARAMETER ClientAdresse
    IP-Adresse des RADIUS-Clients (Standard 192.168.10.20).

.PARAMETER Benutzer
    Name des lokalen Testkontos (Standard wlan.test).

.PARAMETER ZertifikatsName
    DNS-Name im Zertifikat (Standard nps.alpenwerk.example).

.EXAMPLE
    .\02.1-nps-einrichten.ps1 -WhatIf

.NOTES
    Zu Uebung 02.1. Nur in der isolierten Testumgebung ausfuehren.
    Das gemeinsame RADIUS-Geheimnis und das Kennwort werden verdeckt abgefragt und nirgends protokolliert.
    Nicht bestaetigt: Verhalten von Install-WindowsFeature und New-NpsRadiusClient auf der verwendeten
    Windows-Server-Version. Getestet wurde nur mit nachgebauten Cmdlets.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ClientName = 'AP-Simulator',
    [string]$ClientAdresse = '192.168.10.20',
    [string]$Benutzer = 'wlan.test',
    [string]$ZertifikatsName = 'nps.alpenwerk.example'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not [System.Net.IPAddress]::TryParse($ClientAdresse, [ref]([System.Net.IPAddress]$null))) {
    throw "Ungueltige Adresse: $ClientAdresse"
}

# 1. Rolle
if ($PSCmdlet.ShouldProcess('NPAS', 'Rolle installieren')) {
    Install-WindowsFeature -Name NPAS -IncludeManagementTools | Out-Null
}

# 2. Zertifikat (Server-Authentifizierung, 1 Jahr)
$zert = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -eq "CN=$ZertifikatsName" -and $_.NotAfter -gt (Get-Date) } | Select-Object -First 1
if (-not $zert) {
    if ($PSCmdlet.ShouldProcess($ZertifikatsName, 'Selbstsigniertes Serverzertifikat erstellen')) {
        $zert = New-SelfSignedCertificate -DnsName $ZertifikatsName -CertStoreLocation Cert:\LocalMachine\My `
            -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(1) `
            -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1')
    }
}
if ($zert) { Write-Host ("Zertifikat: {0}  Fingerabdruck {1}" -f $zert.Subject, $zert.Thumbprint) }

# 3. Testkonto
if (-not (Get-LocalUser -Name $Benutzer -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($Benutzer, 'Lokales Testkonto anlegen')) {
        $pw = Read-Host -Prompt "Kennwort fuer $Benutzer (Uebungskennwort, nicht aus dem echten Leben)" -AsSecureString
        New-LocalUser -Name $Benutzer -Password $pw -PasswordNeverExpires -Description 'Uebung 02.1 WLAN-Test' | Out-Null
    }
} else {
    Write-Host "Konto $Benutzer existiert bereits. Es wird nicht veraendert."
}

# 4. RADIUS-Client
$vorhanden = @(Get-NpsRadiusClient -ErrorAction SilentlyContinue) | Where-Object { $_ -and $_.Name -eq $ClientName }
if (-not $vorhanden) {
    if ($PSCmdlet.ShouldProcess($ClientName, "RADIUS-Client $ClientAdresse eintragen")) {
        $secret = Read-Host -Prompt 'Gemeinsames RADIUS-Geheimnis (auf dem Client gleich eingeben)' -AsSecureString
        $klar = [System.Net.NetworkCredential]::new('', $secret).Password
        if ($klar.Length -lt 12) { throw 'Das Geheimnis soll mindestens 12 Zeichen haben.' }
        New-NpsRadiusClient -Name $ClientName -Address $ClientAdresse -SharedSecret $klar | Out-Null
    }
} else {
    Write-Host "RADIUS-Client $ClientName existiert bereits."
}
Write-Host 'Weiter in der NPS-Konsole: Netzwerkrichtlinie anlegen (siehe Uebung, Teil 2).'
