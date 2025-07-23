#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

using module .\JoinModule.psd1

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
param()

if (!(Get-Command 'ConvertFrom-SourceTable').Parameters.ParseRightAligned) { Update-Script 'ConvertFrom-SourceTable' -Confirm:$False -Force }

Describe 'Join-Object' {

    BeforeAll {

        Set-StrictMode -Version Latest

        # . .\ConvertFrom-SourceTable -ParseRightAligned.ps1                             # https://www.powershellgallery.com/packages/ConvertFrom-SourceTable

        Function Compare-PSObject([Object[]]$ReferenceObject, [Object[]]$DifferenceObject) {
            $Property = ($ReferenceObject  | Select-Object -First 1).PSObject.Properties.Name +
                        ($DifferenceObject | Select-Object -First 1).PSObject.Properties.Name | Select-Object -Unique
                        Compare-Object $ReferenceObject $DifferenceObject -Property $Property
        }

        Function ConvertTo-Array([String]$String, [String]$Pattern = '{,}') {
            $Open, $Split, $Close = Switch ($Pattern.Length) {
                0      	{$Null}
                1      	{$Null, $Pattern}
                2      	{$Pattern[0], $Pattern[1]}
                Default	{$Pattern[0], $Pattern.Substring(1, $Pattern.Length - 2), $Pattern[-1]}
            }
            &{
                If ($Split) {
                    If ($Open) {
                        If ($Close) {
                            If ($String[0] -eq $Open -and $String[-1] -eq $Close) {
                                $String.Substring(1, $String.Length - 2).Trim() -Split "\s*$Split\s*"
                            } Else {$String}
                        } ElseIf (Value[-1] -eq $Close) {
                            $String.Substring(1).Trim() -Split "\s*$Split\s*"
                        } Else {$String}
                    } Else {$String -Split "\s*$Split\s*"}
                } Else {$String}
            } | ForEach-Object {If ($_ -eq '$null') {$Null} Else {$_}}
        }; Set-Alias cta ConvertTo-Array

        $Employee = ConvertFrom-SourceTable -ParseRightAligned '
            Id Name    Country Department  Age ReportsTo
            -- ----    ------- ----------  --- ---------
             1 Aerts   Belgium Sales        40         5
             2 Bauer   Germany Engineering  31         4
             3 Cook    England Sales        69         1
             4 Duval   France  Engineering  21         5
             5 Evans   England Marketing    35
             6 Fischer Germany Engineering  29         4'


        $Department = ConvertFrom-SourceTable -ParseRightAligned '
            Name        Country
            ----        -------
            Engineering Germany
            Marketing   England
            Sales       France
            Purchase    France'

        $Changes = ConvertFrom-SourceTable -ParseRightAligned '
            Id Name    Country Department  Age ReportsTo
            -- ----    ------- ----------  --- ---------
             3 Cook    England Sales        69         5
             6 Fischer France  Engineering  29         4
             7 Geralds Belgium Sales        71         1'

    }

    Context 'Sanity check' {

         It 'Help' {
             Join-Object -? |Out-String -Stream |Should -Contain SYNOPSIS
         }
    }

    Context 'Join types' {

        It '$Employee | InnerJoin $Department -On Country -Discern Employee, Department' {
            $Actual = $Employee | InnerJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    EmployeeCountry Department  Age ReportsTo DepartmentCountry
                -- ----    --------------- ----------  --- --------- -----------------
                 1 Aerts   Belgium         Sales        40         5 France
                 2 Bauer   Germany         Engineering  31         4 Germany
                 3 Cook    England         Sales        69         1 France
                 4 Duval   France          Engineering  21         5 Germany
                 5 Evans   England         Marketing    35           England
                 6 Fischer Germany         Engineering  29         4 Germany'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | InnerJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | InnerJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 2 Bauer   Germany Engineering  31         4
                 5 Evans   England Marketing    35
                 6 Fischer Germany Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | InnerJoin $Department -On Country' {
            $Actual = $Employee | InnerJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name                   Country Department  Age ReportsTo
                -- ----                   ------- ----------  --- ---------
                 2 {Bauer, Engineering}   Germany Engineering  31         4
                 3 {Cook, Marketing}      England Sales        69         1
                 4 {Duval, Sales}         France  Engineering  21         5
                 4 {Duval, Purchase}      France  Engineering  21         5
                 5 {Evans, Marketing}     England Marketing    35
                 6 {Fischer, Engineering} Germany Engineering  29         4
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Country, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin $Department -On Country -Discern Employee, Department' {
            $Actual = $Employee | LeftJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 1 Aerts        Belgium Sales        40         5          $Null
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin $Department -On Department -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | LeftJoin $Department -On Department -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    EmployeeCountry Department  Age ReportsTo DepartmentCountry
                -- ----    --------------- ----------  --- --------- -----------------
                 1 Aerts   Belgium         Sales        40         5 France
                 2 Bauer   Germany         Engineering  31         4 Germany
                 3 Cook    England         Sales        69         1 France
                 4 Duval   France          Engineering  21         5 Germany
                 5 Evans   England         Marketing    35           England
                 6 Fischer Germany         Engineering  29         4 Germany'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | LeftJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   Belgium Sales        40         5
                 2 Bauer   Germany Engineering  31         4
                 3 Cook    England Sales        69         1
                 4 Duval   France  Engineering  21         5
                 5 Evans   England Marketing    35
                 6 Fischer Germany Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin $Department -On Country' {
            $Actual = $Employee | LeftJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Id Name                   Department  Age ReportsTo
                ------- -- ----                   ----------  --- ---------
                Belgium  1 {Aerts, $null}         Sales        40         5
                Germany  2 {Bauer, Engineering}   Engineering  31         4
                England  3 {Cook, Marketing}      Sales        69         1
                France   4 {Duval, Sales}         Engineering  21         5
                France   4 {Duval, Purchase}      Engineering  21         5
                England  5 {Evans, Marketing}     Marketing    35
                Germany  6 {Fischer, Engineering} Engineering  29         4
            ' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | RightJoin $Department -On Country -Discern Employee, Department' {
            $Actual = $Employee | RightJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | RightJoin $Department -On Department -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | RightJoin $Department -On Department -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    EmployeeCountry Department    Age ReportsTo DepartmentCountry
                   -- ----    --------------- ----------    --- --------- -----------------
                    1 Aerts   Belgium         Sales          40         5 France
                    2 Bauer   Germany         Engineering    31         4 Germany
                    3 Cook    England         Sales          69         1 France
                    4 Duval   France          Engineering    21         5 Germany
                    5 Evans   England         Marketing      35           England
                    6 Fischer Germany         Engineering    29         4 Germany
                $Null   $Null           $Null Purchase    $Null     $Null France'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | RightJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | RightJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    Country Department    Age ReportsTo
                   -- ----    ------- ----------    --- ---------
                    2 Bauer   Germany Engineering    31         4
                    5 Evans   England Marketing      35
                    6 Fischer Germany Engineering    29         4
                $Null   $Null France  Sales       $Null     $Null
                $Null   $Null France  Purchase    $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | RightJoin $Department -On Country' {
            $Actual = $Employee | RightJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Id Name                   Department  Age ReportsTo
                ------- -- ----                   ----------  --- ---------
                Germany  2 {Bauer, Engineering}   Engineering  31         4
                England  3 {Cook, Marketing}      Sales        69         1
                France   4 {Duval, Sales}         Engineering  21         5
                France   4 {Duval, Purchase}      Engineering  21         5
                England  5 {Evans, Marketing}     Marketing    35
                Germany  6 {Fischer, Engineering} Engineering  29         4
            ' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | FullJoin $Department -On Country -Discern Employee, Department' {
            $Actual = $Employee | FullJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 1 Aerts        Belgium Sales        40         5          $Null
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | FullJoin $Department -On Department -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | FullJoin $Department -On Department -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    EmployeeCountry Department    Age ReportsTo DepartmentCountry
                   -- ----    --------------- ----------    --- --------- -----------------
                    1 Aerts   Belgium         Sales          40         5 France
                    2 Bauer   Germany         Engineering    31         4 Germany
                    3 Cook    England         Sales          69         1 France
                    4 Duval   France          Engineering    21         5 Germany
                    5 Evans   England         Marketing      35           England
                    6 Fischer Germany         Engineering    29         4 Germany
                $Null   $Null           $Null Purchase    $Null     $Null France'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | FullJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | FullJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    Country Department    Age ReportsTo
                   -- ----    ------- ----------    --- ---------
                    1 Aerts   Belgium Sales          40         5
                    2 Bauer   Germany Engineering    31         4
                    3 Cook    England Sales          69         1
                    4 Duval   France  Engineering    21         5
                    5 Evans   England Marketing      35
                    6 Fischer Germany Engineering    29         4
                $Null   $Null France  Sales       $Null     $Null
                $Null   $Null France  Purchase    $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | FullJoin $Department -On Country' {
            $Actual = $Employee | FullJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Id Name                   Department  Age ReportsTo
                ------- -- ----                   ----------  --- ---------
                Belgium  1 {Aerts, $null}         Sales        40         5
                Germany  2 {Bauer, Engineering}   Engineering  31         4
                England  3 {Cook, Marketing}      Sales        69         1
                France   4 {Duval, Sales}         Engineering  21         5
                France   4 {Duval, Purchase}      Engineering  21         5
                England  5 {Evans, Marketing}     Marketing    35
                Germany  6 {Fischer, Engineering} Engineering  29         4
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Country, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | OuterJoin $Department -On Country -Discern Employee, Department' {
            $Actual = $Employee | OuterJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName DepartmentName Country Department  Age ReportsTo
                -- ------------ -------------- ------- ----------  --- ---------
                 1 Aerts                 $Null Belgium Sales        40         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | OuterJoin $Department -On Department -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | OuterJoin $Department -On Department -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    EmployeeCountry DepartmentCountry Department    Age ReportsTo
                   -- ----    --------------- ----------------- ----------    --- ---------
                $Null   $Null           $Null France            Purchase    $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | OuterJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
            $Actual = $Employee | OuterJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name    Country Department    Age ReportsTo
                   -- ----    ------- ----------    --- ---------
                    1 Aerts   Belgium Sales          40         5
                    3 Cook    England Sales          69         1
                    4 Duval   France  Engineering    21         5
                $Null   $Null France  Sales       $Null     $Null
                $Null   $Null France  Purchase    $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | OuterJoin $Department -On Country' {
            $Actual = $Employee | OuterJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name           Country  Department  Age ReportsTo
                -- ----           -------  ----------  --- ---------
                 1 {Aerts, $null} Belgium  Sales        40         5
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Country, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | CrossJoin $Department -Discern Employee, Department' {
            $Actual = $Employee | CrossJoin $Department -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
                -- ------------ --------------- ----------  --- --------- -------------- -----------------
                 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
                 1 Aerts        Belgium         Sales        40         5 Marketing      England
                 1 Aerts        Belgium         Sales        40         5 Sales          France
                 1 Aerts        Belgium         Sales        40         5 Purchase       France
                 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
                 2 Bauer        Germany         Engineering  31         4 Marketing      England
                 2 Bauer        Germany         Engineering  31         4 Sales          France
                 2 Bauer        Germany         Engineering  31         4 Purchase       France
                 3 Cook         England         Sales        69         1 Engineering    Germany
                 3 Cook         England         Sales        69         1 Marketing      England
                 3 Cook         England         Sales        69         1 Sales          France
                 3 Cook         England         Sales        69         1 Purchase       France
                 4 Duval        France          Engineering  21         5 Engineering    Germany
                 4 Duval        France          Engineering  21         5 Marketing      England
                 4 Duval        France          Engineering  21         5 Sales          France
                 4 Duval        France          Engineering  21         5 Purchase       France
                 5 Evans        England         Marketing    35           Engineering    Germany
                 5 Evans        England         Marketing    35           Marketing      England
                 5 Evans        England         Marketing    35           Sales          France
                 5 Evans        England         Marketing    35           Purchase       France
                 6 Fischer      Germany         Engineering  29         4 Engineering    Germany
                 6 Fischer      Germany         Engineering  29         4 Marketing      England
                 6 Fischer      Germany         Engineering  29         4 Sales          France
                 6 Fischer      Germany         Engineering  29         4 Purchase       France'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        Context 'Update' {

            BeforeAll {
                $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                    Id Name    Country Department  Age ReportsTo
                    -- ----    ------- ----------  --- ---------
                     1 Aerts   Belgium Sales        40         5
                     2 Bauer   Germany Engineering  31         4
                     3 Cook    England Sales        69         5
                     4 Duval   France  Engineering  21         5
                     5 Evans   England Marketing    35
                     6 Fischer France  Engineering  29         4'
            }

            It '$Employee | Update $Changes -On Id' {
                $Actual = $Employee | Update $Changes -On Id
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | LeftJoin $Changes -On Id -Property "Right.*"' {
                $Actual = $Employee | LeftJoin $Changes -On Id -Property 'Right.*'
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | LeftJoin $Changes -On Id -Property @{ "*" = "Right.*" }' {
                $Actual = $Employee | LeftJoin $Changes -On Id -Property @{ '*' = 'Right.*' }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | LeftJoin $Changes -On Id -Property { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } }' {
                $Actual = $Employee | LeftJoin $Changes -On Id -Property { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | LeftJoin $Changes -On Id -Property @{ "*" = { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } } }' {
                $Actual = $Employee | LeftJoin $Changes -On Id -Property @{ '*' = { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } } }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }
        }

        Context 'Merge' {

            BeforeAll {
                $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                    Id Name    Country Department  Age ReportsTo
                    -- ----    ------- ----------  --- ---------
                     1 Aerts   Belgium Sales        40         5
                     2 Bauer   Germany Engineering  31         4
                     3 Cook    England Sales        69         5
                     4 Duval   France  Engineering  21         5
                     5 Evans   England Marketing    35
                     6 Fischer France  Engineering  29         4
                     7 Geralds Belgium Sales        71         1'
            }

            It '$Employee | Merge $Changes -On Id' {
                $Actual = $Employee | Merge $Changes -On Id
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | FullJoin $Changes -On Id -Property "Right.*"' {
                $Actual = $Employee | FullJoin $Changes -On Id -Property 'Right.*'
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | FullJoin $Changes -On Id -Property @{ "*" = "Right.*" }' {
                $Actual = $Employee | FullJoin $Changes -On Id -Property @{ '*' = 'Right.*' }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | FullJoin $Changes -On Id -Property { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } }' {
                $Actual = $Employee | FullJoin $Changes -On Id -Property { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }

            It '$Employee | FullJoin $Changes -On Id -Property @{ "*" = { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } } }' {
                $Actual = $Employee | FullJoin $Changes -On Id -Property @{ '*' = { if ($Null -ne $RightIndex) { $Right.$_ } else { $Left.$_ } } }
                Compare-PSObject $Actual $Expected | Should -BeNull
            }
        }

        It '$Employee | Differs $Department -On Country' {
            $Actual = $Employee | Differs $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   Belgium Sales        40         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | Differs $Department -On Department -Equals Name' {
            $Actual = $Employee | Differs $Department -On Department -Equals Name
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name     Country Department   Age ReportsTo
                   -- ----     ------- ----------   --- ---------
                $Null Purchase France       $Null $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | Differs $Department -On Department, Country -Equals Name' {
            $Actual = $Employee | Differs $Department -On Department, Country -Equals Name
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                   Id Name     Country Department    Age ReportsTo
                   -- ----     ------- ----------    --- ---------
                    1 Aerts    Belgium Sales          40         5
                    3 Cook     England Sales          69         1
                    4 Duval    France  Engineering    21         5
                $Null Sales    France        $Null $Null     $Null
                $Null Purchase France        $Null $Null     $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | Differs $Department -On Country' {
            $Actual = $Employee | Differs $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   Belgium Sales        40         5'


            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context 'Self join on LeftObject' {

        It '$Employee | Join -On Country -Discern *1,*2' {
            $Actual = $Employee | Join -On Country -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id1 Id2 Name1   Name2   Country Department1 Department2 Age1 Age2 ReportsTo1 ReportsTo2
                --- --- -----   -----   ------- ----------- ----------- ---- ---- ---------- ----------
                  2   6 Bauer   Fischer Germany Engineering Engineering   31   29          4          4
                  3   5 Cook    Evans   England Sales       Marketing     69   35          1
                  5   3 Evans   Cook    England Marketing   Sales         35   69                     1
                  6   2 Fischer Bauer   Germany Engineering Engineering   29   31          4          4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin -On ReportsTo -Equals Id -Discern *1,*2' {
            $Actual = $Employee | LeftJoin -On ReportsTo -Equals Id -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name1   Country1 Department1 Age1 Name2  Country2 Department2 Age2   ReportsTo
                -- -----   -------- ----------- ---- -----  -------- ----------- ----   ---------
                 1 Aerts   Belgium  Sales         40 Evans  England  Marketing       35
                 2 Bauer   Germany  Engineering   31 Duval  France   Engineering     21         5
                 3 Cook    England  Sales         69 Aerts  Belgium  Sales           40         5
                 4 Duval   France   Engineering   21 Evans  England  Marketing       35
                 5 Evans   England  Marketing     35  $Null    $Null       $Null  $Null     $Null
                 6 Fischer Germany  Engineering   29 Duval  France   Engineering     21         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | InnerJoin -On ReportsTo, Department -Equals Id -Discern *1,*2' {
            $Actual = $Employee | InnerJoin -On ReportsTo, Department -Equals Id -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name1   Country1 Department  Age1 Name2 Country2 Age2 ReportsTo
                -- -----   -------- ----------  ---- ----- -------- ---- ---------
                 2 Bauer   Germany  Engineering   31 Duval France     21         5
                 3 Cook    England  Sales         69 Aerts Belgium    40         5
                 6 Fischer Germany  Engineering   29 Duval France     21         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin -On ReportsTo -Equals Id -Property @{Name = {$Left["Name"]}; Manager = {$Right["Name"]}}' {
            $Actual = $Employee | LeftJoin -On ReportsTo -Equals Id -Property @{Name = {$Left['Name']}; Manager = {$Right['Name']}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Manager Name
                ------- ----
                Evans   Aerts
                Duval   Bauer
                Aerts   Cook
                Evans   Duval
                  $Null Evans
                Duval   Fischer'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context 'Self join on RightObject' {

        It 'Join $Employee -On Department -Discern *1,*2' {
            $Actual = Join $Employee -On Department -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id1 Id2 Name1   Name2   Country1 Country2 Department  Age1 Age2 ReportsTo1 ReportsTo2
                --- --- -----   -----   -------- -------- ----------  ---- ---- ---------- ----------
                  1   3 Aerts   Cook    Belgium  England  Sales         40   69          5          1
                  2   4 Bauer   Duval   Germany  France   Engineering   31   21          4          5
                  2   6 Bauer   Fischer Germany  Germany  Engineering   31   29          4          4
                  3   1 Cook    Aerts   England  Belgium  Sales         69   40          1          5
                  4   2 Duval   Bauer   France   Germany  Engineering   21   31          5          4
                  4   6 Duval   Fischer France   Germany  Engineering   21   29          5          4
                  6   2 Fischer Bauer   Germany  Germany  Engineering   29   31          4          4
                  6   4 Fischer Duval   Germany  France   Engineering   29   21          4          5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'LeftJoin $Employee -On ReportsTo -Equals Id -Discern *1,*2' {
            $Actual = LeftJoin $Employee -On ReportsTo -Equals Id -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
            Id Name1   Country1 Department1 Age1 Name2  Country2 Department2 Age2   ReportsTo
            -- -----   -------- ----------- ---- -----  -------- ----------- ----   ---------
             1 Aerts   Belgium  Sales         40 Evans  England  Marketing       35
             2 Bauer   Germany  Engineering   31 Duval  France   Engineering     21         5
             3 Cook    England  Sales         69 Aerts  Belgium  Sales           40         5
             4 Duval   France   Engineering   21 Evans  England  Marketing       35
             5 Evans   England  Marketing     35  $Null    $Null       $Null  $Null     $Null
             6 Fischer Germany  Engineering   29 Duval  France   Engineering     21         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'InnerJoin $Employee -On ReportsTo, Department -Equals Id -Discern *1,*2' {
            $Actual = InnerJoin $Employee -On ReportsTo, Department -Equals Id -Discern *1,*2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name1   Country1 Department  Age1 Name2 Country2 Age2 ReportsTo
                -- -----   -------- ----------  ---- ----- -------- ---- ---------
                 2 Bauer   Germany  Engineering   31 Duval France     21         5
                 3 Cook    England  Sales         69 Aerts Belgium    40         5
                 6 Fischer Germany  Engineering   29 Duval France     21         5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left["Name"]}; Manager = {$Right["Name"]}}' {
            $Actual = LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left['Name']}; Manager = {$Right['Name']}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Manager Name
                ------- ----
                Evans   Aerts
                Duval   Bauer
                Aerts   Cook
                Evans   Duval
                  $Null Evans
                Duval   Fischer'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = "Left.Name"; Manager = "Right.Name"}' { # Smart properties
            $Actual = LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = 'Left.Name'; Manager = 'Right.Name'}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Manager Name
                ------- ----
                Evans   Aerts
                Duval   Bauer
                Aerts   Cook
                Evans   Duval
                  $Null Evans
                Duval   Fischer'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context 'Join by index' {

        It '$Employee | InnerJoin $Department -Discern Employee, Department' {
            $Actual = $Employee | InnerJoin $Department -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
                -- ------------ --------------- ----------  --- --------- -------------- -----------------
                 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
                 2 Bauer        Germany         Engineering  31         4 Marketing      England
                 3 Cook         England         Sales        69         1 Sales          France
                 4 Duval        France          Engineering  21         5 Purchase       France'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | LeftJoin $Department -Discern Employee, Department' {
            $Actual = $Employee | LeftJoin $Department -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
                -- ------------ --------------- ----------  --- --------- -------------- -----------------
                 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
                 2 Bauer        Germany         Engineering  31         4 Marketing      England
                 3 Cook         England         Sales        69         1 Sales          France
                 4 Duval        France          Engineering  21         5 Purchase       France
                 5 Evans        England         Marketing    35                    $Null             $Null
                 6 Fischer      Germany         Engineering  29         4          $Null             $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Department | RightJoin $Employee -Discern Employee, Department' {				# Swapped $Department and $Employee
            $Actual = $Department | RightJoin $Employee -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                EmployeeName EmployeeCountry Id DepartmentName DepartmentCountry Department  Age ReportsTo
                ------------ --------------- -- -------------- ----------------- ----------  --- ---------
                Engineering  Germany          1 Aerts          Belgium           Sales        40         5
                Marketing    England          2 Bauer          Germany           Engineering  31         4
                Sales        France           3 Cook           England           Sales        69         1
                Purchase     France           4 Duval          France            Engineering  21         5
                       $Null           $Null  5 Evans          England           Marketing    35
                       $Null           $Null  6 Fischer        Germany           Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | FullJoin $Department -Discern Employee, Department' {
            $Actual = $Employee | FullJoin $Department -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
                -- ------------ --------------- ----------  --- --------- -------------- -----------------
                 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
                 2 Bauer        Germany         Engineering  31         4 Marketing      England
                 3 Cook         England         Sales        69         1 Sales          France
                 4 Duval        France          Engineering  21         5 Purchase       France
                 5 Evans        England         Marketing    35                    $Null             $Null
                 6 Fischer      Germany         Engineering  29         4          $Null             $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context "Merge columns" {

        It 'Use the left object property if exists otherwise use right object property' {
            $Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   Belgium Sales        40         5
                 2 Bauer   Germany Engineering  31         4
                 3 Cook    England Sales        69         1
                 4 Duval   France  Engineering  21         5
                 5 Evans   England Marketing    35
                 6 Fischer Germany Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Use the left object property if exists otherwise use right object property (using smart property)' {
            $Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property Left.*
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   Belgium Sales        40         5
                 2 Bauer   Germany Engineering  31         4
                 3 Cook    England Sales        69         1
                 4 Duval   France  Engineering  21         5
                 5 Evans   England Marketing    35
                 6 Fischer Germany Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context "Selected properties" {

        It 'Only use the left name property and the right manager property' {
            $Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property *, @{Name = {$Left.$_}; Country = {$Right.$_}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Name    Id Department  Age ReportsTo
                ------- ----    -- ----------  --- ---------
                France  Aerts    1 Sales        40         5
                Germany Bauer    2 Engineering  31         4
                France  Cook     3 Sales        69         1
                Germany Duval    4 Engineering  21         5
                England Evans    5 Marketing    35
                Germany Fischer  6 Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Only use the left name property and the right manager property (ordered selection)' {
            $Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property Id, @{Name = {$Left.$_}}, Department, @{Country = {$Right.$_}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Department  Country
                -- ----    ----------  -------
                 1 Aerts   Sales       France
                 2 Bauer   Engineering Germany
                 3 Cook    Sales       France
                 4 Duval   Engineering Germany
                 5 Evans   Marketing   England
                 6 Fischer Engineering Germany'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Use the left object property except for the country property' {
            $Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property @{'*' = {$Left.$_}; Country = {$Right.$_}}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country Department  Age ReportsTo
                -- ----    ------- ----------  --- ---------
                 1 Aerts   France  Sales        40         5
                 2 Bauer   Germany Engineering  31         4
                 3 Cook    France  Sales        69         1
                 4 Duval   Germany Engineering  21         5
                 5 Evans   England Marketing    35
                 6 Fischer Germany Engineering  29         4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context "Join using expression" {

        It '$Employee | Join $Department {$Left.Department -ne $Right.Name}' {
            $Actual = $Employee | Join $Department -Using {$Left.Department -ne $Right.Name}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name                 Country            Department  Age ReportsTo
                -- ----                 -------            ----------  --- ---------
                 1 {Aerts, Engineering} {Belgium, Germany} Sales        40         5
                 1 {Aerts, Marketing}   {Belgium, England} Sales        40         5
                 1 {Aerts, Purchase}    {Belgium, France}  Sales        40         5
                 2 {Bauer, Marketing}   {Germany, England} Engineering  31         4
                 2 {Bauer, Sales}       {Germany, France}  Engineering  31         4
                 2 {Bauer, Purchase}    {Germany, France}  Engineering  31         4
                 3 {Cook, Engineering}  {England, Germany} Sales        69         1
                 3 {Cook, Marketing}    {England, England} Sales        69         1
                 3 {Cook, Purchase}     {England, France}  Sales        69         1
                 4 {Duval, Marketing}   {France, England}  Engineering  21         5
                 4 {Duval, Sales}       {France, France}   Engineering  21         5
                 4 {Duval, Purchase}    {France, France}   Engineering  21         5
                 5 {Evans, Engineering} {England, Germany} Marketing    35
                 5 {Evans, Sales}       {England, France}  Marketing    35
                 5 {Evans, Purchase}    {England, France}  Marketing    35
                 6 {Fischer, Marketing} {Germany, England} Engineering  29         4
                 6 {Fischer, Sales}     {Germany, France}  Engineering  29         4
                 6 {Fischer, Purchase}  {Germany, France}  Engineering  29         4
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | Join $Department {$Left.Department -eq $Right.Name -and $Left.Country -ne $Right.Country}' {	# Recommended: $Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}
            $Actual = $Employee | Join $Department -Using {$Left.Department -eq $Right.Name -and $Left.Country -ne $Right.Country}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name                 Country           Department  Age ReportsTo
                -- ----                 -------           ----------  --- ---------
                 1 {Aerts, Sales}       {Belgium, France} Sales        40         5
                 3 {Cook, Sales}        {England, France} Sales        69         1
                 4 {Duval, Engineering} {France, Germany} Engineering  21         5
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context "Where..." {

        It '$Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}' {
            $Actual = $Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name  Country           Department  Age ReportsTo
                -- ----  -------           ----------  --- ---------
                 1 Aerts {Belgium, France} Sales        40         5
                 3 Cook  {England, France} Sales        69         1
                 4 Duval {France, Germany} Engineering  21         5
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It '$Employee | Join $Department -Where {$Left.Country -eq $Right.Country}' {		# On index where...
            $Actual = $Employee | Join $Department -Where {$Left.Country -eq $Right.Country}
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name              Country          Department  Age ReportsTo
                -- ----              -------          ----------  --- ---------
                 4 {Duval, Purchase} {France, France} Engineering  21         5
            ' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context "DataTables" {

        BeforeAll {
            $DataTable1 = New-Object Data.DataTable
            $Null = $DataTable1.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
            $Null = $DataTable1.Columns.Add((New-Object Data.DataColumn 'Column2'), [Int])
            $DataRow = $DataTable1.NewRow()
            $DataRow.Item('Column1') = "A"
            $DataRow.Item('Column2') = 1
            $DataTable1.Rows.Add($DataRow)
            $DataRow = $DataTable1.NewRow()
            $DataRow.Item('Column1') = "B"
            $DataRow.Item('Column2') = 2
            $DataTable1.Rows.Add($DataRow)
            $DataRow = $DataTable1.NewRow()
            $DataRow.Item('Column1') = "C"
            $DataRow.Item('Column2') = 3
            $DataTable1.Rows.Add($DataRow)

            $DataTable2 = New-Object Data.DataTable
            $Null = $DataTable2.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
            $Null = $DataTable2.Columns.Add((New-Object Data.DataColumn 'Column3'), [Int])
            $DataRow = $DataTable2.NewRow()
            $DataRow.Item('Column1') = "B"
            $DataRow.Item('Column3') = 3
            $DataTable2.Rows.Add($DataRow)
            $DataRow = $DataTable2.NewRow()
            $DataRow.Item('Column1') = "C"
            $DataRow.Item('Column3') = 4
            $DataTable2.Rows.Add($DataRow)
            $DataRow = $DataTable2.NewRow()
            $DataRow.Item('Column1') = "D"
            $DataRow.Item('Column3') = 5
            $DataTable2.Rows.Add($DataRow)
        }

        It '(inner)join DataTables' {
            $Actual = $DataTable1 | Join $DataTable2 -On Column1
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Column1 Column2 Column3
                ------- ------- -------
                B             2       3
                C             3       4
            '

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'LeftJoin DataTables' {
            $Actual = $DataTable1 | LeftJoin $DataTable2 -On Column1
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Column1 Column2 Column3
                ------- ------- -------
                A             1   $Null
                B             2       3
                C             3       4
            '

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'RightJoin DataTables' {
            $Actual = $DataTable1 | RightJoin $DataTable2 -On Column1
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Column1 Column2 Column3
                ------- ------- -------
                B             2       3
                C             3       4
                D         $Null       5
            '

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'FullJoin DataTables' {
            $Actual = $DataTable1 | FullJoin $DataTable2 -On Column1
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Column1 Column2 Column3
                ------- ------- -------
                A             1   $Null
                B             2       3
                C             3       4
                D         $Null       5
            '

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Self join DataTable' {
            Join $DataTable1 -On Column1 | Should -BeNull
        }
    }

    Context 'Regression tests' {

        It 'Single left object' {
            $Actual = $Employee[1] | InnerJoin $Department -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
            Country Id Name                 Department  Age ReportsTo
            ------- -- ----                 ----------  --- ---------
            Germany  2 {Bauer, Engineering} Engineering  31         4
            ' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Single right object' {
            $Actual = $Employee | InnerJoin $Department[0] -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Id Name                   Department  Age ReportsTo
                ------- -- ----                   ----------  --- ---------
                Germany  2 {Bauer, Engineering}   Engineering  31         4
                Germany  6 {Fischer, Engineering} Engineering  29         4
            ' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Single left object and single right object' {
            $Actual = $Employee[1] | InnerJoin $Department[0] -On Country
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Country Id Name                 Department  Age ReportsTo
                ------- -- ----                 ----------  --- ---------
                Germany  2 {Bauer, Engineering} Engineering  31         4
            ' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context 'Casting' {

        BeforeAll {
            $LeftObject =
                [PSCustomObject]@{Left = 'Null';            Value = $Null},
                [PSCustomObject]@{Left = 'Empty String';    Value = ''},
                [PSCustomObject]@{Left = 'String';          Value = 'abc'},
                [PSCustomObject]@{Left = 'Zero';            Value = 0},
                [PSCustomObject]@{Left = 'One';             Value = 1},
                [PSCustomObject]@{Left = 'Empty Array';     Value = ,@()},
                [PSCustomObject]@{Left = 'Array';           Value = @('a', 'b', 'c')},
                [PSCustomObject]@{Left = 'Empty HashTable'; Value = @{}},
                [PSCustomObject]@{Left = 'HashTable';       Value = @{a = 'd'; b = 'e'; c = 'f'}},
                [PSCustomObject]@{Left = 'Empty Object';    Value = [PSCustomObject]@{}},
                [PSCustomObject]@{Left = 'HashTable';       Value = [PSCustomObject]@{a = 'd'; b = 'e'; c = 'f'}}

            $RightObject =
                [PSCustomObject]@{Right = 'Null';            Value = $Null},
                [PSCustomObject]@{Right = 'Empty String';    Value = ''},
                [PSCustomObject]@{Right = 'String';          Value = 'ABC'},
                [PSCustomObject]@{Right = 'Zero';            Value = 0},
                [PSCustomObject]@{Right = 'One';             Value = 1},
                [PSCustomObject]@{Right = 'Empty Array';     Value = ,@()},
                [PSCustomObject]@{Right = 'Array';           Value = @('A', 'B', 'C')},
                [PSCustomObject]@{Right = 'Empty HashTable'; Value = @{}},
                [PSCustomObject]@{Right = 'HashTable';       Value = @{A = 'D'; B = 'E'; C = 'F'}},
                [PSCustomObject]@{Right = 'Empty Object';    Value = [PSCustomObject]@{}},
                [PSCustomObject]@{Right = 'HashTable';       Value = [PSCustomObject]@{A = 'D'; B = 'E'; C = 'F'}}
        }

        It 'Default' {

            $Actual = $LeftObject | Join $RightObject -on Value -Property Left,Right
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Left            Right
                ----            -----
                Null            Null
                Empty String    Empty String
                String          String
                Zero            Zero
                One             One
                Empty Array     Empty Array
                Array           Array
                Empty HashTable Empty HashTable
                HashTable       HashTable
                Empty Object    Empty Object
                HashTable       HashTable'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Strict' {

            $Actual = $LeftObject | Join $RightObject -on Value -Strict -Property Left,Right
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Left            Right
                ----            -----
                Null            Null
                Empty String    Empty String
                String          String
                Zero            Zero
                One             One
                Empty Array     Empty Array
                Array           Array
                Empty HashTable Empty HashTable
                HashTable       HashTable
                Empty Object    Empty Object
                HashTable       HashTable'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Case Sensitive' {

            $Actual = $LeftObject | Join $RightObject -on Value -MatchCase -Property Left,Right
            $Expected =
                if ($PSVersionTable.PSVersion -lt [Version]'7.3.0') {
                    ConvertFrom-SourceTable -ParseRightAligned '
                        Left            Right
                        ----            -----
                        Null            Null
                        Empty String    Empty String
                        Zero            Zero
                        One             One
                        Empty Array     Empty Array
                        Empty HashTable Empty HashTable
                        HashTable       HashTable
                        Empty Object    Empty Object'
                }
                else {
                    ConvertFrom-SourceTable -ParseRightAligned '
                        Left            Right
                        ----            -----
                        Null            Null
                        Empty String    Empty String
                        Zero            Zero
                        One             One
                        Empty Array     Empty Array
                        Empty HashTable Empty HashTable
                        Empty Object    Empty Object'
                }

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Strict / Case Sensitive' {

            $Actual = $LeftObject | Join $RightObject -on Value -Strict -MatchCase -Property Left,Right
            $Expected =
                if ($PSVersionTable.PSVersion -lt [Version]'7.3.0') {
                    ConvertFrom-SourceTable -ParseRightAligned '
                        Left            Right
                        ----            -----
                        Null            Null
                        Empty String    Empty String
                        Zero            Zero
                        One             One
                        Empty Array     Empty Array
                        Empty HashTable Empty HashTable
                        HashTable       HashTable
                        Empty Object    Empty Object'
                }
                else {
                    ConvertFrom-SourceTable -ParseRightAligned '
                        Left            Right
                        ----            -----
                        Null            Null
                        Empty String    Empty String
                        Zero            Zero
                        One             One
                        Empty Array     Empty Array
                        Empty HashTable Empty HashTable
                        Empty Object    Empty Object'
                }

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }


#      _____ _             _     ____                  __ _
#     / ____| |           | |   / __ \                / _| |
#    | (___ | |_ __ _  ___| | _| |  | |_   _____ _ __| |_| | _____      __
#     \___ \| __/ _` |/ __| |/ / |  | \ \ / / _ \ '__|  _| |/ _ \ \ /\ / /
#     ____) | || (_| | (__|   <| |__| |\ V /  __/ |  | | | | (_) \ V  V /
#    |_____/ \__\__,_|\___|_|\_\\____/  \_/ \___|_|  |_| |_|\___/ \_/\_/


    Context "Stackoverflow answers" {

        It "In Powershell, what's the best way to join two tables into one?" { # https://stackoverflow.com/a/45483110

            $leases = ConvertFrom-SourceTable -ParseRightAligned '
                IP                    Name
                --                    ----
                192.168.1.1           Apple
                192.168.1.2           Pear
                192.168.1.3           Banana
                192.168.1.99          FishyPC'

            $reservations = ConvertFrom-SourceTable -ParseRightAligned '
                IP                    MAC
                --                    ---
                192.168.1.1           001D606839C2
                192.168.1.2           00E018782BE1
                192.168.1.3           0022192AF09C
                192.168.1.4           0013D4352A0D'

            $Actual = $reservations | LeftJoin $leases -On IP
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                IP          MAC          Name
                --          ---          ----
                192.168.1.1 001D606839C2 Apple
                192.168.1.2 00E018782BE1 Pear
                192.168.1.3 0022192AF09C Banana
                192.168.1.4 0013D4352A0D  $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'How can i merge multiple CSV files in which two columns have same data using Powershell' { # https://stackoverflow.com/a/63281452

$csv1 = @'
Appli,Folder,FileName,Config,VM1
ABC,Folder1,FN1,Con1,VM11
,Folder2,FN2,Con2,VM12
,Folder3,FN3,Con3,VM13
SID,Folder4,FN4,Con4,VM14
,Folder5,FN5,Con5,VM15
'@ | ConvertFrom-Csv

$csv2 = @'
Appli,Folder,FileName,Config,VM2
ABC,Folder1,FN1,Con1,VM11
,Folder2,FN2,Con2,VM12
,Folder3,FN3,Con3,VM13
SID,Folder4,FN4,Con4,VM14
,Folder5,FN5,Con5,VM15
'@ | ConvertFrom-Csv

$csv3 = @'
Appli,Folder,FileName,Config,VM3
ABC,Folder1,FN1,Con1,VM11
,Folder2,FN2,Con2,VM12
,Folder3,FN3,Con3,VM13
SID,Folder4,FN4,Con4,VM14
,Folder5,FN5,Con5,VM15
'@ | ConvertFrom-Csv

            $Actual = $csv1 | Merge-Object $csv2 -on Folder,FileName | Merge-object $csv3 -on Folder,FileName
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Appli Folder  FileName Config VM1  VM2  VM3
                ----- ------  -------- ------ ---  ---  ---
                ABC   Folder1 FN1      Con1   VM11 VM11 VM11
                      Folder2 FN2      Con2   VM12 VM12 VM12
                      Folder3 FN3      Con3   VM13 VM13 VM13
                SID   Folder4 FN4      Con4   VM14 VM14 VM14
                      Folder5 FN5      Con5   VM15 VM15 VM15'

            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'Combining Multiple CSV Files' { # https://stackoverflow.com/a/54855458
            $CSV1 = ConvertFrom-Csv @'
Name,Attrib1,Attrib2
VM1,111,True
VM2,222,False
'@

            $CSV2 = ConvertFrom-Csv @'
Name,AttribA,Attrib1
VM1,AAA,111
VM3,CCC,333
'@

            $CSV3 = ConvertFrom-Csv @'
Name,Attrib2,AttribB
VM2,False,YYY
VM3,True,ZZZ
'@

            $Actual = $CSV1 | Merge $CSV2 -On Name | Merge $CSV3 -On Name
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
            Name Attrib1 Attrib2 AttribA AttribB
            ---- ------- ------- ------- -------
            VM1  111     True    AAA       $Null
            VM2  222     False     $Null YYY
            VM3  333     True    CCC     ZZZ'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Combine two CSVs - Add CSV as another Column' { # https://stackoverflow.com/a/55431240
            $csv1 = ConvertFrom-Csv @'
VLAN
1
2
3
'@

            $csv2 = ConvertFrom-Csv @'
Host
NETMAN
ADMIN
CLIENT
'@


            $Actual = $csv1 | Join $csv2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                VLAN Host
                ---- ----
                1    NETMAN
                2    ADMIN
                3    CLIENT'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'CMD or Powershell command to combine (merge) corresponding lines from two files' { # https://stackoverflow.com/a/54607741

            $A = ConvertFrom-Csv @'
ID,Name
1,Peter
2,Dalas
'@

            $B = ConvertFrom-Csv @'
Class
Math
Physic
'@

            $Actual = $A | Join $B
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                ID Name  Class
                -- ----  -----
                1  Peter Math
                2  Dalas Physic'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Can I use SQL commands (such as join) on objects in powershell, without any SQL server/database involved?' { # https://stackoverflow.com/a/55431393

        }

        It 'CMD or Powershell command to combine (merge) corresponding lines from two files' { # https://stackoverflow.com/a/54855647

            $Purchase = ConvertFrom-Csv @'
Fruit,Farmer,Region,Water
Apple,Adam,Alabama,1
Cherry,Charlie,Cincinnati,2
Damson,Daniel,Derby,3
Elderberry,Emma,Eastbourne,4
Fig,Freda,Florida,5
'@

            $Selling = ConvertFrom-Csv @'
Fruit,Market,Cost,Tax
Apple,MarketA,10,0.1
Cherry,MarketC,20,0.2
Damson,MarketD,30,0.3
Elderberry,MarketE,40,0.4
Fig,MarketF,50,0.5
'@

            $Actual = $Purchase | Join $Selling -On Fruit
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Fruit      Farmer  Region     Water Market  Cost Tax
                -----      ------  ------     ----- ------  ---- ---
                Apple      Adam    Alabama    1     MarketA 10   0.1
                Cherry     Charlie Cincinnati 2     MarketC 20   0.2
                Damson     Daniel  Derby      3     MarketD 30   0.3
                Elderberry Emma    Eastbourne 4     MarketE 40   0.4
                Fig        Freda   Florida    5     MarketF 50   0.5'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Compare Two CSVs, match the columns on 2 or more Columns, export specific columns from both csvs with powershell' { # https://stackoverflow.com/a/52235645

            $Left = ConvertFrom-Csv @"
Ref_ID,First_Name,Last_Name,DOB
321364060,User1,Micah,11/01/1969
946497594,User2,Acker,05/28/1960
887327716,User3,Aco,06/26/1950
588496260,User4,John,05/23/1960
565465465,User5,Jack,07/08/2020
"@

            $Right = ConvertFrom-Csv @"
First_Name,Last_Name,DOB,City,Document_Type,Filename
User1,Micah,11/01/1969,Parker,Transcript,T4IJZSYO.pdf
User2,Acker,05/28/1960,,Transcript,R4IKTRYN.pdf
User3,Aco,06/26/1950,,Transcript,R4IKTHMK.pdf
User4,John,05/23/1960,,Letter,R4IKTHSL.pdf
"@

            $Actual = $Left | Join $Right -On First_Name, Last_Name, DOB -Property Ref_ID, Filename, First_Name, DOB, Last_Name
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Ref_ID    Filename     First_Name DOB        Last_Name
                ------    --------     ---------- ---        ---------
                321364060 T4IJZSYO.pdf User1      11/01/1969 Micah
                946497594 R4IKTRYN.pdf User2      05/28/1960 Acker
                887327716 R4IKTHMK.pdf User3      06/26/1950 Aco
                588496260 R4IKTHSL.pdf User4      05/23/1960 John'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Merge two CSV files while adding new and overwriting existing entries' { # https://stackoverflow.com/a/54949056

                $configuration = ConvertFrom-SourceTable -ParseRightAligned '
                | path       | item  | value  | type |
                |------------|-------|--------|------|
                | some/path  | item1 | value1 | ALL  |
                | some/path  | item2 | UPDATE | ALL  |
                | other/path | item1 | value2 | SOME |'

                $customization= ConvertFrom-SourceTable -ParseRightAligned '
                | path       | item  | value  | type |
                |------------|-------|--------|------|
                | some/path  | item2 | value3 | ALL  |
                | new/path   | item3 | value3 | SOME |'

            $Actual = $configuration | Merge $customization -on path, item
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                path       item  value  type
                ----       ----  -----  ----
                some/path  item1 value1 ALL
                some/path  item2 value3 ALL
                other/path item1 value2 SOME
                new/path   item3 value3 SOME'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Merging two CSVs and then re-ordering columns on output' { # https://stackoverflow.com/a/54981257

            $Csv1 = ConvertFrom-Csv 'Server,Info
server1,item1
server1,item1'

            $Csv2 = ConvertFrom-Csv 'Server,Info
server2,item2
server2,item2'

            $Actual = $Csv1 | Join $Csv2 -Discern *1, *2
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Server1 Server2 Info1 Info2
                ------- ------- ----- -----
                server1 server2 item1 item2
                server1 server2 item1 item2'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Comparing two CSVs using one property to compare another' { # https://stackoverflow.com/q/55602662

$file1='"FACILITY","FILENAME"
"16","abc.txt"
"16","def.txt"
"12","abc.txt"
"17","def.txt"
"18","abc.txt"
"19","abc.txt"'|convertfrom-csv

$file2='"FACILITY","FILENAME"
"16","jkl.txt"
"16","abc.txt"
"12","abc.txt"
"17","jkl.txt"
"18","jkl.txt"
"19","jkl.txt"'|convertfrom-csv


            $Actual = $file1 | Join $file2 -On Facility, Filename
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                FACILITY FILENAME
                -------- --------
                16       abc.txt
                12       abc.txt
            '
            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'Merge two CSV files while adding new and overwriting existing entries' { # https://stackoverflow.com/a/54949056

            $configuration = ConvertFrom-SourceTable -ParseRightAligned '
                | path       | item  | value  | type |
                |------------|-------|--------|------|
                | some/path  | item1 | value1 | ALL  |
                | some/path  | item2 | UPDATE | ALL  |
                | other/path | item1 | value2 | SOME |
                | other/path | item1 | value3 | ALL  |
            '
            $customization= ConvertFrom-SourceTable -ParseRightAligned '
                | path       | item  | value  | type |
                |------------|-------|--------|------|
                | some/path  | item2 | value3 | ALL  |
                | new/path   | item3 | value3 | SOME |
                | new/path   | item3 | value4 | ALL  |
            '

            $Actual = $configuration | Merge $customization -on path, item
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                path       item  value  type
                ----       ----  -----  ----
                some/path  item1 value1 ALL
                some/path  item2 value3 ALL
                other/path item1 value2 SOME
                other/path item1 value3 ALL
                new/path   item3 value3 SOME
                new/path   item3 value4 ALL
            '
            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'Efficiently merge large object datasets having mulitple matching keys' { # https://stackoverflow.com/a/55543321

            $dataset1 = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY    ZY
                - -    --    --
                1 val1 foo1  bar1
                2 val2 foo2  bar2
                3 val3 foo3  bar3
                4 val4 foo4  bar4
                4 val4 foo4a bar4a
                5 val5 foo5  bar5
                6 val6 foo6  bar6
            '
            $dataset2 = ConvertFrom-SourceTable -ParseRightAligned '
                A B    ABC   GH
                - -    ---   --
                3 val3 foo3  bar3
                4 val4 foo4  bar4
                5 val5 foo5  bar5
                5 val5 foo5a bar5a
                6 val6 foo6  bar6
                7 val7 foo7  bar7
                8 val8 foo8  bar8
            '

            $Actual = $Dataset1 | FullJoin $dataset2 -On A, B
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY      ZY      ABC    GH
                - -    --      --      ---    --
                1 val1 foo1    bar1     $Null  $Null
                2 val2 foo2    bar2     $Null  $Null
                3 val3 foo3    bar3    foo3   bar3
                4 val4 foo4    bar4    foo4   bar4
                4 val4 foo4a   bar4a   foo4   bar4
                5 val5 foo5    bar5    foo5   bar5
                5 val5 foo5    bar5    foo5a  bar5a
                6 val6 foo6    bar6    foo6   bar6
                7 val7  $Null   $Null  foo7   bar7
                8 val8  $Null   $Null  foo8   bar8
            '
            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $Dataset1 | FullJoin $dataset2 -On *
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY      ZY      ABC    GH
                - -    --      --      ---    --
                1 val1 foo1    bar1     $Null  $Null
                2 val2 foo2    bar2     $Null  $Null
                3 val3 foo3    bar3    foo3   bar3
                4 val4 foo4    bar4    foo4   bar4
                4 val4 foo4a   bar4a   foo4   bar4
                5 val5 foo5    bar5    foo5   bar5
                5 val5 foo5    bar5    foo5a  bar5a
                6 val6 foo6    bar6    foo6   bar6
                7 val7  $Null   $Null  foo7   bar7
                8 val8  $Null   $Null  foo8   bar8
            '
            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $Dataset1 | InnerJoin $dataset2 -On *
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY    ZY    ABC   GH
                - -    --    --    ---   --
                3 val3 foo3  bar3  foo3  bar3
                4 val4 foo4  bar4  foo4  bar4
                4 val4 foo4a bar4a foo4  bar4
                5 val5 foo5  bar5  foo5  bar5
                5 val5 foo5  bar5  foo5a bar5a
                6 val6 foo6  bar6  foo6  bar6
            '
            Compare-PSObject $Actual $Expected | Should -BeNull

            $dsLength = 1000
            $dataset1 = 0..$dsLength | ForEach-Object{
                New-Object psobject -Property @{ A=$_ ; B="val$_" ; XY = "foo$_"; ZY ="bar$_" }
            }
            $dataset2 = ($dsLength/2)..($dsLength*1.5) | ForEach-Object{
                New-Object psobject -Property @{ A=$_ ; B="val$_" ; ABC = "foo$_"; GH ="bar$_" }
            }

            (Measure-Command {$dataset1| FullJoin $dataset2 -On A, B}).TotalSeconds | Should -BeLessThan 10
        }

        It 'PowerShell list combinator - optimize please' { # https://stackoverflow.com/a/57832299

$list1 = ConvertFrom-Csv -Delimiter ';' @'
server
hostname1
hostname2
hostname3
hostname4
hostname5
hostname6
hostname7
'@

$ADscan = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname2;Microsoft Windows Server 2012 R2 Datacenter
hostname3;Microsoft Windows Server 2008 R2 Standard
'@

$export2 = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname1;w2k12
hostname2;w2k12
hostname3;w2k8
hostname4;w2k8
hostname5;w2k16
'@

$export3 = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname2.suffix;windows server 2012
hostname3.suffix;windows server 2008
hostname6.suffix;windows server 2008
'@

$Actual = $List1 |
    Merge $ADScan -On Server |
    Merge $export2 -On Server |
    Merge ($export3 | Select-Object @{n='Server';e={$_.Server.Split('.', 2)[0]}}, OS) -On Server

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                server    OS
                ------    --
                hostname1 w2k12
                hostname2 windows server 2012
                hostname3 windows server 2008
                hostname4 w2k8
                hostname5 w2k16
                hostname6 windows server 2008
                hostname7               $Null'

            Compare-PSObject $Actual $Expected | Should -BeNull


$Actual = $List1 |
    Merge $ADScan -On Server |
    Merge $export2 -On Server -Discern '',Export2 |
    Merge ($export3 | Select-Object @{n='Server';e={$_.Server.Split('.', 2)[0]}}, OS) -On Server -Discern '',Export3

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
server    OS                                          Export3OS           Export2OS
------    ------------------------------------------- ------------------- ---------
hostname1                                       $Null               $Null w2k12
hostname2 Microsoft Windows Server 2012 R2 Datacenter windows server 2012 w2k12
hostname3 Microsoft Windows Server 2008 R2 Standard   windows server 2008 w2k8
hostname4                                       $Null               $Null w2k8
hostname5                                       $Null               $Null w2k16
hostname6                                       $Null windows server 2008     $Null
hostname7                                       $Null               $Null     $Null'

            # Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'Which operator provides quicker output -match -contains or Where-Object for large CSV files' { # https://stackoverflow.com/a/58474740

$AAA = ConvertFrom-Csv @'
Number,Name,Domain
Z001,ABC,Domain1
Z002,DEF,Domain2
Z003,GHI,Domain3
'@

$BBB = ConvertFrom-Csv @'
Number,Name,Domain
Z001,ABC,Domain1
Z002,JKL,Domain2
Z004,MNO,Domain4
'@

$CCC = ConvertFrom-Csv @'
Number,Name,Domain
Z005,PQR,Domain2
Z001,ABC,Domain1
Z001,STU,Domain2
'@

$DDD = ConvertFrom-Csv @'
Number,Name,Domain
Z005,VWX,Domain4
Z006,XYZ,Domain1
Z001,ABC,Domain3
'@

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number -Discern AAA, BBB, CCC, DDD

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Number AAAName BBBName CCCName DDDName AAADomain BBBDomain CCCDomain DDDDomain
                ------ ------- ------- ------- ------- --------- --------- --------- ---------
                Z001   ABC     ABC     ABC     ABC     Domain1   Domain1   Domain1   Domain3
                Z001   ABC     ABC     STU     ABC     Domain1   Domain1   Domain2   Domain3
                Z002   DEF     JKL       $Null   $Null Domain2   Domain2       $Null     $Null
                Z003   GHI       $Null   $Null   $Null Domain3       $Null     $Null     $Null
                Z004     $Null MNO       $Null   $Null     $Null Domain4       $Null     $Null
                Z005     $Null   $Null PQR     VWX         $Null     $Null Domain2   Domain4
                Z006     $Null   $Null   $Null XYZ         $Null     $Null     $Null Domain1'

            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number -Discern *1,*2,*3,*4

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Number Name1  Name2  Name3  Name4  Domain1  Domain2  Domain3  Domain4
                ------ ------ ------ ------ ------ -------- -------- -------- --------
                Z001   ABC    ABC    ABC    ABC    Domain1  Domain1  Domain1  Domain3
                Z001   ABC    ABC    STU    ABC    Domain1  Domain1  Domain2  Domain3
                Z002   DEF    JKL     $Null  $Null Domain2  Domain2     $Null    $Null
                Z003   GHI     $Null  $Null  $Null Domain3     $Null    $Null    $Null
                Z004    $Null MNO     $Null  $Null    $Null Domain4     $Null    $Null
                Z005    $Null  $Null PQR    VWX       $Null    $Null Domain2  Domain4
                Z006    $Null  $Null  $Null XYZ       $Null    $Null    $Null Domain1'

            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number -Discern *2,*3,*4

            # Number Name Name2 Name3 Name4 Domain  Domain2 Domain3 Domain4
            # ------ ---- ----- ----- ----- ------  ------- ------- -------
            # Z001   ABC  ABC   ABC   ABC   Domain1 Domain1 Domain1 Domain3
            # Z001   ABC  ABC   STU   ABC   Domain1 Domain1 Domain2 Domain3
            # Z002   DEF  JKL               Domain2 Domain2
            # Z003   GHI                    Domain3
            # Z004        MNO                       Domain4
            # Z005              PQR   VWX                   Domain2 Domain4
            # Z006                    XYZ                           Domain1

            $Expected = @(
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC'; Name3 = 'ABC'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1'; Domain3 = 'Domain1'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC'; Name3 = 'STU'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1'; Domain3 = 'Domain2'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z002'; Name = 'DEF', 'JKL'; Name3 = $Null; Name4 = $Null; Domain = 'Domain2', 'Domain2'; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z003'; Name = 'GHI', $Null; Name3 = $Null; Name4 = $Null; Domain = 'Domain3', $Null; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z004'; Name = $Null, 'MNO'; Name3 = $Null; Name4 = $Null; Domain = $Null, 'Domain4'; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z005'; Name = $Null, $Null; Name3 = 'PQR'; Name4 = 'VWX'; Domain = $Null, $Null; Domain3 = 'Domain2'; Domain4 = 'Domain4'}
                [pscustomobject]@{Number = 'Z006'; Name = $Null, $Null; Name3 = $Null; Name4 = 'XYZ'; Domain = $Null, $Null; Domain3 = $Null; Domain4 = 'Domain1'}
            )

            # Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number -Discern *3,*4

            # Number Name           Name3 Name4 Domain             Domain3 Domain4
            # ------ ----           ----- ----- ------             ------- -------
            # Z001   {ABC, ABC}     ABC   ABC   {Domain1, Domain1} Domain1 Domain3
            # Z001   {ABC, ABC}     STU   ABC   {Domain1, Domain1} Domain2 Domain3
            # Z002   {DEF, JKL}                 {Domain2, Domain2}
            # Z003   {GHI, $null}               {Domain3, $null}
            # Z004   {$null, MNO}               {$null, Domain4}
            # Z005   {$null, $null} PQR   VWX   {$null, $null}     Domain2 Domain4
            # Z006   {$null, $null}       XYZ   {$null, $null}             Domain1

            $Expected = @(
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC'; Name3 = 'ABC'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1'; Domain3 = 'Domain1'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC'; Name3 = 'STU'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1'; Domain3 = 'Domain2'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z002'; Name = 'DEF', 'JKL'; Name3 = $Null; Name4 = $Null; Domain = 'Domain2', 'Domain2'; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z003'; Name = 'GHI', $Null; Name3 = $Null; Name4 = $Null; Domain = 'Domain3', $Null; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z004'; Name = $Null, 'MNO'; Name3 = $Null; Name4 = $Null; Domain = $Null, 'Domain4'; Domain3 = $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z005'; Name = $Null, $Null; Name3 = 'PQR'; Name4 = 'VWX'; Domain = $Null, $Null; Domain3 = 'Domain2'; Domain4 = 'Domain4'}
                [pscustomobject]@{Number = 'Z006'; Name = $Null, $Null; Name3 = $Null; Name4 = 'XYZ'; Domain = $Null, $Null; Domain3 = $Null; Domain4 = 'Domain1'}
            )

            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number -Discern *4

            # Number Name                  Name4 Domain                      Domain4
            # ------ ----                  ----- ------                      -------
            # Z001   {ABC, ABC, ABC}       ABC   {Domain1, Domain1, Domain1} Domain3
            # Z001   {ABC, ABC, STU}       ABC   {Domain1, Domain1, Domain2} Domain3
            # Z002   {DEF, JKL, $null}           {Domain2, Domain2, $null}
            # Z003   {GHI, $null, $null}         {Domain3, $null, $null}
            # Z004   {$null, MNO, $null}         {$null, Domain4, $null}
            # Z005   {$null, $null, PQR}   VWX   {$null, $null, Domain2}     Domain4
            # Z006   {$null, $null, $null} XYZ   {$null, $null, $null}       Domain1

            $Expected = @(
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC', 'ABC'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1', 'Domain1'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC', 'STU'; Name4 = 'ABC'; Domain = 'Domain1', 'Domain1', 'Domain2'; Domain4 = 'Domain3'}
                [pscustomobject]@{Number = 'Z002'; Name = 'DEF', 'JKL', $Null; Name4 = $Null; Domain = 'Domain2', 'Domain2', $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z003'; Name = 'GHI', $Null, $Null; Name4 = $Null; Domain = 'Domain3', $Null, $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z004'; Name = $Null, 'MNO', $Null; Name4 = $Null; Domain = $Null, 'Domain4', $Null; Domain4 = $Null}
                [pscustomobject]@{Number = 'Z005'; Name = $Null, $Null, 'PQR'; Name4 = 'VWX'; Domain = $Null, $Null, 'Domain2'; Domain4 = 'Domain4'}
                [pscustomobject]@{Number = 'Z006'; Name = $Null, $Null, $Null; Name4 = 'XYZ'; Domain = $Null, $Null, $Null; Domain4 = 'Domain1'}
            )

            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $AAA | FullJoin $BBB -On Number | FullJoin $CCC -On Number | FullJoin $DDD -On Number

            # Number Name                       Domain
            # ------ ----                       ------
            # Z001   {ABC, ABC, ABC, ABC}       {Domain1, Domain1, Domain1, Domain3}
            # Z001   {ABC, ABC, STU, ABC}       {Domain1, Domain1, Domain2, Domain3}
            # Z002   {DEF, JKL, $null, $null}   {Domain2, Domain2, $null, $null}
            # Z003   {GHI, $null, $null, $null} {Domain3, $null, $null, $null}
            # Z004   {$null, MNO, $null, $null} {$null, Domain4, $null, $null}
            # Z005   {$null, $null, PQR, VWX}   {$null, $null, Domain2, Domain4}
            # Z006   {$null, $null, $null, XYZ} {$null, $null, $null, Domain1}

            $Expected = @(
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC', 'ABC', 'ABC'; Domain = 'Domain1', 'Domain1', 'Domain1', 'Domain3'}
                [pscustomobject]@{Number = 'Z001'; Name = 'ABC', 'ABC', 'STU', 'ABC'; Domain = 'Domain1', 'Domain1', 'Domain2', 'Domain3'}
                [pscustomobject]@{Number = 'Z002'; Name = 'DEF', 'JKL', $Null, $Null; Domain = 'Domain2', 'Domain2', $Null, $Null}
                [pscustomobject]@{Number = 'Z003'; Name = 'GHI', $Null, $Null, $Null; Domain = 'Domain3', $Null, $Null, $Null}
                [pscustomobject]@{Number = 'Z004'; Name = $Null, 'MNO', $Null, $Null; Domain = $Null, 'Domain4', $Null, $Null}
                [pscustomobject]@{Number = 'Z005'; Name = $Null, $Null, 'PQR', 'VWX'; Domain = $Null, $Null, 'Domain2', 'Domain4'}
                [pscustomobject]@{Number = 'Z006'; Name = $Null, $Null, $Null, 'XYZ'; Domain = $Null, $Null, $Null, 'Domain1'}
            )

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Powershell "join"' { # https://stackoverflow.com/a/58800704
            $cpu = Get-CimInstance -Class Win32_Processor
            $mb = Get-CimInstance -Class Win32_BaseBoard

            $Actual = $cpu | Select-Object Name, Description | Join-Object ($mb | Select-Object Manufacturer, Product)

            $Actual.Name         | Should -Be $cpu.Name
            $Actual.Description  | Should -Be $cpu.Description
            $Actual.Manufacturer | Should -Be $mb.Manufacturer
            $Actual.Product      | Should -Be $mb.Product
        }

        It 'Join/merge arrays' { # https://stackoverflow.com/a/58801439
            $TxtTestcases = ConvertFrom-SourceTable -ParseRightAligned '
                Messages                                   Name   Error
                --------                                   ----   -----
                {\\APPS-EUAUTO1\C$\Users\xautosqa\AppDa... test 1 True
                {[APPS-EUAUTO1] [prep] Setting agent op... test 2 False'

            $RexTestcases = ConvertFrom-SourceTable -ParseRightAligned '
                TestPlan        Script          TestCase        TestData        ErrorCount      ErrorText       DateTime        Elapsed
                --------        ------          --------        --------        ----------      ---------       --------        -------
                D:\XHostMach... D:\XHostMach... rt1             1,\a\""         1               [#ERROR#][AP... 2014-03-28 1... 0:00:18
                D:\XHostMach... D:\XHostMach... rt2             1,\a\""         0                               2014-03-28 1... 0:00:08 '

            $Actual = $TxtTestcases | Join-Object $RexTestcases
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Messages                                   Name   Error TestPlan        Script          TestCase TestData ErrorCount ErrorText       DateTime        Elapsed
                --------                                   ----   ----- --------        ------          -------- -------- ---------- ---------       --------        -------
                {\\APPS-EUAUTO1\C$\Users\xautosqa\AppDa... test 1 True  D:\XHostMach... D:\XHostMach... rt1      1,\a\""  1          [#ERROR#][AP... 2014-03-28 1... 0:00:18
                {[APPS-EUAUTO1] [prep] Setting agent op... test 2 False D:\XHostMach... D:\XHostMach... rt2      1,\a\""  0                          2014-03-28 1... 0:00:08'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Compare two different csv files using PowerShell' { # https://stackoverflow.com/a/58855413

            $Csv2 = ConvertFrom-Csv @'
Client Name,Policy Name,KB Size
hostname1,Company_Policy,487402463
hostname2,Company_Policy,227850336
hostname3,Company_Policy_11,8360960
hostname4,Company_Policy_11,1238838488
hostname1,Company_Policy_55,521423110
hostname10,Company_Policy,28508975
hostname3,Company_Policy_66,295925
hostname5,Company_Policy_22,82001824
hostname2,Company_Policy_33,26176885
hostnameXX,Company_Policy_XXX,0
hostnameXX,Company_Policy_XXX,41806794
hostnameYY,Company_Policy_XXX,41806794
'@

            $Csv1 = ConvertFrom-Csv @'
Client Name,Policy Name,KB Size
hostname1,Company_Policy,487402555
hostname2,Company_Policy,227850666
hostname3,Company_Policy_11,8361200
hostname4,Company_Policy_11,1638838488
hostname1,Company_Policy_55,621423110
hostname10,Company_Policy,28908975
hostname3,Company_Policy_66,295928
hostname5,Company_Policy_22,92001824
hostname2,Company_Policy_33,36176885
hostname22,Company_Policy,291768854
hostname23,Company_Policy,291768854
'@

            $Actual = $CSV2 | FullJoin $CSV1 `
                -On 'Client Name','Policy Name' `
                -Property 'Client Name',
                          'Policy Name',
                          @{'TB Size' = {[math]::Round(($Left['KB Size'] - $Right['KB Size']) / 1GB, 2)}} `
                -Where {[math]::Abs($Left['KB Size'] - $Right['KB Size']) -gt 100MB}

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                    Client Name Policy Name       TB Size
                    ----------- -----------       -------
                    hostname1   Company_Policy       0.45
                    hostname2   Company_Policy       0.21
                    hostname4   Company_Policy_11   -0.37
                    hostname1   Company_Policy_55    0.49
                    hostname1   Company_Policy      -0.45
                    hostname2   Company_Policy      -0.21
                    hostname1   Company_Policy_55   -0.58
                    hostname22  Company_Policy      -0.27
                    hostname23  Company_Policy      -0.27'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'multiple lookup powershell array' { # https://stackoverflow.com/a/58880814

            $List = ConvertFrom-SourceTable -ParseRightAligned '
                org_id  org_name        parent_id
                1       Company         NULL
                2       HR              1
                3       MARKETING       2
                4       FINANCE         1
                5       IT              4'

            $Actual = FullJoin $List parent_id -eq org_id '', 'parent'
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                org_id org_name  parentorg_name parent_id
                ------ --------  -------------- ---------
                1      Company            $Null     $Null
                2      HR        Company        NULL
                3      MARKETING HR             1
                4      FINANCE   Company        NULL
                5      IT        FINANCE        1
                 $Null     $Null MARKETING      2
                 $Null     $Null IT             4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Merge two json objects' { # https://stackoverflow.com/a/45563467

            $Json1 = ConvertFrom-Json '
                {
                  a:{
                    b:"asda"
                  },
                  c:"asdasd"
                }'

            $Json2 = ConvertFrom-Json '
                {
                  a:{
                   b:"d"
                  }
                }'

            $Actual = $Json1 | Merge $Json2
            $Expected = ConvertFrom-Json '
                {
                  "a": {
                    "b": "d"
                  },
                  "c": "asdasd"
                }'

            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $Json1 | Join $Json2
            $Expected = ConvertFrom-Json '
                {
                  "a": [
                    {
                      "b": "asda"
                    },
                    {
                      "b": "d"
                    }
                  ],
                  "c": "asdasd"
                }'
            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Combine JSON objects in PowerShell' { # https://stackoverflow.com/q/57724976

            $aVar = '{ "oldEmployees" : [ { "firstName": "Jane", "lastName": "Doe" }, { "firstName": "John", "lastName": "Doe" } ] }'
            $bVar = '{ "newEmployees" : [ { "firstName": "Joe", "lastName": "Doe" } ] }'

            $Actual = ($aVar | ConvertFrom-Json) | Join ($bVar | ConvertFrom-Json)
            $Expected = ConvertFrom-Json '
                {
                  "oldEmployees": [
                    {
                      "firstName": "Jane",
                      "lastName": "Doe"
                    },
                    {
                      "firstName": "John",
                      "lastName": "Doe"
                    }
                  ],
                  "newEmployees": {
                    "firstName": "Joe",
                    "lastName": "Doe"
                  }
                }'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'How to combine items from one PowerShell Array and one Powershell Object and produce a 3rd PowerShell Object?' { # https://stackoverflow.com/q/63203376

            $vmSizelist = ConvertFrom-SourceTable -ParseRightAligned '
                Name VMSize          ResourceGroup
                VM1  Standard_D2s_v3 RG1
                VM2  Standard_D14_v2 RG2'

            $AllVMSize = ConvertFrom-SourceTable -ParseRightAligned '
                Name            NumberOfCores MemoryInMB MaxDataDiskCount OSDiskSizeInMB ResourceDiskSizeInMB
                Standard_B1ls               1        512                2        1047552                 4096
                Standard_B1ms               1       2048                2        1047552                 4096
                Standard_B1s                1       1024                2        1047552                 4096
                Standard_B2ms               2       8192                4        1047552                16384
                Standard_B2s                2       4096                4        1047552                 8192
                Standard_D2s_v3             2       8192                4        1047552                16384
                Standard_D14_v2            16     114688               64        1047552               819200'

            $Actual = $vmSizelist | Join-Object $AllVMSize -on VMSize -Eq Name -Property Name, VMSize, ResourceGroup, NumberOfCores, MemoryInMB
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Name VMSize          ResourceGroup NumberOfCores MemoryInMB
                ---- ------          ------------- ------------- ----------
                VM1  Standard_D2s_v3 RG1                       2       8192
                VM2  Standard_D14_v2 RG2                      16     114688'

                Compare-PSObject $Actual $Expected | Should -BeNull
            }

        It 'Updating data in .csv without overwriting the existing data / adding new data in powershell' { # https://stackoverflow.com/q/63242408

            $Old = ConvertFrom-SourceTable -ParseRightAligned '
                Date       Filename  Type (BAY) ...
                ----       --------  ---------- ---
                2020-08-01 File1.csv Type 1     Info 1
                2020-08-02 File2.csv Type 2
                2020-08-03 File3.csv Type 3'

            $New = ConvertFrom-SourceTable -ParseRightAligned '
                Date       Filename  Type (BAY) ...
                ----       --------  ---------- ---
                2020-08-04 File2.csv Type 2     Info 2
                2020-08-04 File4.csv Type 4     Info 4'

            $Actual = $Old | Merge-Object $New -on Filename
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Date       Filename  Type (BAY) ...
                ----       --------  ---------- ---
                2020-08-01 File1.csv Type 1     Info 1
                2020-08-04 File2.csv Type 2     Info 2
                2020-08-03 File3.csv Type 3
                2020-08-04 File4.csv Type 4     Info 4'

            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'Match on two columns in two separate csvs then merge one column' { # https://stackoverflow.com/q/39733868

$Source = ConvertFrom-Csv @'
"Employee ID","username","givenname","surname","emailaddress","title","Division","Location"
"204264","ABDUL.JALIL@domain.com","Abdul Jalil","Bin Hajar","Abdul.jalil@domain.com","Warehouse Associate I","Singapore","Singapore, "
"30053","ABEL.BARRAGAN@domain.com","Abel","Barragan","Abel.Barragan@domain.com","Manager, Customer Programs - CMS","Germany","Norderstedt, "
'@

$Change = ConvertFrom-Csv @'
givenname,surname,samaccountname,emailaddress,mail,country,city,state
Abigai,Teoyotl Rugerio,Abigai.Teoyotl,Abigai.TeoyotlRugerio@domain.com,Abigai.TeoyotlRugerio@domain.com,MX,,
Adekunle,Adesiyan,Adekunle.Adesiyan,Adekunle.Adesiyan@domain.com,Adekunle.Adesiyan@domain.com,US,VALENCIA,CALIFORNIA
'@

            # (some) Properties do not show issue !!!
            $Source | Update-Object $Change givenname,surname

        }

        It 'How to join two object arrays in Powershell' { # https://stackoverflow.com/a/63576946

            $Array1 = @{Id=1; Count=24},
                      @{Id=2; Count=34}

            $Array2 = @{Id=1; Name="Some name"},
                      @{Id=2; Name="Some other name"}

            $Actual = $Array1 | Join $Array2 -On Id
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Count Id Name
                ----- -- ----
                   24  1 Some name
                   34  2 Some other name'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        it 'On expression' { # https://stackoverflow.com/q/70120859

            $Domain1 = ConvertFrom-SourceTable -ParseRightAligned '
                DN                                          FirstName LastName
                --                                          --------- --------
                CN=E466097,OU=Sales,DC=Domain1,DC=COM       Karen     Berge
                CN=E000001,OU=HR,DC=Domain1,DC=COM          John      Doe
                CN=E475721,OU=Engineering,DC=Domain1,DC=COM Maria     Garcia
                CN=E890223,OU=Engineering,DC=Domain1,DC=COM James     Johnson
                CN=E235479,OU=HR,DC=Domain1,DC=COM          Mary      Smith
                CN=E964267,OU=Sales,DC=Domain1,DC=COM       Jeff      Smith'

            $Domain2 = ConvertFrom-SourceTable -ParseRightAligned '
                DN                                    Name
                --                                    ----
                CN=E000001,OU=Users,DC=Domain2,DC=COM John Doe
                CN=E235479,OU=Users,DC=Domain2,DC=COM Mary Smith
                CN=E466097,OU=Users,DC=Domain2,DC=COM Karen Berge
                CN=E475721,OU=Users,DC=Domain2,DC=COM Maria Garcia
                CN=E890223,OU=Users,DC=Domain2,DC=COM James Johnson
                CN=E964267,OU=Users,DC=Domain2,DC=COM Jeff Smith'

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Domain1DN                                   Domain2DN                             FirstName LastName Name
                ---------                                   ---------                             --------- -------- ----
                CN=E466097,OU=Sales,DC=Domain1,DC=COM       CN=E466097,OU=Users,DC=Domain2,DC=COM Karen     Berge    Karen Berge
                CN=E000001,OU=HR,DC=Domain1,DC=COM          CN=E000001,OU=Users,DC=Domain2,DC=COM John      Doe      John Doe
                CN=E475721,OU=Engineering,DC=Domain1,DC=COM CN=E475721,OU=Users,DC=Domain2,DC=COM Maria     Garcia   Maria Garcia
                CN=E890223,OU=Engineering,DC=Domain1,DC=COM CN=E890223,OU=Users,DC=Domain2,DC=COM James     Johnson  James Johnson
                CN=E235479,OU=HR,DC=Domain1,DC=COM          CN=E235479,OU=Users,DC=Domain2,DC=COM Mary      Smith    Mary Smith
                CN=E964267,OU=Sales,DC=Domain1,DC=COM       CN=E964267,OU=Users,DC=Domain2,DC=COM Jeff      Smith    Jeff Smith'

            $Actual = $Domain1 |Join $Domain2 -On { [RegEx]::Match($_.DN, '(?<=CN=)E\d{6}(?=,OU=)') } -Name Domain1,Domain2
            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $Domain1 |Join $Domain2 -On { $_.FirstName, $_.LastName -Join ' ' } -Eq Name -Name Domain1,Domain2
            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        it 'Compare two different csv files using PowerShell' { # https://stackoverflow.com/q/58850132
        $Csv1 = ConvertFrom-Csv @'
name,surname,height,city,county,state,zipCode
John,Doe,120,jefferson,Riverside,NJ,8075
Jack,Yan,220,Phila,Riverside,PA,9119
Jill,Fan,120,jefferson,Riverside,NJ,8075
Steve,Tan,220,Phila,Riverside,PA,9119
Alpha,Fan,120,jefferson,Riverside,NJ,8075
'@

        $Csv2 = ConvertFrom-Csv @'
name,surname,height,city,county,state,zipCode
John,Doe,120,jefferson,Riverside,NJ,8075
Jack,Yan,220,Phila,Riverside,PA,9119
Jill,Fan,120,jefferson,Riverside,NJ,8075
Steve,Tan,220,Phila,Riverside,PA,9119
Bravo,Tan,220,Phila,Riverside,PA,9119
'@

            $Expected = ConvertFrom-Csv @'
name,surname,height,city,county,state,zipCode
Alpha,Fan,120,jefferson,Riverside,NJ,8075
Bravo,Tan,220,Phila,Riverside,PA,9119
'@

            $Actual = $Csv1 |OuterJoin $Csv2
            Compare-PSObject $Actual $Expected | Should -BeNull

            $dataset1 = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY    ZY
                - -    --    --
                1 val1 foo1  bar1
                2 val2 foo2  bar2
                3 val3 foo3  bar3
                4 val4 foo4  bar4
                4 val4 foo4a bar4a
                5 val5 foo5  bar5
                6 val6 foo6  bar6
            '
            $dataset2 = ConvertFrom-SourceTable -ParseRightAligned '
                A B    ABC   GH
                - -    ---   --
                3 val3 foo3  bar3
                4 val4 foo4  bar4
                5 val5 foo5  bar5
                5 val5 foo5a bar5a
                6 val6 foo6  bar6
                7 val7 foo7  bar7
                8 val8 foo8  bar8
            '

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                A B    XY     ZY     ABC    GH
                - -    --     --     ---    --
                1 val1 foo1   bar1    $Null  $Null
                2 val2 foo2   bar2    $Null  $Null
                7 val7  $Null  $Null foo7   bar7
                8 val8  $Null  $Null foo8   bar8'

            $Actual = $Dataset1 |OuterJoin $Dataset2 -on a,b
            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = $Dataset1 |Get-Difference $Dataset2 -on b
            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It "Transpose table" { # https://stackoverflow.com/q/76288937/1701026

            $Csv = @'
"@","A","B","C"
"1","D","E","F"
"2","G","H","I"
"3","J","K","L"
'@

            $Table = @()
            # Get-Content .\My.csv |Foreach-Object {
            $Csv -Split '\r?\n' |Foreach-Object {
                $Table = $Table |FullJoin $_.Split(',')
            }
            $Transposed = $Table |Foreach-Object {
                $_ -Join ','
            }
            ($Transposed |Out-String).Trim() | Should -Be @'
"@","1","2","3"
"A","D","G","J"
"B","E","H","K"
"C","F","I","L"
'@

            $Data = ConvertFrom-Csv $Csv
            $Names = $Data[0].PSObject.Properties.Name
            $Last = $Names.get_Count() - 1
            $Table = @() |FullJoin $Names[1..$Last] -Name $Names[0]
            $Data |Foreach-Object {
                $Values = $_.PSObject.Properties.Value
                $Last = $Values.get_Count() - 1
                $Table =  $Table |FullJoin $Values[1..$Last] -Name $Values[0]
            }

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                @ 1 2 3
                - - - -
                A D G J
                B E H K
                C F I L'

            Compare-PSObject $Table $Expected | Should -BeNull
        }
    }


#      _____ _ _   _    _       _
#     / ____(_) | | |  | |     | |
#    | |  __ _| |_| |__| |_   _| |__
#    | | |_ | | __|  __  | | | | '_ \
#    | |__| | | |_| |  | | |_| | |_) |
#     \_____|_|\__|_|  |_|\__,_|_.__/

    Context '#9 `-where` condition not work correctly if function imported via `Import-module`' { # https://github.com/iRon7/Join-Object/issues/9

        BeforeAll {
            $LeftObject = ConvertFrom-SourceTable -ParseRightAligned '
                volume                                  vol-state lun-serial
                ------                                  --------- ----------
                cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH
                cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh'

            $RightObject = ConvertFrom-SourceTable -ParseRightAligned '
                lun-serial   host-DiskNumber host-OperationalStatus
                ----------   --------------- ----------------------
                QvaAo+E56ZNH 11              Online
                QvaAo+E56ZNh 34              Offline'
        }

        It 'Case insensitive' {

            $Actual = $LeftObject | LeftJoin $RightObject -On lun-serial
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                volume                                  vol-state lun-serial   host-DiskNumber host-OperationalStatus
                ------                                  --------- ----------   --------------- ----------------------
                cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH 11              Online
                cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNh 34              Offline
                cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNH 11              Online
                cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh 34              Offline'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Case sensitive' {

            $Actual = $LeftObject | LeftJoin $RightObject -On lun-serial -CaseSensitive
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                volume                                  vol-state lun-serial   host-DiskNumber host-OperationalStatus
                ------                                  --------- ----------   --------------- ----------------------
                cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH 11              Online
                cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh 34              Offline'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context "Dictionaries for input" { # https://github.com/iRon7/Join-Object/issues/10

        It 'InnerJoin' {

            $hostNumaInfo = @{
                TypeId            = 0
                CpuID             = 11, 10, 9, 8
                MemoryRangeBegin  = 0
                MemoryRangeLength = 34259832832
                PciId             = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
            }

            $hostPciInfo = @{
                Id           = '0000:00:00.0'
                ClassId      = 1536
                Bus          = 0
                Slot         = 0
                Function     = 0
                VendorId     = -32634
                SubVendorId  = -32634
                VendorName   = 'Intel Corporation'
                DeviceId     = 12032
                SubDeviceId  = 0
                ParentBridge = ''
                DeviceName   = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
            }

            $Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On PciId -Equals Id
            $Actual | Should -BeNullOrEmpty
            $Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On TypeId -Equals Bus
            $Expected = [pscustomobject]@{
                    'TypeId' = 0
                    'CpuID' = 11, 10, 9, 8
                    'PciId' = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
                    'MemoryRangeLength' = 34259832832
                    'MemoryRangeBegin' = 0
                    'DeviceId' = 12032
                    'VendorName' = 'Intel Corporation'
                    'Bus' = 0
                    'Id' = '0000:00:00.0'
                    'ParentBridge' = ''
                    'Slot' = 0
                    'DeviceName' = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
                    'VendorId' = -32634
                    'Function' = 0
                    'SubDeviceId' = 0
                    'ClassId' = 1536
                    'SubVendorId' = -32634
            }
            Compare-PSObject $Actual $Expected | Should -BeNull

        }

        It 'FullJoin on hashtables' {

            $Employee =
                @{'Id' = 1; 'Name' = 'Aerts'; 'Country' = 'Belgium'; 'Department' = 'Sales'; 'Age' = 40; 'ReportsTo' = 5},
                @{'Id' = 2; 'Name' = 'Bauer'; 'Country' = 'Germany'; 'Department' = 'Engineering'; 'Age' = 31; 'ReportsTo' = 4},
                @{'Id' = 3; 'Name' = 'Cook'; 'Country' = 'England'; 'Department' = 'Sales'; 'Age' = 69; 'ReportsTo' = 1},
                @{'Id' = 4; 'Name' = 'Duval'; 'Country' = 'France'; 'Department' = 'Engineering'; 'Age' = 21; 'ReportsTo' = 5},
                @{'Id' = 5; 'Name' = 'Evans'; 'Country' = 'England'; 'Department' = 'Marketing'; 'Age' = 35; 'ReportsTo' = ''},
                @{'Id' = 6; 'Name' = 'Fischer'; 'Country' = 'Germany'; 'Department' = 'Engineering'; 'Age' = 29; 'ReportsTo' = 4}

            $Department =
                @{'Name' = 'Engineering'; 'Country' = 'Germany'},
                @{'Name' = 'Marketing'; 'Country' = 'England'},
                @{'Name' = 'Sales'; 'Country' = 'France'},
                @{'Name' = 'Purchase'; 'Country' = 'France'}

            $Actual = $Employee | FullJoin $Department -On Country -Discern Employee, Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 1 Aerts        Belgium Sales        40         5          $Null
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Ordered for input' {

            $hostNumaInfo = [Ordered]@{
                TypeId            = 0
                CpuID             = 11, 10, 9, 8
                MemoryRangeBegin  = 0
                MemoryRangeLength = 34259832832
                PciId             = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
            }

            $hostPciInfo = [Ordered]@{
                Id           = '0000:00:00.0'
                ClassId      = 1536
                Bus          = 0
                Slot         = 0
                Function     = 0
                VendorId     = -32634
                SubVendorId  = -32634
                VendorName   = 'Intel Corporation'
                DeviceId     = 12032
                SubDeviceId  = 0
                ParentBridge = ''
                DeviceName   = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
            }

            $Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On PciId -Equals Id
            $Actual | Should -BeNullOrEmpty
            $Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On TypeId -Equals Bus
            $Expected = [pscustomobject]@{
                    'TypeId' = 0
                    'CpuID' = 11, 10, 9, 8
                    'PciId' = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
                    'MemoryRangeLength' = 34259832832
                    'MemoryRangeBegin' = 0
                    'DeviceId' = 12032
                    'VendorName' = 'Intel Corporation'
                    'Bus' = 0
                    'Id' = '0000:00:00.0'
                    'ParentBridge' = ''
                    'Slot' = 0
                    'DeviceName' = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
                    'VendorId' = -32634
                    'Function' = 0
                    'SubDeviceId' = 0
                    'ClassId' = 1536
                    'SubVendorId' = -32634
            }
            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context 'Error handling' {

        It 'Object required' {
            { Join-Object } | Should -Throw -ExceptionType ArgumentException
        }

        It 'Left member not found' {
            { $Employee | Join $Department -On Foo } | Should -Throw -ExceptionType MissingMemberException
        }

        It 'Right member not found' {
            { $Employee | Join $Department -On Name -Equals Bar } | Should -Throw -ExceptionType MissingMemberException
        }

        It 'Join-Object: Invalid cross join' {
            { $Employee | CrossJoin $Department -Using { } } | Should -Throw -ExceptionType ArgumentException
        }
    }

    Context '#14 Support scalar arrays' { # https://github.com/iRon7/Join-Object/issues/14

        BeforeAll {
            $a = 'a1', 'a2', 'a3', 'a4'
            $b = 'b1', 'b2', 'b3', 'b4'
            $c = 'c1', 'c2', 'c3', 'c4'
            $d = 'd1', 'd2', 'd3', 'd4'
        }

        It 'Join chain' {

            $Actual = $a |Join $b |Join $c |Join $d |ForEach-Object { $_ -Join '|' }
            $Expected =
                'a1|b1|c1|d1',
                'a2|b2|c2|d2',
                'a3|b3|c3|d3',
                'a4|b4|c4|d4'

            $Actual | Should -Be $Expected
        }

        It 'Join chain with subsequent naming' {

            $Actual = $a |Join $b |Join $c |Join $d -Name a, b, c, d
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                a  b  c  d
                -  -  -  -
                a1 b1 c1 d1
                a2 b2 c2 d2
                a3 b3 c3 d3
                a4 b4 c4 d4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Join object collection with scalar colection' {

            $Actual = $Department |Join $a
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Name        Country <Value>
                ----        ------- -------
                Engineering Germany a1
                Marketing   England a2
                Sales       France  a3
                Purchase    France  a4'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Join scalar collection with object colection' {

            $Actual = $a |Join $Department
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                <Value> Name        Country
                ------- ----        -------
                a1      Engineering Germany
                a2      Marketing   England
                a3      Sales       France
                a4      Purchase    France'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Outer join on scalar collections' {

            $a |OuterJoin $b | Should -be 'a1', 'a2', 'a3', 'a4', 'b1', 'b2', 'b3', 'b4'

            1..5 |OuterJoin @(3..7) | Should -be 1, 2, 6, 7
        }

        It 'Scalar collection with embedded array' {

            $a = 'foo', 'bar'
            $b = 'baz', @(1,2)
            $c = 'and', 'so on'

            $Result = $a |Join $b |Join $c |ForEach-Object {
                $aElem, $bElem, $cElem = $_
                "$aElem | $bElem | $cElem"
            }

            $Result[0] | Should -be 'foo | baz | and'
            $Result[1] | Should -be 'bar | 1 2 | so on'

        }
    }

    Context '#19 Deal with empty (and $Null) inputs' { # https://github.com/iRon7/Join-Object/issues/19

        It 'Join empty (and $Null) inputs' {

            @() |Join $Employee | Should -benull

            $Employee |Join $Null | Should -benull

            $Employee |Join @() | Should -benull

            @{id = 1; name = 'one'} |Join @{id = 2; name = 'Two'} -On id | Should -benull

            @{id = 1; name = 'one'} |Join @{id = 2; name = 'Two'} -On id |Join @{id = 3; name = 'Three'} -On id | Should -benull

            @() |Join @{id = 3; name = 'Three'} -On id | Should -benull # Self join

            Join @{id = 3; name = 'Three'} -On id | Should -BeNull

        }
    }

    Context '#21 merge repeating names' { # https://github.com/iRon7/Join-Object/issues/21

        It 'should collect sums' {

            $Actual = 0..9 |Join 3, 5, 6 |Join 1, 2, 4 |Join 7, 8, 9 -Name Index, Sum, Sum, Sum
            $Expected = @(
                [PSCustomObject]@{Index = 0; Sum = 3, 1, 7}
                [PSCustomObject]@{Index = 1; Sum = 5, 2, 8}
                [PSCustomObject]@{Index = 2; Sum = 6, 4, 9}
            )
            Compare-PSObject $Actual $Expected | Should -BeNull

        }
    }

    Context '#27 MissingLeftProperty: Join-Object : The property xxx cannot be found on the left object' { # https://github.com/iRon7/Join-Object/issues/27

        It 'MissingLeftProperty' {

            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id EmployeeName Country Department  Age ReportsTo DepartmentName
                -- ------------ ------- ----------  --- --------- --------------
                 1 Aerts        Belgium Sales        40         5          $Null
                 2 Bauer        Germany Engineering  31         4 Engineering
                 3 Cook         England Sales        69         1 Marketing
                 4 Duval        France  Engineering  21         5 Sales
                 4 Duval        France  Engineering  21         5 Purchase
                 5 Evans        England Marketing    35           Marketing
                 6 Fischer      Germany Engineering  29         4 Engineering'

            $Actual = Join -JoinType Left -LeftObject $Employee -RightObject $Department -On Country -Discern Employee, Department
            Compare-PSObject $Actual $Expected | Should -BeNull

            $Actual = LeftJoin -LeftObject $Employee -RightObject $Department -On Country -Discern Employee, Department
            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context "#28 FullJoin doesn't work properly when joining multiple array when one of the array is empty" { # https://github.com/iRon7/Join-Object/issues/28

        BeforeAll {
            $arrayList1 = [Object[]]@('james', 'henry')
            $arrayList2 = [Object[]]@()
        }

        It 'From pipeline with empty right object' {

            $Actual = $arrayList1 |FullJoin $arrayList2 -Name arrayList1, arrayList2
            $Expected =
                [pscustomobject]@{arrayList1 = 'james'; arrayList2 = $Null},
                [pscustomobject]@{arrayList1 = 'henry'; arrayList2 = $Null}

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Named left parameter with empty right object' {

            $Actual = FullJoin -Left $arrayList1 -Right $arrayList2 -Name arrayList1, arrayList2
            $Expected =
                [pscustomobject]@{arrayList1 = 'james'; arrayList2 = $Null},
                [pscustomobject]@{arrayList1 = 'henry'; arrayList2 = $Null}

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Empty left object with named right parameter' {

            $Actual = FullJoin -Left $arrayList2 -Right $arrayList1 -Name arrayList1, arrayList2
            $Expected =
                [pscustomobject]@{arrayList1 = $Null; arrayList2 = 'james'},
                [pscustomobject]@{arrayList1 = $Null; arrayList2 = 'henry'}

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context "#42 An outer join on an empty pipeline should return the right object" { # https://github.com/iRon7/Join-Object/issues/42

        BeforeAll {
            $a = 'a1', 'a2', 'a3', 'a4'
            $b = 'b1', 'b2', 'b3', 'b4'
        }

        It 'Inner join with empty pipeline and scalar collection' {

            $Actual = @() | Join $a | Join $b | Should -BeNull
        }

        It 'Inner join with empty pipeline and scalar collection' {

            $Actual = @() | FullJoin $a | FullJoin $b |ForEach-Object { "$_" }
            $Expected =
                'a1 b1',
                'a2 b2',
                'a3 b3',
                'a4 b4'

            $Actual | Should -Be $Expected
        }

        It 'Inner join with empty pipeline and object collection' {

            $Actual = @() | FullJoin $Employee -On Country
            Compare-PSObject $Actual $Employee | Should -BeNull
        }
    }

    Context '#43 Scalar joins should use `-On` and `-Equals` for naming' { # https://github.com/iRon7/Join-Object/issues/43

        it 'Left scalar collection with -On' {

            $Actual = 1,2,3 | Join $Employee -On Id
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country  Department  Age ReportsTo
                -- ----    -------- ----------  --- ---------
                 1 Aerts   Belgium  Sales        40         5
                 2 Bauer   Germany  Engineering  31         4
                 3 Cook    England  Sales        69         1'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Right scalar collection with -On' {
            $Actual = $Employee | Join 1,2,3 -On Id
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country  Department  Age ReportsTo
                -- ----    -------- ----------  --- ---------
                 1 Aerts   Belgium  Sales        40         5
                 2 Bauer   Germany  Engineering  31         4
                 3 Cook    England  Sales        69         1'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        it 'Single left property collection with -On' {

            $Single =
                [PSCustomObject]@{ Id = 1 },
                [PSCustomObject]@{ Id = 2 },
                [PSCustomObject]@{ Id = 3 }

            $Actual = $Single | Join $Employee -On Id
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country  Department  Age ReportsTo
                -- ----    -------- ----------  --- ---------
                 1 Aerts   Belgium  Sales        40         5
                 2 Bauer   Germany  Engineering  31         4
                 3 Cook    England  Sales        69         1'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        It 'Single right property collection with -On' {

            $Single =
                [PSCustomObject]@{ Id = 1 },
                [PSCustomObject]@{ Id = 2 },
                [PSCustomObject]@{ Id = 3 }

            $Actual = $Employee | Join $Single -On Id
            $Expected = ConvertFrom-SourceTable -ParseRightAligned '
                Id Name    Country  Department  Age ReportsTo
                -- ----    -------- ----------  --- ---------
                 1 Aerts   Belgium  Sales        40         5
                 2 Bauer   Germany  Engineering  31         4
                 3 Cook    England  Sales        69         1'

            Compare-PSObject $Actual $Expected | Should -BeNull
        }
    }

    Context '#45 incorrect automatically named FullJoin -on -eq' {

        it 'Scalars' {

            $Actual = 1,2,3 | FullJoin 2,3,4 -On Left -eq Right
            $Expected = @(
                [PSCustomObject]@{ 'Left' = 1;     'Right' = $null },
                [PSCustomObject]@{ 'Left' = 2;     'Right' = 2 },
                [PSCustomObject]@{ 'Left' = 3;     'Right' = 3 },
                [PSCustomObject]@{ 'Left' = $null; 'Right' = 4 }
            )

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

        it 'Objects' {

            $a = [PSCustomObject]@{ AId = 1; AName = 'A' },
                 [PSCustomObject]@{ AId = 2; AName = 'B' },
                 [PSCustomObject]@{ AId = 3; AName = 'C' }
            $b = [PSCustomObject]@{ BId = 2; BName = 'B' },
                 [PSCustomObject]@{ BId = 3; BName = 'C' },
                 [PSCustomObject]@{ BId = 4; BName = 'D' }

            $Actual = $a | FullJoin $b -On AId -Eq BId
            $Expected = @(
                [PSCustomObject]@{ AId = 1;     AName = 'A';   BId = $Null; BName = $Null },
                [PSCustomObject]@{ AId = 2;     AName = 'B';   BId = 2;     BName = 'B' },
                [PSCustomObject]@{ AId = 3;     AName = 'C';   BId = 3;     BName = 'C' },
                [PSCustomObject]@{ AId = $Null; AName = $Null; BId = 4;     BName = 'D' }
            )

            Compare-PSObject $Actual $Expected | Should -BeNull
        }

    }

    Context '#46 issue #43 should exclude ScriptBlocks' {

        it 'Merge strings' { #https://stackoverflow.com/questions/76534806/parsing-files-and-replacing-matching-entries-based-on-single-element

            $File1 = @'
2   "Key1"   "ContentAASD#@!"   |
3   "Key2"   "Conte111111#@!"   |
4   "Key112"   "Keep me"   |
'@ -Split '[\r?\n]'

                $File2 = @'
2   "Key1"   "I'm correct one"   |
3   "Key2"   "Me too"   |
'@ -Split '[\r?\n]'

            $File1 | Merge $File2 -on { ("$_""" -split '"')[1] } | Where-Object { $_ } | Should -Be @(
                '2   "Key1"   "I''m correct one"   |',
                '3   "Key2"   "Me too"   |',
                '4   "Key112"   "Keep me"   |'
            )
        }
    }

    Context '#52 cross join with empty right table causes error' {

        it 'Results' {

            $results = @{
                principals = @()
                roles = @(@{ c = 5; d = 6 }, @{ c = 7; d = 8 })
            }

            Join-object -LeftObject $results.roles -RightObject $results.principals -JoinType Cross | Should -BeNullOrEmpty
        }


    }

    Context '#53 possible to force discern to simulate SQL "as" statement to rename columns' {

        it 'Results' {
            $a = ConvertFrom-Csv @'
c1,c2,c3
11,12,13
21,12,13
'@

            $b = ConvertFrom-Csv @'
c1,c2,c3
11,22,23
21,22,23
'@

            $Prefix = 'du_'
            $pb = $b | ForEach-Object {
                $Dictionary = [Ordered]@{}
                $_.PSObject.Properties.foreach{ $Dictionary[$Prefix + $_.Name] = $_.Value }
                $Dictionary
            }

        $Actual = $a | Join $pb -on c1 -eq "$($Prefix)c1"
        $Expected = ConvertFrom-SourceTable -ParseRightAligned '
        c1 c2 c3 du_c1 du_c2 du_c3
        -- -- -- ----- ----- -----
        11 12 13 11    22    23
        21 12 13 21    22    23
        '
        Compare-PSObject $Actual $Expected | Should -BeNull}
    }
}