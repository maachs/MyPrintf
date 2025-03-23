section .text

global _start                  ; predefined entry point name for ld

_start:
    lea rsi, FormatParam        ;format string
    lea rdi, Buffer             ;in rdi - buffer
    push "12"

    push rsi                    ;format string in stack

    jmp MyPrintf
    jmp EOP
;----------------------------------------------------
MyPrintf:
    pop rsi
RepPrintf:
    cmp byte [rsi], "%"
    je CheckParamOfPercent

    cmp byte [rsi], "$"          ;$ - symbol end of format
    je PrintBuff

    movsb                           ;copy string from format arg to buff

    jmp RepPrintf               ;write buffer into console

    End_PrintBuff:
;---------------------------------------------------
CheckParamOfPercent:
    ;inc rdi
    ;movsb                   ;from rsi(arg of %) to rdi
    ;mov rax, rdi            ;in rax %(-)
    inc rsi
    xor rax, rax
    mov al, [rsi]
    inc rsi
    shl rax, 3d             ;rax * 8
    add rax, JumpTable
    jmp [rax]               ;jump to arg of percent
    nop
    nop
;----------------------------------------------------
PercentB:
    pop rax                 ;get num
    mov rbx, 2d             ;numer system

    jmp RepPrintf
;----------------------------------------------------
PercentC:
    pop rax                 ;param of printf
    mov [rdi], al
    ;movsb               ;[rdi] = [rsi] copy on symbol from rsi to rdi
    inc rdi

    jmp RepPrintf
;----------------------------------------------------
PercentD:
    pop rax                 ;
    mov rbx, 10d            ;number system
    jmp ConvertToDec
    EndConvertDec:
    inc rdi

    jmp RepPrintf
;------------------------------------------------------
PercentO:
PercentS:
PercentX:
PercentPercent:
error:
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMessage
    mov rdx, ErrorLen
    syscall
    jmp EOP
;--------------------------------------------------
ConvertToDec:               ;Entry: rax - num, rbx - number system
    xor rdx, rdx
    xor rcx, rcx

    push rsi                ;save format string
    xor rsi, rsi
    lea rsi, NumberBuff

    ReverseNum:
    xor rdx, rdx
    ;mov rbx, 10d            ;in rbx - number system
    div rbx                 ;rax - quotient, rdx - remainder

    add rdx, "0"                ;get ascii
    mov byte [rsi], dl           ;reminder in NumberBuff
    inc rsi

    ;push rax
    ;push rdi
    ;push rsi
    ;push rdx
    ;push rcx

    ;mov rax, 0x01
    ;mov rdi, 1
    ;mov rsi, NumberBuff
    ;mov rdx, 2
    ;syscall

    ;pop rcx
    ;pop rdx
    ;pop rsi
    ;pop rdi
    ;pop rax

    inc rcx                 ;count len of number

    cmp rax, 0              ;check quotient on zero
    jne ReverseNum

    xor rdx, rdx

    NextDigit:                  ;
    dec rsi
    movsb                       ;[rdi] = [rsi], rdi++
    dec rsi
    ;mov byte dl, [rsi]
    ;mov byte [rdi], dl
    ;mov [rdi], [rsi]           ;from NumberBuff to Buffer

    ;inc rdi                 ;step one to next digit
    ;dec rsi

    loop NextDigit
    inc rdi                 ;step ine in buffer
    pop rsi                 ;restore format string
    jmp EndConvertDec       ;ret
;--------------------------------------------------
PrintBuff:
    ;lea rbx, Buffer
    ;sub rdi, rbx            ;find len of buff
    ;inc rdi
    ;inc rdi

    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1
    mov rsi, Buffer
    mov rdx, BufferLen
    syscall

    jmp EOP
EOP:
    mov rax, 0x3C      ; exit64 (rdi)
    xor rdi, rdi
    syscall

section     .data
JumpTable:
    dq 37 dup(error)
    dq PercentPercent
    dq 60 dup(error)
    dq PercentB
    dq PercentC
    dq PercentD
    dq 10 dup(error)
    dq PercentO
    dq 3 dup(error)
    dq PercentS
    dq 4 dup(error)
    dq PercentX
    dq 135 dup(error)

NumberBuff   db 32 dup(0)
NumberBuffLen db $ - NumberBuff
ErrorMessage db "non specific type", 0x0a
ErrorLen     equ $ - ErrorMessage
FormatParam  dw "%b$"
Buffer:      db 40 dup(0), 0x0a
BufferLen    equ $ - Buffer

