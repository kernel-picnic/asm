TASM /zi main
TASM /zi menu
TASM /zi io
TASM /zi rand

TLINK /vi /3 main.obj menu.obj io.obj rand.obj

TD main.exe