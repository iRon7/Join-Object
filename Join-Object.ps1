<#PSScriptInfo
.VERSION 2.3.1
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR iRon
.DESCRIPTION Join-Object combines two objects lists based on a related property between them.
.COMPANYNAME
.COPYRIGHT
.TAGS Join-Object Join Combine Table
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
	common to each. There are five types of the Join-Object cmdlet:
	InnerJoin-Object (InnerJoin, or Join), LeftJoin-Object (or LeftJoin),
	RightJoin-Object (or RightJoin), FullJoin-Object (or FullJoin) and
	CrossJoin-Object (or CrossJoin). As a special case, a join by index
	can be invoked by omitting the -On parameter.

	.PARAMETER LeftObject
		The LeftObject (usually provided through the pipeline) defines the
		left object (or list of objects) to be joined.

	.PARAMETER RightObject
		The RightObject (provided as an argument) defines the right object (or
		list of objects) to be joined.

	.PARAMETER On
		The -On (alias Using) parameter defines the condition that specify how
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

	.PARAMETER Merge
		An expression that defines how the left and right properties with the
		same name should be merged. Where in the expression:
		* $_ refers to each property name
		* $Left and $Right refers to each corresponding object
		* $Left.$_ and $Right.$_ refers to corresponding value
		* $LeftProperty.$_ and $RightProperty.$_ refers to a corresponding
		  list of existing properties keys
		If the -Merge parameter and the -Property parameter are omitted, the
		merge expression will be set to:

			{If ($LeftProperty.$_) {$Left.$_};
			If ($RightProperty.$_) {$Right.$_}}

		This means that the left property and/or the right property will only
		be listed in the result if the property exists in the corresponding
		object list.

		If the merge expression is set, the property names of the left object
		and right object will automatically be include in the result.

		Properties set by the -Merge expression might be overwritten by the
		-Property parameter

	.PARAMETER Property
		If the property parameter doesn't contain a hashtable, it is presumed
		to be a list of property names to be output.

		If the property parameter contains a hashtable, it defines how the
		specific left and right properties should be merged. Where each key
		refers to the specific property name and each related value to an
		expression using the variable listed in the -Merge parameter.

		The default property expression for the properties supplied by the -On
		parameter is (in the knowledge that the properties at both sides are
		equal or empty at one side in the outer join):

			If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}

		Existing properties set by the (default) merge expression will be
		overwritten by the -Property parameter.

		New properties will be added to the output object.

	.EXAMPLE

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


		PS C:\> $Employee | LeftJoin $Department -On Country

		Country Department  Name                   Manager
		------- ----------  ----                   -------
		Belgium Sales       {Aerts, $null}
		Germany Engineering {Bauer, Engineering}   Meyer
		England Sales       {Cook, Marketing}      Morris
		France  Engineering {Duval, Sales}         Millet
		England Marketing   {Evans, Marketing}     Morris
		Germany Engineering {Fischer, Engineering} Meyer

	.EXAMPLE

		PS C:\> $Employee | Join $Department -On Department -Eq Name -Property @{Name = {$Left.$_}; Manager = {$Right.$_}}

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

	.EXAMPLE

		PS C:\>Import-CSV .\old.csv | LeftJoin (Get-Service) Name {If ($Null -ne $Right.$_) {$Right.$_} Else {$Left.$_}} | Export-CSV .\New.csv

	.LINK
		https://github.com/iRon7/Join-Object
