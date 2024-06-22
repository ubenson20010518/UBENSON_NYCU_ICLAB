Lab 05可以說是這門課難度最高的一次Lab，我們需要實現 convolution 和 transpose convolution 的功能，其中image matrix的size有三種：8x8、16x16 和 32x32，每個size 都有 16 張image。題目要求我們使用 SRAM 來存取image matrix，如果直接用 register 來存image ，面積肯定會爆掉。

這次 Lab 的難點在於 transpose convolution。這部分的演算法我花了很長時間才想出來。在performance的部分沒特別優化，個人覺得寫出來已經謝天謝地了，ps.超多人1de沒過。
