<#PSScriptInfo
.VERSION 3.7.2
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR Ronald Bode (iRon)
.DESCRIPTION Join-Object combines two object lists based on a related property between them.
.COMPANYNAME PowerSnippets.com
.COPYRIGHT Ronald Bode (iRon)
.TAGS Join-Object Join InnerJoin LeftJoin RightJoin FullJoin OuterJoin CrossJoin Update Merge Difference Combine Table
.LICENSEURI https://github.com/iRon7/Join-Object/LICENSE
.PROJECTURI https://github.com/iRon7/Join-Object
.ICONURI https://raw.githubusercontent.com/iRon7/Join-Object/master/Join-Object.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES To install the new Join module equivalent: Install-Module -Name JoinModule
.PRIVATEDATA
#>

<#
    .SYNOPSIS
    Combines two object lists based on a related property between them.

    .DESCRIPTION
    Combines properties from one or more objects. It creates a set that can be saved as a new object or used as it
    is. An object join is a means for combining properties from one (self-join) or more object lists by using
    values common to each.

    Main features:
    * Intuitive (SQL like) syntax
    * Smart property merging
    * Predefined join commands for updating, merging and specific join types
    * Well defined pipeline for the (left) input objects and output objects (preserves memory when correctly used)
    * Performs about 40% faster than Compare-Object on large object lists
    * Supports a list of (custom) objects, strings or primitives and dictionaries (e.g. hash tables) and data tables for input
    * Smart properties and calculated property expressions
    * Custom relation expressions
    * Module (Install-Module -Name JoinModule) or (dot-sourcing) Script version (Install-Script -Name Join)
    * Supports PowerShell for Windows (5.1) and PowerShell Core

    The Join-Object cmdlet reveals the following proxy commands with their own (-JoinType and -Property) defaults:
    * InnerJoin-Object (Alias InnerJoin or Join), combines the related objects
    * LeftJoin-Object (Alias LeftJoin), combines the related objects and adds the rest of the left objects
    * RightJoin-Object (Alias RightJoin), combines the related objects and adds the rest of the right objects
    * OuterJoin-Object (Alias OuterJoin), returns the symmetric difference of the unrelated objects
    * FullJoin-Object (Alias FullJoin), combines the related objects and adds the rest of the left and right objects
    * CrossJoin-Object (Alias CrossJoin), combines each left object with each right object
    * Update-Object (Alias Update), updates the left object with the related right object
    * Merge-Object (Alias Merge), updates the left object with the related right object and adds the rest of the
      new (unrelated) right objects
    * Get-Difference (Alias Differs), returns the symmetric different objects and their properties

    .PARAMETER LeftObject
        The left object list, usually provided through the pipeline, to be joined.

        Note: a self-join on the LeftObject list will be performed if the RightObject is omitted.

    .PARAMETER RightObject
        The right object list, provided by the first argument, to be joined.

        Note: a self-join on the RightObject list will be performed if the LeftObject is omitted.

    .PARAMETER On
        The -On parameter (alias -Using) defines which objects should be joined together.
        If the -Equals parameter is omitted, the value(s) of the properties listed by the -On parameter should be
        equal at both sides in order to join the left object with the right object.
        If the -On parameter contains an expression, the expression will be evaluted where $_, $PSItem and
        $Left contains the currect object. The result of the expression will be compared to right object property
        defined by the -Equals parameter.

        Note 1: The list of properties defined by the -On parameter will be complemented with the list of
        properties defined by the -Equals parameter and vice versa.

        Note 2: Related properties will be merged to a single property by default (see also the -Property
        parameter).

        Note 3: If the -On and the -Using parameter are omitted, a side-by-side join is returned unless OuterJoin
        is performed where the default -On parameter value is * (all properties).

    .PARAMETER Equals
        If the -Equals parameter is supplied, the value(s) of the left object properties listed by the -On
        parameter should be equal to the value(s)of the right object listed by the -Equals parameter in order to
        join the left object with the right object.
        If the -Equals parameter contains an expression, the expression will be evaluted where $_, $PSItem and
        $Right contains the currect object. The result of the expression will be compared to left object property
        defined by the -On parameter.

        Note 1: The list of properties defined by the -Equal parameter will be complemented with the list of
        properties defined by the -On parameter and vice versa. This means that by default value of the -Equals
        parameter is equal to the value supplied to the -On parameter

        Note 2: A property will be omitted in the results if it exists on both sides and if the property at the
        other side is related to another property.

        Note 3: The -Equals parameter can only be used with the -On parameter.

    .PARAMETER Strict
        If the -Strict switch is set, the comparison between the related properties defined by the -On Parameter
        (and the -Equals parameter) is based on a strict equality (both type and value need to be equal).

    .PARAMETER MatchCase
        If the -MatchCase (alias -CaseSensitive) switch is set, the comparison between the related properties
        defined by the -On Parameter (and the -Equals parameter) will case sensitive.

    .PARAMETER Using
        Any conditional expression that requires to evaluate to true in order to join the left object with the
        right object.

        The following variables are exposed for a (ScriptBlock) expression:
        * $_: iterates each property name
        * $Left: a hash table representing the current left object (each self-contained -LeftObject).
          The hash table will be empty (@{}) in the outer part of a left join or full join.
        * $LeftIndex: the index of the left object ($Null in the outer part of a right- or full join)
        * $Right: a hash table representing the current right object (each self-contained -RightObject)
          The hash table will be empty (@{}) in the outer part of a right join or full join.
        * $RightIndex: the index of the right object ($Null in the outer part of a left- or full join)


        Note 1: The -Using parameter has the most complex comparison possibilities but is considerable slower
        than the -On parameter.

        Note 2: The -Using parameter cannot be used with the -On parameter.

    .PARAMETER Where
        An expression that defines the condition to be met for the objects to be returned. See the Using
        parameter for available expression variables.

    .PARAMETER Discern
        By default unrelated properties with the same name will be collected in a single object property.
        The -Discern parameter (alias -NameItems)  defines how to rename the object properties and divide
        them over multiple properties. If a given name pattern contains an asterisks (*), the asterisks
        will be replaced with the original property name. Otherwise, the property name for each property
        item will be prefixed with the given name pattern.

        The property collection of multiple (chained) join commands can be divided in once from the last join
        command in the change. The rename patterns are right aligned, meaning that the last renamed pattern
        will be applied to the last object joined. If there are less rename patterns than property items,
        the rest of the (left most) property items will be put in a fixed array under the original property name.

        Note 1: Only properties with the same name on both sides will not be renamed.

        Note 2: Related properties (with an equal value defined by the -On parameter) will be merged to a signle
        item.

    .PARAMETER Property
        A hash table or list of property names (strings) and/or hash tables that define a new selection of
        property names and values

        Hash tables should be in the format @{<PropertyName> = <Expression>} where the <Expression> is a
        ScriptBlock or a smart property (string) and defines how the specific left and right properties should be
        merged. See the Using parameter for available expression variables.

        The following smart properties are available:
        * A general property: '<Property Name>', where <Property Name> represents the property name of the left
          and/or right property, e.g. @{ MyProperty = 'Name' }. If the property exists on both sides, an array
          holding both values will be returned. In the outer join, the value of the property will be $Null.
          This smart property is similar to the expression: @{ MyProperty = { @($Left['Name'], $Right['Name']) } }
        * A general wildcard property: '*', where * represents the property name of the current property, e.g.
          'MyProperty' in @{ MyProperty = '*' }. If the property exists on both sides:
          - and the properties are unrelated, an array holding both values will be returned
          - and the properties are related to each other, the (equal) values will be merged in one property value
          - and the property at the other side is related to an different property, the property is omitted
          The argument: -Property *, will apply a general wildcard on all left and right properties.
        * A left property: 'Left.<Property Name>', or right property: 'Right.<Property Name>', where
          <Property Name> represents the property name of the either the left or right property. If the property
          doesn't exist, the value of the property will be $Null.
        * A left wildcard property: 'Left.*', or right wildcard property: 'Right.*', where '*' represents the
          property name of the current the left or right property, e.g. 'MyProperty' in @{ MyProperty = 'Left.*' }.
          If the property doesn't exist (in an outer join), the property with the same name at the other side will
          be taken. If the property doesn't exist on either side, the value of the property will be $Null.
          The argument: -Property 'Left.*', will apply a left wildcard property on all the left object properties.

        If the -Property parameter and the -Discern parameter are omitted, a general wildcard property is applied
        on all the left and right properties.

        The last defined expression or smart property will overrule any previous defined properties.

    .PARAMETER ValueName
        Defines the default name for the property name in case a scalar array is joined with an object array.

        Note: If two scalar (or collection) arrays are joined, an array of (psobject) collections is returned.
        Each collection is a concatenation of the left item (collection) and the right item (collection).

    .PARAMETER JoinType
        Defines which unrelated objects should be included (see: Description).
        Valid values are: 'Inner', 'Left', 'Right', 'Full' or 'Cross'. The default is 'Inner'.

        Note: It is recommended to use the related proxy commands (... |<JoinType>-Object ...) instead.

    .EXAMPLE

        PS C:\> $Employee

        Id Name    Country Department  Age ReportsTo
        -- ----    ------- ----------  --- ---------
         1 Aerts   Belgium Sales        40         5
         2 Bauer   Germany Engineering  31         4
         3 Cook    England Sales        69         1
         4 Duval   France  Engineering  21         5
         5 Evans   England Marketing    35
         6 Fischer Germany Engineering  29         4

        PS C:\> $Department

        Name        Country
        ----        -------
        Engineering Germany
        Marketing   England
        Sales       France
        Purchase    France


        PS C:\> # Join the employees with the departments based on the country
        PS C:\> $Employee |Join $Department -On Country |Format-Table

        Id Name                   Country Department  Age ReportsTo
        -- ----                   ------- ----------  --- ---------
         2 {Bauer, Engineering}   Germany Engineering  31         4
         3 {Cook, Marketing}      England Sales        69         1
         4 {Duval, Sales}         France  Engineering  21         5
         4 {Duval, Purchase}      France  Engineering  21         5
         5 {Evans, Marketing}     England Marketing    35
         6 {Fischer, Engineering} Germany Engineering  29         4

    .EXAMPLE

        PS C:\> # Full join the employees with the departments based on the department name
        PS C:\> # and Split the names over differend properties
        PS C:\> $Employee |InnerJoin $Department -On Department -Equals Name -Discern Employee, Department |Format-Table

        Id Name    EmployeeCountry DepartmentCountry Department  Age ReportsTo
        -- ----    --------------- ----------------- ----------  --- ---------
         1 Aerts   Belgium         France            Sales        40         5
         2 Bauer   Germany         Germany           Engineering  31         4
         3 Cook    England         France            Sales        69         1
         4 Duval   France          Germany           Engineering  21         5
         5 Evans   England         England           Marketing    35
         6 Fischer Germany         Germany           Engineering  29         4

    .EXAMPLE

        PS C:\> $Changes

        Id Name    Country Department  Age ReportsTo
        -- ----    ------- ----------  --- ---------
         3 Cook    England Sales        69         5
         6 Fischer France  Engineering  29         4
         7 Geralds Belgium Sales        71         1

        PS C:\> # Apply the changes to the employees
        PS C:\> $Employee |Merge $Changes -On Id |Format-Table

        Id Name    Country Department  Age ReportsTo
        -- ----    ------- ----------  --- ---------
         1 Aerts   Belgium Sales        40         5
         2 Bauer   Germany Engineering  31         4
         3 Cook    England Sales        69         5
         4 Duval   France  Engineering  21         5
         5 Evans   England Marketing    35
         6 Fischer France  Engineering  29         4
         7 Geralds Belgium Sales        71         1

    .EXAMPLE

        PS C:\> # (Self) join each employee with its each manager
        PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id -Property @{ Name = 'Left.Name' }, @{ Manager = 'Right.Name' }

        Name    Manager
        ----    -------
        Aerts   Evans
        Bauer   Duval
        Cook    Aerts
        Duval   Evans
        Evans
        Fischer Duval

    .EXAMPLE

        PS C:\> # Add an Id to the department list
        PS C:\> 1..9 |Join $Department -ValueName Id

        Id Name        Country
        -- ----        -------
         1 Engineering Germany
         2 Marketing   England
         3 Sales       France
         4 Purchase    France

    .EXAMPLE

        PS C:\> $a = 'a1', 'a2', 'a3', 'a4'
        PS C:\> $b = 'b1', 'b2', 'b3', 'b4'
        PS C:\> $c = 'c1', 'c2', 'c3', 'c4'
        PS C:\> $d = 'd1', 'd2', 'd3', 'd4'

        PS C:\> # Join (transpose) multiple arrays to a collection array
        PS C:\> $a |Join $b |Join $c |Join $d |% { "$_" }

        a1 b1 c1 d1
        a2 b2 c2 d2
        a3 b3 c3 d3
        a4 b4 c4 d4

    .EXAMPLE

        PS C:\> # Create objects with named properties from multiple arrays
        PS C:\> $a |Join $b |Join $c |Join $d -Name a, b, c, d

        a  b  c  d
        -  -  -  -
        a1 b1 c1 d1
        a2 b2 c2 d2
        a3 b3 c3 d3
        a4 b4 c4 d4

    .LINK
        https://www.powershellgallery.com/packages/Join
        https://www.powershellgallery.com/packages/JoinModule
        https://github.com/iRon7/Join-Object
        https://github.com/PowerShell/PowerShell/issues/14994 (Please give a thumbs up if you like to support the proposal to "Add a Join-Object cmdlet to the standard PowerShell equipment")

