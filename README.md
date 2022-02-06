# Food Trucks Engineering Challenge

Your guide into [the world of food trucks of San Francisco](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/data) and my take on [Take Home Engineering Challenge](https://github.com/timfpark/take-home-engineering-challenge).

<img src="https://user-images.githubusercontent.com/5447190/152690412-a8652e9a-7b9e-4843-ad73-c9f9e0bf6b9b.png" width="900px"/>

This repo is basically a **fork of my own demo web UI for Azure Cognitive Search** - https://github.com/scale-tone/cognitive-search-static-web-apps-sample-ui.
The application code here is almost identical to the code there (except for minor UI fixes).

Yet it also includes [this deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1), which automatically creates all required Azure resources (an [Azure Cognitive Search index](https://docs.microsoft.com/en-us/azure/search/search-what-is-an-index), an [Azure Maps](https://docs.microsoft.com/en-us/azure/azure-maps/how-to-manage-account-keys) account and an [Azure Static Web App](https://docs.microsoft.com/en-us/azure/static-web-apps/overview) instance) and also populates the index with data from https://data.sfgov.org/api/views/rqzj-sfat/rows.csv.

## Live Demo

[https://purple-forest-0da7f9603.azurestaticapps.net](https://purple-forest-0da7f9603.azurestaticapps.net/?search=%22evans%20ave%22&$filter=FoodItems/any(f:%20search.in(f,%20%27muffins|rice%20pudding%27,%20%27|%27)))

This web app implements the so called *faceted search* user experience, whereas the user first enters some search phrase and then narrows down search resuls with facets on the left sidebar. Facets have different data types, and the app automatically detects and renders them accordingly. E.g. `FoodItems` is an array of strings, and you can pick up several values there, and also choose whether they should be combined with `OR` ('ANY OF') or `AND` ('ALL OF') logical operator. `X` and `Y` facets are numbers, so those are rendered as two-way sliders.

The map is also interactive. Use the 'draw-rectangle' button in the lower-right corner to select rectangular regions on it.

Search result cards show generic info about a particular food truck/push cart, including the list of food items it offers. Items in this list are clickable, use them to narrow down your search to a specific type of food you enjoy the most. Clicking on a card brings up the 'Details' dialog with all the item's data shown on it.

The list of search results supports infinite scrolling.

Also, all the search parameters are reflected in the browser's address bar, making your searches easily shareable.

## How to deploy to Azure

As per prerequisites, you will need:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), >>> **version 2.33.0 or later** <<< (earlier versions might fail to deploy Static Web Apps).
- [Powershell](https://docs.microsoft.com/en-us/powershell/).
- You need to be logged in into Azure: 
  ```
  az login
  ```

Do the following:

1. **Fork** this repo (cloning is not enough, because Static Web Apps deployment process needs write access to your GitHub repo).
2. Clone your fork onto your local devbox.
3. Go to the [project root folder](https://github.com/scale-tone/food-trucks-engineering-challenge) and run the [deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1) from there:
    ```
    ./deploy.ps1
    ```
  
   IMPORTANT: at some point the script will pause and wait for you to login into GitHub:

   <img src="https://user-images.githubusercontent.com/5447190/152693351-19c4c993-f60b-4042-92ec-7f1f5c180943.png" width="800px"/>

   Please, do what it asks you to.

Apart from creating/updating Azure resources, the script also updates the search index with [latest trucks data](https://data.sfgov.org/api/views/rqzj-sfat/rows.csv). This can take a few minutes, so please be patient.

Once done, the script will show you the URL of your newly created Azure Static Web App instance: 

  ![image](https://user-images.githubusercontent.com/5447190/152693969-0d4592b1-a4fd-482c-80f2-999b04aee4d7.png)

Navigate to that URL with your browser and observe the app running.

The deployment script has some optional parameters, that allow you to customize resource names and other things. See [the commments here](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1#L1).

Also, the script is idempotent. You can re-run it at any time, e.g. to re-populate the search index with latest data.

Alternatively, you can use [this ARM template](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/arm-template.json) to deploy the Static Web App only, but in that case you need to have a search index already created (or reuse some existing one).

## How to run locally on your devbox

As per prerequisites, you will need:
- [Node.js](https://nodejs.org/en).
- [Azure Functions Core Tools](https://github.com/Azure/azure-functions-core-tools#installing) package installed **globally** (`npm i -g azure-functions-core-tools@3`).
- A pre-created and pre-populated Azure Cognitive Search index. You can create it by running the [deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1) like this: 
    
    ```
      ./deploy.ps1 -skipDeployingStaticWebApp $true
    ```
    
- An [Azure Maps account](https://docs.microsoft.com/en-us/azure/azure-maps/how-to-manage-account-keys#create-a-new-account).

Do the following:

- Clone the sources onto your devbox.
- Update the `SearchApiKey` and `AzureMapSubscriptionKey` settings in [/api/local.settings.json](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/api/local.settings.json) file with your key values.
- Make sure these keys will never be committed.
- Go to the [project root folder](https://github.com/scale-tone/food-trucks-engineering-challenge) and execute this:

    ```
    npm install
    npm run start-with-backend
    ```
    
    The code will be compiled and started at http://localhost:3000. A browser tab with that page should open up automatically, but if not, then navigate to http://localhost:3000 with your browser.

## Implementation details

The code here is a typical React- and TypeScript-based Single-Page Application (SPA), designed to be hosted via [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/overview). With help from [MobX](https://mobx.js.org/README.html), it implements a classic [Model-View-ViewModel](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) design pattern. It has a [hierarchy of state objects](https://github.com/scale-tone/food-trucks-engineering-challenge/tree/master/src/states) (aka viewmodels) and a corresponding [hierarchy of pure (stateless) React components](https://github.com/scale-tone/food-trucks-engineering-challenge/tree/master/src/components) (aka views). These two hierarchies are welded together at the root level [here](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/src/index.tsx#L11). For example, [here](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/src/states/SearchResultsState.ts) is the state object, that represents the list of search results, and [here](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/src/components/SearchResults.tsx) is its markup.

The list of facets and their possible values on the left sidebar is [generated dynamically](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/src/states/FacetsState.ts#L15), based on **CognitiveSearchFacetFields** config value and results returned by Cognitive Search. The type of each faceted field (and the way it needs to be visualized) is also detected dynamically [here](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/src/states/FacetState.ts#L49).

The app doesn't have a backend as such. Instead, all requests to the underlying search index are proxied via [this set of Azure Function proxies](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/api/proxies.json#L1), where the Cognitive Search **api-key** is appended to each request. This ensures that the **api-key** is never exposed to the public and at the same time greatly simplifies the architecture.

## Important note on authN/authZ

By default there will be **no authentication** configured for your Static Web App instance, so anyone could potentially access it. You can then explicitly configure authN/authZ rules [as described here](https://docs.microsoft.com/en-us/azure/static-web-apps/authentication-authorization). E.g. to force every user to authenticate via AAD just add the following property: `"allowedRoles": [ "authenticated" ]` to the only one route that is currently defined in [routes.json](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/public/routes.json). Please remember though, that `authenticated` is a built-in role, which corresponds to anybody anyhow authenticated. To restrict the list of allowed users further, you will need to define and assign your own custom roles.

## Known issues

- There's an [ongoing DNS issue with Static Web Apps](https://github.com/Azure/static-web-apps/issues/713), whereas newly created instances might not be reachable. This seems to be very specific to the internet provider you use. If the app instance doesn't respond, try switching to another (e.g. mobile) network.
- Static Web App deployments depend on GitHub Actions. GitHub Actions tend to be down from time to time. If the app fails to be deployed, check the current status of GitHub Actions.
- When using a GitHub Codespace as a devbox, there can be CORS-related problems. Please, don't run this on a GitHub Codespace.

## What could be done better

- Unit tests are almost missing. [There're a few here](https://github.com/scale-tone/food-trucks-engineering-challenge/tree/master/src/__test), but so far they just demonstrate the idea and nothing more.
- The [deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1) could be optimized so, that it ingests trucks data in batches, rather than one-by-one. That would greatly increase its speed.
- Intergration tests at the end of the [deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1) could be more extensive. By far it only pings one single endpoint and doesn't even validate whether the search index is up and running.
- Would be great to make the [deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1) accept a [GitHub personal access token](https://docs.microsoft.com/en-us/azure/static-web-apps/publish-azure-resource-manager?tabs=azure-cli#create-a-github-personal-access-token), so that it can be run unattended (instead of requiring you to go through [GitHub Device Activation](https://github.com/login/device))
- Client side needs to be migrated to latest versions of MobX and Material-UI. This would take some refactoring though, because they're backward-incompatible.
