#include "Timer.h"
#include "bracelet.h"
#include "printf.h"	
#include <string.h>
#include <stdlib.h>
 
/**
 * @author Lorenzo Poletti, Manuel Peracci
 * @date   July 27 2022
 */

module braceletC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as BroadcastTimer;
    interface Timer<TMilli> as ChildTimer;
    interface Timer<TMilli> as ParentTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  int random; 
  
  char key[21]; 
  char received_key[21];
  
  uint8_t status;
  uint8_t TOS_sender; 
  uint8_t msg[21];
  
  message_t packet;
 
  bool locked, locked_key = FALSE;
  int i;
  
  packet_message_t* rcm;
  packet_message_info_t* rcm2;
 
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
//////// Booting
event void Boot.booted() {
    
    printf("Booting\n");
	printfflush();
	
	if(TOS_NODE_ID == 1 || TOS_NODE_ID == 2){   // motes 1 and 2 have the same key
    	strcpy(key, "98765432109876543210");
	}else{										// motes 3 and 4 have the same key, different from the previous one
	  	strcpy(key, "01234567890123456789");	
	}
	
	for (i = 0; i < 21; i++){
		msg[i] = (uint8_t)key[i];
	}
	
	call AMControl.start();  //start the radio
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// StartDone Radio
event void AMControl.startDone(error_t err) {

    if (err == SUCCESS) {  
      call BroadcastTimer.startPeriodic(1000);  //start a periodic timer for broadcasting
      //printf("Broadcast timer started\n");      	
    }else{
      call AMControl.start();
      printf("Restart Radio\n");
    }
    printfflush();
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// StopDone Radio
event void AMControl.stopDone(error_t err) {
  	//printf("Stop Radio");
    // do nothing
}
  
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// BroadcastTimer firing 
event void BroadcastTimer.fired() {
  
    if (locked) {
      return;
    }else {

      rcm = (packet_message_t*)call Packet.getPayload(&packet, sizeof(packet_message_t));
      
      if (rcm == NULL) {
      	//printf("rcm is null\n");
		return;
      }

      strcpy((char*)rcm->msg,(char*)msg);		  
      rcm->id = TOS_NODE_ID;					 
      rcm->type = BROADCAST_PAIRING;
      
      //printf("broadcast: tos_sender %d, type: %d\n",TOS_NODE_ID,rcm->type);
      
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(packet_message_t)) == SUCCESS) {	
		locked = TRUE;
      }else{
      	//printf("problems with firing\n");
      }
    }
    //printfflush();
}

  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// ChildTimer firing
