Lab11 要我們練習在 always block 中加入clock gating，並觀察有無 clock gating 對power的影響。 clock gating的概念是關閉未使用的DFF，讓其值保持不變，以減少不必要的功耗。

這次Lab需要我們先設計一個 SNN 電路，相較於 Lab04 的 CNN，難度簡單了很多，可能是為了讓我們更著重在power的分析。題目要求有 clock gating 的版本比沒有 clock gating 的版本功耗要減少 25%。但如果原本的coding style不差，能讓未使用的 DFF 保持在 0，那麼有無 clock gating 對功耗的影響幾乎不大。

這裡有個偷吃步的方法是讓未使用的 DFF 持續在 0 和 1 之間跳動，這樣很容易就能達到減少 25% 功耗的要求，這個方法同學們屢試不爽。
