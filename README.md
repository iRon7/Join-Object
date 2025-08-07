<!-- markdownlint-disable MD033 -->
# Join-Object

Combines two object lists based on a related property between them.

## Syntax

```PowerShell
Join-Object
    [-LeftObject <Object>]
    [-RightObject <Object>]
    [-On <Array> = @()]
    [-Equals <Array> = @()]
    [-Discern <String[]>]
    [-Property <Object>]
    [-Where <ScriptBlock>]
    [-JoinType <String> = 'Inner']
    [-ValueName <String> = '<Value>']
    [-Strict]
    [-MatchCase]
    [<CommonParameters>]
```

```PowerShell
Join-Object
    [-LeftObject <Object>]
    [-RightObject <Object>]
    [-Using <ScriptBlock>]
    [-Discern <String[]>]
    [-Property <Object>]
    [-Where <ScriptBlock>]
    [-JoinType <String> = 'Inner']
    [-ValueName <String> = '<Value>']
    [<CommonParameters>]
```

## Description

[This module][1] provides a set of commands to combine the properties from one or more objects.
It creates a set that can be saved as a new object or used as it is.
An object join is a means for combining properties from one (self-join) or more object lists
by using values common to each.

Main features:
* An intuitive idiomatic PowerShell syntax
* SQL like joining features
* Smart property merging
* Predefined join commands for updating, merging and specific join types
* Well defined pipeline for the (left) input objects and output objects (streaming preserves memory)
* Performs about twice as fast as Compare-Object on large object lists
* Supports a list of (custom) objects, strings or primitives and dictionaries (e.g. hash tables) and data tables for input
* Smart properties and calculated property expressions
* Custom relation expressions
* Supports PowerShell for Windows (5.1) and PowerShell Core

