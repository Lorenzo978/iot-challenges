/**
 * @author Lorenzo Poletti, Manuel Peracci
 * @date   July 27 2022
 */

#define NEW_PRINTF_SEMANTICS
#include "printf.h"	
#include "bracelet.h"

configuration braceletAppC {}
implementation {
  components MainC, braceletC as App, braceletC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as timerBroadcast;
  components new TimerMilliC() as timerInfoChild;
  components new TimerMilliC() as timerMissingChild;
  components ActiveMessageC;
  
  components SerialPrintfC;
  components SerialStartC;
    
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  App.AMControl -> ActiveMessageC;

  App.BroadcastTimer -> timerBroadcast;
  App.ChildTimer -> timerInfoChild;
  App.ParentTimer -> timerMissingChild;
  App.Packet -> AMSenderC;

  
  braceletC -> MainC.Boot;
}

