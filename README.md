# Exe-Shoes 

This is a Windows only project that packages a Shoes project into a more 
developer friendly Windows .exe. It attempts to hide the use of Shoes as
the platform. Basically it merges your app into a copy of Shoes, delete's
built in Shoes ext's and gems and merges in any Gem's you specify that you've
installed in your Windows Shoes.

The result is an .exe with just enough Shoes. No manual. No irb. No debug, no
samples and the static directory is minimal. No need for Cobbler or packaging. 
No clever shy files. Windows 10 will install it. You can customize just about
any Installer and App appearance for the experierence you want for your app's
users.   Of course, you will have to do to some work. 


## Requirements 

* You need Shoes 3.3.3 ,r(2921) or newer installed on your Windows machine doing the 
  packaging
* You'll need a way to, and the graphics skills to create an icon for the Installer and two old time .bmp files
  for the installer. I use Gimp but thats just me. 
* You may have to modify the scripts in the project and NSIS scripts but there's 
  nothing particularly clever or difficult about the Ruby - NSIS is a shock but
  that's the very last place you should be looking to fix things. 

## Contents 

Download the zip or if you have git then you can clone the github repo.
Inside is the ytm\ directory which is a **sample** application
and and an nsis\ directory which contains the nsis installer scripts. Then there is ytm-merge and ytm.yaml which
guide the command line version for the **Sample**. That's for the sample application.  Peek at the yaml
and you'll see it mostly about pointing out where various things for your Shoes is and where your app lives. 
There's sample below. 

The nsis dir contains the NSIS scripts and macros, icons, installer images (in .bmp format - not my problem to
fix). There is a min-shoes.rb which will be copied and modified to call your starting script
instead of shoes.rb

Perhaps you're thinking "I need to know a lot". Perhaps, but it's just scripts.
Nothing to be afraid of and we have graphical way to build that yaml you need. 

## Wizard

Before you get too excited about the GUI wizard, it not __that__ much of a timesaver for
you and you still need to read the rest of this document and do your testing. So, fire up Shoes and run the
`build-exe.rb` script. I'm a command line fan so `$ cshoes.exe path\to\build-exe.rb` but you can do it from 
the Shoes splash screen if you really want to.

![wizard](https://cloud.githubusercontent.com/assets/222691/25981983/f88ee538-3695-11e7-993b-9a6eb4ef2593.png)

That's after I pushed the button to load my test ytm.yaml. Yes, you can edit the yaml file
you have created. Note: you can hover the cursor over many widgets to get some tooltip reminders.

As described below, you need to pick the gems carefully (and all dependent gems that you choice needs). In the 
final screen you can save the yaml and use it to create and exe -- that freezes Shoes for many minutes (3 to 5)
You may also see a button to select your makensis.exe and resourcehacker.exe If those were not installed
in the default location. 

## Command Line Usage 

It's quite possible that you want the exe-shoes packaging to be part of
some other build process you have automated. 

`$ cshoes.exe --ruby ytm-merge.rb`

As you know --ruby means to run Shoes as a mostly standard Ruby with some
ENV['vars'] and Constants you'll find in Shoes. Like DIR and without showing the GUI.

```ruby
# run this with cshoes.exe --ruby ytm-merge.rb
require 'yaml'
require_relative 'merge-exe'
opts = YAML.load_file('ytm.yaml')
here = Dir.getwd
home = ENV['HOME']
appdata =   ENV['LOCALAPPDATA']
appdata  =   ENV['APPDATA'] if ! appdata
GEMS_DIR = File.join(appdata.tr('\\','\/'), 'Shoes','+gem')
$stderr.puts "DIR = #{DIR}"
$stderr.puts "GEMS_DIR = #{GEMS_DIR}"
$stderr.puts "Here = #{here}"
PackShoes::merge_exe opts
```

That **sample** just loads ytm.yaml and calls the Shoes module function
PackShoes::merge_exe in merge-exe.rb which uses the ytm.yaml settings and goes
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
include_gems:
 - sqlite3
 - nokogiri-1.6.7.1-x86-mingw32
```
 Remember - That is just a demo!  Give it a try to see how it works. 
 
 WARNING: because it's yaml and read by Ruby you must use Ruby Windows file path
 syntax. There is a special place in hell if you use Windows `\`. To be safe
 do not have any spaces in any of the path or file names. 
 
 app_loc: is where your app to package is and app_start: is the starting script
 in app_loc. app_png is your app icon in png format. (if you need it - it's good idea). 
 You certainly want your own Windows icon (.ico) for the your app app_ico: is
 where point to it. If you want a different icon for the installer - app_installer_ico:
 
 Gem are fun. You can include Shoes built in gems like sqlite and nokogiri as shown above
 and you can include gems you have installed in the Shoes that is running the script. 
 If you can't install the Gems in Shoes, then you can't include them.
 We don't automatically include dependent gems and libraries. You'll have to do that yourself with
 proper entries in your yaml file. 
 
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

## Where is my app.exe?

If successful it's in pkg\. Move it from there to your website or test machine
or double click it to launch the installer just like a user would. Test out how your installer
looks. Install your app. Run it on the same machine if you like -- it's independent
of any existing Shoes you or your users might have.  Uninstall it - Shoes won't change.
Poke around in `C:\"Program Files (86)"\myapp` - notice the differences between between
the insides of `C:\"Program Files (86)"\Shoes`


## Troubleshooting
nsis is a little weird - the messages for packaging may display 
before the starting messages from Ruby.  You'll have no trouble telling whether
the error is from Ruby or NSIS. 

If you encounter errors, remember that a full copy is made into packdir\
and a copy/modified nsis script is in packdir\nsis so you can see what was
done at the point of failure.

### Beware 

The most likely source of trouble will be name collisions in lib\* and static\*
__if__ you happen to use those directories in your app. You will have to adjust
your app. You can't change Shoes at this point but you can fix your code. For example
having a lib\shoes\ directory in your app is not a good idea.


 


