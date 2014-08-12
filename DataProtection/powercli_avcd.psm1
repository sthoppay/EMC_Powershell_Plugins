##
#
# EMC - vElemental.com -  @clintonskitson
# 0708/2014
# powercli_vcp.psm1 - module for managing backups with vCloud Director Backup Extensions
#
##


$Version = Get-PSSnapin vmware.vimautomation.core | %{ $_.version }
if(!$Version -or $Version.Major -lt 5 -or ($Version.Major -eq 5 -and $Version.Minor -lt 1)) { Write-Error "This module must be imported from PowerCLI console version (v5.1+).";pause;break }
if($PSVersionTable.PSVersion.Major -lt 3) { Write-Error "Version 3 of Powershell required.";pause;break }



#is a dependency due to dynamic functions
Function New-CIXmlChildNode  { 
    [CmdletBinding()]   
    Param ([string]$type=$(throw "missing -type"))
    Begin {
        $hashTypes = @{
            "ActiveBackupRepositoryParams"="ReferenceTypeParams"
            "AdhocBackupParams"="AdhocBackupParams"
            "backupApplianceParams"="RegisterBackupApplianceParams"
            "backupoptionsetparams"="backupOptionSetParams"
            "BackupPolicyParams"="BackupPolicyParams"
            "BackupPolicyTemplateReferenceParams"="BackupPolicyTemplateReferenceParams"
            "BackupPolicyTemplateCatalogParams" = "backupPolicyTemplateCatalogParams"
            "BackupPolicyTemplateParams" = "backupPolicyTemplateParams"
            "BackupPolicyCIVAppParams"="ReferenceTypeParams"
            "BackupPolicyDefaultCIVAppParams"="ReferenceTypeParams"
            "backupretentionparams"="backupRetentionParams"
            "backupscheduleparams"="backupScheduleParams"
            "backupRepositoryParams"="RegisterBackupRepositoryParams"
            "DefaultBackupPolicyParams"="ReferenceTypeParams"
            "DefaultReplicationPolicyParams"="ReferenceTypeParams"
            "orgRegistrationParams"="RegisterOrgParams"
            "vCenterRegistrationParams"="RegisterVcenterParams"
            "ReplicationPolicyCIVAppParams"="ReferenceTypeParams"
            "ReplicationPolicyDefaultCIVAppParams"="ReferenceTypeParams"
            "ReplicationPolicyParams"="replicationPolicyParams"
            "RestoreToNewVappParams"="RestoreToNewVappParams"
            "RestorevAppToOriginalParams" = "RestorevAppToOriginalParams"
            "VAppBackupExcludeListParams"="VAppBackupExcludeListParams"
            "VAppBackupExcludeListEmptyParams"="VAppBackupExcludeListEmptyParams"
            "VAppRefList"="VAppRefList"
        }
        if(!$hashTypes.$type -and $hashTypes.Values -notcontains $type)  { Throw "-type of `"$($type)`" does not match $($hashtypes.keys -join ",")" }
        
        [xml]$BackupPolicyParams = @"
<BackupPolicyParams>
    <BackupPolicy name="">
        <Description></Description>
        <IsEnabled>true</IsEnabled>
    </BackupPolicy>
</BackupPolicyParams>
"@
        
        [xml]$BackupScheduleParams = @"
<BackupScheduleParams>
	<BackupSchedule name="">
		<ActivationInterval>2007-03-01T13:00:00/2008-05-11T15:30:00</ActivationInterval>
		<BackupScheduleType>DailyRepeat</BackupScheduleType>
        <BackupWindowDuration>PT3H</BackupWindowDuration>
        <DayOfMonth></DayOfMonth>
        <DayOfWeek></DayOfWeek>
        <Description>No Description</Description>
        <EndTime></EndTime>
        <IsEnabled>true</IsEnabled>
        <NativeTimezone>America/Los_Angeles</NativeTimezone>
        <StartDOWs></StartDOWs>
        <StartHours>1,6,17</StartHours>
        <StartTime></StartTime>
        <WeekOfMonth></WeekOfMonth>
	</BackupSchedule>
</BackupScheduleParams>
"@

    [xml]$BackupRetentionParams = @"
<BackupRetentionParams>
	<BackupRetention name="">
		<Description></Description>
		<AdaptiveRetentionEnabled>false</AdaptiveRetentionEnabled>
		<BackupRetentionType>Duration</BackupRetentionType>
		<Duration>P20D</Duration>
        <EndDate></EndDate>
		<FirstYearlyRetentionDuration>P5Y</FirstYearlyRetentionDuration>
		<FirstMonthlyRetentionDuration>P3M</FirstMonthlyRetentionDuration>
		<FirstWeeklyRetentionDuration>P9W</FirstWeeklyRetentionDuration>
		<FirstDailyRetentionDuration>P60D</FirstDailyRetentionDuration>
	</BackupRetention>
</BackupRetentionParams>
"@

    [xml]$BackupOptionSetParams = @"
<BackupOptionSetParams>
	<BackupOptionSet name="">
		<Description></Description>
		<vAppBackupOptionFlags></vAppBackupOptionFlags>
		<VmBackupOptionFlags></VmBackupOptionFlags>
	</BackupOptionSet>
</BackupOptionSetParams>
"@

    [xml]$BackupPolicyTemplateCatalogParams = @"
<BackupPolicyTemplateCatalogParams>
	<BackupPolicyTemplateCatalog name="">
		<Description></Description>
	</BackupPolicyTemplateCatalog>
</BackupPolicyTemplateCatalogParams>
"@

    [xml]$BackupPolicyTemplateReferenceParams = @"
<BackupPolicyParams>
    <BackupPolicyTemplateReference href="" />
</BackupPolicyParams>
"@

    [xml]$BackupPolicyTemplateParams = @"
<BackupPolicyTemplateParams>
    <BackupPolicyTemplate name="">
        <Description></Description>
        <BackupScheduleRef
            href="" />
        <BackupRetentionRef
            href="" />
        <BackupOptionSetRef
            href="" />
    </BackupPolicyTemplate>
</BackupPolicyTemplateParams>
"@

    [xml]$RegisterBackupApplianceParams = @"
<RegisterBackupApplianceParams>
    <BackupAppliance name="">
        <Description></Description>
        <IsEnabled>true</IsEnabled>
        <Username></Username>
        <Password></Password>
        <Url>https://backupgateway:8443</Url>
    </BackupAppliance>
</RegisterBackupApplianceParams>
"@

    [xml]$RegisterVCenterParams = @"
<RegisterVCenterParams>
    <VCenterReference>
        <Name></Name>
        <vimServer href=""/>
        <Username></Username>
        <Password></Password>
        <EnableSslCertEnforcement>false</EnableSslCertEnforcement>
    </VCenterReference>
</RegisterVCenterParams>
"@

    [xml]$RegisterOrgParams = @"
<RegisterOrgParams>
    <OrgReference href="" name=""/>
</RegisterOrgParams>
"@

    [xml]$RegisterBackupRepositoryParams = @"
<RegisterBackupRepositoryParams>
    <BackupRepositoryParams name="">
        <Description></Description>
        <BackupRepositoryConfigurationSection>
            <IsEnabled>true</IsEnabled>
            <IsBackupAllowed>true</IsBackupAllowed>
            <IsRestoreAllowed>true</IsRestoreAllowed>
            <PrimaryBytesAllowed>1000000000000</PrimaryBytesAllowed>
            <NewBytesAllowedPerDay>1000000000000</NewBytesAllowedPerDay>
        </BackupRepositoryConfigurationSection>
        <BackupStoreId></BackupStoreId>
        <CloudIdFilter></CloudIdFilter>
        <OrgIdFilter></OrgIdFilter>
        <OrgVdcIdFilter></OrgVdcIdFilter>
        <BackupApplianceReference href=""/>
    </BackupRepositoryParams>
</RegisterBackupRepositoryParams>
"@

    [xml]$ReferenceTypeParams = @"
<ReferenceType href="" />
"@

    [xml]$ReplicationPolicyParams = @"
<ReplicationPolicyParams>
	<ReplicationPolicy name="">
		<DestinationAccountName></DestinationAccountName>
		<DestinationAddress></DestinationAddress>
		<DestinationPassword></DestinationPassword>
		<Description>No Description</Description>
		<ByteCountCap>0</ByteCountCap>
		<BandwidthLimit>0</BandwidthLimit>
		<EncryptionSetting>Hi</EncryptionSetting>
		<RetentionOverrideEnabled>false</RetentionOverrideEnabled>
		<RetentionOverride>P7D</RetentionOverride>
		<IsEnabled>true</IsEnabled>
        <IsScheduleEnabled>true</IsScheduleEnabled>
        <IsReplicationEncrypted>true</IsReplicationEncrypted>
		<ReplicationSchedule>
			<NativeTimezone>America/Los_Angeles</NativeTimezone>
			<ActivationInterval>2007-03-01T13:00:00/2008-05-11T15:30:00</ActivationInterval>
			<Description>No Description</Description>
			<ReplicationScheduleType>DailyRepeat</ReplicationScheduleType>
			<StartHours>1,6,17</StartHours>
			<ReplicationWindowDuration>PT4H</ReplicationWindowDuration>
		</ReplicationSchedule>
        <MaximumBackupsPerAccount>0</MaximumBackupsPerAccount>
        <MaximumAgeOfBackup>P7D</MaximumAgeOfBackup>
        <IsMaximumAgeOfBackupFilterEnabled>true</IsMaximumAgeOfBackupFilterEnabled>
    </ReplicationPolicy>
</ReplicationPolicyParams>
"@

    [xml]$AdHocBackupParams = @"
<AdhocBackupParams name="">
    <VappBackupExcludeList excludeallvms="false" >
		    <VmExclude excludealldisks="false" href="https://vcloud.example.com/api/vApp/vm-4"/>
		    <VmExclude excludealldisks="false" href="https://vcloud.example.com/api/vApp/vm-5">
			    <DiskExclude addressofparent="2" diskinstanceid="2000"/>
			    <DiskExclude addressofparent="2" diskinstanceid="2001"/>
		    </VmExclude>
    </VappBackupExcludeList>
</AdhocBackupParams>
"@

    [xml]$VAppBackupExcludeListParams = @"
<VappBackupExcludeList excludeallvms="false" >
	<VmExclude excludealldisks="false" href="">
		<DiskExclude addressofparent="1" diskinstanceid="2000"/>
		<DiskExclude addressofparent="1" diskinstanceid="2001"/>
    </VmExclude>
</VappBackupExcludeList>
"@

    [xml]$VAppBackupExcludeListEmptyParams = @"
<VappBackupExcludeList excludeallvms="false" >
	<VmExclude excludealldisks="false" href=""/>
</VappBackupExcludeList>
"@

    [xml]$RestoreToNewVappParams = @"
<RestoreToNewVappParams name="">
    <Description>""</Description>
    <Owner type="application/vnd.vmware.vcloud.owner+xml">
	<User type="application/vnd.vmware.admin.user+xml" name="" href=""/>
    </Owner>
    <LeaseSettingsSection type="application/vnd.vmware.vcloud.leaseSettingsSection+xml" href="">
	    <DeploymentLeaseInSeconds>0</DeploymentLeaseInSeconds>
	    <StorageLeaseInSeconds>0</StorageLeaseInSeconds>
    </LeaseSettingsSection>
    <RestoreMetadata>true</RestoreMetadata>
    <Source href=""/>
    <VmBackupList>
        <VmBackup
            include="true"
            href="https://vcloud.example.com/api/vApp/vm-4"
            name="ubuntu10-x86">
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
        </VmBackup>
        <VmBackup
            include="true"
            href="https://vcloud.example.com/api/vApp/vm-5"
            name="ubuntu10-x64">
            <Disk
                include="false"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="20480"
                storageprofile="44"
                diskname="Hard disk 2"
                diskinstanceid="2001"
                addressofparent="0"
                addressonparent="1" />
        </VmBackup>
        <VmBackup
            include="false"
            href="https://vcloud.example.com/api/vApp/vm-6"
            name="windows2008-x86">
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
        </VmBackup>
    </VmBackupList>
</RestoreToNewVappParams>
"@

    [xml]$RestorevAppToOriginalParams = @"
<RestorevAppToOriginalParams RetainExcludedVms="false" DelayVMDeletion="false">
    <VmBackupList>
        <VmBackup
            include="true"
            href=""
            name="ubuntu10-x86">
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
        </VmBackup>
        <VmBackup
            include="true"
            href=""
            name="ubuntu10-x64">
            <Disk
                include="false"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="20480"
                storageprofile="44"
                diskname="Hard disk 2"
                diskinstanceid="2001"
                addressofparent="0"
                addressonparent="1" />
        </VmBackup>
        <VmBackup
            include="false"
            href=""
            name="windows2008-x86">
            <Disk
                include="true"
                controllerinstanceid="2"
                capacity="10240"
                storageprofile="44"
                diskname="Hard disk 1"
                diskinstanceid="2000"
                addressofparent="0"
                addressonparent="0" />
        </VmBackup>
    </VmBackupList>
</RestorevAppToOriginalParams>
"@

        [xml]$VAppRefList = @"
<VappRefList>
    <VappRef href=""/>
</VappRefList>
"@

    }
    Process {
        if ($hashTypes.$type -and ($return = Invoke-Expression "`$$($hashTypes.$type)")) { 
            $return
        } else {
            $hashTypes.keys | %{ 
                if($hashTypes.$_ -eq $type) { 
                    (Invoke-Expression "`$$($hashTypes.$_)")
                }
            } | select -first 1
        }

    }
}





