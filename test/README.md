# qixall - tests

## Install

nothing more, everythind is installed with ruby.

## Run
All tests run in `test/` folder.

Simply run file.

~~~
cd test/
ruby test_area.rb
~~~


## Programming tests

add this ruby code to find our lib, relative to `tests/` folder.

~~~
$:.push(File.expand_path(File.dirname(__FILE__) + '/..'))
~~~

