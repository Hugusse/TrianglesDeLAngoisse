# Variables
NASM_FLAGS=-felf64 -Fdwarf -g
GCC_FLAGS=-lm -fPIC -fno-pie -no-pie -z noexecstack --for-linker /lib64/ld-linux-x86-64.so.2 -lX11

# Dossier des étapes et des fonctions
ETAPES_DIR=etapes
FUNCTIONS_DIR=functions
OUTPUT_DIR=output

# Liste des fichiers ASM dans functions/
FUNCTIONS_SOURCES=$(wildcard $(FUNCTIONS_DIR)/*.asm)
FUNCTIONS_OBJECTS := $(patsubst $(FUNCTIONS_DIR)/%.asm,$(OUTPUT_DIR)/%.o,$(FUNCTIONS_SOURCES))
ETAPE_OBJECTS := $(patsubst $(ETAPES_DIR)/%.asm,$(OUTPUT_DIR)/%.o,$(wildcard $(ETAPES_DIR)/*.asm))

# Règle principale : compiler toutes les étapes
all: etape1 etape2 etape3 etape4_1 etape4_2
	echo "Les exécutables des étapes sont dans $(OUTPUT_DIR)/"

# Fonction pour assembler un fichier et ses dépendances
assemble: 
	@if [ -z "$(file)" ]; then \
		echo "Erreur : Spécifiez un fichier comme second argument, exemple : make assemble file=etape1"; \
		exit 1; \
	fi
	
	@mkdir -p $(OUTPUT_DIR)
	
	@if [ -f $(ETAPES_DIR)/$(file).asm ]; then \
		echo "Assemblage de $(ETAPES_DIR)/$(file).asm"; \
		nasm $(NASM_FLAGS) $(ETAPES_DIR)/$(file).asm -o $(OUTPUT_DIR)/$(file).o; \
		for func in $(FUNCTIONS_SOURCES); do \
			echo "Assemblage de $$func"; \
			nasm $(NASM_FLAGS) $$func -o $(OUTPUT_DIR)/$$(basename $$func .asm).o; \
		done; \
	else \
		echo "Fichier $(ETAPES_DIR)/$(file).asm non trouvé."; \
	fi

# Règle pour chaque étape, crée l'exécutable
etape1: $(ETAPES_DIR)/etape1.asm $(FUNCTIONS_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	make assemble file=etape1
	gcc $(OUTPUT_DIR)/etape1.o $(OUTPUT_DIR)/drawLines.o $(OUTPUT_DIR)/myrandom.o $(OUTPUT_DIR)/distance_points.o -o $(OUTPUT_DIR)/etape1.out $(GCC_FLAGS)
	echo "$(OUTPUT_DIR)/etape1.out a été créé"

etape2: $(ETAPES_DIR)/etape2.asm $(FUNCTIONS_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	make assemble file=etape2
	gcc $(OUTPUT_DIR)/etape2.o $(OUTPUT_DIR)/fillTriangle.o $(OUTPUT_DIR)/draw_one_triangle.o $(OUTPUT_DIR)/determinant.o $(OUTPUT_DIR)/myrandom.o -o $(OUTPUT_DIR)/etape2.out $(GCC_FLAGS)	
	echo "$(OUTPUT_DIR)/etape2.out a été créé"

etape3: $(ETAPES_DIR)/etape3.asm $(FUNCTIONS_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	make assemble file=etape3
	gcc $(OUTPUT_DIR)/etape3.o $(OUTPUT_DIR)/draw_one_triangle.o $(OUTPUT_DIR)/fillTriangle.o $(OUTPUT_DIR)/determinant.o $(OUTPUT_DIR)/myrandom.o -o $(OUTPUT_DIR)/etape2.out $(GCC_FLAGS)	
	echo "$(OUTPUT_DIR)/etape3.out a été créé"

clean:
	echo "Suppression des exécutables"
	rm -f $(OUTPUT_DIR)/*.out
	echo "Les exécutables ont été supprimés"

fclean: clean
	echo "Suppression des fichiers objets"
	rm -f $(OUTPUT_DIR)/*.o
	echo "Les fichiers exécutables et objets ont été supprimés"

re: clean fclean all

.PHONY: all clean fclean re
