xseg segment public 'code'
     assume cs : xseg, ds : xseg, ss : xseg
     org     100h
main proc    near
     mov     bp, OFFSET var
     mov ax, 42
     push ax
     sub  sp, 4
     call near ptr _puti
     add  sp, 6
     mov  ax, OFFSET newline
     push ax
     sub  sp, 4
     call near ptr _puts
     add  sp, 6
     mov     ax, 4C00h
     int     21h
main endp
var  dw      26 dup(0)
newline db 0dh, 0ah, 00h
     extrn _puts : proc
     extrn _puti : proc
xseg ends
     end  main
