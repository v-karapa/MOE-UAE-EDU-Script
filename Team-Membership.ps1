﻿#creating token id
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

      
       

    #Get Team details
         write-host "Getting Team details..."
         $getTeams = "https://graph.microsoft.com/beta/groups?filter=resourceProvisioningOptions/Any(x:x eq 'Team')" 
         $Team = Invoke-RestMethod -Headers $Header -Uri $getTeams -Method get -ContentType 'application/json'
         #$Team.value.id
         #$Team.value.DisplayName
        

         do 
        {

      foreach($id in $Team.value.id){

        $Tmembers="https://graph.microsoft.com/v1.0/groups/$id/members"
        $members = Invoke-RestMethod -Headers $Header -Uri $Tmembers -Method get 
        #$members.value.id
        #$members.value.jobTitle
        #$members.value.DisplayName
      

        foreach($member in  $members.value.id)
       
        {
       $licenseuri="https://graph.microsoft.com/v1.0/users/$member/licenseDetails"
       $licenseresult=Invoke-RestMethod -Headers $Header -Uri $licenseuri -Method get

        $licensevalue = $licenseresult.value
        $license = $licensevalue.skuPartNumber
        #$titlejob.jobTitle
        #$titlejob.displayName
        #$titlejob.value|fl
        
          
          if($license -eq "M365EDU_A5_FACULTY")
         {
          $facultybody='{
                "@odata.id": "https://graph.microsoft.com/v1.0/users/'+$member+'"
                }'

    $facultyuri ="https://graph.microsoft.com/v1.0/groups/$id/owners/`$ref"
    $output =Invoke-RestMethod -Headers $Header -Uri $facultyuri -Method Post -Body $facultybody -ContentType 'application/json'
    write-host "Faculty Membership role has been changed to Owner for" $id  $member
        }
        elseif($license -eq "M365EDU_A5_STUDENT")
        {

        #add student as member
        $addstudentbody='{
                "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/'+$member+'"
                }'
        $addstudenturi ="https://graph.microsoft.com/v1.0/groups/$id/members/`$ref"
        $output1=Invoke-RestMethod -Headers $Header -Uri $addstudenturi -Method Post -Body $addstudentbody -ContentType 'application/json'

        
        #remove student as owner
        $removestudenturi="https://graph.microsoft.com/v1.0/groups/$id/owners/" +$member+ "/`$ref"
        $output2=Invoke-RestMethod -Headers $Header -Uri $removestudenturi -Method Delete -ContentType 'application/json'
        write-host "student Membership role has been changed to member " $id $member
        }

      else
      {
            write-host "user have the different license" 
            $file = New-Object psobject
            $file | add-member -MemberType NoteProperty -Name userid $id
        }
    }
    }
    
    
    
    if ($group.'@odata.nextLink' -eq $null ) 
        { 
        break 
        } 
        else 
        { 
        $group = Invoke-RestMethod -Headers $Header -Uri $group.'@odata.nextLink' -Method Get 
        } 
        }while($true); 
        }
        

        else 
{
    write-host "You need to login admin consent in order to continue... " 
}

    
    