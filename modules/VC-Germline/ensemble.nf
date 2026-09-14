process ensembleVariants {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/ensemble_vcf", mode: 'copy'

    input:
    tuple val(project_id), path(gatk_vcf), path(gatk_tbi)
    tuple val(project_id_2), path(dv_vcf),   path(dv_tbi)

    output:
    tuple val(project_id), path("${project_id}_consensus.vcf.gz"), path("${project_id}_consensus.vcf.gz.tbi"), emit: consensus_vcf
    tuple val(project_id), path("${project_id}_ensemble.vcf.gz"),  path("${project_id}_ensemble.vcf.gz.tbi"),  emit: ensemble_vcf
    path("${project_id}_ensemble_stats.txt"),                                                                  emit: ensemble_stats

    script:
    """
    mkdir -p isec_out

    INFO_HDR='##INFO=<ID=CALLERS,Number=1,Type=String,Description="Callers that detected this variant">'

    # Normalizar ambos VCFs
    bcftools norm -f /ref/${params.refname} -m -any ${gatk_vcf} \\
        | bgzip -c > gatk_norm.vcf.gz && tabix gatk_norm.vcf.gz

    bcftools norm -f /ref/${params.refname} -m -any ${dv_vcf} \\
        | bgzip -c > dv_norm.vcf.gz && tabix dv_norm.vcf.gz

    # Intersección: 0000=GATK-only, 0001=DV-only, 0002=ambos(GATK), 0003=ambos(DV)
    bcftools isec -p isec_out -Oz gatk_norm.vcf.gz dv_norm.vcf.gz

    # Consensus: variantes en AMBOS callers
    cp isec_out/0002.vcf.gz ${project_id}_consensus.vcf.gz
    tabix ${project_id}_consensus.vcf.gz

    # GATK-only con anotación CALLERS
    bcftools view isec_out/0000.vcf.gz \\
        | awk -v hdr="\$INFO_HDR" 'BEGIN{OFS="\\t"} \\
              /^##/{print} \\
              /^#CHROM/{print hdr; print} \\
              !/^#/{\$8=\$8";CALLERS=GATK"; print}' \\
        | bgzip -c > hc_only.vcf.gz
    tabix hc_only.vcf.gz

    # DV-only con anotación CALLERS
    bcftools view isec_out/0001.vcf.gz \\
        | awk -v hdr="\$INFO_HDR" 'BEGIN{OFS="\\t"} \\
              /^##/{print} \\
              /^#CHROM/{print hdr; print} \\
              !/^#/{\$8=\$8";CALLERS=DeepVariant"; print}' \\
        | bgzip -c > dv_only.vcf.gz
    tabix dv_only.vcf.gz

    # Consensus con anotación CALLERS=GATK_DeepVariant
    bcftools view ${project_id}_consensus.vcf.gz \\
        | awk -v hdr="\$INFO_HDR" 'BEGIN{OFS="\\t"} \\
              /^##/{print} \\
              /^#CHROM/{print hdr; print} \\
              !/^#/{\$8=\$8";CALLERS=GATK_DeepVariant"; print}' \\
        | bgzip -c > consensus_ann.vcf.gz
    tabix consensus_ann.vcf.gz

    # Union ensemble completo
    bcftools concat -a -D consensus_ann.vcf.gz hc_only.vcf.gz dv_only.vcf.gz \\
        | bcftools sort -Oz -o ${project_id}_ensemble.vcf.gz
    tabix ${project_id}_ensemble.vcf.gz

    # Estadísticas
    echo "=== Ensemble Variant Caller Statistics ===" >  ${project_id}_ensemble_stats.txt
    echo "Project: ${project_id}"                      >> ${project_id}_ensemble_stats.txt
    echo ""                                            >> ${project_id}_ensemble_stats.txt
    echo "Variants in GATK only:"                      >> ${project_id}_ensemble_stats.txt
    bcftools stats hc_only.vcf.gz                 | grep "^SN" >> ${project_id}_ensemble_stats.txt
    echo "Variants in DeepVariant only:"               >> ${project_id}_ensemble_stats.txt
    bcftools stats dv_only.vcf.gz                 | grep "^SN" >> ${project_id}_ensemble_stats.txt
    echo "Variants in BOTH callers (consensus):"       >> ${project_id}_ensemble_stats.txt
    bcftools stats ${project_id}_consensus.vcf.gz | grep "^SN" >> ${project_id}_ensemble_stats.txt

    rm -rf isec_out hc_only.vcf.gz* dv_only.vcf.gz* \\
           gatk_norm.vcf.gz* dv_norm.vcf.gz* consensus_ann.vcf.gz*
    """
}
