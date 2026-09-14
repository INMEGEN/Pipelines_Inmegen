#!/bin/bash

# Workflow    : Identificación conjunta de variantes germinales
# Institución : Instituto Nacional de Medicina Genómica (INMEGEN)
# Descripción : Construye la carpeta de entregables con la estructura descrita
#               en RESULTS_INFO.md a partir del directorio de salida del pipeline
#
# Uso: bash bin/entregables.sh [directorio_destino]
#      Si no se indica destino se crea en el mismo nivel que 'outdir'

CONFIG="nextflow.config"

# Leer el valor de 'outdir' y 'project_id' desde el archivo de configuración
OUTDIR=$(grep -E '^\s*params\.outdir\s*=\s*".*"' "$CONFIG" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | tr -d '"')
FOLIO=$(grep -E '^\s*params\.project_id\s*=\s*".*"' "$CONFIG" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | tr -d '"')

# Validar que se obtuvieron los valores
if [ -z "$OUTDIR" ] || [ -z "$FOLIO" ]; then
  echo "Error: No se pudo encontrar 'outdir' o 'project_id' en el archivo de configuración."
  exit 1
fi

OUT="${OUTDIR}/out"

if [ ! -d "$OUT" ]; then
  echo "Error: No existe el directorio de salida $OUT"
  exit 1
fi

# Directorio de los entregables
DESTINO="${1:-${OUTDIR}/${FOLIO}}"

# === Subdirectorios del flujo de trabajo =====================
# Editar SOLO si se modificó el publishDir de algún proceso
DIR_BAM="${OUT}/dedup_sorted"
DIR_FQSCREEN="${OUT}/fastq_screen"
DIR_FASTQC="${OUT}/fastqc"
DIR_MULTIQC="${OUT}/multiqc"
DIR_VARIANTQC="${OUT}/variant_stats"
DIR_SUMMARY="${OUT}/summary_metrics"
DIR_CLINICAL="${OUT}/clinical_vcf"
DIR_PERSAMPLE="${OUT}/vcfs_persample"
DIR_ANNOVAR="${OUT}/annovar"
DIR_SNPEFF="${OUT}/snpEff"

# === Funciones auxiliares ====================================

# Copia un patrón de archivos y avisa si no encuentra nada
copiar() {
    origen="$1"
    destino="$2"
    encontrados=$(ls -1 $origen 2>/dev/null | wc -l)

    if [ "$encontrados" -eq 0 ]; then
        echo "  AVISO: no se encontró $origen"
        return 1
    fi

    cp -rL $origen "$destino" 2>/dev/null
    echo "  OK: $encontrados archivo(s) -> ${destino#$DESTINO/}"
}

# Copia un solo archivo renombrándolo
copiar_como() {
    origen=$(ls -1 $1 2>/dev/null | head -n 1)
    destino="$2"

    if [ -z "$origen" ]; then
        echo "  AVISO: no se encontró $1"
        return 1
    fi

    cp -L "$origen" "$destino"
    echo "  OK: $(basename $origen) -> $(basename $destino)"
}

# === Estructura de directorios ===============================

echo -e "\nGenerando entregables del proyecto ${FOLIO} en:\n  ${DESTINO}\n"

mkdir -p "${DESTINO}/Alineamientos"
mkdir -p "${DESTINO}/Analisis_de_calidad/Inspeccion_Secuencias"
mkdir -p "${DESTINO}/Analisis_de_calidad/Reportes_Calidad"
mkdir -p "${DESTINO}/Resultados/Reportes_de_calidad"
mkdir -p "${DESTINO}/Resultados/Variantes/variantes_por_muestra"
mkdir -p "${DESTINO}/Resultados/Variantes_anotadas/variantes_por_muestra"

# === Alineamientos ===========================================

echo "[1/5] Alineamientos"
copiar "${DIR_BAM}/*_alineamiento.bam"     "${DESTINO}/Alineamientos/"
copiar "${DIR_BAM}/*_alineamiento.bam.bai" "${DESTINO}/Alineamientos/"

# === Analisis_de_calidad =====================================

echo "[2/5] Analisis_de_calidad"
copiar "${DIR_FQSCREEN}/*"          "${DESTINO}/Analisis_de_calidad/Inspeccion_Secuencias/"
copiar "${DIR_FASTQC}/*"            "${DESTINO}/Analisis_de_calidad/Reportes_Calidad/"
copiar_como "${DIR_MULTIQC}/QC_report.html" "${DESTINO}/Analisis_de_calidad/Reporte_Calidad.html"

# === Resultados: reportes ====================================

echo "[3/5] Resultados (reportes)"
copiar_como "${DIR_MULTIQC}/QC_report.html"         "${DESTINO}/Resultados/Reporte_de_Calidad_Analisis.html"
copiar_como "${DIR_VARIANTQC}/*_variantQC.html"     "${DESTINO}/Resultados/Reporte_variantQC.html"
copiar_como "${DIR_SUMMARY}/Summary_QCmetrics.txt"  "${DESTINO}/Resultados/Resumen_cobertura.txt"
copiar "${DIR_MULTIQC}/multiqc_data/*"              "${DESTINO}/Resultados/Reportes_de_calidad/"
copiar "${DIR_SNPEFF}/*_snpEff_stats.*"             "${DESTINO}/Resultados/Reportes_de_calidad/"

# === Resultados: Variantes ===================================

echo "[4/5] Resultados (variantes)"
copiar_como "${DIR_CLINICAL}/*_clinical_pass.vcf.gz"     "${DESTINO}/Resultados/Variantes/${FOLIO}_variantes.vcf.gz"
copiar_como "${DIR_CLINICAL}/*_clinical_pass.vcf.gz.tbi" "${DESTINO}/Resultados/Variantes/${FOLIO}_variantes.vcf.gz.tbi"
copiar "${DIR_PERSAMPLE}/variantes_vcfs/*"        "${DESTINO}/Resultados/Variantes/variantes_por_muestra/"

# === Resultados: Variantes_anotadas ==========================

echo "[5/5] Resultados (variantes anotadas)"
copiar_como "${DIR_ANNOVAR}/*_multianno.vcf.gz"     "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.annovar.vcf.gz"
copiar_como "${DIR_ANNOVAR}/*_multianno.vcf.gz.tbi" "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.annovar.vcf.gz.tbi"
copiar_como "${DIR_ANNOVAR}/*_multianno.txt"        "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.annovar.txt"
copiar_como "${DIR_SNPEFF}/*_snpSift.vcf.gz"        "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.snpEff.vcf.gz"
copiar_como "${DIR_SNPEFF}/*_snpSift.vcf.gz.tbi"    "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.snpEff.vcf.gz.tbi"
copiar_como "${DIR_SNPEFF}/*_snpSift_fields.txt"    "${DESTINO}/Resultados/Variantes_anotadas/${FOLIO}_vars_anotadas.snpEff.txt"
copiar "${DIR_PERSAMPLE}/anotadas_vcfs/*"           "${DESTINO}/Resultados/Variantes_anotadas/variantes_por_muestra/"

# === Documentación e integridad ==============================

if [ -f "RESULTS_INFO.md" ]; then
    cp RESULTS_INFO.md "${DESTINO}/"
fi

echo -e "\nGenerando sumas de verificación (md5)"
cd "${DESTINO}" && find . -type f ! -name "md5sum.txt" -exec md5sum {} \; > md5sum.txt

echo -e "\nTamaño total del entregable: $(du -sh "${DESTINO}" | cut -f1)"
echo -e "Entregables del proyecto ${FOLIO} listos en ${DESTINO}\n"
