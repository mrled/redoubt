#  Visualizations

* The original idea: sha512 hash block
    * Show easter eggs, like if hunter2 is the password, change all values to asterisks
    * I like that it changes every time a character is entered - it's just hashing the user input one character at a time
    * It is nice and fast, which is good for the app, but bad for password storage
    * When moving to argon2, the result isn't as nice to lookup
    * Idea: sha512 hash the argon2 output and show that. also obfuscates it in case someone is worried about that.
* From Papa: animate stars falling from random places on the screen into the text field
    * Use taptic engine to make little bumps when they hit the field
* From Ben: Something like Matrix code?
* In general
    * Something that feels like entering a password in a movie
    * Haptic feedback that feels satisfying, like entering your password feels nice. Like how the ChatGPT app taps at you when it responds, it feels good.
    * Each character should change the visualization

