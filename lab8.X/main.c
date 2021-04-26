/*
 * File:   main.c
 * Author: Andres Laufer
 * 
 * Compilador:	pic-as (v2.30), MPLABX V5.45
 * 
 * Programa: Valor binario y decimal de diferentes entradas analogicas
 * Hardware: Pic 16f887, transistores, resistencias, leds, displays 7 seg,button
 * 
 * Created on April 20, 2021
 */

// PIC16F887 Configuration Bit Settings
// 'C' source line config statements

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>

// Directivas de compilador

#define _tmr0_value 100
#define _XTAL_FREQ 8000000 

// Variables 
char centena, decena, unidad;
char dividendo, divisor;
char turno;
                          // 0     1    2     3     4
const char num_display[] = {0xFC, 0x60, 0xDA, 0xF2, 0x66,
                            0xB6, 0xBE, 0xE0, 0xFE, 0xF6};
                          //  5     6     7    8     9


// Interrupciones

void __interrupt()isr(void){

    if (T0IF == 1) { //INTERRUPCION POR TIMMER0
   
        RD0 = 0;                         
        RD1 = 0;                          
        RD2 = 0;                          
        if (turno == 3) {
            PORTC = (num_display[centena]);
            RD0 = 1;                        
        } 
        else if (turno == 2) {
            PORTC = (num_display[decena]);
            RD1 = 1;                        
        }
        else if (turno == 1) {
            PORTC = (num_display[unidad]);
            RD2 = 1;                        //turn on only this display
        }
        
        turno--;
        if (turno == 0){
            turno = 3;                     
        }

        INTCONbits.T0IF = 0; 
        TMR0 = _tmr0_value; 
    }
}


void main(void){

    ANSEL = 0b01100000; // hay i/o analogicas AN5 y AN6
    ANSELH = 0x00;
    TRISA = 0x00; // PORTA todo salida
    TRISC = 0x00; // PORTC todo salida
    TRISD = 0x00; // PORTD todo salida
    TRISE = 0b0011; // PORTE Como entrada analogica
    
    ADCON1bits.ADFM = 0;    
    ADCON1bits.VCFG0 = 0;   
    ADCON1bits.VCFG1 = 0;
    ADCON0bits.ADCS0 = 0;  
    ADCON0bits.ADCS1 = 1;
    ADCON0bits.CHS = 5; 
    __delay_us(100);
    ADCON0bits.ADON = 1;    
    
    OSCCONbits.IRCF2 = 1; 
    OSCCONbits.IRCF1 = 1; 
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1; 

    OPTION_REGbits.T0CS = 0; 
    OPTION_REGbits.PSA = 0; 
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 0;
    OPTION_REGbits.PS0 = 1; 
    TMR0 = 100; 

    INTCONbits.GIE = 1; 
    INTCONbits.T0IE = 1; 
    INTCONbits.T0IF = 0; 

    
    ADCON0bits.GO = 1;  
    
    PORTA = 0; 
    PORTB = 0; 
    PORTC = 0; 
    PORTD = 0; 

    centena = 0; 
    decena = 0;
    unidad = 0;
    turno = 3;

    // Loop
    while (1) {
        
        if(ADCON0bits.GO == 0){
            
            if(ADCON0bits.CHS == 6){
                PORTA = ADRESH;
                ADCON0bits.CHS = 5;
            }
            else if(ADCON0bits.CHS == 5){
                dividendo = ADRESH;
                ADCON0bits.CHS = 6;
            }
            __delay_us(50);     
                                
            ADCON0bits.GO = 1;
        }
        
        centena = (dividendo / 100);                  
        decena = (dividendo - (100 * centena))/10; 
        unidad = dividendo - (100 * centena) - (decena * 10);  

    }
    return;    
}