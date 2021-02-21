;-------------------------------------------------------------------------------
    ;Archivo:	  main.s
    ;Dispositivo: PIC16F887
    ;Autor: Andres Laufer
    ;Compilador: pic-as (v2.30), MPLABX V5.45
    ;
    ;Programa: Timer y contador Hexadecimal
    ;Hardware: Display 7 Seg, Push Buttom, Leds, Resistencias. 
    ;
    ;Creado: 16 feb, 2021
    ;Última modificación: 20 feb, 2021    
;-------------------------------------------------------------------------------

    PROCESSOR 16F887
    #include <xc.inc>
    
    
    CONFIG FOSC=INTRC_NOCLKOUT //Oscillador interno
    CONFIG WDTE=OFF	//WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON	//PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF	//El pin de MCLR se utiliza como I/O
    CONFIG CP=OFF	//Sin protecci[on de codigo
    CONFIG CPD=OFF	//Sin proteccion de datos

    CONFIG BOREN=OFF	//Sin reinicio cuando el voltaje de alimentacion baja 4v
    CONFIG IESO=OFF	//Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF	//Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON	//programacion en bajo voltaje permitida
    

    CONFIG WRT=OFF	//Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V //Reinicio abajo de 4V, (BOR21v=2.1v)
    
    PSECT udata_bank0
	CONTADOR: DS 1
	DISPLAY: DS 1
	DELAY: DS 1
	PORTB_ANTERIOR: DS 1
	PORTB_ACTUAL: DS 1
    
    PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
    BSF STATUS, 6 
    BSF STATUS, 5 ; Banco 3
    CLRF ANSEL
    CLRF ANSELH
    
    BCF STATUS, 6 ; Banco 1
    CLRF TRISA ; Puerto A como salida
    CLRF TRISC ; Puerto C como salida
    CLRF TRISD 
    
    MOVLW 255
    MOVWF TRISB ; Puerto B Como entrada
    
    BCF OPTION_REG, 7 
    BCF OPTION_REG, 5
    BCF OPTION_REG, 3
    BSF OPTION_REG, 2
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0
    
    BCF STATUS, 5; Banco 0
    
    MOVLW 61
    MOVWF TMR0
    CLRF PORTA ;Poner en 0 el puerto
    CLRF PORTC ;Poner en 0 el puerto
    CLRF PORTD
    
    MOVLW 10
    MOVWF CONTADOR
    
    MOVLW 255
    MOVWF  PORTB_ACTUAL
    MOVWF  PORTB_ANTERIOR
    BCF INTCON, 2
;---------------------------Loop----------------------------------------
    
LOOP:
    MOVF    PORTB_ACTUAL, W
    MOVWF   PORTB_ANTERIOR
    CALL    delay_small
    MOVF    PORTB,W
    MOVWF   PORTB_ACTUAL
    BTFSC INTCON, 2
    CALL INCCOUNT
    BTFSS PORTB_ANTERIOR, 0 ;Boton incremento contador 1
    CALL INCREMENTOC
    BTFSS PORTB_ANTERIOR, 1 ;Boton decremento contador 1
    CALL DECREMENTOC
;-----------------Muestra el contador de botones en el display------------------
    CALL TRADUCCION
    MOVWF PORTC
;------------------------------Comparacion -------------------------------------
    MOVF PORTA, W
    SUBWF DISPLAY, W
    BTFSC STATUS, 2
    BSF PORTD, 0
    BTFSS STATUS, 0
    CALL ALARMA
    GOTO LOOP
;------------------Subrutinas-------------------
ALARMA:
    CLRF PORTA
    BCF PORTD,0
    RETURN
INCCOUNT:
    BCF INTCON, 2
    MOVLW 61
    MOVWF TMR0
    DECFSZ CONTADOR, F
    RETURN
    MOVLW 10
    MOVWF CONTADOR
    INCF PORTA, F
    MOVLW 16
    SUBWF PORTA, W
    BTFSS STATUS, 2
    RETURN
    CLRF PORTA
    RETURN
    
 INCREMENTOC:
    BTFSS  PORTB_ACTUAL, 0
    RETURN
    INCF DISPLAY, F
    BTFSC DISPLAY, 4 ;Instruccion para no sobrepasar los 4 bits encendidos
    DECF DISPLAY, F
    RETURN
    
 DECREMENTOC:
    BTFSS PORTB_ACTUAL, 1
    RETURN
    
    DECF DISPLAY, F ;decrementa puerto A
    INCFSZ DISPLAY, F ;Incrementa puerto A, si valor de F es 1
    DECF DISPLAY,F ;Decrementa puerto A y guarda valor en F
    RETURN
    
 TRADUCCION:
    MOVF DISPLAY, W
    ANDLW 00001111B
    ADDWF PCL, F
    RETLW 00111111B ; 0
    RETLW 00000110B ; 1
    RETLW 01011011B ; 2
    RETLW 01001111B ; 3
    RETLW 01100110B ; 4
    RETLW 01101101B ; 5
    RETLW 01111101B ; 6
    RETLW 00000111B ; 7
    RETLW 01111111B ; 8
    RETLW 01101111B ; 9
    RETLW 01110111B ; A
    RETLW 01111100B ; B
    RETLW 00111001B ; C
    RETLW 01011110B ; D
    RETLW 01111001B ; E
    RETLW 01110001B ; F

 delay_small:
    movlw   167		    ;valor inicial del contador 
    movwf   DELAY
    decfsz  DELAY, F   ;decrementa el contador
    goto    $-1		    ;ejecutar linea anterior
    return	
 END


