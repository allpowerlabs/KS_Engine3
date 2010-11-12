void DoFilter() {
  pRatioFilter = (float)Press[P_REACTOR]/(float)Press[P_FILTER];
  pRatioFilterHigh = (pRatioFilter < 0.3 && Press[P_REACTOR] < -200);
  
  // if pressure ratio is "high" for a long time, shake harder
  if (pRatioFilterHigh) {
    filter_pratio_accumulator++;
  } else {
    filter_pratio_accumulator -= 5;
  }
  filter_pratio_accumulator = max(0,filter_pratio_accumulator); // don't let it go below 0
}
