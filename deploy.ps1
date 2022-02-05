param (
    [string] $resourceGroupName = "food-trucks-rg",
    [string] $staticWebAppName,
    [string] $mapsAccountName,
    [string] $searchServiceName,
    [string] $truckCsvDataUrl = "https://data.sfgov.org/api/views/rqzj-sfat/rows.csv",
    [string] $gitHubRepoUrl
)

if( az group exists --name $resourceGroupName | ConvertFrom-Json) {

    # Checking resource group location. It will be inherited by all created resources, so it must be one of the regions where Static Web Apps are supported

    $resourceGroup = az group show --name $resourceGroupName | ConvertFrom-Json
    $allowedLocations = ("westus2","centralus","eastus2","westeurope","eastasia")

    if(!($allowedLocations -contains $resourceGroup.location)) {

        Write-Error "The resource group must be in one of the following locations: $($allowedLocations). That's because Azure Static Web Apps are only supported there, as of today."
        return
    }

    Write-Host "Using an existing resource group $($resourceGroup.name)"

} else {

    # Creating the resource group in some default location (westeurope)

    $resourceGroup = az group create --name $resourceGroupName --location "westeurope" | ConvertFrom-Json
    Write-Host "Created a new resource group $($resourceGroup.name)"
}

# Choosing a unique search service name
if(!$searchServiceName) {

    $searchServiceName = "food-trucks-search-service-$($resourceGroup.id.GetHashCode().toString('x'))"
}

# Creating the Cognitive Search service instance

Write-Host "Creating $($searchServiceName)..."

az search service create --name $searchServiceName --resource-group $resourceGroupName --sku Basic

Write-Host "$($searchServiceName) was created"

# Getting search keys

$adminKey = (az search admin-key show --service-name $searchServiceName --resource-group $resourceGroupName | ConvertFrom-Json).primaryKey
$queryKey = (az search query-key list --service-name $searchServiceName --resource-group $resourceGroupName | ConvertFrom-Json)[0].key

# Search index name is predefined and cannot be changed
$searchIndexName = "food-trucks-index"

# Creating the search index

Write-Host "Creating the search index..."

$indexDefinition = Get-Content 'index-definition.json' | Out-String
Invoke-WebRequest -Uri "https://$($searchServiceName).search.windows.net/indexes?api-version=2020-06-30" -Method POST -Body $indexDefinition -ContentType "application/json" -Headers @{"api-key"=$adminKey}

Write-Host "Search index $($searchIndexName) was created"

# Choosing a unique Azure Maps account name
if(!$mapsAccountName) {

    $mapsAccountName = "food-trucks-maps-account-$($resourceGroup.id.GetHashCode().toString('x'))"
}

# Deploying Azure Maps account
az maps account create --account-name $mapsAccountName --resource-group $resourceGroupName --sku S0 --accept-tos
$mapsKey = (az maps account keys list --account-name $mapsAccountName --resource-group $resourceGroupName | ConvertFrom-Json).primaryKey


# Deploying Static Web App instance

If (!$gitHubRepoUrl) { 

    # Trying to read and use the git remote origin url
    $gitHubRepoUrl = git config --get remote.origin.url

    if($gitHubRepoUrl -match '.git$') {

        $gitHubRepoUrl = $gitHubRepoUrl.Substring(0, $gitHubRepoUrl.Length - 4)
    }
}

# Choosing a unique Static Web App instance name
if(!$staticWebAppName) {

    $staticWebAppName = "food-trucks-static-web-app-$($resourceGroup.id.GetHashCode().toString('x'))"
}

$staticApp = az staticwebapp create `
    --name $staticWebAppName `
    --resource-group $resourceGroupName `
    --location $resourceGroup.location `
    --sku Standard `
    --source $gitHubRepoUrl `
    --branch master `
    --app-location "/" `
    --api-location "api" `
    --output-location "build" `
    --login-with-github `
    | ConvertFrom-Json

az staticwebapp appsettings set --name $staticWebAppName `
    --setting-names `
        SearchServiceName=$searchServiceName `
        SearchIndexName=$searchIndexName `
        SearchApiKey=$queryKey `
        AzureMapSubscriptionKey=$mapsKey `
        CognitiveSearchKeyField=locationid `
        CognitiveSearchNameField=Applicant `
        CognitiveSearchGeoLocationField=Location `
        CognitiveSearchOtherFields=FoodItems,LocationDescription,dayshours `
        CognitiveSearchFacetFields=FacilityType,FoodItems*,Status,block,lot,X,Y `
        CognitiveSearchTranscriptFields=Applicant,LocationDescription,FoodItems,Status,dayshours

Write-Host "The static web app $($staticWebAppName) was successfully deployed"
Write-Host "Navigate to https://$($staticApp.defaultHostname) to see it in action"

# Ingesting data into search index

$trucksData = Invoke-RestMethod -Uri $truckCsvDataUrl | ConvertFrom-Csv

foreach ($truck in $trucksData)
{
    # Location field needs to be converted into GeoJSON format
    $locationField = [String]::Empty
    If (($truck.Longitude -ne 0) -and ($truck.Latitude -ne 0)) { 
        $locationField = ", Location: { ""type"": ""Point"", ""coordinates"": [$($truck.Longitude),$($truck.Latitude)]}"
    }

    $foodItemsArray = $truck.FoodItems -split ":"
    $foodItems = $foodItemsArray | ForEach-Object { """$($_.Trim())""" }

    $json = "{value:[{ 
        locationid: ""$($truck.locationid)"",

        Applicant: ""$($truck.Applicant -replace "\\",[String]::Empty)"",
        LocationDescription: ""$($truck.LocationDescription -replace "\\",[String]::Empty)"",

        $( &{If($truck.dayshours) {"dayshours: '$($truck.dayshours)',"} Else {[String]::Empty}} )
        $( &{If($truck.Status) {"Status: '$($truck.Status)',"} Else {[String]::Empty}} )

        $( &{If($truck.FacilityType) {"FacilityType: '$($truck.FacilityType)',"} Else {[String]::Empty}} )
        $( &{If($truck.block) {"block: '$($truck.block)',"} Else {[String]::Empty}} )
        $( &{If($truck.lot) {"lot: '$($truck.lot)',"} Else {[String]::Empty}} )

        $( &{If($truck.X) {"X: $($truck.X),"} Else {[String]::Empty}} )
        $( &{If($truck.Y) {"Y: $($truck.Y),"} Else {[String]::Empty}} )

        FoodItems: [ $( $foodItems -join ','  ) ]
        $( $locationField )
    }]}"

    Invoke-WebRequest -Uri "https://$($searchServiceName).search.windows.net/indexes/$($searchIndexName)/docs/index?api-version=2020-06-30" -Method POST -Body $json -ContentType "application/json" -Headers @{"api-key"=$adminKey}
}

Write-Host "Finished ingesting trucks data"
Write-Host "You should now be able to see it at https://$($staticApp.defaultHostname)"
Write-Host "NOTE: it might take a few minutes for a Static Web App to finish its deployment. Please, be patient."