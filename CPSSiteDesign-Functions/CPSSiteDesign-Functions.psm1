#region Write-CPSStatus
<#
    .Synopsis
    Writes a status message

    .Description
    Assess the type of message, the $ShowDebug and Level and writes an appropriate message

    .Parameter Message
    The message to be written

    .Parameter Level
    The level of indentation to be used

    .Parameter Type
    The type of message: Start, Progress, Debug or Success

    .Parameter ShowDebug
    Indicates whether or not to show debug messages

    .Example
    $Message = Write-CPSStatus `
        -Message "This is the message"  `
        -Level 1 `
        -Type "Progress" `
        -ShowDebug $false
#>

function Write-CPSStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Message,

        [Parameter(Mandatory=$true)]
        [int]$Level,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Start", "Debug", "Progress", "Success")]
        [String]$Type = "Debug",

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $StartColours = @{
        ForegroundColor = "Blue"
    }
    

    $DebugColours = @{
        ForegroundColor = "Cyan"
    }
    
    $SuccessColours = @{
        ForegroundColor = "Green"
    }
    
    $ProgressColours = @{
        ForegroundColor = "DarkMagenta"
    }

    switch ($Type) {
        "Debug" {
            $Level = ($Level+2)
            break
        }
        "Progress" {
            $Level = ($Level+1)
            break
        }
    }

    $Padding = 4*$Level + $Message.Length
    
    $MessageOutput = $Message.PadLeft($Padding," ")

    
    if ($Type -eq "Start") {
        Write-Host $MessageOutput @StartColours
    }
    
    if (($Type -eq "Debug") -and ($ShowDebug)) {
        Write-Host $MessageOutput @DebugColours
    }

    if ($Type -eq "Progress") {
        Write-Host $MessageOutput @ProgressColours
    }

    if ($Type -eq "Success") {
        Write-Host $MessageOutput @SuccessColours
    }
}
Export-ModuleMember -Function "Write-CPSStatus"
#endregion Write-CPSStatus

#region Check-CPSTermSet
<#
    .Synopsis
    Confirms that a Termset exists based on the paramters provided.

    .Description
    Checks if the Term Group exists.
        Success > Check if the Term Set exists.
            Success > Return success
            Failure > Return error message
        Failure > Return error message

    .Parameter TermGroupName
    The name of the Term Group that contains the Term Set

    .Parameter TermSetName
    The name of the Term Set

    .Parameter ShowDebug
    Shows Function debug output

    .Example
    $Message = Check-CPSTermSet `
        -TermGroupName "PMO"  `
        -TermSetName "Project" `
        -ShowDebug $false
#>

function Check-CPSTermSet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$TermGroupName,

        [Parameter(Mandatory=$true)]
        [String]$TermSetName,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $TermGroup = $null
    $TermSet = $null
    $StatusLevel = 2
    
    Write-CPSStatus -Message "Starting Term Set Check" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "TermGroupName: $TermGroupName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "TermSetName: $TermSetName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "Check for Term Group" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

    $TermGroup = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction SilentlyContinue
    
    if ($TermGroup) {
        Write-CPSStatus -Message "Check for Term Set" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

        $TermSet = Get-PnPTermSet -Identity $TermSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue

        if ($TermSet) {
            Write-CPSStatus -Message "Term Set $TermGroupName exists in Term Group $TermGroupName" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            Write-CPSStatus -Message "Completed Term Set Check" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug
            return 0
        } else {
            Write-Warning "Term Set $TermSetName does not exist"
        }
    } else {
        Write-Warning "Term Group $TermGroupName does not exist"
    }
}
Export-ModuleMember -Function "Check-CPSTermSet"
#endregion Check-CPSTermSet

#region Check-CPSHubSite
<#
    .Synopsis
    Confirms that a Hub site exists based on the paramters provided.

    .Description
    Checks if the Hub site exists.
        Success > Return success
        Failure > Return error message

    .Parameter HubSiteURL
    The URL of the Hub Site

    .Parameter ShowDebug
    Shows Function debug output

    .Example
    $Message = Check-CPSHubSite `
        -HubSiteURL "https://test.sharepoint.com/sites/Hub"  `
        -ShowDebug $false
#>

function Check-CPSHubSite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$HubSiteURL,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $HubSite = $null
    $StatusLevel = 2

    Write-CPSStatus -Message "Starting Hub Site Check" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "HubSiteURL: $HubSiteUrl" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "Check for Hub Site" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $HubSite = Get-PnPHubSite -Identity $HubSiteUrl -ErrorAction SilentlyContinue
    
    if ($HubSite) {
        Write-CPSStatus -Message "Hub Site Found: $HubSiteUrl" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        Write-CPSStatus -Message "Completed Hub Site Check" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug
        return 0
    } else {
        Write-Warning "Hub Site $HubSiteUrl does not exist"
        Return 1
    }
}
Export-ModuleMember -Function "Check-CPSHubSite"
#endregion Check-CPSHubSite

#region Set-CPSSiteScript
<#
 .Synopsis
  Creates or updates a Site Script that does not include reference to a Hub Site.

 .Description
  Checks if a Site Script with the same Title exists.
  If it does, the JSON content is updated.
  If it does not, a new Site Script is created.
  The GUID of the Site Script is added to the SiteScripts parameter and returned from the function.

 .Parameter Title
  The title of the Site Script - used to check for existence.

 .Parameter Description
  A description of the functionality of the Site Script.

 .Parameter JSON
  The JSON content that will be used to create or update the Site Script

 .Parameter SiteScripts
  An array of strings identifying SiteScripts that can be used to create a Site Design
  The create/updated Site Script will be added to the array and returned

 .Parameter ShowDebug
  Shows Function debug output

 .Example
   # Show a default display of this month.
    $SiteScripts = Set-CPSSiteScriptWithHubJoin `
        -Title "Set Region"  `
        -Description "Sets region to UK" `
        -JSON $JSON `
        -SiteScripts "Remove 1111-1111-1111-1111" `
        -ShowDebug $false
