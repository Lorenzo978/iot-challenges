// $Id: BlinkC.nc,v 1.6 2010-06-29 22:07:16 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include "Timer.h"
#include "printf.h"	
module prova @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
   int q[20];
   uint32_t cdp;
   int count = 0;
   int count_event; 
   int temp;
   int i;
   uint8_t led0 = 0x01;
   uint8_t led1 = 0x02;
   uint8_t led2 = 0x04;
   uint8_t state = 0x00;

  event void Boot.booted()
  {
  	//print the initial state
	for (i = 2; 0 <= i; i--) {
		printf("%c", ((state)  & (1 << i)) ? '1' : '0');
		if(i!=0){
			printf(",");
		}else{
			printf("\n");
		}
			
	  }
	for (cdp = 10824742; cdp != 0; cdp = cdp/3) {
   		q[count] = cdp % 3;
   		//printf("count: %d, rest:%d, ",count,q[count]);
   		//printf("personal code:%ld \n",cdp);
   		count++;
	}

    count_event = 0;
    call Timer0.startPeriodic( 1000 );
    //printf("ehi %u \n",call Leds.get());
    printfflush();
  }

  event void Timer0.fired()
  {

    if(count_event < count){

    	temp = q[count -1 - count_event];

    	//printf("count_event: %d, led: %d\n",count_event,temp);
		
    	if(temp == 2){
    		call Leds.led2Toggle();
 			state = state ^ led2;
    	}
    	else if(temp == 1){
    		call Leds.led1Toggle();
			state = state ^ led1;
    	}
    	else{
    		call Leds.led0Toggle();
			state = state ^ led0;
    	}
    	
    	for (i = 2; 0 <= i; i--) {
			printf("%c", ((state)  & (1 << i)) ? '1' : '0');
			if(i!=0){
				printf(",");
			}else{
				printf("\n");
			}
				
		  }

    	count_event++;
   	 	printfflush();
    }else{
    	call Timer0.stop();
    }
  }

}
