@{
    # PSScriptAnalyzer settings for bootstrapped PowerShell projects.
    # Opinions encoded here match the `powershell-bootstrap` skill.

    IncludeDefaultRules = $true

    Severity = @(
        'Error'
        'Warning'
        'Information'
    )

    IncludeRules = @(
        'PSAvoidAssignmentToAutomaticVariable'
        'PSAvoidDefaultValueForMandatoryParameter'
        'PSAvoidGlobalVars'
        'PSAvoidInvokingEmptyMembers'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidUsingUsernameAndPasswordParams'
        'PSAvoidUsingWriteHost'
        'PSMisleadingBacktick'
        'PSMissingModuleManifestField'
        'PSPlaceCloseBrace'
        'PSPlaceOpenBrace'
        'PSPossibleIncorrectComparisonWithNull'
        'PSProvideCommentHelp'
        'PSReservedCmdletChar'
        'PSReservedParams'
        'PSShouldProcess'
        'PSUseApprovedVerbs'
        'PSUseBOMForUnicodeEncodedFile'
        'PSUseCmdletCorrectly'
        'PSUseCompatibleSyntax'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseLiteralInitializerForHashtable'
        'PSUseOutputTypeCorrectly'
        'PSUsePSCredentialType'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseSingularNouns'
        'PSUseUTF8EncodingForHelpFile'
    )

    ExcludeRules = @(
        # Allow Write-Host in interactive scripts only; enforcement is by review, not by rule.
        # Re-enable this rule at L2 for library code by adding it to a team-level settings file.
    )

    Rules = @{

        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @(
                '7.4'
            )
        }

        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }

        PSUseConsistentWhitespace = @{
            Enable         = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator  = $true
            CheckPipe      = $true
            CheckSeparator = $true
        }

        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $false
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }

        PSAvoidUsingCmdletAliases = @{
            Whitelist = @()
        }
    }
}
