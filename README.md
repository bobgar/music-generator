# music-generator
a simple music generator toy written with godot and playable at https://bobgar.itch.io/music-generator

Samples were listed as CC0.  The piano is from Versilian Studios LLC. (https://vis.versilstudios.com/products.html#freeware) while the rest were obtained by searching for C3 samples on https://freesound.org

This generator was inspired by a chapter in the book Procedural Generation in Game Design.  Specifically Audio and Composition by Bronson Zgeb.  My general approach is outlined below.

Always starts at the root note.
All notes are in a two octave range and I use one sample sped up / down to make the right sound.  Root is always C.
Each sub-division of time has a probability to place a note, with higher probability on the larger subdivisions.
Music steps in runs, with step size based on probability and number of steps before changing direction based on probability.
Right now just using pentatonic scale
Randomly adds chords based on probability matrix for the timestamp the note occurs.
Generates a motif, called A below, that is repeated in the song, then mixes in things from outside the motif.
The third repeat currently always starts on the 5th
General form of the music right now is:
A/B
A/C
D/E
A/Root note
(NOTE letters above are section and have nothing to do with note)