<#PSScriptInfo
.VERSION 3.0.1
.GUID 54688e75-298c-4d4b-a2d0-d478e6069126
.AUTHOR iRon
.DESCRIPTION Join-Object combines two objects lists based on a related property between them.
.COMPANYNAME
.COPYRIGHT
.TAGS Join-Object Join InnerJoin LeftJoin RightJoin FullJoin CrossJoin Update Merge Combine Table
.LICENSEURI https://github.com/iRon7/Join-Object/LICENSE
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
	* Update-Object (Join-Object -JoinType Left -MergeExpression = {RightOrLeft.$_})
	  Updates the left object with the right object properties
	* Merge-Object (Join-Object -JoinType Full -MergeExpression = {RightOrLeft.$_})
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
		the SQL using clause. This means that the left and right object will be
		merged and added to the result set if all the left object properties
		listed by the -On parameter are equal to the right object properties
		(listed by the -Equal parameter).

		Note 1: The list of properties defined by the -On parameter will be
		justified with the list of properties defined by the -Eqaul parameter
		and visa versa.

		Note 2: The equal properties will be merged to a single (left) property
		by default (see also the -Property parameter).

		<ScriptBlock>
		Any conditional expression (where $Left refers to each left object and
		$Right refers to each right object) which requires to evaluate to true
		in order to join the objects.

		Note 1: The -On <ScriptBlock> type has the most complex comparison
		possibilities but is considerable slower than the other types.

		Note 2: If the -On and the -Equal parameter are omitted, a join by
		row index is returned.

	.PARAMETER Equals
		The left and right object will be merged and added to the result set
		if all the right object properties listed by the -Equal parameter are
		equal to the left object properties (listed by the -On parameter).

		Note 1: The list of properties defined by the -Equal parameter will be
		justified with the list of properties defined by the -On parameter and
		visa versa.

		Note 2: If the -Equal and the -On parameter are omitted, a join by
		row index is returned.

		Note 3: The -Equals parameter cannot be used in combination with an
		-On parameter expression.

	.PARAMETER Where
		An expression that defines the condition to be met for the objects to
		be returned. There is no limit to the number of predicates that can be
		included in the condition.

	.PARAMETER Unify
		The -Unify (alias -Merge) parameter defines how to unify the left and
		right object with respect to the unrelated common properties. The
		common properties can discerned (<String>[,<String>]) or merged
		(<ScriptBlock>). By default the unrelated common properties wil be
		merged using the expression: {$LeftOrVoid.$_, $RightOrVoid.$_}

		<String>[,<String>]
		If the value is not a ScriptBlock, it is presumed a string array with
		one or two items defining the left and right key format. If the item
		includes an asterisks (*), the asterisks will be replaced with the
		property name otherwise the item will be used to prefix the property name.

		Note: A consecutive number will be automatically added to a common
		property name if is already used.

		<ScriptBlock>
		An expression that defines how the left and right properties with the
		common property should be merged. Where the following variables are
		available:
		* $_: iterates each property name
		* $Void: an object with all (left and right) properties set to $Null
		* $Left: the current left object (each self-contained -LeftObject)
		* $LeftOrVoid: the left object otherwise an object with null values
		* $LeftOrRight: the left object otherwise the right object
		* $LeftKeys: an array containing all the left keys
		* $Right: the current right object (each self-contained -RightObject)
		* $RightOrVoid: the right object otherwise an object with null values
		* $RightOrLeft: the right object otherwise the left object
		* $RightKeys: an array containing all the right keys

		Note: Property expressions set by the -Unify paramter might be
		overwritten by specific -Property expressions.


	.PARAMETER Property
		A hash table or list of property names (strings) and/or hash tables.
		Hash tables should be in the format @{<PropertyName> = <Expression>}
		where the <Expression> usually defines how the specific left and
		right properties should be merged.

		If only a name (string) is supplied, either the left or the right
		value is used for unique properties or the default unify expression
		is used for unrelated common properties.

		Note: Any unknown properties will be added to the output object.

	.EXAMPLE

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

	.EXAMPLE

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

	.EXAMPLE

		PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id

		Id         Name             Country            Department                 Age         ReportsTo
		--         ----             -------            ----------                 ---         ---------
		{1, 5}     {Aerts, Evans}   {Belgium, England} {Sales, Marketing}         {40, 35}    {5, }
		{2, 4}     {Bauer, Duval}   {Germany, France}  {Engineering, Engineering} {31, 21}    {4, 5}
		{3, 1}     {Cook, Aerts}    {England, Belgium} {Sales, Sales}             {69, 40}    {1, 5}
		{4, 5}     {Duval, Evans}   {France, England}  {Engineering, Marketing}   {21, 35}    {5, }
		{5, $null} {Evans, $null}   {England, $null}   {Marketing, $null}         {35, $null} {, $null}
		{6, 4}     {Fischer, Duval} {Germany, France}  {Engineering, Engineering} {29, 21}    {4, 5}

	.LINK
		https://github.com/iRon7/Join-Object
