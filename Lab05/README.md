Lab05 可以說是這門課難度最高的一次 Lab，我們需要實現 convolution 和 transpose convolution 的功能，其中 image matrix 的 size 有三種：8x8、16x16 和 32x32，每個 size 都有 16 張image。題目要求我們使用 SRAM 來存取 image matrix，如果直接用 register 來存 image，面積肯定會爆掉。

這次 Lab 的難點在於 transpose convolution。這部分的演算法我花了很長時間才想出來。在 performance 的部分沒特別優化，個人覺得寫出來已經謝天謝地了，ps.超多人1de沒過。
