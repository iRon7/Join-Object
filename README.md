# Join-Object
Combines two objects lists based on a related property between them.

The Join cmdlet combines properties from one or more objects. It creates
a set that can	be saved as a new object or used as it is. A object join is
a means for 	combining properties from one (self-join) or more tables by
using values	common to each. 
There are four basic types of the Join-Object cmdlet:
- InnerJoin-Object (InnerJoin, or Join)
- LeftJoin-Object (or LeftJoin)
- RightJoin-Object (or RightJoin)
- FullJoin-Object (or FullJoin)  
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

A self join example creating new name and manager properties:

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
