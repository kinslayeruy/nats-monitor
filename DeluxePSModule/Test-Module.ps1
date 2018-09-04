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
Set-Location -Path 'c:\TestData\SonyGPMS\1 - SER'
#ls *.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
ls TitleMaster_20180312175308_WALKERYS_SRS_20180312055316_GPMS-50121.xml | Send-Rosetta -template 'json.sony.gpms.canonical-metadata' -hostName rosetta-api.service.owf-dev -showResults
#ls TitleMaster_20180312175308_WALKERYS_SRS_20180312055308_GPMS-50000.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
#cat TitleMaster_20180312175223_WALKERYS_NEPS_20180312061131_GPMS-5641.xml
#ls TitleMaster_20180312175223_WALKERYS_NEPS_20180312061131_GPMS-5641.xml | Compare-RvP -CompareType SonyGPMS-Atlas | Format-List
#ls TitleMaster_20180312175223_WALKERYS_NEPS_20180312061131_GPMS-5641.xml | Compare-RvP -CompareType SonyGPMS-Atlas -showResults