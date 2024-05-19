// Apache V2 License

#ifndef MCPRO_H
	#define MCPRO_H
	
	// MemCard Pro assembly functions
	extern int MemCardPro_Ping(int portnum);
	extern int MemCardPro_SendGameID(int portnum, int maxLen255, char *gameID);
	extern int MemCardPro_NextCH(int portnum);
	extern int MemCardPro_PrevCH(int portnum);
	extern int MemCardPro_NextDIR(int portnum);
	extern int MemCardPro_PrevDIR(int portnum);
	
	// this function should be placed between 'MemCardPro_Ping()' and 'MemCardPro_SendGameID()'
	extern int MemcardPro_InterCommandDelay();
	
	// port values
	#define MCPRO_PORT_1 0
	#define MCPRO_PORT_2 1
	
	// error return values
	#define MCPRO_0_NO_ERROR
	#define MCPRO_1_BUS_SELECT_FAIL
	#define MCPRO_2_OPERATION_FAILED
	#define MCPRO_3_RESERVE_FAIL
	#define MCPRO_4_STRING_LENGTH_OR_SUCCESS_FAIL
	#define MCPRO_5_DATA_TRANSMISSION_FAIL
#endif /* MCPRO_H */