<#	
	.NOTES
	 Author:   	Juan Estrada

	.DESCRIPTION
		A test for the module.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\LoadTests'
$Ignore = @(
	  '.Result[*].record.metadata.countryOfOrigin'
	, '.Result[*].record.metadata.originalLanguage'
)

#Get-ChildItem *.xml | Compare-RvP -CompareType SonyGPMS-Atlas -ignore $Ignore | ForEach-Object { $_.WriteOut() }
$toTest = 'TitleMaster_20180312175223_WALKERYS_SRS_20180312064822_GPMS-36775.xml'
#Get-Content $toTest
(Send-Rosetta -template 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr' -hostName rosetta-api.service.owf-dev -file $toTest -Verbose).WriteOut()
(Send-Preparser -inFormat SonyGPMS -outFormat MR -hostName transform-preparser.service.owf-dev -file $toTest -Verbose).WriteOut()
Compare-RvP -CompareType SonyGPMS-Atlas -ignore $Ignore -File $toTest | ForEach-Object { $_.WriteOut() }

#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults