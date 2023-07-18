.MODEL small
.STACK 100h


.DATA

    char db ? ; the character read by the get_char procedure and printed by the put_char procedure
    i dw ? ; counter to be used in loops
    buf db 255, ?, 36, 252 dup(" ") ; buffer for the int 21h/ah=0Ah and int 21h/ah=9 interrupts used in the gets and puts procedures, max 254 chars

    scanf_printf_value_counter dw 3 ; the max number of values scanf can read and printf can output (by default 3)
    scanf_printf_buf db 255, ?, 36, 252 dup(" "), 255, ?, 36, 252 dup(" "), 255, ?, 36, 252 dup(" ") ; buffers for scanf and printf, each buffer 255, ?, 36, 252 dup(" ") holds a single string with max length of 254 characters, there must always be at least scanf_printf_value_counter number of these buffers (by default 3)    
    read_newline_enter dw 0 ; saves whether a newline or enter character has been read so that scanf stops reading if such a character is read, 0 means no such character has been read and 1 means the opposite
    printf_str db "1st str= %s, 2nd str= %s, 3rd str= %s.", "$" ; the format string of printf, each %s part prints the next string that scanf read, by default it prints the three values that scanf read
    
    getchar_msg db "getchar input: ", "$"
    putchar_msg db "putchar output: ", "$"
    gets_msg db "gets input: ", "$"
    puts_msg db "puts output: ", "$"
    scanf_msg db "scanf input (give three strings separated by a a space): ", "$"
    printf_msg db "printf output: ", "$"
    new_line db 0ah,0dh, "$"


.CODE
.STARTUP


    call get_put_char ; call the procedure that uses getchar to read a character from the keyboard and prints it using put_char 
    call print_new_line ; call the procedure that prints a new line
    call print_new_line ; call the procedure that prints a new line
    
    call gets_puts ; call the procedure that uses gets to read a string from the keyboard and prints it using puts
    call print_new_line ; call the procedure that prints a new line
    call print_new_line ; call the procedure that prints a new line
    
    call scanf_printf ; call the procedure that uses scanf to read scanf_printf_value_counter number of strings from the keyboard and prints them using scanf 

    
.EXIT


    proc get_put_char ; procedure that uses getchar to read a character from the keyboard and prints it using putchar 
        lea dx, getchar_msg ; save the effective address of the string with the applicable message for reading the input of getchar
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        call getchar ; call the procedure that implements the getchar function
        
        call print_new_line ; call the procedure that prints a new line
        
        lea dx, putchar_msg ; save the effective address of the string with the applicable message for printing the output of putchar
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        call putchar ; call the procedure that implements the putchar function 
        ret
    get_put_char endp  
    
    proc gets_puts ; procedure that uses gets to read a string from the keyboard and prints it using puts
        lea dx, gets_msg ; save the effective address of the string with the applicable message for reading the input of gets
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        lea si, buf ; save to si the effective address of the buffer where the input of gets will be saved
        call gets ; call the procedure that implements the gets function
        
        call print_new_line ; call the procedure that prints a new line
        
        lea dx, puts_msg ; save the effective address of the string with the applicable message for printing the output of puts
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        
        lea si, buf ; save to si the effective address of the buffer where the output of puts is saved
        call puts ; call the procedure that implements the puts function
        ret
    gets_puts endp
    
    proc scanf_printf ; procedure that uses scanf to read scanf_printf_value_counter number of strings from the keyboard and prints them using scanf
        lea dx, scanf_msg ; save the effective address of the string with the applicable message for reading the input of scanf
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        call scanf ; call the procedure that implements the scanf function
         
        call print_new_line ; call the procedure that prints a new line
        
        lea dx, printf_msg ; save the effective address of the string with the applicable message for printing the output of printf
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        call printf ; call the procedure that implements the printf function
        ret
    scanf_printf endp  
    
    proc getchar ; procedure that implements the getchar function
        mov ah, 1 ; move to ah the value that reads a character from standard input, with echo, with the result being saved in al 
        int 21h ; call the interrupt that reads a character from standard input, with echo and saves the result in al
        mov char, al ; save the character that was read to the variable char
        ret
    getchar endp 
   
    proc putchar ; procedure that implements the putchar function
        xor dx, dx ; set dx to 0
        mov dl, char ; save to dl the character that will be printed and is saved in the variable char
        mov ah, 2 ; move to ah the value that writes a character saved in dl to standard output  
        int 21h ; call the interrupt that writes a character saved in dl to standard output
        ret
    putchar endp   
    
    proc gets ; procedure that implements the gets function
        mov dx, si ; save to dx the memory location of the buffer that will be used for the interrupt 21h/ah=0Ah which was saved in si
        mov ah, 0ah ; move to ah the interrupt value that corresponds to the interrupt 21h/ah=0A
        int 21h ; call the interrupt that reads a string from standard input, the result is saved in the buffer si
        xor bx, bx ; set bx to 0
        mov bl, si[1] ; save to bl the character count of the buffer si which was used to save the string that was read 
        mov si[bx + 2], "$" ; add the character "$" to the end of the string that was read and is saved in si[2], bx is added so that si[bx + 2] points to the character right after the string's last character
        ret
    gets endp  
    
    proc puts ; procedure that implements the puts function
        add si, 2 ; add 2 to the memory location of the buffer si where the string to be printed is saved to get to the start of the string
        mov dx, si ; save to dx the memory location of the string read by gets  
        mov ah, 9 ; move to ah the value that writes the string at ds:dx to standard output
        int 21h ; call the interrupt that writes the string at ds:dx to standard output
        ret
    puts endp  
    
    proc scanf ; procedure that implements the scanf function
        mov read_newline_enter, 0 ; initialize the variable which saves whether a newline or enter character has been read to 0 to indicate such a character has not been read yet
        mov i, 0 ; counter for the amount of values read that is initialized to 0
        scan_values_loop: ; loop that iterates until all scanf_printf_value_counter number of values have been read
            cmp read_newline_enter, 1 ; if the variable which saves whether a newline or enter character has been read is set to 1, it means that such a character has been read
            je exit_scanning ; if an enter or newline character was read, then stop scanning with scanf
        
            mov ax, 255
            mul i ; save 255 * i to ax
            lea si, scanf_printf_buf ; load to si the effective address of the buffer scanf and printf use
            add si, ax ; add 255 * i to si so that si points to the correct buffer, each buffer is 255 chars long (the last char is "$")
            inc i ; increment the counter for the amount of values read
            call scan_value ; call the procedure that reads a string until a space, enter or a new line is inputted
            
            mov ax, scanf_printf_value_counter ; save to ax the amount of values scanf must read 
            cmp i, ax ; compare the counter of read values i to the the amount of values scanf must read saved in ax
            jl scan_values_loop ; if not all the values have been read (i < ax), then loop again to read another value
        
        exit_scanning: 
        ret       
    scanf endp  
    
    proc printf ; procedure that implements the printf function
        lea bx, printf_str ; save to bx the effective address of printf's format string 
        mov i, 0 ; counter for the amount of values printed that is initialized to 0 
        print_str: ; loop that iterates over all the character of printf's format string printf_str
            mov ax, [bx] ; save the first two characters of printf's format string to ax
            mov char, al ; save the next character of printf's format string to char
            
            cmp char, 36
            je stop_printing ; if the next char of printf's format string is "$", then jump to stop_printing to exit printf since all of its format string has been printed
            
            cmp char, 37
            je print_value ; if the next char of printf's string is "%", then jump to print_value to print the next value read by scanf
            
            call putchar ; call the procedure that prints the character saved in char
            inc bx ; increment the effective address of printf's string to get its next character in the next loop
            jmp print_str ; loop again to print the next character of printf's format string
            
            print_value: ; print the next value read by scanf
                mov ax, 255
                mul i ; save 255 * i to ax
                inc bx ; increment the effective address of printf's format string to skip the "%" character 
                inc bx ; increment the effective address of printf's format string to skip the "s" character
                lea si, scanf_printf_buf ; load to si the effective address of the buffer scanf and printf use
                add si, ax ; add 255 * i to si so that si points to the correct buffer, each buffer is 255 chars long 
                inc i ; increment the counter for the amount of values printed 
                call puts ; call the procedure that prints the string saved in the buffer with effective address si
                jmp print_str ; repeat the loop to print the next character of printf's format string
             
        stop_printing:
            ret
    printf endp 
    
    proc scan_value ; procedure that reads a string from the keyboard char by char until a space, enter or a newline is read
        mov cx, 0 ; counter for the number of characters read in this string
        read_loop: ; loop that reads characters until a space, enter or a newline is read 
            call getchar ; call the procedure that reads a character from standard input and saves it in char
            cmp char, 10
            je stop_scanning ; if the character that was read is the newline character, then stop scanning for values in scanf
            cmp char, 13
            je stop_scanning ; if the character that was read is enter, then stop scanning for values in scanf
            cmp char, 32
            je stop_reading ; if the character that was read is the space character, then stop reading
            
            continue_reading: ; if the character that was read is neither newline, enter or space, then continue reading characters
                mov bx, 2
                add bx, cx ; save to bx 2 plus the counter for the number of characters read in this string, bx = 2 + cx
                mov al, char ; save to al the character that was read
                mov si + bx, al ; si holds the effective address of the buffer that scanf and printf use, this saves the character saved in al to the buffer's cx byte (bx = 2 + cx to get past the buffer's max chars and char count - saved in the first two bytes of the buffer si)
                inc cx ; increment the counter for the number of characters read in this string 
                jmp read_loop ; repeat the loop to read the next character 
        
        stop_scanning:
            mov read_newline_enter, 1 ; save 1 to read_enter, this tells scanf to stop reading values since newline or enter was read, then move on to stop_reading
        
        stop_reading:
            mov bx, cx ; save the final counter for the number of characters read in this string to bx 
            mov si[bx + 2], "$" ; save the character "$" in the end of the string saved in the buffer si 
            mov si[1], bl ; save the number of characters in the string to the second byte of the buffer si
            ret
    endp scan_value  
    
    print_new_line proc ; procedure that prints a new line
        lea dx, new_line ; load the effective address of the string with the new line
        mov ah, 9 ; move the value that prints a string to ah
        int 21h ; call the interrupt that prints the string saved in dx
        ret
    print_new_line endp

                           
END