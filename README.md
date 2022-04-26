## Join-Object
Combines two object lists based on a related property between them.

## Description
Combines properties from one or more objects. It creates a set that can be saved as a new object or used as it is. An object join is a means for combining properties from one (self-join) or more object lists by using values common to each.

**Main features:**
* Intuitive (SQL like) syntax
* Smart property merging
* Predefined join commands for updating, merging and specific join types
* Well defined pipeline for the (left) input objects and output objects (preserves memory when correctly used)
* Performs about 40% faster than Compare-Object on large object lists
* Supports a list of (custom) objects, strings or primitives and dictionaries (e.g. hash tables) and data tables for input
* Smart properties and calculated property expressions
* Custom relation expressions
* Easy installation (dot-sourcing)
* Supports PowerShell for Windows (5.1) and PowerShell Core

The Join-Object cmdlet reveals the following proxy commands with their own (`-JoinType` and `-Property`) defaults:
* `InnerJoin-Object` (Alias `InnerJoin` or `Join`), combines the related objects
* `LeftJoin-Object` (Alias `LeftJoin`), combines the related objects and adds the rest of the left objects
* `RightJoin-Object` (Alias `RightJoin`), combines the related objects and adds the rest of the right objects
* `FullJoin-Object` (Alias `FullJoin`), combines the related objects and adds the rest of the left and right objects
* `OuterJoin-Object` (Alias `OuterJoin`), combines the unrelated objects
* `CrossJoin-Object` (Alias `CrossJoin`), combines each left object with each right object
* `Update-Object` (Alias `Update`), updates the left object with the related right object
* `Merge-Object` (Alias `Merge`), updates the left object with the related right object and adds the rest of the
  new (unrelated) right objects
* `Get-Difference` (Alias `Differs`), gets the symmetric difference between the object and merges the properties

## Installation
There are two versions of this `Join-Object` cmdlet (both versions supply the same functionality):

