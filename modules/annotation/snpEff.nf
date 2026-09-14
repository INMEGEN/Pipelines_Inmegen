process snpEff {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:An2'
    publishDir params.out + "/snpEff", mode: 'copy'

    input:
    tuple val(sample_id), path(filtered_vcf), path(filtered_vcf_idx)

    output:
    tuple val("${sample_id}"),
          path("${sample_id}_snpEff.vcf.gz"),
          path("${sample_id}_snpEff.vcf.gz.tbi"),      emit: snpeff_ch_vcf
    tuple path("${sample_id}_snpEff_stats.csv"),
          path("${sample_id}_snpEff_stats.genes.txt"), emit: snpeff_ch_txt

    script:
    """
    zcat ${filtered_vcf} | snpEff -v GRCh37.75 \\
        -csvStats ${sample_id}_snpEff_stats.csv \\
        -noLog \\
        -cancer \\
        > ${sample_id}_snpEff.vcf

    bgzip -c ${sample_id}_snpEff.vcf > ${sample_id}_snpEff.vcf.gz
    tabix ${sample_id}_snpEff.vcf.gz
    rm ${sample_id}_snpEff.vcf
    """
}
