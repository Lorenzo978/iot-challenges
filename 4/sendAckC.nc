/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Manuel Peracci
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
	//interface for timer
    //other interfaces, if needed
	
	//interface used to perform sensor reading (to get the value from a sensor)
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
	interface Read<uint16_t>;
	interface PacketAcknowledgements as Pack;
  }

} implementation {

  uint8_t x = 2 + 1;
  uint8_t y = 24;
  uint8_t counter = 0;
  uint8_t counter_transm = 0;
  double temp;
  message_t packet;

  void sendReq();
  void sendResp();
  
    //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call AMControl.start();
  }


  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err){
    if (err == SUCCESS) {
      dbg("radio","Radio on on node %d!\n", TOS_NODE_ID);
    }
    else {
      dbg("radio","Radio didn't start?\n");
      call AMControl.start();
    }
    if(TOS_NODE_ID == REQ){ //REQ = sender = 1, RESP = receiver = 2
    	call MilliTimer.startPeriodic(1000);
    }
  }
  
  event void AMControl.stopDone(error_t err){

    if (err == SUCCESS) {
       dbg("radio","Radio is successfully off\n");
    }
    else {
       dbg("radio","Radio is not off\n");
    }
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	 dbg("init","-------------------------timer is on fire yeaahh\n");
	 counter++;
	 dbg("init","coutner:%hu, counter_transm: %hu \n",counter,counter_transm );
	 if(counter_transm < x){
	 	sendReq();
	 }else{
	 	call MilliTimer.stop();
	 }
	 
  }
  

  //***************** Send request function ********************//
  void sendReq() {

	 /* X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 my_msg_t* rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
     rcm->counter = counter;
     rcm->type = TOS_NODE_ID; 
     rcm->value = 0;
     if (rcm == NULL) {
		return;
     } 
     if(counter_transm < x){
     	 call Pack.requestAck(&packet);
		 if (call AMSend.send(RESP, &packet, sizeof(my_msg_t)) == SUCCESS) {
			dbg("radio_send", "Sending packet\n");	
		 }
	 }else if(counter_transm == x){
	 	 counter++;
	 	 rcm->counter = counter;
	 	 call Pack.requestAck(&packet);
	 	 if (call AMSend.send(RESP, &packet, sizeof(my_msg_t)) == SUCCESS) {
			dbg("radio_rec", "final ack\n");
		 }
	 }

     //dbg("radio_send", "End of send\n");
}

 
  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
     call Read.read();
      
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 my_msg_t* rcm;
	 
	 temp = ((double)data/65535)*100;
	 dbg("radio_rec","temp read done %f\n",temp);
	 
	 rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
	 rcm->counter = counter;
     rcm->type = TOS_NODE_ID; 
     rcm->value = (uint16_t)temp;
     if (rcm == NULL) {
		return;
     } 
     if(counter_transm < x && call Pack.requestAck(&packet)==SUCCESS){
			 if (call AMSend.send(REQ, &packet, sizeof(my_msg_t)) == SUCCESS) {
				dbg("radio_rec", "Answering packet\n");	
			 }
	 }

}

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer according to your id. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if(&packet == buf){
		 //dbg("radio_rec","bool: %d\n", call Pack.wasAcked(&packet));
	     if(call Pack.wasAcked(&packet)==1){
		 	//dbg("radio_send","transmitted packet was acknowledged\n");
		 	counter_transm++;
		 	dbg("radio_rec","the counter for ack is: %hu\n", counter_transm);
		 	if (counter_transm == x && TOS_NODE_ID == REQ){
		 		call MilliTimer.stop();
		 		dbg("radio_send","----------------------------------stopping the timer\n");
		 		
		 	}
		 }else if(counter_transm < x){
		 	dbg("radio_send","packet not acked\n");
		 	//sendReq();
		 }else{
		 	dbg("radio_send","we have a problem\n");
		 }
	  }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if(len == sizeof(my_msg_t) ) {
		my_msg_t* pay = (my_msg_t*)payload;
		dbg("radio_rec", "counter: %hu\n", pay->counter);
		dbg("radio_rec", "type: %hu\n", pay->type);
		dbg("radio_rec", "value: %hu\n", pay->value);
		if ( pay->type == REQ && TOS_NODE_ID == RESP && counter_transm < x){
			counter = pay->counter;
			sendResp();
		}else if( pay->type == RESP && TOS_NODE_ID == REQ && counter_transm == x){
			
			dbg("radio_rec", "final ack\n");
			sendReq();
		}
	  }
	    	  
	//dbg("radio_rec", "it's time to receive\n");
	return buf;
  }
  


}