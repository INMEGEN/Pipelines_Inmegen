process variantQC {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/variant_qc", mode: 'copy'

    input:
    tuple val(project_id), path(vcf), path(vcf_idx)

    output:
    path("${project_id}_variant_stats.txt")

    script:
    """
    bcftools stats ${vcf} > ${project_id}_variant_stats.txt
    """
}
