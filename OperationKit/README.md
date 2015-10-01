# Operation Kit

This is a modified version of the code provided by the [Advanced NSOperations Session at WWDC 2015](https://developer.apple.com/videos/wwdc/2015/?id=226).  Some changes have been made to the original code to fix bugs and use `ErrorType` in preference to `NSError`.

# Advanced NSOperations

This shows how to use NSOperations to simplify app architecture. It includes several different kinds of ready-to-use NSOperation subclasses to guarantee that your code will only execute if certain conditions have been met. By composing and chaining these operations together, you can quickly construct complex behaviors with extremely little code.
