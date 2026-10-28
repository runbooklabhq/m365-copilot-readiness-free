# M365 Copilot Readiness Kit: Top 5

_Version 1.0 (2026-10-28; facts re-read on Microsoft Learn 2026-10-28; validated: quality gate, read-only guard, PowerShell 7.4 parse, Excel recalc)_

Five controls to stop Microsoft 365 Copilot from surfacing files people should never have seen. Copilot only shows what a user can already open, so the work is fixing oversharing before rollout, then setting safer defaults. Free. Each control has why, steps, impact, rollback, a read-only PowerShell check, how to verify, licence, effort and the Microsoft Learn page it is based on. It follows the order of Microsoft's own Copilot oversharing blueprint (remediate oversharing, set up guardrails, meet regulations).

Read-only checks: run `m365-copilot-readiness-kit-top-5-readonly-checks.ps1` (read-only, changes nothing).

| # | Control | Area | Sprint | Priority | Effort |
|---|---|---|---|---|---|
| CR01 | Find the overshared sites before Copilot does | Find and fix oversharing | Sprint 1 - Before Copilot pilot | Highest | 2 h |
| CR02 | Hide the riskiest sites from Copilot while you fix them (Restricted Content Discovery) | Find and fix oversharing | Sprint 1 - Before Copilot pilot | Highest | 1 h |
| CR03 | Make 'Specific people, view' the default sharing link and put an expiry on Anyone links | Safer sharing defaults | Sprint 1 - Before Copilot pilot | High | 1 h |
| CR04 | Remove 'Everyone except external users' from sensitive sites and hide it in the people picker | Safer sharing defaults | Sprint 2 - Remediate and guard | High | 2 h + site owner time |
| CR05 | Confirm Copilot interactions are audited and searchable | Copilot audit and evidence | Sprint 1 - Before Copilot pilot | High | 30 min |

## CR01. Find the overshared sites before Copilot does

**Why:** Copilot answers from everything a user can open. Sites shared with 'Everyone except external users', broken inheritance and old company-wide links are the usual source of 'how did Copilot find the salary sheet'. Microsoft's blueprint starts here: identify high-risk sites and content first.

**Steps:**
1. SharePoint admin center > Reports > Data access governance: run the permission state report for SharePoint sites and the 'Everyone except external users' (EEEU) insights. Export both.
2. If you have Microsoft Purview DSPM: run the data risk assessment for oversharing (overshared sites with sensitive data, risky sharing links, frequently accessed content).
3. Sort by sensitivity (HR, finance, legal, board, M&A first) and by audience size. Put the top 20 sites in the tracker with a named owner each.
4. Run the read-only check below to list sites that allow sharing with anyone or with guests, and add the sensitive ones to the same list.

**Impact:** None. Reports and the check only read data. Report generation can take hours on large tenants.

**Rollback:** Nothing to roll back.

**Check (read-only PowerShell):**

```powershell
$s = Get-SPOSite -Limit All | Where-Object { $_.SharingCapability -ne 'Disabled' }; "Sites with external sharing on: $($s.Count)"; $s | Group-Object SharingCapability | ForEach-Object { "$($_.Name): $($_.Count)" }; $s | Where-Object { $_.SharingCapability -eq 'ExternalUserAndGuestSharing' } | Select-Object -First 50 | ForEach-Object { "Anyone links allowed: $($_.Url)" }
```

**Verify:** A list of high-risk sites with an owner for each exists in the tracker, and the DAG/EEEU reports are saved with the date they were run.

**Licence:** Data access governance reports and EEEU insights are part of SharePoint Advanced Management, which Microsoft includes with Microsoft 365 Copilot licences. DSPM data risk assessments need Microsoft Purview (check your plan). SharePoint Administrator role. · **Effort:** 2 h · **Priority:** Highest · **Sprint 1 - Before Copilot pilot**

**Microsoft Learn:** https://learn.microsoft.com/en-us/copilot/microsoft-365/microsoft-365-copilot-blueprint-oversharing · https://learn.microsoft.com/en-us/microsoft-365/copilot/configure-secure-governed-data-foundation-microsoft-365-copilot · https://learn.microsoft.com/en-us/sharepoint/advanced-management

