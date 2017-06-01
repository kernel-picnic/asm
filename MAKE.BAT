tasm /zi main
tasm /zi io
tasm /zi menu

tlink /vf /3 main.obj + io.obj + menu.obj

td main