; Hardware register definitions

IOBASE 				equ 0x1F80 ; IO segment base

; GPU
GP0 				equ 0x1810 ; also GPUREAD
GP1 				equ 0x1814 ; also GPUSTAT

; CD
CD_STAT				equ 0x1800
CD_CMD				equ 0x1801 ; also response FIFO
CD_DATA				equ 0x1802 ; also parameters
CD_IRQ				equ 0x1803

CD_REG0				equ 0x1800
CD_REG1				equ 0x1801
CD_REG2				equ 0x1802
CD_REG3				equ 0x1803

SBUS_5				equ 0x1018
COM_DELAY			equ 0x1020

; SPU (must be used with 16-bit load/store instructions)
SPU_VOICE_BASE		equ 0x1C00

SPU_MASTER_VOL		equ 0x1D80
SPU_REVERB_VOL		equ 0x1D84
SPU_KEY_ON			equ 0x1D88
SPU_KEY_OFF			equ 0x1D8C
SPU_FM_MODE			equ 0x1D90
SPU_NOISE_MODE		equ 0x1D94
SPU_REVERB_ON		equ 0x1D98
SPU_CHAN_STATUS		equ	0x1D9C

SPU_REVERB_ADDR 	equ	0x1DA2
SPU_IRQ_ADDR		equ 0x1DA4
SPU_ADDR			equ 0x1DA6
SPU_DATA			equ 0x1DA8

SPUCNT				equ 0x1DAA
SPUDTCNT			equ 0x1DAC
SPUSTAT				equ 0x1DAE

SPU_CD_VOL			equ 0x1DB0
SPU_EXT_VOL			equ 0x1DB4
SPU_CURRENT_VOL 	equ	0x1DB8

SPU_VOICE_VOL_L		equ 0x00
SPU_VOICE_VOL_R		equ 0x02
SPU_VOICE_FREQ 		equ 0x04
SPU_VOICE_ADDR		equ 0x06
SPU_VOICE_ADSR_L	equ 0x08
SPU_VOICE_ADSR_H	equ 0x0A		
SPU_VOICE_LOOP		equ 0x0E

; MDEC
MDEC0				equ 0x1820
MDEC1				equ 0x1824

; Pads
JOY_TXRX			equ 0x1040
JOY_STAT			equ 0x1044
JOY_MODE			equ 0x1048
JOY_CTRL			equ 0x104A
JOY_BAUD			equ 0x104E

; Serial
SIO_TXRX			equ 0x1050
SIO_STAT			equ 0x1054
SIO_MODE			equ 0x1058
SIO_CTRL			equ 0x105A
SIO_BAUD			equ 0x105E

; IRQ
ISTAT				equ 0x1070
IMASK				equ 0x1074

; DMA
DPCR				equ 0x10F0     
DICR				equ 0x10F4

D0_MADR				equ 0x1080
D0_BCR				equ 0x1084
D0_CHCR				equ 0x1088

D1_MADR				equ 0x1090
D1_BCR				equ 0x1094
D1_CHCR				equ 0x1098

D2_MADR				equ 0x10A0
D2_BCR				equ 0x10A4
D2_CHCR				equ 0x10A8

D3_MADR				equ 0x10B0
D3_BCR				equ 0x10B4
D3_CHCR				equ 0x10B8

D4_MADR				equ	0x10C0
D4_BCR				equ 0x10C4
D4_CHCR				equ	0x10C8

D6_MADR				equ	0x10E0
D6_BCR				equ 0x10E4
D6_CHCR				equ	0x10E8

; Timers
T0_CNT				equ 0x1100
T0_MODE				equ	0x1104
T0_TGT				equ 0x1108

T1_CNT				equ 0x1110
T1_MODE				equ	0x1114
T1_TGT				equ 0x1118

T2_CNT				equ 0x1120
T2_MODE				equ	0x1124
T2_TGT				equ 0x1128
