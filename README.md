# M365 Copilot Readiness Kit: Top 5 (free)

Microsoft 365 Copilot answers from everything a user can already open. If a finance folder is shared with "Everyone except external users", Copilot will happily quote it to anyone who asks. These five controls find that oversharing, hide the worst sites while you fix them, and make new sharing narrow by default. They follow the order of Microsoft's own Copilot oversharing blueprint.

| File | What it is |
|---|---|
| `m365-copilot-readiness-kit-top-5-guide.md` | Why, steps, impact, rollback, check, verify, licence, effort and the Microsoft Learn source for each control |
| `m365-copilot-readiness-kit-top-5-jira-import.csv` | Jira Cloud import: epics + stories with parent links, priority, sprint and labels |
| `m365-copilot-readiness-kit-top-5-tracker.csv` | Same backlog for Planner, Azure DevOps, Excel or Linear |
| `m365-copilot-readiness-kit-top-5-project-plan.xlsx` | Excel project plan for teams without Jira: owner, dates, status drop-down, % complete and a progress dashboard by area and sprint |
| `m365-copilot-readiness-kit-top-5-readonly-checks.ps1` | Get-* / Search-* cmdlets only. Changes nothing. Writes `hardening-check-results.csv` |

| # | Control | Licence note |
|---|---|---|
| CR01 | Find the overshared sites before Copilot does | Data access governance reports: SharePoint Advanced Management (included with Copilot licences) |
| CR02 | Hide the riskiest sites from Copilot while you fix them (Restricted Content Discovery) | Copilot licence; SharePoint sites only |
| CR03 | Make "Specific people, view" the default link and put an expiry on Anyone links | Any SharePoint Online plan |
| CR04 | Remove "Everyone except external users" from sensitive sites and hide it in the people picker | Site access reviews: SharePoint Advanced Management |
| CR05 | Confirm Copilot interactions are audited and searchable | Audit (Standard) |

## Import into Jira
Jira Cloud > Settings > System > External system import > CSV. Map `Issue ID` and `Parent` so stories land under their epics.

## Run the checks
```powershell
Install-Module Microsoft.Online.SharePoint.PowerShell, ExchangeOnlineManagement -Scope CurrentUser
Connect-SPOService -Url https://<tenant>-admin.sharepoint.com
Connect-ExchangeOnline
./m365-copilot-readiness-kit-top-5-readonly-checks.ps1
```
Each check runs on its own. If a cmdlet or property behaves differently in your module version, that check writes an ERROR line to the results file and the others still run.

## Scope and limits
- Built from Microsoft Learn pages re-read on 28 October 2026 (links in the guide). Validated before release: every control has why, steps, impact, rollback, verify, licence and a Learn source; the script contains read commands only and parses cleanly in PowerShell 7.4; the Excel plan recalculates with no errors. If a check misreads your setup, open an issue.
- Restricted Content Discovery is an interim measure: it hides content from Copilot and organisation-wide search, it does not change permissions.
- DLP for Copilot prompts is still in preview (Microsoft Learn, 5 Oct 2026), so it is not in the Top 5.
- Search-UnifiedAuditLog retires on 15 October 2027 (MC1505599); CR05 will move to the Graph AuditLogQuery API before then.

## Related (free)
- **M365 Hardening Kit: Emergency Top 10**: the ten tenant-wide controls to do first → https://github.com/runbooklabhq/m365-hardening-kit-free
- **Entra SMS MFA Exit Kit: Top 5**: Microsoft retires its SMS/voice MFA on 1 Feb 2027 → https://github.com/runbooklabhq/entra-sms-mfa-exit-kit-free

## Complete kit
All 24 controls plus an AI acceptable-use policy template, rollout comms and pilot success measures: https://runbooklab.gumroad.com/l/copilot-readiness-kit?utm_source=github&utm_campaign=copilot-free-repo

MIT licence. Not affiliated with or endorsed by Microsoft. Test changes on a pilot site or group first.
