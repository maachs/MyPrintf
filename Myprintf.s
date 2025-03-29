section .text

global MyPrintf                  ; predefined entry point name for ld

MyPrintf:

    pop qword [RetAddr]         ;save ret addr in c

    push r9                     ;sixth arg
    push r8                     ;
    push rcx                    ;
    push rdx                    ;
    push rsi                    ;second arg
    push rdi                    ;format string in stack

    xor rdi, rdi
    lea rdi, [rel Buffer]       ;in rdi - buffer
    pop rsi                     ;get format str
;-----------------------------------------------
RepPrintf:
    cmp byte [rsi], "%"
    je CheckParamOfPercent      ;checking arg of %

    cmp byte [rsi], "$"         ;$ - symbol end of format
    je PrintBuff

    call RestoreBuffer          ;checking buffer

    movsb                       ;copy string from format arg to buff

    jmp RepPrintf               ;write buffer into console

    End_PrintBuff:
;---------------------------------------------------
;CheckParamOfPercent - func to get addr to jump in jump_table
;Entry: rsi - format str
;Exit: jmp to func
;Destr: rax
;---------------------------------------------------
CheckParamOfPercent:
    inc rsi                 ;
    xor rax, rax
    mov al, [rsi]           ;in al - arg
    inc rsi
    shl rax, 3d             ;rax * 8
    add rax, JumpTable
    jmp [rax]               ;jump to arg of percent
    nop
    nop
;----------------------------------------------------
;Percent_ - functions to write in buffer in depends of arg of %
;Entry: stack
;Exit: rdi
;Destr: rax, rbx, rcx
;----------------------------------------------------
PercentB:
    pop rax                 ;get num

    mov rdx, 0x01           ;mask to get last digit
    mov rcx, 1d             ;number system - 2^1
    jmp ConvertToMultipleOfTwo
;----------------------------------------------------
PercentC:
    pop rax                 ;get char

    call RestoreBuffer

    mov [rdi], al           ;copy on symbol from Format str to buff
    inc rdi

    jmp RepPrintf           ;ret
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

    jmp ConvertDec
;------------------------------------------------------
PercentO:
    pop rax                 ;get num

    mov rdx, 0x07           ;mask to get last digit
    mov rcx, 3d             ;number system 8 = 2^3

    jmp ConvertToMultipleOfTwo
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
    mov dl, [rsi]           ;in dl - symbol
    inc rsi                 ;next symbol
    inc rcx                 ;count symbols
    cmp dl, 0               ;check on \0
    jne Symbol

    dec rcx

    pop rsi                 ;restore addr str

    CopyStr:
    call RestoreBuffer

    movsb                   ;copy from rsi to rdi
    loop CopyStr

    pop rsi

    jmp RepPrintf           ;ret
;-----------------------------------------------------
PercentX:
    pop rax                  ;get num

    mov rdx, 0x0f            ;mask to get last digit
    mov rcx, 4d              ;number system 16 = 2^4

    jmp ConvertToMultipleOfTwo
;-----------------------------------------------------
PercentPercent:
    inc rsi

    call RestoreBuffer

    mov byte [rdi], "%"      ;write in buffer %
    inc rdi
    jmp RepPrintf           ;ret
;-----------------------------------------------------
;error - func to write in stdout error_msg if arg of % non specify
;Entry: -
;Exit: stdout
;Destr: rax, rdi, rsi, rdx
;-----------------------------------------------------
error:                      ;if %arg non specify write error message
    mov rax, 0x01
    mov rdi, 1
    lea rsi, [rel ErrorMessage]
    mov rdx, ErrorLen
    syscall
    jmp EOP
;--------------------------------------------------
;ConvertDec - func to convert num from rax into dec str in buffer
;Entry: rax - num to convert, rbx - number system
;Exit: rdi
;Destr: rdx, rcx
;--------------------------------------------------
ConvertDec:
    xor rdx, rdx
    xor rcx, rcx

    push rsi                 ;save format string
    xor rsi, rsi
    lea rsi, [rel NumberBuff]

    ReverseNum:
    xor rdx, rdx
    div rbx                  ;rax - quotient, rdx - remainder

    add rdx, "0"             ;get ascii
    mov byte [rsi], dl       ;reminder in NumberBuff
    inc rsi

    inc rcx                 ;count len of number

    cmp rax, 0              ;check quotient on zero
    jne ReverseNum

    xor rdx, rdx

    NextDigit:              ;copy num from NumBuffer to Buffer

    call RestoreBuffer

    dec rsi
    movsb                   ;[rdi] = [rsi], rdi++
    dec rsi

    loop NextDigit
    inc rdi                 ;step ine in buffer
    pop rsi                 ;restore format string
    jmp RepPrintf           ;ret