* [**Join Module**](https://www.powershellgallery.com/packages/JoinModule)

<span></span>

    Install-Module -Name JoinModule

* [**Join Script**](https://www.powershellgallery.com/packages/Join)

<span></span>

    Install-Script -Name Join

(Or rename the `Join.psm1` module to a `Join.ps1` script file) and invoked the script by [**dot sourcing**](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-6#script-scope-and-dot-sourcing): 

    . .\Join.ps1

## Examples

**Example 1**
```PowerShell
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
PS C:\> $Employee | InnerJoin $Department -On Country | Format-Table

Id Name                   Country Department  Age ReportsTo
-- ----                   ------- ----------  --- ---------
 2 {Bauer, Engineering}   Germany Engineering  31         4
 3 {Cook, Marketing}      England Sales        69         1
 4 {Duval, Sales}         France  Engineering  21         5
 4 {Duval, Purchase}      France  Engineering  21         5
 5 {Evans, Marketing}     England Marketing    35
 6 {Fischer, Engineering} Germany Engineering  29         4
```

**Example 2**
```PowerShell
PS C:\> # Full join the employees with the departments based on the department name
PS C:\> # and Split the names over differend properties
PS C:\> $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

Id Name    EmployeeCountry DepartmentCountry Department  Age ReportsTo
-- ----    --------------- ----------------- ----------  --- ---------
 1 Aerts   Belgium         France            Sales        40         5
 2 Bauer   Germany         Germany           Engineering  31         4
 3 Cook    England         France            Sales        69         1
 4 Duval   France          Germany           Engineering  21         5
 5 Evans   England         England           Marketing    35
 6 Fischer Germany         Germany           Engineering  29         4
```

**Example 3**
```PowerShell
PS C:\> $Changes

Id Name    Country Department  Age ReportsTo
-- ----    ------- ----------  --- ---------
 3 Cook    England Sales        69         5
 6 Fischer France  Engineering  29         4
 7 Geralds Belgium Sales        71         1


PS C:\> # Apply the changes to the employees
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
```

**Example 4**
```PowerShell
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
```

**Example 5**
```PowerShell
PS C:\> # Add an Id to the department list
PS C:\> 1..9 |Join $Department -ValueName Id

Id Name        Country
-- ----        -------
 1 Engineering Germany
 2 Marketing   England
 3 Sales       France
 4 Purchase    France
```

**Example 6**
```PowerShell
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
```

**Example 7**
```PowerShell
PS C:\> # Create objects with named properties from multiple arrays
PS C:\> $a |Join $b |Join $c |Join $d -Name a, b, c, d

a  b  c  d
-  -  -  -
a1 b1 c1 d1
a2 b2 c2 d2
a3 b3 c3 d3
a4 b4 c4 d4
```

## Parameters

**`-LeftObject <object list, data table or list of hash tables>`**  
The left object list, usually provided through the pipeline, to be joined.

*Note:* a self-join on the LeftObject list will be performed if the RightObject is omitted.

**`-RightObject <object list, data table or list of hash tables>`**  
The right object list, provided by the first argument, to be joined.

*Note:* a self-join on the RightObject list will be performed if the LeftObject is omitted.

**`-On <String[]>`**  
The `-On` parameter (alias `-Using`) defines which objects should be joined together.
If the `-Equals` parameter is omitted, the value(s) of the properties listed by the `-On` parameter should be equal at both sides in order to join the left object with the right object.
If the `-On` parameter contains an expression, the expression will be evaluted where `$_`, `$PSItem` and `$Left` contains the currect object. The result of the expression will be compared to right object property defined by the `-Equals` parameter.

*Note 1:* The list of properties defined by the `-On` parameter will be complemented with the list of
properties defined by the `-Equals` parameter and vice versa.

*Note 2:* Related properties will be merged to a single property by default (see also the -Property
parameter).

*Note 3:* If the -On and the `-Using` parameter are omitted, a side-by-side join is returned.

**`-Equals <String[]>`**  
If the `-Equals` parameter is supplied, the value(s) of the left object properties listed by the `-On`
parameter should be equal to the value(s)of the right object listed by the `-Equals` parameter in order to join the left object with the right object.
If the `-Equals` parameter contains an expression, the expression will be evaluted where `$_`, `$PSItem` and `$Right` contains the currect object. The result of the expression will be compared to left object property defined by the `-On` parameter.

*Note 1:* The list of properties defined by the `-Equal` parameter will be complemented with the list of properties defined by the `-On` parameter and vice versa.

*Note 2:* A property will be omitted if it exists on both sides and if the property at the other side is
related to another property.

*Note 3:* The `-Equals` parameter can only be used with the `-On` parameter.

**`-Strict`**  
If the `-Strict` switch is set, the comparison between the related properties defined by the `-On` Parameter (and the `-Equals` parameter) is based on a strict equality (both type and value need to be equal).

**`-MatchCase`**  
If the `-MatchCase` (alias `-CaseSensitive`) switch is set, the comparison between the related properties defined by the `-On` Parameter (and the `-Equals` parameter) will case sensitive.

**`-Using <ScriptBlock>`**  
Any conditional expression that requires to evaluate to true in order to join the left object with the right object.

The following variables are exposed for a (`ScriptBlock`) expression:
* **`$_`**: iterates each property name
* **`$Left`**: a hash table representing the current left object (each self-contained `-LeftObject`).
  The hash table will be empty (`@{}`) in the outer part of a left join or full join.
* **`$LeftIndex`**: the index of the left object (`$Null` in the outer part of a right- or full join)
* **`$Right`**: a hash table representing the current right object (each self-contained `-RightObject`)
  The hash table will be empty (`@{}`) in the outer part of a right join or full join.
* **`$RightIndex`**: the index of the right object (`$Null` in the outer part of a left- or full join)

*Note 1:* The `-Using` parameter has the most complex comparison possibilities but is considerable slower than the -On parameter.

*Note 2:* The `-Using` parameter cannot be used with the `-On` parameter.

**`-Where <ScriptBlock>`**  
An expression that defines the condition to be met for the objects to be returned. See the Using parameter for available expression variables.
        
**`-Discern <String[]>`**  
By default unrelated properties with the same name will be collected in a single object property.
The `-Discern` parameter (alias `-NameItems`)  defines how to rename the object properties and divide them over multiple properties. If a given name pattern contains an asterisks (`*`), the asterisks will be replaced with the original property name. Otherwise, the property name for each property item will be prefixed with the given name pattern.

The property collection of multiple (chained) join commands can be divided in once from the last join command in the change. The rename patterns are right aligned, meaning that the last renamed pattern will be applied to the last object joined. If there are less rename patterns than property items, the rest of the (left most) property items will be put in a fixed array under the original property name.

*Note 1:* Only properties with the same name on both sides will not be renamed.

*Note 2:* Related properties (with an equal value defined by the -On parameter) will be merged to a signle
item.

**`-Property <(HashTable or String)[]>`**  
A hash table or list of property names (strings) and/or hash tables that define a new selection of
property names and values

Hash tables should be in the format `@{<PropertyName> = <Expression>}` where the <Expression> is a `ScriptBlock` or a *smart property* (string) and defines how the specific left and right properties should be merged.

The following smart properties are available:
* A **general property**: `'<Property Name>'`, where `<Property Name>` represents the property name of the left and/or right property, e.g. `@{ MyProperty = 'Name' }`. If the property exists on both sides, an array holding both values will be returned. In the outer join, the value of the property will be `$Null`.  This smart property is similar to the expression: `@{ MyProperty = { @($Left['Name'], $Right['Name']) } }`
* A **general wildcard property**: `'*'`, where `*` represents the property name of the current property, e.g. ` 'MyProperty' in @{ MyProperty = '*' }`. If the property exists on both sides:
  - and the properties are unrelated, an array holding both values will be returned
  - and the properties are related to each other, the (equal) values will be merged in one property value
  - and the property at the other side is related to an different property, the property is omitted
  
  The argument: `-Property *`, will apply a general wildcard on all left and right properties.
* A **left property**: `'Left.<Property Name>'`, or **right property**: `'Right.<Property Name>'`, where `<Property Name>` represents the property name of the either the left or right property. If the property doesn't exist, the value of the property will be `$Null`.
* A **left wildcard property**: `'Left.*'`, or **right wildcard property**: `'Right.*'`, where `*` represents the property name of the current the left or right property, e.g. `'MyProperty' in @{ MyProperty = 'Left.*' }`. If the property doesn't exist (in an outer join), the property with the same name at the other side will be taken. If the property doesn't exist on either side, the value of the property will be `$Null`.
  
  The argument: `-Property 'Left.*'`, will apply a left wildcard property on all the left object properties.

If the `-Property` parameter and the `-Discern` parameter are omitted, a general wildcard property is applied on all the left and right properties.

The last defined expression or smart property will overrule any previous defined properties.

**`-ValueName <String>`**  
Defines the default name for the property name in case a scalar array is joined with an object array.

**`-JoinType <'Inner'|'Left'|'Right'|'Full'|'Cross'>`**  
Defines which unrelated objects should be included (see: Description). The default is `'Inner'`.

Note: It is recommended to use the related proxy commands (`... | <JoinType>-Object ...`) instead.

<sub>Please give a 👍 if you support the proposal to [Add a Join-Object cmdlet to the standard PowerShell equipment (`#14994`)](https://github.com/PowerShell/PowerShell/issues/14994)</sub>
