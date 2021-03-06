#Requires -Modules psake
[CmdletBinding(DefaultParameterSetName='Do')]
PARAM (
	[Parameter(Position=0,ParameterSetName='Do')][string[]]$Task = 'Build',
	[Parameter(ParameterSetName='Show')][switch]$ListTasks
)

[hashtable]$Parameters = @{
    ModuleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot/src/Cofl.Util.PowerShell/Cofl.Util.psd1" -ErrorAction Stop).ModuleVersion
    ModuleVersion2 = (Import-PowerShellDataFile -Path "$PSScriptRoot/src/Cofl.GetFilteredChildItem.PowerShell/Cofl.GetFilteredChildItem.psd1" -ErrorAction Stop).ModuleVersion
}

if($ListTasks){
	Invoke-Psake $PSScriptRoot\Cofl.Util.psake.ps1 -docs -parameters $Parameters -Verbose:$VerbosePreference
} else {
	Invoke-Psake $PSScriptRoot\Cofl.Util.psake.ps1 -taskList $Task -parameters $Parameters -Verbose:$VerbosePreference
}
