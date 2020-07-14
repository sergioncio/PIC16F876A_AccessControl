		LIST P=16F876A
		include "p16f876a.inc"
		__CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

;Contraseña Usuario 1: 1 2 3 4
;Contraseña Usuario 2: A B C D
;Contraseña Usuario 3: 6 7 8 9

columna			EQU 0x20
n_columna		EQU	0x21
tecla			EQU 0x22
valor_RB		EQU	0x23
n_fila			EQU	0x24
Activado		EQU	0x25
Desactivado		EQU	0x26
Detectado		EQU	0x27
Disparado		EQU	0x28
Cont_10s		EQU	0x29
Cont_15s		EQU	0x2A
Valor_IN		EQU	0x2B
Dato_Recibido	EQU	0x2C
Valor_c			EQU	0x2D
Valor_s			EQU	0x2E
Valor_0			EQU	0x2F
Valor_1			EQU	0x30
Valor_R			EQU	0x31
Valor_S			EQU	0x32
Tecla_Pulsada	EQU	0x33
Dato0			EQU	0x34
Dato1			EQU	0x35
Dato2			EQU	0x36
Dato3			EQU	0x37
Usuario_Valido	EQU	0x38

		ORG	0
		goto	inicio
		ORG	4
		goto 	ISR
		ORG	5

inicio
		MOVLW	'c'
		MOVWF	Valor_c

		MOVLW	's'
		MOVWF	Valor_s

		MOVLW	'0'
		MOVWF	Valor_0

		MOVLW	'1'
		MOVWF	Valor_1

		MOVLW	'R'
		MOVWF	Valor_R

		MOVLW	'S'
		MOVWF	Valor_S

		CLRF	n_fila
		CLRF 	columna
		MOVLW	.4
		MOVWF	valor_RB

		BSF		STATUS, 0
		BSF		STATUS,RP0
		
		BSF 	ADCON1, PCFG0
		BSF 	ADCON1, PCFG1
		BSF 	ADCON1, PCFG2	
		BCF		TRISA,RA0
		BCF		TRISA,RA1
		BCF		TRISA,RA2			
		
		BSF		TRISB,RB0	
		BCF		TRISB,RB1
		BCF		TRISB,RB2
		BCF		TRISB,RB3
		BSF		TRISB,RB4			
		BSF		TRISB,RB5
		BSF		TRISB,RB6
		BSF		TRISB,RB7					
			
		CLRF	TRISC
		BSF		TRISC,RC7
		
		BSF 	INTCON, GIE
		BSF 	INTCON, PEIE
		BSF		INTCON, INTE
		BSF		INTCON, RBIE
		BCF		INTCON, T0IE

		BCF		OPTION_REG,T0CS		;Temporizador
		BCF		OPTION_REG,PSA		;Prescaler al módulo Timer0
		BSF		OPTION_REG,PS2
		BSF		OPTION_REG,PS1
		BSF		OPTION_REG,PS0 		;1:256
		BSF		OPTION_REG,INTEDG	;Interrupción RB0 por flanco ASCENDENTE
		BCF 	OPTION_REG,7		;Habilitar Pull-Up

		BSF		PIE1,RCIE

		BCF		TXSTA,SYNC
		BCF		TXSTA,TX9
		BSF		TXSTA,BRGH
		BSF		TXSTA,TXEN
		MOVLW	.25
		MOVWF	SPBRG
			
		BCF		STATUS,RP0

		BCF		RCSTA,RX9
		BSF		RCSTA,SPEN
		BSF		RCSTA,CREN

		BSF		Activado,0	
		BCF		Desactivado,0
		BCF		Disparado,0
		BCF		Detectado,0

		BCF		PORTA,RA0
		BSF		PORTA,RA1
		BCF		PORTA,RA2

		CLRF	PORTC	
		
main
		GOTO 	main

