<#	
	.NOTES
	 Author:   	Juan Estrada

	.DESCRIPTION
		A test for the module.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\SonyGPMS\2 - SEA'
$Ignore = @(
	'.Result[0].record.metadata.countryOfOrigin',
	'.Result[0].record.metadata.originalLanguage',
	'.Result[1].record.metadata.countryOfOrigin',
	'.Result[1].record.metadata.originalLanguage'
)
ls *.xml | Compare-RvP -CompareType SonyGPMS-MR -ignore $Ignore | ForEach-Object { $_.WriteOut()}
#ls *.xml | Send-Rosetta -template 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr' -hostName rosetta-api.service.owf-dev
#ls TitleMaster_20180312175308_WALKERYS_SRS_20180312055308_GPMS-50000.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
#$toTest = 'TitleMaster_20180312175223_WALKERYS_SEA_20180312061113_GPMS-5360.xml'
#cat $toTest
#(Send-Rosetta -template 'json.sony.gpms.canonical-metadata' -hostName rosetta-api.service.owf-dev -file $toTest -Verbose).WriteOut()
#(Send-Preparser -inFormat SonyGPMS -outFormat MR -hostName transform-preparser.service.owf-dev -file $toTest -Verbose).WriteOut()


#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults