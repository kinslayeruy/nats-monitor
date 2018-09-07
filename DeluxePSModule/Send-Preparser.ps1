function Send-Preparser
{
  <#
	.SYNOPSIS
		Sends XMLs to Transform-Preparser
	
	.DESCRIPTION
		Will encode the XMLs passed and send them to the service to be processed.
	
	.PARAMETER file
		A file name to be encoded and sent, this parameter can be piped in.
	
	.PARAMETER hostName
		The hostname for transform-preparser. default is localhost:5020.
	
	.PARAMETER outFormat
		The preparser out format (equivalent to diferent route calls) can be a value between 'MR', 'Atlas' or 'Asset'.
	
	.PARAMETER inFormat
		The preparser input format. can be a value between 'GPMS', 'Alpha' or 'DBB'.
		
	.PARAMETER hideProgress
		Hides progress bars.
	
	.EXAMPLE
		ls *.xml | Send-Preparser -inFormat SonyGPMS -outFormat MR -hostName localhost:5020
	
	.NOTES
		Author: Juan Estrada
#>
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$file,
		[string]$hostName = 'localhost:5020',
		[ValidateSet('MR', 'Atlas')]
		[Parameter(Mandatory)]
		[string]$outFormat,
		[ValidateSet('SonyGPMS', 'SonyAlpha', 'SonyDBB')]
		[Parameter(Mandatory)]
		[string]$inFormat,
		[switch]$hideProgress
	)
	Begin
	{
		switch ($outFormat)
		{
			'MR'    {
				$route = ('http://{0}/v1/preparse/oneingest-titleToMR-transform' -f $hostName)
				break
			}
			'Atlas' {
				$route = ('http://{0}/v1/preparse/oneingest-titleToAtlas-transform' -f $hostName)
				break
			}
		}
		switch ($inFormat)
		{
			'SonyGPMS' {
				$route = $route + '?provider=sony&inputFormat=gpms'
				break
			}
			'SonyAlpha' {
				$route = $route + '?provider=sony&inputFormat=alpha'
				break
			}
			'SonyDBB' {
				$route = ('http://{0}/v1/preparse/oneingest-asset-transformations?provider=sony&outputFormat=atlas' -f $hostName)
				break
			}
		}
		Write-Verbose ('Route: {0}' -f $route)
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
		Write-Verbose -Message ('PP - Processing {0}' -f $name)
		$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($xml))
		$json = ('{{ "ingestURN": "{0}", "content": "{1}"}}' -f $name, $encoded)
		$hdrs = @{ 'Content-Type' = 'application/json' }
		
		try
		{
			if ($hideProgress)
			{
				$progressPreference = 'silentlyContinue'
			}
			Write-Verbose -Message ('PP - Calling {0}' -f $route)
			$response = Invoke-RestMethod -Uri $route -Method POST -Headers $hdrs -Body $json -ErrorAction Ignore
			$progressPreference = 'Continue'
			
			if (-Not $response.succeeded)
			{
				$out = New-Object -TypeName SendResult -ArgumentList $name, $false, ($response.results | Select-Object -ExpandProperty errors)
				Write-Output -InputObject $out
				Write-Verbose -Message 'PP - Transformation was NOT successful'
			}
			else
			{
				Write-Verbose -Message 'PP - Transformation was successful'
				if ($inFormat -eq 'SonyDBB')
				{
					$out = New-Object -TypeName SendResult -ArgumentList $name, $true, @(($response.document | ConvertFrom-Json))
				}
				else
				{
					$out = New-Object -TypeName SendResult -ArgumentList $name, $true, ($response.results | Select-Object -ExpandProperty transformation | ConvertFrom-Json)
				}
				Write-Output -InputObject $out
				Write-Verbose -Message ('PP - Found {0} results' -f $out.Result.Count)
			}
			
			$i++
			if (-not $hideProgress)
			{
				$progress = Write-ProgressInner -lastSecond $lastSecond -lastIndex $lastIndex -i $i -perSecond $perSecond -stopwatch $stopWatch
				$lastSecond = $progress[0]
				$lastIndex = $progress[1]
				$perSecond = $progress[2]
			}
			
		}
		catch
		{
			Write-Verbose -Message ('PP - Exception calling route {0}' -f $_)
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