<#	
	.NOTES
	 Author:   	Juan Estrada

	.DESCRIPTION
		A test for the module.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\SonyGPMS\1 - SER'
$Ignore = @(
	  '.Result[*].record.metadata.countryOfOrigin'
	, '.Result[*].record.metadata.originalLanguage'	
)
Get-ChildItem *.xml | Select-Object -First 1 -Skip 100 | Compare-RvP -CompareType SonyGPMS-MR -ignore $Ignore | ForEach-Object { $_.WriteOut() }
#ls *.xml | Send-Rosetta -template 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr' -hostName rosetta-api.service.owf-dev
#ls TitleMaster_20180312175308_WALKERYS_SRS_20180312055308_GPMS-50000.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
#$toTest = 'TitleMaster_20180312175308_WALKERYS_SRS_20180312055315_GPMS-50110.xml'
#cat $toTest
#(Send-Rosetta -template 'json.sony.gpms.canonical-metadata' -hostName rosetta-api.service.owf-dev -file $toTest -Verbose).WriteOut()
#(Send-Preparser -inFormat SonyGPMS -outFormat MR -hostName transform-preparser.service.owf-dev -file $toTest -Verbose).WriteOut()


#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults