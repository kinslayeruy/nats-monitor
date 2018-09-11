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
	[string]$Module
	
	# Constructors
	SendResult ([string]$name, [bool]$success, [Array]$result, [string]$module)
	{
		$this.Name = $name
		$this.Success = $success
		$this.Result = $result
		$this.Module = $module
	}
	
	WriteIfError()
	{
		if (-not $this.Success)
		{
			$this.WriteOut()
		}
		else
		{
			$this.WriteStatus()
		}
	}
	
	WriteStatus()
	{
		Write-Host -NoNewline "$($this.Module)" -ForegroundColor Cyan
		Write-Host -NoNewline ' -'
		Write-Host -NoNewline " $($this.Name)" -ForegroundColor Cyan
		Write-Host -NoNewline ' returned '
		if ($this.Success)
		{
			Write-Host ' Success' -ForegroundColor Green
		}
		else
		{
			Write-Host ' Failure' -ForegroundColor Red
		}
	}
	
	#Methods	
	WriteOut()
	{
		$this.WriteStatus()
		foreach ($item in $this.Result)
		{
			if ($item -is [string])
			{
				Write-Host "`t$item"
			}
			elseif ($this.Success)
			{
				Write-Host "`t$(ConvertTo-Json -InputObject $item -Depth 10 -Compress)"
			}
			else
			{
				Write-Host "`t$(ConvertTo-Json -InputObject $item -Depth 1 -Compress)"
			}
		}
		Write-Host ' '
	}
}

