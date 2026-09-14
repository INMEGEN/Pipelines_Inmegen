process snpSift {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:An2'
    containerOptions "-v ${params.snpsift_db}:/snpsift_db -v ${params.annovar_db}:/humandb"
    publishDir params.out + "/snpEff", mode: 'copy'

    input:
    tuple val(sample_id), path(snpeff_vcf), path(snpeff_vcf_idx)

    output:
    tuple val("${sample_id}"),
          path("${sample_id}_snpSift.vcf.gz"),
          path("${sample_id}_snpSift.vcf.gz.tbi"),
          emit: snpsift_ch_vcf
    tuple val("${sample_id}"),
          path("${sample_id}_snpSift_fields.txt"),
          emit: snpsift_ch_txt

    script:
    """
# ── 1. ClinVar ────────────────────────────────────────────────────────────
    SnpSift annotate \\
        -name CLINVAR_ \\
        /snpsift_db/clinvar.vcf.gz \\
        ${snpeff_vcf} \\
        > ${sample_id}_tmp_clinvar.vcf

    # ── 2. dbSNP ──────────────────────────────────────────────────────────────
    SnpSift annotate \\
        -name DBSNP_ \\
        /snpsift_db/dbSNP_GRCh37.vcf.gz \\
        ${sample_id}_tmp_clinvar.vcf \\
        > ${sample_id}_tmp_dbsnp.vcf

    # ── 3. ClinGen haploinsuficiencia ─────────────────────────────────────────
    # Entrada ahora desde dbsnp (paso 2) en lugar de dbnsfp (paso 3)
    SnpSift intervals \\
        /snpsift_db/ClinGen_haploinsufficiency_gene_GRCh37.bed \\
        ${sample_id}_tmp_dbsnp.vcf \\
        > ${sample_id}_tmp_clingen_hi.vcf

    SnpSift intervals \\
        /snpsift_db/ClinGen_triplosensitivity_gene_GRCh37.bed \\
        ${sample_id}_tmp_clingen_hi.vcf \\
        > ${sample_id}_tmp_clingen_ts.vcf

    # ── 4. Comprimir e indexar ────────────────────────────────────────────────
    bgzip -c ${sample_id}_tmp_clingen_ts.vcf \\
        > ${sample_id}_snpSift.vcf.gz
    tabix ${sample_id}_snpSift.vcf.gz

    # ── 5. Extraer campos a tabla plana ───────────────────────────────────────
    SnpSift extractFields \\
        -s "," -e "." \\
        ${sample_id}_snpSift.vcf.gz \\
        CHROM POS ID REF ALT QUAL FILTER \\
        "ANN[0].GENE" "ANN[0].EFFECT" "ANN[0].IMPACT" \\
        "ANN[0].FEATURE" "ANN[0].FEATUREID" \\
        "ANN[0].HGVS_C" "ANN[0].HGVS_P" \\
        "ANN[0].RANK" \\
        CLINVAR_CLNSIG CLINVAR_CLNDN CLINVAR_CLNACC \\
        DBSNP_ID \\
        INTERVAL \\
        > ${sample_id}_snpSift_fields.txt

    # ── Limpieza ──────────────────────────────────────────────────────────────
    rm -f ${sample_id}_tmp_*.vcf
    """
}
