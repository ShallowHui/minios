%include "boot.inc"
section mbr vstart=0x7c00 ;----BIOS把启动区加载到内存的该位置，所以需设置地址偏移量

;----卷屏中断，目的是清屏
mov ax,0x0600
mov bx,0x0700
mov cx,0
mov dx,0x184f
int 0x10

;----直接往显存中写数据
mov ax,0xb800
mov gs,ax
mov byte [gs:0x00],'H'
mov byte [gs:0x02],'e'
mov byte [gs:0x04],'l'
mov byte [gs:0x06],'l'
mov byte [gs:0x08],'o'
mov byte [gs:0x0a],','
mov byte [gs:0x0c],'m'
mov byte [gs:0x0e],'i'
mov byte [gs:0x10],'n'
mov byte [gs:0x12],'i'
mov byte [gs:0x14],'O'
mov byte [gs:0x15],0xa4 ;指定文本模式下的闪烁和背景
mov byte [gs:0x16],'S'
mov byte [gs:0x17],0xa4
mov byte [gs:0x18],'!'

mov eax,Loader_start_sector
mov bx,Loader_addr
mov cx,1
call read_disk

jmp Loader_addr

read_disk: ;完成读取硬盘数据的函数

    mov esi,eax ;备份寄存器
    mov di,cx

    ;遵循IDE硬盘标准，第一步指定要读取的扇区数
    mov dx,0x1f2 ;指定硬盘的扇区完成情况端口
    mov al,cl
    out dx,al
    mov eax,esi

    ;第二步，指定扇区地址，以LBA方式
    mov dx,0x1f3
    out dx,al
    mov cl,8
    shr eax,cl
    mov dx,0x1f4
    out dx,al
    shr eax,cl ;同或
    mov dx,0x1f5
    out dx,al
    shr eax,cl
    and al,0x0f
    or al,0xe0
    mov dx,0x1f6
    out dx,al

    ;第三步，向0x1f7端口写入读命令
    mov dx,0x1f7
    mov al,0x20
    out dx,al

    ;第四步，轮询硬盘状态，这里还不是I/O中断的方式
    .not_ready:
        
        nop
        in al,dx
        and al,0x88
        cmp al,0x08
        jnz .not_ready

    ;第五步，从0x1f0端口读取数据
    mov ax,di
    mov dx,256
    mul dx ; ax = ax * dx
    mov cx,ax
    mov dx,0x1f0

    .go_read:

        in ax,dx
        mov [bx],ax
        add bx,2
        loop .go_read
    
    ret


;----512字节的最后两字节是启动区标识
times 446-($-$$) db 0

;----活动分区标志
active_flag db 0x80

times 510-($-$$) db 0

db 0x55,0xaa