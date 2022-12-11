all:
	nvcc proyecto.cu -o proyecto
	proyecto.exe 8 10000 1 1
short:
	nvcc proyectoshort.cu -o proyectoshort
	proyectoshort.exe 8 18000 1 1