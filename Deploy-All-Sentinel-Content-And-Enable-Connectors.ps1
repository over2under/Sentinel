#Requires -Version 7.2
<#
.DESCRIPTION
Select a subscription, resource group and Sentinel workspace interactively.
Enter B or Back at the resource-group or workspace menu to return to the previous
selection. Going back clears dependent selections, including parameter overrides.
Deploy missing/newer Content Hub content, then reconcile ALL installed connectors,
including connectors left incomplete by an earlier run. Existing source selections
and customized analytics rules are preserved. Package version is not proof of
deployed rules/workbooks: their individual deployment checks still run.
Successful workspace contentPackages discovery drives installation: absent packages
install; older versions upgrade with the official incremental ARM package, including
inline nested deployments and all packaged content. Current versions skip package
installation; supported owned-artifact checks can repair demonstrably missing content.
Local ARM expression inspection is supplementary, never a prerequisite for first
installation or upgrading. ARM validates parameter/reference expressions, and the
script verifies terminal deployment success plus the installed package ID/version.
Fresh installs and upgrades share schema-validated manifest preparation, including
JSON-string and ARM 2.0 symbolic-resource packages. Only declared workspace/region
parameters are supplied; other declared defaults remain with ARM. Missing manifests
never become registration-only installs. An explicit empty resource collection can
register a content-free package. Current/newer versions are not reinstalled or
downgraded; verified missing owned artifacts use selective repair.
Unknown installed versions require review (no speculative downgrade). An unavailable
package body cannot be replaced with a registration-only write. Detailed artifact
checks may be partial; this is reported separately from verified installation.
Artifact verification accepts documented one-to-four-part versions and uses exact
resource/parent/content identity. Missing optional provenance or list-projected
template bodies are not treated as absent resources; scoped detail GETs resolve
projections. Genuine absence, conflicting identity and failed reads remain explicit.
SharedPresent is limited to five reviewed SOC/TI shared dependencies: exact declared
content/kind/version, reviewed owner and nested provenance, plus equivalent payload
or exact pinned published variants. Foreign/changed/unknown artifacts authorize no
repair. Shared templates do not prove saved workbooks or configured ingestion.
Package rows in the JSON report retain expected/observed artifact identities,
versions and API read outcomes, not template/query bodies or credentials.
The canonical tenant, subscription, workspace ARM ID and workspace CustomerId are
displayed/verified; package reads cannot silently target another workspace.
Analytics rules reuse verified template-linked IDs. Workbooks use saved-resource
inventory plus workspace ownership and Sentinel metadata, not template presence alone.
Exact-name collisions, ambiguous matches and saved workbooks missing metadata are
preserved with ActionRequired warnings, never overwritten or duplicated. New resources
use deterministic workspace/content IDs; repeated templates are processed once.
Workbook inventory reads both Sentinel and general workbook categories throughout
the selected subscription (read permission required), but only selected-workspace
artifacts participate in matching. Existing saved-resource IDs/locations are retained.
Pre-existing duplicates are not deleted. Inert Content Hub templates can still appear
alongside deployed resources in the portal; they are not duplicate runtime resources.
NRT (near-real-time) analytics rules are skipped: no creation, update, deletion
or metadata changes to existing NRT rules. Scheduled rules still deploy normally.
Content Hub may retain inert NRT templates; those are not active analytics rules.
Rule-only HTTP 400 validation failures are reported separately and do not prevent
supported connector configuration after package verification. They remain failures
in the final run result and appear as Content rows in the JSON report.
Supported automatic setup: Microsoft 365, ID Protection (unless XDR is present),
XDR incidents/alerts, selected-source Azure Activity/Entra/Storage/NSG/Purview
diagnostics, opt-in Microsoft Copilot DCR/DCE/runtime configuration, and explicitly
scoped Windows SecurityEvent DCR/AMA/machine associations. Every inventory row
includes required/optional stages, installed permission/data-type/instruction
evidence and remaining inputs; control-plane configuration is not end-to-end readiness.
API connectors mean supported Sentinel dataConnectors APIs, not Logic App connections.
Unknown CCF/vendor/Agent/PurviewAudit definitions require their exact source contract,
credentials/consent and connector-page setup; metadata instructions are never executed.
No playbook discovery/deployment/execution, Logic Apps, API connections or playbook
permission grants. Packages containing executable rules/workbooks outside the
identity-checked deployer, or executable workflows/connections, fail closed.
Policies are manual by default. ConfigureConnectorPolicies opts into seven pinned,
reviewed built-ins in the selected Sentinel subscription by default. Override with
ConnectorPolicyScopeIds for explicit subscription/resource-group scopes.
Existing source resources are excluded on creation; existing assignments are never
overwritten. Unknown schemas, conflicts and newly conflicting diagnostics require
manual review. GrantConnectorPolicyRoles and RemediateConnectorPolicies separately
authorize privileged identity grants and asynchronous remediation. No rollback is
promised; assignment acceptance never means source configuration or ingestion.
Defaults: source subscription is the workspace subscription; Entra requests All.
Diagnostic setup first verifies enabled log coverage to this exact Sentinel
workspace. A covering existing setting, or complementary settings together, is
AlreadyConfigured and its names are reported, even if all five slots are occupied.
Only missing categories are added in a new setting when fewer than five exist.
At five settings, missing coverage is ActionRequired: no existing setting is
deleted, overwritten, redirected or adopted. Existing metrics, routing, retention
and additional destinations remain untouched. Coverage/count/name are rechecked
before creation; Azure still enforces the limit if another writer races this run.
If Entra category discovery is unavailable, the six reference log categories are
configured and additional-category coverage is explicitly reported as unverified.
Existing Storage/NSG/Purview sources are discovered in selected source
subscriptions. Ingestion may incur charges. Scope with SourceSubscriptionIds and
DiagnosticResourceIds before applying. Use WhatIf to preview connector writes.
Requires Azure resource read/write privileges for the selected resources, Sentinel
Contributor, and source-specific licensing, tenant permissions and consent. No
source permissions, agents, audit licensing or consent are granted automatically.
Missing Az.Accounts, Az.Resources and Az.OperationalInsights modules are installed
from the official PSGallery into CurrentUser, including in Cloud Shell.
Preview deployment additionally installs Microsoft.Graph.Authentication as needed.
Healthy installed modules are reused. PSGallery registration and the NuGet provider
are bootstrapped only when installation is needed; repository trust is not changed.
PowerShell 7.2+ and Git are host requirements (both supplied by PowerShell Cloud Shell);
this script does not replace its own runtime or install operating-system packages.
WhatIf never installs/updates dependencies and stops explicitly if one is missing.
After deployment/configuration, including on failure, read and report ALL installed
connector records. Inventory observations do not prove event ingestion; Action
rows separately record this run's configuration successes, failures and setup needs.
Every run creates a unique text transcript, including preview/status-only runs.
It captures displayed output, deployment warnings and fatal errors; it is separate
from the structured connector JSON report. Treat logs as sensitive operational data.
Review/redact before sharing; transcripts are not a credential-redaction boundary.
.PARAMETER ConnectorStatusOnly
Skip repository preparation, Content Hub deployment and connector configuration.
Read installed connector/native/diagnostic status and optionally save the JSON report.
No Azure resources are written by this mode. Unknown means status is not verifiable
by an implemented adapter, not that the connector is disconnected.
.PARAMETER InstallPrerequisitesOnly
Install/import all four required PowerShell modules, including Graph authentication,
and check the built-in Git prerequisite, then stop before Azure/Graph sign-in,
target selection, cloning or any cloud writes. Use this for dependency-only setup.
Licenses, Defender onboarding, Azure/Defender roles and admin consent are not
software dependencies and are never granted or purchased by this mode.
.PARAMETER ContentStatusOnly
Read package registrations and supported packaged-artifact evidence without cloning
the repository, installing content or configuring connectors. Target selection and
final read-only connector inventory still run. Use with ConnectorReportPath to
diagnose exact missing/outdated/conflicting artifacts before another deployment.
Mutually exclusive with ConnectorStatusOnly and ConfigureConnectorsOnly.
.PARAMETER ConfigureConnectorsOnly
Configure supported already-installed connectors without running Content Hub or
analytics-rule deployment. Existing source selections and opt-in controls still
apply. Mutually exclusive with the two read-only modes. Does not repair failed rules.
.PARAMETER ConnectorReportPath
Optional local JSON report file with full actions, errors, requirements and Package
rows containing exact safe artifact diagnostics (including after deployment failure).
Content rows retain package/API failures even when the upstream deployer exits early;
local resource-preflight failures include the offending structural path, not credentials.
The terminal shows a compact connector summary; use -Verbose for technical detail.
.PARAMETER LogPath
Optional text log filename. Default: a unique timestamped file under
$HOME/clouddrive/Sentinel-Logs when Cloud Shell persistent storage is mounted,
otherwise ./Sentinel-Logs in the current directory. The resolved path is displayed
at startup. Missing parent directories are created; existing files are never
overwritten or appended. Logging starts before prerequisites/target selection and
stops on success or failure. Use -Verbose to include additional technical output.
Logs are also written with -WhatIf; that previews Azure writes, not local logging.
Parameter-binding, syntax and #Requires failures occur before logging can start.
An unwritable log path stops the run before Azure changes.
.PARAMETER DeployPreviewDetections
Opt into separately deploying scheduled MicrosoftSecurity preview custom detections
from the selected official packages through Microsoft Graph beta. Standard package
installation explicitly uses E5Flavor=false; inactive preview nested deployments
are not submitted. New Graph rules remain disabled. Existing unowned, enabled or
externally changed rules are preserved. Installs/imports Microsoft.Graph.Authentication
when needed; requires delegated CustomDetection.ReadWrite.All, appropriate
active Defender/Sentinel roles, Defender onboarding and licensing. No roles/consent
are granted automatically; Graph sign-in requires explicit interactive approval.
WhatIf reads package definitions but never signs in to Graph or writes rules/state.
.PARAMETER UpdateOwnedPreviewDetections
With DeployPreviewDetections, permit individually approved updates of unchanged,
journal-owned disabled rules. This never adopts an existing rule or enables one.
Graph PATCH has no assumed conditional-write guarantee: keep other rule writers
quiescent. No automatic rollback/deletion; ambiguous writes require manual review.
.PARAMETER PreviewDetectionStatePath
Optional JSON ownership journal for preview detections. Keep the same file across
runs. It records stable rule IDs and configuration hashes, not queries or credentials.
Pending/failed writes are not silently retried or adopted. Use persistent Cloud Shell
storage and retain the journal; do not share it between concurrent deployments.
.PARAMETER EntraLogCategories
Defaults to All. Tries tenant category discovery, but HTTP 400/404/405 or an empty
category list no longer blocks setup: uses AuditLogs, SignInLogs,
NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs,
ManagedIdentitySignInLogs and ProvisioningLogs from the working reference command.
This fallback does NOT claim all tenant categories are enabled; the report requests
review of additional categories. Explicit category names bypass discovery entirely.
Uses tenant diagnosticSettings GET/PUT with api-version=2017-04-01 and the selected
workspace ARM resource ID, not its CustomerId. Settings/destinations are preserved.
Individual categories may require additional licenses/roles and increase costs.
.PARAMETER ConfigureCopilot
Explicitly allow the reviewed MicrosoftCopilot/CopilotGeneral PurviewAudit adapter.
Creates missing DCR/DCE only in the workspace resource group/region, with public
ingestion enabled and a single Microsoft-CopilotActivity stream. Existing network
restrictions/routing are never weakened. Partial failures leave resources for
inspection/rerun; no automatic rollback. Requires Monitor DCR/DCE write permission
and Copilot/unified-audit licensing and source consent.
.PARAMETER ConfigureConnectorPolicies
Opt into reviewed Activity/NSG/Storage DeployIfNotExists assignments, pinned to a
validated live definition version and schema hash. Existing resources are excluded
at initial assignment; direct adapters configure them. Only new resources receive
policy diagnostics. Storage policy service logs use AzureDiagnostics, not Dedicated;
existing Dedicated settings are excluded, never converted. Activity policy is
dormant if the subscription already has diagnostics. No existing assignment changes.
.PARAMETER ConnectorPolicyScopeIds
Optional subscription or resource-group ARM scopes, within SourceSubscriptionIds.
With ConfigureConnectorPolicies, omission uses /subscriptions/<selected Sentinel
subscription ID>, resolved after interactive target selection. Explicit scopes
are preserved, including an empty array (no policy writes). DiagnosticResourceIds
does not narrow policy scope. Activity requires a subscription scope.
No management-group/tenant grants.
.PARAMETER GrantConnectorPolicyRoles
Separately authorize the two roles declared by the reviewed definition for its
system-assigned identity: Monitoring Contributor at the explicit source scope and
Log Analytics Contributor only at the destination workspace. Requires
roleAssignments/write. Every missing
grant uses ShouldProcess; group membership is not inferred. No role removal.
.PARAMETER RemediateConnectorPolicies
Separately submit one deterministic remediation per assignment after verified roles,
safe exclusions and no conflicting assignments. Reruns observe the same task, never
silently resubmit failed/completed tasks. Use an explicit new ConnectorRemediationRunId
for another approved cycle. Monitor Policy Insights; asynchronous work can outlive
this script, fail or remain pending. No completion/ingestion claims on submission.
.PARAMETER IncludeStorageMetricsPolicy
Explicitly include the storage-account AllMetrics policy (additional ingestion/cost).
Service-log policies do not enable metrics.
.PARAMETER WindowsSecurityEventMachineIds
Explicit Windows Azure VM ARM IDs in SourceSubscriptionIds. Enables the installed
WindowsSecurityEvents adapter to validate/create a SecurityEvent DCR and associate
these VMs. No VM discovery, machine identity changes, Arc onboarding, host audit
policy changes, firewall changes or guest scripts. Ingestion charges may apply.
.PARAMETER WindowsSecurityEventXPathQueries
Explicit Security! XPath filters for a new DCR, for example
"Security!*[System[(EventID=4625)]]". No default all-events collection. Existing
DCR filters are preserved and must match if filters are supplied.
.PARAMETER WindowsSecurityEventDcrId
Optional existing, approved Windows DCR in the workspace resource group/region.
Only one Microsoft-SecurityEvent source/flow to this workspace is supported.
DCE/private-link/custom transformations or other sources need manual review.
Without this ID a deterministic workspace DCR is created from explicit XPath filters.
.PARAMETER InstallWindowsAzureMonitorAgent
Separately authorize missing AzureMonitorWindowsAgent extensions on the explicitly
selected Azure VMs only. Requires an existing system-assigned VM identity. Uses a
published Microsoft.Azure.Monitor image version; does not modify existing extensions.
Requires VM extensions/write plus Monitor DCR/association writes. Agent provisioning
is not agent health: verify host audit policy, outbound networking and SecurityEvent
ingestion separately. Partial resources remain for inspection/rerun; no rollback.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$RepoPath,
    [switch]$InstallPrerequisitesOnly,
    [string[]]$SourceSubscriptionIds = @(),
    [ValidateNotNullOrEmpty()]
    [string[]]$EntraLogCategories = @('All'),
    [string[]]$DiagnosticResourceIds = @(),
    [switch]$EnableLegacyDefenderForCloud,
    [switch]$ConfigureCopilot,
    [string]$CopilotDataCollectionRuleId = '',
    [string]$CopilotDataCollectionEndpointId = '',
    [switch]$ConfigureConnectorPolicies,
    [string[]]$ConnectorPolicyScopeIds = @(),
    [switch]$GrantConnectorPolicyRoles,
    [switch]$RemediateConnectorPolicies,
    [switch]$IncludeStorageMetricsPolicy,
    [ValidatePattern('^[a-zA-Z0-9_-]{1,32}$')]
    [string]$ConnectorRemediationRunId = 'initial',
    [string[]]$WindowsSecurityEventMachineIds = @(),
    [string[]]$WindowsSecurityEventXPathQueries = @(),
    [string]$WindowsSecurityEventDcrId = '',
    [switch]$InstallWindowsAzureMonitorAgent,
    [ValidateRange(0, 30)]
    [int]$ThreatIntelLookbackDays = 0,
    [string]$ConnectorReportPath,
    [ValidateNotNullOrEmpty()]
    [string]$LogPath,
    [switch]$DeployPreviewDetections,
    [switch]$UpdateOwnedPreviewDetections,
    [string]$PreviewDetectionStatePath,
    # Read-only Azure inventory; skips Content Hub deployment and connector writes.
    [switch]$ConnectorStatusOnly,
    [switch]$ContentStatusOnly,
    [switch]$ConfigureConnectorsOnly,
    [switch]$PassThru,
    [switch]$FailOnConnectorError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Start-SentinelRunLog([string]$Path) {
    if (-not $Path) {
        $cloudDrive = Join-Path $HOME 'clouddrive'
        $root = if (Test-Path -LiteralPath $cloudDrive -PathType Container) { $cloudDrive } else { $PWD.Path }
        $filename = 'sentinel-deployment-{0}-{1}.log' -f [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'), [guid]::NewGuid().ToString('N')
        $Path = Join-Path (Join-Path $root 'Sentinel-Logs') $filename
    }
    $provider = $null; $drive = $null
    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path, [ref]$provider, [ref]$drive)
    if ($provider.Name -ne 'FileSystem') { throw 'LogPath must be a filesystem filename.' }
    if ($ConnectorReportPath -and $resolved -eq $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConnectorReportPath)) {
        throw 'LogPath and ConnectorReportPath must be different files.'
    }
    if (Test-Path -LiteralPath $resolved) { throw "Log file already exists; choose a new LogPath: $resolved" }
    $parent = Split-Path -Parent $resolved
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $parent -Force -WhatIf:$false -Confirm:$false -ErrorAction Stop
    }
    $null = Start-Transcript -LiteralPath $resolved -NoClobber -IncludeInvocationHeader -WhatIf:$false -Confirm:$false -ErrorAction Stop
    return $resolved
}

$runTranscriptStarted = $false
$transcriptRunError = $null
try {
    $LogPath = Start-SentinelRunLog $LogPath
    $runTranscriptStarted = $true
    Write-Host "Run log: $LogPath" -ForegroundColor Cyan
    Write-Host 'Default log filenames use UTC timestamps. Treat this transcript as sensitive; review/redact before sharing.'

$script:ChangeCaller = $PSCmdlet
if (@(@($ConnectorStatusOnly, $ContentStatusOnly, $ConfigureConnectorsOnly) | Where-Object { $_ }).Count -gt 1) {
    throw 'Choose one of -ContentStatusOnly, -ConnectorStatusOnly (read-only), or -ConfigureConnectorsOnly (apply supported connector setup).'
}
if ($UpdateOwnedPreviewDetections -and -not $DeployPreviewDetections) {
    throw '-UpdateOwnedPreviewDetections requires -DeployPreviewDetections.'
}
if ($DeployPreviewDetections -and ($ConnectorStatusOnly -or $ContentStatusOnly)) {
    throw 'Preview detection deployment cannot be combined with read-only status modes; use -WhatIf to preview it.'
}

if (-not $RepoPath) {
    $cloudDrive = Join-Path $HOME 'clouddrive'
    $RepoPath = if (Test-Path $cloudDrive) { Join-Path $cloudDrive 'Sentinel-As-Code' } else { Join-Path $HOME 'Sentinel-As-Code' }
}
$RepoUrl = 'https://github.com/noodlemctwoodle/Sentinel-As-Code.git'
$ApiVersion = '2025-09-01'
$PreviewApiVersion = '2025-10-01-preview'
$MonitorApiVersion = '2021-05-01-preview'
$MaxRetryAttempts = 2

$RequestedSolutions = @(
    'Azure Activity'
    'Microsoft 365'
    'Agent 365'
    'Data collection health monitoring'
    'Threat Intelligence'
    'Microsoft Defender XDR'
    'Microsoft Defender for Cloud'
    'Security Threat Essentials'
    'Business Email Compromise - Financial Fraud'
    'Cloud Identity Threat Protection Essentials'
    'Cloud Service Threat Protection Essentials'
    'Network Threat Protection Essentials'
    'Web Shells Threat Protection'
    'Microsoft Entra ID Protection'
    'Microsoft Purview'
    'Microsoft Entra ID'
    'Endpoint Threat Protection Essentials'
    'Multi Cloud Attack Coverage'
    'Malware Protection Essentials'
    'Log4j Vulnerability Detection'
    'Windows Security Events'
    'Dev 0270 Detection and Hunting'
    'Attacker Tools Threat Protection Essentials'
    'ZINC Open Source Threat Protection'
    'Windows Firewall'
    'Sentinel SOAR Essentials'
    'Threat Intelligence (NEW)'
    'SOC Handbook'
    'Azure Storage'
    'Azure Network Security Groups'
    'Global Secure Access'
    'Hybrid Attack - Cloud & Identity'
    'Microsoft Copilot'
    'Microsoft Purview Insider Risk Management'
    'Microsoft Defender Threat Intelligence'
    'Threat Analysis & Response'
    'UEBA Essentials'
)
$Severities = @('High', 'Medium', 'Low', 'Informational')

function Step([string]$Text) { Write-Host "`n=== $Text ===" -ForegroundColor Cyan }

function Initialize-SentinelModuleInstaller {
    foreach ($command in @('Install-Module', 'Get-PSRepository', 'Register-PSRepository', 'Get-PackageProvider', 'Install-PackageProvider')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "PowerShell dependency installer command $command is unavailable. Use PowerShell 7.2+ Cloud Shell with PowerShellGet/PackageManagement; no cloud setup was attempted."
        }
    }
    $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $repository) {
        Write-Host 'Registering the default PowerShell Gallery for dependency installation.' -ForegroundColor Cyan
        Register-PSRepository -Default -ErrorAction Stop
        $repository = Get-PSRepository -Name PSGallery -ErrorAction Stop
    }
    if ($repository.SourceLocation -notmatch '^https://www\.powershellgallery\.com/api/v2/?$') {
        throw 'PSGallery points to an unexpected source. Correct its registration manually; dependencies will not be downloaded from an unverified repository.'
    }
    $provider = @(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -ge [version]'2.8.5.201' })
    if (-not $provider.Count) {
        Write-Host 'Installing the NuGet provider for CurrentUser.' -ForegroundColor Cyan
        Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    }
}

function Ensure-Module([string]$Name, [string[]]$RequiredCommands = @()) {
    $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    $install = $null -eq $module
    if ($module) {
        Import-Module $Name -Force -ErrorAction Stop
        $install = @($RequiredCommands | Where-Object { -not (Get-Command $_ -Module $Name -ErrorAction SilentlyContinue) }).Count -gt 0
    }
    if ($install) {
        if ($WhatIfPreference) {
            throw "Dependency $Name is missing or lacks required commands. WhatIf does not install modules; run -InstallPrerequisitesOnly without -WhatIf first."
        }
        Initialize-SentinelModuleInstaller
        Write-Host "Installing/updating dependency $Name from PSGallery (CurrentUser)." -ForegroundColor Cyan
        $arguments = @{ Name = $Name; Scope = 'CurrentUser'; Repository = 'PSGallery'; Force = $true
            AllowClobber = $true; ErrorAction = 'Stop' }
        if ((Get-Command Install-Module -ErrorAction Stop).Parameters.ContainsKey('AcceptLicense')) { $arguments.AcceptLicense = $true }
        Install-Module @arguments
        Import-Module $Name -Force -ErrorAction Stop
    }
    foreach ($command in $RequiredCommands) {
        if (-not (Get-Command $command -Module $Name -ErrorAction SilentlyContinue)) {
            throw "$Name still lacks required command $command after dependency setup. Restart PowerShell if an older assembly is loaded, then rerun; no cloud setup was attempted."
        }
    }
    Write-Host "Dependency ready: $Name" -ForegroundColor Green
}

function Ensure-AzureLogin {
    try {
        if (Get-AzContext -ErrorAction SilentlyContinue) {
            Get-AzSubscription -ErrorAction Stop | Out-Null
            return
        }
    } catch {}
    if (Test-Path (Join-Path $HOME 'clouddrive')) {
        throw 'No Azure context was found. In Azure Portal Cloud Shell, restart the PowerShell session or run Connect-AzAccount, then rerun this script.'
    }
    Write-Warning 'Azure authentication is required. Starting device authentication.'
    Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop | Out-Null
}

function Select-ItemNumber([array]$Items, [scriptblock]$Display, [string]$Prompt, [switch]$AllowBack, [string]$BackLabel = 'Previous selection') {
    if ($Items.Count -eq 0) {
        if (-not $AllowBack) { throw "No options found for $Prompt" }
        Write-Warning 'No items are available here. Enter B to go back and choose a different target.'
    }
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), (& $Display $Items[$i]))
    }
    if ($AllowBack) { Write-Host "  [B] Back - $BackLabel" -ForegroundColor Yellow }
    do {
        $raw = (Read-Host $Prompt).Trim()
        if ($AllowBack -and $raw -in @('B', 'Back')) { return $null }
        $number = 0
        $valid = [int]::TryParse($raw, [ref]$number) -and $number -ge 1 -and $number -le $Items.Count
        if (-not $valid) {
            $choices = if ($Items.Count) { "Enter 1-$($Items.Count)" } else { 'No numbered choices are available' }
            if ($AllowBack) { $choices += ', or B to go back' }
            Write-Warning "$choices."
        }
    } until ($valid)
    $Items[$number - 1]
}

function Select-SentinelTarget([string]$TargetSubscriptionId, [string]$TargetResourceGroup, [string]$TargetWorkspace) {
    $stage = 'Subscription'
    $selectedGroup = $null
    $selectedWorkspace = $null
    $selectedContext = $null
    while ($stage -ne 'Done') {
        switch ($stage) {
            'Subscription' {
                if ($TargetSubscriptionId) {
                    $TargetSubscriptionId = ([guid]::Parse($TargetSubscriptionId)).ToString()
                } else {
                    $subscriptions = @(Get-AzSubscription | Where-Object State -eq 'Enabled' | Sort-Object Name)
                    Write-Host 'Available subscriptions:' -ForegroundColor Cyan
                    $selectedSubscription = Select-ItemNumber $subscriptions { param($item) "$($item.Name) [$($item.Id)]" } 'Select subscription number'
                    $TargetSubscriptionId = [string]$selectedSubscription.Id
                }
                $selectedContext = Set-AzContext -SubscriptionId $TargetSubscriptionId -ErrorAction Stop
                $stage = 'ResourceGroup'
            }
            'ResourceGroup' {
                if ($TargetResourceGroup) {
                    $selectedGroup = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction Stop
                } else {
                    $groups = @(Get-AzResourceGroup | Sort-Object ResourceGroupName)
                    Write-Host "`nAvailable resource groups in subscription $TargetSubscriptionId :" -ForegroundColor Cyan
                    $selectedGroup = Select-ItemNumber $groups { param($item) "$($item.ResourceGroupName) [$($item.Location)]" } 'Select resource group number (or B to go back)' -AllowBack -BackLabel 'Subscriptions'
                }
                if ($null -eq $selectedGroup) {
                    $TargetSubscriptionId = ''
                    $TargetResourceGroup = ''
                    $TargetWorkspace = ''
                    $selectedWorkspace = $null
                    $stage = 'Subscription'
                } else {
                    $stage = 'Workspace'
                }
            }
            'Workspace' {
                if ($TargetWorkspace) {
                    $selectedWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $selectedGroup.ResourceGroupName -Name $TargetWorkspace -ErrorAction Stop
                } else {
                    $workspaces = @(Get-AzOperationalInsightsWorkspace -ResourceGroupName $selectedGroup.ResourceGroupName | Sort-Object Name)
                    Write-Host "`nAvailable Log Analytics workspaces in $($selectedGroup.ResourceGroupName):" -ForegroundColor Cyan
                    $selectedWorkspace = Select-ItemNumber $workspaces {
                        param($item)
                        $location = Safe-Prop $item 'Location'
                        if (-not $location) { $location = Safe-Prop $item 'ResourceLocation' }
                        if (-not $location) { $location = 'region resolved after selection' }
                        "$($item.Name) [$location]"
                    } 'Select Sentinel workspace number (or B to go back)' -AllowBack -BackLabel 'Resource groups'
                }
                if ($null -eq $selectedWorkspace) {
                    $TargetResourceGroup = ''
                    $TargetWorkspace = ''
                    $selectedGroup = $null
                    $stage = 'ResourceGroup'
                } else {
                    $stage = 'Done'
                }
            }
        }
    }
    [pscustomobject]@{
        SubscriptionId = $TargetSubscriptionId
        Context = $selectedContext
        ResourceGroup = $selectedGroup
        Workspace = $selectedWorkspace
    }
}

function Safe-Prop([object]$Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { $property.Value }
}

function Get-Field($Object, [string]$Name, $Default = $null) {
    if ($Object -is [Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        foreach ($key in $Object.Keys) {
            if ([string]$key -eq $Name) { return $Object[$key] }
        }
    }
    return $Default
}

function Content-Name([object]$Item) {
    $properties = Safe-Prop $Item 'properties'
    foreach ($propertyName in @('displayName', 'title', 'contentProductId', 'packageName', 'name')) {
        $value = Safe-Prop $properties $propertyName
        if ($value) { return [string]$value }
    }
    $topName = Safe-Prop $Item 'name'
    if ($topName) { return [string]$topName }
    return ''
}

function Workspace-Region($WorkspaceObject, [string]$Sub, [string]$RG, [string]$Name) {
    foreach ($propertyName in @('Location', 'ResourceLocation')) {
        $value = Safe-Prop $WorkspaceObject $propertyName
        if ($value) { return ([string]$value).ToLowerInvariant().Replace(' ', '') }
    }
    $id = "/subscriptions/$Sub/resourceGroups/$RG/providers/Microsoft.OperationalInsights/workspaces/$Name"
    $resource = Get-AzResource -ResourceId $id -ErrorAction Stop
    ([string]$resource.Location).ToLowerInvariant().Replace(' ', '')
}

function Read-Arm([string]$Path, [string]$Method = 'GET', $Body = $null) {
    if ($Path -match '^https?://') {
        $uri = [uri]$Path
        if ($script:ArmEndpoint -and ($uri.Scheme -ne 'https' -or $uri.Authority -ne $script:ArmEndpoint.Authority)) {
            throw "Unexpected ARM pagination host: $($uri.Authority)"
        }
        $Path = $uri.PathAndQuery
    }
    $arguments = @{ Path = $Path; Method = $Method; ErrorAction = 'Stop' }
    if ($null -ne $Body) {
        $arguments.Payload = ConvertTo-Json -InputObject $Body -Depth 100
    }
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $response = Invoke-AzRestMethod @arguments
        $status = [int]$response.StatusCode
        if ($status -ge 200 -and $status -lt 300) { break }
        $retryable = $Method -in @('GET', 'PUT') -and $status -in @(429, 500, 502, 503, 504)
        $delay = [math]::Ceiling([math]::Pow(2, $attempt))
        $headerProperty = $response.PSObject.Properties['Headers']
        if ($retryable -and $headerProperty -and $headerProperty.Value -is [System.Net.Http.Headers.HttpResponseHeaders]) {
            $retryAfter = $headerProperty.Value.RetryAfter
            if ($null -ne $retryAfter) {
                if ($null -ne $retryAfter.Delta) { $delay = [math]::Ceiling($retryAfter.Delta.TotalSeconds) }
                elseif ($null -ne $retryAfter.Date) { $delay = [math]::Ceiling([math]::Max(0, ($retryAfter.Date - [DateTimeOffset]::UtcNow).TotalSeconds)) }
            }
        }
        if ($retryable -and $attempt -lt 3 -and $delay -le 30) {
            Write-Warning "ARM $Method returned HTTP $status; retry attempt $($attempt + 1)/3 in $delay second(s)."
            Start-Sleep -Seconds $delay
            continue
        }
        $errorMessage = "$Method $Path returned HTTP $status. Check API support, permissions and source prerequisites."
        $exception = [InvalidOperationException]::new($errorMessage)
        $exception.Data['ArmStatusCode'] = $status
        throw $exception
    }
    if ($response.Content) {
        return ConvertFrom-Json -InputObject $response.Content -AsHashtable -Depth 100
    }
}

function Read-ArmList([string]$Path) {
    $seen = [Collections.Generic.HashSet[string]]::new()
    while ($Path) {
        if (-not $seen.Add($Path)) { throw 'ARM returned a repeated pagination link.' }
        $page = Read-Arm $Path
        if ($null -eq $page -or -not $page.Contains('value') -or $page.value -isnot [array]) { throw "Missing or invalid collection in $Path; resource absence cannot be inferred." }
        foreach ($item in $page.value) { $item }
        $Path = [string](Get-Field $page 'nextLink' '')
    }
}

function Arm-Get([string]$Path) {
    $response = Invoke-AzRestMethod -Method GET -Path $Path -ErrorAction Stop
    if ($response.StatusCode -ne 200) { throw "GET failed: HTTP $($response.StatusCode)" }
    $response.Content | ConvertFrom-Json
}

function Available-Solutions {
    $path = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace/providers/Microsoft.SecurityInsights/contentProductPackages?api-version=$ApiVersion"
    @(Read-ArmList $path | ForEach-Object { ConvertFrom-Json (ConvertTo-Json $_ -Depth 100) })
}

function Installed-Names {
    $path = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace/providers/Microsoft.SecurityInsights/contentPackages?api-version=$ApiVersion"
    $set = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($item in @(Read-ArmList $path | ForEach-Object { ConvertFrom-Json (ConvertTo-Json $_ -Depth 100) })) {
        $name = Content-Name $item
        if ($name) { [void]$set.Add($name) }
    }
    return ,$set
}

function Confirmed-ContentHubPackageNames([string[]]$Names, [switch]$DiagnosticOnly) {
    $script:ServerUrl = $script:ArmEndpoint.AbsoluteUri.TrimEnd('/')
    $script:BaseUri = "$script:ServerUrl$script:WorkspaceId"
    $script:SentinelApiVersion = $ApiVersion
    $script:ContentHubUnresolvedFailures = @{}
    $script:ContentHubRequestDetails = @{}
    $script:ContentHubApiFailures = 0
    . ([scriptblock]::Create("function Invoke-SentinelApi {`n$((Get-Command Invoke-ContentHubArmApi).Definition)`n}"))
    Confirm-ContentHubSelectedTarget
    $root = "$script:BaseUri/providers/Microsoft.SecurityInsights"
    $catalog = Invoke-SentinelApi -Uri "$root/contentProductPackages?api-version=$ApiVersion" -Method GET -Headers @{}
    $ledger = Invoke-SentinelApi -Uri "$root/contentPackages?api-version=$ApiVersion" -Method GET -Headers @{}
    $lookup = @{}
    foreach ($entry in $ledger.value) {
        $name = [string](Get-ContentHubField $entry.properties 'displayName')
        if ($name) {
            if ($lookup.ContainsKey($name)) { throw "Ambiguous package registration: $name" }
            $lookup[$name] = $entry
        }
    }
    $confirmed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Names) {
        $status = Get-VersionAwareSolutionStatus $name @($catalog.value) $lookup
        if ($status.CatalogEntry) {
            if ($DiagnosticOnly -and $status.Presence.State -in @('Pending', 'Unverified')) {
                $status.Presence = Test-ContentHubPackagePresence $status.CatalogEntry
            }
            Save-ContentHubPackageDiagnostic $status.CatalogEntry $status.Presence $status.InstalledVersion
            $script:ContentHubPackageDiagnostics[[string]$status.CatalogEntry.name] | Add-Member InstallationStatus $status.Status -Force
        }
        if ($status.Status -eq 'Installed' -and $status.Presence.State -in @('Verified', 'NotFullyInspected')) {
            [void]$confirmed.Add($name)
            if ($status.Presence.State -eq 'NotFullyInspected') { Write-Verbose "$name registered version verified; detailed artifact inspection is partial. $($status.Presence.Detail)" }
        }
        else {
            $detail = if ($status.Presence) { $status.Presence.Detail } else { 'Not present in the current catalog.' }
            Write-Warning "$name package installation not confirmed: $($status.Status); $detail"
        }
    }
    return ,$confirmed
}

# Upstream passes a startup-only bearer header to every request. Do not use it:
# Az.Accounts obtains/renews ARM credentials through the existing Azure context.
# This adapter is installed only in a temporary copy of the Content Hub deployer.
function Get-ContentHubResourceCondition($Resource, $Template, $ParameterValues = $null) {
    $condition = Get-ContentHubField $Resource 'condition' '__absent__'
    if ($condition -ceq '__absent__') { return $true }
    if ($condition -is [bool]) { return $condition }
    if ($condition -isnot [string]) { return $null }
    $negate = $false
    if ($condition -match "^\[parameters\('([a-zA-Z0-9_-]+)'\)\]$") { $name = $Matches[1] }
    elseif ($condition -match "^\[not\(parameters\('([a-zA-Z0-9_-]+)'\)\)\]$") { $name = $Matches[1]; $negate = $true }
    else { return $null }
    $spec = Get-ContentHubField (Get-ContentHubField $Template 'parameters') $name
    if ((Get-ContentHubField $spec 'type') -ne 'bool') { return $null }
    $entry = Get-ContentHubField $ParameterValues $name
    $value = if ($null -ne $entry) { Get-ContentHubField $entry 'value' } else { Get-ContentHubField $spec 'defaultValue' }
    if ($value -isnot [bool]) { return $null }
    if ($negate) { return -not $value }
    return $value
}

function Assert-ContentHubPackageResources($Template, [string]$Path = 'template', [int]$Depth = 0, $ParameterValues = $null) {
    function Stop-PackagePreflight([string]$Reason) {
        $failure = [InvalidOperationException]::new("Package resource preflight failed: $Reason No deployment submitted.")
        $failure.Data['ContentHubPreflightReason'] = $Reason
        throw $failure
    }
    if ($Depth -gt 64) { Stop-PackagePreflight "$Path exceeds the supported nesting depth." }
    if ($null -eq $Template -or ($Template -isnot [Collections.IDictionary] -and $Template -isnot [pscustomobject])) {
        Stop-PackagePreflight "$Path must be a JSON object."
    }
    $resources = Get-ContentHubField $Template 'resources' -NoEnumerate
    if ($null -eq $resources) { return }
    if ($resources -is [array]) {
        $entries = $resources
    } elseif ($resources -is [Collections.IDictionary] -or $resources -is [pscustomobject]) {
        if ((Get-ContentHubField $Template 'languageVersion') -ne '2.0') {
            Stop-PackagePreflight "$Path.resources is an object; symbolic resources require languageVersion 2.0."
        }
        # ARM 2.0 resources are keyed by symbolic name, not an array of resources.
        $entries = @(if ($resources -is [Collections.IDictionary]) { $resources.Values } else {
            $resources.PSObject.Properties | ForEach-Object Value
        })
    } else { Stop-PackagePreflight "$Path.resources must be an array or an ARM 2.0 symbolic resource object." }
    $index = 0
    foreach ($resource in $entries) {
        $resourcePath = "$Path.resources[$index]"
        $index++
        if ($resource -isnot [Collections.IDictionary] -and $resource -isnot [pscustomobject]) {
            Stop-PackagePreflight "$resourcePath must be a JSON resource object."
        }
        $condition = Get-ContentHubResourceCondition $resource $Template $ParameterValues
        if ($condition -is [bool] -and -not $condition) { continue }
        $type = Get-ContentHubField $resource 'type'
        if ($type -isnot [string] -or $type -notmatch '^[a-zA-Z0-9.]+(?:/[a-zA-Z0-9.-]+)+$') {
            Stop-PackagePreflight "$resourcePath.type is missing, empty or not a supported literal ARM resource type."
        }
        if ($type -match 'Microsoft\.(Logic|Web/connections|Authorization|Resources/deploymentScripts)') {
            Stop-PackagePreflight "$resourcePath contains a prohibited executable resource type."
        }
        if ($type -match '(^|/)alertRules$' -and (Get-ContentHubField $resource 'kind') -eq 'NRT') {
            Stop-PackagePreflight "$resourcePath contains an executable NRT rule; inert content templates are permitted."
        }
        if ($type -match '(^|/)(alertRules|workbooks|workflows|connections)$') {
            Stop-PackagePreflight "$resourcePath contains executable content outside the identity-checked deployer."
        }
        if ($type -match '(^|/)deployments$') {
            $properties = Get-ContentHubField $resource 'properties'
            if ($null -eq $properties -or ($properties -isnot [Collections.IDictionary] -and $properties -isnot [pscustomobject])) {
                Stop-PackagePreflight "$resourcePath.properties must be an inline deployment object."
            }
            if ((Get-ContentHubField $properties 'templateLink' '__absent__') -ne '__absent__') {
                Stop-PackagePreflight "$resourcePath contains a linked deployment; an inspectable inline template is required."
            }
            $inline = Get-ContentHubField $properties 'template'
            if ($null -eq $inline -or ($inline -isnot [Collections.IDictionary] -and $inline -isnot [pscustomobject]) -or
                $null -eq (Get-ContentHubField $inline 'resources' -NoEnumerate)) {
                Stop-PackagePreflight "$resourcePath requires an inspectable inline ARM template with resources."
            }
            Assert-ContentHubPackageResources $inline "$resourcePath.properties.template" ($Depth + 1)
        }
        # Child ARM resources are executable; properties.mainTemplate remains inert.
        Assert-ContentHubPackageResources $resource $resourcePath ($Depth + 1) $ParameterValues
    }
}

function Initialize-ContentHubPackageTemplate($Template) {
    if ($null -eq $Template) { throw 'The catalog returned no deployable package manifest. No content registration or deployment submitted.' }
    try {
        $json = if ($Template -is [string]) { $Template } else { ConvertTo-Json -InputObject $Template -Depth 100 -WarningAction Stop }
        $copy = ConvertFrom-Json -InputObject $json -Depth 100 -ErrorAction Stop
    } catch { throw 'Package manifest could not be read without truncation; no deployment submitted. Provider bodies and parameter values suppressed.' }
    $resources = Get-ContentHubField $copy 'resources' -NoEnumerate
    if ($null -eq $resources) { throw 'The catalog manifest does not declare resources. Missing content is not a registration-only solution; no write submitted.' }
    Assert-ContentHubPackageResources $copy -ParameterValues @{ E5Flavor = @{ value = $false } }
    function Clear-ContentHubPostDeployment($Node) {
        $resources = Get-ContentHubField $Node 'resources' -NoEnumerate
        $entries = @(if ($resources -is [array]) { $resources }
            elseif ($resources -is [Collections.IDictionary]) { $resources.Values }
            elseif ($resources -is [pscustomobject]) { $resources.PSObject.Properties | ForEach-Object Value })
        foreach ($resource in $entries) {
            $properties = Get-ContentHubField $resource 'properties'
            $metadata = Get-ContentHubField (Get-ContentHubField $properties 'mainTemplate') 'metadata'
            if ($metadata -and $metadata.PSObject.Properties['postDeployment']) { $metadata.postDeployment = $null }
            if ((Get-ContentHubField $resource 'type') -match '(^|/)deployments$') {
                Clear-ContentHubPostDeployment (Get-ContentHubField $properties 'template')
            }
            Clear-ContentHubPostDeployment $resource
        }
    }
    Clear-ContentHubPostDeployment $copy
    return $copy
}

function Get-ContentHubPackageParameters($Template, [string]$Workspace, [string]$Region) {
    $parameters = Get-ContentHubField $Template 'parameters'
    $result = @{}
    if ($null -eq $parameters) { return $result }
    if ($parameters -isnot [Collections.IDictionary] -and $parameters -isnot [pscustomobject]) {
        throw 'Package parameter declarations must be a JSON object; no deployment submitted.'
    }
    $names = if ($parameters -is [Collections.IDictionary]) { @($parameters.Keys) } else { @($parameters.PSObject.Properties.Name) }
    foreach ($name in $names) {
        $spec = Get-ContentHubField $parameters $name
        if ($null -eq $spec -or ($spec -isnot [Collections.IDictionary] -and $spec -isnot [pscustomobject])) {
            throw 'Package contains an invalid parameter declaration; no deployment submitted.'
        }
        if ($name -eq 'E5Flavor') {
            if ((Get-ContentHubField $spec 'type') -ne 'bool') { throw 'Package E5Flavor must be a boolean; no deployment submitted.' }
            $result[$name] = @{ value = $false }
        } elseif ($name -in @('workspace', 'workspace-location')) {
            if ((Get-ContentHubField $spec 'type') -ne 'string') { throw 'Workspace package parameters must be strings; no deployment submitted.' }
            $value = if ($name -eq 'workspace') { $Workspace } else { $Region }
            $result[$name] = @{ value = $value }
        } else {
            $hasDefault = if ($spec -is [Collections.IDictionary]) { $spec.Contains('defaultValue') } else { $null -ne $spec.PSObject.Properties['defaultValue'] }
            if (-not $hasDefault) { throw 'Package requires additional template-specific parameters without defaults; review the installed documentation and deploy that package separately. No deployment submitted.' }
        }
    }
    return $result
}

function Invoke-ContentHubArmApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][hashtable]$Headers,
        [string]$Body,
        [switch]$OptionalWorkbookProbe,
        [switch]$AllowMissingWorkbook,
        [switch]$AllowMissingContentArtifact,
        [string[]]$VisitedPages = @(),
        [ValidateRange(1, 10)][int]$MaxRetries = 3,
        [ValidateRange(0, 30)][int]$RetryDelaySeconds = 5
    )

    $failureKey = "$($Method.ToUpperInvariant()) $Uri"
    $status = $null
    $serviceCode = ''
    $prerequisite = ''
    $reason = 'Azure validation reason not classified; inspect the rule in Sentinel.'
    $requestId = ''
    $ruleName = ''
    $requestSubmitted = $false
    if (-not (Get-Variable ContentHubRequestDetails -Scope Script -ErrorAction SilentlyContinue)) {
        $script:ContentHubRequestDetails = @{}
    }
    try {
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) { throw 'Azure context is unavailable. Restart Cloud Shell authentication before rerunning.' }
        $endpoint = [uri]$context.Environment.ResourceManagerUrl
        $target = [uri]$Uri
        if (-not $target.IsAbsoluteUri -or $target.Scheme -ne 'https' -or $target.Authority -ne $endpoint.Authority) {
            throw 'Content Hub request does not target the current Azure ARM endpoint.'
        }
        if ($Uri -in $VisitedPages) { throw 'Repeated Content Hub pagination link.' }
        if ([string]$context.Subscription.Id -ne $script:SubscriptionId) {
            throw 'Azure subscription context changed during Content Hub deployment.'
        }
        $expectedTarget = Get-Variable ContentHubExpectedTarget -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($expectedTarget) {
            if ([string]$context.Tenant.Id -ne $expectedTarget.TenantId -or [string]$context.Subscription.Id -ne $expectedTarget.SubscriptionId) {
                throw 'Selected Content Hub tenant/subscription context changed.'
            }
            if ($target.AbsolutePath -match '^/subscriptions/([^/]+)(?:/|$)' -and $matches[1] -ne $expectedTarget.SubscriptionId) {
                throw 'Content Hub request targets a different subscription than the canonical target.'
            }
            if ($target.AbsolutePath -match '(?i)^(.*/providers/Microsoft\.OperationalInsights/workspaces/[^/]+)(?:/|$)' -and
                $matches[1] -ne $expectedTarget.WorkspaceResourceId) {
                throw 'Content Hub request targets a different workspace than the selected canonical target.'
            }
        }
        if ($Method -eq 'PUT' -and $target.AbsolutePath -match '/Microsoft\.SecurityInsights/alertRules/[^/]+$' -and $Body) {
            $rulePayload = $Body | ConvertFrom-Json -Depth 100
            if ($rulePayload.PSObject.Properties['kind'] -and $rulePayload.kind -eq 'NRT') {
                throw 'NRT rule deployment is disabled. No NRT write was submitted.'
            }
        }
        $request = @{
            Uri = $Uri
            Method = $Method
            DefaultProfile = $context
            ErrorAction = 'Stop'
        }
        if ($Method -eq 'PUT' -and $target.AbsolutePath -match '/providers/Microsoft\.Resources/deployments/[^/]+$') {
            $deployment = $Body | ConvertFrom-Json -Depth 100
            $deploymentProperties = Get-ContentHubField $deployment 'properties'
            Assert-ContentHubPackageResources (Get-ContentHubField $deploymentProperties 'template') -ParameterValues (Get-ContentHubField $deploymentProperties 'parameters')
        }
        if ($PSBoundParameters.ContainsKey('Body')) { $request.Payload = $Body }
        $authRetried = $false
        $attempt = 0
        while ($true) {
            $attempt++
            $response = $null
            $errorBody = ''
            try {
                $requestSubmitted = $true
                $response = Az.Accounts\Invoke-AzRestMethod @request
                $status = [int]$response.StatusCode
                if ($status -ge 400) { $errorBody = [string]$response.Content }
            } catch {
                $responseProperty = $_.Exception.PSObject.Properties['Response']
                $statusProperty = if ($responseProperty -and $responseProperty.Value) {
                    $responseProperty.Value.PSObject.Properties['StatusCode']
                }
                if (-not $statusProperty) { throw }
                $status = [int]$statusProperty.Value
                if ($_.ErrorDetails) { $errorBody = [string]$_.ErrorDetails.Message }
                if (-not $errorBody -and $responseProperty.Value -is [System.Net.Http.HttpResponseMessage]) {
                    $errorBody = $responseProperty.Value.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                }
            }
            if ($status -ge 200 -and $status -lt 300) {
                $data = if ($response.Content) { $response.Content | ConvertFrom-Json -Depth 100 }
                if ($AllowMissingContentArtifact -and $Method -eq 'GET' -and
                    (-not $data -or -not $data.PSObject.Properties['id'])) {
                    throw 'Artifact GET returned no resource identity; absence was not established.'
                }
                if ($Method -eq 'GET' -and $target.AbsolutePath -match '/(alertRules|metadata|workbooks|contentTemplates|contentPackages|contentProductPackages|dataConnectors|dataConnectorDefinitions|savedSearches)$' -and
                    (-not $data -or -not $data.PSObject.Properties['value'] -or $data.value -isnot [array])) {
                    throw 'Incomplete content inventory response; refusing to infer resource absence.'
                }
                # A later successful call resolves an earlier failed probe of
                # this exact method/URI; do not confuse history with final failure.
                $script:ContentHubUnresolvedFailures.Remove($failureKey)
                $script:ContentHubRequestDetails.Remove($failureKey)
                if ($data -and $Method -eq 'GET' -and $data.PSObject.Properties['nextLink'] -and $data.nextLink) {
                    if (-not $data.PSObject.Properties['value']) { throw 'Invalid paginated ARM collection.' }
                    $next = & $MyInvocation.MyCommand.Name -Uri $data.nextLink -Method GET -Headers @{} -VisitedPages @($VisitedPages + $Uri)
                    $data.value = @($data.value) + @($next.value)
                    $data.nextLink = $null
                }
                if ($data -and $Method -eq 'PUT' -and $target.AbsolutePath -match '/providers/Microsoft\.Resources/deployments/[^/]+$') {
                    for ($poll = 0; $poll -lt 120; $poll++) {
                        $state = [string]$data.properties.provisioningState
                        if ($state -eq 'Succeeded') { break }
                        if ($state -in @('Failed', 'Canceled', 'Cancelled')) { throw "ARM deployment ended in $state. Inspect deployment operations in Azure." }
                        Start-Sleep -Seconds 5
                        $data = & $MyInvocation.MyCommand.Name -Uri $Uri -Method GET -Headers @{}
                    }
                    if ($data.properties.provisioningState -ne 'Succeeded') { throw 'ARM deployment still pending after ten minutes; inspect before rerunning.' }
                }
                if ($null -ne $data) { return $data }
                return
            }
            # One authentication retry only, and only for idempotent ARM operations.
            if ($status -eq 401 -and -not $authRetried -and $Method -in @('GET', 'PUT')) {
                $authRetried = $true
                Write-Warning 'ARM returned 401; reacquiring credentials from the existing Az context and retrying once.'
                $null = Get-AzAccessToken -ResourceUrl $endpoint.AbsoluteUri -TenantId $context.Tenant.Id -DefaultProfile $context -ErrorAction Stop
                $attempt--
                continue
            }
            if ($status -in @(429, 500, 502, 503, 504) -and $Method -in @('GET', 'PUT') -and $attempt -lt $MaxRetries) {
                $delay = $RetryDelaySeconds * $attempt
                $headerProperty = if ($null -ne $response) { $response.PSObject.Properties['Headers'] }
                if ($headerProperty -and $headerProperty.Value -is [System.Net.Http.Headers.HttpResponseHeaders]) {
                    $retryAfter = $headerProperty.Value.RetryAfter
                    if ($null -ne $retryAfter) {
                        if ($null -ne $retryAfter.Delta) { $delay = $retryAfter.Delta.TotalSeconds }
                        elseif ($null -ne $retryAfter.Date) { $delay = [math]::Max(0, ($retryAfter.Date - [DateTimeOffset]::UtcNow).TotalSeconds) }
                    }
                }
                if ($delay -le 30) {
                    Write-Warning "ARM returned HTTP $status; retrying request in $([math]::Ceiling($delay)) seconds."
                    Start-Sleep -Seconds ([math]::Ceiling($delay))
                    continue
                }
            }
            $headersProperty = if ($response) { $response.PSObject.Properties['Headers'] }
            if ($headersProperty -and $headersProperty.Value -is [System.Net.Http.Headers.HttpResponseHeaders]) {
                $values = $null
                if ($headersProperty.Value.TryGetValues('x-ms-request-id', [ref]$values)) {
                    $candidateId = [string](@($values)[0])
                    if ($candidateId -match '^[a-zA-Z0-9-]{1,128}$') { $requestId = $candidateId }
                }
            }
            # Keep structured codes and only reviewed prerequisite phrases. Never echo
            # raw service bodies (they can include credentials or template parameters).
            try {
                $serviceError = $errorBody | ConvertFrom-Json -Depth 100
                $errorDocument = if ($serviceError.PSObject.Properties['error']) { $serviceError.error } else { $serviceError }
                $code = if ($errorDocument.PSObject.Properties['code']) { [string]$errorDocument.code } else { '' }
                if ($code -match '^[A-Za-z][A-Za-z0-9_.-]{0,100}$') { $serviceCode = $code }
                $messages = $errorDocument | ConvertTo-Json -Depth 100 -Compress
                if ($status -eq 400 -and $Method -eq 'PUT' -and $target.AbsolutePath -match '/Microsoft\.SecurityInsights/alertRules/[^/]+$') {
                    if ($messages -match 'One of the tables does not exist|Failed to resolve table or column expression|FailedToResolveTable') { $prerequisite = 'One of the tables does not exist' }
                    elseif ($messages -match 'The given column|FailedToResolveColumn|Failed to resolve column expression') { $prerequisite = 'The given column is unavailable' }
                    elseif ($messages -match 'FailedToResolveScalarExpression|Failed to resolve scalar expression') { $prerequisite = 'FailedToResolveScalarExpression' }
                    if ($prerequisite) { $reason = $prerequisite }
                    elseif ($messages -match 'SemanticError|semantic error|SyntaxError|syntax error') {
                        $reason = 'Query semantic/syntax validation failed; this is not automatically a missing-source prerequisite.'
                    } elseif ($messages -match '(?i)(queryFrequency|queryPeriod).*(not supported|not allowed|not applicable|must not|invalid)') {
                        $reason = 'Query scheduling fields were rejected for this rule type.'
                    } elseif ($messages -match 'InvalidTemplate|DeploymentFailed') {
                        $reason = 'Rule template validation failed.'
                    }
                }
            } catch {
                $reason = 'Azure error body was unavailable or not valid structured JSON; inspect the failed request in Azure.'
            }
            if ($Method -eq 'PUT' -and $target.AbsolutePath -match '/Microsoft\.SecurityInsights/alertRules/[^/]+$' -and $Body) {
                $ruleBody = $Body | ConvertFrom-Json -Depth 100
                if ($ruleBody.PSObject.Properties['properties'] -and $ruleBody.properties.PSObject.Properties['displayName']) {
                    $ruleName = ([string]$ruleBody.properties.displayName -replace '[\x00-\x1f\x7f]', ' ')
                    if ($ruleName.Length -gt 200) { $ruleName = $ruleName.Substring(0, 200) }
                }
            }
            $exception = [InvalidOperationException]::new("Content Hub ARM $Method failed with HTTP $status; code=$serviceCode; rule=$ruleName; reason=$reason; requestId=$requestId.")
            $exception.Data['ArmStatusCode'] = $status
            $exception.Data['AzureErrorCode'] = $serviceCode
            $exception.Data['RulePrerequisite'] = $prerequisite
            throw $exception
        }
    } catch {
        $script:ContentHubApiFailures++
        if ($_.Exception.Data['ContentHubPreflightReason']) { $reason = [string]$_.Exception.Data['ContentHubPreflightReason'] }
        $requestUri = $null
        $safePath = if ([uri]::TryCreate($Uri, [UriKind]::Absolute, [ref]$requestUri)) {
            $requestUri.AbsolutePath
        } else { '(invalid request URI)' }
        $httpStatus = if ($null -ne $status) { [string]$status } else { 'unavailable' }
        # Do not retain bearer headers, query strings or response bodies, which
        # can contain credentials or echoed request properties.
        $failure = "$($Method.ToUpperInvariant()) $safePath | HTTP $httpStatus | $($_.Exception.GetType().Name) | AzureCode=$serviceCode | Rule=$ruleName | Reason=$reason | RequestId=$requestId"
        $expectedProbe = $Method -eq 'GET' -and $OptionalWorkbookProbe -and $status -in @(400, 404) -and
            $safePath -match '/Microsoft\.SecurityInsights/contentTemplates/[^/]+$'
        $missingWorkbook = $Method -eq 'GET' -and $AllowMissingWorkbook -and $status -eq 404 -and
            $safePath -match '/Microsoft\.Insights/workbooks/[^/]+$'
        $missingArtifact = $Method -eq 'GET' -and $AllowMissingContentArtifact -and $status -eq 404 -and
            $safePath -match '/Microsoft\.SecurityInsights/(contentTemplates|metadata|dataConnectors|dataConnectorDefinitions)/[^/?#]+$'
        if ($AllowMissingContentArtifact -and $Method -eq 'GET' -and $status -eq 404 -and
            $safePath -match '/Microsoft\.OperationalInsights/workspaces/[^/]+/savedSearches/[^/?#]+$') { $missingArtifact = $true }
        if (-not $expectedProbe -and -not $missingWorkbook -and -not $missingArtifact -and -not $prerequisite) {
            $script:ContentHubUnresolvedFailures[$failureKey] = $failure
            $script:ContentHubRequestDetails[$failureKey] = [pscustomobject]@{
                Method = $Method.ToUpperInvariant(); ResourceId = $safePath; HttpStatus = $status
                AzureErrorCode = $serviceCode; RuleName = $ruleName; Reason = $reason; RequestId = $requestId
                WriteAttempted = $requestSubmitted
            }
        }
        if ($missingWorkbook -or $missingArtifact) { return $null }
        if ($expectedProbe) { Write-Verbose "Optional workbook identifier unavailable; upstream will try its fallback: $failure" }
        elseif ($prerequisite) { Write-Warning "Rule prerequisite unavailable: $prerequisite. Existing rules are retained; retry after source ingestion/schema is available." }
        else { Write-Warning "Content Hub request failed: $failure; Azure code=$serviceCode" }
        throw
    }
}

function Get-VersionAwareSolutionStatus {
    param([string]$SolutionName, [array]$AvailableSolutions, [hashtable]$InstalledLookup)
    $catalog = @($AvailableSolutions | Where-Object {
        $_.properties.PSObject.Properties['displayName'] -and $_.properties.displayName -eq $SolutionName
    })
    $result = @{
        Name = $SolutionName; Status = 'NotFound'; AvailableVersion = $null
        InstalledVersion = $null; CatalogEntry = $null; InstalledPackage = $null; Action = 'None'
        Presence = @{ State = 'Pending'; Detail = 'Package deployment and registration readback have not run.' }
        DeploymentSucceeded = $null
    }
    if (-not $catalog.Count) { return $result }
    if ($catalog.Count -ne 1) { throw "Ambiguous catalog solution name: $SolutionName. Select a verified package identity before deployment." }
    $result.CatalogEntry = $catalog[0]
    if ($catalog[0].properties.PSObject.Properties['version']) { $result.AvailableVersion = [string]$catalog[0].properties.version }
    $result.Action = 'Install'
    $result.Status = 'NotInstalled'
    if ($null -eq (Compare-ContentHubArtifactVersion $result.AvailableVersion $result.AvailableVersion)) {
        $result.Status = 'Unverified'
        $result.Action = 'None'
        $result.Presence = @{ State = 'Unverified'; Detail = 'Catalog version is unknown; no version can be selected safely.' }
        return $result
    }
    # A successful contentPackages inventory is authoritative for absence. Do not
    # make installation depend on our ability to interpret every ARM expression.
    if (-not $InstalledLookup.ContainsKey($SolutionName)) { return $result }
    if ($InstalledLookup.ContainsKey($SolutionName)) {
        $result.InstalledPackage = $InstalledLookup[$SolutionName]
        $properties = $result.InstalledPackage.properties
        foreach ($field in @('installedVersion', 'version')) {
            if ($properties.PSObject.Properties[$field] -and $properties.$field) {
                $result.InstalledVersion = [string]$properties.$field
                break
            }
        }
        $versionComparison = Compare-ContentHubArtifactVersion $result.InstalledVersion $result.AvailableVersion
        if ($null -eq $versionComparison) {
            $result.Status = 'Unverified'; $result.Action = 'None'
            $result.Presence = @{ State = 'Unverified'; Detail = 'Installed version is unknown; review it before upgrading or risking a downgrade.' }
            return $result
        } elseif ($versionComparison -ge 0) {
            # Product catalog is not an installation ledger. Its missing
            # isInstalled field must not force repeated package reinstallation.
            $result.Status = 'Installed'
            $result.Action = 'None'
        } else {
            $result.Status = 'UpdateAvailable'
            $result.Action = 'Update'
        }
    }
    if ($result.InstalledPackage) {
        $registeredId = Get-ContentHubField $result.InstalledPackage.properties 'contentId'
        $catalogId = Get-ContentHubField $result.CatalogEntry.properties 'contentId'
        if ($registeredId -and $catalogId -and $registeredId -ne $catalogId) {
            $result.Status = 'Unverified'; $result.Action = 'None'
            $result.Presence = @{ State = 'Unverified'; Detail = 'Package display-name collision with a different registered content ID.' }
            return $result
        }
    }
    # Older packages take the official incremental upgrade path. Presence checking
    # supplements only the latest-version skip; unsupported manifests are not absence.
    if ($result.Action -eq 'Update') { return $result }
    $result.Presence = Test-ContentHubPackagePresence $result.CatalogEntry
    if ($result.Presence.State -eq 'Unverified') {
        $result.Presence.State = 'NotFullyInspected'
        $result.Presence.Detail = "Registered version is current; no missing content was established. Detailed manifest inspection unavailable: $($result.Presence.Detail)"
    } elseif ($result.Presence.State -eq 'Missing') {
        if ((Compare-ContentHubArtifactVersion $result.InstalledVersion $result.AvailableVersion) -gt 0) {
            $result.Status = 'Unverified'; $result.Action = 'None'
            $result.Presence.State = 'Unverified'
            $result.Presence.Detail = 'The ledger is newer than this catalog manifest; do not repair using an older package.'
        } elseif ($result.Presence.RepairTemplate) {
            $result.Status = 'RepairRequired'; $result.Action = 'Update'
        } else {
            $result.Status = 'Unverified'; $result.Action = 'None'
            $result.Presence.Detail += ' Missing content needs manual repair because a safe selective repair could not be constructed.'
        }
    }
    return $result
}

function Compare-ContentHubArtifactVersion([string]$Installed, [string]$Expected) {
    # Sentinel explicitly supports numeric versions with one through four parts.
    # SemVer alone rejects the documented metadata version "1.0.0.0".
    if ($Installed -match '^\d+(\.\d+){0,3}$' -and $Expected -match '^\d+(\.\d+){0,3}$') {
        $left = $Installed -split '\.'; $right = $Expected -split '\.'
        for ($index = 0; $index -lt 4; $index++) {
            $a = if ($index -lt $left.Count) { [System.Numerics.BigInteger]::Parse($left[$index]) } else { [System.Numerics.BigInteger]::Zero }
            $b = if ($index -lt $right.Count) { [System.Numerics.BigInteger]::Parse($right[$index]) } else { [System.Numerics.BigInteger]::Zero }
            $comparison = $a.CompareTo($b)
            if ($comparison -ne 0) { return $comparison }
        }
        return 0
    }
    $versions = @()
    foreach ($text in @($Installed, $Expected)) {
        if ($text -match '^\d+(\.\d+)?$') { while (($text -split '\.').Count -lt 3) { $text += '.0' } }
        $version = $null
        if (-not [Management.Automation.SemanticVersion]::TryParse($text, [ref]$version)) { return $null }
        $versions += $version
    }
    return $versions[0].CompareTo($versions[1])
}

function Sort-ContentHubTemplates($Templates) {
    $sorted = [Collections.Generic.List[object]]::new()
    foreach ($template in $Templates) { $sorted.Add($template) }
    $comparer = [Collections.Generic.Comparer[object]]::Create([Comparison[object]]{
        param($Left, $Right)
        $leftVersion = [string](Get-ContentHubField $Left.properties 'version')
        $rightVersion = [string](Get-ContentHubField $Right.properties 'version')
        if ($null -eq (Compare-ContentHubArtifactVersion $leftVersion $leftVersion)) { $leftVersion = '0.0.0' }
        if ($null -eq (Compare-ContentHubArtifactVersion $rightVersion $rightVersion)) { $rightVersion = '0.0.0' }
        $comparison = Compare-ContentHubArtifactVersion $leftVersion $rightVersion
        if ($null -eq $comparison) {
            # Mixed four-part numeric and SemVer versions share a three-part base;
            # numeric revisions sort after that base's stable release.
            $leftRevision = [Numerics.BigInteger]::Zero
            $rightRevision = [Numerics.BigInteger]::Zero
            if ($leftVersion -match '^(\d+\.\d+\.\d+)\.(\d+)$') {
                $leftVersion = $Matches[1]; $leftRevision = [Numerics.BigInteger]::Parse($Matches[2])
            }
            if ($rightVersion -match '^(\d+\.\d+\.\d+)\.(\d+)$') {
                $rightVersion = $Matches[1]; $rightRevision = [Numerics.BigInteger]::Parse($Matches[2])
            }
            $comparison = Compare-ContentHubArtifactVersion $leftVersion $rightVersion
            if ($null -eq $comparison) { throw 'Template versions cannot be ordered safely; review the installed versions.' }
            if ($comparison -eq 0) { $comparison = $leftRevision.CompareTo($rightRevision) }
        }
        if ($comparison -ne 0) { return -$comparison }
        return [StringComparer]::OrdinalIgnoreCase.Compare([string]$Left.name, [string]$Right.name)
    })
    $sorted.Sort($comparer)
    return $sorted.ToArray()
}

function Confirm-ContentHubSelectedTarget {
    $expected = Get-Variable ContentHubExpectedTarget -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $expected) { throw 'The canonical selected Content Hub target was not supplied.' }
    $context = Get-AzContext -ErrorAction Stop
    $endpoint = ([string]$context.Environment.ResourceManagerUrl).TrimEnd('/')
    if ($script:SubscriptionId -ne $expected.SubscriptionId -or [string]$context.Subscription.Id -ne $expected.SubscriptionId -or
        [string]$context.Tenant.Id -ne $expected.TenantId -or $script:BaseUri.TrimEnd('/') -ne "$endpoint$($expected.WorkspaceResourceId)") {
        throw 'Content Hub initialization does not match the selected tenant/subscription/workspace.'
    }
    $resource = Invoke-SentinelApi -Uri "$script:BaseUri`?api-version=2022-10-01" -Method GET -Headers @{}
    if ($resource.id -ne $expected.WorkspaceResourceId) { throw 'Canonical workspace GET returned a different resource ID.' }
    if ($expected.CustomerId -and [string]$resource.properties.customerId -ne $expected.CustomerId) { throw 'Workspace was recreated or changed after selection. Select the target again; no cached installation evidence may be reused.' }
    $script:ContentHubPresenceInventory = @{}
    Write-Host "Content Hub target tenant: $($expected.TenantId); subscription: $($expected.SubscriptionId)" -ForegroundColor Cyan
    Write-Host "Canonical workspace: $($resource.id); customerId: $($resource.properties.customerId)" -ForegroundColor Cyan
}

function Write-ContentHubPackagePresenceReport($SolutionStatuses) {
    Write-PipelineMessage 'Content Hub solutions: installed version versus latest catalog version' -Level Section
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($status in $SolutionStatuses) {
        $label = switch ($status.Status) {
            Installed { 'Current' }
            NotInstalled { 'Not installed' }
            UpdateAvailable { 'Older' }
            RepairRequired { 'Content missing' }
            NotFound { 'Not in catalog' }
            default { 'Version/identity unknown' }
        }
        $action = switch ($status.Action) {
            'Install' { 'Install' }
            'Update' { if ($status.Status -eq 'RepairRequired') { 'Repair missing' } else { 'Upgrade' } }
            default { if ($status.Status -eq 'Unverified') { 'Review version' } else { 'Skip package' } }
        }
        $rows.Add([pscustomobject]@{
            Solution = $status.Name
            Installed = $(if ($status.InstalledVersion) { $status.InstalledVersion } else { '-' })
            Latest = $(if ($status.AvailableVersion) { $status.AvailableVersion } else { '-' })
            Status = $label
            Action = $action
        })
        if ($status.Presence) {
            Write-Verbose "$($status.Name): status=$($status.Status); action=$($status.Action); $($status.Presence.Detail)"
            if ($status.Status -eq 'Unverified') { Write-PipelineMessage "$($status.Name): $($status.Presence.Detail)" -Level Warning }
        }
    }
    $table = $rows | Format-Table @{ Name = 'Solution'; Expression = { $_.Solution }; Width = 46 },
        @{ Name = 'Installed version'; Expression = { $_.Installed }; Width = 17 },
        @{ Name = 'Latest version'; Expression = { $_.Latest }; Width = 15 },
        @{ Name = 'Status'; Expression = { $_.Status }; Width = 24 },
        @{ Name = 'Action'; Expression = { $_.Action }; Width = 15 } -Wrap |
        Out-String -Width 126
    Write-PipelineMessage $table.TrimEnd() -Level Info
    Write-PipelineMessage 'Installed = workspace contentPackages version. New/older solutions deploy their official ARM package, including inline nested deployments. Current packages skip installation; rules/workbooks still reconcile independently.' -Level Info
    Write-PipelineMessage 'Packaged Playbook templates are inert and permitted; runtime Playbooks and NRT rules remain excluded. Source licensing, consent and ingestion are separate from installation.' -Level Info
}

function Confirm-ContentHubPackageArtifacts($SolutionStatuses) {
    $script:ContentHubPresenceInventory = @{}
    $script:ContentHubPackageUnverified = @{}
    if ($WhatIf) { Write-PipelineMessage 'WhatIf: package installation/readback was not performed.' -Level Info; return }
    $ledger = Invoke-SentinelApi -Uri "$script:BaseUri/providers/Microsoft.SecurityInsights/contentPackages?api-version=$script:SentinelApiVersion" -Method GET -Headers @{}
    foreach ($status in $SolutionStatuses) {
        if ($status.Status -eq 'NotFound') { continue }
        if ($status.Status -eq 'Unverified' -or ($status.Action -ne 'None' -and $status.DeploymentSucceeded -ne $true)) {
            $script:ContentHubPackageUnverified[$status.Name] = 'Package version/identity is unknown or the ARM installation did not succeed.'
            $status.Presence = @{ State = 'Unverified'; Detail = $script:ContentHubPackageUnverified[$status.Name]; Missing = @(); Artifacts = @() }
            Save-ContentHubPackageDiagnostic $status.CatalogEntry $status.Presence $status.InstalledVersion
            continue
        }
        $packageId = [string](Get-ContentHubField $status.CatalogEntry.properties 'contentId')
        if (-not $packageId) { $packageId = [string]$status.CatalogEntry.name }
        $registered = $false
        for ($attempt = 0; $attempt -lt 3; $attempt++) {
            $matches = @($ledger.value | Where-Object {
                (Get-ContentHubField $_.properties 'contentId') -eq $packageId -or $_.name -eq $packageId
            })
            if ($matches.Count -eq 1) {
                $p = $matches[0].properties
                $version = Get-ContentHubField $p 'installedVersion'
                if (-not $version) { $version = Get-ContentHubField $p 'version' }
                $comparison = Compare-ContentHubArtifactVersion $version $status.AvailableVersion
                if ($null -ne $comparison -and $comparison -ge 0) { $registered = $true; break }
            }
            if ($status.Action -eq 'None' -or $attempt -eq 2) { break }
            Start-Sleep -Seconds 5
            $ledger = Invoke-SentinelApi -Uri "$script:BaseUri/providers/Microsoft.SecurityInsights/contentPackages?api-version=$script:SentinelApiVersion" -Method GET -Headers @{}
        }
        if (-not $registered) {
            $script:ContentHubPackageUnverified[$status.Name] = 'Expected installed package ID/version was not confirmed after deployment.'
            Save-ContentHubPackageDiagnostic $status.CatalogEntry @{ State = 'Missing'; Detail = $script:ContentHubPackageUnverified[$status.Name]; Missing = @('contentPackages: expected package ID/version was not returned'); Artifacts = @() } $status.InstalledVersion
            continue
        }
        $presence = Test-ContentHubPackagePresence $status.CatalogEntry
        if ($presence.State -eq 'Missing' -and $status.Action -ne 'None') {
            for ($attempt = 0; $attempt -lt 2 -and $presence.State -eq 'Missing'; $attempt++) {
                Start-Sleep -Seconds 5; $script:ContentHubPresenceInventory = @{}
                $presence = Test-ContentHubPackagePresence $status.CatalogEntry
            }
        }
        $status.Presence = $presence
        Save-ContentHubPackageDiagnostic $status.CatalogEntry $presence $version
        if ($presence.State -eq 'Missing') { $script:ContentHubPackageUnverified[$status.Name] = $presence.Detail }
        elseif ($presence.State -eq 'Unverified') {
            $presence.State = 'NotFullyInspected'
            Write-PipelineMessage "$($status.Name): installed package version verified$(if ($status.Action -ne 'None') { ' after successful ARM deployment' }); detailed local manifest inspection is partial. Runtime content checks follow." -Level Info
            Write-Verbose $presence.Detail
        } else { Write-PipelineMessage "$($status.Name): installed version and supported package artifact checks verified." -Level Info }
    }
}

function Resolve-ContentHubManifestValue($Value, $Template, [int]$Depth = 0, [switch]$Expression, [switch]$ScopeOnly) {
    if ($Depth -gt 24) { throw 'Cyclic or excessively nested manifest expression.' }
    if ($Value -isnot [string]) { return $Value }
    $text = $Value.Trim()
    if (-not $Expression) {
        if (-not $text.StartsWith('[')) { return $Value }
        if (-not $text.EndsWith(']')) { throw 'Invalid manifest expression.' }
        $text = $text.Substring(1, $text.Length - 2).Trim()
    }
    if ($text -match "^'((?:[^']|'')*)'$") { return $matches[1].Replace("''", "'") }
    if ($text -match "^variables\('([^']+)'\)((?:\.[A-Za-z0-9_]+)*)$") {
        $value = Get-ContentHubField (Get-ContentHubField $Template 'variables') $matches[1]
        foreach ($member in @($matches[2].TrimStart('.') -split '\.' | Where-Object { $_ })) { $value = Get-ContentHubField $value $member }
        if ($null -eq $value) { throw 'Unknown manifest variable/member.' }
        return Resolve-ContentHubManifestValue $value $Template ($Depth + 1) -ScopeOnly:$ScopeOnly
    }
    if ($text -match "^parameters\('(workspace|workspace-location)'\)$") {
        if ($matches[1] -eq 'workspace') { return $Workspace }
        return $Region
    }
    if ($text -notmatch '(?s)^(concat|resourceId|extensionResourceId|split|last|uniqueString)\((.*)\)$') { throw "Unsupported manifest identity expression: $text" }
    $operation = $matches[1]; $arguments = $matches[2]
    $parts = [Collections.Generic.List[string]]::new()
    $quoted = $false; $level = 0; $start = 0
    for ($i = 0; $i -lt $arguments.Length; $i++) {
        $char = $arguments[$i]
        if ($char -eq "'") {
            if ($quoted -and $i + 1 -lt $arguments.Length -and $arguments[$i + 1] -eq "'") { $i++; continue }
            $quoted = -not $quoted
        } elseif (-not $quoted) {
            if ($char -eq '(') { $level++ }
            elseif ($char -eq ')') { $level-- }
            elseif ($char -eq ',' -and $level -eq 0) { $parts.Add($arguments.Substring($start, $i - $start).Trim()); $start = $i + 1 }
        }
    }
    if ($quoted -or $level -ne 0) { throw 'Invalid manifest arguments.' }
    $parts.Add($arguments.Substring($start).Trim())
    $values = @(foreach ($part in $parts) {
        $resolved = Resolve-ContentHubManifestValue $part $Template ($Depth + 1) -Expression -ScopeOnly:$ScopeOnly
        ,$resolved
    })
    switch ($operation) {
        'concat' { return ($values -join '') }
        'split' { if ($values.Count -ne 2) { throw 'Invalid split arguments.' }; return ,([string]$values[0]).Split([string]$values[1]) }
        'last' { return @($values[0])[-1] }
        'uniqueString' {
            # Only establish the workspace prefix, never invent an ARM resource name.
            if (-not $ScopeOnly) { throw 'Dynamic resource identity requires review.' }
            return '__dynamic_suffix__'
        }
        'resourceId' {
            $types = ([string]$values[0]).Split('/')
            if ($types.Count -ne $values.Count -or $types[0] -notmatch '^Microsoft\.') { throw 'Unsupported resourceId overload.' }
            $id = "/subscriptions/$script:SubscriptionId/resourceGroups/$ResourceGroup/providers/$($types[0])"
            for ($i = 1; $i -lt $types.Count; $i++) { $id += "/$($types[$i])/$($values[$i])" }
            return $id
        }
        'extensionResourceId' {
            if ($values.Count -ne 3) { throw 'Unsupported extensionResourceId overload.' }
            return "$($values[0])/providers/$($values[1])/$($values[2])"
        }
    }
}

function Get-ContentHubPresenceInventory([string]$Collection) {
    if (-not (Get-Variable ContentHubPresenceInventory -Scope Script -ErrorAction SilentlyContinue)) { $script:ContentHubPresenceInventory = @{} }
    $key = "$($script:BaseUri)|$Collection"
    if (-not $script:ContentHubPresenceInventory.ContainsKey($key)) {
        $root = if ($Collection -eq 'savedSearches') { $script:BaseUri } else { "$script:BaseUri/providers/Microsoft.SecurityInsights" }
        $version = if ($Collection -eq 'savedSearches') { '2020-08-01' } else { $script:SentinelApiVersion }
        $uri = "$root/$Collection`?api-version=$version"
        if ($Collection -eq 'contentTemplates') { $uri += '&$expand=properties/mainTemplate' }
        $page = Invoke-SentinelApi -Uri $uri -Method GET -Headers @{}
        if (-not $page -or -not $page.PSObject.Properties['value'] -or $page.value -isnot [array]) { throw 'Incomplete package artifact inventory.' }
        foreach ($item in $page.value) {
            if (-not (Get-ContentHubField $item 'id') -or -not ([string]$item.id).StartsWith("$(([uri]$root).AbsolutePath)/$Collection/", [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Artifact inventory returned a resource outside the selected workspace/collection.'
            }
        }
        $script:ContentHubPresenceInventory[$key] = @($page.value)
    }
    return @($script:ContentHubPresenceInventory[$key])
}

function Get-ContentHubArtifactIdentity($Resource) {
    $p = Get-ContentHubField $Resource 'properties'
    [pscustomobject]@{
        ResourceId = [string](Get-ContentHubField $Resource 'id')
        ResourceName = [string](Get-ContentHubField $Resource 'name')
        ResourceKind = [string](Get-ContentHubField $Resource 'kind')
        ContentId = [string](Get-ContentHubField $p 'contentId')
        ContentProductId = [string](Get-ContentHubField $p 'contentProductId')
        PackageId = [string](Get-ContentHubField $p 'packageId')
        Kind = [string](Get-ContentHubField $p 'contentKind')
        MetadataKind = [string](Get-ContentHubField $p 'kind')
        Version = [string](Get-ContentHubField $p 'version')
        ParentId = [string](Get-ContentHubField $p 'parentId')
        SourceId = [string](Get-ContentHubField (Get-ContentHubField $p 'source') 'sourceId')
        HasMainTemplate = $null -ne (Get-ContentHubField $p 'mainTemplate')
    }
}

function Save-ContentHubPackageDiagnostic($CatalogEntry, $Presence, [string]$InstalledVersion = '') {
    if (-not (Get-Variable ContentHubPackageDiagnostics -Scope Script -ErrorAction SilentlyContinue)) { $script:ContentHubPackageDiagnostics = @{} }
    $key = [string]$CatalogEntry.name
    $script:ContentHubPackageDiagnostics[$key] = [pscustomobject]@{
        Solution = [string](Get-ContentHubField $CatalogEntry.properties 'displayName')
        PackageId = [string](Get-ContentHubField $CatalogEntry.properties 'contentId')
        WorkspaceResourceId = ([uri]$script:BaseUri).AbsolutePath
        InstalledVersion = $InstalledVersion
        CatalogVersion = [string](Get-ContentHubField $CatalogEntry.properties 'version')
        State = $Presence.State
        Detail = $Presence.Detail
        Expected = Get-ContentHubField $Presence 'Expected'
        Missing = @((Get-ContentHubField $Presence 'Missing') | Where-Object { $_ })
        Artifacts = @((Get-ContentHubField $Presence 'Artifacts') | Where-Object { $_ })
        CheckedAt = [DateTime]::UtcNow.ToString('o')
    }
}

function Read-ContentHubArtifact([string]$Id, [string]$Collection, [string]$ManifestApiVersion, $Evidence) {
    $workspaceId = ([uri]$script:BaseUri).AbsolutePath.TrimEnd('/')
    $root = if ($Collection -eq 'savedSearches') { $workspaceId } else { "$workspaceId/providers/Microsoft.SecurityInsights" }
    if (-not $Id.StartsWith("$root/$Collection/", [StringComparison]::OrdinalIgnoreCase) -or $Id -match '[?#]') { throw 'Artifact detail read is outside the selected workspace/collection.' }
    $version = if ($Collection -eq 'savedSearches') { '2020-08-01' } else { $script:SentinelApiVersion }
    # Packaged StaticUI connectors can reject the general Sentinel API even
    # though GET succeeds with the version declared by their ARM resource.
    $versions = @(if ($ManifestApiVersion -match '^\d{4}-\d{2}-\d{2}(-preview)?$') {
        $ManifestApiVersion
    } else { $version })
    if ($version -notin $versions) { $versions += $version }
    foreach ($api in $versions) {
        try {
            $body = Invoke-SentinelApi -Uri "$script:ServerUrl$Id`?api-version=$api" -Method GET -Headers @{} -AllowMissingContentArtifact
            $Evidence.Reads += [pscustomobject]@{ ResourceId = $Id; ApiVersion = $api; Result = $(if ($body) { 'Found' } else { 'HTTP404' }); HttpStatus = $(if ($body) { 200 } else { 404 }) }
            if ($body) {
                if ((Get-ContentHubField $body 'id') -ne $Id) { throw 'Artifact detail read returned a different resource identity.' }
                return $body
            }
        } catch {
            $Evidence.Outcome = 'ReadFailed'
            $Evidence.Reason = 'Detail GET failed; absence was not established. Check permissions, API support and the exact resource ID.'
            $Evidence.Reads += [pscustomobject]@{ ResourceId = $Id; ApiVersion = $api; Result = 'ReadFailed'; HttpStatus = $_.Exception.Data['ArmStatusCode'] }
            throw
        }
    }
    return $null
}

function ConvertTo-ContentHubSharedValue($Value, $Template, [switch]$Resolve, [int]$Depth = 0) {
    if ($Depth -gt 100) { throw 'Shared template comparison depth exceeded.' }
    if ($Value -is [string]) {
        if (-not $Resolve) { return $Value }
        # ARM evaluates the outer package once; doubled brackets are deferred
        # expressions in the inert template, not expressions to execute here.
        if ($Value.StartsWith('[[')) { return $Value.Substring(1) }
        if ($Value -match "^\[parameters\('(workbook\d+-name)'\)\]$") {
            $parameter = Get-ContentHubField (Get-ContentHubField $Template 'parameters') $matches[1]
            $default = Get-ContentHubField $parameter 'defaultValue'
            if ((Get-ContentHubField $parameter 'type') -ne 'string' -or $default -isnot [string] -or $default.StartsWith('[')) { throw 'Workbook name default is not a literal string.' }
            $Value = $default
        } else { $Value = Resolve-ContentHubManifestValue $Value $Template }
        if ($Value -is [string]) { return $Value }
    }
    if ($Value -is [Collections.IDictionary] -or $Value -is [pscustomobject]) {
        $keys = [string[]]@(if ($Value -is [Collections.IDictionary]) { @($Value.Keys) } else { $Value.PSObject.Properties | ForEach-Object Name })
        [Array]::Sort($keys, [StringComparer]::Ordinal)
        $copy = [ordered]@{}
        foreach ($key in $keys) { $copy[$key] = ConvertTo-ContentHubSharedValue (Get-ContentHubField $Value $key) $Template -Resolve:$Resolve -Depth ($Depth + 1) }
        return $copy
    }
    if ($Value -is [array]) {
        return ,@($Value | ForEach-Object { ConvertTo-ContentHubSharedValue $_ $Template -Resolve:$Resolve -Depth ($Depth + 1) })
    }
    return $Value
}

function Test-ContentHubSharedTemplate($Descriptor, $Template, $Registration, [string]$PackageId, $Related, $Evidence) {
    # Reviewed Azure/Azure-Sentinel Solutions/{SOC Handbook,SentinelSOARessentials,
    # Threat Intelligence (NEW),Threat Intelligence}/Package/mainTemplate.json:
    # these pairs declare the same workspace/content-derived template name.
    # Do not generalize this exception to arbitrary packages or display titles.
    $owner = ''
    if ($PackageId -eq 'microsoftsentinelcommunity.azure-sentinel-solution-sochandbook' -and
        $Descriptor.Kind -eq 'Workbook' -and $Descriptor.ContentId -eq 'SecurityOperationsEfficiency' -and $Descriptor.Version -ceq '1.5.2') {
        $owner = 'azuresentinel.azure-sentinel-solution-sentinelsoaressentials'
    } elseif ($PackageId -eq 'azuresentinel.azure-sentinel-solution-threatintelligence-updated' -and
        $Descriptor.Kind -eq 'DataConnector' -and $Descriptor.Version -ceq '1.0.0' -and
        $Descriptor.ContentId -in @('ThreatIntelligenceTaxii', 'ThreatIntelligence', 'ThreatIntelligenceUploadIndicatorsAPI', 'MicrosoftDefenderThreatIntelligence')) {
        $owner = 'azuresentinel.azure-sentinel-solution-threatintelligence-taxii'
    }
    $Evidence.Outcome = 'IdentityConflict'
    $Evidence.Reason = 'A different package owns related content; no supported shared equivalence was established. Preserve it for review, not reinstallation.'
    if (-not $owner) { return }
    $declared = @()
    try {
        foreach ($registrationResource in $Registration) {
            $dependencies = Get-ContentHubField $registrationResource.properties 'dependencies'
            if ((Get-ContentHubField $dependencies 'operator') -ne 'AND') { continue }
            $declared += @(Get-ContentHubField $dependencies 'criteria' | Where-Object {
                (Resolve-ContentHubManifestValue (Get-ContentHubField $_ 'contentId') $Template) -eq $Descriptor.ContentId -and
                (Resolve-ContentHubManifestValue (Get-ContentHubField $_ 'kind') $Template) -eq $Descriptor.Kind -and
                (Resolve-ContentHubManifestValue (Get-ContentHubField $_ 'version') $Template) -ceq $Descriptor.Version
            })
        }
    } catch {
        $Evidence.Outcome = 'Unverifiable'; $Evidence.Reason = 'Shared dependency declaration could not be resolved.'
        return
    }
    if (-not $declared.Count) { return }
    $candidates = @($Related | Where-Object {
        (Get-ContentHubField $_.properties 'packageId') -eq $owner -and
        (Get-ContentHubField $_.properties 'contentId') -eq $Descriptor.ContentId -and
        (Get-ContentHubField $_.properties 'contentKind') -eq $Descriptor.Kind -and
        ((Get-ContentHubField $_.properties 'version') -ceq $Descriptor.Version -or -not (Get-ContentHubField $_.properties 'version'))
    })
    if ($candidates.Count -ne 1) { return }
    $candidate = $candidates[0]
    if (-not (Get-ContentHubField $candidate.properties 'mainTemplate') -or -not (Get-ContentHubField $candidate.properties 'version')) {
        $candidate = Read-ContentHubArtifact ([string]$candidate.id) 'contentTemplates' $Evidence.ManifestApiVersion $Evidence
        if (-not $candidate) {
            $Evidence.Outcome = 'Unverifiable'; $Evidence.Reason = 'Shared candidate detail is unavailable; do not infer absence from a stale collection.'
            return
        }
    }
    $Evidence.Observed = @(Get-ContentHubArtifactIdentity $candidate)
    $p = $candidate.properties
    if ((Get-ContentHubField $p 'packageId') -ne $owner -or (Get-ContentHubField $p 'contentId') -ne $Descriptor.ContentId -or
        (Get-ContentHubField $p 'contentKind') -ne $Descriptor.Kind -or (Get-ContentHubField $p 'version') -cne $Descriptor.Version) { return }
    $equivalence = 'equivalent inert template payload'
    try {
        $expected = ConvertTo-ContentHubSharedValue (Get-ContentHubField $Descriptor.Resource.properties 'mainTemplate') $Template -Resolve
        $actual = ConvertTo-ContentHubSharedValue (Get-ContentHubField $p 'mainTemplate') $null
        if (-not $expected -or -not $actual -or -not $expected['resources'] -or -not $actual['resources']) {
            $Evidence.Outcome = 'Unverifiable'; $Evidence.Reason = 'Shared template payload is unavailable or empty; equivalence is unproved.'
            return
        }
        foreach ($body in @($expected, $actual)) {
            $metadata = @($body['resources'] | Where-Object { $_['type'] -eq 'Microsoft.OperationalInsights/workspaces/providers/metadata' })
            if ($metadata.Count -ne 1) { throw 'Shared template metadata contract is unsupported.' }
            $m = $metadata[0]['properties']
            $expectedOwner = if ([object]::ReferenceEquals($body, $expected)) { $PackageId } else { $owner }
            if ($m['contentId'] -ne $Descriptor.ContentId -or $m['kind'] -ne $Descriptor.Kind -or
                $m['version'] -cne $Descriptor.Version -or $m['source']['kind'] -ne 'Solution' -or $m['source']['sourceId'] -ne $expectedOwner) {
                $Evidence.Reason = 'Shared template nested metadata identity/provenance conflicts with the declared dependency.'
                return
            }
            # Only package-attribution fields differ in the supported shared
            # contract. Keep parent, content identity, dependencies and all payload.
            foreach ($field in @('source', 'author', 'support', 'description')) { $m.Remove($field) }
        }
        if ((ConvertTo-Json $expected -Depth 100 -Compress) -cne (ConvertTo-Json $actual -Depth 100 -Compress)) {
            # Published packages reuse canonical identities even where their
            # same-version bodies differ. Accept only these reviewed payload
            # pairs, not a generic foreign-owner or same-name exception.
            # SOC 3.0.6: bd1ac187b9ca3f0e858f4310a22a5899858b3316
            # Other packages: 08eb9e62835b6fe87e0e6b33a4f68f445f77cca0
            # Both refs are in Azure/Azure-Sentinel; paths are listed above.
            $publishedPairs = @{
                SecurityOperationsEfficiency = @('049FECADCC43D40088848C76D62A760223EF0E4965AA3425A928469D936018A1', '585A9ED1438224C4A70BC29556C78B6E3B3C6CD84A721F8391C4A9FBF9C55B6B')
                ThreatIntelligenceTaxii = @('7758F6B851F7100C3CC42744EDF17997CF3A887E77C772A5DE1D89433F6F2175', '917493EB1CB737E114B002E0A8E3BA1F76872B8552BFB3E105F0910EF74AFCB7')
                ThreatIntelligence = @('2361A5B8B6B05177B904D89B62F6346F8F5D0B66EEAF4F95BD92C6250F6F5D94', '30260BB21FA4026BC22671B99CB624FD7E52AAD329908616331134E1E2F95235')
                ThreatIntelligenceUploadIndicatorsAPI = @('1E3F87C65B95B9B097CA1F1FDF32695A2BB2DD2F844658C6CA74AF5927B4B690', '2B6323648408FDAC893F2178C4AB4822FAB4A70B79107E94008F6E16B5592A78')
                MicrosoftDefenderThreatIntelligence = @('73223F80C3EB0E7D765742C0FE7DBEE99FE6828CBF3D8B67C888C4A192820AFF', 'A96B44C1A0DC97945424F691E2AF576019823ED7C4196578D3C444692D8DF6D4')
            }
            $field = if ($Descriptor.Kind -eq 'Workbook') { 'serializedData' } else { 'connectorUiConfig' }
            $bodies = @($expected, $actual)
            $hashes = @()
            for ($index = 0; $index -lt 2; $index++) {
                $payload = $bodies[$index]['resources'][0]['properties'][$field]
                $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $payload -Depth 100 -Compress))
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') } finally { $sha.Dispose() }
                if ($hash -cne $publishedPairs[$Descriptor.ContentId][$index]) {
                    $Evidence.Reason = 'Shared payload is neither equivalent nor an exact reviewed published variant; preserve for review.'
                    return
                }
                $hashes += $hash
                $bodies[$index]['resources'][0]['properties'].Remove($field)
            }
            if ((ConvertTo-Json $expected -Depth 100 -Compress) -cne (ConvertTo-Json $actual -Depth 100 -Compress)) {
                $Evidence.Reason = 'Shared template envelope differs beyond reviewed attribution/payload variants; preserve for review.'
                return
            }
            $equivalence = "reviewed canonical shared artifact with different published payload variants (expected SHA256=$($hashes[0]); owner SHA256=$($hashes[1])); remaining template envelope equivalent"
        }
    } catch {
        $Evidence.Outcome = 'Unverifiable'; $Evidence.Reason = 'Shared template expressions/schema could not be compared safely; no repair is authorized.'
        return
    }
    $Evidence.Outcome = 'SharedPresent'
    $Evidence.Reason = "Exact declared contentId/kind/version; $equivalence; reviewed shared owner $owner. Nested Solution provenance verified. Runtime configuration/ingestion is not proved."
}

function Test-ContentHubPackagePresence($CatalogEntry, $InlineTemplate = $null, [int]$Depth = 0) {
    $uri = "$script:BaseUri/providers/Microsoft.SecurityInsights/contentProductPackages/$([uri]::EscapeDataString($CatalogEntry.name))?api-version=$script:SentinelApiVersion"
    $result = @{ State = 'Unverified'; Detail = 'No readable owned-artifact manifest; package registration alone is not installation proof.'; Expected = 0; Missing = @(); RepairTemplate = $null; Artifacts = @() }
    # Read failures escape, rather than becoming absence or permission to deploy.
    if ($null -eq $InlineTemplate) {
        try { $detail = Invoke-SentinelApi -Uri $uri -Method GET -Headers @{} }
        catch {
            $result.State = 'ReadFailed'; $result.Detail = "Product manifest GET failed: $(([uri]$uri).AbsolutePath). No absence or installation completeness was inferred."
            Save-ContentHubPackageDiagnostic $CatalogEntry $result
            throw
        }
        $template = Get-ContentHubField (Get-ContentHubField $detail 'properties') 'packagedContent'
    } else { $template = $InlineTemplate }
    if ($Depth -gt 16) { $result.Detail = 'Nested manifest inspection depth exceeded.'; return $result }
    if (-not $template -or -not $template.PSObject.Properties['resources'] -or $template.resources -isnot [array]) { return $result }
    $nested = @($template.resources | Where-Object { (Get-ContentHubField $_ 'type') -eq 'Microsoft.Resources/deployments' })
    if ($nested.Count) {
        # Inline deployments are normal Content Hub packaging, not missing content
        # or a reason to prevent ARM installing/upgrading the official package.
        $outer = $template | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
        $outer.resources = @($outer.resources | Where-Object type -ne 'Microsoft.Resources/deployments')
        $parts = [Collections.Generic.List[object]]::new()
        $parts.Add((Test-ContentHubPackagePresence $CatalogEntry $outer ($Depth + 1)))
        $repairResources = [Collections.Generic.List[object]]::new()
        if ($parts[0].RepairTemplate) { foreach ($r in $parts[0].RepairTemplate.resources) { $repairResources.Add($r) } }
        foreach ($deployment in $nested) {
            $p = $deployment.properties
            if ((Get-ContentHubField $p 'templateLink') -or (Get-ContentHubField $deployment 'copy') -or
                $null -ne (Get-ContentHubField $deployment 'condition') -or
                (Get-ContentHubField $deployment 'subscriptionId') -or (Get-ContentHubField $deployment 'resourceGroup') -or
                (Get-ContentHubField $deployment 'scope')) {
                $parts.Add(@{ State = 'Unverified'; Expected = 0; Missing = @(); Detail = 'Nested deployment uses a scoped, linked or conditional manifest; ARM deployment is verified separately.'; RepairTemplate = $null })
                continue
            }
            $childTemplate = Get-ContentHubField $p 'template'
            if (-not $childTemplate -or $childTemplate -is [string]) {
                $parts.Add(@{ State = 'Unverified'; Expected = 0; Missing = @(); Detail = 'Inline template is unavailable for local inspection.'; RepairTemplate = $null })
                continue
            }
            $child = Test-ContentHubPackagePresence $CatalogEntry $childTemplate ($Depth + 1)
            $parts.Add($child)
            if ($child.RepairTemplate) {
                $repairDeployment = $deployment | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
                $repairDeployment.properties.template = $child.RepairTemplate
                $repairResources.Add($repairDeployment)
            }
        }
        $result.Expected = ($parts | Measure-Object Expected -Sum).Sum
        $result.Missing = @($parts | ForEach-Object { $_.Missing })
        $result.Artifacts = @($parts | ForEach-Object { Get-ContentHubField $_ 'Artifacts' })
        $result.State = if ($result.Missing.Count) { 'Missing' } elseif (@($parts | Where-Object State -eq 'Unverified').Count) { 'Unverified' } else { 'Verified' }
        $result.Detail = "Inline deployment inspection: $($result.Expected) expected artifacts; $($result.Missing.Count) missing/outdated. " +
            (@($result.Missing | Select-Object -First 3) -join '; ') + ' ' +
            (@($parts | Where-Object State -eq 'Unverified' | ForEach-Object Detail) -join '; ')
        if (@($parts | Where-Object { -not $_.RepairTemplate }).Count -eq 0) {
            $repair = $template | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
            $repair.resources = @($repairResources)
            $result.RepairTemplate = $repair
        }
        Save-ContentHubPackageDiagnostic $CatalogEntry $result
        return $result
    }
    $packageId = [string](Get-ContentHubField $CatalogEntry.properties 'contentId')
    if (-not $packageId) { $packageId = [string]$CatalogEntry.name }
    $workspaceId = ([uri]$script:BaseUri).AbsolutePath.TrimEnd('/')
    $descriptors = [Collections.Generic.List[object]]::new()
    $registration = @()
    try {
        foreach ($resource in $template.resources) {
            if ((Get-ContentHubField $resource 'condition') -eq $false) { continue }
            if ($null -ne (Get-ContentHubField $resource 'condition') -or (Get-ContentHubField $resource 'copy')) { throw 'Conditional/copied package resources require review.' }
            $type = [string](Get-ContentHubField $resource 'type')
            $collection = ($type -split '/')[-1]
            if ($collection -notin @('contentTemplates', 'contentPackages', 'metadata', 'dataConnectors', 'dataConnectorDefinitions', 'savedSearches')) {
                throw "Package artifact contract not verified: $type. No forced reinstallation."
            }
            $scopeName = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $resource 'name') $template -ScopeOnly)
            if ($type -like 'Microsoft.OperationalInsights/workspaces/providers/*') {
                if (-not $scopeName.StartsWith("$Workspace/Microsoft.SecurityInsights/", [StringComparison]::OrdinalIgnoreCase)) { throw 'Package resource targets a different workspace.' }
            } elseif ($type -eq 'Microsoft.OperationalInsights/workspaces/savedSearches') {
                if (-not $scopeName.StartsWith("$Workspace/", [StringComparison]::OrdinalIgnoreCase)) { throw 'Saved search targets a different workspace.' }
            } elseif ($type -like 'Microsoft.SecurityInsights/*') {
                if ((Resolve-ContentHubManifestValue (Get-ContentHubField $resource 'scope') $template) -ne $workspaceId) { throw 'Extension resource workspace scope is unverified.' }
            } else { throw 'Unexpected package resource type.' }
            if ($collection -eq 'contentPackages') {
                $registrationId = Resolve-ContentHubManifestValue (Get-ContentHubField $resource.properties 'contentId') $template
                if ($registrationId -ne $packageId) { throw 'Manifest registration belongs to a different package.' }
                $registration += $resource
                continue
            }
            $properties = Get-ContentHubField $resource 'properties'
            $descriptor = @{ Resource = $resource; Collection = $collection; Id = ''; ReadId = ''; ParentId = ''; ContentId = ''; Kind = ''; Version = ''; Missing = $false }
            if ($collection -in @('contentTemplates', 'metadata')) {
                $descriptor.ContentId = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $properties 'contentId') $template)
                $kindField = if ($collection -eq 'metadata') { 'kind' } else { 'contentKind' }
                $descriptor.Kind = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $properties $kindField) $template)
                $descriptor.Version = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $properties 'version') $template)
                $owner = if ($collection -eq 'metadata') { Get-ContentHubField (Get-ContentHubField $properties 'source') 'sourceId' } else { Get-ContentHubField $properties 'packageId' }
                if ((Resolve-ContentHubManifestValue $owner $template) -ne $packageId -or -not $descriptor.ContentId -or -not $descriptor.Kind) { throw 'Package artifact ownership/identity is unverified.' }
                if ($collection -eq 'metadata') {
                    $leaf = ([string](Resolve-ContentHubManifestValue $resource.name $template) -split '/')[-1]
                    $descriptor.ReadId = "$workspaceId/providers/Microsoft.SecurityInsights/metadata/$leaf"
                    $descriptor.ParentId = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $properties 'parentId') $template)
                }
            } else {
                $resolvedName = [string](Resolve-ContentHubManifestValue (Get-ContentHubField $resource 'name') $template)
                $leaf = ($resolvedName -split '/')[-1]
                if (-not $leaf) { throw 'Empty package artifact identity.' }
                $root = if ($collection -eq 'savedSearches') { $workspaceId } else { "$workspaceId/providers/Microsoft.SecurityInsights" }
                $descriptor.Id = "$root/$collection/$leaf"
                $descriptor.ReadId = $descriptor.Id
            }
            $descriptors.Add($descriptor)
        }
    } catch {
        $result.Detail = "Manifest requires review: $($_.Exception.Message)"
        return $result
    }
    $result.Expected = $descriptors.Count
    $existingIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($descriptor in $descriptors) {
        $evidence = [ordered]@{
            Collection = $descriptor.Collection; ExpectedResourceId = $descriptor.ReadId
            ExpectedContentId = $descriptor.ContentId; ExpectedKind = $descriptor.Kind
            ExpectedVersion = $descriptor.Version; ExpectedPackageId = $packageId
            ExpectedParentId = $descriptor.ParentId; ManifestApiVersion = [string](Get-ContentHubField $descriptor.Resource 'apiVersion')
            Role = $(if ($descriptor.Collection -eq 'contentTemplates') { 'Inert packaged template (required even when runtime NRT/Playbook is excluded)' } else { 'Declared packaged artifact' })
            Outcome = 'Present'; Reason = ''; Observed = @(); Reads = @()
        }
        $result.Artifacts += [pscustomobject]$evidence
        $evidence = $result.Artifacts[-1]
        try { $inventory = @(Get-ContentHubPresenceInventory $descriptor.Collection) }
        catch {
            $evidence.Outcome = 'ReadFailed'; $evidence.Reason = 'Collection read failed; missing content cannot be inferred.'
            $result.Detail = "$($descriptor.Collection) inventory failed."
            Save-ContentHubPackageDiagnostic $CatalogEntry $result
            throw
        }
        foreach ($item in $inventory) { [void]$existingIds.Add([string]$item.id) }
        $related = @($inventory | Where-Object {
            ($descriptor.ReadId -and $_.id -eq $descriptor.ReadId) -or
            ($descriptor.ContentId -and (Get-ContentHubField $_.properties 'contentId') -eq $descriptor.ContentId)
        })
        $evidence.Observed = @($related | Select-Object -First 5 | ForEach-Object { Get-ContentHubArtifactIdentity $_ })
        $matching = @($inventory | Where-Object {
            if ($descriptor.Id) { return $_.id -eq $descriptor.Id }
            $p = $_.properties
            $owner = if ($descriptor.Collection -eq 'metadata') { Get-ContentHubField (Get-ContentHubField $p 'source') 'sourceId' } else { Get-ContentHubField $p 'packageId' }
            $kind = if ($descriptor.Collection -eq 'metadata') { Get-ContentHubField $p 'kind' } else { Get-ContentHubField $p 'contentKind' }
            if ($descriptor.Collection -eq 'metadata' -and $descriptor.ParentId) {
                return (Get-ContentHubField $p 'parentId') -eq $descriptor.ParentId -and
                    $kind -eq $descriptor.Kind -and (Get-ContentHubField $p 'contentId') -eq $descriptor.ContentId
            }
            $owner -eq $packageId -and $kind -eq $descriptor.Kind -and (Get-ContentHubField $p 'contentId') -eq $descriptor.ContentId
        })
        if (-not $matching.Count -and $descriptor.Collection -eq 'contentTemplates' -and $related.Count) {
            try { Test-ContentHubSharedTemplate $descriptor $template $registration $packageId $related $evidence }
            catch { Save-ContentHubPackageDiagnostic $CatalogEntry $result; throw }
            continue
        }
        if ($matching.Count -gt 1) {
            if ($descriptor.Collection -ne 'contentTemplates') { $result.Detail = "Ambiguous installed artifact: $($descriptor.Collection)/$($descriptor.ContentId)."; return $result }
            # Content Hub retains inert template versions side by side; any intact
            # owned version at least as new as the manifest satisfies presence.
            $usable = @($matching | Where-Object {
                $comparison = Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $_.properties 'version')) $descriptor.Version
                $body = Get-ContentHubField $_.properties 'mainTemplate'
                $expectedBody = Get-ContentHubField $descriptor.Resource.properties 'mainTemplate'
                $null -ne $comparison -and $comparison -ge 0 -and
                    (-not $expectedBody -or ($body -and (-not (Get-ContentHubField $expectedBody 'resources') -or (Get-ContentHubField $body 'resources'))))
            })
            if (-not $usable.Count) {
                $resolved = [Collections.Generic.List[object]]::new()
                foreach ($candidate in $matching) {
                    $comparison = Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $candidate.properties 'version')) $descriptor.Version
                    $expectedBody = Get-ContentHubField $descriptor.Resource.properties 'mainTemplate'
                    if ($null -eq $comparison -or ($comparison -ge 0 -and $expectedBody -and -not (Get-ContentHubField $candidate.properties 'mainTemplate'))) {
                        try { $candidate = Read-ContentHubArtifact ([string]$candidate.id) $descriptor.Collection $evidence.ManifestApiVersion $evidence }
                        catch { Save-ContentHubPackageDiagnostic $CatalogEntry $result; throw }
                    }
                    if ($candidate) { $resolved.Add($candidate) }
                }
                $matching = @($resolved)
                $evidence.Observed = @($matching | Select-Object -First 5 | ForEach-Object { Get-ContentHubArtifactIdentity $_ })
                $usable = @($matching | Where-Object {
                    $comparison = Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $_.properties 'version')) $descriptor.Version
                    $body = Get-ContentHubField $_.properties 'mainTemplate'
                    $null -ne $comparison -and $comparison -ge 0 -and
                        (-not $expectedBody -or ($body -and (-not (Get-ContentHubField $expectedBody 'resources') -or (Get-ContentHubField $body 'resources'))))
                })
                $uncertain = @($matching | Where-Object {
                    $comparison = Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $_.properties 'version')) $descriptor.Version
                    $null -eq $comparison -or ($comparison -ge 0 -and $expectedBody -and -not (Get-ContentHubField $_.properties 'mainTemplate'))
                })
                if (-not $usable.Count -and $uncertain.Count) {
                    $evidence.Outcome = 'Unverifiable'; $evidence.Reason = 'Retained template versions have incomplete detail projections; none can establish absence/outdated content.'
                    continue
                }
            }
            # Never let an older retained version win solely because it appeared
            # first in a projected list response.
            $matching = @(if ($usable.Count) { $usable[0] } elseif ($matching.Count) {
                $newest = $matching[0]
                foreach ($candidate in $matching) {
                    if ((Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $candidate.properties 'version')) ([string](Get-ContentHubField $newest.properties 'version'))) -gt 0) { $newest = $candidate }
                }
                $newest
            })
        }
        $descriptor.Missing = $matching.Count -eq 0
        # List responses are projections. A missing source/mainTemplate/version
        # field is not proof of a missing resource. GET the actual ARM resource
        # name, never contentId as a guessed contentTemplates resource name.
        $readId = ''
        if ($matching.Count -eq 0 -and $descriptor.ReadId) { $readId = $descriptor.ReadId }
        elseif ($matching.Count -eq 1) {
            $p = $matching[0].properties
            if (($descriptor.Version -and -not (Get-ContentHubField $p 'version')) -or
                ($descriptor.Collection -eq 'contentTemplates' -and (Get-ContentHubField $descriptor.Resource.properties 'mainTemplate') -and -not (Get-ContentHubField $p 'mainTemplate')) -or
                ($descriptor.Collection -eq 'metadata' -and $descriptor.ParentId -and -not (Get-ContentHubField $p 'parentId'))) {
                $readId = [string]$matching[0].id
            }
        }
        if ($readId) {
            try { $readback = Read-ContentHubArtifact $readId $descriptor.Collection $evidence.ManifestApiVersion $evidence }
            catch { Save-ContentHubPackageDiagnostic $CatalogEntry $result; throw }
            if ($readback) {
                $matching = @($readback)
                $evidence.Observed = @(Get-ContentHubArtifactIdentity $readback)
                [void]$existingIds.Add([string]$readback.id)
                $descriptor.Missing = $false
                $evidence.Reason = 'Exact resource GET established presence; list projection was not absence.'
            } else {
                $matching = @(); $descriptor.Missing = $true
                $evidence.Reason = 'Exact resource GET returned 404 with both current and manifest API versions (when different).'
            }
        }
        if ($matching.Count -eq 1 -and $descriptor.Collection -eq 'metadata' -and $descriptor.ParentId) {
            $p = $matching[0].properties
            $actualParent = [string](Get-ContentHubField $p 'parentId')
            if ($actualParent -and ($actualParent -ne $descriptor.ParentId -or
                (Get-ContentHubField $p 'contentId') -ne $descriptor.ContentId -or
                (Get-ContentHubField $p 'kind') -ne $descriptor.Kind)) {
                $evidence.Outcome = 'IdentityConflict'; $evidence.Reason = 'Existing metadata has a different parent/content identity; preserved, not repaired.'
                $result.Missing += "$($descriptor.ReadId): metadata identity conflict"
                continue
            }
            if (-not $actualParent) {
                $evidence.Outcome = 'Unverifiable'; $evidence.Reason = 'Metadata parentId is unavailable even after detail GET; no missing-resource or repair claim.'
                continue
            }
            # source.sourceId is optional provenance, not an ARM resource key.
            # Exact metadata ID + parentId + contentId + kind establish identity.
            if ((Get-ContentHubField (Get-ContentHubField $p 'source') 'sourceId') -ne $packageId) {
                $evidence.Reason = 'Exact metadata/parent/content identity matched; optional source provenance differs or is absent and is preserved.'
            }
        }
        if ($matching.Count -eq 1 -and $descriptor.Version) {
            $comparison = Compare-ContentHubArtifactVersion ([string](Get-ContentHubField $matching[0].properties 'version')) $descriptor.Version
            if ($null -eq $comparison) {
                $evidence.Outcome = 'Unverifiable'; $evidence.Reason = 'Resource exists but its version cannot be compared; not evidence of absence.'
                continue
            }
            $descriptor.Missing = $comparison -lt 0
            if ($descriptor.Missing) { $evidence.Outcome = 'Outdated'; $evidence.Reason = 'Observed resource version is older than the manifest artifact version (not packageVersion/contentSchemaVersion).' }
            if ($descriptor.Missing -and $descriptor.Collection -eq 'metadata') {
                $actualSource = Get-ContentHubField (Get-ContentHubField $matching[0].properties 'source') 'sourceId'
                if ($actualSource -and $actualSource -ne $packageId) {
                    $descriptor.Missing = $false
                    $evidence.Outcome = 'IdentityConflict'; $evidence.Reason = 'Metadata version is older but source provenance changed; manual review required before any overwrite.'
                    $result.Missing += "$($descriptor.ReadId): older metadata with changed source provenance"
                    continue
                }
            }
        }
        if ($matching.Count -eq 1 -and $descriptor.Collection -eq 'contentTemplates') {
            $expectedBody = Get-ContentHubField $descriptor.Resource.properties 'mainTemplate'
            if ($expectedBody) {
                $actualBody = Get-ContentHubField $matching[0].properties 'mainTemplate'
                if (-not $actualBody) {
                    $evidence.Outcome = 'Unverifiable'; $evidence.Reason = 'Template identity exists but mainTemplate is unavailable after detail GET. Projection is not proof that the stored template is missing.'
                    continue
                }
                elseif ((Get-ContentHubField $expectedBody 'resources') -and -not (Get-ContentHubField $actualBody 'resources')) {
                    $descriptor.Missing = $true
                    $evidence.Outcome = 'Missing'; $evidence.Reason = 'Stored template body explicitly contains none of the expected resources.'
                }
            }
        }
        if ($descriptor.Missing) {
            if ($evidence.Outcome -eq 'Present') {
                $evidence.Outcome = 'Missing'
                if (-not $evidence.Reason) { $evidence.Reason = $(if ($matching.Count) { 'Explicit template body contains none of the expected resources.' } else { 'Complete scoped collection contained no matching package/kind/content identity.' }) }
            }
            $result.Missing += "$($descriptor.Collection)/$(if ($descriptor.ReadId) { $descriptor.ReadId } else { $descriptor.ContentId }) v$($descriptor.Version): $($evidence.Reason)"
        }
    }
    if (-not $result.Missing.Count) {
        $sharedCount = @($result.Artifacts | Where-Object Outcome -eq 'SharedPresent').Count
        $result.State = 'Verified'; $result.Detail = "Verified $($result.Expected) manifest artifacts; $sharedCount SharedPresent (not runtime rule/workbook or ingestion readiness)."
    } else {
        $result.State = 'Missing'; $result.Detail = "Missing/outdated manifest artifacts: $($result.Missing -join '; ')"
    }
    if (@($result.Artifacts | Where-Object Outcome -in @('Unverifiable', 'IdentityConflict')).Count) {
        if (-not $result.Missing.Count) { $result.State = 'Unverified'; $result.Detail = 'Some existing artifact fields could not be verified; see exact artifact evidence.' }
        Save-ContentHubPackageDiagnostic $CatalogEntry $result
        return $result # Never construct a repair for uncertain ownership/version.
    }
    try {
        # Repair only absent/outdated owned artifacts and the registration. Existing
        # connector selections, parsers and saved searches are never replayed here.
        $repair = $template | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
        $selected = @($descriptors | Where-Object Missing | ForEach-Object Resource) + @($registration)
        $newIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        [void]$existingIds.Add($workspaceId)
        foreach ($resource in $selected) {
            $collection = ([string]$resource.type -split '/')[-1]
            try { $leaf = ([string](Resolve-ContentHubManifestValue $resource.name $template) -split '/')[-1] }
            catch { continue } # Dynamic names cannot authorize a dependency guess.
            $root = if ($collection -eq 'savedSearches') { $workspaceId } else { "$workspaceId/providers/Microsoft.SecurityInsights" }
            [void]$newIds.Add("$root/$collection/$leaf")
        }
        $repair.resources = @(foreach ($resource in $selected) {
            if ($resource.PSObject.Properties['dependsOn']) {
                $dependencies = @($resource.dependsOn | Where-Object {
                    $id = Resolve-ContentHubManifestValue $_ $template
                    if ($existingIds.Contains([string]$id)) { return $false }
                    if (-not $newIds.Contains([string]$id)) { throw 'Package dependency is neither verified present nor included with an exact resource identity in this repair.' }
                    return $true
                })
                $resource = $resource.PSObject.Copy()
                $resource.dependsOn = $dependencies
            }
            # Serialization below makes the repair independent of the original manifest.
            $resource
        })
        $result.RepairTemplate = $repair
    } catch {
        $result.Detail = "Missing/outdated artifacts: $($result.Missing.Count). Safe repair dependencies could not be established: $($_.Exception.Message)"
    }
    Save-ContentHubPackageDiagnostic $CatalogEntry $result
    return $result
}

function Get-ContentHubStableId([string]$Kind, [string]$ContentId) {
    $key = "$(([uri]$script:BaseUri).AbsolutePath.TrimEnd('/'))|$Kind|$ContentId".ToLowerInvariant()
    $hash = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($key))
    return ([guid]::new([byte[]]$hash[0..15])).ToString()
}

function Get-ContentHubField($Object, [string]$Name, $Default = $null, [switch]$NoEnumerate) {
    $value = $Default
    if ($null -ne $Object) {
        if ($Object -is [Collections.IDictionary]) {
            if ($Object.Contains($Name)) { $value = $Object[$Name] }
        } elseif ($Object.PSObject.Properties[$Name]) {
            $value = $Object.PSObject.Properties[$Name].Value
        }
    }
    if ($NoEnumerate) { return ,$value }
    return $value
}

function Get-ContentHubSavedWorkbooks {
    $items = @{}
    foreach ($category in @('sentinel', 'workbook')) {
        $uri = "$($script:ServerUrl)/subscriptions/$($script:SubscriptionId)/providers/Microsoft.Insights/workbooks?api-version=2022-04-01&category=$category"
        $result = Invoke-SentinelApi -Uri $uri -Method GET -Headers @{}
        if (-not $result -or -not $result.PSObject.Properties['value']) { throw 'Saved workbook inventory was incomplete; refusing to infer absence.' }
        foreach ($item in $result.value) {
            if (-not (Get-ContentHubField $item 'id')) { throw 'Saved workbook inventory contains a resource without an ID.' }
            $items[[string]$item.id] = $item
        }
    }
    return @($items.Values)
}

function Test-ContentHubRuleCollision($Rules, [string]$TemplateName, [string]$DisplayName, [string]$Kind) {
    if (-not $TemplateName -or $TemplateName.StartsWith('[')) { return 'Missing or unevaluated template identity.' }
    $stableId = Get-ContentHubStableId 'AnalyticsRule' $TemplateName
    $matches = @($Rules | Where-Object {
        if ($null -eq $_) { return $false }
        (Get-ContentHubField $_.properties 'alertRuleTemplateName') -eq $TemplateName -or
        ($DisplayName -and (Get-ContentHubField $_.properties 'displayName') -eq $DisplayName) -or $_.name -eq $stableId
    })
    if ($matches.Count -gt 1) { return "Multiple existing rules match the template/name: $(@($matches.name) -join ', '). Existing duplicates are preserved." }
    if ($matches.Count -eq 1) {
        $rule = $matches[0]
        $existingKind = Get-ContentHubField $rule 'kind'
        if ($existingKind -eq 'NRT') { return "Existing NRT rule $($rule.name) is preserved." }
        if ((Get-ContentHubField $rule.properties 'alertRuleTemplateName') -ne $TemplateName) { return "Existing rule $($rule.name) has an exact name/ID collision without the same template link; preserving user-owned content." }
        if ($existingKind -and $existingKind -ne $Kind) { return "Existing rule $($rule.name) has a different kind; no replacement is permitted." }
    }
    return $null
}

function Resolve-ContentHubWorkbookIdentity($Metadata, $SavedWorkbooks, [string]$ContentId, [string[]]$DisplayNames, [hashtable]$ReadCache = @{}) {
    $result = @{ Blocked = $false; Reason = ''; Metadata = $null; Resource = $null; ResourceId = ''; Name = '' }
    if (-not $ContentId -or $ContentId.StartsWith('[')) {
        $result.Blocked = $true; $result.Reason = 'Missing or unevaluated workbook content identity.'
        return $result
    }
    $workspaceId = $script:BaseUri.Substring($script:ServerUrl.Length).TrimEnd('/')
    $name = Get-ContentHubStableId 'Workbook' $ContentId
    $result.Name = $name
    $result.ResourceId = "/subscriptions/$($script:SubscriptionId)/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/workbooks/$name"
    $links = @($Metadata | Where-Object {
        (Get-ContentHubField $_.properties 'contentId') -eq $ContentId -and
        (Get-ContentHubField $_.properties 'parentId') -match '/providers/Microsoft\.Insights/workbooks/'
    })
    $parents = @($links | ForEach-Object { [string]$_.properties.parentId } | Sort-Object -Unique)
    $candidates = @{}
    foreach ($parent in $parents) {
        if ($parent -notmatch "^/subscriptions/$([regex]::Escape($script:SubscriptionId))/resourceGroups/[^/]+/providers/Microsoft\.Insights/workbooks/[^/?#]+$") {
            $result.Blocked = $true; $result.Reason = "Untrusted workbook metadata parentId: $parent"
            return $result
        }
        # A stale metadata link is absence only on this explicit resource GET's 404.
        if (-not $ReadCache.ContainsKey($parent)) {
            $ReadCache[$parent] = Invoke-SentinelApi -Uri "$($script:ServerUrl)$parent`?api-version=2022-04-01" -Method GET -Headers @{} -AllowMissingWorkbook
        }
        $saved = $ReadCache[$parent]
        if ($saved) {
            if ($saved.id -ne $parent) { throw 'Workbook readback returned an unexpected resource identity.' }
            $candidates[$parent] = $saved
        }
    }
    foreach ($saved in $SavedWorkbooks) {
        $properties = Get-ContentHubField $saved 'properties'
        $tags = Get-ContentHubField $saved 'tags'
        $source = [string](Get-ContentHubField $properties 'sourceId')
        $tag = [string](Get-ContentHubField $tags 'hidden-sentinelWorkspaceId')
        $inWorkspace = $source.TrimEnd('/') -eq $workspaceId -or $tag.TrimEnd('/') -eq $workspaceId
        $titleMatch = @($DisplayNames | Where-Object { $_ -and $_ -eq (Get-ContentHubField $properties 'displayName') }).Count -gt 0
        if (($inWorkspace -and ($titleMatch -or (Get-ContentHubField $tags 'sentinel-contentId') -eq $ContentId)) -or $saved.id -eq $result.ResourceId) {
            if (-not $candidates.ContainsKey([string]$saved.id)) { $candidates[[string]$saved.id] = $saved }
        }
    }
    if ($candidates.Count -gt 1) {
        $result.Blocked = $true; $result.Reason = "Multiple saved workbooks match: $(@($candidates.Keys) -join ', '). Existing duplicates are preserved."
        return $result
    }
    if (-not $candidates.Count) { return $result }
    $saved = @($candidates.Values)[0]
    $source = [string](Get-ContentHubField (Get-ContentHubField $saved 'properties') 'sourceId')
    $tag = [string](Get-ContentHubField (Get-ContentHubField $saved 'tags') 'hidden-sentinelWorkspaceId')
    $link = @($links | Where-Object { $_.properties.parentId -eq $saved.id })
    if (($source -and $source.TrimEnd('/') -ne $workspaceId) -or ($tag -and $tag.TrimEnd('/') -ne $workspaceId)) {
        $result.Blocked = $true; $result.Reason = "Workbook $($saved.id) belongs to a different or conflicting workspace."
        return $result
    }
    # Only Sentinel metadata authorizes updating an existing saved workbook.
    # A deterministic ID/tag without metadata means a prior write may have been interrupted:
    # preserve it rather than create a duplicate or claim its metadata is complete.
    if (-not $link.Count) {
        $result.Blocked = $true; $result.Reason = "Saved workbook $($saved.id) already exists without a verified Sentinel metadata link; preserved. Review/link it manually rather than duplicate or overwrite it."
        return $result
    }
    if ($link.Count -gt 1) {
        $result.Blocked = $true; $result.Reason = "Multiple metadata entries refer to $($saved.id); review the conflicting links."
        return $result
    }
    $result.Metadata = $link[0]
    $result.Resource = $saved
    $result.ResourceId = [string]$saved.id
    $result.Name = ($result.ResourceId -split '/')[-1]
    return $result
}

function Update-ContentHubSource([string]$Source) {
    $tokens = $null
    $errors = $null
    $tree = [Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
    $functions = @($tree.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] }, $true))
    # Tiny authentication fixtures do not contain a deployment engine.
    if (-not @($functions | Where-Object Name -eq 'Invoke-Main').Count) { return $Source }
    $edits = [Collections.Generic.List[object]]::new()
    foreach ($name in @('Get-SolutionStatus', 'Get-ContentHubSolutions', 'Deploy-Solution', 'Get-SolutionUpdateReport', 'Invoke-Main', 'Deploy-AnalyticsRules', 'Deploy-Workbooks')) {
        $nodes = @($functions | Where-Object Name -eq $name)
        if ($nodes.Count -ne 1) { throw "Upstream deployment layout changed: $name. Review before executing." }
        $node = $nodes[0]
        $text = $node.Extent.Text
        if ($name -eq 'Get-SolutionStatus') {
            $text = "function Get-SolutionStatus {`n$((Get-Command Get-VersionAwareSolutionStatus).Definition)`n}"
        } elseif ($name -eq 'Get-ContentHubSolutions') {
            $old = 'Write-PipelineMessage "Could not fetch installed solutions: $($_.Exception.Message). Treating all as new." -Level Warning'
            if (-not $text.Contains($old)) { throw 'Upstream package inventory error handling changed.' }
            $text = $text.Replace($old, 'throw # A failed registration inventory never authorizes installation.')
            $text = $text.Replace('Found $($installedPackages.Count) installed solutions.', 'Found $($installedPackages.Count) package registration records; owned artifacts are verified separately.')
            $old = '$installedLookup[$name] = $pkg'
            if (-not $text.Contains($old)) { throw 'Upstream package lookup layout changed.' }
            $text = $text.Replace($old, 'if ($installedLookup.ContainsKey($name)) { throw "Ambiguous registered package name: $name" }; $installedLookup[$name] = $pkg')
        } elseif ($name -eq 'Get-SolutionUpdateReport') {
            $text = 'function Get-SolutionUpdateReport { param($SolutionStatuses) Write-ContentHubPackagePresenceReport $SolutionStatuses }'
        } elseif ($name -eq 'Deploy-Solution') {
            $packageAssignment = @($node.FindAll({
                param($n)
                $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$packagedContent'
            }, $true))
            if ($packageAssignment.Count -ne 1) { throw 'Upstream package body discovery layout changed.' }
            $text = $text.Replace($packageAssignment[0].Extent.Text, '$packagedContent = Get-ContentHubField (Get-ContentHubField $detailedSolution ''properties'') ''packagedContent''')
            $old = '$action = $SolutionStatus.Action'
            if (-not $text.Contains($old)) { throw 'Upstream solution action layout changed.' }
            $text = $text.Replace($old, $old + @'

    if ($SolutionStatus.Status -eq 'Unverified') {
        Write-PipelineMessage "  ActionRequired: $solutionName installation is unverified. $($SolutionStatus.Presence.Detail)" -Level Warning
        return $false
    }
'@)
            $old = '    if (-not $packagedContent) {'
            if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw 'Upstream packaged content layout changed.' }
            $text = $text.Replace($old, @'
    if ($SolutionStatus.Status -in @('RepairRequired', 'RegistrationMissing')) {
        $packagedContent = $SolutionStatus.Presence.RepairTemplate
        if (-not $packagedContent) { throw 'No verified repair template is available.' }
    }
    $packagedContent = Initialize-ContentHubPackageTemplate $packagedContent
    $packageResources = Get-ContentHubField $packagedContent 'resources' -NoEnumerate
    $resourceCount = if ($packageResources -is [array] -or $packageResources -is [Collections.IDictionary]) { $packageResources.Count }
        else { @($packageResources.PSObject.Properties).Count }
    if ($resourceCount -eq 0) {
        # An explicit empty manifest is a valid registration-only solution.
        $packagedContent = $null
    }
    if (-not $packagedContent) {
'@)
            $postDeploymentLoops = @($node.FindAll({
                param($n)
                $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -eq '$packagedContent.resources'
            }, $true))
            if ($postDeploymentLoops.Count -ne 1) { throw 'Upstream package metadata preparation changed.' }
            $text = $text.Replace($postDeploymentLoops[0].Extent.Text, '# Package metadata was prepared on a schema-validated copy.')
            $bodyAssignments = @($node.FindAll({
                param($n)
                $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$deploymentBody'
            }, $true))
            if ($bodyAssignments.Count -ne 1) { throw 'Upstream ARM package deployment body changed.' }
            $text = $text.Replace($bodyAssignments[0].Extent.Text, $bodyAssignments[0].Extent.Text +
                "`n    `$deploymentBody.properties.parameters = Get-ContentHubPackageParameters `$packagedContent -Workspace `$Workspace -Region `$Region")
            $serialization = '$jsonBody = $deploymentBody | ConvertTo-Json -EnumsAsStrings -Depth 50 -EscapeHandling EscapeNonAscii'
            if (-not $text.Contains($serialization)) { throw 'Upstream ARM package serialization changed.' }
            $text = $text.Replace($serialization, '$jsonBody = $deploymentBody | ConvertTo-Json -EnumsAsStrings -Depth 100 -EscapeHandling EscapeNonAscii -WarningAction Stop')
            # Keep preparation failures as per-package failures even when they occur
            # before the upstream request/serialization try blocks.
            $parameterEnd = $node.Body.ParamBlock.Extent.EndOffset - $node.Extent.StartOffset
            $text = $text.Insert($parameterEnd, "`n    try {")
            $preparationCatch = @'
    } catch {
        $reason = if ($_.Exception.Data['ContentHubPreflightReason']) {
            [string]$_.Exception.Data['ContentHubPreflightReason']
        } elseif ($_.Exception.Message -match '^(Package |The catalog |No verified repair |Workspace package )') {
            $_.Exception.Message
        } else { 'Local package preparation failed; inspect the run log. Parameter values and provider bodies suppressed.' }
        $resourceId = ([uri]"$script:BaseUri/providers/Microsoft.SecurityInsights/contentProductPackages/$($catalogEntry.name)").AbsolutePath
        if (-not (Get-Variable ContentHubRequestDetails -Scope Script -ErrorAction SilentlyContinue)) { $script:ContentHubRequestDetails = @{} }
        $script:ContentHubRequestDetails["PREPARE $resourceId"] = [pscustomobject]@{
            Method = 'PREPARE'; ResourceId = $resourceId; HttpStatus = $null
            AzureErrorCode = ''; RuleName = ''; Reason = $reason; RequestId = ''; WriteAttempted = $false
        }
        Write-PipelineMessage "  Package preparation failed for $solutionName : $reason" -Level Error
        return $false
    }
'@
            $text = $text.Insert($text.LastIndexOf('}'), "$preparationCatch`n")
        } elseif ($name -eq 'Invoke-Main') {
            $old = '$script:AuthHeader          = $azCtx.AuthHeader'
            if (-not $text.Contains($old)) { throw 'Upstream target initialization layout changed.' }
            $text = $text.Replace($old, "$old`n    Confirm-ContentHubSelectedTarget")
            $old = '$success = Deploy-Solution -SolutionStatus $status'
            if (-not $text.Contains($old)) { throw 'Upstream package deployment outcome layout changed.' }
            $text = $text.Replace($old, "$old`n            `$status.DeploymentSucceeded = [bool]`$success")
            $old = '    # Track which solutions were freshly installed or updated this run'
            if (-not $text.Contains($old)) { throw 'Upstream package/runtime phase boundary changed.' }
            $text = $text.Replace($old, "    Confirm-ContentHubPackageArtifacts `$solutionStatuses`n`n$old")
            $text = $text.Replace('Freshly deployed solutions (content will be force-processed)', 'Package operations completed (runtime content still uses independent version/identity checks)')
        } else {
            $pattern = '(?m)^[ \t]*\$isFromNewSolution = [^\r\n]+'
            if ([regex]::Matches($text, $pattern).Count -ne 1) { throw "Upstream content version layout changed: $name." }
            $text = [regex]::Replace($text, $pattern, '        $isFromNewSolution = $false')
            if ($name -eq 'Deploy-AnalyticsRules') {
                $kindAssignments = @($node.FindAll({
                    param($n)
                    $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$kind'
                }, $true))
                if ($kindAssignments.Count -ne 1) { throw 'Upstream analytics rule-kind detection layout changed; refusing to deploy without the NRT filter.' }
                $kindAssignment = $kindAssignments[0].Extent.Text
                $text = $text.Replace($kindAssignment, $kindAssignment + @'

        if ($kind -eq 'NRT') {
            $nrtContentId = Get-ContentHubField $template.properties 'contentId'
            if ($nrtContentId) { [void]$seenContent.Add("id:$nrtContentId") }
            Write-PipelineMessage "  Skipping NRT rule (excluded): $displayName" -Level Info
            $counters.Skipped++
            continue
        }
'@)
                $templateAssignments = @($node.FindAll({
                    param($n)
                    $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$templateName'
                }, $true))
                if ($templateAssignments.Count -ne 1) { throw 'Upstream rule identity layout changed; refusing to alter existing NRT rules.' }
                $templateAssignment = $templateAssignments[0].Extent.Text
                $text = $text.Replace($templateAssignment, $templateAssignment + @'

        $collision = Test-ContentHubRuleCollision $existingRules $templateName $displayName $kind
        if ($collision -or -not $seenContent.Add("id:$templateName") -or -not $seenContent.Add("title:$displayName")) {
            Write-PipelineMessage "  ActionRequired/Skipped rule '$displayName': $(if ($collision) { $collision } else { 'Repeated template identity or exact title in this run.' })" -Level Warning
            $counters.Skipped++
            continue
        }
        # Also protect an existing NRT rule if the current template changes kind.
        $matchedRules = @(
            if ($templateName -and $rulesByTemplate.ContainsKey($templateName)) { $rulesByTemplate[$templateName] }
            if ($displayName -and $rulesByName.ContainsKey($displayName)) { $rulesByName[$displayName] }
        )
        if (@($matchedRules | Where-Object { $_.PSObject.Properties['kind'] -and $_.kind -eq 'NRT' }).Count) {
            Write-PipelineMessage "  Skipping existing NRT rule (preserved): $displayName" -Level Info
            $counters.Skipped++
            continue
        }
'@)
                $deletes = @($node.FindAll({
                    param($n)
                    $n -is [Management.Automation.Language.CommandAst] -and
                    $n.GetCommandName() -eq 'Invoke-SentinelApi' -and $n.Extent.Text -match '-Method Delete'
                }, $true))
                if ($deletes.Count -ne 1) { throw 'Upstream NRT update layout changed.' }
                $deleteBlock = $deletes[0].Parent
                while ($deleteBlock -and -not ($deleteBlock -is [Management.Automation.Language.IfStatementAst] -and
                    $deleteBlock.Clauses[0].Item1.Extent.Text -eq '$needsUpdate -and $existingRule')) {
                    $deleteBlock = $deleteBlock.Parent
                }
                if (-not $deleteBlock) { throw 'Upstream NRT replacement layout changed.' }
                $text = $text.Replace($deleteBlock.Extent.Text, '# NRT rules are excluded above; existing NRT rules are never deleted.')
                $old = '(New-Guid).Guid'
                if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw 'Upstream analytics resource naming changed.' }
                $text = $text.Replace($old, "(Get-ContentHubStableId 'AnalyticsRule' `$templateName)")
            }
            if ($name -eq 'Deploy-Workbooks') {
                $old = 'Invoke-SentinelApi -Uri $detailUrl -Method Get -Headers $script:AuthHeader'
                if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw 'Upstream workbook fallback layout changed.' }
                $text = $text.Replace($old, "$old -OptionalWorkbookProbe")
                foreach ($pair in @(
                    @('Invoke-AzRestMethod -Path $workbookPath -Method PUT -Payload $workbookPayload',
                      'Invoke-ContentHubWorkbookWrite -Path $workbookPath -Payload $workbookPayload'),
                    @('Invoke-AzRestMethod -Path $metadataPath -Method PUT -Payload $metadataPayload',
                      'Invoke-ContentHubWorkbookWrite -Path $metadataPath -Payload $metadataPayload')
                )) {
                    if ([regex]::Matches($text, [regex]::Escape($pair[0])).Count -ne 1) { throw 'Upstream workbook write layout changed.' }
                    $text = $text.Replace($pair[0], $pair[1])
                }
                $old = '$existingVersion -and $templateVersion -and $existingVersion -eq $templateVersion'
                if (-not $text.Contains($old)) { throw 'Upstream workbook version comparison layout changed.' }
                $text = $text.Replace($old, '$existingVersion -and $templateVersion -and (Compare-SemanticVersion -Version1 $existingVersion -Version2 $templateVersion) -ge 0')
                $old = '/contentTemplates/${tmplId}?'
                if (-not $text.Contains($old)) { throw 'Upstream workbook identifier layout changed.' }
                $text = $text.Replace($old, '/contentTemplates/$([uri]::EscapeDataString($tmplId))?')
                $old = 'Write-PipelineMessage "Could not fetch workbook metadata: $($_.Exception.Message)" -Level Warning'
                if (-not $text.Contains($old)) { throw 'Upstream workbook inventory error handling changed.' }
                $text = $text.Replace($old, 'throw # A failed inventory never establishes absence.')
                $old = '        $needsUpdate = $false'
                if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw 'Upstream workbook version layout changed.' }
                $text = $text.Replace($old, @'
        $displayNames = @($displayName)
        $mainTemplate = Get-ContentHubField $template.properties 'mainTemplate'
        $displayNames += @((Get-ContentHubField $mainTemplate 'resources') | Where-Object { $_ -and (Get-ContentHubField $_ 'type') -eq 'Microsoft.Insights/workbooks' } | ForEach-Object { Get-ContentHubField $_.properties 'displayName' })
        $workbookIdentity = Resolve-ContentHubWorkbookIdentity $existingWorkbooks $savedWorkbooks $contentId $displayNames $workbookReads
        if ($workbookIdentity.Blocked -or -not $seenContent.Add("id:$contentId") -or -not $seenContent.Add("title:$displayName")) {
            Write-PipelineMessage "  ActionRequired/Skipped workbook '$displayName': $(if ($workbookIdentity.Blocked) { $workbookIdentity.Reason } else { 'Repeated template identity or exact title in this run.' })" -Level Warning
            $counters.Skipped++
            continue
        }
        $existingMeta = $workbookIdentity.Metadata
        $needsUpdate = $false
'@)
                foreach ($variable in @('$guid', '$workbookPath', '$workbookResourceId')) {
                    $assignments = @($node.FindAll({
                        param($n)
                        $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $variable
                    }, $true))
                    if ($assignments.Count -ne 1) { throw "Upstream workbook resource naming changed: $variable." }
                    $replacement = switch ($variable) {
                        '$guid' { '$guid = $workbookIdentity.Name' }
                        '$workbookPath' { '$workbookPath = "$($workbookIdentity.ResourceId)?api-version=2022-04-01"' }
                        '$workbookResourceId' { '$workbookResourceId = $workbookIdentity.ResourceId' }
                    }
                    $text = $text.Replace($assignments[0].Extent.Text, $replacement)
                }
                $old = '        $workbookPayload = $workbookBody | ConvertTo-Json -Depth 50 -EnumsAsStrings'
                if (-not $text.Contains($old)) { throw 'Upstream workbook payload layout changed.' }
                $text = $text.Replace($old, @'
        # The detailed template can have a different title from the listing.
        $finalIdentity = Resolve-ContentHubWorkbookIdentity $existingWorkbooks $savedWorkbooks $contentId @($displayName, $wbDisplayName) $workbookReads
        if ($finalIdentity.Blocked -or $finalIdentity.ResourceId -ne $workbookIdentity.ResourceId -or
            -not $seenContent.Add("saved-title:$wbDisplayName")) {
            Write-PipelineMessage "  ActionRequired/Skipped workbook '$wbDisplayName': a saved title/identity collision requires review. $($finalIdentity.Reason)" -Level Warning
            $counters.Skipped++
            continue
        }
        if ($workbookIdentity.Resource) {
            if (Get-ContentHubField $workbookIdentity.Resource 'location') { $workbookBody.location = $workbookIdentity.Resource.location }
            $savedTags = Get-ContentHubField $workbookIdentity.Resource 'tags'
            if ($savedTags) {
                foreach ($tag in $savedTags.PSObject.Properties) { $workbookBody.tags[$tag.Name] = $tag.Value }
            }
        }
        $workbookBody.tags['sentinel-contentId'] = $contentId
        $workbookPayload = $workbookBody | ConvertTo-Json -Depth 50 -EnumsAsStrings
'@)
            }
            $old = '    foreach ($template in $targetTemplates) {'
            if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw "Upstream template enumeration changed: $name." }
            $initialization = @'
    # Inert template versions coexist in Content Hub. Reconcile the newest first
    # so the same-run identity guard cannot select an older version by list order.
    $targetTemplates = @(Sort-ContentHubTemplates $targetTemplates)
    $seenContent = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
'@
            if ($name -eq 'Deploy-Workbooks') { $initialization += "`n    `$savedWorkbooks = @(Get-ContentHubSavedWorkbooks)`n    `$workbookReads = @{}" }
            $text = $text.Replace($old, "$initialization`n$old")
        }
        $edits.Add(@{ Start = $node.Extent.StartOffset; Length = $node.Extent.EndOffset - $node.Extent.StartOffset; Text = $text })
    }
    foreach ($edit in @($edits | Sort-Object Start -Descending)) { $Source = $Source.Remove($edit.Start, $edit.Length).Insert($edit.Start, $edit.Text) }
    $successMessage = 'Write-PipelineMessage "Deployment completed successfully." -Level Success'
    if ([regex]::Matches($Source, [regex]::Escape($successMessage)).Count -ne 1) {
        throw 'Upstream completion reporting layout changed; review before executing.'
    }
    $Source = $Source.Replace($successMessage, @'
if ($script:ContentHubUnresolvedFailures.Count -gt 0 -or $script:ContentHubPackageUnverified.Count -gt 0) {
            Write-PipelineMessage "Content phase finished with unresolved API errors or unverified package artifacts. Registration/skip counters do not establish deployment success; detailed outcomes follow." -Level Warning
        } else {
            Write-PipelineMessage "Deployment completed successfully." -Level Success
        }
'@)
    return $Source
}

function New-ContentHubDeploymentCopy([string]$Path) {
    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw 'The upstream Content Hub script has parse errors.' }
    $imports = @($ast.EndBlock.Statements | Where-Object {
        $_ -is [Management.Automation.Language.PipelineAst] -and
        $_.PipelineElements.Count -eq 1 -and
        $_.PipelineElements[0] -is [Management.Automation.Language.CommandAst] -and
        $_.PipelineElements[0].GetCommandName() -eq 'Import-Module' -and
        $_.Extent.Text -match 'Sentinel\.Common\.psd1'
    })
    $apiDefinitions = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-SentinelApi'
    }, $true))
    if ($imports.Count -ne 1 -or $apiDefinitions.Count) {
        throw 'Upstream authentication layout changed. Refusing to run without the token-refresh adapter; review the updated deployer.'
    }
    $adapter = (Get-Command Invoke-ContentHubArmApi -CommandType Function).Definition
    $insert = "`n`$script:ContentHubApiFailures = 0`n`$script:ContentHubUnresolvedFailures = @{} `n`$script:ContentHubRequestDetails = if (`$null -ne `$ContentHubFailureSink) { `$ContentHubFailureSink } else { @{} }`nfunction Invoke-SentinelApi {`n$adapter`n}`n"
    foreach ($helper in @('Get-ContentHubStableId', 'Get-ContentHubField', 'Get-ContentHubResourceCondition', 'Assert-ContentHubPackageResources', 'Initialize-ContentHubPackageTemplate', 'Get-ContentHubPackageParameters', 'Get-ContentHubSavedWorkbooks', 'Test-ContentHubRuleCollision', 'Resolve-ContentHubWorkbookIdentity', 'Compare-ContentHubArtifactVersion', 'Sort-ContentHubTemplates', 'Resolve-ContentHubManifestValue', 'Get-ContentHubPresenceInventory', 'Get-ContentHubArtifactIdentity', 'Save-ContentHubPackageDiagnostic', 'Read-ContentHubArtifact', 'ConvertTo-ContentHubSharedValue', 'Test-ContentHubSharedTemplate', 'Test-ContentHubPackagePresence', 'Confirm-ContentHubSelectedTarget', 'Write-ContentHubPackagePresenceReport', 'Confirm-ContentHubPackageArtifacts')) {
        $insert += "`nfunction $helper {`n$((Get-Command $helper -CommandType Function).Definition)`n}`n"
    }
    $expected = Get-Variable ContentHubExpectedTarget -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if ($expected) {
        $serializedTarget = (ConvertTo-Json $expected -Compress).Replace("'", "''")
        $insert += "`n`$script:ContentHubExpectedTarget = '$serializedTarget' | ConvertFrom-Json -AsHashtable`n"
    }
    $insert += "`n`$script:ContentHubPresenceInventory = @{}`n`$script:ContentHubPackageUnverified = @{}`n"
    $insert += "`n`$script:ContentHubPackageDiagnostics = if (`$null -ne `$ContentHubDiagnosticsSink) { `$ContentHubDiagnosticsSink } else { @{} }`n"
    $insert += @'
function Invoke-ContentHubWorkbookWrite([string]$Path, [string]$Payload) {
    $null = Invoke-SentinelApi -Uri "$($script:ServerUrl)$Path" -Method PUT -Headers @{} -Body $Payload
    [pscustomobject]@{ StatusCode = 200; Content = '' }
}

'@
    if (-not $ast.ParamBlock) { throw 'Upstream parameter block missing; cannot preserve package diagnostics.' }
    $source = $ast.Extent.Text.Insert($imports[0].Extent.EndOffset, $insert)
    $separator = if ($ast.ParamBlock.Parameters.Count) { ',' } else { '' }
    $source = $source.Insert($ast.ParamBlock.Extent.EndOffset - 1, "$separator`n[hashtable]`$ContentHubDiagnosticsSink,`n[hashtable]`$ContentHubFailureSink`n")
    $source = Update-ContentHubSource $source
    $source += @'

if ($script:ContentHubUnresolvedFailures.Count -gt 0) {
    $failureDetails = @($script:ContentHubUnresolvedFailures.Values | Sort-Object) -join "`n"
    $failure = [InvalidOperationException]::new("Content Hub API operations failed and were not subsequently confirmed successful:`n$failureDetails`nContent deployment completeness is unverified. Expected workbook fallback probes and recognized missing-table/column rule prerequisites are excluded; other failures remain actionable.")
    $details = @($script:ContentHubRequestDetails.Values)
    $failure.Data['ContentHubRequestDetails'] = $details
    # Only rule-level validation failures can be deferred until after connector
    # configuration. Authentication, package, discovery and workbook failures stop.
    $failure.Data['ContentHubRuleValidationOnly'] = $script:ContentHubPackageUnverified.Count -eq 0 -and
        $details.Count -eq $script:ContentHubUnresolvedFailures.Count -and
        @($details | Where-Object {
            $_.Method -ne 'PUT' -or $_.HttpStatus -ne 400 -or
            $_.ResourceId -notmatch '/Microsoft\.SecurityInsights/alertRules/[^/]+$'
        }).Count -eq 0
    throw $failure
}
if ($script:ContentHubPackageUnverified.Count -gt 0) {
    throw "Package artifact installation remains unverified: $(@($script:ContentHubPackageUnverified.GetEnumerator() | ForEach-Object { '{0}: {1}' -f $_.Key, $_.Value }) -join '; '). Package registrations and runtime deployment are separate."
}
'@
    $null = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw 'Unable to prepare the token-safe Content Hub deployment script.' }
    # Same directory preserves upstream PSScriptRoot-relative module imports.
    $temporaryPath = Join-Path (Split-Path -Parent $Path) ("Deploy-SentinelContentHub.session-{0}.ps1" -f [guid]::NewGuid())
    [IO.File]::WriteAllText($temporaryPath, $source, [Text.UTF8Encoding]::new($false))
    return $temporaryPath
}

function Deploy-Solutions([string[]]$Solutions, [string]$Label) {
    if ($Solutions.Count -eq 0) { return }
    Step $Label
    if (-not (Get-Variable ContentHubPackageDiagnostics -Scope Script -ErrorAction SilentlyContinue)) { $script:ContentHubPackageDiagnostics = @{} }
    $temporaryScript = New-ContentHubDeploymentCopy $script:DeployScript
    $previousExitCode = Get-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    $savedExitCode = if ($previousExitCode) { $previousExitCode.Value } else { $null }
    try {
        $invocationState = @{ ErrorCount = 0 }
        $global:LASTEXITCODE = 0
        & $temporaryScript -SubscriptionId $script:SubscriptionId -ResourceGroup $script:ResourceGroup -Workspace $script:Workspace -Region $script:Region -Solutions $Solutions -SeveritiesToInclude $Severities -ContentHubDiagnosticsSink $script:ContentHubPackageDiagnostics -ContentHubFailureSink $script:ContentHubDeploymentFailures -WhatIf:$WhatIfPreference 2>&1 |
            ForEach-Object {
                if ($_ -is [Management.Automation.ErrorRecord]) {
                    $invocationState.ErrorCount++
                    Write-Warning $_.ToString()
                    Write-Host "Content Hub error ID: $($_.FullyQualifiedErrorId)"
                    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { Write-Host "Content Hub error details: $($_.ErrorDetails.Message)" }
                    if ($_.ScriptStackTrace) { Write-Host "Content Hub error stack: $($_.ScriptStackTrace)" }
                } else { $_ }
            }
        $invocationSucceeded = $?
        if (-not $invocationSucceeded -or $global:LASTEXITCODE -ne 0 -or $invocationState.ErrorCount -gt 0) {
            throw "Content Hub deployment reported errors (exit=$global:LASTEXITCODE; error records=$($invocationState.ErrorCount)). Rule/workbook deployment is incomplete; installed packages alone are not success. Resolve the reported errors and rerun."
        }
    } finally {
        if ($previousExitCode) { $global:LASTEXITCODE = $savedExitCode }
        else { Remove-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $temporaryScript -Force -WhatIf:$false -Confirm:$false -ErrorAction Stop
    }
}

function Invoke-ContentHubDeploymentPhase([string[]]$Solutions, [string]$Label) {
    try { Deploy-Solutions $Solutions $Label }
    catch {
        if ($_.Exception.Data['ContentHubRuleValidationOnly'] -ne $true) { throw }
        foreach ($failure in @($_.Exception.Data['ContentHubRequestDetails'])) {
            $script:ContentHubRuleFailures[$failure.ResourceId] = $failure
        }
        Write-Warning 'Analytics-rule validation failed. These failures are retained; continuing package verification and independent connector configuration. The final run result will remain incomplete, not success.'
    }
}

function Stop-PreviewDetection([string]$Reason) {
    $exception = [InvalidOperationException]::new($Reason)
    $exception.Data['PreviewDetectionSafeReason'] = $Reason
    throw $exception
}

function ConvertTo-PreviewDetectionData($Value, [int]$Depth = 0, [object[]]$Ancestors = @()) {
    if ($Depth -gt 64) { Stop-PreviewDetection 'Preview declaration exceeds the supported inspection depth.' }
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [ValueType]) { return $Value }
    foreach ($ancestor in $Ancestors) {
        if ([object]::ReferenceEquals($Value, $ancestor)) { Stop-PreviewDetection 'Circular preview declaration is not inspectable.' }
    }
    $parents = @($Ancestors) + ,$Value
    if ($Value -is [Collections.IDictionary] -or $Value -is [pscustomobject]) {
        $result = @{}
        $keys = if ($Value -is [Collections.IDictionary]) { @($Value.Keys) } else { @($Value.PSObject.Properties.Name) }
        foreach ($key in $keys) {
            if ($result.ContainsKey([string]$key)) { Stop-PreviewDetection 'Ambiguous case-colliding preview JSON field names are unsupported.' }
            if ($Value -is [Collections.IDictionary]) { $child = $Value[$key] }
            else { $child = $Value.PSObject.Properties[$key].Value }
            $result[[string]$key] = ConvertTo-PreviewDetectionData $child ($Depth + 1) $parents
        }
        return $result
    }
    if ($Value -is [array]) {
        return ,@($Value | ForEach-Object { ConvertTo-PreviewDetectionData $_ ($Depth + 1) $parents })
    }
    Stop-PreviewDetection 'Preview declaration must contain JSON-compatible values.'
}

function Get-PreviewDetectionHash($Value) {
    $canonical = ConvertTo-PolicyCanonical (ConvertTo-PreviewDetectionData $Value)
    $json = ConvertTo-Json -InputObject $canonical -Depth 100 -Compress
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))
}

function Assert-PreviewDetectionFields($Object, [string[]]$Allowed, [string[]]$Required = @()) {
    if ($Object -isnot [Collections.IDictionary]) { Stop-PreviewDetection 'Preview payload requires a literal JSON object.' }
    foreach ($key in $Object.Keys) {
        if ($key -cnotin $Allowed) { Stop-PreviewDetection 'Preview payload contains an unsupported field; review the current Graph beta schema manually.' }
    }
    foreach ($key in $Required) {
        if (-not $Object.Contains($key) -or $null -eq $Object[$key]) { Stop-PreviewDetection 'Preview payload is missing a required literal field.' }
    }
}

function Assert-PreviewDetectionLiteral($Value) {
    if ($Value -is [string] -and $Value.TrimStart().StartsWith('[')) {
        Stop-PreviewDetection 'ARM expressions in preview payloads are unsupported; no expressions are evaluated or sent to Graph.'
    }
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) { Assert-PreviewDetectionLiteral $Value[$key] }
    } elseif ($Value -is [array]) {
        foreach ($child in $Value) { Assert-PreviewDetectionLiteral $child }
    }
}

function Test-PreviewDetectionEmptyAction($Value) {
    if ($null -eq $Value) { return $true }
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ($key -eq '@odata.type') { continue }
            if (-not (Test-PreviewDetectionEmptyAction $Value[$key])) { return $false }
        }
        return $true
    }
    if ($Value -is [array]) { return $Value.Count -eq 0 }
    return $false
}

function Assert-PreviewDetectionNoAutomation($Rule) {
    $action = Get-Field $Rule 'detectionAction' @{}
    Assert-PreviewDetectionFields $action @('alertTemplate', 'automatedActions', 'responseActions', 'incidentConfiguration', 'organizationalScope', '@odata.type')
    foreach ($key in @('automatedActions', 'responseActions')) {
        if (-not (Test-PreviewDetectionEmptyAction (Get-Field $action $key))) {
            Stop-PreviewDetection 'Automated response actions are not supported by this disabled scheduled-preview adapter.'
        }
    }
}

function Assert-PreviewDetectionAlertSchema($Alert) {
    if ([string]::IsNullOrWhiteSpace($Alert.title)) { Stop-PreviewDetection 'Preview alert title must be nonempty.' }
    if ($Alert.Contains('tactics')) {
        if ($Alert.tactics -isnot [array]) { Stop-PreviewDetection 'Preview tactics must be a literal array.' }
        foreach ($tactic in $Alert.tactics) {
            Assert-PreviewDetectionFields $tactic @('tactic', 'techniques') @('tactic')
            if ($tactic.tactic -isnot [string] -or [string]::IsNullOrWhiteSpace($tactic.tactic)) { Stop-PreviewDetection 'Preview tactic identifier must be a literal string.' }
            if ($tactic.Contains('techniques')) {
                if ($tactic.techniques -isnot [array]) { Stop-PreviewDetection 'Preview techniques must be a literal array.' }
                foreach ($technique in $tactic.techniques) {
                    Assert-PreviewDetectionFields $technique @('technique', 'subTechniques') @('technique')
                    if ($technique.technique -isnot [string] -or [string]::IsNullOrWhiteSpace($technique.technique)) { Stop-PreviewDetection 'Preview technique identifier must be a literal string.' }
                    if ($technique.Contains('subTechniques')) {
                        if ($technique.subTechniques -isnot [array]) { Stop-PreviewDetection 'Preview subTechniques must be a literal string array.' }
                        foreach ($subTechnique in $technique.subTechniques) {
                            if ($subTechnique -isnot [string]) { Stop-PreviewDetection 'Preview subTechniques must be literal strings.' }
                        }
                    }
                }
            }
        }
    }
    if ($Alert.Contains('entityMappings')) {
        $reviewed = @{
            accounts = @('id', 'aadUserIdColumn', 'dnsDomainColumn', 'nameColumn', 'ntDomainColumn', 'sidColumn', 'upnColumn', 'upnSuffixColumn')
            hosts = @('id', 'deviceIdColumn', 'dnsDomainColumn', 'nameColumn', 'netBiosNameColumn', 'ntDomainColumn')
            ips = @('id', 'addressColumn')
            azureResources = @('id', 'resourceIdColumn')
            files = @('id', 'nameColumn', 'directoryColumn', 'sha1Column', 'sha256Column')
        }
        Assert-PreviewDetectionFields $Alert.entityMappings @($reviewed.Keys)
        foreach ($kind in $Alert.entityMappings.Keys) {
            $mappings = $Alert.entityMappings[$kind]
            if ($mappings -isnot [array]) { Stop-PreviewDetection 'Preview entity mappings must be literal arrays of mapping objects.' }
            foreach ($mapping in $mappings) {
                Assert-PreviewDetectionFields $mapping $reviewed[$kind]
                foreach ($value in $mapping.Values) {
                    if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { Stop-PreviewDetection 'Preview entity mapping identifiers and columns must be nonempty literal strings.' }
                }
            }
        }
    }
    if ($Alert.Contains('customDetails')) {
        if ($Alert.customDetails -isnot [Collections.IDictionary]) { Stop-PreviewDetection 'Preview customDetails must be a literal column-name map.' }
        foreach ($value in $Alert.customDetails.Values) {
            if ($value -isnot [string]) { Stop-PreviewDetection 'Preview customDetails column names must be literal strings.' }
        }
    }
}

function ConvertTo-PreviewDetectionPayload($Properties) {
    $payload = ConvertTo-PreviewDetectionData $Properties
    Assert-PreviewDetectionFields $payload @('id', 'displayName', 'description', 'status', 'queryCondition', 'schedule', 'detectionAction') @('id', 'displayName', 'status', 'queryCondition', 'schedule', 'detectionAction')
    Assert-PreviewDetectionLiteral $payload
    if ($payload.id -isnot [string] -or $payload.id -cnotmatch '^[a-z0-9][a-z0-9_-]{0,127}$') {
        Stop-PreviewDetection 'Preview rule ID must be a literal stable safe slug (1-128 lowercase letters, digits, underscores or hyphens).'
    }
    if ($payload.displayName -isnot [string] -or [string]::IsNullOrWhiteSpace($payload.displayName) -or $payload.status -cne 'disabled') {
        Stop-PreviewDetection 'Preview source must declare a nonempty literal displayName and disabled status; source statuses are not rewritten.'
    }
    if ($payload.Contains('description') -and $payload.description -isnot [string]) { Stop-PreviewDetection 'Preview description must be a literal string.' }
    Assert-PreviewDetectionFields $payload.queryCondition @('queryText') @('queryText')
    if ($payload.queryCondition.queryText -isnot [string] -or [string]::IsNullOrWhiteSpace($payload.queryCondition.queryText)) { Stop-PreviewDetection 'Preview queryText must be a nonempty literal string.' }
    Assert-PreviewDetectionFields $payload.schedule @('frequency') @('frequency')
    if ($payload.schedule.frequency -cnotin @('PT5M', 'PT1H', 'PT3H', 'PT12H', 'PT24H', 'P1D')) {
        Stop-PreviewDetection 'Only reviewed positive scheduled frequencies are supported; continuous/zero or unknown frequencies require manual review.'
    }
    Assert-PreviewDetectionFields $payload.detectionAction @('alertTemplate', 'automatedActions', 'responseActions', 'incidentConfiguration') @('alertTemplate')
    Assert-PreviewDetectionNoAutomation $payload
    if ($payload.detectionAction.Contains('incidentConfiguration')) {
        Assert-PreviewDetectionFields $payload.detectionAction.incidentConfiguration @('isExcludedFromIncidentCorrelation')
        foreach ($value in $payload.detectionAction.incidentConfiguration.Values) {
            if ($value -isnot [bool]) { Stop-PreviewDetection 'Preview incident configuration must be a literal boolean.' }
        }
    }
    $alert = $payload.detectionAction.alertTemplate
    Assert-PreviewDetectionFields $alert @('title', 'description', 'severity', 'recommendedActions', 'tactics', 'entityMappings', 'customDetails') @('title', 'description', 'severity')
    foreach ($field in @('title', 'description', 'recommendedActions')) {
        if ($alert.Contains($field) -and $alert[$field] -isnot [string]) { Stop-PreviewDetection 'Preview alert text must be literal strings.' }
    }
    if ($alert.severity -cnotin @('informational', 'low', 'medium', 'high')) { Stop-PreviewDetection 'Preview alert severity is unsupported.' }
    Assert-PreviewDetectionAlertSchema $alert
    return $payload
}

function Get-PreviewDetectionPlans($Template, [string]$Package, [string]$Version, [int]$Depth = 0) {
    if ($Depth -gt 32) { Stop-PreviewDetection 'Nested preview template inspection depth exceeded.' }
    if ($Template -is [string]) {
        try { $Template = ConvertFrom-Json -InputObject $Template -AsHashtable -Depth 100 -ErrorAction Stop }
        catch { Stop-PreviewDetection 'Preview package template is not valid inspectable JSON.' }
    }
    $Template = ConvertTo-PreviewDetectionData $Template
    if ($Template -isnot [Collections.IDictionary] -or -not $Template.Contains('resources')) { Stop-PreviewDetection 'Preview package has no inspectable inline resources.' }
    $resources = $Template.resources
    $children = if ($resources -is [Collections.IDictionary]) { @($resources.Values) } elseif ($resources -is [array]) { @($resources) } else { Stop-PreviewDetection 'Preview resources must be an array or symbolic resource map.' }
    foreach ($resource in $children) {
        if ($resource -isnot [Collections.IDictionary]) { Stop-PreviewDetection 'Preview resource declaration must be an object.' }
        $type = [string](Get-Field $resource 'type' '')
        $importName = [string](Get-Field $resource 'import' '')
        if ($importName -or $type -match '^Microsoft\.Security/detectionRules(?:@|$)') {
            $import = Get-Field (Get-Field $Template 'imports' @{}) $importName @{}
            if ($type -cne 'Microsoft.Security/detectionRules@2026-06-01-preview' -or $importName -cne 'MicrosoftSecurity' -or
                (Get-Field $import 'provider') -cne 'MicrosoftSecurity' -or (Get-Field $import 'version') -cne '1.0.0') {
                Stop-PreviewDetection 'Unreviewed preview extension type, provider or version; no MicrosoftSecurity ARM extension resource is submitted.'
            }
            $payload = ConvertTo-PreviewDetectionPayload (Get-Field $resource 'properties')
            @{ Id = $payload.id; Payload = $payload; DesiredHash = Get-PreviewDetectionHash $payload; Sources = @(@{ Package = $Package; Version = $Version }) }
        }
        if ($type -eq 'Microsoft.Resources/deployments') {
            $properties = Get-Field $resource 'properties' @{}
            if ($properties.Contains('template')) {
                Get-PreviewDetectionPlans $properties.template $Package $Version ($Depth + 1)
            } elseif ($properties.Contains('templateLink')) {
                Stop-PreviewDetection 'Linked deployment is not inspectable offline; resolve preview declarations manually.'
            }
        }
        # Only executable resource children are walked, never stored properties.mainTemplate.
        if ($resource.Contains('resources')) {
            Get-PreviewDetectionPlans @{ resources = $resource.resources; imports = (Get-Field $Template 'imports' @{}) } $Package $Version ($Depth + 1)
        }
    }
}

function Test-PreviewDetectionPrerequisites {
    Ensure-Module 'Microsoft.Graph.Authentication' -RequiredCommands @('Get-MgContext', 'Connect-MgGraph', 'Invoke-MgGraphRequest', 'Get-MgRequestContext', 'Set-MgRequestContext')
    foreach ($name in @('Get-MgContext', 'Connect-MgGraph', 'Invoke-MgGraphRequest', 'Get-MgRequestContext', 'Set-MgRequestContext')) {
        if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
            Stop-PreviewDetection 'Graph authentication commands remain unavailable after automatic dependency setup. Restart PowerShell and rerun. No preview roles or consent are granted automatically.'
        }
    }
}

function Test-PreviewDetectionGraphContext($Context) {
    return ($null -ne $Context -and (Get-PreviewDetectionContextField $Context 'TenantId') -eq $script:TenantId -and
        (Get-PreviewDetectionContextField $Context 'Environment') -eq 'Global' -and (Get-PreviewDetectionContextField $Context 'AuthType') -eq 'Delegated' -and
        'CustomDetection.ReadWrite.All' -cin @(Get-PreviewDetectionContextField $Context 'Scopes'))
}

function Get-PreviewDetectionContextField($Context, [string]$Name) {
    if ($Context -is [Collections.IDictionary]) { return Get-Field $Context $Name }
    if ($null -ne $Context) {
        $property = $Context.PSObject.Properties[$Name]
        if ($property) { return $property.Value }
    }
    return $null
}

function Save-PreviewDetectionJournal {
    if ($WhatIfPreference) { Stop-PreviewDetection 'WhatIf cannot persist a preview journal.' }
    if (-not (Get-Variable PreviewDetectionLock -Scope Script -ValueOnly -ErrorAction SilentlyContinue)) { Stop-PreviewDetection 'Preview journal lock is not held.' }
    $temporary = "$script:PreviewDetectionJournalPath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $json = ConvertTo-Json -InputObject $script:PreviewDetectionJournal -Depth 20 -Compress -ErrorAction Stop
        $stream = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally { $stream.Dispose() }
        if ([IO.File]::Exists($script:PreviewDetectionJournalPath)) { [IO.File]::Replace($temporary, $script:PreviewDetectionJournalPath, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $script:PreviewDetectionJournalPath) }
    } catch {
        $script:PreviewDetectionPersistenceBlocked = $true
        Stop-PreviewDetection 'Preview journal persistence failed; prior journal preserved. No further write is permitted; inspect the stable ID and reconcile manually.'
    } finally {
        if ([IO.File]::Exists($temporary)) {
            try { [IO.File]::Delete($temporary) } catch { Write-Warning 'Could not remove this run''s preview journal staging file.' }
        }
    }
}

function Initialize-PreviewDetectionSupport {
    $script:PreviewDetectionFailures = 0
    $script:PreviewDetectionPersistenceBlocked = $false
    if ($WhatIfPreference) { return }
    Test-PreviewDetectionPrerequisites
    if ($script:ArmEndpoint.Scheme -ne 'https' -or $script:ArmEndpoint.Authority -ne 'management.azure.com') {
        Stop-PreviewDetection 'Defender detectionRules beta support is public-cloud only; no sovereign-cloud Graph fallback is allowed.'
    }
    if (Get-Variable PreviewDetectionLock -Scope Script -ValueOnly -ErrorAction SilentlyContinue) { Stop-PreviewDetection 'Preview support is already initialized.' }
    $statePath = [string](Get-Variable PreviewDetectionStatePath -ValueOnly -ErrorAction SilentlyContinue)
    if (-not $statePath) {
        $directory = if (Test-Path -LiteralPath (Join-Path $HOME 'clouddrive') -PathType Container) { Join-Path $HOME 'clouddrive' } else { $HOME }
        $statePath = Join-Path $directory "sentinel-preview-detections-$(Get-StableName $script:WorkspaceId).json"
    }
    $provider = $null
    $drive = $null
    $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($statePath, [ref]$provider, [ref]$drive)
    if ($provider.Name -ne 'FileSystem' -or [IO.Path]::GetExtension($path) -ine '.json' -or -not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($path))) {
        Stop-PreviewDetection 'PreviewDetectionStatePath must be a .json filesystem file in an existing persistent directory.'
    }
    foreach ($variable in @('ConnectorReportPath', 'LogPath', 'PSCommandPath')) {
        $reserved = [string](Get-Variable $variable -ValueOnly -ErrorAction SilentlyContinue)
        if ($reserved -and $path -ieq $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($reserved)) {
            Stop-PreviewDetection 'Preview journal cannot overwrite a report, log or script path.'
        }
    }
    foreach ($candidate in @($path, "$path.lock")) {
        if (Test-Path -LiteralPath $candidate) {
            $item = Get-Item -LiteralPath $candidate -Force
            if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Stop-PreviewDetection 'Preview state and lock must be ordinary files, not directories or links.' }
        }
    }
    $script:PreviewDetectionJournalPath = $path
    try {
        try { $script:PreviewDetectionLock = [IO.File]::Open("$path.lock", [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
        catch { Stop-PreviewDetection 'Preview journal is locked or inaccessible. Finish the other run or select the correct persistent state file; do not delete a live lock.' }
        $scope = @{
            schemaVersion = 1; adapter = 'SentinelScheduledDefenderPreview-v1'; tenantId = $script:TenantId
            workspaceId = $script:WorkspaceId; subscriptionId = $script:SubscriptionId
            rootIdentity = Get-StableName "$script:SubscriptionId|$script:WorkspaceId|https://graph.microsoft.com/beta/security/rules/detectionRules"
            rules = @{}
        }
        if ([IO.File]::Exists($path)) {
            try { $journal = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($path)) -AsHashtable -Depth 20 -ErrorAction Stop }
            catch { Stop-PreviewDetection 'Preview journal is unreadable or invalid JSON; preserve it and reconcile manually.' }
            Assert-PreviewDetectionFields $journal @($scope.Keys) @($scope.Keys)
            foreach ($field in @('schemaVersion', 'adapter', 'tenantId', 'workspaceId', 'subscriptionId', 'rootIdentity')) {
                if ($journal[$field] -ne $scope[$field]) { Stop-PreviewDetection 'Preview journal schema or tenant/workspace/root scope does not match this run; no adoption is allowed.' }
            }
            if ($journal.rules -isnot [Collections.IDictionary]) { Stop-PreviewDetection 'Preview journal rules must be an ownership map.' }
            foreach ($id in $journal.rules.Keys) {
                $entry = $journal.rules[$id]
                Assert-PreviewDetectionFields $entry @('id', 'sources', 'desiredHash', 'observedHash', 'phase', 'status', 'operation') @('id', 'sources', 'desiredHash', 'observedHash', 'phase', 'status', 'operation')
                if ($id -cnotmatch '^[a-z0-9][a-z0-9_-]{0,127}$' -or $entry.id -cne $id -or
                    $entry.desiredHash -cnotmatch '^[A-F0-9]{64}$' -or $entry.phase -cnotin @('Pending', 'Accepted', 'Verified', 'Failed') -or
                    $entry.status -cne 'disabled' -or $entry.operation -cnotin @('CREATE', 'UPDATE') -or
                    ($entry.phase -eq 'Verified' -and $entry.observedHash -cnotmatch '^[A-F0-9]{64}$') -or
                    ($entry.observedHash -ne '' -and $entry.observedHash -cnotmatch '^[A-F0-9]{64}$') -or $entry.sources -isnot [array]) {
                    Stop-PreviewDetection 'Preview journal ownership record is invalid; preserve it and reconcile manually.'
                }
                foreach ($source in $entry.sources) {
                    Assert-PreviewDetectionFields $source @('Package', 'Version') @('Package', 'Version')
                    if ($source.Package -isnot [string] -or $source.Version -isnot [string]) { Stop-PreviewDetection 'Preview journal provenance record is invalid.' }
                }
            }
            $script:PreviewDetectionJournal = $journal
        } else { $script:PreviewDetectionJournal = $scope }
        Write-Warning 'Preview Graph privileges are tenant-wide, not workspace-scoped. Azure Owner does not grant Graph consent. Active Defender/Sentinel roles, licensing and onboarding are required. Rules remain disabled; no ingestion or query validation is claimed.'
        try { $context = Get-MgContext -ErrorAction Stop } catch { Stop-PreviewDetection 'Cannot inspect delegated Graph context; authenticate separately and rerun.' }
        if (-not (Test-PreviewDetectionGraphContext $context)) {
            if ((Read-Host 'Type AUTHENTICATE to request tenant-wide delegated CustomDetection.ReadWrite.All') -cne 'AUTHENTICATE') {
                Stop-PreviewDetection 'Preview Graph authentication was not approved; no roles or consent were granted by this script.'
            }
            try {
                Connect-MgGraph -TenantId $script:TenantId -Environment Global -Scopes 'CustomDetection.ReadWrite.All' -ContextScope Process -NoWelcome -ErrorAction Stop -Verbose:$false -Debug:$false | Out-Null
                $context = Get-MgContext -ErrorAction Stop
            } catch { Stop-PreviewDetection 'Delegated Graph authentication failed. Obtain CustomDetection.ReadWrite.All consent and active Defender/Sentinel roles separately; provider details suppressed.' }
            if (-not (Test-PreviewDetectionGraphContext $context)) { Stop-PreviewDetection 'Graph context tenant, cloud, delegated authentication or required scope does not match; no Graph calls are allowed.' }
        }
        if (-not [IO.File]::Exists($path)) { Save-PreviewDetectionJournal }
    } catch { Close-PreviewDetectionSupport; throw }
}

function Close-PreviewDetectionSupport {
    $lock = Get-Variable PreviewDetectionLock -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $lock) {
        try { $lock.Dispose() } catch { Write-Warning 'Could not close the preview journal lock; original run errors are preserved.' -WarningAction Continue }
        $script:PreviewDetectionLock = $null
    }
}

function Get-PreviewDetectionHttpStatus($Exception) {
    foreach ($name in @('ResponseStatusCode', 'StatusCode')) {
        $property = $Exception.PSObject.Properties[$name]
        if ($property -and $null -ne $property.Value) {
            try { return [int]$property.Value } catch { }
        }
    }
    $response = $Exception.PSObject.Properties['Response']
    if ($response -and $null -ne $response.Value) {
        $status = $response.Value.PSObject.Properties['StatusCode']
        if ($status -and $null -ne $status.Value) {
            try { return [int]$status.Value } catch { }
        }
    }
    return 0
}

function Invoke-PreviewDetectionGraph([string]$Method, [string]$Uri, $Body = $null, [switch]$Allow404) {
    if ($WhatIfPreference) { Stop-PreviewDetection 'WhatIf cannot call Graph.' }
    if ($Method -in @('POST', 'PATCH') -and (Get-Variable PreviewDetectionPersistenceBlocked -Scope Script -ValueOnly -ErrorAction SilentlyContinue)) {
        Stop-PreviewDetection 'A journal persistence failure has blocked further preview writes in this run; reconcile the journal manually.'
    }
    $target = $null
    if (-not [uri]::TryCreate($Uri, [UriKind]::Absolute, [ref]$target) -or $target.Scheme -ne 'https' -or
        $target.Authority -cne 'graph.microsoft.com' -or $target.UserInfo -or $target.Fragment -or $target.Query -or
        $target.AbsolutePath -cnotmatch '^/beta/security/rules/detectionRules(?:/[a-z0-9][a-z0-9_-]{0,127})?$') {
        Stop-PreviewDetection 'Unexpected Graph beta endpoint or pagination link; no request was sent.'
    }
    $collection = $target.AbsolutePath -ceq '/beta/security/rules/detectionRules'
    if (($collection -and $Method -cne 'POST') -or (-not $collection -and $Method -cnotin @('GET', 'PATCH'))) {
        Stop-PreviewDetection 'Unsupported preview Graph operation; lists, deletes and arbitrary writes are not allowed.'
    }
    if (-not (Test-PreviewDetectionGraphContext (Get-MgContext -ErrorAction Stop))) { Stop-PreviewDetection 'Graph context changed; stop and reinitialize preview support.' }
    $requestContext = Get-MgRequestContext -ErrorAction Stop
    $retry = Get-PreviewDetectionContextField $requestContext 'MaxRetry'
    if ($null -eq $retry) { Stop-PreviewDetection 'Graph SDK retry configuration is unavailable; cannot guarantee no write retries.' }
    try {
        Set-MgRequestContext -MaxRetry 0 -ErrorAction Stop | Out-Null
        $arguments = @{
            Method = $Method; Uri = $Uri; OutputType = 'Hashtable'; ErrorAction = 'Stop'
            Verbose = $false; Debug = $false; InformationAction = 'SilentlyContinue'; WarningAction = 'SilentlyContinue'
        }
        if ($null -ne $Body) { $arguments.Body = ConvertTo-Json -InputObject $Body -Depth 100 -Compress; $arguments.ContentType = 'application/json' }
        try { $response = Invoke-MgGraphRequest @arguments }
        catch {
            $status = Get-PreviewDetectionHttpStatus $_.Exception
            if ($Method -eq 'GET' -and $Allow404 -and $status -eq 404) { return $null }
            Stop-PreviewDetection "Graph $Method failed (HTTP $status; provider bodies suppressed). Check consent, active roles, licensing and onboarding. If a write was attempted its outcome is uncertain; reconcile the stable ID manually without retrying."
        }
        $data = ConvertTo-PreviewDetectionData $response
        if ($data -isnot [Collections.IDictionary] -or $data.Contains('@odata.nextLink')) { Stop-PreviewDetection 'Graph did not return a single inspectable detection rule; no pagination or success inference is permitted.' }
        return $data
    } finally {
        try { Set-MgRequestContext -MaxRetry $retry -ErrorAction Stop | Out-Null }
        catch { Stop-PreviewDetection 'Graph SDK retry settings could not be restored; stop this run and reset the request context manually.' }
    }
}

function Get-PreviewDetectionWritable($Rule) {
    $data = ConvertTo-PreviewDetectionData $Rule
    $writable = @{}
    foreach ($key in @('id', 'displayName', 'description', 'status', 'isEnabled', 'queryCondition', 'schedule', 'detectionAction')) {
        if ($data.Contains($key)) { $writable[$key] = $data[$key] }
    }
    # Only documented read-only/deprecated timestamps and OData annotations are excluded.
    foreach ($pair in @(@('queryCondition', 'lastModifiedDateTime'), @('schedule', 'nextRunDateTime'))) {
        if ($writable.Contains($pair[0]) -and $writable[$pair[0]] -is [Collections.IDictionary]) { $writable[$pair[0]].Remove($pair[1]) }
    }
    Remove-PreviewDetectionAnnotations $writable
    return $writable
}

function Remove-PreviewDetectionAnnotations($Value) {
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in @($Value.Keys)) {
            if ($key.StartsWith('@odata.')) { $Value.Remove($key) }
            else { Remove-PreviewDetectionAnnotations $Value[$key] }
        }
    } elseif ($Value -is [array]) {
        foreach ($child in $Value) { Remove-PreviewDetectionAnnotations $child }
    }
}

function Test-PreviewDetectionSupplied($Expected, $Observed) {
    if ($Expected -is [Collections.IDictionary]) {
        if ($Observed -isnot [Collections.IDictionary]) { return $false }
        foreach ($key in $Expected.Keys) {
            if (-not $Observed.Contains($key) -or -not (Test-PreviewDetectionSupplied $Expected[$key] $Observed[$key])) { return $false }
        }
        return $true
    }
    if ($Expected -is [array]) {
        if ($Observed -isnot [array] -or $Observed.Count -ne $Expected.Count) { return $false }
        for ($i = 0; $i -lt $Expected.Count; $i++) {
            if (-not (Test-PreviewDetectionSupplied $Expected[$i] $Observed[$i])) { return $false }
        }
        return $true
    }
    return (Get-PreviewDetectionHash $Expected) -ceq (Get-PreviewDetectionHash $Observed)
}

function Add-PreviewDetectionResult([string]$Id, [string]$Status, [string]$Reason, $Evidence = @{}) {
    $Evidence.Stage = 'PreviewContent'
    $Evidence.Requested = 'Scheduled Defender custom detection, disabled; manual enable and query review required.'
    $Evidence.ConnectorStatus = if ($Status -in @('Configured', 'AlreadyConfigured')) { 'Disabled (preview review required)' } else { 'N/A' }
    $previousRecord = Get-Variable CurrentRecord -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $script:CurrentRecord = $null
    try {
        Add-ConnectorResult "Preview detection / $Id" $Status $Reason 'Inspect the stable Graph rule ID and ownership journal. Reconcile uncertain outcomes manually; do not delete or adopt rules. Review query, licensing and onboarding in Defender before any manual enable.' $Evidence
    } finally { $script:CurrentRecord = $previousRecord }
    $script:ConnectorReport[$script:ConnectorReport.Count - 1].RowType = 'Content'
    if ($Status -in @('ActionRequired', 'Failed')) { $script:PreviewDetectionFailures++ }
}

function Invoke-PreviewDetectionPlan($Plan) {
    $id = $Plan.Id
    $uri = "https://graph.microsoft.com/beta/security/rules/detectionRules/$id"
    $evidence = @{ Attempted = $false; Verified = $false; Change = ''; Existing = 'Not verified.'; PolicyOrDiagnosticSetting = $uri }
    $intentSaved = $false
    try {
        if (Get-Variable PreviewDetectionPersistenceBlocked -Scope Script -ValueOnly -ErrorAction SilentlyContinue) {
            Stop-PreviewDetection 'A journal persistence failure has blocked further preview writes in this run; reconcile the journal manually.'
        }
        $owned = Get-Field $script:PreviewDetectionJournal.rules $id
        if ($null -ne $owned -and $owned.phase -cne 'Verified') {
            Stop-PreviewDetection 'Journal contains a pending, accepted or failed write. Preserve the rule and reconcile this stable ID manually; matching content is not adoption evidence.'
        }
        $existing = Invoke-PreviewDetectionGraph GET $uri -Allow404
        if ($null -ne $existing) {
            $existingStatus = [string](Get-Field $existing 'status' 'unknown')
            if ($existingStatus -cnotin @('enabled', 'disabled', 'autoDisabled', 'unknownFutureValue')) { $existingStatus = 'unknown' }
            $evidence.Existing = "Graph ID $id exists; status $existingStatus."
            if ((Get-Field $existing 'id') -cne $id) { Stop-PreviewDetection 'Graph response ID differs from the exact requested stable ID; no write is allowed.' }
            if ($null -eq $owned) { Stop-PreviewDetection 'Existing rule is unowned. It is preserved even if its content appears equivalent; no adoption or overwrite is allowed.' }
            $observed = Get-PreviewDetectionWritable $existing
            if ((Get-Field $observed 'status') -cne 'disabled' -or (Get-PreviewDetectionHash $observed) -cne $owned.observedHash) {
                Stop-PreviewDetection 'Owned rule was externally modified or is no longer disabled; preserve it and reconcile ownership manually.'
            }
            Assert-PreviewDetectionNoAutomation $observed
            if ($owned.desiredHash -ceq $Plan.DesiredHash) {
                $evidence.Verified = $true
                $evidence.Verification = "Exact ID $id, disabled status and full writable ownership fingerprint unchanged."
                Add-PreviewDetectionResult $id AlreadyConfigured 'Journal-owned disabled scheduled rule is unchanged; no query or ingestion validation is claimed.' $evidence
                return
            }
            if (-not [bool](Get-Variable UpdateOwnedPreviewDetections -ValueOnly -ErrorAction SilentlyContinue)) {
                Stop-PreviewDetection 'Catalog payload changed. Updating requires -UpdateOwnedPreviewDetections and exact per-rule UPDATE approval; existing rule preserved.'
            }
            $operation = 'UPDATE'
            $method = 'PATCH'
            $body = ConvertTo-PreviewDetectionData $Plan.Payload
            $body.Remove('id')
            Write-Warning "UPDATE $id replaces the reviewed writable declaration while keeping it disabled. Graph supplies no assumed atomic concurrency/ETag guarantee; keep other writers quiescent."
        } else {
            if ($null -ne $owned) { Stop-PreviewDetection 'Previously owned rule is missing; manual review is required, never automatic recreation.' }
            $evidence.Existing = "Exact Graph ID $id returned HTTP 404."
            $operation = 'CREATE'
            $method = 'POST'
            $body = $Plan.Payload
        }
        $evidence.Change = "$operation disabled scheduled detection $id"
        if (-not (Invoke-ConnectorChange $uri $evidence.Change)) {
            Add-PreviewDetectionResult $id Planned 'ShouldProcess prevented the write.' $evidence
            return
        }
        $priorHash = if ($null -ne $owned) { $owned.desiredHash } else { 'new rule' }
        Write-Host "Preview $operation ID $id; disabled; frequency $($Plan.Payload.schedule.frequency); sources: $((@($Plan.Sources | ForEach-Object { $_.Package + ' ' + $_.Version })) -join ', '); prior SHA256 $priorHash; desired SHA256 $($Plan.DesiredHash). Review the catalog declaration manually; query bodies are not logged."
        if ((Read-Host "Type $operation $id to approve this exact disabled scheduled rule") -cne "$operation $id") {
            Stop-PreviewDetection 'Exact per-rule write approval was not supplied; rule preserved.'
        }
        $latest = Invoke-PreviewDetectionGraph GET $uri -Allow404
        if ($operation -eq 'CREATE') {
            if ($null -ne $latest) { Stop-PreviewDetection 'Rule appeared before POST; it is unowned and must be preserved.' }
        } elseif ($null -eq $latest -or (Get-Field $latest 'id') -cne $id -or (Get-Field $latest 'status') -cne 'disabled' -or
            (Get-PreviewDetectionHash (Get-PreviewDetectionWritable $latest)) -cne $owned.observedHash) {
            Stop-PreviewDetection 'Rule changed immediately before PATCH; preserve it. No atomic concurrency guarantee is assumed.'
        }
        $entry = @{
            id = $id; sources = $Plan.Sources; desiredHash = $Plan.DesiredHash; observedHash = ''
            phase = 'Pending'; status = 'disabled'; operation = $operation
        }
        $script:PreviewDetectionJournal.rules[$id] = $entry
        Save-PreviewDetectionJournal
        $intentSaved = $true
        $evidence.Attempted = $true
        $writeUri = if ($operation -eq 'CREATE') { 'https://graph.microsoft.com/beta/security/rules/detectionRules' } else { $uri }
        $accepted = Invoke-PreviewDetectionGraph $method $writeUri $body
        if ((Get-Field $accepted 'id') -cne $id) { Stop-PreviewDetection 'Write response did not confirm the exact stable ID; outcome uncertain, reconcile manually.' }
        $entry.phase = 'Accepted'
        Save-PreviewDetectionJournal
        $verified = $false
        for ($attempt = 0; $attempt -lt 3; $attempt++) {
            if ($attempt -gt 0) { Start-Sleep -Seconds 1 }
            $readback = Invoke-PreviewDetectionGraph GET $uri -Allow404
            if ($null -eq $readback) { continue }
            if ((Get-Field $readback 'id') -cne $id) { Stop-PreviewDetection 'Readback returned a different ID; reconcile manually.' }
            $writable = Get-PreviewDetectionWritable $readback
            Assert-PreviewDetectionNoAutomation $writable
            if ((Get-Field $writable 'status') -cne 'disabled') { Stop-PreviewDetection 'Readback is not disabled; preserve it and reconcile manually.' }
            if (Test-PreviewDetectionSupplied $Plan.Payload $writable) { $verified = $true; break }
        }
        if (-not $verified) { Stop-PreviewDetection 'Bounded readback could not verify all supplied fields; do not retry the write or adopt the rule.' }
        $entry.observedHash = Get-PreviewDetectionHash $writable
        $entry.phase = 'Verified'
        Save-PreviewDetectionJournal
        $evidence.Verified = $true
        $evidence.Verification = "Exact ID $id, disabled status, supplied fields and observed writable fingerprint verified."
        Add-PreviewDetectionResult $id Configured 'Disabled scheduled preview rule persisted and read back. Manual query and enable review remains required.' $evidence
    } catch {
        if ($intentSaved) {
            $script:PreviewDetectionJournal.rules[$id].phase = 'Failed'
            try { Save-PreviewDetectionJournal } catch { Write-Warning "Preview journal remains uncertain for ID $id; preserve its prior Pending/Accepted record and reconcile manually." }
        }
        $reason = if ($_.Exception.Data.Contains('PreviewDetectionSafeReason')) { [string]$_.Exception.Data['PreviewDetectionSafeReason'] } else { 'Preview operation failed; provider bodies suppressed. Preserve this stable ID and reconcile manually before rerunning.' }
        Add-PreviewDetectionResult $id ActionRequired $reason $evidence
    }
}

function Invoke-PreviewDetectionConfiguration([string[]]$Names) {
    if (-not (Get-Variable PreviewDetectionFailures -Scope Script -ErrorAction SilentlyContinue)) { $script:PreviewDetectionFailures = 0 }
    $plans = @{}
    $blocked = $false
    try { $catalog = @(Available-Solutions | ForEach-Object { ConvertTo-PreviewDetectionData $_ }) }
    catch { Add-PreviewDetectionResult 'catalog' ActionRequired 'Official Content Hub catalog GET failed; no preview writes are allowed.'; return }
    foreach ($name in @($Names | Select-Object -Unique)) {
        try {
            $matches = @($catalog | Where-Object { (Get-Field (Get-Field $_ 'properties' @{}) 'displayName') -ceq $name })
            if ($matches.Count -eq 0) { Add-PreviewDetectionResult $name Skipped 'Exact display name is absent from the official catalog.'; continue }
            if ($matches.Count -ne 1) { Stop-PreviewDetection 'Exact catalog display name is ambiguous; no preview writes are allowed.' }
            $entry = $matches[0]
            $catalogId = [string](Get-Field $entry 'name' '')
            if ([string]::IsNullOrWhiteSpace($catalogId) -or $catalogId.StartsWith('[')) { Stop-PreviewDetection 'Catalog resource name is not a literal identity.' }
            $detailPath = "$script:WorkspaceId/providers/Microsoft.SecurityInsights/contentProductPackages/$([uri]::EscapeDataString($catalogId))?api-version=$ApiVersion"
            $detail = ConvertTo-PreviewDetectionData (Read-Arm $detailPath)
            $properties = Get-Field $detail 'properties' @{}
            $template = Get-Field $properties 'packagedContent'
            $version = [string](Get-Field $properties 'version' (Get-Field (Get-Field $entry 'properties' @{}) 'version' ''))
            if ($null -eq $template) { Stop-PreviewDetection 'Catalog detail has no inspectable packagedContent; no preview writes are allowed.' }
            $packagePlans = @(Get-PreviewDetectionPlans $template $catalogId $version)
            if ($packagePlans.Count -eq 0) { Add-PreviewDetectionResult $name Skipped 'No direct reviewed scheduled preview detection declarations; stored contentTemplates are inert.' }
            foreach ($plan in $packagePlans) {
                if ($plans.ContainsKey($plan.Id)) {
                    if ($plans[$plan.Id].DesiredHash -cne $plan.DesiredHash) { Stop-PreviewDetection 'Conflicting stable preview rule IDs across selected packages; all preview writes are blocked.' }
                    $plans[$plan.Id].Sources = @($plans[$plan.Id].Sources) + @($plan.Sources)
                } else { $plans[$plan.Id] = $plan }
            }
        } catch {
            $blocked = $true
            $reason = if ($_.Exception.Data.Contains('PreviewDetectionSafeReason')) { [string]$_.Exception.Data['PreviewDetectionSafeReason'] } else { 'Preview catalog detail or declaration inspection failed; provider bodies suppressed. No preview writes are allowed.' }
            Add-PreviewDetectionResult $name ActionRequired $reason
        }
    }
    foreach ($id in @($plans.Keys | Sort-Object)) {
        if ($blocked) { Add-PreviewDetectionResult $id ActionRequired 'A selected package failed preview preflight; all preview writes blocked before any Graph mutation.' }
        elseif ($WhatIfPreference) {
            Add-PreviewDetectionResult $id Planned 'Scheduled disabled declaration extracted; WhatIf performs no Graph authentication, requests, journal or lock writes.' @{ Change = "Review disabled scheduled detection $id"; PolicyOrDiagnosticSetting = "https://graph.microsoft.com/beta/security/rules/detectionRules/$id" }
        } else { Invoke-PreviewDetectionPlan $plans[$id] }
    }
}

function Get-StableName([string]$Text) {
    $bytes = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.ToLowerInvariant()))
    return ([guid]::new([byte[]]$bytes[0..15])).ToString()
}

function Invoke-ConnectorChange([string]$Target, [string]$Action) {
    return $script:ChangeCaller.ShouldProcess($Target, $Action)
}

$script:ConnectorReport = [Collections.Generic.List[object]]::new()
$script:ContentHubRuleFailures = @{}
$script:ContentHubDeploymentFailures = @{}
$script:ContentHubPackageDiagnostics = @{}
$script:Operation = @{}
$script:CurrentRecord = $null
$script:Candidates = [Collections.Generic.List[object]]::new()
$script:DiagnosticSources = @{}
$script:ExplicitDiagnosticSources = $PSBoundParameters.ContainsKey('DiagnosticResourceIds')
$script:UiOnlyKinds = @('StaticUI', 'GenericUI', 'Customizable')
$script:UiAdapters = @{
    Office365 = 'Office365'
    MicrosoftDefenderThreatIntelligence = 'MicrosoftThreatIntelligence'
    MicrosoftThreatIntelligence = 'MicrosoftThreatIntelligence'
    AzureActiveDirectoryIdentityProtection = 'IdentityProtection'
    AzureActiveDirectory = 'EntraDiagnostics'
    MicrosoftThreatProtection = 'MicrosoftThreatProtection'
    AzureSecurityCenter = 'AzureSecurityCenter'
    AzureActivity = 'AzureActivity'
    AzureStorageAccount = 'AzureStorageAccount'
    AzureNSG = 'AzureNSG'
    MicrosoftPurview = 'MicrosoftPurview'
    MicrosoftAzurePurview = 'MicrosoftPurview'
    WindowsSecurityEvents = 'WindowsSecurityEvents'
    SecurityEvents = 'SecurityEvents'
    WindowsFirewall = 'WindowsFirewall'
    WindowsFirewallAma = 'WindowsFirewallAma'
    MicrosoftCopilot = 'MicrosoftCopilot'
    OfficeIRM = 'OfficeIRM'
    ThreatIntelligence = 'ThreatIntelligence'
    ThreatIntelligenceTaxii = 'ThreatIntelligenceTaxii'
    ThreatIntelligenceTaxiiExport = 'ThreatIntelligenceTaxiiExport'
    ThreatIntelligenceUploadIndicatorsAPI = 'ThreatIntelligenceUploadIndicatorsAPI'
    MicrosoftDefenderForCloudTenantBased = 'MicrosoftDefenderForCloudTenantBased'
    PremiumMicrosoftDefenderForThreatIntelligence = 'ThreatIntelligencePremium'
    MicrosoftDefenderThreatIntelligencePremium = 'ThreatIntelligencePremium'
    AzureAdvancedThreatProtection = 'AzureAdvancedThreatProtection'
    MicrosoftDefenderAdvancedThreatProtection = 'MicrosoftDefenderAdvancedThreatProtection'
    MicrosoftCloudAppSecurity = 'MicrosoftCloudAppSecurity'
    OfficeATP = 'OfficeATP'
}
$script:NativeAdapters = @{
    Office365 = @{ Key = 'Office365'; Scope = 'tenantId'; Types = @('exchange', 'sharePoint', 'teams') }
    MicrosoftThreatIntelligence = @{ Key = 'MicrosoftThreatIntelligence'; Scope = 'tenantId'; Types = @('microsoftEmergingThreatFeed') }
    AzureActiveDirectory = @{ Key = 'IdentityProtection'; Scope = 'tenantId'; Types = @('alerts') }
    MicrosoftThreatProtection = @{ Key = 'MicrosoftThreatProtection'; Scope = 'tenantId'; Types = @('incidents', 'alerts') }
    AzureSecurityCenter = @{ Key = 'AzureSecurityCenter'; Scope = 'subscriptionId'; Types = @('alerts') }
}
$script:RetiredConnectorIds = @{
    SecurityEvents = 'SecurityEvents uses the retired MMA/Log Analytics agent.'
    WindowsFirewall = 'WindowsFirewall is the retired legacy connector, not WindowsFirewallAma.'
    ThreatIntelligence = 'ThreatIntelligence is the retired legacy Graph/TIP connector.'
    PremiumMicrosoftDefenderForThreatIntelligence = 'Premium Microsoft Defender Threat Intelligence is deprecated.'
    MicrosoftDefenderThreatIntelligencePremium = 'Premium Microsoft Defender Threat Intelligence is deprecated.'
}

function Add-ConnectorResult([string]$Connector, [string]$Status, [string]$Detail, [string]$NextSteps = '', $Evidence = $null) {
    if (-not $NextSteps) {
        $NextSteps = switch ($Status) {
            'Configured' { 'Verify incoming data in Sentinel and source licensing, consent, audit/export settings or source-side configuration.' }
            'AlreadyConfigured' { 'No change needed to the selected ARM configuration. Verify incoming data in Sentinel.' }
            'Planned' { 'No changes were applied because -WhatIf or ShouldProcess prevented the write.' }
            default { $Detail }
        }
    }
    $evidenceContext = if ($null -ne $Evidence) { $Evidence } else { $script:Operation }
    $attempted = [bool](Get-Field $evidenceContext 'Attempted' $false)
    $verified = Get-Field $evidenceContext 'Verified'
    $applied = switch ($Status) {
        'Configured' { [string](Get-Field $evidenceContext 'Change' '') }
        'AlreadyConfigured' { 'None (already configured)' }
        'Planned' { "None (planned only): $(Get-Field $evidenceContext 'Change' (Get-Field $evidenceContext 'Requested' ''))" }
        'Skipped' { 'None (intentionally skipped)' }
        'Discovered' { 'N/A (source discovery only)' }
        default {
            if ($attempted) { "Attempted: $(Get-Field $evidenceContext 'Change' '')" } else { 'None (not applied)' }
        }
    }
    $successful = if ($Status -eq 'Configured') { $true } elseif ($Status -eq 'Failed') { $false } else { $null }
    $script:ConnectorReport.Add([pscustomobject]@{
        Connector = $Connector
        ConnectorKey = $(if ($script:CurrentRecord) { [string]$script:CurrentRecord.Key } else { '' })
        RowType = 'Action'
        Status = $Status
        Detail = $Detail
        NextSteps = $NextSteps
        ConnectorStatus = [string](Get-Field $evidenceContext 'ConnectorStatus' 'Unknown')
        PolicyOrDiagnosticSetting = [string](Get-Field $evidenceContext 'PolicyOrDiagnosticSetting' 'N/A')
        ErrorMessage = $(if ($Status -eq 'Failed') { $Detail } else { '' })
        ConfigurationApplied = $applied
        AppliedSuccessfully = $successful
        ExistingConfiguration = [string](Get-Field $evidenceContext 'Existing' 'Not verified.')
        RequestedConfiguration = [string](Get-Field $evidenceContext 'Requested' '')
        ConfigurationVerified = $verified
        ConfigurationStage = $(if ((Get-Field $evidenceContext 'Stage' '')) { [string]$evidenceContext.Stage }
            elseif ($Connector -match '/ policy|/ policies' -or (Get-Field $evidenceContext 'ConnectorStatus' '') -match 'policy') { 'Policy' }
            else { 'SourceConfiguration' })
        RequirementStages = @()
        RemainingInputs = @()
        OverallOutcome = ''
        VerificationEvidence = [string](Get-Field $evidenceContext 'Verification' '')
        ChangesApplied = $(if ($Status -eq 'Configured') { $true } elseif ($attempted) { $null } else { $false })
        WriteAttempted = $attempted
        Sources = @($(if ($script:CurrentRecord) { $script:CurrentRecord.Sources }))
        Names = @($(if ($script:CurrentRecord) { $script:CurrentRecord.Names }))
        DeprecationReason = $(if ($script:CurrentRecord) { $script:CurrentRecord.DeprecationEvidence -join '; ' } else { '' })
        AdditionalConfiguration = @($(if ($script:CurrentRecord) { $script:CurrentRecord.Requirements }))
        Instructions = @($(if ($script:CurrentRecord) { $script:CurrentRecord.Instructions }))
    })
}

function Invoke-ConnectorWork([string]$Label, [scriptblock]$Work) {
    $previous = $script:Operation
    $script:Operation = @{}
    try { & $Work }
    catch {
        Add-ConnectorResult $Label 'Failed' $_.Exception.Message
        Write-Warning "${Label}: $($_.Exception.Message)"
    }
    finally { $script:Operation = $previous }
}

function Test-DeprecatedTitle([string]$Title) {
    return $Title -match '(?i)\b(deprecated|retired)\b'
}

function Read-DeprecationEvidence($Metadata, [string]$Source) {
    if ($Metadata -isnot [Collections.IDictionary]) { return }
    foreach ($field in @('isDeprecated', 'deprecated', 'isRetired', 'retired')) {
        $value = Get-Field $Metadata $field
        if ($value -eq $true) { "$Source/$field=true" }
    }
    foreach ($field in @('title', 'displayName', 'lifecycleStatus', 'status')) {
        $value = Get-Field $Metadata $field
        if ($value -is [string] -and (Test-DeprecatedTitle $value)) { "$Source/$field=$value" }
    }
}

function Resolve-ContentLiteral($Value, $Template, [int]$Depth = 0) {
    if ($Value -isnot [string] -or $Depth -gt 5) { return '' }
    if (-not $Value.StartsWith('[')) { return $Value }
    if ($Value -match "^\[(parameters|variables)\('([^']+)'\)\]$") {
        $section = Get-Field $Template $Matches[1] @{}
        $resolved = Get-Field $section $Matches[2]
        if ($Matches[1] -eq 'parameters') { $resolved = Get-Field $resolved 'defaultValue' }
        return Resolve-ContentLiteral $resolved $Template ($Depth + 1)
    }
    return ''
}

function Read-InstructionText($Steps) {
    foreach ($step in @($Steps)) {
        if ($step -isnot [Collections.IDictionary]) { continue }
        foreach ($field in @('title', 'description', 'descriptionMarkdown')) {
            $value = Get-Field $step $field
            if ($value -is [string] -and $value) { $value }
        }
        foreach ($field in @('instructions', 'instructionSteps')) {
            $nested = Get-Field $step $field
            if ($nested) { Read-InstructionText $nested }
        }
        if ((Get-Field $step 'type' '') -eq 'Markdown') {
            $parameters = Get-Field $step 'parameters' @{}
            foreach ($field in @('content', 'text')) {
                $value = Get-Field $parameters $field
                if ($value -is [string] -and $value) { $value }
            }
        }
    }
}

function Add-Candidate($Ui, [string[]]$Ids, [string]$Title, [string]$Source, $Instance = $null, [string]$NativeKind = '', [object[]]$Metadata = @(), [switch]$CopilotSource) {
    $ids = @($Ids | Where-Object { $_ -and -not $_.StartsWith('[') } | Select-Object -Unique)
    $names = @($Title)
    $deprecation = @(
        foreach ($item in @($Ui) + @($Metadata)) {
            Read-DeprecationEvidence $item $Source
            foreach ($field in @('title', 'displayName')) {
                $value = Get-Field $item $field
                if ($value -is [string] -and $value -and (-not $value.StartsWith('[') -or (Test-DeprecatedTitle $value))) { $names += $value }
            }
        }
    )
    $key = ''
    if ($CopilotSource) {
        $key = 'MicrosoftCopilot'
    } elseif ($NativeKind -and $script:NativeAdapters.ContainsKey($NativeKind)) {
        $key = $script:NativeAdapters[$NativeKind].Key
    } elseif (-not $NativeKind) {
        foreach ($id in $ids) {
            if ($script:UiAdapters.ContainsKey($id)) { $key = $script:UiAdapters[$id]; break }
        }
    } elseif ($NativeKind -in @('AzureAdvancedThreatProtection', 'MicrosoftDefenderAdvancedThreatProtection', 'MicrosoftCloudAppSecurity', 'OfficeATP')) {
        $key = $NativeKind
    } elseif ($NativeKind -and $script:RetiredConnectorIds.ContainsKey($NativeKind)) {
        $key = $script:UiAdapters[$NativeKind]
    }
    $retiredIds = if ($NativeKind) { @($NativeKind) } else { @($ids | Where-Object { $script:UiAdapters.ContainsKey($_) -and $script:UiAdapters[$_] -eq $key }) }
    foreach ($id in $retiredIds) {
        if ($script:RetiredConnectorIds.ContainsKey($id)) { $deprecation += $script:RetiredConnectorIds[$id] }
    }
    if ($NativeKind -and $key) { $ids = @("adapter:$key") }
    if ($key) { $ids += "adapter:$key" }
    if (-not $Title -or ($Title.StartsWith('[') -and -not (Test-DeprecatedTitle $Title))) { $Title = if ($ids.Count) { $ids[0] } else { $Source } }
    $instructions = @(Read-InstructionText (Get-Field $Ui 'instructionSteps' @()))
    $requirements = @(
        foreach ($field in @('permissions', 'customs', 'resourceProvider')) {
            $value = Get-Field $Ui $field
            if ($value) { "${field}: $(ConvertTo-Json -InputObject $value -Depth 30 -Compress)" }
        }
    )
    $requirementMetadata = @{}
    foreach ($field in @('permissions', 'dataTypes', 'connectivityCriterias', 'availability', 'customs', 'resourceProvider')) {
        $value = Get-Field $Ui $field
        if ($null -ne $value) { $requirementMetadata[$field] = $value }
    }
    $script:Candidates.Add(@{
        Key = $key
        Aliases = $ids
        Title = $Title
        Sources = @($Source)
        Names = @($names | Where-Object { $_ -and (-not $_.StartsWith('[') -or (Test-DeprecatedTitle $_)) } | Select-Object -Unique)
        DeprecationEvidence = @($deprecation | Select-Object -Unique)
        Instructions = $instructions
        Requirements = $requirements
        RequirementMetadata = @($(if ($requirementMetadata.Count) { $requirementMetadata }))
        Instances = @($(if ($null -ne $Instance) { $Instance }))
        CopilotSource = [bool]$CopilotSource
        UnsupportedTemplateKinds = @($(if ($null -eq $Instance -and $NativeKind -and -not $CopilotSource -and -not $script:NativeAdapters.ContainsKey($NativeKind)) { $NativeKind }))
    })
}

function Read-TemplateResources($Template) {
    if ($Template -is [string]) {
        try { $Template = ConvertFrom-Json $Template -AsHashtable -Depth 100 }
        catch {
            Write-Warning "Cannot parse installed connector template JSON: $($_.Exception.Message)"
            return
        }
    }
    if ($Template -isnot [Collections.IDictionary]) { return }
    foreach ($resource in @(Get-Field $Template 'resources' @())) {
        if ($resource -isnot [Collections.IDictionary]) { continue }
        $type = [string](Get-Field $resource 'type' '')
        if ($type -match '(^|/)(dataConnectors|dataConnectorDefinitions)$') {
            @{ Resource = $resource; Template = $Template }
        }
        Read-TemplateResources @{ resources = @(Get-Field $resource 'resources' @()); parameters = (Get-Field $Template 'parameters' @{}); variables = (Get-Field $Template 'variables' @{}) }
        if ($type -match '(^|/)deployments$') {
            Read-TemplateResources (Get-Field (Get-Field $resource 'properties' @{}) 'template')
        }
    }
}

function Add-TemplateInventory($Item, [string]$Source) {
    $properties = Get-Field $Item 'properties' $Item
    $contentId = [string](Get-Field $properties 'contentId' '')
    $title = [string](Get-Field $properties 'displayName' (Get-Field $Item 'name' $contentId))
    $main = Get-Field $properties 'mainTemplate' $Item
    $resources = @(Read-TemplateResources $main)
    if ($resources.Count -eq 0) {
        Add-Candidate @{} @($contentId) $title $Source -Metadata @($Item, $properties)
    }
    $index = 0
    foreach ($entry in $resources) {
        $index++
        $resource = $entry.Resource
        $rp = Get-Field $resource 'properties' @{}
        $ui = Get-Field $rp 'connectorUiConfig' (Get-Field $rp 'uiConfig' @{})
        $id = Resolve-ContentLiteral (Get-Field $ui 'id' '') $entry.Template
        $name = Resolve-ContentLiteral (Get-Field $resource 'name' '') $entry.Template
        $definitionName = Resolve-ContentLiteral (Get-Field $rp 'connectorDefinitionName' (Get-Field $rp 'dataConnectorDefinitionName' '')) $entry.Template
        $ids = @($id, $name, $definitionName)
        if ($resources.Count -eq 1 -or (-not $id -and -not $name)) { $ids += $contentId }
        $kind = [string](Get-Field $resource 'kind' '')
        $nativeKind = if ($kind -and $kind -notin $script:UiOnlyKinds -and [string](Get-Field $resource 'type' '') -match '(^|/)dataConnectors$') { $kind } else { '' }
        Add-Candidate $ui $ids ([string](Get-Field $ui 'title' $title)) "$Source/resource$index" -NativeKind $nativeKind -Metadata @($Item, $properties, $entry.Template, $resource, $rp) -CopilotSource:(Test-CopilotSource $resource)
    }
    foreach ($dependent in @(Get-Field $properties 'dependantTemplates' @())) {
        Add-TemplateInventory $dependent "$Source/dependant"
    }
}

function Merge-Inventory {
    $records = [Collections.Generic.List[object]]::new()
    foreach ($candidate in $script:Candidates) {
        $matches = @($records | Where-Object {
            $record = $_
            (-not $record.Key -or -not $candidate.Key -or $record.Key -eq $candidate.Key) -and
            @($record.Aliases | Where-Object { $_ -in $candidate.Aliases }).Count -gt 0
        })
        foreach ($match in $matches) {
            if (-not $candidate.Key) { $candidate.Key = $match.Key }
            $candidate.CopilotSource = $candidate.CopilotSource -or $match.CopilotSource
            foreach ($field in @('Aliases', 'Sources', 'Names', 'DeprecationEvidence', 'Instructions', 'Requirements', 'RequirementMetadata', 'Instances', 'UnsupportedTemplateKinds')) {
                $candidate[$field] = @($candidate[$field]) + @($match[$field])
            }
            $null = $records.Remove($match)
        }
        foreach ($field in @('Aliases', 'Sources', 'Names', 'DeprecationEvidence', 'Instructions', 'Requirements')) {
            $candidate[$field] = @($candidate[$field] | Select-Object -Unique)
        }
        $records.Add($candidate)
    }
    $records.ToArray()
}

function Get-SetupGuidance([string]$Key) {
    switch ($Key) {
        'Office365' { 'Verify Microsoft 365 audit licensing and unified audit logging for Exchange, SharePoint/OneDrive and Teams workloads, tenant administrator consent and OfficeActivity ingestion.' }
        'IdentityProtection' { 'Verify Entra ID Protection licensing, tenant security-administrator permissions and Identity Protection alert ingestion; do not duplicate this source through XDR.' }
        'MicrosoftThreatProtection' { 'Review duplicate incident-creation rules; advanced-hunting event streams require separate XDR connector-page setup. Verify Defender product licensing, tenant permissions and component coverage.' }
        'EntraDiagnostics' { 'Entra uses diagnosticSettings GET/PUT with the selected workspace ARM resource ID. Explicit -EntraLogCategories bypasses category discovery. All falls back to the six reference categories if discovery is unavailable; review additional categories separately. Verify tenant permissions, licenses and ingestion costs.' }
        'AzureActivity' { 'Verify subscription diagnostic setting permissions and Activity log ingestion.' }
        'AzureStorageAccount' { 'Automatically discovers existing storage blob/file/queue/table service resources in -SourceSubscriptionIds. Override discovery with -DiagnosticResourceIds. No storage services or metrics are created.' }
        'AzureNSG' { 'Automatically discovers NSGs in -SourceSubscriptionIds. This enables NSG diagnostic logs, not Network Watcher flow logs.' }
        'MicrosoftPurview' { 'Automatically discovers Microsoft.Purview/accounts in -SourceSubscriptionIds. Verify Purview source permissions and DataSensitivityLogEvent ingestion.' }
        'WindowsSecurityEvents' { 'Supply -WindowsSecurityEventMachineIds plus explicit -WindowsSecurityEventXPathQueries or an approved -WindowsSecurityEventDcrId. Missing AMA requires separate -InstallWindowsAzureMonitorAgent approval and an existing system-assigned VM identity. Azure Windows VMs only; Arc, private link/DCE, audit policy, networking and SecurityEvent ingestion require independent setup/verification.' }
        'WindowsFirewallAma' { 'Manual setup required: enable host firewall logging and configure AMA/DCR/DCE and machine associations from the connector page.' }
        'MicrosoftCopilot' { 'Use -ConfigureCopilot to opt into the reviewed CopilotGeneral/PurviewAudit adapter and workspace-group DCR/DCE setup. Optional -CopilotDataCollectionRuleId and -CopilotDataCollectionEndpointId select existing compatible resources. Verify Copilot licensing, unified audit logging, tenant consent and CopilotActivity ingestion separately.' }
        'AzureSecurityCenter' { 'Choose tenant-based Defender for Cloud manually, or rerun with -EnableLegacyDefenderForCloud to enable the legacy subscription alert connector.' }
        'MicrosoftThreatIntelligence' { 'Standard Microsoft Defender Threat Intelligence is not automatically configured here; verify connector-page support, feed entitlement and source prerequisites manually.' }
        { $_ -in @('ThreatIntelligence', 'ThreatIntelligenceTaxii', 'ThreatIntelligenceTaxiiExport', 'ThreatIntelligenceUploadIndicatorsAPI') } { 'Threat intelligence feed/API/TAXII connectors require endpoint, credential, app, feed or export choices and are left for manual connector-page configuration.' }
        { $_ -in @('OfficeATP', 'AzureAdvancedThreatProtection', 'MicrosoftDefenderAdvancedThreatProtection', 'MicrosoftCloudAppSecurity', 'OfficeIRM') } { 'Verify licensed XDR/source coverage and avoid duplicate standalone alerts; no standalone connection is created automatically.' }
        default { 'Open this installed connector in Sentinel > Data connectors and provide any required source scope, licensing, consent or credentials.' }
    }
}

function Get-NativeConfiguration($Instance, [string]$Kind, [string]$ScopeProperty, [string]$ScopeValue, [string[]]$DataTypes) {
    $types = Get-Field (Get-Field $Instance 'properties' @{}) 'dataTypes' @{}
    $states = foreach ($type in $DataTypes) {
        $state = Get-Field (Get-Field $types $type @{}) 'state' ''
        if ($state -notin @('Enabled', 'Disabled')) { $state = 'Unselected/unknown' }
        "$type=$state"
    }
    return "Kind=$Kind; source ${ScopeProperty}=$ScopeValue; workspace=$script:WorkspaceId; dataTypes: $($states -join ', ')"
}

function Get-NativeStatus($Instance, [string[]]$DataTypes) {
    $types = Get-Field (Get-Field $Instance 'properties' @{}) 'dataTypes' @{}
    if (@($types.Values | Where-Object { (Get-Field $_ 'state' '') -eq 'Enabled' }).Count) { return 'Enabled (ingestion unverified)' }
    if ($DataTypes.Count -gt 0 -and @($DataTypes | Where-Object { (Get-Field (Get-Field $types $_ @{}) 'state' '') -ne 'Disabled' }).Count -eq 0) { return 'Disabled' }
    return 'Unknown'
}

function Enable-NativeConnector([string]$Label, [string]$Kind, [string]$ScopeProperty, [string]$ScopeValue, [string[]]$DataTypes, [string]$ConnectorApiVersion = $ApiVersion) {
    if ($ScopeProperty -eq 'tenantId' -and $ScopeValue -ne $script:TenantId) {
        Add-ConnectorResult $Label 'ActionRequired' 'Existing native connector belongs to a different tenant; no API activation or retargeting permitted.'
        return
    }
    $script:Operation.PolicyOrDiagnosticSetting = 'N/A (native connector)'
    $matches = @($script:Connectors | Where-Object {
        (Get-Field $_ 'kind' '') -eq $Kind -and
        (Get-Field (Get-Field $_ 'properties' @{}) $ScopeProperty '') -eq $ScopeValue
    })
    if ($matches.Count -gt 1) { throw "Multiple $Kind connectors for $ScopeValue; resolve duplicates first." }
    $script:Operation.ConnectorStatus = if ($matches.Count) { Get-NativeStatus $matches[0] $DataTypes } else { 'Configuration incomplete' }
    $body = @{ kind = $Kind; properties = @{ $ScopeProperty = $ScopeValue; dataTypes = @{} } }
    $name = Get-StableName "$script:WorkspaceId|$Kind|$ScopeValue"
    $script:Operation.Existing = "No matching $Kind runtime connector in ARM GET; source ${ScopeProperty}=$ScopeValue; workspace=$script:WorkspaceId."
    if ($matches.Count -eq 1) {
        $name = $matches[0].name
        $body.properties = ConvertFrom-Json (ConvertTo-Json $matches[0].properties -Depth 100) -AsHashtable
        if ($matches[0].Contains('etag')) { $body.etag = $matches[0].etag }
        if (-not $body.properties.Contains('dataTypes')) { $body.properties.dataTypes = @{} }
        $existingTypes = Get-Field $body.properties 'dataTypes' @{}
        $script:Operation.Existing = Get-NativeConfiguration $matches[0] $Kind $ScopeProperty $ScopeValue $DataTypes
        $selected = @($existingTypes.Keys | Where-Object { (Get-Field $existingTypes[$_] 'state' '') -eq 'Enabled' })
        if ($selected.Count -gt 0) {
            $remaining = @($DataTypes | Where-Object { $_ -notin $selected })
            $script:Operation.Verified = $true
            $script:Operation.Verification = "ARM GET confirmed existing selection: $($script:Operation.Existing)"
            Add-ConnectorResult $Label 'AlreadyConfigured' "$Kind / $ScopeValue; enabled: $($selected -join ', '); disabled/unselected: $($remaining -join ', '). Selection preserved; ingestion not verified." "Selection preserved, including partial selections. Verify ingestion separately."
            return
        }
    } elseif (@($script:Inventory | Where-Object name -eq $name).Count -gt 0) {
        throw "Resource-name collision for $Kind; refusing to overwrite another connector."
    }
    if (-not $body.properties.Contains('dataTypes')) { $body.properties.dataTypes = @{} }
    $changed = $false
    foreach ($type in $DataTypes) {
        if (-not $body.properties.dataTypes.Contains($type)) { $body.properties.dataTypes[$type] = @{} }
        if ((Get-Field $body.properties.dataTypes[$type] 'state' '') -ne 'Enabled') {
            $body.properties.dataTypes[$type].state = 'Enabled'
            $changed = $true
        }
    }
    if ($Kind -eq 'MicrosoftThreatIntelligence' -and -not (Get-Field $body.properties.dataTypes.microsoftEmergingThreatFeed 'lookbackPeriod')) {
        $body.properties.dataTypes.microsoftEmergingThreatFeed.lookbackPeriod = [DateTime]::UtcNow.AddDays(-$ThreatIntelLookbackDays).ToString('o')
        $changed = $true
    }
    if (-not $changed) {
        $script:Operation.Verified = $true
        $script:Operation.Verification = "ARM GET: $($script:Operation.Existing)"
        Add-ConnectorResult $Label 'AlreadyConfigured' "$Kind / $ScopeValue; ingestion not verified."
        return
    }
    $script:Operation.Change = "$(if ($matches.Count -eq 0) { 'Create' } else { 'Update' }) native connector: $(Get-NativeConfiguration $body $Kind $ScopeProperty $ScopeValue $DataTypes)"
    $script:Operation.Requested = $script:Operation.Change
    if (-not (Invoke-ConnectorChange "$Label ($ScopeValue)" "Enable $($DataTypes -join ', ')")) {
        Add-ConnectorResult $Label 'Planned' "Would enable $Kind / ${ScopeValue}: $($DataTypes -join ', ')."
        return
    }
    $path = "$script:SentinelId/dataConnectors/${name}?api-version=$ConnectorApiVersion"
    $script:Operation.Attempted = $true
    $null = Read-Arm $path 'PUT' $body
    $script:Operation.Accepted = $true
    $actual = Read-Arm $path
    if ((Get-Field $actual 'kind' '') -ne $Kind -or
        (Get-Field (Get-Field $actual 'properties' @{}) $ScopeProperty '') -ne $ScopeValue -or
        (Get-Field $actual 'name' '') -ne $name) { throw "Native connector identity/source read-back mismatch at $path." }
    foreach ($type in $DataTypes) {
        $actualType = Get-Field (Get-Field (Get-Field $actual 'properties' @{}) 'dataTypes' @{}) $type @{}
        if ((Get-Field $actualType 'state' '') -ne 'Enabled') { throw "Read-back did not confirm $type enabled." }
    }
    $script:Operation.Verified = $true
    $script:Operation.Verification = "ARM GET read-back: $(Get-NativeConfiguration $actual $Kind $ScopeProperty $ScopeValue $DataTypes)"
    $script:Operation.ConnectorStatus = 'Enabled (ingestion unverified)'
    Add-ConnectorResult $Label 'Configured' "$Kind / $ScopeValue; ingestion not verified."
}

function Test-StorageQueueScope([string]$ResourceId) {
    return $ResourceId -match '^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\.Storage/storageAccounts/[a-z0-9]{3,24}/queueServices/default(?:/providers/Microsoft\.Insights/diagnosticSettings/[a-zA-Z0-9_.()-]+)?$'
}

function Get-ConnectorPolicies([string]$Key) {
    $specs = @(switch ($Key) {
        'AzureActivity' { ,@('2465583e-4e78-4c15-b6be-a36cbc7c8b0f', 'Activity') }
        'AzureNSG' { ,@('98a2e215-5382-489e-bd29-32e7190a39ba', 'NSG') }
        'AzureStorageAccount' {
            ,@('59759c62-9a22-4cdf-ae64-074495983fef', 'Account')
            ,@('b4fe1a3b-0715-4c6c-a5ea-ffc33cf823cb', 'Blob')
            ,@('7bd000e3-37c7-4928-9f31-86c4b77c5c45', 'Queue')
            ,@('2fb86bf3-d221-43d1-96d1-2434af34eaa0', 'Table')
            ,@('25a70cc8-2bd4-47f1-90b6-1478e4662c96', 'File')
        }
    })
    foreach ($spec in $specs) {
        $type = switch ($spec[1]) {
            Activity { 'Microsoft.Resources/subscriptions' }
            NSG { 'Microsoft.Network/networkSecurityGroups' }
            Account { 'Microsoft.Storage/storageAccounts' }
            default { "Microsoft.Storage/storageAccounts/$($spec[1].ToLowerInvariant())Services" }
        }
        @{ Id = "/providers/Microsoft.Authorization/policyDefinitions/$($spec[0])"; Kind = $spec[1]; Type = $type }
    }
}

function ConvertTo-PolicyCanonical($Value) {
    if ($Value -is [Collections.IDictionary]) {
        $ordered = [ordered]@{}
        $keys = [string[]]@($Value.Keys)
        [Array]::Sort($keys, [StringComparer]::Ordinal)
        foreach ($key in $keys) { $ordered[$key] = ConvertTo-PolicyCanonical $Value[$key] }
        return $ordered
    }
    if ($Value -is [array]) {
        return ,@($Value | ForEach-Object { ConvertTo-PolicyCanonical $_ })
    }
    return $Value
}

function Get-ConnectorPolicyContractHash($Definition) {
    $p = Get-Field $Definition 'properties' @{}
    $schema = @{}
    foreach ($key in (Get-Field $p 'parameters' @{}).Keys) {
        $schema[$key] = @{}
        foreach ($field in @('type', 'allowedValues', 'defaultValue')) {
            if ($p.parameters[$key].Contains($field)) { $schema[$key][$field] = $p.parameters[$key][$field] }
        }
    }
    $contract = ConvertTo-PolicyCanonical @{ mode = $p.mode; parameters = $schema; policyRule = $p.policyRule }
    $json = ConvertTo-Json -InputObject $contract -Depth 100 -Compress
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))
}

function Stop-ConnectorPolicySetup([string]$Message) {
    $exception = [InvalidOperationException]::new($Message)
    $exception.Data['PolicyActionRequired'] = $true
    throw $exception
}

function Read-OptionalConnectorPolicyResource([string]$Path) {
    try {
        $resource = Read-Arm $Path
        if ($resource -isnot [Collections.IDictionary] -or -not $resource.Contains('properties')) {
            throw "Invalid ARM policy resource response: $Path"
        }
        return $resource
    } catch { if ($_.Exception.Data['ArmStatusCode'] -ne 404) { throw } }
}

function Assert-ConnectorPolicyContract($Definition, $Spec, $Parameters) {
    # Azure/azure-policy reviewed contracts (2026-09-28). Hash includes the entire
    # executable rule/template plus parameter types/defaults/allowed values/mode.
    # No downloaded policy instructions are executed; unknown drift fails closed.
    $reviewed = @{
        Activity = @('1.0.0', 'A2904EA2A507427124DD83480479535D92DD20B0F2F2DDC84CBC20AAC5B60302')
        NSG = @('1.0.0', '95F2EA46605C6478538C62FCF2EF96DD7E87E3ED85D096D00247E78739129C16')
        Account = @('4.0.0', '8B8C5E2FE152EDA6C0E153FF7E15FB6D4FDAB967B981D2460D4D62B9F781779C')
        Blob = @('4.0.0', 'A4E35AB39E48EC3944D166C1C36E57D393C2D02BB1DA803478FA6EE450E01B0D')
        Queue = @('4.0.1', '4BE96C6FB7C45B0BD13AEE3FC89DDAC575C34155258A0D143847CE7AED164337')
        Table = @('4.0.1', '8C7B2B0748888122A791549E42DD8B2E35F3C8C4C6A84D3E81CA888EACC6E26D')
        File = @('4.0.0', '4ADFA3924F5748A5D8886569453085664C9B86CD64D43D702AA18CFB9B29F840')
    }
    $known = @(Get-ConnectorPolicies AzureActivity) + @(Get-ConnectorPolicies AzureNSG) + @(Get-ConnectorPolicies AzureStorageAccount)
    if (@($known | Where-Object { $_.Id -eq $Spec.Id -and $_.Kind -eq $Spec.Kind -and $_.Type -eq $Spec.Type }).Count -ne 1) {
        Stop-ConnectorPolicySetup 'Unreviewed policy identity/target.'
    }
    $p = Get-Field $Definition 'properties' @{}
    $version = [string](Get-Field (Get-Field $p 'metadata' @{}) 'version' '')
    if ((Get-Field $Definition 'id' '') -ne $Spec.Id -or (Get-Field $p 'policyType' '') -ne 'BuiltIn' -or
        $version -cne $reviewed[$Spec.Kind][0] -or
        (Get-ConnectorPolicyContractHash $Definition) -cne $reviewed[$Spec.Kind][1]) {
        Stop-ConnectorPolicySetup "Unreviewed live definition/version/schema: $($Spec.Id) version=$version. No assignment, grants or remediation. Review the updated built-in contract."
    }
    $roles = @($p.policyRule.then.details.roleDefinitionIds)
    $expected = @('749f88d5-cbae-40b8-bcfc-e573ddc772fa', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
    if ($roles.Count -ne 2 -or @($expected | Where-Object { "/providers/Microsoft.Authorization/roleDefinitions/$_" -notin $roles }).Count) {
        Stop-ConnectorPolicySetup 'Unexpected policy identity role requirements.'
    }
    if ($p.parameters.Count -ne $Parameters.Count) { Stop-ConnectorPolicySetup 'Unexpected policy parameter count.' }
    foreach ($name in $Parameters.Keys) {
        $value = $Parameters[$name].value
        $entry = Get-Field $p.parameters $name @{}
        $type = if ($value -is [bool]) { 'Boolean' } else { 'String' }
        if ((Get-Field $entry 'type' '') -ne $type -or
            ($entry.Contains('allowedValues') -and $value -cnotin $entry.allowedValues)) {
            Stop-ConnectorPolicySetup "Unsupported policy parameter: $name."
        }
    }
    return $version
}

function Get-ConnectorPolicyParameters($Spec, [string]$SettingName) {
    $parameters = @{ logAnalytics = @{ value = $script:WorkspaceId }; effect = @{ value = 'DeployIfNotExists' } }
    switch ($Spec.Kind) {
        Activity { $parameters.logsEnabled = @{ value = 'True' } }
        NSG {
            $parameters.diagnosticsSettingNameToUse = @{ value = $SettingName }
            $parameters.NetworkSecurityGroupEventEnabled = @{ value = 'True' }
            $parameters.NetworkSecurityGroupRuleCounterEnabled = @{ value = 'True' }
        }
        default {
            $parameters.profileName = @{ value = $SettingName }
            $parameters.metricsEnabled = @{ value = ($Spec.Kind -eq 'Account') }
            if ($Spec.Kind -ne 'Account') { $parameters.logsEnabled = @{ value = $true } }
        }
    }
    return $parameters
}

function Test-ExactConnectorPolicyDiagnostic($Setting, $Spec, [string]$Name) {
    if ((Get-Field $Setting 'name' '') -ne $Name) { return $false }
    $p = Get-Field $Setting 'properties' @{}
    if ((Get-Field $p 'workspaceId' '') -ne $script:WorkspaceId -or
        (Get-Field $p 'logAnalyticsDestinationType' '') -notin @('', 'AzureDiagnostics', $null)) { return $false }
    foreach ($key in $p.Keys) {
        if ($key -notin @('workspaceId', 'logs', 'metrics', 'logAnalyticsDestinationType') -and $null -ne $p[$key]) { return $false }
    }
    $categories = @(switch ($Spec.Kind) {
        Activity { 'Administrative'; 'Security'; 'ServiceHealth'; 'Alert'; 'Recommendation'; 'Policy'; 'Autoscale'; 'ResourceHealth' }
        NSG { 'NetworkSecurityGroupEvent'; 'NetworkSecurityGroupRuleCounter' }
        Account {}
        default { 'StorageRead'; 'StorageWrite'; 'StorageDelete' }
    })
    $logs = @(Get-Field $p 'logs' @())
    if ($logs.Count -ne $categories.Count) { return $false }
    foreach ($category in $categories) {
        $matching = @($logs | Where-Object { (Get-Field $_ 'category' '') -ceq $category -and (Get-Field $_ 'enabled') -ceq $true })
        if ($matching.Count -ne 1 -or (Get-Field (Get-Field $matching[0] 'retentionPolicy' @{}) 'enabled' $false) -ne $false) { return $false }
    }
    $metrics = @(Get-Field $p 'metrics' @())
    if ($Spec.Kind -in @('Activity', 'NSG')) { return $metrics.Count -eq 0 }
    if ($metrics.Count -ne 1) { return $false }
    return (Get-Field $metrics[0] 'category' '') -ceq 'AllMetrics' -and
        (Get-Field $metrics[0] 'enabled') -ceq ($Spec.Kind -eq 'Account') -and
        (Get-Field (Get-Field $metrics[0] 'retentionPolicy' @{}) 'enabled' $false) -eq $false
}

function Get-ConnectorPolicyExclusions($Spec, [string]$Scope, [switch]$AllCurrentResources) {
    $assignmentName = 'sc-' + (Get-StableName "$Scope|$script:WorkspaceId|$($Spec.Id)").Replace('-', '').Substring(0, 20)
    $settingName = if ($Spec.Kind -eq 'Activity') { 'subscriptionToLa' } else { "sentinel-policy-$assignmentName" }
    if ($Spec.Kind -eq 'Activity') {
        $settings = @(Read-ArmList "$Scope/providers/Microsoft.Insights/diagnosticSettings?api-version=$MonitorApiVersion")
        if ($settings.Count -and ($AllCurrentResources -or @($settings | Where-Object { -not (Test-ExactConnectorPolicyDiagnostic $_ $Spec $settingName) }).Count)) { $Scope }
        return
    }
    $type = if ($Spec.Kind -eq 'NSG') { $Spec.Type } else { 'Microsoft.Storage/storageAccounts' }
    $filter = [uri]::EscapeDataString("resourceType eq '$type'")
    foreach ($source in @(Read-ArmList "$Scope/resources?api-version=2021-04-01&`$filter=$filter")) {
        $id = [string](Get-Field $source 'id' '')
        if ((Get-Field $source 'type' '') -ne $type -or
            $id -notmatch ('^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/' + [regex]::Escape($type) + '/[^/?#]+$') -or
            -not $id.StartsWith("$Scope/", [StringComparison]::OrdinalIgnoreCase)) {
            Stop-ConnectorPolicySetup "Unexpected source resource during policy exclusion preflight: $id"
        }
        if ($AllCurrentResources) { $id; continue }
        $ids = @($id)
        if ($Spec.Kind -notin @('NSG', 'Account')) {
            $service = $Spec.Type.Split('/')[-1]
            $ids = @(Read-ArmList "$id/${service}?api-version=2023-05-01" | ForEach-Object {
                $serviceId = [string](Get-Field $_ 'id' '')
                if ($serviceId -ne "$id/$service/default") { Stop-ConnectorPolicySetup "Unexpected storage service: $serviceId" }
                $serviceId
            })
        }
        foreach ($sourceId in $ids) {
            $settings = @(Read-ArmList "$sourceId/providers/Microsoft.Insights/diagnosticSettings?api-version=$MonitorApiVersion")
            # Only an exact already-generated policy setting is harmless on rerun.
            # Foreign names, extra destinations, Dedicated routing or customized
            # categories/retention require exclusion before any policy operation.
            if (@($settings | Where-Object { -not (Test-ExactConnectorPolicyDiagnostic $_ $Spec $settingName) }).Count) { $id; break }
        }
    }
}

function Test-ConnectorPolicyExcluded([string]$ResourceId, [string[]]$Exclusions) {
    return @($Exclusions | Where-Object {
        $ResourceId -eq $_ -or $ResourceId.StartsWith("$($_.TrimEnd('/'))/", [StringComparison]::OrdinalIgnoreCase)
    }).Count -gt 0
}

function Assert-NoConnectorPolicyConflict($Spec, [string]$Scope, [string]$AssignmentId) {
    # Unfiltered list includes inherited/descendant assignments. Inspect initiatives,
    # not just directly assigned definitions, to avoid an unnoticed duplicate DINE.
    foreach ($assignment in @(Read-ArmList "$Scope/providers/Microsoft.Authorization/policyAssignments?api-version=2024-04-01")) {
        if ((Get-Field $assignment 'id' '') -eq $AssignmentId) { continue }
        $p = Get-Field $assignment 'properties' @{}
        $definitionId = [string](Get-Field $p 'policyDefinitionId' '')
        $ids = @($definitionId -replace '/versions/[^/]+$', '')
        if ($definitionId -match '/policySetDefinitions/') {
            $set = Read-Arm "${definitionId}?api-version=2023-04-01"
            $ids = @((Get-Field (Get-Field $set 'properties' @{}) 'policyDefinitions' @()) | ForEach-Object {
                [string](Get-Field $_ 'policyDefinitionId' '') -replace '/versions/[^/]+$', ''
            })
        }
        if ($Spec.Id -in $ids) {
            Stop-ConnectorPolicySetup "Potential overlapping direct/initiative assignment $($assignment.id) uses $($Spec.Id). Existing parameters, exclusions, exemptions and identity are preserved; ask its owner to review instead of duplicating it."
        }
        $known = @(Get-ConnectorPolicies AzureActivity) + @(Get-ConnectorPolicies AzureNSG) + @(Get-ConnectorPolicies AzureStorageAccount)
        foreach ($otherId in $ids) {
            if (-not $otherId -or $otherId -notmatch '^/(?:subscriptions/[^/]+/|providers/Microsoft.Management/managementGroups/[^/]+/)?providers/Microsoft.Authorization/policyDefinitions/[^/?#]+$') {
                Stop-ConnectorPolicySetup "Cannot safely inspect policy reference in $($assignment.id); resolve it before adding diagnostic policies."
            }
            # The seven reviewed definitions target distinct resource types.
            # Other diagnostic policies may overlap even with a different ID.
            $other = Read-Arm "${otherId}?api-version=2023-04-01"
            $otherSpec = @($known | Where-Object Id -eq $otherId)
            if ($otherSpec.Count) {
                $null = Assert-ConnectorPolicyContract $other $otherSpec[0] (Get-ConnectorPolicyParameters $otherSpec[0] 'schema-validation-only')
                continue
            }
            $rule = Get-Field (Get-Field $other 'properties' @{}) 'policyRule'
            if (-not $rule) { Stop-ConnectorPolicySetup "Policy rule unavailable for $otherId; cannot establish nonoverlap." }
            if ((ConvertTo-Json $rule -Depth 100 -Compress) -match '(?i)diagnosticSettings|templateLink') {
                Stop-ConnectorPolicySetup "Unreviewed diagnostic/linked-deployment policy $otherId in $($assignment.id) could overlap source destinations. No new assignment/grants/remediation; review scope and exclusions with its owner."
            }
        }
    }
}

function Assert-ConnectorPolicyAssignment($Actual, $Expected, [string]$Id) {
    $p = Get-Field $Actual 'properties' @{}
    if ((Get-Field $Actual 'id' '') -ne $Id -or (Get-Field $Actual 'location' '') -ne $Expected.location -or
        (Get-Field (Get-Field $Actual 'identity' @{}) 'type' '') -ne 'SystemAssigned' -or
        (Get-Field $p 'policyDefinitionId' '') -ne $Expected.properties.policyDefinitionId -or
        (Get-Field $p 'definitionVersion' '') -cne $Expected.properties.definitionVersion -or
        (Get-Field $p 'enforcementMode' '') -ne 'Default' -or
        (Get-Field $p 'scope' '') -ne $Expected.properties.scope -or
        @(Get-Field $p 'overrides' @()).Count -or @(Get-Field $p 'resourceSelectors' @()).Count -or
        (Get-Field (Get-Field $p 'metadata' @{}) 'managedBy' '') -ne 'Scout-SentinelConnectorPolicies-v1' -or
        (Get-Field (Get-Field $p 'metadata' @{}) 'workspaceId' '') -ne $script:WorkspaceId) {
        Stop-ConnectorPolicySetup "Existing assignment/readback conflict at $Id. No takeover, enforcement changes, retargeting, version changes or role grants."
    }
    $wanted = ConvertTo-Json (ConvertTo-PolicyCanonical $Expected.properties.parameters) -Depth 30 -Compress
    $actualParameters = ConvertTo-Json (ConvertTo-PolicyCanonical (Get-Field $p 'parameters' @{})) -Depth 30 -Compress
    if ($wanted -cne $actualParameters) { Stop-ConnectorPolicySetup "Existing policy parameters differ at $Id; no changes." }
    foreach ($exclusion in $Expected.properties.notScopes) {
        if (-not (Test-ConnectorPolicyExcluded $exclusion @(Get-Field $p 'notScopes' @()))) {
            Stop-ConnectorPolicySetup "Assignment $Id must exclude $exclusion to preserve existing diagnostics/routing. No automatic assignment update, grant or remediation; add the exclusion through an independently reviewed change first."
        }
    }
}

function Enable-ConnectorPolicyIdentityRoles([string]$Label, [string]$Scope, [string]$Principal) {
    $guid = [guid]::Empty
    if (-not [guid]::TryParse($Principal, [ref]$guid)) { Stop-ConnectorPolicySetup 'Policy identity principal is pending; rerun before grants/remediation.' }
    # Monitoring Contributor is needed on source deployments/diagnostics; do not
    # grant Log Analytics Contributor across the source subscription unnecessarily.
    $grants = @(
        @{ Scope = $Scope; Role = '749f88d5-cbae-40b8-bcfc-e573ddc772fa'; Name = 'Monitoring Contributor' }
        @{ Scope = $script:WorkspaceId; Role = '92aaf0da-9dab-42b6-94a3-d43ce8d16293'; Name = 'Log Analytics Contributor' }
    )
    $ready = $true
    foreach ($grant in $grants) {
        $filter = [uri]::EscapeDataString("principalId eq '$Principal'")
        $roles = @(Read-ArmList "$($grant.Scope)/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01&`$filter=$filter")
        $matches = @($roles | Where-Object {
            $p = Get-Field $_ 'properties' @{}
            $roleScope = [string](Get-Field $p 'scope' '')
            (Get-Field $p 'principalId' '') -eq $Principal -and
            ([string](Get-Field $p 'roleDefinitionId' '')).Split('/')[-1] -eq $grant.Role -and
            -not (Get-Field $p 'condition') -and $roleScope -and
            ($roleScope -eq $grant.Scope -or $grant.Scope.StartsWith("$roleScope/", [StringComparison]::OrdinalIgnoreCase))
        })
        $description = "principal=$Principal; $($grant.Name) ($($grant.Role)); scope=$($grant.Scope)"
        if ($matches.Count) {
            Add-ConnectorResult "$Label / identity" 'PolicyRoleVerified' "$description; existing unconditional grant(s): $(@($matches | ForEach-Object { $_.id }) -join ', '). Effective RBAC propagation is not inferred." '' @{ ConnectorStatus = 'Not assessed (policy identity)' }
            continue
        }
        if (-not $GrantConnectorPolicyRoles) {
            Add-ConnectorResult "$Label / identity" 'ActionRequired' "Missing verifiable grant: $description. Separately authorize -GrantConnectorPolicyRoles, or have an RBAC administrator grant it." '' @{ ConnectorStatus = 'Not assessed (policy identity)' }
            $ready = $false
            continue
        }
        $roleId = "/subscriptions/$($grant.Scope.Split('/')[2])/providers/Microsoft.Authorization/roleDefinitions/$($grant.Role)"
        $name = Get-StableName "$($grant.Scope)|$Principal|$($grant.Role)"
        $id = "$($grant.Scope)/providers/Microsoft.Authorization/roleAssignments/$name"
        $path = "${id}?api-version=2022-04-01"
        if (Read-OptionalConnectorPolicyResource $path) { Stop-ConnectorPolicySetup "Role assignment ID collision: $id. Existing grant left unchanged." }
        if (-not (Invoke-ConnectorChange $id "Privileged grant: $description")) {
            Add-ConnectorResult "$Label / identity" 'Planned' "Would grant $description at $id." '' @{ ConnectorStatus = 'Not assessed (policy identity)' }
            $ready = $false
            continue
        }
        $script:Operation.Attempted = $true
        $script:Operation.Change = "Grant $description; id=$id"
        $null = Read-Arm $path 'PUT' @{ properties = @{ principalId = $Principal; principalType = 'ServicePrincipal'; roleDefinitionId = $roleId } }
        $actual = Read-Arm $path
        $p = Get-Field $actual 'properties' @{}
        if ((Get-Field $actual 'id' '') -ne $id -or (Get-Field $p 'principalId' '') -ne $Principal -or
            (Get-Field $p 'roleDefinitionId' '') -ne $roleId -or (Get-Field $p 'scope' '') -ne $grant.Scope -or
            (Get-Field $p 'condition')) { throw "Role assignment readback mismatch at $id; inspect manually." }
        Add-ConnectorResult "$Label / identity" 'PolicyRoleGranted' "ARM verified $id; $description. RBAC propagation is asynchronous; remediation is deferred until a later run." '' @{
            Attempted = $true; Verified = $true; Change = $script:Operation.Change
            ConnectorStatus = 'Not assessed (policy identity)'; PolicyOrDiagnosticSetting = $id
        }
        # A GET proves the assignment exists, not that effective RBAC has propagated.
        $ready = $false
    }
    return $ready
}

function Invoke-ConnectorPolicyRemediation([string]$Label, [string]$Scope, [string]$AssignmentId) {
    $root = "$Scope/providers/Microsoft.PolicyInsights/remediations"
    $name = "sc-$((Get-StableName $AssignmentId).Replace('-', '').Substring(0, 20))-$ConnectorRemediationRunId"
    $id = "$root/$name"
    $path = "${id}?api-version=2021-10-01"
    $tasks = @(Read-ArmList "${root}?api-version=2021-10-01" | Where-Object {
        (Get-Field (Get-Field $_ 'properties' @{}) 'policyAssignmentId' '') -eq $AssignmentId
    })
    $active = @($tasks | Where-Object {
        (Get-Field $_.properties 'provisioningState' '') -notin @('Succeeded', 'Failed', 'Canceled', 'Cancelled')
    })
    $actual = if ($active.Count) { Read-Arm "$($active[0].id)?api-version=2021-10-01" } else { Read-OptionalConnectorPolicyResource $path }
    $submitted = $false
    if (-not $actual) {
        if (-not (Invoke-ConnectorChange $id "Submit asynchronous ReEvaluateCompliance for $AssignmentId; no rollback; monitor deployments/charges")) {
            Add-ConnectorResult "$Label / remediation" 'Planned' "Would submit $id for $AssignmentId." '' @{ ConnectorStatus = 'Not assessed (policy remediation)' }
            return
        }
        $script:Operation.Attempted = $true
        $script:Operation.Change = "Submit remediation $id for $AssignmentId"
        $null = Read-Arm $path 'PUT' @{ properties = @{ policyAssignmentId = $AssignmentId; resourceDiscoveryMode = 'ReEvaluateCompliance' } }
        $submitted = $true
        $actual = Read-OptionalConnectorPolicyResource $path
        if (-not $actual) {
            Add-ConnectorResult "$Label / remediation" 'RemediationPending' "Submitted $id; readback not yet available. No completion confirmed." 'Inspect this exact remediation ID; rerun observes the same ID, not a fresh task.' @{
                Attempted = $true; ConnectorStatus = 'Not assessed (policy remediation)'; PolicyOrDiagnosticSetting = $id
            }
            return
        }
    }
    $id = [string](Get-Field $actual 'id' $id)
    $p = Get-Field $actual 'properties' @{}
    if ((Get-Field $p 'policyAssignmentId' '') -ne $AssignmentId -or
        (Get-Field $p 'resourceDiscoveryMode' '') -ne 'ReEvaluateCompliance') {
        Stop-ConnectorPolicySetup "Remediation $id uses unexpected parameters; not replaced."
    }
    $state = [string](Get-Field $p 'provisioningState' 'Unknown')
    $failed = Get-Field (Get-Field $p 'deploymentStatus' @{}) 'failedDeployments' 0
    $status = if ($state -in @('Failed', 'Canceled', 'Cancelled') -or $failed -gt 0) { 'Failed' }
        elseif ($state -eq 'Succeeded') { 'RemediationCompleted' } else { 'RemediationPending' }
    Add-ConnectorResult "$Label / remediation" $status "Remediation=$id; assignment=$AssignmentId; state=$state; failedDeployments=$failed. This does not verify source ingestion." 'Monitor Policy Insights deployments and source routing. Reruns do not resubmit this cycle; a separate approved cycle requires a new -ConnectorRemediationRunId. Queue/Table may need recurring cycles; no schedule is created.' @{
        Attempted = $submitted; Verified = ($status -eq 'RemediationCompleted')
        ConnectorStatus = 'Not assessed (policy remediation)'; PolicyOrDiagnosticSetting = $id
    }
}

function Enable-ReviewedConnectorPolicy([string]$Label, $Spec, [string]$Scope) {
    $script:Operation = @{ ConnectorStatus = 'Not assessed (policy only)'; PolicyOrDiagnosticSetting = $Spec.Id }
    try {
        if ($Scope -notmatch '^/subscriptions/([0-9a-f-]{36})(?:/resourceGroups/[^/?#]+)?$' -or
            $Scope.Split('/')[2] -notin $SourceSubscriptionIds) {
            Stop-ConnectorPolicySetup "Policy scope $Scope must be an explicit subscription/resource-group ARM scope within SourceSubscriptionIds."
        }
        if ($Spec.Kind -eq 'Activity' -and $Scope -match '/resourceGroups/') {
            Stop-ConnectorPolicySetup 'Azure Activity policy requires an explicitly approved subscription scope.'
        }
        if ($Spec.Kind -eq 'Account' -and -not $IncludeStorageMetricsPolicy) {
            Stop-ConnectorPolicySetup 'Storage-account AllMetrics policy requires separate -IncludeStorageMetricsPolicy cost approval. Service-log policies are independent.'
        }
        $name = 'sc-' + (Get-StableName "$Scope|$script:WorkspaceId|$($Spec.Id)").Replace('-', '').Substring(0, 20)
        $id = "$Scope/providers/Microsoft.Authorization/policyAssignments/$name"
        $path = "${id}?api-version=2024-04-01"
        $parameters = Get-ConnectorPolicyParameters $Spec "sentinel-policy-$name"
        $definition = Read-Arm "$($Spec.Id)?api-version=2023-04-01"
        $version = Assert-ConnectorPolicyContract $definition $Spec $parameters
        Assert-NoConnectorPolicyConflict $Spec $Scope $id
        $current = Read-OptionalConnectorPolicyResource $path
        $exclusions = @(Get-ConnectorPolicyExclusions $Spec $Scope -AllCurrentResources:(-not $current) | Select-Object -Unique)
        $body = @{ location = $script:Region; identity = @{ type = 'SystemAssigned' }; properties = @{
            displayName = "Sentinel $($Spec.Kind) to $script:Workspace"
            scope = $Scope; policyDefinitionId = $Spec.Id; definitionVersion = $version
            enforcementMode = 'Default'; parameters = $parameters; notScopes = $exclusions
            metadata = @{ managedBy = 'Scout-SentinelConnectorPolicies-v1'; workspaceId = $script:WorkspaceId }
        } }
        $script:Operation.PolicyOrDiagnosticSetting = $id
        $details = "Assignment=$id; definition=$($Spec.Id); exact version=$version; scope=$Scope; workspace=$script:WorkspaceId; parameters=$(ConvertTo-Json $parameters -Depth 10 -Compress); exclusions=$($exclusions -join ', '); identity location=$script:Region."
        $details += ' Future-resource diagnostics only; existing source settings/routing excluded. Storage service policies use AzureDiagnostics (not Dedicated); ingestion/metrics charges may apply. Reserve the generated sentinel-policy setting name; do not repurpose it.'
        if ($Spec.Kind -eq 'Activity') { $details += ' Activity uses fixed setting name subscriptionToLa and deployment metadata location northeurope; existing diagnostics make the assignment dormant.' }
        $script:Operation.Requested = $details
        if ($current) { Assert-ConnectorPolicyAssignment $current $body $id }
        else {
            Write-Host $details
            if (-not (Invoke-ConnectorChange $id "Create DeployIfNotExists assignment with system identity; $details")) {
                Add-ConnectorResult $Label 'Planned' $details
                return
            }
            # Repeat preflight immediately before submission to narrow creation races.
            Assert-NoConnectorPolicyConflict $Spec $Scope $id
            if (Read-OptionalConnectorPolicyResource $path) { Stop-ConnectorPolicySetup "Assignment appeared concurrently: $id; rerun without overwriting it." }
            $body.properties.notScopes = @(Get-ConnectorPolicyExclusions $Spec $Scope -AllCurrentResources | Select-Object -Unique)
            $script:Operation.Attempted = $true
            $script:Operation.Change = "Create $id; parameters=$(ConvertTo-Json $parameters -Depth 10 -Compress); exclusions=$($body.properties.notScopes -join ', ')"
            $wireBody = ConvertFrom-Json (ConvertTo-Json $body -Depth 40) -AsHashtable -Depth 40
            $null = $wireBody.properties.Remove('scope')
            $null = Read-Arm $path 'PUT' $wireBody
            $current = Read-OptionalConnectorPolicyResource $path
            if (-not $current) {
                Add-ConnectorResult $Label 'PolicyPending' "Submitted $id; readback pending. No roles/remediation submitted." 'Inspect the exact assignment ID and rerun; no rollback is attempted.'
                return
            }
            Assert-ConnectorPolicyAssignment $current $body $id
        }
        $state = [string](Get-Field $current.properties 'provisioningState' '')
        if ($state -in @('Failed', 'Canceled', 'Cancelled')) { throw "Policy assignment $id provisioning=$state." }
        if ($state -and $state -ne 'Succeeded') {
            Add-ConnectorResult $Label 'PolicyPending' "Assignment=$id; provisioning=$state. No identity grants/remediation attempted."
            return
        }
        $script:Operation.Verified = $true
        $script:Operation.Verification = "ARM GET matched assignment=$id; version=$version; parameters and exclusions. Not proof of effective enforcement/ingestion."
        Add-ConnectorResult $Label 'PolicyAssigned' $script:Operation.Verification 'Existing assignment controls are not changed. Verify policy exemptions, compliance and asynchronous deployments separately.'
        if (Test-ConnectorPolicyExcluded $Scope @(Get-Field $current.properties 'notScopes' @())) {
            Add-ConnectorResult $Label 'ActionRequired' "Assignment $id is dormant: its entire source scope is excluded to preserve existing diagnostics. No grants/remediation." 'Direct diagnostic results determine current coverage; separately review any future change to exclusions.'
            return
        }
        $principal = [string](Get-Field (Get-Field $current 'identity' @{}) 'principalId' '')
        if (-not (Enable-ConnectorPolicyIdentityRoles $Label $Scope $principal)) {
            Add-ConnectorResult $Label 'ActionRequired' "Assignment $id exists, but identity role readiness is not confirmed. No remediation submitted." 'Authorize missing grants separately; after newly granted RBAC has propagated, rerun to verify existing grants.'
            return
        }
        if (-not $RemediateConnectorPolicies) {
            Add-ConnectorResult $Label 'ActionRequired' "Assignment/identity verified for $id; remediation not requested." 'Use -RemediateConnectorPolicies only after reviewing noncompliant future sources, exemptions, charges and deployment effects.'
            return
        }
        $required = @(Get-ConnectorPolicyExclusions $Spec $Scope)
        $body.properties.notScopes = $required
        Assert-ConnectorPolicyAssignment (Read-Arm $path) $body $id
        Assert-NoConnectorPolicyConflict $Spec $Scope $id
        Invoke-ConnectorPolicyRemediation $Label $Scope $id
    } catch {
        if ($_.Exception.Data['PolicyActionRequired']) { Add-ConnectorResult $Label 'ActionRequired' $_.Exception.Message }
        else { Add-ConnectorResult $Label 'Failed' $_.Exception.Message 'Inspect the exact resource IDs in this report. Partial assignments/grants/remediations remain; no automatic rollback. Resolve the error and rerun safely.' }
    } finally { $script:Operation = @{} }
}

function Add-ConnectorPolicyRequirements([string]$Label, [string]$Key) {
    foreach ($spec in @(Get-ConnectorPolicies $Key)) {
        $parameters = @{ logAnalytics = $script:WorkspaceId; effect = 'DeployIfNotExists' }
        switch ($spec.Kind) {
            'Activity' { $parameters.logsEnabled = 'True' }
            'NSG' {
                $parameters.diagnosticsSettingNameToUse = '<choose nonconflicting setting name>'
                $parameters.NetworkSecurityGroupEventEnabled = 'True'
                $parameters.NetworkSecurityGroupRuleCounterEnabled = 'True'
            }
            default {
                $parameters.profileName = '<choose nonconflicting setting name>'
                $parameters.metricsEnabled = $spec.Kind -eq 'Account'
                if ($spec.Kind -ne 'Account') { $parameters.logsEnabled = $true }
            }
        }
        $scope = if ($script:ExplicitDiagnosticSources) { 'Only explicitly selected resource IDs; subscription-wide assignment is NOT authorized.' }
            else { "Review subscription scopes: $($SourceSubscriptionIds -join ', ')." }
        $detail = "Recurring policy enforcement is not applied or verified. Reviewed built-in $($spec.Id) ($($spec.Kind)); proposed parameters: $(ConvertTo-Json $parameters -Compress). $scope"
        $next = 'Direct diagnostics cover current selected sources without a policy. Opt in for future resources using -ConfigureConnectorPolicies: policy scope defaults to the selected Sentinel subscription. Override with -ConnectorPolicyScopeIds within -SourceSubscriptionIds if needed. The script validates/pins the exact reviewed built-in schema/version and excludes existing resources, never updates existing assignments. Separately authorize -GrantConnectorPolicyRoles (Monitoring Contributor at the source scope; Log Analytics Contributor only at the destination workspace). Requires policyAssignments/write and separately roleAssignments/write. After RBAC propagation, -RemediateConnectorPolicies submits/observes an asynchronous cycle; acceptance is NOT completion. Inspect policy exemptions and deployments; no rollback is promised. Unknown schemas/conflicts stay ActionRequired. Queue/Table need recurring remediation for future accounts; use an explicit new -ConnectorRemediationRunId. Storage service policy logs use AzureDiagnostics, not Dedicated; existing Dedicated settings remain excluded. Agents, licensing and source consent are not configured.'
        if ($spec.Kind -eq 'Account') { $next += ' This storage-account policy adds AllMetrics (additional ingestion/cost), not service logs; it is not required for direct service-log collection.' }
        if ($spec.Kind -eq 'Activity') { $next += ' Review built-in setting name subscriptionToLa and deployment metadata location northeurope for conflicts/region constraints.' }
        $priorOperation = $script:Operation
        $script:Operation = @{}
        try {
            Add-ConnectorResult "$Label / policy $($spec.Kind)" 'OptionalNotRequested' $detail $next @{
                ConnectorStatus = 'Not assessed (policy only)'
                PolicyOrDiagnosticSetting = $spec.Id
            }
        } finally { $script:Operation = $priorOperation }
    }
}

function Test-CopilotSource($Resource) {
    $p = Get-Field $Resource 'properties' @{}
    return (Get-Field $Resource 'kind' '') -eq 'PurviewAudit' -and
        (Get-Field $p 'connectorDefinitionName' '') -eq 'MicrosoftCopilot' -and
        (Get-Field $p 'sourceType' '') -eq 'CopilotGeneral'
}

function Stop-CopilotSetup([string]$Message) {
    $exception = [InvalidOperationException]::new($Message)
    $exception.Data['CopilotActionRequired'] = $true
    throw $exception
}

function Read-CopilotResource([string]$Id, [string]$Type) {
    if ($Id -notmatch "^/subscriptions/$([regex]::Escape($script:SubscriptionId))/resourceGroups/$([regex]::Escape($script:ResourceGroup))/providers/Microsoft\.Insights/$Type/[^/?#]+$") {
        Stop-CopilotSetup "Invalid/out-of-workspace-group $Type ID: $Id. No retargeting allowed."
    }
    try { Read-Arm "${Id}?api-version=2024-03-11" }
    catch { if ($_.Exception.Data['ArmStatusCode'] -ne 404) { throw } }
}

function Wait-CopilotResource([string]$Id) {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $resource = Read-Arm "${Id}?api-version=2024-03-11"
        $state = [string](Get-Field (Get-Field $resource 'properties' @{}) 'provisioningState' '')
        if ($state -eq 'Succeeded') { return $resource }
        if ($state -in @('Failed', 'Canceled', 'Cancelled')) { throw "Provisioning $Id ended in $state." }
        if ($attempt -lt 29) { Start-Sleep -Seconds 2 }
    }
    Stop-CopilotSetup "Provisioning still pending for $Id. Inspect before rerunning; no success claimed."
}

function Assert-CopilotDce($Dce, [string]$Id, [string]$Location) {
    $p = Get-Field $Dce 'properties' @{}
    $endpoint = [string](Get-Field (Get-Field $p 'logsIngestion' @{}) 'endpoint' '')
    $uri = $null
    if ((Get-Field $Dce 'id' '') -ne $Id -or (Get-Field $Dce 'location' '') -ne $Location -or
        (Get-Field (Get-Field $p 'networkAcls' @{}) 'publicNetworkAccess' '') -ne 'Enabled' -or
        @(Get-Field $p 'privateLinkScopedResources' @()).Count -gt 0 -or
        -not [uri]::TryCreate($endpoint, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne 'https' -or $uri.UserInfo -or $uri.Query -or $uri.Fragment) {
        Stop-CopilotSetup "DCE $Id must be in $Location with HTTPS ingestion and unrestricted publicNetworkAccess Enabled. Existing restrictions will NOT be weakened."
    }
}

function Assert-CopilotDcr($Dcr, [string]$Id, [string]$DceId, [string]$Location) {
    $p = Get-Field $Dcr 'properties' @{}
    $destinations = Get-Field $p 'destinations' @{}
    $targets = @(Get-Field $destinations 'logAnalytics' @())
    $flows = @(Get-Field $p 'dataFlows' @())
    $valid = (Get-Field $Dcr 'id' '') -eq $Id -and (Get-Field $Dcr 'location' '') -eq $Location -and
        (Get-Field $p 'dataCollectionEndpointId' '') -eq $DceId -and
        (Get-Field $p 'immutableId' '') -and $targets.Count -eq 1 -and $flows.Count -eq 1
    if ($valid) {
        $valid = (Get-Field $targets[0] 'workspaceResourceId' '') -eq $script:WorkspaceId -and
            (Get-Field $targets[0] 'name' '') -and
            (@(Get-Field $flows[0] 'streams' @()) -join ',') -ceq 'Microsoft-CopilotActivity' -and
            (@(Get-Field $flows[0] 'destinations' @()) -join ',') -ceq [string]$targets[0].name -and
            (Get-Field $flows[0] 'transformKql' '') -ceq 'source' -and
            (Get-Field $flows[0] 'outputStream' '') -ceq 'Microsoft-CopilotActivity'
    }
    foreach ($key in $destinations.Keys) { if ($key -ne 'logAnalytics' -and $destinations[$key]) { $valid = $false } }
    foreach ($field in @('dataSources', 'streamDeclarations')) {
        $value = Get-Field $p $field @{}
        if ($value -isnot [Collections.IDictionary] -or $value.Count -gt 0) { $valid = $false }
    }
    if (-not $valid) { Stop-CopilotSetup "Incompatible DCR $Id. Requires only this workspace and one Microsoft-CopilotActivity flow (transformKql=source). Existing routing is preserved." }
}

function Enable-CopilotConnector([string]$Label, $Record) {
    try {
        if (-not $Record.CopilotSource -or $Record.UnsupportedTemplateKinds.Count -or
            @($Record.Instances | Where-Object { -not (Test-CopilotSource $_) }).Count) {
            Stop-CopilotSetup 'Installed metadata is not exclusively the reviewed MicrosoftCopilot/CopilotGeneral PurviewAudit source; no template instructions executed.'
        }
        if (@($script:ConnectorDefinitions | Where-Object {
            (Get-Field $_ 'name' '') -eq 'MicrosoftCopilot' -and (Get-Field $_ 'kind' '') -eq 'Customizable'
        }).Count -ne 1) { Stop-CopilotSetup 'Install the MicrosoftCopilot Customizable definition through Content Hub first.' }
        if ($Record.Instances.Count -gt 1) { Stop-CopilotSetup 'Multiple Copilot runtime instances; resolve duplicates first.' }
        $name = Get-StableName "$script:WorkspaceId|PurviewAudit|MicrosoftCopilot|CopilotGeneral|$script:TenantId"
        $body = @{ kind = 'PurviewAudit'; properties = @{
            tenantId = $script:TenantId; connectorDefinitionName = 'MicrosoftCopilot'; sourceType = 'CopilotGeneral'
            dataTypes = @{ logs = @{ state = 'Enabled' } }
        } }
        $oldConfig = @{}
        $enabled = $false
        if ($Record.Instances.Count) {
            $existing = $Record.Instances[0]
            if ((Get-Field $existing.properties 'tenantId' '') -ne $script:TenantId) { Stop-CopilotSetup 'Existing Copilot tenant is missing/different; no retargeting.' }
            $name = $existing.name
            $body.properties = ConvertFrom-Json (ConvertTo-Json $existing.properties -Depth 100) -AsHashtable
            if ($existing.Contains('etag')) { $body.etag = $existing.etag }
            $oldConfig = Get-Field $body.properties 'dcrConfig' @{}
            $enabled = (Get-Field (Get-Field (Get-Field $body.properties 'dataTypes' @{}) 'logs' @{}) 'state' '') -eq 'Enabled'
        } elseif (@($script:Inventory | Where-Object name -eq $name).Count) { Stop-CopilotSetup 'Copilot resource-name collision.' }
        $oldImmutable = [string](Get-Field $oldConfig 'dataCollectionRuleImmutableId' '')
        $oldEndpoint = [string](Get-Field $oldConfig 'dataCollectionEndpoint' '')
        if (($enabled -or $oldConfig.Count) -and (-not $oldImmutable -or -not $oldEndpoint -or
            (Get-Field $oldConfig 'streamName' '') -cne 'LLMACTIVITY_RESTAPI')) {
            Stop-CopilotSetup 'Existing Copilot dcrConfig is incomplete/incompatible; repair on the connector page, no silent retargeting.'
        }
        $root = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.Insights"
        $dcrId = $CopilotDataCollectionRuleId.TrimEnd('/')
        $dceId = $CopilotDataCollectionEndpointId.TrimEnd('/')
        if (-not $dcrId) {
            $rules = @(Read-ArmList "$root/dataCollectionRules?api-version=2024-03-11")
            $candidates = @($rules | Where-Object {
                $p = Get-Field $_ 'properties' @{}
                if ($oldImmutable) { (Get-Field $p 'immutableId' '') -ceq $oldImmutable }
                else {
                    @((Get-Field (Get-Field $p 'destinations' @{}) 'logAnalytics' @()) | Where-Object {
                        (Get-Field $_ 'workspaceResourceId' '') -eq $script:WorkspaceId
                    }).Count -gt 0 -and
                    @((Get-Field $p 'dataFlows' @()) | Where-Object { 'Microsoft-CopilotActivity' -in @(Get-Field $_ 'streams' @()) }).Count -gt 0
                }
            })
            if ($candidates.Count -gt 1) { Stop-CopilotSetup 'Multiple candidate Copilot DCRs; supply -CopilotDataCollectionRuleId.' }
            if ($candidates.Count) { $dcrId = [string]$candidates[0].id }
            elseif ($oldImmutable) { Stop-CopilotSetup 'Existing Copilot DCR cannot be resolved in the workspace resource group.' }
            else { $dcrId = "$root/dataCollectionRules/Copilot-DCR-$((Get-StableName $script:WorkspaceId).Substring(0, 12))" }
        }
        $dcr = Read-CopilotResource $dcrId 'dataCollectionRules'
        if (-not $dcr -and $CopilotDataCollectionRuleId) { Stop-CopilotSetup 'Explicit Copilot DCR does not exist.' }
        if ($dcr) {
            $associated = [string](Get-Field $dcr.properties 'dataCollectionEndpointId' '')
            if (-not $associated -or ($dceId -and $dceId -ne $associated)) { Stop-CopilotSetup 'Copilot DCR/DCE association conflict; no routing changes.' }
            $dceId = $associated
            Assert-CopilotDcr $dcr $dcrId $dceId $script:Region
            if ($oldImmutable -and $dcr.properties.immutableId -cne $oldImmutable) { Stop-CopilotSetup 'Selected Copilot DCR differs from existing runtime.' }
        }
        $mustExist = [bool]($dcr -or $dceId)
        if (-not $dceId) { $dceId = "$root/dataCollectionEndpoints/$script:Workspace" }
        $dce = Read-CopilotResource $dceId 'dataCollectionEndpoints'
        if (-not $dce -and $mustExist) { Stop-CopilotSetup 'Selected/referenced Copilot DCE does not exist.' }
        if ($dce) {
            Assert-CopilotDce $dce $dceId $script:Region
            if ($oldEndpoint -and $dce.properties.logsIngestion.endpoint -cne $oldEndpoint) { Stop-CopilotSetup 'Copilot DCE endpoint differs from existing runtime.' }
        }
        $script:Operation.PolicyOrDiagnosticSetting = "DCR=$dcrId; DCE=$dceId"
        $script:Operation.Requested = "CopilotGeneral -> Microsoft-CopilotActivity at $script:WorkspaceId; public DCE, region=$script:Region; ingestion charges may apply."
        if ($dcr) { $dcr = Wait-CopilotResource $dcrId; Assert-CopilotDcr $dcr $dcrId $dceId $script:Region }
        if ($dce) { $dce = Wait-CopilotResource $dceId; Assert-CopilotDce $dce $dceId $script:Region }
        $path = "$script:SentinelId/dataConnectors/${name}?api-version=$PreviewApiVersion"
        if (-not $enabled) {
            $script:Operation.Change = "Configure Copilot runtime; create missing DCE=$dceId (publicNetworkAccess=Enabled) and DCR=$dcrId. Preserve existing dependencies. No rollback; inspect partial failures."
            if (-not (Invoke-ConnectorChange $Label $script:Operation.Change)) {
                Add-ConnectorResult $Label 'Planned' $script:Operation.Change
                return
            }
            $script:Operation.Attempted = $true
            if (-not $dce) {
                $null = Read-Arm "${dceId}?api-version=2024-03-11" 'PUT' @{ location = $script:Region; properties = @{ networkAcls = @{ publicNetworkAccess = 'Enabled' } } }
                $dce = Wait-CopilotResource $dceId
                Assert-CopilotDce $dce $dceId $script:Region
            }
            if (-not $dcr) {
                $null = Read-Arm "${dcrId}?api-version=2024-03-11" 'PUT' @{ location = $script:Region; properties = @{
                    dataCollectionEndpointId = $dceId
                    destinations = @{ logAnalytics = @(@{ workspaceResourceId = $script:WorkspaceId; name = 'clv2ws1' }) }
                    dataFlows = @(@{ streams = @('Microsoft-CopilotActivity'); destinations = @('clv2ws1'); transformKql = 'source'; outputStream = 'Microsoft-CopilotActivity' })
                } }
                $dcr = Wait-CopilotResource $dcrId
                Assert-CopilotDcr $dcr $dcrId $dceId $script:Region
            }
            if (-not $body.properties.Contains('dataTypes')) { $body.properties.dataTypes = @{} }
            if (-not $body.properties.dataTypes.Contains('logs')) { $body.properties.dataTypes.logs = @{} }
            $body.properties.dataTypes.logs.state = 'Enabled'
            if (-not $oldConfig.Count) {
                $body.properties.dcrConfig = @{
                    dataCollectionEndpoint = $dce.properties.logsIngestion.endpoint
                    dataCollectionRuleImmutableId = $dcr.properties.immutableId; streamName = 'LLMACTIVITY_RESTAPI'
                }
            }
            $null = Read-Arm $path 'PUT' $body
            $script:Operation.Accepted = $true
        }
        $actual = Read-Arm $path
        $p = Get-Field $actual 'properties' @{}
        $config = Get-Field $p 'dcrConfig' @{}
        if (-not (Test-CopilotSource $actual) -or (Get-Field $p 'tenantId' '') -ne $script:TenantId -or
            (Get-Field (Get-Field (Get-Field $p 'dataTypes' @{}) 'logs' @{}) 'state' '') -ne 'Enabled' -or
            (Get-Field $config 'dataCollectionEndpoint' '') -cne $dce.properties.logsIngestion.endpoint -or
            (Get-Field $config 'dataCollectionRuleImmutableId' '') -cne $dcr.properties.immutableId -or
            (Get-Field $config 'streamName' '') -cne 'LLMACTIVITY_RESTAPI') { throw 'Copilot runtime read-back mismatch.' }
        $script:Operation.Verified = $true
        $script:Operation.Verification = 'ARM GET verified Copilot runtime and DCR/DCE routing; ingestion not verified.'
        $script:Operation.ConnectorStatus = 'Enabled (ingestion unverified)'
        Add-ConnectorResult $Label $(if ($enabled) { 'AlreadyConfigured' } else { 'Configured' }) $script:Operation.Verification (Get-SetupGuidance 'MicrosoftCopilot')
    } catch {
        if (-not $_.Exception.Data['CopilotActionRequired']) { throw }
        Add-ConnectorResult $Label 'ActionRequired' $_.Exception.Message (Get-SetupGuidance 'MicrosoftCopilot')
    }
}

function Read-OptionalConnectorDependency([string]$Path) {
    try {
        $actual = Read-Arm $Path
        if ($actual -isnot [Collections.IDictionary] -or -not $actual.Contains('properties')) { throw "Invalid dependency document at $Path" }
        return $actual
    } catch { if ($_.Exception.Data['ArmStatusCode'] -ne 404) { throw } }
}

function Assert-SecurityEventDcr($Dcr, [string]$Id) {
    $p = Get-Field $Dcr 'properties' @{}
    $sources = Get-Field $p 'dataSources' @{}
    $events = @(Get-Field $sources 'windowsEventLogs' @())
    $destinations = Get-Field $p 'destinations' @{}
    $targets = @(Get-Field $destinations 'logAnalytics' @())
    $flows = @(Get-Field $p 'dataFlows' @())
    $valid = (Get-Field $Dcr 'id' '') -eq $Id -and (Get-Field $Dcr 'kind' '') -eq 'Windows' -and
        (Get-Field $Dcr 'location' '') -eq $script:Region -and -not (Get-Field $p 'dataCollectionEndpointId') -and
        $events.Count -eq 1 -and $targets.Count -eq 1 -and $flows.Count -eq 1
    if ($valid) {
        $valid = (@(Get-Field $events[0] 'streams' @()) -join ',') -ceq 'Microsoft-SecurityEvent' -and
            @(Get-Field $events[0] 'xPathQueries' @()).Count -gt 0 -and
            @((Get-Field $events[0] 'xPathQueries' @()) | Where-Object { $_ -isnot [string] -or $_ -cnotmatch '^Security!.+' }).Count -eq 0 -and
            (Get-Field $targets[0] 'workspaceResourceId' '') -eq $script:WorkspaceId -and
            (@(Get-Field $flows[0] 'streams' @()) -join ',') -ceq 'Microsoft-SecurityEvent' -and
            (@(Get-Field $flows[0] 'destinations' @()) -join ',') -ceq [string](Get-Field $targets[0] 'name' '') -and
            (Get-Field $flows[0] 'transformKql' '') -cin @('', 'source') -and
            (Get-Field $flows[0] 'outputStream' '') -cin @('', 'Microsoft-SecurityEvent')
        if ($WindowsSecurityEventXPathQueries.Count) {
            $wanted = @($WindowsSecurityEventXPathQueries | Sort-Object -Unique) -join "`n"
            $actual = @($events[0].xPathQueries | Sort-Object -Unique) -join "`n"
            if ($wanted -cne $actual) { $valid = $false }
        }
    }
    foreach ($name in $sources.Keys) { if ($name -ne 'windowsEventLogs' -and $sources[$name]) { $valid = $false } }
    foreach ($name in $destinations.Keys) { if ($name -ne 'logAnalytics' -and $destinations[$name]) { $valid = $false } }
    foreach ($field in @('streamDeclarations', 'references', 'agentSettings')) {
        if ((Get-Field $p $field @{}).Count) { $valid = $false }
    }
    if (-not $valid) { Stop-CopilotSetup "DCR $Id is not a reviewed single-source Windows SecurityEvent rule to this workspace. Filters, DCE/private networking, sources and transformations are not overwritten." }
}

function Wait-ConnectorDependency([string]$Path) {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $actual = Read-Arm $Path
        $state = [string](Get-Field (Get-Field $actual 'properties' @{}) 'provisioningState' '')
        if ($state -eq 'Succeeded') { return $actual }
        if ($state -in @('Failed', 'Canceled', 'Cancelled')) { throw "Dependency provisioning ended in $state at $Path." }
        if ($attempt -lt 29) { Start-Sleep -Seconds 2 }
    }
    Stop-CopilotSetup "Dependency remains pending at $Path. Inspect before rerunning; no successful configuration claimed."
}

function Enable-WindowsSecurityEventCollection([string]$Label) {
    $script:Operation.Stage = 'AgentCollection'
    try {
        if (-not $WindowsSecurityEventMachineIds.Count) {
            Stop-CopilotSetup 'Explicit WindowsSecurityEventMachineIds and approved event filters/DCR are required. No machines or all-events filters are guessed.'
        }
        $machineIds = @($WindowsSecurityEventMachineIds | ForEach-Object { $_.TrimEnd('/') } | Select-Object -Unique)
        foreach ($machineId in $machineIds) {
            if ($machineId -notmatch '^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/?#]+/providers/Microsoft\.Compute/virtualMachines/[^/?#]+$' -or
                $machineId.Split('/')[2] -notin $SourceSubscriptionIds) {
                Stop-CopilotSetup "Unsupported/out-of-selected-scope machine $machineId. This adapter supports explicit Windows Azure VMs only; Arc/VMSS require separate connector-page setup."
            }
        }
        foreach ($query in $WindowsSecurityEventXPathQueries) {
            if ($query -cnotmatch '^Security!.+' -or $query.Length -gt 4096) { Stop-CopilotSetup 'Supply explicit Security! XPath queries (maximum 4096 characters each); no other log channels are deployed by this adapter.' }
        }
        $dcrRoot = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.Insights/dataCollectionRules"
        $dcrId = if ($WindowsSecurityEventDcrId) { $WindowsSecurityEventDcrId.TrimEnd('/') }
            else { "$dcrRoot/Sentinel-SecurityEvent-$((Get-StableName $script:WorkspaceId).Substring(0, 12))" }
        if (-not $dcrId.StartsWith("$dcrRoot/", [StringComparison]::OrdinalIgnoreCase) -or
            $dcrId.Substring($dcrRoot.Length + 1) -match '[/?:#]') { Stop-CopilotSetup 'SecurityEvent DCR must be in the workspace resource group; no arbitrary resource scope.' }
        $dcrPath = "${dcrId}?api-version=2024-03-11"
        $workspaceResource = Read-Arm "$script:WorkspaceId`?api-version=2022-10-01"
        if ((Get-Field (Get-Field $workspaceResource 'properties' @{}) 'publicNetworkAccessForIngestion' 'Enabled') -ne 'Enabled') {
            Stop-CopilotSetup 'Workspace public ingestion is disabled; configure the required DCE/private-link/agent network chain manually. No public agent collection setup is deployed.'
        }
        $dcr = Read-OptionalConnectorDependency $dcrPath
        if ($dcr) { Assert-SecurityEventDcr $dcr $dcrId }
        elseif ($WindowsSecurityEventDcrId) { Stop-CopilotSetup 'Explicit SecurityEvent DCR does not exist; create/review it or omit its ID and supply approved XPath filters.' }
        elseif (-not $WindowsSecurityEventXPathQueries.Count) { Stop-CopilotSetup 'Creating a SecurityEvent DCR requires explicit WindowsSecurityEventXPathQueries; no default all-event collection.' }
        $plans = [Collections.Generic.List[object]]::new()
        foreach ($machineId in $machineIds) {
            $vm = Read-Arm "${machineId}?api-version=2024-03-01"
            if ((Get-Field $vm 'id' '') -ne $machineId -or
                (Get-Field (Get-Field (Get-Field (Get-Field $vm 'properties' @{}) 'storageProfile' @{}) 'osDisk' @{}) 'osType' '') -ne 'Windows' -or
                (Get-Field (Get-Field $vm 'identity' @{}) 'type' '') -notmatch '(^|,\s*)SystemAssigned($|,)' -or
                -not (Get-Field (Get-Field $vm 'identity' @{}) 'principalId')) {
                Stop-CopilotSetup "$machineId must be a Windows Azure VM with an existing system-assigned managed identity. No VM identity/OS configuration is changed."
            }
            $location = [string](Get-Field $vm 'location' '')
            if (-not $location) { Stop-CopilotSetup "VM region missing: $machineId." }
            $associations = @(Read-ArmList "$machineId/providers/Microsoft.Insights/dataCollectionRuleAssociations?api-version=2024-03-11")
            $matching = @()
            foreach ($association in $associations) {
                $p = Get-Field $association 'properties' @{}
                if (Get-Field $p 'dataCollectionEndpointId') { Stop-CopilotSetup "$machineId already has a DCE association/private-network configuration; use the connector page, no new collection association." }
                $otherId = [string](Get-Field $p 'dataCollectionRuleId' '')
                if ($otherId -eq $dcrId) { $matching += $association; continue }
                if ($otherId -notmatch '^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/?#]+/providers/Microsoft\.Insights/dataCollectionRules/[^/?#]+$') {
                    Stop-CopilotSetup "Cannot inspect existing association at $machineId; no new association."
                }
                $other = Read-Arm "${otherId}?api-version=2024-03-11"
                $eventSources = @(Get-Field (Get-Field (Get-Field $other 'properties' @{}) 'dataSources' @{}) 'windowsEventLogs' @())
                if (@($eventSources | Where-Object {
                    'Microsoft-SecurityEvent' -in @(Get-Field $_ 'streams' @()) -or
                    @((Get-Field $_ 'xPathQueries' @()) | Where-Object { $_ -match '^Security!' }).Count
                }).Count) { Stop-CopilotSetup "$machineId already collects Security events through $otherId; no duplicate collection or retargeting." }
            }
            $extensions = @(Read-ArmList "$machineId/extensions?api-version=2024-03-01")
            $agents = @($extensions | Where-Object {
                (Get-Field (Get-Field $_ 'properties' @{}) 'publisher' '') -eq 'Microsoft.Azure.Monitor' -and
                (Get-Field (Get-Field $_ 'properties' @{}) 'type' '') -eq 'AzureMonitorWindowsAgent'
            })
            if ($agents.Count -gt 1) { Stop-CopilotSetup "Multiple Windows AMA extensions at $machineId; resolve manually." }
            $agentId = "$machineId/extensions/AzureMonitorWindowsAgent"
            $agentVersion = ''
            if ($agents.Count) {
                if ((Get-Field $agents[0].properties 'provisioningState' '') -ne 'Succeeded') {
                    Stop-CopilotSetup "Existing AMA is not successfully provisioned at $machineId; it is preserved, not overwritten."
                }
                $agentId = [string](Get-Field $agents[0] 'id' '')
            } else {
                if (@($extensions | Where-Object { (Get-Field $_ 'id' '') -eq $agentId -or (Get-Field $_ 'name' '') -eq 'AzureMonitorWindowsAgent' }).Count) {
                    Stop-CopilotSetup "Extension-name collision at $agentId."
                }
                if (-not $InstallWindowsAzureMonitorAgent) { Stop-CopilotSetup "AMA missing at $machineId. Separately authorize -InstallWindowsAzureMonitorAgent, or install it through the supported connector page." }
                $versions = @(Read-Arm "/subscriptions/$($machineId.Split('/')[2])/providers/Microsoft.Compute/locations/$location/publishers/Microsoft.Azure.Monitor/artifacttypes/vmextension/types/AzureMonitorWindowsAgent/versions?api-version=2024-03-01")
                $version = @($versions | Where-Object { (Get-Field $_ 'name' '') -match '^\d+\.\d+(?:\.\d+){0,2}$' } |
                    Sort-Object { [version]$_.name } -Descending | Select-Object -First 1)
                if (-not $version.Count) { Stop-CopilotSetup "No published Microsoft Windows AMA image version verified in $location." }
                $agentVersion = ([version]$version[0].name).ToString(2)
            }
            $associationId = "$machineId/providers/Microsoft.Insights/dataCollectionRuleAssociations/sc-$((Get-StableName $dcrId).Replace('-', '').Substring(0, 20))"
            if (-not $matching.Count -and @($associations | Where-Object { (Get-Field $_ 'id' '') -eq $associationId }).Count) { Stop-CopilotSetup "Association-name collision at $associationId." }
            $plans.Add(@{ Machine = $machineId; Location = $location; AgentId = $agentId; AgentVersion = $agentVersion; AssociationId = $associationId; Existing = ($matching.Count -gt 0) })
        }
        $newDcr = -not $dcr
        $description = "SecurityEvent DCR=$dcrId; machines=$($machineIds -join ', '); XPath=$(if ($dcr) { $dcr.properties.dataSources.windowsEventLogs[0].xPathQueries -join '; ' } else { $WindowsSecurityEventXPathQueries -join '; ' }); stream=Microsoft-SecurityEvent; workspace=$script:WorkspaceId; new AMA=$(@($plans | Where-Object AgentVersion).Count). Ingestion charges apply; no host audit/network changes."
        $script:Operation.Requested = $description
        $script:Operation.PolicyOrDiagnosticSetting = $dcrId
        $needsChange = $newDcr -or @($plans | Where-Object { $_.AgentVersion -or -not $_.Existing }).Count -gt 0
        if ($needsChange -and -not (Invoke-ConnectorChange $dcrId "Create only missing approved agent/DCR/associations; $description")) {
            Add-ConnectorResult $Label 'Planned' $description
            return
        }
        $script:Operation.Change = $description
        if ($newDcr) {
            $script:Operation.Attempted = $true
            $null = Read-Arm $dcrPath 'PUT' @{ location = $script:Region; kind = 'Windows'; properties = @{
                dataSources = @{ windowsEventLogs = @(@{ name = 'securityEvents'; streams = @('Microsoft-SecurityEvent'); xPathQueries = $WindowsSecurityEventXPathQueries }) }
                destinations = @{ logAnalytics = @(@{ workspaceResourceId = $script:WorkspaceId; name = 'sentinel' }) }
                dataFlows = @(@{ streams = @('Microsoft-SecurityEvent'); destinations = @('sentinel') })
            } }
        }
        $dcr = Wait-ConnectorDependency $dcrPath
        Assert-SecurityEventDcr $dcr $dcrId
        foreach ($plan in $plans) {
            $agentPath = "$($plan.AgentId)?api-version=2024-03-01"
            if ($plan.AgentVersion) {
                $script:Operation.Attempted = $true
                $script:Operation.Change += "; extension=$($plan.AgentId)"
                $null = Read-Arm $agentPath 'PUT' @{ location = $plan.Location; properties = @{
                    publisher = 'Microsoft.Azure.Monitor'; type = 'AzureMonitorWindowsAgent'; typeHandlerVersion = $plan.AgentVersion
                    autoUpgradeMinorVersion = $true; enableAutomaticUpgrade = $true
                } }
            }
            $agent = Wait-ConnectorDependency $agentPath
            if ((Get-Field $agent 'id' '') -ne $plan.AgentId -or (Get-Field $agent.properties 'publisher' '') -ne 'Microsoft.Azure.Monitor' -or
                (Get-Field $agent.properties 'type' '') -ne 'AzureMonitorWindowsAgent') { throw "AMA readback mismatch at $($plan.AgentId)" }
            if (-not $plan.Existing) {
                $script:Operation.Attempted = $true
                $script:Operation.Change += "; association=$($plan.AssociationId)"
                $null = Read-Arm "$($plan.AssociationId)?api-version=2024-03-11" 'PUT' @{ properties = @{ dataCollectionRuleId = $dcrId; description = 'Explicit Sentinel SecurityEvent collection' } }
            }
            $actual = @(Read-ArmList "$($plan.Machine)/providers/Microsoft.Insights/dataCollectionRuleAssociations?api-version=2024-03-11" | Where-Object {
                (Get-Field (Get-Field $_ 'properties' @{}) 'dataCollectionRuleId' '') -eq $dcrId
            })
            if (-not $actual.Count) { throw "DCR association not verified at $($plan.Machine)" }
            Add-ConnectorResult "$Label / $($plan.Machine)" $(if ($plan.Existing -and -not $plan.AgentVersion -and -not $newDcr) { 'AlreadyConfigured' } else { 'Configured' }) "Verified DCR=$dcrId; AMA=$($plan.AgentId); associations=$(@($actual | ForEach-Object { $_.id }) -join ', '). Host audit policy, network access, agent heartbeat and SecurityEvent ingestion remain unverified." 'Verify required Windows audit subcategories and outbound Azure Monitor connectivity. No guest audit policy or firewall/network restrictions were changed.' @{
                Stage = 'AgentCollection'; Attempted = (-not $plan.Existing -or [bool]$plan.AgentVersion -or $newDcr)
                Verified = $true; Change = $description; Verification = 'ARM GET confirmed DCR schema, AMA extension provisioning and machine association.'
                ConnectorStatus = 'Configured (agent health/ingestion unverified)'; PolicyOrDiagnosticSetting = $dcrId
            }
        }
    } catch {
        if ($_.Exception.Data['CopilotActionRequired']) { Add-ConnectorResult $Label 'ActionRequired' $_.Exception.Message (Get-SetupGuidance WindowsSecurityEvents) }
        else { throw }
    }
}

function Get-EntraLogSelection {
    $cacheKey = "$script:TenantId|$($EntraLogCategories -join ',')"
    if (-not (Get-Variable EntraLogSelectionCache -Scope Script -ErrorAction SilentlyContinue)) {
        $script:EntraLogSelectionCache = @{}
    }
    if ($script:EntraLogSelectionCache.ContainsKey($cacheKey)) {
        return $script:EntraLogSelectionCache[$cacheKey]
    }
    $referenceCategories = @('AuditLogs', 'SignInLogs', 'NonInteractiveUserSignInLogs',
        'ServicePrincipalSignInLogs', 'ManagedIdentitySignInLogs', 'ProvisioningLogs')
    $allRequested = $EntraLogCategories -contains 'All'
    $fallback = $false
    $reason = ''
    if ($allRequested) {
        try {
            $categories = @(Read-ArmList '/providers/Microsoft.AADIAM/diagnosticSettingsCategories?api-version=2017-04-01' |
                ForEach-Object { [string](Get-Field $_ 'name' '') } | Where-Object { $_ } | Sort-Object -Unique)
        } catch {
            if ($_.Exception.Data['ArmStatusCode'] -notin @(400, 404, 405)) { throw }
            $categories = @()
            $reason = "category discovery returned HTTP $($_.Exception.Data['ArmStatusCode'])"
        }
        if (-not $categories.Count) {
            $fallback = $true
            if (-not $reason) { $reason = 'category discovery returned no categories' }
            $categories = $referenceCategories
            Write-Warning "Microsoft Entra ID: $reason. Using the six reference log categories; this does not confirm ALL tenant log categories."
        }
    } else {
        $categories = @($EntraLogCategories | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)
    }
    if (-not $categories.Count) { throw 'No Entra log categories selected; no settings changed.' }
    # Diagnostic category IDs are not table names (for example, no AAD prefix).
    $tableAliases = @{
        AADNonInteractiveUserSignInLogs = 'NonInteractiveUserSignInLogs'
        AADServicePrincipalSignInLogs = 'ServicePrincipalSignInLogs'
        AADManagedIdentitySignInLogs = 'ManagedIdentitySignInLogs'
        AADProvisioningLogs = 'ProvisioningLogs'
    }
    $categories = @($categories | ForEach-Object {
        if ($tableAliases.ContainsKey($_)) { $tableAliases[$_] } else { $_ }
    } | Sort-Object -Unique)
    $selection = @{
        Categories = $categories; AllRequested = $allRequested
        UsedReferenceFallback = $fallback; DiscoveryNote = $reason
    }
    $script:EntraLogSelectionCache[$cacheKey] = $selection
    return $selection
}

function Get-DiagnosticCoverage($Settings, [string[]]$Categories) {
    if (-not $Categories.Count -or @($Categories | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count) {
        throw 'Diagnostic coverage requires explicit nonempty category names.'
    }
    $requested = @($Categories | Select-Object -Unique)
    $covering = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($setting in $Settings) {
        $name = [string](Get-Field $setting 'name' '')
        $properties = Get-Field $setting 'properties'
        if (-not $name -or -not $seen.Add($name) -or $properties -isnot [Collections.IDictionary]) {
            throw 'Diagnostic inventory has missing/duplicate names or invalid properties; no coverage or free slot can be inferred.'
        }
        $workspace = [string](Get-Field $properties 'workspaceId' '')
        if (-not [string]::Equals($workspace.TrimEnd('/'), $script:WorkspaceId.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase)) { continue }
        $logs = Get-ContentHubField $properties 'logs' -NoEnumerate
        if ($null -ne $logs -and $logs -isnot [array]) { throw "Diagnostic setting $name has an invalid logs collection; no coverage can be inferred." }
        $enabled = @()
        foreach ($log in $logs) {
            if ($log -isnot [Collections.IDictionary]) { throw "Diagnostic setting $name has an invalid log entry." }
            if ((Get-Field $log 'enabled' $false) -isnot [bool]) { throw "Diagnostic setting $name has an invalid enabled flag." }
            if ((Get-Field $log 'enabled' $false) -ne $true) { continue }
            if ((Get-Field $log 'categoryGroup' '') -eq 'allLogs') { $enabled += $requested }
            elseif ((Get-Field $log 'category' '') -in $requested) { $enabled += [string]$log.category }
        }
        $enabled = @($enabled | Select-Object -Unique)
        if ($enabled.Count) { $covering.Add(@{ Name = $name; Categories = $enabled }) }
    }
    $full = @($covering | Where-Object { $_.Categories.Count -eq $requested.Count } | Sort-Object Name | Select-Object -First 1)
    $selected = if ($full.Count) { $full } else { @($covering | Sort-Object Name) }
    $covered = @($selected | ForEach-Object { $_.Categories } | Select-Object -Unique)
    return @{
        Missing = @($requested | Where-Object { $_ -notin $covered })
        Covered = $covered
        Names = @($selected | ForEach-Object { $_.Name })
        Settings = $selected
        Count = @($Settings).Count
    }
}

function Get-UncoveredCategories($Settings, [string[]]$Categories) {
    (Get-DiagnosticCoverage $Settings $Categories).Missing
}

function Set-DiagnosticCoverageEvidence($Coverage, [string]$Destination, [string[]]$Categories) {
    $observed = @($Coverage.Settings | ForEach-Object { "$($_.Name): $($_.Categories -join ', ')" })
    $script:Operation.Existing = "ARM GET; $Destination; enabled categories: $($Coverage.Covered -join ', '); missing/disabled: $($Coverage.Missing -join ', '); settings: $($observed -join '; '); setting count=$($Coverage.Count)/5."
    $script:Operation.Requested = "$Destination; enabled categories: $($Categories -join ', ')"
    $script:Operation.PolicyOrDiagnosticSetting = if ($Coverage.Names.Count) { $Coverage.Names -join '; ' } else { 'None (no covering setting)' }
    $script:Operation.ConnectorStatus = if (-not $Coverage.Missing.Count) { 'Configured (ingestion unverified)' }
        elseif ($Coverage.Covered.Count) { 'Partially configured' } else { 'Not configured' }
}

function Complete-ExistingDiagnosticCoverage([string]$Label, $Coverage) {
    $script:Operation.Verified = $true
    $script:Operation.Verification = "ARM GET confirmed all requested categories to the Sentinel workspace in existing setting(s): $($Coverage.Names -join '; ')."
    Write-Host "$Label | Already configured by existing diagnostic setting(s): $($Coverage.Names -join '; '). No changes required." -ForegroundColor Green
    Add-ConnectorResult $Label 'AlreadyConfigured' "Required logs already target this Sentinel workspace. Existing setting(s): $($Coverage.Names -join '; '). Ingestion not verified."
}

function Get-DiagnosticRouting($Properties, [string]$ResourceId = '') {
    $routing = [string](Get-Field $Properties 'logAnalyticsDestinationType' '')
    if ($routing -eq '' -and (Test-StorageQueueScope $ResourceId)) { return 'ProviderDefault (StorageQueueLogs expected; ingestion unverified)' }
    if ($routing -in @('', 'AzureDiagnostics')) { return 'AzureDiagnostics' }
    return $routing
}

function Enable-DiagnosticConnector([string]$Label, [string]$Scope, [string[]]$Categories, [switch]$Entra, [switch]$Dedicated) {
    $api = if ($Entra) { '2017-04-01' } else { $MonitorApiVersion }
    $root = if ($Entra) { '/providers/Microsoft.AADIAM' } else { "$Scope/providers/Microsoft.Insights" }
    $settings = @(Read-ArmList "$root/diagnosticSettings?api-version=$api")
    $Categories = @($Categories | Select-Object -Unique)
    $coverage = Get-DiagnosticCoverage $settings $Categories
    $uncovered = $coverage.Missing
    $sourceScope = if ($Entra) { "/providers/microsoft.aadiam (tenant $script:TenantId)" } else { $Scope }
    $destination = "source=$sourceScope; workspace=$script:WorkspaceId"
    Set-DiagnosticCoverageEvidence $coverage $destination $Categories
    if ($uncovered.Count -eq 0) {
        Complete-ExistingDiagnosticCoverage $Label $coverage
        return
    }
    if ($settings.Count -ge 5) {
        Add-ConnectorResult $Label 'ActionRequired' "Diagnostic setting limit reached ($($settings.Count)/5). Missing categories: $($uncovered -join ', '). Existing settings: $($settings.name -join '; '). No settings changed." 'Review/consolidate existing settings manually while preserving required destinations. All five slots are occupied; a sixth setting cannot be created.'
        return
    }
    $name = 'sentinel-' + (Get-StableName "$script:WorkspaceId|$sourceScope|$($Categories -join ',')").Substring(0, 24)
    if ($Entra -and -not @($settings | Where-Object name -eq 'Microsoft-Entra-ID-Sentinel').Count) {
        $name = 'Microsoft-Entra-ID-Sentinel'
    }
    if (@($settings | Where-Object name -eq $name).Count -gt 0) {
        $name = "sentinel-$([guid]::NewGuid().ToString('N'))"
    }
    $properties = @{ workspaceId = $script:WorkspaceId; logs = @() }
    if ($Dedicated -and -not (Test-StorageQueueScope $Scope)) { $properties.logAnalyticsDestinationType = 'Dedicated' }
    foreach ($category in $uncovered) {
        $log = @{ category = $category; enabled = $true }
        if (-not $Entra) { $log.retentionPolicy = @{ enabled = $false; days = 0 } }
        $properties.logs += $log
    }
    $routing = Get-DiagnosticRouting $properties $Scope
    $script:Operation.Change = "Create separate diagnostic setting: $destination; setting=$name; newly enabled categories: $($uncovered -join ', '); table routing=$routing"
    $script:Operation.Requested += "; table routing=$routing"
    if (-not (Invoke-ConnectorChange "$Label -> $script:WorkspaceId" "Enable diagnostic categories: $($uncovered -join ', ')")) {
        Add-ConnectorResult $Label 'Planned' "Would enable diagnostic categories: $($uncovered -join ', ')."
        return
    }
    # Approval may take time: recheck both coverage and capacity before submitting a create.
    $settings = @(Read-ArmList "$root/diagnosticSettings?api-version=$api")
    $coverage = Get-DiagnosticCoverage $settings $Categories
    Set-DiagnosticCoverageEvidence $coverage $destination $Categories
    if (-not $coverage.Missing.Count) {
        Complete-ExistingDiagnosticCoverage $Label $coverage
        return
    }
    if ($settings.Count -ge 5) {
        Add-ConnectorResult $Label 'ActionRequired' "Diagnostic setting limit reached during approval ($($settings.Count)/5). Missing categories: $($coverage.Missing -join ', '). Existing settings: $($settings.name -join '; '). No write submitted." 'Another writer may have consumed the last slot. Review existing destinations; no settings were overwritten or deleted.'
        return
    }
    if (@($settings | Where-Object name -eq $name).Count) {
        Add-ConnectorResult $Label 'ActionRequired' "Diagnostic setting $name appeared during approval. No existing setting will be overwritten." 'Rerun to reassess coverage and select a collision-free new setting name.'
        return
    }
    if (@($coverage.Missing | Where-Object { $_ -notin $uncovered }).Count) {
        Add-ConnectorResult $Label 'ActionRequired' 'Existing coverage decreased during approval. No write submitted because the approved categories no longer cover the requirement.' 'Rerun after other diagnostic-setting writers have finished.'
        return
    }
    $uncovered = $coverage.Missing
    $properties.logs = @($properties.logs | Where-Object { $_.category -in $uncovered })
    $script:Operation.Change = "Create separate diagnostic setting: $destination; setting=$name; newly enabled categories: $($uncovered -join ', '); table routing=$routing"
    $script:Operation.PolicyOrDiagnosticSetting = (@($coverage.Names) + @($name) | Select-Object -Unique) -join '; '
    $path = "$root/diagnosticSettings/${name}?api-version=$api"
    $script:Operation.Attempted = $true
    $null = Read-Arm $path 'PUT' @{ properties = $properties }
    $script:Operation.Accepted = $true
    $verified = $false
    for ($poll = 0; $poll -lt 6; $poll++) {
        # Entra named GET can briefly return 404 after PUT; verify through the source collection.
        $settings = @(Read-ArmList "$root/diagnosticSettings?api-version=$api")
        $actual = @($settings | Where-Object name -eq $name)
        if ($actual.Count -gt 1) { throw 'Diagnostic read-back returned duplicate names; verification refused.' }
        if ($actual.Count -eq 1) {
            $createdCoverage = Get-DiagnosticCoverage $actual $uncovered
            $coverage = Get-DiagnosticCoverage $settings $Categories
            if (-not $createdCoverage.Missing.Count -and -not $coverage.Missing.Count) {
                $verified = $true
                break
            }
        }
        if ($poll -lt 5) { Start-Sleep -Seconds 5 }
    }
    if (-not $verified) { throw "Diagnostic PUT was accepted but setting $name and all required workspace/category coverage could not be verified within six collection reads. Do not assume success; inspect the setting before rerunning." }
    $script:Operation.Verified = $true
    $script:Operation.Verification = "ARM GET confirmed requested diagnostic setting and all categories: $($script:Operation.Requested)"
    $script:Operation.ConnectorStatus = 'Configured (ingestion unverified)'
    $script:Operation.PolicyOrDiagnosticSetting = (@($coverage.Names) + @($name) | Select-Object -Unique) -join '; '
    Add-ConnectorResult $Label 'Configured' "Created $name for missing categories: $($uncovered -join ', '). Required coverage verified using setting(s): $($coverage.Names -join '; '). Existing settings preserved; ingestion not verified."
}

function Get-ResourceAdapter([string]$ResourceId) {
    switch -Regex ($ResourceId.TrimEnd('/')) {
        '^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\.Storage/storageAccounts/[^/]+/(blob|file|queue|table)Services/default$' { 'AzureStorageAccount'; break }
        '^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\.Network/networkSecurityGroups/[^/]+$' { 'AzureNSG'; break }
        '^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\.Purview/accounts/[^/]+$' { 'MicrosoftPurview'; break }
        default { '' }
    }
}

function Find-DiagnosticSources([string]$Key, [string]$Label) {
    $type = switch ($Key) {
        'AzureStorageAccount' { 'Microsoft.Storage/storageAccounts' }
        'AzureNSG' { 'Microsoft.Network/networkSecurityGroups' }
        'MicrosoftPurview' { 'Microsoft.Purview/accounts' }
    }
    foreach ($source in $SourceSubscriptionIds) {
        $filter = [uri]::EscapeDataString("resourceType eq '$type'")
        $items = @(Read-ArmList "/subscriptions/$source/resources?api-version=2021-04-01&`$filter=$filter")
        if ($items.Count -eq 0) {
            Add-ConnectorResult "$Label / subscription $source / $type" 'NoSourcesFound' 'No source resources found; no diagnostic settings created.' (Get-SetupGuidance $Key)
        }
        foreach ($item in $items) {
            $id = [string](Get-Field $item 'id' '')
            if ((Get-Field $item 'type' '') -ne $type) { throw "Discovery returned an unexpected resource type: $id" }
            if ($Key -ne 'AzureStorageAccount') { $id; continue }
            $serviceCount = 0
            foreach ($serviceType in @('blobServices', 'fileServices', 'queueServices', 'tableServices')) {
                $services = @(Read-ArmList "$id/${serviceType}?api-version=2023-05-01")
                foreach ($service in $services) {
                    $serviceId = [string](Get-Field $service 'id' '')
                    if ($serviceId -ne "$id/$serviceType/default") { throw "Unexpected storage service scope returned for $id/$serviceType." }
                    $serviceCount++
                    $serviceId
                }
            }
            if ($serviceCount -eq 0) {
                Add-ConnectorResult "$Label / $id" 'NoSourcesFound' 'No existing storage service resources found for log collection. Account metrics are not service logs; no services created.' (Get-SetupGuidance $Key)
            }
        }
    }
}

function Get-ConnectorSnapshot {
    $templates = @(Read-ArmList "$script:SentinelId/contentTemplates?api-version=$ApiVersion&`$expand=properties/mainTemplate,properties/dependantTemplates" |
        Where-Object { (Get-Field (Get-Field $_ 'properties' @{}) 'contentKind' '') -eq 'DataConnector' })
    $definitions = @(Read-ArmList "$script:SentinelId/dataConnectorDefinitions?api-version=$ApiVersion")
    $inventory = @(Read-ArmList "$script:SentinelId/dataConnectors?api-version=$PreviewApiVersion")
    [pscustomobject]@{
        Templates = $templates
        Definitions = $definitions
        Inventory = $inventory
        TemplateNames = @($templates | ForEach-Object { [string](Get-Field $_ 'name' '') } | Where-Object { $_ } | Select-Object -Unique)
        DefinitionNames = @($definitions | ForEach-Object { [string](Get-Field $_ 'name' '') } | Where-Object { $_ } | Select-Object -Unique)
        RuntimeNames = @($inventory | ForEach-Object { [string](Get-Field $_ 'name' '') } | Where-Object { $_ } | Select-Object -Unique)
    }
}

function Get-ConnectorRecords($Snapshot) {
    $script:Candidates = [Collections.Generic.List[object]]::new()
    foreach ($template in $Snapshot.Templates) {
        Add-TemplateInventory $template "Template:$([string](Get-Field $template 'name' 'unnamed'))"
    }
    foreach ($definition in $Snapshot.Definitions) {
        $properties = Get-Field $definition 'properties' @{}
        $ui = Get-Field $properties 'connectorUiConfig' (Get-Field $properties 'uiConfig' @{})
        $name = [string](Get-Field $definition 'name' '')
        Add-Candidate $ui @([string](Get-Field $ui 'id' ''), $name) ([string](Get-Field $ui 'title' $name)) "Definition:$name" -Metadata @($definition, $properties)
    }
    foreach ($connector in $Snapshot.Inventory) {
        $properties = Get-Field $connector 'properties' @{}
        $kind = [string](Get-Field $connector 'kind' '')
        $name = [string](Get-Field $connector 'name' '')
        if ($kind -in $script:UiOnlyKinds) {
            $ui = Get-Field $properties 'connectorUiConfig' (Get-Field $properties 'uiConfig' @{})
            Add-Candidate $ui @([string](Get-Field $ui 'id' ''), $name) ([string](Get-Field $ui 'title' $name)) "${kind}:$name" -Metadata @($connector, $properties)
        } else {
            $definitionName = [string](Get-Field $properties 'connectorDefinitionName' (Get-Field $properties 'dataConnectorDefinitionName' ''))
            Add-Candidate @{} @($definitionName, "runtime:$name") $kind "Runtime:$name" $connector $kind -Metadata @($connector, $properties) -CopilotSource:(Test-CopilotSource $connector)
        }
    }
    Merge-Inventory
}

function Get-NewConnectorSourceTokens($Before, $After) {
    $tokens = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in @($After.TemplateNames | Where-Object { $_ -notin $Before.TemplateNames })) { [void]$tokens.Add("Template:$name") }
    foreach ($name in @($After.DefinitionNames | Where-Object { $_ -notin $Before.DefinitionNames })) { [void]$tokens.Add("Definition:$name") }
    foreach ($name in @($After.RuntimeNames | Where-Object { $_ -notin $Before.RuntimeNames })) {
        [void]$tokens.Add("Runtime:$name")
        foreach ($kind in $script:UiOnlyKinds) { [void]$tokens.Add("${kind}:$name") }
    }
    return ,$tokens
}

function Test-RecordFromNewConnector($Record, [Collections.Generic.HashSet[string]]$NewSourceTokens) {
    foreach ($source in @($Record.Sources)) {
        foreach ($token in $NewSourceTokens) {
            if ($source -eq $token -or $source.StartsWith("$token/", [StringComparison]::OrdinalIgnoreCase)) { return $true }
        }
    }
    return $false
}

function Get-WindowsSecurityEventEvidence {
    if (-not $WindowsSecurityEventMachineIds.Count) {
        return @{ ConnectorStatus = 'Required inputs: machine/filter selection'; Existing = 'No explicit machine IDs supplied; no fleet inferred.'; Verified = $null }
    }
    $dcrId = if ($WindowsSecurityEventDcrId) { $WindowsSecurityEventDcrId.TrimEnd('/') }
        else { "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/Sentinel-SecurityEvent-$((Get-StableName $script:WorkspaceId).Substring(0, 12))" }
    $dcr = Read-OptionalConnectorDependency "${dcrId}?api-version=2024-03-11"
    if (-not $dcr) { return @{ ConnectorStatus = 'Not configured (DCR missing)'; Existing = "DCR=$dcrId"; Verified = $false } }
    try { Assert-SecurityEventDcr $dcr $dcrId }
    catch {
        if (-not $_.Exception.Data['CopilotActionRequired']) { throw }
        return @{ ConnectorStatus = 'Action required (DCR needs review)'; Existing = $_.Exception.Message; Verified = $false }
    }
    $details = [Collections.Generic.List[string]]::new()
    $ready = 0
    $machineIds = @($WindowsSecurityEventMachineIds | ForEach-Object { $_.TrimEnd('/') } | Select-Object -Unique)
    foreach ($id in $machineIds) {
        if ($id -notmatch '^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/?#]+/providers/Microsoft\.Compute/virtualMachines/[^/?#]+$' -or $id.Split('/')[2] -notin $SourceSubscriptionIds) {
            $details.Add("Unsupported/out-of-source-scope machine: $id"); continue
        }
        $extensions = @(Read-ArmList "$id/extensions?api-version=2024-03-01" | Where-Object {
            (Get-Field $_.properties 'publisher' '') -eq 'Microsoft.Azure.Monitor' -and
            (Get-Field $_.properties 'type' '') -eq 'AzureMonitorWindowsAgent' -and
            (Get-Field $_.properties 'provisioningState' '') -eq 'Succeeded'
        })
        $associations = @(Read-ArmList "$id/providers/Microsoft.Insights/dataCollectionRuleAssociations?api-version=2024-03-11" | Where-Object {
            (Get-Field $_.properties 'dataCollectionRuleId' '') -eq $dcrId
        })
        if ($extensions.Count -eq 1 -and $associations.Count) { $ready++ }
        $details.Add("VM=$id; AMA successfully provisioned=$($extensions.Count); matching DCR associations=$($associations.Count)")
    }
    return @{
        ConnectorStatus = $(if ($ready -eq $machineIds.Count) { 'Configured (agent health/ingestion unverified)' } else { 'Partially configured (agent/association missing)' })
        Existing = "DCR=$dcrId; $($details -join '; ')"; Verified = $true
        Verification = 'Read-only ARM verification of approved DCR, extension provisioning and associations, not host audit/network/ingestion.'
        PolicyOrDiagnosticSetting = $dcrId
    }
}

function Get-ConnectorRecordEvidence($Record) {
    $key = [string]$Record.Key
    $policyOrSetting = 'N/A'
    $status = 'Unknown'
    $existing = "Installed connector artifact(s): $($Record.Sources -join '; ')"
    if ($Record.DeprecationEvidence.Count -gt 0) {
        $status = 'Not assessed (deprecated/skipped)'
        $policyOrSetting = 'N/A (skipped)'
    } elseif ($key -eq 'WindowsSecurityEvents') {
        return Get-WindowsSecurityEventEvidence
    } elseif ($key -in @('EntraDiagnostics', 'AzureActivity', 'AzureStorageAccount', 'AzureNSG', 'MicrosoftPurview')) {
        return Get-DiagnosticRecordEvidence $Record
    } else {
        $kind = @($script:NativeAdapters.Keys | Where-Object { $script:NativeAdapters[$_].Key -eq $key } | Select-Object -First 1)
        if ($kind.Count -gt 0) {
            $adapter = $script:NativeAdapters[$kind[0]]
            $instances = @($Record.Instances)
            if ($instances.Count -gt 0) {
                $states = @($instances | ForEach-Object { Get-NativeStatus $_ $adapter.Types } | Select-Object -Unique)
                $status = $states -join '; '
                $policyOrSetting = 'N/A (native connector)'
                $existing = @($instances | ForEach-Object {
                    $properties = Get-Field $_ 'properties' @{}
                    $scopeValue = [string](Get-Field $properties $adapter.Scope '')
                    Get-NativeConfiguration $_ ([string](Get-Field $_ 'kind' $kind[0])) $adapter.Scope $scopeValue $adapter.Types
                }) -join '; '
            } else {
                $status = 'Not configured'
                $policyOrSetting = 'N/A (native connector)'
            }
        } elseif ($Record.Instances.Count -gt 0) {
            $runtimeStates = @($Record.Instances | ForEach-Object {
                $kind = [string](Get-Field $_ 'kind' 'UnknownKind')
                $properties = Get-Field $_ 'properties' @{}
                $tenant = [string](Get-Field $properties 'tenantId' '')
                $subscription = [string](Get-Field $properties 'subscriptionId' '')
                $scope = if ($tenant) { "tenantId=$tenant" } elseif ($subscription) { "subscriptionId=$subscription" } else { 'scope=unknown' }
                "$kind ($scope): state cannot be verified by an automatic adapter"
            })
            $status = 'Runtime exists; connection state not automatically verifiable'
            $existing = $runtimeStates -join '; '
        }
    }
    @{
        Existing = $existing
        Requested = 'Read-only inventory/status assessment; no configuration changes requested.'
        Verified = $null
        Verification = 'ConnectorStatus is ARM-observed configuration where supported, not proof of portal Connected state or data ingestion.'
        ConnectorStatus = $status
        PolicyOrDiagnosticSetting = $policyOrSetting
    }
}

function Get-DiagnosticRecordEvidence($Record) {
    $key = [string]$Record.Key
    $scopes = switch ($key) {
        'EntraDiagnostics' { '/providers/Microsoft.AADIAM' }
        'AzureActivity' { $SourceSubscriptionIds | ForEach-Object { "/subscriptions/$_" } }
        default {
            if ($script:ExplicitDiagnosticSources) {
                $DiagnosticResourceIds | Where-Object {
                    (Get-ResourceAdapter $_) -eq $key -and $_.Split('/')[2] -in $SourceSubscriptionIds
                } | ForEach-Object { $_.TrimEnd('/') }
            } else { Find-DiagnosticSources $key $Record.Title }
        }
    }
    $scopes = @($scopes | Select-Object -Unique)
    if (-not $scopes.Count) {
        return @{
            ConnectorStatus = 'No sources found in selected scope'
            Existing = 'No matching source resources in the selected subscriptions/resource IDs.'
            Verified = $null
            Verification = 'Source inventory only; no diagnostic configuration or ingestion established.'
        }
    }
    $details = [Collections.Generic.List[string]]::new()
    $names = [Collections.Generic.List[string]]::new()
    $complete = 0
    $coveredCount = 0
    foreach ($scope in $scopes) {
        $isEntra = $key -eq 'EntraDiagnostics'
        $root = if ($isEntra) { $scope } else { "$scope/providers/Microsoft.Insights" }
        $api = if ($isEntra) { '2017-04-01' } else { $MonitorApiVersion }
        $categories = @(switch ($key) {
            'EntraDiagnostics' {
                $selection = Get-EntraLogSelection
                $selection.Categories
            }
            'AzureActivity' { 'Administrative', 'Security', 'ServiceHealth', 'Alert', 'Recommendation', 'Policy', 'Autoscale', 'ResourceHealth' }
            'AzureStorageAccount' { 'StorageRead', 'StorageWrite', 'StorageDelete' }
            'AzureNSG' { 'NetworkSecurityGroupEvent', 'NetworkSecurityGroupRuleCounter' }
            'MicrosoftPurview' { 'DataSensitivityLogEvent' }
        })
        if (-not $categories.Count) { throw "No diagnostic categories could be assessed for $scope." }
        $settings = @(Read-ArmList "$root/diagnosticSettings?api-version=$api")
        $coverage = Get-DiagnosticCoverage $settings $categories
        $uncovered = $coverage.Missing
        if (-not $uncovered.Count) { $complete++ }
        $coveredCount += $categories.Count - $uncovered.Count
        foreach ($name in $coverage.Names) { $names.Add("$scope/$name") }
        $details.Add("${scope}: covered=$($categories.Count - $uncovered.Count)/$($categories.Count); missing=$($uncovered -join ', '); covering settings=$($coverage.Names -join ', '); setting count=$($coverage.Count)/5")
    }
    $allCoverageUnknown = $key -eq 'EntraDiagnostics' -and (Get-EntraLogSelection).UsedReferenceFallback
    @{
        ConnectorStatus = $(if ($allCoverageUnknown -and $complete -eq $scopes.Count) { 'Partially configured (six reference categories verified; all-category coverage unknown)' }
            elseif ($complete -eq $scopes.Count) { 'Configured (ingestion unverified)' }
            elseif ($coveredCount -gt 0) { 'Partially configured' } else { 'Not configured for selected categories' })
        Existing = $details -join '; '
        Verified = $true
        Verification = "Read-only diagnostic settings GET for $($scopes.Count) selected source(s); does not prove event ingestion." +
            $(if ($allCoverageUnknown) { ' Category discovery unavailable: only the six reference categories were assessed, not all tenant categories.' } else { '' })
        PolicyOrDiagnosticSetting = $names -join '; '
    }
}

function Get-ConnectorRequirementReview($Record, $Evidence, [object[]]$Actions) {
    $stages = [Collections.Generic.List[object]]::new()
    function Add-RequirementStage([string]$Name, [bool]$Required, [string]$Status, [string]$Detail, [string[]]$Inputs = @(), [string]$Proof = '') {
        $stages.Add([pscustomobject]@{
            Stage = $Name; Required = $Required; Status = $Status; Detail = $Detail
            RequiredInputs = $Inputs; Evidence = $Proof
        })
    }
    $key = [string]$Record.Key
    $sourceActions = @($Actions | Where-Object ConfigurationStage -ne 'Policy')
    $configured = @($sourceActions | Where-Object Status -in @('Configured', 'AlreadyConfigured'))
    $failed = @($sourceActions | Where-Object Status -eq 'Failed')
    $needsInput = @($sourceActions | Where-Object Status -in @('ActionRequired', 'NoSourcesFound'))
    $planned = @($sourceActions | Where-Object Status -eq 'Planned')
    $sourceState = if ($failed.Count) { 'Failed' } elseif ($needsInput.Count) { 'ActionRequired' }
        elseif ($planned.Count) { 'Planned' } elseif ($configured.Count) { 'VerifiedControlPlane' }
        elseif ((Get-Field $Evidence 'ConnectorStatus' '') -match '^(Enabled|Configured)') { 'ObservedControlPlane' }
        else { 'NotVerified' }
    $proof = (@($configured | ForEach-Object { "$($_.Connector): $($_.VerificationEvidence) $($_.Detail)" }) -join '; ')
    if (-not $proof) { $proof = [string](Get-Field $Evidence 'Existing' '') }
    $native = @($script:NativeAdapters.Keys | Where-Object { $script:NativeAdapters[$_].Key -eq $key })
    $diagnostic = $key -in @('EntraDiagnostics', 'AzureActivity', 'AzureStorageAccount', 'AzureNSG', 'MicrosoftPurview')
    $runtimeKinds = @($Record.Instances | ForEach-Object { Get-Field $_ 'kind' '' }) + @($Record.UnsupportedTemplateKinds)
    if ($Record.DeprecationEvidence.Count) {
        Add-RequirementStage 'Lifecycle' $true 'Retired' ($Record.DeprecationEvidence -join '; ') @('Migrate through the supported replacement connector; retired sources remain untouched.')
    } elseif ($native.Count -and $key -ne 'MicrosoftThreatIntelligence') {
        Add-RequirementStage 'SentinelRuntimeAPI' $true $sourceState "Reviewed $($native[0]) dataConnectors API; current source selections are preserved, including partially enabled workloads." @() $proof
        $partial = @($Record.Instances | Where-Object {
            $types = Get-Field (Get-Field $_ 'properties' @{}) 'dataTypes' @{}
            @($types.Values | Where-Object { (Get-Field $_ 'state' '') -eq 'Enabled' }).Count -gt 0 -and
            @($script:NativeAdapters[$native[0]].Types | Where-Object { (Get-Field (Get-Field $types $_ @{}) 'state' '') -ne 'Enabled' }).Count -gt 0
        })
        if ($partial.Count) { Add-RequirementStage 'WorkloadSelection' $false 'PreservedSelection' 'Only the existing selected workloads remain enabled; no missing workload is silently enabled.' @('Review the connector page if you intend to broaden the source/workload selection.') }
        $prerequisites = switch ($key) {
            Office365 { @('Microsoft 365 tenant audit entitlement and unified audit logging for selected workloads', 'Tenant administrator consent/source permissions for OfficeActivity') }
            IdentityProtection { @('Entra ID Protection licensing and active tenant security role', 'Confirm XDR coverage before any standalone alerts (duplicate incidents prevented)') }
            MicrosoftThreatProtection { @('Defender source product licensing, tenant security permissions and product onboarding', 'Advanced-hunting event streams and incident-rule duplication choices on the XDR connector page') }
            AzureSecurityCenter { @('Explicit legacy connector selection versus tenant-based Defender for Cloud', 'Defender source licensing/export coverage; no paid plan activation') }
        }
        Add-RequirementStage 'SourceAuthorizationAndAudit' $true 'ManualVerification' 'An ARM-enabled connector does not verify upstream entitlement, audit production or tenant consent.' $prerequisites
    } elseif ($diagnostic) {
        Add-RequirementStage 'DiagnosticSettings' $true $sourceState 'Reviewed Azure Monitor/source diagnostic APIs configure selected categories to this workspace, retaining other settings and destinations.' @() $proof
        $inputs = switch ($key) {
            EntraDiagnostics { @('Entra licensing/active tenant role; All uses six reference categories if discovery is unavailable, with additional categories requiring review; ingestion costs may increase') }
            AzureActivity { @('Approved SourceSubscriptionIds and diagnosticSettings read/write permission') }
            AzureStorageAccount { @('Existing blob/file/queue/table resources and approved SourceSubscriptionIds/DiagnosticResourceIds; service requests must generate logs') }
            AzureNSG { @('Approved NSG sources; diagnostic events/counters are not Network Watcher flow logs') }
            MicrosoftPurview { @('Microsoft.Purview/accounts DataSensitivityLogEvent source activity and permissions; this is not Microsoft 365 Purview audit') }
        }
        Add-RequirementStage 'SourceScopeAndPermissions' $true 'ManualVerification' 'Selected ARM categories/routing are verified separately from source-side activity and business authorization.' $inputs
    } elseif ($key -eq 'MicrosoftCopilot') {
        Add-RequirementStage 'CopilotDcrDceRuntime' $true $sourceState 'Exact MicrosoftCopilot/CopilotGeneral PurviewAudit adapter verifies DCR/DCE routing and activates the Sentinel runtime API; no /connect, credentials or Logic App connections.' @($(if (-not $ConfigureCopilot) { 'Explicit -ConfigureCopilot approval; optional compatible CopilotDataCollectionRuleId/CopilotDataCollectionEndpointId' })) $proof
        Add-RequirementStage 'SourceAuthorizationAndAudit' $true 'ManualVerification' 'Copilot licensing, unified audit logging and active Security Administrator/Global Administrator source authorization are not provisioned or inferred.' @('Verify eligible Copilot license, tenant consent/auditing and CopilotActivity generation.')
    } elseif ($key -eq 'WindowsSecurityEvents') {
        Add-RequirementStage 'AmaDcrMachineAssociation' $true $sourceState 'Explicit Windows Azure VM adapter validates/provisions the SecurityEvent DCR, optionally installs missing AMA, and associates selected machines. No implicit fleet scope.' @($(if (-not $WindowsSecurityEventMachineIds.Count) { 'WindowsSecurityEventMachineIds plus approved XPath queries or an existing WindowsSecurityEventDcrId' })) $proof
        Add-RequirementStage 'HostAndNetworkPrerequisites' $true 'ManualVerification' 'Agent extension provisioning is not guest audit-policy, heartbeat, network or event-ingestion verification. Arc/private-link/DCE/VMSS scenarios are outside this adapter.' @('Existing system-assigned VM identity; separate InstallWindowsAzureMonitorAgent approval if AMA is missing', 'Required host audit subcategories, outbound Azure Monitor access, and SecurityEvent data; no guest scripts or audit policy changes')
    } elseif ($key -eq 'WindowsFirewallAma') {
        Add-RequirementStage 'FirewallHostAmaCollection' $true 'RequiredInput' 'No reviewed host-firewall/DCR adapter is executed. Firewall logging is host-specific and cannot be inferred from an installed template.' @('Explicit machine/Arc scope, firewall logging paths/categories, AMA identity/network and approved Windows Firewall DCR/DCE', 'Enable host firewall logging and associate the reviewed DCR through the Windows Firewall via AMA connector page; validate ingestion')
    } else {
        $protocol = if (@($runtimeKinds | Where-Object { $_ -in @('RestApiPoller', 'APIPolling', 'GenericUI', 'Customizable', 'PurviewAudit') }).Count) {
            'Installed API/CCF or PurviewAudit runtime/definition'
        } else { 'Installed connector definition/runtime' }
        $inputs = @('Review the exact installed connector identities, permissions, data types and instruction metadata below; no title-based adapter or arbitrary instruction execution.')
        if (@($Record.Aliases + @($key) | Where-Object { $_ -match 'Taxii' }).Count) {
            $inputs += 'Approved TAXII API root, collection IDs, polling/lookback and secret credentials/consent through the supported connector page.'
        } elseif ('PurviewAudit' -in $runtimeKinds) {
            $inputs += 'Exact connectorDefinitionName/sourceType, licensed Microsoft 365 audit workload, tenant permissions/consent and supported DCR/stream contract. Only MicrosoftCopilot/CopilotGeneral is automated.'
        } else {
            $inputs += 'For API/CCF: vendor endpoint/region, source account or tenant, authentication type, application/API permissions, secret provisioning and polling/collection choices. Configure secrets only through the supported connector flow; this script accepts none.'
            $inputs += 'For agent/export-based sources: explicit machines/resources, export/audit configuration, collection filters, destination schema and ingestion validation.'
        }
        Add-RequirementStage 'ConnectorSpecificSetup' $true 'RequiredInput' "$protocol has no verified automatic activation adapter. Identities=$($Record.Aliases -join ', '); kinds=$($runtimeKinds -join ', '). Runtime existence alone is not configured/connected evidence." $inputs $proof
    }
    $metadata = @(Get-Field $Record 'RequirementMetadata' @())
    Add-RequirementStage 'InstalledRequirementMetadata' $true $(if ($metadata.Count -or $Record.Requirements.Count -or $Record.Instructions.Count) { 'ReviewRequired' } else { 'Unavailable' }) 'Installed permissions, data types, connectivity criteria and instructions are reference evidence, never executable commands or proof of fulfilled prerequisites.' @() (ConvertTo-Json @{
        Metadata = $metadata; Requirements = $Record.Requirements; Instructions = $Record.Instructions
    } -Depth 40 -Compress)
    if ($key -in @('AzureActivity', 'AzureNSG', 'AzureStorageAccount')) {
        $policy = @($Actions | Where-Object ConfigurationStage -eq 'Policy')
        $policyStatus = if (-not $ConfigureConnectorPolicies) { 'OptionalNotRequested' }
            elseif (@($policy | Where-Object Status -eq 'Failed').Count) { 'Failed' }
            elseif (@($policy | Where-Object Status -eq 'ActionRequired').Count) { 'ActionRequired' }
            elseif (@($policy | Where-Object Status -match 'Pending').Count) { 'Pending' } else { 'SeePolicyActions' }
        Add-RequirementStage 'FutureResourcePolicy' $false $policyStatus 'Optional recurring governance, NOT a prerequisite for current sources already configured through diagnostics. Assignment/grant/remediation outcomes do not establish connector connectivity.' @() (@($policy | ForEach-Object { "$($_.Status): $($_.Detail)" }) -join '; ')
    }
    Add-RequirementStage 'IngestionValidation' $true 'ManualVerification' 'No data-plane query, portal Connected state, retention or billing assertion is inferred from ARM configuration.' @('Generate source activity; check the connector data types/connectivity criteria, ingestion latency and relevant table/agent heartbeat in this workspace.')
    $outcome = if ($failed.Count) { 'ConfigurationFailed' }
        elseif ($Record.DeprecationEvidence.Count) { 'RetiredSourceSkipped' }
        elseif (@($stages | Where-Object { $_.Required -and $_.Status -in @('RequiredInput', 'ActionRequired') }).Count) { 'RequiredInputsOrManualSetup' }
        elseif ($planned.Count) { 'PlannedNotApplied' }
        elseif ($sourceState -in @('VerifiedControlPlane', 'ObservedControlPlane')) { 'ControlPlaneConfigured_ExternalPrerequisitesUnverified' }
        else { 'ConfigurationNotVerified_ReviewRequired' }
    return @{
        Stages = $stages.ToArray()
        Inputs = @($stages | Where-Object Required | ForEach-Object RequiredInputs | Select-Object -Unique)
        Outcome = $outcome
    }
}

function Add-AllConnectorStatus($Snapshot, [string]$NoAttemptReason) {
    $records = @(Get-ConnectorRecords $Snapshot)
    foreach ($record in $records) {
        $script:CurrentRecord = $record
        $script:Operation = @{}
        $actions = @($script:ConnectorReport | Where-Object {
            $_.RowType -eq 'Action' -and $_.Status -ne 'Discovered' -and
            (($_.ConnectorKey -and $_.ConnectorKey -eq $record.Key) -or
                @($_.Sources | Where-Object { $_ -in $record.Sources }).Count -gt 0)
        })
        try {
            $evidence = Get-ConnectorRecordEvidence $record
            $detail = if ($actions.Count) {
                'Configuration action outcomes this run: ' + (($actions.Status | Select-Object -Unique) -join ', ') + '. See Action rows for per-source success/failure.'
            } else { $NoAttemptReason }
            $status = if ($actions.Count) { 'Observed' } else { 'NotAttempted' }
            Add-ConnectorResult $record.Title $status $detail (Get-SetupGuidance $record.Key) $evidence
            $review = Get-ConnectorRequirementReview $record $evidence $actions
            $row = $script:ConnectorReport[$script:ConnectorReport.Count - 1]
            $row.RequirementStages = $review.Stages
            $row.RemainingInputs = $review.Inputs
            $row.OverallOutcome = $review.Outcome
        } catch {
            Add-ConnectorResult $record.Title 'Failed' "Status read failed: $($_.Exception.Message)" 'Connection state is unknown. Resolve the read error; no configuration write was attempted by this assessment.' @{ ConnectorStatus = 'Unknown (status read failed)' }
        }
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].RowType = 'Inventory'
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].AppliedSuccessfully = $null
    }
    $script:CurrentRecord = $null
    $script:Operation = @{}
    if (-not $records.Count) {
        Add-ConnectorResult 'Connector inventory' 'NotAttempted' 'No data connector templates, definitions or runtime instances were returned for this workspace.' 'Package installation is not evidence of a configured connector.'
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].RowType = 'Inventory'
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].AppliedSuccessfully = $null
    }
}

function Get-ConnectorDisplaySummary($Row, [array]$Actions) {
    $name = switch ($Row.Connector) {
        'MicrosoftThreatProtection' { 'Microsoft Defender XDR' }
        'Office365' { 'Microsoft 365' }
        'MicrosoftCloudAppSecurity' { 'Microsoft Defender for Cloud Apps' }
        'AzureAdvancedThreatProtection' { 'Microsoft Defender for Identity' }
        'MicrosoftDefenderAdvancedThreatProtection' { 'Microsoft Defender for Endpoint' }
        'OfficeATP' { 'Microsoft Defender for Office 365' }
        default { $Row.Connector }
    }
    $state = switch -Regex ($Row.ConnectorStatus) {
        '^Not assessed.*(deprecated|skipped)' { 'Retired'; break }
        '^(Enabled|Configured) \(' { 'Configured'; break }
        '^Partially configured' { 'Partly configured'; break }
        '^Not configured' { 'Not configured'; break }
        '^No sources found' { 'No sources found'; break }
        '^Required inputs' { 'Needs your input'; break }
        default { 'Not verified' }
    }
    $matched = @($Actions | Where-Object {
        $_.ConfigurationStage -ne 'Policy' -and
        (($_.ConnectorKey -and $_.ConnectorKey -eq $Row.ConnectorKey) -or
            @($_.Sources | Where-Object { $_ -in $Row.Sources }).Count -gt 0)
    })
    $result = if ($Row.Status -eq 'Failed') { 'Status check failed' }
        elseif (@($matched | Where-Object Status -eq 'Failed').Count) { 'Setup failed' }
        elseif (@($matched | Where-Object Status -eq 'ActionRequired').Count) { 'Needs attention' }
        elseif (@($matched | Where-Object Status -eq 'Configured').Count) { 'Changes applied' }
        elseif (@($matched | Where-Object Status -eq 'AlreadyConfigured').Count) { 'Already configured' }
        elseif (@($matched | Where-Object Status -eq 'Planned').Count) { 'Preview / not applied' }
        elseif (@($matched | Where-Object Status -eq 'NoSourcesFound').Count) { 'No sources found' }
        elseif ($state -eq 'Retired' -or @($matched | Where-Object Status -eq 'Skipped').Count) { 'Skipped' }
        else { 'Not attempted' }
    $next = if ($result -eq 'Setup failed') { 'Resolve the setup error; see failure details below.' }
        elseif ($result -eq 'Status check failed') { 'Restore read access, then run the status check again.' }
        elseif ($state -eq 'Retired') { 'Use the supported replacement connector.' }
        elseif ($result -eq 'Preview / not applied') { 'Review the plan before applying changes.' }
        elseif ($state -eq 'No sources found') { 'Select or create a supported source resource.' }
        elseif ($state -eq 'Configured' -and $result -ne 'Needs attention') { 'Verify incoming data; ingestion is not checked here.' }
        else {
            switch ($Row.ConnectorKey) {
                'MicrosoftCopilot' { 'Review Copilot auditing, consent and DCR/DCE setup.' }
                'Office365' { 'Review tenant audit permissions and selected workloads.' }
                'MicrosoftThreatProtection' { 'Review Defender licensing and XDR source coverage.' }
                'IdentityProtection' { 'Confirm XDR coverage before enabling standalone alerts.' }
                'WindowsSecurityEvents' { 'Provide machine IDs and event filters (or an existing DCR).' }
                'WindowsFirewallAma' { 'Configure host firewall logging, AMA and its collection rule.' }
                'AzureSecurityCenter' { 'Choose legacy subscription or tenant-based collection.' }
                { $_ -in @('AzureActivity', 'EntraDiagnostics', 'AzureStorageAccount', 'AzureNSG', 'MicrosoftPurview') } {
                    'Review source selection, permissions and diagnostic settings.'
                }
                { $_ -match 'Taxii' } { 'Provide the TAXII endpoint, collection and credentials.' }
                default { 'Review the connector setup page; manual input may be needed.' }
            }
        }
    [pscustomobject]@{ Connector = $name; State = $state; ThisRun = $result; NextStep = $next }
}

function Add-ContentHubPackageDiagnosticRows {
    if (-not (Get-Variable ContentHubPackageDiagnostics -Scope Script -ErrorAction SilentlyContinue)) { return }
    foreach ($diagnostic in @($script:ContentHubPackageDiagnostics.Values)) {
        $issues = @($diagnostic.Artifacts | Where-Object Outcome -notin @('Present', 'SharedPresent'))
        $installationStatus = Get-ContentHubField $diagnostic 'InstallationStatus'
        $status = if ($diagnostic.State -in @('Missing', 'ReadFailed') -or @($issues | Where-Object Outcome -eq 'ReadFailed').Count) { 'Failed' }
            elseif ($diagnostic.State -in @('Unverified', 'NotFullyInspected', 'Pending') -or ($installationStatus -and $installationStatus -ne 'Installed')) { 'ActionRequired' } else { 'Verified' }
        Add-ConnectorResult "Content Hub package / $($diagnostic.Solution)" $status $diagnostic.Detail 'Inspect PackageEvidence.Artifacts for exact expected/observed IDs, versions and GET results. Use -ContentStatusOnly -ConnectorReportPath <file.json> to collect read-only evidence; no reinstall is required to diagnose.' @{
            Attempted = $false; Verified = $null; ConnectorStatus = 'Not applicable (package verification)'
        }
        $row = $script:ConnectorReport[$script:ConnectorReport.Count - 1]
        $row.RowType = 'Package'
        $row | Add-Member PackageEvidence $diagnostic
    }
}

function Write-ConnectorReport {
    $connectorOutcomes = $script:ConnectorReport.ToArray()
    $actions = @($connectorOutcomes | Where-Object RowType -eq 'Action')
    $inventory = @($connectorOutcomes | Where-Object RowType -eq 'Inventory')
    $summary = @($inventory | ForEach-Object { Get-ConnectorDisplaySummary $_ $actions } | Sort-Object Connector)
    Step 'Connector summary'
    Write-Host "$($summary.Count) connectors | Configured: $(@($summary | Where-Object State -eq 'Configured').Count) | Partly configured: $(@($summary | Where-Object State -eq 'Partly configured').Count) | Retired: $(@($summary | Where-Object State -eq 'Retired').Count)"
    Write-Host 'Current state and this-run results are separate. Configured does not confirm incoming data.'
    if (-not @($actions | Where-Object { $_.WriteAttempted -and $_.ConfigurationStage -ne 'Policy' }).Count) {
        Write-Host 'No connector configuration writes were attempted in this run.' -ForegroundColor Yellow
        if (-not (Get-Variable ContentStatusOnly -ValueOnly -ErrorAction SilentlyContinue) -and @($connectorOutcomes | Where-Object { $_.RowType -eq 'Package' -and $_.Status -eq 'Failed' }).Count) {
            Write-Host 'Package verification blocked setup. Package errors are separate from connector health; see exact artifact evidence below/in JSON.' -ForegroundColor Yellow
        }
    }
    # Stacked short lines avoid Cloud Shell dropping rightmost table columns.
    foreach ($item in $summary) {
        Write-Host "`n$($item.Connector)"
        Write-Host "  State: $($item.State) | This run: $($item.ThisRun)"
        Write-Host "  Next: $($item.NextStep)"
    }
    $policies = @($actions | Where-Object ConfigurationStage -eq 'Policy')
    if ($policies.Count) {
        Step 'Azure Policy (separate from connector status)'
        Write-Host "Assignments: $(@($policies | Where-Object Status -eq 'PolicyAssigned').Count) | Pending: $(@($policies | Where-Object { $_.Status -in @('PolicyPending', 'RemediationPending') }).Count) | Failed: $(@($policies | Where-Object Status -eq 'Failed').Count) | Needs attention: $(@($policies | Where-Object Status -eq 'ActionRequired').Count)"
        Write-Host 'Policy assignment does not mean remediation or data collection is complete. Exact scopes and pending actions are in the detailed report.'
    }
    $content = @($connectorOutcomes | Where-Object RowType -eq 'Content')
    if ($content.Count) {
        Step 'Analytics rules (not connector failures)'
        Write-Host "$(@($content | Where-Object Status -eq 'Failed').Count) rule deployment(s) failed. See Content rows in the detailed report." -ForegroundColor Yellow
    }
    $packages = @($connectorOutcomes | Where-Object RowType -eq 'Package')
    if ($packages.Count) {
        Step 'Content Hub package verification (separate from connectors)'
        Write-Host "$($packages.Count) packages checked | Failed: $(@($packages | Where-Object Status -eq 'Failed').Count) | Partial/review: $(@($packages | Where-Object Status -eq 'ActionRequired').Count)"
        foreach ($row in $packages) {
            $shared = @($row.PackageEvidence.Artifacts | Where-Object Outcome -eq 'SharedPresent')
            if ($shared.Count) { Write-Host "$($row.PackageEvidence.Solution): $($shared.Count) SharedPresent (verified shared packaged templates; not runtime configuration/ingestion)." }
        }
        foreach ($row in @($packages | Where-Object Status -eq 'Failed')) {
            Write-Host "$($row.PackageEvidence.Solution): $($row.PackageEvidence.Missing.Count) missing/outdated/conflicting artifact(s)." -ForegroundColor Yellow
            foreach ($artifact in @($row.PackageEvidence.Artifacts | Where-Object Outcome -notin @('Present', 'SharedPresent') | Select-Object -First 3)) {
                $identity = if ($artifact.ExpectedResourceId) { ($artifact.ExpectedResourceId -split '/')[-1] } else { $artifact.ExpectedContentId }
                Write-Host "  $($artifact.Collection)/$identity [$($artifact.Outcome)]: $($artifact.Reason)"
            }
        }
        Write-Host 'Exact expected and observed IDs/parents/versions/API read results are retained in Package rows of the JSON report; no connector credentials or template/query bodies are exported.'
    }
    $failures = @($connectorOutcomes | Where-Object { $_.Status -eq 'Failed' -and $_.RowType -notin @('Content', 'Package') })
    if ($failures.Count) {
        Step 'Setup / status-check failures'
        foreach ($row in $failures) {
            $shortError = ($row.ErrorMessage -replace '/subscriptions/[^\s;,)]+', '[resource ID in detailed report]') -replace '\s+', ' '
            if ($shortError.Length -gt 200) { $shortError = $shortError.Substring(0, 197) + '...' }
            Write-Host "$($row.Connector.Split(' / ')[0]): $shortError" -ForegroundColor Red
        }
    }
    foreach ($row in $connectorOutcomes) {
        Write-Verbose ("[{0}] {1}`n{2}" -f $row.RowType, $row.Connector, (ConvertTo-Json $row -Depth 40))
    }
    Write-Host "`nFull requirements, source IDs and error details: use -ConnectorReportPath <file.json> or -Verbose."
    if ($ConnectorReportPath) {
        # The report is a local artifact, including in Azure-read-only mode.
        $json = ConvertTo-Json -InputObject $connectorOutcomes -Depth 40
        [IO.File]::WriteAllText($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConnectorReportPath), $json, [Text.UTF8Encoding]::new($false))
        Write-Host "Connector JSON report saved: $ConnectorReportPath"
    }
    if ($PassThru) { $connectorOutcomes }
}

function Invoke-NewConnectorConfiguration($BeforeSnapshot, $AfterSnapshot) {
    Step 'Reconcile all installed Sentinel data connectors'
    $script:Inventory = $AfterSnapshot.Inventory
    $script:ConnectorDefinitions = $AfterSnapshot.Definitions
    $script:Connectors = @($AfterSnapshot.Inventory | Where-Object { (Get-Field $_ 'kind' '') -notin $script:UiOnlyKinds })
    $newSourceTokens = Get-NewConnectorSourceTokens $BeforeSnapshot $AfterSnapshot
    $records = @(Get-ConnectorRecords $AfterSnapshot)
    Write-Host "New artifact groups: $($newSourceTokens.Count); ALL installed connector records selected: $($records.Count). Existing selections are preserved."
    if ($records.Count -eq 0) {
        Write-Host 'No installed connector records detected. No configuration attempted.'
        return
    }
    Step 'Review connector requirement stages before configuration'
    foreach ($record in $records) {
        $review = Get-ConnectorRequirementReview $record @{ Existing = "Installed identities: $($record.Aliases -join ', ')" } @()
        $stageSummary = @($review.Stages | ForEach-Object { "$($_.Stage) [$($_.Status)]" }) -join '; '
        Write-Verbose "$($record.Title): $stageSummary"
    }
    $script:CurrentRecord = $null
    if ($SourceSubscriptionIds.Count -eq 0) { $script:SourceSubscriptionIds = @($script:SubscriptionId) } else { $script:SourceSubscriptionIds = $SourceSubscriptionIds }
    $script:SourceSubscriptionIds = @($script:SourceSubscriptionIds | ForEach-Object { ([guid]::Parse($_)).ToString() } | Select-Object -Unique)
    $SourceSubscriptionIds = $script:SourceSubscriptionIds
    Write-Host "Source subscriptions for connector diagnostics: $($SourceSubscriptionIds -join ', ')."
    foreach ($record in @($records | Where-Object { $_.DeprecationEvidence.Count -eq 0 -and $_.Key -in @('AzureStorageAccount', 'AzureNSG', 'MicrosoftPurview') -and $_.Instances.Count -eq 0 -and $_.UnsupportedTemplateKinds.Count -eq 0 })) {
        $script:CurrentRecord = $record
        $key = $record.Key
        $selected = @(if ($script:ExplicitDiagnosticSources) {
            $DiagnosticResourceIds | Where-Object { (Get-ResourceAdapter $_) -eq $key } | ForEach-Object { $_.TrimEnd('/') }
        } else {
            Find-DiagnosticSources $key $record.Title
        })
        $script:DiagnosticSources[$key] = @($selected | Where-Object {
            $sourceSubscription = $_.Split('/')[2]
            if ($sourceSubscription -in $SourceSubscriptionIds) { $true }
            else {
                Add-ConnectorResult "$($record.Title) / $_" 'ActionRequired' 'Source is outside selected -SourceSubscriptionIds; no changes made.' 'Explicitly include its subscription after verifying ownership, then rerun.'
                $false
            }
        } | Select-Object -Unique)
    }
    $xdrActive = @($script:Connectors | Where-Object {
        (Get-Field $_ 'kind' '') -eq 'MicrosoftThreatProtection' -and
        (Get-NativeStatus $_ @('incidents', 'alerts')) -eq 'Enabled (ingestion unverified)'
    }).Count -gt 0
    $xdrPlanned = $false
    $xdrFailed = $false
    $standaloneXdrComponents = @('IdentityProtection', 'AzureAdvancedThreatProtection', 'MicrosoftDefenderAdvancedThreatProtection', 'MicrosoftCloudAppSecurity', 'OfficeATP', 'OfficeIRM')
    foreach ($record in @($records | Sort-Object @{ Expression = { if ($_.Key -eq 'MicrosoftThreatProtection') { 0 } else { 1 } } }, Title)) {
        $script:CurrentRecord = $record
        $key = [string]$record.Key
        $label = [string]$record.Title
        $guidance = Get-SetupGuidance $key
        try {
            if ($record.DeprecationEvidence.Count -gt 0) {
                Add-ConnectorResult $label 'Skipped' "Deprecated connector intentionally ignored: $($record.DeprecationEvidence -join '; ') Existing configuration was left untouched." 'No action required by this script.'
                continue
            }
            if (-not $ConfigureConnectorPolicies) { Add-ConnectorPolicyRequirements $label $key }
            $protocolIdentifiers = @($key) + @($record.Aliases) + @($record.UnsupportedTemplateKinds) + @($record.Instances | ForEach-Object { [string](Get-Field $_ 'kind' '') })
            if (@($protocolIdentifiers | Where-Object { $_ -in @('MicrosoftThreatIntelligence', 'MicrosoftDefenderThreatIntelligence', 'adapter:MicrosoftThreatIntelligence') }).Count -gt 0) {
                Add-ConnectorResult $label 'ActionRequired' 'Microsoft Defender Threat Intelligence requires source/feed entitlement and connector-page validation; existing settings were not changed.' $guidance
                continue
            }
            if (@($protocolIdentifiers | Where-Object { $_ -match 'TAXII' }).Count -gt 0 -or $label -match '\bTAXII\b') {
                Add-ConnectorResult $label 'ActionRequired' 'TAXII-dependent connector requires endpoint, collection and credential choices; no settings changed.' $guidance
                continue
            }
            $kind = @($script:NativeAdapters.Keys | Where-Object { $script:NativeAdapters[$_].Key -eq $key } | Select-Object -First 1)
            if ($kind.Count -gt 0) {
                $kind = $kind[0]
                $adapter = $script:NativeAdapters[$kind]
                $scopeProperty = $adapter.Scope
                $instances = @($record.Instances)
                $scopes = @($(if ($instances.Count) {
                    $instances | ForEach-Object { [string](Get-Field (Get-Field $_ 'properties' @{}) $scopeProperty '') } | Select-Object -Unique
                } elseif ($scopeProperty -eq 'tenantId') { $script:TenantId } else { $SourceSubscriptionIds }))
                $hasInstalledDefinition = @($record.Sources | Where-Object { $_ -match '^(Template|Definition|StaticUI|GenericUI|Customizable):' }).Count -gt 0
                if ($hasInstalledDefinition) { $scopes += @(if ($scopeProperty -eq 'tenantId') { $script:TenantId } else { $SourceSubscriptionIds }) }
                $scopes = @($scopes | Where-Object { $_ } | Select-Object -Unique)
                foreach ($scope in $scopes) {
                    $scopeLabel = "$label / $scope"
                    $scoped = @($instances | Where-Object { (Get-Field (Get-Field $_ 'properties' @{}) $scopeProperty '') -eq $scope })
                    if ($scopeProperty -eq 'subscriptionId' -and $scope -notin $SourceSubscriptionIds) {
                        Add-ConnectorResult $scopeLabel 'ActionRequired' 'Source subscription is outside selected -SourceSubscriptionIds; no changes made.' $guidance
                        continue
                    }
                    if ($scoped.Count -gt 1) {
                        Add-ConnectorResult $scopeLabel 'ActionRequired' "Multiple $kind instances for this source; no writes." 'Resolve duplicate runtime instances in Sentinel before rerunning.'
                        continue
                    }
                    if ($key -eq 'AzureSecurityCenter' -and -not $EnableLegacyDefenderForCloud) {
                        Add-ConnectorResult $scopeLabel 'ActionRequired' 'Legacy subscription-based Defender for Cloud connector was installed but not enabled. Use -EnableLegacyDefenderForCloud only if you intentionally want the legacy subscription connector.' $guidance
                        continue
                    }
                    if ($key -in $standaloneXdrComponents -and ($xdrActive -or $xdrPlanned -or $xdrFailed)) {
                        Add-ConnectorResult $scopeLabel 'ActionRequired' 'Standalone source left unchanged because Microsoft Defender XDR is active, planned or failed in this run; verify coverage and avoid duplicate incidents.' $guidance
                        continue
                    }
                    Invoke-ConnectorWork $scopeLabel {
                        $connectorApi = if ($kind -eq 'MicrosoftThreatProtection') { $PreviewApiVersion } else { $ApiVersion }
                        Enable-NativeConnector $scopeLabel $kind $scopeProperty $scope $adapter.Types $connectorApi
                    }
                    $last = if ($script:ConnectorReport.Count) { $script:ConnectorReport[$script:ConnectorReport.Count - 1] } else { $null }
                    if ($key -eq 'MicrosoftThreatProtection' -and $last) {
                        if ($last.Status -in @('Configured', 'AlreadyConfigured')) { $xdrActive = $true }
                        elseif ($last.Status -eq 'Planned') { $xdrPlanned = $true }
                        elseif ($last.Status -eq 'Failed') { $xdrFailed = $true }
                    }
                }
                continue
            }
            switch ($key) {
                'WindowsSecurityEvents' {
                    Invoke-ConnectorWork $label { Enable-WindowsSecurityEventCollection $label }
                }
                'MicrosoftCopilot' {
                    if (-not $ConfigureCopilot) {
                        Add-ConnectorResult $label 'ActionRequired' 'Copilot dependency/runtime configuration requires explicit -ConfigureCopilot; no changes made.' $guidance
                    } else {
                        Invoke-ConnectorWork $label { Enable-CopilotConnector $label $record }
                    }
                }
                'EntraDiagnostics' {
                    Invoke-ConnectorWork $label {
                        $selection = Get-EntraLogSelection
                        $requested = @($selection.Categories)
                        Write-Host "Microsoft Entra ID: requesting $($requested.Count) log categories: $($requested -join ', ')."
                        Write-Verbose 'Entra diagnosticSettings PUT uses category/enabled pairs and the selected workspace ARM resource ID; category-specific licenses/permissions and ingestion charges apply.'
                        Enable-DiagnosticConnector "$label / tenant $script:TenantId" '' $requested -Entra
                        if ($selection.UsedReferenceFallback) {
                            Add-ConnectorResult "$label / additional log categories" 'ActionRequired' 'The six reference log categories were requested and assessed; ALL tenant category coverage could not be verified because category discovery is unavailable.' 'Review other Entra log types in the portal or supply their diagnostic category IDs explicitly using -EntraLogCategories. Do not use Log Analytics table names.' @{
                                ConnectorStatus = 'Additional categories unverified'
                            }
                        }
                    }
                }
                'AzureActivity' {
                    foreach ($source in $SourceSubscriptionIds) {
                        Invoke-ConnectorWork "$label / $source" {
                            Enable-DiagnosticConnector "$label / $source" "/subscriptions/$source" @('Administrative', 'Security', 'ServiceHealth', 'Alert', 'Recommendation', 'Policy', 'Autoscale', 'ResourceHealth')
                        }
                    }
                }
                { $_ -in @('AzureStorageAccount', 'AzureNSG', 'MicrosoftPurview') } {
                    $resources = @($script:DiagnosticSources[$key])
                    if ($resources.Count -eq 0 -and $DiagnosticResourceIds.Count -gt 0) {
                        Add-ConnectorResult $label 'ActionRequired' 'No matching resource IDs within selected subscriptions. Explicit -DiagnosticResourceIds overrides automatic discovery.' $guidance
                    }
                    foreach ($resourceId in $resources) {
                        Invoke-ConnectorWork "$label / $resourceId" {
                            $categories = switch ($key) {
                                'AzureStorageAccount' { @('StorageRead', 'StorageWrite', 'StorageDelete') }
                                'AzureNSG' { @('NetworkSecurityGroupEvent', 'NetworkSecurityGroupRuleCounter') }
                                'MicrosoftPurview' { @('DataSensitivityLogEvent') }
                            }
                            $available = @(Read-ArmList "$resourceId/providers/Microsoft.Insights/diagnosticSettingsCategories?api-version=$MonitorApiVersion" |
                                Where-Object { (Get-Field $_.properties 'categoryType' '') -eq 'Logs' } | ForEach-Object { $_.name })
                            $missing = @($categories | Where-Object { $_ -notin $available })
                            if ($missing.Count -gt 0) {
                                Add-ConnectorResult "$label / $resourceId" 'ActionRequired' "Source does not advertise required log categories: $($missing -join ', '). No settings changed." $guidance
                                return
                            }
                            Enable-DiagnosticConnector "$label / $resourceId" $resourceId $categories -Dedicated:($key -eq 'AzureStorageAccount')
                        }
                    }
                }
                default {
                    if ($record.UnsupportedTemplateKinds.Count -gt 0 -and $record.Instances.Count -eq 0) {
                        Add-ConnectorResult $label 'ActionRequired' "Installed template contains unsupported native kind(s): $($record.UnsupportedTemplateKinds -join ', '). No changes made." $guidance
                    } else {
                        Add-ConnectorResult $label 'ActionRequired' 'Installed definition/template/UI is not proof of a connected source. Additional source configuration or manual verification is required.' $guidance
                    }
                }
            }
        } catch {
            Add-ConnectorResult $label 'Failed' $_.Exception.Message
            if ($key -eq 'MicrosoftThreatProtection') { $xdrFailed = $true }
        }
    }
    foreach ($resourceId in ($DiagnosticResourceIds | Select-Object -Unique)) {
        $key = Get-ResourceAdapter $resourceId
        if (-not $key -or $key -notin @($records | ForEach-Object { $_.Key })) {
            Add-ConnectorResult "Resource diagnostics / $resourceId" 'ActionRequired' 'Unsupported resource ID or matching installed connector was not detected; no changes made.' 'Install the matching connector and supply a Storage service, NSG or Purview account resource ID.'
        }
    }
    if (($WindowsSecurityEventMachineIds.Count -or $WindowsSecurityEventDcrId -or $WindowsSecurityEventXPathQueries.Count -or $InstallWindowsAzureMonitorAgent) -and
        -not @($records | Where-Object { $_.Key -eq 'WindowsSecurityEvents' -and $_.DeprecationEvidence.Count -eq 0 }).Count) {
        $script:CurrentRecord = $null
        Add-ConnectorResult 'Windows SecurityEvent prerequisites' 'ActionRequired' 'Windows collection inputs were supplied, but no nondeprecated installed WindowsSecurityEvents connector was identified. No AMA/DCR/association setup attempted.' 'Install its Content Hub solution; do not infer an adapter from a connector title.'
    }
    if ($ConfigureConnectorPolicies) {
        Step 'Opt-in reviewed connector policies (after direct source diagnostics)'
        Write-Host 'Policies/RBAC/remediation are asynchronous and not transactional. Exact IDs are recorded; no automatic rollback.'
        $policyRecords = @($records | Where-Object { $_.DeprecationEvidence.Count -eq 0 -and $_.Key -in @('AzureActivity', 'AzureNSG', 'AzureStorageAccount') })
        foreach ($record in $policyRecords) {
            $script:CurrentRecord = $record
            if (-not $ConnectorPolicyScopeIds.Count) {
                Add-ConnectorResult "$($record.Title) / policies" 'ActionRequired' 'No connector policy scopes selected; no policy, grant or remediation writes.' 'Omit -ConnectorPolicyScopeIds to use the selected Sentinel subscription, or provide scopes within -SourceSubscriptionIds.'
                continue
            }
            foreach ($scope in @($ConnectorPolicyScopeIds | ForEach-Object { $_.TrimEnd('/') } | Select-Object -Unique)) {
                foreach ($spec in @(Get-ConnectorPolicies $record.Key)) {
                    Enable-ReviewedConnectorPolicy "$($record.Title) / policy $($spec.Kind) / $scope" $spec $scope
                }
            }
        }
        if (-not $policyRecords.Count) {
            Add-ConnectorResult 'Connector policies' 'ActionRequired' 'No nondeprecated installed Activity/NSG/Storage connector was detected; no policies, grants or remediation submitted.'
        }
    } elseif ($GrantConnectorPolicyRoles -or $RemediateConnectorPolicies -or $IncludeStorageMetricsPolicy -or $ConnectorPolicyScopeIds.Count) {
        Add-ConnectorResult 'Connector policies' 'ActionRequired' 'Policy scopes/grants/remediation options require -ConfigureConnectorPolicies. No policy operations performed.'
    }
}

Step 'Prerequisites'
if ($PSVersionTable.PSVersion -lt [version]'7.2') { throw 'PowerShell 7.2+ is required.' }
'Az.Accounts', 'Az.Resources', 'Az.OperationalInsights' | ForEach-Object { Ensure-Module $_ }
if ($InstallPrerequisitesOnly -or ($DeployPreviewDetections -and -not $WhatIfPreference)) { Test-PreviewDetectionPrerequisites }
if (($InstallPrerequisitesOnly -or (-not $ConnectorStatusOnly -and -not $ContentStatusOnly -and -not $ConfigureConnectorsOnly)) -and
    -not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is unavailable. PowerShell Cloud Shell supplies Git; on another host install Git using its approved operating-system package manager, then rerun. No cloud setup was attempted.'
}
if ($InstallPrerequisitesOnly) {
    Write-Host "Prerequisite setup complete. No Azure/Graph sign-in or cloud writes attempted. Log file: $LogPath" -ForegroundColor Green
    return
}
Ensure-AzureLogin

Step 'Select target environment'
$target = Select-SentinelTarget $SubscriptionId $ResourceGroupName $WorkspaceName
$script:SubscriptionId = $target.SubscriptionId
$context = $target.Context
$script:TenantId = [string]$context.Tenant.Id
$script:ArmEndpoint = [uri]$context.Environment.ResourceManagerUrl
$resourceGroup = $target.ResourceGroup
$script:ResourceGroup = [string]$resourceGroup.ResourceGroupName
$workspace = $target.Workspace
$script:Workspace = [string]$workspace.Name
$script:Region = Workspace-Region $workspace $script:SubscriptionId $script:ResourceGroup $script:Workspace
$script:WorkspaceId = "/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace"
$script:SentinelId = "$script:WorkspaceId/providers/Microsoft.SecurityInsights"
$selectedResourceId = [string](Safe-Prop $workspace 'ResourceId')
if ($selectedResourceId -and $selectedResourceId -ne $script:WorkspaceId) { throw 'Selected workspace object does not match the canonical subscription/resource-group/workspace target.' }
if ([string]$context.Subscription.Id -ne $script:SubscriptionId) { throw 'Selected subscription and active context disagree.' }
$script:ContentHubExpectedTarget = @{
    WorkspaceResourceId = $script:WorkspaceId; SubscriptionId = $script:SubscriptionId
    TenantId = $script:TenantId; CustomerId = [string](Safe-Prop $workspace 'CustomerId')
}
Write-Host "Selected tenant: $script:TenantId; subscription: $script:SubscriptionId" -ForegroundColor Cyan
Write-Host "Selected canonical workspace: $script:WorkspaceId" -ForegroundColor Green
Write-Host "Detected region: $script:Region" -ForegroundColor Green
$onboard = "$script:SentinelId/onboardingStates/default?api-version=$ApiVersion"
if ((Invoke-AzRestMethod -Method GET -Path $onboard).StatusCode -ne 200) { throw 'Microsoft Sentinel onboarding was not confirmed.' }

if ($SourceSubscriptionIds.Count -eq 0) { $SourceSubscriptionIds = @($script:SubscriptionId) }
$SourceSubscriptionIds = @($SourceSubscriptionIds | ForEach-Object { ([guid]::Parse($_)).ToString() } | Select-Object -Unique)
if ($ConfigureConnectorPolicies -and -not $PSBoundParameters.ContainsKey('ConnectorPolicyScopeIds')) {
    $ConnectorPolicyScopeIds = @("/subscriptions/$script:SubscriptionId")
    Write-Host "Connector policy scope defaults to Sentinel subscription: $($ConnectorPolicyScopeIds[0])" -ForegroundColor Cyan
}
if ($DeployPreviewDetections) { Initialize-PreviewDetectionSupport }
$runError = $null
$reportError = $null
$noAttemptReason = 'No configuration action recorded for this connector; this inventory observation is not a configuration success.'
try {
if ($ContentStatusOnly) {
    $noAttemptReason = 'Read-only package diagnostics requested. No package installation or connector configuration was attempted.'
    Step 'Read-only package artifact diagnostics (no installation or configuration)'
    $null = Confirmed-ContentHubPackageNames $RequestedSolutions -DiagnosticOnly
} elseif ($ConnectorStatusOnly) {
    $noAttemptReason = 'Read-only connector status requested. Content Hub deployment and connector configuration were not attempted.'
} elseif ($ConfigureConnectorsOnly) {
    Step 'Configure already-installed connectors without Content Hub or analytics-rule deployment'
    $connectorSnapshot = Get-ConnectorSnapshot
    Invoke-NewConnectorConfiguration $connectorSnapshot $connectorSnapshot
} else {
Step 'Snapshot existing Sentinel data connector artifacts'
$beforeConnectorSnapshot = Get-ConnectorSnapshot
Write-Host "Existing data connector templates: $($beforeConnectorSnapshot.TemplateNames.Count); definitions: $($beforeConnectorSnapshot.DefinitionNames.Count); runtime connectors: $($beforeConnectorSnapshot.RuntimeNames.Count)."

Step 'Prepare latest Sentinel-As-Code'
if (Test-Path (Join-Path $RepoPath '.git')) {
    git -C $RepoPath fetch origin main
    git -C $RepoPath checkout main
    git -C $RepoPath pull --ff-only origin main
} else {
    git clone --branch main --single-branch $RepoUrl $RepoPath
}
if ($LASTEXITCODE -ne 0) { throw 'Unable to clone/update Sentinel-As-Code.' }
$script:DeployScript = Join-Path $RepoPath 'Deploy/content/Deploy-SentinelContentHub.ps1'
if (-not (Test-Path $script:DeployScript)) { throw "Missing deployment script: $script:DeployScript" }

Step 'Resolve requested solutions against live catalog'
$lookup = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($item in (Available-Solutions)) {
    $name = Content-Name $item
    if ($name -and -not $lookup.ContainsKey($name)) { $lookup[$name] = $name }
}
$deployable = [Collections.Generic.List[string]]::new()
$skipped = [Collections.Generic.List[string]]::new()
foreach ($name in $RequestedSolutions) {
    if ($lookup.ContainsKey($name)) { $deployable.Add($lookup[$name]) }
    else {
        $skipped.Add($name)
        Write-Warning "Unavailable and intentionally skipped: $name"
    }
}
Write-Host "Requested: $($RequestedSolutions.Count); deployable: $($deployable.Count); unavailable: $($skipped.Count)."

Invoke-ContentHubDeploymentPhase @($deployable) 'Install all available requested solutions and packaged content'

Step 'Verify installed package versions and supported artifact checks; retry missing packages'
$installed = Confirmed-ContentHubPackageNames @($deployable)
$missing = [Collections.Generic.List[string]]::new()
foreach ($name in $deployable) {
    if ($installed.Contains($name)) { Write-Host "Verified installed package version: $name (artifact inspection/runtime outcomes reported separately)" -ForegroundColor Green }
    else {
        $missing.Add($name)
        Write-Warning "Not confirmed: $name"
    }
}
for ($round = 1; $round -le $MaxRetryAttempts -and $missing.Count -gt 0; $round++) {
    $retry = @($missing)
    $missing.Clear()
    Invoke-ContentHubDeploymentPhase $retry "Retry round $round of $MaxRetryAttempts"
    $installed = Confirmed-ContentHubPackageNames $retry
    foreach ($name in $retry) {
        if ($installed.Contains($name)) { Write-Host "Confirmed after retry: $name" -ForegroundColor Green }
        else { $missing.Add($name) }
    }
}

if ($missing.Count -eq 0) {
    $afterConnectorSnapshot = Get-ConnectorSnapshot
    Invoke-NewConnectorConfiguration $beforeConnectorSnapshot $afterConnectorSnapshot
} else {
    Write-Warning 'Connector configuration skipped because not all deployable Content Hub packages were confirmed installed.'
}

Step 'Final report'
Write-Host "Requested packages: $($RequestedSolutions.Count)"
Write-Host "Verified installed package versions: $($deployable.Count - $missing.Count)" -ForegroundColor Green
Write-Host "Intentionally skipped packages: $($skipped.Count)" -ForegroundColor Yellow
if ($skipped.Count -gt 0) { Write-Warning ($skipped -join ', ') }
Write-Host "Unconfirmed packages after retries: $($missing.Count)" -ForegroundColor $(if ($missing.Count -gt 0) { 'Red' } else { 'Green' })
if ($missing.Count -gt 0) {
    Write-Warning ($missing -join ', ')
    throw 'Some Content Hub packages remain unconfirmed. Connector configuration was not attempted.'
}
Write-Host 'Requested package versions were verified in this workspace. Detailed artifact checks, runtime rules/workbooks and connector/source ingestion have separate outcomes above.' -ForegroundColor Green
}
if ($DeployPreviewDetections) { Invoke-PreviewDetectionConfiguration $RequestedSolutions }
} catch {
    $runError = $_
    $noAttemptReason = 'No connector configuration action was recorded before the run stopped. Deployment/configuration encountered an error; this is not proof of connector failure.'
    if ($ContentStatusOnly) {
        $noAttemptReason = 'Read-only diagnostics encountered a read error. Connector setup was not requested; any partial package evidence is retained in Package rows.'
    } elseif (@($script:ContentHubPackageDiagnostics.Values | Where-Object { $_.State -in @('Missing', 'ReadFailed') -or @($_.Artifacts | Where-Object Outcome -eq 'ReadFailed').Count }).Count) {
        $noAttemptReason = 'Connector configuration was not attempted because package verification blocked this run. See the separate Package rows and exact artifact evidence; this is not a connector failure. Collect read-only evidence with -ContentStatusOnly.'
    }
    Write-Warning 'Deployment or setup stopped before completion. Connector status will still be shown below; this does not mean all connectors failed.'
    Write-Verbose "Run error: $($_.Exception.Message)"
} finally {
    $script:CurrentRecord = $null
    $script:Operation = @{}
    Add-ContentHubPackageDiagnosticRows
    foreach ($failure in @($script:ContentHubDeploymentFailures.Values)) {
        if ($script:ContentHubRuleFailures.ContainsKey($failure.ResourceId)) { continue }
        $http = if ($null -eq $failure.HttpStatus) { 'No HTTP response (local preflight/client failure)' } else { "HTTP $($failure.HttpStatus)" }
        Add-ConnectorResult "Content deployment / $($failure.ResourceId)" 'Failed' "$http; AzureCode=$($failure.AzureErrorCode); $($failure.Reason); requestId=$($failure.RequestId)" 'Resolve the recorded package/API failure and rerun. Connector configuration may not have been reached; see individual inventory/action rows.' @{
            Attempted = [bool](Get-ContentHubField $failure 'WriteAttempted'); Verified = $false; ConnectorStatus = 'Not applicable (content deployment)'
        }
        $row = $script:ConnectorReport[$script:ConnectorReport.Count - 1]
        $row.RowType = 'Content'
        $row | Add-Member -NotePropertyName ContentFailure -NotePropertyValue $failure
    }
    foreach ($failure in @($script:ContentHubRuleFailures.Values)) {
        $label = if ($failure.RuleName) { $failure.RuleName } else { $failure.ResourceId.Split('/')[-1] }
        Add-ConnectorResult "Analytics rule / $label" 'Failed' "HTTP $($failure.HttpStatus); AzureCode=$($failure.AzureErrorCode); $($failure.Reason); requestId=$($failure.RequestId); resource=$($failure.ResourceId)" 'Rule deployment did not succeed. Resolve validation/source prerequisites and rerun; connector actions are reported separately.' @{
            Attempted = $true; Verified = $false; ConnectorStatus = 'Not applicable (analytics rule)'
        }
        $row = $script:ConnectorReport[$script:ConnectorReport.Count - 1]
        $row.RowType = 'Content'
        $row | Add-Member -NotePropertyName ContentFailure -NotePropertyValue $failure
    }
    try {
        $finalSnapshot = Get-ConnectorSnapshot
        Add-AllConnectorStatus $finalSnapshot $noAttemptReason
    } catch {
        $script:CurrentRecord = $null
        Add-ConnectorResult 'Connector inventory' 'Failed' "Unable to complete connector status inventory: $($_.Exception.Message)" 'Existing action results are retained. Resolve inventory read permissions/authentication, then use -ConnectorStatusOnly.' @{ ConnectorStatus = 'Unknown (inventory unavailable)' }
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].RowType = 'Inventory'
        $script:ConnectorReport[$script:ConnectorReport.Count - 1].AppliedSuccessfully = $null
    }
    try { Write-ConnectorReport }
    catch {
        $reportError = $_
        Write-Warning "Connector report could not be fully displayed/saved: $($_.Exception.Message)"
    }
}
if ($runError) { throw $runError }
if ($reportError) { throw $reportError }
$failedConnectors = @($script:ConnectorReport | Where-Object { $_.Status -eq 'Failed' -and $_.RowType -notin @('Content', 'Package') })
if ($failedConnectors.Count -gt 0) {
    Write-Warning "$($failedConnectors.Count) connector configuration operation(s) failed. Review ErrorMessage, NextSteps and any JSON report."
    if ($FailOnConnectorError) {
        $failureDetails = @($failedConnectors | ForEach-Object { "Connector: $($_.Connector)`nError: $($_.ErrorMessage)`nNext steps: $($_.NextSteps)" }) -join "`n`n"
        throw "Connector configuration failed.`n`n$failureDetails"
    }
}
if ($script:ContentHubRuleFailures.Count -gt 0) {
    throw "$($script:ContentHubRuleFailures.Count) analytics rule(s) failed validation. Connector configuration was processed separately; review its Action outcomes and the Content rows in the saved report. The run is incomplete."
}
if ($DeployPreviewDetections -and $script:PreviewDetectionFailures -gt 0) {
    throw "$script:PreviewDetectionFailures preview detection operation(s) failed. Inspect Content rows and the preview ownership journal; no rules were automatically enabled."
}

Write-Warning 'Connector configuration status is ARM configuration/read-back only. Verify source permissions, licensing, consent, audit/export settings and data ingestion separately.'
    Write-Host "Run completed. Log file: $LogPath" -ForegroundColor Cyan
} catch {
    $transcriptRunError = $_
    if ($runTranscriptStarted) {
        # Rethrowing alone can display the exception only after the transcript has stopped.
        Write-Host "Run failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error ID: $($_.FullyQualifiedErrorId)"
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) { Write-Host "Error details: $($_.ErrorDetails.Message)" }
        if ($_.ScriptStackTrace) { Write-Host "Error stack: $($_.ScriptStackTrace)" }
        Write-Host "Failure details captured in: $LogPath" -ForegroundColor Cyan
    }
    throw
} finally {
    if ($DeployPreviewDetections -and (Get-Command Close-PreviewDetectionSupport -CommandType Function -ErrorAction SilentlyContinue)) {
        Close-PreviewDetectionSupport
    }
    if ($runTranscriptStarted) {
        try { $null = Stop-Transcript -WhatIf:$false -Confirm:$false -ErrorAction Stop }
        catch {
            if ($transcriptRunError) {
                Write-Warning "Could not finalize run log $LogPath; the original run error is preserved. $($_.Exception.Message)"
            } else { throw }
        }
    }
}
