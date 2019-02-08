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

Describe 'Join-Object' {
	
	$Employee = ConvertFrom-SourceTable '
		Name    Country Department
		----    ------- ----------
		Aerts   Belgium Sales
		Bauer   Germany Engineering
		Cook    England Sales
		Duval   France  Engineering
		Evans   England Marketing
		Fischer Germany Engineering'

	$Department = ConvertFrom-SourceTable '
		Name        Country     Manager
		----        -------     -------
		Engineering Germany     Meyer
		Marketing   England     Morris
		Sales       France      Millet
		Board       Netherlands Mans'

	Context 'Join types' {

		It '$Employee | InnerJoin $Department -On Country' {
			$Actual = $Employee | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                     Name
				------- ----------  -------                     ----
				Germany Engineering Meyer     "Bauer", "Engineering"
				England Sales       Morris       "Cook", "Marketing"
				France  Engineering Millet          "Duval", "Sales"
				England Marketing   Morris      "Evans", "Marketing"
				Germany Engineering Meyer   "Fischer", "Engineering"'
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Country' {
			$Actual = $Employee | LeftJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                     Name
				------- ----------  -------                     ----
				Belgium Sales         $Null           "Aerts", $Null
				Germany Engineering Meyer     "Bauer", "Engineering"
				England Sales       Morris       "Cook", "Marketing"
				France  Engineering Millet          "Duval", "Sales"
				England Marketing   Morris      "Evans", "Marketing"
				Germany Engineering Meyer   "Fischer", "Engineering"'
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Country' {
			$Actual = $Employee | RightJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Department                      Name Manager Country
				----------                      ---- ------- -------
				Engineering   "Bauer", "Engineering" Meyer   Germany
				Sales            "Cook", "Marketing" Morris  England
				Engineering         "Duval", "Sales" Millet  France
				Marketing       "Evans", "Marketing" Morris  England
				Engineering "Fischer", "Engineering" Meyer   Germany
				      $Null           $Null, "Board" Mans    Netherlands'
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Country' {
			$Actual = $Employee | FullJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country     Department                      Name Manager
				-------     ----------                      ---- -------
				Belgium     Sales                 "Aerts", $Null   $Null
				Germany     Engineering   "Bauer", "Engineering" Meyer
				England     Sales            "Cook", "Marketing" Morris
				France      Engineering         "Duval", "Sales" Millet
				England     Marketing       "Evans", "Marketing" Morris
				Germany     Engineering "Fischer", "Engineering" Meyer
				Netherlands       $Null        @($Null, "Board") Mans'
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | CrossJoin $Department' {
			$Actual = $Employee | CrossJoin $Department
			$Expected = ConvertFrom-SourceTable '
				                 Country Department  Manager                     Name
				                 ------- ----------  -------                     ----
				    "Belgium", "Germany" Sales       Meyer     "Aerts", "Engineering"
				    "Belgium", "England" Sales       Morris      "Aerts", "Marketing"
				     "Belgium", "France" Sales       Millet          "Aerts", "Sales"
				"Belgium", "Netherlands" Sales       Mans            "Aerts", "Board"
				    "Germany", "Germany" Engineering Meyer     "Bauer", "Engineering"
				    "Germany", "England" Engineering Morris      "Bauer", "Marketing"
				     "Germany", "France" Engineering Millet          "Bauer", "Sales"
				"Germany", "Netherlands" Engineering Mans            "Bauer", "Board"
				    "England", "Germany" Sales       Meyer      "Cook", "Engineering"
				    "England", "England" Sales       Morris       "Cook", "Marketing"
				     "England", "France" Sales       Millet           "Cook", "Sales"
				"England", "Netherlands" Sales       Mans             "Cook", "Board"
				     "France", "Germany" Engineering Meyer     "Duval", "Engineering"
				     "France", "England" Engineering Morris      "Duval", "Marketing"
				      "France", "France" Engineering Millet          "Duval", "Sales"
				 "France", "Netherlands" Engineering Mans            "Duval", "Board"
				    "England", "Germany" Marketing   Meyer     "Evans", "Engineering"
				    "England", "England" Marketing   Morris      "Evans", "Marketing"
				     "England", "France" Marketing   Millet          "Evans", "Sales"
				"England", "Netherlands" Marketing   Mans            "Evans", "Board"
				    "Germany", "Germany" Engineering Meyer   "Fischer", "Engineering"
				    "Germany", "England" Engineering Morris    "Fischer", "Marketing"
				     "Germany", "France" Engineering Millet        "Fischer", "Sales"
				"Germany", "Netherlands" Engineering Mans          "Fischer", "Board"'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	$Changes = ConvertFrom-SourceTable '
		Name    Country Department
		----    ------- ----------
		Aerts   Germany Sales
		Bauer   Germany Marketing
		Geralds Belgium Engineering'

		It '$Employee | Update $Changes -On Country' {
			$Actual = $Employee | Update $Changes -On Name
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Country
				----------  ----    -------
				Sales       Aerts   Germany
				Marketing   Bauer   Germany
				Sales       Cook    England
				Engineering Duval   France
				Marketing   Evans   England
				Engineering Fischer Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | Merge $Changes -On Country' {
			$Actual = $Employee | Merge $Changes -On Name
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Country
				----------  ----    -------
				Sales       Aerts   Germany
				Marketing   Bauer   Germany
				Sales       Cook    England
				Engineering Duval   France
				Marketing   Evans   England
				Engineering Fischer Germany
				Engineering Geralds Belgium'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context 'Join by index' {

		It '$Employee | InnerJoin $Department' {
			$Actual = $Employee | InnerJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Department                    Name                 Country Manager
				----------                    ----                 ------- -------
				Sales       "Aerts", "Engineering"    "Belgium", "Germany" Meyer
				Engineering   "Bauer", "Marketing"    "Germany", "England" Morris
				Sales              "Cook", "Sales"     "England", "France" Millet
				Engineering       "Duval", "Board" "France", "Netherlands" Mans'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | LeftJoin $Department' {
			$Actual = $Employee | LeftJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Department                    Name                 Country Manager
				----------                    ----                 ------- -------
				Sales       "Aerts", "Engineering"    "Belgium", "Germany" Meyer
				Engineering   "Bauer", "Marketing"    "Germany", "England" Morris
				Sales              "Cook", "Sales"     "England", "France" Millet
				Engineering       "Duval", "Board" "France", "Netherlands" Mans
				Marketing           "Evans", $Null        "England", $Null   $Null
				Engineering       "Fischer", $Null        "Germany", $Null   $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Department | RightJoin $Employee' {
			$Actual = $Department | RightJoin $Employee
			$Expected = ConvertFrom-SourceTable '
				                  Name Manager                 Country Department
				                  ---- -------                 -------  ----------
				"Engineering", "Aerts" Meyer      "Germany", "Belgium" Sales
				  "Marketing", "Bauer" Morris     "England", "Germany" Engineering
				       "Sales", "Cook" Millet      "France", "England" Sales
				      "Board", "Duval" Mans    "Netherlands", "France" Engineering
				        $Null, "Evans"   $Null        $Null, "England" Marketing
				      $Null, "Fischer"   $Null        $Null, "Germany" Engineering'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | FullJoin $Department' {
			$Actual = $Employee | FullJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Department                    Name                 Country Manager
				----------                    ----                 ------- -------
				Sales       "Aerts", "Engineering"    "Belgium", "Germany" Meyer
				Engineering   "Bauer", "Marketing"    "Germany", "England" Morris
				Sales              "Cook", "Sales"     "England", "France" Millet
				Engineering       "Duval", "Board" "France", "Netherlands" Mans
				Marketing           "Evans", $Null        "England", $Null   $Null
				Engineering       "Fischer", $Null        "Germany", $Null   $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}
	
	Context 'Single object' {

		It 'Single left object' {
			$Actual = $Employee[1] | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                   Name
				------- ----------  ------- ----------------------
				Germany Engineering Meyer   "Bauer", "Engineering"'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Single right object' {
			$Actual = $Employee | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                     Name
				------- ----------  ------- ------------------------
				Germany Engineering Meyer     "Bauer", "Engineering"
				Germany Engineering Meyer   "Fischer", "Engineering"'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Single left object and single right object' {
			$Actual = $Employee[1] | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                   Name
				------- ----------  ------- ----------------------
				Germany Engineering Meyer   "Bauer", "Engineering"'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "-On ... -Equals ..." {

		It '$Employee | InnerJoin $Department -On Department -Eq Name' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name
			$Expected = ConvertFrom-SourceTable '
				             Country Department                      Name Manager
				             ------- ----------- ------------------------ -------
				 "Belgium", "France" Sales               "Aerts", "Sales" Millet
				"Germany", "Germany" Engineering   "Bauer", "Engineering" Meyer
				 "England", "France" Sales                "Cook", "Sales" Millet
				 "France", "Germany" Engineering   "Duval", "Engineering" Meyer
				"England", "England" Marketing       "Evans", "Marketing" Morris
				"Germany", "Germany" Engineering "Fischer", "Engineering" Meyer'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Merge values on Department = Name" {

		It 'Use the left object property if exists otherwise use right object property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Sales       Aerts   Millet  Belgium
				Engineering Bauer   Meyer   Germany
				Sales       Cook    Millet  England
				Engineering Duval   Meyer   France
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Only use the left name property and the right manager property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Property @{Name = {$Left.$_}; Manager = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Name    Manager
				----    -------
				Aerts   Millet
				Bauer   Meyer
				Cook    Millet
				Duval   Meyer
				Evans   Morris
				Fischer Meyer'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Use the left object property except for the country property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name {$Left.$_} Department, Name, @{Manager = {$Right.$_}}, Country
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Sales       Aerts   Millet  Belgium
				Engineering Bauer   Meyer   Germany
				Sales       Cook    Millet  England
				Engineering Duval   Meyer   France
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Join using expression" {

		It 'InnerJoin on Employee.Department = Department.Name and Employee.Country = Department.Country' {
			$Actual = $Employee | InnerJoin $Department -Using {$Left.Department -eq $Right.Name -and $Left.Country -eq $Right.Country} {$Left.$_} Department, Name, @{Manager = {$Right.$_}}, Country
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Engineering Bauer   Meyer   Germany
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Inner join on index' {
			$Actual = $Employee | InnerJoin $Department
			$Expected = ConvertFrom-SourceTable '
				                Country Department                    Name Manager
				 ---------------------- ----------- ---------------------- -------
				   "Belgium", "Germany" Sales       "Aerts", "Engineering" Meyer
				   "Germany", "England" Engineering   "Bauer", "Marketing" Morris
				    "England", "France" Sales              "Cook", "Sales" Millet
				"France", "Netherlands" Engineering       "Duval", "Board" Mans'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'Full join on index' {
			$Actual = $Employee | FullJoin $Department
			$Expected = ConvertFrom-SourceTable '
				                Country Department                    Name Manager
				----------------------- ----------  ---------------------- -------
				   "Belgium", "Germany" Sales       "Aerts", "Engineering" Meyer
				   "Germany", "England" Engineering   "Bauer", "Marketing" Morris
				    "England", "France" Sales              "Cook", "Sales" Millet
				"France", "Netherlands" Engineering       "Duval", "Board" Mans
				    `  "England", $Null Marketing   `       "Evans", $Null   $Null
				`      "Germany", $Null Engineering `     "Fischer", $Null   $Null'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It 'Self join with new properties' {
			$Employees = ConvertFrom-SourceTable '
				EmployeeId LastName  FirstName ReportsTo
				---------- --------  --------- ---------
				         1 Davolio   Nancy              2
				         2 Fuller    Andrew
				         3 Leveling  Janet              2
				         4 Peacock   Margaret           2
				         5 Buchanan  Steven             2
				         6 Suyama    Michael            5
				         7 King      Robert             5
				         8 Callahan  Laura              2
				         9 Dodsworth Anne               5'
				
			$Actual = $Employees | InnerJoin $Employees -On ReportsTo -Eq EmployeeID -Property @{Name = {"$($Left.FirstName) $($Left.LastName)"}; Manager = {"$($Right.FirstName) $($Right.LastName)"}}
			$Expected = ConvertFrom-SourceTable '
				Name             Manager
				----             -------
				Nancy Davolio    Andrew Fuller
				Janet Leveling   Andrew Fuller
				Margaret Peacock Andrew Fuller
				Steven Buchanan  Andrew Fuller
				Michael Suyama   Steven Buchanan
				Robert King      Steven Buchanan
				Laura Callahan   Andrew Fuller
				Anne Dodsworth   Steven Buchanan'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'InnerJoin using multiple property matches and output specific columns' {
			$Left = ConvertFrom-SourceTable '
				   Ref_ID First_Name Last_Name [DateTime]DOB
				--------- ---------- --------- -------------
				321364060 User1      Micah     11/01/1969
				946497594 User2      Acker     05/28/1960
				887327716 User3      Aco       06/26/1950
				588496260 User4      John      05/23/1960
				565465465 User5      Jack      07/08/2020'
				
			$Right = ConvertFrom-SourceTable '
				First_Name Last_Name [DateTime]DOB City   Document_Type Filename
				---------- --------- ------------- ------ ------------- ------------
				User1      Micah     11/01/1969    Parker Transcript    T4IJZSYO.pdf
				User2      Acker     05/28/1960           Transcript    R4IKTRYN.pdf
				User3      Aco       06/26/1950           Transcript    R4IKTHMK.pdf
				User4      John      05/23/1960           Letter        R4IKTHSL.pdf'
				
			$Actual = $Left | Join $Right -On First_Name, Last_Name, DOB -Property Ref_ID, Filename, Document_Type, First_Name, DOB, Last_Name
			$Expected = ConvertFrom-SourceTable '
				Filename     Document_Type    Ref_ID First_Name [DateTime]DOB Last_Name
				--------     -------------    ------ ---------- ------------- ---------
				T4IJZSYO.pdf Transcript    321364060 User1      1969/11/01    Micah
				R4IKTRYN.pdf Transcript    946497594 User2      1960/05/28    Acker
				R4IKTHMK.pdf Transcript    887327716 User3      1950/06/26    Aco
				R4IKTHSL.pdf Letter        588496260 User4      1960/05/23    John'
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'performance test' {
			
			$Left = 1..1000 | Foreach-Object {[PSCustomObject]@{Name = "jsmith$_"; Birthday = (Get-Date).adddays(-1)}}

			$Right = 501..1500 | Foreach-Object {[PSCustomObject]@{Department = "Department $_"; Name = "Department $_"; Manager = "jsmith$_"}}
				
			(Measure-Command {$Left | Join $Right Name -eq Manager}).TotalSeconds | Should -BeLessThan 10
		}

		
	}

}
