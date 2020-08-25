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
* Supports (custom) objects, data tables and dictionaries (e.g. hash tables) for input
* Smart properties and calculated property expressions
* Custom relation expressions
* Easy installation (dot-sourcing)
* Supports PowerShell for Windows (5.1) and PowerShell Core

The Join-Object cmdlet reveals the following proxy commands with their own (`-JoinType` and `-Property`) defaults:
* `InnerJoin-Object` (Alias `InnerJoin` or `Join`), combines the related objects
* `LeftJoin-Object` (Alias `LeftJoin`), combines the related objects and adds the rest of the left objects
* `RightJoin-Object` (Alias `RightJoin`), combines the related objects and adds the rest of the right objects
* `FullJoin-Object` (Alias `FullJoin`), combines the related objects and adds the rest of the left and right objects
* `CrossJoin-Object` (Alias `CrossJoin`), combines each left object with each right object
* `Update-Object` (Alias `Update`), updates the left object with the related right object
* `Merge-Object` (Alias `Merge`), updates the left object with the related right object and adds the rest of the
  new (unrelated) right objects

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
PS C:\> $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

Id Name    EmployeeCountry Department  Age ReportsTo DepartmentCountry
-- ----    --------------- ----------  --- --------- -----------------
 1 Aerts   Belgium         Sales        40         5 France
 2 Bauer   Germany         Engineering  31         4 Germany
 3 Cook    England         Sales        69         1 France
 4 Duval   France          Engineering  21         5 Germany
 5 Evans   England         Marketing    35           England
 6 Fischer Germany         Engineering  29         4 Germany
```

**Example 3**
```PowerShell
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
```

**Example 4**
```PowerShell
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

**Parameters**

**`-LeftObject <object list, data table or list of hash tables>`**  
The left object list, usually provided through the pipeline, to be joined.

**`-RightObject <object list, data table or list of hash tables>`**  
The right object list, provided by the first argument, to be joined.

**`-On <String[]>`**  
The `-On` parameter (alias `-Using`) defines which objects should be joined together.
If the `-Equals` parameter is omitted, the value(s) of the properties listed by the `-On` parameter should be equal at both sides in order to join the left object with the right object.

*Note 1:* The list of properties defined by the `-On` parameter will be complemented with the list of
properties defined by the `-Equals` parameter and vice versa.

*Note 2:* Related properties will be merged to a single property by default (see also the -Property
parameter).

*Note 3:* If the -On and the `-OnExpression` parameter are omitted, a join by row index is returned.

**`-Equals <String[]>`**  
If the `-Equals` parameter is supplied, the value(s) of the left object properties listed by the `-On`
parameter should be equal to the value(s)of the right object listed by the `-Equals` parameter in order to join the left object with the right object.

*Note 1:* The list of properties defined by the `-Equal` parameter will be complemented with the list of properties defined by the `-On` parameter and vice versa.

*Note 2:* A property will be omitted if it exists on both sides and if the property at the other side is
related to another property.

*Note 3:* The `-Equals` parameter can only be used with the `-On` parameter.

**`-Strict`**  
If the `-Strict` switch is set, the comparison between the related properties defined by the `-On` Parameter (and the `-Equals` parameter) is based on a strict equality (both type and value need to be equal).

**`-MatchCase`**  
If the `-MatchCase` (alias `-CaseSensitive`) switch is set, the comparison between the related properties defined by the `-On` Parameter (and the `-Equals` parameter) will case sensitive.

**`-OnExpression <ScriptBlock>`**  
Any conditional expression (where `$Left` refers to each left object and `$Right` refers to each right object) that requires to evaluate to true in order to join the left object with the right object.

*Note 1:* The `-OnExpression` parameter has the most complex comparison possibilities but is considerable slower than the other types.

*Note 2:* The `-OnExpression` parameter cannot be used with the `-On` parameter.

**`-Where <ScriptBlock>`**  
An expression that defines the condition to be met for the objects to be returned. There is no limit to the number of predicates that can be included in the condition.

**`-Discern <String, String>`**  
The `-Discern` parameter defines how to discern the left and right object properties with respect to the common properties that aren't related.

The first string defines how to rename the left property, the second string (if defined) defines how to
rename the right property. If the string contains an asterisks (`*`), the asterisks will be replaced with
the original property name, otherwise, the property name will be prefixed with the given string.

Properties that don't exist on both sides will not be renamed.

Joined (equal) properties (defined by the -On parameter) will be merged.

*Note:* The -Discern parameter cannot be used with the -Property parameter.

**`-Property <(HashTable or String)[]>`**  
A hash table or list of property names (strings) and/or hash tables that define a new selection of
property names and values

Hash tables should be in the format `@{<PropertyName> = <Expression>}` where the <Expression> is a `ScriptBlock` or a *smart property* (string) and defines how the specific left and right properties should be merged.

The following variables are exposed for a (`ScriptBlock`) expression:
* **`$_`**: iterates each property name
* **`$Left`**: a hash table representing the current left object (each self-contained `-LeftObject`).
  The hash table will be empty (`@{}`) in the outer part of a left join or full join.
* **`$LeftIndex`**: the index of the left object (`$Null` in the outer part of a right- or full join)
* **`$Right`**: a hash table representing the current right object (each self-contained `-RightObject`)
  The hash table will be empty (`@{}`) in the outer part of a right join or full join.
* **`$RightIndex`**: the index of the right object (`$Null` in the outer part of a left- or full join)

The following smart properties are available:
* A **general property**: `'<Property Name>'`, where `<Property Name>` represents the property name of the left and/or right property, e.g. `@{ MyProperty = 'Name' }`. If the property exists on both sides, an array holding both values will be returned. In the outer join, the value of the property will be `$Null`.  This smart property is similar to the expression: `@{ MyProperty = { @($Left['Name'], $Right['Name']) } }`
* A **general wildcard property**: `'*'`, where `*` represents the property name of the current property, e.g. ` 'MyProperty' in @{ MyProperty = '*' }`. If the property exists on both sides:
  - and the properties are unrelated, an array holding both values will be returned
  - and the properties are related to each other, the (equal) values will be merged in one property value
  - and the property at the other side is related to an different property, the property is omitted
  
  The argument: `-Property *`, will apply a general wildcard on all left and right properties.
* A **left property**: `Left.<Property Name>'`, or **right property**: `Right.'<Property Name>'`, where `<Property Name>` represents the property name of the either the left or right property. If the property doesn't exist, the value of the property will be `$Null`.
* A **left wildcard property**: `Left.'*'`, or **right wildcard property**: `Right.'*'`, where `*` represents the property name of the current the left or right property, e.g. `'MyProperty' in @{ MyProperty = 'Left.*' }`. If the property doesn't exist (in an outer join), the property with the same name at the other side will be taken. If the property doesn't exist on either side, the value of the property will be `$Null`.
  
  The argument: `-Property 'Left.*'`, will apply a left wildcard property on all the left object properties.

If the `-Property` parameter and the `-Discern` parameter are omitted, a general wildcard property is applied on all the left and right properties.

The last defined expression or smart property will overrule any previous defined properties.

*Note:* The `-Property` parameter cannot be used with the `-Discern` parameter.

**`-JoinType <'Inner'|'Left'|'Right'|'Full'|'Cross'>`**  
Defines which unrelated objects should be included (see: Description). The default is `'Inner'`.

Note: It is recommended to use the related proxy commands (`... | <JoinType>-Object ...`) instead.
