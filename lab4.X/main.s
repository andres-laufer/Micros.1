;-------------------------------------------------------------------------------
    ;Archivo:	  main.s
    ;Dispositivo: PIC16F887
    ;Autor: Andres Laufer
    ;Compilador: pic-as (v2.30), MPLABX V5.45
    ;
    ;Programa: Interrupt-on-change del PORTB
    ;Hardware: 2 Displays 7 Seg, Push Buttom, Leds, Resistencias. 
    ;
    ;Creado: 23 feb, 2021
    ;Última modificación: 27 feb, 2021
;-------------------------------------------------------------------------------

PROCESSOR 16F887
    #include <xc.inc>
    
  CONFIG FOSC=INTRC_NOCLKOUT	//oscilador interno
  CONFIG WDTE=OFF   // WDT disabled (reinicio repetitivo de pic)
  CONFIG PWRTE=ON   // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF  // El pin de MCLR se utiliza como I/O
  CONFIG CP=OFF    //Sin protección de código
  CONFIG CPD=OFF   //Sin protección de datos
  
  CONFIG BOREN=OFF  // Sin reinicio cuando el voltaje de alimentación baja de 4V
  CONFIG IESO=OFF   //Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF  //Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=ON	    //programación en bajo voltaje permitida
  
; configuration word 2
   CONFIG WRT=OFF  //Protección de autoescritura por el programa desactivada
   CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V, (BOR21V-2.1V)
   
UP    EQU 0
DOWN  EQU 1
  
PSECT udata_bank0   
  cont:         DS 2  
  var:		DS 1
    
;variables
PSECT udata_shr
  W_TEMP:	DS 1	    
  STATUS_TEMP:  DS 1

PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
;-----------vector interrupt--------------;
ORG 04h     ;posicion 0004h para las interrupciones
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    btfsc   RBIF
    call    int_iocb
    btfss   T0IF
    call    T0_int
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

int_iocb:
    banksel PORTA
    btfss   PORTB, UP
    incf    PORTA
    btfss   PORTB, DOWN
    decf    PORTA
    movf    PORTA, w	    
    call    tabla_
    movwf   PORTC
    bcf	    RBIF
    return
T0_int:
    call    reinicio_tmr0           ;50ms
    incf    cont
    movf    cont, W
    sublw   10
    btfss   ZERO       ; STATUS, 2
    goto    $+2
    clrf    cont	;500 ms
    return
    
    
PSECT code, delta=2, abs
ORG 100h    ; posicion para le codigo
 tabla_:
 clrf    PCLATH
 bsf	 PCLATH, 0
 ANDLW	 00001111B
 ADDWF   PCL		    
 RETLW   00111111B	    ; 0	    
 RETLW   00000110B	    ; 1	  
 RETLW   01011011B	    ; 2	  
 RETLW   01001111B	    ; 3	    
 RETLW   01100110B	    ; 4	    
 RETLW   01101101B	    ; 5	  
 RETLW   01111101B	    ; 6
 RETLW   00000111B	    ; 7
 RETLW   01111111B	    ; 8
 RETLW   01100111B	    ; 9
 RETLW   01110111B	    ; A
 RETLW   01111100B	    ; b
 RETLW   00111001B	    ; c
 RETLW   01011110B	    ; d
 RETLW   01111001B	    ; E
 RETLW   01110001B	    ; F
 return
    

	
main:
   
    banksel ANSEL	
    clrf    ANSEL	; unicamente puertos digitales
    clrf    ANSELH
    
    banksel TRISA	
    bcf	    TRISA, 0	; configuracion de los bits para leds
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    
    bsf	    TRISB, UP	;configuracion de pines para buttoms 
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    movlw   00000000B
    movwf   TRISD	;se configura el pin de salida del led de alarma
    
    call    reloj	;se llama al reloj 
    call    config_ioc	;se llama a nuestro timer 0
    call    int_enable
    call    timer0
    
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    var


loop:
    btfss   T0IF	;sumar cuando el timer0 llegue a overflow
    goto    $-1
    call    reinicio_tmr0 ;regresa el overflow a 0
    incf    var
    movf    var, w
    call tabla_
    movwf   PORTD
    goto loop		; sigue en el loop
  
       
    
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return
    
reloj:
    BANKSEL    OSCCON
    bcf	    OSCCON, 3	    ; Oscilador interno a 500Khz
    bsf	    OSCCON, 4
    bsf	    OSCCON, 5
    bcf	    OSCCON, 6
    return
    
timer0:
    BANKSEL    OPTION_REG
    bcf	    T0CS
    bcf	    T0SE            ; Condifuración del TMR0 con prescaler 256
    bcf	    PSA
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0      
    banksel PORTA
    return

reinicio_tmr0:
    movlw   61	    ;valor incial del timer0
    movwf   TMR0    
    bcf	    T0IF    ;vuelve 0 al bit de overflow
   
    return

int_enable:
    bsf	    GIE     ;INTCON
    bsf	    RBIE
    bcf	    RBIF
    return
    
END




