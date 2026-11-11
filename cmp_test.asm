; cmp_test.asm - the course CMP test program (same program on every node)
;
; Every processor sends one packet to each of three other processors and
; receives the three packets sent to it (handout item 7, adapted to the
; 4x4 mesh of Project 1). Node N is the processor at mesh coordinate
; (x = N % 4, y = N / 4). The packets to send are pre-loaded in data memory
; words 0-2 of each node (cmp_test.dmem.N.fill):
;   MEM[0]  to the right neighbour   (x + 1 mod 4, same row)
;   MEM[1]  to the lower neighbour   (same column, y + 1 mod 4)
;   MEM[2]  to the opposite node     (x + 2 mod 4, y + 2 mod 4)
; Each of the three patterns is a permutation of the nodes, so every node
; also receives exactly three packets. Processors in columns 0 and 1 use
; odd virtual channels (vc = 1), processors in columns 2 and 3 even ones
; (vc = 0). The three received packets are stored to MEM[5]-MEM[7] in
; arrival order; the order depends on the pipeline timing of the design
; and on the mesh.
;
; Packet format (bit 0 = MSB): bit 0 vc, bit 1 reserved, bits 2-3
; destination x, bits 4-5 destination y, bits 6-7 reserved, bits 8-15 unary
; hop count (Manhattan distance), bits 16-31 source node, bits 32-63
; payload (here 0x0000SSDD: source SS, destination DD).
;
; NIC registers (memAddr[16:17] = 11): 0xC000 input buffer, 0xC001 input
; status, 0xC002 output buffer, 0xC003 output status.
;
; Assembled word by word, this is cmp_test.imem.N.fill (the same file for
; every node; a branch target is the byte address of its label).
        vnop                    ; F0000000
        vld   r10, 0            ; packet 1 (right neighbour)
        vld   r20, 1            ; packet 2 (lower neighbour)
        vld   r30, 2            ; packet 3 (opposite node)
tx1:    vld   r1, 0xC003        ; output channel status
        vbnez r1, tx1           ; wait while the output buffer is full
        vsd   r10, 0xC002       ; send packet 1
tx2:    vld   r1, 0xC003
        vbnez r1, tx2
        vsd   r20, 0xC002       ; send packet 2
tx3:    vld   r1, 0xC003
        vbnez r1, tx3
        vsd   r30, 0xC002       ; send packet 3
rx1:    vld   r2, 0xC001        ; input channel status
        vbez  r2, rx1           ; wait until a packet has arrived
        vld   r5, 0xC000        ; read the packet (this empties the buffer)
rx2:    vld   r2, 0xC001
        vbez  r2, rx2
        vld   r15, 0xC000
rx3:    vld   r2, 0xC001
        vbez  r2, rx3
        vld   r25, 0xC000
        vsd   r5, 5             ; MEM[5] <- first received packet
        vsd   r15, 6            ; MEM[6] <- second
        vsd   r25, 7            ; MEM[7] <- third
        end                     ; 00000000: end of program
