#Requires -Modules @{ModuleName="Pester"; ModuleVersion="4.4.0"}
Set-StrictMode -Version 2

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

. .\ConvertFrom-SourceTable.ps1			# https://www.powershellgallery.com/packages/ConvertFrom-SourceTable

Function Compare-PSObject([Object[]]$ReferenceObject, [Object[]]$DifferenceObject) {
	$Property = ($ReferenceObject  | Select-Object -First 1).PSObject.Properties + 
	            ($DifferenceObject | Select-Object -First 1).PSObject.Properties | Select-Object -Expand Name -Unique
				Compare-Object $ReferenceObject $DifferenceObject -Property $Property
}

Function ConvertTo-Array([String]$String, [String]$Pattern = '{,}') {
	$Open, $Split, $Close = Switch ($Pattern.Length) {
		0      	{$Null}
		1      	{$Null, $Pattern}
		2      	{$Pattern[0], $Pattern[1]}
		Default	{$Pattern[0], $Pattern.Substring(1, $Pattern.Length - 2), $Pattern[-1]}
	}
	&{
		If ($Split) {
			If ($Open) {
				If ($Close) {
					If ($String[0] -eq $Open -and $String[-1] -eq $Close) {
						$String.Substring(1, $String.Length - 2).Trim() -Split "\s*$Split\s*"
					} Else {$String}
				} ElseIf (Value[-1] -eq $Close) {
					$String.Substring(1).Trim() -Split "\s*$Split\s*"
				} Else {$String}
			} Else {$String -Split "\s*$Split\s*"}
		} Else {$String}
	} | ForEach-Object {If ($_ -eq '$null') {$Null} Else {$_}}
}; Set-Alias cta ConvertTo-Array

