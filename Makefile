# Variables
NASM_FLAGS=-felf64 -Fdwarf -g
GCC_FLAGS=-lm -fPIC -fno-pie -no-pie -z noexecstack --for-linker /lib64/ld-linux-x86-64.so.2 -lX11

# Dossier des étapes et des fonctions
ETAPES_DIR=etapes
FUNCTIONS_DIR=functions
OUTPUT_DIR=output

# Liste des fichiers ASM dans functions/
FUNCTIONS_SOURCES=$(wildcard $(FUNCTIONS_DIR)/*.asm)
FUNCTIONS_OBJECTS := $(FUNCTIONS_SOURCES:.asm=.o)

# Règle principale : compiler toutes les étapes
all: etape1 etape2 etape3 etape4_1 etape4_2
	echo "Les exécutables des étapes sont dans $(OUTPUT_DIR)/"

# Fonction pour assembler un fichier et ses dépendances
assemble: 
	@if [ -z "$(file)" ]; then \
		echo "Erreur : Spécifiez un fichier comme second argument, exemple : make assedmble file=etape1"; \
		exit 1; \
	fi
	
	@if [ -f $(ETAPES_DIR)/$(file).asm ]; then \
		echo "Assemblage de $(ETAPES_DIR)/$(file).asm"; \
		set -e; \
		nasm $(NASM_FLAGS) $(ETAPES_DIR)/$(file).asm -o $(ETAPES_DIR)/$(file).o; \
		for func in $(FUNCTIONS_SOURCES); do \
			echo "Assemblage de $$func"; \
			set -e; \
			nasm $(NASM_FLAGS) $$func -o $(FUNCTIONS_DIR)/$$(basename $$func .asm).o; \
		done; \
	else \
		echo "Fichier $(ETAPES_DIR)/$@.asm non trouvé."; \
	fi

# Règle pour chaque étape, crée l'exécutable
etape1: $(ETAPES_DIR)/etape1.asm $(FUNCTIONS_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	make assemble file=etape1
	gcc $(ETAPES_DIR)/etape1.o $(FUNCTIONS_OBJECTS) -o $(OUTPUT_DIR)/etape1.out $(GCC_FLAGS)
	rm -rf $(ETAPES_DIR)/etape1.o $(FUNCTIONS_OBJECTS) && \
	echo "$(OUTPUT_DIR)/etape1.out a été crée"  
	

# Nettoyage
clean:
	echo "Suppression des exécutables"
	rm -rf */*.out && \
	rm -rf $(OUTPUT_DIR)/ && \
	echo "Les exécutables ont été supprimés"

fclean: clean
	make clean
	echo "Suppression des fichiers objets"
	rm -rf */*.o && \
	echo "Les fichiers exécutables et objects ont été supprimés"

re: clean fclean all

.PHONY: all clean fclean re