#Invoke-GenericREST -href $href -ContentType blah -Accept blah -httpType GET -globalVar "DefaultConcertoServer"
Function Invoke-GenericREST {
    [CmdletBinding()] 
        param([uri]$href = $(throw "missing -href"),
            $ContentType = $(throw "missing -ContentType"),
            $Accept= $(throw "missing -Accept"),
            $httpType="GET",$username,$password,
            $content,$timeout=60000,$GlobalVarName,
            [boolean]$ignoreSsl=$true,$normalResponse,$HeaderAuthName,$authId)
        Process {
                Write-Verbose "$($HttpType): $($Href)"
                try { 
                    $webRequest = [System.Net.WebRequest]::Create($Href)
                } catch { Throw "Problem with Href input" }
                $webRequest.ContentType = $ContentType
                Write-Verbose "ContentType: $($ContentType)"
                $webRequest.Accept = $Accept
                Write-Verbose "Accept: $($Accept)"
                $webRequest.Timeout = $timeout
                $webRequest.Method = $httpType
                $webRequest.KeepAlive = $False
                $webRequest.UserAgent = "Invoke-GenericREST (.NET)"
                if($username -and $password) {
                    $userpass = "$($username):$($password)".ToCharArray()
                    $webRequest.Headers.Add('Authorization',("Basic $([System.Convert]::ToBase64String($userpass))"))
                }elseif($authId) {
                    Write-Verbose "$($HeaderAuthName): $($AuthId)"
                    $webRequest.Headers.Add($HeaderAuthName,$AuthId)
                }else {
                    Throw "Missing Username and Password OR previous `$global:$($GlobalVarName).authId"
                } 
                
                if($ignoreSsl) { 
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
                }


                if($content) {
                    Write-Verbose ("Content: $($content)")
                    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                    try {
                        $requestStream = $webRequest.GetRequestStream()
                        $requestStream.Write($contentBytes, 0,$contentBytes.length)
                        $requestStream.Flush()
                        $requestStream.Close()
                    } catch {}
                }
                                       
                $errorRawResponse = try { $rawResponse = $webRequest.GetResponse() } catch { 
                    $rawResponse = $_.Exception.InnerException.Response
                    $rawResponse
                    $webRequest.Abort()
                }

                if($ignoreSsl) { 
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$false}
                }

                if([int]$rawResponse.statusCode -ne 204) {
                    $streamReader = New-Object System.IO.StreamReader($rawResponse.GetResponseStream())
                    $response = $streamReader.ReadToEnd()
                    $streamReader.Close()
                    Write-Debug ("response: $($response)")
                }else { $response = $null }

                $webRequest.Abort()

                $auth = $rawResponse.headers.get_Item($HeaderAuthName)
                if($auth) {
                    Write-Verbose "Got $($HeaderAuthName): $($auth)"
                    try {
                        New-Variable -name $GlobalVarName -scope global -value @{authId=$auth} -ea stop | Out-Null
                    } catch {
                        $tmpVar = Get-Variable -name $GlobalVarName -scope global
                        $tmpVar.value.authId = $auth
                    }
                    #$tmpVar.Value = @{authId=$auth}
                    #$global:DefaultConcertoServer = @{authId=$auth}
                }

                write-verbose "Got a $([int]$rawResponse.statusCode) response code"
                Write-Verbose ($rawResponse | fl * | Out-String)

                if($errorRawResponse) {
                    if($rawResponse.ContentType -match "xml") {
                        [xml]$response = $response
                        Write-Host -fore red ($response | select * -expandproperty error | select message | fl * | Out-String)
                        Write-Debug ($response | select * -expandproperty error | fl * | Out-String)
                    }elseif($rawResponse.ContentType -match "json") {
                        $response = $response | ConvertFrom-Json
                        Write-Host -fore red ($response | select errorCode,Message | fl * | out-string)
                        Write-Debug ($response | fl * | Out-String)
                    }else {
                        Write-Host -fore red $response
                    }
                } else {
                    Write-Verbose "RESPONSE: $($response | fl * | Out-String)"
                }


                if ($rawResponse -and $normalResponse -contains [int]$rawResponse.statusCode) {
                    #($rawResponse -and $normalResponse -contains [int]$rawResponse.statusCode -and [int]$rawResponse.statusCode -eq 204)) 
                    return @{rawResponse=$rawResponse;response=$response}
                }else {
                    Throw ("Got $($rawResponse.statusCode) and $([int]$rawResponse.statusCode) HTTP status code")
                }                        
                
        }
}



#Invoke-vCDREST -href $href 
Function Invoke-vCDREST {
    [CmdletBinding()] 
        param([uri]$href,$apiCall,
            $ContentType = "",
            $Accept="application/*+xml;version=5.1",
            $httpType="GET",$username,$password,
            [array]$normalResponse=200,$content,$timeout=60000)
        Process {
                if($apiCall -and !$Href) { $href = $global:DefaultCIServers[0].serviceUri.OriginalString + $apiCall }
                if(!$href) { Write-Verbose "No resources to retrieve or missing Href"; return }
                Write-Verbose "apiCall: $($apiCall)"
                #$GlobalVarName = "none"
                $HeaderAuthName = "x-vcloud-authorization"
                $AuthId = $global:DefaultCIServers[0].sessionid
                $result = Invoke-GenericREST -href $href -ContentType $ContentType -Accept $Accept -HttpType $HttpType -Username $Username -Password $Password `
                    -content $content -timeout $timeout -normalResponse $normalResponse -HeaderAuthName $HeaderAuthName -AuthId $AuthId -ignoreSsl:$False
                [xml]$result.response = $result.response
                return $result
                
        }
}



Function Invoke-AvCDREST {
    [CmdletBinding()]
    param([Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [psobject]$InputObject,[string]$name,[string]$id,[ScriptBlock]$FilterScript={$_},$httpType="GET",
        [Boolean]$XmlObject=$False,[Boolean]$References=$False,[boolean]$NoRecurse=$False,$NormalResponse=200,
        $DynamicApiCall,$ApiCall,$ReturnVarInPlace,$ReturnVar=".response",[string]$ReturnVarTask,$RunAsync,[string]$Content,[string]$ContentType,$postTaskLookupCmd)
    Process {
        if(!$ApiCall -and !$DynamicApiCall) {
            $result = $InputObject
            [array]$arrOutput = Invoke-Expression "`$result$($ReturnVarInPlace)"
            [array]$arrOutput2 = $arrOutput | %{
                if(!$References) { 
                     Invoke-vCDREST -href $_.Href -httpType $httpType -normalResponse $normalResponse -Content $Content -ContentType $ContentType | %{Invoke-Expression "`$_$($ReturnVar)"} | where{$_} | Get-CIXmlChildNodes 
                } else {
                    $_
                }
            }
        } else {
            $Href = if($DynamicApiCall) {
                $InputObject.Href+"$($DynamicApiCall)"
            } elseif($ApiCall) {
                "$($ApiCall)"
            } else {$InputObject.Href} 


            $result = Invoke-vCDREST -href $Href -httpType $httpType -normalResponse $normalResponse -Content $Content -ContentType $ContentType 
            [array]$arrOutput = Invoke-Expression "`$result$($ReturnVar)"
            if($noRecurse) { return ($arrOutput | where{$_} | Get-CIXmlChildNodes) }
            [array]$arrOutput2 = $arrOutput | %{ 
                if(!$XmlObject) {
                    $_ | where{$_} | Get-CIXmlChildNodes | select name,id,href,@{n="object";e={
                        if(!$References) { 
                            Invoke-vCDREST -href $_.Href | %{Invoke-Expression "`$_$($ReturnVar)"} | where{$_} | Get-CIXmlChildNodes 
                        } 
                    } }
                } else {$_.DocumentElement}
            }
        }
        
        if($RunAsync -is [boolean] -and !$RunAsync) {
            #do {
            #    $tmpTask = Get-Task -id $arrOutput2.id
            #    $tmpTask
            #    if($tmpTask.state -eq "Error") { write-host -fore red ($tmpTask.ExtensionData | select operation,details | fl * | Out-String); throw "Problem encountered: $($tmpTask.details)" }
            #    if(@("Running","Queued") -contains $tmpTask.state) { Sleep -m 1000 }
            #} until (@("Running","Queued") -notcontains $tmpTask.state)
            
            $Task = (Invoke-Expression "`$arrOutput2$($ReturnVarTask)")
            try {
                Get-Task -id $Task.id -ea stop | Wait-Task -ea stop
                $tmpTask = Get-Task -id $Task.id -ea stop
                Write-Verbose ($tmpTask | fl * | out-string)
            } catch {
                $tmpTask = Get-Task -id $Task.id -ea stop
                if($tmpTask.state -eq "Error") { 
                    write-host -fore red ($tmpTask.ExtensionData | select operation,details | fl * | Out-String)
                    throw  
                } else {
                    throw
                }
            }
            if($postTaskLookupCmd) { Invoke-Expression "$($postTaskLookupCmd) $((Get-Task -id $Task.id).Result)" }
        } else {
            if($name) { $FilterScript = {$_.name -eq $name} }
            if($id) { $FilterScript = {$_.id -eq $id} }
            $return = $arrOutput2 | %{ if($_.object) { $_.object } else { $_ } } | where-object -filterscript $FilterScript
            return $return
        }
    }
}

Function Get-CIXmlChildNodes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject
    )
    Process {
        $childNodes = if($InputObject) { $InputObject.get_childNodes() | where {$_.nodetype -ne "xmldeclaration"}  }
        $childNodes | where {$_} | %{
            if($_.localname -notmatch "Ref$" -and $_.get_parentnode().documentelement.tostring() -match "List$|References$") {
                $_.get_childnodes()
            } else { $_ }
        }
    }
}


function Format-CIXml ($xml, $indent=4) 
{
    <# 
        .DESCRIPTION 
            Serializes an Xml Object
            The example exports the raw XML, deserializes ([xml]), and then serializes again (Format-CIXml) to verify integrity across serialization and deserialziation processes
        .EXAMPLE 
            PS C:\> Format-CIXml [xml](Get-CIVApp vApp1 | Export-CIXml)
    #>   

    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = $Indent 
    
    if($xml.GetType().Name -eq "XmlElement") { 
        $xml_new = new-object system.xml.xmldocument
        $node = $xml_new.ImportNode($xml,$true)
        [void]$xml_new.appendChild($node)
        $xml = $xml_new
    }
    [xml]$xml = $xml
    
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output ($StringWriter.ToString() -replace " />","/>")
}