ISR		
		BTFSC	PIR1,RCIF
		GOTO	Recepcion_USART

		BTFSC	INTCON,INTF
		GOTO	Interrupcion_RB0

		BTFSC	INTCON,T0IF
		GOTO	esperar_15s
		
		BTFSS	PORTB,RB4
		GOTO	Rutina
		BTFSS	PORTB,RB5
		GOTO	Rutina
		BTFSS	PORTB,RB6
		GOTO	Rutina
		BTFSS	PORTB,RB7
		GOTO	Rutina
		GOTO	Salir_Interrupcion

Rutina
        CALL    retardo_30ms
        BCF     INTCON,T0IF

        BTFSC   INTCON,RBIF
        GOTO    Interrupcion_RBIF
        GOTO    Salir_Interrupcion

Salir_Interrupcion
        BCF        INTCON,RBIF
        RETFIE

Interrupcion_RBIF
		BTFSS	PORTB,RB4
		MOVLW	.0
		BTFSS	PORTB,RB5
		MOVLW	.1
		BTFSS	PORTB,RB6
		MOVLW	.2
		BTFSS	PORTB,RB7
		MOVLW	.3
		MOVWF	columna
		CLRW
		ADDWF	columna,0
		MOVWF	n_columna
		
		CALL	identificar_tecla
		
		MOVLW	.0
		SUBWF	Tecla_Pulsada,0
		BTFSS	STATUS,Z			;¿tecla_pulsada = 0?
		GOTO	Comprobar_NDato
		GOTO	Salir_Interrupcion

;RETARDO 15 SEGUNDOS
Retardo_15s	
		BSF		INTCON, T0IE	
		MOVLW	.231
		MOVWF	Cont_15s

bucle_15s
		MOVLW	.2		;65ms	
		MOVWF	TMR0

esperar_15s
		BTFSS	INTCON, T0IF
		RETFIE
		
		BCF		INTCON,T0IF
		DECFSZ	Cont_15s
		GOTO	bucle_15s
		BCF		INTCON, T0IE
		BTFSC	Detectado,0
		GOTO	Estado_Disparado
		RETURN

;RETARDO 10 SEGUNDOS
Retardo_10s	
		BSF		INTCON, T0IE
		CLRF	Usuario_Valido	
		MOVLW	.154
		MOVWF	Cont_10s

bucle_10s
		MOVLW	.2		;65ms	
		MOVWF	TMR0

esperar_10s
		BTFSS	INTCON, T0IF
		GOTO 	esperar_10s
		
		BCF		INTCON,T0IF
		DECFSZ	Cont_10s
		GOTO	bucle_10s
		BCF		INTCON, T0IE
		GOTO	Estado_Activado

;RETARDO 30 MS
retardo_30ms
		BSF		INTCON, T0IE
		MOVLW 	.139
		MOVWF	TMR0

esperar_30ms
		BTFSS	INTCON, T0IF
		GOTO 	esperar_30ms
		BTFSS	Detectado,0
		BCF		INTCON, T0IE
		RETURN	

incrementar_columna
		INCF	valor_RB
		GOTO	continuar

;Rutina identificar tecla
identificar_tecla
		MOVLW	b'1110'
		MOVWF	PORTC

continuar		
		CLRW
		SUBWF	n_columna,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_columna0
		MOVLW	.1
		SUBWF	n_columna,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_columna1
		MOVLW	.2
		SUBWF	n_columna,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_columna2
		GOTO	Comprobar_columna3
	
Comprobar_columna0
		MOVLW	.0
		MOVWF	n_columna
		BTFSC	PORTB,RB4		
		GOTO	tecla_NOpulsada		
		GOTO	tecla_PULSADA

Comprobar_columna1
		MOVLW	.1
		MOVWF	n_columna
		BTFSC	PORTB,RB5		
		GOTO	tecla_NOpulsada		
		GOTO	tecla_PULSADA

Comprobar_columna2
		MOVLW	.2
		MOVWF	n_columna
		BTFSC	PORTB,RB6		
		GOTO	tecla_NOpulsada		
		GOTO	tecla_PULSADA

