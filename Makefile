all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe
clean:
	*.exe