Function Export-CIXml { 
    [CmdletBinding()]
    <# 
        .DESCRIPTION 
            Export the raw CI XML for a specific CI Object
        .EXAMPLE 
            PS C:\> Get-CIVApp vApp1 | Export-CIXml
    #>     
    Param (
        [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject
    ) 
    
    Process {
        $InputObject | %{
            if($href = $_.Href) {
                Format-CIXML -xml ((Invoke-vCDREST -href $href).response)
            } else {
                write-host -fore red "Href not found on object"
            } 
        }
    }
}

Function Get-CIXmlObject { 
    [CmdletBinding()]
    <# 
        .DESCRIPTION 
            Return a single dimensional parameter list of CI object properties
        .EXAMPLE 
            PS C:\> [xml](Get-CIVApp vApp1 | Export-CIXml) | Get-CIXmlObject
    #>     
    Param (
        [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$true)]
        [PSObject]$InputObject,
        [String]$Location,
        [Boolean]$Recursive=$True
    ) 
    Process {
        $InputObject | Get-Member * | Where {($_.MemberType -eq "Property" -or $_.MemberType -eq "ParameterizedProperty") -and 
          ($_.Definition -match "^System.Xml.XmlElement " -or $_.Definition -match "^string " -or $_.Definition -match "Object\[\]")} | 
            Select *,@{n="FullName";e={if($Location) { "$($Location).$($_.Name)" } else {$_.Name} }} | %{
            $tmpObj = $_
            if($InputObject.Href) { $tmpHref = $InputObject.Href }
            if($_.Definition -match "^string " -and $_.FullName -notmatch "Item.Name$|Item.TypeNameOfValue$") {
                New-Object -type PsObject -Property @{"FullName"=($_.FullName);
                                                      "Value"=($InputObject.($_.Name));
                                                      "NormalizedFullName"=($_.FullName -replace "([a-zA-Z0-9])\.",'$1[0].');
                                                      "Href"=$tmpHref}
            }elseif($_.Definition -match "^System.Xml.XmlElement |^System.Object\[\] ") {
                if(($InputObject.($_.Name)) -and ($InputObject.($_.Name)).GetType() -and ($InputObject.($_.Name)).GetType().name -match "Object\[\]") {
                    $i = 0
                    $InputObject.($_.Name) | %{
                        $strName = "$($tmpObj.FullName)[$($i)]"
                        $_ | Get-CIXmlObject -location $strName
                        $i++
                    }
                } else { 
                    $InputObject.($_.Name) | Get-CIXmlObject -location ($_.FullName)
                }
            }
        } 
    }
}

Function Get-EmcBackupServiceQuery {
    [CmdletBinding()] 
        param($href=$(throw "missing -href"),$httpType="GET",$pageSize=5000,$forceInterval)
        Process {
                if($pageSize) { $Href += "&n=$($pageSize)" }
                Write-Verbose $href
                $result = Invoke-vCDREST -href $href -normalResponse @(200,202)
                $xmlResponse = $result.response
                $rawResponse = $result.rawResponse
                $QueryResultList = $xmlResponse.QueryResultList
                Write-Verbose ($QueryResultList | Out-String)
                if($QueryResultList.href -notmatch 'type=q' -or ($QueryResultList.href -match 'type=q' -and !$QueryResultList.interval)) { $QueryResultList }

                if([int]$rawResponse.statusCode -eq 202) {
                    $interval = if($forceInterval) { $forceInterval } else { $QueryResultList.Interval }
                    Write-Verbose "Sleeping $($interval) seconds"
                    Sleep $interval
                    Get-EmcBackupServiceQuery -Href $QueryResultList.href -pageSize ""
                }elseif($QueryResultList.Next) { 
                    Get-EmcBackupServiceQuery -href $QueryResultList.Next -pageSize ""
                }
        }
}


