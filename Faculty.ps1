#creating token id
$input = get-content info.json | ConvertFrom-Json
$Client_Secret = $input.Client_Secret
$client_Id = $input.client_Id
$Tenantid = $input.Tenantid

#Grant Adminconsent 
$Grant= 'https://login.microsoftonline.com/common/adminconsent?client_id='
$admin = '&state=12345&redirect_uri=https://localhost:1234'
$Grantadmin = $Grant + $client_Id + $admin

start $Grantadmin
write-host "login with your tenant login detials to proceed further"

$proceed = Read-host " Press Y to continue "
if ($proceed -eq 'Y')
{
    write-host "Creating Access_Token"          
              $ReqTokenBody = @{
         Grant_Type    =  "client_credentials"
        client_Id     = "$client_Id"
        Client_Secret = "$Client_Secret"
        Scope         = "https://graph.microsoft.com/.default"
    } 

    $loginurl = "https://login.microsoftonline.com/" + "$Tenantid" + "/oauth2/v2.0/token"
    $Token = Invoke-RestMethod -Uri "$loginurl" -Method POST -Body $ReqTokenBody -ContentType "application/x-www-form-urlencoded"

    $Header = @{
        Authorization = "$($token.token_type) $($token.access_token)"
    }

    $userList = Import-Csv "Faculty.csv"
    foreach($users in $userList)
    {
    #$id = "035f20f8-9f51-4df5-a301-48771af5285d"
    $id = $users.userid
    
    $Teams="https://graph.microsoft.com/v1.0/users/" + "$id" + "/joinedTeams"
    $Teamsinfo = Invoke-RestMethod -Headers $Header -Uri $Teams -Method Get
    $teamscount = $Teamsinfo.'@odata.count'

 

    foreach($Teamid in $Teamsinfo.value)
    {
       $groupuri = "https://graph.microsoft.com/v1.0/groups/" + $teamid.id + "/owners"
       $groupowners = Invoke-RestMethod -Headers $Header -Uri $groupuri -Method Get

       $owner = $groupowners.value.id
       $owners = [string]::Join("; ",$owner)

       
       if ((!$owner -eq $null) -or (!$owners -contains $null))
               {
               Write-host "already faculty is owner in" $teamid.displayName
               write-host "Already user as owner"
       
               }

       else{

        $body ='{
                "@odata.id": "https://graph.microsoft.com/v1.0/users/'+$id+'"
                }'
            $change = "https://graph.microsoft.com/v1.0/groups/" + $teamid.id + "/owners/`$ref"
            $output = Invoke-RestMethod -Headers $Header -Uri $change -Method Post -Body $body -ContentType 'application/json'

            write-host "updated user to owner"
              }
                    $file = New-Object psobject
                    $file | add-member -MemberType NoteProperty -Name User $id
                    $file | add-member -MemberType NoteProperty -Name Teamscount $teamscount
                    $file | export-csv output.csv -NoTypeInformation -Append

    }
    }
    }

 else 
{
    write-host "You need to login admin consent in order to continue... " 
}