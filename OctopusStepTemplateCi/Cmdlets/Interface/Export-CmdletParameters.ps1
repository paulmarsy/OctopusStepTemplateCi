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
        [Parameter(Mandator=$true)][System.String]$Name
    )
    
    $cmdlettMetaData = Get-Help -Name $Name 
    $firstParameter = $true
    
    $mappedCmdlet = ""
     $cmdlettMetaData |  % { $_.parameters.parameter } | % {
        $mappedCmdlet += "-$($_.name) `$$($_.Name) "
        
         if ($firstParameter) { "@{"; $firstParameter = $false }
         else { "}, @{" }
         
        "`t'Name' = '{0}'" -f $_.name
        "`t'Label' = '{0}'" -f ($_.name -creplace '(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])', ' $&') # Pascal split
        if  ($_.required -eq "true") {
            $qualifier = "Required"
        } else {
            $qualifier = "Optional"
        }
        "`t'HelpText' = `"{0}: {1}`"" -f $qualifier, (($_.description | % Text | % Replace "`r" "`n" |  % Replace "`n" '`n'  ) -join '\n')
        
        if ($_.type.name -eq "switch") {
            "`t'DefaultValue' = 'False'"
            "`t'DisplaySettings' = @{ 'Octopus.ControlType' = 'Checkbox' }"
        } else {
            if  ($null -ne $_.defaultValue -and $_.defaultValue -ne "none") {
                "`t'DefaultValue' = '{0}'" -f $_.defaultValue
            } else {
                "`t'DefaultValue' = `$null"
            }

            $validateSet = $cmdlettMetaData | % { $_.syntax.syntaxItem.parameter } | ? name -eq $_.name | % parameterValueGroup | % parameterValue
            if ($validateSet) {
                "`t'DisplaySettings' = @{"
                    "`t`t'Octopus.ControlType' = 'Select'"
                    "`t`t'Octopus.SelectOptions' = `"{0}`"" -f ($validateSet -join '`n')
                "`t}"
            } else {
                "`t'DisplaySettings' = @{ 'Octopus.ControlType' = 'SingleLineText' }"
            }
        }
    }
    '}'
    
    "# Cmdlet Invocation"
    "$Name $mappedCmdlet"
}
