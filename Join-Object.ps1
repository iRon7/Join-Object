<#PSScriptInfo
.VERSION 2.4.2
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR iRon
.DESCRIPTION Join-Object combines two objects lists based on a related property between them.
.COMPANYNAME
.COPYRIGHT
.TAGS Join-Object Join InnerJoin LeftJoin RightJoin FullJoin CrossJoin Update Merge Combine Table
.LICENSEURI https://github.com/iRon7/Join-Object/LICENSE.txt
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
	Combines two objects lists based on a related property between them.

	.DESCRIPTION
	Combines properties from one or more objects. It creates a set that can
	be saved as a new object or used as it is. An object join is a means for
	combining properties from one (self-join) or more tables by using values
	common to each. The Join-Object cmdlet supports a few proxy commands with
	their own defaults:

	* InnerJoin-Object (Join-Object -JoinType Inner)
	  Only returns the joined objects
	* LeftJoin-Object (Join-Object -JoinType Left)
	  Returns the joined objects and the rest of the left objects
	* RightJoin-Object (Join-Object -JoinType Right)
	  Returns the joined objects and the rest of the right objects
	* FullJoin-Object (Join-Object -JoinType Full)
	  Returns the joined objects and the rest of the left and right objects
	* CrossJoin-Object (Join-Object -JoinType Cross)
	  Joins each left object to each right object
	* Update-Object (Join-Object -JoinType Left -MergeExpression = {RightOrLeft.$_}
	  Updates the left object with the right object properties
	* Merge-Object (Join-Object -JoinType Full -MergeExpression = {RightOrLeft.$_}
	  Updates the left object with the right object properties and inserts
	  right if the values of the related property is not equal.

	Each command has an alias equal to its verb (omitting '-Object').

	.PARAMETER LeftObject
		The LeftObject, usually provided through the pipeline, defines the
		left object (or list of objects) to be joined.

	.PARAMETER RightObject
		The RightObject, provided by the (first) argument, defines the right
		object (or list of objects) to be joined.

	.PARAMETER On
		The -On (alias -Using) parameter defines the condition that specify how
		to join the left and right object and which objects to include in the
		(inner) result set. The -On parameter supports the following formats:

		<String> or <Array>
		If the value is a string or array type, the -On parameter is similar to
		the SQL using clause. This means that all the listed properties require
		to be equal (at the left and right side) to be included in the (inner)
		result set. The listed properties will output a single value by default
		(see also the -Property parameter).

		<ScriptBlock>
		Any conditional expression (where $Left refers to each left object and
		$Right refers to each right object) which requires to evaluate to true
		in order to join the objects.

		Note 1: The -On <ScriptBlock> type has the most complex comparison
		possibilities but is considerable slower than the other types.

		Note 2: If the -On parameter is omitted, a join by index is returned.

	.PARAMETER Equals
		Requires the -On value to be a string. The property of the left object
		defined by the -On value requires to be equal to the property of the
		right object defined by the -Equals value for the objects to be joined
		and added to the result sets.

	.PARAMETER MergeExpression
		An expression that defines how the left and right properties with the
		common property should be merged. Where the following variables are
		available:
		* $_: iterates each property name
		* $Keys: an array containing all the (left and right) keys
		* $Left: the current left object (each self-contained -LeftObject)
		* $LeftOrNull: the left object otherwise an object with null values
		* $LeftOrRight: the left object otherwise the right object
		* $LeftKeys: an array containing all the left keys
		* $Right: the current right object (each self-contained -RightObject)
		* $RightOrNull: the right object otherwise an object with null values
		* $RightOrLeft: the right object otherwise the left object
		* $RightKeys: an array containing all the right keys

		The default -MergeExpression is: {$Left.$_, $Right.$_}

		The merge expression is only used in case that the left and right
		properties are overlapping

	.PARAMETER Property
		If the property parameter doesn't contain a hash table, it is presumed
		to be a list of property names to be output.

		If the property parameter contains a hash table, it defines how the
		specific left and right properties should be merged. Where each key
		refers to the specific property name and each related value to an
		expression using the variable listed in the -Merge parameter.

		The default property expression for the properties supplied by the -On
		parameter is: {$LeftOrRight.$_}

		Existing properties set by the (default) merge expression will be
		overwritten by the -Property parameter.

		Any unknown properties will be added to the output object.

	.EXAMPLE

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

	.EXAMPLE

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

	.EXAMPLE

		PS C:\> $Employee | Join $Department -On Department -Eq Name -Property @{Name = {$Left.$_}}, "Manager"

		Name    Manager
		----    -------
		Aerts   Millet
		Bauer   Meyer
		Cook    Millet
		Duval   Meyer
		Evans   Morris
		Fischer Meyer

	.EXAMPLE

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

	.LINK
		https://github.com/iRon7/Join-Object
#>
Function Join-Object {
	[CmdletBinding(DefaultParametersetName='None')][OutputType([Object[]])]Param (
		[Parameter(ValueFromPipeLine = $True)][Object[]]$LeftObject, [Parameter(Position=0)][Object[]]$RightObject,
		[Parameter(Position = 1, ParameterSetName='On')][Alias("Using")]$On, [Parameter(ParameterSetName='On')][String]$Equals,
		[Parameter(Position = 2)][ScriptBlock]$MergeExpression = {$LeftOrNull.$_, $RightOrNull.$_},
		[Parameter(Position = 3)]$Property,
		[Parameter(Position = 4)][ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')]$JoinType = 'Inner'
	)
	Begin {
		$Script:Keys = @(); $Script:All = $False; $Expression = @{}; $Script:New = New-Object System.Collections.Specialized.OrderedDictionary
		$RightKeys = @(); $RightObject[0].PSObject.Properties | ForEach-Object {$RightKeys += $_.Name}
		$RightLength = @($RightObject).Length; $Script:RightOffs = @($False) * $RightLength; $LeftIndex = 0
		Function Join-Output($Left, $Right, $LeftOrRight, $RightOrLeft, $LeftOrNull, $RightOrNull) {
			$Keys | ForEach-Object {$Script:New.$_ = &$Expression.$_}; New-Object PSObject -Property $New
		}
	}
	Process {
		ForEach ($Left in @($LeftObject)) {
			$Script:LeftOff = $False
			If (!$LeftIndex) {
				$LeftKeys = @(); $LeftObject[0].PSObject.Properties | ForEach-Object {$LeftKeys += $_.Name}
				If ($Property.PSTypeNames -Match "^System.Collections") {$Expression = $Property; $Script:Keys = $Property.Keys}
				Else {
					@($Property) | Where-Object {$_} | ForEach-Object {
						If ($_.PSObject.Properties['Keys']) {$Expression += $_; $Script:Keys += $_.Keys}
						Else {If ($_ -eq "*") {$Script:All = $True} Else {$Script:Keys += "$_"}}
					}
					If (!$Property -or $Script:All) {$Script:Keys = $Keys + $LeftKeys + $RightKeys | Select-Object -Unique}
					$Keys | Where-Object {!$Expression.ContainsKey($_)} | ForEach-Object {
						$Using = If ($On -is [Array]) {@($On) -Contains $_} Else {$On -isnot [ScriptBlock] -and !$Equals -and $_ -eq $On}
						$Expression.$_ = If ($Using) {{$LeftOrRight.$_}}
						ElseIf ($LeftKeys -Contains $_) {If ($RightKeys -Contains $_) {$MergeExpression} Else {{$LeftOrNull.$_}}} Else {{$RightOrNull.$_}}
					}
				}
				$Keys | ForEach-Object {$Script:New.$_ = $Null}; $Void = New-Object PSObject -Property $New
			}
			If ($On -or $JoinType -eq "Cross") {
				For ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {$Right = $RightObject[$RightIndex]
					$Select = If ($On -is [Array]) {$Null -eq ($On | Where-Object {!($Left.$_ -eq $Right.$_)})}
						ElseIf ($On -is [ScriptBlock]) {&$On} Else {If ($Equals) {$Left.$On -eq $Right.$Equals} Else {$Left.$On -eq $Right.$On}}
					If ($Select) {
						Join-Output $Left $Right $Left $Right $Left $Right
						$Script:LeftOff = $True; $Script:RightOffs[$RightIndex] = $True
					}
				}
			} Elseif ($LeftIndex -lt $RightLength) {
				$RightIndex = $LeftIndex; $Right = $RightObject[$RightIndex]
				Join-Output $Left $Right $Left $Right $Left $Right
				$Script:LeftOff = $True; $Script:RightOffs[$RightIndex] = $True
			}
			If (!$LeftOff -And ($JoinType -eq "Left" -or $JoinType -eq "Full")) {Join-Output $Left $Null $Left $Left $Left $Void}
			$LeftIndex++
		}
	}
	End {
		If ($JoinType -eq "Right" -or $JoinType -eq "Full") {$Left = $Null
			For ($RightIndex = 0; $RightIndex -lt $RightOffs.Length; $RightIndex++) {
				If (!$RightOffs[$RightIndex]) {$Right = $RightObject[$RightIndex]
					Join-Output $Null $Right $Right $Right $Void $Right
				}
			}
		}
	}
}; Set-Alias Join Join-Object

Function Copy-Command([System.Management.Automation.CommandInfo]$Command, [String]$Name, [HashTable]$DefaultParameters) {
	Try {
		$MetaData = [System.Management.Automation.CommandMetadata]::New($Command)
		$Value = [System.Management.Automation.ProxyCommand]::Create($MetaData)
		$Null = New-Item -Path Function:\ -Name "Script:$Name" -Value $Value -Force
		ForEach ($Key in $DefaultParameters.Keys) {$PSDefaultParameterValues["$Name`:$Key"] = $DefaultParameters.$Key}
	} Catch {$PSCmdlet.WriteError($_)}
}

$JoinCommand = Get-Command Join-Object
Copy-Command $JoinCommand InnerJoin-Object @{JoinType = 'Inner'}; Set-Alias InnerJoin InnerJoin-Object
Copy-Command $JoinCommand LeftJoin-Object  @{JoinType = 'Left'};  Set-Alias LeftJoin  LeftJoin-Object
Copy-Command $JoinCommand RightJoin-Object @{JoinType = 'Right'}; Set-Alias RightJoin RightJoin-Object
Copy-Command $JoinCommand FullJoin-Object  @{JoinType = 'Full'};  Set-Alias FullJoin  FullJoin-Object
Copy-Command $JoinCommand CrossJoin-Object @{JoinType = 'Cross'}; Set-Alias CrossJoin CrossJoin-Object
Copy-Command $JoinCommand Update-Object    @{JoinType = 'Left'; MergeExpression = {{$RightOrLeft.$_}}}; Set-Alias Update Update-Object
Copy-Command $JoinCommand Merge-Object     @{JoinType = 'Full'; MergeExpression = {{$RightOrLeft.$_}}}; Set-Alias Merge  Merge-Object