#>
Function Join-Object {
	[CmdletBinding(DefaultParametersetName='None')][OutputType([Object[]])]Param (
		[Parameter(ValueFromPipeLine = $True)][Object[]]$LeftObject, [Parameter(Position=0)][Object[]]$RightObject,
		[Parameter(Position = 1, ParameterSetName='On')][Alias("Using")]$On, [Parameter(ParameterSetName='On')][String]$Equals,
		[Parameter(Position = 2)][ScriptBlock]$Merge = {If ($LeftProperty.$_) {$Left.$_}; If ($RightProperty.$_) {$Right.$_}},
		[Parameter(Position = 3)]$Property = @{}, [Parameter(Position = 4)] [ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')]$JoinType = 'Inner'
	)
	Begin {
		$Script:Keys = @(); $Hash = @{}; $Script:New = New-Object System.Collections.Specialized.OrderedDictionary
		$RightProperty = @{}; $RightObject[0].PSObject.Properties | ForEach-Object {$RightProperty[$_.Name] = $True}
		$RightLength = @($RightObject).Length; $Script:RightOffs = @($False) * $RightLength; $LeftIndex = 0
		Function Join-Output($Left, $Right) {$Keys | ForEach-Object {$Script:New.$_ = &$Property.$_}; New-Object PSObject -Property $New}
	}
	Process {
		ForEach ($Left in @($LeftObject)) {
			$Script:LeftOff = $False
			If (!$LeftIndex) {
				$LeftProperty = @{}; $LeftObject[0].PSObject.Properties  | ForEach-Object {$LeftProperty[$_.Name] = $True}
				If ($Property.PSTypeNames -Match "^System.Collections") {$Script:Keys = $Property.Keys}
				Else {@($Property) | ForEach-Object {If ($_.Keys) {$Hash += $_; $Script:Keys += $_.Keys} Else {$Script:Keys += "$_"}}; $Property = $Hash}
				If ($Keys.Count -eq 0) {$Script:Keys = $LeftProperty.Keys + $RightProperty.Keys}
				$Script:Keys = $Keys | Select-Object -Unique; $Keys | Where-Object {!$Property.$_} | ForEach-Object {$Property.$_ = $True}
				If ($Equals) {If ($Property.$On -is [Bool]) {$Property.$On = {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}; If ($RightProperty.$_) {$Right.$_}}}}
				ElseIf ($On -is [String] -or $On -is [Array]) {@($On) | ForEach-Object {If ($Property.$_  -is [Bool]) {$Property.$_ = {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}}}}
				$Keys | ForEach-Object {$Script:New.Add($_, $Null); If ($Property.$_ -is [Bool]) {$Property.$_ = $Merge}}
			}
			If ($On -or $JoinType -eq "Cross") {
				For ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {$Right = $RightObject[$RightIndex]
					$Select = If ($On -is [String]) {If ($Equals) {$Left.$On -eq $Right.$Equals} Else {$Left.$On -eq $Right.$On}}
					ElseIf ($On -is [Array]) {$Null -eq ($On | Where-Object {!($Left.$_ -eq $Right.$_)})} ElseIf ($On -is [ScriptBlock]) {&$On} Else {$True}
					If ($Select) {Join-Output $Left $Right; $Script:LeftOff = $True; $Script:RightOffs[$RightIndex] = $True}
				}
			} Elseif ($LeftIndex -lt $RightLength) {
				$RightIndex = $LeftIndex; Join-Output $Left $RightObject[$RightIndex]; $Script:LeftOff = $True; $Script:RightOffs[$RightIndex] = $True
			}
			If (!$LeftOff -And ($JoinType -eq "Left" -or $JoinType -eq "Full")) {Join-Output $Left}
			$LeftIndex++
		}
	}
	End {
		If ($JoinType -eq "Right" -or $JoinType -eq "Full") {$Left = $Null
			For ($RightIndex = 0; $RightIndex -lt $RightOffs.Length; $RightIndex++) {
				If (!$RightOffs[$RightIndex]) {Join-Output $Left $RightObject[$RightIndex]}
			}
		}
	}
}; Set-Alias Join Join-Object
$JoinCommand = Get-Command Join-Object
$JoinData = [System.Management.Automation.CommandMetadata]::New($JoinCommand)
$JoinCommand.Parameters.JoinType.Attributes.ValidValues | ForEach-Object {
	$Name = "$($_)Join-Object"
	$Null = New-Item -Path Function:\ -Name $Name -Value ([System.Management.Automation.ProxyCommand]::Create($JoinData)) -Force
	$PSDefaultParameterValues["$Name`:JoinType"] = $_
	Set-Alias "$($_)Join" $Name
}
