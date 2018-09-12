$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

. .\ConvertFrom-SourceTable.ps1			# https://www.powershellgallery.com/packages/ConvertFrom-SourceTable

Function Should-BeObject {
	Param (
		[Parameter(Position=0)][Object[]]$b, [Parameter(ValueFromPipeLine = $True)][Object[]]$a
	)
	$Property = ($a | Select-Object -First 1).PSObject.Properties | Select-Object -Expand Name
	$Difference = Compare-Object $b $a -Property $Property
	Try {"$($Difference | Select-Object -First 1)" | Should -BeNull} Catch {$PSCmdlet.WriteError($_)}

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

		It 'InnerJoin' {
			$Actual = $Employee | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                     Name
				------- ----------  -------                     ----
				Germany Engineering Meyer     "Bauer", "Engineering"
				England Sales       Morris       "Cook", "Marketing"
				France  Engineering Millet          "Duval", "Sales"
				England Marketing   Morris      "Evans", "Marketing"
				Germany Engineering Meyer   "Fischer", "Engineering"'
				
			,$Actual | Should-BeObject $Expected
		}

		It 'LeftJoin' {
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
				
			,$Actual | Should-BeObject $Expected
		}

		It "RightJoin" {
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
				
			,$Actual | Should-BeObject $Expected
		}

		It 'FullJoin' {
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
				
			,$Actual | Should-BeObject $Expected
		}

		It 'Cross Join' {
			$Actual = $Employee | Join $Department
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

			,$Actual | Should-BeObject $Expected
		}

	}
	
	Context 'Single object' {

		It 'Single left object' {
			$Actual = $Employee[1] | InnerJoin $Department -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                   Name
				------- ----------  ------- ----------------------
				Germany Engineering Meyer   "Bauer", "Engineering"'

			,$Actual | Should-BeObject $Expected
		}

		It 'Single right object' {
			$Actual = $Employee | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                     Name
				------- ----------  ------- ------------------------
				Germany Engineering Meyer     "Bauer", "Engineering"
				Germany Engineering Meyer   "Fischer", "Engineering"'

			,$Actual | Should-BeObject $Expected
		}

		It 'Single left object and single right object' {
			$Actual = $Employee[1] | InnerJoin $Department[0] -On Country
			$Expected = ConvertFrom-SourceTable '
				Country Department  Manager                   Name
				------- ----------  ------- ----------------------
				Germany Engineering Meyer   "Bauer", "Engineering"'

			,$Actual | Should-BeObject $Expected
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

			,$Actual | Should-BeObject $Expected
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

			,$Actual | Should-BeObject $Expected
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

			,$Actual | Should-BeObject $Expected
		}

		It 'Use the left object property except for the country property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name {$Left.$_} @{Manager = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Sales       Aerts   Millet  Belgium
				Engineering Bauer   Meyer   Germany
				Sales       Cook    Millet  England
				Engineering Duval   Meyer   France
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany'

			,$Actual | Should-BeObject $Expected
		}
	}

	Context "Join using expression" {

		It 'InnerJoin on Employee.Department = Department.Name and Employee.Country = Department.Country' {
			$Actual = $Employee | InnerJoin $Department -Using {$Left.Department -eq $Right.Name -and $Left.Country -eq $Right.Country} {$Left.$_} @{Manager = {$Right.$_}}
			$Expected = ConvertFrom-SourceTable '
				Department  Name    Manager Country
				----------  ----    ------- -------
				Engineering Bauer   Meyer   Germany
				Marketing   Evans   Morris  England
				Engineering Fischer Meyer   Germany'

			,$Actual | Should-BeObject $Expected
		}

		It 'Inner join on index' {
			$Actual = $Employee | InnerJoin $Department {$LeftIndex -eq $RightIndex}
			$Expected = ConvertFrom-SourceTable '
				                Country Department                    Name Manager
				 ---------------------- ----------- ---------------------- -------
				   "Belgium", "Germany" Sales       "Aerts", "Engineering" Meyer
				   "Germany", "England" Engineering   "Bauer", "Marketing" Morris
				    "England", "France" Sales              "Cook", "Sales" Millet
				"France", "Netherlands" Engineering       "Duval", "Board" Mans'

			,$Actual | Should-BeObject $Expected
		}
		
		It 'Full join on index' {
			$Actual = $Employee | FullJoin $Department {$LeftIndex -eq $RightIndex}
			$Expected = ConvertFrom-SourceTable '
				                Country Department                    Name Manager
				----------------------- ----------  ---------------------- -------
				   "Belgium", "Germany" Sales       "Aerts", "Engineering" Meyer
				   "Germany", "England" Engineering   "Bauer", "Marketing" Morris
				    "England", "France" Sales              "Cook", "Sales" Millet
				"France", "Netherlands" Engineering       "Duval", "Board" Mans
				    `  "England", $Null Marketing   `       "Evans", $Null   $Null
				`      "Germany", $Null Engineering `     "Fischer", $Null   $Null'

			,$Actual | Should-BeObject $Expected
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

			,$Actual | Should-BeObject $Expected
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
			
			,$Actual | Should-BeObject $Expected
		}
	}

}
