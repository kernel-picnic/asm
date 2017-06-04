TASM /zi main
TASM /zi menu
TASM /zi io

TLINK /vi /3 main.obj menu.obj io.obj

TD main.exe