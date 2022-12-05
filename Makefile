all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe 8 10000 0 1