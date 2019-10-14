# Get-O365Numbers.ps1

param(

    [Parameter(mandatory=$false)][string]$SearchString,
    [Parameter(mandatory = $false)][uri]$SendToFlowURL

)

if ($SearchString) {

    $filter = "tel:$SearchString*"
    Write-Host "Searching using string '$SearchString'..."

} else {

    $filter = "tel:*"
    Write-Host "Searching for all assigned numbers..."
    
}

# Get list of users and assigned telephone numbers
$users = Get-CSOnlineUser -WarningAction SilentlyContinue | Where-Object {$_.LineURI -like $filter -and $_.InterpretedUserType -like "*User*"} | Select-Object DisplayName, UserPrincipalName, Enabled, EnterpriseVoiceEnabled, HostedVoicemail, @{N='PhoneNumber';E={$(($_.LineURI).ToString().Trim("tel:+"))}}, @{N='ServiceType';E={'USER'}}
$assignedNumbers += $users

# Get list of users and assigned telephone numbers
$resourceAccounts = Get-CSOnlineUser -WarningAction SilentlyContinue | Where-Object {$_.LineURI -like $filter -and $_.InterpretedUserType -like "*AppEndpoint*"} | Select-Object DisplayName, UserPrincipalName, Enabled, EnterpriseVoiceEnabled, HostedVoicemail, @{N='PhoneNumber';E={$(($_.LineURI).ToString().Trim("tel:+"))}}, @{N='ServiceType';E={'RESOURCE ACCOUNT'}}
$assignedNumbers += $resourceAccounts

$assignedNumbers = $assignedNumbers | Sort-Object -Property PhoneNumber

$assignedNumbers | Format-Table

if ($SendToFlowURL) {

    $JSON = [System.Text.UTF8Encoding]::GetEncoding('UTF-8').GetBytes((ConvertTo-Json $assignedNumbers))

    Write-Host "Sending to Flow URL: $SendToFlowURL"

    Invoke-RestMethod -Method Post -ContentType "application/json" -Body $JSON -Uri $SendToFlowURL

}