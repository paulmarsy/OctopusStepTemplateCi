function Export-CmdletParameters {
    param(
        $Name
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
        "`t'HelpText' = '{0}: {1}'" -f $qualifier, (($_.description | % Text | % Replace "`r" "`n" |  % Replace "`n" '`n'  ) -join '`n')
        
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
                    "`t`t'Octopus.SelectOptions' = '{0}'" -f ($validateSet -join '`n')
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