Comprobar_columna3
		MOVLW	.3
		MOVWF	n_columna
		BTFSC	PORTB,RB7		
		GOTO	tecla_NOpulsada		
		GOTO	tecla_PULSADA

tecla_NOpulsada
		INCF	n_fila,1
		BTFSS	PORTC, RB3
		GOTO 	ultima_fila
		
		RLF		PORTC, 1
		GOTO 	continuar

tecla_PULSADA
		INCF	Tecla_Pulsada,1
		CLRW
		SUBWF	columna,0
		BTFSC	STATUS,Z
		GOTO	columna0
		MOVLW	.1
		SUBWF	columna,0
		BTFSC	STATUS,Z
		GOTO	columna1
		MOVLW	.2
		SUBWF	columna,0
		BTFSC	STATUS,Z
		GOTO	columna2
		GOTO	columna3

columna0
		CLRW
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_1
		MOVLW	.1
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_4
		MOVLW	.2
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_7
		GOTO	tecla_ast

columna1
		CLRW
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_2
		MOVLW	.1
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_5
		MOVLW	.2
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_8
		GOTO	tecla_0

columna2
		CLRW
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_3
		MOVLW	.1
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_6
		MOVLW	.2
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_9
		GOTO	tecla_alm

columna3
		CLRW
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_A
		MOVLW	.1
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_B
		MOVLW	.2
		SUBWF	n_fila,0
		BTFSC	STATUS,Z
		GOTO	tecla_C
		GOTO	tecla_D

tecla_0
		MOVLW	'0'
		MOVWF	tecla
		GOTO	Final

tecla_1
		MOVLW	'1'
		MOVWF	tecla
		GOTO	Final

tecla_2
		MOVLW	'2'
		MOVWF	tecla
		GOTO	Final

tecla_3
		MOVLW	'3'
		MOVWF	tecla
		GOTO	Final

tecla_4
		MOVLW	'4'
		MOVWF	tecla
		GOTO	Final

tecla_5
		MOVLW	'5'
		MOVWF	tecla
		GOTO	Final

tecla_6
		MOVLW	'6'
		MOVWF	tecla
		GOTO	Final

tecla_7
		MOVLW	'7'
		MOVWF	tecla
		GOTO	Final

tecla_8
		MOVLW	'8'
		MOVWF	tecla
		GOTO	Final

tecla_9
		MOVLW	'9'
		MOVWF	tecla
		GOTO	Final

tecla_A
		MOVLW	'A'
		MOVWF	tecla
		GOTO	Final

tecla_B
		MOVLW	'B'
		MOVWF	tecla
		GOTO	Final

tecla_C
		MOVLW	'C'
		MOVWF	tecla
		GOTO	Final

tecla_D
		MOVLW	'D'
		MOVWF	tecla
		GOTO	Final

tecla_ast
		MOVLW	'*'
		MOVWF	tecla
		GOTO	Final

tecla_alm
		MOVLW	'#'
		MOVWF	tecla
		GOTO	Final

ultima_fila
		MOVLW	0xFF
		;MOVWF	tecla
		GOTO	Final

Final			
		MOVLW	b'0000'
		MOVWF	PORTC
		MOVLW 	.4
		MOVWF	valor_RB
		CLRF	n_fila
		
		RETURN

Comprobar_NDato
		MOVLW	.1
		SUBWF	Tecla_Pulsada,0
		BTFSC	STATUS,Z
		GOTO	Guardar_dato0
					
		MOVLW	.2
		SUBWF	Tecla_Pulsada,0
		BTFSC	STATUS,Z
		GOTO	Guardar_dato1		
			
		MOVLW	.3
		SUBWF	Tecla_Pulsada,0
		BTFSC	STATUS,Z
		GOTO	Guardar_dato2	
			
		MOVLW	.4
		SUBWF	Tecla_Pulsada,0
		BTFSC	STATUS,Z
		GOTO	Guardar_dato3

Guardar_dato0
		MOVFW	tecla
		MOVWF	Dato0			
		GOTO	Salir_Interrupcion

