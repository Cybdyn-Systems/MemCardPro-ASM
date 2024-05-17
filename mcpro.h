// Apache V2 License


#ifndef MCPRO_H
#define MCPRO_H

//
// Asm functions
//

extern int MemCardPro_Ping(int port01);
extern int MemCardPro_SendGameID(int port01, int maxLen255, char *gameID);

extern int MemCardPro_NextCH(int port01);
extern int MemCardPro_PrevCH(int port01);
//extern int MemCardPro_NextDir(int port01);
//extern int MemCardPro_PrevDir(int port01);

//
// Errors:
//

#define MCPRO_0_NO_ERROR
#define MCPRO_1_BUS_SELECT_FAIL
// e.g no ping response, failed to change channel, etc.
#define MCPRO_2_OPERATION_FAILED
#define MCPRO_3_RESERVE_FAIL
#define MCPRO_4_STRING_LENGTH_FAIL
#define MCPRO_5_DATA_TRANSMISSION_FAIL

#define MCPRO_PORT_0 0
#define MCPRO_PORT_1 1

#endif /* MCPRO_H */