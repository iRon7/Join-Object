<#PSScriptInfo
.VERSION 3.3.0
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR iRon
.DESCRIPTION Join-Object combines two objects lists based on a related property between them.
.COMPANYNAME
.COPYRIGHT
.TAGS Join-Object Join InnerJoin LeftJoin RightJoin FullJoin CrossJoin Update Merge Combine Table
.LICENSE https://github.com/iRon7/Join-Object/LICENSE
.PROJECTURI https://github.com/iRon7/Join-Object
.ICONURI https://raw.githubusercontent.com/iRon7/Join-Object/master/Join-Object.png
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
        The -Discern parameter defines how to discern the left and right object properties with respect to the
        common properties that aren't related.

        The first string defines how to rename the left property, the second string (if defined) defines how to
        rename the right property. If the string contains an asterisks (*), the asterisks will be replaced with
        the original property name, otherwise, the property name will be prefixed with the given string.

        Properties that don't exist on both sides will not be renamed.

        Joined (equal) properties (defined by the -On parameter) will be merged.

        Note: The -Discern parameter cannot be used with the -Property parameter.

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
        * A left property: Left.'<Property Name>', or right property: Right.'<Property Name>', where
          <Property Name> represents the property name of the either the left or right property. If the property
          doesn't exist, the value of the property will be $Null.
        * A left wildcard property: Left.'*', or right wildcard property: Right.'*', where '*' represents the
          property name of the current the left or right property, e.g. 'MyProperty' in @{ MyProperty = 'Left.*' }.
          If the property doesn't exist (in an outer join), the property with the same name at the other side will
          be taken. If the property doesn't exist on either side, the value of the property will be $Null.
          The argument: -Property 'Left.*', will apply a left wildcard property on all the left object properties.

        If the -Property parameter and the -Discern parameter are omitted, a general wildcard property is applied
        on all the left and right properties.

        The last defined expression or smart property will overrule any previous defined properties.

        Note: The -Property parameter cannot be used with the -Discern parameter.

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
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Property')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Discern')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'OnProperty')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'OnDiscern')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'ExpressionProperty')]
        [Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'ExpressionDiscern')]
        $LeftObject,

        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Default')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'On')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Expression')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Property')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Discern')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'OnProperty')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'OnDiscern')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'ExpressionProperty')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'ExpressionDiscern')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Self')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOn')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpression')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfProperty')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfDiscern')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOnProperty')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOnDiscern')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpressionProperty')]
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpressionDiscern')]
        $RightObject,

        [Parameter(Position = 1, ParameterSetName = 'On', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'OnProperty', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'OnDiscern', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfOn', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfOnProperty', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfOnDiscern', Mandatory = $True)]
        [Alias("Using")] [String[]]$On,

        [Parameter(Position = 1, ParameterSetName = 'Expression', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'ExpressionProperty', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'ExpressionDiscern', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfExpression', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfExpressionProperty', Mandatory = $True)]
        [Parameter(Position = 1, ParameterSetName = 'SelfExpressionDiscern', Mandatory = $True)]
        [Alias("UsingExpression")] [scriptblock]$OnExpression,

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'OnProperty')]
        [Parameter(ParameterSetName = 'OnDiscern')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfOnProperty')]
        [Parameter(ParameterSetName = 'SelfOnDiscern')]
        [String[]]$Equals,

        [Parameter(Position = 2, ParameterSetName = 'Discern', Mandatory = $True)]
        [Parameter(Position = 2, ParameterSetName = 'OnDiscern', Mandatory = $True)]
        [Parameter(Position = 2, ParameterSetName = 'ExpressionDiscern', Mandatory = $True)]
        [Parameter(Position = 2, ParameterSetName = 'SelfDiscern', Mandatory = $True)]
        [Parameter(Position = 2, ParameterSetName = 'SelfOnDiscern', Mandatory = $True)]
        [Parameter(Position = 2, ParameterSetName = 'SelfExpressionDiscern', Mandatory = $True)]
        [AllowEmptyString()] [String[]]$Discern,

        [Parameter(ParameterSetName = 'Property', Mandatory = $True)]
        [Parameter(ParameterSetName = 'OnProperty', Mandatory = $True)]
        [Parameter(ParameterSetName = 'ExpressionProperty', Mandatory = $True)]
        [Parameter(ParameterSetName = 'SelfProperty', Mandatory = $True)]
        [Parameter(ParameterSetName = 'SelfOnProperty', Mandatory = $True)]
        [Parameter(ParameterSetName = 'SelfExpressionProperty', Mandatory = $True)]
        $Property,

        [Parameter(Position = 3, ParameterSetName = 'Default')]
        [Parameter(Position = 3, ParameterSetName = 'On')]
        [Parameter(Position = 3, ParameterSetName = 'Expression')]
        [Parameter(Position = 3, ParameterSetName = 'Property')]
        [Parameter(Position = 3, ParameterSetName = 'Discern')]
        [Parameter(Position = 3, ParameterSetName = 'OnProperty')]
        [Parameter(Position = 3, ParameterSetName = 'OnDiscern')]
        [Parameter(Position = 3, ParameterSetName = 'ExpressionProperty')]
        [Parameter(Position = 3, ParameterSetName = 'ExpressionDiscern')]
        [Parameter(Position = 3, ParameterSetName = 'Self')]
        [Parameter(Position = 3, ParameterSetName = 'SelfOn')]
        [Parameter(Position = 3, ParameterSetName = 'SelfExpression')]
        [Parameter(Position = 3, ParameterSetName = 'SelfProperty')]
        [Parameter(Position = 3, ParameterSetName = 'SelfDiscern')]
        [Parameter(Position = 3, ParameterSetName = 'SelfOnProperty')]
        [Parameter(Position = 3, ParameterSetName = 'SelfOnDiscern')]
        [Parameter(Position = 3, ParameterSetName = 'SelfExpressionProperty')]
        [Parameter(Position = 3, ParameterSetName = 'SelfExpressionDiscern')]
        [scriptblock]$Where = { $True },

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'Expression')]
        [Parameter(ParameterSetName = 'Property')]
        [Parameter(ParameterSetName = 'Discern')]
        [Parameter(ParameterSetName = 'OnProperty')]
        [Parameter(ParameterSetName = 'OnDiscern')]
        [Parameter(ParameterSetName = 'ExpressionProperty')]
        [Parameter(ParameterSetName = 'ExpressionDiscern')]
        [Parameter(ParameterSetName = 'Self')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfExpression')]
        [Parameter(ParameterSetName = 'SelfProperty')]
        [Parameter(ParameterSetName = 'SelfDiscern')]
        [Parameter(ParameterSetName = 'SelfOnProperty')]
        [Parameter(ParameterSetName = 'SelfOnDiscern')]
        [Parameter(ParameterSetName = 'SelfExpressionProperty')]
        [Parameter(ParameterSetName = 'SelfExpressionDiscern')]
        [ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')] $JoinType = 'Inner',

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'OnProperty')]
        [Parameter(ParameterSetName = 'OnDiscern')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfOnProperty')]
        [Parameter(ParameterSetName = 'SelfOnDiscern')]
        [switch]$Strict,

        [Parameter(ParameterSetName = 'On')]
        [Parameter(ParameterSetName = 'OnProperty')]
        [Parameter(ParameterSetName = 'OnDiscern')]
        [Parameter(ParameterSetName = 'SelfOn')]
        [Parameter(ParameterSetName = 'SelfOnProperty')]
        [Parameter(ParameterSetName = 'SelfOnDiscern')]
        [Alias("CaseSensitive")] [switch]$MatchCase
    )
    begin {
        $LeftIndex, $RightIndex, $HashTable = $Null
        $Esc = [char]27; $EscSeparator = $Esc + ', '
        $Expressions = [Ordered]@{}
        if ($RightObject -isnot [array] -and $RightObject -isnot [Data.DataTable]) { $RightObject = @($RightObject) }
        $RightKeys = @(
            if ($RightObject -is [Data.DataTable]) { $RightObject.Columns | Select-Object -ExpandProperty 'ColumnName' }
            else {
                $First = $RightObject | Select-Object -First 1
                if ($First -is [System.Collections.IDictionary]) { $First.Get_Keys() }
                else { $First.PSObject.Properties | Select-Object -ExpandProperty 'Name' }
            }
        )
        $RightLeft = @{}; foreach ($Key in $RightKeys) { $RightLeft[$Key] = $Null } # Right to Left relation
        $RightLength = @($RightObject).Length; $LeftIndex = 0; $InnerRight = [Boolean[]](@($False) * $RightLength)
        function OutObject ($LeftIndex, $RightIndex, $LeftItem = @{}, $RightItem = @{}) {
            if ($LeftItem  -is [System.Collections.IDictionary]) { $Left = $LeftItem }
            else {
                $Left = [Ordered]@{}
                foreach ($Property in $LeftItem.psobject.properties)  { $Left[$Property.Name]  = $Property.Value }
            }
            if ($RightItem  -is [System.Collections.IDictionary]) { $Right = $RightItem }
            else {
                $Right = [Ordered]@{}
                foreach ($Property in $RightItem.psobject.properties) { $Right[$Property.Name] = $Property.Value }
            }
            if (& $Where) {
                $Nodes = [Ordered]@{}
                foreach ($_ in $Expressions.Get_Keys()) {
                    $Nodes[$_] = if ($Expressions[$_] -is [scriptblock]) { & $Expressions[$_] } else {
                        $Key = $Expressions[$_]
                        if ($LeftRight.Contains($Key) -or $RightLeft.Contains($Key)) {
                            if ($LeftRight.Contains($Key) -and $RightLeft.Contains($Key)) { $Left[$Key], $Right[$Key] }
                            elseif ($LeftRight.Contains($Key)) { $Left[$Key] }
                            else { $Right[$Key] } # if($RightLeft.Contains($_))
                        }
                        elseif ($Key.Trim() -eq '*') {
                            if ($LeftRight.Contains($_) -and $RightLeft.Contains($_)) {
                                if ($LeftRight[$_] -eq $_) { if ($Left.Contains($_)) { $Left[$_] } else { $Right[$_] } }
                                elseif ($Null -eq $LeftRight[$_] -and $Null -ne $RightLeft[$_]) { $Left[$_] }
                                elseif ($Null -ne $LeftRight[$_] -and $Null -eq $RightLeft[$_]) { $Right[$_] }
                                else { $Left[$_], $Right[$_] }
                            }
                            elseif ($LeftRight.Contains($_))  {
                                if ($Left.Contains($_)) { $Left[$_] }
                                elseif ($Null -ne $LeftRight[$_]) { $Right[$LeftRight[$_]] }
                            }
                            elseif ($RightLeft.Contains($_)) {
                                if ($Right.Contains($_)) { $Right[$_] }
                                elseif ($Null -ne $RightLeft[$_]) { $Left[$RightLeft[$_]] }
                            }
                        }
                        else {
                            $Side, $Key = $Key.Split('.', 2)
                            if ($Null -ne $Key) {
                                if ($Side[0] -eq 'L') {
                                    if ($LeftRight.Contains($Key)) { $Left[$Key] }
                                    elseif ($Key -eq '*') {
                                        if ($Left.Contains($_)) { $Left[$_] }
                                        elseif ($Right.Contains($_)) { $Right[$_] }
                                    }
                                }
                                if ($Side[0] -eq 'R') {
                                    if ($RightLeft.Contains($Key)) { $Right[$Key] }
                                    elseif ($Key -eq '*') {
                                        if ($Right.Contains($_)) { $Right[$_] }
                                        elseif ($Left.Contains($_)) { $Left[$_] }
                                    }
                                }
                            } else { throw [ArgumentException]"The property '$Key' doesn't exists" }
                        }
                    }
                }
                New-Object PSCustomObject -Property $Nodes
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
    }
    process {
        try {
            $SelfJoin = !$PSBoundParameters.ContainsKey('LeftObject'); if ($SelfJoin) { $LeftObject = $RightObject }
            foreach ($Left in @($LeftObject)) {
                if (!$LeftIndex) {
                    $LeftKeys = @(
                        if ($Left -is [Data.DataRow]) { $Left.Table.Columns | Select-Object -ExpandProperty 'ColumnName' }
                        elseif ($Left -is [System.Collections.IDictionary]) { $Left.Get_Keys() }
                        else { $Left.PSObject.Properties | Select-Object -ExpandProperty 'Name' }
                    )
                    $LeftRight = @{}; foreach ($Key in $LeftKeys) { $LeftRight[$Key] = $Null } # Left to Right relation
                    $BothKeys = New-Object System.Collections.Generic.HashSet[Object]
                    foreach ($Key in ($LeftKeys + $RightKeys)) { $Null = $BothKeys.Add($Key) }
                    if ($Null -ne $On) {
                        if ($On.Trim() -eq '*' -and !$BothKeys.Contains('*')) { # Use e.g. -On ' * ' if there exists an '*' property
                            $On = $LeftRight.Get_Keys() | Where-Object { $RightLeft.Contains($_) }
                        }
                        $On = if ($On) {, @($On) } else {, @() }; $Equals = if ($Equals) {, @($Equals) } else {, @() }
                        for ($i = 0; $i -lt [math]::Max($On.Length, $Equals.Length); $i++) {
                            if ($i -ge $On.Length) { $On += $Equals[$i] }
                            if (!$LeftRight.ContainsKey($On[$i])) { throw [ArgumentException]"The property '$($On[$i])' cannot be found on the left object." }
                            if ($i -ge $Equals.Length) { $Equals += $On[$i] }
                            if (!$RightLeft.ContainsKey($Equals[$i])) { throw [ArgumentException]"The property '$($Equals[$i])' cannot be found on the right object." }
                            $LeftRight[$On[$i]] = $Equals[$i]
                            $RightLeft[$Equals[$i]] = $On[$i]
                        }
                        $HashTable = if ($MatchCase) { [hashtable]::new(0, [StringComparer]::Ordinal) } else { @{} }
                        $RightIndex = 0; foreach ($Right in $RightObject) {
                            $JoinKeys = if ($Right  -is [System.Collections.IDictionary]) {
                                foreach ($Name in @($Equals)) { $Right[$Name] }
                            } else {
                                foreach ($Name in @($Equals)) { $Right.PSObject.Properties[$Name].Value }
                            }
                            $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                            else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                            [array]$HashTable[$HashKey] += $RightIndex++
                        }
                    }
                    if ($Discern) {
                        if (@($Discern).Count -le 1) { $Discern = @($Discern) + '' }
                        foreach ($Key in $LeftKeys) {
                            if ($RightLeft.ContainsKey($Key)) {
                                if ($LeftRight[$Key] -eq $Key) { $Expressions[$Key] = ' * ' }
                                elseif ($Null -ne $LeftRight[$Key]) {  $Expressions[$LeftRight[$Key]] = 'Left.' + $Key }
                                elseif ($Null -eq $RightLeft[$Key]) {
                                    $Name = if ($Discern[0].Contains('*')) { ([regex]"\*").Replace($Discern[0], $Key, 1) } else { $Discern[0] + $Key }
                                    $Expressions[$Name] = 'Left.' + $Key
                                } else { $Expressions[$Key] = 'Left.' + $Key }
                            } else { $Expressions[$Key] = ' * ' }
                        }
                        foreach ($Key in $RightKeys) {
                            if ($Null -eq $RightLeft[$Key]) {
                                if ($LeftRight.ContainsKey($Key) -and $Null -eq $LeftRight[$Key]) {
                                    $Name = if ($Discern[1].Contains('*')) { ([regex]'\*').Replace($Discern[1], $Key, 1) } else { $Discern[1] + $Key }
                                    $Expressions[$Name] = 'Right.' + $Key
                                } else { $Expressions[$Key] = 'Right.' + $Key }
                            }
                        }
                    } elseif ($Property) {
                        foreach ($Item in @($Property)) {
                            if ($Item -is [System.Collections.IDictionary]) { foreach ($Key in $Item.Get_Keys()) { SetExpression $Key $Item[$Key] } }
                            else { SetExpression $Item }
                        }
                    } else { SetExpression }
                }
                $InnerLeft = $Null
                $RightList = if ($On) {
                    if ($JoinType -eq 'Cross') { throw [ArgumentException]'The On parameter cannot be used on a cross join.' }
                    $JoinKeys = if ($Left  -is [System.Collections.IDictionary]) {
                            foreach ($Name in @($On)) { $Left[$Name] }
                        } else {
                            foreach ($Name in @($On)) { $Left.PSObject.Properties[$Name].Value }
                        }
                    $HashKey = if (!$Strict) { [string]::Join($EscSeparator, @($JoinKeys)) }
                    else { [System.Management.Automation.PSSerializer]::Serialize($JoinKeys) }
                    $HashTable[$HashKey]
                } elseif ($OnExpression) {
                    if ($JoinType -eq 'Cross') { throw [ArgumentException]'The OnExpression parameter cannot be used on a cross join.' }
                    for ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {
                        $Right = $RightObject[$RightIndex]; if (& $OnExpression) { $RightIndex }
                    }
                }
                elseif ($JoinType -eq 'Cross') { 0..($RightObject.Length - 1) }
                elseif ($LeftIndex -lt $RightLength) { $LeftIndex } else { $Null }
                foreach ($RightIndex in $RightList) {
                    $Right = if ($RightObject -is [Data.DataTable]) { $RightObject.Rows[$RightIndex] } else { $RightObject[$RightIndex] }
                    $OutObject = OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex -LeftItem $Left -RightItem $Right
                    if ($Null -ne $OutObject) { $OutObject; $InnerLeft = $True; $InnerRight[$RightIndex] = $True }
                }
                if (!$InnerLeft -and ($JoinType -eq 'Left' -or $JoinType -eq 'Full')) { OutObject -LeftIndex $LeftIndex -LeftItem $Left }
                $LeftIndex++
            }
        } catch [ArgumentException]{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        if ($JoinType -eq 'Right' -or $JoinType -eq 'Full') { $Left = $Null
            $RightIndex = 0; foreach ($Right in $RightObject) {
                if (!$InnerRight[$RightIndex]) { OutObject -RightIndex $RightIndex -RightItem $Right }
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
