Function Join-Object {
	[CmdletBinding()]Param (
		[PSObject[]]$RightTable, [Alias("Using")]$On, $Merge = @{}, [Parameter(ValueFromPipeLine = $True)][Object[]]$LeftTable, [String]$Equals
	)
	$Type = ($MyInvocation.InvocationName -Split "-")[0]
	$PipeLine = $Input | ForEach {$_}; If ($PipeLine) {$LeftTable = $PipeLine}
	If ($LeftTable -eq $Null) {If ($RightTable[0] -is [Array]) {$LeftTable = $RightTable[0]; $RightTable = $RightTable[-1]} Else {$LeftTable = $RightTable}}
	$DefaultMerge = If ($Merge -is [ScriptBlock]) {$Merge; $Merge = @{}} ElseIf ($Merge."") {$Merge.""} Else {{$Left.$_, $Right.$_}}
	If ($Equals) {$Merge.$Equals = {If ($Left.$Equals -ne $Null) {$Left.$Equals} Else {$Right.$Equals}}}
	ElseIf ($On -is [String] -or $On -is [Array]) {@($On) | ForEach {If (!$Merge.$_) {$Merge.$_ = {$Left.$_}}}}
	$LeftKeys  = @($LeftTable[0].PSObject.Properties  | ForEach {$_.Name})
	$RightKeys = @($RightTable[0].PSObject.Properties | ForEach {$_.Name})
	$Keys = $LeftKeys + $RightKeys | Select -Unique
	$Keys | Where {!$Merge.$_} | ForEach {$Merge.$_ = $DefaultMerge}
	$Properties = @{}; $Keys | ForEach {$Properties.$_ = $Null}; $Out = New-Object PSObject -Property $Properties
	$LeftOut  = @($True) * @($LeftTable).Length; $RightOut = @($True) * @($RightTable).Length
	$NullObject = New-Object PSObject
	For ($LeftIndex = 0; $LeftIndex -lt $LeftOut.Length; $LeftIndex++) {$Left = $LeftTable[$LeftIndex]
		For ($RightIndex = 0; $RightIndex -lt $RightOut.Length; $RightIndex++) {$Right = $RightTable[$RightIndex]
			$Select = If ($On -is [String]) {If ($Equals) {$Left.$On -eq $Right.$Equals} Else {$Left.$On -eq $Right.$On}}
			ElseIf ($On -is [Array]) {($On | Where {!($Left.$_ -eq $Right.$_)}) -eq $Null} ElseIf ($On -is [ScriptBlock]) {&$On} Else {$True}
			If ($Select) {$Keys | ForEach {$Out.$_ = 
					If ($LeftKeys -NotContains $_) {$Right.$_} ElseIf ($RightKeys -NotContains $_) {$Left.$_} Else {&$Merge.$_}
				}; $Out; $LeftOut[$LeftIndex], $RightOut[$RightIndex] = $Null
	}	}	}
	If ("LeftJoin",  "FullJoin" -Contains $Type) {
		For ($LeftIndex = 0; $LeftIndex -lt $LeftOut.Length; $LeftIndex++) {
			If ($LeftOut[$LeftIndex]) {$Keys | ForEach {$Out.$_ = $LeftTable[$LeftIndex].$_}; $Out}
	}	}
	If ("RightJoin", "FullJoin" -Contains $Type) {
		For ($RightIndex = 0; $RightIndex -lt $RightOut.Length; $RightIndex++) {
			If ($RightOut[$RightIndex]) {$Keys | ForEach {$Out.$_ = $RightTable[$RightIndex].$_}; $Out}
	}	}
}; Set-Alias Join   Join-Object
Set-Alias InnerJoin Join-Object; Set-Alias InnerJoin-Object Join-Object -Description "Returns records that have matching values in both tables"
Set-Alias LeftJoin  Join-Object; Set-Alias LeftJoin-Object  Join-Object -Description "Returns all records from the left table and the matched records from the right table"
Set-Alias RightJoin Join-Object; Set-Alias RightJoin-Object Join-Object -Description "Returns all records from the right table and the matched records from the left table"
Set-Alias FullJoin  Join-Object; Set-Alias FullJoin-Object  Join-Object -Description "Returns all records when there is a match in either left or right table"
