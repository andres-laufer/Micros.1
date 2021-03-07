;Archivo:		Lab5.s
;Dispositivo:		PIC16F887
;Autor;			Andres Laufer 
;Compilador:		pic-as (v2.31) MPLABX V5.40
;Programa:		contadores en binario, hexadecimal y decimal
;Hardware:		2 Pushbuttons en PORTB, 8 Leds PORTA, 5 7seg en PORTC
;Creado:		2 marzo, 2021
;Ultima modificacion:	6 marzo, 2021
    
PROCESSOR 16F887
#include <xc.inc>

 CONFIG FOSC=INTRC_NOCLKOUT ; Oscilador externo a 1MHz
 CONFIG WDTE=OFF    ; reinicio repetitivo del pic
 CONFIG PWRTE=ON    ; PWRT enabled 
 CONFIG MCLRE=OFF   ; mclr utilizado como I/0
 CONFIG CP=OFF	    ; Sin protección de código
 CONFIG CPD=OFF	    ; Sin protección de datos
 
 CONFIG BOREN=OFF   ; No se reinicia cuando el voltaje baja de 4V
 CONFIG IESO=OFF    ; Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF   ; Cambio de reloj de externo a interno 
 CONFIG LVP=ON	    ; programación en bajo voltaje 
 
 CONFIG WRT=OFF	    ; Protección de autoescritura por el programa desactivada
 CONFIG BOR4V=BOR40V ; Reinicio abajo de 4v
 
;-----------------------------------Variables-----------------------------------

 PSECT udata_bank0 
    Cont_Cent:		DS 1 
    Cont_Dec:		DS 1 
    var:		DS 1
    nibble:		DS 2 
    display_var:	DS 5 
    PORTD_temp:		DS 1 
    
PSECT udata_shr 
    w_temp:	 DS 1
    status_temp: DS 1

 PSECT resVector, class=CODE, abs, delta=2
 ORG 00h	    ;0000h posición del reset 
 
 resetVector:
    PAGESEL main
    goto main
 
   
;-----------------------CONFIGURACIÓN DEL MICROCONTROLADOR----------------------

PSECT intVect, class=CODE,abs, delta=2
ORG 04h
push:			;se guarda W
    movwf w_temp
    swapf STATUS, w
    movwf status_temp

isr:
    btfsc RBIF		
    call  int_OCB		;interrupción de push bottons 
    btfsc T0IF	    
    call  int_tm0		;interrupción del Timer0

pop:				;reset de las banderas y W
    swapf status_temp, w
    movwf STATUS
    swapf w_temp, f
    swapf w_temp, w
    retfie
 

PSECT code, delta=2, abs
ORG 100h
 
 ;tabla para 7 segmentos 
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
    call    config_IO	    ;Inputs para PORTB, Outputs para  PORTA, PORTC Y PORTD
    call    Tm0_config	    ;Timer0 
    call    reloj_config    ;500KHz para el reloj 
    call    config_iocb	    
    call    config_interrup
    banksel PORTA
    clrf    PORTA
    clrf    PORTD
    movlw   3Fh		    
    movwf   PORTC
    
;--------------------------------Displays---------------------------------------
    
    bsf	    PORTD, 0	    ;display 1
    bcf	    PORTD, 0
    bsf	    PORTD, 1	    ;display 2
    bcf	    PORTD, 1
    bsf	    PORTD, 3	    ;display 4
    bcf	    PORTD, 3
    bsf	    PORTD, 4	    ;display 5
    bcf	    PORTD, 4
    bsf	    PORTD, 5	    ;display 6
    bcf	    PORTD, 5 
    
    movlw   01h		    ;valor inicial de la variable 
    movwf   PORTD_temp
    clrf    Cont_Cent	    ;limpieza de W y banderas 
    clrf    Cont_Dec
    
   
;-----------------------------------LOOP PRINCIPAL------------------------------
    
loop:
    call separar_nibbles
    call preparar_display
    call contador_centenas
    goto loop

    
;--------------------------------CONFIGURACIONES--------------------------------
    
config_IO: 
    banksel ANSEL		;pines digitales 
    clrf    ANSEL	    
    clrf    ANSELH
    
    banksel TRISA
    bsf	    TRISB, 0		; PORTB,0,1 como Input 
    bsf	    TRISB, 1
    clrf    TRISA		; PORT A	c y d como outputs 
    clrf    TRISC   
    clrf    TRISD
    bcf	    OPTION_REG, 7	; Se habilitan los Pull Ups 
    bsf	    WPUB, 0		; incrementa
    bsf	    WPUB, 1		; decrementa
    return