Guardar_dato1
		MOVFW	tecla
		MOVWF	Dato1			
		GOTO	Salir_Interrupcion

Guardar_dato2
		MOVFW	tecla
		MOVWF	Dato2			
		GOTO	Salir_Interrupcion

Guardar_dato3
		MOVFW	tecla
		MOVWF	Dato3			
		MOVLW	.0
		MOVWF	Tecla_Pulsada
		GOTO	Validar_Codigo

Validar_Codigo
		MOVLW	'1'
		SUBWF	Dato0,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_Usuario1
			
		MOVLW	'A'
		SUBWF	Dato0,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_Usuario2
			
		MOVLW	'6'
		SUBWF	Dato0,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_Usuario3

Comprobar_Usuario1
		MOVLW	'2'
		SUBWF	Dato1,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'3'
		SUBWF	Dato2,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'4'
		SUBWF	Dato3,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
		GOTO	Codigo_Usuario1

Comprobar_Usuario2
		MOVLW	'B'
		SUBWF	Dato1,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'C'
		SUBWF	Dato2,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'D'
		SUBWF	Dato3,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
		GOTO	Codigo_Usuario2

Comprobar_Usuario3
		MOVLW	'7'
		SUBWF	Dato1,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'8'
		SUBWF	Dato2,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
			
		MOVLW	'9'
		SUBWF	Dato3,0
		BTFSS	STATUS,Z
		GOTO	Codigo_NoValido
		GOTO	Codigo_Usuario3

Codigo_NoValido
		MOVLW	'N'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'O'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	' '
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'V'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'Á'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'L'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'I'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'D'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'O'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx
		GOTO	Salir_Interrupcion

Codigo_Usuario1
		MOVLW	.1
		MOVWF	Usuario_Valido

		MOVLW	'F'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'L'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'O'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'R'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'E'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'N'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'T'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'I'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'N'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'O'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		BTFSC	Detectado,0
		CLRF	Usuario_Valido

		BTFSC	Detectado,0
		GOTO	Estado_Desactivado

		BTFSC	Activado,0
		CLRF	Usuario_Valido

		BTFSC	Activado,0
		GOTO	Estado_Desactivado

		BTFSC	Desactivado,0
		GOTO	Estado_Desactivado
	
		CLRF	Usuario_Valido

		GOTO	Salir_Interrupcion

Codigo_Usuario2
		MOVLW	.1
		MOVWF	Usuario_Valido

		MOVLW	'P'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'E'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'R'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'E'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'Z'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		BTFSC	Detectado,0
		CLRF	Usuario_Valido

		BTFSC	Detectado,0
		GOTO	Estado_Desactivado

		BTFSC	Activado,0
		CLRF	Usuario_Valido

		BTFSC	Activado,0
		GOTO	Estado_Desactivado

		BTFSC	Desactivado,0
		GOTO	Estado_Desactivado
	
		CLRF	Usuario_Valido

		GOTO	Salir_Interrupcion

Codigo_Usuario3
		MOVLW	.1
		MOVWF	Usuario_Valido

		MOVLW	'Z'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'I'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'D'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'A'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'N'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'E'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		BTFSC	Detectado,0
		CLRF	Usuario_Valido

		BTFSC	Detectado,0
		GOTO	Estado_Desactivado

		BTFSC	Activado,0
		CLRF	Usuario_Valido

		BTFSC	Activado,0
		GOTO	Estado_Desactivado

		BTFSC	Desactivado,0
		GOTO	Estado_Desactivado
	
		CLRF	Usuario_Valido

		GOTO	Salir_Interrupcion

;ESTADO ACTIVADO
Estado_Activado
		BSF		Activado,0	
		BCF		Desactivado,0
		BCF		Disparado,0
		BCF		Detectado,0

		BCF		PORTA,RA0
		BSF		PORTA,RA1
		BCF		PORTA,RA2

		MOVLW	's'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'0'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'1'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'R'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		CLRF	Valor_IN

		RETFIE

