#################################
#Functions
#################################

#################################
#Recursive peak finding, sorted
#################################
find_peaks <- function(y, peak.threshold, footprint.fraction)
{
  local.max = max(y)
  if (local.max<peak.threshold)
  {
    return(c())
  }
  max.index = which.max(y)
  peaks = c(max.index)
  
  w = length(y)
  
  
  # Descend forward until reach footprint threshold
  i=max.index
  while(i < w  && y[i]>local.max*footprint.fraction)
  {
    i = i + 1
  }
  # start Tracking local min
  local.min = y[i]
  while(i < w)
  {
    i = i + 1
    local.min = min(c(local.min,y[i]))
    
    # Continue until back above the footprint threshold
    if(y[i]>local.min/footprint.fraction)
    {
      # recursively call on the remaining curve
      peaks = c(peaks, i+find_peaks(y[i:w], peak.threshold, footprint.fraction))
      break
    }
  }
  
  
  # Descend backward until reach footprint threshold
  i=max.index
  while(i > 1  && y[i]>local.max*footprint.fraction)
  {
    i = i - 1
  }
  # start tracking local min
  local.min = y[i]
  while(i > 1)
  {
    i = i - 1
    local.min = min(c(local.min, y[i]))
    
    # Continue until back above the footprint threshold
    if(y[i]>local.min/footprint.fraction)
    {
      # recursively call on the remaining curve
      peaks = c(find_peaks(y[0:i],peak.threshold, footprint.fraction), peaks)
      break
    }
  }
  return(peaks)
}


#############################
#Current footprint finding
#############################
find_footprints <- function(y, peaks)
{
  npeaks = length(peaks)
  footprints = rep(0,npeaks-1)
  if(npeaks>1)
  {
    for(i in 1:(npeaks-1))
    {
      footprints[i] =  peaks[i]+which.min(y[peaks[i]:peaks[i+1]])
    }
  }
  return(footprints)
}

###########################
#Current centres
###########################
find_centre <- function(peaks, footprints)
{
  # Centre on centre peak if the number of peaks is odd 
  if(length(footprints)%%2==0)
  {
    return(peaks[length(footprints)/2+1])
  }
  # Centre on centre footprint if the number of footprints is odd
  return(footprints[(length(footprints)+1)/2])
}




####################
# Wrap functions
####################
process_peak <- function(id, reads, min.reads, rel.threshold, abs.threshold, footprint.frac)
{
  r = reads[reads$id==id,]
  centre = 0
  nfootprints=NA
  footprint.pos = NA
  nreads = nrow(r)
  
  d = density(r$pos)
  if(nreads >= min.reads)
  {
    threshold = max(c(abs.threshold, max(d$y)*rel.threshold))
    peaks = find_peaks(d$y, threshold, footprint.frac)
    footprints = find_footprints(d$y, peaks)
    nfootprints = length(footprints)
    if (nfootprints>0)
    {
      footprint.pos = round(d$x[footprints])
    }
    centre = round(d$x[find_centre(peaks, footprints)])
  }
  
  return(data.frame(id, centre, nfootprints, footprint.pos, nreads))
}