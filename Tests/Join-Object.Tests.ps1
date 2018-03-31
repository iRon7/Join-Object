$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

. .\ConvertFrom-Table.ps1

Function Should-BeObject {
	Param (
		[Parameter(Position=0)][Object[]]$b, [Parameter(ValueFromPipeLine = $True)][Object[]]$a
	)
	$Property = ($a | Select-Object -First 1).PSObject.Properties | Select-Object -Expand Name
	$Difference = Compare-Object $b $a -Property $Property
	Try {"$($Difference | Select-Object -First 1)" | Should -BeNull} Catch {$PSCmdlet.WriteError($_)}

}

Describe 'Join-Object' {
	
	$Employee = ConvertFrom-Table '
		Name    Country Department
		----    ------- ----------
		Aerts   Belgium Sales
		Bauer   Germany Engineering
		Cook    England Sales
		Duval   France  Engineering
		Evans   England Marketing
		Fischer Germany Engineering'

	$Department = ConvertFrom-Table '
		Name        Country     Manager
		----        -------     -------
		Engineering Germany     Meyer
		Marketing   England     Morris
		Sales       France      Millet
		Board       Netherlands Mans'
	
	Context 'Join types' {

		It 'InnerJoin' {
			,($Employee | InnerJoin $Department -On Country) | Should-BeObject (ConvertFrom-Table '
				Country Department  Manager Name
				------- ----------  ------- ----
				Germany Engineering Meyer   {Bauer, Engineering}
				England Sales       Morris  {Cook, Marketing}
				France  Engineering Millet  {Duval, Sales}
				England Marketing   Morris  {Evans, Marketing}
				Germany Engineering Meyer   {Fischer, Engineering}')
		}

		It 'LeftJoin' {
			,($Employee | LeftJoin $Department -On Country) | Should-BeObject (ConvertFrom-Table '
				Country Department  Manager Name
				------- ----------  ------- ----
				Belgium Sales       `$Null  `"Aerts", $Null
				Germany Engineering Meyer   {Bauer, Engineering}
				England Sales       Morris  {Cook, Marketing}
				France  Engineering Millet  {Duval, Sales}
				England Marketing   Morris  {Evans, Marketing}
				Germany Engineering Meyer   {Fischer, Engineering}')
		}

		It "RightJoin" {
			,($Employee | RightJoin $Department -On Country) | Should-BeObject (ConvertFrom-Table '
				Department  Name                   Manager Country
				----------  ----                   ------- -------
				Engineering {Bauer, Engineering}   Meyer   Germany
				Sales       {Cook, Marketing}      Morris  England
				Engineering {Duval, Sales}         Millet  France
				Marketing   {Evans, Marketing}     Morris  England
				Engineering {Fischer, Engineering} Meyer   Germany
				`$Null      `$Null, "Board"        Mans    Netherlands')
		}

		It 'FullJoin' {
			,($Employee | FullJoin $Department -On Country) | Should-BeObject (ConvertFrom-Table '
				Country     Department  Name                   Manager
				-------     ----------  ----                   -------
				Belgium     Sales       `"Aerts", $Null        `$Null
				Germany     Engineering {Bauer, Engineering}   Meyer
				England     Sales       {Cook, Marketing}      Morris
				France      Engineering {Duval, Sales}         Millet
				England     Marketing   {Evans, Marketing}     Morris
				Germany     Engineering {Fischer, Engineering} Meyer
				Netherlands `$Null      `$Null, "Board"        Mans')
		}

		It 'Cross Join' {
			,($Employee | Join $Department) | Should-BeObject (ConvertFrom-Table '
				Country                Department  Manager Name
				-------                ----------  ------- ----
				{Belgium, Germany}     Sales       Meyer   {Aerts, Engineering}
				{Belgium, England}     Sales       Morris  {Aerts, Marketing}
				{Belgium, France}      Sales       Millet  {Aerts, Sales}
				{Belgium, Netherlands} Sales       Mans    {Aerts, Board}
				{Germany, Germany}     Engineering Meyer   {Bauer, Engineering}
				{Germany, England}     Engineering Morris  {Bauer, Marketing}
				{Germany, France}      Engineering Millet  {Bauer, Sales}
				{Germany, Netherlands} Engineering Mans    {Bauer, Board}
				{England, Germany}     Sales       Meyer   {Cook, Engineering}
				{England, England}     Sales       Morris  {Cook, Marketing}
				{England, France}      Sales       Millet  {Cook, Sales}
				{England, Netherlands} Sales       Mans    {Cook, Board}
				{France, Germany}      Engineering Meyer   {Duval, Engineering}
				{France, England}      Engineering Morris  {Duval, Marketing}
				{France, France}       Engineering Millet  {Duval, Sales}
				{France, Netherlands}  Engineering Mans    {Duval, Board}
				{England, Germany}     Marketing   Meyer   {Evans, Engineering}
				{England, England}     Marketing   Morris  {Evans, Marketing}
				{England, France}      Marketing   Millet  {Evans, Sales}
				{England, Netherlands} Marketing   Mans    {Evans, Board}
				{Germany, Germany}     Engineering Meyer   {Fischer, Engineering}
				{Germany, England}     Engineering Morris  {Fischer, Marketing}
				{Germany, France}      Engineering Millet  {Fischer, Sales}
				{Germany, Netherlands} Engineering Mans    {Fischer, Board}')
		}

	}
	
	Context 'Single object' {

		It 'Single left object' {
			,($Employee[1] | InnerJoin $Department -On Country) | Should-BeObject (ConvertFrom-Table '
				Country Department  Manager Name
				------- ----------  ------- ----
				Germany Engineering Meyer   {Bauer, Engineering}')
		}

		It 'Single right object' {
			,($Employee | InnerJoin $Department[0] -On Country) | Should-BeObject (ConvertFrom-Table '
				Country Department  Manager Name
				------- ----------  ------- ----
				Germany Engineering Meyer   {Bauer, Engineering}
				Germany Engineering Meyer   {Fischer, Engineering}')
		}

		It 'Single left object and single right object' {
			,($Employee[1] | InnerJoin $Department[0] -On Country) | Should-BeObject (ConvertFrom-Table '
				Country Department  Manager Name
				------- ----------  ------- ----
				Germany Engineering Meyer   {Bauer, Engineering}')
		}
	}

	Context "-On ... -Equals ..." {

		It '$Employee | InnerJoin $Department -On Department -Eq Name' {
			,($Employee | InnerJoin $Department -On Department -Eq Name) | Should-BeObject (ConvertFrom-Table '
				Country            Department  Name                   Manager
				-------            ----------  ----                   -------
				{Belgium, France}  Sales       {Aerts, Sales}         Millet
				{Germany, Germany} Engineering {Bauer, Engineering}   Meyer
				{England, France}  Sales       {Cook, Sales}          Millet
				{France, Germany}  Engineering {Duval, Engineering}   Meyer
				{England, England} Marketing   {Evans, Marketing}     Morris
				{Germany, Germany} Engineering {Fischer, Engineering} Meyer')
		}
	}

	Context "Merge values on Department = Name" {

		It 'Use the left object property if exists otherwise use right object property' {
			,($Employee | InnerJoin $Department -On Department -Eq Name {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}) | Should-BeObject (ConvertFrom-Table '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Sales       Aerts   Millet  Belgium
				Engineering Bauer   Meyer   Germany
				Sales       Cook    Millet  England
				Engineering Duval   Meyer   France
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany')
		}

		It 'Only use the left name property and the right manager property' {
			,($Employee | InnerJoin $Department -On Department -Eq Name -Property @{Name = {$Left.$_}; Manager = {$Right.$_}}) | Should-BeObject (ConvertFrom-Table '
				Name    Manager
				----    -------
				Aerts   Millet
				Bauer   Meyer
				Cook    Millet
				Duval   Meyer
				Evans   Morris
				Fischer Meyer')
		}

		It 'Use the left object property except for the country property' {
			,($Employee | InnerJoin $Department -On Department -Eq Name {$Left.$_} @{Manager = {$Right.$_}}) | Should-BeObject (ConvertFrom-Table '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Sales       Aerts   Millet  Belgium
				Engineering Bauer   Meyer   Germany
				Sales       Cook    Millet  England
				Engineering Duval   Meyer   France
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany')
		}
	}

	Context "Join using expression" {

		It 'InnerJoin on Employee.Department = Department.Name and Employee.Country = Department.Country' {
			,($Employee | InnerJoin $Department -Using {$Left.Department -eq $Right.Name -and $Left.Country -eq $Right.Country} {$Left.$_} @{Manager = {$Right.$_}}) | Should-BeObject (ConvertFrom-Table '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Engineering Bauer   Meyer   Germany
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany')
		}

		It 'Inner join on index' {
			,($Employee | InnerJoin $Department {$LeftIndex -eq $RightIndex}) | Should-BeObject (ConvertFrom-Table '
				Country               Department  Name                 Manager
				-------               ----------  ----                 -------
				{Belgium, Germany}    Sales       {Aerts, Engineering} Meyer
				{Germany, England}    Engineering {Bauer, Marketing}   Morris
				{England, France}     Sales       {Cook, Sales}        Millet
				{France, Netherlands} Engineering {Duval, Board}       Mans')
		}
		
		It 'Full join on index' {
			,($Employee | FullJoin $Department {$LeftIndex -eq $RightIndex}) | Should-BeObject (ConvertFrom-Table '
				Country               Department  Name                 Manager
				-------               ----------  ----                 -------
				{Belgium, Germany}    Sales       {Aerts, Engineering} Meyer
				{Germany, England}    Engineering {Bauer, Marketing}   Morris
				{England, France}     Sales       {Cook, Sales}        Millet
				{France, Netherlands} Engineering {Duval, Board}       Mans
				`"England", $Null     Marketing   `"Evans", $Null      `$Null
				`"Germany", $Null     Engineering `"Fischer", $Null    `$Null')
		}
		
		It 'Self join with new propeties' {
			$Employees = ConvertFrom-Table '
				EmployeeId LastName  FirstName ReportsTo
				---------- --------  --------- ---------
				`1         Davolio   Nancy     `2
				`2         Fuller    Andrew
				`3         Leveling  Janet     `2
				`4         Peacock   Margaret  `2
				`5         Buchanan  Steven    `2
				`6         Suyama    Michael   `5
				`7         King      Robert    `5
				`8         Callahan  Laura     `2
				`9         Dodsworth Anne      `5'
				
			,($Employees | InnerJoin $Employees -On ReportsTo -Eq EmployeeID -Property @{Name = {"$($Left.FirstName) $($Left.LastName)"}; Manager = {"$($Right.FirstName) $($Right.LastName)"}}) | Should-BeObject (ConvertFrom-Table '
				Name             Manager
				----             -------
				Nancy Davolio    Andrew Fuller
				Janet Leveling   Andrew Fuller
				Margaret Peacock Andrew Fuller
				Steven Buchanan  Andrew Fuller
				Michael Suyama   Steven Buchanan
				Robert King      Steven Buchanan
				Laura Callahan   Andrew Fuller
				Anne Dodsworth   Steven Buchanan')
		}

	}

}

Exit



# Describe 'Join-Object' {
	
	# Context 'Basic inner join' {

		Compare-Object ($Employee | InnerJoin $Department Country) @(
				[PSCustomObject]@{
						'Country' = 'Germany'
						'Department' = 'Engineering'
						'Manager' = 'Meyer'
						'Name' = @(
								'Fischer',
								'Engineering'
						)
				},
				[PSCustomObject]@{
						'Country' = 'Germany'
						'Department' = 'Engineering'
						'Manager' = 'Meyer'
						'Name' = @(
								'Fischer',
								'Engineering'
						)
				},
				[PSCustomObject]@{
						'Country' = 'Germany'
						'Department' = 'Engineering'
						'Manager' = 'Meyer'
						'Name' = @(
								'Fischer',
								'Engineering'
						)
				},
				[PSCustomObject]@{
						'Country' = 'Germany'
						'Department' = 'Engineering'
						'Manager' = 'Meyer'
						'Name' = @(
								'Fischer',
								'Engineering'
						)
				},
				[PSCustomObject]@{
						'Country' = 'Germany'
						'Department' = 'Engineering'
						'Manager' = 'Meyer'
						'Name' = @(
								'Fischer',
								'Engineering'
						)
				}
		)
	# }
# }

Exit

# InnerJoin on Department = Name
$Employee | InnerJoin $Department Department -eq Name
# LeftJoin using country (excluding department.name)
$Employee | LeftJoin ($Department | Select Manager,Country) Country
# InnerJoin on Employee.Department = Department.Name and Employee.Country = Department.Country (returning only the left name and - country)
$Employee | InnerJoin $Department {$Left.Department -eq $Right.Name -and $Left.Country -eq $Right.Country} @{Name = {$Left.$_}; Country = {$Left.$_}}
# Cross Join
$Employee | InnerJoin $Department
