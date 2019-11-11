<#PSScriptInfo
.VERSION 3.1.2
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
	Combines two object lists based on a related property between them.

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
	  Returns each left object joined to each right object
	* Update-Object (Join-Object -JoinType Left -Merge = {RightOrLeft.$_})
	  Returns each left object updated with the right object properties
	* Merge-Object (Join-Object -JoinType Full -Merge = {RightOrLeft.$_})
	  Returns each left object updated with the right object properties
	  and the rest of the right objects

	Each command has an alias equal to its verb (omitting '-Object').

	.PARAMETER LeftObject
		The LeftObject, usually provided through the pipeline, defines the
		left object (or datatable) to be joined.

	.PARAMETER RightObject
		The RightObject, provided by the first argument, defines the right
		object (or datatable) to be joined.

	.PARAMETER On
		The -On (alias -Using) parameter defines the condition that specify how
		to join the left and right object and which objects to include in the
		(inner) result set. The -On parameter supports the following formats:

		<String> or <Array>
		If the value is a string or array type, the -On parameter is similar to
		the SQL using clause. This means that the left and right object will be
		merged and added to the result set if all the left object properties
		listed by the -On parameter are equal to the right object properties
		(listed by the -Equals parameter).

		Note 1: The list of properties defined by the -On parameter will be
		complemented with the list of properties defined by the -Equals
		parameter and vice versa.

		Note 2: Joined properties will be merged to a single (left) property
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
		complemented with the list of properties defined by the -On parameter
		and vice versa.

		Note 2: If the -On and the -Equals parameter are omitted, a join by
		row index is returned.

		Note 3: The -Equals parameter cannot be used in combination with an
		-On parameter expression.

	.PARAMETER Where
		An expression that defines the condition to be met for the objects to
		be returned. There is no limit to the number of predicates that can be
		included in the condition.

	.PARAMETER Discern
		The -Discern parameter defines how to discern the left and right object
		with respect to the common properties that aren't joined.

		The first string defines how to rename the left property, the second
		string (if defined) defines how to rename the right property.
		If the string contains an asterisks (*), the asterisks will be replaced
		with the original property name, otherwise, the property name will be
		prefixed with the given string.

		Properties that don't exist on both sides will not be renamed.

		Joined properties (defined by the -On parameter) will be merged.

		Note: The -Discern parameter cannot be used with the -Property parameter.

	.PARAMETER Property
		A hash table or list of property names (strings) and/or hash tables that
		define a new selection of property names and values

		Hash tables should be in the format @{<PropertyName> = <Expression>}
		where the <Expression> defines how the specific left and right
		properties should be merged. Where the following variables are
		available for each joined object:
		* $_: iterates each property name
		* $Left: the current left object (each self-contained -LeftObject)
		* $LeftIndex: the index of the left object
		* $Right: the current right object (each self-contained -RightObject)
		* $RightIndex: the index of the right object
		If the $LeftObject isn't joined in a Right- or FullJoin then $LeftIndex
		will be $Null and the $Left object will represent an object with each
		property set to $Null.
		If the $RightObject isn't joined in a Left- or FullJoin then $RightIndex
		will be $Null and the $Right object will represent an object with each
		property set to $Null.

		An asterisks (*) represents all known left - and right properties.

		If the -Property and the -Discern parameters are ommited or in case a
		property name (or an asterisks) is supplied without expression, the
		expression will be automatically added using the following rules:
		* If the property only exists on the left side, the expression is:
		  {$Left.$_}
		* If the property only exists on the right side, the expression is:
		  {$Right.$_}
		* If the left - and right properties aren't joined, the expression is:
		  {$Left.$_, $Right.$_}
		* If the left - and right property are joined, the expression is:
		  {If ($Null -ne $LeftIndex) {$Left.$_} Else {$Right.$_}}}

		If an expression without a property name assignment is supplied, it will
		be assigned to all known properties in the $LeftObject and $RightObject.

		The last defined expression will overrule any previous defined
		expressions

		Note: The -Property parameter cannot be used with the -Discern parameter.

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


		PS C:\> $Employee | InnerJoin $Department -On Country | Format-Table

		Id Name                   Country Department  Age ReportsTo
		-- ----                   ------- ----------  --- ---------
		 2 {Bauer, Engineering}   Germany Engineering  31         4
		 3 {Cook, Marketing}      England Sales        69         1
		 4 {Duval, Sales}         France  Engineering  21         5
		 4 {Duval, Purchase}      France  Engineering  21         5
		 5 {Evans, Marketing}     England Marketing    35
		 6 {Fischer, Engineering} Germany Engineering  29         4

	.EXAMPLE

		PS C:\> $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department | Format-Table

		Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
		-- ------------ --------------- ----------  --- --------- -------------- -----------------
		 1 Aerts        Belgium         Sales        40         5 Sales          France
		 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
		 3 Cook         England         Sales        69         1 Sales          France
		 4 Duval        France          Engineering  21         5 Engineering    Germany
		 5 Evans        England         Marketing    35           Marketing      England
		 6 Fischer      Germany         Engineering  29         4 Engineering    Germany

	.EXAMPLE

		PS C:\> $Changes

		Id Name    Country Department  Age ReportsTo
		-- ----    ------- ----------  --- ---------
		 3 Cook    England Sales        69         5
		 6 Fischer France  Engineering  29         4
		 7 Geralds Belgium Sales        71         1


		PS C:\> $Employee | Merge $Changes -On Id | Format-Table

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

		PS C:\> LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left.Name}; Manager = {$Right.Name}}

		Name    Manager
		----    -------
		Aerts   Evans
		Bauer   Duval
		Cook    Aerts
		Duval   Evans
		Evans
		Fischer Duval

	.LINK
		https://github.com/iRon7/Join-Object
