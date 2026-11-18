// Data memory: [0]=96 iterations, [1]=1, [2]=3
    vld r1, 0
    vld r2, 1
    vld r7, 2
loop:
    vadd.ad r4, r4, r2
    vsd r4, 25
    vadd.ad r9, r9, r4
    vxor.ad r10, r10, r9
    vxor.ad r3, r3, r2
    vbez r3, skip_toggle
    vadd.ad r5, r5, r2
skip_toggle:
    vadd.ad r6, r6, r2
    vand.ad r6, r6, r7
    vadd.ad r11, r11, r6
    vbez r6, skip_phase
    vadd.ad r8, r8, r2
skip_phase:
    vsub.ad r1, r1, r2
    vbnez r1, loop
    vsd r4, 16
    vsd r5, 17
    vsd r8, 18
    vsd r1, 19
    vsd r6, 20
    vsd r3, 21
    vsd r9, 22
    vsd r10, 23
    vsd r11, 24
    vnop
    vnop
    vnop
    end
