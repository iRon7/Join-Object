Function Join-Object {
	[CmdletBinding()]Param (
		[PSObject[]]$RightTable, [Alias("Using")]$On, $Merge = @{}, [Parameter(ValueFromPipeLine = $True)][Object[]]$LeftTable, [String]$Equals
	)
	$Type = ($MyInvocation.InvocationName -Split "-")[0]
	$PipeLine = $Input | ForEach {$_}; If ($PipeLine) {$LeftTable = $PipeLine}
	If ($LeftTable -eq $Null) {If ($RightTable[0] -is [Array]) {$LeftTable = $RightTable[0]; $RightTable = $RightTable[-1]} Else {$LeftTable = $RightTable}}
	$DefaultMerge = If ($Merge -is [ScriptBlock]) {$Merge; $Merge = @{}} ElseIf ($Merge."") {$Merge.""} Else {{$Left.$_, $Right.$_}}
	If ($Equals) {$Merge.$Equals = {If ($Left.$Equals -ne $Null) {$Left.$Equals} Else {$Right.$Equals}}}
	ElseIf ($On -is [String] -or $On -is [Array]) {@($On) | ForEach {If (!$Merge.$_) {$Merge.$_ = {Merge-Left}}}}
	$LeftKeys  = $LeftTable[0].PSObject.Properties  | ForEach {$_.Name}
	$RightKeys = $RightTable[0].PSObject.Properties | ForEach {$_.Name}
	$Keys = $LeftKeys + $RightKeys | Select -Unique
	$Keys | Where {!$Merge.$_} | ForEach {$Merge.$_ = $DefaultMerge}
	$Properties = @{}; $Keys | ForEach {$Properties.$_ = $Null}; $PSObject = New-Object PSObject -Property $Properties
	$LeftOut  = @($True) * @($LeftTable).Length; $RightOut = @($True) * @($RightTable).Length
	$NullObject = New-Object PSObject
	Function Merge-Left  {If ($Left.$_ -ne $Null)  {$Left.$_}  Else {$Right.$_}}; Set-Alias Left  Merge-Left
	Function Merge-Right {If ($Right.$_ -ne $Null) {$Right.$_} Else {$Left.$_}};  Set-Alias Right Merge-Right
	Function Add-PSObject($Left, $Right) {
		$Keys | ForEach {$PSObject.$_ = If ($LeftKeys -NotContains $_) {$Right.$_} ElseIf ($RightKeys -NotContains $_) {$Left.$_} Else {&$Merge.$_}}
		$PSObject
	}
	For ($LeftIndex = 0; $LeftIndex -lt $LeftOut.Length; $LeftIndex++) {$Left = $LeftTable[$LeftIndex]
		For ($RightIndex = 0; $RightIndex -lt $RightOut.Length; $RightIndex++) {$Right = $RightTable[$RightIndex]
			$Select = If ($On -is [String]) {If ($Equals) {$Left.$On -eq $Right.$Equals} Else {$Left.$On -eq $Right.$On}}
			ElseIf ($On -is [Array]) {($On | Where {!($Left.$_ -eq $Right.$_)}) -eq $Null} ElseIf ($On -is [ScriptBlock]) {&$On} Else {$True}
			If ($Select) {Add-PSObject $Left $Right; $LeftOut[$LeftIndex], $RightOut[$RightIndex] = $Null}
		}
	}
	If ("LeftJoin",  "FullJoin" -Contains $Type) {For ($LeftIndex = 0; $LeftIndex -lt $LeftOut.Length; $LeftIndex++) {
		If ($LeftOut[$LeftIndex]) {Add-PSObject $LeftTable[$LeftIndex] $NullObject}}
	}
	If ("RightJoin", "FullJoin" -Contains $Type) {For ($RightIndex = 0; $RightIndex -lt $RightOut.Length; $RightIndex++) {
		If ($RightOut[$RightIndex]) {Add-PSObject $NullObject $RightTable[$RightIndex]}}
	}
}; Set-Alias Join   Join-Object
Set-Alias InnerJoin Join-Object; Set-Alias InnerJoin-Object Join-Object -Description "Returns records that have matching values in both tables"
Set-Alias LeftJoin  Join-Object; Set-Alias LeftJoin-Object  Join-Object -Description "Returns all records from the left table and the matched records from the right table"
Set-Alias RightJoin Join-Object; Set-Alias RightJoin-Object Join-Object -Description "Returns all records from the right table and the matched records from the left table"
Set-Alias FullJoin  Join-Object; Set-Alias FullJoin-Object  Join-Object -Description "Returns all records when there is a match in either left or right table"
