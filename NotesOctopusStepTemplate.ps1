#=================================
#
# == TELERIK PLATFORM DEPLOY ==
#
#=================================
# List of varibles
#$TelerikUserName
#$TelerikPassword
#$AndriodCertID
#$iOSCertID
#$iOSProvitionID
#$GroupAccessList 
#$DisableSendPush

#$currentstepname        
#$OctopusProjectName     
#$parentLocation         
#$OctopusEnvironmentName 
#=================================

$currentstepname        = $OctopusParameters["Octopus.Step[0].Package.NuGetPackageId"]
$OctopusProjectName     = $OctopusParameters["Octopus.Project.Name"]
$parentLocation         = $OctopusParameters["Octopus.Action[$currentstepname].Output.Package.InstallationDirectoryPath"]
$OctopusEnvironmentName = $OctopusParameters["Octopus.Environment.Name"]

# Setup Group Command
$GroupCmd =" --group " + $GroupAccessList.Replace(","," --group ");
$GroupCmd=$GroupCmd.Replace("  "," ").Replace("  "," ")

# Setup Push message command
$SendPushCmd=" --send-push"
if($DisableSendPush="True")
{
$SendPushCmd=""
}

#Check Varibles
Write-host "currentstepname `t= $currentstepname"
Write-host "OctopusProjectName `t= $OctopusProjectName"
Write-host "parentLocation `t`t= $parentLocation"
Write-host "OctopusEnvironmentName `t= $OctopusEnvironmentName"

CD $parentLocation; get-location

$Path = Get-Location; Write-Host "Run Script from   $Path"
$AppData = $env:APPDATA 

# Grab JSON form the project file
$JSON = (Get-Content "$parentLocation\.abproject" -Raw) | ConvertFrom-Json; 

#Write out Old values
Write-Host "`n---------------------------`nShow Old value in JSON file`n---------------------------"
$JSON_ProjectName   = $JSON.ProjectName;   Write-host "ProjectName `t= $JSON_ProjectName"
$JSON_AppIdentifier = $JSON.AppIdentifier; Write-host "AppIdentifier `t= $JSON_AppIdentifier"
$JSON_DisplayName   = $JSON.DisplayName;   Write-host "DisplayName `t= $JSON_DisplayName"
$JSON_BundleVersion = $JSON.BundleVersion; Write-host "BundleVersion `t= $JSON_BundleVersion"

#Write out values that will be used in file
Write-Host "`n---------------------------`nShow value it will Replacement to JSON file`n---------------------------"
Write-host "ProjectName `t= $ProjectName `t<from Octopus Variable>"
Write-host "AppIdentifier `t= $AppIdentifier `t<from Octopus Variable>"
Write-host "DisplayName `t= $DisplayName `t<from Octopus Variable>"
Write-host "BundleVersion `t= $OctopusReleaseNumber `t<from Octopus Release Number>"

# Set values in object
$JSON.ProjectName   = $ProjectName;  
$JSON.AppIdentifier = $AppIdentifier; 
$JSON.DisplayName   = $DisplayName;
$JSON.BundleVersion = $OctopusReleaseNumber; 

#Write back to file
get-location
Write-Host "'$JSON' | ConvertTo-Json | Set-Content "$parentLocation\.abproject""
$JSON | ConvertTo-Json | Set-Content "$parentLocation\.abproject"

#Run update on appBuilder, if its not he altest version it will fail     
Write-Host "`n-----------------------------------------------------------`nupdate to the latest version of the Telerik AppBuilder CLI`n-----------------------------------------------------------"
CMD /C C:\"Program Files (x86)"\nodejs\npm update -g appbuilder; $LASTEXITCODE

# Login to teleirk platform
Write-Host "`n---------------------`nConnecting to telerik`n---------------------"
CMD /C $APPDATA\npm\appbuilder dev-telerik-login $TelerikUserName $TelerikPassword       IF ($LASTEXITCODE -ne 0) { Write-Error "Error"}
Write-Host "`n---------------------`nConnected to telerik`n---------------------"
CMD /C $APPDATA\npm\appbuilder user

# Write out all available groups
Write-Host "`n-----------------`nAppmanager Groups`n-----------------"
$groups = CMD /C $APPDATA\npm\appbuilder appmanager groups;
$groupsCutLine = $groups[3..($groups.count - 2)]
$groupsCutLine | Foreach-object {$_ -replace "â`”‚", "" }

#Write out all available Certs
Write-Host "`n------------------------------------------------------------------------------------------------------`nLists all configured certificates for code signing iOS and Android applications with index and name.`n------------------------------------------------------------------------------------------------------"
$certificate = CMD /C $APPDATA\npm\appbuilder certificate; $certificate

#Write out all avialable provisioning profiles
Write-Host "`n------------------------------------------------------------------------------------------------------`nLists all configured provisioning profiles for code signing iOS applications with index and name.`n------------------------------------------------------------------------------------------------------"
$provision   = CMD /C $APPDATA\npm\appbuilder provision;   $provision

# Run Android Upload
Write-Host "`n--------------------------------------------------`nappbuilder appmanager upload android to Developers`n--------------------------------------------------"
CMD /C $APPDATA\npm\appbuilder appmanager upload android --certificate $AndriodCertID --publish --send-push $GroupCmd;$LASTEXITCODE;IF ($LASTEXITCODE -ne 0) { Write-Error "error"}
# Run iOS Deploy
Write-Host "`n----------------------------------------------`nappbuilder appmanager upload iOS to Developers`n----------------------------------------------"
CMD /C $APPDATA\npm\appbuilder appmanager upload ios     --certificate $iOSCertID --provision $iOSProvitionID --publish $SendPushCmd $GroupCmd;$LASTEXITCODE;IF ($LASTEXITCODE -ne 0) { Write-Error "error"}

#Run Logout
CMD /C $APPDATA\npm\appbuilder logout; $LASTEXITCODE
        
#Write-Host "`n-----------------------------------------------`nShow IE Open`n----------------------------------------------"
#Get-Process iexplore -ErrorAction SilentlyContinue | format-table -auto
#Write-Host "`n-----------------------------------------------`nClose IE `n----------------------------------------------"
#Get-Process iexplore -ErrorAction SilentlyContinue | stop-process
#Write-Host "`n-----------------------------------------------`nShow IE Open`n----------------------------------------------"
#Get-Process iexplore -ErrorAction SilentlyContinue | format-table -auto

    
    
    
    
    