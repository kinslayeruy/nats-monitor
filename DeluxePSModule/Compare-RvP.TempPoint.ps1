function GetObjectValue
{
	Param (
		[string]$Path,
		[object]$CurrentObject
	)
	Process
	{
		$nav = $Path.Split('.')[0]
		if ($nav -eq $Path)
		{
			return $CurrentObject."$nav"
		}
		return GetObjectValue -Path $Path.Remove(0, $nav.Length + 1) -CurrentObject $CurrentObject."$nav"
	}
}
function Sort-ByPath
{
	Param (
		[string]$Path = '',
		[object]$InputObject = $null
	)
	Process
	{
		if ($null -eq $InputObject)
		{
			return;
		}
		if ($Path -eq '' -and $InputObject -is [Array])
		{
			return $InputObject | Sort-Object
		}
		if ($InputObject -is [Array])
		{
			$sorted = @()
			foreach ($item in $InputObject) {
				$sort = [pscustomobject] @{
					SortBy = GetObjectValue -Path $Path -CurrentObject $item
					Value = $item
				}
				$sorted += $sort
			}
			return $sorted | Sort-Object -Property SortBy | Select-Object -ExpandProperty Value
		}
	}
}

function ReplaceWithSortedBy
{
	Param (
		[string]$PathToArray = '',
		[string]$arrayName = '',
		[object]$BaseObject = $null,
		[string]$PathToSortBy = ''
	)
	Process
	{
		$node = GetObjectValue -Path $pathToArray -CurrentObject $BaseObject;
		$node.$arrayName = Sort-ByPath -Path $PathToSortBy -InputObject $node.$arrayName
	}
}

#$test = @{
#	Route = @{
#		ArrayDec = @([pscustomobject]@{
#				Test = [pscustomobject]@{
#					Inner = @('hola', 'aa')
#					BySort = 'z'
#				}
#				Another = 2
#			}, [pscustomobject]@{
#				Test = [pscustomobject]@{
#					Inner = @('hola', 'aa')
#					BySort = 'b'
#				}
#				Another = 2
#			})
#	}
#}
#$test.Route.ArrayDec | Select-Object Test
#ReplaceWithSortedBy -PathToArray 'Route' -arrayName 'ArrayDec' -BaseObject $test -PathToSortBy 'Test.BySort'
#$test.Route.ArrayDec | Select-Object Test

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
function Compare-RvP
{
	Param (
		[ValidateSet('SonyGPMS-MR', 'SonyGPMS-Atlas', 'SonyAlpha-MR', 'SonyAlpha-Atlas')]
		[Parameter(Mandatory)]
		[string]$CompareType,
		[Parameter(ValueFromPipeline, Mandatory)]
		[string]$File,
		[string[][]]$Sorts = $null,
		[switch]$local
	)
	Begin
	{
		switch ($CompareType)
		{
			"SonyGPMS-MR" {
				$rosettaTemplate = "json.sony.gpms.canonical-metadata,json.canonical-metadata.mr"
				$preparserIn = "SonyGPMS"
				$preparserOut = "MR"
				break
			}
			"SonyGPMS-Atlas" {
				$rosettaTemplate = "json.sony.gpms.canonical-metadata,json.canonical-metadata.atlas"
				$preparserIn = "SonyGPMS"
				$preparserOut = "Atlas"
				break
			}
			"SonyAlpha-MR" {
				$rosettaTemplate = "json.sony.alpha.canonical-metadata,json.canonical-metadata.mr"
				$preparserIn = "SonyAlpha"
				$preparserOut = "MR"
				break
			}
			"SonyAlpha-Atlas" {
				$rosettaTemplate = "json.sony.alpha.canonical-metadata,json.canonical-metadata.atlas"
				$preparserIn = "SonyAlpha"
				$preparserOut = "Atlas"
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
		
		$rosetta = (Send-Rosetta -file $File -template $rosettaTemplate -hostName $rosettaRoute -hideProgress)
		
		$preparser = (Send-Preparser -file $File -inFormat $preparserIn -outFormat $preparserOut -hostName $preparserRoute -hideProgress)
		if ($null -ne $Sorts)
		{
			foreach ($Sort in $Sorts)
			{
				ReplaceWithSortedBy -PathToArray $Sort[0] -arrayName $Sort[1] -PathToSortBy $Sort[2] -BaseObject $rosetta
				ReplaceWithSortedBy -PathToArray $Sort[0] -arrayName $Sort[1] -PathToSortBy $Sort[2] -BaseObject $preparser
			}
		}
		$Name = Split-Path -Path $File -Leaf
		Compare-ObjectDeep -Name $Name -Base $preparser -Compare $rosetta
		$i++
		Write-Progress -Activity 'Comparing Files' -Status "$i files processed" -PercentComplete -1
	}
}