#get-orgvdc orgvdc1 | Get-BackupRepositoryActive
#Get-BackupAppliance
#Get-CIVApp | Get-CIVAppBackupConf
#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-ReplicationPolicyDefaultCIVApp -noRecurse
#get-orgvdc orgvdc1 | get-backupconfiguration
#get-orgvdc orgvdc1 | get-backuprepository
#get-orgregistration
#get-backupappliance | get-vcenterregistration
#get-backuppolicytemplatecatalog
#get-backuppolicytemplatecatalog | select -first 1 | get-backuppolicytemplate
#get-backuppolicytemplatecatalog | select -first 1 | get-backuppolicytemplate | get-backupschedule
#get-backupschedule
#get-backuppolicytemplatecatalog | select -first 1 | get-backuppolicytemplate | get-backupretention
#get-backupretention
#get-backuppolicytemplatecatalog | select -first 1 | get-backuppolicytemplate | get-backupoptionset
#get-backupoptionset
#get-orgvdc orgvdc1 | get-backuppolicy
#get-orgvdc orgvdc1 | get-backuppolicydefault
#get-orgvdc orgvdc1 | get-backuppolicy | select -first 1 | get-backuppolicycivapp
#get-orgvdc orgvdc1 | get-backuprepositoryactive | get-replicationpolicy
#get-orgvdc orgvdc1 | get-backuprepositoryactive | get-replicationpolicy | get-replicationpolicycivapp
#get-orgvdc orgvdc1 | get-backuprepositoryactive | get-replicationpolicydefault
#get-orgvdc orgvdc1 | get-backuprepositoryactive | get-replicationpolicydefault | get-replicationpolicydefaultcivapp -norecurse
@{name="EmcBackupService";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService";returnVar=".response"},
@{name="BackupRepositoryActive";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/ActiveBackupRepository";returnVar=".response";expectInput="true";OnlyAdminRecurse="true"},
@{name="BackupAppliance";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupAppliances";apiIdCall="/backupAppliance/";returnVar=".response"},
@{name="vCenterRegistration";dynamicApiCall="/vCenterRegistrations";apiIdCall="/vCenterRegistration/";returnVar=".response"},
@{name="BackupConfiguration";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/BackupConfiguration";returnVar=".response";expectInput="true"},
@{name="BackupRepository";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/BackupRepositories";apiIdCall="/backupRepository/";returnVar=".response";OnlyAdminRecurse="true"},
@{name="OrgRegistration";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/orgRegistrations";returnVar=".response";references="true";noRecurse="true"},
@{name="BackupPolicyTemplateCatalog";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupPolicyTemplateCatalogs";apiIdCall="/backupPolicyTemplateCatalog/";returnVar=".response"},
@{name="BackupPolicyTemplate";apiIdCall="/backupPolicyTemplate/";returnVar=".response";returnVarInPlace=".BackupPolicyTemplateRef"},
@{name="BackupSchedule";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupSchedules";apiIdCall="/backupSchedule/";returnVar=".response";returnVarInPlace=".BackupScheduleRef"},
@{name="BackupRetention";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupRetentions";apiIdCall="/backupRetention/";returnVar=".response";returnVarInPlace=".BackupRetentionRef"},
@{name="BackupOptionSet";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupOptionSets";apiIdCall="/backupOptionSet/";returnVar=".response";returnVarInPlace=".BackupOptionSetRef"},
@{name="BackupPolicy";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/BackupPolicies";apiIdCall="/backupPolicy/";returnVar=".response"},
@{name="BackupPolicyDefault";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/DefaultBackupPolicy";returnVar=".response";expectInput="true"},
@{name="BackupPolicyDefaultCIVApp";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/DefaultBackupPolicy/attachedVapps";returnVar=".response";expectInput="true";noRecurse="true"},
@{name="BackupPolicyCIVApp";apiCall="`$null";dynamicApiCall="/attachedVapps";expectInput="true";returnVar=".response";noRecurse="true"},
@{name="ReplicationPolicy";apiCall="`$null";dynamicApiCall="/ReplicationPolicies";apiIdCall="/replicationPolicy/";returnVar=".response"},
@{name="ReplicationPolicyCIVApp";apiCall="`$null";dynamicApiCall="/attachedVapps";expectInput="true";returnVar=".response";noRecurse="true"},
@{name="ReplicationPolicyDefault";apiCall="`$null";dynamicApiCall="/DefaultReplicationPolicy";expectInput="true";returnVar=".response";},
@{name="ReplicationPolicyDefaultCIVApp";apiCall="`$null";dynamicApiCall="/DefaultReplicationPolicy/attachedVapps";expectInput="true";returnVar=".response";noRecurse="true"} | %{
    $strCmdlet = @"
Function Get-$($_.Name) {
    [CmdletBinding()]
    param([Parameter(Mandatory=`$$([boolean]"$($_.expectInput)"), Position=0, ValueFromPipeline=`$true)]
        [psobject]`$InputObject,[string]`$name,[string]`$id,[ScriptBlock]`$FilterScript={`$_},
        [boolean]`$XmlObject =`$$([boolean]"$($_.XmlObject)"),
        [boolean]`$References =`$$([boolean]"$($_.References)"),
        [boolean]`$NoRecurse =`$$([boolean]"$($_.NoRecurse)"))
    Process {
        `$normalResponse = if(`"$($_.normalResponse)") { $($_.normalResponse) } else { 200 }
        if(!`$NoRecurse) { `$NoRecurse = if(`"$($_.OnlyAdminRecurse)" -and  `$global:DefaultCIServers[0].Org -ne "System") { `$true } }
        if(`$id -and "$($_.apiIdCall)") {
            `$apiCall = `"`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService$($_.apiIdCall)`"+`$id.split(':')[-1]
            `$dynamicApiCall = `$null
            `$noRecurse = `$true
        } elseif(`"$($_.apiCall)`" -and `"$($_.dynamicApiCall)`" -and !`$InputObject) {
            `$apiCall = `"$($_.apiCall)`"
            `$dynamicApiCall = `$null
        } elseif(`"$($_.apiCall)`" -and `"$($_.dynamicApiCall)`" -and `$InputObject) {
            `$apiCall = `$null
            `$dynamicApiCall = `"$($_.dynamicApiCall)`"
        } else {
            if(!"$($_.apiIdCall)" -and "$($_.expectInput)" -and `!`$InputObject) { throw "Missing -InputObject" }  
            `$apiCall = `"$($_.apiCall)`"
            `$dynamicApiCall = `"$($_.dynamicApiCall)`"
        }

        `$InputObject | Invoke-AvCDREST -Name `$name -id `$id -FilterScript `$FilterScript ``
            -XmlObject:([boolean]`$XmlObject) -References:([boolean]`$References) -NoRecurse:([boolean]`$NoRecurse) ``
            -NormalResponse `$NormalResponse ``
            -DynamicApiCall `$dynamicApiCall -ApiCall `$apiCall ``
            -ReturnVarInPlace `"$($_.ReturnVarInPlace)`" -ReturnVar `"$($_.ReturnVar)`"
    }
}
"@
    Invoke-Expression $strCmdlet
}


#Get-BackupAppliance | Search-BackupAppliance -type vcloud 
#Get-BackupAppliance | Search-BackupAppliance -type vcloud -vcloudname $global:DefaultCIServers[0].ExtensionData.Name
#Get-BackupAppliance | Search-BackupAppliance -type org -vcloudguid (Get-BackupAppliance | Search-BackupAppliance -type vcloud -vcloudname $global:DefaultCIServers[0].ExtensionData.Name).guid
#Get-BackupAppliance | Search-BackupAppliance -type vdc -vcloudguid "37101445-39d2-4fd5-a1ec-cc404f689571" -orgguid "392b75c8-726c-428a-90e5-2c6ac6d0c4d7"
#Get-BackupAppliance | Search-BackupAppliance -type vapp -vcloudguid "37101445-39d2-4fd5-a1ec-cc404f689571" -orgguid "392b75c8-726c-428a-90e5-2c6ac6d0c4d7"
#Get-BackupAppliance | Search-BackupAppliance -type backup -vcloudguid "37101445-39d2-4fd5-a1ec-cc404f689571" -orgguid "392b75c8-726c-428a-90e5-2c6ac6d0c4d7" -vappguid "7e09f643-5210-4c00-a1ad-b60182f55581"
#Get-BackupAppliance | Search-BackupAppliance -type owner -vcloudguid "37101445-39d2-4fd5-a1ec-cc404f689571" -orgguid "392b75c8-726c-428a-90e5-2c6ac6d0c4d7"
#Get-BackupAppliance | Search-BackupAppliance -type activity
#Get-BackupAppliance | Search-BackupAppliance -type appliancestate
#Get-Orgvdc | Get-BackupRepository | Search-BackupRepository -type vapp
#Get-Orgvdc | Get-BackupRepository | Search-BackupRepository -type vdc
#Get-Orgvdc | Get-BackupRepository | Search-BackupRepository -type backup -vappguid ((get-orgvdc orgvdc1 | get-civapp vapp_system_1).id.split(':')[-1])
@(
    @{"function"="BackupAppliance";"call"="backupAppliances";"call_instance"="backupAppliance"},
    @{"function"="BackupRepository";"call"="backupRepository";"call_instance"="backupRepository"}
) | %{
    $execStmt = @"
Function Search-$($_.function) { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=`$False, Position=0, ValueFromPipeline=`$true)]
        [PSObject]`$InputObject,
        `$href,
        `[ValidateSet("vcloud","org","vdc","vapp","backup","owner","activity","appliancestate","repositorystate")]`$type=`$(throw "missing -type"),
        `$vcloudname,
        `$vcloudguid,
        `$orgname,
        `$orgguid,
        `$vdcname,
        `$vdcguid,
        `$vappname,
        `$vappguid,
        `$backupdaterange,
        `$ownername,
        `$pageSize=5000
        )
    Process {
        `$newHref = if(!`$href) { `$InputObject.Href } else { `$href }
        `$typeHash = @{
            "vcloud"="vcloudname"
            "org"="vcloudguid","orgname"
            "vdc"="vcloudguid","orgguid","vdcname"
            "vapp"="vcloudguid","orgguid","vappname"
            "backup"="vcloudguid","orgguid","vappguid","backupdaterange"
            "owner"="vcloudguid","orgguid","ownername"
        }
        `$options = "type=`$(`$type)"
        `$typeHash.`$type | where {`$_} | where -filterScript {(Invoke-Expression "``$`$(`$_)")} | %{ `$options += "&`$(`$_)=`$(Invoke-Expression "``$`$(`$_)")" }
        `$newHref = "`$(`$newHref)/query?`$options"
        [array]`$arrOutput = Get-EmcBackupServiceQuery -href `$newHref -pageSize `$pageSize
        if(`$arrOutput) {
            Write-Verbose (`$arrOutput.OuterXml | Out-String)
            [array]`$arrOutput2 = `$arrOutput | where{`$_} | Get-CIXmlChildNodes 
            `$arrOutput2 | %{ if(`$_.object) { `$_.object } else { `$_ } }
        }
    }
}
"@
   Invoke-Expression ($execStmt)
}


#get-backupappliance | select -first 1 | remove-backupappliance
#get-org orgvdc1 | get-backuprepositoryrestoreonly | remove-backuprepository
#get-org dpad10 | remove-orgregistration
#get-backupappliance  | select -first 1 | Get-vCenterRegistration | Remove-vCenterRegistration
#get-backuppolicytemplatecatalog | select -last 1 | Remove-BackupPolicyTemplateCatalog
#get-backuppolicytemplatecatalog | select -first 1 | get-backupschedule | select -last 1 | remove-backupschedule
#get-backuppolicytemplatecatalog | select -first 1 | Get-BackupPolicyTemplate | Get-BackupSchedule | remove-backupschedule
#get-backuppolicytemplatecatalog | select -first 1 | Get-BackupPolicyTemplate | Get-BackupOptionSet | remove-backupoptionset
#get-backuppolicytemplatecatalog | select -first 1 | Get-BackupPolicyTemplate | Get-BackupRetention | remove-backupretention
#get-backuppolicytemplatecatalog | select -first 1 | Get-BackupPolicyTemplate | select -first 1 | Remove-BackupPolicyTemplate
#get-civapp vapp_system_1 | Get-CIVAppBackup -verbose | select -first 1 | remove-civappbackup
#get-orgvdc orgvdc1 | get-backuprepository | get-replicationpolicy | select -last 1 | remove-replicationpolicy
#Get-CIVApp name | removecivappbackupexcludelist
@{name="BackupAppliance";returnVar=".response";normalResponse=202;runAsyncCapable=$true;XmlObject="true";expectInput="true"},
@{name="vCenterRegistration";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupRepository";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupPolicyTemplateCatalog";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupSchedule";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupRetention";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupOptionSet";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupPolicyTemplate";returnVar=".response";expectInput="true";normalResponse=204},
@{name="BackupPolicy";returnVar=".response";expectInput="true";normalResponse=200},
@{name="ReplicationPolicy";returnVar=".response";expectInput="true";normalResponse=204},
@{name="CIVAppBackup";returnVar=".response";expectInput="true";normalResponse=202},
@{name="CIVAppBackupExcludeList";DynamicApiCall="/backupexcludelist";returnVar=".response";expectInput="true";normalResponse=204} | %{
    $strRunAsync = if($_.runAsyncCapable) { ",[boolean]`$runAsync=`$False" }
    $execStmt = @"
Function Remove-$($_.Name) {
    [CmdletBinding()]
    param([Parameter(Mandatory=`$$([boolean]"$($_.expectInput)"), Position=0, ValueFromPipeline=`$true)]
        [psobject]`$InputObject$strRunAsync)
    Process {
        `$normalResponse = if(`"$($_.normalResponse)") { $($_.normalResponse) } else { 204 }
        `$httpType = if("$($_.httpType)") { "$($_.httpType)" } else { "DELETE" }
        if(`$RunAsync -isnot [boolean]) { `$RunAsync = `$true }
        if(`$XmlObject -isnot [boolean]) { `$XmlObject = `$false }
        if(`$References -isnot [boolean]) { `$References = `$false }
        if(`$NoRecurse -isnot [boolean]) { `$NoRecurse = `$false }
        `$InputObject | Invoke-AvCDREST  ``
            -XmlObject:([boolean]`$XmlObject) -References:([boolean]`$References) -NoRecurse:([boolean]`$NoRecurse) ``
            -NormalResponse `$NormalResponse -httpType `$httpType ``
            -DynamicApiCall `"$($_.DynamicApiCall)`" -ApiCall `"$($_.ApiCall)`" ``
            -ReturnVarInPlace `"$($_.ReturnVarInPlace)`" -ReturnVar `"$($_.ReturnVar)`" ``
            -RunAsync:`$RunAsync
    }
}
"@
    Invoke-Expression $execStmt
}



#2..13 | %{ get-org "dpad" | new-orgvdc -Name "OrgvDC$($_)" -AllocationModelPayAsYouGo -ProviderVdc (Get-ProviderVdc) -VMCpuCoreMHz 256 }
#2..13 | %{ Get-Orgvdc "OrgvDC$($_)" | New-BackupRepository -name vcp-bg -BackupStoreId (Get-BackupAppliance | %{ $_.backupstores.backupstore.backupstoreid }) -BackupApplianceReference ((get-backupappliance).href) }
#get-orgvdc mgc_vdc1 | New-BackupRepository -name repository02 -BackupStoreId (Get-BackupAppliance -name ave-04 | %{ $_.backupstores.backupstore | where {$_.backupstorename -eq "ddve-02.brsvlab.local"} | %{ $_.backupstoreid }}) -BackupApplianceReference ((get-backupappliance -name ave-04).href)

#New-BackupAppliance -name vcp-bg -Description nodesc -IsEnabled "true" -Username MCUser -password MCUser1 -Url https://vcp-bg.brsvlab.local:8443
#new-backupoptionset -name test
#new-backupretention -name test
#new-backupschedule -name test
#$BP = get-orgvdc orgvdc2 | New-BackupPolicy -href ((Get-backuppolicytemplate)[0].href) -verbose; $BP.name = "newName"; $BP | Update-BackupPolicy
#get-orgvdc orgvdc2 | New-BackupPolicyDefault -href ((Get-orgvdc orgvdc2 | get-backuppolicy | select -first 1).href)
#$BA = get-backupappliance | select -first 1; get-orgvdc orgvdc1 | new-backuprepository -BackupApplianceReference $BA.href -verbose -BackupStoreId $BA.backupstores.backupstore.backupstoreid
#get-orgvdc orgvdc1 | New-BackupRepositoryActive -href ((Get-OrgVdc orgvdc1 | Get-BackupRepository | select -first 1).href) -verbose
#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | New-ReplicationPolicy  -name "test" -DestinationAccountName test -DestinationAddress test -DestinationPassword test -verbose
#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | get-replicationpolicy | select -last 1 | New-ReplicationPolicyCIVApp -href((get-orgvdc orgvdc1 | get-civapp | select -first 1).href) -verbose                                                                                            
#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | New-ReplicationPolicyDefaultCIVApp -href ((get-orgvdc orgvdc1 | get-civapp | select -first 1).href)
#get-orgvdc orgvdc1 | New-BackupPolicyDefaultCIVApp -href ((get-orgvdc orgvdc1 | get-civapp test15).href) -verbose

@{name="BackupAppliance";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupAppliances";param="RegisterBackupApplianceParams";returnVar=".response";normalResponse=202;runAsync=$false;PostTaskLookupCmd="Get-BackupAppliance -id"},
@{name="vCenterRegistration";dynamicApiCall="/vCenterRegistrations";param="RegisterVCenterParams";returnVar=".response";returnVarTask=".Tasks";expectInput="true";normalResponse=202;runAsync=$false;XmlObject=$true},
@{name="BackupRetention";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupRetentions";param="BackupRetentionParams";returnVar=".response";normalResponse=201},
@{name="BackupSchedule";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupSchedules";param="BackupScheduleParams";returnVar=".response";normalResponse=201},
@{name="BackupOptionSet";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupOptionSets";param="BackupOptionSetParams";returnVar=".response";normalResponse=201},
@{name="BackupPolicy";apiCall="`$(`$InputObject.Href.replace('/vdc','/extension/vdc'))/BackupPolicies";param="BackupPolicyTemplateReferenceParams";returnVar=".response";expectInput="true";normalResponse=201},
@{name="BackupPolicyCIVApp";dynamicApiCall="/attachedVapps";param="BackupPolicyCIVAppParams";returnVar=".response";httpType="PUT";normalResponse=204;XmlObject=$true},
@{name="BackupPolicyDefault";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/DefaultBackupPolicy";param="DefaultBackupPolicyParams";returnVar=".response";httpType="PUT";expectInput="true";normalResponse=200;XmlObject=$true},
@{name="BackupPolicyTemplateCatalog";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/backupPolicyTemplateCatalogs";param="BackupPolicyTemplateCatalogParams";returnVar=".response";normalResponse=201},
@{name="BackupPolicyTemplate";dynamicApiCall="/backupPolicyTemplates";param="BackupPolicyTemplateParams";returnVar=".response";expectInput="true";normalResponse=201},
@{name="BackupPolicyDefaultCIVApp";apiCall="`$(`$InputObject.Href.replace('/api/vdc','/api/admin/vdc').replace('/vdc','/extension/vdc'))/DefaultBackupPolicy/attachedVapps";param="BackupPolicyDefaultCIVAppParams";returnVar=".response";httpType="PUT";normalResponse=204;XmlObject=$true},
@{name="BackupRepository";apiCall="`$(`$InputObject.Href.replace('/vdc','/extension/vdc'))/BackupRepositories";param="BackupRepositoryParams";returnVar=".response";expectInput="true";normalResponse=202;runAsync=$false;PostTaskLookupCmd="Get-BackupRepository -id"},
@{name="BackupRepositoryActive";apiCall="`$(`$InputObject.Href.replace('/vdc','/extension/vdc'))/ActiveBackupRepository";param="ActiveBackupRepositoryParams";returnVar=".response";httpType="PUT";expectInput="true";normalResponse=204},
@{name="OrgRegistration";apiCall="`$(`$global:DefaultCIServers[0].serviceUri.OriginalString)admin/extension/EmcBackupService/orgRegistrations";param="RegisterOrgParams";returnVar=".response";normalResponse=202;runAsync=$false;},
@{name="ReplicationPolicy";apiCall="ReplicationPolicies";dynamicApiCall="/ReplicationPolicies";param="ReplicationPolicyParams";returnVar=".response";expectInput="true";normalResponse=201},
@{name="ReplicationPolicyCIVApp";dynamicApiCall="/attachedVapps";param="ReplicationPolicyCIVAppParams";returnVar=".response";httpType="PUT";normalResponse=204;XmlObject=$true},
@{name="ReplicationPolicyDefault";apiCall="`$(`$InputObject.Href.replace('/vdc','/extension/vdc'))/DefaultReplicationPolicy";param="DefaultReplicationPolicyParams";returnVar=".response";httpType="PUT";expectInput="true";normalResponse=200;XmlObject=$true},
@{name="ReplicationPolicyDefaultCIVApp";apiCall="`$(`$InputObject.Href.replace('/vdc','/extension/vdc'))/DefaultReplicationPolicy/attachedVapps";param="ReplicationPolicyDefaultCIVAppParams";returnVar=".response";httpType="PUT";normalResponse=204;XmlObject=$true} | %{
    $strRunAsync = if($_.runAsync -is [boolean] -and $_.runAsync) { ",[boolean]`$runAsync=`$True" } elseif($_.runAsync -is [boolean] -and !$_.runAsync) { ",[boolean]`$runAsync=`$False" }
    $paramParent =  try { New-CIXmlChildNode -type "$($_.param)" } catch {}
    if($paramParent) {
        $param = try { ($paramParent.get_childNodes() | where {$_.nodetype -ne "xmldeclaration"}).get_childNodes() | where {$_.nodetype -ne "xmldeclaration"} } catch {}    
        if(!$param) { $param = $paramParent.get_childNodes() | where {$_.nodetype -ne "xmldeclaration"} }
        [array]$getParamsAttributes = $param.get_attributes() | %{"[string]`$$($_.name)" }
        [array]$getParamsNodes = $param.get_childnodes() | %{"[string]`$$($_.name)" }
        $strGetParamsAttributes = $getParamsAttributes -join ","
        $strGetParamsNodes = $getParamsNodes -join ","
        $strGetParams = if($getParamsAttributes -or $getParamsNodes) { ",$(@($getParamsAttributes+$getParamsNodes | where{$_}) -join ",")" }
    }else {
        [array]$getParamsAttributes = @()
        [array]$getParamsNodes = @()
        $strGetParamsAttributes = ""
        $strGetParamsNodes = ""
        $strGetParams = ""
    }

    $execStmt = @"
Function New-$($_.name) {
    [CmdletBinding()]   
    Param ([Parameter(Mandatory=`$$([boolean]"$($_.expectInput)"), Position=0, ValueFromPipeline=`$true)]
           [PSObject]`$InputObject,[PSObject]`$param
           $($strGetParams)$($strRunAsync)
           )
    Process {
        if(!`$param) { 
            `$paramParent = New-CIXmlChildNode -type "$($_.param)"
        } else {
            `$paramParent = `$param.clone()
        }

        `$param = try { (`$paramParent.get_childNodes() | where {`$_.nodetype -ne "xmldeclaration"}).get_childNodes() | where {`$_.nodetype -ne "xmldeclaration"} } catch {}  
        if(!`$param) { `$param = `$paramParent.get_childNodes() | where {`$_.nodetype -ne "xmldeclaration"} }

        [array]`$arrInParamsAttributes = ("$("$strGetParamsAttributes" -replace "\[string\]\`$",'')").split(',')
        [array]`$arrInParamsNodes = ("$("$strGetParamsNodes" -replace "\[string\]\`$",'')").split(',')
        Write-Verbose (`$arrInParamsAttributes -join ",")
        Write-Verbose (`$arrInParamsNodes -join ",")
        Write-Verbose (`$psboundparameters.keys -join ",")
        `$arrInParamsAttributes | %{ if(`$psboundparameters.keys -contains `$_) { `$param.`$_ = Invoke-Expression "``$`$(`$_)" } }
        `$arrInParamsNodes | %{ if(`$psboundparameters.keys -contains `$_) {
            if(`$param.`$_.href -eq '') { `$param.`$_.href = Invoke-Expression "``$`$(`$_).toString()" } else { `$param.`$_ = Invoke-Expression "``$`$(`$_)" } }
        }

        write-verbose "`nSENDING OBJECT"
        write-verbose (`$param | out-string)

        #`$content =  Format-CIXml -xml `$paramParent.DocumentElement.OuterXml
        `$content =  Format-CIXml -xml `$paramParent
        `$contentType = "`$(`$paramParent.DocumentElement.toString())+xml"

        `$normalResponse = if(`"$($_.normalResponse)") { $($_.normalResponse) } else { 204 }
        `$httpType = if("$($_.httpType)") { "$($_.httpType)" } else { "POST" }
        if(`$RunAsync -isnot [boolean]) { `$RunAsync = `$true }
        `$XmlObject = if("$($_.XmlObject)") { "`$$($_.XmlObject)" }
        `$References = if("$($_.References)") { `$true }
        `$NoRecurse = if("$($_.NoRecurse)") { `$true }
        `$InputObject | Invoke-AvCDREST  ``
            -XmlObject:([boolean]`$XmlObject) -References:([boolean]`$References) -NoRecurse:([boolean]`$NoRecurse) ``
            -Content `$Content -ContentType `$ContentType ``
            -NormalResponse `$NormalResponse -httpType `$httpType ``
            -DynamicApiCall `"$($_.DynamicApiCall)`" -ApiCall `"$($_.ApiCall)`" ``
            -ReturnVarInPlace `"$($_.ReturnVarInPlace)`" -ReturnVar `"$($_.ReturnVar)`" ``
            -RunAsync:`$RunAsync -ReturnVarTask "$($_.ReturnVarTask)" -PostTaskLookupCmd `"$($_.PostTaskLookupCmd)`"
    }
}
"@
    Invoke-Expression ($execStmt)
}




#get-backupappliance | where{$_.name -eq "vcp-bg"} | Update-BackupAppliance -name "vcp-bg-test" -username MCUser -password MCUser1
#$bc = get-orgvdc orgvdc1 | get-backupconfiguration; $bc.OrgAdminAuthorizations.enableAdhocBackup = "true";$bc | update-backupconfiguration
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog1"} | update-backuppolicytemplatecatalog -name "catalog1-test"
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog1-test"} | get-backuppolicytemplate | select -first 1 | update-backuppolicytemplate -name backuppolicytemplate1
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog1-test"} | get-backuppolicytemplate | select -first 1 | get-backupschedule | update-backupschedule -name "schedule1"
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog2"} | get-backuppolicytemplate | get-backupschedule | update-backupschedule -name backupschedule1
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog2"} | get-backuppolicytemplate | get-backupoptionset | update-backupoptionset -name backupoptionset1
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog2"} | get-backuppolicytemplate | get-backupoptionset | update-backupoptionset -vmbackupoptionflags "[avvcbimage]quiesce_fs=false,debug=false"
#get-backuppolicytemplatecatalog | where {$_.name -eq "catalog2"} | get-backuppolicytemplate | get-backupretention | update-backupretention -name backupretention1
#$bp = get-orgvdc orgvdc1 | get-backuppolicy | select -first 1;$bp.name="silver";$bp | update-backuppolicy
#$bp = get-orgvdc orgvdc1 | get-backuppolicy | where {$_.name -eq "gold"}; $bp.BackupOptionSetSection.VmBackupOptionFlags = "[avvcbimage]quiesce_fs=false,debug=false"; $bp | update-backuppolicy
#get-orgvdc orgvdc1 | get-replicationpolicy | select -first 1 | update-replicationpolicy -name replicationpolicy1
@(
    @{name="BackupAppliance";apiCall="`$(`$InputObject.Href)";param="BackupApplianceParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupConfiguration";apiCall="`$(`$InputObject.Href)";param="BackupConfigurationParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupPolicy";apiCall="`$(`$InputObject.Href)";param="BackupPolicyParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupPolicyTemplateCatalog";apiCall="`$(`$InputObject.Href)";param="BackupPolicyTemplateCatalogParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupPolicyTemplate";apiCall="`$(`$InputObject.Href)";param="BackupPolicyTemplateParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupRepository";apiCall="`$(`$InputObject.Href)";param="BackupRepositoryParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupRetention";apiCall="`$(`$InputObject.Href)";param="BackupRetentionParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupOptionSet";apiCall="`$(`$InputObject.Href)";param="BackupOptionSetParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="BackupSchedule";apiCall="`$(`$InputObject.Href)";param="BackupScheduleParams";returnVar=".response";expectInput="true";normalResponse=200},
    @{name="ReplicationPolicy";apiCall="`$(`$InputObject.Href)";param="ReplicationPolicyParams";returnVar=".response";expectInput="true";normalResponse=200}
) | %{
    $strRunAsync = if($_.runAsync -is [boolean] -and $_.runAsync) { ",[boolean]`$runAsync=`$True" } elseif($_.runAsync -is [boolean] -and !$_.runAsync) { ",[boolean]`$runAsync=`$False" }
    $paramParent =  try { New-CIXmlChildNode -type "$($_.param)" } catch {}
    if($paramParent) {
        $param = try { ($paramParent.get_childNodes() | where {$_.nodetype -ne "xmldeclaration"}).get_childNodes() | where {$_.nodetype -ne "xmldeclaration"} } catch {}    
        if(!$param) { $param = $paramParent.get_childNodes() | where {$_.nodetype -ne "xmldeclaration"} }
        [array]$getParamsAttributes = $param.get_attributes() | %{"[string]`$$($_.name)" }
        [array]$getParamsNodes = $param.get_childnodes() | %{"[string]`$$($_.name)" }
        $strGetParamsAttributes = $getParamsAttributes -join ","
        $strGetParamsNodes = $getParamsNodes -join ","
        $strGetParams = if($getParamsAttributes -or $getParamsNodes) { ",$(@($getParamsAttributes+$getParamsNodes | where{$_}) -join ",")" }
    }else {
        [array]$getParamsAttributes = @()
        [array]$getParamsNodes = @()
        $strGetParamsAttributes = ""
        $strGetParamsNodes = ""
        $strGetParams = ""
    }

    $execStmt = @"
Function Update-$($_.name) { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=`$True, Position=0, ValueFromPipeline=`$true)]
        [PSObject]`$InputObject$($strGetParams)$($strRunAsync)
        )
    Process {
        [array]`$arrInParamsAttributes = ("$("$strGetParamsAttributes" -replace "\[string\]\`$",'')").split(',')
        [array]`$arrInParamsNodes = ("$("$strGetParamsNodes" -replace "\[string\]\`$",'')").split(',')
        Write-Verbose (`$arrInParamsAttributes -join ",")
        Write-Verbose (`$arrInParamsNodes -join ",")
        Write-Verbose (`$psboundparameters.keys -join ",")
        `$arrInParamsAttributes | %{ 
            if(`$psboundparameters.keys -contains `$_) { 
                if(`$InputObject.hasAttribute("`$(`$_)")) { `$InputObject.`$_ = Invoke-Expression "``$`$(`$_)" } else {
                    `$InputObject.SetAttribute("`$(`$_)",(Invoke-Expression "``$`$(`$_)"))
                }
            } 
        }
        `$arrInParamsNodes | %{ 
            if(`$psboundparameters.keys -contains `$_) { 
                if(`$InputObject.`$_) { 
                    if(`$InputObject.`$_.href -eq '') { `$InputObject.`$_.href = Invoke-Expression "``$`$(`$_)" } else { `$InputObject.`$_ = Invoke-Expression "``$`$(`$_)" }
                } else {
                    `$newNode = `$InputObject.get_ownerdocument().CreateNode([System.Xml.XmlNodeType]"Element","`$(`$_)","")
                    `$newNode.InnerText = Invoke-Expression "``$`$(`$_)"
                    [void]`$InputObject.appendChild(`$newNode)
                }
            } 
        }


        write-verbose "`nSENDING OBJECT"
        write-verbose (`$InputObject | out-string)

        #`$content =  Format-CIXml -xml `$InputObject.OwnerDocument.OuterXml
        `$content =  Format-CIXml -xml `$InputObject
        `$contentType = "`$(`$InputObject.LocalName.toString())+xml"

        `$normalResponse = if(`"$($_.normalResponse)") { $($_.normalResponse) } else { 200 }
        `$httpType = if("$($_.httpType)") { "$($_.httpType)" } else { "PUT" }
        if(`$RunAsync -isnot [boolean]) { `$RunAsync = `$true }
        `$XmlObject = if("$($_.XmlObject)") { "`$$($_.XmlObject)" }
        `$References = if("$($_.References)") { `$true }
        `$NoRecurse = if("$($_.NoRecurse)") { `$true }
        `$InputObject | Invoke-AvCDREST  ``
            -XmlObject:([boolean]`$XmlObject) -References:([boolean]`$References) -NoRecurse:([boolean]`$NoRecurse) ``
            -Content `$Content -ContentType `$ContentType ``
            -NormalResponse `$NormalResponse -httpType `$httpType ``
            -DynamicApiCall `"$($_.DynamicApiCall)`" -ApiCall `"$($_.ApiCall)`" ``
            -ReturnVarInPlace `"$($_.ReturnVarInPlace)`" -ReturnVar `"$($_.ReturnVar)`" ``
            -RunAsync:`$RunAsync -ReturnVarTask "$($_.ReturnVarTask)" -PostTaskLookupCmd `"$($_.PostTaskLookupCmd)`"
    }
}
"@
   Invoke-Expression ($execStmt)
}

Function Get-CIVirtualCenter {
 [CmdletBinding()] 
     Param ($name
        )
    Process {
        Search-Cloud virtualcenter | where {($name -and $name -eq $_.name) -or !$name}| select *,@{n="href";e={"$($global:DefaultCIServers[0].serviceuri.absoluteuri)admin/extension/vimServer/$($_.id.split(':')[-1])"}} -excludeProperty href
    }
}



#get-orgvdc orgvdc1 | get-backuprepositoryactive | remove-replicationpolicydefault
Function Remove-ReplicationPolicyDefault { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        Write-Verbose $InputObject.id
        $InputObject | New-ReplicationPolicyDefault -href ""
    }
}


#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | get-replicationpolicyDefaultCIVApp | select -first 2 | Start-CIVAppReplication -href ((Get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-ReplicationPolicyDefault).href) -verbose
Function Start-CIVAppReplication { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,$PolicyRef=$(throw "missing -PolicyRef"),[boolean]$runAsync=$False)
    Begin {
        $arrInput = @()
    }
    Process {
        $arrInput += $InputObject
    }
    End {
        Write-Verbose ($arrInput | select name,id,href | out-string)
        $VAppRefList = New-CIXmlChildNode -type VAppRefList
        $VAppRefList = $VAppRefList.DocumentElement
        $param = "VAppRef"
        $newNode = $VAppRefList.$param.CloneNode($true)
        $VAppRefList.$param | %{ [void]$VAppRefList.RemoveChild($_) }
        $arrInput | %{
            $cloneNode = $newNode.CloneNode($true)
            $cloneNode.href = $_.href
            [void]$VAppRefList.AppendChild($cloneNode)
        }
        #$content =  Format-CIXml -xml $VAppRefList.OwnerDocument.OuterXml
        $content =  Format-CIXml -xml $VAppRefList
        Invoke-AvCDREST -httpType POST -ApiCall $PolicyRef -Content $content -RunAsync:$RunAsync -NormalResponse 202

        #$href = "$($global:DefaultCIServers[0].serviceUri.AbsoluteUri)admin/extension/EmcBackupService/replicationPolicy/$($href)"
        #$InputObject | Update-CIXmlObject -href $href -httpType "POST" -runAsync:$True
    }
}

#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | start-civappbackup
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | start-civappbackup -jsonVmFilterInclude '{"WebServer1":{"Disk":["2:2000"]}}'
#get-orgvdc orgvdc1 | get-civapp vapp_system_1b | start-civappbackup -jsonVmFilterInclude '{"WebServer1":null,"WebServer2":null}'
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | start-civappbackup -ExcludeAllVms "true"
Function Start-CIVAppBackup { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$href,$ExcludeAllVms="false",$VAppBackupExcludeParam,$jsonVmFilterInclude,[boolean]$runAsync=$False)
    Process {
        Write-Verbose ($InputObject | out-string)
        $AdhocBackupParams = New-CIXmlChildNode -type AdHocBackupParams
        if($jsonVmFilterInclude -or $VAppBackupExcludeParam) {
            if(!$VAppBackupExcludeParam) {
                try {
                    if($jsonVmFilterInclude) {
                        $VAppBackupExcludeParam = $InputObject | New-CIVAppBackupExcludeParam -jsonVmFilterInclude $jsonVmFilterInclude -BackupExcludeList ($InputObject | Get-CIVAppBackupExcludeList)
                    } else {
                        $VAppBackupExcludeParam = $InputObject | Get-CIVAppBackupExcludeList
                    }
                } catch { Throw }
            }
            $newVAppBackupExcludeParam = $AdhocBackupParams.ImportNode($VAppBackupExcludeParam.VappBackupExcludeList,$true)
            [void]$AdhocBackupParams.AdhocBackupParams.ReplaceChild($newVAppBackupExcludeParam,$AdhocBackupParams.AdhocBackupParams.VappBackupExcludeList)

            #$AdhocBackupParams | Update-CIXmlObject -href "$($InputObject.href)/backups" -httpType "POST" -runAsync:$True
            $content =  Format-CIXml -xml $AdhocBackupParams
        }
        $InputObject | Invoke-AvCDREST -httpType POST -DynamicApiCall "/backups" -Content $content -RunAsync:$RunAsync -NormalResponse 202

    }
}

#Get-CIVApp name | Get-CIVAppBackup
Function Get-CIVAppBackup { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$pageSize=500,$page=1)
    Process {
        $Href = "$($InputObject.href)/backups?pageSize=$($pageSize)&page=$($page)"  
        Write-Verbose $Href
        $InputObject | Invoke-AvCDREST -DynamicApiCall "/backups?pageSize=$($pageSize)&page=$($page)" -NoRecurse:$True #| where {$_} #| Get-CIXmlChildNodes
    }
}

#Get-CIVApp name | Get-CIVAppBackupStat
Function Get-CIVAppBackupStat { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $Href = "$($InputObject.href)/backups/query?type=stats"  
        Write-Verbose $Href
        $vappstats = Get-EmcBackupServiceQuery -href $href -pageSize "" | where {$_} | %{ $_.vappstats }
        if($vappstats) {
            $hashVappStats = @{}
            $vappstats.get_attributes() | %{ $hashVappStats.($_.name) = $_.value }
            New-Object -type psobject -property $hashVappStats |  select *,@{n="name";e={$InputObject.name}},@{n="id";e={$InputObject.id}}
        }
    }
}

#Get-OrgVDc orgvdc1 | Get-BackupRepositoryCIVAppBackup -vappguid ((Get-OrgVDc orgvdc1 | Get-BackupRepository | Get-BackupRepositoryCIVApp -vappname "vapp_system_1b" | select -unique).guid)
#get-orgvdc mgc_vdc1 | Get-BackupRepositoryCIVAppBackup -vappguid ((get-civapp vapp01).id.split(':')[-1])
Function Get-BackupRepositoryCIVAppBackup { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$vappguid)
    Process {
        
        [array]$BackupRepository = $InputObject | Get-CIVAppBackupRepository -vappguid $vappguid
        $BackupRepository | %{
            $_ | Search-BackupRepository -type backup -vappguid $vappguid
        }

    }
}

#get-civapp vapp_system_1 | Get-CIVAppBackup -verbose | select -first 1 | Get-CIVAppBackupDetail
Function Get-CIVAppBackupDetail { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Invoke-AvCDREST
    }
}

#get-civapp vapp_system_1 | Get-CIVAppBackup -verbose | select -first 1 | Get-CIVAppBackupContent -content vappconfigcollection
#get-civapp vapp_system_1 | Get-CIVAppBackup -verbose | select -first 1 | Get-CIVAppBackupContent -content backupmetadatacollection
Function Get-CIVAppBackupVAppContent { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$content=$(throw "missing -content"))
    Process {
        if($InputObject.link) { 
            $Href = "$($InputObject.Href)&content=$($content)"
        } else {
            $Href = "$($InputObject.Href)/$($content)"
        }

        Invoke-AvCDREST -ApiCall $Href -XmlObject:$True
    }
}

#get-orgvdc orgvdc1 | Get-BackupPolicy | select -first 1 | New-BackupPolicyCIVApp -href ((Get-orgvdc orgvdc1 | get-civapp vapp_system_1).href) -verbose

#get-orgvdc orgvdc1 | Get-CIVApp vapp_system_1 | New-CIVAppBackupPolicy -BackupPolicy (Get-Orgvdc orgvdc1 | get-backuppolicy | select -last 1)
Function New-CIVAppBackupPolicy { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$BackupPolicy)
    Process {
        $BackupPolicy | New-BackupPolicyCIVApp -href $InputObject.href
    }
}


#get-orgvdc orgvdc1 | Get-BackupRepositoryRestoreOnly
Function Get-BackupRepositoryRestoreOnly { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Get-BackupRepository | where {$_.cloudidfilter -or $_.orgvdcidfilter -or $_.orgidfilter}
    }
}



#get-orgvdc orgvdc1 | Get-CIVApp vapp_system_1 | New-CIVAppBackupPolicyDefault
Function New-CIVAppBackupPolicyDefault { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject)
    Begin {
        $arrInputObject = @()
    }
    Process {
        $arrInputObject += $InputObject
    }
    End {
        $admin = if($global:DefaultCIServers[0].Org -eq "system") { "admin" } else { "" }
        $strId = ($arrInputObject | %{ "id==$($_.id)" }) -join ","
        [array]$arrGrpVDC =  %{ Search-Cloud -querytype "$($admin)vapp" -Filter $strId } | group vdc 
        $arrGrpVdc | %{
            $grpVdc = $_.group
            $OrgVdc = Get-OrgVdc -id $_.group[0].vdc
            $OrgVdc | Get-OrgVdcCIVAppBackupPolicy | where {!$_.backupPolicyImplicitDefault -and @($grpVdc.id | %{ $_.split(':')[-1]}) -contains $_.id} | %{
                $OrgVdc | New-BackupPolicyDefaultCIVApp -href $_.href
            }
        }
        
    }
}


#get-orgvdc orgvdc1 | Get-CIVApp vapp_system_1 | Get-CIVAppBackupPolicy
Function Get-CIVAppBackupPolicy { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject)
    Begin {
        $arrInputObject = @()
    }
    Process {
        $arrInputObject += $InputObject
    }
    End {
        $admin = if($global:DefaultCIServers[0].Org -eq "system") { "admin" } else { "" }
        $strId = ($arrInputObject | %{ "id==$($_.id)" }) -join ","
        [array]$arrVDC =  %{ Search-Cloud -querytype "$($admin)vapp" -Filter $strId } | group vdc | %{ Get-OrgVdc -id $_.name }
        $arrVDC | Get-OrgVdcCIVAppBackupPolicy | where {$arrInputObject.id -contains "urn:vcloud:vapp:$($_.id)"}
    }
}

#get-orgvdc orgvdc1 | get-orgvdccivappbackuppolicy | ft *
Function Get-OrgVdcCIVAppBackupPolicy { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $OrgVdc = $InputObject
        $admin = if($global:DefaultCIServers[0].Org -eq "system") { "admin" } else { "" }
        $hashVApp = [ordered]@{}
        $adminUrl = if($admin) { $admin+"/" }
        $InputObject | %{ Search-Cloud -querytype "$($admin)vapp" -Filter "vdc==$($_.id)" } | %{ 
            $hashVApp.($_.id.split(':')[-1]) = $_ | select *
            $hashVApp.($_.id.split(':')[-1]).href = "$($global:DefaultCIServers[0].serviceUri.OriginalString)$($adminUrl)vApp/vapp-$($_.id.split(':')[-1])"
        }
        [array]$BackupPolicyDefaultCIVApp = $OrgVdc | Get-BackupPolicyDefaultCIVApp
        $BackupPolicyDefault = $OrgVdc | Get-BackupPolicyDefault
        [array]$arrBackupPolicy = $OrgVdc | Get-BackupPolicy
        $hashBackupPolicy = @{}
        $arrBackupPolicy | %{ $hashBackupPolicy.($_.id) = $_ }
        $hashBackupPolicy = [ordered]@{}
        $arrBackupPolicy | %{ $hashBackupPolicy.($_.id) = $_ }
        $hashBackupPolicyCIVApp = [ordered]@{}
        $arrBackupPolicy | %{ [array]$hashBackupPolicyCIVApp.($_.id) = $_ | Get-BackupPolicyCIVApp }
        $hashVApp.keys | %{
            $VAppId = $_
            $hashOutput = [ordered]@{"Name"= $hashVApp.($_).Name; "Id"= $hashVApp.($_).Id.split(':')[-1];
                                     "BackupPolicyInherited" = .{if($BackupPolicyDefaultCIVApp.id -contains $hashVApp.($_).Id.split(':')[-1]) { $BackupPolicyDefault.Name }};
                                     "BackupPolicyInheritedHref" = .{if($BackupPolicyDefaultCIVApp.id -contains $hashVApp.($_).Id.split(':')[-1]) { $BackupPolicyDefault.Href }};
                                     "BackupPolicyInheritedId" = .{if($BackupPolicyDefaultCIVApp.id -contains $hashVApp.($_).Id.split(':')[-1]) { $BackupPolicyDefault.Id }};
                                     "BackupPolicyEffective" = .{
                                        $hashBackupPolicyCIVApp.keys | %{
                                            $BPCIVApp = $hashBackupPolicyCIVApp.$_
                                            if(@($BPCIVApp.id) -contains $VAppId) {$hashBackupPolicy.($_).Name}
                                        }
                                    };
                                    "BackupPolicyEffectiveHref" = .{
                                        $hashBackupPolicyCIVApp.keys | %{
                                            $BPCIVApp = $hashBackupPolicyCIVApp.$_
                                            if(@($BPCIVApp.id) -contains $VAppId) {$hashBackupPolicy.($_).Href}
                                        }
                                    }
                                    "BackupPolicyEffectiveId" = .{
                                        $hashBackupPolicyCIVApp.keys | %{
                                            $BPCIVApp = $hashBackupPolicyCIVApp.$_
                                            if(@($BPCIVApp.id) -contains $VAppId) {$hashBackupPolicy.($_).Id}
                                        }
                                    }
                                    "Href"= $hashVApp.($_).Href;
                                    
            }

            [pscustomobject]$hashOutput

        }

    }
}


#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | get-civappbackup | select -first 1 | get-civappbackupvappconfigcollection
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | get-civappbackup | select -first 1 | get-civappbackupmetadatacollection
@{"cmdlet"="VAppConfigCollection";"call"="vappconfigcollection"},
@{"cmdlet"="MetadataCollection";"call"="backupmetadatacollection"} | %{
    $execStmt = @"
Function Get-CIVAppBackup$($_.cmdlet) { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=`$False, Position=0, ValueFromPipeline=`$true)]
        [PSObject]`$InputObject)
    Process {
        `$InputObject | Get-CIVAppBackupVAppContent -content $($_.call)
    }
}
"@
    Invoke-Expression $execStmt
}




#get-orgvdc orgvdc1 | Get-CIVAppBackupRepository -vappguid ((get-civapp vapp_system_1).id) -verbose
#get-orgvdc orgvdc1 | Get-CIVAppBackupRepository -vappguid ((get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-BackupRepositoryCIVApp -vappname "vapp_system_1b").id) -verbose
Function Get-CIVAppBackupRepository { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$vappguid=$(throw "missing -vappguid"))
    Process {
        [array]$BackupRepository = $InputObject | Get-BackupRepository
        $BackupRepository | %{ 
            $result = $_ | Search-BackupRepository -type backup -vappguid $vappguid.split(':')[-1]
            if($result) { $_ }
        }
    }
}



#Get-civapp name | Get-CIVAppOrgVdc
Function Get-CIVAppOrgVdc { 
    [CmdletBinding()]    
    Param ([Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $admin = if($global:DefaultCIServers[0].Org -eq "system") { "admin" } else { "" }
        $InputObject | %{ Search-Cloud -querytype "$($admin)vapp" -Filter "id==$($_.id)" -ea stop } | %{ Get-OrgVdc -id $_.vdc }
    }
}


#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-BackupRepositoryCIVApp
#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-BackupRepositoryCIVApp -vappname test11
Function Get-BackupRepositoryCIVApp { 
    [CmdletBinding()]    
    Param ([Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$vappname,$orgguid,$vcloudguid)
    Process {
        $InputObject | Search-BackupRepository -type vapp -vappname $vappname -orgguid $orgguid -vcloudguid $vcloudguid | select name,guid,@{n="id";e={$_.guid}}
    }
}

#get-orgvdc orgvdc1 | Get-BackupRepositoryActive | Get-BackupRepositoryOrgVdc -vdcname orgvdc1
Function Get-BackupRepositoryOrgVdc { 
    [CmdletBinding()]    
    Param ([Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$vdcname,$orgguid,$vcloudguid)
    Process {
        $InputObject | Search-BackupRepository -type vdc -vdcname $vdcname | select name,guid,@{n="id";e={$_.guid}}
    }
}

#get-civapp vapp_system_1 | Get-CIVAppBackup -verbose | Update-CIVAppBackup
Function Update-CIVAppBackup { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$effectiveretention=$(throw "missing -retention in format of 2014-02-19T06:21:31.011Z"),$RunAsync=$False)
    Process {
        Write-Verbose ($InputObject.Href | out-string)
        $CIVAppBackupDetail = $InputObject | Get-CIVAppBackupDetail 
        $CIVAppBackupDetail.effectiveretention = $effectiveretention
        Invoke-AvCDREST -httpType PUT -ApiCall $InputObject.Href -normalResponse 202 -Content $CIVAppBackupDetail.OuterXml -RunAsync:$RunAsync
    }
}


#Get-CIVApp name | Get-CIVAppBackupExcludeList
Function Get-CIVAppBackupExcludeList { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Invoke-AvCDREST -DynamicApiCall "/backupexcludelist" -XmlObject:$True #| %{ $_.DocumentElement.VappBackupExcludeList }
    }
}

#Get-CIVM | Get-CIVMHardDisk
Function Get-CIVMHardDisk { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [psobject]$CIVM)
    Process {
        $hashHW = @{}
        $CIVM.extensiondata.getvirtualhardwaresection().item | %{ $hashHW."$($_.instanceid)" = $_ }
        $CIVM.extensiondata.getvirtualhardwaresection().item | where {$_.elementname -match "hard disk"} | 
            select   @{n="elementName";e={$_.elementName}},
                     @{n="controllerInstanceId";e={$_.parent}},
                     @{n="addressOfParent";e={$hashHW."$($_.parent)".address}}, 
                     @{n="addressOnParent";e={$_.addressonparent}},
                     @{n="diskInstanceId";e={$_.instanceid}} |
                select @{n="href";e={$CIVM.href}},@{n="DiskExclude";e={$_}
            } | group href | select @{n="href";e={$_.group[0].href}},@{n="DiskExclude";e={$_.group.DiskExclude}}
    }
}

#Get-CIVApp name | Get-CIVMCustom
Function Get-CIVMCustom {
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [psobject]$CIVApp)
    Process {
        Invoke-AvCDRest -apiCall $CIVApp.href | %{ $_.Children.Vm }
    }
}

#Get-CIVMCustom | Get-CIVMCustomHardDisk
Function Get-CIVMCustomHardDisk { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [System.Xml.XmlLinkedNode]$CIVM)
    Process {
        $hashHW = @{}
        $CIVM.VirtualHardwareSection.ChildNodes | %{ $hashHW."$($_.instanceid)" = $_ }
        $CIVM.VirtualHardwareSection.ChildNodes | where {$_.elementname -match "hard disk"} | 
            select   @{n="elementName";e={$_.elementName}},
                     @{n="controllerInstanceId";e={$_.parent}},
                     @{n="addressOfParent";e={$hashHW."$($_.parent)".address}}, 
                     @{n="addressOnParent";e={$_.addressonparent}},
                     @{n="diskInstanceId";e={$_.instanceid}} |
                select @{n="href";e={$CIVM.href}},@{n="DiskExclude";e={$_}
            } | group href | select @{n="href";e={$_.group[0].href}},@{n="DiskExclude";e={$_.group.DiskExclude}}
    }
}


