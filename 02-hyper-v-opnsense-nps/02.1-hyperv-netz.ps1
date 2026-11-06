<#
.SYNOPSIS
    Legt den privaten Hyper-V-Switch fuer die Uebung an und setzt die VLANs an den VM-Adaptern.

.DESCRIPTION
    Modus Einrichten:
      - erstellt einen privaten Switch (kein Zugang zum Host oder zum Heimnetz),
      - setzt den LAN-Adapter der Firewall-VM als Trunk (VLAN 10 und 20),
      - setzt die Adapter der Client-VMs als Access-Port im jeweiligen VLAN.
    Modus Entfernen: setzt die VLAN-Einstellungen zurueck und loescht den Switch (nur wenn er leer ist).
    Muss in einer administrativen PowerShell auf dem Hyper-V-Host laufen.

.PARAMETER Modus
    Einrichten oder Entfernen.

.PARAMETER SwitchName
    Name des privaten Switches (Standard sw-wlan-lab).

.PARAMETER Firewall
    Name der OPNsense-VM (Standard WL-FW).

.PARAMETER FirmenVMs
    Namen der VMs im Firmen-VLAN 10 (Standard WL-NPS, WL-AP, WL-CL-FIRMA).

.PARAMETER GastVMs
    Namen der VMs im Gaeste-VLAN 20 (Standard WL-CL-GAST).

.EXAMPLE
    .\02.1-hyperv-netz.ps1 -Modus Einrichten -WhatIf

.NOTES
    Zu Uebung 02.1. Auf dem Host werden keine Adressen geaendert.
    Die Cmdlets stammen aus dem Hyper-V-Modul (New-VMSwitch, Set-VMNetworkAdapterVlan). Das Skript wurde
    nur auf Syntax und mit nachgebauten Cmdlets geprueft, nicht auf einem echten Hyper-V-Host.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Einrichten', 'Entfernen')][string]$Modus,
    [string]$SwitchName = 'sw-wlan-lab',
    [string]$Firewall = 'WL-FW',
    [string[]]$FirmenVMs = @('WL-NPS', 'WL-AP', 'WL-CL-FIRMA'),
    [string[]]$GastVMs = @('WL-CL-GAST')
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-Adapter {
    param([string]$VmName)
    $a = @(Get-VMNetworkAdapter -VMName $VmName | Where-Object { $_.SwitchName -eq $SwitchName -or -not $_.SwitchName })
    if ($a.Count -eq 0) { throw "VM '$VmName' hat keinen Netzwerkadapter, der fuer '$SwitchName' infrage kommt." }
    return $a
}

if ($Modus -eq 'Einrichten') {
    if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($SwitchName, 'Privaten Switch anlegen')) {
            New-VMSwitch -Name $SwitchName -SwitchType Private | Out-Null
        }
    }
    # Firewall: der Adapter am Lab-Switch wird Trunk. Ein zweiter Adapter (WAN) bleibt unberuehrt.
    foreach ($vm in @($Firewall)) {
        $fwAdapter = @(Get-VMNetworkAdapter -VMName $vm | Where-Object { $_.SwitchName -eq $SwitchName })
        if ($fwAdapter.Count -eq 0) {
            if ($PSCmdlet.ShouldProcess($vm, "Adapter mit Switch '$SwitchName' verbinden (erster freier Adapter)")) {
                $first = @(Get-VMNetworkAdapter -VMName $vm | Where-Object { -not $_.SwitchName })[0]
                if (-not $first) { throw "VM '$vm' hat keinen freien Adapter. Bitte einen zweiten Adapter hinzufuegen." }
                Connect-VMNetworkAdapter -VMNetworkAdapter $first -SwitchName $SwitchName
                $fwAdapter = @($first)
            }
        }
        foreach ($a in $fwAdapter) {
            if ($PSCmdlet.ShouldProcess("$vm / $($a.Name)", 'Trunk fuer VLAN 10 und 20')) {
                Set-VMNetworkAdapterVlan -VMNetworkAdapter $a -Trunk -AllowedVlanIdList '10,20' -NativeVlanId 0
            }
        }
    }
    foreach ($pair in @(@{ VMs = $FirmenVMs; Id = 10 }, @{ VMs = $GastVMs; Id = 20 })) {
        foreach ($vm in $pair.VMs) {
            foreach ($a in (Get-Adapter -VmName $vm)) {
                if ($PSCmdlet.ShouldProcess("$vm / $($a.Name)", "Access-VLAN $($pair.Id)")) {
                    if (-not $a.SwitchName) { Connect-VMNetworkAdapter -VMNetworkAdapter $a -SwitchName $SwitchName }
                    Set-VMNetworkAdapterVlan -VMNetworkAdapter $a -Access -VlanId $pair.Id
                }
            }
        }
    }
    Write-Host 'Fertig. Kontrolle:  Get-VMNetworkAdapterVlan -VMName <name>'
}
else {
    $sw = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if (-not $sw) { Write-Host "Switch '$SwitchName' existiert nicht. Nichts zu tun."; return }
    $belegt = @(Get-VMNetworkAdapter -VMName * | Where-Object { $_.SwitchName -eq $SwitchName })
    foreach ($a in $belegt) {
        if ($PSCmdlet.ShouldProcess("$($a.VMName) / $($a.Name)", 'VLAN zuruecksetzen und vom Switch trennen')) {
            Set-VMNetworkAdapterVlan -VMNetworkAdapter $a -Untagged
            Disconnect-VMNetworkAdapter -VMNetworkAdapter $a
        }
    }
    if ($PSCmdlet.ShouldProcess($SwitchName, 'Switch loeschen')) {
        Remove-VMSwitch -Name $SwitchName -Force
    }
}
