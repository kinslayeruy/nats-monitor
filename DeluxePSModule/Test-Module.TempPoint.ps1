<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	9/3/2018 2:41 PM
	 Created by:   	JEstrada
	 Organization: 	
	 Filename:     	Test-Module.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\SonyGPMS\1 - SER'
$Ignore = @(
	'.Result[0].record.metadata.countryOfOrigin',
	'.Result[0].record.metadata.originalLanguage',
	'.Result[1].record.metadata.countryOfOrigin',
	'.Result[1].record.metadata.originalLanguage'
)
#ls *.xml | Compare-RvP -CompareType SonyGPMS-MR -ignore $Ignore | Format-List

#ls TitleMaster_20180312175308_WALKERYS_SRS_20180312055308_GPMS-50000.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
$toTest = 'TitleMaster_20180312175223_WALKERYS_SRS_20180312061954_GPMS-12508.xml'
cat $toTest
$result = (Send-Rosetta -template 'json.sony.gpms.canonical-metadata' -hostName rosetta-api.service.owf-dev -file $toTest).Result
$result.basicMetadata | ConvertTo-Json

#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults