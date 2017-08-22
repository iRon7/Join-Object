The Join-Object (alias Join) function combines columns from two object arrays into a new object array which can be saved as a table (Export-CSV) or used as it is.

Syntax
======

`<Object[]> |  InnerJoin|LeftJoin|RightJoin|FullJoin <Object[]> [-On <String>|<Array>|<ScriptBlock>] [-Merge <HashTable>|<ScriptBlock>] [-Eq <String>]`

`InnerJoin|LeftJoin|RightJoin|FullJoin <Object[]>,<Object[]>  [-On <String>|<Array>|<ScriptBlock>] [-Merge <HashTable>|<ScriptBlock>] [-Eq <String>]`

`InnerJoin|LeftJoin|RightJoin|FullJoin -LeftTable <Object[]> -RightTable <Object[]>  [-On <String>|<Array>|<ScriptBlock>] [-Merge <HashTable>|<ScriptBlock>] [-Eq <String>]`

Commands
========

The `Join-Object` (alias `Join`) function is one function with several aliases that joins two tables (each consisting out of an array of [PSCustomObjects](https://msdn.microsoft.com/en-us/library/system.management.automation.pscustomobject(v=vs.85).aspx))  similar to the respective [SQL Join](http://www.sql-join.com/) instructions. The default [join type](http://www.sql-join.com/sql-join-types) is an `InnerJoin`.

 - `InnerJoin-Object` (Alias `InnerJoin`)  
Returns records that have matching values in both tables.

 - `LeftJoin-Object` (alias `LeftJoin`)  
Returns all records from the left table and the matched records from the right table.

 - `RightJoin-Object` (alias `RightJoin`)  
Returns all records from the right table and the matched records from the right table.

 - `FullJoin-Object` (alias `FullJoin`)  
Returns all records when there is a match in either left or right table.

*Notes*

 1. All `Join` commands are compatible with PowerShell version 2 and higher.

Parameters
==========

`-LeftTable <Object[]>` and `-RightTable <Object[]>`
----------------------------------------------------
The  `-LeftTable` and `RightTable` parameter define the left - and right table to be joined. There are three possible syntaxis to supply the tables:

 - Using the PowerShell pipeline:
 <code><i>&lt;LeftTable&gt;</i> |  Join  <i>&lt;RightTable&gt;</i></code>

 - Supplying both tables in an array (separated by a comma) at the first argument position:
 <code>Join  <i>&lt;LeftTable&gt;</i>,<i>&lt;RightTable&gt;</i></code>

 - Supplying both tables with named arguments:
 <code>Join  -Left <i>&lt;LeftTable&gt;</i> -Right <i>&lt;RightTable&gt;</i></code>

*Notes*

 1. If only one table is supplied (<code>Join  <i>&lt;Table&gt;</i></code>), a self [self-join](https://en.wikipedia.org/wiki/Join_(SQL)#Self-join) will be performed on the table.

`-On <String>|<Array>|<ScriptBlock>` and `-Equals <String>`
------------------------------------------------
The  `-On` (alias `Using`) parameter defines the condition that specify how to join tables and which rows to include in the (inner) result set. The  `-On` parameter supports the following formats:

 - `String -Equals <String>`
If the `-On` value is a `String` and the `-Equals <String>` parameters is supplied, the property in the left column defined by the `-On` value requires to be equal to the property in the right column defined by the `-equals` value to be included in the (inner) result set.

 - `String` or `Array`
If the value is a `String` or `Array` the `-On` parameter is similar to the SQL `using` clause. This means that all the listed properties require to be equal (at the left and right side) to be included in the (inner) result set. The listed properties will output a single value by default (see also `-Expressions`).

 - `ScriptBlock`
Any conditional expression where `$Left` defines the left row, `$Right` defines the right row.  

*Notes*

 1. The  `ScriptBlock` type has the most comparison possibilities but is considerable slower than the other types.

 2.  If the `-On` parameter is omitted or from an unknown type, a [cross-join](https://en.wikipedia.org/wiki/Join_(SQL)#Cross_join) will be performed.

`-Merge <HashTable>|<ScriptBlock>`
----------------------------------

Defines how the specific columns with the same name should be merged.  The `-Merge` parameter accepts to types:  a `HashTable`  containing the specific merge expression for each column or `ScriptBlock` containing the default merge expression for all columns that have no merge expression defined.  
Where in the expression:

 - `$_` holds each column name.
 - `$Left` holds the left row and `$Right` holds the right row.
 - `$Left.$_` holds each left value  and `$Right.$_` holds each right value.
 - `$LeftIndex` holds the current left row index and `$RightIndex` holds the current right row index.

*Notes:*
 
 1. Expressions are only executed if both left value (` Left.$_`) and right value (` Left.$_`) are existing (including values that are `$Null`) otherwise just the exiting value is returned.

 2. If no expression is defined for a column the expression `{$Left.$_, $Right.$_}` is used.
This means that both values are assigned (in an array) to the current property.

 3.  The expression for columns defined by the `-On <String>`, `-Equals <String>`and -On `<Array>` is: `{$Left.$_}`  and can only be overruled by a column specific expression defined in a hash table.
This means that a single value (either `$Left` or `$Right` which is not equal to `$Null`) is assigned to the current property.

 4.  To use column specific expressions *and* define a default expression use a zero length key name for the default expression, e.g. `-Merge @{"" = {$Left.$_}; "Column Name" = {$Right.$_}}`

Examples
========

Given the following tables:

<pre><code><b>   $Employee                               $Department</b>
+---------+---------+-------------+    +-------------+---------+---------+
|  Name   | Country | Department  |    |    Name     | Country | Manager |
+---------+---------+-------------+    +-------------+---------+---------+
| Aerts   | Belgium | Sales       |    | Engineering | Germany | Meyer   |
| Bauer   | Germany | Engineering |    | Marketing   | England | Morris  |
| Cook    | England | Sales       |    | Sales       | France  | Millet  |
| Duval   | France  | Engineering |    +-------------+---------+---------+
| Evans   | England | Marketing   |
| Fischer | Germany | Engineering |
+---------+---------+-------------+
</code></pre>

    PS C:\> # InnerJoin on Department = Name
    PS C:\> $Employee | InnerJoin $Department Department -eq Name | Format-Table
    
    Department  Name    Manager Country
    ----------  ----    ------- -------
    Sales       Aerts   Millet  {Belgium, France}
    Engineering Bauer   Meyer   {Germany, Germany}
    Sales       Cook    Millet  {England, France}
    Engineering Duval   Meyer   {France, Germany}
    Marketing   Evans   Morris  {England, England}
    Engineering Fischer Meyer   {Germany, Germany}
    
    
    PS C:\> # LeftJoin using country (selecting Department.Name and Department.Country)
    PS C:\> $Employee | LeftJoin ($Department | Select Manager,Country) Country | Format-Table
    
    Department  Name    Manager Country
    ----------  ----    ------- -------
    Engineering Bauer   Meyer   Germany
    Sales       Cook    Morris  England
    Engineering Duval   Millet  France
    Marketing   Evans   Morris  England
    Engineering Fischer Meyer   Germany
    Sales       Aerts           Belgium
    
    
    PS C:\> # InnerJoin on Employee.Department = Department.Name and Employee.Country = Department.Country (returning only the left name and - country)
    PS C:\> $Employee | InnerJoin $Department {$Left.Department -eq $Right.Name -and $Left.Country -eq $Right.Country} {$Left.$_}
    
    Department  Name    Manager Country
    ----------  ----    ------- -------
    Engineering Bauer   Meyer   Germany
    Marketing   Evans   Morris  England
    Engineering Fischer Meyer   Germany
    
    
    PS C:\> # Cross Join
    PS C:\> $Employee | InnerJoin $Department | Format-Table
    
    Department  Name                   Manager Country
    ----------  ----                   ------- -------
    Sales       {Aerts, Engineering}   Meyer   {Belgium, Germany}
    Sales       {Aerts, Marketing}     Morris  {Belgium, England}
    Sales       {Aerts, Sales}         Millet  {Belgium, France}
    Engineering {Bauer, Engineering}   Meyer   {Germany, Germany}
    Engineering {Bauer, Marketing}     Morris  {Germany, England}
    Engineering {Bauer, Sales}         Millet  {Germany, France}
    Sales       {Cook, Engineering}    Meyer   {England, Germany}
    Sales       {Cook, Marketing}      Morris  {England, England}
    Sales       {Cook, Sales}          Millet  {England, France}
    Engineering {Duval, Engineering}   Meyer   {France, Germany}
    Engineering {Duval, Marketing}     Morris  {France, England}
    Engineering {Duval, Sales}         Millet  {France, France}
    Marketing   {Evans, Engineering}   Meyer   {England, Germany}
    Marketing   {Evans, Marketing}     Morris  {England, England}
    Marketing   {Evans, Sales}         Millet  {England, France}
    Engineering {Fischer, Engineering} Meyer   {Germany, Germany}
    Engineering {Fischer, Marketing}   Morris  {Germany, England}
    Engineering {Fischer, Sales}       Millet  {Germany, France}

    PS C:\> # Update service list (replace existing services on name and add new ones)
    PS C:\> Import-CSV .\Service.csv | LeftJoin (Get-Service) Name {$Right.$_} | Export-CSV .\Service.csv

    PS C:\> # Update process list and only insert processes with a higher CPU
    PS C:\> Import-CSV .\CPU.csv | LeftJoin (Get-Process) ID {If ($Left.CPU -gt $Right.CPU) {$Left.$_} Else {$Right.$_}} | Export-CSV .\CPU.csv