Describe 'Join-Object' {
	
	$Employee = ConvertFrom-SourceTable '
		Id Name    Country Department  Age ReportsTo
		-- ----    ------- ----------  --- ---------
		 1 Aerts   Belgium Sales        40         5
		 2 Bauer   Germany Engineering  31         4
		 3 Cook    England Sales        69         1
		 4 Duval   France  Engineering  21         5
		 5 Evans   England Marketing    35
		 6 Fischer Germany Engineering  29         4'


	$Department = ConvertFrom-SourceTable '
		Name        Country
		----        -------
		Engineering Germany
		Marketing   England
		Sales       France
		Purchase    France'

	Context 'Join types' {

		It '$Employee | InnerJoin $Department -On Country -Discern Employee, Department' {
			$Actual = $Employee | InnerJoin $Department -On Country -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1 Marketing
				 4 Duval        France  Engineering  21         5 Sales
				 4 Duval        France  Engineering  21         5 Purchase
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | InnerJoin $Department -On Department -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Sales          France
				 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
				 3 Cook         England         Sales        69         1 Sales          France
				 4 Duval        France          Engineering  21         5 Engineering    Germany
				 5 Evans        England         Marketing    35           Marketing      England
				 6 Fischer      Germany         Engineering  29         4 Engineering    Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | InnerJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | InnerJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 2 Bauer        Germany Engineering  31         4 Engineering
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | InnerJoin $Department -On Country' {
			$Actual = $Employee | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  3 {Cook, Marketing}      Sales        69         1
				France   4 {Duval, Sales}         Engineering  21         5
				France   4 {Duval, Purchase}      Engineering  21         5
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Country -Discern Employee, Department' {
			$Actual = $Employee | LeftJoin $Department -On Country -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 1 Aerts        Belgium Sales        40         5          $Null
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1 Marketing
				 4 Duval        France  Engineering  21         5 Sales
				 4 Duval        France  Engineering  21         5 Purchase
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Department -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | LeftJoin $Department -On Department -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Sales          France
				 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
				 3 Cook         England         Sales        69         1 Sales          France
				 4 Duval        France          Engineering  21         5 Engineering    Germany
				 5 Evans        England         Marketing    35           Marketing      England
				 6 Fischer      Germany         Engineering  29         4 Engineering    Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | LeftJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 1 Aerts        Belgium Sales        40         5          $Null
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1          $Null
				 4 Duval        France  Engineering  21         5          $Null
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Country' {
			$Actual = $Employee | LeftJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Belgium  1 {Aerts, $null}         Sales        40         5
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  3 {Cook, Marketing}      Sales        69         1
				France   4 {Duval, Sales}         Engineering  21         5
				France   4 {Duval, Purchase}      Engineering  21         5
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Country -Discern Employee, Department' {
			$Actual = $Employee | RightJoin $Department -On Country -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1 Marketing
				 4 Duval        France  Engineering  21         5 Sales
				 4 Duval        France  Engineering  21         5 Purchase
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Department -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | RightJoin $Department -On Department -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				   Id EmployeeName EmployeeCountry Department    Age ReportsTo DepartmentName DepartmentCountry
				   -- ------------ --------------- ----------    --- --------- -------------- -----------------
				    1 Aerts        Belgium         Sales          40         5 Sales          France
				    2 Bauer        Germany         Engineering    31         4 Engineering    Germany
				    3 Cook         England         Sales          69         1 Sales          France
				    4 Duval        France          Engineering    21         5 Engineering    Germany
				    5 Evans        England         Marketing      35           Marketing      England
				    6 Fischer      Germany         Engineering    29         4 Engineering    Germany
				$Null        $Null           $Null       $Null $Null     $Null Purchase       France'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | RightJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				   Id EmployeeName Country Department    Age ReportsTo DepartmentName
				   -- ------------ ------- ----------    --- --------- --------------
				    2 Bauer        Germany Engineering    31         4 Engineering
				    5 Evans        England Marketing      35           Marketing
				    6 Fischer      Germany Engineering    29         4 Engineering
				$Null        $Null France        $Null $Null     $Null Sales
				$Null        $Null France        $Null $Null     $Null Purchase'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Country' {
			$Actual = $Employee | RightJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  3 {Cook, Marketing}      Sales        69         1
				France   4 {Duval, Sales}         Engineering  21         5
				France   4 {Duval, Purchase}      Engineering  21         5
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Country -Discern Employee, Department' {
			$Actual = $Employee | FullJoin $Department -On Country -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 1 Aerts        Belgium Sales        40         5          $Null
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1 Marketing
				 4 Duval        France  Engineering  21         5 Sales
				 4 Duval        France  Engineering  21         5 Purchase
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Department -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | FullJoin $Department -On Department -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				   Id EmployeeName EmployeeCountry Department    Age ReportsTo DepartmentName DepartmentCountry
				   -- ------------ --------------- ----------    --- --------- -------------- -----------------
				    1 Aerts        Belgium         Sales          40         5 Sales          France
				    2 Bauer        Germany         Engineering    31         4 Engineering    Germany
				    3 Cook         England         Sales          69         1 Sales          France
				    4 Duval        France          Engineering    21         5 Engineering    Germany
				    5 Evans        England         Marketing      35           Marketing      England
				    6 Fischer      Germany         Engineering    29         4 Engineering    Germany
				$Null        $Null           $Null       $Null $Null     $Null Purchase       France'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Department, Country -Equals Name -Discern Employee, Department' {
			$Actual = $Employee | FullJoin $Department -On Department, Country -Equals Name -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				   Id EmployeeName    Country Department    Age ReportsTo DepartmentName
				   -- ------------    ------- ----------    --- --------- --------------
				    1 Aerts           Belgium Sales          40         5          $Null
				    2 Bauer           Germany Engineering    31         4 Engineering
				    3 Cook            England Sales          69         1          $Null
				    4 Duval           France  Engineering    21         5          $Null
				    5 Evans           England Marketing      35           Marketing
				    6 Fischer         Germany Engineering    29         4 Engineering
				$Null           $Null France        $Null $Null     $Null Sales
				$Null           $Null France        $Null $Null     $Null Purchase'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Country' {
			$Actual = $Employee | FullJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Belgium  1 {Aerts, $null}         Sales        40         5
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  3 {Cook, Marketing}      Sales        69         1
				France   4 {Duval, Sales}         Engineering  21         5
				France   4 {Duval, Purchase}      Engineering  21         5
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Country, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | CrossJoin $Department -Discern Employee, Department' {
			$Actual = $Employee | CrossJoin $Department -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
				 1 Aerts        Belgium         Sales        40         5 Marketing      England
				 1 Aerts        Belgium         Sales        40         5 Sales          France
				 1 Aerts        Belgium         Sales        40         5 Purchase       France
				 2 Bauer        Germany         Engineering  31         4 Engineering    Germany
				 2 Bauer        Germany         Engineering  31         4 Marketing      England
				 2 Bauer        Germany         Engineering  31         4 Sales          France
				 2 Bauer        Germany         Engineering  31         4 Purchase       France
				 3 Cook         England         Sales        69         1 Engineering    Germany
				 3 Cook         England         Sales        69         1 Marketing      England
				 3 Cook         England         Sales        69         1 Sales          France
				 3 Cook         England         Sales        69         1 Purchase       France
				 4 Duval        France          Engineering  21         5 Engineering    Germany
				 4 Duval        France          Engineering  21         5 Marketing      England
				 4 Duval        France          Engineering  21         5 Sales          France
				 4 Duval        France          Engineering  21         5 Purchase       France
				 5 Evans        England         Marketing    35           Engineering    Germany
				 5 Evans        England         Marketing    35           Marketing      England
				 5 Evans        England         Marketing    35           Sales          France
				 5 Evans        England         Marketing    35           Purchase       France
				 6 Fischer      Germany         Engineering  29         4 Engineering    Germany
				 6 Fischer      Germany         Engineering  29         4 Marketing      England
				 6 Fischer      Germany         Engineering  29         4 Sales          France
				 6 Fischer      Germany         Engineering  29         4 Purchase       France'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	$Changes = ConvertFrom-SourceTable '
		Id Name    Country Department  Age ReportsTo
		-- ----    ------- ----------  --- ---------
		 3 Cook    England Sales        69         5
		 6 Fischer France  Engineering  29         4
		 7 Geralds Belgium Sales        71         1'

		It '$Employee | Update $Changes -On Id' {
			$Actual = $Employee | Update $Changes -On Id
			$Expected = ConvertFrom-SourceTable '
				Id Name    Country Department  Age ReportsTo
				-- ----    ------- ----------  --- ---------
				 1 Aerts   Belgium Sales        40         5
				 2 Bauer   Germany Engineering  31         4
				 3 Cook    England Sales        69         5
				 4 Duval   France  Engineering  21         5
				 5 Evans   England Marketing    35
				 6 Fischer France  Engineering  29         4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | Merge $Changes -On Id' {
			$Actual = $Employee | Merge $Changes -On Id
			$Expected = ConvertFrom-SourceTable '
				Id Name    Country Department  Age ReportsTo
				-- ----    ------- ----------  --- ---------
				 1 Aerts   Belgium Sales        40         5
				 2 Bauer   Germany Engineering  31         4
				 3 Cook    England Sales        69         5
				 4 Duval   France  Engineering  21         5
				 5 Evans   England Marketing    35
				 6 Fischer France  Engineering  29         4
				 7 Geralds Belgium Sales        71         1'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	}
	
	Context 'Self join' {
	
		It 'LeftJoin $Employee -On ReportsTo -Equals Id -Discern *1,*2' {
			$Actual = LeftJoin $Employee -On ReportsTo -Equals Id -Discern *1,*2
			$Expected = ConvertFrom-SourceTable '
			Id1 Name1   Country1 Department1 Age1 ReportsTo1    Id2 Name2  Country2 Department2  Age2 ReportsTo2
			--- -----   -------- ----------- ---- ----------    --- ------ -------- ----------- ----- ----------
			  1 Aerts   Belgium  Sales         40          5      5 Evans  England  Marketing      35
			  2 Bauer   Germany  Engineering   31          4      4 Duval  France   Engineering    21          5
			  3 Cook    England  Sales         69          1      1 Aerts  Belgium  Sales          40          5
			  4 Duval   France   Engineering   21          5      5 Evans  England  Marketing      35
			  5 Evans   England  Marketing     35             $Null  $Null    $Null       $Null $Null      $Null
			  6 Fischer Germany  Engineering   29          4      4 Duval  France   Engineering    21          5'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'InnerJoin $Employee -On ReportsTo, Department -Equals Id -Discern *1,*2' {
			$Actual = InnerJoin $Employee -On ReportsTo, Department -Equals Id -Discern *1,*2
			$Expected = ConvertFrom-SourceTable '
				Id1 Name1   Country1 Department  Age1 ReportsTo1 Id2 Name2 Country2 Age2 ReportsTo2
				--- -----   -------- ----------  ---- ---------- --- ----- -------- ---- ----------
				  2 Bauer   Germany  Engineering   31          4   4 Duval France     21          5
				  3 Cook    England  Sales         69          1   1 Aerts Belgium    40          5
				  6 Fischer Germany  Engineering   29          4   4 Duval France     21          5'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left.Name}; Manager = {$Right.Name}}' {
			$Actual = LeftJoin $Employee -On ReportsTo -Equals Id -Property @{Name = {$Left.Name}; Manager = {$Right.Name}}
			$Expected = ConvertFrom-SourceTable '
				Manager Name
				------- ----
				Evans   Aerts
				Duval   Bauer
				Aerts   Cook
				Evans   Duval
				  $Null Evans
				Duval   Fischer'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}
	
	Context 'Join by index' {

		It '$Employee | InnerJoin $Department -Discern Employee, Department' {
			$Actual = $Employee | InnerJoin $Department -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
				 2 Bauer        Germany         Engineering  31         4 Marketing      England
				 3 Cook         England         Sales        69         1 Sales          France
				 4 Duval        France          Engineering  21         5 Purchase       France'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | LeftJoin $Department -Discern Employee, Department' {
			$Actual = $Employee | LeftJoin $Department -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
				 2 Bauer        Germany         Engineering  31         4 Marketing      England
				 3 Cook         England         Sales        69         1 Sales          France
				 4 Duval        France          Engineering  21         5 Purchase       France
				 5 Evans        England         Marketing    35                    $Null             $Null
				 6 Fischer      Germany         Engineering  29         4          $Null             $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Department | RightJoin $Employee -Discern Employee, Department' {				# Swapped $Department and $Employee
			$Actual = $Department | RightJoin $Employee -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				EmployeeName EmployeeCountry Id DepartmentName DepartmentCountry Department  Age ReportsTo
				------------ --------------- -- -------------- ----------------- ----------  --- ---------
				Engineering  Germany          1 Aerts          Belgium           Sales        40         5
				Marketing    England          2 Bauer          Germany           Engineering  31         4
				Sales        France           3 Cook           England           Sales        69         1
				Purchase     France           4 Duval          France            Engineering  21         5
				       $Null           $Null  5 Evans          England           Marketing    35
				       $Null           $Null  6 Fischer        Germany           Engineering  29         4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | FullJoin $Department -Discern Employee, Department' {
			$Actual = $Employee | FullJoin $Department -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName EmployeeCountry Department  Age ReportsTo DepartmentName DepartmentCountry
				-- ------------ --------------- ----------  --- --------- -------------- -----------------
				 1 Aerts        Belgium         Sales        40         5 Engineering    Germany
				 2 Bauer        Germany         Engineering  31         4 Marketing      England
				 3 Cook         England         Sales        69         1 Sales          France
				 4 Duval        France          Engineering  21         5 Purchase       France
				 5 Evans        England         Marketing    35                    $Null             $Null
				 6 Fischer      Germany         Engineering  29         4          $Null             $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Merge columns" {

		It 'Use the left object property if exists otherwise use right object property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Id Name    Country Department  Age ReportsTo
				-- ----    ------- ----------  --- ---------
				 1 Aerts   Belgium Sales        40         5
				 2 Bauer   Germany Engineering  31         4
				 3 Cook    England Sales        69         1
				 4 Duval   France  Engineering  21         5
				 5 Evans   England Marketing    35
				 6 Fischer Germany Engineering  29         4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Selected properties" {

		It 'Only use the left name property and the right manager property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property *, @{Name = {$Left.$_}; Country = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Country Name    Id Department  Age ReportsTo
				------- ----    -- ----------  --- ---------
				France  Aerts    1 Sales        40         5
				Germany Bauer    2 Engineering  31         4
				France  Cook     3 Sales        69         1
				Germany Duval    4 Engineering  21         5
				England Evans    5 Marketing    35
				Germany Fischer  6 Engineering  29         4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Only use the left name property and the right manager property (ordered selection)' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property Id, @{Name = {$Left.$_}}, Department, @{Country = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Id Name    Department  Country
				-- ----    ----------  -------
				 1 Aerts   Sales       France
				 2 Bauer   Engineering Germany
				 3 Cook    Sales       France
				 4 Duval   Engineering Germany
				 5 Evans   Marketing   England
				 6 Fischer Engineering Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Use the left object property except for the country property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property @{'*' = {$Left.$_}; Country = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Id Name    Country Department  Age ReportsTo
				-- ----    ------- ----------  --- ---------
				 1 Aerts   France  Sales        40         5
				 2 Bauer   Germany Engineering  31         4
				 3 Cook    France  Sales        69         1
				 4 Duval   Germany Engineering  21         5
				 5 Evans   England Marketing    35
				 6 Fischer Germany Engineering  29         4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Join using expression" {

		It '$Employee | Join $Department {$Left.Department -ne $Right.Name}' {
			$Actual = $Employee | Join $Department {$Left.Department -ne $Right.Name}
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country            Department  Age ReportsTo
				-- ----                 -------            ----------  --- ---------
				 1 {Aerts, Engineering} {Belgium, Germany} Sales        40         5
				 1 {Aerts, Marketing}   {Belgium, England} Sales        40         5
				 1 {Aerts, Purchase}    {Belgium, France}  Sales        40         5
				 2 {Bauer, Marketing}   {Germany, England} Engineering  31         4
				 2 {Bauer, Sales}       {Germany, France}  Engineering  31         4
				 2 {Bauer, Purchase}    {Germany, France}  Engineering  31         4
				 3 {Cook, Engineering}  {England, Germany} Sales        69         1
				 3 {Cook, Marketing}    {England, England} Sales        69         1
				 3 {Cook, Purchase}     {England, France}  Sales        69         1
				 4 {Duval, Marketing}   {France, England}  Engineering  21         5
				 4 {Duval, Sales}       {France, France}   Engineering  21         5
				 4 {Duval, Purchase}    {France, France}   Engineering  21         5
				 5 {Evans, Engineering} {England, Germany} Marketing    35
				 5 {Evans, Sales}       {England, France}  Marketing    35
				 5 {Evans, Purchase}    {England, France}  Marketing    35
				 6 {Fischer, Marketing} {Germany, England} Engineering  29         4
				 6 {Fischer, Sales}     {Germany, France}  Engineering  29         4
				 6 {Fischer, Purchase}  {Germany, France}  Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | Join $Department {$Left.Department -eq $Right.Name -and $Left.Country -ne $Right.Country}' {	# Recommended: $Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}
			$Actual = $Employee | Join $Department {$Left.Department -eq $Right.Name -and $Left.Country -ne $Right.Country}
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country           Department  Age ReportsTo
				-- ----                 -------           ----------  --- ---------
				 1 {Aerts, Sales}       {Belgium, France} Sales        40         5
				 3 {Cook, Sales}        {England, France} Sales        69         1
				 4 {Duval, Engineering} {France, Germany} Engineering  21         5
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	}

	Context "Where..." {

		It '$Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}' {
			$Actual = $Employee | Join $Department -On Department -Eq Name -Where {$Left.Country -ne $Right.Country}
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country           Department  Age ReportsTo
				-- ----                 -------           ----------  --- ---------
				 1 {Aerts, Sales}       {Belgium, France} Sales        40         5
				 3 {Cook, Sales}        {England, France} Sales        69         1
				 4 {Duval, Engineering} {France, Germany} Engineering  21         5
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | Join $Department -Where {$Left.Country -eq $Right.Country}' {		# On index where...
			$Actual = $Employee | Join $Department -Where {$Left.Country -eq $Right.Country}
			$Expected = ConvertFrom-SourceTable '
				Id Name              Country          Department  Age ReportsTo
				-- ----              -------          ----------  --- ---------
				 4 {Duval, Purchase} {France, France} Engineering  21         5
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	}
	
	Context "DataTables" {
	
		$DataTable1 = New-Object Data.DataTable
		$Null = $DataTable1.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
		$Null = $DataTable1.Columns.Add((New-Object Data.DataColumn 'Column2'), [Int])
		$DataRow = $DataTable1.NewRow()
		$DataRow.Item('Column1') = "A"
		$DataRow.Item('Column2') = 1
		$DataTable1.Rows.Add($DataRow)
		$DataRow = $DataTable1.NewRow()
		$DataRow.Item('Column1') = "B"
		$DataRow.Item('Column2') = 2
		$DataTable1.Rows.Add($DataRow)
		$DataRow = $DataTable1.NewRow()
		$DataRow.Item('Column1') = "C"
		$DataRow.Item('Column2') = 3
		$DataTable1.Rows.Add($DataRow)

		$DataTable2 = New-Object Data.DataTable
		$Null = $DataTable2.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
		$Null = $DataTable2.Columns.Add((New-Object Data.DataColumn 'Column3'), [Int])
		$DataRow = $DataTable2.NewRow()
		$DataRow.Item('Column1') = "B"
		$DataRow.Item('Column3') = 3
		$DataTable2.Rows.Add($DataRow)
		$DataRow = $DataTable2.NewRow()
		$DataRow.Item('Column1') = "C"
		$DataRow.Item('Column3') = 4
		$DataTable2.Rows.Add($DataRow)
		$DataRow = $DataTable2.NewRow()
		$DataRow.Item('Column1') = "D"
		$DataRow.Item('Column3') = 5
		$DataTable2.Rows.Add($DataRow)
		
		It '(inner)join DataTables' {
			$Actual = $DataTable1 | Join $DataTable2 -On Column1
			$Expected = ConvertFrom-SourceTable '
				Column1 Column2 Column3
				------- ------- -------
				B             2       3
				C             3       4
			'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Leftjoin DataTables' {
			$Actual = $DataTable1 | LeftJoin $DataTable2 -On Column1
			$Expected = ConvertFrom-SourceTable '
				Column1 Column2 Column3
				------- ------- -------
				A             1   $Null
				B             2       3
				C             3       4
			'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Rightjoin DataTables' {
			$Actual = $DataTable1 | RightJoin $DataTable2 -On Column1
			$Expected = ConvertFrom-SourceTable '
				Column1 Column2 Column3
				------- ------- -------
				B             2       3
				C             3       4
				D         $Null       5
			'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Fulljoin DataTables' {
			$Actual = $DataTable1 | FullJoin $DataTable2 -On Column1
			$Expected = ConvertFrom-SourceTable '
				Column1 Column2 Column3
				------- ------- -------
				A             1   $Null
				B             2       3
				C             3       4
				D         $Null       5
			'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Self join DataTable' {
			$Actual = Join $DataTable1 -On Column1 -Property {$Left.$_}
			$Expected = ConvertFrom-SourceTable '
				Column1 Column2
				------- -------
				A             1
				B             2
				C             3
			'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context 'Regression tests' {

		It 'Single left object' {
			$Actual = $Employee[1] | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
			Country Id Name                 Department  Age ReportsTo
			------- -- ----                 ----------  --- ---------
			Germany  2 {Bauer, Engineering} Engineering  31         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Single right object' {
			$Actual = $Employee | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Single left object and single right object' {
			$Actual = $Employee[1] | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                 Department  Age ReportsTo
				------- -- ----                 ----------  --- ---------
				Germany  2 {Bauer, Engineering} Engineering  31         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context 'Compare options' {

		$LeftObject = ConvertFrom-SourceTable '
			volume                                  vol-state lun-serial
			------                                  --------- ----------
			cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH
			cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh'

		$RightObject = ConvertFrom-SourceTable '
			lun-serial   host-DiskNumber host-OperationalStatus
			----------   --------------- ----------------------
			QvaAo+E56ZNH 11              Online
			QvaAo+E56ZNh 34              Offline'

		It 'case insensitive (default)' {

			$Actual = $LeftObject | LeftJoin $RightObject -On lun-serial
			$Expected = ConvertFrom-SourceTable '
				volume                                  vol-state lun-serial   host-DiskNumber host-OperationalStatus
				------                                  --------- ----------   --------------- ----------------------
				cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH 11              Online
				cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNh 34              Offline
				cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNH 11              Online
				cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh 34              Offline'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'case sensitive' {

			$Actual = $LeftObject | LeftJoin $RightObject -On lun-serial -CaseSensitive
			$Expected = ConvertFrom-SourceTable '
				volume                                  vol-state lun-serial   host-DiskNumber host-OperationalStatus
				------                                  --------- ----------   --------------- ----------------------
				cl_Cedar_WithAcessPath_SQL_T03_3        online    QvaAo+E56ZNH 11              Online
				cl_ExportMasterDB_Max_to_Dell_SQL_T03_2 online    QvaAo+E56ZNh 34              Offline'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		$Object =
			[pscustomobject]@{'Name' = 'Null'; 'Value' = $Null},
			[pscustomobject]@{'Name' = 'String'; 'Value' = ''},
			[pscustomobject]@{'Name' = 'abc'; 'Value' = 'abc'},
			[pscustomobject]@{'Name' = 'Zero'; 'Value' = 0},
			[pscustomobject]@{'Name' = 'One'; 'Value' = 1},
			[pscustomobject]@{'Name' = 'Empty'; 'Value' = @()},
			[pscustomobject]@{'Name' = 'Array'; 'Value' = @(0,1,2)}


		It 'Default Join with null, zero, empty, etc.' {

			$Actual = InnerJoin $Object -On Value Left,Right -Where {$LeftIndex -ne $RightIndex}
			$Expected = 
				[pscustomobject]@{'LeftName' = 'Null'; 'Value' = $Null; 'RightName' = 'String'},
				[pscustomobject]@{'LeftName' = 'Null'; 'Value' = $Null; 'RightName' = 'Empty'},
				[pscustomobject]@{'LeftName' = 'String'; 'Value' = ''; 'RightName' = 'Null'},
				[pscustomobject]@{'LeftName' = 'String'; 'Value' = ''; 'RightName' = 'Empty'},
				[pscustomobject]@{'LeftName' = 'Empty'; 'Value' = $Null; 'RightName' = 'Null'},
				[pscustomobject]@{'LeftName' = 'Empty'; 'Value' = $Null; 'RightName' = 'String'}

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Strict Join with null, zero, empty, etc.' {

			$Actual = InnerJoin $Object -Strict -On Value Left,Right -Where {$LeftIndex -ne $RightIndex}
			$Expected = 
				[pscustomobject]@{'LeftName' = 'Null'; 'Value' = $Null; 'RightName' = 'Empty'},
				[pscustomobject]@{'LeftName' = 'Empty'; 'Value' = $Null; 'RightName' = 'Null'}

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Stackoverflow answers" {

		It "In Powershell, what's the best way to join two tables into one?" { # https://stackoverflow.com/a/45483110/1701026

			$leases = ConvertFrom-SourceTable '
				IP                    Name
				--                    ----
				192.168.1.1           Apple
				192.168.1.2           Pear
				192.168.1.3           Banana
				192.168.1.99          FishyPC'

			$reservations = ConvertFrom-SourceTable '
				IP                    MAC
				--                    ---
				192.168.1.1           001D606839C2
				192.168.1.2           00E018782BE1
				192.168.1.3           0022192AF09C
				192.168.1.4           0013D4352A0D'

			$Actual = $reservations | LeftJoin $leases -On IP
			$Expected = ConvertFrom-SourceTable '
				IP          MAC          Name
				--          ---          ----
				192.168.1.1 001D606839C2 Apple
				192.168.1.2 00E018782BE1 Pear
				192.168.1.3 0022192AF09C Banana
				192.168.1.4 0013D4352A0D  $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	

		It 'Combining Multiple CSV Files' { # https://stackoverflow.com/a/54855458/1701026
			$CSV1 = ConvertFrom-Csv @'
Name,Attrib1,Attrib2
VM1,111,True
VM2,222,False
'@

			$CSV2 = ConvertFrom-Csv @'
Name,AttribA,Attrib1
VM1,AAA,111
VM3,CCC,333
'@

			$CSV3 = ConvertFrom-Csv @'
Name,Attrib2,AttribB
VM2,False,YYY
VM3,True,ZZZ
'@

			$Actual = $CSV1 | Merge $CSV2 -On Name | Merge $CSV3 -On Name
			$Expected = ConvertFrom-SourceTable '
			Name Attrib1 Attrib2 AttribA AttribB
			---- ------- ------- ------- -------
			VM1  111     True    AAA       $Null
			VM2  222     False     $Null YYY
			VM3  333     True    CCC     ZZZ'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'Combine two CSVs - Add CSV as another Column' { # https://stackoverflow.com/a/55431240/1701026
			$csv1 = ConvertFrom-Csv @'
VLAN
1
2
3
'@

			$csv2 = ConvertFrom-Csv @'
Host
NETMAN
ADMIN
CLIENT
'@


			$Actual = $csv1 | Join $csv2
			$Expected = ConvertFrom-SourceTable '
				VLAN Host
				---- ----
				1    NETMAN
				2    ADMIN
				3    CLIENT'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}		
		
		It 'CMD or Powershell command to combine (merge) corresponding lines from two files' { # https://stackoverflow.com/a/54607741/1701026

			$A = ConvertFrom-Csv @'
ID,Name
1,Peter
2,Dalas
'@

			$B = ConvertFrom-Csv @'
Class
Math
Physic
'@

			$Actual = $A | Join $B
			$Expected = ConvertFrom-SourceTable '
				ID Name  Class
				-- ----  -----
				1  Peter Math
				2  Dalas Physic'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	
		
		It 'Can I use SQL commands (such as join) on objects in powershell, without any SQL server/database involved?' { # https://stackoverflow.com/a/55431393/1701026

		}	
		
		It 'CMD or Powershell command to combine (merge) corresponding lines from two files' { # https://stackoverflow.com/a/54855647/1701026

			$Purchase = ConvertFrom-Csv @'
Fruit,Farmer,Region,Water
Apple,Adam,Alabama,1
Cherry,Charlie,Cincinnati,2
Damson,Daniel,Derby,3
Elderberry,Emma,Eastbourne,4
Fig,Freda,Florida,5
'@

			$Selling = ConvertFrom-Csv @'
Fruit,Market,Cost,Tax
Apple,MarketA,10,0.1
Cherry,MarketC,20,0.2
Damson,MarketD,30,0.3
Elderberry,MarketE,40,0.4
Fig,MarketF,50,0.5
'@

			$Actual = $Purchase | Join $Selling -On Fruit
			$Expected = ConvertFrom-SourceTable '
				Fruit      Farmer  Region     Water Market  Cost Tax
				-----      ------  ------     ----- ------  ---- ---
				Apple      Adam    Alabama    1     MarketA 10   0.1
				Cherry     Charlie Cincinnati 2     MarketC 20   0.2
				Damson     Daniel  Derby      3     MarketD 30   0.3
				Elderberry Emma    Eastbourne 4     MarketE 40   0.4
				Fig        Freda   Florida    5     MarketF 50   0.5'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	
		
		It 'Compare Two CSVs, match the columns on 2 or more Columns, export specific columns from both csvs with powershell' { # https://stackoverflow.com/a/52235645/1701026

			$Left = ConvertFrom-Csv @"
Ref_ID,First_Name,Last_Name,DOB
321364060,User1,Micah,11/01/1969
946497594,User2,Acker,05/28/1960
887327716,User3,Aco,06/26/1950
588496260,User4,John,05/23/1960
565465465,User5,Jack,07/08/2020
"@

			$Right = ConvertFrom-Csv @"
First_Name,Last_Name,DOB,City,Document_Type,Filename
User1,Micah,11/01/1969,Parker,Transcript,T4IJZSYO.pdf
User2,Acker,05/28/1960,,Transcript,R4IKTRYN.pdf
User3,Aco,06/26/1950,,Transcript,R4IKTHMK.pdf
User4,John,05/23/1960,,Letter,R4IKTHSL.pdf
"@

			$Actual = $Left | Join $Right -On First_Name, Last_Name, DOB -Property Ref_ID, Filename, First_Name, DOB, Last_Name
			$Expected = ConvertFrom-SourceTable '
				Ref_ID    Filename     First_Name DOB        Last_Name
				------    --------     ---------- ---        ---------
				321364060 T4IJZSYO.pdf User1      11/01/1969 Micah
				946497594 R4IKTRYN.pdf User2      05/28/1960 Acker
				887327716 R4IKTHMK.pdf User3      06/26/1950 Aco
				588496260 R4IKTHSL.pdf User4      05/23/1960 John'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	
		
		It 'Merge two CSV files while adding new and overwriting existing entries' { # https://stackoverflow.com/a/54949056/1701026

				$configuration = ConvertFrom-SourceTable '
				| path       | item  | value  | type |
				|------------|-------|--------|------|
				| some/path  | item1 | value1 | ALL  |
				| some/path  | item2 | UPDATE | ALL  |
				| other/path | item1 | value2 | SOME |'

				$customization= ConvertFrom-SourceTable '
				| path       | item  | value  | type |
				|------------|-------|--------|------|
				| some/path  | item2 | value3 | ALL  |
				| new/path   | item3 | value3 | SOME |'

			$Actual = $configuration | Merge $customization -on path, item
			$Expected = ConvertFrom-SourceTable '
				path       item  value  type
				----       ----  -----  ----
				some/path  item1 value1 ALL
				some/path  item2 value3 ALL
				other/path item1 value2 SOME
				new/path   item3 value3 SOME'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	
	
		It 'Merging two CSVs and then re-ordering columns on output' { # https://stackoverflow.com/a/54981257/1701026

			$Csv1 = ConvertFrom-Csv 'Server,Info
server1,item1
server1,item1'

			$Csv2 = ConvertFrom-Csv 'Server,Info
server2,item2
server2,item2'

			$Actual = $Csv1 | Join $Csv2 -Discern *1, *2
			$Expected = ConvertFrom-SourceTable '
				Server1 Server2 Info1 Info2
				------- ------- ----- -----
				server1 server2 item1 item2
				server1 server2 item1 item2'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	

		It 'Comparing two CSVs using one property to compare another' { # https://stackoverflow.com/q/55602662/1701026
		
$file1='"FACILITY","FILENAME"
"16","abc.txt"
"16","def.txt"
"12","abc.txt"
"17","def.txt"
"18","abc.txt"
"19","abc.txt"'|convertfrom-csv

$file2='"FACILITY","FILENAME"
"16","jkl.txt"
"16","abc.txt"
"12","abc.txt"
"17","jkl.txt"
"18","jkl.txt"
"19","jkl.txt"'|convertfrom-csv


			$Actual = $file1 | Join $file2 -On Facility, Filename
			$Expected = ConvertFrom-SourceTable '
				FACILITY FILENAME
				-------- --------
				16       abc.txt
				12       abc.txt
			'
			Compare-PSObject $Actual $Expected | Should -BeNull

		}

		It 'Merge two CSV files while adding new and overwriting existing entries' { # https://stackoverflow.com/a/54949056/1701026
		
			$configuration = ConvertFrom-SourceTable '
				| path       | item  | value  | type |
				|------------|-------|--------|------|
				| some/path  | item1 | value1 | ALL  |
				| some/path  | item2 | UPDATE | ALL  |
				| other/path | item1 | value2 | SOME |
				| other/path | item1 | value3 | ALL  |
			'
			$customization= ConvertFrom-SourceTable '
				| path       | item  | value  | type |
				|------------|-------|--------|------|
				| some/path  | item2 | value3 | ALL  |
				| new/path   | item3 | value3 | SOME |
				| new/path   | item3 | value4 | ALL  |
			'

			$Actual = $configuration | Merge $customization -on path, item
			$Expected = ConvertFrom-SourceTable '
				path       item  value  type
				----       ----  -----  ----
				some/path  item1 value1 ALL
				some/path  item2 value3 ALL
				other/path item1 value2 SOME
				other/path item1 value3 ALL
				new/path   item3 value3 SOME
				new/path   item3 value4 ALL
			'
			Compare-PSObject $Actual $Expected | Should -BeNull

		}

		It 'Efficiently merge large object datasets having mulitple matching keys' { # https://stackoverflow.com/a/55543321/1701026

			$dataset1 = ConvertFrom-SourceTable '
				A B    XY    ZY  
				- -    --    --  
				1 val1 foo1  bar1
				2 val2 foo2  bar2
				3 val3 foo3  bar3
				4 val4 foo4  bar4
				4 val4 foo4a bar4a
				5 val5 foo5  bar5
				6 val6 foo6  bar6
			'
			$dataset2 = ConvertFrom-SourceTable '
				A B    ABC   GH  
				- -    ---   --  
				3 val3 foo3  bar3
				4 val4 foo4  bar4
				5 val5 foo5  bar5
				5 val5 foo5a bar5a
				6 val6 foo6  bar6
				7 val7 foo7  bar7
				8 val8 foo8  bar8
			'

			$Actual = $Dataset1 | FullJoin $dataset2 -On A, B
			$Expected = ConvertFrom-SourceTable '
				A B    XY      ZY      ABC    GH
				- -    --      --      ---    --
				1 val1 foo1    bar1     $Null  $Null
				2 val2 foo2    bar2     $Null  $Null
				3 val3 foo3    bar3    foo3   bar3
				4 val4 foo4    bar4    foo4   bar4
				4 val4 foo4a   bar4a   foo4   bar4
				5 val5 foo5    bar5    foo5   bar5
				5 val5 foo5    bar5    foo5a  bar5a
				6 val6 foo6    bar6    foo6   bar6
				7 val7  $Null   $Null  foo7   bar7
				8 val8  $Null   $Null  foo8   bar8
			'
			Compare-PSObject $Actual $Expected | Should -BeNull

			$dsLength = 1000
			$dataset1 = 0..$dsLength | %{
				New-Object psobject -Property @{ A=$_ ; B="val$_" ; XY = "foo$_"; ZY ="bar$_" }
			}
			$dataset2 = ($dsLength/2)..($dsLength*1.5) | %{
				New-Object psobject -Property @{ A=$_ ; B="val$_" ; ABC = "foo$_"; GH ="bar$_" }
			}
			
			(Measure-Command {$dataset1| FullJoin $dataset2 -On A, B}).TotalSeconds | Should -BeLessThan 10
		}	

		It 'PowerShell list combinator - optimize please' { # https://stackoverflow.com/a/57832299/1701026
		
$list1 = ConvertFrom-Csv -Delimiter ';' @'
server
hostname1
hostname2
hostname3
hostname4
hostname5
hostname6
hostname7
'@

$ADscan = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname2;Microsoft Windows Server 2012 R2 Datacenter
hostname3;Microsoft Windows Server 2008 R2 Standard
'@

$export2 = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname1;w2k12
hostname2;w2k12
hostname3;w2k8
hostname4;w2k8
hostname5;w2k16
'@

$export3 = ConvertFrom-Csv -Delimiter ';' @'
server;OS
hostname2.suffix;windows server 2012
hostname3.suffix;windows server 2008
hostname6.suffix;windows server 2008
'@

$Actual = $List1 |
	Merge $ADScan -On Server |
	Merge $export2 -On Server |
	Merge ($export3 | Select-Object @{n='Server';e={$_.Server.Split('.', 2)[0]}}, OS) -On Server

			$Expected = ConvertFrom-SourceTable '
				server    OS
				------    --
				hostname1 w2k12
				hostname2 windows server 2012
				hostname3 windows server 2008
				hostname4 w2k8
				hostname5 w2k16
				hostname6 windows server 2008
				hostname7               $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull


$Actual = $List1 |
	Merge $ADScan -On Server |
	Merge $export2 -On Server -Discern '',Export2 |
	Merge ($export3 | Select-Object @{n='Server';e={$_.Server.Split('.', 2)[0]}}, OS) -On Server -Discern '',Export3

			$Expected = ConvertFrom-SourceTable '
server    OS                                          Export2OS Export3OS
------    ------------------------------------------- --------- -------------------
hostname1                                       $Null w2k12                   $Null
hostname2 Microsoft Windows Server 2012 R2 Datacenter w2k12     windows server 2012
hostname3 Microsoft Windows Server 2008 R2 Standard   w2k8      windows server 2008
hostname4                                       $Null w2k8                    $Null
hostname5                                       $Null w2k16                   $Null
hostname6                                       $Null     $Null windows server 2008
hostname7                                       $Null     $Null               $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull

		}
		
		It 'Which operator provides quicker output -match -contains or Where-Object for large CSV files' { # https://stackoverflow.com/a/58474740/1701026
		
$AAA = ConvertFrom-Csv @'
Number,Name,Domain
Z001,ABC,Domain1
Z002,DEF,Domain2
Z003,GHI,Domain3
'@

$BBB = ConvertFrom-Csv @'
Number,Name,Domain
Z001,ABC,Domain1
Z002,JKL,Domain2
Z004,MNO,Domain4
'@

$CCC = ConvertFrom-Csv @'
Number,Name,Domain
Z005,PQR,Domain2
Z001,ABC,Domain1
Z001,STU,Domain2
'@

$DDD = ConvertFrom-Csv @'
Number,Name,Domain
Z005,VWX,Domain4
Z006,XYZ,Domain1
Z001,ABC,Domain3
'@

			$Expected = ConvertFrom-SourceTable '
				Number AAAName AAADomain BBBName BBBDomain CCCName CCCDomain DDDName DDDDomain
				------ ------- --------- ------- --------- ------- --------- ------- ---------
				Z001   ABC     Domain1   ABC     Domain1   ABC     Domain1   ABC     Domain3
				Z001   ABC     Domain1   ABC     Domain1   STU     Domain2   ABC     Domain3
				Z002   DEF     Domain2   JKL     Domain2     $Null     $Null   $Null     $Null
				Z003   GHI     Domain3     $Null     $Null   $Null     $Null   $Null     $Null
				Z004     $Null     $Null MNO     Domain4     $Null     $Null   $Null     $Null
				Z005     $Null     $Null   $Null     $Null PQR     Domain2   VWX     Domain4
				Z006     $Null     $Null   $Null     $Null   $Null     $Null XYZ     Domain1'

			$Actual = $AAA | FullJoin $BBB -On Number -Discern AAA |
				FullJoin $CCC -On Number -Discern BBB |
				FullJoin $DDD -On Number -Discern CCC,DDD
				
			Compare-PSObject $Actual $Expected | Should -BeNull

			$Actual = $AAA | FullJoin $BBB Number AAA |
				FullJoin $CCC Number BBB |
				FullJoin $DDD Number CCC,DDD
				
			Compare-PSObject $Actual $Expected | Should -BeNull
			
			$Expected = ConvertFrom-SourceTable '
				Number Name1   Domain1   Name2   Domain2   Name3   Domain3   Name4   Domain4
				------ ------- --------- ------- --------- ------- --------- ------- ---------
				Z001   ABC     Domain1   ABC     Domain1   ABC     Domain1   ABC     Domain3
				Z001   ABC     Domain1   ABC     Domain1   STU     Domain2   ABC     Domain3
				Z002   DEF     Domain2   JKL     Domain2     $Null     $Null   $Null     $Null
				Z003   GHI     Domain3     $Null     $Null   $Null     $Null   $Null     $Null
				Z004     $Null     $Null MNO     Domain4     $Null     $Null   $Null     $Null
				Z005     $Null     $Null   $Null     $Null PQR     Domain2   VWX     Domain4
				Z006     $Null     $Null   $Null     $Null   $Null     $Null XYZ     Domain1'

				
			$Actual = $AAA | FullJoin $BBB Number *1 |
				FullJoin $CCC Number *2 |
				FullJoin $DDD Number *3,*4
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Powershell "join"' { # https://stackoverflow.com/a/58800704/1701026
			$cpu = Get-CimInstance -Class Win32_Processor 
			$mb = Get-CimInstance -Class Win32_BaseBoard
			
			$Actual = $cpu | Select-Object Name, Description | Join-Object ($mb | Select-Object Manufacturer, Product)
			
			$Actual.Name         | Should -Be $cpu.Name
			$Actual.Description  | Should -Be $cpu.Description
			$Actual.Manufacturer | Should -Be $mb.Manufacturer
			$Actual.Product      | Should -Be $mb.Product
		}

		It 'Join/merge arrays' { # https://stackoverflow.com/a/58801439/1701026
			$TxtTestcases = ConvertFrom-SourceTable '
				Messages                                   Name   Error
				--------                                   ----   -----
				{\\APPS-EUAUTO1\C$\Users\xautosqa\AppDa... test 1 True
				{[APPS-EUAUTO1] [prep] Setting agent op... test 2 False'

			$RexTestcases = ConvertFrom-SourceTable '
				TestPlan        Script          TestCase        TestData        ErrorCount      ErrorText       DateTime        Elapsed        
				--------        ------          --------        --------        ----------      ---------       --------        -------        
				D:\XHostMach... D:\XHostMach... rt1             1,\a\""         1               [#ERROR#][AP... 2014-03-28 1... 0:00:18        
				D:\XHostMach... D:\XHostMach... rt2             1,\a\""         0                               2014-03-28 1... 0:00:08 '
				
			$Actual = $TxtTestcases | Join-Object $RexTestcases
			$Expected = ConvertFrom-SourceTable '
				Messages                                   Name   Error TestPlan        Script          TestCase TestData ErrorCount ErrorText       DateTime   Elapsed
				--------                                   ----   ----- --------        ------          -------- -------- ---------- ---------       --------   -------
				{\\APPS-EUAUTO1\C$\Users\xautosqa\AppDa... test 1 True  D:\XHostMach... D:\XHostMach... rt1      1,\a\""  1          [#ERROR#][AP... 2014-03-28 0:00:18
				{[APPS-EUAUTO1] [prep] Setting agent op... test 2 False D:\XHostMach... D:\XHostMach... rt2      1,\a\""  0                          2014-03-28 0:00:08'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Compare two different csv files using PowerShell' { # https://stackoverflow.com/a/58855413/1701026
		
			$Csv2 = ConvertFrom-Csv @'
Client Name,Policy Name,KB Size
hostname1,Company_Policy,487402463
hostname2,Company_Policy,227850336
hostname3,Company_Policy_11,8360960
hostname4,Company_Policy_11,1238838488
hostname1,Company_Policy_55,521423110
hostname10,Company_Policy,28508975
hostname3,Company_Policy_66,295925
hostname5,Company_Policy_22,82001824
hostname2,Company_Policy_33,26176885
hostnameXX,Company_Policy_XXX,0
hostnameXX,Company_Policy_XXX,41806794
hostnameYY,Company_Policy_XXX,41806794
'@

			$Csv1 = ConvertFrom-Csv @'
Client Name,Policy Name,KB Size
hostname1,Company_Policy,487402555
hostname2,Company_Policy,227850666
hostname3,Company_Policy_11,8361200
hostname4,Company_Policy_11,1638838488
hostname1,Company_Policy_55,621423110
hostname10,Company_Policy,28908975
hostname3,Company_Policy_66,295928
hostname5,Company_Policy_22,92001824
hostname2,Company_Policy_33,36176885
hostname22,Company_Policy,291768854
hostname23,Company_Policy,291768854
'@

			$Actual = $CSV2 | FullJoin $CSV1 `
				-On 'Client Name','Policy Name' `
				-Property 'Client Name',
						  'Policy Name', 
						  @{'TB Size' = {[math]::Round(($Left.'KB Size' - $Right.'KB Size') / 1GB, 2)}} `
				-Where {[math]::Abs($Left.'KB Size' - $Right.'KB Size') -gt 100MB}
					
			$Expected = ConvertFrom-SourceTable '
					Client Name Policy Name       TB Size
					----------- -----------       -------
					hostname1   Company_Policy       0.45
					hostname2   Company_Policy       0.21
					hostname4   Company_Policy_11   -0.37
					hostname1   Company_Policy_55    0.49
					hostname1   Company_Policy      -0.45
					hostname2   Company_Policy      -0.21
					hostname1   Company_Policy_55   -0.58
					hostname22  Company_Policy      -0.27
					hostname23  Company_Policy      -0.27'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'multiple lookup powershell array' { # https://stackoverflow.com/a/58880814/1701026
		
			$List = ConvertFrom-SourceTable '
				org_id  org_name        parent_id
				1       Company         NULL
				2       HR              1
				3       MARKETING       2
				4       FINANCE         1
				5       IT              4'

			$Actual = FullJoin $List parent_id -eq org_id '', 'parent'
			$Expected = ConvertFrom-SourceTable '
				org_id org_name  parent_id parentorg_id parentorg_name parentparent_id
				------ --------  --------- ------------ -------------- ---------------
				1      Company   NULL             $Null          $Null           $Null 
				2      HR        1         1            Company        NULL
				3      MARKETING 2         2            HR             1
				4      FINANCE   1         1            Company        NULL
				5      IT        4         4            FINANCE        1
				 $Null     $Null     $Null 3            MARKETING      2
				 $Null     $Null     $Null 5            IT             4'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Merge two json objects' { # https://stackoverflow.com/a/45563467/1701026
		
			$Json1 = ConvertFrom-Json '
				{
				  a:{
				    b:"asda"
				  },
				  c:"asdasd"
				}'

			$Json2 = ConvertFrom-Json '
				{
				  a:{
				   b:"d"
				  }
				}'
				
			$Actual = $Json1 | Merge $Json2
			$Expected = ConvertFrom-Json '
				{
				  "a": {
					"b": "d"
				  },
				  "c": "asdasd"
				}'

			Compare-PSObject $Actual $Expected | Should -BeNull

			$Actual = $Json1 | Join $Json2
			$Expected = ConvertFrom-Json '
				{
				  "a": [
					{
					  "b": "asda"
					},
					{
					  "b": "d"
					}
				  ],
				  "c": "asdasd"
				}'
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Combine JSON objects in PowerShell' { # https://stackoverflow.com/q/57724976/1701026
		
			$aVar = '{ "oldEmployees" : [ { "firstName": "Jane", "lastName": "Doe" }, { "firstName": "John", "lastName": "Doe" } ] }'
			$bVar = '{ "newEmployees" : [ { "firstName": "Joe", "lastName": "Doe" } ] }'


			$Actual = ($aVar | ConvertFrom-Json) | Join ($bVar | ConvertFrom-Json)
			$Expected = ConvertFrom-Json '
				{
				  "oldEmployees": [
					{
					  "firstName": "Jane",
					  "lastName": "Doe"
					},
					{
					  "firstName": "John",
					  "lastName": "Doe"
					}
				  ],
				  "newEmployees": {
					"firstName": "Joe",
					"lastName": "Doe"
				  }
				}'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'Match on two columns in two separate csvs then merge one column' { # https://stackoverflow.com/q/39733868/1701026
		
$Source = ConvertFrom-Csv @'
"Employee ID","username","givenname","surname","emailaddress","title","Division","Location"
"204264","ABDUL.JALIL@domain.com","Abdul Jalil","Bin Hajar","Abdul.jalil@domain.com","Warehouse Associate I","Singapore","Singapore, "
"30053","ABEL.BARRAGAN@domain.com","Abel","Barragan","Abel.Barragan@domain.com","Manager, Customer Programs - CMS","Germany","Norderstedt, "
'@

$Change = ConvertFrom-Csv @'
givenname,surname,samaccountname,emailaddress,mail,country,city,state
Abigai,Teoyotl Rugerio,Abigai.Teoyotl,Abigai.TeoyotlRugerio@domain.com,Abigai.TeoyotlRugerio@domain.com,MX,,
Adekunle,Adesiyan,Adekunle.Adesiyan,Adekunle.Adesiyan@domain.com,Adekunle.Adesiyan@domain.com,US,VALENCIA,CALIFORNIA
'@

			# (some) Property do not show issue !!!
			$Source | Update-Object $Change givenname,surname

		}
	}
		
	Context "Github issues" {
		It 'HashTables for input' { # https://github.com/iRon7/Join-Object/issues/10
		
			$hostNumaInfo = @{
				TypeId            = 0
				CpuID             = 11, 10, 9, 8
				MemoryRangeBegin  = 0
				MemoryRangeLength = 34259832832
				PciId             = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
			}

			$hostPciInfo = @{
				Id           = '0000:00:00.0'
				ClassId      = 1536
				Bus          = 0
				Slot         = 0
				Function     = 0
				VendorId     = -32634
				SubVendorId  = -32634
				VendorName   = 'Intel Corporation'
				DeviceId     = 12032
				SubDeviceId  = 0
				ParentBridge = ''
				DeviceName   = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
			}
			
			$Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On PciId -Equals Id
			$Actual | Should -BeNullOrEmpty
			$Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On TypeId -Equals Bus
			$Expected = [pscustomobject]@{
					'TypeId' = 0
					'CpuID' = 11, 10, 9, 8
					'PciId' = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
					'MemoryRangeLength' = 34259832832
					'MemoryRangeBegin' = 0
					'DeviceId' = 12032
					'VendorName' = 'Intel Corporation'
					'Bus' = 0
					'Id' = '0000:00:00.0'
					'ParentBridge' = ''
					'Slot' = 0
					'DeviceName' = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
					'VendorId' = -32634
					'Function' = 0
					'SubDeviceId' = 0
					'ClassId' = 1536
					'SubVendorId' = -32634
			}
			Compare-PSObject $Actual $Expected | Should -BeNull



		}
		
		It 'FullJoin on hashtables' {
		
			$Employee =
				@{'Id' = 1; 'Name' = 'Aerts'; 'Country' = 'Belgium'; 'Department' = 'Sales'; 'Age' = 40; 'ReportsTo' = 5},
				@{'Id' = 2; 'Name' = 'Bauer'; 'Country' = 'Germany'; 'Department' = 'Engineering'; 'Age' = 31; 'ReportsTo' = 4},
				@{'Id' = 3; 'Name' = 'Cook'; 'Country' = 'England'; 'Department' = 'Sales'; 'Age' = 69; 'ReportsTo' = 1},
				@{'Id' = 4; 'Name' = 'Duval'; 'Country' = 'France'; 'Department' = 'Engineering'; 'Age' = 21; 'ReportsTo' = 5},
				@{'Id' = 5; 'Name' = 'Evans'; 'Country' = 'England'; 'Department' = 'Marketing'; 'Age' = 35; 'ReportsTo' = ''},
				@{'Id' = 6; 'Name' = 'Fischer'; 'Country' = 'Germany'; 'Department' = 'Engineering'; 'Age' = 29; 'ReportsTo' = 4}
				
			$Department =
				@{'Name' = 'Engineering'; 'Country' = 'Germany'},
				@{'Name' = 'Marketing'; 'Country' = 'England'},
				@{'Name' = 'Sales'; 'Country' = 'France'},
				@{'Name' = 'Purchase'; 'Country' = 'France'}

			$Actual = $Employee | FullJoin $Department -On Country -Discern Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName Country Department  Age ReportsTo DepartmentName
				-- ------------ ------- ----------  --- --------- --------------
				 1 Aerts        Belgium Sales        40         5          $Null
				 2 Bauer        Germany Engineering  31         4 Engineering
				 3 Cook         England Sales        69         1 Marketing
				 4 Duval        France  Engineering  21         5 Sales
				 4 Duval        France  Engineering  21         5 Purchase
				 5 Evans        England Marketing    35           Marketing
				 6 Fischer      Germany Engineering  29         4 Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'Ordered for input' { # https://github.com/iRon7/Join-Object/issues/10
		
			$hostNumaInfo = [Ordered]@{
				TypeId            = 0
				CpuID             = 11, 10, 9, 8
				MemoryRangeBegin  = 0
				MemoryRangeLength = 34259832832
				PciId             = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
			}

			$hostPciInfo = [Ordered]@{
				Id           = '0000:00:00.0'
				ClassId      = 1536
				Bus          = 0
				Slot         = 0
				Function     = 0
				VendorId     = -32634
				SubVendorId  = -32634
				VendorName   = 'Intel Corporation'
				DeviceId     = 12032
				SubDeviceId  = 0
				ParentBridge = ''
				DeviceName   = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
			}
			
			$Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On PciId -Equals Id
			$Actual | Should -BeNullOrEmpty
			$Actual = $hostNumaInfo | InnerJoin-Object $hostPciInfo -On TypeId -Equals Bus
			$Expected = [pscustomobject]@{
					'TypeId' = 0
					'CpuID' = 11, 10, 9, 8
					'PciId' = '0000:00:00.0', '0000:00:01.0', '0000:00:02.0', '0000:00:03.0'
					'MemoryRangeLength' = 34259832832
					'MemoryRangeBegin' = 0
					'DeviceId' = 12032
					'VendorName' = 'Intel Corporation'
					'Bus' = 0
					'Id' = '0000:00:00.0'
					'ParentBridge' = ''
					'Slot' = 0
					'DeviceName' = 'Xeon E7 v3/Xeon E5 v3/Core i7 DMI2'
					'VendorId' = -32634
					'Function' = 0
					'SubDeviceId' = 0
					'ClassId' = 1536
					'SubVendorId' = -32634
			}
			Compare-PSObject $Actual $Expected | Should -BeNull

		}
	}

}