#Get-CIVApp | New-CIVAppBackupExcludeParam
#New-CIVAppBackupExcludeParam -BackupExcludeList (Get-orgvdc orgvdc1 | get-civapp vapp_system_1 | get-civappbackupexcludelist)
#Get-CIVApp | New-CIVAppBackupExcludeParam -jsonVmFilterInclude '{}'
#Get-CIVApp | New-CIVAppBackupExcludeParam -jsonVmFilterInclude '{"WebServer1":{"Disk":["2:2000"]}}'
#Get-CIVApp | New-CIVAppBackupExcludeParam -jsonVmFilterInclude '{"WebServer1":null,"WebServer2":null}'
Function New-CIVAppBackupExcludeParam { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$jsonVmFilterInclude,$BackupExcludeList)
    Process {
        if(!$BackupExcludeList) {
            $hashCIVMHrefName = @{}
            $InputObject | Get-CIVMCustom | %{ $hashCIVMHrefName.($_.href) = $_.name }
            [array]$CIVMHardDisk = $InputObject | Get-CIVMCustom | Get-CIVMCustomHardDisk
            $VAppBackupExcludeListParams = New-CIXmlChildNode -type VAppBackupExcludeListParams
      
            $VmExclude = $VAppBackupExcludeListParams.VappBackupExcludeList.VmExclude.clone()
            $DiskExclude = $VmExclude.DiskExclude[0].Clone()

            [array]$newVmExclude = $CIVMHardDisk | %{
                $CIVM = $_
                $VmExclude = $VAppBackupExcludeListParams.VappBackupExcludeList.VmExclude.clone()
                $VmExclude.SetAttribute("href",$CIVM.href)
                [array]$newDiskExclude = $CIVM.DiskExclude | %{
                    $DiskExclude = $VmExclude.DiskExclude[0].Clone()
                    $DiskExclude.SetAttribute("addressofparent",$_.AddressOfParent)
                    $DisKExclude.SetAttribute("diskinstanceid",$_.DiskInstanceId)
                    $VAppBackupExcludeListParams.ImportNode($DiskExclude,$true)
                }
                $VmExclude.DiskExclude | %{ [void]$VmExclude.RemoveChild($_) }
                $newDiskExclude | %{ [void]$VmExclude.AppendChild($_) }
                $VAppBackupExcludeListParams.ImportNode($VmExclude,$true)
            }

            $VAppBackupExcludeListParams.VAppBackupExcludeList.VmExclude | %{ [void]$VAppBackupExcludeListParams.VAppBackupExcludeList.RemoveChild($_) }
            $newVmExclude | %{ [void]$VAppBackupExcludeListParams.VAppBackupExcludeList.AppendChild($_) }
        } else {
            $VAppBackupExcludeListParams = New-CIXmlChildNode -type VAppBackupExcludeListParams
            [void]$VAppBackupExcludeListParams.replaceChild($VAppBackupExcludeListParams.ImportNode($BackupExcludeList,$true),$VAppBackupExcludeListParams.VappBackupExcludeList)
        }
                

        
        if($jsonVmFilterInclude) {
            $VmFilterInclude = $jsonVmFilterInclude | ConvertFrom-Json
            
            $VAppBackupExcludeListParams.vappbackupexcludelist.VmExclude | %{
                $VmExclude=$_
                if($VmFilterInclude.psobject.members.name -notcontains $hashCIVMHrefName.($VmExclude.Href)) {
                    $VmExclude.ExcludeAllDisks = "true"
                } else {
                    $VmExclude.ExcludeAllDisks = "false"
                    [array]$arrIncludeDisk = $VmFilterInclude.($hashCIVMHrefName.($VmExclude.Href)).Disk
                    $VmExclude.DiskExclude | where {$arrIncludeDisk -contains "$($_.addressofparent):$($_.diskinstanceid)"} | %{
                        [void]$VmExclude.RemoveChild($_)
                    }
                        
                }
            }
        }
        $VAppBackupExcludeListParams
    }
}

