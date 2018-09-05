<#	
	.NOTES
	 Author:   	Juan Estrada
	 
	.DESCRIPTION
		Helper Classes.
#>

class CompareError
{
	
	# Properties
	[string]$Name
	[string]$Path
	[string]$Message
	
	# Constructors
	CompareError ([string]$name, [string]$path, [string]$message)
	{
		$this.Name = $name
		$this.Message = $message
		$this.Path = $path
	}
	
	
	#Methods
	
	[string]WriteOut()
	{
		return ('{0} @ {1}, {2}' -f $this.Name, $this.Path, $this.Message)
	}
}

class SendResult
{
	# Properties
	[string]$Name
	[bool]$Success
	[Array]$Result
	
	# Constructors
	SendResult ([string]$name, [bool]$success, [Array]$result)
	{
		$this.Name = $name
		$this.Success = $success
		$this.Result = $result
	}
	
	
	#Methods	
	[string]WriteOut()
	{
		$ret = New-Object -TypeName System.Collections.ArrayList
		$ret.Add("$($this.Name) status $(IIF $this.Success 'Success' 'Failure')`r`n")
		
		foreach ($item in $this.Result)
		{
			if ($item -is [string])
			{
				$ret.Add("`t$item`r`n")
			}
			else
			{
				$ret.Add("`t$(ConvertTo-Json -InputObject $item -Depth 100 -Compress)`r`n")
			}
		}
		
		return $ret
	}
}