#>

function Set-CPSSiteScript {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Title,

        [Parameter(Mandatory=$true)]
        [String]$Description,

        [Parameter(Mandatory=$true)]
        [String]$JSON,

        [Parameter(Mandatory=$true)]
        [String[]]$SiteScripts,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $SiteScript = $null
    $StatusLevel = 1

    Write-CPSStatus -Message "Setting Site Script" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "Title: $Title" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "Description: $Description" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "SiteScripts: $SiteScripts" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "Get existing Site Script" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $SiteScript = Get-SPOSiteScript | Where-Object {$_.Title -eq $Title}

    if ($SiteScript) {
        Write-CPSStatus -Message "Updating Site Script - $Title" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

        $SiteScript = Set-SPOSiteScript `
            -Id $SiteScript.Id `
            -Title $SiteScript.Title `
            -Content $JSON
    } else {
        Write-CPSStatus -Message "Adding Site Script - $Title" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        
        $SiteScript = Add-SPOSiteScript `
            -Title $Title `
            -Content $JSON `
            -Description $Description
    }

    $SiteScripts = $SiteScripts + $SiteScript.Id

    Write-CPSStatus -Message "Completed setting Site Script" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $SiteScripts
}
Export-ModuleMember -Function "Set-CPSSiteScript"
#endregion Set-CPSSiteScript

