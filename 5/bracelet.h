#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct packet_message {
  nx_uint8_t id;
  nx_uint8_t type;
  nx_uint8_t msg[21];
} packet_message_t;

typedef nx_struct packet_message_info {
  nx_uint8_t id;
  nx_uint8_t type;
  nx_uint8_t posx;
  nx_uint8_t posy;
  nx_uint8_t status;
} packet_message_info_t;

#define BROADCAST_PAIRING 1
#define UNICAST_PAIRING 2 
#define UNICAST_INFO 3 

#define CHILD 1
#define PARENT 2 

#define CHILD_2 3
#define PARENT_2 4 

#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
