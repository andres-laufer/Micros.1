/*
 * File:   main.c
 * Author: Andres Laufer
 * 
 * Compilador:	pic-as (v2.30), MPLABX V5.45
 * 
 * Programa: PWM
 * Hardware: Pic 16f887, transistores, Servos
 * 
 * Created on April 27, 2021
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

// Directivas del compilador 

#define _XTAL_FREQ 8000000 

// Variables
char    toca;

// Interrupciones

void __interrupt()isr(void){
    
    if(PIR1bits.ADIF == 1){
        
        if(toca == 1){
            CCPR1L = (ADRESH >> 1) + 124;
        }
        else if(toca == 0){
            CCPR2L = (ADRESH >> 1) + 124;
        }
                
        PIR1bits.ADIF = 0;
        
    }

}


void main(void){

    ANSEL = 0b00000011; 
    ANSELH = 0x00;

    TRISA = 0b00000011; // PORTA solo 2 pines como entradas
    TRISC = 0x00; // PORTC todo salida
    TRISD = 0x00; // PORTC todo salida
    
                            
    ADCON1bits.ADFM = 0;    
    ADCON1bits.VCFG0 = 0;  
    ADCON1bits.VCFG1 = 0;
    ADCON0bits.ADCS = 0b10; 
    ADCON0bits.CHS = 0;    
    __delay_us(50);
    ADCON0bits.ADON = 1;    
    
                           
    TRISCbits.TRISC2 = 1;
    TRISDbits.TRISD5 = 1;
    
    PR2 = 255;          
    
    CCP1CONbits.P1M = 0;
    CCP1CONbits.CCP1M = 0b1100; 
    CCPR1L = 0x0f;      
 
    CCP2CONbits.CCP2M = 0;
    CCP2CONbits.CCP2M = 0b1100; 
    CCPR1L = 0x0f;         
    CCPR2L = 0x0f;          
    
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;

    PIR1bits.TMR2IF = 0;  
    T2CONbits.T2CKPS = 0b11; 
    T2CONbits.TMR2ON = 1;    
    while(PIR1bits.TMR2IF == 0);  
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;        
    TRISDbits.TRISD5 = 0;       
    
    OSCCONbits.IRCF = 0b0111 ;  
    OSCCONbits.SCS = 1;      
    
    
                         
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1; 
    INTCONbits.PEIE = 1;
    INTCONbits.GIE = 1;
    ADCON0bits.GO = 1;  

    toca = 1;

    // Loop
    while (1) {
        
        if(ADCON0bits.GO == 0){
            
            if(ADCON0bits.CHS == 0){
                toca = 0;
                ADCON0bits.CHS = 1;
            }
            else if(ADCON0bits.CHS == 1){
                toca = 1;
                ADCON0bits.CHS = 0;
            }
            __delay_us(50);     
                               
            ADCON0bits.GO = 1;
        }
    }
    return; 
}