The Join-Object cmdlet reveals the following proxy commands and aliases with their own
([`-JoinType`](#-jointype) and [`-Property`](#-property)) defaults:
* `InnerJoin` (Alias `InnerJoin-Object` or `Join`), combines the related objects
* `LeftJoin` (Alias `LeftJoin-Object`), combines the related objects and adds the rest of the left objects
* `RightJoin` (Alias `RightJoin-Object`), combines the related objects and adds the rest of the right objects
* `OuterJoin` (Alias `OuterJoin-Object`), returns the symmetric difference of the unrelated objects
* `FullJoin` (Alias `FullJoin-Object`), combines the related objects and adds the rest of the left and right objects
* `CrossJoin` (Alias `CrossJoin-Object`), combines each left object with each right object
* `Update-Object` (Alias `Update`), updates the left object with the related right object
* `Merge-Object` (Alias `Merge`), updates the left object with the related right object and adds the rest of the new (unrelated) right objects
* `Get-Difference` (Alias `Differs`), returns the symmetric different objects and their properties

> [!Note](#note)
> Some unapproved verb cmdlets (as e.g. `FullJoin-Object`) are provided as aliases to prevent a
> "*unapproved verbs*" warning during the module import. For details see: [PowerShell\issues\25642][2].

## Examples

### <a id="example-1"><a id="example-common-inner-join">Example 1: Common (inner) join</a></a>

The following example will show an inner join based on the `country` property.  
Given the following object lists:

```PowerShell
$Employee

Id Name    Country Department  Age ReportsTo
-- ----    ------- ----------  --- ---------
 1 Aerts   Belgium Sales        40         5
 2 Bauer   Germany Engineering  31         4
 3 Cook    England Sales        69         1
 4 Duval   France  Engineering  21         5
 5 Evans   England Marketing    35
 6 Fischer Germany Engineering  29         4

$Department

Name        Country
----        -------
Engineering Germany
Marketing   England
Sales       France
Purchase    France


$Employee | Join $Department -On Country | Format-Table

Id Name                   Country Department  Age ReportsTo
-- ----                   ------- ----------  --- ---------
 2 {Bauer, Engineering}   Germany Engineering  31         4
 3 {Cook, Marketing}      England Sales        69         1
 4 {Duval, Sales}         France  Engineering  21         5
 4 {Duval, Purchase}      France  Engineering  21         5
 5 {Evans, Marketing}     England Marketing    35
 6 {Fischer, Engineering} Germany Engineering  29         4
```

### <a id="example-2"><a id="example-full-join-overlapping-column-names">Example 2: Full join overlapping column names</a></a>


The example below does a full join of the tables mentioned in the first example based
on the `department` name and splits the duplicate (`country`) names over different properties.

```PowerShell
$Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

Id Name    EmployeeCountry DepartmentCountry Department  Age ReportsTo
-- ----    --------------- ----------------- ----------  --- ---------
 1 Aerts   Belgium         France            Sales        40         5
 2 Bauer   Germany         Germany           Engineering  31         4
 3 Cook    England         France            Sales        69         1
 4 Duval   France          Germany           Engineering  21         5
 5 Evans   England         England           Marketing    35
 6 Fischer Germany         Germany           Engineering  29         4
```

### <a id="example-3"><a id="example-merge-a-table-with-updates">Example 3: merge a table with updates</a></a>


This example merges the following `$Changes` list into the `$Employee` list of the first example.

```PowerShell
$Changes

Id Name    Country Department  Age ReportsTo
-- ----    ------- ----------  --- ---------
 3 Cook    England Sales        69         5
 6 Fischer France  Engineering  29         4
 7 Geralds Belgium Sales        71         1

# Apply the changes to the employees
$Employee | Merge $Changes -On Id | Format-Table

Id Name    Country Department  Age ReportsTo
-- ----    ------- ----------  --- ---------
 1 Aerts   Belgium Sales        40         5
 2 Bauer   Germany Engineering  31         4
 3 Cook    England Sales        69         5
 4 Duval   France  Engineering  21         5
 5 Evans   England Marketing    35
 6 Fischer France  Engineering  29         4
 7 Geralds Belgium Sales        71         1
```

### <a id="example-4"><a id="example-self-join">Example 4: Self join</a></a>


This example shows a (self)join where each employee is connected with another employee on the country.

```PowerShell
$Employee | Join -On Country -Discern *1,*2 | Format-Table *

Id1 Id2 Name1   Name2   Country Department1 Department2 Age1 Age2 ReportsTo1 ReportsTo2
--- --- -----   -----   ------- ----------- ----------- ---- ---- ---------- ----------
 2   6 Bauer   Fischer Germany Engineering Engineering   31   29          4          4
 3   5 Cook    Evans   England Sales       Marketing     69   35          1
 5   3 Evans   Cook    England Marketing   Sales         35   69                     1
 6   2 Fischer Bauer   Germany Engineering Engineering   29   31          4          4
```

### <a id="example-5"><a id="example-join-a-scalar-array">Example 5: Join a scalar array</a></a>


This example adds an Id to the department list.  

> [!Note](#note)
> The default column name of (nameless) scalar array is `<Value>` this will show when the [`-ValueName`](#-valuename) parameter is omitted.

```PowerShell
1..9 | Join $Department -ValueName Id

Id Name        Country
-- ----        -------
 1 Engineering Germany
 2 Marketing   England
 3 Sales       France
 4 Purchase    France
```

### <a id="example-6"><a id="example-transpose-arrays">Example 6: Transpose arrays</a></a>


The following example, the `join-Object` cmdlet (`... | Join`) joins multiple arrays to a collection array.  
The [`Foreach-Object`](https://go.microsoft.com/fwlink/?LinkID=2096867) cmdlet iterates over the rows and the `-Join` operator concatenates the item collections

```PowerShell
$a = 'a1', 'a2', 'a3', 'a4'
$b = 'b1', 'b2', 'b3', 'b4'
$c = 'c1', 'c2', 'c3', 'c4'
$d = 'd1', 'd2', 'd3', 'd4'

$a | Join $b | Join $c | Join $d | % { $_ -Join '|' }

a1|b1|c1|d1
a2|b2|c2|d2
a3|b3|c3|d3
a4|b4|c4|d4
```

### <a id="example-7"><a id="example-arrays-to-objects">Example 7: Arrays to objects</a></a>


This example will change the collections of the previous example into objects with named properties.

```PowerShell
$a | Join $b | Join $c | Join $d -Name a, b, c, d

a  b  c  d
-  -  -  -
a1 b1 c1 d1
a2 b2 c2 d2
a3 b3 c3 d3
a4 b4 c4 d4
```

## Parameters

### <a id="-leftobject">`-LeftObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The left object list, usually provided through the pipeline, to be joined.

> [!Note](#note)
> A **self-join** on the `LeftObject` list will be performed if the `RightObject` is omitted.

```powershell
Name:                       -LeftObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-rightobject">`-RightObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The right object list, provided by the first argument, to be joined.

> [!Note](#note)
> A **self-join** on the `RightObject` list will be performed if the `LeftObject` is omitted.

```powershell
Name:                       -RightObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-on">`-On` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Array">&lt;Array&gt;</a></a>

The [`-On`](#-on) parameter defines which objects should be joined together.  
If the [`-Equals`](#-equals) parameter is omitted, the value(s) of the properties listed by the [`-On`](#-on) parameter should be
equal at both sides in order to join the left object with the right object.  
If the [`-On`](#-on) parameter contains an expression, the expression will be evaluated where `$_`, `$PSItem` and
`$Left` contains the current object. The result of the expression will be compared to right object property
defined by the [`-Equals`](#-equals) parameter.

> [!Note](#note)
> The list of properties defined by the [`-On`](#-on) parameter will be complemented with the list of
> properties defined by the [`-Equals`](#-equals) parameter and vice versa.

> [!Note](#note)
> Related properties will be merged to a single property by default (see also the [`-Property`](#-property) parameter).

> [!Tip](#tip)
> If the [`-On`](#-on) and the [`-Using`](#-using) parameter are omitted, a side-by-side join is returned unless
> `OuterJoin` is performed where the default [`-On`](#-on) parameter value is * (all properties).

> [!Tip](#tip)
> if the left object is a scalar array, the [`-On`](#-on) parameters is used to name the scalar array.

```powershell
Name:                       -On
Aliases:                    # None
Type:                       [Array]
Value (default):            @()
Parameter sets:             On
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-using">`-Using` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.ScriptBlock">&lt;ScriptBlock&gt;</a></a>

Any conditional expression that requires to evaluate to true in order to join the left object with the
right object.

The following variables are exposed for a (ScriptBlock) expression:
* `$_`: iterates each property name
* `$Left`: a hash table representing the current left object (each self-contained [`-LeftObject`](#-leftobject)).
The hash table will be empty (`@{}`) in the outer part of a left join or full join.
* `$LeftIndex`: the index of the left object (`$Null` in the outer part of a right- or full join)
* `$Right`: a hash table representing the current right object (each self-contained [`-RightObject`](#-rightobject))
The hash table will be empty (`@{}`) in the outer part of a right join or full join.
* `$RightIndex`: the index of the right object (`$Null` in the outer part of a left- or full join)

> [!Warning](#warning)
> The [`-Using`](#-using) parameter has the most complex comparison possibilities but is considerable slower
> than the [`-On`](#-on) parameter.

> [!Note](#note)
> The [`-Using`](#-using) parameter cannot be used with the [`-On`](#-on) parameter.

```powershell
Name:                       -Using
Aliases:                    # None
Type:                       [ScriptBlock]
Value (default):            # Undefined
Parameter sets:             Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-equals">`-Equals` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Array">&lt;Array&gt;</a></a>

If the [`-Equals`](#-equals) parameter is supplied, the value(s) of the left object properties listed by the [`-On`](#-on)
parameter should be equal to the value(s) of the right object listed by the [`-Equals`](#-equals) parameter in order to
join the left object with the right object.  
If the [`-Equals`](#-equals) parameter contains an expression, the expression will be evaluated where `$_`, `$PSItem` and
`$Right` contains the current object. The result of the expression will be compared to left object property
defined by the [`-On`](#-on) parameter.

> [!Note](#note)
> The list of properties defined by the [-Equal](#equal) parameter will be complemented with the list of properties
> defined by the -On parameter and vice versa. This means that by default value of the [`-Equals`](#-equals) parameter
> is equal to the value supplied to the [`-On`](#-on) parameter.

> [!Note](#note)
> A property will be omitted in the results if it exists on both sides and if the property at the other side
> is related to another property.

> [!Note](#note)
> The [`-Equals`](#-equals) parameter can only be used with the [`-On`](#-on) parameter.

> [!Tip](#tip)
> if the right object is a scalar array, the [`-Equals`](#-equals) parameters is used to name the scalar array.

```powershell
Name:                       -Equals
Aliases:                    -Eq
Type:                       [Array]
Value (default):            @()
Parameter sets:             On
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-discern">`-Discern` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

By default unrelated properties with the same name will be collected in a single object property.
The [`-Discern`](#-discern) parameter (alias [-NameItems](#nameitems))  defines how to rename the object properties and divide
them over multiple properties. If a given name pattern contains an asterisks (`*`), the asterisks
will be replaced with the original property name. Otherwise, the property name for each property
item will be prefixed with the given name pattern.

The property collection of multiple (chained) join commands can be divided in once from the last join
command in the change. The rename patterns are right aligned, meaning that the last renamed pattern
will be applied to the last object joined. If there are less rename patterns than property items,
the rest of the (left most) property items will be put in a fixed array under the original property name.

> [!Note](#note)
> As apposed to the [`-On`](#-on) parameter, properties with the same name on both sides will not be renamed.

> [!Note](#note)
> Related properties (with an equal value defined by the [`-On`](#-on) parameter) will be merged to a single item.

```powershell
Name:                       -Discern
Aliases:                    -NameItems
Type:                       [String[]]
Value (default):            # Undefined
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-property">`-Property` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

A hash table or list of property names (strings) and/or hash tables that define a new selection of
property names and values

Hash tables should be in the format `@{<PropertyName> = <Expression>}` where the `<Expression>` is a
ScriptBlock or a smart property (string) and defines how the specific left and right properties should be
merged. See the [`-Using`](#-using) parameter for available expression variables.

The following smart properties are available:
* A general property: '<Property Name>', where `<Property Name>` represents the property name of the left
and/or right property, e.g. `@{ MyProperty = 'Name' }`. If the property exists on both sides, an array
holding both values will be returned. In the outer join, the value of the property will be `$Null`.
This smart property is similar to the expression: `@{ MyProperty = { @($Left['Name'], $Right['Name']) } }`
* A general wildcard property: `'*'`, where `* `represents the property name of the current property, e.g.
`MyProperty` in `@{ MyProperty = '*' }`. If the property exists on both sides:
- and the properties are unrelated, an array holding both values will be returned
- and the properties are related to each other, the (equal) values will be merged in one property value
- and the property at the other side is related to an different property, the property is omitted
The argument: `-Property *`, will apply a general wildcard on all left and right properties.
* A left property: `;Left.<Property Name>'`, or right property: `;Right.<Property Name>'`, where
`<Property Name>` represents the property name of the either the left or right property. If the property
doesn't exist, the value of the property will be `$Null`.
* A left wildcard property: `'Left.*'`, or right wildcard property: `Right.*`, where `*` represents the
property name of the current the left or right property, e.g. `MyProperty` in `@{ MyProperty = 'Left.*' }`.
If the property doesn't exist (in an outer join), the property with the same name at the other side will
be taken. If the property doesn't exist on either side, the value of the property will be `$Null`.
The argument: `-Property 'Left.*'`, will apply a left wildcard property on all the left object properties.

If the [`-Property`](#-property) parameter and the [`-Discern`](#-discern) parameter are omitted, a general wildcard property is applied
on all the left and right properties.

The last defined expression or smart property will overrule any previous defined properties.

```powershell
Name:                       -Property
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-where">`-Where` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.ScriptBlock">&lt;ScriptBlock&gt;</a></a>

An expression that defines the condition to be met for the objects to be returned. See the [`-Using`](#-using)
parameter for available expression variables.

```powershell
Name:                       -Where
Aliases:                    # None
Type:                       [ScriptBlock]
Value (default):            # Undefined
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-jointype">`-JoinType` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">&lt;String&gt;</a></a>

Defines which unrelated objects should be included (see: [Description](#description)).
Valid values are: `Inner`, `Left`, `Right`, `Full` or `Cross`. The default is `Inner`.

> [!Tip](#tip)
> it is recommended to use the related proxy commands (`... | <JoinType>-Object ...`) instead.

```powershell
Name:                       -JoinType
Aliases:                    # None
Type:                       [String]
Value (default):            'Inner'
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-valuename">`-ValueName` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">&lt;String&gt;</a></a>

Defines the name of the added property in case a scalar array is joined with an object array.
The default property name for each scalar is: `<Value>`.

> [!Note](#note)
> if two scalar (or collection) arrays are joined, an array of (PSObject) collections is returned.
Each collection is a concatenation of the left item (collection) and the right item (collection).

```powershell
Name:                       -ValueName
Aliases:                    # None
Type:                       [String]
Value (default):            '<Value>'
Parameter sets:             On, Using
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-strict">`-Strict`</a>

If the [`-Strict`](#-strict) switch is set, the comparison between the related properties defined by the [`-On`](#-on) Parameter
(and the [`-Equals`](#-equals) parameter) is based on a strict equality (both type and value need to be equal).

```powershell
Name:                       -Strict
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             On
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-matchcase">`-MatchCase`</a>

If the [`-MatchCase`](#-matchcase) (alias `-CaseSensitive`) switch is set, the comparison between the related properties
defined by the [`-On`](#-on) Parameter (and the [`-Equals`](#-equals) parameter) will case sensitive.

```powershell
Name:                       -MatchCase
Aliases:                    -CaseSensitive
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             On
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

## Related Links

* [Join-Object on GitHub](https://github.com/iRon7/Join-Object)
* [Give the script author the ability to disable the unapproved verbs warning](https://github.com/PowerShell/PowerShell/issues/25642)
<!-- -->

* [Please give a thumbs up if you like to support the proposal to 'Add a Join-Object cmdlet to the standard PowerShell equipment'](https://github.com/PowerShell/PowerShell/issues/14994)
<!-- -->


[1]: https://github.com/iRon7/Join-Object "Join-Object on GitHub"
[2]: https://github.com/PowerShell/PowerShell/issues/25642 "Give the script author the ability to disable the unapproved verbs warning"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
