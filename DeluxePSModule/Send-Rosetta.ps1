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
		[Parameter(Mandatory)]
		[string]$template,
		[string]$hostName = 'localhost:5050',
		[switch]$hideProgress
	)
	
	Begin
	{
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
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, $response.errors
				Write-Output -InputObject $out
				Write-Verbose -Message 'R  - Transformation was NOT successful'
			}
			else
			{
				Write-Verbose -Message 'R  - Transformation was successful'
				$out = New-Object -TypeName SendResult -ArgumentList $name, $true, ($response.transformResults | ConvertFrom-Json)
				Write-Output -InputObject $out
				Write-Verbose -Message ('R  - Found {0} results' -f $out.Result.Count)
			}
			
			$i++
			if (-Not $hideProgress)
			{
				$progress = Write-ProgressInner -lastSecond $lastSecond -lastIndex $lastIndex -i $i -perSecond $perSecond -stopwatch $stopWatch
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
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception, $responseBody)
			}
			else
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception)
			}
			Write-Output -InputObject $out
		}
	}
}