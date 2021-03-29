;Archivo:		Lab6.s
;Dispositivo:		PIC16F887
;Autor;			Andres Laufer 
;Compilador:		pic-as (v2.31) MPLABX V5.40
;Programa:		Temporizador utilizando Timer1 y Timer2
;Hardware:		2 displays 7 segmentos, led
;Creado:		23 marzo, 2021
;Ultima modificacion:	23 marzo, 2021

    PROCESSOR 16F887
    #include <xc.inc>

    ;configuration word 1
     CONFIG FOSC=INTRC_NOCLKOUT ; Oscilador externo de cristal a 1MHz
     CONFIG WDTE=OFF    ; wdt disables (reinicio repetitivo del pic)
     CONFIG PWRTE=ON    ; PWRT enabled (espera de 72ms al iniciar)
     CONFIG MCLRE=OFF   ; El pin de MCLR se utiliza como I/O
     CONFIG CP=OFF	    ; Sin protección de codigo
     CONFIG CPD=OFF	    ; Sin protección de datos

     CONFIG BOREN=OFF   ; Sin reinicio cuando el voltaje de alimentación baja de 4V
     CONFIG IESO=OFF    ; Reinicio sin cambio de reloj de interno a externo
     CONFIG FCMEN=OFF   ; Cambio de reloj externo a interno en caso de fallo
     CONFIG LVP=ON	    ; programación en bajo voltaje permitida

     ;configuration word 2
     CONFIG WRT=OFF	    ; Protección de autoescritura por el programa desactivada
     CONFIG BOR4V=BOR40V ; Reinicio abajo de 4v, (BOR21V=2.1V)

 
    ;-----------------------VARIABLES----------------------
     PSECT udata_bank0 
	nibble:		DS 2 ; 2 bytes
	display_var:	DS 2 ; 2 bytes
	banderas:		DS 1 ; 1 byte
	banderaTM2:		DS 1 ; 1 byte
	bandera_int:	DS 1 ; 1 byte
	portD_temp:		DS 1 ; 1 byte



    PSECT udata_shr ;memoria compartida
	w_temp:	 DS 1
	status_temp: DS 1

    ;----------------------INSTRUCCIONES VECTOR DE RESET-------------

     PSECT resVector, class=CODE, abs, delta=2
     ORG 00h	    ; posición 0000h para el reset
     resetVector:
	PAGESEL main
	goto main


    ;--------------------CONFIGURACIÓN DEL MICROCONTROLADOR-----------------
    
    PSECT intVect, class=CODE,abs, delta=2
    ORG 04h
    push:			;guardado de banderas y W
	movwf w_temp
	swapf STATUS, w
	movwf status_temp

    isr:
	btfsc T0IF	    
	call  int_tm0	;interrupción del Timer0
	btfsc TMR1IF
	call  int_tm1	;interrupción del Timer1
	btfsc TMR2IF
	call  int_tm2	;interrupción del Timer2

    pop:			;regreso de las banderas y W a su normalidad
	swapf status_temp, w
	movwf STATUS
	swapf w_temp, f
	swapf w_temp, w
	retfie



    PSECT code, delta=2, abs
    ORG 100h
    siete_seg:
	clrf    PCLATH
	bsf	    PCLATH, 0
	andlw   0Fh
	addwf   PCL, F
	retlw   3Fh	    ; 0
	retlw   06h	    ; 1
	retlw   5Bh	    ; 2
	retlw   4Fh	    ; 3
	retlw   66h	    ; 4
	retlw   6Dh	    ; 5
	retlw   7Dh	    ; 6
	retlw   07h	    ; 7
	retlw   7Fh	    ; 8
	retlw   6Fh	    ; 9
	retlw   77h	    ; A
	retlw   7Ch	    ; B
	retlw   39h	    ; C
	retlw   5Eh	    ; D
	retlw   79h	    ; E
	retlw   71h	    ; F

    main:
	call    config_IO	    ;Inputs PORTB, Outputs PORTA, C y D
	call    Tm0_config	    ;Timer0 a 2ms
	call    Tm1_config	    ;Timer1 a 1 segundo
	call    Tm2_config	    ;Timer2 a 250ms
	call    reloj_config    ;500KHz    
	call    config_interrup
	banksel PORTA
	clrf    PORTA
	clrf    PORTD
	clrf    PORTB
	clrf    banderas



    ;----------------------LOOP PRINCIPAL----------------------

    loop:
	call separar_nibbles
	call preparar_display
	goto loop


    ;----------------------------------SUBRUTINAS--------------------


    ;-----------------------CONFIGURACIONES---------------------
    config_IO: 
	banksel ANSEL
	clrf    ANSEL	    ; pines digitales
	clrf    ANSELH

	banksel TRISA
	clrf    TRISB
	clrf    TRISA	    ;Todos los ports son salidas
	clrf    TRISC   
	clrf    TRISD
	return

    Tm0_config:
	banksel TRISA
	bcf	    T0CS	    ;selección del reloj interno
	bcf	    PSA		    ;asignamos prescaler al Timer0
	bcf	    PS2
	bcf	    PS1
	bcf	    PS0		    ;prescaler a 2
	banksel PORTA
	movlw   131		    ;reseteo del Timer0
	movwf   TMR0
	bcf	    T0IF
	return


    Tm1_config:
	banksel PORTA
	bsf	    TMR1ON
	bcf	    TMR1CS
	bsf	    T1CKPS0
	bcf	    T1CKPS1
	movlw   1011B	    ;reset timer1
	movwf   TMR1H
	movlw   11011100B
	movwf   TMR1L
	return


    Tm2_config:
	bsf    TMR2ON	    ;encender el timer2
	bsf    TOUTPS3	    ;postscaler a 16
	bsf    TOUTPS2
	bsf    TOUTPS1
	bsf    TOUTPS0
	bsf    T2CKPS1
	banksel TRISA
	movlw   122
	movwf   PR2
	return


    reloj_config:
	banksel TRISA
	bcf	    IRCF2
	bsf	    IRCF1
	bsf	    IRCF0	    ; reloj a 500KHz 
	return

    config_interrup:
	banksel TRISA
	bsf	    GIE
	bsf	    T0IE	    ;interrupción del timer0
	bcf	    T0IF   
	bsf	    PEIE	    ;habilitar más interrupciones
	bsf	    TMR1IE	    ;interrupción timer1
	bsf	    TMR2IE	    ;interrupción timer2
	banksel PORTA
	bcf	    TMR1IF	    ;limpieza de banderas
	bcf	    TMR2IF
	return

    ;-----------------------INTERRUPCIONES----------------------- 
    int_tm0:
	banksel PORTA	    ;reseteo del Timer0
	movlw   131	
	movwf   TMR0
	bcf	    T0IF	    ;limpieza de bandera

	btfsc   bandera_int,0   ;verificar si los displays deben funcionar normal
	goto    disp_apagado    ;o deben apagarse

	btfsc   banderas,0
	goto    display_1
	btfss   banderas,0
	goto    display_2
    display_1:
	clrf    PORTD	    ;apagar el display seleccionado anteriormente
	movf    display_var, W  ;colocar el valor deseado
	movwf   PORTC
	bsf	    PORTD, 0	    ;enceder el display deseado
	goto    next_display
    display_2:
	clrf    PORTD
	movf    display_var+1, W
	movwf   PORTC
	bsf	    PORTD, 1
	goto    next_display
    next_display:		    ;seleccionador del siguiente display
	movlw   1
	xorwf   banderas, F
	return
    disp_apagado:
	clrf    PORTD	    ;ambos displays apagados para el titileo
	clrf    PORTC
	bsf	    PORTD,0
	bcf	    PORTD,0
	bsf	    PORTD,1
	bcf	    PORTD,1
	return


    int_tm1:
	banksel PORTA
	incf    PORTA	    ;incremento de PORTA
	movlw   1011B	    
	movwf   TMR1H
	movlw   11011100B
	movwf   TMR1L	    ;reset timer1
	bcf	    TMR1IF
	return


     int_tm2:
	btfsc   banderaTM2,0
	goto    encender
	btfss   banderaTM2,0
	goto    apagar
	encender:
	bsf	    PORTB, 0
	goto    sig_estado
	apagar:
	bcf	    PORTB, 0
	goto    sig_estado
	sig_estado:
	movlw   1		    ;cambio de estado entre encedido y apagado
	xorwf   banderaTM2, F
	movlw   1		    ;cambio de estado para displays
	xorwf   bandera_int, F
	bcf	    TMR2IF
	return

    ;-----------------------------LOOP--------------------------
    separar_nibbles:
	banksel PORTA
	movf    PORTA, w
	andlw   0x0f	    ;copiar los bits menos significativos
	movwf   nibble+1
	swapf   PORTA, w
	andlw   0x0f	    ;copiar los bits mÃ¡s significativos
	movwf   nibble
	return

    preparar_display:
	banksel PORTA
	movf    nibble, w
	call    siete_seg	    
	movwf   display_var	 ;colocar el valor del contador en 7 segmentos
	movf    nibble+1, w
	call    siete_seg
	movwf   display_var+1   ;colocar el valor del contador en 7 segmentos
	return

 
END