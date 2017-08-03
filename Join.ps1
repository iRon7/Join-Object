Function Join-Object {
	[CmdletBinding()]Param (
		[PSObject[]]$RightTable, [Alias("Using")]$On, [HashTable]$Expressions = @{}, [ScriptBlock]$DefaultExpression = {$Left.$_, $Right.$_}, 
		[Parameter(ValueFromPipeLine = $True)][Object[]]$LeftTable, [String]$Equals
	)
	$Type = ($MyInvocation.InvocationName -Split "-")[0]
	$PipeLine = $Input | ForEach {$_}; If ($PipeLine) {$LeftTable = $PipeLine}
	If ($LeftTable -eq $Null) {If ($RightTable[0] -is [Array]) {$LeftTable = $RightTable[0]; $RightTable = $RightTable[-1]} Else {$LeftTable = $RightTable}}
	If ($Equals) {$Expressions.$Equals = {If ($Left.$Equals -ne $Null) {$Left.$Equals} Else {$Right.$Equals}}}
	ElseIf ($On -is [String] -or $On -is [Array]) {@($On) | ForEach {If (!$Expressions.$_) {$Expressions.$_ = {If ($Left.$_ -ne $Null) {$Left.$_} Else {$Right.$_}}}}}
	$LeftKeys  = $LeftTable[0].PSObject.Properties  | ForEach {$_.Name}
	$RightKeys = $RightTable[0].PSObject.Properties | ForEach {$_.Name}
	$Keys = $LeftKeys + $RightKeys | Select -Unique
	$Keys | Where {!$Expressions.$_} | ForEach {$Expressions.$_ = $DefaultExpression}
	$Properties = @{}; $Keys | ForEach {$Properties.$_ = $Null}; $PSObject = New-Object PSObject -Property $Properties
	$LeftList  = @($True) * @($LeftTable).Length; $RightList = @($True) * @($RightTable).Length
	$NullObject = New-Object PSObject
	Function Add-PSObject($Left, $Right) {
		$Keys | ForEach {$PSObject.$_ = If ($LeftKeys -NotContains $_) {$Right.$_} ElseIf ($RightKeys -NotContains $_) {$Left.$_} Else {&$Expressions.$_}}
		$PSObject
	}
	For ($L = 0; $L -lt $LeftList.Length; $L++) {$Left = $LeftTable[$L]
		For ($R = 0; $R -lt $RightList.Length; $R++) {$Right = $RightTable[$R]
			$Select = If ($On -is [String]) {If ($Equals) {$Left.$On -eq $Right.$Equals} Else {$Left.$On -eq $Right.$On}}
			ElseIf ($On -is [Array]) {($On | Where {!($Left.$_ -eq $Right.$_)}) -eq $Null} ElseIf ($On -is [ScriptBlock]) {&$On} Else {$True}
			If ($Select) {Add-PSObject $Left $Right; $LeftList[$L], $RightList[$R] = $Null}
		}
	}
	If ("LeftJoin",  "FullJoin" -Contains $Type) {For ($L = 0; $L -lt $LeftList.Length; $L++) {If ($LeftList[$L]) {Add-PSObject $LeftTable[$L] $NullObject}}}
	If ("RightJoin", "FullJoin" -Contains $Type) {For ($R = 0; $R -lt $RightList.Length; $R++) {If ($RightList[$R]) {Add-PSObject $NullObject $RightTable[$R]}}
	}
}; Set-Alias Join   Join-Object
Set-Alias InnerJoin Join-Object; Set-Alias InnerJoin-Object Join-Object -Description "Returns records that have matching values in both tables"
Set-Alias LeftJoin  Join-Object; Set-Alias LeftJoin-Object  Join-Object -Description "Returns all records from the left table and the matched records from the right table"
Set-Alias RightJoin Join-Object; Set-Alias RightJoin-Object Join-Object -Description "Returns all records from the right table and the matched records from the left table"
Set-Alias FullJoin  Join-Object; Set-Alias FullJoin-Object  Join-Object -Description "Returns all records when there is a match in either left or right table"
