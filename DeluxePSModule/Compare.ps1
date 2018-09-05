function Get-HashFromObject
{
	Param
	(
		[object]$obj
	)
	Process
	{
		$objProps = Get-Member -InputObject $obj -MemberType Properties -ErrorAction Ignore
		$objHash = @{ }
		foreach ($prop in ($objProps | Sort-Object -Property Name))
		{
			$objHash.Add($prop.Name, ($obj."$($prop.Name)"))
		}
		return $objHash
	}
}

function Compare-String
{
	param (
		[String]$string1,
		[String]$string2
	)
	if ($string1 -eq $string2)
	{
		return -1
	}
	$diffIndex = -1
	for ($i = 0; $i -lt $string1.Length; $i++)
	{
		if ($string1[$i] -ne $string2[$i])
		{
			$diffIndex = $i
			$i = $string1.Length + 1
		}
	}
	if ($diffIndex -lt 0)
	{
		$diffIndex = $string1.Length
	}
	if ($diffIndex -gt 6)
	{
		$cutIndex = $diffIndex - 3
		$baseDiff = '...'
		$compareDiff = '...'
	}
	else
	{
		$cutIndex = 0
		$baseDiff = ''
		$compareDiff = ''
	}
	
	$baseDiff += ([String]$string1).Substring($cutIndex);
	if ($baseDiff.Length -gt 15)
	{
		$baseDiff = $baseDiff.Substring(0, 15)
	}
	$compareDiff += ([String]$string2).Substring($cutIndex);
	if ($compareDiff.Length -gt 15)
	{
		$compareDiff = $compareDiff.Substring(0, 15)
	}
	
	return ($diffIndex, $baseDiff, $compareDiff)
}

function Compare-Arrays
{
	Param (
		[Parameter(Mandatory)]
		[string]$Name,
		[string]$Path = '',
		[Object[]]$Base = $null,
		[Object[]]$Compare = $null,
		[string[]]$Ignore = $null
	)
	Process
	{
		Write-Verbose "Array     $Name $Path"
		
		if ($Base.Count -ne $Compare.Count)
		{
			if ($Ignore -notcontains $Path)
			{
				Write-Output (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Base and Compare array count differ ({0} != {1})' -f $Base.Count, $Compare.Count))
			}
			return;
		}
		$BaseSorted = $Base | Sort-Object
		$CompareSorted = $Compare | Sort-Object
		for ($i = 0; $i -lt $Base.Count; $i++)
		{
			Compare-ObjectDeep -Name $Name -Path "$Path[$i]" -Base $Base[$i] -Compare $Compare[$i] -Ignore $Ignore
		}
	}
}

function Compare-HashTable
{
	Param
	(
		[Parameter(Mandatory)]
		[string]$Name,
		[string]$Path = '',
		[HashTable]$Base = $null,
		[HashTable]$Compare = $null,
		[string[]]$Ignore = $null
	)
	Write-Verbose "Hashtable $Name $Path"
	$keys = @()
	$keys += $Base.Keys
	$keys += $Compare.Keys
	$keys = $keys | Sort-Object -Unique
	
	for ($i = 0; $i -lt $keys.Count; $i++)
	{
		$key = $keys[$i]
		Compare-ObjectDeep -Name $Name -Path ('{0}.{1}' -f $Path, $key) -Base $Base."$key" -Compare $Compare."$key" -Ignore $Ignore
	}
}

function Compare-ObjectDeep
{
	Param
	(
		[Parameter(Mandatory)]
		[string]$Name,
		[string]$Path = '',
		[Object]$Base = $null,
		[Object]$Compare = $null,
		[string[]]$Ignore = $null
	)
	Process
	{
		Write-Verbose "Object   $Name $Path"
		if (($null -eq $Base) -xor ($null -eq $Compare))
		{
			if ($null -eq $Base)
			{
				if ($Compare -is [string] -and $Compare -eq '')
				{
					return
				}
				if ($Compare -is [Array] -and ([Array]$Compare).Length -eq 0)
				{
					return
				}
				if ($Ignore -notcontains $Path)
				{
					Write-Output -InputObject (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Base object is null (null != {0})' -f $Compare))
				}
				return
			}
			if ($Base -is [string] -and $Base -eq '')
			{
				return
			}
			if ($Base -is [Array] -and ([Array]$Base).Length -eq 0)
			{
				return
			}
			if ($Ignore -notcontains $Path)
			{
				Write-Output -InputObject (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Compare object is null ({0} != null)' -f $Base))
			}
			return
		}
		
		if (($null -eq $Base) -and ($null -eq $Compare))
		{
			return
		}
		
		if ($Base.GetType().FullName -ne $Compare.GetType().FullName)
		{
			if ($Ignore -notcontains $Path)
			{
				Write-Output (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Base and Compare object types are different ({0} != {1})' -f $Base.GetType().FullName, $Compare.GetType().FullName))
			}
			return
		}
		
		if ($Base.GetType().IsArray)
		{
			Compare-Arrays -Name $Name -Path $Path -Base $Base -Compare $Compare -Ignore $Ignore
			return
		}
		
		if ($Base -is [String])
		{
			$diffIndex = Compare-String $Base $Compare
			if ($diffIndex[0] -ge 0)
			{
				if ($Ignore -notcontains $Path)
				{
					Write-Output (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Base and Compare are not equal starting at index {0} (''{1}'' != ''{2}'')' -f $diffIndex[0], $diffIndex[1], $diffIndex[2]))
				}
			}
			return
		}
		
		if ($Base.GetType().IsPrimitive)
		{
			if ($Base -ne $Compare)
			{
				if ($Ignore -notcontains $Path)
				{
					Write-Output (New-Object -TypeName CompareError -ArgumentList $Name, $Path, ('Base and Compare are not equal ({0} != {1})' -f $Base, $Compare))
				}
				return
			}
			return
		}
		
		if ($Base -isnot [Hashtable])
		{
			#an object!
			[hashtable]$baseHash = Get-HashFromObject -obj $Base
			[hashtable]$compareHash = Get-HashFromObject -obj $Compare
		}
		else
		{
			[hashtable]$baseHash = $Base
			[hashtable]$compareHash = $Compare
		}
		Compare-HashTable -Name $Name -Path $Path -Base $baseHash -Compare $compareHash -Ignore $Ignore
	}
}



#$props1 = [pscustomobject]@{
#	Test = 'test'
#	another = 'another test'
#	aNumber = 3
#}
#
#$props2 = @{ }
#$props2.Test = 'test'
#$props2.another = 'another test'
#$props2.aNumber = 4
#
#Compare-ObjectDeep -Name 'test' -Path 'pepe' -Base ($props1) -Compare (New-Object -TypeName PSObject -Property $props2)
