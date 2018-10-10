function Send-Rosetta
{
<#
	.SYNOPSIS
		Sends the xmls passed to the Rosetta service.

	.DESCRIPTION
		Will encode and send xmls passed to the Rosetta service.

	.PARAMETER file
		An xml to process, this parameter can be piped in.

	.PARAMETER template
		The template to use in Rosetta.

	.PARAMETER hostName
		The Rosetta hostname to use, by default is localhost:5050.

	.PARAMETER showResults
		Will show the results in the host instead of returning them as objects.

	.PARAMETER compress
		Will compress the results. This parameter will not be taken into account if showResults is not present.

	.PARAMETER writeError
		Writes the errors into an error log file instead of the host.

	.PARAMETER hideProgress
		Hides progress bars.

	.EXAMPLE
		ls *.xml | Send-Rosetta -template 'json.sony.gpms.canonical-metadata' -hostname localhost:5050

	.NOTES
		Author: Juan Estrada
#>
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$file,
		[string]$template,
		[ValidateSet(
				  'SonyGPMSToDCMeToMR'
			    , 'SonyGPMSToDCMeToAtlas'
			    , 'SonyGPMSToDCMe'
			
			    , 'SonyAlphaToDCMeToMR'
			    , 'SonyAlphaToDCMeToAtlas'
			    , 'SonyAlphaToDCMe'
			
			    , 'SonyDBBToDCMaToAtlas'
			    , 'SonyDBBToDCMa'
			
				, 'CanonicalMetadataToDCMeToMR'
			    , 'CanonicalMetadataToDCMeToAtlas'
			    , 'CanonicalMetadataToDCMe'
			   
			    , 'CanonicalManifestToDCMaToAtlas'
			    , 'CanonicalManifestToDCMa'
			
			    , 'RedBeeMediaLGIToDCMeToMR'
			    , 'RedBeeMediaLGIToDCMe'
			
			    , 'RedBeeMediaLGIToDCMaToAtlas'
			    , 'RedBeeMediaLGIToDCMa'
			   
			    , 'ADIToDCMeToMR'
			    , 'ADIToDCMeToAtlas'
			    , 'ADIToDCMe'
			
			    , 'ADIToDCMaToAtlas'
			    , 'ADIToDCMa')]		
		[string]$flow,
		[string]$hostName = 'localhost:5050',
		[switch]$hideProgress
	)
	
	Begin
	{
		if (($null -eq $template) -or ('' -eq $template))
		{
			switch ($flow) {
				'SonyGPMSToDCMeToMR' {
					$template = 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr'
				}
				'SonyGPMSToDCMeToAtlas' {
					$template = 'json.sony.gpms.canonical-metadata,json.canonical-metadata.atlas'
				}
				'SonyGPMSToDCMe' {
					$template = 'json.sony.gpms.canonical-metadata'
				}
				'SonyAlphaToDCMeToMR' {
					$template = 'json.sony.alpha.canonical-metadata,json.canonical-metadata.mr'
				}
				'SonyAlphaToDCMeToAtlas' {
					$template = 'json.sony.alpha.canonical-metadata,json.canonical-metadata.atlas'
				}
				'SonyAlphaToDCMe' {
					$template = 'json.sony.alpha.canonical-metadata'
				}
				'SonyDBBToDCMaToAtlas' {
					$template = 'json.sony.dbb.canonical-manifest,json.canonical-manifest.atlas'
				}
				'SonyDBBToDCMa' {
					$template = 'json.sony.dbb.canonical-manifest'
				}
				'CanonicalMetadataToDCMeToMR' {
					$template = 'json.canonical-metadata.canonical-metadata,json.canonical-metadata.mr'
				}
				'CanonicalMetadataToDCMeToAtlas' {
					$template = 'json.canonical-metadata.canonical-metadata,json.canonical-metadata.atlas'
				}
				'CanonicalMetadataToDCMe' {
					$template = 'json.canonical-metadata.canonical-metadata'
				}
				'CanonicalManifestToDCMaToAtlas' {
					$template = 'json.canonical-manifest.canonical-manifest,json.canonical-manifest.atlas'
				}
				'CanonicalManifestToDCMa' {
					$template = 'json.canonical-manifest.canonical-manifest'
				}
				'RedBeeMediaLGIToDCMeToMR' {
					$template = 'json.red-bee-media.canonical-metadata,json.canonical-metadata.mr'
				}
				'RedBeeMediaLGIToDCMe' {
					$template = 'json.red-bee-media.canonical-metadata'
				}
				'RedBeeMediaLGIToDCMaToAtlas' {
					$template = 'json.red-bee-media.canonical-manifest,json.canonical-manifest.atlas'
				}
				'RedBeeMediaLGIToDCMa' {
					$template = 'json.red-bee-media.canonical-manifest'
				}
				'ADIToDCMeToMR' {
					$template = 'json.adi.canonical-metadata,json.canonical-metadata.mr'
				}
				'ADIToDCMeToAtlas' {
					$template = 'json.adi.canonical-metadata,json.canonical-metadata.atlas'
				}
				'ADIToDCMe' {
					$template = 'json.adi.canonical-metadata'
				}
				'ADIToDCMaToAtlas' {
					$template = 'json.adi.canonical-manifest,json.canonical-manifest.atlas'
				}
				'ADIToDCMa' {
					$template = 'json.adi.canonical-manifest'
				}				
				default {
					throw New-Object -TypeName System.Exception -ArgumentList 'no template'
				}
			}
		}
		$i = 0
		$lastSecond = 0
		$lastIndex = 0
		$perSecond = 0
		$stopWatch = [Diagnostics.Stopwatch]::StartNew()
		$route = 'http://' + $hostName + '/v1/transform'
	}
	Process
	{
		$xml = [IO.File]::ReadAllLines((Resolve-Path -Path $file))
		$name = Split-Path -Path $file -Leaf
		Write-Verbose -Message ('R  - Processing {0}' -f $name)
		$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($xml))
		$json = ('{{ "ingestURN": "{0}", "template": "{1}", "payload": "{2}"}}' -f $name, $template, $encoded)
		$hdrs = @{ 'Content-Type' = 'application/json' }
		
		try
		{
			if ($hideProgress)
			{
				$progressPreference = 'silentlyContinue'
			}
			Write-Verbose -Message ('R  - Calling {0}' -f $route)
			$response = Invoke-RestMethod -Uri $route -Method POST -Headers $hdrs -Body $json -ErrorAction Ignore
			$progressPreference = 'Continue'
			
			if (-Not $response.success)
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, $response.errors, 'Rosetta'
				Write-Output -InputObject $out
				Write-Verbose -Message 'R  - Transformation was NOT successful'
			}
			else
			{
				Write-Verbose -Message 'R  - Transformation was successful'
				$out = New-Object -TypeName SendResult -ArgumentList $name, $true, ($response.transformResults | ConvertFrom-Json), 'Rosetta'
				Write-Output -InputObject $out
				Write-Verbose -Message ('R  - Found {0} results' -f $out.Result.Count)
			}
			
			$i++
			if (-Not $hideProgress)
			{
				$progress = Write-ProgressInner -lastSecond $lastSecond -lastIndex $lastIndex -i $i -perSecond $perSecond -stopwatch $stopWatch -current $name
				$lastSecond = $progress[0]
				$lastIndex = $progress[1]
				$perSecond = $progress[2]
			}
		}
		catch
		{
			Write-Verbose -Message ('R  - Exception calling route {0}' -f $_)
			$exception = $_.Exception.GetBaseException()
			if ($null -ne $_.Exception.Response)
			{
				$result = $_.Exception.Response.GetResponseStream()
				$reader = New-Object -TypeName IO.StreamReader -ArgumentList ($result)
				$reader.BaseStream.Position = 0
				$reader.DiscardBufferedData()
				$responseBody = $reader.ReadToEnd()
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception, $responseBody), 'Rosetta'
			}
			else
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception), 'Rosetta'
			}
			Write-Output -InputObject $out
		}
	}
}