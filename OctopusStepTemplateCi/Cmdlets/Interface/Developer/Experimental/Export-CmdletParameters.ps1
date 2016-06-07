<#
Copyright 2016 ASOS.com Limited
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.NAME
    Export-CmdletParameters
    
.SYNOPSIS
    Exports the parameters of another cmdlet
.DESCRIPTION
    Exports the parameters of another cmdlet into the metadata variable format used by the module,
    so you can run for example, Export-CmdletParameters -Name Get-Help and it will generate the $StepTemplateParameters array    
    
.PARAMETER Name
    The name of the cmdlet to export the parameters of.
    
.INPUTS
    None. You cannot pipe objects to Export-CmdletParameters.
.OUTPUTS
    None.
#>
function Export-CmdletParameters {
    [CmdletBinding()]
    [OutputType("System.String")]
    param(
        [Parameter(Mandatory=$true)][System.String]$Name,
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$ExportToClipboard
    )
    Set-StrictMode -Off
    function Write-ParameterLine {
        param(
            $Name,
            $Value,
            $Indent = 2,
            [switch]$InlinePowerShell
        )
        if (-not $InlinePowerShell) {
            $Value = "`"$($Value)`""
        }
        Write-Output ("{0}'{1}' = {2}" -f ("`t" * $Indent), $Name, $Value)
    }

    $output = & {
        $cmdlettMetaData = Get-Help -Name $Name 
        $firstParameter = $true
        
        $mappedCmdlet = ""
        '$StepTemplateParameters = @('
        $cmdlettMetaData |  % { $_.parameters.parameter } | % {
            if ($_.name -in @('InformationAction', 'InformationVariable', 'Profile')) { return }
            $mappedCmdlet += "-$($_.name) `$$($_.Name) "
            
            if ($firstParameter) { "`t@{"; $firstParameter = $false }
            else { "`t}, @{" }
            
            Write-ParameterLine Name $_.name
            Write-ParameterLine Label ($_.name -creplace '(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])', ' $&') # Pascal split
            if  ($_.required -eq "true") {
                $qualifier = "Required"
            } else {
                $qualifier = "Optional"
            }
            Write-ParameterLine HelpText ("{0}: {1}" -f $qualifier, (($_.description | % Text | % Replace "`r" "`n" |  % Replace "`n" '`n'  ) -join '\n'))
            
            if ($_.type.name -eq "switch") {
                Write-ParameterLine DefaultValue False
                Write-ParameterLine DisplaySettings "@{ 'Octopus.ControlType' = 'Checkbox' }" -InlinePowerShell
            } else {
                if  (-not ([string]::IsNullOrWhiteSpace($_.defaultValue)) -and $_.defaultValue -ne "none") {
                    Write-ParameterLine DefaultValue $_.defaultValue
                } else {
                    Write-ParameterLine DefaultValue '$null' -InlinePowerShell
                }

                $validateSet = $cmdlettMetaData | % { $_.syntax.syntaxItem.parameter } | ? name -eq $_.name | % parameterValueGroup | % parameterValue
                if (-not ([string]::IsNullOrWhiteSpace($validateSet))) {
                    Write-ParameterLine DisplaySettings "@{" -InlinePowerShell
                    Write-ParameterLine 'Octopus.ControlType' Select 2
                    Write-ParameterLine 'Octopus.SelectOptions' ($validateSet -join '`n') 2
                    "`t`t}"
                } else {
                    Write-ParameterLine DisplaySettings "@{ 'Octopus.ControlType' = 'SingleLineText' }" -InlinePowerShell
                }
            }
        }
        "`t}"
        ')'
        
        "# Cmdlet Invocation"
        "$Name $mappedCmdlet"
    }
    
     if ($ExportToClipboard) { [System.Windows.Forms.Clipboard]::SetText($output) }
     else { Write-Output $output }
}
