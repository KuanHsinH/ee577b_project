// Data memory: [0]=96 iterations, [1]=1, [2]=1
    vld r1, 0
    vld r2, 1
    vld r3, 2
loop:
    vxor.ad r3, r3, r2
    vbez r3, skip_1
    vadd.ad r5, r5, r2
skip_1:
    vbez r3, skip_2
    vadd.ad r6, r6, r2
skip_2:
    vbez r3, skip_3
    vadd.ad r7, r7, r2
skip_3:
    vadd.ad r4, r4, r2
    vsub.ad r1, r1, r2
    vbnez r1, loop
    vsd r4, 16
    vsd r5, 17
    vsd r6, 18
    vsd r7, 19
    vsd r3, 20
    vsd r1, 21
    vnop
    vnop
    vnop
    end
