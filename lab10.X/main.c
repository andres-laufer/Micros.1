/*
 * File:   main.c
 * Author: Andres Laufer
 * 
 * Compilador:	pic-as (v2.30), MPLABX V5.45
 * 
 * Programa: Comunicación serial
 * Hardware: Pic 16f887, Leds, resistencias, terminal serial
 * 
 * Created on April 27, 2021
 */

// PIC16F887 Configuration Bit Settings
// 'C' source line config statements

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits 
#pragma config WDTE = OFF       // Watchdog Timer Enable bit 
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit 
#pragma config CP = OFF         // Code Protection bit 
#pragma config CPD = OFF        // Data Code Protection bit 
#pragma config BOREN = OFF      // Brown Out Reset Selection bits 
#pragma config IESO = OFF       // Internal External Switchover bit 
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit
#pragma config LVP = ON         // Low Voltage Programming Enable bit 

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

// Librerias
#include <xc.h>
#include <stdint.h>

// Directivas del compilador 

#define _XTAL_FREQ 8000000

// Funciones
void USART_Tx(char data);
char USART_Rx();
void USART_Cadena(char *str);

// Variables

char valor;

// Interrupcion 

void main(void){

    ANSEL = 0X00;   
    ANSELH = 0x00;

    TRISA = 0x00; 
    TRISB = 0x00; 
    
    PORTA = 0x00;
    PORTB = 0x00;
    
    OSCCONbits.IRCF = 0b111 ;  
    OSCCONbits.SCS = 1;         

                           
    TXSTAbits.SYNC = 0;     
    TXSTAbits.BRGH = 1;    
    BAUDCTLbits.BRG16 = 1;  
   
    SPBRG = 207;                        
    SPBRGH = 0;         
    
    RCSTAbits.SPEN = 1;    
    RCSTAbits.RX9 = 0;      
    RCSTAbits.CREN = 1;     
    TXSTAbits.TXEN = 1;     
   
// Loop
    while (1) {
        USART_Cadena("\r Que accion desea ejecutar? \r");
        USART_Cadena(" 1) Desplegar cadena de caracteres \r");
        USART_Cadena(" 2) Cambiar PORTA \r");
        USART_Cadena(" 3) Cambiar PORTB \r \r");
        
        while(PIR1bits.RCIF == 0);  // Se espera a que se envie un dato
        
        valor = USART_Rx();
          
        switch(valor){
            case ('1'):
                USART_Cadena(" Bienvenido \r");
                break;
                        
            case ('2'):
                USART_Cadena(" Ingresar carater para el puerto A: ");
                while(PIR1bits.RCIF == 0);
                PORTA = USART_Rx();  //lo paso al puerto A
                break;
                        
            case ('3'):
                USART_Cadena(" Ingresar caracter para el puerto B: ");
                while(PIR1bits.RCIF == 0);
                PORTB = USART_Rx();  //lo paso al puerto B
                break;
        }
    }
    
    return; 
}


    void USART_Tx(char data){
        while(TXSTAbits.TRMT == 0);
        TXREG = data;
    }

    void USART_Cadena(char *str){
        while(*str != '\0'){
            USART_Tx(*str);
            str++;
        }
    }
    
    char USART_Rx(){
        return RCREG; 
       }