;--------------------------------------------------
;--------------------------------------------------
ConvertToMultipleOfTwo:
    xor rbx, rbx

    push rsi                 ;save format string
    xor rsi, rsi
    lea rsi, [rel NumberBuff]

    @ReverseNum:
    push rax

    and rax, rdx             ;get last symbol

    cmp rcx, 4d             ;check on hex
    jne @Continue

    cmp rax, 9d
    jle @Not_Letter

    add rax, 7d              ;because "9" to "a"

    @Not_Letter:

    @Continue:
    add rax, "0"             ;get ascii
    mov byte [rsi], al       ;reminder in NumberBuff
    inc rsi

    inc rbx                 ;count len of number

    pop rax
    shr rax, cl             ;div rax, 2^(cl)

    cmp rax, 0              ;check quotient on zero
    jne @ReverseNum

    mov rcx, rbx
    xor rdx, rdx

    NextDigit2:              ;copy num from NumBuffer to Buffer

    call RestoreBuffer

    dec rsi
    movsb                   ;[rdi] = [rsi], rdi++
    dec rsi

    loop NextDigit2

    inc rdi                 ;step ine in buffer
    pop rsi                 ;restore format string
    jmp RepPrintf           ;ret
;--------------------------------------------------
;PrintBuff - func to print buffer to stdout
;Entry: -
;Exit: stdout
;Destr: rax, rdi, rsi, rdx
;--------------------------------------------------
PrintBuff:
    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1              ;1 - stdout
    lea rsi, [rel Buffer]   ;buffer to print
    mov rdx, BufferLen      ;len buffer
    syscall

    jmp EOP
;--------------------------------------------------
;RestoreBuffer - func to check buffer on overflow
;Entry:
;--------------------------------------------------
RestoreBuffer:

    push rcx                ;save rcx
    lea rcx, [rel Buffer]
    sub rcx, rdi            ;get buf len
    neg rcx                 ;*(-1)

    cmp rcx, MaxBuffLen     ;cmp with max len of buffer
    jne Return              ;if less - ret

    push rax                ;
    push rdi                ;saving reg
    push rsi                ;
    push rdx                ;

    mov rax, 0x01           ;0x01 - fn to write str in console
    mov rdi, 1              ;stdout
    mov rsi, Buffer         ;buffer to write
    mov rdx, BufferLen      ;len
    syscall                 ;system call

    call DtorBuff           ;clean buff

    pop rdx                 ;
    pop rsi                 ;restore registers
    pop rdi                 ;
    pop rax                 ;

    jmp Next

    Return:
    pop rcx
    ret

    Next:
    pop rcx
    lea rdi, [rel Buffer]   ;set addr in first element

    ret
;--------------------------------------------------
DtorBuff:
    push rcx
    push rdi

    lea rdi, [rel Buffer]
    mov rcx, MaxBuffLen         ;repeat max len of buffer times

    Dtor:
    mov byte [rdi], 0           ;\0
    inc rdi                     ;next elem
    loop Dtor

    pop rdi
    pop rcx

    ret
;--------------------------------------------------
EOP:
    push qword [RetAddr]       ;restore return address
    ret
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

RetAddr        dq 0

Arg_str       db "real champion", 0x00
NumberBuff    db 32 dup(0)
NumberBuffLen db $ - NumberBuff

ErrorMessage  db "non specific type", 0x0a
ErrorLen      equ $ - ErrorMessage

FormatParam   dw "%s\n %%n\nbin - %b\noct - %o\ndec - %d\nhex - %x\n$"

Buffer:       db 25 dup(0)
MaxBuffLen    equ 24d
BufferLen     equ $ - Buffer

