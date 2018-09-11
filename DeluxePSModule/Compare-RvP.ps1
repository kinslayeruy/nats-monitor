function script:GetObjectValue
{
	[OutputType([string])]
	Param (
		[string]$Path = '',
		[object]$CurrentObject = $null
	)
	Process
	{
		if ($null -eq $CurrentObject)
		{
			return $null
		}
		if ($Path -eq '')
		{
			return $CurrentObject
		}
		$nav = $Path.Split('.')[0]
		if ($nav -eq $Path)
		{
			return $CurrentObject.('{0}' -f $nav)
		}
		return GetObjectValue -Path $Path.Remove(0, $nav.Length + 1) -CurrentObject $CurrentObject.('{0}' -f $nav)
	}
}
function script:Sort-ByPath
{
	Param (
		[string]$Path = '',
		[object]$InputObject = $null
	)
	Process
	{
		if ($null -eq $InputObject)
		{
			return
		}
		if ($Path -eq '' -and $InputObject -is [Array])
		{
			return $InputObject | Sort-Object
		}
		if ($InputObject -is [Array])
		{
			$sorted = @()
			foreach ($item in $InputObject)
			{
				$value = GetObjectValue -Path $Path -CurrentObject $item
				if ($null -eq $value)
				{
					$value = ''
				}
				$sort = [pscustomobject] @{
					SortBy = $value.ToString()
					Value  = $item
				}
				$sorted += $sort
			}
			return $sorted | Sort-Object -Property SortBy | Select-Object -ExpandProperty Value
		}
	}
}

function script:ReplaceWithSortedBy
{
	Param (
		[string]$PathToArray = '',
		[string]$arrayName = '',
		[object]$BaseObject = $null,
		[string]$PathToSortBy = ''
	)
	Process
	{
		$node = GetObjectValue -Path $pathToArray -CurrentObject $BaseObject
		if ($null -ne $node)
		{
			if ($node.PSobject.Properties.Name -contains $arrayName)
			{
				$node.$arrayName = Sort-ByPath -Path $PathToSortBy -InputObject $node.$arrayName
			}
		}
	}
}

