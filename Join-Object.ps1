<#PSScriptInfo
.VERSION 3.4.2
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR iRon
.DESCRIPTION Join-Object combines two objects lists based on a related property between them.
.COMPANYNAME
.COPYRIGHT
.TAGS Join-Object Join InnerJoin LeftJoin RightJoin FullJoin CrossJoin Update Merge Combine Table
.LICENSE https://github.com/iRon7/Join-Object/LICENSE
.PROJECTURI https://github.com/iRon7/Join-Object
.ICON https://raw.githubusercontent.com/iRon7/Join-Object/master/Join-Object.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
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
    * Supports (custom) objects, data tables and dictionaries (e.g. hash tables) for input
    * Smart properties and calculated property expressions
    * Custom relation expressions
    * Easy installation (dot-sourcing)
    * Supports PowerShell for Windows (5.1) and PowerShell Core

    The Join-Object cmdlet reveals the following proxy commands with their own (-JoinType and -Property) defaults:
    * InnerJoin-Object (Alias InnerJoin or Join), combines the related objects
    * LeftJoin-Object (Alias LeftJoin), combines the related objects and adds the rest of the left objects
    * RightJoin-Object (Alias RightJoin), combines the related objects and adds the rest of the right objects
    * FullJoin-Object (Alias FullJoin), combines the related objects and adds the rest of the left and right objects
    * CrossJoin-Object (Alias CrossJoin), combines each left object with each right object
    * Update-Object (Alias Update), updates the left object with the related right object
    * Merge-Object (Alias Merge), updates the left object with the related right object and adds the rest of the
      new (unrelated) right objects

    .INPUTS
    PSObject[], DataTable[] or HashTable[]

    .OUTPUTS
    PSCustomObject[]

    .PARAMETER LeftObject
        The left object list, usually provided through the pipeline, to be joined.

    .PARAMETER RightObject
        The right object list, provided by the first argument, to be joined.

    .PARAMETER On
        The -On parameter (alias -Using) defines which objects should be joined together.
        If the -Equals parameter is omitted, the value(s) of the properties listed by the -On parameter should be
        equal at both sides in order to join the left object with the right object.

        Note 1: The list of properties defined by the -On parameter will be complemented with the list of
        properties defined by the -Equals parameter and vice versa.

        Note 2: Related properties will be merged to a single property by default (see also the -Property
        parameter).

        Note 3: If the -On and the -OnExpression parameter are omitted, a join by row index is returned.

    .PARAMETER Equals
        If the -Equals parameter is supplied, the value(s) of the left object properties listed by the -On
        parameter should be equal to the value(s)of the right object listed by the -Equals parameter in order to
        join the left object with the right object.

        Note 1: The list of properties defined by the -Equal parameter will be complemented with the list of
        properties defined by the -On parameter and vice versa.

        Note 2: A property will be omitted if it exists on both sides and if the property at the other side is
        related to another property.

        Note 3: The -Equals parameter can only be used with the -On parameter.

    .PARAMETER Strict
        If the -Strict switch is set, the comparison between the related properties defined by the -On Parameter
        (and the -Equals parameter) is based on a strict equality (both type and value need to be equal).

    .PARAMETER MatchCase
        If the -MatchCase (alias -CaseSensitive) switch is set, the comparison between the related properties
        defined by the -On Parameter (and the -Equals parameter) will case sensitive.

    .PARAMETER OnExpression
        Any conditional expression (where $Left refers to each left object and $Right refers to each right object)
        that requires to evaluate to true in order to join the left object with the right object.

        Note 1: The -OnExpression parameter has the most complex comparison possibilities but is considerable
        slower than the other types.

        Note 2: The -OnExpression parameter cannot be used with the -On parameter.

    .PARAMETER Where
        An expression that defines the condition to be met for the objects to be returned. There is no limit to
        the number of predicates that can be included in the condition.

    .PARAMETER Discern
        The -Discern parameter (alias -NameItems) defines how to discern the left and right object properties
        with respect to the common properties that aren't related.

        The first string defines how to rename the left property, the second string (if defined) defines how to
        rename the right property. If the string contains an asterisks (*), the asterisks will be replaced with
        the original property name, otherwise, the property name will be prefixed with the given string.

        Properties that don't exist on both sides will not be renamed.

        Joined (equal) properties (defined by the -On parameter) will be merged.

    .PARAMETER Property
        A hash table or list of property names (strings) and/or hash tables that define a new selection of
        property names and values

        Hash tables should be in the format @{<PropertyName> = <Expression>} where the <Expression> is a
        ScriptBlock or a smart property (string) and defines how the specific left and right properties should be
        merged.

        The following variables are exposed for a (ScriptBlock) expression:
        * $_: iterates each property name
        * $Left: a hash table representing the current left object (each self-contained -LeftObject).
          The hash table will be empty (@{}) in the outer part of a left join or full join.
        * $LeftIndex: the index of the left object ($Null in the outer part of a right- or full join)
        * $Right: a hash table representing the current right object (each self-contained -RightObject)
          The hash table will be empty (@{}) in the outer part of a right join or full join.
        * $RightIndex: the index of the right object ($Null in the outer part of a left- or full join)

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

    .PARAMETER JoinType
        Defines which unrelated objects should be included (see: Description).
        Valid values are: 'Inner', 'Left', 'Right', 'Full' or 'Cross'. The default is 'Inner'.

        Note: It is recommended to use the related proxy commands (... | <JoinType>-Object ...) instead.

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


        PS C:\> $Employee | InnerJoin $Department -On Country | Format-Table

        Id Name                   Country Department  Age ReportsTo
        -- ----                   ------- ----------  --- ---------
         2 {Bauer, Engineering}   Germany Engineering  31         4
         3 {Cook, Marketing}      England Sales        69         1
         4 {Duval, Sales}         France  Engineering  21         5
         4 {Duval, Purchase}      France  Engineering  21         5
         5 {Evans, Marketing}     England Marketing    35
         6 {Fischer, Engineering} Germany Engineering  29         4

    .EXAMPLE

        PS C:\> $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

        Id Name    EmployeeCountry Department  Age ReportsTo DepartmentCountry
        -- ----    --------------- ----------  --- --------- -----------------
         1 Aerts   Belgium         Sales        40         5 France
         2 Bauer   Germany         Engineering  31         4 Germany
         3 Cook    England         Sales        69         1 France
         4 Duval   France          Engineering  21         5 Germany
         5 Evans   England         Marketing    35           England
         6 Fischer Germany         Engineering  29         4 Germany

    .EXAMPLE

        PS C:\> $Changes

        Id Name    Country Department  Age ReportsTo
        -- ----    ------- ----------  --- ---------
         3 Cook    England Sales        69         5
         6 Fischer France  Engineering  29         4
         7 Geralds Belgium Sales        71         1


        PS C:\> $Employee | Merge $Changes -On Id | Format-Table

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

        PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id -Property @{ Name = 'Left.Name' }, @{ Manager = 'Right.Name' }

        Name    Manager
        ----    -------
        Aerts   Evans
        Bauer   Duval
        Cook    Aerts
        Duval   Evans
        Evans
        Fischer Duval

    .LINK
        https://github.com/iRon7/Join-Object
