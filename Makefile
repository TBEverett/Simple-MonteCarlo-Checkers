all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe 8 10000 1 1