;ESTADO DETECTADO
Estado_Detectado
		BCF		Activado,0	
		BCF		Desactivado,0
		BCF		Disparado,0
		BSF		Detectado,0

		BCF		PORTA,RA0
		BCF		PORTA,RA1
		BSF		PORTA,RA2
		
		MOVLW	's'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'0'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'1'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'D'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		CLRF	Valor_IN

		RETURN

;ESTADO DISPARADO
Estado_Disparado
		BCF		Activado,0	
		BCF		Desactivado,0
		BSF		Disparado,0
		BCF		Detectado,0

		BSF		PORTA,RA0
		BCF		PORTA,RA1
		BCF		PORTA,RA2

		MOVLW	's'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'0'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'1'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'F'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		CLRF	Valor_IN

		BTFSC	INTCON,RBIF
		BCF		INTCON,RBIF

		RETFIE

;ESTADO Desactivado
Estado_Desactivado
		BCF		Activado,0	
		BSF		Desactivado,0
		BCF		Disparado,0
		BCF		Detectado,0

		BSF		PORTA,RA0
		BSF		PORTA,RA1
		BSF		PORTA,RA2
	
		MOVLW	's'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'0'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'1'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	'S'
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.10
		MOVWF	TXREG
		CALL	Esperar_tx

		MOVLW	.13
		MOVWF	TXREG
		CALL	Esperar_tx

		CLRF	Valor_IN

		BTFSC	Usuario_Valido,0
		GOTO	Retardo_10s

		RETFIE

Esperar_tx
		BTFSS	PIR1,TXIF
		GOTO	Esperar_tx
			
		RETURN

;Rutina Recepcion USART	
Recepcion_USART
		MOVFW	RCREG
		CLRF	Dato_Recibido
		ADDWF	Dato_Recibido,1
		MOVLW	.0
		SUBWF	Valor_IN,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_c
		MOVLW	.1
		SUBWF	Valor_IN,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_s
		MOVLW	.2
		SUBWF	Valor_IN,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_0
		MOVLW	.3
		SUBWF	Valor_IN,0
		BTFSC	STATUS,Z
		GOTO	Comprobar_1
		GOTO	Comprobar_Final	

Comprobar_c
		MOVFW	Dato_Recibido
		SUBWF	Valor_c,0
		BTFSS	STATUS,Z
		GOTO	Salir_Comprobacion
		MOVLW	.1
		MOVWF	Valor_IN
		RETFIE

Comprobar_s
		MOVFW	Dato_Recibido
		SUBWF	Valor_s,0
		BTFSS	STATUS,Z
		GOTO	Salir_Comprobacion
		MOVLW	.2
		MOVWF	Valor_IN
		RETFIE

Comprobar_0
		MOVFW	Dato_Recibido
		SUBWF	Valor_0,0
		BTFSS	STATUS,Z
		GOTO	Salir_Comprobacion
		MOVLW	.3
		MOVWF	Valor_IN
		RETFIE

Comprobar_1
		MOVFW	Dato_Recibido
		SUBWF	Valor_1,0
		BTFSS	STATUS,Z
		GOTO	Salir_Comprobacion
		MOVLW	.4
		MOVWF	Valor_IN
		RETFIE

Comprobar_Final
		MOVFW	Dato_Recibido
		SUBWF	Valor_R,0
		BTFSC	STATUS,Z
		GOTO 	Estado_Activado
		MOVFW	Dato_Recibido
		SUBWF	Valor_S,0
		BTFSC	STATUS,Z
		GOTO 	Estado_Desactivado
		GOTO	Salir_Comprobacion

Salir_Comprobacion
		CLRF	Valor_IN
		RETFIE	

;Sensor de movimiento
Interrupcion_RB0
		BTFSC	Activado,0
		GOTO	Sensor_Detectado
		BCF		INTCON,INTF
		RETFIE

Sensor_Detectado
		CALL	Estado_Detectado
		BCF		INTCON,INTF
		CALL	Retardo_15s
		RETFIE

		END
