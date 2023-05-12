## 2023-05-12 3.8.0 (iRon)
  - Updated
    - [#39](https://github.com/iRon7/Join-Object/issues/39): Improved performance (by more than a factor 2)
    - [#38](https://github.com/iRon7/Join-Object/issues/38): Change default `-ValueName` ([bucket 2](https://github.com/PowerShell/PowerShell/blob/master/docs/dev-process/breaking-change-contract.md#bucket-2-unlikely-grey-area) break-change)
    - [#37](https://github.com/iRon7/Join-Object/issues/37): Exclude identical objects on a self join where the `-equal` parameter is omitted ([bucket 3](https://github.com/PowerShell/PowerShell/blob/master/docs/dev-process/breaking-change-contract.md#bucket-3-unlikely-grey-area) break-change)
    - [#40](https://github.com/iRon7/Join-Object/issues/40): Improved the way multiple properties are compared  ([bucket 3](https://github.com/PowerShell/PowerShell/blob/master/docs/dev-process/breaking-change-contract.md#bucket-3-unlikely-grey-area) break-change)
    - [#41](https://github.com/iRon7/Join-Object/issues/41): Improved comparison with collection values ( `@{a=1} -ne @{a=2}` ) ([bucket 3](https://github.com/PowerShell/PowerShell/blob/master/docs/dev-process/breaking-change-contract.md#bucket-3-unlikely-grey-area) break-change)
    - Changed comment based help to make use of the [Get-MarkdownHelp](https://github.com/iRon7/Get-MarkdownHelp) features 
## 2022-04-26 3.7.1 (iRon)
  - New feature
    - Added [#30](https://github.com/iRon7/Join-Object/issues/30): Symmetric difference (OuterJoin)
## 2021-12-17 3.6.0 (iRon)
  - Updated
    - Implemented [#29](https://github.com/iRon7/Join-Object/issues/29): key expressions (requires explicit `-Using` parameter for compare expressions)
## 2021-07-27 3.5.4 (iRon)
  - Fixes
    - Fixed issue [#28](https://github.com/iRon7/Join-Object/issues/28): FullJoin doesn't work properly when joining multiple array when one of the array is empty
## 2021-07-06 3.5.3 (iRon)
  - Fixes
    - Fixed issue [#27](https://github.com/iRon7/Join-Object/issues/27): MissingLeftProperty: `Join-Object` : The property 'xxx' cannot be found on the left object.
## 2021-06-14 3.5.2 (iRon)
  - Help
    - Minor Help update and advertisement for the Module version.
## 2021-06-10 3.5.1 (iRon)
  - Fixes
    - Fixed ScriptBlock module scope issue: https://stackoverflow.com/q/2193410/1701026
## 2021-06-08 3.5.0 (iRon)
  - Updated
    - Prepared for module version
## 2021-04-08 3.4.7 (iRon)
  - Updated
    - Improved proxy command defaults
## 2021-04-08 3.4.6 (iRon)
  - Fixes
    - Fixed issue [#19](https://github.com/iRon7/Join-Object/issues/19): Deal with empty (and `$Null`) inputs
## 2021-03-11 3.4.5 (iRon)
  - Help
    - Issue [#17](https://github.com/iRon7/Join-Object/issues/17) Updated help
## 2021-03-24 3.4.4 (iRon)
  - Updated
    - Using `$PSCmdlet`.ThrowTerminatingError for argument exceptions
## 2021-03-20 3.4.2 (iRon)
  - Updated
    - Issue [#18](https://github.com/iRon7/Join-Object/issues/18) Support self-join on the left (piped) object
## 2021-03-11 3.4.2 (iRon)
  - Help
    - Code and Help clearance
## 2021-03-08 3.4.1 (iRon)
  - Updated
    - Implemented issue [#16](https://github.com/iRon7/Join-Object/issues/16) "Discern merged properties for multiple joins"
## 2021-03-01 3.4.0 (iRon)
  - Updated
    - Implemented issue [#14](https://github.com/iRon7/Join-Object/issues/14) "Support non-object arrays"
## 2020-08-09 3.3.0 (iRon)
  - Updated
    - Convert each object to a hash table for strict expressions
    - Support wildcard * (all properties) for the `-On` parameter
    - Prevent against code injection: https://devblogs.microsoft.com/powershell/powershell-injection-hunter-security-auditing-for-powershell-scripts/
    - Implemented smarter properties merge: [#12](https://github.com/iRon7/Join-Object/issues/12)
    - Reformatted script with https://github.com/DTW-DanWard/PowerShell-Beautifier
## 2020-04-05 3.2.2 (iRon)
  - Updated
    - Better handling argument exceptions
## 2020-01-19 3.2.1 (iRon)
  - Updated
    - Issue [#10](https://github.com/iRon7/Join-Object/issues/10): Support for dictionaries (hashtable, ordered, ...)
## 2019-12-16 3.2.0 (iRon)
  - Updated
    - Defined stricter parameter sets (separated `-On` <String[]> and `-OnExpression` <ScriptBlock>)
## 2019-12-10 3.1.6 (iRon)
  - New feature
    - Added `-MatchCase` (alias `-CaseSensitive`) parameter
## 2019-12-09 3.1.5 (iRon)
  - New feature
    - Added `-Strict` parameter
## 2019-12-02 3.1.4 (iRon)
  - Updated
    - Throw "The `-On` parameter cannot be used on a cross join."
## 2019-11-15 3.1.3 (iRon)
  - Updated
    - Also apply `-Where` argument to outer join part (expression to evaluate `$Null` values)
## 2019-11-11 3.1.2 (iRon)
  - Fixes
    - Resolved bug with single right object
## 2019-11-10 3.1.1 (iRon)
  - Updated
    - Improved `-Property` * implementation
## 2019-11-08 3.1.0 (iRon)
  - Help
    - Adjusted help
## 2019-11-07 3.0.8 (iRon)
  - Updated
    - All properties of the `$Left` and `$Right` object are set to `$Null` in the outer join part.
    - Better support chaining multiple joins and simplified available expression objects:
## 2019-11-01 3.0.7 (iRon)
  - Updated
    - Renamed `-Unify` parameter to `-Discern` and divided `-Discern` from `-Property` parameter
## 2019-07-16 3.0.6 (iRon)
  - Updated
    - Issue [#6](https://github.com/iRon7/Join-Object/issues/6), improved performance (~2x on large tables), thanks to @burkasaurusrex' suggestion
## 2019-07-14 3.0.5 (meany)
  - Fixes
    - Issue [#5](https://github.com/iRon7/Join-Object/issues/5), resolved: Cannot dot source / invoke script on 2012 R2 bug
## 2019-07-03 3.0.4 (iRon)
  - Updated
    - Experimental version (not implemented)
## 2019-07-02 3.0.3 (iRon)
  - Updated
    - Support for datatables
## 2019-04-10 3.0.2 (iRon)
  - Fixes
    - Fixed default unify issue due to `-On` case difference
## 2019-03-30 3.0.1 (iRon)
  - Updated
    - Updated embedded examples
## 2019-03-30 3.0.0 (iRon)
  - New feature
    - New release with new test set
## 2019-03-29 3.7.1 (iRon)
  - Updated
    - Improved self join syntax
## 2019-03-25 3.7.0 (iRon)
  - New feature
    - Added `-Where` clause
## 2019-03-10 2.6.0 (iRon)
  - Updated
    - Improved performance by using a HashTable for the inner (right) loop where possible
## 2019-03-04 2.5.2 (iRon)
  - Updated
    - Changed `-Pair` to `-Unify`
## 2019-03-03 2.5.1 (iRon)
  - New feature
    - Added `-Pair` (alias `-Merge`) feature to separate duplicated unrelated property names
## 2019-02-24 2.4.4 (iRon)
  - Fixes
    - Resolved scope bug when invoked multiple times in the same stream
## 2019-02-06 2.4.3 (iRon)
  - Updated
    - Changed `$LeftOrNull` and `$RightOrNull` to `$LeftOrVoid` and `$RightOrVoid`
## 2019-02-08 2.4.2 (mcclimont)
  - Updated
    - Compliant with StrictMode `-Version` 2 (https://github.com/iRon7/Join-Object/pull/3)
## 2019-02-06 2.4.1 (iRon)
  - New feature
    - Added `$LeftOrRight` and `$RightOrLeft` references
## 2019-02-02 2.4.0 (iRon)
  - New feature
    - Added Update-Object and Merge-Object proxy commands
## 2019-02-01 2.3.2 (iRon)
  - Updated
    - The `-MergeExpression` is only used in case the Left and Right properties overlap
## 2018-12-30 2.3.1 (iRon)
  - New feature
    - Added CrossJoin Type. If the `-On` parameter is omitted, a join by index will be done
## 2018-11-28 2.3.0 (iRon)
  - Updated
    - Replaced `InnerJoin-`, `LeftJoin-`, `RightJoin-`, `FullJoin-Object` aliases by proxy commands
## 2018-11-28 2.2.6 (iRon)
  - Updated
    - Support for mixed `[string]Key`/`[hashtable]@{Key={Expression}}` `-Property` parameter
## 2018-11-27 2.2.5 (iRon)
  - Fixes
    - Fixed empty output bug (including test)
## 2018-03-25 2.2.4 (iRon)
  - Updated
    - Keeping the properties in order
## 2018-03-25 2.2.3 (iRon)
  - Updated
    - Supply a list of properties by: `-Property` [String[]]
## 2018-03-25 2.2.2 (iRon)
  - Updated
    - PowerShell Gallery Release
## 2018-03-25 2.2.1 (iRon)
  - New feature
    - Support for adding new properties (see: `-Property`)
## 2018-03-15 2.2.0 (iRon)
  - Updated
    - Read single records from the pipeline
## 2018-03-01 2.1.0 (iRon)
  - Fixes
    - Resolved: "Unexpected results when reusing custom objects in the pipeline"
## 2017-12-11 2.0.2 (iRon)
  - Updated
    - Reworked for PowerSnippets.com
## 2017-10-24 1.1.1 (iRon)
  - Fixes
    - Resolved bug where the Left Table contains a single column
## 2017-08-08 1.1.0 (iRon)
  - Updated
    - Merged the `-Expressions` and `-DefaultExpression` parameters
## 2017-01-01 0.99.99 (iRon)
  - Updated
    - First releases
