Remove-Module CPSSiteDesign-Functions
Import-Module -Name ".\CPSSiteDesign-Functions" -Verbose

$ShowDebug = $false
$SiteDesign = $null
$SiteScripts = @{}
$ErrorCount = 0

$CSVFile = "C:\Users\Al\OneDrive - Eardley\Documents\GitHub\DeploySiteDesigns\CSV\PMO-ProjectSite.csv"
$JSONPath = "C:\Users\Al\OneDrive - Eardley\Documents\GitHub\DeploySiteDesigns\JSON\"

$ErrorCount = Check-CPSPreReqs `
    -TenantUrl $TenantUrl `
    -CSVFile $CSVFile `
    -ShowDebug $ShowDebug

If ($ErrorCount -gt 0) {
    Write-Error "Pre-Requisites need to be created before creating Site Scripts and Site Designs"
    Break
}

$SiteScripts = Process-CPSSiteScriptList `
    -CSVFile $CSVFile  `
    -JSONPath $JSONPath `
    -TenantUrl $TenantUrl `
    -ShowDebug $ShowDebug

$TidySiteScripts = {$SiteScripts}.Invoke()
$TidySiteScripts.Remove($true)
Write-CPSStatus -Message "TidySiteScripts: $TidySiteScripts" -Level 1 -Type Debug -ShowDebug $ShowDebug

$SiteDesign = Set-CPSSiteDesign `
    -Title "PMO - Project Site" `
    -Description "Creates an PMO Project site" `
    -SiteScripts $TidySiteScripts `
    -WebTemplate "64" `
    -ShowDebug $ShowDebug

Write-CPSStatus -Message "Site Design: $SiteDesign" -Level 0 -Type Success -ShowDebug $ShowDebug