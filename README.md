# Exe-Shoes 

This is a Windows only project that packages a Shoes project into a more 
developer friendly Windows .exe. It attempts to hide the use of Shoes as
the platform. Basically it merges your app into a copy of Shoes, delete's
built in Shoes ext's and gems and merges in any Gem's you specify that you've
installed in you Windows Shoes.

At some point in the future there might be a GUI (packaged Shoes.app) to create the yaml,
and run the build for you. Don't wait for that, it's only eye candy and if it is written
probably doesn't do what you want. 

## Requirements 

* You need Shoes 3.3.x installed on your Windows machine. 
* You need NSIS Unicode installed on your Windows machine. Version 2.45.6 is good
  Please be Unicode if you value your users. 
* Must be willing to learn enough about NSIS packaging and accept it's rules.
* Must be willing to use the Windows commandline (or the msys commandline)
* your may have to modify Ruby and NSIS scripts.
* You'll probably want a git client and configure it on your Windows machine.

## Contents 

You need to clone this project. Inside is ytm/ which is a sample application
and ytm.yaml. There is a pack.rb which does all the work. You'll probably
want to modify it to load the yaml file for your app. The nsis dir contains
the NSIS script and macros, icons, installer images (in .bmp - not my problem to
fix. There is a min-shoes.rb which is modified to call your starting script

Perhaps you're thinking "I need to know a lot". Yes. Me too.