#region Check-CPSPreReqs
<#
    .Synopsis
    Checks that all of the pre-requisite artefacts exist in the tenant.

    .Description
    Pre-processes the CSV to check for the following.
        Term Store
        Term Set
        Hub Site

    .Parameter CSVFile
    The path to a CSV file

    .Parameter TenantUrl
    The URL of the tenant

    .Parameter ShowDebug
    Shows Function debug output

    .Example
    $Message = Check-CPSPreReqs `
        -TermGroupName "PMO"  `
        -TermSetName "Project" `
        -ShowDebug $false
#>

function Check-CPSPreReqs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$CSVFile,

        [Parameter(Mandatory=$true)]
        [String]$TenantUrl,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $TotalErrorCount = 0
    $StatusLevel = 1

    Write-CPSStatus -Message "Starting Pre-Req Check" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "CSVFile: $CSVFile" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "TenantUrl: $TenantUrl" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "Get CSV contents" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $CSV = Import-Csv -Path $CSVFile

    foreach ($Row in $CSV) {
        $IncludeHubJoin = $Row.IncludeHubJoin
        $HubSitePath = $Row.HubSitePath
        $IncludeTermSet = $Row.IncludeTermSet
        $TermGroupName = $Row.TermGroupName
        $TermSetName = $Row.TermSetName
        $IncludeFlow = $Row.IncludeFlow
        $FlowName = $Row.FlowName

        Write-CPSStatus -Message "Starting Row Process" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

        Write-CPSStatus -Message "IncludeHubJoin: $IncludeHubJoin" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "HubSitePath: $HubSitePath" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "IncludeTermSet: $IncludeTermSet" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "TermGroupName: $TermGroupName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "TermSetName: $TermSetName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "IncludeFlow: $IncludeFlow" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "FlowName: $FlowName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug

        if ($IncludeHubJoin -eq "Yes") {
            Write-CPSStatus -Message "Checking for Hub Site" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            $HubSiteUrl = $TenantUrl + $HubSitePath
            $ErrorCount = Check-CPSHubSite -HubSiteURL $HubSiteUrl -ErrorAction Continue
            $TotalErrorCount = $TotalErrorCount + $ErrorCount
        }

        if ($IncludeTermSet -eq "Yes") {
            Write-CPSStatus -Message "Checking for Term Set" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            $ErrorCount = Check-CPSTermSet -TermGroupName $TermGroupName -TermSetName $TermSetName -ErrorAction Continue
            $TotalErrorCount = $TotalErrorCount + $ErrorCount
        }
        
        Write-CPSStatus -Message "Row Checks Complete" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    }
    Write-CPSStatus -Message "All Checks Complete" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $TotalErrorCount
}
Export-ModuleMember -Function "Check-CPSPreReqs"
#endregion Check-CPSPreReqs

#region Update-CPSSiteScriptJSONHubSiteId
<#
 .Synopsis
  Updates the JSON script that will be used to create a Site Script

 .Description
  Updates the tokens for the Hub Site
  Returns the JSON from the function

 .Parameter JSON
  The JSON that will be used to create the Site Script

  .Parameter TenantUrl
  The path of the Hub Site that will be used in the Site Script

  .Parameter HubSitePath
  The path of the Hub Site that will be used in the Site Script
  
 .Parameter ShowDebug
  Shows Function debug output

 .Example
   # Executing without a Hub Join, Termset of Flow
    $UpdatedJSON = Update-CPSSiteScriptJSONHubSiteId `
        -JSON $RawJSON  `
        -TenantUrl "https://contoso.sharepoint.com" `
        -HubSitePath "/sites/HubSite" `
        -ShowDebug
#>
function Update-CPSSiteScriptJSONHubSiteId {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$JSON,

        [Parameter(Mandatory=$true)]
        [String]$TenantUrl,
        
        [Parameter(Mandatory=$true)]
        [String]$HubSitePath,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $HubSite = $null
    $HubSiteUrl = "$TenantUrl$HubSitePath"
    $UpdatedJSON = $JSON    
    $StatusLevel = 2

    Write-CPSStatus -Message "Starting JSON Update - Hub Site" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "TenantUrl: $TenantUrl" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "HubSitePath: $HubSitePath" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "HubSiteUrl: $HubSiteUrl" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug

    Write-CPSStatus -Message "Get Hub Site" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $HubSite = Get-SPOHubSite | Where-Object {$_.SiteUrl -eq $HubSiteUrl}
    if ($HubSite) {
        Write-CPSStatus -Message "Hub Site Found" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    } else {
        Write-Error "Hub Site Not Found - Ensure the HubSiteUrl parameter points at a hub site" -Category ObjectNotFound
        Exit
    }
    
    Write-CPSStatus -Message "Update JSON" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $UpdatedJSON = $JSON.Replace("##hubSiteId##", $HubSite.Id)
    
    Write-CPSStatus -Message "Completed JSON Update - Hub Site" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $UpdatedJSON
}
Export-ModuleMember -Function "Update-CPSSiteScriptJSONHubSiteId"
#endregion Update-CPSSiteScriptJSONHubSiteId

#region Update-CPSSiteScriptJSONTermSet
<#
 .Synopsis
  Updates the JSON script that will be used to create a Site Script

 .Description
  Updates the tokens for the Term Store, Term Group and Term Set
  Returns the JSON from the function

 .Parameter JSON
  The JSON that will be used to create the Site Script

  .Parameter TermGroupName
  The name of the Term Group containing the Term Set

  .Parameter TermSetName
  The name of the Term Set
  
 .Parameter ShowDebug
  Shows Function debug output

 .Example
   # Executing without a Hub Join, Termset of Flow
    $UpdatedJSON = Update-CPSSiteScriptJSONTermSet `
        -JSON $RawJSON  `
        -TermGroupName "PMO" `
        -TermSetName "Project" `
        -ShowDebug
#>
function Update-CPSSiteScriptJSONTermSet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$JSON,

        [Parameter(Mandatory=$true)]
        [String]$TermGroupName,
        
        [Parameter(Mandatory=$true)]
        [String]$TermSetName,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $TermStore = $null
    $TermGroup = $null
    $TermSet = $null
    $UpdatedJSON = $JSON   
    $StatusLevel = 2

    Write-CPSStatus -Message "Starting JSON Update - Term Set" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "TermGroupName: $TermGroupName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "TermSetName: $TermSetName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug

    Write-CPSStatus -Message "Get Term Group" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $TermGroup = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction SilentlyContinue
    
    if ($TermGroup) {
        Write-CPSStatus -Message "Get Term Set" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        $TermSet = Get-PnPTermSet -Identity $TermSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue

        if ($TermSet) {
            Write-CPSStatus -Message "Get Term Store" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            $TermStores = Get-PnPTaxonomySession
            $TermStore = $TermStores.TermStores.Item(0)
        } else {
            Write-Error "Term Set $TermSetName does not exist" -Category ObjectNotFound
        }
    } else {
        Write-Error "Term Group $TermGroupName does not exist" -Category ObjectNotFound
    }

    Write-CPSStatus -Message "Update JSON" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $JSON = $JSON.Replace("##TermStoreId##", $TermStore.Id)
    $JSON = $JSON.Replace("##TermSetId##", $TermSet.Id)
    
    Write-CPSStatus -Message "Completed JSON Update - Term Set" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $JSON
}
Export-ModuleMember -Function "Update-CPSSiteScriptJSONTermSet"
#endregion Update-CPSSiteScriptJSONTermSet

#region Set-CPSSiteDesign
<#
 .Synopsis
  Creates or updates a Site Design.

 .Description
  Checks if a Site Design with the same Title exists.
  If it does, the associated Site Scripts are updated.
  If it does not, a new Site Design is created.
  The GUID of the Site Design is returned from the function.

 .Parameter Title
  The title of the Site Design - used to check for existence.

 .Parameter Description
  A description of the functionality of the Site Design.
  
 .Parameter SiteScripts
  An array of strings identifying Site Scripts that used in the Site Design
  
 .Parameter WebTemplate
  Identifies the type of site that the Site Design will be applied to
    64 - Team Site
    68 - Communication Site

 .Parameter ShowDebug
  Shows Function debug output

 .Example
   # Show a default display of this month.
    $SiteScripts = Set-CPSSiteDesign `
        -Title "Intranet Department"  `
        -Description "Creates a Department site joind to Intranet Hub" `
        -SiteScripts "1111-1111-1111-1111" `
        -WebTemplate 68 `
        -ShowDebug
