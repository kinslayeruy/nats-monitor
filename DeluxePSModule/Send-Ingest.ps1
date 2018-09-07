<#	
	.NOTES
		Author:   	Juan Estrada
	.DESCRIPTION
		A description of the file.
#>

function SendPayload([string]$route, [string]$providerInputFormat, [object]$payload, [string]$module)
{
	$json = ('{{"ingestURN": "{0}", "providerInputFormat": "{1}", "data":"{2}"}}' -f $name, $providerInputFormat, $encoded)
	$hdrs = @{ 'Content-Type' = 'application/json' }
	$progressPreference = 'silentlyContinue'
	try
	{
		Write-Verbose -Message ('MI - {1} Calling {0}' -f $route, $module)
		$response = Invoke-RestMethod -Uri $route -Method POST -Headers $hdrs -Body $json -ErrorAction Ignore
		$progressPreference = 'Continue'
		
		if ($response.overallStatus -eq 'Failure')
		{
			$out = New-Object -TypeName SendResult -ArgumentList $name, $false, ($response.payloadResults | Select-Object -Property failureReason, errorObject), $module
			Write-Output -InputObject $out
			Write-Verbose -Message ('MI - {0} Ingest was NOT successful' -f $module)
		}
		else
		{
			Write-Verbose -Message ('MI - {0} Ingest was successful' -f $module)
			$out = New-Object -TypeName SendResult -ArgumentList $name, $true, ($response.payloadResults | Select-Object -Property metadataRepositoryURN, atlasURNs, action), $module
			Write-Output -InputObject $out
			Write-Verbose -Message ('MI - {1} Found {0} results' -f $out.Result.Count, $module)
		}
	}
	catch
	{
		Write-Verbose -Message ('MI - {1} Exception calling route {0}' -f $_, $module)
		$exception = $_.Exception.GetBaseException()
		if ($null -ne $_.Exception.Response)
		{
			$result = $_.Exception.Response.GetResponseStream()
			$reader = New-Object -TypeName IO.StreamReader -ArgumentList ($result)
			$reader.BaseStream.Position = 0
			$reader.DiscardBufferedData()
			$responseBody = $reader.ReadToEnd()
			$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception, $responseBody), $module
		}
		else
		{
			$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception), $module
		}
		Write-Output -InputObject $out
	}
}

function Send-Ingest
{
	[OutputType([SendResult])]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$file,
		[string]$hostName = 'localhost:5001',
		[ValidateSet('MR', 'Atlas', 'Full')]
		[Parameter(Mandatory)]
		[string]$ingestType,
		[ValidateSet('SonyGPMS', 'SonyAlpha')]
		[Parameter(Mandatory)]
		[string]$providerInputFormat
	)
	Begin
	{
		$mrRoute = ('http://{0}/v1/ingest/metadata' -f $hostName)
		$atlasRoute = ('http://{0}/v1/ingest/atlas' -f $hostName)
		$linkRoute = ('http://{0}/v1/ingest/link' -f $hostName)
		$i = 0
		$lastSecond = 0
		$lastIndex = 0
		$perSecond = 0
		$stopWatch = [Diagnostics.Stopwatch]::StartNew()
	}
	Process
	{
		$xml = [IO.File]::ReadAllLines((Resolve-Path -Path $file))
		$name = Split-Path -Path $file -Leaf
		Write-Verbose -Message ('MI - Processing {0}' -f $name)
		$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($xml))
		switch ($ingestType) {
			'MR' {
				SendPayload -route $mrRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'MR   '
			}
			'Atlas' {
				SendPayload -route $atlasRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'Atlas'
			}
			'Full' {
				$mr = SendPayload -route $mrRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'MR   '
				$atlas = SendPayload -route $atlasRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'Atlas'
				$mr				
				$atlas
			}
		}
		
		$i++
		$progress = Write-ProgressInner -lastSecond $lastSecond -lastIndex $lastIndex -i $i -perSecond $perSecond -stopwatch $stopWatch -current $name
		$lastSecond = $progress[0]
		$lastIndex = $progress[1]
		$perSecond = $progress[2]
	}	
}


