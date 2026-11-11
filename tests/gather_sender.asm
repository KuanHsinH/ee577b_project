  0: F0000000  vnop
  4: 81400000  vld r10, 0
  8: 8020C003  tx: vld r1, 0xC003
 12: 8C200008  vbnez r1, tx
 16: 8540C002  vsd r10, 0xC002
 20: 00000000  end
