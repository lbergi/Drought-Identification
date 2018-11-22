# Drought Function 

DroughtFunction <- function(
  # the path to the rootmoisture data (NetCDF file)
  datapath = "", 
  #  a NetCDF file with the same extent and resolution as the datapath-file but with empty cells                         
  emptyfile = "", 
  # The name of the rootmoisture file                        
  datafile = "", 
  startyear, 
  endyear,
  # the number of consecutive months that define a drought, default is 7           
  duration = 7, 	
  # "Splitted Drought Year" - number of months that must be in a drought year if the      
  # consecutive drought months extend two years, default is 4
  SpDY = 4, 		
  # percentile that defines the threshold to identify the driest years, default is 90
  percentile = 90, 
  outputfile = ""
  ){
  
  Rootmoisturefile = paste0(datapath,datafile)
  duration = duration 
  percentilefF = (100-percentile)/100
  
  ### 1 read data 
  RootmoisBrick <- brick(Rootmoisturefile)
  names(RootmoisBrick) = paste( "Rootmoisture", 
                                outer( 1:12, startyear:endyear, paste, sep="-" ), 
                                sep = "-" )
  print( "datafile loaded." )
  
  ### 2 get the percentiles 
  month = c(1:12)
  Monate = format(ISOdate(2004,1:12,1),"%B")
  Unlistmonth <- unlist(rep(Monate,40))
  years <- unlist(lapply(X = c(startyear:endyear), FUN = function(x) {rep(x,12)}))
  dates <- (as.Date(paste(years, 1:12, 1,sep = "-")))
  seasons = data.frame(month,Unlistmonth)
  Dates = cbind(dates, seasons)
  if ( !exists( "season_percentile")){
    season_percentile <-  stack()
    for (i in Monate){
      season_percentile <- stack(season_percentile, 
                                 overlay( RootmoisBrick[[ which( Dates$Unlistmonth == i )]],
                                          fun = function(x) { quantile(x,
                                                                       probs = percentilefF,
                                                                       na.rm=TRUE ) } ) ) }
    names(season_percentile) = Monate
    print( paste0( percentile, "th monthly percentile estimated."))
  }
  
  # 3 check if the months are below the percentile threshold, save as binary brick
  if( !exists( "Binarybrick") ){
    for ( j in c(1:40) ){
      for ( i in c(1:12) ){
        if(exists("Binarybrick")){
          Binarybrick[[i+((j-1)*12)]] <- RootmoisBrick[[i+((j-1)*12)]] < season_percentile[[i]]
        } else {
          Binarybrick <- brick(RootmoisBrick[[i+((j-1)*12)]] < season_percentile[[i]])
        }
      }
    }
  }
  print( "Monthly values checked for percentile threshold." )
  
  ### 4 get indizes to loop (omit NA or grids with no more than 6 drought months to save computing time)
  Binarybricksum <- sum( Binarybrick )
  ArrayFromBrick <- as.array( Binarybricksum )
  PairsToOmit <- matrix(NA, nrow = 360*720, ncol = 2)
  PairsToLoop <- matrix(NA, nrow = 360*720, ncol = 2)
  Index = 1
  for (i in c( 1: dim( Binarybrick )[ 1 ])){ 
    for( j in c( 1: dim( Binarybrick )[ 2 ])){
      PairsToLoop[Index,] <- c(i,j)
      if(is.na(ArrayFromBrick[i,j,1])){
        PairsToOmit[Index,] <- c(i,j)
      }
      if(!is.na(ArrayFromBrick[i,j,1])){
        if(ArrayFromBrick[i,j,1] <= 7){
          PairsToOmit[Index,] <- c(i,j)
        } else {  }
      }
      Index = Index +1 
    }
  }
  Indizes = which(!is.na(PairsToOmit))
  
  ### 5 count the dry month and transform them to drought years
  empty.raster <- raster(paste0(datapath,emptyfile))
  emptybrick <- brick(empty.raster)
  for ( i in c(1:(endyear-startyear))){
    emptybrick <- stack(emptybrick, empty.raster)
  }
  Emptybrick <- brick(emptybrick)
  Yearnames <- format(ISOdate(startyear:endyear,1,1), "%Y")
  names(Emptybrick) <- Yearnames
  print("Emptyraster buildt")
  Yearvector <- c(startyear:endyear)
  Names <- unlist( lapply( X = c( startyear:endyear ), FUN = function(x) {rep(x,12)}))
  Index = 1
  for ( grid1 in c( 1: dim( Binarybrick )[ 1 ]) ){
    for ( grid2 in c( 1: dim( Binarybrick )[ 2 ])){
      if( Index %in% Indizes){
        # do nothing
      } else {
        TS.grid <- (Binarybrick[[1:480]][grid1,grid2])
        # form binaryvector:
        TS.grid[ TS.grid == FALSE ] = 0
        TS.grid[ TS.grid == TRUE ] = 1
        binaryvector <- as.vector(unname(unlist(TS.grid)))
        names(binaryvector) <- Names
        for (i in c( 1:( length( binaryvector ) - duration ) ) ){
          Summe = binaryvector[ i:(i+duration-1) ]
          if( sum( is.na( Summe ) == duration)){
            Whichyear <- which( unique(names( Summe )[1]) == Yearvector)
            Emptybrick[[ Whichyear ]][ grid1,grid2 ] <- NA}
          if( sum( Summe, na.rm = T ) == duration){
            if(length(unique(names(Summe)))>1){
              Year1 <- Summe[ names(Summe) == names( Summe[1] )]
              Year2 <- Summe[ names(Summe) == names( Summe[2] )]
              if (sum(Year1) >= SpDY ){
                Whichyear <- which( unique( names( Year1 )) == Yearvector)
                Emptybrick[[ Whichyear ]][ grid1,grid2 ] <- 1
              }
              if (sum(Year2) >= SpDY ){
                Whichyear <- which( unique( names( Year2 )) == Yearvector)
                Emptybrick[[ Whichyear ]][ grid1,grid2 ] <- 1
            }
            } else {
              Whichyear <- which(unique(names(Summe)) == Yearvector)
              Emptybrick[[Whichyear]][grid1,grid2] <- 1
            }
          }
        }
      print(paste0("Drought analysed for 480 time steps for grid ", grid1, " and ",grid2))
      }
    Index = Index + 1  
    }
  }

  ### 6 save the result 
  saveRDS(object = Emptybrick, file = outputfile)
  print( "Droughts estimated." )
  return(Emptybrick)
} #EOF