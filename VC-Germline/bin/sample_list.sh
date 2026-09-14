#!/bin/bash

# Directorios raiz para la busqueda
DIRECTORIOS=(${@:-.})

# Archivo de salida
SALIDA="sample_info.tsv"

# Imprimir encabezado de la tabla en el archivo de salida
echo -e "SampleID\tSample_name\tRG_PU\tRG_PL\tRG_LB\tR1\tR2" > "$SALIDA"

# Enlistar archivos fastq y generar la salida
for DIRECTORIO in "${DIRECTORIOS[@]}"; do
    find "$DIRECTORIO" -type f \( -name "*.fastq.gz" -o -name "*.fastq" -o -name "*.fq" -o -name "*.fq.gz" \) | sort | while read -r FILE; do
        # Obtener la ruta absoluta del archivo
        ABS_PATH=$(realpath "$FILE")

        # Obtener el nombre base del archivo sin extension
        BASE_NAME=$(basename "$FILE" | sed -E 's/\.fastq.gz$|\.fastq$|\.fq.gz$|\.fq$//')

        # Obtener SampleID y Sample_name a partir del nombre base del archivo
        if [[ "$BASE_NAME" =~ (.+)_L[0-9]{3}_R[12] ]]; then
            SAMPLE_ID=${BASH_REMATCH[1]}
            LANE=$(echo "$BASE_NAME" | grep -oE '_L[0-9]{3}')
            SAMPLE_NAME="${SAMPLE_ID}${LANE}"
        elif [[ "$BASE_NAME" =~ (.+)_R[12] ]]; then
            SAMPLE_ID=${BASH_REMATCH[1]}
            SAMPLE_NAME="$SAMPLE_ID"
        else
            continue
        fi

        # Identificar si es R1 o R2
        if [[ "$BASE_NAME" =~ (_R1|_read1|_1|_r1) ]]; then
            # Definir el patron para encontrar el archivo R2 correspondiente
            PAIR_R2=$(echo "$FILE" | sed -E 's/_R1|_read1|_1|_r1/_R2/; s/_read1/_read2/; s/_1/_2/; s/_r1/_r2/')

            if [[ -f "$PAIR_R2" ]]; then
                # Leer el encabezado del archivo R1
                if [[ "$FILE" == *.gz ]]; then
                    HEADER=$(zcat "$FILE" | head -n 1)
                else
                    HEADER=$(head -n 1 "$FILE")
                fi

                # Extraer la informacion del encabezado
		RG_LB=$(echo "$HEADER" | cut -d ':' -f 3)
        	RG_PU=$(echo "$HEADER" | awk -F ':' '{print substr($1, 2) "." $4}')
        	RG_PL="ILLUMINA"

                # Imprimir la informacion en el archivo de salida
                echo -e "$SAMPLE_ID\t$SAMPLE_NAME\t$RG_PU\t$RG_PL\t$RG_LB\t$ABS_PATH\t$(realpath "$PAIR_R2")" >> "$SALIDA"
            fi
        fi
    done
done
