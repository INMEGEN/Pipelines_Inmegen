process analyzeCovariates{
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public'
    publishDir params.out + "/bqsr", mode:'copy'

    input:
    tuple val(sample_id), path(recal_table), path(post_recal_table)

    output:
    tuple val(sample_id), path("${sample_id}_recalibration_plots.pdf"), emit: analyzed_covariates

    script:
    """
    gatk AnalyzeCovariates \
        -before ${recal_table} \
        -after ${post_recal_table} \
        -plots ${sample_id}_recalibration_plots.pdf 
     """
}
