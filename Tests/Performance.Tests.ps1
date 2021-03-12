Write-Host 'Preparing...'
. .\Join.ps1
$Null = Random -SetSeed 0
$Max = 1000
$NumberFormat = '{0:' + '0' * ($Max - 1).ToString().Length + '}'

$Left = foreach ($i in 0..$Max) {
    [pscustomobject]@{
        Number = $i
        Random = "Random$NumberFormat" -f (Random $Max)
        Side = "Left$NumberFormat" -f $i
    }
}

$Right = foreach ($i in 0..$Max) {
    [pscustomobject]@{
        Name = "Name$NumberFormat" -f $i
        Random = "Random$NumberFormat" -f (Random $Max)
        Side = "Right$NumberFormat" -f $i
    } 
}


Write-Host 'Measuring inner join...'
$InnerJoin = Measure-Command {
    $Test = $Left | Join $Right -On Random
}
Write-Host ($Test | Select-Object -First 5 | Format-Table | Out-String)
Write-Host $InnerJoin.TotalSeconds

Write-Host 'Measuring full join...'
$FullJoin = Measure-Command {
    $Test = $Left | FullJoin $Right -On Random
}
Write-Host ($Test | Select-Object -First 5 | Format-Table | Out-String)
Write-Host $FullJoin.TotalSeconds

Write-Host 'Measuring side-by-side join...'
$SideJoin = Measure-Command {
    $Test = $Left | FullJoin $Right
}
Write-Host ($Test | Select-Object -First 5 | Format-Table | Out-String)
Write-Host $SideJoin.TotalSeconds

Write-Host 'Total:' ($InnerJoin.TotalSeconds + $FullJoin.TotalSeconds + $SideJoin.TotalSeconds)
