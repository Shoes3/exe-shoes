# Exe-Shoes 

This is a Windows only project that packages a Shoes project into a more 
developer friendly Windows .exe. It attempts to hide the use of Shoes as
the platform. Basically it merges your app into a copy of Shoes, delete's
built in Shoes ext's and gems and merges in any Gem's you specify that you've
installed in you Windows Shoes.

The result is .exe with just enough Shoes. No manual. No irb. No debug, no
samples and the static directory is gone. We don't need Cobbler or packaging. 

At some point in the future there might be a GUI (packaged Shoes.app) to create the yaml,
and run the build for you. Don't wait for that, it's only eye candy and if it is written
probably doesn't do what you want. 

## Requirements 

* You need Shoes 3.3.x installed on your Windows machine. 
* You need NSIS Unicode installed on your Windows machine. Version 2.45.6 is good
  Please use NSIS Unicode if you value your users. 
* You [http://www.angusj.com/resourcehacker](Resource Hacker) or some way
  to set the icon of and exe
* Must be willing to learn enough about NSIS packaging and accept it's rules.
* Must be willing to use the Windows commandline (or the msys commandline)
* You may have to modify the scripts in the project and NSIS scripts.
* You'll probably want a git client and configure it on your Windows machine.

## Contents 

You'll want to git clone this project. Inside is ytm/ which is a sample application
and ytm.yaml. There is a pack.rb which does all the work. You'll probably
want to modify it to load the yaml file for your app. The nsis dir contains
the NSIS script and macros, icons, installer images (in .bmp format - not my problem to
fix). There is a min-shoes.rb which will be modified to call your starting script
instead of shoes.rb

Perhaps you're thinking "I need to know a lot". Yes. Me too.

## Usage 

`$ cshoes.exe --ruby pack.rb`

As you know --ruby means to run Shoes as a mostly standard Ruby with some
ENV['vars'] and Constants you'll find in Shoes. Like DIR and without the GUI.

Modify pack.rb to load the .yaml file for your app.  The .yaml for the example
ytm is 
```
system_nsis: C:/Program Files (x86)/NSIS/Unicode/makensis.exe
app_name: Ytm
app_version: 2
app_loc: E:/exe-shoes/ytm/
app_start: ytm.rb
app_nsis_dir: 'nsis'
app_ico: E:/exe-shoes/ytm/ytm.ico
include_exts:
 - chipmunk
include_gems:
 - sqlite3
 - nokogiri-1.6.7.1-x86-mingw32
 - ffi-1.9.10-x86-mingw32
 - rubyserial-0.2.4
 ```
 This just a demo!  system_nsis: isn't used as I write this nor is app_nsis_dir: 
 app_loc: is where your app to package is and app_start: is the starting script
 in app_loc. You certainly want your own icon (.ico) for the installer and app_ico: is
 where point to it.
 
 If you want to include Shoes exts, ftsearch and chipmunk you would list them here.
 Unless you really do need chipmunk you shouldn't add like I show above. Since you're not
 going to get a manual, you don't need ftsearch.
 
 Gem are fun. You can include Shoes built in gems like sqlite and nokogiri as shown above
 and you can include gems you have installed in the Shoes that is running the script
 (cshoes.exe) . If you can't install the Gems in Shoes, then you can't include them.
 We don't automatically include dependent gems. You'll have to do that yourself with
 proper entries in your yaml file as I've shown above, 'rubyserial' requires 'ffi'
 
 === app_name, app_version:

Beware! these are sent to the nsis script and it's very particular. Even worse
pack.rb uses app_name: to do some things. Expect some confusion and trouble. 
Nothing that couldn't be fixed with another yaml entry and some coding. Maybe 
app_full_name: or the other side could be app_exe_name: Or both. 

== NSIS

NSIS has it's own scripting language and the scripts included in this project
are just slightly modified from what Shoes uses for building Shoes exe's.  
You can and probably should modify things for what you want the installer 
to do and look like.

It you're going to use the included default script your certainly want to 
replace the installer-1.bmp and install-2.bmp with your own images. You'll want
width and height to be very close to what is used. 

=== base.nsis

If you peek at base.nsis you'll see some Shoes entries that you probably 
don't want people to see if you're trying to hide Shoes or behavior you 
don't want. I don't want to sound too cavalier, but it's your base.nsi and pack.rb
to modify as you need.


