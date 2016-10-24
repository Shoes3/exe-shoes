# Exe-Shoes 

This is a Windows only project that packages a Shoes project into a more 
developer friendly Windows .exe. It attempts to hide the use of Shoes as
the platform. Basically it merges your app into a copy of Shoes, delete's
built in Shoes ext's and gems and merges in any Gem's you specify that you've
installed in your Windows Shoes.

The result is .exe with just enough Shoes. No manual. No irb. No debug, no
samples and the static directory is minimal. No need for Cobbler or packaging. 
No clever shy files. 

At some point in the future there might be a GUI (packaged Shoes.app) to create the yaml,
and run the build for you. Don't wait for that, it's only eye candy and if it is written
probably doesn't do what you want. 

## Requirements 

* You need Shoes 3.3.1 ,r2480 or newer installed on your Windows machine doing the 
  packaging
* You need NSIS Unicode installed on your Windows machine. Version 2.45.6 is good
  but can be hard to find. [http://shoes.mvmanila.com/public/shoesdeps/mingw/nsis-2.46.5-Unicode-setup.exe]
  Please use NSIS Unicode if you value your users. 
* You need [http://www.angusj.com/resourcehacker] Resource Hacker or some way
  to set the icon of an exe
* Must be willing to learn enough about NSIS packaging and accept it's rules.
* Must be willing to use the Windows commandline (or the msys commandline)
* You may have to modify the scripts in the project and NSIS scripts.


## Contents 

Download the zip or if you have git then you can clone the github repo.
Inside is ytm\ directory which is a sample application
and and an nsis\ directory which contains the nsis installer scripts. Then there is ytm-merge  ytm.yaml. There is a pack.rb which does all the work. You'll probably
want to modify it to load the yaml file for your app. The nsis dir contains
the NSIS script and macros, icons, installer images (in .bmp format - not my problem to
fix). There is a min-shoes.rb which will be copied and modified to call your starting script
instead of shoes.rb

Perhaps you're thinking "I need to know a lot". Perhaps, but it's just scripts.
Nothing to be afraid of.

## Usage 

`$ cshoes.exe --ruby ytm-merge.rb`

As you know --ruby means to run Shoes as a mostly standard Ruby with some
ENV['vars'] and Constants you'll find in Shoes. Like DIR and without showing the GUI.

The **sample** just loads ytm.yaml and calls the Shoes module function
PackShoes::merge_exe in merge-exe.rb which reads the ytm.yaml settings and goes
to work building an exe. 

The .yaml for the example is 
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
 Remember - That is just a demo!  Give it a try to see how it works. 
 
 WARNING: because it's yaml and read by Ruby you must use Ruby Windows file path
 syntax. There is a special place in hell if you use Windows `\`. To be safe
 do not have any spaces in any of the path or file names. 
 
 app_loc: is where your app to package is and app_start: is the starting script
 in app_loc. app_png is your app icon in png format. (if you need it - it's good idea). 
 You certainly want your own Windows icon (.ico) for the your app app_ico: is
 where point to it. If you want a different icon for the installer - app_installer_ico:
 
 If you want to include Shoes exts, ftsearch and chipmunk you would list them here.
 Unless you really do need chipmunk you shouldn't add it like I show above. Since you're not
 going to get a manual, you don't need ftsearch so delete those two lines.
 
 Gem are fun. You can include Shoes built in gems like sqlite and nokogiri as shown above
 and you can include gems you have installed in the Shoes that is running the script
 like ffi and rubyserial in the example. If you can't install the Gems in Shoes, then you can't include them.
 We don't automatically include dependent gems. You'll have to do that yourself with
 proper entries in your yaml file as I've shown above, 'rubyserial' requires 'ffi'
 
### app_name, app_version:

Beware! these are sent to the nsis script and it's very particular. Even worse
pack.rb uses app_name: to do multiple duty. Some confusion is possible. 

NSIS expects app_version to be a string and all it really does is name the exe
`#{app_name}-#{app_version}`. Expect annoyance. 

Read the merge-exe.rb script. It's not that big and it's yours to do what
you want.

## NSIS

NSIS has it's own scripting language and the scripts included in this project
are just slightly modified from what Shoes uses for building Shoes exe's.  
You can and probably should modify things for what you want the installer 
to do and look like.

It you're going to use the included default script you'll certainly want to 
replace the installer-1.bmp and install-2.bmp with your own images. You'll want
width and height to be very close to what is used. These have to be ancient format bmps
24 bit, no color space.  Not my rules. Accept what NSIS wants. 

### base.nsis

If you peek at base.nsis you'll see some Shoes entries that you probably 
don't want people to see if you're trying to hide Shoes or behavior you 
don't want. I don't want to sound too cavalier, but it's your base.nsi and merge-exe.rb
to modify as you need. You can do some customization of the installer with as shown in
the ytm.yaml above. The defaults are Shoes based. 

You'll have to consider the Liscensing terms. You should acknowledge the copyrights and terms 
of some of the code. As written, if you have a license: entry in your .yaml 
that text file it will be merged with normal Shoes T&C's - yours will be at the
top of what the user will see.

### Where is my app.exe?

If successful it's in pkg\. Move it from there to your website or test machine
or double click it to launch the installer just like a user would. Test out how your installer
looks. Install it. Run it on the same machine if you like -- it's independent
of any existing Shoes you or your users might have.  Uninstall it - Shoes won't change.
Poke around in `C:\"Program Files (86)"\myapp` - notice the differences between between
the insides of `C:\"Program Files (86)"\Shoes`


### Troubleshooting
nsis is a little weird - the messages for packaging may display 
before the starting messages from Ruby.  You'll have no trouble telling whether
the error is from Ruby or NSIS. 

If you encounter errors, remember that a full copy is made into packdir\
and a copy/modified nsis script is in packdir\nsis so you can see what was
done at the point of failure.


 


