I had started working for a company whoms application is in pascal so apart of the jr dev program we were to make a game.
I made pong, essentially in 2hrs, I believe you were suppose to take a week to do the project. I may have gone over time a bit,
but I was joking with my lead on a code review and he said i should network it. So I did, but never finished since I got involved
in contributing to their code base. The networking works and essentially all the needs to happen is handling for the network packages
in the game its self. There is a lobby system its a lan setup but by technicality you should be able to port forward without issue
if you know what your doing. The notable item is the network dispatchin system and the dictionary. there is some pretty nice little
logic wrappers i wrote it, threading. etc etc. the network units themselves arnt to bad for a jr. dev and within my first few weeks
of every writing anything in pascal. hope you like. and if there are things here that inspire you leave a comment for me in your code
;)

I've thought about finishing it, but currently between work and other personal projects this isnt my first prioriety. 

Whats here:

-WinSock2 implmentations in pascal
-A Form as a Frame loader to dynamically control whats rendered to the form
-a seperate system for being able to create units with a 'is a' realtionship
  and load them based on selection
-conditionally controlling how those frames operate based on the condition they
  are loaded
-a network dispatch/handler system for being able to define an api for connected 
  systems with roles or other conditional handling
-believe there is some use of higher order functions, maybe? been a few months
-use of polymorphism, in the few spots, i do believe its reasonably elegent
-handling of circular references. 

All in all i belive that in the first 3 weeks of me interacting with a new language this shows a fairly clean picture that
i understand more then just the simple concepts programatically. there are many different paradigms and systems all tightly
packed into the small project. even some small reactive ui design concepts. 

Thanks for checking it out,
nix
