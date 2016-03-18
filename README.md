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

* You need Shoes 3.3.1 (r2480 or newer) installed on your Windows machine doing the 
  packaging
* You need NSIS Unicode installed on your Windows machine. Version 2.45.6 is good
  Please use NSIS Unicode if you value your users. 
* You need [http://www.angusj.com/resourcehacker](Resource Hacker) or some way
  to set the icon of an exe
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

`$ cshoes.exe --ruby ytm-merge.rb`

As you know --ruby means to run Shoes as a mostly standard Ruby with some
ENV['vars'] and Constants you'll find in Shoes. Like DIR and without showing the GUI.

The **sample** just loads ytm.yaml and calls the Shoes module function
PackShoes::merge_exe 

Modify pack.rb to load the .yaml file for your app.  The .yaml for the example is 
```
app_name: Ytm
app_version: 'Demo'
app_loc: C:/Projects/exe-shoes/ytm/
app_start: ytm.rb
app_png: ytm.png
app_ico: C:/Projects/exe-shoes/ytm/ytm.ico
app_installer_ico: C:/Projects/exe-shoes/ytm/ytm.ico
installer_sidebar_bmp: E:/icons/ytm/installer-1.bmp
installer_header_bmp: E:/icons/ytm/installer-2.bmp
publisher: 'YTM Corp Inc'
website: 'https://github.com/Shoes3/shoes3'
hkey_org: 'mvmanila.com'
license: C:/Projects/exe-shoes/ytm/Ytm.license
include_exts:
 - ftsearch
 - chipmunk
include_gems:
 - sqlite3
 - nokogiri-1.6.7.1-x86-mingw32
 - ffi-1.9.10-x86-mingw32
 - rubyserial-0.2.4
```
 Remember - This just a demo!  
 
 app_loc: is where your app to package is and app_start: is the starting script
 in app_loc. app_png is the Shoes icon (if you need it) 
 You certainly want your own Windows icon (.ico) for the your app app_ico: is
 where point to it. If you want a different icon for the installer -
 
 If you want to include Shoes exts, ftsearch and chipmunk you would list them here.
 Unless you really do need chipmunk you shouldn't add it like I show above. Since you're not
 going to get a manual, you don't need ftsearch.
 
 Gem are fun. You can include Shoes built in gems like sqlite and nokogiri as shown above
 and you can include gems you have installed in the Shoes that is running the script
 (cshoes.exe) . If you can't install the Gems in Shoes, then you can't include them.
 We don't automatically include dependent gems. You'll have to do that yourself with
 proper entries in your yaml file as I've shown above, 'rubyserial' requires 'ffi'
 
### app_name, app_version:

Beware! these are sent to the nsis script and it's very particular. Even worse
pack.rb uses app_name: to do multiple duty. Expect some confusion and trouble. 
Nothing that couldn't be fixed with another yaml entry and some coding. Maybe 
app_full_name: or the other side could be app_exe_name: Or both. 

NSIS expects app_version to be a string and all it really does is name the exe
`#{app_name}-#{app_version}`. Expect annoyance. 

Read the merge-exe.rb script. It's not that big and it's yours now to do what
you want.

## NSIS

NSIS has it's own scripting language and the scripts included in this project
are just slightly modified from what Shoes uses for building Shoes exe's.  
You can and probably should modify things for what you want the installer 
to do and look like.

It you're going to use the included default script you'll certainly want to 
replace the installer-1.bmp and install-2.bmp with your own images. You'll want
width and height to be very close to what is used. These have too be ancient format bmps
24 bit, no color space.  Not my rules. Accept what NSIS wants. 

### base.nsis

If you peek at base.nsis you'll see some Shoes entries that you probably 
don't want people to see if you're trying to hide Shoes or behavior you 
don't want. I don't want to sound too cavalier, but it's your base.nsi and pack.rb
to modify as you need. You'll have to consider the Liscensing terms in COPYING.txt and rewrite 
that for your code while giving credit to what is there. 


