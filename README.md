# Food Trucks Engineering Challenge

Your guide into [the world of food trucks of San Francisco](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/data) and my take on [Take Home Engineering Challenge](https://github.com/timfpark/take-home-engineering-challenge).

<img src="https://user-images.githubusercontent.com/5447190/152690412-a8652e9a-7b9e-4843-ad73-c9f9e0bf6b9b.png" width="800px"/>

This repo is basically a **fork of my own demo web UI for Azure Cognitive Search** - https://github.com/scale-tone/cognitive-search-static-web-apps-sample-ui.
The application code here is almost identical to the code there (except for minor UI fixes).
Yet it also includes [this deployment script](https://github.com/scale-tone/food-trucks-engineering-challenge/blob/master/deploy.ps1), which automatically creates all required Azure resources (an [Azure Cognitive Search index](https://docs.microsoft.com/en-us/azure/search/search-what-is-an-index), an [Azure Maps](https://docs.microsoft.com/en-us/azure/azure-maps/how-to-manage-account-keys) account and an [Azure Static Web App](https://docs.microsoft.com/en-us/azure/static-web-apps/overview) instance) and also populates the index with data from https://data.sfgov.org/api/views/rqzj-sfat/rows.csv.
