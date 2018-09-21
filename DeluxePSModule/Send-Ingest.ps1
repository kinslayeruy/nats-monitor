<#	
	.NOTES
		Author:   	Juan Estrada
	.DESCRIPTION
		A description of the file.
#>


function SendPayload([string]$route, [string]$providerInputFormat, [object]$payload, [string]$module, [string]$name)
{
	[OutputType([SendResult])]
	
	$json = ('{{"ingestURN": "{0}", "providerInputFormat": "{1}", "data":"{2}"}}' -f $name, $providerInputFormat, $payload)
	$hdrs = @{ 'Content-Type' = 'application/json' }
	$progressPreference = 'silentlyContinue'
	try
	{
		Write-Verbose -Message ('MI - {1} Calling {0}' -f $route, $module)
		$response = Invoke-RestMethod -Uri $route -Method POST -Headers $hdrs -Body $json -ErrorAction Ignore
		$progressPreference = 'Continue'
		
		if ($response.overallStatus -eq 'Failure')
		{
			$errors = New-Object System.Collections.ArrayList
			
			foreach ($payload in $response.payloadResults) {
				$echo = $errors.Add($payload.failureReason)
				$errorMessages = @($payload.transformationDetails | Select-Object -expand errors)
				if ($null -ne $errorMessages)
				{
					$errors.AddRange($errorMessages)
				}
				$errorObjects = $payload.errorObject | Select-Object result | ConvertTo-Json -Depth 3 -Compress
				if ($null -ne $errorObjects)
				{
					$echo = $errors.Add($errorObjects)
				}				
			}
			$out = New-Object -TypeName SendResult -ArgumentList $name, $false, $errors, $module
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
		return $out
	}
}

function Link([string]$route, [string]$name, [SendResult]$mr, [SendResult]$atlas)
{
	#[OutputType([SendResult])]
	
	foreach ($mrResult in $mr.Result) {
		$json = ('{{"ingestURN": "{0}", "metadataRepositoryId": "{1}", "atlasIds":{2}}}' -f $name, $mrResult.metadataRepositoryURN, ($atlas.Result[0].atlasURNs | ConvertTo-Json -Depth 2))
		$hdrs = @{ 'Content-Type' = 'application/json' }
		$progressPreference = 'silentlyContinue'
		try
		{
			Write-Verbose -Message ('MI - Link  Calling {0}' -f $route)
			$response = Invoke-WebRequest -Uri $route -Method POST -Headers $hdrs -Body $json -ErrorAction Ignore
			$progressPreference = 'Continue'
			if ($response.StatusCode -eq 200)
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $true, @(), 'Link '
			}
			else
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @(), 'Link '
			}
			return $out
		}
		catch
		{
			Write-Verbose -Message ('MI - Link  Exception calling route {0}' -f $_)
			$exception = $_.Exception.GetBaseException()
			if ($null -ne $_.Exception.Response)
			{
				$result = $_.Exception.Response.GetResponseStream()
				$reader = New-Object -TypeName IO.StreamReader -ArgumentList ($result)
				$reader.BaseStream.Position = 0
				$reader.DiscardBufferedData()
				$responseBody = $reader.ReadToEnd()
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception, $responseBody), 'Link '
			}
			else
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, @($exception), 'Link '
			}
			return $out
		}
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
		[ValidateSet('SonyGPMS', 'SonyAlpha', 'CanonicalMetadata')]
		[Parameter(Mandatory)]
		[string]$providerInputFormat,
		[switch]$force
	)
	Begin
	{
		$mrRoute = ('http://{0}/v1/ingest/metadata?Verbosity=HideBoth' -f $hostName)
		$atlasRoute = ('http://{0}/v1/ingest/atlas?Verbosity=HideBoth' -f $hostName)
		if ($force)
		{
			$mrRoute += '&force=true'
			$atlasRoute += '&force=true'
		}
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
				SendPayload -route $mrRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'MR   ' -name $name
			}
			'Atlas' {
				SendPayload -route $atlasRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'Atlas' -name $name
			}
			'Full' {
				[SendResult]$mr = SendPayload -route $mrRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'MR   ' -name $name
				[SendResult]$atlas = SendPayload -route $atlasRoute -providerInputFormat $providerInputFormat -payload $encoded -module 'Atlas' -name $name
				
				Write-Output $mr
				Write-Output $atlas
				if ($mr.Success -and $atlas.Success)
				{
					[SendResult]$link = Link -route $linkRoute -name $name -mr $mr -atlas $atlas
					Write-Output $link
				}
			}
		}
		
		$i++
		$progress = Write-ProgressInner -lastSecond $lastSecond -lastIndex $lastIndex -i $i -perSecond $perSecond -stopwatch $stopWatch -current $name
		$lastSecond = $progress[0]
		$lastIndex = $progress[1]
		$perSecond = $progress[2]
	}	
}