#>
Function Join-Object {
	[CmdletBinding(DefaultParameterSetName='Property')][OutputType([Object[]])]Param (
		[Parameter(ValueFromPipeLine = $True)]$LeftObject,
		[Parameter(Position = 0, ParameterSetName = 'Property', Mandatory = $True)][Parameter(Position = 0, ParameterSetName = 'Discern', Mandatory = $True)]$RightObject,
		[Parameter(Position = 1, ParameterSetName = 'Property')][Parameter(Position = 1, ParameterSetName = 'Discern')][Alias("Using")]$On,
		[Parameter(ParameterSetName = 'Property')][Parameter(ParameterSetName = 'Discern')][String[]]$Equals,
		[Parameter(Position = 2, ParameterSetName = 'Discern')][String[]]$Discern, [Parameter(ParameterSetName = 'Property')]$Property,
		[Parameter(Position = 3, ParameterSetName = 'Property')][Parameter(Position = 3, ParameterSetName = 'Discern')][ScriptBlock]$Where,
		[Parameter(ParameterSetName = 'Property')][Parameter(ParameterSetName = 'Discern')][ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')]$JoinType = 'Inner'
	)
	Begin {
		$HashTable = $Null; $Esc = [Char]27;$EscNull = $Esc + 'Null'; $EscSeparator = $Esc + ','
		$Expression = [Ordered]@{}; $PropertyList = [Ordered]@{}; $Related = @()
		If ($RightObject -isnot [Array] -and $RightObject -isnot [Data.DataTable]) {$RightObject = @($RightObject)}
		$RightKeys = @(
			If ($RightObject -is [Data.DataTable]) {$RightObject.Columns | Select-Object -ExpandProperty 'ColumnName'}
			Else {($RightObject | Select-Object -First 1).PSObject.Properties | Select-Object -ExpandProperty 'Name'}
		)
		$RightProperties = @{}; ForEach ($Key in $RightKeys) {$RightProperties.$Key = $Null}
		$RightVoid = New-Object PSCustomObject -Property $RightProperties
		$RightLength = @($RightObject).Length; $LeftIndex = 0; $InnerRight = @($False) * $RightLength
		Function Out-Join($LeftIndex, $RightIndex, $Left = $LeftVoid, $Right = $RightVoid) {
			ForEach ($_ in $Expression.Get_Keys()) {$PropertyList.$_ = &$Expression.$_}
			New-Object PSCustomObject -Property $PropertyList
		}
		Function SetExpression([String]$Key, [ScriptBlock]$ScriptBlock) {
			If ($Key -eq '*') {$Key = $Null}
			If ($Key -and $ScriptBlock) {$Expression.$Key = $ScriptBlock}
			Else {
				$Keys = If ($Key) {@($Key)} Else {$LeftKeys + $RightKeys}
				ForEach ($Key in $Keys) {
					If (!$Expression.Contains($Key)) {
						$InLeft  = $LeftKeys  -Contains $Key
						$InRight = $RightKeys -Contains $Key
						If ($InLeft -and $InRight) {
							$Expression.$Key = If ($ScriptBlock) {$ScriptBlock}
								ElseIf ($Related -NotContains $Key) {{$Left.$_, $Right.$_}}
								Else {{If ($Null -ne $LeftIndex) {$Left.$_} Else {$Right.$_}}}
						}
						ElseIf ($InLeft)  {$Expression.$Key = {$Left.$_}}
						ElseIf ($InRight) {$Expression.$Key = {$Right.$_}}
						Else {Throw "The property '$Key' cannot be found on the left or right object."}
					}
				}
			}
		}
	}
	Process {
		$SelfJoin = !$PSBoundParameters.ContainsKey('LeftObject'); If ($SelfJoin) {$LeftObject = $RightObject}
		ForEach ($Left in @($LeftObject)) {
			$InnerLeft = $Null
			If (!$LeftIndex) {
				$LeftKeys = @(
					If ($Left -is [Data.DataRow]) {$Left.Table.Columns | Select-Object -ExpandProperty 'ColumnName'}
					Else {$Left.PSObject.Properties | Select-Object -ExpandProperty 'Name'}
				)
				$LeftProperties = @{}; ForEach ($Key in $LeftKeys) {$LeftProperties.$Key = $Null}
				$LeftVoid = New-Object PSCustomObject -Property $LeftProperties
				If ($On -is [ScriptBlock]) {If ($Equals) {Throw "The Equals parameter cannot be used with an On parameter expression"}}
				ElseIf ($Null -ne $On -or $Null -ne $Equals) {
					$On = If ($On) {,@($On)} Else {,@()}; $Equals = If ($Equals) {,@($Equals)} Else {,@()}
					For ($i = 0; $i -lt [Math]::Max($On.Length, $Equals.Length); $i++) {
						If ($i -ge $On.Length) {$On += $Equals[$i]}
						If ($LeftKeys -NotContains $On[$i]) {Throw "The property '$($On[$i])' cannot be found on the left object."}
						If ($i -ge $Equals.Length) {$Equals += $On[$i]}
						If ($RightKeys -NotContains $Equals[$i]) {Throw "The property '$($Equals[$i])' cannot be found on the right object."}
						If ($On[$i] -eq $Equals[$i]) {$Related += $On[$i]}
					}
				}
				If ($On -is [Array]) {$HashTable = @{}
					$RightIndex = 0; ForEach ($Right in $RightObject) {
						$Values = ForEach ($Name in @($Equals)) {If ($Null -ne $Right.$Name) {$Right.$Name} Else {$EscNull}}
						[Array]$HashTable[[String]::Join($EscSeparator, $Values)] += $RightIndex++
					}
				}
				If ($Discern) {
					If (@($Discern).Count -le 1) {$Discern = @($Discern) + ''}
					ForEach ($Key in $LeftKeys) {
						If ($RightKeys -Contains $Key) {
							If ($Related -Contains $Key) {
								$Expression[$Key] = {If ($Null -ne $LeftIndex) {$Left.$_} Else {$Right.$_}}
							} Else {
								$Name = If ($Discern[0].Contains('*')) {([Regex]"\*").Replace($Discern[0], $Key, 1)} Else {$Discern[0] + $Key}
								$Expression[$Name] = [ScriptBlock]::Create("`$Left.'$Key'")
							}
						} Else {$Expression[$Key] = {$Left.$_}}
					}
					ForEach ($Key in $RightKeys) {
						If ($LeftKeys -Contains $Key) {
							If ($Related -NotContains $Key) {
								$Name = If ($Discern[1].Contains('*')) {([Regex]"\*").Replace($Discern[1], $Key, 1)} Else {$Discern[1] + $Key}
								$Expression[$Name] = [ScriptBlock]::Create("`$Right.'$Key'")
							}
						} Else {$Expression[$Key] = {$Right.$_}}
					}
				} ElseIf ($Property) {
					ForEach ($Item in @($Property)) {
						If ($Item -is [ScriptBlock]) {SetExpression $Null $Item}
						ElseIf ($Item -is [System.Collections.IDictionary]) {ForEach ($Key in $Item.Get_Keys()) {SetExpression $Key $Item.$Key}}
						Else {SetExpression $Item}
					}
				} Else {SetExpression}
			}
			$RightList = `
				If ($On -is [Array]) {
					$Values = ForEach ($Name in @($On)) {If ($Null -ne $Left.$Name) {$Left.$Name} Else {$EscNull}}
					$HashTable[[String]::Join($EscSeparator, $Values)]
				} ElseIf ($On -is [ScriptBlock]) {
					For ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {
						$Right = $RightObject[$RightIndex]; If (&$On) {$RightIndex}
					}
				}
				ElseIf ($JoinType -eq "Cross") {0..($RightObject.Length - 1)}
				ElseIf ($LeftIndex -lt $RightLength) {$LeftIndex} Else {$Null}
			ForEach ($RightIndex in $RightList) {
				$Right = If ($RightObject -is [Data.DataTable]) {$RightObject.Rows[$RightIndex]} Else {$RightObject[$RightIndex]}
				If (!$Where -Or (&$Where)) {
					Out-Join -LeftIndex $LeftIndex -RightIndex $RightIndex -Left $Left -Right $Right
					$InnerLeft = $True; $InnerRight[$RightIndex] = $True
				}
			}
			If (!$InnerLeft -and ($JoinType -eq "Left" -or $JoinType -eq "Full")) {
				Out-Join -LeftIndex $LeftIndex -Left $Left
			}
			$LeftIndex++
		}
	}
	End {
		If ($JoinType -eq "Right" -or $JoinType -eq "Full") {$Left = $Null
			$RightIndex = 0; ForEach ($Right in $RightObject) {
				If (!$InnerRight[$RightIndex]) {
					Out-Join -RightIndex $RightIndex -Right $Right
				}
				$RightIndex++
			}
		}
	}
}; Set-Alias Join Join-Object

Function Copy-Command([System.Management.Automation.CommandInfo]$Command, [String]$Name, [HashTable]$DefaultParameters) {
	Try {
		$MetaData = [System.Management.Automation.CommandMetadata]$Command
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
Copy-Command -Command $JoinCommand -Name Update-Object    -Default @{JoinType = 'Left'; Property = {{If ($Null -ne $RightIndex) {$Right.$_} Else {$Left.$_}}}}; Set-Alias Update Update-Object
Copy-Command -Command $JoinCommand -Name Merge-Object     -Default @{JoinType = 'Full'; Property = {{If ($Null -ne $RightIndex) {$Right.$_} Else {$Left.$_}}}}; Set-Alias Merge  Merge-Object
