# Identificación conjunta de variantes germinales a partir de datos WGS/WES

## Descripción de los archivos de salida del flujo de trabajo [VC-Germline]

Como parte de los servicios de análisis bioinformáticos del INMEGEN, después de ejecutar el flujo de trabajo se entregarán los siguientes directorios organizados de la siguiente manera:

    Folio de Proyecto/
    ├── Alineamientos
    ├── Analisis_de_calidad
    │   ├── Inspeccion_Secuencias
    │   └── Reportes_Calidad
    ├── Resultados
    │   ├── Reportes_de_calidad
    │   ├── Variantes
    │   │   └── variantes_por_muestra
    │   └── Variantes_anotadas
    │       └── variantes_por_muestra
    ├── RESULTS_INFO.md
    └── md5sum.txt

Esta estructura se genera de forma automática al terminar la corrida con el script `bin/entregables.sh`, que también calcula las sumas de verificación (`md5sum.txt`) de todos los archivos entregados.

**NOTA:** Todos los resultados están referidos al genoma humano **hg38 (GRCh38)**.

### Directorio: **Alineamientos**

Este directorio contiene los archivos alineados a hg38 (genoma humano versión GRCh38) **por muestra** en formato [bam](https://support.illumina.com/help/BS_App_RNASeq_Alignment_OLH_1000000006112/Content/Source/Informatics/BAM-Format.htm), junto con su índice (`.bai`). Los alineamientos ya tienen marcados los duplicados (GATK MarkDuplicatesSpark).

**NOTA:** Regularmente los archivos alineados son de un peso aproximado que oscila entre ~1 Gb a 20 Gb por lo que se recomienda elegir un lugar con suficiente espacio para la transferencia de dichos archivos.

### Directorio: **Analisis_de_calidad**

  - **Reporte_Calidad.html**

  Resumen del análisis de calidad de la secuenciación (FASTQ: R1 + R2). Informe generado con MultiQC con las salidas de FastQC y Fastq_Screen.

#### Subdirectorio, **Inspeccion_Secuencias**:

 - Archivos de salida de **Fastq_Screen** con la inspección completa del origen de las secuencias utilizando genomas de bacterias, hongos y algunas especies comunes.

#### Subdirectorio, **Reportes_Calidad**:

 - Archivos de salida de **FastQC** por cada archivo (FASTQ: R1 + R2).

**IMPORTANTE:** El análisis de calidad y la inspección de las secuencias realizados con **FastQC** y **Fastq_Screen** se llevaron a cabo sobre los archivos **FASTQ** sin ningún tratamiento previo.

### Directorio: **Resultados**

 - **Reporte_de_Calidad_Analisis.html**
   Archivo generado con MultiQC. Este informe incluye diversas métricas de calidad y alineamiento generadas por las siguientes herramientas bioinformáticas:

     1 **FastQC** y **Fastp**: Evaluación de la calidad de las lecturas después del recorte de adaptadores y la eliminación de lecturas de baja calidad.

     2 **GATK** y **Picard**: Métricas de alineamiento al genoma de referencia.

     3 **Mosdepth:** Comprobación de la cobertura y profundidad de las regiones del genoma alineadas.

     4 **SnpEff:** Métricas de la calidad de las variantes.

 - **Reporte_variantQC.html**
   Diversos estadísticos del número y tipo de variantes encontradas (DISCVRSeq VariantQC).

   Este reporte clasifica a las variantes en tres categorías:
   1. RAW (número total de variantes sin filtrar).
   2. Filtered (número de variantes que NO pasaron algún filtro de VQSR).
   3. Called (número de variantes que pasaron los filtros de VQSR y fueron marcadas con la bandera PASS).

 - **Resumen_cobertura.txt**
   Resumen rápido de la profundidad y lecturas on-target de las muestras.
   NOTA: En el caso de secuenciación de genoma completo las lecturas on-target son aquellas que han sido alineadas.

#### Subdirectorio: **Reportes_de_calidad**

 - Tablas planas generadas por MultiQC (`multiqc_data`) y las estadísticas de **SnpEff** (`*_snpEff_stats.csv` y `*_snpEff_stats.genes.txt`).

#### Subdirectorio: **Variantes**

 - **[Folio]_variantes.vcf.gz**
   Archivo VCF con las variantes identificadas de forma conjunta que pasaron los filtros de [VQSR](https://gatk.broadinstitute.org/hc/en-us/articles/360035531612-Variant-Quality-Score-Recalibration-VQSR) (bandera **PASS**) y el post-filtrado de cobertura mínima (`params.min_dp`) de todas las muestras.

**NOTA:** Cuando el módulo de DeepVariant está activo (`params.run_deepvariant = true`), este archivo corresponde al **consenso** entre GATK HaplotypeCaller y DeepVariant. El campo `INFO/CALLERS` indica qué identificador de variantes detectó cada sitio.

**NOTA**: Se incluye el subdirectorio *variantes_por_muestra* que contiene un archivo VCF por muestra.

#### Subdirectorio: **Variantes_anotadas**

 - **[Folio]_vars_anotadas.annovar.vcf.gz**
   Variantes identificadas de forma conjunta y anotadas con ANNOVAR. Los catálogos de genes utilizados son: *refGene*, *refGeneWithVer* y *ensGene*, así como las bases de datos *avSNP*, *ClinVar*, *gnomAD* (genoma v3.1.2 y exoma v2.1.1), *ESP6500*, *dbNSFP*, *dbscSNV*, *InterVar* y *COSMIC*. Los catálogos exactos se definen en `params.annovar_protocol`.

 - **[Folio]_vars_anotadas.annovar.txt**
   Misma información que el archivo `[Folio]_vars_anotadas.annovar.vcf.gz` pero en un formato tabular.

**NOTA**: En caso de existir más de un alelo alternativo, este se coloca en un renglón diferente. Entonces, para la correcta interpretación del genotipo es necesario remitirse a la columna ALT (diferente de Alt) la cual describe todos los alelos encontrados en las distintas muestras.

 - **[Folio]_vars_anotadas.snpEff.vcf.gz**
   Variantes anotadas con **SnpEff** (catálogo *GRCh38.99*) y enriquecidas con **SnpSift** utilizando *ClinVar*, *dbSNP* y los intervalos de *ClinGen* (haploinsuficiencia y triplosensibilidad).

 - **[Folio]_vars_anotadas.snpEff.txt**
   Tabla plana generada con `SnpSift extractFields` con los campos más relevantes por variante: gen, efecto, impacto, transcrito, HGVS.c, HGVS.p, significancia clínica de ClinVar, rsID y los intervalos de ClinGen.

**NOTA**: Se incluye el subdirectorio *variantes_por_muestra* que contiene un archivo VCF con las variantes anotadas por muestra.

**NOTA**: Todos los archivos VCFs se entregarán compresos en formato bgzip con su índice `.tbi`. Para mayor información del formato de llamado de variantes (VCF) [consulte esta liga](https://support.illumina.com/help/BS_App_RNASeq_Alignment_OLH_1000000006112/Content/Source/Informatics/VCF-Format.htm).

## Recursos utilizados

   - [Bundle GATK, genoma hg38](https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/)
   - Bases de datos de ANNOVAR (`params.annovar_db`)
   - Bases de datos de SnpSift: ClinVar, dbSNP y ClinGen (`params.snpsift_db`)
   - Genomas de Fastq_Screen (`params.fqscreen_db`)

### Versiones de las herramientas utilizadas en el flujo de análisis
  - Fastp 0.23.4
  - FastQC v0.12.1
  - Fastq_Screen v0.15.3
  - BWA MEM 0.7.17
  - Mosdepth 0.3.6
  - GATK 4.6.2
  - DeepVariant 1.6.1
  - GLnexus 1.4.1
  - Picard
  - BCFTools
  - SAMTools
  - ANNOVAR
  - SnpEff / SnpSift
  - DISCVRSeq VariantQC
  - MultiQC v1.25.1
  - R 4.4.2
  - NextFlow v24.10.4.5934
  - Docker v25.0.1
