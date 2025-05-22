# Single-Precision-Floating-Point-IEEE-754-values-multiplication-ARM-algorithm
The function returns a result of a multiplication of two single precision floating point values (IEEE 754). The function has been created using ARMv7 instructions and for Thumb mode.
To use the function in your code you have to:
1) Add the file to your workspace:

![](images/workspace.png)

2) Write the prototype of the function (I use uint32_t as a type of returning values because I need to do some logical operations on the results. This is still the same value, but compiler allows me to do some logic operations):

![](images/prototype.png)

3) Use the function in code:

 ![](images/usage.png)