#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | New-CIVAppBackupExcludeList -jsonVmFilterInclude '{"WebServer1":null,"WebServer2":null}'
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | New-CIVAppBackupExcludeList -jsonVmFilterInclude '{"vapp02":{"Disk":["0:2001"]}}'
Function New-CIVAppBackupExcludeList { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$VAppBackupExcludeListParams,$jsonVmFilterInclude='{}')
    Process {
        $Href = "$($InputObject.href)/backupexcludelist"  
        Write-Verbose $Href
        
        if(!$VAppBackupExcludeListParams) {
            $VAppBackupExcludeListParams = $InputObject | New-CIVAppBackupExcludeParam -jsonVmFilterInclude $jsonVmFilterInclude
        }
        Invoke-AvCDREST -httpType PUT -ApiCall $Href -normalResponse 200 -content $VAppBackupExcludeListParams.OuterXml -xmlObject:$True
    }
}


#Get-BackupAppliance | Get-BackupApplianceActivity
Function Get-BackupApplianceActivity { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Search-BackupAppliance -type activity
    }
}

#Get-BackupAppliance | Get-BackupApplianceState
Function Get-BackupApplianceState { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Search-BackupAppliance -type appliancestate
    }
}


#get-org dpad | Get-OrgVdc orgvdc2 | New-BackupRepositoryRestoreOnly -name orgvdc1-restoreOnly -BackupRepository (get-orgvdc orgvdc1 | get-BackupRepositoryActive) -sourceOrgVdc (Get-orgvdc orgvdc1)
Function New-BackupRepositoryRestoreOnly { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,$Name=$(throw "missing -Name"),$BackupRepository,$SourceOrgVdc)
    Process {
        $targetOrgVdc = $InputObject
        $BackupAppliance = Get-BackupAppliance -id $BackupRepository.BackupApplianceReference.id
        $vcloud = $BackupAppliance | Search-BackupAppliance -type vcloud
        
        $orgVdc = search-cloud -querytype adminorgvdc -filter "id==$(($sourceOrgVdc).id)"
        $orgGuid = $orgVdc.Org
        $targetOrgVdc | New-BackupRepository -name $Name -BackupApplianceReference $BackupRepository.BackupApplianceReference.href -BackupStoreId $BackupRepository.BackupStoreId -CloudIdFilter $vcloud.guid -OrgIdFilter $orgGuid.split(':')[-1] -OrgVdcIdFilter $sourceOrgVdc.id.split(':')[-1] 
    }
}