## CR02. Hide the riskiest sites from Copilot while you fix them (Restricted Content Discovery)

**Why:** Fixing permissions on a big site takes weeks. Restricted Content Discovery keeps a site's content out of organisation-wide search and Copilot answers in the meantime. Microsoft calls it an interim protection: remove it once access is fixed.

**Steps:**
1. SharePoint admin center > Sites > Active sites > select the site > Settings > turn on 'Restrict content from Microsoft Copilot' > Save. Or: Set-SPOSite -Identity <site-url> -RestrictContentOrgWideSearch $true (this changes the site; run it yourself, it is not part of the read-only script).
2. Apply it only to the high-risk sites from CR01. Microsoft advises using it selectively: every restricted site makes Copilot answers less complete.
3. Allow time. Sites with more than 500,000 items can take over a week to reflect the change.
4. Test with a pilot user who has access: ask Copilot about the site's content and check the answer no longer cites it.
5. Record a removal date per site in the tracker (when CR01's owner has fixed access).

**Impact:** Copilot and organisation-wide search stop surfacing the site's content. Permissions do not change: users with access can still open files directly, and searches from inside the site still work. AI entry points such as the Copilot button and agent creation are removed on that site.

**Rollback:** Turn the setting off on the site (or Set-SPOSite -Identity <site-url> -RestrictContentOrgWideSearch $false). Allow the same propagation time.

**Check (read-only PowerShell):**

```powershell
Get-SPOTenant | Select-Object DelegateRestrictedContentDiscoverabilityManagement | Format-List | Out-String; 'Existing Restricted Content Discovery reports:'; Get-SPORestrictedContentDiscoverabilityReport
```

**Verify:** Every high-risk site from CR01 either has access fixed or has 'Restrict content from Microsoft Copilot' on, with a removal date in the tracker. A pilot user's Copilot answer no longer cites the restricted site.

**Licence:** Microsoft 365 Copilot licence (SharePoint Advanced Management included). SharePoint sites only, not OneDrive. SharePoint Administrator role. · **Effort:** 1 h · **Priority:** Highest · **Sprint 1 - Before Copilot pilot**

**Microsoft Learn:** https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery · https://learn.microsoft.com/en-us/microsoft-365/copilot/configure-secure-governed-data-foundation-microsoft-365-copilot

## CR03. Make 'Specific people, view' the default sharing link and put an expiry on Anyone links

**Why:** Every 'People in your organisation' link created today is something Copilot can surface to the whole company tomorrow. Microsoft's guardrail step is to restrict company-wide and Anyone links at tenant level so new sharing is narrow by default.

**Steps:**
1. SharePoint admin center > Policies > Sharing: set 'File and folder links' default to 'Specific people (only the people the user specifies)' and the default permission to View.
2. Same page: if Anyone links stay allowed, set them to expire (for example 30 days) and limit them to View. If nobody needs them, lower the external sharing level for SharePoint and OneDrive to 'New and existing guests'.
3. For sites that must keep a different default, set it per site: Active sites > site > Sharing > Default sharing link type.
4. Tell users in one short message: links now default to specific people; ask IT if you need a wider link.

**Impact:** Changes only new links. Existing links keep working until they expire or are removed (CR01 finds them). Some users will need one extra click to share wider.

**Rollback:** Set the defaults back on the same Sharing page. Changing the default affects new links only.

**Check (read-only PowerShell):**

```powershell
Get-SPOTenant | Select-Object SharingCapability, OneDriveSharingCapability, DefaultSharingLinkType, DefaultLinkPermission, RequireAnonymousLinksExpireInDays | Format-List
```

**Verify:** Check output shows DefaultSharingLinkType = Direct, DefaultLinkPermission = View, and either Anyone links not allowed or RequireAnonymousLinksExpireInDays set to a value greater than 0.

**Licence:** Any SharePoint Online plan. SharePoint Administrator role. · **Effort:** 1 h · **Priority:** High · **Sprint 1 - Before Copilot pilot**

**Microsoft Learn:** https://learn.microsoft.com/en-us/sharepoint/change-default-sharing-link · https://learn.microsoft.com/en-us/microsoft-365/copilot/configure-secure-governed-data-foundation-microsoft-365-copilot

## CR04. Remove 'Everyone except external users' from sensitive sites and hide it in the people picker

**Why:** 'Everyone except external users' (EEEU) gives every employee access in one click. On a sensitive site it means Copilot can use that content for anyone who asks. Microsoft's remediation step is to remove company-wide groups and links from overshared sites, starting with site access reviews.

**Steps:**
1. From the EEEU insights (CR01), start a site access review for each sensitive site so the site owner removes EEEU and company-wide links (SharePoint admin center > Reports > Data access governance > select the report > Initiate site access review).
2. Where owners do not respond within the deadline, remove EEEU from the site permissions yourself and record it in the tracker.
3. Hide the EEEU claim in the people picker so new grants are harder: Set-SPOTenant -ShowEveryoneExceptExternalUsersClaim $false (a tenant change; run it yourself after telling the helpdesk).
4. Re-run the EEEU insights report after 28 days and compare.

**Impact:** People who relied on EEEU lose access to that site and may raise tickets. Hiding the claim does not remove existing EEEU grants; it only stops new ones from the people picker.

**Rollback:** Re-add the group to the site if a business need is confirmed (prefer a named group). Show the claim again with -ShowEveryoneExceptExternalUsersClaim $true.

**Check (read-only PowerShell):**

```powershell
Get-SPOTenant | Select-Object ShowEveryoneExceptExternalUsersClaim, ShowAllUsersClaim, ShowEveryoneClaim | Format-List
```

**Verify:** Sensitive sites from CR01 no longer grant EEEU; the next EEEU insights report shows fewer items; ShowEveryoneExceptExternalUsersClaim is False.

**Licence:** Site access reviews and EEEU insights: SharePoint Advanced Management (included with Microsoft 365 Copilot licences). People picker setting: any SharePoint Online plan. · **Effort:** 2 h + site owner time · **Priority:** High · **Sprint 2 - Remediate and guard**

**Microsoft Learn:** https://learn.microsoft.com/en-us/sharepoint/advanced-management · https://learn.microsoft.com/en-us/microsoft-365/copilot/configure-secure-governed-data-foundation-microsoft-365-copilot

## CR05. Confirm Copilot interactions are audited and searchable

**Why:** When someone asks 'who saw this through Copilot?', the audit log is your only evidence. Copilot interactions are logged as part of Audit (Standard) under the CopilotInteraction record type, but only if auditing is on in your tenant. Check it before the pilot, not after the first incident.

**Steps:**
1. Run the read-only check: it confirms unified audit log ingestion is on and counts CopilotInteraction records in the last 7 days.
2. If ingestion is off, turn it on in Microsoft Purview > Audit (a tenant change; allow up to 60 minutes).
3. Microsoft Purview > Audit > search Activities - operation names: CopilotInteraction for one pilot user and save the search as your evidence procedure.
4. Decide how long to keep Copilot audit records and Copilot interactions (audit log retention policy and Data Lifecycle Management retention for Copilot). Write the decision in the tracker.

**Impact:** Checking changes nothing. Turning on auditing has no user impact.

**Rollback:** Not needed for the check. Do not turn auditing off.

**Check (read-only PowerShell):**

```powershell
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled | Format-List | Out-String; $r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -RecordType CopilotInteraction -ResultSize 1000; "CopilotInteraction records (last 7 days, max 1000): $(@($r).Count)"
```

**Verify:** UnifiedAuditLogIngestionEnabled is True and a CopilotInteraction search for a pilot user returns results; the retention decision is recorded.

**Licence:** Audit (Standard), included in Microsoft 365 business and enterprise plans. Longer audit retention needs Audit (Premium) or a retention add-on. Audit Logs or View-Only Audit Logs role. · **Effort:** 30 min · **Priority:** High · **Sprint 1 - Before Copilot pilot**

**Microsoft Learn:** https://learn.microsoft.com/en-us/purview/audit-copilot · https://learn.microsoft.com/en-us/microsoft-365/copilot/configure-secure-governed-data-foundation-microsoft-365-copilot

---
Not affiliated with or endorsed by Microsoft. Test every change in Report-only or on a pilot group first. Licence names and portal paths change; check Microsoft Learn if a menu has moved.
