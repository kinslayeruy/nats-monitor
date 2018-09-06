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

#Get-ChildItem *.xml | Select-Object -First 1000 | Compare-RvP -CompareType SonyGPMS-Atlas -ignore $Ignore | ForEach-Object { $_.WriteOut() } | Out-File -FilePath 'compare-errors.log' -Force -Encoding ascii

$toTest = 'TitleMaster_20180312175223_WALKERYS_NEPS_20180312063344_GPMS-25173.xml'
Get-Content $toTest
(Send-Rosetta -template 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr' -hostName localhost:35010 -file $toTest -Verbose).WriteOut()
#(Send-Preparser -inFormat SonyGPMS -outFormat MR -hostName transform-preparser.service.owf-dev -file $toTest -Verbose).WriteOut()
#Compare-RvP -CompareType SonyGPMS-Atlas -ignore $Ignore -File $toTest | ForEach-Object { $_.WriteOut() }

#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults