---
title: Connect to MySQL HeatWave on AWS via Public Endpoint from OCI Compute Instance
parent: [tutorials]
tags: [mysql,database,heatwave]
categories: [cloudapps]
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-10-08 17:00
description: "Wiring up our OCI Compute Instance to the MySQL HeatWave on AWS instance for analytics."
author: Victor Agreda
mrm: WWMK220224P00058
---
Once we've created a database on OCI and set up our virtual private network with a way to connect (using access lists), we can easily wire it up to MySQL HeatWave on AWS.

1. Create a MySQL database on OCI, allow public access
2. Log into MySQL HeatWave on AWS
3. Create a HeatWave cluster
3. Use database credentials from the database on OCI to log in from the cluster and run analytics

