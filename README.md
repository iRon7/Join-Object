# Join-Object
Combines two objects lists based on a related property between them.

The Join cmdlet combines properties from one or more objects. It creates
a set that can	be saved as a new object or used as it is. A object join is
a means for 	combining properties from one (self-join) or more tables by
using values	common to each. 
There are four basic types of the Join-Object cmdlet:
- `InnerJoin-Object` (`InnerJoin`, or `Join`)
- `LeftJoin-Object` (or `LeftJoin`)
- `RightJoin-Object` (or `RightJoin`)
- `FullJoin-Object` (or `FullJoin`)

As a special case, a cross join can be invoked by omitting the -On parameter.
 
 ## Examples 

Consider the following tables:

```powershell
PS C:\> $Employee

Department  Name    Country
----------  ----    -------
Sales       Aerts   Belgium
Engineering Bauer   Germany
Sales       Cook    England
Engineering Duval   France
Marketing   Evans   England
Engineering Fischer Germany


PS C:\> $Department

Name        Manager Country
----        ------- -------
Engineering Meyer   Germany
Marketing   Morris  England
Sales       Millet  France
Board       Mans    Netherlands
```
A simple inner join on the country property:

```powershell
PS C:\> $Employee | LeftJoin $Department -On Country

Country Department  Name                   Manager
------- ----------  ----                   -------
Belgium Sales       {Aerts, $null}
Germany Engineering {Bauer, Engineering}   Meyer
England Sales       {Cook, Marketing}      Morris
France  Engineering {Duval, Sales}         Millet
England Marketing   {Evans, Marketing}     Morris
Germany Engineering {Fischer, Engineering} Meyer
```
An (inner) join where the department property of the employee matches the
name property of the department. only retruning the (left) employee name
property and the (right) department manager:

```powershell
PS C:\> $Employee | Join $Department -On Department -Eq Name -Property @{Name = {$Left.$_}; Manager = {$Right.$_}}

Name    Manager
----    -------
Aerts   Millet
Bauer   Meyer
Cook    Millet
Duval   Meyer
Evans   Morris
Fischer Meyer
```

A self join example creating a new name and manager properties:

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
>> Name = {"$($Left.FirstName) $($Left.LastName)"}
>> Manager = {"$($Right.FirstName) $($Right.LastName)"}}

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

Updating (replacing entries with the same name and adding entries with
new names) a saved list of services with a newly retrieve service list:

```powershell
PS C:\>Import-CSV .\old.csv | LeftJoin (Get-Service) Name {If ($Null -ne $Right.$_) {$Right.$_} Else {$Left.$_}} | Export-CSV .\New.csv
```

## Parameters

`-LeftObject`  
The LeftObject (usually provided through the pipeline) defines the
left object (or list of objects) to be joined.

`-RightObject`  
The RightObject (provided as an argument) defines the right object (or
list of objects) to be joined.

`-On`  
The `-On` (alias `-Using`) parameter defines the condition that specify
how to join the left and right object and which objects to include in the
(inner) result set. The -On parameter supports the following formats:

`-On <String>` or `-On <Array>`  
If the value is a string or array type, the `-On` parameter is similar to
the SQL using clause. This means that all the listed properties require
to be equal (at the left and right side) to be included in the (inner)
result set. The listed properties will output a single value by default
(see also the -Property parameter).

`-On <ScriptBlock>`  
Any conditional expression (where `$Left` refers to each left object and
`$Right` refers to each right object) which requires to evaluate to true
in order to join the objects.

Note: The `-On <ScriptBlock>` type has the most complex comparison
possibilities but is considerable slower than the other types.

`-Equals`  
Requires the `-On` value to be a string. The property of the left object
defined by the -On value requires to be equal to the property of the
right object defined by the -Equals value for the objects to be joined
and added to the result sets.

`-Merge`  
An expression that defines how the left and right properties with the
same name should be merged. Where in the expression:
- `$_` refers to each property name
- `$Left` and `$Right` refers to each corresponding object
- `$Left.$`_ and `$Right.$_` refers to corresponding value
- `$LeftIndex` and `$RightIndex` refers to corresponding index
- `$LeftProperty` and `$RightProperty` refers to a corresponding list of properties

If the `-Merge` parameter and the `-Property` parameter are omitted, the
merge expression will be set to:

```powershell
{If ($LeftProperty.$_) {$Left.$_}; If ($RightProperty.$_) {$Right.$_}}
```

This means that the left property and/or the right property will only
be listed in the result if the property exists in the corresponding
object list.

If the merge expression is set, the property names of the left and
right object will automatically be include in the result.

Properties set by the `-Merge` expression will be overwritten by the
`-Property` parameter

`-Property`  
If the property parameter doesn't contain a hashtable, it is presumed
to be a list of property names to be output.

If the property parameter contains a hashtable, it defines how the
specific left and right properties should be merged. Where each key
refers to the specific property name and each related value to an
expression using the variable listed in the -Merge parameter.

The default property expression for the properties supplied by the `-On`
parameter is (in the knowledge that the properties at both sides are
equal or empty at one side in the outer join):

```powershell
If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}
```

Existing properties set by the (default) merge expression will be
overwritten by the `-Property` parameter.

New properties will be added to the output object.