function Compare-RvP
{
<#
	.SYNOPSIS
		Compares Rosetta vs Preparser output.
  .DESCRIPTION
		Will send XMLs to Send-Rosetta and Send-Preparser and compare the results.

	.PARAMETER CompareType
		Will define the parameters for both Rosetta tempate and Preparser inFormat and outFormat. Possible values are 'SonyGPMS-MR', 'SonyGPMS-Atlas', 'SonyAlpha-MR', 'SonyAlpha-Atlas'
			'SonyGPMS-MR' 		-> Rosetta: 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr' Preparser: GPMS , MR
			'SonyGPMS-Atlas' 	-> Rosetta: 'json.sony.gpms.canonical-metadata,json.canonical-metadata.atlas' Preparser: GPMS , Atlas
			'SonyAlpha-MR'		-> Rosetta: 'json.sony.atlas.canonical-metadata,json.canonical-metadata.mr' Preparser: Alpha , MR
			'SonyAlpha-Atlas'   -> Rosetta: 'json.sony.atlas.canonical-metadata,json.canonical-metadata.atlas' Preparser: Alpha , Atlas

	.PARAMETER File
		The XML to process, this parameter can be piped in.

	.PARAMETER Sorts
		Additional sortings (in progress).

	.PARAMETER local
		If local is set, the localhost containers are used, if not, the owf-dev services are used for calls.

	.EXAMPLE
		Compare-RvP -CompareType SonyGPMS-MR -File '.\1075.xml'

	.NOTES
		Author: Juan Estrada
#>
	Param (
		[ValidateSet('SonyGPMS-MR', 'SonyGPMS-Atlas', 'SonyAlpha-MR', 'SonyAlpha-Atlas', 'SonyDBB-Atlas')]
		[Parameter(Mandatory)]
		[string]$CompareType,
		[Parameter(ValueFromPipeline, Mandatory)]
		[string]$File,
		[switch]$local,
		[switch]$showResults,
		[string[]]$ignore = $null
	)
	Begin
	{
		switch ($CompareType)
		{
			'SonyGPMS-MR' {
				$rosettaTemplate = 'json.sony.gpms.canonical-metadata,json.canonical-metadata.mr'
				$preparserIn = 'SonyGPMS'
				$preparserOut = 'MR'
				$LangSorts = @('record.country', 'record.language')
				$Sorts = New-Object -TypeName System.Collections.ArrayList
				$echo = $Sorts.Add(@('record.metadata', 'associatedOrg', 'role'))
				$echo = $Sorts.Add(@('record.metadata', 'associatedOrg', 'orgName.sortName'))
				$echo = $Sorts.Add(@('record.metadata', 'releaseHistory', 'description'))
				break
			}
			'SonyGPMS-Atlas' {
				$rosettaTemplate = 'json.sony.gpms.canonical-metadata,json.canonical-metadata.atlas'
				$preparserIn = 'SonyGPMS'
				$preparserOut = 'Atlas'
				$Sorts = New-Object -TypeName System.Collections.ArrayList
				$echo = $Sorts.Add(@('feature', 'references', 'value'))
				$echo = $Sorts.Add(@('feature', 'references', 'type'))
				$echo = $Sorts.Add(@('series', 'references', 'value'))
				$echo = $Sorts.Add(@('series', 'references', 'type'))
				$echo = $Sorts.Add(@('episode', 'references', 'value'))
				$echo = $Sorts.Add(@('episode', 'references', 'type'))
				$echo = $Sorts.Add(@('version', 'references', 'value'))
				$echo = $Sorts.Add(@('version', 'references', 'type'))
				break
			}
			'SonyAlpha-MR' {
				$rosettaTemplate = 'json.sony.alpha.canonical-metadata,json.canonical-metadata.mr'
				$preparserIn = 'SonyAlpha'
				$preparserOut = 'MR'
				break
			}
			'SonyAlpha-Atlas' {
				$rosettaTemplate = 'json.sony.alpha.canonical-metadata,json.canonical-metadata.atlas'
				$preparserIn = 'SonyAlpha'
				$preparserOut = 'Atlas'
				$Sorts = New-Object -TypeName System.Collections.ArrayList
				$echo = $Sorts.Add(@('version', 'references', 'type'))
				break
			}
			'SonyDBB-Atlas' {
				$rosettaTemplate = 'json.sony.dbb.canonical-manifest,json.canonical-manifest.atlas'
				$preparserIn = 'SonyDBB'
				$preparserOut = 'Atlas'
				break
			}
		}
		if ($local)
		{
			$rosettaRoute = 'localhost:5050'
			$preparserRoute = 'localhost:5020'
		}
		else
		{
			$rosettaRoute = 'rosetta-api.service.owf-dev'
			$preparserRoute = 'transform-preparser.service.owf-dev'
		}
		$i = 0
	}
	Process
	{
		
		Write-Verbose -Message 'Calling rosetta'
		[SendResult]$rosetta = (Send-Rosetta -file $File -template $rosettaTemplate -hostName $rosettaRoute -hideProgress)
		Write-Verbose -Message ('Calling preparser')
		[SendResult]$preparser = (Send-Preparser -file $File -inFormat $preparserIn -outFormat $preparserOut -hostName $preparserRoute -hideProgress)
		
		if ($null -ne $LangSorts)
		{
			foreach ($LangSort in $LangSorts)
			{
				ReplaceWithSortedBy -PathToArray '' -arrayName 'Result' -PathToSortBy $LangSort -BaseObject $rosetta
				ReplaceWithSortedBy -PathToArray '' -arrayName 'Result' -PathToSortBy $LangSort -BaseObject $preparser
			}
		}
		
		if ($null -ne $Sorts)
		{
			foreach ($Sort in $Sorts)
			{
				foreach ($rosettaResult in $rosetta.Result)
				{
					ReplaceWithSortedBy -PathToArray $Sort[0] -arrayName $Sort[1] -PathToSortBy $Sort[2] -BaseObject $rosettaResult
				}
				foreach ($preparserResult in $preparser.Result)
				{
					ReplaceWithSortedBy -PathToArray $Sort[0] -arrayName $Sort[1] -PathToSortBy $Sort[2] -BaseObject $preparserResult
				}
			}
		}
		$Name = Split-Path -Path $File -Leaf
		if ($showResults)
		{
			'Rosetta: ['
			$rosetta.Result | ForEach-Object { ConvertTo-Json -Depth 100 -Compress -InputObject $_ }
			']'
			'Preparser: ['
			$preparser.Result | ForEach-Object { ConvertTo-Json -Depth 100 -Compress -InputObject $_ }
			']'
		}
		else
		{
			if ($null -eq $ignore)
			{
				$ignore = @()
			}
			$ignore+= '.Module'
			Compare-ObjectDeep -Name $Name -Base $preparser -Compare $rosetta -Ignore $ignore
		}
		$i++
		Write-Progress -Activity 'Comparing Files' -Status ('{0} files processed' -f $i) -PercentComplete -1
	}
	End
	{
		Write-Host  ('Pocessed {0} files' -f $i) -ForegroundColor Green -BackgroundColor Black
	}
}