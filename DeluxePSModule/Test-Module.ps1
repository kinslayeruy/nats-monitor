<#	
	.NOTES
	 Author:   	Juan Estrada

	.DESCRIPTION
		A test for the module.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\rosetta'
$Ignore = @(
		'.Result[*].record.metadata.countryOfOrigin'
	# , '.Result[*].record.metadata.originalLanguage'
	 , '.Result[*].version.status'
	# , '.Result[*].record.platform'
	, '.Result[*].feature.studios'
)

Send-Rosetta -file .\1075.xml -hostName rosetta-api.service.owf-dev -flow SonyGPMSToDCMe -Verbose | ForEach-Object { $_.WriteOut() }
#Get-ChildItem *.xml | Send-Rosetta -template 'json.canonical-metadata.canonical-metadata' -hostname localhost:35010 | ForEach-Object { $_.WriteOut() }
#Get-ChildItem *v5.xml | Send-Ingest -ingestType Full -providerInputFormat CanonicalMetadata -hostName localhost:5003 | ForEach-Object { $_.WriteOut() }

#Get-ChildItem *.xml | Select-Object -first 100 | Send-Ingest -ingestType Full -providerInputFormat SonyGPMS -hostName metadata-ingest.service.owf-dev | ForEach-Object { $_.WriteOut() }
#Get-ChildItem *.xml -Recurse | Select-Object -Skip 300 | Compare-RvP -CompareType SonyGPMS-MR -ignore $Ignore | ForEach-Object { $_.WriteOut() }
#Get-ChildItem *.xml -Recurse | Send-Ingest -ingestType Full -hostName localhost:5003 -providerInputFormat SonyGPMS -force | ForEach-Object { $_.WriteOutWithActionHightlight() }
#Get-ChildItem *.xml | Select-Object -First 10 | Send-Ingest -Verbose -hostName 'metadata-ingest.service.owf-dev' -ingestType Atlas -providerInputFormat SonyGPMS | ForEach-Object { $_.WriteOut() }

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