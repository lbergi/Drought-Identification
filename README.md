---
title: "Calling the Drought Function"
author: "Lisa Berghäuser"
date: "19 November 2018"
output: html_document
---

## Introduction
Here I share a function that identifies extremes of data (i.e. droughts via soilmoisture) stored in NetCDF files with a percentile and a monthly duration using R.

I wrote the code while working with the ISIMIP group at the Potsdam Institute for Climate Impact Research (PIK, see <https://www.pik-potsdam.de/>). It identifies droughts via rootmoisture with a 90th percentile and a seven month duration, using the output data of the ISIMIP2a framework (see <https://www.isimip.org/protocol/#isimip2a>). 

The code first identifies the driest single months in the available time period of the NetCDF file, defined with a 90th percentile threshold. Afterwards, it checks whether seven consecutive identified months appear in a row. If so, the year in the specific grid is marked as a drought year with 1, else it is marked with 0. Consequently, the result data is a binary NetCDF file with occuring extreme years.

The function can be used to identify extremes in any other data in NetCDF format. 

## Parameters of the Function 
You can change the extreme event definition by adjusting the parameters of the **DroughtFunction**. 

**datapath**, **emptyfile**, **datafile**, **startyear**, **endyear** and **outputfile** are the mandatory input parameters to the function. **duration**, **SpDY** and **percentile** are optional. 

**datapath** is the path to the NetCDF data containing the data that you want to analyse (**datafile**) and **emptyfile**. 
Enter the name of the data file to **datafile**, e.g. **datafile = "rootmoisture.nc"**. Give a NetCDF file with the same extent and resolution as the datafile but with empty cells in **emptyfile** and store it in **datapath**. I used the software cdo ( see <https://code.mpimet.mpg.de/projects/cdo/embedded/cdo.pdf>) to create this from one of my **datafile**s. The **emptyfile** provides the cells where the results can be saved. **startyear** and **endyear** mark the time frame that the NetCDF file provides. The default is 1971 and 2010.

Please give a file name of type rds including a file path in **outputfile**. If no path is given, the outputfile will be saved in the current working directory. Ask for that with **getwd()** if in doubt. 

**duration** sets the number of consecutive months that define your drought. The default is 7 months. **SpDY** means "Splitted Drought Year" and sets the number of months that must be in a drought year if the consecutive drought months extend two years. As the default of the duration is 7, the default here will be 4, respectively. **percentile** defines the threshold to identify the driest months. The default is 90.

## Run the Function
Please load the **raster** package. With **source()** you can load the function script. Make sure to adjust the right paths. 
Then call the function. The result is saved in the working environment as **Resultbrick** and as rds object that you defined in **outputfile**. Saving the data as rds objects faciliates working further in R. Feel free to save the output as NetCDF if you are interested in the direct function output as final result or want to use other software from now on. 

Here is an example of how to run the function: 
```{r eval=FALSE}
library(raster)
source("Drought_Function.R")

Resultbrick <- DroughtFunction(datapath  = "/user/Data/ ", 
                               emptyfile = "Emptyfile.nc", 
                               datafile  = "Datafile.nc",
                               startyear = 1971,
                               endyear = 2010,
                               outputfile = "Droughts_From_Data.rds")
```
