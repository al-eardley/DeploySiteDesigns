# Deploy Site Designs
Site Designs have made the deployment of repeatable customisation of sites much easier, and in my opinion are the starting point for any SharePoint deployment for communication or collaboration.

While the capabilities of Site Designs are well documented and continue to evolve, I see many environments where the deployment of the Site Scripts and Site Designs has been done in a way that allows for multiple versions of the same Site Script and Site Design to exist.

I have put together a very basic framework to support the repeatable deployment and upgrade of Site Scripts and Site Designs.

As a starting point the solution consists of the following components:

- A repository of JSON files for the different Site Scripts
- A PowerShell module script
- A connection script
- A CSV file to define the Site Scripts for a Site Design
- A script to create the Site Scripts from the CSV and create a Site Designs

This library includes the ability to provide the name of a hub site to join to and the name of term sets that can be used in columns.  The intention with this library is to minimise the need to update Site Script JSON for different environments.