#>

function Join-Object {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('InjectionRisk.Create', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('InjectionRisk.ForeachObjectInjection', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Scope = 'Function')]
    [CmdletBinding(DefaultParameterSetName = 'Default')][OutputType([Object[]])] param(

        [Parameter(ValueFromPipeLine = $True, ParameterSetName = 'Default')]
        [Parameter(ValueFromPipeLine = $True, ParameterSetName = 'On')]
        [Parameter(ValueFromPipeLine = $True, ParameterSetName = 'Using')]
        $LeftObject,

        [Parameter(Position = 0, ParameterSetName = 'Default')]
        [Parameter(Position = 0, ParameterSetName = 'On')]
        [Parameter(Position = 0, ParameterSetName = 'Using')]
        $RightObject,

        [Parameter(Position = 1, ParameterSetName = 'On')]
        [array]$On = @(),

        [Parameter(Position = 1, ParameterSetName = 'Using')]
        [scriptblock]$Using,

        [Parameter(ParameterSetName = 'On')]
        [Alias('Eq')][array]$Equals = @(),

        [Parameter(Position = 2, ParameterSetName = 'Default')]
        [Parameter(Position = 2, ParameterSetName = 'On')]
        [Parameter(Position = 2, ParameterSetName = 'Using')]
        [Alias('NameItems')][AllowEmptyString()][String[]]$Discern,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Using')]
        $Property,

        [Parameter(Position = 3, ParameterSetName = 'Default')]
        [Parameter(Position = 3, ParameterSetName = 'On')]
        [Parameter(Position = 3, ParameterSetName = 'Using')]
        [scriptblock]$Where = { $True },

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Using')]
        [ValidateSet('Inner', 'Left', 'Right', 'Full', 'Outer', 'Cross')][String]$JoinType = 'Inner',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Using')]
        [string]$ValueName = 'VALUE',

        [Parameter(ParameterSetName = 'On')]
        [switch]$Strict,

        [Parameter(ParameterSetName = 'On')]
        [Alias('CaseSensitive')][switch]$MatchCase
    )
    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }
        function GetKeys($Object) {
            if ($Null -eq $Object) { ,@() }
            elseif ($Object.GetType().GetElementType() -and $Object.get_Count() -eq 0) { ,[string[]]$ValueName } # ,[string[]] is used to easy recognise a value arrey
            else {
                $1 = $Object |Select-Object -First 1
                if ($1 -is [string] -or $1 -is [ValueType] -or $1 -is [Array]) { ,[string[]]$ValueName }
                elseif ($1 -is [Collections.ObjectModel.Collection[psobject]]) { ,[string[]]$ValueName }
                elseif ($1 -is [Data.DataRow]) { ,@($1.Table.Columns.ColumnName) }
                elseif ($1 -is [System.Collections.IDictionary]) { ,@($1.Get_Keys()) }
                elseif ($1) { ,@($1.PSObject.Properties.Name) }
            }
        }
        function GetProperties($Object, $Keys) {
            if ($Keys -is [string[]]) { [ordered]@{ $ValueName = $Object } }
            else {
                $Properties = [ordered]@{}
                if ($Null -ne $Object) {
                    foreach ($Key in $Keys) { $Properties.Add($Key, $Object.psobject.properties[$Key].Value) }
                }
                $Properties
            }
        }
        function AsDictionary($Object, $Keys) {
            if ($Object -isnot [array] -and $Object -isnot [Data.DataTable]) { $Object = @($Object) }
            ,@(foreach ($Item in $Object) {
                if ($Item -is [Collections.IDictionary]) { $Object; Break } else { GetProperties $Item $Keys }
            })
        }
        function SetExpression ($Key = '*', $Expression) {
            $Wildcard = if ($Key -is [ScriptBlock]) { $BothKeys } else {
                if (!$BothKeys.Contains($Key)) {
                    if ($Key.Trim() -eq '*') { $BothKeys }
                    else {
                        $Side, $Asterisks = $Key.Split('.', 2)
                        if ($Null -ne $Asterisks -and $Asterisks.Trim() -eq '*') {
                            if ($Side -eq 'Left') { $LeftKeys } elseif ($Side -eq 'Right') { $RightKeys }
                        }
                    }
                }
            }
            if ($Null -ne $Wildcard) {
                if ($Null -eq $Expression) { $Expression = $Key }
                foreach ($Key in $Wildcard) {
                    if ($Null -ne $Key -and !$Expressions.Contains($Key)) {
                        $Expressions[$Key] = $Expression
                    }
                }
            }
            else { $Expressions[$Key] = if ($Expression) { $Expression } else { ' * ' } }
        }
        function OutObject ($LeftIndex, $RightIndex) {
            $Nodes = [Ordered]@{}
                foreach ($_ in $Expressions.Get_Keys()) {
                $Tuple =
                    if ($Expressions[$_] -is [scriptblock]) { @{ 0 = &([scriptblock]::Create($Expressions[$_])) } }
                    else {
                        $Key = $Expressions[$_]
                        if ($Left.Contains($Key) -or $Right.Contains($Key)) {
                            if ($Left.Contains($Key) -and $Right.Contains($Key)) { @{ 0 = $Left[$Key]; 1 = $Right[$Key] } }
                            elseif ($Left.Contains($Key)) { @{ 0 = $Left[$Key] } }
                            else { @{ 0 = $Right[$Key] } } # if($Right.Contains($_))
                        }
                        elseif ($Key.Trim() -eq '*') {
                            if ($Left.Contains($_) -and $Right.Contains($_)) {
                                if ($LeftRight.Contains($_) -and $LeftRight[$_] -eq $_) {
                                    if ($Null -ne $LeftIndex -and $Left.Contains($_)) { @{ 0 = $Left[$_] } } else { @{ 0 = $Right[$_] } }
                                }
                                elseif (!$LeftRight.Contains($_) -and $RightLeft.Contains($_)) { @{ 0 = $Left[$_] } }
                                elseif ($LeftRight.Contains($_) -and !$RightLeft.Contains($_)) { @{ 0 = $Right[$_] } }
                                else { @{ 0 = $Left[$_]; 1 = $Right[$_] } }
                            }
                            elseif ($Left.Contains($_))  {
                                if ($Null -ne $LeftIndex -and $Left.Contains($_)) { @{ 0 = $Left[$_] } }
                                elseif ($LeftRight.Contains($_)) { @{ 0 = $Right[$LeftRight[$_]] } }
                            }
                            elseif ($Right.Contains($_)) {
                                if ($Null -ne $RightIndex -and $Right.Contains($_)) { @{ 0 = $Right[$_] } }
                                elseif ($RightLeft.Contains($_)) { @{ 0 = $Left[$RightLeft[$_]] } }
                            }
                        }
                        else {
                            $Side, $Key = $Key.Split('.', 2)
                            if ($Null -ne $Key) {
                                if ($Side[0] -eq 'L') {
                                    if ($Left.Contains($Key)) { @{ 0 = $Left[$Key] } }
                                    elseif ($Key -eq '*') {
                                        if ($Null -ne $LeftIndex -and $Left.Contains($_)) { @{ 0 = $Left[$_] } }
                                        elseif ($Null -ne $RightIndex -and $Right.Contains($_)) { @{ 0 = $Right[$_] } }
                                    }
                                }
                                if ($Side[0] -eq 'R') {
                                    if ($Right.Contains($Key)) { @{ 0 = $Right[$Key] } }
                                    elseif ($Key -eq '*') {
                                        if ($Null -ne $RightIndex -and $Right.Contains($_)) { @{ 0 = $Right[$_] } }
                                        elseif ($Null -ne $LeftIndex -and $Left.Contains($_)) { @{ 0 = $Left[$_] } }
                                    }
                                }
                            } else { StopError "The property '$Key' doesn't exists" 'MissingProperty' }
                        }
                    }
                if ($Tuple -isnot [System.Collections.IDictionary] ) { $Node = $Null }
                elseif ($Tuple.Count -eq 1) { $Node = $Tuple[0] }
                else {
                    $Node = [Collections.ObjectModel.Collection[psobject]]::new()
                    if ($Tuple[0] -is [Collections.ObjectModel.Collection[psobject]]) { foreach ($Value in $Tuple[0]) { $Node.Add($Value) } } else { $Node.Add($Tuple[0]) }
                    if ($Tuple[1] -is [Collections.ObjectModel.Collection[psobject]]) { foreach ($Value in $Tuple[1]) { $Node.Add($Value) } } else { $Node.Add($Tuple[1]) }
                }
                if ($Node -is [Collections.ObjectModel.Collection[psobject]] -and $Null -ne $Discern) {
                    if ($Node.Count -eq $Discern.Count + 1) { $Nodes[$_] = $Node[$Node.Count - $Discern.Count - 1] }
                    if ($Node.Count -gt $Discern.Count + 1) { $Nodes[$_] = $Node[0..($Node.Count - $Discern.Count - 1)] }
                    for ($i = [math]::Min($Node.Count, $Discern.Count); $i -gt 0; $i--) {
                        $Rename = $Discern[$Discern.Count - $i]
                        $Name = if ($Rename.Contains('*')) { ([regex]"\*").Replace($Rename, $_, 1) } elseif ( $_ -eq $ValueName) { $Rename } else { $Rename + $_ }
                        $Nodes[$Name] = if ($Nodes.Contains($Name)) { @($Nodes[$Name]) + $Node[$Node.Count - $i] } else { $Node[$Node.Count - $i] }
                    }
                } else { $Nodes[$_] = $Node }
            }
            if ($Nodes.Count -eq 1 -and $Nodes.Contains($ValueName)) { ,$Nodes[0] } else { [PSCustomObject]$Nodes }
        }
        function ProcessObject ($Left) {
            if ($Left -isnot [Collections.IDictionary]) { $Left = GetProperties $Left $LeftKeys }
            if (!$LeftIndex) {
                ([ref]$InnerRight).Value = [Boolean[]](@($False) * $RightList.Count)
                foreach ($Key in $LeftKeys) {
                    if ($Left[$Key] -isnot [Collections.ObjectModel.Collection[psobject]]) { $LeftNull[$Key] = $Null }
                    else { $LeftNull[$Key] = [Collections.ObjectModel.Collection[psobject]]( ,$Null * $Left[$Key].Count) }
                }
                foreach ($Key in $RightKeys) {
                    $RightNull[$Key] = if ($RightList) {
                        if ($RightList[0][$Key] -isnot [Collections.ObjectModel.Collection[psobject]]) { $Null }
                        else { [Collections.ObjectModel.Collection[psobject]]( ,$Null * $Left[$Key].Count) }
                    }
                }
                $BothKeys = [System.Collections.Generic.HashSet[string]](@($LeftKeys) + @($RightKeys))
                if ($On.Count) {
                    if ($On.Count -eq 1 -and $On[0] -is [string] -and $On[0].Trim() -eq '*' -and !$BothKeys.Contains('*')) { # Use e.g. -On ' * ' if there exists an '*' property
                        ([Ref]$On).Value = $LeftKeys.Where{ $RightKeys.Contains($_) }
                    }
                        if ($On.Count -gt $Equals.Count) { ([Ref]$Equals).Value += $On[($Equals.Count)..($On.Count - 1)] }
                    elseif ($On.Count -lt $Equals.Count) { ([Ref]$On).Value     += $Equals[($On.Count)..($Equals.Count - 1)] }
                    for ($i = 0; $i -lt $On.Count; $i++) {
                        if ( $On[$i] -is [ScriptBlock] ) { if ( $On[$i] -Like '*$Right*' ) { Write-Warning 'Use the -Using parameter for comparison expressions' } }
                        else {
                            if ($On[$i] -notin $LeftKeys) { StopError "The property $($On[$i]) cannot be found on the left object."  'MissingLeftProperty' }
                            $LeftRight[$On[$i]] = $Equals[$i]
                        }
                        if ( $Equals[$i] -is [ScriptBlock] ) { if ( $On[$i] -Like '*$Left*' ) { Write-Warning 'Use the -Using parameter for comparison expressions' } }
                        else {
                            if ($Equals[$i] -notin $RightKeys) { StopError "The property $($Equals[$i]) cannot be found on the right object." 'MissingRightProperty' }
                            $RightLeft[$Equals[$i]] = $On[$i]
                        }
                    }
                    $RightIndex = 0
                    foreach ($Right in $RightList) {
                        $JoinKeys = foreach ($Key in $Equals) { if ($Key -is [ScriptBlock]) { $Right |ForEach-Object $Key } else { $Right[$Key] } }
                        $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                                   else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                        if ($RightIndices.ContainsKey($HashKey)) { $RightIndices[$HashKey].Add($RightIndex++) } else { $RightIndices.Add($HashKey, $RightIndex++) }
                    }
                }
                if ($Property) {
                    foreach ($Item in @($Property)) {
                        if ($Item -is [System.Collections.IDictionary]) { foreach ($Key in $Item.Get_Keys()) { SetExpression $Key $Item[$Key] } }
                        else { SetExpression $Item }
                    }
                } else { SetExpression }
            }
            $Indices =
                if ($On.Count) {
                    if ($JoinType -eq 'Cross') { StopError 'The On parameter cannot be used on a cross join.' 'CrossOn' }
                    $JoinKeys = foreach ($Key in $On) { if ($Key -is [ScriptBlock]) { $Left |ForEach-Object $Key } else { $Left[$Key] } }
                    $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                               else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                    $RightIndices[$HashKey]
                }
                elseif ($Using) {
                    if ($JoinType -eq 'Cross') { StopError 'The Using parameter cannot be used on a cross join.' 'CrossUsing' }
                    for ($RightIndex = 0; $RightIndex -lt $RightList.Count; $RightIndex++) {
                        $Right = $RightList[$RightIndex]; if (&([scriptblock]::Create($Using))) { $RightIndex }
                    }
                }
                elseif ($JoinType -eq 'Cross') { 0..($RightList.Length - 1) }
                elseif ($LeftIndex -lt $RightList.Count) { $LeftIndex } else { $Null }
            foreach ($RightIndex in $Indices) {
                $Right = $RightList[$RightIndex]
                if (&([scriptblock]::Create($Where))) {
                    if ($JoinType -ne 'Outer') { OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex }
                    $InnerLeft = $True
                    $InnerRight[$RightIndex] = $True
                }
            }
            $RightIndex = $Null; $Right = $RightNull
            if (!$InnerLeft -and ($JoinType -in 'Left', 'Full', 'Outer')) {
                if (&([scriptblock]::Create($Where))) { OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex }
            }
        }
        if ($PSBoundParameters.ContainsKey('Discern') -and !$Discern) { $Discern = @() }
        if ($JoinType -eq 'Outer' -and !$PSBoundParameters.ContainsKey('On')) { $On = '*' }
        $Esc = [char]27; $EscSeparator = $Esc + ', '
        $Expressions = [Ordered]@{}
        $StringComparer = if ($MatchCase) { [StringComparer]::Ordinal } Else { [StringComparer]::OrdinalIgnoreCase }
        $LeftKeys, $InnerLeft, $RightKeys, $InnerRight, $Pipeline, $LeftList = $Null
        $RightIndices = [Collections.Generic.Dictionary[string, [Collections.Generic.List[Int]]]]::new($StringComparer)
        $LeftRight = @{}; $RightLeft = @{}; $LeftNull = [ordered]@{}; $RightNull = [ordered]@{}
        $LeftParameter = $PSBoundParameters.ContainsKey('LeftObject')
        $RightParameter = $PSBoundParameters.ContainsKey('RightObject')
        $RightKeys = GetKeys $RightObject
        $RightList = if ($RightParameter) { AsDictionary $RightObject $RightKeys }
        $LeftIndex = 0
    }
    process {
        # The Process block is invoked (once) if the pipeline is omitted but not if it is empty: @()
        if ($Null -eq $LeftKeys) { $LeftKeys = GetKeys $LeftObject }
        if ($LeftParameter) { $LeftList = AsDictionary $LeftObject $LeftKeys }
        else {
            if ($Null -eq $Pipeline) { $Pipeline = [Collections.Generic.List[Collections.IDictionary]]::New() }
            if ($Null -ne $LeftObject) {
                if ($LeftObject -isnot [Collections.IDictionary]) { $LeftObject = GetProperties $LeftObject $LeftKeys }
                if ($RightParameter) { ProcessObject $LeftObject; $LeftIndex++ } else { $Pipeline.Add($LeftObject) }
            }
        }
    }
    end {
        if (!($LeftParameter -or $Pipeline) -and !$RightParameter) { StopError 'A value for either the LeftObject, pipeline or the RightObject is required.' 'MissingObject' }
        if ($Pipeline) { $LeftList = $Pipeline } elseif ($Null -eq $LeftKeys) { $LeftList = @() }
        if (!$LeftIndex) { # Not yet streamed/processed
            if ($Null -eq $LeftList) { # Right Self Join
                $LeftKeys = $RightKeys
                $LeftList = $RightList
            }
            if ($Null -eq $RightList) { # Left Self Join
                $RightKeys = $LeftKeys
                $RightList = $LeftList
            }
            foreach ($Left in $LeftList) { ProcessObject $Left; $LeftIndex++ }
        }
        if ($JoinType -in 'Right', 'Full', 'Outer') {
            if (!$LeftIndex) { ProcessObject $LeftObject $Null }
            $LeftIndex = $Null; $Left = $LeftNull
            $RightIndex = 0; foreach ($Right in $RightList) {
                if (!$InnerRight -or !$InnerRight[$RightIndex]) {
                    if (&([scriptblock]::Create($Where))) { OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex }
                }
                $RightIndex++
            }
        }
    }
}; Set-Alias Join Join-Object

