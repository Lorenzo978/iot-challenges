/**
 *  @author Manuel Peracci
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	nx_uint16_t counter;
	nx_uint16_t type;
	nx_uint16_t value;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
	AM_MY_MSG = 6,
};


#endif