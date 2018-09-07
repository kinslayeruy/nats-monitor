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
	, '.Result[*].version.status'
)

#Get-ChildItem *.xml | Select-Object -Skip 300 | Compare-RvP -CompareType SonyAlpha-Atlas -ignore $Ignore | ForEach-Object { $_.WriteOut() }

Get-ChildItem *.xml | Select-Object -First 10 | Send-Ingest -Verbose -hostName 'metadata-ingest.service.owf-dev' -ingestType Atlas -providerInputFormat SonyGPMS | ForEach-Object { $_.WriteOut() }

#$toTest = 'Sony_DBB_Asset_Input.xml'
#Get-Content $toTest
#'Preparser Call:'
#(Send-Preparser -inFormat SonyDBB -outFormat Atlas -hostName transform-preparser.service.owf-dev -file $toTest).WriteOut()
#'Rosetta Call:'
#(Send-Rosetta -template 'json.sony.dbb.canonical-manifest,json.canonical-manifest.atlas' -hostName rosetta-api.service.owf-dev -file $toTest).WriteOut()
#'Compare Call:'
#Compare-RvP -CompareType SonyDBB-Atlas -ignore $Ignore -File $toTest | ForEach-Object { $_.WriteOut() }

#Compare-RvP -CompareType SonyGPMS-MR -File $toTest | Format-List
#Compare-RvP -CompareType SonyGPMS-MR -File $toTest -showResults