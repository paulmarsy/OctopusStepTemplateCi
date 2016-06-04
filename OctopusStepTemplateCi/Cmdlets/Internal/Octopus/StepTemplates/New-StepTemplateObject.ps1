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
	New-StepTemplateObject

.SYNOPSIS
    Creates a new step template object
#>
function New-StepTemplateObject {
    param (
        $Path
    )
    
    $stepTemplateName =  Get-VariableFromScriptFile -Path $Path -VariableName StepTemplateName
    $baseStepTemplate = Get-ScriptBody -Path $Path
    $moduleImports = Get-VariableFromScriptFile -Path $Path -VariableName StepTemplateModuleImports -AllowMissingVariable
    $stepTemplateContent = ""
    if ($moduleImports) {
        $stepTemplateContent = @"
if (`$null -eq `$ImportedScriptModules) {
    throw "No Script Modules have been imported"
}
"@
        foreach ($scriptModule in @($moduleImports)) {
            $stepTemplateContent += @"
 if (-not `$ImportedScriptModules.Contains('$($scriptModule.Name)')) {
     throw "This Octopus project requires Script Module '$($scriptModule.Name)' to be included, please add it and retry the deployment (Step Template: '$($stepTemplateName)')"     
 }
"@
            if ($scriptModule.RequiredVersion) {
                $stepTemplateContent += @"
 if (`$ImportedScriptModules['$($scriptModule.Name)'].Version -ne '$($scriptModule.RequiredVersion)') {
     throw "Step Template '$($stepTemplateName)' requires version '$($scriptModule.RequiredVersion)' of Script Module '$($scriptModule.Name)', the Step Template needs to be updated and/or the Octopus project needs to reference the newer template."
 }
"@
            } 
        }
    } else {
        $stepTemplateContent = $baseStepTemplate
    }

    New-Object -TypeName PSObject -Property (@{
        'Name' = $stepTemplateName
        'Description' = Get-VariableFromScriptFile -Path $Path -VariableName StepTemplateDescription
        'ActionType' = 'Octopus.Script'
        'Properties' = @{
            'Octopus.Action.Script.ScriptBody' = $stepTemplateContent
            'Octopus.Action.Script.Syntax' = 'PowerShell'
            }
        'Parameters' = @(Get-VariableFromScriptFile -Path $Path -VariableName StepTemplateParameters)
        'SensitiveProperties' = @{}
        '$Meta' = @{'Type' = 'ActionTemplate'}
        'Version' = 1
    })
}