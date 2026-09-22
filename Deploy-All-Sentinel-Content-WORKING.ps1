#Requires -Version 7.2
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$RepoPath=Join-Path $HOME 'Sentinel-As-Code'
$RepoUrl='https://github.com/noodlemctwoodle/Sentinel-As-Code.git'
$ApiVersion='2025-09-01'
$MaxRetryAttempts=2

$RequestedSolutions=@(
'Azure Activity'
'Microsoft 365'
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
)
$Severities=@('High','Medium','Low','Informational')

function Step([string]$Text){Write-Host "`n=== $Text ===" -ForegroundColor Cyan}
function Ensure-Module([string]$Name){
 $m=Get-Module -ListAvailable -Name $Name|Sort-Object Version -Descending|Select-Object -First 1
 if (-not $m){Install-Module -Name $Name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber}
 Import-Module $Name -Force -ErrorAction Stop
}
function Ensure-AzureLogin{
 try{if(Get-AzContext -ErrorAction SilentlyContinue){Get-AzSubscription -ErrorAction Stop|Out-Null;return}}catch{}
 Write-Warning 'Azure authentication is required. Starting device authentication.'
 Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop|Out-Null
}
function Select-ItemNumber([array]$Items,[scriptblock]$Display,[string]$Prompt){
 if($Items.Count-eq0){throw "No options found for $Prompt"}
 for ($i = 0; $i -lt $Items.Count; $i++){Write-Host ("  [{0}] {1}"-f($i+1),(& $Display $Items[$i]))}
 do{$raw=(Read-Host $Prompt).Trim();$n=0;$ok = [int]::TryParse($raw, [ref]$n) -and $n -ge 1 -and $n -le $Items.Count;if (-not $ok){Write-Warning "Enter 1-$($Items.Count)."}}until($ok)
 $Items[$n-1]
}
function Safe-Prop([object]$Object,[string]$Name){if ($null -eq $Object){return $null};$p=$Object.PSObject.Properties[$Name];if($p){$p.Value}}
function Content-Name([object]$Item) {
    $props = Safe-Prop $Item 'properties'
    foreach ($propertyName in @('displayName','title','contentProductId','packageName','name')) {
        $value = Safe-Prop $props $propertyName
        if ($value) { return [string]$value }
    }
    $topName = Safe-Prop $Item 'name'
    if ($topName) { return [string]$topName }
    return ''
}
function Workspace-Region($WS,[string]$Sub,[string]$RG,[string]$Name){
 foreach($p in @('Location','ResourceLocation')){$v=Safe-Prop $WS $p;if($v){return([string]$v).ToLowerInvariant().Replace(' ','')}}
 $id="/subscriptions/$Sub/resourceGroups/$RG/providers/Microsoft.OperationalInsights/workspaces/$Name"
 $r=Get-AzResource -ResourceId $id -ErrorAction Stop
 ([string]$r.Location).ToLowerInvariant().Replace(' ','')
}
function Arm-Get([string]$Path){$r=Invoke-AzRestMethod -Method GET -Path $Path -ErrorAction Stop;if($r.StatusCode-ne200){throw "GET failed: HTTP $($r.StatusCode)"};$r.Content|ConvertFrom-Json}
function Available-Solutions{
 $p="/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace/providers/Microsoft.SecurityInsights/contentProductPackages?api-version=$ApiVersion"
 @((Arm-Get $p).value)
}
function Installed-Names{
 $p="/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace/providers/Microsoft.SecurityInsights/contentPackages?api-version=$ApiVersion"
 $set=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($x in @((Arm-Get $p).value)){$n=Content-Name $x;if($n){[void]$set.Add($n)}}
 $set
}
function Deploy-Solutions([string[]]$Solutions,[string]$Label){
 if($Solutions.Count-eq0){return}
 Step $Label
 & $script:DeployScript -SubscriptionId $script:SubscriptionId -ResourceGroup $script:ResourceGroup -Workspace $script:Workspace -Region $script:Region -Solutions $Solutions -SeveritiesToInclude $Severities -ForceSolutionUpdate -ForceContentDeployment
 if (-not $?){Write-Warning 'Deployment invocation reported errors. Post-deployment verification will identify missing packages.'}
}

Step 'Prerequisites'
if($PSVersionTable.PSVersion-lt[version]'7.2'){throw 'PowerShell 7.2+ is required.'}
'Az.Accounts','Az.Resources','Az.OperationalInsights'|ForEach-Object{Ensure-Module $_}
if(-not(Get-Command git -ErrorAction SilentlyContinue)){throw 'git is unavailable.'}
Ensure-AzureLogin

