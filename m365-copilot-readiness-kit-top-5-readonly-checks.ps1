<#
 M365 Copilot Readiness Kit: Top 5 - read-only checks (Runbook Lab)
 Read-only: Get-* and Search-* cmdlets only. Changes nothing in your tenant.
 Requires: Microsoft.Online.SharePoint.PowerShell (SharePoint settings), ExchangeOnlineManagement (audit).
 Connect first:
   Connect-SPOService -Url https://<tenant>-admin.sharepoint.com
   Connect-ExchangeOnline
 Note: Microsoft retires Search-UnifiedAuditLog on 15 Oct 2027 (MC1505599). CR05 will move to the Graph AuditLogQuery API before then.
 Output: .\hardening-check-results.csv (ID, Control, Status, Output).
#>
$ErrorActionPreference = 'Stop'
$results = @()
function Invoke-Check($Id, $Title, [scriptblock]$Block) {
  try { $o = & $Block | Out-String -Width 400; $s = 'OK' } catch { $o = $_.Exception.Message; $s = 'ERROR' }
  Write-Host "[$Id] $Title -> $s"
  $script:results += [pscustomobject]@{ ID = $Id; Control = $Title; Status = $s; Output = $o.Trim() }
}

Invoke-Check 'CR01' 'Find the overshared sites before Copilot does' { $s = Get-SPOSite -Limit All | Where-Object { $_.SharingCapability -ne 'Disabled' }; "Sites with external sharing on: $($s.Count)"; $s | Group-Object SharingCapability | ForEach-Object { "$($_.Name): $($_.Count)" }; $s | Where-Object { $_.SharingCapability -eq 'ExternalUserAndGuestSharing' } | Select-Object -First 50 | ForEach-Object { "Anyone links allowed: $($_.Url)" } }
Invoke-Check 'CR02' 'Hide the riskiest sites from Copilot while you fix them (Restricted Content Discovery)' { Get-SPOTenant | Select-Object DelegateRestrictedContentDiscoverabilityManagement | Format-List | Out-String; 'Existing Restricted Content Discovery reports:'; Get-SPORestrictedContentDiscoverabilityReport }
Invoke-Check 'CR03' 'Make ''Specific people, view'' the default sharing link and put an expiry on Anyone links' { Get-SPOTenant | Select-Object SharingCapability, OneDriveSharingCapability, DefaultSharingLinkType, DefaultLinkPermission, RequireAnonymousLinksExpireInDays | Format-List }
Invoke-Check 'CR04' 'Remove ''Everyone except external users'' from sensitive sites and hide it in the people picker' { Get-SPOTenant | Select-Object ShowEveryoneExceptExternalUsersClaim, ShowAllUsersClaim, ShowEveryoneClaim | Format-List }
Invoke-Check 'CR05' 'Confirm Copilot interactions are audited and searchable' { Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled | Format-List | Out-String; $r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -RecordType CopilotInteraction -ResultSize 1000; "CopilotInteraction records (last 7 days, max 1000): $(@($r).Count)" }

$results | Export-Csv -NoTypeInformation -Encoding UTF8 .\hardening-check-results.csv
Write-Host "Done: $($results.Count) checks -> hardening-check-results.csv"
