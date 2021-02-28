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
 andlw	 00001111B
 addwf   PCL		    ; El valor del PC se suma con lo que haya en w para
 retlw   00111111B	    ; 0	    ir a la linea respectiva de cada valor
 retlw   00000110B	    ; 1	    El and es para asegurar que el valor que 
 retlw   01011011B	    ; 2	    entre sea unicamente de 4 bits.
 retlw   01001111B	    ; 3	    Con el retlw regresa a al respectivo módulo
 retlw   01100110B	    ; 4	    y lo traslada al puerto A, que es donde
 retlw   01101101B	    ; 5	    está el display.
 retlw   01111101B	    ; 6
 retlw   01000111B	    ; 7
 retlw   01111111B	    ; 8
 retlw   01100111B	    ; 9
 retlw   01110111B	    ; A
 retlw   01111100B	    ; b
 retlw   00111001B	    ; c
 retlw   01011110B	    ; d
 retlw   01111001B	    ; E
 retlw   01110001B	    ; F
 return
    

	
main:
   
    banksel ANSEL	; 
    clrf    ANSEL	; unicamente puertos digitales
    clrf    ANSELH
    
    banksel TRISA	; 
    bcf	    TRISA, 0	; Los primeros cuartos bits serán los outputs 
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    
    bsf	    TRISB, UP	;se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    movlw   00000000B
    movwf   TRISD	;se configura el pin de salida del led de alarma
    
    call    reloj	;se llama al reloj 
    call    config_ioc	;se llama a nuestro timer 9
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
    movlw   12	    ;valor incial del timer0
    movwf   TMR0    
    bcf	    T0IF    ;vuelve 0 al bit de overflow
   
    return

int_enable:
    bsf	    GIE     ;INTCON
    bsf	    RBIE
    bcf	    RBIF
    return
    
END