#>
function Set-CPSSiteDesign {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]
        $Title,

        [Parameter(Mandatory=$true)]
        [String]
        $Description,

        [Parameter(Mandatory=$true)]
        [String[]]
        $SiteScripts,

        [Parameter(Mandatory=$true)]
        [ValidateSet("64","68")]
        [String]$WebTemplate,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $SiteDesign = $null   
    $StatusLevel = 1

    Write-CPSStatus -Message "Starting Set Site Design" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "Title: $Title" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "Description: $Description" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "SiteScripts: $SiteScripts" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "WebTemplate: $WebTemplate" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "Get existing Site Design" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $SiteDesign = Get-SPOSiteDesign | Where-Object {$_.Title -eq $Title}

    if ($SiteDesign) {
        Write-CPSStatus -Message "Updating Site Design - $Title" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        $siteDesign = Set-SPOSiteDesign -Identity $SiteDesign.Id -SiteScripts $SiteScripts
    } else {
        Write-CPSStatus -Message "Adding Site Design - $Title" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

        $siteDesign = Add-SPOSiteDesign `
            -Title $Title `
            -WebTemplate $WebTemplate `
            -SiteScripts $SiteScripts `
            -Description $Description
    }

    Write-CPSStatus -Message "Completed Set Site Design" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $siteDesign.Id
}
Export-ModuleMember -Function "Set-CPSSiteDesign"
#endregion Set-CPSSiteDesign

