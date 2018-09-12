﻿<#	
	.NOTES
	 Author:   	Juan Estrada
	 
	.DESCRIPTION
		Helper Methods.
#>

Function IgnoreMatches([string[]]$ignoreArray, [string]$key)
{
	$key = $key -replace '(\[[\d]*\])', '[*]'
	return $ignoreArray -notcontains $key
}

Function IIf($If, $Right, $Wrong)
{
	If ($If)
	{
		$Right
	}
	Else
	{
		$Wrong
	}
}

function Write-ErrorInner
{
	Param (
		[bool]$ToFile = $false,
		[string]$ErrorToWrite = '',
		[Parameter(Mandatory)]
		[string]$OutputFile
	)
	if ($ToFile)
	{
		Out-File -FilePath $OutputFile -Append -InputObject $ErrorToWrite
	}
	else
	{
		$ErrorToWrite
	}
}

function Write-ProgressInner
{
	param
	(
		[Parameter(Mandatory)]
		[int]$lastSecond,
		[Parameter(Mandatory)]
		[int]$lastIndex,
		[Parameter(Mandatory)]
		[int]$i,
		[Parameter(Mandatory)]
		[int]$perSecond,
		[Parameter(Mandatory)]
		[Diagnostics.Stopwatch]$stopWatch,
		[switch]$hideProgress,
		[string]$current
	)
	
	$newSecond = $stopWatch.Elapsed.Seconds
	if ($newSecond -gt $lastSecond)
	{
		$perSecond = $i - $lastIndex
	}
	
	if (-Not $hideProgress)
	{
		if ($null -ne $current)
		{
			Write-Progress -Activity 'Sending xmls' -Status ('Processing at {0}/s ({1} sent total)' -f $perSecond, $i) -CurrentOperation ('Sent {0}' -f $current)
		}
		else
		{
			
		}
	}
	if ($newSecond -gt $lastSecond)
	{
		return $newSecond, $i, $perSecond
	}
	return $lastSecond, $lastIndex, $perSecond
}
