all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe 8 256 1