#region Process-CPSSiteScriptList
<#
    .Synopsis
    Processes a CSV list and creates or updates the site scripts.

    .Description
    Processes the CSV to do the following.
        Retrieve the JSON
        If necessasry, update tokens for Term Set
        If necessasry, update tokens for Hub Site
        Create or update the Site Script
        Return an array of Site Script IDs

    .Parameter CSVFile
    The path to a CSV file

    .Parameter JSONPath
    The path where the JSON files are located

    .Parameter TenantUrl
    The URL of the tenant

    .Parameter ShowDebug
    Shows Function debug output

    .Example
    $SiteScripts = Process-CPSSiteScriptList `
        -CSVFile "c:\files\SiteScripts.csv"  `
        -JSONPath "c:\files\JSON\"
        -TenantUrl "https://contoso.sharepoint.com" `
        -ShowDebug $false
#>

function Process-CPSSiteScriptList {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$CSVFile,

        [Parameter(Mandatory=$true)]
        [String]$JSONPath,

        [Parameter(Mandatory=$true)]
        [String]$TenantUrl,

        [Parameter(Mandatory=$false)]
        [Bool]$ShowDebug = $false
    )

    $SiteScripts = @("Remove")
    $StatusLevel = 1

    Write-CPSStatus -Message "Starting Site Design Processing" -Level $StatusLevel -Type Start -ShowDebug $ShowDebug

    Write-CPSStatus -Message "CSVFile: $CSVFile" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "JSONPath: $JSONPath" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    Write-CPSStatus -Message "TenantUrl: $TenantUrl" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "Get CSV contents" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    $CSV = Import-Csv -Path $CSVFile

    foreach ($Row in $CSV) {
        $SiteScriptTitle = $Row.Title
        $SiteScriptDescription = $Row.Description
        $SiteScriptFile = $Row.File
        $IncludeHubJoin = $Row.IncludeHubJoin
        $HubSitePath = $Row.HubSitePath
        $IncludeTermSet = $Row.IncludeTermSet
        $TermGroupName = $Row.TermGroupName
        $TermSetName = $Row.TermSetName
        $IncludeFlow = $Row.IncludeFlow
        $FlowName = $Row.FlowName

        Write-CPSStatus -Message "Starting Row Process" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug

        Write-CPSStatus -Message "SiteScriptTitle: $SiteScriptTitle" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "SiteScriptDescription: $SiteScriptDescription" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "SiteScriptFile: $SiteScriptFile" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "IncludeHubJoin: $IncludeHubJoin" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "HubSitePath: $HubSitePath" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "IncludeTermSet: $IncludeTermSet" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "TermGroupName: $TermGroupName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "TermSetName: $TermSetName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "IncludeFlow: $IncludeFlow" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        Write-CPSStatus -Message "FlowName: $FlowName" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug


        Write-CPSStatus -Message "Getting JSON" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        $JSONFile = $JSONPath + $SiteScriptFile
        Write-CPSStatus -Message "JSONFile: $JSONFile" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
        $JSON = Get-Content -Path $JSONFile -Raw

        if ($IncludeHubJoin -eq "Yes") {
            Write-CPSStatus -Message "Calling Update-CPSSiteScriptJSONHubSiteId" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            $JSON = Update-CPSSiteScriptJSONHubSiteId `
                -JSON $JSON  `
                -TenantUrl $TenantUrl `
                -HubSitePath $HubSitePath `
                -ShowDebug $ShowDebug

                Write-CPSStatus -Message "JSON: $JSON" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
            }

        if ($IncludeTermSet -eq "Yes") {
            Write-CPSStatus -Message "Calling Update-CPSSiteScriptJSONTermSet" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
            $JSON = Update-CPSSiteScriptJSONTermSet `
                -JSON $JSON  `
                -TermGroupName $TermGroupName `
                -TermSetName $TermSetName `
                -ShowDebug $ShowDebug
            
            Write-CPSStatus -Message "JSON: $JSON" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
            }

        Write-CPSStatus -Message "Setting Site Script" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
        $SiteScripts = Set-CPSSiteScript `
            -Title $SiteScriptTitle `
            -Description $SiteScriptDescription `
            -JSON $JSON `
            -SiteScripts $SiteScripts `
            -ShowDebug $ShowDebug
        
        Write-CPSStatus -Message "Site Script Processed" -Level $StatusLevel -Type Progress -ShowDebug $ShowDebug
    }

    Write-CPSStatus -Message "Remove the initial entry in the Site Scripts array" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    $TidySiteScripts = {$SiteScripts}.Invoke()
    $TidySiteScripts.Remove("Remove")

    Write-CPSStatus -Message "Site Scripts: $TidySiteScripts" -Level $StatusLevel -Type Debug -ShowDebug $ShowDebug
    
    Write-CPSStatus -Message "All Site Scripts Processed" -Level $StatusLevel -Type Success -ShowDebug $ShowDebug

    return $TidySiteScripts
}
Export-ModuleMember -Function "Process-CPSSiteScriptList"
#endregion Process-CPSSiteScriptList