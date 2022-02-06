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
