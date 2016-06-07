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
    Import-StepTemplate
    
.SYNOPSIS
    Imports a step template

.DESCRIPTION
    Imports a step template in JSON format from the Community Site or Export from Octopus's UI into the native .ps1 format used by this module
    
.PARAMETER Path
    The path to the step template

.PARAMETER ExportPath
    The location to save the step template file
    
.PARAMETER Force
    Overwrites the file if it already exists
    
.PARAMETER ExportToClipboard
    Imports the step template to the system clipboard
    
.INPUTS
    None. You cannot pipe objects to Import-StepTemplate.

.OUTPUTS
    None.
#>
function Import-StepTemplate {
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(Mandatory=$true)][ValidateSet("File", "Clipboard")][System.String]$ImportFrom,
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$Path,
        [Parameter(Mandatory=$true)][ValidateSet("File", "Clipboard", "Pipeline")][System.String]$ExportTo,
        [Parameter(Mandatory=$false)][System.String]$ExportPath,
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$Force
    )
    if ($ImportFrom -eq 'File' -and (Test-Path $Path)) {
        $json = Get-Content -Path (Resolve-Path -Path $Path) -Raw
    } elseif ($ImportFrom -eq 'Clipboard') {
        Add-Type -AssemblyName System.Windows.Forms
        $json = [System.Windows.Forms.Clipboard]::GetText()
    } else {
        throw "Invalid import"
    }
    $jsonConverted = $json | ConvertFrom-Json
    $stepTemplate = @"
`$StepTemplateName = '$($jsonConverted.Name)'
`$StepTemplateDescription = '$($jsonConverted.Description)'
`$StepTemplateParameters = @(

"@
   $stepTemplate += (@($jsonConverted.Parameters | % {
@"
        @{
            'Name' = "$($_.Name)"
            'Label' = "$($_.Label)"
            'HelpText' = "$($_.HelpText)"
            'DefaultValue' = $($_.DefaultValue)
            'DisplaySettings' = $($_.DisplaySettings)
        }
"@
    } | % Trim) -join ',')
    $stepTemplate += "`n)`n'`n"
    $stepTemplate += $jsonConverted.Properties.'Octopus.Action.Script.ScriptBody'

    if ($ExportTo -eq 'File' -and -not ([string]::IsNullOrWhiteSpace($ExportPath))) {
            if ((Test-Path $ExportPath) -and -not $Force) {
                throw "$ExportPath already exists. Specify -Force to overwrite"
            }
            
            Set-Content -Path $ExportPath -Value $stepTemplate -Force:$Force -Encoding UTF8
            
            "Step Template exported to $ExportPath"
        } elseif ($ExportTo -eq 'Clipboard') {
             Add-Type -AssemblyName System.Windows.Forms
             [System.Windows.Forms.Clipboard]::SetText($stepTemplate)
            
            "Step Template exported to clipboard"
        } elseif ($ExportTo -eq 'Pipeline') {
            $stepTemplate | Write-Output
    } 
}