#Get-OrgVdc orgvdc1 | get-civapp vapp_system_1 | get-civappbackup | select -first 1 | get-civappbackupbackuprepository
Function Get-CIVAppBackupBackupRepository { 
    [CmdletBinding()]    
    Param ([Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        [system.uri]$uriHref = $InputObject.Href
        $seqNum = $uriHref.segments[-1]
        $vappguid = $uriHref.segments[-3] -replace 'vapp-','' -replace '/',''
        try {
            $OrgVdc = @{"Id"=$($vappguid)} | Get-CIVAppOrgVdc -ea stop
        } catch { Write-Host -fore red $_;Throw "Failed to lookup OrgVdc from vappguid $($urihref)" }

        [array]$arrBR = $OrgVdc | Get-BackupRepository | %{ 
            $BackupRepository = $_
            $result = $BackupRepository | Search-BackupRepository -type backup -vappguid $vappguid | where {$_.seqnum -eq $seqnum}
            if($result) { $BackupRepository }
        }

        if($arrBr.count -gt 1) { 
            $returnBA = $arrBr | %{ if($_.backuprepositoryconfigurationsection.IsEnabled) { $_;continue } }
            if(!$returnBA) { $returnBA =  $arrBr | where {$_.backuprepositoryconfigurationsection.IsRestoreAllowed} | %{ return $_ } }
            return $returnBA
        } else { return $arrBr }

    }
}

#Get-BackupRepository | Get-BackupRepositoryActivity
Function Get-BackupRepositoryActivity { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$False, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject)
    Process {
        $InputObject | Search-BackupRepository -type activity
    }
}

