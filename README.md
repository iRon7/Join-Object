# Join-Object
Combines two object lists based on a related property between them.

Combines properties from one or more objects. It creates a set that can
be saved as a new object or used as it is. An object join is a means for
combining properties from one (self-join) or more tables by using values
common to each. The Join-Object cmdlet supports a few proxy commands with
their own  (`-JoinType` and `-Property`) defaults:
- `InnerJoin-Object` (Alias `InnerJoin` or `Join`)  
Only returns the joined objects
- `LeftJoin-Object` (Alias `LeftJoin`)  
Returns the joined objects and the rest of the left objects
- `RightJoin-Object` (Alias `RightJoin`)  
Returns the joined objects and the rest of the right objects
- `FullJoin-Object` (Alias `FullJoin`)  
Returns the joined objects and the rest of the left and right objects
- `CrossJoin-Object` (Alias `CrossJoin`)  
Joins each left object to each right object
- `Update-Object` (Alias `Update`)  
Updates the left object with the right object properties
- `Merge-Object` (Alias `Merge`)  
Updates the left object with the right object properties and inserts
right if the values of the related property is not equal.

 ## Examples 
A simple inner join on the country property considering the following
existing list of objects:

```powershell
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

Renaming unrelated columns
```powershell
PS C:\> $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
-- ------------ --------------- ----------  --- --------- -------------- -----------------
 1 Aerts        Belgium         Sales        40         5 Sales          France
 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
 3 Cook         England         Sales        69         1 Sales          France
 4 Duval        France          Engineering  21         5 Engineering    Germany
 5 Evans        England         Marketing    35           Marketing      England
 6 Fischer      Germany         Engineering  29         4 Engineering    Germany
```

Merging (update and insert) a new list
```powershell
PS C:\> $Changes

Id Name    Country Department  Age ReportsTo
-- ----    ------- ----------  --- ---------
 3 Cook    England Sales        69         5
 6 Fischer France  Engineering  29         4
 7 Geralds Belgium Sales        71         1


PS C:\> $Employee | Merge $Changes -On Id

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

Self join on Id:
```powershell
PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left.Name}; Manager = {$Right.Name}}

Name    Manager
----    -------
Aerts   Evans
Bauer   Duval
Cook    Aerts
Duval   Evans
Evans
Fischer Duval
```

## Parameters

`-LeftObject`  
The LeftObject, usually provided through the pipeline, defines the
left object (or datatable) to be joined.

`-RightObject`  
The RightObject, provided by the first argument, defines the right
object (or datatable) to be joined.

`-On`  
The `-On` parameter (alias `-Using`) defines which objects should be joined.
If the `-Equals` parameter is omitted, the value(s) of the properties
listed by the `-On` parameter should be equal at both sides in order to
join the left object with the right object.

_Note 1:_ The list of properties defined by the `-On` parameter will be
complemented with the list of properties defined by the `-Equals`
parameter and vice versa.

_Note 2:_ Related joined properties will be merged to a single (left)
property by default (see also the -Property parameter).

_Note 3:_ If the `-On` and the `-OnExpression` parameter are omitted, a
join by row index is returned.

`-Equals`  
If the `-Equals` parameter is supplied, the value(s) of the left object
properties listed by the `-On` parameter should be equal to the value(s)
of the right object listed by the `-Equals` parameter in order to join
the left object with the right object.

_Note 1:_ The list of properties defined by the `-Equal` parameter will be
complemented with the list of properties defined by the `-On` parameter
and vice versa.

_Note 2:_ The `-Equals` parameter can only be used with the `-On` parameter.

`-Strict`  
If the `-Strict` switch is set, the comparison between the related
properties defined by the `-On` Parameter (and the `-Equals` parameter) is
based on a strict equality (both type and value need to be equal).

`-MatchCase`  
If the `-MatchCase` (alias `-CaseSensitive`) switch is set, the comparison
between the related properties defined by the `-On` Parameter (and the
-`Equals` parameter) will case sensitive.

`-OnExpression`
Any conditional expression (where `$Left` refers to each left object and
`$Right` refers to each right object) that requires to evaluate to true
in order to join the left object with the right object.

Note 1: The `-OnExpression` parameter has the most complex comparison
possibilities but is considerable slower than the other types.

Note 2: The `-OnExpression parameter` cannot be used with the `-On`
parameter.

`-Where`  
An expression that defines the condition to be met for the objects to
be returned. There is no limit to the number of predicates that can be
included in the condition.

`-Discern`  
The `-Discern` parameter defines how to discern the left and right object
with respect to the common properties that aren't joined.

The first string defines how to rename the left property, the second
string (if defined) defines how to rename the right property.
If the string contains an asterisks (`*`), the asterisks will be replaced
with the original property name, otherwise, the property name will be
prefixed with the given string.

Properties that don't exist on both sides will not be renamed.

Joined properties (defined by the `-On` parameter) will be merged.

_Note_: The `-Discern` parameter cannot be used with the `-Property` parameter.

`-Property`  
A hash table or list of property names (strings) and/or hash tables that
define a new selection of property names and values

Hash tables should be in the format `@{<PropertyName> = <Expression>}`
where the `<Expression>` defines how the specific left and right
properties should be merged. Where the following variables are
available for each joined object:
- `$_`: iterates each property name
- `$Left`: the current left object (each self-contained `-LeftObject`)
- `$LeftIndex`: the index of the left object
- `$Right`: the current right object (each self-contained `-RightObject`)
- `$RightIndex`: the index of the right object
If the `$LeftObject` isn't joined in a Right- or FullJoin then `$LeftIndex`
will be `$Null` and the `$Left` object will represent an object with each
property set to `$Null`.
If the `$RightObject` isn't joined in a Left- or FullJoin then `$RightIndex`
will be `$Null` and the `$Right` object will represent an object with each
property set to `$Null`.

An asterisks (`*`) represents all known left - and right properties.

If the `-Property` and the `-Discern` parameters are ommited or in case a
property name (or an asterisks) is supplied without expression, the
expression will be automatically added using the following rules:
- If the property only exists on the left side, the expression is:  
  `{$Left.$_}`
- If the property only exists on the right side, the expression is:  
  `{$Right.$_}`
- If the left - and right properties aren't joined, the expression is:  
  `{$Left.$_, $Right.$_}`
- If the left - and right property are joined, the expression is:  
  `{If ($Null -ne $LeftIndex) {$Left.$_} Else {$Right.$_}}}`

If an expression without a property name assignment is supplied, it will
be assigned to all known properties in the `$LeftObject` and `$RightObject`.

The last defined expression will overrule any previous defined expressions

_Note_: The `-Property` parameter cannot be used with the `-Discern` parameter.

`-JoinType`  
Defines which unrelated objects should be included (see: **Descripton**).
Valid values are: `Inner`, `Left`, `Right`, `Full` or `Cross`.
The default is `Inner`.

_Note:_ It is recommended to use the related proxy commands instead.
