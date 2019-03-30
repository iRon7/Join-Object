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


PS C:\> $Employee | InnerJoin $Department -On Country

Country Id Name                   Department  Age ReportsTo
------- -- ----                   ----------  --- ---------
Germany  2 {Bauer, Engineering}   Engineering  31         4
England  3 {Cook, Marketing}      Sales        69         1
France   4 {Duval, Sales}         Engineering  21         5
France   4 {Duval, Purchase}      Engineering  21         5
England  5 {Evans, Marketing}     Marketing    35
Germany  6 {Fischer, Engineering} Engineering  29         4
```

Unifing columns
```powershell
.EXAMPLE

PS C:\> $Employee | InnerJoin $Department -On Department -Equals -Unify Employee, Department

Id EmployeeName DepartmentName EmployeeCountry DepartmentCountry Department  Age ReportsTo
-- ------------ -------------- --------------- ----------------- ----------  --- ---------
 1 Aerts        Sales          Belgium         France            Sales        40         5
 2 Bauer        Engineering    Germany         Germany           Engineering  31         4
 3 Cook         Sales          England         France            Sales        69         1
 4 Duval        Engineering    France          Germany           Engineering  21         5
 5 Evans        Marketing      England         England           Marketing    35
 6 Fischer      Engineering    Germany         Germany           Engineering  29         4
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
PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id

Id         Name             Country            Department                 Age         ReportsTo
--         ----             -------            ----------                 ---         ---------
{1, 5}     {Aerts, Evans}   {Belgium, England} {Sales, Marketing}         {40, 35}    {5, }
{2, 4}     {Bauer, Duval}   {Germany, France}  {Engineering, Engineering} {31, 21}    {4, 5}
{3, 1}     {Cook, Aerts}    {England, Belgium} {Sales, Sales}             {69, 40}    {1, 5}
{4, 5}     {Duval, Evans}   {France, England}  {Engineering, Marketing}   {21, 35}    {5, }
{5, $null} {Evans, $null}   {England, $null}   {Marketing, $null}         {35, $null} {, $null}
{6, 4}     {Fischer, Duval} {Germany, France}  {Engineering, Engineering} {29, 21}    {4, 5}
```

## Parameters

`-LeftObject`  
The LeftObject, usually provided through the pipeline, defines the
left object (or list of objects) to be joined.

`-RightObject`  
The RightObject, provided by the (first) argument, defines the right
object (or list of objects) to be joined.

`-On`  
The `-On` (alias `-Using`) parameter defines the condition that specify how
to join the left and right object and which objects to include in the
(inner) result set. The `-On` parameter supports the following formats:

`-On <String> or <Array>`  
If the value is a string or array type, the `-On` parameter is similar to
the SQL using clause. This means that the left and right object will be
merged and added to the result set if all the left object properties
listed by the `-On` parameter are equal to the right object properties
(listed by the `-Equals` parameter).

_Note 1:_ The list of properties defined by the `-On` parameter will be
justified with the list of properties defined by the `-Equals` parameter
and visa versa.

_Note 2:_ The equal properties will be merged to a single (left) property
by default (see also the `-Property` parameter).

`-On <ScriptBlock>`  
Any conditional expression (where `$Left` refers to each left object and
`$Right` refers to each right object) which requires to evaluate to true
in order to join the objects.

_Note 1:_ The `-On <ScriptBlock>` type has the most complex comparison
possibilities but is considerable slower than the other types.

_Note 2:_ If the `-On` and the `-Equal` parameter are omitted, a join by
row index is returned.

`-Equals`  
The left and right object will be merged and added to the result set
if all the right object properties listed by the `-Equal` parameter are
equal to the left object properties (listed by the -On parameter).

_Note 1:_ The list of properties defined by the `-Equal` parameter will be
justified with the list of properties defined by the -On parameter and
visa versa.

_Note 2:_ If the -Equal and the `-O`n parameter are omitted, a join by
row index is returned.

_Note 3:_ The `-Equals` parameter cannot be used in combination with an
-On parameter expression.

`-Where`  
An expression that defines the condition to be met for the objects to
be returned. There is no limit to the number of predicates that can be
included in the condition.

`-Unify`  
The `-Unify` (alias `-Merge`) parameter defines how to unify the left and
right object with respect to the unrelated common properties. The
common properties can discerned (`<String>[,<String>]`) or merged
(`<ScriptBlock>`). By default the unrelated common properties wil be
merged using the expression: `{$LeftOrVoid.$_, $RightOrVoid.$_}`

`-Unify <String>[,<String>]`  
If the value is not a ScriptBlock, it is presumed a string array with
one or two items defining the left and right key format. If the item
includes an asterisks (`*`), the asterisks will be replaced with the
property name otherwise the item will be used to prefix the property name.

_Note_: A consecutive number will be automatically added to a common
property name if is already used.

`-Unify <ScriptBlock>`  
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

_Note_: Property expressions set by the `-Unify` paramter might be
overwritten by specific `-Property` expressions.

`-Property`  
A hash table or list of property names (strings) and/or hash tables.
Hash tables should be in the format `@{<PropertyName> = <Expression>}`
where the `<Expression>` usually defines how the specific left and
right properties should be merged.

If only a name (string) is supplied, either the left or the right
value is used for unique properties or the default unify expression
is used for unrelated common properties.

_Note_: Any unknown properties will be added to the output object.