#>
function Join-Object {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Scope = 'Function')]
    [CmdletBinding(DefaultParameterSetName = 'Default')][OutputType([Object[]])] param(

        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Default')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'On')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Expression')]

        $LeftObject,

        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Default')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'On')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Expression')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Self')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOn')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpression')]
        $RightObject,

        [Parameter(Position = 1, ParameterSetName = 'On')]
        [Parameter(Position = 1, ParameterSetName = 'SelfOn')]
        [Alias('Using')][Collections.Generic.List[string]]$On = [Collections.Generic.List[string]]::new(),

        [Parameter(Position = 1, ParameterSetName = 'Expression')]
        [Parameter(Position = 1, ParameterSetName = 'SelfExpression')]
        [Alias('UsingExpression')][scriptblock]$OnExpression,

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Collections.Generic.List[string]]$Equals = [Collections.Generic.List[string]]::new(),

        [Parameter(Position = 2, ParameterSetName = 'Default')]
        [Parameter(Position = 2, ParameterSetName = 'On')]
        [Parameter(Position = 2, ParameterSetName = 'Expression')]
        [Parameter(Position = 2, ParameterSetName = 'Self')]
        [Parameter(Position = 2, ParameterSetName = 'SelfOn')]
        [Parameter(Position = 2, ParameterSetName = 'SelfExpression')]
        [Alias('NameItems')][AllowEmptyString()][String[]]$Discern,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Expression')]
        [Parameter(ParameterSetName = 'Self')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfExpression')]
        $Property,

        [Parameter(Position = 3, ParameterSetName = 'Default')]
        [Parameter(Position = 3, ParameterSetName = 'On')]
        [Parameter(Position = 3, ParameterSetName = 'Expression')]
        [Parameter(Position = 3, ParameterSetName = 'Self')]
        [Parameter(Position = 3, ParameterSetName = 'SelfOn')]
        [Parameter(Position = 3, ParameterSetName = 'SelfExpression')]
        [scriptblock]$Where = { $True },

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Expression')]
        [Parameter(ParameterSetName = 'Self')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfExpression')]
        [ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')][String]$JoinType = 'Inner',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Expression')]
        [Parameter(ParameterSetName = 'Self')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfExpression')]
        [string]$ValueName = 'Value',

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [switch]$Strict,

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Alias('CaseSensitive')][switch]$MatchCase
    )
    begin {
        function GetKeys($Object) {
            if ($Null -eq $Object) {}
            if ($Object -is [string] -or $Object -is [ValueType] -or $Object -is [Array]) { $ValueName }
            elseif ($Object -is [Collections.ObjectModel.Collection[psobject]]) { $ValueName }
            elseif ($Object -is [Data.DataRow]) { $Object.Table.Columns.ColumnName }
            elseif ($Object -is [System.Collections.IDictionary]) { $Object.Get_Keys() }
            else { $Object.PSObject.Properties.Name }
        }
        function GetProperties($Object, $Keys) {
            if (@($Keys).Count -eq 1 -and $Keys.Contains($ValueName) ) { [ordered]@{ $ValueName = $Object } }
            else {
                $Properties = [ordered]@{}
                foreach ($Key in $Keys) { $Properties.Add($Key, $Object.psobject.properties[$Key].Value) }
                $Properties
            }
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
                    if (!$Expressions.Contains($Key)) {
                        $Expressions[$Key] = $Expression
                    }
                }
            }
            else { $Expressions[$Key] = if ($Expression) { $Expression } else { ' * ' } }
        }
        function OutObject ($LeftIndex, $RightIndex, $Left, $Right) {
            $Nodes = [Ordered]@{}
            foreach ($_ in $Expressions.Get_Keys()) {
                $Value0 = [System.Management.Automation.Internal.AutomationNull]::Value
                $Value1 = [System.Management.Automation.Internal.AutomationNull]::Value
                if ($Expressions[$_] -is [scriptblock]) { $Value0 = & $Expressions[$_] } else {
                    $Key = $Expressions[$_]
                    if ($LeftRight.Contains($Key) -or $RightLeft.Contains($Key)) {
                        if ($LeftRight.Contains($Key) -and $RightLeft.Contains($Key)) { $Value0 = $Left[$Key]; $Value1 = $Right[$Key] }
                        elseif ($LeftRight.Contains($Key)) { $Value0 = $Left[$Key] }
                        else { $Value0 = $Right[$Key] } # if($RightLeft.Contains($_))
                    }
                    elseif ($Key.Trim() -eq '*') {
                        if ($LeftRight.Contains($_) -and $RightLeft.Contains($_)) {
                            if ($LeftRight[$_] -eq $_) { if ($Null -ne $LeftIndex -and $Left.Contains($_)) { $Value0 = $Left[$_] } else { $Value0 = $Right[$_] } }
                            elseif ($Null -eq $LeftRight[$_] -and $Null -ne $RightLeft[$_]) { $Value0 = $Left[$_] }
                            elseif ($Null -ne $LeftRight[$_] -and $Null -eq $RightLeft[$_]) { $Value0 = $Right[$_] }
                            else { $Value0 = $Left[$_]; $Value1 = $Right[$_] }
                        }
                        elseif ($LeftRight.Contains($_))  {
                            if ($Null -ne $LeftIndex -and $Left.Contains($_)) { $Value0 = $Left[$_] }
                            elseif ($Null -ne $LeftRight[$_]) { $Value0 = $Right[$LeftRight[$_]] }
                        }
                        elseif ($RightLeft.Contains($_)) {
                            if ($Null -ne $RightIndex -and $Right.Contains($_)) { $Value0 = $Right[$_] }
                            elseif ($Null -ne $RightLeft[$_]) { $Value0 = $Left[$RightLeft[$_]] }
                        }
                    }
                    else {
                        $Side, $Key = $Key.Split('.', 2)
                        if ($Null -ne $Key) {
                            if ($Side[0] -eq 'L') {
                                if ($LeftRight.Contains($Key)) { $Value0 = $Left[$Key] }
                                elseif ($Key -eq '*') {
                                    if ($Null -ne $LeftIndex -and $Left.Contains($_)) { $Value0 = $Left[$_] }
                                    elseif ($Null -ne $RightIndex -and $Right.Contains($_)) { $Value0 = $Right[$_] }
                                }
                            }
                            if ($Side[0] -eq 'R') {
                                if ($RightLeft.Contains($Key)) { $Value0 = $Right[$Key] }
                                elseif ($Key -eq '*') {
                                    if ($Null -ne $RightIndex -and $Right.Contains($_)) { $Value0 = $Right[$_] }
                                    elseif ($Null -ne $LeftIndex -and $Left.Contains($_)) { $Value0 = $Left[$_] }
                                }
                            }
                        } else { throw [ArgumentException]"The property '$Key' doesn't exists" }
                    }
                }
                if (@($Value1).Count) {
                    $Node = [Collections.ObjectModel.Collection[psobject]]::new()
                    if ($Value0 -is [Collections.ObjectModel.Collection[psobject]]) { foreach ($Value in $Value0) { $Node.Add($Value) } } else { $Node.Add($Value0) }
                    if ($Value1 -is [Collections.ObjectModel.Collection[psobject]]) { foreach ($Value in $Value1) { $Node.Add($Value) } } else { $Node.Add($Value1) }
                } else { $Node = $Value0 }
                if ($Node -is [Collections.ObjectModel.Collection[psobject]] -and $Null -ne $Discern) {
                    if ($Node.Count -eq $Discern.Count + 1) { $Nodes[$_] = $Node[$Node.Count - $Discern.Count - 1] }
                    if ($Node.Count -gt $Discern.Count + 1) { $Nodes[$_] = $Node[0..($Node.Count - $Discern.Count - 1)] }
                    for ($i = [math]::Min($Node.Count, $Discern.Count); $i -gt 0; $i--) {
                        $Rename = $Discern[$Discern.Count - $i]
                        $Name = if ($Rename.Contains('*')) { ([regex]"\*").Replace($Rename, $_, 1) } elseif ( $_ -eq $ValueName) { $Rename} else { $Rename + $_ }
                        $Nodes[$Name] = $Node[$Node.Count - $i]
                    }
                } else { $Nodes[$_] = $Node }
            }
            if ($Nodes.Count -eq 1 -and $Nodes.Contains($ValueName)) { ,$Nodes[0] } else { New-Object PSCustomObject -Property $Nodes }
        }
        function ProcessObject ($Left) {
            if ($Null -eq $LeftKeys) { ([ref]$LeftKeys).Value = GetKeys $Left }
            if ($Left -isnot [Collections.IDictionary]) { $Left = GetProperties $Left $LeftKeys }
            if (!$LeftIndex) {
                foreach ($Key in $LeftKeys) {
                    $LeftRight[$Key] = $Null                                    # Left to Right relation
                    if ($Left[$Key] -isnot [Collections.ObjectModel.Collection[psobject]]) { $LeftNull[$Key] = $Null }
                    else { $LeftNull[$Key] = [Collections.ObjectModel.Collection[psobject]](,$Null * $Left[$Key].Count) }
                }
                $BothKeys = New-Object System.Collections.Generic.HashSet[Object]
                foreach ($Key in (@($LeftKeys) + $RightKeys)) { $Null = $BothKeys.Add($Key) }
                if ($On.Count) {
                    if ($On.Count -eq 1 -and $On[0].Trim() -eq '*' -and !$BothKeys.Contains('*')) { # Use e.g. -On ' * ' if there exists an '*' property
                        $On.Clear()
                        $LeftRight.Get_Keys().Where{ $RightLeft.Contains($_) }.ForEach{ $On.Add($_) }
                    }
                    for ($i = 0; $i -lt [math]::Max($On.Count, $Equals.Count); $i++) {
                        if ($i -ge $On.Count) { $On.Add($Equals[$i]) }
                        if (!$LeftRight.ContainsKey($On[$i])) { throw [ArgumentException]"The property '$($On[$i])' cannot be found on the left object." }
                        if ($i -ge $Equals.Count) { $Equals.Add($On[$i]) }
                        if (!$RightLeft.ContainsKey($Equals[$i])) { throw [ArgumentException]"The property '$($Equals[$i])' cannot be found on the right object." }
                        $LeftRight[$On[$i]] = $Equals[$i]
                        $RightLeft[$Equals[$i]] = $On[$i]
                    }
                    $RightIndex = 0; foreach ($Right in $RightObject) {
                        $JoinKeys = foreach ($Name in $Equals) { $Right[$Name] }
                        $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                        else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                        if ($RightList.ContainsKey($HashKey)) { $RightList[$HashKey].Add($RightIndex++) } else { $RightList.Add($HashKey, $RightIndex++) }
                    }
                }
                if ($Property) {
                    foreach ($Item in @($Property)) {
                        if ($Item -is [System.Collections.IDictionary]) { foreach ($Key in $Item.Get_Keys()) { SetExpression $Key $Item[$Key] } }
                        else { SetExpression $Item }
                    }
                } else { SetExpression }
            }
            $InnerLeft = $Null
            $RightIndices = if ($On.Count) {
                if ($JoinType -eq 'Cross') { throw [ArgumentException]'The On parameter cannot be used on a cross join.' }
                $JoinKeys = foreach ($Name in $On) { $Left[$Name] }
                $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                $RightList[$HashKey]
            }
            elseif ($OnExpression) {
                if ($JoinType -eq 'Cross') { throw [ArgumentException]'The OnExpression parameter cannot be used on a cross join.' }
                for ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {
                    $Right = $RightObject[$RightIndex]; if (& $OnExpression) { $RightIndex }
                }
            }
            elseif ($JoinType -eq 'Cross') { 0..($RightObject.Length - 1) }
            elseif ($LeftIndex -lt $RightLength) { $LeftIndex } else { $Null }
            foreach ($RightIndex in $RightIndices) {
                $Right = $RightObject[$RightIndex]
                if (& $Where) {
                    OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex -Left $Left -Right $Right
                    $InnerLeft = $True
                    $InnerRight[$RightIndex] = $True
                }
            }
            $RightIndex = $Null; $Right = $RightNull
            if (!$InnerLeft -and ($JoinType -eq 'Left' -or $JoinType -eq 'Full')) {
                if (& $Where) { OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex -Left $Left -Right $Right }
            }
        }
        $StringComparer = if ($MatchCase) { [StringComparer]::Ordinal } Else { [StringComparer]::OrdinalIgnoreCase }
        if ($PSBoundParameters.ContainsKey('Discern') -and !$Discern) { $Discern = @() }
        $RightList = [Collections.Generic.Dictionary[string, [Collections.Generic.List[Int]]]]::new($StringComparer)
        $Esc = [char]27; $EscSeparator = $Esc + ', '
        $Expressions = [Ordered]@{}
        if ($RightObject -isnot [array] -and $RightObject -isnot [Data.DataTable]) { $RightObject = @($RightObject) }
        $LeftKeys = $Null
        $RightKeys = @(GetKeys ($RightObject | Select-Object -First 1))
        $RightObject = @(foreach ($Right in $RightObject) {
           if ($Right -is [Collections.IDictionary]) { $RightObject; Break } else { GetProperties $Right $RightKeys }
        })
        $LeftRight = @{}; $RightLeft = @{}; $LeftNull = [ordered]@{}; $RightNull = [ordered]@{}
        foreach ($Key in $RightKeys) {
                $RightLeft[$Key] = $Null                                        # Right to Left relation
                $RightNull[$Key] = if ($RightObject[$Key] -isnot [Collections.ObjectModel.Collection[psobject]]) { $Null }
                                   else { [Collections.ObjectModel.Collection[psobject]](,$Null * $RightObject[$Key].Count) }
        }
        $LeftKeys, $SelfJoin = $Null
        $RightLength = @($RightObject).Length; $LeftIndex = 0; $InnerRight = [Boolean[]](@($False) * $RightLength)
    }
    process {
        if ($Null -eq $SelfJoin) { $SelfJoin = !$PSBoundParameters.ContainsKey('LeftObject') }
        if (!$SelfJoin) { ProcessObject $LeftObject; $LeftIndex++ }
    }
    end {
        if ($SelfJoin) { ForEach ($Left in $RightObject) { ProcessObject $Left; $LeftIndex++ } }
        if ($JoinType -eq 'Right' -or $JoinType -eq 'Full') {
            $LeftIndex = $Null; $Left = $LeftNull
            $RightIndex = 0; foreach ($Right in $RightObject) {
                if (!$InnerRight[$RightIndex]) {
                    if (& $Where) { OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex -Left $Left -Right $Right }
                }
                $RightIndex++
            }
        }
    }
}; Set-Alias Join Join-Object

