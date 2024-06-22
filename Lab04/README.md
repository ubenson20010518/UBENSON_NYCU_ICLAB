Lab 04 要我們完成 CNN 的架構，運算部分包括 padding、convolution、max pooling、normalization 和 activation function。這次題目要求我們使用 DesignWare IP，並且有面積限制，因此需要盡可能的共用硬體。在合電路過程中，我發現了一個很有趣的 bug：DesignWare 提供的 dot product，也就是乘完再加功能，竟然比直接使用乘法和加法佔用更大的面積。

這次 Lab 是我第一次寫超過 1000 行的 Verilog，也是第一次邊吃飯邊debug，但打完這次還不能鬆懈，下次更難。