event void ChildTimer.fired() {
  
	rcm2 = (packet_message_info_t*)call Packet.getPayload(&packet, sizeof(packet_message_info_t));
	
	if (rcm2 == NULL) {
		//printf("rcm2 is null\n");
		return;
	}
	  
	random = (rand() % 10 + 1);
	
	if(random == 10){
		status = FALLING;
	}else if(7 <= random && random <= 9){
		status = STANDING;
	}else if(4 <= random && random <= 6){
		status = WALKING;
	}else if(1 <= random && random <= 3){
		status = RUNNING;
	} 

	rcm2->id = TOS_NODE_ID;
	rcm2->type = UNICAST_INFO;
	rcm2->posx = (nx_uint8_t)(rand() % 100 + 1);
	rcm2->posy = (nx_uint8_t)(rand() % 100 + 1);
	rcm2->status = (nx_uint8_t)status;

	//printf("info fires: tos_sender %d, tos_receiver: %d, type: %d, status: %d, posX: %d, posY: %d, \n",TOS_NODE_ID,TOS_sender,rcm2->type,rcm2->status,rcm2->posx,rcm2->posy);
	
	if (call AMSend.send(TOS_sender, &packet, sizeof(packet_message_info_t)) == SUCCESS) {	
		locked = TRUE;
	}else{
		//printf("problems with info firing\n");
	}
	//printfflush();
}
  
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// ParentTimer firing
event void ParentTimer.fired() {

	printf("MISSING CHILD!!!!!\n");																		// MISSING alarm
	
	call ParentTimer.startOneShot(60000);
	
	printfflush();
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// Receive Packet Event
event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
	   
	rcm = (packet_message_t*)payload;
	
	if(rcm->type == BROADCAST_PAIRING){	  									  // Receiving BROADCAST packets for pairing
	 
	 	rcm = (packet_message_t*)payload;
	 	//printf("broadcast_pairing received\n");
		
		if(!strncmp((char*)rcm->msg,key,sizeof(key)) && !locked_key){     						// Checking the same key
				
			locked_key = TRUE;
			//printf("Same key\n");
			
			strcpy(received_key,(char*)rcm->msg);
			TOS_sender = rcm->id;
				
		    rcm = (packet_message_t*)call Packet.getPayload(&packet, sizeof(packet_message_t));
		    
			if (rcm == NULL) {
				//printf("rcm is null\n");
			 	return bufPtr;
			}
			
			rcm->type = UNICAST_PAIRING;
			strcpy((char*)rcm->msg,(char*)msg);
			rcm->id = TOS_NODE_ID;
			
			//printf("unicast: tos_sender %d, tos_receiver %d. type: %d\n",TOS_NODE_ID,TOS_sender,rcm->type);
			if (call AMSend.send(TOS_sender, &packet, sizeof(packet_message_t)) == SUCCESS) {	
			  locked = TRUE;
			  call BroadcastTimer.stop();
			}else{
			  //printf("problems with fire\n");
			}
			
			if(TOS_NODE_ID == CHILD || TOS_NODE_ID == CHILD_2){	    // if you are the child start the timer to send INFO
				//printf("Child info start\n");
				call ChildTimer.startPeriodic(10000);
			}else{
				//printf("Parent timer\n");
				call ParentTimer.startOneShot(60000);		   // if you are the parent start the timer to check MISSING
			}
		}
	}else if(rcm->type == UNICAST_PAIRING){  			 						// Receiving UNICAST packets for pairing
	
		rcm = (packet_message_t*)payload;
		
		printf("Unicast_pairing received\n");
		
		if(!strncmp((char*)rcm->msg,key,sizeof(key)) && !locked_key){  // Checking the same key also on the other device
			
			locked_key = TRUE;
			printf("Same key\n");
			
			TOS_sender = rcm->id;
			strcpy(received_key,(char*)rcm->msg);
			call BroadcastTimer.stop();
			
			if(TOS_NODE_ID == CHILD || TOS_NODE_ID == CHILD_2){
				printf("Child info start\n");
				call ChildTimer.startPeriodic(10000);
			}else{
				printf("Parent timer\n");
				call ParentTimer.startOneShot(60000);         // Starting again the ParentTimer. It will fire after 1 min
			}
		}
		printf("locked:%d, locked_key:%d\n",locked,locked_key);
		
	}else if(rcm->type == UNICAST_INFO ){							             	// Receiving UNICAST packets for INFO
	
		call ParentTimer.stop();	
		rcm2 = (packet_message_info_t*)payload;
		
		if(rcm2->status == FALLING){
			printf("WATCH OUT!!!!!!! YOUR CHILD IS FALLLING!!!!!\n"); 					                 // FALLING alarm
			printf("your child is here: posX %d, posY %d\n",rcm2->posx,rcm2->posy);
		}else{
			//printf("receiverID: %d, senderID: %d\n",TOS_NODE_ID,rcm2->id);
			printf("Status: %d, PosX: %d, PosY: %d\n",rcm2->status,rcm2->posx,rcm2->posy);					 //child INFO 
		}
		call ParentTimer.startOneShot(60000);           	  // Starting again the ParentTimer. It will fire after 1 min
		
	}else{
		//printf("Problems in receiving. type: %d\n",rcm->type);	
	}
    printfflush();
    return bufPtr;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// SendDone Packet Event
event void AMSend.sendDone(message_t* bufPtr, error_t error) {
  
    if (&packet == bufPtr) {
      locked = FALSE;
    }
}

}



