<#PSScriptInfo
.VERSION 3.2.1
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
	their own (-JoinType and -Property) defaults:

	* InnerJoin-Object (Alias InnerJoin or Join)
	  Returns the joined objects
	* LeftJoin-Object (Alias LeftJoin)
	  Returns the joined objects and the rest of the left objects
	* RightJoin-Object (Alias RightJoin)
	  Returns the joined objects and the rest of the right objects
	* FullJoin-Object (Alias FullJoin)
	  Returns the joined objects and the rest of the left and right objects
	* CrossJoin-Object (Alias CrossJoin)
	  Returns each left object joined to each right object
	* Update-Object (Alias Update)
	  Returns each left object updated with the right object properties
	* Merge-Object (Alias Merge)
	  Returns each left object updated with the right object properties
	  and the rest of the right objects

	.PARAMETER LeftObject
		The LeftObject, usually provided through the pipeline, defines the
		left object (or datatable) to be joined.

	.PARAMETER RightObject
		The RightObject, provided by the first argument, defines the right
		object (or datatable) to be joined.

	.PARAMETER On
		The -On parameter (alias -Using) defines which objects should be joined.
		If the -Equals parameter is omitted, the value(s) of the properties
		listed by the -On parameter should be equal at both sides in order to
		join the left object with the right object.

		Note 1: The list of properties defined by the -On parameter will be
		complemented with the list of properties defined by the -Equals
		parameter and vice versa.

		Note 2: Related joined properties will be merged to a single (left)
		property by default (see also the -Property parameter).

		Note 3: If the -On and the -OnExpression parameter are omitted, a
		join by row index is returned.

	.PARAMETER Equals
		If the -Equals parameter is supplied, the value(s) of the left object
		properties listed by the -On parameter should be equal to the value(s)
		of the right object listed by the -Equals parameter in order to join
		the left object with the right object.

		Note 1: The list of properties defined by the -Equal parameter will be
		complemented with the list of properties defined by the -On parameter
		and vice versa.

		Note 2: The -Equals parameter can only be used with the -On parameter.

	.PARAMETER Strict
		If the -Strict switch is set, the comparison between the related
		properties defined by the -On Parameter (and the -Equals parameter) is
		based on a strict equality (both type and value need to be equal).

	.PARAMETER MatchCase
		If the -MatchCase (alias -CaseSensitive) switch is set, the comparison
		between the related properties defined by the -On Parameter (and the
		-Equals parameter) will case sensitive.

	.PARAMETER OnExpression
		Any conditional expression (where $Left refers to each left object and
		$Right refers to each right object) that requires to evaluate to true
		in order to join the left object with the right object.

		Note 1: The -OnExporession parameter has the most complex comparison
		possibilities but is considerable slower than the other types.

		Note 2: The -OnExpression parameter cannot be used with the -On
		parameter.

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
		* If the properties are joined by the -On parameter, the expression is:
		  {If ($Null -ne $LeftIndex) {$Left.$_} Else {$Right.$_}}}
		* If properties aren't joined by the -On parameter, the expression is:
		  {$Left.$_, $Right.$_}

		If an expression without a property name assignment is supplied, it will
		be assigned to all known properties in the $LeftObject and $RightObject.

		The last defined expression will overrule any previous defined
		expressions

		Note: The -Property parameter cannot be used with the -Discern parameter.

	.PARAMETER JoinType
		Defines which unrelated objects should be included (see: Descripton).
		Valid values are: 'Inner', 'Left', 'Right', 'Full' or 'Cross'.
		The default is 'Inner'.

		Note: It is recommended to use the related proxy commands instead.

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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Scope='Function')]
	[CmdletBinding(DefaultParameterSetName='Default')][OutputType([Object[]])]Param (

		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Default')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'On')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Expression')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Property')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'Discern')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'OnProperty')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'OnDiscern')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'ExpressionProperty')]
		[Parameter(ValueFromPipeLine = $True, Mandatory = $True, ParameterSetName = 'ExpressionDiscern')]
		$LeftObject,

		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Default')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'On')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Expression')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Property')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Discern')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'OnProperty')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'OnDiscern')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'ExpressionProperty')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'ExpressionDiscern')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Self')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOn')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpression')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfProperty')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfDiscern')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOnProperty')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfOnDiscern')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpressionProperty')]
		[Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'SelfExpressionDiscern')]
		$RightObject,

		[Parameter(Position = 1, ParameterSetName = 'On', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'OnProperty', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'OnDiscern', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfOn', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfOnProperty', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfOnDiscern', Mandatory = $True)]
		[Alias("Using")][String[]]$On,

		[Parameter(Position = 1, ParameterSetName = 'Expression', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'ExpressionProperty', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'ExpressionDiscern', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfExpression', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfExpressionProperty', Mandatory = $True)]
		[Parameter(Position = 1, ParameterSetName = 'SelfExpressionDiscern', Mandatory = $True)]
		[Alias("UsingExpression")][ScriptBlock]$OnExpression,

		[Parameter(ParameterSetName = 'On')]
		[Parameter(ParameterSetName = 'OnProperty')]
		[Parameter(ParameterSetName = 'OnDiscern')]
		[Parameter(ParameterSetName = 'SelfOn')]
		[Parameter(ParameterSetName = 'SelfOnProperty')]
		[Parameter(ParameterSetName = 'SelfOnDiscern')]
		[String[]]$Equals,

		[Parameter(Position = 2, ParameterSetName = 'Discern', Mandatory = $True)]
		[Parameter(Position = 2, ParameterSetName = 'OnDiscern', Mandatory = $True)]
		[Parameter(Position = 2, ParameterSetName = 'ExpressionDiscern', Mandatory = $True)]
		[Parameter(Position = 2, ParameterSetName = 'SelfDiscern', Mandatory = $True)]
		[Parameter(Position = 2, ParameterSetName = 'SelfOnDiscern', Mandatory = $True)]
		[Parameter(Position = 2, ParameterSetName = 'SelfExpressionDiscern', Mandatory = $True)]
		[AllowEmptyString()][String[]]$Discern,

		[Parameter(ParameterSetName = 'Property', Mandatory = $True)]
		[Parameter(ParameterSetName = 'OnProperty', Mandatory = $True)]
		[Parameter(ParameterSetName = 'ExpressionProperty', Mandatory = $True)]
		[Parameter(ParameterSetName = 'SelfProperty', Mandatory = $True)]
		[Parameter(ParameterSetName = 'SelfOnProperty', Mandatory = $True)]
		[Parameter(ParameterSetName = 'SelfExpressionProperty', Mandatory = $True)]
		$Property,

		[Parameter(Position = 3, ParameterSetName = 'Default')]
		[Parameter(Position = 3, ParameterSetName = 'On')]
		[Parameter(Position = 3, ParameterSetName = 'Expression')]
		[Parameter(Position = 3, ParameterSetName = 'Property')]
		[Parameter(Position = 3, ParameterSetName = 'Discern')]
		[Parameter(Position = 3, ParameterSetName = 'OnProperty')]
		[Parameter(Position = 3, ParameterSetName = 'OnDiscern')]
		[Parameter(Position = 3, ParameterSetName = 'ExpressionProperty')]
		[Parameter(Position = 3, ParameterSetName = 'ExpressionDiscern')]
		[Parameter(Position = 3, ParameterSetName = 'Self')]
		[Parameter(Position = 3, ParameterSetName = 'SelfOn')]
		[Parameter(Position = 3, ParameterSetName = 'SelfExpression')]
		[Parameter(Position = 3, ParameterSetName = 'SelfProperty')]
		[Parameter(Position = 3, ParameterSetName = 'SelfDiscern')]
		[Parameter(Position = 3, ParameterSetName = 'SelfOnProperty')]
		[Parameter(Position = 3, ParameterSetName = 'SelfOnDiscern')]
		[Parameter(Position = 3, ParameterSetName = 'SelfExpressionProperty')]
		[Parameter(Position = 3, ParameterSetName = 'SelfExpressionDiscern')]
		[ScriptBlock]$Where = {$True},

		[Parameter(ParameterSetName = 'Default')]
		[Parameter(ParameterSetName = 'On')]
		[Parameter(ParameterSetName = 'Expression')]
		[Parameter(ParameterSetName = 'Property')]
		[Parameter(ParameterSetName = 'Discern')]
		[Parameter(ParameterSetName = 'OnProperty')]
		[Parameter(ParameterSetName = 'OnDiscern')]
		[Parameter(ParameterSetName = 'ExpressionProperty')]
		[Parameter(ParameterSetName = 'ExpressionDiscern')]
		[Parameter(ParameterSetName = 'Self')]
		[Parameter(ParameterSetName = 'SelfOn')]
		[Parameter(ParameterSetName = 'SelfExpression')]
		[Parameter(ParameterSetName = 'SelfProperty')]
		[Parameter(ParameterSetName = 'SelfDiscern')]
		[Parameter(ParameterSetName = 'SelfOnProperty')]
		[Parameter(ParameterSetName = 'SelfOnDiscern')]
		[Parameter(ParameterSetName = 'SelfExpressionProperty')]
		[Parameter(ParameterSetName = 'SelfExpressionDiscern')]
		[ValidateSet('Inner', 'Left', 'Right', 'Full', 'Cross')]$JoinType = 'Inner',

		[Parameter(ParameterSetName = 'On')]
		[Parameter(ParameterSetName = 'OnProperty')]
		[Parameter(ParameterSetName = 'OnDiscern')]
		[Parameter(ParameterSetName = 'SelfOn')]
		[Parameter(ParameterSetName = 'SelfOnProperty')]
		[Parameter(ParameterSetName = 'SelfOnDiscern')]
		[Switch]$Strict,

		[Parameter(ParameterSetName = 'On')]
		[Parameter(ParameterSetName = 'OnProperty')]
		[Parameter(ParameterSetName = 'OnDiscern')]
		[Parameter(ParameterSetName = 'SelfOn')]
		[Parameter(ParameterSetName = 'SelfOnProperty')]
		[Parameter(ParameterSetName = 'SelfOnDiscern')]
		[Alias("CaseSensitive")][Switch]$MatchCase
	)
	Begin {
		$HashTable = $Null; $Esc = [Char]27; $EscSeparator = $Esc + ','
		$Expression = [Ordered]@{}; $PropertyList = [Ordered]@{}; $Related = @()
		If ($RightObject -isnot [Array] -and $RightObject -isnot [Data.DataTable]) {$RightObject = @($RightObject)}
		$RightKeys = @(
			If ($RightObject -is [Data.DataTable]) {$RightObject.Columns | Select-Object -ExpandProperty 'ColumnName'}
			Else {
				$First = $RightObject | Select-Object -First 1
				If ($First -is [System.Collections.IDictionary]) {$First.Get_Keys()}
				Else {$First.PSObject.Properties | Select-Object -ExpandProperty 'Name'}
			}
		)
		$RightProperties = @{}; ForEach ($Key in $RightKeys) {$RightProperties.$Key = $Null}
		$RightVoid = New-Object PSCustomObject -Property $RightProperties
		$RightLength = @($RightObject).Length; $LeftIndex = 0; $InnerRight = @($False) * $RightLength
		Function OutObject($LeftIndex, $RightIndex, $Left = $LeftVoid, $Right = $RightVoid) {
			If (&$Where) {
				ForEach ($_ in $Expression.Get_Keys()) {$PropertyList.$_ = &$Expression.$_}
				New-Object PSCustomObject -Property $PropertyList
			}
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
					ElseIf ($Left -is [System.Collections.IDictionary]) {$Left.Get_Keys()}
					Else {$Left.PSObject.Properties | Select-Object -ExpandProperty 'Name'}
				)
				$LeftProperties = @{}; ForEach ($Key in $LeftKeys) {$LeftProperties.$Key = $Null}
				$LeftVoid = New-Object PSCustomObject -Property $LeftProperties
				If ($Null -ne $On -or $Null -ne $Equals) {
					$On = If ($On) {,@($On)} Else {,@()}; $Equals = If ($Equals) {,@($Equals)} Else {,@()}
					For ($i = 0; $i -lt [Math]::Max($On.Length, $Equals.Length); $i++) {
						If ($i -ge $On.Length) {$On += $Equals[$i]}
						If ($LeftKeys -NotContains $On[$i]) {Throw "The property '$($On[$i])' cannot be found on the left object."}
						If ($i -ge $Equals.Length) {$Equals += $On[$i]}
						If ($RightKeys -NotContains $Equals[$i]) {Throw "The property '$($Equals[$i])' cannot be found on the right object."}
						If ($On[$i] -eq $Equals[$i]) {$Related += $On[$i]}
					}
					$HashTable = If ($MatchCase) {[HashTable]::New(0, [StringComparer]::Ordinal)} Else {@{}}
					$RightIndex = 0; ForEach ($Right in $RightObject) {
						$Keys = ForEach ($Name in @($Equals)) {$Right.$Name}
						$HashKey = If (!$Strict) {[String]::Join($EscSeparator, @($Keys))}
						           Else {[System.Management.Automation.PSSerializer]::Serialize($Keys)}
						[Array]$HashTable[$HashKey] += $RightIndex++
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
				If ($On) {
					If ($JoinType -eq "Cross") {Throw "The On parameter cannot be used on a cross join."}
					$Keys = ForEach ($Name in @($On)) {$Left.$Name}
					$HashKey = If (!$Strict) {[String]::Join($EscSeparator, @($Keys))}
							   Else {[System.Management.Automation.PSSerializer]::Serialize($Keys)}
					$HashTable[$HashKey]
				} ElseIf ($OnExpression) {
					If ($JoinType -eq "Cross") {Throw "The OnExpression parameter cannot be used on a cross join."}
					For ($RightIndex = 0; $RightIndex -lt $RightLength; $RightIndex++) {
						$Right = $RightObject[$RightIndex]; If (&$OnExpression) {$RightIndex}
					}
				}
				ElseIf ($JoinType -eq "Cross") {0..($RightObject.Length - 1)}
				ElseIf ($LeftIndex -lt $RightLength) {$LeftIndex} Else {$Null}
			ForEach ($RightIndex in $RightList) {
				$Right = If ($RightObject -is [Data.DataTable]) {$RightObject.Rows[$RightIndex]} Else {$RightObject[$RightIndex]}
					$OutObject = OutObject -LeftIndex $LeftIndex -RightIndex $RightIndex -Left $Left -Right $Right
					If ($Null -ne $OutObject) {$OutObject; $InnerLeft = $True; $InnerRight[$RightIndex] = $True}
			}
			If (!$InnerLeft -and ($JoinType -eq "Left" -or $JoinType -eq "Full")) {OutObject -LeftIndex $LeftIndex -Left $Left}
			$LeftIndex++
		}
	}
	End {
		If ($JoinType -eq "Right" -or $JoinType -eq "Full") {$Left = $Null
			$RightIndex = 0; ForEach ($Right in $RightObject) {
				If (!$InnerRight[$RightIndex]) {OutObject -RightIndex $RightIndex -Right $Right}
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
