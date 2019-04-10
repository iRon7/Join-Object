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

		It '$Employee | InnerJoin $Department -On Department -Equals Name' {
			$Actual = $Employee | InnerJoin $Department -On Department -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Id Name                   Country            Department  Age ReportsTo
				-- ----                   -------            ----------  --- ---------
				 1 {Aerts, Sales}         {Belgium, France}  Sales        40         5
				 2 {Bauer, Engineering}   {Germany, Germany} Engineering  31         4
				 3 {Cook, Sales}          {England, France}  Sales        69         1
				 4 {Duval, Engineering}   {France, Germany}  Engineering  21         5
				 5 {Evans, Marketing}     {England, England} Marketing    35
				 6 {Fischer, Engineering} {Germany, Germany} Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | InnerJoin $Department -On Department, Country -Equals Name' {
			$Actual = $Employee | InnerJoin $Department -On Department, Country -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

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

		It '$Employee | LeftJoin $Department -On Department -Equals Name' {
			$Actual = $Employee | LeftJoin $Department -On Department -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Id Name                   Country            Department  Age ReportsTo
				-- ----                   -------            ----------  --- ---------
				 1 {Aerts, Sales}         {Belgium, France}  Sales        40         5
				 2 {Bauer, Engineering}   {Germany, Germany} Engineering  31         4
				 3 {Cook, Sales}          {England, France}  Sales        69         1
				 4 {Duval, Engineering}   {France, Germany}  Engineering  21         5
				 5 {Evans, Marketing}     {England, England} Marketing    35
				 6 {Fischer, Engineering} {Germany, Germany} Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | LeftJoin $Department -On Department, Country -Equals Name' {
			$Actual = $Employee | LeftJoin $Department -On Department, Country -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Country Id Name                   Department  Age ReportsTo
				------- -- ----                   ----------  --- ---------
				Belgium  1 {Aerts, $null}         Sales        40         5
				Germany  2 {Bauer, Engineering}   Engineering  31         4
				England  3 {Cook, $null}          Sales        69         1
				France   4 {Duval, $null}         Engineering  21         5
				England  5 {Evans, Marketing}     Marketing    35
				Germany  6 {Fischer, Engineering} Engineering  29         4
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

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

		It '$Employee | RightJoin $Department -On Department -Equals Name' {
			$Actual = $Employee | RightJoin $Department -On Department -Equals Name
			$Expected = ConvertFrom-SourceTable '
				    Id Name                   Country            Department     Age ReportsTo
				------ ----                   -------            ----------  ------ ---------
				     1 {Aerts, Sales}         {Belgium, France}  Sales           40         5
				     2 {Bauer, Engineering}   {Germany, Germany} Engineering     31         4
				     3 {Cook, Sales}          {England, France}  Sales           69         1
				     4 {Duval, Engineering}   {France, Germany}  Engineering     21         5
				     5 {Evans, Marketing}     {England, England} Marketing       35
				     6 {Fischer, Engineering} {Germany, Germany} Engineering     29         4
				 $Null {$null, Purchase}      {$null, France}          $Null  $Null     $Null
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | RightJoin $Department -On Department, Country -Equals Name' {
			$Actual = $Employee | RightJoin $Department -On Department, Country -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Country     Id Name                   Department     Age ReportsTo
				------- ------ ----                   ----------  ------ ---------
				Germany      2 {Bauer, Engineering}   Engineering     31         4
				England      5 {Evans, Marketing}     Marketing       35
				Germany      6 {Fischer, Engineering} Engineering     29         4
				France   $Null {$null, Sales}               $Null  $Null     $Null
				France   $Null {$null, Purchase}            $Null  $Null     $Null
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

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

		It '$Employee | FullJoin $Department -On Department -Equals Name' {
			$Actual = $Employee | FullJoin $Department -On Department -Equals Name
			$Expected = ConvertFrom-SourceTable '
				    Id Name                   Country            Department     Age ReportsTo
				------ ----                   -------            ----------  ------ ---------
				     1 {Aerts, Sales}         {Belgium, France}  Sales           40         5
				     2 {Bauer, Engineering}   {Germany, Germany} Engineering     31         4
				     3 {Cook, Sales}          {England, France}  Sales           69         1
				     4 {Duval, Engineering}   {France, Germany}  Engineering     21         5
				     5 {Evans, Marketing}     {England, England} Marketing       35
				     6 {Fischer, Engineering} {Germany, Germany} Engineering     29         4
				 $Null {$null, Purchase}      {$null, France}          $Null  $Null     $Null
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | FullJoin $Department -On Department, Country -Equals Name' {
			$Actual = $Employee | FullJoin $Department -On Department, Country -Equals Name
			$Expected = ConvertFrom-SourceTable '
				Country     Id Name                   Department     Age ReportsTo
				------- ------ ----                   ----------  ------ ---------
				Belgium      1 {Aerts, $null}         Sales           40         5
				Germany      2 {Bauer, Engineering}   Engineering     31         4
				England      3 {Cook, $null}          Sales           69         1
				France       4 {Duval, $null}         Engineering     21         5
				England      5 {Evans, Marketing}     Marketing       35
				Germany      6 {Fischer, Engineering} Engineering     29         4
				France   $Null {$null, Sales}               $Null  $Null     $Null
				France   $Null {$null, Purchase}            $Null  $Null     $Null
			' | Select-Object Country, Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It '$Employee | CrossJoin $Department' {
			$Actual = $Employee | CrossJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Id Name                   Country            Department  Age ReportsTo
				-- ----                   -------            ----------  --- ---------
				 1 {Aerts, Engineering}   {Belgium, Germany} Sales        40         5
				 1 {Aerts, Marketing}     {Belgium, England} Sales        40         5
				 1 {Aerts, Sales}         {Belgium, France}  Sales        40         5
				 1 {Aerts, Purchase}      {Belgium, France}  Sales        40         5
				 2 {Bauer, Engineering}   {Germany, Germany} Engineering  31         4
				 2 {Bauer, Marketing}     {Germany, England} Engineering  31         4
				 2 {Bauer, Sales}         {Germany, France}  Engineering  31         4
				 2 {Bauer, Purchase}      {Germany, France}  Engineering  31         4
				 3 {Cook, Engineering}    {England, Germany} Sales        69         1
				 3 {Cook, Marketing}      {England, England} Sales        69         1
				 3 {Cook, Sales}          {England, France}  Sales        69         1
				 3 {Cook, Purchase}       {England, France}  Sales        69         1
				 4 {Duval, Engineering}   {France, Germany}  Engineering  21         5
				 4 {Duval, Marketing}     {France, England}  Engineering  21         5
				 4 {Duval, Sales}         {France, France}   Engineering  21         5
				 4 {Duval, Purchase}      {France, France}   Engineering  21         5
				 5 {Evans, Engineering}   {England, Germany} Marketing    35
				 5 {Evans, Marketing}     {England, England} Marketing    35
				 5 {Evans, Sales}         {England, France}  Marketing    35
				 5 {Evans, Purchase}      {England, France}  Marketing    35
				 6 {Fischer, Engineering} {Germany, Germany} Engineering  29         4
				 6 {Fischer, Marketing}   {Germany, England} Engineering  29         4
				 6 {Fischer, Sales}       {Germany, France}  Engineering  29         4
				 6 {Fischer, Purchase}    {Germany, France}  Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

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
	
		It 'LeftJoin $Employee -On ReportsTo -Equals Id' {
			$Actual = LeftJoin $Employee -On ReportsTo -Equals Id
			$Expected = ConvertFrom-SourceTable '
				Id         Name             Country            Department                 Age         ReportsTo
				--         ----             -------            ----------                 ---         ---------
				{1, 5}     {Aerts, Evans}   {Belgium, England} {Sales, Marketing}         {40, 35}    {5, }
				{2, 4}     {Bauer, Duval}   {Germany, France}  {Engineering, Engineering} {31, 21}    {4, 5}
				{3, 1}     {Cook, Aerts}    {England, Belgium} {Sales, Sales}             {69, 40}    {1, 5}
				{4, 5}     {Duval, Evans}   {France, England}  {Engineering, Marketing}   {21, 35}    {5, }
				{5, $null} {Evans, $null}   {England, $null}   {Marketing, $null}         {35, $null} {, $null}
				{6, 4}     {Fischer, Duval} {Germany, France}  {Engineering, Engineering} {29, 21}    {4, 5}
			' | Select-Object @{N='Id'; E={ConvertTo-Array $_.Id}}, 
				@{N='Name'; E={ConvertTo-Array $_.Name}},
				@{N='Country'; E={ConvertTo-Array $_.Country}},
				@{N='Department'; E={ConvertTo-Array $_.Department}},
				@{N='Age'; E={ConvertTo-Array $_.Age}},
				@{N='ReportsTo'; E={ConvertTo-Array $_.ReportsTo}}

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'InnerJoin $Employee -On ReportsTo, Country -Equals Id' {
			$Actual = InnerJoin $Employee -On ReportsTo, Department -Equals Id
			$Expected = ConvertFrom-SourceTable '
				Department  Id     Name             Country            Age      ReportsTo
				----------  --     ----             -------            ---      ---------
				Engineering {2, 4} {Bauer, Duval}   {Germany, France}  {31, 21} {4, 5}
				Sales       {3, 1} {Cook, Aerts}    {England, Belgium} {69, 40} {1, 5}
				Engineering {6, 4} {Fischer, Duval} {Germany, France}  {29, 21} {4, 5}
			' | Select-Object @{N='Id'; E={ConvertTo-Array $_.Id}}, 
				@{N='Name'; E={ConvertTo-Array $_.Name}},
				@{N='Country'; E={ConvertTo-Array $_.Country}},
				@{N='Department'; E={ConvertTo-Array $_.Department}},
				@{N='Age'; E={ConvertTo-Array $_.Age}},
				@{N='ReportsTo'; E={ConvertTo-Array $_.ReportsTo}}

			Compare-PSObject $Actual $Expected | Should -BeNull
		}

	}
	
	Context 'Join by index' {

		It '$Employee | InnerJoin $Department' {
			$Actual = $Employee | InnerJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country            Department  Age ReportsTo
				-- ----                 -------            ----------  --- ---------
				 1 {Aerts, Engineering} {Belgium, Germany} Sales        40         5
				 2 {Bauer, Marketing}   {Germany, England} Engineering  31         4
				 3 {Cook, Sales}        {England, France}  Sales        69         1
				 4 {Duval, Purchase}    {France, France}   Engineering  21         5
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo
			
			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | LeftJoin $Department' {
			$Actual = $Employee | LeftJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country            Department  Age ReportsTo
				-- ----                 -------            ----------  --- ---------
				 1 {Aerts, Engineering} {Belgium, Germany} Sales        40         5
				 2 {Bauer, Marketing}   {Germany, England} Engineering  31         4
				 3 {Cook, Sales}        {England, France}  Sales        69         1
				 4 {Duval, Purchase}    {France, France}   Engineering  21         5
				 5 {Evans, $null}       {England, $null}   Marketing    35
				 6 {Fischer, $null}     {Germany, $null}   Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Department | RightJoin $Employee' {								# Swapped $Department and $Employee
			$Actual = $Department | RightJoin $Employee
			$Expected = ConvertFrom-SourceTable '
				Name                 Country            Id Department  Age ReportsTo
				----                 -------            -- ----------  --- ---------
				{Engineering, Aerts} {Germany, Belgium}  1 Sales        40         5
				{Marketing, Bauer}   {England, Germany}  2 Engineering  31         4
				{Sales, Cook}        {France, England}   3 Sales        69         1
				{Purchase, Duval}    {France, France}    4 Engineering  21         5
				{$null, Evans}       {$null, England}    5 Marketing    35
				{$null, Fischer}     {$null, Germany}    6 Engineering  29         4
			' | Select-Object @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Id, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
		
		It '$Employee | FullJoin $Department' {
			$Actual = $Employee | FullJoin $Department
			$Expected = ConvertFrom-SourceTable '
				Id Name                 Country            Department  Age ReportsTo
				-- ----                 -------            ----------  --- ---------
				 1 {Aerts, Engineering} {Belgium, Germany} Sales        40         5
				 2 {Bauer, Marketing}   {Germany, England} Engineering  31         4
				 3 {Cook, Sales}        {England, France}  Sales        69         1
				 4 {Duval, Purchase}    {France, France}   Engineering  21         5
				 5 {Evans, $null}       {England, $null}   Marketing    35
				 6 {Fischer, $null}     {Germany, $null}   Engineering  29         4
			' | Select-Object Id, @{N='Name'; E={ConvertTo-Array $_.Name}}, @{N='Country'; E={ConvertTo-Array $_.Country}}, Department, Age, ReportsTo

			Compare-PSObject $Actual $Expected | Should -BeNull
		}
	}

	Context "Merge columns" {

		It 'Use the left object property if exists otherwise use right object property' {
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name {If ($Null -ne $Left.$_) {$Left.$_} Else {$Right.$_}}
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

	Context 'Unify columns' {

		It '$Employee | InnerJoin $Department -On Department -Equals Name -Unify Employee, Department' {
			$Actual = $Employee | InnerJoin $Department -On Department -Equals Name -Unify Employee, Department
			$Expected = ConvertFrom-SourceTable '
				Id EmployeeName DepartmentName EmployeeCountry DepartmentCountry Department  Age ReportsTo
				-- ------------ -------------- --------------- ----------------- ----------  --- ---------
				 1 Aerts        Sales          Belgium         France            Sales        40         5
				 2 Bauer        Engineering    Germany         Germany           Engineering  31         4
				 3 Cook         Sales          England         France            Sales        69         1
				 4 Duval        Engineering    France          Germany           Engineering  21         5
				 5 Evans        Marketing      England         England           Marketing    35
				 6 Fischer      Engineering    Germany         Germany           Engineering  29         4'
				
			Compare-PSObject $Actual $Expected | Should -BeNull
		}

		It 'Join $Employee -On ReportsTo -Equals Id -Unify *1, *2' {
			$Actual = Join $Employee -On ReportsTo -Equals Id -Unify *1, *2
			$Expected = ConvertFrom-SourceTable '
				Id1 Id2 Name1   Name2 Country1 Country2 Department1 Department2 Age1 Age2 ReportsTo1 ReportsTo2
				--- --- -----   ----- -------- -------- ----------- ----------- ---- ---- ---------- ----------
				  1   5 Aerts   Evans Belgium  England  Sales       Marketing     40   35          5
				  2   4 Bauer   Duval Germany  France   Engineering Engineering   31   21          4          5
				  3   1 Cook    Aerts England  Belgium  Sales       Sales         69   40          1          5
				  4   5 Duval   Evans France   England  Engineering Marketing     21   35          5
				  6   4 Fischer Duval Germany  France   Engineering Engineering   29   21          4          5'

			Compare-PSObject $Actual $Expected
		}

		It '$Employee | CrossJoin $Department -Unify ""' {
			$Actual = $Employee | CrossJoin $Department -Unify ''
			$Expected = ConvertFrom-SourceTable '
				Id Name    Name1       Country Country1 Department  Age ReportsTo
				-- ----    -----       ------- -------- ----------  --- ---------
				 1 Aerts   Engineering Belgium Germany  Sales        40         5
				 1 Aerts   Marketing   Belgium England  Sales        40         5
				 1 Aerts   Sales       Belgium France   Sales        40         5
				 1 Aerts   Purchase    Belgium France   Sales        40         5
				 2 Bauer   Engineering Germany Germany  Engineering  31         4
				 2 Bauer   Marketing   Germany England  Engineering  31         4
				 2 Bauer   Sales       Germany France   Engineering  31         4
				 2 Bauer   Purchase    Germany France   Engineering  31         4
				 3 Cook    Engineering England Germany  Sales        69         1
				 3 Cook    Marketing   England England  Sales        69         1
				 3 Cook    Sales       England France   Sales        69         1
				 3 Cook    Purchase    England France   Sales        69         1
				 4 Duval   Engineering France  Germany  Engineering  21         5
				 4 Duval   Marketing   France  England  Engineering  21         5
				 4 Duval   Sales       France  France   Engineering  21         5
				 4 Duval   Purchase    France  France   Engineering  21         5
				 5 Evans   Engineering England Germany  Marketing    35
				 5 Evans   Marketing   England England  Marketing    35
				 5 Evans   Sales       England France   Marketing    35
				 5 Evans   Purchase    England France   Marketing    35
				 6 Fischer Engineering Germany Germany  Engineering  29         4
				 6 Fischer Marketing   Germany England  Engineering  29         4
				 6 Fischer Sales       Germany France   Engineering  29         4
				 6 Fischer Purchase    Germany France   Engineering  29         4'

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
			$Actual = $Employee | InnerJoin $Department -On Department -Eq Name -Merge {$Left.$_} -Property @{Country = {$Right.$_}}, *
			$Expected = ConvertFrom-SourceTable '
				Country Id Name    Department  Age ReportsTo
				------- -- ----    ----------  --- ---------
				France   1 Aerts   Sales        40         5
				Germany  2 Bauer   Engineering  31         4
				France   3 Cook    Sales        69         1
				Germany  4 Duval   Engineering  21         5
				England  5 Evans   Marketing    35
				Germany  6 Fischer Engineering  29         4'

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
		
		It 'Null, zero and empty string' {
			$Test = ConvertFrom-SourceTable '
				Value  Description
				------ -----------
				 $Null Null
				     0 Zero value
				       Empty string'
				
			$Actual = Join $Test -On Value
			$Expected = ConvertFrom-SourceTable '
			Value                     Description
			------                    -----------
			 $Null                 "Null", "Null"
			     0     "Zero value", "Zero value"
			       "Empty string", "Empty string"'
			
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

			$Actual = $Csv1 | Join $Csv2 -Unify *1, *2
			$Expected = ConvertFrom-SourceTable '
				Server1 Server2 Info1 Info2
				------- ------- ----- -----
				server1 server2 item1 item2
				server1 server2 item1 item2'

			Compare-PSObject $Actual $Expected | Should -BeNull
		}	

		It 'Comparing two CSVs using one property to compare another' { # https://stackoverflow.com/questions/55602662/comparing-two-csvs-using-one-property-to-compare-another
		
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
	}
}