#>
Function Join-Object {
	[CmdletBinding()][OutputType([Object[]])]Param (
		[Parameter(ValueFromPipeLine = $True)][Object[]]$LeftObject, [Parameter(Position=0)][Object[]]$RightObject,
		[Parameter(Position = 1)][Alias("Using")]$On, [String[]]$Equals, [ScriptBlock]$Where,
		[Parameter(Position = 2)][Alias("Merge")]$Unify = {$LeftOrVoid.$_, $RightOrVoid.$_},
		[Parameter(Position = 3)]$Property,
		[Parameter(Position = 4)][ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')]$JoinType = 'Inner'
	)
	Begin {
		$HashTable = $Null; $Esc = [Char]27;$EscNull = $Esc + 'Null'; $EscSeparator = $Esc + ','
		$Expression = New-Object System.Collections.Specialized.OrderedDictionary; $New = New-Object System.Collections.Specialized.OrderedDictionary
		$RightKeys = @(); $RightObject[0].PSObject.Properties | ForEach-Object {$RightKeys += $_.Name}
		$RightLength = @($RightObject).Length; $LeftIndex = 0; $InnerRight = @($False) * $RightLength
		Function Out-Join($LeftIndex, $RightIndex, $Left, $Right, $LeftOrRight, $RightOrLeft, $LeftOrVoid, $RightOrVoid) {
			$Expression.Get_Keys() | ForEach-Object {$New.$_ = &$Expression.$_}; New-Object PSObject -Property $New
		}
	}
	Process {
		If (!$PSBoundParameters.ContainsKey('LeftObject')) {$LeftObject = $RightObject}
		ForEach ($Left in @($LeftObject)) {
			$InnerLeft = $Null; $All = !$PSBoundParameters.ContainsKey('Property')
			If (!$LeftIndex) {
				$LeftKeys = @(); $LeftObject[0].PSObject.Properties | ForEach-Object {$LeftKeys += $_.Name}
				If ($Property.PSTypeNames -Match "^System.Collections") {$Expression = $Property}
				Else {
					@($Property) | Where-Object {$_} | ForEach-Object {
						If ($_.PSObject.Properties['Keys']) {$Expression += $_}
						Else {If ($_ -eq "*") {$All = $True} Else {$Expression.$_ = {}}}
					}
				}
				If ($On -is [ScriptBlock]) {If ($Equals) {Throw "The Equals parameter cannot be used with an On parameter expression"}}
				ElseIf ($Null -ne $On -or $Null -ne $Equals) {
					$On = If ($On) {,@($On)} Else {,@()}; $Equals = If ($Equals) {,@($Equals)} Else {,@()}
					For ($i = 0; $i -lt [Math]::Max($On.Length, $Equals.Length); $i++) {
						If ($i -ge $On.Length) {$On += $Equals[$i]}
						If ($LeftKeys -NotContains $On[$i]) {Throw "The property '$($On[$i])' cannot be found on the left object."}
						If ($i -ge $Equals.Length) {$Equals += $On[$i]}
						If ($RightKeys  -NotContains $Equals[$i]) {Throw "The property '$($Equals[$i])' cannot be found on the right object."}
						If ($On[$i] -eq $Equals[$i] -and ($All -or $Expression[$On[$i]]) -and !"$($Expression[$On[$i]])") {$Expression[$On[$i]] = {$LeftOrRight.$_}}
					}
				}
				If ($On -is [Array]) {$HashTable = @{}
					For ($i = 0; $i -lt $RightLength; $i++) {$Right = $RightObject[$i]
						$Values = $Equals | ForEach-Object {If ($Null -ne $Right.$_) {$Right.$_} Else {$EscNull}}
						[Array]$HashTable[[system.String]::Join($EscSeparator, $Values)] += $i
					}
				}
				$Items = @{}; $LeftKeys + $RightKeys | Select-Object -Unique | ForEach-Object {$Items.$_ = $Null
					If (($All -or $Expression[$_]) -and !"$($Expression[$_])") {
						If ($LeftKeys -Contains $_ ) {
							If ($RightKeys -Contains $_) {
								If ($Unify -is [ScriptBlock]) {
									$Expression.$_ = $Unify
								} Else {
									ForEach ($01 in 0, 1) {$Key = (@($Unify) + "")[$01]
										$Key = If ("$Key".Contains("*"))  {([Regex]"\*").Replace("$Key", $_, 1)} Else {"$Key$_"}
										$i = ""; While ($Expression.Keys -Contains "$Key$i") {$i = [Int]$i + 1}; $Key = "$Key$i"
										$Expression.$Key = [ScriptBlock]::Create("$(('$LeftOrVoid', '$RightOrVoid')[$01]).'$_'")
									}
								}
							} Else {$Expression.$_ = {$LeftOrVoid.$_}}
						} Else {$Expression.$_ = {$RightOrVoid.$_}}
					}
				}; $Void = New-Object PSObject -Property $Items
			}
			$RightList = `
				If ($On -is [Array]) {
					$Values = $On | ForEach-Object {If ($Null -ne $Left.$_) {$Left.$_} Else {$EscNull}}
					$HashTable[[system.String]::Join($EscSeparator, $Values)]
				} ElseIf ($On -is [ScriptBlock]) {
					For ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {
						$Right = $RightObject[$RightIndex]; If (&$On) {$RightIndex}
					}
				}
				ElseIf ($JoinType -eq "Cross") {0..($RightObject.Length - 1)}
				ElseIf ($LeftIndex -lt $RightLength) {$LeftIndex} Else {$Null}
			ForEach ($RightIndex in $RightList) {$Right = $RightObject[$RightIndex]
				If (!$Where -Or (&$Where)) {
					Out-Join -LeftIndex $LeftIndex -RightIndex $RightIndex `
						-Left $Left -Right $Right -LeftOrRight $Left -RightOrLeft $Right -LeftOrVoid $Left -RightOrVoid $Right
					$InnerLeft = $True; $InnerRight[$RightIndex] = $True
				}
			}
			If (!$InnerLeft -and ($JoinType -eq "Left" -or $JoinType -eq "Full")) {
				Out-Join -LeftIndex $LeftIndex -RightIndex $Null `
					-Left $Left -Right $Null -LeftOrRight $Left -RightOrLeft $Left -LeftOrVoid $Left -RightOrVoid $Void
			}
			$LeftIndex++
		}
	}
	End {
		If ($JoinType -eq "Right" -or $JoinType -eq "Full") {$Left = $Null
			For ($RightIndex = 0; $RightIndex -lt $RightObject.Length; $RightIndex++) {
				If (!$InnerRight[$RightIndex]) {
					$Right = $RightObject[$RightIndex]
					Out-Join -LeftIndex $Null -RightIndex $RightIndex `
						-Left $Null -Right $Right -LeftOrRight $Right -RightOrLeft $Right -LeftOrVoid $Void -RightOrVoid $Right
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
Copy-Command -Command $JoinCommand -Name InnerJoin-Object -Default @{JoinType = 'Inner'}; Set-Alias InnerJoin InnerJoin-Object
Copy-Command -Command $JoinCommand -Name LeftJoin-Object  -Default @{JoinType = 'Left'};  Set-Alias LeftJoin  LeftJoin-Object
Copy-Command -Command $JoinCommand -Name RightJoin-Object -Default @{JoinType = 'Right'}; Set-Alias RightJoin RightJoin-Object
Copy-Command -Command $JoinCommand -Name FullJoin-Object  -Default @{JoinType = 'Full'};  Set-Alias FullJoin  FullJoin-Object
Copy-Command -Command $JoinCommand -Name CrossJoin-Object -Default @{JoinType = 'Cross'}; Set-Alias CrossJoin CrossJoin-Object
Copy-Command -Command $JoinCommand -Name Update-Object    -Default @{JoinType = 'Left'; Merge = {{$RightOrLeft.$_}}}; Set-Alias Update Update-Object
Copy-Command -Command $JoinCommand -Name Merge-Object     -Default @{JoinType = 'Full'; Merge = {{$RightOrLeft.$_}}}; Set-Alias Merge  Merge-Object