function Copy-Command ([System.Management.Automation.CommandInfo]$Command, [string]$Name, [hashtable]$DefaultParameters) {
    try {
        $MetaData = [System.Management.Automation.CommandMetadata]$Command
        $Value = [System.Management.Automation.ProxyCommand]::Create($MetaData)
        $Null = New-Item -Path Function:\ -Name "Script:$Name" -Value $Value -Force
        foreach ($Key in $DefaultParameters.Keys) { $PSDefaultParameterValues[$Name + ':' + $Key] = $DefaultParameters[$Key] }
    } catch { $PSCmdlet.WriteError($_) }
}

$JoinCommand = Get-Command Join-Object
Copy-Command -Command $JoinCommand -Name InnerJoin-Object -Default @{ JoinType = 'Inner' }; Set-Alias InnerJoin InnerJoin-Object
Copy-Command -Command $JoinCommand -Name LeftJoin-Object  -Default @{ JoinType = 'Left' };  Set-Alias LeftJoin  LeftJoin-Object
Copy-Command -Command $JoinCommand -Name RightJoin-Object -Default @{ JoinType = 'Right' }; Set-Alias RightJoin RightJoin-Object
Copy-Command -Command $JoinCommand -Name FullJoin-Object  -Default @{ JoinType = 'Full' };  Set-Alias FullJoin  FullJoin-Object
Copy-Command -Command $JoinCommand -Name CrossJoin-Object -Default @{ JoinType = 'Cross' }; Set-Alias CrossJoin CrossJoin-Object
Copy-Command -Command $JoinCommand -Name Update-Object    -Default @{ JoinType = 'Left'; Property = @{ '*' = 'Right.*' } }; Set-Alias Update Update-Object
Copy-Command -Command $JoinCommand -Name Merge-Object     -Default @{ JoinType = 'Full'; Property = @{ '*' = 'Right.*' } }; Set-Alias Merge  Merge-Object
