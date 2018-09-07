<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	9/6/2018 10:48 PM
	 Created by:   	Juan Estrada
	 Organization: 	Endava
	 Filename:     	DockerModule.psm1
	-------------------------------------------------------------------------
	 Module Name: DockerModule
	===========================================================================
#>


function Build-Containers
{
	Param (
		[Parameter(ValueFromPipeline)]
		[string]$Container
	)
	Process
	{
		if ((Get-ChildItem -Filter .mold.yml | Measure-Object).Count -gt 0)
		{
			Write-Verbose ('Running mold for {0}' -f (Split-Path -Path (Get-Location) -Leaf))
		}
		Write-Verbose ('Running mold for {0}' -f $Container)
		Set-Location ('.\{0}' -f $Container)
		Invoke-Command mold 
	}
}

function Start-Containers
{	
	
}

