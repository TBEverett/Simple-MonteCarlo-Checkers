all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe 8 100 1 1