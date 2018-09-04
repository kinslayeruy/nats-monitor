<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	9/3/2018 2:41 PM
	 Created by:   	JEstrada
	 Organization: 	
	 Filename:     	Test-Module.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module Deluxe
Set-Location -Path 'c:\TestData\LoadTests'
ls *.xml | Compare-RvP -CompareType SonyGPMS-MR -local -Verbose | Format-List