Tm0_config:
    banksel TRISA
    bcf	    T0CS		;Se escoje el reloj interno 
    bcf	    PSA			;Prescaler a timer0
    bcf	    PS2
    bsf	    PS1
    bcf	    PS0			;Prescaler a 8
    banksel PORTA
    movlw   125			;Se limpia el timer0
    movwf   TMR0
    bcf	    T0IF
    return

reloj_config:		    ;configuración del reloj a 50Mhz
    banksel TRISA
    bcf	    IRCF2
    bsf	    IRCF1
    bsf	    IRCF0	    
    return

config_interrup:
    banksel TRISA
    bsf	    GIE
    bsf	    RBIE	    ;interrupción en puerto b
    bcf	    RBIF
    bsf	    T0IE	    ;interrupción en Timer0
    bcf	    T0IF   
    return

config_iocb:
    banksel TRISA
    bsf	    IOCB, 0
    bsf	    IOCB, 1
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF    
    return

;--------------------------------INTERRUPCIONES---------------------------------  

int_OCB:		    ;Configuración de botones 
    btfss   PORTB, 0	    ;Push de incremento
    incf    PORTA
    btfss   PORTB, 1	    ;Push de decremento
    decf    PORTA
    bcf	    RBIF	    ;Limpieza de los botones 
    return

int_tm0:		    ;Interrupción del timer 
    banksel PORTA	    
    movlw   125
    movwf   TMR0
    bcf	    T0IF	    
    btfsc   PORTD_temp,0    
    goto    display_1
    btfsc   PORTD_temp,1
    goto    display_2
    btfsc   PORTD_temp,2
    goto    display_4
    btfsc   PORTD_temp,3
    goto    display_5
    btfsc   PORTD_temp,4
    goto    display_6
    
    
;-------------------------------Selección de displays---------------------------
    
display_1:
    clrf    PORTD	    
    movf    display_var, W  
    movwf   PORTC
    bsf	    PORTD, 0	    ;
    goto    next_display
display_2:
    clrf    PORTD
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTD, 1
    goto    next_display
display_4:
    clrf    PORTD
    movf    display_var+2, W
    movwf   PORTC
    bsf	    PORTD, 3
    goto    next_display
display_5:
    clrf    PORTD
    movf    display_var+3, W
    movwf   PORTC
    bsf	    PORTD, 4
    goto    next_display
display_6:
    clrf    PORTD
    movf    display_var+4, W
    movwf   PORTC
    bsf	    PORTD, 5
    goto    next_display
next_display:
	bcf	CARRY
	btfss   PORTD_temp,5	    ;Reset de variables para limpiar displays	    
	goto	$+3
	movlw	01h
	movwf	PORTD_temp
	rlf	PORTD_temp, F	    
	return


    
;------------------------------------LOOP---------------------------------------
	
separar_nibbles:		;se separan los bits significativos 
    movf    PORTA, w
    andwf   0x0f	    
    movwf   nibble+1
    swapf   PORTA, w
    andwf   0x0f	    
    movwf   nibble
    return
    
preparar_display:
    movf    nibble, w
    call    siete_seg	    
    movwf   display_var	    
    movf    nibble+1, w
    call    siete_seg
    movwf   display_var+1   
    return

contador_centenas:
    clrf    Cont_Cent		;Se resetea el counter 
    bcf	    CARRY
    movf    PORTA, w
    movwf   var		    ;el balor W se convierte en variable 
    movlw   100
    subwf   var, F	    
    incf    Cont_Cent
    btfsc   CARRY	    ;Se repite el proceso si no hay overflow 
    goto    $-3
    decf    Cont_Cent	    
    addwf   var		    
    movf    Cont_Cent,w
    call    siete_seg	    
    movwf   display_var+2   
    call    contador_decenas
    return
    
contador_decenas:
    clrf    Cont_Dec		;Se resetea el counter 
    bcf	    CARRY
    movlw   10
    subwf   var			
    incf    Cont_Dec
    btfsc   CARRY		;Se repite el proceso si no hay overflow
    goto    $-3
    decf    Cont_Dec	    
    addwf   var		    
    movf    Cont_Dec,w	    
    call    siete_seg	    
    movwf   display_var+3   
    movf    var, w	    
    call    siete_seg	    
    movwf   display_var+4   
    return  

    
END