section .text

global _start                  ; predefined entry point name for ld

_start:
    lea rsi, FormatParam        ;format string
    lea rdi, Buffer             ;in rdi - buffer
    lea rax, Arg_str
    ;mov rbx, -1
    push 12

    ;push 12
    ;push 12
    ;push 12
    ;push 12
    ;push rax
    push rsi                    ;format string in stack

    jmp MyPrintf
;----------------------------------------------------
MyPrintf:
    pop rsi
RepPrintf:
    cmp byte [rsi], "%"
    je CheckParamOfPercent

    cmp byte [rsi], "$"          ;$ - symbol end of format
    je PrintBuff

    cmp byte [rsi], "\" ;bACK_SLASH_nnnnn
    je BackSlash

    call RestoreBuffer

    push rdx
    mov dl, byte [rsi]
    pop rdx

    movsb                           ;copy string from format arg to buff

    jmp RepPrintf               ;write buffer into console

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
    ;mov rbx, 2d             ;numer system
    jmp ConvertNum
;----------------------------------------------------
PercentC:
    pop rax                 ;get char

    call RestoreBuffer

    mov [rdi], al              ; copy on symbol from Format str to buff
    inc rdi

    jmp RepPrintf
;----------------------------------------------------
PercentD:
    pop rax                 ;get num

    test rax, rax
    jns UnsignedValue       ;jmp if not signed

    mov byte [rdi], "-"     ;print " - "
    inc rdi
    neg rax                 ;* (-1)

    UnsignedValue:
    mov rbx, 10d            ;number system

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

    call RestoreBuffer

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

    call RestoreBuffer

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
ConvertNum:               ;Entry: rax - num, rсx - number system
    ;rbx - count
    xor rcx, rcx
    xor rbx, rbx
    xor rbx, rbx
    ;xor rcx, rcx

    push rsi                ;save format string
    xor rsi, rsi
    lea rsi, NumberBuff

    mov rdx, 0x01           ;bit mask
    mov rcx, 1d             ;number system 2^(rcx)

    ReverseNum:
    push rax

    and rax, rdx
    ;shr rax, cl                 ;rax - quotient, rdx - remainder

    cmp rcx, 4d            ;check on hex
    jne Continue

    cmp rdx, 9d
    jle Not_Letter

    add rdx, 7d             ;because "9" to "a"

    Not_Letter:

    Continue:
    add rax, "0"                ;get ascii
    mov byte [rsi], al           ;reminder in NumberBuff
    inc rsi

    inc rbx                 ;count len of number
    pop rax
    shr rax, cl
    cmp rax, 0              ;check quotient on zero
    jne ReverseNum

    mov rcx, rbx
    xor rdx, rdx

    NextDigit:                  ;copy num from NumBuffer to Buffer

    call RestoreBuffer

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

    call RestoreBuffer

    cmp al, "n" ;\m
    jne Jump_nahui
    mov byte [rdi], 0x0a            ;\n
    jmp SkipAction

    Jump_nahui:
    mov byte [rdi], "\"  ;ghj
    inc rdi
    mov byte [rdi], al
    SkipAction:

    inc rdi
    inc rsi

    jmp RepPrintf
;--------------------------------------------------
RestoreBuffer:

    push rcx
    lea rcx, [rel Buffer]
    sub rcx, rdi
    neg rcx

    cmp rcx, 9d
    jne Return

    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1
    mov rsi, Buffer
    mov rdx, BufferLen
    syscall

    call DtorBuff

    pop rdx
    pop rsi
    pop rdi
    pop rax

    jmp Next

    Return:
    pop rcx
    ret

    Next:
    pop rcx
    lea rdi, [rel Buffer]

    ret
;--------------------------------------------------
DtorBuff:
    push rcx
    push rdi

    lea rdi, [rel Buffer]
    mov rcx, 10d

    Dtor:
    mov byte [rdi], 0
    inc rdi
    loop Dtor

    pop rdi
    pop rcx

    ret
;--------------------------------------------------
PrintBuff:
    lea rdx, [rel Buffer]
    sub rdx, rdi
    neg rdx

    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1
    mov rsi, Buffer
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

Arg_str       db "hui", 0x00
NumberBuff    db 32 dup(0)
NumberBuffLen db $ - NumberBuff
ErrorMessage  db "non specific type", 0x0a
ErrorLen      equ $ - ErrorMessage
FormatParam   dw "%b\n$"
Buffer:       db 10 dup(0)
BufferLen     equ $ - Buffer
