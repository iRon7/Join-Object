# Join-Object
Combines two objects lists based on a related property between them.

Combines properties from one or more objects. It creates a set that can
be saved as a new object or used as it is. An object join is a means for
combining properties from one (self-join) or more tables by using values
common to each. The Join-Object cmdlet supports a few proxy commands with
their own defaults:
- `InnerJoin-Object` (`Join-Object -JoinType Inner`)  
Only returns the joined objects
- `LeftJoin-Object` (`Join-Object -JoinType Left`)  
Returns the joined objects and the rest of the left objects
- `RightJoin-Object` (`Join-Object -JoinType Right`)  
Returns the joined objects and the rest of the right objects
- `FullJoin-Object` (`Join-Object -JoinType Full`)  
Returns the joined objects and the rest of the left and right objects
- `CrossJoin-Object` (`Join-Object -JoinType Cross`)  
Joins each left object to each right object
- `Update-Object` (`Join-Object -JoinType Left -MergeExpression = {RightOrLeft.$_}`)  
Updates the left object with the right object properties
- `Merge-Object` (`Join-Object -JoinType Full -MergeExpression = {RightOrLeft.$_}`)  
Updates the left object with the right object properties and inserts
right if the values of the related property is not equal.

Each command has an alias equal to its verb (omitting `-Object`).

 ## Examples 
A simple inner join on the country property considering the following
existing list of objects:
```powershell
PS C:\> $Employee

Name    Country Department
----    ------- ----------
Aerts   Belgium Sales
Bauer   Germany Engineering
Cook    England Sales
Duval   France  Engineering
Evans   England Marketing
Fischer Germany Engineering

PS C:\> $Department

Name        Manager Country
----        ------- -------
Engineering Meyer   Germany
Marketing   Morris  England
Sales       Millet  France
Board       Mans    Netherlands

PS C:\> $Employee | LeftJoin $Department -On Country
Department  Name                   Country Manager
----------  ----                   ------- -------
Sales       {Aerts, $null}         Belgium
Engineering {Bauer, Engineering}   Germany Meyer
Sales       {Cook, Marketing}      England Morris
Engineering {Duval, Sales}         France  Millet
Marketing   {Evans, Marketing}     England Morris
Engineering {Fischer, Engineering} Germany Meyer
```

Updating an existing object list:
```powershell
PS C:\> $Changes

Name    Country Department
----    ------- ----------
Aerts   Germany Sales
Bauer   Germany Marketing
Geralds Belgium Engineering

PS C:\> $Employee | Merge $Changes -On Name

Department  Name    Country
----------  ----    -------
Sales       Aerts   Germany
Marketing   Bauer   Germany
Sales       Cook    England
Engineering Duval   France
Marketing   Evans   England
Engineering Fischer Germany
Engineering Geralds Belgium
```

Defining the employee's manager based on department:
```powershell
PS C:\> $Employee | Join $Department -On Department -Eq Name -Property @{Name = {$Left.$_}}, "Manager"

Name    Manager
----    -------
Aerts   Millet
Bauer   Meyer
Cook    Millet
Duval   Meyer
Evans   Morris
Fischer Meyer
```

Defining the employee's manager using a self-join based on Employee id:
```powershell
PS C:\> $Employees

EmployeeId FirstName LastName  ReportsTo
---------- --------- --------  ---------
         1 Nancy     Davolio           2
         2 Andrew    Fuller
         3 Janet     Leveling          2
         4 Margaret  Peacock           2
         5 Steven    Buchanan          2
         6 Michael   Suyama            5
         7 Robert    King              5
         8 Laura     Callahan          2
         9 Anne      Dodsworth         5

PS C:\> $Employees | InnerJoin $Employees -On ReportsTo -Eq EmployeeID -Property @{
            Name = {"$($Left.FirstName) $($Left.LastName)"}
            Manager = {"$($Right.FirstName) $($Right.LastName)"}
        }

Name             Manager
----             -------
Nancy Davolio    Andrew Fuller
Janet Leveling   Andrew Fuller
Margaret Peacock Andrew Fuller
Steven Buchanan  Andrew Fuller
Michael Suyama   Steven Buchanan
Robert King      Steven Buchanan
Laura Callahan   Andrew Fuller
Anne Dodsworth   Steven Buchanan
```

## Parameters

`-LeftObject`  
The LeftObject, usually provided through the pipeline, defines the
left object (or list of objects) to be joined.

`-RightObject`  
The RightObject, provided by the (first) argument, defines the right
object (or list of objects) to be joined.

`-On`  
The `-On` (alias `-Using`) parameter defines the condition that specify
how to join the left and right object and which objects to include in the
(inner) result set. The -On parameter supports the following formats:

`-On <String> or <Array>`  
If the value is a string or array type, the `-O` parameter is similar to
the SQL using clause. This means that all the listed properties require
to be equal (at the left and right side) to be included in the (inner)
result set. The listed properties will output a single value by default
(see also the `-Property` parameter).

`-On <ScriptBlock>`  
Any conditional expression (where `$Left` refers to each left object and
`$Right` refers to each right object) which requires to evaluate to true
in order to join the objects.

_Note 1_: The -On <ScriptBlock> type has the most complex comparison
possibilities but is considerable slower than the other types.

_Note 2_: If the -On parameter is omitted, a join by index is returned.

Requires the `-On` value to be a string. The property of the left object
defined by the `-On` value requires to be equal to the property of the
right object defined by the `-Equals` value for the objects to be joined
and added to the result sets.

`-Pair`  
The `-Pair` (alias `-Merge`) parameter defines how unrelated properties
with the same name are paired.
	he `-Pair` parameter supports the following formats:

`Pair <String>,<String>`  
If the value is not a ScriptBlock, it is presumed a string array with
one or two items defining the left and right key format. If the item
includes an asterisks (`*`), the asterisks will be replaced with the
property name otherwise the item will be used to prefix the property name.

_Note_: A consecutive number will be automatically added to the property
name if the property name already exists.

`Pair <ScriptBlock>`  
An expression that defines how the left and right properties with the
common property should be merged. Where the following variables are
available:

- `$_`: iterates each property name
- `$Void`: an object with all (left and right) properties set to $Null
- `$Left`: the current left object (each self-contained -`LeftObject`)
- `$LeftOrVoid`: the left object otherwise an object with null values
- `$LeftOrRight`: the left object otherwise the right object
- `$LeftKeys`: an array containing all the left keys
- `$Right`: the current right object (each self-contained `-RightObject`)
- `$RightOrVoid`: the right object otherwise an object with null values
- `$RightOrLeft`: the right object otherwise the left object
- `$RightKeys`: an array containing all the right keys
The default `-Pair` is: `{$LeftOrVoid.$_, $RightOrVoid.$_}`

`-Property`  
A hash table or list of property names (strings) and/or hash tables.

Hash tables should be in the format `@{<PropertyName> = <Expression>}`
where the `<Expression>` usually defines how the specific left and
right properties should be merged.

If only a name (string) is supplied, the default merge expression
is used

Existing properties set by the (default) merge expression will be
overwritten by the -Property parameter.

Any unknown properties will be added to the output object.
