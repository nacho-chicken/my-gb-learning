# Time to learn GB assembly

I've always wanted to make a game for the Game Boy, but haven't gotten around
to properly learning. Most of what I've worked in previously have been C-style
languages, so moving to assembly is a slight leap. Needless to say, I've
bounced off of it a couple of times. For one thing, the existing tutorials
available are either not the best or incomplete. Rare was the guide that went
past a "Hello world!" Even then, they don't teach the most important thing:
The ***WHY***

If I was going to learn, I was going to have to stop wading in the kiddie pool
and cannonball into the deep end without a floatie.

This repo is meant to be a look into the mindset of someone learning this
for the first time. The way I'm learning is laid out similarly to a tutorial;
each new feature I work on builds on the last in a natural way and focuses on
a new piece of hardware or a new function. Changes are made to older code
as well, in order to optimize or take advantage of new knowledge. From the
structure, you can gleam lots of information that you'd have to spend hours
poring through the fantastic but über-technical documentation to learn.
It's a purely personal project, but if you want to use anything from it,
be it code, graphics, music, etc. **please** do so! It's licensed under
the CC-BY 4.0 license, so you're free to do pretty much whatever you want to
with it.

Code is commented heavily in order to facilitate reading it for the purposes
of learning. That said, **this is not a tutorial**, so don't expect to be
taught like you would in a classroom. Think of it more like reading notes
from someone who's already been to the class.

I hope this helps anyone out there.

## What if I want to build it instead?

There are makefiles provided for each topic. Just go into the directory and
run
```
$ make all
```

As far as dependencies go, you will need:
- RGBDS v0.5.2 or later
- GNU Make (4.3 was used by me)

...but if you're working on learning Game Boy assembly, you probably already
have both of those installed.

