# README #

### What is this repository for? ###

EV3toC is a tool written in perl that converts a LEGO® Mindstorms EV3 program to c code. The generated c code is made to run on a platform for the IEEE ORC.

Version 0.0.1 - pre-alpha

### How do I get set up? ###

Requires a PERL installation. Will work with StrawberyPerl in Windows.

Run these commands to get up and running. Note that you will need an EV3 program to parse.
A .ev3 file is a compressed folder that can be uncompressed using a tool like 7-zip.
The uncompressed folder contains multiple files but the only ones that we are concerned with are the .ev3p files. XML descriptions of the program. Please copy the correct .ev3p file and place it in the same directory as the ev32c.pl script. The .ev3p file should also be named Program.ev3p.

Running
"perl ev32c.pl"
will now produce a .c file in the same directory as the perl script.

### Who do I talk to? ###
Contact Bobby Wood at orcinfo@gmail.com