$JoinCommand = Get-Command Join-Object
$MetaData = [System.Management.Automation.CommandMetadata]$JoinCommand
$ProxyCommand = [System.Management.Automation.ProxyCommand]::Create($MetaData)
$ParamBlock, $ScriptBlock = $ProxyCommand -Split '\r?\n(?=begin\r?\n)', 2

$Proxies =
    @{ Name = 'InnerJoin-Object'; Alias = 'InnerJoin'; Default = "JoinType = 'Inner'" },
    @{ Name = 'LeftJoin-Object';  Alias = 'LeftJoin';  Default = "JoinType = 'Left'" },
    @{ Name = 'RightJoin-Object'; Alias = 'RightJoin'; Default = "JoinType = 'Right'" },
    @{ Name = 'FullJoin-Object';  Alias = 'FullJoin';  Default = "JoinType = 'Full'" },
    @{ Name = 'OuterJoin-Object'; Alias = 'OuterJoin'; Default = "JoinType = 'Outer'" },
    @{ Name = 'CrossJoin-Object'; Alias = 'CrossJoin'; Default = "JoinType = 'Cross'" },
    @{ Name = 'Update-Object';    Alias = 'Update';    Default = "JoinType = 'Left'",  "Property = @{ '*' = 'Right.*' }" },
    @{ Name = 'Merge-Object';     Alias = 'Merge';     Default = "JoinType = 'Full'",  "Property = @{ '*' = 'Right.*' }" },
    @{ Name = 'Get-Difference';   Alias = 'Differs';   Default = "JoinType = 'Outer'", "Property = @{ '*' = 'Right.*' }" }

foreach ($Proxy in $Proxies) {
    $ProxyCommand = @(
        $ParamBlock
        'DynamicParam  {'
        foreach ($Default in @($Proxy.Default)) { '    $PSBoundParameters.' + $Default }
        '}'
        $ScriptBlock
    ) -Join [Environment]::NewLine
    $Null = New-Item -Path Function:\ -Name $Proxy.Name -Value $ProxyCommand -Force
    Set-Alias $Proxy.Alias $Proxy.Name
}