# Qixall

Qixall, a qix like game - opensource - 2D Game - ruby - Gosu

## LICENSE
GPL v3
See [LICENSE.txt](LICENSE.txt)


## status
Not working, some primitiv code `coordinate`, `Line`, `Polygon`, and Gosu learnig

## Install

Linux tested only.

### rvm
Install ruby (with rvm)
OK with ruby-2.4

~~~
time rvm install ruby-2.4
real  5m4.130s
user  5m27.492s
sys 0m22.380s
~~~

### Gosu
~~~
sudo apt  install build-essential libsdl2-dev \
                  libsdl2-ttf-dev libpango1.0-dev \
                  libgl1-mesa-dev libopenal-dev libsndfile1-dev
~~~

### qixall code

~~~
git clone
rvm use 2.4
bundler install
~~~

## Run qixall

~~~
cd qixall
ruby qixall.rb
~~~

## Editor

This project includes a game editor, fully opensource and hackable for your own
needs.

### Run editor

~~~
cd qixall
ruby editor.rb
~~~

### Editor help

Actions and keyboard

(for up-to-date bindings see the code [editor.rb](editor.rb) `def button_down`

* ESC - quit - no confirm
* F1 - load an area playground (polygon data structure) - loop over files `data/playground*.txt`
* F2 - show / hide grid
* F3 - increase grid size
* F4 - decrease grid size
* click left - select a point (snap to the grid - even hidden), select a tool first
* click right - empty current `@area_click` - tool area
* space - quit current tool => :none
* a - area mode : draw an area (only vertical horizontal edges)
* f - free lines : cannot be saved for now free line, 2 click for drawing
* m - multi line shape : not saved - last click start a new line
* d - dump (save) the current area (line are not saved)
* l - load - read an area (`@area_click`) from file 'data/area*.txt'
* . - (dot) test polygon inside outside detection (print stdout)
* -/+ - increase / decrease monster draw factor, *doesn't work any more*.

Output format of the editor

[data/area.txt](data/area.txt) See: [area.rb](area.rb)
~~~
Polygon:
 (255,204)
 (459,204)
 (459,255)
 (408,255)
 (408,306)
 (357,306)
 (357,255)
 (255,255)
~~~

## Some interesting links to share

## Unit test

Work in progess See `test/`