#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | Get-CIVAppBackup | Start-CIVAppRestore -OutOfPlace -Name "test1"
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | Get-CIVAppBackup | select -first 1 | Start-CIVAppRestore -OutOfPlace -Name "test13" -runAsync:$false  -restoreowner "false"
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | Get-CIVAppBackup | select -first 1 | Start-CIVAppRestore -OutOfPlace -Name "test13" -runAsync:$false  -restoreowner (get-org dpad | Get-CIUser -name orgadmin)
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | Get-CIVAppBackup | select -first 1 | Start-CIVAppRestore -OutOfPlace -Name "test35" -runAsync:$false  -restoreowner (get-org dpad | Get-CIUser -name orgadmin) -jsonVmFilterInclude '{"WebServer1":{"Disk":["0:2001"]}}'
#get-orgvdc orgvdc1 | get-civapp vapp_system_1 | Get-CIVAppBackup | select -first 1 | Start-CIVAppRestore -Inplace -runAsync:$false
#Get-Orgvdc orgvdc1 | Get-BackupRepositoryCIVAppBackup -vappguid ((Get-OrgVDc orgvdc1 | Get-BackupRepository | Get-BackupRepositoryCIVApp -vappname "vapp_system_1" | select -unique).guid) | select -first 1 | Start-CIVAppRestore -OutOfPlace -Name "test14" -runAsync:$false  -restoreowner "false"
Function Start-CIVAppRestore { 
    [CmdletBinding()]    
    Param (        
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [PSObject]$InputObject,[switch]$OutOfPlace,[switch]$InPlace,$Name,$Description="`"`"",
        $RestoreMetadata="true",$RestoreOwner="true",$RestoreLeaseSettings="true",$jsonVmFilterInclude,
        $runAsync=$False)
    Process {
        if(!$InPlace -and !$OutOfPlace) { Throw "missing -InPlace or -OutOfPlace" }
        Write-Verbose ($InputObject.Href | out-string)
        [system.uri]$uriHref = $InputObject.href
        if($uriHref.localpath -match '/api/admin/extension/EmcBackupService/backupRepository') {
            $BackupRepositoryGuid = $uriHref.segments[6].replace('/','')
            $BackupRepository = Get-BackupRepository -id $BackupRepositoryGuid
            $ResultBackup = $InputObject
        } elseif($OutOfPlace) {
            [system.uri]$uriHref = $InputObject.Href
            $seqNum = $uriHref.segments[-1]
            $vappguid = $uriHref.segments[-3] -replace 'vapp-','urn:vcloud:vapp:' -replace '/',''
            $BackupRepository = Get-CIVApp -id $vappguid | Get-CIVAppOrgVdc | Get-BackupRepositoryActive
            $ResultBackup = $BackupRepository | Search-BackupRepository -type backup -vappguid $vappguid.split(':')[-1] | where {$_.seqnum -eq $seqnum}
        }
        
        $CIVAppBackupDetail = $InputObject | Get-CIVAppBackupDetail
        
        
        if($InPlace) {
            $RestorevAppToOriginalParams = New-CIXmlChildNode -type RestorevAppToOriginalParams
            [void]$RestorevAppToOriginalParams.RestorevAppToOriginalParams.ReplaceChild($RestorevAppToOriginalParams.ImportNode($CIVAppBackupDetail.VmBackupList,$true),$RestorevAppToOriginalParams.RestorevAppToOriginalParams.VmBackupList)
            
            if($jsonVmFilterInclude) { 
                $psVmFilterInclude = $jsonVmFilterInclude | ConvertFrom-Json
                $RestorevAppToOriginalParams.RestorevAppToOriginalParams.VmBackupList.VmBackup | where {$_.include -eq "true" -and $psVmFilterInclude.($_.name)} | %{ 
                    $vm=$_
                    $_.Disk | where {$_.include -eq "true" -and $psVmFilterInclude.($vm.name).Disk -notcontains "$($_.AddressOfParent):$($_.DiskInstanceId)"} | %{
                        $_.include = "false"
                    }
                }

                $RestorevAppToOriginalParams.RestorevAppToOriginalParams.VmBackupList.VmBackup | where {($_.include -eq "true" -and !$psVmFilterInclude.($_.name)) -or $_.status -ne "success" } | %{
                    $_.include = "false"
                }
            }
            try {
                ,@(Invoke-AvCDREST -httpType "POST" -ApiCall $CIVAppBackupDetail.Href -content $RestorevAppToOriginalParams.OuterXml -NormalResponse 202 -runAsync:$runAsync -postTaskLookupCmd "Write-Output") | Tee-Object -Variable arrTask | Out-Null
            } catch {
                Throw $_
            }
        } elseif($OutOfPlace) {
            $VAppConfigCollection = $InputObject | Get-CIVAppBackupVAppConfigCollection
            $RestoreToNewVappParams = New-CIXmlChildNode -type RestoreToNewVappParams
            $RestoreToNewVappParams.RestoreToNewVappParams.Name = $Name
            $RestoreToNewVappParams.RestoreToNewVappParams.Description = $Description
            
            $RestoreToNewVappParams.RestoreToNewVappParams.Source.Href = $ResultBackup.Href.tostring()
            $RestoreToNewVappParams.RestoreToNewVappParams.RestoreMetadata = $RestoreMetadata
            [void]$RestoreToNewVappParams.RestoreToNewVappParams.ReplaceChild($RestoreToNewVappParams.ImportNode($CIVAppBackupDetail.VmBackupList,$true),$RestoreToNewVappParams.RestoreToNewVappParams.VmBackupList)

            if($jsonVmFilterInclude) { 
                $psVmFilterInclude = $jsonVmFilterInclude | ConvertFrom-Json
                $RestoreToNewVappParams.RestoreToNewVappParams.VmBackupList.VmBackup | where {$_.include -eq "true" -and $psVmFilterInclude.($_.name)} | %{ 
                    $vm=$_
                    $_.Disk | where {$_.include -eq "true" -and $psVmFilterInclude.($vm.name).Disk -notcontains "$($_.AddressOfParent):$($_.DiskInstanceId)"} | %{
                        $_.include = "false"
                    }
                }

                $RestoreToNewVappParams.RestoreToNewVappParams.VmBackupList.VmBackup | where {($_.include -eq "true" -and !$psVmFilterInclude.($_.name)) -or $_.status -ne "success" } | %{
                    $_.include = "false"
                }
            }
        
            if($RestoreOwner -eq "true") {
                [void]$RestoreToNewVappParams.RestoreToNewVappParams.ReplaceChild($RestoreToNewVappParams.ImportNode($VAppConfigCollection.Vapp.Owner,$true),$RestoreToNewVappParams.RestoreToNewVappParams.Owner)
            }elseif($RestoreOwner -eq "false") {
                [void]$RestoreToNewVappParams.RestoreToNewVappParams.RemoveChild($RestoreToNewVappParams.RestoreToNewVappParams.Owner)
            }else{
                #$User = $RestoreOwner | %{ Get-CIEdit -href $_.href -skipPrefetch -OutXmlObject } | %{ $_.user }
                $User = $RestoreOwner | %{ Invoke-AvCDREST -ApiCall $_.href -httpType GET -XmlObject:$True } | %{ $_.user }
                $RestoreToNewVappParams.RestoreToNewVappParams.Owner.User.Href = $User.Href
                $RestoreToNewVappParams.RestoreToNewVappParams.Owner.User.Name = $User.Name
            }

            if($RestoreLeaseSettings -eq "true") {
                [void]$RestoreToNewVappParams.RestoreToNewVappParams.ReplaceChild($RestoreToNewVappParams.ImportNode($VAppConfigCollection.Vapp.LeaseSettingsSection,$true),$RestoreToNewVappParams.RestoreToNewVappParams.LeaseSettingsSection)
            } else {
                [void]$RestoreToNewVappParams.RestoreToNewVappParams.RemoveChild($RestoreToNewVappParams.RestoreToNewVappParams.LeaseSettingsSection)
            }   
        
            try {
                ,@(Invoke-AvCDREST -httpType "POST" -ApiCall $BackupRepository.Href -content $RestoreTonewVappParams.OuterXml -NormalResponse 202 -runAsync:$runAsync -postTaskLookupCmd "Write-Output") | Tee-Object -Variable arrTask | Out-Null
            } catch {
                Throw $_
            }
        }

        if($runAsync -eq $False) {
            if($arrTask[-1]) { 
                #$VApp = Get-CIEdit -href $arrTask[-1].result -skipPrefetch -OutXmlObject
                #$VApp = Invoke-AvCDREST -ApiCall $arrTask[-1] -XmlObject:$True -httpType GET
                $VApp = $arrTask[-1].split('/')[-1].replace('vapp-','')
                $CIVApp = Get-CIVApp -id "urn:vcloud:vapp:$($VApp)"
                $CIVApp | %{ $_.ExtensionData.ExitMaintenanceMode() }
            }
#elseif($arrTask[-1].state -eq "error") {
#                Throw "Error encountered"
#            }
        }
    }
}

#(Get-BackupPolicyTemplateCatalog)[1] | New-BackupPolicyTemplate -name test -BackupScheduleRef ((Get-BackupSchedule | select -first 1).href) -BackupRetentionRef ((Get-BackupRetention | select -first 1).href) -BackupOptionSetRef ((Get-BackupOptionSet | select -first 1).href)