Step 'Select target environment'
$subs=@(Get-AzSubscription|Where-Object State -eq 'Enabled'|Sort-Object Name)
Write-Host 'Available subscriptions:' -ForegroundColor Cyan
$sub=Select-ItemNumber $subs {param($x)"$($x.Name) [$($x.Id)]"} 'Select subscription number'
$script:SubscriptionId=[string]$sub.Id;Set-AzContext -SubscriptionId $script:SubscriptionId|Out-Null
$rgs=@(Get-AzResourceGroup|Sort-Object ResourceGroupName)
Write-Host "`nAvailable resource groups:" -ForegroundColor Cyan
$rg=Select-ItemNumber $rgs {param($x)"$($x.ResourceGroupName) [$($x.Location)]"} 'Select resource group number'
$script:ResourceGroup=[string]$rg.ResourceGroupName
$wss=@(Get-AzOperationalInsightsWorkspace -ResourceGroupName $script:ResourceGroup|Sort-Object Name)
Write-Host "`nAvailable Log Analytics workspaces:" -ForegroundColor Cyan
$ws=Select-ItemNumber $wss {param($x)$l=Safe-Prop $x 'Location';if (-not $l){$l=Safe-Prop $x 'ResourceLocation'};if (-not $l){$l='region resolved after selection'};"$($x.Name) [$l]"} 'Select Sentinel workspace number'
$script:Workspace=[string]$ws.Name;$script:Region=Workspace-Region $ws $script:SubscriptionId $script:ResourceGroup $script:Workspace
Write-Host "Selected workspace: $script:Workspace" -ForegroundColor Green;Write-Host "Detected region: $script:Region" -ForegroundColor Green
$onboard="/subscriptions/$script:SubscriptionId/resourceGroups/$script:ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$script:Workspace/providers/Microsoft.SecurityInsights/onboardingStates/default?api-version=$ApiVersion"
if((Invoke-AzRestMethod -Method GET -Path $onboard).StatusCode-ne200){throw 'Microsoft Sentinel onboarding was not confirmed.'}

Step 'Prepare latest Sentinel-As-Code'
if(Test-Path(Join-Path $RepoPath '.git')){git -C $RepoPath fetch origin main;git -C $RepoPath checkout main;git -C $RepoPath pull --ff-only origin main}else{git clone --branch main --single-branch $RepoUrl $RepoPath}
if ($LASTEXITCODE -ne 0){throw 'Unable to clone/update Sentinel-As-Code.'}
$script:DeployScript=Join-Path $RepoPath 'Deploy/content/Deploy-SentinelContentHub.ps1'
if (-not (Test-Path $script:DeployScript)){throw "Missing deployment script: $script:DeployScript"}

Step 'Resolve requested solutions against live catalog'
$lookup=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($x in(Available-Solutions)){$n=Content-Name $x;if ($n -and -not $lookup.ContainsKey($n)){$lookup[$n]=$n}}
$deployable=[Collections.Generic.List[string]]::new();$skipped=[Collections.Generic.List[string]]::new()
foreach($n in $RequestedSolutions){if($lookup.ContainsKey($n)){$deployable.Add($lookup[$n])}else{$skipped.Add($n);Write-Warning "Unavailable and intentionally skipped: $n"}}
Write-Host "Requested: $($RequestedSolutions.Count); deployable: $($deployable.Count); unavailable: $($skipped.Count)."

# One complete upstream invocation, matching the successful Microsoft Entra ID test.
Deploy-Solutions @($deployable) 'Install all available requested solutions and packaged content'

Step 'Verify installed packages and retry missing packages'
$installed=Installed-Names;$missing=[Collections.Generic.List[string]]::new()
foreach($n in $deployable){if($installed.Contains($n)){Write-Host "Confirmed installed: $n" -ForegroundColor Green}else{$missing.Add($n);Write-Warning "Not confirmed: $n"}}
for ($round = 1; $round -le $MaxRetryAttempts -and $missing.Count -gt 0; $round++){
 $retry=@($missing);$missing.Clear();Deploy-Solutions $retry "Retry round $round of $MaxRetryAttempts";$installed=Installed-Names
 foreach($n in $retry){if($installed.Contains($n)){Write-Host "Confirmed after retry: $n" -ForegroundColor Green}else{$missing.Add($n)}}
}

Step 'Final report'
Write-Host "Requested: $($RequestedSolutions.Count)"
Write-Host "Confirmed installed: $($deployable.Count-$missing.Count)" -ForegroundColor Green
Write-Host "Intentionally skipped: $($skipped.Count)" -ForegroundColor Yellow
if ($skipped.Count -gt 0){Write-Warning($skipped-join', ')}
Write-Host "Unconfirmed after retries: $($missing.Count)" -ForegroundColor $(if ($missing.Count -gt 0){'Red'}else{'Green'})
if ($missing.Count -gt 0){Write-Warning($missing-join', ');exit 2}
Write-Host 'All available requested solutions were confirmed installed.' -ForegroundColor Green
Write-Warning 'Connector definitions may still require source-specific authentication, permissions, diagnostic settings, or other configuration before they become connected and ingest data.'
