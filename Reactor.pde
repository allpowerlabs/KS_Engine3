void DoFlare() {
  if (Press[P_REACTOR] < -50) {
    analogWrite(FET_FLARE,255);
  } else {
    analogWrite(FET_FLARE,0);
  }
}

//void DoReactor() {
//  switch (reactor_state) {
//    case REACTOR_OFF:
//      break;
//    case REACTOR_IGNITING:
//      break;
//    case REACTOR_WARMING:
//      break;
//    case REACTOR_COOLING:
//      break;
//    case REACTOR_WARM:
//      break;
//  }
//}
//  
