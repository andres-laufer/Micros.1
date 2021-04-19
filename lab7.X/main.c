/*
 * File:   main.c
 * Author: Andres Laufer
 *
 * Created on April 13, 2021
 */
 
// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

// CONFIG1
#pragma config FOSC = EXTRC_NOCLKOUT// Oscillator Selection bits 
#pragma config WDTE = OFF        // Watchdog Timer Enable bit (WDT enabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF       // RE3/MCLR pin function select bit 
#pragma config CP = OFF         // Code Protection bit 
#pragma config CPD = OFF        // Data Code Protection bit 
#pragma config BOREN = OFF       // Brown Out Reset Selection bits (BOR enabled)
#pragma config IESO = OFF        // Internal External Switchover bit 
#pragma config FCMEN = OFF       // Fail-Safe Clock Monitor Enabled bit 
#pragma config LVP = OFF         // Low Voltage Programming Enable bit 

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h> //tipos de datos estandard y otros

//Variables

char    Disp_Sig;
char    display_var[3];
char    Minus_cent;
char    cent;
char    dec;
char    unit;

//Tabla de 7 segmentos

unsigned char tabla_seg(unsigned char valor){
    switch(valor) {
        case 0:                     //0
            return 0x3F;
            break;
        case 1:                     //1
            return 0x06;
            break;
        case 2:                     //2
            return 0x5B;
            break;
        case 3:                     //3
            return 0x4F;
            break;   
        case 4:                     //4
            return 0x66;
            break; 
        case 5:                     //5
            return 0x6D;
            break;
        case 6:                     //6
            return 0x7D;
            break;
        case 7:                     //7
            return 0x07;
            break;
        case 8:                     //8
            return 0x7F;
            break;
        case 9:                     //9
            return 0x6F;
            break;
        case 10:                    //A
            return 0x77;
            break;  
        case 11:                    //B
            return 0x7C;
            break;
        case 12:                    //C
            return 0x39;
            break;
        case 13:                    //D
            return 0x5E;
            break;
        case 14:                    //E
            return 0x79;
            break;
        case 15:                    //F
            return 0x71;
            break;
    }
}

//Interrupcion

void __interrupt()  ISR(){
    /*if(INTCONbits.T0IF){
        TMR0 = 217;
        INTCONbits.T0IF = 0;
        PORTC ++;
    }*/
    if(RBIF == 1)  {
        if (PORTBbits.RB0 == 0) {   //presiona el botón de incrementar 
            PORTA++; 
        }
        if (PORTBbits.RB1 == 0) {   // presiona el botón de decrementar
            PORTA--; 
        } 
        INTCONbits.RBIF = 0;        //reseteo de banderas
    }
    
    if (T0IF == 1) {                
        TMR0 = 100;                 //reseteo de timer0
        INTCONbits.T0IF = 0;        //limpieza de bandera
        switch(Disp_Sig) {
            case 0:
                PORTD = 0;
                PORTC = display_var[2];
                PORTDbits.RD0 = 1;
                Disp_Sig++;
                break;
            case 1:
                PORTD = 0;
                PORTC = display_var[1];
                PORTDbits.RD1 = 1;
                Disp_Sig++;
                break;
            case 2:
                PORTD = 0;
                PORTC = display_var[0];
                PORTDbits.RD2 = 1;
                Disp_Sig = 0;
                break;
        }
    }        
}

//Prototipo de funciones

void main(void) {
    
   //configuraciones de RELOJ
    OSCCONbits.IRCF2 = 1;       
    OSCCONbits.IRCF1 = 0;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS   = 1;
    
    ANSELH = 0;
    ANSEL  = 0;
    TRISB  = 3;
    TRISA  = 0;
    TRISC  = 0;
    TRISD  = 0;
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;         //se habilitan los pull-ups
    WPUBbits.WPUB1 = 1;
    PORTA  = 0;                 //Se limpian los puertos 
    PORTB  = 0;
    PORTC  = 0;
    PORTD  = 0;
    
    //INTERRUPT ON CHANGE
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    
    //configuraciones en tmr0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA  = 0;
    OPTION_REGbits.PS2  = 0;
    OPTION_REGbits.PS1  = 1;
    OPTION_REGbits.PS0  = 1;
    TMR0 = 100;                 //reseteo TMR0
    INTCONbits.T0IF = 0;        
    
    //HABILITADO DE INTERRUPCIONES
    INTCONbits.GIE  = 1;
    INTCONbits.RBIE = 1;
    INTCONbits.T0IE = 1;
    

//---------------------------------PRINCIPAL------------------------------------
    while (1)
    {
        cent = PORTA / 100;         //traduce a decimal 
        Minus_cent = PORTA % 100;
        dec = Minus_cent / 10;
        unit = Minus_cent % 10;
        
        display_var[2] = tabla_seg(cent);   //coloca los valores en el display
        display_var[1] = tabla_seg(dec);
        display_var[0] = tabla_seg(unit);
     }
}