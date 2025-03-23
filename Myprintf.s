section .text

global _start                  ; predefined entry point name for ld

_start:
    lea rsi, FormatParam        ;format string
    lea rdi, Buffer             ;in rdi - buffer
    lea rax, Arg_str

    push 12
    push 10000000
    push 12
    push 12
    push rax
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

    cmp byte [rsi], "\"
    je BackSlash

    movsb                           ;copy string from format arg to buff

    jmp RepPrintf               ;write buffer into console

    End_PrintBuff:
;---------------------------------------------------
CheckParamOfPercent:
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
    jmp ConvertNum

    jmp RepPrintf
;----------------------------------------------------
PercentC:
    pop rax                 ;get char
    mov [rdi], al              ; copy on symbol from Format str to buff
    inc rdi

    jmp RepPrintf
;----------------------------------------------------
PercentD:
    pop rax                 ;get num
    mov rbx, 10d            ;number system
    jmp ConvertNum
;------------------------------------------------------
PercentO:
    pop rax                 ;get num
    mov rbx, 8d             ;number system
    jmp ConvertNum
;-----------------------------------------------------
PercentS:
    pop rax                 ;addr of str
    push rsi                ;save format str
    xor rsi, rsi
    mov rsi, rax            ;addr str in rsi

    xor rdx, rdx
    xor rcx, rcx

    push rsi                ;save addr

    Symbol:
    xor rdx, rdx
    mov dl, [rsi]
    inc rsi
    inc rcx                 ;count symbols
    cmp dl, 0               ;check on \0
    jne Symbol

    dec rcx

    pop rsi                 ;restore addr str

    CopyStr:
    movsb
    loop CopyStr

    pop rsi

    jmp RepPrintf
;-----------------------------------------------------
PercentX:
    pop rax                 ;get num
    mov rbx, 16d             ;number system
    jmp ConvertNum
;-----------------------------------------------------
PercentPercent:
    inc rsi
    mov byte[rdi], "%"
    inc rdi
    jmp RepPrintf
;-----------------------------------------------------
error:
    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMessage
    mov rdx, ErrorLen
    syscall
    jmp EOP
;--------------------------------------------------
ConvertNum:               ;Entry: rax - num, rbx - number system
    xor rdx, rdx
    xor rcx, rcx

    push rsi                ;save format string
    xor rsi, rsi
    lea rsi, NumberBuff

    ReverseNum:
    xor rdx, rdx
    div rbx                 ;rax - quotient, rdx - remainder

    cmp rbx, 16d            ;check on hex
    jne Continue

    cmp rdx, 9d
    jle Not_Letter

    add rdx, 7d             ;because "9" to "a"

    Not_Letter:

    Continue:
    add rdx, "0"                ;get ascii
    mov byte [rsi], dl           ;reminder in NumberBuff
    inc rsi

    inc rcx                 ;count len of number

    cmp rax, 0              ;check quotient on zero
    jne ReverseNum

    xor rdx, rdx

    NextDigit:                  ;copy num from NumBuffer to Buffer
    dec rsi
    movsb                       ;[rdi] = [rsi], rdi++
    dec rsi

    loop NextDigit
    inc rdi                 ;step ine in buffer
    pop rsi                 ;restore format string
    jmp RepPrintf       ;ret
;--------------------------------------------------
BackSlash:
    inc rsi
    xor rax, rax
    mov byte al, [rsi]              ;get arg slash

    cmp al, "n"
    mov byte [rdi], 0x0a            ;\n

    inc rdi
    inc rsi

    jmp RepPrintf
;--------------------------------------------------
PrintBuff:
    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1
    mov rsi, Buffer
    mov rdx, BufferLen
    syscall

    jmp EOP
;--------------------------------------------------
EOP:
    mov rax, 0x3C      ; exit64 (rdi)
    xor rdi, rdi
    syscall
;--------------------------------------------------
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

Arg_str       db "real champion", 0x00
NumberBuff    db 32 dup(0)
NumberBuffLen db $ - NumberBuff
ErrorMessage  db "non specific type", 0x0a
ErrorLen      equ $ - ErrorMessage
FormatParam   dw "%s\n %%n\nbin - %b\noct - %o\ndec - %d\nhex - %x\n$"
Buffer:       db 100 dup(0)
BufferLen     equ $ - Buffer

